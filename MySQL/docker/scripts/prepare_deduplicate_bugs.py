import os
import shutil

db_base_dir = "/home/mysql/mysql-server/bld/data_all/"

for i in range(100):
    cur_target_dir = db_base_dir + f"data_{i}"
    if os.path.isdir(cur_target_dir):
        shutil.rmtree(cur_target_dir)
    shutil.copytree(db_base_dir + "ori_data", cur_target_dir)
print("Finished preparing the database folder.")

dest_copy_dir = "/home/mysql/AFLTriage/target/debug/crash"
if os.path.isdir(dest_copy_dir):
    shutil.rmtree(dest_copy_dir)
os.mkdir(dest_copy_dir)

for i in range (100):
    cur_crash_dir = f"/home/mysql/fuzzing/fuzz_root/outputs/outputs_{i}/crashes"
    if not os.path.isdir(cur_crash_dir):
        continue
    for cur_file in os.listdir(cur_crash_dir):
        if "README.txt" in cur_file:
            continue
        shutil.copy(os.path.join(cur_crash_dir, cur_file), os.path.join(dest_copy_dir, f"{i}_"+cur_file))
        print(f'Copy from {os.path.join(cur_crash_dir, cur_file)} to {os.path.join(dest_copy_dir, f"{i}_"+cur_file)}\n\n')

print("""
Copy finished. Now executing the following script: 

```bash
cd /home/mysql/AFLTriage/target/debug
./afltriage -i ./crash -o outputs -t 60000 --stdin --debug --client_command '/home/mysql/mysql-server/bld/bin/mysql -f --user=root ' /home/mysql/mysql-server/bld/bin/mysqld --basedir=/home/mysql/mysql-server/bld/ --mysqlx=OFF --performance_schema=OFF
```
""")

