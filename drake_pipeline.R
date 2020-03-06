library(drake)
library(lubridate)

library(ruimtehol)
library(Rtsne)

set.seed(20200223)

source("./scripts/functions_metadata.R")
source("./scripts/functions_ts.R")
source("./scripts/functions_text.R")

plan <- drake_plan(
  cutoff = as_date("2019-01-25"),
  window = 43,
  sections = c("politics", "Arts & Entertainment", "world", "tech", "reader", "science", "books",
               "opinion", "health", "national", "lgbt", "investigations", "business"),
  raw_data =  read_csv(file_in('./data/scraped_stories_761days-all.csv')),
  data = clean_data(raw_data),
  data_social = text_embeds(data),
  data_mutate = text_measures(data_social),
  data_pre = data_mutate %>% 
    filter(pub_date<cutoff),
  data_window = data_mutate %>% 
    filter(pub_date>cutoff-window & pub_date<cutoff+window),
  cohort = cohort_build(data_window, cutoff),
  data_agg = agg_measures(data_window),
  data_noseason = target(deseason(data_agg, outcome, cutoff),
                         transform = cross(data_agg, outcome=c("stories", "bylines"))),
  rdd_model = target(RDestimate(deseasoned ~ relative_days, data=data_noseason, cutpoint = 0),
                      transform=map(data_noseason)),
  cohort_agg = agg_measures(cohort) %>% 
                  mutate(relative_days=pub_date-cutoff) %>% 
                  select(relative_days, storiesper) %>% 
                  rename("measure"=storiesper),
  cohort_rdd = RDestimate(measure ~ relative_days, data=cohort_agg, cutpoint=0),
  data_sections = data %>% filter(section %in% sections) %>% 
                           mutate(prepost=ifelse(pub_date<cutoff, 0, 1)) %>% 
                           group_by(prepost, section) %>% 
                           summarize(stories=n()) %>% 
                           mutate(pct_stories=stories/sum(stories)),
  plot_sections = section_plot(data_sections),
  embed_model = starspace_load_model(file_in("textspace.ruimtehol")),
  embeddings = starspace_embedding(embed_model, data_window$text_body) %>% 
    as_tibble() %>% 
    bind_cols(data_window) %>% 
    unite("e", V1:V100, remove=F) %>% 
    distinct(e, .keep_all=T) %>% 
    select(-e),
  tsne = target(tsne_coords(embeddings, sec, period, cutoff),
                transform=cross(sec=c("politics", "world", "", "Arts & Entertainment"), period=c("pre", "post"))),
  tsne_plots = target(tsne %>% 
                        ggplot(aes(X, Y, color=section)) + 
                        geom_point() +
                        scale_x_continuous(limits = c(-40, 40)) + 
                        scale_y_continuous(limits = c(-40, 40)),
                       transform=map(tsne)),
  out = rmarkdown::render(knitr_in("results.Rmd"),
                              output_file = file_out("results.html"),
                          quiet=T)
)

make(plan)

vis_drake_graph(plan)


loadd(tsne_politics_pre)
loadd(tsne_politics_post)
loadd(tsne_world_pre)
loadd(tsne_world_post)

tsne_politics_pre %>% 
  filter(X <-15 & X>-25) %>% 
  select(hed) %>% 
  pull()

tsne_politics_post %>% 
  filter(X < -25) %>% 
  select(hed) %>% 
  pull()

tsne_world_pre %>% 
  filter(X>0 & X<20 & Y<0) %>% 
  select(hed) %>% 
  pull()

tsne_world_post %>% 
  filter(X>0 & X<20 & Y<0) %>% 
  select(hed) %>% 
  pull()

test <- tsne_coords(embeddings, "politics", "pre", as_date("2019-01-25"))

embeddings %>% 
  filter(section=="politics")

test



loadd(tsne_world_post)

tsne_politics_post %>% select(section)
tsne_world_post

loadd(data_pre)

m <- starspace_load_model("textspace.ruimtehol")


unique_embeddings <- starspace_embedding(m, data_pre$text_body) %>% 
  as_tibble() %>% 
  bind_cols(data_pre) %>% 
  unite("e", V1:V100, remove=F) %>% 
  distinct(e, .keep_all=T) %>% 
  select(-e)

tsne <- unique_embeddings %>% 
  select(V1:V100) %>% 
  as.matrix() %>% 
  Rtsne()

tsne$Y %>% 
  as_tibble() %>% 
  rename(c("X"=V1, "Y"=V2)) %>% 
  bind_cols(unique_embeddings) %>% 
  filter(pub_date>as_date("2019-01-25")-43) %>% 
  ggplot(aes(X, Y, color=section)) + 
  geom_point()



tsne <- Rtsne(unique(embeddings))
plot(tsne$Y)

tsne$Y
nrow(embeddings)

data_pre %>% 
  select(text_body) %>% 
  write_csv("training_docs.txt")

model <- starspace(file = "training_docs.txt", fileFormat = "fastText", dim = 100, trainMode = 5)


test <- data_pre %>% 
  head(1) %>% 
  pull(text_body)
test_embed <- starspace_embedding(m, test)


unname(test_embed)
