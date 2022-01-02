DROP FUNCTION IF EXISTS f1;
CREATE FUNCTION f1() RETURNS INT RETURN 1;
RENAME TABLE mysql.procs_priv TO mysql.procs_priv_backup;
FLUSH TABLE mysql.procs_priv;
DROP FUNCTION f1;
SHOW WARNINGS;
RENAME TABLE mysql.procs_priv_backup TO mysql.procs_priv;
FLUSH TABLE mysql.procs_priv;
