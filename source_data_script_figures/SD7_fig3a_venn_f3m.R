# DESCRIPTION ----------------------------------------------------------------

# This script generates Venn diagram of genes in couscous (n=19) and other fermented cereals (n=75) according to F3M annotation.


# PACKAGES ----------------------------------------------------------------
library(tidyverse)
library(readxl)
library(writexl)
library(ggvenn)
library(openxlsx)


source("colors.R")

# ANALYSIS ----------------------------------------------------------------

# To set working directory 
setwd("source_data_script_figures")
#setwd("your_working_directory")

# Metadata on samples 
input_metadata <- "metadata_samples.xlsx"
metadata <- read_excel(input_metadata)

metadata <- metadata %>%
  filter(filter_analysis %in% c("Y")) %>%
  mutate(clean_id_copy = clean_id) %>% 
  column_to_rownames("clean_id_copy")

# Data Sylph
data_sylph <- read_excel("f3m_count_table_sylph_filtered.xlsx")

# VENN -------------------------------------------------------

data_venn <- data_sylph %>%
  mutate(species_functions = paste(species, food_microbiome_functional_gene, sep = "__"))

# Sous-échantillonage pour couscous fermentés (n=19) vs others (n=75)
meta_cols <- c("domain", "phylum", "order", "class", "family", "genus", "species", "species_functions", "main_module", "food_microbiome_metabolic_module", "food_microbiome_metabolic_function", "food_microbiome_functional_gene")
data_couscous <- data_venn %>%
  select(all_of(meta_cols), matches("^(FMa|FMi|FSo|FMM)"))%>%
  filter(rowSums(across(-all_of(meta_cols))) > 0)
data_others <- data_venn %>%
  select(all_of(meta_cols), !matches("^(RMa|RMi|RSo|RMM|RPz|FMa|FMi|FSo|FMM)")) %>%
  filter(rowSums(across(-all_of(meta_cols))) > 0)

genes_couscous <- unique(data_couscous$species_functions)
genes_others <- unique(data_others$species_functions)
genes_only_couscous <- setdiff(genes_couscous, genes_others)
genes_only_others <- setdiff(genes_others, genes_couscous)
genes_common <- intersect(genes_couscous, genes_others)

venn_data <- list(
  "Couscous" = genes_couscous,
  "Others fermented cereals" = genes_others
)
p <- ggvenn(
  venn_data,
  fill_color = c("#E69F00", "#B0AFED"),
  stroke_size = 0.3,
  set_name_size = 7 / .pt,
  text_size = 0
)

custom_labels <- data.frame(
  x = c(-0.82, 0, 0.82), 
  y = c(0, 0, 0),      
  label = c(
    paste0(length(genes_only_couscous)),
    paste0(length(genes_common)),
    paste0(length(genes_only_others))
  )
)

# Final Venn
p_final <- p + 
  geom_text(
    data = custom_labels,
    aes(x = x, y = y, label = label),
    size = 5 / .pt
  ) + 
  expand_limits(
    x = c(-1.4, 1.4),
    y = c(-1.2, 1.8)
  ) +
  theme(
    panel.background = element_rect(fill = "white"),
    plot.background = element_rect(fill = "white")
    )
print(p_final)

# Export
ggsave(
  filename = "plots/SD7_fig3a_venn_f3m.png",
  plot = p_final,
  width = 58,
  height = 58,
  units = "mm",
  dpi = 300,
  bg = "white"
)

ggsave(
  filename = "plots/SD7_fig3a_venn_f3m.svg",
  plot = p_final,
  width = 58,
  height = 58,
  units = "mm"
  )



# Table source data----------------------------
# species_functions only in couscous
data_venn <- data_sylph %>%
  mutate(species_functions = paste(species, food_microbiome_functional_gene, sep = "__"))

meta_cols2 <- setdiff(meta_cols, "species_functions")

list_couscous <- data_venn %>%
  filter(species_functions %in% genes_only_couscous) %>%
  group_by(species_functions) %>%
  summarise(
    across(all_of(meta_cols2), first),                  
    across(where(is.numeric), sum, na.rm = TRUE),       
    .groups = "drop"
  )

list_others <- data_venn %>%
  filter(species_functions %in% genes_only_others) %>%
  group_by(species_functions) %>%
  summarise(
    across(all_of(meta_cols2), first),                 
    across(where(is.numeric), sum, na.rm = TRUE),       
    .groups = "drop"
  )

list_common <- data_venn %>%
  filter(species_functions %in% genes_common) %>%
  group_by(species_functions) %>%
  summarise(
    across(all_of(meta_cols2), first),                  
    across(where(is.numeric), sum, na.rm = TRUE),       
    .groups = "drop"
  )

# Export
wb <- createWorkbook()

addWorksheet(wb, "couscous_only")
addWorksheet(wb, "others_only")
addWorksheet(wb, "common")

writeData(wb, "couscous_only", list_couscous)
writeData(wb, "others_only", list_others)
writeData(wb, "common", list_common)

saveWorkbook(wb, "SD7_fig3a_venn_f3m.xlsx", overwrite = TRUE)
