# DESCRIPTION ----------------------------------------------------------------

# This script generates histogram of microbial genus across fermented cereals (n=94)


# PACKAGES ----------------------------------------------------------------
library(tidyverse)
library(readxl)
library(writexl)
library(phyloseq)
library(cowplot)

source("colors.R")

# ANALYSIS ----------------------------------------------------------------

# To set working directory 
setwd("source_data_script_figures")
#setwd("your_working_directory")


# Taxonomic counting table
input_dir <- "merged_sylph_abundance_clean.xlsx" 
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

ps_all <- psmelt(phyloseq_f)



# PLOT --------------------------------------------------------------------
taxa_colors <- colors[["genus"]]
var1_colors <- colors[["product"]]
var2_colors <- colors[["cereals"]]



# 15 most abundant genus
top_genus_all <- ps_all %>%
  group_by(Genus) %>%
  summarise(Total_Abundance = sum(Abundance)) %>%
  arrange(desc(Total_Abundance)) %>%
  top_n(15, Total_Abundance)

ps_all_genus <- ps_all %>%
  mutate(Genus = ifelse(Genus %in% top_genus_all$Genus, Genus, "Others"))

ps_all_genus <- ps_all_genus %>%
  mutate(
    Genus = factor(Genus, levels = names(taxa_colors))
  )

sample_order <- ps_all_genus %>%
  distinct(Sample, product, cereals) %>%
  arrange(product, cereals) %>%   
  pull(Sample)


ps_all_genus_ordered <- ps_all_genus %>%
  mutate(
    Sample = factor(Sample, levels = sample_order)
  )

# PLOT
full_plot <- ggplot(ps_all_genus_ordered,
                    aes(x = Sample, y = Abundance, fill = Genus)) +
  geom_bar(stat = "identity", position = "stack") +
  scale_fill_manual(values = taxa_colors, name = "Genus") +
  
  # annotation name
  ggnewscale::new_scale_fill() +
  geom_tile(
    data = ps_all_genus_ordered %>% distinct(Sample, product),
    aes(x = Sample, y = 112, fill = product),
    height = 7,
    inherit.aes = FALSE
  ) +
  scale_fill_manual(values = var1_colors, name = "Product") +
  
  # annotation cereals
  ggnewscale::new_scale_fill() +
  geom_tile(
    data = ps_all_genus_ordered %>% distinct(Sample, cereals),
    aes(x = Sample, y = 104, fill = cereals),
    height = 7,
    inherit.aes = FALSE
  ) +
  scale_fill_manual(values = var2_colors, name = "Cereals") +
  
  scale_y_continuous(
    limits = c(0, 125),
    breaks = seq(0, 100, by = 20),
    minor_breaks = seq(0, 100, by = 10)
  ) +
  labs(y = "Relative abundance (%)") +
  theme_minimal() +
  theme(
    axis.title.x = element_blank(),
    axis.text.x = element_blank(),
    axis.title.y = element_text(size = 7),
    axis.text.y = element_text(size = 5),
    legend.title = element_text(size = 7),
    legend.text = element_text(size = 5),
    legend.key.size = unit(4, "mm"),
    panel.grid = element_blank()
  )

full_plot <- ggplot(ps_all_genus_ordered,
                    aes(x = Sample, y = Abundance, fill = Genus)) +
  
  # Barres principales
  geom_bar(stat = "identity", position = "stack") +
  scale_fill_manual(values = taxa_colors, name = "Genus") +
  
  # Annotation Product
  ggnewscale::new_scale_fill() +
  geom_bar(
    data = ps_all_genus_ordered %>% distinct(Sample, product),
    aes(x = Sample, y = 7, fill = product),   
    stat = "identity",
    width = 1,
    inherit.aes = FALSE
  ) +
  scale_fill_manual(
    values = var1_colors,
    name = "Product",
    guide = guide_legend(
      keywidth = unit(4, "mm"),
      keyheight = unit(4, "mm"),
      override.aes = list(colour = NA)   
    )
  ) +
  
  # Annotation Cereals
  ggnewscale::new_scale_fill() +
  geom_bar(
    data = ps_all_genus_ordered %>% distinct(Sample, cereals),
    aes(x = Sample, y = 7, fill = cereals),  
    stat = "identity",
    width = 1,
    inherit.aes = FALSE
  ) +
  scale_fill_manual(
    values = var2_colors,
    name = "Cereals",
    guide = guide_legend(
      keywidth = unit(4, "mm"),
      keyheight = unit(4, "mm"),
      override.aes = list(colour = NA)
    )
  ) +
  
  # Échelle Y
  scale_y_continuous(
    limits = c(0, 125),
    breaks = seq(0, 100, by = 20),
    minor_breaks = seq(0, 100, by = 10)
  ) +
  
  # Labels
  labs(y = "Relative abundance (%)") +
  
  # Theme
  theme_minimal() +
  theme(
    axis.title.x = element_blank(),
    axis.text.x = element_blank(),
    axis.title.y = element_text(size = 7),
    axis.text.y = element_text(size = 5),
    legend.title = element_text(size = 7),
    legend.text = element_text(size = 5),
    legend.key.size = unit(4, "mm"),
    panel.grid = element_blank()
  )
# Plot no legend
plot_no_legend <- full_plot + theme(legend.position = "none")
print(plot_no_legend)

# Legend 
legend_name <- get_legend(
  full_plot +
    ggnewscale::new_scale_fill() +
    geom_bar(
      data = ps_all_genus_ordered %>% distinct(Sample, product) %>% na.omit(),
      aes(x = Sample, y = 7, fill = product),
      stat = "identity",
      width = 1,
      inherit.aes = FALSE
    ) +
    scale_fill_manual(
      values = var1_colors,
      name = "Product",
      guide = guide_legend(
        keywidth = unit(4, "mm"),
        keyheight = unit(4, "mm"),
        override.aes = list(colour = NA, width = 1, height = 1)
      )
    ) +
    theme(legend.position = "right")
)

print(plot_no_legend)

# Export 
ggsave(
  filename = "plots/SD6_fig2d_genus_histo_fermented_cereals.png",  
  plot = last_plot(),              
  width = 175,                     
  height = 70, 
  units = "mm",
  dpi = 300,                        
  bg = "white"
)

ggsave(
  filename = "plots/SD6_fig2d_genus_histo_fermented_cereals.svg", 
  plot = last_plot(),             
  width = 7,                    
  height = 3.5                  
)

grid::grid.newpage()
grid::grid.draw(legend_name)


ggsave(
  filename = "plots/SD6_fig2d_genus_histo_fermented_cereals_legend.png",
  plot = legend_name,      
  width = 3,               
  height = 15,           
  dpi = 300,
  bg = "white"
)

ggsave(
  filename = "plots/SD6_fig2d_genus_histo_fermented_cereals_legend.svg",  
  plot = legend_name,             
  width = 7,                     
  height = 3.5                  
)
