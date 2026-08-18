#!/usr/bin/env bash
set -euo pipefail

config=$1
outdir=$2
threads=$3
genome=$(awk -F '\t' '$1 == "BISMARK_GENOME" {print $2; exit}' "$config")
mkdir -p "$outdir/methylation" "$outdir/logs"

shopt -s nullglob
bams=("$outdir/bismark"/*_bismark_bt2_pe.bam)
[[ "${#bams[@]}" -gt 0 ]] || { echo "No paired-end Bismark BAM files found" >&2; exit 1; }
for bam in "${bams[@]}"; do
    bismark_methylation_extractor --gzip --bedGraph --cytosine_report \
        --genome_folder "$genome" --multicore "$threads" --buffer_size 10G \
        --output "$outdir/methylation" "$bam" > "$outdir/logs/$(basename "$bam").extract.log" 2>&1
done
