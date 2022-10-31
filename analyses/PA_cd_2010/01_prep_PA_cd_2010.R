###############################################################################
# Download and prepare data for `PA_cd_2010` analysis
# © ALARM Project, October 2022
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
cli_process_start("Downloading files for {.pkg PA_cd_2010}")

path_data <- download_redistricting_file("PA", "data-raw/PA", year = 2010)

# download the enacted plan.
# TODO try to find a download URL at <https://redistricting.lls.edu/state/pennsylvania/>
url <- "https://redistricting.lls.edu/wp-content/uploads/pa_2010_congress_2011-12-22_2018-02-19.zip"
path_enacted <- "data-raw/PA/PA_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "PA_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/PA/PA_enacted/BlockLevelFinalCongressionalPlan21Dec2011.shp" # TODO use actual SHP

# TODO other files here (as necessary). All paths should start with `path_`
# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/PA_2010/shp_vtd.rds"
perim_path <- "data-out/PA_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong PA} shapefile")
    # read in redistricting data
    pa_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$PA) %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("PA", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("PA"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("PA", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("PA"), vtd),
                  cd_2000 = as.integer(cd))
    pa_shp <- left_join(pa_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by="GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    pa_shp <- pa_shp %>%
        mutate(cd_2010 = as.integer(cd_shp$District_1)[
            geo_match(pa_shp, cd_shp, method = "area")],
            .after = cd_2000)

    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = pa_shp,
                             perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        pa_shp <- rmapshaper::ms_simplify(pa_shp, keep = 0.05,
                                                 keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    pa_shp$adj <- redist.adjacency(pa_shp)

    # TODO any custom adjacency graph edits here

    pa_shp <- pa_shp %>%
        fix_geo_assignment(muni)

    write_rds(pa_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    pa_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong PA} shapefile")
}
