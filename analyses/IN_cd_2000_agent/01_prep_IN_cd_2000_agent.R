###############################################################################
# Download and prepare data for `IN_cd_2000_agent` analysis
# © ALARM Project, April 2026
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
    library(stringr)
    devtools::load_all() # load utilities
})

# Load pre-built shapefile -----
shp_path <- "data-out/IN_2000_agent/shp_vtd.rds"

in_shp <- read_rds(here(shp_path))
cli_alert_success("Loaded {.strong IN} shapefile")
