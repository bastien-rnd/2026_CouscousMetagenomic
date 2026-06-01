# DESCRIPTION ----------------------------------------------------------------

# This script generates DESeq2 analysis and associated plot on bacterial species in cereal flours (n=19) and couscous (n=19)

# PACKAGES ----------------------------------------------------------------
library(tidyverse)
library(readxl)
library(writexl)
library(DESeq2)



source("colors.R")

# ANALYSIS ----------------------------------------------------------------

# To set working directory 
setwd("source_data_script_figures")
#setwd("your_working_directory")

# Metadata on samples 
input_metadata <- "metadata_samples.xlsx"
metadata <- read_excel(input_metadata)

# Taxonomic counting table
input_dir <- "merged_sylph_abundance_0.1_clean.xlsx" 
sylph_count <- read_excel(input_dir)

metadata <- metadata %>%
  filter(filter_analysis %in% c("Y")) %>% 
  mutate(clean_id_copy = clean_id) %>% 
  column_to_rownames("clean_id_copy")

metadata_f <- metadata %>%
  filter(couscous %in% "Y")






sample_names <- colnames(sylph_count)[-c(1:7)]  

# To extract total reads
total_seqs <- metadata[sample_names, "clean_reads"] %>% as.numeric()

# To convert as proportion
count_table <- sylph_count
count_table[sample_names] <- lapply(count_table[sample_names], function(x) as.numeric(x) / 100)

# <0.001 to 0
count_table[sample_names] <- lapply(count_table[sample_names], function(x) ifelse(x < 0.001, 0, x))

# absolute abundance
count_table[sample_names] <- round(sweep(count_table[sample_names], 2, total_seqs, FUN = "*"))

count_species <- count_table %>%
  dplyr::select(-c(1:6)) %>%  
  column_to_rownames("Species") %>%
  .[, rownames(metadata_f)]      

count_species_filt <- count_species + 1

# DESeq2
dds <- DESeqDataSetFromMatrix(
  countData = count_species_filt,
  colData   = metadata_f,
  design    = ~ ferm
)

dds$ferm <- factor(dds$ferm, levels = c("yes", "no"))

dds <- DESeq(dds)

res <- results(dds, contrast = c("ferm", "yes", "no"))

#Export

res_species_df <- as.data.frame(res) %>%
  rownames_to_column("Species") %>%
  arrange(padj)

write_xlsx(res_species_df, "SD15_fig4d_deseq2_taxo_couscous.xlsx")






### Species
res_species_sig <- res_species_df %>%
  filter(padj < 0.05, log2FoldChange > 0.5)

# Plot
ggplot(res_species_sig, aes(x = log2FoldChange, y = reorder(Species, log2FoldChange), fill = log2FoldChange > 0)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(
    values = c("TRUE" = "#E69F00", "FALSE" = "#E6765E"),
    labels = c("TRUE" = "Increased", "FALSE" = "Decreased")
  ) +
  labs(
    x = "Log2 Fold Change",
    y = "",
    fill = ""
  ) +
  scale_x_continuous(
    breaks = seq(-15, ceiling(max(res_species_sig$log2FoldChange)), by = 5), 
    expand = c(0, 0) 
  ) +
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
    legend.key.size = unit(4, "mm")
  )

# Sauvegarde
ggsave(
  filename = "plots/SD14_fig4d_deseq2_taxo_couscous.png",
  plot = last_plot(),
  width = 80,
  height = 50,
  units = "mm",
  dpi = 300,
  bg = "white"
)

ggsave(
  filename = "plots/SD14_fig4d_deseq2_taxo_couscous.svg",
  plot = last_plot(),
  width = 80,
  height = 50,
  units = "mm"
)
