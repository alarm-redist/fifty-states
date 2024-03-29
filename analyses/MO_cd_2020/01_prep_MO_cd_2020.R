###############################################################################
# Download and prepare data for `MO_cd_2020` analysis
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
cli_process_start("Downloading files for {.pkg MO_cd_2020}")

path_data <- download_redistricting_file("MO", "data-raw/MO")

# download the enacted plan
url <- "https://house.mo.gov/billtracking/bills221/RedistrictingMaps/5799H_02T.xlsx"
path_enacted <- "data-raw/MO/MO_enacted.xlsx"
download(url, here(path_enacted))

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MO_2020/shp_vtd.rds"
perim_path <- "data-out/MO_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong MO} shapefile")
    # read in redistricting data
    mo_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$MO)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("MO", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("MO"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("MO", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("MO"), vtd),
            cd_2010 = as.integer(cd))
    mo_shp <- left_join(mo_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add the enacted plan
    baf <- readxl::read_xlsx(here(path_enacted), col_types = c("text", "text")) %>%
        rename(
            GEOID = Block,
            cd_2020 = `DistrictID:1`
        )
    baf_vtd <- PL94171::pl_get_baf("MO", geographies = "VTD")$VTD %>%
        rename(GEOID = BLOCKID, county = COUNTYFP, vtd = DISTRICT)
    baf <- baf %>% left_join(baf_vtd, by = "GEOID")
    baf <- baf %>% select(-GEOID) %>%
        mutate(GEOID = paste0("29", county, vtd)) %>%
        select(-county, vtd)

    baf <- baf %>%
        group_by(GEOID) %>%
        summarize(cd_2020  = Mode(cd_2020)) %>%
        select(GEOID, cd_2020)

    mo_shp <- mo_shp %>% left_join(baf, by = "GEOID")

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = mo_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        mo_shp <- rmapshaper::ms_simplify(mo_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    mo_shp$adj <- redist.adjacency(mo_shp)

    mo_shp <- mo_shp %>%
        fix_geo_assignment(muni)

    write_rds(mo_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    mo_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong MO} shapefile")
}
