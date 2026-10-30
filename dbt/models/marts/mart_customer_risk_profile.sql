{{ config(
    materialized='table',
    order_by=['name_1', 'name_2', 'street', 'city', 'state', 'post_code']
) }}

with customer_metrics as (
    select
        name_1,
        name_2,
        street,
        city,
        state,
        post_code,
        min(transaction_time) as first_transaction_time,
        max(transaction_time) as last_transaction_time,
        count() as transaction_count,
        countIf(is_fraud = 1) as fraud_count,
        100.0 * countIf(is_fraud = 1) / count() as fraud_rate,
        sum(amount) as total_amount,
        sumIf(amount, is_fraud = 1) as fraud_amount,
        avg(amount) as avg_amount
    from {{ ref('stg_transactions') }}
    group by
        name_1,
        name_2,
        street,
        city,
        state,
        post_code
)

select
    name_1,
    name_2,
    street,
    city,
    state,
    post_code,
    first_transaction_time,
    last_transaction_time,
    transaction_count,
    fraud_count,
    fraud_rate,
    total_amount,
    fraud_amount,
    avg_amount,
    multiIf(fraud_rate >= 5, 'HIGH', fraud_rate >= 1, 'MEDIUM', 'LOW') as risk_level
from customer_metrics
