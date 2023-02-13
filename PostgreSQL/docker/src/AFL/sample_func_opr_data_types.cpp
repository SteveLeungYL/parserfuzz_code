// This file is used to run and sample function/operator signatures from the
// DBMS. Read all the function signatures from the func_type_lib and
// operator_type_lib, test them in the DBMS, and retrive the testing information
// into a JSON file.

#include <string>
#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>

#include "../include/data_type_signatures.h"

// Required for the PostgreSQL connection.
#include "libpq-fe.h"
#include "../include/utils.h"

using namespace std;

int bind_to_port = 5432;

enum SQLSTATUS
{
  kConnectFailed,
  kExecuteError,
  kServerCrash,
  kNormal,
  kTimeout,
  kSyntaxError,
  kSemanticError
};

struct POSTGRES_OUTPUT {
  string outputs = "";
  SQLSTATUS status;
};

static void exit_nicely(PGconn *conn) {
  PQfinish(conn);
  exit(1);
}

static void setting_failed(PGconn *conn) {
  cerr << "Unable to enter single row mode: " << PQerrorMessage(conn) << endl;
  exit_nicely(conn);
}

class PostgresClient
{
public:
  PostgresClient() : counter_(0) {}

  PGconn *connect()
  {
    string conninfo = "postgresql://localhost?port=" + to_string(bind_to_port) + "&dbname=x";
    return PQconnectdb(conninfo.c_str());
  }

  void disconnect(PGconn *conn)
  {
    PQfinish(conn);
    counter_++;
  }

  POSTGRES_OUTPUT execute(string cmd)
  {
    PGresult *res;
    POSTGRES_OUTPUT result;
    std::ostringstream outputStream;
    result.outputs = "";
    int first = 1;
    int nFields;
    int i, j;
    int execute_ok = 0;

    conn = connect();

    // if (PQstatus(conn) != CONNECTION_OK) {
    //   // disconnect(conn);
    //   conn = connect();
    if (PQstatus(conn) != CONNECTION_OK) {
      disconnect(conn);
      result.status = kConnectFailed;
      return result;
    }
    // }

    reset_database(conn);

    vector<string> cmd_vec = string_splitter(cmd, ";");
    vector<string> timeout_cmd_vec = {"set statement_timeout to 200; "};
    timeout_cmd_vec.insert(timeout_cmd_vec.end(), cmd_vec.begin(), cmd_vec.end());
    cmd_vec = timeout_cmd_vec;

    time_t begin_timer;
    time_t process_timer;
    bool is_timeout = false;
    time(&begin_timer);
    // Loop through the cmd_vec.
    for (string& cur_cmd : cmd_vec) {
      cur_cmd += "; ";
      /* Send our statements off to the server. */
      if (!PQsendQuery(conn, cur_cmd.c_str())) {
        cerr << "Sending statements to server failed: " << PQerrorMessage(conn) << endl;
        // exit_nicely(conn);
      }

      if (check_status(conn) == false) {
        cerr << "In func execute(), we get kServerCrash. \n";
        result.status = kServerCrash;
        return result;
      }

      /* We want results row-by-row. */
      if (!PQsetSingleRowMode(conn)) {
        setting_failed(conn);
      }

      /* Loop through the results of our statements. */
      while ( !is_timeout  &&  (res = PQgetResult(conn)) && res != NULL ) {
        switch (PQresultStatus(res)) {
        case PGRES_COMMAND_OK: {
          /* a query command that doesn't return
              * anything was executed properly by the
              * backend */
          break;
        }
        case PGRES_TUPLES_OK:  {/* No more rows from current query. */
          /* We want the next statement's results row-by-row also. */
          if (!PQsetSingleRowMode(conn)) {
            PQclear(res);
            setting_failed(conn);
          }
          first = 1;
          break;
        }
        case PGRES_SINGLE_TUPLE: {
          if (first) {
            /* Produce a "nice" header" */
            // cout << "-----------------------------"
            //         "-----------------------------"
            //         << endl
            //         << "Results of statement number:" << endl;
            /* print out the attribute names */
            nFields = PQnfields(res);
            // for (i = 0; i < nFields; i++) {
            //   cout << "PQfname: " << PQfname(res, i) << endl;
            //   outputStream << PQfname(res, i) << " ";
            // }
            // outputStream << endl;
            first = 0;
          }
          /* print out the row */
          for (j = 0; j < nFields; j++) {
            // cout << "PQgetvalue: " << PQgetvalue(res, 0, j) << endl;
            // outputStream << PQgetvalue(res, 0, j) << " ";
            const char* res_char = PQgetvalue(res, 0, j);
            if (res_char != NULL && !PQgetisnull(res, 0, j)) {
              result.outputs += string(res_char) + " ";
            }
            time(&process_timer);
            double run_seconds = difftime(process_timer, begin_timer);
            // cerr << "Getting timeout run_seconds: " << run_seconds << "\n\n\n";
            if (run_seconds > 2.0) {
              result.outputs = "Error: Execution is Timeout. ";
              PGcancel* cancel_conn = PQgetCancel(conn);
              char errbuf[512];
              PQcancel(cancel_conn, errbuf, 512);
              PQfreeCancel(cancel_conn);
              is_timeout = true;
              break;
            }
          }
          result.outputs += "\n";
          // outputStream << endl;
          // cerr << "result.outputs is: " << result.outputs << "\n\n\n";
          // result.outputs = outputStream.str();
          // execute_ok += 1;
          break;
        }
        case PGRES_FATAL_ERROR: {
          // disconnect(conn);
          result.status = kExecuteError;

          string error_msg = PQerrorMessage(conn);
          result.outputs += error_msg + "\n";
        }
        default: {
          /* Always call PQgetResult until it returns null, even on
            * error. */
          // cerr << "Query execution failed: " << PQerrorMessage(conn) << endl;
          // cerr << "PQresultStatus: " << PQresultStatus(res) << endl;
          // postgre_execute_error += 1;
        }
        } // switch
        PQclear(res);
      }  // while ( (res = PQgetResult(conn))  && !is_timeout)
      if (is_timeout) {  // Timeout, ignore the following SQL commands.
        break;
      }
    } // for (string& cur_cmd : cmd_vec)

    disconnect(conn);
    result.status = kNormal;

    // getchar();
    return result;
  }

