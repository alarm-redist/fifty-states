###############################################################################
# Download and prepare data for `NV_cd_2020` analysis
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
cli_process_start("Downloading files for {.pkg NV_cd_2020}")

path_data <- download_redistricting_file("NV", "data-raw/NV")

# https://www.leg.state.nv.us/Division/Research/Districts/Reapp/2021/district-plans#districts-final
path_shp <- here("data-raw", "NV", "2021Congressional_Final_SB1_Amd2.shp")
if (!file.exists(path_shp)) {
    url <- "https://www.leg.state.nv.us/Division/Research/Documents/2021Congressional_Final_SB1_Amd2.zip"
    download(url, paste0(dirname(path_shp), "/nv.shp"))
    unzip(paste0(dirname(path_shp), "/nv.shp"), exdir = dirname(path_shp))
}

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NV_2020/shp_vtd.rds"
perim_path <- "data-out/NV_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NV} shapefile")
    # read in redistricting data
    nv_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$NV)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("NV", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("NV"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("NV", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("NV"), vtd),
                  cd_2010 = as.integer(cd))
    nv_shp <- left_join(nv_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by="GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # Add enacted ----
    dists <- read_sf(path_shp)
    nv_shp$cd_2020 <- as.numeric(dists$DISTRICT)[geo_match(from = nv_shp, to = dists, method = "area")]


    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = nv_shp,
                             perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        nv_shp <- rmapshaper::ms_simplify(nv_shp, keep = 0.05,
                                         keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    nv_shp$adj <- redist.adjacency(nv_shp)

    nv_shp <- nv_shp %>%
        fix_geo_assignment(muni)

    write_rds(nv_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    nv_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NV} shapefile")
}
