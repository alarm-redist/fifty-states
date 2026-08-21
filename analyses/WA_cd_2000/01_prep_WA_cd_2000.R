###############################################################################
# Download and prepare data for `WA_cd_2000` analysis
# © ALARM Project, February 2026
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
    devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg WA_cd_2000}")

path_data <- download_redistricting_file("WA", "data-raw/WA", year = 2000, overwrite = TRUE)

# download ferry routes
url <- "https://data.wsdot.wa.gov/geospatial/DOT_TDO/FerryRoutes/FerryRoutes.zip"
path_ferries <- "data-raw/WA/WA_ferries.zip"
download(url, path_ferries)
unzip(here(path_ferries), exdir = here(dirname(path_ferries), "WA_ferries"))
file.remove(path_ferries)
path_ferries <- "data-raw/WA/WA_ferries/FerryRoutes/FerryRoutes.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/WA_2000/shp_vtd.rds"
perim_path <- "data-out/WA_2000/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong WA} shapefile")
    # read in redistricting data
    wa_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
        join_vtd_shapefile(year = 2000) %>%
        st_transform(EPSG$WA)

    wa_shp <- wa_shp %>%
        rename(muni = place) %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_1990, .after = county)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = wa_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        wa_shp <- rmapshaper::ms_simplify(wa_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    wa_shp$adj <- redist.adjacency(wa_shp)

    # for geographic links
    # need to use 2011 data due to 1990 not being available (earliest for prisecroads)
    d_roads <- tigris::primary_secondary_roads("53", year = 2011) %>%
        st_transform(EPSG$WA)

    d_water <- filter(tigris::fips_codes, state == "WA")$county_code %>%
        lapply(function(cty) tigris::area_water("53", cty, year = 2011)) %>%
        do.call(bind_rows, .) %>%
        st_transform(EPSG$WA)

    d_ferries <- read_sf(path_ferries) %>%
        st_transform(EPSG$WA) %>%
        st_cast("MULTILINESTRING")

    # create adjacency graph
    wa_shp <- st_make_valid(wa_shp)
    sf::sf_use_s2(FALSE)
    wa_shp$adj <- redist.adjacency(wa_shp)

    if (is.null(wa_shp$geometry)) {
        wa_shp$geometry <- sf::st_geometry(wa_shp)
        sf::st_geometry(wa_shp) <- "geometry"
    }

    # disconnect water
    d_bigwater <- filter(d_water, as.numeric(st_area(d_water)) > 1e7) %>%
        summarize() %>% st_make_valid() %>%
        rmapshaper::ms_simplify(keep = 0.05) %>%
        st_snap(wa_shp$geometry, tolerance = 100) %>%
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
    for (i in seq_along(wa_shp$adj)) {
        cty_i <- wa_shp$county[i]
        adj_i <- wa_shp$adj[[i]] + 1L
        cty_j <- wa_shp$county[adj_i]
        diff_cty <- which(cty_j != cty_i)
        if (length(diff_cty) > 0) {
            wa_shp$adj <- remove_edge(wa_shp$adj, rep(i, length(diff_cty)), adj_i[diff_cty])
        }
    }

    # reconnect precincts across county borders by roads + ferries
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

    # Connect precincts
    left_ids <- c(
        "53033000755", "53033000756", "53033000757", "53033000758", "53033000759",
        "53033000761", "53033000762", "53033000763", "53033000765", "53033000766",
        "53033000767", "53033000768", "53033000769", "53033000770", "53033000771",
        "53033000772", "53033000773", "53033000774", "53033000775", "53033000776",
        "53033000777", "53033000778", "53033000779", "53033000780", "53033000781",
        "53033000782", "53033000783", "53033000784", "53033000785", "53033000786",
        "53033000787", "53033000788", "53033000789", "53033000790", "53033000791",
        "53033000792", "53033000793", "53033000794", "53033000795", "53033000796",
        "53033000797", "53033002465",
        "53007WVCRWN", "53011WVVAN1", "530270WVOS1", "530310WVPTE", "530310WVPTS",
        "53033001818", "530330WVMED", "530330WVRED", "53033WVEB11", "53033WVEB43",
        "53033WVLW11", "53033WVLW33", "53033WVLW41", "53033WVMERI", "53033WVPS30",
        "53033WVPS32", "53061WVEDM1", "53061WVPS38", "53061WVWOD1",
        "53033002445", "53033002691", "53033002808", "53061000339", "53033002809"
    )

    right_ids <- c(
        "53033WVMERI",
        "53033000755", "53033000756", "53033000757", "53033000758", "53033000759",
        "53033000761", "53033000762", "53033000763", "53033000765", "53033000766",
        "53033000767", "53033000768", "53033000769", "53033000770", "53033000771",
        "53033000772", "53033000773", "53033000774", "53033000775", "53033000776",
        "53033000777", "53033000778", "53033000779", "53033000780", "53033000781",
        "53033000782", "53033000783", "53033000784", "53033000785", "53033000786",
        "53033000787", "53033000788", "53033000789", "53033000790", "53033000791",
        "53033000792", "53033000793", "53033000794", "53033000795", "53033000796",
        "53033000797",
        "53007007303", "53011011675", "53027027801",
        "53031WVPTBY", "53031WVPTBY",
        "53033001817", "53033WVBE41", "53033009166", "53033001493", "53033001834",
        "530330WVS37", "53033WVNPK1", "53033WVRT11", "53033000099", "53033003019",
        "53033000514", "53029WVPUGS", "53029WVSARP", "53061000232",
        "53033WVMERI", "53033000765", "53033000774", "53061WVPS10", "53033000795"
    )

    stopifnot(length(left_ids) == length(right_ids))

    # ensure GEOID is character
    wa_shp <- wa_shp |>
        mutate(GEOID = as.character(GEOID))

    for (k in seq_along(left_ids)) {
        u <- match(left_ids[k], wa_shp$GEOID)
        v <- match(right_ids[k], wa_shp$GEOID)

        if (!is.na(u) && !is.na(v)) {
            wa_shp$adj <- add_edge(wa_shp$adj, u, v, zero = TRUE)
        }
    }

    wa_shp <- wa_shp %>%
        fix_geo_assignment(muni)

    write_rds(wa_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    wa_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong WA} shapefile")
}
