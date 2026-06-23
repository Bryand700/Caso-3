from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from sqlalchemy import func, or_ as orCondition, select
from sqlalchemy.orm import Session, aliased

from models import (
    Balance,
    Currency,
    MoneyBalance,
    Player,
    Prediction,
    PredictionResult,
    PredictionStake,
    PredictionType,
    Proposition,
    PropositionPredictionCurrency,
    PropositionResult,
    PropositionStatus,
    Resource,
    ResourceType,
    Transaction,
)


def decimalValue(value: Decimal | None) -> float:
    return float(value or 0)


class GathelReadRepository:
    def __init__(self, session: Session):
        self.session = session

    def authenticate(self, identifier: str, password: str) -> Player | None:
        normalized = identifier.strip().lower().lstrip("@")
        player = self.session.scalar(
            select(Player).where(
                Player.isActive == True,
                    orCondition(
                    func.lower(Player.email) == normalized,
                    func.lower(Player.username) == normalized,
                ),
            )
        )
        if player and player.passwordHash == password:
            return player
        return None

    def player(self, playerId: int) -> Player | None:
        return self.session.get(Player, playerId)

    def players(self, search: str = "") -> list[dict]:
        statement = select(Player).where(Player.isActive == True)
        if search:
            pattern = f"%{search.strip().lower().lstrip('@')}%"
            statement = statement.where(
                orCondition(
                    func.lower(Player.username).like(pattern),
                    func.lower(Player.firstName + " " + Player.lastName).like(pattern),
                )
            )
        rows = self.session.scalars(statement.order_by(Player.firstName).limit(50)).all()
        return [
            {
                "id": row.playerID,
                "name": f"{row.firstName} {row.lastName}",
                "username": f"@{row.username}",
            }
            for row in rows
        ]

    def dashboard(self, playerId: int) -> dict:
        player = self.player(playerId)
        if not player:
            raise LookupError("Jugador no encontrado.")

        pointBalance = self.session.execute(
            select(Balance.availableAmount)
            .join(Currency, Currency.currencyID == Balance.currencyID)
            .where(
                Balance.playerID == playerId,
                Balance.isCurrent == True,
                Currency.currencyCode == "POINT",
            )
        ).scalar_one_or_none()

        moneyBalance = self.session.execute(
            select(MoneyBalance.availableAmount, Currency.currencyCode)
            .join(Currency, Currency.currencyID == MoneyBalance.currencyID)
            .where(
                MoneyBalance.playerID == playerId,
                MoneyBalance.isActive == True,
                Currency.currencyCode == "USD",
            )
        ).first()

        activePredictions = self.session.scalar(
            select(func.count(Prediction.predictionID))
            .join(Proposition, Proposition.propositionID == Prediction.propositionID)
            .join(
                PropositionStatus,
                PropositionStatus.propositionStatusID == Proposition.propositionStatusID,
            )
            .where(
                Prediction.playerID == playerId,
                Prediction.isActive == True,
                PropositionStatus.statusName == "activa",
            )
        )

        recentTransactions = self.session.execute(
            select(Transaction, Currency)
            .join(Currency, Currency.currencyID == Transaction.currencyID)
            .where(Transaction.playerID == playerId)
            .order_by(Transaction.transactionDate.desc())
            .limit(5)
        ).all()

        activities = [
            {
                "id": transaction.transactionID,
                "title": transaction.description or "Movimiento de balance",
                "detail": f"{decimalValue(transaction.amount):.2f} {currency.currencyCode}",
                "occurredAt": transaction.transactionDate.isoformat(),
            }
            for transaction, currency in recentTransactions
        ]

        return {
            "player": playerJson(player),
            "balances": {
                "points": decimalValue(pointBalance),
                "money": decimalValue(moneyBalance[0]) if moneyBalance else 0,
                "moneyCurrency": moneyBalance[1] if moneyBalance else "USD",
            },
            "activePredictions": int(activePredictions or 0),
            "activity": activities,
        }

    def activePropositions(self, search: str = "", limit: int = 100) -> list[dict]:
        target = aliased(Player)
        creator = aliased(Player)
        predictionCount = (
            select(
                Prediction.propositionID.label("propositionID"),
                func.count(Prediction.predictionID).label("predictionCount"),
            )
            .group_by(Prediction.propositionID)
            .subquery()
        )

        statement = (
            select(
                Proposition,
                target,
                creator,
                Resource,
                ResourceType,
                func.coalesce(predictionCount.c.predictionCount, 0),
            )
            .join(target, target.playerID == Proposition.targetPlayerID)
            .join(creator, creator.playerID == Proposition.creatorPlayerID)
            .join(Resource, Resource.resourceID == Proposition.relatedResourceID)
            .join(ResourceType, ResourceType.resourceTypeID == Resource.resourceTypeID)
            .join(
                PropositionStatus,
                PropositionStatus.propositionStatusID == Proposition.propositionStatusID,
            )
            .outerjoin(
                predictionCount,
                predictionCount.c.propositionID == Proposition.propositionID,
            )
            .where(
                Proposition.isActive == True,
                PropositionStatus.statusName == "activa",
            )
            .order_by(Proposition.predictionsDeadline)
            .limit(min(max(limit, 1), 200))
        )
        if search:
            pattern = f"%{search.strip().lower()}%"
            statement = statement.where(
                orCondition(
                    func.lower(Proposition.propositionText).like(pattern),
                    func.lower(target.username).like(pattern),
                    func.lower(target.firstName + " " + target.lastName).like(pattern),
                )
            )

        rows = self.session.execute(statement).all()
        result = []
        for proposition, targetPlayer, creatorPlayer, resource, resourceType, count in rows:
            currencies = self.session.scalars(
                select(Currency.currencyCode)
                .join(
                    PropositionPredictionCurrency,
                    PropositionPredictionCurrency.currencyID == Currency.currencyID,
                )
                .where(
                    PropositionPredictionCurrency.propositionID == proposition.propositionID
                )
                .order_by(Currency.currencyID)
            ).all()
            result.append(
                {
                    "id": proposition.propositionID,
                    "title": proposition.propositionText,
                    "target": playerJson(targetPlayer),
                    "creator": playerJson(creatorPlayer),
                    "deadline": proposition.predictionsDeadline.isoformat(),
                    "status": "active",
                    "currencies": currencies,
                    "predictionCount": int(count),
                    "resource": {
                        "type": resourceType.resourceTypeName,
                        "url": resource.contentURL,
                    },
                }
            )
        return result

    def results(self, playerId: int, limit: int = 100) -> list[dict]:
        rows = self.session.execute(
            select(
                Proposition,
                PropositionResult,
                Prediction,
                PredictionType,
                PredictionStake,
                Currency,
                PredictionResult,
            )
            .join(Prediction, Prediction.propositionID == Proposition.propositionID)
            .join(PredictionType, PredictionType.predictionTypeID == Prediction.predictionTypeID)
            .join(PredictionStake, PredictionStake.predictionID == Prediction.predictionID)
            .join(Currency, Currency.currencyID == PredictionStake.currencyID)
            .join(PredictionResult, PredictionResult.predictionID == Prediction.predictionID)
            .join(
                PropositionResult,
                PropositionResult.propositionID == Proposition.propositionID,
            )
            .where(Prediction.playerID == playerId)
            .order_by(PredictionResult.determinedAt.desc())
            .limit(min(max(limit, 1), 200))
        ).all()

        return [
            {
                "id": proposition.propositionID,
                "title": proposition.propositionText,
                "fulfilled": propositionResult.propositionFulfilled,
                "prediction": predictionType.predictionTypeName,
                "didWin": predictionResult.didWin,
                "stake": decimalValue(stake.amount),
                "currency": currency.currencyCode,
                "determinedAt": predictionResult.determinedAt.isoformat(),
            }
            for (
                proposition,
                propositionResult,
                prediction,
                predictionType,
                stake,
                currency,
                predictionResult,
            ) in rows
        ]


def playerJson(player: Player) -> dict:
    return {
        "id": player.playerID,
        "name": f"{player.firstName} {player.lastName}",
        "username": f"@{player.username}",
        "email": player.email,
        "initials": f"{player.firstName[:1]}{player.lastName[:1]}".upper(),
    }
