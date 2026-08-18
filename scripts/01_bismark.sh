#!/usr/bin/env bash
set -euo pipefail

samples=$1
config=$2
outdir=$3
threads=$4

get_config() { awk -F '\t' -v key="$1" '$1 == key {print $2; exit}' "$config"; }
genome=$(get_config BISMARK_GENOME)
adapter=$(get_config ADAPTER)
min_length=$(get_config MIN_LENGTH)
min_overlap=$(get_config MIN_OVERLAP)
mkdir -p "$outdir/trimmed" "$outdir/bismark" "$outdir/qc" "$outdir/logs"

while IFS=$'\t' read -r sample _ r1 r2; do
    [[ "$sample" == "sample" || -z "$sample" ]] && continue
    [[ -f "$r1" && -f "$r2" ]] || { echo "FASTQ files missing for $sample" >&2; exit 1; }
    cutadapt -j "$threads" -e 0.2 -a "$adapter" -A "$adapter" -m "$min_length" -O "$min_overlap" \
        -o "$outdir/trimmed/${sample}_R1.fastq.gz" -p "$outdir/trimmed/${sample}_R2.fastq.gz" \
        "$r1" "$r2" > "$outdir/logs/${sample}.cutadapt.log" 2>&1
    bismark --genome "$genome" --bowtie2 --parallel "$threads" \
        -1 "$outdir/trimmed/${sample}_R1.fastq.gz" -2 "$outdir/trimmed/${sample}_R2.fastq.gz" \
        --output_dir "$outdir/bismark" > "$outdir/logs/${sample}.bismark.log" 2>&1
done < "$samples"

bismark2report --dir "$outdir/qc" || true
bismark2summary "$outdir/bismark"/*.bam > "$outdir/qc/bismark_summary.txt" 2>&1 || true
