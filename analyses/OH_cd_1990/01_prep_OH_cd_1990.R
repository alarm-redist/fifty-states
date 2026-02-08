###############################################################################
# Download and prepare data for `OH_cd_1990` analysis
# © ALARM Project, December 2025
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
cli_process_start("Downloading files for {.pkg OH_cd_1990}")

path_data <- download_redistricting_file("OH", "data-raw/OH", year = 1990)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path   <- "data-out/OH_1990/shp_vtd.rds"
perim_path <- "data-out/OH_1990/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong OH} shapefile")
  # read in redistricting data
  oh_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) |>
    mutate(state = as.character(state)) |>
    join_vtd_shapefile(year = 1990) |>
    st_transform(EPSG$OH)
  
  oh_shp <- oh_shp |>
    rename(muni = place) |>
    mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
    relocate(muni, county_muni, cd_1980, .after = county)
  
  # Create perimeters in case shapes are simplified
  redistmetrics::prep_perims(shp = oh_shp,
                             perim_path = here(perim_path)) |>
    invisible()
  
  # simplifies geometry for faster processing, plotting, and smaller shapefiles
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    oh_shp <- rmapshaper::ms_simplify(oh_shp, keep = 0.05,
                                      keep_shapes = TRUE) |>
      suppressWarnings()
  }
  
  # create adjacency graph
  oh_shp$adj <- redist.adjacency(oh_shp)
  
  # connect precicnts
  pairs <- list( c("39035103399", "39035001032") ) 
  for (p in pairs) { 
    ia <- match(p[1], oh_shp$GEOID) 
    ib <- match(p[2], oh_shp$GEOID) 
    if (!is.na(ia) && !is.na(ib)) { 
      oh_shp$adj <- geomander::add_edge(oh_shp$adj, ia, ib, zero = TRUE)
    } 
  }
  
  write_rds(oh_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  oh_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong OH} shapefile")
}
