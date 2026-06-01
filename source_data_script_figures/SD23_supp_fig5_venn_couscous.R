 # DESCRIPTION ----------------------------------------------------------------

# This script generates Venn diagram of species in cereal flours (n=19) and couscous (n=19) depending cereals.


# PACKAGES ----------------------------------------------------------------

library(tidyverse)
library(writexl)
library(readxl)
library(openxlsx)
library(ggvenn)
library(VennDiagram)


# ANALYSIS ----------------------------------------------------------------

# To set working directory 
setwd("Metagenome Assembled Genomes (MAGs) from couscous compared to publicly available MAGs from other fermented cereals")
#setwd("your_working_directory")

# Metadata on samples 
input_metadata <- "metadata_samples.xlsx"
metadata <- read_excel(input_metadata)

metadata <- metadata %>%
  filter(filter_analysis %in% c("Y")) %>%
  mutate(clean_id_copy = clean_id) %>% 
  column_to_rownames("clean_id_copy")

# Metadata cereal flours and couscous
metadata_f <- metadata %>%
  filter(product == "couscous")

# Data Sylph
input_dir <- "merged_sylph_abundance_0.1_clean.xlsx" 
sylph_count <- read_excel(input_dir)


#VENN -----------------------------------------------------

samples_f <- metadata_f %>%
  pull(clean_id)

sylph_clean_f <- sylph_count %>%
  select(any_of(c("Family", "Genus", "Phylum", "Class", "Order", "Kingdom", "Species", samples_f)))

# to change the argument "ferm" in yes or no to generate both figures
samples_millet <- metadata_f %>% filter(cereals == "millet" & ferm == "yes") %>% pull(clean_id)
samples_maize  <- metadata_f %>% filter(cereals == "maize" & ferm == "yes") %>% pull(clean_id)
samples_mm  <- metadata_f %>% filter(cereals == "millet_maize" & ferm == "yes") %>% pull(clean_id)
samples_sorghum  <- metadata_f %>% filter(cereals == "sorghum" & ferm == "yes") %>% pull(clean_id)

sylph_clean_f <- sylph_clean_f %>%
  select(any_of(c("Species", samples_millet, samples_maize, samples_mm, samples_sorghum)))

sylph_clean_f <- sylph_clean_f %>% 
  filter(rowSums(select(., -Species) != 0) > 0)

species_millet <- sylph_clean_f %>%
  filter(rowSums(select(., all_of(samples_millet)) != 0) > 0) %>%
  pull(Species)

species_maize <- sylph_clean_f %>%
  filter(rowSums(select(., all_of(samples_maize)) != 0) > 0) %>%
  pull(Species)

species_mm <- sylph_clean_f %>%
  filter(rowSums(select(., all_of(samples_mm)) != 0) > 0) %>%
  pull(Species)

species_sorghum <- sylph_clean_f %>%
  filter(rowSums(select(., all_of(samples_sorghum)) != 0) > 0) %>%
  pull(Species)

venn_data <- list("Maize" = species_maize, "Millet-Maize" = species_mm, "Millet" = species_millet, "Sorghum" = species_sorghum)

ggvenn(
  venn_data,
  fill_color = c("#F8766D", "#987116","#7CAE00", "#6d6bef"),
  fill_alpha = 0.4,
  stroke_size = 0.8,
  set_name_size = 2, 
  text_size = 2,
  show_percentage = FALSE
) 

# Export

ggsave(
  filename = "plots/SD23_supp_fig5_venn_couscous.png", 
  plot = last_plot(),              
  width = 85,                      
  height = 58,
  units = "mm",
  dpi = 300,             
  bg = "white"
)

ggsave(
  filename = "plots/SD23_supp_fig5_venn_couscous.svg", 
  plot = last_plot(),              
  width = 85,                      
  height = 58,
  units = "mm",
)





