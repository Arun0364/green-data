#!/bin/bash
#SBATCH --job-name=rgreat_plots
#SBATCH --output=rgreat_plots_%j.out
#SBATCH --error=rgreat_plots_%j.err
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=2000M
#SBATCH --account=bio230007p
#SBATCH --partition=RM-shared
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=surathas@andrew.cmu.edu

ROOT="${ROOT:-${SLURM_SUBMIT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}"

cd "$ROOT"

module load anaconda3
eval "$(conda shell.bash hook)"
conda activate "${RGREAT_CONDA_ENV:-rgreat_env}"

Rscript rGREAT_Analysis/scripts/rgreat_plots.R "$ROOT"  