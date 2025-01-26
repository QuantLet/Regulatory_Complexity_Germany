<div style="margin: 0; padding: 0; text-align: center; border: none;">
<a href="https://quantlet.com" target="_blank" style="text-decoration: none; border: none;">
<img src="https://github.com/StefanGam/test-repo/blob/main/quantlet_design.png?raw=true" alt="Header Image" width="100%" style="margin: 0; padding: 0; display: block; border: none;" />
</a>
</div>

```
Name of Quantlet: Regulatory_Complexity_Distances

Published in: Measuring Regulatory Complexity and its Impact on the German Banking Sector

Description: Computes distances between all sentences in a given version of the GBA and aggregates them to a single complexity measure.

Keywords: Regulatory_Complexity, complexity-measure, word2vec, doc2vec, gensim, euclidean-distance, word-movers-distance

Author: Sabine Bertram

Input: - wordModel: the gensim word2vec model
- sentenceModel: the gensim doc2vec model
- completeVersions: a dictionary with key: date, value: list of sentences

Output: folder 'output' with files called METHOD_METRIC.txt for each distance calculation method and each metric (mean, sd, iqr)

```
