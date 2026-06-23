# Gathel — Gaming the life

Repositorio del Caso 3 de Bases de Datos.

## MVP

- [Frontend web](./frontend/README.md): interfaz responsive con login, dashboard, creación de proposiciones, pronósticos y resultados.
- [Backend local](./backend/README.md): REST API con SQLAlchemy ORM para lecturas y Stored Procedures para escrituras.
- [Migraciones Flyway](./Gathel/Gathel/migrations): creación, seeding y laboratorio de seguridad para SQL Server.

Los scripts SQL ubicados en la raíz se conservan intencionalmente como versiones históricas. Las migraciones dentro de `Gathel/Gathel/migrations` son la fuente vigente del esquema.

## Ejecutar el conjunto local

Primero configure las variables de conexión a SQL Server y asegúrese de que
Flyway haya aplicado las migraciones V001-V004 sobre la base `Gathel`.

Ejemplo:

```bash
export GATHEL_SQL_HOST=localhost
export GATHEL_SQL_USER=gathel_app
export GATHEL_SQL_PASSWORD='123'
python3 backend/app.py
```

Abra `http://127.0.0.1:5080`.

El frontend y el backend trabajan directamente contra SQL Server. Consulte la
configuración completa en [backend/README.md](./backend/README.md).

## Ejecutar con Docker y SQL Server en Windows

La configuración de Docker contiene frontend y backend en un único servicio.
SQL Server 2022 permanece instalado en Windows y el contenedor se conecta
mediante `host.docker.internal`.

Requisitos previos:

- SQL Server iniciado y escuchando por TCP en `1433`.
- Migraciones Flyway V001-V004 aplicadas.
- Un login SQL con lectura y permiso para ejecutar los Stored Procedures.
- Docker Desktop iniciado.

Prepare las variables:

```powershell
Copy-Item backend\.env.example .env
notepad .env
```

Construya y ejecute:

```powershell
docker compose up -d --build
docker compose ps
```

Abra:

```text
http://127.0.0.1:5080
```

Las instrucciones completas, incluido el SQL para crear `gathel_app`, están en
[backend/README.md](./backend/README.md).
