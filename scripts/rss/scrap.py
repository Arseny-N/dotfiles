#!/usr/bin/python3
from bs4 import BeautifulSoup
import requests
from urllib.parse import urlparse, urljoin
import datetime
from pathlib import Path

import dateparser
from rfeed import *
import favicon

import os
import sys



class FeedConverter:

    html_base = Path('./html')
    feeds_base = Path('./feeds')
    
    name = None
    title = None
    author = None
    base_url = None
    

    def fetch_html_from_web(self):
        self.log('Fetching', self.name, 'from web...')
        headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36'}
        page = requests.get(self.base_url, headers=headers)
        self.log('Got', len(page.content), 'bytes.')
        return page.content
    
    def fetch_html_from_file(self):
        self.log('Fetching', self.name, 'from file')
        return Path(self.html_base / (self.name + '.html') ).read_text()
    
    def fetch_html(self):      
        if self.fetch_from_web:
            return self.fetch_html_from_web()
        else:
            return self.fetch_html_from_file()


    def log(self, *args):
        if self.verbose:
            print(*args, file=sys.stderr)
    
    def __init__(self, fetch_from_web=False, save_to_file=True, verbose=True):
        self.fetch_from_web = fetch_from_web
        self.save_to_file = save_to_file
        self.verbose = verbose

    def soup_items(self, soup):
        pass
    
    def build_rss_item(self, soup_item):
        pass
    
    def build_feed(self, rss_items):
        image_link = favicon.get(self.base_url)[0].url
        image = Image(image_link, 'icon', self.base_url)
    
        feed = Feed(
            title = self.title,
            link = self.base_url,
            description = self.title,
            language = "en-US",
            lastBuildDate = datetime.datetime.now(),
            items = rss_items,
            image = image
        )
        
        return feed
        

    
    def html_to_feed(self):
        
        html = self.fetch_html()
        
        soup = BeautifulSoup(html, 'html.parser')
        
        items = self.soup_items(soup)
        items = [
            self.build_rss_item(item)
                for item in items    
        ]

        self.log('Extracted', len(items), 'items')
        feed = self.build_feed(items)

        if self.save_to_file:
            self.feed_to_file(feed)
        else:
            self.log('Printing feed xml')
            self.log('------------------------')
            print(feed.rss())

    def feed_to_file(self, feed):
        feed_file = self.feeds_base / (self.name+'.xml')
        self.log('Saving feed to', feed_file)        
        feed_file.write_text(feed.rss())

    
    
    
registry = {}
def register_converter(cls):
    registry[cls.name] = cls
    return cls

#
# Converters
#


@register_converter
class ColinRaffel(FeedConverter):
    title = 'Colin Raffel Blog'
    author = 'Colin Raffel'
    base_url = 'http://colinraffel.com/blog/'
    name = 'colin-raffel'
    
    def soup_items(self, soup):
        return soup.find_all('div', class_='item')
    
    def build_rss_item(self, item):
        date, post = item.find_all('div')
        date = date.text
        post = post.find('a')
        link = post.attrs['href']
        title = post.text
        link = urljoin(self.base_url, link)
        date = dateparser.parse(date)

        return Item(
            title = title,
            link = link, 
            description = title,
            author = self.author,
            guid = Guid(link),
            pubDate = date
        )


@register_converter
class SamGreydanus(FeedConverter):
    
    name = 'sam-greydanus'
    title = 'Sam Greydanus Blog'
    author = 'Sam Greydanus'
    base_url = 'https://greydanus.github.io/'
        
    def soup_items(self, soup):
        return soup.find('ul', class_='posts').find_all('li')
    
    def build_rss_item(self, item):
        a = item.find('a', class_='post-link')
                        
        link = a.attrs['href']        
        link = urljoin(self.base_url, link)
        
        title = a.text
        
        date = item.find('span',class_='post-date').text
        date = dateparser.parse(date)
        
        description = item.text
        
        # print(link, title, date, description)
        # print('-----')
        
        return Item(
            title = title,
            link = link, 
            description = description,
            author = self.author,
            guid = Guid(link),
            pubDate = date,
            # image = Image()
        )   

import argparse


def main():

    parser = argparse.ArgumentParser(description='Scrap/Convert rss feeds')

    parser.add_argument('feed_name', choices=list(registry),
                        help='Feed to convert')

    parser.add_argument('-f', '--fetch_from_file', action='store_true',
                        help='Retrive data from html/<feed_name>.html')

    parser.add_argument('-s', '--save_to_file', action='store_true',  
                        help='Silently save extracted data to feeds/<feed_name>.xml')

    parser.add_argument('-v', '--verbose', action='store_true', 
                        help='Print logs to stderr')

    args = parser.parse_args()

    registry[args.feed_name](
            fetch_from_web=not args.fetch_from_file,
            save_to_file=args.save_to_file,
            verbose=args.verbose
        ).html_to_feed()
    

if __name__ == '__main__':
    main()