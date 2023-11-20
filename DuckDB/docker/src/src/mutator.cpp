#include "../include/mutator.h"
#include "../include/utils.h"


#include <assert.h>
#include <fstream>
#include <cstdio>
#include <climits>
#include <cfloat>
#include <algorithm>
#include <deque>
#include <cstring>
#include <vector>

using namespace std;

set<IR *> Mutator::visited;  // Already validated/fixed node. Avoid multiple fixing.
map<string, vector<string> > Mutator::m_tables;   // Table name to column name mapping.
map<string, vector<string> > Mutator::m_table2index;   // Table name to index mapping.
vector<string> Mutator::v_table_names;  // All saved table names
vector<string> Mutator::v_table_names_single; // All used table names in one query statement.
vector<string> Mutator::v_create_table_names_single; // All table names just created in the current stmt.
vector<string> Mutator::v_alias_names_single; // All alias name local to one query statement.
map<string, vector<string> > Mutator::m_table2alias_single;   // Table name to alias mapping.
map<string, COLTYPE> Mutator::m_column2datatype;   // Column name mapping to column type. 0 means unknown, 1 means numerical, 2 means character_type_, 3 means boolean_type_.
vector<string> Mutator::v_column_names_single; // All used column names in one query statement. Used to confirm literal type.
vector<string> Mutator::v_table_name_follow_single;  // All used table names follow type in one query stmt.
vector<string> Mutator::v_statistics_name; // All statistic names defined in the current stmt.
vector<string> Mutator::v_sequence_name; // All sequence names defined in the current SQL.
vector<string> Mutator::v_view_name; // All saved view names.
vector<string> Mutator::v_constraint_name; // All constraint names defined in the current SQL.
vector<string> Mutator::v_foreign_table_name; // All foreign table names defined inthe current SQL.
vector<string> Mutator::v_create_foreign_table_names_single; // All foreign table names created in the current SQL.
vector<string> Mutator::v_database_name_follow_single; // All used database name follow in the query. Either test_sqlright1 or mysql.

vector<string> Mutator::v_sys_column_name;
vector<string> Mutator::v_sys_catalogs_name;

vector<string> Mutator::v_aggregate_func;
vector<string> Mutator::v_table_with_partition_name;

vector<string> Mutator::v_saved_reloption_str;

vector<int> Mutator::v_int_literals;
vector<double> Mutator::v_float_literals;
vector<string> Mutator::v_string_literals;

map<string, vector<string> > Mutator::m_tables_backup;               // Table name to column name mapping.
map<string, vector<string> > Mutator::m_table2index_backup;          // Table name to index mapping.
vector<string> Mutator::v_table_names_backup;                       // All saved table names
vector<string> Mutator::v_statistics_name_backup;                   // All statistic names defined in the current stmt.
vector<string> Mutator::v_sequence_name_backup;                     // All sequence names defined in the current SQL.
vector<string> Mutator::v_view_name_backup;                         // All saved view names.
vector<string> Mutator::v_constraint_name_backup;                   // All constraint names defined in the current SQL.
vector<string> Mutator::v_foreign_table_name_backup;                // All foreign table names defined inthe current SQL.
vector<string> Mutator::v_table_with_partition_name_backup;
vector<int> Mutator::v_int_literals_backup;
vector<double> Mutator::v_float_literals_backup;
vector<string> Mutator::v_string_literals_backup;

static void collect_ir(IR *root, set<DATATYPE> &type_to_fix,
                       vector<IR *> &ir_to_fix) {
    DATATYPE idtype = root->data_type_;

    if (root->left_) {
        collect_ir(root->left_, type_to_fix, ir_to_fix);
    }

    if (type_to_fix.find(idtype) != type_to_fix.end()) {
        ir_to_fix.push_back(root);
    }

    if (root->right_) {
        collect_ir(root->right_, type_to_fix, ir_to_fix);
    }
}

void Mutator::pre_validate() {
    // Reset components that is local to the one query sequence.
    reset_id_counter();
    reset_data_library();
    reset_data_library_single_stmt();

    /* Experimental: This is the default first statement. CREATE TABLE v1099(c1100 INT); */
    v_table_names.push_back("v1099");
    m_tables["v1099"].push_back("c1100");

    return;
}


vector<IR*> Mutator::pre_fix_transform(IR * root, vector<STMT_TYPE>& stmt_type_vec) {
    // Dump function. Deep copy the passed in statement without doing anything else.
    vector<IR*> all_trans_vec;
    vector<IR*> all_statements_vec = IRWrapper::get_stmt_ir_vec();

    for (IR* cur_stmt : all_statements_vec) {
        IR* trans_IR = cur_stmt->deep_copy();
        all_trans_vec.push_back(trans_IR);
    }

    return all_trans_vec;
}


vector<vector<vector<IR*>>> Mutator::post_fix_transform(vector<IR*>& all_pre_trans_vec, vector<STMT_TYPE>& stmt_type_vec) {
    // Dump function. Deep copy the passed in statement without doing anything else.
    int total_run_count = p_oracle->get_mul_run_num();
    vector<vector<vector<IR*>>> all_trans_vec_all_run;
    for (int run_count = 0; run_count < total_run_count; run_count++){
        all_trans_vec_all_run.push_back(this->post_fix_transform(all_pre_trans_vec, stmt_type_vec, run_count)); // All deep_copied.
    }
    return all_trans_vec_all_run;
}

vector<vector<IR*>> Mutator::post_fix_transform(vector<IR*>& all_pre_trans_vec, vector<STMT_TYPE>& stmt_type_vec, int run_count) {
    // Dump function. Deep copy the passed in statement without doing anything else.
    vector<vector<IR*>> all_post_trans_vec;
    vector<int> v_stmt_to_rov;
    for (int i = 0; i < all_pre_trans_vec.size(); i++) { // Loop through across statements.
        IR* cur_pre_trans_ir = all_pre_trans_vec[i];
        vector<IR*> post_trans_stmt_vec;
        assert(cur_pre_trans_ir != nullptr);

        post_trans_stmt_vec.push_back(cur_pre_trans_ir->deep_copy());

        all_post_trans_vec.push_back(post_trans_stmt_vec);
    }

    return all_post_trans_vec;
}

void Mutator::init_common_string(string filename){
    common_string_library_.push_back("'DO_NOT_BE_EMPTY'");
    if(filename != ""){
        ifstream input_string(filename);
        string s;

        while(getline(input_string, s)){
            common_string_library_.push_back(s);
        }
    }
}

void Mutator::init_value_library(){
    vector<unsigned long> value_lib_init = {0, (unsigned long)LONG_MAX, (unsigned long)ULONG_MAX,
                                            (unsigned long)CHAR_BIT, (unsigned long)SCHAR_MIN, (unsigned long)SCHAR_MAX, (unsigned long)UCHAR_MAX,
                                            (unsigned long)CHAR_MIN, (unsigned long)CHAR_MAX, (unsigned long)MB_LEN_MAX, (unsigned long)SHRT_MIN,
                                            (unsigned long)INT_MIN, (unsigned long)INT_MAX, (unsigned long)SCHAR_MIN, (unsigned long)SCHAR_MIN,
                                            (unsigned long)UINT_MAX, (unsigned long)FLT_MAX, (unsigned long)DBL_MAX, (unsigned long)LDBL_MAX,
                                            (unsigned long)FLT_MIN, (unsigned long)DBL_MIN, (unsigned long)LDBL_MIN };

    value_library_.insert(value_library_.begin(), value_lib_init.begin(), value_lib_init.end());

    return;
}

void Mutator::init_library() {

    // init value_library_
    init_value_library();


    float_types_.insert({kFloatLiteral});
    int_types_.insert(kIntegerLiteral);
    string_types_.insert(kStringLiteral);

    split_stmt_types_.insert(kStmt);
    split_substmt_types_.insert({kSelectClause});
    split_substmt_types_.insert({kSelectNoParens});
    split_substmt_types_.insert({kSelectWithParens});

    // Initialize the common_string_library();
    common_string_library_.push_back("'HELLO'");
    common_string_library_.push_back("'WORLD'");
    common_string_library_.push_back("'test'");
    common_string_library_.push_back("'files'");
    common_string_library_.push_back("'music'");
    common_string_library_.push_back("'score'");
    common_string_library_.push_back("'green'");
    common_string_library_.push_back("'red'");
    common_string_library_.push_back("'right'");
    common_string_library_.push_back("'left'");
    common_string_library_.push_back("'plot'");
    common_string_library_.push_back("'cov'");
    common_string_library_.push_back("'bug'");
    common_string_library_.push_back("'sample'");

}

IR * Mutator::locate_parent(IR * root ,IR * old_ir) {

    if(root->left_ == old_ir || root->right_ == old_ir) return root;

    if(root->left_ != NULL)
        if(auto res = locate_parent(root->left_, old_ir))  return res;
    if(root->right_ != NULL)
        if(auto res = locate_parent(root->right_, old_ir)) return res;

    return NULL;
}



string Mutator::get_a_string() {
    unsigned com_size = common_string_library_.size();
    unsigned lib_size = string_library_.size();
    unsigned double_lib_size = lib_size * 2;

    unsigned rand_int = get_rand_int(double_lib_size + com_size);
    if(rand_int < double_lib_size){
        return string_library_[rand_int >> 1];
    }else{
        rand_int -= double_lib_size;
        return common_string_library_[rand_int];
    }
}

unsigned long Mutator::get_a_val() {
    assert(value_library_.size());
    return vector_rand_ele(value_library_);
}

void Mutator::debug(IR *root){
    this->debug(root, 0);
}

void Mutator::debug(IR* root, unsigned level) {

    for (unsigned i = 0; i < level; i++) {
        cerr << " ";
    }

    cerr << level << ": "
         << get_string_by_ir_type(root->type_) << ": "
         << get_string_by_data_type(root->data_type_) << ": "
         << get_string_by_data_flag(root->data_flag_) << ": "
         << root->uniq_id_in_tree_ << ": "
         << root -> to_string() << ":";
    if (root->op_ != nullptr) {
        cerr << "prefix:" << root->get_prefix() << ":middle:" << root->get_middle() << ":suffix:"
             << root->get_suffix() << ":";
    }
    cerr << endl;

    if (root->left_) {
        debug(root->left_, level + 1);
    }
    if (root->right_) {
        debug(root->right_, level + 1);
    }
}

void Mutator::rollback_data_library() {
    m_tables = m_tables_backup;
    v_table_names = v_table_names_backup;
    m_table2index = m_table2index_backup;
    v_statistics_name = v_statistics_name_backup;
    v_sequence_name = v_sequence_name_backup;
    v_view_name = v_view_name_backup;
    v_constraint_name = v_constraint_name_backup;
    v_foreign_table_name = v_foreign_table_name_backup;
    v_table_with_partition_name = v_table_with_partition_name_backup;
    v_int_literals = v_int_literals_backup;
    v_float_literals = v_float_literals_backup;
    v_string_literals = v_string_literals_backup;
}

void Mutator::backup_data_library() {
    m_tables_backup = m_tables;
    v_table_names_backup = v_table_names;
    m_table2index_backup = m_table2index;
    v_statistics_name_backup = v_statistics_name;
    v_sequence_name_backup = v_sequence_name;
    v_view_name_backup = v_view_name;
    v_constraint_name_backup = v_constraint_name;
    v_foreign_table_name_backup = v_foreign_table_name;
    v_table_with_partition_name_backup = v_table_with_partition_name;
    v_int_literals_backup = v_int_literals;
    v_float_literals_backup = v_float_literals;
    v_string_literals_backup = v_string_literals;
}

void Mutator::reset_data_library(){
    m_tables.clear();
    v_table_names.clear();
    m_table2index.clear();
    m_table2alias_single.clear();
    v_table_names_single.clear();
    v_create_table_names_single.clear();
    v_alias_names_single.clear();
    v_column_names_single.clear();
    v_table_name_follow_single.clear();
    v_statistics_name.clear();
    v_create_foreign_table_names_single.clear();
    v_sequence_name.clear();
    v_view_name.clear();
    v_constraint_name.clear();
    v_foreign_table_name.clear();
    v_table_with_partition_name.clear();
    v_int_literals.clear();
    v_float_literals.clear();
    v_string_literals.clear();
    v_database_name_follow_single.clear();
}

void Mutator::reset_data_library_single_stmt() {
    this->v_table_names_single.clear();
    this->v_create_table_names_single.clear();
    this->v_alias_names_single.clear();
    this->m_table2alias_single.clear();
    this->v_column_names_single.clear();
    this->v_table_name_follow_single.clear();
    this->v_create_foreign_table_names_single.clear();
    this->v_database_name_follow_single.clear();
}

bool Mutator::validate(IR* cur_stmt, bool is_debug_info) {

    reset_data_library_single_stmt();
    backup_data_library();

    if (cur_stmt == NULL) {return false;}

    bool res = true;
    if (cur_stmt->type_ == kStmtblock) {
        vector<IR*> cur_stmt_vec = IRWrapper::get_stmt_ir_vec(cur_stmt);
        for (IR* cur_stmt_tmp : cur_stmt_vec) {
            res = this->validate(cur_stmt_tmp, is_debug_info) && res;
        }
        return res;
    }

    /* All the fixing steps happens here. */
    if (is_debug_info) {
        cerr << "Trying to fix stmt: " << cur_stmt->to_string() << " \n";
    }

    if (!fix_one_stmt(cur_stmt, is_debug_info)) {  // Pass kSpecificStatementType.
        return false;
    }
    if (is_debug_info) {
        cerr << "After fixing: " << cur_stmt->to_string() << " \n\n\n";
    }
    return true;
}

