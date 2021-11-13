#include "../include/relopt_generator.h"
#include "../include/utils.h"

pair<string, string> RelOptionGenerator::get_rel_option_pair(RelOptionType type) {

    switch (type) {
        case StorageParameters: {
            return get_rel_option_storage_parameters();
        }
        case SetConfigurationOptions: {
            return get_rel_option_set_configuration_options();
        }
        // TODO:: More options here...
        default: {
            assert(false && "Getting unknown options in the get_rel_option_pair functions. \n");
        }
    }

}


pair<string, string> RelOptionGenerator::get_rel_option_storage_parameters() {

    int rand_choice = get_rand_int(13);

    switch (rand_choice) {
        case 0: {
            string f = "fillfactor";
            int s_int = get_rand_int(10, 100);
            string s = to_string(s_int);
            return make_pair(f, s);
        }
        case 1: {
            string f = "parallel_workers";
            int s_int = get_rand_int(1024);
            string s = to_string(s_int);
            return make_pair(f, s);
        }
        case 2: {
            string f = "autovacuum_enabled";
            int s_int = get_rand_int(2);
            string s = to_string(s_int);
            return make_pair(f, s);
        }
        case 3: {
            string f = "autovacuum_vacuum_threshold";
            int s_int = get_rand_int(2147483647);
            string s = to_string(s_int);
            return make_pair(f, s);
        }
        case 4: {
            string f = "oids";
            int s_int = get_rand_int(2);
            string s = to_string(s_int);
            return make_pair(f, s);
        }
        case 5: {
            string f = "autovacuum_vacuum_scale_factor";
            vector<float> s_v_float = {0.0, 0.00001, 0.01, 0.1, 0.2, 0.5, 0.8, 0.9, 1.0};
            float s_float = vector_rand_ele(s_v_float);
            string s = to_string(s_float);
            return make_pair(f, s);
        }
        case 6: {
            string f = "autovacuum_analyze_threshold";
            int s_int = get_rand_int(RAND_MAX);
            string s = to_string(s_int);
            return make_pair(f, s);
        }
        case 7: {
            string f = "autovacuum_analyze_scale_factor";
            vector<float> s_v_float = {0.0, 0.00001, 0.01, 0.1, 0.2, 0.5, 0.8, 0.9, 1.0};
            float s_float = vector_rand_ele(s_v_float);
            string s = to_string(s_float);
            return make_pair(f, s);
        }
        case 8: {
            string f = "autovacuum_vacuum_cost_delay";
            int s_int = get_rand_int(100);
            string s = to_string(s_int);
            return make_pair(f, s);
        }
        case 9: {
            string f = "autovacuum_vacuum_cost_limit";
            int s_int = get_rand_int(1, 10000);
            string s = to_string(s_int);
            return make_pair(f, s);
        }
        case 10: {
            string f = "autovacuum_freeze_min_age";
            long long s_int = get_rand_long_long(0, 1000000000);
            string s = to_string(s_int);
            return make_pair(f, s);
        }
        case 11: {
            string f = "autovacuum_freeze_max_age";
            long long s_int = get_rand_long_long(100000, 2000000000);
            string s = to_string(s_int);
            return make_pair(f, s);
        }
        case 12: {
            string f = "autovacuum_freeze_table_age";
            long long s_int = get_rand_long_long(0, 2000000000);
            string s = to_string(s_int);
            return make_pair(f, s);
        }
        default: {
            assert(false && "Fatal Error: Finding unknown type in the get_rel_option_storage_parameters function. \n");
            return make_pair("", "");
        }
    }
}

