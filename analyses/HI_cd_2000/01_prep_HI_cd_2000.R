###############################################################################
# Download and prepare data for `HI_cd_2000` analysis
# © ALARM Project, September 2026
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
    library(tibble)
    devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg HI_cd_2000}")

path_data <- download_redistricting_file("HI", "data-raw/HI", year = 2000)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/HI_2000/shp_vtd.rds"
perim_path <- "data-out/HI_2000/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong HI} shapefile")

    # read in redistricting data
    hi_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) |>
        mutate(state = as.character(state)) |>
        join_vtd_shapefile(year = 2000) |>
        st_transform(EPSG$HI)

    hi_shp <- hi_shp |>
        rename(muni = place) |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, cd_1990, .after = county)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(
        shp = hi_shp,
        perim_path = here(perim_path)
    ) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        hi_shp <- rmapshaper::ms_simplify(
            hi_shp, keep = 0.05,
            keep_shapes = TRUE
        ) |>
            suppressWarnings()
    }

    # create adjacency graph
    hi_shp$adj <- redist.adjacency(hi_shp)

    # Remove Honolulu edges without land contact in the coastal audit.
    drop_edges <- tribble(
        ~v1, ~v2,
        "15003001503", "15003001603",
        "15003001605", "15003001703",
        "15003003001", "15003003201",
        "15003003203", "15003003402",
        "15003003203", "15003003603",
        "15003003203", "15003003604",
        "15003003203", "15003004104",
        "15003003604", "15003004104",
        "15003004101", "15003004104",
        "15003004603", "15003004604",
        "15003004801", "15003004902",
        "15003004801", "15003005006",
        "15003004802", "15003005006"
    )
    stopifnot(!anyDuplicated(hi_shp$GEOID))
    for (r in seq_len(nrow(drop_edges))) {
        p <- match(c(drop_edges$v1[r], drop_edges$v2[r]), hi_shp$GEOID)
        stopifnot(!anyNA(p))
        hi_shp$adj[[p[1]]] <- setdiff(hi_shp$adj[[p[1]]], p[2] - 1L)
        hi_shp$adj[[p[2]]] <- setdiff(hi_shp$adj[[p[2]]], p[1] - 1L)
    }

    # connect islands
    island_codes <- tribble(
        ~v1,           ~v2,
        "15007001305", "15003ZZZZZZ",
        "15003ZZZZZZ", "15005ZZZZZZ"
    )
    v1 <- match(island_codes$v1, hi_shp$GEOID)
    v2 <- match(island_codes$v2, hi_shp$GEOID)
    stopifnot(!anyNA(c(v1, v2)),
        identical(as.character(hi_shp$county[v1]), c("007", "003")),
        identical(as.character(hi_shp$county[v2]), c("003", "005")))
    hi_shp$adj <- add_edge(hi_shp$adj, v1, v2, zero = TRUE)
    hi_shp$adj <- add_edge(hi_shp$adj, v2, v1, zero = TRUE)
    
    county_chain <- tribble(
        ~c1,   ~c2,
        "005", "009",
        "009", "001"
    )

    cent_xy <- st_coordinates(st_centroid(st_geometry(hi_shp)))

    closest_pair_between_counties <- function(county_a, county_b) {
        ia <- which(hi_shp$county == county_a)
        ib <- which(hi_shp$county == county_b)

        xa <- cent_xy[ia, , drop = FALSE]
        xb <- cent_xy[ib, , drop = FALSE]

        best_d2 <- Inf
        best_i <- NA_integer_
        best_j <- NA_integer_

        for (k in seq_along(ia)) {
            dx <- xb[, 1] - xa[k, 1]
            dy <- xb[, 2] - xa[k, 2]
            d2 <- dx*dx + dy*dy
            m <- which.min(d2)

            if (d2[m] < best_d2) {
                best_d2 <- d2[m]
                best_i <- ia[k]
                best_j <- ib[m]
            }
        }
        c(best_i, best_j)
    }

    for (r in seq_len(nrow(county_chain))) {
        p <- closest_pair_between_counties(
            county_chain$c1[r],
            county_chain$c2[r]
        )

        hi_shp$adj <- add_edge(hi_shp$adj, p[1], p[2], zero = TRUE)
        hi_shp$adj <- add_edge(hi_shp$adj, p[2], p[1], zero = TRUE)
    }

    hi_shp$adj <- lapply(seq_along(hi_shp$adj), function(i) {
        as.integer(sort(setdiff(hi_shp$adj[[i]], i - 1L)))
    })

    write_rds(hi_shp, here(shp_path), compress = "gz")
    cli_process_done()

} else {
    hi_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong HI} shapefile")
}
