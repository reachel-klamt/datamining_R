# Data Mining Project Template

This repository contains the code for a small data mining project developed as part of the course:

**Data Access and Data Mining for Social Science**

University of Lucerne

R. Klamt
Course: Data Mining for the Social Sciences using R Term: Spring 2026
Project Goal

The goal of this project is to collect and analyze data from an online source (API or web scraping) in order to answer a research question relevant to political or social science.

The project should demonstrate:

    Identification of a suitable data source
    Automated data collection (API and scraping)
    Data cleaning and preparation
    Reproducible analysis

## Research Question

Do Investor-State Dispute Settlements (ISDS) reproduce neocolonial patterns and therefore function as a tool for exploitation of the Global South by first world countries?


## Data Source

The data is extracted from the offical Website of the International Center for Settlement of Investment Disputes (ICSID).
This is done in two steps.

1. The internal API is called in order to get a all the Case No.
2. The cases No. of each case is used to loop through the URL's (https://icsid.worldbank.org/cases/case-database/case-detail?CaseNo=xxx) to receive all the detailed information of interested.

These include:
  - Subject of Dispute
  - Economic Sector
  - Instruments Invoked
  - Applicable Rules

Information included in the first API call are the following:
  - Claimant (incl. State)
  - Respondent (State)
  - Date Registered


## Repository Structure
The repository contains two folders that were not pushed at all:

    1. data_raw: This folder contains the raw data collected from the ICSID website. (not pushed to GitHub)
    2. data_preprocessed: This folder contains the cleaned data.  (not pushed to GitHub)
    
In the script folder, there are three scripts:

    1. data_collection.R: This script collects the data from the ICSID website using API calls and web scraping techniques.
    2. data_cleaning.R: This script processes the raw data, cleans it, and prepares it for analysis.
    3. data_analysis.R: This script performs the analysis to answer the research question.

Furthermore, there is a report folder, which contained various content, however, not all of it was pushed to GitHub, 
as some of it is not relevant for the project and would only clutter the repository. The report folder contains:

    1. template_full.tex: My Latex-Template for the final report, which I use for all of my papers. (not pushed to GitHub)
    2. Report.qmd: This is the R-Cuarto File in which the report was created. It contains the text of the report as well as the code chunks.
    3. Report.pdf: The final report, which is generated from the report.qmd file. The signiture was added manually.
    4. References.bib: The bibliography file, which contains all the references used in the report. (not pushed to GitHub)
    5. apsa.csl: The citation style file, which is used to format the references according to the APSA style. (not pushed to GitHub)


Moreover, the project contains a figures folder, which contains all the figures generated during the analysis. These include:

    1. maps_country.png: A world map showing the distribution of ISDS cases by country.
    2. map_sector.png: A world map showing the income classifications from the World Bank. (not included in the report)
    3. heatmap_income.png: A heatmap showing the distribution of ISDS cases by income classification of the respondent state.
    4. heatmap_sector_group.png: A heatmap showing the distribution of ISDS cases for extractive sector.
    5. sector.png: A bar chart showing the distribution of ISDS cases by economic sector. (not included in the report)
    
