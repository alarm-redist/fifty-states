#' Prep Particles for Partial SMC
#'
#' @param map primary map of entire state
#' @param map_plan_list A list of lists, where each inner list is named  'map' for
#' each `redist_map` and 'plans' for each `redist_plans`
#' @param uid unique id column identifying each row. Must be unique and the same
#' across `map` and each `redist_map` in `map_plan_list`
#' @param dist_keep column in each plans object identifying which districts to keep
#' @param nsims The number of samples to draw.
#'
#' @md
#' @return matrix of particles
#' @export
#'
#' @examples
#' # TODO
prep_particles <- function(map, map_plan_list, uid, dist_keep, nsims) {
    m_init <- matrix(0L, nrow = nrow(map), ncol = nsims)

    # set up id correspondence ----
    ids <- rlang::eval_tidy(rlang::enquo(uid), map)
    map_rows <- lapply(map_plan_list, function(x) {
        match(rlang::eval_tidy(rlang::enquo(uid), x$map), ids)
    })

    plans_m_l <- lapply(map_plan_list, function(x) {
        redist::get_plans_matrix(subset_sampled(x$plans))
    })

    keep_l <- lapply(map_plan_list, function(x) {
        keeps <- as.logical(rlang::eval_tidy(rlang::enquo(dist_keep), x$plans))
        if (is.null(keeps)) {
            keeps <- rep(TRUE, x$plans %>% subset_sampled() %>% nrow())
        }
        x$plans %>%
            redist::subset_sampled() %>%
            as_tibble() %>%
            select(draw, district) %>%
            filter(keeps) %>%
            mutate(draw = as.integer(draw))
    })

    adds <- sapply(keep_l, function(x) {
        z <- x$draw[1]
        x %>% filter(draw == z) %>% nrow()
    }) %>% cumsum() %>% c(0, .)

    plans_m_l <- lapply(seq_along(plans_m_l), function(i) {
        m <- plans_m_l[[i]]
        keep <- keep_l[[i]]
        for (j in seq_len(ncol(m))) {
            keep_j <- keep %>%
                filter(draw == j) %>%
                pull(district)
            m[!(m[, j] %in% keep_j), j] <- 0L
            m[, j] <- match(m[, j], sort(unique(m[, j]))) - as.integer(any(m[, j] == 0))
            m[, j] <- ifelse(m[, j] == 0, m[, j], m[, j] + adds[i])
        }
        m
    })

    for (i in seq_len(length(plans_m_l))) {
        n <- nsims/ncol(plans_m_l[[i]])
        m_init[map_rows[[i]], ] <- rep_cols(plans_m_l[[i]], n)
    }

    m_init
}

rep_cols <- function(mat, n) {
    do.call("cbind", lapply(seq_len(ncol(mat)), \(x) rep_col(mat[, x], n)))
}

rep_col <- function(col, n) {
    matrix(rep(col, n), ncol = n, byrow = FALSE)
}

add_summary_stats_cvap <- function(plans, map, ...) {
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
            total_cvap = tally_var(map, cvap),
            plan_dev =  plan_parity(map),
            comp_edge = distr_compactness(map),
            comp_polsby = distr_compactness(map,
                measure = "PolsbyPopper",
                perim_df = perim_df),
            ndv = tally_var(map, ndv),
            nrv = tally_var(map, nrv),
            ndshare = ndv/(ndv + nrv),
            ...)

    tally_cols <- names(map)[c(tidyselect::eval_select(starts_with("pop_"), map),
        tidyselect::eval_select(starts_with("vap_"), map),
        tidyselect::eval_select(starts_with("cvap_"), map),
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
        vote_d <- select(as_tibble(map),
            starts_with(paste0(el, "_dem_")),
            starts_with(paste0(el, "_rep_")))
        if (ncol(vote_d) != 2) return(tibble())
        dvote <- pull(vote_d, 1)
        rvote <- pull(vote_d, 2)

        plans %>%
            mutate(dem = group_frac(map, dvote, dvote + rvote),
                egap = partisan_metrics(map, "EffGap", rvote, dvote),
                pbias = partisan_metrics(map, "Bias", rvote, dvote)) %>%
            as_tibble() %>%
            group_by(draw) %>%
            transmute(draw = draw,
                district = district,
                pr_dem = dem > 0.5,
                e_dem = sum(dem > 0.5, na.rm = T),
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
