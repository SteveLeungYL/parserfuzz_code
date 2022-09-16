CREATE TABLE kv ( k INT PRIMARY KEY, v INT );
INSERT INTO kv VALUES (1, 2), (3, 4), (5, 6), (7, 8);
CREATE TABLE kvString ( k STRING PRIMARY KEY, v STRING );
INSERT INTO kvString VALUES ('like1', 'hell%'), ('like2', 'worl%');
SELECT * FROM kv WHERE k IN (SELECT k FROM kv);
SELECT * FROM kv WHERE (k,v) IN (SELECT * FROM kv);
SELECT 'hello' LIKE v FROM kvString WHERE k LIKE 'like%' ORDER BY k;
SELECT 'hello' ~ replace(v, '%', '.*') FROM kvString WHERE k ~ 'like[1-2]' ORDER BY k;
SELECT * FROM kv WHERE k IN (1, 5.0, 9);
