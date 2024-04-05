/*
Question #1: 
Write a query to find the customer(s) with the most orders. Return only the preferred name.
*/

WITH t1 AS (SELECT COUNT(o.order_id) total_order_count, o.customer_id, c.preferred_name
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY o.customer_id, c.preferred_name)

,t2 AS(

SELECT MAX(total_order_count) max_order_count
FROM t1)

SELECT preferred_name
FROM t1
JOIN t2
ON t2.max_order_count = t1.total_order_count

-- alternative cleaner solution using RANK window function:

SELECT preferred_name
FROM 
(SELECT o.customer_id, c.preferred_name,
RANK() OVER(ORDER BY COUNT(o.order_id) DESC) AS rank
FROM orders o
JOIN customers c
ON c.customer_id = o.customer_id
GROUP BY 1,2) as ranked_customers

WHERE rank = 1;

/* 
Question #2: 
RevRoll does not install every part that is purchased. Some customers prefer to install parts themselves. This is a valuable line of business RevRoll wants to encourage by finding valuable self-install customers and sending them offers.

Return the customer_id and preferred name of customers who have made at least $2000 of purchases in parts that RevRoll did not install. 

Expected column names: customer_id, preferred_name
*/
WITH no_installs AS (SELECT *
FROM (SELECT c.customer_id, c.preferred_name, o.order_id, o.quantity, p.price, i.install_id
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
JOIN parts p
ON p.part_id = o.part_id
FULL OUTER JOIN installs i
ON o.order_id = i.order_id) AS all_installs
WHERE install_id IS NULL)

SELECT no_installs.customer_id, no_installs.preferred_name
FROM no_installs
GROUP BY 1, 2
HAVING SUM(price*quantity) >= 2000
;

/* 
Question #3: 
Report the id and preferred name of customers who bought an Oil Filter and Engine Oil but did not buy an Air Filter since we want to recommend these customers buy an Air Filter. Return the result table ordered by customer_id.

Expected column names: customer_id, preferred_name

*/

WITH customers AS (
  SELECT c.customer_id, c.preferred_name,
-- Note: MAX() works in this case because it reflects that a customer has bought 
-- the specified item at least once across all their purchase rows. 
MAX(CASE WHEN p.name = 'Oil Filter' THEN 1 ELSE 0 END) AS oil_filter,
MAX(CASE WHEN p.name = 'Air Filter' THEN 1 ELSE 0 END) AS air_filter,
MAX(CASE WHEN p.name = 'Engine Oil' THEN 1 ELSE 0 END) AS engine_oil
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
JOIN parts p
ON p.part_id = o.part_id
GROUP BY 1, 2)

SELECT customer_id, preferred_name
FROM customers
WHERE oil_filter = 1 AND engine_oil = 1 AND air_filter = 0
ORDER BY 1;

/*
Question #4: 
Write a solution to calculate the cumulative part summary for every part that the RevRoll team has installed.
The cumulative part summary for an part can be calculated as follows:
For each month that the part was installed, sum up the price*quantity in that month and the previous two months. This is the 3-month sum for that month. If a part was not installed in previous months, the effective price*quantity for those months is 0.
Do not include the 3-month sum for the most recent month that the part was installed.
Do not include the 3-month sum for any month the part was not installed.
Return the result table ordered by part_id in ascending order. In case of a tie, order it by month in descending order. Limit the output to the first 10 rows.
Expected column names: part_id, month, part_summary
*/



