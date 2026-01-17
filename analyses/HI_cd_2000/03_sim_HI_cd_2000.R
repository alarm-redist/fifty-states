###############################################################################
# Simulate plans for `HI_cd_2000`
# © ALARM Project, January 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg HI_cd_2000}")

set.seed(2000)

# Target output
target_per_chain <- 2500L
runs <- 2L

# Start reasonably large
nsims <- 30000L   

plans_raw <- redist_smc(
  map,
  nsims = nsims, runs = runs,
  counties = dplyr::coalesce(as.character(muni), as.character(county))
)

cli_process_done()

# Filter: all non-Honolulu units must be in the same district
cli_process_start("HI_cd_2000: filter draws")

mat_all <- get_plans_matrix(plans_raw)
mat_sim <- if (ncol(mat_all) == nsims * runs + 1L) mat_all[, -1, drop = FALSE] else mat_all

w_all <- get_plans_weights(plans_raw)
w_sim <- if (length(w_all) == ncol(mat_sim) + 1L) w_all[-1] else w_all
if (length(w_sim) != ncol(mat_sim)) stop("weights/cols mismatch")

non_hnl <- map$county != "003"

outside_lab <- apply(mat_sim[non_hnl, , drop = FALSE], 2, unique)
keep <- lengths(outside_lab) == 1L

mat_keep <- mat_sim[, keep, drop = FALSE]
w_keep <- w_sim[keep]

cli_alert_info("Kept {ncol(mat_keep)} / {ncol(mat_sim)}")

chain_all  <- rep(seq_len(runs), each = nsims)
chain_keep <- chain_all[keep]

# take first `target_per_chain` kept per chain
pick <- unlist(lapply(seq_len(runs), function(ch) {
  idx <- which(chain_keep == ch)
  if (length(idx) < target_per_chain) cli_abort("need more draws (chain {ch})")
  idx[seq_len(target_per_chain)]
}))

mat_final <- mat_keep[, pick, drop = FALSE]
w_final   <- w_keep[pick]
chain_cols <- chain_keep[pick]

cli_process_done()

# Build plans object, add reference, relabel
cli_process_start("Building redist_plans object")

stopifnot(all(mat_final %in% c(1L, 2L)))
storage.mode(mat_final) <- "integer"
colnames(mat_final) <- NULL

plans <- redist_plans(
  plans     = mat_final,
  map       = map,
  algorithm = "smc",
  wgt       = w_final
)

# chain column: redist_plans sometimes has 1 row per draw or 2 rows per draw
n <- nrow(plans)
if (n == length(chain_cols)) {
  plans <- plans |> dplyr::mutate(chain = chain_cols, .after = draw)
} else if (n == 2L * length(chain_cols)) {
  plans <- plans |> dplyr::mutate(chain = rep(chain_cols, each = 2L), .after = draw)
} else {
  cli_abort("chain length mismatch")
}

plans <- plans |>
  add_reference(ref_plan = map$cd_2000, name = "cd_2000")

# if reference got added once, copy for chain 2
if ("is_reference" %in% names(plans)) {
  ref_rows <- dplyr::filter(plans, is_reference)
  if (nrow(ref_rows) == 1L && runs == 2L) {
    ref2 <- ref_rows
    ref2$chain <- setdiff(seq_len(runs), ref_rows$chain)[1]
    plans <- dplyr::bind_rows(plans, ref2)
  }
}

# relabel to match the enacted plan
plans <- match_numbers(plans, "cd_2000")

cli_process_done()

cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/HI_2000/HI_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg HI_cd_2000}")
plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/HI_2000/HI_cd_2000_stats.csv")
cli_process_done()

# Validation
if (interactive()) {
  validate_analysis(plans, map)
  summary(plans)
}
