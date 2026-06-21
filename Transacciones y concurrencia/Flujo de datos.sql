/*Dlujo exitoso, y uno fallido*/

/*SP 1 crea una predicción*/

CREATE OR ALTER PROCEDURE dbo.usp_CreatePrediction
(
    @PlayerID BIGINT,
    @PropositionID BIGINT,
    @PredictionTypeID BIGINT,
    @CurrencyID BIGINT,
    @Amount DECIMAL(18,6)
)
AS
BEGIN

    SET XACT_ABORT ON;

    BEGIN TRY

        BEGIN TRAN;

        EXEC dbo.usp_ReserveStake
            @PlayerID,
            @CurrencyID,
            @Amount,
            @PropositionID;

        INSERT INTO dbo.predictions
        (
            propositionID,
            playerID,
            predictionTypeID,
            predictionActive,
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
            GETDATE(),
            GETDATE(),
            1
        );

        COMMIT;

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT > 0
            ROLLBACK;

        THROW;

    END CATCH
END
GO

/*SP 2 reserta reserva los datos de la apuesta*/
CREATE OR ALTER PROCEDURE dbo.usp_ReserveStake
(
    @PlayerID BIGINT,
    @CurrencyID BIGINT,
    @Amount DECIMAL(18,6),
    @PropositionID BIGINT
)
AS
BEGIN

    UPDATE dbo.balances
    SET availableAmount = availableAmount - @Amount,
        reservedAmount  = reservedAmount + @Amount
    WHERE playerID = @PlayerID
      AND currencyID = @CurrencyID
      AND isCurrent = 1;

    EXEC dbo.usp_ValidateProposition
         @PropositionID;
END
GO

/*SP 3 valida la proposición*/
CREATE OR ALTER PROCEDURE dbo.usp_ValidateProposition
(
    @PropositionID BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IsActive BIT;

    SELECT @IsActive = propositionActive
    FROM dbo.propositions
    WHERE propositionID = @PropositionID;

    IF @IsActive = 0
    BEGIN
        THROW 50001,
              'La proposición ya está cerrada.',
              1;
    END
END
GO

/*
Primero vamos a preparar los datos para saber con antelación que esperar */
UPDATE dbo.propositions
SET propositionActive = 1
WHERE propositionID = 1;

UPDATE dbo.balances
SET availableAmount = 100,
    reservedAmount = 0
WHERE playerID = 1
AND currencyID = 1;

/*para validar los datos nomas*/
SELECT availableAmount,reservedAmount
FROM dbo.balances
WHERE playerID = 1;

/*Ejecutamos el sp createprediction*/
EXEC dbo.usp_CreatePrediction
     @PlayerID = 1,
     @PropositionID = 1,
     @PredictionTypeID = 1,
     @CurrencyID = 1,
     @Amount = 10;

/*Validamos*/
SELECT availableAmount,reservedAmount
FROM dbo.balances
WHERE playerID = 1;

/*Validamos que la nueva prediccón existe*/
SELECT *
FROM dbo.predictions
WHERE playerID = 1
ORDER BY predictionID DESC;

/*Demostración fallida*/

/*Cambiamos la proposición a inactiava*/
UPDATE dbo.propositions
SET propositionActive = 0
WHERE propositionID = 1;

/*Y el saldo del jugador*/
UPDATE dbo.balances
SET availableAmount = 100,
    reservedAmount = 0
WHERE playerID = 1
AND currencyID = 1;

/*Se ejecuta*/
EXEC dbo.usp_CreatePrediction
     @PlayerID = 1,
     @PropositionID = 1,
     @PredictionTypeID = 1,
     @CurrencyID = 1,
     @Amount = 10;

/*Da error*/

/*Por la forma en que están escritos los sp, cuando el tercer sp da error, hace 
rollback de todo y no se efectua ningun cambio, ahora bien, los siguientes scripts
va a hacer exatemente lo mismo pero estos si van a guardar los datos cambiados
aunque el tercer sp va a dar error, ya que se va a eliminar la atomicidad de los sp
*/

/*SP 1*/
CREATE OR ALTER PROCEDURE dbo.usp_CreatePrediction
(
    @PlayerID BIGINT,
    @PropositionID BIGINT,
    @PredictionTypeID BIGINT,
    @CurrencyID BIGINT,
    @Amount DECIMAL(18,6)
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        EXEC dbo.usp_ReserveStake
            @PlayerID = @PlayerID,
            @CurrencyID = @CurrencyID,
            @Amount = @Amount,
            @PropositionID = @PropositionID;

        INSERT INTO dbo.predictions
        (
            propositionID,
            playerID,
            predictionTypeID,
            predictionActive,
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
            GETDATE(),
            GETDATE(),
            1
        );
    END TRY
    BEGIN CATCH
        PRINT 'Error en el flujo principal.';
        THROW;
    END CATCH
END
GO

/*SP 2*/
CREATE OR ALTER PROCEDURE dbo.usp_ReserveStake
(
    @PlayerID BIGINT,
    @CurrencyID BIGINT,
    @Amount DECIMAL(18,6),
    @PropositionID BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        UPDATE dbo.balances
        SET availableAmount = availableAmount - @Amount,
            reservedAmount  = reservedAmount + @Amount
        WHERE playerID = @PlayerID
          AND currencyID = @CurrencyID
          AND isCurrent = 1;

        EXEC dbo.usp_ValidateProposition
            @PropositionID = @PropositionID;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        THROW;
    END CATCH
END
GO

/*SP 3*/
CREATE OR ALTER PROCEDURE dbo.usp_ValidateProposition
(
    @PropositionID BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IsActive BIT;

    SELECT @IsActive = isActive
    FROM dbo.propositions
    WHERE propositionID = @PropositionID;

    IF @IsActive = 0
    BEGIN
        THROW 50001, 'La proposición ya está cerrada.', 1;
    END
END
GO

/*Datos*/

UPDATE dbo.balances
SET availableAmount = 100.000000,
    reservedAmount = 0.000000
WHERE playerID = 1
  AND currencyID = 1;

/*se cierra la proposición para forzar el error del SP3*/
UPDATE dbo.propositions
SET isActive = 0
WHERE propositionID = 1;

/*Ejecucion fallida*/
EXEC dbo.usp_CreatePrediction
    @PlayerID = 1,
    @PropositionID = 1,
    @PredictionTypeID = 1,
    @CurrencyID = 1,
    @Amount = 10.000000;

/*Validamos que los sp1 y 2 si guardaron los cambios*/
SELECT availableAmount, reservedAmount
FROM dbo.balances
WHERE playerID = 1
  AND currencyID = 1;

SELECT *
FROM dbo.predictions
WHERE playerID = 1
ORDER BY createdAt DESC;

