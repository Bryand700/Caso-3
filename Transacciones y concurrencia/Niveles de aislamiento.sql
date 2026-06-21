/*Read Uncommitted
Permite leer datos que todavía no han sido confirmados mediante COMMIT.
Problema que sí puede ocurrir: dirty read, y los demas, pero solamente
se trabajara con el dirty read, pues es el unico nivel que lo permite*/

/*Sesión A*/

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRAN;

UPDATE dbo.balances
SET availableAmount = 50.00
WHERE balanceID = 1;

WAITFOR DELAY '00:00:10';

ROLLBACK;

/*Sesión B*/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT availableAmount
FROM dbo.balances
WHERE balanceID = 1;

/*
Qué se demuestra:
La sesión B puede leer 50.00 aunque esa actualización nunca se 
confirme. Después del ROLLBACK, el valor real vuelve a 100.00.
Eso es un dirty read.

¿Cómo identificarlo?
Se detecta cuando: se leen valores que luego desaparecen,
los reportes muestran datos inconsistentes,
aparecen resultados imposibles de reproducir.}

Mitigación utilizar READ COMMITTED o superior.
*/

/*READ COMMITTED
Problema que todavía puede ocurrir: nonrepeatable read.

Sesión A*/

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRAN;

UPDATE dbo.balances
SET availableAmount = 80.00
WHERE balanceID = 1;

COMMIT;

/*Sesión B*/

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRAN;

SELECT availableAmount
FROM dbo.balances
WHERE balanceID = 1;

WAITFOR DELAY '00:00:10';

SELECT availableAmount
FROM dbo.balances
WHERE balanceID = 1;

COMMIT;

/*Qué se demuestra:
Si la primera lectura da 100.00 y la segunda da 80.00, 
la transacción B leyó dos valores distintos para la misma 
fila dentro de la misma transacción. Eso es un nonrepeatable read.*
¿Cómo identificarlo?

La misma consulta devuelve resultados distintos sin que la propia 
transacción haya modificado datos.

Mitigación
Utilizar:
REPEATABLE READ
cuando la transacción requiere que los datos leídos permanezcan estables.
*/

/*REPEATABLE READ
Mantiene bloqueadas las filas leídas hasta finalizar la transacción.
Problema que todavía puede ocurrir: phantom.

Sesión A*/

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRAN;

SELECT *
FROM dbo.transactions
WHERE playerID = 1 AND transactionDate >= '2026-06-01';

WAITFOR DELAY '00:00:10';

SELECT *
FROM dbo.transactions
WHERE playerID = 1 AND transactionDate >= '2026-06-01';

COMMIT;

/*Sesión B*/

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRAN;

INSERT INTO dbo.transactions
(
    playerID, transactionTypeCodeID, propositionID, predictionID,
    currencyID, amount, balanceBefore, balanceAfter,
    description, checksum, transactionDate, createdAt
)
VALUES
(
    1, 1, 1, 1,
    1, 1.000000, 100.000000, 99.000000,
    'Inserción de prueba', 'abc123', SYSDATETIME(), SYSDATETIME()
);

COMMIT;

/*Qué se demuestra:
La segunda lectura de la sesión A puede mostrar una fila nueva que antes no
existía. Eso es un phantom.

¿Cómo identificarlo?
La cantidad de filas cambia aunque ninguna fila previamente leída haya  sido modificada.
Mitigación: utilizar SERIALIZABLE cuando se requiere estabilidad completa del conjunto de resultados.
*/


/*SERIALIZABLE

Problema: Aunque garantiza máxima consistencia, aumenta:
Bloqueos
Esperas
Deadlocks

Sesión A*/

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRAN;

SELECT *
FROM dbo.transactions
WHERE playerID = 1 AND transactionDate >= '2026-06-01';

WAITFOR DELAY '00:00:10';

SELECT *
FROM dbo.transactions
WHERE playerID = 1 AND transactionDate >= '2026-06-01';

COMMIT;

/*Sesión B*/

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRAN;

INSERT INTO dbo.transactions
(
    playerID, transactionTypeCodeID, propositionID, predictionID,
    currencyID, amount, balanceBefore, balanceAfter,
    description, checksum, transactionDate, createdAt
)
VALUES
(
    1, 1, 1, 1,
    1, 1.000000, 100.000000, 99.000000,
    'Inserción bloqueada', 'xyz789', SYSDATETIME(), SYSDATETIME()
);

COMMIT;

/*Qué se demuestra:
La inserción de la sesión B puede quedar bloqueada o esperar hasta que la sesión A
termine. Así se evita el phantom y también los otros problemas.*/