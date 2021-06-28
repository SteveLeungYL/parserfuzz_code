#include "../include/ir_wrapper.h"
#include "../AFL/debug.h"
#include <iostream>
#include <vector>

bool IRWrapper::is_exist_ir_node_in_stmt_with_type(IRTYPE ir_type, bool is_subquery, int stmt_idx){
    vector<IR*> matching_IR_vec = this->get_ir_node_in_stmt_with_type(ir_type, is_subquery, stmt_idx);
    if (matching_IR_vec.size() == 0){
        return false;
    } else {
        return true;
    }
}

bool IRWrapper::is_exist_ir_node_in_stmt_with_type(IR* cur_stmt, IRTYPE ir_type, bool is_subquery) {
    vector<IR*> matching_IR_vec = this->get_ir_node_in_stmt_with_type(cur_stmt, ir_type, is_subquery);
    if (matching_IR_vec.size() == 0){
        return false;
    } else {
        return true;
    }
}


vector<IR*> IRWrapper::get_ir_node_in_stmt_with_type(IR* cur_stmt, IRTYPE ir_type, bool is_subquery = false) {

    // Iterate IR binary tree, left depth prioritized.
    bool is_finished_search = false;
    std::vector<IR*> ir_vec_iter;
    std::vector<IR*> ir_vec_matching_type;
    IR* cur_IR = cur_stmt; 
    // Begin iterating. 
    while (!is_finished_search) {
        ir_vec_iter.push_back(cur_IR);
        if (cur_IR->type_ == ir_type) {
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
    std::vector<IR*> ir_vec_matching_type_depth;
    for (IR* ir_match : ir_vec_matching_type){
        IR* cur_iter = ir_match;
        bool is_finished_search = false;
        while (!is_finished_search) {
            if (cur_iter->type_ == kStatementList) {
                if (!is_subquery) {ir_vec_matching_type_depth.push_back(ir_match); is_finished_search == true; break;}
            }
            else if (cur_iter->type_ == kSelectStatement) {
                if (cur_iter->get_parent()->type_ != kStatementList) {
                    if (is_subquery) {ir_vec_matching_type_depth.push_back(ir_match); is_finished_search == true; break;}
                }
            }
            cur_iter = cur_iter->get_parent(); // Assuming cur_iter->get_parent() will always get to kStatementList. Otherwise, it would be error. 
            continue;
        }
        continue;
    }

    return ir_vec_matching_type_depth;

}

vector<IR*> IRWrapper::get_ir_node_in_stmt_with_type(IRTYPE ir_type, bool is_subquery = false, int stmt_idx = -1) { // (IRTYPE, subquery_level)

    if (stmt_idx < 0) {
        FATAL("Checking on non-existing stmt. Function: IRWrapper::get_ir_node__in_stmt_with_type. Idx < 0. idx: '%s' \n", to_string(stmt_idx));
    }
    IR* cur_stmt = this->get_ir_node_for_stmt_with_idx(stmt_idx);

    return this->get_ir_node_in_stmt_with_type(cur_stmt, ir_type, is_subquery);
}

IR* IRWrapper::get_ir_node_for_stmt_with_idx(int idx) {

    if (idx < 0) {
        FATAL("Checking on non-existing stmt. Function: IRWrapper::get_ir_node_for_stmt_with_idx(). Idx < 0. idx: '%s' \n", to_string(idx));
    }

    if (this->ir_root == nullptr){
        FATAL("Root IR not found in IRWrapper::get_ir_node_for_stmt_with_idx(); Forgot to initilize the IRWrapper? \n");
    }

    vector<IR*> stmt_list_v = this->get_stmtlist_IR_vec();

    if (idx >= stmt_list_v.size()){
        std::cerr << "Statement with idx " << idx << " not found in the IR. " << std::endl;
        return nullptr;
    }
    IR* cur_stmt_list = stmt_list_v[idx];
    IR* cur_stmt = cur_stmt_list -> right_;
    return cur_stmt;
}

bool IRWrapper::is_ir_before(IR* f, IR* l){
    return this->is_ir_after(l, f);
}

bool IRWrapper::is_ir_after(IR* f, IR* l){
    if (this->ir_root == nullptr){
        FATAL("Root IR not found in IRWrapper::is_ir_before/after(); Forgot to initilize the IRWrapper? \n");
    }

    // Left depth prioritized iteration. Should found l first if IR f is behind(after) l. 
    // Iterate IR binary tree, left depth prioritized.
    bool is_finished_search = false;
    std::vector<IR*> ir_vec_iter;
    IR* cur_IR = this->ir_root; 
    // Begin iterating. 
    while (!is_finished_search) {
        ir_vec_iter.push_back(cur_IR);
        if (cur_IR == l) {
            return true;
        } else if (cur_IR == f) {
            return false;
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

    FATAL("Cannot find curent IR in the IR tree. Function IRWrapper::is_ir_after(). \n");

}

vector<IRTYPE> IRWrapper::get_all_ir_type(){

    vector<IR*> stmt_list_v = this->get_stmtlist_IR_vec();

    vector<IRTYPE> all_types;
    for (auto iter = stmt_list_v.begin(); iter != stmt_list_v.end(); iter++){
        all_types.push_back((**iter).type_);
    }
    return all_types;

}

int IRWrapper::get_stmt_num(){
    return this->get_stmtlist_IR_vec().size();
}

vector<IR*> IRWrapper::get_stmtlist_IR_vec(){
    IR* stmt_IR_p = this->ir_root->left_;
    vector<IR*> stmt_list_v_rev, stmt_list_v;


    while (true){ // Iterate from the last kstatementlist to the first. 
        stmt_list_v_rev.push_back(stmt_IR_p);
        if (stmt_IR_p->right_ == nullptr || stmt_IR_p->left_ == nullptr) break; // This is the first kstatementlist. 

        stmt_IR_p = stmt_IR_p -> left_; // Lead to the previous kstatementlist. 
    }

    // Reverse the list from the first statmentlist to the last. 
    for (auto v = stmt_list_v_rev.rbegin(); v != stmt_list_v_rev.rend(); v++){
        stmt_list_v.push_back(*v);
    }

    return stmt_list_v;
}

bool IRWrapper::append_stmt_after_idx(string app_str, unsigned idx, const Mutator& g_mutator){

    vector<IR*> stmt_list_v = this->get_stmtlist_IR_vec();

    if (idx >= stmt_list_v.size()){
        std::cerr << "Error: Input index exceed total statement number. \n In function IRWrapper::append_stmt_after_idx(). \n";
        return false;
    }

    IR* insert_pos_ir = stmt_list_v[idx];

    // Parse and get the new statement. 
    vector<IR*> app_IR_vec = g_mutator.parse_query_str_get_ir_set(app_str);
    IR* app_IR_node = app_IR_vec.back()->left_->left_;  // Program -> Statementlist -> Statement. 
    app_IR_node = app_IR_node->deep_copy();
    app_IR_vec.back()->deep_drop();
    app_IR_vec.clear();

    auto new_res = new IR(kStatementList, OPMID(";"), NULL, app_IR_node);

    if (!ir_root->swap_node(insert_pos_ir, new_res)){ // swap_node only rewrite the parent of insert_pos_ir, it will not affect insert_pos_ir. 
        app_IR_node->deep_drop();
        // FATAL("Error: Swap node failure? In function: IRWrapper::append_stmt_after_idx. \n");
        std::cerr << "Error: Swap node failure? In function: IRWrapper::append_stmt_after_idx. \n";
        return false;
    }
    new_res->update_left(insert_pos_ir);

    return true;
}

bool IRWrapper::append_stmt_at_end(string app_str, const Mutator& g_mutator) {
    vector<IR*> stmt_list_v = this->get_stmtlist_IR_vec();

    IR* insert_pos_ir = stmt_list_v[stmt_list_v.size()-1];

    // Parse and get the new statement. 
    vector<IR*> app_IR_vec = g_mutator.parse_query_str_get_ir_set(app_str);
    IR* app_IR_node = app_IR_vec.back()->left_->left_;  // Program -> Statementlist -> Statement. 
    app_IR_node = app_IR_node->deep_copy();
    app_IR_vec.back()->deep_drop();
    app_IR_vec.clear();

    auto new_res = new IR(kStatementList, OPMID(";"), NULL, app_IR_node);

    if (!ir_root->swap_node(insert_pos_ir, new_res)){ // swap_node only rewrite the parent of insert_pos_ir, it will not affect insert_pos_ir. 
        app_IR_node->deep_drop();
        // FATAL("Error: Swap node failure? In function: IRWrapper::append_stmt_after_idx. \n");
        std::cerr << "Error: Swap node failure? In function: IRWrapper::append_stmt_after_idx. \n";
        return false;
    }

    new_res->update_left(insert_pos_ir);

    return true;
}

bool IRWrapper::append_stmt_after_idx(IR* app_IR_node, unsigned idx) { // Please provide with IR* (Statement*) type, do not provide IR*(StatementList*) type. 
    vector<IR*> stmt_list_v = this->get_stmtlist_IR_vec();

    if (idx >= stmt_list_v.size()){
        std::cerr << "Error: Input index exceed total statement number. \n In function IRWrapper::append_stmt_after_idx(). \n";
        return false;
    }

    IR* insert_pos_ir = stmt_list_v[idx];

    auto new_res = new IR(kStatementList, OPMID(";"), NULL, app_IR_node);

    if (!ir_root->swap_node(insert_pos_ir, new_res)){ // swap_node only rewrite the parent of insert_pos_ir, it will not affect insert_pos_ir. 
        app_IR_node->deep_drop();
        // FATAL("Error: Swap node failure? In function: IRWrapper::append_stmt_after_idx. \n");
        std::cerr << "Error: Swap node failure? In function: IRWrapper::append_stmt_after_idx. \n";
        return false;
    }

    new_res->update_left(insert_pos_ir);

    return true;

}

bool IRWrapper::append_stmt_at_end(IR* app_IR_node) { // Please provide with IR* (Statement*) type, do not provide IR*(StatementList*) type. 

    vector<IR*> stmt_list_v = this->get_stmtlist_IR_vec();

    IR* insert_pos_ir = stmt_list_v[stmt_list_v.size()-1];

    auto new_res = new IR(kStatementList, OPMID(";"), NULL, app_IR_node);

    if (!ir_root->swap_node(insert_pos_ir, new_res)){ // swap_node only rewrite the parent of insert_pos_ir, it will not affect insert_pos_ir. 
        app_IR_node->deep_drop();
        // FATAL("Error: Swap node failure? In function: IRWrapper::append_stmt_after_idx. \n");
        std::cerr << "Error: Swap node failure? In function: IRWrapper::append_stmt_after_idx. \n";
        return false;
    }

    new_res->update_left(insert_pos_ir);

    return true;

}

bool IRWrapper::remove_stmt_at_idx(unsigned idx){

    vector<IR*> stmt_list_v = this->get_stmtlist_IR_vec();

    if (idx >= stmt_list_v.size()){
        std::cerr << "Error: Input index exceed total statement number. \n In function IRWrapper::remove_stmt_at_idx(). \n";
        return false;
    }

    IR* rov_stmt = stmt_list_v[idx];

    // For removing idx 0, we need to rewrite idx 1 to fit in the specific format of statementlist idx 0. 
    if (idx == 0){
        IR* next_stmt = stmt_list_v[1];
        IR* new_next_stmt = new IR(kStatementList, OP0(), next_stmt->right_->deep_copy());
        this->ir_root->swap_node(next_stmt, new_next_stmt);
        next_stmt->deep_drop(); // next_stmt->deep_drop() will lead to rov_stmt, because next_stmt->left_ is rov_stmt. 
        // rov_stmt->deep_drop();

    } else { 
        IR* prev_stmt = stmt_list_v[idx-1];
        this->ir_root->swap_node(rov_stmt, prev_stmt);
        rov_stmt->left_ = nullptr; // Cut the connection between rov_stmt and prev_stmt, prevent accidentally deep_drop for prev_stmt. 
        rov_stmt->deep_drop();
    }

    return true;

}


vector<IR*> IRWrapper::get_stmt_ir_vec() {
    vector<IR*> stmtlist_vec = this->get_stmtlist_IR_vec(), stmt_vec;
    if (stmtlist_vec.size() == 0) return stmt_vec;

    stmt_vec.push_back(stmtlist_vec[0]->left_);

    for (int i = 1; i < stmt_vec.size(); i++){
        stmt_vec.push_back(stmtlist_vec[i]->right_);
    }
    return stmt_vec;
}

bool IRWrapper::remove_stmt(IR* rov_stmt) {
    vector<IR*> stmt_vec = this->get_stmt_ir_vec();
    int stmt_idx = -1;
    for (int i = 0; i < stmt_vec.size(); i++) {
        if (stmt_vec[i] == rov_stmt) {stmt_idx = i; break;}
    }
    if (stmt_idx == -1) {return false;}
    else {
        return this->remove_stmt_at_idx(stmt_idx);
    }
}

bool IRWrapper::append_components_at_ir(IR* parent_node, IR* app_node, bool is_left, bool is_replace = true) {
    if (is_left) {
        if (parent_node->left_ != nullptr) {
            if (!is_replace) {
                cerr << "Append location has content, use is_replace=true if necessary. Function: IRWrapper::append_components_at_ir. \n";
                return false;
            }
            IR* old_node = parent_node->left_;
            old_node->detach_node(old_node);
            old_node->deep_drop();
        }
        parent_node->update_left(app_node);
        return true;
    } else {
        if (parent_node->right_ != nullptr) {
            if (!is_replace) {
                cerr << "Append location has content, use is_replace=true if necessary. Function: IRWrapper::append_components_at_ir. \n";
                return false;
            }
            IR* old_node = parent_node->right_;
            old_node->detach_node(old_node);
            old_node->deep_drop();
        }
        parent_node->update_right(app_node);
        return true;
    }
}

bool IRWrapper::remove_components_at_ir(IR* rov_ir) {
    if (rov_ir) {
        rov_ir->detach_node(rov_ir);
        rov_ir->deep_drop();
        return true;
    }
    cerr << "Error: rov_ir is nullptr. Function IRWrapper::remove_components_at_ir() \n";
    return false;
}