process QUARTO_NEITHER {
  tag "${meta.species}_${meta.cluster_id}"
  label 'process_medium'

  errorStrategy 'ignore'

  container 'quay.io/mdhhs_bioinformatics/quarto-wgs-reporting@sha256:2a3c9d9a87796ff612cce94e7638d906a04aec850ca0358446a3d5415526b326'
  // 'quay.io/mdhhs_bioinformatics/quarto-wgs-reporting:1.0.0'

  containerOptions(
    ['singularity', 'apptainer'].contains(workflow.containerEngine)
      ? '--no-home --env QUARTO_PRINT_STACK=true'
      : '--user $(id -u):$(id -g) -e QUARTO_PRINT_STACK=true'
  )
  
  stageInMode = 'copy'
  afterScript = 'rm -rf tmp'

  input:
  tuple val(meta), path(linkages), path(snptree), path(snpmatrix),
        path(pan_summary), path(pan_roary), path(pan_rtab), path(pan_genedists)
  path(yaml)
  path(qmd)
  path(logo)

  output:
  tuple val(meta), path("${meta.species}_${meta.cluster_id}.html"), emit: html
  path "versions.yml", emit: versions

  script:
  def prefix = "${meta.species}_${meta.cluster_id}"
  cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
  species = task.ext.prefix ?: "${meta.species}"
  """
  mkdir -p .quarto-cache .quarto-data .deno-cache tmp
  chmod -R u+rwX .quarto-cache .quarto-data .deno-cache tmp

  export XDG_CACHE_HOME="\$PWD/.quarto-cache"
  export XDG_DATA_HOME="\$PWD/.quarto-data"
  export XDG_RUNTIME_DIR="\$PWD/tmp"
  export DENO_DIR="\$PWD/.deno-cache"
  export QUARTO_PRINT_STACK=true

  cp -n ${linkages} ${snptree} ${snpmatrix} ${pan_summary} ${pan_roary} ${pan_rtab} ${pan_genedists} ${logo} .
  
  quarto render $qmd --execute-params $yaml --output "${prefix}.html"

  cat <<-END_VERSIONS > versions.yml
  "${task.process}":
      quarto: \$(quarto --version)
  END_VERSIONS
  """
}
