-- Import Data
LOAD DATA INFILE 'C:/WAMPSERVER/tmp/trx11.csv'
INTO TABLE mydb.trx11
FIELDS TERMINATED BY ','
ignore 1 lines;

LOAD DATA INFILE 'C:/WAMPSERVER/tmp/mcc.csv'
INTO TABLE mydb.mcc
FIELDS TERMINATED BY ','
ignore 1 lines;

LOAD DATA INFILE 'C:/WAMPSERVER/tmp/client_cd.csv'
INTO TABLE mydb.client_cd
FIELDS TERMINATED BY ','
ignore 1 lines;

-- Sampling
create table client11 as
select * from client_cd where client_cd.CLIENT_ID in (select distinct(ACCT) from trx11);

select count(distinct(CLIENT_ID))
from client11;

show global variables like 'max_allowed_packet';

select count(distinct(acct))
from trx11;

create table trx12 as
select * from trx11 where MOD(ACCT, 7) = 1;

select count(distinct(acct))
from trx12;

create table client12 as
select * from client11 where client11.CLIENT_ID in (select distinct(ACCT) from trx12);

select count(distinct(CLIENT_ID))
from client12;

create table client12_cd as
select *
from client12 
group by CLIENT_ID;

select count(distinct(CLIENT_ID))
from client12_cd;

-- Export
select * from client12_cd into outfile "C:/WAMPSERVER/tmp/client12.csv" fields terminated by ',';
select * from trx12 into outfile "C:/WAMPSERVER/tmp/trx12.csv" fields terminated by ',';
