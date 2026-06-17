/* ============================================================================
   GATHEL — Seeding · SQL Server 2022
   Archivo:  src/database/migrations/V2__seed_gathel.sql
   Requiere: V1__schema_gathel.sql aplicada.
   Login de demo: la contraseña de cada jugador es Palabra+Palabra+3 dígitos
   (ej. 'TigreLuna473'), guardada en texto en passwordHash.
============================================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF EXISTS (SELECT 1 FROM dbo.players)
BEGIN
    PRINT 'Seeding omitido: la base ya contiene datos.';
    RETURN;
END;

DECLARE @anchorPlayers DATETIME2 = '2025-01-01T00:00:00';
DECLARE @anchorProps   DATETIME2 = '2025-06-01T00:00:00';

/* ====== SECCIÓN 1 · CATÁLOGOS BASE ====== */

SET IDENTITY_INSERT dbo.currencies ON;
INSERT dbo.currencies (currencyID, currencyCode, currencyName, currencySymbol, isActive, createdAt) VALUES
 (1, N'POINT', N'Puntos Gathel',      N'pts', 1, SYSUTCDATETIME()),
 (2, N'USD',   N'US Dollar',          N'$',   1, SYSUTCDATETIME()),
 (3, N'EUR',   N'Euro',               N'€',   1, SYSUTCDATETIME()),
 (4, N'CRC',   N'Colón costarricense',N'₡',   1, SYSUTCDATETIME()),
 (5, N'MXN',   N'Peso mexicano',      N'$',   1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.currencies OFF;

SET IDENTITY_INSERT dbo.countries ON;
INSERT dbo.countries (countryID, countryName, iso2Code, iso3Code, localCurrencyID, isActive, createdAt) VALUES
 (1, N'Costa Rica',     'CR','CRI', 4, 1, SYSUTCDATETIME()),
 (2, N'Estados Unidos', 'US','USA', 2, 1, SYSUTCDATETIME()),
 (3, N'México',         'MX','MEX', 5, 1, SYSUTCDATETIME()),
 (4, N'España',         'ES','ESP', 3, 1, SYSUTCDATETIME()),
 (5, N'Argentina',      'AR','ARG', 2, 1, SYSUTCDATETIME()),
 (6, N'Colombia',       'CO','COL', 2, 1, SYSUTCDATETIME()),
 (7, N'Chile',          'CL','CHL', 2, 1, SYSUTCDATETIME()),
 (8, N'Perú',           'PE','PER', 2, 1, SYSUTCDATETIME());
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

SET IDENTITY_INSERT dbo.exchangePairs ON;
INSERT dbo.exchangePairs (exchangePairID, baseCurrencyID, quoteCurrencyID, isActive, createdAt) VALUES
 (1, 2, 4, 1, SYSUTCDATETIME()),
 (2, 1, 2, 1, SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.exchangePairs OFF;

SET IDENTITY_INSERT dbo.currentExchangeRates ON;
INSERT dbo.currentExchangeRates (currentExchangeRateID, exchangePairID, baseCurrencyID, quoteCurrencyID, buyRate, sellRate, sourceName, updatedAt) VALUES
 (1, 1, 2, 4, 512.000000, 518.000000, N'BCCR',     SYSUTCDATETIME()),
 (2, 2, 1, 2,   0.010000,   0.012000, N'Internal', SYSUTCDATETIME());
SET IDENTITY_INSERT dbo.currentExchangeRates OFF;

SET IDENTITY_INSERT dbo.currencyConfigurations ON;
INSERT dbo.currencyConfigurations
 (currencyConfigurationID, currencyID, configCode, configName, initialBalance, maxAmountPerPrediction,
  platformFeePercent, proposerFeePercent, validationFailurePenaltyPercent, propositionRejectionPenalty,
  validFrom, isCurrent, createdAt) VALUES
 (1, 1, N'POINT_DEFAULT', N'Configuración de puntos',   100.000000, 1.000000, 5.00, 3.00, 15.00, 1.000000, SYSUTCDATETIME(), 1, SYSUTCDATETIME()),
 (2, 2, N'USD_DEFAULT',   N'Configuración dinero real',   0.000000, 0.000000, 8.00, 4.00,  0.00, 0.000000, SYSUTCDATETIME(), 1, SYSUTCDATETIME());
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
FROM GENERATE_SERIES(1, 1000) AS g
JOIN @firstNames fn  ON fn.idx  = (CAST(g.value AS BIGINT)*48271 % 2147483647) % 24
JOIN @lastNames  ln  ON ln.idx  = (CAST(g.value AS BIGINT)*16807 % 2147483647) % 20
JOIN @lastNames  ln2 ON ln2.idx = (CAST(g.value AS BIGINT)*69621 % 2147483647) % 20
JOIN @pwWords    pw1 ON pw1.idx = (CAST(g.value AS BIGINT)*48271 % 2147483647) % 16
JOIN @pwWords    pw2 ON pw2.idx = (CAST(g.value AS BIGINT)*69621 % 2147483647) % 16;
SET IDENTITY_INSERT dbo.players OFF;

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
SELECT p.playerID, p.playerID, 1,
       N'ig_' + CAST(p.playerID AS NVARCHAR(10)),
       p.username,
       1, 1, p.createdAt, p.createdAt
FROM dbo.players p;
SET IDENTITY_INSERT dbo.playersSocialNetwork OFF;

INSERT dbo.balances
 (playerID, currencyID, availableAmount, reservedAmount, totalAmountEarned, totalAmountSpent, createdAt, isCurrent)
SELECT p.playerID, 1, 100.000000, 0, 0, 0, p.createdAt, 1
FROM dbo.players p;

INSERT dbo.moneyBalance
 (playerID, currencyID, availableAmount, reservedAmount, totalDeposited, totalWithdrawn, createdAt, isActive)
SELECT p.playerID, 2,
       CAST((CAST(p.playerID AS BIGINT)*16807 % 2147483647) % 50000 AS DECIMAL(18,6)) / 100.0,
       0,
       CAST((CAST(p.playerID AS BIGINT)*16807 % 2147483647) % 50000 AS DECIMAL(18,6)) / 100.0,
       0,
       p.createdAt, 1
FROM dbo.players p;
PRINT '== 1000 jugadores insertados ==';

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
FROM GENERATE_SERIES(1, 5000) AS g;
SET IDENTITY_INSERT dbo.resources OFF;

SET IDENTITY_INSERT dbo.propositions ON;
INSERT dbo.propositions
 (propositionID, creatorPlayerID, targetPlayerID, relatedResourceID, propositionStatusID,
  propositionText, predictionsDeadline, votingDeadline, acceptedAt, closedAt, createdAt, isActive)
SELECT
   g.value,
   (CAST(g.value AS BIGINT)*48271 % 2147483647) % 1000 + 1,
   CASE WHEN (CAST(g.value AS BIGINT)*16807 % 2147483647) % 5 = 0
        THEN (CAST(g.value AS BIGINT)*48271 % 2147483647) % 1000 + 1
        ELSE (CAST(g.value AS BIGINT)*16807 % 2147483647) % 1000 + 1 END,
   g.value,
   CASE WHEN g.value % 10 BETWEEN 0 AND 5 THEN 2
        WHEN g.value % 10 BETWEEN 6 AND 8 THEN 3
        ELSE 4 END,
   N'@usuario ' + v.val,
   DATEADD(MINUTE, ofs.m + 1500 + (((CAST(g.value AS BIGINT)*40692 % 2147483647) % 14) + 2) * 1440, @anchorProps),
   DATEADD(MINUTE, ofs.m + 1440, @anchorProps),
   DATEADD(MINUTE, ofs.m + 1500, @anchorProps),
   DATEADD(MINUTE, ofs.m + 1560 + (((CAST(g.value AS BIGINT)*40692 % 2147483647) % 14) + 2) * 1440, @anchorProps),
   DATEADD(MINUTE, ofs.m, @anchorProps),
   1
FROM GENERATE_SERIES(1, 5000) AS g
JOIN @verbs v ON v.idx = (CAST(g.value AS BIGINT)*69621 % 2147483647) % 8
CROSS APPLY (SELECT CAST((CAST(g.value AS BIGINT)*40692 % 2147483647) % 360000 AS INT) AS m) ofs;
SET IDENTITY_INSERT dbo.propositions OFF;
PRINT '== 5000 proposiciones + recursos insertados ==';

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
        (CAST(g.value AS BIGINT)*16807 % 2147483647) % 1000 + 1,
        (CAST(g.value AS BIGINT)*40692 % 2147483647) % 2 + 1,
        1,
        CONVERT(NVARCHAR(80), HASHBYTES('SHA2_256', CAST(g.value AS NVARCHAR(20))), 2),
        DATEADD(MINUTE,
                (CAST(g.value AS BIGINT)*69621 % 2147483647)
                   % (ABS(DATEDIFF(MINUTE, pr.acceptedAt, pr.predictionsDeadline)) + 1),
                pr.acceptedAt),
        DATEADD(MINUTE,
                (CAST(g.value AS BIGINT)*69621 % 2147483647)
                   % (ABS(DATEDIFF(MINUTE, pr.acceptedAt, pr.predictionsDeadline)) + 1),
                pr.acceptedAt),
        1
    FROM GENERATE_SERIES(@inicio, @fin) AS g
    JOIN dbo.propositions pr
      ON pr.propositionID = (CAST(g.value AS BIGINT)*48271 % 2147483647) % 5000 + 1;

    INSERT dbo.predictionStakes (predictionStakeID, predictionID, currencyID, amount, createdAt, isActive)
    SELECT
        g.value,
        g.value,
        CASE WHEN g.value % 2 = 0 THEN 1 ELSE 2 END,
        CASE WHEN g.value % 2 = 0 THEN 1.000000
             ELSE CAST((CAST(g.value AS BIGINT)*16807 % 2147483647) % 50 + 1 AS DECIMAL(18,6)) END,
        pd.createdAt,
        1
    FROM GENERATE_SERIES(@inicio, @fin) AS g
    JOIN dbo.predictions pd ON pd.predictionID = g.value;

    PRINT CONCAT('   lote predicciones ', @inicio, '..', @fin, ' OK');
    SET @inicio = @fin + 1;
END;
SET IDENTITY_INSERT dbo.predictions OFF;
PRINT '== 250 000 predicciones + stakes insertadas ==';

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
PRINT '== resultados y liquidaciones insertados ==';

/* ====== SECCIÓN 7 · PAGOS DE LAS PROPOSICIONES ====== */

INSERT dbo.transactions
 (playerID, transactionTypeCodeID, propositionID, predictionID, currencyID,
  amount, balanceBefore, balanceAfter, description, checksum, transactionDate, createdAt)
SELECT
    pr.creatorPlayerID,
    5,
    pr.propositionID,
    NULL,
    2,
    CAST((CAST(pr.propositionID AS BIGINT)*16807 % 2147483647) % 1000 AS DECIMAL(18,6)) / 100.0,
    100.000000, 100.000000,
    N'Comisión de plataforma por proposición ' + CAST(pr.propositionID AS NVARCHAR(10)),
    CONVERT(NVARCHAR(80), HASHBYTES('SHA2_256', CONCAT('tx-', pr.propositionID)), 2),
    DATEADD(HOUR, 7, pr.closedAt),
    DATEADD(HOUR, 7, pr.closedAt)
FROM dbo.propositions pr;

INSERT dbo.paymentAttempts
 (paymentMethodID, playerID, operationTypeCodeID, targetEntityType, targetEntityID,
  sourceEntityType, sourceEntityID, amount, currencyID, exchangeRate, exchangeRateID,
  paymentStatusID, result, requestPayload, responsePayload, transactionReference, checksum, postedAt, createdAt)
SELECT
    (pr.propositionID % 2) + 1,
    pr.creatorPlayerID,
    3,
    N'proposition', pr.propositionID,
    N'player',      pr.creatorPlayerID,
    CAST((CAST(pr.propositionID AS BIGINT)*16807 % 2147483647) % 1000 AS DECIMAL(18,6)) / 100.0,
    2,
    515.000000, 1,
    CASE WHEN pr.propositionID % 11 = 0 THEN 3 ELSE 2 END,
    CASE WHEN pr.propositionID % 11 = 0 THEN N'failed' ELSE N'completed' END,
    N'{"op":"fee","proposition":' + CAST(pr.propositionID AS NVARCHAR(10)) + N'}',
    N'{"status":"ok"}',
    N'ref_' + CAST(pr.propositionID AS NVARCHAR(10)),
    CONVERT(NVARCHAR(80), HASHBYTES('SHA2_256', CONCAT('pay-', pr.propositionID)), 2),
    DATEADD(HOUR, 7, pr.closedAt),
    DATEADD(HOUR, 7, pr.closedAt)
FROM dbo.propositions pr;
PRINT '== pagos (transactions + paymentAttempts) insertados ==';
PRINT '== Gathel seeding: completado ==';
