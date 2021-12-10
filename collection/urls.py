import pathlib
from time import sleep

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
    base = 'https://www.buzzfeed.com/archive'

    path = pathlib.Path(path)
    log_path = pathlib.Path("./data/url_log.txt")
    if log_path.exists():
        with open(log_path, "r") as f:
            start_date = f.read()
        start_date = pd.to_datetime(start_date)
        dates = pd.date_range(start_date, dates[-1])

    for d in tqdm(dates):
        with open(log_path, "w") as f:
            f.write(str(d))
        url = f'{base}/{d.year}/{d.month}/{d.day}'
        r = requests.get(url)
        soup = BeautifulSoup(r.text)
        links = soup.find_all("a", {"class": 'js-card__link link-gray'})
        hrefs = [i['href'] for i in links]
        if len(hrefs)==0:
            break
        if path.exists():
            mode = 'a'
        else:
            mode = 'w'

        with open(path, mode) as f:
            for i in hrefs:
                f.write(f"{i}\n")
        
        sleep(1)
        