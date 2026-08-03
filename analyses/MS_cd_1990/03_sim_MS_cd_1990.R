###############################################################################
# Simulate plans for `MS_cd_1990`
# © ALARM Project, July 2026
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg MS_cd_1990}")

# a district is Black-performing if it clears both thresholds
BVAP_THRESH <- 0.30
DEM_THRESH <- 0.50

# attempt to create single bvap mmd
constr_sc <- redist_constr(map) %>%
    add_constr_grp_hinge(15, vap_black, vap, 0.55) %>%
    add_constr_grp_hinge(-8, vap_black, vap, 0.40) %>%
    add_constr_grp_hinge(-10, vap_black, vap, 0.20)

set.seed(1990)
# oversample by 100 draws per run so that every chain still has at least
# 1,000 compliant draws once noncompliant plans are rejected below
plans <- redist_smc(map,
    nsims = 2.1e3,
    runs = 5,
    counties = county,
    constraints = constr_sc
)
plans <- match_numbers(plans, "cd_1990")

# Reject plans without a Black-performing district -----
# computed in a separate tibble so that `n_black_perf` never enters the
# saved `redist_plans` object or the summary statistics
n_perf <- plans %>%
    mutate(
        bvap = group_frac(map, vap_black, vap),
        ndshare = group_frac(map, ndv, nrv + ndv)
    ) %>%
    group_by(chain, draw) %>%
    summarize(
        n_black_perf = sum(bvap > BVAP_THRESH & ndshare > DEM_THRESH),
        .groups = "drop"
    )

plans_5k <- plans %>%
    # drop sampled plans with no Black-performing district; the enacted plan
    # is never a join candidate because its `chain` is NA
    anti_join(
        filter(n_perf, !is.na(chain), n_black_perf == 0),
        by = c("chain", "draw")
    ) %>%
    # thin the accepted plans to exactly 1,000 per chain, keeping the enacted plan
    group_by(chain) %>%
    filter(is.na(chain) | dense_rank(as.integer(draw)) <= 1000) %>%
    ungroup()

cli_process_done()

# Validate the filtered sample before saving -----
kept <- plans_5k %>%
    subset_sampled() %>%
    as_tibble() %>%
    distinct(chain, draw)
kept_perf <- semi_join(n_perf, kept, by = c("chain", "draw"))
kept_by_chain <- count(kept, chain)

stopifnot(
    "all five chains are present" = nrow(kept_by_chain) == 5L,
    "each chain has exactly 1,000 sampled plans" = all(kept_by_chain$n == 1000L),
    "exactly 5,000 sampled plans are retained" = nrow(kept) == 5000L,
    "every sampled plan has a Black-performing district" =
        nrow(kept_perf) == 5000L && all(kept_perf$n_black_perf > 0),
    "the enacted plan is retained" = "cd_1990" %in% as.character(plans_5k$draw)
)

cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans_5k, here("data-out/MS_1990/MS_cd_1990_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg MS_cd_1990}")

plans_5k <- add_summary_stats(plans_5k, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans_5k, "data-out/MS_1990/MS_cd_1990_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans_5k, map)
    summary(plans_5k)

    # Black VAP Performance Plot
    redist.plot.distr_qtys(plans_5k, vap_black/total_vap,
        color_thresh = NULL,
        color = ifelse(
            subset_sampled(plans_5k)$ndv > subset_sampled(plans_5k)$nrv,
            "#3D77BB", "#B25D4C"
        ),
        size = 0.5, alpha = 0.5) +
        scale_y_continuous("Percent Black by VAP") +
        labs(title = "Approximate Performance") +
        scale_color_manual(values = c(cd_1990 = "black"))

    # Total Black districts that are performing
    plans_5k %>%
        subset_sampled() %>%
        group_by(draw) %>%
        summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & ndshare > 0.5)) %>%
        count(n_black_perf)
}
