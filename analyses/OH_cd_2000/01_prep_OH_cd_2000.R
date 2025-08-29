###############################################################################
# Download and prepare data for OH_cd_2000 analysis
# © ALARM Project, August 2025
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
  library(stringr) 
  devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg OH_cd_2000}")
path_data <- download_redistricting_file("OH", "data-raw/OH", year = 2000)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/OH_2000/shp_vtd.rds"
perim_path <- "data-out/OH_2000/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong OH} shapefile")
  
  # read in redistricting data
  oh_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
    join_vtd_shapefile(year = 2000) %>%
    st_transform(EPSG$OH)
  
  oh_shp <- oh_shp %>%
    rename(muni = place) %>%
    mutate(muni = as.character(muni),
           county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
    relocate(muni, county_muni, cd_1990, .after = county)
  
  redistmetrics::prep_perims(oh_shp, here(perim_path)) %>% invisible()
  
  # simplifies geometry for faster processing, plotting, and smaller shapefiles
  # feel free to delete if this dependency isn't available
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    oh_shp <- rmapshaper::ms_simplify(oh_shp, keep = 0.05,
                                      keep_shapes = TRUE) %>%
      suppressWarnings()
  }
  
  # create adjacency graph
  oh_shp$adj <- redist.adjacency(oh_shp)
  
  oh_shp <- oh_shp %>%
    fix_geo_assignment(muni)
  
  write_rds(oh_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  oh_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong OH} shapefile")
}
