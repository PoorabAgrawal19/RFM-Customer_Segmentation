-- Data Cleaning in SQL 
-- Qualtity Check for the Raw Data 

Use RFM_Analysis
select * from [dbo].[retail_raw_new]

Select Count(*) As Total_Records  --- Total Records in the table are "1067371" 
from [dbo].[retail_raw_new]


-- These CASE statements Queries Counts the total Number of False rows where data is somehow missing or corrupted
-- Inside the table

Select
    COUNT(*) AS total_rows,

--Takes where the Customer_ID is NULL, and Reflects the Sum 

    SUM(CASE When Customer_ID Is Null   
        Then 1 Else 0 END) As null_customer_ids,

--Takes where the Invoice starts with C Aplhabet, and Reflects the Sum 

    SUM(CASE When CAST(Invoice AS VARCHAR)
        LIKE 'C%' Then 1 Else 0 END) As cancelled_orders,

--Takes where the Quantity is any Negative Value, and Reflects the Sum 

    SUM(CASE When Quantity <= 0
        Then 1 Else 0 END) As negative_quantities,
        
--Takes where the Price is equal or less than zero, and Reflects the Sum

    SUM(CASE When Price <= 0
        Then 1 Else 0 END) As zero_or_negative_price,

--Takes where the Description NULL, and Reflects the Sum

    SUM(CASE When Description Is Null 
        Then 1 Else 0 END) As null_descriptions

from dbo.retail_raw_new


--Findings of these Queries

-- null_customer_ids = 243007
-- cancelled_orders = 19494
-- negative_quantities = 22950
-- zero_or_negative_price = 6207
-- null_description = 4382



SELECT COUNT(*) AS total_Currupted_rows
From dbo.retail_raw_new
WHERE Customer_ID IS NULL
OR CAST(Invoice AS VARCHAR) Like 'C%'
OR Quantity <= 0
OR Price <= 0
OR Description IS NULL

-- total_Currupted_rows = 261822

SELECT *
INTO dbo.retail_clean
From dbo.retail_raw_new
WHERE Customer_ID IS NOT NULL
AND CAST(Invoice AS VARCHAR) NOT Like 'C%'
AND Quantity > 0
AND Price > 0
AND Description IS NOT NULL

-- Cleaned table copied to a new table named "dbo.retail_clean"

select * from dbo.retail_clean

Select Count(*) from dbo.retail_clean  as Cleaned_Rows_Count

-- Cleaned_Rows_Count = 805549

-- Comparing Before and After table 

SELECT 'Before Cleaning' as stage, COUNT(*) AS total_rows
FROM dbo.retail_raw_new
UNION ALL
SELECT 'After Cleaning' as stage, COUNT(*) AS total_rows
FROM dbo.retail_clean

-- Total Rows before cleaning = 1067371
-- Total Rows after cleaning = 805549 

--total_Currupted_rows removed in clening  = 261822



Select Count(*) from dbo.retail_clean  as Cleaned_Rows_Count

--So 
--The final cleaned rows = 805549








