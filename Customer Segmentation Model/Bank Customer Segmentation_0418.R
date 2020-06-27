library(tidyverse)
library(dplyr)
library(tidyr)
library(stringr)
library(lubridate)
library(haven)
library(cluster)

trx <- read_sas("/deac/business/team20/trx_test.sas7bdat")
mcc <- read_sas("/deac/business/team20/mcc_v2.sas7bdat")

head(trx)

#clean flipped columns
unique(trx$MFX_2013DESC)
trx_1 = filter(trx, MFX_2013DESC == 'DEBIT CARD PURCHASE-PIN')
trx_2 = filter(trx, MFX_2013DESC != 'DEBIT CARD PURCHASE-PIN')
colnames(trx_1)
colnames(trx_1) = c("ACCT","EFF_FROM_DT","MFX_EDESC2","MFX_DDESC1","MFX_2013DESC","MFX_MCC_CODE","MFX_TRAMT")
trx_cd = rbind(trx_1, trx_2)

#date format
trx_cd$EFF_FROM_DT = as_date(trx_cd$EFF_FROM_DT)
d = as_date('2019-11-01')

#date is event happened time, city consider delete, state consider use, codes don't know
#states does not always means where the transaction happens
#some transactions do not have state info, some are online recurring pymt, not in the same place as the residence place

#group by account number
acct <- trx_cd %>%
  group_by(ACCT) %>%
  summarize(n = n(), amt = sum(MFX_TRAMT), recency=as.numeric(d-max(EFF_FROM_DT)))

summary(acct)

p1 <- ggplot(acct, aes(x=acct$n)) +
  geom_histogram(breaks=seq(0,2200,10))+theme_classic()
p1

p2 <- ggplot(acct, aes(x=acct$amt)) +
  geom_histogram(breaks=seq(0,380000,1000))+theme_classic()
p2

#transactions distribution
amtlabels = c("0-800", "801-1600", "1601-2400", "2400+")
amtcuttime=c(0,800,1600,2400,373700) 
acct$amtk <- cut(acct$amt, amtcuttime, amtlabels)

nlabels = c("1-15", "16-30", "31-45", "45+")
ncuttime = c(0,15,30,45,2166) 
acct$nk <- cut(acct$n, ncuttime, nlabels)

rlabels = c("1-7", "8-14", "15-21", "21+")
rcuttime = c(0,7,14,21,32) 
acct$rk <- cut(acct$recency, rcuttime, rlabels)

acct_tot = nrow(acct)

acct_amt <- acct %>%
  group_by(amtk) %>%
  summarize(count = n(), p = count/acct_tot)

acct_n <- acct %>%
  group_by(nk) %>%
  summarize(count = n(), p = count/acct_tot)

acct_r <- acct %>%
  group_by(rk) %>%
  summarize(count = n(), p = count/acct_tot)

acct_count <- acct %>%
  group_by(n) %>%
  summarize(d = n(), p = d/acct_tot)

write.csv(acct_amt, file = "/deac/business/team20/sy/acct_amt.csv")
write.csv(acct_n, file = "/deac/business/team20/sy/acct_n.csv")
write.csv(acct_r, file = "/deac/business/team20/sy/acct_r.csv")

#RFM analysis
acct <- acct %>%
  mutate(Renc = ifelse(recency < median(recency), 1,0),
         Freq = ifelse(n > median(n), 1,0),
         Mony = ifelse(amt > median(amt), 1,0),
         segment=paste(Renc, Freq, Mony, sep=","))

ggplot(acct, aes(x = segment, y = amt)) + geom_boxplot()

RFM <- acct %>%
  group_by(segment) %>%
  summarize(count=n(), n_p=count/acct_tot, 
            R_avg=mean(recency), F_avg=mean(n), M_avg=mean(amt),
            R_med=median(recency), F_med=median(n), M_med=median(amt),
            R_min=min(recency), F_min=min(n), M_min=min(amt),
            R_max=max(recency), F_max=max(n), M_max=max(amt))

