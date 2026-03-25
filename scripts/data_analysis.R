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
library(wbstats)
library(lubridate)

#### LOAD DATA ####
  icsid_df <- readRDS(here("data_preprocessed", "icsid.rds"))


#### PREPARATIONS FOR ANALYSIS ####
  # World df prep for mapping
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
  
  ## check if claimant countries not in rnaturalearth
  # similar code for respondent countries
  # missing_claimant <- icsid_df |>
  #  filter(!is.na(iso3_claimant)) |>
  #  distinct(iso3_claimant) |>
  #  filter(!iso3_claimant %in% world_iso3) |>
  #  pull(iso3_claimant)
  
  # print("Missing claimant countries:")
  # print(missing_claimant)


  # count claimant cases per country
  claimant_counts <- icsid_df |>
    filter(!is.na(iso3_claimant)) |>
    count(iso3_claimant, name = "n_claimant")
  
  # count respondent cases per country
  respondent_counts <- icsid_df |>
    filter(!is.na(iso3_respondent)) |>
    count(iso3_respondent, name = "n_respondent")

  # Join both counts into the world data frame
  world <- world |>
    left_join(claimant_counts,   by = c("iso_a3" = "iso3_claimant")) |>
    left_join(respondent_counts, by = c("iso_a3" = "iso3_respondent"))
  
  ## ICSID_DF
  # converting year variable to numeric (extracting the year from the date format)
  icsid_df <- icsid_df |>
    mutate(year = lubridate::year(lubridate::ymd(date_registered)))
  
  # Recode sector group in two groups (extractive and non-extractive sectors)
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
  
  # Clean base dataset — removes incomplete and unclassified income groups and makes them into factors
  income_order <- c("Low income", "Lower middle income", "Upper middle income", "High income")
  
  icsid_clean <- icsid_df |>
    filter(
      !is.na(income_claimant), !is.na(income_respondent),
      income_claimant  != "Not classified",
      income_respondent != "Not classified"
    ) |>
    mutate(
      income_claimant   = factor(income_claimant,  levels = income_order),
      income_respondent = factor(income_respondent, levels = income_order)
    )
  
