import bisecting
import constants
import file_io 
import utils
from loguru import logger

def setup_logger(debug_level):
    logger.add(
        constants.LOG_OUTPUT_FILE,
        format="{time} {level} {message}",
        level=debug_level,
        rotation="100 MB",
    )

def enter_bisecting_mode():
    """ Main bisecting logic. """

    all_commits = utils.json_load(constants.TIDB_SORTED_COMMITS)
    logger.info(f"Getting {len(all_commits)} number of commits for bisecting.")

    logger.info("Beginning processing files in the target folder.")

    # Loop through yield
    for sample_file, sample_query in file_io.read_queries_from_files():
        logger.info(f"Start bisecting file: {sample_file}")
        bisecting.start_bisect(sample_file, sample_query, all_commits)

def main():

    debug_level = "DEBUG"
    setup_logger(debug_level)

    enter_bisecting_mode()

if __name__ == "__main__":
    main()
