#include "../include/ir_wrapper.h"
#include "../include/utils.h"
#include <chrono>

IR* IRWrapper::reconstruct_ir_with_stmt_vec(const vector<IR*>& stmt_vec) {
    if (stmt_vec.size() == 0) {
        return nullptr;
    }
    if (!stmt_vec[0]) {
        return nullptr;
    }

    IR* cur_root = new IR(kQuery, OP0(), nullptr, nullptr);
    IR* first_simple_stmt = new IR(kSimpleStatement, OP0(), stmt_vec[0]->deep_copy());
    IR* first_stmtlist = new IR(kStmtList, OP3("", ";", ""), first_simple_stmt);
    cur_root->update_left(first_stmtlist);

    set_ir_root(cur_root);

    for (int i = 1; i < stmt_vec.size(); i++) {
        if (stmt_vec[i] == nullptr) continue;
        IR* new_stmt = stmt_vec[i]->deep_copy();
        append_stmt_at_end(new_stmt);
    }

    return cur_root;
}

bool IRWrapper::is_exist_ir_node_in_stmt_with_type(IR* cur_stmt,
    IRTYPE ir_type, bool is_subquery, bool ignore_is_subquery) {

    vector<IR*> matching_IR_vec = IRWrapper::get_ir_node_in_stmt_with_type(cur_stmt,
        ir_type, is_subquery, ignore_is_subquery);
    if (matching_IR_vec.size() == 0){
        return false;
    } else {
        return true;
    }
}

vector<IR*> IRWrapper::get_ir_node_in_stmt_with_type(IR* cur_stmt,
    IRTYPE ir_type, bool is_subquery, bool ignore_is_subquery, bool ignore_type_suffix) {

    // Iterate IR binary tree, left depth prioritized.
    bool is_finished_search = false;
    std::vector<IR*> ir_vec_iter;
    std::vector<IR*> ir_vec_matching_type;
    IR* cur_IR = cur_stmt; 
    // Begin iterating. 
    while (!is_finished_search) {
        ir_vec_iter.push_back(cur_IR);
        if (!ignore_type_suffix && cur_IR->type_ == ir_type) {
            ir_vec_matching_type.push_back(cur_IR);
        } else if (ignore_type_suffix && cur_IR->type_ == ir_type) {
            ir_vec_matching_type.push_back(cur_IR);
        }

        if (cur_IR->left_ != nullptr){
            cur_IR = cur_IR->left_;
            continue;
        } else { // Reaching the most depth. Consulting ir_vec_iter for right_ nodes. 
            cur_IR = nullptr;
            while (cur_IR == nullptr){
                if (ir_vec_iter.size() == 0){
                    is_finished_search = true;
                    break;
                }
                cur_IR = ir_vec_iter.back()->right_;
                ir_vec_iter.pop_back();
            }
            continue;
        }
    }
    // Check whether IR node is in a SELECT subquery.
    if (!ignore_is_subquery) {
        std::vector<IR*> ir_vec_matching_type_depth;
        for (IR* ir_match : ir_vec_matching_type){
            if(IRWrapper::is_in_subquery(cur_stmt, ir_match) == is_subquery) {
                ir_vec_matching_type_depth.push_back(ir_match);
            }
            continue;
        }
        return ir_vec_matching_type_depth;
    } else {
        return ir_vec_matching_type;
    }
}

bool IRWrapper::is_in_subquery(IR* cur_stmt, IR* check_node,
    bool output_debug) {
    if (IRWrapper::is_ir_in(check_node, kSubquery)) {
        return true;
    } else {
        return false;
    }
}

