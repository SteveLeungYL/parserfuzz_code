# sqlright: a general platform to test DBMS logical bugs

<a href="Paper/paper_no_names.pdf"><img src="Paper/paper_no_names.png" align="right" width="250"></a>

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
### 3.2 PostgreSQL NoREC

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
### 3.3 MySQL NoREC

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

#### 3.3.2 Squirrel-Oracle

<sub>`367` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 72 hours.

```bash
cd <sqlright_root>/MySQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_mysql_fuzzing.sh squirrel-oracle --start-core 0 --num-concurrent 5 --oracle NOREC
```

After `72` hours, stop the Docker container instance, and then run the following bug bisecting command. 

```bash
# Stop the fuzzing process
sudo docker stop squirrel_oracle_NOREC
# Run bug bisecting
bash run_mysql_bisecting.sh squirrel-oracle --oracle NOREC
```

The bug bisecting process is expected to finish in `7` hours. 

#### 3.3.3 Figures 

The following scripts will generate *Figure 5b, d, g, j* in the paper. 

```bash
# If you use the `root` user to execute the docker command. It is possible that you need to change the privilege access for the Results output folder. 
cd <sqlright_root>/MySQL/Results
sudo chown -R <your_user_name> ./*

# Plot the figures
cd <sqlright_root>/Plot_Scripts/MySQL/NoREC/Comp_diff_tools
python3 copy_results.py
python3 run_plots.py
```

The figures will be generated in folder `<sqlright_root>/Plot_Scripts/MySQL/NoREC/Comp_diff_tools/plots`. 

**Expectations**:

- For MySQL logical bugs figure: The current bisecting and bug filtering scripts could slightly over-estimate the number of unique bugs for MySQL. Some manual efforts might be needed to scan through the bug reports and deduplicate the bugs. But in general, `SQLRight` should detect the most bugs (`>= 2` bugs in 72 hours).  
- For MySQL code coverage figure: `SQLRight` should have the highest code coverage among the other baselines. 
- For MySQL query validity: `SQLRight` has higher validity than `Squirrel-oracle`. 
- For MySQL valid stmts / hr: `SQLRight` has more valid_stmts / hr than `Squirrel-oracle`.

---------------------------------------
### 3.4 SQLite TLP

#### 3.4.1 SQLRight   

<sub>`361` CPU hours</sub>

Run the following command. 

The bash command will invoke the fuzzing script inside Docker. Let the fuzzing processes run for `72` hours. 

**Attention**: Be careful with the `--oracle` flag. Here we are using `TLP` instead of `NOREC` in the previous evaluations.

```bash
cd <sqlright_root>/SQLite/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_sqlite_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle TLP
```

After `72` hours, stop the Docker container instance, and then run the following bug bisecting command. 

**Attention**: Be careful with the `--oracle` flag. Here we are using `TLP` instead of `NOREC` in the previous evaluations. 

```bash
# Stop the fuzzing process
sudo docker stop sqlright_sqlite_TLP
# Run bug bisecting
bash run_sqlite_bisecting.sh SQLRight --oracle TLP
```

The bug bisecting process is expected to finish in `1` hour. 

#### 3.4.2 Squirrel-Oracle 

<sub>`361` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 72 hours.

**WARNING**: The `Squirrel-Oracle` process consumes a large amount of memory. In our evaluation, we observed a maximum of `100GB` of memory usage PER `Squirrel-Oracle` process after running for 72 hours. With 5 concurrent processes, the evalution could use in total of `600GB` of memory within 72 hours. If not enough memory is available, consider using a smaller number of `--num-concurrent`.  

**Attention**: Be careful with the `--oracle` flag. Here we are using `TLP` instead of `NOREC` in the previous evaluation. 

```bash
cd <sqlright_root>/SQLite/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_sqlite_fuzzing.sh squirrel-oracle --start-core 0 --num-concurrent 5 --oracle TLP
```

After `72` hours, stop the Docker container instance, and then run the following bug bisecting command. 

```bash
# Stop the fuzzing process
sudo docker stop squirrel_oracle_TLP
# Run bug bisecting
bash run_sqlite_bisecting.sh squirrel-oracle --oracle TLP
```

The bug bisecting process is expected to finish in `1` hour. 

#### 3.4.3 SQLancer 

<sub>`360` CPU hours</sub>

Run the following command. Let the `SQLancer` processes run for 72 hours. 

**WARNING**: The SQLancer process will generate a large amount of `cache` data, and it will save the cache to the file system. We expected around `50GB` of cache being generated from EACH SQLancer instances. Following the command below, we will call 5 instances of SQLancer, which will dump `250GB` of cache data. If not enough storage space is available, consider using a smaller number of `--num-concurrent`. 

**Attention**: Be careful with the `--oracle` flag. Here we are using `TLP` instead of `NOREC` in the previous evaluation. 

**Attention**: Expect some error messages: `unable to setup input stream: unable to set IO streams as raw terminal: input/output error`. It won't impact the evaluation process. 

```bash
cd <sqlright_root>/SQLite/scripts
# Call 5 instances of SQLancer. 
bash run_sqlite_fuzzing.sh sqlancer --num-concurrent 5 --oracle TLP
```

After `72` hours, stop the Docker container instance. 

```bash
sudo docker ps --filter name=sqlancer_sqlite_TLP_raw_* --filter status=running -aq | xargs sudo docker stop
```

#### 3.4.4 Figures

The following scripts will generate *Figure 8a, c, f, i* in the paper. 

