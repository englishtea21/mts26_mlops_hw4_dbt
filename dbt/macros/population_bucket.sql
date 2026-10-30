{% macro population_bucket(population_expression) -%}
    multiIf(
        isNull({{ population_expression }})
            or ({{ population_expression }}) < 0, 'UNKNOWN',
        ({{ population_expression }}) < 5000, 'LT_5K',
        ({{ population_expression }}) < 20000, '5K_20K',
        ({{ population_expression }}) < 50000, '20K_50K',
        ({{ population_expression }}) < 100000, '50K_100K',
        ({{ population_expression }}) < 500000, '100K_500K',
        ({{ population_expression }}) < 1000000, '500K_1M',
        '1M_PLUS'
    )
{%- endmacro %}