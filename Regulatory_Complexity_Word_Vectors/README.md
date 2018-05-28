[<img src="https://github.com/QuantLet/Styleguide-and-FAQ/blob/master/pictures/banner.png" width="888" alt="Visit QuantNet">](http://quantlet.de/)

## [<img src="https://github.com/QuantLet/Styleguide-and-FAQ/blob/master/pictures/qloqo.png" alt="Visit QuantNet">](http://quantlet.de/) **Regulatory_Complexity_Word_Vectors** [<img src="https://github.com/QuantLet/Styleguide-and-FAQ/blob/master/pictures/QN2.png" width="60" alt="Visit QuantNet 2.0">](http://quantlet.de/)

```yaml

Name of Quantlet : Regulatory_Complexity_Word_Vectors
Published in : Measuring Regulatory Complexity and its Impact on the German Banking Sector
Description : Computes word embeddings according to Mikolov et al. (2013) word2vec using gensim
Keywords : Regulatory_Complexity, word2vec, gensim, word-vectors, embeddings
Author : Sabine Bertram
Input : 'modelData: a list of sentences, split into words'
Output : 'wordModel: a gensim model containing the embeddings and additional info'

```

### PYTHON Code
```python

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
cwd       = os.getcwd()
inputPath = os.path.normpath(os.path.join(cwd, "..", 'Regulatory_Complexity_Preprocessing'))
with open(os.path.join(inputPath, 'modelData'),'rb') as f:
     data = pickle.load(f)

# screen output
logging.basicConfig(format='%(asctime)s : %(levelname)s : %(message)s', level=logging.INFO)

# parameters
skip_gram    = 1            # use skip gram model
features     = 100          # Word vector dimensionality
count        = 3            # Minimum word count
threads      = 4            # Number of threads to run in parallel
context      = 5            # Context window size
downsampling = 1e-3         # Downsample setting for frequent words
neg          = 5            # negative sample
epochs       = 10           # number of epochs in NN

# training
model = gensim.models.Word2Vec(data, sg = skip_gram, size = features, window = context, min_count = count, workers = threads, negative = neg, iter = epochs)
model.init_sims(replace=True)
model.save('wordModel')

```

automatically created on 2018-05-28