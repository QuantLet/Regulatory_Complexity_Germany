from scipy.spatial import distance

def avAggreg(inputs):
    sentence, model = inputs
    wVecs = []
    for w in sentence:
        try:
            wVec = model[w]
            wVecs.append(wVec)
        except:
            continue
    l = len(wVecs)
    avVec = [sum(i)/l for i in zip(*wVecs)]
    return avVec

def tfidfAggreg(inputs):
    sentence, model, dicCorpus = inputs
    wwVecs = []
    for w in sentence:
        try:
            wVec = model[w]
            wWeight = dicCorpus[w]
            wwVec = [i*wWeight for i in wVec]
            wwVecs.append(wwVec)
        except:
            continue
    tfidfVector = [sum(i) for i in zip(*wwVecs)]
    return tfidfVector

def distances(inputs):
    i, j, sentVecs = inputs
    dist = distance.euclidean(sentVecs[i], sentVecs[j])
    return dist

def newDistances(inputs):
    i, j, newSentVecs, oldSentVecs= inputs
    dist = distance.euclidean(newSentVecs[i], oldSentVecs[j])
    return dist

def wmdPrep(paragraph, frequency, stop):
    sentences = []
    for s in paragraph:
        sent = [w for w in s if w not in stop]
        sent = [token for token in sent if frequency[token] > 2]
        sentences.append(sent)
    return sentences

def wmdDist(inputs):
    i, j, sentences, model = inputs
    dist = model.wmdistance(sentences[i], sentences[j])
    return dist

def getVectors(inputs):
    sentence, model = inputs
    label = "_".join(sentence)
    vector = model.docvecs[label]
    return vector
