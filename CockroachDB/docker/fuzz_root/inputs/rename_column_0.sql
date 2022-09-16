CREATE TABLE users ( uid    INT PRIMARY KEY, name  VARCHAR NOT NULL, title VARCHAR, INDEX foo (name) STORING (title), UNIQUE INDEX bar (uid, name) );
INSERT INTO users VALUES (1, 'tom', 'cat'),(2, 'jerry', 'rat');
ALTER TABLE IF EXISTS uses RENAME COLUMN title TO species;
ALTER TABLE users RENAME COLUMN title TO species;
ALTER TABLE users RENAME COLUMN name TO username;
CREATE VIEW v1 AS SELECT id FROM users WHERE username = 'tom';
ALTER TABLE users RENAME COLUMN id TO uid;