  void reset_database(PGconn *conn)
  {
    PGresult *res = PQexec(conn, "SET client_min_messages TO WARNING;DROP SCHEMA public CASCADE; CREATE SCHEMA public;");
    PQclear(res);
  }

  void drop_database(PGconn *conn)
  {
    if (counter_ % 2 == 0){
      PGresult *res = PQexec(conn, "DROP DATABASE IF EXISTS test;");
      PQclear(res);
    }
    else {
      PGresult *res = PQexec(conn, "DROP DATABASE IF EXISTS test2;");
      PQclear(res);
    }
  }

  void create_database(PGconn *conn)
  {
    if (counter_ % 2 == 0) {
      PGresult *res = PQexec(conn, "CREATE DATABASE test;");
      PQclear(res);
    }
    else {
      PGresult *res = PQexec(conn, "CREATE DATABASE test2;");
      PQclear(res);
    }
  }

  bool check_status(PGconn *conn)
  {
    auto res = PQstatus(conn);
    if (res == CONNECTION_OK)
      return true;

    return false;
  }

  char *get_next_database_name()
  {
    if (counter_ % 2 == 0)
      return "test2";

    return "test";
  }

private:
  unsigned counter_; //odd for "test", even for "test2"
  PGconn *conn;
};

PostgresClient g_psql_client;

char* FUNC_TYPE_LIB_PATH = "./func_type_lib";

void init_all_func_sig(vector<FuncSig>& v_func_sig) {

  std::ifstream t(FUNC_TYPE_LIB_PATH);
  std::stringstream buffer;
  buffer << t.rdbuf();

  string func_type_str = buffer.str();

  vector<string> func_type_split = string_splitter(func_type_str, "\n");

  for (int i = 2; i < func_type_split.size() - 1; i++) {
    // Skip the first 2 lines and the last line.
    // The first two lines are name and separators, the last line is the row number

    bool is_skip = false;

    vector<string> line_split = string_splitter(func_type_split[i], "|");
    if (line_split.size() != 3) {
      cerr << "\n\n\nERROR: For line break for line: " << func_type_split[i]
           << ", cannot split to three parts. \n\n\n";
      assert(false);
    }
    string func_sig_str = line_split[0];
    trim_string(func_sig_str);
    string ret_type_str =  line_split[1];
    trim_string(ret_type_str);
    string func_category_flag = line_split[2];
    trim_string(func_category_flag);

    FuncSig cur_func_sig;

    vector<string> tmp_line_break;
    string tmp_str;
    // Handle the func_sig_str
    tmp_line_break = string_splitter(func_sig_str, "(");
    if (tmp_line_break.size() != 2) {
      cerr << "\n\n\nERROR: for func_sig_str, the tmp_line_break is not at size 2. Str: "
           << func_sig_str << " \n\n\n";
      assert(false);
    }
    tmp_str = tmp_line_break.front();
    cur_func_sig.set_func_name(tmp_str);

    // Handle the function argument list.
    // remove right bracket ")".
    tmp_str = tmp_line_break[1];
    tmp_line_break = string_splitter(tmp_str, ")");
    if (tmp_line_break.size() != 2) {
      cerr << "\n\n\nERROR: for func_sig_str, the tmp_line_break is not at size 2. Str: "
           << tmp_str << " \n\n\n";
      assert(false);
    }
    tmp_str = tmp_line_break.front();

    // separate the function arguments.
    tmp_line_break = string_splitter(tmp_str, ",");
    for (string cur_arg_str: tmp_line_break) {
      if (cur_arg_str == "") {
        continue;
      }
      DataType cur_arg_type(cur_arg_str);
      if (cur_arg_type.get_data_type_enum() == kTYPEUNKNOWN) {
        is_skip = true;
        cerr << "\n\n\nSkip function signature: \n" << func_type_split[i]
             << "\n because arguments parsing failed. \n\n\n";
        break;
      }
      cur_func_sig.push_arg_type(cur_arg_type);
    }

    if (is_skip) {
      continue;
    }

    // And then, parse the return type string.
    DataType ret_type(ret_type_str);
    if (ret_type.get_data_type_enum() == kTYPEUNKNOWN) {
      is_skip = true;
      cerr << "\n\n\nSkip function signature: \n" << func_type_split[i]
           << "\n because arguments parsing failed. \n\n\n";
      continue;
    }
    cur_func_sig.set_ret_type(ret_type);

    // At last, identify the function type. Normal, Aggregate or Window function.
    cur_func_sig.set_func_catalog(func_category_flag);

    v_func_sig.push_back(cur_func_sig);
  }

  return;
}

int main() {

  vector<FuncSig> v_func_sig;
  init_all_func_sig(v_func_sig);

  return 0;
}
