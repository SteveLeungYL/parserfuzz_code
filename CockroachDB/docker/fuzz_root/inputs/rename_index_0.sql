CREATE TABLE users ( id INT PRIMARY KEY, name  VARCHAR NOT NULL, title VARCHAR, INDEX foo (name), UNIQUE INDEX bar (id, name) );
CREATE TABLE users_dupe (id INT PRIMARY KEY, name  VARCHAR NOT NULL, title VARCHAR, INDEX foo (name), UNIQUE INDEX bar (id, name));
INSERT INTO users VALUES (1, 'tom', 'cat'),(2, 'jerry', 'rat');
INSERT INTO users_dupe VALUES (1, 'tom', 'cat'),(2, 'jerry', 'rat');
ALTER INDEX users.foo RENAME TO bar;
ALTER INDEX users@ffo RENAME TO ufo;
