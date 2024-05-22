###############################################################################
# Download and prepare data for `KS_cd_2020` analysis
# © ALARM Project, January 2022
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
cli_process_start("Downloading files for {.pkg KS_cd_2020}")

path_data <- download_redistricting_file("KS", "data-raw/KS")

# download the enacted plan.
url <- "https://thearp.org/documents/718/KS_CD_Enacted02092022.zip"
path_enacted <- "data-raw/KS/KS_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "KS_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/KS/KS_enacted/KS_CD_enacted02092022.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/KS_2020/shp_vtd.rds"
perim_path <- "data-out/KS_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong KS} shapefile")
    # read in redistricting data
    ks_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$KS)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("KS", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("KS"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("KS", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("KS"), vtd),
            cd_2010 = as.integer(cd))
    ks_shp <- left_join(ks_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    cd_shp <- st_transform(cd_shp, st_crs(ks_shp))
    ks_shp <- ks_shp %>%
        mutate(cd_2020 = as.integer(cd_shp$district)[
            geo_match(ks_shp, cd_shp, method = "area")],
        .after = cd_2010)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ks_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ks_shp <- rmapshaper::ms_simplify(ks_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ks_shp$adj <- redist.adjacency(ks_shp)

    ks_shp <- ks_shp %>%
        fix_geo_assignment(muni)

    write_rds(ks_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ks_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong KS} shapefile")
}