ggplot(RFM, aes(x=segment, y=n_p)) + geom_bar(stat="identity", fill=rgb(29/256, 29/256, 100/256))+
  theme_classic()+ geom_text(label = paste(round(RFM$n_p*100), "%", sep=''), vjust=-0.6)+   
  labs(title = "RFM Segments", x="", y="")

write.csv(RFM, file = "/deac/business/team20/sy/rfm.csv")

#basic cluster
#set.seed(123)
#k.max <- 10
#data <- acct[,c("n","amt","recency")]
#wss <- sapply(1:k.max, function(k){kmeans(data, k, nstart=10, iter.max=10)$tot.withinss})
#wss
#p3 <- plot(1:k.max, wss, type="b", pch = 19, frame = FALSE, xlab="Number of clusters K", ylab="Total within-clusters sum of squares")


#4 clusters is a proper number of clusters currently
clustk <- kmeans(acct[,c("n","amt","recency")], centers=4, nstart = 10)
acct_k <- cbind(acct[,1:4], clustk$cluster)
acct_kg <- acct_k %>%
  group_by(clustk$cluster) %>%
  summarize(acct_n = n(), p = acct_n/acct_tot, tran = mean(n), amt = mean(amt), freq = mean(recency))

#scaled one is better, median summary table
clustk2 <- kmeans(scale(acct[,2:4]), centers=4, nstart = 10)
acct_k2 <- cbind(acct[,1:4], clustk2$cluster)
acct_kg2 <- acct_k2 %>%
  group_by(clustk2$cluster) %>%
  summarize(acct_n = n(), p = acct_n/acct_tot, r = median(recency), amt = median(amt), freq = median(n))

p4 <- ggplot(acct_k2, aes(x=n, y=amt, col=clustk2$cluster)) + geom_point()
p4


# mcc
acct_mcc <- trx_cd %>%
  group_by(ACCT, MFX_MCC_CODE) %>%
  summarize(n = n(), amt = sum(MFX_TRAMT))

mcc_acct <- acct_mcc %>%
  group_by(MFX_MCC_CODE) %>%
  summarize(acct_n = n(), acct_p=acct_n/acct_tot, mcc_n=sum(n), amt_tot = sum(amt))
colnames(mcc_acct)[colnames(mcc_acct) == "MFX_MCC_CODE"] <- "MCC"
mcc_acct <-  left_join(mcc_acct, mcc, by = 'MCC')
a = sum(mcc_acct$amt_tot)
c = sum(mcc_acct$mcc_n)
mcc_acct <- arrange(mutate(mcc_acct, mcc_np=mcc_n/c, amt_p=amt_tot/a), desc(amt_tot), desc(mcc_n))

ggplot(mcc_acct[1:11,], aes(x=reorder(CLASS, -amt_tot), y=amt_tot)) + geom_bar(stat="identity")

#acct-mcc cluster

top11 <- mcc_acct[1:11,]$MCC

acct_mcck <- filter(acct_mcc[-3], MFX_MCC_CODE %in% top11)
acct_mcck <- spread(acct_mcck, MFX_MCC_CODE, amt)
acct_mccks <- left_join(acct[,1:4], acct_mcck, by = 'ACCT')
acct_mccks[is.na(acct_mccks)] <- 0
acct_mccks <- mutate(acct_mccks, others=amt-rowSums(acct_mccks[5:15]))

# not necessarily need to run this part, it requires plenty of time 
set.seed(123)
k.max <- 10
data <- acct_mccks[2:16]
wss <- sapply(1:k.max, function(k){kmeans(data, k, nstart=10, iter.max=10)$tot.withinss})
p5 <- plot(1:k.max, wss, type="b", pch = 19, frame = FALSE, xlab="Number of clusters K", ylab="Total within-clusters sum of squares")
##

