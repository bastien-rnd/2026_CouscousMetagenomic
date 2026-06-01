#!/bin/bash

#$ -S /bin/bash
#$ -N run_megahit
#$ -q long.q
#$ -cwd
#$ -pe thread 64
#$ -o /work_projet/domino/analysis_rb/cereals_bdd/LOG/run_megahit_o
#$ -e /work_projet/domino/analysis_rb/cereals_bdd/LOG/run_megahit_e

########### DESCRIPTION

# Metagenomes assembly



########### DATA

CLEAN_FASTQ="/work_projet/domino/analysis_rb/cereals_bdd/B_process_data_fastq/3_fastq_after_nextera"

OUTPUT_DIR="/work_projet/domino/analysis_rb/cereals_bdd/D_assembly"
mkdir -p "$OUTPUT_DIR"


########### SCRIPT

#MEGAHIT
conda activate megahit-1.2.9

for sample_dir in $CLEAN_FASTQ/new_samples/* ; do
    sample_name=$(basename $sample_dir)
    echo "Processing sample : $sample_name"

    echo "Decompressing FASTQ file..."
    if gzip -dk $sample_dir/${sample_name}_1.fastq.gz && \
       gzip -dk $sample_dir/${sample_name}_2.fastq.gz; then
        echo "Decompression successful for $sample_name"
    else
        echo "Error during decompression for $sample_name"
        continue
    fi

    echo "Running MEGAHIT for assembly..."
    megahit -1 $sample_dir/${sample_name}_1.fastq \
            -2 $sample_dir/${sample_name}_2.fastq \
            -o "$OUTPUT_DIR"/$sample_name --out-prefix $sample_name \
            -t 64
    
    if [ -f "$OUTPUT_DIR/$sample_name/${sample_name}.contigs.fa" ]; then
        echo "Assembly completed : $sample_name"
        
    else
        echo "Assembly error : $sample_name"
    fi
    
    echo "Cleaning up decompressed files..."
        rm -f $sample_dir/${sample_name}_1.fastq
        rm -f $sample_dir/${sample_name}_2.fastq
        
done
    
conda deactivate

