1 : Quality control of metagenomes reads
Input : Raw metagenomic reads
Output : Clean metagenomic reads

Script :
- 1a_fastq_quality_control.sh : to remove bad quality sequences
- 1b_fastq_remove_cereals : to remove reads associated to the host (cereals)
- 1c_fastq_remove_nextera_adapters : to remove nextera adapters


2 - Taxonomic assignation
Input : Clean metagenomes reads
Output : Taxonomic table (relative abundance)

Script :
- 2_run_sylph : to create taxonomic table using Sylph


3 - MAG reconstruction
Input : Clean metagenomes reads
Output : MAGs assembly

Scripts : 
- 3a_mag_reconstruction.sh : to reconstruct MAGs from metagenomes
- 3b_run_checkm.sh : to assess quality of MAGs
- 3c_run_gtdb.sh : to assignate taxonomy to MAGs


4 - Functional anotation by F3M
Input : Clean metagenomes reads
Output : Gene counting table 

Scripts : 
- 4_run_f3m.sh : to create f3m gene catalog and to map metagenomes or MAGs on the gene catalog

Files :
- bdd_progenomes_list.tab : list of pangenomes to download in Progenomes database
- config_build_a_genes_catalog_from_pangenomes.yaml : settings file for the gene catalog construction
- config_map_reads_to_genes_catalog.yaml : settings file for the mapping


5 - Resistome
Input : Clean metagenomes reads
Output :  Resistome counting table

Scripts : 
- 5a_run_megahit.sh : to create assembly to map them on CARD DB
- 5b_arg_mapping.sh : to map assembly on CARD DB


6 - Weissella confusa pangenomes
Input : MAGs assembly
Output : Pangenomes of W. confusa with enrichment analysis 

Scripts : 
- 6_run_anvio

Files :
- WCONFUSA_FERM-GENOMES.db : Pangenome
