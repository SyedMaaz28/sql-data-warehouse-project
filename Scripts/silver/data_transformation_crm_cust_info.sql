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
