#include "../include/mutator.h"
#include "../include/ast.h"
#include "../include/define.h"
#include "../include/utils.h"

#include <sys/time.h>
#include <sys/resource.h>

#include <assert.h>
#include <fstream>
#include <cstdio>
#include <climits>
#include <cfloat>
#include <algorithm>
#include <deque>
#define _NON_REPLACE_

using namespace std;


vector<string> Mutator::common_string_libary;
vector<unsigned long> Mutator::value_libary;
map<string, vector<string>> Mutator::m_tables;
vector<string> Mutator::v_table_names; 


IR * Mutator::deep_copy_with_record(const IR * root, const IR * record){

    IR * left = NULL, * right = NULL, * copy_res;

    if(root->left_) left = deep_copy_with_record(root->left_, record);                                             
    if(root->right_) right = deep_copy_with_record(root->right_, record); 

    if(root->op_ != NULL)
        copy_res = new IR(root->type_, OP3(root->op_->prefix_, root->op_->middle_, root->op_->suffix_), 
                    left, right, root->f_val_, root->str_val_, root->name_, root->mutated_times_);
    else
        copy_res = new IR(root->type_, NULL, left, right, root->f_val_, root->str_val_, root->name_, root->mutated_times_);

    copy_res->id_type_ = root->id_type_;

    if(root == record && record != NULL){
        this->record_ = copy_res;
    }
    
    return copy_res;

}

bool Mutator::check_node_num(IR * root, unsigned int limit){
    
    auto v_statements = extract_statement(root);
    bool is_good = true;
    
    if(v_statements.size() > 50){
        is_good = false;

    }else
        for(auto stmt: v_statements){
            if(calc_node(stmt) > limit){
                is_good = false;
                break;
            }
        }

    return is_good;
}

bool Mutator::make_current_node_as_norec_select_stmt(IR* root){
    if (root == nullptr) return false;
    /* the following types do not added to the norec_select_stmt list. They should be able to mutate as usual. */
    if (root -> type_ == kExpr || root->type_ == kTableRef || root->type_ == kOptGroup || root-> type_ == kWindowClause) return false;
    root -> is_norec_select_fixed = true;
    if (root -> left_ != nullptr) this->make_current_node_as_norec_select_stmt(root->left_);
    if (root -> right_ != nullptr) this->make_current_node_as_norec_select_stmt(root->right_);
    return true;
}

bool Mutator::is_norec_compatible(const string& query){
  if (
        ((query.find("SELECT COUNT ( * )")) != std::string::npos || (query.find("select count ( * )")) != std::string::npos) && // This is a SELECT stmt. Not INSERT or UPDATE stmts.
        ((query.find("SELECT COUNT ( * )")) <= 5 || (query.find("select count ( * )")) <= 5) &&
        ((query.find("INSERT")) == std::string::npos && (query.find("insert")) == std::string::npos) &&
        ((query.find("UPDATE")) == std::string::npos && (query.find("update")) == std::string::npos)  &&
        ((query.find("WHERE")) != std::string::npos || (query.find("where")) != std::string::npos) &&  // This is a SELECT stmt that matching the requirments of NoREC.
        ((query.find("FROM")) != std::string::npos || (query.find("from")) != std::string::npos) &&  
        ((query.find("GROUP BY")) == std::string::npos && (query.find("group by")) == std::string::npos) // TODO:: Should support group by a bit later. 
    ) return true;
    return false;
}

bool Mutator::mark_all_norec_select_stmt(vector<IR *> &v_ir_collector)
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
            par_ir = locate_parent(root, ir);
            if (par_ir != nullptr && par_ir->type_ == kSelectStatement)
            {
                par_par_ir = locate_parent(root, par_ir);
                if (par_par_ir != nullptr && par_par_ir->type_ == kStatement)
                {
                    par_par_par_ir = locate_parent(root, par_par_ir);
                    if (par_par_par_ir != nullptr && par_par_par_ir->type_ == kStatementList)
                    {
                        string query = extract_struct(ir);
                        if (   !(this->is_norec_compatible(query))   )  continue;  // Not norec compatible. Jump to the next ir. 
                        query.clear();
                        is_mark_successfully = make_current_node_as_norec_select_stmt(ir);
                        // cerr << "\n\n\nThe marked norec ir is: " << this->extract_struct(ir) << " \n\n\n";
                        par_ir -> is_norec_select_fixed = true;
                        par_par_ir -> is_norec_select_fixed = true;
                        par_par_par_ir -> is_norec_select_fixed = true;
                    }
                }
            }
        }
    }
    // cerr << "Norec select marked (bool): " << is_mark_successfully << endl;
    return is_mark_successfully;
}

vector<IR *> Mutator::mutate_all(vector<IR *> &v_ir_collector){
    vector<IR *> res;
    set<unsigned long> res_hash;
    IR * root = v_ir_collector[v_ir_collector.size()-1];

    mark_all_norec_select_stmt(v_ir_collector);

    for(auto ir: v_ir_collector){
        if(ir == root || ir->type_ == kProgram 
        || ir -> is_norec_select_fixed 
        ) continue;
        vector<IR *> v_mutated_ir = mutate(ir);

        for(auto i: v_mutated_ir){
            IR * new_ir_tree = deep_copy_with_record(root, ir);
            replace(new_ir_tree, this->record_, i);        

            if(!check_node_num(new_ir_tree, 100)){
                deep_delete(new_ir_tree);
                continue;
            }

            string tmp = extract_struct(new_ir_tree);
            unsigned tmp_hash = hash(tmp);
            if(res_hash.find(tmp_hash) != res_hash.end()){
                deep_delete(new_ir_tree);
                continue;
            }


            res_hash.insert(tmp_hash);
            res.push_back(new_ir_tree);
        }
    }

    return res;

}

int Mutator::get_ir_libary_2D_hash_kStatement_size(){
    return this->ir_libary_2D_hash_[kStatement].size();
}


