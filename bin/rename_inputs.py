#!/usr/bin/env python3

import argparse
import shutil
import sys
from pathlib import Path
import gzip


def rename_assembly(path, prefix, renamed_dir):
    old_path = Path(path)
    new_name = f"{prefix}.fna"
    new_path = renamed_dir / new_name

    if str(old_path).endswith(".gz"):
        with gzip.open(old_path, "rt") as fin, open(new_path, "wt") as fout:
            shutil.copyfileobj(fin, fout)
    else:
        with open(old_path, "rt") as fin, open(new_path, "wt") as fout:
            shutil.copyfileobj(fin, fout)

    print(f"Renamed assembly {path} to {new_path}")
    return new_path

def rename_annotation(path, prefix, renamed_dir, annotation_format):
    old_path = Path(path)
    name = old_path.name.lower()

    if annotation_format in ["gff", "split_gff"]:
        if name.endswith(".gff.gz"):
            out_ext = ".gff"
        elif name.endswith(".gff3.gz"):
            out_ext = ".gff3"
        elif name.endswith(".gff"):
            out_ext = ".gff"
        elif name.endswith(".gff3"):
            out_ext = ".gff3"
        else:
            raise ValueError(f"Unsupported GFF annotation extension for file: {path}")

    elif annotation_format == "genbank":
        if name.endswith(".gbk.gz"):
            out_ext = ".gbk"
        elif name.endswith(".gb.gz"):
            out_ext = ".gb"
        elif name.endswith(".gbff.gz"):
            out_ext = ".gbff"
        elif name.endswith(".gbk"):
            out_ext = ".gbk"
        elif name.endswith(".gb"):
            out_ext = ".gb"
        elif name.endswith(".gbff"):
            out_ext = ".gbff"
        else:
            raise ValueError(f"Unsupported GenBank annotation extension for file: {path}")

    else:
        raise ValueError(
            f"Unsupported annotation_format '{annotation_format}'. "
            "Expected one of: gff, split_gff, genbank"
        )

    new_name = f"{prefix}{out_ext}"
    new_path = renamed_dir / new_name

    if name.endswith(".gz"):
        with gzip.open(old_path, "rt") as fin, open(new_path, "wt") as fout:
            shutil.copyfileobj(fin, fout)
    else:
        shutil.copy(old_path, new_path)

    print(f"Renamed annotation {path} to {new_path}")
    return new_path


def main():
    parser = argparse.ArgumentParser(description="Rename assembly and annotation files")
    parser.add_argument(
        "--prefix",
        type=str,
        required=True,
        help="Sample name to use as the prefix for the renamed files",
    )
    parser.add_argument(
        "--assembly",
        type=str,
        required=False,
        help="Assembly file to rename",
    )
    parser.add_argument(
        "--annotation",
        type=str,
        required=False,
        help="Annotation file to rename",
    )
    parser.add_argument(
        "--annotation_format",
        type=str,
        required=False,
        default="gff",
        choices=["gff", "split_gff", "genbank"],
        help="Annotation format: gff, split_gff, or genbank",
    )
    args = parser.parse_args()

    renamed_dir = Path.cwd() / "renamed_files"
    renamed_dir.mkdir(exist_ok=True)

    renamed_any = False

    if args.assembly:
        assembly_path = Path(args.assembly)
        if not assembly_path.exists():
            sys.exit(f"Error: Assembly file {args.assembly} does not exist.")
        rename_assembly(assembly_path, args.prefix, renamed_dir)
        renamed_any = True

    if args.annotation:
        annotation_path = Path(args.annotation)
        if not annotation_path.exists():
            sys.exit(f"Error: Annotation file {args.annotation} does not exist.")
        rename_annotation(annotation_path, args.prefix, renamed_dir, args.annotation_format)
        renamed_any = True

    if not renamed_any:
        print("No assembly or annotation file provided. Nothing to rename.")
    else:
        print("Renaming complete.")


if __name__ == "__main__":
    main()