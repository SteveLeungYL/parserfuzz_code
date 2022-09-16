CREATE TABLE c (c_id INT PRIMARY KEY, bill TEXT);
CREATE TABLE o (o_id INT PRIMARY KEY, c_id INT, ship TEXT);
INSERT INTO c VALUES (1, 'CA'), (2, 'TX'), (3, 'MA'), (4, 'TX'), (5, NULL), (6, 'FL');
INSERT INTO o VALUES (10, 1, 'CA'), (20, 1, 'CA'), (30, 1, 'CA'), (40, 2, 'CA'), (50, 2, 'TX'), (60, 2, NULL), (70, 4, 'WY'), (80, 4, NULL), (90, 6, 'WA');
TRUNCATE table c; 
SELECT * FROM c WHERE EXISTS(SELECT * FROM o WHERE o.c_id=c.c_id);
SELECT * FROM c WHERE NOT EXISTS(SELECT * FROM o WHERE o.c_id=c.c_id);
SELECT * FROM c WHERE bill < ANY(SELECT ship FROM o WHERE o.c_id=c.c_id);