void Mutator::init(string f_testcase, string f_common_string, string pragma) {

    ifstream input_test(f_testcase);
    string line;

    //init lib from multiple sql
    while(getline(input_test, line)) {

        auto p = parser(line) ;
        if(p == NULL) continue;

        vector<IR *> v_ir;
        auto res = p->translate(v_ir);
        p->deep_delete();
        p = NULL;
        string strip_sql = extract_struct(res);
        deep_delete(res);

        p = parser(strip_sql);
        if(p == NULL) continue;

        res = p->translate(v_ir);
        p->deep_delete();
        p = NULL;
        add_to_library(res);
        deep_delete(res);;
    }

    //init utils::m_tables
    vector<string> v_tmp = {"haha1", "haha2", "haha3"};
    v_table_names.insert(v_table_names.end(), v_tmp.begin(), v_tmp.end());
    m_tables["haha1"] = {"fucking_column0_1", "fucking_column1_1", "fucking_column2_1"};
    m_tables["haha2"] = {"fucking_column0_2", "fucking_column1_2", "fucking_column2_2"};
    m_tables["haha3"] = {"fucking_column0_3", "fucking_column1_3", "fucking_column2_3"};

    //init value_libary
    vector<unsigned long> value_lib_init = {0, (unsigned long)LONG_MAX, (unsigned long)ULONG_MAX,
        (unsigned long)CHAR_BIT, (unsigned long)SCHAR_MIN, (unsigned long)SCHAR_MAX, (unsigned long)UCHAR_MAX,
        (unsigned long)CHAR_MIN, (unsigned long)CHAR_MAX, (unsigned long)MB_LEN_MAX, (unsigned long)SHRT_MIN,
        (unsigned long)INT_MIN, (unsigned long)INT_MAX, (unsigned long)SCHAR_MIN, (unsigned long)SCHAR_MIN,
        (unsigned long)UINT_MAX, (unsigned long)FLT_MAX, (unsigned long)DBL_MAX, (unsigned long)LDBL_MAX,
        (unsigned long)FLT_MIN, (unsigned long)DBL_MIN, (unsigned long)LDBL_MIN };

    value_libary.insert(value_libary.begin(), value_lib_init.begin(), value_lib_init.end());


    //init common_string_libary 
    common_string_libary.push_back("DO_NOT_BE_EMPTY");
    if(f_common_string != ""){
        ifstream input_string(f_common_string);
        string s;

        while(getline(input_string, s)){
            common_string_libary.push_back(s);
        }
    }
    string_libary.push_back("x");
    string_libary.push_back("v0");
    string_libary.push_back("v1");
    
    ifstream input_pragma("./pragma");
    string s;
    cout << "start init pragma" << endl;
    while(getline(input_pragma, s)){
        if(s.empty()) continue;
        auto pos = s.find('=');
        if(pos == string::npos) continue;

        string k = s.substr(0, pos-1);
        string v = s.substr(pos+2);
        if(find(cmds_.begin(), cmds_.end(), k) == cmds_.end()) cmds_.push_back(k);
        m_cmd_value_lib_[k].push_back(v);
    }

    relationmap[id_column_name] = id_top_table_name;
    relationmap[id_table_name] = id_top_table_name;
    relationmap[id_index_name] = id_top_table_name;
    relationmap[id_create_column_name] = id_create_table_name;
    relationmap[id_pragma_value] = id_pragma_name;
    cross_map[id_top_table_name] = id_create_table_name;
    return;
}

vector<IR *> Mutator::mutate(IR * input){
    vector<IR *> res;

    if(!lucky_enough_to_be_mutated(input->mutated_times_)){
        return res; // return a empty set if the IR is not mutated
    }

    res.push_back(strategy_delete(input));
    res.push_back(strategy_insert(input));
    res.push_back(strategy_replace(input));

    // may do some simple filter for res, like removing some duplicated cases

    input->mutated_times_ += res.size();
    for(auto i : res){
        if(i == NULL) continue;
        i->mutated_times_ = input->mutated_times_ ;
    }
    return res;
}

bool Mutator::replace(IR * root , IR* old_ir, IR* new_ir){ 
    auto parent_ir = locate_parent(root, old_ir);
    if(parent_ir == NULL) return false;
    if(parent_ir->left_ == old_ir) { deep_delete(old_ir); parent_ir->left_ = new_ir; return true;}
    else if(parent_ir->right_ == old_ir) { deep_delete(old_ir); parent_ir->right_ = new_ir; return true;}

    return false;
}

IR * Mutator::locate_parent(IR * root ,IR * old_ir){

    if(root->left_ == old_ir || root->right_ == old_ir) return root;

    if(root->left_ != NULL) 
        if(auto res = locate_parent(root->left_, old_ir))  return res;
    if(root->right_ != NULL)
        if(auto res = locate_parent(root->right_, old_ir)) return res;

    return NULL;
}

IR * Mutator::find_child_with_type_and_parent(const vector<IR *> &v_ir_collector, NODETYPE node_type, IR * parent){
    IR * root = v_ir_collector[v_ir_collector.size()-1];
    for(auto ir: v_ir_collector){
        if (ir != nullptr && ir -> type_ == node_type && this->locate_parent(root, ir) == parent)
            return ir;
    }
    cerr << "Error: Cannot find the child type from parent. " << endl;
    return nullptr;
}

string Mutator::validate(IR * root){

    if(root == NULL) return "";
    try{
        string sql_str = root->to_string();
        // cerr << "Mutated query string: " << sql_str << endl << endl;
        auto parsed_ir = parser(sql_str);
        if(parsed_ir == NULL)
            // cerr << "Mutated query not passing parser!!!" << endl << endl;
            return "";
        parsed_ir->deep_delete();

        reset_counter();
        vector<IR*> ordered_ir;
        auto graph = build_dependency_graph(root, relationmap, cross_map, ordered_ir);
        fix_graph(graph, root, ordered_ir);
        // cerr << "Mutated query ISSSSS  passing parser!!!" << endl << endl;
        return fix(root);
    }catch(...){
        // invalid sql , skip
    }
    return "";
}

