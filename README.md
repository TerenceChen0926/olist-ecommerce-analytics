# Olist E-Commerce Operations & Customer Experience Analytics

An independent portfolio project using **Python, SQL Server, and Power BI** to turn Olist's public transaction data into an operations reporting model and three interactive dashboards.

## Business scenario

The project simulates an e-commerce operations team's request for a shared view of business performance, regional delivery service, and customer feedback. It answers:

- How do orders, sales, product categories, and payment methods compare?
- Which customer states have slower deliveries or weaker on-time performance?
- Are late deliveries associated with lower customer review scores?

The deliverables are implemented analysis and reporting artifacts. Recommendations are proposals, not deployed interventions or measured business improvements.

## Tools and workflow

**Python / pandas:** Profile the nine source CSV files, including row counts, missing values, and maximum text lengths, to inform SQL data types and quality checks. The portable profiling script accepts paths as command-line arguments.

**SQL Server:** Convert raw text into typed columns, normalize empty strings, translate product categories with fallbacks, and validate keys and relationships. Four dimensions and four facts preserve their original grains. Item prices, freight, and payments are aggregated from their respective facts rather than a wide join that could multiply rows and inflate totals.

**Power BI / DAX:** Model relationships and calculate order, financial, delivery, and review metrics. Year and customer-state slicers synchronize across all three pages. Monthly charts use **order purchase month**, including review trends; they do not represent the month a review was submitted.

| Dashboard | Main analyses |
|---|---|
| Executive Overview | KPI overview, monthly sales, leading categories, order status, payment mix |
| Logistics Analysis | Monthly on-time rate, state delivery times, on-time/late composition, state on-time rates |
| Customer Experience | Review distribution and trends, delivery-performance score comparison, state scores |

Screenshots still need to be exported and added; see [image instructions](olist-ecommerce-analytics/images/README.md). The exported [report-definition JSON](olist-ecommerce-analytics/powerbi/report-definition/) captures the native report layer only. It excludes the semantic model and DAX and is **not a complete PBIP project**. The optional `.pbix` is distributed separately as a release asset.

## Data model

| Table | Grain | Rows |
|---|---|---:|
| `dim_customers` | Order-associated customer ID; not unique people | 99,441 |
| `dim_sellers` | Seller ID | 3,095 |
| `dim_products` | Product ID | 32,951 |
| `dim_date` | Calendar date | 1,314 |
| `fact_orders` | Order ID | 99,441 |
| `fact_order_items` | Order ID + item ID | 112,650 |
| `fact_payments` | Order ID + payment sequence | 103,886 |
| `fact_reviews` | Source review record with surrogate key | 99,224 |

The calendar extends beyond purchase activity to cover source delivery dates. A calendar year existing in `dim_date` does not imply orders occurred in that year.

## Baseline results

Values below describe the full dataset, without year/state slicer selections.

| Metric | Value |
|---|---:|
| Total orders | 99,441 |
| Product sales, excluding freight | R$13,591,643.70 |
| Freight value | R$2,251,909.54 |
| Customer paid amount | R$16,008,872.12 |
| Delivered orders | 96,478 |
| Review records | 99,224 |
| Average delivery time | 12.50 days |
| Average review score | 4.09 / 5 |
| Five-star review rate | 57.78% |
| Low-rating rate, 1–2 stars | 14.69% |
| On-time delivery rate | Approximately 91.9%; reconciliation pending |

Late-delivery orders have an average review score of approximately **2.6**, compared with **4.3** for on-time orders. This is an association, not proof of causation. State comparisons identify areas for further investigation; freight is approximately 16.57% of product sales, not a profit-margin measure.

## Reproduce the workflow

1. Download the nine CSVs from the [official Olist Kaggle dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) into `olist-ecommerce-analytics/data/raw/`. Raw data is excluded from this repository.
2. Install dependencies and run profiling:

   ```sh
   cd olist-ecommerce-analytics
   python -m pip install -r requirements.txt
   python python/profile_csv.py --data-dir data/raw --output outputs/csv_profile.csv
   ```

3. Import the nine raw tables into a dedicated SQL Server database named `Olist_Ecommerce_Analytics`, retaining the source table/column names. Execute `sql/01_dimensions.sql`, `02_facts.sql`, `03_calendar.sql`, and `04_validation.sql` in order.
4. Open the optional Power BI file and replace its local server/database settings with your own. Apply the [documented SQL-to-report field aliases](olist-ecommerce-analytics/docs/data_dictionary.md) and derive a date-only purchase column when reconnecting the historical SQL snapshots, then refresh and check the baseline metrics.

**The SQL scripts drop and recreate cleaned tables.** Use a dedicated project database. They are historical modeling snapshots; some fields were renamed or derived in Power BI. For reconstruction, the scripts are authoritative for the SQL schema.

## Repository contents

The project files are stored under `olist-ecommerce-analytics/`. Paths below are relative to that directory.

- `python/profile_csv.py`, `requirements.txt` — portable CSV profiling.
- `sql/` — dimension, fact, calendar, and validation scripts.
- `docs/data_dictionary.md`, `docs/metrics.md` — grains and metric definitions.
- `docs/Olist_SQL_Modeling_Guide.md` — modeling walkthrough and historical examples.
- `powerbi/report-definition/` — exported report-layer JSON.
- `images/README.md` — pending dashboard screenshot instructions.
- `data/README.md`, `.gitignore` — source-data setup and exclusions.

## Limitations and next steps

- Reconcile the on-time card's **91.89%** with the donut's **91.88%**, checking denominator eligibility and missing delivery dates. The difference has not been established as rounding.
- Focus trend comparisons on October 2016–August 2018; early months contain small samples and later purchase activity is sparse. Exclusions are chart-level choices, not deleted records.
- Verify state sample thresholds and ranking behavior before interpreting “worst-performing” states.
- Review count is a count of records, not necessarily unique orders or customers. Review text classification and delivery-risk prediction remain future work.

Data attribution: **Olist**, [Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), listed under **CC BY-NC-SA 4.0**. Consult the source terms for reuse, including derived data-bearing artifacts. This repository does not grant an additional license to the dataset.
