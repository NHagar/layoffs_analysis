library(drake)
library(lubridate)

source("../scripts/functions_metadata.R")
source("../scripts/functions_ts.R")
source("../scripts/functions_text.R")

plan <- drake_plan(
  cutoff = as_date("2019-01-25"),
  raw_data =  read_csv(file_in('../data/scraped_stories_761days.csv')),
  data = clean_data(raw_data),
  data_social = text_embeds(data),
  data_sentiment = text_sent(data_social),
  data_mutate = text_measures(data_sentiment),
  data_agg = target(agg_measures(data_mutate, cutoff, days),
                    transform = map(days=c(14, 28, 42, 168))),
  time_series = target(convert_ts(data_agg, outcome),
                       transform = cross(data_agg, outcome=c("stories", "bylines", 
                                                 "log_len_chars", "log_len_words",
                                                 "polarity", "pct_tweet", "pct_insta")))
)

make(plan)

vis_drake_graph(plan)
