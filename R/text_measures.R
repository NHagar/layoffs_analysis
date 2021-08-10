##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @title
##' @param data_social
text_measures <- function(df) {
  df_mutate <- df %>% 
    mutate(log_len_chars=log1p(len_chars),
           log_len_words=log1p(len_words),
           has_tweet=tweets>0,
           has_insta=insta>0)
  return(df_mutate)
}
