#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ape)
  library(phytools)
})

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Usage: root_tree.R <input_tree> <output_tree> [bootstrap_cutoff]", call. = FALSE)
}

input_tree <- args[1]
output_tree <- args[2]
bootstrap_cutoff <- ifelse(length(args) >= 3, as.numeric(args[3]), 50)

tree <- read.tree(input_tree)

midpoint_tree <- midpoint.root(tree)
midpoint_tree <- drop.tip(midpoint_tree, 'Reference')
midpoint_tree <- ladderize(midpoint_tree, right = FALSE)

# Collapse branches with bootstrap support below cutoff
if (!is.null(midpoint_tree$node.label)) {
  bs <- suppressWarnings(as.numeric(midpoint_tree$node.label))

  if (any(!is.na(bs))) {
    internal_nodes <- (Ntip(midpoint_tree) + 1):(Ntip(midpoint_tree) + midpoint_tree$Nnode)
    bad_nodes <- internal_nodes[!is.na(bs) & bs < bootstrap_cutoff]
    bad_edges <- match(bad_nodes, midpoint_tree$edge[, 2])
    bad_edges <- bad_edges[!is.na(bad_edges)]

    if (length(bad_edges) > 0) {
      midpoint_tree$edge.length[bad_edges] <- 0
      midpoint_tree <- di2multi(midpoint_tree, tol = 0)
    }
  }
}

write.tree(midpoint_tree, file = output_tree)
