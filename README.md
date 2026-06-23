# Gathel — Gaming the life

Repositorio del Caso 3 de Bases de Datos. El proyecto implementa un MVP local de Gathel con base de datos SQL Server, migraciones Flyway, seeding masivo, laboratorio de seguridad, transacciones/concurrencia, backend REST API y frontend web.

## Resumen del MVP

El sistema permite demostrar los flujos principales solicitados para el MVP:

- Login y logout de jugadores existentes en la base de datos.
- Pantalla principal con balance de puntos, balance de dinero real y actividad básica.
- Creación de proposiciones para otro jugador o para el propio jugador.
- Visualización de proposiciones activas disponibles para pronosticar.
- Registro de pronósticos usando puntos o dinero real.
- Visualización de resultados de proposiciones finalizadas.
- Comunicación frontend/backend mediante REST API.
- Lecturas implementadas con ORM.
- Escrituras ejecutadas mediante Stored Procedures.
- Pool fijo de conexiones hacia SQL Server.

No se implementa integración real con IA, redes sociales externas ni backoffice administrativo. Los flujos avanzados de aceptación, votación, cierre, liquidación, penalización o validación operativa pueden ejecutarse mediante scripts SQL o Stored Procedures fuera del flujo principal del frontend.

## Estructura del repositorio

| Ruta | Propósito |
|---|---|
| [frontend/](./frontend) | Aplicación web del MVP. Contiene HTML, CSS y JavaScript. |
| [frontend/app.js](./frontend/app.js) | Lógica principal del frontend: rutas internas, login, dashboard, proposiciones, búsqueda de jugadores, pronósticos y resultados. |
| [frontend/README.md](./frontend/README.md) | Documentación específica del frontend. |
| [backend/](./backend) | REST API local en Python. También sirve los archivos del frontend. |
| [backend/app.py](./backend/app.py) | Punto de entrada del servidor local. Expone las rutas REST y sirve la aplicación web. |
| [backend/config.py](./backend/config.py) | Configuración de conexión a SQL Server mediante variables de entorno. |
| [backend/database.py](./backend/database.py) | Creación del engine SQLAlchemy y configuración del pool fijo de conexiones. |
| [backend/models.py](./backend/models.py) | Modelos ORM que representan las tablas usadas por el backend. |
| [backend/repositories.py](./backend/repositories.py) | Consultas de lectura usando SQLAlchemy ORM. |
| [backend/services.py](./backend/services.py) | Operaciones de escritura llamando Stored Procedures. |
| [backend/README.md](./backend/README.md) | Documentación específica del backend y de la ejecución local/Docker. |
| [Gathel/Gathel/migrations/](./Gathel/Gathel/migrations) | Migraciones Flyway vigentes para crear, poblar y extender la base de datos. |
| [V001_20260618004000__creacionDB.sql](./Gathel/Gathel/migrations/V001_20260618004000__creacionDB.sql) | Creación del esquema principal de base de datos. |
| [V002_20260618004000__seeding.sql](./Gathel/Gathel/migrations/V002_20260618004000__seeding.sql) | Seeding masivo y validaciones de consistencia. |
| [V003_20260618012500__securityLab.sql](./Gathel/Gathel/migrations/V003_20260618012500__securityLab.sql) | Laboratorio de seguridad, incluyendo Row-Level Security. |
| [V004_20260618030000__mvpStoredProcedures.sql](./Gathel/Gathel/migrations/V004_20260618030000__mvpStoredProcedures.sql) | Stored Procedures usados por el backend del MVP. |
| [Transacciones y concurrencia/](./Transacciones%20y%20concurrencia) | Scripts y pruebas de transacciones, niveles de aislamiento y deadlocks. |
| [compose.yaml](./compose.yaml) | Configuración Docker para ejecutar frontend + backend en un contenedor conectado a SQL Server externo. |

## Proceso seguido para construir el proyecto

### 1. Reunión inicial y reutilización del Caso 2

Primero nos reunimos como equipo para revisar el trabajo realizado en el Caso 2 y decidir qué partes podían reutilizarse para Gathel. El objetivo no era empezar desde cero, sino aprovechar lo que ya servía: ideas de modelo relacional, estructura de entidades, etc.

Durante esta etapa definimos qué debía mantenerse, qué debía corregirse y qué debía rediseñarse para cumplir con el nuevo enunciado del Caso 3.

### 2. Revisión con apoyo de IA

Después usamos un revisor con apoyo de IA para analizar el diseño y detectar inconsistencias. Esta revisión ayudó a encontrar puntos de mejora en la estructura de tablas, relaciones, integridad referencial y alcance del MVP.

A partir de esa revisión aplicamos correcciones al diseño antes de continuar con la implementación final.

### 3. Envío al profesor y retroalimentación

Luego se envió el avance al profesor para recibir feedback. Con esa retroalimentación ajustamos el proyecto para alinearlo mejor con los requisitos del curso, especialmente en temas de:

### 4. Configuración de Flyway en ambas computadoras

