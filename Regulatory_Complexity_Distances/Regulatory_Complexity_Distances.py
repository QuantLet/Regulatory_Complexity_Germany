#!/usr/bin/python
# -*- coding: utf-8 -*-
################################################################################

# Computes distances of sentences generated based on several techniques

# 1. Average aggregation of word2vec word vectors + euclidean distance
# 2. TF-IDF aggregation of word2vec word vectors + euclidean distance
# 3. Word Movers' Dinstances of sentences using word2vec word vectors
# 3. doc2vec sentence vectors + euclidean distance

# input: - wordModel: the gensim word2vec model
#        - sentenceModel: the gensim doc2vec model
#        - completeVersions: a dictionary with key: date, value: list of sentences
# output: folder 'output' with files called METHOD_METRIC.txt for each distance
#         calculation method and each metric (mean, sd, iqr)

################################################################################

# imports

import os
import gensim
from gensim import corpora, models
import logging
import pickle
import multiprocessing
import multiprocessing.pool
import math
from nltk.corpus import stopwords
from collections import defaultdict
import itertools
from scipy.spatial import distance
import numpy as np
import warnings
from tqdm import tqdm
from functions import *

################################################################################

# functions in functions.py

################################################################################

# main

# load paragraphs with dates and sentences
cwd = os.getcwd()
bd = os.path.normpath(os.path.join(cwd, ".."))

with open(os.path.join(bd, 'Regulatory_Complexity_Preprocessing', 'completeVersions'),'rb') as g:
     versions = pickle.load(g)

# prepare for multithreaded processing
numCores = int(math.floor(multiprocessing.cpu_count()))
pool = multiprocessing.Pool(processes=numCores)

# create directory for output measures
directory = os.path.join(os.getcwd(), 'output')
if not os.path.exists(directory):
    os.mkdir(directory)

for method in ['average', 'tfidf', 'wmd', 'doc2vec']:

    print 'Current method: ', method
    # load neccessary data
    if (method == 'average') or (method == 'tfidf') or (method == 'wmd'):
        # load gensim model
        model = gensim.models.Word2Vec.load(os.path.join(bd, 'Regulatory_Complexity_Word_Vectors', 'wordModel'))
        # load sentences for dictionary
        with open(os.path.join(bd, 'Regulatory_Complexity_Preprocessing', 'modelData'), 'rb') as f:
            data = pickle.load(f)
    else:
        # load gensim model
        model = gensim.models.Doc2Vec.load(os.path.join(bd, 'Regulatory_Complexity_Sentence_Vectors', 'sentenceModel'))

    # load stopwords for wmd
    if method == 'wmd':
        frequency = defaultdict(int)
        for s in data:
            for token in s:
                frequency[token] += 1
        stop = set(stopwords.words('english'))

    # calculate distances
    vMeans = []
    vStds = []
    vIQRs = []
    for key in tqdm(sorted(versions)):
        date = key
        sentences = versions[key]
        if method == 'wmd':
            sentences = wmdPrep(sentences, frequency, stop)
            sentences = [s for s in sentences if s]
            x = len(sentences)
            indices = [(i,j) for i,j in itertools.product(range(x), range(x)) if (i != j) and (i < j)]
            inputs = [(i[0], i[1], sentences, model) for i in indices]
            distList = pool.map(wmdDist, inputs)
            dists = [d for d in distList if d != float('inf')]
        else:
            if method == 'average':
                inputs = [(s, model) for s in sentences]
                sentVecs = pool.map(avAggreg,inputs)
                sentVecs = [s for s in sentVecs if s]

            elif method == 'tfidf':
                dictionary = corpora.Dictionary(sentences)
                corpus = [dictionary.doc2bow(s) for s in sentences]
                tfidf = models.TfidfModel(corpus)
                corpus_tfidf = tfidf[corpus]
                dicCorpus = {dictionary.get(id): value for doc in corpus_tfidf for id, value in doc}
                inputs =[(s, model, dicCorpus) for s in sentences]
                sentVecs = pool.map(tfidfAggreg,inputs)
                sentVecs = [s for s in sentVecs if s]

            elif method == 'doc2vec':
                inputs = [(s, model) for s in sentences]
                sentVecs = pool.map(getVectors, inputs)

            x = len(sentVecs)
            indices = [(i,j) for i,j in itertools.product(range(x), range(x)) if (i != j) and (i < j)]
            inputs = [(i[0], i[1], sentVecs) for i in indices]
            dists = pool.map(distances,inputs)

        # dispersion measures per version
        try:
            mean = np.mean(dists)
        except RuntimeWarning:
            mean = 0
        try:
            std = np.std(dists)
        except RuntimeWarning:
            std = 0
        try:
            q1 = np.percentile(dists, 25)
            q3 = np.percentile(dists, 75)
            iqr = q3 - q1
        except:
            iqr = 0
        vMeans.append((date, mean))
        vStds.append((date, std))
        vIQRs.append((date, iqr))

    # save data
    outputs = [vMeans, vStds, vIQRs]
    names = ['_means', '_stds', '_iqrs']
    for i, output in enumerate(outputs):
        with open(os.path.join(directory, method + names[i] + '.txt'), 'w') as f:
             for item in output:
                 w = str(item[0]) + ',' + str(item[1]) + '\n'
                 f.write(w)
