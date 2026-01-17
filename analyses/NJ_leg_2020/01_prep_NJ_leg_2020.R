###############################################################################
# Download and prepare data for `NJ_leg_2020` analysis
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
cli_process_start("Downloading files for {.pkg NJ_leg_2020}")

path_data <- download_redistricting_file("NJ", "data-raw/NJ", year = 2020)

# TODO other files here (as necessary). All paths should start with `path_`
# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NJ_2020/shp_vtd.rds"
perim_path <- "data-out/NJ_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NJ} shapefile")
    # read in redistricting data
    nj_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) |>
        join_vtd_shapefile(year = 2020) |>
        st_transform(EPSG$NJ)  |>
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("NJ", "INCPLACE_CDP", "VTD", year = 2020)  |>
        mutate(GEOID = paste0(censable::match_fips("NJ"), vtd)) |>
        select(-vtd)
    d_ssd <- make_from_baf("NJ", "SLDU", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("NJ"), vtd),
                  ssd_2010 = as.integer(sldu))
    d_shd <- make_from_baf("NJ", "SLDL", "VTD", year = 2020)  |>
        transmute(GEOID = paste0(censable::match_fips("NJ"), vtd),
                  shd_2010 = as.integer(sldl))

    nj_shp <- nj_shp |>
        left_join(d_muni, by = "GEOID") |>
        left_join(d_ssd, by = "GEOID") |>
        left_join(d_shd, by = "GEOID") |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, ssd_2010, .after = county) |>
        relocate(muni, county_muni, shd_2010, .after = county)

    # add the enacted plan
    nj_shp <- nj_shp |>
        left_join(y = leg_from_baf(state = "NJ"), by = "GEOID")


    # TODO any additional columns or data you want to add should go here
    # add CVAP
    state <- "NJ"
    path_cvap <- here(paste0("data-raw/", state, "/cvap.rds"))
    
    if (!file.exists(path_cvap)) {
      cvap <-
        cvap::cvap_distribute_censable(state) %>% select(GEOID, starts_with("cvap"))
      vtd_baf <- PL94171::pl_get_baf(state)$VTD
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
    
    cvap <- cvap %>% mutate(GEOID = paste0("34", GEOID))
    
    nj_shp <- nj_shp %>%
      left_join(cvap, by = "GEOID") %>%
      st_as_sf()
    
    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = nj_shp,
                             perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        nj_shp <- rmapshaper::ms_simplify(nj_shp, keep = 0.05,
                                                 keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    nj_shp$adj <- adjacency(nj_shp)

    # TODO any custom adjacency graph edits here

    # check max number of connected components
    # 1 is one fully connected component, more is worse
    ccm(nj_shp$adj, nj_shp$ssd_2020)
    ccm(nj_shp$adj, nj_shp$shd_2020)

    nj_shp <- nj_shp |>
        fix_geo_assignment(muni)

    write_rds(nj_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    nj_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NJ} shapefile")
}

# TODO visualize the enacted maps using:
# redistio::draw(nj_shp, nj_shp$ssd_2020)
# redistio::draw(nj_shp, nj_shp$shd_2020)
