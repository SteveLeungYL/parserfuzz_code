CREATE TABLE kv ( k INT PRIMARY KEY, v INT );
UPDATE kv SET v = (SELECT (10, 11));
UPDATE kv SET v = 3.2;
UPDATE kv SET (k, v) = (SELECT 3, 3.2);
UPDATE kv SET v = '3.2'::STRING;
INSERT INTO kv VALUES (1, 2), (3, 4), (5, 6), (7, 8);
UPDATE kv2 SET v = 'i' WHERE k IN ('a');
SELECT * FROM kv;
