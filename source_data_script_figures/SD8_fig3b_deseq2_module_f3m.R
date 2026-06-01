# DESCRIPTION ----------------------------------------------------------------

# This script generates DESeq2 analysis and associated plot on F3M Food Microbiome Metabolic Module.


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

metadata <- metadata %>%
  filter(filter_analysis %in% c("Y")) %>%
  mutate(clean_id_copy = clean_id) %>% 
  column_to_rownames("clean_id_copy")

metadata_filtered <- metadata %>%
  filter(ferm %in% "yes")


# F3M HISTOGRAM ----------------------------------------
## Data preprocess -------------------------------------

### Import F3M table -----------------------------------
f3m_table <- read_excel("f3m_count_table_sylph_filtered.xlsx")

# Vector of variables
meta_cols <- c("domain", "phylum", "order", "class", "family", "genus", "species", "main_module", "food_microbiome_metabolic_module", "food_microbiome_metabolic_function", "food_microbiome_functional_gene")
count_cols <- setdiff(colnames(f3m_table), meta_cols)

# If necessary, to subsample the initial table
count_cols <- intersect(count_cols, metadata_filtered$clean_id)
f3m_table <- f3m_table %>%
  select(all_of(c(meta_cols, count_cols)))

### Filtering variables----------------------------------------
# To select taxonomic and functional hierarchical level
taxonomic_level <- "domain"
functional_level <- "food_microbiome_metabolic_module"
hierarchical_level <- c(taxonomic_level, functional_level)

# Functional filter
#func_filter <- "F3MC"

# If necessary, to filter functions
#f3m_table <- f3m_table %>%
#  filter(str_starts(!!sym(functional_level), func_filter))

# To group following taxo and functional level
f3m_table_matrix <- f3m_table %>%
  select(intersect(meta_cols, hierarchical_level), all_of(count_cols)) %>%
  unite(col = feature, all_of(hierarchical_level), sep = "___", remove = F) %>% 
  group_by(across(all_of(hierarchical_level))) %>%
  summarise(across(all_of(count_cols), sum), .groups = "drop")

# To transform into DESeq2 matrix
f3m_deseq2_matrix <- f3m_table_matrix %>%
  select(-taxonomic_level) %>%
  as.data.frame() %>%
  column_to_rownames(functional_level)



### DESeq2 analysis ---------------------------------------------------------
metadata <- metadata[colnames(f3m_deseq2_matrix), ]

dds <- DESeqDataSetFromMatrix(
  countData = f3m_deseq2_matrix,
  colData   = metadata,
  design    = ~ couscous
)

# Définir l'ordre des niveaux
dds$couscous <- factor(dds$couscous, levels = c("N", "Y"))

#DESEQ2
dds <- DESeq(dds)

res <- results(dds, contrast = c("couscous", "Y", "N"))

norm_counts <- counts(dds, normalized = TRUE)
group <- colData(dds)$couscous

mean_N <- rowMeans(norm_counts[, group == "N", drop = FALSE])
mean_Y <- rowMeans(norm_counts[, group == "Y", drop = FALSE])
n_N <- sum(group == "N")
n_Y <- sum(group == "Y")

res_df <- as.data.frame(res) %>%
  rownames_to_column("feature") %>%
  mutate(
    mean_Y = mean_Y[feature],
    mean_N = mean_N[feature],
    n_Y = n_Y,
    n_N = n_N
  ) %>%

  arrange(padj)

#write_xlsx(res_df, "SD8_fig3b_deseq2_carbohydrates_f3m.xlsx")


# PLOT --------------------------------------------------------------------

res_sig <- res_df %>%
  filter(
    padj < 0.05,
    log2FoldChange > 0.5)

# Plot
ggplot(res_sig, aes(x = log2FoldChange, y = reorder(feature, log2FoldChange), fill = log2FoldChange > 0)) +
  geom_bar(stat = "identity") +
  geom_vline(xintercept = 0, color = "grey20", size = 0.25) +
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
    breaks = seq(floor(min(res_sig$log2FoldChange)),
                 ceiling(max(res_sig$log2FoldChange)), by = 0.5)
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

ggsave(
  filename = "plots/SD8_fig3b_deseq2_metabolic_module_f3m.png",  
  plot = last_plot(),            
  width = 115,                    
  height = 58,
  units = "mm",
  dpi = 600,                  
  bg = "white"
)

ggsave(
  filename = "plots/SD8_fig3b_deseq2_metabolic_module_f3m.svg",  
  plot = last_plot(),              
  width = 115,                
  height = 58,
  units = "mm")
