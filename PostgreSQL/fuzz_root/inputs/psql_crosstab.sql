CREATE TABLE ctv_data (v, h, c, i, d) ASVALUES   ('v1','h2','foo', 3, '2015-04-01'::date),   ('v2','h1','bar', 3, '2015-01-02'),   ('v1','h0','baz', NULL, '2015-07-12'),   ('v0','h4','qux', 4, '2015-07-15'),   ('v0','h4','dbl', -3, '2014-12-15'),   ('v0',NULL,'qux', 5, '2014-07-15'),   ('v1','h2','quux',7, '2015-04-04');
ANALYZE ctv_data;
SELECT v, EXTRACT(year FROM d), count(*) FROM ctv_data GROUP BY 1, 2 ORDER BY 1, 2;
CREATE TABLE ctv_data (x int, y int, v text);
SELECT * FROM ctv_data \crosstabviewINSERT INTO ctv_data VALUES (1, 10, '*');
 SELECT * FROM ctv_data \crosstabviewDROP TABLE ctv_data;
 SELECT * FROM ctv_data \crosstabviewDROP TABLE ctv_data;
