###############################################################################
# Process plans for `MN_ssd_2020` SSD
# © ALARM Project, December 2025
###############################################################################

# Filter SSD plans to match SHD survival
survive_all <- readRDS("data-out/MN_2020/survive_all.rds")

plans_oversample <- readRDS("data-raw/MN/MN_ssd_2020_plans_oversample.rds")

# Prepare survival vector
survive <- survive_all[seq(1, nrow(survive_all), by = max(map_shd$shd_2020)), , drop = FALSE]
survive$survive <- survive$survive_all
survive_all_ssd <- survive_all[rep(c(TRUE, FALSE), each = max(map_ssd$ssd_2020), length.out = nrow(survive_all)), ]

# Subset plans matrix
plans_ssd_matrix <- get_plans_matrix(subset_sampled(plans_oversample))
plans_ssd_matrix <- plans_ssd_matrix[, survive$survive]
colnames(plans_ssd_matrix) <- NULL

plans_ssd <- redist_plans(plans = plans_ssd_matrix,
                          map = map_ssd,
                          algorithm = "smc")

# Add draw and chain numbering
plans_ssd$draw <- as.factor(rep(1:sum(survive$survive), each = n_distinct(map_ssd$ssd_2020)))

full_chain <- plans_oversample$chain[!is.na(plans_oversample$chain)]

plans_ssd$chain <- full_chain[survive_all_ssd]

# Add enacted plan
plans_ssd <- add_reference(plans_ssd, ref_plan = map_ssd$ssd_2020, name = "ssd_2020")

# Trim as usual
plans <- plans_ssd |>
  group_by(chain) |>
  filter(as.integer(draw) < min(as.integer(draw)) + 2000) |> # thin samples
  ungroup()
plans <- match_numbers(plans, "ssd_2020")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/MN_2020/MN_ssd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg MN_ssd_2020}")

plans <- add_summary_stats(plans, map_ssd)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/MN_2020/MN_ssd_2020_stats.csv")

cli_process_done()

if (interactive()) {
  library(ggplot2)
  library(patchwork)

  validate_analysis(plans, map_ssd)
  summary(plans)

}
