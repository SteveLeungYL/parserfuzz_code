#include <iostream>
#include "./sqlite_tlp.h"
#include "../include/utils.h"
#include "../include/mutator.h"

#include <string>
#include <algorithm>

void SQL_TLP::append_ori_valid_stmts(string& query_str, int valid_max_num = 10) {


  int trial = 0;
  int num_norec = 0;
  int max_trial = valid_max_num * 3;  // For each norec select stmt, we have on average 3 chances to append the stmt and check. 

  while (num_norec < valid_max_num){

    if (trial++ >= max_trial) // Give on average 3 chances per select stmts.  
      break;

    string new_norec_stmts = g_mutator->get_random_mutated_valid_stmt();
    if (new_norec_stmts == "") continue;
    ensure_semicolon_at_query_end(new_norec_stmts);

    query_str += new_norec_stmts;

    num_norec++;
  }

  return;
}

int SQL_TLP::count_valid_stmts(const string& input){
  int norec_select_count = 0;
  vector<string> queries_vector = string_splitter(input, ";");
  for (string &query : queries_vector) 
    if (this->is_oracle_valid_stmt(query))
      norec_select_count++;
  return norec_select_count;
}


bool SQL_TLP::is_oracle_valid_stmt(const string& query){
  if (
        ((query.find("SELECT")) != std::string::npos || (query.find("select")) != std::string::npos) && // This is a SELECT stmt. Not INSERT or UPDATE stmts.
        ((query.find("SELECT")) <= 5 || (query.find("select")) <= 5) &&
        ((query.find("INSERT")) == std::string::npos && (query.find("insert")) == std::string::npos) &&
        ((query.find("UPDATE")) == std::string::npos && (query.find("update")) == std::string::npos)  &&
        ((query.find("FROM")) != std::string::npos || (query.find("from")) != std::string::npos)
    ) return true;
    return false;
}

bool SQL_TLP::mark_all_valid_node(vector<IR *> &v_ir_collector)
{
    bool is_mark_successfully = false;

    IR *root = v_ir_collector[v_ir_collector.size() - 1];
    IR *par_ir = nullptr;
    IR *par_par_ir = nullptr;
    IR *par_par_par_ir = nullptr; // If we find the correct selectnoparen, this should be the statementlist.
    for (auto ir : v_ir_collector){
        if (ir != nullptr) ir -> is_norec_select_fixed = false;
    }
    for (auto ir : v_ir_collector)
    {
        if (ir != nullptr && ir->type_ == kSelectCore)
        {
            par_ir = root->locate_parent(ir);
            if (par_ir != nullptr && par_ir->type_ == kSelectStatement)
            {
                par_par_ir = root->locate_parent(par_ir);
                if (par_par_ir != nullptr && par_par_ir->type_ == kStatement)
                {
                    par_par_par_ir = root->locate_parent(par_par_ir);
                    if (par_par_par_ir != nullptr && par_par_par_ir->type_ == kStatementList)
                    {
                        string query = g_mutator->extract_struct(ir);
                        if (   !(this->is_oracle_valid_stmt(query))   )  continue;  // Not norec compatible. Jump to the next ir.
                        query.clear();
                        is_mark_successfully = this->mark_node_valid(ir);
                        // cerr << "\n\n\nThe marked norec ir is: " << this->extract_struct(ir) << " \n\n\n";
                        par_ir -> is_norec_select_fixed = true;
                        par_par_ir -> is_norec_select_fixed = true;
                        par_par_par_ir -> is_norec_select_fixed = true;
                    }
                }
            }
        }
    }

    return is_mark_successfully;
}

