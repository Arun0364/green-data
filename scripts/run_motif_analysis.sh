#!/usr/bin/bash
# Submit from the repo root so relative log paths resolve correctly:
#   sbatch run_motif_analysis.sh
#
# Override external resource paths at submit time if needed, e.g.:
#   MM10_GENOME=/path/to/mm10.fa JASPAR_DB=/path/to/db.meme sbatch run_motif_analysis.sh

#SBATCH -J motif_analysis     # Job name
#SBATCH -p RM-shared          # Partition
#SBATCH -N 1                  # Number of nodes
#SBATCH --cpus-per-task=16     # Number of tasks (CPUs)
#SBATCH -t 24:00:00           # Walltime (hh:mm:ss)
#SBATCH --mem=30G             # Memory
#SBATCH -o Motif_analysis/logs/task5_motif_%j.out
#SBATCH -e Motif_analysis/logs/task5_motif_%j.err

set -euo pipefail

eval "$(conda shell.bash hook)" 2>/dev/null || true
module purge
module load bedtools
module load MEME-suite/5.4.1

# Derive the repo root from the script's own location so the script works
# for any user without modification.
ROOT="${ROOT:-${SLURM_SUBMIT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}"

PE_OUT="$ROOT/PE_classification/outputs"
ROWCOUNT="$PE_OUT/rowcount"
UNIQUE="$PE_OUT/unique"

OUT="$ROOT/Motif_analysis/outputs"
BEDS="$OUT/beds"
FASTAS="$OUT/fastas"

# External resources: honour env-var overrides, fall back to conventional
# locations inside the repo root.
MM10_GENOME="${MM10_GENOME:-$ROOT/mm10.fa}"
JASPAR_DB="${JASPAR_DB:-$ROOT/motif_dbs/JASPAR2026_vertebrates_combined.meme}"
WINDOW=100

mkdir -p "$BEDS" "$FASTAS" "$OUT/logs" "$ROOT/Motif_analysis/logs"

echo "Performing Motif Analysis"
echo "Root:       $ROOT"
echo "Output:     $OUT"
echo "Genome:     $MM10_GENOME"
echo "JASPAR:     $JASPAR_DB"
echo "Window:     ±${WINDOW}bp"
echo ""

if [[ ! -f "$MM10_GENOME" ]]; then
  echo "ERROR: mm10 genome not found at $MM10_GENOME"; exit 1
fi
if [[ ! -f "$JASPAR_DB" ]]; then
  echo "ERROR: JASPAR DB not found at $JASPAR_DB"; exit 1
fi

echo "[Step 1] Generating mouse-native BED files..."

bedtools intersect -v \
  -a "$ROWCOUNT/mouse_native.sorted.bed" \
  -b "$ROWCOUNT/mouse_promoter_pm2kb.merged.bed" \
  | cut -f1-3 | sort -k1,1 -k2,2n | uniq \
  > "$BEDS/mouse_native_enhancer.bed"

bedtools intersect -u \
  -a "$ROWCOUNT/mouse_native.sorted.bed" \
  -b "$ROWCOUNT/mouse_promoter_pm2kb.merged.bed" \
  | cut -f1-3 | sort -k1,1 -k2,2n | uniq \
  > "$BEDS/mouse_native_promoter.bed"

cat "$UNIQUE/shared_enhancer.bed" "$UNIQUE/human_specific_enhancer.bed" \
  | sort -k1,1 -k2,2n | uniq \
  > "$BEDS/human_all_enhancer.bed"

cat "$UNIQUE/shared_promoter.bed" "$UNIQUE/human_specific_promoter.bed" \
  | sort -k1,1 -k2,2n | uniq \
  > "$BEDS/human_all_promoter.bed"

cp "$UNIQUE/shared_enhancer.bed"          "$BEDS/shared_enhancer.bed"
cp "$UNIQUE/human_specific_enhancer.bed"  "$BEDS/human_specific_enhancer.bed"
cp "$UNIQUE/mouse_specific_enhancer.bed"  "$BEDS/mouse_specific_enhancer.bed"

echo "[Step 1] Region counts:"
for f in "$BEDS"/*.bed; do
  printf "  %-35s %d regions\n" "$(basename "$f")" "$(wc -l < "$f")"
done
echo ""

echo "[Step 2] Resizing peaks to $(( WINDOW * 2 ))bp windows..."

resize_bed() {
  local in_bed="$1"
  local out_bed="$2"
  awk -v w="$WINDOW" 'BEGIN{OFS="\t"} {
    mid = int(($2 + $3) / 2)
    s = mid - w
    if (s < 0) s = 0
    print $1, s, mid + w
  }' "$in_bed" | sort -k1,1 -k2,2n | uniq > "$out_bed"
}

declare -A PEAK_SETS
PEAK_SETS["human_enhancer"]="$BEDS/human_all_enhancer.bed"
PEAK_SETS["mouse_enhancer"]="$BEDS/mouse_native_enhancer.bed"
PEAK_SETS["human_promoter"]="$BEDS/human_all_promoter.bed"
PEAK_SETS["mouse_promoter"]="$BEDS/mouse_native_promoter.bed"
PEAK_SETS["shared_enhancer"]="$BEDS/shared_enhancer.bed"
PEAK_SETS["human_specific_enhancer"]="$BEDS/human_specific_enhancer.bed"
PEAK_SETS["mouse_specific_enhancer"]="$BEDS/mouse_specific_enhancer.bed"

for name in "${!PEAK_SETS[@]}"; do
  resize_bed "${PEAK_SETS[$name]}" "$BEDS/${name}.resized.bed"
  echo "  $name: $(wc -l < "$BEDS/${name}.resized.bed") windows"
done
echo ""

echo "[Step 3] Extracting FASTA sequences from mm10..."

for name in "${!PEAK_SETS[@]}"; do
  bedtools getfasta \
    -fi "$MM10_GENOME" \
    -bed "$BEDS/${name}.resized.bed" \
    -fo "$FASTAS/${name}.fa"
  echo "  $name: $(grep -c '^>' "$FASTAS/${name}.fa") sequences"
done
echo ""

echo "[Step 4] Running MEME-ChIP (this will take a while)..."

run_meme_chip() {
  local name="$1"
  local fasta="$FASTAS/${name}.fa"
  local outdir="$OUT/meme_chip_${name}"
  local logfile="$OUT/logs/${name}.log"

  echo "  [$name] Starting..."
  export OMPI_MCA_rmaps_base_oversubscribe=1
  meme-chip \
    -oc "$outdir" \
    -maxw 20 \
    -meme-nmotifs 10 \
    -meme-p 4 \
    -db "$JASPAR_DB" \
    "$fasta" \
    > "$logfile" 2>&1
  echo "  [$name] Done. Results: $outdir"
}

for name in "${!PEAK_SETS[@]}"; do
  run_meme_chip "$name"
done

echo ""
echo "[Step 5] Top motif hits per set:"
for name in "${!PEAK_SETS[@]}"; do
  summary="$OUT/meme_chip_${name}/summary.tsv"
  if [[ -f "$summary" ]]; then
    echo "  === $name ==="
    head -4 "$summary"
    echo ""
  fi
done

echo "===== All done ====="
echo "Results in: $OUT"
echo "Open meme_chip_<name>/meme-chip.html in a browser for full results."