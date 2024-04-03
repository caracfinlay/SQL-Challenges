--Question #1: 
--Identify installers who have participated in at least one installer competition by name.
SELECT i.name
FROM installers i
JOIN install_derby d
ON i.installer_id = d.installer_one_id OR i.installer_id = d.installer_two_id
GROUP BY 1; 

--Question #2: 
/*Write a solution to find the third transaction of every customer, 
where the spending on the preceding two transactions is lower than the 
spending on the third transaction. Only consider transactions that include an 
installation, and return the result table by customer_id in ascending order.*/

WITH 

order_prices AS (
    SELECT o.order_id, 
    o.customer_id, 
    (p.price * o.quantity) AS order_price, 
    i.install_date
FROM installs i
JOIN orders o
ON i.order_id = o.order_id
JOIN parts p
ON o.part_id = p.part_id)
,
ranked_orders AS(
SELECT customer_id,
  order_price,
  install_date,
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY install_date ASC) AS transaction_number
,LAG(order_price, 1) OVER (PARTITION BY customer_id ORDER BY install_date ASC) AS previous_order_price_1
,LAG(order_price, 2) OVER (PARTITION BY customer_id ORDER BY install_date ASC) AS previous_order_price_2
FROM order_prices
)

SELECT customer_id, 
order_price AS third_transaction_spend, 
install_date AS third_transaction_date
FROM ranked_orders
WHERE transaction_number = 3 
AND order_price > previous_order_price_1 
AND order_price > previous_order_price_2

--Question #3: 
/*Write a solution to report the most expensive part in each order. 
Only include installed orders. In case of a tie, report all parts with the 
maximum price. Order by order_id and limit the output to 5 rows.
Expected column names: order_id, part_id*/

SELECT o.order_id, 
   o.part_id
    --MAX(p.price),
    --o.quantity,
    --p.price * o.quantity AS order_price, 
    --i.install_date,
    --p.name AS part_name
FROM installs i
JOIN orders o
ON i.order_id = o.order_id
JOIN parts p
ON o.part_id = p.part_id
ORDER BY 1
LIMIT 5;

/* Question #4: 
Write a query to find the installers who have completed installations for at 
least four consecutive days. Include the installer_id, start date of the 
consecutive installations period and the end date of the consecutive 
installations period. 
Return the result table ordered by installer_id in ascending order.
Expected column names: installer_id, consecutive_start, consecutive_end */


WITH InstallationDiffs AS (
    SELECT
        installer_id,
        install_date,
        -- Calculate the difference in days between the current and previous installation date per installer
        install_date - LAG(install_date) OVER (
            PARTITION BY installer_id ORDER BY install_date
        ) AS day_diff
    FROM
        Installs
    GROUP BY installer_id, install_date
),
ConsecutiveInstallations AS (
    SELECT
        installer_id,
        install_date,
        -- Sum up instances where day_diff = 1 (consecutive days) to identify consecutive periods
        SUM(CASE WHEN day_diff = 1 THEN 0 ELSE 1 END) OVER (
            PARTITION BY installer_id ORDER BY install_date
        ) AS consecutive_period
    FROM
        InstallationDiffs
)
SELECT
    installer_id,
    MIN(install_date) AS consecutive_start,
    MAX(install_date) AS consecutive_end
FROM
    ConsecutiveInstallations
GROUP BY
    installer_id,
    consecutive_period
HAVING
    -- Ensure the period covers at least four consecutive days
    COUNT(consecutive_period) >= 4
ORDER BY
    installer_id;



















