#include "../include/ir_wrapper.h"

bool IRWrapper::is_exist_ir_node_in_stmt_with_type(IR* cur_stmt,
    IRTYPE ir_type, bool is_subquery, bool ignore_is_subquery) {

    vector<IR*> matching_IR_vec = this->get_ir_node_in_stmt_with_type(cur_stmt,
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
        } else if (ignore_type_suffix && compare_ir_type(cur_IR->type_, ir_type)) {
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

    // cerr << "We have ir_vec_matching_type.size()" << ir_vec_matching_type.size() << "\n\n\n";
    // if (ir_vec_matching_type.size() > 0 ) {
    //     cerr << "We have ir_vec_matching_type.type_, parent->type_, parent->parent->type_: " << ir_vec_matching_type[0] ->type_ << "  "
    //          << get_parent_type(ir_vec_matching_type[0], 3)  << "   " << get_parent_type(ir_vec_matching_type[0], 4) << "\n\n\n";
    //     cerr << "is_sub_query: " << this->is_in_subquery(cur_stmt, ir_vec_matching_type[0]) << "\n\n\n";
    //     cerr << "ir_vec_matching_type->to_string: " << ir_vec_matching_type[0]->to_string() << "\n\n\n";
    // }

    // Check whether IR node is in a SELECT subquery. 
    if (!ignore_is_subquery) {
        std::vector<IR*> ir_vec_matching_type_depth;
        for (IR* ir_match : ir_vec_matching_type){
            if(this->is_in_subquery(cur_stmt, ir_match) == is_subquery) {
                ir_vec_matching_type_depth.push_back(ir_match);
            }
            continue;
        }
        // cerr << "We have ir_vec_matching_type_depth.size()" << ir_vec_matching_type_depth.size() << "\n\n\n";
        return ir_vec_matching_type_depth;
    } else {
        return ir_vec_matching_type;
    }
}

bool IRWrapper::is_in_subquery(IR* cur_stmt, IR* check_node,
    bool output_debug) {
    
    if (this->is_ir_in(check_node, kSubquery)) {
        return true;
    } else {
        return false;
    }
}

IR* IRWrapper::get_ir_node_for_stmt_by_idx(int idx) {

    if (idx < 0) {
        FATAL("Checking on non-existing stmt. Function: IRWrapper::get_ir_node_for_stmt_with_idx(). Idx < 0. idx: '%d' \n", idx);
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
    // cerr << "Debug: 136: cur_stmt_list type: " << get_string_by_ir_type(cur_stmt_list->get_ir_type()) << "\n";
    IR* cur_stmt = get_stmt_ir_from_stmtlist(cur_stmt_list);
    return cur_stmt;
}

IR* IRWrapper::get_ir_node_for_stmt_by_idx(IR* ir_root, int idx) {
    this->set_ir_root(ir_root);
    return this->get_ir_node_for_stmt_by_idx(idx);
}

vector<IRTYPE> IRWrapper::get_all_stmt_ir_type(){

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

int IRWrapper::get_stmt_num(IR* cur_root) {
    if (cur_root->type_ != kStartEntry) {
        cerr << "Error: Receiving NON-kProgram root. Func: IRWrapper::get_stmt_num(IR* cur_root). Aboard!\n";
        FATAL("Error: Receiving NON-kProgram root. Func: IRWrapper::get_stmt_num(IR* cur_root). Aboard!\n");
    }
    this->set_ir_root(cur_root);
    return this->get_stmt_num();
}

IR* IRWrapper::get_first_stmtlist_from_root() {

    /* First of all, given the root, we need to get to kStmtList. */

    if (ir_root == NULL ) {
        cerr << "Error: In ir_wrapper::get_stmtmulti_IR_vec, receiving empty IR root. \n";
        return NULL;
    }
    if (ir_root->get_left()->get_ir_type() != kStmtList) {
        cerr << "Error: In ir_wrapper:get_stmtmulti_IR_vec, cannot find the kStmtmulti " \
            "structure from the current IR tree. Empty stmt? Or PLAssignStmt? " \
            "PLAssignStmt is not currently supported. \n";
        return NULL;
    }

    /* If the first kStmtList confirm, it is the first stmtlist we need. Returns directly.  */
    return ir_root->get_left();
    
}

IR* IRWrapper::get_first_stmtlist_from_root(IR* cur_root) {
    this->ir_root = cur_root;
    return get_first_stmtlist_from_root();
}

IR* IRWrapper::get_first_stmt_from_root() {
    IR* first_stmtmulti = this->get_first_stmtlist_from_root();
    if (first_stmtmulti == NULL) {
        return NULL;
    }

    return this->get_stmt_ir_from_stmtlist(first_stmtmulti);
}

IR* IRWrapper::get_first_stmt_from_root(IR* cur_root) {
    this->ir_root = cur_root;
    return get_first_stmt_from_root();
}

IR* IRWrapper::get_last_stmtlist_from_root() {

    /* First of all, given the root, we need to get to kStmtmulti. */

    if (ir_root == NULL ) {
        cerr << "Error: In ir_wrapper::get_stmtmulti_IR_vec, receiving empty IR root. \n";
        return NULL;
    }
    if (ir_root->get_left()->get_ir_type() != kStmtList) {
        cerr << "Error: In ir_wrapper:get_stmtmulti_IR_vec, cannot find the kStmtmulti " \
            "structure from the current IR tree. Empty stmt? Or PLAssignStmt? " \
            "PLAssignStmt is not currently supported. \n";
        return NULL;
    }

    vector<IR*> v_stmtlist = this->get_stmtlist_IR_vec();
    return v_stmtlist.back();
}

IR* IRWrapper::get_last_stmt_from_root(IR* cur_root) {
    this->ir_root = cur_root;
    return get_last_stmt_from_root();
}

vector<IR*> IRWrapper::get_stmtlist_IR_vec(){

    IR* stmt_IR_p = get_first_stmtlist_from_root();

    vector<IR*> stmt_list_v;

    while (stmt_IR_p && stmt_IR_p -> get_ir_type() == kStmtList){ // Iterate from the first kstatementlist to the last.
        stmt_list_v.push_back(stmt_IR_p);
        if (stmt_IR_p->get_right() == nullptr) break; // This is the last kstatementlist.
        stmt_IR_p = stmt_IR_p -> get_right(); // Lead to the next kstatementlist.
    }

    stmt_list_v.clear();

    return stmt_list_v;
}