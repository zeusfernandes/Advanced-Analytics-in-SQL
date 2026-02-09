with customer_segments as 
(SELECT 
c.customer_key,
SUM(f.sales_amount) as customer_sales,
MIN(order_date) as first_order,
MAX(order_date) as last_order,
TIMESTAMPDIFF(MONTH,MIN(order_date),MAX(order_date)) AS lifespan_months
from fact_sales f
JOIN dim_customers c
USING (customer_key)
GROUP BY c.customer_key)

SELECT 
customer_segment,
COUNT(customer_key) AS total_customers
FROM
	(
	SELECT 
	customer_key,
	CASE 
		WHEN lifespan_months > 12 AND customer_sales > 5000 THEN "VIP"
		WHEN lifespan_months > 12 AND customer_sales < 5000  THEN "Regular"
		ELSE "New"
	END as customer_segment
	FROM customer_segments) t
GROUP BY customer_segment
ORDER BY total_customers DESC
    