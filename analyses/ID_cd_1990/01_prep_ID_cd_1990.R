###############################################################################
# Download and prepare data for `ID_cd_1990` analysis
# © ALARM Project, November 2025
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
cli_process_start("Downloading files for {.pkg ID_cd_1990}")

path_data <- download_redistricting_file("ID", "data-raw/ID", year = 1990)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/ID_1990/shp_vtd.rds"
perim_path <- "data-out/ID_1990/perim.rds"
tract_path <- "data-raw/ID/16_tracts.gpkg"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong ID} shapefile")
    # read in redistricting data
    raw_data <- read_csv(here(path_data), col_types = cols(GEOID = "c"))
    raw_data$state = as.character(raw_data$state)
    shapefile <- st_read(tract_path, quiet = TRUE) |>
        rename(state_shp = state)
    id_shp <- raw_data |>
        left_join(shapefile, by = "GEOID")
    # manually set state to ID
    id_shp = mutate(id_shp, state = "ID") |>
        st_as_sf()

    # id_shp = join_vtd_shapefile(raw_data, year = 1990)

    id_shp = st_transform(id_shp, EPSG$ID)

    id_shp <- id_shp |>
        rename(muni = place) |>
        mutate(county_muni = if_else(is.na(muni), county.x, str_c(county.x, muni))) |>
        relocate(muni, county_muni, cd_1980, .after = county.x)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = id_shp,
                               perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        id_shp <- rmapshaper::ms_simplify(id_shp, keep = 0.05,
                                                 keep_shapes = TRUE) |>
            suppressWarnings()
    }
    id_shp <- id_shp |>
      select(-county.y, -tract.y, -state_shp)
    id_shp <- id_shp %>%
      rename(county = county.x)

    # create adjacency graph
    id_shp$adj <- redist.adjacency(id_shp)

    cty <- id_shp %>%
      group_by(county) %>%
      summarize(geometry = sf::st_as_sfc(geos::geos_unary_union(geos::geos_make_collection(geom))))

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

    id_shp$muni <- ifelse(is.na(id_shp$muni) | id_shp$muni == "NA",
                     id_shp$county_muni,
                     id_shp$muni)

    id_shp <- id_shp %>%
      fix_geo_assignment(muni)

    write_rds(id_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    id_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong ID} shapefile")
}
