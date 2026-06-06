-- SQL Server 2022 script for Gathel - Gaming the life
SET NOCOUNT ON;
GO
IF DB_ID(N'Gathel - Gaming the life') IS NULL
    EXEC(N'CREATE DATABASE [Gathel - Gaming the life]');
GO
USE [Gathel - Gaming the life];
GO


-- =========================================
-- SEGURIDAD Y ACCESO
-- =========================================
CREATE TABLE userRoles (
    userRoleID BIGINT IDENTITY(1,1) NOT NULL,
    roleName NVARCHAR(30) NOT NULL,
    roleDescription NVARCHAR(150) NULL,
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_userRoles PRIMARY KEY (userRoleID),
    CONSTRAINT UQ_userRoles_roleName UNIQUE (roleName)
);
GO
CREATE TABLE permissions (
    permissionID BIGINT IDENTITY(1,1) NOT NULL,
    permissionName NVARCHAR(30) NOT NULL,
    permissionDescription NVARCHAR(150) NULL,
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_permissions PRIMARY KEY (permissionID),
    CONSTRAINT UQ_permissions_permissionName UNIQUE (permissionName)
);
GO
CREATE TABLE rolePermissions (
    userRoleID BIGINT NOT NULL,
    permissionID BIGINT NOT NULL,
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_rolePermissions PRIMARY KEY (userRoleID, permissionID)
);
GO
CREATE TABLE currencies (
    currencyID BIGINT IDENTITY(1,1) NOT NULL,
    currencyCode NVARCHAR(20) NOT NULL,
    currencyName NVARCHAR(45) NOT NULL,
    currencySymbol NVARCHAR(30) NULL,
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_currencies PRIMARY KEY (currencyID),
    CONSTRAINT UQ_currencies_currencyCode UNIQUE (currencyCode)
);
GO
CREATE TABLE countries (
    countryID BIGINT IDENTITY(1,1) NOT NULL,
    countryName NVARCHAR(50) NOT NULL,
    iso2Code CHAR(2) NOT NULL,
    iso3Code CHAR(3) NOT NULL,
    localCurrencyID BIGINT NULL,
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_countries PRIMARY KEY (countryID),
    CONSTRAINT UQ_countries_iso2Code UNIQUE (iso2Code),
    CONSTRAINT UQ_countries_iso3Code UNIQUE (iso3Code)
);
GO
CREATE TABLE players (
    playerID BIGINT IDENTITY(1,1) NOT NULL,
    countryID BIGINT NULL,
    email NVARCHAR(150) NOT NULL CHECK (email LIKE '%@%'),
    username NVARCHAR(50) NOT NULL,
    firstName NVARCHAR(40) NOT NULL,
    lastName NVARCHAR(40) NOT NULL,
    secondLastName NVARCHAR(40) NULL,
    passwordHash NVARCHAR(255) NOT NULL,
    isEmailVerified BIT NOT NULL DEFAULT (0),
    isActive BIT NOT NULL DEFAULT (1),
    lastLoginAt DATETIME2(7) NULL,
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_players PRIMARY KEY (playerID),
    CONSTRAINT UQ_players_email UNIQUE (email),
    CONSTRAINT UQ_players_username UNIQUE (username)
);
GO
CREATE TABLE systemUsers (
    playerID BIGINT NOT NULL,
    roleID BIGINT NOT NULL,
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_systemUsers PRIMARY KEY (playerID, roleID)
);
GO
CREATE TABLE loginAttempts (
    loginAttemptID BIGINT IDENTITY(1,1) NOT NULL,
    playerID BIGINT NULL,
    attemptedEmail NVARCHAR(150) NOT NULL CHECK (attemptedEmail LIKE '%@%'),
    ipAddress NVARCHAR(45) NOT NULL,
    wasSuccessful BIT NOT NULL,
    failureReason NVARCHAR(100) NULL,
    attemptedAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_loginAttempts PRIMARY KEY (loginAttemptID)
);
GO

-- =========================================
-- GEOGRAFÍA Y MONEDAS
-- =========================================
CREATE TABLE exchangePairs (
    exchangePairID BIGINT IDENTITY(1,1) NOT NULL,
    baseCurrencyID BIGINT NOT NULL,
    quoteCurrencyID BIGINT NOT NULL,
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_exchangePairs PRIMARY KEY (exchangePairID),
    CONSTRAINT UQ_exchangePairs_baseCurrencyID_quoteCurrencyID UNIQUE (baseCurrencyID, quoteCurrencyID),
    CONSTRAINT CK_exchangePairs_differentCurrencies CHECK (baseCurrencyID <> quoteCurrencyID)
);
GO
CREATE TABLE currentExchangeRates (
    currentExchangeRateID BIGINT IDENTITY(1,1) NOT NULL,
    exchangePairID BIGINT NOT NULL,
    baseCurrencyID BIGINT NOT NULL,
    quoteCurrencyID BIGINT NOT NULL,
    buyRate DECIMAL(18,6) NOT NULL CHECK (buyRate > 0),
    sellRate DECIMAL(18,6) NOT NULL CHECK (sellRate > 0),
    sourceName NVARCHAR(50) NOT NULL,
    updatedAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_currentExchangeRates PRIMARY KEY (currentExchangeRateID),
    CONSTRAINT UQ_currentExchangeRates_exchangePairID UNIQUE (exchangePairID),
    CONSTRAINT CK_currentExchangeRates_1 CHECK (baseCurrencyID <> quoteCurrencyID)
);
GO
CREATE TABLE historicalExchangeRates (
    historicalExchangeRateID BIGINT IDENTITY(1,1) NOT NULL,
    currentExchangeRateID BIGINT NOT NULL,
    buyRate DECIMAL(18,6) NOT NULL CHECK (buyRate > 0),
    sellRate DECIMAL(18,6) NOT NULL CHECK (sellRate > 0),
    validFrom DATETIME2(7) NOT NULL,
    validTo DATETIME2(7) NULL,
    recordedAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_historicalExchangeRates PRIMARY KEY (historicalExchangeRateID),
    CONSTRAINT CK_historicalExchangeRates_1 CHECK (validTo IS NULL OR validTo >= validFrom)
);
GO

