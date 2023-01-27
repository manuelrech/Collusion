rm(list = ls())
gc()

if (!require(rstudioapi)) {
  install.packages("rstudioapi")
  library(rstudioapi)
}
if (!require(randomForest)) {
  install.packages("randomForest")
  library(randomForest)
}
if (!require(ROCR)) {
  install.packages("ROCR")
  library(ROCR)
}
if (!require(gbm)) {
  install.packages("gbm")
  library(gbm)
}
if (!require(changepoint)) {
  install.packages("changepoint")
  library(changepoint)
}
if (!require(caTools)) {
  install.packages("caTools")
  library(caTools)
}

# ######################################

ExperimentNumber = 2
numSessions = 250
numAgents = 2
numPrices = 2
numStates = numPrices^2

setwd('/Users/manuel/Desktop/Laurea/Tesi')
FolderName = paste0(getwd(), '/', ExperimentNumber, '/')

# ######################################
# Preparazione dei dati
# IDEA (ancora da esplorare): ridurre il numero di osservazioni negative nel campione
# introducendo qualche vincolo, per esempio:
# - il segno delle altre dQ alla data di crossing (dovrebbero essere tutte positive?)
# - le strategie alla data prima del crossing
# ######################################
CritIterCC_test_1 = read.csv(file = paste0(FolderName, 'data_test_1/CritIterCC_test_1.csv'),header = TRUE, sep = ";")
CritIterCC_test_2 = read.csv(file = paste0(FolderName, 'data_test_2/CritIterCC_test_2.csv'),header = TRUE, sep = ";")
CritIterCC_test_3 = read.csv(file = paste0(FolderName, 'data_test_3/CritIterCC_test_3.csv'),header = TRUE, sep = ";")
CritIterCC_test_4 = read.csv(file = paste0(FolderName, 'data_test_4/CritIterCC_test_4.csv'),header = TRUE, sep = ";")
CritIterCC_train = read.csv(file = paste0(FolderName, 'data_train/CritIterCC_final.csv'),header = TRUE, sep = ";")
iterations_not_to_consider_train = c(371, 379, 541, 597, 628, 875)
iterations_not_to_consider_test_1 = c(170, 245)
iterations_not_to_consider_test_2 = c(94, 134, 136)
iterations_not_to_consider_test_3 = c(141, 180, 181, 208)
iterations_not_to_consider_test_4 = c(35, 86, 98, 101, 144, 215, 249)
#grid = seq(from = 100, to = 1100, by = 500) # grid = seq(from = 500, to = 1000, by = 100)
grid = c(100, 500, 1000, 5000, 8000, 30000, 50000)

numGrid = length(grid)
obs = setNames(data.frame(matrix(ncol = length(grid)*6+4, nrow = 0)), 
               c('session', 'agent', 't', 'y', 
               paste0('ml', grid, '_CC'), paste0('mu', grid, '_CC'), 
               paste0('ml', grid, '_DD'), paste0('mu', grid, '_DD'),
               paste0('ml', grid, '_DC'), paste0('mu', grid, '_DC')))

 