static void collect_ir(IR* root,set<IDTYPE> &type_to_fix, vector<IR*> &ir_to_fix){
    auto idtype = root->id_type_;

    if(root->left_){
        collect_ir(root->left_, type_to_fix, ir_to_fix);
    }

    if(type_to_fix.find(idtype) != type_to_fix.end()){
        ir_to_fix.push_back(root);
    }

    if(root->right_){
        collect_ir(root->right_, type_to_fix, ir_to_fix);
    }
}

static IR* search_mapped_ir(IR* ir, IDTYPE idtype){
    vector<IR*> to_search;
    vector<IR*> backup;
    to_search.push_back(ir);
    while(!to_search.empty()){
        for(auto i: to_search){
            if(i->id_type_ == idtype){
                return i;
            }
            if(i->left_){
                backup.push_back(i->left_);
            }
            if(i->right_){
                backup.push_back(i->right_);
            }
        }
        to_search = move(backup);
        backup.clear();
    }
    return NULL;
}

void cross_stmt_map(map<IR*, set<IR*>> &graph, vector<IR*> &ir_to_fix, map<IDTYPE, IDTYPE> &cross_map){
    for(auto m: cross_map){
        vector<IR*> value;
        vector<IR*> key;

        for(auto &k: graph){
            if(k.first->id_type_ == m.first){
                key.push_back(k.first);
            }
        }

        for(auto &k: ir_to_fix){
            if(k->id_type_ == m.second){
                value.push_back(k);
            }
        }

        if(key.empty()) return;
        for(auto val: value){
            graph[key[get_rand_int(key.size())]].insert(val);
        }
    }
}

void toptable_map(map<IR*, set<IR*>> &graph, vector<IR*> &ir_to_fix, vector<IR*> &toptable){
    vector<IR*> tablename;
    for(auto ir: ir_to_fix){
        if(ir->id_type_ == id_table_name){
            tablename.push_back(ir);
        }else if(ir->id_type_ == id_top_table_name){
            toptable.push_back(ir);
        }
    }
    if(toptable.empty()) return;  
    for(auto k: tablename){
        auto r = get_rand_int(toptable.size());
        graph[toptable[r]].insert(k);
    }
}


vector<IR *> Mutator::extract_statement(IR * root){
    vector<IR *> res;
    deque<IR *> bfs = {root};

    while(bfs.empty() != true){
        auto node = bfs.front();
        bfs.pop_front();

        if(node->type_ == kStatement) res.push_back(node);
        if(node->left_) bfs.push_back(node->left_);
        if(node->right_) bfs.push_back(node->right_);
    }

    return res;
}

vector<IR *> Mutator::cut_subquery(IR * program, map<IR**, IR*> &m_save){

    vector<IR *> res;
    vector<IR *> v_statements;
    deque<IR *> dfs = {program};

    while(dfs.empty() != true){
        auto node = dfs.front();
        dfs.pop_front();

        if(node->type_ == kStatement) v_statements.push_back(node);
        if(node->left_) dfs.push_back(node->left_);
        if(node->right_) dfs.push_back(node->right_);
    }

    reverse(v_statements.begin(), v_statements.end());
    for(auto &stmt: v_statements){
        deque<IR *> q_bfs = {stmt};
        res.push_back(stmt);

        while(!q_bfs.empty()){
            auto cur = q_bfs.front();
            q_bfs.pop_front();

            if(cur->left_){
                q_bfs.push_back(cur->left_);
                if(cur->left_->type_ == kSelectNoParen){
                    res.push_back(cur->left_);
                    m_save[&cur->left_] = cur->left_;
                    cur->left_ = NULL;
                }
            }

            if(cur->right_){
                q_bfs.push_back(cur->right_);
                if(cur->right_->type_ == kSelectNoParen){
                    res.push_back(cur->right_);
                    m_save[&cur->right_] = cur->right_;
                    cur->right_ = NULL;
                }
            }

        }
    }
    return res;
}



bool Mutator::fix_back(map<IR**, IR*> &m_save){
    for(auto &i: m_save){
        if(*(i.first) != NULL) return false;
        *(i.first) = i.second;
    }

    return true;
}




map<IR*, set<IR*> > Mutator::build_dependency_graph(IR* root, map<IDTYPE, IDTYPE> &relationmap, map<IDTYPE, IDTYPE> &cross_map, vector<IR*> &ordered_ir){
  map<IR*, set<IR*>> graph;
  set<IDTYPE> type_to_fix;
  map<IR**, IR*> m_save;
  for(auto &iter: relationmap){
    type_to_fix.insert(iter.first);
    type_to_fix.insert(iter.second);
  }

  auto ir_list = cut_subquery(root, m_save);

  for(auto stmt: ir_list){
    vector<IR*> ir_to_fix;
    collect_ir(stmt, type_to_fix, ir_to_fix);
    for(auto ii: ir_to_fix){
      ordered_ir.push_back(ii);
    }
    cross_stmt_map(graph, ir_to_fix, cross_map);
    vector<IR*> v_top_table;
    toptable_map(graph, ir_to_fix, v_top_table);
    for(auto ir: ir_to_fix){

      auto idtype = ir->id_type_;
      graph[ir].empty();
      if(relationmap.find(idtype) == relationmap.end()){
        continue;
      }

      auto curptr = ir;
      bool flag = false;
      while(true){
        auto pptr = locate_parent(stmt, curptr);
        if(pptr == NULL)break;
        while(pptr->left_ == NULL || pptr->right_ == NULL){
          curptr = pptr;
          pptr = locate_parent(stmt, curptr);
          if(pptr == NULL){
            flag = true;
            break;
          }
        }
        if(flag) break;

        auto to_search_child = pptr->left_;
        if(pptr->left_ == curptr){
          to_search_child = pptr->right_;
        }

        auto match_ir = search_mapped_ir(to_search_child, relationmap[idtype]);
        if(match_ir != NULL){
          if(ir->type_ == kColumnName  && ir->left_ != NULL){
            if(v_top_table.size() > 0)
              match_ir = v_top_table[get_rand_int(v_top_table.size())];
            graph[match_ir].insert(ir->left_);
            if(ir->right_){
              graph[match_ir].insert(ir->right_);
              ir->left_->id_type_ = id_table_name;
              ir->right_->id_type_ = id_column_name;
              ir->id_type_ = id_whatever;
            }
          }else
            graph[match_ir].insert(ir);
          break;
        }
        curptr = pptr;
      }
    }
  }

  fix_back(m_save);
  return graph;
}

