###############################################################################
# Download and prepare data for `LA_leg_2020` analysis
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
cli_process_start("Downloading files for {.pkg LA_leg_2020}")

path_data <- download_redistricting_file("LA", "data-raw/LA", year = 2020)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/LA_2020/shp_vtd.rds"
perim_path <- "data-out/LA_2020/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong LA} shapefile")
  # read in redistricting data
  la_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
    join_vtd_shapefile(year = 2020) |>
    st_transform(EPSG$LA)  |>
    rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

  # add municipalities
  d_muni <- make_from_baf("LA", "INCPLACE_CDP", "VTD", year = 2020)  |>
    mutate(GEOID = paste0(censable::match_fips("LA"), vtd)) |>
    select(-vtd)
  d_ssd <- make_from_baf("LA", "SLDU", "VTD", year = 2020)  |>
    transmute(GEOID = paste0(censable::match_fips("LA"), vtd),
              ssd_2010 = as.integer(sldu))
  d_shd <- make_from_baf("LA", "SLDL", "VTD", year = 2020)  |>
    transmute(GEOID = paste0(censable::match_fips("LA"), vtd),
              shd_2010 = as.integer(sldl))

  la_shp <- la_shp |>
    left_join(d_muni, by = "GEOID") |>
    left_join(d_ssd, by = "GEOID") |>
    left_join(d_shd, by = "GEOID") |>
    mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
    relocate(muni, county_muni, ssd_2010, .after = county) |>
    relocate(muni, county_muni, shd_2010, .after = county)

  # add the enacted plan
  la_shp <- la_shp |>
    left_join(y = leg_from_baf(state = "LA"), by = "GEOID") |>
    mutate(ssd_2020 = case_match(
      GEOID,
      "22051ZZZZZZ" ~ "009",
      "22071ZZZZZZ" ~ "004",
      "22103ZZZZZZ" ~ "011",
      "22105ZZZZZZ" ~ "037",
      .default = ssd_2020
    )) |>
    mutate(ssd_2020 = as.integer(ssd_2020))

  # Create perimeters in case shapes are simplified
  redistmetrics::prep_perims(shp = la_shp,
                             perim_path = here(perim_path)) |>
    invisible()

  # simplifies geometry for faster processing, plotting, and smaller shapefiles
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    la_shp <- rmapshaper::ms_simplify(la_shp, keep = 0.05,
                                      keep_shapes = TRUE) |>
      suppressWarnings()
  }

  # create adjacency graph
  la_shp$adj <- adjacency(la_shp)

  # add bridges
  la_shp$adj <- la_shp$adj |>
    geomander::add_edge(
      v1 = match("2212100001C", la_shp$GEOID),
      v2 = match("22047000021", la_shp$GEOID),
      zero = TRUE
    ) |>
    geomander::add_edge(
      v1 = match("220570005-2", la_shp$GEOID),
      v2 = match("22057002-14", la_shp$GEOID),
      zero = TRUE
    )

  # check max number of connected components
  # 1 is one fully connected component, more is worse
  ccm(la_shp$adj, la_shp$ssd_2020)
  ccm(la_shp$adj, la_shp$shd_2020)

  la_shp <- la_shp |>
    fix_geo_assignment(muni)

  write_rds(la_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  la_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong LA} shapefile")
}

