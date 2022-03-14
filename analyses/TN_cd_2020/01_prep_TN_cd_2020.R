###############################################################################
# Download and prepare data for `TN_cd_2020` analysis
# © ALARM Project, January 2022
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
cli_process_start("Downloading files for {.pkg TN_cd_2020}")

path_data <- download_redistricting_file("TN", "data-raw/TN")

# download the enacted plan.
url <- "https://thearp.org/documents/941/TN_CD_Enacted02062022.zip"
path_enacted <- "data-raw/TN/TN_enacted.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "TN_enacted"))
file.remove(path_enacted)
path_enacted <- "data-raw/TN/TN_enacted/TN_CD_Enacted_02060222.shp"

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/TN_2020/shp_vtd.rds"
perim_path <- "data-out/TN_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong TN} shapefile")
    # read in redistricting data
    tn_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$TN)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("TN", "INCPLACE_CDP", "VTD")  %>%
        mutate(GEOID = paste0(censable::match_fips("TN"), vtd)) %>%
        select(-vtd) %>%
        mutate(muni_name = recode(muni,
            `48000` = "Memphis",
            `52006` = "Nashville",
            `38320` = "Johnson City",
            `51560` = "Murfreesboro",
            `14000` = "Chattanooga",
            `15160` = "Clarksville",
            `37640` = "Jackson",
            `27740` = "Franklin",
            `33280` = "Hendersonville",
            `40000` = "Knoxville",
            `08280` = "Brentwood",
            `28960` = "Germantown",
            `41200` = "La Vergne",
            `69420` = "Smyrna",
            `70580` = "Spring Hill",
            `28540` = "Gallatin",
            `15400` = "Cleveland",
            `39560` = "Kingsport",
            `03440` = "Bartlett",
            `16420` = "Collierville",
            .default = NA_character_))

    d_cd <- make_from_baf("TN", "CD", "VTD")  %>%
        transmute(GEOID = paste0(censable::match_fips("TN"), vtd),
            cd_2010 = as.integer(cd))
    tn_shp <- left_join(tn_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni_name, sep = " - "))) %>%
        relocate(muni_name, county_muni, cd_2010, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    tn_shp <- tn_shp %>%
        mutate(cd_2020 = as.integer(cd_shp$district)[
            geo_match(tn_shp, cd_shp, method = "area")],
        .after = cd_2010)

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(shp = tn_shp,
        perim_path = here(perim_path)) %>%
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        tn_shp <- rmapshaper::ms_simplify(tn_shp, keep = 0.05,
            keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # create adjacency graph
    tn_shp$adj <- redist.adjacency(tn_shp)

    tn_shp <- tn_shp %>%
        fix_geo_assignment(muni)

    write_rds(tn_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    tn_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong TN} shapefile")
}
