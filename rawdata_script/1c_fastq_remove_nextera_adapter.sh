#!/bin/bash

#$ -S /bin/bash
#$ -N remove_nextera_adapter
#$ -q long.q
#$ -cwd
#$ -pe thread 32
#$ -o /work_projet/domino/analysis_rb/cereals_bdd/LOG/remove_nextera_adapter_o
#$ -e /work_projet/domino/analysis_rb/cereals_bdd/LOG/remove_nextera_adapter_e

########### DESCRIPTION

# Removing NEXTERA adapter specifically


########### DATA

CLEAN_DATA="/work_projet/domino/analysis_rb/cereals_bdd/B_process_data_fastq/2_fastq_after_host"

FASTQ_OUT="/work_projet/domino/analysis_rb/cereals_bdd/B_process_data_fastq/3_fastq_after_nextera"

REPORT_OUT="/work_projet/domino/analysis_rb/cereals_bdd/B_quality_report"

#nextera adapters
ADAPTERS="/work_projet/domino/analysis_rb/cereals_bdd/A_others_data/adapters/NexteraPE-PE.fa"


########### SCRIPT

#Trimmomatic

conda activate trimmomatic-0.39

for sample_dir in "$CLEAN_DATA"/*/* ; do
    if [ -d "$sample_dir" ]; then
        sample_name=$(basename "$sample_dir")
        category_name=$(basename "$(dirname "$sample_dir")")

        output_dir="$FASTQ_OUT/$category_name/$sample_name"
        mkdir -p "$output_dir"

        report_dir="$REPORT_OUT/3_fast_after_nextera/$sample_name"
        mkdir -p "$report_dir"

        r1_file=$(ls "$sample_dir"/*_{R1,2}_clean.fastq.gz 2>/dev/null)
        r2_file=$(ls "$sample_dir"/*_{R2,2}_clean.fastq.gz 2>/dev/null)

        if [ -z "$r1_file" ] || [ -z "$r2_file" ]; then
            echo "Fichiers R1 ou R2 introuvables pour $sample_name dans $category_name. Ignoré."
            continue
        fi

        trimmomatic PE -threads 32 \
          "$r1_file" "$r2_file" \
          "$output_dir/${sample_name}_R1_clean2.fastq.gz" "$output_dir/${sample_name}_R1_unpaired.fastq.gz" \
          "$output_dir/${sample_name}_R2_clean2.fastq.gz" "$output_dir/${sample_name}_R2_unpaired.fastq.gz" \
          ILLUMINACLIP:"$ADAPTERS":2:30:10 \
          LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:75

        if [[ $? -ne 0 ]]; then
            echo "Erreur lors du traitement de $sample_name dans $category_name"
        fi
    fi
done
conda deactivate



### FASTQC

conda activate fastqc-0.12.1

for sample_dir in "$FASTQ_OUT"/*/*; do

    if [ -d "$sample_dir" ]; then

      mkdir -p "$REPORT_OUT"/3_fastq_after_nextera/"$(basename "$sample_dir")"
      
      fastqc "$sample_dir"/*_R1_clean2.fastq.gz "$sample_dir"/*_R2_clean2.fastq.gz -o "$REPORT_OUT"/3_fastq_after_nextera/"$(basename "$sample_dir")"
    
      if [[ $? -ne 0 ]]; then
          echo "Erreur lors du traitement de $(basename "$sample_dir")"
      fi
    fi
done

conda deactivate
