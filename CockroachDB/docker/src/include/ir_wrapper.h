#ifndef __IR_WRAPPER_H__
#define __IR_WRAPPER_H__

#include "ast.h"
#include "define.h"
#include "mutate.h"
#include <string>

class IRWrapper {
public:
  void set_ir_root(IR *in) { this->ir_root = in; }
  IR *get_ir_root() { return this->ir_root; }

  IR *get_first_stmtlist_from_root(IR *cur_root);
  IR *get_first_stmtlist_from_root();
  IR *get_first_stmt_from_root(IR *cur_root);
  IR *get_first_stmt_from_root();

  IR *get_last_stmtlist_from_root(IR *cur_root);
  IR *get_last_stmtlist_from_root();
  IR *get_last_stmt_from_root(IR *cur_root);
  IR *get_last_stmt_from_root();

  IR *get_stmt_ir_from_stmtlist(IR *cur_stmtlist);

  vector<IR *> get_all_ir_node(IR *cur_ir_root);
  vector<IR *> get_all_ir_node();

  IRTYPE get_cur_stmt_type_from_sub_ir(IR *cur_ir);

  bool is_exist_ir_node_in_stmt_with_type(IRTYPE ir_type, bool is_subquery,
                                          int stmt_idx);
  template <typename TYPE>
  bool is_exist_ir_node_in_stmt_with_type(IR *cur_stmt, TYPE ir_type,
                                          bool is_subquery = false,
                                          bool ignore_is_subquery = false);
  bool is_exist_ir_node_in_stmt_with_type(IR *cur_stmt, IRTYPE ir_type);

  /* By default, is_ignore_type_suffix == true.
   * Which means kSelectStmt_1 and kSelectStmt_2 is the same type
   */
  template <typename TYPE>
  vector<IR *> get_ir_node_in_stmt_with_type(IR *cur_stmt, TYPE ir_type,
                                             bool is_subquery = false,
                                             bool ignore_is_subquery = false,
                                             bool is_ignore_type_suffix = true);

  bool append_stmt_at_idx(string, int idx, Mutator &g_mutator);
  bool append_stmt_at_end(string, Mutator &g_mutator);
  bool
  append_stmt_at_idx(IR *,
                     int idx); // Please provide with IR* (kStatement*) type, do
                               // not provide IR*(kStatementList*) type. If want
                               // to append at the start, use idx=-1;
  bool append_stmt_at_end(IR *, Mutator &g_mutator);
  bool append_stmt_at_end(IR *); // Please provide with IR* (kStatement*) type,
                                 // do not provide IR*(kStatementList*) type.

  bool remove_stmt_at_idx_and_free(unsigned idx);
  bool remove_stmt_and_free(IR *rov_stmt);

  bool replace_stmt_and_free(IR *old_stmt, IR *cur_stmt);

  bool append_components_at_ir(IR *, IR *, bool is_left,
                               bool is_replace = true);
  bool remove_components_at_ir(IR *);

  // bool swap_components_at_ir(IR*, bool is_left_f, IR*, bool is_left_l);

  IR *get_ir_node_for_stmt_with_idx(int idx);
  IR *get_ir_node_for_stmt_with_idx(IR *ir_root, int idx);

  bool is_ir_before(IR *f, IR *l); // Check is IR f before IR l in query string.
  bool is_ir_after(IR *f, IR *l);  // Check is IR f after IR l in query string.

  vector<IRTYPE> get_all_stmt_ir_type();
  int get_stmt_num();
  int get_stmt_num(IR *cur_root);
  int get_stmt_idx(IR *);

  vector<IR *> get_stmt_ir_vec();
  vector<IR *> get_stmt_ir_vec(IR *root) {
    this->set_ir_root(root);
    return this->get_stmt_ir_vec();
  }

  vector<IR *> get_stmtlist_IR_vec();
  vector<IR *> get_stmtmulti_IR_vec(IR *root) {
    this->set_ir_root(root);
    return this->get_stmtlist_IR_vec();
  }

  bool compare_ir_type(IRTYPE, IRTYPE);

