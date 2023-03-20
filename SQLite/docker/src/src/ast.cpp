#include "../include/ast.h"
#include "../include/utils.h"
#include <cassert>
#include <cstdio>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <vector>

u8 GramCovMap::has_new_grammar_bits(u8* cur_cov_map, u8* cur_virgin_map, bool is_debug) {

#if defined(__x86_64__) || defined(__arm64__) || defined(__aarch64__)

  u64 *current = (u64 *)cur_cov_map;
  u64 *virgin = (u64 *)cur_virgin_map;

  u32 i = (MAP_SIZE >> 3);

#else

  u32 *current = (u32 *)this->cov_map;
  u32 *virgin = (u32 *)this->virgin_map;

  u32 i = (MAP_SIZE >> 2);

#endif /* ^__x86_64__ __arm64__ __aarch64__ */

  u8 ret = 0;

  while (i--) {

    /* Optimize for (*current & *virgin) == 0 - i.e., no bits in current bitmap
       that have not been already cleared from the virgin map - since this will
       almost always be the case. */

    if (unlikely(*current) && unlikely(*current & *virgin)) {

      if (likely(ret < 2) || unlikely(is_debug)) {

        u8 *cur = (u8 *)current;
        u8 *vir = (u8 *)virgin;

        /* Looks like we have not found any new bytes yet; see if any non-zero
           bytes in current[] are pristine in virgin[]. */

#if defined(__x86_64__) || defined(__arm64__) || defined(__aarch64__)

        if ((cur[0] && vir[0] == 0xff) || (cur[1] && vir[1] == 0xff) ||
            (cur[2] && vir[2] == 0xff) || (cur[3] && vir[3] == 0xff) ||
            (cur[4] && vir[4] == 0xff) || (cur[5] && vir[5] == 0xff) ||
            (cur[6] && vir[6] == 0xff) || (cur[7] && vir[7] == 0xff)) {
          ret = 2;
          if (unlikely(is_debug)) {
            vector<u8> byte = get_cur_new_byte(cur, vir);
            for (const u8& cur_byte: byte){
//              this->gram_log_map_id(i, cur_byte);
            }
          }
        }
        else if (unlikely(ret != 2))
          ret = 1;

#else

        if ((cur[0] && vir[0] == 0xff) || (cur[1] && vir[1] == 0xff) ||
            (cur[2] && vir[2] == 0xff) || (cur[3] && vir[3] == 0xff))
          ret = 2;
        else if (unlikely(ret != 2))
          ret = 1;

#endif /* ^__x86_64__ __arm64__ __aarch64__ */
      }
      *virgin &= ~*current;
    }

    current++;
    virgin++;
  }

  return ret;
}

/* Count the number of non-255 bytes set in the bitmap. Used strictly for the
   status screen, several calls per second or so. */
// Copy from afl-fuzz.cpp
u32 GramCovMap::count_non_255_bytes(u8 *mem) {

#define FF(_b) (0xff << ((_b) << 3))
  u32 *ptr = (u32 *)mem;
  u32 i = (MAP_SIZE >> 2);
  u32 ret = 0;

  while (i--) {

    u32 v = *(ptr++);

    /* This is called on the virgin bitmap, so optimize for the most likely
       case. */

    if (v == 0xffffffff)
      continue;
    if ((v & FF(0)) != FF(0))
      ret++;
    if ((v & FF(1)) != FF(1))
      ret++;
    if ((v & FF(2)) != FF(2))
      ret++;
    if ((v & FF(3)) != FF(3))
      ret++;
  }

  return ret;
#undef FF
}

string get_string_by_ir_type(IRTYPE type) {
#define DECLARE_CASE(classname)                                                \
  if (type == classname)                                                    \
    return #classname;
  ALLTYPE(DECLARE_CASE);
#undef DECLARE_CASE

  return "";
}

