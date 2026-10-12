/* Validates clean model keys, matches and key sales totals. */
USE Olist_Ecommerce_Analytics;
GO

SELECT 'fact_orders_without_customer' AS check_name, COUNT(*) AS issue_count
FROM dbo.fact_orders AS o
LEFT JOIN dbo.dim_customers AS c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'order_items_without_product', COUNT(*)
FROM dbo.fact_order_items AS oi
LEFT JOIN dbo.dim_products AS p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL
UNION ALL
SELECT 'order_items_without_seller', COUNT(*)
FROM dbo.fact_order_items AS oi
LEFT JOIN dbo.dim_sellers AS s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL
UNION ALL
SELECT 'order_items_without_order', COUNT(*)
FROM dbo.fact_order_items AS oi
LEFT JOIN dbo.fact_orders AS o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'payments_without_order', COUNT(*)
FROM dbo.fact_payments AS pay
LEFT JOIN dbo.fact_orders AS o ON pay.order_id = o.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'reviews_without_order', COUNT(*)
FROM dbo.fact_reviews AS r
LEFT JOIN dbo.fact_orders AS o ON r.order_id = o.order_id
WHERE o.order_id IS NULL;
GO

SELECT
    SUM(price) AS product_sales,
    SUM(freight_value) AS freight_value,
    SUM(total_item_value) AS total_item_value
FROM dbo.fact_order_items;
GO

SELECT SUM(payment_value) AS customer_payment_value
FROM dbo.fact_payments;
GO
