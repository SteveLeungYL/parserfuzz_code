# sqlright: a general platform to test DBMS logical bugs

<a href="Paper/paper.pdf"><img src="Paper/paper.jpg" align="right" width="250"></a>

Version: 1.0\
Update: Jul 28, 2022\
Paper: Detecting Logical Bugs of DBMS with Coverage-based Guidance

Currently supported DBMS:
1. SQLite3
2. PostgreSQL
3. MySQL

<br/><br/>
## Getting Started

### Operating System configuration and Source Code setup

The `SQLRight` fuzzing environment are built inside the Docker hosted environment. We have evaluated the `SQLRight` code inside `Ubuntu 20.04` host system with Docker version `>= 20.10.16`. 

**Warning**: If you are running your `Ubuntu` "host" system inside an Virtual Machine, i.e., VMware Workstation, VMware Fusion, VirtualBox, Parallel Desktop etc, the `Disable On-demand CPU scaling` step in the following script could fail. User can continue running `SQLRIght` even if this specific setup step fails on their machine. But we generally don't recommend to run the `SQLRight` Docker environment inside any Virtual Machines, it could cause some other unexpected errors on the running process. Check [Host system in VM](#host-system-in-vm) for more details. 

```bash
# System Configurations. 
# Open the terminal app from the Ubuntu host system, if you are using a Ubuntu Desktop distribution. 
# Disable On-demand CPU scaling
cd /sys/devices/system/cpu
echo performance | sudo tee cpu*/cpufreq/scaling_governor

# Avoid having crashes being misinterpreted as hangs
sudo sh -c " echo core >/proc/sys/kernel/core_pattern "
```

**WARNING**: Since the operating system will automatically reset some settings upon restarts, we need to reset the system settings using the above scripts **EVERY TIME** after the computer restarted. If the system settings are not being setup correctly, all the fuzzing processes inside Docker will failed. 

We use python3 scripts in the host operating system to generate the bug Figures. Therefore, we should install the `python3` and `python3 dependencies` in the host operating system. 

```bash
# Assuming the host system is `Ubuntu`.
sudo apt-get install -y python3
sudo apt-get install -y python3-pip

# Use `sudo` to run pip3 if necessary. 
pip3 install matplotlib
pip3 install numpy
pip3 install pandas
pip3 install paramiko
pip3 install datetime
```

The whole Artifact Evaluations are built within the `Docker` virtualized environment. If the host system does not have the `Docker` application installed, here is the command to install `Docker` in `Ubuntu`. 

```bash
# The script is grabbed from Docker official documentation: https://docs.docker.com/engine/install/ubuntu/

sudo apt-get remove docker docker-engine docker.io containerd runc

sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
    
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# The next script could fail on some machines. However, the following installation process should still succeed. 
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Receiving a GPG error when running apt-get update?
# Your default umask may not be set correctly, causing the public key file for the repo to not be detected. Run the following command and then try to update your repo again: sudo chmod a+r /etc/apt/keyrings/docker.gpg.

# To test the Docker installation. 
sudo docker run hello-world
# Expected outputs 'Hello from Docker!'
``` 

By default, interacting with `Docker` requires the `root` privilege from the host system. For a normal (non-root) user, calling `docker` requires the `sudo` command prefix. 

### Host system in VM

We generally don't recommend running the this Artifact Evaluation inside a Virtual Machine, e.g., VMware Workstation, VMware Fusion, VirtualBox, Parallel Desktop etc. However, if an VM is the only choice, make sure you check the following:

- Make sure when you call any fuzzing command in the instructions, the `--start-core + --num-concurrent` number won't exceed the total number of CPU cores you assigned to the Virtual Machine. 

- If any of the `SQLRight` processes fail inside the system that is hosted by Virtual Machine, please consider to redo the `SQLRight` runs in a native unvirtualized environment. 

### Troubleshooting

- If the Docker Image building process failed or stuck at some steps for a couple hours, consider to clean the Docker environments. The following command will clean up the Docker cache, and we can rebuild another Docker Images from scratch. 

```bash
sudo docker system prune --all
```