IR * Mutator::strategy_delete(IR * cur){
  assert(cur);
  MUTATESTART

    DOLEFT
    res = deep_copy(cur);
  if(res->left_ != NULL)
    deep_delete(res->left_);
  res->left_ = NULL;

  DORIGHT
    res = deep_copy(cur);
  if(res->right_ != NULL)
    deep_delete(res->right_);
  res->right_ = NULL;

  DOBOTH
    res = deep_copy(cur);
  if(res->left_ != NULL)
    deep_delete(res->left_);
  if(res->right_ != NULL)
    deep_delete(res->right_);
  res->left_ = res->right_ = NULL;

  MUTATEEND 
}


IR * Mutator::strategy_insert(IR * cur){

  assert(cur);

  if(cur->type_ == kStatementList){
    auto new_right = get_from_libary_with_left_type(cur->type_);
    if (new_right != NULL){
      auto res = deep_copy(cur);
      auto new_res = new IR(kStatementList, OPMID(";"), res, new_right);
      return new_res;
    }
  }

  if(cur->right_ == NULL && cur->left_ != NULL){
    auto left_type = cur->left_->type_;
    auto new_right = get_from_libary_with_left_type(left_type);
    if (new_right != NULL){
      auto res = deep_copy(cur);
      res->right_ = new_right;
      return res;
    }
  }
  
  else if(cur->right_ != NULL && cur->left_ == NULL){
    auto right_type = cur->right_->type_;
    auto new_left = get_from_libary_with_right_type(right_type);
    if(new_left != NULL){
      auto res = deep_copy(cur);
      res->left_ = new_left;
      return res;
    }
  }

  return get_from_libary_with_type(cur->type_);
}

IR * Mutator::strategy_replace(IR * cur){
  assert(cur);

  MUTATESTART
  

    DOLEFT
    res = deep_copy(cur);
    if (res->left_ == NULL) break;

  auto new_node = get_from_libary_with_type(res->left_->type_);

  if(new_node != NULL) {
    if(res->left_ != NULL){
      new_node->id_type_ = res->left_->id_type_;
    }
  }
  if(res->left_ != NULL) deep_delete(res->left_);
  res->left_ = new_node;

  DORIGHT
    res = deep_copy(cur);
    if (res->right_ == NULL) break;

  auto new_node = get_from_libary_with_type(res->right_->type_);
  if(new_node != NULL) {
    if(res->right_ != NULL){
      new_node->id_type_ = res->right_->id_type_;
    }
  }
  if(res->right_ != NULL) deep_delete(res->right_);
  res->right_ = new_node;

  DOBOTH
    res = deep_copy(cur);
    if ( res->left_ == NULL || res->right_ == NULL) break;
    

  auto new_left = get_from_libary_with_type(res->left_->type_);
  auto new_right = get_from_libary_with_type(res->right_->type_);

  if(new_left != NULL){
    if(res->left_ != NULL){
      new_left->id_type_ = res->left_->id_type_;

    }
  }

  if(new_right != NULL){
    if(res->right_ != NULL){
      new_right->id_type_ = res->right_->id_type_;
    }
  }

  if(res->left_) deep_delete(res->left_);
  if(res->right_) deep_delete(res->right_);
  res->left_ = new_left;
  res->right_ = new_right;

  MUTATEEND

    return res;
}

bool Mutator::lucky_enough_to_be_mutated(unsigned int mutated_times){
  if(get_rand_int(mutated_times+1) < LUCKY_NUMBER){
    return true;
  }
  return false;
}

IR* Mutator::get_from_libary_with_type(IRTYPE type_){

  vector<IR*> matching_ir_set;
  for (int i = 0; i < 3000; i++){
    vector<IR*> ir_set = get_random_query_IR_set();
    for (auto ir: ir_set){
      if (ir->type_ == type_) matching_ir_set.push_back(deep_copy(ir));
    }
    /* Clean up the whole generated query ir. Only return the deep_copied matching ir set. */
    // for (auto ir: ir_set) delete ir; 
    if(ir_set.size() > 0) deep_delete(ir_set[ir_set.size()-1]);

    if (matching_ir_set.size() > 0) break;
  }

  /* If current type_ cannot be found by the random queries by multiple trials. Return NULL */
  if (matching_ir_set.size() > 0){
    IR* selected_matching_ir = deep_copy(matching_ir_set[get_rand_int(matching_ir_set.size())]);
    for (auto ir:matching_ir_set) delete ir;
    return selected_matching_ir;
  }
  else {
    return new IR(kStringLiteral, "");
  }
}

IR* Mutator::get_from_libary_with_left_type(IRTYPE type_){

  vector<IR*> matching_ir_set;
  for (int i = 0; i < 3000; i++){
    vector<IR*> ir_set = get_random_query_IR_set();
    for (auto ir: ir_set){
      if (ir->left_ != NULL && ir->left_->type_ == type_) matching_ir_set.push_back(deep_copy(ir->right_));
    }
    /* Clean up the whole generated query ir. Only return the deep_copied matching ir set. */
    // for (auto ir: ir_set) delete ir; 
    if(ir_set.size() > 0) deep_delete(ir_set[ir_set.size()-1]);

    if (matching_ir_set.size() > 0) break;
  }

  /* If current type_ cannot be found by the random queries by multiple trials. Return NULL */
  if (matching_ir_set.size() > 0){
    IR* selected_matching_ir = deep_copy(matching_ir_set[get_rand_int(matching_ir_set.size())]);
    for (auto ir:matching_ir_set) delete ir;
    return selected_matching_ir;
  }
  else {
    return NULL;
  }
}

