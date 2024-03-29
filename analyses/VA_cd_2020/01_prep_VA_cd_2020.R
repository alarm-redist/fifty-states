###############################################################################
# Download and prepare data for `VA_cd_2020` analysis
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
cli_process_start("Downloading files for {.pkg VA_cd_2020}")

path_data <- download_redistricting_file("VA", "data-raw/VA")

url <- "https://dl.boxcloud.com/zip_download/zip_download?ProgressReportingKey=5A9CC158FE2DCF60713C56229863A5C0&d=153073836778&ZipFileName=SCV%20Final%20Shape%20%26%20Block%20Files.zip&Timestamp=1659990432&SharedLink=https%3A%2F%2Fvacourts.box.com%2Fs%2F2t0xgsmshemsveou2jx55h6tl38ml8jx&HMAC2=8c474c4a21100a056013473a2d36587a176cd737d62389f21f6d85d39f7a1403"
path_enacted <- "data-raw/VA/VA_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "VA_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/VA/VA_enacted/SCV FINAL CD.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/VA_2020/shp_vtd.rds"
perim_path <- "data-out/VA_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong VA} shapefile")
    # read in redistricting data
    va_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$VA)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("VA", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("VA"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("VA", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("VA"), vtd),
            cd_2010 = as.integer(cd))
    va_shp <- left_join(va_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add 2020 enacted plan
    cd_shp <- st_read(here(path_enacted))
    cd_shp <- st_transform(cd_shp, crs = st_crs(va_shp))
    va_shp <- mutate(va_shp,
        cd_2020 = geo_match(va_shp, cd_shp, method = "area"),
        .after = cd_2010)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = va_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        va_shp <- rmapshaper::ms_simplify(va_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    va_shp$adj <- redist.adjacency(va_shp)

    va_shp <- va_shp %>%
        fix_geo_assignment(muni)

    write_rds(va_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    va_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong VA} shapefile")
}
