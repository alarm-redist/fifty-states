###############################################################################
# Download and prepare data for `CT_leg_2020` analysis
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
cli_process_start("Downloading files for {.pkg CT_leg_2020}")

path_data <- download_redistricting_file("CT", "data-raw/CT", year = 2020)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/CT_2020/shp_vtd.rds"
perim_path <- "data-out/CT_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong CT} shapefile")
    # read in redistricting data
    ct_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        join_vtd_shapefile(year = 2020) |>
        st_transform(EPSG$CT)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    vtd_cty <- ct_shp |>
        select(state, county, vtd) |>
        st_drop_geometry()

    library(tigris)

    ct_blocks_tigris <- tigris::blocks(
        state = "CT",
        year = 2020,
        class = "sf"
    ) |>
        st_drop_geometry() |>
        select(GEOID20, ALAND20, AWATER20) |>
        rename(BLOCKID = GEOID20,
            area_land = ALAND20,
            area_water = AWATER20)

    block_data <- censable::build_dec(
        geography = "block",
        state = "CT",
        year = 2020
    ) |>
        st_transform(EPSG$CT) |>
        left_join(ct_blocks_tigris, by = c("GEOID" = "BLOCKID"))

    ct_vtds <- voting_districts(
        state = "CT",
        year = 2020,
        class = "sf"
    ) |>
        st_transform(EPSG$CT)

    blocks_with_vtd <- st_join(
        block_data,
        ct_vtds[, c("GEOID20")],  # VTD GEOID
        left = TRUE
    )

    baf <- readRDS("data-raw/CT/CT_baf.rds")
    blocks_vtd_crosswalk <- baf$VTD |> mutate(VTD = DISTRICT) |> select(-DISTRICT)
    blocks_shd_crosswalk <- baf$SLDL |> mutate(SHD = DISTRICT) |> select(-DISTRICT)
    blocks_ssd_crosswalk <- baf$SLDU |> mutate(SSD = DISTRICT) |> select(-DISTRICT)

    blocks_full <- blocks_vtd_crosswalk |>
        left_join(blocks_shd_crosswalk) |>
        left_join(blocks_ssd_crosswalk)

    ## testing other baf files
    baf_2024 <- baf::baf(state = "CT", geographies = c("SLDL", "SLDU", "VTD"), year = 2024)

    blocks_vtd_crosswalk_2024 <- baf_2024$VTD |> mutate(VTD = DISTRICT) |> select(-DISTRICT)
    blocks_shd_crosswalk_2024 <- baf_2024$SLDL |> mutate(SHD = DISTRICT) |> select(-DISTRICT)
    blocks_ssd_crosswalk_2024 <- baf_2024$SLDU |> mutate(SSD = DISTRICT) |> select(-DISTRICT)

    blocks_full_2024 <- blocks_vtd_crosswalk_2024 |>
        left_join(blocks_shd_crosswalk_2024) |>
        left_join(blocks_ssd_crosswalk_2024) |>
        left_join(block_data, by = c("BLOCKID" = "GEOID"))

    blocks_full_sf_2024 <- blocks_full_2024 |>
        st_as_sf()

    redistio::draw(blocks_full_sf_2024, blocks_full_sf_2024$SHD)


    # BEF from CT Gov
    bef_ct <- read_csv("data-raw/CT/21HouseBEF.txt",
        col_names = c("BLOCKID", "SHD_BEF"))

    blocks_full_BEF_2024 <- blocks_full_sf_2024 |>
        left_join(bef_ct)

    redistio::draw(blocks_full_BEF_2024, blocks_full_BEF_2024$SHD_BEF)

    ### SHP version
    ct_shp_2020 <- st_read("data-raw/CT/ct_shp_data/ct_2020_lower_2021-11-18_2031-06-30.shp") |>
        st_transform(crs = st_crs(ct_vtds)) |>
        st_make_valid()

    ct_vtds <- ct_vtds |>
        st_make_valid()

    ct_shd_vtd <- st_intersection(ct_shp_2020, ct_vtds)

    ct_shd_vtd <- st_make_valid(ct_shd_vtd)

    ct_shd_vtd <- ct_shd_vtd |>
        st_make_valid() |>
        st_collection_extract("POLYGON") |>
        filter(st_dimension(geometry) == 2, !st_is_empty(geometry))


    # Build polygon adjacency (edge-sharing neighbors only)
    nb <- st_touches(ct_shp_2020)

    edges <- do.call(
        rbind,
        lapply(seq_along(nb), function(i) {
            if (length(nb[[i]]) == 0) return(NULL)
            cbind(i, nb[[i]])
        })
    )

    library(igraph)
    # Build graph and color it (greedy planar coloring)
    g <- graph_from_edgelist(edges, directed = FALSE)

    color_df <- ct_shp_2020 |>
        select(DISTRICT) |>
        st_drop_geometry()

    color_df$color <- greedy_vertex_coloring(g)

    ct_shd_vtd <- ct_shd_vtd |>
        left_join(color_df, by = c("DISTRICT" = "DISTRICT"))

    ct_shd_vtd <- ct_shd_vtd |>
        mutate(area = as.numeric(st_area(geometry)))

    vtd_area <- ct_shd_vtd |>
        group_by(VTDST20) |>
        mutate(
            total_area = sum(area),
            share = area/total_area
        ) |>
        ungroup()

    meaningful_vtd_shd <- vtd_area |>
        filter(share >= 0.05) |>
        distinct(VTDST20, DISTRICT)

    split_vtds <- meaningful_vtd_shd |>
        count(VTDST20, name = "n_shd") |>
        filter(n_shd > 1)

    split_ids <- split_vtds$VTDST20

    vtd_unsplit <- ct_vtds |>
        filter(!VTDST20 %in% split_ids)

    ### alternative using the full blocks_full_BEF_2024

    vtd_status <- blocks_full_BEF_2024 |>
        distinct(VTD, SHD_BEF) |>
        count(VTD, name = "n_shd")

    split_vtds   <- vtd_status |> filter(n_shd > 1)
    unsplit_vtds <- vtd_status |> filter(n_shd == 1)

    vtd_unsplit_geom <- blocks_full_BEF_2024 |>
        filter(VTD %in% unsplit_vtds$VTD) |>
        group_by(VTD) |>
        summarize(
            SHD_BEF    = first(SHD_BEF),   # guaranteed unique here
            # Total population
            pop        = sum(pop, na.rm = TRUE),
            # Race / ethnicity
            pop_white  = sum(pop_white, na.rm = TRUE),
            pop_black  = sum(pop_black, na.rm = TRUE),
            pop_hisp   = sum(pop_hisp, na.rm = TRUE),
            pop_aian   = sum(pop_aian, na.rm = TRUE),
            pop_asian  = sum(pop_asian, na.rm = TRUE),
            pop_nhpi   = sum(pop_nhpi, na.rm = TRUE),
            pop_other  = sum(pop_other, na.rm = TRUE),
            pop_two    = sum(pop_two, na.rm = TRUE),
            # Voting-age population
            vap        = sum(vap, na.rm = TRUE),
            vap_white  = sum(vap_white, na.rm = TRUE),
            vap_black  = sum(vap_black, na.rm = TRUE),
            vap_hisp   = sum(vap_hisp, na.rm = TRUE),
            vap_aian   = sum(vap_aian, na.rm = TRUE),
            vap_asian  = sum(vap_asian, na.rm = TRUE),
            vap_nhpi   = sum(vap_nhpi, na.rm = TRUE),
            vap_other  = sum(vap_other, na.rm = TRUE),
            vap_two    = sum(vap_two, na.rm = TRUE),
            # geom
            geometry   = st_union(geometry),
            .groups    = "drop"
        )

    vtd_shd_split_geom <- blocks_full_BEF_2024 |>
        filter(VTD %in% split_vtds$VTD) |>
        group_by(VTD, SHD_BEF) |>
        summarize(
            # Total population
            pop        = sum(pop, na.rm = TRUE),
            # Race / ethnicity
            pop_white  = sum(pop_white, na.rm = TRUE),
            pop_black  = sum(pop_black, na.rm = TRUE),
            pop_hisp   = sum(pop_hisp, na.rm = TRUE),
            pop_aian   = sum(pop_aian, na.rm = TRUE),
            pop_asian  = sum(pop_asian, na.rm = TRUE),
            pop_nhpi   = sum(pop_nhpi, na.rm = TRUE),
            pop_other  = sum(pop_other, na.rm = TRUE),
            pop_two    = sum(pop_two, na.rm = TRUE),
            # Voting-age population
            vap        = sum(vap, na.rm = TRUE),
            vap_white  = sum(vap_white, na.rm = TRUE),
            vap_black  = sum(vap_black, na.rm = TRUE),
            vap_hisp   = sum(vap_hisp, na.rm = TRUE),
            vap_aian   = sum(vap_aian, na.rm = TRUE),
            vap_asian  = sum(vap_asian, na.rm = TRUE),
            vap_nhpi   = sum(vap_nhpi, na.rm = TRUE),
            vap_other  = sum(vap_other, na.rm = TRUE),
            vap_two    = sum(vap_two, na.rm = TRUE),
            # geom
            geometry   = st_union(geometry),
            .groups    = "drop"
        )

    final_vtd_basis <- bind_rows(
        vtd_unsplit_geom,
        vtd_shd_split_geom
    )

    final_vtd_basis <- final_vtd_basis |>
        group_by(VTD) |>
        mutate(
            vtd_pop       = sum(pop, na.rm = TRUE),
            vtd_pop_share = pop/vtd_pop
        ) |>
        ungroup()

    final_vtd_basis <- final_vtd_basis |>
        mutate(is_split = VTD %in% split_vtds$VTD) |>
        mutate(SHD3 = str_pad(SHD_BEF, 3, "left", "0")) |>
        mutate(SHD_BEF_char = as.character(SHD_BEF)) |>
        mutate(unit_id = paste0(VTD, "-", SHD3)) |>
        left_join(color_df, by = c("SHD_BEF_char" = "DISTRICT")) |>
        arrange(VTD, SHD3)

    # adding in political vars

    ct_shp_pvs <- ct_shp |>
        select(vtd, pre_16_dem_cli:ndv) |>
        rename_with(~ paste0(.x, "_vtd"), pre_16_dem_cli:ndv) |>
        st_drop_geometry()

    final_vtd_basis_pv <- final_vtd_basis |>
        left_join(ct_shp_pvs, by = c("VTD" = "vtd")) |>
        mutate(
            across(
                ends_with("_vtd"),
                ~ .x*vtd_pop_share
            )
        ) |>
        rename_with(
            ~ sub("_vtd$", "", .x),
            ends_with("_vtd")
        )


    ct_shp <- final_vtd_basis_pv

    # add municipalities
    d_muni <- make_from_baf("CT", "INCPLACE_CDP", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("CT"), vtd)) |>
        mutate(vtd = str_sub(vtd, 4))
    d_ssd <- make_from_baf("CT", "SLDU", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("CT"), vtd),
            ssd_2010 = as.integer(sldu)) |>
        mutate(vtd = str_sub(vtd, 4))
    d_shd <- make_from_baf("CT", "SLDL", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("CT"), vtd),
            shd_2010 = as.integer(sldl)) |>
        mutate(vtd = str_sub(vtd, 4))

    ct_shp <- ct_shp |>
        left_join(vtd_cty, by = c("VTD" = "vtd")) |>
        left_join(d_muni, by = c("VTD" = "vtd")) |>
        left_join(d_ssd, by = c("VTD" = "vtd")) |>
        left_join(d_shd, by = c("VTD" = "vtd")) |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, ssd_2010, .after = county) |>
        relocate(muni, county_muni, shd_2010, .after = county)

    # add enacted plan
    ct_shp <- ct_shp |>
        left_join(y = leg_from_baf(state = "CT"), by = "GEOID")

    ct_shp <- ct_shp |>
        mutate(across(c(pop:vap_two, pre_16_dem_cli:ndv), ~ replace_na(.x, 0))) |>
        filter(!is.na(SHD_BEF))

    # Create perimeters in case shapes are simplified
    # TODO do here might need to change perim_path
    # once you've filtered but before you simplify
    redistmetrics::prep_perims(shp = ct_shp,
        perim_path = here(perim_path)) |>
        invisible()

    # Not working
    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ct_shp <- rmapshaper::ms_simplify(ct_shp, keep = 0.05,
            keep_shapes = TRUE)
    }

    # create adjacency graph
    ct_shp$adj <- adjacency(ct_shp)

    ct_shp$SHD_BEF <- as.integer(ct_shp$SHD_BEF)

    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(ct_shp$adj, ct_shp$SHD_BEF)
    ccm(ct_shp$adj, ct_shp$shd_2020)

    ct_shp <- ct_shp |>
        fix_geo_assignment(muni)

    redistio::draw(ct_shp, ct_shp$SHD_BEF)

    write_rds(ct_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ct_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong CT} shapefile")
}
