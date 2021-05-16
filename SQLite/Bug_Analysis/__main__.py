import sys
import os
import time

print(os.getcwd())
sys.path.append(os.getcwd())

from bi_config import *
from helper import * 
from ORACLE import *


def main():
    
    # IO.gen_unique_bug_output_dir()
    # Fuzzer.setup_and_run_fuzzing()

    oracle = Oracle_TLP()

    repo = Repo(SQLITE_DIR)
    assert not repo.bare

    all_commits_hexsha, all_tags = VerCon.get_all_commits(repo=repo)
    log_out_line("Getting %d number of commits, and %d number of tags. \n\n" % (len(all_commits_hexsha), len(all_tags)))

    log_out_line("Beginning processing files in the target folder. (Infinite Loop) \n\n")
    while True:
        # Read one file at a time. 
        all_new_queries = IO.read_queries_from_files(file_directory=QUERY_SAMPLE_DIR)
        if all_new_queries == []:
            time.sleep(1.0)
            continue
        for all_queries_idx, opt_unopt_queries in enumerate(all_new_queries): 
            if "randomblob" in opt_unopt_queries or "random" in opt_unopt_queries or "julianday" in opt_unopt_queries:
                continue
            Bisect.run_bisecting(opt_unopt_queries = opt_unopt_queries, oracle=oracle)

if __name__ == "__main__":
    main()