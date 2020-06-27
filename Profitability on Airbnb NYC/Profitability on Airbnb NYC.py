# -*- coding: utf-8 -*-
# Provided by S.Y. 2020

'''Data Import'''
import pandas as pd
import numpy as np

zillow = pd.read_csv('D:/C1/Zip_Zhvi_2bedroom.csv')
airbnb = pd.read_csv('D:/C1/listings.csv')

#Display Settings
pd.set_option('expand_frame_repr', False) 
pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)
np.set_printoptions(suppress=True)
pd.set_option('display.float_format', lambda x:'%.2f'%x)


'''Data Quality Check'''
import missingno as msno
#Zillow dataset quality check

##basic info
zillow.shape
zillow.columns
zillow.head()
zillow.info(' ')
zillow.describe()

##drop duplicates
zillow = zillow.drop_duplicates()

##data type change (RegionName is zipcode, better coded as string)
zillow.RegionName = zillow.RegionName.astype('str')

##check missing value
msno.bar(zillow)
zillow_null = pd.DataFrame((zillow.isnull()).mean()*100)
zillow_null[zillow_null[0] < 10]

#Airbnb Dataset

##basic info
airbnb.shape
airbnb.columns
airbnb.head()
airbnb.info(' ')
airbnb.describe()

##drop duplicates
airbnb = airbnb.drop_duplicates()

##check missing value
msno.bar(airbnb, labels = True)
airbnb_null = pd.DataFrame((airbnb.isnull()).mean()*100)
airbnb_null[airbnb_null[0] > 40]  #view 40% missing variables, consider delete

##data format correcting
airbnb['zipcode'] = airbnb['zipcode'].astype('str').str[0:5].replace('.', '')  #zipcode format 5 digits string
airbnb.host_response_rate = airbnb.host_response_rate.str.strip('%').fillna(0).astype('int64')

###here turned these columns into datetime type, but when in use only consider year and month 
airbnb.last_scraped = pd.to_datetime(airbnb.last_scraped)
airbnb.host_since = pd.to_datetime(airbnb.host_since)
airbnb.first_review = pd.to_datetime(airbnb.first_review)
airbnb.last_review = pd.to_datetime(airbnb.last_review)  

###Function for convert currency data type to float
def convert_currency(value):
    new_value = value.replace('$', '').replace(',', '')
    return np.float(new_value)
##currency data format correcting, fill na as 0
airbnb['price'] = airbnb['price'].apply(convert_currency)
airbnb['weekly_price'] = airbnb['weekly_price'].fillna(0).astype('str').apply(convert_currency)
airbnb['monthly_price'] = airbnb['monthly_price'].fillna(0).astype('str').apply(convert_currency)
airbnb['security_deposit'] = airbnb['security_deposit'].fillna(0).astype('str').apply(convert_currency)
airbnb['cleaning_fee'] = airbnb['cleaning_fee'].fillna(0).astype('str').apply(convert_currency)
airbnb['extra_people'] = airbnb['extra_people'].fillna(0).astype('str').apply(convert_currency)

##Uniform state and city name
airbnb.state.nunique()
airbnb.state.unique()
airbnb.state = airbnb.state.replace('Ny', 'NY').replace('ny', 'NY').replace('New York ', 'NY')
airbnb.city.nunique()
airbnb.city.unique()   #Too many different city names, could not clean currently, will discuss this later
##Other string format cleaning
airbnb.amenities = airbnb.amenities.replace('{', '').replace('}', '').replace("'", '').replace('"', '')


'''Data Munging'''
#Useable Airbnb dataset

##Discuss some variables and decide if it is useful for profitability analysis
###Weekly price and monthly price has 90% missing values, but price is important for profit analysis
###Calculate the relationship with non-zero weekly price and monthly price with daily price
a1 = airbnb[['price', 'weekly_price']][airbnb.weekly_price>0]
a1.weekly_price.mean()/a1.price.mean()   #weekly price is approximate 6 times of daily price
a2 = airbnb[['price', 'monthly_price']][airbnb.monthly_price>0]
a2.monthly_price.mean()/a2.price.mean()   #monthly price is approximate 21 times of daily price

###longitude and latitude could be used for identify location, however need to check if exact or not
len(airbnb[airbnb.is_location_exact == 't'])/len(airbnb)   #over 82% are exact, consider use

###Variables like 'experiences_offered' has no missing value, but every value are the same 'none', consider not use
airbnb.experiences_offered.head()
airbnb.experiences_offered.nunique()

