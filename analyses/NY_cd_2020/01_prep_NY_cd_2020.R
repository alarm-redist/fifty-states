###############################################################################
# Download and prepare data for `NY_cd_2020` analysis
# © ALARM Project, November 2021
###############################################################################

suppressMessages({
    library(dplyr)
    library(readr)
    library(sf)
    library(redist)
    library(geomander)
    library(cli)
    library(here)
    library(fs)
    devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg NY_cd_2020}")

path_data <- download_redistricting_file("NY", "data-raw/NY")

path_dem_irc <- here("data-raw/NY/NY congress Letters Plan Draft 9.14.csv")
path_rep_irc <- here("data-raw/NY/NY CD Block Equivalency.xlsx")

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/NY_2020/shp_vtd.rds"
perim_path <- "data-out/NY_2020/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong NY} shapefile")
    # read in redistricting data
    ny_shp <- read_csv(here(path_data), col_types = cols(GEOID20 = "c")) %>%
        join_vtd_shapefile() %>%
        st_transform(EPSG$NY) %>%
        rename_with(function(x) gsub("[0-9.]", "", x), starts_with("GEOID"))

    # add municipalities
    d_muni <- make_from_baf("NY", "INCPLACE_CDP", "VTD") %>%
        mutate(GEOID = paste0(censable::match_fips("NY"), vtd)) %>%
        select(-vtd)
    d_cd <- make_from_baf("NY", "CD", "VTD") %>%
        transmute(
            GEOID = paste0(censable::match_fips("NY"), vtd),
            cd_2010 = as.integer(cd)
        )
    ny_shp <- left_join(ny_shp, d_muni, by = "GEOID") %>%
        left_join(d_cd, by = "GEOID") %>%
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) %>%
        relocate(muni, county_muni, cd_2010, .after = county)

    if (!file.exists(path_dem_irc)) {
        temp_dem_irc <- fs::file_temp(ext = "zip")
        download(
            url = "https://nyirc.gov/storage/plans/20210915/congress_letters.zip",
            path = temp_dem_irc
        )
        unzip(temp_dem_irc, exdir = "data-raw/NY")
    }
    dem_irc_baf <- read_csv(here(path_dem_irc),
                            col_names = c("GEOID", "dem_irc"),
                            col_types = 'cc'
    )
    dem_irc_baf <- dem_irc_baf %>%
        rowwise() %>%
        mutate(dem_irc = tolower(dem_irc),
               dem_irc = which(dem_irc == letters)) %>%
        ungroup()

    if (!file.exists(path_rep_irc)) {
        temp_rep_irc <- fs::file_temp(ext = "zip")
        download(
            url = "https://nyirc.gov/storage/plans/20210915/congress_names.zip",
            path = temp_rep_irc
        )
        unzip(temp_rep_irc, exdir = "data-raw/NY")
    }
    rep_irc_baf <- readxl::read_xlsx(here(path_rep_irc))
    names(rep_irc_baf) <- c("GEOID", "rep_irc")
    vals <- unique(rep_irc_baf$rep_irc)
    rep_irc_baf <- rep_irc_baf %>%
        rowwise() %>%
        mutate(rep_irc = which(rep_irc == vals)) %>%
        ungroup()
    rm(vals)

    baf_vtd <- PL94171::pl_get_baf("NY", geographies = "VTD")$VTD %>%
        rename(GEOID = BLOCKID, county = COUNTYFP, vtd = DISTRICT)
    baf <- baf_vtd %>% left_join(rep_irc_baf, by = "GEOID") %>%
        left_join(dem_irc_baf, by = "GEOID")
    baf <- baf %>% select(-GEOID) %>%
        mutate(GEOID = paste0(censable::match_fips("NY"), county, vtd)) %>%
        select(-county, vtd)

    baf <- baf %>%
        group_by(GEOID) %>%
        summarize(rep_irc = Mode(rep_irc),
                  dem_irc = Mode(dem_irc)
                  )

    baf <- baf %>% select(GEOID, rep_irc, dem_irc)

    ny_shp <- ny_shp %>% left_join(baf, by = "GEOID")

    # Create perimeters in case shapes are simplified
    redist.prep.polsbypopper(
        shp = ny_shp,
        perim_path = here(perim_path)
    ) %>%
        invisible()

    # create adjacency graph
    ny_shp$adj <- redist.adjacency(ny_shp)

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ny_shp <- rmapshaper::ms_simplify(ny_shp,
                                          keep = 0.05,
                                          keep_shapes = TRUE
        ) %>%
            suppressWarnings()
    }

    # TODO any custom adjacency graph edits here
    ny_shp <- ny_shp %>%
        fix_geo_assignment(muni)

    # takes a long time
    if (FALSE) {
        nbr <- geomander::suggest_neighbors(ny_shp, adjacency = ny_shp$adj)
    } else {
        nbr <- structure(list(x = 7042L, y = 7040L),
                         class = c("tbl_df", "tbl", "data.frame"),
                         row.names = c(NA, -1L))
    }

    ny_shp$adj <- geomander::add_edge(ny_shp$adj, nbr$x, nbr$y)

    if (FALSE) {
        conn <- geomander::suggest_component_connection(ny_shp, adjacency = ny_shp$adj, group = ny_shp$rep_irc)
    } else {
        conn <- structure(list(x = c(8925L, 1078L, 889L, 10461L, 7040L),
                               y = c(13272L, 7714L, 892L, 10467L, 7042L)),
                          row.names = c(NA, -5L),
                          class = c("tbl_df", "tbl", "data.frame"))
    }

    ny_shp$adj <- geomander::add_edge(ny_shp$adj, conn$x, conn$y)


    write_rds(ny_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ny_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NY} shapefile")
}
