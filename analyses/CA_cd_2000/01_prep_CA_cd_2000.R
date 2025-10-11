###############################################################################
# Download and prepare data for CA_cd_2000 analysis
# © ALARM Project, October 2025
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
cli_process_start("Downloading files for {.pkg CA_cd_2000}")
path_data <- download_redistricting_file("CA", "data-raw/CA", year = 2000)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/CA_2000/shp_vtd.rds"
perim_path <- "data-out/CA_2000/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong CA} shapefile")
  
  # read in redistricting data
  df <- read_csv(here(path_data), col_types = cols(GEOID = "c"))
  
  # join the data
  ca_shp <- read_sf(here("data-raw/CA/ca_2000_tracts.geojson")) %>%
    mutate(GEOID = paste0(STATEFP00, COUNTYFP00, TRACTCE00),
           county = paste0(STATEFP00, COUNTYFP00)) %>%
    left_join(df, by = "GEOID") %>%
    st_transform(EPSG$CA)
  
  # data cleaning
  ca_shp <- ca_shp %>%
    mutate(
      county = dplyr::coalesce(.data[["county.x"]],
                               .data[["county.y"]],
                               substr(.data[["GEOID"]], 1, 5))
    ) %>%
    select(-any_of(c("county.x", "county.y"))) %>%
    rename(muni = place) %>%
    mutate(
      muni = as.character(muni),
      county_muni = if_else(is.na(muni), county, stringr::str_c(county, muni))
    ) %>%
    relocate(muni, county_muni, cd_1990, .after = county)
  
  redistmetrics::prep_perims(ca_shp, perim_path = here(perim_path)) %>% invisible()
  
  ca_shp <- sf::st_set_precision(ca_shp, 1) %>% sf::st_buffer(0)
  adj_full <- redist.adjacency(ca_shp)
  
  ca_shp_s <- if (requireNamespace("rmapshaper", quietly = TRUE)) {
    rmapshaper::ms_simplify(ca_shp, keep = 0.05, keep_shapes = TRUE) %>% suppressWarnings()
  } else {
    ca_shp
  }
  
  idx <- match(ca_shp_s$GEOID, ca_shp$GEOID)
  ca_shp_s$adj <- adj_full[idx]
  
  # connect island
  pairs <- list(
    c("06037599000", "06037599100"),
    c("06037599100", "06037297500")
  )
  
  for (p in pairs) {
    ia <- match(p[1], ca_shp_s$GEOID) 
    ib <- match(p[2], ca_shp_s$GEOID)
    if (!is.na(ia) && !is.na(ib)) {
      ca_shp_s$adj <- geomander::add_edge(ca_shp_s$adj, ia, ib, zero = TRUE)
    } else {
      warning(sprintf("Could not find GEOID(s): %s, %s", p[1], p[2]))
    }
  }
  
  # fix_geo_assignment 
  ca_shp_s <- ca_shp_s %>% fix_geo_assignment(muni)
  ca_shp <- ca_shp_s
  
  write_rds(ca_shp_s, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  ca_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong CA} shapefile")
}
