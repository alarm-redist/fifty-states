###############################################################################
# Download and prepare data for `NE_leg_2020` analysis
# <U+00A9> ALARM Project, April 2026
###############################################################################
suppressMessages({
    library(dplyr)
    library(readr)
    library(sf)
    library(redist)
    library(geomander)
    library(cli)
    library(here)
    library(stringr)
    library(tinytiger)
    devtools::load_all() # load utilities
})

stopifnot(utils::packageVersion("redist") >= "5.0.0.1")

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg NE_leg_2020}")

path_data <- download_redistricting_file("NE", "data-raw/NE", year = 2020)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NE_2020/shp_vtd.rds"
perim_path <- "data-out/NE_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NE} shapefile")
    # read in redistricting data
    ne_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        join_vtd_shapefile(year = 2020) |>
        st_transform(EPSG$NE)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("NE", "INCPLACE_CDP", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("NE"), vtd)) |>
        select(-vtd)
    d_ssd <- make_from_baf("NE", "SLDU", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("NE"), vtd),
            ssd_2010 = as.integer(sldu))

    # Nebraska has a unicameral legislature, so its enacted legislative
    # districts are only available through the upper-chamber BAF geography.
    d_leg <- {
        d_plan <- baf::baf(state = "NE", year = 2023, geographies = "ssd")$SSD2022 |>
            transmute(BLOCKID = GEOID, ssd_20 = as.integer(SLDUST))
        d_vtd <- baf::baf(state = "NE", year = 2023, geographies = "VTD")[[1]] |>
            transmute(
                BLOCKID = BLOCKID,
                GEOID = paste0(str_sub(BLOCKID, 1, 2), COUNTYFP, DISTRICT)
            )

        left_join(d_plan, d_vtd, by = "BLOCKID") |>
            group_by(GEOID) |>
            summarize(ssd_2020 = Mode(ssd_20), .groups = "drop")
    }

    ne_shp <- ne_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, ssd_2010, .after = county)

    # add the enacted plan
    ne_shp <- ne_shp |>
        left_join(d_leg, by = "GEOID")

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ne_shp,
        perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ne_shp <- rmapshaper::ms_simplify(ne_shp, keep = 0.05,
            keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    ne_shp$adj <- adjacency(ne_shp)

    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(ne_shp$adj, ne_shp$ssd_2020)

    ne_shp <- ne_shp |>
        fix_geo_assignment(muni)

    write_rds(ne_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ne_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NE} shapefile")
}

# To visualize the enacted map, use:
# redistio::draw(ne_shp, ne_shp$ssd_2020)

