USE superstore_db;

-- A. Create staging table
CREATE TABLE superstore_raw (
    Row_ID VARCHAR(50),
    Order_ID VARCHAR(50),
    Order_Date VARCHAR(50),
    Ship_Date VARCHAR(50),
    Ship_Mode VARCHAR(50),
    Customer_ID VARCHAR(50),
    Customer_Name VARCHAR(100),
    Segment VARCHAR(50),
    Country VARCHAR(50),
    City VARCHAR(50),
    State VARCHAR(50),
    Postal_Code VARCHAR(50),
    Region VARCHAR(50),
    Product_ID VARCHAR(50),
    Category VARCHAR(50),
    Sub_Category VARCHAR(50),
    Product_Name VARCHAR(255),
    Sales VARCHAR(50),
    Quantity VARCHAR(50),
    Discount VARCHAR(50),
    Profit VARCHAR(50)
);

-- B. Bulk load raw CSV data
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'D:/DIYA/PROJECTS/Retail Sales Dashboard/data/raw/Sample - Superstore.csv'
INTO TABLE superstore_raw
CHARACTER SET latin1
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- C. Create production table
CREATE TABLE superstore_sales (
    Row_ID INT PRIMARY KEY,
    Order_ID VARCHAR(50),
    Order_Date DATE,
    Ship_Date DATE,
    Ship_Mode VARCHAR(50),
    Customer_ID VARCHAR(50),
    Customer_Name VARCHAR(100),
    Segment VARCHAR(50),
    Country VARCHAR(50),
    City VARCHAR(50),
    State VARCHAR(50),
    Postal_Code VARCHAR(20),
    Region VARCHAR(50),
    Product_ID VARCHAR(50),
    Category VARCHAR(50),
    Sub_Category VARCHAR(50),
    Product_Name VARCHAR(255),
    Sales DECIMAL(10, 4),
    Quantity INT,
    Discount DECIMAL(4, 2),
    Profit DECIMAL(10, 4)
);

-- D. Insert with US Date Parsing (%m-%d-%y and %m/%d/%Y)
INSERT INTO superstore_sales
SELECT 
    CAST(Row_ID AS SIGNED),
    Order_ID,
    CASE 
        WHEN Order_Date LIKE '%/%/%' AND LENGTH(SUBSTRING_INDEX(Order_Date, '/', -1)) = 4 THEN STR_TO_DATE(Order_Date, '%m/%d/%Y')
        WHEN Order_Date LIKE '%/%/%' AND LENGTH(SUBSTRING_INDEX(Order_Date, '/', -1)) = 2 THEN STR_TO_DATE(Order_Date, '%m/%d/%y')
        WHEN Order_Date LIKE '%-%-%' AND LENGTH(SUBSTRING_INDEX(Order_Date, '-', -1)) = 4 THEN STR_TO_DATE(Order_Date, '%m-%d-%Y')
        WHEN Order_Date LIKE '%-%-%' AND LENGTH(SUBSTRING_INDEX(Order_Date, '-', -1)) = 2 THEN STR_TO_DATE(Order_Date, '%m-%d-%y')
        ELSE STR_TO_DATE(Order_Date, '%Y-%m-%d')
    END,
    CASE 
        WHEN Ship_Date LIKE '%/%/%' AND LENGTH(SUBSTRING_INDEX(Ship_Date, '/', -1)) = 4 THEN STR_TO_DATE(Ship_Date, '%m/%d/%Y')
        WHEN Ship_Date LIKE '%/%/%' AND LENGTH(SUBSTRING_INDEX(Ship_Date, '/', -1)) = 2 THEN STR_TO_DATE(Ship_Date, '%m/%d/%y')
        WHEN Ship_Date LIKE '%-%-%' AND LENGTH(SUBSTRING_INDEX(Ship_Date, '-', -1)) = 4 THEN STR_TO_DATE(Ship_Date, '%m-%d-%Y')
        WHEN Ship_Date LIKE '%-%-%' AND LENGTH(SUBSTRING_INDEX(Ship_Date, '-', -1)) = 2 THEN STR_TO_DATE(Ship_Date, '%m-%d-%y')
        ELSE STR_TO_DATE(Ship_Date, '%Y-%m-%d')
    END,
    Ship_Mode,
    Customer_ID,
    Customer_Name,
    Segment,
    Country,
    City,
    State,
    Postal_Code,
    Region,
    Product_ID,
    Category,
    Sub_Category,
    Product_Name,
    CAST(REPLACE(REPLACE(Sales, '$', ''), ',', '') AS DECIMAL(10, 4)),
    CAST(Quantity AS SIGNED),
    CAST(Discount AS DECIMAL(4, 2)),
    CAST(REPLACE(REPLACE(Profit, '$', ''), ',', '') AS DECIMAL(10, 4))
FROM superstore_raw;

-- E. Clean up staging table
DROP TABLE superstore_raw;


-- F. VERIFYING DATA INTEGRITY AND ROW COUNTS
-- 1. Verify all 9,994 rows exist
SELECT COUNT(*) AS total_rows FROM superstore_sales;

-- 2. Verify date sequence integrity (must return 0 rows)
SELECT Order_ID, Order_Date, Ship_Date
FROM superstore_sales
WHERE Ship_Date < Order_Date;


-- G. RUNNING BASELINE KPI BENCHMARKS
-- 1. Executive Totals
SELECT 
    COUNT(DISTINCT Order_ID) AS Total_Orders,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS Overall_Profit_Margin_PCT
FROM superstore_sales;

-- 2. Regional Breakdown
SELECT 
    Region,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS Profit_Margin_PCT
FROM superstore_sales
GROUP BY Region
ORDER BY Total_Sales DESC;