CREATE TABLE onecolumn (x INT);
INSERT INTO onecolumn(x) VALUES (44), (NULL), (42);
SELECT * FROM onecolumn AS a(x) CROSS JOIN onecolumn AS b(y);
SELECT * FROM onecolumn AS a(x) JOIN onecolumn AS b(y) ON a.x = b.y;
SELECT * FROM onecolumn AS a LEFT OUTER JOIN onecolumn AS b USING(x) ORDER BY x;
SELECT * FROM onecolumn AS a RIGHT OUTER JOIN onecolumn AS b USING(x) ORDER BY x;
SELECT * FROM (VALUES ('a'), ('b')) WITH ORDINALITY AS x(name, i);

