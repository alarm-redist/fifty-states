###############################################################################
# Download and prepare data for `WI_cd_2020` analysis
# © ALARM Project, February 2022
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
cli_process_start("Downloading files for {.pkg WI_cd_2020}")

path_data <- download_redistricting_file("WI", "data-raw/WI")

# download the enacted plan.
# TODO try to find a download URL at <https://redistricting.lls.edu/state/wisconsin/>
# url <- "https://redistricting.lls.edu/wp-content/uploads/`state`_2020_congress_XXXXX.zip"
# path_enacted <- "data-raw/WI/WI_enacted.zip"
# download(url, here(path_enacted))
# unzip(here(path_enacted), exdir = here(dirname(path_enacted), "WI_enacted"))
# file.remove(path_enacted)
# path_enacted <- "data-raw/WI/WI_enacted/XXXXXXX.shp" # TODO use actual SHP

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/WI_2020/shp_vtd.rds"
perim_path <- "data-out/WI_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong WI} shapefile")
    # read in redistricting data
    wi_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$WI)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("WI", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("WI"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("WI", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("WI"), vtd),
            cd_2010 = as.integer(cd))
    wi_shp <- left_join(wi_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add the enacted plan
    # cd_shp <- st_read(here(path_enacted))
    # wi_shp <- wi_shp %>%
    #     mutate(cd_2020 = as.integer(cd_shp$DISTRICT)[
    #         geo_match(wi_shp, cd_shp, method = "area")],
    #         .after = cd_2010)

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = wi_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        wi_shp <- rmapshaper::ms_simplify(wi_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    wi_shp$adj <- redist.adjacency(wi_shp)

    wi_shp <- wi_shp %>%
        fix_geo_assignment(muni)

    write_rds(wi_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    wi_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong WI} shapefile")
}
