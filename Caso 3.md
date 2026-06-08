not nullMotor de base de datos: SQL Server 2022
Nombre Base de datos: Gathel - Gaming the life
Contexto: Gathel es un juego digital de predicciones basado en acciones y eventos de la vida real de las personas, validados mediante redes sociales e inteligencia artificial.
Los jugadores asocian cuentas de redes sociales, crean proposiciones sobre eventos reales, otros votan/predicen con puntos o dinero real, y la AI valida los resultados mediante el contenido publicado.
Cada jugador inicia con 100 puntos. Las predicciones se hacen con puntos (máx 1 pt por predicción) o dinero real (monto libre). La plataforma cobra comisiones por evento.

# Tables:

/*---------------Seguridad y acceso---------------*/

## userRoles
- userRoleID PK
- roleName nvarchar(30) 
- roleDescription nvarchar(150)
- isActive bit 
- createdAt datetime2 

## permissions
- permissionID PK
- permissionName nvarchar(30)
- permissionDescription nvarchar(150)
- isActive bit
- createdAt datetime2

## rolePermissions
- userRoleID FK
- permissionID FK
- createdAt datetime2

## currencies
- currencyID PK
- currencyCode nvarchar(20) 
- currencyName nvarchar(45) 
- currencySymbol nvarchar(30)
- isActive bit
- createdAt datetime2 
- updatedAt datetime2 null
- Únicos: currencyCode
- Incluye monedas reales y virtuales, por ejemplo POINT

## countries
- countryID PK 
- countryName nvarchar(50) 
- iso2Code char(2) 
- iso3Code char(3) 
- localCurrencyID FK
- isActive bit
- createdAt datetime2 
- updatedAt datetime2 null
- Únicos: iso2Code; iso3Code

## players
- playerID PK 
- countryID FK 
- email nvarchar(150)
- username nvarchar(50) 
- firstName nvarchar(40) 
- lastName nvarchar(40) 
- secondLastName nvarchar(40) null
- passwordHash nvarchar(255) 
- isEmailVerified bit  default (0)
- isActive bit
- lastLoginAt datetime2 null
- createdAt datetime2 
- updatedAt datetime2 null
- Únicos: email; username

## systemUsers
- playerID FK 
- roleID FK  
- createdAt datetime2 

## loginAttempts
- loginAttemptID PK  
- playerID FK 
- attemptedEmail nvarchar(150)
- ipAddress nvarchar(45) 
- wasSuccessful bit 
- failureReason nvarchar(100) null
- attemptedAt datetime2 
- createdAt datetime2 

/*---------------Geografía y Monedas---------------*/

## exchangePairs
- exchangePairID PK  
- baseCurrencyID FK  
- quoteCurrencyID FK 
- isActive bit
- createdAt datetime2 
- updatedAt datetime2 null
- Únicos: baseCurrencyID, quoteCurrencyID; Checks: baseCurrencyID <> quoteCurrencyID

## currentExchangeRates
- currentExchangeRateID PK
- exchangePairID FK  
- baseCurrencyID FK  
- quoteCurrencyID FK  
- buyRate decimal(18,6)
- sellRate decimal(18,6)
- sourceName nvarchar(50) 
- updatedAt datetime2 
- Únicos: exchangePairID; Checks: baseCurrencyID <> quoteCurrencyID

## historicalExchangeRates
- historicalExchangeRateID PK 
- currentExchangeRateID FK 
- buyRate decimal(18,6)
- sellRate decimal(18,6)
- validFrom datetime2 
- validTo datetime2 null
- recordedAt datetime2 
- Checks: validTo IS NULL OR validTo >= validFrom

/*---------------Configuración de Puntos---------------*/

## currencyConfigurations
- currencyConfigurationID PK
- currencyID FK
- configCode nvarchar(30) 
- configName nvarchar(80) 
- initialBalance decimal(18,6)
- maxAmountPerPrediction decimal(18,6)
- platformFeePercent decimal(5,2)
- proposerFeePercent decimal(5,2)
- validationFailurePenaltyPercent decimal(5,2)
- propositionRejectionPenalty decimal(18,6)
- validFrom datetime2 
- validTo datetime2 null
- isCurrent bit
- createdAt datetime2 
- updatedAt datetime2 null
- Únicos: configCode; Checks: validTo IS NULL OR validTo >= validFrom

