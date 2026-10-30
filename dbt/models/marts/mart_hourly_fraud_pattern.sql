{{ config(materialized='table', order_by=['day_of_week', 'transaction_hour']) }}

-- Grain: one row per ISO weekday (1 = Monday) and hour across all dates.
-- Hours use the stored timestamp; no conversion to a customer's local time.
select
    day_of_week,
    toHour(transaction_time) as transaction_hour,
    count() as transaction_count,
    countIf(is_fraud = 1) as fraud_count,
    100.0 * countIf(is_fraud = 1) / count() as fraud_rate,
    sum(amount) as total_amount,
    sumIf(amount, is_fraud = 1) as fraud_amount
from {{ ref('stg_transactions') }}
group by
    day_of_week,
    transaction_hour