void SQL_TLP::rewrite_valid_stmt_from_ori(string& query, string& rew_1, string& rew_2, string& rew_3)
{
  // vector<string> stmt_vector = string_splitter(query, "where|WHERE|SELECT|select|FROM|from");

  while (query[0] == ' ' || query[0] == '\n' || query[0] == '\t')
  { // Delete duplicated whitespace at the beginning.
    query = query.substr(1, query.size() - 1);
  }

  size_t select_position = 0;
  size_t from_position = -1;
  size_t where_position = -1;
  size_t group_by_position = -1;
  size_t order_by_position = -1;

  vector<size_t> op_lp_v;
  vector<size_t> op_rp_v;

  size_t tmp1 = 0, tmp2 = 0;
  while ((tmp1 = query.find("(", tmp1)) && tmp1 != string::npos)
  {
    op_lp_v.push_back(tmp1);
    tmp1++;
    if (tmp1 == query.size())
    {
      break;
    }
  }
  while ((tmp2 = query.find(")", tmp2)) && tmp2 != string::npos)
  {
    op_rp_v.push_back(tmp2);
    tmp2++;
    if (tmp2 == query.size())
    {
      break;
    }
  }

  if (op_lp_v.size() != op_rp_v.size())
  { // The symbol of '(' and ')' is not matched. Ignore all the '()' symbol.
    op_lp_v.clear();
    op_rp_v.clear();
  }

  for (int i = 0; i < op_lp_v.size(); i++)
  { // The symbol of '(' and ')' is not matched. Ignore all the '()' symbol.
    if (op_lp_v[i] > op_rp_v[i])
    {
      op_lp_v.clear();
      op_rp_v.clear();
    }
  }

  tmp1 = -1;
  tmp2 = -1;

  tmp1 = query.find("SELECT", 0); // The first SELECT statement will always be the correct outter most SELECT statement. Pick its pos.
  tmp2 = query.find("select", 0);
  if (tmp1 != string::npos)
  {
    select_position = tmp1;
  }
  if (tmp2 != string::npos && tmp2 < tmp1)
  {
    select_position = tmp2;
  }

  tmp1 = 0;
  tmp2 = 0;
  from_position = -1;

  do
  {
    if (tmp1 != string::npos)
      tmp1 = query.find("FROM", tmp1 + 4);
    if (tmp2 != string::npos)
      tmp2 = query.find("from", tmp2 + 4);

    if (tmp1 != string::npos)
    {
      bool is_ignore = false;
      for (int i = 0; i < op_lp_v.size(); i++)
      {
        if (tmp1 > op_lp_v[i] && tmp1 < op_rp_v[i])
        {
          is_ignore = true;
          break;
        }
      }
      if (!is_ignore)
      {
        from_position = tmp1;
        break; // from_position is found. Break the outter do...while loop.
      }
    }

    if (tmp2 != string::npos)
    {
      bool is_ignore = false;
      for (int i = 0; i < op_lp_v.size(); i++)
      {
        if (tmp2 > op_lp_v[i] && tmp2 < op_rp_v[i])
        {
          is_ignore = true;
          break;
        }
      }
      if (!is_ignore)
      {
        from_position = tmp2;
        break; // from_position is found. Break the outter do...while loop.
      }
    }

  } while (tmp1 != string::npos || tmp2 != string::npos);

  tmp1 = 0;
  tmp2 = 0;
  where_position = -1;

  do
  {
    if (tmp1 != string::npos)
      tmp1 = query.find("WHERE", tmp1 + 5);
    if (tmp2 != string::npos)
      tmp2 = query.find("where", tmp2 + 5);

    if (tmp1 != string::npos)
    {
      bool is_ignore = false;
      for (int i = 0; i < op_lp_v.size(); i++)
      {
        if (tmp1 > op_lp_v[i] && tmp1 < op_rp_v[i])
        {
          is_ignore = true;
          break;
        }
      }
      if (!is_ignore)
      {
        where_position = tmp1;
        break; // where_position is found. Break the outter do...while loop.
      }
    }

    if (tmp2 != string::npos)
    {
      bool is_ignore = false;
      for (int i = 0; i < op_lp_v.size(); i++)
      {
        if (tmp2 > op_lp_v[i] && tmp2 < op_rp_v[i])
        {
          is_ignore = true;
          break;
        }
      }
      if (!is_ignore)
      {
        where_position = tmp2;
        break; // where_position is found. Break the outter do...while loop.
      }
    }

  } while (tmp1 != string::npos || tmp2 != string::npos);

  /*** Taking care of GROUP BY stmt.   ***/
  tmp1 = -1, tmp2 = -1;
  size_t tmp = 0;
  while ((tmp = query.find("GROUP BY", tmp + 8)) &&
         (tmp != string::npos))
  {
    bool is_ignore = false;
    for (int i = 0; i < op_lp_v.size(); i++)
    {
      if (tmp > op_lp_v[i] && tmp < op_rp_v[i])
      {
        is_ignore = true;
        break;
      }
    }
    if (!is_ignore)
    {
      tmp1 = tmp;
    }
  } // The last GROUP BY statement outside the bracket will always be the correct outter most GROUP BY statement. Pick its pos.

  tmp = -8;
  while ((tmp = query.find("group by", tmp + 8)) &&
         (tmp != string::npos))
  {
    bool is_ignore = false;
    for (int i = 0; i < op_lp_v.size(); i++)
    {
      if (tmp > op_lp_v[i] && tmp < op_rp_v[i])
      {
        is_ignore = true;
        break;
      }
    }
    if (!is_ignore)
    {
      tmp2 = tmp;
    }
  } // The last GROUP BY statement outside the bracket will always be the correct outter most GROUP BY statement. Pick its pos.
  if (tmp1 != string::npos)
  {
    group_by_position = tmp1;
  }
  if (tmp2 != string::npos && tmp2 > tmp1)
  {
    group_by_position = tmp2;
  }

  /*** Taking care of ORDER BY stmt.   ***/
  tmp1 = -1, tmp2 = -1;
  tmp = -8;
  while ((tmp = query.find("ORDER BY", tmp + 8)) &&
         (tmp != string::npos))
  {
    bool is_ignore = false;
    for (int i = 0; i < op_lp_v.size(); i++)
    {
      if (tmp > op_lp_v[i] && tmp < op_rp_v[i])
      {
        is_ignore = true;
        break;
      }
    }
    if (!is_ignore)
    {
      tmp1 = tmp;
    }
  } // The last ORDER BY statement outside the bracket will always be the correct outter most GROUP BY statement. Pick its pos.
  tmp = -8;
  while ((tmp = query.find("order by", tmp + 8)) &&
         (tmp != string::npos))
  {
    bool is_ignore = false;
    for (int i = 0; i < op_lp_v.size(); i++)
    {
      if (tmp > op_lp_v[i] && tmp < op_rp_v[i])
      {
        is_ignore = true;
        break;
      }
    }
    if (!is_ignore)
    {
      tmp2 = tmp;
    }
  } // The last order by statement outside the bracket will always be the correct outter most GROUP BY statement. Pick its pos.
  if (tmp1 != string::npos)
  {
    order_by_position = tmp1;
  }
  if (tmp2 != string::npos && tmp2 > tmp1)
  {
    order_by_position = tmp2;
  }

  size_t extra_stmt_position = -1;
  if (group_by_position != string::npos && order_by_position != string::npos)
    extra_stmt_position = ((group_by_position < order_by_position) ? group_by_position : order_by_position);
  else if (group_by_position != string::npos)
    extra_stmt_position = group_by_position;
  else if (order_by_position != string::npos)
    extra_stmt_position = order_by_position;

  string before_select_stmt;
  string select_stmt;
  string from_stmt;
  string where_stmt;
  string extra_stmt;

  before_select_stmt = query.substr(0, select_position - 0);

  select_stmt = query.substr(select_position + 6, from_position - select_position - 6);

  if (from_position == -1)
    from_stmt = "";
  else
    from_stmt = query.substr(from_position + 4, where_position - from_position - 4);

  if (where_position == -1)
    where_stmt = "";
  else if (extra_stmt_position == -1)
    where_stmt = query.substr(where_position + 5, query.size() - where_position - 5);
  else
    where_stmt = query.substr(where_position + 5, extra_stmt_position - where_position - 5);

  if (extra_stmt_position == -1)
    extra_stmt = "";
  else
    extra_stmt = query.substr(extra_stmt_position, query.size() - extra_stmt_position);


  if ( (extra_stmt.find("HAVING") == string::npos) || (extra_stmt.find("having") == string::npos) ) {  // This is not a having stmts. Handle with where stmt.
    if (
        ((select_stmt.find("DISTINCT") == string::npos) || (select_stmt.find("distinct") == string::npos)) &&
        ((extra_stmt.find("GROUP BY") == string::npos) || (extra_stmt.find("group by") == string::npos))
    )
    {

      rewrite_where_union_all(query, rew_1, before_select_stmt, select_stmt, from_stmt, where_stmt, extra_stmt);

    } else {

      rewrite_where_union(query, rew_1, before_select_stmt, select_stmt, from_stmt, where_stmt, extra_stmt);

    }

  } else {
    // TODO:: Handling HAVING stmt. 
  }

  rew_2 = "";
  rew_3 = "";

}

