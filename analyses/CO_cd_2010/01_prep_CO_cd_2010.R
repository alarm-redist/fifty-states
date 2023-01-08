###############################################################################
# Download and prepare data for `CO_cd_2010` analysis
# © ALARM Project, January 2023
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
cli_process_start("Downloading files for {.pkg CO_cd_2010}")

path_data <- download_redistricting_file("CO", "data-raw/CO", year = 2010)

# download the enacted plan.
# TODO try to find a download URL at <https://redistricting.lls.edu/state/colorado/>
url <- "https://redistricting.lls.edu/wp-content/uploads/co_2010_congress_2011-12-05_2021-12-31.zip"
path_enacted <- "data-raw/CO/CO_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "CO_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/CO/CO_enacted/Moreno_South_Shapefiles.shp" # TODO use actual SHP

# TODO other files here (as necessary). All paths should start with `path_`
# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/CO_2010/shp_vtd.rds"
perim_path <- "data-out/CO_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong CO} shapefile")
    # read in redistricting data
    co_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$CO)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("CO", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("CO"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("CO", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("CO"), vtd),
                  cd_2000 = as.integer(cd))
    co_shp <- left_join(co_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by="GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    co_shp <- co_shp %>%
        mutate(cd_2010 = as.integer(cd_shp$DISTRICT)[
            geo_match(co_shp, cd_shp, method = "area")],
            .after = cd_2000)

    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = co_shp,
                             perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        co_shp <- rmapshaper::ms_simplify(co_shp, keep = 0.05,
                                                 keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    co_shp$adj <- redist.adjacency(co_shp)

    # TODO any custom adjacency graph edits here

    co_shp <- co_shp %>%
        fix_geo_assignment(muni)

    write_rds(co_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    co_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong CO} shapefile")
}
