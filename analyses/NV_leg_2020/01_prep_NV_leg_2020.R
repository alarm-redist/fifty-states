###############################################################################
# Download and prepare data for `NV_leg_2020` analysis
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
    library(tinytiger)
    devtools::load_all() # load utilities
})

stopifnot(utils::packageVersion("redist") >= "5.0.0.1")

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg NV_leg_2020}")

path_data <- download_redistricting_file("NV", "data-raw/NV", year = 2020)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NV_2020/shp_vtd.rds"
perim_path <- "data-out/NV_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NV} shapefile")
    # read in redistricting data
    nv_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        join_vtd_shapefile(year = 2020) |>
        st_transform(EPSG$NV)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("NV", "INCPLACE_CDP", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("NV"), vtd)) |>
        select(-vtd)
    d_ssd <- make_from_baf("NV", "SLDU", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("NV"), vtd),
            ssd_2010 = as.integer(sldu))
    d_shd <- make_from_baf("NV", "SLDL", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("NV"), vtd),
            shd_2010 = as.integer(sldl))

    nv_shp <- nv_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        left_join(d_shd, by = "GEOID") |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, ssd_2010, .after = county) |>
        relocate(muni, county_muni, shd_2010, .after = county)

    # add the enacted plan
    nv_shp <- nv_shp |>
        left_join(y = leg_from_baf(state = "NV"), by = "GEOID")


    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = nv_shp,
        perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        nv_shp <- rmapshaper::ms_simplify(nv_shp, keep = 0.05,
            keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    nv_shp$adj <- adjacency(nv_shp)


    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(nv_shp$adj, nv_shp$ssd_2020)
    ccm(nv_shp$adj, nv_shp$shd_2020)

    nv_shp <- nv_shp |>
        fix_geo_assignment(muni)

    write_rds(nv_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    nv_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NV} shapefile")
}

redistio::draw(nv_shp, nv_shp$ssd_2020)
redistio::draw(nv_shp, nv_shp$shd_2020)
