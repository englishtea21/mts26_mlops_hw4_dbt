{{ config(materialized='table', order_by=['state']) }}

-- Grain: one row per state across the entire dataset.
-- Customer groups approximate identity using the agreed name/address tuple.
select
    state,
    count() as transaction_count,
    countIf(is_fraud = 1) as fraud_count,
    100.0 * countIf(is_fraud = 1) / count() as fraud_rate,
    uniqExact(tuple(name_1, name_2, street, city, state, post_code)) as unique_customer_groups,
    uniqExact(merchant) as unique_merchants,
    sum(amount) as total_amount,
    sumIf(amount, is_fraud = 1) as fraud_amount
from {{ ref('stg_transactions') }}
group by state
