import re
from time import sleep
from typing import List

from bs4 import BeautifulSoup
import pandas as pd
import requests
from tqdm import tqdm

def load_and_filter_urls(path: str) -> List[str]:
    url_paths = [i for i in path.glob("*.txt")]
    all_urls = []
    for p in url_paths:
        with open(p, "r") as f:
            urls = f.readlines()
        urls = [i.replace("\n", "") for i in urls]
        all_urls.extend(urls)

    all_urls = list(set(all_urls))

    return all_urls

def scrape_article(url: str):
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36"
    }
    r = requests.get(url, headers=headers)
    soup = BeautifulSoup(r.text)
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
        "url": url,
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
