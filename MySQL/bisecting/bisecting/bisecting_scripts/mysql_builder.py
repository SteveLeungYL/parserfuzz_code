import constants
import utils
from loguru import logger
import os
import shutil


def checkout_and_clean_mysql_repo(hexsha: str):
    checkout_cmd = f"git checkout {hexsha} --force && git clean -xdf"
    utils.execute_command(checkout_cmd, cwd=constants.MYSQL_SRC)

    logger.debug(f"Checkout commit completed: {hexsha}")

def compile_mysql_source(hexsha: str):
    BLD_PATH = os.path.join(constants.MYSQL_SRC, "bld")
    boost_setup_command = "ln -s /home/mysql/boost_versions /home/mysql/mysql-server/boost"
    utils.execute_command(boost_setup_command, cwd=BLD_PATH)

    run_cmake = "CC=gcc-6 CXX=g++-6 cmake .. -DWITH_BOOST=../boost -DWITH_DEBUG=1"
    utils.execute_command(run_cmake, cwd=BLD_PATH)

    run_make = "make -j$(nproc)"
    utils.execute_command(run_make, cwd=BLD_PATH)

    compiled_program_path = os.path.join(BLD_PATH, "bin/mysqld")
    if os.path.isfile(compiled_program_path):
        is_success = True
    else:
        is_success = False

    if is_success:
        logger.debug("Compilation succeed: %s." % (hexsha))
    else:
        logger.warning("Failed to compile: %s" % (hexsha))

    return is_success

def copy_binaries (hexsha: str):
    # Setup the output folder. 
    cur_output_dir = os.path.join(constants.MYSQL_ROOT, hexsha)
    utils.execute_command("mkdir -p %s" % (cur_output_dir), cwd = constants.MYSQL_ROOT)


    if os.path.isfile("/home/mysql/mysql-server/bld/scripts/mysql_install_db"):
        # This is the old version of the code. Need several more folders to be copied. 
        if os.path.isfile("/home/mysql/mysql-server/bld/bin/mysqld"):
            utils.execute_command("strip /home/mysql/mysql-server/bld/bin/mysqld", cwd=cur_output_dir)
        if os.path.isfile("/home/mysql/mysql-server/bld/bin/mysql"):
            utils.execute_command("strip /home/mysql/mysql-server/bld/bin/mysql", cwd=cur_output_dir)

        if os.path.isdir("/home/mysql/mysql-server/bld/bin"):
            shutil.copytree("/home/mysql/mysql-server/bld/bin", os.path.join(cur_output_dir, "bin"))
        if os.path.isdir("/home/mysql/mysql-server/bld/scripts"):
            shutil.copytree("/home/mysql/mysql-server/bld/scripts", os.path.join(cur_output_dir, "scripts"))
        if os.path.isdir("/home/mysql/mysql-server/bld/extra"):
            shutil.copytree("/home/mysql/mysql-server/bld/extra", os.path.join(cur_output_dir, "extra"))
        if os.path.isdir("/home/mysql/mysql-server/bld/support-files"):
            shutil.copytree("/home/mysql/mysql-server/bld/support-files", os.path.join(cur_output_dir, "support-files"))
        if os.path.isdir("/home/mysql/mysql-server/bld/share"):
            shutil.copytree("/home/mysql/mysql-server/bld/share", os.path.join(cur_output_dir, "share"))

        return True

    elif os.path.isfile("/home/mysql/mysql-server/bld/bin/mysqld"):
        cur_output_bin = os.path.join(cur_output_dir, "bin")
        # utils.execute_command("mkdir -p %s" % (cur_output_bin), cwd = cur_output_dir)

        if os.path.isfile("/home/mysql/mysql-server/bld/bin/mysqld"):
            utils.execute_command("strip /home/mysql/mysql-server/bld/bin/mysqld", cwd=cur_output_dir)
        if os.path.isfile("/home/mysql/mysql-server/bld/bin/mysql"):
            utils.execute_command("strip /home/mysql/mysql-server/bld/bin/mysql", cwd=cur_output_dir)
        if os.path.isdir("/home/mysql/mysql-server/bld/bin"):
            shutil.copytree("/home/mysql/mysql-server/bld/bin", os.path.join(cur_output_dir, "bin"))
        if os.path.isdir("/home/mysql/mysql-server/bld/scripts"):
            shutil.copytree("/home/mysql/mysql-server/bld/scripts", os.path.join(cur_output_dir, "scripts"))
        if os.path.isdir("/home/mysql/mysql-server/bld/library_output_directory"):
            for lib_file in os.listdir("/home/mysql/mysql-server/bld/library_output_directory"):
                if "libprotobuf-lite" in lib_file:
                    shutil.copy(os.path.join("/home/mysql/mysql-server/bld/library_output_directory", lib_file), os.path.join(cur_output_bin, lib_file))

        # Slightly older version, such as MySQL 5.7. Copy a few more folders in advanced. 
        if os.path.isfile("/home/mysql/mysql-server/bld/sql/mysqld"):
            utils.execute_command("strip /home/mysql/mysql-server/bld/sql/mysqld", cwd=cur_output_bin)
        if os.path.isfile("/home/mysql/mysql-server/bld/client/mysql"):
            utils.execute_command("strip /home/mysql/mysql-server/bld/client/mysql", cwd=cur_output_bin)
        if os.path.isdir("/home/mysql/mysql-server/bld/sql"):
            shutil.copytree("/home/mysql/mysql-server/bld/sql", os.path.join(cur_output_bin, "sql"))
        if os.path.isdir("/home/mysql/mysql-server/bld/client"):
            shutil.copytree("/home/mysql/mysql-server/bld/client", os.path.join(cur_output_bin, "client"))

        return True

    else:
        logger.error("The mysqld output file not found. Compilation Failed?")
        return False

