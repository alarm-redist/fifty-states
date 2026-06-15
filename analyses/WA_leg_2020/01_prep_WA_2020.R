###############################################################################
# Download and prepare data for `WA_shd_2020` analysis
# © ALARM Project, June 2026
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
cli_process_start("Downloading files for {.pkg WA_shd_2020}")

path_data <- download_redistricting_file("WA", "data-raw/WA", year = 2020)

# I edited the URL and path_enacted

# download the enacted plan.
# TODO try to find a download URL at <https://redistricting.lls.edu/state/washington/>
url <- "https://redistricting.lls.edu/wp-content/uploads/wa_2020_state_lower_2024-03-15.zip"
path_enacted <- "data-raw/WA/WA_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "WA_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/WA/WA_enacted/Washington_State_Legislative_Districts_2024.shp" # TODO use actual SHP

# TODO other files here (as necessary). All paths should start with `path_`
# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/WA_2020/shp_vtd.rds"
perim_path <- "data-out/WA_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong WA} shapefile")
    # read in redistricting data
    wa_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        join_vtd_shapefile(year = 2020) |>
        st_transform(EPSG$WA)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("WA", "INCPLACE_CDP", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("WA"), vtd)) |>
        select(-vtd)
    d_cd <- make_from_baf("WA", "CD", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("WA"), vtd),
                  cd_2010 = as.integer(cd))
    wa_shp <- left_join(wa_shp, d_muni, by = "GEOID") |>
        left_join(d_cd, by="GEOID") |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, cd_2010, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    wa_shp <- wa_shp |>
        mutate(cd_2020 = as.integer(cd_shp$DISTRICT)[
            geo_match(wa_shp, cd_shp, method = "area")],
            .after = cd_2010)

    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = wa_shp,
                             perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        wa_shp <- rmapshaper::ms_simplify(wa_shp, keep = 0.05,
                                                 keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    wa_shp$adj <- redist.adjacency(wa_shp)

    # TODO any custom adjacency graph edits here

    wa_shp <- wa_shp |>
        fix_geo_assignment(muni)

    write_rds(wa_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    wa_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong WA} shapefile")
}
