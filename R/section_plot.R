##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @title
##' @param data_sections
#Section plot
section_plot <- function(df) {
  p <- df %>% 
    select(-stories) %>% ungroup() %>% 
    pivot_wider(names_from=prepost, values_from=pct_stories) %>% 
    replace_na(list(`1`=0)) %>% 
    mutate(pct_change=(`1`/`0`-1)) %>% 
    ggplot(aes(x=`0`, y=section, xend=`1`, yend=section)) + geom_segment(arrow=arrow(length = unit(0.2, "cm"))) + 
    labs(x="% of stories", y="Section", title="Composition pre/post layoffs")
  
  return(p)
}
