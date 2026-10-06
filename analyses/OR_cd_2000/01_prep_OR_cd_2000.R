###############################################################################
# Download and prepare data for `OR_cd_2000` analysis
# © ALARM Project, July 2025
###############################################################################

suppressMessages({
    library(dplyr)
    library(readr)
    library(sf)
    library(redist)
    library(geomander)
    library(baf)
    library(cli)
    library(here)
    devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg OR_cd_2000}")

path_data <- download_redistricting_file("OR", "data-raw/OR", year = 2000, overwrite = TRUE)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/OR_2000/shp_vtd.rds"
perim_path <- "data-out/OR_2000/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong OR} shapefile")
    # read in redistricting data
    or_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
        join_vtd_shapefile(year = 2000) %>%
        st_transform(EPSG$OR)

    or_shp <- or_shp %>%
        rename(muni = place) %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_1990, .after = county)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = or_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        or_shp <- rmapshaper::ms_simplify(or_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    or_shp$adj <- redist.adjacency(or_shp)

    # Disconnect counties not connected by state or federal highways
    # (counties identified by 3-digit FIPS, matching OR_cd_1990)
    disconn_cty <- function(adj, cty1, cty2) {
        v1 <- which(or_shp$county == cty1)
        if (length(v1) == 0) stop(cty1, " not found")
        v2 <- which(or_shp$county == cty2)
        if (length(v2) == 0) stop(cty2, " not found")
        vs <- tidyr::crossing(v1, v2)
        remove_edge(adj, vs$v1, vs$v2)
    }

    or_shp$adj <- or_shp$adj %>%
        disconn_cty("015", "033") %>%  # Curry – Josephine
        disconn_cty("053", "041") %>%  # Polk – Lincoln
        disconn_cty("003", "039") %>%  # Benton – Lane
        disconn_cty("047", "031") %>%  # Marion – Jefferson
        disconn_cty("047", "065") %>%  # Marion – Wasco
        disconn_cty("063", "001") %>%  # Wallowa – Baker
        disconn_cty("049", "023") %>%  # Morrow – Grant
        disconn_cty("013", "023") %>%  # Crook – Grant
        disconn_cty("017", "025") %>%  # Deschutes – Harney
        disconn_cty("017", "043")      # Deschutes – Linn

    or_shp <- or_shp %>%
        fix_geo_assignment(muni)

    write_rds(or_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    or_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong OR} shapefile")
}
