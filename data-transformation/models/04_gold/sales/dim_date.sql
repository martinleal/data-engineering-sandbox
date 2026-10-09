{{ config(
    materialized='table'
) }}


with date_spine as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="to_date('1990-01-01')",
        end_date="to_date('2030-01-01')"
    ) }}

)

select
    to_number(to_char(date_day, 'YYYYMMDD')) as DATE_KEY,
    date_day as FULL_DATE,
    dayofmonth(date_day) as DAY_OF_MONTH,
    dayofweekiso(date_day) as DAY_OF_WEEK,
    dayname(date_day) as DAY_NAME,
    weekiso(date_day) as ISO_WEEK,
    month(date_day) as MONTH_NUMBER,
    monthname(date_day) as MONTH_NAME,
    quarter(date_day) as QUARTER_NUMBER,
    year(date_day) as YEAR_NUMBER,
    dayofweekiso(date_day) in (6, 7) as IS_WEEKEND
from date_spine