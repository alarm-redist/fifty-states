###############################################################################
# Download and prepare data for MD_cd_2000 analysis
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
  library(stringr)
  devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg MD_cd_2000}")
path_data <- download_redistricting_file("MD", "data-raw/MD", year = 2000)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MD_2000/shp_vtd.rds"
perim_path <- "data-out/MD_2000/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong MD} shapefile")
  # read in redistricting data
  md_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
    # If the state is not at the VTD-level, swap in a `tinytiger::tt_*` function
    join_vtd_shapefile(year = 2000) %>%
    st_transform(EPSG$MD)
  
  md_shp <- md_shp %>%
    rename(muni = place) %>%
    mutate(muni = as.character(muni), county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
    relocate(muni, county_muni, cd_1990, .after = county)
  
  # Exclude Bay units
  bay_ids <- c(
    "24003ZZZZZZ","24005ZZZZZZ","24009ZZZZZZ",
    "24029ZZZZZZ","24037ZZZZZZ","24041ZZZZZZ"
  )
  
  md_bay  <- md_shp[md_shp$GEOID %in% bay_ids, ]
  md_land <- md_shp[!md_shp$GEOID %in% bay_ids, ]
  
  sf::sf_use_s2(FALSE)
  md_land <- st_make_valid(md_land)
  adj_full <- redist.adjacency(md_land)
  
  # Create perimeters in case shapes are simplified
  redistmetrics::prep_perims(shp = md_land, perim_path = here(perim_path)) %>% invisible()
  
  # simplifies geometry for faster processing, plotting, and smaller shapefiles
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    md_land <- rmapshaper::ms_simplify(md_land, keep = 0.05, keep_shapes = TRUE) %>% suppressWarnings()
  }
  
  md_land$adj <- adj_full
  md_shp <- md_land
  
  # Connect an island
  key_col <- "GEOID"
  
  island_codes <- tibble::tribble(
    ~v1,             ~v2,
    "2403702-001",   "2403709-001" 
  )
  
  island_codes$v1 <- match(island_codes$v1, md_shp[[key_col]])
  island_codes$v2 <- match(island_codes$v2, md_shp[[key_col]])
  
  for (i in seq_len(nrow(island_codes))) {
    md_shp$adj <- md_shp$adj %>%
      add_edge(island_codes$v1[i], island_codes$v2[i], zero = TRUE)
  }
  
  md_shp <- md_shp %>%
    fix_geo_assignment(muni)
  
  write_rds(md_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  md_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong MD} shapefile")
}

