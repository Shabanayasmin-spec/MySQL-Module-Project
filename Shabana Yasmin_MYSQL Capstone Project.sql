-- USE ecomm;

SELECT * FROM CUSTOMER_CHURN;

-- UPDATING NULL VALUES
SET SQL_SAFE_UPDATES=0; 

-- Data Cleaning: 
-- Handling Missing Values 

UPDATE CUSTOMER_CHURN
SET WAREHOUSETOHOME =(SELECT ROUND(AVG(WarehouseToHome)) FROM CUSTOMER_CHURN WHERE WarehouseToHome IS NOT NULL)
 WHERE WAREHOUSETOHOME IS NULL;

UPDATE CUSTOMER_CHURN
SET HourSpendOnApp =(SELECT ROUND(AVG(HourSpendOnApp)) FROM CUSTOMER_CHURN WHERE HourSpendOnApp IS NOT NULL)
 WHERE HourSpendOnApp IS NULL;

UPDATE CUSTOMER_CHURN
SET OrderAmountHikeFromlastYear =(SELECT ROUND(AVG(OrderAmountHikeFromlastYear)) FROM CUSTOMER_CHURN WHERE OrderAmountHikeFromlastYear IS NOT NULL)
 WHERE OrderAmountHikeFromlastYear IS NULL;

UPDATE CUSTOMER_CHURN
SET DaySinceLastOrder =(SELECT ROUND(AVG(DaySinceLastOrder)) FROM CUSTOMER_CHURN WHERE DaySinceLastOrder IS NOT NULL)
 WHERE DaySinceLastOrder IS NULL;

SELECT * FROM CUSTOMER_CHURN;

