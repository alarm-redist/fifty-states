#!/usr/bin/env bash

# Re-run the heavy CA / TX / FL congressional analyses on FASRC, one heavy
# Slurm job per state-year (the 112-core treatment these three always get).
#
# These were held out of the regular non-convergence re-run because they need
# the big-core resources. Their 03_sim files on this branch (rerun-ca-tx-fl)
# have doubled `nsims`; each still thins to a 5000-draw final sample.
#
# Each job sources 01_prep -> 02_setup -> 03_sim via R/run_one_analysis.R and
# prints summary() diagnostics at the end.
#
# Just run it (from the repo root, on a FASRC login node):
#   bash scripts/submit_ca_tx_fl_fasrc.sh
#
# Useful overrides:
#   PARTITION=shared CPUS=112 MEM=80G TIME=0-18:00 \
#   STATES="TX" YEARS="2010" \
#   bash scripts/submit_ca_tx_fl_fasrc.sh

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
MEM="${MEM:-80G}"
CPUS="${CPUS:-112}"
STATES="${STATES:-CA TX FL}"
YEARS="${YEARS:-2010 2020}"
LOG_DIR="${LOG_DIR:-$REPO_DIR/data-raw/rerun_logs}"

cd "$REPO_DIR"
mkdir -p "$LOG_DIR"

echo "Repository: $REPO_DIR"
echo "Resources:  $CPUS cores, $MEM, partition $PARTITION, time $TIME"
echo "Submitting heavy jobs for: states=[$STATES] years=[$YEARS]"
echo

for state in $STATES; do
    for year in $YEARS; do
        slug="${state}_cd_${year}"
        if [[ ! -d "analyses/$slug" ]]; then
            echo "SKIP  $slug (analyses/$slug not found)"
            continue
        fi
        # REDIST_NCORES is exported for any script that reads it; note the
        # CA/FL 03_sim files set ncores explicitly, so they keep their own value.
        wrap_cmd="cd \"$REPO_DIR\" && module load R && REDIST_NCORES=$CPUS Rscript R/run_one_analysis.R $slug"
        sbatch \
            -p "$PARTITION" \
            -c "$CPUS" \
            --mem="$MEM" \
            -t "$TIME" \
            --job-name="rerun_${slug}" \
            --output="$LOG_DIR/${slug}_%j.out" \
            --wrap="$wrap_cmd"
        echo "submitted $slug"
    done
done

echo
echo "Slurm logs: $LOG_DIR/<STATE>_cd_<YEAR>_<jobid>.out"
