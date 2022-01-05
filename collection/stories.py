import pathlib
import re
from time import sleep
from typing import List

from bs4 import BeautifulSoup
from numpy import log
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
        try:
            tag = soup.find("a", {"class": "metadata-link"}).contents[0]
        except AttributeError:
            return None
        if tag != "News":
            return None
        authors = soup.find_all("span", {"class": re.compile(".*bylineName.*")})
        authors = [i.contents[0] for i in authors]
        pub_dt = soup.find("time")['datetime']
        try:
            hed = soup.find("h1").contents[0]
        except IndexError:
            hed = ""
        art = soup.find("article")
        text = art.find_all(["p", "h2"])
        text = [i.text for i in text]
    else:
        # Collect metadata from BuzzFeed News
        try:
            tag = soup.find("a", {"data-vars-unit-type": "buzz_head"}).contents[0]
        except AttributeError:
            tag = ""
        authors = [i.contents[0] for i in soup.find_all("span", {"class": re.compile("news-byline-full__name*")})]
        try:
            pub_dt = soup.find("p", {"class": "news-article-header__timestamps-posted"}).contents[0]
        except AttributeError:
            pub_dt = ""
        hed = soup.find("h1").contents[0]
        art = soup.find("div", {"class": "js-article-wrapper"})
        try:
            text = [i.text for i in art.find_all(["p", "h2"])]
        except AttributeError:
            text = ""

    result = {
        "tag": tag,
        "authors": authors,
        "pub_date": pub_dt,
        "hed": hed,
        "article_text": text
    }

    return result

def collect_articles(urls, log_path, data_path):
    # Logging and data paths
    # Check for logging path
    if log_path.exists():
        with open(log_path, "r") as f:
            completed_urls = f.read().splitlines()
        urls = list(set(urls) - set(completed_urls))
    print(f"URLs to go: {len(urls)}")
    # For each url
    for u in tqdm(urls):
        # Scrape article
        contents = scrape_article(u)
        # If data returned
        if contents:
            # Append or write data
            contents = pd.DataFrame([contents])
            if data_path.exists():
                mode = "a"
                header = False
            else:
                mode = "w"
                header = True

            contents.to_csv(data_path, mode=mode, header=header, index=False)

        # Append or write log
        if log_path.exists():
            mode = 'a'
        else:
            mode = 'w'
        with open(log_path, mode) as f:
            f.write(f"{u}\n")
        sleep(1)
