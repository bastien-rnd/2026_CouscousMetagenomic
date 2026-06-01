# DESCRIPTION ----------------------------------------------------------------

# This script generates the World map of non-alcoholic fermented cereals extracted from the literature (Fig 1a).
# Aesthetic modification have been performed on the generated map using Inkscape to produce the final figure.

# PACKAGES ----------------------------------------------------------------
library(tidyverse)
library(readxl)
library(sf)
library(rnaturalearth)
library(rmapshaper)
library(ggpattern)


# ANALYSIS ----------------------------------------------------------------

# To set working directory 
setwd("source_data_script_figures")

# To import data
map_data <- read_excel("SD1_fig1a_map_fermented_cereals.xlsx")

# To filter geographic region with ISO3 code (= country)
map_non_alc <- map_data %>% 
  filter(!is.na(iso3_code))

# Geographic data
world <- ne_countries(scale = "medium", returnclass = "sf")

# Summary by country
map_ff <- map_non_alc %>% 
  group_by(iso3_code) %>% 
  summarise(
    n = n(),
    has_seq = any(ref_shotgun != "NA"),
    .groups = "drop"
  )

# To join map and data
world_ff <- world %>%
  select(iso_a3_eh, geometry) %>%
  left_join(map_ff, by = c("iso_a3_eh" = "iso3_code")) %>%
  mutate(
    n = replace_na(n, 0),
    has_seq = replace_na(has_seq, FALSE)
  )

world_smooth <- ms_simplify(
  world_ff,
  keep = 0.05,
  keep_shapes = FALSE
)

# Country with shotgun sequencing on fermented cereals
world_seq_senegal <- world_smooth %>%
  filter(iso_a3_eh == "SEN", has_seq)

world_seq_other <- world_smooth %>%
  filter(iso_a3_eh != "SEN", has_seq)

# To generate the map
p <- ggplot(world_smooth) +
  
  geom_sf(aes(fill = n)) +
  
  geom_sf_pattern(
    data = world_seq_other,
    pattern = "stripe",
    pattern_fill = "black",
    pattern_colour = NA,
    pattern_angle = 45,
    pattern_density = 0.15,
    pattern_spacing = 0.006,
    fill = NA,
    color = NA
  ) +
  
  geom_sf_pattern(
    data = world_seq_senegal,
    pattern = "stripe",
    pattern_fill = "black",
    pattern_colour = NA,
    pattern_angle = 45,
    pattern_density = 0.15,
    pattern_spacing = 0.006,
    fill = NA,
    color = NA
  ) +
  
  scale_fill_gradientn(
    colours = c("#f3f3f3", "#f6e6d6", "#F7955E", "#F6744D", "#de482c"),
    values = scales::rescale(c(0, 1, 5, 10, max(world_ff$n, na.rm = TRUE))),
    breaks = c(0, 5, 10, 20, 30),
    labels = c("0", "5", "10", "20", "30"),
    name = "Number of fermented cereals type",
    guide = guide_colourbar(
      barwidth = 10,
      barheight = 0.6,
      ticks = TRUE,
      frame.colour = "black",
      frame.linewidth = 0.5
    )
  ) +
  
  coord_sf(crs = "+proj=robin") +
  theme_void() +
  theme(
    panel.background = element_rect(fill = "white", color = NA),
    legend.position = "bottom",
    legend.text = element_text(size = 8),
    legend.title = element_text(size = 9, face = "bold")
  )

p

# To save the map 
ggsave("plots/SD1_raw_fig1a_map_fermented_cereals.png", p,
       width = 14, height = 8, dpi = 600)

ggsave("plots/SD1_raw_fig1a_map_fermented_cereals.svg", p,
       width = 14, height = 8)


