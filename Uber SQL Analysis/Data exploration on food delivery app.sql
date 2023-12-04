-- Calculate the total amount spent by each customer on Zomato
SELECT s.userid, SUM(p.price) AS total_amount
FROM sales s
JOIN product p ON s.product_id = p.product_id
GROUP BY s.userid;

-- Total number of days each customer visited Zomato
SELECT s.userid, COUNT(DISTINCT s.created_date) AS distinct_days
FROM sales s
GROUP BY s.userid;

-- First product purchased by each customer
SELECT s.userid, s.created_date, p.product_name
FROM (
    SELECT RANK() OVER (PARTITION BY userid ORDER BY created_date) AS rnk, 
           userid, created_date, product_id
    FROM sales
) s
JOIN product p ON s.product_id = p.product_id
WHERE s.rnk = 1;

-- Most purchased product for each customer
SELECT s.userid, s.product_id, COUNT(s.product_id) AS purchase_count
FROM sales s
JOIN (
    SELECT userid, product_id, RANK() OVER(PARTITION BY userid ORDER BY COUNT(product_id) DESC) AS rnk
    FROM sales
    GROUP BY userid, product_id
) AS ranked_sales ON s.userid = ranked_sales.userid AND s.product_id = ranked_sales.product_id
WHERE ranked_sales.rnk = 1
GROUP BY s.userid, s.product_id;

-- Item purchased just before the customer became a member
SELECT s.userid, s.created_date, s.product_id
FROM sales s
JOIN goldusers_signup g ON s.userid = g.userid AND s.created_date < g.gold_signup_date
WHERE s.created_date = (
    SELECT MAX(created_date)
    FROM sales
    WHERE userid = s.userid AND created_date < g.gold_signup_date
)

--  Total number of orders and amount spent by  customer before joining as a member
SELECT s.userid, SUM(p.price) AS total_spent, COUNT(s.created_date) AS total_orders
FROM sales s
JOIN goldusers_signup g ON s.userid = g.userid
JOIN product p ON s.product_id = p.product_id
WHERE s.created_date <= g.gold_signup_date
GROUP BY s.userid;


--  Total number of orders and amount spent by each customer after joining as a member
SELECT s.userid, SUM(p.price) AS total_spent, COUNT(s.created_date) AS total_orders
FROM sales s
JOIN goldusers_signup g ON s.userid = g.userid
JOIN product p ON s.product_id = p.product_id
WHERE s.created_date >= g.gold_signup_date
GROUP BY s.userid;



--Total points collected by each customer 
SELECT s.userid, SUM(p.price / p.amountPerPoint) AS Totalpoints 
FROM sales s
JOIN (
    SELECT product_id, 
        CASE 
            WHEN product_id = 1 OR product_id = 3 THEN 5 
            WHEN product_id = 2 THEN 2 
            ELSE 0 
        END AS amountPerPoint,
        price
    FROM product
) AS p ON s.product_id = p.product_id
GROUP BY s.userid
ORDER BY Totalpoints DESC;


-- Identify the product for which the most points have been given based on purchases
SELECT TOP 1 *
FROM (
    SELECT p.product_id, SUM(p.price / a.amountPerPoint) AS TotalPoints
    FROM product p
    JOIN (
        SELECT product_id, 
            CASE 
                WHEN product_id = 1 OR product_id = 3 THEN 5 
                WHEN product_id = 2 THEN 2 
                ELSE 0 
            END AS amountPerPoint
        FROM product
    ) a ON p.product_id = a.product_id
    GROUP BY p.product_id
) AS TotalPointsPerProduct
ORDER BY TotalPoints DESC;


-- Calculate points earned by users in their first year after joining the gold membership
SELECT g.userid, s.created_date, g.gold_signup_date, 
    CASE 
        WHEN p.product_id IN (1, 3) THEN (p.price / 5) + (p.price / 2)
        WHEN p.product_id = 2 THEN (p.price / 2) + (p.price / 2)
        ELSE 0 
    END AS points_earned
FROM sales s
JOIN product p ON s.product_id = p.product_id
JOIN goldusers_signup g ON s.userid = g.userid 
    AND s.created_date >= g.gold_signup_date 
    AND s.created_date <= DATEADD(YEAR, 1, g.gold_signup_date);


-- rank all the transactions for each member. For every non gold member transaction mark as na
SELECT 
    s.userid,
    s.created_date,
    CASE 
        WHEN g.gold_signup_date IS NOT NULL THEN 
            CONVERT(VARCHAR(10), RANK() OVER (PARTITION BY s.userid ORDER BY s.created_date))
        ELSE 'na' 
    END AS transaction_rank
FROM sales s
LEFT JOIN goldusers_signup g ON s.userid = g.userid 
    AND s.created_date >= g.gold_signup_date;