  bool is_in_subquery(IR *cur_stmt, IR *check_node, bool output_debug = false);
  bool is_in_insert_rest(IR *cur_stmt, IR *check_node,
                         bool output_debug = false);

  /*
  ** Iterately find the parent type. Skip kUnknown and keep iterating until not
  *kUnknown is found. Return the parent IRTYPE.
  ** If parent_ is NULL. Return kUnknown instead.
  */
  IRTYPE get_parent_type(IR *cur_IR, int depth = 0);
  IR *get_p_parent_with_a_type(IR *cur_IR, int depth = 0);

  template <typename TYPE> IR* get_parent_node_with_type(IR *cur_IR, TYPE);
  template <typename TYPE> IR* get_parent_node_with_type_past(IR *cur_IR, TYPE);

  /**/
  bool is_exist_group_clause(IR *);
  bool is_exist_having_clause(IR *);
  bool is_exist_limit_clause(IR *);

  /**/
  vector<IR *> get_selectclauselist_vec(IR *);
  bool append_selectclause_clause_at_idx(IR *cur_stmt, IR *app_ir,
                                         string set_oper_str, int idx);
  bool remove_selectclause_clause_at_idx_and_free(IR *cur_stmt, int idx);
  // int get_num_selectclause(IR* cur_stmt) {return
  // this->get_selectclauselist_vec(cur_stmt).size();}
  bool is_exist_UNION_SELECT(IR *cur_stmt);
  bool is_exist_INTERSECT_SELECT(IR *cur_stmt);
  bool is_exist_EXCEPT_SELECT(IR *cur_stmt);
  bool is_exist_set_operator(IR *cur_stmt);

  vector<IR*> get_expr_vec_from_expr_list(IR* expr_list);

  vector<IR *> get_select_exprs(IR *cur_stmt);
  int get_num_select_exprs(IR *cur_stmt) {
    return this->get_select_exprs(cur_stmt).size();
  }

  bool is_ir_in(IR *, IR *);
  bool is_ir_in(IR *, IRTYPE);

  // Helper function for find_closest_nearby_IR_with_type();
  inline bool comp_type(IR* cur_node, IRTYPE ir_type) {
      if (cur_node->get_ir_type() == ir_type) {
          return true;
      } else {
          return false;
      }
  }
  inline bool comp_type(IR* cur_node, DATATYPE data_type) {
    if (cur_node->get_data_type() == data_type) {
        return true;
    } else {
        return false;
    }
  }
  inline bool comp_type(IR* cur_node, string in_str) {
      if (cur_node->to_string() == in_str) {
          return true;
      }
      return false;
  }
  inline bool comp_type(IR* cur_node, vector<IRTYPE> v_ir_type) {
      for (auto& ir_type : v_ir_type) {
          if (cur_node->get_ir_type() == ir_type) {
              return true;
          }
      }
      return false;
  }
  inline bool comp_type(IR* cur_node, vector<DATATYPE> v_data_type) {
      for (auto& data_type : v_data_type) {
          if (cur_node->get_data_type() == data_type) {
              return true;
          }
      }
      return false;
  }
  inline bool comp_type(IR* cur_node, vector<string> v_in_str) {
      for (string& in_str : v_in_str) {
          if (cur_node->to_string() == in_str) {
              return true;
          }
      }
      return false;
  }

  // Iterate all the child node from the input cur_node. For each child node,
  // call the handler function from its input function pointer.
  typedef void (*handler_t)(IR*);
  void iter_cur_node_with_handler(IR* cur_node, handler_t);

  // Iterate all the child node from the input cur_node. Left Depth first.
  template <typename T, typename U> IR* iter_cur_node(IR* cur_node, T ir_name, U cap_name);
  template <typename T> IR* iter_cur_node(IR* cur_node, T ir_name) {
      vector<T> dummy_vec;
      return this->iter_cur_node(cur_node, ir_name, dummy_vec);
  };
  // C++ template. The TYPE could be ir_type or data_type.
  template <typename T, typename U> IR*
            find_closest_nearby_IR_with_type(IR* cur_node, T ir_name, U cap_name);
  template <typename T> IR*
    find_closest_nearby_IR_with_type(IR* cur_node, T ir_name) {
      vector<T> dummy_vec;
      return this->find_closest_nearby_IR_with_type(cur_node, ir_name, dummy_vec);
    }

