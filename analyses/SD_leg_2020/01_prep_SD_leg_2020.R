###############################################################################
# Download and prepare data for `SD_leg_2020` analysis
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
cli_process_start("Downloading files for {.pkg SD_leg_2020}")

path_data <- download_redistricting_file("SD", "data-raw/SD", year = 2020)

# TODO other files here (as necessary). All paths should start with `path_`
# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/SD_2020/shp_vtd.rds"
perim_path <- "data-out/SD_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong SD} shapefile")
    # read in redistricting data
    sd_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        join_vtd_shapefile(year = 2020) |>
        st_transform(EPSG$SD)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

# OLD shd_2010 and ssd_2010: ssd_2010 = as.integer(sldu); had to change

    # add municipalities
    d_muni <- make_from_baf("SD", "INCPLACE_CDP", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("SD"), vtd)) |>
        select(-vtd)
    d_ssd <- make_from_baf("SD", "SLDU", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("SD"), vtd),
                  ssd_2010 = as.integer(sldu))
    d_shd <- make_from_baf("SD", "SLDL", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("SD"), vtd),
                  shd_2010 = as.integer(sldl))

    sd_shp <- sd_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        left_join(d_shd, by = "GEOID") |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, ssd_2010, .after = county) |>
        relocate(muni, county_muni, shd_2010, .after = county)

    # add the enacted plan
    sd_shp <- sd_shp |>
        left_join(y = leg_from_baf(state = "SD"), by = "GEOID")


    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = sd_shp,
                             perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        sd_shp <- rmapshaper::ms_simplify(sd_shp, keep = 0.05,
                                                 keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    sd_shp$adj <- adjacency(sd_shp)

    # TODO any custom adjacency graph edits here

    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(sd_shp$adj, sd_shp$ssd_2020)
    ccm(sd_shp$adj, sd_shp$shd_2020)

    sd_shp <- sd_shp |>
        fix_geo_assignment(muni)

    write_rds(sd_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    sd_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong SD} shapefile")
}

# TODO visualize the enacted maps using:
# redistio::draw(sd_shp, sd_shp$ssd_2020)
# redistio::draw(sd_shp, sd_shp$shd_2020)
