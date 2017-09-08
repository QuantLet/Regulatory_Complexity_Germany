################################################################################

# Regressions

# input: - regressiondata.csv: sample data and yearly aggregates of complexity
# output: - folder 'output' which contains regression outputs and test outputs
#         - latex code for regression tables
#         - figures to compute economic effects
#         - residual plots

# 1. Hypothesis 1 Regressions
# 2. Hypothesis 2 Regressions
#  2.1 Hypothesis 2a
#  2.2 Hypothesis 2b
# 3. Output Results
# 4. Print Latex Tables
# 5. Economic Effects
# 6. Residual Analysis

################################################################################

# imports

library(dplyr)
library(stargazer)
library(lmtest)
library(sandwich)
library(ggplot2)
library(gridExtra)

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

# create output directory
dir.create(file.path(getwd(), 'Regulatory_Complexity_Regressions', 'output'), 
           showWarnings = FALSE)
outputPath = file.path(getwd(), 'Regulatory_Complexity_Regressions', 'output')

### 1. Hypothesis 1 Regressions

# Regression Variables
bankControls       = c('Size_lag1', 'EquityRatio_lag1', 'Liquidity_lag1',
                       'Funding_lag1', 'Risk_lag1', 'BusinessModel_lag1')
complexity         = colnames(regData)[grep(pattern = 'avg$',
                                            colnames(regData))]
complexityInteract = paste(complexity, 'Size_lag1', sep = ':')

# POLS
polsROAplain  = reg(regData, 'ROA', bankControls, dynamic = TRUE)
polsROA       = reg(regData, 'ROA', bankControls, complexity, complexityInteract)
polsROAint    = reg(regData, 'ROA', bankControls, complexityInteract)
polsROAdyn    = reg(regData, 'ROA', bankControls, complexity, complexityInteract,
                    dynamic = TRUE)
polsROAintdyn = reg(regData, 'ROA', bankControls, complexityInteract,
                     dynamic = TRUE)

# Time Fixed Effects
feTimeROA    = reg(regData, 'ROA', bankControls, complexityInteract, time = TRUE)
feTimeROAdyn = reg(regData, 'ROA', bankControls, complexityInteract,
                    time = TRUE, dynamic = TRUE)

# Bank Fixed Effects
feBankROA    = reg(regData, 'ROA', bankControls, complexity, complexityInteract, 
                 bank = TRUE)
feBankROAdyn = reg(regData, 'ROA', bankControls, complexity, 
                    complexityInteract, bank = TRUE, dynamic = TRUE)

# Bank Time Fixed Effects
feBankTimeROA    = reg(regData, 'ROA', bankControls, complexityInteract, 
                       time = TRUE, bank = TRUE)
feBankTimeROAdyn = reg(regData, 'ROA', bankControls, complexityInteract,
                        time = TRUE, bank = TRUE, dynamic = TRUE)

# test for fixed effects
testFeTimeROA    = testFE(polsROAint, feTimeROA)
testFeBankROA    = testFE(polsROA, feBankROA)
testFeTimeROAdyn = testFE(polsROAintdyn, feTimeROAdyn)
testFeBankROAdyn = testFE(polsROAdyn, feBankROAdyn)

# test for heteroscedasticity
modelsROA  = mget(ls(pattern="polsROA|fe.*ROA"))
testHetROA = testHeterosc(modelsROA)

### Hypothesis 2 Regressions

# Regression Variables
bankControlsLoan  = bankControls[-grep('BusinessModel', bankControls)]
bankControlsLoan1 = c(bankControlsLoan, 'LoansToBanksLT_lag1', 
                       'LoansToBanksST_lag1', 'LoansToCustomersST_lag1')
bankControlsLoan2 = c(bankControlsLoan, 'LoansToCustomersLT_lag1', 
                       'LoansToBanksST_lag1', 'LoansToCustomersST_lag1')

### 2.1 Hypothesis 2a: Customers

# POLS
polsLoan1plain  = reg(regData, 'LoansToCustomersLT', bankControlsLoan1, 
                      dynamic = TRUE)
polsLoan1       = reg(regData, 'LoansToCustomersLT', bankControlsLoan1, 
                      complexity, complexityInteract)
