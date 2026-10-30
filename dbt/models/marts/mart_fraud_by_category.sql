{{ config(materialized='table', order_by=['category']) }}

-- Grain: one row per category across the entire dataset.
select
    category,
    count() as transaction_count,
    countIf(is_fraud = 1) as fraud_count,
    100.0 * countIf(is_fraud = 1) / count() as fraud_rate,
    sum(amount) as total_amount,
    sumIf(amount, is_fraud = 1) as fraud_amount
from {{ ref('stg_transactions') }}
group by category
