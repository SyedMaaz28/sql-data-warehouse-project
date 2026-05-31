/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ====================================================================
-- Checking 'silver.crm_cust_info'
-- ====================================================================
-- Checks for NULLs or Duplicates in Primary Key

SELECT * FROM bronze.crm_cust_info 

Select
cst_id,
count(*) total_count
from bronze.crm_cust_info 
group by cst_id
having count(*) > 1


-- Removing NUlls and Duplicates 

select
*
from(
Select
*,
row_number() over(partition by cst_id order by cst_create_date desc) flag_last
from bronze.crm_cust_info
where cst_id is not null
)t
where flag_last = 1



-- ------------------------------------------------------------------------------------------------------------------------------



-- Check for unwanted Spaces in Strings
-- Observations:
	-- Contains 17 entries in Firstname
	-- Contains 22 entries in Lastname
	-- Contains 0 entries in both MaritalStatus and Gender
select 
cst_firstname
from bronze.crm_cust_info 
where cst_firstname != trim(cst_firstname)

select 
cst_lastname
from bronze.crm_cust_info 
where cst_lastname != trim(cst_lastname)

select 
cst_marital_status
from bronze.crm_cust_info 
where cst_marital_status != trim(cst_marital_status)

select 
cst_gndr
from bronze.crm_cust_info 
where cst_gndr != trim(cst_gndr)



-- Removing Unwanted Spaces

select
cst_id,
cst_key,
trim(cst_firstname) as cst_firstname,
trim(cst_lastname) as cst_lastname,
cst_marital_status,
cst_gndr,
cst_create_date
from(
Select
*,
row_number() over(partition by cst_id order by cst_create_date desc) flag_last
from bronze.crm_cust_info
where cst_id is not null
)t
where flag_last = 1




-- ------------------------------------------------------------------------------------------------------------------------------

-- Data Standardization and Consistency

-- For Marital Status
select distinct cst_marital_status
from bronze.crm_cust_info

-- For Gender
select distinct cst_gndr
from bronze.crm_cust_info




select
cst_id,
cst_key,
trim(cst_firstname) as cst_firstname,
trim(cst_lastname) as cst_lastname,
case when upper(trim(cst_marital_status)) = 'S' then 'Single'
	 when upper(trim(cst_marital_status)) = 'M' then 'Married'
	 else 'n/a'
end cst_marital_status,
case when upper(trim(cst_gndr)) = 'M' then 'Male'
	 when upper(trim(cst_gndr)) = 'F' then 'Female'
	 else 'n/a'
end cst_gndr,
cst_create_date
from(
Select
*,
row_number() over(partition by cst_id order by cst_create_date desc) flag_last
from bronze.crm_cust_info
where cst_id is not null
)t
where flag_last = 1


SELECT * FROM bronze.crm_cust_info 

-- ------------------------------------------------------------------------------------------------------------------------------
-- INSERT INTO SILVER LAYER

INSERT INTO SILVER.crm_cust_info(
cst_id,
cst_key,
cst_firstname,
cst_lastname,
cst_marital_status,
cst_gndr,
cst_create_date
)
select
cst_id,
cst_key,
trim(cst_firstname) as cst_firstname,
trim(cst_lastname) as cst_lastname,
case when upper(trim(cst_marital_status)) = 'S' then 'Single'
	 when upper(trim(cst_marital_status)) = 'M' then 'Married'
	 else 'n/a'
end cst_marital_status,
case when upper(trim(cst_gndr)) = 'M' then 'Male'
	 when upper(trim(cst_gndr)) = 'F' then 'Female'
	 else 'n/a'
end cst_gndr,
cst_create_date
from(
Select
*,
row_number() over(partition by cst_id order by cst_create_date desc) flag_last
from bronze.crm_cust_info
where cst_id is not null
)t
where flag_last = 1




SELECT * FROM silver.crm_cust_info 



-- ====================================================================
-- Checking 'silver.crm_prd_info'
-- ====================================================================


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



