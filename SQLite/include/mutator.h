#ifndef __MUTATOR_H__
#define __MUTATOR_H__


#include "ast.h"
#include "define.h"
#include "utils.h"
#include "../oracle/sqlite_oracle.h"

#define LUCKY_NUMBER 500

using namespace std;

class Mutator{

public:
    Mutator(){
        srand(time(nullptr));
    }

    void set_dump_library(bool);

    vector<string> string_splitter(string, string);

    IR * deep_copy_with_record(const IR * root, const IR * record);
    unsigned long hash(IR* );
    unsigned long hash(string);

    bool make_current_node_as_norec_select_stmt(IR* root);
    bool mark_all_norec_select_stmt(vector<IR *> &v_ir_collector);
    vector<string *> mutate_all(vector<IR*> &v_ir_collector);

    vector<IR*> mutate(IR* input);  
    IR * strategy_delete(IR * cur);
    IR * strategy_insert(IR * cur);
    IR * strategy_replace(IR * cur);

    bool replace(IR * root , IR* old_ir, IR* new_ir);
    IR * find_child_with_type_and_parent(const vector<IR *> &v_ir_collector, NODETYPE node_type, IR * parent);
    string validate(string query);
    string validate(IR * root); 

    void minimize(vector<IR*> &);
    bool lucky_enough_to_be_mutated(unsigned int mutated_times);

    int get_ir_libary_2D_hash_kStatement_size();
    int get_norec_select_collection_size();

    vector<IR*> parse_query_str_get_ir_set(string &query_str);
    string get_random_mutated_valid_stmt();

    void add_all_to_library(IR*);
    void add_all_to_library(string);
    IR* get_from_libary_with_type(IRTYPE);
    IR* get_from_libary_with_left_type(IRTYPE);
    IR* get_from_libary_with_right_type(IRTYPE);

    bool is_stripped_str_in_lib(string stripped_str);

    void init(string f_testcase, string f_common_string = "", string pragma = "");
    string fix(IR * root);
    void _fix(IR * root, string &);
    string extract_struct(IR * root);
    void _extract_struct(IR * root, string &);
    string extract_struct(string);
    string extract_struct2(IR * root);
    void add_new_table(IR * root, string &table_name);
    void reset_database();

    bool check_node_num(IR * root, unsigned int limit);
    vector<IR *> extract_statement(IR * root);
    unsigned int calc_node(IR * root);

    map<IR*, set<IR*>> build_dependency_graph(IR* root, map<IDTYPE,IDTYPE> &relationmap, map<IDTYPE,IDTYPE> &crssmap, vector<IR*>& ordered_ir);
    vector<IR *> cut_subquery(IR * program, map<IR**, IR*> &m_save);
    bool fix_back(map<IR**, IR*> &m_save);
    void fix_one(map<IR*, set<IR*>> &graph, IR* fixed_key, set<IR*> &visited);
    void fix_graph(map<IR*, set<IR*>> &graph, IR* root, vector<IR*>& ordered_ir);

    string get_a_string(); 
    unsigned long get_a_val();
    static vector<string> common_string_libary;
    static vector<unsigned long> value_libary;
    static map<string, vector<string>> m_tables;
    static vector<string> v_table_names;
    ~Mutator();
    
    void debug(IR * root);
    unsigned long get_library_size();
    void get_memory_usage();
    int try_fix(char* buf, int len, char* &new_buf, int &new_len);

    unsigned long total_temp = 0;
    unsigned long total_random_norec = 0;

private:
    void add_to_norec_lib(IR*, string&);
    void add_to_library(IR*, string&);
    void add_to_library_core(IR*, string*);

    bool dump_library = false;

    IR * record_ = NULL;
    //map<NODETYPE, map<NODETYPE, vector<IR*>> > ir_libary_3D_; 
    //map<NODETYPE, map<NODETYPE, set<unsigned long>> > ir_libary_3D_hash_;
    map<NODETYPE, set<unsigned long> > ir_libary_2D_hash_;
    set<unsigned long> stripped_string_hash_;
    // map<NODETYPE, vector<IR*> > ir_libary_2D_;
    // map<NODETYPE, vector<IR *>> left_lib;
    // map<NODETYPE, vector<IR *>> right_lib;
    vector<string> string_libary;
    map<IDTYPE, IDTYPE> relationmap;
    map<IDTYPE, IDTYPE> cross_map;
    set<unsigned long> string_libary_hash_;

    vector<string> cmds_;
    map<string, vector<string>> m_cmd_value_lib_;

    string s_table_name;
    
    map<NODETYPE, int> type_counter_;

    /* The interface of saving the required context for the mutator. Giving the NODETYPE, we should be able to extract all the related IR nodes from this library.
        The string* points to the string of the complete query stmt where the current NODE is from.
        And the int is the unique ID for the specific node, 
            can be used to identify and extract the specific node from the IR tree when the tree is being reconstructed. 
    */
    map<NODETYPE, vector<pair<string*, int>>> real_ir_set;
    map<NODETYPE, vector<pair<string*, int>>> left_lib_set;
    map<NODETYPE, vector<pair<string*, int>>> right_lib_set;

    map<unsigned long, bool> norec_hash;
    set<string*> all_query_pstr_set;
    vector<string*> all_valid_pstr_vec;

    SQL_ORACLE* p_oracle;
};


#endif
