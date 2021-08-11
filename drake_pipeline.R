# TODO: Incorporate model training into pipeline
# TODO: Better analysis of pre/post embedding spaces
lapply(list.files("./R", full.names = TRUE), source)

set.seed(20200223)

plan <- drake_plan(
  # Define inflection point
  cutoff = as_date("2019-01-25"),
  # Define window to measure before/after inflection
  window = 43,
  # Enumerate section names
  sections = factor(c("politics", "Arts & Entertainment", "world", "tech", "reader", "science", "books",
               "opinion", "health", "national", "lgbt", "investigations", "business")),
  # Load in raw data file
  raw_data =  read_csv(file_in('./data/scraped_stories_761days-all.csv')),
  # Clean data - URL, headline, text, and pub date
  data = clean_data(raw_data),
  # Count and remove social media embeds
  data_social = text_embeds(data),
  # Text descriptive stats
  data_mutate = text_measures(data_social),
  # Split data into pre and post window
  data_pre = data_mutate %>% 
    filter(pub_date<cutoff),
  data_window = data_mutate %>% 
    filter(pub_date>cutoff-window & pub_date<cutoff+window),
  # Get laid off cohort
  laid_off = read_csv(file_in("./data/layoffs_lists_joined.csv")) %>% 
    select(`0`) %>% rename("name"=`0`),
  cohort = cohort_build(laid_off, data_window, cutoff),
  # Generate aggregate measures per day
  data_agg = agg_measures(data_window),
  # Remove seasonal trend from data
  data_noseason = target(deseason(data_agg, outcome, cutoff),
                         transform = cross(data_agg, outcome=c("stories", "bylines"))),
  # Fit RDD model
  rdd_model = target(RDestimate(deseasoned ~ relative_days, data=data_noseason, cutpoint = 0),
                      transform=map(data_noseason)),
  # Get aggregate data for specified cohort
  cohort_agg = agg_measures(cohort) %>% 
                  mutate(relative_days=pub_date-cutoff) %>% 
                  select(relative_days, storiesper) %>% 
                  rename("measure"=storiesper),
  # Fit cohort-specific RDD model
  cohort_rdd = RDestimate(measure ~ relative_days, data=cohort_agg, cutpoint=0),
  # Limit data to sections and transform for analysis steps
  data_sections = data %>% filter(section %in% sections) %>% 
                           mutate(prepost=ifelse(pub_date<cutoff, 0, 1)) %>% 
                           group_by(prepost, section) %>% 
                           summarize(stories=n()) %>% 
                           mutate(pct_stories=stories/sum(stories)*100),
  # Generate section change plot
  plot_sections = section_plot(data_sections),
  # Generate and transform embeddings from starspace model
  embeddings_starspace = starspace_embedding(starspace_load_model(file_in("textspace.ruimtehol")), 
                                             data_window$text_body) %>% 
    as_tibble() %>% 
    bind_cols(data_window) %>% 
    unite("e", V1:V100, remove=F) %>% 
    distinct(e, .keep_all=T) %>% 
    select(-e),
  # Transform embeddings to 2D coordinates w/TSNE
  tsne_embeddings = tsne_coords(embeddings_starspace),
  # Subset TSNE coordinates along desired parameters
  tsne = target(tsne_split(tsne_embeddings, sec, period, cutoff),
                transform=cross(sec=c("politics", "world", "", "Arts & Entertainment"), 
                                period=c("pre", "post"))),
  # Generate TSNE plots
  tsne_plots = target(tsne %>% 
                        ggplot(aes(X, Y)) + 
                        geom_point() +
                        scale_x_continuous(limits = c(-40, 40)) + 
                        scale_y_continuous(limits = c(-40, 40)),
                       transform=map(tsne)),
  # Export results to file
  out = rmarkdown::render(knitr_in("results.Rmd"),
                              output_file = file_out("results.html"),
                          quiet=T)
)

make(plan)

vis_drake_graph(plan)