string SQL_TLP::rewrite_where_union_all(string& ori, string& rew_1, const string& bef_sel_stmt, const string& sel_stmt, const string& from_stmt, const string& where_stmt, const string& extra_stmt){
  /* Taking care of TLP select stmt: SELECT x FROM x [joins] */
  if (where_stmt == ""){
    rew_1 = bef_sel_stmt + " SELECT " + sel_stmt + " FROM " + from_stmt + " WHERE TRUE " + extra_stmt;
    rew_1 += " UNION ALL ";
    rew_1 += bef_sel_stmt + " SELECT " + sel_stmt + " FROM " + from_stmt + " WHERE NOT TRUE " + extra_stmt;
    rew_1 += " UNION ALL ";
    rew_1 += bef_sel_stmt + " SELECT " + sel_stmt + " FROM " + from_stmt + " WHERE TRUE IS NULL " + extra_stmt;

  } else {

    rew_1 = bef_sel_stmt + " SELECT " + sel_stmt + " FROM " + from_stmt + " WHERE " + where_stmt + " " + extra_stmt;
    rew_1 += " UNION ALL ";
    rew_1 += bef_sel_stmt + " SELECT " + sel_stmt + " FROM " + from_stmt + " WHERE NOT (" + where_stmt + ") " + extra_stmt;
    rew_1 += " UNION ALL ";
    rew_1 += bef_sel_stmt + " SELECT " + sel_stmt + " FROM " + from_stmt + " WHERE (" + where_stmt + ") IS NULL " + extra_stmt;

    ori = bef_sel_stmt + " SELECT " + sel_stmt + " FROM " + from_stmt + " " + extra_stmt;

  }
}

