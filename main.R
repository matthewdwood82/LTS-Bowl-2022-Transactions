

# clear envirionment and load dependencies --------------------------------

rm(list = ls())
gc()

# renv::activate()

library(dplyr)
library(purrr)
library(stringr)
library(lubridate)
library(googledrive)
library(googlesheets4)
library(ffscrapr)



# gs4 auth ----------------------------------------------------------------
# point to json secret per https://gargle.r-lib.org/articles/non-interactive-auth.html#provide-a-service-account-token-directly
googledrive::drive_auth(email = "matthewdwood82@gmail.com", path = Sys.getenv("GOOGLE_AUTHENTICATION_CREDENTIALS"))

# tell gs4 that the googledrive token works fine per 
# https://googlesheets4.tidyverse.org/articles/drive-and-sheets.html#auth-with-googledrive-first-then-googlesheets4
googlesheets4::gs4_auth(token = googledrive::drive_token())

# connect to Sleeper ------------------------------------------------------

con <-
  c(
    "869072831982559232",
    "859524057538887680",
    "869073624508891136",
    "869073848140800000",
    "866166165288939520"
  ) %>%
  purrr::set_names("L1", "L2", "L3", "L4", "L5") %>%
  purrr::map(.x = .,
             ~ ff_connect(
               league_id = .x,
               platform = "sleeper",
               season = 2022
             ))



# collect transactions ----------------------------------------------------

df_all <- purrr::map(con, ~ ff_transactions(.x)) %>%
  dplyr::bind_rows(.id = "league") %>%
  arrange(desc(timestamp), league) %>%
  mutate(
    week = difftime(timestamp, lubridate::ymd("2022-09-06"), units = "weeks") %>% ceiling(.) %>% as.integer(.) %>% if_else(. < 0L, 0L, .)
  ) %>%
  select(league, week, everything())


# send transactions to Google Sheets --------------------------------------

# sheet URL
url <- "https://docs.google.com/spreadsheets/d/1dbLITRWTaDBRU0wksk9nFJ4DqxV9BTokIQHW5pqDx5Y/edit#gid=83722163"

# drive_find(n_max = 1)

df_all %>%
  dplyr::filter(stringr::str_detect(type, "free_agent")) %>%
  googlesheets4::sheet_write(ss = url, sheet = "free agent transactions")

df_all %>% 
  dplyr::filter(stringr::str_detect(type, "waiver")) %>% 
  googlesheets4::sheet_write(ss = url, sheet = "waiver transactions")

df_all %>% 
  dplyr::filter(stringr::str_detect(type, "trade")) %>% 
  googlesheets4::sheet_write(ss = url, sheet = "trades")

googlesheets4::sheet_write(Sys.time(), ss = url, sheet = "transactions_last_updated")


