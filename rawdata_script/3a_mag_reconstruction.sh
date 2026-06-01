#!/bin/bash

#$ -S /bin/bash
#$ -N mag_reconstruction
#$ -q long.q
#$ -cwd
#$ -pe thread 32
#$ -o /work_projet/domino/analysis_rb/cereals_bdd/LOG/mag_reconstruction_out
#$ -e /work_projet/domino/analysis_rb/cereals_bdd/LOG/mag_reconstruction_err


########### DESCRIPTION

# Generates MAGs from metagenomes 
# Parameters : minimal contigs length = 1000bp (except metabat = 1500bp)
# Bins quality : > 50% complétion, < 5% contamination



########### DATA

INPUT_CONTIG="/work_projet/domino/analysis_rb/cereals_bdd/D_assembly"

INPUT_FASTQ="/work_projet/domino/analysis_rb/cereals_bdd/B_process_data_fastq/3_fastq_after_nextera"

OUTPUT_DIR="/work_projet/domino/analysis_rb/cereals_bdd/H_MAGs"
mkdir -p "$OUTPUT_DIR"

SAMPLE_LIST="/work_projet/domino/analysis_rb/cereals_git/1_couscous/3_functions/script/list_metawrap/metawrap.txt"


########### SCRIPT

#METAWRAP
conda activate metawrap-1.3
conda activate metawrap-env

for contig_file in "$INPUT_CONTIG"/*/*.fa; do
    sample=$(basename "$contig_file" .contigs.fa)
    echo "Traitement de l'échantillon : $sample"

    if ! grep -Fxq "$sample" "$SAMPLE_LIST"; then
        continue
    fi
    
    R1=$(echo "$INPUT_FASTQ"/*/"$sample"/"${sample}"_R1_clean2.fastq.gz)
    R2=$(echo "$INPUT_FASTQ"/*/"$sample"/"${sample}"_R2_clean2.fastq.gz)

    ln -sf "$R1" "$OUTPUT_DIR/bin_$sample/${sample}_1.fastq"
    ln -sf "$R2" "$OUTPUT_DIR/bin_$sample/${sample}_2.fastq"

    if [[ ! -f "$R1" || ! -f "$R2" ]]; then
        echo "Reads R1 ou R2 manquants pour $sample :"
        echo "R1=$R1"
        echo "R2=$R2"
        continue
    fi

    mkdir -p "$OUTPUT_DIR/bin_$sample/bin_refinement_$sample"
    mkdir -p "$OUTPUT_DIR/bin_$sample/metabat2_bins"
    mkdir -p "$OUTPUT_DIR/bin_$sample/maxbin2_bins"
    mkdir -p "$OUTPUT_DIR/bin_$sample/concoct_bins"
    mkdir -p "$OUTPUT_DIR/bin_$sample/reassembled_bins_$sample"



    echo "Binning pour $sample"
    metawrap binning --metabat2 --maxbin2 -t 32 -m 125 -l 1000 \
     -a "$contig_file" -o "$OUTPUT_DIR/bin_$sample" "$OUTPUT_DIR/bin_$sample/${sample}_1.fastq" "$OUTPUT_DIR/bin_$sample/${sample}_2.fastq"  
       
          
    echo "Raffinement des bins pour $sample"
    metawrap bin_refinement \
      -o "$OUTPUT_DIR/bin_$sample/bin_refinement_$sample" \
      -t 32 -m 125 \
      -A "$OUTPUT_DIR/bin_$sample/metabat2_bins" \
      -B "$OUTPUT_DIR/bin_$sample/maxbin2_bins" \
      -c 50 -x 5
    
    echo "Reassemblage des bins pour $sample"
    metawrap reassemble_bins \
      -o "$OUTPUT_DIR/bin_$sample/reassembled_bins_$sample" \
      -t 32 -m 125 \
      -b "$OUTPUT_DIR/bin_$sample/bin_refinement_$sample/metawrap_50_5_bins" \
      -1 "$R1" \
      -2 "$R2" \
      -c 50 -x 5

    echo "Fin du traitement de $sample"
done

conda deactivate
conda deactivate











