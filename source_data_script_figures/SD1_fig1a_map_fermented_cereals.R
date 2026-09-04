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
    colours = c("#f3f3f3", "#ffffd4", "#fed98e", "#fe9929", "#cc4c02"),
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



# PieChart
#this study, PRJEB108338, 19, #E69F00
#CM_INJERA, PRJNA504891, 2, #0072B2
#LandisEA_2021, PRJNA589612, 40, #009E73"
#Leech_xxxx, PRJNA1052643, 27, "#56B4E9"
#Leech_2020, PRJEB35321, 1, "#CC79A7"
#LopezSanchezR_2023, PRJNA648868, 3, "#F0E442"
#Shangpliang_2023_b, PRJNA914730, 2, "#D55E00"

# ============================================================
# Piechart avec secteur éclaté pour "This study"
# ============================================================

# ---- Données ----
# ============================================================
# Piechart avec secteur eclate pour "This study"
# - secteurs ordonnes par ordre croissant du nombre d'echantillons
# - bordures noires
# - etiquettes de donnees a l'exterieur, reliees par des traits
# ============================================================

# ---- Donnees ----
# ============================================================
# Piechart avec secteur eclate pour "This study"
# - secteurs ordonnes par ordre croissant du nombre d'echantillons
# - le plus gros secteur commence a la verticale, en haut (12h)
# - bordures blanches
# - etiquettes de donnees a l'exterieur, reliees par des traits
# ============================================================

# ---- Donnees ----
# ============================================================
# Piechart avec secteur eclate pour "This study"
# - secteurs ordonnes par ordre croissant du nombre d'echantillons
# - bordures blanches epaisses
# - etiquettes de donnees a l'exterieur, reliees par des traits
# ============================================================

# ---- Donnees ----
# ============================================================
# Piechart avec secteur eclate pour "This study"
# - secteurs ordonnes par ordre croissant du nombre d'echantillons
# - bordures blanches epaisses
# - etiquettes de donnees a l'exterieur, reliees par des traits
# ============================================================

# ---- Donnees ----
df <- data.frame(
  name = c("This study", "CM_INJERA", "LandisEA_2021", "Leech_xxxx", "Leech_2020",
           "LopezSanchezR_2023", "Shangpliang_2023_b"),
  accession = c("PRJEB108338", "PRJNA504891", "PRJNA589612", "PRJNA1052643",
                "PRJEB35321", "PRJNA648868", "PRJNA914730"),
  n = c(19, 2, 40, 27, 1, 3, 2),
  color = c("#E69F00", "#0072B2", "#009E73", "#56B4E9",
            "#CC79A7", "#F0E442", "#D55E00"),
  stringsAsFactors = FALSE
)

# ---- Tri croissant par effectif ----
df <- df[order(df$n), ]
rownames(df) <- NULL

# ---- Calcul des angles (sens trigo, depart a 0) ----
df$fraction    <- df$n / sum(df$n)
df$ymax        <- cumsum(df$fraction)
df$ymin        <- c(0, head(df$ymax, -1))
df$angle_start <- df$ymin * 2 * pi
df$angle_end   <- df$ymax * 2 * pi

df$mid_angle <- (df$angle_start + df$angle_end) / 2

# Distance de decalage du secteur eclate
explode_amount <- 0.15
df$explode <- ifelse(df$name == "This study", explode_amount, 0)

# ---- Fonction pour dessiner un secteur (wedge) ----
draw_wedge <- function(angle_start, angle_end, radius = 1, center = c(0, 0), n = 200) {
  theta <- seq(angle_start, angle_end, length.out = n)
  x <- c(0, radius * cos(theta), 0) + center[1]
  y <- c(0, radius * sin(theta), 0) + center[2]
  list(x = x, y = y)
}

# ---- Fonction pour l'etiquette exterieure avec trait de rappel ----
add_outer_label <- function(mid_angle, cx, cy, label,
                             radius_edge = 1, radius_elbow = 1.18, x_text = 1.42) {
  x0 <- cx + radius_edge  * cos(mid_angle)
  y0 <- cy + radius_edge  * sin(mid_angle)
  x1 <- cx + radius_elbow * cos(mid_angle)
  y1 <- cy + radius_elbow * sin(mid_angle)
  side <- ifelse(cos(mid_angle) >= 0, 1, -1)
  x2 <- side * x_text
  y2 <- y1

  segments(x0, y0, x1, y1, col = "grey30", lwd = 1)
  segments(x1, y1, x2, y2, col = "grey30", lwd = 1)
  text(x2 + side * 0.03, y2, label, adj = c(ifelse(side > 0, 0, 1), 0.5), cex = 0.8)
}

# ---- Trace ----
svg("plots/piechart_exploded.svg", width = 9, height = 6.8)
par(mar = c(1, 1, 1, 12), xpd = TRUE)
plot(NA, xlim = c(-1.9, 1.9), ylim = c(-1.5, 1.5), asp = 1,
     axes = FALSE, xlab = "", ylab = "")

for (i in seq_len(nrow(df))) {
  cx <- df$explode[i] * cos(df$mid_angle[i])
  cy <- df$explode[i] * sin(df$mid_angle[i])

  w <- draw_wedge(df$angle_start[i], df$angle_end[i], radius = 1, center = c(cx, cy))
  polygon(w$x, w$y, col = df$color[i], border = "white", lwd = 4)

  pct <- round(df$fraction[i] * 100, 1)
  label <- paste0(df$name[i], " - ", pct, "%")
  add_outer_label(df$mid_angle[i], cx, cy, label,
                   radius_edge = 1 + df$explode[i])
}

# ---- Legende avec les numeros d'accession ----
legend("right", inset = c(-0.62, 0),
       legend = paste0(df$name, " (", df$accession, ", n=", df$n, ")"),
       fill = df$color, bty = "n", cex = 0.72, title = "Jeux de donnees")

dev.off()
