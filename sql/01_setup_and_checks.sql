create schema if not exists raw;
create schema if not exists clean;
create schema if not exists dq;
create schema if not exists analysis;

create table raw.cb_arrears(
reporting_date TEXT,
entity_group TEXT,
format TEXT,
category TEXT,
row_position TEXT,
column_position TEXT,
row_desc TEXT,
observation_type TEXT,
observation TEXT,
number_of_accounts TEXT
);

select table_schema ,table_name
from information_schema.tables
where table_schema in ('raw','clean','dp','analysis')

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'raw' AND table_name = 'cb_arrears';


select count(*) 
from raw.cb_arrears;


select observation,number_of_accounts
from raw.cb_arrears
where observation like '%,%' or number_of_accounts like '% %'
limit 5;

create table raw.ppr(
sale_date TEXT,
address TEXT,
county TEXT,
eircode TEXT,
price TEXT,
not_full_market_price TEXT,
vat_exclusive TEXT,
description TEXT,
property_sixe TEXT
);


select column_name
from information_schema.columns 
where table_schema ='raw' and table_name ='ppr';


alter table raw.ppr
rename column property_sixe to property_size;


select column_name
from information_schema.columns 
where table_schema ='raw' and table_name ='ppr';

CREATE TABLE raw.bpfi_volumes (
    row_num     SERIAL,
    col_year    TEXT,
    col_month   TEXT,
    ftb         TEXT,
    mover       TEXT,
    ril         TEXT,
    remortgage  TEXT,
    topup       TEXT,
    total       TEXT
);

