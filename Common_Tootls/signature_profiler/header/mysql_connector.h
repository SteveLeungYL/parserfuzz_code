#include <mysql/mysql.h>
#include <mysql/mysqld_error.h>
#include <mysql/errmsg.h>

#include <string>
#include <vector>
#include <random>
#include <sstream>
#include <regex>
#include <iostream>
#include <mutex>
#include <thread>
#include <unistd.h>

using namespace std;

string socket_path = "/tmp/mysql_0.sock";
uint bind_to_port = 5432;

std::mutex timeout_mutex;
bool is_timeout = false;

static uint exec_tmout = 1000;
unsigned long timeout_id = 0;

deque<char*> g_previous_input;

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

class MysqlClient
{
public:
  MysqlClient(const char *host, char *user_name, char *passwd) : host_(host), user_name_(user_name), passwd_(passwd), counter_(0) {}

  bool connect()
  {
    string dbname;

    m_ = mysql_init(m_);

    if (m_ == NULL) {
      return false;
    }

    dbname = "test";
    if (mysql_real_connect(m_, NULL, "root", "", dbname.c_str(), bind_to_port, socket_path.c_str(), 0) == NULL)
    {
      fprintf(stderr, "Connection error1 \n", mysql_errno(m_), mysql_error(m_));
      disconnect();
      counter_++;
      return false;
    }
    
    return true;
  }

  void disconnect()
  {
    mysql_close(m_);
    m_ = NULL;
  }

  bool fix_database()
  {
    MYSQL tmp_m;

    database_id += 1;
    if (mysql_init(&tmp_m) == NULL)
    {
      mysql_close(&tmp_m);
      return false;
    }

    if (mysql_real_connect(&tmp_m, NULL, "root", "", "test_init", bind_to_port, socket_path.c_str(), 0) == NULL)
    {
      fprintf(stderr, "Connection error3 \n", mysql_errno(&tmp_m), mysql_error(&tmp_m));
      mysql_close(&tmp_m);
      return false;
    }
    bool is_error = false;

    vector<string> v_cmd = {"SET GLOBAL TRANSACTION READ WRITE", "SET SESSION TRANSACTION READ WRITE", "RESET PERSIST", "RESET MASTER", "ALTER USER 'root'@'localhost' WITH MAX_USER_CONNECTIONS 0;", "DROP DATABASE IF EXISTS test", "CREATE DATABASE IF NOT EXISTS test", "USE test", "SELECT 'Successful'"};
    for (string cmd : v_cmd) {
      if(mysql_real_query(&tmp_m, cmd.c_str(), cmd.size()))  {
        is_error = true;
      }
      clean_up_connection(&tmp_m);
    }

    mysql_close(&tmp_m);

    return !is_error;
  }

  SQLSTATUS clean_up_connection(MYSQL *mm)
  {
    int res = -1;
    do
    {
      auto q_result = mysql_store_result(mm);
      if (q_result)
        mysql_free_result(q_result);
    } while ((res = mysql_next_result(mm)) == 0);

    if (res != -1)
    {
      if (mysql_errno(mm) == 1064)
      {
        return kSyntaxError;
      }
      else
      {
        return kSemanticError;
      }
    }
    return kNormal;
  }

  string get_rand_on_off_string()
  {
    std::random_device dev;
    std::mt19937 generator(dev());
    std::uniform_int_distribution<std::mt19937::result_type> distribution(0, 1);
    if (distribution(generator))
    {
      return "on";
    }
    else
    {
      return "off";
    }
  }

  int retrieve_query_results_count(MYSQL &m_)
  {
    MYSQL_ROW row;
    int result_count = 0;
    int status = 0;
    MYSQL_RES *result;
    do
    {
      /* did current statement return data? */
      result = mysql_store_result(&m_);
      if (result)
      {
        while ((row = mysql_fetch_row(result)) != NULL)
          result_count++;
      }
      /* more results? -1 = no, >0 = error, 0 = yes (keep looping) */
      if ((status = mysql_next_result(&m_)) > 0)
        break;
    } while (status == 0);

    return result_count;
  }

