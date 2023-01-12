/*
  Copyright 2015 Google LLC All rights reserved.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at:

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

/*
   american fuzzy lop - test case minimizer
   ----------------------------------------

   Written and maintained by Michal Zalewski <lcamtuf@google.com>

   A simple test case minimizer that takes an input file and tries to remove
   as much data as possible while keeping the binary in a crashing state
   *or* producing consistent instrumentation output (the mode is auto-selected
   based on the initially observed behavior).
*/

#define AFL_MAIN

#include "alloc-inl.h"
#include "config.h"
#include "debug.h"
#include "hash.h"
#include "types.h"

#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include "../include/ir_wrapper.h"
#include "../include/mutate.h"
#include "debug.h"

#include <atomic>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <sys/resource.h>
#include <sys/shm.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/wait.h>

using namespace std;

static std::atomic<s32> forksrv_pid = -1, /* PID of the fork server           */
    child_pid = -1;                       /* PID of the fuzzed program        */

static u8 *trace_bits, /* SHM with instrumentation bitmap   */
    *mask_bitmap;      /* Mask for trace bits (-B)          */

static u8 *in_file, /* Minimizer input test case         */
    *out_file,      /* Minimizer output file             */
    *prog_in,       /* Targeted program input file       */
    *target_path,   /* Path to target binary             */
    *doc_path;      /* Path to docs                      */

static s32 fsrv_ctl_fd, /* Fork server control pipe (write) */
    fsrv_st_fd;         /* Fork server status pipe (read)   */

static u8 *in_data; /* Input data for trimming           */

static u32 in_len,             /* Input data length                 */
    orig_cksum,                /* Original checksum                 */
    total_execs,               /* Total number of execs             */
    missed_hangs,              /* Misses due to hangs               */
    missed_crashes,            /* Misses due to crashes             */
    missed_paths,              /* Misses due to exec path diffs     */
    exec_tmout = EXEC_TIMEOUT; /* Exec timeout (ms)                 */

static u64 mem_limit = MEM_LIMIT; /* Memory limit (MB)                 */

static s32 shm_id,    /* ID of the SHM region              */
    dev_null_fd = -1; /* FD to /dev/null                   */

static u8 crash_mode, /* Crash-centric mode?               */
    exit_crash,       /* Treat non-zero exit as crash?     */
    edges_only,       /* Ignore hit counts?                */
    exact_mode,       /* Require path match for crashes?   */
    use_stdin = 1;    /* Use stdin for program input?      */

static volatile u8 stop_soon, /* Ctrl-C pressed?                   */
    child_timed_out = 0;      /* Child timed out?                  */

static bool is_timeout;

///* Classify tuple counts. This is a slow & naive version, but good enough
///here. */
//
// static const u8 count_class_lookup[256] = {
//
//  [0]           = 0,
//  [1]           = 1,
//  [2]           = 2,
//  [3]           = 4,
//  [4 ... 7]     = 8,
//  [8 ... 15]    = 16,
//  [16 ... 31]   = 32,
//  [32 ... 127]  = 64,
//  [128 ... 255] = 128
//
//};
static u8 count_class_lookup8[256] = {0};
static u8 simplify_lookup[256] = {0};

static u16 count_class_lookup16[65536];

#if defined(__x86_64__) || defined(__arm64__) || defined(__aarch64__)

static void simplify_trace(u64 *mem) {

  u32 i = MAP_SIZE >> 3;

  while (i--) {

    /* Optimize for sparse bitmaps. */

    if (unlikely(*mem)) {

      u8 *mem8 = (u8 *)mem;

      mem8[0] = simplify_lookup[mem8[0]];
      mem8[1] = simplify_lookup[mem8[1]];
      mem8[2] = simplify_lookup[mem8[2]];
      mem8[3] = simplify_lookup[mem8[3]];
      mem8[4] = simplify_lookup[mem8[4]];
      mem8[5] = simplify_lookup[mem8[5]];
      mem8[6] = simplify_lookup[mem8[6]];
      mem8[7] = simplify_lookup[mem8[7]];
    } else
      *mem = 0x0101010101010101ULL;

    mem++;
  }
}

#else

static void simplify_trace(u32 *mem) {

  u32 i = MAP_SIZE >> 2;

  while (i--) {

    /* Optimize for sparse bitmaps. */

    if (unlikely(*mem)) {

      u8 *mem8 = (u8 *)mem;

      mem8[0] = simplify_lookup[mem8[0]];
      mem8[1] = simplify_lookup[mem8[1]];
      mem8[2] = simplify_lookup[mem8[2]];
      mem8[3] = simplify_lookup[mem8[3]];
    } else
      *mem = 0x01010101;

    mem++;
  }
}

#endif /* ^__x86_64__ */

void memset_array() {
  simplify_lookup[0] = 1;
  memset(simplify_lookup + 1, 128, 255);

  count_class_lookup8[0] = 0;
  count_class_lookup8[1] = 1;
  count_class_lookup8[2] = 2;
  count_class_lookup8[3] = 4;
  memset(count_class_lookup8 + 4, 8, 7 - 4 + 1);
  memset(count_class_lookup8 + 8, 16, 15 - 8 + 1);
  memset(count_class_lookup8 + 16, 32, 32 - 16);
  memset(count_class_lookup8 + 32, 64, 128 - 32);
  memset(count_class_lookup8 + 128, 128, 128);
}

