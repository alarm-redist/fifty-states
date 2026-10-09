###############################################################################
# Download and prepare data for `AK_leg_2020` analysis
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
cli_process_start("Downloading files for {.pkg AK_leg_2020}")

path_data <- download_redistricting_file("AK", "data-raw/AK", year = 2020)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/AK_2020/shp_vtd.rds"
perim_path <- "data-out/AK_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong AK} shapefile")
    # read in redistricting data
    ak_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        join_vtd_shapefile(year = 2020) |>
        st_transform(EPSG$AK)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("AK", "INCPLACE_CDP", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("AK"), vtd)) |>
        select(-vtd)
    d_ssd <- make_from_baf("AK", "SLDU", "VTD", year = 2020) |>
        mutate(sldu_num = vctrs::vec_group_id(sldu)) |>
        transmute(GEOID = paste0(censable::match_fips("AK"), vtd),
            ssd_2010 = as.integer(sldu_num))
    d_shd <- make_from_baf("AK", "SLDL", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("AK"), vtd),
            shd_2010 = as.integer(sldl))

    # Fix missing counties
    ak_shp$county[164:169] <- "Chugach Census Area"
    ak_shp$county[170:177] <- "Copper River Census Area"

    ak_shp <- ak_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        left_join(d_shd, by = "GEOID") |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, ssd_2010, .after = county) |>
        relocate(muni, county_muni, shd_2010, .after = county)

    # add the enacted plan
    ak_shp <- ak_shp |>
        left_join(y = leg_from_baf(state = "AK"), by = "GEOID")

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ak_shp,
        perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ak_shp <- rmapshaper::ms_simplify(ak_shp, keep = 0.05,
            keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    ak_shp$adj <- adjacency(ak_shp)

    ak_shp$adj <- ak_shp$adj |>
        add_edge(138, 149) |>
        add_edge(149, 156) |>
        add_edge(149, 153) |>
        add_edge(7, 8) |>
        add_edge(368, 373) |>
        add_edge(301, 368) |>
        add_edge(307, 368) |>
        add_edge(366, 368) |>
        add_edge(303, 368) |>
        subtract_edge(7, 291) |>
        add_edge(2, 8) |>
        add_edge(6, 8) |>
        add_edge(1, 8) |>
        add_edge(361, 375) |>
        add_edge(281, 297) |>
        add_edge(280, 297)

    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(ak_shp$adj, ak_shp$ssd_2020)
    ccm(ak_shp$adj, ak_shp$shd_2020)

    ak_shp <- ak_shp |>
        fix_geo_assignment(muni)

    # Fix ssd district numbering
    ak_shp <- ak_shp |>
        mutate(ssd_2020 = dense_rank(ssd_2020))

    write_rds(ak_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ak_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong AK} shapefile")
}
