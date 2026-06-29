#!/usr/bin/env bash

# Submit the non-converged 2010/2020 congressional re-runs as Slurm arrays on
# FASRC. Each array task re-runs one state-year via scripts/run_rerun_fasrc.sh
# (which calls R/rerun_unconverged.R for that one target).
#
# The default split puts the heaviest analyses (largest nsims / the two-stage
# OH_2020) in their own higher-core array, and runs the rest as a throttled
# array with a smaller per-task core count.
#
# Scope mirrors CONVERGENCE_REPORT.md: all "Fail" (R-hat > 1.1) and "Marginal"
# (1.05-1.1) 2010/2020 state-years, EXCLUDING TX / CA / FL.
#
# Usage:
#   bash scripts/submit_rerun_fasrc.sh
#
# Useful overrides:
#   PARTITION=test HEAVY_CPUS=48 REGULAR_CPUS=16 REGULAR_MAX_PARALLEL=8 \
#   bash scripts/submit_rerun_fasrc.sh
#
# Run a custom set instead of the defaults:
#   REGULAR_TARGETS="CO_2010 PA_2010" HEAVY_TARGETS="NY_2010" \
#   bash scripts/submit_rerun_fasrc.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

if [[ -z "${REPO_DIR:-}" ]]; then
    if REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)"; then
        REPO_DIR="$REPO_ROOT"
    else
        REPO_DIR="$(cd "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
    fi
fi

PARTITION="${PARTITION:-test}"
TIME="${TIME:-0-12:00}"
REGULAR_MEM="${REGULAR_MEM:-80G}"
HEAVY_MEM="${HEAVY_MEM:-80G}"
REGULAR_CPUS="${REGULAR_CPUS:-16}"   # NY_2010/PA_2010 hardcode up to 16 ncores
HEAVY_CPUS="${HEAVY_CPUS:-48}"
REGULAR_MAX_PARALLEL="${REGULAR_MAX_PARALLEL:-8}"
LOG_DIR="${LOG_DIR:-$REPO_DIR/data-raw/rerun_logs}"

# Fail (R-hat > 1.1) + Marginal (1.05-1.1), excl. TX/CA/FL. The heaviest by
# nsims / structure are split off into their own array.
HEAVY_TARGETS="${HEAVY_TARGETS:-NY_2010 GA_2010 IL_2010 NY_2020 OH_2020}"
REGULAR_TARGETS="${REGULAR_TARGETS:-CO_2010 AL_2010 PA_2010 IN_2010 WA_2010 SC_2010 IA_2010 MI_2010 NC_2010 OH_2010 PA_2020 KS_2020 MI_2020 NC_2020 AL_2020 CO_2020 SC_2020 MS_2020 WA_2020}"

submit_array() {
    local label="$1"
    local targets_string="$2"
    local cpus="$3"
    local mem="$4"
    local max_parallel="${5:-}"
    local -a targets
    local array_spec target_exports wrap_cmd

    read -r -a targets <<< "$targets_string"
    if [[ ${#targets[@]} -eq 0 ]]; then
        echo "Skipping $label because it has no targets."
        return 0
    fi

    target_exports="$(printf "%s " "${targets[@]}")"
    target_exports="${target_exports% }"
    array_spec="0-$((${#targets[@]} - 1))"
    if [[ -n "$max_parallel" ]]; then
        array_spec="${array_spec}%${max_parallel}"
    fi

    # Each array task picks its single target and re-runs it. SKIP_SRUN=1 keeps
    # run_rerun_fasrc.sh from grabbing a nested allocation; REDIST_NCORES exposes
    # the requested core count to any script that reads it.
    wrap_cmd="targets=($target_exports); target=\"\${targets[\$SLURM_ARRAY_TASK_ID]}\"; cd \"$REPO_DIR\" && module load R && REDIST_NCORES=$cpus SKIP_SRUN=1 bash scripts/run_rerun_fasrc.sh \"\$target\""

    sbatch \
        -p "$PARTITION" \
        --mem="$mem" \
        -c "$cpus" \
        -t "$TIME" \
        --job-name="rerun_${label}" \
        --array="$array_spec" \
        --output="$LOG_DIR/rerun_${label}_%A_%a.out" \
        --wrap="$wrap_cmd"
}

main() {
    cd "$REPO_DIR"
    mkdir -p "$LOG_DIR"

    echo "Submitting regular-target array:"
    echo "  targets: $REGULAR_TARGETS"
    echo "  resources: $REGULAR_CPUS cores, $REGULAR_MEM, max $REGULAR_MAX_PARALLEL concurrent tasks"
    submit_array "regular" "$REGULAR_TARGETS" "$REGULAR_CPUS" "$REGULAR_MEM" "$REGULAR_MAX_PARALLEL"

    echo "Submitting heavy-target array:"
    echo "  targets: $HEAVY_TARGETS"
    echo "  resources: $HEAVY_CPUS cores, $HEAVY_MEM"
    submit_array "heavy" "$HEAVY_TARGETS" "$HEAVY_CPUS" "$HEAVY_MEM"

    echo
    echo "Slurm --output logs: $LOG_DIR/rerun_<label>_<jobid>_<task>.out"
    echo "Per-analysis R logs: $LOG_DIR/<STATE>_<YEAR>_<timestamp>.log"
}

main "$@"
