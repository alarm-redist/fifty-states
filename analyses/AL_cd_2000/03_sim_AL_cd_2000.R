###############################################################################
# Simulate plans for `AL_cd_2000`
# © ALARM Project, July 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg AL_cd_2000}")

map <- map %>%
  mutate(
    vap_safe = if_else(vap <= 0 | is.na(vap), 1, vap),
    pop_safe = if_else(pop <= 0 | is.na(pop), 1, pop)
  )


tgts <- c(0.40, rep(0.33, 6))  # 1 high target, 6 low targets

constr_al <- redist_constr(map) |>
  # (A) Count constraint: exactly 1 district clears 0.40
  # Keep this SOFT or SMC weights can overflow.
  add_constr_min_group_frac(
    strength      = 0.03,      # << do NOT use 1 here
    group_pops    = list(map$vap_black),
    total_pops    = list(map$vap_safe),
    min_fracs     = 0.40,
    thresh        = -0.05,     # << do NOT use -0.8 / -0.9
    only_nregions = 1L
  ) |>
  # (B) Shape: pull districts toward {0.40, 0.33,...}
  add_constr_grp_hinge(
    strength   = 25,
    group_pop  = vap_black,
    total_pop  = vap_safe,
    tgts_group = tgts
  ) |>
  add_constr_grp_inv_hinge(
    strength   = 25,
    group_pop  = vap_black,
    total_pop  = vap_safe,
    tgts_group = tgts
  )

set.seed(2000)
plans <- redist_smc(map, nsims = 15e3, runs = 5, counties = pseudo_county, constraints = constr_al,
                    pop_temper   = 0.05, verbose=TRUE)

plans <- plans %>%
    group_by(chain) %>%
    filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
    ungroup()
plans <- match_numbers(plans, "cd_2000")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/AL_2000/AL_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg AL_cd_2000}")

plans <- add_summary_stats(plans, map)

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/AL_2000/AL_cd_2000_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    validate_analysis(plans, map)
    summary(plans)

    # Black VAP Performance Plot
    redist.plot.distr_qtys(plans, vap_black/total_vap,
                           color_thresh = NULL,
                           color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
                           size = 0.5, alpha = 0.5) +
      scale_y_continuous("Percent Black by VAP") +
      labs(title = "Alabama Proposed Plan versus Simulations") +
      scale_color_manual(values = c(cd_2020_prop = "black")) +
      theme_bw()

    # Minority VAP Performance Plot
    redist.plot.distr_qtys(plans, (total_vap - vap_white)/total_vap,
                           color_thresh = NULL,
                           color = ifelse(subset_sampled(plans)$ndv > subset_sampled(plans)$nrv, "#3D77BB", "#B25D4C"),
                           size = 0.5, alpha = 0.5) +
      scale_y_continuous("Minority Percentage by VAP") +
      labs(title = "Alabama Proposed Plan versus Simulations") +
      scale_color_manual(values = c(cd_2020_prop = "black")) +
      theme_bw()

    # Dem seats by BVAP rank -- numeric
    plans %>%
      group_by(draw) %>%
      mutate(bvap = vap_black/total_vap, bvap_rank = rank(bvap)) %>%
      subset_sampled() %>%
      select(draw, district, bvap, bvap_rank, ndv, nrv) %>%
      mutate(dem = ndv > nrv) %>%
      group_by(bvap_rank) %>%
      summarize(dem = mean(dem))

    # Total Black districts that are performing
    plans %>%
      subset_sampled() %>%
      group_by(draw) %>%
      summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & ndshare > 0.5)) %>%
      count(n_black_perf)

    # Total Black districts that are performing from subset
    plans %>%
      subset_sampled() %>%
      group_by(draw) %>%
      summarize(n_black_perf = sum(vap_black/total_vap > 0.3 & ndshare > 0.5)) %>%
      count(n_black_perf)
}

bottleneck_split <- 6

plot(
  map,
  rowMeans(as.matrix(plans) == bottleneck_split),
)
