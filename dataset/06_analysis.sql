-- =============================================
-- Project: Nashville Housing Analysis
-- File: 06_analysis.sql
-- Description: Business & Market Analysis Queries
-- =============================================

USE NashvilleHousingDB;
GO

-- =============================================
-- SECTION 1: MARKET SUMMARY DATASET
-- =============================================
/*
	PURPOSE:
	THIS DATASET PROVIDES A HIGH-LEVEL MARKET SNAPSHOT OF THE NASHVILLE HOUSING MARKET.
	IT CONSOLIDATES VOLUME, PRICING, PROPERTY CHARACTERISTICS, AND TIME COVERAGE OMTO A SINGLE EXECUTIVE-READY SUMMARY TABLE.

	INCLUDES:

	1. CORE VOLUME METRICS
	   - TotalTransactions
	   - DistinctCities
	   - DistinctTaxDistricts

	2. TIME COVERAGE
	   - EarliestSaleDate
	   - LatestSaleDate
	   - DistinctYears

	3. PRICING METRICS
	   - AverageSalePrice
	   - MedianSalePrice
	   - MinimumSalePrice
	   - MaximumSalePrice

	4. PROPERTY CHARACTERISTICS
	   - AverageAcreage
	   - AverageBedrooms
	   - AverageFullBath

	USE CASE:
	This dataset feeds:
	   - KPI cards
	   - Dashboard header metrics
	   - Executive summary visuals
*/

WITH MEDIAN_CTE AS
(
	SELECT DISTINCT CAST(
	PERCENTILE_CONT(0.5)
	WITHIN GROUP (ORDER BY SalePrice)
	OVER ()
	AS DECIMAL(18,2)) AS MedianSalePrice
	FROM dbo.nashville_clean
)

SELECT COUNT(*) AS TotalTransactions,
COUNT(DISTINCT Property_City) AS DistinctCities,
COUNT(DISTINCT TaxDistrict) AS DistinctTaxDistricts,
MIN(SaleDate) AS EarliestSaleDate,
MAX(SaleDate) AS LatestSaleDate,
COUNT(DISTINCT SaleYear) AS DistinctYears,
CAST(AVG(SalePrice) AS DECIMAL(18,2)) AS AverageSalePrice,
MIN(SalePrice) AS MinimumSalePrice,
MAX(SalePrice) AS MaximumSalePrice,
(
	SELECT MedianSalePrice
	FROM MEDIAN_CTE
) AS MedianSalePrice,
CAST(AVG(Acreage) AS DECIMAL(18,2)) AS AverageAcreage,
AVG(Bedrooms) AS AverageBedrooms,
AVG(FullBath) AS AverageFullBath
FROM dbo.nashville_clean;


-- =============================================
-- SECTION 2: TIME-BASED MARKET TRENDS
-- =============================================
/* 
	OBJECTIVE: EVALUATE HOW THE HOUSING MARKET EVOLVES OVER TIME.

	KEY QUESTIONS:
	- Is the market expanding or contracting?
	- Is pricing increasing year-over-year?
	- Is transaction volume rising?
	- Are there cyclical patterns (boom/correction phases)?

	OUTPUT USE CASE:
	This dataset feeds:
	- Line charts
	- Area charts
	- Year-over-Year KPIs
	- Trend visuals in Power BI
*/


-- CTE TO CALCULATE YEARLY AGGREGATES
WITH BASE_YEARLY AS
(
	SELECT SaleYear,
	COUNT(*) AS TotalTransactions,
	AVG(SalePrice) AS AverageSalePrice,
	MIN(SalePrice) AS MinimumSalePrice,
	MAX(SalePrice) AS MaximumSalePrice
	FROM dbo.nashville_clean
	GROUP BY SaleYear
),
-- CTE TO CALCULATE YEARLY MEDIAN
MEDIAN_YEARLY AS
(
	SELECT DISTINCT SaleYear,
	PERCENTILE_CONT(0.5)
	WITHIN GROUP (ORDER BY SalePrice)
	OVER (PARTITION BY SaleYear)
	AS MedianSales
	FROM dbo.nashville_clean
),
-- CTE TO COMBINE YEARLY AGGREGATES AND YEARLY MEDIAN INTO 1 TABLE
YEARY_SUMMARY AS
(
	SELECT base.SaleYear,
	base.TotalTransactions,
	CAST(base.AverageSalePrice AS DECIMAL(10,2)) AS AverageSalePrice,
	CAST(base.MinimumSalePrice AS DECIMAL(10,2)) AS MinimumSalePrice,
	CAST(base.MaximumSalePrice AS DECIMAL(10,2)) AS MaximumSalePrice,
	CAST(median.MedianSales AS DECIMAL (18,2)) AS MedianSalePrice
	FROM BASE_YEARLY AS base
	JOIN MEDIAN_YEARLY AS median
	ON base.SaleYear = median.SaleYear
)

