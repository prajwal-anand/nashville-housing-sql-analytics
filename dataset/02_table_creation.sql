-- =========================================
-- Project: Nashville Housing Analysis
-- Table Creation Script
-- =========================================

USE NashvilleHousingDB;
GO

CREATE TABLE dbo.nashville_raw (
    UniqueID INT NOT NULL,
    ParcelID NVARCHAR(50) NOT NULL,
    LandUse NVARCHAR(100) NOT NULL,
    PropertyAddress NVARCHAR(255) NULL,
    SaleDate DATE NOT NULL,
    SalePrice NVARCHAR(50) NOT NULL,  -- kept as text for cleaning stage
    LegalReference NVARCHAR(255) NOT NULL,
    SoldAsVacant NVARCHAR(10) NOT NULL,
    OwnerName NVARCHAR(255) NULL,
    OwnerAddress NVARCHAR(255) NULL,
    Acreage DECIMAL(10,2) NULL,
    TaxDistrict NVARCHAR(50) NULL,
    LandValue DECIMAL(18,2) NULL,
    BuildingValue DECIMAL(18,2) NULL,
    TotalValue DECIMAL(18,2) NULL,
    YearBuilt SMALLINT NULL,
    Bedrooms TINYINT NULL,
    FullBath TINYINT NULL,
    HalfBath TINYINT NULL
);

-- Creating a copy of nashville_raw on which all data cleaning and transformations will be applied

SELECT * INTO dbo.nashville_clean
FROM dbo.nashville_raw;

SELECT * FROM dbo.nashville_clean;

DROP TABLE IF EXISTS dbo.nashville_clean;