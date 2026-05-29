###############################################################################
# Download and prepare data for `HI_cd_1990` analysis
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
  library(stringr)
  library(tibble)
  devtools::load_all() # load utilities 
})

# Download necessary files for analysis -----
cli_process_start("Downloading files for {.pkg HI_cd_1990}")

path_data <- download_redistricting_file("HI", "data-raw/HI", year = 1990)

cli_process_done()

# Compile raw data into a final shapefile for analysis -----
shp_path <- "data-out/HI_1990/shp_vtd.rds"
perim_path <- "data-out/HI_1990/perim.rds"

if (!file.exists(here(shp_path))) {
  cli_process_start("Preparing {.strong HI} shapefile")
  
  # read in redistricting data
  hi_shp <- read_csv(here(path_data), col_types = cols(GEOID = "c")) |>
    mutate(state = as.character(state)) |>
    join_vtd_shapefile(year = 1990) |>
    st_transform(EPSG$HI)
  
  hi_shp <- hi_shp |>
    rename(muni = place) |>
    mutate(county_muni = if_else(is.na(muni), county, str_c(county, muni))) |>
    relocate(muni, county_muni, cd_1980, .after = county)
  
  # Create perimeters in case shapes are simplified
  redistmetrics::prep_perims(
    shp = hi_shp,
    perim_path = here(perim_path)
  ) |>
    invisible()
  
  # simplifies geometry for faster processing, plotting, and smaller shapefiles
  if (requireNamespace("rmapshaper", quietly = TRUE)) {
    hi_shp <- rmapshaper::ms_simplify(
      hi_shp, keep = 0.05,
      keep_shapes = TRUE
    ) |>
      suppressWarnings()
  }
  
  # create adjacency graph
  hi_shp$adj <- redist.adjacency(hi_shp)
  
  # Connect precicnts
  island_codes <- tribble(
    ~v1,            ~v2,
    "15001000201",  "15001000202",
    "15001000202",  "15001000201",
    "15001000203",  "15001000201",
    "15001000204",  "15001000201",
    "15001000205",  "15001000203",
    "15001000206",  "15001000201",
    "15001000209",  "15001000201",
    "15001000211",  "15001000212",
    "15001000212",  "15001000209",
    "15001000213",  "15001000211",
    "15001000214",  "15001000212",
    "15001000216",  "15001021002",
    "15001000217",  "15001000218",
    "15001000218",  "15001000216",
    "15001000219",  "15001000216",
    "15001000220",  "15001000211",
    "15001000221",  "15001000201",
    "15001020699",  "15001000205",
    "15001020701",  "15001000204",
    "15001020702",  "15001000206",
    "15001020801",  "15001000201",
    "15001020802",  "15001000202",
    "15001021001",  "15001000205",
    "15001021002",  "15001000201",
    "15001021501",  "15001000214",
    "15001021502",  "15001000211",
    "15001021597",  "15001000213",
    "15001021598",  "15001000213",
    "15003003407",  "15003000033",
    "15003011302",  "15003000102",
    "15003011498",  "15003009901",
    "15005000319",  "15009000316",
    "15007000401",  "15001000201",
    "15007000403",  "15001000201",
    "15007000404",  "15001000202",
    "15007000405",  "15007000404",
    "15007000406",  "15007000403",
    "15007000407",  "15007000403",
    "15007000408",  "15005000319",
    "15007000409",  "15005000319",
    "15007000410",  "15003011498",
    "15007040201",  "15005000319",
    "15007040202",  "15007000401",
    "15007040599",  "15007000404",
    "15007041198",  "15007000410",
    "15009000301",  "15001000218",
    "15009000302",  "15007041198",
    "15009000305",  "15009000301",
    "15009000306",  "15009000302",
    "15009000307",  "15009000305",
    "15009000308",  "15009000305",
    "15009000309",  "15009000305",
    "15009000310",  "15009000307",
    "15009000312",  "15009000305",
    "15009000313",  "15009000305",
    "15009000314",  "15009000306",
    "15009000315",  "15009000307",
    "15009000316",  "15009000315",
    "15009000317",  "15003011498",
    "15009000318",  "15003011498",
    "15009030301",  "15007041198",
    "15009030302",  "15007041198",
    "15009030401",  "15009000301",
    "15009030402",  "15009000301",
    "15009030799",  "15009000306",
    "15009031101",  "15009000307",
    "15009031102",  "15009000310",
    "15009031103",  "15009000310",
    "15009000318",  "15003000105"
  )
  
  island_codes <- island_codes |>
    mutate(
      v1 = match(v1, hi_shp$GEOID),
      v2 = match(v2, hi_shp$GEOID)
    ) |>
    filter(!is.na(v1), !is.na(v2), v1 != v2)
  
  # Enforce symmetry automatically
  island_codes_sym <- island_codes |>
    bind_rows(island_codes |> transmute(v1 = v2, v2 = v1)) |>
    distinct(v1, v2)
  
  hi_shp$adj <- hi_shp$adj |>
    add_edge(island_codes_sym$v1, island_codes_sym$v2, zero = TRUE)
  
  write_rds(hi_shp, here(shp_path), compress = "gz")
  cli_process_done()
  
} else {
  hi_shp <- read_rds(here(shp_path))
  cli_alert_success("Loaded {.strong HI} shapefile")
}