  template <typename TYPE> bool is_find_closest_nearby_IR_with_type(IR* cur_node, TYPE ir_type) {
      if (this->find_closest_nearby_IR_with_type(cur_node, ir_type)) {
          return true;
      } else {
          return false;
      }
  }

private:
  IR *ir_root = nullptr;
};

// Given current node, iterate through all its child node and see if it can find matches.
// Return the matched, otherwise return NULL.
template<typename T, typename U> IR* IRWrapper::iter_cur_node(IR* cur_node, T ir_type, U cap_type) {
    // Recursive function.
    // Depth first search.
    if (cur_node == NULL) {
        return NULL;
    }

    if (comp_type(cur_node, cap_type)) {
        // Encounter the cap_type.
        // Do not search any further.
        return NULL;
    }

    // Template. Could be ir_type or data_type.
    if (this->comp_type(cur_node, ir_type)) {
        return cur_node;
    }

    // Check its left and right child node.
    if (cur_node->get_left()) {
        IR* left_child = iter_cur_node(cur_node->get_left(), ir_type, cap_type);
        if (left_child != NULL) {
            return left_child;
        }
    }

    if (cur_node->get_right()) {
        IR* right_child = iter_cur_node(cur_node->get_right(), ir_type, cap_type);
        if (right_child != NULL) {
            return right_child;
        }
    }

    return NULL;
}

template <typename T, typename U>
IR* IRWrapper::find_closest_nearby_IR_with_type(IR* cur_node, T ir_type, U cap_type){
    // Given one node, find the closest and nearby IR that matches the inputted
    // ir_type.
    // The function would iterate to the parent node and find the closest nearby
    // matched node.
    // The find function will be stopped if it encounters capType.

    if (cur_node == NULL) {
        cerr << "ERROR: Inside the function: find_closest_nearby_IR_with_type, getting "
                "NULL cur_node. \n\n\n";
        return NULL;
    }

    // First of all, check all the child node for the current node,
    // make sure there is no ir_type matched in the child node of the current
    // node.
    // Avoid comparing to the original input node.

    IR* ret_node = NULL;
    if (cur_node->get_left()) {
        ret_node = iter_cur_node(cur_node->get_left(), ir_type, cap_type);
    }
    if (ret_node != NULL) {
        return ret_node;
    }
    if (cur_node->get_right()) {
        ret_node = iter_cur_node(cur_node->get_right(), ir_type, cap_type);
    }
    if (ret_node != NULL) {
        return ret_node;
    }

    // Has already check the sub-node before. If no parent, can directly drop.
    if (cur_node->get_parent() == NULL) {
        return NULL;
    }

    if (comp_type(cur_node->get_parent(), cap_type)) {
        return NULL;
    }

    do {
        IR* ori_child_node = cur_node;
        cur_node = cur_node->get_parent();

        if (comp_type(cur_node, cap_type)) {
            // Encounter the cap_type.
            // Do not search any further.
            break;
        }

        if (ori_child_node == cur_node->get_left()) {
            ret_node = this->iter_cur_node(cur_node->get_right(), ir_type, cap_type);
            if (ret_node != NULL) {
                return ret_node;
            }
        } else { // ori_child_node == cur_node->get_right()
            ret_node = this->iter_cur_node(cur_node->get_left(), ir_type, cap_type);
            if (ret_node != NULL) {
                return ret_node;
            }
        }
    } while (cur_node->get_parent() != NULL);

    // Cannot find the matching node.
    return NULL;
}

template <typename TYPE>
IR* IRWrapper::get_parent_node_with_type(IR *cur_IR, TYPE ir_type) {
    while (cur_IR->get_parent() != nullptr) {
        IR* par_IR = cur_IR->get_parent();
        if (this->comp_type(par_IR, ir_type)) {
            return par_IR;
        }
        cur_IR = cur_IR->get_parent();
    }
    return nullptr;
}