bool Mutator::fix_one_stmt(IR *cur_stmt, bool is_debug_info) {
    bool res = true;

    /* Reset library that is local to one query set. */
    reset_data_library_single_stmt();

    /* m_substmt_save, used for reconstruct the tree. */
    map<IR *, pair<bool, IR*>> m_substmt_save;
    auto substmts = split_to_substmt(cur_stmt, m_substmt_save, split_substmt_types_);

    int substmt_num = substmts.size();
    if (substmt_num > 10) {
        connect_back(m_substmt_save);
        if (is_debug_info) {
            cerr << "Dependency Error: the query is too complicated to fix. Has more than 5 subqueries. \n\n\n";  // Ad-hoc number, just based on intuition.
        }
        return false;
    }

    vector<vector<IR*> > cur_stmt_ir_to_fix;

    for (auto &substmt : substmts) {
        substmt->parent_ = NULL;

        vector<IR*> cur_substmt_ir_to_fix;
        this->fix_preprocessing(substmt, cur_substmt_ir_to_fix);

        cur_stmt_ir_to_fix.push_back(cur_substmt_ir_to_fix);

    }

    res = connect_back(m_substmt_save) && res;

    res = fix_dependency(cur_stmt, cur_stmt_ir_to_fix, is_debug_info) && res;

    return res;
}

/*
** From the outer most parent-statements to the inner most sub-statements.
*/
vector<IR *> Mutator::split_to_substmt(IR *cur_stmt, map<IR *, pair<bool, IR*>> &m_save,
                                       set<IRTYPE> &split_set) {
    vector<IR *> res;
    deque<IR *> bfs;
    bfs.push_back(cur_stmt);

    /* The root cur_stmt should always be saved. */
    res.push_back(cur_stmt);

    while (!bfs.empty()) {
        auto node = bfs.front();
        bfs.pop_front();

        if (node && node->left_)
            bfs.push_back(node->left_);
        if (node && node->right_)
            bfs.push_back(node->right_);

        /* See if current node type is matching split_set. If yes, disconnect node->left and node->right. */
        if (node->left_ &&
            find(split_set.begin(), split_set.end(), node->left_->type_) != split_set.end() &&
            IRWrapper::is_in_subquery(cur_stmt, node->left_)
                ) {
            res.push_back(node->left_);
            pair<bool, IR*> cur_m_save = make_pair<bool, IR*> (true, node->get_left());
            m_save[node] = cur_m_save;
        }
        if (node->right_ &&
            find(split_set.begin(), split_set.end(), node->right_->type_) != split_set.end() &&
            IRWrapper::is_in_subquery(cur_stmt, node->right_)
                ) {
            res.push_back(node->right_);
            pair<bool, IR*> cur_m_save = make_pair<bool, IR*> (false, node->get_right());
            m_save[node] = cur_m_save;
        }
    }

    for (int idx = 1; idx < res.size(); idx++) {
        cur_stmt->detatch_node(res[idx]);
    }

    return res;
}


void
Mutator::fix_preprocessing(IR *stmt_root,
                           vector<IR*> &ordered_all_subquery_ir) {
    set<DATATYPE> type_to_fix = {
            kDataColumnName, kDataTableName, kDataPragmaKey,
            kDataPragmaValue, kDataLiteral,
            kDataIndexName, kDataAliasName,
            kDataSequenceName,
            kDataViewName, kDataSequenceName,
            kDataDatabase, kDataDatabaseFollow, kDataTableNameFollow,
            kDataColumnNameFollow, kDataAliasTableName
            // kDataRelOption, kDataTableNameFollow, kDataColumnNameFollow, kDataStatisticName, kDataForeignTableName, kDataConstraintName,
            // kDataStatisticName
    };
    vector<IR*> ir_to_fix;
    collect_ir(stmt_root, type_to_fix, ordered_all_subquery_ir);
}

