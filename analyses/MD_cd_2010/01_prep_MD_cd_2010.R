###############################################################################
# Download and prepare data for `MD_cd_2010` analysis
# © ALARM Project, November 2025
###############################################################################

suppressMessages({
  library(dplyr)
  library(readr)
  library(sf)
  library(redist)
  library(geomander)
  library(cli)
  library(here)
  devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg MD_cd_2010}")

path_data <- download_redistricting_file("MD", "data-raw/MD", year = 2010)

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/md_2010_congress_2011-10-20_2021-12-31.zip"
path_enacted <- "data-raw/MD/MD_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "MD_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/MD/MD_enacted/Congress_2011/Congress_2011.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MD_2010/shp_vtd.rds"
perim_path <- "data-out/MD_2010/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong MD} shapefile")
  # read in redistricting data
  md_shp <- read_csv(here(path_data), col_types = cols(GEOID10 = "c")) %>%
    join_vtd_shapefile(year = 2010) %>%
    st_transform(EPSG$MD)  %>%
    rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))
  
  # add municipalities
  d_muni <- make_from_baf("MD", "INCPLACE_CDP", "VTD", year = 2010)  %>%
    mutate(GEOID = paste0(censable::match_fips("MD"), vtd)) %>%
    select(-vtd)
  d_cd <- make_from_baf("MD", "CD", "VTD", year = 2010)  %>%
    transmute(GEOID = paste0(censable::match_fips("MD"), vtd),
              cd_2000 = as.integer(cd))
  md_shp <- left_join(md_shp, d_muni, by = "GEOID") %>%
    left_join(d_cd, by = "GEOID") %>%
    mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
    relocate(muni, county_muni, cd_2000, .after = county)
  
  # add the enacted plan
  cd_shp <- st_read(here(path_enacted))
  md_shp <- md_shp %>%
    mutate(cd_2010 = as.integer(cd_shp$DISTRICT)[
      geo_match(md_shp, cd_shp, method = "area")],
      .after = cd_2000)
  
  # Create perimeters in case shapes are simplified
  redistmetrics::prep_perims(shp = md_shp,
                             perim_path = here(perim_path)) %>%
    invisible()
  
  # simplifies geometry for faster processing, plotting, and smaller shapefiles
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    md_shp <- rmapshaper::ms_simplify(md_shp, keep = 0.05,
                                      keep_shapes = TRUE) %>%
      suppressWarnings()
  }
  
  # create adjacency graph
  md_shp$adj <- redist.adjacency(md_shp)
  
  # Remove all neighbors of the three Bay pseudo-units
  bay_ids <- c("24037ZZZZZZ", "24009ZZZZZZ", "24041ZZZZZZ")
  
  for (bid in bay_ids) {
    if (!(bid %in% md_shp$GEOID)) next
    i <- match(bid, md_shp$GEOID)
    
    nbr_idx <- md_shp$adj[[i]] + 1L
    nbr_geoids <- md_shp$GEOID[nbr_idx]
    
    for (nid in nbr_geoids) {
      md_shp$adj <- geomander::subtract_edge(
        md_shp$adj, bid, nid, ids = md_shp$GEOID
      )
    }
  }
  
  # Add the specific connections listed
  connect_pairs <- list(
    c("2403702-001", "2403709-001"), # island bridge
    c("24041ZZZZZZ", "2404103-003"), # Bay → mainland
    c("24009ZZZZZZ", "2400902-004"), # Bay → mainland
    c("24037ZZZZZZ", "2403707-001")  # Bay → mainland
  )
  
  for (p in connect_pairs) {
    u <- match(p[1], md_shp$GEOID)
    v <- match(p[2], md_shp$GEOID)
    if (!is.na(u) && !is.na(v)) {
      md_shp$adj <- geomander::add_edge(md_shp$adj, u, v, zero = TRUE)
    }
  }
  
  md_shp <- md_shp %>%
    fix_geo_assignment(muni)
  
  write_rds(md_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  md_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong MD} shapefile")
}