```bash
# If you use the `root` user to execute the docker command. It is possible that you need to change the privilege access for the Results output folder. 
cd <sqlright_root>/SQLite/Results
sudo chown -R <your_user_name> ./*

# Plot the figures
cd <sqlright_root>/Plot_Scripts/SQLite3/TLP/Comp_diff_tools
python3 copy_results.py
python3 run_plots.py
```

The figures will be generated in folder `<sqlright_root>/Plot_Scripts/SQLite3/TLP/Comp_diff_tools/plots`.

**Expectations**:

- For SQLite logical bugs figure: `SQLRight` should detect the most bugs. On different evaluation around, we expect `>= 1` bugs being detected by `SQLRight` in `72` hours. 
- For SQLite code coverage figure: `SQLRight` should have the highest code coverage among the other baselines. 
- For SQLite query validity: `SQLancer` have the highest query validity, while `SQLRight` performs better than `Squirrel-oracle`. 
- For SQLite valid stmts / hr: `SQLancer` have the highest valid stmts / hr, while `SQLRight` performs better than `Squirrel-oracle`.


--------------------------------------------------------------------------
### 3.5 PostgreSQL TLP

#### 3.5.1 SQLRight

<sub>`360` CPU hours</sub>

Run the following command. Let the fuzzing processes run for `72` hours.

**Attention**: Be careful with the `--oracle` flag. Here we are using `TLP` instead of `NOREC` in the previous evaluations. 

```bash
cd <sqlright_root>/PostgreSQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_postgres_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle TLP
```

After `72` hours, stop the Docker container instance. 

```bash
sudo docker stop sqlright_postgres_TLP
```

Since we did not find any bugs for PostgreSQL, we skip the bug bisecting process for PostgreSQL fuzzings. 

#### 3.5.2 Squirrel-Oracle

<sub>`360` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 72 hours.

**Attention**: Be careful with the `--oracle` flag. Here we are using `TLP` instead of `NOREC` in the previous evaluations. 

```bash
cd <sqlright_root>/PostgreSQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_postgres_fuzzing.sh squirrel-oracle --start-core 0 --num-concurrent 5 --oracle TLP
```

After `72` hours, stop the Docker container instance. 

```bash
sudo docker stop squirrel_oracle_TLP
```

#### 3.5.3 SQLancer

<sub>`360` CPU hours</sub>

Run the following command. Let the `SQLancer` processes run for 72 hours. 

**Attention**: Be careful with the `--oracle` flag. Here we are using `TLP` instead of `NOREC` in the previous evaluations. 

**WARNING**: The SQLancer process will generate a large amount of `cache` data, and it will save the cache to the file system. We expected around `50GB` of cache being generated from EACH SQLancer instances. Following the command below, we will call 5 instances of SQLancer, which will dump `250GB` of cache data. If not enough storage space is available, consider using a smaller number of `--num-concurrent`. 

**Attention**: Expect some error messages: `unable to setup input stream: unable to set IO streams as raw terminal: input/output error`. It won't impact the evaluation process. 

```bash
cd <sqlright_root>/PostgreSQL/scripts
bash run_postgres_fuzzing.sh sqlancer --num-concurrent 5 --oracle TLP
```

After `72` hours, stop the Docker container instance. 

```bash
sudo docker ps --filter name=sqlancer_postgres_TLP_raw_* --filter status=running -aq | xargs sudo docker stop
```

#### 3.5.4 Figures 

The following scripts will generate *Figure 8e, h, k* in the paper. 

```bash
# If you use the `root` user to execute the docker command. It is possible that you need to change the privilege access for the Results output folder. 
cd <sqlright_root>/PostgreSQL/Results
sudo chown -R <your_user_name> ./*

# Plot the figures
cd <sqlright_root>/Plot_Scripts/Postgres/TLP/Comp_diff_tools_TLP
python3 copy_results.py
python3 run_plots.py
```

The figures will be generated in folder `<sqlright_root>/Plot_Scripts/Postgres/TLP/Comp_diff_tools_TLP/plots`. 

**Expectations**:

- For PostgreSQL code coverage figure: `SQLRight` should have the highest code coverage among the other baselines. 
- For PostgreSQL query validity: `SQLancer` have the highest query validity, while `SQLRight` performs better than `Squirrel-oracle`. 
- For PostgreSQL valid stmts / hr: `SQLancer` have the highest valid stmts / hr, while `SQLRight` performs better than `Squirrel-oracle`.

--------------------------------------------------------------------------
### 3.6 MySQL TLP

#### 3.6.1 SQLRight

<sub>`367` CPU hours</sub>

Run the following command. Let the `SQLancer` processes run for 72 hours. 

**Attention**: Be careful with the `--oracle` flag. Here we are using `TLP` instead of `NOREC` in the previous evaluations. 

```bash
cd <sqlright_root>/MySQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_mysql_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle TLP
```

After `72` hours, stop the Docker container instance. And then run the following bug bisecting command. 

```bash
# Stop the fuzzing process
sudo docker stop sqlright_mysql_TLP
# Run bug bisecting
bash run_mysql_bisecting.sh SQLRight --oracle TLP
```

The bug bisecting process is expected to finish in `7` hours. 

#### 3.6.2 Squirrel-Oracle

<sub>`367` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 72 hours.

**Attention**: Be careful with the `--oracle` flag. Here we are using `TLP` instead of `NOREC` in the previous evaluations. 

```bash
cd <sqlright_root>/MySQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_mysql_fuzzing.sh squirrel-oracle --start-core 0 --num-concurrent 5 --oracle TLP
```

After `72` hours, stop the Docker container instance, and then run the following bug bisecting command. 

```bash
# Stop the fuzzing process
sudo docker stop squirrel_oracle_TLP
# Run bug bisecting
bash run_mysql_bisecting.sh squirrel-oracle --oracle TLP
```

