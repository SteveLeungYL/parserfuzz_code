import constants
import utils
from loguru import logger
import os
import shutil
import subprocess


def checkout_and_clean_tidb_repo(hexsha: str):
    checkout_cmd = f"git checkout {hexsha} --force && git clean -xdf"
    utils.execute_command(checkout_cmd, cwd=constants.TIDB_SRC)

    logger.debug(f"Checkout commit completed: {hexsha}")

def compile_tidb_source(hexsha: str):
    run_make = "make -j$(nproc)"
    utils.execute_command(run_make, cwd=constants.TIDB_SRC)

    compiled_program_path = os.path.join(constants.TIDB_SRC, "bin/tidb-server")
    if os.path.isfile(compiled_program_path):
        logger.debug("Compilation succeed: %s." % (hexsha))
        return True
    else:
        logger.warning("Failed to compile: %s" % (hexsha))
        return False

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

    src_folder = os.path.join(constants.TIDB_SRC, "bin")
    strip_all_binary(src_folder)

    # Setup the output folder. 
    dest_folder = os.path.join(constants.TIDB_CACHE_ROOT, hexsha)
    utils.execute_command("mkdir -p %s" % dest_folder, cwd = constants.TIDB_CACHE_ROOT)

    if os.path.isfile(os.path.join(src_folder, "tidb-server")):
        # Contain the bin subfolder
        shutil.copytree(src_folder, dest_folder)
        return True

    else:
        logger.error("The TiDB compiled binary file not found. Compilation Failure?")
        return False

def setup_tidb_commit(hexsha: str):
    """Entry function. Pass in the target tidb commit hash, and the function will build the tidb binary from source and then return. """

    # First of all, check whether the pre-compiled binary exists in the destination directory.
    if not os.path.isdir(constants.TIDB_CACHE_ROOT):
        os.mkdir(constants.TIDB_CACHE_ROOT)

    if os.path.isdir(constants.TIDB_CACHE_ROOT):
        cur_output_dir = os.path.join(constants.TIDB_CACHE_ROOT, hexsha)
        if os.path.isdir(cur_output_dir):
            cur_output_binary = os.path.join(cur_output_dir, "bin/tidb-server")
            if os.path.isfile(cur_output_binary):
                # The precompiled version existed, skip compilation. 
                logger.debug("TiDB Version: %s existed. Skip compilation. " % (hexsha))
                is_success = True
                return is_success

            # output folder exists, but the bin subfolder is not. Recompile. 
            shutil.rmtree(cur_output_dir)
    else:
        exit("FATEL ERROR: cannot find the output dir. ")


    logger.debug("Checkout and clean up TiDB root dir.")
    checkout_and_clean_tidb_repo(hexsha)

    logger.debug("Compile TiDB root dir.")
    is_success = compile_tidb_source(hexsha)

    if not is_success:
        logger.warning("Error: Failed to compile TiDB with commit %s." % (hexsha))
        return False

    # Copy the necessary files to the output repo. 
    is_success = copy_binaries(hexsha)

    if not is_success:
        logger.warning("Error: Failed to copy binary TiDB with commit %s directly." % (hexsha))
        return False

    return is_success

