#ifndef __MUTATOR_H__
#define __MUTATOR_H__


#include "ast.h"
#include "sql/sql_ir_define.h"
#include "utils.h"
#include "../oracle/mysql_oracle.h"
#include "../include/ir_wrapper.h"

#include <set>
#include <map>

#define LUCKY_NUMBER 500

using namespace std;

enum RELATIONTYPE{
    kRelationElement,
    kRelationSubtype,
    kRelationAlias,
};

enum STMT_TYPE {
  NOT_ORACLE = 0,
  ORACLE_SELECT = 1,
  ORACLE_NORMAL = 2
};

class SQL_ORACLE;

class Mutator{

public:
    Mutator(){
        srand(time(nullptr));
    }

    IR * deep_copy_with_record(const IR * root, const IR * record);
    unsigned long hash(IR* );
    unsigned long hash(string &);

    IR * ir_random_generator(vector<IR *> v_ir_collector);

    vector<IR *> mutate_all(IR* ori_ir_root, IR* ir_to_mutate, u64& total_mutate_failed, u64& total_mutate_num);
    vector<IR*> mutate(IR* input); //done
    IR * strategy_delete(IR * cur); //Done
    IR * strategy_insert(IR * cur); //Done
    IR * strategy_replace(IR * cur);  //done
    bool lucky_enough_to_be_mutated(unsigned int mutated_times); //done

    bool replace(IR* root, IR* old_ir, IR* new_ir); //done
    IR * locate_parent(IR* root, IR * old_ir) ; //done


    void init(string f_testcase = "", string f_common_string = "", string file2d = "", string file1d = "", string f_gen_type = "");//DONE

    void init_ir_library(string filename);//DONE
    void init_value_library();//DONE
    void init_common_string(string filename);//DONE
    void init_data_library(string filename);//DONE
    void init_data_library_2d(string filename);//DONE
    void init_not_mutatable_type(string filename);//DONE
    void init_safe_generate_type(string filename);
    void add_ir_to_library(IR*);//DONE

    void set_p_oracle(SQL_ORACLE *oracle) { this->p_oracle = oracle; }
    void set_dump_library(bool to_dump) { this->dump_library = to_dump; }

    void pre_validate();

    vector<IR*> pre_fix_transform(IR*, vector<STMT_TYPE>&);
    vector<vector<vector<IR*>>> post_fix_transform(vector<IR*>& all_pre_trans_vec, vector<STMT_TYPE>& stmt_type_vec);
    vector<vector<IR*>> post_fix_transform(vector<IR*>& all_pre_trans_vec, vector<STMT_TYPE>& stmt_type_vec, int run_count);

    pair<string, string> ir_to_string(IR* root, vector<vector<IR*>> all_post_trans_vec, const vector<STMT_TYPE>& stmt_type_vec);

    string get_a_string() ; //DONE
    unsigned long get_a_val() ; //DONE
    IR* get_ir_from_library(IRTYPE);//DONE
    IR* generate_ir_by_type(IRTYPE) ; //Done

    string get_data_by_type(DATATYPE) ;
    pair<string, string> get_data_2d_by_type(DATATYPE, DATATYPE); //DONE

    void reset_data_library(); //DONE

    string parse_data(string &) ;//DONE

    bool fix(IR * root);//done

    vector<IR *> split_to_stmt(IR * root, map<IR**, IR*> &m_save, set<IRTYPE> &split_set);//done
    bool connect_back(map<IR**, IR*> &m_save); //done

    bool fix_one(IR * stmt_root, map<int, map<DATATYPE, vector<IR*>>> &scope_library);//done

    void analyze_scope(IR * stmt_root);
    map<IR*, vector<IR*>> build_graph(IR * stmt_root, map<int, map<DATATYPE, vector<IR*>>> &scope_library);
    bool fill_stmt_graph(map<IR*, vector<IR*>> &graph); //done
    void clear_scope_library(bool clear_define);// done
    IR * find_closest_node(IR * stmt_root, IR * node, DATATYPE type); //done
    bool fill_one(IR* parent); //done
    bool fill_one_pair(IR* parent, IR* child); //done
    bool fill_stmt_graph_one(map<IR*, vector<IR*>> &graph, IR* ir);//done
    bool validate(IR * &root); //done
    
    bool replace_one_value_from_datalibray_2d(DATATYPE p_datatype, DATATYPE c_data_type, string &p_key, string &old_c_value, string &new_c_value);
    bool remove_one_pair_from_datalibrary_2d(DATATYPE p_datatype, DATATYPE c_data_type, string &p_key);
    bool replace_one_from_datalibrary(DATATYPE datatype, string &old_str, string &new_str);
    bool remove_one_from_datalibrary(DATATYPE datatype, string& key);
    ~Mutator();
    void debug(IR * root);
    void debug(IR * root, unsigned level);
    int try_fix(char* buf, int len, char* &new_buf, int &new_len);


    void add_ir_to_library_no_deepcopy(IR*);//DONE

    IR* record_ = NULL;
    IR* mutated_root_  = NULL;
    map<IRTYPE, vector<IR*>> ir_library_;
    map<IRTYPE, set<unsigned long>> ir_library_hash_;

    vector<string> string_library_;
    set<unsigned long> string_library_hash_;
    vector<unsigned long> value_library_;
    
    map<DATATYPE, map<DATATYPE, RELATIONTYPE>> relationmap_;

    vector<string> common_string_library_;
    set<IRTYPE> not_mutatable_types_;
    set<IRTYPE> string_types_;
    set<IRTYPE> int_types_;
    set<IRTYPE> float_types_;

    set<IRTYPE> safe_generate_type_;
    set<IRTYPE> split_stmt_types_;
    set<IRTYPE> split_substmt_types_;

    map<DATATYPE, vector<string>> data_library_;
    map<DATATYPE, map<string, map<DATATYPE, vector<string>>>> data_library_2d_;

    map<DATATYPE, vector<string>> g_data_library_;
    map<DATATYPE, set<unsigned long>> g_data_library_hash_;
    map<DATATYPE, map<string, map<DATATYPE, vector<string>>>> g_data_library_2d_;
    map<DATATYPE, map<string, map<DATATYPE, vector<string>>>> g_data_library_2d_hash_;
    
    
    map<int, map<DATATYPE, vector<IR*>>> scope_library_;

    set<unsigned long> global_hash_;

    map<unsigned long, bool> norec_hash;
    vector<string *> all_valid_pstr_vec;
    vector<string *> all_cri_valid_pstr_vec;
    set<string *> all_query_pstr_set;
    map<IRTYPE, set<unsigned long>> ir_libary_2D_hash_;
    set<unsigned long> stripped_string_hash_;

    bool dump_library = false;
    SQL_ORACLE *p_oracle;

    /* The interface of saving the required context for the mutator. Giving the
        IRTYPE, we should be able to extract all the related IR nodes from this
        library. The string* points to the string of the complete query stmt where
        the current NODE is from. And the int is the unique ID for the specific
        node, can be used to identify and extract the specific node from the IR
        tree when the tree is being reconstructed.
    */
    map<IRTYPE, vector<pair<string *, int>>> real_ir_set;
    map<IRTYPE, vector<pair<string *, int>>> left_lib_set;
    map<IRTYPE, vector<pair<string *, int>>> right_lib_set;

    bool get_valid_str_from_lib(string &ori_norec_select);
    bool check_node_num(IR *root, unsigned int limit);
    unsigned int calc_node(IR *root);

    string extract_struct(IR* root);
    void _extract_struct(IR* root);

};



#endif
