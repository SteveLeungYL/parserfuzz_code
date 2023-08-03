import libtmux
import time
import os

os.chdir("/home/tidb/fuzz_root")

server = libtmux.Server()
session = server.new_session(session_name="fuzzing_setup")
create_database_window = session.new_window(attach=False, window_name="create_database")
pane = create_database_window.attached_pane

pane.send_keys("cd /home/tidb/fuzz_root")
pane.send_keys("./tidb-server-ori -P 8000 -socket /tmp/mysql_0.sql -path $(pwd)/db_data")
time.sleep(10)
create_database_window_client = session.new_window(attach=False, window_name="create_database_client_setup")
pane_client = create_database_window_client.attached_pane
pane_client.send_keys("cd /home/tidb/fuzz_root")
pane_client.send_keys("mysql -P 8000 -u root --socket /tmp/mysql_0.sql -e \"create database if not exists test_rsg1; create database if not exists test_init;\"")
time.sleep(5)
create_database_window.kill_window()
create_database_window_client.kill_window()
session.kill_session()
os.system("kill `pidof tidb-server-ori`")
