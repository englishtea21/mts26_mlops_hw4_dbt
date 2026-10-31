.DEFAULT_GOAL := help

PYTHON := .venv/bin/python
DBT := .venv/bin/dbt
SQLFLUFF := .venv/bin/sqlfluff
PRE_COMMIT := .venv/bin/pre-commit
EDR := .venv/bin/edr
WITH_ENV := $(PYTHON) -m dotenv --file .env run --
DBT_ARGS := --project-dir dbt --profiles-dir dbt
export DBT_SEND_ANONYMOUS_USAGE_STATS := false
export DBT_RUNNER_METHOD := api

.PHONY: help install deps debug run test unit-test build docs docs-serve report lint lint-fix hooks pre-commit

help:
	@echo "install     Install project and development dependencies into .venv"
	@echo "deps        Install dbt packages"
	@echo "debug       Check the ClickHouse connection"
	@echo "run         Build dbt models"
	@echo "test        Run data tests and unit tests"
	@echo "unit-test   Run only unit tests"
	@echo "build       Build models and run tests in dependency order"
	@echo "docs        Generate dbt documentation"
	@echo "docs-serve  Serve documentation on localhost:8080"
	@echo "report      Generate the Elementary HTML report"
	@echo "lint        Check SQL formatting"
	@echo "lint-fix    Automatically fix SQL formatting"
	@echo "hooks       Install the local Git pre-commit hook"
	@echo "pre-commit  Check all tracked SQL files with pre-commit"

.venv/bin/python:
	uv venv --python 3.13 .venv

install: .venv/bin/python
	uv pip install --python $(PYTHON) -r requirements.txt

deps:
	$(WITH_ENV) $(DBT) deps $(DBT_ARGS)

debug:
	$(WITH_ENV) $(DBT) debug $(DBT_ARGS)

run:
	$(WITH_ENV) $(DBT) run $(DBT_ARGS)

test:
	$(WITH_ENV) $(DBT) test $(DBT_ARGS)

unit-test:
	$(WITH_ENV) $(DBT) test $(DBT_ARGS) --select test_type:unit

build:
	$(WITH_ENV) $(DBT) build $(DBT_ARGS)

docs:
	$(WITH_ENV) $(DBT) docs generate $(DBT_ARGS)

docs-serve:
	$(WITH_ENV) $(DBT) docs serve $(DBT_ARGS) --host 127.0.0.1 --port 8080

report:
	$(WITH_ENV) $(EDR) report --project-dir dbt --profiles-dir dbt \
		--profile-target default --project-profile-target dev \
		--target-path "$(CURDIR)/dbt/target/elementary" \
		--file-path "$(CURDIR)/dbt/target/elementary_report.html" --open-browser false

lint:
	$(WITH_ENV) $(SQLFLUFF) lint dbt/models dbt/tests

lint-fix:
	$(WITH_ENV) $(SQLFLUFF) fix dbt/models dbt/tests

hooks:
	$(PRE_COMMIT) install

pre-commit:
	$(PRE_COMMIT) run --all-files
