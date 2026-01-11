###############################################################################
# Download and prepare data for `MN_cd_1990` analysis
# © ALARM Project, January 2026
###############################################################################

suppressMessages({
  library(dplyr)
  library(readr)
  library(sf)
  library(redist)
  library(geomander)
  library(baf)
  library(cli)
  library(here)
  devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg MN_cd_1990}")

path_data <- download_redistricting_file("MN", "data-raw/MN", year = 1990)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MN_1990/shp_vtd.rds"
perim_path <- "data-out/MN_1990/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong MN} shapefile")
  # read in redistricting data
  mn_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) |>
    mutate(state = as.character(state)) |>
    join_vtd_shapefile(year = 1990) |>
    st_transform(EPSG$MN)
  
  mn_shp <- mn_shp |>
    rename(muni = place) |>
    mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
    relocate(muni, county_muni, cd_1980, .after = county)
  
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
  mn_shp$adj <- redist.adjacency(mn_shp)
  
  write_rds(mn_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  mn_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong MN} shapefile")
}
