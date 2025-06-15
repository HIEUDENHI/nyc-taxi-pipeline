{{ config(materialized='view', schema='staging') }}

select * from {{ ref('stg_green_trips') }}
union all
select * from {{ ref('stg_yellow_trips') }}
