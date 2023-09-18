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

def cleanup_data(hexsha:str):
    cur_data = os.path.join(constants.MYSQL_ROOT, hexsha, "data_all/data_0")
    utils.remove_directory(cur_data)    

def check_mysql_server_connection() -> bool:
    p = subprocess.run("lsof -i -P",
                        shell=True,
                        stdin=subprocess.DEVNULL,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT
                        )
    
    res = p.stdout.decode()
    if "mariadbd" in res:
        return True
    else:
        return False

def check_mysql_server_alive() -> bool:
    p = subprocess.run("pidof mariadbd",
                        shell=True,
                        stdin=subprocess.DEVNULL,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT
                        )
    res = p.stdout.decode()
    if res != "":
        return True
    else:
        return False

def stop_mysqld_server():
    p = subprocess.run("pkill mariadbd",
                        shell=True,
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL,
                        stdin=subprocess.DEVNULL
                        )
    
    while (check_mysql_server_alive()):
        time.sleep(2)
        p = subprocess.run("pkill -9 mariadbd",
                        shell=True,
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL,
                        stdin=subprocess.DEVNULL
                        )
    logger.debug("Stopped server.")

def start_mysqld_server(hexsha: str):
    stop_mysqld_server()

    if utils.is_failed_commit(hexsha):
        # Running with previous known failed_to_compile commit. Don't bother to try.
        return

    cur_mysql_root = os.path.join(constants.MYSQL_ROOT, hexsha)

    if not os.path.isdir(cur_mysql_root):
        mysql_builder.setup_mysql_commit(hexsha)
    
    if not os.path.isdir(cur_mysql_root):
        # Failed to compile the current version of MySQL. Return.
        utils.dump_failed_commit(hexsha)
        return

    # Firstly, restore the database backup. 
    force_copy_data_backup(hexsha)

    cur_mysql_data_dir = os.path.join(cur_mysql_root, "data_all/data_0")

    logger.debug("Starting mariadbd server with hash: %s" % (hexsha))

    # And then, call MySQL server process. 
    mysql_command = [
        "./sql/mariadbd",
        "--basedir=" + str(cur_mysql_root),
        "--datadir=" + str(cur_mysql_data_dir),
        "--port=" + str(constants.MYSQL_SERVER_PORT),
        "--socket=" + str(constants.MYSQL_SERVER_SOCKET),
        "&"
    ]

    mysql_command = " ".join(mysql_command)

    logger.debug("Running command: %s" % (mysql_command))

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
    trial = 0
    while (not check_mysql_server_connection()):
        logger.debug("mysql server not alive after 3 seconds. ")
        time.sleep(3)
        trial += 1
        if trial >= 6:
            return

    time.sleep(3)
    
    return

def execute_queries(query: str, hexsha: str):
    """
        Entry function. Call this function to run the mysql server and the client. 
        Run the passed in query and check whether the query crashes the server.
    """

    start_mysqld_server(hexsha=hexsha)

    if not check_mysql_server_alive() or not check_mysql_server_connection():
        # Did not find the mysql server process after the start_mysqld function. Failed to compile.
        return constants.RESULT.FAIL_TO_COMPILE
    
    cur_mysql_root = os.path.join(constants.MYSQL_ROOT, hexsha)

    mysql_client = "./client/mariadb -u root -N -f --socket=%s" % (constants.MYSQL_SERVER_SOCKET)

    # clean_database_query = "DROP DATABASE IF EXISTS test_sqlright1; CREATE DATABASE IF NOT EXISTS test_sqlright1; "
    clean_database_query = "DROP DATABASE IF EXISTS test123; CREATE DATABASE IF NOT EXISTS test123; "

    utils.execute_command(
        mysql_client, input_contents=clean_database_query, cwd=cur_mysql_root, timeout=1  # 3 seconds timeout. 
    )

    # safe_query = "USE test_sqlright1; " + query
    safe_query = "USE test123; " + query

    output, error_msg, status = utils.execute_query_helper(
        mysql_client, input_contents=safe_query, cwd=cur_mysql_root, timeout=5  # 5 seconds timeout. 
    )

    # logger.debug(f"Query:\n\n{safe_query}")
    logger.debug(f"Result: {output}")
    logger.debug(f"Result Error Message: {error_msg}")
    logger.debug(f"Directory: {cur_mysql_root}")
    logger.debug(f"Return Code: {status}")

    if check_mysql_server_alive():
        stop_mysqld_server()
        return constants.RESULT.PASS
    else:
        stop_mysqld_server()
        return constants.RESULT.SEG_FAULT