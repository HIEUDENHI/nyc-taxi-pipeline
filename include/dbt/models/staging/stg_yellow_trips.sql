

{{ config(
     materialized = 'view',
     schema       = 'staging'
) }}

with src as (

    select *
    from {{ source('nyc_taxi_raw','yellow_trips') }}
    where TIMESTAMP_TRUNC(tpep_pickup_datetime, MONTH)
          = TIMESTAMP('{{ var("load_month") }}-01')  

)

select distinct
    'yellow'                        as service_type,
    tpep_pickup_datetime            as pickup_datetime,
    tpep_dropoff_datetime           as dropoff_datetime,

    cast(VendorID     as int64)     as vendor_id,
    cast(RatecodeID   as int64)     as rate_code,
    cast(PULocationID as int64)     as pickup_location_id,
    cast(DOLocationID as int64)     as dropoff_location_id,
    cast(payment_type as int64)     as payment_type_id,

    safe_cast(passenger_count        as int64)    as passenger_count,
    safe_cast(trip_distance          as float64)  as trip_distance,
    safe_cast(fare_amount            as float64)  as fare_amount,
    safe_cast(extra                  as float64)  as extra,
    safe_cast(mta_tax                as float64)  as mta_tax,
    safe_cast(tip_amount             as float64)  as tip_amount,
    safe_cast(tolls_amount           as float64)  as tolls_amount,
    safe_cast(improvement_surcharge  as float64)  as improvement_surcharge,
    safe_cast(congestion_surcharge   as float64)  as congestion_surcharge,
    safe_cast(Airport_fee            as float64)  as airport_fee,
    safe_cast(total_amount           as float64)  as total_amount

from src
