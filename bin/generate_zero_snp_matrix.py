#!/usr/bin/env python3

"""
Generate a zero-SNP distance matrix for clusters where snippy-core
reports no qualifying SNPs in the complete-site alignment.

The matrix is intended for downstream linkage analysis.
Run only for clusters explicitly classified as ZERO_CORE_SNPS.
"""

import argparse
import sys
from pathlib import Path

import pandas as pd


def generate_zero_snp_matrix(
    snp_report: Path,
    output: Path,
    min_alignment_fraction: float = 0.90,
):
    report = pd.read_csv(snp_report, sep="\t")

    required = {"ID", "LENGTH", "ALIGNED"}
    missing = required - set(report.columns)

    if missing:
        raise ValueError(
            f"Missing required columns in Snippy report: {missing}"
        )

    # Exclude the reference genome
    report = report.loc[
        report["ID"].str.lower() != "reference"
    ].copy()

    if len(report) < 2:
        raise ValueError(
            "At least two isolates are required to generate "
            "a zero-SNP distance matrix."
        )

    if report["ID"].isna().any() or report["ID"].duplicated().any():
        raise ValueError("Missing or duplicated sample IDs.")

    # Check alignment completeness
    report["LENGTH"] = pd.to_numeric(
        report["LENGTH"], errors="coerce"
    )
    report["ALIGNED"] = pd.to_numeric(
        report["ALIGNED"], errors="coerce"
    )

    if (
        report["LENGTH"].isna().any()
        or report["ALIGNED"].isna().any()
        or (report["LENGTH"] <= 0).any()
    ):
        raise ValueError("Invalid alignment statistics.")

    alignment_fraction = report["ALIGNED"] / report["LENGTH"]

    if (alignment_fraction < min_alignment_fraction).any():
        low_quality = report.loc[
            alignment_fraction < min_alignment_fraction, "ID"
        ].tolist()

        raise ValueError(
            "Insufficient alignment completeness for automatic "
            f"strong linkage assignment: {low_quality}"
        )

    samples = report["ID"].tolist()

    matrix = pd.DataFrame(
        0,
        index=samples,
        columns=samples,
        dtype=int,
    )

    output.parent.mkdir(parents=True, exist_ok=True)
    matrix.to_csv(output, sep="\t", index=True, index_label="Sample")

    print(
        f"Generated zero-SNP matrix for {len(samples)} isolates: "
        f"{output}",
        file=sys.stderr,
    )


def main():
    parser = argparse.ArgumentParser(
        description="Generate zero-SNP pairwise distance matrix."
    )

    parser.add_argument(
        "--snp-report",
        type=Path,
        required=True,
        help="Snippy-core summary TXT file.",
    )

    parser.add_argument(
        "--output",
        type=Path,
        required=True,
        help="Output TSV SNP distance matrix.",
    )

    parser.add_argument(
        "--min-alignment-fraction",
        type=float,
        default=0.90,
        help="Minimum aligned fraction (default: 0.90).",
    )

    args = parser.parse_args()

    if not 0 <= args.min_alignment_fraction <= 1:
        parser.error(
            "--min-alignment-fraction must be between 0 and 1."
        )

    generate_zero_snp_matrix(
        snp_report=args.snp_report,
        output=args.output,
        min_alignment_fraction=args.min_alignment_fraction,
    )


if __name__ == "__main__":
    main()
