library(drake)
library(lubridate)
library(ggrepel)

source("../scripts/functions_metadata.R")
source("../scripts/functions_ts.R")
source("../scripts/functions_text.R")

plan <- drake_plan(
  cutoff = as_date("2019-01-25"),
  window = 42,
  sections = c("politics", "Arts & Entertainment", "world", "tech", "reader", "science", "books",
               "opinion", "health", "national", "lgbt", "investigations", "business"),
  raw_data =  read_csv(file_in('../data/scraped_stories_761days-all.csv')),
  data = clean_data(raw_data),
  data_social = text_embeds(data),
  data_sentiment = text_sent(data_social),
  data_mutate = text_measures(data_sentiment),
  cohort = cohort_build(data_mutate, cutoff, window),
  data_agg = agg_measures(data_mutate, cutoff, window),
  data_noseason = target(deseason(data_agg, outcome, cutoff),
                         transform = cross(data_agg, outcome=c("stories", "bylines"))),
  rdd_model = target(RDestimate(deseasoned ~ relative_days, data=data_noseason, cutpoint = 0),
                      transform=map(data_noseason)),
  cohort_agg = target(agg_measures(cohort, cutoff, window) %>% 
                  mutate(relative_days=pub_date-cutoff) %>% 
                  select(relative_days, outcome) %>% 
                  rename("measure"=outcome),
                  transform=map(outcome=c("storiesper",
                                          "log_len_chars", "log_len_words",
                                          "polarity", "pct_tweet", "pct_insta"))),
  cohort_rdd = target(RDestimate(measure ~ relative_days, data=cohort_agg, cutpoint=0),
                      transform=map(cohort_agg)),
  data_sections = data %>% filter(section %in% sections &
                                  pub_date>cutoff-window &
                                  pub_date<cutoff+window) %>% 
                           mutate(prepost=ifelse(pub_date<cutoff, 0, 1)),
  sections_prepost = data_sections %>% group_by(prepost, section) %>% 
    summarize(stories=n()) %>% 
    mutate(pct_stories=stories/sum(stories)),
  plot_sections = section_plot(sections_prepost),
  results = rmarkdown::render(knitr_in("results.Rmd"),
                              output_file = file_out("results.html"),
                              quiet=T)
)

make(plan)

vis_drake_graph(plan)