static void init_count_class16(void) {

  u32 b1, b2;

  for (b1 = 0; b1 < 256; b1++)
    for (b2 = 0; b2 < 256; b2++)
      count_class_lookup16[(b1 << 8) + b2] =
          (count_class_lookup8[b1] << 8) | count_class_lookup8[b2];
}

#if defined(__x86_64__) || defined(__arm64__) || defined(__aarch64__)
static inline void classify_counts(u64 *mem) {

  u32 i = MAP_SIZE >> 3;

  while (i--) {

    /* Optimize for sparse bitmaps. */

    if (unlikely(*mem)) {

      u16 *mem16 = (u16 *)mem;

      mem16[0] = count_class_lookup16[mem16[0]];
      mem16[1] = count_class_lookup16[mem16[1]];
      mem16[2] = count_class_lookup16[mem16[2]];
      mem16[3] = count_class_lookup16[mem16[3]];
    }

    mem++;
  }
}

#else

static inline void classify_counts(u32 *mem) {

  u32 i = MAP_SIZE >> 2;

  while (i--) {

    /* Optimize for sparse bitmaps. */

    if (unlikely(*mem)) {

      u16 *mem16 = (u16 *)mem;

      mem16[0] = count_class_lookup16[mem16[0]];
      mem16[1] = count_class_lookup16[mem16[1]];
    }

    mem++;
  }
}

#endif /* ^__x86_64__ */

static void init_forkserver(char **argv);

// static void classify_counts(u8* mem) {
//
//  u32 i = MAP_SIZE;
//
//  if (edges_only) {
//
//    while (i--) {
//      if (*mem) *mem = 1;
//      mem++;
//    }
//
//  } else {
//
//    while (i--) {
//      *mem = count_class_lookup[*mem];
//      mem++;
//    }
//
//  }
//
//}

///* Apply mask to classified bitmap (if set). */
//
// static void apply_mask(u32* mem, u32* mask) {
//
//  u32 i = (MAP_SIZE >> 2);
//
//  if (!mask) return;
//
//  while (i--) {
//
//    *mem &= ~*mask;
//    mem++;
//    mask++;
//
//  }
//
//}

/* See if any bytes are set in the bitmap. */

static inline u8 anything_set(void) {

  u32 *ptr = (u32 *)trace_bits;
  u32 i = (MAP_SIZE >> 2);

  while (i--)
    if (*(ptr++))
      return 1;

  return 0;
}

/* Get rid of shared memory and temp files (atexit handler). */

static void remove_shm(void) {

  if (prog_in)
    unlink(prog_in); /* Ignore errors */
  shmctl(shm_id, IPC_RMID, NULL);
}

/* Configure shared memory. */

static void setup_shm(void) {

  u8 *shm_str;

  shm_id = shmget(IPC_PRIVATE, MAP_SIZE, IPC_CREAT | IPC_EXCL | 0600);

  if (shm_id < 0)
    PFATAL("shmget() failed");

  atexit(remove_shm);

  shm_str = alloc_printf("%d", shm_id);

  setenv(SHM_ENV_VAR, shm_str, 1);

  ck_free(shm_str);

  trace_bits = shmat(shm_id, NULL, 0);

  if (trace_bits == (void *)-1)
    PFATAL("shmat() failed");
}

/* Read initial file. */

static void read_initial_file(void) {

  struct stat st;
  s32 fd = open(in_file, O_RDONLY);

  if (fd < 0)
    PFATAL("Unable to open '%s'", in_file);

  if (fstat(fd, &st) || !st.st_size)
    FATAL("Zero-sized input file.");

  if (st.st_size >= TMIN_MAX_FILE)
    FATAL("Input file is too large (%u MB max)", TMIN_MAX_FILE / 1024 / 1024);

  in_len = st.st_size;
  in_data = ck_alloc_nozero(in_len);

  ck_read(fd, in_data, in_len, in_file);

  close(fd);

  OKF("Read %u byte%s from '%s'.", in_len, in_len == 1 ? "" : "s", in_file);
}

/* Write output file. */

static void write_to_file(u8 *path, u8 *mem, u32 len) {

  string input = "";
  for (int i = 0; i < len; i++) {
    input += (char)(mem[i]);
  }

  ofstream query_input;
  query_input.open("./input_query.sql", ofstream::out);
  query_input << input;
  query_input.close();

  return;
}

/*
 * Restart the CockroachDB persistent server.
 * */
static void restart_cockroachdb(char **argv) {
  if (forksrv_pid != -1) {
    kill(forksrv_pid, SIGKILL);
  }
  forksrv_pid = -1;
  init_forkserver(argv);
  return;
}

/* Handle timeout signal. */

static void handle_timeout(int sig) {

  is_timeout = true;
  //  child_timed_out = 1;
  if (forksrv_pid != -1) {
    kill(forksrv_pid, SIGKILL);
  }
  forksrv_pid = -1;
}

