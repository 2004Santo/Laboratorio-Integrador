-- Dimensión proveedor del taxímetro (diccionario de datos de TLC).
select column1::int as vendor_key, column2::varchar as vendor_name
from values
    (1, 'Creative Mobile Technologies'),
    (2, 'Curb Mobility'),
    (6, 'Myle Technologies'),
    (7, 'Helix')
