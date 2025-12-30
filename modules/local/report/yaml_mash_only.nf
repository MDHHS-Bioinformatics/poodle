process YAML_MASH_ONLY {
  tag "${meta.species}_${meta.cluster_id}"
  label 'process_single'
  
  input:
  tuple val(meta), path(ref_eval), path(snptree), path(snpmatrix),
        path(pan_summary), path(pan_roary), path(pan_rtab), path(pan_genedists),
        path(mashtree), path(mashmatrix)
  
  output:
  tuple val(meta), path(ref_eval), path(snptree), path(snpmatrix),
        path(pan_summary), path(pan_roary), path(pan_rtab), path(pan_genedists),
        path(mashtree), path(mashmatrix), emit: files
  path("*.yaml"), emit: yaml
  
  script:
  def prefix = "${meta.species}_${meta.cluster_id}"
  cluster_id = task.ext.prefix ?: "${meta.cluster_id}"
  species = task.ext.prefix ?: "${meta.species}"
  """
  echo "cluster_id: ${meta.cluster_id}"                  >  ${prefix}.yaml
  echo "species: ${meta.species}"                        >> ${prefix}.yaml
  echo "ref_eval: \$(basename ${ref_eval})"              >> ${prefix}.yaml
  echo "snptree: \$(basename ${snptree})"                >> ${prefix}.yaml
  echo "snpmatrix: \$(basename ${snpmatrix})"            >> ${prefix}.yaml
  echo "pan_summary: \$(basename ${pan_summary})"        >> ${prefix}.yaml
  echo "pan_roary: \$(basename ${pan_roary})"            >> ${prefix}.yaml
  echo "pan_rtab: \$(basename ${pan_rtab})"              >> ${prefix}.yaml
  echo "pan_genedists: \$(basename ${pan_genedists})"    >> ${prefix}.yaml
  echo "mashtree: \$(basename ${mashtree})"              >> ${prefix}.yaml
  echo "mashmatrix: \$(basename ${mashmatrix})"          >> ${prefix}.yaml
  """
}
