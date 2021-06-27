#include "define.h"
#include "ast.h"
#include <string>

typedef NODETYPE IRTYPE;

class IRWrapper {
public:

    void set_ir_root (IR* in) {this->ir_root = in;} 

    bool is_exist_ir_node_in_stmt_with_type(IRTYPE ir_type, bool is_subquery, int stmt_idx);
    vector<IR*> get_ir_node_in_stmt_with_type(IRTYPE ir_type, bool is_subquery = false, int stmt_idx = -1);

    bool append_stmt_after_idx(string, unsigned idx, Mutator g_mutator);
    bool remove_stmt_at_idx(unsigned idx);

    bool append_components_at_ir(IR*, IR*, bool is_left);
    bool remove_components_at_ir(IR*, bool is_left);

    // bool swap_components_at_ir(IR*, bool is_left_f, IR*, bool is_left_l);

    IR* get_ir_node_for_stmt_with_idx(int idx);

    bool is_ir_before(IR* f, IR* l); // Check is IR f before IR l in query string.
    bool is_ir_after(IR* f, IR* l); // Check is IR f after IR l in query string.

    vector<IRTYPE> get_all_ir_type();
    int get_stmt_num();


private:
    IR* ir_root;

    vector<IR*> get_stmt_IR_vec();

};
