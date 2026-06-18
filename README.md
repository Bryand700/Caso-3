# Gathel — Gaming the life

Repositorio del Caso 3 de Bases de Datos.

## MVP

- [Frontend web](./frontend/README.md): interfaz responsive con login, dashboard, creación de proposiciones, pronósticos y resultados.
- [Backend local](./backend/README.md): REST API con SQLAlchemy ORM para lecturas y Stored Procedures para escrituras.
- [Migraciones Flyway](./Gathel/Gathel/migrations): creación, seeding y laboratorio de seguridad para SQL Server.

Los scripts SQL ubicados en la raíz se conservan intencionalmente como versiones históricas. Las migraciones dentro de `Gathel/Gathel/migrations` son la fuente vigente del esquema.

## Ejecutar el conjunto local

```bash
cd backend
GATHEL_DEMO_MODE=true python3 app.py
```

Abra `http://127.0.0.1:5080`.

El modo demo usa una base SQLite local para ejecutar el conjunto sin instalar componentes. Para utilizar el seeding completo de SQL Server, consulte la configuración en [backend/README.md](./backend/README.md).
