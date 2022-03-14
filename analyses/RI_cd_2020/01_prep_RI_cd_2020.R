###############################################################################
# Download and prepare data for `RI_cd_2020` analysis
# © ALARM Project, February 2022
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
cli_process_start("Downloading files for {.pkg RI_cd_2020}")

path_data <- download_redistricting_file("RI", "data-raw/RI")

# download the enacted plan.
url <- "https://thearp.org/documents/914/RI_CD_Enacted02162022.zip"
path_enacted <- "data-raw/RI/RI_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "RI_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/RI/RI_enacted/RI_CD_Enacted02162022.shp" # TODO use actual SHP

# download enacted state senate plan
url_sd <- "https://thearp.org/documents/920/RI_SD_Enacted02162022.zip"
path_enacted_sd <- "data-raw/RI/RI_enacted_sd.zip"
download(url_sd, here(path_enacted_sd))
unzip(here(path_enacted_sd), exdir = here(dirname(path_enacted_sd), "RI_enacted_sd"))
file.remove(path_enacted_sd)
path_enacted_sd <- "data-raw/RI/RI_enacted_sd/RI_SD_Enacted02162022.shp" # TODO use actual SHP

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/RI_2020/shp_vtd.rds"
perim_path <- "data-out/RI_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong RI} shapefile")
    # read in redistricting data
    ri_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$RI)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("RI", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("RI"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("RI", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("RI"), vtd),
            cd_2010 = as.integer(cd))
    ri_shp <- left_join(ri_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    cd_shp <- st_transform(cd_shp, st_crs(ri_shp))
    sd_shp <- st_read(here(path_enacted_sd))
    sd_shp <- st_transform(sd_shp, st_crs(ri_shp))
    ri_shp <- ri_shp %>%
        mutate(cd_2020 = as.integer(cd_shp$DISTRICT)[
            geo_match(ri_shp, cd_shp, method = "area")],
        .after = cd_2010) %>%
        mutate(sd_2020 = as.integer(sd_shp$DISTRICT)[
            geo_match(ri_shp, sd_shp, method = "area")],
        .after = cd_2020)

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = ri_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ri_shp <- rmapshaper::ms_simplify(ri_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ri_shp$adj <- redist.adjacency(ri_shp)
    ri_shp$adj <- add_edge(ri_shp$adj, 395, 416)

    ri_shp <- ri_shp %>%
        fix_geo_assignment(muni)

    write_rds(ri_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ri_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong RI} shapefile")
}