-- CALCULATION YoY PERCENTAGE CHANGES
SELECT SaleYear,
MinimumSalePrice as MinimumSalePrice,
MaximumSalePrice as MaximumSalePrice,
TotalTransactions as Volume,
LAG(TotalTransactions) OVER (ORDER BY SaleYear) AS PrevVolume,
CAST((CAST(TotalTransactions AS DECIMAL(10,2)) - LAG(CAST(TotalTransactions AS DECIMAL(10,2))) OVER (ORDER BY SaleYear)) / LAG(CAST(TotalTransactions AS DECIMAL(10,2))) OVER (ORDER BY SaleYear) * 100.0 AS DECIMAL(10,2)) AS [YoY_Volume_Growth%],
AverageSalePrice as AverageSalePrice,
LAG(AverageSalePrice) OVER (ORDER BY SaleYear) AS PrevAvgPrice,
CAST((AverageSalePrice - LAG(AverageSalePrice) OVER (ORDER BY SaleYear)) / LAG(AverageSalePrice) OVER (ORDER BY SaleYear) * 100.0 AS DECIMAL(10,2)) AS [YoY_Avg_Price_Growth%],
MedianSalePrice as MedianSalePrice,
LAG(MedianSalePrice) OVER (ORDER BY SaleYear) AS PrevMedianPrice,
CAST((MedianSalePrice - LAG(MedianSalePrice) OVER (ORDER BY SaleYear)) / LAG(MedianSalePrice) OVER (ORDER BY SaleYear) * 100.0 AS DECIMAL(10,2)) AS [YoY_Median_Growth%]
FROM YEARY_SUMMARY

/*
	SUMMARY OF FINDINGS

	1. MARKET GROWTH
	   The market experienced strong expansion between 2013–2015,
	   followed by a moderation phase in 2016.

	2. PRICING TRENDS
	   Median prices increased steadily across the observed period,
	   indicating broad-based appreciation.
	   Average prices showed higher volatility due to luxury outliers.

	3. VOLUME TRENDS
	   Transaction volume peaked in 2015,
	   suggesting heightened demand during the early growth phase.

	4. CYCLICAL BEHAVIOR
	   The pattern reflects a normal expansion followed by stabilization,
	   rather than structural market decline.

	NOTE:
	Data for 2017–2018 is unavailable.
	2019 data is incomplete.
	Time-based analysis is therefore focused on 2013–2016.
*/

-- ============================================================
-- SECTION 3: PROPERTY AGE ANALYSIS
-- ============================================================

/*
	OBJECTIVE:
	ASSESS HOW PROPERTY AGE INFLUENCES BOTH DEMAND CONCENTRATION AND PRICING BEHAVIOUR WITHIN
	THE NASHVILLE HOUSING MARKET

	ANALYTICAL FRAMEWORK:

	1. Demand by PropertyAgeGroup
	   - TotalTransactions
	   - MarketShare%

	2. Pricing Metrics by PropertyAgeGroup
	   - MinimumSalePrice
	   - MaximumSalePrice
	   - AverageSalePrice
	   - MedianSalePrice

	APPROACH:
	- AGE_VOLUME measures demand concentration.
	- AGE_PRICING calculates pricing distribution using window functions.
	- Final output joins both for a consolidated age-segment view.

	BUSINESS QUESTIONS:
	- Is the market driven by new construction or resale inventory?
	- Which age segments command pricing premiums?
	- Does pricing distribution vary across lifecycle stages?
*/

