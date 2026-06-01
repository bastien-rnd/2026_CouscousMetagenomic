#!/bin/bash

#$ -S /bin/bash
#$ -N run_sylph
#$ -q short.q
#$ -cwd
#$ -pe thread 32
#$ -o /work_projet/domino/analysis_rb/cereals_bdd/LOG/run_sylph_o
#$ -e /work_projet/domino/analysis_rb/cereals_bdd/LOG/run_sylph_e



########### DESCRIPTION

# Generate a counting table using sylph and sylph_tax


########### DATA

CLEAN_FASTQ="/work_projet/domino/analysis_rb/cereals_bdd/B_process_data_fastq/3_fastq_after_nextera"

TABLE_OUT="/work_projet/domino/analysis_rb/cereals_bdd/C_taxo_sylph"
mkdir -p "$TABLE_OUT/output_sylph"

DB_FILES="/db/outils/sylph-0.8.1/gtdb-r220-c200-dbv1.syldb /db/outils/sylph-0.8.1/fungi-refseq-2024-07-25-c200-v0.3.syldb"



########### SCRIPT

conda activate sylph-0.8.1

# Sylph

R1_FILES=$(ls "$CLEAN_FASTQ"/*/*/*_1.fastq.gz | tr '\n' ' ')
R2_FILES=$(ls "$CLEAN_FASTQ"/*/*/*_2.fastq.gz | tr '\n' ' ')

sylph profile $DB_FILES \
  -1 $R1_FILES \
  -2 $R2_FILES \
  -o "$TABLE_OUT/sylph_output_bdd.tsv" \
  -t 32


for sample_dir in "$CLEAN_FASTQ"/*/*; do
    sample_name=$(basename "$sample_dir")

    R1="$sample_dir/${sample_name}_1.fastq.gz"
    R2="$sample_dir/${sample_name}_2.fastq.gz"

    if [[ -f "$R1" && -f "$R2" ]]; then
        echo "Traitement de $sample_name"
        sylph profile $DB_FILES \
          -1 "$R1" \
          -2 "$R2" \
          -o "$TABLE_OUT/output_sylph/${sample_name}.sylphmpa" \
          -t 32
    else
        echo "Fichiers manquants pour $sample_name. R1 ou R2 introuvable."
    fi
done

conda deactivate



#Sylph-tax : counting table
conda activate sylph-tax-1.2.0

sylph-tax download --download-to $TABLE_OUT


mkdir -p "$TABLE_OUT"/indiv_list
cd $TABLE_OUT/indiv_list

sylph-tax taxprof "$TABLE_OUT/sylph_output_bdd.tsv" -t GTDB_r220 FungiRefSeq-2024-07-25

sylph-tax merge *.sylphmpa --colum relative_abundance -o "$TABLE_OUT/merged_sylph_abundance.tsv"

conda deactivate

echo "Traitement terminé. Les fichiers de sortie sont disponibles dans $TABLE_OUT."


