#!/usr/bin/env python3
import os
import sys
import pandas as pd
import numpy as np
import argparse
import logging


def bacterial_linkage_corge(species: str, cluster_id: str, snp_dists: str, snp_report: str, output: str):
    """
    Generate a summary bacterial linkage table with potential strong and intermediate linkages.
    """

    # -----------------------------
    # Helper: format linkages
    # -----------------------------
    def format_linkages(df, threshold, max_distance, include_threshold=False):
        def linkages(distances):
            linked = [
                (sample, distances[sample])
                for sample in distances.index
                if (
                    ((distances[sample] > threshold) if not include_threshold else (distances[sample] >= threshold))
                    and distances[sample] <= max_distance
                    and sample != distances.name
                )
            ]

            if not linked:
                return 'None'

            linked_sorted = sorted(linked, key=lambda x: x[1])
            return ', '.join(f"{s} ({int(d)})" for s, d in linked_sorted)

        return df.apply(linkages, axis=1)

    # -----------------------------
    # Load distance matrix
    # -----------------------------
    if not os.path.exists(snp_dists):
        logging.error(f"Error: Distance file not found - {snp_dists}")
        sys.exit(1)

    try:
        matrix_df = pd.read_csv(snp_dists, sep='\t', index_col=0).astype(float)
    except Exception as e:
        logging.error(f"Error reading distance file {snp_dists}: {e}")
        sys.exit(1)
        
    # -----------------------------
    # Remove Reference from distance matrix
    # -----------------------------
    if "Reference" in matrix_df.index or "Reference" in matrix_df.columns:
        matrix_df = matrix_df.drop(index="Reference", columns="Reference", errors="ignore")

    # Replace diagonal with inf
    np.fill_diagonal(matrix_df.values, float('inf'))

    # Minimum distance per sample
    min_dist = matrix_df.min(axis=1)

    # -----------------------------
    # Load SNP report
    # -----------------------------
    if not os.path.exists(snp_report):
        logging.error(f"Error: SNP report not found - {snp_report}")
        sys.exit(1)

    try:
        snp_df = pd.read_csv(snp_report, sep='\t')
    except Exception as e:
        logging.error(f"Error reading SNP report {snp_report}: {e}")
        sys.exit(1)

    if 'ID' not in snp_df.columns or 'LENGTH' not in snp_df.columns or 'ALIGNED' not in snp_df.columns :
        logging.error("SNP report must contain columns: 'ID', 'LENGTH', 'ALIGNED'")
        sys.exit(1)

    snp_df = snp_df.rename(columns={'ID': 'sample'})
    snp_df = snp_df[['sample', 'LENGTH', 'ALIGNED']]
    snp_df = snp_df[snp_df["sample"] != "Reference"]

    # Create ref_genome_fraction as a fraction of the reference genome aligned
    snp_df['ref_genome_fraction'] = snp_df['ALIGNED'] / snp_df['LENGTH']
    
    # -----------------------------
    # Completeness logic
    # -----------------------------
    def completeness_qc(ref_genome_fraction):
        if pd.isna(ref_genome_fraction):
            return 'FAIL'
        if ref_genome_fraction >= 0.95:
            return 'PASS'
        elif ref_genome_fraction >= 0.90:
            return 'WARN'
        else:
            return 'FAIL'

    snp_df['ref_alignment_qc'] = snp_df['ref_genome_fraction'].apply(completeness_qc)

    # -----------------------------
    # Compute linkages
    # -----------------------------
    strong_linkages = format_linkages(matrix_df, 0, 10, include_threshold=True)
    intermediate_linkages = format_linkages(matrix_df, 10, 40)
    lineage_level = format_linkages(matrix_df, 40, 150)

    # -----------------------------
    # Build results table
    # -----------------------------
    result_df = pd.DataFrame({
        'sample': matrix_df.index,
        'species': species,
        'cluster_id': cluster_id,
        'ref_genome_fraction': matrix_df.index.map(snp_df.set_index('sample')['ref_genome_fraction']),
        'ref_alignment_qc': matrix_df.index.map(snp_df.set_index('sample')['ref_alignment_qc']),
        'min_dist': min_dist,
        'strong_linkages': strong_linkages,
        'intermediate_linkages': intermediate_linkages,
        'lineage_level': lineage_level
    })

    # Fill missing safely
    for col in ['strong_linkages', 'intermediate_linkages', 'lineage_level']:
        result_df[col] = result_df[col].fillna('None')

    result_df['ref_genome_fraction'] = result_df['ref_genome_fraction'].astype(float)
    result_df['min_dist'] = result_df['min_dist'].astype(int)

    # -----------------------------
    # Save to CSV
    # -----------------------------
    try:
        result_df.to_csv(output, index=False)
        logging.info(f"✅ Potential linkage table saved: {output}")
    except Exception as e:
        logging.error(f"❌ Failed to write output file {output}: {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(
        description="Generate linkage tables based on core genome distances."
    )
    parser.add_argument("--species", required=True)
    parser.add_argument("--cluster-id", required=True)
    parser.add_argument("--snp-dists", required=True)
    parser.add_argument("--snp-report", required=True)
    parser.add_argument("--output", required=True)

    args = parser.parse_args()

    logging.basicConfig(
        format='[%(asctime)s] %(levelname)s: %(message)s',
        level=logging.INFO
    )

    bacterial_linkage_corge(
        args.species,
        args.cluster_id,
        args.snp_dists,
        args.snp_report,
        args.output
    )


if __name__ == "__main__":
    main()
