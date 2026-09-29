-- Tabla de hechos: un viaje por fila.
-- Se reconstruye completa en cada corrida (materialized=table), así que
-- re-ejecutar siempre deja exactamente lo que hay en Silver.
select
    -- clave primaria
    trip_id,

    -- claves foráneas a dimensiones
    to_number(to_char(pickup_datetime, 'YYYYMMDD'))   as pickup_date_key,
    hour(pickup_datetime)                             as pickup_time_key,
    to_number(to_char(dropoff_datetime, 'YYYYMMDD'))  as dropoff_date_key,
    pickup_location_id                                as pickup_location_key,
    dropoff_location_id                               as dropoff_location_key,
    vendor_id                                         as vendor_key,
    payment_type_id                                   as payment_type_key,
    rate_code_id                                      as rate_code_key,

    -- atributos del viaje (dimensiones degeneradas)
    pickup_datetime,
    dropoff_datetime,
    is_store_and_forward,
    source_file,

    -- métricas
    passenger_count,
    trip_distance_miles,
    trip_duration_minutes,
    fare_amount,
    extra_amount,
    mta_tax_amount,
    tip_amount,
    tolls_amount,
    improvement_surcharge_amount,
    congestion_surcharge_amount,
    airport_fee_amount,
    cbd_congestion_fee_amount,
    total_amount

from {{ ref('slv_yellow_tripdata') }}
