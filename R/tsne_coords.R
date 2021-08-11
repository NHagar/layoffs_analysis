##' .. content for \description{} (no empty lines) ..
##'
##' .. content for \details{} ..
##'
##' @title
##' @param embeddings_starspace
#Generate 2-dimensional coordinates with tsne
tsne_coords <- function(df) {
  tsne <- df %>% 
    select(V1:V100) %>% 
    as.matrix() %>% 
    Rtsne()
  
  df_coords <- tsne$Y %>% 
    as_tibble() %>% 
    rename(c("X"=V1, "Y"=V2)) %>% 
    bind_cols(df)
  
  return(df_coords)
}