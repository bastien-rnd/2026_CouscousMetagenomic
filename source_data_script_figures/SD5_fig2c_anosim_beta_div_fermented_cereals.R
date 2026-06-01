# DESCRIPTION ----------------------------------------------------------------

# This script generates a plot of ANOSIM results. ANOSIM were performed on Bray-Curtis distances across all fermented cereals (n=94) related to metadata.


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

metadata2 <- metadata %>%
  filter(ferm %in% "yes") %>%
  select(c("clean_id", "country", "cereals", "hulling", "soaking", "milling", "ferm_type", "backslopping", "ferm_duration"))



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



# PLOT -----------------------------------------------------------------

# Bray-Curtis distances + export table
bray_dist <- distance(phyloseq_template, method = "bray")

metadata_model <- metadata2
metadata_model <- metadata_model[
  match(labels(bray_dist), metadata_model$clean_id),
]
metadata_model <- metadata_model %>%
  select(-clean_id)


vars <- colnames(metadata_model)

results_anosim <- data.frame(
  Variable = vars,
  R = NA,
  p.value = NA
)

#ANOSIM
set.seed(123)

for(v in vars){
  grp <- metadata_model[[v]]
  
  if(length(unique(grp)) > 1){
    res <- anosim(bray_dist, grp, permutations = 999)
    results_anosim[results_anosim$Variable == v, "R"] <- res$statistic
    results_anosim[results_anosim$Variable == v, "p.value"] <- res$signif
  } else {
    results_anosim[results_anosim$Variable == v, "R"] <- NA
    results_anosim[results_anosim$Variable == v, "p.value"] <- NA
  }
}

print(results_anosim)

# Export Excel
#write_xlsx(results_anosim, "SD5_fig2c_anosim_beta_div_fermented_cereals.xlsx")




# PLOT --------------------------------------------------------------------


results_anosim <- results_anosim %>%
  mutate(
    Variable = dplyr::recode(Variable,
                             backslopping         = "Backslopping",
                             country       = "Country",
                             cereals       = "Cereals",
                             ferm_type    = "Fermentation type",
                             milling       = "Milling type",
                             ferm_duration     = "Fermentation duration",
                             hulling       = "Hulling",
                             soaking       = "Soaking"
    ),
    Significant = p.value < 0.05 
  )


# Plot
ggplot(results_anosim,
       aes(x = R,
           y = reorder(Variable, R),
           fill = Significant)) +
  geom_bar(stat = "identity", width = 0.7) +
  geom_vline(xintercept = 0, color = "grey20", linewidth = 0.25) +
  scale_fill_manual(
    values = c("TRUE" = "#748CE3", "FALSE" = "grey80"),
    labels = c("TRUE" = "p < 0.05", "FALSE" = "NS")
  ) +
  labs(
    x = "ANOSIM R Statistics",
    y = "",
    fill = ""
  ) +
  scale_x_continuous(breaks = seq(-1, 1, by = 0.2)) +
  theme(
    panel.background = element_rect(fill = "white"),
    plot.background  = element_rect(fill = "white"),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.title = element_text(size = 7),
    axis.text  = element_text(size = 6, color = "black"),
    axis.ticks = element_line(color = "black", linewidth = 0.25),
    axis.line  = element_line(color = "black", linewidth = 0.25),
    axis.title.x = element_text(margin = margin(t = 10)),
    legend.text = element_text(size = 5),
    legend.key.size = unit(4, "mm"),
    
  )

ggsave(
  filename = "plots/SD5_fig2c_anosim_beta_div_fermented_cereals.png",  
  plot = last_plot(),            
  width = 200,            
  height = 70,
  units = "mm",
  dpi = 300,                    
  bg = "white"
)

ggsave(
  filename = "plots/SD5_fig2c_anosim_beta_div_fermented_cereals.svg", 
  plot = last_plot(),         
  width = 200,             
  height = 70,
  units = "mm"
)
