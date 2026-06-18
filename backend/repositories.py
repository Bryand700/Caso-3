from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from sqlalchemy import func, or_, select
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


def decimal_value(value: Decimal | None) -> float:
    return float(value or 0)


class GathelReadRepository:
    def __init__(self, session: Session):
        self.session = session

    def authenticate(self, identifier: str, password: str) -> Player | None:
        normalized = identifier.strip().lower().lstrip("@")
        player = self.session.scalar(
            select(Player).where(
                Player.isActive.is_(True),
                or_(
                    func.lower(Player.email) == normalized,
                    func.lower(Player.username) == normalized,
                ),
            )
        )
        if player and player.passwordHash == password:
            return player
        return None

    def player(self, player_id: int) -> Player | None:
        return self.session.get(Player, player_id)

    def players(self, search: str = "") -> list[dict]:
        statement = select(Player).where(Player.isActive.is_(True))
        if search:
            pattern = f"%{search.strip().lower().lstrip('@')}%"
            statement = statement.where(
                or_(
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

    def dashboard(self, player_id: int) -> dict:
        player = self.player(player_id)
        if not player:
            raise LookupError("Jugador no encontrado.")

        point_balance = self.session.execute(
            select(Balance.availableAmount)
            .join(Currency, Currency.currencyID == Balance.currencyID)
            .where(
                Balance.playerID == player_id,
                Balance.isCurrent.is_(True),
                Currency.currencyCode == "POINT",
            )
        ).scalar_one_or_none()

        money_balance = self.session.execute(
            select(MoneyBalance.availableAmount, Currency.currencyCode)
            .join(Currency, Currency.currencyID == MoneyBalance.currencyID)
            .where(
                MoneyBalance.playerID == player_id,
                MoneyBalance.isActive.is_(True),
                Currency.currencyCode == "USD",
            )
        ).first()

        active_predictions = self.session.scalar(
            select(func.count(Prediction.predictionID))
            .join(Proposition, Proposition.propositionID == Prediction.propositionID)
            .join(
                PropositionStatus,
                PropositionStatus.propositionStatusID == Proposition.propositionStatusID,
            )
            .where(
                Prediction.playerID == player_id,
                Prediction.isActive.is_(True),
                PropositionStatus.statusName == "activa",
            )
        )

        recent_transactions = self.session.execute(
            select(Transaction, Currency)
            .join(Currency, Currency.currencyID == Transaction.currencyID)
            .where(Transaction.playerID == player_id)
            .order_by(Transaction.transactionDate.desc())
            .limit(5)
        ).all()

        activities = [
            {
                "id": transaction.transactionID,
                "title": transaction.description or "Movimiento de balance",
                "detail": f"{decimal_value(transaction.amount):.2f} {currency.currencyCode}",
                "occurredAt": transaction.transactionDate.isoformat(),
            }
            for transaction, currency in recent_transactions
        ]

        return {
            "player": player_json(player),
            "balances": {
                "points": decimal_value(point_balance),
                "money": decimal_value(money_balance[0]) if money_balance else 0,
                "moneyCurrency": money_balance[1] if money_balance else "USD",
            },
            "activePredictions": int(active_predictions or 0),
            "activity": activities,
        }

    def active_propositions(self, search: str = "", limit: int = 100) -> list[dict]:
        target = aliased(Player)
        creator = aliased(Player)
        prediction_count = (
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
                func.coalesce(prediction_count.c.predictionCount, 0),
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
                prediction_count,
                prediction_count.c.propositionID == Proposition.propositionID,
            )
            .where(
                Proposition.isActive.is_(True),
                PropositionStatus.statusName == "activa",
            )
            .order_by(Proposition.predictionsDeadline)
            .limit(min(max(limit, 1), 200))
        )
        if search:
            pattern = f"%{search.strip().lower()}%"
            statement = statement.where(
                or_(
                    func.lower(Proposition.propositionText).like(pattern),
                    func.lower(target.username).like(pattern),
                    func.lower(target.firstName + " " + target.lastName).like(pattern),
                )
            )

        rows = self.session.execute(statement).all()
        result = []
        for proposition, target_player, creator_player, resource, resource_type, count in rows:
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
                    "target": player_json(target_player),
                    "creator": player_json(creator_player),
                    "deadline": proposition.predictionsDeadline.isoformat(),
                    "status": "active",
                    "currencies": currencies,
                    "predictionCount": int(count),
                    "resource": {
                        "type": resource_type.resourceTypeName,
                        "url": resource.contentURL,
                    },
                }
            )
        return result

    def results(self, player_id: int, limit: int = 100) -> list[dict]:
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
            .where(Prediction.playerID == player_id)
            .order_by(PredictionResult.determinedAt.desc())
            .limit(min(max(limit, 1), 200))
        ).all()

        return [
            {
                "id": proposition.propositionID,
                "title": proposition.propositionText,
                "fulfilled": proposition_result.propositionFulfilled,
                "prediction": prediction_type.predictionTypeName,
                "didWin": prediction_result.didWin,
                "stake": decimal_value(stake.amount),
                "currency": currency.currencyCode,
                "determinedAt": prediction_result.determinedAt.isoformat(),
            }
            for (
                proposition,
                proposition_result,
                prediction,
                prediction_type,
                stake,
                currency,
                prediction_result,
            ) in rows
        ]


def player_json(player: Player) -> dict:
    return {
        "id": player.playerID,
        "name": f"{player.firstName} {player.lastName}",
        "username": f"@{player.username}",
        "email": player.email,
        "initials": f"{player.firstName[:1]}{player.lastName[:1]}".upper(),
    }
