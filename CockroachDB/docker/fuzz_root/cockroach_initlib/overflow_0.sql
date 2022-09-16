CREATE TABLE large_numbers (a INT8);
INSERT INTO large_numbers VALUES (9223372036854775807),(1);
SELECT sum_int(a) FROM large_numbers;
DELETE FROM large_numbers;
INSERT INTO large_numbers VALUES (-9223372036854775808),(-1);
SELECT sum_int(a) FROM large_numbers;
