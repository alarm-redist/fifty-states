###############################################################################
# Download and prepare data for `CA_cd_2020` analysis
# © ALARM Project, February 2022
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
cli_process_start("Downloading files for {.pkg CA_cd_2020}")

path_data <- download_redistricting_file("CA", "data-raw/CA", type = "block")

# download the enacted plan.
url <- "https://drive.google.com/uc?export=download&id=1GQjROCuMQ7_yg-NuKJ524wpR6hWAdwu1"
path_enacted <- "data-raw/CA/CA_enacted.csv"
download(url, here(path_enacted))

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/CA_2020/shp_vtd.rds"
perim_path <- "data-out/CA_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong CA} shapefile")
    # read in redistricting data
    ca_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        left_join(y = tigris::blocks("CA", year = 2020), by  = "GEOID20") %>%
        st_as_sf() %>%
        st_transform(EPSG$CA)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- PL94171::pl_get_baf("CA", "INCPLACE_CDP")[[1]] %>%
        rename(GEOID = BLOCKID, muni = PLACEFP)
    d_cd <- PL94171::pl_get_baf("CA", "CD")[[1]]  %>%
        transmute(GEOID = BLOCKID,
                  cd_2010 = as.integer(DISTRICT))
    ca_shp <- left_join(ca_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    # add the enacted plan
    cd_baf <- read_csv(path_enacted, col_names = c("GEOID", "cd_2020"),
                       col_types = c("ci"))

    ca_shp <- ca_shp %>%
        left_join(cd_baf, by = "GEOID") %>%
        mutate(tract = str_sub(GEOID, 1, 11)) %>%
        group_by(tract) %>%
        summarize(cd_2010 = Mode(cd_2010),
                  cd_2020 = Mode(cd_2020),
                  muni = Mode(muni),
                  state = unique(state),
                  county = unique(county),
                  across(where(is.numeric), sum)
        )

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = ca_shp,
                             perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ca_shp <- rmapshaper::ms_simplify(ca_shp, keep = 0.05,
                                         keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ca_shp$adj <- redist.adjacency(ca_shp)

    ca_shp$adj <- geomander::suggest_neighbors(ca_shp, ca_shp$adj)

    ca_shp <- ca_shp %>%
        fix_geo_assignment(muni)

    write_rds(ca_shp, here(shp_path), compress = "xz")
    cli_process_done()
} else {
    ca_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong CA} shapefile")
}