-- =========================================
-- CONFIGURACIÓN DE PUNTOS
-- =========================================
CREATE TABLE systemConfigurations (
    systemConfigurationID BIGINT IDENTITY(1,1) NOT NULL,
    configCode NVARCHAR(50) NOT NULL,
    configValue NVARCHAR(255) NOT NULL,
    configDescription NVARCHAR(200) NULL,
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_systemConfigurations PRIMARY KEY (systemConfigurationID),
    CONSTRAINT UQ_systemConfigurations_configCode UNIQUE (configCode)
);
GO
CREATE TABLE pointConfigurations (
    pointConfigurationID BIGINT IDENTITY(1,1) NOT NULL,
    configCode NVARCHAR(30) NOT NULL,
    configName NVARCHAR(80) NOT NULL,
    initialBalance INT NOT NULL CHECK (initialBalance >= 0),
    maxPointsPerPrediction INT NOT NULL CHECK (maxPointsPerPrediction >= 0 AND maxPointsPerPrediction <= 1),
    platformFeePercent DECIMAL(5,2) NOT NULL CHECK (platformFeePercent >= 0 AND platformFeePercent <= 100),
    proposerFeePercent DECIMAL(5,2) NOT NULL CHECK (proposerFeePercent >= 0 AND proposerFeePercent <= 100),
    validationFailurePenaltyPercent DECIMAL(5,2) NOT NULL CHECK (validationFailurePenaltyPercent >= 0 AND validationFailurePenaltyPercent <= 100),
    propositionRejectionPenalty INT NOT NULL CHECK (propositionRejectionPenalty >= 0),
    validFrom DATETIME2(7) NOT NULL,
    validTo DATETIME2(7) NULL,
    isCurrent BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_pointConfigurations PRIMARY KEY (pointConfigurationID),
    CONSTRAINT UQ_pointConfigurations_configCode UNIQUE (configCode),
    CONSTRAINT CK_pointConfigurations_1 CHECK (validTo IS NULL OR validTo >= validFrom)
);
GO
CREATE TABLE pointBalances (
    pointBalanceID BIGINT IDENTITY(1,1) NOT NULL,
    playerID BIGINT NOT NULL,
    availablePoints INT NOT NULL CHECK (availablePoints >= 0),
    reservedPoints INT NOT NULL CHECK (reservedPoints >= 0),
    totalPointsEarned INT NOT NULL CHECK (totalPointsEarned >= 0),
    totalPointsSpent INT NOT NULL CHECK (totalPointsSpent >= 0),
    lastUpdatedAt DATETIME2(7) NULL,
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_pointBalances PRIMARY KEY (pointBalanceID),
    CONSTRAINT UQ_pointBalances_playerID UNIQUE (playerID)
);
GO
CREATE TABLE pointTransactionTypes (
    pointTransactionTypeCodeID BIGINT IDENTITY(1,1) NOT NULL,
    typeName NVARCHAR(50) NOT NULL,
    typeDescription NVARCHAR(150) NULL,
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_pointTransactionTypes PRIMARY KEY (pointTransactionTypeCodeID),
    CONSTRAINT UQ_pointTransactionTypes_typeName UNIQUE (typeName)
);
GO
CREATE TABLE pointTransactions (
    pointTransactionID BIGINT IDENTITY(1,1) NOT NULL,
    playerID BIGINT NOT NULL,
    pointTransactionTypeCodeID BIGINT NOT NULL,
    propositionID BIGINT NULL,
    predictionID BIGINT NULL,
    pointsAmount INT NOT NULL CHECK (pointsAmount >= 0),
    balanceBefore INT NOT NULL CHECK (balanceBefore >= 0),
    balanceAfter INT NOT NULL CHECK (balanceAfter >= 0),
    description NVARCHAR(200) NULL,
    checksum NVARCHAR(80) NULL,
    transactionDate DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_pointTransactions PRIMARY KEY (pointTransactionID),
    CONSTRAINT CK_pointTransactions_1 CHECK ((propositionID IS NOT NULL OR predictionID IS NOT NULL))
);
GO

-- =========================================
-- MÉTODOS DE PAGO Y DINERO REAL
-- =========================================
CREATE TABLE providers (
    providerID BIGINT IDENTITY(1,1) NOT NULL,
    providerName NVARCHAR(50) NOT NULL,
    providerDescription NVARCHAR(150) NULL,
    isActive BIT NOT NULL DEFAULT (1),
    CONSTRAINT PK_providers PRIMARY KEY (providerID),
    CONSTRAINT UQ_providers_providerName UNIQUE (providerName)
);
GO
CREATE TABLE paymentTransactionsStatus (
    statusCodeID BIGINT IDENTITY(1,1) NOT NULL,
    statusName NVARCHAR(50) NOT NULL,
    statusDescription NVARCHAR(150) NULL,
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_paymentTransactionsStatus PRIMARY KEY (statusCodeID),
    CONSTRAINT UQ_paymentTransactionsStatus_statusName UNIQUE (statusName)
);
GO
CREATE TABLE paymentOperationTypes (
    operationTypeCodeID BIGINT IDENTITY(1,1) NOT NULL,
    operationTypeName NVARCHAR(50) NOT NULL,
    operationTypeDescription NVARCHAR(150) NULL,
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_paymentOperationTypes PRIMARY KEY (operationTypeCodeID),
    CONSTRAINT UQ_paymentOperationTypes_operationTypeName UNIQUE (operationTypeName)
);
GO
CREATE TABLE paymentMethods (
    paymentMethodID BIGINT IDENTITY(1,1) NOT NULL,
    providerID BIGINT NOT NULL,
    methodName NVARCHAR(50) NOT NULL,
    methodDescription NVARCHAR(150) NULL,
    apiURL NVARCHAR(255) NULL,
    config NVARCHAR(MAX) NULL,
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_paymentMethods PRIMARY KEY (paymentMethodID),
    CONSTRAINT UQ_paymentMethods_methodName UNIQUE (methodName),
    CONSTRAINT CK_paymentMethods_1 CHECK (config IS NULL OR ISJSON(config) = 1)
);
GO
CREATE TABLE paymentAttempts (
    paymentAttemptID BIGINT IDENTITY(1,1) NOT NULL,
    paymentMethodID BIGINT NOT NULL,
    playerID BIGINT NOT NULL,
    operationTypeCodeID BIGINT NOT NULL,
    targetEntityType NVARCHAR(50) NULL,
    targetEntityID BIGINT NULL,
    sourceEntityType NVARCHAR(50) NULL,
    sourceEntityID BIGINT NULL,
    amount DECIMAL(18,6) NOT NULL CHECK (amount >= 0),
    currencyID BIGINT NOT NULL,
    exchangeRate DECIMAL(18,6) NOT NULL CHECK (exchangeRate >= 0),
    exchangeRateID BIGINT NULL,
    paymentStatusID BIGINT NOT NULL,
    result NVARCHAR(30) NOT NULL,
    requestPayload NVARCHAR(MAX) NULL,
    responsePayload NVARCHAR(MAX) NULL,
    transactionReference NVARCHAR(150) NOT NULL,
    checksum NVARCHAR(80) NULL,
    postedAt DATETIME2(7) NULL,
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_paymentAttempts PRIMARY KEY (paymentAttemptID),
    CONSTRAINT CK_paymentAttempts_1 CHECK (requestPayload IS NULL OR ISJSON(requestPayload) = 1),
    CONSTRAINT CK_paymentAttempts_2 CHECK (responsePayload IS NULL OR ISJSON(responsePayload) = 1)
);
GO
CREATE TABLE moneyBalance (
    moneyBalanceID BIGINT IDENTITY(1,1) NOT NULL,
    playerID BIGINT NOT NULL,
    currencyID BIGINT NOT NULL,
    availableAmount DECIMAL(18,6) NOT NULL CHECK (availableAmount >= 0),
    reservedAmount DECIMAL(18,6) NOT NULL CHECK (reservedAmount >= 0),
    totalDeposited DECIMAL(18,6) NOT NULL CHECK (totalDeposited >= 0),
    totalWithdrawn DECIMAL(18,6) NOT NULL CHECK (totalWithdrawn >= 0),
    lastUpdatedAt DATETIME2(7) NULL,
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_moneyBalance PRIMARY KEY (moneyBalanceID),
    CONSTRAINT UQ_moneyBalance_playerID_currencyID UNIQUE (playerID, currencyID)
);
GO

