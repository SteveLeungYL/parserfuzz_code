CREATE TABLE t (k1 INT, k2 INT, v INT, w INT, PRIMARY KEY (k1, k2));
SELECT start_key, end_key, replicas, lease_holder FROM [SHOW RANGES FROM TABLE t];
ALTER TABLE t SPLIT AT VALUES (1), (10);
