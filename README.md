# Laboratorio Integrador I — ELT NYC Yellow Taxi

Tubería ELT reproducible que ingiere, almacena, transforma y modela los viajes de
NYC Yellow Taxi (enero 2025 – agosto 2026) usando **Kestra + Snowflake + dbt**.

```
TLC (parquet/csv) ──Kestra──▶ Snowflake RAW ──dbt──▶ BRONZE ──▶ SILVER ──▶ GOLD (estrella)
```

| Componente | Rol |
|---|---|
| Docker Compose | Levanta Kestra y su base Postgres |
| Kestra | Descarga los archivos de TLC, los carga a Snowflake y ejecuta dbt |
| Snowflake | Almacenamiento: schemas `RAW`, `BRONZE`, `SILVER`, `GOLD` en la base `NYC_TAXI` |
| dbt | Transformaciones Bronze → Silver → Gold y pruebas de calidad |

## Cómo ejecutar

1. Completar el archivo `.env` (credenciales de Postgres, Kestra y Snowflake).
2. Levantar la infraestructura:
   ```bash
   docker compose up -d
   ```
   Kestra queda en http://localhost:8080. Los flows de `kestra/flows/` se cargan al iniciar
   el contenedor (si se modifican, reiniciar con `docker compose restart kestra`).
3. En Kestra, ejecutar en orden:
   1. `nyc_taxi.snowflake_setup`: crea warehouse, base, schemas, rol, usuario y stage (una sola vez).
   2. `nyc_taxi.ingest_yellow_all`: carga las zonas y los 20 meses a `RAW`, y al terminar
      llama a `nyc_taxi.dbt_build`, que construye Bronze, Silver y Gold y corre los tests.

Para cargar un solo mes: `nyc_taxi.ingest_yellow_month` (input `month = YYYY-MM`).
Para correr solo las transformaciones: `nyc_taxi.dbt_build`.

### dbt en local (opcional)

```powershell
python -m venv .venv
.venv\Scripts\pip install -r requirements.txt
# cargar las variables de .env y correr dbt
Get-Content .env | ? { $_ -match '^\s*[A-Za-z_]\w*=' } | % { $k,$v = $_ -split '=',2; Set-Item "env:$k" $v.Trim() }
cd dbt
..\.venv\Scripts\dbt deps --profiles-dir .
..\.venv\Scripts\dbt build --profiles-dir .
```

## Capas

### RAW (Kestra)
`RAW.YELLOW_TRIPDATA` y `RAW.TAXI_ZONE_LOOKUP` con los datos tal como los publica TLC, más
`SOURCE_FILE` y `LOADED_AT`. Cada mes se carga borrando antes las filas de ese archivo, así que
recargar un mes no duplica.

> Al 2026-09-28 TLC todavía no publicó **agosto 2026**: se cargaron 19 de los 20 meses
> (75,089,241 viajes). Ese mes queda en WARNING en Kestra y entra automáticamente cuando se
> publique y se vuelva a ejecutar `ingest_yellow_all`.

### Bronze (`dbt/models/bronze`)
Copia fiel de RAW: mismas columnas y tipos. Agrega metadata de linaje:
`source_file` (archivo de origen), `source_period` (YYYY-MM), `loaded_at` (carga a RAW) y
`bronze_loaded_at` (escritura en Bronze).

### Silver (`dbt/models/silver`)
Datos limpios y estandarizados (73,962,165 viajes, se descarta el 1.5%). Resumen de decisiones;
el detalle con los conteos está en `dbt/models/silver/_silver.yml`.

| Dimensión de calidad | Decisión |
|---|---|
| Tipos de datos | Pasajeros y rate code de FLOAT a INT; montos y distancia a `NUMBER(10,2)` |
| Nombres y formatos | snake_case (`pickup_location_id`, `total_amount`…); `Y/N` → booleano; zonas `N/A` → `Unknown` |
| Valores nulos | 24.5% de los viajes son "Flex Fare" (`payment_type = 0`) sin pasajeros ni recargos: **se conservan**. Rate code nulo → 99 (Unknown de TLC), recargos nulos → 0, pasajeros nulos se dejan NULL |
| Registros inválidos | Se excluyen: total negativo (anulaciones), dropoff antes del pickup, duración > 24 h, distancia > 200 millas, total > 1,000 USD, pickup fuera del mes del archivo. Pasajeros 0 o > 6 → NULL |
| Duplicados | `trip_id` = hash de los atributos del viaje; se deja una fila por `trip_id` |

### Gold (`dbt/models/gold`): esquema estrella

```
            dim_date (pickup y dropoff)
                    |
 dim_vendor ---- fct_trips ---- dim_location (pickup y dropoff)
               /    |    \
 dim_payment_type dim_time dim_rate_code
```

- **Tabla de hechos `fct_trips`**. Grano: **un viaje por fila**. PK `trip_id`.
  Métricas: pasajeros, distancia, duración, tarifa, propina, peajes, recargos y total.
- **Dimensiones** (PK entre paréntesis):
  `dim_date` (`date_key` YYYYMMDD), `dim_time` (`time_key` hora 0-23),
  `dim_location` (`location_key`, zona de TLC), `dim_vendor` (`vendor_key`),
  `dim_payment_type` (`payment_type_key`), `dim_rate_code` (`rate_code_key`).
- **Foreign keys** en `fct_trips`: `pickup_date_key`, `dropoff_date_key`, `pickup_time_key`,
  `pickup_location_key`, `dropoff_location_key`, `vendor_key`, `payment_type_key`, `rate_code_key`.

## Validación

`dbt build` ejecuta 70 pruebas definidas en los `_*.yml` de cada capa:
- `not_null` y `unique` en todas las claves primarias y en `trip_id`.
- `relationships` de cada foreign key de `fct_trips` hacia su dimensión, y de las zonas de Silver
  hacia el catálogo de zonas.
- `accepted_values` en vendor, tipo de pago y rate code.

## Re-ejecución sin duplicados

- **RAW**: antes de cada `COPY INTO` se borran las filas del mismo archivo.
- **Bronze y Silver**: incrementales con `delete+insert` por `source_file`; si un mes se recarga,
  sus filas se reemplazan.
- **Gold**: se reconstruye completo en cada corrida.

Verificado: una segunda ejecución inserta 0 filas nuevas y `fct_trips` mantiene 73,962,165 viajes.

---

## Enunciado

**Objetivo:** construir una tubería ELT reproducible que ingiera, almacene, transforme y modele
los datos de NYC Yellow Taxi.

**Datos:** enero–diciembre de 2025 y enero–agosto de 2026 (20 meses).

**Requerimientos:** levantar la infraestructura necesaria; ingresar automáticamente los archivos;
cargar los datos originales en Snowflake; transformar con dbt en una arquitectura Bronze → Silver → Gold.

- **Bronze:** mantener los datos lo más cercanos posible a la fuente y agregar metadata de
  archivo/período de origen y fecha de carga.
- **Silver:** limpiar y estandarizar tratando tipos de datos, valores nulos, duplicados, registros
  inválidos y nombres/formatos inconsistentes, con decisiones justificadas.
- **Gold:** esquema estrella con una tabla de hechos y las dimensiones necesarias, definiendo grano,
  primary keys, foreign keys, métricas y atributos.
- **Validación:** pruebas de dbt `not_null`, `unique` y `relationships`. La tubería debe poder
  ejecutarse nuevamente sin generar duplicados ni inconsistencias.
