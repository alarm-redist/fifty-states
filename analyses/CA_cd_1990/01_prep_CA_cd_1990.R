###############################################################################
# Download and prepare data for `CA_cd_1990` analysis
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
  devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg CA_cd_1990}")

path_data <- download_redistricting_file("CA", "data-raw/CA", year = 1990)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/CA_1990/shp_vtd.rds"
perim_path <- "data-out/CA_1990/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong CA} shapefile")
  # read in redistricting data
  ca_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) |>
    join_vtd_shapefile(year = 1990) |>
    st_transform(EPSG$CA)
  
  ca_shp <- ca_shp |>
    rename(muni = place) |>
    mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
    relocate(muni, county_muni, cd_1980, .after = county)
  
  # Create perimeters in case shapes are simplified
  redistmetrics::prep_perims(shp = ca_shp,
                             perim_path = here(perim_path)) |>
    invisible()
  
  # simplifies geometry for faster processing, plotting, and smaller shapefiles
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    ca_shp <- rmapshaper::ms_simplify(ca_shp, keep = 0.05,
                                      keep_shapes = TRUE) |>
      suppressWarnings()
  }
  
  # create adjacency graph
  ca_shp$adj <- redist.adjacency(ca_shp)
  
  # connect island
  pairs <- list(
    c("06015000001", "06015000002"),
    c("06037005990", "06037005991"),
    c("06037005991", "06037006706"),
    c("06015000199", "06013378099"),
    c("06073006299", "06013378099")
  )
  
  for (p in pairs) {
    ia <- match(p[1], ca_shp$GEOID) 
    ib <- match(p[2], ca_shp$GEOID)
    if (!is.na(ia) && !is.na(ib)) {
      ca_shp$adj <- geomander::add_edge(ca_shp$adj, ia, ib, zero = TRUE)
    }
  }
  
  write_rds(ca_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  ca_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong CA} shapefile")
}
