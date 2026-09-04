# DESCRIPTION ----------------------------------------------------------------

# Ce script genere les PCoA de beta-diversite pour les cereales fermentees (n=94)
# en utilisant trois metriques complementaires :
#   - Bray-Curtis   (abondance, non compositionnelle)
#   - Jaccard       (presence/absence)
#   - Aitchison     (CLR + distance euclidienne, adaptee aux donnees compositionnelles)
# Pour chaque metrique, l'homogeneite de la dispersion multivariee (PERMDISP) est
# testee via vegan::betadisper() + permutest(), et les differences entre centroides
# de groupes sont testees via une PERMANOVA (vegan::adonis2()).


# PACKAGES ----------------------------------------------------------------
library(tidyverse)
library(readxl)
library(writexl)
library(phyloseq)
library(vegan)

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

phyloseq_template <- subset_samples(phyloseq_all, ferm == "yes")


# FONCTIONS UTILITAIRES --------------------------------------------------

# Transformation CLR (centered log-ratio) -> utilisee pour la distance d'Aitchison.
# Un pseudocount (moitie de la plus petite valeur non-nulle) remplace les zeros,
# car le log n'est pas defini en 0.
make_clr_phyloseq <- function(ps, pseudocount = NULL) {
  otu <- as(otu_table(ps), "matrix")  # taxa_are_rows = TRUE -> taxons en lignes, echantillons en colonnes
  if (is.null(pseudocount)) {
    pseudocount <- min(otu[otu > 0], na.rm = TRUE) / 2
  }
  otu[otu == 0] <- pseudocount
  log_otu <- log(otu)
  clr_otu <- sweep(log_otu, 2, colMeans(log_otu), "-")  # CLR calcule par echantillon (colonne)
  OTU_clr <- otu_table(clr_otu, taxa_are_rows = TRUE)
  phyloseq(OTU_clr, tax_table(ps), sample_data(ps))
}

# Fonction principale : calcule la distance, la PCoA, le test de dispersion (PERMDISP),
# genere le plot et exporte les fichiers.
run_beta_diversity <- function(ps,
                                distance_method = c("bray", "jaccard", "aitchison"),
                                group_var = "product",
                                ellipse_group = "couscous",
                                dispersion_var = "couscous",
                                output_prefix,
                                n_perm = 999) {
  distance_method <- match.arg(distance_method)

  if (distance_method == "aitchison") {
    ps_for_ord <- make_clr_phyloseq(ps)
    dist_obj <- phyloseq::distance(ps_for_ord, method = "euclidean")
  } else if (distance_method == "jaccard") {
    ps_for_ord <- ps
    dist_obj <- phyloseq::distance(ps, method = "jaccard", binary = TRUE)
  } else {
    ps_for_ord <- ps
    dist_obj <- phyloseq::distance(ps, method = "bray")
  }

  # Export de la matrice de distance
  dist_mat <- as.matrix(dist_obj)
  dist_df <- data.frame(Sample = rownames(dist_mat), dist_mat, check.names = FALSE)
  write_xlsx(dist_df, paste0(output_prefix, "_", distance_method, ".xlsx"))

  # PCoA
  pcoa_res <- ordinate(ps_for_ord, method = "PCoA", distance = dist_obj)
  explained_var <- (pcoa_res$values$Eigenvalues / sum(pcoa_res$values$Eigenvalues)) * 100
  pc1 <- round(explained_var[1], 2)
  pc2 <- round(explained_var[2], 2)

  # Homogeneite de la dispersion multivariee (PERMDISP)
  # -> testee sur la meme variable que celle utilisee pour les ellipses (dispersion_var)
  groups <- as.factor(sample_data(ps)[[dispersion_var]])
  disp <- betadisper(dist_obj, groups)
  disp_permtest <- permutest(disp, permutations = n_perm)

  cat("\n==== ", output_prefix, " - ", distance_method,
      " : homogeneite de dispersion (PERMDISP) sur '", dispersion_var, "' ====\n")
  print(disp_permtest)

  # PERMANOVA (differences entre centroides des groupes)
  meta_df <- data.frame(sample_data(ps))
  permanova_formula <- as.formula(paste("dist_obj ~", dispersion_var))
  permanova_res <- adonis2(permanova_formula, data = meta_df, permutations = n_perm)

  cat("\n==== ", output_prefix, " - ", distance_method,
      " : PERMANOVA sur '", dispersion_var, "' ====\n")
  print(permanova_res)

  # PLOT
  colors_vector <- colors[[group_var]]

  p <- plot_ordination(ps_for_ord, pcoa_res, color = group_var) +
    geom_point(size = 0.5, stroke = 0.5) +
    stat_ellipse(aes(group = .data[[ellipse_group]]), type = "norm",
                 linetype = "solid", linewidth = 0.5, alpha = 0.3) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "black", linewidth = 0.25) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "black", linewidth = 0.25) +
    scale_color_manual(values = colors_vector, breaks = names(colors_vector)) +
    labs(
      title = "",
      x = paste0("PCoA 1 (", round(pc1, 0), "%)"),
      y = paste0("PCoA 2 (", round(pc2, 0), "%)"),
      color = "Product",
      shape = "Couscous"
    ) +
    theme(
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white"),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      panel.border = element_rect(color = "black", fill = NA, linewidth = 0.5),
      legend.title = element_text(size = 7),
      legend.text = element_text(size = 5),
      legend.key.size = unit(3, "mm"),
      axis.title = element_text(size = 7),
      axis.text = element_text(size = 5),
      axis.ticks = element_line(linewidth = 0.25),
      axis.ticks.length = unit(1, "mm"),
      plot.title = element_text(hjust = 0.5, size = 5)
    )

  ggsave(filename = paste0("plots/", output_prefix, "_", distance_method, ".png"),
         plot = p, width = 121, height = 70, units = "mm", dpi = 300, bg = "white")
  ggsave(filename = paste0("plots/", output_prefix, "_", distance_method, ".svg"),
         plot = p, width = 121, height = 70, units = "mm")

  list(plot = p, dist = dist_obj, pcoa = pcoa_res,
       betadisper = disp, permutest = disp_permtest,
       permanova = permanova_res)
}