/* Execute target application. Returns 0 if the changes are a dud, or
   1 if they should be kept. */

static u8 run_target(char **argv, u8 *mem, u32 len, u8 first_run) {

  static struct itimerval it;
  int status = 0;
  is_timeout = false;

  static u64 exec_ms = 0;
  static u32 prev_timed_out = 0;
  u32 cksum;
  s32 res;

  Mutator mutator;
  IRWrapper ir_wrapper;
  mutator.init_data_library();

  string in_str = "";
  string mutated_str = "";

  for (int i = 0; i < len; i++) {
    in_str += mem[i];
  }

  while (true) {

    mutated_str = in_str;

    if (stop_soon) {
      exit(0);
    }

    for (int j = 0; j < 10; j++) {
      IR *new_rand_ir = mutator.constr_rand_set_stmt();
      string new_rand_str = new_rand_ir->to_string();
      new_rand_ir->deep_drop();

      mutated_str = new_rand_str + "\n" + mutated_str;
    }

    cerr << "\n\n\nTesting with mutated_str: \n" << mutated_str << "\n\n\n";

    write_to_file(prog_in, (u8 *)(mutated_str.c_str()), mutated_str.size());

    // Send the signal to notify the CockroachDB to start executions.
    while ((res = write(fsrv_ctl_fd, &prev_timed_out, 4)) != 4) {
      if (stop_soon) {
        return 0;
      }
      // Make sure the CockroachDB process is restart correctly.
      restart_cockroachdb(argv);
    }

    /* Inside the parent process.
    // Wait for the child process.
    // Check the execution status.
    // Let the signal handler handle the timeout situation.
    */

    // Setup the timeout struct.
    it.it_value.tv_sec = (exec_tmout / 1000);
    it.it_value.tv_usec = (exec_tmout % 1000) * 1000;

    setitimer(ITIMER_REAL, &it, NULL);

    if ((res = read(fsrv_st_fd, &status, 4)) != 4) {

      /* Get the timeout message before looping the forksrv_pid.  */
      bool cur_is_timeout = is_timeout;

      cerr << "The CockroachDB process is not responding? Could be timeout "
              "killed or crashed. is_timeout: "
           << cur_is_timeout << "\n\n\n";

      // Clean up the fd before calling init_forkserver.
      close(fsrv_ctl_fd);
      close(fsrv_st_fd);

      // Block the execution until handle_timeout has been finished.
      do {
      } while (forksrv_pid != -1);

      // Restart the argv execution.
      init_forkserver(argv);

      // Return the error.
      if (cur_is_timeout) {
        return 0;
      } else {

        ofstream out_file("./crash_poc", ios_base::out);
        out_file << mutated_str;
        out_file.close();

        cerr << "\n\n\nFound the system setting that can trigger the crash: \n"
             << mutated_str << "\n\n\nEXIT\n\n\n";

        return 1;
      }
    }

    string sql_res_str;
    if (filesystem::exists("query_res_out.txt")) {
      ifstream res_in("query_res_out.txt", ios::in);
      if (res_in) {
        // get length of file:
        res_in.seekg(0, res_in.end);
        int length = res_in.tellg();
        res_in.seekg(0, res_in.beg);

        char tmp_res[length];
        res_in.read(tmp_res, length);
        sql_res_str = string(tmp_res, length);
      }
      res_in.close();
      // Remove the file. Ignore the returned value.
      remove("./query_res_out.txt");
    }

    cerr << "Getting Results: \n" << sql_res_str << "\n\n";

    if (findStringIn(sql_res_str, "internal error")) {
      ofstream out_file("./crash_poc", ios_base::out);
      out_file << mutated_str;
      out_file.close();

      cerr << "\n\n\nFound the system setting that can trigger the crash: \n"
           << mutated_str << "\n\n\nEXIT\n\n\n";

      return 1;
    }

    // Always restart the CockroachDB server.
    close(fsrv_ctl_fd);
    close(fsrv_st_fd);
    restart_cockroachdb(argv);

    getitimer(ITIMER_REAL, &it);
    exec_ms = (u64)exec_tmout -
              (it.it_value.tv_sec * 1000 + it.it_value.tv_usec / 1000);

    // Cancel the SIGALRM timer.
    it.it_value.tv_sec = 0;
    it.it_value.tv_usec = 0;

    setitimer(ITIMER_REAL, &it, NULL);
  }

  //  if (filesystem::exists("./cov_out.bin")) {
  //      ifstream fin("./cov_out.bin", ios::in | ios::binary);
  //      fin.read(trace_bits, MAP_SIZE);
  //      fin.close();
  //      // Remove the file. Ignore the returned value.
  //      remove("./cov_out.bin");
  //  }

  //  /* Handle crashing inputs depending on current mode. */
  //
  //  if (WIFSIGNALED(status) ||
  //      (WIFEXITED(status) && WEXITSTATUS(status) == MSAN_ERROR) ||
  //      (WIFEXITED(status) && WEXITSTATUS(status) && exit_crash)) {
  //
  //    if (first_run) crash_mode = 1;
  //
  //    if (crash_mode) {
  //
  //      if (!exact_mode) return 1;
  //
  //    } else {
  //
  //      missed_crashes++;
  //      return 0;
  //
  //    }
  //
  //  } else
  //
  //  /* Handle non-crashing inputs appropriately. */
  //
  //  if (crash_mode) {
  //
  //    missed_paths++;
  //    return 0;
  //
  //  }
  //
  //  cksum = hash32(trace_bits, MAP_SIZE, HASH_CONST);
  //
  //  if (first_run) orig_cksum = cksum;
  //
  //  if (orig_cksum == cksum) return 1;
  //
  //  missed_paths++;
  return 0;
}

