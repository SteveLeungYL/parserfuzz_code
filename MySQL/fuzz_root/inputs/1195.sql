use mysql;
create database MYSQLtest;
grant all on MySQLtest.* to mysqltest_1@localhost;
show grants for mysqltest_1@localhost;
flush privileges;
show grants for mysqltest_1@localhost;
flush privileges;
drop database MYSQLtest;
