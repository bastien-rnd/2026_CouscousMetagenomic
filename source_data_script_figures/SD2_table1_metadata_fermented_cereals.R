# DESCRIPTION ----------------------------------------------------------------

# This script generates the table of metadata of fermented cereals analysed in the study (Table 1)

# PACKAGES ----------------------------------------------------------------
library(gt)
library(tidyverse)
library(readxl)

# To set working directory 
setwd("source_data_script_figures")

# To import data
data <- read_excel("SD2_table1_metadata_fermented_cereals.xlsx")

# To create table
table_pub <- data %>%
  gt() %>%
  cols_align(
    align = "center",
    columns = everything()
  ) %>%
  tab_options(
    table.font.names = "Arial",
    table.font.size = px(12),
    column_labels.font.weight = "bold",
    table_body.hlines.color = "grey85",
    table.border.top.width = px(0),
    table.border.bottom.color = "black") %>%
  tab_source_note(
    source_note = "Details on all samples can be found in Supplementary Table 2."
  ) %>%
  cols_width(
    Continent ~ px(70),
    Country ~ px(50),
    Product ~ px(70),
    `Number samples` ~ px(60),
    `Consumption form` ~ px(85),
    Cereals ~ px(130),
    Hulling ~ px(50),
    Soaking ~ px(55),
    Milling ~ px(50),
    `Fermentation duration` ~ px(90),
    `Fermentation type` ~ px(90),
    Backslopping ~ px(90),
    `Final cooking` ~ px(90),
    
  ) %>%
  tab_style(
    style = cell_borders(
      sides = "top",
      color = "black",
      weight = px(1)
    ),
    locations = cells_body(
      rows = c(11, 12, 13, 15, 16)
    )
  )

table_pub

# To export final table
gtsave(table_pub, "plots/SD2_table1_metadata_fermented_cereals.png")