string get_string_by_id_type(IDTYPE type) {

  switch (type) {
  case id_whatever:
    return "id_whatever";

  case id_create_table_name:
    return "id_create_table_name";
  case id_top_table_name:
    return "id_top_table_name";
  case id_table_name:
    return "id_table_name";

  case id_create_column_name:
    return "id_create_column_name";
  case id_column_name:
    return "id_column_name";

  case id_pragma_name:
    return "id_pragma_name";
  case id_pragma_value:
    return "id_pragma_value";

  case id_create_index_name:
    return "id_create_index_name";
  case id_index_name:
    return "id_index_name";

  case id_create_trigger_name:
    return "id_create_trigger_name";
  case id_trigger_name:
    return "id_trigger_name";

  case id_create_window_name:
    return "id_create_window_name";
  case id_window_name:
    return "id_window_name";
  case id_base_window_name:
    return "id_base_window_name";

  case id_create_savepoint_name:
    return "id_create_savepoint_name";
  case id_savepoint_name:
    return "id_savepoint_name";

  case id_schema_name:
    return "id_schema_name";
  case id_module_name:
    return "id_moudle_name";
  case id_collation_name:
    return "id_collation_name";
  case id_database_name:
    return "id_database_name";
  case id_alias_name:
    return "id_alias_name";
  case id_table_alias_name:
    return "id_table_alias_name";
  case id_column_alias_name:
    return "id_column_alias_name";
  case id_function_name:
    return "id_function_name";
  case id_table_constraint_name:
    return "id_table_constraint_name";
  case id_create_table_name_with_tmp:
    return "id_create_table_name_with_tmp";
  case id_create_column_name_with_tmp:
    return "id_create_column_name_with_tmp";
  default:
    return "unknown identifier type";
  }
}

string IR::to_string() {

  string res = "";
  _to_string(res);
  trim_string(res);
  return res;
}

// recursive function, frequently called. Must be very fast
void IR::_to_string(string &res) {

  if (type_ == kStringLiteral) {
     res += str_val_;
     return;
   }

  if (!str_val_.empty()) {
    res += str_val_;
    return;
  }

  if (op_ && !(op_->prefix_.empty())) {
    res += op_->prefix_;
    res +=  " ";
  }

  if (left_) {
    left_->_to_string(res);
    res += " ";
  }

  if (op_ && !(op_->middle_.empty())) {
    res += op_->middle_;
    res += " ";
  }

  if (right_) {
    right_->_to_string(res);
    res += " ";
  }

  if (op_ && !(op_->suffix_.empty())) {
    res += op_->suffix_;
  }

  return;
}

bool IR::detach_node(IR *node) { return swap_node(node, NULL); }

bool IR::swap_node(IR *old_node, IR *new_node) {

  IR *parent = this->locate_parent(old_node);

  if (parent == NULL) {
    // cerr << "Error: parent is null. Locate_parent error. In func: IR::swap_node(). \n";
    return false;
  }
  else if (parent->left_ == old_node)
    parent->update_left(new_node);
  else if (parent->right_ == old_node)
    parent->update_right(new_node);
  else {
    // cerr << "Error: parent-child not matching. In func: IR::swap_node(). \n";
    return false;
  }

  old_node->parent_ = NULL;

  return true;
}

IR *IR::locate_parent(IR *child) {

  for (IR *p = child; p; p = p->parent_)
    if (p->parent_ == this)
      return child->parent_;

  return NULL;
}

IR *IR::get_root() {

  IR *node = this;

  while (node->parent_ != NULL)
    node = node->parent_;

  return node;
}

IR *IR::get_parent() {

  return this->parent_;
}

void IR::update_left(IR *new_left) {

  // we do not update the parent_ of the old left_
  // we do not update the child of the old parent_ of new_left

  this->left_ = new_left;
  if (new_left)
    new_left->parent_ = this;
}

void IR::update_right(IR *new_right) {

  // we do not update the parent_ of the old right_
  // we do not update the child of the old parent_ of new_right

  this->right_ = new_right;
  if (new_right)
    new_right->parent_ = this;
}

void IR::drop() {

  if (this->op_)
    delete this->op_;
  delete this;
}

void IR::deep_drop() {

  if (this->left_)
    this->left_->deep_drop();

  if (this->right_)
    this->right_->deep_drop();

  this->drop();
}

IR *IR::deep_copy() {

  IR *left = NULL, *right = NULL, *copy_res;
  IROperator *op = NULL;

  if (this->left_)
    left = this->left_->deep_copy();
  if (this->right_)
    right = this->right_->deep_copy();

  if (this->op_ != NULL)
    op = OP3(this->op_->prefix_, this->op_->middle_, this->op_->suffix_);

  copy_res = new IR(this->type_, op, left, right, this->f_val_, this->str_val_,
                    this->mutated_times_);
  copy_res->id_type_ = this->id_type_;
  copy_res->parent_ = this->parent_;
  copy_res->str_val_ = this->str_val_;
  copy_res->uniq_id_in_tree_ = this->uniq_id_in_tree_;
  copy_res->operand_num_ = this->operand_num_;
  copy_res->is_node_struct_fixed = this->is_node_struct_fixed;

  return copy_res;
}