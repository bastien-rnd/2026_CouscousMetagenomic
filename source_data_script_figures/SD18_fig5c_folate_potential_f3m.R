# DESCRIPTION ----------------------------------------------------------------

# This script generates the heatmap folate content and bacterial folate biosynthetic genes in cereal flours and couscous.

# PACKAGES ----------------------------------------------------------------
library(tidyverse)
library(readxl)
library(writexl)
library(grid)
library(ComplexHeatmap)
library(svglite)



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

metadata_f <- metadata %>%
  filter(couscous %in% "Y")


# F3M HISTOGRAM ----------------------------------------
## Data preprocess -------------------------------------

### Import F3M table -----------------------------------
f3m_table <- read_excel("f3m_count_table_sylph_filtered.xlsx")

# Vector of variables
meta_cols <- c("domain", "phylum", "order", "class", "family", "genus", "species", "main_module", "food_microbiome_metabolic_module", "food_microbiome_metabolic_function", "food_microbiome_functional_gene")
count_cols <- setdiff(colnames(f3m_table), meta_cols)

# If necessary, to subsample the initial table
count_cols <- intersect(count_cols, metadata_f$clean_id) 
f3m_table <- f3m_table %>%
  select(all_of(c(meta_cols, count_cols)))

# Folate heatmap --------------------------------------------------------------
data_folate <- f3m_table %>%
  filter(food_microbiome_metabolic_module == "F3MF_07_folate_tetrahydrofolate_biosynthesis")

sample_cols <- grep("^(R|F)", colnames(data_folate), value = TRUE)

data_folate[sample_cols] <- lapply(data_folate[sample_cols], function(x) ifelse(x != 0, 1, 0))

gene_counts <- data_folate %>%
  select(species, food_microbiome_functional_gene, all_of(sample_cols)) %>%
  group_by(species) %>%
  summarise(across(all_of(sample_cols), ~ sum(.x > 0)), .groups = "drop") %>%
  filter(rowSums(across(all_of(sample_cols))) > 0) 

gene_counts_bin <- gene_counts

gene_counts_bin[,-1] <- lapply(gene_counts_bin[,-1], function(x) ifelse(x > 0, 1, 0))

target_genes <- c(
  "F3MF_07_F058_Dihydropteroate_synthase_folP",
  "F3MF_07_F056_2-amino-4-hydroxy-6-hydroxymethyldihydropteridine_diphosphokinase_folK"
)

species_with_both_genes_wide <- data_folate %>%
  filter(food_microbiome_functional_gene %in% target_genes) %>%
  select(species, all_of(sample_cols), food_microbiome_functional_gene) %>%
  pivot_longer(cols = all_of(sample_cols), names_to = "sample", values_to = "presence") %>%
  filter(presence == 1) %>% 
  group_by(species, sample) %>%
  summarise(n_genes_present = n(), .groups = "drop") %>%  
  filter(n_genes_present == length(target_genes)) %>% 
  pivot_wider(
    names_from = sample,
    values_from = n_genes_present,
    values_fill = 0
  )

species_with_both_genes_wide[,-1] <- lapply(species_with_both_genes_wide[,-1], function(x) ifelse(x > 0, 1, 0))

gene_counts_bin <- as.data.frame(gene_counts_bin)

sample_order <- colnames(gene_counts_bin)[-1]

species_with_both_genes_wide <- species_with_both_genes_wide %>%
  select(species, all_of(sample_order))


for (sp in species_with_both_genes_wide$species) {
  rows <- which(gene_counts_bin$species == sp)
  if (length(rows) > 0) {
    cols <- which(as.numeric(species_with_both_genes_wide[species_with_both_genes_wide$species == sp, -1]) == 1)
    if (length(cols) > 0) {
      gene_counts_bin[rows, cols + 1] <- 2
    }
  }
}

#### NEED TO ADD THE VALUE 3 MANUALLY TO DISTINGUISH COMPLETE PATHWAY

# Metadata folate content
metadata <- read_excel("~/1 - PhD DOMINO/1 - WP4 - Microbial consortia/git_cereals/metadata_bdd.xlsx")
metadata_b9 <- metadata %>%
  filter(product %in% "couscous") %>%
  filter(filter_analysis %in% c("Y")) %>% 
  select(clean_id, `b9 (µg/100g)`)

# TAxonomic classification
gtdb_classification_path <- "f3m/gtdb_db.tsv"
gtdb_classification <- read_tsv(gtdb_classification_path)
gtdb_classification <- gtdb_classification %>%
  select(domain, phylum, class, order, family, genus, species) %>%
  mutate(
    species = gsub("_[A-Za-z]\\b", "", species),
    species = paste0("s__", species)
  ) %>%
  distinct(species, .keep_all = TRUE)

data <- read_excel("SD20_fig6c_folate_contributors_and_genes.xlsx")

data <- data %>%
  left_join(gtdb_classification, by = "species")

sample_cols <- grep("^(R|F)", colnames(data), value = TRUE)

