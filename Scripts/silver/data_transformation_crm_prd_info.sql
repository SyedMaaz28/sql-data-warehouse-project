
SELECT * FROM BRONZE.crm_prd_info 

SELECT 
prd_id,
prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
FROM BRONZE.crm_prd_info 


--  CHECKS FOR NULLS AND DUPLICATES IN PRIMARY KEY
Select
prd_id,
count(*) total_count
from bronze.crm_prd_info 
group by prd_id
having count(*) > 1 or prd_id is null



SELECT 
prd_id,
prd_key,
replace(substring(prd_key,1,5),'-','_' ) as cat_id,
substring(prd_key,7,length(prd_key)) as prd_key,
prd_nm,
coalesce(prd_cost,0) as prd_cost,
prd_line,
case upper(trim(prd_line)) 
	when 'M' then 'Mountain'
	when 'R' then 'Road'
	when 'T' then 'Touring'
	when 'S' then 'Other Sales'
	else 'n/a'
end as prd_line,
prd_start_dt,
prd_end_dt
FROM BRONZE.crm_prd_info 


-- Transforming Start and End Date Columns

select
prd_id,
prd_key,
prd_start_dt,
prd_end_dt,
lead(prd_start_dt) over(partition by prd_key order by prd_start_dt) - INTERVAL '1 day' AS prd_end_dt_test
from bronze.crm_prd_info
where prd_key in ('AC-HE-HL-U509','AC-HE-HL-U509-B')





SELECT 
prd_id,
prd_key,
replace(substring(prd_key,1,5),'-','_' ) as cat_id,
substring(prd_key,7,length(prd_key)) as prd_key,
prd_nm,
coalesce(prd_cost,0) as prd_cost,
prd_line,
case upper(trim(prd_line)) 
	when 'M' then 'Mountain'
	when 'R' then 'Road'
	when 'T' then 'Touring'
	when 'S' then 'Other Sales'
	else 'n/a'
end as prd_line,
cast(prd_start_dt as date) as prd_start_dt,
cast(lead(prd_start_dt) over(partition by prd_key order by prd_start_dt) - INTERVAL '1 day' as date) AS prd_end_dt_test
FROM BRONZE.crm_prd_info 


-- Altering table

DROP TABLE IF EXISTS silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info (
    prd_id       INT,
	cat_id		 VARCHAR(50),
    prd_key      VARCHAR(50),
    prd_nm       VARCHAR(50),
    prd_cost     INT,
    prd_line     VARCHAR(50),
    prd_start_dt DATE,
    prd_end_dt   DATE,
	dwh_create_date TIMESTAMP DEFAULT NOW()
);



-- INSERT INTO SILVER LAYER

insert into silver.crm_prd_info(
    prd_id,
	cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT 
prd_id,
replace(substring(prd_key,1,5),'-','_' ) as cat_id,  -- Extract category id
substring(prd_key,7,length(prd_key)) as prd_key,  -- Extract Product key
prd_nm,
coalesce(prd_cost,0) as prd_cost,  -- Remove Null Cost value
case upper(trim(prd_line)) 
	when 'M' then 'Mountain'
	when 'R' then 'Road'
	when 'T' then 'Touring'
	when 'S' then 'Other Sales'
	else 'n/a'    -- Map product lune codes to Descriptive Values
end as prd_line,
cast(prd_start_dt as date) as prd_start_dt,  
cast(lead(prd_start_dt) over(partition by prd_key order by prd_start_dt) - INTERVAL '1 day' as date) AS prd_end_dt
FROM BRONZE.crm_prd_info 

select * from silver.crm_prd_info
