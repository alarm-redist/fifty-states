###############################################################################
# Download and prepare data for `OR_cd_1990` analysis
# © ALARM Project, January 2026
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
  library(tigris)
  library(ggplot2)
  devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg OR_cd_1990}")

path_data <- download_redistricting_file("OR", "data-raw/OR", year = 1990)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/OR_1990/shp_vtd.rds"
perim_path <- "data-out/OR_1990/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong OR} shapefile")
  # read in redistricting data
  or_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) |>
    mutate(state = as.character(state)) |>
    join_vtd_shapefile(year = 1990) |>
    st_transform(EPSG$OR)
  
  or_shp <- or_shp |>
    rename(muni = place) |>
    mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
    relocate(muni, county_muni, cd_1980, .after = county)
  
  # Create perimeters in case shapes are simplified
  redistmetrics::prep_perims(shp = or_shp,
                             perim_path = here(perim_path)) |>
    invisible()
  
  # simplifies geometry for faster processing, plotting, and smaller shapefiles
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    or_shp <- rmapshaper::ms_simplify(or_shp, keep = 0.05,
                                      keep_shapes = TRUE) |>
      suppressWarnings()
  }

  # create adjacency graph
  or_shp$adj <- redist.adjacency(or_shp)
  
  # Remove adjacency between neighboring counties not connected by state or federal highways
  or_shp$adj <- or_shp$adj %>%
    seam_rip(shp = or_shp, admin = "county", seam = c("015", "033")) %>%  # Curry – Josephine
    seam_rip(shp = or_shp, admin = "county", seam = c("053", "041")) %>%  # Polk – Lincoln
    seam_rip(shp = or_shp, admin = "county", seam = c("003", "039")) %>%  # Benton – Lane
    seam_rip(shp = or_shp, admin = "county", seam = c("047", "031")) %>%  # Marion – Jefferson
    seam_rip(shp = or_shp, admin = "county", seam = c("047", "065")) %>%  # Marion – Wasco
    seam_rip(shp = or_shp, admin = "county", seam = c("063", "001")) %>%  # Wallowa – Baker
    seam_rip(shp = or_shp, admin = "county", seam = c("049", "023")) %>%  # Morrow – Grant
    seam_rip(shp = or_shp, admin = "county", seam = c("013", "023")) %>%  # Crook – Grant
    seam_rip(shp = or_shp, admin = "county", seam = c("017", "025")) %>%  # Deschutes – Harney
    seam_rip(shp = or_shp, admin = "county", seam = c("017", "043"))      # Deschutes – Linn
  
  write_rds(or_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  or_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong OR} shapefile")
}
