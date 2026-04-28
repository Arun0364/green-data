#!/bin/bash
# Submit from repo root:
#   sbatch run_halper.sh
#
# Optional overrides:
#   HUMAN_PEAKS=/path/to/file.gz HAL_FILE=/path/to/file.hal sbatch run_halper.sh

#SBATCH -J halper_map             # Job name
#SBATCH -p RM-shared              # Partition
#SBATCH -N 1                      # Number of nodes
#SBATCH -n 4                     # Number of tasks (CPUs)
#SBATCH -t 15:00:00               # Walltime (hh:mm:ss)
#SBATCH --mem=4G                 # Memory
#SBATCH -o logs/halper_%j.out
#SBATCH -e logs/halper_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL

set -euo pipefail

# -------------------------------
# ======= HALPER mapping =======
# -------------------------------

#Setup paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${ROOT:-$SCRIPT_DIR}"

DATA_DIR="$ROOT/data"
OUT_DIR="$ROOT/halper_output"
LOG_DIR="$ROOT/logs"

mkdir -p "$OUT_DIR" "$LOG_DIR"

echo "Running HALPER with ROOT=$ROOT"

# Load modules
module purge
module load anaconda3     

eval "$(conda shell.bash hook)"

# Activate HAL conda environment
conda activate hal

HALPER_SCRIPT="${HALPER_SCRIPT:-$ROOT/repos/halLiftover-postprocessing/halper_map_peak_orthologs.sh}"

export PATH="${HAL_BIN:-$HOME/repos/hal/bin}:${PATH:-}"
export PYTHONPATH="${HAL_PYTHONPATH:-$HOME/repos/halLiftover-postprocessing}:${PYTHONPATH:-}"


# -------------------------------
# ===== USER PARAMETERS =====
# -------------------------------

# Input peak files (gzipped narrowPeak)
HUMAN_PEAKS="${HUMAN_PEAKS:-$DATA_DIR/human_liver.narrowPeak.gz}"
MOUSE_PEAKS="${MOUSE_PEAKS:-$DATA_DIR/mouse_liver.narrowPeak.gz}"

# HAL file and species
HAL_FILE="${HAL_FILE:-$ROOT/data/10plusway-master.hal}"
SOURCE_SPECIES="${SOURCE_SPECIES:-Human}"
TARGET_SPECIES="${TARGET_SPECIES:-Mouse}"

# -------------------------------
# ===== Validate files =====
# -------------------------------

if [[ ! -f "$HUMAN_PEAKS" ]]; then
  echo "ERROR: Human peaks not found: $HUMAN_PEAKS"
  exit 1
fi

if [[ ! -f "$MOUSE_PEAKS" ]]; then
  echo "ERROR: Mouse peaks not found: $MOUSE_PEAKS"
  exit 1
fi

if [[ ! -f "$HAL_FILE" ]]; then
  echo "ERROR: HAL file not found: $HAL_FILE"
  exit 1
fi

if [[ ! -f "$HALPER_SCRIPT" ]]; then
  echo "ERROR: HALPER script not found: $HALPER_SCRIPT"
  exit 1
fi

# Unzip BED files
echo "Unzipping human peaks..."
gunzip -c "$HUMAN_PEAKS" > "$OUT_DIR/human_liver.narrowPeak"

echo "Unzipping mouse peaks..."
gunzip -c "$MOUSE_PEAKS" > "$OUT_DIR/mouse_liver.narrowPeak"

# Run HALPER mapping
echo "Running HALPER mapping..."
"$HALPER_SCRIPT" \
    -b "$OUT_DIR/human_liver.narrowPeak" \
    -o "$OUT_DIR" \
    -s "$SOURCE_SPECIES" \
    -t "$TARGET_SPECIES" \
    -c "$HAL_FILE"
echo "HALPER mapping finished!"
