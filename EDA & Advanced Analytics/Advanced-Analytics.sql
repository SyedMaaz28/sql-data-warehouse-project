
-- ADVANCE ANALYTICS

-- 1) CHANGE OVER TIME TREND

-- {[MEASURE] BY [DATE DIMENSION]
-- TOTAL SALES BY YEAR
-- AVERAGE COST BY MONTH

SELECT
EXTRACT(YEAR FROM ORDER_DATE) AS YEAR,
SUM(SALES_AMOUNT)
FROM GOLD.FACT_SALES
WHERE ORDER_DATE IS NOT NULL
GROUP BY YEAR
ORDER BY YEAR



-- 2) CUMULATIVE ANALYSIS
--  Running Total sale by year
-- Moving Average of sales by months

select
order_date,
total_sales,
sum(total_sales) over(order by order_date) as Running_total_sales
from(
select
cast(DATE_TRUNC('MONTH',order_date) as date) as order_date,
sum(sales_amount) as total_sales
from gold.fact_sales
where order_date is not null
group by cast(DATE_TRUNC('MONTH',order_date) as date)
)t


select 
sum(sales_amount)
from gold.fact_sales



-- 3) Performance Analysis
-- Current Measure - Target Measure
-- Current Sales - Avg Sales

/*Q) Analyze the Yearly performance of Products by comparing their sales to both the
 average sales performance of the product and the previous year's sales */


with yearly_product_sales as(
	Select 
	extract(year from fs.order_date) as order_year,
	dp.product_name,
	sum(sales_amount) as total_sales
	from gold.fact_sales as fs
	left join gold.dim_products as dp
	on fs.product_key = dp.product_key
	where fs.order_date is not null 
	group by extract(year from fs.order_date), product_name
)

select 
	order_year,
	product_name,
	total_sales,
	-- Avg Sales
	avg(total_sales) over(partition by product_name) as avg_sales,
	total_sales - avg(total_sales) over(partition by product_name) as diff_avg,
	CASE WHEN total_sales - avg(total_sales) over(partition by product_name) > 0 then 'Above Avg'
		 WHEN total_sales - avg(total_sales) over(partition by product_name) < 0 then 'Below Avg'
		 else 'Avg'
	End as avg_change,
	-- Previous Year sales  -----> Year Over year Analysis
	lag(total_sales) over(partition by product_name order by order_year) as py_sales,
	total_sales - lag(total_sales) over(partition by product_name order by order_year) as diff_py,
	CASE WHEN total_sales - lag(total_sales) over(partition by product_name order by order_year) > 0 then 'Increase'
		 WHEN total_sales - lag(total_sales) over(partition by product_name order by order_year) < 0 then 'Decrease'
		 else 'No Change'
	End as py_change
from yearly_product_sales
order by product_name, order_year



-- 4) Part to Whole -----> Proportional Analysis
-- ([Measure] / Total[Measure]) * 100 By [Dimension]
-- (Sales / TotalSales) * 100 By Country

/* 
Which categories contribute the most to overall Sales
*/


with category_sales as(
Select 
category,
sum(sales_amount) as total_sales
from gold.fact_sales as fs
left join gold.dim_products as dp
on fs.product_key = dp.product_key
group by category)

select 
category,
total_sales,
sum(total_sales) over() overall_sales,
concat(round((total_sales / sum(total_sales) over()) * 100 , 2) , '%') as percentage_of_total
from category_sales
order by total_sales desc





-- 5) Data Segmentation 

with products_segments as(
Select 
	product_key,
	product_name,
	product_cost,
	case when product_cost < 100 then 'Below 100'
		 when product_cost between 100 and 500 then '100-500'
		 when product_cost between 500 and 1000 then '500-1000'
		 else 'Above 1000'
	end cost_range
from gold.dim_products)

select
cost_range,
count(product_key) as total_products
from products_segments
group by cost_range
order by total_products desc


/*Group customers into three segments based on their spending behavior:
  - VIP: Customers with at least 12 months of history and spending more than €5,000.
  - Regular: Customers with at least 12 months of history but spending €5,000 or less.
  - New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group
*/


WITH CUSTOMER_SPENDING AS (
SELECT
C.CUSTOMER_KEY,
SUM(F.SALES_AMOUNT) AS TOTAL_SPENDING,
MIN(ORDER_DATE) AS FIRST_ORDER,
MAX(ORDER_DATE) AS LAST_ORDER,
DATE_PART('month', AGE(MAX(order_date), MIN(order_date))) AS LIFESPAN
FROM GOLD.FACT_SALES AS F
LEFT JOIN GOLD.DIM_CUSTOMERS AS C
ON F.CUSTOMER_KEY = C.CUSTOMER_KEY
GROUP BY C.CUSTOMER_KEY
)


SELECT
CUSTOMER_SEGMENT,
COUNT(CUSTOMER_KEY)
FROM(
	SELECT 
		CUSTOMER_KEY,
		CASE WHEN LIFESPAN >= 10 AND TOTAL_SPENDING > 5000 THEN 'VIP'
		     WHEN LIFESPAN >= 10 AND TOTAL_SPENDING <= 5000 THEN 'REGULAR'
			 ELSE 'NEW'
		END AS CUSTOMER_SEGMENT
	FROM CUSTOMER_SPENDING
)T
GROUP BY CUSTOMER_SEGMENT


















