/* =====================================================
   Olist Ecommerce Analytics
   Step 4: Create clean dimension tables

   This script reads the imported raw tables and creates
   clean, typed tables for Power BI. It does not modify the
   raw olist_* tables.
   ===================================================== */

USE Olist_Ecommerce_Analytics;
GO

/* =====================================================
   1. Customer dimension
   Grain: one row per customer_id (an order-level customer key)
   ===================================================== */

DROP TABLE IF EXISTS dbo.dim_customers;
GO

CREATE TABLE dbo.dim_customers (
    customer_id NVARCHAR(50) NOT NULL PRIMARY KEY,
    customer_unique_id NVARCHAR(50) NULL,
    customer_zip_code_prefix NVARCHAR(50) NULL,
    customer_city NVARCHAR(100) NULL,
    customer_state NVARCHAR(10) NULL
);
GO

INSERT INTO dbo.dim_customers (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
SELECT
    LTRIM(RTRIM(customer_id)),
    NULLIF(LTRIM(RTRIM(customer_unique_id)), ''),
    NULLIF(LTRIM(RTRIM(customer_zip_code_prefix)), ''),
    NULLIF(LTRIM(RTRIM(customer_city)), ''),
    NULLIF(LTRIM(RTRIM(customer_state)), '')
FROM dbo.olist_customers_dataset;
GO


/* =====================================================
   2. Seller dimension
   Grain: one row per seller_id
   ===================================================== */

DROP TABLE IF EXISTS dbo.dim_sellers;
GO

CREATE TABLE dbo.dim_sellers (
    seller_id NVARCHAR(50) NOT NULL PRIMARY KEY,
    seller_zip_code_prefix NVARCHAR(50) NULL,
    seller_city NVARCHAR(100) NULL,
    seller_state NVARCHAR(10) NULL
);
GO

INSERT INTO dbo.dim_sellers (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT
    LTRIM(RTRIM(seller_id)),
    NULLIF(LTRIM(RTRIM(seller_zip_code_prefix)), ''),
    NULLIF(LTRIM(RTRIM(seller_city)), ''),
    NULLIF(LTRIM(RTRIM(seller_state)), '')
FROM dbo.olist_sellers_dataset;
GO


/* =====================================================
   3. Product dimension
   Grain: one row per product_id
   - Adds English category where a translation exists.
   - Uses Portuguese category as fallback.
   - Uses Unknown when the source category is missing.
   - Converts product measures from raw text to integers.
   ===================================================== */

DROP TABLE IF EXISTS dbo.dim_products;
GO

CREATE TABLE dbo.dim_products (
    product_id NVARCHAR(50) NOT NULL PRIMARY KEY,
    product_category_name_portuguese NVARCHAR(100) NULL,
    product_category_name_english NVARCHAR(100) NOT NULL,
    product_name_length INT NULL,
    product_description_length INT NULL,
    product_photos_qty INT NULL,
    product_weight_g INT NULL,
    product_length_cm INT NULL,
    product_height_cm INT NULL,
    product_width_cm INT NULL
);
GO

INSERT INTO dbo.dim_products (
    product_id,
    product_category_name_portuguese,
    product_category_name_english,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT
    LTRIM(RTRIM(p.product_id)),
    NULLIF(LTRIM(RTRIM(p.product_category_name)), ''),
    COALESCE(
        NULLIF(LTRIM(RTRIM(t.product_category_name_english)), ''),
        NULLIF(LTRIM(RTRIM(p.product_category_name)), ''),
        'Unknown'
    ),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(p.product_name_lenght)), '')),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(p.product_description_lenght)), '')),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(p.product_photos_qty)), '')),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(p.product_weight_g)), '')),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(p.product_length_cm)), '')),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(p.product_height_cm)), '')),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(p.product_width_cm)), ''))
FROM dbo.olist_products_dataset AS p
LEFT JOIN dbo.product_category_name_translation AS t
    ON LTRIM(RTRIM(p.product_category_name)) = LTRIM(RTRIM(t.product_category_name));
GO


/* =====================================================
   4. Dimension-table validation
   ===================================================== */

SELECT 'dim_customers' AS table_name, COUNT(*) AS row_count
FROM dbo.dim_customers
UNION ALL
SELECT 'dim_sellers', COUNT(*)
FROM dbo.dim_sellers
UNION ALL
SELECT 'dim_products', COUNT(*)
FROM dbo.dim_products;
GO

SELECT
    SUM(CASE WHEN product_category_name_english = 'Unknown' THEN 1 ELSE 0 END)
        AS products_with_unknown_category,
    SUM(CASE WHEN product_category_name_portuguese IS NOT NULL
              AND product_category_name_english = product_category_name_portuguese
             THEN 1 ELSE 0 END)
        AS products_using_portuguese_fallback
FROM dbo.dim_products;
GO