- If any fuzzing processes failed to launch, immediately return errors, or never output any results while running; Or if the `Plotting Scripts` failed to read/write from the `Results` files:
    - Please check whether the `System Configuration` has been setup correctly. Specifically, please repeat the steps of `Disable On-demand CPU scaling` and `Avoid having crashes being misinterpreted as hangs` before retrying the fuzzing scripts. 
    - Please check the `--start-core` and `--num-concurrent` flags you passed into the fuzzing command, and make sure `--start-core + --num-concurrent` won't exceed the total number of CPU cores you have on your machine. (This is a very common mistake that causes evaluation failure. )

<br/><br/>
## 1.  Build the Docker Images

### 1.1  Build the Docker Image for SQLite3 evaluations

Execute the following commands before running any SQLite3 related evaluations. 

The Docker build process can last for about `1` hour. Expect long runtime when executing the commands. 
```bash
cd <sqlright_root>/SQLite/scripts/
bash setup_sqlite.sh
```

After the command finihsed, a Docker Image named `sqlright_sqlite` is created. 

--------------------------------------------------------------------------
### 1.2  Build the Docker Image for PostgreSQL evaluations

Execute the following commands before running any PostgreSQL related evaluations. 

The Docker build process can last for about `1` hour. Expect long runtime when executing the commands. 
```bash
cd <sqlright_root>/PostgreSQL/scripts/
bash setup_postgres.sh
```

After the command finihsed, a Docker Image named `sqlright_postgres` is created. 

--------------------------------------------------------------------------
### 1.3  Build the Docker Images for MySQL evaluations

Execute the following commands before running any MySQL related evaluations. 

The Docker build process can last for about `3` hour. Expect long runtime when executing the commands. The created Docker Image will have around `70GB` of storage space. 

We expect some **Warnings** being returned from the MySQL compilation process. The **Warnings** won't impact the build process. 

```bash
cd <sqlright_root>/MySQL/scripts/
bash setup_mysql.sh
bash setup_mysql_bisecting.sh
```

After the command finished, two Docker Images named `sqlright_mysql` and `sqlright_mysql_bisecting` are created. 

<br/><br/>
## 2. Run SQLRight fuzzing

### 2.1 SQLite NoREC oracle

The following bash scripts will wake the fuzzing script inside `sqlright_sqlite` Docker image, and start the `SQLRight` `SQLite3` fuzzing with `NoREC` oracle. 

```bash
cd <sqlright_root>/SQLite/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based)
bash run_sqlite_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle NOREC
```

Explanation of the command:

- The argument `SQLRight` determines the current running configurations. 

- The `start-core` flag binds the fuzzing process to the specific CPU core. The index starts with `0`. Using `start-core 0` will bind the first fuzzing process to the first CPU core on your machine. Combined with `num-concurrent`, the script will bind each fuzzing process to a unique CPU core, in order to avoid performance penalty introduced by running mutliple processes on one CPU core. For example, flags: `--start-core 0 --num-concurrent 5` will bind `5` fuzzing processes to CPU core `1~5`. Throughout all the evaluation scripts we show in this instruction, we use a default value of `0` for `--start-core`. However, please adjust the CORE-ID based on your testing scenarios, and avoid conflicted CORE-ID already used by other running evaluation processes. 

- The `num-concurrent` flag determines the number of concurrent fuzzing processes. If the testing machine is constrained by CPU cores, memory size or hard drive space, consider using a lower value for this flag. In our paper evaluations, we use the value of `5` across all the configurations. 

- **Attention**: Make sure `start-core + num-concurrent` won't exceed the total CPU core count of your machine. Otherwise, the script will return error and the fuzzing process will failed to launch. 

- The `oracle` flag determines the oracle used for the fuzzing. `SQLRight` currently support: `NOREC` and `TLP`. User can include more oracles in their own implementation. 

Back to the current evaluation. :-)

To stop the Docker container instance, use the following command.
```bash
# Stop the fuzzing process
sudo docker stop sqlright_sqlite_NOREC
# Run bug bisecting
bash run_sqlite_bisecting.sh SQLRight --oracle NOREC
```

And then, use the following command to do bug bisecting: 

```bash
# Run bug bisecting
bash run_sqlite_bisecting.sh SQLRight --oracle NOREC
```

The bisecting script doesn't require `--start-core` and `--num-concurrent` flags. And it will auto exit upon finished. The unique bug reports will be generated in `<sqlright_root>/SQLite3/Results/sqlright_sqlite_NOREC_bugs/bug_samples/unique_bug_output/`.

