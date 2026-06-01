#!/bin/bash

# DESCRIPTION ----------------------------------------------------------------

#This script generate anvio pangenomes

# DATA
ANVIO_DIR="/work_projet/domino/analysis_rb/cereals_bdd/H_MAGs_wconfusa/anvio"
ANVIO_MAG="${ANVIO_DIR}/mag_genome" #directory containing MAGs files
ANVIO_DB="${ANVIO_DIR}/anvio_db" #directory where DB will be created

mkdir -p $ANVIO_DB


# CREATION DB ANNOTATIONS (COG,KEGG,PFAM,CAZY)

conda activate anvio-8

for f in ${ANVIO_MAG}/*.fa; do
  base=$(basename "$f" .fa)
  echo ">>> Traitement de $base"
  
  anvi-gen-contigs-database -f "$f" -o "${ANVIO_DB}/${base}.db" -n "${base}"
  
  anvi-run-hmms -c "${ANVIO_DB}/${base}.db"
done


for db in ${ANVIO_DB}/*.db; do
  anvi-run-ncbi-cogs -c $db --cog-data-dir /db/outils/anvio-8 --num-threads 32
  anvi-run-pfams -c $db --pfam-data-dir /db/outils/anvio-8/Pfam --num-threads 32
  anvi-run-kegg-kofams -c $db --kegg-data-dir /db/outils/anvio-8/KEGG --num-threads 32
  anvi-run-cazymes -c $db --cazyme-data-dir /db/outils/anvio-8/CAZYME --num-threads 32
done



# To store pangenomes
anvi-gen-genomes-storage -e genomes_list_ferm.txt -o WCONFUSA_FERM-GENOMES.db

# To build pangenomes
anvi-pan-genome -g WCONFUSA_FERM-GENOMES.db  -n WCONFUSA_FERM --num-threads 32

# To add metadata
anvi-import-misc-data added_infos_wconf_ferm.txt -p WCONFUSA_FERM/WCONFUSA_FERM-PAN.db -t layers


# Enrichment analysis
#Pfam, COG20_FUNCTION, KEGG_BRITE, KEGG_Module, CAZyme
anvi-compute-functional-enrichment-in-pan -p WCONFUSA_FERM/WCONFUSA_FERM-PAN.db \
                                          -g WCONFUSA_FERM-GENOMES.db \
                                          --category Couscous \
                                          --annotation-source CAZyme \
                                          -o enriched-functions_CAZY.txt

# To display pangenomes
anvi-display-pan -p WCONFUSA_FERM/WCONFUSA_FERM-PAN.db -g WCONFUSA_FERM-GENOMES.db


# Information on pangenomes
anvi-summarize -g WCONFUSA_FERM-GENOMES.db -p WCONFUSA_FERM/WCONFUSA_FERM-PAN.db -C default
