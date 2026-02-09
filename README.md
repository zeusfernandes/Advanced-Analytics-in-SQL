# 📊 SQL Advanced Analytics – Data Warehouse Project

This project demonstrates **end-to-end SQL-based advanced analytics** using a **star schema data warehouse** design. It covers data modeling, data loading challenges, and multiple analytical techniques commonly used in business intelligence and analytics roles.

The goal of this project is to showcase **strong SQL skills**, including **window functions, CTEs, aggregations, segmentation logic, and KPI reporting**, all wrapped in a clean, portfolio-ready format.

---

## 🏗️ Data Warehouse Design

**Database Name:** `DataWarehouseAnalytics`

The schema follows a classic **star schema**:

- **Dimension Tables**
  - `dim_customers`
  - `dim_products`
- **Fact Table**
  - `fact_sales`

### 📁 Table Structures

#### dim_customers
| Column Name | Description |
|------------|------------|
| customer_key | Surrogate key |
| customer_id | Source system ID |
| customer_number | Business identifier |
| first_name | Customer first name |
| last_name | Customer last name |
| country | Country |
| marital_status | Marital status |
| gender | Gender |
| birthdate | Date of birth |
| create_date | Customer creation date |

#### dim_products
| Column Name | Description |
|------------|------------|
| product_key | Surrogate key |
| product_id | Source system ID |
| product_number | Product code |
| product_name | Product name |
| category_id | Category ID |
| category | Product category |
| subcategory | Product subcategory |
| maintenance | Maintenance type |
| cost | Product cost |
| product_line | Product line |
| start_date | Product start date |

#### fact_sales
| Column Name | Description |
|------------|------------|
| order_number | Order identifier |
| product_key | FK → dim_products |
| customer_key | FK → dim_customers |
| order_date | Order date |
| shipping_date | Shipping date |
| due_date | Due date |
| sales_amount | Sales value |
| quantity | Units sold |
| price | Unit price |

---

## 🗄️ Database & Table Creation

```sql
CREATE DATABASE IF NOT EXISTS DataWarehouseAnalytics;
```

```sql
CREATE TABLE dim_customers (
  customer_key INT,
  customer_id INT,
  customer_number VARCHAR(50),
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  country VARCHAR(50),
  marital_status VARCHAR(50),
  gender VARCHAR(50),
  birthdate DATE,
  create_date DATE
);
```

```sql
CREATE TABLE dim_products (
  product_key INT,
  product_id INT,
  product_number VARCHAR(50),
  product_name VARCHAR(50),
  category_id VARCHAR(50),
  category VARCHAR(50),
  subcategory VARCHAR(50),
  maintenance VARCHAR(50),
  cost INT,
  product_line VARCHAR(50),
  start_date DATE
);
```

```sql
CREATE TABLE fact_sales (
  order_number VARCHAR(50),
  product_key INT,
  customer_key INT,
  order_date DATE,
  shipping_date DATE,
  due_date DATE,
  sales_amount INT,
  quantity TINYINT,
  price INT
);
```

---

## 📥 Data Import Challenge

While importing CSV files using `LOAD DATA INFILE`, the following MySQL error was encountered:

> **Error Code: 1290** – The MySQL server is running with the `--secure-file-priv` option.

### 🔧 Resolution Attempted
- Checked allowed directory using:
```sql
SHOW VARIABLES LIKE 'secure_file_priv';
```
- Moved CSV files to the permitted directory

Despite this, the issue persisted. Therefore, **manual data import** was performed using MySQL Workbench’s table data import wizard.

> ⚠️ This step can be time-consuming for large datasets but ensures compatibility across environments.

---

## 📈 Advanced Analytics Performed

### 1️⃣ Change Over Time Analysis
Tracks business growth over time (monthly aggregation).

```sql
SELECT
  DATE_FORMAT(order_date, '%Y-%m-01') AS order_month,
  SUM(sales_amount) AS total_sales,
  COUNT(DISTINCT customer_key) AS total_customers,
  SUM(quantity) AS total_quantity
FROM fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
ORDER BY order_month;
```

---

### 2️⃣ Cumulative Analysis (Running Total & Moving Average)

