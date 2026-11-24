###############################################################################
# Download and prepare data for `WV_leg_2020` analysis
# © ALARM Project, May 2026
###############################################################################

suppressMessages({
    library(dplyr)
    library(readr)
    library(sf)
    library(redist)
    library(geomander)
    library(cli)
    library(here)
    library(tinytiger)
    devtools::load_all() # load utilities
})

stopifnot(utils::packageVersion("redist") >= "5.0.0.1")

# Count connected components in an adjacency graph.
# This is used only as a diagnostic check before and after the WV adjacency fix.
count_adj_components <- function(adj) {
    n <- length(adj)

    # Use a temporary 1-based copy for graph traversal.
    vals <- unlist(adj, use.names = FALSE)
    one_based <- length(vals) > 0 && max(vals, na.rm = TRUE) == n

    adj_1 <- lapply(adj, function(x) {
        x <- x[!is.na(x)]
        if (!one_based) x <- x + 1L
        x[x >= 1L & x <= n]
    })

    comp <- rep(NA_integer_, n)
    comp_id <- 0L

    # Breadth-first search assigns every row to one connected component.
    for (i in seq_len(n)) {
        if (!is.na(comp[i])) next

        comp_id <- comp_id + 1L
        queue <- i
        comp[i] <- comp_id

        while (length(queue) > 0) {
            v <- queue[1]
            queue <- queue[-1]

            nbrs <- adj_1[[v]]
            nbrs <- nbrs[is.na(comp[nbrs])]

            if (length(nbrs) > 0) {
                comp[nbrs] <- comp_id
                queue <- c(queue, nbrs)
            }
        }
    }

    list(
        n_components = comp_id,
        component = comp,
        component_sizes = sort(tabulate(comp), decreasing = TRUE)
    )
}

# Convert adjacency indices to the convention expected by redist.
# For n rows, valid stored neighbor indices should run from 0 to n - 1.
normalize_adj_indices <- function(adj) {
    n <- length(adj)
    vals <- unlist(adj, use.names = FALSE)

    if (length(vals) == 0) return(adj)

    # If the adjacency contains n, it is using 1-based row indices.
    # Subtract 1 so the largest valid stored index becomes n - 1.
    if (max(vals, na.rm = TRUE) == n) {
        adj <- lapply(adj, function(x) {
            x <- x[!is.na(x)]
            x - 1L
        })
    }

    adj
}

# Connect isolated adjacency components by adding one nearest-neighbor bridge
# edge from each smaller component to the largest component.
connect_adj_components <- function(shp, adj) {
    n <- length(adj)
    vals <- unlist(adj, use.names = FALSE)
    one_based <- length(vals) > 0 && max(vals, na.rm = TRUE) == n

    comp_info <- count_adj_components(adj)
    comp <- comp_info$component
    comp_id <- comp_info$n_components

    # If the graph is already connected, no repair is needed.
    if (comp_id == 1L) {
        attr(adj, "bridge_log") <- tibble()
        return(adj)
    }

    # Treat the largest component as the main graph.
    main_comp <- which.max(tabulate(comp))
    main_idx <- which(comp == main_comp)

    bridge_log <- tibble(
        from_row = integer(),
        to_row = integer(),
        from_geoid = character(),
        to_geoid = character(),
        from_county = character(),
        to_county = character(),
        distance = numeric()
    )

    for (this_comp in setdiff(seq_len(comp_id), main_comp)) {
        this_idx <- which(comp == this_comp)

        # Find the nearest row in the main component.
        nearest_main_pos <- st_nearest_feature(
            st_geometry(shp[this_idx, ]),
            st_geometry(shp[main_idx, ])
        )

        d <- st_distance(
            st_geometry(shp[this_idx, ]),
            st_geometry(shp[main_idx[nearest_main_pos], ]),
            by_element = TRUE
        )

        # Add one bridge edge using the shortest pair.
        k <- which.min(d)
        i <- this_idx[k]
        j <- main_idx[nearest_main_pos[k]]

        # Add bridge edges using the same indexing convention as the current
        # adjacency object. The object is normalized before ccm() and saving.
        i_adj <- if (one_based) i else i - 1L
        j_adj <- if (one_based) j else j - 1L

        adj[[i]] <- sort(unique(c(adj[[i]], j_adj)))
        adj[[j]] <- sort(unique(c(adj[[j]], i_adj)))

        # Record the added bridge edge for inspection.
        bridge_log <- bind_rows(
            bridge_log,
            tibble(
                from_row = i,
                to_row = j,
                from_geoid = shp$GEOID[i],
                to_geoid = shp$GEOID[j],
                from_county = shp$county[i],
                to_county = shp$county[j],
                distance = as.numeric(d[k])
            )
        )
    }

    attr(adj, "bridge_log") <- bridge_log
    adj
}

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg WV_leg_2020}")

