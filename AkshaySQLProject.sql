create database akshay;
use akshay;
#### Tables used ######
## brands
## customers
## orders
## brands

###### DATA CLEANING #######
select * from brands;
## Table 1 brands

## Check for nulls or blanks
SELECT * FROM brands WHERE brand_name IS NULL OR brand_name = '';


## Table 2 customers
select * from customers;
## Find NULL phone numbers
SELECT * FROM customers WHERE phone IS NULL;

## Standardize phone numbers (example: remove brackets and dashes)
SET SQL_SAFE_UPDATES = 0;
UPDATE customers
SET phone = REPLACE(REPLACE(REPLACE(phone, '(', ''), ')', ''), '-', '');

## Validate email format
SELECT * FROM customers WHERE email NOT LIKE '%@%.%';

## Remove duplicates
DELETE c1 FROM customers c1
JOIN customers c2 
  ON c1.first_name = c2.first_name 
 AND c1.last_name = c2.last_name 
 AND c1.email = c2.email
WHERE c1.customer_id > c2.customer_id;

## Table 3 orders
select * from orders;

## Find records with missing shipment info
SELECT * FROM orders WHERE shipped_date IS NULL;

## Convert invalid or default dates
UPDATE orders
SET shipped_date = NULL
WHERE shipped_date IN ('0000-00-00', '');

## Validate foreign keys (e.g., invalid store_id)
SELECT * FROM orders WHERE store_id NOT IN (SELECT store_id FROM stores);

## Ensure date consistency
SELECT * FROM orders
WHERE shipped_date < order_date;

## Table 4 stores
select * from stores;

-- Normalize phone numbers
UPDATE stores
SET phone = REPLACE(REPLACE(REPLACE(phone, '(', ''), ')', ''), '-', '');

-- Remove duplicates
DELETE s1 FROM stores s1
JOIN stores s2 
  ON s1.store_name = s2.store_name 
 AND s1.street = s2.street
WHERE s1.store_id > s2.store_id;

#### Data Validation & Summary Checks

## Count cleaned customers with valid emails and phones
SELECT COUNT(*) FROM customers
WHERE email LIKE '%@%.%' AND phone IS NOT NULL;

## Count valid orders with proper date logic
SELECT COUNT(*) FROM orders
WHERE order_date <= shipped_date;

## Orders per store (post-cleaning)
SELECT store_id, COUNT(*) AS total_orders
FROM orders
GROUP BY store_id;

######## EDA PROCESS ##########
##### 1. JOINED TABLE SETUP (for EDA)
## Create a joined view or use in subqueries
CREATE OR REPLACE VIEW full_orders AS
SELECT 
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_date,
    o.required_date,
    o.shipped_date,
    o.store_id,
    o.staff_id,
    c.first_name,
    c.last_name,
    c.city AS customer_city,
    c.state AS customer_state,
    s.store_name,
    s.city AS store_city,
    s.state AS store_state
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN stores s ON o.store_id = s.store_id;

#####  2. Total Number of Orders

SELECT COUNT(*) AS total_orders
FROM full_orders;

##### 3. Orders by Status

SELECT order_status, COUNT(*) AS total
FROM full_orders
GROUP BY order_status
ORDER BY total DESC;

##### 4. Orders by Store

SELECT store_name, COUNT(*) AS total_orders
FROM full_orders
GROUP BY store_name
ORDER BY total_orders DESC;

 ##### 5. Orders by Customer State

SELECT customer_state, COUNT(*) AS total_orders
FROM full_orders
GROUP BY customer_state
ORDER BY total_orders DESC;

##### 6. Orders with Missing Shipped Date

SELECT COUNT(*) AS missing_shipped_dates
FROM full_orders
WHERE shipped_date IS NULL;

 ##### 7. Average Shipping Delay (in days)

SELECT 
    ROUND(AVG(DATEDIFF(shipped_date, order_date)), 2) AS avg_shipping_delay_days
FROM full_orders
WHERE shipped_date IS NOT NULL;

##### 8. Monthly Order Volume

SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    COUNT(*) AS total_orders
FROM full_orders
GROUP BY month
ORDER BY month;

##### 9. Orders with Invalid Date Logic (Shipped before Ordered)

SELECT *
FROM full_orders
WHERE shipped_date < order_date;

#####  Top 10 Customers by Number of Orders

SELECT 
    customer_id,
    MAX(CONCAT(first_name, ' ', last_name)) AS customer_name,
    COUNT(*) AS order_count
FROM full_orders
GROUP BY customer_id
ORDER BY order_count DESC
LIMIT 10;


#################################################################################################################