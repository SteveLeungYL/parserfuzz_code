CREATE TABLE ab (a INT, b INT);
INSERT INTO ab VALUES (1, 10), (2, 20), (3, 30), (4, NULL), (NULL, 50), (NULL, NULL);
SELECT * FROM ab WHERE a IN (1, 3, 4);
SELECT * FROM ab WHERE a IN (1, 3, 4, NULL);
SELECT * FROM ab WHERE (a, b) IN ((1, 10), (3, 30), (4, 40));
SELECT * FROM ab WHERE (a, b) IN ((1, 10), (4, NULL), (NULL, 50));
