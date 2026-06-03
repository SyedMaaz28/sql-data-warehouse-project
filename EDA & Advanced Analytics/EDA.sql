
select 
* 
from information_schema.tables


select 
* 
from information_schema.columns
where table_name = 'dim_customers'
order by ordinal_position


--  Exlore all Countries our customers come from

select distinct
country
from gold.dim_customers

-- Explore all categories 'The Major Distinct'

select distinct
category,
subcategory,
product_name
from gold.dim_products
order by 1,2,3

--  Find Total sales

select 
sum(sales_amount)
from gold.fact_sales

-- Find How many itmes are sold

select 
sum(quantity)
from gold.fact_sales


-- Find average selling price

select
avg(price)
from gold.fact_sales

-- Find the total number of orders

select 
count(order_number)
from gold.fact_sales

select 
count(distinct order_number)
from gold.fact_sales

-- Find the total number of Products

select 
count(product_name)
from gold.dim_products


-- Find the total number of Customers

select
count(customer_key)
from gold.dim_customers

-- Find the total number of Customers that placed an order

select
count(distinct customer_key)
from gold.fact_sales



--  Generate a report that shows all key metrics of the business

select 'Total Sales' as measure_name, sum(sales_amount) as measure_value from gold.fact_sales
UNION ALL 
select 'Total Quantity' as measure_name, sum(quantity) as measure_value from gold.fact_sales
Union all
select 'Average Selling Price' as measure_name, avg(price) as measure_value from gold.fact_sales
Union all
select 'Total Number of Orders' as measure_name, count(distinct order_number) as measure_value from gold.fact_sales
Union all
select 'Total Number of Products' as measure_name, count(product_name) as measure_value from gold.dim_products
Union all
select 'Total Number of Customers' as measure_name, count(customer_key) as measure_value from gold.dim_customers


-- Measures by Dimensions 

-- Total Customers by countries

select
country,
count(customer_key)
from gold.dim_customers
group by country
-- union all
-- select 
-- 'Total Customers',
-- count(customer_key)
-- from gold.dim_customers



-- Total Customers by gender

select
gender,
count(customer_key)
from gold.dim_customers
group by gender



-- Total Product by category

select
category,
count(product_name) as Total_products
from gold.dim_products
group by category
order by Total_products desc


-- WHat is the Avg cost in each Country

select 
dp.category,
avg(product_cost)
from gold.dim_products as dp
group by category


select * from gold.dim_products
select * from gold.fact_sales


--  Top N | Bottom N Measures

--  Which 5 Products generates the Highest Revenue

Select
dp.product_name,
sum(fs.sales_amount) as revenue
from gold.fact_sales as fs 
left join gold.dim_products as dp
on dp.product_key = fs.product_key
group by dp.product_name
order by revenue desc
limit 5

--  TOP 5 Products WOPRST PRODUCTS IN TERMS OF SALES

Select
dp.product_name,
sum(fs.sales_amount) as revenue
from gold.fact_sales as fs 
left join gold.dim_products as dp
on dp.product_key = fs.product_key
group by dp.product_name
order by revenue ASC
limit 5








