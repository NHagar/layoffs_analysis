##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @title
##' @param data_agg
##' @param outcome
##' @param cutoff
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

#Convert the dataframe to a time series object with a weekly frequency
convert_ts <- function(df, outcome) {
  weekly_ts <- df %>% 
    select(outcome) %>% 
    pull() %>% 
    ts(., frequency = 7)
  
  return(weekly_ts)
}