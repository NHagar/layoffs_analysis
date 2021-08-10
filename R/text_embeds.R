##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @title
##' @param data
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