-- =========================================
-- Project: Nashville Housing Analysis
-- Data Profiling Script
-- =========================================

USE NashvilleHousingDB;
GO

SELECT ordinal_position, column_name, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'nashville_clean';

SELECT * FROM [dbo].[nashville_clean];

---------------------------------------------

/* CHECK SOLD AS VACANT COLUMN VALUES */
SELECT DISTINCT SoldAsVacant
FROM dbo.nashville_clean;

-- SOLD AS VACANT HAS 4 VALUES [N,Y,Yes,No]. CONVERT TO [No, Yes] ONLY.
---------------------------------------------

/* PROPERTY ADDRESS PROFILING */

SELECT PropertyAddress
FROM nashville_clean;

-- CHECK FOR NULL PROPERTY ADDRESS.
SELECT COUNT(*) AS NullPropertyAddress
FROM dbo.nashville_clean
WHERE PropertyAddress IS NULL;
-- PROPERTY ADDRESS HAS 29 NULL VALUES.

-- CHECK FORMAT.
SELECT TOP 25 PropertyAddress
FROM dbo.nashville_clean

-- FORMAT : [Street, City]
-- SEPERATORS: [' ', ',']

-- CHECK IF ALL ROWS HAS ONLY 1 COMMA IN PROPERTY ADDRESS.
SELECT *
FROM dbo.nashville_clean
WHERE LEN(PropertyAddress) - LEN(REPLACE(PropertyAddress,',','')) <> 1;

-- ALL ROWS HAS EXACTLY 1 COMMA IN PROPERTY ADDRESS.
---------------------------------------------
/* OWNER ADDRESS PROFILING */

SELECT OwnerAddress
FROM nashville_clean;

-- CHECK FOR NULL OWNER ADDRESSES .
SELECT COUNT(*) AS NullOwnerAddress
FROM dbo.nashville_clean
WHERE OwnerAddress IS NULL;

-- OWNER ADDRESS HAS 30462 NULL VALUES.

-- CHECK FORMAT OF OWNER ADDRESS.
SELECT TOP 25 OwnerAddress
FROM dbo.nashville_clean

-- FORMAT : [Street, City, State]
-- SEPERATORS: [',']

-- CHECK IF ALL ROWS HAS ONLY 2 COMMAS IN OWNER ADDRESS.
SELECT *
FROM dbo.nashville_clean
WHERE LEN(OwnerAddress) - LEN(REPLACE(OwnerAddress,',','')) <> 2;

-- ALL ROWS HAS EXACTLY 2 COMMAS IN OWNER ADDRESS.
---------------------------------------------

/* CHECK SALE PRICE FORMAT */
SELECT SalePrice
FROM dbo.nashville_clean
WHERE SalePrice LIKE '%$%'
   OR SalePrice LIKE '%,%';

-- SALE PRICE IS A STRING AND CONTAINS ',' OR '$'.
-- MUST CONVERT SALE PRICE TO DECIMAL.
---------------------------------------------

/* 
	DUPLICATE PROFILING 

	Unique Transaction Definition:-
	If all of the following factors are unique, then it is a Unique Transaction.
		-> ParcelID
		-> SaleDate
		-> SalePrice
		-> LegalReference 
*/

--  ROW COUNT 

SELECT COUNT(*) AS TotalRows
FROM dbo.nashville_clean;

-- DUPLICATE GROUPS COUNT

SELECT ParcelID, SaleDate, SalePrice, LegalReference, COUNT(*) AS [Duplicate Group Count]
FROM dbo.nashville_clean
GROUP BY  ParcelID, SaleDate, SalePrice, LegalReference
HAVING COUNT(*) > 1

-- CTE TO IDENTIFY POTENTIAL DUPLICATES

WITH DUPLICATE_ROWS_CTE AS
(
	SELECT *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) as [Row Number]
	FROM dbo.nashville_clean
)

SELECT *
FROM DUPLICATE_ROWS_CTE
WHERE [Row Number] > 1

-- DUPLICATE ROWS COUNT

WITH DUPLICATE_ROWS_CTE AS
(
	SELECT *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) as [Row Number]
	FROM dbo.nashville_clean
)

SELECT count(*) as [Count of Duplicates]
FROM DUPLICATE_ROWS_CTE
WHERE [Row Number] > 1

-- SUMMARY
/*
	- TOTAL ROWS BEFORE REMOVING DUPLICATES = 56477
	- TOTAL NUMBER DUPLICATE GROUPS = 104
	- TOTAL NUMBER OF DUPLICATE RECORDS IN EACH GROUP = 2
	- TOTAL NUMBER OF DUPLICATE ROWS = 104
	- REMAINING NUMBER OF ROWS AFTER REMOVING DUPLICATES = 56373
*/
---------------------------------------------

/* 
==========================================
	PROPERTY AGE METRICS DATA PROFILING
==========================================
*/


/* YEAR BUILT DATA PROFILING */

-- UNDERSTANDING YEAR BUILT DATA

SELECT MIN(YearBuilt) AS Oldest, MAX(YearBuilt) AS Youngest
FROM dbo.nashville_clean;

-- TOTAL CASES WHERE YEAR BUILT IS GREATER THAN THE SALE YEAR
SELECT COUNT(*) AS TOTAL,
SUM(CASE WHEN YearBuilt > SaleYear THEN 1 ELSE 0 END) AS [COUNT OF CASES],
CAST(100.0 * SUM(CASE WHEN YearBuilt > SaleYear THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS [% OF TOTAL]
FROM dbo.nashville_clean

-- CALCULATING WHAT PERCENTAGE OF YEAR BUILT DATASET HAS NULL VALUES
SELECT COUNT(*) AS TOTAL,
SUM(CASE WHEN YearBuilt IS NULL THEN 1 ELSE 0 END) AS NullCount,
CAST(100.0 * SUM(CASE WHEN YearBuilt IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS [% OF TOTAL]
FROM dbo.nashville_clean

-- SUMMARY
/*
	IN THE DATASET, 57.18% OF THE PROPERTIES HAVE MISSING YearBuilt VALUES. 1.38% (780 RECORDS) OF THE PROPERTIES
	HAVE YearBuilt GREATER THAN SaleYear. HENCE, WE WILL FIND THE PROPERTY AGE ONLY FOR THOSE
	RECORDS WHERE:-
		A. YearBuilt is not null
		B. YearBuilt <= SaleYear
*/

-- UNDERSTANDING PROPERTY AGE AT SALE DATA

SELECT MIN(PropertyAgeAtSale) AS LOWEST, MAX(PropertyAgeAtSale) AS HIGHEST
FROM dbo.nashville_clean

/*
	COMMENTS:

	CONSIDERING ALL PROPERTIES WHERE PropertyAgeAtSale IS NOT EMPTY, THE LOWEST AGE IS 0 AND THE HIGHEST AGE IS 216.
	BASED ON THESE FINDINGS, WE ARE CREATING THE FOLLOWING CATEGORIES OF AGE GROUPS:-
		1. 0-5 YEARS : 'NEW CONSTRUCTION'
		2. 6-15 YEARS : 'VERY NEW'
		3. 16-30 YEARS : 'MODERATELY NEW'
		4. 31-50 YEARS : 'ESTABLISHED'
		5. 51-75 YEARS : 'OLD'
		6. 76-100 YEARS : 'VERY OLD'
		7. 101+ YEARS : 'HISTORIC'
		8. NULL : 'UNKNOWN'
*/

---------------------------------------------