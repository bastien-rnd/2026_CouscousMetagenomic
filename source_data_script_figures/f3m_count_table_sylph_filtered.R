# DESCRIPTION ----------------------------------------------------------------

#This script generate a clean and filtered (using sylph taxonomy) F3M counting table.


# PACKAGES ----------------------------------------------------------------
library(f3mr)
library(tidyverse)
library(readxl)
library(writexl)

source("colors.R")

# ANALYSIS ----------------------------------------------------------------

# To set working directory 
setwd("source_data_script_figures")
#setwd("your_working_directory")


# Taxonomic counting table
input_dir <- "merged_sylph_abundance_0.1_clean.xlsx" 
sylph_count <- read_excel(input_dir)

# Metadata on samples 
input_metadata <- "metadata_samples.xlsx"
metadata <- read_excel(input_metadata)

metadata <- metadata %>%
  filter(filter_analysis %in% c("Y")) %>%
  mutate(clean_id_copy = clean_id) %>%
  column_to_rownames("clean_id_copy")


# REFERENCE DATABASE INIT -------------------------------------------------

# Paths to annotation files
funct_annotations_path <- "f3m/all_specI_annotations_with_f3m_tags.tsv"
gtdb_classification_path <- "f3m/gtdb_db.tsv"
f3m_path <- "f3m/Food_Microbiomes_Metabolic_Modules_V1_1_0.tsv"

# To build the DB
cereals_ref_db <- build_ref_db(
  funct_annotations_path = funct_annotations_path,
  gtdb_classification_path = gtdb_classification_path
)


# IMPORT MULTIPLE SAMPLES -------------------------------------------------

# Path to the folder containing multiple sample files from f3m
folder_path <- "f3m/add_functions_and_species"

# Import and combine sample counts
all_sample_counts <- import_multiple_samples(folder_path = folder_path)

# Rename sample columns
all_sample_counts <- all_sample_counts %>%
  left_join(metadata %>% select(raw_id, clean_id),
            by = c("sample_name" = "raw_id")) %>%
  mutate(sample_name = coalesce(clean_id, sample_name)) %>%
  select(-clean_id)

# Removing bad quality samples
all_sample_counts <- all_sample_counts %>%
  filter(sample_name %in% metadata$clean_id)



# Taxonomic table ---------------------------------------------------------

gtdb_taxo <- read_tsv(gtdb_classification_path)

gtdb_taxo$species <- gsub("_[A-Za-z]\\b", "", gtdb_taxo$species)
gtdb_taxo$genus <- gsub("_[A-Za-z]\\b", "", gtdb_taxo$genus)
gtdb_taxo$family <- gsub("_[A-Za-z]\\b", "", gtdb_taxo$family)
gtdb_taxo$order <- gsub("_[A-Za-z]\\b", "", gtdb_taxo$order)
gtdb_taxo$class <- gsub("_[A-Za-z]\\b", "", gtdb_taxo$class)
gtdb_taxo$phylum <- gsub("_[A-Za-z]\\b", "", gtdb_taxo$phylum)

gtdb_taxo2 <- gtdb_taxo %>%
  select(c("domain", "phylum", "class", "order", "family", "genus", "species")) %>%
  distinct()


# To generate count table of F3M functions -----------------------------------------------------

# Transform gene and specI ID by species and functional gene
aggregated_counts <- aggregate_counts(
  all_sample_counts = all_sample_counts,
  ref_db = cereals_ref_db,
  taxonomic_level = "species",
  functional_level = "food_microbiome_functional_gene"
)

# Build a count matrix of F3M gene by sample
count_matrix <- build_count_matrix(
  aggregated_counts = aggregated_counts,
  deseq2 = TRUE 
)

# Deduplicate functional_gene (associated to multiple COG_KO)
f3m <- f3m %>%
  group_by(food_microbiome_functional_gene) %>%
  summarise(
    across(
      where(is.character),
      ~ paste(unique(.), collapse = " | ")
    ),
    .groups = "drop"
  )

# Export count matrix as a dataframe
export_df <- count_matrix %>%
  rownames_to_column(var ="test") %>%
  separate(test, into = c("species", "food_microbiome_functional_gene"), sep = "\\|") %>% 
  right_join(f3m, by = "food_microbiome_functional_gene") %>%
  select(
    species,
    main_module,
    food_microbiome_metabolic_module,
    food_microbiome_metabolic_function,
    food_microbiome_functional_gene,
    everything(),
    -food_microbiome_COG_KO
  )


# Link with sylph -----------------------------------------------------
meta_cols <- c("species", "main_module", "food_microbiome_metabolic_module", "food_microbiome_metabolic_function", "food_microbiome_functional_gene")
count_cols <- setdiff(colnames(export_df), meta_cols)

export_df$species <- gsub("_[A-Za-z]\\b", "", export_df$species)

export_df2 <- export_df %>%
  group_by(across(all_of(meta_cols))) %>%
  summarise(
    across(all_of(count_cols), sum, na.rm = TRUE),
    .groups = "drop"
  )

export_df3 <- export_df2[!is.na(export_df2$species), ]
export_df3$species <- paste0("s__", export_df3$species)

sample_cols <- colnames(sylph_count)[8:ncol(sylph_count)]
fixed_cols <- colnames(sylph_count)[1:7]
sylph_count <- sylph_count[, c(fixed_cols, count_cols)]

sylph_pa <- sylph_count %>%
  select(Species, all_of(count_cols)) %>%
  mutate(across(all_of(count_cols), \(x) as.integer(x > 0)))

pa_mat <- as.matrix(sylph_pa[, count_cols])
rownames(pa_mat) <- sylph_pa$Species


export_masked <- export_df3 %>%
  left_join(sylph_pa, by = c("species" = "Species"), suffix = c("", "_pa"))

for (s in sample_cols) {
  export_masked[[s]] <- ifelse(export_masked[[paste0(s, "_pa")]] == 0, 0, export_masked[[s]])
}

export_masked <- export_masked %>% select(-ends_with("_pa"))

export_masked <- export_masked %>%
  filter(if_any(all_of(count_cols), ~ . != 0))


export_masked_clean <- export_masked %>%
  mutate(species = gsub("s__", "", species)) %>%
  left_join(
    gtdb_taxo2 %>%
      select(domain, phylum, class, order, family, genus, species),
    by = "species"
  ) %>%
  select(domain, phylum, class, order, family, genus, species, main_module, food_microbiome_metabolic_module, food_microbiome_metabolic_function, food_microbiome_functional_gene, count_cols)


# EXPORT
write_xlsx(export_masked_clean, "f3m_count_table_sylph_filtered.xlsx")
