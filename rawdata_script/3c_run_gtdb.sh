#!/bin/bash

#$ -S /bin/bash
#$ -N run_gtdb
#$ -q short.q
#$ -cwd
#$ -pe thread 64
#$ -o /work_projet/domino/analysis_rb/cereals_bdd/LOG/run_gtdb_o
#$ -e /work_projet/domino/analysis_rb/cereals_bdd/LOG/run_gtdb_e

########### DESCRIPTION

# Bins taxonomic assignation using GTDB-Tk.


########### DATA

BINS_DIR="/work_projet/domino/analysis_rb/cereals_bdd/H_MAGs/all_bins"

GTDB_DIR="/work_projet/domino/analysis_rb/cereals_bdd/H_MAGs/gtdb_tk_all_bins"



########### SCRIPT

# GTDB-Tk

mkdir -p "$GTDB_DIR"

conda activate gtdbtk-2.5.2

gtdbtk classify_wf --genome_dir "$BINS_DIR" --out_dir "$GTDB_DIR"/gtdbtk_output  --extension fa --cpus 64 --skip_ani_screen

conda deactivate
