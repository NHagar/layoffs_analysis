# %%
import pathlib

import pandas as pd

from collection import urls, stories

# %%
url_path = pathlib.Path("./data/archive_urls_raw/")
complete_path = pathlib.Path("./data/completed.txt")
article_data_path = pathlib.Path("./data/article_data.csv")
start_date, end_date = urls.daterange('2019-01-25', 365)
dates = pd.date_range(start_date, end_date)

# %%
urls.collect_urls(dates, url_path)

# %%
links = stories.load_and_filter_urls(url_path)

# %%
stories.collect_articles(links, complete_path, article_data_path)
# %%
