#!/usr/bin/env python


"""Provide a command line tool to validate and transform tabular samplesheets."""


import argparse
import csv
import logging
import sys
from collections import Counter
from pathlib import Path

logger = logging.getLogger()


class RowChecker:
    """
    Define a service that can validate and transform each given row.

    Attributes:
        modified (list): A list of dicts, where each dict corresponds to a previously
            validated and transformed row. The order of rows is maintained.

    """

    VALID_FASTQ_FORMATS = (
        ".fq.gz",
        ".fastq.gz",
    )

    VALID_ASSEMBLY_FORMATS = (
        ".fasta", ".fasta.gz",
        ".fna", ".fna.gz",
        ".fa", ".fa.gz"
    )

    VALID_GFF_FORMATS = (
        ".gff",
        ".gff3",
    )

    def __init__(
        self,
        sample_col="sample",
        first_col="fastq_1",
        second_col="fastq_2",
        third_col="gff",  # GFF column
        fourth_col='assembly',  # Assembly column, # values will have to be NA or '' if not being used
        fifth_col='reference',
        sixth_col='cluster_id',
        seventh_col='species',
        single_col="single_end",
        **kwargs,
    ):
        """
        Initialize the row checker with the expected column names.

        Args:
            sample_col (str): The name of the column that contains the sample name
                (default "sample").
            first_col (str): The name of the column that contains the first (or only)
                FASTQ file path (default "fastq_1").
            second_col (str): The name of the column that contains the second (if any)
                FASTQ file path (default "fastq_2").
            third_col (str): The name of the column that contains the GFF file path (default "gff").
            fourth_col (str): The name of the column that contains the assembly file paths, if not being used, values must be NA or ''
            fifth_col (str): The name of the columnn that contains the reference file paths
            sixth_col (str): The name of the column that contains the cluster_id for the sample
            seventh_col (str): The name of the column that contains the species for the sample
            single_col (str): The name of the new column that will be inserted and
                records whether the sample contains single- or paired-end sequencing
                reads (default "single_end").

        """
        super().__init__(**kwargs)
        self._sample_col = sample_col
        self._first_col = first_col
        self._second_col = second_col
        self._third_col = third_col
        self._fourth_col = fourth_col
        self._fifth_col = fifth_col
        self._sixth_col = sixth_col
        self._seventh_col = seventh_col
        self._single_col = single_col
        self._seen = set()
        self.modified = []

    def validate_and_transform(self, row):
        """
        Perform all validations on the given row and insert the read pairing status.

        Args:
            row (dict): A mapping from column headers (keys) to elements of that row
                (values).

        """
        self._validate_sample(row)
        self._validate_fastq_and_assembly(row)
        self._validate_gff(row)  # Validate GFF
        self._validate_reference(row)
        self._validate_pair(row)
        self._seen.add((row[self._sample_col], row[self._first_col]))
        self.modified.append(row)

    def _validate_sample(self, row):
        """Assert that the sample name exists and convert spaces to underscores."""
        if len(row[self._sample_col]) <= 0:
            raise AssertionError("Sample input is required.")
        # Sanitize samples slightly.
        row[self._sample_col] = row[self._sample_col].replace(" ", "_")

    def _validate_fastq_and_assembly(self, row):
        """
        Validate that either fastq_1 and fastq_2 or the assembly column is filled correctly.

        - If fastq_1 and fastq_2 are empty, check if the assembly column ends with .fasta, .fna, or .fa (could be .gz compressed)
        - If fastq_1 or fastq_2 has data, validate its format.
        """
        fastq_1 = row[self._first_col]
        fastq_2 = row[self._second_col]

        if not fastq_1 and not fastq_2:
            if self._fourth_col: #verify that the assembly column exists
                assembly = row.get(self._fourth_col, "")
                if len(assembly) <= 0:
                    raise AssertionError(f"Sample {row[self._sample_col]}: Must have either FASTQ files or an assembly.")
                self._validate_assembly_format(assembly)
            else:
                raise AssertionError(f"Sample {row[self._sample_col]}: Must have either FASTQ files or an assembly.")
        else:
            if fastq_1:
                self._validate_fastq_format(fastq_1)
            if fastq_2:
                self._validate_fastq_format(fastq_2)

    def _validate_gff(self, row):
        """Assert that the GFF file has the correct format if it exists."""
        gff = row.get(self._third_col, "")
        if gff and not any(gff.endswith(extension) for extension in self.VALID_GFF_FORMATS):
            raise AssertionError(
                f"The GFF file has an unrecognized extension: {gff}\n"
                f"It should be one of: {', '.join(self.VALID_GFF_FORMATS)}"
            )
    def _validate_reference(self,row):
        """Assert that the Reference file has the correct format if it exists"""
        reference = row.get(self._fifth_col, "")
        if reference and not any(reference.endswith(extension) for extension in self.VALID_ASSEMBLY_FORMATS):
            raise AssertionError(
                f"The Reference file has an unrecognized extension: {reference}\n"
                f"It should be one of: {', '.join(self.VALID_ASSEMBLY_FORMATS)}"
            )

    def _validate_pair(self, row):
        """Assert that read pairs have the same file extension. Report pair status."""
        if row[self._first_col] and row[self._second_col]:
            row[self._single_col] = False
            first_col_suffix = Path(row[self._first_col]).suffixes[-2:]
            second_col_suffix = Path(row[self._second_col]).suffixes[-2:]
            if first_col_suffix != second_col_suffix:
                raise AssertionError("FASTQ pairs must have the same file extensions.")
        else:
            row[self._single_col] = True

    def _validate_fastq_format(self, filename):
        """Assert that a given filename has one of the expected FASTQ extensions."""
        if not any(filename.endswith(extension) for extension in self.VALID_FASTQ_FORMATS):
            raise AssertionError(
                f"The FASTQ file has an unrecognized extension: {filename}\n"
                f"It should be one of: {', '.join(self.VALID_FASTQ_FORMATS)}"
            )

    def _validate_assembly_format(self, filename):
        """Assert that a given filename has one of the expected assembly extensions."""
        if not any(filename.endswith(extension) for extension in self.VALID_ASSEMBLY_FORMATS):
            raise AssertionError(
                f"The assembly file has an unrecognized extension: {filename}\n"
                f"It should be one of: {', '.join(self.VALID_ASSEMBLY_FORMATS)}"
            )
    def check_if_nan(self,row):
        """Check if the row contains any NA values
        Only FastQ or Assembly columns are allowed to have these if either are missing
        """
        #possible variations
        nans = ['NaN','Nan','nan','NA','Na']
        if row in nans:
            return True
        else:
            return False

    def validate_unique_samples(self):
        """
        Assert that the combination of sample name and FASTQ filename is unique.

        In addition to the validation, also rename all samples to have a suffix of _T{n}, where n is the
        number of times the same sample exist, but with different FASTQ files, e.g., multiple runs per experiment.

        """
        if len(self._seen) != len(self.modified):
            raise AssertionError("The pair of sample name and FASTQ must be unique.")
        seen = Counter()
        for row in self.modified:
            sample = row[self._sample_col]
            seen[sample] += 1
            row[self._sample_col] = f"{sample}_T{seen[sample]}"


