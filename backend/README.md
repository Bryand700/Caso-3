# Gathel Backend local

REST API local para conectar el frontend con los datos de Gathel.

## Arquitectura

```text
Navegador → API Python local → SQLAlchemy → SQL Server
                                  ↓
                         Stored Procedures
                         para escrituras
```

- Las lecturas utilizan SQLAlchemy ORM.
- En modo SQL Server, las escrituras llaman `sp_CreateProposition` y `sp_CreatePrediction`.
- El pool es fijo y pequeño: 3 conexiones por defecto.
- El mismo proceso sirve el frontend, por lo que no es necesario configurar CORS en uso normal.

## Ejecución inmediata sin instalaciones

SQLAlchemy ya está disponible en el ambiente actual. Desde la raíz:

```bash
cd backend
GATHEL_DEMO_MODE=true python3 app.py
```

Abra `http://127.0.0.1:5080`.

Credenciales de demostración:

```text
Correo: daniela@gathel.local
Contraseña: DemoGathel2026
```

Este modo crea `backend/gathel-demo.db` para comprobar el conjunto frontend/API. Es únicamente una alternativa local de desarrollo.

## Conectar el SQL Server real

Se necesita el controlador de Python para ODBC:

```bash
python3 -m pip install -r backend/requirements.txt
```

También debe estar instalado Microsoft ODBC Driver 18 for SQL Server.

Ejemplo:

```bash
export GATHEL_DEMO_MODE=false
export GATHEL_DATABASE_URL='mssql+pyodbc://usuario:clave@localhost:1433/Gathel?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes'
cd backend
python3 app.py
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
