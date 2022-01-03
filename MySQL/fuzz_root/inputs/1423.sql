FLUSH PRIVILEGES;
SELECT USER(),CURRENT_USER();
CREATE USER u1@localhost;
ALTER USER u1@localhost IDENTIFIED BY 'pass1';
SET PASSWORD FOR u1@localhost = 'pass2';
SET PASSWORD = 'cant have';
DROP USER u1@localhost;