UPDATE CUSTOMER_CHURN
SET Tenure =(SELECT Tenure FROM (SELECT Tenure FROM CUSTOMER_CHURN 
        GROUP BY Tenure
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS Mode_TENURE
)
WHERE TENURE IS NULL;

UPDATE CUSTOMER_CHURN
SET CouponUsed =(SELECT CouponUsed FROM (SELECT CouponUsed FROM CUSTOMER_CHURN 
        GROUP BY CouponUsed
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS Mode_CouponUsed
)
WHERE CouponUsed IS NULL;

UPDATE CUSTOMER_CHURN
SET OrderCount =(SELECT OrderCount FROM (SELECT OrderCount FROM CUSTOMER_CHURN 
        GROUP BY OrderCount
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS Mode_OrderCount
)
WHERE OrderCount IS NULL;

SELECT * FROM CUSTOMER_CHURN;

-- HANDLING OUTLINERS 
SELECT * FROM CUSTOMER_CHURN
WHERE WarehouseToHome > 100;

DELETE FROM CUSTOMER_CHURN
WHERE WAREHOUSETOHOME >100;

-- DEALING WITH INCONSISTENCIES

UPDATE CUSTOMER_CHURN
SET PreferredLoginDevice = 'Mobile Phone' WHERE PreferredLoginDevice ='Phone';
UPDATE CUSTOMER_CHURN
SET PreferredLoginDevice = 'Mobile Phone' WHERE PreferredLoginDevice IN('Mobile Mobile phone','Mobile Phone');
 
UPDATE CUSTOMER_CHURN
SET PreferedOrderCat ='Mobile Phone' WHERE PreferedOrderCat = 'Mobile';
UPDATE CUSTOMER_CHURN
SET PreferedOrderCat = 'Mobile Phone' WHERE PreferedOrderCat IN('Mobile phone phone','Mobile Phone');

SELECT * FROM CUSTOMER_CHURN
WHERE PreferredLoginDevice LIKE '%Phone%' OR PreferedOrderCat LIKE '%Mobile%';

UPDATE CUSTOMER_CHURN
SET PreferredPaymentMode =REPLACE(PreferredPaymentMode,'COD','Cash on Delivery')
WHERE PreferredPaymentMode= 'COD';

UPDATE CUSTOMER_CHURN
SET  PreferredPaymentMode = REPLACE(PreferredPaymentMode,'CC','Credit Card')
WHERE PreferredPaymentMode= 'CC';

SELECT PreferredPaymentMode
FROM CUSTOMER_CHURN;
SELECT * FROM CUSTOMER_CHURN;

-- DATA TRASFORMATION
-- COLUMN RENAMING

-- Rename the column "PreferedOrderCat" to "PreferredOrderCat"
ALTER TABLE CUSTOMER_CHURN
RENAME COLUMN PreferedOrderCat TO PreferredOrderCat;

-- Rename the column 'HourSpendOnApp' to 'HoursSpentOnApp'
ALTER TABLE CUSTOMER_CHURN
RENAME COLUMN HourSpendOnApp to HoursSpentOnApp;
SELECT * FROM CUSTOMER_CHURN;

-- CREATING NEW COLUMN 'ComplaintReceived' and updating values
ALTER TABLE CUSTOMER_CHURN
ADD COLUMN ‘ComplaintReceived’  VARCHAR(5);
UPDATE CUSTOMER_CHURN
SET ComplaintReceived = IF(Complain = '1','Yes','No');
SELECT * FROM CUSTOMER_CHURN;

-- CREATING NEW COLUMN 'ChurnStatus' and updating values
ALTER TABLE CUSTOMER_CHURN
ADD COLUMN ChurnStatus VARCHAR(20);
UPDATE CUSTOMER_CHURN
SET ChurnStatus = IF(Churn = '1','Churned','Active');
SELECT * FROM CUSTOMER_CHURN;

-- Column Dropping
ALTER TABLE CUSTOMER_CHURN
DROP COLUMN CHURN;

ALTER TABLE CUSTOMER_CHURN
DROP COLUMN Complain;
SELECT * FROM CUSTOMER_CHURN;

-- Data Exploration and Analysis
-- 1. Count of churned and active customers
SELECT CHURNSTATUS, COUNT(*) AS CHURNCOUNT
FROM CUSTOMER_CHURN
GROUP BY CHURNSTATUS;

-- 2.Average tenure of customers who churned
SELECT ROUND(AVG(TENURE),2) AS AvgTenure 
FROM CUSTOMER_CHURN
WHERE CHURNSTATUS = 'Churned';

-- 3.Total cashback amount earned by customers who churned
SELECT SUM(CASHBACKAMOUNT) AS TotalCashback
FROM CUSTOMER_CHURN
WHERE CHURNSTATUS = 'Churned';

-- 4. Percentage of churned customers who complained
SELECT 
    ComplaintReceived,
    (SUM(IF(ChurnStatus = 'Churned', 1, 0)) * 100.0) / COUNT(*) AS PercentageChurnedCustomers
FROM CUSTOMER_CHURN 
GROUP BY ComplaintReceived;

-- 5. Gender distribution of customers who complained
SELECT 
GENDER,
COUNT(*) AS NumberofComplaints
FROM CUSTOMER_CHURN
WHERE ComplaintReceived = 'Yes'
group by Gender;

-- 6. City tier with the highest number of churned customers whose preferred order category is Laptop & Accessory. 
SELECT 
    CityTier,
    COUNT(*) AS ChurnedCustomers
FROM CUSTOMER_CHURN
WHERE 
    ChurnStatus = 'Churned' 
    AND PreferedOrderCat = 'Laptop & Accessory'
GROUP BY CityTier
ORDER BY ChurnedCustomers DESC
LIMIT 1;

-- 7. Most preferred payment mode among active customers. 
SELECT
PreferredPaymentMode,
COUNT(*) AS MostPreferredPaymentMode
FROM CUSTOMER_CHURN
WHERE CHURNSTATUS = 'ACTIVE'
GROUP BY PreferredPaymentMode
ORDER BY MostPreferredPaymentMode DESC
LIMIT 1;

-- 8. Preferred login device(s) among customers who took more than 10 days since their last order.
SELECT 
PreferredLoginDevice,
COUNT(*) AS MoreThan10days
FROM CUSTOMER_CHURN
WHERE DaySinceLastOrder > 10
GROUP BY PreferredLoginDevice
ORDER BY MoreThan10days DESC
LIMIT 1;

-- 9. Number of active customers who spent more than 3 hours on the app.
SELECT 
HourSpendonApp,
count(*) AS ActiveCustomers
FROM CUSTOMER_CHURN
WHERE DaySinceLastOrder > 3
GROUP BY HourSpendonApp
ORDER BY ActiveCustomers DESC
LIMIT 1;

 -- 10. Average cashback amount received by customers who spent at least 2 hours on the app.
 SELECT * from customer_churn;
 SELECT ROUND(AVG(CASHBACKAMOUNT),2) AS AvgCashBackAmount
 FROM CUSTOMER_CHURN
 WHERE HourSpendOnApp >= 2;
 
 -- 11. Maximum hours spent on the app by customers in each preferred order category
 SELECT 
 PreferedOrderCat,
MAX(HourspendonApp) as MaxHoursSpent
FROM CUSTOMER_CHURN
GROUP BY PreferedOrderCat
ORDER BY MaxHoursSpent desc;

-- 12. Average order amount hike from last year for customers in each marital status category.
SELECT
MaritalStatus,
ROUND(AVG(OrderAmountHikeFromlastYear),2) AS AvgOrderAmountHikeFromLastYear
FROM CUSTOMER_CHURN
GROUP BY MaritalStatus
ORDER BY AvgOrderAmountHikeFromLastYear DESC;

-- 13. Total order amount hike from last year for customers who are single and prefer mobile phones for ordering.
SELECT
MaritalStatus,
PreferredLoginDevice,
SUM(OrderAmountHikeFromlastYear) AS TotalOrderAmountHikeFromLastYear
FROM CUSTOMER_CHURN
WHERE MaritalStatus = 'Single'
GROUP BY MaritalStatus
HAVING PreferredLoginDevice like '%Mobile Phone%'
ORDER BY TotalOrderAmountHikeFromLastYear DESC;

-- 14.  Average number of devices registered among customers who used UPI as their preferred payment mode.
SELECT * FROM CUSTOMER_CHURN;
SELECT
PreferredPaymentMode,
ROUND(AVG(NumberOfDeviceRegistered),2) AS AvgNumberOfDevicesRegistered
FROM CUSTOMER_CHURN
WHERE PreferredPaymentMode = 'UPI'
GROUP BY PreferredPaymentMode ;

-- 15. City tier with the highest number of customers
SELECT 
CityTier,
count(*) AS HighestNumberOfCustomers 
FROM CUSTOMER_CHURN
GROUP BY CityTier
ORDER BY HighestNumberOfCustomers DESC
LIMIT 1;

-- 16. Marital status of customers with the highest number of addresses
SELECT 
MaritalStatus,
MAX(NumberOfAddress) AS HighestNumberOfAddresses
FROM CUSTOMER_CHURN
GROUP BY MaritalStatus
ORDER BY HighestNumberOfAddresses DESC;

-- 17.Gender that utilized the highest number of coupons
SELECT GENDER,
SUM(CouponUsed) AS HighestNumberOfCoupons
FROM CUSTOMER_CHURN
GROUP BY GENDER
ORDER BY HighestNumberOfCoupons DESC
LIMIT 1;

-- 18. Average satisfaction score in each of the preferred order categories. 
SELECT PreferedOrderCat,
ROUND(AVG(SatisfactionScore),2) AS AvgSatisfactionScore
FROM CUSTOMER_CHURN
GROUP BY PreferedOrderCat
ORDER BY AvgSatisfactionScore DESC;

-- 19. Total order count for customers who prefer using credit cards and have the maximum satisfaction score.
SELECT 
    PreferredPaymentMode,
    COUNT(OrderCount) AS TotalOrderCount
FROM CUSTOMER_CHURN
WHERE 
    PreferredPaymentMode = 'Credit Card'
    AND SatisfactionScore = (
        SELECT MAX(SatisfactionScore)
        FROM CUSTOMER_CHURN
        WHERE PreferredPaymentMode = 'Credit Card'
    )
GROUP BY PreferredPaymentMode;

-- 20. Customers are there who spent only one hour on the app and days since their last order was more than 5
SELECT * FROM CUSTOMER_CHURN
WHERE  HourSpendOnApp = 1
    AND DaySinceLastOrder > 5;
    
-- 21. Average satisfaction score of customers who have complained
SELECT ComplaintReceived, AVG(SatisfactionScore) AS AvgSatisfactionScore
FROM CUSTOMER_CHURN
WHERE ComplaintReceived = 'Yes';
   
-- 22.  Customers are there in each preferred order category
SELECT PreferedOrderCat,
COUNT(*) AS CustomerPreferedOrderCat
FROM CUSTOMER_CHURN
GROUP BY PreferedOrderCat 
ORDER BY CustomerPreferedOrderCat DESC;

-- 23.  Average cashback amount received by married customers
SELECT MaritalStatus,
Round(AVG(CashBackAmount),2) AS AvgCashBackAmount
FROM CUSTOMER_CHURN
WHERE MaritalStatus = 'Married'
GROUP BY MaritalStatus
ORDER BY AvgCashBackAmount DESC;

-- 24.  Average number of devices registered by customers who are not using Mobile Phone as their preferred login device
SELECT PreferredLoginDevice,
ROUND(AVG(NumberOfDeviceRegistered),2) AS AvgNumberOfDevicesRegistered
FROM CUSTOMER_CHURN
WHERE PreferredLoginDevice <> 'Mobile Phone'
GROUP BY PreferredLoginDevice
ORDER BY AvgNumberOfDevicesRegistered DESC;

-- 25. Preferred order category among customers who used more than 5 coupons
SELECT PreferedOrderCat,
SUM(CouponUsed) AS MoreThan5Coupons
FROM CUSTOMER_CHURN
GROUP BY PreferedOrderCat
HAVING SUM(CouponUsed) > 5
ORDER BY MoreThan5Coupons DESC;

-- 26. Top 3 preferred order categories with the highest average cashback amount
SELECT PreferedOrderCat,
    ROUND(AVG(CashBackAmount),2) AS AvgCashBackAmount
FROM CUSTOMER_CHURN
GROUP BY PreferedOrderCat
ORDER BY AvgCashBackAmount DESC
LIMIT 3;

-- 27. Preferred payment modes of customers whose average tenure is 10 months and have placed more than 500 orders.
SELECT 
    PreferredPaymentMode,
    AVG(Tenure) AS AvgTenure,
    SUM(OrderCount) AS TotalOrders
FROM CUSTOMER_CHURN
GROUP BY PreferredPaymentMode
HAVING AVG(Tenure) = 10 AND SUM(OrderCount) > 500;

-- 28. Categorize customers based on their distance from the warehouse to home 
SELECT 'Very Close Distance' AS DistanceCategory, ChurnStatus, COUNT(*) AS CustomerCount
FROM CUSTOMER_CHURN
WHERE WarehouseToHome <= 5
GROUP BY ChurnStatus

UNION

SELECT 'Close Distance' AS DistanceCategory, ChurnStatus, COUNT(*) AS CustomerCount
FROM CUSTOMER_CHURN
WHERE WarehouseToHome <= 10 AND WarehouseToHome > 5
GROUP BY ChurnStatus

UNION

SELECT 'Moderate Distance' AS DistanceCategory, ChurnStatus, COUNT(*) AS CustomerCount
FROM CUSTOMER_CHURN
WHERE WarehouseToHome <= 15 AND WarehouseToHome > 10
GROUP BY ChurnStatus

UNION

SELECT 'Far Distance' AS DistanceCategory, ChurnStatus, COUNT(*) AS CustomerCount
FROM CUSTOMER_CHURN
WHERE WarehouseToHome > 15
GROUP BY ChurnStatus

ORDER BY DistanceCategory, CustomerCount DESC;

-- 29. Customer’s order details who are married, live in City Tier-1, and their order counts are more than the average number of orders placed by all customers. 
SELECT *
FROM CUSTOMER_CHURN
WHERE MaritalStatus = 'Married'
  AND CityTier = 1
  AND OrderCount > (
      SELECT AVG(OrderCount)
      FROM CUSTOMER_CHURN
  );

-- 30. A) Create a ‘customer_returns’ table in the ‘ecomm’ database
CREATE TABLE ecomm.customer_returns (
    ReturnID INT PRIMARY KEY,
    CustomerID INT,
    ReturnDate DATE,
    RefundAmount DECIMAL(10, 2)
);

INSERT INTO ecomm.customer_returns (ReturnID, CustomerID, ReturnDate, RefundAmount)
VALUES
    (1001, 50022, '2023-01-01', 2130),
    (1002, 50316, '2023-01-23', 2000),
    (1003, 51099, '2023-02-14', 2290),
    (1004, 52321, '2023-03-08', 2510),
    (1005, 52928, '2023-03-20', 3000),
    (1006, 53749, '2023-04-17', 1740),
    (1007, 54206, '2023-04-21', 3250),
    (1008, 54838, '2023-04-30', 1990);

SELECT * FROM ecomm.customer_returns;

-- B) Display the return details along with the customer details of those who have churned and have made complaints. 
SELECT 
    cr.ReturnID,
    cr.CustomerID,
    cr.ReturnDate,
    cr.RefundAmount,
    cc.MaritalStatus,
    cc.CityTier,
    cc.OrderCount,
    cc.Gender,
    cc.ComplaintReceived,
    cc.ChurnStatus
FROM 
    ecomm.customer_returns cr
JOIN 
    ecomm.customer_churn cc
ON 
    cr.CustomerID = cc.CustomerID
WHERE 
    cc.ChurnStatus = 'Churned' 
    AND cc.ComplaintReceived = 'Yes';

