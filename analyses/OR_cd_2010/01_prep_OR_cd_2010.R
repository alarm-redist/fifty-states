###############################################################################
# Download and prepare data for `OR_cd_2010` analysis
# © ALARM Project, August 2022
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
cli_process_start("Downloading files for {.pkg OR_cd_2010}")

path_data <- download_redistricting_file("OR", "data-raw/OR")

# download the enacted plan.
url <- "https://www.oregonlegislature.gov/la/2011_Redistricting/SB_0990.zip"
path_enacted <- "data-raw/OR/OR_enacted_2010.zip"
download(url, here(path_enacted))
unzip(here(path_enacted), exdir = here(dirname(path_enacted), "OR_enacted_2010"))
file.remove(path_enacted)
path_enacted <- "data-raw/OR/OR_enacted_2010/SB 0990/Congressional_Districts.shp"
# TODO other files here (as necessary). All paths should start with `path_`
# If large, consider checking to see if these files exist before downloading

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/OR_2010/shp_vtd.rds"
perim_path <- "data-out/OR_2010/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong OR} shapefile")
    # read in redistricting data
    or_shp <- read_csv(here(path_data)) %>%
        join_vtd_shapefile(year = 2010) #%>%
        mutate(state = "OR", .before=everything()) %>%
        st_transform(EPSG$OR)  %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID")) %>%
    relocate(GEOID, .before = state)

    # add municipalities
    d_muni <- make_from_baf("OR", "INCPLACE_CDP", "VTD", year = 2010)  %>%
        mutate(GEOID = paste0(censable::match_fips("OR"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("OR", "CD", "VTD", year = 2010)  %>%
        transmute(GEOID = paste0(censable::match_fips("OR"), vtd),
                  cd_2000 = as.integer(cd))
    or_shp <- left_join(or_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by="GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2000, .after = county)

    # add the enacted plan
    cd_shp <- st_read(here(path_enacted))
    or_shp <- or_shp %>%
        mutate(cd_2010 = as.integer(cd_shp$DISTRICT)[
            geo_match(or_shp, cd_shp, method = "area")],
            .after = cd_2000)

    # TODO any additional columns or data you want to add should go here

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = or_shp, perim_path = here(perim_path)) %>% invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    # TODO feel free to delete if this dependency isn't available
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        or_shp <- rmapshaper::ms_simplify(or_shp, keep = 0.05,
                                         keep_shapes = TRUE) %>%
            suppressWarnings()
    }

    # Highway plot for geographical links constraint
    if (FALSE) {
        d_roads <- tigris::primary_secondary_roads("OR", 2010) %>%
            st_transform(EPSG$OR)

        ggplot(or_shp, aes(fill = county)) +
            geom_sf(size = 0.2, color = "white") +
            geom_sf(size = 0.7, color = "red", fill = NA, inherit.aes = FALSE,
                    data = summarize(group_by(or_shp, cd), is_coverage = TRUE)) +
            geom_sf(size = 0.4, color = "black", inherit.aes = FALSE,
                    data = filter(d_roads, RTTYP %in% c("I", "U", "S"))) +
            geom_sf_text(aes(label = county), size = 2.2, color = "black",
                         data = filter(or_shp, area_land >= 1e8)) +
            scale_fill_manual(values = sf.colors(36, categorical = TRUE), guide = "none") +
            theme_void()
    }

    # create adjacency graph
    or_shp$adj <- redist.adjacency(or_shp)

    # TODO any custom adjacency graph edits here

    or_shp <- or_shp %>%
        fix_geo_assignment(muni)

    write_rds(or_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    or_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong OR} shapefile")
}

