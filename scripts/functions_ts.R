#--
#Functions to conduct time series analysis/preprocessing
#--
library(tidyverse)
library(forecast)
library(lubridate)
library(fastDummies)
library(rdd)

#Convert the dataframe to a time series object with a weekly frequency
convert_ts <- function(df, outcome) {
  weekly_ts <- df %>% 
    select(outcome) %>% 
    pull() %>% 
    ts(., frequency = 7)
  
  return(weekly_ts)
}

#De-season timeseries
deseason <- function(df, outcome, cutoff) {
  ts <- convert_ts(df, outcome)
  decomposed <- decompose(ts)
  deseasoned <- decomposed$x - decomposed$seasonal
  df$deseasoned <- deseasoned
  df <- df %>% 
    mutate(relative_days=as.integer(pub_date-cutoff))
  return(df)
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

#Section plot
section_plot <- function(df) {
  df %>% 
    select(-stories) %>% ungroup() %>% 
    pivot_wider(names_from=prepost, values_from=pct_stories) %>% 
    replace_na(list(`1`=0)) %>% 
    mutate(pct_change=`1`/`0`-1) %>% 
    ggplot(aes(x=`0`, y=section, xend=`1`, yend=section)) + geom_segment(arrow=arrow(length = unit(0.2, "cm"))) + 
    labs(x="% of stories", y="Section", title="% of stories, before and after layoffs")
}