##Create new cleaned Airbnb data table
airbnb_cd = airbnb
##Filling missing data for numeric data(bedrooms, bathrooms, beds) using median 
###In the first data quality part had already checked the missing value amount and distribution
###these variables has small amount of missing values and approximate normally distruibution, so consider use median to fill 
airbnb_cd['bedrooms'] = airbnb_cd['bedrooms'].fillna(airbnb_cd['bedrooms'].median())
airbnb_cd['bathrooms'] = airbnb_cd['bathrooms'].fillna(airbnb_cd['bathrooms'].median())
airbnb_cd['beds'] = airbnb_cd['beds'].fillna(airbnb_cd['bathrooms'].median())

##Delete extreme value data, for example the daily price less or equal to 0 
airbnb_cd = airbnb[airbnb_cd.price > 0] 

##After dropping the high perportion of missing value variables and irrelevant variables with profit analysis
##Here select the useful variables for further data analysis
###This table could be changed due to different variable selection combination
airbnb_cd = airbnb[['id', 'summary', 'space', 'description', 'neighborhood_overview', 'neighbourhood_cleansed', 
                    'neighbourhood_group_cleansed', 'zipcode', 'property_type', 'bathrooms', 'bedrooms', 
                    'amenities', 'price', 'cleaning_fee', 'minimum_nights', 'maximum_nights', 
                    'availability_30', 'availability_60', 'availability_90', 'availability_365']]


#Useable Zillow dataset

##Property value trend check using median property value
zillow2 = zillow.drop(columns=['RegionID', 'RegionName', 'City', 'State', 'Metro', 'CountyName', 'SizeRank'])
zillow2_median = pd.DataFrame(zillow2.median())

##Line trend chart for median property value overall
import matplotlib.pyplot as plt
import pylab as pl
plt.figure(figsize=(45, 4))
plt.margins(x=0)
p1 = plt.plot(zillow2_median)
plt.ylim(ymin = 0)
pl.xticks(rotation=90)
plt.show()   #Increase from 1996 till 2007, but decrease from 2007 till 2011 (probably caused by financial crisis), increase again after that 

##Predict the latest property value (time series forecasting)
##Start from 2010-8 based on data quality (<2% missing value) and society situation (almost the end of 2007 financial crisis)
##Prediction period same as Airbnb revenue data latest scraped time (year and month)
##If goes to different market, start time does not change
from statsmodels.graphics.tsaplots import plot_acf, plot_pacf
from statsmodels.tsa.arima_model import ARIMA
##Slice the zillow dataset from 2010-08 and transpose for time series calculation
zillow_column = list(zillow.columns)
start = zillow_column.index('2010-08')   #in case in other discussion this start period could be changed
zillow_column_cd = zillow_column[:7] + zillow_column[start:]
zillow_cd = zillow[zillow_column_cd]

##Define the time series forecasting period
##The latest time period is defined by airbnb dataset last scraped time
##This method makes sure that the revenue(airbnb) and cost(zillow) are in the same time period
latest = airbnb.last_scraped[1]
pre = pd.to_datetime(zillow_column[-1])
t = (latest.year - pre.year)*12 + (latest.month - pre.month)

##Use median value to build ARIMA model and decide the parameters
zillow_cd_median = pd.DataFrame(zillow_cd.drop(columns=['RegionID', 'RegionName', 'City', 'State', 'Metro', 'CountyName', 'SizeRank']).median())
zillow_cd_median.index = pd.to_datetime(zillow_cd_median.index)

##Check the ACF and PACF, determine that the order (0,1,1) is proper for the model
plot_acf(zillow_cd_median)
plot_pacf(zillow_cd_median) 

##Fit the ARIMA model and predict
model1 = ARIMA(zillow_cd_median.values, (0,1,1)).fit()
model1.summary()
output1 = pd.DataFrame(model1.forecast(t)[0])
zillow_cd_median = zillow_cd_median.append(output1)
zillow_cd_median.index = pd.date_range('8/1/2010', latest, freq = 'MS')

##Create the forcasting line trend chart for the median property value
plt.figure(figsize=(15, 4))
plt.margins(x=0)
p2 = plt.plot(zillow_cd_median)
plt.axvline(x=pre, color='r', linestyle='--')
plt.ylim(ymin = 0)
plt.show()   #gently increaseing trend for the perdiction period from 2017 to 2019 

