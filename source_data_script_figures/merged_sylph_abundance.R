# DESCRIPTION ----------------------------------------------------------------

# This script generate a metaphlan-like counting taxonomic table from output of sylph-tax
# Rename of samples/taxa and cut-off to 0.1% relative abundance according to Leech & al. 2020


# PACKAGES ----------------------------------------------------------------
library(tidyverse)
library(readxl)
library(writexl)


# ANALYSIS ----------------------------------------------------------------

# To set working directory 
setwd("source_data_script_figures")


# Table de comptage des échantillons de la BDD cereals
input_dir <- "merged_sylph_abundance.tsv" 
sylph_count <- read_tsv(input_dir)

# Métadonnées sur les échantillons de la BDD cerealss
input_metadata <- "metadata_samples.xlsx"
metadata <- read_excel(input_metadata)



# Cleaning of count table ----------------------------------------------------------------

# To clean sample columns names
colnames(sylph_count) <- gsub("/work_projet/domino/analysis_rb/cereals_bdd/B_process_data_fastq/3_fastq_after_nextera/", "", colnames(sylph_count))
colnames(sylph_count) <- gsub("ird_flours/", "", colnames(sylph_count))
colnames(sylph_count) <- gsub("cfmd_sourdough/", "", colnames(sylph_count))
colnames(sylph_count) <- gsub("cfmd_others/", "", colnames(sylph_count))
colnames(sylph_count) <- gsub("pozol/", "", colnames(sylph_count))
colnames(sylph_count) <- gsub("new_samples/", "", colnames(sylph_count))
colnames(sylph_count) <- sub("/.*", "", colnames(sylph_count))

rename_vector <- setNames(metadata$clean_id, metadata$raw_id)

colnames(sylph_count) <- ifelse(
  colnames(sylph_count) %in% names(rename_vector),
  rename_vector[colnames(sylph_count)],
  colnames(sylph_count)  # laisse les autres colonnes inchangées
)


# Rename of species
sylph_count <- sylph_count %>%
  mutate(clade_name = recode(clade_name,
                             "NO_TAXONOMY|t__GCF_000213175.1_v2.0"    = "d__Eukaryota|p__Ascomycota|c__Sordariomycetes|o__Sordariales|f__Sordariaceae|g__Neurospora|s__Neurospora tetrasperma",
                             "NO_TAXONOMY|t__GCF_001417885.1_Kmar_1.0"= "d__Eukaryota|p__Ascomycota|c__Saccharomycetes|o__Saccharomycetales|f__Saccharomycetaceae|g__Kluyveromyces|s__Kluyveromyces marxianus",
                             "NO_TAXONOMY|t__GCF_001661235.1_Picme2"  = "d__Eukaryota|p__Ascomycota|c__Saccharomycetes|o__Saccharomycetales|f__Pichiaceae|g__Pichia|s__Pichia membranifaciens",
                             "NO_TAXONOMY|t__GCF_001661255.1_Wican1"  = "d__Eukaryota|p__Ascomycota|c__Saccharomycetes|o__Phaffomycetales|f__Wickerhamomycetaceae|g__Wickerhamomyces|s__Wickerhamomyces anomalus",
                             "NO_TAXONOMY|t__GCF_001661395.1_Hypbu1"  = "d__Eukaryota|p__Ascomycota|c__Pichiomycetes|o__Serinales|f__Debaryomycetaceae|g__Hyphopichia|s__Hyphopichia burtonii",
                             "NO_TAXONOMY|t__GCF_001661255.1_Wican1"  = "d__Eukaryota|p__Ascomycota|c__Sordariomycetes|o__Hypocreales|f__Ophiocordycipitaceae|g__Purpureocillium|s__Purpureocillium lilacinum",
                             "NO_TAXONOMY|t__GCF_023168085.1_PurlilCBS_1.0" = "d__Eukaryota|p__Ascomycota|c__Eurotiomycetes|o__Eurotiales|f__Aspergillaceae|g__Penicillium|s__Penicillium longicatenatum"
  ))


# To organise taxonomic clusters

#To filter species and delete t_ level
sylph_species <- sylph_count %>% dplyr::filter(str_detect(clade_name, "s__") & !str_detect(clade_name, "t__"))

sylph_species <- sylph_species %>%
  separate(clade_name, into = c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species"), sep = "\\|", fill = "right" ) 

# To clean taxonomic clusters names
sylph_species <- sylph_species %>%
  mutate(across(
    .cols = c(Kingdom, Phylum, Class, Order, Family, Genus, Species),
    .fns = ~ str_replace_all(.x, "_[A-Z]+\\b", "") |> str_squish()
  ))

sylph_species <- sylph_species %>%
  group_by(Kingdom, Phylum, Class, Order, Family, Genus, Species) %>%
  summarise(across(where(is.numeric), sum, na.rm = TRUE), .groups = "drop")


# To select only samples with good quality
samples_keep <- metadata$clean_id[metadata$filter_analysis == "Y"]

# To keep only species in good quality samples
samples_in_order <- intersect(colnames(sylph_species), samples_keep)

# To build clean table
sylph_species_clean <- sylph_species %>%
  select(c(colnames(sylph_species)[1:7], samples_in_order))

#write_xlsx(sylph_species_clean, "merged_sylph_abundance_clean.xlsx")



# Cut-off at 0.1% relative abundance --------------------------------------
sample_names <- colnames(sylph_species_clean)[-c(1:7)]  # toutes les colonnes sauf "ID"
sylph_species_clean[sample_names] <- lapply(sylph_species_clean[sample_names], function(x) ifelse(x < 0.1, 0, x))

# To suppress all 0
sylph_species_clean <- sylph_species_clean %>%
  filter(if_any(all_of(sample_names), ~ .x != 0))

# To export final clean table ---------------------------------------------
write_xlsx(sylph_species_clean, "merged_sylph_abundance_0.1_clean.xlsx")