The bug bisecting process is expected to finish in `7` hours. 

#### 3.6.3 SQLancer

<sub>`360` CPU hours</sub>

Run the following command. Let the SQLancer processes run for 72 hours.

**Attention**: Be careful with the `--oracle` flag. Here we are using `TLP` instead of `NOREC` in the previous evaluations. 

**WARNING**: The SQLancer process will generate a large amount of cache data, and it will save the cache to the file system. We expected around `20GB` of cache being generated from EACH SQLancer instances. Following the command below, we will call `5` instances of SQLancer, which will dump `100GB` of cache data. If not enough storage space is available, consider using a smaller number of `--num-concurrent`.

**Attention**: Expect some error messages: `unable to setup input stream: unable to set IO streams as raw terminal: input/output error`. It won't impact the evaluation process. 

```bash
cd <sqlright_root>/MySQL/scripts
bash run_mysql_fuzzing.sh sqlancer  --num-concurrent 5 --oracle TLP
```

After `72` hours, stop the Docker container instance. 

```bash
sudo docker ps --filter name=sqlancer_mysql_TLP_raw_* --filter status=running -aq | xargs sudo docker stop
```

#### 3.6.4 Figures

The following scripts will generate *Figure 8b, d, g, j* in the paper. 

```bash
# If you use the `root` user to execute the docker command. It is possible that you need to change the privilege access for the Results output folder. 
cd <sqlright_root>/MySQL/Results
sudo chown -R <your_user_name> ./*

# Plot the figures
cd <sqlright_root>/Plot_Scripts/MySQL/TLP/Comp_diff_tools
python3 copy_results.py
python3 run_plots.py
```

The figures will be generated in folder `<sqlright_root>/Plot_Scripts/MySQL/TLP/Comp_diff_tools/plots`. 

**Expectations**:

- For MySQL logical bugs figure: The current bisecting and bug filtering scripts could slightly over-estimate the number of unique bugs for MySQL. Some manual efforts might be needed to scan through the bug reports and deduplicate the bugs. But in general, `SQLRight` should detect the most bugs (`>= 1` bugs in 72 hours).  
- For MySQL code coverage figure: `SQLRight` should have the highest code coverage among the other baselines. 
- For MySQL query validity: `SQLRight` has a higher validity than `Squirrel-oracle`. 
- For MySQL valid stmts / hr: `SQLRight` has more valid_stmts / hr than `Squirrel-oracle`.

<br/><br/>
## 4. Contribution of Code-Coverage Feedback

### 4.1 NoREC

#### 4.1.1 SQLRight

Make sure you have finished *Session 3.1.1* in this Artifact Evaluation. 

#### 4.1.2 SQLRight Drop All

<sub>`121` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 24 hours.

```bash
cd <sqlright_root>/SQLite/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_sqlite_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle NOREC --feedback drop_all 
```

After `24` hours, stop the Docker container instance, and then run the following bug bisecting command. 

```bash
# Stop the fuzzing process
sudo docker stop sqlright_sqlite_drop_all_NOREC
# Run bug bisecting
cd <sqlright_root>/SQLite/scripts
bash run_sqlite_bisecting.sh SQLRight --oracle NOREC --feedback drop_all 
```

The bug bisecting process is expected to finish in `1` hours. 

#### 4.1.3 SQLRight Random Save

<sub>`121` CPU hours</sub>

**WARNING**: Due to the aggresive query seed handling strategy, the `SQLRight` Random Save config will generate a large amount of `cache` data, and it will save the cache to the file system. We expected around `15GB` of cache being generated from EACH SQLRight instance. Following the command below, we will call 5 instances of SQLancer, which will dump `75GB` of cache data. If not enough storage space is available, consider using a smaller number of `--num-concurrent`. 

```bash
cd <sqlright_root>/SQLite/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_sqlite_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle NOREC --feedback random_save
```

After `24` hours, stop the Docker container instance, and then run the following bug bisecting command. 

```bash
# Stop the fuzzing process
sudo docker stop sqlright_sqlite_random_save_NOREC
# Run bug bisecting
cd <sqlright_root>/SQLite/scripts
bash run_sqlite_bisecting.sh SQLRight --oracle NOREC --feedback random_save
```

The bug bisecting process is expected to finish in `1` hours. 

#### 4.1.4 SQLRight Save All

<sub>`121` CPU hours</sub>

**WARNING**: Due to the aggresive query seed handling strategy, the `SQLRight` Random Save config will generate a large amount of `cache` data, and it will save the cache to the file system. We expected around `20GB` of cache being generated from EACH SQLRight instance. Following the command below, we will call 5 instances of SQLancer, which will dump `100GB` of cache data. If not enough storage space is available, consider using a smaller number of `--num-concurrent`. 

```bash
cd <sqlright_root>/SQLite/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_sqlite_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle NOREC --feedback save_all
```

After `24` hours, stop the Docker container instance, and then run the following bug bisecting command. 

```bash
# Stop the fuzzing process
sudo docker stop sqlright_sqlite_save_all_NOREC
# Run bug bisecting
cd <sqlright_root>/SQLite/scripts
bash run_sqlite_bisecting.sh SQLRight --oracle NOREC --feedback save_all
```

The bug bisecting process is expected to finish in `1` hours. 

#### 4.1.5 Figures

Make sure you have finished the steps in `Session 4.1.1 - 4.1.4`. 

The following scripts will generate *Figure 6a, c* in the paper. 