WITH AGE_VOLUME AS
(
	SELECT PropertyAgeGroup,
	COUNT(*) AS TotalTransactions,
	CAST(100.0 * CAST(COUNT(*) AS DECIMAL(10,2)) / SUM(CAST(COUNT(*) AS DECIMAL(10,2))) OVER () AS DECIMAL(10,2)) AS [MarketShare%]
	FROM dbo.nashville_clean
	WHERE PropertyAgeGroup IS NOT NULL AND PropertyAgeGroup NOT IN ('Unknown')
	GROUP BY PropertyAgeGroup
),
AGE_PRICING AS
(
	SELECT DISTINCT PropertyAgeGroup as [PropertyAgeGroup],
	ROUND(MIN(SalePrice) OVER (PARTITION BY PropertyAgeGroup),2) AS [MinimumSalePrice],
	ROUND(MAX(SalePrice) OVER (PARTITION BY PropertyAgeGroup),2) AS [MaximumSalePrice],
	CAST(AVG(SalePrice) OVER (PARTITION BY PropertyAgeGroup) AS DECIMAL(18,2)) AS [AverageSalePrice],
	CAST(PERCENTILE_CONT(0.5)
	WITHIN GROUP (ORDER BY SalePrice)
	OVER (PARTITION BY PropertyAgeGroup) AS DECIMAL(18,2)) AS [MedianSalePrice]
	FROM dbo.nashville_clean
	WHERE PropertyAgeGroup IS NOT NULL
	AND PropertyAgeGroup NOT IN ('Unknown')
)
SELECT volume.PropertyAgeGroup AS [PropertyAgeGroup],
volume.TotalTransactions AS [Volume],
volume.[MarketShare%] AS [MarketShare%],
price.MinimumSalePrice AS [MinimumSalePrice],
price.MaximumSalePrice AS [MaximumSalePrice],
price.AverageSalePrice AS [AverageSalePrice],
price.MedianSalePrice AS [MedianSalePrice]
FROM AGE_VOLUME AS volume
JOIN AGE_PRICING AS price
ON volume.PropertyAgeGroup = price.PropertyAgeGroup
ORDER BY
CASE volume.PropertyAgeGroup
	WHEN 'New Construction' THEN 1
	WHEN 'Very New' THEN 2
	WHEN 'Moderately New' THEN 3
	WHEN 'Established' THEN 4
	WHEN 'Old' THEN 5
	WHEN 'Very Old' THEN 6
	WHEN 'Historic' THEN 7
END;

/*
	SECTION FINDINGS

	1. MARKET DRIVER
	   The Nashville housing market is primarily driven by resale inventory.
	   Approximately 42% of all transactions occur within the "Old" segment.
	   Combined with "Established" and "Very Old" properties,
	   aging housing stock forms the volume backbone of the market.

	2. PRICING PREMIUMS
	   While resale drives volume, pricing premiums are concentrated in:
	   - New Construction
	   - Very New
	   - Historic properties

	   Newer homes command higher median prices.
	   Historic homes function as a niche premium segment.

	3. PRICING DISTRIBUTION
	   Pricing behavior varies meaningfully across age segments.
	   - Newer homes show higher price floors and wider dispersion.
	   - Established and Old properties demonstrate greater affordability.
	   - Historic homes exhibit high variability due to uniqueness.

	CONCLUSION:
	The market is volume-driven by aging inventory,
	but value-supported by newer and premium property segments.
*/



-- =============================================
-- SECTION 4: GEOGRAPHIC ANALYSIS
-- =============================================
/*
	OBJECTIVE: EVALUATE HOW GEOGRAPHY (Property_City) INFLUENCES DEMAND CONCENTRATION AND PRICING
	ACROSS THE NASHVILLE MARKET.

	ANALYSIS DIMENSIONS:
	- Transaction volume (market concentration)
	- Pricing levels (median & average)
	- Pricing distribution (min/max spread)

	BUSINESS QUESTIONS:
	- Which cities drive transaction activity?
	- Which cities command pricing premiums?
	- Is pricing distribution uniform across locations?

*/

