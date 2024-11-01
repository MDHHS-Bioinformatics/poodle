#!/usr/bin/env Rscript

# Read in command line arguments
args <- commandArgs(trailingOnly=TRUE)
panaroo_rtab_path <- args[1]         # Input file path (rtab file)
output_file <- args[2]               # Output file path (profile)

# Read the input file using base R
# Assuming the file is a tab-delimited file, we use `read.table`
pangenome_tab <- read.table(panaroo_rtab_path, header=TRUE, sep="\t", row.names=1,
                check.names = FALSE)

# Custom Hamming distance function using base R's `dist`
hamming_dist <- function(x) {
  dist(x, method = "manhattan")  # Manhattan distance is equivalent to Hamming distance for binary data
}

# Calculate the Hamming distance for the gene-presence-absence table
genes_dist <- hamming_dist(t(pangenome_tab))

# Convert the distance object to a matrix
genes_matrix <- as.matrix(genes_dist)

# Write the matrix to a file
write.table(genes_matrix, file=output_file, sep="\t", col.names=NA, quote=FALSE)
