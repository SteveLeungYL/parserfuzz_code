import constants
import utils
from loguru import logger
import os
import shutil
import subprocess

def check_whether_buggy_commit_found():
    check_cmd = "git bisect log"
    res_out, _, _ = utils.execute_command(check_cmd, cwd=constants.MYSQL_SRC)
    if "first bad commit: [" in res_out:
        last_corr_commit = ""
        if "git bisect good " in res_out:
            last_corr_commit = res_out.split("git bisect good ")[-1].split("\n")[0]
        res_out = res_out.split("first bad commit: [")[1]
        res_out = res_out.split("]")[0]
        return res_out, last_corr_commit
    else:
        return "", "" 

def get_current_bisecting_commit():
    check_cmd = "git log -1"
    res_out, _, _ = utils.execute_command(check_cmd, cwd=constants.MYSQL_SRC)
    res_out = res_out.split(" ")[1].split("\n")[0]
    return res_out

def clean_mysql_repo():
    clean_cmd = f"git clean -xdf && git clean -xffd && git submodule foreach --recursive git clean -xffd"
    utils.execute_command(clean_cmd, cwd=constants.MYSQL_SRC)

    logger.debug(f"Clean MySQL repo completed. ")

def init_bisecting_repo(buggy_commit: str, correct_commit: str):
    init_cmd = f"git clean -xdff && git bisect reset && git bisect start {buggy_commit} {correct_commit}"
    utils.execute_command(init_cmd, cwd=constants.MYSQL_SRC)

    logger.debug(f"Init bisecting MySQL repo completed. ")

def bisect_good():
    run_cmd = f"git bisect good"
    utils.execute_command(run_cmd, cwd=constants.MYSQL_SRC)

    logger.debug(f"Git Bisect good")

def bisect_bad():
    run_cmd = f"git bisect bad"
    utils.execute_command(run_cmd, cwd=constants.MYSQL_SRC)

    logger.debug(f"Git Bisect bad")

def bisect_skip():
    run_cmd = f"git bisect skip"
    utils.execute_command(run_cmd, cwd=constants.MYSQL_SRC)

    logger.debug(f"Git Bisect skipped. ")

def checkout_and_clean_mysql_repo(hexsha: str):
    checkout_cmd = f"git checkout {hexsha} --force && git clean -xdf && git clean -xffd && git submodule foreach --recursive git clean -xffd"
    utils.execute_command(checkout_cmd, cwd=constants.MYSQL_SRC)

    logger.debug(f"Checkout commit completed: {hexsha}")

def compile_mysql_source(hexsha: str):
    BLD_PATH = os.path.join(constants.MYSQL_SRC, "bld")

    run_cmake = "cmake .. -DMYSQL_MAINTAINER_MODE=OFF -DWITH_ASAN=ON -DCMAKE_INSTALL_PREFIX=$(pwd) -DWITH_ASAN=ON"
    _, stderr, _ = utils.execute_command(run_cmake, cwd=BLD_PATH)

    run_make = "make install -j$(nproc)"
    utils.execute_command(run_make, cwd=BLD_PATH)

    if os.path.exists(os.path.join(BLD_PATH, "sql/mysqld")) and not os.path.exists(os.path.join(BLD_PATH, "sql/mariadbd")):
        # in some early version, mariadb server does not have mariadb binary, but instead named mysql. 
        shutil.copy2(os.path.join(BLD_PATH, "sql/mysqld"), os.path.join(BLD_PATH, "sql/mariadbd"))
    if os.path.exists(os.path.join(BLD_PATH, "client/mysql")) and not os.path.exists(os.path.join(BLD_PATH, "client/mariadb")):
        # in some early version, mariadb server does not have mariadb binary, but instead named mysql. 
        shutil.copy2(os.path.join(BLD_PATH, "client/mysql"), os.path.join(BLD_PATH, "client/mariadb"))

    compiled_program_path = os.path.join(BLD_PATH, "sql/mariadbd")
    if os.path.isfile(compiled_program_path):
        is_success = True
    else:
        is_success = False

    if is_success:
        logger.debug("Compilation succeed: %s." % (hexsha))
    else:
        logger.warning("Failed to compile: %s" % (hexsha))

    return is_success

def strip_binary_helper(cur_file_path: str):

    command = "strip " + cur_file_path
    p = subprocess.Popen(command, shell=True)
    _, _ = p.communicate()
    print(f"Stripped {cur_file_path}")
    return

def check_is_binary(cur_file_path: str):
    command = "file " + cur_file_path
    p = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = p.communicate()
    out = out.decode()
    if "ELF" in out:
        return True
    else:
        return False

def strip_all_binary(cur_file_folder: str):
    for root, dirs, files in os.walk(cur_file_folder):
        for cur_file_name in files:
            cur_file_path = root + "/" + cur_file_name
            if check_is_binary(cur_file_path):
                strip_binary_helper(cur_file_path)

