#!/bin/bash

#$ -S /bin/bash
#$ -N run_anvio_db
#$ -q long.q
#$ -cwd
#$ -pe thread 32
#$ -o /work_projet/domino/analysis_rb/cereals_bdd/LOG/run_anvio_out
#$ -e /work_projet/domino/analysis_rb/cereals_bdd/LOG/run_anvio_err


########### DESCRIPTION

# This script generates pangenome from W.confusa MAGs in couscous and other fermented cereals using anvio-8.


########### DATA

ANVIO_DIR="/work_projet/domino/analysis_rb/cereals_bdd/H_MAGs_wconfusa/anvio"
ANVIO_MAG="${ANVIO_DIR}/mag_genome"
ANVIO_DB="${ANVIO_DIR}/anvio_db"

mkdir -p $ANVIO_DB


########### SCRIPT

# DB CREATION USING ANVIO

conda activate anvio-8

for f in ${ANVIO_MAG}/*.fa; do
  base=$(basename "$f" .fa)
  echo ">>> Traitement de $base"
  anvi-gen-contigs-database -f "$f" -o "${ANVIO_DB}/${base}.db" -n "${base}"
  anvi-run-hmms -c "${ANVIO_DB}/${base}.db"
done


# To annotate DB
for db in ${ANVIO_DB}/*.db; do
  anvi-run-ncbi-cogs -c $db --cog-data-dir /db/outils/anvio-8 --num-threads 32
  anvi-run-pfams -c $db --pfam-data-dir /db/outils/anvio-8/Pfam --num-threads 32
  anvi-run-kegg-kofams -c $db --kegg-data-dir /db/outils/anvio-8/KEGG --num-threads 32
  anvi-run-cazymes -c $db --kegg-data-dir /db/outils/anvio-8/CAZY --num-threads 32
done


# To store genome .db
anvi-gen-genomes-storage -e genomes_list_all.txt -o WCONFUSA_FERM-GENOMES.db

# To create pangenome
anvi-pan-genome -g WCONFUSA_ALL-GENOMES.db  -n WCONFUSA_FERM --num-threads 32


# To add metadata to pangenome
anvi-import-misc-data added_infos_wconf_all.txt -p WCONFUSA_ALL/WCONFUSA_ALL-PAN.db -t layers

# Enrichment analysis
#To change --annotation-source by the following databases : Pfam, COG20_FUNCTION, KEGG_BRITE, KEGG_Module, CAZyme
anvi-compute-functional-enrichment-in-pan -p WCONFUSA_FERM/WCONFUSA_FERM-PAN.db \
                                          -g WCONFUSA_FERM-GENOMES.db \
                                          --category Couscous \
                                          --annotation-source CAZyme \
                                          -o enriched-functions_CAZY.txt


# To display pangenomes
anvi-display-pan -p WCONFUSA_FERM/WCONFUSA_FERM-PAN.db -g WCONFUSA_FERM-GENOMES.db

conda deactivate