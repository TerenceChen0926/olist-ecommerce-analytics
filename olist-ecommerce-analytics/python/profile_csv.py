"""Profile Olist CSV fields before designing typed SQL Server tables.

This portable version extends the original inspect_csv_fields.py script with
command-line paths, chunked reads, and a machine-readable summary.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import sys

import pandas as pd


SOURCE_FILES = (
    "olist_customers_dataset.csv",
    "olist_sellers_dataset.csv",
    "olist_products_dataset.csv",
    "product_category_name_translation.csv",
    "olist_orders_dataset.csv",
    "olist_order_items_dataset.csv",
    "olist_order_payments_dataset.csv",
    "olist_order_reviews_dataset.csv",
    "olist_geolocation_dataset.csv",
)


def profile_file(path: Path, chunksize: int) -> list[dict]:
    """Count empty fields and maximum text lengths without type inference."""
    row_count = 0
    null_counts: dict[str, int] = {}
    max_lengths: dict[str, int] = {}
    for chunk in pd.read_csv(
        path,
        dtype="string",
        keep_default_na=False,
        na_values=[""],
        encoding="utf-8-sig",
        chunksize=chunksize,
    ):
        row_count += len(chunk)
        for column in chunk.columns:
            values = chunk[column]
            null_counts[column] = null_counts.get(column, 0) + int(
                values.isna().sum()
            )
            longest = values.fillna("").str.len().max()
            max_lengths[column] = max(
                max_lengths.get(column, 0),
                0 if pd.isna(longest) else int(longest),
            )
    return [
        {
            "file": path.name,
            "column": column,
            "row_count": row_count,
            "null_count": null_counts[column],
            "null_percentage": (
                round(null_counts[column] / row_count * 100, 4)
                if row_count
                else 0.0
            ),
            "max_chars": max_lengths[column],
        }
        for column in null_counts
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data-dir", type=Path, default=Path("data/raw"))
    parser.add_argument(
        "--output", type=Path, default=Path("outputs/csv_profile.csv")
    )
    parser.add_argument("--chunksize", type=int, default=50_000)
    args = parser.parse_args()
    if args.chunksize < 1:
        parser.error("--chunksize must be a positive integer")
    if not args.data_dir.is_dir():
        parser.error(f"Data directory does not exist: {args.data_dir}")

    records: list[dict] = []
    for filename in SOURCE_FILES:
        path = args.data_dir / filename
        if not path.is_file():
            print(f"Skipping missing source file: {filename}", file=sys.stderr)
            continue
        result = profile_file(path, args.chunksize)
        records.extend(result)
        if result:
            print(f"{filename}: {result[0]['row_count']:,} rows")
    if not records:
        parser.error("No fields were found in the expected Olist CSV files")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    pd.DataFrame(records).to_csv(args.output, index=False, encoding="utf-8")
    print(f"Field profile saved to {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