IR* IRWrapper::get_ir_node_for_stmt_by_idx(int idx) {

    if (idx < 0) {
        FATAL("Checking on non-existing stmt. Function: IRWrapper::get_ir_node_for_stmt_with_idx(). Idx < 0. idx: '%d' \n", idx);
    }

    if (IRWrapper::ir_root == nullptr){
        FATAL("Root IR not found in IRWrapper::get_ir_node_for_stmt_with_idx(); Forgot to initilize the IRWrapper? \n");
    }

    vector<IR*> stmt_list_v = IRWrapper::get_stmtlist_IR_vec();

    if (idx >= stmt_list_v.size()){
        std::cerr << "Statement with idx " << idx << " not found in the IR. " << std::endl;
        return nullptr;
    }
    IR* cur_stmt_list = stmt_list_v[idx];
    // cerr << "Debug: 136: cur_stmt_list type: " << get_string_by_ir_type(cur_stmt_list->get_ir_type()) << "\n";
    IR* cur_stmt = get_stmt_ir_from_stmtlist(cur_stmt_list);
    return cur_stmt;
}

IR* IRWrapper::get_ir_node_for_stmt_by_idx(IR* ir_root, int idx) {
    IRWrapper::set_ir_root(ir_root);
    return IRWrapper::get_ir_node_for_stmt_by_idx(idx);
}

vector<IRTYPE> IRWrapper::get_all_stmt_ir_type(){

    vector<IR*> stmt_list_v = IRWrapper::get_stmtlist_IR_vec();

    vector<IRTYPE> all_types;
    for (auto iter = stmt_list_v.begin(); iter != stmt_list_v.end(); iter++){
        all_types.push_back((**iter).type_);
    }
    return all_types;

}

int IRWrapper::get_stmt_num(){
    return IRWrapper::get_stmtlist_IR_vec().size();
}

int IRWrapper::get_stmt_num(IR* cur_root) {
    if (cur_root->type_ != kQuery) {
        cerr << "Error: Receiving NON-kProgram root. Func: IRWrapper::get_stmt_num(IR* cur_root). Aboard!\n";
        FATAL("Error: Receiving NON-kProgram root. Func: IRWrapper::get_stmt_num(IR* cur_root). Aboard!\n");
    }
    IRWrapper::set_ir_root(cur_root);
    return IRWrapper::get_stmt_num();
}

IR* IRWrapper::get_first_stmtlist_from_root() {

    /* First of all, given the root, we need to get to kStmtList. */

    if (ir_root == nullptr ) {
        cerr << "Error: In ir_wrapper::get_stmtmulti_IR_vec, receiving empty IR root. \n";
        return nullptr;
    }
    if (ir_root->get_left()->get_ir_type() == kStmtList) {  // This is the rewritten and reconstruct IR tree.
        return ir_root->get_left();
    }

    /* This is not a reconstructed IR tree. Do not have any kStmtList. */
    return nullptr;
    
}

IR* IRWrapper::get_first_stmtlist_from_root(IR* cur_root) {
    IRWrapper::ir_root = cur_root;
    return get_first_stmtlist_from_root();
}

IR* IRWrapper::get_first_stmt_from_root() {

    if (ir_root->get_left()->get_ir_type() == kStmtList) {  // This is the rewritten and reconstruct IR tree.
        IR* first_stmtmulti = IRWrapper::get_first_stmtlist_from_root();
        if (first_stmtmulti == nullptr) {
            return nullptr;
        }
        return IRWrapper::get_stmt_ir_from_stmtlist(first_stmtmulti);
    }

    /* Now, we try to return the first stmt from the original parser IR tree returns. */
    IR* sql_statement = ir_root->get_left();
    if (sql_statement == nullptr || sql_statement->get_ir_type() != kSimpleStatement) {
        return nullptr;
    }

    return sql_statement->get_left();
}

IR* IRWrapper::get_first_stmt_from_root(IR* cur_root) {
    IRWrapper::ir_root = cur_root;
    return get_first_stmt_from_root();
}

IR* IRWrapper::get_last_stmtlist_from_root() {

    /* First of all, given the root, we need to get to kStmtmulti. */

    if (ir_root == nullptr ) {
        cerr << "Error: In ir_wrapper::get_stmtmulti_IR_vec, receiving empty IR root. \n";
        return nullptr;
    }
    vector<IR*> v_stmtlist = IRWrapper::get_stmtlist_IR_vec();
    return v_stmtlist.back();
}

