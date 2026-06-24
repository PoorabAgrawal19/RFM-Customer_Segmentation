-- RFM SCORING

--Calculate raw Recency, Frequency, Monetary
SELECT 
    Customer_ID, 
    DATEDIFF(DAY, MAX(PurchaseDate), '2011-12-09') AS  Recency, 
    COUNT(DISTINCT Invoice ) AS Frequency, 
    ROUND(SUM(TotalPrice), 2) AS Monetary
INTO dbo.rfm_raw 

FROM dbo.retail_eda_cleaned
GROUP BY Customer_ID 
order by Monetary desc


--- Calculated Recency   = days between last purchase and 2011-12-09
--- Calculated Frequency = count of unique invoices per customer
--- Calculated Monetary  = total spend per customer (Total Price)


-- Check the values 

-- The highest amount of money spend by a customer is €608821.65
SELECT TOP 10 * FROM dbo.rfm_raw
ORDER BY Monetary DESC;


-- The maximum Recency is 738 means some customers have bought at very start and never came back

SELECT TOP 10 *
FROM dbo.rfm_raw
ORDER BY Recency DESC

-- The highest frequency is 379 means the customer bought 379 times over the span of 2 years. This customer is definetly wholesale buyer
-- There must be only few whole sale customers.  

select top 10 * 
from dbo.rfm_raw 
order by Frequency DESC



-- Calculating the percentile to find the 25th, median and 75 of each of the Metrices
-- Here we can divide the segments so that we can have a overview of which kind of customer have what value of R, F and M

SELECT top 1
    -- Recency percentiles
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Recency) OVER() AS R_25th,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Recency) OVER() AS R_Median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Recency) OVER() AS R_75th,

    -- Frequency percentiles
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Frequency) OVER() AS F_25th,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Frequency) OVER() AS F_Median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Frequency) OVER() AS F_75th,

    -- Monetary percentiles
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY Monetary) OVER() AS M_25th,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY Monetary) OVER() AS M_Median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY Monetary) OVER() AS M_75th

FROM dbo.rfm_raw

-- After calculating percentiles we get ---
--- R_25th = 25, R_Median = 95, R_75th = 379
--- F_25th = 1, F_Median = 3, F_75th = 7
--- M_25th = 347.77, M_Median = 896.66, M_75th = 2301.13


-- Here we make a assumption that--
--- If any customer has Monetary < M_25th, we can place them in bottom 25% 
--- If any customer has Frequency > F_75th, we can place them in top 25% 
--- If any customer has Recency > R_Median, more than 50% of customers bought within the last 95 days


--- The Main reason of finding these percentiles is to get a rough idea about the scoring whether it will gonna make sense or not.
--- If the percentile analysis showed median monetary = £800 but score 5 customers are spending £200,something went wrong in the scoring. Percentiles will help catch this.
--- These scoring will make a threshold to understand and place the customers under each Metric. 





--- Assigning the score to them under the certain range i found by looking at the percentiles that we have taken
--- They may not me the same distribution as shown in the precentile because we are not dividing it in same quaterly range 
--- Distribution was done based on the observations

SELECT
    Customer_ID,
    Recency, Frequency, Monetary,

      -- Recency: lower = better
    Case
        WHEN Recency <= 25  THEN 5
        WHEN Recency <= 95  THEN 4
        WHEN Recency <= 379 THEN 3
        WHEN  Recency <= 500 THEN 2
        ELSE 1
    End as  R_Score,

      -- Frequency: higher = better
    Case
      WHEN Frequency >= 21 THEN 5
      WHEN Frequency >= 13 THEN 4
      WHEN Frequency >= 7 THEN 3
      WHEN Frequency >= 3 THEN 2
      ELSE 1
    End as  F_Score,

    -- Monetary: higher = better 
    Case
      WHEN Monetary >= 9500 THEN 5
      WHEN Monetary >= 5500 THEN 4
      WHEN Monetary >= 2500  THEN 3
      WHEN Monetary >= 900  THEN 2
      ELSE 1
    End as  M_Score

  INTO dbo.rfm_scored
  FROM [dbo].[rfm_raw]



select top 10 * from dbo.rfm_scored

--- Done sum of values of all three scores RFM_Sum and also concatenated them as a string to see the final score of all combined. 
Select
  Customer_ID,
  Recency, Frequency, Monetary,
  R_Score, F_Score, M_Score,
  (R_Score + F_Score + M_Score) as RFM_Sum,
  CONCAT(R_Score, F_Score, M_Score) as RFM_Segment
into dbo.Distributed_scored
From dbo.rfm_scored

select top 10* from  dbo.Distributed_scored


--- Verification of score distribution across all 3 metrics


-- R Score distribution
Select 'Recency' as Metric, R_Score as Score, 
       COUNT(*) AS Customers,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS Percentage
   from dbo.rfm_scored
GROUP BY R_Score
ORDER BY R_Score


-- F Score distribution
Select 'Frequency' AS Metric, F_Score AS Score,
       COUNT(*) AS Customers,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS Percentage
   from dbo.rfm_scored
GROUP BY F_Score
ORDER BY F_Score


-- M Score distribution
Select 'Monetary' AS Metric, M_Score AS Score,
       COUNT(*) AS Customers,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS Percentage
   from dbo.rfm_scored
GROUP BY M_Score
ORDER BY M_Score

--- This distribution gives us that about 43% of customers have frequency score is equal to '1' which means that these customers have ordered only a few times .
--- And about 50% of customers have monetary score equal to 1 
--- These are real flags in the data because some customers are B2B customers which generate the highest revenue but the large customer base spends 900 or less as a normal customer.