bool Mutator::fix_dependency(IR* cur_stmt_root, const vector<vector<IR*>> cur_stmt_ir_to_fix_vec, bool is_debug_info) {

    if (is_debug_info) {
        cerr << "Fix_dependency: cur_stmt_root: " << cur_stmt_root->to_string() << ", size of cur_stmt_ir_to_fix_vec " << cur_stmt_ir_to_fix_vec.size() << ". \n\n\n";
    }

    /* Used to mark the IRs that are needed to be deep_drop(). However, it is not a good idea
     * to deep_drop in the middle of the fix_dependency() function, some ir_to_fix node might have
     * nested IR strcuture. Use this vector to save all IR that needs deep_drop, and drop them at the end
     * of the function.
     * */
    vector<IR*> ir_to_deep_drop;
    vector<IR*> fixed_ir;
    string cur_ir_str = cur_stmt_root->to_string();

    bool is_replace_table = false, is_replace_column = false;
    for (const vector<IR*>& ir_to_fix_vec : cur_stmt_ir_to_fix_vec) {  // Loop for substmt.

        /* kUse of kDatabaseName. We don't care about kDefine and kUndefine of kDatabase */
        for (IR* ir_to_fix : ir_to_fix_vec) {
            if (std::find(fixed_ir.begin(), fixed_ir.end(), ir_to_fix) != fixed_ir.end()) {
                continue;
            }

            // cerr << "DEPENDENCY: In kDataDatabase kUndefine. Get ir_to_fix: " << ir_to_fix->to_string() << get_string_by_ir_type(ir_to_fix->get_ir_type()) << get_string_by_data_flag(ir_to_fix->get_data_flag()) << "\n\n\n";

            // Do not fix kDataDatabase in the drop stmt. Avoid our own database.
            if (
                    (ir_to_fix->get_data_type() == kDataDatabase || ir_to_fix->get_data_type() == kDataDatabaseFollow) &&
                    ir_to_fix->get_data_flag() == kUndefine
                    ) {
                if (is_debug_info) {
                    cerr << "DEPENDENCY: In kDataDatabase kUndefine. Get ir_to_fix: " << ir_to_fix->to_string() << "\n\n\n";
                }
                if (ir_to_fix->get_str_val() == "test_sqlright1" || ir_to_fix->get_str_val() == "fuck") {
                    ir_to_fix->set_str_val("whatever");
                    fixed_ir.push_back(ir_to_fix);
                    continue;
                }
                fixed_ir.push_back(ir_to_fix);
                continue;
            }

            if (
                    (ir_to_fix->data_type_ == kDataDatabaseFollow) &&
                    (ir_to_fix->data_flag_ == kUse)
                    ) {
                if (ir_to_fix->get_str_val() == "memory") {
                    if (get_rand_int(20) < 19) {
                        // In 9.5/10 chances, keep the original mysql.* sql.
                        v_database_name_follow_single.push_back(ir_to_fix->get_str_val());
                        fixed_ir.push_back(ir_to_fix);
                        continue;
                    }
                }
                // not 'mysql', set it to default 'test_sqlright1'
                ir_to_fix->set_str_val("test_parserfuzz");
                v_database_name_follow_single.push_back(ir_to_fix->get_str_val());
                fixed_ir.push_back(ir_to_fix);
                continue;
            }

            // For kUse of kDataDatabase.
            if (
                    (ir_to_fix->data_type_ == kDataDatabase) &&
                    (ir_to_fix->data_flag_ == kUse)
                    ) {
                ir_to_fix->set_str_val("test_parserfuzz");
                fixed_ir.push_back(ir_to_fix);
                continue;
            }

            if (
                    (ir_to_fix->data_type_ == kDataDatabase || ir_to_fix->data_type_ == kDataDatabaseFollow) &&
                    (ir_to_fix->data_flag_ == kDefine)
                    ) {
                ir_to_fix->set_str_val("test_parserfuzz");
                v_database_name_follow_single.push_back(ir_to_fix->get_str_val());
                fixed_ir.push_back(ir_to_fix);
                continue;
            }

            if (
                    (ir_to_fix->data_type_ == kDataDatabase || ir_to_fix->data_type_ == kDataDatabaseFollow) &&
                    (ir_to_fix->data_flag_ == kUndefine)
                    ) {
                ir_to_fix->set_str_val("test_parserfuzz");
                v_database_name_follow_single.push_back(ir_to_fix->get_str_val());
                fixed_ir.push_back(ir_to_fix);
                continue;
            }
        }

        vector<string> v_with_clause_alias_table_name;

        /* Definition of kDataTableName */
        for (IR* ir_to_fix : ir_to_fix_vec){
            if (std::find(fixed_ir.begin(), fixed_ir.end(), ir_to_fix) != fixed_ir.end()) {
                continue;
            }

            if (
                    (
                            ir_to_fix->data_type_ == kDataTableName
                            // ir_to_fix->data_type_ == kDataForeignTableName
                    ) &&
                    (ir_to_fix->data_flag_ == kDefine))
            {
                string new_name = gen_id_name();
                ir_to_fix->str_val_ = new_name;
                fixed_ir.push_back(ir_to_fix);

                v_create_table_names_single.push_back(new_name);

                if (is_debug_info) {
                    cerr << "Dependency: Added to v_table_names: " << new_name << ", in kDataTableName with kDefine or kReplace. \n\n\n";
                    for (string& all_used_name : v_table_names) {
                        cerr << "Dependency: All saved table used names: " << all_used_name << "\n\n\n";
                    }
                }
                is_replace_table = true;
            }
        }

        /* Undefine of kDataTableName */
        for (IR* ir_to_fix : ir_to_fix_vec){
            if (std::find(fixed_ir.begin(), fixed_ir.end(), ir_to_fix) != fixed_ir.end()) {
                continue;
            }

            if (
                    (
                            ir_to_fix->data_type_ == kDataTableName
                    ) &&
                    ir_to_fix->data_flag_ == kUndefine)
            {
                if (v_table_names.size() > 0 ) {
                    string removed_table_name = v_table_names[get_rand_int(v_table_names.size())];
                    v_table_names.erase(std::remove(v_table_names.begin(), v_table_names.end(), removed_table_name), v_table_names.end());
                    v_table_names_single.erase(std::remove(v_table_names_single.begin(), v_table_names_single.end(), removed_table_name), v_table_names_single.end());
                    ir_to_fix->str_val_ = removed_table_name;
                    fixed_ir.push_back(ir_to_fix);
                    if (is_debug_info) {
                        cerr << "Dependency: Removed from v_table_names: " << removed_table_name << ", in kDataTableName with kUndefine \n\n\n";
                    }
                    if (is_replace_table && v_create_table_names_single.size() != 0) {
                        string new_table_name = v_create_table_names_single.front();
                        m_tables[new_table_name] = m_tables[removed_table_name];
                    }
                } else {
                    if (is_debug_info) {
                        cerr << "Dependency Error: Failed to find info in v_table_names, in kDataTableName with kUndefine. \n\n\n";
                    }
                    fixed_ir.push_back(ir_to_fix);
                }
            }
            // else if (
            //   (
            //     ir_to_fix->data_type_ == kDataForeignTableName
            //   ) &&
            //   ir_to_fix->data_flag_ == kUndefine)
            // {
            //   if (v_foreign_table_name.size() > 0 ) {
            //     /* Find table name in the foreign table vector, not normal table vec.  */
            //     string removed_table_name = v_foreign_table_name[get_rand_int(v_foreign_table_name.size())];
            //     v_foreign_table_name.erase(std::remove(v_foreign_table_name.begin(), v_foreign_table_name.end(), removed_table_name), v_foreign_table_name.end());

            //     v_table_names.erase(std::remove(v_table_names.begin(), v_table_names.end(), removed_table_name), v_table_names.end());
            //     v_table_names_single.erase(std::remove(v_table_names_single.begin(), v_table_names_single.end(), removed_table_name), v_table_names_single.end());
            //     ir_to_fix->str_val_ = removed_table_name;
            //     fixed_ir.push_back(ir_to_fix);
            //     if (is_debug_info) {
            //       cerr << "Dependency: Removed from v_foreign_table_names: " << removed_table_name << ", in kDataForeignTableName with kUndefine \n\n\n";
            //     }
            //     if (is_replace_table && v_create_foreign_table_names_single.size() != 0) {
            //       string new_table_name = v_create_foreign_table_names_single.front();
            //       m_tables[new_table_name] = m_tables[removed_table_name];
            //     }

            //   } else {
            //     if (is_debug_info) {
            //       cerr << "Dependency Error: Failed to find info in v_foreign_table_names, in kDataForeignTableName with kUndefine. \n\n\n";
            //     }
            //     /* Unreconized, keep original */
            //     // ir_to_fix->str_val_ = "y";
            //     fixed_ir.push_back(ir_to_fix);
            //   }

            // }
        }

        /* kUse of kDataTableNameFollow */
        for (IR* ir_to_fix : ir_to_fix_vec){
            if (std::find(fixed_ir.begin(), fixed_ir.end(), ir_to_fix) != fixed_ir.end()) {
                continue;
            }

            int follow_id = 0;
            if (ir_to_fix->data_type_ == kDataTableNameFollow && ir_to_fix->data_flag_ == kUse) {
                if (v_database_name_follow_single.size() > follow_id) {

                    if (v_database_name_follow_single[follow_id] == "mysql") {
                        if (is_debug_info) {
                            cerr << "Dependency: Using duckdb default table. Do not change. \n\n\n";
                        }
                        // Keep original
                        fixed_ir.push_back(ir_to_fix);
                        continue;
                    }
                    else {
                        // ir_to_fix->data_type_ = kDataTableName;
                        continue;
                    }

                } else {
                    if (is_debug_info) {
                        cerr << "ERROR: Cannot find the kDatabaseNameFollow, treat it as normal kTableName. \n\n\n";
                    }
                    // ir_to_fix->data_type_ = kDataTableName;
                    continue;
                }
            }

        }


        /* kUse of kDataTableName */
        for (IR* ir_to_fix : ir_to_fix_vec){
            if (std::find(fixed_ir.begin(), fixed_ir.end(), ir_to_fix) != fixed_ir.end()) {
                continue;
            }

            if (ir_to_fix->data_type_ == kDataTableName && ir_to_fix->data_flag_ == kUse) {

                /* If the original SQL is using the system catalogs,
                 * gives just 10% chance to fix it.
                 * */

                string ori_str = ir_to_fix->get_str_val();
                // if (
                //   find(v_sys_catalogs_name.begin(), v_sys_catalogs_name.end(), ori_str) != v_sys_catalogs_name.end()
                //   &&
                //   get_rand_int(10) < 9
                // ) {
                //   continue;
                // }

                /* MySQL doesn't seem to have PARTITION OF clause. Ignore for now. */
                // /* Check whether we are in the PARTITION OF clause, if yes, use the v_table_with_partition_names */
                // if (
                //   IRWrapper::is_ir_in(ir_to_fix, kCreateStmt_30) ||
                //   IRWrapper::is_ir_in(ir_to_fix, kCreateStmt_38) ||
                //   IRWrapper::is_ir_in(ir_to_fix, kCreateForeignTableStmt_7) ||
                //   IRWrapper::is_ir_in(ir_to_fix, kCreateForeignTableStmt_11)
                // ) {
                //   if (is_debug_info) {
                //     cerr << "Dependency: Detected fixing for kUse kTablename in the PARTITION OF clause. \n\n\n";
                //   }
                //   if (v_table_with_partition_name.size() > 0) {
                //     ir_to_fix->set_str_val(vector_rand_ele(v_table_with_partition_name));
                //     fixed_ir.push_back(ir_to_fix);
                //     if (is_debug_info) {
                //       cerr << "Dependency: In kUse of kTableName, use table name with partitioning: " << ir_to_fix->get_str_val() << ". \n\n\n";
                //     }
                //     continue;
                //   } else {
                //     if (is_debug_info) {
                //       cerr << "Dependency Error: In kUse of kTableName, cannot find table names with partitioning. \n\n\n";
                //     }
                //     /* In this error case, 20% use original */
                //     if(get_rand_int(5) < 1) {
                //       fixed_ir.push_back(ir_to_fix);
                //       continue;
                //     }
                //   }
                // }

                // /* Give 5% chances, use system catalogs tables */
                // if (get_rand_int(20) < 1) {
                //   ir_to_fix->str_val_ = vector_rand_ele(v_sys_catalogs_name);
                //   if (is_debug_info) {
                //     cerr << "Dependency: In the context of kUsed table, we use system_catalog table with table_name: " << ir_to_fix->str_val_ << ". \n\n\n";
                //   }
                //   continue;
                // }

                if (v_table_names.size() == 0 && v_table_names_single.size() == 0 && v_create_table_names_single.size() == 0) {
                    if (is_debug_info) {
                        cerr << "Dependency Error: Failed to find info in v_table_names and v_create_table_names_single, in kDataTableName with kUse. \n\n\n";
                    }
                    fixed_ir.push_back(ir_to_fix);
                    continue;
                }
                string used_name = "";
                if (v_table_names.size() != 0) {
                    used_name = v_table_names[get_rand_int(v_table_names.size())];
                } else if (v_table_names_single.size() != 0){
                    used_name = v_table_names_single[get_rand_int(v_table_names_single.size())];
                } else {
                    used_name = v_create_table_names_single[get_rand_int(v_create_table_names_single.size())];
                }
                ir_to_fix->str_val_ = used_name;
                fixed_ir.push_back(ir_to_fix);
                v_table_names_single.push_back(used_name);
                if (is_debug_info) {
                    cerr << "Dependency: In the context of kUsed table, we got table_name: " << used_name << ". \n\n\n";
                    for (string& all_used_name : v_table_names) {
                        cerr << "Dependency: All saved table used names: " << all_used_name << "\n\n\n";
                    }
                }

                // TODO:: CREATE TABLE LIKE TABLE statements.
//        /* For Create Table Like Table stmts. */
//        if (cur_stmt_root->get_ir_type() == kCreateStatement) {
//
//          // For kCreateTableStmt_7.
//          vector<IR*> v_create_table_stmt_with_like = IRWrapper::get_ir_node_in_stmt_with_type(cur_stmt_root, kCreateTableStmt_7, false);
//          for (IR* create_table_stmt_with_like : v_create_table_stmt_with_like) {
//            IR* create_table_stmt = create_table_stmt_with_like->get_parent();
//
//            if (create_table_stmt && IRWrapper::is_ir_in(ir_to_fix, create_table_stmt)) {
//              if (v_create_table_names_single.size() > 0) {
//                string newly_create_table_str = v_create_table_names_single.front();
//                m_tables[newly_create_table_str] = m_tables[ir_to_fix->get_str_val()];
//              }
//            }
//          }
//          // For kCreateTableStmt_9
//          v_create_table_stmt_with_like.clear();
//          v_create_table_stmt_with_like = IRWrapper::get_ir_node_in_stmt_with_type(cur_stmt_root, kCreateTableStmt_9, false);
//          for (IR* create_table_stmt_with_like : v_create_table_stmt_with_like) {
//            IR* create_table_stmt = create_table_stmt_with_like->get_parent();
//
//            if (create_table_stmt && IRWrapper::is_ir_in(ir_to_fix, create_table_stmt)) {
//              if (v_create_table_names_single.size() > 0) {
//                string newly_create_table_str = v_create_table_names_single.front();
//                m_tables[newly_create_table_str] = m_tables[ir_to_fix->get_str_val()];
//              }
//            }
//          }
//
//        }  // Finished Create Table LIKE table stmts fixing. */

            }
        }

        /* kDefine of kDataViewName. */
        for (IR* ir_to_fix : ir_to_fix_vec) {
            if (std::find(fixed_ir.begin(), fixed_ir.end(), ir_to_fix) != fixed_ir.end()) {
                continue;
            }

            if (ir_to_fix->data_type_ == kDataViewName && ir_to_fix->data_flag_ == kDefine) {
                string new_view_name_str = gen_view_name();
                ir_to_fix->set_str_val(new_view_name_str);
                fixed_ir.push_back(ir_to_fix);

                v_create_table_names_single.push_back(new_view_name_str);
                v_view_name.push_back(new_view_name_str);

                if(is_debug_info) {
                    cerr << "Dependency: In kDefine of kDataViewName, generating view name: " << new_view_name_str << "\n\n\n";
                }
            }
        }

        /* kUndefine of kDataViewName. */
        for (IR* ir_to_fix : ir_to_fix_vec) {
            if (std::find(fixed_ir.begin(), fixed_ir.end(), ir_to_fix) != fixed_ir.end()) {
                continue;
            }

            if (ir_to_fix->data_type_ == kDataViewName && ir_to_fix->data_flag_ == kUndefine) {
                if (!v_view_name.size()) {
                    if (is_debug_info) {
                        cerr << "Dependency Error: In kUndefine of kDataViewname, cannot find view name defined before. \n\n\n";
                    }
                    fixed_ir.push_back(ir_to_fix);
                    continue;
                }
                string view_to_rov_str = vector_rand_ele(v_view_name);
                ir_to_fix->set_str_val(view_to_rov_str);
                fixed_ir.push_back(ir_to_fix);

                remove(v_view_name.begin(), v_view_name.end(), view_to_rov_str);
                remove(v_table_names.begin(), v_table_names.end(), view_to_rov_str);
                remove(v_create_table_names_single.begin(), v_create_table_names_single.end(), view_to_rov_str);

                if(is_debug_info) {
                    cerr << "Dependency: In kUndefine of kDataViewName, removing view name: " << view_to_rov_str << "\n\n\n";
                }
            }

            /* kUse of kDataViewName */
            if (ir_to_fix->data_type_ == kDataViewName && ir_to_fix->data_flag_ == kUse) {
                if (!v_view_name.size()) {
                    if (is_debug_info) {
                        cerr << "Dependency Error: In kUndefine of kDataViewname, cannot find view name defined before. \n\n\n";
                    }
                    continue;
                }
                string view_str = vector_rand_ele(v_view_name);
                ir_to_fix->set_str_val(view_str);
                fixed_ir.push_back(ir_to_fix);
                v_table_names_single.push_back(view_str);

                if(is_debug_info) {
                    cerr << "Dependency: In kUse of kDataViewName, using view name: " << view_str << "\n\n\n";
                }
            }
        }

        /* Fix of kAliasTableName.  */
        for (IR* ir_to_fix : ir_to_fix_vec) {
            if (std::find(fixed_ir.begin(), fixed_ir.end(), ir_to_fix) != fixed_ir.end()) {
                continue;
            }

            if (ir_to_fix->data_type_ == kDataAliasTableName && ir_to_fix->data_flag_ == kDefine) {
                string new_alias_table_name_str = gen_alias_name();
                ir_to_fix->set_str_val(new_alias_table_name_str);
                fixed_ir.push_back(ir_to_fix);

                if (IRWrapper::is_ir_in(ir_to_fix, kWithClause)) {
                    v_with_clause_alias_table_name.push_back(new_alias_table_name_str);
                } else {
                    v_table_names_single.push_back(new_alias_table_name_str);
                }

                if(is_debug_info) {
                    cerr << "Dependency: In kDefine of kDataAliasTableName, generating alias table name: " << new_alias_table_name_str << "\n\n\n";
                }
            }
        }

        /* Fix of kAlias name. */
        int alias_idx = 0;
        for (IR* ir_to_fix : ir_to_fix_vec) {
            if (std::find(fixed_ir.begin(), fixed_ir.end(), ir_to_fix) != fixed_ir.end()) {
                continue;
            }

            /* Assume all kAlias are alias to Table name.  */
            if (ir_to_fix->data_type_ == kDataAliasTableName) {

                string closest_table_name = "";

                if (
                        v_with_clause_alias_table_name.size() != 0
                        ) {
                    closest_table_name = vector_rand_ele(v_with_clause_alias_table_name);
                    if (is_debug_info) {
                        cerr << "Dependency: In with clause kAlias Name Defined, find table name: " << closest_table_name << ". \n\n\n" << endl;
                    }
                }
                else if (v_table_names_single.size() != 0) {
                    if (alias_idx < v_table_names_single.size()) {
                        closest_table_name = v_table_names_single[alias_idx];
                        alias_idx++;
                    } else {
                        closest_table_name = v_table_names_single[get_rand_int(v_table_names_single.size())];
                    }
                    if (is_debug_info) {
                        cerr << "Dependency: In kAlias Name Defined, find table name: " << closest_table_name << ". \n\n\n" << endl;
                    }
                } else if (v_create_table_names_single.size() != 0) {
                    closest_table_name = v_create_table_names_single[0];
                    if (is_debug_info) {
                        cerr << "Dependency: In kAlias defined, find newly declared table name: " << closest_table_name << ". \n\n\n" << endl;
                    }
                } else if (v_table_names.size() != 0) {
                    closest_table_name = v_table_names[get_rand_int(v_table_names.size())];
                    if (is_debug_info) {
                        cerr << "Dependency Error: In defined of kDataAliasName, cannot find v_table_names_single. Thus find from v_table_name instead. Use table name: " << closest_table_name << ". \n\n\n" << endl;
                    }
                }

                if (closest_table_name == "" || closest_table_name == "x" || closest_table_name == "y") {
                    if (is_debug_info) {
                        cerr << "Dependency Error: Cannot find the closest_table_name from the query. Error cloest_table_name is: " << closest_table_name << ". In kAliasName Define. \n\n\n";
                    }
                    /* Randomly set an alias name to the defined table.
                     * And ignore the mapping for the moment
                     * */
                    string alias_name = gen_alias_name();
                    ir_to_fix->str_val_ = alias_name;
                    v_alias_names_single.push_back(alias_name);
                    fixed_ir.push_back(ir_to_fix);
                    continue;
                    // return false;
                }

                /* Found the table name that matched to the alias, now generate the alias and save it.  */
                string alias_name = gen_alias_name();
                ir_to_fix->set_str_val(alias_name);
                vector<string>& cur_mapped_alias_vec = m_table2alias_single[closest_table_name];
                cur_mapped_alias_vec.push_back(alias_name);
                v_alias_names_single.push_back(alias_name);
                fixed_ir.push_back(ir_to_fix);

                if (is_debug_info) {
                    cerr << "Dependency: In kAlias defined, generates: " << alias_name << " mapping to: " << closest_table_name << ". \n\n\n" << endl;
                }
            }
        }


        /* kDefine and kReplace of kDataColumnName */
        for (IR* ir_to_fix : ir_to_fix_vec){
            if (std::find(fixed_ir.begin(), fixed_ir.end(), ir_to_fix) != fixed_ir.end()) {
                continue;
            }

            /* Don't fix values inside the kValueClause. That is not permitted by Postgres semantics.
             * Change it to kDataLiteral, and it would be handled by later kDataLiteral logic.
             * */
            if (cur_stmt_root->get_ir_type() == kInsertStmt && IRWrapper::is_ir_in(ir_to_fix, kInsertColumnList)) {
                ir_to_fix->set_data_type(kDataLiteral);
                ir_to_fix->set_data_flag(kFlagUnknown);
//                fixed_ir.push_back(ir_to_fix);
                continue;
            }

            if (ir_to_fix->data_type_ == kDataColumnName && (ir_to_fix->data_flag_ == kDefine || ir_to_fix->data_flag_ == kReplace)) {
                if (ir_to_fix->data_flag_ == kReplace) {
                    is_replace_column = true;
                }
                string new_name = gen_column_name();
                ir_to_fix->str_val_ = new_name;
                fixed_ir.push_back(ir_to_fix);
                string closest_table_name = "";
                /* Attach the newly generated column name to the table. */
                if (v_create_table_names_single.size() > 0) {
                    /* We have table name that is newly defined. */
                    closest_table_name = v_create_table_names_single[0];
                    if (is_debug_info) {
                        cerr << "Dependency: For newly defined column name: " << new_name << ", we find v_create_table_names_single: " << closest_table_name << "\n\n\n";
                    }
                } else if (v_table_names_single.size() != 0) {
                    /* We cannot find the newly defined table name, see whether there are local table name used, this is typical in ALTER statement.  */
                    closest_table_name = v_table_names_single[0];
                    if (is_debug_info) {
                        cerr << "Dependency: For newly defined column name: " << new_name << ", cannot find v_create_table_names_single, is it in a ALTER statement? We find v_table_names_single: " << closest_table_name << "\n\n\n";
                    }
                } else if (v_table_names.size() != 0){
                    /* This is an ERROR. Cannot find the TABLE name to attach to.
                    ** 80% chance, keep original.
                    ** 20% chance, find any declared table and attached to it. */
                    if (get_rand_int(5) < 4) {
                        /* Keep original */
                        continue;
                    }
                    closest_table_name = v_table_names[get_rand_int(v_table_names.size())];
                    if (is_debug_info) {
                        cerr << "Dependency ERROR: For newly defined column name: " << new_name << ", ERROR finding matched newly created table names. Used previous declared table name: " << closest_table_name << "\n\n\n";
                    }
                }
                if (closest_table_name == "" || closest_table_name == "x" || closest_table_name == "y") {
                    if (is_debug_info) {
                        cerr << "Dependency Error: Cannot find the closest_table_name from the query. ";
                        cerr << "cloest_table_name returns: " << closest_table_name << "In kDataColumnName, kDefine or kReplace. \n\n\n";
                    }
                    // return false;
                    /* Randomly set a name to the defined column.
                     * And ignore the mapping for the moment
                     * */

                    /* Unreconized, keep original */
                    // ir_to_fix->str_val_ = gen_column_name();
                    continue;
                }
                if (is_debug_info) {
                    cerr << "Dependency: For column_name: " << new_name << ", found closest_table_name: " << closest_table_name << ". \n\n\n";
                }
                m_tables[closest_table_name].push_back(new_name);


                /* Next, we save the column type to the mapping */
                if (ir_to_fix->data_flag_ == kDefine) {
                    /* For normal tables, we need to save its column type. */
                    if ( ir_to_fix->get_data_type() == kDataTypeName) {

                        // IR* typename_ir = ir_to_fix ->get_parent() ->get_right();
                        // COLTYPE column_type = typename_ir->typename_ir_get_type();

                        // TODO:: SETUP column type!!!
                        m_column2datatype[new_name] = COLTYPE::UNKNOWN_T;

                    }
                        /* For view, we don't have the obvious type information. Currently treat it as unknown types. */
                    else {
                        m_column2datatype[new_name] = COLTYPE::UNKNOWN_T; // Unknown data type.
                    }
                    if (is_debug_info) {
                        cerr << "Dependency: For newly declared column: " << new_name << ", we map with type: " << m_column2datatype[new_name] << "\n\n\n";
                    }
                } else { // kReplace for type mapping
                    /* This is a ALTER replace column statment. Find the previous column name type, map it to the new one. */
                    vector<IR*> column_name_ir;
                    set<DATATYPE> type_to_search;
                    type_to_search.insert(kDataColumnName);

                    collect_ir(cur_stmt_root, type_to_search, column_name_ir);
                    string prev_column_name = column_name_ir[0]->str_val_;
                    COLTYPE column_data_type = m_column2datatype[prev_column_name];
                    m_column2datatype[new_name] = column_data_type;
                    if (is_debug_info) {
                        cerr << "Dependency: In the context of kReplace column mapping replace, we map the old column name: " << prev_column_name <<
                             "to new column_name: " << new_name << ", mapped type: " << m_column2datatype[new_name] << ". \n\n\n";
                    }
                }
                /* Finished mapping algorithm. */

            } else if (ir_to_fix->data_type_ == kDataColumnName && ir_to_fix->data_flag_ == kUndefine) {
                /* Find the table_name in the query first. */
                string closest_table_name = "";
                if (v_table_names_single.size() != 0) {
                    closest_table_name = v_table_names_single[0];
                    if (is_debug_info) {
                        cerr << "Dependency: For removing kDataColumnName: we find v_create_table_names_single: " << closest_table_name << "\n\n\n";
                    }
                }
                if (closest_table_name == "" || closest_table_name == "x" || closest_table_name == "y") {
                    if (is_debug_info) {
                        cerr << "Dependency Error: Cannot find the closest_table_name from the query. closest_table_name returns: " << closest_table_name << ". In kDataColumnName, kUndefine. \n\n\n";
                    }
                    /* Unreconized, keep original */
                    // return false;
                    fixed_ir.push_back(ir_to_fix);
                    continue;
                }

                if (is_debug_info) {
                    cerr << "Dependency: In kDataColumnName, kUndefine, found closest_table_name: " << closest_table_name << ". \n\n\n";
                }

                vector<string>& column_vec = m_tables[closest_table_name];
                if (column_vec.size() == 0) {
                    if (is_debug_info) {
                        cerr << "Dependency Error: Cannot find the mapped column_vec for table_name: " << closest_table_name << " \n\n\n";
                    }
                    /* Not reconized column name. Keep original */
                    // ir_to_fix->str_val_ = "y";
                    // return false;
                    fixed_ir.push_back(ir_to_fix);
                    continue;
                }
                string removed_column_name = column_vec[get_rand_int(column_vec.size())];
                column_vec.erase(std::remove(column_vec.begin(), column_vec.end(), removed_column_name), column_vec.end());
                ir_to_fix->str_val_ = removed_column_name;
                fixed_ir.push_back(ir_to_fix);

                if (is_debug_info) {
                    cerr << "Dependency: In kDataColumnName, kUndefine, found removed_column_name: " << removed_column_name << ", from closest_table_name: " << closest_table_name << ". \n\n\n";
                }
            }
        } // for (IR* ir_to_fix : ir_to_fix_vec)

        /* kUse of kDataColumnName */
        for (IR* ir_to_fix : ir_to_fix_vec){
            if (std::find(fixed_ir.begin(), fixed_ir.end(), ir_to_fix) != fixed_ir.end()) {
                continue;
            }

            /* Don't fix values inside the kValueClause. That is not permitted by Postgres semantics.
             * Change it to kDataLiteral, and it would be handled by later kDataLiteral logic.
             * */
            if (cur_stmt_root->get_ir_type() == kInsertStmt && IRWrapper::is_ir_in(ir_to_fix, kInsertColumnList)) {
                ir_to_fix->set_data_type(kDataLiteral);
                ir_to_fix->set_data_flag(kFlagUnknown);
                // fixed_ir.push_back(ir_to_fix);
                continue;
            }


            if (ir_to_fix->data_type_ == kDataColumnName &&
                (
                        ir_to_fix->data_flag_ == kUse ||
                        ir_to_fix->data_flag_ == kUseDefine
                )
            ) {

                if (cur_stmt_root->get_ir_type() == kPragmaStmt) {
                    fixed_ir.push_back(ir_to_fix);
                    if (is_debug_info) {
                        cerr << "Do not fix kDataColumnName in the kSet stmt. Skip kUse of kDataColumnName " << ir_to_fix->to_string() << "\n\n\n";
                    }
                    continue;
                }

                if (is_debug_info) {
                    cerr << "Dependency: ori column name: " << ir_to_fix->str_val_ << "\n\n\n";
                    cerr << "In the kDataColumnName with kUse, found v_alias_names_single.size: " << v_alias_names_single.size() << "\n\n\n";
                }
                /* If we are seeing system default columns, 75% skip the fixing and reuse the original.  */
                string ori_str = ir_to_fix->get_str_val();
                if (
                        find(v_sys_column_name.begin(), v_sys_column_name.end(), ori_str) != v_sys_column_name.end() &&
                        get_rand_int(4) >= 1
                        ) {
                    continue;
                } else if (
                    // Do not use alias inside kWithClause
                        !IRWrapper::is_ir_in(ir_to_fix, kWithClause) &&
                        v_alias_names_single.size() > 0 &&
                        ir_to_fix->data_flag_ != kUseDefine  && // Do not use alias in kUseDefine!!!
                        get_rand_int(3) < 2
                        ) {
                    /* We have defined a new alias for column name! use it with 66% percentage. */
                    // cerr << "DEBUG: is in kWithClause: " <<           IRWrapper::is_ir_in(ir_to_fix, kWithClause) << "\n\n\n";
                    ir_to_fix->str_val_ = vector_rand_ele(v_alias_names_single);
                    if (is_debug_info) {
                        cerr << "Dependency: Using alias inside kUse of kColumnName: " << ir_to_fix->str_val_ << ". \n\n\n";
                    }
                    continue;
                }
                // TODO:: Check whether there are system column in MySQL.
                /* Or, assign with system column in 5% chances */
                // else if (get_rand_int(20) < 1){
                //   ir_to_fix->str_val_ = v_sys_column_name[get_rand_int(v_sys_column_name.size())];
                //   continue;
                // }

                string closest_table_name = "";

                // If it is kUseDefine, only look at the table that is just created.
                if (ir_to_fix->data_flag_ == kUseDefine) {
                    if (v_create_table_names_single.size() != 0) {
                        closest_table_name = v_create_table_names_single[0];
                        if (is_debug_info) {
                            cerr << "Dependency: In kUseDefine of kDataColumnName, find newly declared table name: " << closest_table_name << " for column name   origin. \n\n\n" << endl;
                        }
                    } else {
                        if (is_debug_info) {
                            cerr << "Error: In kUseDefine of kDataColumnName, cannot find newly declared table name for column name origin. Fix it as normal kUse. \n\n\n" << endl;
                        }
                        ir_to_fix->data_flag_ = kUse;
                        // fixed_ir.push_back(ir_to_fix);
                        // continue;  // Keep original.
                    }
                }


                if (v_table_names_single.size() != 0 && ir_to_fix->data_flag_ == kUse) {
                    closest_table_name = v_table_names_single[get_rand_int(v_table_names_single.size())];
                    if (is_debug_info) {
                        cerr << "Dependency: In kUse of kDataColumnName, find table name: " << closest_table_name << " for column name origin. \n\n\n" << endl;
                    }
                } else if (v_create_table_names_single.size() != 0  && ir_to_fix->data_flag_ == kUse) {
                    closest_table_name = v_create_table_names_single[0];
                    if (is_debug_info) {
                        cerr << "Dependency: In kUse of kDataColumnName, find newly declared table name: " << closest_table_name << " for column name origin. \n\n\n" << endl;
                    }
                } else if (v_alias_names_single.size() != 0  && ir_to_fix->data_flag_ == kUse) {
                    ir_to_fix->str_val_ = v_alias_names_single[get_rand_int(v_alias_names_single.size())];
                    if (is_debug_info) {
                        cerr << "Dependency: In kUse of kDataColumnName, use alias name as the column name. Use alias name: " << ir_to_fix->str_val_ << " for column name. \n\n\n" << endl;
                    }
                    // Finished assigning column name. continue;
                    fixed_ir.push_back(ir_to_fix);
                    continue;
                } else if (v_table_names.size() != 0  && ir_to_fix->data_flag_ == kUse) {

                    /* This should be an error.
                    ** 80% chances, keep original.
                    ** 20%, use predefined table name.
                    */
                    if (get_rand_int(5) < 4) {
                        fixed_ir.push_back(ir_to_fix);
                        continue;
                    }

                    closest_table_name = v_table_names[get_rand_int(v_table_names.size())];
                    if (is_debug_info) {
                        cerr << "Dependency Error: In kUse of kDataColumnName, cannot find v_table_names_single. Thus find from v_table_name instead. Use table name: " << closest_table_name << " for column name origin. \n\n\n" << endl;
                    }
                }

                if (closest_table_name == "" || closest_table_name == "x" || closest_table_name == "y") {
                    if (is_debug_info) {
                        cerr << "Dependency Error: Cannot find the closest_table_name from the query. Error cloest_table_name is: " << closest_table_name << ". In kDataColumnName, kUse. \n\n\n";
                    }
                    if (v_alias_names_single.size() != 0) {
                        ir_to_fix->str_val_ = vector_rand_ele(v_alias_names_single);
                        if (is_debug_info) {
                            cerr << "Dependency: Using alias inside kUse of kColumnName: " << ir_to_fix->str_val_ << ". \n\n\n";
                        }
                        fixed_ir.push_back(ir_to_fix);
                        continue;
                    }
                    /* Unreconized, keep original */
                    // ir_to_fix->str_val_ = "y";
                    // return false;
                    fixed_ir.push_back(ir_to_fix);
                    continue;
                }

                vector<string>& cur_mapped_column_name_vec = m_tables[closest_table_name];
                if (is_debug_info) {
                    cerr << "Dependency: In kUse of kDataColunName, use origin table name: " << closest_table_name << ". column size is: " << cur_mapped_column_name_vec.size() << ". \n\n\n";
                }
                if (cur_mapped_column_name_vec.size() > 0) {
                    string cur_chosen_column = cur_mapped_column_name_vec[get_rand_int(cur_mapped_column_name_vec.size())];
                    ir_to_fix->str_val_ = cur_chosen_column;
                    fixed_ir.push_back(ir_to_fix);
                    v_column_names_single.push_back(cur_chosen_column);
                    if (is_debug_info) {
                        cerr << "Dependency: In kDataColumnName, kUse, we choose closest_table_name: " << closest_table_name << " and column_name: " << cur_chosen_column << ". \n\n\n";
                    }
                } else {
                    /* Unreconized, keep original */
                    // ir_to_fix->str_val_ = "y";
                    fixed_ir.push_back(ir_to_fix);
                    if (is_debug_info) {
                        cerr << "Dependency Error: In kDataColumnName, kUse, cannot find mapping from table_name" << closest_table_name << ". \n\n\n";
                    }
                }
            }
        }

        /* Fix for kDataTableNameFollow.  */
        for (IR* ir_to_fix : ir_to_fix_vec) {
            if (std::find(fixed_ir.begin(), fixed_ir.end(), ir_to_fix) != fixed_ir.end()) {
                continue;
            }
            if (ir_to_fix->get_data_type() == kDataTableNameFollow) {
                /* This type is used in kDataTableNameFollow . kDataColumnNameFollow. */

                string cur_chosen_table_name = "";
                if (v_table_names_single.size()){
                    cur_chosen_table_name = v_table_names_single[get_rand_int(v_table_names_single.size())];
                } else if (v_create_table_names_single.size()) {
                    cur_chosen_table_name = v_create_table_names_single[get_rand_int(v_create_table_names_single.size())];
                } else if (v_table_names.size()) {
                    if (is_debug_info) {
                        cerr << "Dependency Error: In kDataTableNameFollow, cannot find mapping for cur_chosen_table_name in the local stmt, use v_table_names instead\n\n\n";
                    }
                    cur_chosen_table_name = v_table_names[get_rand_int(v_table_names.size())];
                } else {
                    if (is_debug_info) {
                        cerr << "Dependency Error: In kDataTableNameFollow, cannot find mapping for cur_chosen_table_name. \n\n\n";
                    }
                    fixed_ir.push_back(ir_to_fix);
                    continue;
                }

                /* Save the chosen table name before change it to alias name.  */
                v_table_name_follow_single.push_back(cur_chosen_table_name);

                /* If the chosen table name has alias, use the alias */
                if (m_table2alias_single[cur_chosen_table_name].size()) {
                    cur_chosen_table_name = m_table2alias_single[cur_chosen_table_name][0];
                }

                ir_to_fix->set_str_val(cur_chosen_table_name);
                fixed_ir.push_back(ir_to_fix);

                if (is_debug_info) {
                    cerr << "Dependency: In kDataTableNameFollow, choose table name: " << cur_chosen_table_name << ". \n\n\n";
                }

            }
        }

        /* Fix for kDataColumnNameFollow.  */
        int table_follow_idx = -1;
        for (IR* ir_to_fix : ir_to_fix_vec) {
            if (std::find(fixed_ir.begin(), fixed_ir.end(), ir_to_fix) != fixed_ir.end()) {
                continue;
            }

            if (ir_to_fix->get_data_type() == kDataColumnNameFollow) {
                /* This type is used in kDataTableNameFollow . kDataColumnNameFollow. */
                table_follow_idx++;
                if (table_follow_idx < v_table_name_follow_single.size()) {
                    string cur_chosen_table_name = v_table_name_follow_single[table_follow_idx];
                    vector<string>& v_cur_mapped_column = m_tables[cur_chosen_table_name];
                    if ( !v_cur_mapped_column.size() ) {
                        if (is_debug_info) {
                            cerr << "Dependency Error: In kDataColumnNameFollow, choose table name: " << cur_chosen_table_name << " cannot find mapped column names. \n\n\n";
                        }
                        fixed_ir.push_back(ir_to_fix);
                        continue;
                    }

                    string cur_chosen_column_name = v_cur_mapped_column[get_rand_int(v_cur_mapped_column.size())];
                    ir_to_fix->set_str_val(cur_chosen_column_name);
                    fixed_ir.push_back(ir_to_fix);

                    if (is_debug_info) {
                        cerr << "Dependency: In kDataColumnNameFollow, choose table name: " << cur_chosen_table_name << ", mapped with kDataColumnName:" << cur_chosen_column_name << ". \n\n\n";
                    }

                } else {
                    if (is_debug_info) {
                        cerr << "Dependency Error: In kDataColumnNameFollow, cannot find mapped table_follow names. \n\n\n";
                    }
                    fixed_ir.push_back(ir_to_fix);
                    continue;
                }
            }
        }

        /* Fix of kDataIndex name. */
        for (IR* ir_to_fix : ir_to_fix_vec) {
            if (std::find(fixed_ir.begin(), fixed_ir.end(), ir_to_fix) != fixed_ir.end()) {
                continue;
            }


            if (ir_to_fix->get_data_type() == kDataIndexName) {
                if (ir_to_fix->get_data_flag() == kDefine) {
                    string tmp_index_name = gen_index_name();
                    ir_to_fix->set_str_val(tmp_index_name);
                    fixed_ir.push_back(ir_to_fix);

                    /* Find the table used in this stmt. */
                    if (v_table_names_single.size() != 0) {
                        string tmp_table_name = v_table_names_single[0];
                        m_table2index[tmp_table_name].push_back(tmp_index_name);
                    }
                }
                else if (ir_to_fix->get_data_flag() == kUndefine) {

                    string tmp_index_name = "y";

                    /* Find the table used in this stmt. */
                    if (v_table_names_single.size() != 0) {
                        string tmp_table_name = v_table_names_single[0];
                        vector<string>& v_index_name = m_table2index[tmp_table_name];
                        if (!v_index_name.size()) continue;
                        tmp_index_name = vector_rand_ele(v_index_name);

                        vector<string> tmp_v_index_name;
                        for (string s: v_index_name) {
                            if (s != tmp_index_name) {
                                tmp_v_index_name.push_back(s);
                            }
                        }
                        v_index_name = tmp_v_index_name;
                    } else {
                        for (auto it = m_table2index.begin(); it != m_table2index.end(); it++) {
                            vector<string>& v_index_name = it->second;
                            if (!v_index_name.size()) continue;
                            tmp_index_name = vector_rand_ele(v_index_name);

                            vector<string> tmp_v_index_name;
                            for (string s: v_index_name) {
                                if (s != tmp_index_name) {
                                    tmp_v_index_name.push_back(s);
                                }
                            }
                            v_index_name = tmp_v_index_name;
                        }
                    }
                    if (tmp_index_name != "y") {
                        ir_to_fix->set_str_val(tmp_index_name);
                        fixed_ir.push_back(ir_to_fix);
                    }
                }

                else if (ir_to_fix->get_data_flag() == kUse) {

                    string tmp_index_name = "y";

                    /* Find the table used in this stmt. */
                    if (v_table_names_single.size() != 0) {
                        string tmp_table_name = v_table_names_single[0];
                        vector<string>& v_index_name = m_table2index[tmp_table_name];
                        if (!v_index_name.size()) continue;
                        tmp_index_name = vector_rand_ele(v_index_name);
                    } else {
                        for (auto it = m_table2index.begin(); it != m_table2index.end(); it++) {
                            vector<string>& v_index_name = it->second;
                            if (!v_index_name.size()) continue;
                            tmp_index_name = vector_rand_ele(v_index_name);
                        }
                    }
                    if (tmp_index_name != "y") {
                        ir_to_fix->set_str_val(tmp_index_name);
                        fixed_ir.push_back(ir_to_fix);
                    }
                }
            }
        }


        /* Fix the Literal. */
        int cur_literal_idx = -1;
        for (IR* ir_to_fix : ir_to_fix_vec) {
            if (std::find(fixed_ir.begin(), fixed_ir.end(), ir_to_fix) != fixed_ir.end()) {
                continue;
            }

            if (ir_to_fix->data_type_ == kDataLiteral) {
                fixed_ir.push_back(ir_to_fix);

                if (is_debug_info) {
                    cerr << "Fixing Literals: ori_literals: " << ir_to_fix->get_str_val() << "\n\n\n";
                }

                string ori_str = ir_to_fix->get_str_val();
                // TODO:: Differentiate literal types.
                if (
//                        ir_to_fix->get_ir_type() == kLiteral &&
                        find(common_string_library_.begin(), common_string_library_.end(), ori_str) == common_string_library_.end() &&
                        get_rand_int(10) < 5
                        ) {
                    /* Update unseen string with just 10% chances. (heuristic) */
                    common_string_library_.push_back(ori_str);
                }

                /* Mutate the literals in just 1% of chances is enough.
                * For 99% of chances, keep original.
                * Only for non_select stmts.
                * For select stmts, 1/5 keep original.
                */
                bool is_keep_ori = false;
                if (cur_stmt_root->get_ir_type() != kSelectStmt && get_rand_int(100) < 99) {
                    is_keep_ori = true;
                } else if (cur_stmt_root->get_ir_type() == kSelectStmt && get_rand_int(60) < 10) {
                    is_keep_ori = true;
                }

                if (is_keep_ori) {

                    /* Save the already seen literals */
                    if (ir_to_fix->get_ir_type() == kIntegerLiteral) {
                        string ori_str = ir_to_fix->get_str_val();
                        try {
                            int ori_int = std::stoi(ori_str);
                            v_int_literals.push_back(ori_int);

                            if (is_debug_info) {
                                cerr << "Dependency: Saved int literals: " << ori_str << "\n\n\n";
                            }
                        } catch (...) {
                            continue;
                        }
                    } else if (ir_to_fix->get_ir_type() == kFloatLiteral) {
                        string ori_str = ir_to_fix->get_str_val();
                        try {
                            double ori_float = std::stod(ori_str);
                            v_float_literals.push_back(ori_float);

                            if (is_debug_info) {
                                cerr << "Dependency: Saved float literals: " << ori_str << "\n\n\n";
                            }
                        } catch (...) {
                            continue;
                        }
                    } else if (ir_to_fix->get_ir_type() == kStringLiteral) {
                        v_string_literals.push_back(ir_to_fix->get_str_val());
                        if (is_debug_info) {
                            cerr << "Dependency: Saved string literals: " << ir_to_fix->get_str_val() << "\n\n\n";
                        }

                    }
                    /* Do not save boolean. Not necessary.  */
                    continue;
                }

                if (
                        cur_stmt_root->get_ir_type() == kPragmaStmt
                    // IRWrapper::is_ir_in(ir_to_fix, kGenericSet)
                        ) {
                    /* Do not fix literals used to define reloptions or Postgres configurations.  */
                    continue;
                }

                cur_literal_idx++;
                COLTYPE column_data_type = COLTYPE::UNKNOWN_T;
                if (v_column_names_single.size() > cur_literal_idx) {
                    /* For cases like INSERT INTO v0 (c1, c2) VALUES (1, 2); */
                    string cur_column_name = v_column_names_single[cur_literal_idx];
                    column_data_type = m_column2datatype[cur_column_name];
                    if (is_debug_info) {
                        cerr << "Dependency: For fixing literal idx: " << cur_literal_idx << ", we found column name: " << cur_column_name << ", thus choose column_data_type: " << column_data_type << ". \n\n\n";
                    }
                } else if (v_table_names_single.size() != 0 && m_tables[v_table_names_single[0]].size() > cur_literal_idx) {
                    /* For cases like INSERT INTO v0 VALUES (1, 2); */
                    string cur_column_name = m_tables[v_table_names_single[0]][cur_literal_idx];
                    column_data_type = m_column2datatype[cur_column_name];
                    if (is_debug_info) {
                        cerr << "Dependency: For fixing literal idx: " << cur_literal_idx << ", no column info found, but found table_name: " << v_table_names_single[0] << ", we choose column_data_type: " << column_data_type << ". \n\n\n";
                    }
                } else {
                    column_data_type = COLTYPE::UNKNOWN_T;
                    if (is_debug_info) {
                        cerr << "Dependency Error: For fixing literal idx: " << cur_literal_idx << ". Cannot find any table or column name that help identify the literal type. Randomly choose now. \n\n\n";
                    }
                }

                /* For non-select, 95% chances, choose the original type.
                 * For select, 1/3 chances, keep original type.
                */
                is_keep_ori = false;
                if (cur_stmt_root->get_ir_type() != kSelectStmt && get_rand_int(20) < 19) {
                    is_keep_ori = true;
                } else if (cur_stmt_root->get_ir_type() == kSelectStmt && get_rand_int(50) < 10) {
                    is_keep_ori = true;
                }

                // TODO:: Expand to other literal type in the MySQL.
                if (is_keep_ori) {
                    if (ir_to_fix->get_ir_type() == kIntegerLiteral) {
                        column_data_type = COLTYPE::INT_T;
                    }
                    else if (ir_to_fix->get_ir_type() == kFloatLiteral) {
                        column_data_type = COLTYPE::FLOAT_T;
                    }
                    else if (ir_to_fix->get_ir_type() == kBoolLiteral) {
                        column_data_type = COLTYPE::BOOLEAN_T;
                    }
                    else if (ir_to_fix->get_ir_type() == kStringLiteral) {
                        column_data_type = COLTYPE::STRING_T;
                    }

                    if (is_debug_info) {
                        cerr << "Dependency: For fixing literal idx: " << cur_literal_idx << ", str_val_: " << ir_to_fix->str_val_ << " choose to use the original type for the literal: " << column_data_type << "\n\n\n";
                    }
                }

//                /* If it is used for defining length of column or text, use kIntLiteral */
//                if (
//                        IRWrapper::is_ir_in(ir_to_fix, kDataType)
//                    // IRWrapper::is_ir_in(ir_to_fix, kCharacterWithLength)
//                        ) {
//                    column_data_type = COLTYPE::INT_T;
//                }


                if (column_data_type == COLTYPE::UNKNOWN_T) {
                    // Randomly choose Numerical, Character or Boolean.
                    int rand_int = get_rand_int(4);
                    switch (rand_int) {
                        case 0:
                            column_data_type = COLTYPE::INT_T;
                            break;
                        case 1:
                            column_data_type = COLTYPE::FLOAT_T;
                            break;
                        case 2:
                            column_data_type = COLTYPE::BOOLEAN_T;
                            break;
                        case 3:
                            column_data_type = COLTYPE::STRING_T;
                            break;
                    }
                }

                /* INT */
                if (column_data_type == COLTYPE::INT_T){

//                    /* 'Size of' values, do not use too big values.  */
//                    if (
//                            IRWrapper::is_ir_in(ir_to_fix, kDataType)
//                        // IRWrapper::is_ir_in(ir_to_fix, kCharacterWithLength)
//                            ) {
//                        ir_to_fix->int_val_ = (get_rand_int(100));
//                        if (ir_to_fix->int_val_ < 0) ir_to_fix->int_val_ = - ir_to_fix->int_val_;
//                        ir_to_fix->str_val_ = to_string(ir_to_fix->int_val_);
//
//                        /* Don't save it to v_int_literals, because they are not data literals. */
//                        // v_int_literals.push_back(ir_to_fix->int_val_);
//                        // if (is_debug_info) {
//                        //   cerr << "Dependency: Saved int literals: " << ir_to_fix->int_val_ << "\n\n\n";
//                        // }
//
//                        continue;
//                    }

                    /* In 90% chances, use the already seen int literals. */
                    if (v_int_literals.size() > 0 && get_rand_int(10) < 9 ) {
                        ir_to_fix->int_val_ = vector_rand_ele(v_int_literals);
                        ir_to_fix->str_val_ = std::to_string(ir_to_fix->int_val_);
                        if (is_debug_info) {
                            cerr << "Dependency: Fixing int literal with previously seen int literals: " << ir_to_fix->str_val_ << "\n\n\n";
                        }
                        continue;
                    }

                    /* Preferred to choose a same range number with 4/5 chances */
                    if (get_rand_int(5) < 4) {
                        string ori_str = ir_to_fix->get_str_val();
                        int ori_int = 0;
                        try {
                            ori_int = std::stoi(ori_str);
                        } catch (...) {
                            ori_int = -1;
                        }
                        if (
                                ori_int >= 0 &&
                                ori_int <= 7 &&
                                get_rand_int(5) < 4
                                ) {
                            int tmp = get_rand_int(8);
                            ir_to_fix->str_val_ = to_string(tmp);

                            v_int_literals.push_back(tmp);
                            if (is_debug_info) {
                                cerr << "Dependency: Saved int literals: " << tmp << "\n\n\n";
                            }

                            continue;
                        }

                        if (ori_int < -10000) {
                            if (get_rand_int(2) < 1) {
                                int new_int = get_rand_int(INT_MIN, -10000);
                                ir_to_fix->int_val_ = new_int;
                                ir_to_fix->str_val_ = to_string(new_int);

                                v_int_literals.push_back(new_int);
                                if (is_debug_info) {
                                    cerr << "Dependency: Saved int literals: " << new_int << "\n\n\n";
                                }

                                continue;
                            } else {
                                int new_int = get_rand_int(-10000, 10000);
                                ir_to_fix->int_val_ = new_int;
                                ir_to_fix->str_val_ = to_string(new_int);

                                v_int_literals.push_back(new_int);
                                if (is_debug_info) {
                                    cerr << "Dependency: Saved int literals: " << new_int << "\n\n\n";
                                }

                                continue;
                            }
                        }
                        else if (ori_int < -10) {
                            int new_int = get_rand_int(-10000, -10);
                            ir_to_fix->int_val_ = new_int;
                            ir_to_fix->str_val_ = to_string(new_int);

                            v_int_literals.push_back(new_int);
                            if (is_debug_info) {
                                cerr << "Dependency: Saved int literals: " << new_int << "\n\n\n";
                            }

                            continue;
                        } else if (ori_int < 0) {
                            int new_int = get_rand_int(-10, 0);
                            ir_to_fix->int_val_ = new_int;
                            ir_to_fix->str_val_ = to_string(new_int);

                            v_int_literals.push_back(new_int);
                            if (is_debug_info) {
                                cerr << "Dependency: Saved int literals: " << new_int << "\n\n\n";
                            }

                            continue;
                        } else if (ori_int < 10) {
                            int new_int = get_rand_int(0, 10);
                            ir_to_fix->int_val_ = new_int;
                            ir_to_fix->str_val_ = to_string(new_int);

                            v_int_literals.push_back(new_int);
                            if (is_debug_info) {
                                cerr << "Dependency: Saved int literals: " << new_int << "\n\n\n";
                            }

                            continue;
                        } else if (ori_int < 10000) {
                            int new_int = get_rand_int(0, 10);
                            ir_to_fix->int_val_ = new_int;
                            ir_to_fix->str_val_ = to_string(new_int);

                            v_int_literals.push_back(new_int);
                            if (is_debug_info) {
                                cerr << "Dependency: Saved int literals: " << new_int << "\n\n\n";
                            }

                            continue;
                        } else {
                            if (get_rand_int(2) < 1) {
                                int new_int = get_rand_int(10000, INT_MAX);
                                ir_to_fix->int_val_ = new_int;
                                ir_to_fix->str_val_ = to_string(new_int);

                                v_int_literals.push_back(new_int);
                                if (is_debug_info) {
                                    cerr << "Dependency: Saved int literals: " << new_int << "\n\n\n";
                                }

                                continue;
                            } else {
                                int new_int = get_rand_int(-10000, 10000);
                                ir_to_fix->int_val_ = new_int;
                                ir_to_fix->str_val_ = to_string(new_int);

                                v_int_literals.push_back(new_int);
                                if (is_debug_info) {
                                    cerr << "Dependency: Saved int literals: " << new_int << "\n\n\n";
                                }

                                continue;
                            }
                        }
                    }

                    /* 4/5 chances, use value_library, 1/2, use rand_int up to INT_MAX */
                    if (get_rand_int(5) < 4 && value_library_.size()) {
                        if (value_library_.size() == 0) {
                            FATAL("Error: value_library_ is not being init properly. \n");
                        }
                        ir_to_fix->int_val_ = vector_rand_ele(value_library_);
                        ir_to_fix->str_val_ = to_string(ir_to_fix->int_val_);

                        v_int_literals.push_back(ir_to_fix->int_val_);
                        if (is_debug_info) {
                            cerr << "Dependency: Saved int literals: " << ir_to_fix->int_val_ << "\n\n\n";
                        }

                        continue;
                    } else {
                        ir_to_fix->int_val_ = get_rand_int(INT_MAX);
                        ir_to_fix->str_val_ = to_string(ir_to_fix->int_val_);

                        v_int_literals.push_back(ir_to_fix->int_val_);
                        if (is_debug_info) {
                            cerr << "Dependency: Saved int literals: " << ir_to_fix->int_val_ << "\n\n\n";
                        }

                        continue;
                    }

                    /* Randomly use string format of the int */
                    // if ( get_rand_int(10) < 3 && ir_to_fix->str_val_.find("'") == string::npos) {
                    //   ir_to_fix->str_val_ = "'" + ir_to_fix->str_val_ + "'";
                    // }

                    ir_to_fix->type_ = kIntegerLiteral;
                }

                    /* FLOAT */
                else if (column_data_type == COLTYPE::FLOAT_T) {  // FLOAT

                    /* In 90% chances, use the already seen float literals. */
                    if (v_float_literals.size() > 0 && get_rand_int(10) < 9 ) {
                        ir_to_fix->float_val_ = vector_rand_ele(v_float_literals);
                        ir_to_fix->str_val_ = std::to_string(ir_to_fix->float_val_);
                        if (is_debug_info) {
                            cerr << "Dependency: Fixing float literal with previously seen float literals: " << ir_to_fix->str_val_ << "\n\n\n";
                        }

                        ir_to_fix->type_ = kFloatLiteral;
                        continue;
                    }


                    if (get_rand_int(100) < 95) {
                        /* Give more possibility to mutate on the same flot range */
                        string ori_str = ir_to_fix->get_str_val();
                        double ori_float = 0;
                        try {
                            ori_float = std::stoi(ori_str);
                        } catch (...) {
                            /* Mutate based on random generation */
                            ir_to_fix->float_val_ = (double)(get_rand_double(DBL_MAX));
                            ir_to_fix->str_val_ = to_string(ir_to_fix->float_val_);
                            ir_to_fix->type_ = kFloatLiteral;

                            v_float_literals.push_back(ir_to_fix->float_val_);
                            if (is_debug_info) {
                                cerr << "Dependency: Saved float literals: " << ir_to_fix->float_val_ << "\n\n\n";
                            }

                            ir_to_fix->type_ = kFloatLiteral;
                            continue;
                        }

                        if (ori_float < -10000.0) {
                            if (get_rand_int(2) < 1) {
                                double new_float = get_rand_double(-DBL_MIN, -10000.0);
                                ir_to_fix->float_val_ = new_float;
                                ir_to_fix->str_val_ = to_string(new_float);

                                v_float_literals.push_back(ir_to_fix->float_val_);
                                if (is_debug_info) {
                                    cerr << "Dependency: Saved float literals: " << ir_to_fix->float_val_ << "\n\n\n";
                                }

                                ir_to_fix->type_ = kFloatLiteral;
                                continue;
                            } else {
                                double new_float = get_rand_double(-10000.0, 10000.0);
                                ir_to_fix->float_val_ = new_float;
                                ir_to_fix->str_val_ = to_string(new_float);

                                v_float_literals.push_back(ir_to_fix->float_val_);
                                if (is_debug_info) {
                                    cerr << "Dependency: Saved float literals: " << ir_to_fix->float_val_ << "\n\n\n";
                                }

                                ir_to_fix->type_ = kFloatLiteral;
                                continue;
                            }
                        }
                        else if (ori_float < -10.0) {
                            double new_float = get_rand_double(-10000.0, -10.0);
                            ir_to_fix->float_val_ = new_float;
                            ir_to_fix->str_val_ = to_string(new_float);

                            v_float_literals.push_back(ir_to_fix->float_val_);
                            if (is_debug_info) {
                                cerr << "Dependency: Saved float literals: " << ir_to_fix->float_val_ << "\n\n\n";
                            }

                            ir_to_fix->type_ = kFloatLiteral;
                            continue;
                        } else if (ori_float < 0.0) {
                            double new_float = get_rand_double(-10.0, 0.0);
                            ir_to_fix->float_val_ = new_float;
                            ir_to_fix->str_val_ = to_string(new_float);

                            v_float_literals.push_back(ir_to_fix->float_val_);
                            if (is_debug_info) {
                                cerr << "Dependency: Saved float literals: " << ir_to_fix->float_val_ << "\n\n\n";
                            }

                            ir_to_fix->type_ = kFloatLiteral;
                            continue;
                        } else if (ori_float < 10.0) {
                            double new_float = get_rand_double(0.0, 10.0);
                            ir_to_fix->float_val_ = new_float;
                            ir_to_fix->str_val_ = to_string(new_float);

                            v_float_literals.push_back(ir_to_fix->float_val_);
                            if (is_debug_info) {
                                cerr << "Dependency: Saved float literals: " << ir_to_fix->float_val_ << "\n\n\n";
                            }

                            ir_to_fix->type_ = kFloatLiteral;
                            continue;
                        } else if (ori_float < 10000.0) {
                            double new_float = get_rand_double(10.0, 10000.0);
                            ir_to_fix->float_val_ = new_float;
                            ir_to_fix->str_val_ = to_string(new_float);

                            v_float_literals.push_back(ir_to_fix->float_val_);
                            if (is_debug_info) {
                                cerr << "Dependency: Saved float literals: " << ir_to_fix->float_val_ << "\n\n\n";
                            }

                            ir_to_fix->type_ = kFloatLiteral;
                            continue;
                        } else {
                            if (get_rand_int(2) < 1) {
                                double new_float = get_rand_double(10000.0, DBL_MAX);
                                ir_to_fix->float_val_ = new_float;
                                ir_to_fix->str_val_ = to_string(new_float);

                                v_float_literals.push_back(ir_to_fix->float_val_);
                                if (is_debug_info) {
                                    cerr << "Dependency: Saved float literals: " << ir_to_fix->float_val_ << "\n\n\n";
                                }

                                ir_to_fix->type_ = kFloatLiteral;
                                continue;
                            } else {
                                double new_float = get_rand_double(-10000.0, 10000.0);
                                ir_to_fix->float_val_ = new_float;
                                ir_to_fix->str_val_ = to_string(new_float);

                                v_float_literals.push_back(ir_to_fix->float_val_);
                                if (is_debug_info) {
                                    cerr << "Dependency: Saved float literals: " << ir_to_fix->float_val_ << "\n\n\n";
                                }

                                ir_to_fix->type_ = kFloatLiteral;
                                continue;
                            }
                        }
                    }
                    else {
                        /* Mutate based on random generation */
                        ir_to_fix->float_val_ = (double)(get_rand_double(DBL_MAX));
                        ir_to_fix->str_val_ = to_string(ir_to_fix->float_val_);

                        v_float_literals.push_back(ir_to_fix->float_val_);
                        if (is_debug_info) {
                            cerr << "Dependency: Saved float literals: " << ir_to_fix->float_val_ << "\n\n\n";
                        }

                        ir_to_fix->type_ = kFloatLiteral;
                        continue;

                    }

                }

                    /* BOOLEAN */
                else if (column_data_type == COLTYPE::BOOLEAN_T){
                    if (get_rand_int(100) < 50){
                        ir_to_fix->str_val_ = "TRUE";
                    } else {
                        ir_to_fix->str_val_ = "FALSE";
                    }

                    ir_to_fix->type_ = kBoolLiteral;
                }

                    /* STRING */
                    /* STRING could represent too many types: inet, datetime, or even regular expressions.
                     *
                     */
                else {

                    /* In 90% chances, use the already seen string literals. */
                    if (v_string_literals.size() > 0 && get_rand_int(10) < 9 ) {
                        ir_to_fix->str_val_ = vector_rand_ele(v_string_literals);
                        if (is_debug_info) {
                            cerr << "Dependency: Fixing string literal with previously seen string literals: " << ir_to_fix->str_val_ << "\n\n\n";
                        }
                        continue;
                    }


                    ir_to_fix->str_val_ = get_a_string();

                    v_string_literals.push_back(ir_to_fix->str_val_);
                    if (is_debug_info) {
                        cerr << "Dependency: Fixing string literal with: " << ir_to_fix->str_val_ << "\n\n\n";
                    }

                    ir_to_fix->type_ = kStringLiteral;
                }
            }
        }  /* for (IR* ir_to_fix : ir_to_fix_vec) */

        // /* Fix for reloptions. (Related options. ) and function names.  */
        // for (IR* ir_to_fix : ir_to_fix_vec) {

        //   if (std::find(fixed_ir.begin(), fixed_ir.end(), ir_to_fix) != fixed_ir.end()) {
        //     continue;
        //   }

        //   if (ir_to_fix->get_data_type() == kDataRelOption) {
        //     fixed_ir.push_back(ir_to_fix);

        //     /* See if we have seen this reloption before, if not, save it.  */
        //     string ori_str = ir_to_fix->to_string();
        //     if (
        //       std::find(v_saved_reloption_str.begin(), v_saved_reloption_str.end(), ori_str) == v_saved_reloption_str.end()
        //     ) {
        //       if (is_debug_info) {
        //         cerr << "Dependency: Saving unseen reloption string: " << ori_str << ". \n\n\n";
        //       }
        //       v_saved_reloption_str.push_back(ori_str);
        //     }

        //     // Use original reloptions, in 99% of chances.
        //     if (get_rand_int(100) < 99) {
        //       continue;
        //     }

        //     if (get_rand_int(5) < 4 && v_saved_reloption_str.size() > 0) {
        //       /* If 4/5 chances, rerun previously seen reloptions */
        //       IR* new_reloption_ir = new IR(kReloptionElem, vector_rand_ele(v_saved_reloption_str));
        //       cur_stmt_root->swap_node(ir_to_fix, new_reloption_ir);
        //       ir_to_deep_drop.push_back(ir_to_fix);
        //       if (is_debug_info) {
        //         cerr << "Dependency: In reloption, using previously seen reloption: " << new_reloption_ir->get_str_val() << ". \n\n\n";
        //       }
        //       continue;
        //     }

        //     if(is_debug_info) {
        //       cerr << "Dependency: Fixing kDataRelOption: " << get_string_by_ir_type(ir_to_fix->get_ir_type()) << ", to_string(): " << ir_to_fix->to_string() << " getting rel_option_type: " << ir_to_fix->get_rel_option_type() << "\n\n\n";
        //     }

        //     pair<string, string> reloption_choice;

        //     bool is_reset = RelOptionGenerator::get_rel_option_pair(ir_to_fix->get_rel_option_type(), reloption_choice);

        //     if (!is_reset) {
        //       IR* new_reloption_label = new IR(kReloptionElem, reloption_choice.first);
        //       IR* new_reloption_args = new IR(kReloptionElem, reloption_choice.second);

        //       IR* new_reloption_ir = new IR(kReloptionElem, OP3("", "=", ""), new_reloption_label, new_reloption_args);

        //       /* Replace the old reloption ir to the new one. But only deep_drop it at the end of the fix_dependency.  */
        //       cur_stmt_root->swap_node(ir_to_fix, new_reloption_ir);
        //       /* If nested reloption_elem happens, this will crash the program.
        //       * But I don't think that is a possible case in practice.
        //       * */
        //       ir_to_deep_drop.push_back(ir_to_fix);
        //     } else {
        //       IR* new_reloption_label = new IR(kReloptionElem, reloption_choice.first);
        //       IR* new_reloption_ir = new IR(kReloptionElem, OP3("", "", ""), new_reloption_label);

        //       /* Replace the old reloption ir to the new one. But only deep_drop it at the end of the fix_dependency.  */
        //       cur_stmt_root->swap_node(ir_to_fix, new_reloption_ir);
        //       /* If nested reloption_elem happens, this will crash the program.
        //       * But I don't think that is a possible case in practice.
        //       * */
        //       ir_to_deep_drop.push_back(ir_to_fix);
        //     }

        //   }

        /* Dont' fix for functions for now.  */
        // /* Fixing for functions.  */
        // if (ir_to_fix->get_data_type() == kDataFunctionName) {
        //   if (ir_to_fix->get_data_flag() == kNoModi) {
        //     continue;
        //   }

        //   string cur_func_str = ir_to_fix->get_str_val();

        //   for (string aggr_func : v_aggregate_func) {
        //     if (findStringIn(cur_func_str, aggr_func) || cur_func_str == "x") {
        //       /* This is a aggregate function. Randomly change it to another functions.  */
        //       ir_to_fix->set_str_val(v_aggregate_func[get_rand_int(v_aggregate_func.size())]);
        //       break;
        //     }
        //   }
        // }
        // }

        for (IR* ir_to_fix : ir_to_fix_vec) {
            if (std::find(fixed_ir.begin(), fixed_ir.end(), ir_to_fix) != fixed_ir.end()) {
                continue;
            }

            /* Fix for kDataConstraintName */
            if (ir_to_fix->get_data_type() == kDataConstraintName) {
                fixed_ir.push_back(ir_to_fix);
                if (ir_to_fix->get_data_flag() == kDefine) {
                    // string cur_chosen_name = gen_sequence_name();
                    // ir_to_fix->set_str_val(cur_chosen_name);

                    /* Yu: Do not fix for constraint name for now */
                    string cur_chosen_name = ir_to_fix->get_str_val();
                    v_constraint_name.push_back(cur_chosen_name);
                }

                else if (ir_to_fix->get_data_flag() == kUndefine) {
                    if (!v_constraint_name.size()) continue;
                    string cur_chosen_name = vector_rand_ele(v_constraint_name);
                    ir_to_fix->set_str_val(cur_chosen_name);

                    /* remove the statistic name from the vector */
                    vector<string> v_tmp;
                    for (string& s : v_constraint_name) {
                        if (s != cur_chosen_name) {
                            v_tmp.push_back(s);
                        }
                    }
                    v_constraint_name = v_tmp;
                }

                else if (ir_to_fix->get_data_flag() == kUse) {
                    if (!v_constraint_name.size()) continue;
                    string cur_chosen_name = vector_rand_ele(v_constraint_name);
                    ir_to_fix->set_str_val(cur_chosen_name);
                }
            }

        }


    }  /* for (const vector<IR*>& ir_to_fix_vec : cur_stmt_ir_to_fix_vec) */


    // /* Check whether the table is in the context of TABLE PARTITIONING */
    // bool is_table_par = false;
    // // First, check kOptPartitionClause
    // vector<IR*> v_opt_par_clause = IRWrapper::get_ir_node_in_stmt_with_type(cur_stmt_root, kOptPartitionClause, false);
    // if (v_opt_par_clause.size() > 0) {
    //   for (IR* opt_par_clause : v_opt_par_clause) {
    //     if (opt_par_clause->get_prefix() == "PARTITION BY") {
    //       is_table_par = true;
    //       break;
    //     }
    //   }
    // }
    // v_opt_par_clause.clear();

    // // Next, check kPartitionSpec
    // vector<IR*> v_par_spec = IRWrapper::get_ir_node_in_stmt_with_type(cur_stmt_root, kPartitionSpec, false);
    // if (v_par_spec.size() > 0) {
    //   is_table_par = true;
    // }

    // if (is_table_par && v_create_table_names_single.size() > 0) {
    //   string new_par_table_name = v_create_table_names_single.front();
    //   v_table_with_partition_name.push_back(new_par_table_name);
    // }



    /* For the newly declared v_table_names_single, save all these newly declared statement to the global v_table_names. */
    v_table_names.insert(v_table_names.end(), v_create_table_names_single.begin(), v_create_table_names_single.end());
    v_foreign_table_name.insert(v_foreign_table_name.end(), v_create_foreign_table_names_single.begin(), v_create_foreign_table_names_single.end());

    /* Reiterate the substmt.
    ** Added missing dependency information that is missing before.
    */
    for (const vector<IR*>& ir_to_fix_vec : cur_stmt_ir_to_fix_vec) {

        /* MySQL doesn't support Inheritance. */
        // /* Added mapping for Inheritance.  */
        // for (IR* ir_to_fix : ir_to_fix_vec) {
        //   if (
        //     ir_to_fix->data_type_ == kDataTableName &&
        //     cur_stmt_root->get_ir_type() == kCreateStmt &&
        //     IRWrapper::is_ir_in(ir_to_fix, kOptInherit) &&
        //     ir_to_fix->data_flag_ == kUse
        //     ) {
        //     if (v_create_table_names_single.size() > 0) {
        //       string cur_new_table_name_str = v_create_table_names_single.front();
        //       string inherit_table_name_str = ir_to_fix->get_str_val();

        //       vector<string>& inherit_m_tables = m_tables[inherit_table_name_str];

        //       for (string col_name : inherit_m_tables) {
        //         m_tables[cur_new_table_name_str].push_back(col_name);
        //       }
        //     }
        //   }
        // }

        for (IR* ir_to_fix : ir_to_fix_vec){
            if (ir_to_fix->data_type_ != kDataTableName && ir_to_fix->data_type_ != kDataViewName) {
                continue;
            }

            /* Add missing mapping for CREATE VIEW stmt.  */
            /* Check whether we are in the CreateViewStatement. If yes, save the column mapping. */
            IR* cur_ir = ir_to_fix;
            bool is_in_create_view = false;
            while (cur_ir != nullptr) {
                if (cur_ir->type_ == kStmtmulti) {
                    break;
                }
                if (cur_ir->type_ == kViewStmt) {
                    is_in_create_view = true;
                    if (is_debug_info) {
                        cerr << "Dependency: We are in a kCreateViewStmt. \n\n\n";
                    }
                    break;
                }

                // /* Yu: Dirty fix for CREATE TABLE PARTITION OF or CREATE TABLE ... AS SELECT ... stmt. */
                // if (
                //   cur_ir_str.find("PARTITION OF") != string::npos &&
                //   cur_ir_str.find("CREATE") != string::npos
                // ) {
                //   is_in_create_view = true;
                //   if (is_debug_info) {
                //     cerr << "Dependency: We are in a CREATE TABLE PARTITION OF. Hack, treat it CREATE VIEW.  \n\n\n";
                //   }
                //   break;
                // }
                if (
                        cur_ir_str.find("CREATE TABLE") != string::npos &&
                        cur_ir_str.find("AS SELECT") != string::npos
                        ) {
                    is_in_create_view = true;
                    if (is_debug_info) {
                        cerr << "Dependency: We are in a CREATE TABLE AS SELECT. Hack, treat it CREATE VIEW.  \n\n\n";
                    }
                    break;
                }

                cur_ir = cur_ir->parent_;
            }
            if (is_in_create_view) {
                /* Added column mapping for CREATE TABLE/VIEW... v0 AS SELECT... statement.
                */
                if (is_debug_info) {
                    cerr << "Dependency: In CREATE VIEW statement, getting cur_stmt_ir_to_fix_vec.size: " << cur_stmt_ir_to_fix_vec.size() << ". \n\n\n";
                }
                // id_column_name should be in the subqueries and already been resolved in the previous loop.
                vector<IR*> all_mentioned_column_vec;
                set<DATATYPE> column_type_set;
                column_type_set.insert(kDataColumnName);
                collect_ir(cur_stmt_root, column_type_set, all_mentioned_column_vec);

                /* Fix: also, add alias name defined here to the table */
                vector<IR*> all_mentioned_alias_vec;
                set<DATATYPE> alias_type_set;
                alias_type_set.insert(kDataAliasName);
                collect_ir(cur_stmt_root, alias_type_set, all_mentioned_alias_vec);

                all_mentioned_column_vec.insert(all_mentioned_column_vec.end(), all_mentioned_alias_vec.begin(), all_mentioned_alias_vec.end());
                all_mentioned_alias_vec.clear();

                if (is_debug_info) {
                    cerr << "Dependency: When building extra mapping for CREATE VIEW AS, collected kDataColumnName.size: " << all_mentioned_column_vec.size() << ". \n\n\n";
                }

                for (const IR* const cur_men_column_ir : all_mentioned_column_vec) {
                    string cur_men_column_str = cur_men_column_ir->str_val_;
                    if (findStringIn(cur_men_column_str, ".")) {
                        cur_men_column_str = string_splitter(cur_men_column_str, ".")[1];
                    }
                    vector<string>& cur_m_table  = m_tables[ir_to_fix->str_val_];
                    if (std::find(cur_m_table.begin(), cur_m_table.end(), cur_men_column_str) == cur_m_table.end()) {
                        m_tables[ir_to_fix->str_val_].push_back(cur_men_column_str);
                        if (is_debug_info) {
                            cerr << "Dependency: Adding mappings: For table/view: " << ir_to_fix->str_val_ << ", map with column: " << cur_men_column_str << ". \n\n\n";
                        }
                    }
                }

                /* For CREATE VIEW x AS SELECT * FROM v0; */
                if (all_mentioned_column_vec.size() == 0) {
                    if (is_debug_info) {
                        cerr << "Dependency: For mapping CREATE VIEW, cannot find column name in the current subqueries. Thus, see if we can find table names, and map from there. \n\n\n";
                    }
                    vector<IR*> all_mentioned_table_vec, all_mentioned_table_kUsed_vec;
                    set<DATATYPE> table_type_set;
                    table_type_set.insert(kDataTableName);
                    collect_ir(cur_stmt_root, table_type_set, all_mentioned_table_vec);
                    for (IR* mentioned_table_ir : all_mentioned_table_vec ) {
                        if (mentioned_table_ir->data_flag_ == kUse) {
                            all_mentioned_table_kUsed_vec.push_back(mentioned_table_ir);
                            if (is_debug_info) {
                                cerr << "Dependency: For mapping CREATE VIEW, getting mentioned table name: " << mentioned_table_ir->str_val_ << ". \n\n\n";
                            }
                        }
                    }
                    for (IR* cur_men_tablename_ir : all_mentioned_table_kUsed_vec) {
                        string cur_men_tablename_str = cur_men_tablename_ir->str_val_;
                        const vector<string>& cur_men_column_vec = m_tables[cur_men_tablename_str];
                        for (const string& cur_men_column_str : cur_men_column_vec) {
                            vector<string>& cur_m_table  = m_tables[ir_to_fix->str_val_];
                            if (std::find(cur_m_table.begin(), cur_m_table.end(), cur_men_column_str) == cur_m_table.end()) {
                                m_tables[ir_to_fix->str_val_].push_back(cur_men_column_str);
                                if (is_debug_info) {
                                    cerr << "Dependency: Adding mappings: For table/view: " << ir_to_fix->str_val_ << ", map with column: " << cur_men_column_str << ". \n\n\n";
                                }
                            }
                        }
                    } // for (IR* cur_men_tablename_ir : all_mentioned_table_kUsed_vec)
                } // if (all_mentioned_column_vec.size() == 0)

                /* The extra mapping only need to be done once. Once reach this point, break the loop. */
                break;
            } // if (is_in_create_view)

        } // for (IR* ir_to_fix : ir_to_fix_vec)
    }

    for (IR* ir_to_drop : ir_to_deep_drop) {
        if (ir_to_drop) {
            ir_to_drop->deep_drop();
        }
    }

    return true;
}



