#######################################
########### Data collection ##########
######################################

# Load necessary libraries
  library(httr2)
  library(jsonlite)
  library(tidyverse)
  library(here)

# fetch data from the internal API
  http_response <- request("https://icsid.worldbank.org/api/all/cases") |>
    req_perform()
  
# extract the content of the response as text
  json_response <- http_response |> 
    resp_body_string()
  
# save the raw response as json file
  writeLines(json_response, here("data_raw", "icsid_raw.json"))

    
# convert the JSON response to an R list
  cases_list <- json_response |>
    fromJSON(simplifyVector = FALSE) |>
    {\(x) x$data$GetAllCasesResult}()
  
# create vector with all case names


  
