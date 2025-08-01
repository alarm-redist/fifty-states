###############################################################################
# Download and prepare data for MI_cd_2000 analysis
# © ALARM Project, July 2025
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
cli_process_start("Downloading files for {.pkg MI_cd_2000}")
path_data <- download_redistricting_file("MI", "data-raw/MI", year = 2000)
cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MI_2000/shp_vtd.rds"
perim_path <- "data-out/MI_2000/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong MI} shapefile")
  # read in redistricting data
  mi_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
    # If the state is not at the VTD-level, swap in a `tinytiger::tt_*` function
    join_vtd_shapefile(year = 2000) %>%
    st_transform(EPSG$MI)
  
  mi_shp <- mi_shp %>%
    rename(muni = place) %>%
    mutate(muni = as.character(muni), county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
    relocate(muni, county_muni, cd_1990, .after = county)
  
  # any additional columns or data you want to add should go here
  # add a stronger county constraint
  
  
  # Create perimeters in case shapes are simplified
  redistmetrics::prep_perims(shp = mi_shp,
                             perim_path = here(perim_path)) %>%
    invisible()
  
  # simplifies geometry for faster processing, plotting, and smaller shapefiles
  # feel free to delete if this dependency isn't available
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    mi_shp <- rmapshaper::ms_simplify(mi_shp, keep = 0.05,
                                      keep_shapes = TRUE) %>%
      suppressWarnings()
  }
  
  # create adjacency graph
  mi_shp$adj <- redist.adjacency(mi_shp)
  
  # any custom adjacency graph edits here
  
  mi_shp <- mi_shp %>%
    fix_geo_assignment(muni)
  
  write_rds(mi_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  mi_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong MI} shapefile")
}