Después nos reunimos para hacer funcionar Flyway en las computadoras de ambos integrantes. Esta parte fue importante porque el proyecto debía poder migrarse y probarse en más de un ambiente local.

Durante esta etapa verificamos que:

- Flyway pudiera conectarse a SQL Server.
- Las migraciones estuvieran en el orden correcto.
- La base `Gathel` pudiera reconstruirse correctamente.
- Los archivos versionados fueran reconocidos por Flyway.
- Los problemas de nombres de migraciones y limpieza de base quedaran corregidos.

Las migraciones vigentes quedaron dentro de [Gathel/Gathel/migrations/](./Gathel/Gathel/migrations).

### 5. Creación del esquema de base de datos

Con Flyway funcionando, consolidamos el script de creación de base en:

[V001_20260618004000__creacionDB.sql](./Gathel/Gathel/migrations/V001_20260618004000__creacionDB.sql)

Esta migración crea las tablas principales del proyecto, incluyendo jugadores, monedas, balances, redes sociales, recursos, proposiciones, predicciones, pagos, transacciones y resultados.

### 6. Construcción del seeding

Luego creamos el seeding principal en:

[V002_20260618004000__seeding.sql](./Gathel/Gathel/migrations/V002_20260618004000__seeding.sql)

El seeding fue diseñado para generar datos realistas y suficientes para la revisión del proyecto. Incluye, como mínimo:

- 1000 jugadores,
- 5000 proposiciones,
- 250000 predicciones/eventos asociados,
- registros de pagos asociados a las proposiciones,
- balances de puntos,
- balances de dinero real,
- transacciones,
- resultados,
- y validaciones de integridad.

El seeding no se hizo con miles de inserts manuales exhaustivos. Se generó usando lógica SQL con conjuntos y validaciones para mantener consistencia, integridad referencial y fechas coherentes.

### 7. Creación de Stored Procedures del MVP

Después se implementaron los Stored Procedures necesarios para que el backend pudiera realizar escrituras sin insertar directamente desde Python.

Estos SPs están en:

[V004_20260618030000__mvpStoredProcedures.sql](./Gathel/Gathel/migrations/V004_20260618030000__mvpStoredProcedures.sql)

Stored Procedures principales:

- `dbo.sp_CreateProposition`
- `dbo.sp_CreatePrediction`

El backend llama estos procedimientos desde [backend/services.py](./backend/services.py).

### 8. Laboratorio de seguridad

Luego se trabajó el security lab en:

[V003_20260618012500__securityLab.sql](./Gathel/Gathel/migrations/V003_20260618012500__securityLab.sql)

Esta parte incluye elementos como:

- usuarios y roles de laboratorio,
- permisos,
- Dynamic Data Masking,
- Row-Level Security sobre proposiciones,
- cuentas técnicas autorizadas para el backend.

Durante las pruebas encontramos que Row-Level Security podía ocultar proposiciones aunque existieran físicamente en la tabla. Por eso se ajustó la política para contemplar usuarios necesarios del laboratorio y la cuenta técnica usada por el backend.

### 9. Frontend y backend con apoyo de ChatGPT

Después, con apoyo de ChatGPT, construimos el frontend y el backend del MVP.

El frontend se encuentra en:

- [frontend/index.html](./frontend/index.html)
- [frontend/styles.css](./frontend/styles.css)
- [frontend/app.js](./frontend/app.js)

El backend se encuentra en:

- [backend/app.py](./backend/app.py)
- [backend/config.py](./backend/config.py)
- [backend/database.py](./backend/database.py)
- [backend/models.py](./backend/models.py)
- [backend/repositories.py](./backend/repositories.py)
- [backend/services.py](./backend/services.py)

Se decidió que el backend sirviera también los archivos del frontend. La forma objetivo de levantar el proyecto es con Docker, usando [compose.yaml](./compose.yaml). Durante la depuración usamos ejecución directa con Python solamente por facilidad, para probar cambios rápidos sin reconstruir el contenedor en cada intento.

### 10. Transacciones y concurrencia

Después se trabajaron los scripts de transacciones y concurrencia en:

[Transacciones y concurrencia/](./Transacciones%20y%20concurrencia)

Archivos principales:

- [Flujo de datos.sql](./Transacciones%20y%20concurrencia/Flujo%20de%20datos.sql)
- [Niveles de aislamiento.sql](./Transacciones%20y%20concurrencia/Niveles%20de%20aislamiento.sql)
- [Deadlocks.sql](./Transacciones%20y%20concurrencia/Deadlocks.sql)
- [Deadlock cíclico.sql](./Transacciones%20y%20concurrencia/Deadlock%20c%C3%ADclico.sql)

Estos scripts permiten demostrar comportamiento transaccional, bloqueos, niveles de aislamiento y escenarios de concurrencia en SQL Server.

### 11. Depuración final del frontend/backend

Finalmente pasamos por una etapa de depuración para que el frontend y backend funcionaran correctamente contra SQL Server.

Entre los problemas corregidos o revisados estuvieron:

