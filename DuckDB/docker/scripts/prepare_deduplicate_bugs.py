import os
import shutil

afltriage_src_dir = "/home/duckdb/AFLTriage"

if not os.path.isdir(afltriage_src_dir):
    os.system(
        f"git clone https://github.com/quic/AFLTriage.git {afltriage_src_dir}"
    )
    os.chdir(afltriage_src_dir)
    os.system("$HOME/.cargo/bin/cargo build")

dest_copy_dir = "/home/duckdb/AFLTriage/target/debug/crash"
if os.path.isdir(dest_copy_dir):
    shutil.rmtree(dest_copy_dir)
os.mkdir(dest_copy_dir)

for i in range(100):
    cur_crash_dir = f"/home/duckdb/fuzzing/fuzz_root/outputs/outputs_{i}/crashes"
    if not os.path.isdir(cur_crash_dir):
        continue
    for cur_file in os.listdir(cur_crash_dir):
        if "README.txt" in cur_file:
            continue
        cur_file_creation_time = os.path.getctime(
            os.path.join(cur_crash_dir, cur_file))
        shutil.copy2(os.path.join(cur_crash_dir, cur_file), os.path.join(
            dest_copy_dir, f"{round(cur_file_creation_time)}_{i}_"+cur_file))
        print(f'Copy from {os.path.join(cur_crash_dir, cur_file)} to {os.path.join(dest_copy_dir, f"{round(cur_file_creation_time)}_{i}_"+cur_file)}\n\n')

print("""
Copy finished. Now executing the following script:

```bash
cd /home/duckdb/AFLTriage/target/debug
./afltriage -i ./crash -o outputs -t 60000 --stdin --debug /home/duckdb/duckdb/build/release/duckdb
```
""")
