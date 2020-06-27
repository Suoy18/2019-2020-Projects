library(tidyverse)
df1 <- read_csv("D:\\Master\\MSBA\\Courses\\2019 Fall\\Case competition\\Open990_Governance_Snack_Set_Public_2019-01-15.csv")

association <- filter(df1, df1$org_form.association == "true")

library(cluster)
library(factoextra) 

df2 <- subset(association, select = c(ein, name_org, tax_yr, state, formation_yr, 
                                      exempt_status.501c3, exempt_status.501c_any, gross_receipts,
                                      income_tot_unrelated, rev_tot_prioryr, expense_tot_prioryr, asset_tot_beginyr, 
                                      rev_tot_curyr, expense_tot_curyr, asset_tot_endyr,
                                      comp_currkeypersons_tot, invest_prog_endyr))
df2$asset_diversion <- df2$asset_tot_endyr - df2$asset_tot_beginyr

df3 <- filter(df2, is.na(df2$rev_tot_curyr)==F)
df3 <- filter(df3, is.na(df3$expense_tot_curyr)==F)
df3 <- filter(df3, is.na(df3$asset_diversion)==F)

a2 <- subset(df3, select = c(rev_tot_curyr, expense_tot_curyr, asset_diversion))
res <- kmeans(a2,4)
res1 <- cbind(df3, res$cluster)
fviz_cluster(res,data=a2)

set.seed(123) 
fviz_nbclust(a2,kmeans,method="wss")+geom_vline(xintercept=4,linetype=2) 
