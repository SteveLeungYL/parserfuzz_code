CREATE TABLE t (x INT PRIMARY KEY, y INT NOT NULL, z INT NOT NULL, w INT, INDEX i (x), INDEX i2 (z));
CREATE TABLE t1 (x INT PRIMARY KEY, y INT, z INT NOT NULL, w INT, v INT, INDEX i1 (y) STORING (w, v), INDEX i2 (z) STORING (y, v) );
INSERT INTO t VALUES (1, 2, 3, 4), (5, 6, 7, 8);
INSERT INTO t1 VALUES (1, 2, 3, 4, 5), (6, 7, 8, 9, 10), (11, 12, 13, 14, 15);
ALTER TABLE t1 ALTER PRIMARY KEY USING COLUMNS (z);
ALTER TABLE t ALTER PRIMARY KEY USING COLUMNS (y, z);
INSERT INTO t VALUES (9, 10, 11, 12);
UPDATE t SET x = 2 WHERE z = 7;
SELECT feature_name FROM crdb_internal.feature_usage WHERE feature_name IN ('sql.schema.alter_table.alter_primary_key') AND usage_count > 0 ORDER BY feature_name;

