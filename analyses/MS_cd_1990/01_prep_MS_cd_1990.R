  ###############################################################################
  # Download and prepare data for `MS_cd_1990` analysis
  # © ALARM Project, December 2025
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
  cli_process_start("Downloading files for {.pkg MS_cd_1990}")

  path_data <- download_redistricting_file("MS", "data-raw/MS", year = 1990)

  cli_process_done()

  # Compile raw data into a final shapefile for analysis -----
  shp_path <- "data-out/MS_1990/shp_vtd.rds"
  perim_path <- "data-out/MS_1990/perim.rds"

  if (!file.exists(here(shp_path))) {
      tract_path = "data-raw/MS/28_tracts.gpkg"
      raw_data <- read_csv(here(path_data), col_types = cols(GEOID = "c"))
      raw_data$state = as.character(raw_data$state)
      shapefile <- st_read(tract_path, quiet = TRUE) |>
        rename(state_shp = state)
      ms_shp <- raw_data |>
        left_join(shapefile, by = "GEOID")
      # manually set state to MS
      ms_shp = mutate(ms_shp, state = "MS") |>
        st_as_sf()
      ms_shp = st_transform(ms_shp, EPSG$ID)

      ms_shp <- ms_shp |>
        mutate(county = coalesce(county.x, county.y)) |>
        select(-county.x, -county.y)

      ms_shp <- ms_shp |>
          rename(muni = place) |>
          mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
          relocate(muni, county_muni, cd_1980, .after = county)
      # Create perimeters in case shapes are simplified
      redistmetrics::prep_perims(shp = ms_shp,
                                 perim_path = here(perim_path)) |>
          invisible()

      # simplifies geometry for faster processing, plotting, and smaller shapefiles
      if (requireNamespace("rmapshaper", quietly = TRUE)) {
          ms_shp <- rmapshaper::ms_simplify(ms_shp, keep = 0.05,
                                                   keep_shapes = TRUE) |>
              suppressWarnings()
      }

      # create adjacency graph
      ms_shp$adj <- redist.adjacency(ms_shp)

      # TODO any custom adjacency graph edits here

      write_rds(ms_shp, here(shp_path), compress = "gz")
      cli_process_done()
  } else {
      ms_shp <- read_rds(here(shp_path))
      cli_alert_success("Loaded {.strong MS} shapefile")
  }


