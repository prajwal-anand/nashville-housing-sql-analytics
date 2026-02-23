# 🏠 Nashville Housing Market Analysis  
## Advanced SQL Analytics & Market Segmentation (SQL Server)

---

## 📌 Project Overview

This project is a structured, end-to-end SQL analytics case study analyzing the Nashville housing market using Microsoft SQL Server.

The objective was to transform raw transactional housing data into a clean, analysis-ready dataset and extract meaningful business insights using advanced SQL techniques.

This repository emphasizes SQL-based analytical modeling rather than dashboard visualization.

### SQL Depth Demonstrated:

- Structured data cleaning workflows
- Feature engineering
- Window functions (PERCENTILE_CONT, LAG, ROW_NUMBER)
- Market share modeling
- Time-series analysis
- Segmentation logic
- Business interpretation from raw data

---

## 🏗 Project Architecture

The project follows a structured, production-style workflow:

```
Raw Dataset
↓
Data Profiling
↓
Data Cleaning
↓
Feature Engineering
↓
Analytical Modeling
↓
Business Insights
```

Each stage is separated into dedicated SQL files to reflect professional project organization and clear analytical layering.

---

## 📂 Repository Structure

```
nashville-housing-sql-analytics/
│
├── dataset/
│ ├── 01_database_setup.sql
│ ├── 02_table_creation.sql
│ ├── 03_data_profiling.sql
│ ├── 04_data_cleaning.sql
│ ├── 05_feature_engineering.sql
│ └── 06_analysis.sql
│
└── README.md

```

## 🧹 1️⃣ Data Cleaning

Key transformations performed:

- Standardizing categorical values (`SoldAsVacant`)
- Converting `SalePrice` into numeric format
- Imputing missing `PropertyAddress` values using self-join logic
- Splitting composite address fields into structured columns
- Removing duplicate records using `ROW_NUMBER()`
- Creating a structured analytical table (`nashville_clean`)

The resulting dataset is normalized and analysis-ready.

---

## 🏗 2️⃣ Feature Engineering

Engineered analytical features to support segmentation and time-series modelling:

- `SaleYear`, `SaleMonth`, `SaleQuarter`
- `PropertyAgeAtSale`
- `PropertyAgeGroup` classification
- Time-based modeling fields
- Market share calculations

This step transformed raw transactional data into a structured analytical layer suitable for advanced modelling.

---

## 📊 3️⃣ Time-Based Market Analysis

Performed trend and growth analysis using window functions.

### Techniques Used:

- `PERCENTILE_CONT` for median pricing
- `LAG()` for Year-over-Year growth modeling
- Partitioned aggregations for yearly summaries

### Key Findings:

- Strong expansion phase between 2013–2015  
- Pricing growth outpaced volume growth in certain periods  
- Post-2015 stabilization reflects cyclical normalization rather than structural collapse  
- Median price was used over average due to right-skewed pricing distribution

The market demonstrates cyclical growth behavior consistent with normal economic patterns.

---

## 🏘 4️⃣ Property Age Segmentation

Segmented properties by lifecycle stage to understand pricing and demand concentration.

### Key Findings:

- ~42% of transactions occur in older resale inventory  
- New construction and historic homes command pricing premiums  
- Pricing dispersion varies significantly across age segments  
- Older homes dominate volume, while newer homes dominate premium positioning  

The housing market is structurally segmented by property age.

---

## 📍 5️⃣ Geographic Segmentation

Analyzed transaction volume and pricing behavior across municipalities.

### Key Findings:

- Nashville accounts for ~71% of total transaction volume  
- Suburban cities (e.g., Nolensville, Brentwood) command higher median prices  
- Pricing dispersion varies materially across cities  
- Urban core shows wider price spread due to mixed-income and luxury outliers  

The market exhibits clear geographic segmentation rather than uniform pricing behavior.

---

## 🧠 Advanced SQL Techniques Demonstrated

This project showcases strong SQL depth including:

- Common Table Expressions (CTEs)
- Window Functions:
  - `ROW_NUMBER()`
  - `PERCENTILE_CONT()`
  - `LAG()`
- Partitioned aggregations
- Market share modeling using window sums
- Duplicate detection via partition logic
- Time-series growth modeling
- Structured query layering

---
## 🎯 Business Questions Answered

- Is the housing market growing?  
- Is pricing increasing?  
- Is transaction volume increasing?  
- Which property age segments drive demand?  
- Which age segments command pricing premiums?  
- Is the market geographically concentrated?  
- Does pricing distribution vary across locations?  

Each question is answered using structured SQL modeling and analytical reasoning.

---

## 🏁 Conclusion

This project demonstrates the ability to:

- Transform messy raw data into structured analytical datasets  
- Apply statistical reasoning within SQL  
- Design production-grade query architecture  
- Use window functions effectively  
- Derive meaningful business insights from transactional data  

This repository serves as a SQL depth showcase, emphasizing analytical thinking and structured query design rather than visualization tools.
