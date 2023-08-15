import os
import constants
import utils
from loguru import logger
import subprocess
import time
import tidb_builder
import shutil

def get_tidb_binary_sub_dir(cur_dir:str):
    command = "bin"
    return command

def check_tidb_server_alive() -> bool:
    # may be deprecated
    p = subprocess.run("lsof -i -P",
                        shell=True,
                        stdin=subprocess.DEVNULL,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT
                        )
    
    res = p.stdout.decode()
    if "tidb-serv" in res:
        return True
    else:
        return False

def stop_tidb_server():
    p = subprocess.run("pkill tidb-server",
                        shell=True,
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL,
                        stdin=subprocess.DEVNULL
                        )
    
    while (check_tidb_server_alive()):
        time.sleep(1)
        p = subprocess.run("pkill -9 tidb-server",
                        shell=True,
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL,
                        stdin=subprocess.DEVNULL
                        )
    logger.debug("Stopped server.")

def start_tidb_server(hexsha: str):
    stop_tidb_server()

    if utils.is_failed_commit(hexsha):
        # Running with previous known failed_to_compile commit. Don't bother to try.
        return

    cur_tidb_cache_root = os.path.join(constants.TIDB_CACHE_ROOT, hexsha)

    if not os.path.isdir(cur_tidb_cache_root):
        tidb_builder.setup_tidb_commit(hexsha)
    
    if not os.path.isdir(cur_tidb_cache_root):
        # Failed to compile the current version of MySQL. Return.
        utils.dump_failed_commit(hexsha)
        return

    cur_tidb_cache_root = os.path.join(cur_tidb_cache_root, get_tidb_binary_sub_dir(cur_tidb_cache_root))
    if os.path.isdir(os.path.join(cur_tidb_cache_root, "db_data")):
        # remove the old database folder.
        shutil.rmtree(os.path.isdir(os.path.join(cur_tidb_cache_root, "db_data")))

    logger.debug("Starting tidb server with hash: %s" % (hexsha))

    # And then, call TiDB server process. 
    tidb_server_launch_command = [
        "./tidb-server",
        f"-P {constants.TIDB_SERVER_PORT}",
        f"-socket {constants.TIDB_SERVER_SOCKET}",
        "-path $(pwd)/db_data"
    ]

    tidb_server_launch_command = " ".join(tidb_server_launch_command)

    logger.debug("Running command: %s" % tidb_server_launch_command)

    _ = subprocess.Popen(
                        tidb_server_launch_command,
                        cwd=cur_tidb_cache_root,
                        shell=True,
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL,
                        stdin=subprocess.DEVNULL
                        )
    # Do not block the Popen, let it run and return. We will later use `pkill` to kill the TiDB-server process.

    trial = 0
    while (not check_tidb_server_alive()):
        time.sleep(0.1)
        trial += 1
        if trial >= 60:
            logger.warning("TiDB-Server not alive after 6 seconds. ")
            return

    time.sleep(0.1)
    stop_tidb_server()
    
    return

def execute_queries(query: str, hexsha: str):
    """Entry function. Call this function to run the mysql server and the client. 
        Run the passed in query and check whether the query crashes the server.
    """

    start_tidb_server(hexsha=hexsha)

    check_wait_trial = 0
    if not check_tidb_server_alive():
        # Did not find the tidb server process after the start_tidb_server function. wait for a while before abort.
        time.sleep(0.1)
        check_wait_trial += 1

        if check_wait_trial > 100:
            # tidb server did not start after 10 second.
            return constants.RESULT.FAIL_TO_COMPILE
    
    cur_mysql_root = os.path.join(constants.TIDB_CACHE_ROOT, hexsha)

    mysql_client = f"mysql -h 127.0.0.1 -P {constants.TIDB_SERVER_PORT} -u root --socket={constants.TIDB_SERVER_SOCKET} "

    # clean_database_query = "DROP DATABASE IF EXISTS test_sqlright1; CREATE DATABASE IF NOT EXISTS test_sqlright1; "
    clean_database_query = "DROP DATABASE IF EXISTS test_rsg1; CREATE DATABASE IF NOT EXISTS test_rsg1; "

    utils.execute_command(
        mysql_client, input_contents=clean_database_query, timeout=3  # 3 seconds timeout. 
    )

    safe_query = "USE test_rsg1; " + query

    all_outputs = ""
    status = 0
    all_error_msg = ""

    output, error_msg, status = utils.execute_query_helper(
        mysql_client, input_contents=safe_query, timeout=5  # 5 seconds timeout. 
    )

    # safe_query itself is far too long. Do not print it.
    # logger.debug(f"Query:\n\n{safe_query}")
    logger.debug(f"Result: \n\n{output}\n")
    logger.debug(f"Directory: {cur_mysql_root}")
    logger.debug(f"Return Code: {status}")

    is_potential_crash = False
    if "ERROR 1105" in output or "ERROR 2013" in output:
        is_potential_crash = True
    if check_tidb_server_alive() and not is_potential_crash:
        stop_tidb_server()
        return constants.RESULT.PASS
    else:
        stop_tidb_server()
        return constants.RESULT.SEG_FAULT