/* Find first power of two greater or equal to val. */

static u32 next_p2(u32 val) {

  u32 ret = 1;
  while (val > ret)
    ret <<= 1;
  return ret;
}

/* Actually minimize! */

static void minimize(char **argv) {

  static u32 alpha_map[256];

  u8 *tmp_buf = ck_alloc_nozero(in_len);
  u32 orig_len = in_len, stage_o_len;

  u32 del_len, set_len, del_pos, set_pos, i, alpha_size, cur_pass = 0;
  u32 syms_removed, alpha_del0 = 0, alpha_del1, alpha_del2, alpha_d_total = 0;
  u8 changed_any, prev_del;

  init_forkserver(argv);

  u8 res = 0;

  do {
    res = run_target(argv, tmp_buf, in_len, 0);
  } while (!res);

  cerr << "\n\n\nFound the crashing test case. EXIT. \n\n\n";
  exit(0);
}

/* Handle Ctrl-C and the like. */

static void handle_stop_sig(int sig) {

  stop_soon = 1;

  if (child_pid > 0)
    kill(child_pid, SIGKILL);
}

/* Do basic preparations - persistent fds, filenames, etc. */

static void set_up_environment(void) {

  char *x;

  dev_null_fd = open("/dev/null", O_RDWR);
  if (dev_null_fd < 0)
    PFATAL("Unable to open /dev/null");

  if (!prog_in) {

    u8 *use_dir = ".";

    if (access(use_dir, R_OK | W_OK | X_OK)) {

      use_dir = getenv("TMPDIR");
      if (!use_dir)
        use_dir = "/tmp";
    }

    prog_in = alloc_printf("%s/.afl-tmin-temp-%u", use_dir, getpid());
  }

  /* Set sane defaults... */

  x = getenv("ASAN_OPTIONS");

  if (x) {

    if (!strstr(x, "abort_on_error=1"))
      FATAL("Custom ASAN_OPTIONS set without abort_on_error=1 - please fix!");

    if (!strstr(x, "symbolize=0"))
      FATAL("Custom ASAN_OPTIONS set without symbolize=0 - please fix!");
  }

  x = getenv("MSAN_OPTIONS");

  if (x) {

    if (!strstr(x, "exit_code=" STRINGIFY(MSAN_ERROR)))
      FATAL("Custom MSAN_OPTIONS set without exit_code=" STRINGIFY(
          MSAN_ERROR) " - please fix!");

    if (!strstr(x, "symbolize=0"))
      FATAL("Custom MSAN_OPTIONS set without symbolize=0 - please fix!");
  }

  setenv("ASAN_OPTIONS",
         "abort_on_error=1:"
         "detect_leaks=0:"
         "symbolize=0:"
         "allocator_may_return_null=1",
         0);

  setenv("MSAN_OPTIONS",
         "exit_code=" STRINGIFY(MSAN_ERROR) ":"
                                            "symbolize=0:"
                                            "abort_on_error=1:"
                                            "allocator_may_return_null=1:"
                                            "msan_track_origins=0",
         0);

  if (getenv("AFL_PRELOAD")) {
    setenv("LD_PRELOAD", getenv("AFL_PRELOAD"), 1);
    setenv("DYLD_INSERT_LIBRARIES", getenv("AFL_PRELOAD"), 1);
  }
}

/* Setup signal handlers, duh. */

static void setup_signal_handlers(void) {

  struct sigaction sa;

  sa.sa_handler = NULL;
  sa.sa_flags = SA_RESTART;
  sa.sa_sigaction = NULL;

  sigemptyset(&sa.sa_mask);

  /* Various ways of saying "stop". */

  sa.sa_handler = handle_stop_sig;
  sigaction(SIGHUP, &sa, NULL);
  sigaction(SIGINT, &sa, NULL);
  sigaction(SIGTERM, &sa, NULL);

  /* Exec timeout notifications. */

  sa.sa_handler = handle_timeout;
  sigaction(SIGALRM, &sa, NULL);
}

/* Detect @@ in args. */

