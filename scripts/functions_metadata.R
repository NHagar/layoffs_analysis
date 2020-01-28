#--
#Functions to handle additional metadata
#--
library(tidyverse)

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