```bash
# If you use the `root` user to execute the docker command. It is possible that you need to change the privilege access for the Results output folder. 
cd <sqlright_root>/SQLite/Results
sudo chown -R <your_user_name> ./*

# Plot the figures
cd <sqlright_root>/Plot_Scripts/SQLite3/NoREC/Feedback_Test
python3 copy_results.py
python3 run_plots.py
```

The figures will be saved in folder: `Plot_Scripts/SQLite3/NoREC/Feedback_Test/plots`.

**Expectations**:

- For bugs of SQLite (NoREC): `SQLRight` should detect the most bugs. On different evaluation around, we expect `>= 2` bugs being detected by `SQLRight` in `24` hours. 
- For coverage of SQLite (NoREC): `SQLRight` should have the highest code coverage among the other baselines. 

--------------------------------------
### 4.2 TLP

#### 4.2.1 SQLRight

Make sure you have finished `Session 3.4.1` in this Artifact Evaluation. 

#### 4.2.2 SQLRight Drop All

<sub>`121` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 24 hours.

```bash
cd <sqlright_root>/SQLite/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_sqlite_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle TLP --feedback drop_all 
```

After `24` hours, stop the Docker container instance, and then run the following bug bisecting command. 

```bash
# Stop the fuzzing process
sudo docker stop sqlright_sqlite_drop_all_TLP
# Run bug bisecting
cd <sqlright_root>/SQLite/scripts
bash run_sqlite_bisecting.sh SQLRight --oracle TLP --feedback drop_all 
```

The bug bisecting process is expected to finish in `1` hours. 

#### 4.2.3 SQLRight Random Save

<sub>`121` CPU hours</sub>

**WARNING**: Due to the aggresive query seed handling strategy, the `SQLRight` Random Save config will generate a large amount of `cache` data, and it will save the cache to the file system. We expected around `15GB` of cache being generated from EACH SQLRight instance. Following the command below, we will call 5 instances of SQLancer, which will dump `75GB` of cache data. If not enough storage space is available, consider using a smaller number of `--num-concurrent`. 

```bash
cd <sqlright_root>/SQLite/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_sqlite_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle TLP --feedback random_save
```

After `24` hours, stop the Docker container instance, and then run the following bug bisecting command. 

```bash
# Stop the fuzzing process
sudo docker stop sqlright_sqlite_random_save_TLP
# Run bug bisecting
cd <sqlright_root>/SQLite/scripts
bash run_sqlite_bisecting.sh SQLRight --oracle TLP --feedback random_save
```

The bug bisecting process is expected to finish in `1` hours. 

#### 4.2.4 SQLRight Save All
<sub>`121` CPU hours</sub>

**WARNING**: Due to the aggresive query seed handling strategy, the `SQLRight` Random Save config will generate a large amount of `cache` data, and it will save the cache to the file system. We expected around `20GB` of cache being generated from EACH SQLRight instance. Following the command below, we will call 5 instances of SQLancer, which will dump `100GB` of cache data. If not enough storage space is available, consider using a smaller number of `--num-concurrent`. 

```bash
cd <sqlright_root>/SQLite/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_sqlite_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle TLP --feedback save_all
```

After `24` hours, stop the Docker container instance, and then run the following bug bisecting command. 

```bash
# Stop the fuzzing process
sudo docker stop sqlright_sqlite_save_all_TLP
# Run bug bisecting
cd <sqlright_root>/SQLite/scripts
bash run_sqlite_bisecting.sh SQLRight --oracle TLP --feedback save_all
```

The bug bisecting process is expected to finish in `1` hours. 

#### 4.2.5 Figures

Make sure you have finished the steps in `Session 4.2.1 - 4.2.4`. 

The following scripts will generate *Figure 6b, d* in the paper. 

```bash
# If you use the `root` user to execute the docker command. It is possible that you need to change the privilege access for the Results output folder. 
cd <sqlright_root>/SQLite/Results
sudo chown -R <your_user_name> ./*

# Plot the figures
cd <sqlright_root>/Plot_Scripts/SQLite3/TLP/Feedback_Tests
python3 copy_results.py
python3 run_plots.py
```

The figures will be generated in folder `Plot_Scripts/SQLite3/TLP/Feedback_Tests/plots`. 

**Expectations**:

- For bugs of SQLite (TLP): `SQLRight` should detect the most bugs. On different evaluation around, we expect `>= 2` bugs being detected by `SQLRight` in `24` hours. 
- For coverage of SQLite (TLP): `SQLRight` should have the highest code coverage among the other baselines. 

---------------------------------------------
### 4.3. Mutation Depth

Get the mutation depth information shown in the *Table 3* in the paper. 

Make sure you have finished all tests in *Session 4.1 and 4.2*. 

```bash
cd <sqlright_root>/Plot_scripts
python3 count_queue_depth.py
```

**Expectations**:

- The Queue Depth information will be returned. 
- The mutation depth number returned could be slightly different between each run. 
- The `Max Depth` from SQLRight NoREC and TLP should be larger than other baselines
- SQLRight NoREC and TLP should have more queue seeds located in a deeper depth, compared to other baselines. 


<br/><br/>
## 5. Contribution of Validity Components

### 5.1 SQLite NoREC

#### 5.1.1 SQLRight 

Make sure you have finished *Session 3.1.1* in this Artifact Evaluation. 

#### 5.1.2 SQLRight No-Ctx-Valid 

<sub>`121` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 24 hours.

```bash
cd <sqlright_root>/SQLite/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_sqlite_fuzzing.sh no-ctx-valid --start-core 0 --num-concurrent 5 --oracle NOREC
```

After 24 hours, stop the Docker container instance. And then run the following bug bisecting command:

