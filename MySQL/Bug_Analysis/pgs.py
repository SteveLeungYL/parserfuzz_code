from pathlib import Path

import constants
import utils
from loguru import logger

def clone_postgresql_source():
    repo_url = "https://github.com/mysql/mysql-server"

    if not constants.MYSQL_SOURCE.exists():
        constants.MYSQL_SOURCE.mkdir(parents=True)

    if not constants.MYSQL_SOURCE_BACKUP.exists():
        clone_cmd = f"git clone {repo_url} {constants.MYSQL_SOURCE_BACKUP}"
        utils.execute_command(clone_cmd)
        utils.copy_directory(
            constants.MYSQL_SOURCE_BACKUP, constants.MYSQL_CHECKOUT_ROOT
        )
        constants.MYSQL_BUILD_ROOT.mkdir()

def prepare_postgresql_data(install_directory: Path):
    data = install_directory / "data"
    if data.exists():
        return True

    def restore_backup_if_exists():
        # use exists data backup.
        return_immediately = False
        backup = data.with_suffix(".bak")
        if backup.exists():
            rsync_cmd = "rsync -avz -q -hH --delete " f"{backup}/ {data}"
            utils.execute_command(rsync_cmd)
            return_immediately = True
        else:
            # clean the exist data folder.
            utils.remove_directory(data)

        logger.debug(f"Use the exist PostgreSQL data: {return_immediately}")
        return return_immediately

    def initialize_postgresql_data():
        initdb = install_directory / "bin/initdb"
        init_cmd = f"{initdb.absolute()} -D {data.absolute()}"
        utils.execute_command(init_cmd)

        return_immediately = not data.exists()
        logger.debug(f"Initialized the PostgreSQL data directory: {return_immediately}")
        return return_immediately

    def create_postgresql_database():
        backup = data.with_suffix(".bak")
        postgres_binary = install_directory / "bin/postgres"
        echo_cmd = 'echo "create database x" '
        pgs_cmd = "{postgres} --single -D {data} template0".format(
            postgres=postgres_binary.absolute(), data=data.absolute()
        )

        create_cmd = f"{echo_cmd} | {pgs_cmd}"
        utils.execute_command(create_cmd)
        utils.copy_directory(data, backup)

    if restore_backup_if_exists():
        return True

    if initialize_postgresql_data():
        return False

    create_postgresql_database()
    return data.exists()


def force_copy_data_backup(install_directory: Path):
    data = install_directory / "data"
    backup = data.with_suffix(".bak")
    utils.remove_directory(data)
    utils.copy_directory(backup, data)


def compile_mysql_source(install_directory: Path):
    run_cmake = "cmake -DDOWNLOAD_BOOST=1 -DWITH_BOOST={boost} {src}".format(
        boost=constants.MYSQL_BOOST_SOURCE, src=constants.MYSQL_CHECKOUT_ROOT
    )
    utils.execute_command(run_cmake, cwd=install_directory)

    run_make = f"make -j{constants.COMPILE_THREAD_COUNT}"
    utils.execute_command(run_make, cwd=install_directory)

    compiled_program = install_directory / "bin/mysqld"
    is_success = compiled_program.exists()

    hexsha = install_directory.name

    if is_success:
        logger.debug(f"Compilation successful: {install_directory}")
        utils.remove_failed_commit(hexsha)
    else:
        logger.warning(f"Failed to compile: {install_directory}")
        utils.dump_failed_commit(hexsha)

    return is_success


def checkout_mysql_commit(hexsha: str):
    # rsync_cmd = "rsync -avz -q -hH --delete {src}/ {dest}".format(
    #     src=constants.MYSQL_SOURCE_BACKUP.absolute(),
    #     dest=constants.MYSQL_CHECKOUT_ROOT.absolute(),
    # )
    # utils.execute_command(rsync_cmd)

    checkout_cmd = f"git checkout {hexsha} --force"
    utils.execute_command(checkout_cmd, cwd=constants.MYSQL_CHECKOUT_ROOT)

    logger.debug(f"Checkout commit completed: {hexsha}")


