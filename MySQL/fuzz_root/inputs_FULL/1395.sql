call mtr.add_suppression("\\[Warning\\] \\[[^]]*\\] \\[[^]]*\\] You need to use --log-bin to make --binlog-format work.");
DROP TABLE IF EXISTS t1, t2;
set @@session.binlog_format='row';
create table t1 (a int);
insert into t1 values (1);
create table t2 select * from t1;
drop table t1, t2;
