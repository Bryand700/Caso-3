from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent
PROJECT_DIR = BASE_DIR.parent


@dataclass(frozen=True)
class Settings:
    host: str = os.getenv("GATHEL_API_HOST", "127.0.0.1")
    port: int = int(os.getenv("GATHEL_API_PORT", "5080"))
    database_url: str = os.getenv(
        "GATHEL_DATABASE_URL",
        f"sqlite+pysqlite:///{BASE_DIR / 'gathel-demo-v4.db'}",
    )
    frontend_dir: Path = PROJECT_DIR / "frontend"
    pool_size: int = int(os.getenv("GATHEL_DB_POOL_SIZE", "3"))
    demo_mode: bool = os.getenv("GATHEL_DEMO_MODE", "true").lower() in {
        "1",
        "true",
        "yes",
    }


settings = Settings()
