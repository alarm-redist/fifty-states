###############################################################################
# Download and prepare data for `NJ_cd_2020` analysis
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
cli_process_start("Downloading files for {.pkg NJ_cd_2020}")

path_data <- download_redistricting_file("NJ", "data-raw/NJ")

# download the enacted plan.
path_enacted <- "data-raw/NJ/nj_baf.txt"
url <- "https://www.njredistrictingcommission.org/documents/2021/Data2021/NJ_CONG_FINAL_REPORTS_block_assignment.txt"
if (!file.exists(path_enacted)) {
    download(url, here(path_enacted))
}

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NJ_2020/shp_vtd.rds"
perim_path <- "data-out/NJ_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NJ} shapefile")
    # read in redistricting data
    nj_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$NJ)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("NJ", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("NJ"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("NJ", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("NJ"), vtd),
            cd_2010 = as.integer(cd))
    nj_shp <- left_join(nj_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add the enacted plan
    baf <- read_csv(here(path_enacted), col_types = "cc",
        col_names = c("GEOID", "cd_2020"))
    baf_vtd <- PL94171::pl_get_baf("NJ", geographies = "VTD")$VTD %>%
        rename(GEOID = BLOCKID, county = COUNTYFP, vtd = DISTRICT)
    baf <- baf %>% left_join(baf_vtd, by = "GEOID")
    baf <- baf %>% select(-GEOID) %>%
        mutate(GEOID = paste0("34", county, vtd)) %>%
        select(-county, vtd)
    baf <- baf %>%
        group_by(GEOID) %>%
        summarize(cd_2020 = Mode(cd_2020))

    nj_shp <- nj_shp %>%
        left_join(baf, by = "GEOID") %>%
        relocate(cd_2020,
            .after = cd_2010)

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = nj_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        nj_shp <- rmapshaper::ms_simplify(nj_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    nj_shp$adj <- redist.adjacency(nj_shp)

    nj_shp <- nj_shp %>%
        fix_geo_assignment(muni)

    write_rds(nj_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    nj_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NJ} shapefile")
}
