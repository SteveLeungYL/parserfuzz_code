#include <iostream>
#include "./sqlite_norec.h"
#include "../include/utils.h"
#include "../include/mutator.h"

void SQL_NOREC::append_valid_stmts(string &input) {

  ensure_semicolon_at_query_end(input);

  string new_norec_stmts = "";
  int num_norec = count_valid_stmts(input);

  int trial = 0;
  int max_trial = (max_norec - num_norec) * 3;  // For each norec select stmt, we have on average 3 chances to append the stmt and check. 

  while (num_norec < max_norec){

    if (trial++ >= max_trial) // Give on average 3 chances per select stmts.  
      break;

    new_norec_stmts = g_mutator->get_random_mutated_valid_stmt();
    if (new_norec_stmts == "") continue;
    ensure_semicolon_at_query_end(new_norec_stmts);

    /* Reparse the combine_query_str to check whether the added norec_stmts is valide. */
    //vector<IR*> new_ir_tree = g_mutator.parse_query_str_get_ir_set(new_norec_stmts);
    //if (new_ir_tree.size() == 0) continue;
    //new_ir_tree.back()->deep_drop();

    input += new_norec_stmts;
    num_norec++;

    /* Return norec query does not pass the parser. Append failed. Retrive new norec query and try again. */
  }

  return;
}

int SQL_NOREC::count_valid_stmts(const string& input){
  int norec_select_count = 0;
  vector<string> queries_vector = string_splitter(input, ";");
  for (string &query : queries_vector) 
    if (this->is_valid_stmt(query))
      norec_select_count++;
  return norec_select_count;
}


bool SQL_NOREC::is_valid_stmt(const string& query){
  if (
        ((query.find("SELECT COUNT ( * ) FROM")) != std::string::npos || (query.find("select count ( * ) from")) != std::string::npos) && // This is a SELECT stmt. Not INSERT or UPDATE stmts.
        ((query.find("SELECT COUNT ( * ) FROM")) <= 5 || (query.find("select count ( * ) from")) <= 5) &&
        ((query.find("INSERT")) == std::string::npos && (query.find("insert")) == std::string::npos) &&
        ((query.find("UPDATE")) == std::string::npos && (query.find("update")) == std::string::npos)  &&
        ((query.find("WHERE")) != std::string::npos || (query.find("where")) != std::string::npos) &&  // This is a SELECT stmt that matching the requirments of NoREC.
        ((query.find("FROM")) != std::string::npos || (query.find("from")) != std::string::npos) &&
        ((query.find("GROUP BY")) == std::string::npos && (query.find("group by")) == std::string::npos) // TODO:: Should support group by a bit later.
    ) return true;
    return false;
}

bool SQL_NOREC::mark_all_valid_node(vector<IR *> &v_ir_collector)
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
        if (ir != nullptr && ir->type_ == kSelectNoParen)
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
                        string query = extract_struct(ir);
                        if (   !(this->is_valid_stmt(query))   )  continue;  // Not norec compatible. Jump to the next ir.
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