acct_clust <- kmeans(acct_mccks[2:16], centers=4, nstart = 10)
acct_mccks <- cbind(acct_mccks, acct_clust$cluster)

acct_k <- cbind(acct_k, acct_clust$cluster)


#PCA
test.pr <- princomp(acct_mccks[2:16],cor=TRUE)
summary(test.pr,loadings=TRUE) 
screeplot(test.pr,type="lines")

#scale
sd <- scale(acct_mccks[2:16])
head(sd)
test.pr2 <- prcomp(sd)
summary(test.pr2,loadings=TRUE) 

#scaled cluster
sd_clust <- kmeans(sd, centers=4, nstart = 10)
acct_k <- cbind(acct_k, sd_clust$cluster)

acct_kg3 <- acct_k %>%
  group_by(sd_clust$cluster) %>%
  summarize(acct_n = n(), p = acct_n/acct_tot, r = median(recency), amt = median(amt), freq = median(n))


#scale2
sd2 <- scale(acct_mccks[5:16])
test.pr3 <- prcomp(sd2)
summary(test.pr3) 

#scaled cluster
sd_clust2 <- kmeans(sd2, centers=4, nstart = 10)
acct_k <- cbind(acct_k, sd_clust2$cluster)

acct_kg4 <- acct_k %>%
  group_by(sd_clust2$cluster) %>%
  summarize(acct_n = n(), p = acct_n/acct_tot, r = median(recency), amt = median(amt), freq = median(n))

#details for each cluster
acct_d <- cbind(acct_mccks, clustk2$cluster)
acct_d <- cbind(acct_d, sd_clust$cluster)
acct_d <- cbind(acct_d, sd_clust2$cluster)

colnames(acct_d)
summary(acct_d)

df <- filter(acct_d, sd_clust2$cluster == 4)
summary(df)


#scale5
sd5 <- scale(acct_mccks[5:15])
test.pr5 <- prcomp(sd5)
summary(test.pr5) 

#scaled cluster5
sd_clust5 <- kmeans(sd5, centers=4, nstart = 10)
acct_k <- cbind(acct_k, sd_clust5$cluster)

acct_kg5 <- acct_k %>%
  group_by(sd_clust5$cluster) %>%
  summarize(acct_n = n(), p = acct_n/acct_tot, r = median(recency), amt = median(amt), freq = median(n))

#scale6
sd6 <- scale(acct_mccks[5:14])
test.pr6 <- prcomp(sd6)
summary(test.pr6) 

#scaled cluster6
sd_clust6 <- kmeans(sd6, centers=4, nstart = 10)
acct_k <- cbind(acct_k, sd_clust6$cluster)

acct_kg6 <- acct_k %>%
  group_by(sd_clust6$cluster) %>%
  summarize(acct_n = n(), p = acct_n/acct_tot, r = median(recency), amt = median(amt), freq = median(n))

#scaled cluster7
sd_clust7 <- kmeans(sd6, centers=5, nstart = 10)
acct_k <- cbind(acct_k, sd_clust7$cluster)

acct_kg7 <- acct_k %>%
  group_by(sd_clust7$cluster) %>%
  summarize(acct_n = n(), p = acct_n/acct_tot, r = median(recency), amt = median(amt), freq = median(n))

#scaled cluster8
sd8 <- scale(acct_mccks[c(2, 5:14)])
test.pr8 <- prcomp(sd8)
summary(test.pr8) 

sd_clust8 <- kmeans(sd8, centers=4, nstart = 10)
acct_k <- cbind(acct_k, sd_clust8$cluster)

acct_kg8 <- acct_k %>%
  group_by(sd_clust8$cluster) %>%
  summarize(acct_n = n(), p = acct_n/acct_tot, r = median(recency), amt = median(amt), freq = median(n))

#scaled cluster9
sd9 <- scale(acct_mccks[c(2, 5:13)])
test.pr9 <- prcomp(sd9)
summary(test.pr9) 

