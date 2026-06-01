# DESCRIPTION ----------------------------------------------------------------

# This script generates the histogram representing bacterial species contribution to starch, maltose and dextran catabolism genes in cereals flours (n=19) and related couscous (n=19)

# PACKAGES ----------------------------------------------------------------
library(tidyverse)
library(readxl)
library(writexl)
library(cowplot)


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

# Data Sylph
f3m_table <- read_excel("f3m_count_table_sylph_filtered.xlsx")


# Vector of variables
meta_cols <- c("domain", "phylum", "order", "class", "family", "genus", "species", "main_module", "food_microbiome_metabolic_module", "food_microbiome_metabolic_function", "food_microbiome_functional_gene")
count_cols <- setdiff(colnames(f3m_table), meta_cols)

# If necessary, to subsample the initial table
count_cols <- intersect(count_cols, metadata_f$clean_id)
f3m_table <- f3m_table %>%
  select(all_of(c(meta_cols, count_cols)))

### Filtering variables----------------------------------------
# To select taxonomic and functional hierarchical level
taxonomic_level <- "species"
functional_level <- "food_microbiome_functional_gene"
hierarchical_level <- c(taxonomic_level, functional_level)

# Functional filter
func_filter <- "F3MC_11"

# Variable to discriminate samples
variable_bar1 <- "ferm"
variable_bar2 <- "cereals"



### Count matrix----------------------------------------

# If necessary, to filter functions
f3m_table <- f3m_table %>%
  filter(str_starts(!!sym(functional_level), func_filter))

# To group following taxo and functional level
f3m_table_matrix <- f3m_table %>%
  select(intersect(meta_cols, hierarchical_level), all_of(count_cols)) %>%
  unite(col = feature, all_of(hierarchical_level), sep = "___", remove = F) %>% 
  group_by(across(all_of(hierarchical_level))) %>%
  summarise(across(all_of(count_cols), sum), .groups = "drop")

# To transform into proportion (% by colums)
f3m_table_matrix_pct <- f3m_table_matrix %>%
  mutate(across(all_of(count_cols), ~ .x / sum(.x) * 100)) %>%
  mutate(across(all_of(count_cols), ~ replace_na(.x, 0))) %>% 
  filter(rowSums(across(all_of(count_cols))) > 0)



## CONTRIBUTORS ---------------------------------------------------------------

# To filter top taxa by sum of proportion in all samples
n_taxa <- 15 #number in the top

top_taxa <- f3m_table_matrix_pct %>%
  group_by(across(all_of(taxonomic_level))) %>%
  summarise(total_sum = sum(across(all_of(count_cols))), .groups = "drop") %>%
  arrange(desc(total_sum)) %>%
  slice_head(n = n_taxa)

f3m_top_taxa <- f3m_table_matrix_pct %>%
  mutate(!!taxonomic_level := if_else(.data[[taxonomic_level]] %in% top_taxa[[taxonomic_level]],.data[[taxonomic_level]],"Others")) %>%
  group_by(across(all_of(c(taxonomic_level, functional_level)))) %>%
  summarise(across(all_of(count_cols), sum), .groups = "drop") %>%
  arrange(desc(rowSums(across(all_of(count_cols)))))


# Long format to build histogram
f3m_table_long <- f3m_top_taxa %>%
  select(-all_of(functional_level)) %>%
  group_by(across(all_of(taxonomic_level))) %>%
  summarise(across(all_of(count_cols), sum), .groups = "drop") %>%
  select(all_of(taxonomic_level), where(~ !all(. == 0)))  %>% 
  as.data.frame() %>% 
  pivot_longer(cols = -taxonomic_level, names_to = "sample", values_to = "percentage")



# To supervise order of samples alphabetically (product/fermentation then cereals) and order taxa to have Others on the bottom
samples_used <- unique(f3m_table_long$sample)

samples_ordered <- metadata %>%
  filter(clean_id %in% samples_used) %>%   
  select(clean_id, !!sym(variable_bar1), !!sym(variable_bar2)) %>%      
  distinct() %>%                           
  arrange(!!sym(variable_bar1), !!sym(variable_bar2)) %>%               
  pull(clean_id) 

