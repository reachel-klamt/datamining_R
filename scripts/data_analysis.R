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
  
  # Get world map and add UN subregion (since it is not included in the rnaturalearth package)
  # cutsom match because Kosovo is not recognized by countrycode, but it is included in the rnaturalearth package, so we need to manually assign it to the correct UN subregion
  world <- ne_countries(scale = "medium", returnclass = "sf") |>
    filter(continent != "Antarctica") |>
    mutate(un_subregion = countrycode(iso_a3, "iso3c", "un.regionsub.name",
                                      custom_match = c("XKX" = "Southern Europe")))


# Prepare counts form the cases
claimant_counts <- icsid_df |>
  filter(!is.na(unsubregion_claimant)) |>
  count(unsubregion_claimant, name = "n_claimant")

respondent_counts <- icsid_df |>
  filter(!is.na(unsubregion_respondent)) |>
  count(unsubregion_respondent, name = "n_respondent")

  # Add the number of each count to the world map dataframe
  world_claimant <- world |>
    left_join(claimant_counts, by = c("un_subregion" = "unsubregion_claimant"))
  
  world_respondent <- world |>
    left_join(respondent_counts, by = c("un_subregion" = "unsubregion_respondent"))

  #  Plot
    # plot for the claimant
    p_claimant <- ggplot(world_claimant) +
      geom_sf(aes(fill = n_claimant), colour = "white", linewidth = 0.1) +
      scale_fill_gradient(low = "#FFF5F0", high = "#BD0026", na.value = "grey90", name = "Cases") +
      labs(title = "Claimant — UN Subregion") +
      theme_void(base_size = 11) +
      theme(plot.title = element_text(face = "bold", hjust = 0.5))
    
    # plot for the respondent
    p_respondent <- ggplot(world_respondent) +
      geom_sf(aes(fill = n_respondent), colour = "white", linewidth = 0.1) +
      scale_fill_gradient(low = "#F7FBFF", high = "#084594", na.value = "grey90", name = "Cases") +
      labs(title = "Respondent — UN Subregion") +
      theme_void(base_size = 11) +
      theme(plot.title = element_text(face = "bold", hjust = 0.5))
    
    p_claimant / p_respondent +
      plot_annotation(
        title   = "ICSID Cases by UN Subregion",
        caption = "Source: ICSID"
      )
  
  ggsave(here("figures", "maps_unsubregion.png"), width = 14, height = 10, dpi = 300)