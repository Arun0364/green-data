# =============================================================================
# config.sh — TRACE Pipeline User Configuration
# =============================================================================
# Fill in the paths below for your Bridges-2 environment.
#
# Usage — two options:
#
#   Option 1: Source before running (values persist in your shell session):
#     source config.sh
#     bash scripts/TRACE_pipeline.sh
#
#   Option 2: Let the pipeline auto-source it (place at repo root):
#     bash scripts/TRACE_pipeline.sh
#     (TRACE_pipeline.sh checks for config.sh at the repo root automatically)
#
# Any value set here can still be overridden by a CLI flag, e.g.:
#     bash scripts/TRACE_pipeline.sh --genome /other/path/mm10.fa
#
# Replace all <user> placeholders with your Bridges-2 username.
# Lines starting with # are comments — remove the # to activate a setting.
# =============================================================================

# ── Project root ──────────────────────────────────────────────────────────────
# Leave commented out — TRACE_pipeline.sh detects this automatically.
# Uncomment only if auto-detection fails on your cluster.
# export ROOT="/ocean/projects/bio230007p/<user>/liver-ATAC-OCR"

# ── Input ATAC-seq peak files ─────────────────────────────────────────────────
export HUMAN_PEAKS="/ocean/projects/bio230007p/<user>/data/human_liver.narrowPeak.gz"
export MOUSE_PEAKS="/ocean/projects/bio230007p/<user>/data/mouse_liver.narrowPeak.gz"

# ── HAL alignment file ────────────────────────────────────────────────────────
export HAL_FILE="/ocean/projects/bio230007p/<user>/data/10plusway-master.hal"

# ── TSS annotation (for PE classification) ───────────────────────────────────
# Default: PE_classification/input/gencode.vM15...bed inside the repo.
# Uncomment to use a custom path.
# export TSS_FILE="/ocean/projects/bio230007p/<user>/data/gencode.vM15.annotation.protTranscript.geneNames_TSSWithStrand_sorted.bed"

# ── Shared reference data (read-only, passed to rgreat_analysis.R) ───────────
# This is the root of the shared ATAC-seq data directory.
# rgreat_analysis.R reads human and mouse peak files from here.
export DATA_ROOT="/ocean/projects/bio230007p/ikaplow"

# ── Genome and motif database ─────────────────────────────────────────────────
export MM10_GENOME="/ocean/projects/bio230007p/<user>/data/mm10.fa"
export JASPAR_DB="/ocean/projects/bio230007p/<user>/data/motif_dbs/JASPAR2026_vertebrates_combined.meme"

# ── HAL / HALPER tool locations ───────────────────────────────────────────────
# These default to $HOME/repos/ which is the standard install location.
# Uncomment and adjust if you installed them elsewhere.
# export HALPER_SCRIPT="$HOME/repos/halLiftover-postprocessing/halper_map_peak_orthologs.sh"
# export HAL_BIN="$HOME/repos/hal/bin"
# export HAL_PYTHONPATH="$HOME/repos/halLiftover-postprocessing"

# ── Conda environments ────────────────────────────────────────────────────────
export HAL_CONDA_ENV="hal"        # Used for Step 1 (HALPER liftover)
export RGREAT_CONDA_ENV="rgreat_env"  # Used for Steps 3–4 (rGREAT + plots)

# ── Species ───────────────────────────────────────────────────────────────────
export SOURCE_SPECIES="Human"
export TARGET_SPECIES="Mouse"