template <typename TYPE>
IR* IRWrapper::get_parent_node_with_type_past(IR *cur_IR, TYPE ir_type) {
    // Reach TYPE, and then return the parent for the given TYPE.
    bool is_reached = false;
    while (cur_IR->get_parent() != nullptr) {
        IR* par_IR = cur_IR->get_parent();
        if (this->comp_type(par_IR, ir_type)) {
            is_reached = true;
        } else if (is_reached) {
            return par_IR;
        }
        cur_IR = cur_IR->get_parent();
    }
    return nullptr;
}

template <typename TYPE>
vector<IR *> IRWrapper::get_ir_node_in_stmt_with_type(IR *cur_stmt,
                                                      TYPE ir_type,
                                                      bool is_subquery,
                                                      bool ignore_is_subquery,
                                                      bool ignore_type_suffix) {

    // Iterate IR binary tree, left depth prioritized.
    bool is_finished_search = false;
    std::vector<IR *> ir_vec_iter;
    std::vector<IR *> ir_vec_matching_type;
    IR *cur_IR = cur_stmt;
    // Begin iterating.
    while (!is_finished_search) {
        ir_vec_iter.push_back(cur_IR);
        if (!ignore_type_suffix && this->comp_type(cur_IR, ir_type)) {
            ir_vec_matching_type.push_back(cur_IR);
        } else if (ignore_type_suffix && comp_type(cur_IR, ir_type)) {
            ir_vec_matching_type.push_back(cur_IR);
        }

        if (cur_IR->left_ != nullptr) {
            cur_IR = cur_IR->left_;
            continue;
        } else { // Reaching the most depth. Consulting ir_vec_iter for right_
            // nodes.
            cur_IR = nullptr;
            while (cur_IR == nullptr) {
                if (ir_vec_iter.size() == 0) {
                    is_finished_search = true;
                    break;
                }
                cur_IR = ir_vec_iter.back()->right_;
                ir_vec_iter.pop_back();
            }
            continue;
        }
    }

    // cerr << "We have ir_vec_matching_type.size()" <<
    // ir_vec_matching_type.size() << "\n\n\n"; if (ir_vec_matching_type.size() >
    // 0 ) {
    //     cerr << "We have ir_vec_matching_type.type_, parent->type_,
    //     parent->parent->type_: " << ir_vec_matching_type[0] ->type_ << "  "
    //          << get_parent_type(ir_vec_matching_type[0], 3)  << "   " <<
    //          get_parent_type(ir_vec_matching_type[0], 4) << "\n\n\n";
    //     cerr << "is_sub_query: " << this->is_in_subquery(cur_stmt,
    //     ir_vec_matching_type[0]) << "\n\n\n"; cerr <<
    //     "ir_vec_matching_type->to_string: " <<
    //     ir_vec_matching_type[0]->to_string() << "\n\n\n";
    // }

    // Check whether IR node is in a SELECT subquery.
    if (!ignore_is_subquery) {
        std::vector<IR *> ir_vec_matching_type_depth;
        for (IR *ir_match : ir_vec_matching_type) {
            if (this->is_in_subquery(cur_stmt, ir_match) == is_subquery) {
                ir_vec_matching_type_depth.push_back(ir_match);
            }
            continue;
        }
        // cerr << "We have ir_vec_matching_type_depth.size()" <<
        // ir_vec_matching_type_depth.size() << "\n\n\n";
        return ir_vec_matching_type_depth;
    } else {
        return ir_vec_matching_type;
    }
}

template <typename TYPE>
bool IRWrapper::is_exist_ir_node_in_stmt_with_type(IR *cur_stmt, TYPE ir_type,
                                                   bool is_subquery,
                                                   bool ignore_is_subquery) {

    vector<IR *> matching_IR_vec = this->get_ir_node_in_stmt_with_type(
            cur_stmt, ir_type, is_subquery, ignore_is_subquery);
    if (matching_IR_vec.size() == 0) {
        return false;
    } else {
        return true;
    }
}

#endif
