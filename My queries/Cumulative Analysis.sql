SELECT
order_date,
total_sales,
avg_price,
SUM(total_sales) OVER(PARTITION BY order_date ORDER BY order_date) as running_sales,
ROUND(AVG(avg_price) OVER(PARTITION BY order_date ORDER BY order_date),2) as moving_average
FROM 
(SELECT 
DATE_FORMAT(order_date, '%Y-%m-01') AS order_date,
sum(sales_amount) as total_sales,
avg(price) as avg_price
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
) t