```bash
# Stop the fuzzing process
sudo docker stop sqlright_sqlite_no_ctx_valid_NOREC
# Run bug bisecting
bash run_sqlite_bisecting.sh no-ctx-valid --oracle NOREC
```

The bug bisecting process is expected to finish in `1` hour.

#### 5.1.3 SQLRight No-DB-Par-Ctx-Valid 

<sub>`121` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 24 hours.

```bash
cd <sqlright_root>/SQLite/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_sqlite_fuzzing.sh no-db-par-ctx-valid --start-core 0 --num-concurrent 5 --oracle NOREC
```

After 24 hours, stop the Docker container instance. And then run the following bug bisecting command:

```bash
# Stop the fuzzing process
sudo docker stop sqlright_sqlite_no_db_par_ctx_valid_NOREC
# Run bug bisecting
bash run_sqlite_bisecting.sh no-db-par-ctx-valid --oracle NOREC
```

The bug bisecting process is expected to finish in `1` hour.

#### 5.1.4 Squirrel-Oracle

Make sure you have finished *Session 3.1.2* in this Artifact Evaluation. 

#### 5.1.5 SQLRight Non-Deter

<sub>`121` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 24 hours.

```bash
cd <sqlright_root>/SQLite/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_sqlite_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle NOREC --non-deter
```

After 24 hours, stop the Docker container instance. And then run the following bug bisecting command:

```bash
# Stop the fuzzing process
sudo docker stop sqlright_sqlite_NOREC_non_deter
# Run bug bisecting
bash run_sqlite_bisecting.sh SQLRight --oracle NOREC --non-deter
```

The bug bisecting process is expected to finish in `1` hour. 

#### 5.1.6 Figures

The following scripts will generate *Figure 7a, c, f, i* in the paper.

```bash
# If you use the `root` user to execute the docker command. It is possible that you need to change the privilege access for the Results output folder. 
cd <sqlright_root>/SQLite/Results
sudo chown -R <your_user_name> ./*

# Plot the figures
cd <sqlright_root>/Plot_Scripts/SQLite3/NoREC/Validate_Parts
python3 copy_results.py
python3 run_plots.py
```

The figures will be generated in folder: `<sqlright_root>/Plot_Scripts/SQLite3/NoREC/Validate_Parts/plots`. 

**Expectations**:

- For SQLite logical bugs figure: `SQLRight` should detect the most bugs. On different evaluation around, we expect `>= 2` bugs being detected by `SQLRight` in `24` hours. Additionally, we have muted the `SQLRight non-deter` config in the Artifact logical bugs figure. Because sometimes `non-deter` could produce tens of False Positives, which would destroy the plot region and render the script outputs an unreadable plots. 
- For SQLite code coverage figure: `SQLRight` and `SQLRight non-deter` should have the highest code coverage among the other baselines. `SQLRight non-ctx-valid` could have a coverage very close to the `SQLRight` config, but in general, `SQLRight non-ctx-valid` is slightly worse in coverage compared to `SQLRight`. 
- For SQLite query validity: `SQLRight` and `SQLRight non-deter` should have the highest query validity. 
- For SQLite valid stmts / hr: `SQLRight` and `SQLRight non-deter` should have the highest number of valid stmts / hr. 

--------------------------------------------------------------
### 5.2 PostgreSQL NoREC

#### 5.2.1 SQLRight

Make sure you have finished *Session 3.2.1* in this Artifact Evaluation. 

#### 5.2.2 SQLRight No-Ctx-Valid

<sub>`120` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 24 hours.

```bash
cd <sqlright_root>/PostgreSQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_postgres_fuzzing.sh no-ctx-valid --start-core 0 --num-concurrent 5 --oracle NOREC
```

After 24 hours, stop the Docker container instance. 

```bash
sudo docker stop sqlright_postgres_no_ctx_valid_NOREC
```

Since we did not find any bugs for PostgreSQL, we skip the bug bisecting process for PostgreSQL fuzzings. 

#### 5.2.3 SQLRight No-DB-Par-Ctx-Valid 

<sub>`120` CPU hours</sub>

Run the following command. Let the fuzzing processes run for `24` hours.

```bash
cd <sqlright_root>/PostgreSQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_postgres_fuzzing.sh no-db-par-ctx-valid --start-core 0 --num-concurrent 5 --oracle NOREC
```

After `24` hours, stop the Docker container instance. 

```bash
sudo docker stop sqlright_postgres_no_db_par_ctx_valid_NOREC
```

#### 5.2.4 Squirrel-Oracle

Make sure you have finished *Session 3.2.2* in this Artifact Evaluation. 

#### 5.2.5 Figures

Because we did not detect False Positives when using `SQLRight non-deter` in our PostgreSQL evaluations, the current `SQLRight non-deter` implementation is basically identical to `SQLRight`. We therefore skip `SQLRight non-deter` in this Artifact Evaluation. 

The following scripts will generate *Figure 7e, h, k* in the paper.

```bash
# If you use the `root` user to execute the docker command. It is possible that you need to change the privilege access for the Results output folder. 
cd <sqlright_root>/PostgreSQL/Results
sudo chown -R <your_user_name> ./*

# Plot the figures
cd <sqlright_root>/Plot_Scripts/Postgres/NoREC/Validate_Parts
python3 copy_results.py
python3 run_plots.py
```

The figures will be generated in folder: `<sqlright_root>/Plot_Scripts/Postgres/NoREC/Validate_Parts/plots`. 

**Expectations**:

