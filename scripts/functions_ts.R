#--
#Functions to conduct time series analysis/preprocessing
#--
library(tidyverse)
library(forecast)
library(lubridate)
library(fastDummies)

#Convert the dataframe to a time series object with a weekly frequency
convert_ts <- function(df, outcome) {
  weekly_ts <- df %>% 
    select(outcome) %>% 
    pull() %>% 
    ts(., frequency = 7)
  
  return(weekly_ts)
}

#Decomposition plots
decomp_plots <- function(timeseries) {
  timeseries %>% 
    decompose(.) %>% 
    plot(.)
  
  timeseries %>% 
    acf(.)
}

#Linear model
lm_df <- function(df, intervention) {
  model <- df %>% 
    mutate(intervention=ifelse(pub_date<date(intervention), 0, 1)) %>%
    dummy_cols(select_columns = 'day_of_week', remove_selected_columns = T) %>% 
    lm(stories ~ day_of_week_1 + 
         day_of_week_2 + 
         day_of_week_3 + 
         day_of_week_4 + 
         day_of_week_5 + 
         day_of_week_6 + 
         day_of_week_7 + 
         intervention, 
       data=.)
  
  return(model)
}

#Detrended plot
detrend_ts <- function(timeseries) {
  timeseries %>% 
    stl(., 'periodic') %>% 
    seasadj(.) %>% 
    plot(.)
}


