#--
#Functions to handle additional metadata
#--
library(tidyverse)
library(lubridate)

#Load and clean the data
clean_data <- function(df, cutoff, window) {
  df_clean <- df %>% 
    select(-X1) %>% 
    distinct() %>% 
    #get rid of JS junk
    mutate(text_body=gsub("\\{.*?\\}\n", "", text_body)) %>% 
    #Get rid of extra whitespace/newlines
    mutate(text_body=gsub("\\s+"," ", text_body)) %>% 
    separate(pub_date, c("f", "l"), sep="Posted on ") %>% 
    separate(l, c("datel", "l2"), sep=", at") %>% 
    filter(!is.na(datel)) %>% 
    mutate(pub_date=mdy(datel)) %>% 
    select(-f, -l2, -datel) %>% 
    filter(pub_date>(cutoff-window) & pub_date<(cutoff+window))
  return(df_clean)
}

#Load the list of cleaned layoff names
load_layoffs <- function() {
  layoffs <- read_csv('./data/layoffs_lists_joined.csv') %>% 
    rename('names'=`0`) %>% 
    select(names) %>% 
    #Remove punctuation and spaces, lowercase
    mutate(byline_cleaned =  gsub('[[:punct:] ]+','',tolower(names)))
  
  return(layoffs)
}

#Clean bylines in dataframe
clean_bylines <- function(df) {
  df_cleaned <- df %>% 
    #Remove punctuation and spaces, lowercase
    mutate(byline_cleaned =  gsub('[[:punct:] ]+','',tolower(byline)))
  
  return(df_cleaned)
}

#Aggregate statistics about layoffs in each section
layoff_percent <- function(df) {
  df_layoff <- df %>% 
    group_by(section, byline) %>%
    summarize(laid_off=first(laid_off)) %>% 
    group_by(section) %>% 
    #Get the number of laid off reporters, total number of reporters, and percent laid off for each section tag
    summarize(layoffs=sum(laid_off), reporters=n(), percent_laidoff=layoffs/n())
  
  return(df_layoff)
}

#Aggregate measures around a cutoff point
agg_measures <- function(df, remove_holidays=F) {
  df_agg = df %>% 
    group_by(pub_date) %>% 
    summarize(stories=n(), bylines=n_distinct(byline), storiesper=stories/bylines,
              log_len_chars=mean(log_len_chars), log_len_words=mean(log_len_words),
              pct_tweet=sum(has_tweet)/n()*100,
              pct_insta=sum(has_insta)/n()*100) %>% 
    mutate(day_of_week=wday(pub_date))
  if (remove_holidays==T) {
    df_agg <- df_agg %>% 
      filter(!pub_date %in% c(as_date("12-24-2018"), 
                              as_date("12-25-2018"),
                              as_date("12-31-2018"), 
                              as_date("01-01-2019")))
  }
  return(df_agg)
}

#Limit data to surviving cohort
cohort_build <- function(df, cutoff) {
  laid_off <- read_csv("./data/layoffs_lists_joined.csv") %>% 
    select(`0`) %>% rename("name"=`0`)
  df %>% 
    group_by(byline) %>% 
    summarize(first_pub=min(pub_date),
              last_pub=max(pub_date),
              stories=n()) %>% 
    filter(first_pub<cutoff & last_pub>cutoff+9) %>%
    ungroup() %>% 
    anti_join(laid_off, by=c("byline"="name")) %>% 
    left_join(df)
}

