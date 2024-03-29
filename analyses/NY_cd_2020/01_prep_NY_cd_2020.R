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
path_enacted_old <- here("data-raw/NY/ny_baf.dbf")
path_enacted <- here("data-raw/NY/ny_baf.csv")

if (!file.exists(path_dem_irc)) {
    temp_dem_irc <- fs::file_temp(ext = "zip")
    download(
        url = "https://nyirc.gov/storage/plans/20210915/congress_letters.zip",
        path = temp_dem_irc
    )
    unzip(temp_dem_irc, exdir = "data-raw/NY")
}

if (!file.exists(path_rep_irc)) {
    temp_rep_irc <- fs::file_temp(ext = "zip")
    download(
        url = "https://nyirc.gov/storage/plans/20210915/congress_names.zip",
        path = temp_rep_irc
    )
    unzip(temp_rep_irc, exdir = "data-raw/NY")
}

if (!file.exists(path_enacted_old)) {
    download(url = "https://latfor.state.ny.us/maps/2022congress/Congress2022_BlockEquivalency.dbf",
        path = path_enacted_old)
}

if (!file.exists(path_enacted)) {
    download(url = "https://latfor.state.ny.us/maps/2022congress/congress_block.csv",
             path = path_enacted)
}

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


    dem_irc_baf <- read_csv(here(path_dem_irc),
        col_names = c("GEOID", "dem_irc"),
        col_types = "cc"
    )
    dem_irc_baf <- dem_irc_baf %>%
        rowwise() %>%
        mutate(dem_irc = tolower(dem_irc),
            dem_irc = which(dem_irc == letters)) %>%
        ungroup()


    rep_irc_baf <- readxl::read_xlsx(here(path_rep_irc))
    names(rep_irc_baf) <- c("GEOID", "rep_irc")
    vals <- unique(rep_irc_baf$rep_irc)
    rep_irc_baf <- rep_irc_baf %>%
        rowwise() %>%
        mutate(rep_irc = which(rep_irc == vals)) %>%
        ungroup()
    rm(vals)

    baf_enacted_old <- foreign::read.dbf(path_enacted_old) %>%
        rename(
            GEOID = BLOCK,
            cd_2020_leg = DISTRICTID
        )
    baf_enacted <- read_csv(path_enacted, col_types = "ci") %>%
        rename(
            GEOID = GEOID20,
            cd_2020 = District
        )

    baf_vtd <- PL94171::pl_get_baf("NY", geographies = "VTD")$VTD %>%
        rename(GEOID = BLOCKID, county = COUNTYFP, vtd = DISTRICT)
    baf <- baf_vtd %>%
        left_join(rep_irc_baf, by = "GEOID") %>%
        left_join(dem_irc_baf, by = "GEOID") %>%
        left_join(baf_enacted_old, by = "GEOID") %>%
        left_join(baf_enacted, by = "GEOID")
    baf <- baf %>% select(-GEOID) %>%
        mutate(GEOID = paste0(censable::match_fips("NY"), county, vtd)) %>%
        select(-county, vtd)

    baf <- baf %>%
        group_by(GEOID) %>%
        summarize(
            rep_irc = Mode(rep_irc),
            dem_irc = Mode(dem_irc),
            cd_2020_leg = Mode(cd_2020_leg),
            cd_2020 = Mode(cd_2020)
        )

    baf <- baf %>% select(GEOID, rep_irc, dem_irc, cd_2020_leg, cd_2020)

    ny_shp <- ny_shp %>% left_join(baf, by = "GEOID")

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(
        shp = ny_shp,
        perim_path = here(perim_path)
    ) %>%
        invisible()


    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        ny_shp <- rmapshaper::ms_simplify(ny_shp,
            keep = 0.05,
            keep_shapes = TRUE
        ) %>%
            suppressWarnings()
    }

    # create adjacency graph
    ny_shp$adj <- redist.adjacency(ny_shp)

    nbr <- geomander::suggest_neighbors(ny_shp, adj = ny_shp$adj)
    ny_shp$adj <- geomander::add_edge(ny_shp$adj, nbr$x, nbr$y)

    ny_shp <- ny_shp %>%
        fix_geo_assignment(muni)


    write_rds(ny_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    ny_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong NY} shapefile")
}
