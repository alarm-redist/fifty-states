###############################################################################
# Download and prepare data for `FL_cd_2000` analysis
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
  library(stringr)
  devtools::load_all() # load utilities
})

state <- "FL"

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg FL_cd_2000}")

path_data <- download_redistricting_file("FL", "data-raw/FL", year = 2000)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/FL_2000/shp_vtd.rds"
perim_path <- "data-out/FL_2000/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong FL} shapefile")
  # read in redistricting data
  fl_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) |>
    join_vtd_shapefile(year = 2000) |>
    st_transform(EPSG$FL)
  
  fl_shp <- fl_shp |>
    rename(muni = place) |>
    mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
    relocate(muni, county_muni, .after = county)
  
  # Create perimeters in case shapes are simplified
  redistmetrics::prep_perims(shp = fl_shp,
                             perim_path = here(perim_path)) |>
    invisible()
  
  # simplifies geometry for faster processing, plotting, and smaller shapefiles
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    fl_shp <- rmapshaper::ms_simplify(fl_shp, keep = 0.05,
                                      keep_shapes = TRUE) |>
      suppressWarnings()
  }
  
  # Add CVAP counts
  path_cvap <- here(paste0("data-raw/", state, "/cvap.rds"))
  
  if (!file.exists(path_cvap)) {
    bg <- readRDS("data-raw/FL/blockgr_2000.rds")
    blks <- censable::build_dec(geography = "block", year = 2000, state = "FL", geometry = FALSE)
    cvap <- cvap::cvap_distribute(bg, blks, wts = "vap")
    vtd_baf <- read_csv("data-raw/FL/BlockAssign_ST12_FL_VTD.txt", col_types = "ccc")
    
    cvap <- cvap %>%
      left_join(vtd_baf %>% rename(GEOID = BLOCKID),
                by = "GEOID")
    
    cvap <- cvap %>%
      mutate(GEOID = paste0(COUNTYFP, "00", DISTRICT)) %>%
      select(GEOID, starts_with("cvap"))
    cvap <- cvap %>%
      group_by(GEOID) %>%
      summarize(across(.fns = sum))
    saveRDS(cvap, path_cvap, compress = "xz")
  } else {
    cvap <- read_rds(path_cvap)
  }
  
  cvap <- cvap %>% mutate(GEOID = paste0("12", GEOID))
  
  fl_shp <- fl_shp %>%
    left_join(cvap, by = "GEOID") %>%
    st_as_sf()
  
  if (mean(!is.na(fl_shp$cvap)) < 0.9) {
    cli::cli_warn("CVAP join looks low: {round(100*mean(!is.na(fl_shp$cvap)), 1)}% matched. Check GEOID format.")
  }
  
  # Create perimeters in case shapes are simplified
  redistmetrics::prep_perims(shp = fl_shp,
                             perim_path = here(perim_path)) %>%
    invisible()
  
  # simplifies geometry for faster processing, plotting, and smaller shapefiles
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    fl_shp <- rmapshaper::ms_simplify(fl_shp, keep = 0.05,
                                      keep_shapes = TRUE) %>%
      suppressWarnings()
  }
  
  # create adjacency graph
  fl_shp$adj <- redist.adjacency(fl_shp)
  
  write_rds(fl_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  fl_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong FL} shapefile")
}
