#!/usr/bin/env bash
#SBATCH --job-name=split-2020
#SBATCH --array=0-2
#SBATCH --cpus-per-task=112
#SBATCH --time=3-00:00:00
#SBATCH --mem=0
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.err

set -euo pipefail

REPO="${1:-$PWD}"
ANALYSES=(CA_cd_2020 FL_cd_2020 TX_cd_2020)
ANALYSIS="${ANALYSES[$SLURM_ARRAY_TASK_ID]}"

cd "$REPO"
mkdir -p logs

export ANALYSIS
export REPO
export REDIST_NCORES="${SLURM_CPUS_PER_TASK:-112}"
export ALARMDATA_RETRIES=5
export ALARMDATA_RETRY_WAIT=30

module load R

which Rscript
Rscript --version

Rscript - <<'RSCRIPT'
analysis <- Sys.getenv("ANALYSIS")
repo <- Sys.getenv("REPO")
ncores <- as.integer(Sys.getenv("REDIST_NCORES", "112"))

# Some patched scripts use parallel::detectCores() - 1.
# Make that resolve to exactly REDIST_NCORES.
assignInNamespace(
  "detectCores",
  function(...) ncores + 1L,
  ns = "parallel"
)

devtools::load_all(repo, quiet = TRUE)

run_sim(
  analysis,
  repo = repo,
  load_all = FALSE,
  map_source = "alarmdata"
)
RSCRIPT
