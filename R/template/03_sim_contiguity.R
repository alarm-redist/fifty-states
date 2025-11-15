###############################################################################
# Simulate plans for ```SLUG```
# ``COPYRIGHT``
###############################################################################

# Run the simulation ----- 
cli_process_start("Running simulations for {.pkg ``SLUG``}") 

# TODO any pre-computation (VRA targets, etc.)

# TODO customize as needed. Recommendations:
#  - For many districts / tighter population tolerances, try setting
#  `pop_temper=0.01` and nudging upward from there. Monitor the output for
#  efficiency!
#  - Monitor the output (i.e. leave `verbose=TRUE`) to ensure things aren't breaking
#  - Don't change the number of simulations unless you have a good reason
#  - If the sampler freezes, try turning off the county split constraint to see
#  if that's the problem.
#  - Ask for help!
set.seed(``YEAR``) 
plans <- redist_smc(map, nsims = 8e3, runs = 10, counties = county)
# IF CORES OR OTHER UNITS HAVE BEEN MERGED:
# make sure to call `pullback()` on this plans object!

plans <- match_numbers(plans, "cd_``YEAR``")

cli_process_done() 

# Screen for contiguity
cli_process_start("Screening for contiguity") 

pmat <- redist::get_plans_matrix(plans) 
res   <- check_valid(pref_n = map, plans_matrix = pmat)
valid <- res$valid
adj_adjusted <- res$adj_adjusted
is_island    <- res$is_island

cli_alert_info("{sum(valid)} of {length(valid)} draws passed contiguity.") 

# Identify contiguous draws and how many will be dropped
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

# Keep only contiguous draws
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

# take a tail: last keep_each draws per chain
keep_ids <- ids %>%
  dplyr::group_by(chain) %>%
  dplyr::slice_max(order_by = draw, n = keep_each, with_ties = FALSE) %>%
  dplyr::ungroup() %>%
  dplyr::select(chain, draw)

plans <- plans %>% dplyr::semi_join(keep_ids, by = c("chain","draw"))

cli_alert_success("Burn-in: dropped up to {burn}/chain; kept {keep_each} tail draws per chain (total {keep_each * n_runs}).")

pmat <- redist::get_plans_matrix(plans)

# add the enacted plan as a named reference plan
plans <- redist::add_reference(plans, ref_plan = map$cd_``YEAR``, name = "cd_``YEAR``")

# Save the filtered redist_plans object. Do not edit this path. 
write_rds(plans, here("data-out/``STATE``_``YEAR``/``SLUG``_plans.rds"), compress = "xz") 
cli_process_done() 

# Compute summary statistics ----- 
cli_process_start("Computing summary statistics for {.pkg ``SLUG``}") 

plans <- add_summary_stats(plans, map) 

plans <- plans %>%
  dplyr::mutate(
    pop_overlap = dplyr::if_else(.data$draw == "cd_``YEAR``" & is.na(.data$pop_overlap),
                                 1, .data$pop_overlap)
  )

# Output the summary statistics. Do not edit this path. 
save_summary_stats(plans, "data-out/``STATE``_``YEAR``/``SLUG``_stats.csv") 
cli_process_done()

# Validation plots
if (interactive()) {
  
  # check contiguity of each plan and summarize
  plan_index <- plans |>
    dplyr::distinct(chain, draw) |>
    dplyr::arrange(chain, draw)
  
  if ("cd_``YEAR``" %in% plan_index$draw) {
    plan_index <- dplyr::filter(plan_index, draw != "cd_``YEAR``")
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
}