IR* Mutator::get_from_libary_with_right_type(IRTYPE type_){

  vector<IR*> matching_ir_set;
  for (int i = 0; i < 3000; i++){
    vector<IR*> ir_set = get_random_query_IR_set();
    for (auto ir: ir_set){
      if (ir->right_ != NULL && ir->right_->type_ == type_) matching_ir_set.push_back(deep_copy(ir->left_));
    }
    /* Clean up the whole generated query ir. Only return the deep_copied matching ir set. */
    // for (auto ir: ir_set) delete ir; 
    if(ir_set.size() > 0) deep_delete(ir_set[ir_set.size()-1]);

    if (matching_ir_set.size() > 0) break;
  }

  /* If current type_ cannot be found by the random queries by multiple trials. Return NULL */
  if (matching_ir_set.size() > 0){
    IR* selected_matching_ir = deep_copy(matching_ir_set[get_rand_int(matching_ir_set.size())]);
    for (auto ir:matching_ir_set) delete ir;
    return selected_matching_ir;
  }
  else {
    return NULL;
  }
}

vector<IR*> Mutator::get_random_query_IR_set(){
  string random_query_str;
  Program * program_root = NULL;
  vector<IR*> ir_set;
  int parser_trial_count = 0;

  while (program_root == NULL){
    /* Cannot find any string that is passing the parser after multiple trials. SHOULD NOT HAPPEN!!! Return empty ir_set. */
    if (parser_trial_count > 3000) {cerr << " \nError: cannot find str that is passing the parser. \n"; return ir_set;} 
    parser_trial_count++;

    if (real_ir_set_str.size() == 0) return ir_set; 
    random_query_str = real_ir_set_str[get_rand_int(real_ir_set_str.size())];
    program_root = parser(random_query_str);

    if (program_root == NULL) continue;
    try {
      program_root->translate(ir_set);
    } catch(...) {
      for(auto ir: ir_set) delete ir;
      program_root->deep_delete();
      program_root = NULL;
      if (ir_set.size() != 0) ir_set.clear();
      random_query_str = "";
      continue;
    }
    program_root->deep_delete(); 
    break;
  }

  return ir_set;
}

//IR* Mutator::get_from_libary_3D(IR* ir){
//  NODETYPE left_type = kEmpty, right_type = kEmpty;
//  if(ir->left_){
//    left_type = ir->left_->type_;
//  } 
//  if(ir->right_){
//    right_type = ir->right_->type_;
//  }
//  auto &i = ir_libary_3D_[left_type][right_type];
//  if(i.size() == 0) return new IR(kStringLiteral, "");
//  return i[get_rand_int(i.size())];
//}

string Mutator::get_a_string(){
  unsigned com_size = common_string_libary.size();
  unsigned lib_size = string_libary.size();
  unsigned double_lib_size = lib_size * 2;

  unsigned rand_int = get_rand_int(double_lib_size + com_size);
  if(rand_int < double_lib_size){
    return string_libary[rand_int >> 1];
  }else{
    rand_int -= double_lib_size;
    return common_string_libary[rand_int];
  }
}

unsigned long Mutator::get_a_val(){
  if(value_libary.size() == 0) return 0xdeadbeef;
  return value_libary[get_rand_int(value_libary.size())];
}

unsigned long Mutator::get_library_size(){
  unsigned long res = 0;

  // for(auto &i: ir_libary_2D_){
  //   res += i.second.size();
  // }

  //for(auto &i: ir_libary_3D_){
  //  for(auto &j: i.second){
  //    res += j.second.size();
  //  }
  //}

  // for(auto &i: left_lib){
  //   res += i.second.size();
  // }

  // for(auto &i: right_lib){
  //   res += i.second.size();
  // }

  for (auto &i: real_ir_set_str){
    res += 1;
  }

  return res;
}

#ifdef _NON_REPLACE_
#define ADD_TO_LIBRARY        add_to_library
#define ADD_TO_LIBRARY_CORE   add_to_library_core
#define DEEP_COPY(x)          x
#else
#define ADD_TO_LIBRARY        add_to_library_core
#define ADD_TO_LIBRARY_CORE   add_to_library
#define DEEP_COPY(x)          deep_copy(x)
#endif

void Mutator::ADD_TO_LIBRARY(IR* ir) {

  NODETYPE p_type = ir->type_;
  string query_str = ir->to_string();
  unsigned long p_hash = hash(query_str);

  if(ir_libary_2D_hash_[p_type].find(p_hash) != 
      ir_libary_2D_hash_[p_type].end())
    return ;

  ir_libary_2D_hash_[p_type].insert(p_hash);

  real_ir_set_str.push_back(query_str);
  query_str.clear();
  get_memory_usage();
  

// #if 0
//   static unsigned long counter = 0;
//   static unsigned long total_size = 0;
//   unsigned long this_size = 0;
//   IR * ir_copy = deep_copy_size(ir, &this_size);
//   counter++;
//   total_size += this_size;

//   std::ofstream f;
//   f.rdbuf()->pubsetbuf(0, 0);
//   f.open("/tmp/memlog", std::ofstream::out | std::ofstream::app);
//   f << "add_to_lib[" << counter << "]: " 
//     << total_size / (1024 * 1024) << "M\t"
//     << this_size / (1024) << "K\n";;
//   f.close();
// #else
//   IR * ir_copy = deep_copy(ir);
// #endif

//   ADD_TO_LIBRARY_CORE(ir_copy);

//   real_ir_set.push_back(ir_copy);


  //get_memory_usage();

}