polsLoan1int    = reg(regData, 'LoansToCustomersLT', bankControlsLoan1,
                      complexityInteract)
polsLoan1dyn    = reg(regData, 'LoansToCustomersLT', bankControlsLoan1, 
                      complexity, complexityInteract, dynamic = TRUE)
polsLoan1intdyn = reg(regData, 'LoansToCustomersLT', bankControlsLoan1,
                      complexityInteract, dynamic = TRUE)

# Time Fixed Effects
feTimeLoan1    = reg(regData, 'LoansToCustomersLT', bankControlsLoan1, 
                     complexityInteract, time = TRUE)
feTimeLoan1dyn = reg(regData, 'LoansToCustomersLT', bankControlsLoan1, 
                     complexityInteract, time = TRUE, dynamic = TRUE)

# Bank Fixed Effects
feBankLoan1    = reg(regData, 'LoansToCustomersLT', bankControlsLoan1, 
                     complexity, complexityInteract, bank = TRUE)
feBankLoan1dyn = reg(regData, 'LoansToCustomersLT', bankControlsLoan1, 
                      complexity, complexityInteract, bank = TRUE, dynamic = TRUE)

# Bank Time Fixed Effects
feBankTimeLoan1    = reg(regData, 'LoansToCustomersLT', bankControlsLoan1, 
                         complexityInteract, time = TRUE, bank = TRUE)
feBankTimeLoan1dyn = reg(regData, 'LoansToCustomersLT', bankControlsLoan1, 
                          complexityInteract, time = TRUE, bank = TRUE, 
                          dynamic = TRUE)

# test for fixed effects
testFeTimeLoan1    = testFE(polsLoan1int, feTimeLoan1)
testFeBankLoan1    = testFE(polsLoan1, feBankLoan1)
testFeTimeLoan1dyn = testFE(polsLoan1intdyn, feTimeLoan1dyn)
testFeBankLoan1dyn = testFE(polsLoan1dyn, feBankLoan1dyn)

# test for heteroscedasticity
modelsLoan1  = mget(ls(pattern="polsLoan1|fe.*Loan1"))
testHetLoan1 = testHeterosc(modelsLoan1)

### 2.2 Hypothesis 2b: Banks

# POLS
polsLoan2plain  = reg(regData, 'LoansToBanksLT', bankControlsLoan2, 
                      dynamic = TRUE)
polsLoan2       = reg(regData, 'LoansToBanksLT', bankControlsLoan2, complexity, 
                      complexityInteract)
polsLoan2int    = reg(regData, 'LoansToBanksLT', bankControlsLoan2, 
                      complexityInteract)
polsLoan2dyn    = reg(regData, 'LoansToBanksLT', bankControlsLoan2, complexity, 
                      complexityInteract, dynamic = TRUE)
polsLoan2intdyn = reg(regData, 'LoansToBanksLT', bankControlsLoan2, 
                      complexityInteract, dynamic = TRUE)

# Time Fixed Effects
feTimeLoan2    = reg(regData, 'LoansToBanksLT', bankControlsLoan2, 
                     complexityInteract, time = TRUE)
feTimeLoan2dyn = reg(regData, 'LoansToBanksLT', bankControlsLoan2, 
                     complexityInteract, time = TRUE, dynamic = TRUE)

# Bank Fixed Effects
feBankLoan2 = reg(regData, 'LoansToBanksLT', bankControlsLoan2, 
                   complexity, complexityInteract, bank = TRUE)
feBankLoan2dyn = reg(regData, 'LoansToBanksLT', bankControlsLoan2, 
                      complexity, complexityInteract, bank = TRUE, dynamic = TRUE)

# Bank Time Fixed Effects
feBankTimeLoan2    = reg(regData, 'LoansToBanksLT', bankControlsLoan2, 
                         complexityInteract, time = TRUE, bank = TRUE)
feBankTimeLoan2dyn = reg(regData, 'LoansToBanksLT', bankControlsLoan2, 
                         complexityInteract, time = TRUE, bank = TRUE, 
                         dynamic = TRUE)

