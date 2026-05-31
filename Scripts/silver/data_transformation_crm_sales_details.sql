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