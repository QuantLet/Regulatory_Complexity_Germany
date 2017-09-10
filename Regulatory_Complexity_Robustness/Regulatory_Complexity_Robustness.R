################################################################################

# Robustness

# input: - regressiondata.csv: sample data and yearly aggregates of complexity
# output: - latex regression tables for robustness checks
#         - descriptives to compute economic effects

################################################################################

# imports

library(dplyr)
library(plm)
library(stargazer)

################################################################################

# functions

source(file.path(getwd(), 'Regulatory_Complexity_Regressions', 'functions.R'))

################################################################################

# main

# load data
inputPath     = file.path(getwd(), 'Regulatory_Complexity_Regressiondata', 'data')
regData       = read.csv(file.path(inputPath, 'regressiondata.csv'))
regData$X     = NULL
regData$index = factor(regData$index)
regData$year  = factor(regData$year)

### 1. Hypothesis 1 Robustness Checks

# Regression Variables
bankControls       = c('Size_lag1', 'EquityRatio_lag1', 'Liquidity_lag1',
                       'Funding_lag1', 'Risk_lag1', 'BusinessModel_lag1')
complexity         = colnames(regData)[grep(pattern = 'avg$',
                                            colnames(regData))]
complexityInteract = paste(complexity, 'Size_lag1', sep = ':')

# find indices of small and large banks
idxROA = regData %>% 
  group_by(index) %>% 
  summarize_at(c('ROA', 'EquityRatio', 'Size', 'Liquidity', 
                 'Funding', 'Risk', 'BusinessModel'), 
               funs(mean, sum(!is.na(.))), na.rm = TRUE) %>% 
  arrange(Size_mean) %>% 
  select(c(index, Size_mean, ends_with('sum'))) %>% 
  select(index)
idxROA = as.vector(idxROA$index)
small  = idxROA[1:floor(0.5*length(idxROA))]
large  = idxROA[ceiling(0.5*length(idxROA)):length(idxROA)]

for (i in 1:2){
  if (i== 1){
    idxROA = small
    cat('\nSmall Banks\n')
  }else{
    idxROA = large
    cat('\nLarge Banks\n')
  }
  # construct dataset
  robDataROA       = regData[regData$index %in% idxROA,]
  robDataROA$index = factor(robDataROA$index)
  robDataROA$year  = factor(robDataROA$year)
  
  # Regressions
  # POLS
  polsROAplain = reg(robDataROA, 'ROA', bankControls, dynamic = TRUE)
  polsROA      = reg(robDataROA, 'ROA', bankControls, complexity, 
                     complexityInteract)
  polsROAdyn   = reg(robDataROA, 'ROA', bankControls, complexity, 
                     complexityInteract, dynamic = TRUE)
  
  # Time Fixed Effects
  feTimeROA    = reg(robDataROA, 'ROA', bankControls, complexityInteract, 
                     time = TRUE)
  feTimeROAdyn = reg(robDataROA, 'ROA', bankControls, complexityInteract,
                     time = TRUE, dynamic = TRUE)
  
  # Bank Fixed Effects
  feBankROA    = reg(robDataROA, 'ROA', bankControls, complexity, 
                     complexityInteract, bank = TRUE)
  feBankROAdyn = reg(robDataROA, 'ROA', bankControls, complexity, 
                     complexityInteract, bank = TRUE, dynamic = TRUE)
  
  # Bank Time Fixed Effects
  feBankTimeROA    = reg(robDataROA, 'ROA', bankControls, complexityInteract, 
                         time = TRUE, bank = TRUE)
  feBankTimeROAdyn = reg(robDataROA, 'ROA', bankControls, complexityInteract,
                         time = TRUE, bank = TRUE, dynamic = TRUE)
  
  # latex output for regressions of interest
  i    = 11
  comp = c('meanWMD', 'meanWMD * Size$_{t-1}$')
  latexOutputROA(i, comp)
  
  i    = 1
  comp = c('iqrAverage', 'iqrAverage * Size$_{t-1}$')
  latexOutputROA(i, comp)
  
  # descriptives for economic effects
  nas     = as.vector(polsROA[[11]]$na.action)
  ROAdata = robDataROA[-nas,]
  descriptives(ROAdata, c('wmd_means_avg', 'average_iqrs_avg'))
}