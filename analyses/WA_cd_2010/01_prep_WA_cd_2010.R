###############################################################################
# Download and prepare data for `WA_cd_2010` analysis
# © ALARM Project, July 2022
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
cli_process_start("Downloading files for {.pkg WA_cd_2010}")

path_data <- download_redistricting_file("WA", "data-raw/WA", year = 2010)

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/wa_2010_congress_2012-02-07_2021-12-31.zip"
path_enacted <- "data-raw/WA/WA_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "WA_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/WA/WA_enacted/CONG_AMEND_FINAL.shp"



cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/WA_2010/shp_vtd.rds"
perim_path <- "data-out/WA_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong WA} shapefile")
    # read in redistricting data
    # removed: , col_types = cols(GEOID20 = "c")
    wa_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$WA)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("WA", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("WA"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("WA", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("WA"), vtd),
            cd_2000 = as.integer(cd))
    wa_shp <- left_join(wa_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    wa_shp <- wa_shp %>%
        mutate(cd_2010 = as.integer(cd_shp$District_N)[
            geo_match(wa_shp, cd_shp, method = "area")],
        .after = cd_2000)


    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = wa_shp, perim_path = here(perim_path)) %>% invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        wa_shp <- rmapshaper::ms_simplify(wa_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    wa_shp <- st_make_valid(wa_shp)
    wa_shp$adj <- redist.adjacency(wa_shp)


    wa_shp <- wa_shp %>%
        fix_geo_assignment(muni)

    write_rds(wa_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    wa_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong WA} shapefile")
}
