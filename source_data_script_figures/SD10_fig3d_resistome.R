# DESCRIPTION ----------------------------------------------------------------

# This script generates the histogram related to Antibiotic Resistance (ARGs) in fermented cereals.


# PACKAGES ----------------------------------------------------------------
library(tidyverse)
library(readxl)
library(writexl)


source("colors.R")

# ANALYSIS ----------------------------------------------------------------

# To set working directory 
setwd("C:/Users/2023br002/Documents/1 - PhD DOMINO/8 - Papers/1_couscous_bdd/source/")
#setwd("your_working_directory")

# Metadata on samples 
input_metadata <- "metadata_samples.xlsx"
metadata <- read_excel(input_metadata)

metadata <- metadata %>%
  filter(filter_analysis %in% c("Y")) %>%
  mutate(clean_id_copy = clean_id) %>% 
  column_to_rownames("clean_id_copy")


# DATA ARGs
aro_index <- read_tsv("resistome/aro_index.tsv")


# BOWTIE2 -----------------------------------------------

folder_path <- "resistome/final_arg_out"

tsv_files <- list.files(folder_path, pattern = "_ARG_counts\\.tsv$", full.names = TRUE)

all_counts <- lapply(tsv_files, function(file) {
  sample_name <- basename(file) %>% str_replace("_ARG_counts\\.tsv$", "")
  
  df <- read_tsv(file, show_col_types = FALSE)
  
  required_cols <- c("seqname", "seqlen", "mapped_reads")
  if(!all(required_cols %in% colnames(df))) {
    warning(paste("Fichier ignoré (colonnes manquantes) :", file))
    return(NULL)
  }
  
  df <- df %>%
    select(all_of(required_cols)) %>%
    rename(!!sample_name := mapped_reads)
  
  return(df)
}) %>% compact()


combined_counts <- reduce(all_counts, full_join, by = c("seqname", "seqlen"))

combined_counts[is.na(combined_counts)] <- 0


sample_cols <- setdiff(names(combined_counts), c("seqname", "seqlen"))

rename_map <- setNames(
  metadata$clean_id[match(sample_cols, metadata$raw_id)],
  sample_cols
)

# to delete NA
rename_map <- rename_map[!is.na(rename_map)]

combined_counts_renamed <- combined_counts %>%
  select(seqname, seqlen, all_of(names(rename_map))) %>%  
  rename_with(~ rename_map[.x], .cols = names(rename_map)) %>%
  mutate(ARO = str_extract(seqname, "ARO:\\d+"))

aro_index_subset <- aro_index %>%
  select(`ARO Accession`, `ARO Name`, `AMR Gene Family`, `Drug Class`, `Resistance Mechanism`) %>%
  distinct(`ARO Accession`, .keep_all = TRUE)


combined_counts_annotated <- combined_counts_renamed %>%
  left_join(aro_index_subset, by = c("ARO" = "ARO Accession")) %>%
  select(seqname, seqlen, ARO, `ARO Name`, `AMR Gene Family`, `Drug Class`, `Resistance Mechanism`, everything())


write_tsv(combined_counts_annotated, "SD10_fig3e_resistome.tsv")


## To calculate CPM  --------------
qty_arg <- read_tsv("SD11_fig3e_resistome.tsv")

qty_arg_long <- qty_arg %>%
  pivot_longer(
    cols = -c(seqname, seqlen, ARO, `ARO Name`, `AMR Gene Family`, `Drug Class`, `Resistance Mechanism`), 
    names_to = "Sample",
    values_to = "mapped_reads"
  )

qty_arg_long <- qty_arg_long %>%
  left_join(
    metadata %>% select(clean_id, clean_reads) %>% rename(Sample = clean_id),
    by = "Sample"
  )

qty_arg_long <- qty_arg_long %>%
  mutate(CPM = mapped_reads / clean_reads * 1e6)

qty_arg_long <- qty_arg_long %>%
  mutate(CPM = ifelse(CPM < 1, 0, CPM))



## CPM-ARGs per sample -----------------------------------------------------------------

cpm_sums <- qty_arg_long %>%
  group_by(Sample) %>%
  summarise(total_CPM = sum(CPM, na.rm = TRUE)) %>%
  left_join(metadata %>% select(clean_id, product), by = c("Sample" = "clean_id"))


arg_richness <- qty_arg_long %>%
  filter(CPM > 0) %>%  
  group_by(Sample) %>%
  summarise(n_ARG = n_distinct(ARO), .groups = "drop") %>%
  right_join(metadata %>% select(clean_id, product),
             by = c("Sample" = "clean_id")) %>%
  mutate(n_ARG = replace_na(n_ARG, 0)) %>% 
  filter(!is.na(Sample))



## Summary ARGs plot  -----------------------------------------------------------------
arg_summary <- cpm_sums %>%
  left_join(arg_richness, by = c("Sample", "product")) %>%
  left_join(metadata %>% select(clean_id, ferm), by = c("Sample" = "clean_id")) %>%
  filter(ferm == "yes") %>%
  #  filter(!name %in% "couscous") %>%
  filter(!total_CPM == 0)

arg_summary_ordered <- arg_summary %>%
  arrange(product, desc(total_CPM)) %>%
  mutate(
    Sample = factor(Sample, levels = Sample)
  )

p <- ggplot(arg_summary_ordered,
            aes(x = Sample, y = total_CPM, fill = product)) +
  geom_col(width = 1, color = "black") +
  geom_text(
    aes(label = n_ARG),
    hjust = 0.5,
    vjust = -0.5,
    size = 1.8
  ) +
  labs(
    x = "",
    y = "ARG-encoding genes (CPM/Sample)",
    fill = "Product"
  ) +
  theme_minimal() +
  scale_fill_manual(values = colors[["product"]]) +
  scale_y_continuous(expand = c(0, 0), limits = c(0, 430)) +
  theme(
    axis.text.x = element_blank(),
    axis.text.y = element_text(size = 5),
    axis.title = element_text(size = 5),
    legend.text = element_text(size = 5),
    legend.title = element_text(size = 7),
    legend.key.size = unit(3, "mm"),
    panel.border = element_rect(color = "black", fill = NA, linewidth = 0.25),
    panel.background = element_rect(fill = "white"),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    plot.background = element_rect(fill = "white", color = "black")
  )

print(p)

ggsave(
  "plots/SD11_fig3d_resistome.png",
  plot = p,
  width = 180,
  height = 45,
  units = "mm"
)

ggsave(
  "plots/SD11_fig3d_resistome.svg",
  plot = p,
  width = 180,
  height = 45,
  units = "mm"
)
