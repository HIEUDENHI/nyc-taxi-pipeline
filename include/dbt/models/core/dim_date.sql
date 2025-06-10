{{ config(
    materialized = 'incremental',
    incremental_strategy = 'merge',
    unique_key = ['date_id', 'hour'],
    partition_by = {
        "field": "date_id",
        "data_type": "date",
        "granularity": "month"
    }
) }}

with base as (

    select distinct
        date(pickup_datetime)               as date_id,
        extract(hour from pickup_datetime)  as hour,
        extract(year   from pickup_datetime) as year,
        extract(month  from pickup_datetime) as month,
        extract(day    from pickup_datetime) as day,
        extract(dayofweek from pickup_datetime) as day_of_week,
        extract(quarter from pickup_datetime)   as quarter
    from {{ ref('stg_trips') }}

    {% if is_incremental() %}
      where date(pickup_datetime) between
            date_trunc('{{ var("load_month") }}-01', month)
        and last_day('{{ var("load_month") }}-01')
    {% endif %}

)

select * from base