static void detect_file_args(char **argv) {

  u32 i = 0;
  u8 *cwd = getcwd(NULL, 0);

  if (!cwd)
    PFATAL("getcwd() failed");

  while (argv[i]) {

    u8 *aa_loc = strstr(argv[i], "@@");

    if (aa_loc) {

      u8 *aa_subst, *n_arg;

      /* Be sure that we're always using fully-qualified paths. */

      if (prog_in[0] == '/')
        aa_subst = prog_in;
      else
        aa_subst = alloc_printf("%s/%s", cwd, prog_in);

      /* Construct a replacement argv value. */

      *aa_loc = 0;
      n_arg = alloc_printf("%s%s%s", argv[i], aa_subst, aa_loc + 2);
      argv[i] = n_arg;
      *aa_loc = '@';

      if (prog_in[0] != '/')
        ck_free(aa_subst);
    }

    i++;
  }

  free(cwd); /* not tracked */
}

/* Display usage hints. */

static void usage(u8 *argv0) {

  SAYF("\n%s [ options ] -- /path/to/target_app [ ... ]\n\n"

       "Required parameters:\n\n"

       "  -i file       - input test case to be shrunk by the tool\n"
       "  -o file       - final output location for the minimized data\n\n"

       "Execution control settings:\n\n"

       "  -f file       - input file read by the tested program (stdin)\n"
       "  -t msec       - timeout for each run (%u ms)\n"
       "  -m megs       - memory limit for child process (%u MB)\n"
       "  -Q            - use binary-only instrumentation (QEMU mode)\n\n"

       "Minimization settings:\n\n"

       "  -e            - solve for edge coverage only, ignore hit counts\n"
       "  -x            - treat non-zero exit codes as crashes\n\n"

       "Other stuff:\n\n"

       "  -V            - show version number and exit\n\n"

       "For additional tips, please consult %s/README.\n\n",

       argv0, EXEC_TIMEOUT, MEM_LIMIT, doc_path);

  exit(1);
}

/* Find binary. */

static void find_binary(char *fname) {

  char *env_path = 0;
  struct stat st;

  if (strchr(fname, '/') || !(env_path = getenv("PATH"))) {

    target_path = ck_strdup(fname);

    if (stat(target_path, &st) || !S_ISREG(st.st_mode) ||
        !(st.st_mode & 0111) || st.st_size < 4)
      FATAL("Program '%s' not found or not executable", fname);

  } else {

    while (env_path) {

      char *cur_elem, *delim = strchr(env_path, ':');

      if (delim) {

        cur_elem = ck_alloc(delim - env_path + 1);
        memcpy(cur_elem, env_path, delim - env_path);
        delim++;

      } else
        cur_elem = ck_strdup(env_path);

      env_path = delim;

      if (cur_elem[0])
        target_path = alloc_printf("%s/%s", cur_elem, fname);
      else
        target_path = ck_strdup(fname);

      ck_free(cur_elem);

      if (!stat(target_path, &st) && S_ISREG(st.st_mode) &&
          (st.st_mode & 0111) && st.st_size >= 4)
        break;

      ck_free(target_path);
      target_path = 0;
    }

    if (!target_path)
      FATAL("Program '%s' not found or not executable", fname);
  }
}

/* Fix up argv for QEMU. */

static char **get_qemu_argv(u8 *own_loc, char **argv, int argc) {

  char **new_argv = ck_alloc(sizeof(char *) * (argc + 4));
  char *tmp, *cp, *rsl, *own_copy;

  /* Workaround for a QEMU stability glitch. */

  setenv("QEMU_LOG", "nochain", 1);

  memcpy(new_argv + 3, argv + 1, sizeof(char *) * argc);

  /* Now we need to actually find qemu for argv[0]. */

  new_argv[2] = target_path;
  new_argv[1] = "--";

  tmp = getenv("AFL_PATH");

  if (tmp) {

    cp = alloc_printf("%s/afl-qemu-trace", tmp);

    if (access(cp, X_OK))
      FATAL("Unable to find '%s'", tmp);

    target_path = new_argv[0] = cp;
    return new_argv;
  }

  own_copy = ck_strdup(own_loc);
  rsl = strrchr(own_copy, '/');

  if (rsl) {

    *rsl = 0;

    cp = alloc_printf("%s/afl-qemu-trace", own_copy);
    ck_free(own_copy);

    if (!access(cp, X_OK)) {

      target_path = new_argv[0] = cp;
      return new_argv;
    }

  } else
    ck_free(own_copy);

  if (!access(BIN_PATH "/afl-qemu-trace", X_OK)) {

    target_path = new_argv[0] = BIN_PATH "/afl-qemu-trace";
    return new_argv;
  }

  FATAL("Unable to find 'afl-qemu-trace'.");
}

/* Read mask bitmap from file. This is for the -B option. */

static void read_bitmap(u8 *fname) {

  s32 fd = open(fname, O_RDONLY);

  if (fd < 0)
    PFATAL("Unable to open '%s'", fname);

  ck_read(fd, mask_bitmap, MAP_SIZE, fname);

  close(fd);
}

