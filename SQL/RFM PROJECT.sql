DROP TABLE IF EXISTS customer_orders;
DROP TABLE IF EXISTS RFM;
CREATE database RFM;
USE RFM;
--Create the hypothetical customer_orders table--
CREATE TABLE customer_orders (
 order_id INT PRIMARY KEY AUTO_INCREMENT,
 customer_id INT NOT NULL,
 order_date DATE NOT NULL,
 order_amount DECIMAL(10, 2) NOT NULL
);
INSERT INTO customer_orders (customer_id, order_date, order_amount) VALUES
(101, '2025-06-10', 50.00), -- Recent, moderate amount
(101, '2025-05-15', 75.00), -- Frequent
(101, '2025-04-01', 100.00),
(102, '2025-06-08', 200.00), -- Recent, high amount
(103, '2025-03-20', 30.00), -- Less recent, low amount
(103, '2025-01-10', 45.00),
(104, '2025-06-05', 120.00), -- Recent, moderate amount
(104, '2025-05-20', 80.00),
(104, '2025-05-01', 90.00),
(104, '2025-04-10', 150.00), -- Very Frequent
(105, '2025-02-28', 15.00), -- Not recent, low amount
(106, '2025-06-12', 300.00), -- Very recent, very high amount
(107, '2025-05-01', 60.00),
(108, '2025-06-09', 90.00),
(108, '2025-06-01', 110.00),
(109, '2024-11-20', 25.00), -- Oldest Recency
(110, '2025-06-11', 85.00),
(110, '2025-06-07', 40.00),
(110, '2025-06-03', 60.00),
(111, '2025-05-25', 180.00),
(112, '2025-06-06', 220.00);
-- Verify the inserted data
SELECT * FROM customer_orders;
SET @snapshot_date = '2025-06-14';
CREATE TEMPORARY TABLE RFM
(
 SELECT
 customer_id,
 DATEDIFF(@snapshot_date, MAX(order_date)) AS Recency,
 COUNT(DISTINCT order_id) AS Frequency,
 SUM(order_amount) AS Monetary
 FROM
 customer_orders
 GROUP BY
 customer_id
);
SELECT * FROM RFM;

CREATE TEMPORARY TABLE RFM_Scores
(
SELECT
 customer_id,
 Recency,
 Frequency,
 Monetary,-- Assign Recency Score (lower days = higher score)
 NTILE(5) OVER (ORDER BY Recency DESC) AS R_Score,
-- Use DESC for Recency (smaller days = better = higher score)
 NTILE(5) OVER (ORDER BY Frequency ASC) AS F_Score,
-- Use ASC for Frequency (smaller count = worse = lower score)
 NTILE(5) OVER (ORDER BY Monetary ASC) AS M_Score
-- Use ASC for Monetary (smaller amount = worse = lower score)
FROM
 RFM
ORDER BY
 customer_id);

 SELECT * FROM RFM_Scores;
 
SELECT
 customer_id,
 Recency,
 Frequency,
 Monetary,
 R_Score,
 F_Score,
 M_Score,
 -- Concatenate scores to create the RFM Segment
 CONCAT(R_Score, F_Score, M_Score) AS RFM_Segment,
 -- Categorize customers based on their RFM Segment
 CASE
 WHEN CONCAT(R_Score, F_Score, M_Score) IN ('555', '545', '455', '554') THEN 'Champions' -- Most valuable customers
 WHEN CONCAT(R_Score, F_Score, M_Score) IN ('544', '454', '445', '535', '355') THEN 'Loyal Customers'
 WHEN CONCAT(R_Score, F_Score, M_Score) IN ('551', '515', '155', '541', '145') THEN 'New/High-Value
but Infrequent' -- Needs frequency boost
 WHEN CONCAT(R_Score, F_Score, M_Score) LIKE '5%' AND F_Score < 3 THEN 'New Customers
(Potential)' -- Recently joined, low frequency
 WHEN CONCAT(R_Score, F_Score, M_Score) LIKE '_5_' OR CONCAT(R_Score, F_Score, M_Score)
LIKE '__5' THEN 'High-Value/Frequent (Needs Recency)' -- High F/M, but not recent
 WHEN CONCAT(R_Score, F_Score, M_Score) IN ('333', '323', '233') THEN 'At Risk'
 WHEN CONCAT(R_Score, F_Score, M_Score) IN ('111', '112', '121', '211', '122', '212', '221') THEN 'Lost
Customers' -- Least engaged
 ELSE 'Other' -- Catch-all for less common combinations
 END AS Customer_Segment
FROM
 RFM_Scores
ORDER BY
 customer_id;
 
 
 DROP TEMPORARY TABLE RFM;
DROP TEMPORARY TABLE RFM_Scores;
