call mtr.add_suppression("You need to use --log-bin to make --binlog-format work.");
call mtr.add_suppression("You need to use --log-bin to make --log-replica-updates work.");
SELECT @@GLOBAL.log_bin;
SELECT @@GLOBAL.log_replica_updates;
