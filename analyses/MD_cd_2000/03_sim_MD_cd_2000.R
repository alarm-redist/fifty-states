###############################################################################
# Simulate plans for `MD_cd_2000`
# © ALARM Project, October 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MD_cd_2000}")

set.seed(2000)
plans <- redist_smc(map, nsims = 45000, runs = 10, counties = county)

plans <- match_numbers(plans, "cd_2000")

cli_process_done() 

# Screen for contiguity
cli_process_start("Screening for contiguity") 

pmat <- redist::get_plans_matrix(plans) 
valid <- check_valid(pref_n = map, plans_matrix = pmat) 

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

# add the enacted plan as a named reference plan
plans <- redist::add_reference(plans, ref_plan = map$cd_2000, name = "cd_2000")

# Save the filtered redist_plans object. Do not edit this path. 
write_rds(plans, here("data-out/MD_2000/MD_cd_2000_plans.rds"), compress = "xz") 
cli_process_done() 

# Compute summary statistics ----- 
cli_process_start("Computing summary statistics for {.pkg MD_cd_2000}") 

plans <- add_summary_stats(plans, map) 

plans <- plans %>%
  dplyr::mutate(
    pop_overlap = dplyr::if_else(.data$draw == "cd_2000" & is.na(.data$pop_overlap),
                                 1, .data$pop_overlap)
  )

# Output the summary statistics. Do not edit this path. 
save_summary_stats(plans, "data-out/MD_2000/MD_cd_2000_stats.csv") 
cli_process_done()
