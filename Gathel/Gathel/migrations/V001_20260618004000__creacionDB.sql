CREATE TABLE dbo.userRoles
(
    userRoleID BIGINT IDENTITY(1,1) NOT NULL,
    roleName NVARCHAR(30) NOT NULL,
    roleDescription NVARCHAR(150) NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_userRoles_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_userRoles_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_userRoles PRIMARY KEY (userRoleID),
    CONSTRAINT UQ_userRoles_roleName UNIQUE (roleName)
);

CREATE TABLE dbo.permissions
(
    permissionID BIGINT IDENTITY(1,1) NOT NULL,
    permissionName NVARCHAR(30) NOT NULL,
    permissionDescription NVARCHAR(150) NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_permissions_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_permissions_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_permissions PRIMARY KEY (permissionID),
    CONSTRAINT UQ_permissions_permissionName UNIQUE (permissionName)
);

CREATE TABLE dbo.rolePermissions
(
    userRoleID BIGINT NOT NULL,
    permissionID BIGINT NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_rolePermissions_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_rolePermissions PRIMARY KEY (userRoleID, permissionID),
    CONSTRAINT FK_rolePermissions_userRoles FOREIGN KEY (userRoleID) REFERENCES dbo.userRoles(userRoleID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_rolePermissions_permissions FOREIGN KEY (permissionID) REFERENCES dbo.permissions(permissionID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.currencies
(
    currencyID BIGINT IDENTITY(1,1) NOT NULL,
    currencyCode NVARCHAR(20) NOT NULL,
    currencyName NVARCHAR(45) NOT NULL,
    currencySymbol NVARCHAR(30) NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_currencies_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_currencies_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    CONSTRAINT PK_currencies PRIMARY KEY (currencyID),
    CONSTRAINT UQ_currencies_currencyCode UNIQUE (currencyCode)
);

CREATE TABLE dbo.countries
(
    countryID BIGINT IDENTITY(1,1) NOT NULL,
    countryName NVARCHAR(50) NOT NULL,
    iso2Code CHAR(2) NOT NULL,
    iso3Code CHAR(3) NOT NULL,
    localCurrencyID BIGINT NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_countries_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_countries_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    CONSTRAINT PK_countries PRIMARY KEY (countryID),
    CONSTRAINT UQ_countries_iso2Code UNIQUE (iso2Code),
    CONSTRAINT UQ_countries_iso3Code UNIQUE (iso3Code),
    CONSTRAINT FK_countries_currencies FOREIGN KEY (localCurrencyID) REFERENCES dbo.currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.players
(
    playerID BIGINT IDENTITY(1,1) NOT NULL,
    countryID BIGINT NOT NULL,
    email NVARCHAR(150) NOT NULL,
    username NVARCHAR(50) NOT NULL,
    firstName NVARCHAR(40) NOT NULL,
    lastName NVARCHAR(40) NOT NULL,
    secondLastName NVARCHAR(40) NULL,
    passwordHash NVARCHAR(255) NOT NULL,
    isEmailVerified BIT NOT NULL CONSTRAINT DF_players_isEmailVerified DEFAULT (0),
    isActive BIT NOT NULL CONSTRAINT DF_players_isActive DEFAULT (1),
    lastLoginAt DATETIME2 NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_players_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    CONSTRAINT PK_players PRIMARY KEY (playerID),
    CONSTRAINT UQ_players_email UNIQUE (email),
    CONSTRAINT UQ_players_username UNIQUE (username),
    CONSTRAINT CK_players_email CHECK (email LIKE N'%@%'),
    CONSTRAINT FK_players_countries FOREIGN KEY (countryID) REFERENCES dbo.countries(countryID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.systemUsers
(
    playerID BIGINT NOT NULL,
    roleID BIGINT NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_systemUsers_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_systemUsers PRIMARY KEY (playerID, roleID),
    CONSTRAINT FK_systemUsers_players FOREIGN KEY (playerID) REFERENCES dbo.players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_systemUsers_userRoles FOREIGN KEY (roleID) REFERENCES dbo.userRoles(userRoleID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.loginAttempts
(
    loginAttemptID BIGINT IDENTITY(1,1) NOT NULL,
    playerID BIGINT NOT NULL,
    attemptedEmail NVARCHAR(150) NOT NULL,
    ipAddress NVARCHAR(45) NOT NULL,
    wasSuccessful BIT NOT NULL,
    failureReason NVARCHAR(100) NULL,
    attemptedAt DATETIME2 NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_loginAttempts_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_loginAttempts PRIMARY KEY (loginAttemptID),
    CONSTRAINT CK_loginAttempts_attemptedEmail CHECK (attemptedEmail LIKE N'%@%'),
    CONSTRAINT FK_loginAttempts_players FOREIGN KEY (playerID) REFERENCES dbo.players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

/*==============================================================
  Geografía y monedas
==============================================================*/

CREATE TABLE dbo.exchangePairs
(
    exchangePairID BIGINT IDENTITY(1,1) NOT NULL,
    baseCurrencyID BIGINT NOT NULL,
    quoteCurrencyID BIGINT NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_exchangePairs_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_exchangePairs_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    CONSTRAINT PK_exchangePairs PRIMARY KEY (exchangePairID),
    CONSTRAINT UQ_exchangePairs_base_quote UNIQUE (baseCurrencyID, quoteCurrencyID),
    CONSTRAINT CK_exchangePairs_differentCurrencies CHECK (baseCurrencyID <> quoteCurrencyID),
    CONSTRAINT FK_exchangePairs_baseCurrency FOREIGN KEY (baseCurrencyID) REFERENCES dbo.currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_exchangePairs_quoteCurrency FOREIGN KEY (quoteCurrencyID) REFERENCES dbo.currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.currentExchangeRates
(
    currentExchangeRateID BIGINT IDENTITY(1,1) NOT NULL,
    exchangePairID BIGINT NOT NULL,
    baseCurrencyID BIGINT NOT NULL,
    quoteCurrencyID BIGINT NOT NULL,
    buyRate DECIMAL(18,6) NOT NULL,
    sellRate DECIMAL(18,6) NOT NULL,
    sourceName NVARCHAR(50) NOT NULL,
    updatedAt DATETIME2 NOT NULL,
    CONSTRAINT PK_currentExchangeRates PRIMARY KEY (currentExchangeRateID),
    CONSTRAINT UQ_currentExchangeRates_exchangePairID UNIQUE (exchangePairID),
    CONSTRAINT CK_currentExchangeRates_differentCurrencies CHECK (baseCurrencyID <> quoteCurrencyID),
    CONSTRAINT CK_currentExchangeRates_rates CHECK (buyRate >= 0 AND sellRate >= 0),
    CONSTRAINT FK_currentExchangeRates_exchangePairs FOREIGN KEY (exchangePairID) REFERENCES dbo.exchangePairs(exchangePairID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_currentExchangeRates_baseCurrency FOREIGN KEY (baseCurrencyID) REFERENCES dbo.currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_currentExchangeRates_quoteCurrency FOREIGN KEY (quoteCurrencyID) REFERENCES dbo.currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.historicalExchangeRates
(
    historicalExchangeRateID BIGINT IDENTITY(1,1) NOT NULL,
    currentExchangeRateID BIGINT NOT NULL,
    buyRate DECIMAL(18,6) NOT NULL,
    sellRate DECIMAL(18,6) NOT NULL,
    validFrom DATETIME2 NOT NULL,
    validTo DATETIME2 NULL,
    recordedAt DATETIME2 NOT NULL,
    CONSTRAINT PK_historicalExchangeRates PRIMARY KEY (historicalExchangeRateID),
    CONSTRAINT CK_historicalExchangeRates_rates CHECK (buyRate >= 0 AND sellRate >= 0),
    CONSTRAINT CK_historicalExchangeRates_dates CHECK (validTo IS NULL OR validTo >= validFrom),
    CONSTRAINT FK_historicalExchangeRates_currentExchangeRates FOREIGN KEY (currentExchangeRateID) REFERENCES dbo.currentExchangeRates(currentExchangeRateID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

/*==============================================================
  Configuración de puntos
==============================================================*/

CREATE TABLE dbo.currencyConfigurations
(
    currencyConfigurationID BIGINT IDENTITY(1,1) NOT NULL,
    currencyID BIGINT NOT NULL,
    configCode NVARCHAR(30) NOT NULL,
    configName NVARCHAR(80) NOT NULL,
    initialBalance DECIMAL(18,6) NOT NULL,
    maxAmountPerPrediction DECIMAL(18,6) NOT NULL,
    platformFeePercent DECIMAL(5,2) NOT NULL,
    proposerFeePercent DECIMAL(5,2) NOT NULL,
    validationFailurePenaltyPercent DECIMAL(5,2) NOT NULL,
    propositionRejectionPenalty DECIMAL(18,6) NOT NULL,
    validFrom DATETIME2 NOT NULL,
    validTo DATETIME2 NULL,
    isCurrent BIT NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_currencyConfigurations_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    CONSTRAINT PK_currencyConfigurations PRIMARY KEY (currencyConfigurationID),
    CONSTRAINT UQ_currencyConfigurations_configCode UNIQUE (configCode),
    CONSTRAINT CK_currencyConfigurations_dates CHECK (validTo IS NULL OR validTo >= validFrom),
    CONSTRAINT CK_currencyConfigurations_amounts CHECK (initialBalance >= 0 AND maxAmountPerPrediction >= 0 AND propositionRejectionPenalty >= 0),
    CONSTRAINT CK_currencyConfigurations_percents CHECK (platformFeePercent BETWEEN 0 AND 100 AND proposerFeePercent BETWEEN 0 AND 100 AND validationFailurePenaltyPercent BETWEEN 0 AND 100),
    CONSTRAINT FK_currencyConfigurations_currencies FOREIGN KEY (currencyID) REFERENCES dbo.currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.balances
(
    balanceID BIGINT IDENTITY(1,1) NOT NULL,
    playerID BIGINT NOT NULL,
    currencyID BIGINT NOT NULL,
    availableAmount DECIMAL(18,6) NOT NULL,
    reservedAmount DECIMAL(18,6) NOT NULL,
    totalAmountEarned DECIMAL(18,6) NOT NULL,
    totalAmountSpent DECIMAL(18,6) NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_balances_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    isCurrent BIT NOT NULL,
    CONSTRAINT PK_balances PRIMARY KEY (balanceID),
    CONSTRAINT UQ_balances_player_currency UNIQUE (playerID, currencyID),
    CONSTRAINT CK_balances_amounts CHECK (availableAmount >= 0 AND reservedAmount >= 0 AND totalAmountEarned >= 0 AND totalAmountSpent >= 0),
    CONSTRAINT FK_balances_players FOREIGN KEY (playerID) REFERENCES dbo.players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_balances_currencies FOREIGN KEY (currencyID) REFERENCES dbo.currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.transactionTypes
(
    transactionTypeCodeID BIGINT IDENTITY(1,1) NOT NULL,
    typeName NVARCHAR(50) NOT NULL,
    typeDescription NVARCHAR(150) NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_transactionTypes_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_transactionTypes_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_transactionTypes PRIMARY KEY (transactionTypeCodeID),
    CONSTRAINT UQ_transactionTypes_typeName UNIQUE (typeName)
);

/*==============================================================
  Pagos y dinero real
==============================================================*/

CREATE TABLE dbo.providers
(
    providerID BIGINT IDENTITY(1,1) NOT NULL,
    providerName NVARCHAR(50) NOT NULL,
    providerDescription NVARCHAR(150) NULL,
    isActive BIT NOT NULL CONSTRAINT DF_providers_isActive DEFAULT (1),
    CONSTRAINT PK_providers PRIMARY KEY (providerID),
    CONSTRAINT UQ_providers_providerName UNIQUE (providerName)
);

CREATE TABLE dbo.paymentTransactionsStatus
(
    statusCodeID BIGINT IDENTITY(1,1) NOT NULL,
    statusName NVARCHAR(50) NOT NULL,
    statusDescription NVARCHAR(150) NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_paymentTransactionsStatus_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_paymentTransactionsStatus_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_paymentTransactionsStatus PRIMARY KEY (statusCodeID),
    CONSTRAINT UQ_paymentTransactionsStatus_statusName UNIQUE (statusName)
);

CREATE TABLE dbo.paymentOperationTypes
(
    operationTypeCodeID BIGINT IDENTITY(1,1) NOT NULL,
    operationTypeName NVARCHAR(50) NOT NULL,
    operationTypeDescription NVARCHAR(150) NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_paymentOperationTypes_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_paymentOperationTypes_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_paymentOperationTypes PRIMARY KEY (operationTypeCodeID),
    CONSTRAINT UQ_paymentOperationTypes_operationTypeName UNIQUE (operationTypeName)
);

CREATE TABLE dbo.paymentMethods
(
    paymentMethodID BIGINT IDENTITY(1,1) NOT NULL,
    providerID BIGINT NOT NULL,
    methodName NVARCHAR(50) NOT NULL,
    methodDescription NVARCHAR(150) NOT NULL,
    apiURL NVARCHAR(255) NOT NULL,
    config NVARCHAR(MAX) NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_paymentMethods_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_paymentMethods_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    CONSTRAINT PK_paymentMethods PRIMARY KEY (paymentMethodID),
    CONSTRAINT UQ_paymentMethods_methodName UNIQUE (methodName),
    CONSTRAINT FK_paymentMethods_providers FOREIGN KEY (providerID) REFERENCES dbo.providers(providerID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.moneyBalance
(
    moneyBalanceID BIGINT IDENTITY(1,1) NOT NULL,
    playerID BIGINT NOT NULL,
    currencyID BIGINT NOT NULL,
    availableAmount DECIMAL(18,6) NOT NULL,
    reservedAmount DECIMAL(18,6) NOT NULL,
    totalDeposited DECIMAL(18,6) NOT NULL,
    totalWithdrawn DECIMAL(18,6) NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_moneyBalance_createdAt DEFAULT (SYSUTCDATETIME()),
    validUntil DATETIME2 NULL,
    isActive BIT NOT NULL CONSTRAINT DF_moneyBalance_isActive DEFAULT (1),
    CONSTRAINT PK_moneyBalance PRIMARY KEY (moneyBalanceID),
    CONSTRAINT UQ_moneyBalance_player_currency UNIQUE (playerID, currencyID),
    CONSTRAINT CK_moneyBalance_amounts CHECK (availableAmount >= 0 AND reservedAmount >= 0 AND totalDeposited >= 0 AND totalWithdrawn >= 0),
    CONSTRAINT FK_moneyBalance_players FOREIGN KEY (playerID) REFERENCES dbo.players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_moneyBalance_currencies FOREIGN KEY (currencyID) REFERENCES dbo.currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

/*==============================================================
  Redes sociales
==============================================================*/

CREATE TABLE dbo.socialNetworks
(
    socialNetworkID BIGINT IDENTITY(1,1) NOT NULL,
    socialNetworkName NVARCHAR(50) NOT NULL,
    socialNetworkDescription NVARCHAR(150) NOT NULL,
    baseURL NVARCHAR(150) NOT NULL,
    apiURL NVARCHAR(255) NOT NULL,
    config NVARCHAR(MAX) NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_socialNetworks_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_socialNetworks_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    CONSTRAINT PK_socialNetworks PRIMARY KEY (socialNetworkID),
    CONSTRAINT UQ_socialNetworks_socialNetworkName UNIQUE (socialNetworkName)
);

CREATE TABLE dbo.playersSocialNetwork
(
    playerSocialNetworkID BIGINT IDENTITY(1,1) NOT NULL,
    playerID BIGINT NOT NULL,
    socialNetworkID BIGINT NOT NULL,
    externalAccountID NVARCHAR(150) NOT NULL,
    externalUsername NVARCHAR(100) NOT NULL,
    isAuthorized BIT NOT NULL CONSTRAINT DF_playersSocialNetwork_isAuthorized DEFAULT (0),
    isActive BIT NOT NULL CONSTRAINT DF_playersSocialNetwork_isActive DEFAULT (1),
    linkedAt DATETIME2 NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_playersSocialNetwork_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    CONSTRAINT PK_playersSocialNetwork PRIMARY KEY (playerSocialNetworkID),
    CONSTRAINT UQ_playersSocialNetwork_player_social_external UNIQUE (playerID, socialNetworkID, externalAccountID),
    CONSTRAINT FK_playersSocialNetwork_players FOREIGN KEY (playerID) REFERENCES dbo.players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_playersSocialNetwork_socialNetworks FOREIGN KEY (socialNetworkID) REFERENCES dbo.socialNetworks(socialNetworkID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.playerSocialNetworkTokens
(
    playerSocialNetworkTokenID BIGINT IDENTITY(1,1) NOT NULL,
    playerSocialNetworkID BIGINT NOT NULL,
    accessTokenHash NVARCHAR(255) NOT NULL,
    refreshTokenHash NVARCHAR(255) NOT NULL,
    tokenExpiresAt DATETIME2 NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_playerSocialNetworkTokens_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_playerSocialNetworkTokens_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_playerSocialNetworkTokens PRIMARY KEY (playerSocialNetworkTokenID),
    CONSTRAINT FK_playerSocialNetworkTokens_playersSocialNetwork FOREIGN KEY (playerSocialNetworkID) REFERENCES dbo.playersSocialNetwork(playerSocialNetworkID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.resourceTypes
(
    resourceTypeID BIGINT IDENTITY(1,1) NOT NULL,
    resourceTypeName NVARCHAR(50) NOT NULL,
    resourceTypeDescription NVARCHAR(150) NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_resourceTypes_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_resourceTypes_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_resourceTypes PRIMARY KEY (resourceTypeID),
    CONSTRAINT UQ_resourceTypes_resourceTypeName UNIQUE (resourceTypeName)
);

CREATE TABLE dbo.resources
(
    resourceID BIGINT IDENTITY(1,1) NOT NULL,
    playerSocialNetworkID BIGINT NOT NULL,
    resourceTypeID BIGINT NOT NULL,
    externalResourceID NVARCHAR(150) NOT NULL,
    contentURL NVARCHAR(500) NOT NULL,
    contentHash NVARCHAR(80) NOT NULL,
    capturedAt DATETIME2 NOT NULL,
    eventOccurredAt DATETIME2 NULL,
    validationStatus NVARCHAR(30) NOT NULL CONSTRAINT DF_resources_validationStatus DEFAULT (N'pending'),
    isActive BIT NOT NULL CONSTRAINT DF_resources_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_resources_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    CONSTRAINT PK_resources PRIMARY KEY (resourceID),
    CONSTRAINT UQ_resources_psn_external_resource UNIQUE (playerSocialNetworkID, externalResourceID, resourceID),
    CONSTRAINT FK_resources_playersSocialNetwork FOREIGN KEY (playerSocialNetworkID) REFERENCES dbo.playersSocialNetwork(playerSocialNetworkID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_resources_resourceTypes FOREIGN KEY (resourceTypeID) REFERENCES dbo.resourceTypes(resourceTypeID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

/*==============================================================
  Núcleo del juego: proposiciones
==============================================================*/

CREATE TABLE dbo.propositionStatus
(
    propositionStatusID BIGINT IDENTITY(1,1) NOT NULL,
    statusName NVARCHAR(50) NOT NULL,
    statusDescription NVARCHAR(150) NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_propositionStatus_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_propositionStatus_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_propositionStatus PRIMARY KEY (propositionStatusID),
    CONSTRAINT UQ_propositionStatus_statusName UNIQUE (statusName)
);

CREATE TABLE dbo.propositions
(
    propositionID BIGINT IDENTITY(1,1) NOT NULL,
    creatorPlayerID BIGINT NOT NULL,
    targetPlayerID BIGINT NOT NULL,
    relatedResourceID BIGINT NOT NULL,
    propositionStatusID BIGINT NOT NULL,
    propositionText NVARCHAR(500) NOT NULL,
    predictionsDeadline DATETIME2 NOT NULL,
    votingDeadline DATETIME2 NOT NULL,
    acceptedAt DATETIME2 NOT NULL,
    closedAt DATETIME2 NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_propositions_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    isActive BIT NOT NULL CONSTRAINT DF_propositions_isActive DEFAULT (1),
    CONSTRAINT PK_propositions PRIMARY KEY (propositionID),
    CONSTRAINT CK_propositions_deadlines CHECK (predictionsDeadline <= votingDeadline),
    CONSTRAINT FK_propositions_creatorPlayer FOREIGN KEY (creatorPlayerID) REFERENCES dbo.players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_propositions_targetPlayer FOREIGN KEY (targetPlayerID) REFERENCES dbo.players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_propositions_resources FOREIGN KEY (relatedResourceID) REFERENCES dbo.resources(resourceID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_propositions_propositionStatus FOREIGN KEY (propositionStatusID) REFERENCES dbo.propositionStatus(propositionStatusID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.propositionVoteTypes
(
    propositionVoteTypeID BIGINT IDENTITY(1,1) NOT NULL,
    voteTypeName NVARCHAR(30) NOT NULL,
    voteTypeDescription NVARCHAR(150) NOT NULL,
    voteValue BIT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_propositionVoteTypes_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_propositionVoteTypes_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    CONSTRAINT PK_propositionVoteTypes PRIMARY KEY (propositionVoteTypeID),
    CONSTRAINT UQ_propositionVoteTypes_voteTypeName UNIQUE (voteTypeName)
);

CREATE TABLE dbo.propositionVotes
(
    propositionVoteID BIGINT IDENTITY(1,1) NOT NULL,
    propositionID BIGINT NOT NULL,
    voterPlayerID BIGINT NOT NULL,
    propositionVoteTypeID BIGINT NOT NULL,
    votedAt DATETIME2 NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_propositionVotes_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_propositionVotes PRIMARY KEY (propositionVoteID),
    CONSTRAINT UQ_propositionVotes_proposition_voter UNIQUE (propositionID, voterPlayerID),
    CONSTRAINT FK_propositionVotes_propositions FOREIGN KEY (propositionID) REFERENCES dbo.propositions(propositionID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_propositionVotes_players FOREIGN KEY (voterPlayerID) REFERENCES dbo.players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_propositionVotes_voteTypes FOREIGN KEY (propositionVoteTypeID) REFERENCES dbo.propositionVoteTypes(propositionVoteTypeID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.propositionStatusHistories
(
    propositionStatusHistorieID BIGINT IDENTITY(1,1) NOT NULL,
    propositionID BIGINT NOT NULL,
    previousStatusCodeID BIGINT NOT NULL,
    currentStatusCodeID BIGINT NOT NULL,
    changeDetails NVARCHAR(250) NOT NULL,
    changedByPlayerID BIGINT NOT NULL,
    changedAt DATETIME2 NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_propositionStatusHistories_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_propositionStatusHistories PRIMARY KEY (propositionStatusHistorieID),
    CONSTRAINT FK_propStatusHistories_propositions FOREIGN KEY (propositionID) REFERENCES dbo.propositions(propositionID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_propStatusHistories_previousStatus FOREIGN KEY (previousStatusCodeID) REFERENCES dbo.propositionStatus(propositionStatusID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_propStatusHistories_currentStatus FOREIGN KEY (currentStatusCodeID) REFERENCES dbo.propositionStatus(propositionStatusID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_propStatusHistories_players FOREIGN KEY (changedByPlayerID) REFERENCES dbo.players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

/*==============================================================
  Predicciones
==============================================================*/

CREATE TABLE dbo.predictionTypes
(
    predictionTypeID BIGINT IDENTITY(1,1) NOT NULL,
    predictionTypeName NVARCHAR(50) NOT NULL,
    predictionTypeDescription NVARCHAR(150) NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_predictionTypes_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_predictionTypes_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_predictionTypes PRIMARY KEY (predictionTypeID),
    CONSTRAINT UQ_predictionTypes_predictionTypeName UNIQUE (predictionTypeName)
);

CREATE TABLE dbo.predictions
(
    predictionID BIGINT IDENTITY(1,1) NOT NULL,
    propositionID BIGINT NOT NULL,
    playerID BIGINT NOT NULL,
    predictionTypeID BIGINT NOT NULL,
    predictionActive BIT NOT NULL,
    checksum NVARCHAR(80) NULL,
    predictedAt DATETIME2 NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_predictions_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    isActive BIT NOT NULL CONSTRAINT DF_predictions_isActive DEFAULT (1),
    CONSTRAINT PK_predictions PRIMARY KEY (predictionID),
    CONSTRAINT FK_predictions_propositions FOREIGN KEY (propositionID) REFERENCES dbo.propositions(propositionID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_predictions_players FOREIGN KEY (playerID) REFERENCES dbo.players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_predictions_predictionTypes FOREIGN KEY (predictionTypeID) REFERENCES dbo.predictionTypes(predictionTypeID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.predictionStakes
(
    predictionStakeID BIGINT IDENTITY(1,1) NOT NULL,
    predictionID BIGINT NOT NULL,
    currencyID BIGINT NOT NULL,
    amount DECIMAL(18,6) NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_predictionStakes_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    isActive BIT NOT NULL CONSTRAINT DF_predictionStakes_isActive DEFAULT (1),
    CONSTRAINT PK_predictionStakes PRIMARY KEY (predictionStakeID),
    CONSTRAINT CK_predictionStakes_amount CHECK (amount >= 0),
    CONSTRAINT FK_predictionStakes_predictions FOREIGN KEY (predictionID) REFERENCES dbo.predictions(predictionID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_predictionStakes_currencies FOREIGN KEY (currencyID) REFERENCES dbo.currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.predictionStakeHistories
(
    predictionStakeHistoryID BIGINT IDENTITY(1,1) NOT NULL,
    predictionStakeID BIGINT NOT NULL,
    previousAmount DECIMAL(18,6) NOT NULL,
    currentAmount DECIMAL(18,6) NOT NULL,
    previousCurrencyID BIGINT NULL,
    currentCurrencyID BIGINT NULL,
    changedAt DATETIME2 NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_predictionStakeHistories_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_predictionStakeHistories PRIMARY KEY (predictionStakeHistoryID),
    CONSTRAINT CK_predictionStakeHistories_amounts CHECK (previousAmount >= 0 AND currentAmount >= 0),
    CONSTRAINT FK_predictionStakeHistories_predictionStakes FOREIGN KEY (predictionStakeID) REFERENCES dbo.predictionStakes(predictionStakeID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_predictionStakeHistories_previousCurrency FOREIGN KEY (previousCurrencyID) REFERENCES dbo.currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_predictionStakeHistories_currentCurrency FOREIGN KEY (currentCurrencyID) REFERENCES dbo.currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.predictionResults
(
    predictionResultID BIGINT IDENTITY(1,1) NOT NULL,
    predictionID BIGINT NOT NULL,
    didWin BIT NOT NULL,
    determinedAt DATETIME2 NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_predictionResults_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    isActive BIT NOT NULL CONSTRAINT DF_predictionResults_isActive DEFAULT (1),
    CONSTRAINT PK_predictionResults PRIMARY KEY (predictionResultID),
    CONSTRAINT FK_predictionResults_predictions FOREIGN KEY (predictionID) REFERENCES dbo.predictions(predictionID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.settlementStatusTypes
(
    settlementStatusTypeID BIGINT IDENTITY(1,1) NOT NULL,
    settlementStatusName NVARCHAR(30) NOT NULL,
    CONSTRAINT PK_settlementStatusTypes PRIMARY KEY (settlementStatusTypeID),
    CONSTRAINT UQ_settlementStatusTypes_settlementStatusName UNIQUE (settlementStatusName)
);

CREATE TABLE dbo.predictionSettlements
(
    predictionSettlementID BIGINT IDENTITY(1,1) NOT NULL,
    predictionResultID BIGINT NOT NULL,
    recipientPlayerID BIGINT NOT NULL,
    currencyID BIGINT NOT NULL,
    amount DECIMAL(18,6) NOT NULL,
    settlementStatusTypeID BIGINT NOT NULL,
    settlementTypeName NVARCHAR(30) NOT NULL,
    settledByPlayerID BIGINT NOT NULL,
    settledAt DATETIME2 NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_predictionSettlements_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_predictionSettlements PRIMARY KEY (predictionSettlementID),
    CONSTRAINT CK_predictionSettlements_amount CHECK (amount >= 0),
    CONSTRAINT FK_predictionSettlements_predictionResults FOREIGN KEY (predictionResultID) REFERENCES dbo.predictionResults(predictionResultID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_predictionSettlements_recipientPlayer FOREIGN KEY (recipientPlayerID) REFERENCES dbo.players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_predictionSettlements_currencies FOREIGN KEY (currencyID) REFERENCES dbo.currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_predictionSettlements_statusTypes FOREIGN KEY (settlementStatusTypeID) REFERENCES dbo.settlementStatusTypes(settlementStatusTypeID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_predictionSettlements_settledByPlayer FOREIGN KEY (settledByPlayerID) REFERENCES dbo.players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

/*==============================================================
  Transacciones, después de proposiciones y predicciones
==============================================================*/

CREATE TABLE dbo.transactions
(
    transactionID BIGINT IDENTITY(1,1) NOT NULL,
    playerID BIGINT NOT NULL,
    transactionTypeCodeID BIGINT NOT NULL,
    propositionID BIGINT NULL,
    predictionID BIGINT NULL,
    currencyID BIGINT NOT NULL,
    amount DECIMAL(18,6) NOT NULL,
    balanceBefore DECIMAL(18,6) NOT NULL,
    balanceAfter DECIMAL(18,6) NOT NULL,
    description NVARCHAR(200) NULL,
    checksum NVARCHAR(80) NOT NULL,
    transactionDate DATETIME2 NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_transactions_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_transactions PRIMARY KEY (transactionID),
    CONSTRAINT CK_transactions_amount CHECK (amount >= 0),
    CONSTRAINT CK_transactions_relatedEntity CHECK (propositionID IS NOT NULL OR predictionID IS NOT NULL),
    CONSTRAINT FK_transactions_players FOREIGN KEY (playerID) REFERENCES dbo.players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_transactions_transactionTypes FOREIGN KEY (transactionTypeCodeID) REFERENCES dbo.transactionTypes(transactionTypeCodeID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_transactions_propositions FOREIGN KEY (propositionID) REFERENCES dbo.propositions(propositionID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_transactions_predictions FOREIGN KEY (predictionID) REFERENCES dbo.predictions(predictionID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_transactions_currencies FOREIGN KEY (currencyID) REFERENCES dbo.currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.paymentAttempts
(
    paymentAttemptID BIGINT IDENTITY(1,1) NOT NULL,
    paymentMethodID BIGINT NOT NULL,
    playerID BIGINT NOT NULL,
    operationTypeCodeID BIGINT NOT NULL,
    targetEntityType NVARCHAR(50) NOT NULL,
    targetEntityID BIGINT NOT NULL,
    sourceEntityType NVARCHAR(50) NOT NULL,
    sourceEntityID BIGINT NOT NULL,
    amount DECIMAL(18,6) NOT NULL,
    currencyID BIGINT NOT NULL,
    exchangeRate DECIMAL(18,6) NOT NULL,
    exchangeRateID BIGINT NOT NULL,
    paymentStatusID BIGINT NOT NULL,
    result NVARCHAR(30) NOT NULL,
    requestPayload NVARCHAR(MAX) NOT NULL,
    responsePayload NVARCHAR(MAX) NOT NULL,
    transactionReference NVARCHAR(150) NOT NULL,
    checksum NVARCHAR(80) NOT NULL,
    postedAt DATETIME2 NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_paymentAttempts_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_paymentAttempts PRIMARY KEY (paymentAttemptID),
    CONSTRAINT CK_paymentAttempts_amount CHECK (amount >= 0 AND exchangeRate >= 0),
    CONSTRAINT FK_paymentAttempts_paymentMethods FOREIGN KEY (paymentMethodID) REFERENCES dbo.paymentMethods(paymentMethodID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_paymentAttempts_players FOREIGN KEY (playerID) REFERENCES dbo.players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_paymentAttempts_operationTypes FOREIGN KEY (operationTypeCodeID) REFERENCES dbo.paymentOperationTypes(operationTypeCodeID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_paymentAttempts_currencies FOREIGN KEY (currencyID) REFERENCES dbo.currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_paymentAttempts_exchangeRates FOREIGN KEY (exchangeRateID) REFERENCES dbo.currentExchangeRates(currentExchangeRateID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_paymentAttempts_status FOREIGN KEY (paymentStatusID) REFERENCES dbo.paymentTransactionsStatus(statusCodeID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

/*==============================================================
  Validación de resultados
==============================================================*/

CREATE TABLE dbo.propositionResultTypes
(
    resultTypeID BIGINT IDENTITY(1,1) NOT NULL,
    statusName NVARCHAR(50) NOT NULL,
    statusDescription NVARCHAR(150) NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_propositionResultTypes_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_propositionResultTypes_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_propositionResultTypes PRIMARY KEY (resultTypeID),
    CONSTRAINT UQ_propositionResultTypes_statusName UNIQUE (statusName)
);

CREATE TABLE dbo.propositionResult
(
    propositionResultID BIGINT IDENTITY(1,1) NOT NULL,
    propositionID BIGINT NOT NULL,
    resultTypeID BIGINT NOT NULL,
    propositionFulfilled BIT NULL,
    evidenceResourceID BIGINT NOT NULL,
    validatedAt DATETIME2 NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_propositionResult_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    isActive BIT NOT NULL CONSTRAINT DF_propositionResult_isActive DEFAULT (1),
    CONSTRAINT PK_propositionResult PRIMARY KEY (propositionResultID),
    CONSTRAINT UQ_propositionResult_propositionID UNIQUE (propositionID),
    CONSTRAINT FK_propositionResult_propositions FOREIGN KEY (propositionID) REFERENCES dbo.propositions(propositionID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_propositionResult_resultTypes FOREIGN KEY (resultTypeID) REFERENCES dbo.propositionResultTypes(resultTypeID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_propositionResult_resources FOREIGN KEY (evidenceResourceID) REFERENCES dbo.resources(resourceID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

/*==============================================================
  Log general
==============================================================*/

CREATE TABLE dbo.changeSources
(
    sourceCode NVARCHAR(30) NOT NULL,
    sourceName NVARCHAR(50) NOT NULL,
    sourceDescription NVARCHAR(150) NULL,
    isActive BIT NOT NULL CONSTRAINT DF_changeSources_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_changeSources_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    CONSTRAINT PK_changeSources PRIMARY KEY (sourceCode),
    CONSTRAINT UQ_changeSources_sourceName UNIQUE (sourceName)
);

CREATE TABLE dbo.auditActionTypes
(
    auditActionTypeID BIGINT IDENTITY(1,1) NOT NULL,
    actionName NVARCHAR(30) NOT NULL,
    actionDescription NVARCHAR(150) NOT NULL,
    CONSTRAINT PK_auditActionTypes PRIMARY KEY (auditActionTypeID),
    CONSTRAINT UQ_auditActionTypes_actionName UNIQUE (actionName)
);

CREATE TABLE dbo.auditLogs
(
    auditLogID BIGINT IDENTITY(1,1) NOT NULL,
    entityName NVARCHAR(60) NOT NULL,
    entityID BIGINT NOT NULL,
    auditActionTypeID BIGINT NOT NULL,
    changeDetails NVARCHAR(500) NULL,
    previousValues NVARCHAR(MAX) NULL,
    newValues NVARCHAR(MAX) NULL,
    changeSourceCode NVARCHAR(30) NOT NULL,
    performedByPlayerID BIGINT NULL,
    performedAt DATETIME2 NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_auditLogs_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_auditLogs PRIMARY KEY (auditLogID),
    CONSTRAINT FK_auditLogs_auditActionTypes FOREIGN KEY (auditActionTypeID) REFERENCES dbo.auditActionTypes(auditActionTypeID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_auditLogs_changeSources FOREIGN KEY (changeSourceCode) REFERENCES dbo.changeSources(sourceCode) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_auditLogs_players FOREIGN KEY (performedByPlayerID) REFERENCES dbo.players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

/*==============================================================
  Comercios afiliados
==============================================================*/

CREATE TABLE dbo.merchants
(
    merchantID BIGINT IDENTITY(1,1) NOT NULL,
    merchantName NVARCHAR(100) NOT NULL,
    countryID BIGINT NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_merchants_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_merchants_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    CONSTRAINT PK_merchants PRIMARY KEY (merchantID),
    CONSTRAINT UQ_merchants_merchantName UNIQUE (merchantName),
    CONSTRAINT FK_merchants_countries FOREIGN KEY (countryID) REFERENCES dbo.countries(countryID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.merchantProducts
(
    merchantProductID BIGINT IDENTITY(1,1) NOT NULL,
    merchantID BIGINT NOT NULL,
    productCode NVARCHAR(50) NOT NULL,
    productName NVARCHAR(120) NOT NULL,
    productDescription NVARCHAR(500) NULL,
    costAmount DECIMAL(18,6) NOT NULL,
    currencyID BIGINT NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_merchantProducts_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_merchantProducts_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    CONSTRAINT PK_merchantProducts PRIMARY KEY (merchantProductID),
    CONSTRAINT UQ_merchantProducts_merchant_productCode UNIQUE (merchantID, productCode),
    CONSTRAINT CK_merchantProducts_costAmount CHECK (costAmount >= 0),
    CONSTRAINT FK_merchantProducts_merchants FOREIGN KEY (merchantID) REFERENCES dbo.merchants(merchantID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_merchantProducts_currencies FOREIGN KEY (currencyID) REFERENCES dbo.currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.redemptions
(
    redemptionID BIGINT IDENTITY(1,1) NOT NULL,
    playerID BIGINT NOT NULL,
    merchantProductID BIGINT NOT NULL,
    currencyID BIGINT NOT NULL,
    amountSpent DECIMAL(18,6) NOT NULL,
    redemptionCode NVARCHAR(80) NOT NULL,
    redeemedAt DATETIME2 NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_redemptions_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    CONSTRAINT PK_redemptions PRIMARY KEY (redemptionID),
    CONSTRAINT UQ_redemptions_redemptionCode UNIQUE (redemptionCode),
    CONSTRAINT CK_redemptions_amountSpent CHECK (amountSpent >= 0),
    CONSTRAINT FK_redemptions_players FOREIGN KEY (playerID) REFERENCES dbo.players(playerID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_redemptions_merchantProducts FOREIGN KEY (merchantProductID) REFERENCES dbo.merchantProducts(merchantProductID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_redemptions_currencies FOREIGN KEY (currencyID) REFERENCES dbo.currencies(currencyID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

/*==============================================================
  IA
==============================================================*/

CREATE TABLE dbo.aiAgents
(
    aiAgentID BIGINT IDENTITY(1,1) NOT NULL,
    modelName NVARCHAR(30) NOT NULL,
    agentPurpose NVARCHAR(200) NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_aiAgents_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_aiAgents_createdAt DEFAULT (SYSUTCDATETIME()),
    updatedAt DATETIME2 NULL,
    CONSTRAINT PK_aiAgents PRIMARY KEY (aiAgentID)
);

CREATE TABLE dbo.aiExecutionStatusTypes
(
    aiExecutionStatusTypeID BIGINT IDENTITY(1,1) NOT NULL,
    statusName NVARCHAR(30) NOT NULL,
    statusDescription NVARCHAR(150) NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_aiExecutionStatusTypes_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_aiExecutionStatusTypes_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_aiExecutionStatusTypes PRIMARY KEY (aiExecutionStatusTypeID),
    CONSTRAINT UQ_aiExecutionStatusTypes_statusName UNIQUE (statusName)
);

CREATE TABLE dbo.aiExecutions
(
    aiExecutionID BIGINT IDENTITY(1,1) NOT NULL,
    aiAgentID BIGINT NOT NULL,
    propositionID BIGINT NOT NULL,
    resourceID BIGINT NOT NULL,
    aiExecutionStatusTypeID BIGINT NOT NULL,
    startedAt DATETIME2 NOT NULL,
    completedAt DATETIME2 NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_aiExecutions_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_aiExecutions PRIMARY KEY (aiExecutionID),
    CONSTRAINT CK_aiExecutions_dates CHECK (completedAt IS NULL OR completedAt >= startedAt),
    CONSTRAINT FK_aiExecutions_aiAgents FOREIGN KEY (aiAgentID) REFERENCES dbo.aiAgents(aiAgentID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_aiExecutions_propositions FOREIGN KEY (propositionID) REFERENCES dbo.propositions(propositionID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_aiExecutions_resources FOREIGN KEY (resourceID) REFERENCES dbo.resources(resourceID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_aiExecutions_statusTypes FOREIGN KEY (aiExecutionStatusTypeID) REFERENCES dbo.aiExecutionStatusTypes(aiExecutionStatusTypeID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.aiRequests
(
    aiRequestID BIGINT IDENTITY(1,1) NOT NULL,
    aiExecutionID BIGINT NOT NULL,
    requestPayload NVARCHAR(MAX) NOT NULL,
    requestedAt DATETIME2 NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_aiRequests_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_aiRequests PRIMARY KEY (aiRequestID),
    CONSTRAINT FK_aiRequests_aiExecutions FOREIGN KEY (aiExecutionID) REFERENCES dbo.aiExecutions(aiExecutionID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.aiValidationResultTypes
(
    aiValidationResultTypeID BIGINT IDENTITY(1,1) NOT NULL,
    resultName NVARCHAR(50) NOT NULL,
    resultDescription NVARCHAR(150) NOT NULL,
    isActive BIT NOT NULL CONSTRAINT DF_aiValidationResultTypes_isActive DEFAULT (1),
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_aiValidationResultTypes_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_aiValidationResultTypes PRIMARY KEY (aiValidationResultTypeID),
    CONSTRAINT UQ_aiValidationResultTypes_resultName UNIQUE (resultName)
);

CREATE TABLE dbo.aiResponses
(
    aiResponseID BIGINT IDENTITY(1,1) NOT NULL,
    aiExecutionID BIGINT NOT NULL,
    aiValidationResultType BIGINT NOT NULL,
    responsePayload NVARCHAR(MAX) NOT NULL,
    confidenceScore DECIMAL(5,2) NULL,
    respondedAt DATETIME2 NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_aiResponses_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_aiResponses PRIMARY KEY (aiResponseID),
    CONSTRAINT CK_aiResponses_confidenceScore CHECK (confidenceScore IS NULL OR confidenceScore BETWEEN 0 AND 100),
    CONSTRAINT FK_aiResponses_aiExecutions FOREIGN KEY (aiExecutionID) REFERENCES dbo.aiExecutions(aiExecutionID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_aiResponses_aiValidationResultTypes FOREIGN KEY (aiValidationResultType) REFERENCES dbo.aiValidationResultTypes(aiValidationResultTypeID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE TABLE dbo.severityLevels
(
    severityLevelID BIGINT IDENTITY(1,1) NOT NULL,
    severityName NVARCHAR(20) NOT NULL,
    severityDescription NVARCHAR(100) NOT NULL,
    CONSTRAINT PK_severityLevels PRIMARY KEY (severityLevelID),
    CONSTRAINT UQ_severityLevels_severityName UNIQUE (severityName)
);

CREATE TABLE dbo.aiFindingTypes
(
    aiFindingTypeID BIGINT IDENTITY(1,1) NOT NULL,
    findingTypeName NVARCHAR(50) NOT NULL,
    findingTypeDescription NVARCHAR(150) NOT NULL,
    CONSTRAINT PK_aiFindingTypes PRIMARY KEY (aiFindingTypeID),
    CONSTRAINT UQ_aiFindingTypes_findingTypeName UNIQUE (findingTypeName)
);

CREATE TABLE dbo.aiFindings
(
    aiFindingID BIGINT IDENTITY(1,1) NOT NULL,
    aiExecutionID BIGINT NOT NULL,
    severityLevelID BIGINT NOT NULL,
    aiFindingTypeID BIGINT NOT NULL,
    findingDetails NVARCHAR(500) NOT NULL,
    isBlocking BIT NOT NULL,
    createdAt DATETIME2 NOT NULL CONSTRAINT DF_aiFindings_createdAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_aiFindings PRIMARY KEY (aiFindingID),
    CONSTRAINT FK_aiFindings_aiExecutions FOREIGN KEY (aiExecutionID) REFERENCES dbo.aiExecutions(aiExecutionID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_aiFindings_severityLevels FOREIGN KEY (severityLevelID) REFERENCES dbo.severityLevels(severityLevelID) ON DELETE NO ACTION ON UPDATE NO ACTION,
    CONSTRAINT FK_aiFindings_aiFindingTypes FOREIGN KEY (aiFindingTypeID) REFERENCES dbo.aiFindingTypes(aiFindingTypeID) ON DELETE NO ACTION ON UPDATE NO ACTION
);

/*==============================================================
  Índices en FKs y campos frecuentes
==============================================================*/

CREATE INDEX IX_countries_localCurrencyID ON dbo.countries(localCurrencyID);
CREATE INDEX IX_players_countryID ON dbo.players(countryID);
CREATE INDEX IX_players_email ON dbo.players(email);
CREATE INDEX IX_players_username ON dbo.players(username);
CREATE INDEX IX_systemUsers_playerID ON dbo.systemUsers(playerID);
CREATE INDEX IX_systemUsers_roleID ON dbo.systemUsers(roleID);
CREATE INDEX IX_loginAttempts_playerID ON dbo.loginAttempts(playerID);
CREATE INDEX IX_loginAttempts_attemptedAt ON dbo.loginAttempts(attemptedAt);

CREATE INDEX IX_exchangePairs_baseCurrencyID ON dbo.exchangePairs(baseCurrencyID);
CREATE INDEX IX_exchangePairs_quoteCurrencyID ON dbo.exchangePairs(quoteCurrencyID);
CREATE INDEX IX_currentExchangeRates_exchangePairID ON dbo.currentExchangeRates(exchangePairID);
CREATE INDEX IX_historicalExchangeRates_currentExchangeRateID ON dbo.historicalExchangeRates(currentExchangeRateID);

CREATE INDEX IX_currencyConfigurations_currencyID ON dbo.currencyConfigurations(currencyID);
CREATE INDEX IX_balances_playerID ON dbo.balances(playerID);
CREATE INDEX IX_balances_currencyID ON dbo.balances(currencyID);
CREATE INDEX IX_transactions_playerID ON dbo.transactions(playerID);
CREATE INDEX IX_transactions_propositionID ON dbo.transactions(propositionID);
CREATE INDEX IX_transactions_predictionID ON dbo.transactions(predictionID);
CREATE INDEX IX_transactions_currencyID ON dbo.transactions(currencyID);
CREATE INDEX IX_transactions_transactionDate ON dbo.transactions(transactionDate);

CREATE INDEX IX_paymentMethods_providerID ON dbo.paymentMethods(providerID);
CREATE INDEX IX_paymentAttempts_paymentMethodID ON dbo.paymentAttempts(paymentMethodID);
CREATE INDEX IX_paymentAttempts_playerID ON dbo.paymentAttempts(playerID);
CREATE INDEX IX_paymentAttempts_currencyID ON dbo.paymentAttempts(currencyID);
CREATE INDEX IX_moneyBalance_playerID ON dbo.moneyBalance(playerID);
CREATE INDEX IX_moneyBalance_currencyID ON dbo.moneyBalance(currencyID);

CREATE INDEX IX_playersSocialNetwork_playerID ON dbo.playersSocialNetwork(playerID);
CREATE INDEX IX_playersSocialNetwork_socialNetworkID ON dbo.playersSocialNetwork(socialNetworkID);
CREATE INDEX IX_resources_playerSocialNetworkID ON dbo.resources(playerSocialNetworkID);
CREATE INDEX IX_resources_resourceTypeID ON dbo.resources(resourceTypeID);
CREATE INDEX IX_resources_capturedAt ON dbo.resources(capturedAt);

CREATE INDEX IX_propositions_creatorPlayerID ON dbo.propositions(creatorPlayerID);
CREATE INDEX IX_propositions_targetPlayerID ON dbo.propositions(targetPlayerID);
CREATE INDEX IX_propositions_relatedResourceID ON dbo.propositions(relatedResourceID);
CREATE INDEX IX_propositions_propositionStatusID ON dbo.propositions(propositionStatusID);
CREATE INDEX IX_propositions_predictionsDeadline ON dbo.propositions(predictionsDeadline);
CREATE INDEX IX_propositionVotes_propositionID ON dbo.propositionVotes(propositionID);
CREATE INDEX IX_propositionVotes_voterPlayerID ON dbo.propositionVotes(voterPlayerID);

CREATE INDEX IX_predictions_propositionID ON dbo.predictions(propositionID);
CREATE INDEX IX_predictions_playerID ON dbo.predictions(playerID);
CREATE INDEX IX_predictions_predictionTypeID ON dbo.predictions(predictionTypeID);
CREATE INDEX IX_predictions_predictedAt ON dbo.predictions(predictedAt);
CREATE INDEX IX_predictionStakes_predictionID ON dbo.predictionStakes(predictionID);
CREATE INDEX IX_predictionStakes_currencyID ON dbo.predictionStakes(currencyID);
CREATE INDEX IX_predictionResults_predictionID ON dbo.predictionResults(predictionID);
CREATE INDEX IX_predictionSettlements_predictionResultID ON dbo.predictionSettlements(predictionResultID);
CREATE INDEX IX_predictionSettlements_recipientPlayerID ON dbo.predictionSettlements(recipientPlayerID);

CREATE INDEX IX_propositionResult_propositionID ON dbo.propositionResult(propositionID);
CREATE INDEX IX_propositionResult_evidenceResourceID ON dbo.propositionResult(evidenceResourceID);

CREATE INDEX IX_auditLogs_entityName_entityID ON dbo.auditLogs(entityName, entityID);
CREATE INDEX IX_auditLogs_performedByPlayerID ON dbo.auditLogs(performedByPlayerID);
CREATE INDEX IX_auditLogs_performedAt ON dbo.auditLogs(performedAt);

CREATE INDEX IX_merchants_countryID ON dbo.merchants(countryID);
CREATE INDEX IX_merchantProducts_merchantID ON dbo.merchantProducts(merchantID);
CREATE INDEX IX_merchantProducts_currencyID ON dbo.merchantProducts(currencyID);
CREATE INDEX IX_redemptions_playerID ON dbo.redemptions(playerID);

CREATE INDEX IX_aiExecutions_aiAgentID ON dbo.aiExecutions(aiAgentID);
CREATE INDEX IX_aiExecutions_propositionID ON dbo.aiExecutions(propositionID);
CREATE INDEX IX_aiExecutions_resourceID ON dbo.aiExecutions(resourceID);
CREATE INDEX IX_aiRequests_aiExecutionID ON dbo.aiRequests(aiExecutionID);
CREATE INDEX IX_aiResponses_aiExecutionID ON dbo.aiResponses(aiExecutionID);
CREATE INDEX IX_aiFindings_aiExecutionID ON dbo.aiFindings(aiExecutionID);
GO

/*==============================================================
  Fin del script
==============================================================*/
