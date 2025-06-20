#!/usr/bin/env python

import os
import shutil
from pathlib import Path
import argparse


#rename the assemblies
def rename_assembly(path, prefix, renamed_dir):
    #copy the file using the prefix as the basename but the extension of whatever the path is
    new_name = f"{prefix}{Path(path).suffix}"
    #create the new file in the renamed_dir directory
    new_path = renamed_dir / new_name
    shutil.copy(path, new_path)
    print(f"Renamed assembly {path} to {new_path}")

#rename the gff files
def rename_gff(path, prefix, renamed_dir):
    # Determine the new file name
    new_name = f"{prefix}.gff"
    old_base_name = Path(path).name
    new_path = renamed_dir / new_name
    shutil.copy(path, new_path)
    print(f"Renamed gff {path} to {new_path}")


def main():
    #set up the parser
    parser = argparse.ArgumentParser(description="Rename the necessary files")
    parser.add_argument('--prefix', type=str, required=True, help="Sample name to use as the prefix for the renamed files")
    parser.add_argument('--assembly', type=str, required=False, help="Assembly file to rename")
    parser.add_argument('--gff', type=str, required=False, help="GFF file to rename")
    args = parser.parse_args()

    #make a directory called renamed_files if it doesn't exist
    renamed_dir = Path.cwd() / "renamed_files"
    renamed_dir.mkdir(exist_ok=True)

    # Rename the assembly file if provided
    if args.assembly:
        if not os.path.exists(args.assembly):
            print(f"Error: Assembly file {args.assembly} does not exist.")
            return
        rename_assembly(args.assembly, args.prefix, renamed_dir)

    # Rename the gff file if provided
    if args.gff:
        if not os.path.exists(args.gff):
            print(f"Error: GFF file {args.gff} does not exist.")
            return
        rename_gff(args.gff, args.prefix, renamed_dir)

    if not args.assembly and not args.gff:
        print("No assembly or GFF file provided. Nothing to rename.")
    else:
        print("Renaming complete.")

if __name__ == "__main__":
    main()
