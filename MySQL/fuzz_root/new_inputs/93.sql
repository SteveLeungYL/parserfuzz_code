CREATE USER 'empl_external'@'localhost' IDENTIFIED WITH test_plugin_server AS 'employee';
CREATE USER 'employee'@'localhost' IDENTIFIED BY 'passkey';
GRANT PROXY ON 'employee'@'localhost' TO 'empl_external'@'localhost';
ALTER USER employee@localhost ACCOUNT LOCK;
SELECT USER(), CURRENT_USER();
ALTER USER empl_external@localhost ACCOUNT LOCK;
ALTER USER employee@localhost ACCOUNT UNLOCK;
DROP USER 'empl_external'@'localhost', 'employee'@'localhost';
