###############################################################################
# Download and prepare data for `FL_cd_1990` analysis
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
cli_process_start("Downloading files for {.pkg FL_cd_1990}")

path_data <- download_redistricting_file("FL", "data-raw/FL", year = 1990)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/FL_1990/shp_vtd.rds"
perim_path <- "data-out/FL_1990/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong FL} shapefile")
  # read in redistricting data
  fl_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) |>
    mutate(state = as.character(state)) |>
    join_vtd_shapefile(year = 1990) |>
    st_transform(EPSG$FL)
  
  fl_shp <- fl_shp |>
    rename(muni = place) |>
    mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
    relocate(muni, county_muni, cd_1980, .after = county)
  
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
  fl_shp$adj <- redist.adjacency(fl_shp)
  
  write_rds(fl_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  fl_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong FL} shapefile")
}
