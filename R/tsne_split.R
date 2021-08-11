##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @title
##' @param tsne_embeddings
##' @param sec
##' @param period
##' @param cutoff
# Create desired data subset for later plotting
tsne_split <- function(df_coords, sec, period=c("pre", "post", "all"), cutoff) {
  if (period=="pre") {
    df_coords <- df_coords %>% 
      filter(pub_date<cutoff)
  } else if (period=="post") {
    df_coords <- df_coords %>% 
      filter(pub_date>=cutoff)
  }
  
  if (sec!="") {
    df_coords <- df_coords %>% 
      filter(section==sec)
  }
  
  return(df_coords)
}