- For PostgreSQL code coverage figure: `SQLRight` and `SQLRight non-deter` should have the highest code coverage among the other baselines. `SQLRight non-ctx-valid` could have a coverage very close to the `SQLRight` config, but in general, `SQLRight non-ctx-valid` is slightly worse in coverage compared to `SQLRight`. 
- For PostgreSQL query validity: `SQLRight` and `SQLRight non-deter` should have the highest query validity. 
- For PostgreSQL valid stmts / hr: `SQLRight` and `SQLRight non-deter` should have the highest number of valid stmts / hr. 

--------------------------------------------------------------------------
### 5.3 MySQL NoREC

#### 5.3.1 SQLRight

Make sure you have finished *Session 3.3.1* in this Artifact Evaluation. 

#### 5.3.2 SQLRight No-Ctx-Valid

<sub>`125` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 24 hours.

```bash
cd <sqlright_root>/MySQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_mysql_fuzzing.sh no-ctx-valid --start-core 0 --num-concurrent 5 --oracle NOREC
```

After 24 hours, stop the Docker container instance. And then run the following bug bisecting command:

```bash
# Stop the fuzzing process
sudo docker stop sqlright_mysql_no_ctx_valid_NOREC
# Run bug bisecting
bash run_mysql_bisecting.sh no-ctx-valid --oracle NOREC
```

The bug bisecting process is expected to finish in `5` hours.

#### 5.3.3 SQLRight No-DB-Par-Ctx-Valid

<sub>`125` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 24 hours.

```bash
cd <sqlright_root>/MySQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process.
bash run_mysql_fuzzing.sh no-db-par-ctx-valid --start-core 0 --num-concurrent 5 --oracle NOREC
```

After 24 hours, stop the Docker container instance. And then run the following bug bisecting command:

```bash
# Stop the fuzzing process
sudo docker stop sqlright_mysql_no_db_par_ctx_valid_NOREC
# Run bug bisecting
bash run_mysql_bisecting.sh no-db-par-ctx-valid --oracle NOREC
```

The bug bisecting process is expected to finish in `5` hour.

#### 5.3.4 Squirrel-Oracle 

Make sure you have finished *Session 3.3.2* in this Artifact Evaluation. 

#### 5.3.5 SQLRight Non-Deter

<sub>`125` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 24 hours.

```bash
cd <sqlright_root>/MySQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_mysql_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle NOREC --non-deter
```

After 24 hours, stop the Docker container instance. And then run the following bug bisecting command:

```bash
# Stop the fuzzing process
sudo docker stop sqlright_mysql_NOREC_non_deter
# Run bug bisecting
bash run_mysql_bisecting.sh SQLRight --oracle NOREC --non-deter
```

The bug bisecting process is expected to finish in `5` hour.

#### 5.3.6 Figures

The following scripts will generate *Figure 7b, d, g, j* in the paper.

```bash
# If you use the `root` user to execute the docker command. It is possible that you need to change the privilege access for the Results output folder. 
cd <sqlright_root>/MySQL/Results
sudo chown -R <your_user_name> ./*

# Plot the figures
cd <sqlright_root>/Plot_Scripts/MySQL/NoREC/Validate_Parts
python3 copy_results.py
python3 run_plots.py
```

**Expectations**:

- For MySQL logical bugs figure: The current bisecting and bug filtering scripts could slightly over-estimate the number of unique bugs for MySQL. Some manual efforts might be needed to scan through the bug reports and deduplicate the bugs. In general, `SQLRight` should detect the most bugs. On different evaluation around, we expect `>= 1` bugs being detected by `SQLRight` in `24` hours. Additionally, we have muted the `SQLRight non-deter` config in the Artifact logical bugs figure. Because sometimes `non-deter` could produce tens of False Positives, which would destroy the plot region and render the script outputs an unreadable plots. 
- For MySQL code coverage figure: `SQLRight` and `SQLRight non-deter` should have the highest code coverage among the other baselines. `SQLRight non-ctx-valid` could have a coverage very close to the `SQLRight` config, but in general, `SQLRight non-ctx-valid` is slightly worse in coverage compared to `SQLRight`. 
- For MySQL query validity: `SQLRight` and `SQLRight non-deter` should have the highest query validity. 
- For MySQL valid stmts / hr: `SQLRight` and `SQLRight non-deter` should have the highest number of valid stmts / hr. 

--------------------------------------------------
### 5.4 SQLite TLP

#### 5.4.1 SQLRight 

Make sure you have finished *Session 3.4.1* in this Artifact Evaluation. 

#### 5.4.2 SQLRight No-Ctx-Valid 

<sub>`121` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 24 hours.

**Attention**: Be careful with the `--oracle` flag. Here we are using `TLP` instead of `NOREC` in the previous evaluations. 

```bash
cd <sqlright_root>/SQLite/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_sqlite_fuzzing.sh no-ctx-valid --start-core 0 --num-concurrent 5 --oracle TLP
```

After 24 hours, stop the Docker container instance. And then run the following bug bisecting command:

```bash
# Stop the fuzzing process
sudo docker stop sqlright_sqlite_no_ctx_valid_TLP
# Run bug bisecting
bash run_sqlite_bisecting.sh no-ctx-valid --oracle TLP
```

The bug bisecting process is expected to finish in `1` hour.

#### 5.4.3 SQLRight No-DB-Par-Ctx-Valid 

<sub>`121` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 24 hours.

**Attention**: Be careful with the `--oracle` flag. Here we are using `TLP` instead of `NOREC` in the previous evaluations. 

```bash
cd <sqlright_root>/SQLite/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_sqlite_fuzzing.sh no-db-par-ctx-valid --start-core 0 --num-concurrent 5 --oracle TLP
```

After 24 hours, stop the Docker container instance. And then run the following bug bisecting command:

