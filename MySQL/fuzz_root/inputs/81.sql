CREATE USER pwd_history_plugin@localhost IDENTIFIED WITH 'test_plugin_server' PASSWORD HISTORY 1;
SHOW CREATE USER pwd_history_plugin@localhost;
ALTER USER pwd_history_plugin@localhost IDENTIFIED WITH 'test_plugin_server' PASSWORD REUSE INTERVAL 1 DAY;
SHOW CREATE USER pwd_history_plugin@localhost;
DROP USER pwd_history_plugin@localhost;
CREATE USER mohit@localhost IDENTIFIED BY 'mohit_native' PASSWORD HISTORY 1;
ALTER USER mohit@localhost IDENTIFIED WITH 'test_plugin_server' AS 'haha';
SHOW CREATE USER mohit@localhost;
DROP USER mohit@localhost;
