
{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- if custom_schema_name is none -%}
        {{ target.schema }}

    {%- elif target.name == 'ci' -%}
        {{ custom_schema_name | trim }}_{{ env_var('GITHUB_RUN_ID', 'LOCAL') }}

    {%- elif target.name == 'dev' -%}
        {{ custom_schema_name | trim }}_{{ target.user }}

    {%- else -%}
        {{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}
