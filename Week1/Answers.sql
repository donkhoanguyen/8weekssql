use dannys_diner;


-- 1. What is the total amount each customer spent at the restaurant?
SELECT sales.customer_id, SUM(menu.price) AS total_spent
FROM sales
INNER JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT(order_date)) AS days_visited
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH rank_table AS(
    SELECT order_date, customer_id, DENSE_RANK() OVER
    (ORDER BY order_date) AS most_ordered
    FROM sales
    )
SELECT DISTINCT sales.customer_id,
menu.product_name,
sales.order_date
FROM sales
INNER JOIN  menu
ON sales.product_id = menu.product_id
WHERE sales.order_date IN
    (SELECT order_date
    FROM rank_table
    WHERE most_ordered = 1);
    
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT menu.product_name, COUNT(*) as count_times
FROM sales
INNER JOIN menu
ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY count_times DESC
limit 1;

-- 5. Which item was the most popular for each customer?
WITH rank_table AS(
SELECT
    sales.customer_id,
    menu.product_name,
    COUNT(sales.product_id) as num_purchased,
    DENSE_RANK()
    OVER (PARTITION BY customer_id ORDER BY COUNT(sales.product_id) DESC) AS popularity_rank
FROM sales
INNER JOIN menu
ON menu.product_id = sales.product_id
GROUP BY sales.customer_id, menu.product_name)

SELECT
customer_id,
product_name,
num_purchased
FROM rank_table
WHERE popularity_rank = 1
;
    
-- 6. Which item was purchased first by the customer after they became a member?
with cte AS(
    SELECT
        sales.customer_id,
        sales.order_date,
        members.join_date,
        DENSE_RANK() 
        OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date) AS time_rank
    FROM sales
    INNER JOIN members
    ON sales.customer_id = members.customer_id
    WHERE sales.order_date >= members.join_date
)

SELECT DISTINCT
	sales.customer_id,
	menu.product_name
FROM sales
INNER JOIN menu
ON menu.product_id = sales.product_id
INNER JOIN cte
ON sales.customer_id = cte.customer_id
AND sales.order_date = cte.order_date
WHERE cte.time_rank = 1;

-- 7. Which item was purchased just before the customer became a member?
with cte AS(
    SELECT
        sales.customer_id,
        sales.order_date,
        members.join_date,
        DENSE_RANK() 
        OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date desc) AS time_rank
    FROM sales
    INNER JOIN members
    ON sales.customer_id = members.customer_id
    WHERE sales.order_date < members.join_date
)

SELECT DISTINCT
	sales.customer_id,
	menu.product_name,
    sales.order_date
FROM sales
INNER JOIN menu
ON menu.product_id = sales.product_id
INNER JOIN cte
ON sales.customer_id = cte.customer_id
AND sales.order_date = cte.order_date
WHERE cte.time_rank = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
WITH cte AS(
    SELECT
        sales.customer_id,
        sales.order_date,
        sales.product_id,
        menu.price,
        members.join_date
    FROM sales
    INNER JOIN members
    ON sales.customer_id = members.customer_id
    INNER JOIN menu
    ON sales.product_id = menu.product_id
    WHERE sales.order_date < members.join_date
)
    SELECT
        customer_id,
        COUNT(*) AS total_items,
        SUM(price) AS total_spent
    FROM cte
    GROUP BY customer_id;
    
-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH cte AS(
    SELECT
        t1.customer_id,
        t2.product_name,
        t2.price,
        CASE WHEN product_name = 'sushi' THEN 20
        ELSE 10 END AS point
    FROM sales AS t1
    INNER JOIN menu AS t2
    ON t1.product_id = t2.product_id
)
    SELECT
        customer_id,
        SUM(point*price) AS total_point
    FROM cte
    GROUP BY customer_id;
    
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH cte AS(
    SELECT
        sales.customer_id,
        sales.order_date,
        sales.product_id,
        menu.product_name,
        menu.price,
        members.join_date,
        DATE_ADD(members.join_date, interval 6 day) AS bonus_date
    FROM sales
    INNER JOIN menu
    ON sales.product_id = menu.product_id
    INNER JOIN members
    ON sales.customer_id = members.customer_id
    WHERE sales.order_date >= members.join_date
),
cte2 AS(
    SELECT
    customer_id,
    price,
    order_date,
    bonus_date,
    product_name,
    CASE
    WHEN order_date <= bonus_date THEN 20
    WHEN order_date > bonus_date AND product_name = 'sushi' THEN 20
    ELSE 10 END AS point
    FROM cte
)
SELECT
    customer_id,
    SUM(point * price) AS total_point
FROM cte2
WHERE order_date < '2021-01-31'
GROUP BY customer_id;

-- BONUS

-- join all
SELECT
    sales.customer_id,
    sales.order_date,
    menu.product_name,
    menu.price,
    CASE
    WHEN sales.order_date >= members.join_date THEN 'Y'
    ELSE 'N' END AS member
FROM sales
INNER JOIN menu
ON sales.product_id = menu.product_id
LEFT JOIN members
ON sales.customer_id = members.customer_id
ORDER BY customer_id, order_date, product_name

-- rank all
WITH cte AS(
    SELECT
    sales.customer_id,
    sales.order_date,
    menu.product_name,
    menu.price,
    CASE
    WHEN sales.order_date >= members.join_date THEN 'Y'
    ELSE 'N' END AS member
FROM sales
INNER JOIN menu
ON sales.product_id = menu.product_id
LEFT JOIN members
ON sales.customer_id = members.customer_id
)
SELECT
    *,
    CASE
    WHEN member = 'N' THEN NULL
    ELSE DENSE_RANK() OVER(
    PARTITION BY customer_id,member
    ORDER BY order_date
    )
    END AS rank
FROM cte

