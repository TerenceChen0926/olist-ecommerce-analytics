# Metric definitions and limitations

Values below are recorded unfiltered project results, not a new execution
against a rebuilt SQL database. Money is denominated in Brazilian reais (BRL).

| Metric | Definition | Recorded result |
|---|---|---:|
| Total Orders | Distinct `fact_orders.order_id` | 99,441 |
| Total Order Items | Rows in `fact_order_items` | 112,650 |
| Product Sales | Sum of item `price` | R$13,591,643.70 |
| Freight Value | Sum of item `freight_value` | R$2,251,909.54 |
| Customer Paid Amount | Sum of payment `payment_value` | R$16,008,872.12 |
| Delivered Orders | Orders with `is_delivered = 1` | 96,478 |
| Average Delivery Days | Average nonblank valid `delivery_days` | 12.50 days |
| Total Reviews | Count of nonblank `review_score` | 99,224 |
| Average Review Score | Average review-record score | 4.09 / 5 |
| Five-Star Review Rate | Score-5 reviews / all rated review records | 57.78% |
| Low Rating Rate | Score-1-or-2 reviews / all rated review records | 14.69% |
| On-Time Delivery Rate | Share of eligible delivered orders arriving by estimate | Approximately 91.9% |

Display measures using `FORMAT()` are text. Use numeric base measures in chart
axes, ranking, filters, and arithmetic; use display measures only for cards.

## Delivery status reconciliation

The current screenshots show 91.89% in the on-time card and 91.88% in the donut.
This difference has not been verified as rounding. Before treating the exact
percentages as a validated common definition, reconcile:

1. Whether delivered orders with missing actual or estimated delivery dates
   are included in the denominator.
2. Whether the Delivery Performance column classifies a blank on-time flag
   as Late.
3. Whether the two visuals have identical filters.

The earlier calculated column labels delivered records On Time when
`is_on_time = 1` and Late otherwise. Its latter branch can include unassessable
records. A future consistent definition should retain an explicit Unknown
category or exclude unassessable records from both visuals.

## Interpretation

- Average delivery days uses calendar-day boundaries, not exact elapsed
  24-hour periods or business days.
- Average scores and rating rates are weighted by review records; an order
  with multiple reviews contributes multiple records.
- The approximate 4.3 versus 2.6 score comparison describes an association
  between assessed delivery performance and ratings. It is not a causal
  estimate or a demonstrated improvement from an intervention.
- Freight is approximately 16.57% of merchandise sales. It is a recorded-charge
  ratio, not an audited operating cost.
- Merchandise amounts and customer payments are different aggregates and
  need not match exactly.

## Date and sample controls

The calendar extends from 2016-09-04 through 2020-04-09, but calendar dates do not
imply purchase activity in every year. Limit year slicers to years with orders.
The sales overview excludes the sparse terminal purchase month 2018-09.
Monthly views should state their purchase-month window and check record counts
before interpreting early or terminal points.

Removing a month from a trend visual does not remove it from unfiltered KPI
cards. Make that distinction explicit when comparing the two.

State comparisons should show the corresponding order or review sample size.
Minimum-volume filters of 100 orders/reviews were proposed during construction;
the published screenshot still needs a final audit of these filters and ranking.
Do not describe it as a validated ranking of exactly ten eligible states.
