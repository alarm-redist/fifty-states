###############################################################################
# Download and prepare data for `ND_leg_2020` analysis
# © ALARM Project, July 2026
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
cli_process_start("Downloading files for {.pkg ND_leg_2020}")

path_data <- download_redistricting_file("ND", "data-raw/ND", year = 2020)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/ND_2020/shp_vtd.rds"
perim_path <- "data-out/ND_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong ND} shapefile")
    # block-level redistricting data
    nd_shp <- PL94171::pl_read(PL94171::pl_url("ND", year = 2020)) |>
        PL94171::pl_subset(sumlev = "750") |>
        PL94171::pl_select_standard() |>
        rename(GEOID20 = GEOID) |>
        left_join(y = tigris::blocks("ND", year = 2020), by = "GEOID20") |>
        st_as_sf() |>
        st_transform(EPSG$ND) |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add block-level geographic assignments from 2020 BAFs
    baf_2020 <- PL94171::pl_get_baf("ND", cache_to = here("data-raw/ND/ND_baf.rds"))
    d_muni <- baf_2020$INCPLACE_CDP |>
        rename(GEOID = BLOCKID, muni = PLACEFP)
    d_ssd <- baf_2020$SLDU |>
        transmute(GEOID = BLOCKID,
            ssd_2010 = as.integer(DISTRICT))
    d_shd <- baf_2020$SLDL |>
        transmute(GEOID = BLOCKID,
            shd_2010 = as.integer(DISTRICT))
    d_vtd <- baf_2020$VTD |>
        transmute(GEOID = BLOCKID,
            vtd_2020 = paste0(censable::match_fips("ND"), COUNTYFP, DISTRICT))

    # Add census AIAN-area assignment: fort berthold reservation (4A) (AIANNHCE == "1160")
    d_aiannh <- baf_2020$AIANNH |>
        transmute(GEOID = BLOCKID, aiannh = AIANNHCE, fort_berthold = coalesce(AIANNHCE == "1160", FALSE))

    nd_shp <- nd_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        left_join(d_shd, by = "GEOID") |>
        left_join(d_vtd, by = "GEOID") |>
        left_join(d_aiannh, by = "GEOID") |>
        mutate(
            county = paste0(censable::match_fips("ND"), county),
            county_muni = if_else(is.na(muni), county, stringr::str_c(county, muni))
        )

    # add the enacted plan
    d_ssd_2020 <- baf::baf(state = "ND", year = 2023, geographies = "ssd")$SSD2022 |>
        transmute(GEOID, ssd_2020 = as.integer(SLDUST))
    d_shd_2020 <- baf::baf(state = "ND", year = 2023, geographies = "shd")$SHD2022 |>
        transmute(GEOID, shd_2020 = SLDLST)

    nd_shp <- nd_shp |>
        left_join(d_ssd_2020, by = "GEOID") |>
        left_join(d_shd_2020, by = "GEOID")

    # Create units for VTDs that cross enacted SSD/SHD boundaries
    # or the Fort Berthold Reservation boundary.
    split_vtds <- nd_shp |>
        st_drop_geometry() |>
        group_by(vtd_2020) |>
        summarize(
            split_vtd = n_distinct(ssd_2020) > 1L | n_distinct(shd_2020) > 1L |
                n_distinct(fort_berthold) > 1L,
            .groups = "drop"
        )

    vtd_elections <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        rename(vtd_2020 = GEOID20) |>
        select(vtd_2020, pre_16_rep_tru:ndv)
    election_cols <- setdiff(names(vtd_elections), "vtd_2020")

    nd_shp <- nd_shp |>
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
                    shd_2020, "_",
                    if_else(fort_berthold, "FB", "NONFB")),
                vtd_2020
            ),
            block_pop_share = if_else(vtd_block_pop > 0, pop/vtd_block_pop, 0)
        ) |>
        mutate(across(all_of(election_cols), ~ coalesce(.x, 0)*block_pop_share))

    nd_shp <- nd_shp |>
        group_by(unit_id) |>
        summarize(
            vtd_2020 = Mode(vtd_2020),
            split_vtd = any(split_vtd),
            aiannh = Mode(aiannh),
            fort_berthold = any(fort_berthold),
            ssd_2010 = Mode(ssd_2010),
            shd_2010 = Mode(shd_2010),
            ssd_2020 = Mode(ssd_2020),
            shd_2020 = Mode(shd_2020),
            muni = Mode(muni),
            county_muni = Mode(county_muni),
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
        rename(GEOID = unit_id, area_land = ALAND20, area_water = AWATER20) |>
        relocate(muni, county_muni, vtd_2020, split_vtd, ssd_2010, shd_2010,
            ssd_2020, shd_2020, .after = county)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = nd_shp,
        perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        nd_shp <- rmapshaper::ms_simplify(nd_shp, keep = 0.05,
            keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    nd_shp$adj <- adjacency(nd_shp)

    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(nd_shp$adj, nd_shp$ssd_2020)
    ccm(nd_shp$adj, nd_shp$shd_2020)

    nd_shp <- nd_shp |>
        fix_geo_assignment(muni)

    write_rds(nd_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    nd_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong ND} shapefile")
}
