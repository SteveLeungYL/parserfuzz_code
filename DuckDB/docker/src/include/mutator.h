#ifndef __MUTATOR_H__
#define __MUTATOR_H__

#include "sql_ir_define.hpp"
#include "utils.h"
#include "../include/ir_wrapper.h"
#include "../oracle/duckdb_oracle.h"

#include <set>
#include <map>

#define LUCKY_NUMBER 500

using namespace duckdb_libpgquery;

using namespace std;

enum RELATIONTYPE{
    kRelationElement,
    kRelationSubtype,
    kRelationAlias,
};

enum COLTYPE {
    UNKNOWN_T,
    INT_T,
    FLOAT_T,
    BOOLEAN_T,
    STRING_T
};

enum STMT_TYPE {
    NOT_ORACLE = 0,
    ORACLE_SELECT = 1,
    ORACLE_NORMAL = 2
};

class SQL_ORACLE;

static unsigned long g_id_counter;

static inline void reset_id_counter(){
    g_id_counter = 0;
}

static string gen_id_name() { return "v" + to_string(g_id_counter++); }
static string gen_view_name() {return "view" + to_string(g_id_counter++);}
static string gen_column_name() {return "c" + to_string(g_id_counter++); }
static string gen_index_name() {return "i" + to_string(g_id_counter++); }
static string gen_alias_name() { return "a" + to_string(g_id_counter++); }
static string gen_statistic_name() {return "stat" + to_string(g_id_counter++);}
static string gen_sequence_name() {return "seq" + to_string(g_id_counter++);}

class Mutator{

public:
    Mutator(){
        srand(time(nullptr));
    }

    unsigned long hash(IR* );
    unsigned long hash(string &);

    int get_valid_collection_size();
    int get_collection_size();

    IR * locate_parent(IR* root, IR * old_ir) ; //done

    void init_library();

    void init_value_library();//DONE
    void init_common_string(string filename);//DONE

    void pre_validate();

    vector<IR*> pre_fix_transform(IR*, vector<STMT_TYPE>&);
    vector<vector<vector<IR* > > > post_fix_transform(vector<IR*>& all_pre_trans_vec, vector<STMT_TYPE>& stmt_type_vec);
    vector<vector<IR* > > post_fix_transform(vector<IR*>& all_pre_trans_vec, vector<STMT_TYPE>& stmt_type_vec, int run_count);

    pair<string, string> ir_to_string(IR* root, vector<vector<IR* > > all_post_trans_vec, const vector<STMT_TYPE>& stmt_type_vec);

    string get_a_string() ; //DONE
    unsigned long get_a_val() ; //DONE

    string get_data_by_type(DATATYPE) ;
    pair<string, string> get_data_2d_by_type(DATATYPE, DATATYPE); //DONE

    void reset_data_library();
    void reset_data_library_single_stmt();
    void rollback_data_library();
    void backup_data_library();

    vector<IR *> split_to_stmt(IR * root, map<IR**, IR*> &m_save, set<IRTYPE> &split_set);//done


    // bool connect_back(map<IR**, IR*> &m_save); //done
    bool connect_back(map<IR *, pair<bool, IR* > > &m_save);

    void fix_preprocessing(IR *stmt_root, vector<IR*> &ordered_all_subquery_ir);
    bool fix_dependency(IR* cur_stmt_root, const vector<vector<IR* > > cur_stmt_ir_to_fix_vec, bool is_debug_info=false);

    bool fix_one(IR * stmt_root, map<int, map<DATATYPE, vector<IR* >  > > &scope_library);//done

    IR * find_closest_node(IR * stmt_root, IR * node, DATATYPE type); //done

    bool validate(IR * root, bool is_debug_info = false);
    bool fix_one_stmt(IR *cur_stmt, bool is_debug_info = false);
    vector<IR *> split_to_substmt(IR *cur_stmt, map<IR *, pair<bool, IR* > > &m_save,
                                  set<IRTYPE> &split_set);

    void debug(IR * root);
    void debug(IR * root, unsigned level);


    vector<string> string_library_;
    set<unsigned long> string_library_hash_;
    vector<unsigned long> value_library_;

    vector<string> common_string_library_;
    set<IRTYPE> string_types_;
    set<IRTYPE> int_types_;
    set<IRTYPE> float_types_;

    set<IRTYPE> split_stmt_types_;
    set<IRTYPE> split_substmt_types_;

    SQL_ORACLE *p_oracle;

    string extract_struct(IR* root);
    void _extract_struct(IR* root);

//    bool add_missing_create_table_stmt(IR* ir_root);
//    bool correct_insert_stmt(IR* ir_root);

    /* Info used by validate function. */

    static set<IR *> visited;                                  // Already validated/fixed node. Avoid multiple fixing.
    static map<string, vector<string > > m_tables;               // Table name to column name mapping.
    static map<string, vector<string > > m_table2index;          // Table name to index mapping.
    static vector<string> v_table_names;                       // All saved table names
    static vector<string> v_table_names_single;                // All used table names in one query statement.
    static vector<string> v_create_table_names_single;         // All table names just created in the current stmt.
    static vector<string> v_alias_names_single;                // All alias name local to one query statement.
    static map<string, vector<string > > m_table2alias_single;   // Table name to alias mapping.
    static map<string, COLTYPE> m_column2datatype;             // Column name mapping to column type. 0 means unknown, 1 means static numerical, 2 means character_type_, 3 means boolean_type_.
    static vector<string> v_column_names_single;               // All used column names in one query statement. Used to confirm static literal type.
    static vector<string> v_table_name_follow_single;          // All used table names follow type in one query stmt.
    static vector<string> v_statistics_name;                   // All statistic names defined in the current stmt.
    static vector<string> v_sequence_name;                     // All sequence names defined in the current SQL.
    static vector<string> v_view_name;                         // All saved view names.
    static vector<string> v_constraint_name;                   // All constraint names defined in the current SQL.
    static vector<string> v_foreign_table_name;                // All foreign table names defined inthe current SQL.
    static vector<string> v_create_foreign_table_names_single; // All foreign table names created in the current SQL.
    static vector<string> v_table_with_partition_name;

    static vector<string> v_database_name_follow_single;       // All used database name follow in the query. Either test_sqlright1 or mysql.

    static map<string, vector<string > > m_tables_backup;               // Table name to column name mapping.
    static map<string, vector<string > > m_table2index_backup;          // Table name to index mapping.
    static vector<string> v_table_names_backup;                       // All saved table names
    static vector<string> v_statistics_name_backup;                   // All statistic names defined in the current stmt.
    static vector<string> v_sequence_name_backup;                     // All sequence names defined in the current SQL.
    static vector<string> v_view_name_backup;                         // All saved view names.
    static vector<string> v_constraint_name_backup;                   // All constraint names defined in the current SQL.
    static vector<string> v_foreign_table_name_backup;                // All foreign table names defined inthe current SQL.
    static vector<string> v_table_with_partition_name_backup;
    static vector<int> v_int_literals_backup;
    static vector<double> v_float_literals_backup;
    static vector<string> v_string_literals_backup;

    // map<IRTYPE, vector<pair<string, DEF_ARG_TYPE >  > > m_reloption;
    static vector<string> v_sys_column_name;
    static vector<string> v_sys_catalogs_name;

    static vector<string> v_aggregate_func;

    static vector<string> v_saved_reloption_str;

    static vector<int> v_int_literals;
    static vector<double> v_float_literals;
    static vector<string> v_string_literals;
};



#endif
