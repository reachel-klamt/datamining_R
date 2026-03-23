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
  
  
  
### correlation between claimant and respondent income group ####
  
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
  
  
  #### Sectors ####
  p_sector <- icsid_df |>
    filter(
      !is.na(economic_sector)
    ) |>
    count(economic_sector, sort = TRUE) |>
    ggplot(aes(x = n, y = reorder(economic_sector, n), fill = n)) +
    geom_col() +
    geom_text(aes(label = n), hjust = -0.2, size = 3.5) +
    scale_fill_gradient(low = "#FFF5F0", high = "#BD0026", guide = "none") +
    labs(
      title    = "Sectors Disputed",
      subtitle = "Number of ICSID cases by economic sector",
      x        = "Number of Cases",
      y        = NULL,
      caption  = "Source: ICSID"
    ) +
    theme_minimal(base_size = 11) +
    theme(
      plot.title      = element_text(face = "bold"),
      plot.background = element_rect(fill = "white", colour = NA)
    )
  
  ggsave(here("figures", "sector.png"), p_sector_claimant, width = 10, height = 6, dpi = 300)
  
  ### correlation between sector and income group of respondent ####
  # Recode sector group
  icsid_df <- icsid_df |>
    mutate(sector_group = case_when(
      economic_sector %in% c(
        "Oil, Gas & Mining",
        "Agriculture, Fishing & Forestry",
        "Water, Sanitation & Flood Protection"
      ) ~ "Resource & Infrastructure Extraction",
      is.na(economic_sector) ~ NA_character_,
      TRUE                   ~ "Other"
    ))
  
  # Heatmap: claimant vs respondent income group, faceted by sector group
  p_sector_heatmap <- icsid_df |>
    filter(
      !is.na(income_claimant), !is.na(income_respondent),
      !is.na(sector_group),
      income_claimant  != "Not classified",
      income_respondent != "Not classified"
    ) |>
    count(income_claimant, income_respondent, sector_group) |>
    mutate(
      income_claimant   = factor(income_claimant,  levels = income_order),
      income_respondent = factor(income_respondent, levels = income_order)
    ) |>
    ggplot(aes(x = income_respondent, y = income_claimant, fill = n)) +
    geom_tile(colour = "white") +
    geom_text(aes(label = n), size = 3.5) +
    scale_fill_gradient(low = "white", high = "#BD0026", name = "Cases") +
    facet_wrap(~ sector_group) +
    labs(
      title   = "ICSID Cases by Income Group and Sector Group",
      x       = "Respondent Income Group",
      y       = "Claimant Income Group",
      caption = "Source: ICSID"
    ) +
    theme_minimal(base_size = 11) +
    theme(
      axis.text.x     = element_text(angle = 25, hjust = 1),
      plot.title      = element_text(face = "bold"),
      plot.background = element_rect(fill = "white", colour = NA),
      strip.text      = element_text(face = "bold")
    )
  
  ggsave(here("figures", "heatmap_sector_group.png"), p_sector_heatmap, width = 12, height = 6, dpi = 300)
  
  # Chi-square
  sector_table <- icsid_df |>
    filter(
      !is.na(income_claimant), !is.na(income_respondent),
      !is.na(sector_group),
      income_claimant  != "Not classified",
      income_respondent != "Not classified"
    ) |>
    count(sector_group, income_respondent) |>
    pivot_wider(names_from = income_respondent, values_from = n, values_fill = 0) |>
    column_to_rownames("sector_group")
  
  print("Contingency table — sector group vs respondent income group:")
  print(sector_table)
  
  chi_sector <- chisq.test(sector_table)
  print(chi_sector)
  print(chi_sector$stdres)
  
  
  # Map of Income Groups
  library(wbstats)
  
  income_df <- wb_countries() |>
    select(iso3c, income_level)
  
  world_income <- world |>
    left_join(income_df, by = c("iso_a3" = "iso3c")) |>
    mutate(income_level = factor(income_level, levels = income_order))
  
  p_income_map <- ggplot(world_income) +
    geom_sf(aes(fill = income_level), colour = "white", linewidth = 0.1) +
    scale_fill_manual(
      values = c(
        "Low income"          = "#d73027",
        "Lower middle income" = "#fc8d59",
        "Upper middle income" = "#4575b4",
        "High income"         = "#313695"
      ),
      na.value = "grey90",
      name     = "Income Group"
    ) +
    labs(
      title   = "World Bank Income Groups",
      caption = "Source: World Bank"
    ) +
    theme_void(base_size = 11) +
    theme(
      plot.title      = element_text(face = "bold", hjust = 0.5),
      plot.background = element_rect(fill = "white", colour = NA),
      legend.position = "bottom"
    )
  
  ggsave(here("figures", "map_income.png"), p_income_map, width = 14, height = 7, dpi = 300)
  
  
  #### Time Trend ####

  p_trend_pattern <- icsid_df |>
    filter(
      !is.na(income_claimant),
      !is.na(income_respondent),
      !is.na(year),
      year <= 2025,
      income_claimant  != "Not classified",
      income_respondent != "Not classified"
    ) |>
    mutate(pattern = case_when(
      income_claimant == "High income" &
        income_respondent %in% c("Low income", "Lower middle income", "Upper middle income") ~ "High income vs Developing",
      income_claimant == "High income" &
        income_respondent == "High income"                                                   ~ "High income vs High income",
      TRUE                                                                                   ~ "Other combinations"
    )) |>
    count(year, pattern) |>
    bind_rows(
      icsid_df |>
        filter(!is.na(year), year <= 2025) |>
        count(year) |>
        mutate(pattern = "Total")
    ) |>
    mutate(pattern = factor(pattern, levels = c(
      "Total",
      "High income vs Developing",
      "High income vs High income",
      "Other combinations"
    ))) |>
    ggplot(aes(x = year, y = n, colour = pattern)) +
    geom_line(linewidth = 0.4, linetype = "dashed", alpha = 0.4) +
    geom_point(size = 1, alpha = 0.4) +
    geom_smooth(method = "loess", se = FALSE, linewidth = 0.7) +
    scale_colour_manual(
      values = c(
        "Total"                      = "black",
        "High income vs Developing"  = "#BD0026",
        "High income vs High income" = "#313695",
        "Other combinations"         = "grey50"
      ),
      name = "Pattern"
    ) +
    scale_x_continuous(breaks = seq(1970, 2025, by = 5)) +
    labs(
      title    = "ICSID Cases Over Time by Dispute Pattern",
      subtitle = "Smoothed trend lines with raw data in background",
      x        = "Year",
      y        = "Number of Cases",
      caption  = "Source: ICSID"
    ) +
    theme_minimal(base_size = 11) +
    theme(
      plot.title      = element_text(face = "bold"),
      plot.background = element_rect(fill = "white", colour = NA),
      legend.position = "bottom"
    )
  
  ggsave(here("figures", "trend_pattern.png"), p_trend_pattern, width = 12, height = 6, dpi = 300)