###############################################################################
# Download and prepare data for `OR_cd_2020` analysis
# © ALARM Project, October 2021
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
cli_process_start("Downloading files for {.pkg OR_cd_2020}")

url <- "https://raw.githubusercontent.com/alarm-redist/census-2020/main/census-vest-2020/or_2020_block.csv"
path_data <- "data-raw/OR/or_2020_block.csv"
download(url, here(path_data))

# updated link: manual download from https://geo.maps.arcgis.com/home/item.html?id=b43a1bf5997d4863a45023bfe7a047b1
# url <- "https://oregon-redistricting.esriemcs.com/portal/sharing/rest/content/items/4ebcfc87b06c4e79b65685135329513c/data"
# path_enacted <- "data-raw/OR/or_enacted.zip"
# download(url, here(path_enacted))
# zip_files <- unzip(here(path_enacted), list = TRUE)
# enacted_baf <- zip_files$Name[str_detect(zip_files$Name, "\\.txt$")]
# unzip(here(path_enacted), files = enacted_baf, exdir = dirname(here(path_enacted)))
path_baf <- "data-raw/OR/Congress SB 881A (Block Assignment File).txt"
# file.rename(here(dirname(path_enacted), enacted_baf), here(path_baf))

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/OR_2020/shp_vtd.rds"
perim_path <- "data-out/OR_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong OR} shapefile")
    # read in redistricting data
    or_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c"))
    or_enacted <-  read_csv(here(path_baf), col_types = "ci", col_names = c("GEOID20", "cd_2020"))
    or_shp <- left_join(or_shp, or_enacted, by = "GEOID20") %>%
        relocate(cd_2020, .after = county)
    # add shapefile
    geom_d <- tigris::blocks("OR", year = 2020) %>%
        select(GEOID20 = GEOID20, area_land = ALAND20, area_water = AWATER20, geometry)
    # add municipalities
    baf <- PL94171::pl_get_baf("OR", cache_to = here(str_glue("data-raw/OR/or_baf.rds")))
    d_muni <- baf$INCPLACE_CDP %>%
        transmute(GEOID20 = BLOCKID,
            muni =  if_else(is.na(PLACEFP), NA_character_,
                paste0(censable::match_fips("OR"), PLACEFP)))

    # join everything
    or_shp <- left_join(or_shp, geom_d, by = "GEOID20") %>%
        left_join(d_muni, by = "GEOID20") %>%
        relocate(muni, .after = county) %>%
        sf::st_as_sf() %>%
        st_transform(EPSG$OR) %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID")) %>%
        mutate(GEOID = str_sub(GEOID, 1, 11)) %>% # trim to tracts
        group_by(GEOID) %>%
        summarize(state = state[1], county = county[1],
            cd_2020 = Mode(cd_2020), muni = muni[1],
            across(pop:ndv, function(x) sum(x, na.rm = TRUE)),
            across(area_land:area_water, sum),
            is_coverage = TRUE) %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(county_muni, .after = muni)

    d_cd_2010 <- tigris::congressional_districts("OR")
    or_shp <- or_shp %>%
        mutate(cd_2010 = as.integer(d_cd_2010$CD116FP)[
            geo_match(or_shp, d_cd_2010, method = "area")],
        .before = cd_2020)

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

    # Highway plot for geographical links constraint
    if (FALSE) {
        d_roads <- tigris::primary_secondary_roads("OR", 2020) %>%
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

    # Disconnect counties not connected by state or federal highways
    disconn_cty <- function(adj, cty1, cty2) {
        v1 <- which(or_shp$county == str_c(cty1, " County"))
        if (length(v1) == 0) stop(cty1, "not found")
        v2 <- which(or_shp$county == str_c(cty2, " County"))
        if (length(v2) == 0) stop(cty1, "not found")
        vs <- tidyr::crossing(v1, v2)
        remove_edge(adj, vs$v1, vs$v2)
    }
    or_shp$adj <- or_shp$adj %>%
        disconn_cty("Curry", "Josephine") %>%
        disconn_cty("Benton", "Lane") %>%
        disconn_cty("Polk", "Lincoln") %>%
        disconn_cty("Marion", "Jefferson") %>%
        disconn_cty("Marion", "Wasco") %>%
        disconn_cty("Wallowa", "Baker") %>%
        disconn_cty("Morrow", "Grant") %>%
        disconn_cty("Crook", "Grant") %>%
        disconn_cty("Deschutes", "Harney") %>%
        disconn_cty("Deschutes", "Linn")

    or_shp <- or_shp %>%
        fix_geo_assignment(muni)

    write_rds(or_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    or_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong OR} shapefile")
}