# Extrait les resultats du test PERMDISP sous forme de ligne de tableau
summarize_permdisp <- function(permtest_obj, distance_method, dispersion_var = "couscous") {
  tab <- permtest_obj$tab
  data.frame(
    distance_metric = distance_method,
    dispersion_var  = dispersion_var,
    Df_groups       = tab$Df[1],
    Df_residuals    = tab$Df[2],
    Sum_Sq_groups   = tab$`Sum Sq`[1],
    Mean_Sq_groups  = tab$`Mean Sq`[1],
    F_value         = tab$F[1],
    N_perm          = permtest_obj$control$nperm,
    p_value         = tab$`Pr(>F)`[1]
  )
}

# Extrait les resultats PERMANOVA (adonis2) sous forme de ligne de tableau
summarize_permanova <- function(permanova_obj, distance_method, dispersion_var = "couscous", n_perm = 999) {
  data.frame(
    distance_metric = distance_method,
    dispersion_var  = dispersion_var,
    Df_groups       = permanova_obj$Df[1],
    Df_residuals    = permanova_obj$Df[2],
    SumOfSqs_groups = permanova_obj$SumOfSqs[1],
    R2              = permanova_obj$R2[1],
    F_value         = permanova_obj$F[1],
    N_perm          = n_perm,
    p_value         = permanova_obj$`Pr(>F)`[1]
  )
}


# EXECUTION : les 3 metriques --------------------------------------------

res_bray <- run_beta_diversity(
  phyloseq_template, "bray",
  output_prefix = "SD4_raw_fig2b_beta_div_fermented_cereals"
)

res_jaccard <- run_beta_diversity(
  phyloseq_template, "jaccard",
  output_prefix = "SD4_fig2b_beta_div_fermented_cereals"
)

res_aitchison <- run_beta_diversity(
  phyloseq_template, "aitchison",
  output_prefix = "SD4_fig2b_beta_div_fermented_cereals"
)

# Tableau recapitulatif des tests d'homogeneite de dispersion
permdisp_summary <- bind_rows(
  summarize_permdisp(res_bray$permutest, "Bray-Curtis"),
  summarize_permdisp(res_jaccard$permutest, "Jaccard"),
  summarize_permdisp(res_aitchison$permutest, "Aitchison")
)

write_xlsx(permdisp_summary, "SD4_betadisper_summary.xlsx")
print(permdisp_summary)

# Tableau recapitulatif des PERMANOVA
permanova_summary <- bind_rows(
  summarize_permanova(res_bray$permanova, "Bray-Curtis"),
  summarize_permanova(res_jaccard$permanova, "Jaccard"),
  summarize_permanova(res_aitchison$permanova, "Aitchison")
)

write_xlsx(permanova_summary, "SD4_permanova_summary.xlsx")
print(permanova_summary)
