###############################################################################
# Download and prepare data for LA_cd_2000 analysis
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
cli_process_start("Downloading files for {.pkg LA_cd_2000}")
path_data <- download_redistricting_file("LA", "data-raw/LA", year = 2000)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/LA_2000/shp_vtd.rds"
perim_path <- "data-out/LA_2000/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong LA} shapefile")
  # read in redistricting data
  la_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
    # If the state is not at the VTD-level, swap in a `tinytiger::tt_*` function
    join_vtd_shapefile(year = 2000) %>%
    st_transform(EPSG$LA)
  
  la_shp <- la_shp %>%
    rename(muni = place) %>%
    mutate(muni = as.character(muni), county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
    relocate(muni, county_muni, cd_1990, .after = county)
  
  # Create perimeters in case shapes are simplified
  redistmetrics::prep_perims(shp = la_shp,
                             perim_path = here(perim_path)) %>%
    invisible()
  
  # simplifies geometry for faster processing, plotting, and smaller shapefiles
  # feel free to delete if this dependency isn't available
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    la_shp <- rmapshaper::ms_simplify(la_shp, keep = 0.05,
                                      keep_shapes = TRUE) %>%
      suppressWarnings()
  }
  
  # create adjacency graph
  la_shp$adj <- redist.adjacency(la_shp)
  
  la_shp <- la_shp %>%
    fix_geo_assignment(muni)
  
  write_rds(la_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  la_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong LA} shapefile")
}
