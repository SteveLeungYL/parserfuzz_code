//
// Created by Yu Liang on 2/13/23.
//

#ifndef SRC_POSTGRES_CONNECTOR_H
#define SRC_POSTGRES_CONNECTOR_H

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


#endif // SRC_POSTGRES_CONNECTOR_H
