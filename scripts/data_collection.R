#######################################
########### Data collection ##########
######################################

# Load necessary libraries
  library(httr2)
  library(jsonlite)
  library(tidyverse)

# fetch data from the internal API
  response <- request("https://icsid.worldbank.org/api/all/cases") |>
    req_perform()
  
# extract the cases from the response
  cases_list <- resp_body_string(response) |>
    
# convert the JSON response to a data frame (list)
    fromJSON(simplifyVector = FALSE)  |>
    {\(x) x$data$GetAllCasesResult}()
  
