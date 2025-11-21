###############################################################################
# Download and prepare data for NH_cd_2000 analysis 
# © ALARM Project, November 2025
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
  devtools::load_all()
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg NH_cd_2000}")
path_data <- download_redistricting_file("NH", "data-raw/NH", year = 2000, overwrite = TRUE)
cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path   <- "data-out/NH_2000/shp_vtd.rds"  
perim_path <- "data-out/NH_2000/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong NH} shapefile")
  
  pl <- read_csv(here(path_data), col_types = cols(GEOID = "c"))
  
  mcd_2000 <- tinytiger::tt_county_subdivisions("NH", 2000) %>%
    mutate(
      GEOID    = paste0(STATEFP00, COUNTYFP00, COUSUBFP00),  
      mcd_name = NAME00                                      
    )
  
  cty_2000 <- tinytiger::tt_counties("NH", 2000) %>%
    sf::st_drop_geometry() %>%   
    select(STATEFP00, COUNTYFP00, county_name = NAME00)
  
  nh_shp <- mcd_2000 %>%
    left_join(cty_2000, by = c("STATEFP00", "COUNTYFP00")) %>%
    left_join(pl, by = "GEOID") %>%
    mutate(
      county = coalesce(county, county_name),  
      place  = coalesce(county_subdivision, mcd_name)      
    ) %>%
    st_transform(EPSG$NH)
  
  nh_shp <- nh_shp %>%
    rename(muni = place) %>%
    mutate(
      muni        = as.character(muni),
      county_muni = if_else(is.na(muni), county, str_c(county, muni))
    ) %>%
    relocate(muni, county_muni, cd_1990, .after = county)

  # Create perimeters in case shapes are simplified
  redistmetrics::prep_perims(shp = nh_shp, perim_path = here(perim_path)) %>% invisible()

  # simplifies geometry for faster processing, plotting, and smaller shapefiles
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    nh_shp <- rmapshaper::ms_simplify(nh_shp, keep = 0.05, keep_shapes = TRUE) %>%
      suppressWarnings()
  }

  # create adjacency graph
  nh_shp$adj <- redist.adjacency(nh_shp)
  nh_shp <- nh_shp %>% fix_geo_assignment(muni)
  
  write_rds(nh_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  nh_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong NH} shapefile")
}