`%notin%` <- Negate(`%in%`)
for (iSession in 1:numSessions) {
    if (iSession %notin% iterations_not_to_consider_test_4) {
    
    FileName = paste0(FolderName, 'data_test_4/Q_', sprintf('%03d', iSession), '.Rdata')
    load(file = FileName)
    for (iAgent in 1:numAgents) {
      start.time <- Sys.time() # start timer to count running time
      cat('iSession = ', iSession, ', iAgent = ', iAgent, ', ')
      
      iD = (iAgent-1)*8+seq(from = 2, to = 8, by = 2)
      iC = (iAgent-1)*8+seq(from = 3, to = 9, by = 2)
      dQ = data[, iD]-data[, iC] # taking the difference between columns
  
      CC_column = dQ[, 4] # selecting the column for CC
      DD_column = dQ[, 1] ## # selecting the column for DD
      DC_column = dQ[, 2]
      CD_column = dQ[, 3]
      len_CC = length(CC_column)
      
      change_in_mean_DD = cpts(cpt.mean(DD_column[-(1:100000)]))
      change_in_meanvar_DD = cpts(cpt.meanvar(DD_column[-(1:100000)]))
      minimum_value_DD = which.min(DD_column[-(1:100000)])
      
      change_in_DD = max(change_in_mean_DD, change_in_meanvar_DD, minimum_value_DD) #### FORSE DA CAMBIARE CON cpt.mean(DD_column) -- FATTO -- prima usavo cpt.meanvar(DD_column)
      change_in_DD = change_in_DD + 100000 + 50000 # this is the cutoff point: the critical date is before this one. 
      # In case we can adjust for some difference (50000) for those agents that learn 2 times
      poss_critical = which(CC_column[1:(len_CC-1)] >= 0 & CC_column[2:len_CC] < 0 & CC_column[100:(len_CC+98)] < 0)+1 #### aggiungere condizioni sulla DD
      length(poss_critical)
      poss_critical = poss_critical[which(poss_critical < change_in_DD)]
      length(poss_critical)
      # this 'u' series contains all the indices of the 'z' series 
      ##### where the current index iteration is negative and the previous one is positive
      poss_critical = poss_critical[poss_critical < len_CC-150000] # risettiamo u
      # ha senso usare questo perche solo 3 hanno valori più grandi di 300000 mila e uno più di 350000
      len_poss_critical = length(poss_critical) 
      
      for (index_critical in 1:len_poss_critical) {
        row_list = list()
        potential_critical = poss_critical[index_critical] # osservazione per osservazione, stiamo iterando sulla lunghezza delle turning points
        
        row_list <- append(row_list, iSession)
        row_list <- append(row_list, iAgent)
        row_list <- append(row_list, potential_critical)
        row_list <- append(row_list, ifelse(potential_critical == CritIterCC_test_4[iSession, 1+iAgent], 1, 0))
        
        for (iState in c(4,1,2)) {
          column_of_interest = dQ[, iState]
          #print(iState)
          #print(head(column_of_interest))
          for (iGrid in 1:numGrid) {
            bwl = grid[iGrid]
            if (potential_critical < bwl) { #se l'indice del turning point è minore del valore di grid
              row_list <- append(row_list, NA)
              #obs[h, 4+iGrid] = NA # nella colonna del valore di grid metti 'NA'
            } else { #if potential_critical > bwl
              row_list <- append(row_list, mean(column_of_interest[(potential_critical-bwl):(potential_critical-1)]))
              #obs[h, 4+iGrid] = mean(DC_column[(potential_critical-bwl):(potential_critical-1)]) 
              # prendi tutte le osservazioni tra l'indice del turning meno bwl fino al turning point meno 1
              # sono tutte medie positive in teoria
            }
          }
          for (iGrid in 1:numGrid) {
            bwu = grid[iGrid]
            if (potential_critical > (len_CC-bwu)) { # se indice osservaizone è maggiore della differenza tra la lunghezza totale e valore di grid
              #can also see as if potential_critical + bwu is larger than T
              #obs[h, 4+numGrid+iGrid] = NA
              row_list <- append(row_list, NA)
            } else { # if potential_critical < T-bwu or equivalently potential_critical+bwu < T
              row_list <- append(row_list, mean(column_of_interest[potential_critical:(potential_critical+bwu-1)]))
              #obs[h, 4+numGrid+iGrid] = mean(DC_column[potential_critical:(potential_critical+bwu-1)]) # altrimenti mean
            }
          }
        }
        obs[nrow(obs)+1,] <- row_list
      } 
    end.time <- Sys.time()
    time.taken <- end.time - start.time
    cat('In time: ', time.taken, '\n')
    }
  }
}
 
obs_CC_DD_DC = obs
obs_CC_DD_DC$t = as.integer(obs_CC_DD_DC$t)
obs_CC_DD_DC$y = as.factor(obs_CC_DD_DC$y)
str(obs_CC_DD_DC)


# colnames(obs_DC) <- c("session", "agent", "t", "y", "ml100_DC", "ml600_DC", "ml1100_DC", "mu100_DC", "mu600_DC", "mu1100_DC")
# obs_CC_DD_DC <- cbind(obs_CC_DD_DC, obs_50000_30000$ml30000_CC, obs_50000_30000$ml50000_CC, obs_50000_30000$mu30000_CC, obs_50000_30000$mu50000_CC,
#                                      obs_50000_30000$ml30000_DD, obs_50000_30000$ml50000_DD, obs_50000_30000$mu30000_DD, obs_50000_30000$mu50000_DD,
#                                      obs_50000_30000$ml30000_DC, obs_50000_30000$ml50000_DC, obs_50000_30000$mu30000_DC, obs_50000_30000$mu50000_DC)
# colnames(obs_CC_DD_DC) <- c("session", "agent", "t", "y", "ml100_CC", "ml600_CC", "ml1100_CC", "mu100_CC", "mu600_CC", "mu1100_CC", 
#                                                           "ml100_DD", "ml600_DD", "ml1100_DD","mu100_DD", "mu600_DD", "mu1100_DD",
#                                                           "ml100_DC", "ml600_DC", "ml1100_DC", "mu100_DC", "mu600_DC", "mu1100_DC",
#                                                           "ml8000_CC", "mu8000_CC", "ml8000_DD", "mu8000_DD", "ml8000_DC", "mu8000_DC",
#                                                           "ml5000_CC", "mu5000_CC", "ml5000_DD", "mu5000_DD", "ml5000_DC", "mu5000_DC",
#                                                           "ml30000_CC", "ml50000_CC","mu30000_CC", "mu50000_CC",
#                                                           "ml30000_DD", "ml50000_DD","mu30000_DD", "mu50000_DD",
#                                                           "ml30000_DC", "ml50000_DC","mu30000_DC", "mu50000_DC")
save(obs_CC_DD_DC, file = paste0(FolderName, 'data_test_4/obs_CC_DD_DC_test_4.Rdata'))
obs = obs_CC_DD_DC

