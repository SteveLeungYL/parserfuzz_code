CREATE USER testadmin_user1;
FLUSH PRIVILEGES;
DROP USER testadmin_user1;
CREATE USER tester@localhost IDENTIFIED WITH caching_sha2_password BY 'abcd';
DROP USER tester@localhost;
