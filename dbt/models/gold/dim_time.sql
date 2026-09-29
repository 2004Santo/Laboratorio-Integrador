-- Dimensión hora del día: una fila por hora (0-23).
with hours as (

    select row_number() over (order by seq4()) - 1 as hour
    from table(generator(rowcount => 24))

)

select
    hour                                           as time_key,
    lpad(hour, 2, '0') || ':00'                    as hour_label,
    case
        when hour between 0 and 5   then 'Madrugada'
        when hour between 6 and 11  then 'Mañana'
        when hour between 12 and 17 then 'Tarde'
        else 'Noche'
    end                                            as day_period,
    -- horas pico de tráfico en NYC
    hour between 7 and 9 or hour between 16 and 19 as is_rush_hour

from hours
