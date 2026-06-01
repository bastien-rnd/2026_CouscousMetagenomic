# DESCRIPTION ----------------------------------------------------------------

# This script generates PCoA of Beta-diversity across cereal flours (n=19) and couscous (n=19).


# PACKAGES ----------------------------------------------------------------
library(tidyverse)
library(readxl)
library(writexl)
library(phyloseq)

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

phyloseq_template <- subset_samples(phyloseq_all, couscous == "Y")


# PLOT -----------------------------------------------------------------

# Bray-Curtis distances + export table
bray_curtis_dist_template <- phyloseq::distance(phyloseq_template, method = "bray")
bray_curtis_mat <- as.matrix(bray_curtis_dist_template)
bray_curtis_df <- data.frame(Sample = rownames(bray_curtis_mat),
                             bray_curtis_mat,
                             check.names = FALSE)
write_xlsx(bray_curtis_df, "SD12_fig4a_beta_div_couscous.xlsx")

# PCoA
pcoa_result_template <- ordinate(phyloseq_template, method = "PCoA", distance = bray_curtis_dist_template)
explained_variance_pcoa_template <- (pcoa_result_template$values$Eigenvalues / sum(pcoa_result_template$values$Eigenvalues)) * 100
pc1_percentage_template <- round(explained_variance_pcoa_template[1], 2)
pc2_percentage_template <- round(explained_variance_pcoa_template[2], 2)


# PLOT
colors_vector <- colors[["cereals"]]

plot_ordination(phyloseq_template, pcoa_result_template, color = "cereals", shape = "ferm") +
  geom_point(size = 0.5, stroke = 0.5) + 
  stat_ellipse(aes(group = ferm), type = "norm", linetype = "solid", size = 0.5, alpha = 0.3) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") + 
  geom_vline(xintercept = 0, linetype = "dashed", color = "black") + 
  scale_color_manual(values = colors_vector, breaks = names(colors_vector)) +
  labs(
    title = paste(""),
    x = paste("PCoA 1 (", round(pc1_percentage_template, 0), "%)", sep = ""),
    y = paste("PCoA 2 (", round(pc2_percentage_template, 0), "%)", sep = ""),
    color = "Cereals",
    shape = "Fermentation",
    
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

# To export plot
ggsave(
  filename = "plots/SD11_fig4a_beta_div_couscous.png",
  plot = last_plot(),
  width = 88,
  height = 60,
  dpi = 300,    
  units = "mm", 
  bg = "white"
)

ggsave(
  filename = "plots/SD11_fig4a_beta_div_couscous.svg",
  plot = last_plot(),
  width = 88,
  height = 60,
  units = "mm",
)