## balances
- balanceID PK
- playerID FK
- currencyID FK
- availableAmount decimal(18,6)
- reservedAmount decimal(18,6)
- totalAmountEarned decimal(18,6)
- totalAmountSpent decimal(18,6)
- createdAt datetime2 
- updatedAt datetime2 null
- isCurrent bit
- Únicos: playerID, currencyID

## transactionTypes
- transactionTypeCodeID PK
- typeName nvarchar(50) 
- typeDescription nvarchar(150)
- isActive bit
- createdAt datetime2
- Únicos: typeName

## transactions
- transactionID PK
- playerID FK 
- transactionTypeCodeID FK 
- propositionID FK 
- predictionID FK 
- currencyID FK 
- amount decimal(18,6) 
- balanceBefore decimal(18,6)
- balanceAfter decimal(18,6)  
- description nvarchar(200) null
- checksum nvarchar(80)
- transactionDate datetime2 
- createdAt datetime2 
- Checks: (propositionID IS NOT NULL OR predictionID IS NOT NULL)

/*---------------Métodos de Pago y Dinero Real---------------*/

## providers
- providerID PK 
- providerName nvarchar(50) 
- providerDescription nvarchar(150) null
- isActive bit
- Únicos: providerName

## paymentTransactionsStatus
- statusCodeID PK  
- statusName nvarchar(50) 
- statusDescription nvarchar(150)
- isActive bit
- createdAt datetime2 
- Únicos: statusName

## paymentOperationTypes
- operationTypeCodeID PK  
- operationTypeName nvarchar(50) 
- operationTypeDescription nvarchar(150)
- isActive bit
- createdAt datetime2 
- Únicos: operationTypeName

## paymentMethods
- paymentMethodID PK
- providerID FK 
- methodName nvarchar(50) 
- methodDescription nvarchar(150) 
- apiURL nvarchar(255) 
- config nvarchar(max) 
- isActive bit
- createdAt datetime2 
- updatedAt datetime2 null
- Únicos: methodName

## paymentAttempts
- paymentAttemptID PK
- paymentMethodID FK 
- playerID FK 
- operationTypeCodeID FK 
- targetEntityType nvarchar(50) 
- targetEntityID bigint 
- sourceEntityType nvarchar(50)
- sourceEntityID bigint
- amount decimal(18,6)  
- currencyID FK  
- exchangeRate decimal(18,6)
- exchangeRateID FK 
- paymentStatusID FK
- result nvarchar(30) 
- requestPayload nvarchar(max) 
- responsePayload nvarchar(max) 
- transactionReference nvarchar(150) 
- checksum nvarchar(80) 
- postedAt datetime2 
- createdAt datetime2 

## moneyBalance
- moneyBalanceID PK
- playerID FK 
- currencyID FK 
- availableAmount decimal(18,6)
- reservedAmount decimal(18,6)
- totalDeposited decimal(18,6)
- totalWithdrawn decimal(18,6)  
- createdAt datetime2 
- validUntil datetime2 null
- isActive bit
- Únicos: playerID, currencyID

/*---------------Redes Sociales---------------*/

## socialNetworks
- socialNetworkID PK
- socialNetworkName nvarchar(50) 
- socialNetworkDescription nvarchar(150)
- baseURL nvarchar(150)
- apiURL nvarchar(255)
- config nvarchar(max)
- isActive bit
- createdAt datetime2 
- updatedAt datetime2 null
- Únicos: socialNetworkName

## playersSocialNetwork
- playerSocialNetworkID PK
- playerID FK 
- socialNetworkID FK
- externalAccountID nvarchar(150) 
- externalUsername nvarchar(100) 
- isAuthorized bit default (0)
- isActive bit
- linkedAt datetime2 null
- createdAt datetime2 
- updatedAt datetime2 null
- Únicos: playerID, socialNetworkID, externalAccountID

