CREATE EXTENSION test_shm_mq;
SELECT test_shm_mq(1024, '', 2000, 1);
SELECT test_shm_mq(1024, 'a', 2001, 1);