  string retrieve_query_results(MYSQL* m_, string cur_cmd_str)
  {
    MYSQL_ROW row;
    // string result_string = ""
    stringstream result_string_stream;
    int status = 0;
    MYSQL_RES *result;

    do
    {
      /* did current statement return data? */
      result = mysql_store_result(m_);
      // cerr << "is result empty? " << result << "\n\n\n";
      if (result)
      {
        /* yes; process rows and free the result set */
        while ((row = mysql_fetch_row(result)) != NULL)
        {
          for (int i = 0; i < mysql_num_fields(result); i++)
          {
            // cerr << "Getting row: " << row[i] << "\n\n\n";
            result_string_stream << row[i];
          }
        }
        // cerr << "Returned all rows " << "\n\n\n";
      }
      else /* no result set or error */
      {
        // cerr << "No results get!\n";
        if (mysql_field_count(m_) == 0)
        {
          // printf("%lld rows affected\n", mysql_affected_rows(m_));
        } else if (mysql_field_count(m_) != 0) {
          // cerr << "Could not retrieve result set\n";
          // break;
        }
      }
      mysql_free_result(result);
      /* more results? -1 = no, >0 = error, 0 = yes (keep looping) */
      if ((status = mysql_next_result(m_)) > 0) {
        // cerr << "Could not execute statement. \n\n\n";
        // break;
      }
      if ((status = mysql_next_result(m_)) == -1) {
        // cerr << "No more results. \n\n\n";
        break;
      }
      // cerr << "Could not execute statement\n";
    } while (status == 0);

    // cerr << "Outputing MySQL message: \nQuery: " << cur_cmd_str << "\nRes: " << result_string_stream.str() << "\n";
    // if (mysql_errno(m_)) {
    //   cerr << "Error message: " << mysql_error(m_) << "\n";
    // }
    // cerr << "\n\n";

    string ret_str;
    if (mysql_errno(m_)) {
      ret_str = string(mysql_error(m_)) + "  " + result_string_stream.str();
    } else {
      ret_str = result_string_stream.str();
    }
    return ret_str;
  }

  vector<string> string_splitter(string input_string, string delimiter_re = "\n")
  {
    size_t pos = 0;
    string token;
    std::regex re(delimiter_re);
    std::sregex_token_iterator first{input_string.begin(), input_string.end(), re, -1}, last; //the '-1' is what makes the regex split (-1 := what was not matched)
    vector<string> split_string{first, last};

    return split_string;
  }

  static bool terminate_query(unsigned long process_id) {
    MYSQL tmp_m;
    if (mysql_init(&tmp_m) == NULL)
    {
      mysql_close(&tmp_m);
      return false;
    }

    // cerr << "Using socket: " << socket_path << "\n\n\n";
    if (mysql_real_connect(&tmp_m, NULL, "root", "", "test_init", bind_to_port, socket_path.c_str(), 0) == NULL)
    {
      fprintf(stderr, "Connection error5 \n", mysql_errno(&tmp_m), mysql_error(&tmp_m));
      mysql_close(&tmp_m);
      return false;
    }
    string cmd = "KILL " + to_string(process_id);
    mysql_real_query(&tmp_m, cmd.c_str(), cmd.size());
    // cerr << "Terminate_database results: "  << retrieve_query_results(&tmp_m) << "\n\n\n";

    mysql_close(&tmp_m);
    std::cout << "Timeout!!! Kill query successful. \n\n\n";
    // sleep(1);
    return true;
  }

  static void timeout_query(unsigned long process_id, unsigned long cur_timeout_id) {
    std::this_thread::sleep_for(std::chrono::milliseconds(exec_tmout));

    timeout_mutex.lock();

    // The previous execution has already finished. No timeout. 
    if (timeout_id != cur_timeout_id) {
      timeout_mutex.unlock();
      return;
    }

    // The prvious execution timeout. Kill it!
    is_timeout = true;

    timeout_mutex.unlock();

    if (is_timeout) {
      terminate_query(process_id);
    }

    // cerr << "\n\n\nQuery terminated!!!!\n\n\n";
  }

