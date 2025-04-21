# Exercise 1
SELECT 
    t.ID_client,
    AVG(t.Count_products) AS avg_check,
    SUM(t.Count_products) / 12 AS avg_monthly_amount,
    COUNT(*) AS total_transactions
FROM transactions t
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY t.ID_client
HAVING COUNT(DISTINCT DATE_FORMAT(t.date_new, '%Y-%m')) = 12;

# Exercise 2
#A 
SELECT 
	DATE_FORMAT(date_new, '%Y-%m') AS month ,
    ROUND(AVG(Sum_payment), 2) AS avg_check_amount
FROM Transactions 
GROUP BY DATE_FORMAT(date_new, '%Y-%m')
ORDER BY month;

#B 
SELECT 
	ROUND(AVG(month_ops), 2) AS avg_operations_per_month
FROM (
	SELECT 
		DATE_FORMAT(date_new, '%Y-%m') AS month, 
        COUNT(Id_check) AS month_ops 
	FROM Transactions 
    GROUP BY DATE_FORMAT(date_new, '%Y-%m')
) AS monthly_counts;

SELECT* from customers;

#C 
SELECT 
    AVG(monthly_clients) AS avg_clients_per_month
FROM (
    SELECT 
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        COUNT(DISTINCT ID_client) AS monthly_clients
    FROM transactions
    GROUP BY month
) AS monthly_data;

#D  
SELECT 
    t.ID_client,
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    
    COUNT(*) OVER (PARTITION BY t.ID_client) AS client_total_ops,
    COUNT(*) OVER () AS total_ops_year,
    ROUND(
        COUNT(*) OVER (PARTITION BY t.ID_client) / COUNT(*) OVER (), 
        4
    ) AS share_of_year_ops,
    
    SUM(t.Count_products) AS client_monthly_sum,
    SUM(SUM(t.Count_products)) OVER (PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) AS total_monthly_sum,
    ROUND(
        SUM(t.Count_products) / SUM(SUM(t.Count_products)) OVER (PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')),
        4
    ) AS share_of_month_sum

FROM transactions t
WHERE t.date_new BETWEEN '2015-01-01' AND '2015-12-31'
GROUP BY t.ID_client, month; 

#E 
SELECT 
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    c.Gender,
    
    COUNT(DISTINCT t.ID_client) AS clients_per_gender,
    COUNT(DISTINCT t.ID_client) * 100.0 / SUM(COUNT(DISTINCT t.ID_client)) OVER (PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) 
        AS percent_clients,

    SUM(t.Count_products) AS total_spent,
    SUM(t.Count_products) * 100.0 / SUM(SUM(t.Count_products)) OVER (PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m'))
        AS percent_spent

FROM transactions t
JOIN customers c ON t.ID_client = c.Id_client

WHERE t.date_new BETWEEN '2015-01-01' AND '2015-12-31'

GROUP BY month, c.Gender
ORDER BY month, c.Gender;

#Exercise 3
WITH age_groups AS (
    SELECT 
        c.Id_client,
        CASE 
            WHEN c.age IS NULL THEN 'Unknown'
            WHEN c.age BETWEEN 0 AND 9 THEN '0-9'
            WHEN c.age BETWEEN 10 AND 19 THEN '10-19'
            WHEN c.age BETWEEN 20 AND 29 THEN '20-29'
            WHEN c.age BETWEEN 30 AND 39 THEN '30-39'
            WHEN c.age BETWEEN 40 AND 49 THEN '40-49'
            WHEN c.age BETWEEN 50 AND 59 THEN '50-59'
            WHEN c.age BETWEEN 60 AND 69 THEN '60-69'
            WHEN c.age BETWEEN 70 AND 79 THEN '70-79'
            ELSE '80+'
        END AS age_group
    FROM customers c
),
enriched AS (
    SELECT 
        ag.age_group,
        t.Count_products,
        t.date_new,
        CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new)) AS quarter
    FROM transactions t
    JOIN age_groups ag ON t.ID_client = ag.Id_client
),
quarterly AS (
    SELECT 
        age_group,
        quarter,
        COUNT(*) AS ops_count,
        SUM(Count_products) AS total_products,
        ROUND(AVG(Count_products), 2) AS avg_products
    FROM enriched
    GROUP BY age_group, quarter
),
quarter_totals AS (
    SELECT 
        quarter,
        SUM(total_products) AS total_products_all
    FROM quarterly
    GROUP BY quarter
)
SELECT 
    q.age_group,
    q.quarter,
    q.ops_count,
    q.total_products,
    q.avg_products,
    ROUND(q.total_products / qt.total_products_all * 100, 2) AS percent_of_total
FROM quarterly q
JOIN quarter_totals qt ON q.quarter = qt.quarter
ORDER BY q.quarter, q.age_group;