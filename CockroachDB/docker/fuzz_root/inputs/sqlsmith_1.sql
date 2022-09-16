CREATE TABLE ab ( a INT, b INT AS (a % 2) STORED, INDEX (b) );
CREATE TABLE cd ( c INT, d INT AS (c % 2) VIRTUAL );
SELECT NULL FROM ab AS ab1 JOIN cd AS cd1 JOIN cd AS cd2 ON cd1.c = cd2.c JOIN ab AS ab2 ON cd2.c = ab2.a AND cd2.c = ab2.crdb_internal_mvcc_timestamp AND cd1.c = ab2.a AND cd1.c = ab2.b AND cd1.d = ab2.b ON ab1.b = cd1.d JOIN cd AS cd3 ON ab1.b = cd3.c AND cd2.c = cd3.d AND cd1.d = cd3.c
