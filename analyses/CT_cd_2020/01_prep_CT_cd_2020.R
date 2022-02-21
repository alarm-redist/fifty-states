###############################################################################
# Download and prepare data for `CT_cd_2020` analysis
# © ALARM Project, December 2021
###############################################################################

suppressMessages({
    library(dplyr)
    library(readr)
    library(sf)
    library(redist)
    library(geomander)
    library(cli)
    library(here)
    devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg CT_cd_2020}")

path_data <- download_redistricting_file("CT", "data-raw/CT")

# download the enacted plan.
url <- "https://redistrictingdatahub.org/download/?datasetid=33952&document=%2Fweb_ready_stage%2Flegislative%2F2021_adopted_plans%2Fct_cong_adopted_2022.zip"
# Downloading the above .zip file requires that one first create and log into their account with Redistricting Data Hub
# path_enacted <- "data-raw/CT/CT_enacted.zip"
# unzip(here(path_enacted), exdir = here(dirname(path_enacted), "CT_enacted"))
# file.remove(path_enacted)
path_enacted <- "data-raw/CT/CT_enacted/Districts_1 2022-02-14.shp"
cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/CT_2020/shp_vtd.rds"
perim_path <- "data-out/CT_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong CT} shapefile")
    # read in redistricting data
    ct_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$CT)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("CT", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("CT"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("CT", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("CT"), vtd),
            cd_2010 = as.integer(cd))
    ct_shp <- left_join(ct_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted)) %>%
        st_transform(EPSG$CT) %>%
        st_make_valid()
    ct_shp <- ct_shp %>%
        mutate(cd_2020 = as.integer(cd_shp$DISTRICT)[
            geo_match(ct_shp, cd_shp, method = "area")],
        .after = cd_2010)
    # A few of the VTDs in the south which encompass mostly-to-only water are not assigned to a district in the final plan.
    # According to the Report and Plan of the Special Master (2022, page 13), these "water blocks" were left
    # "largely as they are under the current plan." Hence, we assign these VTDs with missing district assignment to the same
    # district assignments they had in 2010.
    ct_shp$cd_2020[is.na(ct_shp$cd_2020)] <- ct_shp$cd_2010[is.na(ct_shp$cd_2020)]

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = ct_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ct_shp <- rmapshaper::ms_simplify(ct_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ct_shp$adj <- redist.adjacency(ct_shp)

    ct_shp <- ct_shp %>%
        fix_geo_assignment(muni)

    write_rds(ct_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ct_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong CT} shapefile")
}
