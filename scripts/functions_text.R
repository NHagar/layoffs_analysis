#--
#Functions to handle article text processing
#--
library(futile.logger)
library(tidyverse)
library(textmineR)
library(tidytext)
library(cleanNLP)
library(hunspell)

data("stop_words")

sentiment <- get_sentiments("bing")
cnlp_init_spacy(model_name="en_core_web_lg")

#Social embed-related text cleaning
text_embeds <- function(df) {
  df_social <- df %>% 
    #Count social embeds
    mutate(tweets=str_count(text_body, pattern="\\}.*? Retweet Favorite"), 
           insta=str_count(text_body, pattern="Instagram: @[A-z]* "),
           #Remove social embeds
           text_body=text_clean(text_body),
           #Get text length
           len_chars = str_length(text_body),
           len_words = str_count(text_body, "\\w+")) %>% 
    distinct() %>% 
    distinct(text_body, .keep_all=T)
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
    mutate_all(~replace(., is.na(.), 0)) %>% 
    left_join(df)
  return(df_sent)
}

#Tag parts of speech and entities with spacy
text_tag <- function(df, token_path='./data/tagged_text_tokens.csv', ent_path='./data/tagged_text_entities.csv') {
  tagged_text <- df %>% 
    rename("doc_id"=link, "text"=text_body) %>% 
    select(doc_id, text) %>% 
    cnlp_annotate()
  tagged_text$token %>% write_csv(token_path)
  flog.info("Token dataframe saved to %s", token_path)
  tagged_text$entity %>% write_csv(ent_path)
  flog.info("Entity dataframe saved to %s", ent_path)
}

#Mutate measures
text_measures <- function(df) {
  df_mutate <- df %>% 
    mutate(log_len_chars=log1p(len_chars),
           log_len_words=log1p(len_words),
           has_tweet=tweets>0,
           has_insta=insta>0)
  return(df_mutate)
}

#Topic model
build_dtm <- function(df) {
  sw <- stop_words$word
  
  sw <- c(sw, "buzzfeed", 
          "buzzfeed_news", 
          "getty", 
          "getty_images", 
          "afp", 
          "afp_getty", 
          "images", 
          "news",
          "min",
          "min_width")
  
  df <- df %>% 
    filter(!grepl("}", text_body))
  
  dtm <- CreateDtm(doc_vec = df$text_body,
                   doc_names = df$link,
                   ngram_window = c(1,2),
                   stopword_vec = sw,
                   verbose = T)
  dtm <- dtm[,colSums(dtm) > 16]
  
  return(dtm)
}

mlist <- function(df) {
  dtm <- build_dtm(df)
  
  k_list <- seq(5, 30, by=5)

  model_list <- TmParallelApply(X = k_list, FUN = function(k) {
    model <- FitLdaModel(dtm = dtm, 
                         k = k,
                         iterations = 1000,
                         burnin = 180,
                         alpha = 0.1,
                         beta = 0.05,
                         optimize_alpha = TRUE,
                         calc_likelihood = TRUE,
                         calc_coherence = TRUE,
                         calc_r2 = TRUE)
    model$k <- k
    
    model
  }, export = ls())
    
  return(model_list)
}

topic_model <- function(model_list) {
  coherence_mat <- data.frame(k = sapply(model_list, function(x) nrow(x$phi)), 
                              coherence = sapply(model_list, function(x) mean(x$coherence)), 
                              stringsAsFactors = FALSE)
  
  model_filtering <- coherence_mat %>% 
    mutate(rown = row_number()) %>% 
    filter(coherence==max(coherence)) 
  
  model_num <- model_filtering %>% 
    pull(rown)
  
  k <- model_filtering %>% 
    pull(k)
  
  model_max <- model_list[[model_num]]
  
  doc_topics <- as_tibble(model_max$theta) %>% 
    mutate(link=names(model_max$theta[,1])) %>% 
    pivot_longer(cols=1:k, names_to="topic") %>% 
    group_by(link) %>% 
    filter(value==max(value)) %>% 
    ungroup() %>% 
    select(-value)
  
  return(list(model=model_max, df=doc_topics))
}

#Filter entities
filter_ents <- function(df, text) {
  collapsed_text <- paste(text, sep="", collapse="")
  filtered_names <-  df %>% 
    filter(entity_type=="PERSON" & !grepl("\\(", entity) & !grepl("\\[", entity)) %>% 
    mutate(is_body=str_detect(collapsed_text, paste(entity, "(?!/)(?! /)", sep=""))) %>% 
    filter(is_body==T)
  df <- df %>% 
    filter(entity_type!="PERSON" | entity %in% filtered_names$entity) %>% 
    mutate(entity=tolower(entity)) %>% 
    distinct()
  
  return(df)
}

