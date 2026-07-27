#!/usr/bin/env Rscript
###############################################################################
# Run a single congressional analysis end-to-end: source 01_prep -> 02_setup
# -> 03_sim for one slug, then print summary() convergence diagnostics.
#
# Usage (from the repo root):
#   Rscript R/run_one_analysis.R CA_cd_2020
#
# 01_prep loads libraries + devtools::load_all() and (re)builds the shapefile
# only if it is missing; 02_setup and 03_sim reuse that session. This is the
# worker invoked by scripts/submit_ca_tx_fl_fasrc.sh for each heavy state.
###############################################################################

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
    stop("usage: Rscript R/run_one_analysis.R <SLUG>  e.g. CA_cd_2020")
}
slug <- args[[1]]
dir <- file.path("analyses", slug)
if (!dir.exists(dir)) stop("analysis directory not found: ", dir)

options(error = function() {
    cat("\n--- R traceback ---\n")
    traceback(2)
    quit(save = "no", status = 1)
})

message("==== Running ", slug, " ====")
source(file.path(dir, paste0("01_prep_", slug, ".R")))
source(file.path(dir, paste0("02_setup_", slug, ".R")))
source(file.path(dir, paste0("03_sim_", slug, ".R")))

message("==== summary() diagnostics for ", slug, " ====")
print(summary(plans))
message("==== done ", slug, " ====")
