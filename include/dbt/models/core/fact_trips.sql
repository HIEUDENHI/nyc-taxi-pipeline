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

{% set start_month = var('load_month') ~ '-01' %}

with src as (

    select *
    from {{ ref('stg_trips') }}
    {% if is_incremental() %}
      where pickup_datetime >= timestamp('{{ start_month }}')
        and pickup_datetime <  timestamp(DATE_ADD(DATE('{{ start_month }}'), INTERVAL 1 MONTH))
    {% endif %}

),

prep as (

    select
        service_type,
        vendor_id,
        rate_code,
        payment_type_id,
        pickup_location_id,
        dropoff_location_id,
        pickup_datetime,
        dropoff_datetime,
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
        total_amount,

        DATE(pickup_datetime) as pickup_date        -- ← NEW
    from src
),

dedup as (   -- unchanged
    select * except (rn)
    from (
        select *,
               row_number() over (
                   partition by
                     service_type, vendor_id, rate_code, payment_type_id,
                     pickup_datetime, dropoff_datetime,
                     pickup_location_id, dropoff_location_id,
                     passenger_count, cast(total_amount as NUMERIC)
                   order by dropoff_datetime desc
               ) as rn
        from prep
    ) where rn = 1
),

base as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'service_type','vendor_id','rate_code','payment_type_id',
            'pickup_datetime','dropoff_datetime',
            'pickup_location_id','dropoff_location_id',
            'passenger_count','total_amount'
        ]) }}  as trip_id,

        pickup_date,             -- must be here for partition
        pickup_datetime,
        dropoff_datetime,

        -- FKs
        service_type,
        vendor_id,
        rate_code,
        payment_type_id,
        pickup_location_id,
        dropoff_location_id,

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
    from dedup
)

select * from base