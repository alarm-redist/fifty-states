###############################################################################
# Simulate plans for `CA_cd_2000`
# © ALARM Project, August 2025
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg CA_cd_2000}")

nsims_regional <- 200L
nsims_state    <- 200L

sampling_space_val <- tryCatch(
  getFromNamespace("LINKING_EDGE_SPACE", "redist"),  
  error = function(e) "linking_edge"                 
)

# Simulate southern CA ----
seam_south <- c(
  '06037113202',
  '06037113211',
  '06037113231',
  '06037134401',
  '06037135203',
  '06037137302',
  '06037800201',
  '06037800302',
  '06037800323',
  '06037800325',
  '06037800326',
  '06037800404',
  '06037900102',
  '06037900200',
  '06037900900',
  '06037901203',
  '06037920104',
  '06037920106',
  '06037920303',
  '06037920326',
  '06071008901',
  '06071010300',
  '06071011600'
)

map_south$boundary <- map_south$GEOID %in% seam_south

if (exists("cd_2000",  inherits = FALSE)) rm(cd_2000)
if (exists("exist_col", inherits = FALSE)) rm(exist_col)
attr(map_south, "existing_col") <- NULL

cons_south <- redist_constr(map_south) %>%
  add_constr_grp_hinge(
    strength = 6,
    group_pop = vap_hisp,
    total_pop = vap,
  ) %>%
  add_constr_grp_hinge(
    strength = -3,
    group_pop = vap_hisp,
    total_pop = vap,
    tgts_group = .3
  ) %>%
  add_constr_grp_hinge(
    strength = -3,
    group_pop = vap_hisp,
    total_pop = vap,
    tgts_group = .2
  ) %>%
  add_constr_custom(
    strength = 5,
    fn = function(plan, distr) {
      as.numeric(!any(plan[map_south$boundary] == 0))
    }
  )

n_steps_south <- floor(sum(map_south$pop) / attr(map_south, "pop_bounds")[2])
n_steps_south <- attr(map_south, "ndists") - 1L

set.seed(2000)

plans_south <- redist_smc(
  map_south,
  nsims = nsims_regional, runs = 5,
  counties = pseudo_county,
  constraints = cons_south,
  n_steps = n_steps_south, pop_temper = 0.03, seq_alpha = 0.97,
  sampling_space = sampling_space_val,
  ms_params = list(ms_frequency = 1L, ms_moves_multiplier = 30),
  split_params = list(splitting_schedule = "any_valid_sizes"),
  ncores = parallel::detectCores()
)

if (!"keep" %in% names(plans_south)) plans_south <- plans_south %>% mutate(keep = TRUE)

write_rds(plans_south, here("data-raw/CA/plans_south.rds"), compress = "xz")

# Simulate large bay area ----
seam_bay <- c(
  '06013359101',
  '06013365001',
  '06013365002',
  '06013378000',
  '06039000102',
  '06039000103',
  '06039000105',
  '06039000400',
  '06039001000',
  '06047000100',
  '06047001901',
  '06047001902',
  '06047002100',
  '06047002400',
  '06053011400',
  '06067007100',
  '06067007206',
  '06067007417',
  '06067007418',
  '06067007419',
  '06067007421',
  '06067008113',
  '06067008124',
  '06067008127',
  '06067008128',
  '06067008143',
  '06067008203',
  '06067008210',
  '06067008211',
  '06067008501',
  '06067008502',
  '06067008503',
  '06067008600',
  '06067009404',
  '06067009406',
  '06069000800',
  '06075017902',
  '06075047901',
  '06075060100',
  '06077004702',
  '06095250102',
  '06095250800',
  '06095251803',
  '06095251804',
  '06095251902',
  '06095251903',
  '06095252201',
  '06095252202',
  '06095252307',
  '06095252903',
  '06099000101',
  '06099000102',
  '06099002801',
  '06099002901',
  '06113010102',
  '06113011300',
  '06113011400',
  '06113011500'
)

map_bay$boundary <- map_bay$GEOID %in% seam_bay

