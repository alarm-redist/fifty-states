#!/usr/bin/env bash

# Re-run the non-converged 2010/2020 congressional analyses on FASRC.
#
# This wraps `R/rerun_unconverged.R` (the cross-platform driver) with the
# FASRC niceties used elsewhere in the ALARM repos: it re-execs itself inside a
# Slurm allocation when launched from a login node, loads the R module, and tees
# a summary. The R driver runs each state-year in its own fresh R subprocess
# (sourcing 01_prep -> 02_setup -> 03_sim) so per-analysis globals never leak.
#
# Usage from a login node (grabs an interactive allocation, runs everything):
#   cd fifty-states
#   bash scripts/run_rerun_fasrc.sh
#
# Run a subset (state-years are STATE_YEAR, e.g. OH_2020 NY_2010):
#   bash scripts/run_rerun_fasrc.sh OH_2020 NY_2010
#
# Inside an existing allocation, or as a Slurm array task, set SKIP_SRUN=1 so it
# does not try to grab another allocation:
#   SKIP_SRUN=1 REDIST_NCORES=16 bash scripts/run_rerun_fasrc.sh OH_2020
#
# Useful overrides:
#   FASRC_PARTITION=test FASRC_MEM=80G FASRC_CPUS=16 FASRC_TIME=0-12:00

set -uo pipefail

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)/$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

if [[ -z "${REPO_DIR:-}" ]]; then
    if REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)"; then
        REPO_DIR="$REPO_ROOT"
    else
        REPO_DIR="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
    fi
fi

FASRC_PARTITION="${FASRC_PARTITION:-test}"
FASRC_MEM="${FASRC_MEM:-80G}"
FASRC_CPUS="${FASRC_CPUS:-16}"
FASRC_TIME="${FASRC_TIME:-0-12:00}"

# Targets come from the command line, then $STATES, then the full default set
# baked into the R driver (passed through as no args).
if [[ "$#" -gt 0 ]]; then
    TARGETS=("$@")
elif [[ -n "${STATES:-}" ]]; then
    read -r -a TARGETS <<< "$STATES"
else
    TARGETS=()
fi

# If launched from a login node, restart inside an interactive Slurm allocation.
# Skipped when already in an allocation (SLURM_JOB_ID set) or when SKIP_SRUN=1
# (e.g. when called as an sbatch array task by submit_rerun_fasrc.sh).
if [[ -z "${SLURM_JOB_ID:-}" && "${SKIP_SRUN:-0}" != "1" ]]; then
    exec srun --pty \
        -p "$FASRC_PARTITION" \
        --mem="$FASRC_MEM" \
        -c "$FASRC_CPUS" \
        -t "$FASRC_TIME" \
        /bin/bash "$SCRIPT_PATH" ${TARGETS[@]+"${TARGETS[@]}"}
fi

load_r_module() {
    if ! command -v module >/dev/null 2>&1; then
        source /etc/profile.d/modules.sh >/dev/null 2>&1 || true
        source /usr/share/Modules/init/bash >/dev/null 2>&1 || true
    fi
    if command -v module >/dev/null 2>&1; then
        module load R
    else
        echo "WARN: 'module' command not found; continuing with the current PATH."
    fi
}

cd "$REPO_DIR" || { echo "ERROR: could not cd to REPO_DIR=$REPO_DIR"; exit 1; }
load_r_module

if ! command -v Rscript >/dev/null 2>&1; then
    echo "ERROR: Rscript not found after module load."
    exit 1
fi

echo "================================================================"
echo "Repository:  $REPO_DIR"
echo "Slurm job:   ${SLURM_JOB_ID:-none}  task: ${SLURM_ARRAY_TASK_ID:-none}"
echo "Cores:       REDIST_NCORES=${REDIST_NCORES:-unset} SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK:-unset}"
echo "Targets:     ${TARGETS[*]:-<all default targets>}"
echo "================================================================"

# Hand off to the R driver. With no targets it re-runs the full default set.
Rscript R/rerun_unconverged.R ${TARGETS[@]+"${TARGETS[@]}"}
exit $?
