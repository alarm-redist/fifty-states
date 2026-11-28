###############################################################################
# Simulate plans for `HI_cd_1990`
# © ALARM Project, September 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg HI_cd_1990}")

set.seed(1990)

# Simulation settings
target_per_chain <- 2500L
runs <- 2L
nsims <- 30000L   

# Population bounds for the Honolulu-only district
hpop <- map_honolulu[[attr(map_honolulu, "pop_col")]]
state_pop <- sum(map[[attr(map, "pop_col")]])
L <- attr(map, "pop_bounds")[1]
U <- attr(map, "pop_bounds")[3]
lo <- max(L, state_pop - U)
hi <- min(U, state_pop - L)

honolulu_population_constraint <- function(plan, distr) {
  if (all(plan == plan[1L])) return(0)
  p <- sum(hpop[plan == distr])
  q <- sum(hpop) - p
  ok <- (p >= lo && p <= hi) || (q >= lo && q <= hi)
  as.numeric(!ok)
}

constraints <- redist::add_constr_custom(
  redist::redist_constr(map_honolulu),
  strength = 1,
  fn = honolulu_population_constraint,
  thresh = 1
)

plans_raw <- redist_smc(
  map_honolulu,
  nsims = nsims, runs = runs,
  counties = dplyr::coalesce(as.character(muni), as.character(county)),
  compactness = 1,
  constraints = constraints,
  resample = TRUE,
  init_particles = NULL,
  sampling_space = "linking_edge",
  split_method = "constraint",
  ref_name = FALSE,
  ncores = 1L,
  verbose = TRUE
)
raw_resampled <- attr(plans_raw, "resampled", exact = TRUE)
stopifnot(isTRUE(raw_resampled))

cli_process_done()

# Build plans object, retaining the first draws from each run
cli_process_start("Building redist_plans object")

chain_all <- rep(seq_len(runs), each = nsims)
pick <- unlist(lapply(seq_len(runs), function(ch) {
  which(chain_all == ch)[seq_len(target_per_chain)]
}))
mat_h <- get_plans_matrix(plans_raw)[, pick, drop = FALSE]

# Expand the Honolulu split to a statewide plan
mat_final <- matrix(2L, nrow = nrow(map), ncol = ncol(mat_h))
for (j in seq_len(ncol(mat_h))) {
  labs <- sort(unique(mat_h[, j]))
  pops <- vapply(labs, function(l) sum(hpop[mat_h[, j] == l]), numeric(1))
  fits <- pops >= lo & pops <= hi
  stopifnot(length(labs) == 2L, sum(fits) == 1L)
  mat_final[hnl_rows[mat_h[, j] == labs[fits]], j] <- 1L
}

plans <- redist_plans(
  plans = mat_final, map = map, algorithm = "smc", wgt = get_plans_weights(plans_raw)[pick]
)
attr(plans, "resampled") <- raw_resampled

plans <- plans |>
  dplyr::mutate(chain = rep(chain_all[pick], each = 2L), .after = draw) |>
  add_reference(ref_plan = map$cd_1990, name = "cd_1990") |>
  match_numbers("cd_1990")

cli_process_done()

cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_plans object. Do not edit this path.
write_rds(plans, here("data-out/HI_1990/HI_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg HI_cd_1990}")
plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/HI_1990/HI_cd_1990_stats.csv")
cli_process_done()

# Validation
if (interactive()) {
  validate_analysis(plans, map)
  summary(plans)
}
