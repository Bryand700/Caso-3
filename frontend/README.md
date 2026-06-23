# Gathel Frontend MVP

Frontend web responsive del MVP de Gathel. Consume el REST API incluido en `backend/`.

## Ejecutar

La forma recomendada es ejecutar el backend, que también sirve estos archivos:

```bash
python3 backend/app.py
```

Luego abra `http://127.0.0.1:5080`.

Use las credenciales de un jugador existente en la base SQL Server `Gathel`.

## Alcance implementado

- Login y logout local.
- Dashboard con balance de puntos, dinero real y actividad.
- Exploración y filtrado de proposiciones activas.
- Pronósticos con puntos o dinero real.
- Creación de proposiciones sobre otro jugador o sobre el jugador actual.
- Registro genérico del tipo y URL del recurso social.
- Historial de resultados finalizados.
- Diseño responsive para navegadores modernos en Windows 11 ARM, Windows 11 x64 y dispositivos móviles.

## Límites intencionales

- Los datos provienen del esquema y seeding Flyway en SQL Server.
- No hay integración real con redes sociales ni inteligencia artificial.
- El frontend no muestra razonamiento, análisis, autenticidad ni pasos internos de validación.
- Votaciones, aceptación, cierre, liquidaciones, penalizaciones y otros workflows avanzados quedan fuera del flujo del MVP.
- La aplicación recibe conceptualmente únicamente estados finales de esos procesos.

## Contratos REST implementados

| Método | Ruta | Uso |
|---|---|---|
| `POST` | `/api/auth/login` | Iniciar sesión |
| `POST` | `/api/auth/logout` | Cerrar sesión |
| `GET` | `/api/me/dashboard` | Saldos y actividad |
| `GET` | `/api/propositions?status=active` | Listar proposiciones activas |
| `POST` | `/api/propositions` | Crear proposición mediante Stored Procedure |
| `POST` | `/api/predictions` | Registrar pronóstico mediante Stored Procedure |
| `GET` | `/api/propositions/results` | Consultar resultados finalizados |

Las lecturas están implementadas con SQLAlchemy ORM. Las escrituras llaman directamente a Stored Procedures.
