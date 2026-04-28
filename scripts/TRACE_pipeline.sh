#!/usr/bin/env bash
# =============================================================================
# TRACE_pipeline.sh — liver-ATAC-OCR Master Submission Script
# 03-713: Bioinformatics Data Integration Practicum, Spring 2026
#
# Submits Tasks 2–5 as chained SLURM jobs. Each step only starts after
# the previous one completes successfully (--dependency=afterok). If any
# step fails, all downstream jobs are automatically cancelled by SLURM.
#
#   Step 1: HALPER cross-species liftover          (run_halper_mapping.sh)
#   Step 2: Promoter/Enhancer classification       (run_pe_classification.sh)
#   Step 3: rGREAT biological process enrichment   (run_rgreat.sh)
#   Step 4: rGREAT plots                           (run_plots.sh)
#   Step 5: Motif analysis (MEME-ChIP)             (run_motif_analysis.sh)
#
# Run this script on the LOGIN NODE — it submits jobs, it does not run them.
#
# Quickstart (after filling in config.sh):
#   source config.sh && bash scripts/TRACE_pipeline.sh
#
# Or pass everything via flags (overrides config.sh):
#   bash scripts/TRACE_pipeline.sh \
#       --human  /path/to/human.narrowPeak.gz \
#       --mouse  /path/to/mouse.narrowPeak.gz \
#       --hal    /path/to/alignment.hal \
#       --genome /path/to/mm10.fa \
#       --jaspar /path/to/JASPAR.meme \
#       --data-root /path/to/shared/atac/data
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve repo root.
# TRACE_pipeline.sh lives in scripts/, so go up one level.
# On SLURM, SLURM_SUBMIT_DIR is the directory sbatch was called from.
# Falls back to deriving from BASH_SOURCE for local/interactive use.
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${ROOT:-${SLURM_SUBMIT_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}}"

# ---------------------------------------------------------------------------
# Source config.sh if present at repo root.
# CLI flags (parsed below) override anything set in config.sh.
# ---------------------------------------------------------------------------
CONFIG_FILE="$ROOT/config.sh"
if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
  echo "[config] Loaded $CONFIG_FILE"
fi

# ---------------------------------------------------------------------------
# Defaults — all overridable via config.sh or CLI flags.
# ---------------------------------------------------------------------------
DATA_DIR="${DATA_DIR:-$ROOT/data/raw}"
PE_INPUT="${PE_INPUT:-$ROOT/PE_classification/input}"

HUMAN_PEAKS="${HUMAN_PEAKS:-$DATA_DIR/human_liver.narrowPeak.gz}"
MOUSE_PEAKS="${MOUSE_PEAKS:-$DATA_DIR/mouse_liver.narrowPeak.gz}"
HAL_FILE="${HAL_FILE:-$DATA_DIR/10plusway-master.hal}"
TSS_FILE="${TSS_FILE:-$PE_INPUT/gencode.vM15.annotation.protTranscript.geneNames_TSSWithStrand_sorted.bed}"
MM10_GENOME="${MM10_GENOME:-$DATA_DIR/mm10.fa}"
JASPAR_DB="${JASPAR_DB:-$DATA_DIR/motif_dbs/JASPAR2026_vertebrates_combined.meme}"
DATA_ROOT="${DATA_ROOT:-}"   # Required for rGREAT; no default possible.

# HAL/HALPER tool paths — default to $HOME/repos (common install location).
HALPER_SCRIPT="${HALPER_SCRIPT:-$HOME/repos/halLiftover-postprocessing/halper_map_peak_orthologs.sh}"
HAL_BIN="${HAL_BIN:-$HOME/repos/hal/bin}"
HAL_PYTHONPATH="${HAL_PYTHONPATH:-$HOME/repos/halLiftover-postprocessing}"

SOURCE_SPECIES="${SOURCE_SPECIES:-Human}"
TARGET_SPECIES="${TARGET_SPECIES:-Mouse}"
HAL_CONDA_ENV="${HAL_CONDA_ENV:-hal}"
RGREAT_CONDA_ENV="${RGREAT_CONDA_ENV:-rgreat_env}"