  SQLSTATUS execute(const char *cmd, string& res_str)
  {
    // fix_database();

    auto conn = connect();

    if(!conn){
      string previous_inputs = "";
      for(auto i: g_previous_input) previous_inputs += string(i) + "\n\n";
      previous_inputs += "-------------\n\n";
      //write(crash_fd, previous_inputs.c_str(), previous_inputs.size());  
    }
    
    int retry_time = 0;
    while(!conn){
      //cout << "reconnecting..." << endl;
      std::this_thread::sleep_for(std::chrono::milliseconds(30));
      conn = connect();
      if(!conn)
        fix_database();
    }
    //cout << "connect succeed!" << endl;

    res_str = "";

    if( !reset_database() ) { // Return true for no error, false for errors. 
      res_str += "Reset database ERROR!!!\n\n\n";
    }

    string cmd_str = cmd;
    std::replace(cmd_str.begin(), cmd_str.end(), '\n', ' ');

    /* For debug purpose */
    // cmd_str = "SELECT 'Test_ID " + to_string(test_id++) + "';" + cmd_str;

    vector<string> v_cmd_str = string_splitter(cmd_str, ";");

    // v_cmd_str = {"BEGIN; ", "create table v0(v1 text)", "COMMIT;"};

    SQLSTATUS correctness;
    int server_response;

    timeout_mutex.lock();
    is_timeout = false;
    timeout_mutex.unlock();

    std::thread(timeout_query, m_->thread_id, timeout_id).detach();

    bool is_mutate_error = false;

    bool is_oracle_select = false;

    for (string cur_cmd_str : v_cmd_str) {

      server_response = mysql_real_query(m_, cur_cmd_str.c_str(), cur_cmd_str.length());
      res_str += retrieve_query_results(m_, cur_cmd_str) + "\n";
      correctness = clean_up_connection(m_);

      if (cur_cmd_str.find("BEGIN VERI 0") != string::npos || cur_cmd_str.find("BEGIN VERI 1") != string::npos ) {
        is_oracle_select = true;
      } else {
        is_oracle_select = false;
      }

      if (server_response == CR_SERVER_LOST) {
        cerr << "Server Lost or Server Crashes! \n\n\n";
        break;
      }

    }

    /* For debug purpose */
    if (res_str.find("Test_ID") == string::npos) {
      cerr << "RESULT NOT RETURN CORRECTLY!\n\n\ncmd_str: " << cmd_str << "\n\n\nRes: " << res_str << "\n\n\n";
    }

    if(server_response == CR_SERVER_LOST || server_response == CR_SERVER_GONE_ERROR){
      disconnect();
      return kServerCrash;
    }

    auto res = kNormal;
    // res = correctness;  

    auto check_res = check_server_alive();
    if(check_res == false){
      disconnect();
      sleep(2); // waiting for server to be up again
      return kServerCrash;
    }

    timeout_mutex.lock();
    timeout_id++;
    if (is_timeout) {
      res = kTimeout;
    }
    is_timeout = false;
    timeout_mutex.unlock();

    if (is_mutate_error) {
      res = kSyntaxError;
    }

    counter_++;
    disconnect();
    return res;

  }

  bool check_server_alive()
  {
    MYSQL tmp_m;

    if (mysql_init(&tmp_m) == NULL)
    {
      mysql_close(&tmp_m);
      return false;
    }
    if (mysql_real_connect(&tmp_m, NULL, "root", "", "test_init", bind_to_port, socket_path.c_str(), CLIENT_MULTI_STATEMENTS) == NULL)
    {
      fprintf(stderr, "Connection error2 \n", mysql_errno(&tmp_m), mysql_error(&tmp_m));
      mysql_close(&tmp_m);
      return false;
    }
    mysql_close(&tmp_m);
    return true;
  }

  int reset_database()
  {
    MYSQL tmp_m;

    database_id += 1;
    if (mysql_init(&tmp_m) == NULL)
    {
      mysql_close(&tmp_m);
      return 0;
    }
    if (mysql_real_connect(&tmp_m, NULL, "root", "", "test_sqlright1", bind_to_port, socket_path.c_str(), 0) == NULL)
    {
      fprintf(stderr, "Connection error4 \n", mysql_errno(&tmp_m), mysql_error(&tmp_m));
      mysql_close(&tmp_m);
      return 0;
    }

    bool is_error = false;
    vector<string> v_cmd = {"SET GLOBAL TRANSACTION READ WRITE", "SET SESSION TRANSACTION READ WRITE", "RESET PERSIST", "RESET MASTER", "ALTER USER 'root'@'localhost' WITH MAX_USER_CONNECTIONS 0;", "DROP DATABASE IF EXISTS test_sqlright1", "CREATE DATABASE IF NOT EXISTS test_sqlright1", "USE test_sqlright1", "SELECT 'Successful'"};
    for (string cmd : v_cmd) {
      if(mysql_real_query(&tmp_m, cmd.c_str(), cmd.size()))  {
        is_error = true;
      }
      // cerr << "reset_database results: "  << retrieve_query_results(&tmp_m, cmd) << "\n\n\n";
      retrieve_query_results(m_, "");
      clean_up_connection(&tmp_m);
    }

    mysql_close(&tmp_m);
    return !is_error;
  }

  char *get_next_database_name()
  {
    if (counter_ % 2 == 0)
      return "test2";

    return "test";
  }

private:
  unsigned int database_id = 1;
  MYSQL* m_;
  char *host_;
  //string db_name_;
  char *user_name_;
  char *passwd_;
  bool is_first_time;
  unsigned counter_; //odd for "test", even for "test2"

};

