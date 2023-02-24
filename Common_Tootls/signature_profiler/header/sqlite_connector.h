#ifndef __SQLITE_CONNECTOR_H__
#define __SQLITE_CONNECTOR_H__
#include <string>
#include <vector>
#include <iostream>
#include <fstream>
#include <sstream>
#include <unistd.h>
#include <cassert>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/wait.h>

#include "utils.h"

using namespace std;

enum SQLSTATUS
{
  kNormal,
  kServerCrash,
  kTimeout,
  kSyntaxError,
  kSemanticError,
  kOtherError
};

class SQLiteClient {

private:
  int in_fd, out_fd;
  string fn_in, fn_out, target_path;

  void write_to_testcase(const string& cmd_str) {
    lseek(in_fd, 0, SEEK_SET);
    write(in_fd, cmd_str.c_str(), cmd_str.size() + 1);
    lseek(in_fd, 0, SEEK_SET);
  }

  void setup_stdio_file(void) {

    pid_t pid = getpid();
    fn_in = "./.cur_input_" + to_string(pid);

    in_fd = shm_open(fn_in.c_str(), O_RDWR | O_CREAT | O_EXCL, 0640);

    fn_out = "./.cur_output";

    out_fd = open(fn_out.c_str(), O_RDWR | O_CREAT | O_EXCL | O_TRUNC, 0640);

    if (in_fd < 0) {
      cerr << "\n\n\nERROR: Unable to create " << fn_in << "\n\n\n";
      assert(false);
      return;
    }
    if (out_fd < 0) {
      cerr << "\n\n\nERROR: Unable to create " << fn_out << "\n\n\n";
      assert(false);
      return;
    }
  }

public:
  SQLSTATUS run_target(string cmd_str, int timeout, string& res_str) {

    write_to_testcase(cmd_str);

    int child_pid = fork();

    if (child_pid < 0) {
      cerr << "\n\n\nERROR: fork error\n\n\n";
      assert(false);
      return kOtherError;
    }

    if (!child_pid) {
      // Child SQLite process.
      setsid();
      dup2(out_fd, 1);
      dup2(out_fd, 2);
      dup2(in_fd, 0);

      close(out_fd);
      close(in_fd);

      char * argv[] = {(char*)"./sqlite3"};
      execv(target_path.c_str(), argv);

      exit(0);
      
    }

    int status = 0;
    // Parent process.
    if (waitpid(child_pid, &status, 0) <= 0) {
      cerr << "\n\n\nERROR: waitpid() failed\n\n\n";
      assert(false);

      exit(0);
    }

    std::ifstream t(fn_out);
    std::stringstream buffer;
    buffer << t.rdbuf();

    res_str = buffer.str();

    return kNormal;
  }

  SQLiteClient(): in_fd(-1), out_fd(-1), target_path("./sqlite3") {
    setup_stdio_file();
  }

  SQLiteClient(string target_path_in): in_fd(-1), out_fd(-1), target_path(target_path_in) {
    setup_stdio_file();
  }

  ~SQLiteClient() {
    close(in_fd);
    close(out_fd);
  }

};

#endif


