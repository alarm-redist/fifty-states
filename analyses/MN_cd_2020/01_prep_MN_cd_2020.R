###############################################################################
# Download and prepare data for `MN_cd_2020` analysis
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
cli_process_start("Downloading files for {.pkg MN_cd_2020}")

path_data <- download_redistricting_file("MN", "data-raw/MN")

# download the enacted plan.
url <- "https://gis.lcc.mn.gov/redist2020/Congressional/C2022/geography/C2022-shp.zip"
path_enacted <- "data-raw/MN/MN_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "MN_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/MN/MN_enacted/C2022.shp" # TODO use actual SHP

# TODO other files here (as necessary). All paths should start with `path_`
# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MN_2020/shp_vtd.rds"
perim_path <- "data-out/MN_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong MN} shapefile")
    # read in redistricting data
    mn_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$MN)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("MN", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("MN"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("MN", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("MN"), vtd),
            cd_2010 = as.integer(cd))
    mn_shp <- left_join(mn_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted)) %>%
        st_transform(EPSG$MN) %>%
        st_make_valid()
    mn_shp <- mn_shp %>%
        mutate(cd_2020 = as.integer(cd_shp$DISTRICT)[
            geo_match(mn_shp, cd_shp, method = "area")],
        .after = cd_2010)

    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = mn_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        mn_shp <- rmapshaper::ms_simplify(mn_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    mn_shp$adj <- redist.adjacency(mn_shp)

    # TODO any custom adjacency graph edits here

    mn_shp <- mn_shp %>%
        fix_geo_assignment(muni)

    write_rds(mn_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    mn_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong MN} shapefile")
}
