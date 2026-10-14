#!/usr/bin/env python3

import argparse
from pathlib import Path
import pandas as pd


def main():
    parser = argparse.ArgumentParser(
        description="Generate an unresolved zero-branch-length Newick tree."
    )
    parser.add_argument("--snp-report", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    report = pd.read_csv(args.snp_report, sep="\t")

    if "ID" not in report.columns:
        raise ValueError("Snippy report missing ID column")

    samples = report.loc[
        report["ID"].astype(str).str.lower() != "reference",
        "ID",
    ].dropna().astype(str).tolist()

    if len(samples) < 2:
        raise ValueError("At least two samples required")

    if len(samples) != len(set(samples)):
        raise ValueError("Duplicate sample IDs detected")

    def newick_name(name):
        return name

    tree = "(" + ",".join(
        f"{newick_name(sample)}:0.00000" for sample in samples
    ) + ");\n"

    Path(args.output).write_text(tree)


if __name__ == "__main__":
    main()
