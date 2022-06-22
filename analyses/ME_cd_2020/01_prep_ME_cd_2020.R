###############################################################################
# Download and prepare data for `ME_cd_2020` analysis
# © ALARM Project, December 2021
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
cli_process_start("Downloading files for {.pkg ME_cd_2020}")

path_data <- download_redistricting_file("ME", "data-raw/ME")

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/ME_2020/shp_vtd.rds"
perim_path <- "data-out/ME_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong ME} shapefile")
    # read in redistricting data ----
    # custom build to tracts
    years <- c(2016, 2018, 2020)
    state <- "ME"
    el_l <- lapply(years, function(year) {
        get_vest(state, year)
    })

    block <- censable::build_dec("block", state, year = 2010)

    m_l <- lapply(el_l, function(x) {
        geo_match(from = block, to = x, method = "area")
    })

    el_l <- lapply(seq_along(el_l), function(x) {
        vest <- el_l[[x]]
        elec_at_2010 <- tibble(GEOID = block$GEOID)
        elections <- names(vest)[str_detect(names(vest), str_c("_", years[x] - 2000)) &
            (str_detect(names(vest), "_rep_") | str_detect(names(vest), "_dem_"))]
        for (election in elections) {
            elec_at_2010 <- elec_at_2010 %>%
                mutate(!!election := estimate_down(
                    value = vest[[election]], wts = block[["vap"]],
                    group = m_l[[x]]
                ))
        }
        elec_at_2010
    })
    elec_at_2010 <- purrr::reduce(el_l, left_join, by = "GEOID")
    vest_cw <- cvap::vest_crosswalk(state)
    rt <- PL94171::pl_retally(elec_at_2010, crosswalk = vest_cw)
    names(rt)[4:13] <- names(elec_at_2010)[2:11]

    tract <- rt %>%
        censable::breakdown_geoid() %>%
        censable::construct_geoid("tract") %>%
        select(GEOID, contains(paste(years - 2000))) %>%
        group_by(GEOID) %>%
        summarize(across(.fns = sum)) %>%
        mutate(
            arv_16 = rowMeans(select(., contains("_16_rep_")), na.rm = TRUE),
            adv_16 = rowMeans(select(., contains("_16_dem_")), na.rm = TRUE),
            arv_18 = rowMeans(select(., contains("_18_rep_")), na.rm = TRUE),
            adv_18 = rowMeans(select(., contains("_18_dem_")), na.rm = TRUE),
            arv_20 = rowMeans(select(., contains("_20_rep_")), na.rm = TRUE),
            adv_20 = rowMeans(select(., contains("_20_dem_")), na.rm = TRUE),
            nrv = rowMeans(select(., contains("_rep_")), na.rm = TRUE),
            ndv = rowMeans(select(., contains("_dem_")), na.rm = TRUE)
        )

    me_shp <- censable::build_dec("tract", state) %>%
        left_join(tract, by = "GEOID")
    me_shp <- me_shp %>%
        censable::breakdown_geoid() %>%
        mutate(state = censable::match_fips(state[1]))

    me_shp <- me_shp %>%
        st_transform(EPSG$ME)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    me_shp <- me_shp %>% filter(!st_is_empty(geometry))

    # add municipalities
    d_muni <- PL94171::pl_get_baf("ME")$INCPLACE_CDP %>%
        censable::breakdown_geoid("BLOCKID") %>%
        censable::construct_geoid("tract") %>%
        group_by(GEOID) %>%
        summarize(muni = Mode(PLACEFP))
    d_cd <- PL94171::pl_get_baf("ME")$CD %>%
        censable::breakdown_geoid("BLOCKID") %>%
        censable::construct_geoid("tract") %>%
        group_by(GEOID) %>%
        summarize(cd_2010 = Mode(DISTRICT))
    me_shp <- left_join(me_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # enacted ----
    dists <- read_sf("https://redistrict2020.org/files/ME-2021-09-16/US_Congressional_Districts_Unified_Proposal.geojson")
    me_shp <- me_shp %>% mutate(
        cd_2020 = geo_match(from = me_shp, to = dists, method = "area"),
        .after = cd_2010
    )

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = me_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        me_shp <- rmapshaper::ms_simplify(me_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    me_shp$adj <- redist.adjacency(me_shp)

    # fix disconnected islands, respecting district assumptions
    adds <- suggest_component_connection(me_shp, me_shp$adj, me_shp$cd_2020)
    me_shp$adj <- me_shp$adj %>% add_edge(adds$x, adds$y)

    me_shp <- me_shp %>%
        fix_geo_assignment(muni)

    me_shp$state <- "ME"

    write_rds(me_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    me_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong ME} shapefile")
}
