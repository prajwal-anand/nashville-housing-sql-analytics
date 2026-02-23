-- =========================================
-- Project: Nashville Housing Analysis
-- Feature Engineering Script
-- =========================================

USE NashvilleHousingDB;
GO

SELECT * FROM dbo.nashville_clean;

-- =========================================
-- SECTION 1: TIME-BASED FEATURES
-- =========================================

/*
	FROM SALE DATE, EXTRACT:-
	- SaleYear
	- SaleMonthNumber
	- SaleQuarter	
*/

-- CREATE COLUMNS FOR SALE YEAR, SALE MONTH NUMBER AND SALE QUARTER

ALTER TABLE dbo.nashville_clean
ADD SaleYear INT;


ALTER TABLE dbo.nashville_clean
ADD SaleMonthNumber INT


ALTER TABLE dbo.nashville_clean
ADD SaleQuarter INT;

-- POPULATE THE SALE YEAR

UPDATE [dbo].[nashville_clean]
SET SaleYear = YEAR(SaleDate)
WHERE SaleDate IS NOT NULL;

-- POPULATE THE SALE MONTH NUMBER

UPDATE [dbo].[nashville_clean]
SET SaleMonthNumber = MONTH(SaleDate)
WHERE SaleDate IS NOT NULL;

-- POPULATE THE SALE QUARTER

UPDATE [dbo].[nashville_clean]
SET SaleQuarter = DATEPART(QUARTER, SaleDate)
WHERE SaleDate IS NOT NULL;

-- VALIDATE THE RESULT

SELECT SaleDate, SaleYear, SaleMonthNumber, SaleQuarter
FROM dbo.nashville_clean;

-- UNDERSTANDING SaleDate DATA

SELECT MIN(SaleDate) AS EarliestSaleDate, MAX(SaleDate) AS LatestSaleDate
FROM dbo.nashville_clean

SELECT COUNT(DISTINCT SALEYEAR)
FROM dbo.nashville_clean

-- SUMMARY
/*
	SALE DATE FORMAT : YYYY-MM-DD
	EARLIEST SALE DATE = 2013-01-02
	LATEST SALE DATE = 2019-12-13
	NUMBER OF YEARS = 5
	RANGE : [2013-2019]
*/
---------------------------------------------------------------------------
-- =========================================
-- SECTION 2: PROPERTY METRICS
-- =========================================

/* PROPERTY AGE AT SALE */

-- ADD COLUMN FOR PROPERTY AGE AT SALE

ALTER TABLE dbo.nashville_clean
ADD PropertyAgeAtSale INT;

UPDATE dbo.nashville_clean
SET PropertyAgeAtSale = SaleYear - YearBuilt
WHERE YearBuilt IS NOT NULL
AND YearBuilt <= SaleYear

-- VALIDATING PROPERTY AGE AT SALE

SELECT YearBuilt, SaleYear, PropertyAgeAtSale 
FROM dbo.nashville_clean
-- WHERE YearBuilt IS NOT NULL
-- AND YearBuilt <= SaleYear

/* PROPERTY AGE GROUP */

-- ADD COLUMN FOR PROPERTY AGE GROUP

ALTER TABLE dbo.nashville_clean
ADD PropertyAgeGroup NVARCHAR(255);

-- POPULATE AGE GROUP BASED ON PROPERTY AGE AT SALE

UPDATE dbo.nashville_clean
SET PropertyAgeGroup =
CASE
	WHEN PropertyAgeAtSale BETWEEN 0 AND 5 THEN 'New Construction'
	WHEN PropertyAgeAtSale BETWEEN 6 AND 15 THEN 'Very New'
	WHEN PropertyAgeAtSale BETWEEN 16 AND 30 THEN 'Moderately New'
	WHEN PropertyAgeAtSale BETWEEN 31 AND 50 THEN 'Established'
	WHEN PropertyAgeAtSale BETWEEN 51 AND 75 THEN 'Old'
	WHEN PropertyAgeAtSale BETWEEN 76 AND 100 THEN 'Very Old'
	WHEN PropertyAgeAtSale > 100 THEN 'Historic'
	ELSE 'Unknown'
END

-- VALIDATE CHANGES

SELECT PropertyAgeGroup, COUNT(*) AS [COUNT]
FROM dbo.nashville_clean
GROUP BY PropertyAgeGroup

---------------------------------------------------------------------------