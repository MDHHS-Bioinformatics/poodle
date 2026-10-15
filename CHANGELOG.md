# MDHHS-Bioinformatics/poodle: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project follows [Semantic Versioning](https://semver.org/).

## v1.0.1 - [10/15/2026]

### Fixed
- Fixed pipeline failures when Snippy-core detects zero core SNPs.
- Added support for zero-SNP distance matrices and unresolved zero-length trees, allowing downstream linkage analysis and report generation.
- Fixed errors associated with constant-site calculations and midpoint rooting of zero-length trees.
- Added automatic report fallback when Gubbins results are unavailable, without requiring users to rerun the pipeline with different parameters.

### Improved
- Optimized Quarto reports for large clusters by using static heatmaps for clusters with more than 150 samples.
- Improved visualization of small and zero-length phylogenetic trees.
- Updated figure descriptions to distinguish interactive and static visualizations.
- Improved reporting of zero-core-SNP results and their interpretation.

## v1.0.0 - [06/25/2026]

### Added
- Initial release of PoODLE.
- Core workflow implemented.
- Documentation for usage, workflow, parameters, and outputs.
- Containerized execution using Docker/Singularity.
- Example samplesheet provided in `assets/`.

### Notes
- First stable release of the pipeline.

