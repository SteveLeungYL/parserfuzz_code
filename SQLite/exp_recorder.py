from SQLite.Bug_Analysis.ORACLE import ORACLE
import os
from pathlib import Path
from datetime import datetime
import time
import subprocess

ORACLE_STR = " NOREC "
SQLITE_DIR = "/home/sqlite/sqlite/sqlite/"
SQLITE_MASTER_COMMIT_ID = "3ddc3809bf6148d09ea02345deade44873b9064f"
BEGIN_CORE_ID = 0


SQLITE_FUZZING_BINARY_PATH = os.path.join(
    SQLITE_DIR, "bld/%s/sqlite3" % SQLITE_MASTER_COMMIT_ID
)


"/home/sqlite/sqlite/sqlite/"

def save_loop():
    now = datetime.utcnow().strftime("%m%d-%H%M")
    result_dir = Path('/home/sqlite/sqlite_results') / now
    result_dir.mkdir(parents=True, exist_ok=True)

    for fuzz_root_int in Path.cwd().glob('fuzz_root_*'):
        fuzzer_stats = fuzz_root_int / "fuzz_root_0/fuzzer_stats"
        bug_stats = fuzz_root_int / "fuzz_root_0/fuzzer_stats_correctness"
        bugs_dir = fuzz_root_int / "Bug_Analysis/bug_samples"

        dest_dir = result_dir / fuzz_root_int.name 
        if not dest_dir.exists():
            dest_dir.mkdir()

        command = f"cp {fuzzer_stats} {bug_stats} {dest_dir}"
        os.system(command)
        command = f"cp -r {bugs_dir} {dest_dir}"
        os.system(command)
    return now

def setup_and_run_fuzzing():
    fuzz_root_dir = os.getcwd()
    for i in range(5):
        os.chdir(fuzz_root_dir)
        cur_fuzz_dir = os.path.join(fuzz_root_dir, "./fuzz_root_%d/fuzz_root_0/" % i)
        os.chdir(cur_fuzz_dir)

        fuzzing_command = (
            "AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1  ../afl-fuzz -i ./inputs/ -o ./ -E "
            + " -c "
            + str(BEGIN_CORE_ID + i)
            + " -O "
            + ORACLE_STR
            + " -- "
            + SQLITE_FUZZING_BINARY_PATH
            + " &"
        )
        
        p = subprocess.Popen(
            [fuzzing_command],
            cwd=os.path.join(FUZZING_ROOT_DIR, "fuzz_root_" + str(i)),
            shell=True,
            stderr=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stdin=subprocess.DEVNULL,
        )
    os.chdir(fuzz_root_dir)

setup_and_run_fuzzing()
starttime = time.time()
while True:
    now = save_loop()
    print(f"Save experiment stats files at {now}")
    time.sleep(60.0 - ((time.time() - starttime) % 60.0))

