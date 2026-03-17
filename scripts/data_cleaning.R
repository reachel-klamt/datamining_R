#######################################
########### Data cleaning  ##########
######################################
library(jsonlite)
library(tidyverse)
library(here)

## Loading the two datasets
  cases_list <- fromJSON(here("data_raw", "icsid_raw.json"), simplifyVector = FALSE)$data$GetAllCasesResult
  details_df <- readRDS(here("data_raw", "icsid_details.rds"))
  

## Extract relevant information from cases_list and create a data frame
  #map_df is a function from the purrr package that applies a function to each element of a list and combines the results into a data frame
  cases_df <- map_df(cases_list, function(case) { 
    
    proc <- case$caseproceedings[[1]] # extract the first element of the caseproceedings list, which contains the date_registered information
    
    tibble(
      case_no         = case$caseno,
      claimant        = case$claimant,
      respondent      = case$respondent,
      date_registered = as.Date(mdy_hms(proc$dateregistered)),
      status          = case$status
    )
  })
  
  # Join with details df that was already webscraped
  icsid_df <- cases_df |>
    mutate(case_no = trimws(case_no)) |>
    left_join(details_df |> mutate(case_no = trimws(case_no)), by = "case_no") |>
    select(
      case_no, claimant, claimant_nationality, respondent,
      economic_sector, subject, instrument,
      rules_applied, date_registered, status
    ) |>
    mutate(across(where(is.character), ~ na_if(trimws(.x), "")))
  
  # extracting the country from the claimant company (the nationalities are always in brackets)
  icsid_df <- icsid_df |>
    mutate(
      claimant_nationality = str_extract(claimant_nationality, "(?<=\\()[^)]+(?=\\))")
    )
  
  # Converting respondent to country code
  icsid_df <- icsid_df |>
    mutate(
      iso3_respondent = countrycode::countrycode(respondent,
                                  origin      = "country.name",
                                  destination = "iso3c")
      )
  
  # check cases where it didn't work
  icsid_df |>
    filter(is.na(iso3_respondent)) |>
    select(case_no, respondent)
  
    # Fix cases where the respondent is a country but not recognized by countrycode
    icsid_df <- icsid_df |>
    mutate(iso3_respondent = case_when(
      !is.na(iso3_respondent)              ~ iso3_respondent,
      str_detect(respondent, "Ecuador")    ~ "ECU",
      str_detect(respondent, "Kosovo")     ~ "XKX",
      str_detect(respondent, "Lebanese")   ~ "LBN",
      str_detect(respondent, "Guyana")     ~ "GUY",
      str_detect(respondent, "Portugu")    ~ "PRT",
      TRUE                                 ~ NA_character_
    ))
    
  # Create new variable for country of claimant with github dataset
    # Converting respondent to country code
    icsid_df <- icsid_df |>
      mutate(
        iso3_claimant = countrycode::countrycode(claimant_nationality,
                                                   origin      = "country.name",
                                                   destination = "iso3c")
      )
        
    # Load nationality lookup from GitHub
    nationality_lookup <- read_csv(
      "https://gist.githubusercontent.com/zspine/2365808/raw/c808db0767fdb6171e651eddda38d509f41c88bf/countries.csv"
    ) |>
      select(Nationality, Name, iso3 = CCA3) |>
      distinct(Nationality, .keep_all = TRUE)
    
    # for claimants with multiple nationalities, we will create a separate row for each
    icsid_df <- icsid_df |>
      separate_rows(claimant_nationality, sep = ",") |>
      mutate(claimant_nationality = trimws(claimant_nationality))
    
    # Try to match claimant company to a country
    icsid_df <- icsid_df |>
      mutate(
        iso3_claimant = coalesce(
          # Step 1: match against nationality adjectives (e.g. "Dutch", "French")
          nationality_lookup$iso3[match(claimant_nationality, nationality_lookup$Nationality)],
          # Step 2: fall back to country name match (e.g. "Luxembourg", "Seychelles")
          nationality_lookup$iso3[match(claimant_nationality, nationality_lookup$Name)]
        )
      )

    
    # check cases where it didn't work
    icsid_df |>
      filter(is.na(iso3_claimant)) |>
      select(case_no, claimant_nationality) |> 
      print(n = 100)
    
    icsid_df <- icsid_df |>
      mutate(iso3_claimant = case_when(
        !is.na(iso3_claimant)                           ~ iso3_claimant,
        str_detect(claimant_nationality, "U\\.S\\.")    ~ "USA",
        str_detect(claimant_nationality, "USA")         ~ "USA",
        str_detect(claimant_nationality, "Emiri")       ~ "ARE",
        str_detect(claimant_nationality, "Argentine")   ~ "ARG",
        str_detect(claimant_nationality, "Korean")      ~ "KOR",
        str_detect(claimant_nationality, "Philippine")  ~ "PHL",
        str_detect(claimant_nationality, "Congolese (D.R.)") ~ "COD",
        str_detect(claimant_nationality, "Congo")       ~ "COG",
        str_detect(claimant_nationality, "Icelandic")   ~ "ISL",
        str_detect(claimant_nationality, "España")      ~ "ESP",
        str_detect(claimant_nationality, "Hong Kong")   ~ "HKG",
        str_detect(claimant_nationality, "Slovenian")   ~ "SVN",
        str_detect(claimant_nationality, "Nigerien")    ~ "NER",
        str_detect(claimant_nationality, "Dubai")       ~ "ARE",
        str_detect(claimant_nationality, "Panamá")      ~ "PAN",
        str_detect(claimant_nationality, "Rwandese")    ~ "RWA",
        str_detect(claimant_nationality, "Belarussian") ~ "BLR",
        str_detect(claimant_nationality, "Uzbek")       ~ "UZB",
        str_detect(claimant_nationality, "Sénégal")     ~ "SEN",
        str_detect(claimant_nationality, "UK")          ~ "GBR",
        str_detect(claimant_nationality, "Kosovar")     ~ "XKX",
        str_detect(claimant_nationality, "Kosovar")     ~ "XKX",
        str_detect(claimant_nationality, "Rom")         ~ "ITA",
        str_detect(claimant_nationality, "Cayman")      ~ "CYM",
        str_detect(claimant_nationality, "Kittitian/Nevisian") ~ "KNA",
        TRUE                                            ~ NA_character_
      ))
    
    
  # save the df
  saveRDS(icsid_df, here("data_preprocessed", "icsid.rds"))
