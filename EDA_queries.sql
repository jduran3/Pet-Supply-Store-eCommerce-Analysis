-- MAIN JOIN
--If we don't use LEFT on customers, the number of records goes down to 20,649
--since we have 4,416 customers as guests and we don't have information on them
SELECT COUNT(*) FROM sales s
JOIN products p USING (stock_code)
LEFT JOIN customers c USING (customer_id)
--25065

-- Total number of sales
SELECT COUNT(*) FROM sales
--25065

-- Top 5 customers (in terms of sales revenue)
SELECT s.customer_id as customer, SUM(round(sales::numeric,2)) as sales 
FROM sales s LEFT JOIN customers c USING (customer_id)
GROUP BY s.customer_id
ORDER BY SUM(sales::numeric) DESC
LIMIT 5;

-- Top 5 customers (in terms of # of sales transactions)
SELECT s.customer_id as customer, COUNT(sales) as no_of_sales 
FROM sales s LEFT JOIN customers c USING (customer_id)
GROUP BY s.customer_id
ORDER BY COUNT(sales) DESC
LIMIT 5;

-- Top 5 products (in terms of sales revenue)
SELECT p.description as product, SUM(sales::numeric) as sales
FROM SALES s JOIN PRODUCTS p USING (stock_code)
GROUP BY p.description
ORDER BY SUM(sales::numeric) DESC
LIMIT 5;

-- Top 5 products (in terms of # of sales transactions)
SELECT p.description as product, COUNT(sales) as no_of_sales
FROM SALES s JOIN PRODUCTS p USING (stock_code)
GROUP BY p.description
ORDER BY COUNT(sales) DESC
LIMIT 5;

-- What region, state and city had the highest revenue? (Top 5 for state and city)
SELECT region, SUM(sales::numeric) as sales 
FROM sales s LEFT JOIN customers c USING (customer_id)
GROUP BY region
HAVING region IS NOT NULL  --Filtering out guests
ORDER BY SUM(sales) DESC;

SELECT order_state as state, SUM(sales::numeric) as sales
FROM sales s LEFT JOIN customers c USING (customer_id)
GROUP BY order_state
HAVING order_state IS NOT NULL  --Filtering out guests
ORDER BY SUM(sales) DESC
LIMIT 5;

SELECT order_city as city, order_state as state, SUM(round(sales::numeric,2)) as sales
FROM sales s LEFT JOIN customers c USING (customer_id)
GROUP BY order_city, order_state
HAVING order_city IS NOT NULL  --Filtering out guests
ORDER BY SUM(sales) DESC
LIMIT 5;

-- Which products got more returns?
SELECT DISTINCT(p.description), 
SUM(ROUND(sales::numeric,2)) OVER (PARTITION BY p.description) as sales_returns
FROM SALES s JOIN PRODUCTS p USING (stock_code)
WHERE invoice_no = 'return'
ORDER BY sales_returns
LIMIT 5;


-- Which days of the month generate more sales?
SELECT day, SUM(sales::numeric) as sales
FROM sales
GROUP BY day
ORDER BY SUM(sales) DESC
LIMIT 5;

-- Which days of the month generate less sales?
SELECT day, SUM(sales::numeric) as sales
FROM sales
GROUP BY day
ORDER BY SUM(sales)
LIMIT 5;

-- Which days of the week generate more sales?
SELECT day_of_week, SUM(sales::numeric) as sales
FROM sales
GROUP BY day_of_week
ORDER BY SUM(sales) DESC

-- Which months generate more sales?
SELECT month, SUM(sales::numeric) as sales
FROM sales
GROUP BY month
ORDER BY SUM(sales) DESC

-- Top 5 highest shipping cost products?
SELECT description as product, weight, shipping_cost_1000_mile
FROM products 
ORDER BY shipping_cost_1000_mile DESC
LIMIT 5;

-- Correlation between product weight and shipping cost?
SELECT round(corr(weight, shipping_cost_1000_mile)::numeric,2) as weight_shipping_corr
FROM products 

-- Product association and confidence of buying product 1 given customer bought product 2
-- https://medium.com/@samratjain/explained-market-basket-analysis-using-sql-a7434f30e649
WITH product_association AS
(	
	SELECT product_1, product_2, COUNT(transaction) as transaction_count 
	FROM
	(
		SELECT s1.invoice_no as transaction, s1.description as product_1, s2.description as product_2, s2.invoice_no
		FROM sales s1, sales s2
		WHERE s1.invoice_no = s2.invoice_no
		AND s1.description <> s2.description
		AND s1.description < s2.description
		ORDER BY s1.description
	) as temp
	GROUP BY product_1, product_2
 ),
 transactions_per_product AS
 (
 	SELECT description as product, COUNT(*) as no_of_transactions
	FROM sales
	GROUP BY description
 )
 SELECT product_1, product_2,
 round(transaction_count/no_of_transactions::numeric,2) AS conf_p1_given_p2 -- conf(p1->p2) = support of p1 and p2/support of p2
 FROM product_association pa, transactions_per_product tp
 WHERE pa.product_2 = tp.product
 ORDER BY conf_p1_given_p2 DESC


-- Product association and confidence of buying product 2 given customer bought product 1
WITH product_association AS
(	
	SELECT product_1, product_2, COUNT(transaction) as transaction_count 
	FROM
	(
		SELECT s1.invoice_no as transaction, s1.description as product_1, s2.description as product_2, s2.invoice_no
		FROM sales s1, sales s2
		WHERE s1.invoice_no = s2.invoice_no
		AND s1.description <> s2.description
		AND s1.description < s2.description
		ORDER BY s1.description
	) as temp
	GROUP BY product_1, product_2
 ),
 transactions_per_product AS
 (
 	SELECT description as product, COUNT(*) as no_of_transactions
	FROM sales
	GROUP BY description
 )
 SELECT product_1, product_2,
 round(transaction_count/no_of_transactions::numeric,2) AS conf_p2_given_p1 -- conf(p2->p1) = support of p1 and p2/support of p1
 FROM product_association pa, transactions_per_product tp
 WHERE pa.product_1 = tp.product
 ORDER BY conf_p2_given_p1 DESC

--**********************************************************--
-- QUERY to see data types --
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'sales'
--**********************************************************--