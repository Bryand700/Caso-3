-- flyway:executeInTransaction=false
/* ============================================================================
   GATHEL - Security Lab Migration for Flyway Desktop / SQL Server
   Requiere ejecutarse con un usuario con permisos para CREATE LOGIN.
   No usa USE ni depende de cambios manuales en SSMS.
============================================================================ */

SET NOCOUNT ON;
SET XACT_ABORT ON;

/* 1. Server logins. Flyway clean no elimina logins del servidor. */
IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'lab_reader')
BEGIN
    EXEC(N'CREATE LOGIN [lab_reader] WITH PASSWORD = ''LabReader#2026'', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF');
END;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'lab_writer')
BEGIN
    EXEC(N'CREATE LOGIN [lab_writer] WITH PASSWORD = ''LabWriter#2026'', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF');
END;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'lab_auditor')
BEGIN
    EXEC(N'CREATE LOGIN [lab_auditor] WITH PASSWORD = ''LabAuditor#2026'', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF');
END;

/* 2. Database users. */
IF DATABASE_PRINCIPAL_ID(N'lab_reader') IS NULL
BEGIN
    EXEC(N'CREATE USER [lab_reader] FOR LOGIN [lab_reader]');
END
ELSE
BEGIN
    EXEC(N'ALTER USER [lab_reader] WITH LOGIN = [lab_reader]');
END;

IF DATABASE_PRINCIPAL_ID(N'lab_writer') IS NULL
BEGIN
    EXEC(N'CREATE USER [lab_writer] FOR LOGIN [lab_writer]');
END
ELSE
BEGIN
    EXEC(N'ALTER USER [lab_writer] WITH LOGIN = [lab_writer]');
END;

IF DATABASE_PRINCIPAL_ID(N'lab_auditor') IS NULL
BEGIN
    EXEC(N'CREATE USER [lab_auditor] FOR LOGIN [lab_auditor]');
END
ELSE
BEGIN
    EXEC(N'ALTER USER [lab_auditor] WITH LOGIN = [lab_auditor]');
END;

/* 3. Database roles. */
IF DATABASE_PRINCIPAL_ID(N'rl_gathel_reader') IS NULL
BEGIN
    EXEC(N'CREATE ROLE [rl_gathel_reader] AUTHORIZATION [dbo]');
END;

IF DATABASE_PRINCIPAL_ID(N'rl_gathel_writer') IS NULL
BEGIN
    EXEC(N'CREATE ROLE [rl_gathel_writer] AUTHORIZATION [dbo]');
END;

IF DATABASE_PRINCIPAL_ID(N'rl_gathel_auditor') IS NULL
BEGIN
    EXEC(N'CREATE ROLE [rl_gathel_auditor] AUTHORIZATION [dbo]');
END;

/* 4. Role memberships. */
IF ISNULL(IS_ROLEMEMBER(N'rl_gathel_reader', N'lab_reader'), 0) <> 1
BEGIN
    ALTER ROLE [rl_gathel_reader] ADD MEMBER [lab_reader];
END;

IF ISNULL(IS_ROLEMEMBER(N'rl_gathel_writer', N'lab_writer'), 0) <> 1
BEGIN
    ALTER ROLE [rl_gathel_writer] ADD MEMBER [lab_writer];
END;

IF ISNULL(IS_ROLEMEMBER(N'rl_gathel_auditor', N'lab_auditor'), 0) <> 1
BEGIN
    ALTER ROLE [rl_gathel_auditor] ADD MEMBER [lab_auditor];
END;

/* 5. Permissions. */
GRANT SELECT ON OBJECT::dbo.countries TO [lab_reader];
GRANT SELECT ON OBJECT::dbo.propositions TO [rl_gathel_reader];
GRANT SELECT ON OBJECT::dbo.propositions TO [lab_reader];
DENY INSERT, UPDATE, DELETE ON OBJECT::dbo.propositions TO [lab_reader];

GRANT INSERT ON OBJECT::dbo.loginAttempts TO [lab_writer];
DENY SELECT, UPDATE, DELETE ON OBJECT::dbo.loginAttempts TO [lab_writer];

GRANT SELECT ON SCHEMA::dbo TO [rl_gathel_auditor];