void Mutator::get_memory_usage() {

  static unsigned long old_use = 0;

  std::ofstream f;
  // f.rdbuf()->pubsetbuf(0, 0);
  f.open("./memlog.txt", std::ofstream::out | std::ofstream::app);

  struct rusage usage;
  getrusage(RUSAGE_SELF, &usage);

  unsigned long use = usage.ru_maxrss * 1024;

  // if (use - old_use < 1024 * 1024)
  //   return;

  f << "-------------------------------------\n";
  f << "memory use:  " << use << "\n";
  old_use = use;

  unsigned long total_size = 0;

  // unsigned long size_2D_hash = 0;
  // for (auto &i : ir_libary_2D_hash_)
  //   size_2D_hash += i.second.size() * 8;
  // f << "2D hash size:" << size_2D_hash 
  //      << "\t - " << size_2D_hash * 1.0 / use << "\n";
  // total_size += size_2D_hash;

  // unsigned long size_2D = 0;
  // for(auto &i: ir_libary_2D_)
  //   size_2D += i.second.size() * 8;
  // f << "2D size:     " << size_2D
  //      << "\t - " << size_2D * 1.0 / use << "\n";
  // total_size += size_2D;

  // unsigned long size_left = 0;
  // for(auto &i: left_lib)
  //   size_left += i.second.size() * 8;;
  // f << "left size:   " << size_left
  //      << "\t - " << size_left * 1.0 / use << "\n";
  // total_size += size_left;

  // unsigned long size_right = 0;
  // for(auto &i: right_lib)
  //   size_right += i.second.size();
  // f << "right size:  " << size_right
  //      << "\t - " << size_right * 1.0 / use << "\n";
  // total_size += size_right;


  unsigned long size_common_string_libary = 0;
  for (auto &i : common_string_libary)
    size_common_string_libary += i.capacity();
  f << "common str:  " << size_common_string_libary
       << "\t - " << size_common_string_libary * 1.0 / use << "\n";
  total_size += size_common_string_libary;
    
  unsigned long size_value = 0;
  size_value += value_libary.size() * 8;
  f << "value size:   " << size_value
       << "\t - " << size_value * 1.0 / use << "\n";
  total_size += size_value;

  unsigned long size_m_tables = 0;
  for(auto &i: m_tables)
    for(auto &j : i.second)
      size_m_tables += j.capacity();;
  f << "m_tables size:" << size_m_tables
       << "\t - " << size_m_tables * 1.0 / use << "\n";
  total_size += size_m_tables;

  unsigned long size_v_table_names = 0;
  for(auto &i: v_table_names)
    size_v_table_names += i.capacity();;
  f << "v_tbl size:   " << size_v_table_names
       << "\t - " << size_v_table_names * 1.0 / use << "\n";
  total_size += size_v_table_names;

  unsigned long size_string_libary = 0;
  for (auto &i : string_libary)
    size_string_libary += i.capacity();
  f << "str lib size :" << size_string_libary
       << "\t - " << size_string_libary * 1.0 / use << "\n";
  total_size += size_string_libary;

  unsigned long size_real_ir_set_str_libary = 0;
  for (auto &i : real_ir_set_str)
    size_real_ir_set_str_libary += i.capacity();
  f << "real_ir_set_str size :" << size_real_ir_set_str_libary
       << "\t - " << size_real_ir_set_str_libary * 1.0 / use << "\n";
  total_size += size_real_ir_set_str_libary;

  f << "total size:  " << total_size
       << "\t - " << total_size * 1.0 / use << "\n";

  f.close();
}

// void Mutator::ADD_TO_LIBRARY_CORE(IR * ir) {

//   unsigned long p_hash = hash(ir->to_string());
//   NODETYPE p_type = ir->type_;
//   NODETYPE left_type = kEmpty, right_type = kEmpty;

//   //update library_2D
//   if(ir_libary_2D_hash_[p_type].find(p_hash) != 
//       ir_libary_2D_hash_[p_type].end())
//     return;

//   ir_libary_2D_hash_[p_type].insert(p_hash);
//   ir_libary_2D_[p_type].push_back(DEEP_COPY(ir));

//   if(ir->left_) {

//     left_type = ir->left_->type_;
//     ADD_TO_LIBRARY_CORE(ir->left_);
//   }

//   if(ir->right_) {

//     right_type = ir->right_->type_;
//     ADD_TO_LIBRARY_CORE(ir->right_);
//   }

//   //update right_lib, left_lib
//   if(ir->right_ && ir->left_){

//     right_lib[right_type].push_back(DEEP_COPY(ir->left_));
//     left_lib[left_type].push_back(DEEP_COPY(ir->right_));
//   }

//   //update library_3D
//   //set<unsigned long> &hash_map = ir_libary_3D_hash_[left_type][right_type];
//   //if(hash_map.find(p_hash) != hash_map.end()){
//   //  return;
//   //}

//   //ir_libary_3D_hash_[left_type][right_type].insert(p_hash);
//   //ir_libary_3D_[left_type][right_type].push_back(DEEP_COPY(ir));

//   return;
// }

unsigned long Mutator::hash(string sql){ 
  return fucking_hash(sql.c_str(), sql.size());
}

unsigned long Mutator::hash(IR * root){
  return this->hash(root->to_string());
}

void Mutator::debug(IR *root){
  cout << get_string_by_type(root->type_) << endl;
  if(root->left_) debug(root->left_);
  if(root->right_) debug(root->right_);
}


