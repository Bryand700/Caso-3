Motor de base de datos: SQL Server 2022
Nombre Base de datos: Gathel - Gaming the life
Contexto: Gathel es un juego digital de predicciones basado en acciones y eventos de la vida real de las personas, validados mediante redes sociales e inteligencia artificial.
Los jugadores asocian cuentas de redes sociales, crean proposiciones sobre eventos reales, otros votan/predicen con puntos o dinero real, y la AI valida los resultados mediante el contenido publicado.
Cada jugador inicia con 100 puntos. Las predicciones se hacen con puntos (máx 1 pt por predicción) o dinero real (monto libre). La plataforma cobra comisiones por evento.

# Tables:

/*---------------Seguridad y acceso ---------------*/

## userRoles
- userRoleID PK
- roleName varchar 30
- roleDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## permissions
- permissionID PK
- permissionName varchar 30
- permissionDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## rolePermissions
- userRoleID FK
- permissionID FK
- createdAt timestamp
- updatedAt timestamp

## players
- playerID PK
- countryID FK
- email varchar 150
- username varchar 50
- firstName varchar 40
- lastName varchar 40
- secondLastName varchar 40
- passwordHash varchar 255
- isEmailVerified boolean
- isActive boolean
- lastLoginAt timestamp
- createdAt timestamp
- updatedAt timestamp

## systemUsers
- playerID FK
- roleID FK
- createdAt timestamp
- updatedAt timestamp

## loginAttempts
- loginAttemptID PK
- playerID FK NULL
- attemptedEmail varchar 150
- ipAddress varchar 45
- wasSuccessful boolean
- failureReason varchar 100
- attemptedAt timestamp
- createdAt timestamp

/*---------------Geografía y Monedas---------------*/

## currencys
- currencyID PK
- currencyCode varchar 20
- currencyName varchar 45
- currencySymbol varchar 30
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## countrys
- countryID PK
- countryName varchar 50
- iso2Code char 2
- iso3Code char 3
- localCurrencyID bigint
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## currentExchangeRates
- currentExchangeRateID PK
- exchangePairID bigint
- baseCurrencyID bigint
- quoteCurrencyID bigint
- buyRate numeric 18,6
- sellRate numeric 18,6
- sourceName varchar 50
- updatedAt timestamp

## historicalExchangeRates
- historicalExchangeRateID PK
- currentExchangeRateID FK
- buyRate numeric 18,6
- sellRate numeric 18,6
- validFrom timestamp
- validTo timestamp
- recordedAt timestamp

/*---------------Configuración de Puntos (no hardcodeado)---------------*/

## pointConfigurations
- pointConfigurationID PK
- configCode varchar 30
- configName varchar 80
- initialBalance int
- maxPointsPerPrediction int
- platformFeePercent decimal 5,2
- proposerFeePercent decimal 5,2
- validationFailurePenaltyPercent decimal 5,2
- propositionRejectionPenalty int
- validFrom timestamp
- validTo timestamp
- isCurrent boolean
- createdAt timestamp
- updatedAt timestamp

## pointBalances
- pointBalanceID PK
- playerID FK
- availablePoints int
- reservedPoints int
- totalPointsEarned int
- totalPointsSpent int
- lastUpdatedAt timestamp
- createdAt timestamp
- updatedAt timestamp

## pointTransactionTypes
- pointTransactionTypeCodeID PK 
- typeName varchar 50
- typeDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## pointTransactions
- pointTransactionID PK
- playerID FK
- pointTransactionTypeCodeID FK
- propositionID bigint NULL
- predictionID bigint NULL
- pointsAmount int
- balanceBefore int
- balanceAfter int
- description varchar 200
- checksum varchar 80
- transactionDate timestamp
- createdAt timestamp

/*---------------Métodos de Pago y Dinero Real---------------*/

## paymentMethods
- paymentmethodID PK
- providerID FK
- methodName varchar 50
- methodDescription varchar 150
- apiURL varchar 255
- config JSON NULL
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## providers
- providerID PK
- providerName varchar 50
- providerDescription varchar 150
- isActive boolean

## paymentTransactionsStatus
- statusCodeID PK
- statusName varchar 50
- statusDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## paymentOperationTypes
- operationTypeCodeID PK
- operationTypeName varchar 50
- operationTypeDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## paymentAttempts
- paymentAttemptID PK
- paymentmethodID FK
- playerID FK
- operationTypeCodeID FK
- referencedObjectID FK NULL
- sourceObjectID FK NULL
- amount decimal 18,6
- currencyID FK
- exchangeRate decimal 18,6
- exchangeRateID FK
- paymentStatusID FK
- result varchar 30
- requestPayload JSON NULL
- responsePayload JSON NULL
- transactionReference varchar 150 -----------------------
- checksum varchar 80
- postedAt timestamp
- createdAt timestamp
- updatedAt timestamp

## moneyBalance
- moneyBalanceID PK
- playerID FK
- currencyID FK
- availableAmount decimal 18,6
- reservedAmount decimal 18,6
- totalDeposited decimal 18,6
- totalWithdrawn decimal 18,6
- lastUpdatedAt timestamp
- createdAt timestamp
- updatedAt timestamp

/*---------------Redes Sociales---------------*/