-- ====================================================================
-- Checking 'silver.crm_sales_details'
-- ====================================================================

--  CRM_SALES_DETAILS

SELECT * FROM BRONZE.CRM_SALES_DETAILS

-- DATE CHECKS
SELECT 
NULLIF(sls_ship_dt,0)
FROM BRONZE.CRM_SALES_DETAILS
WHERE sls_ship_dt <= 0 OR LENGTH(sls_ship_dt::VARCHAR) != 8



SELECT 
	sls_ord_num, 
	sls_prd_key,
	sls_cust_id, 
	CASE WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::VARCHAR) != 8 THEN NULL
		ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	END AS SLS_ORDER_DT,
	CASE WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::VARCHAR) != 8 THEN NULL
		ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
	END AS sls_ship_dt,
	CASE WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::VARCHAR) != 8 THEN NULL
		ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
	END AS sls_due_dt,
	sls_sales, 
	sls_quantity, 
	sls_price
FROM BRONZE.CRM_SALES_DETAILS


--  CHECK DATA CONSISTENCY BETWEEN SALES, QUANITIY, PRICE
-- SALES = QUANTITY * PRICE
-- VALUES MUST NOT BE NULL, ZERO, NEGATIVE


SELECT 
SLS_SALES as old_price,
SLS_QUANTITY,
SLS_PRICE,
case when SLS_SALES <= 0 or SLS_SALES is null or SLS_SALES != SLS_QUANTITY * abs(SLS_PRICE) 
	then SLS_QUANTITY * abs(SLS_PRICE) 
	else SLS_SALES
end as SLS_SALES,

case when SLS_PRICE <= 0 or SLS_PRICE is null 
	then SLS_SALES / coalesce(SLS_QUANTITY,0)
	else sls_price
end as sls_price
FROM BRONZE.CRM_SALES_DETAILS
WHERE SLS_SALES != SLS_QUANTITY * SLS_PRICE
OR SLS_SALES <= 0 OR SLS_QUANTITY <= 0 OR SLS_PRICE <= 0
OR SLS_SALES IS NULL OR SLS_QUANTITY IS NULL OR SLS_PRICE IS NULL

--  RULES TO TRANSFORM 
-- 1) If sales is negative, null or zero, Derive it using Quantity and Price
-- 2) If Price is Zero or Null, Calculate it using Sales and Quantity
-- 3) if price is negaitve convert it to positive value





--  Final Query 

SELECT 
	sls_ord_num, 
	sls_prd_key,
	sls_cust_id, 
	CASE WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::VARCHAR) != 8 THEN NULL
		ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	END AS SLS_ORDER_DT,
	CASE WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::VARCHAR) != 8 THEN NULL
		ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
	END AS sls_ship_dt,
	CASE WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::VARCHAR) != 8 THEN NULL
		ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
	END AS sls_due_dt,
	case when SLS_SALES <= 0 or SLS_SALES is null or SLS_SALES != SLS_QUANTITY * abs(SLS_PRICE) 
		then SLS_QUANTITY * abs(SLS_PRICE) 
		else SLS_SALES
	end as SLS_SALES,
	sls_quantity, 
	case when SLS_PRICE <= 0 or SLS_PRICE is null 
		then SLS_SALES / coalesce(SLS_QUANTITY,0)
		else sls_price
	end as sls_price
FROM BRONZE.CRM_SALES_DETAILS

 

-- Insert into silver layer

drop table silver.crm_sales_details;

CREATE TABLE silver.crm_sales_details (
    sls_ord_num  VARCHAR(50),
    sls_prd_key  VARCHAR(50),
    sls_cust_id  INT,
    sls_order_dt DATE,
    sls_ship_dt  DATE,
    sls_due_dt   DATE,
    sls_sales    INT,
    sls_quantity INT,
    sls_price    INT,
	dwh_create_date TIMESTAMP DEFAULT NOW()
);

