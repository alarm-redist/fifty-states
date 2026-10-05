###############################################################################
# Download and prepare data for `MA_leg_2020` analysis
# © ALARM Project, January 2026
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

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg MA_leg_2020}")

path_data <- download_redistricting_file("MA", "data-raw/MA", year = 2020)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MA_2020/shp_vtd.rds"
perim_path <- "data-out/MA_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong MA} shapefile")
    # read in redistricting data
    ma_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        join_vtd_shapefile(year = 2020) |>
        st_transform(EPSG$MA)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("MA", "INCPLACE_CDP", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("MA"), vtd)) |>
        select(-vtd)
    d_ssd <- make_from_baf("MA", "SLDU", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("MA"), vtd),
            ssd_2010 = as.integer(sldu))
    d_shd <- make_from_baf("MA", "SLDL", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("MA"), vtd),
            shd_2010 = as.integer(sldl)) |>
        mutate(shd_2010 = dense_rank(shd_2010)) |>
        ### placeholder vtds assigning to shds
        mutate(shd_2010 = case_when(
            GEOID == "25001ZZZZZZ" ~ 4,
            GEOID == "25005ZZZZZZ" ~ 18,
            GEOID == "25009ZZZZZZ" ~ 28,
            GEOID == "25023ZZZZZZ" ~ 115,
            TRUE ~ shd_2010
        ))

    ma_shp <- ma_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        left_join(d_shd, by = "GEOID") |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, ssd_2010, .after = county) |>
        relocate(muni, county_muni, shd_2010, .after = county)

    # add the enacted plan
    ma_shp <- ma_shp |>
        left_join(y = leg_from_baf(state = "MA"), by = "GEOID") |>
        mutate(ssd_2020 = str_extract(ssd_2020, "(?<=D)\\d+"))

    ma_shp <- ma_shp |>
        mutate(shd_2020 = case_when(
            GEOID == "25001ZZZZZZ" ~ 4L,
            GEOID == "25005ZZZZZZ" ~ 18L,
            GEOID == "25009ZZZZZZ" ~ 28L,
            GEOID == "25023ZZZZZZ" ~ 113L,
            TRUE ~ as.integer(shd_2020)
        )) |>
        mutate(ssd_2020 = as.numeric(ssd_2020),
            ssd_2010 = as.numeric(ssd_2010),
            shd_2010 = as.numeric(shd_2010),
            shd_2020 = as.numeric(shd_2020)
        )

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ma_shp,
        perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ma_shp <- rmapshaper::ms_simplify(ma_shp, keep = 0.05,
            keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    ma_shp$adj <- adjacency(ma_shp) |>
        subtract_edge(66, 151, zero = FALSE) |>
        subtract_edge(1622, 1558, zero = FALSE) |>
        subtract_edge(1622, 294, zero = FALSE) |>
        subtract_edge(1622, 1566, zero = FALSE) |>
        add_edge(1)


    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(ma_shp$adj, ma_shp$ssd_2020)
    ccm(ma_shp$adj, ma_shp$shd_2020)

    ma_shp <- ma_shp |>
        fix_geo_assignment(muni)

    check_graph_issues <- function(adj) {
        n <- length(adj)

        # Self-loops
        self_loops <- do.call(
            rbind,
            lapply(seq_len(n), function(i) {
                u <- i - 1
                nbrs <- adj[[i]]
                bad <- nbrs[nbrs == u]
                if (length(bad) == 0) return(NULL)
                data.frame(vertex = u)
            })
        )

        # Duplicates within a vertex list
        repeated_within_vertex <- do.call(
            rbind,
            lapply(seq_len(n), function(i) {
                u <- i - 1
                nbrs <- adj[[i]]
                dups <- unique(nbrs[duplicated(nbrs)])
                if (length(dups) == 0) return(NULL)
                data.frame(vertex = u, duplicated_neighbor = dups)
            })
        )

        # Directed edge list
        directed_edges <- do.call(
            rbind,
            lapply(seq_len(n), function(i) {
                u <- i - 1
                nbrs <- adj[[i]]
                if (length(nbrs) == 0) return(NULL)
                data.frame(from = u, to = nbrs)
            })
        )

        # Undirected multiplicities
        undirected_edges <- transform(
            directed_edges,
            u = pmin(from, to),
            v = pmax(from, to)
        )
        undirected_counts <- aggregate(
            rep(1, nrow(undirected_edges)),
            by = list(u = undirected_edges$u, v = undirected_edges$v),
            FUN = sum
        )
        names(undirected_counts)[3] <- "count"

        duplicated_undirected_edges <- subset(undirected_counts, count > 2)

        # Asymmetry: edge u->v exists but v->u does not
        edge_keys <- paste(directed_edges$from, directed_edges$to, sep = "_")
        reverse_keys <- paste(directed_edges$to, directed_edges$from, sep = "_")
        asymmetric <- directed_edges[!(reverse_keys %in% edge_keys), , drop = FALSE]

        list(
            self_loops = self_loops,
            repeated_within_vertex = repeated_within_vertex,
            duplicated_undirected_edges = duplicated_undirected_edges,
            asymmetric_edges = asymmetric
        )
    }

    check_graph_issues(ma_shp$adj)

    make_adj_symmetric <- function(adj, sort_neighbors = TRUE) {
        n <- length(adj)

        # Coerce to integer vectors
        adj2 <- lapply(adj, function(x) as.integer(x))

        # Add missing reverse edges
        for (u in seq_len(n)) {
            u0 <- u - 1
            nbrs <- adj2[[u]]

            if (length(nbrs) == 0) next

            for (v0 in nbrs) {
                v <- v0 + 1

                if (v < 1 || v > n) {
                    stop(sprintf("Neighbor %d in adj[[%d]] is out of bounds for graph of size %d", v0, u, n))
                }

                if (!(u0 %in% adj2[[v]])) {
                    adj2[[v]] <- c(adj2[[v]], u0)
                }
            }
        }

        # Remove duplicates and optionally sort
        adj2 <- lapply(adj2, function(x) {
            x <- unique(as.integer(x))
            if (sort_neighbors) x <- sort(x)
            x
        })

        adj2
    }

    ma_shp$adj <- make_adj_symmetric(ma_shp$adj)

    write_rds(ma_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ma_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong MA} shapefile")
}