sample_cols <- c(
  sort(sample_cols[grepl("^R", sample_cols)]),
  sort(sample_cols[grepl("^F", sample_cols)])
)

data <- data %>%
  rowwise() %>%
  mutate(max_value = max(c_across(all_of(sample_cols)), na.rm = TRUE)) %>%
  ungroup()


data_filtered <- data %>%
  rowwise() %>%
  mutate(max_value = max(c_across(all_of(sample_cols)), na.rm = TRUE)) %>%
  ungroup() %>%
  filter(max_value >= 2) %>%
  arrange(phylum, species)


# MATRIX
mat_filtered <- as.matrix(data_filtered[, sample_cols])
rownames(mat_filtered) <- data_filtered$species
colnames(mat_filtered) <- sample_cols

col_fun <- c("0" = "grey95", "1" = "#E08A79", "2" = "orange", "3" = "#B1D48E")

# Lactobacillaceae in bold
font_faces <- ifelse(data_filtered$family == "Lactobacillaceae", "bold", "plain")
font_colors <- rep("black", nrow(data_filtered))
#font_sizes <- rep(8, nrow(data_filtered))


# HEATMAP
b9_anno <- HeatmapAnnotation(
  "Folate\n(µg/100g\nFM)" = anno_barplot(
    metadata_b9$`b9 (µg/100g)`,
    border = TRUE,
    gp = gpar(fill = "grey50"),
    height = unit(2, "cm")
  ),
  annotation_name_gp = gpar(fontsize = 8, col = "black")
)

annot1 <- metadata %>%
  filter(clean_id %in% sample_cols) %>%   
  select(sample = clean_id, ferm)    

# annot2 : Cereals
annot2 <- metadata %>%
  filter(clean_id %in% sample_cols) %>%
  select(sample = clean_id, cereals)    

annot1 <- annot1 %>%
  dplyr::slice(match(colnames(mat_filtered), sample))
annot2 <- annot2 %>%
  dplyr::slice(match(colnames(mat_filtered), sample))

# Barre 1
product_anno <- HeatmapAnnotation(
  bar1 = anno_simple(
    annot1[["ferm"]],
    col = colors[["ferm"]],
    height = unit(0.5, "cm")
  ),
  annotation_name_gp = gpar(fontsize = 5)
)

# Barre 2
cereals_anno <- HeatmapAnnotation(
  bar2 = anno_simple(
    annot2[["cereals"]],
    col = colors[["cereals_couscous"]],
    height = unit(0.5, "cm")
  ),
  annotation_name_gp = gpar(fontsize = 5)
)

# Barplot b9
b9_anno <- HeatmapAnnotation(
  "Folate\n(µg/100g\nFM)" = anno_barplot(
    metadata_b9$`b9 (µg/100g)`,
    border = TRUE,
    gp = gpar(fill = "grey50"),
    height = unit(2, "cm")
  ),
  annotation_name_gp = gpar(fontsize = 5, col = "black")
)

top_annos <- HeatmapAnnotation(
  Fermentation = anno_simple(
    annot1$ferm,
    col = colors[["ferm"]],
    height = unit(0.2, "cm")
  ),
  Cereals = anno_simple(
    annot2$cereals,
    col = colors[["cereals"]],
    height = unit(0.2, "cm")
  ),
  "Folate\n(µg/100g\nFM)" = anno_barplot(
    metadata_b9$`b9 (µg/100g)`,
    border = TRUE,
    gp = gpar(fill = "grey50"),
    height = unit(1.5, "cm")
  ),
  annotation_name_gp = gpar(fontsize = 5, col = "black"),
  gap = unit(0.8, "mm")
  
)


ht <- Heatmap(
  mat_filtered,
  name = "Folate pathway",
  col = col_fun,
  border = TRUE,
  rect_gp = gpar(col = "grey50", lwd = 0.25),
  cluster_rows = TRUE,
  cluster_columns = F,
  show_row_names = TRUE,
  show_column_names = FALSE,
  row_names_gp = gpar(
    fontsize = 5,
    col = font_colors,
    fontface = font_faces
  ),
top_annotation = top_annos,
  heatmap_legend_param = list(
  at = c(0,1,2,3),
  labels = c(
    "No detected genes",
    "Incomplete pathway",
    "Incomplete pathway, including folK/folP",
    "Complete pathway"
  ),
  title_gp  = gpar(fontsize = 7),
  labels_gp = gpar(fontsize = 5),
  legend_height = unit(3, "cm"),
  grid_width  = unit(4, "mm"),
  grid_height = unit(4, "mm"),
  legend.key.size = unit(2, "mm"),
  border = "black"
)
)

draw(ht)

# Export
png("plots/SD18_fig5c_folate_potential_f3m.png", width = 185, height = 110, units = "mm", res = 300)
draw(ht, heatmap_legend_side = "right", gap = unit(3, "mm"))
dev.off()

svglite("plots/SD18_fig5c_folate_potential_f3m.svg",
        width = 185/25.4,
        height = 110/25.4)
draw(ht, heatmap_legend_side = "right", gap = unit(3, "mm"))
dev.off()
