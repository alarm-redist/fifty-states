###############################################################################
# Download and prepare data for HI_cd_2000 analysis
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
  library(tinytiger) 
  devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg HI_cd_2000}")

path_data <- download_redistricting_file("HI", "data-raw/HI", year = 2000)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/HI_2000/shp_vtd.rds"
perim_path <- "data-out/HI_2000/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong HI} shapefile")
  # read in redistricting data
  hi_shp <- tt_counties(state = "HI", year = 2000) %>%
    rename(county = COUNTYFP) %>%
    st_transform(EPSG$HI)
  
  hi_shp <- hi_shp %>%
    mutate(
      muni        = NA_character_, 
      county_muni = county
    )
  
  # any additional columns or data you want to add should go here
  
  # Create perimeters in case shapes are simplified
  redistmetrics::prep_perims(shp = hi_shp,
                             perim_path = here(perim_path)) %>%
    invisible()
  
  # simplifies geometry for faster processing, plotting, and smaller shapefiles
  # feel free to delete if this dependency isn't available
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    hi_shp <- rmapshaper::ms_simplify(hi_shp, keep = 0.05,
                                      keep_shapes = TRUE) %>%
      suppressWarnings()
  }
  
  # create adjacency graph
  hi_shp$adj <- redist.adjacency(hi_shp)
  
  # Connect islands
  
  island_codes <- tribble(
    ~v1,             ~v2,
    "007","003",  
    "003","005",
    "005","009",   
    "009","001"   
  )
  
  island_codes$v1 <- match(island_codes$v1, hi_shp$county)
  island_codes$v2 <- match(island_codes$v2, hi_shp$county)
  
  for (i in seq_len(nrow(island_codes))) {
    hi_shp$adj <- hi_shp$adj %>%
      add_edge(island_codes$v1[i], island_codes$v2[i], zero = TRUE)
  }
  
  hi_shp <- hi_shp %>%
    fix_geo_assignment(county_muni)
  
  write_rds(hi_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  hi_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong HI} shapefile")
}
