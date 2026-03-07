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
    Automated data collection (API or scraping)
    Data cleaning and preparation
    Reproducible analysis

## Research Question

Do Investor-State Dispute Settlements (ISDS) reproduce neocolonial patterns and therefore function as a tool for exploitation of the Global South by first world countries?


## Data Source

The data is extracted from the offical Website of the International Center for Settlement of Investment Disputes (ICSID).
This is done in two steps.

1. The internal API is called in order to get a all the Case No.
2. The cases No. of each case is used to loop through the URL's (https://icsid.worldbank.org/cases/case-database/case-detail?CaseNo=xxx) to receive all the detailed information of intrested.

These include:
  - Subject of Dispute
  - Economic Sector
  - Instruments Invoked
  - Applicable Rules

Information included in the first API call are the following:
  - Claimant (incl. State)
  - Respondent (State)
  - Date Registered
  - Number of Proceedings


## Repository Structure

/code scripts used to collect/process data /data output datasets (not tracked/pushed by git) README.md project description
Reproducibility


All data should be generated automatically by the scripts.
Good Practices

Please follow these guidelines:

    Do not upload raw datasets to GitHub.
    Store API keys outside the repository (e.g., environment variables).
    Write scripts that run from start to finish.
    Commit your work frequently.
    Use clear commit messages.

Example commit messages: added API request cleaned dataset structure added visualization fixed JSON parsing
Notes

Large datasets should not be pushed to GitHub.
If necessary, provide instructions for downloading the data instead.
