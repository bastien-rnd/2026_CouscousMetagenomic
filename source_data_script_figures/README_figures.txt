This repository present the data and script used to process data for the publication : "Understanding microbiomes of traditional fermented cereal-based foods unveils a frail balance from nutritional benefits to health risks"

In this repository you can find 5 folders :
- f3m : data related to f3m necessary to create plots
- final_plots : plots as presented in the publication
Aesthetic modification have been performed on the plots using Inkscape to produce the final figure.
- plots : intermediary and clean individual plots in .svg and .png
- rawdata_scripts : script used to process raw metagenomic data
- resistome : data related to resistome analysis necessary to create plots

Scripts and source data used to produce the figures of the publication are directly stored in the main of this repository.
Legend : 
Script : script use to produce the plot
Source_data : data directly used to create the plot
Raw plot : plot generated with the script
Clean plot : plot after aesthetic modification using Inkscape


List of script and source data (ordered by plots) :

Fig 1
Script : SD1_fig1a_map_fermented_cereals.R
Source data : SD1_fig1a_map_fermented_cereals.xlsx
Raw plot : SD1_raw_fig1a_map_fermented_cereals.svg/.png
Clean plot : SD1_clean_fig1a_map_fermented_cereals.svg

Table 1
Script : SD2_table1_metadata_fermented_cereals.R
Source data : SD2_table1_metadata_fermented_cereals.xlsx
Clean plot : SD2_table1_metadata_fermented_cereals.png

Fig 2a (one figure by index, merged in the clean plot)
Script : SD3_fig2a_alpha_div_fermented_cereals.R
Source data : SD3_fig2a_alpha_div_fermented_cereals.xlsx
Raw plot : SD3_fig2a_Evenness_boxplot.svg/.png ; SD3_fig2a_Richness_boxplot.svg/.png
Clean plot : SD3_clean_fig2a_alpha_div_boxplot.svg

Fig 2b
Script : SD4_fig2b_beta_div_fermented_cereals.R 
Source data : SD4_fig2b_beta_div_fermented_cereals.xlsx
Raw plot : SD4_raw_fig2b_beta_div_fermented_cereals.svg/.png
Clean plot : SD4_clean_fig2b_beta_div_fermented_cereals.svg

Fig 2c
Script : SD5_fig2c_anosim_beta_div_fermented_cereals.R
Source data : SD5_fig2c_anosim_beta_div_fermented_cereals.xlsx
Raw plot : SD5_fig2c_anosim_beta_div_fermented_cereals.svg/.png
Clean plot : SD5_clean_fig2c_anosim_beta_div_fermented_cereals.svg

Fig 2d
Script : SD6_fig2d_genus_histo_fermented_cereals.R
Source data : merged_sylph_abundance_clean.xlsx
Raw plot : SD6_fig2d_genus_histo_fermented_cereals.svg/.png
Clean plot : SD6_clean_fig2d_genus_histo_fermented_cereals.svg

Fig 3a
Script : SD7_fig3a_venn_f3m.R
Source data : SD7_fig3a_venn_f3m.xlsx
Raw plot : SD7_fig3a_venn_f3m.svg/.png
Clean plot : SD7_fig3a_venn_f3m.svg

Fig 3b
Script : SD8_fig3b_deseq2_carbohydrates_f3m.R
Source data : SD8_fig3b_deseq2_carbohydrates_f3m.xlsx
Raw plot : SD8_fig3b_deseq2_metabolic_module_f3m.svg/.png
Clean plot : SD8_clean_fig3b_deseq2_metabolic_module_f3m.svg

Fig 3c
Script : SD9_fig3d_wconf_pangenome.sh
Source data : anvio output
Raw plot : SD9_clean_fig3d_wconf_pangenome.svg
Clean plot : SD9_clean_fig3d_wconf_pangenome.svg

Fig 3d
Script : SD10_fig3d_resistome.R
Source data : SD10_fig3d_resistome.tsv
Raw plot : SD10_fig3e_resistome.svg/.png
Clean plot : SD10_clean_fig3d_resistome.svg


Fig 4a
Script : SD11_fig4a_beta_div_couscous.R
Source data : SD11_fig4a_beta_div_couscous.xlsx
Raw plot : SD11_fig4a_beta_div_couscous.svg/.png
Clean plot : SD11_clean_fig4a_beta_div_couscous.svg

Fig 4b
Script : SD12_fig4b_anosim_beta_div_couscous.R
Source data : SD12_fig4b_anosim_beta_div_couscous.xlsx
Raw plot : SD12_fig4b_anosim_beta_div_couscous.svg/.png
Clean plot : SD12_clean_fig4b_anosim_beta_div_couscous.svg

