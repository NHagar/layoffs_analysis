# %%
import pathlib

import pandas as pd

from collection import urls, stories

# %%
url_path = pathlib.Path("./data/archive_urls_raw.txt")
complete_path = pathlib.Path("./data/completed.txt")
article_data_path = pathlib.Path("./data/article_data.csv")
start_date, end_date = urls.daterange('2019-01-25', 365)
dates = pd.date_range(start_date, end_date)

# %%
urls.collect_urls(dates, "./data/archive_urls_raw.txt")

# %%
with open(url_path, "r") as f:
    urls = f.read().splitlines()
# %%
stories.collect_articles(urls, complete_path, article_data_path)
# %%
