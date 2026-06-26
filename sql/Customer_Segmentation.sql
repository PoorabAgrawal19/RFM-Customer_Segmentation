--- Customer Segementation
--- 5 segments based on RFM scores


Select 
 Customer_ID, Recency, Frequency, Monetary, R_Score, F_Score, M_Score,
 

 CASE 
        When R_Score >= 4 and F_Score >= 4 and M_score >= 4 THEN 'Champions'
        -- Here only those customers are segmented who has all the matrics above or equal to 4. These are segemented as "Champions"

        When R_Score <= 3 and (F_Score >= 3 or M_Score >= 3) THEN 'At Risk'
        -- "At Risk" means they used to be good customers, but hasn't come back rececntly thats why low recency R<=3 is taken.
        -- R score >= 3 means the last purchase date was between 95 to 379 days that's a customer who is drifting, not lost yet.

        When F_Score >=3 and M_Score >= 3 THEN 'Loyal' 
        -- These customers have been loyal to the business but needs to observed before turning them into 'risk' category

        When M_Score >= 4 and F_Score <= 2 THEN 'High Value Occasional'
        -- These are occasional buyers but spends a heavy amount ( more than 5500) so for any recency score it will be evaluated.

        When R_Score >= 4 and F_Score >= 2 AND F_Score <= 3 THEN 'Reactivated'
        --- These are the customers who have started shoping again after long time they are evaluated as "Reactivated".

        When R_Score >= 4 and F_Score <= 1 THEN 'New Customer'
        --- These are the new customers who recenty bought an item and their Frequency is low because of less number of orders. 

        ELSE 'Lost' 
        --- The rest customers is segemented as lost customers because the have low Recency, Frequency and Monetary.

    End As Segment

     INTO dbo.rfm_segments
    From Distributed_scored

 
    select * from dbo.rfm_segments 


    SELECT
    Segment,
    COUNT(*) AS Customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1)  AS Percentage,
    ROUND(AVG(Monetary), 2) AS Avg_Spend,
    ROUND(SUM(Monetary), 2) AS Total_Revenue
FROM dbo.rfm_segments
GROUP BY Segment
ORDER BY Total_Revenue DESC

--- This block of code will show us the total customers fall under their repective segements
--- This will also evaluate the percentage of cutomers comes under each segements with 'Avg spend' and 'Total Revenue' from that segment. 


--- These segementation are strictly based on the RFM scores that we have evaluated.
--- And the range of scores is considered by the percentiles that we have evaluated.


-- PARETO ANALYSIS
-- Prove top segments drive majority of revenue

WITH segment_revenue AS (
    SELECT
        Customer_ID,
        Monetary,
        Segment,
        CASE WHEN Segment IN ('Champions', 'Loyal')
          THEN 1 ELSE 0
        END AS is_top_segment
    FROM dbo.rfm_segments
)


--- These are to find the top customers combining Champions and Loyals 
---  We have used CTE to define as 'segment_revenue' which has both Champoins and Loyal customers.


SELECT
    -- Customer counts 

    COUNT(Customer_ID)                                    as Total_Customers,
    SUM(is_top_segment)                                   as Top_Customers,
    ROUND(SUM(is_top_segment) * 100.0 / COUNT(*), 2)      as Top_Customer_Pct,

    -- Revenue 

--- Revenue from these two top segments 
    ROUND(SUM(is_top_segment * Monetary), 2)              as Top_Revenue,
    ROUND(SUM(Monetary), 2)                               as Total_Revenue,
    ROUND(SUM(is_top_segment * Monetary) * 100.0
          / SUM(Monetary), 1)                             as Pareto_Pct

FROM segment_revenue


-- PARETO ANALYSIS RESULTS

-- Top segments    : Champions + Loyal
-- Top customers   : 980 out of 5,863 (16.71%)
-- Top revenue     : £11,729,355
-- Total revenue   : £17,591,088
-- Revenue share   : 66.7%

-- FINDING:
-- 16.71% of customers drive 66.7% of total revenue.
-- This confirms the Pareto principle.
-- Protecting Champions and Loyal segments is the single most important business priority.
