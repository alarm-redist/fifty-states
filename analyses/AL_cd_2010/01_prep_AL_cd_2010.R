###############################################################################
# Download and prepare data for `AL_cd_2010` analysis
# © ALARM Project, November 2022
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
cli_process_start("Downloading files for {.pkg AL_cd_2010}")

path_data <- download_redistricting_file("AL", "data-raw/AL", year = 2010)

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/al_2010_congress_2011-11-21_2021-12-31.zip"
path_enacted <- "data-raw/AL/AL_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "AL_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/AL/AL_enacted/68b815c2-a1f7-4b05-b530-84c1f624fe6b202048-1-ihxzzh.0q5k.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/AL_2010/shp_vtd.rds"
perim_path <- "data-out/AL_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong AL} shapefile")
    # read in redistricting data
    al_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$AL)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("AL", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("AL"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("AL", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("AL"), vtd),
            cd_2000 = as.integer(cd))
    al_shp <- left_join(al_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    al_shp <- al_shp %>%
        mutate(cd_2010 = as.integer(cd_shp$DISTNAME %>% substr(1, 1))[
            geo_match(al_shp, cd_shp, method = "area")],
        .after = cd_2000)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = al_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        al_shp <- rmapshaper::ms_simplify(al_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    al_shp$adj <- redist.adjacency(al_shp)

    al_shp <- al_shp %>%
        fix_geo_assignment(muni)

    write_rds(al_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    al_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong AL} shapefile")
}
