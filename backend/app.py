from __future__ import annotations

import json
import mimetypes
from datetime import datetime
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from secrets import token_urlsafe as tokenUrlSafe
from urllib.parse import parse_qs as parseQs, urlparse

from sqlalchemy import text

from config import settings
from database import sessionScope
from repositories import GathelReadRepository, playerJson
from services import GathelWriteService


TOKENS: dict[str, int] = {}


class ApiError(Exception):
    def __init__(self, status: int, message: str):
        super().__init__(message)
        self.status = status
        self.message = message


class GathelHandler(BaseHTTPRequestHandler):
    server_version = "GathelLocalAPI/1.0"

    def do_OPTIONS(self):
        self.send_response(HTTPStatus.NO_CONTENT)
        self._cors_headers()
        self.end_headers()

    def do_GET(self):
        self._dispatch()

    def do_POST(self):
        self._dispatch()

    def _dispatch(self):
        parsed = urlparse(self.path)
        try:
            if parsed.path.startswith("/api/"):
                self._handleApi(parsed.path, parseQs(parsed.query))
            elif self.command == "GET":
                self._serveFrontend(parsed.path)
            else:
                raise ApiError(HTTPStatus.NOT_FOUND, "Ruta no encontrada.")
        except ApiError as error:
            self._json(error.status, {"error": error.message})
        except ValueError as error:
            self._json(HTTPStatus.BAD_REQUEST, {"error": str(error)})
        except LookupError as error:
            self._json(HTTPStatus.NOT_FOUND, {"error": str(error)})
        except Exception as error:
            print(f"[backend] {type(error).__name__}: {error}")
            self._json(
                HTTPStatus.INTERNAL_SERVER_ERROR,
                {"error": "Ocurrió un error interno en el API local."},
            )

    def _handleApi(self, path: str, query: dict[str, list[str]]):
        if path == "/api/health" and self.command == "GET":
            with sessionScope() as session:
                session.execute(text("SELECT 1"))
            self._json(
                HTTPStatus.OK,
                {
                    "status": "ok",
                    "mode": "sqlserver",
                    "time": datetime.utcnow().isoformat(),
                },
            )
            return

        if path == "/api/auth/login" and self.command == "POST":
            payload = self._body()
            with sessionScope() as session:
                repository = GathelReadRepository(session)
                player = repository.authenticate(
                    str(payload.get("identifier", "")),
                    str(payload.get("password", "")),
                )
                if not player:
                    raise ApiError(HTTPStatus.UNAUTHORIZED, "Credenciales inválidas.")
                token = tokenUrlSafe(32)
                TOKENS[token] = player.playerID
                self._json(
                    HTTPStatus.OK,
                    {"token": token, "player": playerJson(player)},
                )
            return

        if path == "/api/auth/logout" and self.command == "POST":
            token = self._bearerToken()
            TOKENS.pop(token, None)
            self._json(HTTPStatus.OK, {"ok": True})
            return

        playerId = self._authenticatedPlayer()

        with sessionScope() as session:
            repository = GathelReadRepository(session)

            if path == "/api/me/dashboard" and self.command == "GET":
                self._json(HTTPStatus.OK, repository.dashboard(playerId))
                return

            if path == "/api/players" and self.command == "GET":
                self._json(
                    HTTPStatus.OK,
                    repository.players(query.get("search", [""])[0]),
                )
                return

            if path == "/api/propositions" and self.command == "GET":
                self._json(
                    HTTPStatus.OK,
                    repository.activePropositions(
                        search=query.get("search", [""])[0],
                        limit=int(query.get("limit", ["100"])[0]),
                    ),
                )
                return

            if path == "/api/propositions/results" and self.command == "GET":
                self._json(
                    HTTPStatus.OK,
                    repository.results(
                        playerId,
                        limit=int(query.get("limit", ["100"])[0]),
                    ),
                )
                return

            writer = GathelWriteService(session)
            if path == "/api/propositions" and self.command == "POST":
                propositionId = writer.createProposition(playerId, self._body())
                self._json(
                    HTTPStatus.CREATED,
                    {"propositionId": propositionId, "status": "pending"},
                )
                return

            if path == "/api/predictions" and self.command == "POST":
                predictionId = writer.createPrediction(playerId, self._body())
                self._json(
                    HTTPStatus.CREATED,
                    {"predictionId": predictionId, "status": "active"},
                )
                return

        raise ApiError(HTTPStatus.NOT_FOUND, "Ruta no encontrada.")

    def _serveFrontend(self, requestedPath: str):
        relative = requestedPath.lstrip("/") or "index.html"
        candidate = (settings.frontendDir / relative).resolve()
        frontendRoot = settings.frontendDir.resolve()

        if frontendRoot not in candidate.parents and candidate != frontendRoot:
            raise ApiError(HTTPStatus.FORBIDDEN, "Ruta inválida.")
        if not candidate.is_file():
            candidate = frontendRoot / "index.html"

        mimeType = mimetypes.guess_type(candidate.name)[0] or "application/octet-stream"
        data = candidate.read_bytes()
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", mimeType)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        self.wfile.write(data)

    def _body(self) -> dict:
        length = int(self.headers.get("Content-Length", "0"))
        if length <= 0:
            return {}
        try:
            return json.loads(self.rfile.read(length).decode("utf-8"))
        except json.JSONDecodeError as error:
            raise ApiError(HTTPStatus.BAD_REQUEST, "JSON inválido.") from error

    def _bearerToken(self) -> str:
        authorization = self.headers.get("Authorization", "")
        if not authorization.startswith("Bearer "):
            raise ApiError(HTTPStatus.UNAUTHORIZED, "Falta el token de sesión.")
        return authorization.removeprefix("Bearer ").strip()

    def _authenticatedPlayer(self) -> int:
        token = self._bearerToken()
        playerId = TOKENS.get(token)
        if not playerId:
            raise ApiError(HTTPStatus.UNAUTHORIZED, "La sesión expiró o no es válida.")
        return playerId

    def _json(self, status: int, payload: dict | list):
        encoded = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(encoded)))
        self._cors_headers()
        self.end_headers()
        self.wfile.write(encoded)

    def _cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")

    def log_message(self, format: str, *args):
        print(f"[http] {self.address_string()} - {format % args}")


def main():
    server = ThreadingHTTPServer((settings.host, settings.port), GathelHandler)
    print(
        f"Gathel local ejecutándose en http://{settings.host}:{settings.port} "
        "(SQL Server)"
    )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nServidor detenido.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
