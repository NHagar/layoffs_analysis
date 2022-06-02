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
        section = soup.find("meta", {"property": "article:section"})["content"]
    except (AttributeError, TypeError) as e:
        section = ""
    try:
        tags = [i['content'] for i in soup.find_all("meta", {"property": "article:tag"})]
    except AttributeError:
        tags = ""
    authors = [i['content'] for i in soup.find_all("meta", {"property": "author"})]
    try:
        pub_dt = [i['datetime'] for i in soup.find_all("time") if "Posted" in i.text][0]
    except (AttributeError, IndexError) as e:
        pub_dt = ""
    hed = soup.find("h1").contents[0]
    art = soup.find("article")
    try:
        text = []
        for i in art.find_all(["p", "h2"]):
            if i.has_attr("class"):
                if "bfp-related-links" in "".join(i["class"]) or "newsfooter" in "".join(i["class"]):
                    continue
            text.append(i.text)
        text = " ".join(text)
    except AttributeError:
        text = ""

    result = {
        "url": url,
        "section": section,
        "tags": tags,
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
