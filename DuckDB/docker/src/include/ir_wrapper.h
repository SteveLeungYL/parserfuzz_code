#ifndef __IR_WRAPPER_H__
#define __IR_WRAPPER_H__

#include "sql_ir_define.hpp"
#include "../AFL/debug.h"
#include <string>
#include <vector>

using namespace duckdb_libpgquery;
using namespace std;

DATATYPE get_datatype_by_string(string s);
string get_string_by_ir_type(IRTYPE type);
string get_string_by_data_type(DATATYPE type);
string get_string_by_data_flag(DATAFLAG type);

//string get_string_by_data_flag(DATAFLAG type) {
//#define DECLARE_CASE(classname)                                                \
//  if (type == k##classname)                                                       \
//    return #classname;
//    ALLDATAFLAG(DECLARE_CASE);
//#undef DECLARE_CASE
//    return "";
//}

namespace IRWrapper {
    static IR* ir_root = nullptr;

    void set_ir_root (IR* in);
    IR* get_ir_root ();

    // All deep_copied.
    IR* reconstruct_ir_with_stmt_vec(const vector<IR*>&);

    IR* get_first_stmtlist_from_root(IR* cur_root);
    IR* get_first_stmtlist_from_root();
    IR* get_first_stmt_from_root(IR* cur_root);
    IR* get_first_stmt_from_root();


    IR* get_last_stmtlist_from_root(IR* cur_root);
    IR* get_last_stmtlist_from_root();
    IR* get_last_stmt_from_root(IR* cur_root);
    IR* get_last_stmt_from_root();

    IR* get_stmt_ir_from_stmtlist(IR* cur_stmtlist);


    vector<IR*> get_all_ir_node (IR* cur_ir_root);
    void get_all_ir_node(IR* cur_ir, vector<IR*>& res);

    IRTYPE get_cur_stmt_type_from_sub_ir(IR* cur_ir);
    IR* get_cur_stmt_ir_from_sub_ir(IR* cur_ir);

    bool is_exist_ir_node_in_stmt_with_type(IRTYPE ir_type, bool is_subquery,
                                            int stmt_idx);
    bool is_exist_ir_node_in_stmt_with_type(IR* cur_stmt, IRTYPE ir_type,
                                            bool is_subquery = false, bool ignore_is_subquery = false);
    bool is_exist_ir_node_in_stmt_with_type(IR* cur_stmt, IRTYPE ir_type);

    /* By default, is_ignore_type_suffix == true.
     * Which means kSelectStmt_1 and kSelectStmt_2 is the same type
     */
    vector<IR*> get_ir_node_in_stmt_with_type(IR* cur_stmt, IRTYPE ir_type,
                                              bool is_subquery = false, bool ignore_is_subquery = false);
    vector<IR*> get_ir_node_in_stmt_with_type_one_level(IR* cur_stmt, IRTYPE ir_type);

    bool append_stmt_at_idx(string, int idx);
    bool append_stmt_at_end(string);
    bool append_stmt_at_idx(IR*, int idx); // Please provide with IR* (kStatement*) type, do not provide IR*(kStatementList*) type. If want to append at the start, use idx=-1;
    bool append_stmt_at_end(IR*); // Please provide with IR* (kStatement*) type, do not provide IR*(kStatementList*) type.

    bool remove_stmt_at_idx_and_free(unsigned idx);
    bool remove_stmt_and_free(IR* rov_stmt);

    bool replace_stmt_and_free(IR* old_stmt, IR* cur_stmt);

    IR* get_ir_node_for_stmt_by_idx(int idx);
    IR* get_ir_node_for_stmt_by_idx(IR* ir_root, int idx);

    vector<IRTYPE> get_all_stmt_ir_type();
    int get_stmt_num();
    int get_stmt_num(IR* cur_root);
    int get_stmt_idx(IR*);

    vector<IR*> get_stmt_ir_vec();
    vector<IR*> get_stmt_ir_vec(IR* root);

    vector<IR*> get_stmtlist_IR_vec();
    vector<IR*> get_stmtlist_IR_vec(IR* root);

    bool is_in_subquery(IR* cur_stmt, IR* check_node, bool output_debug = false);

    /*
    ** Iterately find the parent type. Skip kUnknown and keep iterating until not kUnknown is found. Return the parent IRTYPE.
    ** If parent_ is NULL. Return kUnknown instead.
    */
    IR* get_p_parent_with_a_type(IR* cur_IR, int depth=0);

    /**/
    bool is_exist_group_clause(IR*);
    bool is_exist_having_clause(IR*);
    bool is_exist_limit_clause(IR*);

    vector<IR*> get_select_items_in_select_stmt(IR* cur_stmt);
//    int get_num_select_items_in_select_stmt(IR* cur_stmt);

    bool is_ir_in(IR*, IR*);
    bool is_ir_in(IR*, IRTYPE);

//    bool add_fields_to_insert_stmt(IR* cur_stmt);
//    bool drop_fields_to_insert_stmt(IR* cur_stmt);
//    vector<IR*> get_fields_in_stmt(IR* cur_stmt);
//
//    bool add_kvalues_to_insert_stmt(IR* cur_stmt);
//    bool drop_kvalues_to_insert_stmt(IR* cur_stmt);
//    int get_num_fields_in_stmt(IR* cur_stmt);
//    int get_num_kvalues_in_stmt(IR* cur_stmt);

    void debug(IR* root, unsigned level);
};

#endif