IR* IRWrapper::get_last_stmt_from_root(IR* cur_root) {
    IRWrapper::ir_root = cur_root;
    return get_last_stmt_from_root();
}

IR* IRWrapper::get_last_stmt_from_root() {
    if (ir_root == nullptr) {
        return nullptr;
    }

    IR* last_stmtlist = get_last_stmtlist_from_root();
    if (!last_stmtlist) {
        return nullptr;
    }
    IR* last_stmt = get_stmt_ir_from_stmtlist(last_stmtlist);
    if (!last_stmt) {
        return nullptr;
    } else {
        return last_stmt;
    }

    return nullptr;
}

vector<IR*> IRWrapper::get_stmtlist_IR_vec(){

    IR* stmt_IR_p = get_first_stmtlist_from_root();

    vector<IR*> stmt_list_v;

    while (stmt_IR_p && stmt_IR_p -> get_ir_type() == kStmtList){ // Iterate from the first kstatementlist to the last.
        stmt_list_v.push_back(stmt_IR_p);
        if (stmt_IR_p->get_right() == nullptr) break; // This is the last kstatementlist.
        stmt_IR_p = stmt_IR_p -> get_right(); // Lead to the next kstatementlist.
    }

    return stmt_list_v;
}

bool IRWrapper::append_stmt_at_idx(string app_str, int idx){
    /* idx = -1, append to the beginning of the query
    ** idx = stmt_num - 1, append to the ending of the query. 
    */ 

    IR* ori_root = IRWrapper::ir_root;
    int stmt_num = get_stmt_num();

    if (idx < -1 && idx >= stmt_num ){
        std::cerr << "Error: Input index exceed total statement number. \n In function IRWrapper::append_stmt_at_idx(). \n";
        return false;
    }

    // Parse and get the new statement. 
    vector<IR*> ir_vec;
    IR* app_ir_root = nullptr;
    int ret = run_parser_multi_stmt(app_str, ir_vec);
    if (ret == 0 && ir_vec.size() > 0) {
        app_ir_root = ir_vec.back();
    } else {
        return false;
    }

    IR* app_IR_node = get_first_stmt_from_root(app_ir_root);

    if (!app_IR_node) {
        cerr << "Error: get_stmt_ir_from_stmtmulti returns nullptr. \n";
        return false;
    }
    app_IR_node = app_IR_node->deep_copy();
    app_ir_root->deep_drop();

    /* Restore the modified ir_root in the previous function calls.  */ 
    set_ir_root(ori_root);

    return IRWrapper::append_stmt_at_idx(app_IR_node, idx);
}

bool IRWrapper::append_stmt_at_end(string app_str) {

    IR* ori_root = IRWrapper::ir_root;

    // Parse and get the new statement.
    vector<IR*> ir_vec;
    IR* app_ir_root = nullptr;
    int ret = run_parser_multi_stmt(app_str, ir_vec);
    if (ret == 0 && ir_vec.size() > 0) {
        app_ir_root = ir_vec.back();
    } else {
        return false;
    }

    IR* app_ir_node = get_first_stmt_from_root(app_ir_root);

    if (!app_ir_node) {
        cerr << "Error: get_first_stmt_from_root returns nullptr. \n";
        return false;
    }
    app_ir_node = app_ir_node->deep_copy();
    app_ir_root->deep_drop();

    /* Restore the modified ir_root in the previous function calls.  */ 
    set_ir_root(ori_root);

    return IRWrapper::append_stmt_at_idx(app_ir_node, get_stmt_num()-1);
    
}

bool IRWrapper::append_stmt_at_end(IR* app_IR_node) { // Please provide with IR* (Statement*) type, do not provide IR*(StatementList*) type. 

    int total_num = IRWrapper::get_stmt_num();
    return IRWrapper::append_stmt_at_idx(app_IR_node, total_num - 1);

}

