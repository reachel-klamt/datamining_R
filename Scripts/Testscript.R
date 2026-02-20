library(rvest)
library(tidyverse)

url <- "https://www.20min.ch/"
read_html(url) |> 
  html_elements(css = "a") |> 
  html_attr("href")