#### VISUALIZATION ####
  
  ##### Plot: claimant and respondent map #####
  # plot for the claimant
  p_claimant <- ggplot(world) +
    geom_sf(aes(fill = n_claimant), colour = "white", linewidth = 0.1) +
    scale_fill_gradient(low = "#FFF5F0", high = "#BD0026", na.value = "grey90", name = "Cases") +
    labs(title = "Claimant — Country") +
    theme_void(base_size = 11) +
    theme(plot.title = element_text(face = "bold", hjust = 0.5))
  
  # plot for the respondent
  p_respondent <- ggplot(world) +
    geom_sf(aes(fill = n_respondent), colour = "white", linewidth = 0.1) +
    scale_fill_gradient(low = "#F7FBFF", high = "#084594", na.value = "grey90", name = "Cases") +
    labs(title = "Respondent — Country") +
    theme_void(base_size = 11) +
    theme(plot.title = element_text(face = "bold", hjust = 0.5))
  
  p_cases_map <- p_claimant / p_respondent +
    plot_annotation(
      title   = "ICSID Cases by Country",
      caption = "Source: ICSID"
    )
  
  ggsave(here("figures", "maps_country.png"), width = 14, height = 10, dpi = 300)
  
  ##### Plot : Map of Income Groups (independent of my webscraping) #####
  # Visualizing the distribution of income groups (for all countries)
  p_income_map <- world |>
    # adding the data from the wb-package to the world map data (matching the iso3c code from the wb-package with the iso_a3 code from the world map data)
    left_join(
      wb_countries() |> select(iso3c, income_level),
      by = c("iso_a3" = "iso3c")
    ) |>
    mutate(income_level = factor(income_level, levels = income_order)) |>
    ggplot() +
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
  
  
  ##### Plot: Heatmap of claimant vs respondent income group #####
  p_heatmap <- icsid_clean |>
    # creates an internal data frame with the count of cases for each combination and orders them according to the predefined order of income groups
    count(income_claimant, income_respondent) |>
    # creating the plot
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
  

  ##### Statistics: correlation between claimant and respondent income group ######
  # creating contingency table for chi-squared test
  income_table <- icsid_clean |>
    count(income_claimant, income_respondent) |>
    pivot_wider(names_from = income_respondent, values_from = n, values_fill = 0) |>
    column_to_rownames("income_claimant")
  
  print("Contingency table — claimant vs respondent income group:")
  print(income_table)
  
  # conducting chi-squared test to check for independence between claimant and respondent income groups
  chi_test <- chisq.test(income_table)
  print(chi_test)
  
  ##### Plot: Sector #####
  p_sector <- icsid_clean |>
    # filter out missings
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
  
  ggsave(here("figures", "sector.png"), p_sector, width = 10, height = 6, dpi = 300)
  
  ##### Plot: Correlation Sector Group and Income ####
  icsid_clean <- icsid_clean |>
    mutate(sector_group = factor(sector_group, levels = c(
      "Resource & Infrastructure Extraction",
      "Other"
    )))
  
  # Heatmap for each sector group
  p_sector_heatmap <- icsid_clean |>
    filter(!is.na(sector_group)) |>
    # create df with count of cases for each combination of claimant income group, respondent income group and sector group
    count(income_claimant, income_respondent, sector_group) |>
    # creating the plot
    ggplot(aes(x = income_respondent, y = income_claimant, fill = n)) +
    geom_tile(colour = "white") +
    geom_text(aes(label = n), size = 3.5) +
    scale_fill_gradient(low = "white", high = "#BD0026", name = "Cases") +
    # creating separate heatmap for each sector group
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
  
  ##### Statistics: correlation between claimant and respondent sector group ######
  # creating contingency table — filtered to extractive sector only
  # testing whether within extractive sectors, high-income claimants disproportionately sue lower-income respondents
  extractive_table <- icsid_clean |>
    filter(sector_group == "Resource & Infrastructure Extraction") |>
    # create df with count of cases for each combination of claimant and respondent income group
    # chi-squared not possible with 3x3 contingency table
    # for thesis significant association between claimant and respondent income group within extractive sectors
    count(income_claimant, income_respondent) |>
    pivot_wider(names_from = income_respondent, values_from = n, values_fill = 0) |>
    column_to_rownames("income_claimant")
  
  print("Contingency table — extractive sector: claimant vs respondent income group:")
  print(extractive_table)
  
  # Run chi-squared test to check for independence between claimant and respondent income group within extractive sectors
  chi_extractive <- chisq.test(extractive_table)
  print(chi_extractive)
  # standardized residuals to identify which combinations of claimant and respondent income group contribute most to the chi-squared statistic
  print(chi_extractive$stdres)

  
  
  ##### Plot: Time Trend #####
  # filtering like always but only until 2025 to avoid outliers in the future years
  trend_base <- icsid_clean |>
    filter(
      !is.na(year), year <= 2025,
    )
  # creating a new variable "pattern" to categorize each case into different three different groups based on the income of claimant and respondent
  p_trend_pattern <- trend_base |>
    mutate(pattern = case_when(
      # case: high income claimant vs developing respondent (low, lower middle and upper middle income)
      income_claimant == "High income" &
        income_respondent %in% c("Low income", "Lower middle income", "Upper middle income") ~ "High income vs Developing",
      # case: high income claimant vs high income respondent
      income_claimant == "High income" &
        income_respondent == "High income" ~ "High income vs High income",
      # case: all other combinations
      TRUE ~ "Other combinations"
    )) |>
    # counting the number of cases per year for each pattern
    count(year, pattern) |>
    bind_rows(
      trend_base |>
        # counting the total number of cases per year regardless of the pattern
        count(year) |>
        mutate(pattern = "Total")
    ) |>
    # Converts pattern to a factor with a fixed order
    mutate(pattern = factor(pattern, levels = c(
      "Total",
      "High income vs Developing",
      "High income vs High income",
      "Other combinations"
    ))) |>
    # creating the plot
    ggplot(aes(x = year, y = n, colour = pattern)) +
    # raw data
    geom_line(linewidth = 0.4, linetype = "dashed", alpha = 0.4) +
    geom_point(size = 1, alpha = 0.4) +
    # smoothed trend lines using loess method (local regression)
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
    # setting x-axis numbering
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