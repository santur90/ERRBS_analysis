#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
config="$script_dir/config.tsv"
samples="$script_dir/samples.tsv"
dry_run=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --config) config=$2; shift 2;;
    --samples) samples=$2; shift 2;;
    --threads) cli_threads=$2; shift 2;;
    --dry-run) dry_run=true; shift;;
    -h|--help) echo "Usage: $0 [--config FILE] [--samples FILE] [--threads N] [--dry-run]"; exit 0;;
    *) echo "Unknown argument: $1" >&2; exit 1;;
  esac
done
get_config() { awk -F '\t' -v key="$1" '$1 == key {print $2; exit}' "$config"; }
threads=${cli_threads:-$(get_config THREADS)}
outdir=$(get_config OUTDIR)
run() { printf '+ '; printf '%q ' "$@"; printf '\n'; [[ "$dry_run" == true ]] || "$@"; }
mkdir -p "$script_dir/$outdir/logs"
mkdir -p "$script_dir/$outdir/dmr"
run bash "$script_dir/scripts/01_bismark.sh" "$samples" "$config" "$script_dir/$outdir" "$threads"
run bash "$script_dir/scripts/02_extract_methylation.sh" "$config" "$script_dir/$outdir" "$threads"
run Rscript "$script_dir/R/run_methylsig.R" "$config" "$script_dir/$outdir/dmr/differential_methylation.tsv"
echo "Pipeline complete: $script_dir/$outdir"
