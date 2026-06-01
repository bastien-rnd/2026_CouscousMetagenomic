# DESCRIPTION ----------------------------------------------------------------

# This script generates histogram of microbial families across fermented cereals (n=94)


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



#PHYLOSEQ -------------------------------------------------------------

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
taxa_colors <- colors[["family"]]
var1_colors <- colors[["product"]]
var2_colors <- colors[["cereals"]]



# 10 most abundant families
top_family_all <- ps_all %>%
  group_by(Family) %>%
  summarise(Total_Abundance = sum(Abundance), .groups = "drop") %>%
  arrange(desc(Total_Abundance)) %>%
  slice_head(n = 10)

ps_all_family <- ps_all %>%
  mutate(Family = if_else(Family %in% top_family_all$Family, Family, "Others"))

ps_all_family_agg <- ps_all_family %>%
  group_by(Sample, Family, product, cereals) %>%
  summarise(Abundance = sum(Abundance), .groups = "drop")

ps_all_family_ordered <- ps_all_family_agg %>%
  mutate(
    Family = factor(Family, levels = names(taxa_colors)),
    Sample = factor(Sample, levels = ps_all_family_agg %>%
                      distinct(Sample, product, cereals) %>%
                      arrange(product, cereals) %>%
                      pull(Sample))
  )

# PLOT
full_plot <- ggplot(ps_all_family_ordered, aes(x = Sample, y = Abundance, fill = Family)) +
  geom_col(color = "NA", linewidth = 0.1, show.legend = TRUE) +
  scale_fill_manual(values = taxa_colors, name = "Family") +
  scale_y_continuous(
    limits = c(0, 125),
    breaks = seq(0, 100, by = 20),
    minor_breaks = seq(0, 100, by = 10),
    expand = c(0,0)
  ) +
  
  # Bar 1: Product
  ggnewscale::new_scale_fill() +
  geom_tile(
    data = ps_all_family_ordered %>% distinct(Sample, product),
    aes(x = Sample, y = 109, fill = product),
    height = 5,
    inherit.aes = FALSE
  ) +
  scale_fill_manual(values = var1_colors, name = "Product") +
  
  # Bar 2: Cereals
  ggnewscale::new_scale_fill() +
  geom_tile(
    data = ps_all_family_ordered %>% distinct(Sample, cereals),
    aes(x = Sample, y = 103, fill = cereals),
    height = 5,
    inherit.aes = FALSE
  ) +
  scale_fill_manual(values = var2_colors, name = "Cereals") +
  
  labs(x = "", y = "Relative abundance (%)") +
  
  theme_minimal() +
  theme(
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white"),
    panel.grid = element_blank(),
    axis.title.x = element_blank(),
    axis.text.x = element_blank(),
    axis.title.y = element_text(size = 7),
    axis.text.y = element_text(size = 5),
    legend.title = element_text(size = 7),
    legend.text = element_text(size = 5),
    legend.key.size = unit(3, "mm"),
    legend.key.width = unit(3, "mm"),
    legend.key.height = unit(3, "mm")
  )

# Plot no legend
plot_no_legend <- full_plot + theme(legend.position = "none")
print(plot_no_legend)

# Export PNG
ggsave(
  filename = "plots/SD20_supp_fig2_family_histo_fermented_cereals.png",
  plot = plot_no_legend,
  width = 175,
  height = 70,
  units = "mm",
  dpi = 300,
  bg = "white"
)

# Export SVG
ggsave(
  filename = "plots/SD20_supp_fig2_family_histo_fermented_cereals.svg",
  plot = plot_no_legend,
  width = 175,
  height = 70,
  units = "mm"
)


#Legend
full_plot <- ggplot(ps_all_family_ordered,
                    aes(x = Sample, y = Abundance, fill = Family)) +
  
  geom_bar(stat = "identity", position = "stack") +
  scale_fill_manual(values = taxa_colors, name = "Family") +
  
  # Annotation Product
  ggnewscale::new_scale_fill() +
  geom_bar(
    data = ps_all_family_ordered %>% distinct(Sample, product),
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
    data = ps_all_family_ordered %>% distinct(Sample, cereals),
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

legend_name <- get_legend(
  full_plot +
    ggnewscale::new_scale_fill() +
    geom_bar(
      data = ps_all_family_ordered %>% distinct(Sample, product) %>% na.omit(),
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


grid::grid.newpage()
grid::grid.draw(legend_name)

ggsave(
  filename = "plots/SD20_supp_fig2_family_histo_fermented_cereals_legend.png",
  plot = legend_name,      
  width = 3,               
  height = 15,              
  dpi = 300,
  bg = "white"
)

ggsave(
  filename = "plots/SD20_supp_fig2_family_histo_fermented_cereals_legend.svg",  
  plot = legend_name,             
  width = 7,                      
  height = 3.5                   
)












