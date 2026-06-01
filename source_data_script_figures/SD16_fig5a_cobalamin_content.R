# DESCRIPTION ----------------------------------------------------------------

# This script generates the whisker plot on cobalamin content in cereal flours (n=19) and couscous (n=19).


# PACKAGES ----------------------------------------------------------------
library(tidyverse)
library(readxl)
library(writexl)
library(emmeans)
library(lme4)


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

metadata_couscous <- metadata %>%
  filter(couscous %in% "Y")



# FONCTIONS ---------------------------------------------------------------

# To transform number in caracter
replace_numbers_by_letters <- function(numbers) {
  digits <- strsplit(numbers, "")[[1]]
  
  letters <- sapply(digits, function(d) intToUtf8(96 + as.integer(d)))
  
  paste(letters, collapse = "")
}


metadata_couscous$cereals <- recode(metadata_couscous$cereals,
                                    "maize" = "Maize",
                                    "millet" = "Millet",
                                    "millet_maize" = "Millet-Maize",
                                    "sorghum" = "Sorghum"
)



# Vit B12 - Cobalamin -----------------------------------------------------------

## LMM ----------------------------------------------------------------
metadata_couscous$`b12 (µg/100g)` <- as.numeric(as.character(metadata_couscous$`b12 (µg/100g)`))
model_lmm <- lmer(`b12 (µg/100g)` ~ cereals * ferm + (1 | batch_id), data = metadata_couscous)

summary(model_lmm)
anova(model_lmm)

emm <- emmeans(model_lmm, ~ cereals * ferm)
post_hoc <- pairs(emm, adjust = "tukey")

cld_df <- as.data.frame(multcomp::cld(emm, adjust = "sidak"))
cld_df$group <- paste(cld_df$cereals, cld_df$ferm, sep = "_")
cld_df$.group <- trimws(cld_df$.group)

cld_df$.group <- sapply(cld_df$.group, replace_numbers_by_letters)
cld_df$letter <- trimws(cld_df$.group)

plot_data <- metadata_couscous %>%
  group_by(cereals, ferm) %>%
  summarise(
    mean_cobalamin = mean(`b12 (µg/100g)`, na.rm = TRUE),
    min_cobalamin = min(`b12 (µg/100g)`, na.rm = TRUE),
    max_cobalamin = max(`b12 (µg/100g)`, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(group = paste(cereals, ferm, sep = "_")) %>%
  left_join(cld_df %>% dplyr::select(group, letter), by = "group")

metadata_couscous$group <- paste(metadata_couscous$cereals, metadata_couscous$ferm, sep = "_")

group_levels <- plot_data %>%
  distinct(group, ferm) %>%
  arrange(desc(ferm)) %>%
  pull(group)

metadata_couscous$group <- factor(metadata_couscous$group, levels = group_levels)
plot_data$group <- factor(plot_data$group, levels = group_levels)

plot_data <- plot_data %>%
  mutate(min_cobalamin = case_when(
    group == "Maize_no" ~ 0.072,  
    group == "Millet_no" ~ 0.068,  
    group == "Millet-Maize_no" ~ 0.075,  
    group == "Sorghum_no" ~ 0.057,  
    group == "Maize_yes" ~ 0.027,  
    group == "Millet_yes" ~ 0.055,  
    group == "Millet-Maize_yes" ~ 0.002,  
    group == "Sorghum_yes" ~ 0.002,  
    TRUE ~ min_cobalamin            
  ))

plot_data <- plot_data %>%
  mutate(min_cobalamin = min_cobalamin - 0.05 * max(min_cobalamin, na.rm = TRUE))



## Plot ---------------------------------------------------------------
ggplot(metadata_couscous, aes(x = cereals, y = `b12 (µg/100g)`, fill = cereals)) +
  geom_boxplot(size = 0.5) +
  geom_jitter(size = 0.3, width = 0.1, alpha = 0.8, color = "grey30") +
  scale_fill_manual(values = colors[["cereals_couscous"]]) +
  geom_text(data = plot_data,
            aes(x = cereals, y = min_cobalamin, label = letter),
            inherit.aes = FALSE,
            vjust = 1, size = 2) +
  facet_wrap(~ ferm, labeller = labeller(ferm = c("no" = "Cereals flours", "yes" = "Couscous"))) +
  theme_minimal() +
  labs(
    title = "Dosage de vitamine vitc avant et après fermentation",
    x = "Cereals",
    y = "Cobalamin (µg/100g FM)",
    fill = "Cereals"
  ) +
  theme(
    strip.background = element_rect(fill = "lightgray", color = "black", size = 0.25),
    axis.text.x = element_blank(),
    axis.text.y = element_text(size = 5),
    text = element_text(size = 7),
    plot.title = element_blank(),
    panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.25),
    axis.title.x = element_blank(),
    axis.title.y = element_text(size = 7),
    legend.key = element_blank(),
    legend.key.size = unit(4, "mm"),
    legend.title = element_text(size = 7),
    legend.text = element_text(size = 5)
  )

ggsave(
  filename = "plots/SD16_fig5a_cobalamin_content.png",  
  plot = last_plot(),              
  width = 90,                      
  height = 70,
  units = "mm",
  dpi = 300,                        
  bg = "white"
)

ggsave(
  filename = "plots/SD16_fig5a_cobalamin_content.svg", 
  plot = last_plot(),              
  width = 75,                      
  height = 70,
  units = "mm"
)
