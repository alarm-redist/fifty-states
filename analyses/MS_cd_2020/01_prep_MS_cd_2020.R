###############################################################################
# Download and prepare data for `MS_cd_2020` analysis
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
cli_process_start("Downloading files for {.pkg MS_cd_2020}")

path_data <- download_redistricting_file("MS", "data-raw/MS")

# Download the enacted plan.
url <- "https://www.maris.state.ms.us/HTML/Redistricting/Proposed/Data/MS_ProposedCongDists_2021.zip"
path_shp <- here("data-raw/MS/MS_ProposedCongDists_2021.shp")
if (!file.exists(path_shp)) {
    download(url, paste0(dirname(path_shp), "/ms.zip"))
    unzip(paste0(dirname(path_shp), "/ms.zip"), exdir = dirname(path_shp))
}

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MS_2020/shp_vtd.rds"
perim_path <- "data-out/MS_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong MS} shapefile")
    # read in redistricting data
    ms_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$MS)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("MS", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("MS"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("MS", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("MS"), vtd),
                  cd_2010 = as.integer(cd))
    ms_shp <- left_join(ms_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add enacted ----
    cd_shp <- st_read(here(path_shp))
    ms_shp <- ms_shp %>%
        mutate(cd_2020 = as.integer(cd_shp$DISTRICT)[
            geo_match(ms_shp, cd_shp, method = "area")],
            .after = cd_2010)

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = ms_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ms_shp <- rmapshaper::ms_simplify(ms_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ms_shp$adj <- redist.adjacency(ms_shp)

    ms_shp <- ms_shp %>%
        fix_geo_assignment(muni)

    write_rds(ms_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ms_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong MS} shapefile")
}
