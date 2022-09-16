CREATE TABLE t ( a INT PRIMARY KEY, b INT, c INT, INDEX b_desc (b DESC), INDEX bc (b, c) );
CREATE TABLE str (k INT PRIMARY KEY, v STRING, INDEX(v));
INSERT INTO str VALUES (1, 'A'), (4, 'AB'), (2, 'ABC'), (5, 'ABCD'), (3, 'ABCDEZ'), (9, 'ABD'), (10, '\CBA'), (11, 'A%'), (12, 'CAB.*'), (13, 'CABD');
INSERT INTO t VALUES (1, 2, 3), (3, 4, 5), (5, 6, 7);
SELECT b FROM t WHERE c > 4.0 AND a < 4;
SELECT k, v FROM str WHERE v LIKE 'ABC%';
