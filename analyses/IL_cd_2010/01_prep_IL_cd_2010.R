###############################################################################
# Download and prepare data for `IL_cd_2010` analysis
# © ALARM Project, January 2023
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
cli_process_start("Downloading files for {.pkg IL_cd_2010}")

path_data <- download_redistricting_file("IL", "data-raw/IL", year = 2010)

# download the enacted plan.
url <- "https://redistricting.lls.edu/wp-content/uploads/il_2010_congress_2011-06-24_2021-12-31.zip"
path_enacted <- "data-raw/IL/IL_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "IL_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/IL/IL_enacted/PA 97-14 Congl shp files/PA 97-14 Congressional Districts.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/IL_2010/shp_vtd.rds"
perim_path <- "data-out/IL_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong IL} shapefile")
    # read in redistricting data
    il_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) %>%
        st_transform(EPSG$IL)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # Fix labeling
    il_shp$state <- "IL"

    # add municipalities
    d_muni <- make_from_baf("IL", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("IL"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("IL", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("IL"), vtd),
            cd_2000 = as.integer(cd))
    il_shp <- left_join(il_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    cd_shp <- tinytiger::tt_congressional_districts("IL", year = 2013) %>% # 2013 = 113th
        filter(CD113FP != "ZZ")
    il_shp <- il_shp %>%
        mutate(
            cd_2010 = as.integer(cd_shp$CD113FP)[geo_match(il_shp, cd_shp, method = "area")],
            .after = cd_2010
        )

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = il_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        il_shp <- rmapshaper::ms_simplify(il_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    il_shp$adj <- redist.adjacency(il_shp)

    il_shp <- il_shp %>%
        fix_geo_assignment(muni)

    write_rds(il_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    il_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong IL} shapefile")
}