static void init_forkserver(char **argv) {

  static struct itimerval it;
  int st_pipe[2], ctl_pipe[2];
  int status;
  s32 rlen;

  cerr << "\n\n\nRunning forkserver. \n\n\n";

  ACTF("Spinning up the fork server...");

  if (pipe(st_pipe) || pipe(ctl_pipe))
    PFATAL("pipe() failed");

  forksrv_pid = fork();

  if (forksrv_pid < 0)
    PFATAL("fork() failed");

  if (!forksrv_pid) {
    // Child process.

    struct rlimit r;

    /* Umpf. On OpenBSD, the default fd limit for root users is set to
       soft 128. Let's try to fix that... */

    if (!getrlimit(RLIMIT_NOFILE, &r) && r.rlim_cur < FORKSRV_FD + 2) {

      r.rlim_cur = FORKSRV_FD + 2;
      setrlimit(RLIMIT_NOFILE, &r); /* Ignore errors */
    }

    if (mem_limit) {

      r.rlim_max = r.rlim_cur = ((rlim_t)mem_limit) << 50;

#ifdef RLIMIT_AS

      setrlimit(RLIMIT_AS, &r); /* Ignore errors */

#else

      /* This takes care of OpenBSD, which doesn't have RLIMIT_AS, but
         according to reliable sources, RLIMIT_DATA covers anonymous
         maps - so we should be getting good protection against OOM bugs. */

      setrlimit(RLIMIT_DATA, &r); /* Ignore errors */

#endif /* ^RLIMIT_AS */
    }

    /* Dumping cores is slow and can lead to anomalies if SIGKILL is delivered
       before the dump is complete. */

    r.rlim_max = r.rlim_cur = 0;

    setrlimit(RLIMIT_CORE, &r); /* Ignore errors */

    /* Isolate the process and configure standard descriptors. If out_file is
       specified, stdin is /dev/null; otherwise, out_fd is cloned instead. */

    setsid();

    // Close the stdin, stdout and stderr.
    dup2(dev_null_fd, 0);
    dup2(dev_null_fd, 1);
    dup2(dev_null_fd, 2);

    /* Set up control and status pipes, close the unneeded original fds. */
    // FORKSRV_FD == 198
    if (dup2(ctl_pipe[0], FORKSRV_FD) < 0)
      PFATAL("dup2() failed");
    // FD == 199
    if (dup2(st_pipe[1], FORKSRV_FD + 1) < 0)
      PFATAL("dup2() failed");

    close(ctl_pipe[0]);
    close(ctl_pipe[1]);
    close(st_pipe[0]);
    close(st_pipe[1]);

    close(dev_null_fd);

    /* This should improve performance a bit, since it stops the linker from
       doing extra work post-fork(). */

    if (!getenv("LD_BIND_LAZY"))
      setenv("LD_BIND_NOW", "1", 0);

    /* Set sane defaults for ASAN if nothing else specified. */

    setenv("ASAN_OPTIONS",
           "abort_on_error=1:"
           "detect_leaks=0:"
           "symbolize=0:"
           "allocator_may_return_null=1",
           0);

    /* MSAN is tricky, because it doesn't support abort_on_error=1 at this
       point. So, we do this in a very hacky way. */

    setenv("MSAN_OPTIONS",
           "exit_code=" STRINGIFY(MSAN_ERROR) ":"
                                              "symbolize=0:"
                                              "abort_on_error=1:"
                                              "allocator_may_return_null=1:"
                                              "msan_track_origins=0",
           0);

    char *argv_list[] = {"./covtest.test", NULL};
    execv("./covtest.test", argv_list);
    cerr << "Fatal Error: Should not reach this point. \n\n\n";

    *(u32 *)trace_bits = EXEC_FAIL_SIG;
    exit(0);
  }

  /* Close the unneeded endpoints. */

  close(ctl_pipe[0]);
  close(st_pipe[1]);

  fsrv_ctl_fd = ctl_pipe[1];
  fsrv_st_fd = st_pipe[0];

  /* Wait for the fork server to come up, but don't wait too long. */

  it.it_value.tv_sec = ((exec_tmout * FORK_WAIT_MULT) / 1000);
  it.it_value.tv_usec = ((exec_tmout * FORK_WAIT_MULT) % 1000) * 1000;

  setitimer(ITIMER_REAL, &it, NULL);

  rlen = read(fsrv_st_fd, &status, 4);
  //  child_pid = status;
  //  assert(child_pid != -1);

  it.it_value.tv_sec = 0;
  it.it_value.tv_usec = 0;

  setitimer(ITIMER_REAL, &it, NULL);

  /* If we have a four-byte "hello" message from the server, we're all set.
     Otherwise, try to figure out what went wrong. */

  if (rlen == 4) {
    OKF("All right - fork server is up.");
    return;
  }

  //  if (child_timed_out)
  //    FATAL("Timeout while initializing fork server (adjusting -t may help)");

  if (waitpid(forksrv_pid, &status, 0) <= 0)
    PFATAL("waitpid() failed");

  if (WIFSIGNALED(status)) {

    if (mem_limit && mem_limit < 500) { // && uses_asan) {

      SAYF("\n" cLRD "[-] " cRST "Whoops, the target binary crashed suddenly, "
           "before receiving any input\n"
           "    from the fuzzer! Since it seems to be built with ASAN and you "
           "have a\n"
           "    restrictive memory limit configured, this is expected; please "
           "read\n"
           "    %s/notes_for_asan.txt for help.\n",
           doc_path);
    } else if (!mem_limit) {

      SAYF(
          "\n" cLRD "[-] " cRST "Whoops, the target binary crashed suddenly, "
          "before receiving any input\n"
          "    from the fuzzer! There are several probable explanations:\n\n"

          "    - The binary is just buggy and explodes entirely on its own. If "
          "so, you\n"
          "      need to fix the underlying problem or find a better "
          "replacement.\n\n"

#ifdef __APPLE__

          "    - On MacOS X, the semantics of fork() syscalls are non-standard "
          "and may\n"
          "      break afl-fuzz performance optimizations when running "
          "platform-specific\n"
          "      targets. To fix this, set AFL_NO_FORKSRV=1 in the "
          "environment.\n\n"

#endif /* __APPLE__ */

          "    - Less likely, there is a horrible bug in the fuzzer. If other "
          "options\n"
          "      fail, poke <lcamtuf@coredump.cx> for troubleshooting tips.\n");
    } else {

      SAYF("\n" cLRD "[-] " cRST "Whoops, the target binary crashed suddenly, "
           "before receiving any input\n"
           "    from the fuzzer! There are several probable explanations:\n\n"

           "    - The current memory limit (%s) is too restrictive, causing "
           "the\n"
           "      target to hit an OOM condition in the dynamic linker. Try "
           "bumping up\n"
           "      the limit with the -m setting in the command line. A simple "
           "way confirm\n"
           "      this diagnosis would be:\n\n"

#ifdef RLIMIT_AS
           "      ( ulimit -Sv $[%llu << 10]; /path/to/fuzzed_app )\n\n"
#else
           "      ( ulimit -Sd $[%llu << 10]; /path/to/fuzzed_app )\n\n"
#endif /* ^RLIMIT_AS */

           "      Tip: you can use http://jwilk.net/software/recidivm to "
           "quickly\n"
           "      estimate the required amount of virtual memory for the "
           "binary.\n\n"

           "    - The binary is just buggy and explodes entirely on its own. "
           "If so, you\n"
           "      need to fix the underlying problem or find a better "
           "replacement.\n\n"

#ifdef __APPLE__

           "    - On MacOS X, the semantics of fork() syscalls are "
           "non-standard and may\n"
           "      break afl-fuzz performance optimizations when running "
           "platform-specific\n"
           "      targets. To fix this, set AFL_NO_FORKSRV=1 in the "
           "environment.\n\n"

#endif /* __APPLE__ */

           "    - Less likely, there is a horrible bug in the fuzzer. If other "
           "options\n"
           "      fail, poke <lcamtuf@coredump.cx> for troubleshooting tips.\n"
           //           DMS(mem_limit << 20), mem_limit - 1
      );
    }

    FATAL("Fork server crashed with signal %d", WTERMSIG(status));
  }

  if (*(u32 *)trace_bits == EXEC_FAIL_SIG)
    FATAL("Unable to execute target application ('%s')", argv[0]);

  if (mem_limit && mem_limit < 500) { // && uses_asan) {

    SAYF("\n" cLRD "[-] " cRST "Hmm, looks like the target binary terminated "
         "before we could complete a\n"
         "    handshake with the injected code. Since it seems to be built "
         "with ASAN and\n"
         "    you have a restrictive memory limit configured, this is "
         "expected; please\n"
         "    read %s/notes_for_asan.txt for help.\n",
         doc_path);
  } else if (!mem_limit) {

    SAYF("\n" cLRD "[-] " cRST "Hmm, looks like the target binary terminated "
         "before we could complete a\n"
         "    handshake with the injected code. Perhaps there is a horrible "
         "bug in the\n"
         "    fuzzer. Poke <lcamtuf@coredump.cx> for troubleshooting tips.\n");
  } else {

    SAYF(
        "\n" cLRD "[-] " cRST "Hmm, looks like the target binary terminated "
        "before we could complete a\n"
        "    handshake with the injected code. There are %s probable "
        "explanations:\n\n"

        "%s"
        "    - The current memory limit (%s) is too restrictive, causing an "
        "OOM\n"
        "      fault in the dynamic linker. This can be fixed with the -m "
        "option. A\n"
        "      simple way to confirm the diagnosis may be:\n\n"

#ifdef RLIMIT_AS
        "      ( ulimit -Sv $[%llu << 10]; /path/to/fuzzed_app )\n\n"
#else
        "      ( ulimit -Sd $[%llu << 10]; /path/to/fuzzed_app )\n\n"
#endif /* ^RLIMIT_AS */

        "      Tip: you can use http://jwilk.net/software/recidivm to quickly\n"
        "      estimate the required amount of virtual memory for the "
        "binary.\n\n"

        "    - Less likely, there is a horrible bug in the fuzzer. If other "
        "options\n"
        "      fail, poke <lcamtuf@coredump.cx> for troubleshooting tips.\n",
        getenv(DEFER_ENV_VAR) ? "three" : "two",
        getenv(DEFER_ENV_VAR)
            ? "    - You are using deferred forkserver, but __AFL_INIT() is "
              "never\n"
              "      reached before the program terminates.\n\n"
            : ""
        //        DMS(mem_limit << 20), mem_limit - 1
    );
  }

  FATAL("Fork server handshake failed");
}