bool IRWrapper::append_stmt_at_idx(IR* app_IR_node, int idx) { // Please provide with IR* (Specific_Statement*) type, do not provide IR*(StatementList*) type.

    vector<IR*> stmt_list_v = IRWrapper::get_stmtlist_IR_vec();

    if (stmt_list_v.size() == 0) {
        cerr << "Error: Getting stmt_list_v.size() == 0; \n";
        app_IR_node->deep_drop();
        return false;
    }

    if (idx < -1 || idx >= stmt_list_v.size()){
        std::cerr << "Error: Input index exceed total statement number. \n In function IRWrapper::append_stmt_at_idx(). \n";
        std::cerr << "Error: Input index " << to_string(idx) << "; stmt_list_v size(): " << stmt_list_v.size() << ".\n";
        assert(false);
    }

    app_IR_node = new IR(kSimpleStatement, OP0(), app_IR_node);

    if (idx < (stmt_list_v.size() - 1) ) {

        auto new_res = new IR(kStmtList, OPMID(";"), nullptr, nullptr);

        int next_idx = idx + 1;
        IR* next_ir_list = stmt_list_v[next_idx];

        if (!ir_root->swap_node(next_ir_list, new_res)) {
            new_res->deep_drop();
            app_IR_node->update_right(nullptr);
            app_IR_node->deep_drop();
            std::cerr << "Error: Swap node failure? In function: IRWrapper::append_stmt_at_idx. idx = "  << idx << "\n";
            return false;
        }

        new_res->update_left(app_IR_node);
        new_res->update_right(next_ir_list);

        return true;
    } else {
        /* If idx == stmt_list_v.size() -1. Append new stmt to the end to the query sequence */

        auto new_res = new IR(kStmtList, OPMID(";"), app_IR_node, nullptr);

        int last_idx = idx;
        IR* last_ir_list = stmt_list_v[last_idx];

        last_ir_list->update_right(new_res);

        return true;
    }
}

bool IRWrapper::remove_stmt_at_idx_and_free(unsigned idx){

    vector<IR*> stmt_list_v = IRWrapper::get_stmtlist_IR_vec();

    if (idx >= stmt_list_v.size()){
        std::cerr << "Error: Input index exceed total statement number. \n In function IRWrapper::remove_stmt_at_idx_and_free(). \n";
        assert(false);
    }

    if (stmt_list_v.size() <= 1) {
        // Cannot remove stmt becuase there is only one stmt left in the query.
        return false;
    }

    IR* rov_stmt = stmt_list_v[idx];

    if ( idx < (stmt_list_v.size() - 1) ){
        IR* parent_node = rov_stmt->get_parent();
        IR* next_stmt = rov_stmt->get_right();
        parent_node->swap_node(rov_stmt, next_stmt);
        rov_stmt->right_ = nullptr;
        rov_stmt->deep_drop();

    } else { // Remove the last statement from the sequence. 
        IR* parent_node = rov_stmt->get_parent();
        parent_node->update_right(nullptr);
        rov_stmt->deep_drop();
    }

    return true;
}

vector<IR*> IRWrapper::get_stmt_ir_vec() {

    vector<IR*> stmtlist_vec = IRWrapper::get_stmtlist_IR_vec(), stmt_vec;
    if (stmtlist_vec.size() == 0) return stmt_vec;

    for (int i = 0; i < stmtlist_vec.size(); i++){
        if (!stmtlist_vec[i]) {
            cerr << "Error: Found some stmtlist_vec == nullptr. Return empty vector. \n";
            continue;
        }

        IR* stmt_ir = get_stmt_ir_from_stmtlist(stmtlist_vec[i]);
        if (stmt_ir != nullptr) {
            stmt_vec.push_back(stmt_ir);
        }
    }
    
    return stmt_vec;
}

