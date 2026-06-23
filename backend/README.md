# Gathel Backend local

REST API local para conectar el frontend con los datos de Gathel.

## Arquitectura

```text
Navegador → API Python local → SQLAlchemy → SQL Server
                                  ↓
                         Stored Procedures
                         para escrituras
```

- Las lecturas utilizan SQLAlchemy ORM contra SQL Server.
- Las escrituras llaman `sp_CreateProposition` y `sp_CreatePrediction`.
- El pool es fijo y pequeño: 3 conexiones por defecto.
- El mismo proceso sirve el frontend, por lo que no es necesario configurar CORS en uso normal.

## Docker en Windows 11 ARM o x64

La configuración recomendada mantiene SQL Server 2022 instalado en Windows y
ejecuta frontend + backend dentro de un único contenedor Linux:

```text
Navegador → Docker: Gathel frontend + REST API
                         │
                         ▼
               host.docker.internal:1433
                         │
                         ▼
             SQL Server instalado en Windows
```

La imagen instala automáticamente:

- Python 3.12.
- SQLAlchemy.
- `pyodbc`.
- UnixODBC.
- Microsoft ODBC Driver 18 for SQL Server.

Funciona tanto al construir para ARM64 como para x64. SQL Server no forma parte
del Compose y debe estar iniciado en Windows.

### 1. Preparar SQL Server

Antes de usar Docker:

- Aplique las migraciones Flyway V001-V004 sobre la base `Gathel`.
- Habilite TCP/IP y el puerto fijo `1433`.
- Habilite SQL Server Authentication, porque Windows Authentication no se
  transmite automáticamente desde el contenedor Linux.

Compruebe desde PowerShell:

```powershell
Test-NetConnection localhost -Port 1433
```

### 2. Crear un login exclusivo para el contenedor

Ejecute en SSMS con una cuenta administradora:

```sql
USE master;
GO

IF SUSER_ID(N'gathel_app') IS NULL
BEGIN
    CREATE LOGIN gathel_app
    WITH PASSWORD = 'Cambiar#EstaClave2026',
         CHECK_POLICY = ON,
         CHECK_EXPIRATION = OFF;
END;
GO

USE Gathel;
GO

IF DATABASE_PRINCIPAL_ID(N'gathel_app') IS NULL
BEGIN
    CREATE USER gathel_app FOR LOGIN gathel_app;
END;
GO

ALTER ROLE db_datareader ADD MEMBER gathel_app;
GRANT EXECUTE ON dbo.sp_CreateProposition TO gathel_app;
GRANT EXECUTE ON dbo.sp_CreatePrediction TO gathel_app;
GO
```

No se asigna `db_datawriter`: las escrituras del MVP deben pasar por los Stored
Procedures.

V003 registra `gathel_app` en
`SecurityLab.ApplicationServiceAccounts`. Esto permite que la cuenta técnica
del REST API consulte las proposiciones protegidas por Row-Level Security sin
eliminar la restricción de los usuarios del laboratorio.

Si utiliza otro nombre en `GATHEL_SQL_USER`, regístrelo también:

```sql
INSERT SecurityLab.ApplicationServiceAccounts
    (dbUserName, serviceDescription, isActive)
VALUES
    (N'otro_usuario_api', N'Cuenta técnica alternativa del REST API', 1);
```

### 3. Crear `.env`

Desde la raíz del repositorio:

```powershell
Copy-Item backend\.env.example .env
notepad .env
```

Configure:

```text
GATHEL_API_PORT=5080
GATHEL_DB_POOL_SIZE=3
GATHEL_SQL_HOST=host.docker.internal
GATHEL_SQL_PORT=1433
GATHEL_SQL_DATABASE=Gathel
GATHEL_SQL_USER=gathel_app
GATHEL_SQL_PASSWORD="Cambiar#EstaClave2026"
GATHEL_SQL_DRIVER=ODBC Driver 18 for SQL Server
```

La clave del `.env` debe coincidir con la utilizada en `CREATE LOGIN`. El
archivo `.env` está excluido de Git y de la imagen Docker.

### 4. Construir y ejecutar

```powershell
docker compose build
docker compose up -d
```

Compruebe:

```powershell
docker compose ps
docker compose logs -f app
```

Abra:

```text
http://127.0.0.1:5080
```

El servicio estará marcado como `healthy` únicamente cuando el API pueda
ejecutar `SELECT 1` contra la base configurada.

### 5. Detener o reconstruir

```powershell
docker compose down
```

Después de cambiar código:

```powershell
docker compose up -d --build
```

Para borrar solamente el contenedor y la imagen local:

```powershell
docker compose down --rmi local
```

Esto no elimina ni modifica la base SQL Server instalada en Windows.

### Diagnóstico Docker

Si el contenedor aparece `unhealthy`:

```powershell
docker compose logs app
docker compose exec app python -c "import pyodbc; print(pyodbc.drivers())"
```

Debe aparecer:

```text
ODBC Driver 18 for SQL Server
```

Compruebe que SQL Server acepta autenticación SQL:

```powershell
sqlcmd -S localhost,1433 -U gathel_app -P "Cambiar#EstaClave2026" -C -Q "SELECT DB_NAME()"
```

Problemas habituales:

- TCP/IP o el puerto `1433` están deshabilitados.
- SQL Server está configurado únicamente para Windows Authentication.
- El firewall bloquea el acceso al puerto.
- La clave del `.env` no coincide con el login.
- Flyway todavía no aplicó V003 o V004.

## Ejecutar conectado a SQL Server

Se necesita el controlador de Python para ODBC:

```bash
python3 -m pip install -r backend/requirements.txt
```

También debe estar instalado Microsoft ODBC Driver 18 for SQL Server.

Ejemplo:

```bash
export GATHEL_SQL_HOST=localhost
export GATHEL_SQL_USER=gathel_app
export GATHEL_SQL_PASSWORD='Cambiar#EstaClave2026'
python3 backend/app.py
```

Flyway debe haber aplicado primero las migraciones, incluida V004 con los Stored Procedures.

## Endpoints

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/api/health` | Estado del API |
| `POST` | `/api/auth/login` | Iniciar sesión |
| `POST` | `/api/auth/logout` | Cerrar sesión |
| `GET` | `/api/me/dashboard` | Perfil, balances y actividad |
| `GET` | `/api/players?search=` | Buscar jugadores |
| `GET` | `/api/propositions` | Proposiciones activas |
| `POST` | `/api/propositions` | Crear mediante SP |
| `POST` | `/api/predictions` | Pronosticar mediante SP |
| `GET` | `/api/propositions/results` | Resultados del jugador |

## Nota de autenticación

El seeding vigente guarda contraseñas de demostración en `passwordHash` como texto. El API replica ese comportamiento solamente para cumplir el MVP existente. Antes de cualquier uso real debe sustituirse por hashes seguros.
