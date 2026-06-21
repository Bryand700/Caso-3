from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import quote_plus


BASE_DIR = Path(__file__).resolve().parent
PROJECT_DIR = BASE_DIR.parent


def env_flag(name: str, default: str) -> bool:
    return os.getenv(name, default).lower() in {"1", "true", "yes"}


def build_database_url() -> str:
    explicit_url = os.getenv("GATHEL_DATABASE_URL")
    if explicit_url:
        return explicit_url

    if env_flag("GATHEL_DEMO_MODE", "true"):
        return f"sqlite+pysqlite:///{BASE_DIR / 'gathel-demo-v4.db'}"

    host = os.getenv("GATHEL_SQL_HOST", "host.docker.internal")
    port = os.getenv("GATHEL_SQL_PORT", "1433")
    database = os.getenv("GATHEL_SQL_DATABASE", "Gathel")
    username = os.getenv("GATHEL_SQL_USER", "")
    password = os.getenv("GATHEL_SQL_PASSWORD", "")
    driver = quote_plus(os.getenv("GATHEL_SQL_DRIVER", "ODBC Driver 18 for SQL Server"))

    if not username or not password:
        raise RuntimeError(
            "GATHEL_SQL_USER y GATHEL_SQL_PASSWORD son obligatorios "
            "cuando GATHEL_DEMO_MODE=false."
        )

    return (
        f"mssql+pyodbc://{quote_plus(username)}:{quote_plus(password)}"
        f"@{host}:{port}/{database}"
        f"?driver={driver}&Encrypt=yes&TrustServerCertificate=yes"
    )


@dataclass(frozen=True)
class Settings:
    host: str = os.getenv("GATHEL_API_HOST", "127.0.0.1")
    port: int = int(os.getenv("GATHEL_API_PORT", "5080"))
    database_url: str = build_database_url()
    frontend_dir: Path = PROJECT_DIR / "frontend"
    pool_size: int = int(os.getenv("GATHEL_DB_POOL_SIZE", "3"))
    demo_mode: bool = env_flag("GATHEL_DEMO_MODE", "true")


settings = Settings()
