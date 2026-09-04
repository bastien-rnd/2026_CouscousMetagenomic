# DESCRIPTION ----------------------------------------------------------------

# This script generates alpha-diversity plots (richness and pielou's evenness)
# Alpha-diversity index have to be specified as the "variable_y"
# Aesthetic modification have been performed on the generated using Inkscape to produce the final figure.



# PACKAGES ----------------------------------------------------------------
library(tidyverse)
library(readxl)
library(writexl)
library(vegan)
library(emmeans)

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



#To keep only samples of good quality
metadata <- metadata %>%
  filter(filter_analysis %in% c("Y")) %>% #filter good quality samples only
  mutate(clean_id_copy = clean_id) %>%
  column_to_rownames("clean_id_copy")



# To calculate absolute abundance ------------------------------------------------------
sample_names <- colnames(sylph_count)[-c(1:7)]
total_seqs <- metadata$clean_reads[match(sample_names, metadata$clean_id)]
total_seqs <- as.numeric(total_seqs)

count_table <- sylph_count
count_table[sample_names] <- lapply(count_table[sample_names], function(x) as.numeric(x) / 100) 

count_table[sample_names] <- lapply(count_table[sample_names], function(x) ifelse(x < 0.001, 0, x)) # to replace value < 0.1% by 0

count_table[sample_names] <- round(
  sweep(
    count_table[sample_names],
    2,
    total_seqs,
    FUN = "*"
  )
)

count_species <- count_table %>%
  dplyr::select(-c(1:6)) %>%
  column_to_rownames("Species")

abund_matrix <- as.data.frame(t(count_species[ , ]))



# 2 - INDEX + RAREFACTION ---------------------------------------------

# Minimal sequencing depth
min_depth <- min(rowSums(abund_matrix))
abund_rarefied <- rrarefy(abund_matrix, sample = min_depth)

# Index
shannon_rar <- diversity(abund_rarefied, index = "shannon")
simpson_rar <- diversity(abund_rarefied, index = "simpson")
richness_rar <- specnumber(abund_rarefied)  
evenness_rar <- shannon_rar / log(richness_rar)

# To generate results table
alpha_div <- data.frame(
  ID = rownames(abund_rarefied),
  Shannon = shannon_rar,
  Simpson = simpson_rar,
  Richness = richness_rar,
  Evenness = evenness_rar
)

# To merge index with metadata
alpha_merged <- merge(alpha_div, metadata,
                      by.x = "ID", by.y = "clean_id", all.x = TRUE)


# Subsampling to keep only fermented samples
alpha_merged_f <- alpha_merged %>%
  filter(ferm == "yes")

# To rename variables
alpha_merged_f$couscous <- factor(
  alpha_merged_f$couscous,
  levels = c("Y", "N"),
  labels = c("Couscous", "Others fermented cereals")
)

#To export alpha-div
alpha_raw <- alpha_merged_f %>%
  select(c(ID, Richness, Evenness, Shannon, Simpson))
#write_xlsx(alpha_raw, "SD3_fig2a_alpha_div_fermented_cereals.xlsx")



# PLOT --------------------------------------------------------------------

# Parameters to custom
variable_y <- "Evenness"     
variable_group <- "couscous"    
colors_vector <- colors[["couscous_colors"]]

#Wilcoxon test to estimate p-value
wilcox.test( as.formula(paste(variable_y, "~", variable_group)), data = alpha_merged_f )

#Plot
p <- ggplot(alpha_merged_f, 
            aes(x = .data[[variable_group]], 
                y = .data[[variable_y]], 
                fill = .data[[variable_group]])) +
  
  geom_boxplot(size = 0.5) +
  geom_jitter(size = 0.3, width = 0.1, alpha = 0.8, color = "grey30") +
  
  scale_fill_manual(values = colors_vector) +
  theme_minimal() +
  labs(title = paste(variable_y, "index of fermented flours"),
       x = "", 
       y = paste(variable_y, "index"), 
       fill = "") +
  theme(
    axis.text.x = element_blank(),
    axis.text.y = element_text(size = 5),
    text = element_text(size = 5),
    plot.title = element_blank(),
    panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.5),
    axis.title.x = element_blank(),
    axis.title.y = element_text(size = 7),
    legend.key = element_blank(),
    legend.key.size = unit(4, "mm"),
    legend.title = element_text(size = 5),
    legend.text = element_text(size = 5)
  )

ggsave(
  filename = paste0("plots/SD3_fig2a_", variable_y, "_boxplot.png"),
  plot = p,
  width = 58,
  height = 58,
  units = "mm",
  dpi = 300
)

ggsave(
  filename = paste0("plots/SD3_fig2a_", variable_y, "_boxplot.svg"),
  plot = p,
  width = 58,
  height = 58,
  units = "mm"
)
