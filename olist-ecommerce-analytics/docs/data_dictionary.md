# Model and data grain

These names describe the SQL snapshots in `sql/`. The Power BI report uses some
renamed columns; see the mapping below before reconnecting the report.

| Table | One row represents | Key | Recorded rows |
|---|---|---|---:|
| `dim_customers` | Order-level customer record | `customer_id` | 99,441 |
| `dim_sellers` | Seller | `seller_id` | 3,095 |
| `dim_products` | Product | `product_id` | 32,951 |
| `dim_date` | Calendar day | `date_key` | 1,314 |
| `fact_orders` | Order | `order_id` | 99,441 |
| `fact_order_items` | Item within an order | `order_id, order_item_id` | 112,650 |
| `fact_payments` | Payment sequence within an order | `order_id, payment_sequential` | 103,886 |
| `fact_reviews` | Review record | Surrogate `review_key` | 99,224 |

`customer_id` identifies an order-level customer record. Use
`customer_unique_id` for distinct-person or repeat-purchase analysis. The
current source has one order per `customer_id`; 99,441 customer records should
not be described as 99,441 distinct people.

An order can have multiple items, payment records, and reviews. Aggregate each
fact at its own grain. Joining item rows directly to payment rows before
summing amounts can multiply sales and payment values.

## Relationship paths

- Customer and purchase-date dimensions filter `fact_orders`.
- Orders filter item, payment, and review facts.
- Product and seller dimensions filter `fact_order_items`.
- Date analysis uses the order purchase date, not the review creation date or
  actual delivery date.
- Date-to-order matching requires a date-only purchase column derived from the
  timestamp. Mark the calendar as the report's date table.

Product filtering does not automatically propagate back from items to orders,
payments, or reviews in a single-direction model. A product-specific payment or
review analysis would require an explicit filter strategy or bridge.

## Principal fields

| SQL field | Meaning |
|---|---|
| `fact_order_items.price` | Merchandise amount, excluding freight |
| `fact_order_items.freight_value` | Recorded customer freight charge |
| `fact_payments.payment_value` | Recorded customer payment amount |
| `fact_orders.delivery_days` | Calendar-day boundaries from purchase to delivery |
| `fact_orders.is_delivered` | Delivered status flag |
| `fact_orders.is_on_time_delivery` | Actual delivery no later than estimate; nullable when not assessable |
| `fact_reviews.review_score` | Rating from 1 to 5 |
| `dim_products.product_category_name_english` | English category, with source-language/Unknown fallback |

Freight charges are not verified carrier expenses. The freight-to-sales ratio
should not be labeled a logistics-cost margin.

## SQL snapshot versus report aliases

| SQL snapshot | Name used in the report workflow |
|---|---|
| `order_purchase_timestamp` | `order_purchase_at` |
| `order_delivered_customer_date` | `order_delivered_customer_at` |
| `order_delivered_carrier_date` | `order_delivered_carrier_at` |
| `order_estimated_delivery_date` | `order_estimated_delivery_at` |
| `is_on_time_delivery` | `is_on_time` |
| Date-only purchase timestamp, derived during reporting preparation | `order_purchase_date` |
| `dim_date.date_key` (DATE in the SQL snapshot) | Report calendar uses `full_date` as its date column |

The saved SQL scripts are earlier modeling snapshots, not an exact export of
the final PBIX schema. Keep SQL names or add explicit aliases in Power Query
when reproducing the report. The learning guide contains illustrative schema
examples; the runnable SQL files determine the recreated schema.
