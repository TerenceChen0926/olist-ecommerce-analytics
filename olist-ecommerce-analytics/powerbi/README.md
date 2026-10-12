# Power BI report

The dashboard file is named `Olist_Ecommerce_Analytics_Dashboard.pbix`.
It is distributed separately as a GitHub Release asset rather than committed
through the browser file uploader. See this repository's Releases section
after the binary has been attached.

The report contains:

1. Executive Overview: sales, orders, product categories, statuses, payments.
2. Logistics Analysis: delivery time, on-time trends, state differences.
3. Customer Experience: ratings, score trends, delivery-performance comparison.

Year and Customer State slicers are synchronized across pages.

`report-definition/` contains the report's original page and visual JSON
definitions extracted from the saved PBIX. These files show the implemented
visual bindings, positions, and filters. They are report-layer source only,
not a complete PBIP project or an export of the semantic model's DAX measures.

Open the PBIX in Power BI Desktop to view its saved imported data. To refresh:

- Download the source data from the credited dataset page.
- Import the raw tables into a dedicated SQL Server database.
- Run the SQL modeling scripts in numbered order.
- Update the report's SQL Server connection to your own server.
- Apply the explicit column aliases documented in
  [`data_dictionary.md`](../docs/data_dictionary.md), and derive a date-only
  order purchase column before recreating the date relationship.

The report is a portfolio snapshot. It is not a production deployment or a
live hosted Power BI Service dashboard. Its current formatting and known metric
reconciliation tasks are documented in [`metrics.md`](../docs/metrics.md).