SKIP_HALPER=false
SKIP_PE=false
SKIP_GREAT=false
SKIP_MOTIF=false

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
die()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; exit 1; }

usage() {
  cat <<EOF
Usage: bash scripts/TRACE_pipeline.sh [OPTIONS]

Submits the TRACE pipeline as chained SLURM jobs.
Run from the repo root on a login node.

Input/path options:
  --root DIR            Project root directory (default: auto-detected)
  --human FILE          Human ATAC-seq narrowPeak file (.gz)
  --mouse FILE          Mouse ATAC-seq narrowPeak file (.gz)
  --hal FILE            HAL alignment file (.hal)
  --tss FILE            TSS annotation BED file
  --genome FILE         mm10 genome FASTA
  --jaspar FILE         JASPAR motif database (.meme)
  --data-root DIR       Shared ATAC data root (passed to rgreat_analysis.R)

Tool/environment options:
  --halper-script FILE  Path to halper_map_peak_orthologs.sh
  --hal-bin DIR         Path to hal/bin directory
  --hal-pythonpath DIR  Path to halLiftover-postprocessing directory
  --hal-conda-env ENV   Conda env for HALPER step (default: hal)
  --conda-env ENV       Conda env for rGREAT steps (default: rgreat_env)
  --source-species S    Liftover source species (default: Human)
  --target-species T    Liftover target species (default: Mouse)

Pipeline control:
  --skip-halper         Skip Step 1 (liftover already done)
  --skip-pe             Skip Step 2 (PE classification already done)
  --skip-great          Skip Steps 3–4 (rGREAT already done)
  --skip-motif          Skip Step 5
  -h, --help            Show this message and exit
EOF
  exit 0
}

# ---------------------------------------------------------------------------
# Argument parsing — CLI flags override config.sh values.
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)            ROOT="$2";             shift 2 ;;
    --human)           HUMAN_PEAKS="$2";      shift 2 ;;
    --mouse)           MOUSE_PEAKS="$2";      shift 2 ;;
    --hal)             HAL_FILE="$2";         shift 2 ;;
    --tss)             TSS_FILE="$2";         shift 2 ;;
    --genome)          MM10_GENOME="$2";      shift 2 ;;
    --jaspar)          JASPAR_DB="$2";        shift 2 ;;
    --data-root)       DATA_ROOT="$2";        shift 2 ;;
    --halper-script)   HALPER_SCRIPT="$2";    shift 2 ;;
    --hal-bin)         HAL_BIN="$2";          shift 2 ;;
    --hal-pythonpath)  HAL_PYTHONPATH="$2";   shift 2 ;;
    --source-species)  SOURCE_SPECIES="$2";   shift 2 ;;
    --target-species)  TARGET_SPECIES="$2";   shift 2 ;;
    --hal-conda-env)   HAL_CONDA_ENV="$2";    shift 2 ;;
    --conda-env)       RGREAT_CONDA_ENV="$2"; shift 2 ;;
    --skip-halper)     SKIP_HALPER=true;      shift ;;
    --skip-pe)         SKIP_PE=true;          shift ;;
    --skip-great)      SKIP_GREAT=true;       shift ;;
    --skip-motif)      SKIP_MOTIF=true;       shift ;;
    -h|--help)         usage ;;
    *) die "Unknown option: $1. Use -h for help." ;;
  esac
done

