#--
#Functions to conduct time series analysis/preprocessing
#--

#Aggregate time series
agg_df <- function(df, start, end) {
  df_meta_agg <- df %>% 
    group_by(pub_date) %>% 
    summarize(stories=n()) %>% 
    mutate(day_of_week=wday(pub_date)) %>% 
    filter((pub_date>as_date(start)) & (pub_date<as_date(end)))
  
  return(df_meta_agg)
}

#Convert the dataframe to a time series object with a weekly frequency
convert_ts <- function(df) {
  weekly_ts <- df %>% 
    select(stories) %>% 
    pull() %>% 
    ts(., frequency = 7)
  
  return(weekly_ts)
}

#Decomposition plots
decomp_plots <- function(timeseries) {
  timeseries %>% 
    decompose(.) %>% 
    plot(.) %>% 
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