-- =========================================
-- REDES SOCIALES
-- =========================================
CREATE TABLE socialNetworks (
    socialNetworkID BIGINT IDENTITY(1,1) NOT NULL,
    socialNetworkName NVARCHAR(50) NOT NULL,
    socialNetworkDescription NVARCHAR(150) NULL,
    baseURL NVARCHAR(150) NULL,
    apiURL NVARCHAR(255) NULL,
    config NVARCHAR(MAX) NULL,
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_socialNetworks PRIMARY KEY (socialNetworkID),
    CONSTRAINT UQ_socialNetworks_socialNetworkName UNIQUE (socialNetworkName),
    CONSTRAINT CK_socialNetworks_1 CHECK (config IS NULL OR ISJSON(config) = 1)
);
GO
CREATE TABLE playersSocialNetwork (
    playerSocialNetworkID BIGINT IDENTITY(1,1) NOT NULL,
    playerID BIGINT NOT NULL,
    socialNetworkID BIGINT NOT NULL,
    externalAccountID NVARCHAR(150) NOT NULL,
    externalUsername NVARCHAR(100) NULL,
    accessTokenHash NVARCHAR(500) NULL,
    tokenExpiresAt DATETIME2(7) NULL,
    isAuthorized BIT NOT NULL DEFAULT (0),
    isActive BIT NOT NULL DEFAULT (1),
    linkedAt DATETIME2(7) NULL,
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_playersSocialNetwork PRIMARY KEY (playerSocialNetworkID),
    CONSTRAINT UQ_playersSocialNetwork_player_social_external UNIQUE (playerID, socialNetworkID, externalAccountID)
);
GO
CREATE TABLE resourceTypes (
    resourceTypeID BIGINT IDENTITY(1,1) NOT NULL,
    resourceTypeName NVARCHAR(50) NOT NULL,
    resourceTypeDescription NVARCHAR(150) NULL,
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_resourceTypes PRIMARY KEY (resourceTypeID),
    CONSTRAINT UQ_resourceTypes_resourceTypeName UNIQUE (resourceTypeName)
);
GO
CREATE TABLE resources (
    resourceID BIGINT IDENTITY(1,1) NOT NULL,
    playerSocialNetworkID BIGINT NOT NULL,
    resourceTypeID BIGINT NOT NULL,
    externalResourceID NVARCHAR(150) NOT NULL,
    contentURL NVARCHAR(500) NOT NULL,
    contentHash NVARCHAR(80) NULL,
    capturedAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    eventOccurredAt DATETIME2(7) NULL,
    validationStatus NVARCHAR(30) NOT NULL DEFAULT ('PENDING'),
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_resources PRIMARY KEY (resourceID),
    CONSTRAINT UQ_resources_playerSocialNetworkID_externalResourceID UNIQUE (playerSocialNetworkID, externalResourceID)
);
GO

-- =========================================
-- NÚCLEO DEL JUEGO: PROPOSICIONES
-- =========================================
CREATE TABLE propositionStatus (
    propositionStatusID BIGINT IDENTITY(1,1) NOT NULL,
    statusName NVARCHAR(50) NOT NULL,
    statusDescription NVARCHAR(150) NULL,
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_propositionStatus PRIMARY KEY (propositionStatusID),
    CONSTRAINT UQ_propositionStatus_statusName UNIQUE (statusName)
);
GO
CREATE TABLE propositions (
    propositionID BIGINT IDENTITY(1,1) NOT NULL,
    creatorPlayerID BIGINT NOT NULL,
    targetPlayerID BIGINT NOT NULL,
    relatedResourceID BIGINT NULL,
    propositionStatusID BIGINT NOT NULL,
    propositionText NVARCHAR(500) NOT NULL,
    predictionsDeadline DATETIME2(7) NULL,
    votingDeadline DATETIME2(7) NULL,
    acceptedAt DATETIME2(7) NULL,
    closedAt DATETIME2(7) NULL,
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_propositions PRIMARY KEY (propositionID)
);
GO
CREATE TABLE propositionVotes (
    propositionVoteID BIGINT IDENTITY(1,1) NOT NULL,
    propositionID BIGINT NOT NULL,
    voterPlayerID BIGINT NOT NULL,
    votedAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_propositionVotes PRIMARY KEY (propositionVoteID),
    CONSTRAINT UQ_propositionVotes_propositionID_voterPlayerID UNIQUE (propositionID, voterPlayerID)
);
GO
CREATE TABLE propositionStatusLogs (
    propositionStatusLogID BIGINT IDENTITY(1,1) NOT NULL,
    propositionID BIGINT NOT NULL,
    previousStatusCodeID BIGINT NULL,
    currentStatusCodeID BIGINT NOT NULL,
    changeDetails NVARCHAR(250) NULL,
    changedByPlayerID BIGINT NULL,
    changedAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_propositionStatusLogs PRIMARY KEY (propositionStatusLogID)
);
GO