def read_head(handle, num_lines=10):
    """Read the specified number of lines from the current position in the file."""
    lines = []
    for idx, line in enumerate(handle):
        if idx == num_lines:
            break
        lines.append(line)
    return "".join(lines)


def sniff_format(handle):
    """
    Detect the tabular format.

    Args:
        handle (text file): A handle to a `text file`_ object. The read position is
        expected to be at the beginning (index 0).

    Returns:
        csv.Dialect: The detected tabular format.

    .. _text file:
        https://docs.python.org/3/glossary.html#term-text-file

    """
    peek = read_head(handle)
    handle.seek(0)
    sniffer = csv.Sniffer()
    if not sniffer.has_header(peek):
        logger.critical("The given sample sheet does not appear to contain a header.")
    #    sys.exit(1)
    dialect = sniffer.sniff(peek)
    return dialect


def check_samplesheet(file_in, file_out):
    """
    Check that the tabular samplesheet has the structure expected by the pipeline.

    Validate the general shape of the table, expected columns, and each row. Also add
    an additional column which records whether one or two FASTQ reads were found.

    Args:
        file_in (pathlib.Path): The given tabular samplesheet. The format can be either
            CSV, TSV, or any other format automatically recognized by ``csv.Sniffer``.
        file_out (pathlib.Path): Where the validated and transformed samplesheet should
            be created; always in CSV format.

    Example:
        This function checks that the samplesheet follows the following structure,
        see also the `viral recon samplesheet`_::

            sample,fastq_1,fastq_2,gff,assembly,cluster_id,species,reference
            SAMPLE_PE,SAMPLE_PE_RUN1_1.fastq.gz,SAMPLE_PE_RUN1_2.fastq.gz,SAMPLE_PE.gff,SAMPLE_PE.fna,cluster_name,Genus_species,reference.fasta
            SAMPLE_PE,SAMPLE_PE_RUN2_1.fastq.gz,SAMPLE_PE_RUN2_2.fastq.gz,SAMPLE_PE.gff,SAMPLE_PE.fna,cluster_name,Genus_species,reference.fasta
            SAMPLE_SE,SAMPLE_SE_RUN1_1.fastq.gz,,SAMPLE_SE.gff,SAMPLE_PE.fna,cluster_name,Genus_species,reference.fasta
            SAMPLE,,,SAMPLE.gff,SAMPLE.fna,cluster_name,Genus_species,reference.fasta

    .. _viral recon samplesheet:
        https://raw.githubusercontent.com/nf-core/test-datasets/viralrecon/samplesheet/samplesheet_test_illumina_amplicon.csv

    """
    required_columns = {"sample", "fastq_1", "fastq_2", "gff", "assembly", "reference", "cluster_id", "species"}  #
    # See https://docs.python.org/3.9/library/csv.html#id3 to read up on `newline=""`.
    with file_in.open(newline="") as in_handle:
        reader = csv.DictReader(in_handle, dialect=sniff_format(in_handle))
        # Validate the existence of the expected header columns.
        if not required_columns.issubset(reader.fieldnames):
            req_cols = ", ".join(required_columns)
            logger.critical(f"The sample sheet **must** contain these column headers: {req_cols}.")
            sys.exit(1)

        # Validate each row.
        checker = RowChecker()
        for i, row in enumerate(reader):
            try:
                checker.validate_and_transform(row)
            except AssertionError as error:
                logger.critical(f"{str(error)} On line {i + 2}.")
                sys.exit(1)
        #checker.validate_unique_samples()
    header = list(reader.fieldnames)
    header.insert(1, "single_end")
    # See https://docs.python.org/3.9/library/csv.html#id3 to read up on `newline=""`.
    with file_out.open(mode="w", newline="") as out_handle:
        writer = csv.DictWriter(out_handle, header, delimiter=",")
        writer.writeheader()
        for row in checker.modified:
            writer.writerow(row)


def parse_args(argv=None):
    """Define and immediately parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Validate and transform a tabular samplesheet.",
        epilog="Example: python check_samplesheet.py samplesheet.csv samplesheet.valid.csv",
    )
    parser.add_argument(
        "file_in",
        metavar="FILE_IN",
        type=Path,
        help="Tabular input samplesheet in CSV or TSV format.",
    )
    parser.add_argument(
        "file_out",
        metavar="FILE_OUT",
        type=Path,
        help="Transformed output samplesheet in CSV format.",
    )
    parser.add_argument(
        "-l",
        "--log-level",
        help="The desired log level (default WARNING).",
        choices=("CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG"),
        default="WARNING",
    )
    return parser.parse_args(argv)


def main(argv=None):
    """Coordinate argument parsing and program execution."""
    args = parse_args(argv)
    logging.basicConfig(level=args.log_level, format="[%(levelname)s] %(message)s")
    if not args.file_in.is_file():
        logger.error(f"The given input file {args.file_in} was not found!")
        sys.exit(2)
    args.file_out.parent.mkdir(parents=True, exist_ok=True)
    check_samplesheet(args.file_in, args.file_out)

if __name__ == "__main__":
    sys.exit(main())
