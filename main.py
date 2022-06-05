# %%
import ast
import pathlib

import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns

from collection import urls, stories

# %%
url_path = pathlib.Path("./data/archive_urls_raw")
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
# Data loading and cleaning
df = pd.read_csv(article_data_path)
df.pub_date = pd.to_datetime(df.pub_date).dt.date
df.tags = df.tags.apply(ast.literal_eval)
df.authors = df.authors.apply(ast.literal_eval)

# %%
# Data filters
# Date range
df = df[(df.pub_date>=start_date) & (df.pub_date<=end_date)]
df['is_post'] = df.pub_date >= pd.to_datetime('2019-01-25').date()
# %%
# Section composition
grouped_count = df.groupby(['is_post', "section"]).count()
comparison = pd.pivot((grouped_count / grouped_count.groupby(level=0).sum()).url.reset_index(), index='section', columns='is_post').fillna(0)
comparison.columns = ["Pre", "Post"]
comparison = comparison.reset_index()
ax = plt.figure(figsize=(5,10))
ax = sns.stripplot(x="Pre", y="section", data=comparison, orient="h", size=10, color="black", jitter=False)
arrow_starts = comparison["Pre"].values
arrow_lengths = comparison["Post"].values - arrow_starts
for i, subject in enumerate(comparison["section"]):
    plt.arrow(
        x=arrow_starts[i],
        y=i,
        dx=arrow_lengths[i],
        dy=0,
        head_width=0.5,
        head_length=0.01,
        width=0.05,
#        length_includes_head=True,
        color="k",
        clip_on=False,
    )
ax.set(xlabel="% of stories (pre/post layoffs)", ylabel="Section")
# %%
# Analyses to reproduce
# RDD - story count and byline count

# Semantic analysis
    # Embedding generation
    # Overall clustering, comparison to section breakdown
    # Per-section density