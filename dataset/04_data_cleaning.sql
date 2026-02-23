-- =========================================
-- Project: Nashville Housing Analysis
-- Data Cleaning Script
-- ==========================================

USE NashvilleHousingDB;

/* STANDARDIZE SOLD AS VACANT COLUMN DATA */

UPDATE dbo.nashville_clean
SET SoldAsVacant =
CASE
	WHEN LOWER(SoldAsVacant) IN ('y','yes') THEN 'Yes'
	WHEN LOWER(SoldAsVacant) IN ('n','no') THEN 'No'
	ELSE NULL
END

SELECT DISTINCT SoldAsVacant
FROM dbo.nashville_clean

---------------------------------------------

/* SALE PRICE CLEANING */

SELECT SalePrice
FROM dbo.nashville_clean


SELECT REPLACE(REPLACE(SalePrice,'$',''),',','')
FROM dbo.nashville_clean
WHERE SalePrice LIKE '%$%'
   OR SalePrice LIKE '%,%';

-- REMOVE '$' AND ',' FROM SALE PRICE.

UPDATE dbo.nashville_clean
SET SalePrice = REPLACE(REPLACE(SalePrice,'$',''),',','');

-- CONVERT SALEPRICE TO DECIMAL.

ALTER TABLE dbo.nashville_clean
ALTER COLUMN SalePrice DECIMAL(18,2);

-- VALIDATE CHANGES.

SELECT data_type
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'nashville_clean' and column_name = 'SalePrice'

---------------------------------------------

/* PROPERTY ADDRESS CLEANING */

-- POPULATE NULL PROPERTY ADDRESSES.

SELECT * 
FROM nashville_clean
WHERE parcelid = '026 05 0 017.00';


UPDATE a
SET a.propertyaddress = b.propertyaddress
FROM nashville_clean a
JOIN nashville_clean b
ON a.parcelid = b.parcelid
AND a.uniqueid <> b.uniqueid
WHERE a.propertyaddress IS NULL
AND b.propertyaddress IS NOT NULL;

SELECT COUNT(*) AS NullPropertyAddress
FROM dbo.nashville_clean
WHERE PropertyAddress IS NULL;


SELECT DISTINCT PropertyAddress
FROM dbo.nashville_clean;

-- ADD 2 COLUMNS FOR THE STREET AND CITY OF THE PROPERTY.

ALTER TABLE dbo.nashville_clean
ADD Property_Street NVARCHAR(255);


ALTER TABLE dbo.nashville_clean
ADD Property_City NVARCHAR(255);

SELECT PropertyAddress, Property_Street, Property_City
FROM dbo.nashville_clean


-- SPLIT PROPERTY ADDRESS INTO STREET AND CITY COLUMNS.

SELECT PropertyAddress,
LEFT(PropertyAddress,CHARINDEX(',', PropertyAddress)-1) as Property_Street,
LTRIM(RIGHT(PropertyAddress,len(PropertyAddress) - CHARINDEX(',',PropertyAddress))) as Property_City
FROM dbo.nashville_clean;

-- FILL Property_Street
UPDATE dbo.nashville_clean
SET Property_Street = LEFT(PropertyAddress, CHARINDEX(',',PropertyAddress) - 1);

-- FILL Property_City
UPDATE dbo.nashville_clean
SET Property_City = LTRIM(RIGHT(PropertyAddress, LEN(PropertyAddress) - CHARINDEX(',',PropertyAddress)));

-- VALIDATE CHANGES
SELECT *
FROM dbo.nashville_clean
WHERE Property_Street IS NULL
OR Property_City IS NULL;

-- REMOVING REDUNDANT PROPERTY ADDRESS COLUMN AFTER NORMALIZATION.

ALTER TABLE dbo.nashville_clean
DROP COLUMN PropertyAddress;

---------------------------------------------

/* OWNER ADDRESS CLEANING */

SELECT OwnerAddress
FROM dbo.nashville_clean;

-- CREATE 3 COLUMNS FOR STREET, CITY AND STATE OF OWNER.

ALTER TABLE dbo.nashville_clean
ADD Owner_Street NVARCHAR(255);

ALTER TABLE dbo.nashville_clean
ADD Owner_City NVARCHAR(255);

ALTER TABLE dbo.nashville_clean
ADD Owner_State NVARCHAR(255);


SELECT OwnerAddress, Owner_Street, Owner_City, Owner_State
FROM dbo.nashville_clean

-- SPLIT OWNER ADDRESS INTO STREET, CITY AND STATE COLUMNS.

SELECT OwnerAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) as Owner_Street,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) as Owner_City,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) as Owner_State
FROM dbo.nashville_clean
WHERE OwnerAddress IS NOT NULL;

-- FILL Owner_Street
UPDATE dbo.nashville_clean
SET Owner_Street = PARSENAME(REPLACE(OwnerAddress, ',','.'),3)
WHERE OwnerAddress IS NOT NULL;

-- FILL Owner_City
UPDATE dbo.nashville_clean
SET Owner_City = PARSENAME(REPLACE(OwnerAddress, ',','.'),2)
WHERE OwnerAddress IS NOT NULL;

-- FILL Owner_State
UPDATE dbo.nashville_clean
SET Owner_State = PARSENAME(REPLACE(OwnerAddress, ',','.'),1)
WHERE OwnerAddress IS NOT NULL;

-- VALIDATION

SELECT *
FROM dbo.nashville_clean
WHERE OwnerAddress IS NOT NULL
  AND (OwnerStreet IS NULL OR OwnerCity IS NULL OR OwnerState IS NULL);

-- SUCCESSFULLY SPLIT ALL NON-NULL OWNER ADDRESSES.


-- REMOVING REDUNDANT ORDIGINAL OWNER ADDRESS COLUMN AFTER NORMALIZATION

ALTER TABLE dbo.nashville_clean
DROP COLUMN OwnerAddress;

---------------------------------------------

/* DATA CLEANING : REMOVING DUPLICATE ROWS */

WITH DUPLICATE_ROWS_CTE AS
(
	SELECT *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) as [Row Number]
	FROM dbo.nashville_clean
)

DELETE FROM DUPLICATE_ROWS_CTE
WHERE [Row Number] > 1

/* VALIDATE CHANGES */

-- ROW COUNT

SELECT COUNT(*)
FROM dbo.nashville_clean;


-- CHECK IF THERE ARE ANY DUPLICATES

WITH DUPLICATE_ROWS_CTE AS
(
	SELECT *,
	ROW_NUMBER() OVER (PARTITION BY ParcelID, SaleDate, SalePrice, LegalReference ORDER BY UniqueID) as [Row Number]
	FROM dbo.nashville_clean
)

SELECT COUNT(*) AS [Count of Duplicates]
FROM DUPLICATE_ROWS_CTE
WHERE [Row Number] > 1

---------------------------------------------
