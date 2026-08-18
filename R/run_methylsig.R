#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) stop("Usage: run_methylsig.R <config.tsv> <output.tsv>")
suppressPackageStartupMessages({
  library(bsseq)
  library(methylSig)
  library(GenomicRanges)
})
get_config <- function(path, key) {
  x <- read.delim(path, header = FALSE, comment.char = "#", stringsAsFactors = FALSE)
  value <- x[x$V1 == key, 2]
  if (length(value) != 1) stop("Missing config key: ", key)
  value
}
config <- args[[1]]
outfile <- args[[2]]
position <- read.delim(get_config(config, "POSITION_FILE"), check.names = FALSE)
coverage <- read.delim(get_config(config, "COVERAGE_FILE"), check.names = FALSE)
methylation <- read.delim(get_config(config, "METHYL_RATIO_FILE"), check.names = FALSE)
phenotype <- read.delim(get_config(config, "PHENOTYPE_FILE"), row.names = 1, check.names = FALSE)
samples <- rownames(phenotype)
coverage <- as.matrix(coverage[, samples, drop = FALSE])
methylation <- as.matrix(methylation[, samples, drop = FALSE])
gr <- GRanges(seqnames = position$seqnames, ranges = IRanges(start = position$starts + 1, width = as.integer(get_config(config, "REGION_WIDTH"))))
bs <- BSseq(Cov = coverage, M = methylation, gr = gr)
colData(bs) <- S4Vectors::DataFrame(phenotype)
group_column <- get_config(config, "GROUP_COLUMN")
case_label <- get_config(config, "CASE_LABEL")
control_label <- get_config(config, "CONTROL_LABEL")
min_coverage <- as.integer(get_config(config, "MIN_COVERAGE"))
filtered <- filter_loci_by_group_coverage(bs, group_column = group_column, c(case_label, control_label), min_count = min_coverage)
result <- diff_methylsig(filtered, group_column = group_column, comparison_groups = c(case = case_label, control = control_label), disp_groups = c(case = TRUE, control = TRUE), local_window_size = 0, t_approx = FALSE)
output <- cbind(position = paste0(seqnames(result), ":", start(result) - 1, ":", end(result)), as.data.frame(mcols(result)))
write.table(output, outfile, sep = "\t", quote = FALSE, row.names = FALSE)