- eliminación de la base alternativa local usada en prototipos iniciales,
- conexión real del backend a SQL Server,
- configuración del usuario SQL `gathel_app`,
- habilitación de autenticación SQL Server,
- revisión del puerto TCP 1433,
- errores de login por autenticación,
- errores de Flyway por nombres de migraciones,
- errores por base parcialmente creada luego de `clean`,
- validación de que las proposiciones existieran físicamente,
- revisión de Row-Level Security cuando las proposiciones no aparecían,
- ajuste de frontend para usar datos reales de la base,
- limpieza de datos hardcodeados que venían de prototipos iniciales,
- buscador de jugadores al crear una proposición para otro jugador,
- y validación de que las rutas REST coincidieran con lo que consume el frontend.

## Arquitectura final

```text
Navegador
   ↓
Frontend web
   ↓ REST API
Backend Python
   ↓ lecturas con ORM
SQL Server
   ↑ escrituras por Stored Procedures
```

El frontend no se conecta directamente a SQL Server. Siempre llama al backend mediante rutas REST. El backend decide si la operación es lectura o escritura:

- Lecturas: se hacen con SQLAlchemy ORM en [backend/repositories.py](./backend/repositories.py).
- Escrituras: se hacen con Stored Procedures desde [backend/services.py](./backend/services.py).

## REST API implementado

| Método | Ruta | Uso |
|---|---|---|
| `GET` | `/api/health` | Verifica que el backend pueda conectarse a SQL Server. |
| `POST` | `/api/auth/login` | Inicia sesión con un jugador existente. |
| `POST` | `/api/auth/logout` | Cierra sesión local. |
| `GET` | `/api/me/dashboard` | Devuelve jugador, balances y actividad. |
| `GET` | `/api/players?search=` | Busca jugadores para crear proposiciones. |
| `GET` | `/api/propositions` | Lista proposiciones activas. |
| `POST` | `/api/propositions` | Crea una proposición mediante Stored Procedure. |
| `POST` | `/api/predictions` | Registra un pronóstico mediante Stored Procedure. |
| `GET` | `/api/propositions/results` | Lista resultados del jugador autenticado. |

## Ejecución principal con Docker

La configuración Docker contiene frontend + backend en un único servicio. SQL Server no está contenerizado; permanece instalado en Windows y el contenedor se conecta mediante `host.docker.internal`.

Requisitos:

- SQL Server iniciado y escuchando en TCP 1433.
- Migraciones Flyway V001-V004 aplicadas.
- Usuario SQL con permisos de lectura y ejecución de Stored Procedures.
- Docker Desktop iniciado.

Preparar variables:

```powershell
Copy-Item backend\.env.example .env
notepad .env
```

Construir y ejecutar:

```powershell
docker compose up -d --build
docker compose ps
```

Abrir:

```text
http://127.0.0.1:5080
```

## Ejecución directa con Python para pruebas rápidas

Durante el desarrollo también levantamos el backend directamente con Python. Esta forma no es la ejecución principal de entrega; se usó por facilidad para probar errores de conexión, login, Row-Level Security y cambios de frontend/backend sin reconstruir Docker constantemente.

Antes de usarla, configure las variables de conexión a SQL Server y asegúrese de que Flyway haya aplicado las migraciones V001-V004 sobre la base `Gathel`.

Ejemplo en Windows PowerShell:

```powershell
cd "C:\Mac\Home\Desktop\Caso-3"

$env:GATHEL_SQL_HOST="KENNETHYUEN6946"
$env:GATHEL_SQL_PORT="1433"
$env:GATHEL_SQL_DATABASE="Gathel"
$env:GATHEL_SQL_USER="gathel_app"
$env:GATHEL_SQL_PASSWORD="123"
$env:GATHEL_SQL_DRIVER="ODBC Driver 18 for SQL Server"

py -3.14 backend\app.py
```

Luego abra:

```text
http://127.0.0.1:5080
```

Para revisar conexión:

```powershell
Invoke-RestMethod http://127.0.0.1:5080/api/health
```

La respuesta esperada debe indicar:

```text
mode: sqlserver
```

## Decisiones importantes

- Las migraciones dentro de [Gathel/Gathel/migrations/](./Gathel/Gathel/migrations) son la fuente vigente del esquema.
- Los scripts SQL históricos ubicados fuera de las migraciones no son la fuente principal de la base.
- El proyecto trabaja directamente contra SQL Server.
- El frontend usa datos reales devueltos por el backend.
- El backend se conecta directamente a SQL Server.
- La creación de proposiciones y pronósticos se hace mediante Stored Procedures.
- Las consultas de dashboard, jugadores, proposiciones y resultados se hacen mediante ORM.
- Los procesos avanzados fuera del alcance del MVP pueden demostrarse con scripts SQL o Stored Procedures adicionales.

## Estado final

El proyecto quedó preparado para demostrar el MVP de Gathel localmente con SQL Server, Flyway, backend REST API y frontend web. La base se construye mediante migraciones, el seeding genera datos suficientes para revisión, el backend expone los endpoints necesarios y el frontend permite navegar los flujos principales del jugador.