-- VOLUME & MARKET SHARE BY CITY
WITH CITY_VOLUME AS
(
	SELECT Property_City AS [City],
	COUNT(*) AS [Total Volume],
	CAST(CAST(COUNT(*) AS DECIMAL(18,2)) / SUM(CAST(COUNT(*) AS DECIMAL(18,2))) OVER () * 100.0 AS DECIMAL(18,2)) AS [MarketShare%]
	FROM dbo.nashville_clean
	WHERE Property_City IS NOT NULL
	AND Property_City NOT IN ('UNKNOWN')
	GROUP BY Property_City
),

-- PRICING METRICS BY CITY
CITY_PRICING AS
(
	SELECT DISTINCT Property_City as [City],
	ROUND(MIN(SalePrice) OVER (PARTITION BY Property_City), 2) AS [MinimumSalePrice],
	ROUND(MAX(SalePrice) OVER (PARTITION BY Property_City), 2) AS [MaximumSalePrice],
	CAST(AVG(SalePrice) OVER (PARTITION BY Property_City) AS DECIMAL(18,2))[AverageSalePrice],
	CAST(
	PERCENTILE_CONT(0.5)
	WITHIN GROUP (ORDER BY SalePrice)
	OVER (PARTITION BY Property_City)
	AS DECIMAL(18,2)) AS [MedianSalePrice]
	FROM dbo.nashville_clean
	WHERE Property_City NOT IN ('UNKNOWN')
)
SELECT volume.City,
volume.[Total Volume],
volume.[MarketShare%],
price.MinimumSalePrice,
price.MaximumSalePrice,
price.AverageSalePrice,
price.MedianSalePrice
FROM CITY_VOLUME volume
JOIN CITY_PRICING price
ON volume.City = price.City
WHERE [Total Volume] > 50
ORDER BY price.MedianSalePrice DESC

/*
	SECTION FINDINGS

	1. VOLUME CONCENTRATION
	   The market is highly centralized in Nashville (~71% of total volume).
	   Secondary contributors include:
	   - Antioch
	   - Hermitage
	   - Madison
	   - Brentwood

	2. PRICING PREMIUMS
	   Suburban municipalities such as:
	   - Nolensville
	   - Brentwood
	   - Mount Juliet
	   command higher median sale prices than Nashville proper.

	   These areas likely reflect:
	   - Higher-income buyer concentration
	   - Larger properties
	   - Newer development patterns

	3. PRICING DISTRIBUTION
	   Pricing dispersion varies significantly by city:
	   - Nashville exhibits wide range due to luxury outliers.
	   - Premium suburbs show tighter clustering at higher levels.
	   - Lower-tier cities display compressed pricing bands.

	CONCLUSION:
	The Nashville housing market is geographically segmented.
	Volume is concentrated in the urban core,
	while pricing premiums are concentrated in suburban markets.

*/
-- =============================================
-- SECTION 5: KEY MARKET INSIGHTS
-- =============================================
/*
	EXECUTIVE SUMMARY

	This analysis evaluated the Nashville housing market across three dimensions:
	1. Time-based market trends
	2. Property age segmentation
	3. Geographic segmentation

	TIME-BASED INSIGHTS
	- Strong expansion observed between 2013–2015.
	- Median prices increased consistently.
	- Market behavior reflects cyclical stabilization rather than structural decline.

	PROPERTY AGE INSIGHTS
	- Resale inventory drives transaction volume.
	- New construction and historic homes command pricing premiums.
	- Pricing behavior varies across lifecycle stages.

	GEOGRAPHIC INSIGHTS
	- Nashville dominates transaction volume.
	- Suburban markets command pricing premiums.
	- Pricing dispersion varies materially across municipalities.

	OVERALL CONCLUSION

	The Nashville housing market is:

	- Volume-driven by urban resale inventory
	- Price-supported by suburban premium markets
	- Structurally segmented by geography and property age
	- Experiencing steady long-term appreciation (within available data window)

	The market reflects a healthy, segmented ecosystem
	rather than uniform or speculative pricing behavior.
*/