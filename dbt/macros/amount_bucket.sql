{% macro amount_bucket(amount_expression) -%}
    multiIf(
        {{ amount_expression }} < 5, 'TINY',
        {{ amount_expression }} < 50, 'SMALL',
        {{ amount_expression }} < 500, 'MEDIUM',
        'LARGE'
    )
{%- endmacro %}