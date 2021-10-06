#' Tally a variable by district
#'
#' @param map a `redist_map` object
#' @param pop a variable to tally. Tidy-evaluated.
#' @param .data a `redist_plans` object
#'
#' @return a vector containing the tallied values by district and plan (column-major)
#' @export
tally_var <- function(map, pop, .data = redist:::cur_plans()) {
    redist:::check_tidy_types(map, .data)
    if (length(unique(diff(as.integer(.data$district)))) > 2)
        warning("Districts not sorted in ascending order; output may be incorrect.")
    idxs <- unique(as.integer(.data$draw))
    pop <- rlang::eval_tidy(rlang::enquo(pop), map)
    as.numeric(redist:::pop_tally(get_plans_matrix(.data)[, idxs, drop = FALSE],
        pop, attr(map, "ndists")))
}

#' Add summary statistics to sampled plans
#'
#' @param plans a `redist_plans` object
#' @param map a `redist_map` object
#' @param ... additional summary statistics to compute
#'
#' @return a modified `redist_plans` object
#' @export
add_summary_stats <- function(plans, map, ...) {
    perim_path <- here("data-out", attr(map, "analysis_name"), "perim.rds")

    if (file.exists(perim_path)) {
        state <- map$state[1]
        perim_df <- read_rds(perim_path)
    } else {
        perim_df <- redist.prep.polsbypopper(map, perim_path = perim_path)
    }
    plans <- plans %>%
        mutate(total_vap = tally_var(map, vap),
            plan_dev =  plan_parity(map),
            comp_edge = distr_compactness(map),
            comp_polsby = distr_compactness(map,
                                            measure = "PolsbyPopper",
                                            perim_df = perim_df),
            ndv = tally_var(map, ndv),
            nrv = tally_var(map, ndv),
            ...)

    tally_cols <- names(map)[c(tidyselect::eval_select(starts_with("pop_"), map),
                              tidyselect::eval_select(starts_with("vap_"), map),
                              tidyselect::eval_select(starts_with("adv_"), map),
                              tidyselect::eval_select(starts_with("arv_"), map))]
    for (col in tally_cols) {
        plans <- mutate(plans, {{ col }} := tally_var(map, map[[col]]), .before = ndv)
    }

    split_cols <- names(map)[tidyselect::eval_select(any_of(c("county", "muni")), map)]
    for (col in split_cols) {
        plans <- mutate(plans, "{col}_splits" := county_splits(map, map[[col]]), .before = ndv)
    }

    plans
}

#' Export `redist_plans` summary statistics to a file
#'
#' Rounds numeric values as needed and discards auxilliary information.
#'
#' @param plans a `redist_plans` object
#' @param path the path to save the files at. Will be passed to [here::here()]
#'
#' @returns invisibly
#' @export
save_summary_stats <- function(plans, path) {
    as_tibble(plans) %>%
        mutate(across(where(is.numeric), format, digits = 4, scientific = FALSE)) %>%
        write_csv(here(path))
}
