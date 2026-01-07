###############################################################################
# Download and prepare data for WV_cd_1990 analysis
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
  library(tinytiger)
  library(stringr)
  devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg WV_cd_1990}")
path_data <- download_redistricting_file("WV", "data-raw/WV", year = 1990)
cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/WV_1990/shp_vtd.rds"
perim_path <- "data-out/WV_1990/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong WV} shapefile")
  # read in redistricting data
  wv_df <- read_csv(here(path_data), col_types = cols(GEOID = "c"))
  if (!"county" %in% names(wv_df)) {
    wv_df <- wv_df %>% mutate(county = str_sub(GEOID, 3, 5))
  }

  # Aggregate once by county, summing numerics and excluding cd_.
  wv_df_cnty <- wv_df %>%
    group_by(county) %>%
    summarise(
      across(where(is.numeric) & !matches("^cd_"), ~ sum(.x, na.rm = TRUE)),
      .groups = "drop"
    )

  cnty_sf <- tigris::counties(state = "WV", year = 1990, cb = TRUE) %>%
    st_as_sf() %>%
    st_transform(EPSG$WV) %>%
    transmute(county = sprintf("%03s", COUNTYFP), geometry)

  wv_shp <- cnty_sf %>%
    left_join(wv_df_cnty %>% mutate(county = sprintf("%03s", county)),
              by = "county")

  # Assign each county the most frequent cd_1990 from its VTDs
  # Function to calculate mode
  stat_mode <- function(x) {
    ux <- na.omit(unique(x))
    ux[which.max(tabulate(match(x, ux)))]
  }

  # Mode cd_1990 per county from original VTD-level data
  county_cd1990 <- wv_df %>%
    mutate(county = sprintf("%03s", county)) %>%
    group_by(county) %>%
    summarise(cd_1990 = stat_mode(cd_1990), .groups = "drop")

  # Join mode cd_1990 back to county-level shapefile
  wv_shp <- wv_shp %>%
    left_join(county_cd1990, by = "county")

  # Drop unwanted columns if present
  wv_shp <- wv_shp %>% select(-any_of(c("mcd", "shd", "ssd")))

  # Create perimeters in case shapes are simplified
  redistmetrics::prep_perims(shp = wv_shp,
                             perim_path = here(perim_path)) %>%
    invisible()

  # simplifies geometry for faster processing, plotting, and smaller shapefiles
  # feel free to delete if this dependency isn't available
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    wv_shp <- rmapshaper::ms_simplify(wv_shp, keep = 0.05,
                                      keep_shapes = TRUE) %>%
      suppressWarnings()
  }

  # create adjacency graph
  wv_shp$adj <- redist.adjacency(wv_shp)

  write_rds(wv_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  wv_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong WV} shapefile")
}