```sql
SELECT
  order_date,
  total_sales,
  avg_price,
  SUM(total_sales) OVER (ORDER BY order_date) AS running_sales,
  ROUND(AVG(avg_price) OVER (ORDER BY order_date), 2) AS moving_average
FROM (
  SELECT
    DATE_FORMAT(order_date, '%Y-%m-01') AS order_date,
    SUM(sales_amount) AS total_sales,
    AVG(price) AS avg_price
  FROM fact_sales
  WHERE order_date IS NOT NULL
  GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
) t;
```

---

### 3️⃣ Performance Analysis (YoY & Benchmark Comparison)
Compares yearly product sales against:
- Product average sales
- Previous year sales

```sql
WITH yearly_product_sales AS (
  SELECT
    YEAR(f.order_date) AS order_year,
    p.product_name,
    SUM(f.sales_amount) AS current_sales
  FROM fact_sales f
  JOIN dim_products p ON f.product_key = p.product_key
  WHERE f.order_date IS NOT NULL
  GROUP BY YEAR(f.order_date), p.product_name
)
SELECT
  order_year,
  product_name,
  current_sales,
  ROUND(AVG(current_sales) OVER (PARTITION BY product_name), 2) AS product_avg_sales,
  current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
  LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS prev_year_sales
FROM yearly_product_sales;
```

---

### 4️⃣ Part-to-Whole Analysis (Category Contribution)

```sql
WITH category_sales AS (
  SELECT
    p.category,
    SUM(f.sales_amount) AS total_sales
  FROM fact_sales f
  JOIN dim_products p ON f.product_key = p.product_key
  GROUP BY p.category
)
SELECT
  category,
  total_sales,
  SUM(total_sales) OVER () AS overall_sales,
  CONCAT(ROUND((total_sales / SUM(total_sales) OVER ()) * 100, 2), '%') AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC;
```

---

### 5️⃣ Data Segmentation

#### 🧱 Product Cost Segmentation

```sql
SELECT
  CASE
    WHEN cost < 100 THEN 'Below 100'
    WHEN cost BETWEEN 100 AND 500 THEN '100-500'
    WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
    ELSE 'Above 1000'
  END AS cost_range,
  COUNT(product_key) AS total_products
FROM dim_products
GROUP BY cost_range;
```

#### 👥 Customer Segmentation

- **VIP**: >12 months lifespan & sales > 5000
- **Regular**: >12 months lifespan & sales ≤ 5000
- **New**: <12 months lifespan

```sql
WITH customer_segments AS (
  SELECT
    customer_key,
    SUM(sales_amount) AS customer_sales,
    TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan_months
  FROM fact_sales
  GROUP BY customer_key
)
SELECT
  CASE
    WHEN lifespan_months > 12 AND customer_sales > 5000 THEN 'VIP'
    WHEN lifespan_months > 12 THEN 'Regular'
    ELSE 'New'
  END AS customer_segment,
  COUNT(customer_key) AS total_customers
FROM customer_segments
GROUP BY customer_segment;
```

---

## 📑 Analytical Views

### 👤 Customer Report View
Captures customer behavior, KPIs, segmentation & lifecycle metrics.

```sql
CREATE VIEW customer_report AS
SELECT * FROM (...);
```

**KPIs Included:**
- Total orders, sales, quantity, products
- Recency
- Lifespan
- Average order value
- Average monthly spend
- Age & customer segment

---

### 📦 Product Report View
Summarizes product-level performance and revenue behavior.

```sql
CREATE VIEW product_report AS
SELECT * FROM (...);
```

**KPIs Included:**
- Product segmentation (High / Mid / Low performer)
- Recency
- Lifespan
- Average selling price
- Average order value
- Average monthly revenue

---

## 🧠 Key Skills Demonstrated

- Star schema data modeling
- Advanced SQL analytics
- Window functions (LAG, AVG, SUM OVER)
- Common Table Expressions (CTEs)
- Business-oriented segmentation logic
- KPI-driven reporting

---

## 🚀 How This Project Can Be Extended

- Add indexing for performance optimization
- Build dashboards using Power BI / Tableau
- Automate ETL using Python or Airflow
- Add incremental loading logic

---

## 🙏 Data Source Attribution

The dataset and project inspiration are credited to the **"Data with Baraa"** YouTube channel. This project was built for learning, practice, and portfolio demonstration purposes, with full credit to the original content creator.

---

## 📌 Author
**Zeus Mark Fernandes**  
Data Analyst | SQL | Power BI | Analytics

---


