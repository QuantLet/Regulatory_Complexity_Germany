################################################################################

# Functions for Regulatory_Complexity_Regressions.R

# 1. generate independent variables
# 2. regression function
# 3. test for fixed effects
# 4.test for heteroscedasticity
# 5. print test outputs
# 6. descriptives needed to compute economic effects
# 7. compute root mean squared error
# 8. generate fixed effects
# 9. print regression output in console
# 10. latex code for regression output
# 11. plots for residual analysis

################################################################################

# 1. generate independent variables
independent = function(bankControls, ...){
  bankString = paste(bankControls, collapse = '+')
  return(paste(..., bankString, sep = '+'))
}

# 2. regression function
reg = function(data, dep, bankControls, ..., dynamic = FALSE, time = FALSE, bank = FALSE){
  
  indep = independent(bankControls, ...)
  
  if (dynamic == TRUE){
    indep = paste(paste0(dep, '_lag1'), indep, sep = '+')
  }
  if (time == TRUE){
    indep = paste(indep, 'factor(year)', sep = '+')
  }
  if (bank == TRUE){
    indep = paste(indep, 'factor(index)', sep = '+')
  }
  models = lapply(paste(dep, indep, sep = "~"), formula)
  regModels = lapply(models,
                      FUN = function(x) {lm(formula = x, data = data)})
  names(regModels) = paste(dep, indep, sep = "~")
  return(regModels)
}

# 3. test for fixed effects
testFE = function(model1, model2){
  results = list()
  for (i in 1:length(model1)){
    test = anova(model1[[i]], model2[[i]])
    results[[i]] = test
  }
  return(results)
}

# 4.test for heteroscedasticity
testHeterosc = function(allModels){
  testHet = list()
  for (i in 1:length(allModels)){
    testHet[[i]] = lapply(allModels[[i]], bptest)
  }
  return(testHet)
}

# 5. print test outputs
printTest = function(tests){
  for (test in tests) {
    print(test)
  }
}

# 6. descriptives needed to compute economic effects
descriptives = function(data, complexity){
  stargazer(data[c('ROA', 'ROA_lag1', 'Size_lag1', 'EquityRatio_lag1', 
                   'Liquidity_lag1', 'Funding_lag1', 'Risk_lag1', 
                   'BusinessModel_lag1', 'LoansToBanksLT',
                   'LoansToBanksLT_lag1', 'LoansToCustomersLT',
                   'LoansToCustomersLT_lag1', 'LoansToBanksST_lag1',
                   'LoansToCustomersST_lag1', 'TotalAssets')],
            type = 'text',
            covariate.labels = c('ROA', 'ROA$_{t-1}$', 'Size$_{t-1}$',
                                 'Equity Ratio$_{t-1}$', 'Liquidity$_{t-1}$',
                                 'Funding$_{t-1}$', 'Risk$_{t-1}$',
                                 'Business Model$_{t-1}$',
                                 'Loans to Banks LT',
                                 'Loans to Banks LT$_{t-1}$',
                                 'Loans to Customers LT',
                                 'Loans to Customers LT$_{t-1}$',
                                 'Loans to Banks ST$_{t-1}$',
                                 'Loans to Customers ST$_{t-1}$',
                                 'Total Assets'),
            digits = 3,
            digits.extra = 0,
            align = TRUE,
            min.max = FALSE)
  for (c in complexity){
    print(c)
    print(length(unique(data[[c]])))
    print(mean(unique(data[[c]])))
    print(sd(unique(data[[c]])))
  }
  
}

# 7. compute root mean squared error
rmse = function(error){
  sqrt(mean(error^2))
}

# 8. generate fixed effects
effects = function(model){
  time = length(model$xlevels$`factor(year)`)
  bank = length(model$xlevels$`factor(index)`)
  return(time + bank)
}

# 9. print regression output in console
printOutput = function(model){
  cov = lapply(model, vcovHC, type='HC1', cluster='group')
  robustSE = lapply(lapply(cov, diag), sqrt)
  stargazer(model, 
            type='text', 
            se=robustSE,
            omit = '^factor')
}

