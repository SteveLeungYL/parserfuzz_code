#ifndef __AST_H__
#define __AST_H__
#include <vector>
#include <string>
#include "define.h"
#include <iostream>
using namespace std;

enum NODETYPE{
#define DECLARE_TYPE(v)  \
    v,
ALLTYPE(DECLARE_TYPE)
#undef DECLARE_TYPE
};
typedef NODETYPE IRTYPE;

enum CASEIDX{
	CASE0, CASE1, CASE2, CASE3, CASE4, CASE5, CASE6, CASE7, CASE8, CASE9, CASE10, CASE11, CASE12, CASE13, CASE14, CASE15, CASE16, CASE17, CASE18, CASE19, CASE20, CASE21, CASE22, CASE23, CASE24, CASE25, CASE26, CASE27, CASE28, CASE29, CASE30, CASE31, CASE32, CASE33, CASE34, CASE35, CASE36, CASE37, CASE38, CASE39, CASE40, CASE41, CASE42, CASE43, CASE44, CASE45, CASE46, CASE47, CASE48, CASE49, CASE50, CASE51, CASE52, CASE53, CASE54, CASE55, CASE56, CASE57, CASE58, CASE59, CASE60, CASE61, CASE62, CASE63, CASE64, CASE65, CASE66, CASE67, CASE68, CASE69, CASE70, CASE71, CASE72, CASE73, CASE74, CASE75, CASE76, CASE77, CASE78, CASE79, CASE80, CASE81, CASE82, CASE83, CASE84, CASE85, CASE86, CASE87, CASE88, CASE89, CASE90, CASE91, CASE92, CASE93, CASE94, CASE95, CASE96, CASE97, CASE98, CASE99, CASE100, CASE101, CASE102, CASE103, CASE104, CASE105, CASE106, CASE107, CASE108, CASE109, CASE110, CASE111, CASE112, CASE113, CASE114, CASE115, CASE116, CASE117, CASE118, CASE119, CASE120, CASE121, CASE122, CASE123, CASE124, CASE125, CASE126, CASE127, CASE128, CASE129, CASE130, CASE131, CASE132, CASE133, CASE134, CASE135, CASE136, CASE137, CASE138, CASE139, CASE140, CASE141, CASE142, CASE143, CASE144, CASE145, CASE146, CASE147, CASE148, CASE149, CASE150, CASE151, CASE152, CASE153, CASE154, CASE155, CASE156, CASE157, CASE158, CASE159, CASE160, CASE161, CASE162, CASE163, CASE164, CASE165, CASE166, CASE167, CASE168, CASE169, CASE170, CASE171, CASE172, CASE173, CASE174, CASE175, CASE176, CASE177, CASE178, CASE179, CASE180, CASE181, CASE182, CASE183, CASE184, CASE185, CASE186, CASE187, CASE188, CASE189, CASE190, CASE191, CASE192, CASE193, CASE194, CASE195, CASE196, CASE197, CASE198, CASE199, CASE200, CASE201, CASE202, CASE203, CASE204, CASE205, CASE206, CASE207, CASE208, CASE209, CASE210, CASE211, CASE212, CASE213, CASE214, CASE215, CASE216, CASE217, CASE218, CASE219, CASE220, CASE221, CASE222, CASE223, CASE224, CASE225, CASE226, CASE227, CASE228, CASE229, CASE230, CASE231, CASE232, CASE233, CASE234, CASE235, CASE236, CASE237, CASE238, CASE239, CASE240, CASE241, CASE242, CASE243, CASE244, CASE245, CASE246, CASE247, CASE248, CASE249, CASE250, CASE251, CASE252, CASE253, CASE254, CASE255, CASE256, CASE257, CASE258, CASE259, CASE260, CASE261, CASE262, CASE263, CASE264, CASE265, CASE266, CASE267, CASE268, CASE269, CASE270, CASE271, CASE272, CASE273, CASE274, CASE275, CASE276, CASE277, CASE278, CASE279, CASE280, CASE281, CASE282, CASE283, CASE284, CASE285, CASE286, CASE287, CASE288, CASE289, CASE290, CASE291, CASE292, CASE293, CASE294, CASE295, CASE296, CASE297, CASE298, CASE299, CASE300, CASE301, CASE302, CASE303, CASE304, CASE305, CASE306, CASE307, CASE308, CASE309, CASE310, CASE311, CASE312, CASE313, CASE314, CASE315, CASE316, CASE317, CASE318, CASE319, CASE320, CASE321, CASE322, CASE323, CASE324, CASE325, CASE326, CASE327, CASE328, CASE329, CASE330, CASE331, CASE332, CASE333, CASE334, CASE335, CASE336, CASE337, CASE338, CASE339, CASE340, CASE341, CASE342, CASE343, CASE344, CASE345, CASE346, CASE347, CASE348, CASE349, CASE350, CASE351, CASE352, CASE353, CASE354, CASE355, CASE356, CASE357, CASE358, CASE359, CASE360, CASE361, CASE362, CASE363, CASE364, CASE365, CASE366, CASE367, CASE368, CASE369, CASE370, CASE371, CASE372, CASE373, CASE374, CASE375, CASE376, CASE377, CASE378, CASE379, CASE380, CASE381, CASE382, CASE383, CASE384, CASE385, CASE386, CASE387, CASE388, CASE389, CASE390, CASE391, CASE392, CASE393, CASE394, CASE395, CASE396, CASE397, CASE398, CASE399, 
};

enum DATATYPE{
#define DECLARE_TYPE(v)  \
    k##v,
ALLDATATYPE(DECLARE_TYPE)
#undef DECLARE_TYPE
};



