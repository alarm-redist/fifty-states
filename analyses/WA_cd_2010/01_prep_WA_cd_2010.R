###############################################################################
# Download and prepare data for `WA_cd_2010` analysis
# © ALARM Project, July 2022
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
cli_process_start("Downloading files for {.pkg WA_cd_2010}")

path_data <- download_redistricting_file("WA", "data-raw/WA", year = 2010)

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/wa_2010_congress_2012-02-07_2021-12-31.zip"
path_enacted <- "data-raw/WA/WA_enacted_2010.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "WA_enacted_2010"))
file.remove(path_enacted)
path_enacted <- "data-raw/WA/WA_enacted_2010/CONG_AMEND_FINAL.shp"

# download ferry routes
url <- "https://data.wsdot.wa.gov/geospatial/DOT_TDO/FerryRoutes/FerryRoutes.zip"
path_ferries <- "data-raw/WA/WA_ferries.zip"
download(url, path_ferries)
unzip(here(path_ferries), exdir = here(dirname(path_ferries), "WA_ferries"))
file.remove(path_ferries)
path_ferries <- "data-raw/WA/WA_ferries/FerryRoutes/FerryRoutes.shp"


cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/WA_2010/shp_vtd.rds"
perim_path <- "data-out/WA_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong WA} shapefile")
    # read in redistricting data
    wa_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$WA)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID")) %>%
        relocate(GEOID, .before = state)

    # fill Mt. Rainier hole
    geom_pierce <- filter(wa_shp, county == "053") %>%
        summarize() %>%
        pull(geometry)
    geom_pierce_nohole <- lapply(geom_pierce, function(x) x[1]) %>%
        st_multipolygon() %>%
        st_sfc(crs = st_crs(geom_pierce))
    geom_hole <- st_difference(geom_pierce_nohole, geom_pierce)
    wa_shp$geometry[st_geometry_type(wa_shp$geometry) == "GEOMETRYCOLLECTION"] <- geom_hole


    # add municipalities
    d_muni <- make_from_baf("WA", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("WA"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("WA", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("WA"), vtd),
                  cd_2000 = as.integer(cd))
    wa_shp <- left_join(wa_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    wa_shp <- wa_shp %>%
        mutate(cd_2010 = as.integer(cd_shp$District_N)[
            geo_match(wa_shp, cd_shp, method = "area")],
            .after = cd_2000)


    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = wa_shp, perim_path = here(perim_path)) %>% invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        wa_shp <- rmapshaper::ms_simplify(wa_shp, keep = 0.05,
                                          keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # for geographic links
    # need to use 2011 data due to 2010 not being available
    d_roads <- tigris::primary_secondary_roads("53", year = 2011) %>%
        st_transform(EPSG$WA)
    d_water <- filter(tigris::fips_codes, state == "WA")$county_code %>%
        lapply(function(cty) tigris::area_water("53", cty, year = 2011)) %>%
        do.call(bind_rows, .) %>%
        st_transform(EPSG$WA)
    d_ferries <- read_sf(path_ferries) %>%
        st_transform(EPSG$WA) %>%
        st_cast("MULTILINESTRING")

    # Highway plot for geographical links constraint
    # WSF (ferries) is part of the state highway system but doesn't show up in TIGER
    if (FALSE) {
        library(ggplot2)

        p <- ggplot(wa_shp, aes(fill = county)) +
            geom_sf(size = 0.05, color = "white") +
            geom_sf(data = d_water, size = 0.0, fill = "white", color = NA) +
            geom_sf(size = 0.7, color = "red", fill = NA, inherit.aes = FALSE,
                    data = summarize(group_by(wa_shp, cd_2010), is_coverage = TRUE)) +
            geom_sf(size = 0.4, color = "black", inherit.aes = FALSE,
                    data = filter(d_roads, RTTYP %in% c("I", "U", "S"))) +
            scale_fill_manual(values = sf.colors(39, categorical = TRUE), guide = "none") +
            scale_alpha_continuous(range = c(0, 1), guide = "none") +
            theme_void()

        p + geom_sf_text(aes(label = str_glue("{county}\n{vtd}")), size = 2.2, color = "black",
                         data = filter(wa_shp, area_land >= 5e8))

        plot_zoom <- function(cty) {
            bbox <- st_bbox(filter(wa_shp, county == paste(cty, "County")))
            p +
                coord_sf(xlim = bbox[c(1, 3)], ylim = bbox[c(2, 4)])
        }
    }

    # create adjacency graph
    wa_shp <- st_make_valid(wa_shp)
    sf::sf_use_s2(FALSE)
    wa_shp$adj <- redist.adjacency(wa_shp)

    # disconnect water
    d_bigwater <- filter(d_water, as.numeric(st_area(d_water)) > 1e7) %>%
        summarize() %>% st_make_valid() %>%
        rmapshaper::ms_simplify(keep = 0.05) %>%
        st_snap(wa_shp$geometry, tolerance = 100) %>% # 100 ft
        st_buffer(1.0)
    geom_adj <- st_difference(wa_shp, d_bigwater$geometry)
    geom_adj <- bind_rows(
        geom_adj,
        st_buffer(filter(wa_shp, !GEOID %in% geom_adj$GEOID), -50)
    )
    geom_adj <- slice(geom_adj, match(wa_shp$GEOID, geom_adj$GEOID))

    adj_nowater <- redist.adjacency(wa_shp)
    adj_0 <- redist.adjacency(geom_adj)
    wa_shp$adj <- adj_0


    # disconnect all counties
    # Since counties follow the Cascade crest and the Columbia river,
    #   this will take care of major geographic barriers. Smaller features,
    #   e.g., lakes, bays and estuaries, won't be disconnected.
    for (i in seq_along(wa_shp$adj)) {
        cty_i <- wa_shp$county[i]
        adj_i <- wa_shp$adj[[i]] + 1L
        cty_j <- wa_shp$county[adj_i]
        diff_cty <- which(cty_j != cty_i)
        if (length(diff_cty) > 0) {
            wa_shp$adj <- remove_edge(wa_shp$adj, rep(i, length(diff_cty)), adj_i[diff_cty])
        }
    }

    # reconnect precincts across county borders by roads
    geom_roads_ferries <- c(d_roads$geometry, d_ferries$geometry)
    rel_roads_ferries <- st_crosses(geom_roads_ferries, wa_shp)
    for (i in seq_along(rel_roads_ferries)) {
        rel_i <- rel_roads_ferries[[i]]
        if (length(rel_i) == 1) next
        for (j in rel_i) {
            adj_j <- setdiff(intersect(adj_nowater[[j]] + 1L, rel_i), wa_shp$adj[[j]] + 1L)
            if (length(adj_j) > 0) {
                wa_shp$adj <- add_edge(wa_shp$adj, rep(j, length(adj_j)), adj_j)
            }
        }
    }

    # manual connections
    add_update_edge <- function(vtd1, vtd2) {
        wa_shp$adj <<- add_edge(wa_shp$adj, which(wa_shp$GEOID == vtd1), which(wa_shp$GEOID == vtd2))
    }

    # Vashon and N Seattle
    add_update_edge("53033WV0732", "53033000514")
    add_update_edge("53033001818", "53033001817")
    add_update_edge("53033WV0734", "53033001150")
    add_update_edge("53033WV0733", "53033000853")
    add_update_edge("53033WV0933", "53033002416")
    add_update_edge("53033WV0930", "53033003014")

    # Bremerton
    add_update_edge("53035000007", "53035000006")

    # Harstine Island
    add_update_edge("53045000114", "53045000113")

    # Fox, McNeil, and Ketron islands
    add_update_edge("53053026350", "53053026342")
    add_update_edge("53053028575", "53053028542")
    add_update_edge("53053028571", "53053028574")

    # Point Roberts
    add_update_edge("53073000101", "53073000102")

    # Clark County
    add_update_edge("53011WVCR49", "5301111090")

    # Grays Harbor County
    add_update_edge("53027WVPO24", "5302727045")

    # Island County
    add_update_edge("53029WVSTJF", "5302929027")
    add_update_edge("53061WVPG21", "53061WVPGED")
    add_update_edge("53029WVPUGS", "5302929040")
    add_update_edge("53029WVHOLH", "5302929023")
    add_update_edge("53029WVPTSU", "5302929032")
    add_update_edge("53029WVSKGB", "5302929057")

    # Jefferson County
    add_update_edge("53031WVPACO", "5300909262")

    # King County
    add_update_edge("53033WVS361", "53033332200")
    add_update_edge("53033WVPS30", "53033WVPS33")
    add_update_edge("53033303PS67", "5033330846")
    add_update_edge("53033WVPSB9", "53033WVPS34")
    add_update_edge("53033WVLW37", "53033330273")
    add_update_edge("53033WVPSB7", "53033331057")
    add_update_edge("53033WVLW41", "53033331010")
    add_update_edge("53033WVL327", "53033330003")
    add_update_edge("53033WVPSNP", "53033330856")
    add_update_edge("53033331818", "53033331817")

    # Pierce County
    add_update_edge("53053WVROCB", "5305353211")

    # San Juan County
    add_update_edge("5305555015", "5305555004")

    # Snohomish County
    add_update_edge("53061WVPGWY", "53061WVPG32")

    # manual connection helpers
    if (FALSE) {
        redist.plot.adj(wa_shp, wa_shp$adj, centroids = F)
        x <- redist:::contiguity(wa_shp$adj, rep(1, length(wa_shp$adj)))
        unique(wa_shp$county[x > 1])

        idx <- which(x > 1 & str_detect(wa_shp$county, "033"))
        bbox <- st_bbox(st_buffer(wa_shp$geometry[idx], 500))
        lbls <- rep("", nrow(wa_shp))
        adj_idxs <- c(idx, unlist(adj_nowater[idx]) + 1L)
        # adj_idxs = c(adj_idxs, unlist(adj_nowater[adj_idxs]) + 1L)
        lbls[adj_idxs] <- wa_shp$GEOID[adj_idxs]
        ggplot(wa_shp) +
            geom_sf(aes(fill = x > 1), size = 0.1) +
            geom_sf(data = d_water, size = 0.0, fill = "#ffffff55", color = NA) +
            coord_sf(xlim = bbox[c(1, 3)], ylim = bbox[c(2, 4)]) +
            geom_sf_text(aes(label = lbls), size = 2.5) +
            theme_void()

        table(redist:::contiguity(wa_shp$adj, wa_shp$cd_2010))
    }


    wa_shp <- wa_shp %>%
        fix_geo_assignment(muni)

    wa_shp <- st_cast(wa_shp, "MULTIPOLYGON") %>%
        suppressWarnings()
    write_rds(wa_shp, here(shp_path), compress = "gz")
    cli_process_done()

} else {
    wa_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong WA} shapefile")
}
enforce_style("WA", year = 2010)
