
```
📁 <outdir>
├── 📁 <Species>
│       └── 📁 <cluster_id>
│           ├── 📁 snippy_run
│           │   ├── 📁 <sample>
│           │   │   ├── 📄 <sample>.aligned.fa
│           │   │   ├── 📄 <sample>.consensus.fa
│           │   │   ├── 📄 <sample>.consensus.subs.fa
│           │   │   ├── 📄 <sample>.csv
│           │   │   ├── 📄 <sample>.log
│           │   │   ├── 📄 <sample>.tab
│           │   │   ├── 📄 <sample>.txt
│           │   │   ├── 📄 <sample>.vcf
│           ├── 📁 snippy_core
│           │   ├── 📄 <Species>_<cluster_id>_clean.full.aln
│           │   ├── 📄 <Species>_<cluster_id>_dist.tsv
│           │   ├── 📄 <Species>_<cluster_id>.aln
│           │   ├── 📄 <Species>_<cluster_id>.full.aln
│           │   ├── 📄 <Species>_<cluster_id>.iqtree
│           │   ├── 📄 <Species>_<cluster_id>.nwk
│           │   ├── 📄 <Species>_<cluster_id>.tab
│           │   ├── 📄 <Species>_<cluster_id>.tre
│           │   ├── 📄 <Species>_<cluster_id>.txt
│           │   └── 📄 <Species>_<cluster_id>.vcf
│           ├── 📁 gubbins
│           │   ├── 📄 <Species>_<cluster_id>_gubbins_dist.tsv
│           │   ├── 📄 <Species>_<cluster_id>_gubbins.iqtree
│           │   ├── 📄 <Species>_<cluster_id>_gubbins.nwk
│           │   ├── 📄 <Species>_<cluster_id>_gubbins.iqtree
│           │   ├── 📄 <Species>_<cluster_id>_gubbins.tre
│           │   ├── 📄 <Species>_<cluster_id>_snp-sites.fna
│           │   ├── 📄 <Species>_<cluster_id>.branch_base_reconstruction.embl
│           │   ├── 📄 <Species>_<cluster_id>.filtered_plymorphic_sites.fasta
│           │   ├── 📄 <Species>_<cluster_id>.filtered_plymorphic_sites.phylip
│           │   ├── 📄 <Species>_<cluster_id>.final_tree.tre
│           │   ├── 📄 <Species>_<cluster_id>.node_labelled.final_tree.tre
│           │   ├── 📄 <Species>_<cluster_id>.per_branch_statistics.csv
│           │   ├── 📄 <Species>_<cluster_id>.recombination_predictions.embl
│           │   ├── 📄 <Species>_<cluster_id>.recombination_predictions.gff
│           │   └── 📄 <Species>_<cluster_id>.summary_of_snp_distribution.vcf
│           ├── 📁 panaroo
│           │   ├── 📄 <Species>_<cluster_id>_gene_presence_absence_dist.tsv
│           │   ├── 📄 <Species>_<cluster_id>_gene_presence_absence_roary.csv
│           │   ├── 📄 <Species>_<cluster_id>_gene_presence_absence.Rtab
│           │   └── 📄 <Species>_<cluster_id>_summary_statistics.txt
│           ├── 📁 mashtree
│           │   ├── 📄 <Species>_<cluster_id>.dnd
│           │   └── 📄 <Species>_<cluster_id>.tsv
│           ├── 📁 linkages
│           │   ├── 📄 <Species>_<cluster_id>_snippy_linkages.csv
│           │   └── 📄 <Species>_<cluster_id>_gubbins_linkages.csv
│           ├── 📄 <Species>_<cluster_id>.html
│           └── 📄 <Species>_<cluster_id>_reference_evaluation.tsv
└── 📁 pipeline_info
    ├── 📄 execution_report_<date_time>.html
    ├── 📄 execution_timeline_<date_time>.html
    ├── 📄 execution_trace_<date_time>.txt
    ├── 📄 pipeline_dag_<date_time>.html
    ├── 📄 samplesheet.valid.csv
    └── 📄 software_versions.yml
```