sd_clust9 <- kmeans(sd9, centers=4, nstart = 10)
acct_k <- cbind(acct_k, sd_clust9$cluster)

acct_kg9 <- acct_k %>%
  group_by(sd_clust9$cluster) %>%
  summarize(acct_n = n(), p = acct_n/acct_tot, 
            r = median(recency), amt = median(amt), freq = median(n))


## clean full table
acct_cd <- acct_mccks[,1:15]
acct_cd <- cbind(acct_cd, clustk2$cluster)
colnames(acct_cd)[colnames(acct_cd) == "clustk2$cluster"] <- "RFM$cluster"

#RFM + TOP11
#scaled cluster10
sd10 <- scale(acct_cd[2:15])
test.pr10 <- prcomp(sd10)
summary(test.pr10) 

RFM_11 <- kmeans(sd10, centers=4, nstart = 10)
acct_cd <- cbind(acct_cd, RFM_11$cluster)

acct_kg10 <- acct_cd %>%
  group_by(RFM_11$cluster) %>%
  summarize(acct_n = n(), p = acct_n/acct_tot, 
            r = median(recency), amt = median(amt), freq = median(n))


#RF + TOP10
#scaled cluster11
sd11 <- scale(acct_cd[c(2,4,5:14)])
test.pr11 <- prcomp(sd11)
summary(test.pr11) 

RF_10 <- kmeans(sd11, centers=4, nstart = 10)
acct_cd <- cbind(acct_cd, RF_10$cluster)

acct_kg11 <- acct_cd %>%
  group_by(RF_10$cluster) %>%
  summarize(acct_n = n(), p = acct_n/acct_tot, 
            r = median(recency), amt = median(amt), freq = median(n))

#F + TOP9
#scaled cluster12
sd12 <- scale(acct_cd[c(2, 5:13)])
test.pr12 <- prcomp(sd12)
summary(test.pr12) 

F_9 <- kmeans(sd12, centers=4, nstart = 10)
acct_k <- cbind(acct_k, F_9$cluster)

acct_kg12 <- acct_cd %>%
  group_by(F_9$cluster) %>%
  summarize(acct_n = n(), p = acct_n/acct_tot, 
            r = median(recency), amt = median(amt), freq = median(n))

## 
colnames(acct_cd)[colnames(acct_cd) == "RFM$cluster"] <- "RFM"
colnames(acct_cd)[colnames(acct_cd) == "RFM_11$cluster"] <- "RFM_11"
colnames(acct_cd)[colnames(acct_cd) == "RF_10$cluster"] <- "RF_10"

#demographics
demo <- read_sas("/deac/business/team20/client.sas7bdat")
colmissing <- apply(demo, 2, function(x){sum(is.na(x))})
colmissing
head(demo)

demo_cd <- demo[complete.cases(demo),] 
demo_cd$g <- str_count(demo_cd$I1_Gender_Code)
demo_cd$m <- str_count(demo_cd$Marital_Status_1)
demo_cd$e <- str_count(demo_cd$Est_Household_Income_V5)
demo_cd$gme = demo_cd$g*demo_cd$m*demo_cd$e

demo_cd2 <- filter(demo_cd, gme>0)
demo_cd2 <- demo_cd2[,1:7]
## cleaned demo_cd2
acct_d <-  nrow(demo_cd2)
colnames(demo_cd2) = c("ACCT","City","State","Age","Gender","Marital","HHIncome")
demo_acct <- left_join(demo_cd2, acct_cd, by = 'ACCT')

demo_k <- demo_acct %>%
  group_by(RF_10) %>%
  summarize(acct_n = n(), p = acct_n/acct_d, 
            r = median(recency), amt = median(amt), freq = median(n))

#Profile A
seg_A <- filter(demo_acct, RF_10 == 1)
n_A <- nrow(seg_A)
state_A <- seg_A %>%
  group_by(State) %>%
  summarize(n = n(), p = n/n_A)
