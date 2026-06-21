/* ============================================================================
   GATHEL — Seeding · SQL Server 2022
   Archivo:  V002_20260618004000__seeding.sql
   Requiere: V001_20260618004000__creacionDB.sql actualizada y aplicada.
   Login de demo: la contraseña de cada jugador es Palabra+Palabra+3 dígitos
   (ej. 'TigreLuna473'), guardada en texto en passwordHash.
============================================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'dbo.propositionPredictionCurrencies', N'U') IS NULL
BEGIN
    THROW 51000, 'Falta dbo.propositionPredictionCurrencies. Ejecute primero la versión actualizada de V001.', 1;
END;

IF EXISTS (SELECT 1 FROM dbo.players)
BEGIN
    PRINT 'Seeding omitido: la base ya contiene datos.';
    RETURN;
END;

DECLARE @seedNow       DATETIME2 = SYSUTCDATETIME();
/* Las cuentas se distribuyen entre 545 y 180 días atrás, de modo que todos
   los jugadores existan antes de cualquier proposición generada. */
DECLARE @anchorPlayers DATETIME2 = DATEADD(DAY, -545, @seedNow);
DECLARE @anchorProps   DATETIME2 = DATEADD(DAY, -180, @seedNow);

/* Tally table local para no depender de GENERATE_SERIES ni del compatibility level 160. */
CREATE TABLE #Numbers (value INT NOT NULL PRIMARY KEY);
WITH
E1(N) AS (SELECT 1 FROM (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d(n)),
E2(N) AS (SELECT 1 FROM E1 a CROSS JOIN E1 b),
E4(N) AS (SELECT 1 FROM E2 a CROSS JOIN E2 b),
E8(N) AS (SELECT 1 FROM E4 a CROSS JOIN E4 b)
INSERT #Numbers(value)
SELECT TOP (250000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
FROM E8;

BEGIN TRY
    BEGIN TRANSACTION;

/* ====== SECCIÓN 1 · CATÁLOGOS BASE ====== */

SET IDENTITY_INSERT dbo.currencies ON;
INSERT dbo.currencies (currencyID, currencyCode, currencyName, currencySymbol, isActive, createdAt) VALUES
 (1, N'POINT', N'Puntos Gathel',       N'pts', 1, SYSUTCDATETIME()),
 (2, N'USD',   N'US Dollar',           N'$',   1, SYSUTCDATETIME()),
 (3, N'EUR',   N'Euro',                N'€',   1, SYSUTCDATETIME()),
 (4, N'CRC',   N'Colón costarricense', N'₡',   1, SYSUTCDATETIME()),
 (5, N'MXN',   N'Peso mexicano',       N'$',   1, SYSUTCDATETIME()),
 (6, N'ARS',   N'Peso argentino',      N'$',   1, SYSUTCDATETIME()),
 (7, N'COP',   N'Peso colombiano',     N'$',   1, SYSUTCDATETIME()),
 (8, N'CLP',   N'Peso chileno',        N'$',   1, SYSUTCDATETIME()),
 (9, N'PEN',   N'Sol peruano',         N'S/',  1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.currencies OFF;

SET IDENTITY_INSERT dbo.countries ON;
INSERT dbo.countries (countryID, countryName, iso2Code, iso3Code, localCurrencyID, isActive, createdAt) VALUES
 (1, N'Costa Rica',     'CR','CRI', 4, 1, SYSUTCDATETIME()),
 (2, N'Estados Unidos', 'US','USA', 2, 1, SYSUTCDATETIME()),
 (3, N'México',         'MX','MEX', 5, 1, SYSUTCDATETIME()),
 (4, N'España',         'ES','ESP', 3, 1, SYSUTCDATETIME()),
 (5, N'Argentina',      'AR','ARG', 6, 1, SYSUTCDATETIME()),
 (6, N'Colombia',       'CO','COL', 7, 1, SYSUTCDATETIME()),
 (7, N'Chile',          'CL','CHL', 8, 1, SYSUTCDATETIME()),
 (8, N'Perú',           'PE','PER', 9, 1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.countries OFF;

SET IDENTITY_INSERT dbo.userRoles ON;
INSERT dbo.userRoles (userRoleID, roleName, roleDescription, isActive, createdAt) VALUES
 (1, N'player',    N'Jugador estándar',       1, SYSUTCDATETIME()),
 (2, N'admin',     N'Administrador',          1, SYSUTCDATETIME()),
 (3, N'moderator', N'Moderador de contenido', 1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.userRoles OFF;

SET IDENTITY_INSERT dbo.permissions ON;
INSERT dbo.permissions (permissionID, permissionName, permissionDescription, isActive, createdAt) VALUES
 (1, N'proposition.create', N'Crear proposiciones',   1, SYSUTCDATETIME()),
 (2, N'prediction.create',  N'Realizar predicciones', 1, SYSUTCDATETIME()),
 (3, N'user.manage',        N'Gestionar usuarios',    1, SYSUTCDATETIME()),
 (4, N'content.moderate',   N'Moderar contenido',     1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.permissions OFF;

INSERT dbo.rolePermissions (userRoleID, permissionID, createdAt) VALUES
 (1,1,SYSUTCDATETIME()),(1,2,SYSUTCDATETIME()),
 (2,1,SYSUTCDATETIME()),(2,2,SYSUTCDATETIME()),(2,3,SYSUTCDATETIME()),(2,4,SYSUTCDATETIME()),
 (3,4,SYSUTCDATETIME());

SET IDENTITY_INSERT dbo.transactionTypes ON;
INSERT dbo.transactionTypes (transactionTypeCodeID, typeName, typeDescription, isActive, createdAt) VALUES
 (1, N'Predicción',   N'Reserva por predicción',         1, SYSUTCDATETIME()),
 (2, N'Premio',       N'Pago a ganador',                 1, SYSUTCDATETIME()),
 (3, N'Depósito',     N'Ingreso de dinero real',         1, SYSUTCDATETIME()),
 (4, N'Retiro',       N'Retiro de dinero real',          1, SYSUTCDATETIME()),
 (5, N'Comisión',     N'Comisión plataforma/proponente', 1, SYSUTCDATETIME()),
 (6, N'Penalización', N'Penalización por no validación', 1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.transactionTypes OFF;

SET IDENTITY_INSERT dbo.propositionStatus ON;
INSERT dbo.propositionStatus (propositionStatusID, statusName, statusDescription, isActive, createdAt) VALUES
 (1, N'pendiente',  N'Esperando aceptación del objetivo', 1, SYSUTCDATETIME()),
 (2, N'activa',     N'Aceptada, admite predicciones',     1, SYSUTCDATETIME()),
 (3, N'finalizada', N'Validada y liquidada',              1, SYSUTCDATETIME()),
 (4, N'rechazada',  N'Rechazada por el objetivo',         1, SYSUTCDATETIME()),
 (5, N'cerrada',    N'Cerrada sin predicciones',          1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.propositionStatus OFF;

SET IDENTITY_INSERT dbo.predictionTypes ON;
INSERT dbo.predictionTypes (predictionTypeID, predictionTypeName, predictionTypeDescription, isActive, createdAt) VALUES
 (1, N'si', N'Predice que la proposición SÍ se cumplirá', 1, SYSUTCDATETIME()),
 (2, N'no', N'Predice que la proposición NO se cumplirá', 1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.predictionTypes OFF;

SET IDENTITY_INSERT dbo.propositionVoteTypes ON;
INSERT dbo.propositionVoteTypes (propositionVoteTypeID, voteTypeName, voteTypeDescription, voteValue, isActive, createdAt) VALUES
 (1, N'pasa',      N'El votante considera que la proposición sí pasa o se cumplió', 1,    1, SYSUTCDATETIME()),
 (2, N'no_pasa',   N'El votante considera que la proposición no pasa o no se cumplió', 0, 1, SYSUTCDATETIME()),
 (3, N'abstencion',N'El votante no emite una decisión afirmativa ni negativa', NULL,     1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.propositionVoteTypes OFF;

SET IDENTITY_INSERT dbo.propositionResultTypes ON;
INSERT dbo.propositionResultTypes (resultTypeID, statusName, statusDescription, isActive, createdAt) VALUES
 (1, N'cumplida',     N'La proposición se cumplió',       1, SYSUTCDATETIME()),
 (2, N'no_cumplida',  N'La proposición no se cumplió',    1, SYSUTCDATETIME()),
 (3, N'no_validable', N'No se pudo validar el resultado', 1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.propositionResultTypes OFF;

SET IDENTITY_INSERT dbo.settlementStatusTypes ON;
INSERT dbo.settlementStatusTypes (settlementStatusTypeID, settlementStatusName) VALUES
 (1, N'pendiente'), (2, N'pagado'), (3, N'revertido');
SET IDENTITY_INSERT dbo.settlementStatusTypes OFF;

SET IDENTITY_INSERT dbo.paymentTransactionsStatus ON;
INSERT dbo.paymentTransactionsStatus (statusCodeID, statusName, statusDescription, isActive, createdAt) VALUES
 (1, N'pending',   N'En proceso', 1, SYSUTCDATETIME()),
 (2, N'completed', N'Completado', 1, SYSUTCDATETIME()),
 (3, N'failed',    N'Fallido',    1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.paymentTransactionsStatus OFF;

SET IDENTITY_INSERT dbo.paymentOperationTypes ON;
INSERT dbo.paymentOperationTypes (operationTypeCodeID, operationTypeName, operationTypeDescription, isActive, createdAt) VALUES
 (1, N'deposit',    N'Depósito',    1, SYSUTCDATETIME()),
 (2, N'withdrawal', N'Retiro',      1, SYSUTCDATETIME()),
 (3, N'fee',        N'Comisión',    1, SYSUTCDATETIME()),
 (4, N'payout',     N'Pago premio', 1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.paymentOperationTypes OFF;

SET IDENTITY_INSERT dbo.providers ON;
INSERT dbo.providers (providerID, providerName, providerDescription, isActive) VALUES
 (1, N'Stripe', N'Procesador de tarjetas', 1),
 (2, N'PayPal', N'Billetera digital',      1);
SET IDENTITY_INSERT dbo.providers OFF;

SET IDENTITY_INSERT dbo.paymentMethods ON;
INSERT dbo.paymentMethods (paymentMethodID, providerID, methodName, methodDescription, apiURL, config, isActive, createdAt) VALUES
 (1, 1, N'Tarjeta',   N'Débito/Crédito vía Stripe', N'https://api.stripe.com/v1', N'{"mode":"test"}', 1, SYSUTCDATETIME()),
 (2, 2, N'Billetera', N'Saldo PayPal',              N'https://api.paypal.com/v2', N'{"mode":"test"}', 1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.paymentMethods OFF;

/* Exchange rates completos: todos los pares dirigidos entre las monedas registradas.
   La tasa se calcula usando USD como moneda puente, pero se guarda cada par directo
   para facilitar pruebas de conversión sin depender de lógica inversa en la app. */
SET IDENTITY_INSERT dbo.exchangePairs ON;
WITH pairs AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY b.currencyID, q.currencyID) AS exchangePairID,
        b.currencyID AS baseCurrencyID,
        q.currencyID AS quoteCurrencyID
    FROM dbo.currencies b
    CROSS JOIN dbo.currencies q
    WHERE b.currencyID <> q.currencyID
)
INSERT dbo.exchangePairs (exchangePairID, baseCurrencyID, quoteCurrencyID, isActive, createdAt)
SELECT exchangePairID, baseCurrencyID, quoteCurrencyID, 1, SYSUTCDATETIME()
FROM pairs;
SET IDENTITY_INSERT dbo.exchangePairs OFF;

SET IDENTITY_INSERT dbo.currentExchangeRates ON;
WITH currencyUsdValue AS (
    SELECT * FROM (VALUES
        (CAST(1 AS BIGINT), CAST(0.010000 AS DECIMAL(18,8)), N'Internal'), -- POINT: USD por punto
        (CAST(2 AS BIGINT), CAST(1.000000 AS DECIMAL(18,8)), N'Market'),   -- USD
        (CAST(3 AS BIGINT), CAST(1.080000 AS DECIMAL(18,8)), N'ECB'),      -- EUR
        (CAST(4 AS BIGINT), CAST(0.001942 AS DECIMAL(18,8)), N'BCCR'),     -- CRC
        (CAST(5 AS BIGINT), CAST(0.054348 AS DECIMAL(18,8)), N'Market'),   -- MXN
        (CAST(6 AS BIGINT), CAST(0.001093 AS DECIMAL(18,8)), N'Market'),   -- ARS
        (CAST(7 AS BIGINT), CAST(0.000253 AS DECIMAL(18,8)), N'Market'),   -- COP
        (CAST(8 AS BIGINT), CAST(0.001081 AS DECIMAL(18,8)), N'Market'),   -- CLP
        (CAST(9 AS BIGINT), CAST(0.266000 AS DECIMAL(18,8)), N'Market')    -- PEN
    ) v(currencyID, usdValue, sourceName)
), rates AS (
    SELECT
        ep.exchangePairID AS currentExchangeRateID,
        ep.exchangePairID,
        ep.baseCurrencyID,
        ep.quoteCurrencyID,
        CAST((baseUsd.usdValue / quoteUsd.usdValue) * 0.995 AS DECIMAL(18,6)) AS buyRate,
        CAST((baseUsd.usdValue / quoteUsd.usdValue) * 1.005 AS DECIMAL(18,6)) AS sellRate,
        CASE
            WHEN ep.baseCurrencyID = 1 OR ep.quoteCurrencyID = 1 THEN N'Internal'
            WHEN ep.baseCurrencyID = 4 OR ep.quoteCurrencyID = 4 THEN N'BCCR'
            WHEN ep.baseCurrencyID = 3 OR ep.quoteCurrencyID = 3 THEN N'ECB'
            ELSE N'Market'
        END AS sourceName
    FROM dbo.exchangePairs ep
    JOIN currencyUsdValue baseUsd  ON baseUsd.currencyID = ep.baseCurrencyID
    JOIN currencyUsdValue quoteUsd ON quoteUsd.currencyID = ep.quoteCurrencyID
)
INSERT dbo.currentExchangeRates
 (currentExchangeRateID, exchangePairID, baseCurrencyID, quoteCurrencyID, buyRate, sellRate, sourceName, updatedAt)
SELECT currentExchangeRateID, exchangePairID, baseCurrencyID, quoteCurrencyID, buyRate, sellRate, sourceName, SYSUTCDATETIME()
FROM rates;
SET IDENTITY_INSERT dbo.currentExchangeRates OFF;

SET IDENTITY_INSERT dbo.currencyConfigurations ON;
INSERT dbo.currencyConfigurations
 (currencyConfigurationID, currencyID, configCode, configName, initialBalance, maxAmountPerPrediction,
  platformFeePercent, proposerFeePercent, validationFailurePenaltyPercent, propositionRejectionPenalty,
  validFrom, isCurrent, createdAt) VALUES
 (1, 1, N'POINT_DEFAULT', N'Configuración de puntos', 100.000000, 1.000000, 8.00, 4.00, 15.00, 1.000000, SYSUTCDATETIME(), 1, SYSUTCDATETIME()),
 (2, 2, N'USD_DEFAULT', N'Configuración US Dollar', 0.000000, 25.000000, 8.00, 4.00, 15.00, 2.000000, SYSUTCDATETIME(), 1, SYSUTCDATETIME()),
 (3, 3, N'EUR_DEFAULT', N'Configuración Euro', 0.000000, 25.000000, 8.00, 4.00, 15.00, 2.000000, SYSUTCDATETIME(), 1, SYSUTCDATETIME()),
 (4, 4, N'CRC_DEFAULT', N'Configuración Colón costarricense', 0.000000, 13000.000000, 8.00, 4.00, 15.00, 1000.000000, SYSUTCDATETIME(), 1, SYSUTCDATETIME()),
 (5, 5, N'MXN_DEFAULT', N'Configuración Peso mexicano', 0.000000, 450.000000, 8.00, 4.00, 15.00, 30.000000, SYSUTCDATETIME(), 1, SYSUTCDATETIME()),
 (6, 6, N'ARS_DEFAULT', N'Configuración Peso argentino', 0.000000, 22000.000000, 8.00, 4.00, 15.00, 1500.000000, SYSUTCDATETIME(), 1, SYSUTCDATETIME()),
 (7, 7, N'COP_DEFAULT', N'Configuración Peso colombiano', 0.000000, 95000.000000, 8.00, 4.00, 15.00, 6000.000000, SYSUTCDATETIME(), 1, SYSUTCDATETIME()),
 (8, 8, N'CLP_DEFAULT', N'Configuración Peso chileno', 0.000000, 22000.000000, 8.00, 4.00, 15.00, 1500.000000, SYSUTCDATETIME(), 1, SYSUTCDATETIME()),
 (9, 9, N'PEN_DEFAULT', N'Configuración Sol peruano', 0.000000, 90.000000, 8.00, 4.00, 15.00, 6.000000, SYSUTCDATETIME(), 1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.currencyConfigurations OFF;

SET IDENTITY_INSERT dbo.socialNetworks ON;
INSERT dbo.socialNetworks (socialNetworkID, socialNetworkName, socialNetworkDescription, baseURL, apiURL, config, isActive, createdAt) VALUES
 (1, N'Instagram', N'Fotos y reels', N'https://instagram.com', N'https://graph.instagram.com', N'{}', 1, SYSUTCDATETIME()),
 (2, N'TikTok',    N'Videos cortos', N'https://tiktok.com',    N'https://open.tiktokapis.com', N'{}', 1, SYSUTCDATETIME()),
 (3, N'X',         N'Microblogging', N'https://x.com',         N'https://api.x.com',           N'{}', 1, SYSUTCDATETIME()),
 (4, N'YouTube',   N'Videos largos', N'https://youtube.com',   N'https://www.googleapis.com',  N'{}', 1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.socialNetworks OFF;

SET IDENTITY_INSERT dbo.resourceTypes ON;
INSERT dbo.resourceTypes (resourceTypeID, resourceTypeName, resourceTypeDescription, isActive, createdAt) VALUES
 (1, N'post',  N'Publicación', 1, SYSUTCDATETIME()),
 (2, N'story', N'Historia',    1, SYSUTCDATETIME()),
 (3, N'reel',  N'Reel',        1, SYSUTCDATETIME()),
 (4, N'video', N'Video',       1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.resourceTypes OFF;

PRINT '== Catálogos base insertados ==';

/* ====== SECCIÓN 2 · DICCIONARIOS DE GENERACIÓN ====== */

DECLARE @firstNames TABLE (idx INT PRIMARY KEY, val NVARCHAR(40));
INSERT @firstNames VALUES
 (0,N'Ana'),(1,N'Luis'),(2,N'Sofía'),(3,N'Carlos'),(4,N'María'),(5,N'José'),
 (6,N'Laura'),(7,N'Diego'),(8,N'Valeria'),(9,N'Andrés'),(10,N'Camila'),(11,N'Mateo'),
 (12,N'Isabel'),(13,N'Javier'),(14,N'Gabriela'),(15,N'Daniel'),(16,N'Paula'),(17,N'Fernando'),
 (18,N'Lucía'),(19,N'Rodrigo'),(20,N'Elena'),(21,N'Pablo'),(22,N'Natalia'),(23,N'Sergio');

DECLARE @lastNames TABLE (idx INT PRIMARY KEY, val NVARCHAR(40));
INSERT @lastNames VALUES
 (0,N'Rojas'),(1,N'Mora'),(2,N'Brenes'),(3,N'Vargas'),(4,N'Jiménez'),(5,N'Castro'),
 (6,N'Solís'),(7,N'Herrera'),(8,N'Núñez'),(9,N'Ramírez'),(10,N'Quesada'),(11,N'Madrigal'),
 (12,N'Alfaro'),(13,N'Cordero'),(14,N'Salas'),(15,N'Chaves'),(16,N'Araya'),(17,N'Méndez'),
 (18,N'Calderón'),(19,N'Fonseca');

DECLARE @verbs TABLE (idx INT PRIMARY KEY, val NVARCHAR(120));
INSERT @verbs VALUES
 (0,N'publicará un video corriendo 10K'),
 (1,N'subirá una foto cocinando esta semana'),
 (2,N'terminará la maratón entre los primeros 30'),
 (3,N'asistirá al concierto el fin de semana'),
 (4,N'alcanzará 10 000 seguidores este mes'),
 (5,N'viajará fuera del país en julio'),
 (6,N'lanzará un nuevo emprendimiento'),
 (7,N'aprenderá a tocar guitarra y lo demostrará');

DECLARE @pwWords TABLE (idx INT PRIMARY KEY, val NVARCHAR(20));
INSERT @pwWords VALUES
 (0,N'Tigre'),(1,N'Luna'),(2,N'Fuego'),(3,N'Rio'),(4,N'Sol'),(5,N'Nube'),
 (6,N'Roca'),(7,N'Viento'),(8,N'Mar'),(9,N'Bosque'),(10,N'Rayo'),(11,N'Hielo'),
 (12,N'Trueno'),(13,N'Estrella'),(14,N'Cobra'),(15,N'Lobo');

/* ====== SECCIÓN 3 · CREAR JUGADORES ====== */

SET IDENTITY_INSERT dbo.players ON;
INSERT dbo.players
 (playerID, countryID, email, username, firstName, lastName, secondLastName,
  passwordHash, isEmailVerified, isActive, lastLoginAt, createdAt)
SELECT
   g.value,
   (CAST(g.value AS BIGINT)*69621 % 2147483647) % 8 + 1,
   LOWER(fn.val + ln.val + CAST(g.value AS NVARCHAR(10))) + N'@gathel.com',
   fn.val + ln.val + CAST(g.value AS NVARCHAR(10)),
   fn.val, ln.val,
   CASE WHEN g.value % 3 = 0 THEN ln2.val ELSE NULL END,
   pw1.val + pw2.val + RIGHT(N'000' + CAST((CAST(g.value AS BIGINT)*40692 % 2147483647) % 1000 AS NVARCHAR(3)), 3),
   CASE WHEN (CAST(g.value AS BIGINT)*16807 % 2147483647) % 5 = 0 THEN 0 ELSE 1 END,
   1,
   DATEADD(MINUTE, (CAST(g.value AS BIGINT)*40692 % 2147483647) % 200000, @anchorPlayers),
   DATEADD(MINUTE, (CAST(g.value AS BIGINT)*48271 % 2147483647) % 525600, @anchorPlayers)
FROM (SELECT value FROM #Numbers WHERE value BETWEEN 1 AND 1000) AS g
JOIN @firstNames fn  ON fn.idx  = (CAST(g.value AS BIGINT)*48271 % 2147483647) % 24
JOIN @lastNames  ln  ON ln.idx  = (CAST(g.value AS BIGINT)*16807 % 2147483647) % 20
JOIN @lastNames  ln2 ON ln2.idx = (CAST(g.value AS BIGINT)*69621 % 2147483647) % 20
JOIN @pwWords    pw1 ON pw1.idx = (CAST(g.value AS BIGINT)*48271 % 2147483647) % 16
JOIN @pwWords    pw2 ON pw2.idx = (CAST(g.value AS BIGINT)*69621 % 2147483647) % 16;
SET IDENTITY_INSERT dbo.players OFF;

UPDATE dbo.players
SET lastLoginAt = DATEADD(
    MINUTE,
    (CAST(playerID AS BIGINT) * 40692 % 2147483647)
        % (DATEDIFF(MINUTE, createdAt, @seedNow) + 1),
    createdAt
);

INSERT dbo.systemUsers (playerID, roleID, createdAt)
SELECT p.playerID,
       CASE WHEN p.playerID % 200 = 0 THEN 2
            WHEN p.playerID % 100 = 0 THEN 3
            ELSE 1 END,
       p.createdAt
FROM dbo.players p;

SET IDENTITY_INSERT dbo.playersSocialNetwork ON;
INSERT dbo.playersSocialNetwork
 (playerSocialNetworkID, playerID, socialNetworkID, externalAccountID, externalUsername,
  isAuthorized, isActive, linkedAt, createdAt)
SELECT p.playerID, p.playerID, ((p.playerID - 1) % 4) + 1,
       N'sn_' + CAST(((p.playerID - 1) % 4) + 1 AS NVARCHAR(2))
           + N'_' + CAST(p.playerID AS NVARCHAR(10)),
       p.username,
       1, 1, p.createdAt, p.createdAt
FROM dbo.players p;
SET IDENTITY_INSERT dbo.playersSocialNetwork OFF;

INSERT dbo.balances
 (playerID, currencyID, availableAmount, reservedAmount, totalAmountEarned, totalAmountSpent, createdAt, isCurrent)
SELECT
    p.playerID,
    pointCurrency.currencyID,
    CAST(100 + ((p.playerID * 17) % 200) AS DECIMAL(18,6)),
    CAST((p.playerID * 7) % 20 AS DECIMAL(18,6)),
    CAST(100 + ((p.playerID * 23) % 500) AS DECIMAL(18,6)),
    CAST((p.playerID * 11) % 120 AS DECIMAL(18,6)),
    p.createdAt,
    1
FROM dbo.players p
CROSS JOIN (SELECT currencyID FROM dbo.currencies WHERE currencyCode = N'POINT') pointCurrency;

INSERT dbo.moneyBalance
 (playerID, currencyID, availableAmount, reservedAmount, totalDeposited, totalWithdrawn, createdAt, isActive)
SELECT
    p.playerID,
    c.currencyID,
    CASE
        WHEN c.currencyID IN (4,6,7,8) THEN CAST(((p.playerID * 21401 + c.currencyID * 16807) % 2000000) AS DECIMAL(18,6)) / 10.0
        ELSE CAST(((p.playerID * 21401 + c.currencyID * 16807) % 85000) AS DECIMAL(18,6)) / 100.0
    END,
    CASE
        WHEN c.currencyID IN (4,6,7,8) THEN CAST(((p.playerID * 71 + c.currencyID * 37) % 40000) AS DECIMAL(18,6)) / 10.0
        ELSE CAST(((p.playerID * 71 + c.currencyID * 37) % 2500) AS DECIMAL(18,6)) / 100.0
    END,
    CASE
        WHEN c.currencyID IN (4,6,7,8) THEN CAST(70000 + ((p.playerID * 157 + c.currencyID * 59) % 2500000) AS DECIMAL(18,6)) / 10.0
        ELSE CAST(1000 + ((p.playerID * 157 + c.currencyID * 59) % 100000) AS DECIMAL(18,6)) / 100.0
    END,
    CASE
        WHEN c.currencyID IN (4,6,7,8) THEN CAST(((p.playerID * 47 + c.currencyID * 23) % 700000) AS DECIMAL(18,6)) / 10.0
        ELSE CAST(((p.playerID * 47 + c.currencyID * 23) % 25000) AS DECIMAL(18,6)) / 100.0
    END,
    p.createdAt,
    1
FROM dbo.players p
CROSS JOIN dbo.currencies c
WHERE c.currencyCode <> N'POINT';
PRINT '== 1000 jugadores insertados con balances de puntos y dinero real separados ==';

/* ====== SECCIÓN 4 · CREAR PROPOSICIONES Y RECURSOS ====== */

SET IDENTITY_INSERT dbo.resources ON;
INSERT dbo.resources
 (resourceID, playerSocialNetworkID, resourceTypeID, externalResourceID, contentURL, contentHash,
  capturedAt, eventOccurredAt, validationStatus, isActive, createdAt)
SELECT
   g.value,
   CASE WHEN (CAST(g.value AS BIGINT)*16807 % 2147483647) % 5 = 0
        THEN (CAST(g.value AS BIGINT)*48271 % 2147483647) % 1000 + 1
        ELSE (CAST(g.value AS BIGINT)*16807 % 2147483647) % 1000 + 1 END,
   (CAST(g.value AS BIGINT)*69621 % 2147483647) % 4 + 1,
   N'res_' + CAST(g.value AS NVARCHAR(10)),
   N'https://cdn.gathel.com/evidence/' + CAST(g.value AS NVARCHAR(10)),
   CONVERT(NVARCHAR(80), HASHBYTES('SHA2_256', CAST(g.value AS NVARCHAR(20))), 2),
   DATEADD(MINUTE, (CAST(g.value AS BIGINT)*40692 % 2147483647) % 360000, @anchorProps),
   CASE WHEN g.value % 10 BETWEEN 6 AND 8
        THEN DATEADD(MINUTE, (CAST(g.value AS BIGINT)*40692 % 2147483647) % 360000 + 4320, @anchorProps)
        ELSE NULL END,
   CASE WHEN g.value % 10 BETWEEN 6 AND 8 THEN N'validated' ELSE N'pending' END,
   1,
   DATEADD(MINUTE, (CAST(g.value AS BIGINT)*40692 % 2147483647) % 360000, @anchorProps)
FROM (SELECT value FROM #Numbers WHERE value BETWEEN 1 AND 5000) AS g;
SET IDENTITY_INSERT dbo.resources OFF;

SET IDENTITY_INSERT dbo.propositions ON;
INSERT dbo.propositions
 (propositionID, creatorPlayerID, targetPlayerID, relatedResourceID, propositionStatusID,
  propositionText, predictionsDeadline, votingDeadline, acceptedAt, closedAt, createdAt, isActive)
SELECT
   g.value,
   (CAST(g.value AS BIGINT)*48271 % 2147483647) % 1000 + 1,
   targetSelection.targetPlayerID,
   g.value,
   propositionDates.statusID,
   N'@' + targetPlayer.username + N' ' + v.val,
   propositionDates.predictionsDeadline,
   DATEADD(DAY, 1, propositionDates.predictionsDeadline),
   DATEADD(HOUR, 1, propositionDates.createdAt),
   DATEADD(HOUR, 1, DATEADD(DAY, 1, propositionDates.predictionsDeadline)),
   propositionDates.createdAt,
   1
FROM (SELECT value FROM #Numbers WHERE value BETWEEN 1 AND 5000) AS g
JOIN @verbs v ON v.idx = (CAST(g.value AS BIGINT)*69621 % 2147483647) % 8
CROSS APPLY
(
    VALUES
    (
        CASE WHEN (CAST(g.value AS BIGINT)*16807 % 2147483647) % 5 = 0
             THEN (CAST(g.value AS BIGINT)*48271 % 2147483647) % 1000 + 1
             ELSE (CAST(g.value AS BIGINT)*16807 % 2147483647) % 1000 + 1 END
    )
) targetSelection(targetPlayerID)
JOIN dbo.players targetPlayer ON targetPlayer.playerID = targetSelection.targetPlayerID
CROSS APPLY
(
    SELECT
        CASE WHEN g.value % 5 IN (0,1,2) THEN 2 ELSE 3 END AS statusID,
        CASE
            WHEN g.value % 5 IN (0,1,2)
                THEN DATEADD(DAY, -1 - ((CAST(g.value AS BIGINT) * 48271 % 2147483647) % 20), @seedNow)
            ELSE DATEADD(DAY, -30 - ((CAST(g.value AS BIGINT) * 48271 % 2147483647) % 150), @seedNow)
        END AS createdAt,
        CASE
            WHEN g.value % 5 IN (0,1,2)
                THEN DATEADD(DAY, 1 + ((CAST(g.value AS BIGINT) * 40692 % 2147483647) % 30), @seedNow)
            ELSE DATEADD(
                DAY,
                2 + ((CAST(g.value AS BIGINT) * 40692 % 2147483647) % 10),
                DATEADD(DAY, -30 - ((CAST(g.value AS BIGINT) * 48271 % 2147483647) % 150), @seedNow)
            )
        END AS predictionsDeadline
) propositionDates;
SET IDENTITY_INSERT dbo.propositions OFF;

/* Monedas permitidas por proposición:
   25% solo POINT, 25% solo USD y 50% ambas. */
INSERT dbo.propositionPredictionCurrencies (propositionID, currencyID, createdAt)
SELECT
    pr.propositionID,
    c.currencyID,
    pr.createdAt
FROM dbo.propositions pr
JOIN dbo.currencies c
  ON (pr.propositionID % 4 = 0 AND c.currencyCode = N'POINT')
  OR (pr.propositionID % 4 = 1 AND c.currencyCode = N'USD')
  OR (pr.propositionID % 4 IN (2,3) AND c.currencyCode IN (N'POINT', N'USD'));

/* Para proposiciones finalizadas, el recurso funciona como evidencia del evento
   y queda temporalmente alineado con el cierre y la validación. */
UPDATE r
SET
    r.createdAt = pr.createdAt,
    r.capturedAt = CASE WHEN pr.propositionStatusID = 3
                        THEN DATEADD(MINUTE, 15, pr.closedAt)
                        ELSE pr.createdAt END,
    r.eventOccurredAt = CASE WHEN pr.propositionStatusID = 3
                             THEN DATEADD(MINUTE, 10, pr.closedAt)
                             ELSE NULL END,
    r.validationStatus = CASE WHEN pr.propositionStatusID = 3
                              THEN N'validated'
                              ELSE N'pending' END,
    r.updatedAt = CASE WHEN pr.propositionStatusID = 3
                       THEN DATEADD(HOUR, 6, pr.closedAt)
                       ELSE NULL END
FROM dbo.resources r
JOIN dbo.propositions pr ON pr.relatedResourceID = r.resourceID;

PRINT '== 5000 proposiciones, recursos y monedas permitidas insertados ==';

/* ====== SECCIÓN 5 · CREAR PREDICCIONES (eventos) ====== */

DECLARE @inicio INT = 1;
DECLARE @lote   INT = 50000;
DECLARE @total  INT = 250000;
DECLARE @fin    INT;

SET IDENTITY_INSERT dbo.predictions ON;
WHILE @inicio <= @total
BEGIN
    SET @fin = CASE WHEN @inicio + @lote - 1 > @total THEN @total ELSE @inicio + @lote - 1 END;

    INSERT dbo.predictions
     (predictionID, propositionID, playerID, predictionTypeID, predictionActive, checksum, predictedAt, createdAt, isActive)
    SELECT
        g.value,
        pr.propositionID,
        ((CAST(pr.propositionID AS BIGINT) * 17 + distribution.waveNumber * 37) % 1000) + 1,
        ((CAST(pr.propositionID AS BIGINT) + distribution.waveNumber) % 2) + 1,
        CASE WHEN pr.propositionStatusID = 2 THEN 1 ELSE 0 END,
        CONVERT(
            NVARCHAR(80),
            HASHBYTES(
                'SHA2_256',
                CONCAT(N'prediction-', g.value, N'-', pr.propositionID, N'-', distribution.waveNumber)
            ),
            2
        ),
        predictionTime.predictedAt,
        predictionTime.predictedAt,
        1
    FROM (SELECT value FROM #Numbers WHERE value BETWEEN @inicio AND @fin) AS g
    CROSS APPLY
    (
        VALUES
        (
            ((g.value - 1) % 5000) + 1,
            (g.value - 1) / 5000
        )
    ) distribution(propositionID, waveNumber)
    JOIN dbo.propositions pr
      ON pr.propositionID = distribution.propositionID
    CROSS APPLY
    (
        VALUES
        (
            CASE
                WHEN pr.predictionsDeadline < @seedNow THEN pr.predictionsDeadline
                ELSE @seedNow
            END
        )
    ) predictionWindow(windowEnd)
    CROSS APPLY
    (
        VALUES
        (
            DATEADD(
                MINUTE,
                1 + (
                    (CAST(g.value AS BIGINT) * 69621 % 2147483647)
                    % (DATEDIFF(MINUTE, pr.acceptedAt, predictionWindow.windowEnd) - 1)
                ),
                pr.acceptedAt
            )
        )
    ) predictionTime(predictedAt);

    INSERT dbo.predictionStakes (predictionID, currencyID, amount, createdAt, isActive)
    SELECT
        pd.predictionID,
        selectedCurrency.currencyID,
        CASE
            WHEN selectedCurrency.currencyID = 1 THEN CAST(1.000000 AS DECIMAL(18,6))
            ELSE CAST(((CAST(pd.predictionID AS BIGINT) * 16807) % 2400 + 100) AS DECIMAL(18,6)) / 100.0
        END,
        pd.createdAt,
        1
    FROM dbo.predictions pd
    JOIN dbo.propositions pr ON pr.propositionID = pd.propositionID
    CROSS APPLY
    (
        VALUES
        (
            CASE
                WHEN pr.propositionID % 4 = 0 THEN CAST(1 AS BIGINT)
                WHEN pr.propositionID % 4 = 1 THEN CAST(2 AS BIGINT)
                WHEN ((pd.predictionID - 1) / 5000) % 2 = 0 THEN CAST(1 AS BIGINT)
                ELSE CAST(2 AS BIGINT)
            END
        )
    ) selectedCurrency(currencyID)
    WHERE pd.predictionID BETWEEN @inicio AND @fin;

    PRINT CONCAT('   lote predicciones ', @inicio, '..', @fin, ' OK');
    SET @inicio = @fin + 1;
END;
SET IDENTITY_INSERT dbo.predictions OFF;
PRINT '== 250 000 predicciones + stakes válidos insertados (50 por proposición) ==';

/* ====== SECCIÓN 6 · RESULTADOS Y LIQUIDACIONES ====== */

INSERT dbo.propositionResult
 (propositionID, resultTypeID, propositionFulfilled, evidenceResourceID, validatedAt, createdAt, isActive)
SELECT
    pr.propositionID,
    CASE WHEN pr.propositionID % 2 = 0 THEN 1 ELSE 2 END,
    CASE WHEN pr.propositionID % 2 = 0 THEN 1 ELSE 0 END,
    pr.relatedResourceID,
    DATEADD(HOUR, 6, pr.closedAt),
    DATEADD(HOUR, 6, pr.closedAt),
    1
FROM dbo.propositions pr
WHERE pr.propositionStatusID = 3;

INSERT dbo.predictionResults (predictionID, didWin, determinedAt, createdAt, isActive)
SELECT
    pd.predictionID,
    CASE WHEN (pd.predictionTypeID = 1 AND pr.propositionID % 2 = 0)
            OR (pd.predictionTypeID = 2 AND pr.propositionID % 2 <> 0)
         THEN 1 ELSE 0 END,
    DATEADD(HOUR, 6, pr.closedAt),
    DATEADD(HOUR, 6, pr.closedAt),
    1
FROM dbo.predictions pd
JOIN dbo.propositions pr ON pr.propositionID = pd.propositionID
WHERE pr.propositionStatusID = 3;

INSERT dbo.predictionSettlements
 (predictionResultID, recipientPlayerID, currencyID, amount, settlementStatusTypeID,
  settlementTypeName, settledByPlayerID, settledAt, createdAt)
SELECT
    res.predictionResultID,
    pd.playerID,
    stk.currencyID,
    CAST(stk.amount * 1.8 AS DECIMAL(18,6)),
    2,
    CASE WHEN stk.currencyID = 1 THEN N'premio_puntos' ELSE N'premio_dinero' END,
    pd.playerID,
    res.determinedAt,
    res.determinedAt
FROM dbo.predictionResults res
JOIN dbo.predictions pd       ON pd.predictionID = res.predictionID
JOIN dbo.predictionStakes stk ON stk.predictionID = res.predictionID
WHERE res.didWin = 1;

/* Los saldos reservados se derivan de los pronósticos que siguen activos.
   Los acumulados quedan cuadrados con el saldo inicial de 100 puntos y con
   los fondos depositados en cada moneda real. */
WITH pointActivity AS
(
    SELECT
        pd.playerID,
        SUM(CASE WHEN pr.propositionStatusID = 2 THEN stk.amount ELSE 0 END) AS reservedAmount,
        SUM(CASE WHEN pr.propositionStatusID = 3 THEN stk.amount ELSE 0 END) AS spentAmount
    FROM dbo.predictions pd
    JOIN dbo.propositions pr ON pr.propositionID = pd.propositionID
    JOIN dbo.predictionStakes stk ON stk.predictionID = pd.predictionID
    JOIN dbo.currencies c ON c.currencyID = stk.currencyID
    WHERE c.currencyCode = N'POINT'
    GROUP BY pd.playerID
)
UPDATE b
SET
    b.reservedAmount = COALESCE(pa.reservedAmount, 0),
    b.totalAmountSpent = COALESCE(pa.spentAmount, 0),
    b.totalAmountEarned =
        b.availableAmount
        + COALESCE(pa.reservedAmount, 0)
        + COALESCE(pa.spentAmount, 0)
        - 100.000000,
    b.updatedAt = @seedNow
FROM dbo.balances b
LEFT JOIN pointActivity pa ON pa.playerID = b.playerID;

WITH moneyActivity AS
(
    SELECT
        pd.playerID,
        stk.currencyID,
        SUM(stk.amount) AS reservedAmount
    FROM dbo.predictions pd
    JOIN dbo.propositions pr ON pr.propositionID = pd.propositionID
    JOIN dbo.predictionStakes stk ON stk.predictionID = pd.predictionID
    WHERE pr.propositionStatusID = 2
      AND stk.currencyID <> 1
    GROUP BY pd.playerID, stk.currencyID
)
UPDATE mb
SET
    mb.reservedAmount = COALESCE(ma.reservedAmount, 0),
    mb.totalDeposited =
        mb.availableAmount
        + COALESCE(ma.reservedAmount, 0)
        + mb.totalWithdrawn
FROM dbo.moneyBalance mb
LEFT JOIN moneyActivity ma
  ON ma.playerID = mb.playerID
 AND ma.currencyID = mb.currencyID;

PRINT '== resultados y liquidaciones insertados ==';

/* ====== SECCIÓN 7 · PAGOS Y TRANSACCIONES VARIADAS ====== */

INSERT dbo.transactions
 (playerID, transactionTypeCodeID, propositionID, predictionID, currencyID,
  amount, balanceBefore, balanceAfter, description, checksum, transactionDate, createdAt)
SELECT
    ranked.playerID,
    1,
    ranked.propositionID,
    ranked.predictionID,
    stk.currencyID,
    stk.amount,
    CAST(COALESCE(b.availableAmount, mb.availableAmount) + stk.amount AS DECIMAL(18,6)),
    CAST(COALESCE(b.availableAmount, mb.availableAmount) AS DECIMAL(18,6)),
    N'Reserva inicial del pronóstico ' + CAST(ranked.predictionID AS NVARCHAR(20)),
    CONVERT(NVARCHAR(80), HASHBYTES('SHA2_256', CONCAT(N'tx-prediction-', ranked.predictionID)), 2),
    ranked.predictedAt,
    ranked.createdAt
FROM
(
    SELECT
        pd.predictionID,
        pd.propositionID,
        pd.playerID,
        pd.predictedAt,
        pd.createdAt,
        ROW_NUMBER() OVER (PARTITION BY pd.propositionID ORDER BY pd.predictionID) AS rowInProposition
    FROM dbo.predictions pd
) ranked
JOIN dbo.predictionStakes stk ON stk.predictionID = ranked.predictionID
LEFT JOIN dbo.balances b
  ON b.playerID = ranked.playerID
 AND b.currencyID = stk.currencyID
 AND b.isCurrent = 1
LEFT JOIN dbo.moneyBalance mb
  ON mb.playerID = ranked.playerID
 AND mb.currencyID = stk.currencyID
 AND mb.isActive = 1
WHERE ranked.rowInProposition <= 3;

/* Una comisión trazable por cada una de las 5000 proposiciones. */
INSERT dbo.transactions
 (playerID, transactionTypeCodeID, propositionID, predictionID, currencyID,
  amount, balanceBefore, balanceAfter, description, checksum, transactionDate, createdAt)
SELECT
    pr.creatorPlayerID,
    5,
    pr.propositionID,
    NULL,
    pointCurrency.currencyID,
    CAST(0.080000 AS DECIMAL(18,6)),
    b.availableAmount,
    CAST(b.availableAmount + 0.080000 AS DECIMAL(18,6)),
    N'Comisión sintética asociada a la proposición ' + CAST(pr.propositionID AS NVARCHAR(20)),
    CONVERT(NVARCHAR(80), HASHBYTES('SHA2_256', CONCAT(N'tx-proposition-', pr.propositionID)), 2),
    DATEADD(MINUTE, 5, pr.createdAt),
    DATEADD(MINUTE, 5, pr.createdAt)
FROM dbo.propositions pr
CROSS JOIN (SELECT currencyID FROM dbo.currencies WHERE currencyCode = N'POINT') pointCurrency
JOIN dbo.balances b
  ON b.playerID = pr.creatorPlayerID
 AND b.currencyID = pointCurrency.currencyID
 AND b.isCurrent = 1;

INSERT dbo.paymentAttempts
 (paymentMethodID, playerID, operationTypeCodeID, targetEntityType, targetEntityID,
  sourceEntityType, sourceEntityID, amount, currencyID, exchangeRate, exchangeRateID,
  paymentStatusID, result, requestPayload, responsePayload, transactionReference, checksum, postedAt, createdAt)
SELECT
    CASE WHEN pr.propositionID % 2 = 0 THEN 1 ELSE 2 END,
    pr.creatorPlayerID,
    CASE WHEN pr.propositionStatusID = 2 THEN 3 ELSE 4 END,
    N'proposition',
    pr.propositionID,
    N'player',
    pr.creatorPlayerID,
    amt.amount,
    localCurrency.currencyID,
    cer.buyRate,
    cer.currentExchangeRateID,
    CASE WHEN pr.propositionID % 17 = 0 THEN 3
         WHEN pr.propositionID % 13 = 0 THEN 1
         ELSE 2 END,
    CASE WHEN pr.propositionID % 17 = 0 THEN N'failed'
         WHEN pr.propositionID % 13 = 0 THEN N'pending'
         ELSE N'completed' END,
    N'{"op":"seed_proposition_payment","propositionID":' + CAST(pr.propositionID AS NVARCHAR(20))
        + N',"currency":"' + localCurrency.currencyCode + N'"}',
    CASE WHEN pr.propositionID % 17 = 0 THEN N'{"status":"rejected"}'
         WHEN pr.propositionID % 13 = 0 THEN N'{"status":"pending"}'
         ELSE N'{"status":"ok"}' END,
    N'ref_' + localCurrency.currencyCode + N'_' + CAST(pr.propositionID AS NVARCHAR(20)),
    CONVERT(NVARCHAR(80), HASHBYTES('SHA2_256', CONCAT(N'pay-proposition-', pr.propositionID)), 2),
    DATEADD(MINUTE, 120, pr.createdAt),
    DATEADD(MINUTE, 120, pr.createdAt)
FROM dbo.propositions pr
JOIN dbo.players payer ON payer.playerID = pr.creatorPlayerID
JOIN dbo.countries payerCountry ON payerCountry.countryID = payer.countryID
JOIN dbo.currencies localCurrency ON localCurrency.currencyID = payerCountry.localCurrencyID
CROSS APPLY
(
    SELECT TOP (1)
        cer0.currentExchangeRateID,
        cer0.buyRate
    FROM dbo.currentExchangeRates cer0
    WHERE cer0.baseCurrencyID = localCurrency.currencyID
      AND cer0.quoteCurrencyID =
          CASE WHEN localCurrency.currencyCode = N'USD' THEN 1 ELSE 2 END
    ORDER BY cer0.currentExchangeRateID
) cer
CROSS APPLY
(
    SELECT CAST(
        CASE
            WHEN localCurrency.currencyID IN (4,6,7,8)
                THEN ((CAST(pr.propositionID AS BIGINT) * 89) % 20000 + 500) / 10.0
            ELSE ((CAST(pr.propositionID AS BIGINT) * 89) % 2200 + 100) / 100.0
        END AS DECIMAL(18,6)
    ) AS amount
) amt;

PRINT '== 20 000 transacciones y 5000 paymentAttempts coherentes insertados ==';


/* ====== SECCIÓN 8 · TABLAS COMPLEMENTARIAS PARA COBERTURA DEL MODELO ====== */

INSERT dbo.loginAttempts (playerID, attemptedEmail, ipAddress, wasSuccessful, failureReason, attemptedAt, createdAt)
SELECT TOP (9000)
    p.playerID,
    CASE WHEN n.value % 19 = 0
         THEN N'intento.' + CAST(p.playerID AS NVARCHAR(20)) + N'@gathel.com'
         ELSE p.email END,
    N'10.' + CAST((n.value % 200) AS NVARCHAR(3)) + N'.' + CAST((p.playerID % 255) AS NVARCHAR(3)) + N'.' + CAST(((n.value * 7) % 255) AS NVARCHAR(3)),
    CASE WHEN n.value % 11 IN (0,1,2) THEN 0 ELSE 1 END,
    CASE WHEN n.value % 11 = 0 THEN N'password_incorrect'
         WHEN n.value % 11 = 1 THEN N'account_locked'
         WHEN n.value % 11 = 2 THEN N'rate_limited'
         ELSE NULL END,
    DATEADD(
        MINUTE,
        (CAST(n.value AS BIGINT) * 7)
            % (DATEDIFF(MINUTE, p.createdAt, @seedNow) + 1),
        p.createdAt
    ),
    DATEADD(
        MINUTE,
        (CAST(n.value AS BIGINT) * 7)
            % (DATEDIFF(MINUTE, p.createdAt, @seedNow) + 1),
        p.createdAt
    )
FROM #Numbers n
JOIN dbo.players p ON p.playerID = ((n.value - 1) % 1000) + 1
WHERE n.value BETWEEN 1 AND 9000;

INSERT dbo.historicalExchangeRates (currentExchangeRateID, buyRate, sellRate, validFrom, validTo, recordedAt)
SELECT cer.currentExchangeRateID,
       CAST(cer.buyRate * (1 - (CAST(n.value AS DECIMAL(18,6)) * 0.003000)) AS DECIMAL(18,6)),
       CAST(cer.sellRate * (1 - (CAST(n.value AS DECIMAL(18,6)) * 0.003000)) AS DECIMAL(18,6)),
       DATEADD(DAY, -n.value, cer.updatedAt),
       DATEADD(DAY, -(n.value - 1), cer.updatedAt),
       DATEADD(DAY, -n.value, cer.updatedAt)
FROM dbo.currentExchangeRates cer
JOIN #Numbers n ON n.value BETWEEN 1 AND 30;

INSERT dbo.playerSocialNetworkTokens (playerSocialNetworkID, accessTokenHash, refreshTokenHash, tokenExpiresAt, isActive, createdAt)
SELECT TOP (1000)
    psn.playerSocialNetworkID,
    CONVERT(NVARCHAR(80), HASHBYTES('SHA2_256', CONCAT('access-', psn.playerSocialNetworkID)), 2),
    CONVERT(NVARCHAR(80), HASHBYTES('SHA2_256', CONCAT('refresh-', psn.playerSocialNetworkID)), 2),
    DATEADD(DAY, 30, SYSUTCDATETIME()),
    1,
    SYSUTCDATETIME()
FROM dbo.playersSocialNetwork psn;

INSERT dbo.propositionVotes (propositionID, voterPlayerID, propositionVoteTypeID, votedAt, createdAt)
SELECT
    distribution.propositionID,
    ((CAST(distribution.propositionID AS BIGINT) * 29 + distribution.voteNumber * 43) % 1000) + 1,
    CASE WHEN distribution.voteNumber = 3 THEN 3
         WHEN distribution.voteNumber % 2 = 0 THEN 1
         ELSE 2 END,
    DATEADD(MINUTE, 10 + distribution.voteNumber * 10, pr.createdAt),
    DATEADD(MINUTE, 10 + distribution.voteNumber * 10, pr.createdAt)
FROM (SELECT value FROM #Numbers WHERE value BETWEEN 1 AND 20000) n
CROSS APPLY
(
    VALUES
    (
        ((n.value - 1) % 5000) + 1,
        (n.value - 1) / 5000
    )
) distribution(propositionID, voteNumber)
JOIN dbo.propositions pr ON pr.propositionID = distribution.propositionID;

INSERT dbo.propositionStatusHistories
 (propositionID, previousStatusCodeID, currentStatusCodeID, changeDetails, changedByPlayerID, changedAt, createdAt)
SELECT pr.propositionID,
       1,
       2,
       N'Proposición aceptada y habilitada para predicciones',
       pr.creatorPlayerID,
       pr.acceptedAt,
       pr.acceptedAt
FROM dbo.propositions pr;

INSERT dbo.propositionStatusHistories
 (propositionID, previousStatusCodeID, currentStatusCodeID, changeDetails, changedByPlayerID, changedAt, createdAt)
SELECT
    pr.propositionID,
    2,
    3,
    N'Proposición finalizada y lista para liquidación',
    pr.targetPlayerID,
    pr.closedAt,
    pr.closedAt
FROM dbo.propositions pr
WHERE pr.propositionStatusID = 3;

INSERT dbo.predictionStakeHistories
 (predictionStakeID, previousAmount, currentAmount, previousCurrencyID, currentCurrencyID, changedAt, createdAt)
SELECT TOP (10000)
    ps.predictionStakeID,
    0.000000,
    ps.amount,
    NULL,
    ps.currencyID,
    ps.createdAt,
    ps.createdAt
FROM dbo.predictionStakes ps
ORDER BY ps.predictionStakeID;

INSERT dbo.changeSources (sourceCode, sourceName, sourceDescription, isActive, createdAt) VALUES
 (N'SEED', N'Seeding', N'Datos generados por migración Flyway', 1, SYSUTCDATETIME()),
 (N'APP',  N'Aplicación', N'Cambio hecho desde Gathel App', 1, SYSUTCDATETIME()),
 (N'AI',   N'IA', N'Validación automática por agente IA', 1, SYSUTCDATETIME());

SET IDENTITY_INSERT dbo.auditActionTypes ON;
INSERT dbo.auditActionTypes (auditActionTypeID, actionName, actionDescription) VALUES
 (1, N'INSERT', N'Creación de registro'),
 (2, N'UPDATE', N'Actualización de registro'),
 (3, N'DELETE', N'Eliminación lógica');
SET IDENTITY_INSERT dbo.auditActionTypes OFF;

INSERT dbo.auditLogs
 (entityName, entityID, auditActionTypeID, changeDetails, previousValues, newValues, changeSourceCode, performedByPlayerID, performedAt, createdAt)
SELECT TOP (5000)
    N'propositions',
    pr.propositionID,
    1,
    N'Proposición creada por seeding',
    NULL,
    N'{"status":"created"}',
    N'SEED',
    pr.creatorPlayerID,
    pr.createdAt,
    pr.createdAt
FROM dbo.propositions pr
ORDER BY pr.propositionID;

SET IDENTITY_INSERT dbo.merchants ON;
INSERT dbo.merchants (merchantID, merchantName, countryID, isActive, createdAt) VALUES
 (1, N'Gathel Store CR', 1, 1, SYSUTCDATETIME()),
 (2, N'Gathel Store US', 2, 1, SYSUTCDATETIME()),
 (3, N'Gathel Store MX', 3, 1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.merchants OFF;

SET IDENTITY_INSERT dbo.merchantProducts ON;
INSERT dbo.merchantProducts
 (merchantProductID, merchantID, productCode, productName, productDescription, costAmount, currencyID, isActive, createdAt) VALUES
 (1, 1, N'CR-COUPON-5',  N'Cupón digital ₡2500', N'Recompensa de prueba para jugadores en Costa Rica', 2500.000000, 4, 1, SYSUTCDATETIME()),
 (2, 2, N'US-COUPON-10', N'Cupón digital $10',   N'Recompensa de prueba en dólares', 10.000000, 2, 1, SYSUTCDATETIME()),
 (3, 3, N'MX-COUPON-100',N'Cupón digital $100 MXN', N'Recompensa de prueba en pesos mexicanos', 100.000000, 5, 1, SYSUTCDATETIME()),
 (4, 1, N'POINT-BADGE',  N'Insignia Gathel', N'Producto virtual canjeable con puntos', 25.000000, 1, 1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.merchantProducts OFF;

INSERT dbo.redemptions (playerID, merchantProductID, currencyID, amountSpent, redemptionCode, redeemedAt, createdAt)
SELECT TOP (100)
    p.playerID,
    4,
    1,
    25.000000,
    N'RED-' + RIGHT(N'000000' + CAST(p.playerID AS NVARCHAR(10)), 6),
    DATEADD(DAY, p.playerID % 60, @anchorProps),
    DATEADD(DAY, p.playerID % 60, @anchorProps)
FROM dbo.players p
WHERE p.playerID % 10 = 0
ORDER BY p.playerID;

SET IDENTITY_INSERT dbo.aiAgents ON;
INSERT dbo.aiAgents (aiAgentID, modelName, agentPurpose, isActive, createdAt) VALUES
 (1, N'gpt-4.1-mini', N'Validación automática de evidencias públicas', 1, SYSUTCDATETIME()),
 (2, N'gpt-4.1',      N'Revisión secundaria de casos ambiguos', 1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.aiAgents OFF;

SET IDENTITY_INSERT dbo.aiExecutionStatusTypes ON;
INSERT dbo.aiExecutionStatusTypes (aiExecutionStatusTypeID, statusName, statusDescription, isActive, createdAt) VALUES
 (1, N'queued', N'Pendiente de ejecución', 1, SYSUTCDATETIME()),
 (2, N'running', N'En ejecución', 1, SYSUTCDATETIME()),
 (3, N'completed', N'Completada', 1, SYSUTCDATETIME()),
 (4, N'failed', N'Fallida', 1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.aiExecutionStatusTypes OFF;

SET IDENTITY_INSERT dbo.aiValidationResultTypes ON;
INSERT dbo.aiValidationResultTypes (aiValidationResultTypeID, resultName, resultDescription, isActive, createdAt) VALUES
 (1, N'fulfilled', N'La evidencia indica cumplimiento', 1, SYSUTCDATETIME()),
 (2, N'not_fulfilled', N'La evidencia indica no cumplimiento', 1, SYSUTCDATETIME()),
 (3, N'inconclusive', N'La evidencia no permite concluir', 1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.aiValidationResultTypes OFF;

SET IDENTITY_INSERT dbo.severityLevels ON;
INSERT dbo.severityLevels (severityLevelID, severityName, severityDescription) VALUES
 (1, N'low', N'Observación menor'),
 (2, N'medium', N'Requiere revisión'),
 (3, N'high', N'Bloquea validación automática');
SET IDENTITY_INSERT dbo.severityLevels OFF;

SET IDENTITY_INSERT dbo.aiFindingTypes ON;
INSERT dbo.aiFindingTypes (aiFindingTypeID, findingTypeName, findingTypeDescription) VALUES
 (1, N'evidence_quality', N'Calidad o disponibilidad de evidencia'),
 (2, N'identity_match', N'Coincidencia entre objetivo y recurso'),
 (3, N'time_window', N'Consistencia temporal del evento');
SET IDENTITY_INSERT dbo.aiFindingTypes OFF;

SET IDENTITY_INSERT dbo.aiExecutions ON;
INSERT dbo.aiExecutions
 (aiExecutionID, aiAgentID, propositionID, resourceID, aiExecutionStatusTypeID, startedAt, completedAt, createdAt)
SELECT TOP (300)
    pr.propositionID,
    CASE WHEN pr.propositionID % 5 = 0 THEN 2 ELSE 1 END,
    pr.propositionID,
    pr.relatedResourceID,
    3,
    DATEADD(MINUTE, 20, pr.closedAt),
    DATEADD(MINUTE, 22, pr.closedAt),
    DATEADD(MINUTE, 20, pr.closedAt)
FROM dbo.propositions pr
WHERE pr.propositionStatusID = 3
ORDER BY pr.propositionID;
SET IDENTITY_INSERT dbo.aiExecutions OFF;

INSERT dbo.aiRequests (aiExecutionID, requestPayload, requestedAt, createdAt)
SELECT ae.aiExecutionID,
       N'{"task":"validate_proposition","propositionID":' + CAST(ae.propositionID AS NVARCHAR(10)) + N'}',
       ae.startedAt,
       ae.startedAt
FROM dbo.aiExecutions ae;

INSERT dbo.aiResponses (aiExecutionID, aiValidationResultType, responsePayload, confidenceScore, respondedAt, createdAt)
SELECT ae.aiExecutionID,
       CASE WHEN ae.propositionID % 2 = 0 THEN 1 ELSE 2 END,
       N'{"decision":"generated_by_seed"}',
       CAST(70 + (ae.aiExecutionID % 25) AS DECIMAL(5,2)),
       ae.completedAt,
       ae.completedAt
FROM dbo.aiExecutions ae;

INSERT dbo.aiFindings (aiExecutionID, severityLevelID, aiFindingTypeID, findingDetails, isBlocking, createdAt)
SELECT ae.aiExecutionID,
       CASE WHEN ae.aiExecutionID % 10 = 0 THEN 2 ELSE 1 END,
       ((ae.aiExecutionID - 1) % 3) + 1,
       N'Hallazgo sintético generado para pruebas de validación',
       0,
       ae.completedAt
FROM dbo.aiExecutions ae
WHERE ae.aiExecutionID % 4 = 0;

PRINT '== tablas complementarias insertadas ==';

/* ====== SECCIÓN 9 · VALIDACIONES OBLIGATORIAS DEL SEEDING ====== */

IF (SELECT COUNT_BIG(*) FROM dbo.players) <> 1000
    THROW 51001, 'Validación fallida: se esperaban exactamente 1000 jugadores.', 1;

IF (SELECT COUNT_BIG(*) FROM dbo.propositions) <> 5000
    THROW 51002, 'Validación fallida: se esperaban exactamente 5000 proposiciones.', 1;

IF (SELECT COUNT_BIG(*) FROM dbo.predictions) <> 250000
    THROW 51003, 'Validación fallida: se esperaban exactamente 250000 predicciones.', 1;

IF (SELECT COUNT_BIG(*) FROM dbo.balances) <> 1000
   OR (SELECT COUNT_BIG(*) FROM dbo.moneyBalance) <> 8000
   OR EXISTS
   (
       SELECT 1
       FROM dbo.balances b
       JOIN dbo.currencies c ON c.currencyID = b.currencyID
       WHERE c.currencyCode <> N'POINT'
   )
   OR EXISTS
   (
       SELECT 1
       FROM dbo.moneyBalance mb
       JOIN dbo.currencies c ON c.currencyID = mb.currencyID
       WHERE c.currencyCode = N'POINT'
   )
   OR EXISTS
   (
       SELECT 1
       FROM dbo.balances b
       LEFT JOIN
       (
           SELECT
               pd.playerID,
               SUM(CASE WHEN pr.propositionStatusID = 2 THEN stk.amount ELSE 0 END) AS reservedAmount
           FROM dbo.predictions pd
           JOIN dbo.propositions pr ON pr.propositionID = pd.propositionID
           JOIN dbo.predictionStakes stk ON stk.predictionID = pd.predictionID
           WHERE stk.currencyID = 1
           GROUP BY pd.playerID
       ) activity ON activity.playerID = b.playerID
       WHERE b.reservedAmount <> COALESCE(activity.reservedAmount, 0)
          OR b.availableAmount + b.reservedAmount
             <> 100.000000 + b.totalAmountEarned - b.totalAmountSpent
   )
   OR EXISTS
   (
       SELECT 1
       FROM dbo.moneyBalance mb
       LEFT JOIN
       (
           SELECT
               pd.playerID,
               stk.currencyID,
               SUM(stk.amount) AS reservedAmount
           FROM dbo.predictions pd
           JOIN dbo.propositions pr ON pr.propositionID = pd.propositionID
           JOIN dbo.predictionStakes stk ON stk.predictionID = pd.predictionID
           WHERE pr.propositionStatusID = 2
             AND stk.currencyID <> 1
           GROUP BY pd.playerID, stk.currencyID
       ) activity
         ON activity.playerID = mb.playerID
        AND activity.currencyID = mb.currencyID
       WHERE mb.reservedAmount <> COALESCE(activity.reservedAmount, 0)
          OR mb.totalDeposited
             <> mb.availableAmount + mb.reservedAmount + mb.totalWithdrawn
   )
    THROW 51018, 'Validación fallida: los balances de puntos y dinero real no están correctamente separados.', 1;

IF (SELECT COUNT_BIG(*) FROM dbo.propositions WHERE propositionStatusID = 2) <> 3000
   OR (SELECT COUNT_BIG(*) FROM dbo.propositions WHERE propositionStatusID = 3) <> 2000
   OR EXISTS
   (
       SELECT 1
       FROM dbo.propositions
       WHERE (propositionStatusID = 2 AND predictionsDeadline <= @seedNow)
          OR (propositionStatusID = 3 AND closedAt >= @seedNow)
   )
    THROW 51019, 'Validación fallida: la distribución o las fechas de proposiciones activas/finalizadas son incoherentes.', 1;

IF EXISTS
(
    SELECT propositionID
    FROM dbo.predictions
    GROUP BY propositionID
    HAVING COUNT_BIG(*) <> 50
       OR COUNT_BIG(DISTINCT playerID) <> 50
)
    THROW 51004, 'Validación fallida: cada proposición debe tener 50 predicciones de 50 jugadores distintos.', 1;

IF (SELECT COUNT_BIG(*) FROM dbo.predictionStakes) <> 250000
    THROW 51005, 'Validación fallida: cada predicción debe tener exactamente un stake.', 1;

IF EXISTS
(
    SELECT pd.predictionID
    FROM dbo.predictions pd
    LEFT JOIN dbo.predictionStakes stk ON stk.predictionID = pd.predictionID
    GROUP BY pd.predictionID
    HAVING COUNT(stk.predictionStakeID) <> 1
)
    THROW 51006, 'Validación fallida: hay predicciones sin stake o con más de un stake.', 1;

IF (SELECT COUNT_BIG(*) FROM dbo.propositionPredictionCurrencies) <> 7500
   OR (SELECT COUNT_BIG(DISTINCT propositionID) FROM dbo.propositionPredictionCurrencies) <> 5000
    THROW 51007, 'Validación fallida: la distribución de monedas permitidas no coincide con las 5000 proposiciones.', 1;

IF EXISTS
(
    SELECT 1
    FROM dbo.propositionPredictionCurrencies ppc
    JOIN dbo.currencies c ON c.currencyID = ppc.currencyID
    WHERE (ppc.propositionID % 4 = 0 AND c.currencyCode <> N'POINT')
       OR (ppc.propositionID % 4 = 1 AND c.currencyCode <> N'USD')
       OR (ppc.propositionID % 4 IN (2,3) AND c.currencyCode NOT IN (N'POINT', N'USD'))
)
    THROW 51020, 'Validación fallida: una proposición contiene una moneda distinta a la distribución configurada.', 1;

IF EXISTS
(
    SELECT 1
    FROM dbo.predictions pd
    JOIN dbo.predictionStakes stk ON stk.predictionID = pd.predictionID
    LEFT JOIN dbo.propositionPredictionCurrencies ppc
      ON ppc.propositionID = pd.propositionID
     AND ppc.currencyID = stk.currencyID
    WHERE ppc.propositionID IS NULL
)
    THROW 51008, 'Validación fallida: existe un stake en una moneda no permitida por su proposición.', 1;

IF EXISTS
(
    SELECT 1
    FROM dbo.predictions pd
    JOIN dbo.propositions pr ON pr.propositionID = pd.propositionID
    WHERE pd.predictedAt <= pr.acceptedAt
       OR pd.predictedAt >= pr.predictionsDeadline
       OR pd.predictedAt > @seedNow
       OR pd.createdAt <> pd.predictedAt
       OR (pr.propositionStatusID = 2 AND pd.predictionActive <> 1)
       OR (pr.propositionStatusID = 3 AND pd.predictionActive <> 0)
)
    THROW 51009, 'Validación fallida: hay timestamps o estados incoherentes en predictions.', 1;

IF EXISTS
(
    SELECT 1
    FROM dbo.predictionStakes stk
    JOIN dbo.currencies c ON c.currencyID = stk.currencyID
    LEFT JOIN dbo.currencyConfigurations cc
      ON cc.currencyID = stk.currencyID
     AND cc.isCurrent = 1
    WHERE stk.amount <= 0
       OR cc.currencyConfigurationID IS NULL
       OR stk.amount > cc.maxAmountPerPrediction
       OR (c.currencyCode = N'POINT' AND stk.amount <> 1.000000)
)
    THROW 51021, 'Validación fallida: existe un stake inválido o superior al máximo de su moneda.', 1;

IF (SELECT COUNT_BIG(*) FROM dbo.paymentAttempts) <> 5000
   OR (
       SELECT COUNT_BIG(DISTINCT targetEntityID)
       FROM dbo.paymentAttempts
       WHERE targetEntityType = N'proposition'
   ) <> 5000
    THROW 51010, 'Validación fallida: debe existir un paymentAttempt por cada proposición.', 1;

IF EXISTS
(
    SELECT 1
    FROM dbo.paymentAttempts pa
    LEFT JOIN dbo.propositions pr
      ON pa.targetEntityType = N'proposition'
     AND pa.targetEntityID = pr.propositionID
    JOIN dbo.currentExchangeRates cer
      ON cer.currentExchangeRateID = pa.exchangeRateID
    JOIN dbo.players payer ON payer.playerID = pa.playerID
    JOIN dbo.countries payerCountry ON payerCountry.countryID = payer.countryID
    JOIN dbo.currencies paymentCurrency ON paymentCurrency.currencyID = pa.currencyID
    WHERE pr.propositionID IS NULL
       OR cer.baseCurrencyID <> pa.currencyID
       OR cer.quoteCurrencyID <>
          CASE WHEN paymentCurrency.currencyCode = N'USD' THEN 1 ELSE 2 END
       OR cer.buyRate <> pa.exchangeRate
       OR pa.playerID <> pr.creatorPlayerID
       OR pa.sourceEntityType <> N'player'
       OR pa.sourceEntityID <> pa.playerID
       OR pa.currencyID <> payerCountry.localCurrencyID
       OR pa.amount <= 0
       OR pa.postedAt < pr.createdAt
       OR pa.postedAt > @seedNow
       OR pa.createdAt <> pa.postedAt
       OR (pr.propositionStatusID = 2 AND pa.operationTypeCodeID <> 3)
       OR (pr.propositionStatusID = 3 AND pa.operationTypeCodeID <> 4)
)
    THROW 51011, 'Validación fallida: hay pagos sin proposición o con una tasa de cambio incoherente.', 1;

IF (SELECT COUNT_BIG(*) FROM dbo.transactions) <> 20000
   OR EXISTS
   (
       SELECT pr.propositionID
       FROM dbo.propositions pr
       LEFT JOIN dbo.transactions tx ON tx.propositionID = pr.propositionID
       GROUP BY pr.propositionID
       HAVING COUNT_BIG(tx.transactionID) <> 4
          OR SUM(CASE WHEN tx.predictionID IS NOT NULL
                       AND tx.transactionTypeCodeID = 1 THEN 1 ELSE 0 END) <> 3
          OR SUM(CASE WHEN tx.predictionID IS NULL
                       AND tx.transactionTypeCodeID = 5 THEN 1 ELSE 0 END) <> 1
   )
    THROW 51022, 'Validación fallida: se esperaban cuatro transacciones trazables por proposición.', 1;

IF EXISTS
(
    SELECT 1
    FROM dbo.transactions tx
    JOIN dbo.propositions pr ON pr.propositionID = tx.propositionID
    LEFT JOIN dbo.predictions pd ON pd.predictionID = tx.predictionID
    WHERE (tx.predictionID IS NOT NULL
           AND (pd.predictionID IS NULL
                OR tx.playerID <> pd.playerID
                OR tx.propositionID <> pd.propositionID))
       OR tx.transactionDate < pr.createdAt
       OR tx.transactionDate > @seedNow
       OR tx.createdAt <> tx.transactionDate
)
    THROW 51012, 'Validación fallida: hay transacciones que no corresponden al jugador o proposición de la predicción.', 1;

IF EXISTS
(
    SELECT 1
    FROM dbo.transactions
    WHERE (predictionID IS NOT NULL AND balanceBefore - balanceAfter <> amount)
       OR (predictionID IS NULL AND balanceAfter - balanceBefore <> amount)
)
    THROW 51023, 'Validación fallida: los saldos antes/después no corresponden al monto de la transacción.', 1;

IF (SELECT COUNT_BIG(*) FROM dbo.propositionResult)
   <> (SELECT COUNT_BIG(*) FROM dbo.propositions WHERE propositionStatusID = 3)
    THROW 51013, 'Validación fallida: cada proposición finalizada debe tener un resultado.', 1;

IF EXISTS
(
    SELECT pr.propositionID
    FROM dbo.propositions pr
    LEFT JOIN dbo.propositionResult res ON res.propositionID = pr.propositionID
    GROUP BY pr.propositionID, pr.propositionStatusID
    HAVING (pr.propositionStatusID = 3 AND COUNT(res.propositionResultID) <> 1)
        OR (pr.propositionStatusID <> 3 AND COUNT(res.propositionResultID) <> 0)
)
    THROW 51024, 'Validación fallida: hay resultados ausentes, duplicados o asignados a proposiciones no finalizadas.', 1;

IF EXISTS
(
    SELECT 1
    FROM dbo.propositionResult res
    JOIN dbo.propositions pr ON pr.propositionID = res.propositionID
    WHERE res.evidenceResourceID <> pr.relatedResourceID
       OR res.validatedAt < pr.closedAt
       OR res.validatedAt > @seedNow
       OR res.createdAt <> res.validatedAt
       OR (res.resultTypeID = 1 AND res.propositionFulfilled <> 1)
       OR (res.resultTypeID = 2 AND res.propositionFulfilled <> 0)
)
    THROW 51029, 'Validación fallida: el resultado de una proposición no coincide con su evidencia, fecha o estado.', 1;

IF (SELECT COUNT_BIG(*) FROM dbo.predictionResults)
   <> (
       SELECT COUNT_BIG(*)
       FROM dbo.predictions pd
       JOIN dbo.propositions pr ON pr.propositionID = pd.propositionID
       WHERE pr.propositionStatusID = 3
   )
    THROW 51014, 'Validación fallida: cada predicción finalizada debe tener un resultado.', 1;

IF EXISTS
(
    SELECT pd.predictionID
    FROM dbo.predictions pd
    JOIN dbo.propositions pr ON pr.propositionID = pd.propositionID
    LEFT JOIN dbo.predictionResults res ON res.predictionID = pd.predictionID
    GROUP BY pd.predictionID, pr.propositionStatusID
    HAVING (pr.propositionStatusID = 3 AND COUNT(res.predictionResultID) <> 1)
        OR (pr.propositionStatusID <> 3 AND COUNT(res.predictionResultID) <> 0)
)
    THROW 51025, 'Validación fallida: hay resultados ausentes, duplicados o asignados a predicciones activas.', 1;

IF EXISTS
(
    SELECT 1
    FROM dbo.predictionResults res
    JOIN dbo.predictions pd ON pd.predictionID = res.predictionID
    JOIN dbo.propositions pr ON pr.propositionID = pd.propositionID
    WHERE res.determinedAt < pr.closedAt
       OR res.determinedAt > @seedNow
       OR res.createdAt <> res.determinedAt
       OR res.didWin <>
          CASE WHEN (pd.predictionTypeID = 1 AND pr.propositionID % 2 = 0)
                     OR (pd.predictionTypeID = 2 AND pr.propositionID % 2 <> 0)
               THEN 1 ELSE 0 END
)
    THROW 51030, 'Validación fallida: el resultado de una predicción no coincide con la proposición finalizada.', 1;

IF (SELECT COUNT_BIG(*) FROM dbo.predictionSettlements)
   <> (SELECT COUNT_BIG(*) FROM dbo.predictionResults WHERE didWin = 1)
   OR EXISTS
   (
       SELECT res.predictionResultID
       FROM dbo.predictionResults res
       LEFT JOIN dbo.predictionSettlements st
         ON st.predictionResultID = res.predictionResultID
       GROUP BY res.predictionResultID, res.didWin
       HAVING (res.didWin = 1 AND COUNT(st.predictionSettlementID) <> 1)
           OR (res.didWin = 0 AND COUNT(st.predictionSettlementID) <> 0)
   )
   OR EXISTS
   (
       SELECT 1
       FROM dbo.predictionSettlements st
       JOIN dbo.predictionResults res ON res.predictionResultID = st.predictionResultID
       JOIN dbo.predictions pd ON pd.predictionID = res.predictionID
       JOIN dbo.predictionStakes stk ON stk.predictionID = pd.predictionID
       WHERE st.recipientPlayerID <> pd.playerID
          OR st.settledByPlayerID <> pd.playerID
          OR st.currencyID <> stk.currencyID
          OR st.amount <> CAST(stk.amount * 1.8 AS DECIMAL(18,6))
   )
    THROW 51026, 'Validación fallida: las liquidaciones no corresponden exactamente a las predicciones ganadoras.', 1;

IF EXISTS
(
    SELECT 1
    FROM dbo.propositions pr
    JOIN dbo.resources r ON r.resourceID = pr.relatedResourceID
    JOIN dbo.players creator ON creator.playerID = pr.creatorPlayerID
    JOIN dbo.players targetPlayer ON targetPlayer.playerID = pr.targetPlayerID
    JOIN dbo.playersSocialNetwork psn ON psn.playerSocialNetworkID = r.playerSocialNetworkID
    WHERE pr.createdAt >= pr.acceptedAt
       OR pr.acceptedAt >= pr.predictionsDeadline
       OR pr.predictionsDeadline > pr.votingDeadline
       OR pr.votingDeadline >= pr.closedAt
       OR creator.createdAt > pr.createdAt
       OR targetPlayer.createdAt > pr.createdAt
       OR psn.playerID <> pr.targetPlayerID
       OR r.createdAt <> pr.createdAt
       OR r.capturedAt < r.createdAt
       OR (pr.propositionStatusID = 3 AND
           (r.eventOccurredAt IS NULL
            OR r.eventOccurredAt < pr.closedAt
            OR r.capturedAt < r.eventOccurredAt
            OR r.validationStatus <> N'validated'))
)
    THROW 51015, 'Validación fallida: hay proposiciones o recursos con timestamps incoherentes.', 1;

IF EXISTS
(
    SELECT 1
    FROM dbo.loginAttempts la
    JOIN dbo.players p ON p.playerID = la.playerID
    WHERE la.attemptedAt < p.createdAt
       OR la.attemptedAt > @seedNow
       OR la.createdAt <> la.attemptedAt
)
    THROW 51016, 'Validación fallida: hay intentos de login anteriores a la creación del jugador.', 1;

IF EXISTS
(
    SELECT 1
    FROM dbo.players
    WHERE createdAt > lastLoginAt
       OR lastLoginAt > @seedNow
)
    THROW 51027, 'Validación fallida: hay jugadores con una fecha de último acceso incoherente.', 1;

IF (SELECT COUNT_BIG(*) FROM dbo.playersSocialNetwork) <> 1000
   OR (SELECT COUNT_BIG(DISTINCT playerID) FROM dbo.playersSocialNetwork) <> 1000
   OR EXISTS
   (
       SELECT sn.socialNetworkID
       FROM dbo.socialNetworks sn
       LEFT JOIN dbo.playersSocialNetwork psn
         ON psn.socialNetworkID = sn.socialNetworkID
       GROUP BY sn.socialNetworkID
       HAVING COUNT_BIG(psn.playerSocialNetworkID) <> 250
   )
    THROW 51031, 'Validación fallida: las cuentas no están distribuidas correctamente entre las redes sociales.', 1;

IF (SELECT COUNT_BIG(*) FROM dbo.propositionVotes) <> 20000
   OR EXISTS
   (
       SELECT pr.propositionID
       FROM dbo.propositions pr
       LEFT JOIN dbo.propositionVotes pv ON pv.propositionID = pr.propositionID
       GROUP BY pr.propositionID
       HAVING COUNT_BIG(pv.propositionVoteID) <> 4
   )
   OR EXISTS
   (
       SELECT 1
       FROM dbo.propositionVotes pv
       JOIN dbo.propositions pr ON pr.propositionID = pv.propositionID
       WHERE pv.votedAt <= pr.createdAt
          OR pv.votedAt >= pr.acceptedAt
   )
    THROW 51028, 'Validación fallida: los votos no están distribuidos o fechados correctamente.', 1;

/* Toda tabla funcional creada por V001 debe quedar con al menos un registro.
   Se excluye únicamente la metadata interna de Flyway. */
CREATE TABLE #EmptyTables (tableName SYSNAME NOT NULL);

DECLARE @EmptyTableSql NVARCHAR(MAX);
DECLARE @EmptyTableList NVARCHAR(2048);

SELECT @EmptyTableSql = STRING_AGG(
    CAST(
        N'SELECT N''' + REPLACE(t.name, N'''', N'''''') + N''' '
        + N'WHERE NOT EXISTS (SELECT 1 FROM '
        + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N')'
        AS NVARCHAR(MAX)
    ),
    N' UNION ALL '
)
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = N'dbo'
  AND t.is_ms_shipped = 0
  AND t.name <> N'flyway_schema_history';

INSERT #EmptyTables (tableName)
EXEC sys.sp_executesql @EmptyTableSql;

IF EXISTS (SELECT 1 FROM #EmptyTables)
BEGIN
    SELECT @EmptyTableList = STRING_AGG(CAST(tableName AS NVARCHAR(MAX)), N', ')
    FROM #EmptyTables;

    SET @EmptyTableList = N'Validación fallida: tablas sin datos: ' + @EmptyTableList;
    THROW 51017, @EmptyTableList, 1;
END;

COMMIT TRANSACTION;

PRINT '== Gathel seeding: completado ==';
PRINT '== Validaciones superadas: 1000 jugadores, 5000 proposiciones, 250000 predicciones y 5000 pagos ==';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    PRINT CONCAT(
        N'ERROR DE SEEDING [',
        ERROR_NUMBER(),
        N'] línea ',
        ERROR_LINE(),
        N': ',
        ERROR_MESSAGE()
    );
    THROW;
END CATCH;