bool IRWrapper::remove_stmt_and_free(IR* rov_stmt) {
    vector<IR*> stmt_vec = IRWrapper::get_stmt_ir_vec();
    int stmt_idx = -1;
    for (int i = 0; i < stmt_vec.size(); i++) {
        if (stmt_vec[i] == rov_stmt) {stmt_idx = i; break;}
    }
    if (stmt_idx == -1) {return false;}
    else {
        return IRWrapper::remove_stmt_at_idx_and_free(stmt_idx);
    }
}

vector<IR*> IRWrapper::get_all_ir_node (IR* cur_ir_root) {
    // IRWrapper::set_ir_root(cur_ir_root);
    vector<IR*> res;
    IRWrapper::get_all_ir_node(cur_ir_root, res);
    return res;
}

void IRWrapper::get_all_ir_node(IR* cur_ir, vector<IR*>& res) {

    if (cur_ir == nullptr) {
        return;
    }

    if (cur_ir->get_left()) {
        IRWrapper::get_all_ir_node(cur_ir->get_left(), res);
    }

    if (cur_ir->get_ir_type() != kQuery) {
        res.push_back(cur_ir);
    }

    if (cur_ir->get_right()) {
        IRWrapper::get_all_ir_node(cur_ir->get_right(), res);
    }

    if (cur_ir->get_ir_type() == kQuery) {
        res.push_back(cur_ir);
    }

}

int IRWrapper::get_stmt_idx(IR* cur_stmt){
    vector<IR*> all_stmt_vec = IRWrapper::get_stmt_ir_vec();
    int output_idx = -1;
    int count = 0;
    for (IR* iter_stmt : all_stmt_vec) {
        if (iter_stmt == cur_stmt) {
            output_idx = count;
            break;
        }
        count++;
    }
    return output_idx;
}

bool IRWrapper::replace_stmt_and_free(IR* old_stmt, IR* new_stmt) {
    int old_stmt_idx = IRWrapper::get_stmt_idx(old_stmt);
    if (old_stmt_idx < 0) {
        return false;
    }
    if (!IRWrapper::remove_stmt_at_idx_and_free(old_stmt_idx)){
        return false;
    }
    if (!IRWrapper::append_stmt_at_idx(new_stmt, old_stmt_idx-1)){
        return false;
    }
    return true;
}

IR* IRWrapper::get_p_parent_with_a_type(IR* cur_IR, int depth) {
    IRTYPE prev_ir_type = cur_IR->get_ir_type();
    while (cur_IR ->get_parent() != nullptr) {
        IRTYPE parent_type = cur_IR->get_parent()->get_ir_type();
        if (
            // There shouldn't be any exact same ir type nested with each other.
            // If there is, they are from different nested structure.
            parent_type == prev_ir_type
            ||
            (parent_type != kUnknown && parent_type != prev_ir_type)
        ){
            prev_ir_type = parent_type;
            depth--;
            if (depth <= 0) {
                return cur_IR->get_parent();
            }
        }
        cur_IR = cur_IR->get_parent();
    }
    return nullptr;
}

bool IRWrapper::is_exist_group_clause(IR* cur_stmt){
    vector<IR*> v_group_clause = get_ir_node_in_stmt_with_type(cur_stmt, kGroupByClause, false);
    for (IR* group_clause : v_group_clause) {
        if (! group_clause->is_empty()) {
            return true;
        }
    }

    return false;
}

bool IRWrapper::is_exist_having_clause(IR* cur_stmt){
    vector<IR*> v_having_clause = get_ir_node_in_stmt_with_type(cur_stmt, kHavingClause, false);
    for (IR* having_clause : v_having_clause) {
        if (! having_clause->is_empty()) {
            return true;
        }
    }

    return false;
}

bool IRWrapper::is_exist_limit_clause(IR* cur_stmt){
    vector<IR*> v_limit_clause = get_ir_node_in_stmt_with_type(cur_stmt, kLimitClause, false);
    for (IR* limit_clause : v_limit_clause) {
        if (! limit_clause->is_empty()) {
            return true;
        }
    }
    return false;
}

