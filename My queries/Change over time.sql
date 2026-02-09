SELECT 
YEAR(order_date) as order_year,
Month(order_date) as order_month,
sum(sales_amount) as yearly_sales,
count(distinct customer_key) as total_customers,
SUM(quantity) as total_quantity
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date),month(order_date)
ORDER BY YEAR(order_date),month(order_date)

SELECT 
DATE_FORMAT(order_date, '%Y-%m-01') AS order_month,
sum(sales_amount) as monthly_sales,
count(distinct customer_key) as total_customers,
SUM(quantity) as total_quantity
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
ORDER BY DATE_FORMAT(order_date, '%Y-%m-01')
