#!/bin/bash

#$ -S /bin/bash
#$ -N remove_cereals
#$ -q long.q
#$ -cwd
#$ -pe thread 32
#$ -o /work_projet/domino/analysis_rb/cereals_bdd/LOG/remove_out
#$ -e /work_projet/domino/analysis_rb/cereals_bdd/LOG/remove_err


########### DESCRIPTION

# Metagenomes have been mapped using bowtie2 to removed sequences that could be associated to cereals
# Zea Mays: GCF_902167145_1_Zm_B73_REFERENCE_NAM_5.0_genomic
# Pennisetum glaucum : GCA_963924085_1_AwK_v01_genomic
# Sorghum bicolor : GCF_000003195_3_Sorghum_bicolor_NCBIv3_genomic
# Triticum aestivum : GCF_018294505.1_IWGSC_CS_RefSeq_v2.1_genomic
# Secale cereale : GCA_902687465.1_Rye_Lo7_2018_v1p1p1_genomic


########### DATA

# bowtie2 index
BOWTIE2_DIR="/work_projet/domino/analysis_rb/cereals_bdd/A_others_data/bowtie2"

# Cereals genome
GENOME_FASTA="$BOWTIE2_DIR/fna_reference_genome/millet_maize_sorghum_genomic.fna"

INDEX_PREFIX="$BOWTIE2_DIR/bowtie2_index/millet_maize_sorghum/millet_maize_sorghum"

BOWTIE_OUT="/work_projet/domino/analysis_rb/cereals_bdd/B_process_data_fastq/2_bowtie_out"

TRIMMED_DATA="/work_projet/domino/analysis_rb/cereals_bdd/B_process_data_fastq/1_fastq_after_trimming"

FASTQ_OUT="/work_projet/domino/analysis_rb/cereals_bdd/B_process_data_fastq/2_fastq_after_host"

REPORT_OUT="/work_projet/domino/analysis_rb/cereals_bdd/B_quality_report"




########### SCRIPT

# Index creation

conda activate bowtie2-2.5.4

if [[ -f "${INDEX_PREFIX}.1.bt2l" ]]; then
    echo "L'index  existe déjà."
else
    echo "L'index n'existe pas. Création de l'index..."
    bowtie2-build "$GENOME_FASTA" "$INDEX_PREFIX"
fi

conda deactivate



# Read_alignments using BOWTIE2

categories=("ird_flours" "cfmd_others" "pozol")

for category in "${categories[@]}"; do
    category_dir="$TRIMMED_DATA/$category"
    if [ -d "$category_dir" ]; then
        for sample_dir in "$category_dir"/*; do
            sample_name=$(basename "$sample_dir")
            echo "Processing $sample_name in category $category"

            mkdir -p "$BOWTIE_OUT/$category/$sample_name"
            
            conda activate bowtie2-2.5.4
            
            bowtie2 -x "$INDEX_PREFIX" \
                    -1 "$sample_dir/${sample_name}_R1_trimmed.fastq.gz" \
                    -2 "$sample_dir/${sample_name}_R2_trimmed.fastq.gz" \
                    -S "$BOWTIE_OUT/$category/$sample_name/${sample_name}_millet_maize_sorghum.sam" \
                    --sensitive-local --threads 32 --no-mixed

            conda deactivate

            if [[ -f "$BOWTIE_OUT/$category/$sample_name/${sample_name}_millet_maize_sorghum.sam" ]]; then
                echo "Le fichier SAM existe, conversion en BAM."
                
                conda activate samtools-1.21

                samtools view -f 12 "$BOWTIE_OUT/$category/$sample_name/${sample_name}_millet_maize_sorghum.sam" > "$BOWTIE_OUT/$category/$sample_name/${sample_name}_unaligned_millet_maize_sorghum.sam"

                mkdir -p "$FASTQ_OUT/$category/$sample_name"

                samtools fastq -1 "$FASTQ_OUT/$category/$sample_name/${sample_name}_R1_clean.fastq.gz" \
                               -2 "$FASTQ_OUT/$category/$sample_name/${sample_name}_R2_clean.fastq.gz" \
                               "$BOWTIE_OUT/$category/$sample_name/${sample_name}_unaligned_millet_maize_sorghum.sam"

                rm "$BOWTIE_OUT/$category/$sample_name/${sample_name}_millet_maize_sorghum.sam"

                samtools view -b "$BOWTIE_OUT/$category/$sample_name/${sample_name}_unaligned_millet_maize_sorghum.sam" > "$BOWTIE_OUT/$category/$sample_name/${sample_name}_unaligned_millet_maize_sorghum.bam"
                rm "$BOWTIE_OUT/$category/$sample_name/${sample_name}_unaligned_millet_maize_sorghum.sam"
                               
                conda deactivate
                
            else
                echo "Erreur : le fichier SAM n'a pas été généré pour $sample_name."
                continue  
            fi

        done
    else
        echo "Catégorie $category non trouvée dans $TRIMMED_DATA"
    fi
done

conda deactivate


# FASTQC

conda activate fastqc-0.12.1

for category in "${categories[@]}"; do
    category_dir="$FASTQ_OUT/$category"
    if [ -d "$category_dir" ]; then
        for sample_dir in "$category_dir"/*; do
            if [ -d "$sample_dir" ]; then
                sample_name=$(basename "$sample_dir")
                mkdir -p "$REPORT_OUT/2_fastq_after_host/$category/$sample_name"
                
                fastqc "$sample_dir"/*_R1_clean.fastq.gz "$sample_dir"/*_R2_clean.fastq.gz -o "$REPORT_OUT/2_fastq_after_host/$category/$sample_name"
                
                if [[ $? -ne 0 ]]; then
                    echo "Erreur lors du traitement de $sample_name"
                fi
            fi
        done
    else
        echo "Catégorie $category non trouvée dans $FASTQ_OUT"
    fi
done

conda deactivate