##Use the same parameters to predict the property value of specific area 
##Here could build a funcion for connecting the cleaned useful dataset: airbnb_cd and zillow_cd into profit_ny
###The input variable is city, denoted by c
c = 'New York'
#prepare the time series forecasting dataset
zillow_cd_T1 = zillow_cd[zillow_cd.City == c]
zillow_cd_T2 = zillow_cd_T1.T[7:]
zillow_cd_T2.index = pd.to_datetime(zillow_cd_T2.index)
zillow_cd_T2.columns = zillow_cd_T1['RegionName']
for i in zillow_cd_T1['RegionName']:
    zillow_cd_T2[i] = pd.to_numeric(zillow_cd_T2[i])

#forecast for different zipcode using the same ARIMA model as previous decided
#save the predicted latest property value to a new cleaned zillow dataset:zillow_cd_T1
property_value = []
for j in zillow_cd_T1['RegionName']:
    model2 = ARIMA(zillow_cd_T2[j].values, (0,1,1)).fit()
    model2.summary()
    output2 = model2.forecast(t)[0][t-1]
    property_value.append(output2)
property_value = pd.DataFrame(property_value)
property_value.index = zillow_cd_T1.index
zillow_cd_T1 = pd.merge(zillow_cd_T1, property_value, left_on = zillow_cd_T1.index, right_on = property_value.index)
#the prediction of the latest period 
zillow_cd_T1 = zillow_cd_T1.rename(columns={0:'property_value'})
#select the useful variables in zillow dataset to merge with airbnb_cd dataset
zillow_cd_T1 = zillow_cd_T1[['RegionName', 'City', 'CountyName', 'property_value']]
#sort the zillow_cd_T1 dataset by descending order of property value
zillow_cd_T1 = zillow_cd_T1.sort_values(['property_value'],ascending=False)

#Connect the useable Zillow and Airbnb dataset on zipcode: airbnb_cd, zillow_cd_T1
profit = pd.merge(airbnb_cd, zillow_cd_T1, left_on = 'zipcode', right_on = 'RegionName')
#Filter the desired requirements: city (New York) and bedrooms (2)
##Filter variable use the zillow.City, cause this one has no missing values and uniformed
##airbnb_cd.city has a lot of missing values and different values defined as 'New York City'
profit_ny = profit[(profit.City == c) & (profit.bedrooms == 2)]
profit_ny = profit_ny.drop(columns=['City', 'RegionName'])

##The connect function is supposed to end here

###Check the datasets 
airbnb_cd.zipcode.nunique()
zillow_cd_T1.RegionName.nunique()   
#There are a lot more zipcodes in airbnb listing than the zillow dataset
#So using the inner merge to connect these 2 datasets


'''Profitability Analysis'''
#Explore the full profit_ny table
##provide metadata for profit_ny table in the appendix
profit_ny.shape   #22 variables and 1565 observations
profit_ny.columns
profit_ny.info('')
profit_ny.zipcode.nunique()   #24 unique zipcodes represented in profit_ny table

#neighbourhood group level analysis
profit_ny.neighbourhood_group_cleansed.nunique()   #4 neighbourhood group 
##Neighbourhood airbnb listing amount
z1 = profit_ny.groupby(['neighbourhood_group_cleansed','zipcode'])[['id']].count()
z1.stack()   #Manhattan has the most zipcodes and airbnb listings, followed by Brooklyn
##prepare a check list to check which zipcode is in which neighbourhood group
z2 = profit_ny[['neighbourhood_group_cleansed', 'zipcode']].drop_duplicates().sort_values('neighbourhood_group_cleansed')
#one zipcode both in Manhattan and Brooklyn (consider check the reality)
z2.groupby(['neighbourhood_group_cleansed'])[['zipcode']].count()


#Breakeven analysis
##Assumption: the general occupacy rate is 0.75
occ = 0.75
##Creat several new variables for analysis
##provide metadata for profit_ny table in the appendix
###daily price total = daily price + cleaning_fee
profit_ny['price_tot'] = profit_ny['price'] + profit_ny['cleaning_fee']
###breakeven days = property value/(occupacy rate * daily price total)
profit_ny['breakeven_days'] = profit_ny['property_value']/(occ*profit_ny['price_tot'])
###convert the breakeven days into breakeven years 
profit_ny['breakeven_yrs'] = profit_ny['breakeven_days']/365
###create a new adjusted occupacy rate by calulate the booked rate within 90 days
profit_ny['occ_adj'] = (90 - profit_ny['availability_90'])/90