insert into silver.crm_sales_details(
	sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    sls_sales,
    sls_quantity,
    sls_price
)
SELECT 
	sls_ord_num, 
	sls_prd_key,
	sls_cust_id, 
	CASE WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::VARCHAR) != 8 THEN NULL
		ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
	END AS SLS_ORDER_DT,
	CASE WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::VARCHAR) != 8 THEN NULL
		ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
	END AS sls_ship_dt,
	CASE WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::VARCHAR) != 8 THEN NULL
		ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
	END AS sls_due_dt,
	case when SLS_SALES <= 0 or SLS_SALES is null or SLS_SALES != SLS_QUANTITY * abs(SLS_PRICE) 
		then SLS_QUANTITY * abs(SLS_PRICE) 
		else SLS_SALES
	end as SLS_SALES,
	sls_quantity, 
	case when SLS_PRICE <= 0 or SLS_PRICE is null 
		then SLS_SALES / coalesce(SLS_QUANTITY,0)
		else sls_price
	end as sls_price
FROM BRONZE.CRM_SALES_DETAILS


select * from silver.crm_sales_details


SELECT 
SLS_SALES,
SLS_QUANTITY,
SLS_PRICE,
SLS_SALES,
sls_price
FROM silver.CRM_SALES_DETAILS
WHERE SLS_SALES != SLS_QUANTITY * SLS_PRICE
OR SLS_SALES <= 0 OR SLS_QUANTITY <= 0 OR SLS_PRICE <= 0
OR SLS_SALES IS NULL OR SLS_QUANTITY IS NULL OR SLS_PRICE IS NULL



-- ====================================================================
-- Checking 'silver.erp_cust_az12'
-- ====================================================================


--  erp_cust_az12

Select 
*
from bronze.erp_cust_az12

-- Final Query

Select 
	case when cid like 'NAS%' then substring(cid,4,length(cid))
		else cid
	end as cid,
	case when bdate > current_date then NULL
		else bdate
	end as bdate,
	case when upper(trim(gen)) in ('F','FEMALE') then 'Female'
	 when upper(trim(gen)) in ('M','MALE') then 'Male'
	 else 'n/a'
end as gen
from bronze.erp_cust_az12



Select distinct
gen,
case when upper(trim(gen)) in ('F','FEMALE') then 'Female'
	 when upper(trim(gen)) in ('M','MALE') then 'Male'
	 else 'n/a'
end as gen
from bronze.erp_cust_az12



--  insert it into silver layer


insert into silver.erp_cust_az12(cid,bdate,gen)
Select 
	case when cid like 'NAS%' then substring(cid,4,length(cid))
		else cid
	end as cid,
	case when bdate > current_date then NULL
		else bdate
	end as bdate,
	case when upper(trim(gen)) in ('F','FEMALE') then 'Female'
	 when upper(trim(gen)) in ('M','MALE') then 'Male'
	 else 'n/a'
end as gen
from bronze.erp_cust_az12


select
*
from silver.erp_cust_az12


-- ====================================================================
-- Checking 'silver.erp_loc_a101'
-- ====================================================================


-- erp_loc_a101


select 
*
from bronze.erp_loc_a101

-- Data Standardization and Consistency Check
select distinct
cntry
from bronze.erp_loc_a101
order by cntry



-- insert into

insert into silver.erp_loc_a101(cid,cntry)

select 
replace(cid,'-','') as cid,
case when trim(cntry) = 'DE' then 'Germany'
	 when trim(cntry) in ('US','USA') then 'United States'
	 when trim(cntry) = '' or trim(cntry) is null then 'n/a'
	 else trim(cntry)
end as cntry
from bronze.erp_loc_a101



select 
*
from silver.erp_loc_a101


-- ====================================================================
-- Checking 'silver.erp_px_cat_g1v2'
-- ====================================================================

-- erp_px_cat_g1v2

select
*
from bronze.erp_px_cat_g1v2


--  Insert into silver

insert into silver.erp_px_cat_g1v2(id,cat,subcat,maintenance)
select
id,
cat,
subcat,
maintenance
from bronze.erp_px_cat_g1v2



select
*
from silver.erp_px_cat_g1v2


