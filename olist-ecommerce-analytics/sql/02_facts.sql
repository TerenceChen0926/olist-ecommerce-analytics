/* Creates typed transaction facts without modifying raw tables. */
USE Olist_Ecommerce_Analytics;
GO

DROP TABLE IF EXISTS dbo.fact_order_items;
DROP TABLE IF EXISTS dbo.fact_payments;
DROP TABLE IF EXISTS dbo.fact_reviews;
DROP TABLE IF EXISTS dbo.fact_orders;
GO

CREATE TABLE dbo.fact_orders (
    order_id NVARCHAR(50) NOT NULL PRIMARY KEY,
    customer_id NVARCHAR(50) NOT NULL,
    order_status NVARCHAR(30) NOT NULL,
    order_purchase_timestamp DATETIME2 NOT NULL,
    order_approved_at DATETIME2 NULL,
    order_delivered_carrier_date DATETIME2 NULL,
    order_delivered_customer_date DATETIME2 NULL,
    order_estimated_delivery_date DATETIME2 NULL,
    delivery_days INT NULL,
    is_delivered BIT NOT NULL,
    is_on_time_delivery BIT NULL
);
GO

INSERT INTO dbo.fact_orders
SELECT
    LTRIM(RTRIM(order_id)),
    LTRIM(RTRIM(customer_id)),
    LTRIM(RTRIM(order_status)),
    TRY_CONVERT(DATETIME2, order_purchase_timestamp),
    TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(order_approved_at)), '')),
    TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(order_delivered_carrier_date)), '')),
    TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(order_delivered_customer_date)), '')),
    TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(order_estimated_delivery_date)), '')),
    CASE
        WHEN order_status = 'delivered'
         AND TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(order_delivered_customer_date)), '')) IS NOT NULL
         AND TRY_CONVERT(DATETIME2, order_purchase_timestamp)
             <= TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(order_delivered_customer_date)), ''))
        THEN DATEDIFF(
            DAY,
            TRY_CONVERT(DATETIME2, order_purchase_timestamp),
            TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(order_delivered_customer_date)), ''))
        )
    END,
    CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END,
    CASE
        WHEN order_status = 'delivered'
         AND TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(order_delivered_customer_date)), '')) IS NOT NULL
         AND TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(order_estimated_delivery_date)), '')) IS NOT NULL
        THEN CASE WHEN TRY_CONVERT(DATETIME2, order_delivered_customer_date)
                       <= TRY_CONVERT(DATETIME2, order_estimated_delivery_date)
                  THEN 1 ELSE 0 END
    END
FROM dbo.olist_orders_dataset;
GO

CREATE TABLE dbo.fact_order_items (
    order_id NVARCHAR(50) NOT NULL,
    order_item_id INT NOT NULL,
    product_id NVARCHAR(50) NOT NULL,
    seller_id NVARCHAR(50) NOT NULL,
    shipping_limit_date DATETIME2 NULL,
    price DECIMAL(18, 2) NOT NULL,
    freight_value DECIMAL(18, 2) NOT NULL,
    total_item_value AS (price + freight_value),
    CONSTRAINT PK_fact_order_items PRIMARY KEY (order_id, order_item_id)
);
GO

INSERT INTO dbo.fact_order_items (
    order_id, order_item_id, product_id, seller_id,
    shipping_limit_date, price, freight_value
)
SELECT
    LTRIM(RTRIM(order_id)),
    TRY_CONVERT(INT, order_item_id),
    LTRIM(RTRIM(product_id)),
    LTRIM(RTRIM(seller_id)),
    TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(shipping_limit_date)), '')),
    TRY_CONVERT(DECIMAL(18, 2), price),
    TRY_CONVERT(DECIMAL(18, 2), freight_value)
FROM dbo.olist_order_items_dataset;
GO

CREATE TABLE dbo.fact_payments (
    order_id NVARCHAR(50) NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type NVARCHAR(50) NULL,
    payment_installments INT NULL,
    payment_value DECIMAL(18, 2) NOT NULL,
    CONSTRAINT PK_fact_payments PRIMARY KEY (order_id, payment_sequential)
);
GO

INSERT INTO dbo.fact_payments (
    order_id, payment_sequential, payment_type,
    payment_installments, payment_value
)
SELECT
    LTRIM(RTRIM(order_id)),
    TRY_CONVERT(INT, payment_sequential),
    NULLIF(LTRIM(RTRIM(payment_type)), ''),
    TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(payment_installments)), '')),
    TRY_CONVERT(DECIMAL(18, 2), payment_value)
FROM dbo.olist_order_payments_dataset;
GO

CREATE TABLE dbo.fact_reviews (
    review_key INT IDENTITY(1, 1) NOT NULL PRIMARY KEY,
    review_id NVARCHAR(50) NOT NULL,
    order_id NVARCHAR(50) NOT NULL,
    review_score INT NOT NULL,
    review_comment_title NVARCHAR(100) NULL,
    review_comment_message NVARCHAR(MAX) NULL,
    review_creation_date DATETIME2 NULL,
    review_answer_timestamp DATETIME2 NULL
);
GO

INSERT INTO dbo.fact_reviews (
    review_id, order_id, review_score, review_comment_title,
    review_comment_message, review_creation_date, review_answer_timestamp
)
SELECT
    LTRIM(RTRIM(review_id)),
    LTRIM(RTRIM(order_id)),
    TRY_CONVERT(INT, review_score),
    NULLIF(LTRIM(RTRIM(review_comment_title)), ''),
    NULLIF(LTRIM(RTRIM(review_comment_message)), ''),
    TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(review_creation_date)), '')),
    TRY_CONVERT(DATETIME2, NULLIF(LTRIM(RTRIM(review_answer_timestamp)), ''))
FROM dbo.olist_order_reviews_dataset;
GO

SELECT 'fact_orders' AS table_name, COUNT(*) AS row_count FROM dbo.fact_orders
UNION ALL SELECT 'fact_order_items', COUNT(*) FROM dbo.fact_order_items
UNION ALL SELECT 'fact_payments', COUNT(*) FROM dbo.fact_payments
UNION ALL SELECT 'fact_reviews', COUNT(*) FROM dbo.fact_reviews;
GO
