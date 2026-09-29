-- Bronze: copia fiel de RAW.YELLOW_TRIPDATA (mismos nombres y tipos de la fuente)
-- más metadata de linaje: archivo, período de origen y fecha de carga.
--
-- Incremental por archivo: la ingesta de Kestra borra y recarga un mes completo,
-- así que con delete+insert sobre source_file, si un mes se recarga se reemplazan
-- sus filas en Bronze en vez de duplicarlas.
{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key='source_file'
    )
}}

select
    vendorid,
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    passenger_count,
    trip_distance,
    ratecodeid,
    store_and_fwd_flag,
    pulocationid,
    dolocationid,
    payment_type,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount,
    congestion_surcharge,
    airport_fee,
    cbd_congestion_fee,

    -- metadata
    split_part(source_file, '/', -1)                      as source_file,
    regexp_substr(source_file, '[0-9]{4}-[0-9]{2}')       as source_period,
    loaded_at,
    current_timestamp()                                   as bronze_loaded_at

from {{ source('raw', 'yellow_tripdata') }}

{% if is_incremental() %}
-- solo archivos cargados/recargados en RAW después de la última corrida
where loaded_at > (select max(loaded_at) from {{ this }})
{% endif %}
