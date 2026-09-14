###############################################################################
# Download and prepare data for `NY_leg_2020` analysis
# © ALARM Project, March 2026
###############################################################################

suppressMessages({
    library(dplyr)
    library(readr)
    library(sf)
    library(redist)
    library(geomander)
    library(cli)
    library(here)
    library(tinytiger)
    devtools::load_all() # load utilities
})

stopifnot(utils::packageVersion("redist") >= "5.0.0.1")

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg NY_leg_2020}")

path_data <- download_redistricting_file("NY", "data-raw/NY", year = 2020)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NY_2020/shp_vtd.rds"
perim_path <- "data-out/NY_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NY} shapefile")
    # read in redistricting data
    ny_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        join_vtd_shapefile(year = 2020) |>
        st_transform(EPSG$NY)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("NY", "INCPLACE_CDP", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("NY"), vtd)) |>
        select(-vtd)
    d_ssd <- make_from_baf("NY", "SLDU", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("NY"), vtd),
            ssd_2010 = as.integer(sldu))
    d_shd <- make_from_baf("NY", "SLDL", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("NY"), vtd),
            shd_2010 = as.integer(sldl))

    ny_shp <- ny_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        left_join(d_shd, by = "GEOID") |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, ssd_2010, .after = county) |>
        relocate(muni, county_muni, shd_2010, .after = county)

    # add the enacted plan
    ny_shp <- ny_shp |>
        left_join(y = leg_from_baf(state = "NY"), by = "GEOID")

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ny_shp,
        perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ny_shp <- rmapshaper::ms_simplify(ny_shp, keep = 0.05,
            keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    ny_shp$adj <- adjacency(ny_shp)

    nbr <- geomander::suggest_neighbors(ny_shp, adj = ny_shp$adj)
    ny_shp$adj <- geomander::add_edge(ny_shp$adj, nbr$x, nbr$y)

    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(ny_shp$adj, ny_shp$ssd_2020)
    ccm(ny_shp$adj, ny_shp$shd_2020)

    ny_shp <- ny_shp |>
        fix_geo_assignment(muni)

    write_rds(ny_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ny_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NY} shapefile")
}
