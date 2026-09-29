-- Silver: viajes limpios y estandarizados.
-- Las decisiones de limpieza (y cuántas filas afecta cada una sobre los datos
-- 2025-01..2026-07) están documentadas en _silver.yml.
{{
    config(
        materialized='incremental',
        incremental_strategy='delete+insert',
        unique_key='source_file'
    )
}}

with source as (

    select * from {{ ref('brz_yellow_tripdata') }}

    {% if is_incremental() %}
    where loaded_at > (select max(loaded_at) from {{ this }})
    {% endif %}

),

-- 1. Nombres en snake_case, tipos correctos y nulos tratados
standardized as (

    select
        vendorid::int                                          as vendor_id,
        tpep_pickup_datetime::timestamp_ntz                    as pickup_datetime,
        tpep_dropoff_datetime::timestamp_ntz                   as dropoff_datetime,
        pulocationid::int                                      as pickup_location_id,
        dolocationid::int                                      as dropoff_location_id,

        -- 0 pasajeros o más de 6 no es posible en un yellow taxi -> desconocido
        iff(passenger_count between 1 and 6, passenger_count, null)::int
                                                               as passenger_count,
        trip_distance::number(10, 2)                           as trip_distance_miles,
        -- TLC define 99 como "Null/unknown": los nulos se unifican en ese código
        coalesce(ratecodeid, 99)::int                          as rate_code_id,
        payment_type::int                                      as payment_type_id,
        case upper(trim(store_and_fwd_flag))
            when 'Y' then true
            when 'N' then false
        end                                                    as is_store_and_forward,

        -- Montos: los recargos nulos significan "no se cobró" -> 0
        fare_amount::number(10, 2)                             as fare_amount,
        coalesce(extra, 0)::number(10, 2)                      as extra_amount,
        coalesce(mta_tax, 0)::number(10, 2)                    as mta_tax_amount,
        coalesce(tip_amount, 0)::number(10, 2)                 as tip_amount,
        coalesce(tolls_amount, 0)::number(10, 2)               as tolls_amount,
        coalesce(improvement_surcharge, 0)::number(10, 2)      as improvement_surcharge_amount,
        coalesce(congestion_surcharge, 0)::number(10, 2)       as congestion_surcharge_amount,
        coalesce(airport_fee, 0)::number(10, 2)                as airport_fee_amount,
        coalesce(cbd_congestion_fee, 0)::number(10, 2)         as cbd_congestion_fee_amount,
        total_amount::number(10, 2)                            as total_amount,

        datediff('second', tpep_pickup_datetime, tpep_dropoff_datetime) / 60
                                                               as trip_duration_minutes,

        source_file,
        source_period,
        loaded_at

    from source

),

-- 2. Registros inválidos
valid as (

    select *
    from standardized
    where pickup_datetime is not null
      and dropoff_datetime is not null
      -- el viaje debe pertenecer al mes del archivo (TLC incluye algunos de otros meses)
      and to_char(pickup_datetime, 'YYYY-MM') = source_period
      -- no puede terminar antes de empezar ni durar más de 24 horas
      and dropoff_datetime >= pickup_datetime
      and trip_duration_minutes <= 24 * 60
      -- distancias de cientos de miles de millas son errores del taxímetro
      and trip_distance_miles between 0 and 200
      -- total negativo = anulación/reverso de un cobro, no un viaje
      and total_amount >= 0
      and total_amount <= 1000

),

-- 3. Duplicados: misma huella del viaje -> se queda uno
deduplicated as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'vendor_id', 'pickup_datetime', 'dropoff_datetime',
            'pickup_location_id', 'dropoff_location_id', 'trip_distance_miles',
            'fare_amount', 'total_amount', 'payment_type_id'
        ]) }} as trip_id,
        *
    from valid
    qualify row_number() over (partition by trip_id order by loaded_at desc) = 1

)

select
    *,
    current_timestamp() as silver_loaded_at
from deduplicated