def copy_binaries (hexsha: str):


    # Setup the output folder. 
    cur_output_dir = os.path.join(constants.MYSQL_ROOT, hexsha)
    utils.execute_command("mkdir -p %s" % (cur_output_dir), cwd = constants.MYSQL_ROOT)

    if os.path.isfile("/home/mysql/mariadb/bld/sql/mariadbd"):
        target_dir = os.path.join(cur_output_dir, "sql")
        os.mkdir(target_dir)
        shutil.copy2("/home/mysql/mariadb/bld/sql/mariadbd", os.path.join(target_dir, "mariadbd"))
    else:
        logger.error("The mariadbd output file not found. Compilation Failed?")
        return False
    if os.path.isfile("/home/mysql/mariadb/bld/client/mariadb"):
        target_dir = os.path.join(cur_output_dir, "client")
        os.mkdir(target_dir)
        shutil.copy2("/home/mysql/mariadb/bld/client/mariadb", os.path.join(target_dir, "mariadb"))
    else:
        logger.error("The mariadb output file not found. Compilation Failed?")
        return False

    if os.path.isdir("/home/mysql/mariadb/bld/share"):
        target_dir = os.path.join(cur_output_dir, "share")
        shutil.copytree("/home/mysql/mariadb/bld/share", target_dir)
    else:
        logger.warning("The share directory not found. New version? ")

    if os.path.isdir("/home/mysql/mariadb/bld/data_all"):
        target_dir = os.path.join(cur_output_dir, "data_all")
        shutil.copytree("/home/mysql/mariadb/bld/data_all", target_dir)
        if os.path.isdir(os.path.join(target_dir, "data_0")):
            # Delete the tmp tree for space optimization.
            shutil.rmtree(os.path.join(target_dir, "data_0"))
    else:
        logger.error("The data_all not found. Compilation Failed?")
        return False

    strip_all_binary(cur_output_dir)
    return True

def generate_mysql_data_dir():
    cur_dir = os.path.join(constants.MYSQL_SRC, "bld")
    if not os.path.isdir(cur_dir):
        return

    cur_data_dir = os.path.join(cur_dir, "data")
    if os.path.isdir(cur_data_dir):
        shutil.rmtree(cur_data_dir)
    if not os.path.isdir(cur_data_dir):
        os.mkdir(cur_data_dir)

    if os.path.isfile(os.path.join(cur_dir, "scripts/mysql_install_db")):
        # The third scenario, has (bin, extra, scripts, share, support-files)
        command = "chmod +x ./scripts/mysql_install_db && ./scripts/mysql_install_db --user=mysql --datadir=./data"
        utils.execute_command(command, cwd=cur_dir)
        if not os.path.isdir(os.path.join(cur_data_dir, "mysql")):
            return False
    else:
        logger.error("The scripts/mysql_install_db does not initialize the database correctly. Compilation Failed?")
        return False

    cur_data_all_dir = os.path.join(cur_dir, "data_all")
    if os.path.isdir(cur_data_all_dir):
        shutil.rmtree(cur_data_all_dir)
    os.mkdir(cur_data_all_dir)

    shutil.move(cur_data_dir, os.path.join(cur_data_all_dir, "ori_data"))

    return True

def setup_mysql_commit(hexsha: str):
    """Entry function. Pass in the target mysql commit hash, and the function will build the mysql binary from source and then return. """

    # First of all, check whether the pre-compiled binary exists in the destination directory.
    if not os.path.isdir(constants.MYSQL_ROOT):
        os.mkdir(constants.MYSQL_ROOT)

    if os.path.isdir(constants.MYSQL_ROOT):
        cur_output_dir = os.path.join(constants.MYSQL_ROOT, hexsha)
        if os.path.isdir(cur_output_dir):
            cur_output_binary = os.path.join(cur_output_dir, "sql/mariadbd")
            if os.path.isfile(cur_output_binary):
                # The precompiled version existed, skip compilation. 
                logger.debug("MySQL Version: %s existed. Skip compilation. " % (hexsha))
                is_success = True
                return is_success

            # output folder exists, but the bin subfolder is not. Recompile. 
            shutil.rmtree(cur_output_dir)
    else:
        print("FATEL ERROR: cannot find the output dir. ")


    logger.debug("Checkout and clean up MariaDB root dir.")
    # checkout_and_clean_mysql_repo(hexsha)
    clean_mysql_repo()
    utils.execute_command("mkdir -p bld", cwd=constants.MYSQL_SRC)

    logger.debug("Compile MariaDB root dir.")
    is_success = compile_mysql_source(hexsha)

    if not is_success:
        logger.warning("Failed to compile MariaDB with commit %s directly." % (hexsha))
        return False

    # Generate the MySQL data folder. 
    is_success = generate_mysql_data_dir()
    if not is_success:
        logger.warning("Failed to generate data folder with commit %s." % (hexsha))
        return False

    # Copy the necessary files to the output repo. 
    is_success = copy_binaries(hexsha)

    if not is_success:
        logger.warning("Failed to copy binary MySQL with commit %s directly." % (hexsha))
        return False

    return is_success

