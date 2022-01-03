SET @@session.myisam_sort_buffer_size = 4294967296;
SET @@session.myisam_sort_buffer_size = 8388608;
CREATE USER u1@localhost IDENTIFIED BY 'secret' REQUIRE SSL;
GRANT SELECT ON test.* TO u1@localhost;
DROP USER u1@localhost;