f3m_table_long <- f3m_table_long %>%
  mutate(sample = factor(sample, levels = samples_ordered)) %>%
  mutate(!!taxonomic_level := factor(.data[[taxonomic_level]], levels = c(setdiff(unique(.data[[taxonomic_level]]), "Others"), "Others")))


# To annotate product and cereals with bar above histogram
annot1 <- metadata_f %>%
  filter(clean_id %in% unique(f3m_table_long$sample))%>%
  distinct(clean_id, !!sym(variable_bar1)) %>%
  na.omit() %>%
  dplyr::rename(sample = clean_id) %>%
  mutate(sample = factor(sample, levels = samples_ordered))

annot2 <- metadata_f %>%
  filter(clean_id %in% unique(f3m_table_long$sample)) %>%
  distinct(clean_id, !!sym(variable_bar2)) %>%
  na.omit() %>%
  dplyr::rename(sample = clean_id) %>%
  mutate(sample = factor(sample, levels = samples_ordered))


# Plot histogram
p <- ggplot(f3m_table_long, aes(x = sample, y = percentage, fill = !!sym(taxonomic_level))) +
  geom_col(color = "NA", linewidth = 0.1, show.legend = TRUE) +
  scale_fill_manual(values = colors[[taxonomic_level]]) +
  scale_y_continuous(
    limits = c(0, 125),
    breaks = seq(0, 100, by = 20),
    minor_breaks = seq(0, 100, by = 10)
  ) +
  # Bar 1: Product name or fermentation
  ggnewscale::new_scale_fill() +
  geom_tile(
    data = annot1,
    aes(x = sample, y = 109, fill = !!sym(variable_bar1)),
    height = 5,
    inherit.aes = FALSE
  ) +
  scale_fill_manual(values = colors[[variable_bar1]], name = variable_bar1) +
  # Bar 2: Cereals bar
  ggnewscale::new_scale_fill() +
  geom_tile(
    data = annot2,
    aes(x = sample, y = 103, fill = !!sym(variable_bar2)),
    height = 5,
    inherit.aes = FALSE
  ) +
  
  scale_fill_manual(values = colors[[variable_bar2]], name = variable_bar2) +
  theme_minimal() +
  labs(
    title = "Proportion of F3M main module (%) in cereals samples",
    x = "",
    y = "Proportion (%)",
    fill = "F3M Main Module"
  ) +
  theme(
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white"),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    legend.title = element_text(size = 7),
    legend.text = element_text(size = 5),
    legend.key.size = unit(3, "mm"),
    legend.key.width = unit(3, "mm"),
    legend.key.height = unit(3, "mm"),
    axis.title = element_text(size = 5),
    axis.text = element_text(size = 5),
    axis.text.x = element_blank(),
    plot.title = element_blank()
  )

legend <- get_legend(p)
p_no_legend <- p + theme(legend.position = "none")
print(p_no_legend)

# To export plot and legend separately
ggsave(
  filename = "plots/SD15_fig4e_starch_maltose_contribution_f3m.png", 
  plot = p_no_legend,              
  width = 100,                      
  height = 70,
  units = "mm",
  dpi = 300,                        
  bg = "white"
)

ggsave(
  filename =
  "plots/SD15_fig4e_starch_maltose_contribution_f3m_legend.png",  
  plot = legend,              
  width = 30,                      
  height = 100,
  units = "mm",                    
  dpi = 300,                  
  bg = "white"
)

# Export SVG
ggsave(
  filename = "plots/SD15_fig4e_starch_maltose_contribution_f3m.svg", 
  plot = p_no_legend,              
  width = 100,                      
  height = 70,
  units = "mm"
)

ggsave(
  filename = "plots/SD15_fig4e_starch_maltose_contribution_f3m_legend.svg",  
  plot = legend,              
  width = 30,                      
  height = 110,
  units = "mm"
)

# To export table
write_xlsx(f3m_table_matrix_pct, "SD15_fig4e_starch_maltose_contribution_f3m.xlsx")


