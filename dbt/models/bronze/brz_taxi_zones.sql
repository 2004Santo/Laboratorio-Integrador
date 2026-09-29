-- Bronze: catálogo de zonas tal como viene de TLC.
-- Es chico (~265 filas) y RAW se recrea completo en cada ingesta, así que se
-- reconstruye como tabla en cada corrida.
{{ config(materialized='table') }}

select
    locationid,
    borough,
    zone,
    service_zone,

    -- metadata
    split_part(source_file, '/', -1)  as source_file,
    loaded_at,
    current_timestamp()               as bronze_loaded_at

from {{ source('raw', 'taxi_zone_lookup') }}
