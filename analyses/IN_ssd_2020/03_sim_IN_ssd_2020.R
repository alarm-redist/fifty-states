###############################################################################
# Simulate plans for IN_ssd_2020 — baseline per Philip's guidance
# Baseline: use counties only; no extra compactness/splits constraints.
# Assumes 02_setup used pop_tol = ±5% and wrote IN_ssd_2020_map.rds
###############################################################################

suppressMessages({
    library(cli)
    library(here)
    library(dplyr)
    library(readr)
    library(redist)
    devtools::load_all()
})

stopifnot(packageVersion("redist") >= "5.0.0")
set.seed(2020)

cli_process_start("Loading map for {.pkg IN_ssd_2020}")
map <- read_rds(here("data-out/IN_2020/IN_ssd_2020_map.rds"))
cli_process_done()

nd <- attr(map, "ndists")
if (is.null(nd)) nd <- dplyr::n_distinct(map[[attr(map, "existing_col")]])
stopifnot(is.numeric(nd), nd > 1L)
n_steps <- nd - 1L

# --- Constraints: baseline (none beyond pop tolerance) -----------------------
constr <- redist_constr(map)

# --- Sampler config ----------------------------------------------------------
nsims      <- 6000L      # ↑ samples to improve resampling efficiency
runs       <- 5L
mh_per_smc <- 35L        # ↑ MH steps for better mixing (was 25)
pop_temper <- 0.02       # +0.01 per warning (±5% pop_tol)
seq_alpha  <- 0.98       # slow the weight decay slightly

sampling_space_val <- tryCatch(
    getFromNamespace("LINKING_EDGE_SPACE", "redist"),
    error = function(e) "linking_edge"
)

cli_process_start("Running SMC ({nsims} per chain × {runs} chains)")
plans <- redist_smc(
    map,
    nsims          = nsims,
    runs           = runs,
    constraints    = constr,
    counties       = county,                 # baseline per Philip: counties only
    sampling_space = sampling_space_val,
    n_steps        = n_steps,
    ms_params      = list(frequency = 1L, mh_accept_per_smc = mh_per_smc),
    split_params   = list(splitting_schedule = "any_valid_sizes"),
    pop_temper     = pop_temper,
    seq_alpha      = seq_alpha,
    verbose        = TRUE,
    ncores         = max(1, parallel::detectCores() - 1)
)
cli_process_done()

# ---- Diagnostics & Validation (idempotent; safe to re-run) ------------------
suppressMessages({
    library(here)
    library(dplyr)
    library(readr)
    library(ggplot2)
    library(posterior)
    library(cli)
})

# 0) Locate output files and ensure availability --------------------------------
state_abb <- "IN"
year <- 2020
slug <- "IN_ssd_2020"

out_dir  <- here("data-out", sprintf("%s_%d", state_abb, year))
diag_dir <- file.path(out_dir, "diagnostics")
dir.create(diag_dir, recursive = TRUE, showWarnings = FALSE)

plans_file <- file.path(out_dir, sprintf("%s_plans.rds", slug))
stats_file <- file.path(out_dir, sprintf("%s_stats.csv",  slug))
map_file   <- file.path(out_dir, sprintf("%s_map.rds",   slug))

if (!exists("plans") && file.exists(plans_file)) plans <- read_rds(plans_file)
if (!exists("map")   && file.exists(map_file)) map   <- read_rds(map_file)
stopifnot(exists("plans"), exists("map"))

# If the stats CSV was not written yet, create it now (no re-sampling)
if (!file.exists(stats_file)) {
    tmp <- add_summary_stats(plans, map)
    save_summary_stats(tmp, stats_file)
}

# 1) Basic prints ---------------------------------------------------------------
stats <- read_csv(stats_file, show_col_types = FALSE) %>% arrange(chain, draw)

plan_index <- stats %>% distinct(chain, draw)
cli_alert_info(sprintf("Draws: %d   Districts: %s",
    nrow(plan_index), attr(map, "ndists")))

stopifnot("plan_dev" %in% names(stats))
plan_dev_by_plan <- stats %>%
    group_by(chain, draw) %>%
    summarise(plan_dev = dplyr::first(plan_dev), .groups = "drop")
cli_alert_info(sprintf("Max |pop dev|: %.4f",
    max(abs(plan_dev_by_plan$plan_dev), na.rm = TRUE)))