#define GEN_NAME() \
    name_ = gen_id_name();


static unsigned long g_id_counter;

static inline void reset_id_counter(){
    g_id_counter = 0;
}

static string gen_id_name(){
    return "v" + to_string(g_id_counter++);
}

class IROperator{
public:
    IROperator(string prefix="", string middle="", string suffix=""): 
        prefix_(prefix), middle_(middle), suffix_(suffix) {}

    string prefix_;
    string middle_;
    string suffix_;
};

enum UnionType{
    kUnionUnknown = 0,
    kUnionString = 1,
    kUnionFloat,
    kUnionInt,
    kUnionLong,
    kUnionBool,
};


enum DATAFLAG {
	 kUse,
	 kMapToClosestOne,
	 kNoSplit,
	 kGlobal,
	 kReplace,
	 kUndefine,
	 kAlias,
	 kMapToAll,
	 kDefine,
     kFlagUnknown
};
#define isUse(a) ((a) & kUse)
#define isMapToClosestOne(a) ((a) & kMapToClosestOne)
#define isNoSplit(a) ((a) & kNoSplit)
#define isGlobal(a) ((a) & kGlobal)
#define isReplace(a) ((a) & kReplace)
#define isUndefine(a) ((a) & kUndefine)
#define isAlias(a) ((a) & kAlias)
#define isMapToAll(a) ((a) & kMapToAll)
#define isDefine(a) ((a) & kDefine)



class IR{
public:
    IR(IRTYPE type,  IROperator * op, IR * left=NULL, IR* right=NULL):
        type_(type), op_(op), left_(left), right_(right), operand_num_((!!right)+(!!left)), data_type_(kDataWhatever){
            GEN_NAME();
        }

    IR(IRTYPE type, string str_val, DATATYPE data_type=kDataWhatever, int scope = -1, DATAFLAG flag = kUse):
        type_(type), str_val_(str_val), op_(NULL), left_(NULL), right_(NULL), operand_num_
    (0), data_type_(data_type), scope_(scope) , data_flag_(flag){
            GEN_NAME();
        }

    IR(IRTYPE type, bool b_val, DATATYPE data_type=kDataWhatever, int scope = -1, DATAFLAG flag = kUse):
        type_(type), bool_val_(b_val),left_(NULL), op_(NULL), right_(NULL), operand_num_(0), data_type_(kDataWhatever), scope_(scope) , data_flag_(flag){
            GEN_NAME();
        }
    
    IR(IRTYPE type, unsigned long long_val, DATATYPE data_type=kDataWhatever, int scope = -1, DATAFLAG flag = kUse):
        type_(type), long_val_(long_val),left_(NULL), op_(NULL), right_(NULL), operand_num_(0), data_type_(kDataWhatever), scope_(scope) , data_flag_(flag){
            GEN_NAME();
        }
    
    IR(IRTYPE type, int int_val, DATATYPE data_type=kDataWhatever, int scope = -1, DATAFLAG flag = kUse):
        type_(type), int_val_(int_val),left_(NULL), op_(NULL), right_(NULL), operand_num_(0), data_type_(kDataWhatever), scope_(scope) , data_flag_(flag){
            GEN_NAME();
    }

    IR(IRTYPE type, double f_val, DATATYPE data_type=kDataWhatever, int scope = -1, DATAFLAG flag = kUse):
        type_(type), float_val_(f_val),left_(NULL), op_(NULL), right_(NULL), operand_num_(0), data_type_(kDataWhatever), scope_(scope) , data_flag_(flag){
            GEN_NAME();
        }

    IR(IRTYPE type, IROperator * op, IR * left, IR* right, double f_val, string str_val, string name, unsigned int mutated_times, int scope, DATAFLAG flag):
        type_(type), op_(op), left_(left), right_(right), operand_num_((!!right)+(!!left)), name_(name), str_val_(str_val),
        float_val_(f_val), mutated_times_(mutated_times), data_type_(kDataWhatever), scope_(scope), data_flag_(flag){

        }

    IR(const IR* ir, IR* left, IR* right){
        this->type_ = ir->type_;
        if(ir->op_ != NULL)
            this->op_ = OP3(ir->op_->prefix_, ir->op_->middle_, ir->op_->suffix_);
        else{
            this->op_ = OP0();
        }
        this->left_ = left;
        this->right_ = right;
        this->str_val_ = ir->str_val_;
        this->long_val_ = ir->long_val_;
        this->data_type_ = ir->data_type_;
        this->scope_ = ir->scope_;
        this->data_flag_ = ir->data_flag_;
        this->name_ = ir->name_;
        this->operand_num_ = ir->operand_num_;
        this->mutated_times_ = ir->mutated_times_;
    }

    union{
        int int_val_;
        unsigned long long_val_;
        double float_val_;
        bool bool_val_;
    };

    IR* deep_copy();
    void drop();
    void deep_drop();


    int scope_;
    DATAFLAG data_flag_;
    DATATYPE data_type_;
    IRTYPE type_;
    string name_;

    string str_val_;
    //int int_val_ = 0xdeadbeef;
    //double float_val_ = 1.234;

    IROperator* op_;
    IR* left_;
    IR* right_;
    int operand_num_;
    unsigned int mutated_times_ = 0;

    string to_string();
    string to_string_core();
};



DATATYPE get_datatype_by_string(string s);

string get_string_by_ir_type(IRTYPE type);
string get_string_by_datatype(DATATYPE tt);
IR * deep_copy(const IR* const root);

void deep_delete(IR * root);

#endif
