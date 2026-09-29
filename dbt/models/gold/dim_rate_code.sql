-- Dimensión tarifa (diccionario de datos de TLC).
select column1::int as rate_code_key, column2::varchar as rate_code_name
from values
    (1, 'Tarifa estándar'),
    (2, 'JFK'),
    (3, 'Newark'),
    (4, 'Nassau o Westchester'),
    (5, 'Tarifa negociada'),
    (6, 'Viaje grupal'),
    (99, 'Desconocido')