Mutator::~Mutator(){
  cout << "HERE" << endl;
  // delete ir_libary_3D_
  //for(auto &i: ir_libary_3D_){
  //  for(auto &j: i.second){
  //    for(auto &ir: j.second){
  //      deep_delete(ir);
  //    }
  //  }
  //}

  //delete ir_libary_2D_
  //for(auto &i: ir_libary_2D_){
  //  for(auto &ir: i.second){
  //    deep_delete(ir);
  //  }
  //}

  // delete the real ir copy
  // for (auto &ir : real_ir_set)
  //   deep_delete(ir);

  /* Delete the real_ir_set_str vector. */
  real_ir_set_str.clear();

  //delete left_lib
  //for(auto &i: left_lib){
  //  for(auto &ir: i.second){
  //    deep_delete(ir);
  //  }
  //}

  //delete right_lib
  //for(auto &i: right_lib){
  //  for(auto &ir: i.second){
  //    deep_delete(ir);
  //  }
  //}
}



void Mutator::fix_one(map<IR*, set<IR*>> &graph, IR* fixed_key, set<IR*> &visited){
  if(fixed_key->id_type_ == id_create_table_name){
    string tablename = fixed_key->str_val_;
    auto &colums = m_tables[tablename];
    for(auto &val: graph[fixed_key]){
      if(val->id_type_ == id_create_column_name){
        string new_column = gen_id_name();
        colums.push_back(new_column);
        val->str_val_ = new_column;
        visited.insert(val);
      }else if(val->id_type_ == id_top_table_name){
        val->str_val_ = tablename;
        visited.insert(val);
        fix_one(graph, val, visited);
      }
    }
  }
  else if(fixed_key->id_type_ == id_top_table_name){
    string tablename = fixed_key->str_val_;
    auto &colums = m_tables[tablename];

    for(auto &val: graph[fixed_key]){
      if(val->id_type_ == id_column_name){
        val->str_val_ = vector_rand_ele(colums);
        visited.insert(val);
      }else if(val->id_type_ == id_table_name){
        val->str_val_ = tablename;
        visited.insert(val);
      }else if(val->id_type_ == id_index_name){
        string new_index = gen_id_name();
        val->str_val_ = new_index;
        m_tables[new_index] = m_tables[tablename];
        v_table_names.push_back(new_index);
      }
    }
  }
}

void Mutator::fix_graph(map<IR*, set<IR*>> &graph, IR* root, vector<IR*> &ordered_ir){
  set<IR*> visited;

  reset_database();
  for(auto ir: ordered_ir){
    auto iter = make_pair(ir, graph[ir]);

    if(visited.find(iter.first) != visited.end()){
      continue;
    }
    visited.insert(iter.first);
    if(iter.second.empty()){
      if(iter.first->id_type_ == id_column_name){
        string tablename = vector_rand_ele(v_table_names);
        auto &colums = m_tables[tablename];
        iter.first->str_val_ = vector_rand_ele(colums);
        continue;
      }
    }
    if(iter.first->id_type_ == id_create_table_name || iter.first->id_type_ == id_top_table_name){
      if(iter.first->id_type_ == id_create_table_name ){
        string new_table_name = gen_id_name();
        v_table_names.push_back(new_table_name);
        iter.first->str_val_ = new_table_name;
      }else{
        iter.first->str_val_ = vector_rand_ele(v_table_names);

      }
      fix_one(graph, iter.first, visited);
    }
  }

}


/* tranverse ir in the order: _right ==> root ==> left_ */
string Mutator::fix(IR * root){

  string res;
  auto * right_ = root->right_, * left_ = root->left_;
  auto * op_ = root->op_;
  auto type_ = root->type_;
  auto str_val_ = root->str_val_;
  auto f_val_ = root->f_val_;
  auto int_val_ = root->int_val_;
  auto id_type_ = root->id_type_;

  string tmp_right;
  if(right_ != NULL)
    tmp_right = fix(right_);

  if(type_ == kIdentifier && (id_type_ == id_database_name || id_type_ == id_schema_name)){
    if(get_rand_int(2) == 1)
      return string("main");
    else
      return string("temp");
  }



  if(type_ == kCmdPragma){  
    string res = "PRAGMA ";
    int lib_size = cmds_.size();
    string key = "";
    if ( lib_size != 0 ){
      key = cmds_[get_rand_int(lib_size)];
      res += key;
    } else {
      return "";
    }

    int value_size = m_cmd_value_lib_[key].size();
    string value = m_cmd_value_lib_[key][get_rand_int(value_size)];
    if(!value.compare("_int_")){
      value = string("=") + to_string(value_libary[get_rand_int(value_libary.size())]);
    }
    else if(!value.compare("_empty_")){
      value = "";
    }
    else if(!value.compare("_boolean_")){
      if(get_rand_int(2) == 0)
        value = "=false";
      else
        value = "=true";
    }
    else{
      value = "=" + value;
    }
    if(!value.empty()) res += value + ";";
    return res;
  }

  if(type_ == kFilePath || type_ == kPrepareTargetQuery || type_ == kOptOrderType
      || type_ == kColumnType || type_ == kSetType || type_ == kOptJoinType
      || type_ == kOptDistinct || type_ == kNullLiteral) return str_val_;
  if(type_ == kStringLiteral) {auto s = string_libary[get_rand_int(string_libary.size())];  return "'" + s + "'";}
  if(type_ == kIntLiteral) return std::to_string(value_libary[get_rand_int(value_libary.size())]);
  if(type_ == kFloatLiteral || type_ == kconst_float) return std::to_string(float(value_libary[get_rand_int(value_libary.size())]) + 0.1);
  if(type_ == kconst_str) return string_libary[get_rand_int(string_libary.size())];;
  if(type_ == kconst_int)  return std::to_string(value_libary[get_rand_int(value_libary.size())]);

  if(!str_val_.empty()) return str_val_;

  if(op_!= NULL)
    res += op_->prefix_ + " ";
  if(left_ != NULL)
    res += fix(left_) + " ";
  if( op_!= NULL)
    res += op_->middle_ + " ";
  if(right_ != NULL)
    res += tmp_right + " ";
  if(op_!= NULL)
    res += op_->suffix_;

  trim_string(res);
  return res;
}

unsigned int Mutator::calc_node(IR * root){
  unsigned int res = 0;
  if(root->left_) res += calc_node(root->left_);
  if(root->right_) res += calc_node(root->right_);

  return res + 1;
}

