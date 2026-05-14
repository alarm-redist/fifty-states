#!/usr/bin/env bash
#SBATCH --job-name=FL-cd-1990
#SBATCH --partition=test
#SBATCH --mem=80G
#SBATCH --cpus-per-task=112
#SBATCH --time=0-12:00:00
#SBATCH --output=FL_cd_1990_%j.out
#SBATCH --error=FL_cd_1990_%j.err

set -euo pipefail

REPO="${1:-$PWD}"

cd "$REPO"

module load R

Rscript --vanilla - <<'RSCRIPT'
devtools::load_all()

source(file.path(here::here(), "analyses/FL_cd_1990/01_prep_FL_cd_1990.R"))
source(file.path(here::here(), "analyses/FL_cd_1990/02_setup_FL_cd_1990.R"))
source(file.path(here::here(), "analyses/FL_cd_1990/03_sim_FL_cd_1990.R"))
RSCRIPT
