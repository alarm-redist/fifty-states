###############################################################################
# Download and prepare data for WV_cd_2000 analysis
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
cli_process_start("Downloading files for {.pkg WV_cd_2000}")
path_data <- download_redistricting_file("WV", "data-raw/WV", year = 2000)
cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/WV_2000/shp_vtd.rds"
perim_path <- "data-out/WV_2000/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong WV} shapefile")
  # read in redistricting data
  wv_df <- read_csv(here(path_data), col_types = cols(GEOID = "c"))
  if (!"county" %in% names(wv_df)) {
    wv_df <- wv_df %>% mutate(county = str_sub(GEOID, 3, 5))
  }
  
  # Aggregate once, keeping cd_1990 and cd_2000. 
  wv_df_cnty <- wv_df %>%
    group_by(county) %>%
    summarise(
      across(where(is.numeric) & !matches("^cd_1990$|^cd_2000$"),
             ~ sum(.x, na.rm = TRUE)),
      cd_1990 = first(cd_1990),
      cd_2000 = first(cd_2000),
      .groups = "drop"
    )
  
  cnty_sf <- tt_counties("WV", year = 2000) %>%
    st_transform(EPSG$WV) %>%
    transmute(county = COUNTYFP00, geometry)
  
  wv_shp <- cnty_sf %>% left_join(wv_df_cnty, by = "county")

  # Prepare lists of column types
  col_names <- as.vector(colnames(wv_shp))
  mergeable_col_names <- c("state", "county", "cd_2000", "cd_1990")
  sf_col_names <- c("muni", "county_muni", "GEOID", "geometry", "vtd")
  summable_col_names <- col_names[!col_names %in% c(mergeable_col_names, sf_col_names)]
  
  # Extract mergeable columns (non-summed)
  data_without_sf <- st_drop_geometry(wv_shp)
  cols_to_merge <- select(
    data_without_sf[!duplicated(data_without_sf$county), ],
    any_of(mergeable_col_names)
  )
  
  # Sum numeric columns by county
  merged_county_sf <- wv_shp %>%
    group_by(county) %>%
    summarize(across(any_of(summable_col_names), sum), .groups = "drop")
  
  # Merge numeric and non-numeric data
  wv_shp <- merge(merged_county_sf, cols_to_merge, by = "county")
  
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
  
  wv_shp <- wv_shp %>% fix_geo_assignment(county)
  
  write_rds(wv_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  wv_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong WV} shapefile")
}