--------------------------------------------------------------------------
### 2.2 PostgreSQL NoREC

The following bash scripts will wake the fuzzing script inside `sqlright_postgres` Docker image, and start the `SQLRight` `PostgreSQL` fuzzing with `NoREC` oracle. 

```bash
cd <sqlright_root>/PostgreSQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_postgres_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle NOREC
```

To stop the Docker container instance:

```bash
sudo docker stop sqlright_postgres_NOREC
```

Since we did not find any bugs for `PostgreSQL` in our evaluation, we did not include the bug bisecting tool for `PostgreSQL` fuzzing. All the detected bugs from `Postgres` are logged in `<sqlright_root>/PostgreSQL/Results/sqlright_postgres_NOREC_bugs/bug_samples/`

--------------------------------------------------------------------------
### 2.3 MySQL NoREC

The following bash scripts will wake the fuzzing script inside `sqlright_mysql` Docker image, and start the `SQLRight` `MySQL` fuzzing with `NoREC` oracle. 

```bash
cd <sqlright_root>/MySQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_mysql_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle NOREC
```

To stop the Docker container instance, run the following command.

```bash
# Stop the fuzzing process
sudo docker stop sqlright_mysql_NOREC
```

And then run the following bug bisecting command. 

```
# Run bug bisecting
bash run_mysql_bisecting.sh SQLRight --oracle NOREC
```

The bisecting script doesn't require `--start-core` and `--num-concurrent` flags. And it will auto exit upon finished. The unique bug reports will be generated in `<sqlright_root>/MySQL/Results/sqlright_mysql_NOREC_bugs/bug_samples/unique_bug_output`.

---------------------------------------
### 2.4 SQLite TLP

Run the following command. 

The following bash scripts will wake the fuzzing script inside `sqlright_sqlite` Docker image, and start the `SQLRight` `SQLite3` fuzzing with `TLP` oracle. 

Here we are using `TLP` oracle instead of `NOREC` in the previous run instructions.

```bash
cd <sqlright_root>/SQLite/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_sqlite_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle TLP
```

To stop the Docker container instance, run the following command.


```bash
# Stop the fuzzing process
sudo docker stop sqlright_sqlite_TLP
```

Run the bug bisecting command. 

```
# Run bug bisecting
bash run_sqlite_bisecting.sh SQLRight --oracle TLP
```

--------------------------------------------------------------------------
### 2.5 PostgreSQL TLP

Run the following command.

The following bash scripts will wake the fuzzing script inside `sqlright_postgres` Docker image, and start the `SQLRight` `PostgreSQL` fuzzing with `TLP` oracle. 

```bash
cd <sqlright_root>/PostgreSQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_postgres_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle TLP
```

To stop the Docker container instance. 

```bash
sudo docker stop sqlright_postgres_TLP
```

Since we did not find any bugs for PostgreSQL, we skip the bug bisecting process for PostgreSQL fuzzing. 

--------------------------------------------------------------------------
### 2.6 MySQL TLP

Run the following command.

The following bash scripts will wake the fuzzing script inside `sqlright_mysql` Docker image, and start the `SQLRight` `MySQL` fuzzing with `TLP` oracle. 

```bash
cd <sqlright_root>/MySQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_mysql_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle TLP
```

To stop the Docker container instance, run the following command. 

```bash
# Stop the fuzzing process
sudo docker stop sqlright_mysql_TLP
```

And then run the following bug bisecting command. 
```
# Run bug bisecting
bash run_mysql_bisecting.sh SQLRight --oracle TLP
```

The unique bug reports will be generated in `<sqlright_root>/MySQL/Results/sqlright_mysql_TLP_bugs/bug_samples/unique_bug_output`.

<br/><br/>
## 3. SQLRight development

### 3.1 `SQLRight` code structure

The `SQLRight` source code are located in the following location in the repo:

```bash
# SQLite
<sqlright_root>/SQLite/docker/src

# PostgreSQL
<sqlright_root>/PostgreSQL/docker/src

# MySQL
<sqlright_root>/MySQL/docker/src
```

The `SQLRight` code for all three DBMSs share a similar code structure. 

