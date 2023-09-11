import os
import libtmux

server = libtmux.Server()

session = server.new_session(session_name="fuzzing_gdb_debug", kill_session=True, attach=False)

for i in range(8):
    cur_window = session.new_window(attach=True, window_name="fuzzing_test_"+str(i))
    cur_pane = cur_window.attached_pane
    cur_pane.send_keys('sudo docker exec -it sqlright_testing /bin/bash /home/tidb/scripts/envoke_gdb_debug_helper.sh %d'%(i))

server.attach_session(target_session="fuzzing_gdb_debug")