string SQL_TLP::rewrite_where_union(string& ori, string& rew_1, const string& bef_sel_stmt, const string& sel_stmt, const string& from_stmt, const string& where_stmt, const string& extra_stmt){
  /* Taking care of TLP select stmt: SELECT x FROM x [joins] */
  if (where_stmt == ""){
    rew_1 = bef_sel_stmt + " SELECT " + sel_stmt + " FROM " + from_stmt + " WHERE TRUE " + extra_stmt;
    rew_1 += " UNION ";
    rew_1 += bef_sel_stmt + " SELECT " + sel_stmt + " FROM " + from_stmt + " WHERE NOT TRUE " + extra_stmt;
    rew_1 += " UNION ";
    rew_1 += bef_sel_stmt + " SELECT " + sel_stmt + " FROM " + from_stmt + " WHERE TRUE IS NULL " + extra_stmt;

  } else {

    rew_1 = bef_sel_stmt + " SELECT " + sel_stmt + " FROM " + from_stmt + " WHERE " + where_stmt + " " + extra_stmt;
    rew_1 += " UNION ";
    rew_1 += bef_sel_stmt + " SELECT " + sel_stmt + " FROM " + from_stmt + " WHERE NOT (" + where_stmt + ") " + extra_stmt;
    rew_1 += " UNION ";
    rew_1 += bef_sel_stmt + " SELECT " + sel_stmt + " FROM " + from_stmt + " WHERE (" + where_stmt + ") IS NULL " + extra_stmt;

    ori = bef_sel_stmt + " SELECT " + sel_stmt + " FROM " + from_stmt + " " + extra_stmt;

  }
}

string SQL_TLP::rewrite_having(string& ori, string& rew_1, const string& before_select_stmt, const string& select_stmt, const string& from_stmt, const string& where_stmt, const string& extra_stmt){
  // TODO:: Implement having stmts. 
  return "";
}


string SQL_TLP::remove_valid_stmts_from_str(string query){
  string output_query = "";
  vector<string> queries_vector = string_splitter(query, ";");

  for (auto current_stmt : queries_vector){
    if (is_str_empty(current_stmt)) continue;
    if(!is_oracle_valid_stmt(current_stmt)) output_query += current_stmt + "; ";
  }

  return output_query;
}

