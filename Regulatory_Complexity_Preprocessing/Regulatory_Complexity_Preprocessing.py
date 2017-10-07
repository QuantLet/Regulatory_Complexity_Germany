#!/usr/bin/python
# -*- coding: utf-8 -*-
################################################################################

# Preprocessing of HTM files

# input:  - htm pages including the changes in the GBA
# output: - pythonData: a dictionary of tuples with key: paragraphs, value: (date, list of sentences)
#         - modelData: a list of sentences for the vector learning process
#         - completeVersions: a dictionary of tuples with key: date, value: list of sentences

################################################################################

# imports

import os
from bs4 import BeautifulSoup, NavigableString, Tag
import re
from datetime import datetime
import translitcodec
import pickle
from natsort import natsorted, ns

################################################################################

# functions

# clean test of h-class tags
def cleanH(hList):
    for item in hList:
        plain = item.text.strip()
        if re.search(r'^\([A-Z]', plain):
            plain = re.sub(r'\([A-Z].*?\)|\s\([A-Z].*?\)', '', plain)
        elif re.search(r'^\xa7', plain):
            continue
        bullets      = plain.split('  ')
        cleanBullets = []
        cleanP       = ''
        for p in bullets:
            p = p.strip()
            if p and p.startswith('('):
                if cleanP:
                    cleanBullets.append(cleanP.strip())
                cleanP = p.strip() + ' '
            elif p and p[0].isdigit():
                p = re.sub(r'^\d.*?\.', '', p).strip() + ' '
                cleanP += p
            elif p and p[1] == ')':
                p = re.sub(r'^[a-z]\)', '', p).strip() + ' '
                cleanP += p
            elif '---' in p:
                p = re.sub(r'---.*', '', p).strip() + ' '
            elif p:
                cleanP += p + ' '
        if cleanP: cleanBullets.append(cleanP.strip())

        return cleanBullets

# sort paragraphs' subitems
def sortPar(h1, h2):
    if h1 and h2:
        par = sorted(h1 + h2)
    elif h1 and not h2:
        par = h1
    elif not h1 and h2:
        par = h2
    else:
        par = []
    return par

# replace abbreviations such that splitting at . is possible
def cleanSents(parList, abbrevs, repl):
    paragraphs = []
    for p in parList:
        p = p.encode('translit/long').encode('utf-8')
        for i in range(len(abbrevs)):
            p = p.replace(abbrevs[i], repl[i])
        sentences = p.split('.')
        sentences = [re.sub(r'^\d', '', sent).strip() for sent in sentences]
        sents = []
        for s in sentences:
            s = s.strip()
            if s:
                words = s.split(' ')
                cleanWords = []
                for w in words:
                    w = w.strip()
                    w = w.strip('_')
                    w = w.strip(':')
                    w = w.strip(';')
                    w = w.strip(',')
                    w = w.strip('.')
                    w = w.strip('(')
                    w = w.strip(')')
                    w = w.strip('[')
                    w = w.strip(']')
                    w = w.strip('-')
                    w = w.lower()
                    if w:
                        cleanWords.append(w)
                #print cleanWords
                sents.append(cleanWords)
        paragraphs += sents
    return paragraphs

# conduct sorting and cleaning of paragraph at once
def processPar(h1, h2, abbrevs, repl):
    # sort
    par = sortPar(h1, h2)
    # remove numbering in beginning
    par = [re.sub(r'^\(.+?\)', '', p).strip() for p in par]
    # split into sentences and clean words
    par = cleanSents(par, abbrevs, repl)
    return par

################################################################################

# main

cwd = os.getcwd()
inputPath = os.path.normpath(os.path.join(cwd, "..", 'Regulatory_Complexity_Scraper', 'pages'))

