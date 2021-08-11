##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @title
##' @param data_window
#Aggregate measures around a cutoff point
agg_measures <- function(df, remove_holidays=F) {
  df_agg <- df %>% 
    group_by(pub_date) %>% 
    summarize(stories=n(), 
              bylines=n_distinct(byline), 
              storiesper=stories/bylines,
              log_len_chars=mean(log_len_chars), 
              log_len_words=mean(log_len_words),
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
