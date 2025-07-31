###############################################################################
# Download and prepare data for UT_cd_2000 analysis
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
cli_process_start("Downloading files for {.pkg UT_cd_2000}")

path_data <- download_redistricting_file("UT", "data-raw/UT", year = 2000)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/UT_2000/shp_vtd.rds"
perim_path <- "data-out/UT_2000/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong UT} shapefile")
  # read in redistricting data
  ut_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
    # If the state is not at the VTD-level, swap in a `tinytiger::tt_*` function
    join_vtd_shapefile(year = 2000) %>%
    st_transform(EPSG$UT)
  
  ut_shp <- ut_shp %>%
    rename(muni = place) %>%
    mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
    relocate(muni, county_muni, cd_1990, .after = county)
  
  # any additional columns or data you want to add should go here
  
  # Create perimeters in case shapes are simplified
  redistmetrics::prep_perims(shp = ut_shp,
                             perim_path = here(perim_path)) %>%
    invisible()
  
  # simplifies geometry for faster processing, plotting, and smaller shapefiles
  # feel free to delete if this dependency isn't available
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    ut_shp <- rmapshaper::ms_simplify(ut_shp, keep = 0.05,
                                             keep_shapes = TRUE) %>%
      suppressWarnings()
  }
  
  # create adjacency graph
  ut_shp$adj <- redist.adjacency(ut_shp)
  
  # any custom adjacency graph edits here
  
  ut_shp <- ut_shp %>%
    fix_geo_assignment(muni)
  
  write_rds(ut_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  ut_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong UT} shapefile")
}