## playerSocialNetworkTokens
- playerSocialNetworkTokenID PK
- playerSocialNetworkID FK
- accessTokenHash
- refreshTokenHash
- tokenExpiresAt
- isActive
- createdAt

## resourceTypes
- resourceTypeID PK
- resourceTypeName nvarchar(50) 
- resourceTypeDescription nvarchar(150)
- isActive bit
- createdAt datetime2 
- Únicos: resourceTypeName

## resources
- resourceID PK 
- playerSocialNetworkID FK
- resourceTypeID FK 
- externalResourceID nvarchar(150) 
- contentURL nvarchar(500) 
- contentHash nvarchar(80)
- capturedAt datetime2 
- eventOccurredAt datetime2 null
- validationStatus nvarchar(30)  default ('pending')
- isActive bit
- createdAt datetime2 
- updatedAt datetime2 null
- Únicos: playerSocialNetworkID, externalResourceID, resourceID 

/*---------------Núcleo del juego: Proposiciones---------------*/

## propositionStatus
- propositionStatusID PK
- statusName nvarchar(50) 
- statusDescription nvarchar(150)
- isActive bit
- createdAt datetime2 
- Únicos: statusName

## propositions
- propositionID PK  
- creatorPlayerID FK 
- targetPlayerID FK 
- relatedResourceID FK
- propositionStatusID FK 
- propositionText nvarchar(500) 
- predictionsDeadline datetime2 
- votingDeadline datetime2 
- acceptedAt datetime2 
- closedAt datetime2 
- createdAt datetime2 
- updatedAt datetime2 null
- isActive bit

## propositionVotes
- propositionVoteID PK
- propositionID FK
- voterPlayerID FK
- votedAt datetime2 
- createdAt datetime2 
- Únicos: propositionID, voterPlayerID

## propositionStatusHistories
- propositionStatusHistorieID PK
- propositionID FK 
- previousStatusCodeID FK 
- currentStatusCodeID FK 
- changeDetails nvarchar(250)
- changedByPlayerID FK
- changedAt datetime2 
- createdAt datetime2 

/*---------------Predicciones---------------*/

## predictionTypes
- predictionTypeID PK 
- predictionTypeName nvarchar(50) 
- predictionTypeDescription nvarchar(150)
- isActive bit
- createdAt datetime2 
- Únicos: predictionTypeName

## predictions
- predictionID PK
- propositionID FK
- playerID FK 
- predictionTypeID FK
- predictionActive bit
- checksum nvarchar(80) null
- predictedAt datetime2 
- createdAt datetime2 
- updatedAt datetime2 null
- isActive bit

## predictionStakes
- predictionStakeID PK
- predictionID FK
- currencyID FK
- amount decimal(18,6)
- createdAt datetime2
- updatedAt datetime2 null
- isActive bit

## predictionStakeHistories
- predictionStakeHistoryID PK
- predictionStakeID FK
- previousAmount decimal(18,6)
- currentAmount decimal(18,6)
- previousCurrencyID FK null
- currentCurrencyID FK null
- changedAt datetime2 
- createdAt datetime2

## predictionResults
- predictionResultID PK
- predictionID FK
- didWin bit
- determinedAt datetime2
- createdAt datetime2
- updatedAt datetime2 null
- isActive bit

## predictionSettlements
- predictionSettlementID PK
- predictionResultID FK
- recipientPlayerID FK
- currencyID FK
- amount decimal(18,6)
- settlementStatusTypeID FK
- settlementTypeName nvarchar(30)
- settledByPlayerID FK
- settledAt datetime2
- createdAt datetime2

## settlementStatusTypes
- settlementStatusTypeID PK
- settlementStatusName nvarchar(30)

/*---------------Validación de Resultados---------------*/

## propositionResultTypes
- resultTypeID PK  
- statusName nvarchar(50) 
- statusDescription nvarchar(150)
- isActive bit
- createdAt datetime2 
- Únicos: statusName

