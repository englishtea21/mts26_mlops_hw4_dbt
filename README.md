# dbt-проект: анализ транзакций в ClickHouse

Решение учебного задания: `transactions_db.transactions → stg_transactions → 6 marts`.
Staging создаётся как view, витрины — как таблицы в базе `analytics`.
Таблицы пересчитываются при запуске dbt; автоматического расписания нет.

Версии: Python 3.13, dbt Core 1.12.6, dbt-clickhouse 1.10.3,
ClickHouse 26.8.36.3, Elementary 0.26.1, SQLFluff 4.5.0.

## Реализованные требования

| Уровень | Реализация |
| --- | --- |
| 6–7 | Source → staging → marts; шесть витрин вместо требуемых двух |
| 6–7 | Используемые макросы `amount_bucket`, `population_bucket`; пакеты `dbt_utils`, `dbt_date` |
| 6–7 | Описания моделей и колонок; `not_null`, `unique`, `accepted_values`, уникальность составных ключей |
| 8–9 | Elementary: история запусков и тестов, schema changes, freshness и dimension anomalies |
| 8–9 | Singular tests для отрицательных сумм и диапазонов координат |
| 10 | Unit tests для staging и дневной витрины, SQLFluff, pre-commit, Makefile |

## Данные

Исходный файл: [train.csv на Kaggle](https://www.kaggle.com/competitions/teta-ml-1-2025/data?select=train.csv).
Для скачивания может потребоваться вход в Kaggle и принятие правил соревнования.

**До запуска Docker Compose файл должен лежать в `data/train.csv` относительно
корня репозитория.** CSV должен быть распакован и содержать строку заголовков.
Файл не включён в Git. В используемом наборе 786431 строка и 18 колонок.

```text
mts26_mlops_hw3_dbt/
├── data/
│   └── train.csv
├── docker-compose.yaml
├── requirements.txt
├── Makefile
└── dbt/
```

## Запуск с нуля

Нужны запущенный Docker с Compose, `uv`, Git и `make`.
Команды выполняются из корня репозитория.

1. Скачать CSV в `data/train.csv`.
2. Создать `.env` по образцу `.env.example`; указать `CLICKHOUSE_USER` и
   `CLICKHOUSE_PASSWORD`. Секреты не хранятся в Git.
3. Установить зависимости и запустить базу:

```bash
make install
docker compose up -d --wait
docker compose wait load-data
docker compose logs load-data
```

`make install` создаёт `.venv` на Python 3.13 и устанавливает **все Python-зависимости
из одного `requirements.txt`**, включая Elementary CLI, SQLFluff и pre-commit.
Дополнительные команды `pip install` не нужны.

Ожидаемый результат загрузки: `CSV load completed.`, `786431`, код завершения 0.
Повторный запуск пропускает загрузку, если исходная таблица уже существует.
Замена CSV не обновляет существующую таблицу автоматически. Данные хранятся в Docker volume.

4. Установить dbt-пакеты, построить модели и выполнить проверки:

```bash
make deps
make debug
make run
make test
make lint
make hooks
make pre-commit
```

Makefile использует локальные инструменты из `.venv` и сам загружает `.env`.
Elementary CLI также закреплён на Python dbt Core через `DBT_RUNNER_METHOD=api`.
Профиль подключения — `dbt/profiles.yml`, ClickHouse — HTTP `127.0.0.1:8123`.
Пакеты dbt устанавливаются из `dbt/packages.yml` командой `make deps`.

Отдельная проверка unit tests и полный цикл в порядке зависимостей:

```bash
make unit-test
make build
```

## Витрины

| Модель | Зерно и метрики |
| --- | --- |
| `mart_daily_state_metrics` | Дата + штат: количество, сумма, средний чек, P95, доля крупных транзакций |
| `mart_fraud_by_category` | Категория: количество транзакций и фродов, fraud rate, суммы |
| `mart_fraud_by_state` | Штат: фрод, суммы, число клиентских групп и мерчантов |
| `mart_customer_risk_profile` | Клиентская группа: история, средний чек, fraud rate, уровень риска |
| `mart_hourly_fraud_pattern` | День недели + час: количество, суммы и фрод |
| `mart_merchant_analytics` | Мерчант: оборот, средний чек, фрод, флаг подозрительности |

Крупная транзакция — сумма от 500. Fraud rate и доля крупных транзакций выражены
в процентах. Клиентского ID нет: ключ группы — имя, фамилия, улица, город, штат,
индекс. Он может объединять разных людей и разделять одного человека при смене адреса.
Риск группы: HIGH ≥ 5% фрода, MEDIUM ≥ 1%, иначе LOW. Подозрительный мерчант:
не менее 100 транзакций и fraud rate ≥ 5%. Эти правила учебные.

## Документация и отчёт Elementary

```bash
make docs
make report
```

- dbt Docs: `dbt/target/index.html`; просмотр графа через сервер ниже.
- Elementary: `dbt/target/elementary_report.html`, открывается в браузере как HTML-файл.
- История Elementary хранится в базе `analytics_elementary`.

```bash
make docs-serve
```

Сервер dbt Docs доступен на `http://127.0.0.1:8080`; остановка — Ctrl+C.
В документации доступны описания моделей и DAG source → staging → marts.

Freshness и dimension anomalies используют окна относительно времени запуска.
CSV содержит исторические транзакции 2019–2020 годов: отсутствие обнаруженных
аномалий в текущем окне не доказывает свежесть данных.

## Остальные команды

```bash
make help       # Список команд
make lint-fix   # Автоисправление форматирования SQL
```

Pre-commit проверяет SQL перед коммитом. В каждом новом checkout требуется `make hooks`.
SQLFluff использует dbt-templater, которому нужны dbt-пакеты и доступ к базе.
Линтинг не заменяет проверку бизнес-логики.

Логи контрольного запуска сохраняются локально в `dbt/target/verification/`.

# Использование ИИ
Использовался Codex для генерации README, описания схем и дебага.
