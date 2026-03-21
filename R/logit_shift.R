#' Logit Shift Baseline Data
#'
#' @param d_baseline baseline data containing vote columns
#' @param ndv Unquoted Democratic vote column name
#' @param nrv Unquoted Republican vote column name
#' @param target target to logit shift to
#' @param tol
#'
#' @returns a data frame with adjusted vote columns
#' @export
#'
#' @examples
#' # TODO
logit_shift_baseline <- function(d_baseline, ndv, nrv,
                                 target = 0.5,
                                 tol = sqrt(.Machine$double.eps)) {
  if (missing(ndv) || missing(nrv)) {
    cli::cli_abort('Both {.arg ndv} and {.arg nrv} must be provided.')
  }
  ndv_q <- rlang::enquo(ndv)
  nrv_q <- rlang::enquo(nrv)

  ndv_vec <- dplyr::pull(d_baseline, !!ndv_q)
  nrv_vec <- dplyr::pull(d_baseline, !!nrv_q)

  turn <- ndv_vec + nrv_vec
  ldvs <- dplyr::if_else(turn > 0, log(ndv_vec) - log(nrv_vec), 0)

  res <- uniroot(function(shift) {
    stats::weighted.mean(plogis(ldvs + shift), turn) - target
  }, c(-1, 1), tol = tol)

  ldvs <- ldvs + res$root

  ndv_new <- turn * plogis(ldvs)
  nrv_new <- turn - ndv_new

  dplyr::mutate(
    d_baseline,
    !!rlang::as_name(ndv_q) := ndv_new,
    !!rlang::as_name(nrv_q) := nrv_new
  )
}
