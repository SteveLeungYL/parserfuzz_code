CREATE TABLE kv (k INT PRIMARY KEY, v INT, w INT, s STRING, i INTERVAL);
CREATE TABLE abc ( a VARCHAR PRIMARY KEY, b FLOAT, c BOOLEAN, d DECIMAL);
INSERT INTO kv VALUES (1, 2, 3, 'a', '1min'), (3, 4, 5, 'a', '2sec'), (5, NULL, 5, NULL, NULL), (6, 2, 3, 'b', '1ms'), (7, 2, 2, 'b', '4 days'), (8, 4, 2, 'A', '3 years');
INSERT INTO abc VALUES ('one', 1.5, true, 5::decimal), ('two', 2.0, false, 1.1::decimal);
SELECT avg(b), sum(b), avg(d), sum(d) FROM abc
SELECT min(1), count(1), max(1), sum_int(1), avg(1)::float, sum(1), stddev_samp(1), stddev_pop(1), variance(1), var_pop(1), var_samp(1), bool_and(true), bool_or(true), to_hex(xor_agg(b'\x01')), corr(1, 2), sqrdiff(1), covar_pop(1, 2), covar_samp(1, 2), regr_intercept(1, 2), regr_r2(1, 2), regr_slope(1, 2), regr_sxx(1, 1), regr_sxy(1, 1), regr_syy(1, 1), regr_count(1, 1), regr_avgx(1, 1), regr_avgy(1, 1);
SELECT count_rows() FROM generate_series(1,100);
SELECT array_agg(1) FROM kv;
SELECT json_agg(1) FROM kv;
SELECT 3 FROM kv HAVING TRUE;
SELECT * FROM kv GROUP BY v, count(DISTINCT w);
SELECT count(*), kv.s FROM kv GROUP BY kv.s;
SELECT max(z), min(x) FROM xyz WHERE (z,x) = (SELECT max(z), min(x) FROM xyz);
SELECT v, mark, count(*) FILTER (WHERE k > 5), count(*), max(k) FILTER (WHERE k < 8) FROM filter_test GROUP BY v, mark;


