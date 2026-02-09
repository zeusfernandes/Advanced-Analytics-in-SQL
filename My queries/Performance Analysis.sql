WITH yearly_product_sales as 
(select 
YEAR(f.order_date) as order_year,
p.product_name,
SUM(f.sales_amount) as current_sales 
from fact_sales f
LEFT JOIN dim_products p
ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY YEAR(f.order_date),p.product_name
ORDER BY YEAR(f.order_date),p.product_name
)
select 
order_year,
product_name,
current_sales,
ROUND(AVG(current_sales) OVER(PARTITION BY product_name),2) as product_avg_sales,
(current_sales - ROUND(AVG(current_sales) OVER(PARTITION BY product_name),0))	as diff_avg, 
CASE 
	WHEN (current_sales - ROUND(AVG(current_sales) OVER(PARTITION BY product_name),0))>0 THEN "Above Avg"
    WHEN (current_sales - ROUND(AVG(current_sales) OVER(PARTITION BY product_name),0))<0 THEN "Below Avg"
    ELSE "Avg"
END as diff_avg_flag,
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) as prev_year_sales,
current_sales - (LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year)) as prev_year_sales_diff,
CASE 
	WHEN current_sales - (LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year))>0 THEN "Increase"
    WHEN current_sales - (LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year))<0 THEN "Decrease"
    ELSE "No Change"
END as prev_year_change
from yearly_product_sales
order by product_name, order_year