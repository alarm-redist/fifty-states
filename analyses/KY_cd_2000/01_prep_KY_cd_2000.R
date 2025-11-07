###############################################################################
# Download and prepare data for KY_cd_2000 analysis
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
cli_process_start("Downloading files for {.pkg KY_cd_2000}")
path_data <- download_redistricting_file("KY", "data-raw/KY", year = 2000)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/KY_2000/shp_vtd.rds"
perim_path <- "data-out/KY_2000/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong KY} shapefile")
  
  # read in redistricting data
  df <- read_csv(here(path_data), col_types = cols(GEOID = "c"))
  
  # join the data
  ky_shp <- read_sf(here("data-raw/KY/KY_tracts_2000.geojson")) %>%
    mutate(GEOID = paste0(STATEFP00, COUNTYFP00, TRACTCE00),
           county = paste0(STATEFP00, COUNTYFP00)) %>%
    left_join(df, by = "GEOID") %>%
    st_transform(EPSG$KY)
  
  # data cleaning
  ky_shp <- ky_shp %>%
    mutate(
      county = dplyr::coalesce(.data[["county.x"]],
                               .data[["county.y"]],
                               substr(.data[["GEOID"]], 1, 5))
    ) %>%
    select(-any_of(c("county.x", "county.y")))
  
  ky_shp <- ky_shp %>%
    rename(muni = place) %>%
    mutate(muni = as.character(muni),
           county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
    relocate(muni, county_muni, cd_1990, .after = county)
  
  redistmetrics::prep_perims(ky_shp, perim_path = here(perim_path)) %>% invisible()
  
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    ky_shp <- rmapshaper::ms_simplify(ky_shp, keep = 0.05,
                                      keep_shapes = TRUE) %>%
      suppressWarnings()
  }
  
  # create adjacency graph
  ky_shp$adj <- redist.adjacency(ky_shp)
  
  ky_shp <- ky_shp %>%
    fix_geo_assignment(muni)
  
  write_rds(ky_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  ky_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong KY} shapefile")
}
