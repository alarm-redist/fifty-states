###############################################################################
# Download and prepare data for `NH_cd_2020` analysis
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
cli_process_start("Downloading files for {.pkg NH_cd_2020}")

path_data <- download_redistricting_file("NH", "data-raw/NH")

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NH_2020/shp_vtd.rds"
perim_path <- "data-out/NH_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NH} shapefile")
    # read in redistricting data
    nh_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$NH)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("NH", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("NH"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("NH", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("NH"), vtd),
            cd_2010 = as.integer(cd))
    nh_shp <- left_join(nh_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add proposed ----
    # built from hand from this pdf:
    #
    r <- c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 29,
        33, 35, 113, 152, 157, 163, 164, 166, 167, 168, 169, 170, 171, 172,
        173, 174, 175, 176, 177, 179, 191, 193, 197, 201, 205, 206, 217,
        218, 219, 220, 221, 222, 224, 225, 227, 229, 231, 232, 238, 239,
        240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252,
        253, 254, 255, 256, 257, 258, 259, 260, 262, 263, 264, 265, 266,
        267, 269, 275, 276, 277, 278, 279, 280, 281, 282, 296, 309)
    # built from hand from this pdf:
    #
    d <- c(1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
        19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34,
        35, 115, 152, 157, 166, 167, 168, 169, 170, 171, 172, 173, 174,
        175, 176, 177, 179, 225, 238, 240, 241, 242, 243, 244, 245, 246,
        247, 248, 250, 251, 252, 253, 254, 255, 257, 258, 259, 260, 261,
        262, 263, 264, 265, 266, 268, 269, 270, 271, 272, 273, 274, 275,
        277, 278, 279, 280, 282, 283, 284, 285, 286, 287, 288, 289, 290,
        291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 302, 303,
        304, 305, 306, 307, 308, 309)
    nh_shp <- nh_shp %>%
        mutate(rn = row_number(),
            rep_prop = if_else(rn %in% r, 1L, 2L),
            dem_prop = if_else(rn %in% d, 1L, 2L),
            .after = cd_2010)

    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = nh_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        nh_shp <- rmapshaper::ms_simplify(nh_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    nh_shp$adj <- redist.adjacency(nh_shp)

    nh_shp <- nh_shp %>%
        fix_geo_assignment(muni)

    write_rds(nh_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    nh_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NH} shapefile")
}