# 2) Validation image — always saved under diagnostics --------------------------
# Sweep any stray validation images created earlier into diagnostics
raw_dir <- here("data-raw", state_abb)
old_val <- list.files(raw_dir, pattern = "^validation_.*\\.(png|pdf)$", full.names = TRUE)
if (length(old_val)) {
    file.copy(old_val, diag_dir, overwrite = TRUE)
    file.remove(old_val)
}
root_png <- file.path(out_dir, sprintf("%s_validation.png", state_abb))
if (file.exists(root_png)) {
    file.copy(root_png, file.path(diag_dir, basename(root_png)), overwrite = TRUE)
    file.remove(root_png)
}

# Render a fresh, canonical validation figure into diagnostics
if (exists("validate_analysis")) {
    out_png <- file.path(diag_dir, sprintf("%s_validation.png", state_abb))
    png(out_png, width = 1800, height = 2400, res = 150)
    print(validate_analysis(plans, map))
    dev.off()
}

# 3) Internal diagnostic plots --------------------------------------------------
# (a) SMC weight histogram (if weights are present)
w <- attr(plans, "weights")
if (!is.null(w) && length(w)) {
    png(file.path(diag_dir, "weights_hist.png"), width = 1200, height = 800, res = 150)
    hist(w, breaks = 60, xlab = "SMC weight", main = "SMC importance weights")
    dev.off()
}

# (b) Plan-level max |population deviation| histogram
png(file.path(diag_dir, "plan_dev_hist.png"), width = 1200, height = 800, res = 150)
hist(plan_dev_by_plan$plan_dev, breaks = 50,
    main = "Plan-level max |population deviation|", xlab = "Max |pop dev|")
dev.off()

# 4) R-hat / ESS across chains (plan-level metrics only) ------------------------
has <- function(nm) nm %in% names(stats)
plan_df <- stats %>%
    group_by(chain, draw) %>%
    summarise(
        plan_dev      = first(plan_dev),
        mean_polsby   = if (has("comp_polsby")) mean(comp_polsby, na.rm = TRUE) else NA_real_,
        mean_edge     = if (has("comp_edge")) mean(comp_edge,   na.rm = TRUE) else NA_real_,
        d_seats       = if (has("d_seats")) first(d_seats)                  else NA_real_,
        mm            = if (has("mm")) first(mm)                       else NA_real_,
        egap          = if (has("egap")) first(egap)                     else NA_real_,
        county_splits = if (has("county_splits")) first(county_splits)          else NA_real_,
        muni_splits   = if (has("muni_splits")) first(muni_splits)            else NA_real_,
        .groups = "drop"
    )


rvars <- c("plan_dev", "d_seats", "mm", "egap", "county_splits", "muni_splits", "mean_polsby", "mean_edge")
rvars <- rvars[vapply(rvars, function(v) v %in% names(plan_df) && any(is.finite(plan_df[[v]])), logical(1))]


rhat_for <- function(vec, chain) {
    ch  <- sort(unique(chain))
    lst <- lapply(ch, function(cc) vec[chain == cc])
    lst <- lapply(lst, function(v) v[is.finite(v)])
    iters <- min(sapply(lst, length))
    if (iters < 10) return(c(Rhat = NA_real_, ESS_bulk = NA_real_, ESS_tail = NA_real_))
    arr <- array(NA_real_, dim = c(iters, length(ch), 1))
    for (j in seq_along(ch)) arr[, j, 1] <- lst[[j]][seq_len(iters)]
    da <- posterior::as_draws_array(arr)
    c(Rhat = as.numeric(posterior::rhat(da)),
        ESS_bulk = as.numeric(posterior::ess_bulk(da)),
        ESS_tail = as.numeric(posterior::ess_tail(da)))
}

diag_tbl <- do.call(rbind, lapply(rvars, function(v) rhat_for(plan_df[[v]], plan_df$chain)))
diag_tbl <- data.frame(metric = rvars, diag_tbl, row.names = NULL)
write_csv(diag_tbl, file.path(diag_dir, "rhat_table.csv"))

if (nrow(diag_tbl)) {
    p <- ggplot(diag_tbl, aes(x = Rhat, y = factor(metric, levels = rev(metric)))) +
        geom_point(size = 3) +
        geom_vline(xintercept = 1.05, linetype = 2) +
        labs(title = "R-hat by metric", x = "R-hat", y = NULL)
    ggsave(file.path(diag_dir, "rhat.png"), plot = p, width = 7, height = 4, dpi = 150)
}

cli_alert_success(sprintf("Diagnostics saved under: %s", diag_dir))
