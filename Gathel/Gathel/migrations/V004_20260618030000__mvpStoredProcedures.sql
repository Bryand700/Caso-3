/* ============================================================================
   GATHEL - Stored Procedures de escritura para el MVP
   Las lecturas son responsabilidad del ORM del REST API.
============================================================================ */

CREATE TABLE dbo.propositionPredictionCurrencies
(
    propositionID BIGINT NOT NULL,
    currencyID BIGINT NOT NULL,
    createdAt DATETIME2 NOT NULL
        CONSTRAINT DF_propositionPredictionCurrencies_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_propositionPredictionCurrencies
        PRIMARY KEY (propositionID, currencyID),
    CONSTRAINT FK_propositionPredictionCurrencies_propositions
        FOREIGN KEY (propositionID) REFERENCES dbo.propositions(propositionID),
    CONSTRAINT FK_propositionPredictionCurrencies_currencies
        FOREIGN KEY (currencyID) REFERENCES dbo.currencies(currencyID)
);
GO

/* Las proposiciones existentes del seeding aceptan puntos y USD para el MVP. */
INSERT dbo.propositionPredictionCurrencies (propositionID, currencyID)
SELECT p.propositionID, c.currencyID
FROM dbo.propositions p
CROSS JOIN dbo.currencies c
WHERE c.currencyCode IN (N'POINT', N'USD');
GO

