import pathlib

from bs4 import BeautifulSoup
import pandas as pd
import requests
from tqdm import tqdm

def daterange(date: str, padding: int) -> pd.DatetimeIndex:
    """Get range of dates a certain time period around a date"""
    mid = pd.to_datetime(date)
    pad = pd.to_timedelta(f'{padding} days')
    start = mid - pad
    end = mid + pad

    return (start, end)

def collect_urls(dates, path: str) -> None:
    """Collects unfiltered story URLs and saves them to disc"""
    if not path.exists():
        path.mkdir()

    base = "https://www.buzzfeednews.com/sitemap/news/"
    path = pathlib.Path(path)

    years = set([i.year for i in dates])

    for y in tqdm(years):
        it = 1
        url = f"{base}{y}_{it}.xml"
        r = requests.get(url)
        soup = BeautifulSoup(r.text)
        urls = [i.text for i in soup.find_all("loc")]
        with open(path / f"{y}_{it}.txt", "w") as f:
            for u in urls:
                f.write(f"{u}\n")

        while len(urls) > 0:
            it += 1
            url = f"{base}{y}_{it}.xml"
            r = requests.get(url)
            soup = BeautifulSoup(r.text)
            urls = [i.text for i in soup.find_all("loc")]
            with open(path / f"{y}_{it}.txt", "w") as f:
                for u in urls:
                    f.write(f"{u}\n")