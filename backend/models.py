from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from sqlalchemy import BigInteger, Boolean, DateTime, ForeignKey, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column

from database import Base

identityType = BigInteger()


class Player(Base):
    __tablename__ = "players"

    playerID: Mapped[int] = mapped_column(identityType, primary_key=True, autoincrement=True)
    countryID: Mapped[int] = mapped_column(BigInteger)
    email: Mapped[str] = mapped_column(String(150), unique=True)
    username: Mapped[str] = mapped_column(String(50), unique=True)
    firstName: Mapped[str] = mapped_column(String(40))
    lastName: Mapped[str] = mapped_column(String(40))
    secondLastName: Mapped[str | None] = mapped_column(String(40), nullable=True)
    passwordHash: Mapped[str] = mapped_column(String(255))
    isEmailVerified: Mapped[bool] = mapped_column(Boolean, default=False)
    isActive: Mapped[bool] = mapped_column(Boolean, default=True)
    lastLoginAt: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    createdAt: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updatedAt: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class Currency(Base):
    __tablename__ = "currencies"

    currencyID: Mapped[int] = mapped_column(identityType, primary_key=True, autoincrement=True)
    currencyCode: Mapped[str] = mapped_column(String(20), unique=True)
    currencyName: Mapped[str] = mapped_column(String(45))
    currencySymbol: Mapped[str] = mapped_column(String(30))
    isActive: Mapped[bool] = mapped_column(Boolean, default=True)
    createdAt: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updatedAt: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class Balance(Base):
    __tablename__ = "balances"

    balanceID: Mapped[int] = mapped_column(identityType, primary_key=True, autoincrement=True)
    playerID: Mapped[int] = mapped_column(BigInteger, ForeignKey("players.playerID"))
    currencyID: Mapped[int] = mapped_column(BigInteger, ForeignKey("currencies.currencyID"))
    availableAmount: Mapped[Decimal] = mapped_column(Numeric(18, 6))
    reservedAmount: Mapped[Decimal] = mapped_column(Numeric(18, 6))
    totalAmountEarned: Mapped[Decimal] = mapped_column(Numeric(18, 6))
    totalAmountSpent: Mapped[Decimal] = mapped_column(Numeric(18, 6))
    createdAt: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updatedAt: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    isCurrent: Mapped[bool] = mapped_column(Boolean, default=True)


class MoneyBalance(Base):
    __tablename__ = "moneyBalance"

    moneyBalanceID: Mapped[int] = mapped_column(identityType, primary_key=True, autoincrement=True)
    playerID: Mapped[int] = mapped_column(BigInteger, ForeignKey("players.playerID"))
    currencyID: Mapped[int] = mapped_column(BigInteger, ForeignKey("currencies.currencyID"))
    availableAmount: Mapped[Decimal] = mapped_column(Numeric(18, 6))
    reservedAmount: Mapped[Decimal] = mapped_column(Numeric(18, 6))
    totalDeposited: Mapped[Decimal] = mapped_column(Numeric(18, 6))
    totalWithdrawn: Mapped[Decimal] = mapped_column(Numeric(18, 6))
    createdAt: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    validUntil: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    isActive: Mapped[bool] = mapped_column(Boolean, default=True)


class PropositionStatus(Base):
    __tablename__ = "propositionStatus"

    propositionStatusID: Mapped[int] = mapped_column(identityType, primary_key=True, autoincrement=True)
    statusName: Mapped[str] = mapped_column(String(50), unique=True)
    statusDescription: Mapped[str] = mapped_column(String(150))
    isActive: Mapped[bool] = mapped_column(Boolean, default=True)
    createdAt: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class ResourceType(Base):
    __tablename__ = "resourceTypes"

    resourceTypeID: Mapped[int] = mapped_column(identityType, primary_key=True, autoincrement=True)
    resourceTypeName: Mapped[str] = mapped_column(String(50), unique=True)
    resourceTypeDescription: Mapped[str] = mapped_column(String(150))
    isActive: Mapped[bool] = mapped_column(Boolean, default=True)
    createdAt: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class PlayerSocialNetwork(Base):
    __tablename__ = "playersSocialNetwork"

    playerSocialNetworkID: Mapped[int] = mapped_column(identityType, primary_key=True, autoincrement=True)
    playerID: Mapped[int] = mapped_column(BigInteger, ForeignKey("players.playerID"))
    socialNetworkID: Mapped[int] = mapped_column(BigInteger)
    externalAccountID: Mapped[str] = mapped_column(String(150))
    externalUsername: Mapped[str] = mapped_column(String(100))
    isAuthorized: Mapped[bool] = mapped_column(Boolean, default=False)
    isActive: Mapped[bool] = mapped_column(Boolean, default=True)
    linkedAt: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    createdAt: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updatedAt: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class Resource(Base):
    __tablename__ = "resources"

    resourceID: Mapped[int] = mapped_column(identityType, primary_key=True, autoincrement=True)
    playerSocialNetworkID: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("playersSocialNetwork.playerSocialNetworkID")
    )
    resourceTypeID: Mapped[int] = mapped_column(BigInteger, ForeignKey("resourceTypes.resourceTypeID"))
    externalResourceID: Mapped[str] = mapped_column(String(150))
    contentURL: Mapped[str] = mapped_column(String(500))
    contentHash: Mapped[str] = mapped_column(String(80))
    capturedAt: Mapped[datetime] = mapped_column(DateTime)
    eventOccurredAt: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    validationStatus: Mapped[str] = mapped_column(String(30), default="pending")
    isActive: Mapped[bool] = mapped_column(Boolean, default=True)
    createdAt: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updatedAt: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class Proposition(Base):
    __tablename__ = "propositions"

    propositionID: Mapped[int] = mapped_column(identityType, primary_key=True, autoincrement=True)
    creatorPlayerID: Mapped[int] = mapped_column(BigInteger, ForeignKey("players.playerID"))
    targetPlayerID: Mapped[int] = mapped_column(BigInteger, ForeignKey("players.playerID"))
    relatedResourceID: Mapped[int] = mapped_column(BigInteger, ForeignKey("resources.resourceID"))
    propositionStatusID: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("propositionStatus.propositionStatusID")
    )
    propositionText: Mapped[str] = mapped_column(String(500))
    predictionsDeadline: Mapped[datetime] = mapped_column(DateTime)
    votingDeadline: Mapped[datetime] = mapped_column(DateTime)
    acceptedAt: Mapped[datetime] = mapped_column(DateTime)
    closedAt: Mapped[datetime] = mapped_column(DateTime)
    createdAt: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updatedAt: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    isActive: Mapped[bool] = mapped_column(Boolean, default=True)


