Laboratorio Integrador I
Objetivo
Construir una tubería ELT reproducible que ingiera, almacene, transforme y modele los datos de NYC Yellow Taxi.

Datos
Utilicen los datos de NYC Yellow Taxi correspondientes a:

Enero–diciembre de 2025.

Enero–agosto de 2026.

En total deben procesar 20 meses de datos.

Requerimientos
Levanten la infraestructura necesaria para ejecutar la tubería completa.

La solución debe:

Ingresar automáticamente los archivos de NYC Yellow Taxi.

Cargar los datos originales en Snowflake.

Implementar las transformaciones utilizando dbt.

Organizar los modelos utilizando una arquitectura de Bronze → Silver → Gold.

Bronze
Mantener los datos lo más cercanos posible a la fuente original.

Agregar metadata que permita identificar:

Archivo o período de origen.

Fecha de carga.

Silver
Limpiar y estandarizar los datos aplicando las dimensiones de calidad de datos.

Deben tratar:

Tipos de datos.

Valores nulos.

Duplicados.

Registros inválidos.

Nombres y formatos inconsistentes.

Las decisiones de limpieza deben estar justificadas.

Gold
Construir un esquema estrella orientado al análisis de los viajes.

Debe existir:

Una tabla de hechos.

Las dimensiones necesarias para analizar los viajes desde diferentes perspectivas.

Definan correctamente:

Grano de la tabla de hechos.

Primary keys de las dimensiones.

Foreign keys entre hechos y dimensiones.

Métricas y atributos.

Validación
Incluyan pruebas de dbt para validar al menos:

not_null

unique

relationships

La tubería debe poder ejecutarse nuevamente sin generar duplicados ni inconsistencias.