# load pages and save paragraph #, date, list of sentences
data      = []
modelData = []
filenames = sorted(os.listdir(inputPath), reverse = True)
for filename in filenames:

    with open(os.path.join(inputPath, filename),'rb') as f:
        page = f.read()
        soup = BeautifulSoup(page.decode('utf-8','ignore'))

        # paragraph number and date of enactment
        title = soup('title')[0].contents[0]
        try:
            parNum = re.findall(r'\xa7\s(.+?)\sKWG|(Anhang\s.+)\sKWG', title)[0]
        except:
            continue
        parNum = [p for p in parNum if p][0]
        # exceptions
        if ('bis' in parNum) or ('und' in parNum):
            parNum = parNum.split()[0]

        # paragraphs that have been changed
        if '-' in filename:
            date = re.findall(r'\d+\.\d+\.\d{4}', title)[0]
            d    = datetime.strptime(date, '%d.%m.%Y')
            date = d.strftime('%Y-%m-%d')
            # print parNum, date

            # is this the oldest version?
            hnav  = soup.findAll(text='(keine frühere Fassung vorhanden)')
            aTags = soup('a')
            lines = ''
            for tag in aTags:
                lines += tag.get_text() + ' '
            before   = re.findall(r'here Fassung von', lines)
            after    = re.findall(r'chste Fassung von', lines)
            multiple = before + after
            oldest   = False
            if hnav or not multiple:
                oldest = True

            abbrevs = ['a.', 'Abs.', 'b.', 'c.', 'Nr.', 'ABl.', 'S.', 'BGBl.', 'u.', 'vgl.', 'd.', 'Gem.', 'v.', 'e.', 'I.', 'bzw.', '1.']
            repl    = ['a_', 'Abs_', 'b_', 'c_', 'Nr_', 'ABl_', 'S_', 'BGBl_', 'u_', 'vgl_', 'd_', 'Gem_', 'v_', 'e_', 'I_', 'bzw_', '1_']

            days   = [str(i) for i in range(1,32)]
            months = ['Januar', 'Februar', 'Maerz', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember']

            abbrevs = abbrevs + [d + '. ' + m for d in days for m in months]
            repl    = repl + [d + '_ ' + m for d in days for m in months]


            # if oldest version, save previous and new version
            if oldest:
                halt = cleanH(soup.findAll('td', {'class': 'halt'}))
                hunc = cleanH(soup.findAll('div', {'class': 'hunc'}))
                hneu = cleanH(soup.findAll('td', {'class': 'hneu'}))

                # process paragraphs
                oldPar = processPar(halt, hunc, abbrevs, repl)
                newPar = processPar(hneu, hunc, abbrevs, repl)

                # save data
                data.append((parNum, 0, oldPar))
                data.append((parNum, date, newPar))

                # save modelData
                for s in oldPar + newPar:
                    if s not in modelData:
                        modelData.append(s)

            # if not, save only new version
            else:
                hunc = cleanH(soup.findAll('div', {'class': 'hunc'}))
                hneu = cleanH(soup.findAll('td', {'class': 'hneu'}))

                #process paragraphs
                newPar = processPar(hneu, hunc, abbrevs, repl)

                # save data
                data.append((parNum, date, newPar))

                # save modelData
                for s in newPar:
                    if s not in modelData:
                        modelData.append(s)

        # paragraphs that have not been changed
        else:
            if not filter(lambda x: x[0] == parNum and x[1] == 0, data):
                ha = soup.findAll('div', {'class': 'dcontc'})
                for item in ha:
                    brStripped = list(item.stripped_strings)
                    flag = 0
                    par = ''
                    for g in brStripped:
                        if flag == 0:
                            if re.search(r'^\d+\sVorschriften\szitiert', g):
                                flag = 1
                        else:
                            if re.search(r'^\xa7', g):
                                flag = 0
                            else:
                                par += g.strip() + ' '
                    par = re.sub(r'\(\d\)\s', '', par)
                    par = re.sub(r'\d\.\s', '', par)
                    par = [par]
                    par = cleanSents(par, abbrevs, repl)

                    # save data
                    data.append((parNum, 0, par))

                    # save modelData
                    for s in par:
                        if s not in modelData:
                            modelData.append(s)


# reorder data to generate pythonData
parNums = []
dic = {}
for item in data:
    if item[0] not in parNums:
        parNums.append(item[0])
        entry = [[item[1], item[2]]]
        dic[item[0]] = entry
    else:
        sofar = [i[0] for i in dic[item[0]]]
        flag  = 0
        for c, s in enumerate(sofar):
            if item[1] == s:
                dic[item[0]][c][1] = item[2]
                flag = 1
        if flag == 0:
            entry = [item[1], item[2]]
            dic[item[0]].append(entry)

pythonData = {}
for key in dic:
    pythonData[key] = sorted(dic[key])

# reoder data by date
dates  = []
byDate = {}
for par in pythonData:
    versions = pythonData[par]
    for v in versions:
        date = v[0]
        sentences = v[1]
        if date not in dates:
            byDate[date] = [(par, sentences)]
            dates.append(date)
        else:
            byDate[date].append((par, sentences))

# convert it to a sorted list
byDateList = []
for (key, value) in byDate.iteritems():
    value = natsorted(value)
    entry = [key, value]
    byDateList.append(entry)

byDateList = sorted(byDateList)

# construct complete versions of the GBA
versions    = {}
previous    = byDateList[0][1]
previousNum = [i[0] for i in previous]
for item in byDateList:
    key   = item[0]
    value = item[1]
    nums  = [i[0] for i in value]
    for n in previousNum:
        if n not in nums:
            value.append(previous[previousNum.index(n)])
    versions[key] = natsorted(value)
    previous      = value
    previousNum   = [i[0] for i in previous]

# give up paragraphs, each version is only list of sentences
versionsSent = {}
for (key, value) in versions.iteritems():
    sentLists = [i[1] for i in value]
    oneList   = []
    for j in sentLists:
        oneList += j
    versionsSent[key] = oneList

# save data
with open('pythonData', 'w') as f:
    pickle.dump(pythonData, f)
with open('modelData', 'w') as g:
    pickle.dump(modelData, g)
with open('completeVersions', 'w') as h:
    pickle.dump(versionsSent, h)

# generate word and sentence counts
numOfSents = []
numOfWords = []
dates      = []
for (key, value) in versionsSent.iteritems():
    dates.append(key)
    numOfSents.append(len(value))
    words = 0
    for item in value:
        words += len(item)
    numOfWords.append(words)

dates, numOfSents, numOfWords = zip(*sorted(zip(dates, numOfSents, numOfWords)))

descriptives = [numOfSents, numOfWords]
savenames    = ['numSentences.txt', 'numWords.txt']
for series in descriptives:
    with open(savenames[descriptives.index(series)], 'w') as f:
        for i in range(len(series)):
            f.write(str(dates[i]) + ',' + str(series[i]) + '\n')
