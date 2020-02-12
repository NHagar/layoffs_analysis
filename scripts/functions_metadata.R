#--
#Functions to handle additional metadata
#--
library(tidyverse)

#Load and clean the data
clean_data <- function(df) {
  df_clean <- df %>% 
    distinct() %>% 
    #get rid of JS junk
    mutate(text_body=gsub("\\{.*?\\}\n", "", text_body)) %>% 
    #Get rid of extra whitespace/newlines
    mutate(text_body=gsub("\\s+"," ", text_body)) %>% 
    separate(pub_date, c("f", "l"), sep="Posted on ") %>% 
    separate(l, c("datel", "l2"), sep=", at") %>% 
    filter(!is.na(datel)) %>% 
    mutate(pub_date=mdy(datel)) %>% 
    select(-f, -l2, -datel)
  return(df_clean)
}

#Load the list of cleaned layoff names
load_layoffs <- function() {
  layoffs <- read_csv('../data/layoffs_lists_joined.csv') %>% 
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
agg_measures <- function(df, cutoff, days) {
  df_agg = df %>% 
    group_by(pub_date) %>% 
    summarize(stories=n(), bylines=n_distinct(byline),
              log_len_chars=mean(log_len_chars), log_len_words=mean(log_len_words),
              polarity=mean(polarity),
              pct_tweet=sum(has_tweet)/n(),
              pct_insta=sum(has_insta)/n()) %>% 
    mutate(day_of_week=wday(pub_date)) %>% 
    filter(pub_date>(cutoff-days) & pub_date<(cutoff+days))
  return(df_agg)
}