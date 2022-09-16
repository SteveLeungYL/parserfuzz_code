CREATE TABLE abc (a int primary key, b int, c int);
CREATE TABLE new_abc (a int, b int, c int);
INSERT INTO new_abc VALUES (1, 2, 3), (2, 3, 4)
INSERT INTO abc VALUES (1, 20, 300), (2, 30, 400);
UPDATE abc SET b = other.b + 1, c = other.c + 1 FROM abc AS other WHERE abc.a = other.a;
UPDATE abc SET b = other.b + 1 FROM abc AS other WHERE abc.a = other.a;
UPDATE abc SET b = other.b + 1 FROM abc AS other WHERE abc.a = other.a AND abc.a = 1;
UPDATE abc SET b = new_abc.b, c = new_abc.c FROM new_abc WHERE abc.a = new_abc.a;
UPDATE abc SET b = old.b + 1, c = old.c + 2 FROM abc AS old WHERE abc.a = old.a RETURNING abc.a, abc.b AS new_b, old.b as old_b, abc.c as new_c, old.c as old_c;