if (exists("cd_2000",  inherits = FALSE)) rm(cd_2000)
if (exists("exist_col", inherits = FALSE)) rm(exist_col)
attr(map_bay, "existing_col") <- NULL

cons_bay <- redist_constr(map_bay) %>%
  add_constr_grp_hinge(
    strength = 2.5,
    group_pop = vap_hisp,
    total_pop = vap,
  ) %>%
  add_constr_grp_hinge(
    strength = -2.5,
    group_pop = vap_hisp,
    total_pop = vap,
    tgts_group = .3
  ) %>%
  add_constr_grp_hinge(
    strength = -2.5,
    group_pop = vap_hisp,
    total_pop = vap,
    tgts_group = .2
  ) %>%
  add_constr_grp_hinge(
    strength = 3,
    group_pop = vap_asian,
    total_pop = vap,
  ) %>%
  add_constr_grp_hinge(
    strength = -3,
    group_pop = vap_asian,
    total_pop = vap,
    tgts_group = .3
  ) %>%
  add_constr_grp_hinge(
    strength = -3,
    group_pop = vap_asian,
    total_pop = vap,
    tgts_group = .2
  ) %>%
  add_constr_custom(
    strength = 5,
    fn = function(plan, distr) {
      as.numeric(!any(plan[map_bay$boundary] == 0))
    }
  )

n_steps_bay <- floor(sum(map_bay$pop) / attr(map_bay, "pop_bounds")[2])
n_steps_bay   <- attr(map_bay,   "ndists") - 1L 

set.seed(2000)

plans_bay <- redist_smc(
  map_bay,
  nsims = nsims_regional, runs = 5,
  counties = pseudo_county,
  constraints = cons_bay,
  n_steps = n_steps_bay, pop_temper = 0.03, seq_alpha = 0.97, 
  sampling_space = sampling_space_val,
  ms_params = list(ms_frequency = 1L, ms_moves_multiplier = 15),
  split_params = list(splitting_schedule = "any_valid_sizes"),
  ncores = parallel::detectCores()
)
if (!"keep" %in% names(plans_bay)) plans_bay <- plans_bay %>% mutate(keep = TRUE)

write_rds(plans_bay,   here("data-raw/CA/plans_bay.rds"),   compress = "xz")

# Pull it all together ----
# Make sure statewide map has enacted attribute
attr(map, "existing_col") <- "cd_2000"
stopifnot(is.character(attr(map, "existing_col")),
          length(attr(map, "existing_col")) == 1,
          identical(attr(map, "existing_col"), "cd_2000"))

draws_south <- ncol(redist::get_plans_matrix(redist::subset_sampled(plans_south)))
draws_bay   <- ncol(redist::get_plans_matrix(redist::subset_sampled(plans_bay)))

# set statewide nsims to at least the max regional draws
nsims_state <- max(draws_south, draws_bay)

init <- prep_particles(
  map = map,
  map_plan_list = list(
    south = list(
      map = map_south,
      plans = plans_south
    ),
    bay = list(
      map = map_bay,
      plans = plans_bay
    )
  ),
  uid = GEOID,
  dist_keep = keep,
  nsims = nsims_state
)

set.seed(2000)

cons_final <- redist_constr(map) %>%
  add_constr_grp_hinge(strength = 1.5, group_pop = vap_hisp,  total_pop = vap) %>%
  add_constr_grp_hinge(strength = 1.5, group_pop = vap_asian, total_pop = vap)

plans <- redist_smc(
  map,
  nsims = nsims_state, runs = 5,
  counties = county,
  constraints = cons_final,
  #init_particles = init,
  pop_temper = 0.03, seq_alpha  = 0.97,
  sampling_space = sampling_space_val,
  ms_params = list(ms_frequency = 1L, ms_moves_multiplier = 53),
  split_params = list(splitting_schedule = "any_valid_sizes"),
  ncores = parallel::detectCores()
)

attr(plans, "existing_col") <- "cd_2000"
attr(plans, "prec_pop") <- map$pop

