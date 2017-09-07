#!/usr/bin/python
# -*- coding: utf-8 -*-
################################################################################

# Plots the different complexity measures over time

# input: complexity measures (mean, std, iqr) in /Regulatory_Complexity_Distances/output
# output: folder 'plots' with plots of
#         1. relative change of the complexity over time, relative to the initial value
#         2. percentage change of the complexity over time

################################################################################

# imports

import os
import glob
import datetime
import plotly
import plotly.graph_objs as go
import numpy as np
import pandas as pd

################################################################################

# functions

# preprocessing txt files with complexity measures
def processing(filename, time):
    cwd = os.getcwd()
    dates = []
    dists = []
    with open(filename, 'rb') as f:
         for line in f:
             line = line.strip()
             line = line.split(',')
             dists.append(float(line[1]))
             if line[0] != '0':
                 date = datetime.datetime.strptime(line[0], '%Y-%m-%d')
                 date = date.strftime('%Y-%m-%d')
                 dates.append(date)
             else:
                 date = datetime.datetime(day = 01, month = 11, year = 2006)
                 date = date.strftime('%Y-%m-%d')
                 dates.append(date)

    if (len(dates) > 1) and (dates[0] == dates[1]):
        dates = dates[1:]
        dists = dists[1:]
    series = [None]*len(time)
    for i, d in enumerate(dates):
        if d == '2006-11-01':
            series[0] = dists[0]
        else:
            series[time.index(d)] = dists[i]
    if series[0] == None:
        series[0] = 0
    for j in range(1,len(series)):
        if series[j] == None:
            series[j] = series[j-1]

    return [dates, dists]

################################################################################

# main

# set import path
cwd = os.getcwd()
inputPath = os.path.normpath(os.path.join(cwd, "..", 'Regulatory_Complexity_Distances', 'output'))

# create directory for plot output
directory = os.path.join(os.getcwd(), 'plots')
if not os.path.exists(directory):
    os.mkdir(directory)

# create time series
dt = datetime.datetime(day = 01, month = 11, year = 2006)
end = datetime.datetime(day = 01,month = 02, year = 2017)
step = datetime.timedelta(days = 1)
time = []
while dt < end:
    time.append(dt.strftime('%Y-%m-%d'))
    dt += step

readData = {}
methods = ['average', 'tfidf', 'doc2vec', 'wmd']
for method in methods:
    print 'Plots for: ', method
    # read data
    series = {}
    for f in glob.glob(os.path.join(inputPath, method + '*')):
        name = os.path.basename(f).strip(method).strip('_').strip('.txt')
        series[name] = processing(f, time)
    readData[method] = series

    # convert data to dataframe
    data = {}
    for key, value in series.iteritems():
        data[key] = pd.Series(value[1], index = value[0])
    df = pd.DataFrame(data)
    df['year'] = [d[:4] for d in df.index]

    titles = {'average':'Average Aggregation', 'tfidf':'TF-IDF Aggregation', 'wmd':"Word Mover's Distances", 'doc2vec':'Doc2Vec'}

    # plot relative change in datapoints
    trace0 = go.Scatter(x = df.index, y = df.means/df.means[0], mode = 'lines', name = 'Mean')
    trace1 = go.Scatter(x = df.index, y = df.stds/df.stds[0], mode = 'lines', name = 'SD')
    trace2 = go.Scatter(x = df.index, y = df.iqrs/df.iqrs[0], mode = 'lines', name = 'IQR')
    data = [trace0, trace1, trace2]
    layout = dict(height=600, width=1000, title = titles[method], yaxis = dict(title = 'Relative change in complexity'), xaxis = dict(tickformat = '%Y-%m-%d', dtick = 'M6'), showlegend=False)
    figure = dict(data=data, layout=layout)
    plotly.offline.plot(figure, filename = os.path.join(cwd, 'plots', method + '_relative.html'), auto_open = False)

    # plot percentage change in datapoints
    trace3 = go.Scatter(x = df.index, y = df.means.pct_change().fillna(0), mode = 'lines', name = 'Mean')
    trace4 = go.Scatter(x = df.index, y = df.stds.pct_change().fillna(0), mode = 'lines', name = 'SD')
    trace5 = go.Scatter(x = df.index, y = df.iqrs.pct_change().fillna(0), mode = 'lines', name = 'IQR')
    data = [trace3, trace4, trace5]
    layout = dict(height=600, width=1000, yaxis = dict(title = 'Percentage change in complexity'), xaxis = dict(tickformat = '%Y-%m-%d', dtick = 'M6'), legend=dict(orientation = 'h', x=0, y=-0.2))
    figure = dict(data=data, layout=layout)
    plotly.offline.plot(figure, filename = os.path.join(cwd, 'plots', method + '_percentage.html'), auto_open = False)

    # generate yearly aggregates
    g = df.groupby(["year"])
    yearlyAverages = g.aggregate({'iqrs':np.mean, 'means':np.mean, 'stds':np.mean})
    yearlyAverages = yearlyAverages.loc[yearlyAverages.index > '2011']
    del df['year']

    # plot relative change in datapoints
    trace6 = go.Scatter(x = yearlyAverages.index[:-1], y = (yearlyAverages.means/yearlyAverages.means[0])[:-1], mode = 'lines', name = 'Mean')
    trace7 = go.Scatter(x = yearlyAverages.index[:-1], y = (yearlyAverages.stds/yearlyAverages.stds[0])[:-1], mode = 'lines', name = 'SD')
    trace8 = go.Scatter(x = yearlyAverages.index[:-1], y = (yearlyAverages.iqrs/yearlyAverages.iqrs[0])[:-1], mode = 'lines', name = 'IQR')
    data = [trace6, trace7, trace8]
    layout = dict(height=600, width=1000, title = titles[method], yaxis = dict(title = 'Relative complexity - yearly average'), xaxis = dict(dtick = 'linear'),
    showlegend=False)
    figure = dict(data=data, layout=layout)
    plotly.offline.plot(figure, filename = os.path.join(cwd, 'plots', method + '_yearly_relative.html'), auto_open = False)

    # plot percentage change in datapoints
    trace9 = go.Scatter(x = yearlyAverages.index[:-1], y = yearlyAverages.means.pct_change().fillna(0)[:-1], mode = 'lines', name = 'Mean')
    trace10 = go.Scatter(x = yearlyAverages.index[:-1], y = yearlyAverages.stds.pct_change().fillna(0)[:-1], mode = 'lines', name = 'SD')
    trace11 = go.Scatter(x = yearlyAverages.index[:-1], y = yearlyAverages.iqrs.pct_change().fillna(0)[:-1], mode = 'lines', name = 'IQR')
    data = [trace9, trace10, trace11]
    layout = dict(height=600, width=1000, yaxis = dict(title = 'Percentage change in complexity - yearly average'), xaxis = dict(dtick = 'linear'),
    legend=dict(orientation = 'h'))
    figure = dict(data=data, layout=layout)
    plotly.offline.plot(figure, filename = os.path.join(cwd, 'plots', method + '_yearly_percentage.html'), auto_open = False)

print 'Done.'
