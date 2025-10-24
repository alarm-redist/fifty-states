###############################################################################
# Download and prepare data for IN_ssd_2020 analysis
# COPYRIGHT
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

# Download necessary files for analysis ------
cli_process_start("Downloading files for {.pkg IN_ssd_2020}")

# Download redistricting data

path_data <- download_redistricting_file("IN", "data-raw/IN", year = 2020)


# Download the enacted plan (Indiana Senate 2020)

enacted_url <- "https://redistricting.lls.edu/wp-content/uploads/in_2020_state_upper_2022-11-08.zip"
zip_path <- here::here("data-raw/IN/IN_enacted.zip")
dest_dir <- here::here("data-raw/IN/IN_enacted")

# Create directories
dir.create(dirname(zip_path), recursive = TRUE, showWarnings = FALSE)
dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

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
shp_path   <- here::here("data-out/IN_2020/shp_vtd.rds")
perim_path <- here::here("data-out/IN_2020/perim.rds")

if (!file.exists(shp_path)) {
    cli::cli_process_start("Preparing {.strong IN} shapefile")

    # 1) Read in VTD base
    suppressPackageStartupMessages(library(tigris))
    options(tigris_use_cache = TRUE, tigris_class = "sf")

    vtd_sf <- tigris::voting_districts(state = "IN", year = 2020, class = "sf") %>%
        sf::st_transform(EPSG$IN)

    in_csv <- readr::read_csv(here::here(path_data),
        col_types = readr::cols(GEOID20 = readr::col_character()))

    in_shp <- vtd_sf %>%
        dplyr::left_join(in_csv, by = "GEOID20") %>%
        dplyr::rename_with(~ gsub("[0-9.]", "", .x), dplyr::starts_with("GEOID"))

    # 2) Add municipalities and legacy senate IDs (from BAF)
    d_muni <- make_from_baf("IN", "INCPLACE_CDP", "VTD", year = 2020) %>%
        dplyr::mutate(GEOID = paste0(censable::match_fips("IN"), vtd)) %>%
        dplyr::select(-vtd)

    d_ssd10 <- make_from_baf("IN", "SLDU", "VTD", year = 2020) %>%
        dplyr::transmute(GEOID = paste0(censable::match_fips("IN"), vtd),
            ssd_2010 = as.integer(sldu))

    in_shp <- in_shp %>%
        dplyr::left_join(d_muni,  by = "GEOID") %>%
        dplyr::left_join(d_ssd10, by = "GEOID") %>%
        dplyr::mutate(county_muni = dplyr::if_else(is.na(muni), county, stringr::str_c(county, muni))) %>%
        dplyr::relocate(muni, county_muni, ssd_2010, .after = county) %>%
        sf::st_make_valid()

    # 3) Read enacted Senate plan and auto-detect the district column
    sen_shp <- sf::st_read(path_enacted, quiet = TRUE) %>%
        sf::st_make_valid() %>%
        sf::st_transform(sf::st_crs(in_shp))

    cand_names <- c("DISTRICT", "District", "DIST", "SLDUST", "SLDUST20", "NAME", "NAME10", "SLDU", "SLDU20")
    district_col <- cand_names[cand_names %in% names(sen_shp)][1]

    if (is.na(district_col)) {
        # If no common column names found, fall back to numeric-like columns with 20–100 unique values
        int_like <- names(sen_shp)[vapply(sen_shp, function(col) {
            is.integer(col) || is.numeric(col) ||
                (is.character(col) && all(grepl("^\\d+$", col[!is.na(col)])))
        }, logical(1))]
        pick_by_card <- int_like[vapply(int_like, function(nm) {
            x <- sen_shp[[nm]]
            x <- suppressWarnings(as.integer(as.character(x)))
            k <- dplyr::n_distinct(x, na.rm = TRUE)
            isTRUE(k >= 20L & k <= 100L) # expected range of Senate seats
        }, logical(1))]
        district_col <- pick_by_card[1]
    }
    stopifnot(!is.na(district_col))
    sen_shp <- dplyr::select(sen_shp, !!district_col)

    # 4) Spatial join: primary method is intersects; fallback is centroid-in-polygon
    in_shp <- sf::st_join(in_shp, sen_shp, join = sf::st_intersects, left = TRUE)
    names(in_shp)[names(in_shp) == district_col] <- "ssd_2020"
    in_shp <- in_shp %>% dplyr::mutate(ssd_2020 = suppressWarnings(as.integer(as.character(ssd_2020))))

    if (dplyr::n_distinct(in_shp$ssd_2020, na.rm = TRUE) <= 1L) {
        old_s2 <- sf::sf_use_s2()
        sf::sf_use_s2(FALSE)
        cent <- sf::st_point_on_surface(in_shp)
        hit  <- sf::st_intersects(cent, sen_shp)

        dist_vals <- suppressWarnings(as.integer(as.character(sen_shp[[district_col]])))
        in_shp$ssd_2020 <- as.integer(
            vapply(hit, function(ix) if (length(ix)) dist_vals[ix[1]] else NA_integer_, integer(1))
        )
        sf::sf_use_s2(old_s2)
    }

    if (dplyr::n_distinct(in_shp$ssd_2020, na.rm = TRUE) <= 1L) {
        stop("Failed to attach enacted districts (ssd_2020). Check CRS/geometry or field name.")
    }

    # 5) Compute perimeters, simplify geometry, build adjacency
    redistmetrics::prep_perims(shp = in_shp, perim_path = perim_path) %>% invisible()

    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        in_shp <- rmapshaper::ms_simplify(in_shp, keep = 0.05, keep_shapes = TRUE) %>% suppressWarnings()
    }

    in_shp$adj <- redist.adjacency(in_shp)
    in_shp <- in_shp %>% fix_geo_assignment(muni)

    dir.create(dirname(shp_path), recursive = TRUE, showWarnings = FALSE)
    readr::write_rds(in_shp, shp_path, compress = "gz")
    cli::cli_process_done()
} else {
    in_shp <- readr::read_rds(shp_path)
    cli_alert_success("Loaded {.strong IN} shapefile")
}
