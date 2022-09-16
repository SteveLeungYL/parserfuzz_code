CREATE TABLE xyz ( x INT, y INT, z INT, pk1 INT, pk2 INT, PRIMARY KEY (pk1, pk2) );
INSERT INTO xyz VALUES (1, 1, NULL, 1, 1), (1, 1, 2, 2, 2), (1, 1, 2, 3, 3), (1, 2, 1, 4, 4), (2, 2, 3, 5, 5), (4, 5, 6, 6, 6), (4, 1, 6, 7, 7);
CREATE TABLE abc ( a STRING, b STRING, c STRING, PRIMARY KEY (a, b, c));
INSERT INTO abc VALUES ('1', '1', '1'), ('1', '1', '2'), ('1', '2', '2');
SELECT DISTINCT ON(y) min(x) FROM xyz GROUP BY y;
SELECT DISTINCT ON(row_number() OVER(ORDER BY (pk1, pk2))) y FROM xyz ORDER BY row_number() OVER(ORDER BY (pk1, pk2)) DESC;