string Mutator::extract_struct2(IR * root){
  static int counter = 0;
  string res;
  auto * right_ = root->right_, * left_ = root->left_;
  auto * op_ = root->op_;
  auto type_ = root->type_;
  auto str_val_ = root->str_val_;

  if(type_ == kColumnName && str_val_ == "*") return str_val_;
  if(type_ == kOptOrderType || type_ == kNullLiteral || type_ == kColumnType || type_ == kSetType || type_ == kOptJoinType || type_ == kOptDistinct) return str_val_;
  if(root->id_type_ != id_whatever && root->id_type_ != id_module_name) {return "x" + to_string(counter++);}
  if(type_ == kPrepareTargetQuery || type_ == kStringLiteral ){
    string str_val = str_val_;
    str_val.erase(std::remove(str_val.begin(), str_val.end(), '\''), str_val.end());
    str_val.erase(std::remove(str_val.begin(), str_val.end(), '"'), str_val.end());
    string magic_string = magic_string_generator(str_val);
    unsigned long h = hash(magic_string);
    if(string_libary_hash_.find(h) == string_libary_hash_.end()){
      string_libary.push_back(magic_string);
      string_libary_hash_.insert(h);

    }
    return "'y'";
  }
  if(type_ == kIntLiteral) {value_libary.push_back(root->int_val_); return "10";}
  if(type_ == kFloatLiteral || type_ == kconst_float) {value_libary.push_back((unsigned long)root->f_val_); return "0.1";}
  if(type_ == kconst_int)  {value_libary.push_back(root->int_val_); return "11";}
  if(type_ == kFilePath) return "'file_name'";

  if(!str_val_.empty()) return str_val_;
  if(op_!= NULL)
    res += op_->prefix_ + " ";
  if(left_ != NULL)
    res += extract_struct2(left_) + " ";
  if( op_!= NULL)
    res += op_->middle_ + " ";
  if(right_ != NULL)
    res += extract_struct2(right_) + " ";
  if(op_!= NULL)
    res += op_->suffix_;

  trim_string(res);
  return res;
}

string Mutator::extract_struct(IR * root){
  static int counter = 0;
  string res;
  auto * right_ = root->right_, * left_ = root->left_;
  auto * op_ = root->op_;
  auto type_ = root->type_;
  auto str_val_ = root->str_val_;

  if(type_ == kColumnName && str_val_ == "*") return str_val_;
  if(type_ == kOptOrderType || type_ == kNullLiteral || type_ == kColumnType || type_ == kSetType || type_ == kOptJoinType || type_ == kOptDistinct) return str_val_;
  if(root->id_type_ != id_whatever && root->id_type_ != id_module_name) {return "x";}
  if(type_ == kPrepareTargetQuery || type_ == kStringLiteral ){
    string str_val = str_val_;
    str_val.erase(std::remove(str_val.begin(), str_val.end(), '\''), str_val.end());
    str_val.erase(std::remove(str_val.begin(), str_val.end(), '"'), str_val.end());
    string magic_string = magic_string_generator(str_val);
    unsigned long h = hash(magic_string);
    if(string_libary_hash_.find(h) == string_libary_hash_.end()){
      string_libary.push_back(magic_string);
      string_libary_hash_.insert(h);

    }
    return "'y'";
  }
  if(type_ == kIntLiteral) {value_libary.push_back(root->int_val_); return "10";}
  if(type_ == kFloatLiteral || type_ == kconst_float) {value_libary.push_back((unsigned long)root->f_val_); return "0.1";}
  if(type_ == kconst_int)  {value_libary.push_back(root->int_val_); return "11";}
  if(type_ == kFilePath) return "'file_name'";

  if(!str_val_.empty()) return str_val_;
  if(op_!= NULL)
    res += op_->prefix_ + " ";
  if(left_ != NULL)
    res += extract_struct(left_) + " ";
  if( op_!= NULL)
    res += op_->middle_ + " ";
  if(right_ != NULL)
    res += extract_struct(right_) + " ";
  if(op_!= NULL)
    res += op_->suffix_;

  trim_string(res);
  return res;
}

void Mutator::add_new_table(IR * root, string &table_name){


  if(root->left_ != NULL)
    add_new_table(root->left_, table_name);

  if(root->right_ != NULL)
    add_new_table(root->right_, table_name);

  //add to table_name_lib_ 
  if(root->type_ == kTableName){
    if(root->operand_num_ == 1){
      table_name = root->left_->str_val_;
    }
    else if(root->operand_num_ == 2){
      table_name = root->left_->str_val_ + "." + root->right_->str_val_;            
    }
  }

  //add to column_name_lib_
  if(root->type_ == kColumnDef){
    auto tmp = root->left_;
    if(tmp->type_ == kIdentifier){
      if(!table_name.empty() && !tmp->str_val_.empty());
      m_tables[table_name].push_back(tmp->str_val_);
      if(find(v_table_names.begin(), v_table_names.end(), table_name) != v_table_names.end())
        v_table_names.push_back(table_name);
    }
  }

}


void Mutator::reset_database(){
  m_tables.clear();    
  v_table_names.clear();
}

int Mutator::try_fix(char* buf, int len, char* &new_buf, int &new_len){
  string sql(buf);
  auto ast = parser(sql);

  new_buf = buf;
  new_len = len;
  if(ast == NULL) return 0;

  vector<IR *> v_ir;
  auto ir_root = ast->translate(v_ir);
  ast->deep_delete();

  if(ir_root == NULL) return 0;
  auto fixed = validate(ir_root);
  deep_delete(ir_root);
  if(fixed.empty()) return 0;

  char * sfixed = (char *)malloc(fixed.size()+1);
  memcpy(sfixed, fixed.c_str(), fixed.size());
  sfixed[fixed.size()] = 0;

  new_buf = sfixed;
  new_len = fixed.size();

  return 1;
}