/* 6. Stored procedure with controlled public data. */
EXEC(N'
CREATE OR ALTER PROCEDURE dbo.sp_GetPlayerPublicProfile
    @PlayerID BIGINT
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        playerID,
        username,
        firstName,
        lastName,
        isActive
    FROM dbo.players
    WHERE playerID = @PlayerID;
END
');

DENY SELECT ON OBJECT::dbo.players TO [lab_reader];
GRANT EXECUTE ON OBJECT::dbo.sp_GetPlayerPublicProfile TO [lab_reader];

/* 7. Dynamic Data Masking. */
IF EXISTS (
    SELECT 1
    FROM sys.columns c
    INNER JOIN sys.tables t ON c.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = N'dbo' AND t.name = N'players' AND c.name = N'email' AND c.is_masked = 0
)
BEGIN
    EXEC(N'ALTER TABLE dbo.players ALTER COLUMN email ADD MASKED WITH (FUNCTION = ''email()'')');
END;

IF EXISTS (
    SELECT 1
    FROM sys.columns c
    INNER JOIN sys.tables t ON c.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = N'dbo' AND t.name = N'loginAttempts' AND c.name = N'attemptedEmail' AND c.is_masked = 0
)
BEGIN
    EXEC(N'ALTER TABLE dbo.loginAttempts ALTER COLUMN attemptedEmail ADD MASKED WITH (FUNCTION = ''email()'')');
END;

IF EXISTS (
    SELECT 1
    FROM sys.columns c
    INNER JOIN sys.tables t ON c.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = N'dbo' AND t.name = N'loginAttempts' AND c.name = N'ipAddress' AND c.is_masked = 0
)
BEGIN
    EXEC(N'ALTER TABLE dbo.loginAttempts ALTER COLUMN ipAddress ADD MASKED WITH (FUNCTION = ''partial(0,"xxx.xxx.xxx.",4)'')');
END;

/* 8. Row-Level Security. */
IF SCHEMA_ID(N'SecurityLab') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA SecurityLab AUTHORIZATION dbo');
END;

IF OBJECT_ID(N'SecurityLab.UserPlayerMap', N'U') IS NULL
BEGIN
    EXEC(N'
    CREATE TABLE SecurityLab.UserPlayerMap
    (
        dbUserName SYSNAME NOT NULL,
        playerID BIGINT NOT NULL,
        CONSTRAINT PK_UserPlayerMap PRIMARY KEY (dbUserName),
        CONSTRAINT UQ_UserPlayerMap_playerID UNIQUE (playerID),
        CONSTRAINT FK_UserPlayerMap_players FOREIGN KEY (playerID) REFERENCES dbo.players(playerID)
    )');
END;

;MERGE SecurityLab.UserPlayerMap AS target
USING
(
    SELECT N'lab_reader' AS dbUserName, CAST(1 AS BIGINT) AS playerID
    UNION ALL SELECT N'lab_writer', CAST(2 AS BIGINT)
    UNION ALL SELECT N'lab_auditor', CAST(3 AS BIGINT)
) AS source
ON target.dbUserName = source.dbUserName
WHEN MATCHED THEN
    UPDATE SET playerID = source.playerID
WHEN NOT MATCHED THEN
    INSERT (dbUserName, playerID)
    VALUES (source.dbUserName, source.playerID);

/* El REST API utiliza una única cuenta técnica para representar a múltiples
   jugadores autenticados por la aplicación. Estas cuentas necesitan consultar
   todas las proposiciones, pero no deben asociarse con un único playerID. */
IF OBJECT_ID(N'SecurityLab.ApplicationServiceAccounts', N'U') IS NULL
BEGIN
    CREATE TABLE SecurityLab.ApplicationServiceAccounts
    (
        dbUserName SYSNAME NOT NULL,
        serviceDescription NVARCHAR(200) NOT NULL,
        isActive BIT NOT NULL
            CONSTRAINT DF_ApplicationServiceAccounts_isActive DEFAULT (1),
        createdAt DATETIME2 NOT NULL
            CONSTRAINT DF_ApplicationServiceAccounts_createdAt DEFAULT (SYSUTCDATETIME()),
        updatedAt DATETIME2 NULL,
        CONSTRAINT PK_ApplicationServiceAccounts PRIMARY KEY (dbUserName)
    );
END;

IF EXISTS
(
    SELECT 1
    FROM SecurityLab.ApplicationServiceAccounts
    WHERE dbUserName = N'gathel_app'
)
BEGIN
    UPDATE SecurityLab.ApplicationServiceAccounts
    SET
        serviceDescription = N'Cuenta técnica utilizada por el REST API de Gathel',
        isActive = 1,
        updatedAt = SYSUTCDATETIME()
    WHERE dbUserName = N'gathel_app';
END
ELSE
BEGIN
    INSERT SecurityLab.ApplicationServiceAccounts
    (
        dbUserName,
        serviceDescription,
        isActive
    )
    VALUES
    (
        N'gathel_app',
        N'Cuenta técnica utilizada por el REST API de Gathel',
        1
    );
END;

IF EXISTS (SELECT 1 FROM sys.security_policies WHERE name = N'PropositionSecurityPolicy' AND schema_id = SCHEMA_ID(N'SecurityLab'))
BEGIN
    DROP SECURITY POLICY SecurityLab.PropositionSecurityPolicy;
END;

EXEC(N'
CREATE OR ALTER FUNCTION SecurityLab.fn_PropositionAccess
(
    @creatorPlayerID BIGINT,
    @targetPlayerID BIGINT
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS access_result
    WHERE EXISTS
    (
        SELECT 1
        FROM SecurityLab.UserPlayerMap AS playerMap
        WHERE playerMap.dbUserName = USER_NAME()
          AND
          (
              playerMap.playerID = @creatorPlayerID
              OR playerMap.playerID = @targetPlayerID
          )
    )
    OR USER_NAME() = N''lab_auditor''
    OR EXISTS
    (
        SELECT 1
        FROM SecurityLab.ApplicationServiceAccounts AS serviceAccount
        WHERE serviceAccount.dbUserName = USER_NAME()
          AND serviceAccount.isActive = 1
    )
');

EXEC(N'
CREATE SECURITY POLICY SecurityLab.PropositionSecurityPolicy
ADD FILTER PREDICATE SecurityLab.fn_PropositionAccess(creatorPlayerID, targetPlayerID)
ON dbo.propositions
WITH (STATE = ON)
');

/* 9. Encryption hierarchy. */
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = N'##MS_DatabaseMasterKey##')
BEGIN
    EXEC(N'CREATE MASTER KEY ENCRYPTION BY PASSWORD = ''Gathel#2026!MasterKey''');
END;

IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = N'GathelPasswordCert')
BEGIN
    EXEC(N'CREATE CERTIFICATE GathelPasswordCert WITH SUBJECT = ''Certificate for Gathel sensitive secrets''');
END;

IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = N'GathelPasswordKey')
BEGIN
    EXEC(N'CREATE SYMMETRIC KEY GathelPasswordKey WITH ALGORITHM = AES_256 ENCRYPTION BY CERTIFICATE GathelPasswordCert');
END;

/* IMPORTANTE:
   Las columnas cifradas se agregan con SQL dinámico y el UPDATE también se ejecuta
   dinámicamente. Así SQL Server no compila el UPDATE antes de que existan las columnas,
   que era la causa del error Invalid column name encryptedAccessToken/encryptedRefreshToken. */
IF COL_LENGTH(N'dbo.playerSocialNetworkTokens', N'encryptedAccessToken') IS NULL
BEGIN
    EXEC(N'ALTER TABLE dbo.playerSocialNetworkTokens ADD encryptedAccessToken VARBINARY(MAX) NULL');
END;

IF COL_LENGTH(N'dbo.playerSocialNetworkTokens', N'encryptedRefreshToken') IS NULL
BEGIN
    EXEC(N'ALTER TABLE dbo.playerSocialNetworkTokens ADD encryptedRefreshToken VARBINARY(MAX) NULL');
END;

EXEC(N'
OPEN SYMMETRIC KEY GathelPasswordKey DECRYPTION BY CERTIFICATE GathelPasswordCert;

UPDATE dbo.playerSocialNetworkTokens
SET
    encryptedAccessToken = ENCRYPTBYKEY(
        KEY_GUID(N''GathelPasswordKey''),
        CONVERT(NVARCHAR(500), accessTokenHash),
        1,
        CONVERT(VARBINARY(128), playerSocialNetworkTokenID)
    ),
    encryptedRefreshToken = ENCRYPTBYKEY(
        KEY_GUID(N''GathelPasswordKey''),
        CONVERT(NVARCHAR(500), refreshTokenHash),
        1,
        CONVERT(VARBINARY(128), playerSocialNetworkTokenID)
    )
WHERE encryptedAccessToken IS NULL
   OR encryptedRefreshToken IS NULL;

CLOSE SYMMETRIC KEY GathelPasswordKey;
');

/* 10. Auditor can see masked values for the demonstration. */
GRANT UNMASK TO [lab_auditor];