- `AFL` folder contains the main entry of the `SQLRight` program. The `main` function of `SQLRight` is located in the file `AFL/afl-fuzz.cpp`.
- `include` folder for header files. 
- `oracle` folder contains all the `DBMS oracle` implementation code. All `oracle` related code, including the source and header files are all located here. 
- `parser` folder contains the per-DBMS Bison parser file. These translated parsers come from the original parsers from DBMSs, they now translate the SQL strings to `SQLRight Intermediate Representation` instead of `DBMS internal Representations`. 
- `src` folder contains all the helper tools for `SQLRight`, including: 
    - `ast.cpp`: The `SQLRight IR` definition. 
    - `ir_wrapper.cpp`: The helper functions for handling the `SQLRight IR`. Heavily used by the `general oracle interface`.
    - `mutator.cpp`: The fuzzing mutator logic for `SQLRight`.
    - `utils.cpp`: Some more general helper functions, such as string handling functions etc. 

### `SQLRight` new oracle development

To develop a new DBMS oracle for `SQLRight`, all we need to do is to implement a new C++ inherited class in the `oracle` folder. The base class is implemented in the `<dbms_name>_oracle.h` and `<dbms_name_oracle.cpp>` files, we can inherit the pre-defined base class APIs to implement our new oracles. 

We can use `SQLite` `LIKELY` oracle as example, to demonstrate how to implement a new oracle from `SQLRight`. 

The `LIKELY` oracle adds additional `LIKELY` or `UNLIKELY` optimization hints, to the `SQLite3` output `SELECT` statements. The `LIKELY/UNLIKELY` optimization from `SQLite3` should not change the results of the `SELECT`. By using this intuition and comparing the `SELECT` results with/without `LIKELY/UNLIKLY` hints, we can find potentially `LIKELY` related optimization bugs in the `SQLite3` DBMS. 

#### New Oracle Development Step 1: create oracle class files

Create the `sqlite_likely.h` and `sqlite_likely.cpp` files in the `<sqlright_root>/SQLite/docker/src/oracle` folder. 

Include the `sqlite_oracle.h` header file, and declare the new `SQLITE_LIKELY` class, inherited from the `SQLITE_ORACLE` class. 

#### New Oracle Development Step 2: implement the required class functions

A more detailed per class function explanations are included in the `sqlite_oracle.h` source code comments. Here, we only mentioned the APIs we used to implement `LIKELY` oracle. 

- **preprocess** APIs: We do not require to implement any custom logic for `LIKELY` oracle query preprocessing. However, for other oracle such as `INDEX` (add/remove `INDEX` from the query), we can use `IR* get_random_append_stmts_ir();` to insert `CREATE INDEX` statement to the query set. 

- **attach_output** APIs: In this step, we add in the oracle related `SELECT` statements to the query sets. `SQLRight` will save all the `SELECT` statements from the input seeds, mutate them to a different form, and pass the mutated `SELECT` statements to `bool get_random_append_stmts_ir();` function. Developer can use this function to determine whether the current form of `SELECT` statement is supported by the oracle, and use this function to return the boolean results. If return false, the mutated `select` will be discarded. If return true, the current mutated `select` will passed to the next step for query transformation. For `LIKELY` oracle, this API check whether the `FROM` clause and the `WHERE` clause existed in the `SELECT` query. 

- **transform** APIs: The `transform` APIs contains two main functions: `vector<IR*> pre_fix_transform_select_stmt` and `vector<IR*> pro_fix_transform_select_stmt`. These APIs pass in the original form of the oracle compatible `SELECT` statements (from **attach_output** step), and return multiple functional equivalent forms of `SELECTs`. The `pre_fix_*` API happens before the `IR Instantiazation` process, where all the query operands (table names, column names, numerical values etc) are not filled in yet. And thus, the equivalent forms of `SELECTs` will later be filled in different operands. The `post_fix_*` API happens after the `IR Instantiazation` process, where the query operands are determined and already filled in to the passed in IRs. This API is suitable for functional equivalent queries that requires the exact same operands. The `LIKELY` oracle use the `post_fix_*` function, which adds in `LIKELY` and `UNLIKELY` functions to the `SELECT WHERE clause`, forming three functionally equivalent forms query respectively (including the original form). 

