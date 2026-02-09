WITH category_sales AS (select 
category,
SUM(f.sales_amount) as total_sales
from fact_sales f
JOIN dim_products p 
ON p.product_key = f.product_key
GROUP BY category
)
select 
category,
total_sales,
SUM(total_sales) OVER() as overall_sales,
concat(ROUND((total_sales/SUM(total_sales) OVER())*100,2) , '%') as percentage_of_total
FROM category_sales
ORDER BY total_sales DESC