# ---------------------------------------------------------------------------
# Export everything so sub-scripts inherit the full environment via
# sbatch --export=ALL.
# ---------------------------------------------------------------------------
export ROOT
export HUMAN_PEAKS MOUSE_PEAKS HAL_FILE TSS_FILE
export MM10_GENOME JASPAR_DB DATA_ROOT
export HALPER_SCRIPT HAL_BIN HAL_PYTHONPATH
export SOURCE_SPECIES TARGET_SPECIES
export HAL_CONDA_ENV RGREAT_CONDA_ENV

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
preflight() {
  log "Running pre-flight checks..."
  local missing=0

  check_file() {
    local label="$1" path="$2"
    if [[ ! -f "$path" ]]; then
      log "  MISSING [$label]: $path"
      missing=$((missing + 1))
    else
      log "  OK      [$label]: $path"
    fi
  }

  if ! $SKIP_HALPER; then
    check_file "human peaks"   "$HUMAN_PEAKS"
    check_file "mouse peaks"   "$MOUSE_PEAKS"
    check_file "HAL file"      "$HAL_FILE"
    check_file "HALPER script" "$HALPER_SCRIPT"
  fi

  if ! $SKIP_PE; then
    check_file "TSS annotation" "$TSS_FILE"
  fi

  if ! $SKIP_GREAT; then
    if [[ -z "$DATA_ROOT" ]]; then
      log "  MISSING [data-root]: required for rGREAT — pass --data-root or set in config.sh"
      missing=$((missing + 1))
    else
      log "  OK      [data-root]: $DATA_ROOT"
    fi
  fi

  if ! $SKIP_MOTIF; then
    check_file "mm10 genome" "$MM10_GENOME"
    check_file "JASPAR DB"   "$JASPAR_DB"
  fi

  [[ $missing -gt 0 ]] && die "$missing required input(s) missing. Correct the paths above and rerun."
  log "Pre-flight checks passed."
}

# ---------------------------------------------------------------------------
# submit_job <script_path> [prev_job_id]
#
# Submits a script to SLURM and returns its job ID.
# If prev_job_id is given, adds --dependency=afterok so this job only
# starts if the previous one exited with code 0.
# --export=ALL passes the full current environment to the job.
# --chdir ensures relative log paths in each SBATCH header resolve
# to the repo root, not the spool directory.
# ---------------------------------------------------------------------------
submit_job() {
  local script="$1"
  local prev_job="${2:-}"
  local dep_flag=""

  [[ -n "$prev_job" ]] && dep_flag="--dependency=afterok:$prev_job"

  sbatch --parsable \
    --export=ALL \
    --chdir="$ROOT" \
    $dep_flag \
    "$script"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
SCRIPTS_DIR="$ROOT/scripts"
LOG_DIR="$ROOT/logs"
mkdir -p "$LOG_DIR"

log "======================================================"
log "  TRACE Pipeline — $(date)"
log "  Project root : $ROOT"
log "  Log directory: $LOG_DIR"
log "======================================================"

preflight

echo ""
log "Submitting jobs..."
LAST_JOB=""

if $SKIP_HALPER; then
  log "Skipping Step 1 (--skip-halper)"
else
  LAST_JOB=$(submit_job "$SCRIPTS_DIR/run_halper_mapping.sh" "$LAST_JOB")
  log "Submitted Step 1 — HALPER liftover       [job $LAST_JOB]"
fi

if $SKIP_PE; then
  log "Skipping Step 2 (--skip-pe)"
else
  LAST_JOB=$(submit_job "$SCRIPTS_DIR/run_pe_classification.sh" "$LAST_JOB")
  log "Submitted Step 2 — PE classification     [job $LAST_JOB]"
fi

if $SKIP_GREAT; then
  log "Skipping Steps 3–4 (--skip-great)"
else
  LAST_JOB=$(submit_job "$SCRIPTS_DIR/run_rgreat.sh" "$LAST_JOB")
  log "Submitted Step 3 — rGREAT enrichment     [job $LAST_JOB]"
  LAST_JOB=$(submit_job "$SCRIPTS_DIR/run_plots.sh" "$LAST_JOB")
  log "Submitted Step 4 — rGREAT plots          [job $LAST_JOB]"
fi

if $SKIP_MOTIF; then
  log "Skipping Step 5 (--skip-motif)"
else
  LAST_JOB=$(submit_job "$SCRIPTS_DIR/run_motif_analysis.sh" "$LAST_JOB")
  log "Submitted Step 5 — MEME-ChIP motifs      [job $LAST_JOB]"
fi

echo ""
log "All jobs submitted. Monitor progress with:"
log "  squeue -u \$USER"
log "  sacct -u \$USER --format=JobID,JobName,State,ExitCode,Elapsed -X"
log ""
log "Logs will appear in: $LOG_DIR/"
log "======================================================"