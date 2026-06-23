from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import quote_plus as quotePlus


baseDir = Path(__file__).resolve().parent
projectDir = baseDir.parent


def buildDatabaseUrl() -> str:
    explicitUrl = os.getenv("GATHEL_DATABASE_URL")
    if explicitUrl:
        if not explicitUrl.startswith("mssql+pyodbc://"):
            raise RuntimeError("GATHEL_DATABASE_URL debe apuntar a SQL Server usando mssql+pyodbc.")
        return explicitUrl

    host = os.getenv("GATHEL_SQL_HOST", "host.docker.internal")
    port = os.getenv("GATHEL_SQL_PORT", "1433")
    database = os.getenv("GATHEL_SQL_DATABASE", "Gathel")
    username = os.getenv("GATHEL_SQL_USER", "")
    password = os.getenv("GATHEL_SQL_PASSWORD", "")
    driver = quotePlus(os.getenv("GATHEL_SQL_DRIVER", "ODBC Driver 18 for SQL Server"))

    if not username or not password:
        raise RuntimeError(
            "GATHEL_SQL_USER y GATHEL_SQL_PASSWORD son obligatorios para conectar con SQL Server."
        )

    return (
        f"mssql+pyodbc://{quotePlus(username)}:{quotePlus(password)}"
        f"@{host}:{port}/{database}"
        f"?driver={driver}&Encrypt=yes&TrustServerCertificate=yes"
    )


@dataclass(frozen=True)
class Settings:
    host: str = os.getenv("GATHEL_API_HOST", "127.0.0.1")
    port: int = int(os.getenv("GATHEL_API_PORT", "5080"))
    databaseUrl: str = buildDatabaseUrl()
    frontendDir: Path = projectDir / "frontend"
    poolSize: int = int(os.getenv("GATHEL_DB_POOL_SIZE", "3"))


settings = Settings()
