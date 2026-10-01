###############################################################################
# Download and prepare data for `AZ_cd_1990` analysis
# © ALARM Project, September 2026
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
    devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg AZ_cd_1990}")

path_data <- download_redistricting_file("AZ", "data-raw/AZ", year = 1990)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/AZ_1990/shp_vtd.rds"
perim_path <- "data-out/AZ_1990/perim.rds"

if (!file.exists(here(shp_path))) {
    cli_process_start("Preparing {.strong AZ} shapefile")
    # read in redistricting data
    tract_path = "data-raw/AZ/04_tracts.gpkg"
    raw_data <- read_csv(here(path_data), col_types = cols(GEOID = "c"))
    raw_data$state = as.character(raw_data$state)
    shapefile <- st_read(tract_path, quiet = TRUE) |>
      rename(state_shp = state)
    az_shp <- raw_data |>
      left_join(shapefile, by = "GEOID")
    # manually set state to AZ
    az_shp = mutate(az_shp, state = "AZ") |>
      st_as_sf()
    az_shp = st_transform(az_shp, EPSG$AZ)

    az_shp <- az_shp |>
      mutate(county = coalesce(county.x, county.y)) |>
      select(-county.x, -county.y)

    az_shp <- az_shp |>
        rename(muni = place) |>
        mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
        relocate(muni, county_muni, cd_1980, .after = county)

    # Create perimeters in case shapes are simplified
    redistmetrics::prep_perims(shp = az_shp,
                               perim_path = here(perim_path)) |>
        invisible()

    # simplifies geometry for faster processing, plotting, and smaller shapefiles
    if (requireNamespace("rmapshaper", quietly = TRUE)) {
        az_shp <- rmapshaper::ms_simplify(az_shp, keep = 0.05,
                                                 keep_shapes = TRUE) |>
            suppressWarnings()
    }

    # create adjacency graph
    az_shp$adj <- redist.adjacency(az_shp)

    ###############################################################################
    # Logit-shift ndv/nrv to match 1992 LEIP county results
    ###############################################################################
    
    # 1. Load the LEIP county CSV as `leip_cty` ----
    leip_cty <- read_csv(
        here("data-raw/baseline_voteshare_leip_92.csv"),
        show_col_types = FALSE
    )
    
    # 2. Add county_fips column based on tract GEOID ----
    az_shp <- az_shp |>
        mutate(county_fips = stringr::str_sub(GEOID, 1, 5))
    
    # 3. For each county, logit-shift ndv/nrv to the 1992 target from LEIP ----
    az_shp <- az_shp |>
        group_by(county_fips) |>
        group_split() |>
        lapply(function(x) {
            meds <- leip_cty |>
                filter(county == x$county_fips[1])
            target <- meds$dshare_92[1]
    
            if (is.na(target)) return(x)
    
            logit_shift_baseline(x, ndv = ndv, nrv = nrv, target = target)
        }) |>
        bind_rows()

    write_rds(az_shp, here(shp_path), compress = "gz")
    cli_process_done()
} else {
    az_shp <- read_rds(here(shp_path))
    cli_alert_success("Loaded {.strong AZ} shapefile")
}