-- =========================================
-- PREDICCIONES
-- =========================================
CREATE TABLE predictionTypes (
    predictionTypeID BIGINT IDENTITY(1,1) NOT NULL,
    predictionTypeName NVARCHAR(50) NOT NULL,
    predictionTypeDescription NVARCHAR(150) NULL,
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_predictionTypes PRIMARY KEY (predictionTypeID),
    CONSTRAINT UQ_predictionTypes_predictionTypeName UNIQUE (predictionTypeName)
);
GO
CREATE TABLE predictions (
    predictionID BIGINT IDENTITY(1,1) NOT NULL,
    propositionID BIGINT NOT NULL,
    playerID BIGINT NOT NULL,
    predictionTypeID BIGINT NOT NULL,
    predictionActive BIT NOT NULL DEFAULT (1),
    pointsRisked INT NULL CHECK (pointsRisked IS NULL OR pointsRisked BETWEEN 0 AND 1),
    moneyRisked DECIMAL(18,6) NULL CHECK (moneyRisked IS NULL OR moneyRisked >= 0),
    currencyID BIGINT NULL,
    exchangeRate DECIMAL(18,6) NULL CHECK (exchangeRate IS NULL OR exchangeRate >= 0),
    exchangeRateID BIGINT NULL,
    checksum NVARCHAR(80) NULL,
    predictedAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_predictions PRIMARY KEY (predictionID),
    CONSTRAINT CK_predictions_1 CHECK ((pointsRisked IS NOT NULL AND moneyRisked IS NULL AND currencyID IS NULL AND exchangeRate IS NULL AND exchangeRateID IS NULL) OR (pointsRisked IS NULL AND moneyRisked IS NOT NULL AND currencyID IS NOT NULL AND exchangeRate IS NOT NULL AND exchangeRateID IS NOT NULL))
);
GO
CREATE TABLE predictionAmountLogs (
    predictionAmountLogID BIGINT IDENTITY(1,1) NOT NULL,
    predictionID BIGINT NOT NULL,
    previousPointsAmount INT NULL CHECK (previousPointsAmount IS NULL OR previousPointsAmount >= 0),
    currentPointsAmount INT NULL CHECK (currentPointsAmount IS NULL OR currentPointsAmount >= 0),
    previousMoneyAmount DECIMAL(18,6) NULL CHECK (previousMoneyAmount IS NULL OR previousMoneyAmount >= 0),
    currentMoneyAmount DECIMAL(18,6) NULL CHECK (currentMoneyAmount IS NULL OR currentMoneyAmount >= 0),
    changedAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_predictionAmountLogs PRIMARY KEY (predictionAmountLogID)
);
GO
CREATE TABLE predictionOutcomes (
    predictionOutcomeID BIGINT IDENTITY(1,1) NOT NULL,
    predictionID BIGINT NOT NULL,
    didWin BIT NOT NULL,
    pointsWon INT NOT NULL CHECK (pointsWon >= 0),
    moneyWon DECIMAL(18,6) NOT NULL CHECK (moneyWon >= 0),
    currencyID BIGINT NULL,
    platformFeeApplied DECIMAL(18,6) NULL CHECK (platformFeeApplied IS NULL OR platformFeeApplied >= 0),
    proposerFeeApplied DECIMAL(18,6) NULL CHECK (proposerFeeApplied IS NULL OR proposerFeeApplied >= 0),
    settlementStatus NVARCHAR(30) NOT NULL DEFAULT ('PENDING'),
    settledByPlayerID BIGINT NULL,
    settledAt DATETIME2(7) NULL,
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_predictionOutcomes PRIMARY KEY (predictionOutcomeID),
    CONSTRAINT UQ_predictionOutcomes_predictionID UNIQUE (predictionID),
    CONSTRAINT CK_predictionOutcomes_winnerPrize CHECK (didWin = 0 OR pointsWon > 0 OR moneyWon > 0)
);
GO

-- =========================================
-- VALIDACIÓN DE RESULTADOS
-- =========================================
CREATE TABLE propositionResultStatus (
    resultStatusID BIGINT IDENTITY(1,1) NOT NULL,
    statusName NVARCHAR(50) NOT NULL,
    statusDescription NVARCHAR(150) NULL,
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_propositionResultStatus PRIMARY KEY (resultStatusID),
    CONSTRAINT UQ_propositionResultStatus_statusName UNIQUE (statusName)
);
GO
CREATE TABLE propositionResult (
    propositionResultID BIGINT IDENTITY(1,1) NOT NULL,
    propositionID BIGINT NOT NULL,
    resultStatusID BIGINT NOT NULL,
    propositionFulfilled BIT NULL,
    evidenceResourceID BIGINT NULL,
    validatedAt DATETIME2(7) NULL,
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_propositionResult PRIMARY KEY (propositionResultID),
    CONSTRAINT UQ_propositionResult_propositionID UNIQUE (propositionID)
);
GO

-- =========================================
-- BITÁCORA DE PROCESOS
-- =========================================
CREATE TABLE sourceTypes (
    sourceTypeID BIGINT IDENTITY(1,1) NOT NULL,
    sourceTypeName NVARCHAR(50) NOT NULL,
    sourceTypeDescription NVARCHAR(150) NULL,
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_sourceTypes PRIMARY KEY (sourceTypeID),
    CONSTRAINT UQ_sourceTypes_sourceTypeName UNIQUE (sourceTypeName)
);
GO
CREATE TABLE processLogs (
    processLogID BIGINT IDENTITY(1,1) NOT NULL,
    processType NVARCHAR(50) NOT NULL,
    processID BIGINT NOT NULL,
    sourceTypeID BIGINT NOT NULL,
    contentURL NVARCHAR(500) NULL,
    requestPayload NVARCHAR(MAX) NULL,
    responsePayload NVARCHAR(MAX) NULL,
    result NVARCHAR(30) NOT NULL,
    executedAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_processLogs PRIMARY KEY (processLogID),
    CONSTRAINT CK_processLogs_1 CHECK (requestPayload IS NULL OR ISJSON(requestPayload) = 1),
    CONSTRAINT CK_processLogs_2 CHECK (responsePayload IS NULL OR ISJSON(responsePayload) = 1)
);
GO

-- =========================================
-- LOG GENERAL
-- =========================================
CREATE TABLE changeSources (
    sourceCode NVARCHAR(30) NOT NULL,
    sourceName NVARCHAR(50) NOT NULL,
    sourceDescription NVARCHAR(150) NULL,
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_changeSources PRIMARY KEY (sourceCode),
    CONSTRAINT UQ_changeSources_sourceName UNIQUE (sourceName)
);
GO
CREATE TABLE auditLogs (
    auditLogID BIGINT IDENTITY(1,1) NOT NULL,
    entityName NVARCHAR(60) NOT NULL,
    entityID BIGINT NOT NULL,
    actionCode NVARCHAR(30) NOT NULL,
    changeDetails NVARCHAR(500) NULL,
    previousValues NVARCHAR(MAX) NULL,
    newValues NVARCHAR(MAX) NULL,
    changeSourceCode NVARCHAR(30) NOT NULL,
    performedByPlayerID BIGINT NULL,
    performedAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_auditLogs PRIMARY KEY (auditLogID),
    CONSTRAINT CK_auditLogs_1 CHECK (previousValues IS NULL OR ISJSON(previousValues) = 1),
    CONSTRAINT CK_auditLogs_2 CHECK (newValues IS NULL OR ISJSON(newValues) = 1)
);
GO