/* Original validate function.  */
// bool Mutator::validate(IR * &root){
//     reset_data_library();
//     string sql = root->to_string();
//     IR* ast = parser(sql);
//     if(ast == NULL) return false;

//     root->deep_drop();
//     root = NULL;

//     // vector<IR*> ir_vector;
//     // ast->translate(ir_vector);
//     // ast->deep_delete();

//     // root = ir_vector[ir_vector.size() - 1];
//     root = ast;
//     reset_id_counter();

//     if(fix(root) == false){
//         return false;
//     }

//     return true;
// }

pair<string, string> Mutator::ir_to_string(IR* root, vector<vector<IR*>> all_post_trans_vec, const vector<STMT_TYPE>& stmt_type_vec) {
    // Final step, IR_to_string function.
    string output_str_mark, output_str_no_mark;
    for (int i = 0; i < all_post_trans_vec.size(); i++) { // Loop between different statements.
        vector<IR*> post_trans_vec = all_post_trans_vec[i];
        for (IR* cur_trans_stmt : post_trans_vec) {  // Loop between different transformations.
            string tmp = cur_trans_stmt->to_string();
            output_str_mark += tmp + "; \n";
            output_str_no_mark += tmp + "; \n";
        }
    }
    pair<string, string> output_str_pair =  make_pair(output_str_mark, output_str_no_mark);
    return output_str_pair;
}


