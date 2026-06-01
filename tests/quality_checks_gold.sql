
--  Gold Layer
-- silver.crm_cust_info
select
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	ci.cst_gndr,
	ci.cst_create_date
from silver.crm_cust_info as ci
-- silver.erp_cust_az12
select 
cid,
bdate,
gen
from silver.erp_cust_az12 as ca
-- silver.erp_loc_a101
select
cid,
cntry
from silver.erp_loc_a101 as la


-- Checking Genders
select distinct
	ci.cst_gndr,
	ca.gen,
	case when ci.cst_gndr != 'n/a' then ci.cst_gndr -- CRM IS THE MASTER FOR GENDER INFO
		 when ci.cst_gndr = 'n/a' then ca.gen
		else coalesce(ca.gen,'n/a')
	end as new_gen
from silver.crm_cust_info as ci
left join silver.erp_cust_az12 as ca
on ci.cst_key = ca.cid
left join silver.erp_loc_a101 as la
on ci.cst_key = la.cid

-- dim_product_views


select
prd_id,
cat_id,
prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt
from silver.crm_prd_info


select
id,
cat,
subcat,
maintenance
from silver.erp_px_cat_g1v2
