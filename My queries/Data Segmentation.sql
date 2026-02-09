WITH product_segment as (
SELECT
product_key,
product_name,
cost,
CASE
	WHEN cost < 100 THEN "Below 100"
    WHEN cost BETWEEN 100 AND 500 THEN "100-500"
    WHEN cost BETWEEN 500 AND 1000 THEN "500-1000"
    ELSE "Above 1000"
END cost_range
FROM dim_products
)
SELECT
cost_range,
COUNT(product_key) as total_products 
FROM product_segment
GROUP BY cost_range
ORDER BY  total_products DESC