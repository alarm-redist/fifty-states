###############################################################################
# Download and prepare data for `FL_leg_2020` analysis
# © ALARM Project, May 2026
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
cli_process_start("Downloading files for {.pkg FL_leg_2020}")

path_data <- download_redistricting_file("FL", "data-raw/FL", year = 2020)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/FL_2020/shp_vtd.rds"
perim_path <- "data-out/FL_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong FL} shapefile")
    # read in redistricting data
    fl_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        join_vtd_shapefile(year = 2020) |>
        st_transform(EPSG$FL)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("FL", "INCPLACE_CDP", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("FL"), vtd)) |>
        select(-vtd)
    d_ssd <- make_from_baf("FL", "SLDU", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("FL"), vtd),
            ssd_2010 = as.integer(sldu))
    d_shd <- make_from_baf("FL", "SLDL", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("FL"), vtd),
            shd_2010 = as.integer(sldl))

    fl_shp <- fl_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        left_join(d_shd, by = "GEOID") |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, ssd_2010, .after = county) |>
        relocate(muni, county_muni, shd_2010, .after = county)

    # add the enacted plan
    fl_shp <- fl_shp |>
        left_join(y = leg_from_baf(state = "FL"), by = "GEOID")

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = fl_shp,
        perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        fl_shp <- rmapshaper::ms_simplify(fl_shp, keep = 0.05,
            keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    fl_shp$adj <- adjacency(fl_shp)

    # Manually add bridges for separated VTD pieces that are used
    # together in the enacted legislative districts.
    fl_shp$adj <- fl_shp$adj |>
      add_edge(
        v1 = c(
          "12101000044", "1209500630C", "12057000920",
          "12103000254", "12101000045", "12101000046",
          "12101000047", "1209500433B", "12097000153",
          "12103000019", "12115000060", "12099000735",
          "12099000705", "1201100X045", "12099000233"
        ),
        v2 = c(
          "12101000043", "12095000631", "12057000914",
          "12103000265", "12101000043", "12101000043",
          "12101000043", "1209500440C", "1209500126A",
          "12057000940", "12115000069", "12099000704",
          "12099000731", "1201100X019", "12099000234"
        ),
        ids = fl_shp$GEOID
      )

    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(fl_shp$adj, fl_shp$ssd_2020)
    ccm(fl_shp$adj, fl_shp$shd_2020)

    fl_shp <- fl_shp |>
        fix_geo_assignment(muni)

    # compute merge groups
    fl_shp$merge_group <- contiguity_merges(fl_shp)

    write_rds(fl_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    fl_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong FL} shapefile")
}