###boxplot for overall breakevey years
import seaborn as sns
plt.figure(figsize=(7,2))
sns.boxplot(profit_ny.breakeven_yrs,data=profit_ny,orient='h')
plt.yticks(fontsize=15.0)
ax = plt.gca()
ax.spines['right'].set_color('none')
ax.spines['left'].set_color('none')
ax.spines['top'].set_color('none')

###boxplot for the adjusted occupacy rate
plt.figure(figsize=(7,2))
sns.boxplot(profit_ny.occ_adj,data=profit_ny,orient='h')
plt.yticks(fontsize=15.0)
ax = plt.gca()
ax.spines['right'].set_color('none')
ax.spines['left'].set_color('none')
ax.spines['top'].set_color('none')

##Aggregated data at zipcode level
###average breakeven years by zipcode
breakeven_yrs_avg = profit_ny.groupby(['zipcode'])[['breakeven_yrs']].mean()
###average daily price total by zipcode
price_tot_avg = profit_ny.groupby(['zipcode'])[['price_tot']].mean()
###number of airbnb listings by zipcode
cnt = profit_ny.groupby(['zipcode'])[['id']].count()
###average adjusted occupacy rate by zipcode
occ_adj_avg = profit_ny.groupby(['zipcode'])[['occ_adj']].mean()*100

###Merge all aggregated zipcode level data into one table: bp
###provide metadata for bp table in the appendix
bp = pd.merge(breakeven_yrs_avg, price_tot_avg, left_on = breakeven_yrs_avg.index, 
              right_on=price_tot_avg.index)
bp['zipcode'] = bp.key_0
bp = bp.drop(columns=['key_0'])
bp = pd.merge(bp, cnt, left_on=bp.zipcode, right_on=cnt.index)
bp = bp.drop(columns=['key_0'])
bp = bp.rename(columns={'id':'cnt'})
bp = pd.merge(bp, zillow_cd_T1[['RegionName', 'property_value']], left_on = bp.zipcode, right_on=zillow_cd_T1.RegionName)
bp = bp.drop(columns=['key_0', 'RegionName'])
bp = pd.merge(bp, occ_adj_avg, left_on = bp.zipcode, right_on=occ_adj_avg.index)
bp = bp.drop(columns=['key_0'])
bp = pd.merge(bp, z2)
###create yearly revenue by zipcode = daily price total*number of listings*general occupacy rate*365
bp['yearly_revenue'] = bp.price_tot*bp.cnt*occ*365

#Model for evaluation to rank overall performance includes 3 metrics:
##average breakeven years, yearly revenue and adjusted occupacy rate
##each weighted 40%, 40%, 20%
##Get the final rank for each zipcode
bp['rank'] = (bp.breakeven_yrs.rank(method='first')*0.4
  + bp.yearly_revenue.rank(ascending=False, method='first')*0.4 
  + bp.occ_adj.rank(ascending=False, method='first')*0.2).rank(method='first')
bp = bp.sort_values(['rank'])

#Ranked performance by zipcode, 3 subplots for 3 metrics
fig, ax = plt.subplots(figsize=(10, 11))
l = range(len(bp))
x1 = np.array(round(bp.sort_values(['rank'], ascending=False).breakeven_yrs,1))
x2 = np.array(round(bp.sort_values(['rank'], ascending=False).yearly_revenue/1000000, 1))
x3 = np.array(round(bp.sort_values(['rank'], ascending=False).occ_adj,1))
#Bar chart for average years needed to breakeven
ax1 = plt.subplot(131)
plt.barh(y = l, width = x1, data = bp, tick_label=bp.sort_values(['rank'], ascending=False).zipcode, facecolor='#9999ff')
plt.xticks([])
for a, b in zip(l, x1):
    plt.text(b, a, b, ha='left', va='center', fontsize=11)
ax = plt.gca()
ax.set_title('Average Years Needed to Breakeven', fontsize=12)
ax.spines['right'].set_color('none')
ax.spines['left'].set_color('none')
ax.spines['top'].set_color('none')
ax.spines['bottom'].set_color('none')
#Bar chart for yearly revenue in million dollars
ax2 = plt.subplot(132)
plt.barh(y=l, width = x2, data = bp, facecolor='#ff9999')
plt.xticks([])
plt.yticks([])
plt.tight_layout()
for a, b in zip(l, x2):
    plt.text(b, a, b, ha='left', va='center', fontsize=11)
