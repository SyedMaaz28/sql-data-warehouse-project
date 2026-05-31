CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time       TIMESTAMP;
    end_time         TIMESTAMP;
    batch_start_time TIMESTAMP;
    batch_end_time   TIMESTAMP;
BEGIN

    batch_start_time := NOW();

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer';
    RAISE NOTICE '================================================';

    ----------------------------------------------------------------
    -- CRM TABLES
    ----------------------------------------------------------------

    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading CRM Tables';
    RAISE NOTICE '------------------------------------------------';

    ----------------------------------------------------------------
    -- crm_cust_info
    ----------------------------------------------------------------

    start_time := NOW();

    RAISE NOTICE '>> Truncating Table: silver.crm_cust_info';

    TRUNCATE TABLE silver.crm_cust_info;

    RAISE NOTICE '>> Inserting Data Into: silver.crm_cust_info';

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
	where flag_last = 1;

	end_time := NOW();

    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> -------------';

    ----------------------------------------------------------------
    -- crm_prd_info
    ----------------------------------------------------------------

    start_time := NOW();

    RAISE NOTICE '>> Truncating Table: silver.crm_prd_info';

    TRUNCATE TABLE silver.crm_prd_info;

    RAISE NOTICE '>> Inserting Data Into: silver.crm_prd_info';

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
		else 'n/a'    -- Map product line codes to Descriptive Values
	end as prd_line,
	cast(prd_start_dt as date) as prd_start_dt,  
	cast(lead(prd_start_dt) over(partition by prd_key order by prd_start_dt) - INTERVAL '1 day' as date) AS prd_end_dt
	FROM BRONZE.crm_prd_info;

    end_time := NOW();

    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> -------------';

 ----------------------------------------------------------------
    -- crm_sales_details
    ----------------------------------------------------------------

    start_time := NOW();

    RAISE NOTICE '>> Truncating Table: silver.crm_sales_details';

    TRUNCATE TABLE silver.crm_sales_details;

    RAISE NOTICE '>> Inserting Data Into: silver.crm_sales_details';

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
	FROM BRONZE.CRM_SALES_DETAILS;


    end_time := NOW();

    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> -------------';


    ----------------------------------------------------------------
    -- ERP TABLES
    ----------------------------------------------------------------

    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading ERP Tables';
    RAISE NOTICE '------------------------------------------------';

    ----------------------------------------------------------------
    -- erp_loc_a101
    ----------------------------------------------------------------

    start_time := NOW();

    RAISE NOTICE '>> Truncating Table: silver.erp_loc_a101';

    TRUNCATE TABLE silver.erp_loc_a101;

    RAISE NOTICE '>> Inserting Data Into: silver.erp_loc_a101';

	insert into silver.erp_loc_a101(cid,cntry)
	
	select 
	replace(cid,'-','') as cid,
	case when trim(cntry) = 'DE' then 'Germany'
		 when trim(cntry) in ('US','USA') then 'United States'
		 when trim(cntry) = '' or trim(cntry) is null then 'n/a'
		 else trim(cntry)
	end as cntry
	from bronze.erp_loc_a101;


    end_time := NOW();

    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> -------------';


    ----------------------------------------------------------------
    -- erp_cust_az12
    ----------------------------------------------------------------

    start_time := NOW();

    RAISE NOTICE '>> Truncating Table: silver.erp_cust_az12';

    TRUNCATE TABLE silver.erp_cust_az12;

    RAISE NOTICE '>> Inserting Data Into: silver.erp_cust_az12';
	
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
	from bronze.erp_cust_az12;

    end_time := NOW();

    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> -------------';

    ----------------------------------------------------------------
    -- erp_px_cat_g1v2
    ----------------------------------------------------------------

    start_time := NOW();

    RAISE NOTICE '>> Truncating Table: silver.erp_px_cat_g1v2';

    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    RAISE NOTICE '>> Inserting Data Into: silver.erp_px_cat_g1v2';

	insert into silver.erp_px_cat_g1v2(id,cat,subcat,maintenance)
	select
	id,
	cat,
	subcat,
	maintenance
	from bronze.erp_px_cat_g1v2;

    end_time := NOW();

    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> -------------';


    ----------------------------------------------------------------
    -- FINAL MESSAGE
    ----------------------------------------------------------------

    batch_end_time := NOW();

    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Loading Bronze Layer is Completed';
    RAISE NOTICE 'Total Load Duration: % seconds',
        EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));
    RAISE NOTICE '==========================================';

EXCEPTION
    WHEN OTHERS THEN

        RAISE NOTICE '==========================================';
        RAISE NOTICE 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
        RAISE NOTICE 'Error Message: %', SQLERRM;
        RAISE NOTICE '==========================================';

END;
$$;


CALL silver.load_silver();


SELECT
* 
FROM SILVER.CRM_CUST_INFO
