# %%
import pandas as pd

from collection import urls

# %%
start_date, end_date = urls.daterange('2019-01-25', 365)
dates = pd.date_range(start_date, end_date)

# %%
urls.collect_urls(dates, "./data/archive_urls_raw.txt")
