library(drake)
library(lubridate)

source("./scripts/functions_metadata.R")
source("./scripts/functions_ts.R")
source("./scripts/functions_text.R")

plan <- drake_plan(
  cutoff = as_date("2019-01-25"),
  window = 43,
  sections = c("politics", "Arts & Entertainment", "world", "tech", "reader", "science", "books",
               "opinion", "health", "national", "lgbt", "investigations", "business"),
  raw_data =  read_csv(file_in('./data/scraped_stories_761days-all.csv')),
  data = clean_data(raw_data, cutoff, window),
  data_social = text_embeds(data),
  spacy = text_tag(data_social),
  data_mutate = text_measures(data_social),
  cohort = cohort_build(data_mutate, cutoff),
  data_agg = agg_measures(data_mutate),
  data_noseason = target(deseason(data_agg, outcome, cutoff),
                         transform = cross(data_agg, outcome=c("stories", "bylines"))),
  rdd_model = target(RDestimate(deseasoned ~ relative_days, data=data_noseason, cutpoint = 0),
                      transform=map(data_noseason)),
  cohort_agg = target(agg_measures(cohort) %>% 
                  mutate(relative_days=pub_date-cutoff) %>% 
                  select(relative_days, outcome) %>% 
                  rename("measure"=outcome),
                  transform=map(outcome=c("storiesper",
                                          "log_len_chars", "log_len_words",
                                          "pct_tweet", "pct_insta"))),
  cohort_rdd = target(RDestimate(measure ~ relative_days, data=cohort_agg, cutpoint=0),
                      transform=map(cohort_agg)),
  data_sections = data %>% filter(section %in% sections) %>% 
                           mutate(prepost=ifelse(pub_date<cutoff, 0, 1)),
  sections_prepost = data_sections %>% group_by(prepost, section) %>% 
    summarize(stories=n()) %>% 
    mutate(pct_stories=stories/sum(stories)),
  plot_sections = section_plot(sections_prepost),
  out = rmarkdown::render(knitr_in("results.Rmd"),
                              output_file = file_out("results.html"),
                          quiet=T)
)

make(plan)

vis_drake_graph(plan)
