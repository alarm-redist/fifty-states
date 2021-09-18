###############################################################################
# Download and prepare data for `IA_cd_2020` analysis
# © ALARM Project, September 2021
###############################################################################

suppressMessages({
library(dplyr)
library(readr)
library(sf)
library(redist)
library(geomander)
library(cli)
library(here)
devtools::load_all(".") # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg IA_cd_2020}")

path_data = download_redistricting_file("IA", "data-raw/IA")

# TODO other files here (as necessary). All paths should start with `path_`
# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path = "data-out/IA_2020/shp_vtd.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong IA} shapefile")
    # read in redistricting data
    ia_shp = read_csv(here(path_data), col_types = cols(GEOID20="c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$IA)

    d_cd = make_from_baf("IA", "CD", "VTD") %>%
        transmute(vtd = str_sub(vtd, 4),
               cd_2010 = as.integer(cd))
    ia_shp = left_join(ia_shp, d_cd, by="vtd") %>%
        relocate(cd_2010, .after=county)

    ia_shp = ia_shp %>%
        group_by(state, county) %>%
        summarize(cd_2010=cd_2010[1],
                  across(pop:area_water, sum))

    # simplifies geometry for faster processing, plotting, and smaller shapefiles.
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ia_shp = rmapshaper::ms_simplify(ia_shp, keep = 0.15,
                                         keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ia_shp$adj = redist.adjacency(ia_shp)

    write_rds(ia_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ia_shp = read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong IA} shapefile")
}

