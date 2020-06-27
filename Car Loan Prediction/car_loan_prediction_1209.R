library(tidyverse)
library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)
car_loan <- read_csv("D:/Master/MSBA/Courses/2019 Fall/Predictive modeling/Final project/car_loan.csv")

library(haven)
car_loan_cd <- read_sas("D:/Master/MSBA/Courses/2019 Fall/Predictive modeling/Topic 4.5 Parameter Tuning/car_loan_v2.sas7bdat")

library(xgboost)
library(caret)
library(car)
library(Matrix)
car_loan_cd$Risk1 <- as.character(car_loan_cd$Risk1)
car_loan_cd$geo <- as.character(car_loan_cd$geo)
car_loan_cd$log_PERFORM_CNS_SCORE <- log(car_loan_cd$PERFORM_CNS_SCORE)
car_loan_cd$log_PERFORM_CNS_SCORE <- ifelse(is.infinite(car_loan_cd$log_PERFORM_CNS_SCORE), 0, car_loan_cd$log_PERFORM_CNS_SCORE)
car_loan_cd$log_PRI_SANCTIONED_AMOUNT <- log(car_loan_cd$PRI_SANCTIONED_AMOUNT)
car_loan_cd$log_PRI_SANCTIONED_AMOUNT <- ifelse(is.infinite(car_loan_cd$log_PRI_SANCTIONED_AMOUNT), 0, car_loan_cd$log_PRI_SANCTIONED_AMOUNT)
car_loan_cd$log_disbursed_amount <- log(car_loan_cd$disbursed_amount)
car_loan_cd$log_disbursed_amount <- ifelse(is.infinite(car_loan_cd$log_disbursed_amount), 0, car_loan_cd$log_disbursed_amount)
car_loan_cd$log_PRI_DISBURSED_AMOUNT <- log(car_loan_cd$PRI_DISBURSED_AMOUNT)
car_loan_cd$log_PRI_DISBURSED_AMOUNT <- ifelse(is.infinite(car_loan_cd$log_PRI_DISBURSED_AMOUNT), 0, car_loan_cd$log_PRI_DISBURSED_AMOUNT)

car_loan_cd$PRI_OVERDUE_PRI_NO_OF <- ifelse(is.na(car_loan_cd$PRI_OVERDUE_PRI_NO_OF), 0, car_loan_cd$PRI_OVERDUE_PRI_NO_OF)
car_loan_cd$PRI_ACTIVE_PRI_NO_OF <- ifelse(is.na(car_loan_cd$PRI_ACTIVE_PRI_NO_OF), 0, car_loan_cd$PRI_ACTIVE_PRI_NO_OF)
car_loan_cd$PRI_SANCTIONED_PRI_NO_OF <- ifelse(is.na(car_loan_cd$PRI_SANCTIONED_PRI_NO_OF), 0, car_loan_cd$PRI_SANCTIONED_PRI_NO_OF)
car_loan_cd$CREDIT_HISTORY_PRI_NO_OF <- ifelse(is.na(car_loan_cd$CREDIT_HISTORY_PRI_NO_OF), 0, car_loan_cd$CREDIT_HISTORY_PRI_NO_OF)
car_loan_cd$CHISTORY_PRI_NO_PRI_6 <- ifelse(is.na(car_loan_cd$CHISTORY_PRI_NO_PRI_6), 0, car_loan_cd$CHISTORY_PRI_NO_PRI_6)

car_loan_cd <- car_loan_cd[,-c(4,5,6,7,9,10,18)]

car_loan_cdm <- as.data.frame(model.matrix(~.-1, car_loan_cd))

car_loan_cdm <- car_loan_cdm[,-c(1,13,18,19)]

train_sub = sample(nrow(car_loan_cdm),7/10*nrow(car_loan_cdm))
train_data = car_loan_cdm[train_sub,]
test_data = car_loan_cdm[-train_sub,]

cv_tot <- xgb.cv(data = data.matrix(car_loan_cdm[,c(-27)]), 
              label = car_loan_cdm$loan_default,
              eta = 0.24,
              max_depth = 6, 
              nround=30, 
              subsample = 0.8,
              colsample_bytree = 0.8,
              min_child_weight = 1,
              seed = 1,
              objective = "binary:logistic",
              nthread = 3,
              nfold = 5)
print(cv_tot, verbose=TRUE)

xgb_tot <- xgboost(data = data.matrix(car_loan_cdm[,c(-27)]), 
                label = car_loan_cdm$loan_default, 
                eta = 0.1,
                max_depth = 7, 
                nround=25, 
                subsample = 0.6,
                colsample_bytree = 0.6,
                min_child_weight = 1,
                seed = 1,
                objective = "binary:logistic",
                nthread = 3,
                nfold = 4)
xgb.importance(model = xgb_tot)

test_data2 <- test_data %>% mutate(pred = round(predict(xgb2, data.matrix(test_data)),0))

pred = round(predict(xgb_tot, data.matrix(test_data)))
table(test_data$loan_default,pred, dnn=c("raw", "pred"))

######

car_loan_cdm1 <- filter(car_loan_cdm, geo2 == 1)
cv_tot <- xgb.cv(data = data.matrix(car_loan_cdm1[,c(-27)]), 
                 label = car_loan_cdm1$loan_default,
                 eta = 0.1,
                 max_depth = 5, 
                 nround=40, 
                 subsample = 0.8,
                 colsample_bytree = 0.6,
                 min_child_weight = 1,
                 seed = 1,
                 objective = "binary:logistic",
                 nthread = 3,
                 nfold = 5)
print(cv_tot, verbose=TRUE)

car_loan_cdm3 <- filter(car_loan_cdm, geo3 == 1)
cv_tot <- xgb.cv(data = data.matrix(car_loan_cdm3[,c(-27)]), 
                 label = car_loan_cdm3$loan_default,
                 eta = 0.1,
                 max_depth = 6, 
                 nround=40, 
                 subsample = 0.8,
                 colsample_bytree = 0.6,
                 min_child_weight = 1,
                 seed = 1,
                 objective = "binary:logistic",
                 nthread = 3,
                 nfold = 5)
print(cv_tot, verbose=TRUE)

car_loan_cdm4 <- filter(car_loan_cdm, geo4 == 1)
cv_tot <- xgb.cv(data = data.matrix(car_loan_cdm4[,c(-27)]), 
                 label = car_loan_cdm4$loan_default,
                 eta = 0.1,
                 max_depth = 6, 
                 nround=40, 
                 subsample = 0.6,
                 colsample_bytree = 0.6,
                 min_child_weight = 1,
                 seed = 1,
                 objective = "binary:logistic",
                 nthread = 3,
                 nfold = 5)
print(cv_tot, verbose=TRUE)

car_loan_cdm5 <- filter(car_loan_cdm, geo5 == 1)
cv_tot <- xgb.cv(data = data.matrix(car_loan_cdm5[,c(-27)]), 
                 label = car_loan_cdm5$loan_default,
                 eta = 0.2,
                 max_depth = 4, 
                 nround=40, 
                 subsample = 0.6,
                 colsample_bytree = 0.6,
                 min_child_weight = 1,
                 seed = 1,
                 objective = "binary:logistic",
                 nthread = 3,
                 nfold = 5)
print(cv_tot, verbose=TRUE)