-- =========================================
-- COMERCIOS AFILIADOS
-- =========================================
CREATE TABLE merchants (
    merchantID BIGINT IDENTITY(1,1) NOT NULL,
    merchantName NVARCHAR(100) NOT NULL,
    countryID BIGINT NOT NULL,
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_merchants PRIMARY KEY (merchantID),
    CONSTRAINT UQ_merchants_merchantName UNIQUE (merchantName)
);
GO
CREATE TABLE merchantProducts (
    merchantProductID BIGINT IDENTITY(1,1) NOT NULL,
    merchantID BIGINT NOT NULL,
    productCode NVARCHAR(50) NOT NULL,
    productName NVARCHAR(120) NOT NULL,
    productDescription NVARCHAR(500) NULL,
    pointsCost INT NOT NULL CHECK (pointsCost >= 0),
    isActive BIT NOT NULL DEFAULT (1),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_merchantProducts PRIMARY KEY (merchantProductID),
    CONSTRAINT UQ_merchantProducts_merchantID_productCode UNIQUE (merchantID, productCode)
);
GO
CREATE TABLE pointRedemption (
    pointRedemptionID BIGINT IDENTITY(1,1) NOT NULL,
    playerID BIGINT NOT NULL,
    merchantProductID BIGINT NOT NULL,
    pointsSpent INT NOT NULL CHECK (pointsSpent >= 0),
    redemptionCode NVARCHAR(80) NOT NULL,
    redeemedAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    createdAt DATETIME2(7) NOT NULL DEFAULT SYSDATETIME(),
    updatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_pointRedemption PRIMARY KEY (pointRedemptionID),
    CONSTRAINT UQ_pointRedemption_redemptionCode UNIQUE (redemptionCode)
);
GO

