/*
=============================================================================
Customer Report
=============================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
    2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
        - total orders
        - total sales
        - total quantity purchased
        - total products
        - lifespan (in months)
    4. Calculates valuable KPIs:
        - recency (months since last order)
        - average order value
        - average monthly spend
=============================================================================
*/
CREATE VIEW gold.report_customers as

WITH BASE_QUERY AS
(
/* 
1) BASE QUERY: RETRIVE ALL CORE COLUMNS FROM TABLES
*/
SELECT
    f.order_number,
    f.product_key,
    f.order_date,
    f.sales_amount,
    f.quantity,
    c.customer_key,
    c.customer_number,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.birthdate,
    DATE_PART('year', AGE(CURRENT_DATE,c.birthdate)) age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
),

CUSTOMER_AGGREGATION AS
(
/* 
2) CUSTOMER AGGREGATIONS : SUMMARIZES KEY METRICS AT THE CUSTOMER LEVEL
*/
SELECT 
	customer_key,
    customer_number,
    customer_name,
    age,
	count(distinct order_number) as total_orders,
	sum(sales_amount) as total_sales,
	sum(quantity) as total_quantity,
	count(distinct product_key) as total_products,
	max(order_date) as last_order_date,
	DATE_PART('month', AGE(MAX(order_date), MIN(order_date))) AS LIFESPAN
FROM BASE_QUERY
group by 
customer_key,
customer_number,
customer_name,
age 
)


SELECT 
	customer_key,
    customer_number,
    customer_name,
    age,	
	CASE WHEN AGE < 20 THEN 'UNDER 20'
		 WHEN AGE BETWEEN 20 AND 29 THEN '20-29'
		 WHEN AGE BETWEEN 30 AND 39 THEN '30-39'
		 WHEN AGE BETWEEN 40 AND 49 THEN '40-49'
		 ELSE '50 AND ABOVE'
	END AS AGE_SEGMENT,
	
	CASE WHEN LIFESPAN >= 10 AND total_sales > 5000 THEN 'VIP'
		 WHEN LIFESPAN >= 10 AND total_sales <= 5000 THEN 'REGULAR'
		 ELSE 'NEW'
	END AS CUSTOMER_SEGMENT,
	total_orders,
	total_sales,
	-- Compute Avg order value
	total_sales / total_orders as avg_order_value,
	total_quantity,
	total_products,
	last_order_date,
	(DATE_PART('year', AGE(CURRENT_DATE, last_order_date)) * 12)
	+
	DATE_PART('month', AGE(CURRENT_DATE, last_order_date)) AS recency,
	LIFESPAN,
	-- Compute avg monthly spend
	case when lifespan = 0 then total_sales
		else total_sales/lifespan
	end as avg_monthly_sp
FROM CUSTOMER_AGGREGATION








select * from gold.report_customers
