path_data <- download_redistricting_file("WV", "data-raw/WV", year = 2020)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/WV_2020/shp_vtd.rds"
perim_path <- "data-out/WV_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong WV} shapefile")

    # read in redistricting data
    wv_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        join_vtd_shapefile(year = 2020) |>
        st_transform(EPSG$WV) |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("WV", "INCPLACE_CDP", "VTD", year = 2020) |>
        mutate(GEOID = paste0(censable::match_fips("WV"), vtd)) |>
        select(-vtd)

    d_ssd <- make_from_baf("WV", "SLDU", "VTD", year = 2020) |>
        transmute(
            GEOID = paste0(censable::match_fips("WV"), vtd),
            ssd_2010 = as.integer(sldu)
        )

    d_shd <- make_from_baf("WV", "SLDL", "VTD", year = 2020) |>
        transmute(
            GEOID = paste0(censable::match_fips("WV"), vtd),
            shd_2010 = as.integer(sldl)
        )

    wv_shp <- wv_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        left_join(d_shd, by = "GEOID") |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, ssd_2010, .after = county) |>
        relocate(muni, county_muni, shd_2010, .after = county)

    # add the enacted plan
    wv_shp <- wv_shp |>
        left_join(y = leg_from_baf(state = "WV", year_shd = 2023), by = "GEOID")

    # WV-specific fix: remove rows without enacted legislative assignments.
    # These rows cannot be used in enacted-plan contiguity checks.
    wv_shp <- wv_shp |>
        filter(!is.na(ssd_2020), !is.na(shd_2020))

    stopifnot(sum(is.na(wv_shp$ssd_2020)) == 0)
    stopifnot(sum(is.na(wv_shp$shd_2020)) == 0)

    wv_shp <- wv_shp |>
        fix_geo_assignment(muni)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(
        shp = wv_shp,
        perim_path = here(perim_path)
    ) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        wv_shp <- rmapshaper::ms_simplify(
            wv_shp,
            keep = 0.05,
            keep_shapes = TRUE
        ) |>
            suppressWarnings()
    }

    # create adjacency graph AFTER dropping invalid rows
    wv_adj <- adjacency(wv_shp)

    # WV-specific fix: the automatic adjacency graph has a few isolated
    # components. Add one nearest-neighbor bridge edge from each isolated
    # component to the main component before running contiguity checks.
    adj_before <- count_adj_components(wv_adj)
    wv_adj <- connect_adj_components(wv_shp, wv_adj)
    adj_after <- count_adj_components(wv_adj)

    cli_alert_info("WV adjacency components before repair: {adj_before$n_components}")
    cli_alert_info("WV adjacency components after repair: {adj_after$n_components}")
    print(attr(wv_adj, "bridge_log"))

    stopifnot(adj_after$n_components == 1L)

    # Normalize adjacency indices before redist contiguity checks.
    wv_adj <- normalize_adj_indices(wv_adj)

    stopifnot(max(unlist(wv_adj), na.rm = TRUE) <= nrow(wv_shp) - 1L)
    stopifnot(min(unlist(wv_adj), na.rm = TRUE) >= 0L)

    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(wv_adj, wv_shp$ssd_2020)
    ccm(wv_adj, wv_shp$shd_2020)

    wv_shp$adj <- wv_adj

    write_rds(wv_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    wv_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong WV} shapefile")
}
