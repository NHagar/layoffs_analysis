import pathlib
import re
from typing import List

from bs4 import BeautifulSoup
import pandas as pd
import requests
from tqdm import tqdm

def load_and_filter_urls(path: str) -> List[str]:
    with open(path, "r") as f:
        urls = f.readlines()
    urls = [i.replace("\n", "") for i in urls]

    urls = list(set(urls))
    urls = [i for i in urls if "www.buzzfeed" in i and ".com/mx" not in i and ".com/jp" not in i]

    return urls

def scrape_article(url: str):
    r = requests.get(url)
    soup = BeautifulSoup(r.text)
    # Check for non-news stories
    if "buzzfeed.com" in url:
        tag = soup.find("a", {"class": "metadata-link"}).contents[0]
        if tag != "News":
            return None
        authors = soup.find_all("span", {"class": re.compile(".*bylineName.*")})
        authors = [i.contents[0] for i in authors]
        pub_dt = soup.find("time")['datetime']
        hed = soup.find("h1").contents[0]
        art = soup.find("article")
        text = art.find_all(["p", "h2"])
        text = [i.text for i in text]
    else:
        # Collect metadata from BuzzFeed News
        tag = soup.find("a", {"data-vars-unit-type": "buzz_head"}).contents[0]
        authors = [i.contents[0] for i in soup.find_all("span", {"class": re.compile("news-byline-full__name*")})]
        pub_dt = soup.find("p", {"class": "news-article-header__timestamps-posted"}).contents[0]
        hed = soup.find("h1").contents[0]
        art = soup.find("div", {"class": "js-article-wrapper"})
        text = [i.text for i in art.find_all(["p", "h2"])]

    result = {
        "tag": tag,
        "authors": authors,
        "pub_date": pub_dt,
        "hed": hed,
        "article_text": text
    }

    return result

def collect_articles(urls):
    # Logging and data paths
    complete_path = pathlib.Path("./data/completed.txt")
    article_data_path = pathlib.Path("./data/article_data.csv")
    # Check for logging path
    if complete_path.exists():
        with open(complete_path, "r") as f:
            completed_urls = f.readlines()
        completed_urls = [i.replace("\n") for i in completed_urls]
        urls = list(set(urls) - set(completed_urls))
    # For each url
    for u in tqdm(urls):
        # Scrape article
        contents = scrape_article(u)
        # If data returned
        if contents:
            # Append or write data
            contents = pd.DataFrame(contents)
            if article_data_path.exists():
                mode = "a"
                header = False
            else:
                mode = "w"
                header = True
            # Append or write log
            if complete_path.exists():
                mode = 'a'
            else:
                mode = 'w'

            contents.to_csv(article_data_path, mode=mode, header=header, index=False)

            with open(complete_path, mode) as f:
                f.write(f"{u}\n")
        else:
            continue
