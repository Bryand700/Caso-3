from __future__ import annotations

import hashlib
from datetime import datetime, timedelta
from decimal import Decimal

from sqlalchemy import func, select

from database import Base, engine, session_scope
from models import (
    Balance,
    Currency,
    MoneyBalance,
    Player,
    PlayerSocialNetwork,
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


def initialize_demo_database() -> None:
    Base.metadata.create_all(engine)

    with session_scope() as session:
        if session.scalar(select(func.count(Player.playerID))) > 0:
            return

        now = datetime.utcnow()
        currencies = [
            Currency(currencyID=1, currencyCode="POINT", currencyName="Puntos Gathel", currencySymbol="pts"),
            Currency(currencyID=2, currencyCode="USD", currencyName="US Dollar", currencySymbol="$"),
        ]
        statuses = [
            PropositionStatus(
                propositionStatusID=1,
                statusName="pendiente",
                statusDescription="Pendiente de proceso externo",
            ),
            PropositionStatus(
                propositionStatusID=2,
                statusName="activa",
                statusDescription="Acepta pronósticos",
            ),
            PropositionStatus(
                propositionStatusID=3,
                statusName="finalizada",
                statusDescription="Resultado disponible",
            ),
        ]
        resource_types = [
            ResourceType(resourceTypeID=1, resourceTypeName="post", resourceTypeDescription="Publicación"),
            ResourceType(resourceTypeID=2, resourceTypeName="story", resourceTypeDescription="Historia"),
            ResourceType(resourceTypeID=3, resourceTypeName="reel", resourceTypeDescription="Reel"),
            ResourceType(resourceTypeID=4, resourceTypeName="video", resourceTypeDescription="Video"),
        ]
        prediction_types = [
            PredictionType(
                predictionTypeID=1,
                predictionTypeName="si",
                predictionTypeDescription="Sí se cumplirá",
            ),
            PredictionType(
                predictionTypeID=2,
                predictionTypeName="no",
                predictionTypeDescription="No se cumplirá",
            ),
        ]
        session.add_all(currencies + statuses + resource_types + prediction_types)

        names = [
            ("Daniela", "Mora", "danimora", "daniela@gathel.local"),
            ("Sofía", "Rojas", "sofiaruns", "sofia@gathel.local"),
            ("Andrés", "Solís", "andresolis", "andres@gathel.local"),
            ("Valeria", "Castro", "valecastro", "valeria@gathel.local"),
            ("Mateo", "Herrera", "mateoh", "mateo@gathel.local"),
            ("Laura", "Jiménez", "lauraj", "laura@gathel.local"),
            ("Diego", "Chaves", "diegococina", "diego@gathel.local"),
        ]

        for player_id, (first, last, username, email) in enumerate(names, start=1):
            player = Player(
                playerID=player_id,
                countryID=1,
                email=email,
                username=username,
                firstName=first,
                lastName=last,
                passwordHash="DemoGathel2026",
                isEmailVerified=True,
                isActive=True,
                createdAt=now - timedelta(days=90),
            )
            session.add(player)
            session.add(
                PlayerSocialNetwork(
                    playerSocialNetworkID=player_id,
                    playerID=player_id,
                    socialNetworkID=1,
                    externalAccountID=f"demo_{player_id}",
                    externalUsername=username,
                    isAuthorized=True,
                    isActive=True,
                    linkedAt=now - timedelta(days=60),
                    createdAt=now - timedelta(days=60),
                )
            )
            session.add(
                Balance(
                    playerID=player_id,
                    currencyID=1,
                    availableAmount=Decimal("184.00") if player_id == 1 else Decimal("100.00"),
                    reservedAmount=Decimal("0"),
                    totalAmountEarned=Decimal("24.40"),
                    totalAmountSpent=Decimal("6.00"),
                    isCurrent=True,
                )
            )
            session.add(
                Balance(
                    playerID=player_id,
                    currencyID=2,
                    availableAmount=Decimal("72.45") if player_id == 1 else Decimal("40.00"),
                    reservedAmount=Decimal("0"),
                    totalAmountEarned=Decimal("25.00"),
                    totalAmountSpent=Decimal("0"),
                    isCurrent=True,
                )
            )
            session.add(
                MoneyBalance(
                    playerID=player_id,
                    currencyID=2,
                    availableAmount=Decimal("72.45") if player_id == 1 else Decimal("40.00"),
                    reservedAmount=Decimal("0"),
                    totalDeposited=Decimal("100.00"),
                    totalWithdrawn=Decimal("27.55"),
                    isActive=True,
                )
            )

        titles = [
            "Sofía terminará la media maratón en menos de 2 horas",
            "Andrés publicará su primera canción antes del viernes",
            "Valeria llegará a la cima del Cerro Chirripó este fin de semana",
            "Mateo completará 30 días consecutivos de entrenamiento",
            "Laura presentará su nuevo emprendimiento durante junio",
            "Diego cocinará una receta completa en transmisión en vivo",
        ]

        for index, title in enumerate(titles, start=1):
            target_id = index + 1
            resource = Resource(
                resourceID=index,
                playerSocialNetworkID=target_id,
                resourceTypeID=((index - 1) % 4) + 1,
                externalResourceID=f"demo-resource-{index}",
                contentURL=f"https://social.example/resource/{index}",
                contentHash=hashlib.sha256(title.encode()).hexdigest().upper(),
                capturedAt=now - timedelta(days=1),
                validationStatus="pending",
                isActive=True,
            )
            session.add(resource)
            session.add(
                Proposition(
                    propositionID=index,
                    creatorPlayerID=1 if index % 2 else 2,
                    targetPlayerID=target_id,
                    relatedResourceID=index,
                    propositionStatusID=2,
                    propositionText=title,
                    predictionsDeadline=now + timedelta(hours=6 + index * 9),
                    votingDeadline=now + timedelta(days=5 + index),
                    acceptedAt=now - timedelta(days=1),
                    closedAt=now + timedelta(days=6 + index),
                    createdAt=now - timedelta(days=2),
                    isActive=True,
                )
            )
            session.add_all(
                [
                    PropositionPredictionCurrency(propositionID=index, currencyID=1),
                    PropositionPredictionCurrency(propositionID=index, currencyID=2),
                ]
            )

        finished_titles = [
            "Camila completará su primera carrera de 10 km",
            "Javier publicará el episodio 20 de su podcast",
            "María alcanzará 5 000 seguidores durante mayo",
        ]
        for offset, title in enumerate(finished_titles, start=7):
            resource = Resource(
                resourceID=offset,
                playerSocialNetworkID=2,
                resourceTypeID=1,
                externalResourceID=f"finished-resource-{offset}",
                contentURL=f"https://social.example/resource/{offset}",
                contentHash=hashlib.sha256(title.encode()).hexdigest().upper(),
                capturedAt=now - timedelta(days=offset),
                eventOccurredAt=now - timedelta(days=offset - 1),
                validationStatus="validated",
                isActive=True,
            )
            proposition = Proposition(
                propositionID=offset,
                creatorPlayerID=2,
                targetPlayerID=2,
                relatedResourceID=offset,
                propositionStatusID=3,
                propositionText=title,
                predictionsDeadline=now - timedelta(days=offset),
                votingDeadline=now - timedelta(days=offset - 1),
                acceptedAt=now - timedelta(days=offset + 2),
                closedAt=now - timedelta(days=offset - 1),
                createdAt=now - timedelta(days=offset + 3),
                isActive=True,
            )
            prediction = Prediction(
                predictionID=offset,
                propositionID=offset,
                playerID=1,
                predictionTypeID=1,
                predictionActive=False,
                checksum=hashlib.sha256(f"prediction-{offset}".encode()).hexdigest().upper(),
                predictedAt=now - timedelta(days=offset + 1),
                createdAt=now - timedelta(days=offset + 1),
                isActive=True,
            )
            session.add_all([resource, proposition, prediction])
            session.add(
                PropositionPredictionCurrency(
                    propositionID=offset,
                    currencyID=1 if offset != 8 else 2,
                )
            )
            session.add(
                PredictionStake(
                    predictionID=offset,
                    currencyID=1 if offset != 8 else 2,
                    amount=Decimal("1") if offset != 8 else Decimal("8"),
                    isActive=True,
                )
            )
            won = offset != 8
            session.add(
                PredictionResult(
                    predictionID=offset,
                    didWin=won,
                    determinedAt=now - timedelta(days=offset - 1),
                    isActive=True,
                )
            )
            session.add(
                PropositionResult(
                    propositionID=offset,
                    resultTypeID=1 if won else 2,
                    propositionFulfilled=won,
                    evidenceResourceID=offset,
                    validatedAt=now - timedelta(days=offset - 1),
                    isActive=True,
                )
            )

        session.add(
            Transaction(
                playerID=1,
                transactionTypeCodeID=2,
                propositionID=7,
                predictionID=7,
                currencyID=1,
                amount=Decimal("2.40"),
                balanceBefore=Decimal("181.60"),
                balanceAfter=Decimal("184.00"),
                description="Premio por pronóstico acertado",
                checksum="DEMO-TX-1",
                transactionDate=now - timedelta(hours=2),
            )
        )
        session.commit()