int SQL_TLP::compare_results(const vector<string>& result_0, const vector<string>& result_1, const vector<string>& result_2, const vector<string>& result_3, const string& cmd_str){
  
  bool is_all_errors = true;
  int current_ori_result_int;
  int current_rew_result_int;

  vector<valid_type> v_valid_type;
  get_v_valid_type(cmd_str, v_valid_type);

  string result_a, result_b;
  vector<string> v_result_a, v_result_b;
  int out_a = 0, out_b = 0;

  for (int i = 0; i < min({result_0.size(), result_1.size(), v_valid_type.size()}); i++){
    result_a = ""; result_b = ""; 
    v_result_a.clear(); v_result_b.clear();

    switch (v_valid_type[i])
    {
    case valid_type::NORM:
      /* Handle normal valid stmt: SELECT * FROM ...; */
      if (result_0[i] != result_1[i]) return 0;  // Found inconsistent. 
      is_all_errors = false;
      break;

    case valid_type::MIN:
    /* Handle MIN valid stmt: SELECT MIN(*) FROM ...; */
      result_a = result_0[i]; result_b = result_1[i];
      v_result_a = string_splitter(result_a, "\n");
      v_result_b = string_splitter(result_b, "\n");

      out_a = INT32_MAX, out_b = INT32_MAX;

      for (int j = 0; j < min(v_result_a.size(), v_result_b.size() ); j++){
        int cur_a = 0, cur_b = 0;
        try {
          cur_a = stoi(v_result_a[j]);
          cur_b = stoi(v_result_b[j]);
        }
        catch (std::invalid_argument &e) {
          continue;
        }
        catch (std::out_of_range &e) {
          continue;
        }
        is_all_errors = false;
        out_a = (out_a > cur_a) ? cur_a : out_a;
        out_b = (out_b > cur_b) ? cur_b : out_b;
      }
      if (out_a != out_b) return 0; // Found inconsistent. 
      break;

    case valid_type::MAX:
    /* Handle MAX valid stmt: SELECT MAX(*) FROM ...; */
      result_a = result_0[i]; result_b = result_1[i];
      v_result_a = string_splitter(result_a, "\n");
      v_result_b = string_splitter(result_b, "\n");

      out_a = INT32_MIN; out_b = INT32_MIN;

      for (int j = 0; j < min(v_result_a.size(), v_result_b.size() ); j++){
        int cur_a = 0, cur_b = 0;
        try {
          cur_a = stoi(v_result_a[j]);
          cur_b = stoi(v_result_b[j]);
        }
        catch (std::invalid_argument &e) {
          continue;
        }
        catch (std::out_of_range &e) {
          continue;
        }
        is_all_errors = false;
        out_a = (out_a < cur_a) ? cur_a : out_a;
        out_b = (out_b < cur_b) ? cur_b : out_b;
      }
      if (out_a != out_b) return 0; // Found inconsistent. 
      break;
    case valid_type::COUNT:
    /* Handle SELECT COUNT(*) FROM x...; */
    // Fallthrough!!!
      [[fallthrough]];
    case valid_type::SUM:
    /* Handle MAX valid stmt: SELECT MAX(*) FROM ...; */
      result_a = result_0[i]; result_b = result_1[i];
      v_result_a = string_splitter(result_a, "\n");
      v_result_b = string_splitter(result_b, "\n");

      out_a = 0, out_b = 0;

      for (int j = 0; j < min(v_result_a.size(), v_result_b.size() ); j++){
        int cur_a = 0, cur_b = 0;
        try {
          cur_a = stoi(v_result_a[j]);
          cur_b = stoi(v_result_b[j]);
        }
        catch (std::invalid_argument &e) {
          continue;
        }
        catch (std::out_of_range &e) {
          continue;
        }
        is_all_errors = false;
        out_a += cur_a;
        out_b += cur_b;
      }
      if (out_a != out_b) return 0; // Found inconsistent. 
      break;
    // case valid_type::AVG: // TODO: Implement AVG. 
    default:
      cerr << "SQL_TLP::compare_results Error: Unknown valid_type. \n";
      break;
    }
  }

  if (is_all_errors) return -1; // All errors.
  else return 0; // Consistant results. 

}

void SQL_TLP::get_v_valid_type(const string& cmd_str, vector<valid_type>& v_valid_type) {
  /* Look throught first validation stmt's result_1 first */
  size_t begin_idx = cmd_str.find("13579", 0);
  size_t end_idx = cmd_str.find("97531", 0);

  while (begin_idx != string::npos){
    if (end_idx != string::npos){
      string current_cmd_string = cmd_str.substr(begin_idx + 5, (end_idx - begin_idx - 5));
      begin_idx = cmd_str.find("13579", begin_idx+5);
      end_idx = cmd_str.find("97531", end_idx+5);

      if ( (current_cmd_string.find("MIN") != string::npos) || (current_cmd_string.find("min") != string::npos) ) v_valid_type.push_back(valid_type::MIN);
      else if ( (current_cmd_string.find("MAX") != string::npos) || (current_cmd_string.find("max") != string::npos) ) v_valid_type.push_back(valid_type::MAX);
      else if ( (current_cmd_string.find("SUM") != string::npos) || (current_cmd_string.find("sum") != string::npos) ) v_valid_type.push_back(valid_type::SUM);
      else if ( (current_cmd_string.find("COUNT") != string::npos) || (current_cmd_string.find("count") != string::npos) ) v_valid_type.push_back(valid_type::COUNT);
      // else if ( (current_cmd_string.find("AVG") != string::npos) || (current_cmd_string.find("avg") != string::npos) ) v_valid_type.push_back(valid_type::AVG); // TODO:: Implement AVG. 
      else v_valid_type.push_back(valid_type::NORM);
    }
    else {
      break; // For the current begin_idx, we cannot find the end_idx. Ignore the current output. 
    }
  }
}
