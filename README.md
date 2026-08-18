# ERRBS_analysis

A reproducible ERRBS methylation workflow for adapter trimming, Bismark alignment, cytosine extraction, methylation summarization, and differential methylation analysis.

## Workflow

`FASTQ -> cutadapt -> Bismark -> methylation extraction -> methylation tables -> methylSig DMR analysis`

## Quick start

```bash
mamba env create -f environment.yml
mamba activate errbs
./run_errbs.sh --config config.tsv --samples samples.tsv --threads 8
```

Run `--dry-run` to inspect commands without processing data.

## Inputs

`samples.tsv` is tab-separated:

| sample | group | fastq_r1 | fastq_r2 |
|---|---|---|---|
| case_1 | case | data/case_1_R1.fastq.gz | data/case_1_R2.fastq.gz |
| control_1 | control | data/control_1_R1.fastq.gz | data/control_1_R2.fastq.gz |

The methylation analysis expects position, coverage, methylation-ratio, and phenotype tables. Their paths are configured in `config.tsv`.

## Design notes

The pipeline preserves Bismark reports and intermediate BAM files. Cytosine calls are summarized before statistical testing. Differential methylation is tested with methylSig after group-level coverage filtering. Genome assembly, CpG tile width, minimum coverage, and group labels must match the study design.

## Outputs

- `results/qc/`: Bismark reports and summaries
- `results/bismark/`: alignments and methylation extraction output
- `results/tables/`: position, coverage, and methylation-ratio tables
- `results/dmr/`: differential methylation results
- `results/logs/`: stage logs
