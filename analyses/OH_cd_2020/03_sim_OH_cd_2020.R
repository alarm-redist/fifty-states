###############################################################################
# Simulate plans for `OH_cd_2020`
# © ALARM Project, December 2021
###############################################################################

# Run the simulation -----
cli_process_start("Running simulations for {.pkg OH_cd_2020}")

N = 5000 # simulations

## First, simulate a VRA district in Cuyahoga county (Cleveland) -----

idxs = which(map_2020$county == "Cuyahoga County")
map_cleve = slice(map_2020, idxs) %>%
    suppressWarnings() %>%
    `attr<-`("ndists", 2) %>%
    `attr<-`("existing_col", NULL) %>%
    `attr<-`("pop_bounds", attr(map, "pop_bounds"))

constr = redist_constr(map_cleve) %>%
    add_constr_custom(100.0, function(pl, i) {
        spl = tapply(pl, map_cleve$county, dplyr::n_distinct) - 1L
        any(spl >= 3)
    }) %>%
    add_constr_grp_hinge(60.0, vap_black, vap, c(0.02, 0.07, 0.41))

pl_cleve = redist_smc(map_cleve, N, counties=split_unit, constraints=constr, n_steps=1,
                      pop_temper=0.05, seq_alpha=0.5, verbose=TRUE) %>%
    mutate(black = group_frac(map_cleve, vap_black, vap)) %>%
    number_by(black)

# prepare for simulating remainder
m_cleve = pl_cleve %>%
    group_by(draw) %>%
    filter(black[2] > 0.4, total_pop[2] >= attr(map, "pop_bounds")[1]) %>%
    as.matrix()
N_valid = ncol(m_cleve)
m_init = matrix(0L, nrow=nrow(map_2020), ncol=N)
m_init[idxs, seq_len(N_valid)] = m_cleve
m_init[idxs, seq(N_valid+1, N)] = m_cleve[, sample(N_valid, N-N_valid, replace=T)]
m_init[m_init != 2] = 0L
m_init[m_init == 2] = 1L


## Then simulate the remainder of the district -----

columbus_idx <- which(map_2020$class_muni == "B(4)(a)")

constr = redist_constr(map_2020) %>%
    add_constr_custom(100.0, function(pl, i) {
        spl = tapply(pl, map_2020$county, dplyr::n_distinct) - 1L
        any(spl >= 3) + 0.03*any(spl == 2)
    }) %>%
    add_constr_custom(0.5, function(pl, i) dplyr::n_distinct(pl[columbus_idx]) - 1L)

plans = redist_smc(map_2020, N, counties=split_unit, constraints=constr,
                   init_particles=m_init[, 1:N], pop_temper=0.01, seq_alpha=0.7,
                   verbose=TRUE) %>%
    pullback(map) %>%
    `attr<-`("prec_pop", map$pop)

cli_process_done()
cli_process_start("Saving {.cls redist_plans} object")

# Output the redist_map object. Do not edit this path.
write_rds(plans, here("data-out/OH_2020/OH_cd_2020_plans.rds"), compress = "xz")
cli_process_done()

# Compute summary statistics -----
cli_process_start("Computing summary statistics for {.pkg OH_cd_2020}")

splits_mat = apply(as.matrix(plans), 2, \(x) tapply(x, map$county, n_distinct)) - 1L
nd = attr(map, "ndists")

plans <- add_summary_stats(plans, map) %>%
    mutate(splits_1 = rep(as.integer(colSums(splits_mat == 1)), each=nd),
           splits_2 = rep(as.integer(colSums(splits_mat == 2)), each=nd),
           splits_3 = rep(as.integer(colSums(splits_mat >= 3)), each=nd))

# Output the summary statistics. Do not edit this path.
save_summary_stats(plans, "data-out/OH_2020/OH_cd_2020_stats.csv")

cli_process_done()

# Extra validation plots for custom constraints -----
# TODO remove this section if no custom constraints
if (interactive()) {
    library(ggplot2)
    library(patchwork)

    p1 = hist(plans, splits_1) + labs(x="Counties split once")
    p2 = hist(plans, splits_2) + labs(x="Counties split twice")
    p3 = hist(plans, splits_3) + labs(x="Counties split 3+ times")

    p1 + p2 + p3 + plot_layout(guides="collect")
}