# ######################################
# Caricamento ed preprocessing dei dati
load(file = paste0(FolderName, 'data_test_4/obs_CC_DD_DC_test_4.Rdata'))
obs = obs_CC_DD_DC
obs = na.omit(obs)
dim(obs) 

########################################
# Controllare dove non abbiamo piu la y variable
library(dplyr)

check = obs %>% group_by(session) %>% summarise(somma_di_y = sum(as.numeric(y)-1))
check = check[which(check$somma_di_y != 2),]
check
save(check, file = paste0(FolderName, 'data_test_4/check.Rdata'))

# Numero di valori mancanti per variabile
plot(apply(X = is.na(obs), MARGIN = 2, FUN = sum))

# Numero di valori mancanti per osservazione
plot(apply(X = is.na(obs), MARGIN = 1, FUN = sum))

# Numero di osservazioni con almeno un valore mancante
sum(apply(X = is.na(obs), MARGIN = 1, FUN = sum) > 0)
# su un totale osservazioni di 
dim(obs)[1]

# Cancella righe con valore mancante
obs = na.omit(obs)
obs

####################################### SKIP, NOW YOU HAVE VALIDATION TESTS
## train/validation set
set.seed(100)
spl = sample.split(obs$y, SplitRatio = 0.5)
train_set = subset(obs, spl == TRUE)
validation_set = subset(obs, spl == FALSE)

# checking number of rows and column
# in training and testing dataset
dim(train_set)[1]
dim(validation_set)[1]/sum(as.numeric(validation_set$y)-1)

# ######################################
# Random Forest
load(file = paste0(FolderName, 'rf.obs.train.Rdata'))
set.seed(1)
rf.obs.train = randomForest(y ~ . - session - agent - t, 
                            data = obs, 
                            do.trace = TRUE, 
                            ntree = 500)

plot(rf.obs.train$err.rate[,1])
varImpPlot(rf.obs.train)

# phat = predict(rf.obs, type = "prob")[,2]
phat = predict(rf.obs.train, obs, type = "prob")[,2]
predob.rf = prediction(phat, obs$y)
perf = performance(predob.rf, "tpr", "fpr")
plot(perf, main = "Test set 1", colorize = TRUE, 
     print.cutoffs.at = seq(0, 0.8, by = 0.05), 
     text.adj = c(-0.4, 0.7))
as.numeric(performance(predob.rf, "auc")@y.values)

yhat = ifelse(phat > 0.09, 1, 0)
confusion_matrix = table(true = obs$y, predicted = yhat)
confusion_matrix
sum(diag(confusion_matrix)) / sum(confusion_matrix)
save(rf.obs.train, file = paste0(FolderName, 'rf.obs.train.Rdata'))

# ######################################
# GBM
# load(file = paste0(FolderName, 'gbm.Rdata'))
obs$y = as.numeric(obs$y)-1
set.seed'(1)'
cv.gbm.obs = gbm(y ~ . - session - agent - t, 
              data = train_set, 
              distribution = 'bernoulli', 
              n.trees = 1000, 
              shrinkage = 0.05, 
              cv.folds = 10,
              n.cores = 2,
              verbose = TRUE)

best.iter = gbm.perf(cv.gbm.obs, method = "cv")
best.iter

best.gbm.obs = gbm(y ~ . - session - agent - t, 
                   data = train_set, 
                   distribution = 'bernoulli', 
                   n.trees = best.iter, 
                   shrinkage = 0.05, 
                   verbose = TRUE)

phat.gbm = predict(best.gbm.obs, 
                   validation_set, 
                   n.trees = best.iter, 
                   type = "response")
predob = prediction(phat.gbm, validation_set$y)
perf = performance(predob, "tpr", "fpr")
plot(perf, main = "Boosting", colorize = TRUE, 
     print.cutoffs.at = seq(0, 0.8, by = 0.05), 
     text.adj = c(-0.4, 0.7))
as.numeric(performance(predob, "auc")@y.values)

yhat = ifelse(phat.gbm > 0.04, 1, 0)
print(table(true = obs$y, predicted = yhat))
print(mean(obs$y == yhat))

save(cv.gbm.obs, best.gbm.obs, file = paste0(FolderName, 'gbm.Rdata'))
