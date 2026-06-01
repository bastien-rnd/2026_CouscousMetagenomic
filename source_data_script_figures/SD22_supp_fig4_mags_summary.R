# DESCRIPTION ----------------------------------------------------------------

# This script generates the plot related to the Metagenome Assembled Genomes (MAGs) reconstructed from couscous.


# PACKAGES ----------------------------------------------------------------
library(tidyverse)
library(readxl)
library(writexl)
library(circlize)
library(ComplexHeatmap)


source("colors.R")

# ANALYSIS ----------------------------------------------------------------

# To set working directory 
setwd("C:/Users/2023br002/Documents/1 - PhD DOMINO/8 - Papers/1_couscous_bdd/source/")
#setwd("your_working_directory")

# Metadata on samples 
input_metadata <- "metadata_samples.xlsx"
metadata <- read_excel(input_metadata)

input_summary <- "mags_summary.tsv"
mags <- read_tsv(input_summary)


# 0 - TRI DES ECHANTILLONS ----------------------------------------------------
metadata <- metadata %>%
  filter(filter_analysis %in% c("Y")) %>% # filtre échantillons <300k reads
  mutate(clean_id_copy = clean_id) %>% 
  column_to_rownames("clean_id_copy")




# FILTRAGE MAGs ------------------------------------------------------------
mags_f <- mags %>%
  filter(origin %in% c("couscous", "cfmd")) %>%
  filter(!grepl("^R", clean_id)) %>%
  filter(Quality != "LQ")

# SELECTION FAMILLES -------------------------------------------------------
mags_subset <- mags_f %>%
  filter(family %in% c("Lactobacillaceae", "Streptococcaceae"))

top_species <- mags_subset %>%
  dplyr::count(species, sort = TRUE) %>%
  pull(species)

mags_top <- mags_subset %>%
  filter(species %in% top_species)

# RENAME + FUSION TYPES ----------------------------------------------------
mags_top2 <- mags_top %>%
  mutate(
    type2 = case_when(
      grepl("^cfmd_", type) ~ "Others\nfermented\ncereals",
      type == "couscous"    ~ "Couscous",
      TRUE                  ~ type
    )
  )

# MATRICE HEATMAP ----------------------------------------------------------
mat <- mags_top2 %>%
  dplyr::count(type2, species) %>%
  pivot_wider(
    names_from = type2,
    values_from = n,
    values_fill = list(n = 0)
  ) %>%
  column_to_rownames("species") %>%
  as.matrix()

# Espèces à forcer en premier
priority_species <- c("Limosilactobacillus pontis", "Weissella cibaria")

# Sécurité : garder seulement celles présentes dans la matrice
priority_species <- priority_species[priority_species %in% rownames(mat)]

# Autres espèces
other_species <- setdiff(rownames(mat), priority_species)

# Ordre croissant :
# 1) ligne Couscous
# 2) puis ligne Fermented cereals
ord_other <- other_species[
  order(
    mat[other_species, "Couscous"],
    mat[other_species, "Others\nfermented\ncereals"]
  )
]

row_order <- c(priority_species, ord_other)
mat <- mat[row_order, , drop = FALSE]

# PALETTE COULEURS ---------------------------------------------------------
col_fun <- colorRamp2(
  c(0, max(mat) / 2, max(mat)),
  c("white", "#eedf63", "#d26d41")
)

ht <- Heatmap(
  mat,
  name = "# MAGs",
  col = col_fun,
  cluster_rows = FALSE,
  cluster_columns = FALSE,
  show_row_names = TRUE,
  show_column_names = TRUE,
  row_names_gp = gpar(fontsize = 5),
  column_names_gp = gpar(fontsize = 7),
  border = T,
  border_gp = gpar(
    col = "black",     # couleur
    lwd = 0.25,         # épaisseur
    lty = 1            # type de ligne (1 = plein, 2 = pointillé, etc.)
  ),
  heatmap_legend_param = list(
    title_gp = gpar(fontsize = 7),   # titre en bold
    labels_gp = gpar(fontsize = 5)   # valeurs en bold
  ),
  cell_fun = function(j, i, x, y, width, height, fill) {
    value <- mat[i, j]
    if (value != 0) {
      grid.text(value, x, y, gp = gpar(fontsize = 5))
    }
  }
)

draw(ht)

# DRAW --------------------------------------------------------------------
png("plots/SD09_fig3c_mags_summary.png", width = 65, height = 110, units = "mm", res = 300) 
draw(ht)
dev.off()

svg("plots/SD09_fig3c_mags_summary.svg", width = 65/25.4, height = 140/25.4)
draw(ht)
dev.off()



# PLOT HISTO --------------------------------------------------------------

labs_families <- c("Lactobacillaceae", "Streptococcaceae")

bar_df <- mags_f %>%
  mutate(
    type2 = case_when(
      grepl("^cfmd_", type) ~ "Others\nfermented\ncereals",
      type == "couscous"    ~ "Couscous",
      TRUE                 ~ type
    ),
    MAG_type = ifelse(family %in% labs_families, "LABs", "Non-LABs")
  ) %>%
  dplyr::count(type2, MAG_type)

bar_df$type2 <- factor(
  bar_df$type2,
  levels = c("Couscous", "Others\nfermented\ncereals")
)

bar_df$MAG_type <- factor(
  bar_df$MAG_type,
  levels = c("LABs", "Non-LABs")
)

p <- ggplot(bar_df, aes(x = type2, y = n, fill = MAG_type)) +
  geom_col(
    width = 0.7,
    color = "black",
    linewidth = 0.25   # épaisseur des contours des barres
  ) +
  scale_fill_manual(
    values = c(
      "LABs" = "#60A7F0",
      "Non-LABs" = "#A7AEB5"
    )
  ) +
  labs(
    x = NULL,
    y = "Number of total MAGs",
    fill = "MAG type"
  ) +
  scale_y_continuous(
    limits = c(0, 200),
    breaks = seq(0, 200, by = 50)
  ) +  
  theme(
    panel.background = element_rect(fill = "white"),
    plot.background  = element_rect(fill = "white"),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),

    legend.title = element_text(size = 7),
    legend.text  = element_text(size = 5),
    axis.text    = element_text(size = 5),
    axis.title.y = element_text(size = 5),
    legend.key.size = unit(3, "mm"),
    
    # bordure externe
    panel.border = element_rect(
      colour = "black",
      fill = NA,
      linewidth = 0.25
    )
  )

p


ggsave(
  filename = "plots/SD09_fig3c_barplot.png",
  plot = p,
  width = 50,
  height = 40,
  dpi = 300,
  units = "mm",
  bg = "white"
)

ggsave(
  filename = "plots/SD09_fig3c_barplot.svg",
  plot = p,
  width = 50,
  height = 40,
  units = "mm"
  )














