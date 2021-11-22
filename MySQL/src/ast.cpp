#include "../include/ast.h"
#include "../include/define.h"
#include "../include/utils.h"
#include <cassert>

 
static string s_table_name;



Node* generate_ast_node_by_type(IRTYPE type){
    #define DECLARE_CASE(classname) \
    if (type == k##classname) return new classname();

    ALLCLASS(DECLARE_CASE);
    #undef DECLARE_CASE
    return NULL;
}

NODETYPE get_nodetype_by_string(string s){
    #define DECLARE_CASE(datatypename) \
    if(s == #datatypename) return k##datatypename;

    ALLCLASS(DECLARE_CASE);

    #undef DECLARE_CASE
    return kUnknown;
}

string get_string_by_nodetype(NODETYPE tt){
    #define DECLARE_CASE(datatypename) \
    if(tt == k##datatypename) return string(#datatypename);

    ALLCLASS(DECLARE_CASE);

    #undef DECLARE_CASE
    return string("");
}

string get_string_by_datatype(DATATYPE tt){
    #define DECLARE_CASE(datatypename) \
    if(tt == k##datatypename) return string(#datatypename);

    ALLDATATYPE(DECLARE_CASE);

    #undef DECLARE_CASE
    return string("");
}

DATATYPE get_datatype_by_string(string s){
    #define DECLARE_CASE(datatypename) \
    if(s == #datatypename) return k##datatypename;

    ALLDATATYPE(DECLARE_CASE);

    #undef DECLARE_CASE
    return kDataWhatever;
}

void deep_delete(IR * root){
    if(root->left_) deep_delete(root->left_);
    if(root->right_) deep_delete(root->right_);
    
    if(root->op_) delete root->op_;

    delete root;
}

IR * deep_copy(const IR * root){
    IR * left = NULL, * right = NULL, * copy_res;

    if(root->left_) left = deep_copy(root->left_); // do you have a second version for deep_copy that accept only one argument?                                                  
    if(root->right_) right = deep_copy(root->right_);//no I forget to update here

    copy_res = new IR(root, left, right);

    return copy_res;

}

string IR::to_string(){
    auto res = to_string_core();
    trim_string(res);
    return res;
}

string IR::to_string_core(){
    //cout << get_string_by_nodetype(this->type_) << endl;
    switch(type_){
	case kIntLiteral: return std::to_string(int_val_);
	case kFloatLiteral: return std::to_string(float_val_);
	case kIdentifier: return str_val_;
	case kStringLiteral: return str_val_;

}

    string res;
    
    if( op_!= NULL ){
        //if(op_->prefix_ == NULL)
            ///cout << "FUCK NULL prefix" << endl;
         //cout << "OP_Prex: " << op_->prefix_ << endl;
        res += op_->prefix_ + " ";
    }
     //cout << "OP_1_" << op_ << endl;
    if(left_ != NULL)
        //res += left_->to_string() + " ";
        res += left_->to_string_core() + " ";
    // cout << "OP_2_" << op_ << endl;
    if( op_!= NULL)
        res += op_->middle_ + " ";
     //cout << "OP_3_" << op_ << endl;
    if(right_ != NULL)
        //res += right_->to_string() + " ";
        res += right_->to_string_core() + " ";
     //cout << "OP_4_" << op_ << endl;
    if(op_!= NULL)
        res += op_->suffix_;
    
    //cout << "FUCK" << endl;
    //cout << "RETURN" << endl;
    return res;
}


IR* Node::translate(vector<IR *> &v_ir_collector){
    return NULL;
}
