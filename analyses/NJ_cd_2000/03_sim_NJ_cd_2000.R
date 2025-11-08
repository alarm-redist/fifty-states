###############################################################################
# Simulate plans for `NJ_cd_2000`
# © ALARM Project, July 2025
###############################################################################

# Run the simulation ----- 
cli_process_start("Running simulations for {.pkg NJ_cd_2000}") 

set.seed(2000) 
plans <- redist_smc(map, nsims = 30000, runs = 10, counties = pseudo_county) 

plans <- match_numbers(plans, "cd_2000")

cli_process_done() 

# Screen for contiguity
cli_process_start("Screening for contiguity") 

pmat <- redist::get_plans_matrix(plans) 
res   <- check_valid(pref_n = map, plans_matrix = pmat)
valid <- res$valid
adj_adjusted <- res$adj_adjusted
is_island    <- res$is_island

cli_alert_info("{sum(valid)} of {length(valid)} draws passed contiguity.") 

# Keep only contiguous draws
keep_draws <- which(valid) 
n_dropped <- length(valid) - length(keep_draws) 

if (n_dropped > 0) 
  cli_alert_warning("Dropping {n_dropped} non-contiguous draws.") 
if (length(keep_draws) == 0) {
  cli_abort("No draws passed the contiguity screen. Consider revisiting adjacency or constraints.") 
} 

# Tag each draw with validity
pairs <- plans %>% 
  dplyr::distinct(chain, draw) %>%
  dplyr::mutate(valid = valid)

# Filter to valid plans only
plans <- plans %>%
  dplyr::semi_join(dplyr::filter(pairs, valid), by = c("chain", "draw"))

# Thin simulation results to 5000.
burn <- 500
n_total <- 5000

plans <- plans %>% dplyr::arrange(chain, draw)

ids <- plans %>%
  dplyr::distinct(chain, draw) %>%
  dplyr::group_by(chain) %>%
  dplyr::mutate(r = dplyr::row_number(),
                n_in_chain = dplyr::n()) %>%
  dplyr::filter(r > pmin(burn, n_in_chain)) %>%   
  dplyr::ungroup()

n_runs   <- dplyr::n_distinct(ids$chain)
keep_each <- min(floor(n_total / n_runs),
                 ids %>% dplyr::count(chain, name = "m") %>% dplyr::pull(m) %>% min())

# take a contiguous tail: last keep_each draws per chain
keep_ids <- ids %>%
  dplyr::group_by(chain) %>%
  dplyr::slice_max(order_by = draw, n = keep_each, with_ties = FALSE) %>%
  dplyr::ungroup() %>%
  dplyr::select(chain, draw)

plans <- plans %>% dplyr::semi_join(keep_ids, by = c("chain","draw"))

cli_alert_success("Burn-in: dropped up to {burn}/chain; kept {keep_each} tail draws per chain (total {keep_each * n_runs}).")

pmat <- redist::get_plans_matrix(plans)

# add the enacted plan as a named reference plan
plans <- redist::add_reference(plans, ref_plan = map$cd_2000, name = "cd_2000")

# Save the filtered redist_plans object. Do not edit this path. 
write_rds(plans, here("data-out/NJ_2000/NJ_cd_2000_plans.rds"), compress = "xz") 
cli_process_done() 

# Compute summary statistics ----- 
cli_process_start("Computing summary statistics for {.pkg NJ_cd_2000}") 

plans <- add_summary_stats(plans, map) 

plans <- plans %>%
  dplyr::mutate(
    pop_overlap = dplyr::if_else(.data$draw == "cd_2000" & is.na(.data$pop_overlap),
                                 1, .data$pop_overlap)
  )

# Output the summary statistics. Do not edit this path. 
save_summary_stats(plans, "data-out/NJ_2000/NJ_cd_2000_stats.csv") 
cli_process_done()

# Validation plots
if (interactive()) {
  library(ggplot2)
  library(patchwork)
  
  # Black VAP Performance Plot  
  redist.plot.distr_qtys(plans, vap_black / total_vap,
                         color_thresh = NULL,
                         color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
                         size = 0.5, alpha = 0.5) +
    scale_y_continuous("Percent Black by VAP") +
    labs(title = "New Jersey Proposed Plan versus Simulations") +
    scale_color_manual(values = c(cd_2000 = "black")) +
    theme_bw()
  
  # Total Black districts that are performing
  plans %>%
    subset_sampled() %>%
    group_by(draw) %>%
    summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & ndshare > 0.5)) %>%
    count(n_black_perf)

  # Validation for distontiguous plans.
  plan_index <- plans |>
    dplyr::distinct(chain, draw) |>
    dplyr::arrange(chain, draw)
  
  if ("cd_2000" %in% plan_index$draw) {
    plan_index <- dplyr::filter(plan_index, draw != "cd_2000")
  }
  
  plan_index <- plan_index |>
    dplyr::mutate(col = dplyr::row_number())
  
  per_plan_summary <- data.frame(
    col = seq_len(ncol(pmat)),
    all_contiguous = vapply(seq_len(ncol(pmat)), function(j) {
      p <- pmat[, j]
      comp <- geomander::check_contiguity(adj_adjusted, p)$component
      by_district <- tapply(seq_along(p), p, function(idx) {
        idx_main <- idx[!is_island[idx]]
        if (length(idx_main) == 0) TRUE else max(comp[idx_main]) == 1
      })
      all(unlist(by_district))
    }, logical(1))
  ) |>
    dplyr::left_join(plan_index, by = "col")
  
  # quick readout
  tbl <- per_plan_summary |>
  dplyr::count(all_contiguous, name = "n") |>
  dplyr::mutate(prop = round(n / sum(n), 3))
