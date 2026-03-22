########################################
############ Data Analysis  ###########
######################################
library(tidyverse)
library(here)
library(sf)
library(rnaturalearth)
library(rnaturalearthdata)
library(countrycode)
library(patchwork)

#### Load data ####
  icsid_df <- readRDS(here("data_preprocessed", "icsid.rds"))


#### Preparations for Visualization ####
  # Load world map data
  # some countries have different names in the world map data (because of oversea territories) and the ICSID data, so we need to adjust them
  world <- ne_countries(scale = "medium", returnclass = "sf") |>
    filter(continent != "Antarctica") |>
    mutate(iso_a3 = case_when(
      name == "France" ~ "FRA",
      name == "Norway" ~ "NOR",
      name == "Kosovo" ~ "XKX",
      TRUE             ~ iso_a3
    ))
  
  ### check if claimant countries not in rnaturalearth
  # similar code for respondent countries
  # missing_claimant <- icsid_df |>
  #  filter(!is.na(iso3_claimant)) |>
  #  distinct(iso3_claimant) |>
  #  filter(!iso3_claimant %in% world_iso3) |>
  #  pull(iso3_claimant)
  
  # print("Missing claimant countries:")
  # print(missing_claimant)

  # Prepare counts from the cases
  claimant_counts <- icsid_df |>
    filter(!is.na(iso3_claimant)) |>
    count(iso3_claimant, name = "n_claimant")
  
  respondent_counts <- icsid_df |>
    filter(!is.na(iso3_respondent)) |>
    count(iso3_respondent, name = "n_respondent")
  
  # Add the number of each count to the world map dataframe
  world_claimant <- world |>
    left_join(claimant_counts, by = c("iso_a3" = "iso3_claimant"))
  
  world_respondent <- world |>
    left_join(respondent_counts, by = c("iso_a3" = "iso3_respondent"))
  
  # Plot
  # plot for the claimant
  p_claimant <- ggplot(world_claimant) +
    geom_sf(aes(fill = n_claimant), colour = "white", linewidth = 0.1) +
    scale_fill_gradient(low = "#FFF5F0", high = "#BD0026", na.value = "grey90", name = "Cases") +
    labs(title = "Claimant — Country") +
    theme_void(base_size = 11) +
    theme(plot.title = element_text(face = "bold", hjust = 0.5))
  
  # plot for the respondent
  p_respondent <- ggplot(world_respondent) +
    geom_sf(aes(fill = n_respondent), colour = "white", linewidth = 0.1) +
    scale_fill_gradient(low = "#F7FBFF", high = "#084594", na.value = "grey90", name = "Cases") +
    labs(title = "Respondent — Country") +
    theme_void(base_size = 11) +
    theme(plot.title = element_text(face = "bold", hjust = 0.5))
  
  p_claimant / p_respondent +
    plot_annotation(
      title   = "ICSID Cases by Country",
      caption = "Source: ICSID"
    )
  
  ggsave(here("figures", "maps_country.png"), width = 14, height = 10, dpi = 300)
  

  # Heatmap — claimant vs respondent income group
  income_order <- c("Low income", "Lower middle income", "Upper middle income", "High income")
  
  p_heatmap <- icsid_df |>
    filter(
      !is.na(income_claimant), !is.na(income_respondent),
      income_claimant  != "Not classified",
      income_respondent != "Not classified"
    ) |>
    count(income_claimant, income_respondent) |>
    mutate(
      income_claimant  = factor(income_claimant,  levels = income_order),
      income_respondent = factor(income_respondent, levels = income_order)
    ) |>
    ggplot(aes(x = income_respondent, y = income_claimant, fill = n)) +
    geom_tile(colour = "white") +
    geom_text(aes(label = n), size = 3.5) +
    scale_fill_gradient(low = "white", high = "#BD0026", name = "Cases") +
    labs(
      title   = "ICSID Cases: Claimant vs Respondent Income Group",
      x       = "Respondent Income Group",
      y       = "Claimant Income Group",
      caption = "Source: ICSID"
    ) +
    theme_minimal(base_size = 11) +
    theme(
      axis.text.x = element_text(angle = 25, hjust = 1),
      plot.title  = element_text(face = "bold"),
      plot.background = element_rect(fill = "white", colour = NA)
    )
  
  ggsave(here("figures", "heatmap_income.png"), p_heatmap, width = 10, height = 7, dpi = 300)
  
  
  
### correlation between claimant and respondent income group
  
  # Chi-square — claimant vs respondent income group
  income_table <- icsid_df |>
    filter(!is.na(income_claimant), !is.na(income_respondent)) |>
    count(income_claimant, income_respondent) |>
    pivot_wider(names_from = income_respondent, values_from = n, values_fill = 0) |>
    column_to_rownames("income_claimant")
  
  print("Contingency table — claimant vs respondent income group:")
  print(income_table)
  
  chi_test <- chisq.test(income_table)
  print(chi_test)
  
  