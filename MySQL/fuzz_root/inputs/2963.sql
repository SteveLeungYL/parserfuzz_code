FLUSH PRIVILEGES;
CREATE USER tester@localhost IDENTIFIED WITH caching_sha2_password BY 'abcd';
DROP USER tester@localhost;
