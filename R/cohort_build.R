##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @title
##' @param data_window
##' @param cutoff
#Limit data to surviving cohort
cohort_build <- function(laid_off, df, cutoff) {
  cohort <- df %>% 
    group_by(byline) %>% 
    summarize(first_pub=min(pub_date),
              last_pub=max(pub_date),
              stories=n()) %>% 
    filter(first_pub<cutoff & last_pub>cutoff+9) %>%
    ungroup() %>% 
    anti_join(laid_off, by=c("byline"="name")) %>% 
    left_join(df)
  
  return(cohort)
}
