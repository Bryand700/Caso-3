/*DEADLOCK de escritura*/

CREATE OR ALTER PROCEDURE dbo.usp_DeadlockWriteA
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRAN;

    UPDATE dbo.balances
    SET availableAmount = availableAmount - 1
    WHERE balanceID = 1;

    WAITFOR DELAY '00:00:05';

    UPDATE dbo.transactions
    SET description = 'A'
    WHERE transactionID = 1;

    COMMIT TRAN;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_DeadlockWriteB
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRAN;

    UPDATE dbo.transactions
    SET description = 'B'
    WHERE transactionID = 1;

    WAITFOR DELAY '00:00:05';

    UPDATE dbo.balances
    SET availableAmount = availableAmount - 1
    WHERE balanceID = 1;

    COMMIT TRAN;
END;
GO

/*DEADLOCK de lectura*/ 

CREATE OR ALTER PROCEDURE dbo.usp_DeadlockWriteA
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRAN;

    SELECT availableAmount
    FROM dbo.balances
    WHERE balanceID = 1;

    WAITFOR DELAY '00:00:05';

    UPDATE dbo.balances
    SET reservedAmount = reservedAmount + 10
    WHERE balanceID = 1;

    COMMIT TRAN;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_DeadlockWriteB
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRAN;

    UPDATE dbo.balances
    SET reservedAmount = reservedAmount * 10
    WHERE balanceID = 1;

    WAITFOR DELAY '00:00:05';

    SELECT availableAmount
    FROM dbo.balances
    WHERE balanceID = 1;

    COMMIT TRAN;
END;
GO