vector<IR *> Mutator::split_to_stmt(IR * root, map<IR**, IR*> &m_save, set<IRTYPE> &split_set){
    vector<IR *> res;
    deque<IR *> bfs;
    bfs.push_back(root);

    while(!bfs.empty()){
        auto node = bfs.front();
        bfs.pop_front();

        if(node && node->left_) bfs.push_back(node->left_);
        if(node && node->right_) bfs.push_back(node->right_);

        if(node->left_ && find(split_set.begin(), split_set.end(), node->left_->type_) != split_set.end()){
            res.push_back(node->left_);
            m_save[&node->left_] = node->left_;
            node->left_ = NULL;
        }
        if(node->right_ && find(split_set.begin(), split_set.end(), node->right_->type_) != split_set.end()){
            res.push_back(node->right_);
            m_save[&node->right_] = node->right_;
            node->right_ = NULL;
        }



    }

    if(find(split_set.begin(), split_set.end(), root->type_) != split_set.end())
        res.push_back(root);


    return res;
}


bool Mutator::connect_back(map<IR *, pair<bool, IR*>> &m_save) {
    for (auto &iter : m_save) {
        if (iter.second.first) { // is_left?
            iter.first->update_left(iter.second.second);
        } else {
            iter.first->update_right(iter.second.second);
        }
    }
    return true;
}

