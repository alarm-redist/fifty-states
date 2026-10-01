#' Resolve the default number of cores for redist simulations
#'
#' Uses `REDIST_NCORES` when set, then `SLURM_CPUS_PER_TASK`, and finally a
#' repository default. This lets FASRC jobs inherit the cores requested with
#' `sbatch -c` or `srun -c` while still working outside Slurm.
#'
#' @param default Fallback number of cores when no environment variable is set.
#'
#' @returns A positive integer core count.
#' @export
redist_ncores <- function(default = 112L) {
  value <- Sys.getenv("REDIST_NCORES", unset = "")
  if (!nzchar(value)) {
    value <- Sys.getenv("SLURM_CPUS_PER_TASK", unset = "")
  }
  if (!nzchar(value)) {
    value <- as.character(default)
  }

  ncores <- suppressWarnings(as.integer(value))
  if (is.na(ncores) || ncores < 1L) {
    cli::cli_abort(
      "{.envvar REDIST_NCORES} or {.envvar SLURM_CPUS_PER_TASK} must be a positive integer."
    )
  }

  ncores
}

#' Install default redist simulation cores in a sourcing environment
#'
#' Analysis scripts call `redist_smc()` directly. This helper places a wrapper in
#' the script-sourcing environment so calls without an explicit `ncores` argument
#' default to [redist_ncores()]. Calls that already specify `ncores` keep their
#' script-level value.
#'
#' @param envir Environment where analysis scripts will be sourced.
#' @param ncores Default core count passed to `redist_smc()`.
#'
#' @returns Invisibly, the default core count.
#' @export
local_redist_smc_defaults <- function(envir = parent.frame(),
                                      ncores = redist_ncores()) {
  default_ncores <- ncores
  force(default_ncores)
  redist_smc_fn <- redist::redist_smc

  redist_smc <- function(..., ncores = default_ncores) {
    redist_smc_fn(..., ncores = ncores)
  }

  assign("redist_smc", redist_smc, envir = envir)
  invisible(ncores)
}
