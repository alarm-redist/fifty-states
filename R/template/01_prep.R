###############################################################################
# Download and prepare data for ```SLUG``` analysis
# ``COPYRIGHT``
###############################################################################

library(dplyr)
library(readr)
library(sf)
library(redist)
library(geomander)
library(cli)
library(here)
lapply(Sys.glob(here("R/*.R")), source) # load utilities

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg ``SLUG``}")

path_data = download_redistricting_file("``STATE``", "data-raw/``STATE``")

# TODO other files here (as necessary). All paths should start with `path_`
# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path = "data-out/``STATE``_``YEAR``/shp_vtd.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong ``STATE``} shapefile")
    # read in redistricting data
    ``state``_shp = read_csv(here(path_data), col_types = cols(GEOID20="c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$``STATE``)

    <ADD CODE TO GET CDPs>

    # TODO any additional columns or data you want to add should go here

    # simplifies geometry for faster processing, plotting, and smaller shapefiles.
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ``state``_shp = rmapshaper::ms_simplify(``state``_shp, keep = 0.05,
                                                keep_shapes = TRUE)
    }

    # create adjacency graph
    ``state``_shp$adj = redist.adjacency(``state``_shp)

    # TODO any custom adjacency graph edits here

    write_rds(``state``_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ``state``_shp = read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong ``STATE``} shapefile")
}

