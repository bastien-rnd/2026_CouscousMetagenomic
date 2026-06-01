#!/bin/bash

#$ -S /bin/bash
#$ -N run_checkm
#$ -q long.q
#$ -cwd
#$ -pe thread 64
#$ -o /work_projet/domino/analysis_rb/cereals_bdd/LOG/run_checkm_o
#$ -e /work_projet/domino/analysis_rb/cereals_bdd/LOG/run_checkm_e

########### DESCRIPTION

# Bins quality control using CheckM.

########### DATA

BINS_DIR="/work_projet/domino/analysis_rb/cereals_bdd/H_MAGs/all_bins"

CHECKM_DIR="/work_projet/domino/analysis_rb/cereals_bdd/H_MAGs/checkm_all_bins"



########### SCRIPT

# CheckM

mkdir -p "$CHECKM_DIR"

conda activate checkm2-1.1.0

checkm2 predict --threads 64 --input "$BINS_DIR" --output-directory "$CHECKM_DIR"/checkm_output -x fa

conda deactivate



