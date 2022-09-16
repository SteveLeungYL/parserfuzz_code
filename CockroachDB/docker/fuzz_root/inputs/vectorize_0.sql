CREATE TABLE bools (b BOOL, i INT, PRIMARY KEY (b, i)); INSERT INTO bools VALUES (true, 0), (false, 1), (true, 2), (false, 3);
CREATE TABLE nulls (a INT, b INT);
CREATE TABLE t_39827 (a STRING);
INSERT INTO t_39827 VALUES ('hello'), ('world'), ('a'), ('foo');
INSERT INTO nulls VALUES (NULL, NULL), (NULL, 1), (1, NULL), (1, 1);
SELECT count(*) FROM (SELECT DISTINCT a FROM a);
SELECT DISTINCT(a), b FROM a ORDER BY 1, 2 LIMIT 10;
SELECT a, b FROM a WHERE a * 2 < b ORDER BY 1, 2 LIMIT 5;
SELECT a FROM t_39827 ORDER BY a LIMIT 2;
