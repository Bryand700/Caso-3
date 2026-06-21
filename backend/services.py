from __future__ import annotations

import hashlib
from datetime import datetime, timedelta
from decimal import Decimal

from sqlalchemy import select, text
from sqlalchemy.orm import Session

from config import settings
from models import (
    Balance,
    Currency,
    MoneyBalance,
    PlayerSocialNetwork,
    Prediction,
    PredictionStake,
    PredictionType,
    Proposition,
    PropositionPredictionCurrency,
    PropositionStatus,
    Resource,
    ResourceType,
)


class GathelWriteService:
    def __init__(self, session: Session):
        self.session = session

    def create_proposition(self, player_id: int, payload: dict) -> int:
        required = ["targetPlayerId", "text", "resourceType", "resourceUrl"]
        missing = [field for field in required if not payload.get(field)]
        if missing:
            raise ValueError(f"Faltan campos: {', '.join(missing)}")

        if settings.demo_mode:
            return self._create_proposition_demo(player_id, payload)

        result = self.session.execute(
            text(
                """
            EXEC dbo.sp_CreateProposition
                @CreatorPlayerID=:creator,
                @TargetPlayerID=:target,
                @PropositionText=:text,
                @ResourceTypeName=:resource_type,
                @ContentURL=:content_url,
                @PredictionMode=:prediction_mode
                """
            ),
            {
                "creator": player_id,
                "target": int(payload["targetPlayerId"]),
                "text": str(payload["text"]).strip(),
                "resource_type": str(payload["resourceType"]).strip().lower(),
                "content_url": str(payload["resourceUrl"]).strip(),
                "prediction_mode": str(payload.get("predictionMode", "BOTH")),
            },
        ).mappings().first()
        self.session.commit()
        if not result:
            raise RuntimeError("El Stored Procedure no devolvió el identificador.")
        return int(result["propositionID"])

    def create_prediction(self, player_id: int, payload: dict) -> int:
        required = ["propositionId", "answer", "currencyCode", "amount"]
        missing = [field for field in required if payload.get(field) in (None, "")]
        if missing:
            raise ValueError(f"Faltan campos: {', '.join(missing)}")

        amount = Decimal(str(payload["amount"]))
        if amount <= 0:
            raise ValueError("El monto debe ser mayor que cero.")

        if settings.demo_mode:
            return self._create_prediction_demo(player_id, payload, amount)

        result = self.session.execute(
            text(
                """
            EXEC dbo.sp_CreatePrediction
                @PlayerID=:player_id,
                @PropositionID=:proposition_id,
                @PredictionTypeName=:answer,
                @CurrencyCode=:currency,
                @Amount=:amount
                """
            ),
            {
                "player_id": player_id,
                "proposition_id": int(payload["propositionId"]),
                "answer": "si" if str(payload["answer"]).lower() in {"yes", "si", "sí"} else "no",
                "currency": str(payload["currencyCode"]).upper(),
                "amount": amount,
            },
        ).mappings().first()
        self.session.commit()
        if not result:
            raise RuntimeError("El Stored Procedure no devolvió el identificador.")
        return int(result["predictionID"])

    def _create_proposition_demo(self, player_id: int, payload: dict) -> int:
        target_id = int(payload["targetPlayerId"])
        social = self.session.scalar(
            select(PlayerSocialNetwork).where(
                PlayerSocialNetwork.playerID == target_id,
                PlayerSocialNetwork.isActive == True,
            )
        )
        resource_type = self.session.scalar(
            select(ResourceType).where(
                ResourceType.resourceTypeName == str(payload["resourceType"]).lower()
            )
        )
        pending = self.session.scalar(
            select(PropositionStatus).where(PropositionStatus.statusName == "pendiente")
        )
        if not social or not resource_type or not pending:
            raise ValueError("No existe la configuración necesaria para crear la proposición.")

        now = datetime.utcnow()
        resource = Resource(
            playerSocialNetworkID=social.playerSocialNetworkID,
            resourceTypeID=resource_type.resourceTypeID,
            externalResourceID=f"mvp-{int(now.timestamp() * 1000)}",
            contentURL=str(payload["resourceUrl"]).strip(),
            contentHash=hashlib.sha256(str(payload["resourceUrl"]).encode()).hexdigest().upper(),
            capturedAt=now,
            validationStatus="pending",
            isActive=True,
        )
        self.session.add(resource)
        self.session.flush()
        proposition = Proposition(
            creatorPlayerID=player_id,
            targetPlayerID=target_id,
            relatedResourceID=resource.resourceID,
            propositionStatusID=pending.propositionStatusID,
            propositionText=str(payload["text"]).strip(),
            predictionsDeadline=now + timedelta(days=1),
            votingDeadline=now + timedelta(days=3),
            acceptedAt=now,
            closedAt=now + timedelta(days=4),
            createdAt=now,
            isActive=True,
        )
        self.session.add(proposition)
        self.session.flush()
        mode = str(payload.get("predictionMode", "BOTH")).upper()
        currency_codes = ["POINT", "USD"] if mode == "BOTH" else [mode]
        currencies = self.session.scalars(
            select(Currency).where(Currency.currencyCode.in_(currency_codes))
        ).all()
        if not currencies:
            raise ValueError("No existen monedas válidas para la proposición.")
        self.session.add_all(
            [
                PropositionPredictionCurrency(
                    propositionID=proposition.propositionID,
                    currencyID=currency.currencyID,
                )
                for currency in currencies
            ]
        )
        self.session.commit()
        return proposition.propositionID

    def _create_prediction_demo(self, player_id: int, payload: dict, amount: Decimal) -> int:
        proposition = self.session.get(Proposition, int(payload["propositionId"]))
        if not proposition or proposition.predictionsDeadline <= datetime.utcnow():
            raise ValueError("La proposición no existe o ya cerró.")

        answer = "si" if str(payload["answer"]).lower() in {"yes", "si", "sí"} else "no"
        prediction_type = self.session.scalar(
            select(PredictionType).where(PredictionType.predictionTypeName == answer)
        )
        currency = self.session.scalar(
            select(Currency).where(
                Currency.currencyCode == str(payload["currencyCode"]).upper()
            )
        )
        if not prediction_type or not currency:
            raise ValueError("Tipo de pronóstico o moneda inválida.")
        allowed = self.session.get(
            PropositionPredictionCurrency,
            (proposition.propositionID, currency.currencyID),
        )
        if not allowed:
            raise ValueError("La proposición no permite pronósticos con esa moneda.")
        if currency.currencyCode == "POINT" and amount > 1:
            raise ValueError("El máximo permitido es 1 punto.")

        balance_model = Balance if currency.currencyCode == "POINT" else MoneyBalance
        balance = self.session.scalar(
            select(balance_model).where(
                balance_model.playerID == player_id,
                balance_model.currencyID == currency.currencyID,
            )
        )
        if not balance or balance.availableAmount < amount:
            raise ValueError("Saldo insuficiente.")

        now = datetime.utcnow()
        prediction = Prediction(
            propositionID=proposition.propositionID,
            playerID=player_id,
            predictionTypeID=prediction_type.predictionTypeID,
            predictionActive=True,
            checksum=hashlib.sha256(
                f"{player_id}-{proposition.propositionID}-{now.isoformat()}".encode()
            ).hexdigest().upper(),
            predictedAt=now,
            createdAt=now,
            isActive=True,
        )
        self.session.add(prediction)
        self.session.flush()
        self.session.add(
            PredictionStake(
                predictionID=prediction.predictionID,
                currencyID=currency.currencyID,
                amount=amount,
                createdAt=now,
                isActive=True,
            )
        )
        balance.availableAmount -= amount
        balance.reservedAmount += amount
        self.session.commit()
        return prediction.predictionID
