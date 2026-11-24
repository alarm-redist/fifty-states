###############################################################################
# Download and prepare data for `MD_leg_2020` analysis
# © ALARM Project, August 2026
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
cli_process_start("Downloading files for {.pkg MD_leg_2020}")

path_data <- download_redistricting_file("MD", "data-raw/MD", year = 2020)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MD_2020/shp_vtd.rds"
perim_path <- "data-out/MD_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong MD} shapefile")
    # block-level redistricting data
    md_shp <- PL94171::pl_read(PL94171::pl_url("MD", year = 2020)) |>
        PL94171::pl_subset(sumlev = "750") |>
        PL94171::pl_select_standard() |>
        rename(GEOID20 = GEOID) |>
        left_join(y = tigris::blocks("MD", year = 2020), by = "GEOID20") |>
        st_as_sf() |>
        st_transform(EPSG$MD) |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add block-level geographic assignments from 2020 BAFs
    baf_2020 <- PL94171::pl_get_baf("MD", cache_to = here("data-raw/MD/MD_baf.rds"))
    d_muni <- baf_2020$INCPLACE_CDP |>
        transmute(GEOID = BLOCKID, muni = PLACEFP)
    d_ssd <- baf_2020$SLDU |>
        transmute(GEOID = BLOCKID, ssd_2010 = as.integer(na_if(DISTRICT, "ZZZ")))
    d_shd <- baf_2020$SLDL |>
        transmute(GEOID = BLOCKID, shd_2010 = na_if(DISTRICT, "ZZZ"))
    d_vtd <- baf_2020$VTD |>
        transmute(GEOID = BLOCKID,
            vtd_2020 = paste0(censable::match_fips("MD"), COUNTYFP, DISTRICT))

    md_shp <- md_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        left_join(d_shd, by = "GEOID") |>
        left_join(d_vtd, by = "GEOID")

    # add the enacted plan
    d_ssd_2020 <- baf::baf(state = "MD", year = 2023, geographies = "ssd")$SSD2022 |>
        transmute(GEOID = as.character(GEOID), ssd_2020 = as.integer(SLDUST))
    d_shd_2020 <- baf::baf(state = "MD", year = 2023, geographies = "shd")$SHD2022 |>
        transmute(GEOID = as.character(GEOID), shd_2020 = as.character(SLDLST))

    md_shp <- md_shp |>
        left_join(d_ssd_2020, by = "GEOID") |>
        left_join(d_shd_2020, by = "GEOID")

    # Create units for VTDs that cross enacted SSD or SHD boundaries
    split_vtds <- md_shp |>
        st_drop_geometry() |>
        group_by(vtd_2020) |>
        summarise(split_vtd = n_distinct(ssd_2020) > 1L |
            n_distinct(shd_2020) > 1L, .groups = "drop")

    vtd_elections <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        rename(vtd_2020 = GEOID20) |>
        select(vtd_2020, pre_16_rep_tru:ndv)
    election_cols <- setdiff(names(vtd_elections), "vtd_2020")

    md_shp <- md_shp |>
        left_join(split_vtds, by = "vtd_2020") |>
        group_by(vtd_2020) |>
        mutate(vtd_block_pop = sum(pop, na.rm = TRUE)) |>
        ungroup() |>
        left_join(vtd_elections, by = "vtd_2020") |>
        mutate(
            unit_id = if_else(
                split_vtd,
                stringr::str_c(vtd_2020, "_",
                    stringr::str_pad(ssd_2020, 2, "left", "0"), "_",
                    shd_2020),
                vtd_2020
            ),
            block_pop_share = if_else(
                vtd_block_pop > 0, pop/vtd_block_pop, 0)
        ) |>
        mutate(across(all_of(election_cols), ~ coalesce(.x, 0)*block_pop_share))

    md_shp <- md_shp |>
        group_by(unit_id) |>
        summarize(
            vtd_2020 = Mode(vtd_2020),
            split_vtd = any(split_vtd),
            ssd_2010 = Mode(ssd_2010),
            shd_2010 = Mode(shd_2010),
            ssd_2020 = Mode(ssd_2020),
            shd_2020 = Mode(shd_2020),
            muni = Mode(muni),
            state = Mode(state),
            county = Mode(county),
            across(any_of(c(
                "pop", "pop_hisp", "pop_white", "pop_black", "pop_aian",
                "pop_asian", "pop_nhpi", "pop_other", "pop_two",
                "vap", "vap_hisp", "vap_white", "vap_black", "vap_aian",
                "vap_asian", "vap_nhpi", "vap_other", "vap_two",
                "ALAND20", "AWATER20", election_cols
            )), \(x) sum(x, na.rm = TRUE)),
            geometry = st_union(geometry),
            .groups = "drop"
        ) |>
        rename(GEOID = unit_id,
            area_land = ALAND20,
            area_water = AWATER20
        ) |>
        mutate(
            county_muni = if_else(
                is.na(muni), county, stringr::str_c(county, muni)
            )
        ) |>
        relocate(
            muni, county_muni, vtd_2020, split_vtd,
            ssd_2010, shd_2010, ssd_2020, shd_2020,
            .after = county
        )

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = md_shp,
        perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        md_shp <- rmapshaper::ms_simplify(md_shp, keep = 0.05, keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    md_shp$adj <- adjacency(md_shp)

    # prevent Bay water units from connecting opposite shores
    bay_vtds <- c("24009ZZZZZZ", "24015ZZZZZZ", "24017ZZZZZZ",
        "24025ZZZZZZ", "24037ZZZZZZ", "24039ZZZZZZ",
        "24041ZZZZZZ", "24047ZZZZZZ", "24510ZZZZZZ")

    bay_ids <- md_shp$GEOID[md_shp$vtd_2020 %in% bay_vtds]

    # remove all existing edges from every Bay atom
    for (bid in bay_ids) {
        i <- match(bid, md_shp$GEOID)
        nbr_ids <- md_shp$GEOID[md_shp$adj[[i]] + 1L]

        for (nid in nbr_ids) {
            md_shp$adj <- subtract_edge(
                md_shp$adj, bid, nid, ids = md_shp$GEOID
            )
        }
    }

    # connect each Bay atom to the nearest non-Bay atom
    # in the same county, enacted SSD, and enacted SHD
    bay_edge_additions <- tibble::tibble(
        from = character(),
        to = character()
    )

    for (bid in bay_ids) {
        i <- match(bid, md_shp$GEOID)

        candidates <- which(
            !(md_shp$GEOID %in% bay_ids) &
                md_shp$county == md_shp$county[[i]] &
                md_shp$ssd_2020 == md_shp$ssd_2020[[i]] &
                md_shp$shd_2020 == md_shp$shd_2020[[i]]
        )

        nearest <- st_nearest_feature(
            md_shp[i, ],
            md_shp[candidates, ]
        )

        bay_edge_additions <- bind_rows(
            bay_edge_additions,
            tibble::tibble(
                from = bid,
                to = md_shp$GEOID[candidates[[nearest]]]
            )
        )
    }

    for (k in seq_len(nrow(bay_edge_additions))) {
        md_shp$adj <- add_edge(
            md_shp$adj,
            bay_edge_additions$from[[k]],
            bay_edge_additions$to[[k]],
            ids = md_shp$GEOID
        )
    }

    # remove additional cross-Bay edges identified by visual review
    md_shp$adj <- md_shp$adj |>
        subtract_edge(547, 1132) |>
        subtract_edge(549, 1132) |>
        subtract_edge(547, 1131) |>
        subtract_edge(549, 1131) |>
        subtract_edge(550, 1131) |>
        subtract_edge(111, 1131) |>
        subtract_edge(161, 1131) |>
        subtract_edge(115, 1131) |>
        subtract_edge(111, 1776) |>
        subtract_edge(160, 1776) |>
        subtract_edge(161, 1776) |>
        subtract_edge(115, 1776) |>
        subtract_edge(160, 1778) |>
        subtract_edge(181, 1778) |>
        subtract_edge(223, 1778) |>
        subtract_edge(223, 1779) |>
        subtract_edge(237, 1779) |>
        subtract_edge(241, 1779) |>
        subtract_edge(234, 1779)

    # add land and island connections identified by visual review
    # (restore enacted-district contiguity)
    md_shp$adj <- md_shp$adj |>
        add_edge(664, 984) |>
        add_edge(555, 1820) |>
        add_edge(1786, 1829) |>
        add_edge(1841, 1846) |>
        add_edge(1845, 1846) |>
        add_edge(2008, 2020) |>
        add_edge(635, 636) |>

        # repair SSD 27 / SHD 27B
        add_edge("2400903-006", "2403304-001_27_27B", ids = md_shp$GEOID) |>

        # repair SSD 46 / SHD 046
        add_edge("2451025-008", "2451025-011", ids = md_shp$GEOID)


    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(md_shp$adj, md_shp$ssd_2020)
    ccm(md_shp$adj, md_shp$shd_2020)

    md_shp <- md_shp |>
        fix_geo_assignment(muni)

    write_rds(md_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    md_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong MD} shapefile")
}
