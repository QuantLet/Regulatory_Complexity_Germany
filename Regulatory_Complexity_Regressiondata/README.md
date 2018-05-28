[<img src="https://github.com/QuantLet/Styleguide-and-FAQ/blob/master/pictures/banner.png" width="888" alt="Visit QuantNet">](http://quantlet.de/)

## [<img src="https://github.com/QuantLet/Styleguide-and-FAQ/blob/master/pictures/qloqo.png" alt="Visit QuantNet">](http://quantlet.de/) **Regulatory_Complexity_Regressiondata** [<img src="https://github.com/QuantLet/Styleguide-and-FAQ/blob/master/pictures/QN2.png" width="60" alt="Visit QuantNet 2.0">](http://quantlet.de/)

```yaml

Name of Quantlet : Regulatory_Complexity_Regressiondata
Published in : Measuring Regulatory Complexity and its Impact on the German Banking Sector
Description : Preprocesses sample data, complexity measures and text descriptive data to be included in regressions or when computing descriptives.
Keywords : Regulatory_Complexity, data, preprocessing, dataframe, dplyr
Author : Sabine Bertram
Input: '- sample data, located in /Regulatory_Complexity_Germany/Sample_Data
        - complexity data, located in /Regulatory_Complexity_Germany/Regulatory_Complexity_Distances/output
        - descriptive data, located in /Regulatory_Complexity_Germany/Regulatory_Complexity_Preprocessing'
Output: 'folder "data" with 2 csv files containing
       - regressiondata.csv: sample data and yearly aggregates of complexity
       - descriptivedata.csv: complexity and descriptive data'

```

### R Code
```r

################################################################################

# Regression data preparation

# input: - sample data, located in /Regulatory_Complexity_Germany/Sample_Data
#        - complexity data, located in 
#         /Regulatory_Complexity_Germany/Regulatory_Complexity_Distances/output
#        - descriptive data, located in 
#         /Regulatory_Complexity_Germany/Regulatory_Complexity_Preprocessing
# output: folder 'data' with 2 csv files containing
#        - regressiondata.csv: sample data and yearly aggregates of complexity
#        - descriptivedata.csv: complexity and descriptive data

# 1. load sample data and process it
# 2. load complexity data and process it
# 3. load descriptive data and process it
# 4. create regression data

################################################################################

# imports

library(readxl)
library(dplyr)

################################################################################

# main

# define data paths
dataPath       = file.path(getwd(), 'Sample_Data')
complexityPath = file.path(getwd(), 'Regulatory_Complexity_Distances', 'output')
countsPath     = file.path(getwd(), 'Regulatory_Complexity_Preprocessing')

# create output directory
dir.create(file.path(getwd(), 'Regulatory_Complexity_Regressiondata', 'data'), 
           showWarnings = FALSE)
outputPath = file.path(getwd(), 'Regulatory_Complexity_Regressiondata', 'data')

### 1. Sample Data

# load sample data into one dataframe
data = data.frame(read.csv(file.path(dataPath, 'sample.csv')))

# remove spaces in variable names
names          = colnames(data)
newNames       = sapply(names, gsub, pattern = '\\.', replacement = '')
colnames(data) = newNames
data['X']      = NULL
rm(names, newNames)

# rename variables with duplicate names
underscoreNames = grep('__', colnames(data))
for (i in underscoreNames){
  a = colnames(data[i])
  b = strsplit(a, '__')
  if (grepl('thUSD', b[[1]][1])){
    c = strsplit(b[[1]], 'thUSD')
    d = paste0(c[[1]][1],'_',c[[2]][1],'thUSD',c[[1]][2])
    colnames(data)[i] = d
  }
  else {
    c = strsplit(b[[1]], 'thEUR')
    d = paste0(c[[1]][1],'_',c[[2]][1],'thEUR',c[[1]][2])
    colnames(data)[i] = d
  }
}
rm(underscoreNames, a, b, c, d, i)

# extract USD data
dataUSD = as.data.frame(data[c(1, grep('USD', colnames(data)))])

# insert missing variables for reshaping
uniqueNames = unique(gsub(pattern = '\\d', replacement = '', colnames(dataUSD)))
years       = as.character(seq(1988, 2017))
allNames    = c(uniqueNames[1], as.vector(outer(uniqueNames[2:length(uniqueNames)], 
                                                 years, paste0)))
dataUSD[setdiff(allNames, names(dataUSD))] = NA
rm(uniqueNames, years, allNames)

# reshape dataframe to long format
dataUSDLong = reshape(dataUSD, varying = c(2:ncol(dataUSD)),
                            direction = 'long', idvar = 'Indexnumber', 
                            timevar = 'year', sep = 'thUSD')


### 2. Complexity data

# load complexity data
fileList   = list.files(path = complexityPath, pattern='*.txt')
complexity = read.table(file.path(complexityPath, fileList[1]), sep = ',', 
                         col.names = c('date', gsub(fileList[1], 
                                                    pattern = '.txt', 
                                                    replacement = '')))
for (filename in fileList[2:length(fileList)]){
  complexity = cbind(complexity,
                      read.table(
                        file.path(complexityPath, filename), 
                        sep = ',', 
                        col.names = c('date', gsub(filename, 
                                                   pattern = '.txt', 
                                                   replacement = ''))))
}
rm(fileList, filename)
complexity = complexity[, !duplicated(colnames(complexity))]

# construct year variable
complexity$year = factor(sapply(complexity$date, gsub, pattern = '-.*', 
                                 replacement = ''))
complexity$year[1] = 2006

# construct yearly data
complexityYearAvg = complexity %>% 
  group_by(year) %>% 
  summarize_if(is.numeric, mean) %>% 
  ungroup()

complexityYearEnd = complexity %>% 
  group_by(year) %>%
  slice(n()) %>%
  ungroup() %>%
  select(-date) %>% 
  select(year, everything())


### 3. Descriptive Data

nSents = read.table(file.path(countsPath, 'numSentences.txt'), sep = ',',
                    col.names = c('date', 'nSents'))
nWords = read.table(file.path(countsPath, 'numWords.txt'), sep = ',',
                    col.names = c('date', 'nWords'))

descriptiveData = inner_join(complexity, nSents, by = 'date')
descriptiveData = inner_join(descriptiveData, nWords, by = 'date')
levels(descriptiveData$date)[1] = '2006-11-01'
rm(nSents, nWords)

write.csv(descriptiveData, file.path(outputPath, 'descriptivedata.csv'))


### 4. Create regression dataset

dataset = dataUSDLong %>% 
  filter(year >= 2006)%>% 
  mutate(year = factor(year)) %>% 
  mutate(index = factor(Indexnumber)) %>% 
  mutate(ROA = NetIncome / TotalAssets) %>% 
  mutate(DerPerAssets = Derivativefinancialinstruments / TotalAssets) %>% 
  mutate(EquityRatio = Tier1capital / TotalAssets) %>% 
  mutate(Size = log(TotalAssets)) %>% 
  mutate(Liquidity = Liquidassets / TotalAssets) %>% 
  mutate(Funding = DepositsShorttermfunding / Totalliabilities) %>% 
  mutate(Risk = ImpairedNonPerformingLoans / TotalAssets) %>% 
  mutate(LoansToCustomersLT = Loanstocustomers5yearsornotspecified + 
           Loanstocustomers15Years) %>% 
  mutate(LoansToCustomersST = Loanstocustomers312Monthsor12monthsifnotspecified +
           Loanstocustomers3monthsorondemand) %>% 
  mutate(LoansToBanksLT = Loanstobanks5Yearsornotspecified + 
           Loanstobanks15Years) %>% 
  mutate(LoansToBanksST = Loanstobanks312Monthsor12monthsifnotspecified + 
           Loanstobanks3Monthsorondemand) %>% 
  mutate(LoansToCustomers = LoansToCustomersLT + LoansToCustomersST) %>% 
  mutate(BusinessModel = LoansToCustomers / TotalAssets) %>%
  mutate(LoansToCustomersLT = LoansToCustomersLT / TotalAssets) %>% 
  mutate(LoansToCustomersST = LoansToCustomersST / TotalAssets) %>% 
  mutate(LoansToBanksLT = LoansToBanksLT / TotalAssets) %>% 
  mutate(LoansToBanksST = LoansToBanksST / TotalAssets) %>% 
  select(c(year, index, ROA, DerPerAssets, EquityRatio, Size, Liquidity, 
           Funding, Risk, BusinessModel, LoansToBanksLT, LoansToBanksST, 
           LoansToCustomersLT, LoansToCustomersST, TotalAssets))

dataset = inner_join(dataset, complexityYearAvg, by = 'year')
dataset = inner_join(dataset, complexityYearEnd, by = 'year', 
                      suffix = c('_avg', '_end'))

# lagged variables
lagDataset = dataset %>% 
  group_by(index) %>% 
  mutate_if(is.numeric, funs(dplyr::lead), 1) %>% 
  ungroup()
dataset = inner_join(dataset, lagDataset, by = c('year', 'index'),
                      suffix = c('', '_lag1'))
rm(lagDataset)

write.csv(dataset, file.path(outputPath, 'regressiondata.csv'))

```

automatically created on 2018-05-28