#--
#Functions to handle article text processing
#--

library(futile.logger)
library(tidyverse)
library(tidytext)
library(cleanNLP)
library(hunspell)
library(mallet)

sentiment <- get_sentiments("bing")
cnlp_init_spacy(model_name="en_core_web_lg")

#Count social embeds
text_embeds <- function(df) {
  df_social <- df %>% 
    mutate(tweets=str_count(text_body, pattern="\\}.*? Retweet Favorite"), 
           insta=str_count(text_body, pattern="Instagram: @[A-z]* "))
  return(df_social)
}

#Text cleaning
text_clean <- function(s) {
  clean_string <- s %>% 
    #Get rid of embedded tweets
    gsub("\\}.*? Retweet Favorite", "", .)  %>%
    #Get rid of related stories
    gsub("·.*", "", .) %>% 
    #Get rid of Instagram embeds
    gsub(" View this photo on Instagram ", "", .) %>% 
    #Get rid of Instagram embeds
    gsub("Instagram: @[A-z]* ", "", .) %>% 
    #Get rid of Twitter attributions
    gsub("@[A-z]* // Twitter ", "", .)
  return(clean_string)
}

#Calculate word and character length
text_lengths <- function(df) {
  df_len <- df %>% 
    mutate(len_chars = str_length(text_body),
           len_words = str_count(text_body, "\\w+"))
  return(df_len)
}

#Tag stories with sentiment words
text_sent <- function(df) {
  df_sent <- df %>% 
    #Tokenize text
    unnest_tokens(word, text_body) %>% 
    #Join text to sentiment dictionary
    inner_join(sentiment) %>% 
    #Calculate sentiments per story
    group_by(link, sentiment) %>% 
    summarize(words=n()) %>% 
    ungroup() %>% 
    pivot_wider(names_from=sentiment, values_from=words) %>% 
    mutate_all(~replace(., is.na(.), 0))
  return(df_sent)
}

#Tag parts of speech and entities with spacy
text_tag <- function(df, token_path='../data/tagged_text_tokens.csv', ent_path='../data/tagged_text_entities.csv') {
  tagged_text <- df %>% 
    rename("doc_id"=link, "text"=text_body) %>% 
    select(doc_id, text) %>% 
    cnlp_annotate()
  tagged_text$token %>% write_csv(token_path)
  flog.info("Token dataframe saved to %s", token_path)
  tagged_text$entity %>% write_csv(ent_path)
  flog.info("Entity dataframe saved to %s", ent_path)
}

