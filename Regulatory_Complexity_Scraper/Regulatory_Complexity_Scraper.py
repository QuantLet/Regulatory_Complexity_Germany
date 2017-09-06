#!/usr/bin/python
# -*- coding: utf-8 -*-
################################################################################

# HTM Scraper

################################################################################

import os
import urllib2
from bs4 import BeautifulSoup
import pickle
import random

# open proxy list
with open('proxies.txt') as fp:
    ips = [i.strip().split(':')[0] for i in fp.readlines()]

# create directory for pages
directory = os.path.join(os.getcwd(), 'pages')
if not os.path.exists(directory):
    os.mkdir(directory)

# scrape pages
c = 1
for url in ['http://www.buzer.de/gesetz/962/l.htm', 'http://www.buzer.de/gesetz/962/index.htm']:
    # read main page
    html = urllib2.urlopen(url).read()

    # convert it to a BeautifulSoup object
    soup = BeautifulSoup(html)

    # retrieve all of the anchor tags and save relevant pages
    tags = soup('a')
    for tag in tags:
        link = tag.get('href', None)
        if link and ('/962/a' in link):
            c += 1
            while True:
                try:
                    ip = random.choice(ips)
                    proxy_handler = urllib2.ProxyHandler({'http': ip})
                    opener = urllib2.build_opener(proxy_handler)
                    opener.addheaders = [('User-agent', 'Mozilla/5.0')]
                    urllib2.install_opener(opener)
                    req = urllib2.Request('http://www.buzer.de' + link)
                    response = urllib2.urlopen(req, None, 5)
                    html = response.read()
                    if not 'KWG' in html:
                        continue
                    else:
                        break
                # check for expired proxies and delete them
                except urllib2.HTTPError:
                    ips.remove(ip)
                except Exception:
                    ips.remove(ip)

            name = link.split('/')[-1]
            with open(os.path.join(directory, name), 'w') as g:
                pickle.dump(html, g)
            if c % 10 == 0:
                print 'Number of pages downloaded: ', c
                print 'Number of active proxies left: ', len(ips)
