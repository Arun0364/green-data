#!/bin/bash
#SBATCH --job-name=rgreat
#SBATCH --output=rgreat_%j.out
#SBATCH --error=rgreat_%j.err
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8000M
#SBATCH --account=bio230007p
#SBATCH --partition=RM-shared
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=surathas@andrew.cmu.edu

ROOT="${ROOT:-${SLURM_SUBMIT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}"
DATA_ROOT="/ocean/projects/bio230007p/ikaplow"  

cd "$ROOT/rGREAT_Analysis/scripts"

module load anaconda3
eval "$(conda shell.bash hook)"
conda activate "${RGREAT_CONDA_ENV:-rgreat_env}"

Rscript rgreat_analysis.R "$ROOT" "${DATA_ROOT}" 