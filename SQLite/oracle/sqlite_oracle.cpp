#include "./sqlite_oracle.h"
#include "ast.h"

bool SQL_ORACLE::mark_node_valid(IR *root) {
    if (root == nullptr)
        return false;
    /* the following types do not added to the norec_select_stmt list. They should be able to mutate as usual. */
    if (root->type_ == kExpr || root->type_ == kTableRef || root->type_ == kOptGroup || root->type_ == kWindowClause)
        return false;
    root->is_norec_select_fixed = true;
    if (root->left_ != nullptr)
        this->mark_node_valid(root->left_);
    if (root->right_ != nullptr)
        this->mark_node_valid(root->right_);
    return true;
}