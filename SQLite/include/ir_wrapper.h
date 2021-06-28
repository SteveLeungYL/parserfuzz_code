#ifndef __IR_WRAPPER_H__
#define __IR_WRAPPER_H__

#include "define.h"
#include "ast.h"
#include <string>

typedef NODETYPE IRTYPE;

class IRWrapper {
public:

    void set_ir_root (IR* in) {this->ir_root = in;} 
    IR* get_ir_root () {return this->ir_root;}

    bool is_exist_ir_node_in_stmt_with_type(IRTYPE ir_type, bool is_subquery, int stmt_idx);
    vector<IR*> get_ir_node_in_stmt_with_type(IRTYPE ir_type, bool is_subquery = false, int stmt_idx = -1);

    bool is_exist_ir_node_in_stmt_with_type(IR* cur_stmt, IRTYPE ir_type, bool is_subquery);
    vector<IR*> get_ir_node_in_stmt_with_type(IR* cur_stmt, IRTYPE ir_type, bool is_subquery = false);

    bool append_stmt_after_idx(string, unsigned idx, const Mutator& g_mutator);
    bool append_stmt_at_end(string, const Mutator& g_mutator);
    bool append_stmt_after_idx(IR*, unsigned idx); // Please provide with IR* (kStatement*) type, do not provide IR*(kStatementList*) type. 
    bool append_stmt_at_end(IR*); // Please provide with IR* (kStatement*) type, do not provide IR*(kStatementList*) type. 

    bool remove_stmt_at_idx(unsigned idx);
    bool remove_stmt(IR* rov_stmt);

    bool append_components_at_ir(IR*, IR*, bool is_left, bool is_replace = true);
    bool remove_components_at_ir(IR*);

    // bool swap_components_at_ir(IR*, bool is_left_f, IR*, bool is_left_l);

    IR* get_ir_node_for_stmt_with_idx(int idx);

    bool is_ir_before(IR* f, IR* l); // Check is IR f before IR l in query string.
    bool is_ir_after(IR* f, IR* l); // Check is IR f after IR l in query string.

    vector<IRTYPE> get_all_ir_type();
    int get_stmt_num();

    vector<IR*> get_stmt_ir_vec();

private:
    IR* ir_root = nullptr;

    vector<IR*> get_stmtlist_IR_vec();

};

#endif