## propositionResult
- propositionResultID PK 
- propositionID FK 
- resultTypeID FK
- propositionFulfilled bit null
- evidenceResourceID FK 
- validatedAt datetime2 
- createdAt datetime2 
- updatedAt datetime2 null
- isActive bit
- Únicos: propositionID

/*---------------Log general---------------*/

## changeSources
- sourceCode PK 
- sourceName nvarchar(50) 
- sourceDescription nvarchar(150) null
- isActive bit
- createdAt datetime2 
- updatedAt datetime2 null
- Únicos: sourceName

## auditLogs
- auditLogID PK 
- entityName nvarchar(60) 
- entityID bigint 
- auditActionTypeID FK
- changeDetails nvarchar(500) null
- previousValues nvarchar(max) null
- newValues nvarchar(max) null
- changeSourceCode FK 
- performedByPlayerID NULL
- performedAt datetime2 
- createdAt datetime2 

## auditActionTypes
- auditActionTypeID PK
- actionName nvarchar(30)
- actionDescription nvarchar(150)

/*---------------Comercios afiliados---------------*/

## merchants
- merchantID PK 
- merchantName nvarchar(100) 
- countryID FK 
- isActive bit
- createdAt datetime2 
- updatedAt datetime2 null
- Únicos: merchantName

## merchantProducts
- merchantProductID PK
- merchantID FK 
- productCode nvarchar(50) 
- productName nvarchar(120) 
- productDescription nvarchar(500) null
- costAmount decimal(18,6)  check (costAmount >= 0)
- currencyID FK
- isActive bit
- createdAt datetime2 
- updatedAt datetime2 null
- Únicos: merchantID, productCode

## redemptions
- redemptionID PK  
- playerID FK 
- merchantProductID FK 
- currencyID FK
- amountSpent decimal(18,6)  check (amountSpent >= 0)
- redemptionCode nvarchar(80) 
- redeemedAt datetime2 
- createdAt datetime2 
- updatedAt datetime2 null
- Únicos: redemptionCode

/*---------------IA---------------*/

## aiAgents
- aiAgentID PK
- modelName nvarchar(30)
- agentPurpose nvarchar(200)
- isActive bit
- createdAt datetime2
- updatedAt datetime2 null

## aiExecutions
- aiExecutionID PK
- aiAgentID FK
- propositionID FK
- resourceID FK
- aiExecutionStatusTypeID FK
- startedAt datetime2
- completedAt datetime2 null
- createdAt datetime2

## aiExecutionStatusTypes
- aiExecutionStatusTypeID PK
- statusName nvarchar(30)
- statusDescription nvarchar(150)
- isActive bit
- createdAt datetime2

/*(Prompt enviado Contexto enviado JSON enviado)*/
## aiRequests
- aiRequestID PK
- aiExecutionID FK
- requestPayload nvarchar(max)
- requestedAt datetime2
- createdAt datetime2

## aiResponses
- aiResponseID PK
- aiExecutionID FK
- aiValidationResultType FK
- responsePayload nvarchar(max)
- confidenceScore decimal(5,2) null
- respondedAt datetime2
- createdAt datetime2

## aiValidationResultTypes
- aiValidationResultTypeID PK
- resultName nvarchar(50)
- resultDescription nvarchar(150)
- isActive bit
- createdAt datetime2

## aiFindings
- aiFindingID PK
- aiExecutionID FK
- severityLevelID FK
- aiFindingTypeID FK
- findingDetails nvarchar(500)
- isBlocking bit
- createdAt datetime2

## severityLevels
- severityLevelID PK
- severityName nvarchar(20)
- severityDescription nvarchar(100)

## aiFindingTypes
- aiFindingTypeID PK
- findingTypeName nvarchar(50)
- findingTypeDescription nvarchar(150)


Todas las FKs con ON DELETE NO ACTION y ON UPDATE NO ACTION.
para todo los datos not null, a excepción de que se indique lo contrario
CHECK constraints en montos (>= 0), puntos (>= 0), porcentajes (entre 0 y 100), y emails (LIKE '%@%').
Índices en todas las FKs y en campos de búsqueda frecuente (playerID, propositionID, predictedAt, transactionDate).