```bash
# Stop the fuzzing process
sudo docker stop sqlright_sqlite_no_db_par_ctx_valid_TLP
# Run bug bisecting
bash run_sqlite_bisecting.sh no-db-par-ctx-valid --oracle TLP
```

The bug bisecting process is expected to finish in `1` hour.

#### 5.4.4 Squirrel-Oracle

Make sure you have finished *Session 3.4.2* in this Artifact Evaluation. 

#### 5.4.5 SQLRight Non-Deter

<sub>`121` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 24 hours.

**Attention**: Be careful with the `--oracle` flag. Here we are using `TLP` instead of `NOREC` in the previous evaluations. 

```bash
cd <sqlright_root>/SQLite/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_sqlite_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle TLP --non-deter
```

After 24 hours, stop the Docker container instance. And then run the following bug bisecting command:

```bash
# Stop the fuzzing process
sudo docker stop sqlright_sqlite_TLP_non_deter
# Run bug bisecting
bash run_sqlite_bisecting.sh SQLRight --oracle TLP --non-deter
```

The bug bisecting process is expected to finish in `1` hour. 

#### 5.4.6 Figures

The following scripts will generate *Figure 9a, c, f, i* in the paper.

```bash
# If you use the `root` user to execute the docker command. It is possible that you need to change the privilege access for the Results output folder. 
cd <sqlright_root>/SQLite/Results
sudo chown -R <your_user_name> ./*

# Plot the figures
cd <sqlright_root>/Plot_Scripts/SQLite3/TLP/Validate_Parts
python3 copy_results.py
python3 run_plots.py
```

The figures will be generated in folder: `<sqlright_root>/Plot_Scripts/SQLite3/TLP/Validate_Parts/plots`. 

**Expectations**:

- For SQLite logical bugs figure: `SQLRight` should detect the most bugs. On different evaluation around, we expect `>= 2` bugs being detected by `SQLRight` in `24` hours. Additionally, we have muted the `SQLRight non-deter` config in the Artifact logical bugs figure. Because sometimes `non-deter` could produce tens of False Positives, which would destroy the plot region and render the script outputs an unreadable plots. 
- For SQLite code coverage figure: `SQLRight` and `SQLRight non-deter` should have the highest code coverage among the other baselines. 
- For SQLite query validity: `SQLRight` and `SQLRight non-deter` should have the highest query validity. 
- For SQLite valid stmts / hr: `SQLRight` and `SQLRight non-deter` should have the highest number of valid stmts / hr. 

--------------------------------------------------------------
### 5.5 PostgreSQL TLP

#### 5.5.1 SQLRight

Make sure you have finished *Session 3.5.1* in this Artifact Evaluation. 

#### 5.5.2 SQLRight No-Ctx-Valid

<sub>`120` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 24 hours.

**Attention**: Be careful with the `--oracle` flag. Here we are using `TLP` instead of `NOREC` in the previous evaluations. 

```bash
cd <sqlright_root>/PostgreSQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_postgres_fuzzing.sh no-ctx-valid --start-core 0 --num-concurrent 5 --oracle TLP
```

After 24 hours, stop the Docker container instance. 

```bash
sudo docker stop sqlright_postgres_no_ctx_valid_TLP
```

Since we did not find any bugs for PostgreSQL, we skip the bug bisecting process for PostgreSQL fuzzings. 

#### 5.5.3 SQLRight No-DB-Par-Ctx-Valid 

<sub>`120` CPU hours</sub>

Run the following command. Let the fuzzing processes run for `24` hours.

**Attention**: Be careful with the `--oracle` flag. Here we are using `TLP` instead of `NOREC` in the previous evaluations. 

```bash
cd <sqlright_root>/PostgreSQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_postgres_fuzzing.sh no-db-par-ctx-valid --start-core 0 --num-concurrent 5 --oracle TLP
```

After `24` hours, stop the Docker container instance. 

```bash
sudo docker stop sqlright_postgres_no_db_par_ctx_valid_TLP
```

#### 5.5.4 Squirrel-Oracle

Make sure you have finished *Session 3.5.2* in this Artifact Evaluation. 

#### 5.5.5 Figures

Because we did not detect False Positives when using `SQLRight non-deter` in our PostgreSQL evaluations, the current `SQLRight non-deter` implementation is basically identical to `SQLRight`. We therefore skip `SQLRight non-deter` in this Artifact Evaluation. 

The following scripts will generate *Figure 9e, h, k* in the paper.

```bash
# If you use the `root` user to execute the docker command. It is possible that you need to change the privilege access for the Results output folder. 
cd <sqlright_root>/PostgreSQL/Results
sudo chown -R <your_user_name> ./*

# Plot the figures
cd <sqlright_root>/Plot_Scripts/Postgres/TLP/Validate_Parts
python3 copy_results.py
python3 run_plots.py
```

The figures will be generated in folder: `<sqlright_root>/Plot_Scripts/Postgres/NoREC/Validate_Parts/plots`. 

**Expectations**:

- For PostgreSQL code coverage figure: `SQLRight` and `SQLRight non-deter` should have the highest code coverage among the other baselines. `SQLRight non-ctx-valid` could have a coverage very close to the `SQLRight` config, but in general, `SQLRight non-ctx-valid` is slightly worse in coverage compared to `SQLRight`. 
- For PostgreSQL query validity: `SQLRight` and `SQLRight non-deter` should have the highest query validity. 
- For PostgreSQL valid stmts / hr: `SQLRight` and `SQLRight non-deter` should have the highest number of valid stmts / hr. 

--------------------------------------------------------------------------
### 5.6 MySQL TLP

#### 5.6.1 SQLRight

