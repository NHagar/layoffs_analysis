library(drake)
library(lubridate)
library(ggforce)
library(ruimtehol)
library(Rtsne)

use_condaenv("parks")

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
                           mutate(pct_stories=stories/sum(stories)*100),
  plot_sections = section_plot(data_sections),
  embed_model = starspace_load_model(file_in("textspace.ruimtehol")),
  embeddings_starspace = starspace_embedding(embed_model, data_window$text_body) %>% 
    as_tibble() %>% 
    bind_cols(data_window) %>% 
    unite("e", V1:V100, remove=F) %>% 
    distinct(e, .keep_all=T) %>% 
    select(-e),
  embeddings_spacy = gen_spacy_embeddings(data_window),
  tsne_embeddings = target(
    tsne_coords(embeddings),
    transform=map(embeddings=c(embeddings_starspace, embeddings_spacy)),
    .names=c("starspace", "spacy")
  ),
  tsne = target(tsne_split(tsne_embeddings, sec, period, cutoff),
                transform=cross(tsne_embeddings,
                                sec=c("politics", "world", "", "Arts & Entertainment"), 
                                period=c("pre", "post"))),
  tsne_plots = target(tsne %>% 
                        ggplot(aes(X, Y)) + 
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

readd(data)

loadd(data_window)
data_window

loadd(data_pre)
library(tidyverse)
data_pre %>% 
  mutate(year=year(pub_date)) %>% 
  ggplot(aes(year)) + 
  geom_histogram()

data_pre %>% 
  filter(is.na(section))

loadd(tsne_politics_pre)
loadd(tsne_politics_post)
loadd(tsne_world_pre)
loadd(tsne_world_post)
loadd(tsne_plots_tsne_politics_pre)
loadd(tsne_plots_tsne_politics_post)
loadd(tsne_plots_tsne_world_pre)
loadd(tsne_plots_tsne_world_post)


loadd(tsne__pre)
loadd(tsne__post)

tsne__pre %>% 
  filter(X<10 & X>5 & Y< -15 & Y>-20) %>% 
  pull(hed)

tsne__post %>% 
  filter(X< -18 & X> -25 & Y< 25 & Y> 7) %>% 
  pull(hed)

tsne_politics_pre %>% 
  filter(X >20 & X<30 & Y> 3 & Y<25) %>% 
  select(hed) %>% 
  pull()

tsne_politics_post %>% 
  filter(X >20 & X<30 & Y> -10 & Y<10) %>%  
  select(hed) %>% 
  pull()

tsne_plots_tsne_politics_pre + 
  annotate("rect", xmin=18, xmax=30, ymin=-10, ymax=23, alpha=.2, color="red") + 
  annotate("text", x=21, y=-15, size=6, label="Trump administration") + 
  annotate("rect", xmin=2, xmax=16, ymin=15, ymax=30, alpha=.2, color="red") + 
  annotate("text", x=5, y=34, size=6, label="2020 election")

tsne_plots_tsne_politics_post + 
  annotate("rect", xmin=18, xmax=30, ymin=-10, ymax=23, alpha=.2, color="red") + 
  annotate("text", x=21, y=-15, size=6, label="Trump administration") + 
  annotate("rect", xmin=2, xmax=16, ymin=15, ymax=30, alpha=.2, color="red") + 
  annotate("text", x=5, y=34, size=6, label="2020 election")

tsne_plots_tsne_world_pre + 
  annotate("rect", xmin=1, xmax=13.5, ymin=5, ymax=20, alpha=.2, color="red") + 
  annotate("text", x=0, y=24, size=6, label="Human rights") + 
  annotate("rect", xmin=9, xmax=24, ymin=-6, ymax=4, alpha=.2, color="red") + 
  annotate("text", x=20, y=-10, size=6, label="International relations") + 
  annotate("rect", xmin=14, xmax=26, ymin=5, ymax=15, alpha=.2, color="red") + 
  annotate("text", x=25, y=19, size=6, label="Immigration")

tsne_plots_tsne_world_post

tsne_politics_post %>% 
  filter(X < -25) %>% 
  select(hed) %>% 
  pull()

tsne_world_pre %>% 
  filter(X>0 & X<15 & Y>5 & Y<20) %>% 
  select(hed) %>% 
  pull()

tsne_world_post %>% 
  filter(X>0 & X<15 & Y>5 & Y<20) %>%  
  select(hed) %>% 
  pull()


tsne_world_pre %>% 
  filter(X>10 & X<25 & Y> -5 & Y<5) %>% 
  select(hed) %>% 
  pull()

tsne_world_post %>% 
  filter(X>10 & X<25 & Y> -5 & Y<5) %>% 
  select(hed) %>% 
  pull()

tsne_world_pre %>% 
  filter(X>10 & X<25 & Y> 5 & Y<20) %>% 
  select(hed) %>% 
  pull()

loadd(data_noseason_stories)
loadd(rdd_model_data_noseason_stories)
plot(rdd_model_data_noseason_stories, xlab="Days pre-/post-layoffs", ylab="Stories published")


loadd(tsne_plots_tsne__pre)
loadd(tsne_plots_tsne__post)

tsne_plots_tsne__pre + 
  annotate("rect", xmin = 4.5, xmax = 10, ymin = -21, ymax = -15,
           alpha = .2, color="red") + 
  annotate("text", x=15, y=-23, label="Health news", size=6)

readd(tsne_plots_tsne__post) + 
  annotate("rect", xmin = -25, xmax = -18, ymin = 8, ymax = 15,
           alpha = .2, color="red") + 
  annotate("text", x=-24, y=18, label="Jussie Smollett coverage", size=5)


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



readd(data_sections) %>% 
  mutate(pct_stories=pct_stories*100) %>% 
  section_plot()