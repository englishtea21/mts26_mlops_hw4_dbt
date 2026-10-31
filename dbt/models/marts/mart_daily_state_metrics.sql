{{ config(
    materialized='table',
    order_by=['transaction_date', 'state']
) }}
select
    transaction_date,
    state,
    count() as transaction_count,
    sum(amount) as total_amount,
    avg(amount) as avg_amount,
    quantileExact(0.95) (amount) as p95_amount,
    countIf(is_large_transaction = 1) as large_transaction_count,
    100.0 * countIf(is_large_transaction = 1) / count() as large_transaction_pct
from {{ ref('stg_transactions') }}
group by
    transaction_date,
    state
