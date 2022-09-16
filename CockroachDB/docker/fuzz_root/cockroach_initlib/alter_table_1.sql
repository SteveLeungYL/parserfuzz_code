CREATE TABLE decomputed_column (a INT PRIMARY KEY, b INT AS ( a + 1 ) STORED, FAMILY "primary" (a, b));
CREATE TABLE audit(x INT);
ALTER TABLE audit EXPERIMENTAL_AUDIT SET READ WRITE;
INSERT INTO decomputed_column VALUES (1), (2);
INSERT INTO decomputed_column VALUES (3, NULL), (4, 99);
ALTER TABLE decomputed_column ALTER COLUMN b DROP STORED;
INSERT INTO decomputed_column VALUES (3, NULL), (4, 99);
ALTER TABLE audit ADD COLUMN y INT;
select a, b from decomputed_column order by a;
