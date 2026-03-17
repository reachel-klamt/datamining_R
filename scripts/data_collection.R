#######################################
########### Data collection ##########
######################################

# Load necessary libraries
  library(httr2)
  library(jsonlite)
  library(tidyverse)
  library(here)
  library(rvest)

## fetch data from the internal API ##

  # make a GET request to the API endpoint
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
  
## create vector with all case names ##
  
# example of how to access the case number of the first case in the list  
  cases_list[[1]]$caseno
  
  case_nos <- character(length(cases_list))  # empty vector, same length as cases_list

# loop through the cases_list and extract the case numbers
  for (i in seq_along(cases_list)) {
    case_nos[i] <- cases_list[[i]]$caseno
  }
  
## preparation of web scraping case details ##

# defining the base url
base_url <- "https://icsid.worldbank.org/cases/case-database/case-detail?CaseNo="
  

# defining a function to scrape case details
  scrape_detail <- function(case_no) {
    Sys.sleep(0.2)  # wait 0.2 seconds after every request to avoid overwhelming the server
    
    url  <- paste0(base_url,case_no) # construct the url for the case details page using the case number
    
    # tryCatch catches the error before it crashes the loop
    page <- tryCatch(
      read_html(url),
      error = function(e) {
        message("Failed: ", case_no, " — ", e$message)
        return(NULL)
      }
    )
    
    # if the page failed, return an empty row for this case
    if (is.null(page)) {
      return(tibble(
        case_no         = case_no,
        economic_sector = NA_character_,
        subject         = NA_character_,
        instrument      = NA_character_,
        rules_applied   = NA_character_,
        outcome         = NA_character_,
        claimant        = NA_character_
        
      ))
    }
    
    rows <- page |> html_elements("li.row") # extract the list items with class "row" which contain the case details
    
    # creating a sub-function that extracts the important information
    # the information on the website is stored in a table
    get_field <- function(label_text) {
      for (row in rows) {
        label <- row |>
          html_element("[class*='leftcol'] label") |> # extract the label element from the left column of the table
          html_text(trim = TRUE) # extract the text from the label element and trim any whitespace
        
        # if the extracted label matches the one we are looking for,
        # extract the corresponding value from the right column of the table
        if (!is.na(label) && label == label_text) {
          return(
            row |>
              html_element("[class*='rightcol']") |>
              html_text(trim = TRUE)
          )
        }
      }
      NA_character_
    }
    
    tibble(
      case_no         = case_no,
      economic_sector = get_field("Economic Sector:"),
      subject         = get_field("Subject of Dispute:"),
      instrument      = get_field("Instrument(s) Invoked:"),
      rules_applied   = get_field("Applicable Rules:"),
      claimant_nationality = get_field("Claimant(s)/Nationality(ies):")
    )
  }

  # example of how to use the function to scrape details for the first case
  scrape_detail(case_nos[1])
  
  # running the function for all case numbers and combine the results into a single data frame
  case_details <- map_dfr(case_nos, scrape_detail, .progress = TRUE)
  
# save the case details as a R Data
  saveRDS(case_details, here("data_raw", "icsid_details.rds"))

  