CREATE OR ALTER PROCEDURE dbo.sp_CreateProposition
    @CreatorPlayerID BIGINT,
    @TargetPlayerID BIGINT,
    @PropositionText NVARCHAR(500),
    @ResourceTypeName NVARCHAR(50),
    @ContentURL NVARCHAR(500),
    @PredictionMode NVARCHAR(20) = N'BOTH'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NULLIF(LTRIM(RTRIM(@PropositionText)), N'') IS NULL
        THROW 50001, 'La proposición no puede estar vacía.', 1;

    IF NULLIF(LTRIM(RTRIM(@ContentURL)), N'') IS NULL
        THROW 50002, 'La URL del recurso es obligatoria.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.players WHERE playerID = @CreatorPlayerID AND isActive = 1)
        THROW 50003, 'El jugador creador no existe o está inactivo.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.players WHERE playerID = @TargetPlayerID AND isActive = 1)
        THROW 50004, 'El jugador asociado no existe o está inactivo.', 1;

    DECLARE @PlayerSocialNetworkID BIGINT;
    DECLARE @ResourceTypeID BIGINT;
    DECLARE @PendingStatusID BIGINT;
    DECLARE @ResourceID BIGINT;
    DECLARE @PropositionID BIGINT;
    DECLARE @PointCurrencyID BIGINT;
    DECLARE @UsdCurrencyID BIGINT;
    DECLARE @Now DATETIME2 = SYSUTCDATETIME();

    SELECT TOP (1) @PlayerSocialNetworkID = playerSocialNetworkID
    FROM dbo.playersSocialNetwork
    WHERE playerID = @TargetPlayerID
      AND isActive = 1
    ORDER BY isAuthorized DESC, playerSocialNetworkID;

    IF @PlayerSocialNetworkID IS NULL
        THROW 50005, 'El jugador asociado no tiene una red social activa.', 1;

    SELECT @ResourceTypeID = resourceTypeID
    FROM dbo.resourceTypes
    WHERE LOWER(resourceTypeName) = LOWER(@ResourceTypeName)
      AND isActive = 1;

    IF @ResourceTypeID IS NULL
        THROW 50006, 'El tipo de recurso no existe.', 1;

    SELECT @PendingStatusID = propositionStatusID
    FROM dbo.propositionStatus
    WHERE statusName = N'pendiente'
      AND isActive = 1;

    IF @PendingStatusID IS NULL
        THROW 50007, 'No existe el estado pendiente.', 1;

    SELECT @PointCurrencyID = currencyID
    FROM dbo.currencies
    WHERE currencyCode = N'POINT' AND isActive = 1;

    SELECT @UsdCurrencyID = currencyID
    FROM dbo.currencies
    WHERE currencyCode = N'USD' AND isActive = 1;

    SET @PredictionMode = UPPER(@PredictionMode);

    IF @PredictionMode NOT IN (N'POINT', N'USD', N'BOTH')
        THROW 50008, 'El modo de pronóstico no es válido.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT dbo.resources
        (
            playerSocialNetworkID,
            resourceTypeID,
            externalResourceID,
            contentURL,
            contentHash,
            capturedAt,
            eventOccurredAt,
            validationStatus,
            isActive,
            createdAt
        )
        VALUES
        (
            @PlayerSocialNetworkID,
            @ResourceTypeID,
            CONCAT(N'mvp-', CONVERT(NVARCHAR(36), NEWID())),
            @ContentURL,
            CONVERT(NVARCHAR(80), HASHBYTES('SHA2_256', @ContentURL), 2),
            @Now,
            NULL,
            N'pending',
            1,
            @Now
        );

        SET @ResourceID = SCOPE_IDENTITY();

        INSERT dbo.propositions
        (
            creatorPlayerID,
            targetPlayerID,
            relatedResourceID,
            propositionStatusID,
            propositionText,
            predictionsDeadline,
            votingDeadline,
            acceptedAt,
            closedAt,
            createdAt,
            isActive
        )
        VALUES
        (
            @CreatorPlayerID,
            @TargetPlayerID,
            @ResourceID,
            @PendingStatusID,
            LTRIM(RTRIM(@PropositionText)),
            DATEADD(DAY, 1, @Now),
            DATEADD(DAY, 3, @Now),
            @Now,
            DATEADD(DAY, 4, @Now),
            @Now,
            1
        );

        SET @PropositionID = SCOPE_IDENTITY();

        IF @PredictionMode IN (N'POINT', N'BOTH')
        BEGIN
            INSERT dbo.propositionPredictionCurrencies (propositionID, currencyID)
            VALUES (@PropositionID, @PointCurrencyID);
        END;

        IF @PredictionMode IN (N'USD', N'BOTH')
        BEGIN
            INSERT dbo.propositionPredictionCurrencies (propositionID, currencyID)
            VALUES (@PropositionID, @UsdCurrencyID);
        END;

        COMMIT TRANSACTION;

        SELECT
            @PropositionID AS propositionID,
            @ResourceID AS resourceID,
            N'pending' AS status,
            @PredictionMode AS predictionMode;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_CreatePrediction
    @PlayerID BIGINT,
    @PropositionID BIGINT,
    @PredictionTypeName NVARCHAR(50),
    @CurrencyCode NVARCHAR(20),
    @Amount DECIMAL(18,6)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Amount <= 0
        THROW 50101, 'El monto debe ser mayor que cero.', 1;

    DECLARE @PredictionTypeID BIGINT;
    DECLARE @CurrencyID BIGINT;
    DECLARE @PredictionID BIGINT;
    DECLARE @TransactionTypeID BIGINT;
    DECLARE @AvailableAmount DECIMAL(18,6);
    DECLARE @MaxAmount DECIMAL(18,6);
    DECLARE @Now DATETIME2 = SYSUTCDATETIME();

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.propositions p
        JOIN dbo.propositionStatus ps
          ON ps.propositionStatusID = p.propositionStatusID
        WHERE p.propositionID = @PropositionID
          AND p.isActive = 1
          AND ps.statusName = N'activa'
          AND p.predictionsDeadline >= @Now
    )
        THROW 50102, 'La proposición no existe, no está activa o ya cerró.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.predictions
        WHERE propositionID = @PropositionID
          AND playerID = @PlayerID
          AND isActive = 1
    )
        THROW 50103, 'El jugador ya tiene un pronóstico activo en esta proposición.', 1;

    SELECT @PredictionTypeID = predictionTypeID
    FROM dbo.predictionTypes
    WHERE LOWER(predictionTypeName) = LOWER(@PredictionTypeName)
      AND isActive = 1;

    SELECT @CurrencyID = currencyID
    FROM dbo.currencies
    WHERE UPPER(currencyCode) = UPPER(@CurrencyCode)
      AND isActive = 1;

    IF @PredictionTypeID IS NULL
        THROW 50104, 'El tipo de pronóstico no existe.', 1;

    IF @CurrencyID IS NULL
        THROW 50105, 'La moneda no existe.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.propositionPredictionCurrencies
        WHERE propositionID = @PropositionID
          AND currencyID = @CurrencyID
    )
        THROW 50108, 'La proposición no permite pronósticos con esa moneda.', 1;

    SELECT TOP (1) @MaxAmount = maxAmountPerPrediction
    FROM dbo.currencyConfigurations
    WHERE currencyID = @CurrencyID
      AND isCurrent = 1
      AND validFrom <= @Now
      AND (validTo IS NULL OR validTo >= @Now)
    ORDER BY validFrom DESC;

    IF @MaxAmount > 0 AND @Amount > @MaxAmount
        THROW 50106, 'El monto excede el máximo configurado para la moneda.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF UPPER(@CurrencyCode) = N'POINT'
        BEGIN
            SELECT @AvailableAmount = availableAmount
            FROM dbo.balances WITH (UPDLOCK)
            WHERE playerID = @PlayerID
              AND currencyID = @CurrencyID
              AND isCurrent = 1;
        END
        ELSE
        BEGIN
            SELECT @AvailableAmount = availableAmount
            FROM dbo.moneyBalance WITH (UPDLOCK)
            WHERE playerID = @PlayerID
              AND currencyID = @CurrencyID
              AND isActive = 1;
        END;

        IF @AvailableAmount IS NULL OR @AvailableAmount < @Amount
            THROW 50107, 'Saldo insuficiente.', 1;

        SELECT @TransactionTypeID = transactionTypeCodeID
        FROM dbo.transactionTypes
        WHERE typeName = N'Predicción'
          AND isActive = 1;

        INSERT dbo.predictions
        (
            propositionID,
            playerID,
            predictionTypeID,
            predictionActive,
            checksum,
            predictedAt,
            createdAt,
            isActive
        )
        VALUES
        (
            @PropositionID,
            @PlayerID,
            @PredictionTypeID,
            1,
            CONVERT(
                NVARCHAR(80),
                HASHBYTES(
                    'SHA2_256',
                    CONCAT(@PlayerID, N'-', @PropositionID, N'-', CONVERT(NVARCHAR(30), @Now, 126))
                ),
                2
            ),
            @Now,
            @Now,
            1
        );

        SET @PredictionID = SCOPE_IDENTITY();

        INSERT dbo.predictionStakes
        (
            predictionID,
            currencyID,
            amount,
            createdAt,
            isActive
        )
        VALUES
        (
            @PredictionID,
            @CurrencyID,
            @Amount,
            @Now,
            1
        );

        IF UPPER(@CurrencyCode) = N'POINT'
        BEGIN
            UPDATE dbo.balances
            SET
                availableAmount = availableAmount - @Amount,
                reservedAmount = reservedAmount + @Amount,
                updatedAt = @Now
            WHERE playerID = @PlayerID
              AND currencyID = @CurrencyID
              AND isCurrent = 1;
        END
        ELSE
        BEGIN
            UPDATE dbo.moneyBalance
            SET
                availableAmount = availableAmount - @Amount,
                reservedAmount = reservedAmount + @Amount
            WHERE playerID = @PlayerID
              AND currencyID = @CurrencyID
              AND isActive = 1;
        END;

        INSERT dbo.transactions
        (
            playerID,
            transactionTypeCodeID,
            propositionID,
            predictionID,
            currencyID,
            amount,
            balanceBefore,
            balanceAfter,
            description,
            checksum,
            transactionDate,
            createdAt
        )
        VALUES
        (
            @PlayerID,
            @TransactionTypeID,
            @PropositionID,
            @PredictionID,
            @CurrencyID,
            @Amount,
            @AvailableAmount,
            @AvailableAmount - @Amount,
            N'Reserva de balance para pronóstico',
            CONVERT(NVARCHAR(80), HASHBYTES('SHA2_256', CONCAT(N'tx-', @PredictionID)), 2),
            @Now,
            @Now
        );

        COMMIT TRANSACTION;

        SELECT
            @PredictionID AS predictionID,
            N'active' AS status;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