ax = plt.gca()
ax.set_title('Yearly Revenue (million($))', fontsize=12)
ax.spines['right'].set_color('none')
ax.spines['left'].set_color('none')
ax.spines['top'].set_color('none')
ax.spines['bottom'].set_color('none')
#Bar chart for adjusted occupacy rate(booked rate in 90 days) (%)
ax3 = plt.subplot(133)
from matplotlib import cm
map_vir = cm.get_cmap(name='viridis')
norm = plt.Normalize(x3.min(), x3.max())
norm_n = norm(x3)
color = map_vir(norm_n)
plt.barh(y=l, width=x3, data = bp, color = color)
plt.xticks([])
plt.yticks([])
for a, b in zip(l, x3):
    plt.text(b, a, b, ha='left', va='center', fontsize=11)
plt.title('Adjusted Occupacy Rate (%)')
ax = plt.gca()
ax.spines['right'].set_color('none')
ax.spines['left'].set_color('none')
ax.spines['top'].set_color('none')
ax.spines['bottom'].set_color('none')

#Bar chart for property value by zipcode, ordered by ranking
plt.figure(figsize=(15, 4))
plt.margins(x=0.01)
p3 = plt.bar(x = range(len(bp)), height = np.array(bp.property_value), 
             data = bp, tick_label=bp.zipcode, width = 0.6)
plt.axhline(y=bp.property_value.mean(), color='r', linestyle='--')
plt.xlabel('Zipcode')
plt.ylabel('Property Value ($)')
plt.title('Property Value by Zipcode (2019-07)')
ax = plt.gca()
ax.spines['right'].set_color('none')
ax.spines['top'].set_color('none')
plt.show()

#Bar chart for daily price by zipcode, ordered by ranking
plt.figure(figsize=(15, 4))
plt.margins(x=0.01)
p4 = plt.bar(x = range(len(bp)), height = np.array(bp.price_tot),
             data = bp, tick_label=bp.zipcode, width = 0.6)
plt.axhline(y=bp.price_tot.mean(), color='r', linestyle='--')
plt.xlabel('Zipcode')
plt.ylabel('Daily Price ($)')
plt.title('Daily Price by Zipcode')
ax = plt.gca()
ax.spines['right'].set_color('none')
ax.spines['top'].set_color('none')
plt.show()

#Treemap for listing houses count by zipcode 
import squarify
p5 = plt.figure(figsize=(10, 6))
squarify.plot(sizes=bp.cnt, label=(bp.zipcode+': '+bp.cnt.map(str)+' H'), alpha=0.6) 
plt.axis('off') 
plt.show() 

##What's next
##Other potential zipcodes/listings in Manhattan and Brooklyn
airbnb_cd2 = airbnb_cd[airbnb_cd.neighbourhood_group_cleansed == 'Manhattan']
airbnb_cd2.zipcode.nunique()
airbnb_cd3 = airbnb_cd[airbnb_cd.neighbourhood_group_cleansed == 'Brooklyn']
airbnb_cd3.zipcode.nunique()


'''Appendix'''
#profit_ny table metadata
Variable = np.array(['id ... availability_365', 'CountyName', 'property_value', 'price_tot', 'breakeven_days', 'breakeven_yrs', 'occ_adj'])
Description = np.array(['*from original airbbnb dataset', 
                                     'County name, from original zillow dataset', 
                                     'latest property value (at the time of the airbnb dataset last scrapted',
                                     'daily price total(including price and cleaning fee)',
                                     'breakeven days',
                                     'breakeven years',
                                     'adjusted occupacy rate (booked rate within 90 days'])
profit_ny_mt = pd.DataFrame([Variable, Description]).T
profit_ny_mt = profit_ny_mt.rename(columns={0:'Variable', 1:'Description'})
profit_ny_mt

#bp table metadata: bp_mt
Variable = np.array(['breakeven_yrs', 'price_tot', 'zipcode', 'cnt', 'property_value', 'occ_adj', 'yearly_revenue', 'rank'])
Description = np.array(['average breakeven years', 'average daily price total(including price and cleaning fee)',
'zipcode', 'number of airbnb listings', 'average latest property value (at the time of the airbnb dataset last scrapted)',
'average adjusted occupacy rate (booked rate within 90 days',
'yearly revenue (daily price total*number of listings*general occupacy rate*365)',
'ranking for profitability'])
bp_mt = pd.DataFrame([Variable, Description]).T
bp_mt = bp_mt.rename(columns={0:'Variable', 1:'Description'})
bp_mt
