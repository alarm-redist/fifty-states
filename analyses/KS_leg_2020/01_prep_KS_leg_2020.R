###############################################################################
# Download and prepare data for `KS_leg_2020` analysis
# © ALARM Project, February 2026
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
cli_process_start("Downloading files for {.pkg KS_leg_2020}")

path_data <- download_redistricting_file("KS", "data-raw/KS", year = 2020)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/KS_2020/shp_vtd.rds"
perim_path <- "data-out/KS_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong KS} shapefile")
    # read in redistricting data
    ks_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        join_vtd_shapefile(year = 2020) |>
        st_transform(EPSG$KS)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("KS", "INCPLACE_CDP", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("KS"), vtd)) |>
        select(-vtd)
    d_ssd <- make_from_baf("KS", "SLDU", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("KS"), vtd),
            ssd_2010 = as.integer(sldu))
    d_shd <- make_from_baf("KS", "SLDL", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("KS"), vtd),
            shd_2010 = as.integer(sldl))

    ks_shp <- ks_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        left_join(d_shd, by = "GEOID") |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, ssd_2010, .after = county) |>
        relocate(muni, county_muni, shd_2010, .after = county)

    # add the enacted plan
    ks_shp <- ks_shp |>
        left_join(y = leg_from_baf(state = "KS"), by = "GEOID")

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ks_shp,
        perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ks_shp <- rmapshaper::ms_simplify(ks_shp, keep = 0.05,
            keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    ks_shp$adj <- adjacency(ks_shp)

    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(ks_shp$adj, ks_shp$ssd_2020)
    ccm(ks_shp$adj, ks_shp$shd_2020)

    ks_shp <- ks_shp |>
        fix_geo_assignment(muni)

    write_rds(ks_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ks_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong KS} shapefile")
}
