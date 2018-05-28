[<img src="https://github.com/QuantLet/Styleguide-and-FAQ/blob/master/pictures/banner.png" width="888" alt="Visit QuantNet">](http://quantlet.de/)

## [<img src="https://github.com/QuantLet/Styleguide-and-FAQ/blob/master/pictures/qloqo.png" alt="Visit QuantNet">](http://quantlet.de/) **Regulatory_Complexity_Sentence_Vectors** [<img src="https://github.com/QuantLet/Styleguide-and-FAQ/blob/master/pictures/QN2.png" width="60" alt="Visit QuantNet 2.0">](http://quantlet.de/)

```yaml

Name of Quantlet : Regulatory_Complexity_Sentence_Vectors
Published in : Measuring Regulatory Complexity and its Impact on the German Banking Sector
Description : Computes sentence embeddings according to Le et al. (2014) doc2vec using gensim
Keywords : Regulatory_Complexity, doc2vec, gensim, sentence-vectors, embeddings
Author : Sabine Bertram
Input : 'modelData: a list of sentences, split into words'
Output : 'sentenceModel: a gensim model containing the embeddings and additional info'

```

### PYTHON Code
```python

#!/usr/bin/python
# -*- coding: utf-8 -*-
################################################################################

# Learning of sentence embeddings

# input: modelData: a list of sentences, split into words
# output: sentenceModel: a gensim model containing the embeddings and additional info

################################################################################

import os
import pickle
import gensim, logging

################################################################################

# import model training data
cwd       = os.getcwd()
inputPath = os.path.normpath(os.path.join(cwd, "..", 'Regulatory_Complexity_Preprocessing'))
with open(os.path.join(inputPath, 'modelData'),'rb') as f:
     data = pickle.load(f)

# convert into labeled sentences
labeledData = []
for c, s in enumerate(data):
    label           = "_".join(s)
    labeledSentence = gensim.models.doc2vec.LabeledSentence(words=s, tags=[label])
    labeledData.append(labeledSentence)


#doc2vec training
###################
# screen output
logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s', level=logging.INFO)

# parameters
method       = 1              # use distributed memory model
features     = 100            # sent vector dimensionality
count        = 3              # Minimum word count
threads      = 4              # Number of threads to run in parallel
context      = 5              # Context window size
downsampling = 1e-3           # Downsample setting for frequent words
hierarch     = 0              # no hierarchical sampling
neg          = 5              # negative sample
epochs       = 10             # number of epochs in NN

# training
model = gensim.models.doc2vec.Doc2Vec(labeledData, dm = method, size = features, window = context, min_count = count, workers = threads, sample = downsampling, hs = hierarch, negative = neg, iter = epochs)
model.init_sims(replace=True)
model.save('sentenceModel')

```

automatically created on 2018-05-28