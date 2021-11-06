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
    if (is.null(slug <- attr(map, "analysis_name"))) stop("`map` missing `analysis_name` attribute.")
    perim_path <- here("data-out", slug, "perim.rds")

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
            nrv = tally_var(map, nrv),
            ndshare = ndv / (ndv + nrv),
            ...)

    tally_cols <- names(map)[c(tidyselect::eval_select(starts_with("pop_"), map),
                              tidyselect::eval_select(starts_with("vap_"), map),
                              tidyselect::eval_select(matches("_(dem|rep)_"), map),
                              tidyselect::eval_select(matches("^a[dr]v_"), map))]
    for (col in tally_cols) {
        plans <- mutate(plans, {{ col }} := tally_var(map, map[[col]]), .before = ndv)
    }

    elecs <- select(as_tibble(map), contains("_dem_")) %>%
        names() %>%
        str_sub(1, 6) %>%
        unique()

    elect_tb <- purrr::map_dfr(elecs, function(el) {
        dvote <- pull(select(as_tibble(map), starts_with(paste0(el, "_dem_"))))
        rvote <- pull(select(as_tibble(map), starts_with(paste0(el, "_rep_"))))
        plans %>%
            mutate(dem = group_frac(map, dvote, dvote + rvote),
                   egap = partisan_metrics(map, "EffGap", rvote, dvote),
                   pbias = partisan_metrics(map, "Bias", rvote, dvote)) %>%
            as_tibble() %>%
            group_by(draw) %>%
            transmute(draw = draw,
                      district = district,
                      pr_dem = dem > 0.5,
                      e_dem = sum(dem > 0.5, na.rm=T),
                      pbias = -pbias[1], # flip so dem = negative
                      egap = egap[1])
    })

    elect_tb <- elect_tb %>%
        group_by(draw, district) %>%
        summarize(across(everything(), mean))
    plans <- left_join(plans, elect_tb, by = c("draw", "district"))

    split_cols <- names(map)[tidyselect::eval_select(any_of(c("county", "muni")), map)]
    for (col in split_cols) {
        if (col == "county") {
            plans <- mutate(plans, county_splits = county_splits(map, county), .before = ndv)
        } else if (col == "muni") {
            plans <- mutate(plans, muni_splits = muni_splits(map, muni), .before = ndv)
        } else {
            plans <- mutate(plans, "{col}_splits" := county_splits(map, map[[col]]), .before = ndv)
        }
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




#' Counts the Number of Municipalities Split Between Districts
#'
#' Counts the total number of municpalities that are split.
#' Municipalities in this interpretation do not need to cover the entire state, which
#' differs from counties.
#'
#' @param plans A numeric vector (if only one map) or matrix with one row
#' for each precinct and one column for each map. Required.
#' @param munis A vector of municipality names or ids.
#'
#' @return integer matrix where each district is a
#'
#' @concept analyze
#' @export
#'
#' @examples
#' data(iowa)
#' ia <- redist_map(iowa, existing_plan = cd_2010, total_pop = pop, pop_tol = 0.01)
#' plans <- redist_smc(ia, 50, silent = TRUE)
#' ia$region[1:10] <- NA
#' splits <- redist.muni.splits(plans, ia$region)
redist.muni.splits <- function(plans, munis) {
    if (missing(plans)) {
        stop('Please provide an argument to plans.')
    }
    if (inherits(plans, 'redist_plans')) {
        plans <- get_plans_matrix(plans)
    }
    if (!is.matrix(plans)) {
        plans <- matrix(plans, ncol = 1)
    }
    if (!any(class(plans) %in% c('numeric', 'matrix'))) {
        stop('Please provide "plans" as a matrix.')
    }

    if (missing(munis)) {
        stop('Please provide an argument to `munis`.')
    }

    plans <- plans[!is.na(munis), ]
    munis <- munis[!is.na(munis)]
    if (class(munis) %in% c('character', 'numeric', 'integer')) {
        uc <- unique(sort(munis))
        muni_id <- rep(0, nrow(plans))
        for (i in 1:nrow(plans)) {
            muni_id[i] <- which(uc == munis[i])
        }
    } else{
        stop('Please provide `munis` as a character, numeric, or integer vector.')
    }


    redist:::splits(plans - 1, community = muni_id - 1)
}

#' @rdname redist.muni.splits
#' @order 1
#'
#' @param map a \code{\link{redist_map}} object
#' @param .data a \code{\link{redist_plans}} object
#'
#' @concept analyze
#' @export
muni_splits <- function(map, munis, .data = redist:::cur_plans()) {
    redist:::check_tidy_types(map, .data)
    idxs <- unique(as.integer(.data$draw))
    munis <- rlang::eval_tidy(rlang::enquo(munis), map)
    rep(redist.muni.splits(plans = get_plans_matrix(.data)[, idxs, drop = FALSE], munis = munis),
        each = attr(map, 'ndists')
    )
}
