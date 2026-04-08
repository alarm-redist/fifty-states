###############################################################################
# Download and prepare data for MD_cd_2000 analysis
# © ALARM Project, March 2026
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

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg MD_cd_2000}")
path_data <- download_redistricting_file("MD", "data-raw/MD", year = 2000)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/MD_2000/shp_vtd.rds"
perim_path <- "data-out/MD_2000/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong MD} shapefile")
    # read in redistricting data
    md_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) %>%
        join_vtd_shapefile(year = 2000) %>%
        st_transform(EPSG$MD)

    md_shp <- md_shp %>%
        rename(muni = place) %>%
        mutate(muni = as.character(muni), county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_1990, .after = county)

    redistmetrics::prep_perims(
        shp = md_shp,
        perim_path = here(perim_path)
    ) %>%
    invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        md_shp <- rmapshaper::ms_simplify(md_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    md_shp <- md_shp %>%
        fix_geo_assignment(muni)

    # compute merge groups
    md_shp$merge_group <- contiguity_merges(md_shp)

    # create adjacency graph
    md_shp$adj <- redist.adjacency(md_shp)

    # Identify Bay units
    bay_ids <- c("24003ZZZZZZ", "24005ZZZZZZ", "24009ZZZZZZ",
        "24029ZZZZZZ", "24037ZZZZZZ", "24041ZZZZZZ")

    # Remove all existing edges from each Bay unit
    for (bid in bay_ids) {
        if (!(bid %in% md_shp$GEOID)) next
        i <- match(bid, md_shp$GEOID)
        nbr_ids <- md_shp$GEOID[md_shp$adj[[i]] + 1L]
        
        for (nid in nbr_ids) {
            md_shp$adj <- subtract_edge(
                md_shp$adj, bid, nid, ids = md_shp$GEOID
            )
        }
    }
    
    # Connect bay precincts
    edge_additions <- tribble(
        ~from,          ~to,
        "2403702-001",  "2403709-001",  
        "24029ZZZZZZ",  "2402906-001",
        "24005ZZZZZZ",  "2400515-019",
        "24003ZZZZZZ",  "2400306-024",
        "24009ZZZZZZ",  "2400902-002",
        "24037ZZZZZZ",  "2403701-001",
        "24041ZZZZZZ",  "2404105-001"
    )
  
    for (k in seq_len(nrow(edge_additions))) {
        u <- edge_additions$from[[k]]
        v <- edge_additions$to[[k]]
    
        if (u %in% md_shp$GEOID && v %in% md_shp$GEOID) {
            md_shp$adj <- add_edge(
                md_shp$adj, u, v, ids = md_shp$GEOID
            )
        }
    }

    write_rds(md_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    md_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong MD} shapefile")
}
