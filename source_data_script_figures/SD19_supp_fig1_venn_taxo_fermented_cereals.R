# DESCRIPTION ----------------------------------------------------------------

# This script generates Venn diagram of genes in couscous (n=19) and other fermented cereals (n=75) according to taxonomic table (species-level).


# PACKAGES ----------------------------------------------------------------
library(tidyverse)
library(readxl)
library(writexl)
library(ggvenn)

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



# Venn ---------------------------------------------

# F vs NF -----------------------------------------------------------------

metadata_f <- metadata %>%
  filter(ferm == "yes")

samples_f <- metadata %>%
  filter(ferm == "yes") %>%
  pull(clean_id)

sylph_clean_f <- sylph_count %>%
  select(any_of(c("Family", "Genus", "Phylum", "Class", "Order", "Kingdom", "Species", samples_f)))

sylph_clean_f <- sylph_clean_f[
  rowSums(sylph_clean_f[samples_f] != 0) > 0, 
]

samples_yes <- metadata_f %>% filter(couscous == "Y") %>% pull(clean_id)
samples_no  <- metadata_f %>% filter(couscous == "N") %>% pull(clean_id)

sylph_clean_f <- sylph_count %>%
  select(any_of(c("Species", samples_yes, samples_no)))

sylph_clean_f <- sylph_clean_f %>% 
  filter(rowSums(select(., -Species) != 0) > 0)

species_yes <- sylph_clean_f %>%
  filter(rowSums(select(., all_of(samples_yes)) != 0) > 0) %>%
  pull(Species)

species_no <- sylph_clean_f %>%
  filter(rowSums(select(., all_of(samples_no)) != 0) > 0) %>%
  pull(Species)

venn_data <- list(`Couscous` = species_yes, `Others fermented cereals` = species_no)

ggvenn(
  venn_data,
  fill_color = c("#E69F00", "#B0AFED"),
  stroke_size = 0.3,
  set_name_size = 7 / .pt,
  text_size = 5 / .pt,
  show_percentage = FALSE
) 

# Export plot
ggsave(
  filename = "plots/SD19_supp_fig1_venn_taxo_fermented_cereals.png",  
  plot = last_plot(),              
  width = 40,
  height = 40,
  units = "mm",                     
  dpi = 300,                        
  bg = "white"
)

ggsave(
  filename = "plots/SD19_supp_fig1_venn_taxo_fermented_cereals.svg", 
  plot = last_plot(),       
  width = 40,
  height = 40,
  units = "mm"
)

#Export species list

unique_yes <- setdiff(species_yes, species_no)
unique_no  <- setdiff(species_no, species_yes)
shared     <- intersect(species_yes, species_no)

venn_table <- list(
  Unique_NF = data.frame(Species = unique_no),
  Unique_F = data.frame(Species = unique_yes),
  Common = data.frame(Species = shared),
  all_NF = data.frame(Species = species_no),
  all_F = data.frame(Species = species_yes)
  
)

write_xlsx(venn_table, "SD19_supp_fig1_venn_taxo_fermented_cereals.xlsx")