Make sure you have finished *Session 3.6.1* in this Artifact Evaluation. 

#### 5.6.2 SQLRight No-Ctx-Valid

<sub>`125` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 24 hours.

**Attention**: Be careful with the `--oracle` flag. Here we are using `TLP` instead of `NOREC` in the previous evaluations. 

```bash
cd <sqlright_root>/MySQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_mysql_fuzzing.sh no-ctx-valid --start-core 0 --num-concurrent 5 --oracle TLP
```

After 24 hours, stop the Docker container instance. And then run the following bug bisecting command:

```bash
# Stop the fuzzing process
sudo docker stop sqlright_mysql_no_ctx_valid_TLP
# Run bug bisecting
bash run_mysql_bisecting.sh no-ctx-valid --oracle TLP
```

The bug bisecting process is expected to finish in `5` hours.

#### 5.6.3 SQLRight No-DB-Par-Ctx-Valid

<sub>`125` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 24 hours.

**Attention**: Be careful with the `--oracle` flag. Here we are using `TLP` instead of `NOREC` in the previous evaluations. 

```bash
cd <sqlright_root>/MySQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process.
bash run_mysql_fuzzing.sh no-db-par-ctx-valid --start-core 0 --num-concurrent 5 --oracle TLP
```

After 24 hours, stop the Docker container instance. And then run the following bug bisecting command:

```bash
# Stop the fuzzing process
sudo docker stop sqlright_mysql_no_db_par_ctx_valid_TLP
# Run bug bisecting
bash run_mysql_bisecting.sh no-db-par-ctx-valid --oracle TLP
```

The bug bisecting process is expected to finish in `5` hour.

#### 5.6.4 Squirrel-Oracle 

Make sure you have finished *Session 3.6.2* in this Artifact Evaluation. 

#### 5.6.5 SQLRight Non-Deter

<sub>`125` CPU hours</sub>

Run the following command. Let the fuzzing processes run for 24 hours.

**Attention**: Be careful with the `--oracle` flag. Here we are using `TLP` instead of `NOREC` in the previous evaluations. 

```bash
cd <sqlright_root>/MySQL/scripts
# Run the fuzzing with CPU core 1~5 (core id is 0-based). 
# Please adjust the CORE ID based on your machine, 
# and do not use conflict core id with other running evaluation process. 
bash run_mysql_fuzzing.sh SQLRight --start-core 0 --num-concurrent 5 --oracle TLP --non-deter
```

After 24 hours, stop the Docker container instance. And then run the following bug bisecting command:

```bash
# Stop the fuzzing process
sudo docker stop sqlright_mysql_TLP_non_deter
# Run bug bisecting
bash run_mysql_bisecting.sh SQLRight --oracle TLP --non-deter
```

The bug bisecting process is expected to finish in `5` hour.

#### 5.6.6 Figures

The following scripts will generate *Figure 9b, d, g, j* in the paper.

```bash
# If you use the `root` user to execute the docker command. It is possible that you need to change the privilege access for the Results output folder. 
cd <sqlright_root>/MySQL/Results
sudo chown -R <your_user_name> ./*

# Plot the figures
cd <sqlright_root>/Plot_Scripts/MySQL/TLP/Validate_Parts
python3 copy_results.py
python3 run_plots.py
```

**Expectations**:

- For MySQL logical bugs figure: The current bisecting and bug filtering scripts could slightly over-estimate the number of unique bugs for MySQL. Some manual efforts might be needed to scan through the bug reports and deduplicate the bugs. In general, `SQLRight` should detect the most bugs. On different evaluation around, we expect `>= 1` bugs being detected by `SQLRight` in `24` hours. Additionally, we have muted the `SQLRight non-deter` config in the Artifact logical bugs figure. Because sometimes `non-deter` could produce tens of False Positives, which would destroy the plot region and render the script outputs an unreadable plots. 
- For MySQL code coverage figure: `SQLRight` and `SQLRight non-deter` should have the highest code coverage among the other baselines. `SQLRight non-ctx-valid` could have a coverage very close to the `SQLRight` config, but in general, `SQLRight non-ctx-valid` is slightly worse in coverage compared to `SQLRight`. 
- For MySQL query validity: `SQLRight` and `SQLRight non-deter` should have the highest query validity. 
- For MySQL valid stmts / hr: `SQLRight` and `SQLRight non-deter` should have the highest number of valid stmts / hr. 

--------------------------------------------------------------------------
### 5.7 False Positives from Non-Deter

Make sure you have finished *Section 5.1 - 5.6* first.

The following scripts will generate *Table 4* in the paper. 

```bash
cd <sqlright_root>/Plot_Scripts/
python3 count_false_positives.py
```

**Expectations**:

- The script will return the reported bug numbers for the configs in *Table 4*. 
- We have introduced some extra filters that can filter out obvious False Positives. We includes these filters in the Artifact implementation, in order to reduce the manual efforts for excluding FPs, and to produce a more accurate bug numbers. Therefore, the bug number reported by the current Artifact script could be slightly less than the ones we reported in the paper (*Table 3*). 
- For all configurations, the `WITHOUT non-deter` settings should always have less bugs reported compared to the `WITH non-deter` settings, due to the extra False Positives produced by the non-deterministic queries. 


<br/><br/>
<br/><br/>
# End of the Artifact Evaluation Instructions

To clean up all the Docker cache after finishing the Artifact, run the following command:

```bash
# Well, make sure to keep your own Docker Images and Containers. :-)
sudo docker system prune --all
```

We hereby thank all the reviewers for putting in the hard work to reproduce the results we presented in the paper. 

Have a great Summer. And have a great USENIX Security 2022 conference! 
