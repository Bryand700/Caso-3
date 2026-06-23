from __future__ import annotations

from decimal import Decimal

from sqlalchemy import text
from sqlalchemy.orm import Session


class GathelWriteService:
    def __init__(self, session: Session):
        self.session = session

    def createProposition(self, playerId: int, payload: dict) -> int:
        required = ["targetPlayerId", "text", "resourceType", "resourceUrl"]
        missing = [field for field in required if not payload.get(field)]
        if missing:
            raise ValueError(f"Faltan campos: {', '.join(missing)}")

        result = self.session.execute(
            text(
                """
            EXEC dbo.sp_CreateProposition
                @CreatorPlayerID=:creator,
                @TargetPlayerID=:target,
                @PropositionText=:text,
                @ResourceTypeName=:resourceType,
                @ContentURL=:contentUrl,
                @PredictionMode=:predictionMode
                """
            ),
            {
                "creator": playerId,
                "target": int(payload["targetPlayerId"]),
                "text": str(payload["text"]).strip(),
                "resourceType": str(payload["resourceType"]).strip().lower(),
                "contentUrl": str(payload["resourceUrl"]).strip(),
                "predictionMode": str(payload.get("predictionMode", "BOTH")),
            },
        ).mappings().first()
        self.session.commit()
        if not result:
            raise RuntimeError("El Stored Procedure no devolvió el identificador.")
        return int(result["propositionID"])

    def createPrediction(self, playerId: int, payload: dict) -> int:
        required = ["propositionId", "answer", "currencyCode", "amount"]
        missing = [field for field in required if payload.get(field) in (None, "")]
        if missing:
            raise ValueError(f"Faltan campos: {', '.join(missing)}")

        amount = Decimal(str(payload["amount"]))
        if amount <= 0:
            raise ValueError("El monto debe ser mayor que cero.")

        result = self.session.execute(
            text(
                """
            EXEC dbo.sp_CreatePrediction
                @PlayerID=:playerId,
                @PropositionID=:propositionId,
                @PredictionTypeName=:answer,
                @CurrencyCode=:currency,
                @Amount=:amount
                """
            ),
            {
                "playerId": playerId,
                "propositionId": int(payload["propositionId"]),
                "answer": "si" if str(payload["answer"]).lower() in {"yes", "si", "sí"} else "no",
                "currency": str(payload["currencyCode"]).upper(),
                "amount": amount,
            },
        ).mappings().first()
        self.session.commit()
        if not result:
            raise RuntimeError("El Stored Procedure no devolvió el identificador.")
        return int(result["predictionID"])
