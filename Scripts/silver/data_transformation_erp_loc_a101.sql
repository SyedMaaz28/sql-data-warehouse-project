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
