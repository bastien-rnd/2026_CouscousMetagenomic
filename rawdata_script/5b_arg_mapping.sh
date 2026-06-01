#!/bin/bash

#$ -S /bin/bash
#$ -N arg_annotation_full
#$ -q long.q
#$ -cwd
#$ -pe thread 32
#$ -o /work_projet/domino/analysis_rb/cereals_bdd/LOG/arg_annotation_full_o
#$ -e /work_projet/domino/analysis_rb/cereals_bdd/LOG/arg_annotation_full_e


########### DESCRIPTION

# Mapping CARD using bowtie2


########### DATA

# Assembly au format .fna des métagénomes
INPUT_FASTA="/work_projet/domino/analysis_rb/cereals_bdd/D_assembly"

# Reads
INPUT_READS="/work_projet/domino/analysis_rb/cereals_bdd/B_process_data_fastq/3_fastq_after_nextera"


OUTPUT_DIR="/work_projet/domino/analysis_rb/cereals_bdd/G_ARG_annotation"

THREADS=${NSLOTS:-32}



########### SCRIPT

mkdir -p "$OUTPUT_DIR"/db
cd "$OUTPUT_DIR"/db

# CARD index 
conda activate bowtie2-2.5.4
bowtie2-build nucleotide_fasta_protein_homolog_model.fasta CARD_index
conda deactivate


# Alignment

for sample_dir in "$INPUT_FASTA"/*; do
    sample_name=$(basename "$sample_dir")
    echo "Processing $sample_name"
    
    assembly_fa="$sample_dir/${sample_name}.contigs.fa"
    if [[ ! -f "$assembly_fa" ]]; then
        echo "Fichier manquant : $assembly_fa"
        continue
    fi

    R1=$(find "$INPUT_READS" -name "${sample_name}_1.fastq.gz")
    R2=$(find "$INPUT_READS" -name "${sample_name}_2.fastq.gz")

    mkdir -p "$OUTPUT_DIR"/samtools_out
    
    conda activate bowtie2-2.5.4
    
    bowtie2 -x "$OUTPUT_DIR"/db/CARD_index \
            -1 $R1 -2 $R2 -S "$OUTPUT_DIR"/samtools_out/${sample_name}_vs_ARGs.sam \
            -p 32
    
    conda deactivate
    
    
    conda activate samtools-1.21
    
    samtools view -@ $THREADS -bS "$OUTPUT_DIR"/samtools_out/${sample_name}_vs_ARGs.sam | \
        samtools sort -@ $THREADS -o "$OUTPUT_DIR"/samtools_out/${sample_name}_vs_ARGs.sorted.bam
    samtools index "$OUTPUT_DIR"/samtools_out/${sample_name}_vs_ARGs.sorted.bam

    mkdir -p "$OUTPUT_DIR"/final_arg_out
    
    samtools idxstats "$OUTPUT_DIR"/samtools_out/${sample_name}_vs_ARGs.sorted.bam \
        > "$OUTPUT_DIR"/final_arg_out/${sample_name}_ARG_counts.tsv

    sed -i '1i seqname\tseqlen\tmapped_reads\tunmapped_reads' "$OUTPUT_DIR"/final_arg_out/${sample_name}_ARG_counts.tsv

    rm -f "$OUTPUT_DIR"/samtools_out/${sample_name}_vs_ARGs.sam
    rm -f "$OUTPUT_DIR"/samtools_out/${sample_name}_vs_ARGs.sorted.bam
    rm -f "$OUTPUT_DIR"/samtools_out/${sample_name}_vs_ARGs.sorted.bam.bai

    conda deactivate

done