- **compare** API: Allow the developer to define their own rules to check the `SELECT` statements' results for potential logical bugs. The related function is `compare_results`. If the query results are expected, returns `ORA_COMP_RES::Pass`; if the query results are potentially buggy, returns `ORA_COMP_RES::Fail`; if the query results are plained errors, returns `ORA_COMP_RES::Error`. `SQLRight` will automatically generate bug report for every result that has been marked as `ORA_COMP_RES:Fail`. 

Some additional tools can be used while calling the oracle APIs: The `test-parser` program (src: `AFL/test-parser.cpp`, to build: `make test-parser`) can print the IR structure for the SQL query string. It can be used to visual and debug the SQL query statements modified by the oracle interface. 

#### New Oracle Development Step 3: expose the newly implemented oracle

Include the newly created `sqlite_<new-oracle>.h` header file to the `AFL/afl-fuzz.cpp` source. 

In the `main` function parameter handling process, add in the new oracle as available parameter. For `LIKELY` oracle, the following lines are added. 

```diff
@@ -7660,8 +7660,6 @@ int main(int argc, char **argv) {
...
      case 'O': /* Oracle */
      {
        /* Default NOREC */
        string arg = string(optarg);
        if (arg == "NOREC")
         p_oracle = new SQL_NOREC();
       else if (arg == "TLP")
         p_oracle = new SQL_TLP();
+      else if (arg == "LIKELY")
+        p_oracle = new SQL_LIKELY();
       else if (arg == "ROWID")
         p_oracle = new SQL_ROWID();
       else if (arg == "INDEX")
...
```

The implementation of `LIKELY` oracle is finished in `SQLRight`. 

#### New Oracle Development Step 4: (optional) also implement the oracle in the bisecting code. 

The `bisecting` code is located in the following locations:

```bash
# SQLite bisecting python script
<sqlright_root>/SQLite/docker/bisecting

# MySQL bisecting python script
<sqlright_root>/MySQL/bisecting/bisecting/bisecting_scripts
```

Similar to the `SQLRight` source code, all the oracle related code are located in the `ORACLE` subfolders. Take `SQLite` `LIKELY` oracle again oracle for example, the `ORACLE_LIKELY.py` file is required to implement the following two functions:

- `def retrive_all_results()`: The function retrieves all the results from the `SELECT` statements. Since `SQLRight` will put all oracle related results within the `BEGIN VERI *` lines, this function retrieve all results between those lines. (We can copy and paste this function to new oracle implementation, if we didn't change the `SQLRight` logic for outputting results. )

- `def comp_query_res()`: Port the results comparison methods from the `SQLRight` `compare` API to a python version, and place it here. 

And at last, import the newly defined oracle python file to the `__main__.py` file, and expose the oracle parameter to the CLI. 

```diff
--- a/SQLite/docker/bisecting/__main__.py
+++ b/SQLite/docker/bisecting/__main__.py
@@ -42,6 +42,8 @@ def main():
...
     oracle = 0
     if oracle_str == "NOREC":
         oracle = Oracle_NOREC
     elif oracle_str == "TLP":
         oracle = Oracle_TLP
+    elif oracle_str == "LIKELY":
+        oracle = Oracle_LIKELY
     else:
         oracle = Oracle_NoREC
...
```

#### New Oracle Development Step 5: Run the newly implemented oracle

Because we have modified the `SQLRight` and bisecting source code, we need to rebuild the docker testing environment to reflect on the changes. Therefore, we need to repeat the steps on `Section 1: Build the Docker Images`. 

And then, run the fuzzing process with the new oracle:

```bash
# For SQLite3
cd <sqlright_root>/SQLite/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based)
# bash run_sqlite_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle <new-oracle>
bash run_sqlite_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle LIKELY


# For PostgreSQL
cd <sqlright_root>/PostgreSQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_postgres_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle <new-oracle>

# For MySQL
cd <sqlright_root>/MySQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_mysql_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle <new-oracle>
```

For bisecting:
```bash
# For SQLite3
cd <sqlright_root>/SQLite/scripts
# bash run_sqlite_bisecting.sh SQLRight --oracle <new-oracle>
bash run_sqlite_bisecting.sh SQLRight --oracle LIKELY

# For MySQL
cd <sqlright_root>/MySQL/scripts
bash run_mysql_bisecting.sh SQLRight --oracle <new-oracle>
```

#### End of New Oracle Development Steps
