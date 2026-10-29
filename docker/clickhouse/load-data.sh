#!/usr/bin/env bash
set -euo pipefail

test -s /data/train.csv || { echo "Missing or empty /data/train.csv" >&2; exit 1; }

# Credentials are read from environment by clickhouse-client.
client=(clickhouse-client --host "$CLICKHOUSE_HOST" --user "$CLICKHOUSE_USER")
"${client[@]}" --query 'CREATE DATABASE IF NOT EXISTS transactions_db'
"${client[@]}" --query 'CREATE DATABASE IF NOT EXISTS analytics'

if [[ "$("${client[@]}" --query 'EXISTS TABLE transactions_db.transactions')" == "1" ]]; then
    echo 'transactions_db.transactions already exists; skipping CSV load.'
else
    "${client[@]}" --multiquery < /scripts/schema.sql
    # Only the scratch table is cleared when retrying an interrupted load.
    "${client[@]}" --query 'TRUNCATE TABLE transactions_db.transactions_loading'
    "${client[@]}" --date_time_input_format=best_effort \
        --input_format_csv_empty_as_default=0 \
        --input_format_null_as_default=0 \
        --query 'INSERT INTO transactions_db.transactions_loading FORMAT CSVWithNames' \
        < /data/train.csv
    "${client[@]}" --query \
        'RENAME TABLE transactions_db.transactions_loading TO transactions_db.transactions'
    echo 'CSV load completed.'
fi

"${client[@]}" --query 'SELECT count() AS transaction_count FROM transactions_db.transactions'