def generate_mysql_data_dir():
    cur_dir = os.path.join(constants.MYSQL_SRC, "bld")
    if not os.path.isdir(cur_dir):
        return
    cur_bin_dir = os.path.join(cur_dir, "bin")

    cur_data_dir = os.path.join(cur_dir, "data")
    if os.path.isdir(cur_data_dir):
        shutil.rmtree(cur_data_dir)
    if not os.path.isdir(cur_data_dir):
        os.mkdir(cur_data_dir)

    if os.path.isdir(os.path.join(cur_dir, "share")):
        # The third scenario, has (bin, extra, scripts, share, support-files)
        command = "chmod +x ./scripts/mysql_install_db && ./scripts/mysql_install_db --user=mysql --basedir=./ --datadir=./data"
        utils.execute_command(command, cwd=cur_dir)
        if not os.path.isdir(os.path.join(cur_data_dir, "mysql")):
            return False

    elif os.path.isdir(os.path.join(cur_bin_dir, "client")):
        # The second scenario, has (client, scripts and sql)
        command = "./bin/sql/mysqld --initialize-insecure --user=mysql --datadir=./data"
        utils.execute_command(command, cwd=cur_dir)
        if not os.path.isdir(os.path.join(cur_data_dir, "mysql")):
            return False
    else:
        # The first scenario, all binaries directly in bin dir.
        command = "./bin/mysqld --initialize-insecure --user=mysql --datadir=./data"
        utils.execute_command(command, cwd=cur_dir)
        if not os.path.isdir(os.path.join(cur_data_dir, "mysql")):
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
            cur_output_binary = os.path.join(cur_output_dir, "bin/mysql")
            old_cur_output_binary = os.path.join(cur_output_dir, "bin/client/mysql")
            old_cur_output_binary_2 = os.path.join(cur_output_dir, "bin/bin/mysql")
            if os.path.isfile(cur_output_binary) or os.path.isfile(old_cur_output_binary) or os.path.isfile(old_cur_output_binary_2):
                # The precompiled version existed, skip compilation. 
                logger.debug("MySQL Version: %s existed. Skip compilation. " % (hexsha))
                is_success = True
                return is_success

            # output folder exists, but the bin subfolder is not. Recompile. 
            shutil.rmtree(cur_output_dir)
    else:
        print("FATEL ERROR: cannot find the output dir. ")


    logger.debug("Checkout and clean up MySQL root dir.")
    checkout_and_clean_mysql_repo(hexsha)
    utils.execute_command("mkdir -p bld", cwd=constants.MYSQL_SRC)

    logger.debug("Compile MySQL root dir.")
    is_success = compile_mysql_source(hexsha)

    if not is_success:
        logger.warning("Failed to compile MySQL with commit %s directly." % (hexsha))
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

