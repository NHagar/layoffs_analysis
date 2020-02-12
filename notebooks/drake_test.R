library(drake)
library(lubridate)

source("../scripts/functions_metadata.R")
source("../scripts/functions_ts.R")
source("../scripts/functions_text.R")

plan <- drake_plan(
  cutoff = as_date("2019-01-25"),
  raw_data =  read_csv(file_in('../data/scraped_stories_761days-all.csv')),
  data = clean_data(raw_data),
  data_social = text_embeds(data),
  data_sentiment = text_sent(data_social),
  data_mutate = text_measures(data_sentiment),
  data_agg = target(agg_measures(data_mutate, cutoff, days),
                    transform = map(days=c(14, 28, 42, 168))),
  data_noseason = target(deseason(data_agg, outcome, cutoff),
                         transform = cross(data_agg, outcome=c("stories", "bylines" 
                                                               #"log_len_chars", "log_len_words",
                                                               #"polarity", "pct_tweet", "pct_insta"
                                                               ))),
  rdd_model = target(RDestimate(deseasoned ~ relative_days, data=data_noseason, cutpoint = 0),
                      transform=map(data_noseason)),
  results = rmarkdown::render(knitr_in("results.Rmd"),
                              output_file = file_out("results.html"),
                              quiet=T)
)

make(plan)

vis_drake_graph(plan)
