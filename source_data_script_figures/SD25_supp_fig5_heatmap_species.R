# DESCRIPTION ----------------------------------------------------------------

# This script generates histogram of microbial genus across fermented cereals (n=94)


# PACKAGES ----------------------------------------------------------------
library(tidyverse)
library(readxl)
library(writexl)
library(phyloseq)
library(cowplot)
library(ComplexHeatmap)
library(circlize)
library(RColorBrewer)


# ANALYSIS ----------------------------------------------------------------

# To set working directory 
setwd("Documents/1 - PhD DOMINO/8 - Papers/1_couscous_bdd/source/source_data_script_figures")
#setwd("your_working_directory")
source("colors.R")


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

# PHYLOSEQ -------------------------------------------------------------

tax_bdd <- sylph_count %>% 
  select(1:7) %>%
  mutate(Species_rownames = Species) %>% 
  column_to_rownames("Species_rownames")

tax_bdd <- as.matrix(tax_bdd)

otu_bdd <- sylph_count %>% 
  select(-c(1:6)) %>%
  column_to_rownames("Species") 
otu_bdd <- as.matrix(otu_bdd)


TAX = tax_table(tax_bdd)
OTU = otu_table(otu_bdd, taxa_are_rows = TRUE)
samples = sample_data(metadata)

phyloseq_all <- phyloseq(OTU, TAX, samples)

phyloseq_f <- subset_samples(phyloseq_all, ferm == "yes")



# Heatmap -----------------------------------------------------------------

# -----------------------------
# Fonction Heatmap
# -----------------------------

make_tax_heatmap <- function(ps,
                             tax_level = "Genus",
                             top_n = NULL,
                             filter_tax_level = NULL,
                             filter_tax_value = NULL,
                             var1 = "product",
                             var2 = "cereals") {
  # -----------------------------
  # Extraction phyloseq
  # -----------------------------

  ps_df <- psmelt(ps)

  ps_df <- ps_df %>%
  mutate(
    Abundance = Abundance / 100
  )

  # -----------------------------
# Filtre taxonomique parent
# -----------------------------

if (!is.null(filter_tax_level) &
    !is.null(filter_tax_value)) {

  ps_df <- ps_df %>%
    filter(
      .data[[filter_tax_level]] %in% filter_tax_value
    )
}

  annotation_vars <- c(var1, var2)


  # -----------------------------
  # Ordre des samples
  # -----------------------------

  sample_order <- ps_df %>%
    distinct(Sample, across(all_of(annotation_vars))) %>%
    arrange(
      .data[[var1]],
      .data[[var2]]
    ) %>%
    pull(Sample)



  # -----------------------------
  # Agrégation taxonomique
  # -----------------------------

  tax_df <- ps_df %>%
  mutate(
    !!tax_level := replace_na(.data[[tax_level]], "Unclassified")
  ) %>%
  group_by(
    .data[[tax_level]],
    Sample
  ) %>%
  summarise(
    Abundance = sum(Abundance),
    .groups = "drop"
  )

  # -----------------------------
  # Sélection top taxons optionnelle
  # -----------------------------

  if (!is.null(top_n)) {

    top_taxa <- tax_df %>%
      group_by(.data[[tax_level]]) %>%
      summarise(
        total = sum(Abundance),
        .groups = "drop"
      ) %>%
      arrange(desc(total)) %>%
      slice_head(n = top_n) %>%
      pull(.data[[tax_level]])

    tax_df <- tax_df %>%
      filter(.data[[tax_level]] %in% top_taxa)
  }



  # -----------------------------
  # Matrice heatmap
  # -----------------------------

  mat <- tax_df %>%
    select(
      Sample,
      !!sym(tax_level),
      Abundance
    ) %>%
    pivot_wider(
      names_from = Sample,
      values_from = Abundance,
      values_fill = 0
    ) %>%
    column_to_rownames(tax_level) %>%
    as.matrix()

  # Supprimer les taxons absents de tous les échantillons
  mat <- mat[rowSums(mat) > 0, , drop = FALSE]
  
  # Trier les taxons par abondance totale décroissante
  mat <- mat[order(rowSums(mat), decreasing = TRUE), , drop = FALSE]

  mat <- mat[, sample_order[sample_order %in% colnames(mat)], drop = FALSE]



  # -----------------------------
  # Annotation samples
  # -----------------------------

  annotation_col <- ps_df %>%
  distinct(Sample, across(all_of(annotation_vars))) %>%
  column_to_rownames("Sample") %>%
  .[colnames(mat), annotation_vars, drop = FALSE]


  # ordre affichage : var1 en haut, var2 en dessous
  annotation_col <- annotation_col[, c(var2, var1), drop = FALSE]


  # couleurs annotations
  annotation_colors <- list(
    colors[[var1]],
    colors[[var2]]
  )

  names(annotation_colors) <- c(var1, var2)

  # -----------------------------
  # Heatmap
  # -----------------------------

  p <- pheatmap(
    mat,
    color = c(
    "#000000",
    "#0e653b",
    "#44bd83",
    "#6BAED6",
    "#DEEBF7"
    ),
    breaks = c(
      0,
      0.01,
      0.1,
      0.5,
      1
    ),
    legend_breaks = c(0, 0.01, 0.1, 0.5, 1),
    legend_labels = c("0", "0.01", "0.1", "0.5", "1"),
    annotation_col = annotation_col,
    annotation_colors = annotation_colors,
    cluster_cols = FALSE,
    show_colnames = FALSE,
    cluster_rows = FALSE,
    border_color = NA,
    fontsize_row = 8,
    fontsize_col = 8
  )

}


p <- make_tax_heatmap(
  phyloseq_f,
  tax_level = "Species",
  filter_tax_level = "Family",
  filter_tax_value = "f__Lactobacillaceae",
  var1 = "product",
  var2 = "cereals"
)

p

svg(
  "plots/heatmap_lactobacillaceae_species.svg",
  width = 10,
  height = 12
)

draw(p)

dev.off()

png(
  "plots/heatmap_lactobacillaceae_species.png",
  width = 10,
  height = 12,
  units = "in",
  res = 300
)

draw(p)

dev.off()
