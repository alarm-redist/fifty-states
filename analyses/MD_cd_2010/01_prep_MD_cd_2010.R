###############################################################################
# Download and prepare data for `MD_cd_2010` analysis
# © ALARM Project, August 2025
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
  
  # ensure valid geoms; keep all polygons (including bay/water)
  suppressMessages(sf::sf_use_s2(FALSE))
  md_shp <- sf::st_zm(md_shp, drop = TRUE, what = "ZM")
  md_shp <- sf::st_make_valid(md_shp)
  
  write_rds(md_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  md_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong MD} base shapefile (unchanged geometry)")
}

# Build adjacency on full layer, then edit via subtract_edge()
cli_process_start("Building full adjacency and editing edges (no shape edits)")

# Build adjacency once on the full layer
md_shp$adj <- redist.adjacency(md_shp)
attr(md_shp$adj, "zero_indexed") <- TRUE

# Identify Bay units
bay_ids <- c("24037ZZZZZZ", "24009ZZZZZZ", "24041ZZZZZZ")

# For each Bay unit, remove edges to its neighbors using subtract_edge()
for (bid in bay_ids) {
  if (!(bid %in% md_shp$GEOID)) next
  i <- match(bid, md_shp$GEOID)
  nbr_idx    <- md_shp$adj[[i]] + 1L        
  nbr_geoids <- md_shp$GEOID[nbr_idx]
  
  for (nid in nbr_geoids) {
    md_shp$adj <- geomander::subtract_edge(
      md_shp$adj, bid, nid, ids = md_shp$GEOID
    )
  }
}

# connect an island
isle_u <- "2403702-001"
isle_v <- "2403709-001"
u <- match(isle_u, md_shp$GEOID)
v <- match(isle_v, md_shp$GEOID)
if (!is.na(u) && !is.na(v)) {
  md_shp$adj <- add_edge(md_shp$adj, u, v, zero = TRUE)
}

# build the map from a land-only map while leaving the saved shapefile untouched to satisfy redist_map()
is_bay   <- md_shp$GEOID %in% bay_ids
land_idx <- which(!is_bay)

relabel <- setNames(seq_along(land_idx), land_idx)

adj_land <- lapply(land_idx, function(i) {
  nbr <- md_shp$adj[[i]]
  if (length(nbr)) {
    nbr <- nbr + 1L                   
    nbr <- nbr[nbr %in% land_idx]     
    unname(relabel[as.character(nbr)]) - 1L  
  } else integer(0)
})
attr(adj_land, "zero_indexed") <- TRUE

md_land       <- md_shp[land_idx, , drop = FALSE]
md_land$adj   <- adj_land

cd_2010_land <- md_shp$cd_2010[land_idx]

cli_process_done()
