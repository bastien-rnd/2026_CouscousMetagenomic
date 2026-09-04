# DESCRIPTION ----------------------------------------------------------------

# This script generates histogram of microbial genus across fermented cereals (n=94)


# PACKAGES ----------------------------------------------------------------
library(tidyverse)
library(readxl)
library(writexl)
library(ggpubr)
# ============================================================
# 1. METADATA
# ============================================================


input_metadata <- "metadata_samples.xlsx"

metadata <- read_excel(input_metadata) %>%
  filter(filter_analysis == "Y")


# ============================================================
# 2. METAPHLAN TABLE
# ============================================================

sylph_dir <- "merged_sylph_abundance_table.tsv"
sylph_species_clean <- read_excel(
  "merged_sylph_abundance_0.1_clean.xlsx"
)

metaphlan_dir <- "merged_metaphlan_abundance_table.tsv"
metaphlan_species_clean <- read_excel(
  "merged_metaphlan_abundance_0.1_clean.xlsx"
)

#Sensitivity 
# ============================================================
# NUMBER OF SPECIES DETECTED PER SAMPLE
# ============================================================

# Samples communs aux deux outils
common_samples <- intersect(
  colnames(sylph_species_clean)[-c(1:7)],
  colnames(metaphlan_species_clean)[-c(1:7)]
)

# Nombre d'espèces détectées par échantillon
species_comparison <- tibble(
  Sample = common_samples,
  MetaPhlAn = sapply(
    common_samples,
    function(x) sum(metaphlan_species_clean[[x]] > 0, na.rm = TRUE)
  ),
  Sylph = sapply(
    common_samples,
    function(x) sum(sylph_species_clean[[x]] > 0, na.rm = TRUE)
  )
)

# Groupes F et NF
species_comparison <- species_comparison %>%
  mutate(
    Group = case_when(
      str_starts(Sample, "R") ~ "Cereal flours",
      str_starts(Sample, "FMi") |
        str_starts(Sample, "FMa") |
        str_starts(Sample, "FMM") |
        str_starts(Sample, "FSo") ~ "Couscous",
      TRUE ~ "Other fermented cereals"
    )
  )

# Correlation
cor_spearman <- cor.test(
  species_comparison$MetaPhlAn,
  species_comparison$Sylph,
  method = "spearman"
)

cor_pearson <- cor.test(
  species_comparison$MetaPhlAn,
  species_comparison$Sylph,
  method = "pearson"
)

r <- unname(cor_pearson$estimate)
r2 <- r^2
p <- cor_pearson$p.value

cor_label <- paste0(
  "Pearson r = ", round(unname(cor_pearson$estimate), 2),
  "\nSpearman ρ = ", round(unname(cor_spearman$estimate), 2)
)

ggplot(
  species_comparison,
  aes(
    x = MetaPhlAn,
    y = Sylph,
    color = Group
  )
) +
  geom_point(
    size = 2.5,
    alpha = 0.9
  ) +
  geom_abline(
    intercept = 0,
    slope = 1,
    linetype = "dashed"
  ) +
  annotate(
    "text",
    x = 30,
    y = 15,
    label = cor_label,
    hjust = 0,
    vjust = 1,
    size = 3
  ) +
  coord_equal(
    xlim = c(0, 60),
    ylim = c(0, 60)
  ) +
  labs(
    x = "MetaPhlAn - Number of species",
    y = "Sylph - Number of species"
  ) +
  scale_color_manual(
  values = c(
    "Cereal flours" = "#86BF94",
    "Couscous" = "#E69F00",
    "Other fermented cereals" = "#B0AFED")
  ) +
  theme_classic()

ggsave(
  "plots/metaphlan/species_comparison_metaphlan_sylph.png",
  width = 12,
  height = 12,
  units = "cm",
  dpi = 300,
  bg = "white"
)

ggsave(
  "plots/metaphlan/species_comparison_metaphlan_sylph.svg",
  width = 12,
  height = 12,
  units = "cm",
  bg = "white"
)

#Comparaison des espèces 
# ============================================================
# Species detection comparison per sample
# ============================================================

common_samples <- intersect(
  colnames(sylph_species_clean)[-c(1:7)],
  colnames(metaphlan_species_clean)[-c(1:7)]
)

#Homogénéisation des noms d'espèces
sylph_species_clean <- sylph_species_clean %>%
  mutate(
    Species = str_replace_all(Species, " ", "_")
  )

sylph_long <- sylph_species_clean %>%
  select(Species, all_of(common_samples)) %>%
  pivot_longer(
    cols = all_of(common_samples),
    names_to = "Sample",
    values_to = "Sylph"
  )

metaphlan_long <- metaphlan_species_clean %>%
  select(Species, all_of(common_samples)) %>%
  pivot_longer(
    cols = all_of(common_samples),
    names_to = "Sample",
    values_to = "MetaPhlAn"
  )

species_detection <- full_join(
  sylph_long,
  metaphlan_long,
  by = c("Species", "Sample")
) %>%
  mutate(
    Sylph = replace_na(Sylph, 0),
    MetaPhlAn = replace_na(MetaPhlAn, 0)
  ) %>%
  filter(
    Sylph != 0 | MetaPhlAn != 0
  )

species_detection <- species_detection %>%
  mutate(
    Detection = case_when(
      Sylph > 0 & MetaPhlAn > 0 ~ "Both",
      Sylph > 0 & MetaPhlAn == 0 ~ "Sylph only",
      Sylph == 0 & MetaPhlAn > 0 ~ "MetaPhlAn only",
      TRUE ~ "Neither"
    )
  ) %>%
  filter(Detection != "Neither")

species_detection_summary <- species_detection %>%
  count(
    Sample,
    Detection,
    name = "Number"
  )

species_detection_summary <- species_detection_summary %>%
  complete(
    Sample,
    Detection = c(
      "Sylph only",
      "Both",
      "MetaPhlAn only"
    ),
    fill = list(Number = 0)
  )

ggplot(
  species_detection_summary,
  aes(
    x = Sample,
    y = Number,
    fill = Detection
  )
) +
  geom_col(
    width = 0.85
  ) +
  scale_fill_manual(
    values = c(
      "Sylph only" = "#0072B2",
      "Both" = "#009E73",
      "MetaPhlAn only" = "#D55E00"
    )
  ) +
  labs(
    x = NULL,
    y = "Number of species",
    fill = NULL
  ) +
  theme_classic() +
  theme(
    axis.text.x = element_text(
      angle = 90,
      hjust = 1,
      vjust = 0.5,
      size= 4
    ),
    legend.position = "top",
    legend.text = element_text(size = 7)
  )

ggsave(
  "plots/metaphlan/sensitivity.png",
  width = 18,
  height = 8,
  units = "cm",
  dpi = 300
)

ggsave(
  "plots/metaphlan/sensitivity.svg",
  width = 18,
  height = 8,
  units = "cm"
)

species_lists <- species_detection %>%
  group_by(Sample, Detection) %>%
  summarise(
    Species = paste(
      sort(unique(Species)),
      collapse = "; "
    ),
    .groups = "drop"
  ) %>%
  pivot_wider(
    names_from = Detection,
    values_from = Species,
    values_fill = ""
  )

write_xlsx(
  species_lists,
  "species_detection_lists_by_sample.xlsx"
)

species_lists_long <- species_detection %>%
  select(
    Sample,
    Species,
    Detection
  ) %>%
  arrange(
    Sample,
    Detection,
    Species
  )

write_xlsx(
  species_lists_long,
  "species_detection_lists_by_sample_long.xlsx"
)
