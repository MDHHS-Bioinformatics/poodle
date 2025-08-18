process QUARTO_GUB_ONLY {
  tag "${meta.species}_${meta.cluster_id}"
  label 'process_medium'
  errorStrategy 'ignore'
  container "r-quarto-phylo.sif"
  containerOptions = '--no-home --env USERID=$UID,XDG_CACHE_HOME=tmp/quarto_cache_home,XDG_DATA_HOME=tmp/quarto_data_home,QUARTO_PRINT_STACK=true'
  stageInMode = 'copy'
  afterScript = 'rm -rf tmp'

  input:
  tuple val(meta), path(ref_eval), path(snptree), path(snpmatrix),
        path(pan_summary), path(pan_roary), path(pan_rtab), path(pan_genedists),
        path(gubtree), path(gubmatrix)
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
  cp -n ${ref_eval} ${snptree} ${snpmatrix} ${pan_summary} ${pan_roary} ${pan_rtab} ${pan_genedists} \\
        ${gubtree} ${gubmatrix} ${logo} .
  quarto render $qmd --execute-params $yaml --output "${prefix}.html"
  cat <<-END_VERSIONS > versions.yml
  "${task.process}":
      quarto: \$(quarto --version)
  END_VERSIONS
  """
}