-- =========================================
-- FK CONSTRAINTS
-- =========================================
ALTER TABLE rolePermissions WITH CHECK ADD CONSTRAINT FK_rolePermissions_userRoleID_userRoles FOREIGN KEY (userRoleID) REFERENCES userRoles(userRoleID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE rolePermissions CHECK CONSTRAINT FK_rolePermissions_userRoleID_userRoles;
ALTER TABLE rolePermissions WITH CHECK ADD CONSTRAINT FK_rolePermissions_permissionID_permissions FOREIGN KEY (permissionID) REFERENCES permissions(permissionID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE rolePermissions CHECK CONSTRAINT FK_rolePermissions_permissionID_permissions;
ALTER TABLE countries WITH CHECK ADD CONSTRAINT FK_countries_localCurrencyID_currencies FOREIGN KEY (localCurrencyID) REFERENCES currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE countries CHECK CONSTRAINT FK_countries_localCurrencyID_currencies;
ALTER TABLE players WITH CHECK ADD CONSTRAINT FK_players_countryID_countries FOREIGN KEY (countryID) REFERENCES countries(countryID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE players CHECK CONSTRAINT FK_players_countryID_countries;
ALTER TABLE systemUsers WITH CHECK ADD CONSTRAINT FK_systemUsers_playerID_players FOREIGN KEY (playerID) REFERENCES players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE systemUsers CHECK CONSTRAINT FK_systemUsers_playerID_players;
ALTER TABLE systemUsers WITH CHECK ADD CONSTRAINT FK_systemUsers_roleID_userRoles FOREIGN KEY (roleID) REFERENCES userRoles(userRoleID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE systemUsers CHECK CONSTRAINT FK_systemUsers_roleID_userRoles;
ALTER TABLE loginAttempts WITH CHECK ADD CONSTRAINT FK_loginAttempts_playerID_players FOREIGN KEY (playerID) REFERENCES players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE loginAttempts CHECK CONSTRAINT FK_loginAttempts_playerID_players;
ALTER TABLE exchangePairs WITH CHECK ADD CONSTRAINT FK_exchangePairs_baseCurrencyID_currencies FOREIGN KEY (baseCurrencyID) REFERENCES currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE exchangePairs CHECK CONSTRAINT FK_exchangePairs_baseCurrencyID_currencies;
ALTER TABLE exchangePairs WITH CHECK ADD CONSTRAINT FK_exchangePairs_quoteCurrencyID_currencies FOREIGN KEY (quoteCurrencyID) REFERENCES currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE exchangePairs CHECK CONSTRAINT FK_exchangePairs_quoteCurrencyID_currencies;
ALTER TABLE currentExchangeRates WITH CHECK ADD CONSTRAINT FK_currentExchangeRates_exchangePairID_exchangePairs FOREIGN KEY (exchangePairID) REFERENCES exchangePairs(exchangePairID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE currentExchangeRates CHECK CONSTRAINT FK_currentExchangeRates_exchangePairID_exchangePairs;
ALTER TABLE currentExchangeRates WITH CHECK ADD CONSTRAINT FK_currentExchangeRates_baseCurrencyID_currencies FOREIGN KEY (baseCurrencyID) REFERENCES currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE currentExchangeRates CHECK CONSTRAINT FK_currentExchangeRates_baseCurrencyID_currencies;
ALTER TABLE currentExchangeRates WITH CHECK ADD CONSTRAINT FK_currentExchangeRates_quoteCurrencyID_currencies FOREIGN KEY (quoteCurrencyID) REFERENCES currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE currentExchangeRates CHECK CONSTRAINT FK_currentExchangeRates_quoteCurrencyID_currencies;
ALTER TABLE historicalExchangeRates WITH CHECK ADD CONSTRAINT FK_historicalExchangeRates_currentExchangeRateID_currentExchangeRates FOREIGN KEY (currentExchangeRateID) REFERENCES currentExchangeRates(currentExchangeRateID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE historicalExchangeRates CHECK CONSTRAINT FK_historicalExchangeRates_currentExchangeRateID_currentExchangeRates;
ALTER TABLE pointBalances WITH CHECK ADD CONSTRAINT FK_pointBalances_playerID_players FOREIGN KEY (playerID) REFERENCES players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pointBalances CHECK CONSTRAINT FK_pointBalances_playerID_players;
ALTER TABLE pointTransactions WITH CHECK ADD CONSTRAINT FK_pointTransactions_playerID_players FOREIGN KEY (playerID) REFERENCES players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pointTransactions CHECK CONSTRAINT FK_pointTransactions_playerID_players;
ALTER TABLE pointTransactions WITH CHECK ADD CONSTRAINT FK_pointTransactions_pointTransactionTypeCodeID_pointTransactionTypes FOREIGN KEY (pointTransactionTypeCodeID) REFERENCES pointTransactionTypes(pointTransactionTypeCodeID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pointTransactions CHECK CONSTRAINT FK_pointTransactions_pointTransactionTypeCodeID_pointTransactionTypes;
ALTER TABLE pointTransactions WITH CHECK ADD CONSTRAINT FK_pointTransactions_propositionID_propositions FOREIGN KEY (propositionID) REFERENCES propositions(propositionID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pointTransactions CHECK CONSTRAINT FK_pointTransactions_propositionID_propositions;
ALTER TABLE pointTransactions WITH CHECK ADD CONSTRAINT FK_pointTransactions_predictionID_predictions FOREIGN KEY (predictionID) REFERENCES predictions(predictionID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pointTransactions CHECK CONSTRAINT FK_pointTransactions_predictionID_predictions;
ALTER TABLE paymentMethods WITH CHECK ADD CONSTRAINT FK_paymentMethods_providerID_providers FOREIGN KEY (providerID) REFERENCES providers(providerID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE paymentMethods CHECK CONSTRAINT FK_paymentMethods_providerID_providers;
ALTER TABLE paymentAttempts WITH CHECK ADD CONSTRAINT FK_paymentAttempts_paymentMethodID_paymentMethods FOREIGN KEY (paymentMethodID) REFERENCES paymentMethods(paymentMethodID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE paymentAttempts CHECK CONSTRAINT FK_paymentAttempts_paymentMethodID_paymentMethods;
ALTER TABLE paymentAttempts WITH CHECK ADD CONSTRAINT FK_paymentAttempts_playerID_players FOREIGN KEY (playerID) REFERENCES players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE paymentAttempts CHECK CONSTRAINT FK_paymentAttempts_playerID_players;
ALTER TABLE paymentAttempts WITH CHECK ADD CONSTRAINT FK_paymentAttempts_operationTypeCodeID_paymentOperationTypes FOREIGN KEY (operationTypeCodeID) REFERENCES paymentOperationTypes(operationTypeCodeID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE paymentAttempts CHECK CONSTRAINT FK_paymentAttempts_operationTypeCodeID_paymentOperationTypes;
ALTER TABLE paymentAttempts WITH CHECK ADD CONSTRAINT FK_paymentAttempts_currencyID_currencies FOREIGN KEY (currencyID) REFERENCES currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE paymentAttempts CHECK CONSTRAINT FK_paymentAttempts_currencyID_currencies;
ALTER TABLE paymentAttempts WITH CHECK ADD CONSTRAINT FK_paymentAttempts_exchangeRateID_currentExchangeRates FOREIGN KEY (exchangeRateID) REFERENCES currentExchangeRates(currentExchangeRateID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE paymentAttempts CHECK CONSTRAINT FK_paymentAttempts_exchangeRateID_currentExchangeRates;
ALTER TABLE paymentAttempts WITH CHECK ADD CONSTRAINT FK_paymentAttempts_paymentStatusID_paymentTransactionsStatus FOREIGN KEY (paymentStatusID) REFERENCES paymentTransactionsStatus(statusCodeID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE paymentAttempts CHECK CONSTRAINT FK_paymentAttempts_paymentStatusID_paymentTransactionsStatus;
ALTER TABLE moneyBalance WITH CHECK ADD CONSTRAINT FK_moneyBalance_playerID_players FOREIGN KEY (playerID) REFERENCES players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE moneyBalance CHECK CONSTRAINT FK_moneyBalance_playerID_players;
ALTER TABLE moneyBalance WITH CHECK ADD CONSTRAINT FK_moneyBalance_currencyID_currencies FOREIGN KEY (currencyID) REFERENCES currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE moneyBalance CHECK CONSTRAINT FK_moneyBalance_currencyID_currencies;
ALTER TABLE playersSocialNetwork WITH CHECK ADD CONSTRAINT FK_playersSocialNetwork_playerID_players FOREIGN KEY (playerID) REFERENCES players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE playersSocialNetwork CHECK CONSTRAINT FK_playersSocialNetwork_playerID_players;
ALTER TABLE playersSocialNetwork WITH CHECK ADD CONSTRAINT FK_playersSocialNetwork_socialNetworkID_socialNetworks FOREIGN KEY (socialNetworkID) REFERENCES socialNetworks(socialNetworkID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE playersSocialNetwork CHECK CONSTRAINT FK_playersSocialNetwork_socialNetworkID_socialNetworks;
ALTER TABLE resources WITH CHECK ADD CONSTRAINT FK_resources_playerSocialNetworkID_playersSocialNetwork FOREIGN KEY (playerSocialNetworkID) REFERENCES playersSocialNetwork(playerSocialNetworkID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE resources CHECK CONSTRAINT FK_resources_playerSocialNetworkID_playersSocialNetwork;
ALTER TABLE resources WITH CHECK ADD CONSTRAINT FK_resources_resourceTypeID_resourceTypes FOREIGN KEY (resourceTypeID) REFERENCES resourceTypes(resourceTypeID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE resources CHECK CONSTRAINT FK_resources_resourceTypeID_resourceTypes;
ALTER TABLE propositions WITH CHECK ADD CONSTRAINT FK_propositions_creatorPlayerID_players FOREIGN KEY (creatorPlayerID) REFERENCES players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE propositions CHECK CONSTRAINT FK_propositions_creatorPlayerID_players;
ALTER TABLE propositions WITH CHECK ADD CONSTRAINT FK_propositions_targetPlayerID_players FOREIGN KEY (targetPlayerID) REFERENCES players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE propositions CHECK CONSTRAINT FK_propositions_targetPlayerID_players;
ALTER TABLE propositions WITH CHECK ADD CONSTRAINT FK_propositions_relatedResourceID_resources FOREIGN KEY (relatedResourceID) REFERENCES resources(resourceID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE propositions CHECK CONSTRAINT FK_propositions_relatedResourceID_resources;
ALTER TABLE propositions WITH CHECK ADD CONSTRAINT FK_propositions_propositionStatusID_propositionStatus FOREIGN KEY (propositionStatusID) REFERENCES propositionStatus(propositionStatusID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE propositions CHECK CONSTRAINT FK_propositions_propositionStatusID_propositionStatus;
ALTER TABLE propositionVotes WITH CHECK ADD CONSTRAINT FK_propositionVotes_propositionID_propositions FOREIGN KEY (propositionID) REFERENCES propositions(propositionID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE propositionVotes CHECK CONSTRAINT FK_propositionVotes_propositionID_propositions;
ALTER TABLE propositionVotes WITH CHECK ADD CONSTRAINT FK_propositionVotes_voterPlayerID_players FOREIGN KEY (voterPlayerID) REFERENCES players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE propositionVotes CHECK CONSTRAINT FK_propositionVotes_voterPlayerID_players;
ALTER TABLE propositionStatusLogs WITH CHECK ADD CONSTRAINT FK_propositionStatusLogs_propositionID_propositions FOREIGN KEY (propositionID) REFERENCES propositions(propositionID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE propositionStatusLogs CHECK CONSTRAINT FK_propositionStatusLogs_propositionID_propositions;
ALTER TABLE propositionStatusLogs WITH CHECK ADD CONSTRAINT FK_propositionStatusLogs_previousStatusCodeID_propositionStatus FOREIGN KEY (previousStatusCodeID) REFERENCES propositionStatus(propositionStatusID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE propositionStatusLogs CHECK CONSTRAINT FK_propositionStatusLogs_previousStatusCodeID_propositionStatus;
ALTER TABLE propositionStatusLogs WITH CHECK ADD CONSTRAINT FK_propositionStatusLogs_currentStatusCodeID_propositionStatus FOREIGN KEY (currentStatusCodeID) REFERENCES propositionStatus(propositionStatusID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE propositionStatusLogs CHECK CONSTRAINT FK_propositionStatusLogs_currentStatusCodeID_propositionStatus;
ALTER TABLE propositionStatusLogs WITH CHECK ADD CONSTRAINT FK_propositionStatusLogs_changedByPlayerID_players FOREIGN KEY (changedByPlayerID) REFERENCES players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE propositionStatusLogs CHECK CONSTRAINT FK_propositionStatusLogs_changedByPlayerID_players;
ALTER TABLE predictions WITH CHECK ADD CONSTRAINT FK_predictions_propositionID_propositions FOREIGN KEY (propositionID) REFERENCES propositions(propositionID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE predictions CHECK CONSTRAINT FK_predictions_propositionID_propositions;
ALTER TABLE predictions WITH CHECK ADD CONSTRAINT FK_predictions_playerID_players FOREIGN KEY (playerID) REFERENCES players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE predictions CHECK CONSTRAINT FK_predictions_playerID_players;
ALTER TABLE predictions WITH CHECK ADD CONSTRAINT FK_predictions_predictionTypeID_predictionTypes FOREIGN KEY (predictionTypeID) REFERENCES predictionTypes(predictionTypeID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE predictions CHECK CONSTRAINT FK_predictions_predictionTypeID_predictionTypes;
ALTER TABLE predictions WITH CHECK ADD CONSTRAINT FK_predictions_currencyID_currencies FOREIGN KEY (currencyID) REFERENCES currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE predictions CHECK CONSTRAINT FK_predictions_currencyID_currencies;
ALTER TABLE predictions WITH CHECK ADD CONSTRAINT FK_predictions_exchangeRateID_currentExchangeRates FOREIGN KEY (exchangeRateID) REFERENCES currentExchangeRates(currentExchangeRateID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE predictions CHECK CONSTRAINT FK_predictions_exchangeRateID_currentExchangeRates;
ALTER TABLE predictionAmountLogs WITH CHECK ADD CONSTRAINT FK_predictionAmountLogs_predictionID_predictions FOREIGN KEY (predictionID) REFERENCES predictions(predictionID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE predictionAmountLogs CHECK CONSTRAINT FK_predictionAmountLogs_predictionID_predictions;
ALTER TABLE predictionOutcomes WITH CHECK ADD CONSTRAINT FK_predictionOutcomes_predictionID_predictions FOREIGN KEY (predictionID) REFERENCES predictions(predictionID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE predictionOutcomes CHECK CONSTRAINT FK_predictionOutcomes_predictionID_predictions;
ALTER TABLE predictionOutcomes WITH CHECK ADD CONSTRAINT FK_predictionOutcomes_currencyID_currencies FOREIGN KEY (currencyID) REFERENCES currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE predictionOutcomes CHECK CONSTRAINT FK_predictionOutcomes_currencyID_currencies;
ALTER TABLE predictionOutcomes WITH CHECK ADD CONSTRAINT FK_predictionOutcomes_settledByPlayerID_players FOREIGN KEY (settledByPlayerID) REFERENCES players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE predictionOutcomes CHECK CONSTRAINT FK_predictionOutcomes_settledByPlayerID_players;
ALTER TABLE propositionResult WITH CHECK ADD CONSTRAINT FK_propositionResult_propositionID_propositions FOREIGN KEY (propositionID) REFERENCES propositions(propositionID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE propositionResult CHECK CONSTRAINT FK_propositionResult_propositionID_propositions;
ALTER TABLE propositionResult WITH CHECK ADD CONSTRAINT FK_propositionResult_resultStatusID_propositionResultStatus FOREIGN KEY (resultStatusID) REFERENCES propositionResultStatus(resultStatusID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE propositionResult CHECK CONSTRAINT FK_propositionResult_resultStatusID_propositionResultStatus;
ALTER TABLE propositionResult WITH CHECK ADD CONSTRAINT FK_propositionResult_evidenceResourceID_resources FOREIGN KEY (evidenceResourceID) REFERENCES resources(resourceID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE propositionResult CHECK CONSTRAINT FK_propositionResult_evidenceResourceID_resources;
ALTER TABLE processLogs WITH CHECK ADD CONSTRAINT FK_processLogs_sourceTypeID_sourceTypes FOREIGN KEY (sourceTypeID) REFERENCES sourceTypes(sourceTypeID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE processLogs CHECK CONSTRAINT FK_processLogs_sourceTypeID_sourceTypes;
ALTER TABLE auditLogs WITH CHECK ADD CONSTRAINT FK_auditLogs_changeSourceCode_changeSources FOREIGN KEY (changeSourceCode) REFERENCES changeSources(sourceCode) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE auditLogs CHECK CONSTRAINT FK_auditLogs_changeSourceCode_changeSources;
ALTER TABLE auditLogs WITH CHECK ADD CONSTRAINT FK_auditLogs_performedByPlayerID_players FOREIGN KEY (performedByPlayerID) REFERENCES players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE auditLogs CHECK CONSTRAINT FK_auditLogs_performedByPlayerID_players;
ALTER TABLE merchants WITH CHECK ADD CONSTRAINT FK_merchants_countryID_countries FOREIGN KEY (countryID) REFERENCES countries(countryID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE merchants CHECK CONSTRAINT FK_merchants_countryID_countries;
ALTER TABLE merchantProducts WITH CHECK ADD CONSTRAINT FK_merchantProducts_merchantID_merchants FOREIGN KEY (merchantID) REFERENCES merchants(merchantID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE merchantProducts CHECK CONSTRAINT FK_merchantProducts_merchantID_merchants;
ALTER TABLE pointRedemption WITH CHECK ADD CONSTRAINT FK_pointRedemption_playerID_players FOREIGN KEY (playerID) REFERENCES players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pointRedemption CHECK CONSTRAINT FK_pointRedemption_playerID_players;
ALTER TABLE pointRedemption WITH CHECK ADD CONSTRAINT FK_pointRedemption_merchantProductID_merchantProducts FOREIGN KEY (merchantProductID) REFERENCES merchantProducts(merchantProductID) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE pointRedemption CHECK CONSTRAINT FK_pointRedemption_merchantProductID_merchantProducts;
GO

-- =========================================
-- ÍNDICES
-- =========================================
GO
CREATE INDEX IX_players_countryID ON players (countryID);
CREATE INDEX IX_loginAttempts_playerID ON loginAttempts (playerID);
CREATE INDEX IX_loginAttempts_attemptedEmail ON loginAttempts (attemptedEmail);
CREATE INDEX IX_countries_localCurrencyID ON countries (localCurrencyID);
CREATE INDEX IX_historicalExchangeRates_currentExchangeRateID ON historicalExchangeRates (currentExchangeRateID);
CREATE INDEX IX_pointBalances_playerID ON pointBalances (playerID);
CREATE INDEX IX_pointTransactions_playerID ON pointTransactions (playerID);
CREATE INDEX IX_pointTransactions_propositionID ON pointTransactions (propositionID);
CREATE INDEX IX_pointTransactions_predictionID ON pointTransactions (predictionID);
CREATE INDEX IX_pointTransactions_transactionDate ON pointTransactions (transactionDate);
CREATE INDEX IX_paymentMethods_providerID ON paymentMethods (providerID);
CREATE INDEX IX_paymentAttempts_paymentMethodID ON paymentAttempts (paymentMethodID);
CREATE INDEX IX_paymentAttempts_playerID ON paymentAttempts (playerID);
CREATE INDEX IX_paymentAttempts_operationTypeCodeID ON paymentAttempts (operationTypeCodeID);
CREATE INDEX IX_paymentAttempts_currencyID ON paymentAttempts (currencyID);
CREATE INDEX IX_paymentAttempts_exchangeRateID ON paymentAttempts (exchangeRateID);
CREATE INDEX IX_paymentAttempts_paymentStatusID ON paymentAttempts (paymentStatusID);
CREATE INDEX IX_paymentAttempts_postedAt ON paymentAttempts (postedAt);
CREATE INDEX IX_moneyBalance_playerID ON moneyBalance (playerID);
CREATE INDEX IX_moneyBalance_currencyID ON moneyBalance (currencyID);
CREATE INDEX IX_playersSocialNetwork_playerID ON playersSocialNetwork (playerID);
CREATE INDEX IX_playersSocialNetwork_socialNetworkID ON playersSocialNetwork (socialNetworkID);
CREATE INDEX IX_resources_playerSocialNetworkID ON resources (playerSocialNetworkID);
CREATE INDEX IX_resources_resourceTypeID ON resources (resourceTypeID);
CREATE INDEX IX_propositions_creatorPlayerID ON propositions (creatorPlayerID);
CREATE INDEX IX_propositions_targetPlayerID ON propositions (targetPlayerID);
CREATE INDEX IX_propositions_relatedResourceID ON propositions (relatedResourceID);
CREATE INDEX IX_propositions_propositionStatusID ON propositions (propositionStatusID);
CREATE INDEX IX_propositionVotes_propositionID ON propositionVotes (propositionID);
CREATE INDEX IX_propositionVotes_voterPlayerID ON propositionVotes (voterPlayerID);
CREATE INDEX IX_propositionStatusLogs_propositionID ON propositionStatusLogs (propositionID);
CREATE INDEX IX_propositionStatusLogs_changedByPlayerID ON propositionStatusLogs (changedByPlayerID);
CREATE INDEX IX_predictions_propositionID ON predictions (propositionID);
CREATE INDEX IX_predictions_playerID ON predictions (playerID);
CREATE INDEX IX_predictions_predictedAt ON predictions (predictedAt);
CREATE INDEX IX_predictions_predictionTypeID ON predictions (predictionTypeID);
CREATE INDEX IX_predictionAmountLogs_predictionID ON predictionAmountLogs (predictionID);
CREATE INDEX IX_predictionOutcomes_predictionID ON predictionOutcomes (predictionID);
CREATE INDEX IX_propositionResult_propositionID ON propositionResult (propositionID);
CREATE INDEX IX_propositionResult_resultStatusID ON propositionResult (resultStatusID);
CREATE INDEX IX_processLogs_sourceTypeID ON processLogs (sourceTypeID);
CREATE INDEX IX_processLogs_executedAt ON processLogs (executedAt);
CREATE INDEX IX_auditLogs_changeSourceCode ON auditLogs (changeSourceCode);
CREATE INDEX IX_auditLogs_performedByPlayerID ON auditLogs (performedByPlayerID);
CREATE INDEX IX_merchants_countryID ON merchants (countryID);
CREATE INDEX IX_merchantProducts_merchantID ON merchantProducts (merchantID);
CREATE INDEX IX_pointRedemption_playerID ON pointRedemption (playerID);
CREATE INDEX IX_pointRedemption_merchantProductID ON pointRedemption (merchantProductID);

CREATE INDEX IX_exchangePairs_baseCurrencyID_quoteCurrencyID ON exchangePairs (baseCurrencyID, quoteCurrencyID);
CREATE INDEX IX_currentExchangeRates_exchangePairID ON currentExchangeRates (exchangePairID);
CREATE INDEX IX_predictions_propositionID_predictedAt ON predictions (propositionID, predictedAt);
CREATE INDEX IX_pointTransactions_playerID_transactionDate ON pointTransactions (playerID, transactionDate);
CREATE INDEX IX_paymentAttempts_playerID_postedAt ON paymentAttempts (playerID, postedAt);
CREATE INDEX IX_propositions_status_createdAt ON propositions (propositionStatusID, createdAt);
CREATE INDEX IX_propositionVotes_propositionID_votedAt ON propositionVotes (propositionID, votedAt);
CREATE INDEX IX_resources_playerSocialNetworkID_capturedAt ON resources (playerSocialNetworkID, capturedAt);
CREATE INDEX IX_auditLogs_entityName_entityID_performedAt ON auditLogs (entityName, entityID, performedAt);
CREATE INDEX IX_processLogs_processType_processID_executedAt ON processLogs (processType, processID, executedAt);
CREATE INDEX IX_predictionOutcomes_settledByPlayerID ON predictionOutcomes (settledByPlayerID);
GO

