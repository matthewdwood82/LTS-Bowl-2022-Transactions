

# clear envirionment and load dependencies --------------------------------

rm(list = ls())
gc()

renv::activate()

library(dplyr)
library(purrr)
library(stringr)
library(lubridate)
library(googledrive)
library(googlesheets4)
library(ffscrapr)



# gs4 auth ----------------------------------------------------------------

# googledrive::drive_auth(path = Sys.getenv("GOOGLE_AUTHENTICATION_CREDENTIALS"))

googledrive::drive_auth(email = "matthewdwood82@gmail.com", cache = Sys.getenv("GOOGLE_AUTHENTICATION_CREDENTIALS"))


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