def setup_mysql_commit(hexsha: str):
    """
    Given the MySQL commit ID, check out the commit and compile the MySQL source code.
    If succeed, return the MySQL binary directory (not included the binary name) str;
    if failed, return empty str.
    """

    install_directory = constants.MYSQL_BUILD_ROOT / hexsha

    def is_commit_already_compiled(hexsha): 
        postgres_binary = install_directory / "bin/mysqld"
        return postgres_binary.exists()

    def is_commit_already_failed(hexsha):
        commits = utils.json_load(constants.FAILED_COMPILE_COMMITS)
        return hexsha in commits

    if is_commit_already_failed(hexsha):
        logger.debug(
            f"MySQL with commit {hexsha} already failed to compile, skip it."
        )
        return None
    elif is_commit_already_compiled(hexsha):
        logger.debug(f"MySQL with commit {hexsha} already compiled, skip it.")
        return install_directory

    utils.remove_directory(install_directory)
    install_directory.mkdir(parents=True)

    checkout_mysql_commit(hexsha)
    is_success = compile_mysql_source(install_directory)
    if is_success:
        logger.debug(f"Successful to compile MySQL with commit {hexsha} directly.")
        return install_directory

    compile_mysql_source(install_directory)

    if is_commit_already_compiled(hexsha):
        logger.debug(
            f"Successful to compile PostgreSQL with commit {hexsha}."
        )
        return install_directory
    else:
        logger.debug(
            f"Failed to compile PostgreSQL with commit {hexsha}."
        )
        return None


def execute_queries(queries: str, install_directory: Path):

    prepare_success = prepare_postgresql_data(install_directory)
    if not prepare_success:
        return None, constants.RESULT.SEG_FAULT

    clean_database_query = (
        "RESET PERSIST", 
        "RESET MASTER", 
        "DROP DATABASE IF NOT EXISTS test_sqlright1",
        "CREATE DATABASE IF NOT EXISTS test_sqlright1", 
        "USE test_sqlright1", 
    )
    logger.debug(clean_database_query)
    logger.debug(queries)
    safe_queries = clean_database_query + "\n" + queries

    mysql_client = "./bin/mysql -u root --socket=/tmp/mysql_0.sock"
    output, status, error_msg = utils.execute_command(
        mysql_client, input_contents=safe_queries, cwd=install_directory
    )

    logger.debug(f"Query:\n\n{queries}")
    logger.debug(f"Result: \n\n{output}\n")
    logger.debug(f"Directory: {install_directory}")
    logger.debug(f"Return Code: {status}")

    if not output:
        return None, constants.RESULT.ALL_ERROR

    if status not in (0, 1):
        # 1 is the default return code if we terminate the Postgre.
        return None, constants.RESULT.SEG_FAULT

    return parse_mysql_result(output)


def parse_mysql_result(postgres_output: str):
    def is_output_missing():
        return any(
            [
                postgres_output == "",
                postgres_output.count("BEGIN VERI") < 1,
                postgres_output.count("END VERI") < 1,
                # utils.is_string_only_whitespace(postgres_output)
            ]
        )

    if is_output_missing():
        # Missing the outputs from the opt or the unopt.
        # Returning None implying errors.
        return None, constants.RESULT.ALL_ERROR

    output_lines = postgres_output.splitlines()

    def parse_output_lines(opt: bool):
        i = int(not opt)
        begin_indexes = [
            idx for idx, line in enumerate(output_lines) if f"BEGIN VERI {i}" in line
        ]
        end_indexes = [
            idx for idx, line in enumerate(output_lines) if f"END VERI {i}" in line
        ]

        if len(begin_indexes) != len(end_indexes):
            logger.warning(
                f"the number of 'BEGIN VERI {i}' is not "
                f"equal to the number of 'END VERI {i}'."
            )

        result = []
        for begin_idx, end_idx in zip(begin_indexes, end_indexes):
            current_lines_int = [-1]

            current_lines = output_lines[begin_idx + 1 : end_idx]
            current_lines = map(lambda l: l.strip(), current_lines)
            current_lines = list(filter(lambda l: ' = "' in l, current_lines))

            if current_lines:
                current_lines = map(lambda l: l[l.find("=", 1) + 1 :], current_lines)
                current_lines = map(lambda l: l[: l.find("(")], current_lines)
                current_lines = map(lambda l: l.strip(), current_lines)
                current_lines = map(lambda l: l.strip('"'), current_lines)

                try:
                    if opt:
                        current_lines_int = list(map(lambda n: int(n), current_lines))
                    else:
                        current_lines_int = list(
                            map(lambda n: int(float(n) + 0.0001), current_lines)
                        )
                except ValueError:
                    pass

            result.append(current_lines_int)

        return result

    opt_results = parse_output_lines(opt=True)
    unopt_results = parse_output_lines(opt=False)
    logger.debug(f"opt_results: {opt_results}")
    logger.debug(f"unopt_results: {unopt_results}")
    all_result_pairs = [[opt, unopt] for opt, unopt in zip(opt_results, unopt_results)]

    return all_result_pairs, constants.RESULT.PASS
