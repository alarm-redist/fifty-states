###############################################################################
# Download and prepare data for `CO_cd_2020` analysis
# © ALARM Project, October 2021
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
cli_process_start("Downloading files for {.pkg CO_cd_2020}")

path_data <- download_redistricting_file("CO", "data-raw/CO")

path_baf_zip <- "data-raw/CO/baf.zip"
path_baf <- "data-raw/CO/2021_Final_Approved_Congressional_Plan.txt"
if (!file.exists(path_baf_zip)) {
    url <- "https://redistrict2020.org/files/CO-2021-09-ushouse-coleman/CO-2021-09-ushouse-coleman-block-assignment.zip"
    download(url, path_baf_zip)
    unzip(path_baf, exdir = dirname(path_baf))
}

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/CO_2020/shp_vtd.rds"
perim_path <- "data-out/CO_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong CO} shapefile")
    # read in redistricting data
    co_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$CO)  %>%
        rename_with(\(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("CO", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("CO"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("CO", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("CO"), vtd),
            cd_2010 = as.integer(cd))
    co_shp <- left_join(co_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # Add enacted ----
    baf <- read_csv(path_baf, col_names = c("GEOID", "district"))
    baf_vtd <- PL94171::pl_get_baf("CO", geographies = "VTD")$VTD %>%
        rename(GEOID = BLOCKID, county = COUNTYFP, vtd = DISTRICT)
    baf <- baf %>% left_join(baf_vtd, by = "GEOID")
    baf <- baf %>% select(-GEOID) %>%
        mutate(GEOID = paste0("08", county, vtd)) %>%
        select(-county, vtd)

    baf <- baf %>%
        group_by(GEOID) %>%
        count(district) %>%
        filter(n == max(n)) %>%
        ungroup()

    baf <- baf %>% select(GEOID, cd_2020 = district)

    co_shp <- co_shp %>% left_join(baf, by = "GEOID")

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = co_shp,
        perim_path = here(perim_path),
        ncores = 8)

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        co_shp <- rmapshaper::ms_simplify(co_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    co_shp$adj <- redist.adjacency(co_shp)

    co_shp <- co_shp %>%
        fix_geo_assignment(muni)

    write_rds(co_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    co_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong CO} shapefile")
}
