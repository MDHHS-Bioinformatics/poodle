#!/usr/bin/env bash
set -euo pipefail

: "${NXF_APPTAINER_CACHEDIR:?Please set NXF_APPTAINER_CACHEDIR before running this script}"

CACHE="$NXF_APPTAINER_CACHEDIR"
export NXF_APPTAINER_CACHEDIR="$CACHE"
export APPTAINER_CACHEDIR="$CACHE/apptainer-oci-cache"

mkdir -p "$NXF_APPTAINER_CACHEDIR" "$APPTAINER_CACHEDIR"

apptainer cache clean --force || true

pull_image () {
    local uri="$1"
    local name="$2"
    local sif="${CACHE}/${name}.img"

    if [[ -s "$sif" ]]; then
        echo "Already exists: $sif"
    else
        echo "Pulling: $uri"
        apptainer pull --force --name "$sif" "$uri"
    fi
}

pull_image 'docker://quay.io/biocontainers/snp-sites@sha256:d19b090d52dc1d29b6f862e30cfc38f10fad8cb6954d76ef37298002e1a89213' \
'quay.io-biocontainers-snp-sites@sha256-d19b090d52dc1d29b6f862e30cfc38f10fad8cb6954d76ef37298002e1a89213'

pull_image 'docker://quay.io/biocontainers/gubbins@sha256:8e36a93ce43f63fe466617addd0490641edee0c3030c511166d8171622c8c90c' \
'quay.io-biocontainers-gubbins@sha256-8e36a93ce43f63fe466617addd0490641edee0c3030c511166d8171622c8c90c'

pull_image 'docker://quay.io/biocontainers/iqtree@sha256:604552032e25a7a8d30c8d2f6cbc72b576f2f8159b4d5a0bc17c28dfd9e55511' \
'quay.io-biocontainers-iqtree@sha256-604552032e25a7a8d30c8d2f6cbc72b576f2f8159b4d5a0bc17c28dfd9e55511'

pull_image 'docker://quay.io/biocontainers/mashtree@sha256:eb96b6f479f0dc4fd5e655c27ba2ce55e94e63ca36e52132e84f76c6de047cdd' \
'quay.io-biocontainers-mashtree@sha256-eb96b6f479f0dc4fd5e655c27ba2ce55e94e63ca36e52132e84f76c6de047cdd'

pull_image 'docker://quay.io/biocontainers/panaroo@sha256:575f3443970a0d882e8e253ae954cd43cbac799f9a941c7ebe324ab9b11060f9' \
'quay.io-biocontainers-panaroo@sha256-575f3443970a0d882e8e253ae954cd43cbac799f9a941c7ebe324ab9b11060f9'

pull_image 'docker://quay.io/mdhhs_bioinformatics/quarto-wgs-reporting@sha256:2a3c9d9a87796ff612cce94e7638d906a04aec850ca0358446a3d5415526b326' \
'quay.io-mdhhs_bioinformatics-quarto-wgs-reporting@sha256-2a3c9d9a87796ff612cce94e7638d906a04aec850ca0358446a3d5415526b326'

pull_image 'docker://quay.io/staphb/snippy@sha256:011bb8ece52183719d2a188ff18f056a2e43367abf32a99f334da10736e0b79c' \
'quay.io-staphb-snippy@sha256-011bb8ece52183719d2a188ff18f056a2e43367abf32a99f334da10736e0b79c'

pull_image 'docker://quay.io/biocontainers/snp-dists@sha256:d6204b4fba8508d9531a69ee705c36756c79d1f8dc85e129e0908c1eaf19d3ac' \
'quay.io-biocontainers-snp-dists@sha256-d6204b4fba8508d9531a69ee705c36756c79d1f8dc85e129e0908c1eaf19d3ac'

pull_image 'docker://quay.io/biocontainers/pandas@sha256:509adc4983db6c608fa516bea822c29bf34d5b3f039d331fc705fc27492a0987' \
'quay.io-biocontainers-pandas@sha256-509adc4983db6c608fa516bea822c29bf34d5b3f039d331fc705fc27492a0987'

pull_image 'docker://quay.io/biocontainers/multiqc@sha256:0fae3fc02ac26ac0ca18475bd363504d2d39db4ff4391c5899648b8490abceee' \
'quay.io-biocontainers-multiqc@sha256-0fae3fc02ac26ac0ca18475bd363504d2d39db4ff4391c5899648b8490abceee'

rm -rf "$NXF_APPTAINER_CACHEDIR/apptainer-oci-cache/"
