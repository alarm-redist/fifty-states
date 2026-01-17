###############################################################################
# Download and prepare data for `MD_cd_1990` analysis
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
  devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg MD_cd_1990}")

path_data <- download_redistricting_file("MD", "data-raw/MD", year = 1990)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MD_1990/shp_vtd.rds"
perim_path <- "data-out/MD_1990/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong MD} shapefile")
  # read in redistricting data
  md_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) |>
    mutate(state = as.character(state)) |>
    join_vtd_shapefile(year = 1990) |>
    st_transform(EPSG$MD)
  
  md_shp <- md_shp |>
    rename(muni = place) |>
    mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
    relocate(muni, county_muni, cd_1980, .after = county)
  
  # Create perimeters in case shapes are simplified
  redistmetrics::prep_perims(shp = md_shp,
                             perim_path = here(perim_path)) |>
    invisible()
  
  # simplifies geometry for faster processing, plotting, and smaller shapefiles
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    md_shp <- rmapshaper::ms_simplify(md_shp, keep = 0.05,
                                      keep_shapes = TRUE) |>
      suppressWarnings()
  }
  
  # create adjacency graph
  md_shp$adj <- redist.adjacency(md_shp)
  
  # Identify Bay units
  bay_ids <- c(
    "24037009962",
    "24037009959",
    "24037009958",
    "24009008610",
    "24009008608",
    "24009008605",
    "24009008603",
    "24009008604",
    "24003708098",
    "24003007070",
    "24003007012",
    "24003007026",
    "24003730901",
    "24003730902",
    "24003731002",
    "24003731303",
    "24005004519",
    "24025003015",
    "24025003025",
    "24025003063",
    "24025003062"
  )
  
  # For each Bay unit, remove edges to its neighbors using subtract_edge()
  md_shp <- md_shp |>
    mutate(GEOID = as.character(GEOID))
  
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
  
  # Connect bay precincts 
  left_ids <- c(
    "24037009962",
    "24037009959",
    "24037009958",
    "24009008610",
    "24009008608",
    "24009008605",
    "24009008603",
    "24009008604",
    "24003708098",
    "24003007070",
    "24003007012",
    "24003007026",
    "24003730901",
    "24003730902",
    "24003731002",
    "24003731303",
    "24005004519",
    "24025003015",
    "24025003025",
    "24025003063",
    "24025003062"
  )
  
  right_ids <- c(
    "24037009961",
    "24037009960",
    "24037009957",
    "24009008609",
    "24009008607",
    "24009008606",
    "24009860298",
    "24009860298",
    "24033800602",
    "24003007014",
    "24003007011",
    "24003007025",
    "24003007308",
    "24003731103",
    "24003731001",
    "24003731202",
    "24005004510",
    "24005451801",
    "24025003024",
    "24025302801",
    "24025003061"
  )
  
  stopifnot(length(left_ids) == length(right_ids))
  
  # ensure GEOID is character
  md_shp <- md_shp |>
    mutate(GEOID = as.character(GEOID))
  
  for (k in seq_along(left_ids)) {
    u <- match(left_ids[k], md_shp$GEOID)
    v <- match(right_ids[k], md_shp$GEOID)
    
    if (!is.na(u) && !is.na(v)) {
      md_shp$adj <- add_edge(md_shp$adj, u, v, zero = TRUE)
    }
  }
  
  write_rds(md_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  md_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong MD} shapefile")
}
