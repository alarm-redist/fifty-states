###############################################################################
# Download and prepare data for `ID_cd_2020` analysis
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
cli_process_start("Downloading files for {.pkg ID_cd_2020}")

path_data <- download_redistricting_file("ID", "data-raw/ID")

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/ID_2020/shp_vtd.rds"
perim_path <- "data-out/ID_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong ID} shapefile")
    # read in redistricting data
    id_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$ID)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("ID", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("ID"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("ID", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("ID"), vtd),
            cd_2010 = as.integer(cd))
    id_shp <- left_join(id_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add enacted ----
    dists <- read_sf("https://redistricting.lls.edu/wp-content/uploads/id_2020_congress_2021-11-12_2031-06-30.json")
    id_shp$cd_2020 <- as.integer(dists$Districts)[geo_match(from = id_shp, to = dists, method = "area")]

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = id_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        id_shp <- rmapshaper::ms_simplify(id_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    id_shp$adj <- redist.adjacency(id_shp)

    cty <- id_shp %>%
        group_by(county) %>%
        summarize(geometry = sf::st_as_sfc(geos::geos_unary_union(geos::geos_make_collection(geometry))))

    cty_adj <- adjacency(cty) %>% lapply(\(x) x + 1)

    cty_pair <- map_dfr(seq_along(cty_adj), \(x){
        tibble(x = x, y = cty_adj[[x]])
    })

    roads <- tigris::primary_secondary_roads("ID") %>%
        st_transform(st_crs(id_shp)) %>%
        geos::as_geos_geometry()

    ints <- geos::geos_intersects_matrix(geom = roads, tree = cty)
    tbl <- map_dfr(ints, \(x){
        if (length(x) > 1) {
            expand_grid(x = x, y = x) %>% filter(
                x != y
            )
        } else {
            data.frame()
        }
    }) %>% distinct() %>%
        mutate(magic = TRUE)

    cty_pair <- cty_pair %>%
        left_join(tbl) %>%
        filter(is.na(magic))

    cty_pair <- cty_pair %>%
        mutate(x = cty$county[x],
            y = cty$county[y])

    adj <- id_shp$adj
    for (i in seq_len(nrow(cty_pair))) {
        adj <- seam_rip(adj, shp = id_shp,
            admin = "county", seam = c(cty_pair$x[i], cty_pair$y[i])
        )
    }

    id_shp$adj <- adj

    id_shp <- id_shp %>%
        fix_geo_assignment(muni)

    write_rds(id_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    id_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong ID} shapefile")
}
