import sys
import os
import time
from git import Repo

print(os.getcwd())
sys.path.append(os.getcwd())

from bi_config import *
from helper import VerCon, IO, log_out_line, Bisect, Fuzzer
from ORACLE import Oracle_TLP


def main():
    
    IO.gen_unique_bug_output_dir(True)

    Fuzzer.setup_and_run_fuzzing()

    oracle = Oracle_TLP()

    repo = Repo(SQLITE_DIR)
    assert not repo.bare

    vercon = VerCon()
    all_commits_hexsha, all_tags = vercon.get_all_commits(repo=repo)
    log_out_line("Getting %d number of commits, and %d number of tags. \n\n" % (len(all_commits_hexsha), len(all_tags)))

    log_out_line("Beginning processing files in the target folder. (Infinite Loop) \n\n")
    while True:
        # Read one file at a time. 
        all_new_queries = IO.read_queries_from_files(file_directory=QUERY_SAMPLE_DIR)
        if all_new_queries == []:
            time.sleep(1.0)
            continue
        if "randomblob" in all_new_queries[0] or "random" in all_new_queries[0] or "julianday" in all_new_queries[0]:
            continue
        Bisect.run_bisecting(queries_l = all_new_queries, oracle=oracle, vercon=vercon)
        IO.status_print()

if __name__ == "__main__":
    main()