##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @title
##' @param raw_data
clean_data <- function(raw_data) {
    df_clean <- df %>% 
      select(-X1) %>% 
      mutate(link=gsub("\\/$", "", link)) %>% 
      #get rid of JS junk
      mutate(text_body=gsub("\\{.*?\\}\n", "", text_body)) %>% 
      #Get rid of extra whitespace/newlines
      mutate(text_body=gsub("\\s+"," ", text_body)) %>% 
      separate(pub_date, c("f", "l"), sep="Posted on ") %>% 
      separate(l, c("datel", "l2"), sep=", at") %>% 
      filter(!is.na(datel)) %>% 
      mutate(pub_date=mdy(datel)) %>% 
      select(-f, -l2, -datel) %>% 
      distinct() %>% 
      distinct(text_body, .keep_all=T)
    
    return(df_clean)
}
