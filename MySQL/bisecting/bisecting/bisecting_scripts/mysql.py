from pathlib import Path
import os

import constants
import utils
from loguru import logger
import subprocess
import time
import mysql_builder

def force_copy_data_backup(hexsha: str):
    backup_data = os.path.join(constants.MYSQL_ROOT, hexsha, "data_all/ori_data")
    cur_data = os.path.join(constants.MYSQL_ROOT, hexsha, "data_all/data_0")
    utils.remove_directory(cur_data)
    utils.copy_directory(backup_data, cur_data)

def get_mysqld_binary(cur_dir:str):
    if os.path.isdir(os.path.join(cur_dir, "share")) and os.path.isdir(os.path.join(cur_dir, "bin")):
        # The third scenario, has (bin, extra, scripts, share, support-files)
        command = "./bin/mysqld"
        return command

    elif os.path.isdir(os.path.join(cur_dir, "bin/client")):
        # The second scenario, has (client, scripts and sql)
        command = "./bin/sql/mysqld"
        return command
    else:
        # The first scenario, all binaries directly in bin dir.
        command = "./bin/mysqld"
        return command

def check_mysql_server_alive() -> bool:
    p = subprocess.run("lsof -i -P",
                        shell=True,
                        stdin=subprocess.DEVNULL,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT
                        )
    
    res = p.stdout.decode()
    if "mysqld" in res:
        return True
    else:
        return False

def start_mysqld_server(hexsha: str):

    if utils.is_failed_commit(hexsha):
        # Running with previous known failed_to_compile commit. Don't bother to try.
        return

    p = subprocess.run("pkill mysqld",
                        shell=True,
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL,
                        stdin=subprocess.DEVNULL
                        )
    
    while (check_mysql_server_alive()):
        time.sleep(2)
        p = subprocess.run("pkill -9 mysqld",
                        shell=True,
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL,
                        stdin=subprocess.DEVNULL
                        )

    cur_mysql_root = os.path.join(constants.MYSQL_ROOT, hexsha)

    if not os.path.isdir(cur_mysql_root):
        mysql_builder.setup_mysql_commit(hexsha)
    
    if not os.path.isdir(cur_mysql_root):
        # Failed to compile the current version of MySQL. Return.
        utils.dump_failed_commit(hexsha)
        return

    cur_mysql_data_dir = os.path.join(cur_mysql_root, "data_all/data_0")

    # Firstly, restore the database backup. 
    force_copy_data_backup(hexsha)

    logger.debug("Starting mysqld server with hash: %s" % (hexsha))

    # And then, call MySQL server process. 
    mysql_command = [
        get_mysqld_binary(cur_mysql_root),
        "--basedir=" + str(cur_mysql_root),
        "--datadir=" + str(cur_mysql_data_dir),
        "--port=" + str(constants.MYSQL_SERVER_PORT),
        "--socket=" + str(constants.MYSQL_SERVER_SOCKET),
        "&"
    ]

    mysql_command = " ".join(mysql_command)

    p = subprocess.Popen(
                        mysql_command,
                        cwd=cur_mysql_root,
                        shell=True,
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL,
                        stdin=subprocess.DEVNULL
                        )
    # Do not block the Popen, let it run and return. We will later use `pkill` to kill the mysqld process.

    time.sleep(3)
    while (not check_mysql_server_alive()):
        logger.debug("mysql server not alive after 3 seconds. ")
        time.sleep(3)
    
    return

def execute_queries(query: str, hexsha: str):
    """Entry function. Call this function to run the mysql server and the client. 
        Run the passed in query and check whether the query crashes the server.
    """

    start_mysqld_server(hexsha=hexsha)

    if not check_mysql_server_alive():
        # Did not find the mysql server process after the start_mysqld function. Failed to compile.
        return constants.RESULT.FAIL_TO_COMPILE
    
    cur_mysql_root = os.path.join(constants.MYSQL_ROOT, hexsha)

    mysql_client = get_mysql_binary(cur_mysql_root) + " -u root -N --socket=%s" % (constants.MYSQL_SERVER_SOCKET)

    # clean_database_query = "DROP DATABASE IF EXISTS test_sqlright1; CREATE DATABASE IF NOT EXISTS test_sqlright1; "
    clean_database_query = "DROP DATABASE IF EXISTS test123; CREATE DATABASE IF NOT EXISTS test123; "

    utils.execute_command(
        mysql_client, input_contents=clean_database_query, cwd=cur_mysql_root, timeout=1  # 3 seconds timeout. 
    )

    # safe_query = "USE test_sqlright1; " + query
    safe_query = "USE test123; " + query

    all_outputs = ""
    status = 0
    all_error_msg = ""

    output, error_msg, status = utils.execute_query_helper(
        mysql_client, input_contents=safe_query, cwd=cur_mysql_root, timeout=5  # 5 seconds timeout. 
    )

    logger.debug(f"Query:\n\n{safe_query}")
    logger.debug(f"Result: \n\n{output}\n")
    logger.debug(f"Directory: {cur_mysql_root}")
    logger.debug(f"Return Code: {status}")

    if check_mysql_server_alive():
        return constants.RESULT.PASS
    else:
        return constants.RESULT.SEG_FAULT