plans <- plans %>%
  group_by(chain) %>%
  filter(as.integer(draw) < min(as.integer(draw)) + 1000) %>% # thin samples
  ungroup()
plans <- match_numbers(plans, "cd_2000")

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/CA_2000/CA_cd_2000_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg  CA_cd_2000}")

plans <- add_summary_stats(plans, map)
# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/CA_2000/CA_cd_2000_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
if (interactive()) {
  library(ggplot2)
  library(patchwork)
  
  plans   <- plans %>% mutate(total_vap = total_vap)
  enac_sum <- plans %>% subset_ref() %>% mutate(total_vap = total_vap)
  
  plans <- plans %>%
    group_by(draw, district) %>%
    mutate(e_dvs = if_else(sum(ndv + nrv, na.rm = TRUE) > 0,
                           sum(ndv, na.rm = TRUE) / sum(ndv + nrv, na.rm = TRUE),
                           NA_real_)) %>%
    ungroup()
  
  p1 <- redist.plot.hist(plans %>% group_by(draw) %>%
                           mutate(hisp_dem = sum((vap_hisp/total_vap > 0.5) & e_dvs > 0.5)), qty = hisp_dem) +
    labs(x = "Number of Hispanic and Dem. Majority") +
    redist.plot.hist(plans %>% group_by(draw) %>%
                       mutate(hisp_dem = sum((vap_hisp/total_vap > 0.4) & e_dvs > 0.5)), qty = hisp_dem) +
    labs(x = "Number of Hispanic > 40% and Dem. Majority") +
    redist.plot.hist(plans %>% group_by(draw) %>%
                       mutate(hisp_dem = sum((vap_hisp/total_vap > 0.3) & e_dvs > 0.5)), qty = hisp_dem) +
    labs(x = "Number of Hispanic > 30% and Dem. Majority") +
    redist.plot.hist(plans %>% group_by(draw) %>%
                       mutate(ha_dem = sum(((vap_hisp + vap_asian)/total_vap > 0.5) & e_dvs > 0.5)), qty = ha_dem) +
    labs(x = "Number of Hispanic + Asian and Dem. Majority") +
    redist.plot.hist(plans %>% group_by(draw) %>%
                       mutate(hisp_dem = sum(((vap_hisp + vap_asian)/total_vap > 0.4) & e_dvs > 0.5)), qty = hisp_dem) +
    labs(x = "Number of Hispanic + Asian > 40% and Dem. Majority") +
    redist.plot.hist(plans %>% group_by(draw) %>%
                       mutate(hisp_dem = sum(((vap_hisp + vap_asian)/total_vap > 0.3) & e_dvs > 0.5)), qty = hisp_dem) +
    labs(x = "Number of Hispanic + Asian > 30% and Dem. Majority") +
    redist.plot.hist(plans %>% group_by(draw) %>%
                       mutate(asian_dem = sum((vap_asian/total_vap > 0.5) & e_dvs > 0.5)), qty = asian_dem) +
    labs(x = "Number of Asian and Dem. Majority") +
    redist.plot.hist(plans %>% group_by(draw) %>%
                       mutate(hisp_dem = sum((vap_asian/total_vap > 0.4) & e_dvs > 0.5)), qty = hisp_dem) +
    labs(x = "Number of Asian > 40% and Dem. Majority") +
    redist.plot.hist(plans %>% group_by(draw) %>%
                       mutate(coalition_dem = sum(((vap_asian + vap_hisp + vap_black)/total_vap > 0.5) & e_dvs > 0.5)), qty = coalition_dem) +
    labs(x = "Number of Hispanic + Asian + Black and Dem. Majority") &
    theme_bw()
  
  ggsave("data-raw/CA/hist.pdf", p1, width = 11, height = 8)
  
  
  enac_sum <- plans %>%
    subset_ref() %>%
    mutate(minority = (total_vap - vap_white)/(total_vap),
           dist_lab = str_pad(district, width = 2, pad = "0"),
           minority_rank = rank(minority), # ascending order
           hisp_rank = rank(vap_hisp),
           asian_rank = rank(vap_asian),
           ha_rank = rank(vap_hisp + vap_asian),
           coalition_rank = rank(vap_hisp + vap_asian + vap_black),
           compact_rank = rank(comp_polsby)
    )
  
  p2 <- redist.plot.distr_qtys(plans, vap_hisp/total_vap,
                               color_thresh = NULL,
                               color = ifelse(subset_sampled(plans)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
                               size = 0.5, alpha = 0.5) +
    scale_y_continuous("Percent Hispanic by VAP") +
    labs(title = "CA Enacted versus Simulations") +
    scale_color_manual(values = c(cd_2000 = "black")) +
    geom_hline(yintercept = 0.5, linetype = "dotted") +
    geom_text(data = enac_sum, aes(x = hisp_rank, label = round(e_dvs, 2)),
              vjust = 3, y = Inf, size = 2.5, fontface = "bold", lineheight = 0.8, alpha = 0.8,
              color = ifelse(subset_ref(plans)$e_dvs > 0.5, "#3D77BB", "#B25D4C")) +
    redist.plot.distr_qtys(plans, vap_asian/total_vap,
                           color_thresh = NULL,
                           color = ifelse(subset_sampled(plans)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
                           size = 0.5, alpha = 0.5) +
    scale_y_continuous("Percent Asian by VAP") +
    labs(title = "CA Enacted versus Simulations") +
    scale_color_manual(values = c(cd_2000 = "black")) +
    geom_hline(yintercept = 0.5, linetype = "dotted") +
    geom_text(data = enac_sum, aes(x = asian_rank, label = round(e_dvs, 2)),
              vjust = 3, y = Inf, size = 2.5, fontface = "bold", lineheight = 0.8, alpha = 0.8,
              color = ifelse(subset_ref(plans)$e_dvs > 0.5, "#3D77BB", "#B25D4C")) +
    redist.plot.distr_qtys(plans, (vap_asian + vap_hisp)/total_vap,
                           color_thresh = NULL,
                           color = ifelse(subset_sampled(plans)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
                           size = 0.5, alpha = 0.5) +
    scale_y_continuous("Percent Hispanic or Asian by VAP") +
    labs(title = "CA Enacted versus Simulations") +
    scale_color_manual(values = c(cd_2000 = "black")) +
    geom_hline(yintercept = 0.5, linetype = "dotted") +
    geom_text(data = enac_sum, aes(x = ha_rank, label = round(e_dvs, 2)),
              vjust = 3, y = Inf, size = 2.5, fontface = "bold", lineheight = 0.8, alpha = 0.8,
              color = ifelse(subset_ref(plans)$e_dvs > 0.5, "#3D77BB", "#B25D4C")) +
    redist.plot.distr_qtys(plans, (vap_asian + vap_hisp + vap_black)/total_vap,
                           color_thresh = NULL,
                           color = ifelse(subset_sampled(plans)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
                           size = 0.5, alpha = 0.5) +
    scale_y_continuous("Percent Coalition by VAP") +
    labs(title = "CA Enacted versus Simulations") +
    scale_color_manual(values = c(cd_2000 = "black")) +
    geom_hline(yintercept = 0.5, linetype = "dotted") +
    redist.plot.distr_qtys(plans %>% number_by(e_dvs), (vap_asian + vap_hisp + vap_black)/total_vap, sort = FALSE,
                           color_thresh = NULL,
                           color = ifelse(subset_sampled(plans)$e_dvs > 0.5, "#3D77BB", "#B25D4C"),
                           size = 0.5, alpha = 0.5) +
    scale_y_continuous("Percent Coalition by VAP") +
    labs(title = "CA Enacted versus Simulations") +
    scale_color_manual(values = c(cd_2000 = "black")) +
    geom_hline(yintercept = 0.5, linetype = "dotted")
  
  ggsave("data-raw/CA/boxplot.pdf", p2, width = 11, height = 8)
  
}
