###############################################################################
# Download and prepare data for ```SLUG``` analysis
# ``COPYRIGHT``
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
cli_process_start("Downloading files for {.pkg IA_ssd_2020}")

path_data <- download_redistricting_file("IA", "data-raw/IA", year = 2020)

# --- Download enacted plan (Iowa Senate) ----
enacted_url <- "https://redistricting.lls.edu/wp-content/uploads/ia_2020_state_upper_2021-11-04.zip"
zip_path <- here::here("data-raw/IA/IA_enacted.zip")
dest_dir <- here::here("data-raw/IA/IA_enacted")

dir.create(dirname(zip_path), recursive = TRUE, showWarnings = FALSE)
dir.create(dest_dir,          recursive = TRUE, showWarnings = FALSE)

utils::download.file(enacted_url, zip_path, mode = "wb", quiet = TRUE)
unzip(zip_path, exdir = dest_dir)
file.remove(zip_path)

# Robustly find the .shp we just unzipped
shp_candidates <- list.files(dest_dir, pattern = "\\.shp$", full.names = TRUE, recursive = TRUE)
stopifnot(length(shp_candidates) > 0)
pick <- grep("Plan1.*Senate|Senate.*Plan1|Senate", basename(shp_candidates), ignore.case = TRUE)
path_enacted <- if (length(pick)) shp_candidates[pick[1]] else shp_candidates[1]
cli::cli_inform("Using enacted shapefile: {.file {basename(path_enacted)}}")

# --- Build shapefile & attach enacted IDs ----
shp_path   <- here::here("data-out/IA_2020/shp_vtd.rds")
perim_path <- here::here("data-out/IA_2020/perim.rds")

if (!file.exists(shp_path)) {
  cli::cli_process_start("Preparing {.strong IA} shapefile")

  ia_shp <- readr::read_csv(here::here(path_data),
                            col_types = readr::cols(GEOID20 = readr::col_character())) %>%
    join_vtd_shapefile(year = 2020) %>%
    sf::st_transform(EPSG$IA) %>%
    dplyr::rename_with(~ gsub("[0-9.]", "", .x), dplyr::starts_with("GEOID"))

  d_muni <- make_from_baf("IA", "INCPLACE_CDP", "VTD", year = 2020) %>%
    dplyr::mutate(GEOID = paste0(censable::match_fips("IA"), vtd)) %>%
    dplyr::select(-vtd)

  d_ssd <- make_from_baf("IA", "SLDU", "VTD", year = 2020) %>%
    dplyr::transmute(GEOID = paste0(censable::match_fips("IA"), vtd),
                     ssd_2010 = as.integer(sldu))

  ia_shp <- ia_shp %>%
    dplyr::left_join(d_muni, by = "GEOID") %>%
    dplyr::left_join(d_ssd,  by = "GEOID") %>%
    dplyr::mutate(county_muni = dplyr::if_else(is.na(muni), county, stringr::str_c(county, muni))) %>%
    dplyr::relocate(muni, county_muni, ssd_2010, .after = county)

  # Read enacted plan, fix geometry, match CRS, keep district field
  ssd_shp <- sf::st_read(path_enacted, quiet = TRUE) %>%
    sf::st_make_valid() %>%
    sf::st_transform(sf::st_crs(ia_shp)) %>%
    dplyr::select(DISTRICT)   # NOTE: Iowa file uses 'DISTRICT'

  ia_shp <- ia_shp %>% sf::st_make_valid()

  # Primary: spatial join by intersects
  ia_shp <- sf::st_join(ia_shp, ssd_shp, join = sf::st_intersects, left = TRUE) %>%
    dplyr::rename(ssd_2020 = DISTRICT)
  ia_shp <- ia_shp %>% dplyr::mutate(ssd_2020 = as.integer(ssd_2020))

  # Fallback: centroid-in-polygon if still bad
  if (dplyr::n_distinct(ia_shp$ssd_2020, na.rm = TRUE) <= 1L) {
    old_s2 <- sf::sf_use_s2()
    sf::sf_use_s2(FALSE)
    cent <- sf::st_point_on_surface(ia_shp)
    hit  <- sf::st_intersects(cent, ssd_shp)
    ia_shp$ssd_2020 <- as.integer(
      ssd_shp$DISTRICT[sapply(hit, function(ix) if (length(ix)) ix[1] else NA_integer_)]
    )
    sf::sf_use_s2(old_s2)
  }

  if (dplyr::n_distinct(ia_shp$ssd_2020, na.rm = TRUE) <= 1L) {
    stop("Failed to attach enacted districts (ssd_2020). Check CRS/geometry or field name.")
  }

  redistmetrics::prep_perims(shp = ia_shp, perim_path = perim_path) %>% invisible()

  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    ia_shp <- rmapshaper::ms_simplify(ia_shp, keep = 0.05, keep_shapes = TRUE) %>%
      suppressWarnings()
  }

  ia_shp$adj <- redist.adjacency(ia_shp)
  ia_shp <- ia_shp %>% fix_geo_assignment(muni)

  dir.create(dirname(shp_path), recursive = TRUE, showWarnings = FALSE)
  write_rds(ia_shp, shp_path, compress = "gz")
  cli::cli_process_done()
} else {
  ia_shp <- readr::read_rds(shp_path)
  cli_alert_success("Loaded {.strong IA} shapefile")
}