## socialsNetwork
- socialNetworkID PK 
- socialNetworkName varchar 50
- socialNetworkDescription varchar 150
- baseURL varchar 150
- apiURL varchar 255
- config JSON NULL
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## playersSocialNetwork
- playerSocialNetworkID PK
- playerID FK
- socialNetworkID FK
- externalAccountID varchar 150
- externalUsername varchar 100
- accessTokenHash varchar 500
- tokenExpiresAt timestamp NULL
- isAuthorized boolean
- isActive boolean
- linkedAt timestamp
- createdAt timestamp
- updatedAt timestamp

## resourceTypes
- resourceTypeID PK 
- resourceTypeName varchar 50
- resourceTypeDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## resources
- resourceID PK
- playerSocialNetworkID FK
- resourceTypeID FK
- externalResourceID varchar 150
- contentURL varchar 500
- contentHash varchar 80
- capturedAt timestamp
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

/*---------------Núcleo del juego: Proposiciones---------------*/

## propositionsStatus
- propositionStatusID PK
- statusName varchar 50
- statusDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## propositions
- propositionID PK
- creatorPlayerID FK
- targetPlayerID FK
- relatedResourceID FK NULL -----------
- propositionStatusID FK
- propositionText varchar 500
- predictionsDeadline timestamp NULL
- votingDeadline timestamp NULL
- acceptedAt timestamp NULL
- closedAt timestamp NULL
- createdAt timestamp
- updatedAt timestamp

## propositionVotes
- propositionVoteID PK
- propositionID FK
- voterPlayerID FK
- votedAt timestamp
- createdAt timestamp

## propositionStatusLogs
- propositionStatusLogID PK
- propositionID FK
- previousStatusCodeID FK
- currentStatusCodeID FK
- changeDetails varchar 250
- changedByPlayerID FK
- changedAt timestamp
- createdAt timestamp

/*---------------Predicciones---------------*/

## predictionTypes
- predictionTypeID PK 
- predictionTypeName varchar 50
- predictionTypeDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## predictions
- predictionID PK
- propositionID FK
- playerID FK
- predictionTypeID FK
- predictionActive boolean
- pointsRisked int NULL
- moneyRisked decimal 18,6 NULL
- currencyID bigint NULL
- exchangeRate decimal 18,6 NULL
- exchangeRateID bigint NULL
- checksum varchar 80
- predictedAt timestamp
- createdAt timestamp
- updatedAt timestamp

## predictionAmountLogs
- predictionAmountLogID PK
- predictionID FK
- previousPointsAmount int
- currentPointsAmount int
- previousMoneyAmount decimal 18,6
- currentMoneyAmount decimal 18,6
- changedAt timestamp
- createdAt timestamp

## predictionOutcome
- predictionOutcomeID PK
- predictionID FK
- didWin boolean
- pointsWon int
- moneyWon decimal 18,6
- currencyID bigint NULL
- platformFeeApplied decimal 18,6 NULL
- proposerFeeApplied decimal 18,6 NULL
- settledAt timestamp
- createdAt timestamp

/*---------------Validación de Resultados---------------*/

## propositionResultStatus
- resultStatusID PK
- statusName varchar 50
- statusDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## propositionResult
- propositionResultID PK
- propositionID FK
- resultStatusID FK
- propositionFulfilled boolean NULL
- evidenceResourceID FK NULL
- validatedAt timestamp NULL
- createdAt timestamp
- updatedAt timestamp

/*---------------Bitácora de procesos  ---------------*/

## processLogs
- processLogID PK
- processType varchar 50
- processID bigint
- sourceTypeID FK
- contentURL varchar 500
- requestPayload JSON NULL
- responsePayload JSON NULL
- result varchar 30
- executedAt timestamp
- createdAt timestamp

## sourceTypes
- sourceTypeID PK
- sourceTypeName varchar 50
- sourceTypeDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

/*---------------Log general ---------------*/

## changeSources
- sourceCode PK varchar 30
- sourceName varchar 50
- sourceDescription varchar 150
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## auditLogs
- auditLogID PK
- entityName varchar 60
- entityID bigint
- actionCode varchar 30
- changeDetails varchar 500
- previousValues JSON NULL
- newValues JSON NULL
- changeSourceCode varchar 30
- performedByPlayerID bigint NULL
- performedAt timestamp
- createdAt timestamp

/*---------------Comercios afiliados---------------*/

## merchants
- merchantID PK
- merchantName varchar 100
- countryID bigint
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## merchantProducts
- merchantProductID PK
- merchantID bigint
- productCode varchar 50
- productName varchar 120
- productDescription varchar 500
- pointsCost int
- isActive boolean
- createdAt timestamp
- updatedAt timestamp

## pointRedemption
- pointRedemptionID PK
- playerID bigint
- merchantProductID bigint
- pointsSpent int
- redemptionCode varchar 80
- redeemedAt timestamp
- createdAt timestamp
- updatedAt timestamp

Todas las FKs con ON DELETE NO ACTION y ON UPDATE NO ACTION.
CHECK constraints en montos (>= 0), puntos (>= 0), porcentajes (entre 0 y 100), y emails (LIKE '%@%').
Índices en todas las FKs y en campos de búsqueda frecuente (playerID, propositionID, predictedAt, transactionDate).
