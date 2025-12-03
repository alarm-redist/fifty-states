###############################################################################
# Download and prepare data for `TX_leg_2020` analysis
# © ALARM Project, October 2025
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
cli_process_start("Downloading files for {.pkg TX_leg_2020}")

path_data <- download_redistricting_file("TX", "data-raw/TX", year = 2020)

# TODO other files here (as necessary). All paths should start with `path_`
# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/TX_2020/shp_vtd.rds"
perim_path <- "data-out/TX_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong TX} shapefile")
    # read in redistricting data
    tx_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        join_vtd_shapefile(year = 2020) |>
        st_transform(EPSG$TX)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("TX", "INCPLACE_CDP", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("TX"), vtd)) |>
        select(-vtd)
    d_ssd <- make_from_baf("TX", "SLDU", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("TX"), vtd),
                  ssd_2010 = as.integer(sldu))
    d_shd <- make_from_baf("TX", "SLDL", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("TX"), vtd),
                  shd_2010 = as.integer(sldl))

    tx_shp <- tx_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        left_join(d_shd, by = "GEOID") |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, ssd_2010, .after = county) |>
        relocate(muni, county_muni, shd_2010, .after = county)

    # add the enacted plan
    tx_shp <- tx_shp |>
        left_join(y = leg_from_baf(state = "TX"), by = "GEOID")

    # CVAP columns
    state <- "TX"
    path_cvap <- here(paste0("data-raw/", state, "/cvap_2020.rds"))
    
    if (!file.exists(path_cvap)) {
      cvap <-
        cvap::cvap_distribute_censable(state) %>% select(GEOID, starts_with("cvap"))
      vtd_baf <- baf::baf('TX')[['VTD']]
      cvap <- cvap %>%
        left_join(vtd_baf %>% rename(GEOID = BLOCKID),
                  by = "GEOID")
      cvap <- cvap %>%
        mutate(GEOID = paste0(COUNTYFP, DISTRICT)) %>%
        select(GEOID, starts_with("cvap"))
      cvap <- cvap %>%
        group_by(GEOID) %>%
        summarize(across(.fns = sum))
      saveRDS(cvap, path_cvap, compress = "xz")
    } else {
      cvap <- read_rds(path_cvap)
    }
    
    cvap <- cvap %>% mutate(GEOID = paste0("48", GEOID))
    
    tx_shp <- tx_shp %>%
      left_join(cvap, by = "GEOID") %>%
      st_as_sf()
    
    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = tx_shp,
                             perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        tx_shp <- rmapshaper::ms_simplify(tx_shp, keep = 0.05,
                                                 keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    tx_shp$adj <- adjacency(tx_shp)

    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(tx_shp$adj, tx_shp$ssd_2020)
    ccm(tx_shp$adj, tx_shp$shd_2020)

    tx_shp <- tx_shp |>
        fix_geo_assignment(muni)

    write_rds(tx_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    tx_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong TX} shapefile")
}

# TODO visualize the enacted maps using:
# redistio::draw(tx_shp, tx_shp$ssd_2020)
# redistio::draw(tx_shp, tx_shp$shd_2020)
