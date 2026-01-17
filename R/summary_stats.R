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
    if (length(unique(diff(as.integer(.data$district)))) > 2) {
        warning("Districts not sorted in ascending order; output may be incorrect.")
    }
    idxs <- unique(as.integer(.data$draw))
    pop <- rlang::eval_tidy(rlang::enquo(pop), map)
    as.numeric(redist:::pop_tally(
        get_plans_matrix(.data)[, idxs, drop = FALSE],
        pop, attr(map, "ndists")
    ))
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
    perim_path <- perim_path |>
      stringr::str_remove('_SHD') |>
      stringr::str_remove('_SSD')

    if (file.exists(perim_path)) {
        state <- map$state[1]
        perim_df <- read_rds(perim_path)
    } else {
        if (requireNamespace("redistmetrics", quietly = TRUE)) {
            perim_df <- redistmetrics::prep_perims(map, perim_path = perim_path)
        } else {
            perim_df <- redist.prep.polsbypopper(map, perim_path = perim_path)
        }
    }
    plans <- plans |>
        mutate(
            total_vap = redist::tally_var(map, .data$vap),
            plan_dev = redist::plan_parity(map),
            comp_edge = redistmetrics::comp_frac_kept(plans = redist::pl(), map),
            comp_polsby = redistmetrics::comp_polsby(
                plans = redist::pl(), map,
                perim_df = perim_df
            ),
            comp_bbox_reock = redistmetrics::comp_bbox_reock(
                plans = redist::pl(), map
            ),
            ndv = redist::tally_var(map, .data$ndv),
            nrv = redist::tally_var(map, .data$nrv),
            ndshare = .data$ndv / (.data$ndv + .data$nrv),
            ...
        )

    tally_cols <- names(map)[c(
        tidyselect::eval_select(starts_with("pop_"), map),
        tidyselect::eval_select(starts_with("vap_"), map),
        tidyselect::eval_select(matches("_(dem|rep)_"), map),
        tidyselect::eval_select(matches("^a[dr]v_"), map)
    )]
    for (col in tally_cols) {
        plans <- mutate(plans, {{ col }} := tally_var(map, map[[col]]), .before = ndv)
    }

    elecs <- dplyr::select(dplyr::as_tibble(map), dplyr::contains("_dem_")) |>
        names() |>
        stringr::str_sub(1, 6) |>
        unique()
    if (length(elecs) != 0) {
      elect_tb <- lapply(elecs, function(el) {
        vote_d <- dplyr::select(
          dplyr::as_tibble(map),
          dplyr::starts_with(paste0(el, "_dem_")),
          dplyr::starts_with(paste0(el, "_rep_"))
        )
        if (ncol(vote_d) != 2) {
          return(dplyr::tibble())
        }
        dvote <- dplyr::pull(vote_d, 1)
        rvote <- dplyr::pull(vote_d, 2)

        plans |>
          dplyr::mutate(
            dem = redist::group_frac(map, dvote, dvote + rvote),
            egap = redistmetrics::part_egap(plans = redist::pl(), shp = map, rvote = rvote, dvote = dvote),
            pbias = redistmetrics::part_bias(plans = redist::pl(), shp = map, rvote = rvote, dvote = dvote)
          ) |>
          dplyr::as_tibble() |>
          dplyr::group_by(.data$draw) |>
          dplyr::transmute(
            draw = .data$draw,
            district = .data$district,
            e_dvs = .data$dem,
            pr_dem = .data$dem > 0.5,
            e_dem = sum(.data$dem > 0.5, na.rm = TRUE),
            pbias = .data$pbias[1],
            egap = .data$egap[1]
          )
      }) |>
        purrr::list_rbind()

      elect_tb <- elect_tb |>
        dplyr::group_by(.data$draw, .data$district) |>
        dplyr::summarize(dplyr::across(dplyr::everything(), mean))
      plans <- dplyr::left_join(plans, elect_tb, by = c("draw", "district"))
    }

    split_cols <- names(map)[tidyselect::eval_select(tidyselect::any_of(c("county", "muni")), map)]
    for (col in split_cols) {
        if (col == "county") {
          plans <- plans |>
            dplyr::mutate(
              county_splits = redistmetrics::splits_admin(plans = redist::pl(), map, .data$county),
              total_county_splits = redistmetrics::splits_total(
                plans = redist::pl(), map, .data$county
              ),
              .before = "ndv"
            )
        } else if (col == "muni") {
          if (all(is.na(map$muni))) {
            # then by definition
            plans <- plans |>
              dplyr::mutate(muni_splits = 0L, .before = "ndv")
          } else {
            plans <- plans |>
              dplyr::mutate(
                muni_splits = redistmetrics::splits_sub_admin(plans = redist::pl(), map, .data$muni),
                total_muni_splits = redistmetrics::splits_sub_total(
                  plans = redist::pl(), map, .data$muni
                ),
                .before = "ndv"
              )
          }
        } else {
            plans <- plans |>
                dplyr::mutate("{col}_splits" := redistmetrics::splits_admin(plans = redist::pl(), map, map[[col]]), .before = "ndv")
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
    as_tibble(plans) |>
        mutate(across(where(is.numeric), format, digits = 4, scientific = FALSE)) |>
        write_csv(here(path))
}
