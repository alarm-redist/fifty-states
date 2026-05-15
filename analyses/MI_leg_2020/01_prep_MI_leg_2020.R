###############################################################################
# Download and prepare data for `MI_leg_2020` analysis
# © ALARM Project, January 2026
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
cli_process_start("Downloading files for {.pkg MI_leg_2020}")

path_data <- download_redistricting_file("MI", "data-raw/MI", year = 2020)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MI_2020/shp_vtd.rds"
perim_path <- "data-out/MI_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong MI} shapefile")
    # read in redistricting data
    mi_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        join_vtd_shapefile(year = 2020) |>
        st_transform(EPSG$MI)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("MI", "INCPLACE_CDP", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("MI"), vtd)) |>
        select(-vtd)
    d_ssd <- make_from_baf("MI", "SLDU", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("MI"), vtd),
            ssd_2010 = as.integer(sldu))
    d_shd <- make_from_baf("MI", "SLDL", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("MI"), vtd),
            shd_2010 = as.integer(sldl))

    mi_shp <- mi_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        left_join(d_shd, by = "GEOID") |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, ssd_2010, .after = county) |>
        relocate(muni, county_muni, shd_2010, .after = county)

    # add the enacted plan
    mi_shp <- mi_shp |>
        left_join(y = leg_from_baf(state = "MI"), by = "GEOID")

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = mi_shp,
        perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        mi_shp <- rmapshaper::ms_simplify(mi_shp, keep = 0.05,
            keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    mi_shp$adj <- adjacency(mi_shp)

    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(mi_shp$adj, mi_shp$ssd_2020)
    ccm(mi_shp$adj, mi_shp$shd_2020)

    mi_shp <- mi_shp |>
        fix_geo_assignment(muni)

    write_rds(mi_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    mi_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong MI} shapefile")
}
