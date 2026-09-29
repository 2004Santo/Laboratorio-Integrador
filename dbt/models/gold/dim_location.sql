-- Dimensión zona: se usa dos veces en la tabla de hechos (pickup y dropoff).
select
    location_id                                  as location_key,
    borough,
    zone,
    service_zone,
    service_zone in ('Airports', 'EWR')          as is_airport

from {{ ref('slv_taxi_zones') }}