vector<IR*> IRWrapper::get_select_items_in_select_stmt(IR* cur_stmt){

    vector<IR*> res_vec;
    if (cur_stmt->get_ir_type() != kSelectStatement) {
        return res_vec;
    }

    res_vec = IRWrapper::get_ir_node_in_stmt_with_type(cur_stmt, kSelectItem, false);
    return res_vec;
}

IRTYPE IRWrapper::get_cur_stmt_type_from_sub_ir(IR* cur_ir) {
    IR* stmt_ir = get_cur_stmt_ir_from_sub_ir(cur_ir);
    if (!stmt_ir) {
        return kUnknown;
    } else {
        return stmt_ir->get_ir_type();
    }
}

IR* IRWrapper::get_cur_stmt_ir_from_sub_ir(IR* cur_ir) {
    while (cur_ir->get_parent() != nullptr) {
        if (cur_ir->get_ir_type() == kBeginWork) {
            return cur_ir;
        }
        if (cur_ir->get_ir_type() == kSimpleStatement) {
            return cur_ir->get_left();
        }
        if (cur_ir->get_ir_type() == kStmtList) {
            if (cur_ir->get_left()->get_ir_type() == kSimpleStatement) {
                return cur_ir->get_left()->get_left();
            }
        }
        cur_ir = cur_ir->parent_;
    }
    return nullptr;
}

IR* IRWrapper::get_stmt_ir_from_stmtlist(IR* cur_stmtlist){
    // Get actual statement, not kSimpleStatement.
    if (cur_stmtlist == nullptr) {
        cerr << "Getting nullptr cur_stmtmulti. \n";
        return nullptr;
    }
    if (cur_stmtlist->get_ir_type() != kStmtList) {
        cerr << "Error: In IRWrapper::get_stmt_ir_from_stmtmulti(), not getting type kStmtmulti. \n";
        return nullptr;
    }

    assert(cur_stmtlist->get_left() &&
           cur_stmtlist->get_left()->get_ir_type() == kSimpleStatement &&
           cur_stmtlist->get_left() -> get_left()
           );
    return cur_stmtlist->get_left()->get_left(); // Return the actual stmt type, not kSimpleStatement.
}

bool IRWrapper::is_ir_in(IR* sub_ir, IR* par_ir) {

    while (sub_ir) {
        if (sub_ir == par_ir) {
            return true;
        }
        sub_ir = sub_ir->get_parent();
    }
    return false;
}

bool IRWrapper::is_ir_in(IR* sub_ir, IRTYPE par_type) {

    while (sub_ir) {
        if (sub_ir->get_ir_type() == par_type) {
            return true;
        }
        sub_ir = sub_ir->get_parent();
    }
    return false;
}

void IRWrapper::debug(IR* root, unsigned level) {

    for (unsigned i = 0; i < level; i++) {
        cerr << " ";
    }

    cerr << level << ": "
         << get_string_by_ir_type(root->type_) << ": "
         << get_string_by_data_type(root->data_type_) << ": "
         << root -> to_string() << ": "
         << endl;

    if (root->left_) {
        debug(root->left_, level + 1);
    }
    if (root->right_) {
        debug(root->right_, level + 1);
    }
}

bool IRWrapper::add_fields_to_insert_stmt(IR* cur_stmt) {
    if (cur_stmt->get_ir_type() != kInsertStatement) {
        return false;
    }

    vector<IR*> v_fields = IRWrapper::get_fields_in_stmt(cur_stmt);

    if (v_fields.size() == 0 ) {
        return false;
    }

    IR* last_field = v_fields.back();
    last_field->set_ir_type(kUnknown);

    IR* identifier = new IR(kIdentifier, string("v1"), kDataColumnName, kUse);
    identifier = new IR(kPureIdentifier, OP0(), identifier);
    identifier = new IR(kIdentifierRule, OP0(), identifier);
    identifier = new IR(kQualifiedIdentifier, OP0(), identifier);
    identifier = new IR(kColumnRef, OP0(), identifier);
    identifier = new IR(kInsertIdentifier, OP0(), identifier);
    IR* new_field = new IR(kFields, OP3("", ", ", ""), nullptr, identifier);

    cur_stmt->swap_node(last_field, new_field);
    new_field->update_left(last_field);

    return true;

}

