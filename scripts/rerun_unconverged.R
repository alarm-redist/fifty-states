#!/usr/bin/env Rscript
###############################################################################
# Re-run the 2010/2020 congressional analyses that failed to converge
# (per CONVERGENCE_REPORT.md), using the bumped `nsims` in their 03_sim files.
#
# Scope: all "Fail" (R-hat > 1.1) and "Marginal" (1.05-1.1) 2010/2020
#        state-years, EXCLUDING TX / CA / FL.
#
# Each state-year is run in its own fresh R subprocess (so globals such as
# OH_cd_2020's `N` never leak between analyses), sourcing 01_prep -> 02_setup
# -> 03_sim in order. The 03_sim step overwrites the plans + stats in
# data-out/, then we print summary() diagnostics so you can read the new
# split-R-hat values and any SMC efficiency warnings.
#
# Usage (from the repo root):
#   Rscript scripts/rerun_unconverged.R                # re-run every target
#   Rscript scripts/rerun_unconverged.R OH_2020 NY_2020   # re-run a subset
#
# NOTE: this file must live in scripts/, NOT R/. The 01_prep scripts call
# devtools::load_all(), which sources every file under R/ — top-level code
# there gets executed, so a driver in R/ re-launches itself from inside each
# subprocess (infinite fork bomb; see the banner-only CO_2010 logs from the
# June/July 2026 cluster runs).
#
# Logs (full stdout/stderr incl. summary() + warnings) are written to
#   data-raw/rerun_logs/<STATE>_<YEAR>_<timestamp>.log
###############################################################################

suppressMessages({
    library(here)
})

# --- Target state-years -------------------------------------------------------
# Fail (R-hat > 1.1), excl. TX/CA/FL
fail <- c(
    "CO_2010", "AL_2010", "NY_2010", "PA_2010", "IN_2010", "WA_2010",
    "GA_2010", "SC_2010", "IA_2010",
    "OH_2020", "NY_2020", "PA_2020", "KS_2020"
)
# Marginal (1.05-1.1), excl. CA/FL
marginal <- c(
    "MI_2010", "NC_2010", "IL_2010", "OH_2010",
    "MI_2020", "NC_2020", "AL_2020", "CO_2020", "SC_2020", "MS_2020", "WA_2020"
)
all_targets <- c(fail, marginal)

# --- Resolve which targets to run from the command line ----------------------
cli_args <- commandArgs(trailingOnly = TRUE)
targets <- if (length(cli_args) > 0) cli_args else all_targets

unknown <- setdiff(targets, all_targets)
if (length(unknown) > 0) {
    stop("Unknown target(s): ", paste(unknown, collapse = ", "),
        "\nValid targets:\n  ", paste(all_targets, collapse = ", "))
}

# --- Set up logging ----------------------------------------------------------
log_dir <- here("data-raw", "rerun_logs")
dir.create(log_dir, showWarnings = FALSE, recursive = TRUE)
stamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

rscript <- file.path(R.home("bin"), "Rscript")

# Body run inside each isolated subprocess. Instead of re-running
# 01_prep/02_setup (many of their source URLs have rotted), download the
# published redist_map from the ALARM Dataverse deposit via alarmdata — the
# deposit files ARE each 02_setup's output, so this reproduces the original
# runs' exact inputs. Falls back to sourcing 01_prep/02_setup if the download
# fails. Only 03_sim then runs, and we print summary() diagnostics.
# (Uses a @SLUG@ token, not sprintf: the body contains %>%.)
runner_template <- '
slug <- "@SLUG@"
parts <- strsplit(slug, "_")[[1]]
state <- parts[1]
year <- as.integer(parts[3])
dir <- here::here("analyses", slug)
message("==== Re-running ", slug, " ====")
suppressMessages({
    library(dplyr); library(readr); library(stringr); library(sf)
    library(redist); library(cli); library(here)
    devtools::load_all()
})
map_path <- here("data-out", paste0(state, "_", year), paste0(slug, "_map.rds"))
have_map <- file.exists(map_path)
if (!have_map) {
    have_map <- tryCatch({
        # The deposit is public; a stale personal key causes a 401.
        Sys.unsetenv("DATAVERSE_KEY")
        m <- alarmdata::alarm_50state_map(state, year = year)
        dir.create(dirname(map_path), recursive = TRUE, showWarnings = FALSE)
        write_rds(m, map_path, compress = "xz")
        TRUE
    }, error = function(e) {
        message("alarmdata download failed (", conditionMessage(e),
            "); falling back to 01_prep/02_setup")
        FALSE
    })
}
if (have_map) {
    map <- read_rds(map_path)
    # Objects some 03_sim scripts expect from 02_setup, rebuilt from the
    # published map (its columns already include what 02_setup computed).
    if (slug == "KS_cd_2020") {
        map_m <- merge_by(map, core_id)
    }
    if (slug == "OH_cd_2020") {
        map_2020 <- map %>%
            st_drop_geometry() %>%
            group_by(merge_unit, county, cd_2020) %>%
            summarize(across(matches("(pop|vap)"), sum),
                muni = muni[1],
                class_co = class_co[1],
                class_muni = class_muni[1]) %>%
            ungroup() %>%
            mutate(split_unit = if_else(class_muni == "B(4)(a)", muni, county))
    }
} else {
    source(file.path(dir, paste0("01_prep_", slug, ".R")))
    source(file.path(dir, paste0("02_setup_", slug, ".R")))
}
source(file.path(dir, paste0("03_sim_", slug, ".R")))
message("==== summary() diagnostics for ", slug, " ====")
print(summary(plans))
message("==== done ", slug, " ====")
'

# --- Run each target ---------------------------------------------------------
results <- data.frame(
    target = targets, status = NA_character_, log = NA_character_,
    stringsAsFactors = FALSE
)

for (i in seq_along(targets)) {
    sy <- targets[i]
    state <- sub("_.*$", "", sy)
    year <- sub("^.*_", "", sy)
    log_file <- file.path(log_dir, paste0(sy, "_", stamp, ".log"))
    results$log[i] <- log_file

    # The prep scripts write_rds() into data-out/<STATE>_<YEAR>/ without
    # creating it, which fails on a fresh clone.
    dir.create(here("data-out", sy), showWarnings = FALSE, recursive = TRUE)

    message(sprintf("[%d/%d] Re-running %s ... (log: %s)",
        i, length(targets), sy, log_file))

    code <- gsub("@SLUG@", paste0(state, "_cd_", year), runner_template, fixed = TRUE)
    rc <- system2(rscript, args = c("-e", shQuote(code)),
        stdout = log_file, stderr = log_file)

    results$status[i] <- if (identical(rc, 0L)) "ok" else paste0("ERROR(", rc, ")")
    message("    -> ", results$status[i])
}

# --- Report ------------------------------------------------------------------
message("\n================ Re-run summary ================")
for (i in seq_along(targets)) {
    message(sprintf("  %-9s %-10s %s", results$target[i], results$status[i],
        results$log[i]))
}
message("\nInspect each log for the new split-R-hat values (target: 1.00-1.05)")
message("and for any SMC efficiency / low-acceptance warnings. If a state-year")
message("still shows R-hat > 1.05 or warns that it needs more samples or runs,")
message("bump `nsims` further (or add a run) in its 03_sim file and re-run it,")
message("e.g.  Rscript scripts/rerun_unconverged.R ", targets[1])

failed <- results$target[results$status != "ok"]
if (length(failed) > 0) {
    message("\nState-years whose scripts errored out: ",
        paste(failed, collapse = ", "))
    quit(status = 1)
}
