
{{ config(
    materialized         = 'incremental',
    incremental_strategy = 'merge',
    unique_key           = 'trip_id',
    partition_by = {
        "field":       "pickup_date",
        "data_type":   "date",
        "granularity": "month"
    }
) }}

{% set start_date = var('load_month') ~ '-01' %}     -- ví dụ '2025-06'

with base as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'service_type','vendor_id','rate_code','payment_type_id',
            'pickup_datetime','dropoff_datetime',
            'pickup_location_id','dropoff_location_id',
            'passenger_count','total_amount'
        ]) }}                 as trip_id,

        -- dimensions
        service_type,
        vendor_id,
        rate_code,
        payment_type_id,
        pickup_location_id,
        dropoff_location_id,

        -- timestamps + partition key
        pickup_datetime,
        dropoff_datetime,
        date(pickup_datetime) as pickup_date,

        -- measures
        passenger_count,
        trip_distance,
        fare_amount,
        extra,
        mta_tax,
        tip_amount,
        tolls_amount,
        improvement_surcharge,
        congestion_surcharge,
        airport_fee,
        total_amount

    from {{ ref('stg_trips') }}

    {% if is_incremental() %}
      -- giới hạn chỉ nạp đúng tháng var('load_month')
      where date(pickup_datetime) >= date('{{ start_date }}')
        and date(pickup_datetime) <  date_add(date('{{ start_date }}'), interval 1 month)
    {% endif %}

)

select * from base
