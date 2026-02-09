CREATE VIEW customer_report AS
with base_query as (
-- BASE QUERY ====RETRIEVES CORE COLUMNS FROM TABLES
SELECT 
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
concat(c.first_name,' ',c.last_name) as customer_name,
c.birthdate,
TIMESTAMPDIFF(YEAR, c.birthdate, CURDATE()) AS age
FROM fact_sales f
JOIN dim_customers c
ON f.customer_key = c.customer_key
WHERE order_date IS NOT NULL
),
customer_aggregation AS (
-- CUSTOMER AGGREGATION ==== SUMMARIZES MEASURES AT A CUSTOMER LEVEL
SELECT 
customer_key,
customer_number,
customer_name,
age,
COUNT(distinct order_number) as total_orders,
SUM(sales_amount) as total_sales,
SUM(quantity) as total_quantity,
COUNT(distinct product_key) as total_products,
MAX(order_date) as last_order,
TIMESTAMPDIFF(MONTH, MIN(order_date),MAX(order_date)) as lifespan
from base_query
GROUP BY customer_key,customer_number,customer_name,age)

SELECT
customer_key,
customer_number,
customer_name,
age,
CASE 
	WHEN age < 20 THEN "Under 20"
    WHEN age BETWEEN 20 AND 29 THEN "20-29"
    WHEN age BETWEEN 30 AND 39 THEN "30-39"
    WHEN age BETWEEN 40 AND 49 THEN "40-49"
	ELSE "Above 50"
END as age_group,
total_orders,
total_sales,
total_quantity,
total_products,
last_order,
TIMESTAMPDIFF(month, last_order, CURDATE()) AS recency,
lifespan,
CASE 
	WHEN lifespan > 12 AND total_sales > 5000 THEN "VIP"
	WHEN lifespan > 12 AND total_sales < 5000  THEN "Regular"
	ELSE "New"
END as customer_segment,
-- AVG  ORDER VALUE PER CUSTOMER
CASE 
	when total_orders = 0  then 0
	else ROUND(total_sales/total_orders,0)
END avg_order_value,
CASE 
	when lifespan = 0  then total_sales
	else ROUND(total_sales/lifespan,0)
END avg_monthly_spent

FROM customer_aggregation
