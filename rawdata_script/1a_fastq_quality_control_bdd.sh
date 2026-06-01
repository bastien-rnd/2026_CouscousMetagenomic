#!/bin/bash

#$ -S /bin/bash
#$ -N fastq_quality_control
#$ -q long.q
#$ -cwd
#$ -pe thread 32
#$ -o /work_projet/domino/analysis_rb/cereals_bdd/LOG/fastq_quality_control_bdd_o
#$ -e /work_projet/domino/analysis_rb/cereals_bdd/LOG/fastq_quality_control_bdd_e


########### DESCRIPTION

# This script preprocess metagenomes read using fastp and generates quality report.
# Parameters : read length > 75bp, quality > Q20, N >= 2
# Adapters have been removed using trimmomatic



########### DATA

# Raw reads (R1,R2.fastq.gz) : 1 repository/sample using the same name
# ex : sample_R1.fast.gz in the sample repository
RAWDATA="/work_projet/domino/analysis_rb/cereals_bdd/A_rawdata"

FASTQ_OUT="/work_projet/domino/analysis_rb/cereals_bdd/B_process_data_fastq/1_fastq_after_trimming"

REPORT_OUT="/work_projet/domino/analysis_rb/cereals_bdd/B_quality_report"



########### SCRIPT
mkdir -p "$FASTQ_OUT"
mkdir -p "$REPORT_OUT"

conda activate fastqc-0.12.1

# FastQC
for sample_dir in "$RAWDATA"/* ; do

    if [ -d "$sample_dir" ]; then

      mkdir -p "$REPORT_OUT"/0_fastq_before_trimming/"$(basename "$sample_dir")"
    
      fastqc "$sample_dir"/*_{R1,1}.fastq.gz "$sample_dir"/*_{R2,2}.fastq.gz -o "$REPORT_OUT"/0_fastq_before_trimming/"$(basename "$sample_dir")" -t 16    
      if [[ $? -ne 0 ]]; then
          echo "Erreur lors du traitement de $(basename "$sample_dir")"
      fi
    fi
done

conda deactivate

### FASTP

conda activate fastp-0.24.0

for sample_dir in "$RAWDATA"/* ; do
    if [ -d "$sample_dir" ]; then
        sample_name=$(basename "$sample_dir")
        category_name=$(basename "$(dirname "$sample_dir")")

        output_dir="$FASTQ_OUT/$category_name/$sample_name"
        mkdir -p "$output_dir"

        report_dir="$REPORT_OUT/1_fastq_after_trimming/$sample_name"
        mkdir -p "$report_dir"

        r1_file=$(ls "$sample_dir"/*_{R1,2}.fastq.gz 2>/dev/null)
        r2_file=$(ls "$sample_dir"/*_{R2,2}.fastq.gz 2>/dev/null)

        if [ -z "$r1_file" ] || [ -z "$r2_file" ]; then
            echo "Fichiers R1 ou R2 introuvables pour $sample_name dans $category_name. Ignoré."
            continue
        fi

        fastp -i "$r1_file" -I "$r2_file" \
              -o "$output_dir/${sample_name}_R1_trimmed.fastq.gz" \
              -O "$output_dir/${sample_name}_R2_trimmed.fastq.gz" \
              --length_required 75 --qualified_quality_phred 20 --n_base_limit 2 \
              --html "$report_dir/${sample_name}_fastp_report.html" \
              --json "$report_dir/${sample_name}_fastp_report.json"

        if [[ $? -ne 0 ]]; then
            echo "Erreur lors du traitement de $sample_name dans $category_name"
        fi
    fi
done
conda deactivate

### FASTP2

conda activate fastqc-0.12.1

for sample_dir in "$FASTQ_OUT"/new_samples/* ; do

    if [ -d "$sample_dir" ]; then

      fastqc "$sample_dir"/*_R1_trimmed.fastq.gz "$sample_dir"/*_R2_trimmed.fastq.gz -o "$REPORT_OUT"/1_fastq_after_trimming/"$(basename "$sample_dir")"
    
      if [[ $? -ne 0 ]]; then
          echo "Erreur lors du traitement de $(basename "$sample_dir")"
      fi
    fi
done

conda deactivate


