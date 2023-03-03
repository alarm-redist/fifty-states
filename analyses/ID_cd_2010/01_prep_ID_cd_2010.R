###############################################################################
# Download and prepare data for `ID_cd_2010` analysis
# © ALARM Project, March 2023
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
cli_process_start("Downloading files for {.pkg ID_cd_2010}")

path_data <- download_redistricting_file("ID", "data-raw/ID", year = 2010)

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/id_2010_congress_2011-10-17_2021-12-31.zip"
path_enacted <- "data-raw/ID/ID_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "ID_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/ID/ID_enacted/C52.shp" # TODO use actual SHP

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/ID_2010/shp_vtd.rds"
perim_path <- "data-out/ID_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong ID} shapefile")
    # read in redistricting data
    id_shp <- read_csv(here(path_data), col_types = cols(GEOID10 = "c")) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$ID)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("ID", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("ID"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("ID", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("ID"), vtd),
                  cd_2000 = as.integer(cd))
    id_shp <- left_join(id_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by="GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    id_shp <- id_shp %>%
        mutate(cd_2010 = as.integer(cd_shp$DISTRICT)[
            geo_match(id_shp, cd_shp, method = "area")],
            .after = cd_2000)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = id_shp,
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

    cty_pair <- purrr::map_dfr(seq_along(cty_adj), \(x){
        tibble(x = x, y = cty_adj[[x]])
    })

    roads <- tigris::primary_secondary_roads("ID") %>%
        st_transform(st_crs(id_shp)) %>%
        geos::as_geos_geometry()

    ints <- geos::geos_intersects_matrix(geom = roads, tree = cty)
    tbl <- purrr::map_dfr(ints, \(x){
        if (length(x) > 1) {
            tidyr::expand_grid(x = x, y = x) %>% filter(
                x != y
            )
        } else {
            data.frame()
        }
    }) %>% distinct() %>%
        mutate(magic = TRUE)

    cty_pair <- cty_pair %>%
        left_join(tbl, by = c("x", "y")) %>%
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

