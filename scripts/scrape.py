import pandas as pd
import scrapy

df = pd.read_csv('../data/COMPOSITE_29days.csv')

links = df.urls.tolist()

class BFscraper(scrapy.Spider):
    name = 'buzzfeed'

    custom_settings = {
        'AUTOTHROTTLE_ENABLED' : True, #make sure set to True for big crawls
        'HTTPCACHE_ENABLED' : True,
        'ROBOTSTXT_OBEY' : True,
        'LOG_LEVEL' : 'INFO'
        # available levels: CRITICAL, ERROR, WARNING, INFO, DEBUG
    }

    start_urls = links
    allowed_domains = "buzzfeednews.com"
    print("\n\nHello there! Starting with {} urls\n\n".format(len(links)))

    def parse(self, response):
        #link,hed,subhed,sections,byline,pub_date,html_body,text_body,tags

        link = response.request.url
        hed = response.css('h1.news-article-header__title').xpath('.//text()').get()
        subhed = response.css('.news-article-header__dek').xpath('.//text()').get()
        byline = response.css('span.news-byline-full__name').xpath('.//text()').get()
        pub_date = response.css('p.news-article-header__timestamps-posted').xpath('.//text()').get()
        section = response.css('#js-post-container > div > div.grid-layout-main.xs-mb2.lg-mb0 > header > nav > ol > li > a').xpath('.//text()').get()

        text_body = ' '.join(response.css('div.js-article-wrapper').xpath('.//text()').extract())
        tags = ''.join(response.css('span.tags-list').xpath('.//text()').extract()[1:-1]).replace('#','')

        yield {
            'link': link,
            'hed': hed,
            'subhed': subhed,
            'section': section,
            'byline':byline,
            'pub_date':pub_date,
            'text_body':text_body
        }
