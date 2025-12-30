#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(tibble)
})

# -----------------------------
# Parse command-line arguments (base R)
# -----------------------------
args <- commandArgs(trailingOnly = TRUE)

if (length(args) %% 2 != 0) {
  stop("Arguments must be provided as --key value pairs")
}

arg_list <- setNames(
  args[seq(2, length(args), by = 2)],
  sub("^--", "", args[seq(1, length(args), by = 2)])
)

required <- c("species", "cluster_id", "dist", "output")
missing <- setdiff(required, names(arg_list))
if (length(missing) > 0) {
  stop("Missing required arguments: ", paste(missing, collapse = ", "))
}

species    <- arg_list$species
cluster_id <- arg_list$cluster_id
dist_file  <- arg_list$dist
output_file <- arg_list$output

# -----------------------------
# Read distance matrix (TSV)
# -----------------------------
snp_df <- fread(dist_file, data.table = FALSE)

# First column = row names
row_names <- snp_df[[1]]
snp_matrix <- as.matrix(snp_df[, -1])
rownames(snp_matrix) <- row_names
colnames(snp_matrix) <- colnames(snp_df)[-1]

mode(snp_matrix) <- "numeric"

# -----------------------------
# Remove Reference row/column
# -----------------------------
if ("Reference" %in% rownames(snp_matrix)) {
  snp_matrix <- snp_matrix[rownames(snp_matrix) != "Reference", , drop = FALSE]
}
if ("Reference" %in% colnames(snp_matrix)) {
  snp_matrix <- snp_matrix[, colnames(snp_matrix) != "Reference", drop = FALSE]
}


# -----------------------------
# Computing minimum distance per sample
# -----------------------------
compute_min_dist <- function(snp_matrix) {
  apply(snp_matrix, 1, function(x) {
    x <- x[x > 0]              # remove self-distance
    if (length(x) == 0) NA_integer_ else as.integer(min(x))
  })
}

min_distances <- compute_min_dist(snp_matrix)

# -----------------------------
# Create linkage summary
# -----------------------------
create_linkage_summary <- function(snp_matrix) {

  specimen_ids <- rownames(snp_matrix)
  num_specimens <- length(specimen_ids)

  strong_links <- setNames(vector("list", num_specimens), specimen_ids)
  mid_links    <- setNames(vector("list", num_specimens), specimen_ids)

  # Traverse upper triangle only (symmetric de-duplication)
  for (i in seq_len(num_specimens - 1)) {
    for (j in (i + 1):num_specimens) {

      d <- snp_matrix[i, j]
      id_i <- specimen_ids[i]
      id_j <- specimen_ids[j]

      if (d <= 10) {
        strong_links[[id_i]] <- c(strong_links[[id_i]],
                                  paste0(id_j, " (", d, " SNPs)"))
        strong_links[[id_j]] <- c(strong_links[[id_j]],
                                  paste0(id_i, " (", d, " SNPs)"))
      } else if (d <= 40) {
        mid_links[[id_i]] <- c(mid_links[[id_i]],
                               paste0(id_j, " (", d, " SNPs)"))
        mid_links[[id_j]] <- c(mid_links[[id_j]],
                               paste0(id_i, " (", d, " SNPs)"))
      }
    }
  }

  tibble(
    sample_id = specimen_ids,
    strong_linkages = sapply(strong_links, function(x)
      if (length(x) == 0) "None" else paste(sort(x), collapse = ", ")),
    intermediate_linkages = sapply(mid_links, function(x)
      if (length(x) == 0) "None" else paste(sort(x), collapse = ", "))
  )
}

# -----------------------------
# Generate output table
# -----------------------------
linkage_summary <- create_linkage_summary(snp_matrix) %>%
  mutate(
    species = species,
    cluster_id = cluster_id,
    min_dist = min_distances[sample_id]
  ) %>%
  select(
    sample_id,
    species,
    cluster_id,
    min_dist,
    strong_linkages,
    intermediate_linkages
  )

# -----------------------------
# Write CSV
# -----------------------------
write.csv(linkage_summary, output_file, row.names = FALSE)