class PropositionPredictionCurrency(Base):
    __tablename__ = "propositionPredictionCurrencies"

    propositionID: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("propositions.propositionID"),
        primary_key=True,
    )
    currencyID: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("currencies.currencyID"),
        primary_key=True,
    )
    createdAt: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class PredictionType(Base):
    __tablename__ = "predictionTypes"

    predictionTypeID: Mapped[int] = mapped_column(identityType, primary_key=True, autoincrement=True)
    predictionTypeName: Mapped[str] = mapped_column(String(50), unique=True)
    predictionTypeDescription: Mapped[str] = mapped_column(String(150))
    isActive: Mapped[bool] = mapped_column(Boolean, default=True)
    createdAt: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Prediction(Base):
    __tablename__ = "predictions"

    predictionID: Mapped[int] = mapped_column(identityType, primary_key=True, autoincrement=True)
    propositionID: Mapped[int] = mapped_column(BigInteger, ForeignKey("propositions.propositionID"))
    playerID: Mapped[int] = mapped_column(BigInteger, ForeignKey("players.playerID"))
    predictionTypeID: Mapped[int] = mapped_column(BigInteger, ForeignKey("predictionTypes.predictionTypeID"))
    predictionActive: Mapped[bool] = mapped_column(Boolean, default=True)
    checksum: Mapped[str | None] = mapped_column(String(80), nullable=True)
    predictedAt: Mapped[datetime] = mapped_column(DateTime)
    createdAt: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updatedAt: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    isActive: Mapped[bool] = mapped_column(Boolean, default=True)


class PredictionStake(Base):
    __tablename__ = "predictionStakes"

    predictionStakeID: Mapped[int] = mapped_column(identityType, primary_key=True, autoincrement=True)
    predictionID: Mapped[int] = mapped_column(BigInteger, ForeignKey("predictions.predictionID"))
    currencyID: Mapped[int] = mapped_column(BigInteger, ForeignKey("currencies.currencyID"))
    amount: Mapped[Decimal] = mapped_column(Numeric(18, 6))
    createdAt: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updatedAt: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    isActive: Mapped[bool] = mapped_column(Boolean, default=True)


class PredictionResult(Base):
    __tablename__ = "predictionResults"

    predictionResultID: Mapped[int] = mapped_column(identityType, primary_key=True, autoincrement=True)
    predictionID: Mapped[int] = mapped_column(BigInteger, ForeignKey("predictions.predictionID"))
    didWin: Mapped[bool] = mapped_column(Boolean)
    determinedAt: Mapped[datetime] = mapped_column(DateTime)
    createdAt: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updatedAt: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    isActive: Mapped[bool] = mapped_column(Boolean, default=True)


class PropositionResult(Base):
    __tablename__ = "propositionResult"

    propositionResultID: Mapped[int] = mapped_column(identityType, primary_key=True, autoincrement=True)
    propositionID: Mapped[int] = mapped_column(BigInteger, ForeignKey("propositions.propositionID"))
    resultTypeID: Mapped[int] = mapped_column(BigInteger)
    propositionFulfilled: Mapped[bool | None] = mapped_column(Boolean, nullable=True)
    evidenceResourceID: Mapped[int] = mapped_column(BigInteger, ForeignKey("resources.resourceID"))
    validatedAt: Mapped[datetime] = mapped_column(DateTime)
    createdAt: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updatedAt: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    isActive: Mapped[bool] = mapped_column(Boolean, default=True)


class Transaction(Base):
    __tablename__ = "transactions"

    transactionID: Mapped[int] = mapped_column(identityType, primary_key=True, autoincrement=True)
    playerID: Mapped[int] = mapped_column(BigInteger, ForeignKey("players.playerID"))
    transactionTypeCodeID: Mapped[int] = mapped_column(BigInteger)
    propositionID: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    predictionID: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    currencyID: Mapped[int] = mapped_column(BigInteger, ForeignKey("currencies.currencyID"))
    amount: Mapped[Decimal] = mapped_column(Numeric(18, 6))
    balanceBefore: Mapped[Decimal] = mapped_column(Numeric(18, 6))
    balanceAfter: Mapped[Decimal] = mapped_column(Numeric(18, 6))
    description: Mapped[str | None] = mapped_column(String(200), nullable=True)
    checksum: Mapped[str] = mapped_column(String(80))
    transactionDate: Mapped[datetime] = mapped_column(DateTime)
    createdAt: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
