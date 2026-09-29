-- Silver: catálogo de zonas estandarizado.
{{ config(materialized='table') }}

select
    locationid::int                                              as location_id,
    -- TLC usa 'N/A' y 'Unknown' indistintamente para "sin dato" -> 'Unknown'
    coalesce(nullif(nullif(trim(borough), 'N/A'), ''), 'Unknown')      as borough,
    coalesce(nullif(nullif(trim(zone), 'N/A'), ''), 'Unknown')         as zone,
    coalesce(nullif(nullif(trim(service_zone), 'N/A'), ''), 'Unknown') as service_zone,
    source_file,
    loaded_at,
    current_timestamp()                                          as silver_loaded_at

from {{ ref('brz_taxi_zones') }}
