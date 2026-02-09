CREATE VIEW product_report AS
with base_query AS 
(SELECT 
f.order_number,
f.order_date,
f.sales_amount,
f.quantity,
f.customer_key,
p.product_key,
p.product_name,
p.category,
p.subcategory,
p.cost
FROM fact_sales f
JOIN dim_products p
ON f.product_key = p.product_key
WHERE order_date IS NOT NULL)
,
product_aggregation AS (
SELECT 
product_key,
product_name,
category,
subcategory,
cost,
count( distinct order_number) as total_orders,
SUM(sales_amount) as total_sales,
SUM(quantity) as total_quantity,
COUNT(distinct customer_key) as total_customers,
MAX(order_date) as last_sale_date,
TIMESTAMPDIFF(MONTH, MIN(order_date),MAX(order_date)) as lifespan,
ROUND(SUM(sales_amount) / NULLIF(SUM(quantity), 0),0) AS avg_selling_price
FROM base_query
GROUP BY product_key,product_name,category,subcategory,cost)
select 
product_key,
product_name,
category,
subcategory,
cost,
last_sale_date,
TIMESTAMPDIFF(MONTH, last_sale_date,CURDATE()) as recency,
CASE 
	WHEN total_sales > 50000 THEN "High Performer"
	WHEN total_sales >= 10000 THEN "Mid-Performer"
	ELSE "Low Performer"
END as product_segment,
lifespan,
total_orders,
total_sales,
total_quantity,
total_customers,
avg_selling_price,
CASE 
	when total_orders = 0  then 0
	else ROUND(total_sales/total_orders,0)
END avg_order_value,
CASE 
	when lifespan = 0  then total_sales
	else ROUND(total_sales/lifespan,0)
END avg_monthly_spent
from product_aggregation