Fig 4c
Script : SD13_fig4c_venn_taxo_couscous.R
Source data : SD13_fig4c_venn_taxo_couscous.xlsx
Raw plot : SD13_fig4c_venn_taxo_couscous.svg/.png
Clean plot : SD13_clean_fig4c_venn_taxo_couscous.svg

Fig 4d
Script : SD14_fig4d_deseq2_taxo_couscous.R
Source data : SD14_fig4d_deseq2_taxo_couscous.xlsx
Raw plot : SD14_fig4d_deseq2_taxo_couscous.svg/.png
Clean plot : SD14_clean_fig4d_deseq2_taxo_couscous.svg

Fig 4e
Script : SD15_fig4e_starch_maltose_contribution_f3m.R
Source data : SD15_fig4e_starch_maltose_contribution_f3m.xlsx
Raw plot : SD15_fig4e_starch_maltose_contribution_f3m.svg/.png
Clean plot : SD15_clean_fig4e_starch_maltose_contribution_f3m.svg

Fig 5a
Script : SD16_fig5a_cobalamin_content.R
Source data : SD16_fig5a_cobalamin_content.xlsx
Raw plot : SD16_fig5a_cobalamin_content.svg/.png
Clean plot : SD16_clean_fig5a_cobalamin_content.svg

Fig 5b
Script : SD17_fig5b_cobalamin_contribution_f3m.R
Source data : SD17_fig5b_cobalamin_contribution_f3m.xlsx
Raw plot : SD17_fig5b_cobalamin_contribution_f3m.svg
Clean plot : SD17_clean_fig5b_cobalamin_contribution_f3m.svg

Fig 5c
Script : SD18_fig5c_folate_potential_f3m.R
Source data : SD18_fig5c_folate_potential_f3m.xlsx
Raw plot : SD18_fig5c_folate_potential_f3m.svg/.png
Clean plot : SD18_clean_fig5c_folate_potential_f3m.svg


Supplementary Fig 1
Script : SD19_supp_fig1_venn_taxo_fermented_cereals.R
Source data : SD19_supp_fig1_venn_taxo_fermented_cereals.xlsx
Raw plot : SD19_supp_fig1_venn_taxo_fermented_cereals.svg/.png
Clean plot : SD19_clean_supp_fig1_venn_taxo_fermented_cereals.svg

Supplementary Fig 2
Script : SD20_supp_fig2_family_histo_fermented_cereals.R
Source data : merged_sylph_abundance_clean.xlsx
Raw plot : SD20_supp_fig2_family_histo_fermented_cereals.svg/.png
Clean plot : SD20_clean_supp_fig2_family_histo_fermented_cereals.svg

Supplementary Fig 3
Script : SD21_supp_fig3_couscous_specific_gene_f3m.R
Source data : SD21_supp_fig3_couscous_specific_gene_f3m.xlsx
Raw plot : SD21_supp_fig3_couscous_specific_gene_f3m.svg/.png
Clean plot : SD21_clean_supp_fig3_couscous_specific_gene_f3m.svg

Supplementary Fig 4
Script : SD22_fig4_mags_summary.R
Source data : mags_summary.tsv (list of MAGs and metadata)
Raw plot : SD22_fig4_barplot.svg ; SD22_fig3c_mags_summary.svg
Clean plot : SD22_clean_supp_fig4_mag.svg

Supplementary Fig 5
Script : SD23_supp_fig5_venn_couscous.R
Source data : SD23_supp_fig5_venn_couscous.xlsx
Raw plot : SD23_supp_fig5_venn_cereal.svg/.png ; SD23_supp_fig5_venn_couscous.svg/.png
Clean plot : SD23_clean_supp_fig5_venn_cereals_couscous.svg


Others script and data :

Script : f3m_count_table_filtered.R
This script generate a clean and filtered F3M counting table
Input : merged_sylph_abundance_0.1_clean.xlsx (clean and filtered taxonomic table) ; metadata_samples.xlsx (metadata on samples) ; f3m repository (output from f3m)
Output : f3m_count_table_sylph_filtered.xlsx (f3m counting table linked with sylph taxonomic table output) 

Script : merged_sylph_abundance.R
This script generate a metaphlan-like counting taxonomic table from output of sylph-tax
Input : merged_sylph_abundance.tsv (raw output from sylph) ; metadata_samples.xlsx (metadata on samples)
Output : merged_sylph_abundance_0.1_clean.xlsx (clean and filtered taxonomic table)
