{{ config(materialized='table', order_by=['merchant']) }}

-- Grain: one row per normalized merchant name across the entire dataset.
with merchant_metrics as (
    select
        merchant,
        count() as transaction_count,
        countIf(is_fraud = 1) as fraud_count,
        100.0 * countIf(is_fraud = 1) / count() as fraud_rate,
        sum(amount) as total_amount,
        sumIf(amount, is_fraud = 1) as fraud_amount,
        avg(amount) as avg_amount
    from {{ ref('stg_transactions') }}
    group by merchant
)

select
    merchant,
    transaction_count,
    fraud_count,
    fraud_rate,
    total_amount,
    fraud_amount,
    avg_amount,
    -- Agreed educational rule, not a verified fraud classification.
    toUInt8(transaction_count >= 100 and fraud_rate >= 5) as is_suspicious
from merchant_metrics