pair<string, string> RelOptionGenerator::get_rel_option_() {

    int cur_choice = get_rand_int(1);

    switch(cur_choice) {
        case 0: {
            string f = "synchronous_commit";
            vector<string> v_str = {"remote_apply", "remote_write", "local", "off"};
            string s = vector_rand_ele(v_str);
            return make_pair(f, s);
        }
        case 1: {
            string f = "wal_compression";
            int rand_int = get_rand_int(2);
            string s = to_string(rand_int);
            return make_pair(f, s);
        }
        case 2: {
            string f = "commit_delay";
            int rand_int = get_rand_int(100000);
            string s = to_string(rand_int);
            return make_pair(f, s);
        }
        case 3: {
            string f = "commit_siblings";
            int rand_int = get_rand_int(1000);
            string s = to_string(rand_int);
            return make_pair(f, s);
        }
        case 4: {
            string f = "commit_siblings";
            int rand_int = get_rand_int(1000);
            string s = to_string(rand_int);
            return make_pair(f, s);
        }
        case 5: {
            string f = "commit_siblings";
            int rand_int = get_rand_int(2);
            string s = to_string(rand_int);
            return make_pair(f, s);
        }
        case 6: {
            string f = "track_counts";
            int rand_int = get_rand_int(2);
            string s = to_string(rand_int);
            return make_pair(f, s);
        }
        case 7: {
            string f = "track_io_timing";
            int rand_int = get_rand_int(2);
            string s = to_string(rand_int);
            return make_pair(f, s);
        }
    }

}


        TRACK_FUNCTIONS("track_functions", (r) -> Randomly.fromOptions("'none'", "'pl'", "'all'")),
        // stats_temp_directory
        // TODO 19.9.2. Statistics Monitoring
        // https://www.postgresql.org/docs/11/runtime-config-autovacuum.html
        // all can only be set at server-conf time
        // 19.11. Client Connection Defaults
        VACUUM_FREEZE_TABLE_AGE("vacuum_freeze_table_age", (r) -> Randomly.fromOptions(0, 5, 10, 100, 500, 2000000000)),
        VACUUM_FREEZE_MIN_AGE("vacuum_freeze_min_age", (r) -> Randomly.fromOptions(0, 5, 10, 100, 500, 1000000000)),
        VACUUM_MULTIXACT_FREEZE_TABLE_AGE("vacuum_multixact_freeze_table_age",
                (r) -> Randomly.fromOptions(0, 5, 10, 100, 500, 2000000000)),
        VACUUM_MULTIXACT_FREEZE_MIN_AGE("vacuum_multixact_freeze_min_age",
                (r) -> Randomly.fromOptions(0, 5, 10, 100, 500, 1000000000)),
        VACUUM_CLEANUP_INDEX_SCALE_FACTOR("vacuum_cleanup_index_scale_factor",
                (r) -> Randomly.fromOptions(0.0, 0.0000001, 0.00001, 0.01, 0.1, 1, 10, 100, 100000, 10000000000.0)),
        // TODO others
        GIN_FUZZY_SEARCH_LIMIT("gin_fuzzy_search_limit", (r) -> r.getInteger(0, 2147483647)),
        // 19.13. Version and Platform Compatibility
        DEFAULT_WITH_OIDS("default_with_oids", (r) -> Randomly.fromOptions(0, 1)),
        SYNCHRONIZED_SEQSCANS("synchronize_seqscans", (r) -> Randomly.fromOptions(0, 1)),
        // https://www.postgresql.org/docs/devel/runtime-config-query.html
        ENABLE_BITMAPSCAN("enable_bitmapscan", (r) -> Randomly.fromOptions(1, 0)),
        ENABLE_GATHERMERGE("enable_gathermerge", (r) -> Randomly.fromOptions(1, 0)),
        ENABLE_HASHJOIN("enable_hashjoin", (r) -> Randomly.fromOptions(1, 0)),
        ENABLE_INDEXSCAN("enable_indexscan", (r) -> Randomly.fromOptions(1, 0)),
        ENABLE_INDEXONLYSCAN("enable_indexonlyscan", (r) -> Randomly.fromOptions(1, 0)),
        ENABLE_MATERIAL("enable_material", (r) -> Randomly.fromOptions(1, 0)),
        ENABLE_MERGEJOIN("enable_mergejoin", (r) -> Randomly.fromOptions(1, 0)),
        ENABLE_NESTLOOP("enable_nestloop", (r) -> Randomly.fromOptions(1, 0)),
        ENABLE_PARALLEL_APPEND("enable_parallel_append", (r) -> Randomly.fromOptions(1, 0)),
        ENABLE_PARALLEL_HASH("enable_parallel_hash", (r) -> Randomly.fromOptions(1, 0)),
        ENABLE_PARTITION_PRUNING("enable_partition_pruning", (r) -> Randomly.fromOptions(1, 0)),
        ENABLE_PARTITIONWISE_JOIN("enable_partitionwise_join", (r) -> Randomly.fromOptions(1, 0)),
        ENABLE_PARTITIONWISE_AGGREGATE("enable_partitionwise_aggregate", (r) -> Randomly.fromOptions(1, 0)),
        ENABLE_SEGSCAN("enable_seqscan", (r) -> Randomly.fromOptions(1, 0)),
        ENABLE_SORT("enable_sort", (r) -> Randomly.fromOptions(1, 0)),
        ENABLE_TIDSCAN("enable_tidscan", (r) -> Randomly.fromOptions(1, 0)),
        // 19.7.2. Planner Cost Constants (complete as of March 2020)
        // https://www.postgresql.org/docs/current/runtime-config-query.html#RUNTIME-CONFIG-QUERY-CONSTANTS
        SEQ_PAGE_COST("seq_page_cost", (r) -> Randomly.fromOptions(0d, 0.00001, 0.05, 0.1, 1, 10, 10000)),
        RANDOM_PAGE_COST("random_page_cost", (r) -> Randomly.fromOptions(0d, 0.00001, 0.05, 0.1, 1, 10, 10000)),
        CPU_TUPLE_COST("cpu_tuple_cost", (r) -> Randomly.fromOptions(0d, 0.00001, 0.05, 0.1, 1, 10, 10000)),
        CPU_INDEX_TUPLE_COST("cpu_index_tuple_cost", (r) -> Randomly.fromOptions(0d, 0.00001, 0.05, 0.1, 1, 10, 10000)),
        CPU_OPERATOR_COST("cpu_operator_cost", (r) -> Randomly.fromOptions(0d, 0.000001, 0.0025, 0.1, 1, 10, 10000)),
        PARALLEL_SETUP_COST("parallel_setup_cost", (r) -> r.getLong(0, Long.MAX_VALUE)),
        PARALLEL_TUPLE_COST("parallel_tuple_cost", (r) -> r.getLong(0, Long.MAX_VALUE)),
        MIN_PARALLEL_TABLE_SCAN_SIZE("min_parallel_table_scan_size", (r) -> r.getInteger(0, 715827882)),
        MIN_PARALLEL_INDEX_SCAN_SIZE("min_parallel_index_scan_size", (r) -> r.getInteger(0, 715827882)),
        EFFECTIVE_CACHE_SIZE("effective_cache_size", (r) -> r.getInteger(1, 2147483647)),
        JIT_ABOVE_COST("jit_above_cost", (r) -> Randomly.fromOptions(0, r.getLong(-1, Long.MAX_VALUE - 1))),
        JIT_INLINE_ABOVE_COST("jit_inline_above_cost", (r) -> Randomly.fromOptions(0, r.getLong(-1, Long.MAX_VALUE))),
        JIT_OPTIMIZE_ABOVE_COST("jit_optimize_above_cost",
                (r) -> Randomly.fromOptions(0, r.getLong(-1, Long.MAX_VALUE))),
        // 19.7.3. Genetic Query Optimizer (complete as of March 2020)
        // https://www.postgresql.org/docs/current/runtime-config-query.html#RUNTIME-CONFIG-QUERY-GEQO
        GEQO("geqo", (r) -> Randomly.fromOptions(1, 0)),
        GEQO_THRESHOLD("geqo_threshold", (r) -> r.getInteger(2, 2147483647)),
        GEQO_EFFORT("geqo_effort", (r) -> r.getInteger(1, 10)),
        GEQO_POO_SIZE("geqo_pool_size", (r) -> r.getInteger(0, 2147483647)),
        GEQO_GENERATIONS("geqo_generations", (r) -> r.getInteger(0, 2147483647)),
        GEQO_SELECTION_BIAS("geqo_selection_bias", (r) -> Randomly.fromOptions(1.5, 1.8, 2.0)),
        GEQO_SEED("geqo_seed", (r) -> Randomly.fromOptions(0, 0.5, 1)),
        // 19.7.4. Other Planner Options (complete as of March 2020)
        // https://www.postgresql.org/docs/current/runtime-config-query.html#RUNTIME-CONFIG-QUERY-OTHER
        DEFAULT_STATISTICS_TARGET("default_statistics_target", (r) -> r.getInteger(1, 10000)),
        CONSTRAINT_EXCLUSION("constraint_exclusion", (r) -> Randomly.fromOptions("on", "off", "partition")),
        CURSOR_TUPLE_FRACTION("cursor_tuple_fraction",
                (r) -> Randomly.fromOptions(0.0, 0.1, 0.000001, 1, 0.5, 0.9999999)),
        FROM_COLLAPSE_LIMIT("from_collapse_limit", (r) -> r.getInteger(1, Integer.MAX_VALUE)),
        JIT("jit", (r) -> Randomly.fromOptions(1, 0)),
        JOIN_COLLAPSE_LIMIT("join_collapse_limit", (r) -> r.getInteger(1, Integer.MAX_VALUE)),
        PARALLEL_LEADER_PARTICIPATION("parallel_leader_participation", (r) -> Randomly.fromOptions(1, 0)),
        FORCE_PARALLEL_MODE("force_parallel_mode", (r) -> Randomly.fromOptions("off", "on", "regress")),
        PLAN_CACHE_MODE("plan_cache_mode",
                (r) -> Randomly.fromOptions("auto", "force_generic_plan", "force_custom_plan"));
