-- Dimensión tipo de pago (diccionario de datos de TLC).
select column1::int as payment_type_key, column2::varchar as payment_type_name, column3::boolean as is_paid
from values
    (0, 'Flex Fare', true),
    (1, 'Tarjeta de crédito', true),
    (2, 'Efectivo', true),
    (3, 'Sin cargo', false),
    (4, 'Disputa', false),
    (5, 'Desconocido', false),
    (6, 'Viaje anulado', false)
