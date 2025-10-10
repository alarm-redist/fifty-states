
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
            keeps <- rep(TRUE, x$plans |> subset_sampled() |> nrow())
        }
        x$plans |>
            redist::subset_sampled() |>
            as_tibble() |>
            select(draw, district) |>
            filter(keeps) |>
            mutate(draw = as.integer(draw))
    })

    adds <- c(
      0,
      sapply(keep_l, function(x) {
        z <- x$draw[1]
        x |> filter(draw == z) |> nrow()
      }) |> cumsum()
    )

    plans_m_l <- lapply(seq_along(plans_m_l), function(i) {
        m <- plans_m_l[[i]]
        keep <- keep_l[[i]]
        for (j in seq_len(ncol(m))) {
            keep_j <- keep |>
                filter(draw == j) |>
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

# Helpers
rep_col <- function(col, n) {
    matrix(rep(col, n), ncol = n, byrow = FALSE)
}
rep_cols <- function(mat, n) {
    do.call("cbind", lapply(seq_len(ncol(mat)), \(x) rep_col(mat[, x], n)))
}
