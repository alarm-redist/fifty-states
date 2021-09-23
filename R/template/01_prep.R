###############################################################################
# Download and prepare data for ```SLUG``` analysis
# ``COPYRIGHT``
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
cli_process_start("Downloading files for {.pkg ``SLUG``}")

path_data <- download_redistricting_file("``STATE``", "data-raw/``STATE``")

# TODO other files here (as necessary). All paths should start with `path_`
# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/``STATE``_``YEAR``/shp_vtd.rds"
perim_path <- "data-out/``STATE``_``YEAR``/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong ``STATE``} shapefile")
    # read in redistricting data
    ``state``_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$``STATE``)

    # add municipalities
    d_muni <- make_from_baf("``STATE``", "INCPLACE_CDP", "VTD") %>%
        mutate(vtd = str_sub(vtd, 4)) # TODO delete this line depending on how `vtd` variable is constructed / is unique
    d_cd <- make_from_baf("``STATE``", "CD", "VTD") %>%
        transmute(vtd = str_sub(vtd, 4), # TODO delete this line, maybe
                  cd_2010 = as.integer(cd))
    ``state``_shp <- left_join(``state``_shp, d_muni, by = "vtd") %>%
        left_join(d_cd, by="vtd") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = ``state``_shp,
                             perim_path = here(perim_path))

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ``state``_shp <- rmapshaper::ms_simplify(``state``_shp, keep = 0.05,
                                         keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ``state``_shp$adj <- redist.adjacency(``state``_shp)

    # TODO any custom adjacency graph edits here

    ``state``_shp <- ``state``_shp %>%
        fix_geo_assignment(muni)

    write_rds(``state``_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ``state``_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong ``STATE``} shapefile")
}