# test for fixed effects
testFeTimeLoan2    = testFE(polsLoan2int, feTimeLoan2)
testFeBankLoan2    = testFE(polsLoan2, feBankLoan2)
testFeTimeLoan2dyn = testFE(polsLoan2intdyn, feTimeLoan2dyn)
testFeBankLoan2dyn = testFE(polsLoan2dyn, feBankLoan2dyn)

# test for heteroscedasticity
modelsLoan2  = mget(ls(pattern="polsLoan2|fe.*Loan2"))
testHetLoan2 = testHeterosc(modelsLoan2)


### 3. Output Results

modelNames = c('POLS', 'Dynamic POLS', 'Time FE', 'Dynamic Time FE', 'Bank FE',
                'Dynamic Bank FE', 'Bank Time FE', 'Dynamic Bank Time FE')
regsROA    = list(polsROA, polsROAdyn, feTimeROA, feTimeROAdyn, feBankROA,
                  feBankROAdyn, feBankTimeROA, feBankTimeROAdyn)
regsLoan1  = list(polsLoan1, polsLoan1dyn, feTimeLoan1, feTimeLoan1dyn, 
                  feBankLoan1, feBankLoan1dyn, feBankTimeLoan1, feBankTimeLoan1dyn)
regsLoan2  = list(polsLoan2, polsLoan2dyn, feTimeLoan2, feTimeLoan2dyn, 
                  feBankLoan2, feBankLoan2dyn, feBankTimeLoan2, feBankTimeLoan2dyn)


sink(file.path(outputPath, 'H1.txt'))
for (i in c(1:length(regsROA))){
  print('##############################################################################')
  print(modelNames[i])
  print('##############################################################################')
  printOutput(regsROA[[i]])
}
sink()

sink(file.path(outputPath, 'H2a_Customers.txt'))
for (i in c(1:length(regsLoan1))){
  print('##############################################################################')
  print(modelNames[i])
  print('##############################################################################')
  printOutput(regsLoan1[[i]])
}
sink()

sink(file.path(outputPath, 'H2b_Banks.txt'))
for (i in c(1:length(regsLoan2))){
  print('##############################################################################')
  print(modelNames[i])
  print('##############################################################################')
  printOutput(regsLoan2[[i]])
}
sink()


# print Tests for fixed effects
feTests = mget(ls(pattern="testFe"))
sink(file.path(outputPath, 'fe_tests.txt'))
for (tests in feTests){
  printTest(tests)
}
sink()

# print Tests for Heteroscedasticity
hetTests = mget(ls(pattern="testHet[A-Z]"))
sink(file.path(outputPath, 'het_tests.txt'))
for (tests in hetTests){
  printTest(tests)
}
sink()

### 4. Print Latex Tables

i    = 11
comp = c('meanWMD', 'meanWMD * Size$_{t-1}$')
latexOutputROA(i, comp)
latexOutputCustomers(i, comp)
latexOutputBanks(i, comp)

i    = 1
comp = c('iqrAverage', 'iqrAverage * Size$_{t-1}$')
latexOutputROA(i, comp)
latexOutputCustomers(i, comp)
latexOutputBanks(i, comp)

### 5. Economic Effects  

nas       = as.vector(polsROA[[11]]$na.action)
ROAdata   = regData[-nas,]
nas       = as.vector(polsLoan1[[11]]$na.action)
Loan1data = regData[-nas,]
nas       = as.vector(polsLoan2[[11]]$na.action)
Loan2data = regData[-nas,]

descriptives(ROAdata, c('wmd_means_avg', 'average_iqrs_avg'))

### 6. Residual Analysis

i      = 11
models = c(polsROAplain, polsROA[i], polsROAdyn[i], feTimeROA[i],
            feTimeROAdyn[i], feBankROA[i], feBankROAdyn[i],
            feBankTimeROA[i], feBankTimeROAdyn[i])

residualPlots(models, c(-0.05, 0.1), c(-0.05, 0.1), c(-0.05, 0.1))

i      = 1
models = c(polsROAplain, polsROA[i], polsROAdyn[i], feTimeROA[i],
            feTimeROAdyn[i], feBankROA[i], feBankROAdyn[i],
            feBankTimeROA[i], feBankTimeROAdyn[i])

residualPlots(models, c(-0.05, 0.1), c(-0.05, 0.1), c(-0.05, 0.1))

