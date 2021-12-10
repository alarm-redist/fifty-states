###############################################################################
# Download and prepare data for `MD_cd_2020` analysis
# © ALARM Project, November 2021
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
cli_process_start("Downloading files for {.pkg MD_cd_2020}")

path_data <- download_redistricting_file("MD", "data-raw/MD")

path_baf <- "data-raw/MD/LRACPROPOSEDCONGRESSPLAN2.xlsx"
if (!file.exists(path_baf)) {
    url <- "https://redistricting.mgaleg.maryland.gov/MD-Proposed-Plans-Data/LRACPROPOSEDCONGRESSPLAN2.xlsx"
    download(url, path_baf)
}


cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MD_2020/shp_vtd.rds"
perim_path <- "data-out/MD_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong MD} shapefile")
    # read in redistricting data
    md_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$MD)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("MD", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("MD"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("MD", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("MD"), vtd),
            cd_2010 = as.integer(cd))
    md_shp <- left_join(md_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # Add enacted ----
    baf <- readxl::read_xlsx(path_baf) %>% rename(GEOID = Block, district = `DistrictID:1`)
    baf_vtd <- PL94171::pl_get_baf("MD", geographies = "VTD")$VTD %>%
        rename(GEOID = BLOCKID, county = COUNTYFP, vtd = DISTRICT)
    baf <- baf %>% left_join(baf_vtd, by = "GEOID")
    baf <- baf %>% select(-GEOID) %>%
        mutate(GEOID = paste0("24", county, vtd)) %>%
        select(-county, vtd)

    baf <- baf %>%
        group_by(GEOID) %>%
        summarize(district = Mode(district))

    baf <- baf %>% select(GEOID, cd_2020 = district)

    md_shp <- md_shp %>% left_join(baf, by = "GEOID")

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = md_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        md_shp <- rmapshaper::ms_simplify(md_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    md_shp$adj <- redist.adjacency(md_shp)

    md_shp <- md_shp %>%
        fix_geo_assignment(muni)

    write_rds(md_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    md_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong MD} shapefile")
}
