###############################################################################
# Download and prepare data for CA_cd_2000 analysis
# © ALARM Project, September 2025
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
  ca_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
    join_vtd_shapefile(year = 2000) %>%
    st_transform(EPSG$CA)
  
  ca_shp <- ca_shp %>%
    rename(muni = place) %>%
    mutate(muni = as.character(muni),
           county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
    relocate(muni, county_muni, cd_1990, .after = county)

# Reallocate counts from two islands to nearest mainland neighbors, then drop them to keep contiguity.
  xwalk <- tibble::tibble(
    donor_GEOID = c("06037599100", "06037599000"),
    recip_GEOID = c("06037297300", "06037297500")
  )
  
  idx_donors <- match(xwalk$donor_GEOID, ca_shp$GEOID)
  idx_recip  <- match(xwalk$recip_GEOID, ca_shp$GEOID)
  stopifnot(all(!is.na(idx_donors)), all(!is.na(idx_recip)))
  
  counts_cols <- c(
    "pop","vap","ndv","nrv",
    grep("^pop_(white|black|hisp|asian|aian|nhpi|two|other)$", names(ca_shp), value = TRUE),
    grep("^vap_(white|black|hisp|asian|aian|nhpi|two|other)$", names(ca_shp), value = TRUE)
  ) |> intersect(names(ca_shp))
  
  for (k in seq_along(idx_donors)) {
    i <- idx_donors[k]; j <- idx_recip[k]
    di <- sf::st_drop_geometry(ca_shp[i, counts_cols, drop = FALSE]); di[is.na(di)] <- 0
    dj <- sf::st_drop_geometry(ca_shp[j, counts_cols, drop = FALSE]); dj[is.na(dj)] <- 0
    ca_shp[j, counts_cols] <- as.data.frame(mapply(`+`, dj, di, SIMPLIFY = FALSE))
    ca_shp[i, counts_cols] <- 0
  }
  
  ca_shp <- ca_shp %>%
    filter(!GEOID %in% xwalk$donor_GEOID)
  
  dir.create(dirname(here(perim_path)), recursive = TRUE, showWarnings = FALSE)
  redistmetrics::prep_perims(ca_shp, perim_path = here(perim_path)) %>% invisible()
  
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    ca_shp <- rmapshaper::ms_simplify(ca_shp, keep = 0.05,
                                      keep_shapes = TRUE) %>%
      suppressWarnings()
  }
  
  # create adjacency graph
  ca_shp$adj <- redist.adjacency(ca_shp)
  
  ca_shp <- ca_shp %>%
    fix_geo_assignment(muni)
  
  write_rds(ca_shp, here(shp_path), compress = "gz")
  cli_process_done()
} else {
  ca_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong CA} shapefile")
}