static set<IR*> visited;

static bool replace_in_vector(string &old_str, string &new_str, vector<string> & victim){
    for(int i = 0 ; i < victim.size(); i++){
        if(victim[i] == old_str){
            victim[i] = new_str;
            return true;
        }
    }
    return false;
}

static bool remove_in_vector(string &str_to_remove, vector<string> & victim){
    for(auto iter = victim.begin(); iter != victim.end(); iter ++ ){
        if(*iter == str_to_remove){
            victim.erase(iter);
            return true;
        }
    }
    return false;
}

static IR* search_mapped_ir(IR* ir, DATATYPE type){
    vector<IR*> to_search;
    vector<IR*> backup;
    to_search.push_back(ir);
    while(!to_search.empty()){
        for(auto i: to_search){
            if(i->data_type_ == type){
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


IR * Mutator::find_closest_node(IR * stmt_root, IR * node, DATATYPE type){
    auto cur = node;
    while(true){
        auto parent = locate_parent(stmt_root, cur);
        if(!parent) break;
        bool flag = false;
        while(parent->left_ == NULL || parent->right_ == NULL){
            cur = parent;
            parent = locate_parent(stmt_root, cur);
            if(!parent){
                flag = true;
                break;
            }
        }
        if(flag) return NULL;

        auto search_root = parent->left_ == cur? parent->right_:parent->left_;
        auto res = search_mapped_ir(search_root, type);
        if(res) return res;

        cur = parent;
    }
    return NULL;
}

string Mutator::extract_struct(IR *root) {
    string res = "";
    _extract_struct(root);
    res = root->to_string();
    trim_string(res);
    return res;
}

void Mutator::_extract_struct(IR *root) {

    if (root->get_data_flag() == kNoModi) {return;}
    if (root->get_data_type() == kDataFunctionName) {return;}
    if (root->get_data_type() == kDataFixLater) {return;}

    auto type = root->type_;
    if (root->left_) {
        extract_struct(root->left_);
    }
    if (root->right_) {
        extract_struct(root->right_);
    }

    if (root->is_empty()) {
        return;
    }

    if (root->get_ir_type() == kIntegerLiteral ) {
        if ( root->str_val_ != "") {
            root->int_val_ = 0;
            root->str_val_ = "0";
            return;
        }
    } else if (root->get_ir_type() == kFloatLiteral && root->str_val_ != "") {
        root->float_val_ = 0.0;
        root->str_val_ = "0.0";
        return;
    } else if (root->get_ir_type() == kStringLiteral && root->str_val_ != "") {
        root->str_val_ = "x";
    }
    // } else if (root->get_ir_type() == kBol) {
    //   root->bool_val_ = true;
    //   root->str_val_ = "true";
    //   return;
    // }


    if (root->left_ || root->right_ || root->data_type_ == kDataFunctionName)
        return;

    if (root->data_type_ != kDataFunctionName && root->str_val_ != "") {

        root->str_val_ = "x";
        return;
    }

    // if (string_types_.find(type) != string_types_.end()) {
    //   root->str_val_ = "x";
    // } else if (int_types_.find(type) != int_types_.end()) {
    //   root->int_val_ = 1;
    // } else if (float_types_.find(type) != float_types_.end()) {
    //   root->float_val_ = 1.0;
    // }
}

string Mutator::rsg_generate_valid(const string type) {

    for (int i = 0; i < 100; i++) {
        string tmp_query_str = rsg_generate(type) + ";";
#ifdef DEBUG
        cerr << "\n\n\n" << type << ", Getting tmp_query_str: " << tmp_query_str << "\n\n\n";
#endif
        vector<IR *> ir_vec = this->parse_query_str_get_ir_set(tmp_query_str);
        if (ir_vec.size() == 0) {
#ifdef DEBUG
            cerr << "\n\n\n" << type << ", getting tmp_query_str: " << tmp_query_str << "\n";
      cerr << "Rejected. \n\n\n";
#endif
//      cerr << "\n\n\nrsg_generate_valid empty. \n\n\n";
            this->rsg_exec_clear_chosen_expr();
            continue;
        }
//        fix_common_rsg_errors(ir_vec.back());
        tmp_query_str = ir_vec.back()->to_string();
        ir_vec.back()->deep_drop();

#ifdef DEBUG
        cerr << "\n\n\n" << type << ", returned tmp-query-str: " << tmp_query_str << "\n\n\n";
#endif
        return tmp_query_str;
    }

    return "";
}

//bool Mutator::add_missing_create_table_stmt(IR* ir_root) {
//    /* Only accept ir_root as inputs. */
//    if (ir_root->get_ir_type() != kQuery) {
//        return false;
//    }
//
//    // Get Create Stmt. For the beginning.
//    IRWrapper::set_ir_root(ir_root);
//    IR* new_stmt_ir = this->get_ir_with_type(kCreateStatement);
//    if (new_stmt_ir == NULL) {
//        // cerr << "Debug: add_missing_create_table_stmt: Return false because kCreateStmt is NULL. \n\n\n";
//        return false;
//    } else if (new_stmt_ir->get_left() == NULL) {
//        new_stmt_ir->deep_drop();
//        // cerr << "Debug: add_missing_create_table_stmt: Return false because kCreateStmt is NULL. \n\n\n";
//        return false;
//    }
//
//    // // Get INSERT stmt
//    // IRWrapper::set_ir_root(ir_root);
//    // IR* new_stmt_ir_2 = this->get_ir_with_type(kInsertStmt);
//    // if (new_stmt_ir_2 == NULL) {
//    //   // cerr << "Debug: add_missing_create_table_stmt: Return false because kInsertStmt is NULL. \n\n\n";
//    //   new_stmt_ir->deep_drop();
//    //   return false;
//    // } else if (new_stmt_ir_2->get_left() == NULL) {
//    //   new_stmt_ir->deep_drop();
//    //   new_stmt_ir_2->deep_drop();
//    //   // cerr << "Debug: add_missing_create_table_stmt: Return false because kInsertStmt is NULL. \n\n\n";
//    //   return false;
//    // }
//
//    // // Get CREATE INDEX stmt
//    // IRWrapper::set_ir_root(ir_root);
//    // IR* new_stmt_ir_3 = this->get_ir_with_type(kCreateIndexStmt);
//    // if (new_stmt_ir_3 == NULL) {
//    //   // cerr << "Debug: add_missing_create_table_stmt: Return false because kIndexStmt is NULL. \n\n\n";
//    //   new_stmt_ir->deep_drop();
//    //   new_stmt_ir_2->deep_drop();
//    //   return false;
//    // } else if (new_stmt_ir_3->get_left() == NULL) {
//    //   new_stmt_ir->deep_drop();
//    //   new_stmt_ir_2->deep_drop();
//    //   new_stmt_ir_3->deep_drop();
//    //   // cerr << "Debug: add_missing_create_table_stmt: Return false because kIndexStmt is NULL. \n\n\n";
//    //   return false;
//    // }
//
//    IRWrapper::set_ir_root(ir_root);
//    IRWrapper::append_stmt_at_idx(new_stmt_ir, 0);
//    // IRWrapper::append_stmt_at_idx(new_stmt_ir_2, 1);
//    // IRWrapper::append_stmt_at_idx(new_stmt_ir_3, 2);
//
//
//
//    // // Get Create Stmt, for the end.
//    // IRWrapper::set_ir_root(ir_root);
//    // new_stmt_ir = this->get_ir_with_type(kCreateTableStmt);
//    // if (new_stmt_ir == NULL) {
//    //   // cerr << "Debug: add_missing_create_table_stmt: Return false because kCreateStmt is NULL. \n\n\n";
//    //   return false;
//    // } else if (new_stmt_ir->get_left() == NULL) {
//    //   new_stmt_ir->deep_drop();
//    //   // cerr << "Debug: add_missing_create_table_stmt: Return false because kCreateStmt is NULL. \n\n\n";
//    //   return false;
//    // }
//
//    // // Get INSERT stmt
//    // IRWrapper::set_ir_root(ir_root);
//    // new_stmt_ir_2 = this->get_ir_with_type(kInsertStmt);
//    // if (new_stmt_ir_2 == NULL) {
//    //   // cerr << "Debug: add_missing_create_table_stmt: Return false because kInsertStmt is NULL. \n\n\n";
//    //   new_stmt_ir->deep_drop();
//    //   return false;
//    // } else if (new_stmt_ir_2->get_left() == NULL) {
//    //   // cerr << "Debug: add_missing_create_table_stmt: Return false because kInsertStmt is NULL. \n\n\n";
//    //   new_stmt_ir->deep_drop();
//    //   new_stmt_ir_2->deep_drop();
//    //   return false;
//    // }
//
//    // // Get CREATE INDEX stmt
//    // IRWrapper::set_ir_root(ir_root);
//    // new_stmt_ir_3 = this->get_ir_with_type(kCreateIndexStmt);
//    // if (new_stmt_ir_3 == NULL) {
//    //   // cerr << "Debug: add_missing_create_table_stmt: Return false because kIndexStmt is NULL. \n\n\n";
//    //   new_stmt_ir->deep_drop();
//    //   new_stmt_ir_2->deep_drop();
//    //   return false;
//    // } else if (new_stmt_ir_3->get_left() == NULL) {
//    //   // cerr << "Debug: add_missing_create_table_stmt: Return false because kIndexStmt is NULL. \n\n\n";
//    //   new_stmt_ir->deep_drop();
//    //   new_stmt_ir_2->deep_drop();
//    //   new_stmt_ir_3->deep_drop();
//    //   return false;
//    // }
//
//    // IRWrapper::set_ir_root(ir_root);
//    // IRWrapper::append_stmt_at_end(new_stmt_ir);
//    // IRWrapper::append_stmt_at_end(new_stmt_ir_2);
//    // IRWrapper::append_stmt_at_end(new_stmt_ir_3);
//
//    return true;
//
//}

//bool Mutator::correct_insert_stmt(IR* cur_stmt) {
//    vector<int> table_column_num;
//
//    if (cur_stmt->get_ir_type() == kInsertStatement) {
//
//        vector<IR*> v_table_name_ir = IRWrapper::get_ir_node_in_stmt_with_type(cur_stmt, kIdentifier, false);
//        if (v_table_name_ir.size() == 0) {
//            return false;
//        }
//        string table_name_str = "";
//        for (IR* table_name_ir : v_table_name_ir) {
//            if (table_name_ir->get_data_type() == kDataTableName && table_name_ir->get_data_flag() == kUse) {
//                table_name_str = table_name_ir->str_val_;
//                break;
//            }
//        }
//        if (table_name_str == "") {
//            return false;
//        }
//
//        int cur_used_column_size = m_tables[table_name_str].size();
//
//        int field_num = IRWrapper::get_num_fields_in_stmt(cur_stmt);
//        int values_num = IRWrapper::get_num_kvalues_in_stmt(cur_stmt);
//
//        if (field_num != values_num && field_num != 0) {
//            return false;
//        }
//
//        if (values_num > cur_used_column_size) {
//            for (int i = 0; i < (values_num - cur_used_column_size); i++) {
//                IRWrapper::drop_fields_to_insert_stmt(cur_stmt);
//                IRWrapper::drop_kvalues_to_insert_stmt(cur_stmt);
//            }
//        } else if (values_num < cur_used_column_size) {
//            for (int i = 0; i < (cur_used_column_size - values_num); i++) {
//                IRWrapper::add_fields_to_insert_stmt(cur_stmt);
//                IRWrapper::add_kvalues_to_insert_stmt(cur_stmt);
//            }
//        }
//    }
//
//    return true;
//}