/* Main entry point */

int main(int argc, char **argv) {

  s32 opt;
  u8 mem_limit_given = 0, timeout_given = 0, qemu_mode = 0;
  char **use_argv;

  doc_path = access(DOC_PATH, F_OK) ? "docs" : DOC_PATH;

  SAYF(cCYA "afl-tmin " cBRI VERSION cRST " by <lcamtuf@google.com>\n");

  while ((opt = getopt(argc, argv, "+i:o:f:m:t:B:xeQV")) > 0)

    switch (opt) {

    case 'i':

      if (in_file)
        FATAL("Multiple -i options not supported");
      in_file = optarg;
      break;

    case 'o':

      if (out_file)
        FATAL("Multiple -o options not supported");
      out_file = optarg;
      break;

    case 'f':

      if (prog_in)
        FATAL("Multiple -f options not supported");
      use_stdin = 0;
      prog_in = optarg;
      break;

    case 'e':

      if (edges_only)
        FATAL("Multiple -e options not supported");
      edges_only = 1;
      break;

    case 'x':

      if (exit_crash)
        FATAL("Multiple -x options not supported");
      exit_crash = 1;
      break;

    case 'm': {

      u8 suffix = 'M';

      if (mem_limit_given)
        FATAL("Multiple -m options not supported");
      mem_limit_given = 1;

      if (!strcmp(optarg, "none")) {

        mem_limit = 0;
        break;
      }

      if (sscanf(optarg, "%llu%c", &mem_limit, &suffix) < 1 || optarg[0] == '-')
        FATAL("Bad syntax used for -m");

      switch (suffix) {

      case 'T':
        mem_limit *= 1024 * 1024;
        break;
      case 'G':
        mem_limit *= 1024;
        break;
      case 'k':
        mem_limit /= 1024;
        break;
      case 'M':
        break;

      default:
        FATAL("Unsupported suffix or bad syntax for -m");
      }

      if (mem_limit < 5)
        FATAL("Dangerously low value of -m");

      if (sizeof(rlim_t) == 4 && mem_limit > 2000)
        FATAL("Value of -m out of range on 32-bit systems");

    }

    break;

    case 't':

      if (timeout_given)
        FATAL("Multiple -t options not supported");
      timeout_given = 1;

      exec_tmout = atoi(optarg);

      if (exec_tmout < 10 || optarg[0] == '-')
        FATAL("Dangerously low value of -t");

      break;

    case 'Q':

      if (qemu_mode)
        FATAL("Multiple -Q options not supported");
      if (!mem_limit_given)
        mem_limit = MEM_LIMIT_QEMU;

      qemu_mode = 1;
      break;

    case 'B': /* load bitmap */

      /* This is a secret undocumented option! It is speculated to be useful
         if you have a baseline "boring" input file and another "interesting"
         file you want to minimize.

         You can dump a binary bitmap for the boring file using
         afl-showmap -b, and then load it into afl-tmin via -B. The minimizer
         will then minimize to preserve only the edges that are unique to
         the interesting input file, but ignoring everything from the
         original map.

         The option may be extended and made more official if it proves
         to be useful. */

      if (mask_bitmap)
        FATAL("Multiple -B options not supported");
      mask_bitmap = ck_alloc(MAP_SIZE);
      read_bitmap(optarg);
      break;

    case 'V': /* Show version number */

      /* Version number has been printed already, just quit. */
      exit(0);

    default:

      usage(argv[0]);
    }

  if (optind == argc || !in_file)
    usage(argv[0]);

  setup_shm();
  setup_signal_handlers();

  set_up_environment();

  find_binary(argv[optind]);
  detect_file_args(argv + optind);

  if (qemu_mode)
    use_argv = get_qemu_argv(argv[0], argv + optind, argc - optind);
  else
    use_argv = argv + optind;

  exact_mode = !!getenv("AFL_TMIN_EXACT");

  SAYF("\n");

  read_initial_file();

  init_forkserver(use_argv);

  ACTF("Performing dry run (mem limit = %llu MB, timeout = %u ms%s)...",
       mem_limit, exec_tmout, edges_only ? ", edges only" : "");

  u8 res;
  do {
    res = run_target(argv, in_data, in_len, 0);
  } while (!res);

  cerr << "\n\n\nFound the crashing test case. EXIT. \n\n\n";
  exit(0);

  if (child_timed_out)
    FATAL("Target binary times out (adjusting -t may help).");

  if (!crash_mode) {

    OKF("Program terminates normally, minimizing in " cCYA "instrumented" cRST
        " mode.");

    if (!anything_set())
      FATAL("No instrumentation detected.");

  } else {

    OKF("Program exits with a signal, minimizing in " cMGN "%scrash" cRST
        " mode.",
        exact_mode ? "EXACT " : "");
  }

  minimize(use_argv);

  ACTF("Writing output to '%s'...", out_file);

  unlink(prog_in);
  prog_in = NULL;

  // close(write_to_file(out_file, in_data, in_len));

  OKF("We're done here. Have a nice day!\n");

  exit(0);
}
