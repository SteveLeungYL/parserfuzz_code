SET sql_mode = 'NO_ENGINE_SUBSTITUTION';
show fields from t1;
select is_nullable from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='t1' and COLUMN_NAME='posted_on';
drop table t1;