# 10. latex code for regression output
latexOutputROA = function(i, comp, type='latex'){
  # ROA
  models = c(polsROAplain, polsROA[i], polsROAdyn[i], feTimeROA[i],
              feTimeROAdyn[i], feBankROA[i], feBankROAdyn[i], feBankTimeROA[i],
              feBankTimeROAdyn[i])
  cov = lapply(models, vcovHC, type='HC1', cluster='group')
  robustSE = lapply(lapply(cov, diag), sqrt)
  rmseROA = lapply(lapply(models, residuals), rmse)
  effectsROA = lapply(models, effects)
  stargazer(models,
            type = type,
            se = robustSE,
            digits = 3,
            digits.extra = 0,
            no.space = TRUE,
            df = FALSE,
            align = TRUE,
            omit.stat = "ser",
            title = "Hypothesis 1 - regression results",
            model.names = FALSE,
            column.labels   = c("Pooled OLS", "Fixed Effects"),
            column.separate = c(3, 6),
            omit = '^factor',
            order = c('avg$', 'avg:Size_lag1$',
                      'ROA_lag1', 'Size_lag1', 'EquityRatio_lag1',
                      'Liquidity_lag1', 'Funding_lag1',
                      'Risk_lag1', 'BusinessModel_lag1', 'Constant'),
            covariate.labels = c(comp,
                                 'ROA$_{t-1}$', 'Size$_{t-1}$',
                                 'Equity Ratio$_{t-1}$', 'Liquidity$_{t-1}$',
                                 'Funding$_{t-1}$', 'Risk$_{t-1}$',
                                 'Business Model$_{t-1}$','Constant'
            ),
            dep.var.labels = 'ROA',
            add.lines = list(c('Time FE', 'no', 'no', 'no',' yes', 'yes', 'no', 'no', 'yes', 'yes'),
                             c('Bank FE', 'no', 'no', 'no', 'no', 'no', 'yes', 'yes', 'yes', 'yes'),
                             c('No. of FE', as.character(format(effectsROA))),
                             c('RMSE', as.character(format(rmseROA,
                                                           digits = 1,
                                                           nsmall = 3))))
  )
}
  
latexOutputCustomers = function(i, comp, type='latex'){
  # Loans Customers
  models = c(polsLoan1plain, polsLoan1[i], polsLoan1dyn[i], feTimeLoan1[i],
              feTimeLoan1dyn[i], feBankLoan1[i], feBankLoan1dyn[i], feBankTimeLoan1[i],
              feBankTimeLoan1dyn[i])
  cov = lapply(models, vcovHC, type='HC1', cluster='group')
  robustSE = lapply(lapply(cov, diag), sqrt)
  rmseLoan1 = lapply(lapply(models, residuals), rmse)
  effectsLoan1 = lapply(models, effects)
  stargazer(models,
            type = type,
            se = robustSE,
            digits = 3,
            digits.extra = 0,
            no.space = TRUE,
            df = FALSE,
            align = TRUE,
            omit.stat = "ser",
            title = "Hypothesis 2a - regression results",
            model.names = FALSE,
            column.labels   = c("Pooled OLS", "Fixed Effects"),
            column.separate = c(3, 6),
            omit = '^factor',
            order = c('avg$', 'avg:Size_lag1$',
                      'LoansToCustomersLT_lag1', 'LoansToBanksLT_lag1',
                      'LoansToCustomersST_lag1', 'LoansToBanksST_lag1',
                      'Size_lag1', 'EquityRatio_lag1',
                      'Liquidity_lag1', 'Funding_lag1',
                      'Risk_lag1', 'Constant'),
            covariate.labels = c(comp,
                                 'Loans to Customers LT$_{t-1}$',
                                 'Loans to Banks LT$_{t-1}$',
                                 'Loans to Customers ST$_{t-1}$',
                                 'Loans to Banks ST$_{t-1}$',
                                 'Size$_{t-1}$',
                                 'Equity Ratio$_{t-1}$', 'Liquidity$_{t-1}$',
                                 'Funding$_{t-1}$', 'Risk$_{t-1}$','Constant'
            ),
            dep.var.labels = 'Loans to Customers LT',
            add.lines = list(c('Time FE', 'no', 'no', 'no',' yes', 'yes', 'no', 'no', 'yes', 'yes'),
                             c('Bank FE', 'no', 'no', 'no', 'no', 'no', 'yes', 'yes', 'yes', 'yes'),
                             c('No. of FE', as.character(format(effectsLoan1))),
                             c('RMSE', as.character(format(rmseLoan1,
                                                           digits = 1,
                                                           nsmall = 3))))
  )
}