gender_A <- seg_A %>%
  group_by(Gender) %>%
  summarize(n = n(), p = n/n_A)
marital_A <- seg_A %>%
  group_by(Marital) %>%
  summarize(n = n(), p = n/n_A)
HHincome_A <- seg_A %>%
  group_by(HHIncome) %>%
  summarize(n = n(), p = n/n_A)
apply(seg_A[,8:21],2,mean)
apply(seg_A[,8:21],2,median)

#Profile B
seg_B <- filter(demo_acct, RF_10 == 3)
n_B <- nrow(seg_B)
state_B <- seg_B %>%
  group_by(State) %>%
  summarize(n = n(), p = n/n_B)
gender_B <- seg_B %>%
  group_by(Gender) %>%
  summarize(n = n(), p = n/n_B)
marital_B <- seg_B %>%
  group_by(Marital) %>%
  summarize(n = n(), p = n/n_B)
HHincome_B <- seg_B %>%
  group_by(HHIncome) %>%
  summarize(n = n(), p = n/n_B)
apply(seg_B[,8:21],2,mean)
apply(seg_B[,8:21],2,median)

#Profile C
seg_C <- filter(demo_acct, RF_10 == 4)
n_C <- nrow(seg_C)
state_C <- seg_C %>%
  group_by(State) %>%
  summarize(n = n(), p = n/n_C)
gender_C <- seg_C %>%
  group_by(Gender) %>%
  summarize(n = n(), p = n/n_C)
marital_C <- seg_C %>%
  group_by(Marital) %>%
  summarize(n = n(), p = n/n_C)
HHincome_C <- seg_C %>%
  group_by(HHIncome) %>%
  summarize(n = n(), p = n/n_C)
apply(seg_C[,8:21],2,mean)
apply(seg_C[,8:21],2,median)

#Profile D
seg_D <- filter(demo_acct, RF_10 == 2)
n_D <- nrow(seg_D)
state_D <- seg_D %>%
  group_by(State) %>%
  summarize(n = n(), p = n/n_D)
gender_D <- seg_D %>%
  group_by(Gender) %>%
  summarize(n = n(), p = n/n_D)
marital_D <- seg_D %>%
  group_by(Marital) %>%
  summarize(n = n(), p = n/n_D)
HHincome_D <- seg_D %>%
  group_by(HHIncome) %>%
  summarize(n = n(), p = n/n_D)
apply(seg_D[,8:21],2,mean)
apply(seg_D[,8:21],2,median)


## Explore supplement
df1 <- filter(acct, n == 1)
df2 <- left_join(df1[,1:2], acct_mcc, by = 'ACCT')
dfn <- nrow(df2)
df2_g <- df2 %>%
  group_by(MFX_MCC_CODE) %>%
  summarize(acct_n = n(), acct_p=acct_n/dfn, mcc_n=sum(n.x), amt_tot = sum(amt))
d2 = sum(df2_g$amt_tot)
d3 = sum(df2_g$mcc_n)
df2_g <- arrange(mutate(df2_g, mcc_np=mcc_n/d3, amt_p=amt_tot/d2), desc(amt_tot), desc(mcc_n))

##store level supplement
## 5411
head(trx_cd)
df_5411 <- filter(trx_cd, MFX_MCC_CODE == 5411)

grocery <- df_5411 %>%
  group_by(MFX_DDESC1, ACCT) %>%
  summarize(tran=n(), amt=sum(MFX_TRAMT))

groc <- grocery %>%
  group_by(MFX_DDESC1) %>%
  summarize(acct=n(), amt_tot = sum(amt), tran_tot=sum(tran))

## sas file
demo_cd3 <- demo_cd2[,c(-2)]
demo_cd3 <- left_join(demo_cd3, acct[,1:4], by = 'ACCT')
write_sas(demo_cd3, "/deac/business/team20/sy/demo.sas7bdat")
