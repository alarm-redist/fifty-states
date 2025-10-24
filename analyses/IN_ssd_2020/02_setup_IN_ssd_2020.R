###############################################################################
# Set up redistricting simulation for IN_ssd_2020
###############################################################################

suppressMessages({
    library(dplyr)
    library(readr)
    library(redist)
    library(cli)
    library(here)
    devtools::load_all()
})

cli_process_start("Creating {.cls redist_map} object for {.pkg IN_ssd_2020}")

# 1) Load the precinct/VTD shapefile prepared in 01_prep
in_shp <- read_rds(here("data-out/IN_2020/shp_vtd.rds"))

# Quick sanity checks: required columns
req_cols <- c("ssd_2020", "county", "muni", "adj")
missing  <- setdiff(req_cols, names(in_shp))
if (length(missing)) stop("Missing required columns in in_shp: ", paste(missing, collapse = ", "))

# 2) Create the redist_map object
#    pop_tol = 0.5% (tweak here if you need a different deviation)
map <- redist_map(
    in_shp,
    pop_tol       = 0.05,      # 5% population deviation
    existing_plan = ssd_2020,   # enacted IN Senate districts attached in 01_prep
    adj           = in_shp$adj  # precomputed adjacency from 01_prep
)

# 3) (Optional) Build pseudo-counties to reduce county/municipality splits
#    You can adjust `pop_muni` if you want a different target (default uses target pop)
map <- map %>%
    mutate(
        pseudo_county = pick_county_muni(
            map,
            counties  = county,
            munis     = muni,
            pop_muni  = get_target(map)
        )
    )

# 4) Tag analysis name (used by downstream scripts)
attr(map, "analysis_name") <- "IN_2020"

# 5) Ensure output dir exists and write out the map object
dir.create(here("data-out/IN_2020"), recursive = TRUE, showWarnings = FALSE)
write_rds(map, here("data-out/IN_2020/IN_ssd_2020_map.rds"), compress = "xz")

cli_process_done()

# 6) Quick validation logs
cli_alert_info("Precincts (rows): {nrow(map)}")
cli_alert_info("Target population per district: {format(get_target(map), big.mark = ',')}")
cli_alert_info("Number of districts (from existing plan): {dplyr::n_distinct(map$ssd_2020)}")
