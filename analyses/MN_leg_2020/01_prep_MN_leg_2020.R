###############################################################################
# Download and prepare data for `MN_leg_2020` analysis
# © ALARM Project, December 2025
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
cli_process_start("Downloading files for {.pkg MN_leg_2020}")

path_data <- download_redistricting_file("MN", "data-raw/MN", year = 2020)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MN_2020/shp_vtd.rds"
perim_path <- "data-out/MN_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong MN} shapefile")
    # read in redistricting data
    mn_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        join_vtd_shapefile(year = 2020) |>
        st_transform(EPSG$MN)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("MN", "INCPLACE_CDP", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("MN"), vtd)) |>
        select(-vtd)
    d_ssd <- make_from_baf("MN", "SLDU", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("MN"), vtd),
            ssd_2010 = as.integer(sldu))
    d_shd <- make_from_baf("MN", "SLDL", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("MN"), vtd),
            shd_2010 = as.integer(sldl))

    mn_shp <- mn_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        left_join(d_shd, by = "GEOID") |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, ssd_2010, .after = county) |>
        relocate(muni, county_muni, shd_2010, .after = county)

    # add the enacted plan
    mn_shp <- mn_shp |>
        left_join(y = leg_from_baf(state = "MN"), by = "GEOID")

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = mn_shp,
        perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        mn_shp <- rmapshaper::ms_simplify(mn_shp, keep = 0.05,
            keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    mn_shp$adj <- adjacency(mn_shp)

    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(mn_shp$adj, mn_shp$ssd_2020)
    ccm(mn_shp$adj, mn_shp$shd_2020)

    mn_shp <- mn_shp |>
        fix_geo_assignment(muni)

    write_rds(mn_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    mn_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong MN} shapefile")
}

# Function to fix irregular Minnesota shd district names
mn_shd_numbering <- function(x) {
    num <- as.integer(sub("[A-Z]", "", x))
    letter <- substr(x, nchar(x), nchar(x))
    2*num - ifelse(letter == "A", 1L, 0L)
}

mn_shp$shd_2020 <- mn_shd_numbering(mn_shp$shd_2020)
