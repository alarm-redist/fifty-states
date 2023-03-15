###############################################################################
# Download and prepare data for `NC_cd_2010` analysis
# © ALARM Project, April 2022
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
cli_process_start("Downloading files for {.pkg NC_cd_2010}")

path_data <- download_redistricting_file("NC", "data-raw/NC", year = 2010)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NC_2010/shp_vtd.rds"
perim_path <- "data-out/NC_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NC} shapefile")
    # read in redistricting data
    nc_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$NC)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("NC", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("NC"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("NC", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("NC"), vtd),
            cd_2000 = as.integer(cd))
    nc_shp <- left_join(nc_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    baf_cd113 <- make_from_baf("NC", from = read_baf_cd113("NC"), year = 2010) %>%
        rename(GEOID = vtd) %>%
        mutate(
            GEOID = paste0("37", GEOID),
            cd_2010 = as.integer(cd_2010)
        )
    nc_shp <- nc_shp %>%
        left_join(baf_cd113, by = "GEOID")
    nc_shp <- nc_shp %>%
        relocate(cd_2000, cd_2010, .after = cd_2000)

    # remove fully NA columns
    nc_shp <- nc_shp %>%
        select(-adv_18, -arv_18)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = nc_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        nc_shp <- rmapshaper::ms_simplify(nc_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    nc_shp$adj <- redist.adjacency(nc_shp)

    nc_shp <- nc_shp %>%
        fix_geo_assignment(muni)

    write_rds(nc_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    nc_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NC} shapefile")
}
