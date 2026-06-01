#!/bin/bash

#$ -S /bin/bash
#$ -N run_f3m
#$ -q long.q
#$ -cwd
#$ -pe thread 64
#$ -o /work_projet/domino/analysis_rb/cereals_bdd/LOG/run_f3m_out
#$ -e /work_projet/domino/analysis_rb/cereals_bdd/LOG/run_f3m_err

########### DESCRIPTION

# This script generates a gene catalog according to the F3M database by downloading pangenomes in progenomes database according to a list of taxa.
# This pangenomes will be annotated to create in gene catalog.
# This gene catalog will be use to map with metagenomes or MAGs.

# To install conda environment
cd f3m_builder && sh set_up_environment_to_map_reads_to_genes_catalog.sh

#### F3M GENE CATALOG CONSTRUCTION
#BEFORE THE START OF THE GENE CATALOG CONSTRUCTION IT IS NECESSARY TO MODIFY THE FOLLOWING .yaml FILE
# config_build_a_genes_catalog_from_pangenomes.yaml
# list of bacterial species, for which pangenomes will be download in Progenome database : bdd_progenomes_list.tab

# To create f3m gene catalog (on a cluster)
qsub -cwd -V -N genes_cat_fermented_cereals -pe thread 4 -e /work_projet/domino/analysis_rb/cereals_bdd/F_f3m/LOG/f3m_catalog_err -o /work_projet/domino/analysis_rb/cereals_bdd/F_f3m/LOG/f3m_catalog_out -q infinit.q -b y "conda activate snakemake-7.32.4 && snakemake --snakefile /work_projet/domino/analysis_rb/cereals_bdd/F_f3m/f3m_builder/build_a_genes_catalog_from_pangenomes.smk  --configfile /work_projet/domino/analysis_rb/cereals_bdd/F_f3m/config_build_a_genes_catalog_from_pangenomes.yaml --cluster 'qsub -cwd -V -R y -N {rule} -q {params.queue} -pe thread {threads} -e /work_projet/domino/analysis_rb/cereals_bdd/F_f3m/LOG/ -o /work_projet/domino/analysis_rb/cereals_bdd/F_f3m/LOG/' --jobs 100 --restart-times 5 --use-conda  --latency-wait 60 --printshellcmds --latency-wait 60 && conda deactivate"


#### F3M MAPPING
#BEFORE THE START OF THE F3M MAPPING IT IS NECESSARY TO MODIFY THE FOLLOWING .yaml FILE
# config_map_reads_to_genes_catalog.yaml

# Lancer mapping échantillons sur catalogue
qsub -cwd -V -N map_cereals_reads_on_genes_cat_cereals -pe thread 4 -e /work_projet/domino/analysis_rb/cereals_bdd/F_f3m/LOG -o /work_projet/domino/analysis_rb/cereals_bdd/F_f3m/LOG -q infinit.q -b y "conda activate snakemake-7.32.4 && snakemake --snakefile /work_projet/domino/analysis_rb/cereals_bdd/F_f3m/f3m_builder/map_reads_to_genes_catalog.smk  --configfile /work_projet/domino/analysis_rb/cereals_bdd/F_f3m/config_map_reads_to_genes_catalog.yaml --cluster 'qsub -cwd -V -R y -N {rule} -pe thread {threads} -e /work_projet/domino/analysis_rb/cereals_bdd/F_f3m/LOG -o /work_projet/domino/analysis_rb/cereals_bdd/F_f3m/LOG' --jobs 100 --restart-times 5 --use-conda  --latency-wait 60 --printshellcmds --latency-wait 60 && conda deactivate"