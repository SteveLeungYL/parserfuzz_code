DROP TABLE IF EXISTS t1;
drop table t1;
DROP TABLE t1;
SET character_set_client = utf8;
set names binary;
CREATE TABLE t1(c1 INT COMMENT 't�est');
CREATE TABLE t1(c1 INT);
ALTER TABLE t1 ADD COLUMN c2 INT COMMENT 'test􏿿';
DROP TABLE t1;
