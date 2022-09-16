CREATE TABLE users ( id    INT PRIMARY KEY, name  VARCHAR NOT NULL, title VARCHAR, INDEX foo (name), UNIQUE INDEX bar (id, name), INDEX baw (name, title) );
CREATE TABLE othertable ( x INT, y INT, INDEX baw (x), INDEX yak (y, x) );
DROP INDEX IF EXISTS ark;
DROP INDEX IF EXISTS yak;
CREATE VIEW v AS SELECT id FROM users;
CREATE INDEX i ON users(id);
