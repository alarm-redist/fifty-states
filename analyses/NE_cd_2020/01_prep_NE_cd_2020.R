###############################################################################
# Download and prepare data for `NE_cd_2020` analysis
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
cli_process_start("Downloading files for {.pkg NE_cd_2020}")

path_data <- download_redistricting_file("NE", "data-raw/NE")

url <- "https://redistricting.lls.edu/wp-content/uploads/ne_2020_congress_2021-09-30_2031-06-30.zip"
path_enacted <- "data-raw/NE/NE_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "NE_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/NE/NE_enacted/CONG21-39002(1)/CONG21-39002(1).shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NE_2020/shp_vtd.rds"
perim_path <- "data-out/NE_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NE} shapefile")
    # read in redistricting data
    ne_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$NE)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("NE", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("NE"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("NE", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("NE"), vtd),
            cd_2010 = as.integer(cd))
    ne_shp <- left_join(ne_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    cd_shp <- st_read(here(path_enacted))
    ne_shp <- mutate(ne_shp,
        cd_2020 = geo_match(ne_shp, cd_shp, method = "area"),
        .after = cd_2010)

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = ne_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ne_shp <- rmapshaper::ms_simplify(ne_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ne_shp$adj <- redist.adjacency(ne_shp)

    ne_shp <- ne_shp %>%
        fix_geo_assignment(muni)

    write_rds(ne_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ne_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NE} shapefile")
}
