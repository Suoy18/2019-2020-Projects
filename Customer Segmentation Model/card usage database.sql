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


-- EDA
SELECT 
    @total:=SUM(MFX_TRAMT)
FROM
    trx11;

SELECT 
    @customer:=COUNT(DISTINCT ACCT)
FROM
    trx11;

SELECT 
    @totaltrx:=COUNT(*)
FROM
    trx11;

-- ALTER TABLE `mydb`.`trx11` 
-- Modify COLUMN `EFF_FROM_DT` DATE NULL DEFAULT NULL ,
-- Modify COLUMN `MFX_TRAMT` DECIMAL(10,2) NULL DEFAULT NULL ;

-- acct
CREATE TABLE acct_trx AS SELECT ACCT, COUNT(*) AS frequency, SUM(MFX_TRAMT) AS monetary FROM
    trx11
GROUP BY ACCT;

SELECT 
    MIN(frequency), MAX(frequency), AVG(frequency)
FROM
    acct_trx;

SELECT 
    MIN(monetary), MAX(monetary), AVG(monetary)
FROM
    acct_trx;

select frequency, round(acct_count/@customer*100,0)
from 
(select frequency, count(*) as acct_count
from acct_trx
group by frequency
order by acct_count desc) as temp2;

-- mcc
CREATE TABLE mcc_trx AS SELECT MFX_MCC_CODE AS mcc,
    COUNT(*) AS trx_count,
    SUM(MFX_TRAMT) AS amount,
    COUNT(DISTINCT ACCT) AS acct FROM
    trx11
GROUP BY MFX_MCC_CODE
ORDER BY amount DESC;

SELECT DISTINCT
    mcc_trx.mcc,
    mcc.CLASS AS industry,
    trx_count,
    ROUND(trx_count / @totaltrx * 100, 0),
    amount,
    ROUND(amount / @total * 100, 0),
    acct,
    ROUND(acct / @customer * 100, 0)
FROM
    mcc_trx
        LEFT JOIN
    mcc ON mcc_trx.mcc = mcc.MCC
ORDER BY amount DESC
LIMIT 20;

SET @csum := 0;
SELECT 
    mcc, amount, ROUND(cum_amount / @total * 100, 0)
FROM
    (SELECT 
        mcc, amount, (@csum:=@csum + amount) AS cum_amount
    FROM
        mcc_trx) AS temp1;


-- Sampling
CREATE TABLE client11 AS SELECT * FROM
    client_cd
WHERE
    client_cd.CLIENT_ID IN (SELECT DISTINCT
            (ACCT)
        FROM
            trx11);

SELECT 
    COUNT(DISTINCT (CLIENT_ID))
FROM
    client11;

show global variables like 'max_allowed_packet';

SELECT 
    COUNT(DISTINCT (acct))
FROM
    trx11;

CREATE TABLE trx12 AS SELECT * FROM
    trx11
WHERE
    MOD(ACCT, 7) = 1;

SELECT 
    COUNT(DISTINCT (acct))
FROM
    trx12;

CREATE TABLE client12 AS SELECT * FROM
    client11
WHERE
    client11.CLIENT_ID IN (SELECT DISTINCT
            (ACCT)
        FROM
            trx12);

SELECT 
    COUNT(DISTINCT (CLIENT_ID))
FROM
    client12;

CREATE TABLE client12_cd AS SELECT * FROM
    client12
GROUP BY CLIENT_ID;

SELECT 
    COUNT(DISTINCT (CLIENT_ID))
FROM
    client12_cd;

-- Export
SELECT 
    *
FROM
    client12_cd INTO OUTFILE 'C:/WAMPSERVER/tmp/client12.csv' FIELDS TERMINATED BY ',';
SELECT 
    *
FROM
    trx12 INTO OUTFILE 'C:/WAMPSERVER/tmp/trx12.csv' FIELDS TERMINATED BY ',';
