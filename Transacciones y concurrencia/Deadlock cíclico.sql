/*Un deadlock cíclico T1 → T2 → T3 → T1 ocurre cuando cada transacción queda esperando un 
recurso bloqueado por otra transacción del mismo conjunto, y la espera forma un ciclo.

Abrir 3 sesiones de SSMS, una por transacción:

T1 bloquea el recurso A y luego pide B.
T2 bloquea el recurso B y luego pide C.
T3 bloquea el recurso C y luego pide A.
*/

--T1

BEGIN TRAN;

UPDATE dbo.balances
SET reservedAmount = reservedAmount + 1
WHERE balanceID = 1;

WAITFOR DELAY '00:00:10';

UPDATE dbo.balances
SET reservedAmount = reservedAmount + 1
WHERE balanceID = 2;

COMMIT;

--T2

BEGIN TRAN;

UPDATE dbo.balances
SET reservedAmount = reservedAmount + 1
WHERE balanceID = 2;

WAITFOR DELAY '00:00:10';

UPDATE dbo.balances
SET reservedAmount = reservedAmount + 1
WHERE balanceID = 3;

COMMIT;

--T3
BEGIN TRAN;

UPDATE dbo.balances
SET reservedAmount = reservedAmount + 1
WHERE balanceID = 3;

WAITFOR DELAY '00:00:10';

UPDATE dbo.balances
SET reservedAmount = reservedAmount + 1
WHERE balanceID = 1;

COMMIT;

/*
Se construyó un escenario de deadlock cíclico con tres transacciones concurrentes. 
Cada transacción bloquea un recurso y luego intenta acceder a otro bloqueado por la 
siguiente transacción, generando una dependencia circular T1 → T2 → T3 → T1. 
Este patrón corresponde a un ciclo en el grafo de espera, condición suficiente y 
necesaria para deadlock. El sistema DBMS resuelve el conflicto abortando una transacción víctima.
*/