latexOutputBanks = function(i, comp, type='latex'){
  # Loans Banks
  models = c(polsLoan2plain, polsLoan2[i], polsLoan2dyn[i], feTimeLoan2[i],
              feTimeLoan2dyn[i], feBankLoan2[i], feBankLoan2dyn[i], feBankTimeLoan2[i],
              feBankTimeLoan2dyn[i])
  cov = lapply(models, vcovHC, type='HC1', cluster='group')
  robustSE = lapply(lapply(cov, diag), sqrt)
  rmseLoan2 = lapply(lapply(models, residuals), rmse)
  effectsLoan2 = lapply(models, effects)
  stargazer(models,
            type = type,
            se = robustSE,
            digits = 3,
            digits.extra = 0,
            no.space = TRUE,
            df = FALSE,
            align = TRUE,
            omit.stat = "ser",
            title = "Hypothesis 2b - regression results",
            model.names = FALSE,
            column.labels   = c("Pooled OLS", "Fixed Effects"),
            column.separate = c(3, 6),
            omit = '^factor',
            order = c('avg$', 'avg:Size_lag1$',
                      'LoansToBanksLT_lag1', 'LoansToCustomersLT_lag1',
                      'LoansToBanksST_lag1', 'LoansToCustomersST_lag1',
                      'Size_lag1', 'EquityRatio_lag1',
                      'Liquidity_lag1', 'Funding_lag1',
                      'Risk_lag1', 'Constant'),
            covariate.labels = c(comp,
                                 'Loans to Banks LT$_{t-1}$',
                                 'Loans to Customers LT$_{t-1}$',
                                 'Loans to Banks ST$_{t-1}$',
                                 'Loans to Customers ST$_{t-1}$',
                                 'Size$_{t-1}$',
                                 'Equity Ratio$_{t-1}$', 'Liquidity$_{t-1}$',
                                 'Funding$_{t-1}$', 'Risk$_{t-1}$','Constant'
            ),
            dep.var.labels = 'Loans to Banks LT',
            add.lines = list(c('Time FE', 'no', 'no', 'no',' yes', 'yes', 'no', 'no', 'yes', 'yes'),
                             c('Bank FE', 'no', 'no', 'no', 'no', 'no', 'yes', 'yes', 'yes', 'yes'),
                             c('No. of FE', as.character(format(effectsLoan2))),
                             c('RMSE', as.character(format(rmseLoan2,
                                                           digits = 1,
                                                           nsmall = 3))))
  )
}

# 11. plots for residual analysis
residualPlots = function(models, ylim.a, xlim.b, ylim.b){
  plots = list()
  c = 0
  d = 1
  for (model in models){
    if ('fitted.values' %in% names(model)){
      residualData = data.frame(list(model$residuals, model$fitted.values))
    }
    else{
      residualData = data.frame(list(model$residuals, 
                                      model$model[[1]]-model$residuals))
    }
    colnames(residualData) = c('residuals', 'fittedValues')
    q= qqnorm(residualData$fittedValues, plot = FALSE)
    residualData['quantiles'] = q$x
    
    c = c + 1
    plots[[c]] = ggplot(data = residualData, 
                         aes(x = quantiles, y = fittedValues)) +
      geom_smooth(method = "lm", se = FALSE) +
      geom_point() +
      ylim(ylim.a) +
      xlab("Theoretical Quantiles") +
      ylab("Sample Quantiles") + 
      ggtitle(paste0('(', d, ')')) +
      theme_bw() + 
      theme(panel.border = element_blank(),
            text = element_text(size=10))
    d = d + 1
    
    c = c + 1
    plots[[c]] = ggplot(data = residualData, 
                         aes(x = fittedValues, y = residuals)) +
      geom_point() + 
      xlim(xlim.b) +
      ylim(ylim.b) +
      xlab("Fitted Values") +
      ylab("Residuals") + 
      ggtitle(' ') +
      theme_bw() + 
      theme(panel.border = element_blank(),
            text = element_text(size=10))
  }
  marrangeGrob(plots, nrow = 5, ncol = 4,
               layout_matrix = rbind(c(NA,1,2,NA),
                                     c(3,4,5,6),
                                     c(7,8,9,10),
                                     c(11,12,13,14),
                                     c(15,16,17,18)),
               top = NULL)
}