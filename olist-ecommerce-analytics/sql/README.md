# SQL Server modeling scripts

Run these in a dedicated `Olist_Ecommerce_Analytics` database after importing
the original CSV files into the corresponding raw tables.

| Order | File | Purpose |
|---|---|---|
| 1 | `01_dimensions.sql` | Typed customer, seller and product dimensions |
| 2 | `02_facts.sql` | Order, item, payment and review facts |
| 3 | `03_calendar.sql` | Continuous daily calendar |
| 4 | `04_validation.sql` | Unmatched-key checks and monetary totals |

Use SQL Server Management Studio or another client that supports SQL Server
`GO` batch separators.

The first three scripts contain `DROP TABLE IF EXISTS` statements for the clean
analysis tables. They are rebuild scripts for a learning database; do not run
them against unrelated or production tables. The raw Olist tables are preserved.
Foreign keys or custom dependencies added later can prevent a rebuild.

The snapshots were written during the modeling stage and were not re-executed
against a new database as part of publication. Compare the recreated counts and
totals with [the documented baseline](../docs/metrics.md). Report field aliases
and data grain are described in [the dictionary](../docs/data_dictionary.md).
