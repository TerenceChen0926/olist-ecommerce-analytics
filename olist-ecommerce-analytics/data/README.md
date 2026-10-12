# Source data

Download the nine CSV files from the original
[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).
Extract them into a local `data/raw/` directory.

The dataset is credited to Olist and distributed under CC BY-NC-SA 4.0 on its
source page. Follow the original dataset's license and attribution requirements;
this repository does not relicense or redistribute the raw CSV files.

Expected files:

- `olist_customers_dataset.csv`
- `olist_sellers_dataset.csv`
- `olist_products_dataset.csv`
- `product_category_name_translation.csv`
- `olist_orders_dataset.csv`
- `olist_order_items_dataset.csv`
- `olist_order_payments_dataset.csv`
- `olist_order_reviews_dataset.csv`
- `olist_geolocation_dataset.csv`

Import each file into the corresponding `dbo` raw table in a dedicated SQL
Server database named `Olist_Ecommerce_Analytics`. Raw table names equal the
filenames without `.csv`. The modeling scripts expect text-compatible raw
columns and perform explicit conversions into the clean tables.

Preserve original column names, including `product_name_lenght` and
`product_description_lenght`, which are spelled that way in the source.
Preserve leading zeroes in postal-code prefixes. Import review text as Unicode
and support quoted fields containing commas and line breaks.

Geolocation is retained as an optional extension source; it is not part of the
current eight-table reporting model.
