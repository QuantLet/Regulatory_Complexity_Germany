#!/usr/bin/python
# -*- coding: utf-8 -*-
################################################################################

# Learning of word embeddings

# input: modelData: a list of sentences, split into words
# output: wordModel: a gensim model containing the embeddings and additional info

################################################################################

import os
import pickle
import gensim, logging

################################################################################

# import model training data
cwd = os.getcwd()
inputPath = os.path.normpath(os.path.join(cwd, "..", 'Regulatory_Complexity_Preprocessing'))
with open(os.path.join(inputPath, 'modelData'),'rb') as f:
     data = pickle.load(f)

# screen output
logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s', level=logging.INFO)

# parameters
skip_gram = 1           # use skip gram model
features = 100          # Word vector dimensionality
count = 3               # Minimum word count
threads = 4             # Number of threads to run in parallel
context = 5             # Context window size
downsampling = 1e-3     # Downsample setting for frequent words
neg = 5                 # negative sample
epochs = 10             # number of epochs in NN

# training
model = gensim.models.Word2Vec(data, sg = skip_gram, size = features, window = context, min_count = count, workers = threads, negative = neg, iter = epochs)
model.init_sims(replace=True)
model.save('wordModel')
