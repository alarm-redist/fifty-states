###############################################################################
# Download and prepare data for `CT_cd_2010` analysis
# © ALARM Project, November 2022
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
cli_process_start("Downloading files for {.pkg CT_cd_2010}")

path_data <- download_redistricting_file("CT", "data-raw/CT", year = 2010)

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/ct_2010_congress_2012-02-10_2021-12-31.zip"
path_enacted <- "data-raw/CT/CT_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "CT_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/CT/CT_enacted/Special Master Draft Plan.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/CT_2010/shp_vtd.rds"
perim_path <- "data-out/CT_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong CT} shapefile")
    # read in redistricting data
    ct_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$CT)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("CT", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("CT"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("CT", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("CT"), vtd),
            cd_2000 = as.integer(cd))
    ct_shp <- left_join(ct_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    baf_cd113 <- make_from_baf("CT", from = read_baf_cd113("CT"), year = 2010) %>%
        rename(GEOID = vtd) %>% mutate(GEOID = paste0("09", GEOID))
    ct_shp <- ct_shp %>%
        left_join(baf_cd113, by = "GEOID")

    # Four VTDs in the south which encompass mostly-to-only water are not assigned to a district in the final plan.
    # According to the Report and Plan of the Special Master (2012, page 13), these "water blocks" were left
    # "largely as they are under the current plan." These VTDs have population zero, so we are removing them.
    ct_shp <- ct_shp[!is.na(ct_shp$cd_2010), ]

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ct_shp,
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