bool IRWrapper::drop_fields_to_insert_stmt(IR* cur_stmt) {
    if (cur_stmt->get_ir_type() != kInsertStatement) {
        return false;
    }

    vector<IR*> v_fields = get_fields_in_stmt(cur_stmt);

    if (v_fields.size() == 0 ) {
        return false;
    }

    IR* last_field = v_fields.back();

    if (last_field->get_right() == nullptr) {
        // There is only one Identifier in the kField.
        return false;
    }

    IR* next_content = last_field->get_right();
    cur_stmt->swap_node(last_field, next_content);
    next_content->set_ir_type(kFields);

    last_field->update_right(nullptr);
    last_field->deep_drop();

    return true;

}

bool IRWrapper::add_kvalues_to_insert_stmt(IR* cur_stmt) {
    if (cur_stmt->get_ir_type() != kInsertStatement) {
        return false;
    }

    vector<IR*> v_values_node = IRWrapper::get_ir_node_in_stmt_with_type(cur_stmt, kValues, false, false);

    for (IR* cur_values_node: v_values_node) {
        IR* new_literal = new IR(kLiteral, string("0"));
        IR* new_values_node = new IR(kValues, OP3("", ", ", ""), nullptr, new_literal);
        cur_values_node->set_ir_type(kUnknown);
        cur_stmt->swap_node(cur_values_node, new_values_node);
        new_values_node->update_left(cur_values_node);
    }

    return true;

}

bool IRWrapper::drop_kvalues_to_insert_stmt(IR* cur_stmt) {
    if (cur_stmt->get_ir_type() != kInsertStatement) {
        return false;
    }

    vector<IR*> v_values_node = IRWrapper::get_ir_node_in_stmt_with_type(cur_stmt, kValues, false, false);

    for (IR* cur_values_node: v_values_node) {

        if (cur_values_node->get_right() == nullptr) {
            continue;
        }

        IR* next_value = cur_values_node->get_right();
        cur_values_node->update_right(nullptr);
        cur_stmt->swap_node(cur_values_node, next_value);
        cur_values_node->deep_drop();
        next_value->set_ir_type(kValues);
    }

    return true;

}


vector<IR*> IRWrapper::get_fields_in_stmt(IR* cur_stmt) {
    if (cur_stmt->get_ir_type() != kInsertStatement) {
        vector<IR*> tmp;
        return tmp;
    }

    return IRWrapper::get_ir_node_in_stmt_with_type(cur_stmt, kFields, false);
}

int IRWrapper::get_num_fields_in_stmt(IR* cur_stmt) {
    if (cur_stmt->get_ir_type() != kInsertStatement) {
        return false;
    }

    vector<IR*> v_fields = IRWrapper::get_ir_node_in_stmt_with_type(cur_stmt, kFields, false);
    if (v_fields.size() == 0) {
        return 0;
    }

    IR* field_node = v_fields.front();
    string tmp = field_node->to_string();
    return string_splitter(tmp, ",").size();
}

int IRWrapper::get_num_kvalues_in_stmt(IR* cur_stmt) {
    if (cur_stmt->get_ir_type() != kInsertStatement) {
        return 0;
    }

    vector<int> res;

    vector<IR*> v_value_list = IRWrapper::get_ir_node_in_stmt_with_type(cur_stmt, kValues, false);
    if (v_value_list.size() == 0) {
        return 0;
    }
    IR* value_node = v_value_list.front();
    string tmp = value_node->to_string();

    return string_splitter(tmp, ",").size();
}