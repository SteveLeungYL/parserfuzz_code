/*

query:

    END_OF_INPUT {
        auto tmp1 = $1;
        res = new IR(kQuery, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | directly_executable_statement {} ';' opt_end_of_input {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kQuery_1, OP3("", "", ";"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kQuery, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | directly_executable_statement END_OF_INPUT {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kQuery, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_end_of_input:

    END_OF_INPUT {
        auto tmp1 = $1;
        res = new IR(kOptEndOfInput, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | END_OF_INPUT {
        auto tmp1 = $1;
        res = new IR(kOptEndOfInput, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


directly_executable_statement:

    statement {
        auto tmp1 = $1;
        res = new IR(kDirectlyExecutableStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | begin_stmt_mariadb {
        auto tmp1 = $1;
        res = new IR(kDirectlyExecutableStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | compound_statement {
        auto tmp1 = $1;
        res = new IR(kDirectlyExecutableStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



verb_clause:

    alter {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | analyze {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | analyze_stmt_command {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | backup {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | binlog_base64_event {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | call {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | change {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | check {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | checksum {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | commit {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | create {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | deallocate {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | delete {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | describe {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | do {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | drop {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | execute {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | explain_for_connection {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | flush {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | get_diagnostics {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | grant {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | handler {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | help {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | insert {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | install {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keep_gcc_happy {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keycache {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | kill {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | load {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | lock {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | optimize {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | parse_vcol_expr {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | partition_entry {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | preload {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | prepare {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | purge {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | raise_stmt_oracle {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | release {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | rename {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | repair {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | replace {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | reset {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | resignal_stmt {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | revoke {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | rollback {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | savepoint {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | select {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | select_into {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | set {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | signal_stmt {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | show {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | shutdown {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | slave {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | start {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | truncate {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | uninstall {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | unlock {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | update {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | use {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | xa {
        auto tmp1 = $1;
        res = new IR(kVerbClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


deallocate:

    deallocate_or_drop PREPARE_SYM ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDeallocate, OP3("", "PREPARE_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

;


deallocate_or_drop:

    DEALLOCATE_SYM {
        res = new IR(kDeallocateOrDrop, OP3("DEALLOCATE_SYM", "", ""));
        $$ = res;
    }

    | DROP {
        res = new IR(kDeallocateOrDrop, OP3("DROP", "", ""));
        $$ = res;
    }

;


prepare:

    PREPARE_SYM ident FROM {} expr {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kPrepare_1, OP3("PREPARE_SYM", "FROM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kPrepare, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


execute:

    EXECUTE_SYM ident execute_using {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kExecute, OP3("EXECUTE_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | EXECUTE_SYM IMMEDIATE_SYM {} expr {} execute_using {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kExecute_1, OP3("EXECUTE_SYM IMMEDIATE_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kExecute_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kExecute, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


execute_using:

    {} {
        auto tmp1 = $1;
        res = new IR(kExecuteUsing, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | USING {} execute_params {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kExecuteUsing, OP3("USING", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


execute_params:

    expr_or_ignore_or_default {
        auto tmp1 = $1;
        res = new IR(kExecuteParams, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | execute_params ',' expr_or_ignore_or_default {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExecuteParams, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;





help:

    HELP_SYM {} ident_or_text {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kHelp, OP3("HELP_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;




change:

    CHANGE MASTER_SYM optional_connection_name TO_SYM {} master_defs optional_for_channel {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kChange_1, OP3("CHANGE MASTER_SYM", "TO_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kChange_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $7;
        res = new IR(kChange, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


master_defs:

    master_def {
        auto tmp1 = $1;
        res = new IR(kMasterDefs, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | master_defs ',' master_def {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kMasterDefs, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


master_def:

    MASTER_HOST_SYM '=' TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kMasterDef, OP3("MASTER_HOST_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | MASTER_USER_SYM '=' TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kMasterDef, OP3("MASTER_USER_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | MASTER_PASSWORD_SYM '=' TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kMasterDef, OP3("MASTER_PASSWORD_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | MASTER_PORT_SYM '=' ulong_num {
        auto tmp1 = $3;
        res = new IR(kMasterDef, OP3("MASTER_PORT_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | MASTER_CONNECT_RETRY_SYM '=' ulong_num {
        auto tmp1 = $3;
        res = new IR(kMasterDef, OP3("MASTER_CONNECT_RETRY_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | MASTER_DELAY_SYM '=' ulong_num {
        auto tmp1 = $3;
        res = new IR(kMasterDef, OP3("MASTER_DELAY_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | MASTER_SSL_SYM '=' ulong_num {
        auto tmp1 = $3;
        res = new IR(kMasterDef, OP3("MASTER_SSL_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | MASTER_SSL_CA_SYM '=' TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kMasterDef, OP3("MASTER_SSL_CA_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | MASTER_SSL_CAPATH_SYM '=' TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kMasterDef, OP3("MASTER_SSL_CAPATH_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | MASTER_SSL_CERT_SYM '=' TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kMasterDef, OP3("MASTER_SSL_CERT_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | MASTER_SSL_CIPHER_SYM '=' TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kMasterDef, OP3("MASTER_SSL_CIPHER_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | MASTER_SSL_KEY_SYM '=' TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kMasterDef, OP3("MASTER_SSL_KEY_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | MASTER_SSL_VERIFY_SERVER_CERT_SYM '=' ulong_num {
        auto tmp1 = $3;
        res = new IR(kMasterDef, OP3("MASTER_SSL_VERIFY_SERVER_CERT_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | MASTER_SSL_CRL_SYM '=' TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kMasterDef, OP3("MASTER_SSL_CRL_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | MASTER_SSL_CRLPATH_SYM '=' TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kMasterDef, OP3("MASTER_SSL_CRLPATH_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | MASTER_HEARTBEAT_PERIOD_SYM '=' NUM_literal {
        auto tmp1 = $3;
        res = new IR(kMasterDef, OP3("MASTER_HEARTBEAT_PERIOD_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | IGNORE_SERVER_IDS_SYM '=' '(' ignore_server_id_list ')' {
        auto tmp1 = $4;
        res = new IR(kMasterDef, OP3("IGNORE_SERVER_IDS_SYM = (", ")", ""), tmp1);
        $$ = res;
    }

    | DO_DOMAIN_IDS_SYM '=' '(' do_domain_id_list ')' {
        auto tmp1 = $4;
        res = new IR(kMasterDef, OP3("DO_DOMAIN_IDS_SYM = (", ")", ""), tmp1);
        $$ = res;
    }

    | IGNORE_DOMAIN_IDS_SYM '=' '(' ignore_domain_id_list ')' {
        auto tmp1 = $4;
        res = new IR(kMasterDef, OP3("IGNORE_DOMAIN_IDS_SYM = (", ")", ""), tmp1);
        $$ = res;
    }

    | master_file_def {
        auto tmp1 = $1;
        res = new IR(kMasterDef, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ignore_server_id_list:

    ignore_server_id {
        auto tmp1 = $1;
        res = new IR(kIgnoreServerIdList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ignore_server_id {
        auto tmp1 = $1;
        res = new IR(kIgnoreServerIdList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ignore_server_id_list ',' ignore_server_id {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kIgnoreServerIdList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


ignore_server_id:

    ulong_num {
        auto tmp1 = $1;
        res = new IR(kIgnoreServerId, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


do_domain_id_list:

    do_domain_id {
        auto tmp1 = $1;
        res = new IR(kDoDomainIdList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | do_domain_id {
        auto tmp1 = $1;
        res = new IR(kDoDomainIdList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | do_domain_id_list ',' do_domain_id {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDoDomainIdList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


do_domain_id:

    ulong_num {
        auto tmp1 = $1;
        res = new IR(kDoDomainId, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ignore_domain_id_list:

    ignore_domain_id {
        auto tmp1 = $1;
        res = new IR(kIgnoreDomainIdList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ignore_domain_id {
        auto tmp1 = $1;
        res = new IR(kIgnoreDomainIdList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ignore_domain_id_list ',' ignore_domain_id {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kIgnoreDomainIdList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


ignore_domain_id:

    ulong_num {
        auto tmp1 = $1;
        res = new IR(kIgnoreDomainId, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


master_file_def:

    MASTER_LOG_FILE_SYM '=' TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kMasterFileDef, OP3("MASTER_LOG_FILE_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | MASTER_LOG_POS_SYM '=' ulonglong_num {
        auto tmp1 = $3;
        res = new IR(kMasterFileDef, OP3("MASTER_LOG_POS_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | RELAY_LOG_FILE_SYM '=' TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kMasterFileDef, OP3("RELAY_LOG_FILE_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | RELAY_LOG_POS_SYM '=' ulong_num {
        auto tmp1 = $3;
        res = new IR(kMasterFileDef, OP3("RELAY_LOG_POS_SYM =", "", ""), tmp1);
        $$ = res;
    }

    | MASTER_USE_GTID_SYM '=' CURRENT_POS_SYM {
        res = new IR(kMasterFileDef, OP3("MASTER_USE_GTID_SYM = CURRENT_POS_SYM", "", ""));
        $$ = res;
    }

    | MASTER_USE_GTID_SYM '=' SLAVE_POS_SYM {
        res = new IR(kMasterFileDef, OP3("MASTER_USE_GTID_SYM = SLAVE_POS_SYM", "", ""));
        $$ = res;
    }

    | MASTER_USE_GTID_SYM '=' NO_SYM {
        res = new IR(kMasterFileDef, OP3("MASTER_USE_GTID_SYM = NO_SYM", "", ""));
        $$ = res;
    }

    | MASTER_DEMOTE_TO_SLAVE_SYM '=' bool {
        auto tmp1 = $3;
        res = new IR(kMasterFileDef, OP3("MASTER_DEMOTE_TO_SLAVE_SYM =", "", ""), tmp1);
        $$ = res;
    }

;


optional_connection_name:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptionalConnectionName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | connection_name {
        auto tmp1 = $1;
        res = new IR(kOptionalConnectionName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


connection_name:

    TEXT_STRING_sys {
        auto tmp1 = $1;
        res = new IR(kConnectionName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


optional_for_channel:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptionalForChannel, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | for_channel {
        auto tmp1 = $1;
        res = new IR(kOptionalForChannel, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


for_channel:

    FOR_SYM CHANNEL_SYM TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kForChannel, OP3("FOR_SYM CHANNEL_SYM", "", ""), tmp1);
        $$ = res;
    }

;




create:

    create_or_replace opt_temporary TABLE_SYM opt_if_not_exists {} table_ident {} create_body {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreate_1, OP3("", "", "TABLE_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kCreate_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kCreate_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kCreate_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $7;
        res = new IR(kCreate_5, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $8;
        res = new IR(kCreate, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

    | create_or_replace opt_temporary SEQUENCE_SYM opt_if_not_exists table_ident {} opt_sequence opt_create_table_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreate_6, OP3("", "", "SEQUENCE_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kCreate_7, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kCreate_8, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kCreate_9, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $7;
        res = new IR(kCreate_10, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $8;
        res = new IR(kCreate, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

    | create_or_replace INDEX_SYM opt_if_not_exists {} ident opt_key_algorithm_clause ON table_ident {} '(' key_list ')' opt_lock_wait_timeout normal_key_options opt_index_lock_algorithm {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCreate_11, OP3("", "INDEX_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kCreate_12, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kCreate_13, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kCreate_14, OP3("", "", "ON"), res, tmp5);
        PUSH(res);
        auto tmp6 = $8;
        res = new IR(kCreate_15, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $9;
        res = new IR(kCreate_16, OP3("", "", "("), res, tmp7);
        PUSH(res);
        auto tmp8 = $11;
        res = new IR(kCreate_17, OP3("", "", ")"), res, tmp8);
        PUSH(res);
        auto tmp9 = $13;
        res = new IR(kCreate_18, OP3("", "", ""), res, tmp9);
        PUSH(res);
        auto tmp10 = $14;
        res = new IR(kCreate_19, OP3("", "", ""), res, tmp10);
        PUSH(res);
        auto tmp11 = $15;
        res = new IR(kCreate, OP3("", "", ""), res, tmp11);
        $$ = res;
    }

    | create_or_replace UNIQUE_SYM INDEX_SYM opt_if_not_exists {} ident opt_key_algorithm_clause ON table_ident {} '(' key_list opt_without_overlaps ')' opt_lock_wait_timeout normal_key_options opt_index_lock_algorithm {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kCreate_20, OP3("", "UNIQUE_SYM INDEX_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kCreate_21, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kCreate_22, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kCreate_23, OP3("", "", "ON"), res, tmp5);
        PUSH(res);
        auto tmp6 = $9;
        res = new IR(kCreate_24, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $10;
        res = new IR(kCreate_25, OP3("", "", "("), res, tmp7);
        PUSH(res);
        auto tmp8 = $12;
        res = new IR(kCreate_26, OP3("", "", ""), res, tmp8);
        PUSH(res);
        auto tmp9 = $13;
        res = new IR(kCreate_27, OP3("", "", ")"), res, tmp9);
        PUSH(res);
        auto tmp10 = $15;
        res = new IR(kCreate_28, OP3("", "", ""), res, tmp10);
        PUSH(res);
        auto tmp11 = $16;
        res = new IR(kCreate_29, OP3("", "", ""), res, tmp11);
        PUSH(res);
        auto tmp12 = $17;
        res = new IR(kCreate, OP3("", "", ""), res, tmp12);
        $$ = res;
    }

    | create_or_replace fulltext INDEX_SYM {} opt_if_not_exists ident ON table_ident {} '(' key_list ')' opt_lock_wait_timeout fulltext_key_options opt_index_lock_algorithm {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreate_30, OP3("", "", "INDEX_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kCreate_31, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kCreate_32, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kCreate_33, OP3("", "", "ON"), res, tmp5);
        PUSH(res);
        auto tmp6 = $8;
        res = new IR(kCreate_34, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $9;
        res = new IR(kCreate_35, OP3("", "", "("), res, tmp7);
        PUSH(res);
        auto tmp8 = $11;
        res = new IR(kCreate_36, OP3("", "", ")"), res, tmp8);
        PUSH(res);
        auto tmp9 = $13;
        res = new IR(kCreate_37, OP3("", "", ""), res, tmp9);
        PUSH(res);
        auto tmp10 = $14;
        res = new IR(kCreate_38, OP3("", "", ""), res, tmp10);
        PUSH(res);
        auto tmp11 = $15;
        res = new IR(kCreate, OP3("", "", ""), res, tmp11);
        $$ = res;
    }

    | create_or_replace spatial INDEX_SYM {} opt_if_not_exists ident ON table_ident {} '(' key_list ')' opt_lock_wait_timeout spatial_key_options opt_index_lock_algorithm {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreate_39, OP3("", "", "INDEX_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kCreate_40, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kCreate_41, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kCreate_42, OP3("", "", "ON"), res, tmp5);
        PUSH(res);
        auto tmp6 = $8;
        res = new IR(kCreate_43, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $9;
        res = new IR(kCreate_44, OP3("", "", "("), res, tmp7);
        PUSH(res);
        auto tmp8 = $11;
        res = new IR(kCreate_45, OP3("", "", ")"), res, tmp8);
        PUSH(res);
        auto tmp9 = $13;
        res = new IR(kCreate_46, OP3("", "", ""), res, tmp9);
        PUSH(res);
        auto tmp10 = $14;
        res = new IR(kCreate_47, OP3("", "", ""), res, tmp10);
        PUSH(res);
        auto tmp11 = $15;
        res = new IR(kCreate, OP3("", "", ""), res, tmp11);
        $$ = res;
    }

    | create_or_replace DATABASE opt_if_not_exists ident {} opt_create_database_options {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCreate_48, OP3("", "DATABASE", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kCreate_49, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kCreate_50, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kCreate, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | create_or_replace definer_opt opt_view_suid VIEW_SYM opt_if_not_exists table_ident {} view_list_opt AS view_select {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreate_51, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kCreate_52, OP3("", "", "VIEW_SYM"), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kCreate_53, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kCreate_54, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $7;
        res = new IR(kCreate_55, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $8;
        res = new IR(kCreate_56, OP3("", "", "AS"), res, tmp7);
        PUSH(res);
        auto tmp8 = $10;
        res = new IR(kCreate, OP3("", "", ""), res, tmp8);
        $$ = res;
    }

    | create_or_replace view_algorithm definer_opt opt_view_suid VIEW_SYM opt_if_not_exists table_ident {} view_list_opt AS view_select {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreate_57, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kCreate_58, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kCreate_59, OP3("", "", "VIEW_SYM"), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kCreate_60, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $7;
        res = new IR(kCreate_61, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $8;
        res = new IR(kCreate_62, OP3("", "", ""), res, tmp7);
        PUSH(res);
        auto tmp8 = $9;
        res = new IR(kCreate_63, OP3("", "", "AS"), res, tmp8);
        PUSH(res);
        auto tmp9 = $11;
        res = new IR(kCreate, OP3("", "", ""), res, tmp9);
        $$ = res;
    }

    | create_or_replace definer_opt TRIGGER_SYM {} trigger_tail {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreate_64, OP3("", "", "TRIGGER_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kCreate_65, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kCreate, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | create_or_replace definer_opt EVENT_SYM {} event_tail {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreate_66, OP3("", "", "EVENT_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kCreate_67, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kCreate, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | create_or_replace USER_SYM opt_if_not_exists clear_privileges grant_list opt_require_clause opt_resource_options opt_account_locking_and_opt_password_expiration {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCreate_68, OP3("", "USER_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kCreate_69, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kCreate_70, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kCreate_71, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $7;
        res = new IR(kCreate_72, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $8;
        res = new IR(kCreate, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

    | create_or_replace ROLE_SYM opt_if_not_exists clear_privileges role_list opt_with_admin {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCreate_73, OP3("", "ROLE_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kCreate_74, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kCreate_75, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kCreate, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | create_or_replace {} server_def {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreate_76, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kCreate, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | create_routine {
        auto tmp1 = $1;
        res = new IR(kCreate, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_sequence:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptSequence, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sequence_defs {
        auto tmp1 = $1;
        res = new IR(kOptSequence, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sequence_defs:

    sequence_def {
        auto tmp1 = $1;
        res = new IR(kSequenceDefs, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sequence_defs sequence_def {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSequenceDefs, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


sequence_def:

    MINVALUE_SYM opt_equal longlong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSequenceDef, OP3("MINVALUE_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | NO_SYM MINVALUE_SYM {
        res = new IR(kSequenceDef, OP3("NO_SYM MINVALUE_SYM", "", ""));
        $$ = res;
    }

    | NOMINVALUE_SYM {
        res = new IR(kSequenceDef, OP3("NOMINVALUE_SYM", "", ""));
        $$ = res;
    }

    | MAXVALUE_SYM opt_equal longlong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSequenceDef, OP3("MAXVALUE_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | NO_SYM MAXVALUE_SYM {
        res = new IR(kSequenceDef, OP3("NO_SYM MAXVALUE_SYM", "", ""));
        $$ = res;
    }

    | NOMAXVALUE_SYM {
        res = new IR(kSequenceDef, OP3("NOMAXVALUE_SYM", "", ""));
        $$ = res;
    }

    | START_SYM opt_with longlong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSequenceDef, OP3("START_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | INCREMENT_SYM opt_by longlong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSequenceDef, OP3("INCREMENT_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CACHE_SYM opt_equal longlong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSequenceDef, OP3("CACHE_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | NOCACHE_SYM {
        res = new IR(kSequenceDef, OP3("NOCACHE_SYM", "", ""));
        $$ = res;
    }

    | CYCLE_SYM {
        res = new IR(kSequenceDef, OP3("CYCLE_SYM", "", ""));
        $$ = res;
    }

    | NOCYCLE_SYM {
        res = new IR(kSequenceDef, OP3("NOCYCLE_SYM", "", ""));
        $$ = res;
    }

    | RESTART_SYM {
        res = new IR(kSequenceDef, OP3("RESTART_SYM", "", ""));
        $$ = res;
    }

    | RESTART_SYM opt_with longlong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSequenceDef, OP3("RESTART_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;



force_lookahead:

    {} {
        auto tmp1 = $1;
        res = new IR(kForceLookahead, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FORCE_LOOKAHEAD{}} {
        auto tmp1 = $1;
        res = new IR(kForceLookahead, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


server_def:

    SERVER_SYM opt_if_not_exists ident_or_text {} FOREIGN DATA_SYM WRAPPER_SYM ident_or_text OPTIONS_SYM '(' server_options_list ')' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kServerDef_1, OP3("SERVER_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kServerDef_2, OP3("", "", "FOREIGN DATA_SYM WRAPPER_SYM"), res, tmp3);
        PUSH(res);
        auto tmp4 = $8;
        res = new IR(kServerDef_3, OP3("", "", "OPTIONS_SYM ("), res, tmp4);
        PUSH(res);
        auto tmp5 = $11;
        res = new IR(kServerDef, OP3("", "", ")"), res, tmp5);
        $$ = res;
    }

;


server_options_list:

    server_option {
        auto tmp1 = $1;
        res = new IR(kServerOptionsList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | server_options_list ',' server_option {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kServerOptionsList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


server_option:

    USER_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kServerOption, OP3("USER_SYM", "", ""), tmp1);
        $$ = res;
    }

    | HOST_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kServerOption, OP3("HOST_SYM", "", ""), tmp1);
        $$ = res;
    }

    | DATABASE TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kServerOption, OP3("DATABASE", "", ""), tmp1);
        $$ = res;
    }

    | OWNER_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kServerOption, OP3("OWNER_SYM", "", ""), tmp1);
        $$ = res;
    }

    | PASSWORD_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kServerOption, OP3("PASSWORD_SYM", "", ""), tmp1);
        $$ = res;
    }

    | SOCKET_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kServerOption, OP3("SOCKET_SYM", "", ""), tmp1);
        $$ = res;
    }

    | PORT_SYM ulong_num {
        auto tmp1 = $2;
        res = new IR(kServerOption, OP3("PORT_SYM", "", ""), tmp1);
        $$ = res;
    }

;


event_tail:

    remember_name opt_if_not_exists sp_name {} ON SCHEDULE_SYM ev_schedule_time opt_ev_on_completion opt_ev_status opt_ev_comment DO_SYM ev_sql_stmt {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kEventTail_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kEventTail_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kEventTail_3, OP3("", "", "ON SCHEDULE_SYM"), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kEventTail_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $8;
        res = new IR(kEventTail_5, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $9;
        res = new IR(kEventTail_6, OP3("", "", ""), res, tmp7);
        PUSH(res);
        auto tmp8 = $10;
        res = new IR(kEventTail_7, OP3("", "", "DO_SYM"), res, tmp8);
        PUSH(res);
        auto tmp9 = $12;
        res = new IR(kEventTail, OP3("", "", ""), res, tmp9);
        $$ = res;
    }

;


ev_schedule_time:

    EVERY_SYM expr interval {} ev_starts ev_ends {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kEvScheduleTime_1, OP3("EVERY_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kEvScheduleTime_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kEvScheduleTime_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kEvScheduleTime, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | AT_SYM expr {
        auto tmp1 = $2;
        res = new IR(kEvScheduleTime, OP3("AT_SYM", "", ""), tmp1);
        $$ = res;
    }

;


opt_ev_status:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptEvStatus, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ENABLE_SYM {
        res = new IR(kOptEvStatus, OP3("ENABLE_SYM", "", ""));
        $$ = res;
    }

    | DISABLE_SYM ON SLAVE {
        res = new IR(kOptEvStatus, OP3("DISABLE_SYM ON SLAVE", "", ""));
        $$ = res;
    }

    | DISABLE_SYM {
        res = new IR(kOptEvStatus, OP3("DISABLE_SYM", "", ""));
        $$ = res;
    }

;


ev_starts:

    {} {
        auto tmp1 = $1;
        res = new IR(kEvStarts, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | STARTS_SYM expr {
        auto tmp1 = $2;
        res = new IR(kEvStarts, OP3("STARTS_SYM", "", ""), tmp1);
        $$ = res;
    }

;


ev_ends:

    ENDS_SYM expr {
        auto tmp1 = $2;
        res = new IR(kEvEnds, OP3("ENDS_SYM", "", ""), tmp1);
        $$ = res;
    }

    | ENDS_SYM expr {
        auto tmp1 = $2;
        res = new IR(kEvEnds, OP3("ENDS_SYM", "", ""), tmp1);
        $$ = res;
    }

;


opt_ev_on_completion:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptEvOnCompletion, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ev_on_completion {
        auto tmp1 = $1;
        res = new IR(kOptEvOnCompletion, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ev_on_completion:

    ON COMPLETION_SYM opt_not PRESERVE_SYM {
        auto tmp1 = $3;
        res = new IR(kEvOnCompletion, OP3("ON COMPLETION_SYM", "PRESERVE_SYM", ""), tmp1);
        $$ = res;
    }

;


opt_ev_comment:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptEvComment, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | COMMENT_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kOptEvComment, OP3("COMMENT_SYM", "", ""), tmp1);
        $$ = res;
    }

;


ev_sql_stmt:

    {} sp_proc_stmt force_lookahead {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kEvSqlStmt_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kEvSqlStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


clear_privileges:

    clear_privileges: {
        auto tmp1 = $1;
        res = new IR(kClearPrivileges, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_aggregate:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptAggregate, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AGGREGATE_SYM {
        res = new IR(kOptAggregate, OP3("AGGREGATE_SYM", "", ""));
        $$ = res;
    }

;



sp_handler:

    FUNCTION_SYM {
        res = new IR(kSpHandler, OP3("FUNCTION_SYM", "", ""));
        $$ = res;
    }

    | PROCEDURE_SYM {
        res = new IR(kSpHandler, OP3("PROCEDURE_SYM", "", ""));
        $$ = res;
    }

    | PACKAGE_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kSpHandler, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | PACKAGE_ORACLE_SYM BODY_ORACLE_SYM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpHandler, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;



sp_name:

    ident '.' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpName, OP3("", ".", ""), tmp1, tmp2);
        $$ = res;
    }

    | ident {
        auto tmp1 = $1;
        res = new IR(kSpName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_a_chistics:

    {} {
        auto tmp1 = $1;
        res = new IR(kSpAChistics, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_a_chistics sp_chistic{}} {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpAChistics, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


sp_c_chistics:

    {} {
        auto tmp1 = $1;
        res = new IR(kSpCChistics, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_c_chistics sp_c_chistic{}} {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpCChistics, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;



sp_chistic:

    COMMENT_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kSpChistic, OP3("COMMENT_SYM", "", ""), tmp1);
        $$ = res;
    }

    | LANGUAGE_SYM SQL_SYM {
        res = new IR(kSpChistic, OP3("LANGUAGE_SYM SQL_SYM", "", ""));
        $$ = res;
    }

    | NO_SYM SQL_SYM {
        res = new IR(kSpChistic, OP3("NO_SYM SQL_SYM", "", ""));
        $$ = res;
    }

    | CONTAINS_SYM SQL_SYM {
        res = new IR(kSpChistic, OP3("CONTAINS_SYM SQL_SYM", "", ""));
        $$ = res;
    }

    | READS_SYM SQL_SYM DATA_SYM {
        res = new IR(kSpChistic, OP3("READS_SYM SQL_SYM DATA_SYM", "", ""));
        $$ = res;
    }

    | MODIFIES_SYM SQL_SYM DATA_SYM {
        res = new IR(kSpChistic, OP3("MODIFIES_SYM SQL_SYM DATA_SYM", "", ""));
        $$ = res;
    }

    | sp_suid {
        auto tmp1 = $1;
        res = new IR(kSpChistic, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



sp_c_chistic:

    sp_chistic {
        auto tmp1 = $1;
        res = new IR(kSpCChistic, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | opt_not DETERMINISTIC_SYM {
        auto tmp1 = $1;
        res = new IR(kSpCChistic, OP3("", "DETERMINISTIC_SYM", ""), tmp1);
        $$ = res;
    }

;


sp_suid:

    SQL_SYM SECURITY_SYM DEFINER_SYM {
        res = new IR(kSpSuid, OP3("SQL_SYM SECURITY_SYM DEFINER_SYM", "", ""));
        $$ = res;
    }

    | SQL_SYM SECURITY_SYM INVOKER_SYM {
        res = new IR(kSpSuid, OP3("SQL_SYM SECURITY_SYM INVOKER_SYM", "", ""));
        $$ = res;
    }

;


call:

    CALL_SYM ident {} opt_sp_cparam_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCall_1, OP3("CALL_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kCall, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CALL_SYM ident '.' ident {} opt_sp_cparam_list {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kCall_2, OP3("CALL_SYM", ".", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kCall_3, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kCall, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | CALL_SYM ident '.' ident '.' ident {} opt_sp_cparam_list {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kCall_4, OP3("CALL_SYM", ".", "."), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kCall_5, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $7;
        res = new IR(kCall_6, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $8;
        res = new IR(kCall, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;



opt_sp_cparam_list:

    '(' opt_sp_cparams ')' {
        auto tmp1 = $2;
        res = new IR(kOptSpCparamList, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | '(' opt_sp_cparams ')' {
        auto tmp1 = $2;
        res = new IR(kOptSpCparamList, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


opt_sp_cparams:

    sp_cparams {
        auto tmp1 = $1;
        res = new IR(kOptSpCparams, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_cparams {
        auto tmp1 = $1;
        res = new IR(kOptSpCparams, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_cparams:

    sp_cparams ',' expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpCparams, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | expr {
        auto tmp1 = $1;
        res = new IR(kSpCparams, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



sp_fdparam_list:

    {} {
        auto tmp1 = $1;
        res = new IR(kSpFdparamList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | {} sp_fdparams {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpFdparamList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


sp_fdparams:

    sp_fdparams ',' sp_param {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpFdparams, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | sp_param {
        auto tmp1 = $1;
        res = new IR(kSpFdparams, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_param_name:

    ident {
        auto tmp1 = $1;
        res = new IR(kSpParamName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



sp_pdparam_list:

    sp_pdparams {
        auto tmp1 = $1;
        res = new IR(kSpPdparamList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_pdparams {
        auto tmp1 = $1;
        res = new IR(kSpPdparamList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_pdparams:

    sp_pdparams ',' sp_param {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpPdparams, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | sp_param {
        auto tmp1 = $1;
        res = new IR(kSpPdparams, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_parameter_type:

    IN_SYM {
        res = new IR(kSpParameterType, OP3("IN_SYM", "", ""));
        $$ = res;
    }

    | OUT_SYM {
        res = new IR(kSpParameterType, OP3("OUT_SYM", "", ""));
        $$ = res;
    }

    | INOUT_SYM {
        res = new IR(kSpParameterType, OP3("INOUT_SYM", "", ""));
        $$ = res;
    }

;


sp_parenthesized_pdparam_list:

    '(' {} sp_pdparam_list ')' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSpParenthesizedPdparamList, OP3("(", "", ")"), tmp1, tmp2);
        $$ = res;
    }

;


sp_parenthesized_fdparam_list:

    '(' sp_fdparam_list ')' {
        auto tmp1 = $2;
        res = new IR(kSpParenthesizedFdparamList, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


sp_proc_stmts:

    {} {
        auto tmp1 = $1;
        res = new IR(kSpProcStmts, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmts sp_proc_stmt ';' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpProcStmts, OP3("", "", ";"), tmp1, tmp2);
        $$ = res;
    }

;


sp_proc_stmts1:

    sp_proc_stmt ';' {
        auto tmp1 = $1;
        res = new IR(kSpProcStmts1, OP3("", ";", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmts1 sp_proc_stmt ';' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpProcStmts1, OP3("", "", ";"), tmp1, tmp2);
        $$ = res;
    }

;



optionally_qualified_column_ident:

    sp_decl_ident {
        auto tmp1 = $1;
        res = new IR(kOptionallyQualifiedColumnIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_decl_ident '.' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptionallyQualifiedColumnIdent, OP3("", ".", ""), tmp1, tmp2);
        $$ = res;
    }

    | sp_decl_ident '.' ident '.' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptionallyQualifiedColumnIdent_1, OP3("", ".", "."), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kOptionallyQualifiedColumnIdent, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;



row_field_definition:

    row_field_name field_type {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kRowFieldDefinition, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


row_field_definition_list:

    row_field_definition {
        auto tmp1 = $1;
        res = new IR(kRowFieldDefinitionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | row_field_definition_list ',' row_field_definition {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRowFieldDefinitionList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


row_type_body:

    '(' row_field_definition_list ')' {
        auto tmp1 = $2;
        res = new IR(kRowTypeBody, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


sp_decl_idents_init_vars:

    sp_decl_idents {
        auto tmp1 = $1;
        res = new IR(kSpDeclIdentsInitVars, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_decl_variable_list:

    sp_decl_idents_init_vars field_type {} sp_opt_default {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpDeclVariableList_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSpDeclVariableList_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kSpDeclVariableList, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | sp_decl_idents_init_vars ROW_SYM row_type_body sp_opt_default {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpDeclVariableList_3, OP3("", "ROW_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSpDeclVariableList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | sp_decl_variable_list_anchored {
        auto tmp1 = $1;
        res = new IR(kSpDeclVariableList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_decl_handler:

    sp_handler_type HANDLER_SYM FOR_SYM {} sp_hcond_list sp_proc_stmt {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kSpDeclHandler_1, OP3("", "HANDLER_SYM FOR_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kSpDeclHandler_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kSpDeclHandler, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


opt_parenthesized_cursor_formal_parameters:

    '(' sp_fdparams ')' {
        auto tmp1 = $2;
        res = new IR(kOptParenthesizedCursorFormalParameters, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | '(' sp_fdparams ')' {
        auto tmp1 = $2;
        res = new IR(kOptParenthesizedCursorFormalParameters, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;



sp_cursor_stmt_lex:

    sp_cursor_stmt_lex: {
        auto tmp1 = $1;
        res = new IR(kSpCursorStmtLex, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_cursor_stmt:

    sp_cursor_stmt_lex {} select {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpCursorStmt_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSpCursorStmt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


sp_handler_type:

    EXIT_MARIADB_SYM {
        res = new IR(kSpHandlerType, OP3("EXIT_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | CONTINUE_MARIADB_SYM {
        res = new IR(kSpHandlerType, OP3("CONTINUE_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | EXIT_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kSpHandlerType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CONTINUE_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kSpHandlerType, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_hcond_list:

    sp_hcond_element {
        auto tmp1 = $1;
        res = new IR(kSpHcondList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_hcond_list ',' sp_hcond_element {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpHcondList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


sp_hcond_element:

    sp_hcond {
        auto tmp1 = $1;
        res = new IR(kSpHcondElement, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_cond:

    ulong_num {
        auto tmp1 = $1;
        res = new IR(kSpCond, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sqlstate {
        auto tmp1 = $1;
        res = new IR(kSpCond, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sqlstate:

    SQLSTATE_SYM opt_value TEXT_STRING_literal {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSqlstate, OP3("SQLSTATE_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_value:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptValue, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | VALUE_SYM {}} {
        auto tmp1 = $2;
        res = new IR(kOptValue, OP3("VALUE_SYM", "", ""), tmp1);
        $$ = res;
    }

;


sp_hcond:

    sp_cond {
        auto tmp1 = $1;
        res = new IR(kSpHcond, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident {
        auto tmp1 = $1;
        res = new IR(kSpHcond, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SQLWARNING_SYM {
        res = new IR(kSpHcond, OP3("SQLWARNING_SYM", "", ""));
        $$ = res;
    }

    | not FOUND_SYM {
        auto tmp1 = $1;
        res = new IR(kSpHcond, OP3("", "FOUND_SYM", ""), tmp1);
        $$ = res;
    }

    | SQLEXCEPTION_SYM {
        res = new IR(kSpHcond, OP3("SQLEXCEPTION_SYM", "", ""));
        $$ = res;
    }

    | OTHERS_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kSpHcond, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



raise_stmt_oracle:

    RAISE_ORACLE_SYM opt_set_signal_information {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kRaiseStmtOracle, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | RAISE_ORACLE_SYM signal_value opt_set_signal_information {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kRaiseStmtOracle_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kRaiseStmtOracle, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


signal_stmt:

    SIGNAL_SYM signal_value opt_set_signal_information {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSignalStmt, OP3("SIGNAL_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


signal_value:

    ident {
        auto tmp1 = $1;
        res = new IR(kSignalValue, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sqlstate {
        auto tmp1 = $1;
        res = new IR(kSignalValue, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_signal_value:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptSignalValue, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | signal_value {
        auto tmp1 = $1;
        res = new IR(kOptSignalValue, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_set_signal_information:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptSetSignalInformation, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SET signal_information_item_list {
        auto tmp1 = $2;
        res = new IR(kOptSetSignalInformation, OP3("SET", "", ""), tmp1);
        $$ = res;
    }

;


signal_information_item_list:

    signal_condition_information_item_name '=' signal_allowed_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSignalInformationItemList, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

    | signal_information_item_list ',' signal_condition_information_item_name '=' signal_allowed_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSignalInformationItemList_1, OP3("", ",", "="), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kSignalInformationItemList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;



signal_allowed_expr:

    literal {
        auto tmp1 = $1;
        res = new IR(kSignalAllowedExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | variable {
        auto tmp1 = $1;
        res = new IR(kSignalAllowedExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | simple_ident {
        auto tmp1 = $1;
        res = new IR(kSignalAllowedExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



signal_condition_information_item_name:

    CLASS_ORIGIN_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("CLASS_ORIGIN_SYM", "", ""));
        $$ = res;
    }

    | SUBCLASS_ORIGIN_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("SUBCLASS_ORIGIN_SYM", "", ""));
        $$ = res;
    }

    | CONSTRAINT_CATALOG_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("CONSTRAINT_CATALOG_SYM", "", ""));
        $$ = res;
    }

    | CONSTRAINT_SCHEMA_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("CONSTRAINT_SCHEMA_SYM", "", ""));
        $$ = res;
    }

    | CONSTRAINT_NAME_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("CONSTRAINT_NAME_SYM", "", ""));
        $$ = res;
    }

    | CATALOG_NAME_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("CATALOG_NAME_SYM", "", ""));
        $$ = res;
    }

    | SCHEMA_NAME_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("SCHEMA_NAME_SYM", "", ""));
        $$ = res;
    }

    | TABLE_NAME_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("TABLE_NAME_SYM", "", ""));
        $$ = res;
    }

    | COLUMN_NAME_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("COLUMN_NAME_SYM", "", ""));
        $$ = res;
    }

    | CURSOR_NAME_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("CURSOR_NAME_SYM", "", ""));
        $$ = res;
    }

    | MESSAGE_TEXT_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("MESSAGE_TEXT_SYM", "", ""));
        $$ = res;
    }

    | MYSQL_ERRNO_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("MYSQL_ERRNO_SYM", "", ""));
        $$ = res;
    }

    | ROW_NUMBER_SYM {
        res = new IR(kSignalConditionInformationItemName, OP3("ROW_NUMBER_SYM", "", ""));
        $$ = res;
    }

;


resignal_stmt:

    RESIGNAL_SYM opt_signal_value opt_set_signal_information {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kResignalStmt, OP3("RESIGNAL_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


get_diagnostics:

    GET_SYM which_area DIAGNOSTICS_SYM diagnostics_information {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kGetDiagnostics, OP3("GET_SYM", "DIAGNOSTICS_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

;


which_area:

    {} {
        auto tmp1 = $1;
        res = new IR(kWhichArea, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CURRENT_SYM {
        res = new IR(kWhichArea, OP3("CURRENT_SYM", "", ""));
        $$ = res;
    }

;


diagnostics_information:

    statement_information {
        auto tmp1 = $1;
        res = new IR(kDiagnosticsInformation, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CONDITION_SYM condition_number condition_information {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kDiagnosticsInformation, OP3("CONDITION_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


statement_information:

    statement_information_item {
        auto tmp1 = $1;
        res = new IR(kStatementInformation, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | statement_information ',' statement_information_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kStatementInformation, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


statement_information_item:

    simple_target_specification '=' statement_information_item_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kStatementInformationItem, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

;


simple_target_specification:

    ident_cli {
        auto tmp1 = $1;
        res = new IR(kSimpleTargetSpecification, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '@' ident_or_text {
        auto tmp1 = $2;
        res = new IR(kSimpleTargetSpecification, OP3("@", "", ""), tmp1);
        $$ = res;
    }

;


statement_information_item_name:

    NUMBER_MARIADB_SYM {
        res = new IR(kStatementInformationItemName, OP3("NUMBER_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | NUMBER_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kStatementInformationItemName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ROW_COUNT_SYM {
        res = new IR(kStatementInformationItemName, OP3("ROW_COUNT_SYM", "", ""));
        $$ = res;
    }

;



condition_number:

    signal_allowed_expr {
        auto tmp1 = $1;
        res = new IR(kConditionNumber, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


condition_information:

    condition_information_item {
        auto tmp1 = $1;
        res = new IR(kConditionInformation, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | condition_information ',' condition_information_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kConditionInformation, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


condition_information_item:

    simple_target_specification '=' condition_information_item_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kConditionInformationItem, OP3("", "=", ""), tmp1, tmp2);
        $$ = res;
    }

;


condition_information_item_name:

    CLASS_ORIGIN_SYM {
        res = new IR(kConditionInformationItemName, OP3("CLASS_ORIGIN_SYM", "", ""));
        $$ = res;
    }

    | SUBCLASS_ORIGIN_SYM {
        res = new IR(kConditionInformationItemName, OP3("SUBCLASS_ORIGIN_SYM", "", ""));
        $$ = res;
    }

    | CONSTRAINT_CATALOG_SYM {
        res = new IR(kConditionInformationItemName, OP3("CONSTRAINT_CATALOG_SYM", "", ""));
        $$ = res;
    }

    | CONSTRAINT_SCHEMA_SYM {
        res = new IR(kConditionInformationItemName, OP3("CONSTRAINT_SCHEMA_SYM", "", ""));
        $$ = res;
    }

    | CONSTRAINT_NAME_SYM {
        res = new IR(kConditionInformationItemName, OP3("CONSTRAINT_NAME_SYM", "", ""));
        $$ = res;
    }

    | CATALOG_NAME_SYM {
        res = new IR(kConditionInformationItemName, OP3("CATALOG_NAME_SYM", "", ""));
        $$ = res;
    }

    | SCHEMA_NAME_SYM {
        res = new IR(kConditionInformationItemName, OP3("SCHEMA_NAME_SYM", "", ""));
        $$ = res;
    }

    | TABLE_NAME_SYM {
        res = new IR(kConditionInformationItemName, OP3("TABLE_NAME_SYM", "", ""));
        $$ = res;
    }

    | COLUMN_NAME_SYM {
        res = new IR(kConditionInformationItemName, OP3("COLUMN_NAME_SYM", "", ""));
        $$ = res;
    }

    | CURSOR_NAME_SYM {
        res = new IR(kConditionInformationItemName, OP3("CURSOR_NAME_SYM", "", ""));
        $$ = res;
    }

    | MESSAGE_TEXT_SYM {
        res = new IR(kConditionInformationItemName, OP3("MESSAGE_TEXT_SYM", "", ""));
        $$ = res;
    }

    | MYSQL_ERRNO_SYM {
        res = new IR(kConditionInformationItemName, OP3("MYSQL_ERRNO_SYM", "", ""));
        $$ = res;
    }

    | RETURNED_SQLSTATE_SYM {
        res = new IR(kConditionInformationItemName, OP3("RETURNED_SQLSTATE_SYM", "", ""));
        $$ = res;
    }

    | ROW_NUMBER_SYM {
        res = new IR(kConditionInformationItemName, OP3("ROW_NUMBER_SYM", "", ""));
        $$ = res;
    }

;


sp_decl_ident:

    IDENT_sys {
        auto tmp1 = $1;
        res = new IR(kSpDeclIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_decl {
        auto tmp1 = $1;
        res = new IR(kSpDeclIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_decl_idents:

    sp_decl_ident {
        auto tmp1 = $1;
        res = new IR(kSpDeclIdents, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_decl_idents ',' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpDeclIdents, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


sp_proc_stmt_if:

    IF_SYM {} sp_if END IF_SYM {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSpProcStmtIf, OP3("IF_SYM", "", "END IF_SYM"), tmp1, tmp2);
        $$ = res;
    }

;


sp_proc_stmt_statement:

    {} sp_statement {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpProcStmtStatement, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;



RETURN_ALLMODES_SYM:

    RETURN_MARIADB_SYM {
        res = new IR(kRETURNALLMODESSYM, OP3("RETURN_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | RETURN_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kRETURNALLMODESSYM, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_proc_stmt_return:

    RETURN_ALLMODES_SYM expr_lex {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpProcStmtReturn, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | RETURN_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kSpProcStmtReturn, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_proc_stmt_exit_oracle:

    EXIT_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kSpProcStmtExitOracle, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | EXIT_ORACLE_SYM label_ident {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpProcStmtExitOracle, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | EXIT_ORACLE_SYM WHEN_SYM expr_lex {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpProcStmtExitOracle, OP3("", "WHEN_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | EXIT_ORACLE_SYM label_ident WHEN_SYM expr_lex {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpProcStmtExitOracle_1, OP3("", "", "WHEN_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSpProcStmtExitOracle, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


sp_proc_stmt_continue_oracle:

    CONTINUE_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kSpProcStmtContinueOracle, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CONTINUE_ORACLE_SYM label_ident {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpProcStmtContinueOracle, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CONTINUE_ORACLE_SYM WHEN_SYM expr_lex {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpProcStmtContinueOracle, OP3("", "WHEN_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | CONTINUE_ORACLE_SYM label_ident WHEN_SYM expr_lex {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpProcStmtContinueOracle_1, OP3("", "", "WHEN_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSpProcStmtContinueOracle, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;



sp_proc_stmt_leave:

    LEAVE_SYM label_ident {
        auto tmp1 = $2;
        res = new IR(kSpProcStmtLeave, OP3("LEAVE_SYM", "", ""), tmp1);
        $$ = res;
    }

;


sp_proc_stmt_iterate:

    ITERATE_SYM label_ident {
        auto tmp1 = $2;
        res = new IR(kSpProcStmtIterate, OP3("ITERATE_SYM", "", ""), tmp1);
        $$ = res;
    }

;


sp_proc_stmt_goto_oracle:

    GOTO_ORACLE_SYM label_ident {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpProcStmtGotoOracle, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;



expr_lex:

    {} expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kExprLex, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;



assignment_source_lex:

    assignment_source_lex: {
        auto tmp1 = $1;
        res = new IR(kAssignmentSourceLex, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


assignment_source_expr:

    assignment_source_lex {} expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAssignmentSourceExpr_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kAssignmentSourceExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


for_loop_bound_expr:

    assignment_source_lex {} expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kForLoopBoundExpr_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kForLoopBoundExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


cursor_actual_parameters:

    assignment_source_expr {
        auto tmp1 = $1;
        res = new IR(kCursorActualParameters, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | cursor_actual_parameters ',' assignment_source_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCursorActualParameters, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_parenthesized_cursor_actual_parameters:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptParenthesizedCursorActualParameters, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' cursor_actual_parameters ')' {
        auto tmp1 = $2;
        res = new IR(kOptParenthesizedCursorActualParameters, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


sp_proc_stmt_with_cursor:

    sp_proc_stmt_open {
        auto tmp1 = $1;
        res = new IR(kSpProcStmtWithCursor, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_fetch {
        auto tmp1 = $1;
        res = new IR(kSpProcStmtWithCursor, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_close {
        auto tmp1 = $1;
        res = new IR(kSpProcStmtWithCursor, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_proc_stmt_open:

    OPEN_SYM ident opt_parenthesized_cursor_actual_parameters {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSpProcStmtOpen, OP3("OPEN_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


sp_proc_stmt_fetch_head:

    FETCH_SYM ident INTO {
        auto tmp1 = $2;
        res = new IR(kSpProcStmtFetchHead, OP3("FETCH_SYM", "INTO", ""), tmp1);
        $$ = res;
    }

    | FETCH_SYM FROM ident INTO {
        auto tmp1 = $3;
        res = new IR(kSpProcStmtFetchHead, OP3("FETCH_SYM FROM", "INTO", ""), tmp1);
        $$ = res;
    }

    | FETCH_SYM NEXT_SYM FROM ident INTO {
        auto tmp1 = $4;
        res = new IR(kSpProcStmtFetchHead, OP3("FETCH_SYM NEXT_SYM FROM", "INTO", ""), tmp1);
        $$ = res;
    }

;


sp_proc_stmt_fetch:

    sp_proc_stmt_fetch_head sp_fetch_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpProcStmtFetch, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | FETCH_SYM GROUP_SYM NEXT_SYM ROW_SYM {
        res = new IR(kSpProcStmtFetch, OP3("FETCH_SYM GROUP_SYM NEXT_SYM ROW_SYM", "", ""));
        $$ = res;
    }

;


sp_proc_stmt_close:

    CLOSE_SYM ident {
        auto tmp1 = $2;
        res = new IR(kSpProcStmtClose, OP3("CLOSE_SYM", "", ""), tmp1);
        $$ = res;
    }

;


sp_fetch_list:

    ident {
        auto tmp1 = $1;
        res = new IR(kSpFetchList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_fetch_list ',' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpFetchList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


sp_if:

    expr_lex THEN_SYM {} sp_if_then_statements {} sp_elseifs {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpIf_1, OP3("", "THEN_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSpIf_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kSpIf_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kSpIf, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


sp_elseifs:

    ELSEIF_MARIADB_SYM sp_if {
        auto tmp1 = $2;
        res = new IR(kSpElseifs, OP3("ELSEIF_MARIADB_SYM", "", ""), tmp1);
        $$ = res;
    }

    | ELSEIF_MARIADB_SYM sp_if {
        auto tmp1 = $2;
        res = new IR(kSpElseifs, OP3("ELSEIF_MARIADB_SYM", "", ""), tmp1);
        $$ = res;
    }

    | ELSIF_ORACLE_SYM sp_if {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpElseifs, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ELSE sp_if_then_statements {
        auto tmp1 = $2;
        res = new IR(kSpElseifs, OP3("ELSE", "", ""), tmp1);
        $$ = res;
    }

;


case_stmt_specification:

    CASE_SYM {} case_stmt_body else_clause_opt END CASE_SYM {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCaseStmtSpecification_1, OP3("CASE_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kCaseStmtSpecification, OP3("", "", "END CASE_SYM"), res, tmp3);
        $$ = res;
    }

;


case_stmt_body:

    expr_lex {} simple_when_clause_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCaseStmtBody_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kCaseStmtBody, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | searched_when_clause_list {
        auto tmp1 = $1;
        res = new IR(kCaseStmtBody, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


simple_when_clause_list:

    simple_when_clause {
        auto tmp1 = $1;
        res = new IR(kSimpleWhenClauseList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | simple_when_clause_list simple_when_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleWhenClauseList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


searched_when_clause_list:

    searched_when_clause {
        auto tmp1 = $1;
        res = new IR(kSearchedWhenClauseList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | searched_when_clause_list searched_when_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSearchedWhenClauseList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


simple_when_clause:

    WHEN_SYM expr_lex {} THEN_SYM sp_case_then_statements {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSimpleWhenClause_1, OP3("WHEN_SYM", "", "THEN_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kSimpleWhenClause, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


searched_when_clause:

    WHEN_SYM expr_lex {} THEN_SYM sp_case_then_statements {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSearchedWhenClause_1, OP3("WHEN_SYM", "", "THEN_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kSearchedWhenClause, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


else_clause_opt:

    {} {
        auto tmp1 = $1;
        res = new IR(kElseClauseOpt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ELSE sp_case_then_statements {
        auto tmp1 = $2;
        res = new IR(kElseClauseOpt, OP3("ELSE", "", ""), tmp1);
        $$ = res;
    }

;


sp_opt_label:

    {} {
        auto tmp1 = $1;
        res = new IR(kSpOptLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | label_ident {
        auto tmp1 = $1;
        res = new IR(kSpOptLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



opt_sp_for_loop_direction:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptSpForLoopDirection, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | REVERSE_SYM {
        res = new IR(kOptSpForLoopDirection, OP3("REVERSE_SYM", "", ""));
        $$ = res;
    }

;


sp_for_loop_index_and_bounds:

    ident_for_loop_index sp_for_loop_bounds {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpForLoopIndexAndBounds, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


sp_for_loop_bounds:

    IN_SYM opt_sp_for_loop_direction for_loop_bound_expr DOT_DOT_SYM for_loop_bound_expr {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSpForLoopBounds_1, OP3("IN_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSpForLoopBounds_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kSpForLoopBounds, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | IN_SYM opt_sp_for_loop_direction for_loop_bound_expr {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSpForLoopBounds, OP3("IN_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | IN_SYM opt_sp_for_loop_direction '(' sp_cursor_stmt ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kSpForLoopBounds, OP3("IN_SYM", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

;


loop_body:

    sp_proc_stmts1 END LOOP_SYM {
        auto tmp1 = $1;
        res = new IR(kLoopBody, OP3("", "END LOOP_SYM", ""), tmp1);
        $$ = res;
    }

;


repeat_body:

    sp_proc_stmts1 UNTIL_SYM expr_lex END REPEAT_SYM {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRepeatBody, OP3("", "UNTIL_SYM", "END REPEAT_SYM"), tmp1, tmp2);
        $$ = res;
    }

;


pop_sp_loop_label:

    sp_opt_label {
        auto tmp1 = $1;
        res = new IR(kPopSpLoopLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_labeled_control:

    sp_control_label LOOP_SYM {} loop_body pop_sp_loop_label {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpLabeledControl_1, OP3("", "LOOP_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSpLabeledControl_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kSpLabeledControl, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | sp_control_label WHILE_SYM {} while_body pop_sp_loop_label {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpLabeledControl_3, OP3("", "WHILE_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSpLabeledControl_4, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kSpLabeledControl, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | sp_control_label FOR_SYM {} sp_for_loop_index_and_bounds {} for_loop_statements {} pop_sp_loop_label {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpLabeledControl_5, OP3("", "FOR_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSpLabeledControl_6, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kSpLabeledControl_7, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kSpLabeledControl_8, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $7;
        res = new IR(kSpLabeledControl_9, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $8;
        res = new IR(kSpLabeledControl, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

    | sp_control_label REPEAT_SYM {} repeat_body pop_sp_loop_label {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpLabeledControl_10, OP3("", "REPEAT_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSpLabeledControl_11, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kSpLabeledControl, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


sp_unlabeled_control:

    LOOP_SYM {} loop_body {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSpUnlabeledControl, OP3("LOOP_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | WHILE_SYM {} while_body {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSpUnlabeledControl, OP3("WHILE_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | FOR_SYM {} sp_for_loop_index_and_bounds {} for_loop_statements {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSpUnlabeledControl_1, OP3("FOR_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSpUnlabeledControl_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kSpUnlabeledControl, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | REPEAT_SYM {} repeat_body {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSpUnlabeledControl, OP3("REPEAT_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


trg_action_time:

    BEFORE_SYM {
        res = new IR(kTrgActionTime, OP3("BEFORE_SYM", "", ""));
        $$ = res;
    }

    | AFTER_SYM {
        res = new IR(kTrgActionTime, OP3("AFTER_SYM", "", ""));
        $$ = res;
    }

;


trg_event:

    INSERT {
        res = new IR(kTrgEvent, OP3("INSERT", "", ""));
        $$ = res;
    }

    | UPDATE_SYM {
        res = new IR(kTrgEvent, OP3("UPDATE_SYM", "", ""));
        $$ = res;
    }

    | DELETE_SYM {
        res = new IR(kTrgEvent, OP3("DELETE_SYM", "", ""));
        $$ = res;
    }

;


create_body:

    create_field_list_parens {} opt_create_table_options opt_create_partitioning opt_create_select {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateBody_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kCreateBody_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kCreateBody_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kCreateBody, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | opt_create_table_options opt_create_partitioning opt_create_select {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateBody_4, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kCreateBody, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | create_like {
        auto tmp1 = $1;
        res = new IR(kCreateBody, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


create_like:

    LIKE table_ident {
        auto tmp1 = $2;
        res = new IR(kCreateLike, OP3("LIKE", "", ""), tmp1);
        $$ = res;
    }

    | LEFT_PAREN_LIKE LIKE table_ident ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCreateLike, OP3("", "LIKE", ")"), tmp1, tmp2);
        $$ = res;
    }

;


opt_create_select:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptCreateSelect, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | opt_duplicate opt_as create_select_query_expression opt_versioning_option{} } {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptCreateSelect_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kOptCreateSelect_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kOptCreateSelect_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kOptCreateSelect, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


create_select_query_expression:

    query_expression {
        auto tmp1 = $1;
        res = new IR(kCreateSelectQueryExpression, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LEFT_PAREN_WITH with_clause query_expression_no_with_clause ')' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateSelectQueryExpression_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kCreateSelectQueryExpression, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

;


opt_create_partitioning:

    opt_partitioning {
        auto tmp1 = $1;
        res = new IR(kOptCreatePartitioning, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



opt_partitioning:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptPartitioning, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | partitioning {
        auto tmp1 = $1;
        res = new IR(kOptPartitioning, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


partitioning:

    PARTITION_SYM have_partitioning {} partition {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kPartitioning_1, OP3("PARTITION_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kPartitioning, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


have_partitioning:

    have_partitioning: {
        auto tmp1 = $1;
        res = new IR(kHavePartitioning, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


partition_entry:

    PARTITION_SYM {} partition {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kPartitionEntry, OP3("PARTITION_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


partition:

    BY {} part_type_def opt_num_parts opt_sub_part part_defs {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kPartition_1, OP3("BY", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kPartition_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kPartition_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kPartition, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


part_type_def:

    opt_linear KEY_SYM opt_key_algo '(' part_field_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPartTypeDef_1, OP3("", "KEY_SYM", "("), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kPartTypeDef, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | opt_linear HASH_SYM {} part_func {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPartTypeDef_2, OP3("", "HASH_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kPartTypeDef, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | RANGE_SYM part_func {
        auto tmp1 = $2;
        res = new IR(kPartTypeDef, OP3("RANGE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | RANGE_SYM part_column_list {
        auto tmp1 = $2;
        res = new IR(kPartTypeDef, OP3("RANGE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | LIST_SYM {} part_func {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kPartTypeDef, OP3("LIST_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | LIST_SYM part_column_list {
        auto tmp1 = $2;
        res = new IR(kPartTypeDef, OP3("LIST_SYM", "", ""), tmp1);
        $$ = res;
    }

    | SYSTEM_TIME_SYM {} opt_versioning_rotation {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kPartTypeDef, OP3("SYSTEM_TIME_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_linear:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptLinear, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LINEAR_SYM{} } {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptLinear, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_key_algo:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptKeyAlgo, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ALGORITHM_SYM '=' real_ulong_num {
        auto tmp1 = $3;
        res = new IR(kOptKeyAlgo, OP3("ALGORITHM_SYM =", "", ""), tmp1);
        $$ = res;
    }

;


part_field_list:

    {} {
        auto tmp1 = $1;
        res = new IR(kPartFieldList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | part_field_item_list{}} {
        auto tmp1 = $1;
        res = new IR(kPartFieldList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


part_field_item_list:

    part_field_item {
        auto tmp1 = $1;
        res = new IR(kPartFieldItemList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | part_field_item_list ',' part_field_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPartFieldItemList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


part_field_item:

    ident {
        auto tmp1 = $1;
        res = new IR(kPartFieldItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


part_column_list:

    COLUMNS '(' part_field_list ')' {
        auto tmp1 = $3;
        res = new IR(kPartColumnList, OP3("COLUMNS (", ")", ""), tmp1);
        $$ = res;
    }

;



part_func:

    '(' part_func_expr ')' {
        auto tmp1 = $2;
        res = new IR(kPartFunc, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


sub_part_func:

    '(' part_func_expr ')' {
        auto tmp1 = $2;
        res = new IR(kSubPartFunc, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;



opt_num_parts:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptNumParts, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | PARTITIONS_SYM real_ulong_num{} } {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptNumParts, OP3("PARTITIONS_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_sub_part:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptSubPart, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SUBPARTITION_SYM BY opt_linear HASH_SYM sub_part_func{} } opt_num_subparts{}} {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kOptSubPart_1, OP3("SUBPARTITION_SYM BY", "HASH_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kOptSubPart_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $7;
        res = new IR(kOptSubPart, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | SUBPARTITION_SYM BY opt_linear KEY_SYM opt_key_algo '(' sub_part_field_list ')'{} } opt_num_subparts{}} {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kOptSubPart_3, OP3("SUBPARTITION_SYM BY", "KEY_SYM", "("), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kOptSubPart_4, OP3("", "", "')'{}"), res, tmp3);
        PUSH(res);
        auto tmp4 = $9;
        res = new IR(kOptSubPart_5, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $10;
        res = new IR(kOptSubPart, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


sub_part_field_list:

    sub_part_field_item {
        auto tmp1 = $1;
        res = new IR(kSubPartFieldList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sub_part_field_list ',' sub_part_field_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSubPartFieldList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


sub_part_field_item:

    ident {
        auto tmp1 = $1;
        res = new IR(kSubPartFieldItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


part_func_expr:

    bit_expr {
        auto tmp1 = $1;
        res = new IR(kPartFuncExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_num_subparts:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptNumSubparts, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SUBPARTITIONS_SYM real_ulong_num{} } {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptNumSubparts, OP3("SUBPARTITIONS_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


part_defs:

    {} {
        auto tmp1 = $1;
        res = new IR(kPartDefs, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' part_def_list ')' {
        auto tmp1 = $2;
        res = new IR(kPartDefs, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


part_def_list:

    part_definition {
        auto tmp1 = $1;
        res = new IR(kPartDefList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | part_def_list ',' part_definition {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPartDefList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_partition:

    PARTITION_SYM {
        res = new IR(kOptPartition, OP3("PARTITION_SYM", "", ""));
        $$ = res;
    }

    | PARTITION_SYM {
        res = new IR(kOptPartition, OP3("PARTITION_SYM", "", ""));
        $$ = res;
    }

;


part_definition:

    opt_partition {} part_name opt_part_values opt_part_options opt_sub_partition {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPartDefinition_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kPartDefinition_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kPartDefinition_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kPartDefinition_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $6;
        res = new IR(kPartDefinition, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

;


part_name:

    ident {
        auto tmp1 = $1;
        res = new IR(kPartName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_part_values:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptPartValues, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | VALUES_LESS_SYM THAN_SYM {} part_func_max {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptPartValues_1, OP3("", "THAN_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kOptPartValues, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | VALUES_IN_SYM {} part_values_in {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptPartValues_2, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kOptPartValues, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CURRENT_SYM {
        res = new IR(kOptPartValues, OP3("CURRENT_SYM", "", ""));
        $$ = res;
    }

    | HISTORY_SYM {
        res = new IR(kOptPartValues, OP3("HISTORY_SYM", "", ""));
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kOptPartValues, OP3("DEFAULT", "", ""));
        $$ = res;
    }

;


part_func_max:

    MAXVALUE_SYM {
        res = new IR(kPartFuncMax, OP3("MAXVALUE_SYM", "", ""));
        $$ = res;
    }

    | part_value_item {
        auto tmp1 = $1;
        res = new IR(kPartFuncMax, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


part_values_in:

    part_value_item {
        auto tmp1 = $1;
        res = new IR(kPartValuesIn, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' part_value_list ')' {
        auto tmp1 = $2;
        res = new IR(kPartValuesIn, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


part_value_list:

    part_value_item {
        auto tmp1 = $1;
        res = new IR(kPartValueList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | part_value_list ',' part_value_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPartValueList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


part_value_item:

    '(' {} part_value_item_list {} ')' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kPartValueItem_1, OP3("(", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kPartValueItem, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

;


part_value_item_list:

    part_value_expr_item {
        auto tmp1 = $1;
        res = new IR(kPartValueItemList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | part_value_item_list ',' part_value_expr_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPartValueItemList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


part_value_expr_item:

    MAXVALUE_SYM {
        res = new IR(kPartValueExprItem, OP3("MAXVALUE_SYM", "", ""));
        $$ = res;
    }

    | bit_expr {
        auto tmp1 = $1;
        res = new IR(kPartValueExprItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



opt_sub_partition:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptSubPartition, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' sub_part_list ')' {
        auto tmp1 = $2;
        res = new IR(kOptSubPartition, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


sub_part_list:

    sub_part_definition {
        auto tmp1 = $1;
        res = new IR(kSubPartList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sub_part_list ',' sub_part_definition {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSubPartList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


sub_part_definition:

    SUBPARTITION_SYM {} sub_name opt_subpart_options {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSubPartDefinition_1, OP3("SUBPARTITION_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSubPartDefinition, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


sub_name:

    ident_or_text {
        auto tmp1 = $1;
        res = new IR(kSubName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_part_options:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptPartOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | part_option_list{}} {
        auto tmp1 = $1;
        res = new IR(kOptPartOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


part_option_list:

    part_option_list part_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPartOptionList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | part_option {
        auto tmp1 = $1;
        res = new IR(kPartOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


part_option:

    server_part_option {
        auto tmp1 = $1;
        res = new IR(kPartOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | engine_defined_option {
        auto tmp1 = $1;
        res = new IR(kPartOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_subpart_options:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptSubpartOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | subpart_option_list{}} {
        auto tmp1 = $1;
        res = new IR(kOptSubpartOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


subpart_option_list:

    subpart_option_list server_part_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSubpartOptionList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | server_part_option {
        auto tmp1 = $1;
        res = new IR(kSubpartOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


server_part_option:

    TABLESPACE opt_equal ident_or_text {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kServerPartOption, OP3("TABLESPACE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | opt_storage ENGINE_SYM opt_equal storage_engines {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kServerPartOption_1, OP3("", "ENGINE_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kServerPartOption, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CONNECTION_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kServerPartOption, OP3("CONNECTION_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | NODEGROUP_SYM opt_equal real_ulong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kServerPartOption, OP3("NODEGROUP_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | MAX_ROWS opt_equal real_ulonglong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kServerPartOption, OP3("MAX_ROWS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | MIN_ROWS opt_equal real_ulonglong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kServerPartOption, OP3("MIN_ROWS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DATA_SYM DIRECTORY_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kServerPartOption, OP3("DATA_SYM DIRECTORY_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | INDEX_SYM DIRECTORY_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kServerPartOption, OP3("INDEX_SYM DIRECTORY_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | COMMENT_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kServerPartOption, OP3("COMMENT_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_versioning_rotation:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptVersioningRotation, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | INTERVAL_SYM expr interval opt_versioning_interval_start opt_vers_auto_part{} } {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptVersioningRotation_1, OP3("INTERVAL_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kOptVersioningRotation_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kOptVersioningRotation_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kOptVersioningRotation, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | LIMIT ulonglong_num opt_vers_auto_part{} } {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptVersioningRotation_4, OP3("LIMIT", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kOptVersioningRotation, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;



opt_versioning_interval_start:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptVersioningIntervalStart, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | STARTS_SYM literal {
        auto tmp1 = $2;
        res = new IR(kOptVersioningIntervalStart, OP3("STARTS_SYM", "", ""), tmp1);
        $$ = res;
    }

;


opt_vers_auto_part:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptVersAutoPart, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AUTO_SYM {
        res = new IR(kOptVersAutoPart, OP3("AUTO_SYM", "", ""));
        $$ = res;
    }

;



opt_as:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptAs, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AS{}} {
        auto tmp1 = $1;
        res = new IR(kOptAs, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_create_database_options:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptCreateDatabaseOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | create_database_options{}} {
        auto tmp1 = $1;
        res = new IR(kOptCreateDatabaseOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


create_database_options:

    create_database_option {
        auto tmp1 = $1;
        res = new IR(kCreateDatabaseOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | create_database_options create_database_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateDatabaseOptions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


create_database_option:

    default_collation {
        auto tmp1 = $1;
        res = new IR(kCreateDatabaseOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | default_charset {
        auto tmp1 = $1;
        res = new IR(kCreateDatabaseOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | COMMENT_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateDatabaseOption, OP3("COMMENT_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_if_not_exists_table_element:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptIfNotExistsTableElement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IF_SYM not EXISTS {
        auto tmp1 = $2;
        res = new IR(kOptIfNotExistsTableElement, OP3("IF_SYM", "EXISTS", ""), tmp1);
        $$ = res;
    }

;


opt_if_not_exists:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptIfNotExists, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IF_SYM not EXISTS {
        auto tmp1 = $2;
        res = new IR(kOptIfNotExists, OP3("IF_SYM", "EXISTS", ""), tmp1);
        $$ = res;
    }

;


create_or_replace:

    CREATE {
        res = new IR(kCreateOrReplace, OP3("CREATE", "", ""));
        $$ = res;
    }

    | CREATE OR_SYM REPLACE {
        res = new IR(kCreateOrReplace, OP3("CREATE OR_SYM REPLACE", "", ""));
        $$ = res;
    }

;


opt_create_table_options:

    create_table_options {
        auto tmp1 = $1;
        res = new IR(kOptCreateTableOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | create_table_options {
        auto tmp1 = $1;
        res = new IR(kOptCreateTableOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


create_table_options_space_separated:

    create_table_option {
        auto tmp1 = $1;
        res = new IR(kCreateTableOptionsSpaceSeparated, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | create_table_option create_table_options_space_separated {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateTableOptionsSpaceSeparated, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


create_table_options:

    create_table_option {
        auto tmp1 = $1;
        res = new IR(kCreateTableOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | create_table_option create_table_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateTableOptions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | create_table_option ',' create_table_options {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCreateTableOptions, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


create_table_option:

    ENGINE_SYM opt_equal ident_or_text {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("ENGINE_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | MAX_ROWS opt_equal ulonglong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("MAX_ROWS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | MIN_ROWS opt_equal ulonglong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("MIN_ROWS", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | AVG_ROW_LENGTH opt_equal ulong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("AVG_ROW_LENGTH", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | PASSWORD_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("PASSWORD_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | COMMENT_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("COMMENT_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | AUTO_INC opt_equal ulonglong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("AUTO_INC", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | PACK_KEYS_SYM opt_equal ulong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("PACK_KEYS_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | PACK_KEYS_SYM opt_equal DEFAULT {
        auto tmp1 = $2;
        res = new IR(kCreateTableOption, OP3("PACK_KEYS_SYM", "DEFAULT", ""), tmp1);
        $$ = res;
    }

    | STATS_AUTO_RECALC_SYM opt_equal ulong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("STATS_AUTO_RECALC_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | STATS_AUTO_RECALC_SYM opt_equal DEFAULT {
        auto tmp1 = $2;
        res = new IR(kCreateTableOption, OP3("STATS_AUTO_RECALC_SYM", "DEFAULT", ""), tmp1);
        $$ = res;
    }

    | STATS_PERSISTENT_SYM opt_equal ulong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("STATS_PERSISTENT_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | STATS_PERSISTENT_SYM opt_equal DEFAULT {
        auto tmp1 = $2;
        res = new IR(kCreateTableOption, OP3("STATS_PERSISTENT_SYM", "DEFAULT", ""), tmp1);
        $$ = res;
    }

    | STATS_SAMPLE_PAGES_SYM opt_equal ulong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("STATS_SAMPLE_PAGES_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | STATS_SAMPLE_PAGES_SYM opt_equal DEFAULT {
        auto tmp1 = $2;
        res = new IR(kCreateTableOption, OP3("STATS_SAMPLE_PAGES_SYM", "DEFAULT", ""), tmp1);
        $$ = res;
    }

    | CHECKSUM_SYM opt_equal ulong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("CHECKSUM_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | TABLE_CHECKSUM_SYM opt_equal ulong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("TABLE_CHECKSUM_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | PAGE_CHECKSUM_SYM opt_equal choice {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("PAGE_CHECKSUM_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DELAY_KEY_WRITE_SYM opt_equal ulong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("DELAY_KEY_WRITE_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ROW_FORMAT_SYM opt_equal row_types {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("ROW_FORMAT_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | UNION_SYM opt_equal {} '(' opt_table_list ')' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption_1, OP3("UNION_SYM", "", "("), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kCreateTableOption, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | default_charset {
        auto tmp1 = $1;
        res = new IR(kCreateTableOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | default_collation {
        auto tmp1 = $1;
        res = new IR(kCreateTableOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | INSERT_METHOD opt_equal merge_insert_types {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("INSERT_METHOD", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DATA_SYM DIRECTORY_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kCreateTableOption, OP3("DATA_SYM DIRECTORY_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | INDEX_SYM DIRECTORY_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kCreateTableOption, OP3("INDEX_SYM DIRECTORY_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | TABLESPACE ident {
        auto tmp1 = $2;
        res = new IR(kCreateTableOption, OP3("TABLESPACE", "", ""), tmp1);
        $$ = res;
    }

    | STORAGE_SYM DISK_SYM {
        res = new IR(kCreateTableOption, OP3("STORAGE_SYM DISK_SYM", "", ""));
        $$ = res;
    }

    | STORAGE_SYM MEMORY_SYM {
        res = new IR(kCreateTableOption, OP3("STORAGE_SYM MEMORY_SYM", "", ""));
        $$ = res;
    }

    | CONNECTION_SYM opt_equal TEXT_STRING_sys {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("CONNECTION_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | KEY_BLOCK_SIZE opt_equal ulong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("KEY_BLOCK_SIZE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | TRANSACTIONAL_SYM opt_equal choice {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("TRANSACTIONAL_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | engine_defined_option {
        auto tmp1 = $1;
        res = new IR(kCreateTableOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SEQUENCE_SYM opt_equal choice {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCreateTableOption, OP3("SEQUENCE_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | versioning_option {
        auto tmp1 = $1;
        res = new IR(kCreateTableOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


engine_defined_option:

    IDENT_sys equal TEXT_STRING_sys {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kEngineDefinedOption_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kEngineDefinedOption, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | IDENT_sys equal ident {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kEngineDefinedOption_2, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kEngineDefinedOption, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | IDENT_sys equal real_ulonglong_num {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kEngineDefinedOption_3, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kEngineDefinedOption, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | IDENT_sys equal DEFAULT {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kEngineDefinedOption, OP3("", "", "DEFAULT"), tmp1, tmp2);
        $$ = res;
    }

;


opt_versioning_option:

    versioning_option {
        auto tmp1 = $1;
        res = new IR(kOptVersioningOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | versioning_option {
        auto tmp1 = $1;
        res = new IR(kOptVersioningOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


versioning_option:

    WITH_SYSTEM_SYM VERSIONING_SYM {
        auto tmp1 = $1;
        res = new IR(kVersioningOption, OP3("", "VERSIONING_SYM", ""), tmp1);
        $$ = res;
    }

;


default_charset:

    opt_default charset opt_equal charset_name_or_default {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kDefaultCharset_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kDefaultCharset_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kDefaultCharset, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


default_collation:

    opt_default COLLATE_SYM opt_equal collation_name_or_default {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDefaultCollation_1, OP3("", "COLLATE_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kDefaultCollation, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


storage_engines:

    ident_or_text {
        auto tmp1 = $1;
        res = new IR(kStorageEngines, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


known_storage_engines:

    ident_or_text {
        auto tmp1 = $1;
        res = new IR(kKnownStorageEngines, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


row_types:

    DEFAULT {
        res = new IR(kRowTypes, OP3("DEFAULT", "", ""));
        $$ = res;
    }

    | FIXED_SYM {
        res = new IR(kRowTypes, OP3("FIXED_SYM", "", ""));
        $$ = res;
    }

    | DYNAMIC_SYM {
        res = new IR(kRowTypes, OP3("DYNAMIC_SYM", "", ""));
        $$ = res;
    }

    | COMPRESSED_SYM {
        res = new IR(kRowTypes, OP3("COMPRESSED_SYM", "", ""));
        $$ = res;
    }

    | REDUNDANT_SYM {
        res = new IR(kRowTypes, OP3("REDUNDANT_SYM", "", ""));
        $$ = res;
    }

    | COMPACT_SYM {
        res = new IR(kRowTypes, OP3("COMPACT_SYM", "", ""));
        $$ = res;
    }

    | PAGE_SYM {
        res = new IR(kRowTypes, OP3("PAGE_SYM", "", ""));
        $$ = res;
    }

;


merge_insert_types:

    NO_SYM {
        res = new IR(kMergeInsertTypes, OP3("NO_SYM", "", ""));
        $$ = res;
    }

    | FIRST_SYM {
        res = new IR(kMergeInsertTypes, OP3("FIRST_SYM", "", ""));
        $$ = res;
    }

    | LAST_SYM {
        res = new IR(kMergeInsertTypes, OP3("LAST_SYM", "", ""));
        $$ = res;
    }

;


udf_type:

    STRING_SYM {
        res = new IR(kUdfType, OP3("STRING_SYM", "", ""));
        $$ = res;
    }

    | REAL {
        res = new IR(kUdfType, OP3("REAL", "", ""));
        $$ = res;
    }

    | DECIMAL_SYM {
        res = new IR(kUdfType, OP3("DECIMAL_SYM", "", ""));
        $$ = res;
    }

    | INT_SYM {
        res = new IR(kUdfType, OP3("INT_SYM", "", ""));
        $$ = res;
    }

;



create_field_list:

    field_list {
        auto tmp1 = $1;
        res = new IR(kCreateFieldList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


create_field_list_parens:

    LEFT_PAREN_ALT field_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateFieldListParens, OP3("", "", ")"), tmp1, tmp2);
        $$ = res;
    }

;


field_list:

    field_list_item {
        auto tmp1 = $1;
        res = new IR(kFieldList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | field_list ',' field_list_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFieldList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


field_list_item:

    column_def {
        auto tmp1 = $1;
        res = new IR(kFieldListItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | key_def {
        auto tmp1 = $1;
        res = new IR(kFieldListItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | constraint_def {
        auto tmp1 = $1;
        res = new IR(kFieldListItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | period_for_system_time {
        auto tmp1 = $1;
        res = new IR(kFieldListItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | PERIOD_SYM period_for_application_time {
        auto tmp1 = $2;
        res = new IR(kFieldListItem, OP3("PERIOD_SYM", "", ""), tmp1);
        $$ = res;
    }

;


column_def:

    field_spec {
        auto tmp1 = $1;
        res = new IR(kColumnDef, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | field_spec opt_constraint references {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kColumnDef_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kColumnDef, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


key_def:

    key_or_index opt_if_not_exists opt_ident opt_USING_key_algorithm {} '(' key_list ')' normal_key_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kKeyDef_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kKeyDef_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kKeyDef_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kKeyDef_4, OP3("", "", "("), res, tmp5);
        PUSH(res);
        auto tmp6 = $7;
        res = new IR(kKeyDef_5, OP3("", "", ")"), res, tmp6);
        PUSH(res);
        auto tmp7 = $9;
        res = new IR(kKeyDef, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

    | key_or_index opt_if_not_exists ident TYPE_SYM btree_or_rtree {} '(' key_list ')' normal_key_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kKeyDef_6, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kKeyDef_7, OP3("", "", "TYPE_SYM"), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kKeyDef_8, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kKeyDef_9, OP3("", "", "("), res, tmp5);
        PUSH(res);
        auto tmp6 = $8;
        res = new IR(kKeyDef_10, OP3("", "", ")"), res, tmp6);
        PUSH(res);
        auto tmp7 = $10;
        res = new IR(kKeyDef, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

    | fulltext opt_key_or_index opt_if_not_exists opt_ident {} '(' key_list ')' fulltext_key_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kKeyDef_11, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kKeyDef_12, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kKeyDef_13, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kKeyDef_14, OP3("", "", "("), res, tmp5);
        PUSH(res);
        auto tmp6 = $7;
        res = new IR(kKeyDef_15, OP3("", "", ")"), res, tmp6);
        PUSH(res);
        auto tmp7 = $9;
        res = new IR(kKeyDef, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

    | spatial opt_key_or_index opt_if_not_exists opt_ident {} '(' key_list ')' spatial_key_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kKeyDef_16, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kKeyDef_17, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kKeyDef_18, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kKeyDef_19, OP3("", "", "("), res, tmp5);
        PUSH(res);
        auto tmp6 = $7;
        res = new IR(kKeyDef_20, OP3("", "", ")"), res, tmp6);
        PUSH(res);
        auto tmp7 = $9;
        res = new IR(kKeyDef, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

    | opt_constraint constraint_key_type opt_if_not_exists opt_ident opt_USING_key_algorithm {} '(' key_list opt_without_overlaps ')' normal_key_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kKeyDef_21, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kKeyDef_22, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kKeyDef_23, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kKeyDef_24, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $6;
        res = new IR(kKeyDef_25, OP3("", "", "("), res, tmp6);
        PUSH(res);
        auto tmp7 = $8;
        res = new IR(kKeyDef_26, OP3("", "", ""), res, tmp7);
        PUSH(res);
        auto tmp8 = $9;
        res = new IR(kKeyDef_27, OP3("", "", ")"), res, tmp8);
        PUSH(res);
        auto tmp9 = $11;
        res = new IR(kKeyDef, OP3("", "", ""), res, tmp9);
        $$ = res;
    }

    | opt_constraint constraint_key_type opt_if_not_exists ident TYPE_SYM btree_or_rtree {} '(' key_list opt_without_overlaps ')' normal_key_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kKeyDef_28, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kKeyDef_29, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kKeyDef_30, OP3("", "", "TYPE_SYM"), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kKeyDef_31, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $7;
        res = new IR(kKeyDef_32, OP3("", "", "("), res, tmp6);
        PUSH(res);
        auto tmp7 = $9;
        res = new IR(kKeyDef_33, OP3("", "", ""), res, tmp7);
        PUSH(res);
        auto tmp8 = $10;
        res = new IR(kKeyDef_34, OP3("", "", ")"), res, tmp8);
        PUSH(res);
        auto tmp9 = $12;
        res = new IR(kKeyDef, OP3("", "", ""), res, tmp9);
        $$ = res;
    }

    | opt_constraint FOREIGN KEY_SYM opt_if_not_exists opt_ident {} '(' key_list ')' references {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kKeyDef_35, OP3("", "FOREIGN KEY_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kKeyDef_36, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kKeyDef_37, OP3("", "", "("), res, tmp4);
        PUSH(res);
        auto tmp5 = $8;
        res = new IR(kKeyDef_38, OP3("", "", ")"), res, tmp5);
        PUSH(res);
        auto tmp6 = $10;
        res = new IR(kKeyDef, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

;


constraint_def:

    opt_constraint check_constraint {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kConstraintDef, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


period_for_system_time:

    PERIOD_SYM FOR_SYSTEM_TIME_SYM '(' ident ',' ident ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kPeriodForSystemTime_1, OP3("PERIOD_SYM", "(", ","), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kPeriodForSystemTime, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

;


period_for_application_time:

    FOR_SYM ident '(' ident ',' ident ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kPeriodForApplicationTime_1, OP3("FOR_SYM", "(", ","), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kPeriodForApplicationTime, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

;


opt_check_constraint:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptCheckConstraint, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | check_constraint {
        auto tmp1 = $1;
        res = new IR(kOptCheckConstraint, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


check_constraint:

    CHECK_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kCheckConstraint, OP3("CHECK_SYM (", ")", ""), tmp1);
        $$ = res;
    }

;


opt_constraint_no_id:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptConstraintNoId, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CONSTRAINT {}} {
        auto tmp1 = $2;
        res = new IR(kOptConstraintNoId, OP3("CONSTRAINT", "", ""), tmp1);
        $$ = res;
    }

;


opt_constraint:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptConstraint, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | constraint {
        auto tmp1 = $1;
        res = new IR(kOptConstraint, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


constraint:

    CONSTRAINT opt_ident {
        auto tmp1 = $2;
        res = new IR(kConstraint, OP3("CONSTRAINT", "", ""), tmp1);
        $$ = res;
    }

;


field_spec:

    field_ident {} field_type_or_serial opt_check_constraint {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldSpec_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kFieldSpec_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kFieldSpec, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


field_type_or_serial:

    qualified_field_type {} field_def {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldTypeOrSerial_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kFieldTypeOrSerial, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | SERIAL_SYM {} opt_serial_attribute {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFieldTypeOrSerial, OP3("SERIAL_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_serial_attribute:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptSerialAttribute, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | opt_serial_attribute_list{}} {
        auto tmp1 = $1;
        res = new IR(kOptSerialAttribute, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_serial_attribute_list:

    opt_serial_attribute_list serial_attribute {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptSerialAttributeList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | serial_attribute {
        auto tmp1 = $1;
        res = new IR(kOptSerialAttributeList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_asrow_attribute:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptAsrowAttribute, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | opt_asrow_attribute_list{}} {
        auto tmp1 = $1;
        res = new IR(kOptAsrowAttribute, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_asrow_attribute_list:

    opt_asrow_attribute_list asrow_attribute {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptAsrowAttributeList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | asrow_attribute {
        auto tmp1 = $1;
        res = new IR(kOptAsrowAttributeList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


field_def:

    {} {
        auto tmp1 = $1;
        res = new IR(kFieldDef, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | attribute_list {
        auto tmp1 = $1;
        res = new IR(kFieldDef, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | attribute_list compressed_deprecated_column_attribute {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldDef, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | attribute_list compressed_deprecated_column_attribute attribute_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldDef_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kFieldDef, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | opt_generated_always AS virtual_column_func {} vcol_opt_specifier vcol_opt_attribute {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFieldDef_2, OP3("", "AS", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kFieldDef_3, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kFieldDef_4, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kFieldDef, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | opt_generated_always AS ROW_SYM START_SYM opt_asrow_attribute {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kFieldDef, OP3("", "AS ROW_SYM START_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | opt_generated_always AS ROW_SYM END opt_asrow_attribute {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kFieldDef, OP3("", "AS ROW_SYM END", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_generated_always:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptGeneratedAlways, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | GENERATED_SYM ALWAYS_SYM{}} {
        auto tmp1 = $2;
        res = new IR(kOptGeneratedAlways, OP3("GENERATED_SYM", "", ""), tmp1);
        $$ = res;
    }

;


vcol_opt_specifier:

    {} {
        auto tmp1 = $1;
        res = new IR(kVcolOptSpecifier, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | VIRTUAL_SYM {
        res = new IR(kVcolOptSpecifier, OP3("VIRTUAL_SYM", "", ""));
        $$ = res;
    }

    | PERSISTENT_SYM {
        res = new IR(kVcolOptSpecifier, OP3("PERSISTENT_SYM", "", ""));
        $$ = res;
    }

    | STORED_SYM {
        res = new IR(kVcolOptSpecifier, OP3("STORED_SYM", "", ""));
        $$ = res;
    }

;


vcol_opt_attribute:

    {} {
        auto tmp1 = $1;
        res = new IR(kVcolOptAttribute, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | vcol_opt_attribute_list{}} {
        auto tmp1 = $1;
        res = new IR(kVcolOptAttribute, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


vcol_opt_attribute_list:

    vcol_opt_attribute_list vcol_attribute {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kVcolOptAttributeList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | vcol_attribute {
        auto tmp1 = $1;
        res = new IR(kVcolOptAttributeList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


vcol_attribute:

    UNIQUE_SYM {
        res = new IR(kVcolAttribute, OP3("UNIQUE_SYM", "", ""));
        $$ = res;
    }

    | UNIQUE_SYM KEY_SYM {
        res = new IR(kVcolAttribute, OP3("UNIQUE_SYM KEY_SYM", "", ""));
        $$ = res;
    }

    | COMMENT_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kVcolAttribute, OP3("COMMENT_SYM", "", ""), tmp1);
        $$ = res;
    }

    | INVISIBLE_SYM {
        res = new IR(kVcolAttribute, OP3("INVISIBLE_SYM", "", ""));
        $$ = res;
    }

;


parse_vcol_expr:

    PARSE_VCOL_EXPR_SYM {} expr {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kParseVcolExpr, OP3("PARSE_VCOL_EXPR_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


parenthesized_expr:

    expr {
        auto tmp1 = $1;
        res = new IR(kParenthesizedExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | expr ',' expr_list {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kParenthesizedExpr, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


virtual_column_func:

    '(' parenthesized_expr ')' {
        auto tmp1 = $2;
        res = new IR(kVirtualColumnFunc, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | subquery {
        auto tmp1 = $1;
        res = new IR(kVirtualColumnFunc, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


expr_or_literal:

    column_default_non_parenthesized_expr | signed_literal {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kExprOrLiteral_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kExprOrLiteral, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


column_default_expr:

    virtual_column_func {
        auto tmp1 = $1;
        res = new IR(kColumnDefaultExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | expr_or_literal {
        auto tmp1 = $1;
        res = new IR(kColumnDefaultExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


field_type:

    field_type_all {
        auto tmp1 = $1;
        res = new IR(kFieldType, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


qualified_field_type:

    field_type_all {
        auto tmp1 = $1;
        res = new IR(kQualifiedFieldType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_decl_ident '.' field_type_all {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kQualifiedFieldType, OP3("", ".", ""), tmp1, tmp2);
        $$ = res;
    }

;


field_type_all:

    field_type_numeric {
        auto tmp1 = $1;
        res = new IR(kFieldTypeAll, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | field_type_temporal {
        auto tmp1 = $1;
        res = new IR(kFieldTypeAll, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | field_type_string {
        auto tmp1 = $1;
        res = new IR(kFieldTypeAll, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | field_type_lob {
        auto tmp1 = $1;
        res = new IR(kFieldTypeAll, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | field_type_misc {
        auto tmp1 = $1;
        res = new IR(kFieldTypeAll, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IDENT_sys float_options srid_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldTypeAll_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kFieldTypeAll, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | reserved_keyword_udt float_options srid_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldTypeAll_2, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kFieldTypeAll, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | non_reserved_keyword_udt float_options srid_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldTypeAll_3, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kFieldTypeAll, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


field_type_numeric:

    int_type opt_field_length last_field_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldTypeNumeric_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kFieldTypeNumeric, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | real_type opt_precision last_field_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldTypeNumeric_2, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kFieldTypeNumeric, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | FLOAT_SYM float_options last_field_options {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFieldTypeNumeric, OP3("FLOAT_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | BIT_SYM opt_field_length {
        auto tmp1 = $2;
        res = new IR(kFieldTypeNumeric, OP3("BIT_SYM", "", ""), tmp1);
        $$ = res;
    }

    | BOOL_SYM {
        res = new IR(kFieldTypeNumeric, OP3("BOOL_SYM", "", ""));
        $$ = res;
    }

    | BOOLEAN_SYM {
        res = new IR(kFieldTypeNumeric, OP3("BOOLEAN_SYM", "", ""));
        $$ = res;
    }

    | DECIMAL_SYM float_options last_field_options {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFieldTypeNumeric, OP3("DECIMAL_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | NUMBER_ORACLE_SYM float_options last_field_options {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldTypeNumeric_3, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kFieldTypeNumeric, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | NUMERIC_SYM float_options last_field_options {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFieldTypeNumeric, OP3("NUMERIC_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | FIXED_SYM float_options last_field_options {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFieldTypeNumeric, OP3("FIXED_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;



opt_binary_and_compression:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptBinaryAndCompression, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | binary {
        auto tmp1 = $1;
        res = new IR(kOptBinaryAndCompression, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | binary compressed_deprecated_data_type_attribute {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptBinaryAndCompression, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | compressed opt_binary {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptBinaryAndCompression, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


field_type_string:

    char opt_field_length opt_binary {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldTypeString_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kFieldTypeString, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | nchar opt_field_length opt_bin_mod {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldTypeString_2, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kFieldTypeString, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | BINARY opt_field_length {
        auto tmp1 = $2;
        res = new IR(kFieldTypeString, OP3("BINARY", "", ""), tmp1);
        $$ = res;
    }

    | varchar opt_field_length opt_binary_and_compression {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldTypeString_3, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kFieldTypeString, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | VARCHAR2_ORACLE_SYM opt_field_length opt_binary_and_compression {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldTypeString_4, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kFieldTypeString, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | nvarchar opt_field_length opt_compressed opt_bin_mod {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldTypeString_5, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kFieldTypeString_6, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kFieldTypeString, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | VARBINARY opt_field_length opt_compressed {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFieldTypeString, OP3("VARBINARY", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | RAW_ORACLE_SYM opt_field_length opt_compressed {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldTypeString_7, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kFieldTypeString, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


field_type_temporal:

    YEAR_SYM opt_field_length last_field_options {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFieldTypeTemporal, OP3("YEAR_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DATE_SYM {
        res = new IR(kFieldTypeTemporal, OP3("DATE_SYM", "", ""));
        $$ = res;
    }

    | TIME_SYM opt_field_length {
        auto tmp1 = $2;
        res = new IR(kFieldTypeTemporal, OP3("TIME_SYM", "", ""), tmp1);
        $$ = res;
    }

    | TIMESTAMP opt_field_length {
        auto tmp1 = $2;
        res = new IR(kFieldTypeTemporal, OP3("TIMESTAMP", "", ""), tmp1);
        $$ = res;
    }

    | DATETIME opt_field_length {
        auto tmp1 = $2;
        res = new IR(kFieldTypeTemporal, OP3("DATETIME", "", ""), tmp1);
        $$ = res;
    }

;



field_type_lob:

    TINYBLOB opt_compressed {
        auto tmp1 = $2;
        res = new IR(kFieldTypeLob, OP3("TINYBLOB", "", ""), tmp1);
        $$ = res;
    }

    | BLOB_MARIADB_SYM opt_field_length opt_compressed {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFieldTypeLob, OP3("BLOB_MARIADB_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | BLOB_ORACLE_SYM field_length opt_compressed {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldTypeLob_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kFieldTypeLob, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | BLOB_ORACLE_SYM opt_compressed {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldTypeLob, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | MEDIUMBLOB opt_compressed {
        auto tmp1 = $2;
        res = new IR(kFieldTypeLob, OP3("MEDIUMBLOB", "", ""), tmp1);
        $$ = res;
    }

    | LONGBLOB opt_compressed {
        auto tmp1 = $2;
        res = new IR(kFieldTypeLob, OP3("LONGBLOB", "", ""), tmp1);
        $$ = res;
    }

    | LONG_SYM VARBINARY opt_compressed {
        auto tmp1 = $3;
        res = new IR(kFieldTypeLob, OP3("LONG_SYM VARBINARY", "", ""), tmp1);
        $$ = res;
    }

    | LONG_SYM varchar opt_binary_and_compression {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFieldTypeLob, OP3("LONG_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | TINYTEXT opt_binary_and_compression {
        auto tmp1 = $2;
        res = new IR(kFieldTypeLob, OP3("TINYTEXT", "", ""), tmp1);
        $$ = res;
    }

    | TEXT_SYM opt_field_length opt_binary_and_compression {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFieldTypeLob, OP3("TEXT_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | MEDIUMTEXT opt_binary_and_compression {
        auto tmp1 = $2;
        res = new IR(kFieldTypeLob, OP3("MEDIUMTEXT", "", ""), tmp1);
        $$ = res;
    }

    | LONGTEXT opt_binary_and_compression {
        auto tmp1 = $2;
        res = new IR(kFieldTypeLob, OP3("LONGTEXT", "", ""), tmp1);
        $$ = res;
    }

    | CLOB_ORACLE_SYM opt_binary_and_compression {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldTypeLob, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | LONG_SYM opt_binary_and_compression {
        auto tmp1 = $2;
        res = new IR(kFieldTypeLob, OP3("LONG_SYM", "", ""), tmp1);
        $$ = res;
    }

    | JSON_SYM opt_compressed {
        auto tmp1 = $2;
        res = new IR(kFieldTypeLob, OP3("JSON_SYM", "", ""), tmp1);
        $$ = res;
    }

;


field_type_misc:

    ENUM '(' string_list ')' opt_binary {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFieldTypeMisc, OP3("ENUM (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

    | SET '(' string_list ')' opt_binary {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFieldTypeMisc, OP3("SET (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

;


char:

    CHAR_SYM {
        res = new IR(kChar, OP3("CHAR_SYM", "", ""));
        $$ = res;
    }

;


nchar:

    NCHAR_SYM {
        res = new IR(kNchar, OP3("NCHAR_SYM", "", ""));
        $$ = res;
    }

    | NATIONAL_SYM CHAR_SYM {
        res = new IR(kNchar, OP3("NATIONAL_SYM CHAR_SYM", "", ""));
        $$ = res;
    }

;


varchar:

    char VARYING {
        auto tmp1 = $1;
        res = new IR(kVarchar, OP3("", "VARYING", ""), tmp1);
        $$ = res;
    }

    | VARCHAR {
        res = new IR(kVarchar, OP3("VARCHAR", "", ""));
        $$ = res;
    }

;


nvarchar:

    NATIONAL_SYM VARCHAR {
        res = new IR(kNvarchar, OP3("NATIONAL_SYM VARCHAR", "", ""));
        $$ = res;
    }

    | NVARCHAR_SYM {
        res = new IR(kNvarchar, OP3("NVARCHAR_SYM", "", ""));
        $$ = res;
    }

    | NCHAR_SYM VARCHAR {
        res = new IR(kNvarchar, OP3("NCHAR_SYM VARCHAR", "", ""));
        $$ = res;
    }

    | NATIONAL_SYM CHAR_SYM VARYING {
        res = new IR(kNvarchar, OP3("NATIONAL_SYM CHAR_SYM VARYING", "", ""));
        $$ = res;
    }

    | NCHAR_SYM VARYING {
        res = new IR(kNvarchar, OP3("NCHAR_SYM VARYING", "", ""));
        $$ = res;
    }

;


int_type:

    INT_SYM {
        res = new IR(kIntType, OP3("INT_SYM", "", ""));
        $$ = res;
    }

    | TINYINT {
        res = new IR(kIntType, OP3("TINYINT", "", ""));
        $$ = res;
    }

    | SMALLINT {
        res = new IR(kIntType, OP3("SMALLINT", "", ""));
        $$ = res;
    }

    | MEDIUMINT {
        res = new IR(kIntType, OP3("MEDIUMINT", "", ""));
        $$ = res;
    }

    | BIGINT {
        res = new IR(kIntType, OP3("BIGINT", "", ""));
        $$ = res;
    }

;


real_type:

    REAL {
        res = new IR(kRealType, OP3("REAL", "", ""));
        $$ = res;
    }

    | DOUBLE_SYM {
        res = new IR(kRealType, OP3("DOUBLE_SYM", "", ""));
        $$ = res;
    }

    | DOUBLE_SYM PRECISION {
        res = new IR(kRealType, OP3("DOUBLE_SYM PRECISION", "", ""));
        $$ = res;
    }

;


srid_option:

    {} {
        auto tmp1 = $1;
        res = new IR(kSridOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | REF_SYSTEM_ID_SYM '=' NUM {
        auto tmp1 = $3;
        res = new IR(kSridOption, OP3("REF_SYSTEM_ID_SYM =", "", ""), tmp1);
        $$ = res;
    }

;


float_options:

    {} {
        auto tmp1 = $1;
        res = new IR(kFloatOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | field_length {
        auto tmp1 = $1;
        res = new IR(kFloatOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | precision {
        auto tmp1 = $1;
        res = new IR(kFloatOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


precision:

    '(' NUM ',' NUM ')' {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kPrecision, OP3("(", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

;


field_options:

    {} {
        auto tmp1 = $1;
        res = new IR(kFieldOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SIGNED_SYM {
        res = new IR(kFieldOptions, OP3("SIGNED_SYM", "", ""));
        $$ = res;
    }

    | UNSIGNED {
        res = new IR(kFieldOptions, OP3("UNSIGNED", "", ""));
        $$ = res;
    }

    | ZEROFILL {
        res = new IR(kFieldOptions, OP3("ZEROFILL", "", ""));
        $$ = res;
    }

    | UNSIGNED ZEROFILL {
        res = new IR(kFieldOptions, OP3("UNSIGNED ZEROFILL", "", ""));
        $$ = res;
    }

    | ZEROFILL UNSIGNED {
        res = new IR(kFieldOptions, OP3("ZEROFILL UNSIGNED", "", ""));
        $$ = res;
    }

;


last_field_options:

    field_options {
        auto tmp1 = $1;
        res = new IR(kLastFieldOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


field_length_str:

    '(' LONG_NUM ')' {
        auto tmp1 = $2;
        res = new IR(kFieldLengthStr, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | '(' ULONGLONG_NUM ')' {
        auto tmp1 = $2;
        res = new IR(kFieldLengthStr, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | '(' DECIMAL_NUM ')' {
        auto tmp1 = $2;
        res = new IR(kFieldLengthStr, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | '(' NUM ')' {
        auto tmp1 = $2;
        res = new IR(kFieldLengthStr, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


field_length:

    field_length_str {
        auto tmp1 = $1;
        res = new IR(kFieldLength, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



field_scale:

    field_length_str {
        auto tmp1 = $1;
        res = new IR(kFieldScale, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



opt_field_length:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptFieldLength, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | field_length {
        auto tmp1 = $1;
        res = new IR(kOptFieldLength, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_field_scale:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptFieldScale, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | field_scale {
        auto tmp1 = $1;
        res = new IR(kOptFieldScale, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_precision:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptPrecision, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | precision {
        auto tmp1 = $1;
        res = new IR(kOptPrecision, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



attribute_list:

    attribute_list attribute {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAttributeList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | attribute {
        auto tmp1 = $1;
        res = new IR(kAttributeList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


attribute:

    NULL_SYM {
        res = new IR(kAttribute, OP3("NULL_SYM", "", ""));
        $$ = res;
    }

    | DEFAULT column_default_expr {
        auto tmp1 = $2;
        res = new IR(kAttribute, OP3("DEFAULT", "", ""), tmp1);
        $$ = res;
    }

    | ON UPDATE_SYM NOW_SYM opt_default_time_precision {
        auto tmp1 = $4;
        res = new IR(kAttribute, OP3("ON UPDATE_SYM NOW_SYM", "", ""), tmp1);
        $$ = res;
    }

    | AUTO_INC {
        res = new IR(kAttribute, OP3("AUTO_INC", "", ""));
        $$ = res;
    }

    | SERIAL_SYM DEFAULT VALUE_SYM {
        res = new IR(kAttribute, OP3("SERIAL_SYM DEFAULT VALUE_SYM", "", ""));
        $$ = res;
    }

    | COLLATE_SYM collation_name {
        auto tmp1 = $2;
        res = new IR(kAttribute, OP3("COLLATE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | serial_attribute {
        auto tmp1 = $1;
        res = new IR(kAttribute, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_compression_method:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptCompressionMethod, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | equal ident {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptCompressionMethod, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_compressed:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptCompressed, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | compressed{} } {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptCompressed, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_enable:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptEnable, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ENABLE_SYM{} } {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptEnable, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


compressed:

    COMPRESSED_SYM opt_compression_method {
        auto tmp1 = $2;
        res = new IR(kCompressed, OP3("COMPRESSED_SYM", "", ""), tmp1);
        $$ = res;
    }

;


compressed_deprecated_data_type_attribute:

    COMPRESSED_SYM opt_compression_method {
        auto tmp1 = $2;
        res = new IR(kCompressedDeprecatedDataTypeAttribute, OP3("COMPRESSED_SYM", "", ""), tmp1);
        $$ = res;
    }

;


compressed_deprecated_column_attribute:

    COMPRESSED_SYM opt_compression_method {
        auto tmp1 = $2;
        res = new IR(kCompressedDeprecatedColumnAttribute, OP3("COMPRESSED_SYM", "", ""), tmp1);
        $$ = res;
    }

;


asrow_attribute:

    not NULL_SYM opt_enable {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAsrowAttribute, OP3("", "NULL_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | opt_primary KEY_SYM {
        auto tmp1 = $1;
        res = new IR(kAsrowAttribute, OP3("", "KEY_SYM", ""), tmp1);
        $$ = res;
    }

    | vcol_attribute {
        auto tmp1 = $1;
        res = new IR(kAsrowAttribute, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


serial_attribute:

    asrow_attribute {
        auto tmp1 = $1;
        res = new IR(kSerialAttribute, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | engine_defined_option {
        auto tmp1 = $1;
        res = new IR(kSerialAttribute, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | with_or_without_system VERSIONING_SYM {
        auto tmp1 = $1;
        res = new IR(kSerialAttribute, OP3("", "VERSIONING_SYM", ""), tmp1);
        $$ = res;
    }

;


with_or_without_system:

    WITH_SYSTEM_SYM {
        auto tmp1 = $1;
        res = new IR(kWithOrWithoutSystem, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | WITHOUT SYSTEM {
        res = new IR(kWithOrWithoutSystem, OP3("WITHOUT SYSTEM", "", ""));
        $$ = res;
    }

;



charset:

    CHAR_SYM SET {
        res = new IR(kCharset, OP3("CHAR_SYM SET", "", ""));
        $$ = res;
    }

    | CHARSET {
        res = new IR(kCharset, OP3("CHARSET", "", ""));
        $$ = res;
    }

;


charset_name:

    ident_or_text {
        auto tmp1 = $1;
        res = new IR(kCharsetName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | BINARY {
        res = new IR(kCharsetName, OP3("BINARY", "", ""));
        $$ = res;
    }

;


charset_name_or_default:

    charset_name {
        auto tmp1 = $1;
        res = new IR(kCharsetNameOrDefault, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kCharsetNameOrDefault, OP3("DEFAULT", "", ""));
        $$ = res;
    }

;


opt_load_data_charset:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptLoadDataCharset, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | charset charset_name_or_default {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptLoadDataCharset, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


old_or_new_charset_name:

    ident_or_text {
        auto tmp1 = $1;
        res = new IR(kOldOrNewCharsetName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | BINARY {
        res = new IR(kOldOrNewCharsetName, OP3("BINARY", "", ""));
        $$ = res;
    }

;


old_or_new_charset_name_or_default:

    old_or_new_charset_name {
        auto tmp1 = $1;
        res = new IR(kOldOrNewCharsetNameOrDefault, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kOldOrNewCharsetNameOrDefault, OP3("DEFAULT", "", ""));
        $$ = res;
    }

;


collation_name:

    ident_or_text {
        auto tmp1 = $1;
        res = new IR(kCollationName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


collation_name_or_default:

    collation_name {
        auto tmp1 = $1;
        res = new IR(kCollationNameOrDefault, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kCollationNameOrDefault, OP3("DEFAULT", "", ""));
        $$ = res;
    }

;


opt_default:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptDefault, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT{}} {
        auto tmp1 = $1;
        res = new IR(kOptDefault, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


charset_or_alias:

    charset charset_name {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCharsetOrAlias, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ASCII_SYM {
        res = new IR(kCharsetOrAlias, OP3("ASCII_SYM", "", ""));
        $$ = res;
    }

    | UNICODE_SYM {
        res = new IR(kCharsetOrAlias, OP3("UNICODE_SYM", "", ""));
        $$ = res;
    }

;


opt_binary:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptBinary, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | binary {
        auto tmp1 = $1;
        res = new IR(kOptBinary, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


binary:

    BYTE_SYM {
        res = new IR(kBinary, OP3("BYTE_SYM", "", ""));
        $$ = res;
    }

    | charset_or_alias {
        auto tmp1 = $1;
        res = new IR(kBinary, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | charset_or_alias BINARY {
        auto tmp1 = $1;
        res = new IR(kBinary, OP3("", "BINARY", ""), tmp1);
        $$ = res;
    }

    | BINARY {
        res = new IR(kBinary, OP3("BINARY", "", ""));
        $$ = res;
    }

    | BINARY charset_or_alias {
        auto tmp1 = $2;
        res = new IR(kBinary, OP3("BINARY", "", ""), tmp1);
        $$ = res;
    }

    | charset_or_alias COLLATE_SYM DEFAULT {
        auto tmp1 = $1;
        res = new IR(kBinary, OP3("", "COLLATE_SYM DEFAULT", ""), tmp1);
        $$ = res;
    }

    | charset_or_alias COLLATE_SYM collation_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBinary, OP3("", "COLLATE_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | COLLATE_SYM collation_name {
        auto tmp1 = $2;
        res = new IR(kBinary, OP3("COLLATE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | COLLATE_SYM DEFAULT {
        res = new IR(kBinary, OP3("COLLATE_SYM DEFAULT", "", ""));
        $$ = res;
    }

;


opt_bin_mod:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptBinMod, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | BINARY {
        res = new IR(kOptBinMod, OP3("BINARY", "", ""));
        $$ = res;
    }

;


ws_nweights:

    '(' real_ulong_num {} ')' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kWsNweights, OP3("(", "", ")"), tmp1, tmp2);
        $$ = res;
    }

;


ws_level_flag_desc:

    ASC {
        res = new IR(kWsLevelFlagDesc, OP3("ASC", "", ""));
        $$ = res;
    }

    | DESC {
        res = new IR(kWsLevelFlagDesc, OP3("DESC", "", ""));
        $$ = res;
    }

;


ws_level_flag_reverse:

    REVERSE_SYM {
        res = new IR(kWsLevelFlagReverse, OP3("REVERSE_SYM", "", ""));
        $$ = res;
    }

;


ws_level_flags:

    {} {
        auto tmp1 = $1;
        res = new IR(kWsLevelFlags, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ws_level_flag_desc {
        auto tmp1 = $1;
        res = new IR(kWsLevelFlags, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ws_level_flag_desc ws_level_flag_reverse {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kWsLevelFlags, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ws_level_flag_reverse {
        auto tmp1 = $1;
        res = new IR(kWsLevelFlags, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ws_level_number:

    real_ulong_num {
        auto tmp1 = $1;
        res = new IR(kWsLevelNumber, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ws_level_list_item:

    ws_level_number ws_level_flags {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kWsLevelListItem, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


ws_level_list:

    ws_level_list_item {
        auto tmp1 = $1;
        res = new IR(kWsLevelList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ws_level_list ',' ws_level_list_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kWsLevelList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


ws_level_range:

    ws_level_number '-' ws_level_number {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kWsLevelRange, OP3("", "-", ""), tmp1, tmp2);
        $$ = res;
    }

;


ws_level_list_or_range:

    ws_level_list {
        auto tmp1 = $1;
        res = new IR(kWsLevelListOrRange, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ws_level_range {
        auto tmp1 = $1;
        res = new IR(kWsLevelListOrRange, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_ws_levels:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptWsLevels, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LEVEL_SYM ws_level_list_or_range {
        auto tmp1 = $2;
        res = new IR(kOptWsLevels, OP3("LEVEL_SYM", "", ""), tmp1);
        $$ = res;
    }

;


opt_primary:

    PRIMARY_SYM {
        res = new IR(kOptPrimary, OP3("PRIMARY_SYM", "", ""));
        $$ = res;
    }

    | PRIMARY_SYM {
        res = new IR(kOptPrimary, OP3("PRIMARY_SYM", "", ""));
        $$ = res;
    }

;


references:

    REFERENCES table_ident opt_ref_list opt_match_clause opt_on_update_delete {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kReferences_1, OP3("REFERENCES", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kReferences_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kReferences, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


opt_ref_list:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptRefList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' ref_list ')' {
        auto tmp1 = $2;
        res = new IR(kOptRefList, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


ref_list:

    ref_list ',' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRefList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | ident {
        auto tmp1 = $1;
        res = new IR(kRefList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_match_clause:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptMatchClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | MATCH FULL {
        res = new IR(kOptMatchClause, OP3("MATCH FULL", "", ""));
        $$ = res;
    }

    | MATCH PARTIAL {
        res = new IR(kOptMatchClause, OP3("MATCH PARTIAL", "", ""));
        $$ = res;
    }

    | MATCH SIMPLE_SYM {
        res = new IR(kOptMatchClause, OP3("MATCH SIMPLE_SYM", "", ""));
        $$ = res;
    }

;


opt_on_update_delete:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptOnUpdateDelete, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ON UPDATE_SYM delete_option {
        auto tmp1 = $3;
        res = new IR(kOptOnUpdateDelete, OP3("ON UPDATE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | ON DELETE_SYM delete_option {
        auto tmp1 = $3;
        res = new IR(kOptOnUpdateDelete, OP3("ON DELETE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | ON UPDATE_SYM delete_option ON DELETE_SYM delete_option {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kOptOnUpdateDelete, OP3("ON UPDATE_SYM", "ON DELETE_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | ON DELETE_SYM delete_option ON UPDATE_SYM delete_option {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kOptOnUpdateDelete, OP3("ON DELETE_SYM", "ON UPDATE_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

;


delete_option:

    RESTRICT {
        res = new IR(kDeleteOption, OP3("RESTRICT", "", ""));
        $$ = res;
    }

    | CASCADE {
        res = new IR(kDeleteOption, OP3("CASCADE", "", ""));
        $$ = res;
    }

    | SET NULL_SYM {
        res = new IR(kDeleteOption, OP3("SET NULL_SYM", "", ""));
        $$ = res;
    }

    | NO_SYM ACTION {
        res = new IR(kDeleteOption, OP3("NO_SYM ACTION", "", ""));
        $$ = res;
    }

    | SET DEFAULT {
        res = new IR(kDeleteOption, OP3("SET DEFAULT", "", ""));
        $$ = res;
    }

;


constraint_key_type:

    PRIMARY_SYM KEY_SYM {
        res = new IR(kConstraintKeyType, OP3("PRIMARY_SYM KEY_SYM", "", ""));
        $$ = res;
    }

    | UNIQUE_SYM opt_key_or_index {
        auto tmp1 = $2;
        res = new IR(kConstraintKeyType, OP3("UNIQUE_SYM", "", ""), tmp1);
        $$ = res;
    }

;


key_or_index:

    KEY_SYM {
        res = new IR(kKeyOrIndex, OP3("KEY_SYM", "", ""));
        $$ = res;
    }

    | INDEX_SYM {
        res = new IR(kKeyOrIndex, OP3("INDEX_SYM", "", ""));
        $$ = res;
    }

;


opt_key_or_index:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptKeyOrIndex, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | key_or_index {
        auto tmp1 = $1;
        res = new IR(kOptKeyOrIndex, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


keys_or_index:

    KEYS {
        res = new IR(kKeysOrIndex, OP3("KEYS", "", ""));
        $$ = res;
    }

    | INDEX_SYM {
        res = new IR(kKeysOrIndex, OP3("INDEX_SYM", "", ""));
        $$ = res;
    }

    | INDEXES {
        res = new IR(kKeysOrIndex, OP3("INDEXES", "", ""));
        $$ = res;
    }

;


fulltext:

    FULLTEXT_SYM {
        res = new IR(kFulltext, OP3("FULLTEXT_SYM", "", ""));
        $$ = res;
    }

;


spatial:

    SPATIAL_SYM {
        res = new IR(kSpatial, OP3("SPATIAL_SYM", "", ""));
        $$ = res;
    }

;


normal_key_options:

    {} {
        auto tmp1 = $1;
        res = new IR(kNormalKeyOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | normal_key_opts{} } {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kNormalKeyOptions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


fulltext_key_options:

    {} {
        auto tmp1 = $1;
        res = new IR(kFulltextKeyOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | fulltext_key_opts{} } {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFulltextKeyOptions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


spatial_key_options:

    {} {
        auto tmp1 = $1;
        res = new IR(kSpatialKeyOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | spatial_key_opts{} } {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpatialKeyOptions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


normal_key_opts:

    normal_key_opt {
        auto tmp1 = $1;
        res = new IR(kNormalKeyOpts, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | normal_key_opts normal_key_opt {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kNormalKeyOpts, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


spatial_key_opts:

    spatial_key_opt {
        auto tmp1 = $1;
        res = new IR(kSpatialKeyOpts, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | spatial_key_opts spatial_key_opt {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpatialKeyOpts, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


fulltext_key_opts:

    fulltext_key_opt {
        auto tmp1 = $1;
        res = new IR(kFulltextKeyOpts, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | fulltext_key_opts fulltext_key_opt {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFulltextKeyOpts, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_USING_key_algorithm:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptUSINGKeyAlgorithm, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | USING btree_or_rtree {
        auto tmp1 = $2;
        res = new IR(kOptUSINGKeyAlgorithm, OP3("USING", "", ""), tmp1);
        $$ = res;
    }

;



opt_key_algorithm_clause:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptKeyAlgorithmClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | USING btree_or_rtree {
        auto tmp1 = $2;
        res = new IR(kOptKeyAlgorithmClause, OP3("USING", "", ""), tmp1);
        $$ = res;
    }

    | TYPE_SYM btree_or_rtree {
        auto tmp1 = $2;
        res = new IR(kOptKeyAlgorithmClause, OP3("TYPE_SYM", "", ""), tmp1);
        $$ = res;
    }

;


key_using_alg:

    USING btree_or_rtree {
        auto tmp1 = $2;
        res = new IR(kKeyUsingAlg, OP3("USING", "", ""), tmp1);
        $$ = res;
    }

    | TYPE_SYM btree_or_rtree {
        auto tmp1 = $2;
        res = new IR(kKeyUsingAlg, OP3("TYPE_SYM", "", ""), tmp1);
        $$ = res;
    }

;


all_key_opt:

    KEY_BLOCK_SIZE opt_equal ulong_num {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAllKeyOpt, OP3("KEY_BLOCK_SIZE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | COMMENT_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kAllKeyOpt, OP3("COMMENT_SYM", "", ""), tmp1);
        $$ = res;
    }

    | VISIBLE_SYM {
        res = new IR(kAllKeyOpt, OP3("VISIBLE_SYM", "", ""));
        $$ = res;
    }

    | ignorability {
        auto tmp1 = $1;
        res = new IR(kAllKeyOpt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | engine_defined_option {
        auto tmp1 = $1;
        res = new IR(kAllKeyOpt, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


normal_key_opt:

    all_key_opt {
        auto tmp1 = $1;
        res = new IR(kNormalKeyOpt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | key_using_alg {
        auto tmp1 = $1;
        res = new IR(kNormalKeyOpt, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


spatial_key_opt:

    all_key_opt {
        auto tmp1 = $1;
        res = new IR(kSpatialKeyOpt, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


fulltext_key_opt:

    all_key_opt {
        auto tmp1 = $1;
        res = new IR(kFulltextKeyOpt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | WITH PARSER_SYM IDENT_sys {
        auto tmp1 = $3;
        res = new IR(kFulltextKeyOpt, OP3("WITH PARSER_SYM", "", ""), tmp1);
        $$ = res;
    }

;


btree_or_rtree:

    BTREE_SYM {
        res = new IR(kBtreeOrRtree, OP3("BTREE_SYM", "", ""));
        $$ = res;
    }

    | RTREE_SYM {
        res = new IR(kBtreeOrRtree, OP3("RTREE_SYM", "", ""));
        $$ = res;
    }

    | HASH_SYM {
        res = new IR(kBtreeOrRtree, OP3("HASH_SYM", "", ""));
        $$ = res;
    }

;


ignorability:

    IGNORED_SYM {
        res = new IR(kIgnorability, OP3("IGNORED_SYM", "", ""));
        $$ = res;
    }

    | NOT_SYM IGNORED_SYM {
        res = new IR(kIgnorability, OP3("NOT_SYM IGNORED_SYM", "", ""));
        $$ = res;
    }

;


key_list:

    key_list ',' key_part order_dir {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kKeyList_1, OP3("", ",", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kKeyList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | key_part order_dir {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kKeyList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_without_overlaps:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptWithoutOverlaps, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ',' ident WITHOUT OVERLAPS_SYM{} } {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kOptWithoutOverlaps_1, OP3(",", "WITHOUT", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kOptWithoutOverlaps, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


key_part:

    ident {
        auto tmp1 = $1;
        res = new IR(kKeyPart, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident '(' NUM ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kKeyPart, OP3("", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

;


opt_ident:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | field_ident {
        auto tmp1 = $1;
        res = new IR(kOptIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


string_list:

    text_string {
        auto tmp1 = $1;
        res = new IR(kStringList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | string_list ',' text_string {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kStringList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;




alter:

    ALTER {} alter_options TABLE_SYM opt_if_exists table_ident opt_lock_wait_timeout {} alter_commands {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlter_1, OP3("ALTER", "", "TABLE_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kAlter_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kAlter_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kAlter_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $8;
        res = new IR(kAlter_5, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $9;
        res = new IR(kAlter, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

    | ALTER DATABASE ident_or_empty {} create_database_options {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlter_6, OP3("ALTER DATABASE", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kAlter, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ALTER DATABASE COMMENT_SYM opt_equal TEXT_STRING_sys {} opt_create_database_options {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kAlter_7, OP3("ALTER DATABASE COMMENT_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kAlter_8, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $7;
        res = new IR(kAlter, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | ALTER DATABASE ident UPGRADE_SYM DATA_SYM DIRECTORY_SYM NAME_SYM {
        auto tmp1 = $3;
        res = new IR(kAlter, OP3("ALTER DATABASE", "UPGRADE_SYM DATA_SYM DIRECTORY_SYM NAME_SYM", ""), tmp1);
        $$ = res;
    }

    | ALTER PROCEDURE_SYM sp_name {} sp_a_chistics stmt_end {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlter_9, OP3("ALTER PROCEDURE_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kAlter_10, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kAlter, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | ALTER FUNCTION_SYM sp_name {} sp_a_chistics stmt_end {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlter_11, OP3("ALTER FUNCTION_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kAlter_12, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kAlter, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | ALTER view_algorithm definer_opt opt_view_suid VIEW_SYM table_ident {} view_list_opt AS view_select stmt_end {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlter_13, OP3("ALTER", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kAlter_14, OP3("", "", "VIEW_SYM"), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kAlter_15, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kAlter_16, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $8;
        res = new IR(kAlter_17, OP3("", "", "AS"), res, tmp6);
        PUSH(res);
        auto tmp7 = $10;
        res = new IR(kAlter_18, OP3("", "", ""), res, tmp7);
        PUSH(res);
        auto tmp8 = $11;
        res = new IR(kAlter, OP3("", "", ""), res, tmp8);
        $$ = res;
    }

    | ALTER definer_opt opt_view_suid VIEW_SYM table_ident {} view_list_opt AS view_select stmt_end {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlter_19, OP3("ALTER", "", "VIEW_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kAlter_20, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kAlter_21, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kAlter_22, OP3("", "", "AS"), res, tmp5);
        PUSH(res);
        auto tmp6 = $9;
        res = new IR(kAlter_23, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $10;
        res = new IR(kAlter, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

    | ALTER definer_opt remember_name EVENT_SYM sp_name {} ev_alter_on_schedule_completion opt_ev_rename_to opt_ev_status opt_ev_comment opt_ev_sql_stmt {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlter_24, OP3("ALTER", "", "EVENT_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kAlter_25, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kAlter_26, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kAlter_27, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $8;
        res = new IR(kAlter_28, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $9;
        res = new IR(kAlter_29, OP3("", "", ""), res, tmp7);
        PUSH(res);
        auto tmp8 = $10;
        res = new IR(kAlter_30, OP3("", "", ""), res, tmp8);
        PUSH(res);
        auto tmp9 = $11;
        res = new IR(kAlter, OP3("", "", ""), res, tmp9);
        $$ = res;
    }

    | ALTER SERVER_SYM ident_or_text {} OPTIONS_SYM '(' server_options_list ')' {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlter_31, OP3("ALTER SERVER_SYM", "", "OPTIONS_SYM ("), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kAlter, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | ALTER USER_SYM opt_if_exists clear_privileges grant_list opt_require_clause opt_resource_options opt_account_locking_and_opt_password_expiration {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlter_32, OP3("ALTER USER_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kAlter_33, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kAlter_34, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kAlter_35, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $8;
        res = new IR(kAlter, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | ALTER SEQUENCE_SYM opt_if_exists {} table_ident {} sequence_defs {} stmt_end {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlter_36, OP3("ALTER SEQUENCE_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kAlter_37, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kAlter_38, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kAlter_39, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $8;
        res = new IR(kAlter_40, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $9;
        res = new IR(kAlter, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

;


account_locking_option:

    LOCK_SYM {
        res = new IR(kAccountLockingOption, OP3("LOCK_SYM", "", ""));
        $$ = res;
    }

    | UNLOCK_SYM {
        res = new IR(kAccountLockingOption, OP3("UNLOCK_SYM", "", ""));
        $$ = res;
    }

;


opt_password_expire_option:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptPasswordExpireOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NEVER_SYM {
        res = new IR(kOptPasswordExpireOption, OP3("NEVER_SYM", "", ""));
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kOptPasswordExpireOption, OP3("DEFAULT", "", ""));
        $$ = res;
    }

    | INTERVAL_SYM NUM DAY_SYM {
        auto tmp1 = $2;
        res = new IR(kOptPasswordExpireOption, OP3("INTERVAL_SYM", "DAY_SYM", ""), tmp1);
        $$ = res;
    }

;


opt_account_locking_and_opt_password_expiration:

    ACCOUNT_SYM account_locking_option {
        auto tmp1 = $2;
        res = new IR(kOptAccountLockingAndOptPasswordExpiration, OP3("ACCOUNT_SYM", "", ""), tmp1);
        $$ = res;
    }

    | ACCOUNT_SYM account_locking_option {
        auto tmp1 = $2;
        res = new IR(kOptAccountLockingAndOptPasswordExpiration, OP3("ACCOUNT_SYM", "", ""), tmp1);
        $$ = res;
    }

    | PASSWORD_SYM EXPIRE_SYM opt_password_expire_option {
        auto tmp1 = $3;
        res = new IR(kOptAccountLockingAndOptPasswordExpiration, OP3("PASSWORD_SYM EXPIRE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | ACCOUNT_SYM account_locking_option PASSWORD_SYM EXPIRE_SYM opt_password_expire_option {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kOptAccountLockingAndOptPasswordExpiration, OP3("ACCOUNT_SYM", "PASSWORD_SYM EXPIRE_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | PASSWORD_SYM EXPIRE_SYM opt_password_expire_option ACCOUNT_SYM account_locking_option {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kOptAccountLockingAndOptPasswordExpiration, OP3("PASSWORD_SYM EXPIRE_SYM", "ACCOUNT_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

;


ev_alter_on_schedule_completion:

    {} {
        auto tmp1 = $1;
        res = new IR(kEvAlterOnScheduleCompletion, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ON SCHEDULE_SYM ev_schedule_time {
        auto tmp1 = $3;
        res = new IR(kEvAlterOnScheduleCompletion, OP3("ON SCHEDULE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | ev_on_completion {
        auto tmp1 = $1;
        res = new IR(kEvAlterOnScheduleCompletion, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ON SCHEDULE_SYM ev_schedule_time ev_on_completion {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kEvAlterOnScheduleCompletion, OP3("ON SCHEDULE_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_ev_rename_to:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptEvRenameTo, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RENAME TO_SYM sp_name {
        auto tmp1 = $3;
        res = new IR(kOptEvRenameTo, OP3("RENAME TO_SYM", "", ""), tmp1);
        $$ = res;
    }

;


opt_ev_sql_stmt:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptEvSqlStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DO_SYM ev_sql_stmt {
        auto tmp1 = $2;
        res = new IR(kOptEvSqlStmt, OP3("DO_SYM", "", ""), tmp1);
        $$ = res;
    }

;


ident_or_empty:

    prec PREC_BELOW_IDENTIFIER_OPT_SPECIAL_CASE {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kIdentOrEmpty, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ident {
        auto tmp1 = $1;
        res = new IR(kIdentOrEmpty, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


alter_commands:

    DISCARD TABLESPACE {
        res = new IR(kAlterCommands, OP3("DISCARD TABLESPACE", "", ""));
        $$ = res;
    }

    | DISCARD TABLESPACE {
        res = new IR(kAlterCommands, OP3("DISCARD TABLESPACE", "", ""));
        $$ = res;
    }

    | IMPORT TABLESPACE {
        res = new IR(kAlterCommands, OP3("IMPORT TABLESPACE", "", ""));
        $$ = res;
    }

    | alter_list opt_partitioning {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterCommands, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | alter_list remove_partitioning {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterCommands, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | remove_partitioning {
        auto tmp1 = $1;
        res = new IR(kAlterCommands, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | partitioning {
        auto tmp1 = $1;
        res = new IR(kAlterCommands, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | add_partition_rule {
        auto tmp1 = $1;
        res = new IR(kAlterCommands, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DROP PARTITION_SYM opt_if_exists alt_part_name_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterCommands, OP3("DROP PARTITION_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | REBUILD_SYM PARTITION_SYM opt_no_write_to_binlog all_or_alt_part_name_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterCommands, OP3("REBUILD_SYM PARTITION_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | OPTIMIZE PARTITION_SYM opt_no_write_to_binlog all_or_alt_part_name_list {} opt_no_write_to_binlog {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterCommands_1, OP3("OPTIMIZE PARTITION_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kAlterCommands_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kAlterCommands, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | ANALYZE_SYM PARTITION_SYM opt_no_write_to_binlog all_or_alt_part_name_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterCommands, OP3("ANALYZE_SYM PARTITION_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CHECK_SYM PARTITION_SYM all_or_alt_part_name_list {} opt_mi_check_type {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterCommands_3, OP3("CHECK_SYM PARTITION_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kAlterCommands, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | REPAIR PARTITION_SYM opt_no_write_to_binlog all_or_alt_part_name_list {} opt_mi_repair_type {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterCommands_4, OP3("REPAIR PARTITION_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kAlterCommands_5, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kAlterCommands, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | COALESCE PARTITION_SYM opt_no_write_to_binlog real_ulong_num {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterCommands, OP3("COALESCE PARTITION_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | TRUNCATE_SYM PARTITION_SYM all_or_alt_part_name_list {
        auto tmp1 = $3;
        res = new IR(kAlterCommands, OP3("TRUNCATE_SYM PARTITION_SYM", "", ""), tmp1);
        $$ = res;
    }

    | reorg_partition_rule {
        auto tmp1 = $1;
        res = new IR(kAlterCommands, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | EXCHANGE_SYM PARTITION_SYM alt_part_name_item WITH TABLE_SYM table_ident have_partitioning {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterCommands_6, OP3("EXCHANGE_SYM PARTITION_SYM", "WITH TABLE_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kAlterCommands, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CONVERT_SYM PARTITION_SYM alt_part_name_item TO_SYM TABLE_SYM table_ident have_partitioning {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kAlterCommands_7, OP3("CONVERT_SYM PARTITION_SYM", "TO_SYM TABLE_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kAlterCommands, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CONVERT_SYM TABLE_SYM table_ident {} TO_SYM PARTITION_SYM part_definition {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterCommands_8, OP3("CONVERT_SYM TABLE_SYM", "", "TO_SYM PARTITION_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kAlterCommands, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


remove_partitioning:

    REMOVE_SYM PARTITIONING_SYM {
        res = new IR(kRemovePartitioning, OP3("REMOVE_SYM PARTITIONING_SYM", "", ""));
        $$ = res;
    }

;


all_or_alt_part_name_list:

    ALL {
        res = new IR(kAllOrAltPartNameList, OP3("ALL", "", ""));
        $$ = res;
    }

    | alt_part_name_list {
        auto tmp1 = $1;
        res = new IR(kAllOrAltPartNameList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


add_partition_rule:

    ADD PARTITION_SYM opt_if_not_exists opt_no_write_to_binlog {} add_part_extra {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAddPartitionRule_1, OP3("ADD PARTITION_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kAddPartitionRule_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kAddPartitionRule, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


add_part_extra:

    '(' part_def_list ')' {
        auto tmp1 = $2;
        res = new IR(kAddPartExtra, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | '(' part_def_list ')' {
        auto tmp1 = $2;
        res = new IR(kAddPartExtra, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | PARTITIONS_SYM real_ulong_num {
        auto tmp1 = $2;
        res = new IR(kAddPartExtra, OP3("PARTITIONS_SYM", "", ""), tmp1);
        $$ = res;
    }

;


reorg_partition_rule:

    REORGANIZE_SYM PARTITION_SYM opt_no_write_to_binlog {} reorg_parts_rule {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kReorgPartitionRule_1, OP3("REORGANIZE_SYM PARTITION_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kReorgPartitionRule, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


reorg_parts_rule:

    {} {
        auto tmp1 = $1;
        res = new IR(kReorgPartsRule, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alt_part_name_list {} INTO '(' part_def_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kReorgPartsRule_1, OP3("", "", "INTO ("), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kReorgPartsRule, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

;


alt_part_name_list:

    alt_part_name_item {
        auto tmp1 = $1;
        res = new IR(kAltPartNameList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alt_part_name_list ',' alt_part_name_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAltPartNameList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


alt_part_name_item:

    ident {
        auto tmp1 = $1;
        res = new IR(kAltPartNameItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

;




alter_list:

    alter_list_item {
        auto tmp1 = $1;
        res = new IR(kAlterList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_list ',' alter_list_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


add_column:

    ADD opt_column opt_if_not_exists_table_element {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAddColumn, OP3("ADD", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_list_item:

    add_column column_def opt_place {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterListItem_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kAlterListItem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ADD key_def {
        auto tmp1 = $2;
        res = new IR(kAlterListItem, OP3("ADD", "", ""), tmp1);
        $$ = res;
    }

    | ADD period_for_system_time {
        auto tmp1 = $2;
        res = new IR(kAlterListItem, OP3("ADD", "", ""), tmp1);
        $$ = res;
    }

    | ADD PERIOD_SYM opt_if_not_exists_table_element period_for_application_time {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterListItem, OP3("ADD PERIOD_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | add_column '(' create_field_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterListItem, OP3("", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

    | ADD constraint_def {
        auto tmp1 = $2;
        res = new IR(kAlterListItem, OP3("ADD", "", ""), tmp1);
        $$ = res;
    }

    | ADD CONSTRAINT IF_SYM not EXISTS field_ident check_constraint {
        auto tmp1 = $4;
        auto tmp2 = $6;
        res = new IR(kAlterListItem_2, OP3("ADD CONSTRAINT IF_SYM", "EXISTS", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kAlterListItem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CHANGE opt_column opt_if_exists_table_element field_ident field_spec opt_place {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem_3, OP3("CHANGE", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kAlterListItem_4, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kAlterListItem_5, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kAlterListItem, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | MODIFY_SYM opt_column opt_if_exists_table_element field_spec opt_place {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem_6, OP3("MODIFY_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kAlterListItem_7, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kAlterListItem, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | DROP opt_column opt_if_exists_table_element field_ident opt_restrict {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem_8, OP3("DROP", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kAlterListItem_9, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kAlterListItem, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | DROP CONSTRAINT opt_if_exists_table_element field_ident {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterListItem, OP3("DROP CONSTRAINT", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP FOREIGN KEY_SYM opt_if_exists_table_element field_ident {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kAlterListItem, OP3("DROP FOREIGN KEY_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP opt_constraint_no_id PRIMARY_SYM KEY_SYM {
        auto tmp1 = $2;
        res = new IR(kAlterListItem, OP3("DROP", "PRIMARY_SYM KEY_SYM", ""), tmp1);
        $$ = res;
    }

    | DROP key_or_index opt_if_exists_table_element field_ident {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem_10, OP3("DROP", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kAlterListItem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | DISABLE_SYM KEYS {
        res = new IR(kAlterListItem, OP3("DISABLE_SYM KEYS", "", ""));
        $$ = res;
    }

    | ENABLE_SYM KEYS {
        res = new IR(kAlterListItem, OP3("ENABLE_SYM KEYS", "", ""));
        $$ = res;
    }

    | ALTER opt_column opt_if_exists_table_element field_ident SET DEFAULT column_default_expr {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem_11, OP3("ALTER", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kAlterListItem_12, OP3("", "", "SET DEFAULT"), res, tmp3);
        PUSH(res);
        auto tmp4 = $7;
        res = new IR(kAlterListItem, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | ALTER key_or_index opt_if_exists_table_element ident ignorability {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem_13, OP3("ALTER", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kAlterListItem_14, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kAlterListItem, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | ALTER opt_column opt_if_exists_table_element field_ident DROP DEFAULT {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem_15, OP3("ALTER", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kAlterListItem, OP3("", "", "DROP DEFAULT"), res, tmp3);
        $$ = res;
    }

    | RENAME opt_to table_ident {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem, OP3("RENAME", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | RENAME COLUMN_SYM opt_if_exists_table_element ident TO_SYM ident {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterListItem_16, OP3("RENAME COLUMN_SYM", "", "TO_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kAlterListItem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | RENAME key_or_index opt_if_exists_table_element field_ident TO_SYM field_ident {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterListItem_17, OP3("RENAME", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kAlterListItem_18, OP3("", "", "TO_SYM"), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kAlterListItem, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | CONVERT_SYM TO_SYM charset charset_name_or_default {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterListItem, OP3("CONVERT_SYM TO_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CONVERT_SYM TO_SYM charset charset_name_or_default COLLATE_SYM collation_name_or_default {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kAlterListItem_19, OP3("CONVERT_SYM TO_SYM", "", "COLLATE_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kAlterListItem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | create_table_options_space_separated {
        auto tmp1 = $1;
        res = new IR(kAlterListItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FORCE_SYM {
        res = new IR(kAlterListItem, OP3("FORCE_SYM", "", ""));
        $$ = res;
    }

    | alter_order_clause {
        auto tmp1 = $1;
        res = new IR(kAlterListItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_algorithm_option {
        auto tmp1 = $1;
        res = new IR(kAlterListItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_lock_option {
        auto tmp1 = $1;
        res = new IR(kAlterListItem, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ADD SYSTEM VERSIONING_SYM {
        res = new IR(kAlterListItem, OP3("ADD SYSTEM VERSIONING_SYM", "", ""));
        $$ = res;
    }

    | DROP SYSTEM VERSIONING_SYM {
        res = new IR(kAlterListItem, OP3("DROP SYSTEM VERSIONING_SYM", "", ""));
        $$ = res;
    }

    | DROP PERIOD_SYM FOR_SYSTEM_TIME_SYM {
        auto tmp1 = $3;
        res = new IR(kAlterListItem, OP3("DROP PERIOD_SYM", "", ""), tmp1);
        $$ = res;
    }

    | DROP PERIOD_SYM opt_if_exists_table_element FOR_SYM ident {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kAlterListItem, OP3("DROP PERIOD_SYM", "FOR_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_index_lock_algorithm:

    alter_lock_option {
        auto tmp1 = $1;
        res = new IR(kOptIndexLockAlgorithm, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_lock_option {
        auto tmp1 = $1;
        res = new IR(kOptIndexLockAlgorithm, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_algorithm_option {
        auto tmp1 = $1;
        res = new IR(kOptIndexLockAlgorithm, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_lock_option alter_algorithm_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptIndexLockAlgorithm, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | alter_algorithm_option alter_lock_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptIndexLockAlgorithm, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_algorithm_option:

    ALGORITHM_SYM opt_equal DEFAULT {
        auto tmp1 = $2;
        res = new IR(kAlterAlgorithmOption, OP3("ALGORITHM_SYM", "DEFAULT", ""), tmp1);
        $$ = res;
    }

    | ALGORITHM_SYM opt_equal ident {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterAlgorithmOption, OP3("ALGORITHM_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_lock_option:

    LOCK_SYM opt_equal DEFAULT {
        auto tmp1 = $2;
        res = new IR(kAlterLockOption, OP3("LOCK_SYM", "DEFAULT", ""), tmp1);
        $$ = res;
    }

    | LOCK_SYM opt_equal ident {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAlterLockOption, OP3("LOCK_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_column:

    {} %prec PREC_BELOW_IDENTIFIER_OPT_SPECIAL_CASE {
        auto tmp1 = $1;
        res = new IR(kOptColumn, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | COLUMN_SYM {
        res = new IR(kOptColumn, OP3("COLUMN_SYM", "", ""));
        $$ = res;
    }

;


opt_ignore:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptIgnore, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IGNORE_SYM {
        res = new IR(kOptIgnore, OP3("IGNORE_SYM", "", ""));
        $$ = res;
    }

;


alter_options:

    {} alter_options_part2 {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterOptions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


alter_options_part2:

    alter_option_list {
        auto tmp1 = $1;
        res = new IR(kAlterOptionsPart2, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | alter_option_list {
        auto tmp1 = $1;
        res = new IR(kAlterOptionsPart2, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


alter_option_list:

    alter_option_list alter_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterOptionList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | alter_option {
        auto tmp1 = $1;
        res = new IR(kAlterOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


alter_option:

    IGNORE_SYM {
        res = new IR(kAlterOption, OP3("IGNORE_SYM", "", ""));
        $$ = res;
    }

    | ONLINE_SYM {
        res = new IR(kAlterOption, OP3("ONLINE_SYM", "", ""));
        $$ = res;
    }

;


opt_restrict:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptRestrict, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RESTRICT {
        res = new IR(kOptRestrict, OP3("RESTRICT", "", ""));
        $$ = res;
    }

    | CASCADE {
        res = new IR(kOptRestrict, OP3("CASCADE", "", ""));
        $$ = res;
    }

;


opt_place:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptPlace, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AFTER_SYM ident {
        auto tmp1 = $2;
        res = new IR(kOptPlace, OP3("AFTER_SYM", "", ""), tmp1);
        $$ = res;
    }

    | FIRST_SYM {
        res = new IR(kOptPlace, OP3("FIRST_SYM", "", ""));
        $$ = res;
    }

;


opt_to:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptTo, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TO_SYM{}} {
        auto tmp1 = $1;
        res = new IR(kOptTo, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '='{}} {
        auto tmp1 = $1;
        res = new IR(kOptTo, OP3("'='{}}", "", ""), tmp1);
        $$ = res;
    }

    | AS{}} {
        auto tmp1 = $1;
        res = new IR(kOptTo, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


slave:

    START_SYM SLAVE optional_connection_name slave_thread_opts optional_for_channel {} slave_until {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kSlave_1, OP3("START_SYM SLAVE", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kSlave_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kSlave_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kSlave, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | START_SYM ALL SLAVES slave_thread_opts {} {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kSlave, OP3("START_SYM ALL SLAVES", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | STOP_SYM SLAVE optional_connection_name slave_thread_opts optional_for_channel {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kSlave_4, OP3("STOP_SYM SLAVE", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kSlave, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | STOP_SYM ALL SLAVES slave_thread_opts {
        auto tmp1 = $4;
        res = new IR(kSlave, OP3("STOP_SYM ALL SLAVES", "", ""), tmp1);
        $$ = res;
    }

;


start:

    START_SYM TRANSACTION_SYM opt_start_transaction_option_list {
        auto tmp1 = $3;
        res = new IR(kStart, OP3("START_SYM TRANSACTION_SYM", "", ""), tmp1);
        $$ = res;
    }

;


opt_start_transaction_option_list:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptStartTransactionOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | start_transaction_option_list {
        auto tmp1 = $1;
        res = new IR(kOptStartTransactionOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


start_transaction_option_list:

    start_transaction_option {
        auto tmp1 = $1;
        res = new IR(kStartTransactionOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | start_transaction_option_list ',' start_transaction_option {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kStartTransactionOptionList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


start_transaction_option:

    WITH CONSISTENT_SYM SNAPSHOT_SYM {
        res = new IR(kStartTransactionOption, OP3("WITH CONSISTENT_SYM SNAPSHOT_SYM", "", ""));
        $$ = res;
    }

    | READ_SYM ONLY_SYM {
        res = new IR(kStartTransactionOption, OP3("READ_SYM ONLY_SYM", "", ""));
        $$ = res;
    }

    | READ_SYM WRITE_SYM {
        res = new IR(kStartTransactionOption, OP3("READ_SYM WRITE_SYM", "", ""));
        $$ = res;
    }

;


slave_thread_opts:

    {} slave_thread_opt_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSlaveThreadOpts, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


slave_thread_opt_list:

    slave_thread_opt {
        auto tmp1 = $1;
        res = new IR(kSlaveThreadOptList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | slave_thread_opt_list ',' slave_thread_opt {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSlaveThreadOptList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


slave_thread_opt:

    {} {
        auto tmp1 = $1;
        res = new IR(kSlaveThreadOpt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SQL_THREAD {} } {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSlaveThreadOpt, OP3("SQL_THREAD", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | RELAY_THREAD{} } {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSlaveThreadOpt, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


slave_until:

    {} {
        auto tmp1 = $1;
        res = new IR(kSlaveUntil, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | UNTIL_SYM slave_until_opts{} } {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSlaveUntil, OP3("UNTIL_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | UNTIL_SYM MASTER_GTID_POS_SYM '=' TEXT_STRING_sys{} } {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kSlaveUntil, OP3("UNTIL_SYM MASTER_GTID_POS_SYM =", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


slave_until_opts:

    master_file_def {
        auto tmp1 = $1;
        res = new IR(kSlaveUntilOpts, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | slave_until_opts ',' master_file_def {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSlaveUntilOpts, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


checksum:

    CHECKSUM_SYM table_or_tables {} table_list opt_checksum_type {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kChecksum_1, OP3("CHECKSUM_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kChecksum_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kChecksum, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


opt_checksum_type:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptChecksumType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | QUICK {
        res = new IR(kOptChecksumType, OP3("QUICK", "", ""));
        $$ = res;
    }

    | EXTENDED_SYM {
        res = new IR(kOptChecksumType, OP3("EXTENDED_SYM", "", ""));
        $$ = res;
    }

;


repair_table_or_view:

    table_or_tables table_list opt_mi_repair_type {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kRepairTableOrView_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kRepairTableOrView, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | VIEW_SYM {} table_list opt_view_repair_type {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kRepairTableOrView_2, OP3("VIEW_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kRepairTableOrView, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


repair:

    REPAIR opt_no_write_to_binlog {} repair_table_or_view {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kRepair_1, OP3("REPAIR", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kRepair, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_mi_repair_type:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptMiRepairType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | mi_repair_types {
        auto tmp1 = $1;
        res = new IR(kOptMiRepairType, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


mi_repair_types:

    mi_repair_type {
        auto tmp1 = $1;
        res = new IR(kMiRepairTypes, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | mi_repair_type mi_repair_types {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kMiRepairTypes, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


mi_repair_type:

    QUICK {
        res = new IR(kMiRepairType, OP3("QUICK", "", ""));
        $$ = res;
    }

    | EXTENDED_SYM {
        res = new IR(kMiRepairType, OP3("EXTENDED_SYM", "", ""));
        $$ = res;
    }

    | USE_FRM {
        res = new IR(kMiRepairType, OP3("USE_FRM", "", ""));
        $$ = res;
    }

;


opt_view_repair_type:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptViewRepairType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FROM MYSQL_SYM {
        res = new IR(kOptViewRepairType, OP3("FROM MYSQL_SYM", "", ""));
        $$ = res;
    }

;


analyze:

    ANALYZE_SYM opt_no_write_to_binlog table_or_tables {} analyze_table_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAnalyze_1, OP3("ANALYZE_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kAnalyze_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kAnalyze, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


analyze_table_list:

    analyze_table_elem_spec {
        auto tmp1 = $1;
        res = new IR(kAnalyzeTableList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | analyze_table_list ',' analyze_table_elem_spec {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAnalyzeTableList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


analyze_table_elem_spec:

    table_name opt_persistent_stat_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAnalyzeTableElemSpec, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_persistent_stat_clause:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptPersistentStatClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | PERSISTENT_SYM FOR_SYM persistent_stat_spec{} } {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptPersistentStatClause, OP3("PERSISTENT_SYM FOR_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


persistent_stat_spec:

    ALL {
        res = new IR(kPersistentStatSpec, OP3("ALL", "", ""));
        $$ = res;
    }

    | COLUMNS persistent_column_stat_spec INDEXES persistent_index_stat_spec {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kPersistentStatSpec, OP3("COLUMNS", "INDEXES", ""), tmp1, tmp2);
        $$ = res;
    }

;


persistent_column_stat_spec:

    ALL {
        res = new IR(kPersistentColumnStatSpec, OP3("ALL", "", ""));
        $$ = res;
    }

    | '(' {} table_column_list ')' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kPersistentColumnStatSpec, OP3("(", "", ")"), tmp1, tmp2);
        $$ = res;
    }

;


persistent_index_stat_spec:

    ALL {
        res = new IR(kPersistentIndexStatSpec, OP3("ALL", "", ""));
        $$ = res;
    }

    | '(' {} table_index_list ')' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kPersistentIndexStatSpec, OP3("(", "", ")"), tmp1, tmp2);
        $$ = res;
    }

;


table_column_list:

    {} {
        auto tmp1 = $1;
        res = new IR(kTableColumnList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident{} } {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableColumnList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | table_column_list ',' ident{} } {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableColumnList_1, OP3("", ",", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kTableColumnList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


table_index_list:

    {} {
        auto tmp1 = $1;
        res = new IR(kTableIndexList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_index_name {
        auto tmp1 = $1;
        res = new IR(kTableIndexList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_index_list ',' table_index_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableIndexList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


table_index_name:

    ident {
        auto tmp1 = $1;
        res = new IR(kTableIndexName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | PRIMARY_SYM {
        res = new IR(kTableIndexName, OP3("PRIMARY_SYM", "", ""));
        $$ = res;
    }

;


binlog_base64_event:

    BINLOG_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kBinlogBase64Event, OP3("BINLOG_SYM", "", ""), tmp1);
        $$ = res;
    }

    | BINLOG_SYM '@' ident_or_text ',' '@' ident_or_text {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kBinlogBase64Event, OP3("BINLOG_SYM @", ", @", ""), tmp1, tmp2);
        $$ = res;
    }

;


check_view_or_table:

    table_or_tables table_list opt_mi_check_type {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCheckViewOrTable_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kCheckViewOrTable, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | VIEW_SYM {} table_list opt_view_check_type {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCheckViewOrTable_2, OP3("VIEW_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kCheckViewOrTable, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


check:

    CHECK_SYM {} check_view_or_table {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCheck, OP3("CHECK_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_mi_check_type:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptMiCheckType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | mi_check_types {
        auto tmp1 = $1;
        res = new IR(kOptMiCheckType, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


mi_check_types:

    mi_check_type {
        auto tmp1 = $1;
        res = new IR(kMiCheckTypes, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | mi_check_type mi_check_types {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kMiCheckTypes, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


mi_check_type:

    QUICK {
        res = new IR(kMiCheckType, OP3("QUICK", "", ""));
        $$ = res;
    }

    | FAST_SYM {
        res = new IR(kMiCheckType, OP3("FAST_SYM", "", ""));
        $$ = res;
    }

    | MEDIUM_SYM {
        res = new IR(kMiCheckType, OP3("MEDIUM_SYM", "", ""));
        $$ = res;
    }

    | EXTENDED_SYM {
        res = new IR(kMiCheckType, OP3("EXTENDED_SYM", "", ""));
        $$ = res;
    }

    | CHANGED {
        res = new IR(kMiCheckType, OP3("CHANGED", "", ""));
        $$ = res;
    }

    | FOR_SYM UPGRADE_SYM {
        res = new IR(kMiCheckType, OP3("FOR_SYM UPGRADE_SYM", "", ""));
        $$ = res;
    }

;


opt_view_check_type:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptViewCheckType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FOR_SYM UPGRADE_SYM {
        res = new IR(kOptViewCheckType, OP3("FOR_SYM UPGRADE_SYM", "", ""));
        $$ = res;
    }

;


optimize:

    OPTIMIZE opt_no_write_to_binlog table_or_tables {} table_list opt_lock_wait_timeout {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptimize_1, OP3("OPTIMIZE", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kOptimize_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kOptimize_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kOptimize, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


opt_no_write_to_binlog:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptNoWriteToBinlog, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NO_WRITE_TO_BINLOG {
        res = new IR(kOptNoWriteToBinlog, OP3("NO_WRITE_TO_BINLOG", "", ""));
        $$ = res;
    }

    | LOCAL_SYM {
        res = new IR(kOptNoWriteToBinlog, OP3("LOCAL_SYM", "", ""));
        $$ = res;
    }

;


rename:

    RENAME table_or_tables opt_if_exists {} table_to_table_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kRename_1, OP3("RENAME", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kRename_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kRename, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | RENAME USER_SYM clear_privileges rename_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kRename, OP3("RENAME USER_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


rename_list:

    user TO_SYM user {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRenameList, OP3("", "TO_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | rename_list ',' user TO_SYM user {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRenameList_1, OP3("", ",", "TO_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kRenameList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


table_to_table_list:

    table_to_table {
        auto tmp1 = $1;
        res = new IR(kTableToTableList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_to_table_list ',' table_to_table {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableToTableList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


table_to_table:

    table_ident opt_lock_wait_timeout TO_SYM table_ident {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableToTable_1, OP3("", "", "TO_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kTableToTable, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


keycache:

    CACHE_SYM INDEX_SYM {} keycache_list_or_parts IN_SYM key_cache_name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kKeycache_1, OP3("CACHE_SYM INDEX_SYM", "", "IN_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kKeycache, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


keycache_list_or_parts:

    keycache_list {
        auto tmp1 = $1;
        res = new IR(kKeycacheListOrParts, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | assign_to_keycache_parts {
        auto tmp1 = $1;
        res = new IR(kKeycacheListOrParts, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


keycache_list:

    assign_to_keycache {
        auto tmp1 = $1;
        res = new IR(kKeycacheList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keycache_list ',' assign_to_keycache {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kKeycacheList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


assign_to_keycache:

    table_ident cache_keys_spec {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAssignToKeycache, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


assign_to_keycache_parts:

    table_ident adm_partition cache_keys_spec {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAssignToKeycacheParts_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kAssignToKeycacheParts, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


key_cache_name:

    ident {
        auto tmp1 = $1;
        res = new IR(kKeyCacheName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kKeyCacheName, OP3("DEFAULT", "", ""));
        $$ = res;
    }

;


preload:

    LOAD INDEX_SYM INTO CACHE_SYM {} preload_list_or_parts {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kPreload, OP3("LOAD INDEX_SYM INTO CACHE_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


preload_list_or_parts:

    preload_keys_parts {
        auto tmp1 = $1;
        res = new IR(kPreloadListOrParts, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | preload_list {
        auto tmp1 = $1;
        res = new IR(kPreloadListOrParts, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


preload_list:

    preload_keys {
        auto tmp1 = $1;
        res = new IR(kPreloadList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | preload_list ',' preload_keys {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPreloadList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


preload_keys:

    table_ident cache_keys_spec opt_ignore_leaves {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPreloadKeys_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kPreloadKeys, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


preload_keys_parts:

    table_ident adm_partition cache_keys_spec opt_ignore_leaves {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPreloadKeysParts_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kPreloadKeysParts_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kPreloadKeysParts, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


adm_partition:

    PARTITION_SYM have_partitioning {} '(' all_or_alt_part_name_list ')' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAdmPartition_1, OP3("PARTITION_SYM", "", "("), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kAdmPartition, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

;


cache_keys_spec:

    {} cache_key_list_or_empty {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCacheKeysSpec, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


cache_key_list_or_empty:

    {} {
        auto tmp1 = $1;
        res = new IR(kCacheKeyListOrEmpty, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | key_or_index '(' opt_key_usage_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCacheKeyListOrEmpty, OP3("", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

;


opt_ignore_leaves:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptIgnoreLeaves, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IGNORE_SYM LEAVES {
        res = new IR(kOptIgnoreLeaves, OP3("IGNORE_SYM LEAVES", "", ""));
        $$ = res;
    }

;





select:

    query_expression_no_with_clause {} opt_procedure_or_into {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelect_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSelect, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | with_clause query_expression_no_with_clause {} opt_procedure_or_into {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelect_2, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSelect_3, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kSelect, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


select_into:

    select_into_query_specification {} opt_order_limit_lock {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectInto_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSelectInto, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | with_clause select_into_query_specification {} opt_order_limit_lock {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectInto_2, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSelectInto_3, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kSelectInto, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


simple_table:

    query_specification {
        auto tmp1 = $1;
        res = new IR(kSimpleTable, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_value_constructor {
        auto tmp1 = $1;
        res = new IR(kSimpleTable, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


table_value_constructor:

    VALUES {} values_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTableValueConstructor, OP3("VALUES", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


query_specification_start:

    SELECT_SYM {} select_options {} select_item_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kQuerySpecificationStart_1, OP3("SELECT_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kQuerySpecificationStart_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kQuerySpecificationStart, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


query_specification:

    query_specification_start opt_from_clause opt_where_clause opt_group_clause opt_having_clause opt_window_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kQuerySpecification_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kQuerySpecification_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kQuerySpecification_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kQuerySpecification_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $6;
        res = new IR(kQuerySpecification, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

;


select_into_query_specification:

    query_specification_start into opt_from_clause opt_where_clause opt_group_clause opt_having_clause opt_window_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectIntoQuerySpecification_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSelectIntoQuerySpecification_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kSelectIntoQuerySpecification_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kSelectIntoQuerySpecification_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $6;
        res = new IR(kSelectIntoQuerySpecification_5, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $7;
        res = new IR(kSelectIntoQuerySpecification, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

;






query_expression:

    query_expression_no_with_clause {
        auto tmp1 = $1;
        res = new IR(kQueryExpression, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | with_clause query_expression_no_with_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kQueryExpression, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;




query_expression_no_with_clause:

    query_expression_body_ext {
        auto tmp1 = $1;
        res = new IR(kQueryExpressionNoWithClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | query_expression_body_ext_parens {
        auto tmp1 = $1;
        res = new IR(kQueryExpressionNoWithClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;




query_expression_body_ext:

    query_expression_body {} opt_query_expression_tail {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kQueryExpressionBodyExt_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kQueryExpressionBodyExt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | query_expression_body_ext_parens {} query_expression_tail {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kQueryExpressionBodyExt_2, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kQueryExpressionBodyExt, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


query_expression_body_ext_parens:

    '(' query_expression_body_ext_parens ')' {
        auto tmp1 = $2;
        res = new IR(kQueryExpressionBodyExtParens, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | '(' query_expression_body_ext ')' {
        auto tmp1 = $2;
        res = new IR(kQueryExpressionBodyExtParens, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;




query_expression_body:

    query_simple {
        auto tmp1 = $1;
        res = new IR(kQueryExpressionBody, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | query_expression_body unit_type_decl {} query_primary {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kQueryExpressionBody_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kQueryExpressionBody_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kQueryExpressionBody, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | query_expression_body_ext_parens unit_type_decl query_primary {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kQueryExpressionBody_3, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kQueryExpressionBody, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;




query_primary:

    query_simple {
        auto tmp1 = $1;
        res = new IR(kQueryPrimary, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | query_expression_body_ext_parens {
        auto tmp1 = $1;
        res = new IR(kQueryPrimary, OP3("", "", ""), tmp1);
        $$ = res;
    }

;




query_simple:

    simple_table {
        auto tmp1 = $1;
        res = new IR(kQuerySimple, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


subselect:

    query_expression {
        auto tmp1 = $1;
        res = new IR(kSubselect, OP3("", "", ""), tmp1);
        $$ = res;
    }

;




subquery:

    query_expression_body_ext_parens %prec SUBQUERY_AS_EXPR {
        auto tmp1 = $1;
        res = new IR(kSubquery, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' with_clause query_expression_no_with_clause ')' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSubquery, OP3("(", "", ")"), tmp1, tmp2);
        $$ = res;
    }

;


opt_from_clause:

    prec EMPTY_FROM_CLAUSE {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptFromClause, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | from_clause {
        auto tmp1 = $1;
        res = new IR(kOptFromClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


from_clause:

    FROM table_reference_list {
        auto tmp1 = $2;
        res = new IR(kFromClause, OP3("FROM", "", ""), tmp1);
        $$ = res;
    }

;


table_reference_list:

    join_table_list {
        auto tmp1 = $1;
        res = new IR(kTableReferenceList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DUAL_SYM {
        res = new IR(kTableReferenceList, OP3("DUAL_SYM", "", ""));
        $$ = res;
    }

;


select_options:

    select_option_list {
        auto tmp1 = $1;
        res = new IR(kSelectOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | select_option_list {
        auto tmp1 = $1;
        res = new IR(kSelectOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_history_unit:

    prec PREC_BELOW_IDENTIFIER_OPT_SPECIAL_CASE {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptHistoryUnit, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | TRANSACTION_SYM {
        res = new IR(kOptHistoryUnit, OP3("TRANSACTION_SYM", "", ""));
        $$ = res;
    }

    | TIMESTAMP {
        res = new IR(kOptHistoryUnit, OP3("TIMESTAMP", "", ""));
        $$ = res;
    }

;


history_point:

    TIMESTAMP TEXT_STRING {
        auto tmp1 = $2;
        res = new IR(kHistoryPoint, OP3("TIMESTAMP", "", ""), tmp1);
        $$ = res;
    }

    | function_call_keyword_timestamp {
        auto tmp1 = $1;
        res = new IR(kHistoryPoint, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | opt_history_unit bit_expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kHistoryPoint, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


for_portion_of_time_clause:

    FOR_SYM PORTION_SYM OF_SYM remember_tok_start ident FROM bit_expr TO_SYM bit_expr {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kForPortionOfTimeClause_1, OP3("FOR_SYM PORTION_SYM OF_SYM", "", "FROM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kForPortionOfTimeClause_2, OP3("", "", "TO_SYM"), res, tmp3);
        PUSH(res);
        auto tmp4 = $9;
        res = new IR(kForPortionOfTimeClause, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


opt_for_portion_of_time_clause:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptForPortionOfTimeClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | for_portion_of_time_clause {
        auto tmp1 = $1;
        res = new IR(kOptForPortionOfTimeClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_for_system_time_clause:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptForSystemTimeClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FOR_SYSTEM_TIME_SYM system_time_expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptForSystemTimeClause, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


system_time_expr:

    AS OF_SYM history_point {
        auto tmp1 = $3;
        res = new IR(kSystemTimeExpr, OP3("AS OF_SYM", "", ""), tmp1);
        $$ = res;
    }

    | ALL {
        res = new IR(kSystemTimeExpr, OP3("ALL", "", ""));
        $$ = res;
    }

    | FROM history_point TO_SYM history_point {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kSystemTimeExpr, OP3("FROM", "TO_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | BETWEEN_SYM history_point AND_SYM history_point {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kSystemTimeExpr, OP3("BETWEEN_SYM", "AND_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

;


select_option_list:

    select_option_list select_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectOptionList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | select_option {
        auto tmp1 = $1;
        res = new IR(kSelectOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


select_option:

    query_expression_option {
        auto tmp1 = $1;
        res = new IR(kSelectOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SQL_NO_CACHE_SYM {
        res = new IR(kSelectOption, OP3("SQL_NO_CACHE_SYM", "", ""));
        $$ = res;
    }

    | SQL_CACHE_SYM {
        res = new IR(kSelectOption, OP3("SQL_CACHE_SYM", "", ""));
        $$ = res;
    }

;



select_lock_type:

    FOR_SYM UPDATE_SYM opt_lock_wait_timeout_new {
        auto tmp1 = $3;
        res = new IR(kSelectLockType, OP3("FOR_SYM UPDATE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | LOCK_SYM IN_SYM SHARE_SYM MODE_SYM opt_lock_wait_timeout_new {
        auto tmp1 = $5;
        res = new IR(kSelectLockType, OP3("LOCK_SYM IN_SYM SHARE_SYM MODE_SYM", "", ""), tmp1);
        $$ = res;
    }

;



opt_select_lock_type:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptSelectLockType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | select_lock_type {
        auto tmp1 = $1;
        res = new IR(kOptSelectLockType, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_lock_wait_timeout_new:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptLockWaitTimeoutNew, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | WAIT_SYM ulong_num {
        auto tmp1 = $2;
        res = new IR(kOptLockWaitTimeoutNew, OP3("WAIT_SYM", "", ""), tmp1);
        $$ = res;
    }

    | NOWAIT_SYM {
        res = new IR(kOptLockWaitTimeoutNew, OP3("NOWAIT_SYM", "", ""));
        $$ = res;
    }

    | SKIP_SYM LOCKED_SYM {
        res = new IR(kOptLockWaitTimeoutNew, OP3("SKIP_SYM LOCKED_SYM", "", ""));
        $$ = res;
    }

;


select_item_list:

    select_item_list ',' select_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSelectItemList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | select_item {
        auto tmp1 = $1;
        res = new IR(kSelectItemList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '*' {
        auto tmp1 = $1;
        res = new IR(kSelectItemList, OP3("*", "", ""), tmp1);
        $$ = res;
    }

;


select_item:

    remember_name select_sublist_qualified_asterisk remember_end {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectItem_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSelectItem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | remember_name expr remember_end select_alias {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectItem_2, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSelectItem_3, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kSelectItem, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


remember_tok_start:

    remember_tok_start: {
        auto tmp1 = $1;
        res = new IR(kRememberTokStart, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


remember_name:

    remember_name: {
        auto tmp1 = $1;
        res = new IR(kRememberName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


remember_end:

    remember_end: {
        auto tmp1 = $1;
        res = new IR(kRememberEnd, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


select_alias:

    {} {
        auto tmp1 = $1;
        res = new IR(kSelectAlias, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AS ident {
        auto tmp1 = $2;
        res = new IR(kSelectAlias, OP3("AS", "", ""), tmp1);
        $$ = res;
    }

    | AS TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kSelectAlias, OP3("AS", "", ""), tmp1);
        $$ = res;
    }

    | ident {
        auto tmp1 = $1;
        res = new IR(kSelectAlias, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TEXT_STRING_sys {
        auto tmp1 = $1;
        res = new IR(kSelectAlias, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_default_time_precision:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptDefaultTimePrecision, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' ')' {
        auto tmp1 = $2;
        res = new IR(kOptDefaultTimePrecision, OP3("( )", "", ""), tmp1);
        $$ = res;
    }

    | '(' real_ulong_num ')' {
        auto tmp1 = $2;
        res = new IR(kOptDefaultTimePrecision, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


opt_time_precision:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptTimePrecision, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' ')' {
        auto tmp1 = $2;
        res = new IR(kOptTimePrecision, OP3("( )", "", ""), tmp1);
        $$ = res;
    }

    | '(' real_ulong_num ')' {
        auto tmp1 = $2;
        res = new IR(kOptTimePrecision, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


optional_braces:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptionalBraces, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' ')'{}} {
        auto tmp1 = $2;
        res = new IR(kOptionalBraces, OP3("( ')'{}}", "", ""), tmp1);
        $$ = res;
    }

;



expr:

    expr or expr %prec OR_SYM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kExpr_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | expr XOR expr %prec XOR {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExpr, OP3("", "XOR", ""), tmp1, tmp2);
        $$ = res;
    }

    | expr and expr %prec AND_SYM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kExpr_2, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | NOT_SYM expr %prec NOT_SYM {
        auto tmp1 = $2;
        res = new IR(kExpr, OP3("NOT_SYM", "", ""), tmp1);
        $$ = res;
    }

    | expr IS TRUE_SYM %prec IS {
        auto tmp1 = $1;
        res = new IR(kExpr, OP3("", "IS TRUE_SYM", ""), tmp1);
        $$ = res;
    }

    | expr IS not TRUE_SYM %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExpr, OP3("", "IS", "TRUE_SYM"), tmp1, tmp2);
        $$ = res;
    }

    | expr IS FALSE_SYM %prec IS {
        auto tmp1 = $1;
        res = new IR(kExpr, OP3("", "IS FALSE_SYM", ""), tmp1);
        $$ = res;
    }

    | expr IS not FALSE_SYM %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExpr, OP3("", "IS", "FALSE_SYM"), tmp1, tmp2);
        $$ = res;
    }

    | expr IS UNKNOWN_SYM %prec IS {
        auto tmp1 = $1;
        res = new IR(kExpr, OP3("", "IS UNKNOWN_SYM", ""), tmp1);
        $$ = res;
    }

    | expr IS not UNKNOWN_SYM %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExpr, OP3("", "IS", "UNKNOWN_SYM"), tmp1, tmp2);
        $$ = res;
    }

    | expr IS NULL_SYM %prec PREC_BELOW_NOT {
        auto tmp1 = $1;
        res = new IR(kExpr, OP3("", "IS NULL_SYM", ""), tmp1);
        $$ = res;
    }

    | expr IS not NULL_SYM %prec IS {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExpr, OP3("", "IS", "NULL_SYM"), tmp1, tmp2);
        $$ = res;
    }

    | expr EQUAL_SYM predicate %prec EQUAL_SYM {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExpr, OP3("", "EQUAL_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | expr comp_op predicate %prec '=' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kExpr_3, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | expr comp_op all_or_any '(' subselect ')' %prec '=' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kExpr_4, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kExpr_5, OP3("", "", "("), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kExpr, OP3("", "", ")"), res, tmp4);
        $$ = res;
    }

    | predicate {
        auto tmp1 = $1;
        res = new IR(kExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


predicate:

    predicate IN_SYM subquery {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPredicate, OP3("", "IN_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | predicate not IN_SYM subquery {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPredicate_1, OP3("", "", "IN_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kPredicate, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | predicate IN_SYM '(' expr ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kPredicate, OP3("", "IN_SYM (", ")"), tmp1, tmp2);
        $$ = res;
    }

    | predicate IN_SYM '(' expr ',' expr_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kPredicate_2, OP3("", "IN_SYM (", ","), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kPredicate, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | predicate not IN_SYM '(' expr ')' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPredicate_3, OP3("", "", "IN_SYM ("), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kPredicate, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | predicate not IN_SYM '(' expr ',' expr_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPredicate_4, OP3("", "", "IN_SYM ("), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kPredicate_5, OP3("", "", ","), res, tmp3);
        PUSH(res);
        auto tmp4 = $7;
        res = new IR(kPredicate, OP3("", "", ")"), res, tmp4);
        $$ = res;
    }

    | predicate BETWEEN_SYM predicate AND_SYM predicate %prec BETWEEN_SYM {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPredicate_6, OP3("", "BETWEEN_SYM", "AND_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kPredicate, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | predicate not BETWEEN_SYM predicate AND_SYM predicate %prec BETWEEN_SYM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPredicate_7, OP3("", "", "BETWEEN_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kPredicate_8, OP3("", "", "AND_SYM"), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kPredicate, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | predicate SOUNDS_SYM LIKE predicate {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kPredicate, OP3("", "SOUNDS_SYM LIKE", ""), tmp1, tmp2);
        $$ = res;
    }

    | predicate LIKE predicate {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPredicate, OP3("", "LIKE", ""), tmp1, tmp2);
        $$ = res;
    }

    | predicate LIKE predicate ESCAPE_SYM predicate %prec LIKE {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPredicate_9, OP3("", "LIKE", "ESCAPE_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kPredicate, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | predicate not LIKE predicate {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPredicate_10, OP3("", "", "LIKE"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kPredicate, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | predicate not LIKE predicate ESCAPE_SYM predicate %prec LIKE {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPredicate_11, OP3("", "", "LIKE"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kPredicate_12, OP3("", "", "ESCAPE_SYM"), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kPredicate, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | predicate REGEXP predicate {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kPredicate, OP3("", "REGEXP", ""), tmp1, tmp2);
        $$ = res;
    }

    | predicate not REGEXP predicate {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPredicate_13, OP3("", "", "REGEXP"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kPredicate, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | bit_expr %prec PREC_BELOW_NOT {
        auto tmp1 = $1;
        res = new IR(kPredicate, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


bit_expr:

    bit_expr '|' bit_expr %prec '|' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "|", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr '&' bit_expr %prec '&' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "&", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr SHIFT_LEFT bit_expr %prec SHIFT_LEFT {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "SHIFT_LEFT", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr SHIFT_RIGHT bit_expr %prec SHIFT_RIGHT {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "SHIFT_RIGHT", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr ORACLE_CONCAT_SYM bit_expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kBitExpr_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kBitExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | bit_expr '+' bit_expr %prec '+' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "+", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr '-' bit_expr %prec '-' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "-", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr '+' INTERVAL_SYM expr interval %prec '+' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kBitExpr_2, OP3("", "+ INTERVAL_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kBitExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | bit_expr '-' INTERVAL_SYM expr interval %prec '-' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kBitExpr_3, OP3("", "- INTERVAL_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kBitExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | INTERVAL_SYM expr interval '+' expr {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kBitExpr_4, OP3("INTERVAL_SYM", "", "+"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kBitExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | '+' INTERVAL_SYM expr interval '+' expr %prec NEG {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kBitExpr_5, OP3("+ INTERVAL_SYM", "", "+"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kBitExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | '-' INTERVAL_SYM expr interval '+' expr %prec NEG {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kBitExpr_6, OP3("- INTERVAL_SYM", "", "+"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kBitExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | bit_expr '*' bit_expr %prec '*' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "*", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr '/' bit_expr %prec '/' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "/", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr '%' bit_expr %prec '%' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "%", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr DIV_SYM bit_expr %prec DIV_SYM {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "DIV_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr MOD_SYM bit_expr %prec MOD_SYM {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "MOD_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | bit_expr '^' bit_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kBitExpr, OP3("", "^", ""), tmp1, tmp2);
        $$ = res;
    }

    | mysql_concatenation_expr %prec '^' {
        auto tmp1 = $1;
        res = new IR(kBitExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


or:

    OR_SYM {
        res = new IR(kOr, OP3("OR_SYM", "", ""));
        $$ = res;
    }

    | OR2_SYM {
        res = new IR(kOr, OP3("OR2_SYM", "", ""));
        $$ = res;
    }

;


and:

    AND_SYM {
        res = new IR(kAnd, OP3("AND_SYM", "", ""));
        $$ = res;
    }

    | AND_AND_SYM {
        res = new IR(kAnd, OP3("AND_AND_SYM", "", ""));
        $$ = res;
    }

;


not:

    NOT_SYM {
        res = new IR(kNot, OP3("NOT_SYM", "", ""));
        $$ = res;
    }

    | NOT2_SYM {
        auto tmp1 = $1;
        res = new IR(kNot, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


not2:

    '!' {
        auto tmp1 = $1;
        res = new IR(kNot2, OP3("!", "", ""), tmp1);
        $$ = res;
    }

    | NOT2_SYM {
        auto tmp1 = $1;
        res = new IR(kNot2, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


comp_op:

    '=' {
        auto tmp1 = $1;
        res = new IR(kCompOp, OP3("=", "", ""), tmp1);
        $$ = res;
    }

    | GE {
        res = new IR(kCompOp, OP3("GE", "", ""));
        $$ = res;
    }

    | '>' {
        auto tmp1 = $1;
        res = new IR(kCompOp, OP3(">", "", ""), tmp1);
        $$ = res;
    }

    | LE {
        res = new IR(kCompOp, OP3("LE", "", ""));
        $$ = res;
    }

    | '<' {
        auto tmp1 = $1;
        res = new IR(kCompOp, OP3("<", "", ""), tmp1);
        $$ = res;
    }

    | NE {
        res = new IR(kCompOp, OP3("NE", "", ""));
        $$ = res;
    }

;


all_or_any:

    ALL {
        res = new IR(kAllOrAny, OP3("ALL", "", ""));
        $$ = res;
    }

    | ANY_SYM {
        res = new IR(kAllOrAny, OP3("ANY_SYM", "", ""));
        $$ = res;
    }

;


opt_dyncol_type:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptDyncolType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AS dyncol_type {
        auto tmp1 = $2;
        res = new IR(kOptDyncolType, OP3("AS", "", ""), tmp1);
        $$ = res;
    }

;


dyncol_type:

    numeric_dyncol_type {
        auto tmp1 = $1;
        res = new IR(kDyncolType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | temporal_dyncol_type {
        auto tmp1 = $1;
        res = new IR(kDyncolType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | string_dyncol_type {
        auto tmp1 = $1;
        res = new IR(kDyncolType, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


numeric_dyncol_type:

    INT_SYM {
        res = new IR(kNumericDyncolType, OP3("INT_SYM", "", ""));
        $$ = res;
    }

    | UNSIGNED INT_SYM {
        res = new IR(kNumericDyncolType, OP3("UNSIGNED INT_SYM", "", ""));
        $$ = res;
    }

    | DOUBLE_SYM {
        res = new IR(kNumericDyncolType, OP3("DOUBLE_SYM", "", ""));
        $$ = res;
    }

    | REAL {
        res = new IR(kNumericDyncolType, OP3("REAL", "", ""));
        $$ = res;
    }

    | FLOAT_SYM {
        res = new IR(kNumericDyncolType, OP3("FLOAT_SYM", "", ""));
        $$ = res;
    }

    | DECIMAL_SYM float_options {
        auto tmp1 = $2;
        res = new IR(kNumericDyncolType, OP3("DECIMAL_SYM", "", ""), tmp1);
        $$ = res;
    }

;


temporal_dyncol_type:

    DATE_SYM {
        res = new IR(kTemporalDyncolType, OP3("DATE_SYM", "", ""));
        $$ = res;
    }

    | TIME_SYM opt_field_scale {
        auto tmp1 = $2;
        res = new IR(kTemporalDyncolType, OP3("TIME_SYM", "", ""), tmp1);
        $$ = res;
    }

    | DATETIME opt_field_scale {
        auto tmp1 = $2;
        res = new IR(kTemporalDyncolType, OP3("DATETIME", "", ""), tmp1);
        $$ = res;
    }

;


string_dyncol_type:

    char opt_binary {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kStringDyncolType, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | nchar {
        auto tmp1 = $1;
        res = new IR(kStringDyncolType, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


dyncall_create_element:

    expr ',' expr opt_dyncol_type {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDyncallCreateElement_1, OP3("", ",", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kDyncallCreateElement, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


dyncall_create_list:

    dyncall_create_element {
        auto tmp1 = $1;
        res = new IR(kDyncallCreateList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | dyncall_create_list ',' dyncall_create_element {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDyncallCreateList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;



plsql_cursor_attr:

    ISOPEN_SYM {
        res = new IR(kPlsqlCursorAttr, OP3("ISOPEN_SYM", "", ""));
        $$ = res;
    }

    | FOUND_SYM {
        res = new IR(kPlsqlCursorAttr, OP3("FOUND_SYM", "", ""));
        $$ = res;
    }

    | NOTFOUND_SYM {
        res = new IR(kPlsqlCursorAttr, OP3("NOTFOUND_SYM", "", ""));
        $$ = res;
    }

    | ROWCOUNT_SYM {
        res = new IR(kPlsqlCursorAttr, OP3("ROWCOUNT_SYM", "", ""));
        $$ = res;
    }

;


explicit_cursor_attr:

    ident PERCENT_ORACLE_SYM plsql_cursor_attr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kExplicitCursorAttr_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kExplicitCursorAttr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;



trim_operands:

    expr {
        auto tmp1 = $1;
        res = new IR(kTrimOperands, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LEADING expr FROM expr {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kTrimOperands, OP3("LEADING", "FROM", ""), tmp1, tmp2);
        $$ = res;
    }

    | TRAILING expr FROM expr {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kTrimOperands, OP3("TRAILING", "FROM", ""), tmp1, tmp2);
        $$ = res;
    }

    | BOTH expr FROM expr {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kTrimOperands, OP3("BOTH", "FROM", ""), tmp1, tmp2);
        $$ = res;
    }

    | LEADING FROM expr {
        auto tmp1 = $3;
        res = new IR(kTrimOperands, OP3("LEADING FROM", "", ""), tmp1);
        $$ = res;
    }

    | TRAILING FROM expr {
        auto tmp1 = $3;
        res = new IR(kTrimOperands, OP3("TRAILING FROM", "", ""), tmp1);
        $$ = res;
    }

    | BOTH FROM expr {
        auto tmp1 = $3;
        res = new IR(kTrimOperands, OP3("BOTH FROM", "", ""), tmp1);
        $$ = res;
    }

    | expr FROM expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTrimOperands, OP3("", "FROM", ""), tmp1, tmp2);
        $$ = res;
    }

;



column_default_non_parenthesized_expr:

    simple_ident {
        auto tmp1 = $1;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | function_call_keyword {
        auto tmp1 = $1;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | function_call_nonkeyword {
        auto tmp1 = $1;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | function_call_generic {
        auto tmp1 = $1;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | function_call_conflict {
        auto tmp1 = $1;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | literal {
        auto tmp1 = $1;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | param_marker {
        auto tmp1 = $1;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | variable {
        auto tmp1 = $1;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sum_expr {
        auto tmp1 = $1;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | window_func_expr {
        auto tmp1 = $1;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | inverse_distribution_function {
        auto tmp1 = $1;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ROW_SYM '(' expr ',' expr_list ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("ROW_SYM (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | EXISTS '(' subselect ')' {
        auto tmp1 = $3;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("EXISTS (", ")", ""), tmp1);
        $$ = res;
    }

    | '{' ident expr '}' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("{", "", "}"), tmp1, tmp2);
        $$ = res;
    }

    | MATCH ident_list_arg AGAINST '(' bit_expr fulltext_options ')' {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kColumnDefaultNonParenthesizedExpr_1, OP3("MATCH", "AGAINST (", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | CAST_SYM '(' expr AS cast_type ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("CAST_SYM (", "AS", ")"), tmp1, tmp2);
        $$ = res;
    }

    | CASE_SYM when_list_opt_else END {
        auto tmp1 = $2;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("CASE_SYM", "END", ""), tmp1);
        $$ = res;
    }

    | CASE_SYM expr when_list_opt_else END {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("CASE_SYM", "", "END"), tmp1, tmp2);
        $$ = res;
    }

    | CONVERT_SYM '(' expr ',' cast_type ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("CONVERT_SYM (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | CONVERT_SYM '(' expr USING charset_name ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("CONVERT_SYM (", "USING", ")"), tmp1, tmp2);
        $$ = res;
    }

    | DEFAULT '(' simple_ident ')' {
        auto tmp1 = $3;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("DEFAULT (", ")", ""), tmp1);
        $$ = res;
    }

    | VALUE_SYM '(' simple_ident_nospvar ')' {
        auto tmp1 = $3;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("VALUE_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | NEXT_SYM VALUE_SYM FOR_SYM table_ident {
        auto tmp1 = $4;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("NEXT_SYM VALUE_SYM FOR_SYM", "", ""), tmp1);
        $$ = res;
    }

    | NEXTVAL_SYM '(' table_ident ')' {
        auto tmp1 = $3;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("NEXTVAL_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | PREVIOUS_SYM VALUE_SYM FOR_SYM table_ident {
        auto tmp1 = $4;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("PREVIOUS_SYM VALUE_SYM FOR_SYM", "", ""), tmp1);
        $$ = res;
    }

    | LASTVAL_SYM '(' table_ident ')' {
        auto tmp1 = $3;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("LASTVAL_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | SETVAL_SYM '(' table_ident ',' longlong_num ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("SETVAL_SYM (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | SETVAL_SYM '(' table_ident ',' longlong_num ',' bool ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kColumnDefaultNonParenthesizedExpr_2, OP3("SETVAL_SYM (", ",", ","), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | SETVAL_SYM '(' table_ident ',' longlong_num ',' bool ',' ulonglong_num ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kColumnDefaultNonParenthesizedExpr_3, OP3("SETVAL_SYM (", ",", ","), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kColumnDefaultNonParenthesizedExpr_4, OP3("", "", ","), res, tmp3);
        PUSH(res);
        auto tmp4 = $9;
        res = new IR(kColumnDefaultNonParenthesizedExpr, OP3("", "", ")"), res, tmp4);
        $$ = res;
    }

;


primary_expr:

    column_default_non_parenthesized_expr {
        auto tmp1 = $1;
        res = new IR(kPrimaryExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | explicit_cursor_attr {
        auto tmp1 = $1;
        res = new IR(kPrimaryExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' parenthesized_expr ')' {
        auto tmp1 = $2;
        res = new IR(kPrimaryExpr, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | subquery {
        auto tmp1 = $1;
        res = new IR(kPrimaryExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


string_factor_expr:

    primary_expr {
        auto tmp1 = $1;
        res = new IR(kStringFactorExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | string_factor_expr COLLATE_SYM collation_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kStringFactorExpr, OP3("", "COLLATE_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

;


simple_expr:

    string_factor_expr %prec NEG {
        auto tmp1 = $1;
        res = new IR(kSimpleExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | BINARY simple_expr {
        auto tmp1 = $2;
        res = new IR(kSimpleExpr, OP3("BINARY", "", ""), tmp1);
        $$ = res;
    }

    | '+' simple_expr %prec NEG {
        auto tmp1 = $2;
        res = new IR(kSimpleExpr, OP3("+", "", ""), tmp1);
        $$ = res;
    }

    | '-' simple_expr %prec NEG {
        auto tmp1 = $2;
        res = new IR(kSimpleExpr, OP3("-", "", ""), tmp1);
        $$ = res;
    }

    | '~' simple_expr %prec NEG {
        auto tmp1 = $2;
        res = new IR(kSimpleExpr, OP3("~", "", ""), tmp1);
        $$ = res;
    }

    | not2 simple_expr %prec NEG {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleExpr, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


mysql_concatenation_expr:

    simple_expr {
        auto tmp1 = $1;
        res = new IR(kMysqlConcatenationExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | mysql_concatenation_expr MYSQL_CONCAT_SYM simple_expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kMysqlConcatenationExpr_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kMysqlConcatenationExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


function_call_keyword_timestamp:

    TIMESTAMP '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeywordTimestamp, OP3("TIMESTAMP (", ")", ""), tmp1);
        $$ = res;
    }

    | TIMESTAMP '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallKeywordTimestamp, OP3("TIMESTAMP (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

;


function_call_keyword:

    CHAR_SYM '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("CHAR_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | CHAR_SYM '(' expr_list USING charset_name ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallKeyword, OP3("CHAR_SYM (", "USING", ")"), tmp1, tmp2);
        $$ = res;
    }

    | CURRENT_USER optional_braces {
        auto tmp1 = $2;
        res = new IR(kFunctionCallKeyword, OP3("CURRENT_USER", "", ""), tmp1);
        $$ = res;
    }

    | CURRENT_ROLE optional_braces {
        auto tmp1 = $2;
        res = new IR(kFunctionCallKeyword, OP3("CURRENT_ROLE", "", ""), tmp1);
        $$ = res;
    }

    | DATE_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("DATE_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | DAY_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("DAY_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | HOUR_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("HOUR_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | INSERT '(' expr ',' expr ',' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallKeyword_1, OP3("INSERT (", ",", ","), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kFunctionCallKeyword_2, OP3("", "", ","), res, tmp3);
        PUSH(res);
        auto tmp4 = $9;
        res = new IR(kFunctionCallKeyword, OP3("", "", ")"), res, tmp4);
        $$ = res;
    }

    | INTERVAL_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallKeyword, OP3("INTERVAL_SYM (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | INTERVAL_SYM '(' expr ',' expr ',' expr_list ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallKeyword_3, OP3("INTERVAL_SYM (", ",", ","), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kFunctionCallKeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | LEFT '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallKeyword, OP3("LEFT (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | MINUTE_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("MINUTE_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | MONTH_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("MONTH_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | RIGHT '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallKeyword, OP3("RIGHT (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | SECOND_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("SECOND_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | SQL_SYM PERCENT_ORACLE_SYM ROWCOUNT_SYM {
        auto tmp1 = $2;
        res = new IR(kFunctionCallKeyword, OP3("SQL_SYM", "ROWCOUNT_SYM", ""), tmp1);
        $$ = res;
    }

    | TIME_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("TIME_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | function_call_keyword_timestamp {
        auto tmp1 = $1;
        res = new IR(kFunctionCallKeyword, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TRIM '(' trim_operands ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("TRIM (", ")", ""), tmp1);
        $$ = res;
    }

    | USER_SYM '(' ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("USER_SYM ( )", "", ""), tmp1);
        $$ = res;
    }

    | YEAR_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallKeyword, OP3("YEAR_SYM (", ")", ""), tmp1);
        $$ = res;
    }

;



function_call_nonkeyword:

    ADD_MONTHS_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword, OP3("ADD_MONTHS_SYM (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | ADDDATE_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword, OP3("ADDDATE_SYM (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | ADDDATE_SYM '(' expr ',' INTERVAL_SYM expr interval ')' {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kFunctionCallNonkeyword_1, OP3("ADDDATE_SYM (", ", INTERVAL_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | CURDATE optional_braces {
        auto tmp1 = $2;
        res = new IR(kFunctionCallNonkeyword, OP3("CURDATE", "", ""), tmp1);
        $$ = res;
    }

    | CURTIME opt_time_precision {
        auto tmp1 = $2;
        res = new IR(kFunctionCallNonkeyword, OP3("CURTIME", "", ""), tmp1);
        $$ = res;
    }

    | DATE_ADD_INTERVAL '(' expr ',' INTERVAL_SYM expr interval ')' {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kFunctionCallNonkeyword_2, OP3("DATE_ADD_INTERVAL (", ", INTERVAL_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | DATE_SUB_INTERVAL '(' expr ',' INTERVAL_SYM expr interval ')' {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kFunctionCallNonkeyword_3, OP3("DATE_SUB_INTERVAL (", ", INTERVAL_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | DATE_FORMAT_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword, OP3("DATE_FORMAT_SYM (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | DATE_FORMAT_SYM '(' expr ',' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword_4, OP3("DATE_FORMAT_SYM (", ",", ","), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | DECODE_MARIADB_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword, OP3("DECODE_MARIADB_SYM (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | DECODE_ORACLE_SYM '(' expr ',' decode_when_list_oracle ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFunctionCallNonkeyword_5, OP3("", "(", ","), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | EXTRACT_SYM '(' interval FROM expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword, OP3("EXTRACT_SYM (", "FROM", ")"), tmp1, tmp2);
        $$ = res;
    }

    | GET_FORMAT '(' date_time_type ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword, OP3("GET_FORMAT (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | NOW_SYM opt_time_precision {
        auto tmp1 = $2;
        res = new IR(kFunctionCallNonkeyword, OP3("NOW_SYM", "", ""), tmp1);
        $$ = res;
    }

    | POSITION_SYM '(' bit_expr IN_SYM expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword, OP3("POSITION_SYM (", "IN_SYM", ")"), tmp1, tmp2);
        $$ = res;
    }

    | ROWNUM_SYM %ifdef MARIADB '(' ')' %else optional_braces %endif ORACLE {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFunctionCallNonkeyword_6, OP3("ROWNUM_SYM", "", "( )"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kFunctionCallNonkeyword_7, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $7;
        res = new IR(kFunctionCallNonkeyword_8, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $8;
        res = new IR(kFunctionCallNonkeyword_9, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $9;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | SUBDATE_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword, OP3("SUBDATE_SYM (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | SUBDATE_SYM '(' expr ',' INTERVAL_SYM expr interval ')' {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kFunctionCallNonkeyword_10, OP3("SUBDATE_SYM (", ", INTERVAL_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | SUBSTRING '(' expr ',' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword_11, OP3("SUBSTRING (", ",", ","), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | SUBSTRING '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword, OP3("SUBSTRING (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | SUBSTRING '(' expr FROM expr FOR_SYM expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword_12, OP3("SUBSTRING (", "FROM", "FOR_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | SUBSTRING '(' expr FROM expr ')' {} %ifdef ORACLE {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword_13, OP3("SUBSTRING (", "FROM", ")"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kFunctionCallNonkeyword_14, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $8;
        res = new IR(kFunctionCallNonkeyword_15, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $9;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | SYSDATE {} %endif {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFunctionCallNonkeyword, OP3("SYSDATE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | SYSDATE '(' ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallNonkeyword, OP3("SYSDATE ( )", "", ""), tmp1);
        $$ = res;
    }

    | SYSDATE '(' real_ulong_num ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallNonkeyword, OP3("SYSDATE (", ")", ""), tmp1);
        $$ = res;
    }

    | TIMESTAMP_ADD '(' interval_time_stamp ',' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword_16, OP3("TIMESTAMP_ADD (", ",", ","), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | TIMESTAMP_DIFF '(' interval_time_stamp ',' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword_17, OP3("TIMESTAMP_DIFF (", ",", ","), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | TRIM_ORACLE '(' trim_operands ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallNonkeyword, OP3("TRIM_ORACLE (", ")", ""), tmp1);
        $$ = res;
    }

    | UTC_DATE_SYM optional_braces {
        auto tmp1 = $2;
        res = new IR(kFunctionCallNonkeyword, OP3("UTC_DATE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | UTC_TIME_SYM opt_time_precision {
        auto tmp1 = $2;
        res = new IR(kFunctionCallNonkeyword, OP3("UTC_TIME_SYM", "", ""), tmp1);
        $$ = res;
    }

    | UTC_TIMESTAMP_SYM opt_time_precision {
        auto tmp1 = $2;
        res = new IR(kFunctionCallNonkeyword, OP3("UTC_TIMESTAMP_SYM", "", ""), tmp1);
        $$ = res;
    }

    | COLUMN_ADD_SYM '(' expr ',' dyncall_create_list ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword, OP3("COLUMN_ADD_SYM (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | COLUMN_DELETE_SYM '(' expr ',' expr_list ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword, OP3("COLUMN_DELETE_SYM (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | COLUMN_CHECK_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallNonkeyword, OP3("COLUMN_CHECK_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | COLUMN_CREATE_SYM '(' dyncall_create_list ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallNonkeyword, OP3("COLUMN_CREATE_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | COLUMN_GET_SYM '(' expr ',' expr AS cast_type ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallNonkeyword_18, OP3("COLUMN_GET_SYM (", ",", "AS"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kFunctionCallNonkeyword, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

;



function_call_conflict:

    ASCII_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("ASCII_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | CHARSET '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("CHARSET (", ")", ""), tmp1);
        $$ = res;
    }

    | COALESCE '(' expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("COALESCE (", ")", ""), tmp1);
        $$ = res;
    }

    | COLLATION_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("COLLATION_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | DATABASE '(' ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("DATABASE ( )", "", ""), tmp1);
        $$ = res;
    }

    | IF_SYM '(' expr ',' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallConflict_1, OP3("IF_SYM (", ",", ","), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kFunctionCallConflict, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | FORMAT_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallConflict, OP3("FORMAT_SYM (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | FORMAT_SYM '(' expr ',' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallConflict_2, OP3("FORMAT_SYM (", ",", ","), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kFunctionCallConflict, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | LAST_VALUE '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("LAST_VALUE (", ")", ""), tmp1);
        $$ = res;
    }

    | LAST_VALUE '(' expr_list ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallConflict, OP3("LAST_VALUE (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | MICROSECOND_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("MICROSECOND_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | MOD_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallConflict, OP3("MOD_SYM (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | OLD_PASSWORD_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("OLD_PASSWORD_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | PASSWORD_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("PASSWORD_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | QUARTER_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("QUARTER_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | REPEAT_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallConflict, OP3("REPEAT_SYM (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | REPLACE '(' expr ',' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallConflict_3, OP3("REPLACE (", ",", ","), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kFunctionCallConflict, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | REVERSE_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("REVERSE_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | ROW_COUNT_SYM '(' ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("ROW_COUNT_SYM ( )", "", ""), tmp1);
        $$ = res;
    }

    | TRUNCATE_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallConflict, OP3("TRUNCATE_SYM (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | WEEK_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallConflict, OP3("WEEK_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | WEEK_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallConflict, OP3("WEEK_SYM (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | WEIGHT_STRING_SYM '(' expr opt_ws_levels ')' {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kFunctionCallConflict, OP3("WEIGHT_STRING_SYM (", "", ")"), tmp1, tmp2);
        $$ = res;
    }

    | WEIGHT_STRING_SYM '(' expr AS CHAR_SYM ws_nweights opt_ws_levels ')' {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kFunctionCallConflict_4, OP3("WEIGHT_STRING_SYM (", "AS CHAR_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kFunctionCallConflict, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | WEIGHT_STRING_SYM '(' expr AS BINARY ws_nweights ')' {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kFunctionCallConflict, OP3("WEIGHT_STRING_SYM (", "AS BINARY", ")"), tmp1, tmp2);
        $$ = res;
    }

    | WEIGHT_STRING_SYM '(' expr ',' ulong_num ',' ulong_num ',' ulong_num ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kFunctionCallConflict_5, OP3("WEIGHT_STRING_SYM (", ",", ","), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kFunctionCallConflict_6, OP3("", "", ","), res, tmp3);
        PUSH(res);
        auto tmp4 = $9;
        res = new IR(kFunctionCallConflict, OP3("", "", ")"), res, tmp4);
        $$ = res;
    }

;



function_call_generic:

    IDENT_sys '(' {} opt_udf_expr_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFunctionCallGeneric_1, OP3("", "(", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kFunctionCallGeneric, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | CONTAINS_SYM '(' opt_expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallGeneric, OP3("CONTAINS_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | OVERLAPS_SYM '(' opt_expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallGeneric, OP3("OVERLAPS_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | WITHIN '(' opt_expr_list ')' {
        auto tmp1 = $3;
        res = new IR(kFunctionCallGeneric, OP3("WITHIN (", ")", ""), tmp1);
        $$ = res;
    }

    | ident_cli '.' ident_cli '(' opt_expr_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFunctionCallGeneric_2, OP3("", ".", "("), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kFunctionCallGeneric, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | ident_cli '.' ident_cli '.' ident_cli '(' opt_expr_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFunctionCallGeneric_3, OP3("", ".", "."), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kFunctionCallGeneric_4, OP3("", "", "("), res, tmp3);
        PUSH(res);
        auto tmp4 = $7;
        res = new IR(kFunctionCallGeneric, OP3("", "", ")"), res, tmp4);
        $$ = res;
    }

;


fulltext_options:

    opt_natural_language_mode opt_query_expansion {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFulltextOptions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | IN_SYM BOOLEAN_SYM MODE_SYM {
        res = new IR(kFulltextOptions, OP3("IN_SYM BOOLEAN_SYM MODE_SYM", "", ""));
        $$ = res;
    }

;


opt_natural_language_mode:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptNaturalLanguageMode, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IN_SYM NATURAL LANGUAGE_SYM MODE_SYM {
        res = new IR(kOptNaturalLanguageMode, OP3("IN_SYM NATURAL LANGUAGE_SYM MODE_SYM", "", ""));
        $$ = res;
    }

;


opt_query_expansion:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptQueryExpansion, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | WITH QUERY_SYM EXPANSION_SYM {
        res = new IR(kOptQueryExpansion, OP3("WITH QUERY_SYM EXPANSION_SYM", "", ""));
        $$ = res;
    }

;


opt_udf_expr_list:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptUdfExprList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | udf_expr_list {
        auto tmp1 = $1;
        res = new IR(kOptUdfExprList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


udf_expr_list:

    udf_expr {
        auto tmp1 = $1;
        res = new IR(kUdfExprList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | udf_expr_list ',' udf_expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUdfExprList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


udf_expr:

    remember_name expr remember_end select_alias {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUdfExpr_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kUdfExpr_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kUdfExpr, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


sum_expr:

    AVG_SYM '(' in_sum_expr ')' {
        auto tmp1 = $3;
        res = new IR(kSumExpr, OP3("AVG_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | AVG_SYM '(' DISTINCT in_sum_expr ')' {
        auto tmp1 = $4;
        res = new IR(kSumExpr, OP3("AVG_SYM ( DISTINCT", ")", ""), tmp1);
        $$ = res;
    }

    | BIT_AND '(' in_sum_expr ')' {
        auto tmp1 = $3;
        res = new IR(kSumExpr, OP3("BIT_AND (", ")", ""), tmp1);
        $$ = res;
    }

    | BIT_OR '(' in_sum_expr ')' {
        auto tmp1 = $3;
        res = new IR(kSumExpr, OP3("BIT_OR (", ")", ""), tmp1);
        $$ = res;
    }

    | BIT_XOR '(' in_sum_expr ')' {
        auto tmp1 = $3;
        res = new IR(kSumExpr, OP3("BIT_XOR (", ")", ""), tmp1);
        $$ = res;
    }

    | COUNT_SYM '(' opt_all '*' ')' {
        auto tmp1 = $3;
        res = new IR(kSumExpr, OP3("COUNT_SYM (", "* )", ""), tmp1);
        $$ = res;
    }

    | COUNT_SYM '(' in_sum_expr ')' {
        auto tmp1 = $3;
        res = new IR(kSumExpr, OP3("COUNT_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | COUNT_SYM '(' DISTINCT {} expr_list {} ')' {
        auto tmp1 = $4;
        auto tmp2 = $5;
        res = new IR(kSumExpr_1, OP3("COUNT_SYM ( DISTINCT", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kSumExpr, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | MIN_SYM '(' in_sum_expr ')' {
        auto tmp1 = $3;
        res = new IR(kSumExpr, OP3("MIN_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | MIN_SYM '(' DISTINCT in_sum_expr ')' {
        auto tmp1 = $4;
        res = new IR(kSumExpr, OP3("MIN_SYM ( DISTINCT", ")", ""), tmp1);
        $$ = res;
    }

    | MAX_SYM '(' in_sum_expr ')' {
        auto tmp1 = $3;
        res = new IR(kSumExpr, OP3("MAX_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | MAX_SYM '(' DISTINCT in_sum_expr ')' {
        auto tmp1 = $4;
        res = new IR(kSumExpr, OP3("MAX_SYM ( DISTINCT", ")", ""), tmp1);
        $$ = res;
    }

    | STD_SYM '(' in_sum_expr ')' {
        auto tmp1 = $3;
        res = new IR(kSumExpr, OP3("STD_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | VARIANCE_SYM '(' in_sum_expr ')' {
        auto tmp1 = $3;
        res = new IR(kSumExpr, OP3("VARIANCE_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | STDDEV_SAMP_SYM '(' in_sum_expr ')' {
        auto tmp1 = $3;
        res = new IR(kSumExpr, OP3("STDDEV_SAMP_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | VAR_SAMP_SYM '(' in_sum_expr ')' {
        auto tmp1 = $3;
        res = new IR(kSumExpr, OP3("VAR_SAMP_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | SUM_SYM '(' in_sum_expr ')' {
        auto tmp1 = $3;
        res = new IR(kSumExpr, OP3("SUM_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | SUM_SYM '(' DISTINCT in_sum_expr ')' {
        auto tmp1 = $4;
        res = new IR(kSumExpr, OP3("SUM_SYM ( DISTINCT", ")", ""), tmp1);
        $$ = res;
    }

    | GROUP_CONCAT_SYM '(' opt_distinct {} expr_list opt_gorder_clause opt_gconcat_separator opt_glimit_clause ')' {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kSumExpr_2, OP3("GROUP_CONCAT_SYM (", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kSumExpr_3, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kSumExpr_4, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kSumExpr_5, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $8;
        res = new IR(kSumExpr, OP3("", "", ")"), res, tmp6);
        $$ = res;
    }

    | JSON_ARRAYAGG_SYM '(' opt_distinct {} expr_list opt_gorder_clause opt_glimit_clause ')' {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kSumExpr_6, OP3("JSON_ARRAYAGG_SYM (", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kSumExpr_7, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kSumExpr_8, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kSumExpr, OP3("", "", ")"), res, tmp5);
        $$ = res;
    }

    | JSON_OBJECTAGG_SYM '(' {} expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kSumExpr_9, OP3("JSON_OBJECTAGG_SYM (", "", ","), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kSumExpr, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

;


window_func_expr:

    window_func OVER_SYM window_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kWindowFuncExpr, OP3("", "OVER_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | window_func OVER_SYM window_spec {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kWindowFuncExpr, OP3("", "OVER_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

;


window_func:

    simple_window_func {
        auto tmp1 = $1;
        res = new IR(kWindowFunc, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sum_expr {
        auto tmp1 = $1;
        res = new IR(kWindowFunc, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | function_call_generic {
        auto tmp1 = $1;
        res = new IR(kWindowFunc, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


simple_window_func:

    ROW_NUMBER_SYM '(' ')' {
        auto tmp1 = $3;
        res = new IR(kSimpleWindowFunc, OP3("ROW_NUMBER_SYM ( )", "", ""), tmp1);
        $$ = res;
    }

    | RANK_SYM '(' ')' {
        auto tmp1 = $3;
        res = new IR(kSimpleWindowFunc, OP3("RANK_SYM ( )", "", ""), tmp1);
        $$ = res;
    }

    | DENSE_RANK_SYM '(' ')' {
        auto tmp1 = $3;
        res = new IR(kSimpleWindowFunc, OP3("DENSE_RANK_SYM ( )", "", ""), tmp1);
        $$ = res;
    }

    | PERCENT_RANK_SYM '(' ')' {
        auto tmp1 = $3;
        res = new IR(kSimpleWindowFunc, OP3("PERCENT_RANK_SYM ( )", "", ""), tmp1);
        $$ = res;
    }

    | CUME_DIST_SYM '(' ')' {
        auto tmp1 = $3;
        res = new IR(kSimpleWindowFunc, OP3("CUME_DIST_SYM ( )", "", ""), tmp1);
        $$ = res;
    }

    | NTILE_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kSimpleWindowFunc, OP3("NTILE_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | FIRST_VALUE_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kSimpleWindowFunc, OP3("FIRST_VALUE_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | LAST_VALUE '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kSimpleWindowFunc, OP3("LAST_VALUE (", ")", ""), tmp1);
        $$ = res;
    }

    | NTH_VALUE_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSimpleWindowFunc, OP3("NTH_VALUE_SYM (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | LEAD_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kSimpleWindowFunc, OP3("LEAD_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | LEAD_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSimpleWindowFunc, OP3("LEAD_SYM (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

    | LAG_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kSimpleWindowFunc, OP3("LAG_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | LAG_SYM '(' expr ',' expr ')' {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kSimpleWindowFunc, OP3("LAG_SYM (", ",", ")"), tmp1, tmp2);
        $$ = res;
    }

;




inverse_distribution_function:

    percentile_function OVER_SYM '(' opt_window_partition_clause ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kInverseDistributionFunction, OP3("", "OVER_SYM (", ")"), tmp1, tmp2);
        $$ = res;
    }

;


percentile_function:

    inverse_distribution_function_def WITHIN GROUP_SYM '(' {} order_by_single_element_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kPercentileFunction_1, OP3("", "WITHIN GROUP_SYM (", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kPercentileFunction, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

    | MEDIAN_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kPercentileFunction, OP3("MEDIAN_SYM (", ")", ""), tmp1);
        $$ = res;
    }

;


inverse_distribution_function_def:

    PERCENTILE_CONT_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kInverseDistributionFunctionDef, OP3("PERCENTILE_CONT_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | PERCENTILE_DISC_SYM '(' expr ')' {
        auto tmp1 = $3;
        res = new IR(kInverseDistributionFunctionDef, OP3("PERCENTILE_DISC_SYM (", ")", ""), tmp1);
        $$ = res;
    }

;


order_by_single_element_list:

    ORDER_SYM BY order_ident order_dir {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOrderBySingleElementList, OP3("ORDER_SYM BY", "", ""), tmp1, tmp2);
        $$ = res;
    }

;



window_name:

    ident {
        auto tmp1 = $1;
        res = new IR(kWindowName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


variable:

    '@' {} variable_aux {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kVariable, OP3("@", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


variable_aux:

    ident_or_text SET_VAR expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kVariableAux_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kVariableAux, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ident_or_text {
        auto tmp1 = $1;
        res = new IR(kVariableAux, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '@' opt_var_ident_type ident_sysvar_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kVariableAux, OP3("@", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | '@' opt_var_ident_type ident_sysvar_name '.' ident {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kVariableAux_2, OP3("@", "", "."), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kVariableAux, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_distinct:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptDistinct, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DISTINCT {
        res = new IR(kOptDistinct, OP3("DISTINCT", "", ""));
        $$ = res;
    }

;


opt_gconcat_separator:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptGconcatSeparator, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SEPARATOR_SYM text_string {
        auto tmp1 = $2;
        res = new IR(kOptGconcatSeparator, OP3("SEPARATOR_SYM", "", ""), tmp1);
        $$ = res;
    }

;


opt_gorder_clause:

    ORDER_SYM BY gorder_list {
        auto tmp1 = $3;
        res = new IR(kOptGorderClause, OP3("ORDER_SYM BY", "", ""), tmp1);
        $$ = res;
    }

    | ORDER_SYM BY gorder_list {
        auto tmp1 = $3;
        res = new IR(kOptGorderClause, OP3("ORDER_SYM BY", "", ""), tmp1);
        $$ = res;
    }

;


gorder_list:

    gorder_list ',' order_ident order_dir {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGorderList_1, OP3("", ",", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kGorderList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | order_ident order_dir {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kGorderList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_glimit_clause:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptGlimitClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | glimit_clause {
        auto tmp1 = $1;
        res = new IR(kOptGlimitClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



glimit_clause:

    LIMIT glimit_options {
        auto tmp1 = $2;
        res = new IR(kGlimitClause, OP3("LIMIT", "", ""), tmp1);
        $$ = res;
    }

;


glimit_options:

    limit_options {
        auto tmp1 = $1;
        res = new IR(kGlimitOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;




in_sum_expr:

    opt_all {} expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kInSumExpr_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kInSumExpr, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


cast_type:

    BINARY opt_field_length {
        auto tmp1 = $2;
        res = new IR(kCastType, OP3("BINARY", "", ""), tmp1);
        $$ = res;
    }

    | CHAR_SYM opt_field_length opt_binary {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCastType, OP3("CHAR_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | VARCHAR field_length opt_binary {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCastType, OP3("VARCHAR", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | VARCHAR2_ORACLE_SYM field_length opt_binary {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCastType_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kCastType, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | NCHAR_SYM opt_field_length {
        auto tmp1 = $2;
        res = new IR(kCastType, OP3("NCHAR_SYM", "", ""), tmp1);
        $$ = res;
    }

    | cast_type_numeric {
        auto tmp1 = $1;
        res = new IR(kCastType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | cast_type_temporal {
        auto tmp1 = $1;
        res = new IR(kCastType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IDENT_sys {
        auto tmp1 = $1;
        res = new IR(kCastType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | reserved_keyword_udt {
        auto tmp1 = $1;
        res = new IR(kCastType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | non_reserved_keyword_udt {
        auto tmp1 = $1;
        res = new IR(kCastType, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


cast_type_numeric:

    INT_SYM {
        res = new IR(kCastTypeNumeric, OP3("INT_SYM", "", ""));
        $$ = res;
    }

    | SIGNED_SYM {
        res = new IR(kCastTypeNumeric, OP3("SIGNED_SYM", "", ""));
        $$ = res;
    }

    | SIGNED_SYM INT_SYM {
        res = new IR(kCastTypeNumeric, OP3("SIGNED_SYM INT_SYM", "", ""));
        $$ = res;
    }

    | UNSIGNED {
        res = new IR(kCastTypeNumeric, OP3("UNSIGNED", "", ""));
        $$ = res;
    }

    | UNSIGNED INT_SYM {
        res = new IR(kCastTypeNumeric, OP3("UNSIGNED INT_SYM", "", ""));
        $$ = res;
    }

    | DECIMAL_SYM float_options {
        auto tmp1 = $2;
        res = new IR(kCastTypeNumeric, OP3("DECIMAL_SYM", "", ""), tmp1);
        $$ = res;
    }

    | FLOAT_SYM {
        res = new IR(kCastTypeNumeric, OP3("FLOAT_SYM", "", ""));
        $$ = res;
    }

    | DOUBLE_SYM opt_precision {
        auto tmp1 = $2;
        res = new IR(kCastTypeNumeric, OP3("DOUBLE_SYM", "", ""), tmp1);
        $$ = res;
    }

;


cast_type_temporal:

    DATE_SYM {
        res = new IR(kCastTypeTemporal, OP3("DATE_SYM", "", ""));
        $$ = res;
    }

    | TIME_SYM opt_field_scale {
        auto tmp1 = $2;
        res = new IR(kCastTypeTemporal, OP3("TIME_SYM", "", ""), tmp1);
        $$ = res;
    }

    | DATETIME opt_field_scale {
        auto tmp1 = $2;
        res = new IR(kCastTypeTemporal, OP3("DATETIME", "", ""), tmp1);
        $$ = res;
    }

    | INTERVAL_SYM DAY_SECOND_SYM field_scale {
        auto tmp1 = $3;
        res = new IR(kCastTypeTemporal, OP3("INTERVAL_SYM DAY_SECOND_SYM", "", ""), tmp1);
        $$ = res;
    }

;


opt_expr_list:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptExprList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | expr_list {
        auto tmp1 = $1;
        res = new IR(kOptExprList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


expr_list:

    expr {
        auto tmp1 = $1;
        res = new IR(kExprList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | expr_list ',' expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kExprList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


ident_list_arg:

    ident_list {
        auto tmp1 = $1;
        res = new IR(kIdentListArg, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' ident_list ')' {
        auto tmp1 = $2;
        res = new IR(kIdentListArg, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


ident_list:

    simple_ident {
        auto tmp1 = $1;
        res = new IR(kIdentList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_list ',' simple_ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kIdentList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


when_list:

    WHEN_SYM expr THEN_SYM expr {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kWhenList, OP3("WHEN_SYM", "THEN_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | when_list WHEN_SYM expr THEN_SYM expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kWhenList_1, OP3("", "WHEN_SYM", "THEN_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kWhenList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


when_list_opt_else:

    when_list {
        auto tmp1 = $1;
        res = new IR(kWhenListOptElse, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | when_list ELSE expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kWhenListOptElse, OP3("", "ELSE", ""), tmp1, tmp2);
        $$ = res;
    }

;


decode_when_list_oracle:

    expr ',' expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDecodeWhenListOracle, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | decode_when_list_oracle ',' expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDecodeWhenListOracle, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;





table_ref:

    table_factor {
        auto tmp1 = $1;
        res = new IR(kTableRef, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | join_table {
        auto tmp1 = $1;
        res = new IR(kTableRef, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


json_text_literal:

    TEXT_STRING {
        auto tmp1 = $1;
        res = new IR(kJsonTextLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NCHAR_STRING {
        auto tmp1 = $1;
        res = new IR(kJsonTextLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | UNDERSCORE_CHARSET TEXT_STRING {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kJsonTextLiteral, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


json_text_literal_or_num:

    json_text_literal {
        auto tmp1 = $1;
        res = new IR(kJsonTextLiteralOrNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NUM {
        auto tmp1 = $1;
        res = new IR(kJsonTextLiteralOrNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LONG_NUM {
        auto tmp1 = $1;
        res = new IR(kJsonTextLiteralOrNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DECIMAL_NUM {
        auto tmp1 = $1;
        res = new IR(kJsonTextLiteralOrNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FLOAT_NUM {
        auto tmp1 = $1;
        res = new IR(kJsonTextLiteralOrNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


join_table_list:

    derived_table_list {
        auto tmp1 = $1;
        res = new IR(kJoinTableList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


json_table_columns_clause:

    COLUMNS '(' json_table_columns_list ')' {
        auto tmp1 = $3;
        res = new IR(kJsonTableColumnsClause, OP3("COLUMNS (", ")", ""), tmp1);
        $$ = res;
    }

;


json_table_columns_list:

    json_table_column {
        auto tmp1 = $1;
        res = new IR(kJsonTableColumnsList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | json_table_columns_list ',' json_table_column {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kJsonTableColumnsList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


json_table_column:

    ident {} json_table_column_type {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kJsonTableColumn_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kJsonTableColumn, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | NESTED_SYM PATH_SYM json_text_literal {} json_table_columns_clause {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kJsonTableColumn_2, OP3("NESTED_SYM PATH_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kJsonTableColumn, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


json_table_column_type:

    FOR_SYM ORDINALITY_SYM {
        res = new IR(kJsonTableColumnType, OP3("FOR_SYM ORDINALITY_SYM", "", ""));
        $$ = res;
    }

    | json_table_field_type PATH_SYM json_text_literal json_opt_on_empty_or_error {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kJsonTableColumnType_1, OP3("", "PATH_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kJsonTableColumnType, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | json_table_field_type EXISTS PATH_SYM json_text_literal {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kJsonTableColumnType, OP3("", "EXISTS PATH_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

;


json_table_field_type:

    field_type_numeric {
        auto tmp1 = $1;
        res = new IR(kJsonTableFieldType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | field_type_temporal {
        auto tmp1 = $1;
        res = new IR(kJsonTableFieldType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | field_type_string {
        auto tmp1 = $1;
        res = new IR(kJsonTableFieldType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | field_type_lob {
        auto tmp1 = $1;
        res = new IR(kJsonTableFieldType, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


json_opt_on_empty_or_error:

    {} {
        auto tmp1 = $1;
        res = new IR(kJsonOptOnEmptyOrError, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | json_on_error_response {
        auto tmp1 = $1;
        res = new IR(kJsonOptOnEmptyOrError, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | json_on_error_response json_on_empty_response {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kJsonOptOnEmptyOrError, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | json_on_empty_response {
        auto tmp1 = $1;
        res = new IR(kJsonOptOnEmptyOrError, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | json_on_empty_response json_on_error_response {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kJsonOptOnEmptyOrError, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


json_on_response:

    ERROR_SYM {
        res = new IR(kJsonOnResponse, OP3("ERROR_SYM", "", ""));
        $$ = res;
    }

    | NULL_SYM {
        res = new IR(kJsonOnResponse, OP3("NULL_SYM", "", ""));
        $$ = res;
    }

    | DEFAULT json_text_literal_or_num {
        auto tmp1 = $2;
        res = new IR(kJsonOnResponse, OP3("DEFAULT", "", ""), tmp1);
        $$ = res;
    }

;


json_on_error_response:

    json_on_response ON ERROR_SYM {
        auto tmp1 = $1;
        res = new IR(kJsonOnErrorResponse, OP3("", "ON ERROR_SYM", ""), tmp1);
        $$ = res;
    }

;


json_on_empty_response:

    json_on_response ON EMPTY_SYM {
        auto tmp1 = $1;
        res = new IR(kJsonOnEmptyResponse, OP3("", "ON EMPTY_SYM", ""), tmp1);
        $$ = res;
    }

;


table_function:

    JSON_TABLE_SYM '(' {} expr ',' {} json_text_literal json_table_columns_clause ')' opt_table_alias_clause {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kTableFunction_1, OP3("JSON_TABLE_SYM (", "", ","), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kTableFunction_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $7;
        res = new IR(kTableFunction_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $8;
        res = new IR(kTableFunction_4, OP3("", "", ")"), res, tmp5);
        PUSH(res);
        auto tmp6 = $10;
        res = new IR(kTableFunction, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

;



esc_table_ref:

    table_ref {
        auto tmp1 = $1;
        res = new IR(kEscTableRef, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '{' ident table_ref '}' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kEscTableRef, OP3("{", "", "}"), tmp1, tmp2);
        $$ = res;
    }

;




derived_table_list:

    esc_table_ref {
        auto tmp1 = $1;
        res = new IR(kDerivedTableList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | derived_table_list ',' esc_table_ref {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDerivedTableList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;



join_table:

    table_ref normal_join table_ref %prec CONDITIONLESS_JOIN {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kJoinTable_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kJoinTable, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | table_ref normal_join table_ref ON {} expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kJoinTable_2, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kJoinTable_3, OP3("", "", "ON"), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kJoinTable_4, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kJoinTable, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | table_ref normal_join table_ref USING {} '(' using_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kJoinTable_5, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kJoinTable_6, OP3("", "", "USING"), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kJoinTable_7, OP3("", "", "("), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kJoinTable, OP3("", "", ")"), res, tmp5);
        $$ = res;
    }

    | table_ref NATURAL inner_join table_factor {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kJoinTable_8, OP3("", "NATURAL", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kJoinTable, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | table_ref LEFT opt_outer JOIN_SYM table_ref ON {} expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kJoinTable_9, OP3("", "LEFT", "JOIN_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kJoinTable_10, OP3("", "", "ON"), res, tmp3);
        PUSH(res);
        auto tmp4 = $7;
        res = new IR(kJoinTable_11, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $8;
        res = new IR(kJoinTable, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | table_ref LEFT opt_outer JOIN_SYM table_factor {} USING '(' using_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kJoinTable_12, OP3("", "LEFT", "JOIN_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kJoinTable_13, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kJoinTable_14, OP3("", "", "USING ("), res, tmp4);
        PUSH(res);
        auto tmp5 = $9;
        res = new IR(kJoinTable, OP3("", "", ")"), res, tmp5);
        $$ = res;
    }

    | table_ref NATURAL LEFT opt_outer JOIN_SYM table_factor {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kJoinTable_15, OP3("", "NATURAL LEFT", "JOIN_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kJoinTable, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | table_ref RIGHT opt_outer JOIN_SYM table_ref ON {} expr {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kJoinTable_16, OP3("", "RIGHT", "JOIN_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kJoinTable_17, OP3("", "", "ON"), res, tmp3);
        PUSH(res);
        auto tmp4 = $7;
        res = new IR(kJoinTable_18, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $8;
        res = new IR(kJoinTable, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | table_ref RIGHT opt_outer JOIN_SYM table_factor {} USING '(' using_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kJoinTable_19, OP3("", "RIGHT", "JOIN_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kJoinTable_20, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kJoinTable_21, OP3("", "", "USING ("), res, tmp4);
        PUSH(res);
        auto tmp5 = $9;
        res = new IR(kJoinTable, OP3("", "", ")"), res, tmp5);
        $$ = res;
    }

    | table_ref NATURAL RIGHT opt_outer JOIN_SYM table_factor {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kJoinTable_22, OP3("", "NATURAL RIGHT", "JOIN_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kJoinTable, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;



inner_join:

    JOIN_SYM {
        res = new IR(kInnerJoin, OP3("JOIN_SYM", "", ""));
        $$ = res;
    }

    | INNER_SYM JOIN_SYM {
        res = new IR(kInnerJoin, OP3("INNER_SYM JOIN_SYM", "", ""));
        $$ = res;
    }

    | STRAIGHT_JOIN {
        res = new IR(kInnerJoin, OP3("STRAIGHT_JOIN", "", ""));
        $$ = res;
    }

;


normal_join:

    inner_join {
        auto tmp1 = $1;
        res = new IR(kNormalJoin, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CROSS JOIN_SYM {
        res = new IR(kNormalJoin, OP3("CROSS JOIN_SYM", "", ""));
        $$ = res;
    }

;



opt_use_partition:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptUsePartition, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | use_partition {
        auto tmp1 = $1;
        res = new IR(kOptUsePartition, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


use_partition:

    PARTITION_SYM '(' using_list ')' have_partitioning {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUsePartition, OP3("PARTITION_SYM (", ")", ""), tmp1, tmp2);
        $$ = res;
    }

;


table_factor:

    table_primary_ident_opt_parens {
        auto tmp1 = $1;
        res = new IR(kTableFactor, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_primary_derived_opt_parens {
        auto tmp1 = $1;
        res = new IR(kTableFactor, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | join_table_parens {
        auto tmp1 = $1;
        res = new IR(kTableFactor, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_reference_list_parens {
        auto tmp1 = $1;
        res = new IR(kTableFactor, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_function {
        auto tmp1 = $1;
        res = new IR(kTableFactor, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


table_primary_ident_opt_parens:

    table_primary_ident {
        auto tmp1 = $1;
        res = new IR(kTablePrimaryIdentOptParens, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' table_primary_ident_opt_parens ')' {
        auto tmp1 = $2;
        res = new IR(kTablePrimaryIdentOptParens, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


table_primary_derived_opt_parens:

    table_primary_derived {
        auto tmp1 = $1;
        res = new IR(kTablePrimaryDerivedOptParens, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' table_primary_derived_opt_parens ')' {
        auto tmp1 = $2;
        res = new IR(kTablePrimaryDerivedOptParens, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


table_reference_list_parens:

    '(' table_reference_list_parens ')' {
        auto tmp1 = $2;
        res = new IR(kTableReferenceListParens, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | '(' nested_table_reference_list ')' {
        auto tmp1 = $2;
        res = new IR(kTableReferenceListParens, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


nested_table_reference_list:

    table_ref ',' table_ref {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kNestedTableReferenceList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | nested_table_reference_list ',' table_ref {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kNestedTableReferenceList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


join_table_parens:

    '(' join_table_parens ')' {
        auto tmp1 = $2;
        res = new IR(kJoinTableParens, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

    | '(' join_table ')' {
        auto tmp1 = $2;
        res = new IR(kJoinTableParens, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;



table_primary_ident:

    table_ident opt_use_partition opt_for_system_time_clause opt_table_alias_clause opt_key_definition {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTablePrimaryIdent_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kTablePrimaryIdent_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kTablePrimaryIdent_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kTablePrimaryIdent, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


table_primary_derived:

    subquery opt_for_system_time_clause table_alias_clause {} %ifdef ORACLE {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTablePrimaryDerived_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kTablePrimaryDerived_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kTablePrimaryDerived_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kTablePrimaryDerived_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $6;
        res = new IR(kTablePrimaryDerived, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | subquery opt_for_system_time_clause {} %endif {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTablePrimaryDerived_5, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kTablePrimaryDerived_6, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kTablePrimaryDerived, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


opt_outer:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptOuter, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | OUTER{}} {
        auto tmp1 = $1;
        res = new IR(kOptOuter, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


index_hint_clause:

    {} {
        auto tmp1 = $1;
        res = new IR(kIndexHintClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FOR_SYM JOIN_SYM {
        res = new IR(kIndexHintClause, OP3("FOR_SYM JOIN_SYM", "", ""));
        $$ = res;
    }

    | FOR_SYM ORDER_SYM BY {
        res = new IR(kIndexHintClause, OP3("FOR_SYM ORDER_SYM BY", "", ""));
        $$ = res;
    }

    | FOR_SYM GROUP_SYM BY {
        res = new IR(kIndexHintClause, OP3("FOR_SYM GROUP_SYM BY", "", ""));
        $$ = res;
    }

;


index_hint_type:

    FORCE_SYM {
        res = new IR(kIndexHintType, OP3("FORCE_SYM", "", ""));
        $$ = res;
    }

    | IGNORE_SYM {
        res = new IR(kIndexHintType, OP3("IGNORE_SYM", "", ""));
        $$ = res;
    }

;


index_hint_definition:

    index_hint_type key_or_index index_hint_clause {} '(' key_usage_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kIndexHintDefinition_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kIndexHintDefinition_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kIndexHintDefinition_3, OP3("", "", "("), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kIndexHintDefinition, OP3("", "", ")"), res, tmp5);
        $$ = res;
    }

    | USE_SYM key_or_index index_hint_clause {} '(' opt_key_usage_list ')' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kIndexHintDefinition_4, OP3("USE_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kIndexHintDefinition_5, OP3("", "", "("), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kIndexHintDefinition, OP3("", "", ")"), res, tmp4);
        $$ = res;
    }

;


index_hints_list:

    index_hint_definition {
        auto tmp1 = $1;
        res = new IR(kIndexHintsList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | index_hints_list index_hint_definition {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kIndexHintsList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_index_hints_list:

    {} index_hints_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptIndexHintsList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | {} index_hints_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptIndexHintsList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_key_definition:

    {} opt_index_hints_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptKeyDefinition, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_key_usage_list:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptKeyUsageList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | key_usage_list {
        auto tmp1 = $1;
        res = new IR(kOptKeyUsageList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


key_usage_element:

    ident {
        auto tmp1 = $1;
        res = new IR(kKeyUsageElement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | PRIMARY_SYM {
        res = new IR(kKeyUsageElement, OP3("PRIMARY_SYM", "", ""));
        $$ = res;
    }

;


key_usage_list:

    key_usage_element {
        auto tmp1 = $1;
        res = new IR(kKeyUsageList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | key_usage_list ',' key_usage_element {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kKeyUsageList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


using_list:

    ident {
        auto tmp1 = $1;
        res = new IR(kUsingList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | using_list ',' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUsingList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


interval:

    interval_time_stamp {
        auto tmp1 = $1;
        res = new IR(kInterval, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DAY_HOUR_SYM {
        res = new IR(kInterval, OP3("DAY_HOUR_SYM", "", ""));
        $$ = res;
    }

    | DAY_MICROSECOND_SYM {
        res = new IR(kInterval, OP3("DAY_MICROSECOND_SYM", "", ""));
        $$ = res;
    }

    | DAY_MINUTE_SYM {
        res = new IR(kInterval, OP3("DAY_MINUTE_SYM", "", ""));
        $$ = res;
    }

    | DAY_SECOND_SYM {
        res = new IR(kInterval, OP3("DAY_SECOND_SYM", "", ""));
        $$ = res;
    }

    | HOUR_MICROSECOND_SYM {
        res = new IR(kInterval, OP3("HOUR_MICROSECOND_SYM", "", ""));
        $$ = res;
    }

    | HOUR_MINUTE_SYM {
        res = new IR(kInterval, OP3("HOUR_MINUTE_SYM", "", ""));
        $$ = res;
    }

    | HOUR_SECOND_SYM {
        res = new IR(kInterval, OP3("HOUR_SECOND_SYM", "", ""));
        $$ = res;
    }

    | MINUTE_MICROSECOND_SYM {
        res = new IR(kInterval, OP3("MINUTE_MICROSECOND_SYM", "", ""));
        $$ = res;
    }

    | MINUTE_SECOND_SYM {
        res = new IR(kInterval, OP3("MINUTE_SECOND_SYM", "", ""));
        $$ = res;
    }

    | SECOND_MICROSECOND_SYM {
        res = new IR(kInterval, OP3("SECOND_MICROSECOND_SYM", "", ""));
        $$ = res;
    }

    | YEAR_MONTH_SYM {
        res = new IR(kInterval, OP3("YEAR_MONTH_SYM", "", ""));
        $$ = res;
    }

;


interval_time_stamp:

    DAY_SYM {
        res = new IR(kIntervalTimeStamp, OP3("DAY_SYM", "", ""));
        $$ = res;
    }

    | WEEK_SYM {
        res = new IR(kIntervalTimeStamp, OP3("WEEK_SYM", "", ""));
        $$ = res;
    }

    | HOUR_SYM {
        res = new IR(kIntervalTimeStamp, OP3("HOUR_SYM", "", ""));
        $$ = res;
    }

    | MINUTE_SYM {
        res = new IR(kIntervalTimeStamp, OP3("MINUTE_SYM", "", ""));
        $$ = res;
    }

    | MONTH_SYM {
        res = new IR(kIntervalTimeStamp, OP3("MONTH_SYM", "", ""));
        $$ = res;
    }

    | QUARTER_SYM {
        res = new IR(kIntervalTimeStamp, OP3("QUARTER_SYM", "", ""));
        $$ = res;
    }

    | SECOND_SYM {
        res = new IR(kIntervalTimeStamp, OP3("SECOND_SYM", "", ""));
        $$ = res;
    }

    | MICROSECOND_SYM {
        res = new IR(kIntervalTimeStamp, OP3("MICROSECOND_SYM", "", ""));
        $$ = res;
    }

    | YEAR_SYM {
        res = new IR(kIntervalTimeStamp, OP3("YEAR_SYM", "", ""));
        $$ = res;
    }

;


date_time_type:

    DATE_SYM {
        res = new IR(kDateTimeType, OP3("DATE_SYM", "", ""));
        $$ = res;
    }

    | TIME_SYM {
        res = new IR(kDateTimeType, OP3("TIME_SYM", "", ""));
        $$ = res;
    }

    | DATETIME {
        res = new IR(kDateTimeType, OP3("DATETIME", "", ""));
        $$ = res;
    }

    | TIMESTAMP {
        res = new IR(kDateTimeType, OP3("TIMESTAMP", "", ""));
        $$ = res;
    }

;


table_alias:

    AS {
        res = new IR(kTableAlias, OP3("AS", "", ""));
        $$ = res;
    }

    | AS {
        res = new IR(kTableAlias, OP3("AS", "", ""));
        $$ = res;
    }

    | '=' {
        auto tmp1 = $1;
        res = new IR(kTableAlias, OP3("=", "", ""), tmp1);
        $$ = res;
    }

;


opt_table_alias_clause:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptTableAliasClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_alias_clause {
        auto tmp1 = $1;
        res = new IR(kOptTableAliasClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


table_alias_clause:

    table_alias ident_table_alias {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableAliasClause, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_all:

    ALL {
        res = new IR(kOptAll, OP3("ALL", "", ""));
        $$ = res;
    }

    | ALL {
        res = new IR(kOptAll, OP3("ALL", "", ""));
        $$ = res;
    }

;


opt_where_clause:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptWhereClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | WHERE {} expr {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptWhereClause, OP3("WHERE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_having_clause:

    HAVING {} expr {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptHavingClause, OP3("HAVING", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | HAVING {} expr {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptHavingClause, OP3("HAVING", "", ""), tmp1, tmp2);
        $$ = res;
    }

;




opt_group_clause:

    GROUP_SYM BY group_list olap_opt {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptGroupClause, OP3("GROUP_SYM BY", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | GROUP_SYM BY group_list olap_opt {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptGroupClause, OP3("GROUP_SYM BY", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


group_list:

    group_list ',' order_ident order_dir {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGroupList_1, OP3("", ",", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kGroupList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | order_ident order_dir {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kGroupList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


olap_opt:

    {} {
        auto tmp1 = $1;
        res = new IR(kOlapOpt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | WITH_CUBE_SYM{} } {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOlapOpt, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | WITH_ROLLUP_SYM{} } {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOlapOpt, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;




opt_window_clause:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptWindowClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | WINDOW_SYM window_def_list{}} {
        auto tmp1 = $2;
        res = new IR(kOptWindowClause, OP3("WINDOW_SYM", "", ""), tmp1);
        $$ = res;
    }

;


window_def_list:

    window_def_list ',' window_def {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kWindowDefList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | window_def {
        auto tmp1 = $1;
        res = new IR(kWindowDefList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


window_def:

    window_name AS window_spec {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kWindowDef, OP3("", "AS", ""), tmp1, tmp2);
        $$ = res;
    }

;


window_spec:

    '(' {} opt_window_ref opt_window_partition_clause opt_window_order_clause opt_window_frame_clause ')' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kWindowSpec_1, OP3("(", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kWindowSpec_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kWindowSpec_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kWindowSpec, OP3("", "", ")"), res, tmp5);
        $$ = res;
    }

;


opt_window_ref:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptWindowRef, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident{} } {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptWindowRef, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_window_partition_clause:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptWindowPartitionClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | PARTITION_SYM BY group_list {
        auto tmp1 = $3;
        res = new IR(kOptWindowPartitionClause, OP3("PARTITION_SYM BY", "", ""), tmp1);
        $$ = res;
    }

;


opt_window_order_clause:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptWindowOrderClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ORDER_SYM BY order_list {
        auto tmp1 = $3;
        res = new IR(kOptWindowOrderClause, OP3("ORDER_SYM BY", "", ""), tmp1);
        $$ = res;
    }

;


opt_window_frame_clause:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptWindowFrameClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | window_frame_units window_frame_extent opt_window_frame_exclusion{} } {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptWindowFrameClause_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kOptWindowFrameClause_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kOptWindowFrameClause, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


window_frame_units:

    ROWS_SYM {
        res = new IR(kWindowFrameUnits, OP3("ROWS_SYM", "", ""));
        $$ = res;
    }

    | RANGE_SYM {
        res = new IR(kWindowFrameUnits, OP3("RANGE_SYM", "", ""));
        $$ = res;
    }

;


window_frame_extent:

    window_frame_start {
        auto tmp1 = $1;
        res = new IR(kWindowFrameExtent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | BETWEEN_SYM window_frame_bound AND_SYM window_frame_bound {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kWindowFrameExtent, OP3("BETWEEN_SYM", "AND_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

;


window_frame_start:

    UNBOUNDED_SYM PRECEDING_SYM {
        res = new IR(kWindowFrameStart, OP3("UNBOUNDED_SYM PRECEDING_SYM", "", ""));
        $$ = res;
    }

    | CURRENT_SYM ROW_SYM {
        res = new IR(kWindowFrameStart, OP3("CURRENT_SYM ROW_SYM", "", ""));
        $$ = res;
    }

    | literal PRECEDING_SYM {
        auto tmp1 = $1;
        res = new IR(kWindowFrameStart, OP3("", "PRECEDING_SYM", ""), tmp1);
        $$ = res;
    }

;


window_frame_bound:

    window_frame_start {
        auto tmp1 = $1;
        res = new IR(kWindowFrameBound, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | UNBOUNDED_SYM FOLLOWING_SYM {
        res = new IR(kWindowFrameBound, OP3("UNBOUNDED_SYM FOLLOWING_SYM", "", ""));
        $$ = res;
    }

    | literal FOLLOWING_SYM {
        auto tmp1 = $1;
        res = new IR(kWindowFrameBound, OP3("", "FOLLOWING_SYM", ""), tmp1);
        $$ = res;
    }

;


opt_window_frame_exclusion:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptWindowFrameExclusion, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | EXCLUDE_SYM CURRENT_SYM ROW_SYM {
        res = new IR(kOptWindowFrameExclusion, OP3("EXCLUDE_SYM CURRENT_SYM ROW_SYM", "", ""));
        $$ = res;
    }

    | EXCLUDE_SYM GROUP_SYM {
        res = new IR(kOptWindowFrameExclusion, OP3("EXCLUDE_SYM GROUP_SYM", "", ""));
        $$ = res;
    }

    | EXCLUDE_SYM TIES_SYM {
        res = new IR(kOptWindowFrameExclusion, OP3("EXCLUDE_SYM TIES_SYM", "", ""));
        $$ = res;
    }

    | EXCLUDE_SYM NO_SYM OTHERS_MARIADB_SYM {
        res = new IR(kOptWindowFrameExclusion, OP3("EXCLUDE_SYM NO_SYM OTHERS_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | EXCLUDE_SYM NO_SYM OTHERS_ORACLE_SYM {
        auto tmp1 = $3;
        res = new IR(kOptWindowFrameExclusion, OP3("EXCLUDE_SYM NO_SYM", "", ""), tmp1);
        $$ = res;
    }

;




alter_order_clause:

    ORDER_SYM BY alter_order_list {
        auto tmp1 = $3;
        res = new IR(kAlterOrderClause, OP3("ORDER_SYM BY", "", ""), tmp1);
        $$ = res;
    }

;


alter_order_list:

    alter_order_list ',' alter_order_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAlterOrderList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | alter_order_item {
        auto tmp1 = $1;
        res = new IR(kAlterOrderList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


alter_order_item:

    simple_ident_nospvar order_dir {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAlterOrderItem, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;




opt_order_clause:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptOrderClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | order_clause {
        auto tmp1 = $1;
        res = new IR(kOptOrderClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


order_clause:

    ORDER_SYM BY {} order_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOrderClause, OP3("ORDER_SYM BY", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


order_list:

    order_list ',' order_ident order_dir {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOrderList_1, OP3("", ",", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kOrderList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | order_ident order_dir {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOrderList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


order_dir:

    {} {
        auto tmp1 = $1;
        res = new IR(kOrderDir, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ASC {
        res = new IR(kOrderDir, OP3("ASC", "", ""));
        $$ = res;
    }

    | DESC {
        res = new IR(kOrderDir, OP3("DESC", "", ""));
        $$ = res;
    }

;



opt_limit_clause:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptLimitClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | limit_clause {
        auto tmp1 = $1;
        res = new IR(kOptLimitClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


limit_clause:

    LIMIT limit_options {
        auto tmp1 = $2;
        res = new IR(kLimitClause, OP3("LIMIT", "", ""), tmp1);
        $$ = res;
    }

    | LIMIT limit_options ROWS_SYM EXAMINED_SYM limit_rows_option {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kLimitClause, OP3("LIMIT", "ROWS_SYM EXAMINED_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | LIMIT ROWS_SYM EXAMINED_SYM limit_rows_option {
        auto tmp1 = $4;
        res = new IR(kLimitClause, OP3("LIMIT ROWS_SYM EXAMINED_SYM", "", ""), tmp1);
        $$ = res;
    }

    | fetch_first_clause {
        auto tmp1 = $1;
        res = new IR(kLimitClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


fetch_first_clause:

    FETCH_SYM first_or_next row_or_rows only_or_with_ties {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFetchFirstClause_1, OP3("FETCH_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kFetchFirstClause, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | OFFSET_SYM limit_option row_or_rows FETCH_SYM first_or_next row_or_rows only_or_with_ties {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFetchFirstClause_2, OP3("OFFSET_SYM", "", "FETCH_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kFetchFirstClause_3, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kFetchFirstClause_4, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kFetchFirstClause, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | FETCH_SYM first_or_next limit_option row_or_rows only_or_with_ties {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFetchFirstClause_5, OP3("FETCH_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kFetchFirstClause_6, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kFetchFirstClause, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | OFFSET_SYM limit_option row_or_rows FETCH_SYM first_or_next limit_option row_or_rows only_or_with_ties {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFetchFirstClause_7, OP3("OFFSET_SYM", "", "FETCH_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kFetchFirstClause_8, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kFetchFirstClause_9, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kFetchFirstClause_10, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $8;
        res = new IR(kFetchFirstClause, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | OFFSET_SYM limit_option row_or_rows {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFetchFirstClause, OP3("OFFSET_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


first_or_next:

    FIRST_SYM {
        res = new IR(kFirstOrNext, OP3("FIRST_SYM", "", ""));
        $$ = res;
    }

    | NEXT_SYM {
        res = new IR(kFirstOrNext, OP3("NEXT_SYM", "", ""));
        $$ = res;
    }

;


row_or_rows:

    ROW_SYM {
        res = new IR(kRowOrRows, OP3("ROW_SYM", "", ""));
        $$ = res;
    }

    | ROWS_SYM {
        res = new IR(kRowOrRows, OP3("ROWS_SYM", "", ""));
        $$ = res;
    }

;


only_or_with_ties:

    ONLY_SYM {
        res = new IR(kOnlyOrWithTies, OP3("ONLY_SYM", "", ""));
        $$ = res;
    }

    | WITH TIES_SYM {
        res = new IR(kOnlyOrWithTies, OP3("WITH TIES_SYM", "", ""));
        $$ = res;
    }

;



opt_global_limit_clause:

    opt_limit_clause {
        auto tmp1 = $1;
        res = new IR(kOptGlobalLimitClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


limit_options:

    limit_option {
        auto tmp1 = $1;
        res = new IR(kLimitOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | limit_option ',' limit_option {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kLimitOptions, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | limit_option OFFSET_SYM limit_option {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kLimitOptions, OP3("", "OFFSET_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

;


limit_option:

    ident_cli {
        auto tmp1 = $1;
        res = new IR(kLimitOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_cli '.' ident_cli {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kLimitOption, OP3("", ".", ""), tmp1, tmp2);
        $$ = res;
    }

    | param_marker {
        auto tmp1 = $1;
        res = new IR(kLimitOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ULONGLONG_NUM {
        auto tmp1 = $1;
        res = new IR(kLimitOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LONG_NUM {
        auto tmp1 = $1;
        res = new IR(kLimitOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NUM {
        auto tmp1 = $1;
        res = new IR(kLimitOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


limit_rows_option:

    limit_option {
        auto tmp1 = $1;
        res = new IR(kLimitRowsOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


delete_limit_clause:

    {} {
        auto tmp1 = $1;
        res = new IR(kDeleteLimitClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LIMIT limit_option {
        auto tmp1 = $2;
        res = new IR(kDeleteLimitClause, OP3("LIMIT", "", ""), tmp1);
        $$ = res;
    }

    | LIMIT ROWS_SYM EXAMINED_SYM {
        res = new IR(kDeleteLimitClause, OP3("LIMIT ROWS_SYM EXAMINED_SYM", "", ""));
        $$ = res;
    }

    | LIMIT limit_option ROWS_SYM EXAMINED_SYM {
        auto tmp1 = $2;
        res = new IR(kDeleteLimitClause, OP3("LIMIT", "ROWS_SYM EXAMINED_SYM", ""), tmp1);
        $$ = res;
    }

;


order_limit_lock:

    order_or_limit {
        auto tmp1 = $1;
        res = new IR(kOrderLimitLock, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | order_or_limit select_lock_type {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOrderLimitLock, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | select_lock_type {
        auto tmp1 = $1;
        res = new IR(kOrderLimitLock, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_order_limit_lock:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptOrderLimitLock, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | order_limit_lock {
        auto tmp1 = $1;
        res = new IR(kOptOrderLimitLock, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


query_expression_tail:

    order_limit_lock {
        auto tmp1 = $1;
        res = new IR(kQueryExpressionTail, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_query_expression_tail:

    opt_order_limit_lock {
        auto tmp1 = $1;
        res = new IR(kOptQueryExpressionTail, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_procedure_or_into:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptProcedureOrInto, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | procedure_clause opt_select_lock_type {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptProcedureOrInto, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | into opt_select_lock_type {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptProcedureOrInto, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;



order_or_limit:

    order_clause opt_limit_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOrderOrLimit, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | limit_clause {
        auto tmp1 = $1;
        res = new IR(kOrderOrLimit, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



opt_plus:

    '+' {
        auto tmp1 = $1;
        res = new IR(kOptPlus, OP3("+", "", ""), tmp1);
        $$ = res;
    }

    | '+' {
        auto tmp1 = $1;
        res = new IR(kOptPlus, OP3("+", "", ""), tmp1);
        $$ = res;
    }

;


int_num:

    opt_plus NUM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kIntNum, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | '-' NUM {
        auto tmp1 = $2;
        res = new IR(kIntNum, OP3("-", "", ""), tmp1);
        $$ = res;
    }

;


ulong_num:

    opt_plus NUM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUlongNum, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | HEX_NUM {
        auto tmp1 = $1;
        res = new IR(kUlongNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | opt_plus LONG_NUM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUlongNum, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | opt_plus ULONGLONG_NUM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUlongNum, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | opt_plus DECIMAL_NUM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUlongNum, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | opt_plus FLOAT_NUM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUlongNum, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


real_ulong_num:

    NUM {
        auto tmp1 = $1;
        res = new IR(kRealUlongNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | HEX_NUM {
        auto tmp1 = $1;
        res = new IR(kRealUlongNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LONG_NUM {
        auto tmp1 = $1;
        res = new IR(kRealUlongNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ULONGLONG_NUM {
        auto tmp1 = $1;
        res = new IR(kRealUlongNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | dec_num_error {
        auto tmp1 = $1;
        res = new IR(kRealUlongNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


longlong_num:

    opt_plus NUM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kLonglongNum, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | LONG_NUM {
        auto tmp1 = $1;
        res = new IR(kLonglongNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '-' NUM {
        auto tmp1 = $2;
        res = new IR(kLonglongNum, OP3("-", "", ""), tmp1);
        $$ = res;
    }

    | '-' LONG_NUM {
        auto tmp1 = $2;
        res = new IR(kLonglongNum, OP3("-", "", ""), tmp1);
        $$ = res;
    }

;


ulonglong_num:

    opt_plus NUM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUlonglongNum, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | opt_plus ULONGLONG_NUM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUlonglongNum, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | opt_plus LONG_NUM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUlonglongNum, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | opt_plus DECIMAL_NUM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUlonglongNum, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | opt_plus FLOAT_NUM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUlonglongNum, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


real_ulonglong_num:

    NUM {
        auto tmp1 = $1;
        res = new IR(kRealUlonglongNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ULONGLONG_NUM {
        auto tmp1 = $1;
        res = new IR(kRealUlonglongNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | HEX_NUM {
        auto tmp1 = $1;
        res = new IR(kRealUlonglongNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LONG_NUM {
        auto tmp1 = $1;
        res = new IR(kRealUlonglongNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | dec_num_error {
        auto tmp1 = $1;
        res = new IR(kRealUlonglongNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


dec_num_error:

    dec_num {
        auto tmp1 = $1;
        res = new IR(kDecNumError, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


dec_num:

    DECIMAL_NUM {
        auto tmp1 = $1;
        res = new IR(kDecNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FLOAT_NUM {
        auto tmp1 = $1;
        res = new IR(kDecNum, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


choice:

    ulong_num {
        auto tmp1 = $1;
        res = new IR(kChoice, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kChoice, OP3("DEFAULT", "", ""));
        $$ = res;
    }

;


bool:

    ulong_num {
        auto tmp1 = $1;
        res = new IR(kBool, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TRUE_SYM {
        res = new IR(kBool, OP3("TRUE_SYM", "", ""));
        $$ = res;
    }

    | FALSE_SYM {
        res = new IR(kBool, OP3("FALSE_SYM", "", ""));
        $$ = res;
    }

;


procedure_clause:

    PROCEDURE_SYM ident {} '(' procedure_list ')' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kProcedureClause_1, OP3("PROCEDURE_SYM", "", "("), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kProcedureClause, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

;


procedure_list:

    {} {
        auto tmp1 = $1;
        res = new IR(kProcedureList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | procedure_list2{}} {
        auto tmp1 = $1;
        res = new IR(kProcedureList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


procedure_list2:

    procedure_list2 ',' procedure_item {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kProcedureList2, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | procedure_item {
        auto tmp1 = $1;
        res = new IR(kProcedureList2, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


procedure_item:

    remember_name expr remember_end {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kProcedureItem_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kProcedureItem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


select_var_list_init:

    {} select_var_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSelectVarListInit, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


select_var_list:

    select_var_list ',' select_var_ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSelectVarList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | select_var_ident {
        auto tmp1 = $1;
        res = new IR(kSelectVarList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


select_var_ident:

    select_outvar {
        auto tmp1 = $1;
        res = new IR(kSelectVarIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


select_outvar:

    '@' ident_or_text {
        auto tmp1 = $2;
        res = new IR(kSelectOutvar, OP3("@", "", ""), tmp1);
        $$ = res;
    }

    | ident_or_text {
        auto tmp1 = $1;
        res = new IR(kSelectOutvar, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident '.' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSelectOutvar, OP3("", ".", ""), tmp1, tmp2);
        $$ = res;
    }

;


into:

    INTO into_destination {
        auto tmp1 = $2;
        res = new IR(kInto, OP3("INTO", "", ""), tmp1);
        $$ = res;
    }

;


into_destination:

    OUTFILE TEXT_STRING_filesystem {} opt_load_data_charset {} opt_field_term opt_line_term {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kIntoDestination_1, OP3("OUTFILE", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kIntoDestination_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kIntoDestination_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kIntoDestination_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $7;
        res = new IR(kIntoDestination, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | DUMPFILE TEXT_STRING_filesystem {
        auto tmp1 = $2;
        res = new IR(kIntoDestination, OP3("DUMPFILE", "", ""), tmp1);
        $$ = res;
    }

    | select_var_list_init {
        auto tmp1 = $1;
        res = new IR(kIntoDestination, OP3("", "", ""), tmp1);
        $$ = res;
    }

;




do:

    DO_SYM {} expr_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kDo, OP3("DO_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;




drop:

    DROP opt_temporary table_or_tables opt_if_exists {} table_list opt_lock_wait_timeout opt_restrict {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kDrop_1, OP3("DROP", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kDrop_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kDrop_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kDrop_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $7;
        res = new IR(kDrop_5, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $8;
        res = new IR(kDrop, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

    | DROP INDEX_SYM {} opt_if_exists_table_element ident ON table_ident opt_lock_wait_timeout {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDrop_6, OP3("DROP INDEX_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kDrop_7, OP3("", "", "ON"), res, tmp3);
        PUSH(res);
        auto tmp4 = $7;
        res = new IR(kDrop_8, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $8;
        res = new IR(kDrop, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | DROP DATABASE opt_if_exists ident {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDrop, OP3("DROP DATABASE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP USER_SYM opt_if_exists clear_privileges user_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDrop_9, OP3("DROP USER_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kDrop, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | DROP ROLE_SYM opt_if_exists clear_privileges role_list {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDrop_10, OP3("DROP ROLE_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kDrop, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | DROP VIEW_SYM opt_if_exists {} table_list opt_restrict {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDrop_11, OP3("DROP VIEW_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kDrop_12, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kDrop, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | DROP EVENT_SYM opt_if_exists sp_name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDrop, OP3("DROP EVENT_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP TRIGGER_SYM opt_if_exists sp_name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDrop, OP3("DROP TRIGGER_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP SERVER_SYM opt_if_exists ident_or_text {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDrop, OP3("DROP SERVER_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP opt_temporary SEQUENCE_SYM opt_if_exists {} table_list {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kDrop_13, OP3("DROP", "SEQUENCE_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kDrop_14, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kDrop, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | drop_routine {
        auto tmp1 = $1;
        res = new IR(kDrop, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


table_list:

    table_name {
        auto tmp1 = $1;
        res = new IR(kTableList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_list ',' table_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


table_name:

    table_ident {
        auto tmp1 = $1;
        res = new IR(kTableName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


table_name_with_opt_use_partition:

    table_ident opt_use_partition {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableNameWithOptUsePartition, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


table_alias_ref_list:

    table_alias_ref {
        auto tmp1 = $1;
        res = new IR(kTableAliasRefList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_alias_ref_list ',' table_alias_ref {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableAliasRefList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


table_alias_ref:

    table_ident_opt_wild {
        auto tmp1 = $1;
        res = new IR(kTableAliasRef, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_if_exists_table_element:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptIfExistsTableElement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IF_SYM EXISTS {
        res = new IR(kOptIfExistsTableElement, OP3("IF_SYM EXISTS", "", ""));
        $$ = res;
    }

;


opt_if_exists:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptIfExists, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IF_SYM EXISTS {
        res = new IR(kOptIfExists, OP3("IF_SYM EXISTS", "", ""));
        $$ = res;
    }

;


opt_temporary:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptTemporary, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TEMPORARY {
        res = new IR(kOptTemporary, OP3("TEMPORARY", "", ""));
        $$ = res;
    }

;



insert:

    INSERT {} insert_start insert_lock_option opt_ignore opt_into insert_table {} insert_field_spec opt_insert_update opt_returning stmt_end {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kInsert_1, OP3("INSERT", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kInsert_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kInsert_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kInsert_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $7;
        res = new IR(kInsert_5, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $8;
        res = new IR(kInsert_6, OP3("", "", ""), res, tmp7);
        PUSH(res);
        auto tmp8 = $9;
        res = new IR(kInsert_7, OP3("", "", ""), res, tmp8);
        PUSH(res);
        auto tmp9 = $10;
        res = new IR(kInsert_8, OP3("", "", ""), res, tmp9);
        PUSH(res);
        auto tmp10 = $11;
        res = new IR(kInsert_9, OP3("", "", ""), res, tmp10);
        PUSH(res);
        auto tmp11 = $12;
        res = new IR(kInsert, OP3("", "", ""), res, tmp11);
        $$ = res;
    }

;


replace:

    REPLACE {} insert_start replace_lock_option opt_into insert_table {} insert_field_spec opt_returning stmt_end {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kReplace_1, OP3("REPLACE", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kReplace_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kReplace_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kReplace_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $7;
        res = new IR(kReplace_5, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $8;
        res = new IR(kReplace_6, OP3("", "", ""), res, tmp7);
        PUSH(res);
        auto tmp8 = $9;
        res = new IR(kReplace_7, OP3("", "", ""), res, tmp8);
        PUSH(res);
        auto tmp9 = $10;
        res = new IR(kReplace, OP3("", "", ""), res, tmp9);
        $$ = res;
    }

;


insert_start:

    insert_start: {
        auto tmp1 = $1;
        res = new IR(kInsertStart, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


stmt_end:

    stmt_end: {
        auto tmp1 = $1;
        res = new IR(kStmtEnd, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


insert_lock_option:

    {} {
        auto tmp1 = $1;
        res = new IR(kInsertLockOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | insert_replace_option {
        auto tmp1 = $1;
        res = new IR(kInsertLockOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | HIGH_PRIORITY {
        res = new IR(kInsertLockOption, OP3("HIGH_PRIORITY", "", ""));
        $$ = res;
    }

;


replace_lock_option:

    {} {
        auto tmp1 = $1;
        res = new IR(kReplaceLockOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | insert_replace_option {
        auto tmp1 = $1;
        res = new IR(kReplaceLockOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


insert_replace_option:

    LOW_PRIORITY {
        res = new IR(kInsertReplaceOption, OP3("LOW_PRIORITY", "", ""));
        $$ = res;
    }

    | DELAYED_SYM {
        res = new IR(kInsertReplaceOption, OP3("DELAYED_SYM", "", ""));
        $$ = res;
    }

;


opt_into:

    INTO {
        res = new IR(kOptInto, OP3("INTO", "", ""));
        $$ = res;
    }

    | INTO {
        res = new IR(kOptInto, OP3("INTO", "", ""));
        $$ = res;
    }

;


insert_table:

    {} table_name_with_opt_use_partition {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kInsertTable, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


insert_field_spec:

    insert_values {
        auto tmp1 = $1;
        res = new IR(kInsertFieldSpec, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | insert_field_list insert_values {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kInsertFieldSpec, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | SET {} ident_eq_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kInsertFieldSpec, OP3("SET", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


insert_field_list:

    LEFT_PAREN_ALT opt_fields ')' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kInsertFieldList, OP3("", "", ")"), tmp1, tmp2);
        $$ = res;
    }

;


opt_fields:

    fields {
        auto tmp1 = $1;
        res = new IR(kOptFields, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | fields {
        auto tmp1 = $1;
        res = new IR(kOptFields, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


fields:

    fields ',' insert_ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFields, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | insert_ident {
        auto tmp1 = $1;
        res = new IR(kFields, OP3("", "", ""), tmp1);
        $$ = res;
    }

;




insert_values:

    create_select_query_expression {
        auto tmp1 = $1;
        res = new IR(kInsertValues, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


values_list:

    values_list ',' no_braces {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kValuesList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | no_braces_with_names {
        auto tmp1 = $1;
        res = new IR(kValuesList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ident_eq_list:

    ident_eq_list ',' ident_eq_value {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kIdentEqList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | ident_eq_value {
        auto tmp1 = $1;
        res = new IR(kIdentEqList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ident_eq_value:

    simple_ident_nospvar equal expr_or_ignore_or_default {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kIdentEqValue_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kIdentEqValue, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


equal:

    '=' {
        auto tmp1 = $1;
        res = new IR(kEqual, OP3("=", "", ""), tmp1);
        $$ = res;
    }

    | SET_VAR {
        auto tmp1 = $1;
        res = new IR(kEqual, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_equal:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptEqual, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | equal{}} {
        auto tmp1 = $1;
        res = new IR(kOptEqual, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_with:

    opt_equal {
        auto tmp1 = $1;
        res = new IR(kOptWith, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | WITH {
        res = new IR(kOptWith, OP3("WITH", "", ""));
        $$ = res;
    }

;


opt_by:

    opt_equal {
        auto tmp1 = $1;
        res = new IR(kOptBy, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | BY {
        res = new IR(kOptBy, OP3("BY", "", ""));
        $$ = res;
    }

;


no_braces:

    '(' {} opt_values ')' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kNoBraces, OP3("(", "", ")"), tmp1, tmp2);
        $$ = res;
    }

;


no_braces_with_names:

    '(' {} opt_values_with_names ')' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kNoBracesWithNames, OP3("(", "", ")"), tmp1, tmp2);
        $$ = res;
    }

;


opt_values:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptValues, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | values {
        auto tmp1 = $1;
        res = new IR(kOptValues, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_values_with_names:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptValuesWithNames, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | values_with_names {
        auto tmp1 = $1;
        res = new IR(kOptValuesWithNames, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


values:

    values ',' expr_or_ignore_or_default {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kValues, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | expr_or_ignore_or_default {
        auto tmp1 = $1;
        res = new IR(kValues, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


values_with_names:

    values_with_names ',' remember_name expr_or_ignore_or_default remember_end {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kValuesWithNames_1, OP3("", ",", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kValuesWithNames_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kValuesWithNames, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | remember_name expr_or_ignore_or_default remember_end {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kValuesWithNames_3, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kValuesWithNames, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


expr_or_ignore:

    expr {
        auto tmp1 = $1;
        res = new IR(kExprOrIgnore, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IGNORE_SYM {
        res = new IR(kExprOrIgnore, OP3("IGNORE_SYM", "", ""));
        $$ = res;
    }

;


expr_or_ignore_or_default:

    expr_or_ignore {
        auto tmp1 = $1;
        res = new IR(kExprOrIgnoreOrDefault, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kExprOrIgnoreOrDefault, OP3("DEFAULT", "", ""));
        $$ = res;
    }

;


opt_insert_update:

    ON DUPLICATE_SYM {} KEY_SYM UPDATE_SYM {} insert_update_list {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kOptInsertUpdate_1, OP3("ON DUPLICATE_SYM", "KEY_SYM UPDATE_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kOptInsertUpdate, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ON DUPLICATE_SYM {} KEY_SYM UPDATE_SYM {} insert_update_list {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kOptInsertUpdate_2, OP3("ON DUPLICATE_SYM", "KEY_SYM UPDATE_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kOptInsertUpdate, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


update_table_list:

    table_ident opt_use_partition for_portion_of_time_clause opt_table_alias_clause opt_key_definition {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUpdateTableList_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kUpdateTableList_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kUpdateTableList_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kUpdateTableList, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | join_table_list {
        auto tmp1 = $1;
        res = new IR(kUpdateTableList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;




update:

    UPDATE_SYM {} opt_low_priority opt_ignore update_table_list SET update_list {} opt_where_clause opt_order_clause delete_limit_clause {} stmt_end {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUpdate_1, OP3("UPDATE_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kUpdate_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kUpdate_3, OP3("", "", "SET"), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kUpdate_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $8;
        res = new IR(kUpdate_5, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $9;
        res = new IR(kUpdate_6, OP3("", "", ""), res, tmp7);
        PUSH(res);
        auto tmp8 = $10;
        res = new IR(kUpdate_7, OP3("", "", ""), res, tmp8);
        PUSH(res);
        auto tmp9 = $11;
        res = new IR(kUpdate_8, OP3("", "", ""), res, tmp9);
        PUSH(res);
        auto tmp10 = $12;
        res = new IR(kUpdate_9, OP3("", "", ""), res, tmp10);
        PUSH(res);
        auto tmp11 = $13;
        res = new IR(kUpdate, OP3("", "", ""), res, tmp11);
        $$ = res;
    }

;


update_list:

    update_list ',' update_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUpdateList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | update_elem {
        auto tmp1 = $1;
        res = new IR(kUpdateList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


update_elem:

    simple_ident_nospvar equal DEFAULT {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUpdateElem, OP3("", "", "DEFAULT"), tmp1, tmp2);
        $$ = res;
    }

    | simple_ident_nospvar equal expr_or_ignore {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUpdateElem_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kUpdateElem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


insert_update_list:

    insert_update_list ',' insert_update_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kInsertUpdateList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | insert_update_elem {
        auto tmp1 = $1;
        res = new IR(kInsertUpdateList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


insert_update_elem:

    simple_ident_nospvar equal expr_or_ignore_or_default {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kInsertUpdateElem_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kInsertUpdateElem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_low_priority:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptLowPriority, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LOW_PRIORITY {
        res = new IR(kOptLowPriority, OP3("LOW_PRIORITY", "", ""));
        $$ = res;
    }

;




delete:

    DELETE_SYM {} delete_part2 {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kDelete, OP3("DELETE_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_delete_system_time:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptDeleteSystemTime, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | BEFORE_SYM SYSTEM_TIME_SYM history_point {
        auto tmp1 = $3;
        res = new IR(kOptDeleteSystemTime, OP3("BEFORE_SYM SYSTEM_TIME_SYM", "", ""), tmp1);
        $$ = res;
    }

;


delete_part2:

    opt_delete_options single_multi {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kDeletePart2, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | HISTORY_SYM delete_single_table opt_delete_system_time {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kDeletePart2, OP3("HISTORY_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


delete_single_table:

    FROM table_ident opt_use_partition {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kDeleteSingleTable, OP3("FROM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


delete_single_table_for_period:

    delete_single_table opt_for_portion_of_time_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kDeleteSingleTableForPeriod, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


single_multi:

    delete_single_table_for_period opt_where_clause opt_order_clause delete_limit_clause opt_returning {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSingleMulti_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSingleMulti_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kSingleMulti_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kSingleMulti, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | table_wild_list {} FROM join_table_list opt_where_clause {} stmt_end {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSingleMulti_4, OP3("", "", "FROM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSingleMulti_5, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kSingleMulti_6, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kSingleMulti_7, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $7;
        res = new IR(kSingleMulti, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | FROM table_alias_ref_list {} USING join_table_list opt_where_clause {} stmt_end {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSingleMulti_8, OP3("FROM", "", "USING"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kSingleMulti_9, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kSingleMulti_10, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kSingleMulti_11, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $8;
        res = new IR(kSingleMulti, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

;


opt_returning:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptReturning, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RETURNING_SYM {} select_item_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptReturning, OP3("RETURNING_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


table_wild_list:

    table_wild_one {
        auto tmp1 = $1;
        res = new IR(kTableWildList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_wild_list ',' table_wild_one {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableWildList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


table_wild_one:

    ident opt_wild {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableWildOne, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ident '.' ident opt_wild {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableWildOne_1, OP3("", ".", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kTableWildOne, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_wild:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptWild, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '.' '*'{}} {
        auto tmp1 = $2;
        res = new IR(kOptWild, OP3(". '*'{}}", "", ""), tmp1);
        $$ = res;
    }

;


opt_delete_options:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptDeleteOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | opt_delete_option opt_delete_options{}} {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptDeleteOptions, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_delete_option:

    QUICK {
        res = new IR(kOptDeleteOption, OP3("QUICK", "", ""));
        $$ = res;
    }

    | LOW_PRIORITY {
        res = new IR(kOptDeleteOption, OP3("LOW_PRIORITY", "", ""));
        $$ = res;
    }

    | IGNORE_SYM {
        res = new IR(kOptDeleteOption, OP3("IGNORE_SYM", "", ""));
        $$ = res;
    }

;


truncate:

    TRUNCATE_SYM {} opt_table_sym table_name opt_lock_wait_timeout {} opt_truncate_table_storage_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kTruncate_1, OP3("TRUNCATE_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kTruncate_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kTruncate_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kTruncate_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $7;
        res = new IR(kTruncate, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

;


opt_table_sym:

    TABLE_SYM {
        res = new IR(kOptTableSym, OP3("TABLE_SYM", "", ""));
        $$ = res;
    }

    | TABLE_SYM {
        res = new IR(kOptTableSym, OP3("TABLE_SYM", "", ""));
        $$ = res;
    }

;


opt_profile_defs:

    profile_defs {
        auto tmp1 = $1;
        res = new IR(kOptProfileDefs, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | profile_defs {
        auto tmp1 = $1;
        res = new IR(kOptProfileDefs, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


profile_defs:

    profile_def {
        auto tmp1 = $1;
        res = new IR(kProfileDefs, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | profile_defs ',' profile_def {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kProfileDefs, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


profile_def:

    CPU_SYM {
        res = new IR(kProfileDef, OP3("CPU_SYM", "", ""));
        $$ = res;
    }

    | MEMORY_SYM {
        res = new IR(kProfileDef, OP3("MEMORY_SYM", "", ""));
        $$ = res;
    }

    | BLOCK_SYM IO_SYM {
        res = new IR(kProfileDef, OP3("BLOCK_SYM IO_SYM", "", ""));
        $$ = res;
    }

    | CONTEXT_SYM SWITCHES_SYM {
        res = new IR(kProfileDef, OP3("CONTEXT_SYM SWITCHES_SYM", "", ""));
        $$ = res;
    }

    | PAGE_SYM FAULTS_SYM {
        res = new IR(kProfileDef, OP3("PAGE_SYM FAULTS_SYM", "", ""));
        $$ = res;
    }

    | IPC_SYM {
        res = new IR(kProfileDef, OP3("IPC_SYM", "", ""));
        $$ = res;
    }

    | SWAPS_SYM {
        res = new IR(kProfileDef, OP3("SWAPS_SYM", "", ""));
        $$ = res;
    }

    | SOURCE_SYM {
        res = new IR(kProfileDef, OP3("SOURCE_SYM", "", ""));
        $$ = res;
    }

    | ALL {
        res = new IR(kProfileDef, OP3("ALL", "", ""));
        $$ = res;
    }

;


opt_profile_args:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptProfileArgs, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FOR_SYM QUERY_SYM NUM {
        auto tmp1 = $3;
        res = new IR(kOptProfileArgs, OP3("FOR_SYM QUERY_SYM", "", ""), tmp1);
        $$ = res;
    }

;




show:

    SHOW {} show_param {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kShow, OP3("SHOW", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


show_param:

    DATABASES wild_and_where {
        auto tmp1 = $2;
        res = new IR(kShowParam, OP3("DATABASES", "", ""), tmp1);
        $$ = res;
    }

    | opt_full TABLES opt_db wild_and_where {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kShowParam_1, OP3("", "TABLES", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kShowParam, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | opt_full TRIGGERS_SYM opt_db wild_and_where {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kShowParam_2, OP3("", "TRIGGERS_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kShowParam, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | EVENTS_SYM opt_db wild_and_where {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kShowParam, OP3("EVENTS_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | TABLE_SYM STATUS_SYM opt_db wild_and_where {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kShowParam, OP3("TABLE_SYM STATUS_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | OPEN_SYM TABLES opt_db wild_and_where {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kShowParam, OP3("OPEN_SYM TABLES", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | PLUGINS_SYM {
        res = new IR(kShowParam, OP3("PLUGINS_SYM", "", ""));
        $$ = res;
    }

    | PLUGINS_SYM SONAME_SYM TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kShowParam, OP3("PLUGINS_SYM SONAME_SYM", "", ""), tmp1);
        $$ = res;
    }

    | PLUGINS_SYM SONAME_SYM wild_and_where {
        auto tmp1 = $3;
        res = new IR(kShowParam, OP3("PLUGINS_SYM SONAME_SYM", "", ""), tmp1);
        $$ = res;
    }

    | ENGINE_SYM known_storage_engines show_engine_param {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kShowParam, OP3("ENGINE_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ENGINE_SYM ALL show_engine_param {
        auto tmp1 = $3;
        res = new IR(kShowParam, OP3("ENGINE_SYM ALL", "", ""), tmp1);
        $$ = res;
    }

    | opt_full COLUMNS from_or_in table_ident opt_db wild_and_where {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kShowParam_3, OP3("", "COLUMNS", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kShowParam_4, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kShowParam_5, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kShowParam, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | master_or_binary LOGS_SYM {
        auto tmp1 = $1;
        res = new IR(kShowParam, OP3("", "LOGS_SYM", ""), tmp1);
        $$ = res;
    }

    | SLAVE HOSTS_SYM {
        res = new IR(kShowParam, OP3("SLAVE HOSTS_SYM", "", ""));
        $$ = res;
    }

    | BINLOG_SYM EVENTS_SYM binlog_in binlog_from {} opt_global_limit_clause {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kShowParam_6, OP3("BINLOG_SYM EVENTS_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kShowParam_7, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kShowParam, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | RELAYLOG_SYM optional_connection_name EVENTS_SYM binlog_in binlog_from {} opt_global_limit_clause optional_for_channel {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kShowParam_8, OP3("RELAYLOG_SYM", "EVENTS_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kShowParam_9, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kShowParam_10, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kShowParam_11, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $8;
        res = new IR(kShowParam, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | keys_or_index from_or_in table_ident opt_db opt_where_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kShowParam_12, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kShowParam_13, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kShowParam_14, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kShowParam, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | opt_storage ENGINES_SYM {
        auto tmp1 = $1;
        res = new IR(kShowParam, OP3("", "ENGINES_SYM", ""), tmp1);
        $$ = res;
    }

    | AUTHORS_SYM {
        res = new IR(kShowParam, OP3("AUTHORS_SYM", "", ""));
        $$ = res;
    }

    | CONTRIBUTORS_SYM {
        res = new IR(kShowParam, OP3("CONTRIBUTORS_SYM", "", ""));
        $$ = res;
    }

    | PRIVILEGES {
        res = new IR(kShowParam, OP3("PRIVILEGES", "", ""));
        $$ = res;
    }

    | COUNT_SYM '(' '*' ')' WARNINGS {
        res = new IR(kShowParam, OP3("COUNT_SYM ( * ) WARNINGS", "", ""));
        $$ = res;
    }

    | COUNT_SYM '(' '*' ')' ERRORS {
        res = new IR(kShowParam, OP3("COUNT_SYM ( * ) ERRORS", "", ""));
        $$ = res;
    }

    | WARNINGS opt_global_limit_clause {
        auto tmp1 = $2;
        res = new IR(kShowParam, OP3("WARNINGS", "", ""), tmp1);
        $$ = res;
    }

    | ERRORS opt_global_limit_clause {
        auto tmp1 = $2;
        res = new IR(kShowParam, OP3("ERRORS", "", ""), tmp1);
        $$ = res;
    }

    | PROFILES_SYM {
        res = new IR(kShowParam, OP3("PROFILES_SYM", "", ""));
        $$ = res;
    }

    | PROFILE_SYM opt_profile_defs opt_profile_args opt_global_limit_clause {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kShowParam_15, OP3("PROFILE_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kShowParam, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | opt_var_type STATUS_SYM wild_and_where {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kShowParam, OP3("", "STATUS_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | opt_full PROCESSLIST_SYM {
        auto tmp1 = $1;
        res = new IR(kShowParam, OP3("", "PROCESSLIST_SYM", ""), tmp1);
        $$ = res;
    }

    | opt_var_type VARIABLES wild_and_where {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kShowParam, OP3("", "VARIABLES", ""), tmp1, tmp2);
        $$ = res;
    }

    | charset wild_and_where {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kShowParam, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | COLLATION_SYM wild_and_where {
        auto tmp1 = $2;
        res = new IR(kShowParam, OP3("COLLATION_SYM", "", ""), tmp1);
        $$ = res;
    }

    | GRANTS {
        res = new IR(kShowParam, OP3("GRANTS", "", ""));
        $$ = res;
    }

    | GRANTS FOR_SYM user_or_role clear_privileges {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kShowParam, OP3("GRANTS FOR_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CREATE DATABASE opt_if_not_exists ident {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kShowParam, OP3("CREATE DATABASE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CREATE TABLE_SYM table_ident {
        auto tmp1 = $3;
        res = new IR(kShowParam, OP3("CREATE TABLE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | CREATE VIEW_SYM table_ident {
        auto tmp1 = $3;
        res = new IR(kShowParam, OP3("CREATE VIEW_SYM", "", ""), tmp1);
        $$ = res;
    }

    | CREATE SEQUENCE_SYM table_ident {
        auto tmp1 = $3;
        res = new IR(kShowParam, OP3("CREATE SEQUENCE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | BINLOG_SYM STATUS_SYM {
        res = new IR(kShowParam, OP3("BINLOG_SYM STATUS_SYM", "", ""));
        $$ = res;
    }

    | MASTER_SYM STATUS_SYM {
        res = new IR(kShowParam, OP3("MASTER_SYM STATUS_SYM", "", ""));
        $$ = res;
    }

    | ALL SLAVES STATUS_SYM {
        res = new IR(kShowParam, OP3("ALL SLAVES STATUS_SYM", "", ""));
        $$ = res;
    }

    | SLAVE optional_connection_name STATUS_SYM optional_for_channel {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kShowParam, OP3("SLAVE", "STATUS_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | CREATE PROCEDURE_SYM sp_name {
        auto tmp1 = $3;
        res = new IR(kShowParam, OP3("CREATE PROCEDURE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | CREATE FUNCTION_SYM sp_name {
        auto tmp1 = $3;
        res = new IR(kShowParam, OP3("CREATE FUNCTION_SYM", "", ""), tmp1);
        $$ = res;
    }

    | CREATE PACKAGE_MARIADB_SYM sp_name {
        auto tmp1 = $3;
        res = new IR(kShowParam, OP3("CREATE PACKAGE_MARIADB_SYM", "", ""), tmp1);
        $$ = res;
    }

    | CREATE PACKAGE_ORACLE_SYM sp_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kShowParam, OP3("CREATE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CREATE PACKAGE_MARIADB_SYM BODY_MARIADB_SYM sp_name {
        auto tmp1 = $4;
        res = new IR(kShowParam, OP3("CREATE PACKAGE_MARIADB_SYM BODY_MARIADB_SYM", "", ""), tmp1);
        $$ = res;
    }

    | CREATE PACKAGE_ORACLE_SYM BODY_ORACLE_SYM sp_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kShowParam_16, OP3("CREATE", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kShowParam, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CREATE TRIGGER_SYM sp_name {
        auto tmp1 = $3;
        res = new IR(kShowParam, OP3("CREATE TRIGGER_SYM", "", ""), tmp1);
        $$ = res;
    }

    | CREATE USER_SYM {
        res = new IR(kShowParam, OP3("CREATE USER_SYM", "", ""));
        $$ = res;
    }

    | CREATE USER_SYM user {
        auto tmp1 = $3;
        res = new IR(kShowParam, OP3("CREATE USER_SYM", "", ""), tmp1);
        $$ = res;
    }

    | PROCEDURE_SYM STATUS_SYM wild_and_where {
        auto tmp1 = $3;
        res = new IR(kShowParam, OP3("PROCEDURE_SYM STATUS_SYM", "", ""), tmp1);
        $$ = res;
    }

    | FUNCTION_SYM STATUS_SYM wild_and_where {
        auto tmp1 = $3;
        res = new IR(kShowParam, OP3("FUNCTION_SYM STATUS_SYM", "", ""), tmp1);
        $$ = res;
    }

    | PACKAGE_MARIADB_SYM STATUS_SYM wild_and_where {
        auto tmp1 = $3;
        res = new IR(kShowParam, OP3("PACKAGE_MARIADB_SYM STATUS_SYM", "", ""), tmp1);
        $$ = res;
    }

    | PACKAGE_ORACLE_SYM STATUS_SYM wild_and_where {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kShowParam, OP3("", "STATUS_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | PACKAGE_MARIADB_SYM BODY_MARIADB_SYM STATUS_SYM wild_and_where {
        auto tmp1 = $4;
        res = new IR(kShowParam, OP3("PACKAGE_MARIADB_SYM BODY_MARIADB_SYM STATUS_SYM", "", ""), tmp1);
        $$ = res;
    }

    | PACKAGE_ORACLE_SYM BODY_ORACLE_SYM STATUS_SYM wild_and_where {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kShowParam_17, OP3("", "", "STATUS_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kShowParam, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | PROCEDURE_SYM CODE_SYM sp_name {
        auto tmp1 = $3;
        res = new IR(kShowParam, OP3("PROCEDURE_SYM CODE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | FUNCTION_SYM CODE_SYM sp_name {
        auto tmp1 = $3;
        res = new IR(kShowParam, OP3("FUNCTION_SYM CODE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | PACKAGE_MARIADB_SYM BODY_MARIADB_SYM CODE_SYM sp_name {
        auto tmp1 = $4;
        res = new IR(kShowParam, OP3("PACKAGE_MARIADB_SYM BODY_MARIADB_SYM CODE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | PACKAGE_ORACLE_SYM BODY_ORACLE_SYM CODE_SYM sp_name {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kShowParam_18, OP3("", "", "CODE_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kShowParam, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | CREATE EVENT_SYM sp_name {
        auto tmp1 = $3;
        res = new IR(kShowParam, OP3("CREATE EVENT_SYM", "", ""), tmp1);
        $$ = res;
    }

    | describe_command opt_format_json FOR_SYM expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kShowParam_19, OP3("", "", "FOR_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kShowParam, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ANALYZE_SYM opt_format_json FOR_SYM expr {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kShowParam, OP3("ANALYZE_SYM", "FOR_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | IDENT_sys remember_tok_start wild_and_where {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kShowParam_20, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kShowParam, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


show_engine_param:

    STATUS_SYM {
        res = new IR(kShowEngineParam, OP3("STATUS_SYM", "", ""));
        $$ = res;
    }

    | MUTEX_SYM {
        res = new IR(kShowEngineParam, OP3("MUTEX_SYM", "", ""));
        $$ = res;
    }

    | LOGS_SYM {
        res = new IR(kShowEngineParam, OP3("LOGS_SYM", "", ""));
        $$ = res;
    }

;


master_or_binary:

    MASTER_SYM {
        res = new IR(kMasterOrBinary, OP3("MASTER_SYM", "", ""));
        $$ = res;
    }

    | BINARY {
        res = new IR(kMasterOrBinary, OP3("BINARY", "", ""));
        $$ = res;
    }

;


opt_storage:

    STORAGE_SYM {
        res = new IR(kOptStorage, OP3("STORAGE_SYM", "", ""));
        $$ = res;
    }

    | STORAGE_SYM {
        res = new IR(kOptStorage, OP3("STORAGE_SYM", "", ""));
        $$ = res;
    }

;


opt_db:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptDb, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | from_or_in ident {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptDb, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_full:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptFull, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FULL {
        res = new IR(kOptFull, OP3("FULL", "", ""));
        $$ = res;
    }

;


from_or_in:

    FROM {
        res = new IR(kFromOrIn, OP3("FROM", "", ""));
        $$ = res;
    }

    | IN_SYM {
        res = new IR(kFromOrIn, OP3("IN_SYM", "", ""));
        $$ = res;
    }

;


binlog_in:

    {} {
        auto tmp1 = $1;
        res = new IR(kBinlogIn, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IN_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kBinlogIn, OP3("IN_SYM", "", ""), tmp1);
        $$ = res;
    }

;


binlog_from:

    {} {
        auto tmp1 = $1;
        res = new IR(kBinlogFrom, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FROM ulonglong_num {
        auto tmp1 = $2;
        res = new IR(kBinlogFrom, OP3("FROM", "", ""), tmp1);
        $$ = res;
    }

;


wild_and_where:

    {} {
        auto tmp1 = $1;
        res = new IR(kWildAndWhere, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LIKE remember_tok_start TEXT_STRING_sys {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kWildAndWhere, OP3("LIKE", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | WHERE remember_tok_start expr {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kWildAndWhere, OP3("WHERE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;



describe:

    describe_command table_ident {} opt_describe_column {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kDescribe_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kDescribe_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kDescribe, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | describe_command opt_extended_describe {} explainable_command {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kDescribe_3, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kDescribe_4, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kDescribe, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


explainable_command:

    select {
        auto tmp1 = $1;
        res = new IR(kExplainableCommand, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | select_into {
        auto tmp1 = $1;
        res = new IR(kExplainableCommand, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | insert {
        auto tmp1 = $1;
        res = new IR(kExplainableCommand, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | replace {
        auto tmp1 = $1;
        res = new IR(kExplainableCommand, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | update {
        auto tmp1 = $1;
        res = new IR(kExplainableCommand, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | delete {
        auto tmp1 = $1;
        res = new IR(kExplainableCommand, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


describe_command:

    DESC {
        res = new IR(kDescribeCommand, OP3("DESC", "", ""));
        $$ = res;
    }

    | DESCRIBE {
        res = new IR(kDescribeCommand, OP3("DESCRIBE", "", ""));
        $$ = res;
    }

;


analyze_stmt_command:

    ANALYZE_SYM opt_format_json explainable_command {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kAnalyzeStmtCommand, OP3("ANALYZE_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_extended_describe:

    EXTENDED_SYM {
        res = new IR(kOptExtendedDescribe, OP3("EXTENDED_SYM", "", ""));
        $$ = res;
    }

    | EXTENDED_SYM ALL {
        res = new IR(kOptExtendedDescribe, OP3("EXTENDED_SYM ALL", "", ""));
        $$ = res;
    }

    | PARTITIONS_SYM {
        res = new IR(kOptExtendedDescribe, OP3("PARTITIONS_SYM", "", ""));
        $$ = res;
    }

    | opt_format_json {
        auto tmp1 = $1;
        res = new IR(kOptExtendedDescribe, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_format_json:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptFormatJson, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FORMAT_SYM '=' ident_or_text{} } {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptFormatJson, OP3("FORMAT_SYM =", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_describe_column:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptDescribeColumn, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | text_string{} } {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptDescribeColumn, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ident{} } {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptDescribeColumn, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


explain_for_connection:

    describe_command opt_format_json FOR_SYM CONNECTION_SYM expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kExplainForConnection_1, OP3("", "", "FOR_SYM CONNECTION_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kExplainForConnection, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;




flush:

    FLUSH_SYM opt_no_write_to_binlog {} flush_options {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kFlush_1, OP3("FLUSH_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kFlush, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


flush_options:

    table_or_tables {} opt_table_list opt_flush_lock {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFlushOptions_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kFlushOptions_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kFlushOptions, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | flush_options_list {
        auto tmp1 = $1;
        res = new IR(kFlushOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_flush_lock:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptFlushLock, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | flush_lock{} } {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptFlushLock, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


flush_lock:

    WITH READ_SYM LOCK_SYM optional_flush_tables_arguments {
        auto tmp1 = $4;
        res = new IR(kFlushLock, OP3("WITH READ_SYM LOCK_SYM", "", ""), tmp1);
        $$ = res;
    }

    | FOR_SYM {} EXPORT_SYM {
        auto tmp1 = $2;
        res = new IR(kFlushLock, OP3("FOR_SYM", "EXPORT_SYM", ""), tmp1);
        $$ = res;
    }

;


flush_options_list:

    flush_options_list ',' flush_option {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFlushOptionsList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | flush_option {
        auto tmp1 = $1;
        res = new IR(kFlushOptionsList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


flush_option:

    ERROR_SYM LOGS_SYM {
        res = new IR(kFlushOption, OP3("ERROR_SYM LOGS_SYM", "", ""));
        $$ = res;
    }

    | ENGINE_SYM LOGS_SYM {
        res = new IR(kFlushOption, OP3("ENGINE_SYM LOGS_SYM", "", ""));
        $$ = res;
    }

    | GENERAL LOGS_SYM {
        res = new IR(kFlushOption, OP3("GENERAL LOGS_SYM", "", ""));
        $$ = res;
    }

    | SLOW LOGS_SYM {
        res = new IR(kFlushOption, OP3("SLOW LOGS_SYM", "", ""));
        $$ = res;
    }

    | BINARY LOGS_SYM opt_delete_gtid_domain {
        auto tmp1 = $3;
        res = new IR(kFlushOption, OP3("BINARY LOGS_SYM", "", ""), tmp1);
        $$ = res;
    }

    | RELAY LOGS_SYM optional_connection_name optional_for_channel {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kFlushOption, OP3("RELAY LOGS_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | QUERY_SYM CACHE_SYM {
        res = new IR(kFlushOption, OP3("QUERY_SYM CACHE_SYM", "", ""));
        $$ = res;
    }

    | HOSTS_SYM {
        res = new IR(kFlushOption, OP3("HOSTS_SYM", "", ""));
        $$ = res;
    }

    | PRIVILEGES {
        res = new IR(kFlushOption, OP3("PRIVILEGES", "", ""));
        $$ = res;
    }

    | LOGS_SYM {
        res = new IR(kFlushOption, OP3("LOGS_SYM", "", ""));
        $$ = res;
    }

    | STATUS_SYM {
        res = new IR(kFlushOption, OP3("STATUS_SYM", "", ""));
        $$ = res;
    }

    | SLAVE optional_connection_name {
        auto tmp1 = $2;
        res = new IR(kFlushOption, OP3("SLAVE", "", ""), tmp1);
        $$ = res;
    }

    | MASTER_SYM {
        res = new IR(kFlushOption, OP3("MASTER_SYM", "", ""));
        $$ = res;
    }

    | DES_KEY_FILE {
        res = new IR(kFlushOption, OP3("DES_KEY_FILE", "", ""));
        $$ = res;
    }

    | RESOURCES {
        res = new IR(kFlushOption, OP3("RESOURCES", "", ""));
        $$ = res;
    }

    | SSL_SYM {
        res = new IR(kFlushOption, OP3("SSL_SYM", "", ""));
        $$ = res;
    }

    | THREADS_SYM {
        res = new IR(kFlushOption, OP3("THREADS_SYM", "", ""));
        $$ = res;
    }

    | IDENT_sys remember_tok_start {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFlushOption, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_table_list:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptTableList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_list{}} {
        auto tmp1 = $1;
        res = new IR(kOptTableList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


backup:

    BACKUP_SYM backup_statements {
        auto tmp1 = $2;
        res = new IR(kBackup, OP3("BACKUP_SYM", "", ""), tmp1);
        $$ = res;
    }

;


backup_statements:

    STAGE_SYM ident {
        auto tmp1 = $2;
        res = new IR(kBackupStatements, OP3("STAGE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | LOCK_SYM {} table_ident {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kBackupStatements, OP3("LOCK_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | UNLOCK_SYM {
        res = new IR(kBackupStatements, OP3("UNLOCK_SYM", "", ""));
        $$ = res;
    }

;


opt_delete_gtid_domain:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptDeleteGtidDomain, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DELETE_DOMAIN_ID_SYM '=' '(' delete_domain_id_list ')'{}} {
        auto tmp1 = $4;
        res = new IR(kOptDeleteGtidDomain, OP3("DELETE_DOMAIN_ID_SYM = (", "')'{}}", ""), tmp1);
        $$ = res;
    }

;

delete_domain_id_list:

    delete_domain_id {
        auto tmp1 = $1;
        res = new IR(kDeleteDomainIdList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | delete_domain_id {
        auto tmp1 = $1;
        res = new IR(kDeleteDomainIdList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | delete_domain_id_list ',' delete_domain_id {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kDeleteDomainIdList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


delete_domain_id:

    ulonglong_num {
        auto tmp1 = $1;
        res = new IR(kDeleteDomainId, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


optional_flush_tables_arguments:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptionalFlushTablesArguments, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AND_SYM DISABLE_SYM CHECKPOINT_SYM {
        res = new IR(kOptionalFlushTablesArguments, OP3("AND_SYM DISABLE_SYM CHECKPOINT_SYM", "", ""));
        $$ = res;
    }

;


reset:

    RESET_SYM {} reset_options {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kReset, OP3("RESET_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


reset_options:

    reset_options ',' reset_option {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kResetOptions, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | reset_option {
        auto tmp1 = $1;
        res = new IR(kResetOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


reset_option:

    SLAVE {} optional_connection_name slave_reset_options optional_for_channel {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kResetOption_1, OP3("SLAVE", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kResetOption_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kResetOption, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | MASTER_SYM {} master_reset_options {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kResetOption, OP3("MASTER_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | QUERY_SYM CACHE_SYM {
        res = new IR(kResetOption, OP3("QUERY_SYM CACHE_SYM", "", ""));
        $$ = res;
    }

;


slave_reset_options:

    {} {
        auto tmp1 = $1;
        res = new IR(kSlaveResetOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ALL {
        res = new IR(kSlaveResetOptions, OP3("ALL", "", ""));
        $$ = res;
    }

;


master_reset_options:

    {} {
        auto tmp1 = $1;
        res = new IR(kMasterResetOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TO_SYM ulong_num{} } {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kMasterResetOptions, OP3("TO_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


purge:

    PURGE master_or_binary LOGS_SYM TO_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kPurge, OP3("PURGE", "LOGS_SYM TO_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | PURGE master_or_binary LOGS_SYM BEFORE_SYM {} expr {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kPurge_1, OP3("PURGE", "LOGS_SYM BEFORE_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kPurge, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;





kill:

    KILL_SYM {} kill_type kill_option {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kKill_1, OP3("KILL_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kKill, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


kill_type:

    {} {
        auto tmp1 = $1;
        res = new IR(kKillType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | HARD_SYM {
        res = new IR(kKillType, OP3("HARD_SYM", "", ""));
        $$ = res;
    }

    | SOFT_SYM {
        res = new IR(kKillType, OP3("SOFT_SYM", "", ""));
        $$ = res;
    }

;


kill_option:

    opt_connection kill_expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kKillOption, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | QUERY_SYM kill_expr {
        auto tmp1 = $2;
        res = new IR(kKillOption, OP3("QUERY_SYM", "", ""), tmp1);
        $$ = res;
    }

    | QUERY_SYM ID_SYM expr {
        auto tmp1 = $3;
        res = new IR(kKillOption, OP3("QUERY_SYM ID_SYM", "", ""), tmp1);
        $$ = res;
    }

;


opt_connection:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptConnection, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CONNECTION_SYM {
        res = new IR(kOptConnection, OP3("CONNECTION_SYM", "", ""));
        $$ = res;
    }

;


kill_expr:

    expr {
        auto tmp1 = $1;
        res = new IR(kKillExpr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | USER_SYM user {
        auto tmp1 = $2;
        res = new IR(kKillExpr, OP3("USER_SYM", "", ""), tmp1);
        $$ = res;
    }

;


shutdown:

    SHUTDOWN {} shutdown_option {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kShutdown, OP3("SHUTDOWN", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


shutdown_option:

    {} {
        auto tmp1 = $1;
        res = new IR(kShutdownOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | WAIT_SYM FOR_SYM ALL SLAVES {
        res = new IR(kShutdownOption, OP3("WAIT_SYM FOR_SYM ALL SLAVES", "", ""));
        $$ = res;
    }

;




use:

    USE_SYM ident {
        auto tmp1 = $2;
        res = new IR(kUse, OP3("USE_SYM", "", ""), tmp1);
        $$ = res;
    }

;




load:

    LOAD data_or_xml {} load_data_lock opt_local INFILE TEXT_STRING_filesystem {} opt_duplicate INTO TABLE_SYM table_ident opt_use_partition {} opt_load_data_charset {} opt_xml_rows_identified_by opt_field_term opt_line_term opt_ignore_lines opt_field_or_var_spec opt_load_data_set_spec stmt_end {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kLoad_1, OP3("LOAD", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kLoad_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kLoad_3, OP3("", "", "INFILE"), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kLoad_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $8;
        res = new IR(kLoad_5, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $9;
        res = new IR(kLoad_6, OP3("", "", "INTO TABLE_SYM"), res, tmp7);
        PUSH(res);
        auto tmp8 = $12;
        res = new IR(kLoad_7, OP3("", "", ""), res, tmp8);
        PUSH(res);
        auto tmp9 = $13;
        res = new IR(kLoad_8, OP3("", "", ""), res, tmp9);
        PUSH(res);
        auto tmp10 = $14;
        res = new IR(kLoad_9, OP3("", "", ""), res, tmp10);
        PUSH(res);
        auto tmp11 = $15;
        res = new IR(kLoad_10, OP3("", "", ""), res, tmp11);
        PUSH(res);
        auto tmp12 = $16;
        res = new IR(kLoad_11, OP3("", "", ""), res, tmp12);
        PUSH(res);
        auto tmp13 = $17;
        res = new IR(kLoad_12, OP3("", "", ""), res, tmp13);
        PUSH(res);
        auto tmp14 = $18;
        res = new IR(kLoad_13, OP3("", "", ""), res, tmp14);
        PUSH(res);
        auto tmp15 = $19;
        res = new IR(kLoad_14, OP3("", "", ""), res, tmp15);
        PUSH(res);
        auto tmp16 = $20;
        res = new IR(kLoad_15, OP3("", "", ""), res, tmp16);
        PUSH(res);
        auto tmp17 = $21;
        res = new IR(kLoad_16, OP3("", "", ""), res, tmp17);
        PUSH(res);
        auto tmp18 = $22;
        res = new IR(kLoad_17, OP3("", "", ""), res, tmp18);
        PUSH(res);
        auto tmp19 = $23;
        res = new IR(kLoad, OP3("", "", ""), res, tmp19);
        $$ = res;
    }

;


data_or_xml:

    DATA_SYM {
        res = new IR(kDataOrXml, OP3("DATA_SYM", "", ""));
        $$ = res;
    }

    | XML_SYM {
        res = new IR(kDataOrXml, OP3("XML_SYM", "", ""));
        $$ = res;
    }

;


opt_local:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptLocal, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LOCAL_SYM {
        res = new IR(kOptLocal, OP3("LOCAL_SYM", "", ""));
        $$ = res;
    }

;


load_data_lock:

    {} {
        auto tmp1 = $1;
        res = new IR(kLoadDataLock, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CONCURRENT {
        res = new IR(kLoadDataLock, OP3("CONCURRENT", "", ""));
        $$ = res;
    }

    | LOW_PRIORITY {
        res = new IR(kLoadDataLock, OP3("LOW_PRIORITY", "", ""));
        $$ = res;
    }

;


opt_duplicate:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptDuplicate, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | REPLACE {
        res = new IR(kOptDuplicate, OP3("REPLACE", "", ""));
        $$ = res;
    }

    | IGNORE_SYM {
        res = new IR(kOptDuplicate, OP3("IGNORE_SYM", "", ""));
        $$ = res;
    }

;


opt_field_term:

    COLUMNS field_term_list {
        auto tmp1 = $2;
        res = new IR(kOptFieldTerm, OP3("COLUMNS", "", ""), tmp1);
        $$ = res;
    }

    | COLUMNS field_term_list {
        auto tmp1 = $2;
        res = new IR(kOptFieldTerm, OP3("COLUMNS", "", ""), tmp1);
        $$ = res;
    }

;


field_term_list:

    field_term_list field_term {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kFieldTermList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | field_term {
        auto tmp1 = $1;
        res = new IR(kFieldTermList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


field_term:

    TERMINATED BY text_string {
        auto tmp1 = $3;
        res = new IR(kFieldTerm, OP3("TERMINATED BY", "", ""), tmp1);
        $$ = res;
    }

    | OPTIONALLY ENCLOSED BY text_string {
        auto tmp1 = $4;
        res = new IR(kFieldTerm, OP3("OPTIONALLY ENCLOSED BY", "", ""), tmp1);
        $$ = res;
    }

    | ENCLOSED BY text_string {
        auto tmp1 = $3;
        res = new IR(kFieldTerm, OP3("ENCLOSED BY", "", ""), tmp1);
        $$ = res;
    }

    | ESCAPED BY text_string {
        auto tmp1 = $3;
        res = new IR(kFieldTerm, OP3("ESCAPED BY", "", ""), tmp1);
        $$ = res;
    }

;


opt_line_term:

    LINES line_term_list {
        auto tmp1 = $2;
        res = new IR(kOptLineTerm, OP3("LINES", "", ""), tmp1);
        $$ = res;
    }

    | LINES line_term_list {
        auto tmp1 = $2;
        res = new IR(kOptLineTerm, OP3("LINES", "", ""), tmp1);
        $$ = res;
    }

;


line_term_list:

    line_term_list line_term {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kLineTermList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | line_term {
        auto tmp1 = $1;
        res = new IR(kLineTermList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


line_term:

    TERMINATED BY text_string {
        auto tmp1 = $3;
        res = new IR(kLineTerm, OP3("TERMINATED BY", "", ""), tmp1);
        $$ = res;
    }

    | STARTING BY text_string {
        auto tmp1 = $3;
        res = new IR(kLineTerm, OP3("STARTING BY", "", ""), tmp1);
        $$ = res;
    }

;


opt_xml_rows_identified_by:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptXmlRowsIdentifiedBy, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ROWS_SYM IDENTIFIED_SYM BY text_string {
        auto tmp1 = $4;
        res = new IR(kOptXmlRowsIdentifiedBy, OP3("ROWS_SYM IDENTIFIED_SYM BY", "", ""), tmp1);
        $$ = res;
    }

;


opt_ignore_lines:

    IGNORE_SYM NUM lines_or_rows {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptIgnoreLines, OP3("IGNORE_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | IGNORE_SYM NUM lines_or_rows {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptIgnoreLines, OP3("IGNORE_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


lines_or_rows:

    LINES {
        res = new IR(kLinesOrRows, OP3("LINES", "", ""));
        $$ = res;
    }

    | ROWS_SYM {
        res = new IR(kLinesOrRows, OP3("ROWS_SYM", "", ""));
        $$ = res;
    }

;


opt_field_or_var_spec:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptFieldOrVarSpec, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' fields_or_vars ')'{}} {
        auto tmp1 = $2;
        res = new IR(kOptFieldOrVarSpec, OP3("(", "')'{}}", ""), tmp1);
        $$ = res;
    }

    | '(' ')'{}} {
        auto tmp1 = $2;
        res = new IR(kOptFieldOrVarSpec, OP3("( ')'{}}", "", ""), tmp1);
        $$ = res;
    }

;


fields_or_vars:

    fields_or_vars ',' field_or_var {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFieldsOrVars, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | field_or_var {
        auto tmp1 = $1;
        res = new IR(kFieldsOrVars, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


field_or_var:

    simple_ident_nospvar {
        auto tmp1 = $1;
        res = new IR(kFieldOrVar, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '@' ident_or_text {
        auto tmp1 = $2;
        res = new IR(kFieldOrVar, OP3("@", "", ""), tmp1);
        $$ = res;
    }

;


opt_load_data_set_spec:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptLoadDataSetSpec, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SET load_data_set_list{}} {
        auto tmp1 = $2;
        res = new IR(kOptLoadDataSetSpec, OP3("SET", "", ""), tmp1);
        $$ = res;
    }

;


load_data_set_list:

    load_data_set_list ',' load_data_set_elem {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kLoadDataSetList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | load_data_set_elem {
        auto tmp1 = $1;
        res = new IR(kLoadDataSetList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


load_data_set_elem:

    simple_ident_nospvar equal remember_name expr_or_ignore_or_default remember_end {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kLoadDataSetElem_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kLoadDataSetElem_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kLoadDataSetElem_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kLoadDataSetElem, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;




text_literal:

    TEXT_STRING {
        auto tmp1 = $1;
        res = new IR(kTextLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NCHAR_STRING {
        auto tmp1 = $1;
        res = new IR(kTextLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | UNDERSCORE_CHARSET TEXT_STRING {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTextLiteral, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | text_literal TEXT_STRING_literal {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTextLiteral, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


text_string:

    TEXT_STRING_literal {
        auto tmp1 = $1;
        res = new IR(kTextString, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | hex_or_bin_String {
        auto tmp1 = $1;
        res = new IR(kTextString, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



hex_or_bin_String:

    HEX_NUM {
        auto tmp1 = $1;
        res = new IR(kHexOrBinString, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | HEX_STRING {
        auto tmp1 = $1;
        res = new IR(kHexOrBinString, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | BIN_NUM {
        auto tmp1 = $1;
        res = new IR(kHexOrBinString, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


param_marker:

    PARAM_MARKER {
        auto tmp1 = $1;
        res = new IR(kParamMarker, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | COLON_ORACLE_SYM ident_cli {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kParamMarker, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | COLON_ORACLE_SYM NUM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kParamMarker, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


signed_literal:

    '+' NUM_literal {
        auto tmp1 = $2;
        res = new IR(kSignedLiteral, OP3("+", "", ""), tmp1);
        $$ = res;
    }

    | '-' NUM_literal {
        auto tmp1 = $2;
        res = new IR(kSignedLiteral, OP3("-", "", ""), tmp1);
        $$ = res;
    }

;


literal:

    text_literal {
        auto tmp1 = $1;
        res = new IR(kLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NUM_literal {
        auto tmp1 = $1;
        res = new IR(kLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | temporal_literal {
        auto tmp1 = $1;
        res = new IR(kLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NULL_SYM {
        res = new IR(kLiteral, OP3("NULL_SYM", "", ""));
        $$ = res;
    }

    | FALSE_SYM {
        res = new IR(kLiteral, OP3("FALSE_SYM", "", ""));
        $$ = res;
    }

    | TRUE_SYM {
        res = new IR(kLiteral, OP3("TRUE_SYM", "", ""));
        $$ = res;
    }

    | HEX_NUM {
        auto tmp1 = $1;
        res = new IR(kLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | HEX_STRING {
        auto tmp1 = $1;
        res = new IR(kLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | BIN_NUM {
        auto tmp1 = $1;
        res = new IR(kLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | UNDERSCORE_CHARSET hex_or_bin_String {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kLiteral, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


NUM_literal:

    NUM {
        auto tmp1 = $1;
        res = new IR(kNUMLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LONG_NUM {
        auto tmp1 = $1;
        res = new IR(kNUMLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ULONGLONG_NUM {
        auto tmp1 = $1;
        res = new IR(kNUMLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DECIMAL_NUM {
        auto tmp1 = $1;
        res = new IR(kNUMLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FLOAT_NUM {
        auto tmp1 = $1;
        res = new IR(kNUMLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



temporal_literal:

    DATE_SYM TEXT_STRING {
        auto tmp1 = $2;
        res = new IR(kTemporalLiteral, OP3("DATE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | TIME_SYM TEXT_STRING {
        auto tmp1 = $2;
        res = new IR(kTemporalLiteral, OP3("TIME_SYM", "", ""), tmp1);
        $$ = res;
    }

    | TIMESTAMP TEXT_STRING {
        auto tmp1 = $2;
        res = new IR(kTemporalLiteral, OP3("TIMESTAMP", "", ""), tmp1);
        $$ = res;
    }

;


with_clause:

    WITH opt_recursive {} with_list {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kWithClause_1, OP3("WITH", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kWithClause, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;



opt_recursive:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptRecursive, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RECURSIVE_SYM {
        res = new IR(kOptRecursive, OP3("RECURSIVE_SYM", "", ""));
        $$ = res;
    }

;



with_list:

    with_list_element {
        auto tmp1 = $1;
        res = new IR(kWithList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | with_list ',' with_list_element {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kWithList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;



with_list_element:

    with_element_head opt_with_column_list AS '(' query_expression ')' opt_cycle {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kWithListElement_1, OP3("", "", "AS ("), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kWithListElement_2, OP3("", "", ")"), res, tmp3);
        PUSH(res);
        auto tmp4 = $7;
        res = new IR(kWithListElement, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


opt_cycle:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptCycle, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CYCLE_SYM {} comma_separated_ident_list RESTRICT {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptCycle, OP3("CYCLE_SYM", "", "RESTRICT"), tmp1, tmp2);
        $$ = res;
    }

;



opt_with_column_list:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptWithColumnList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' with_column_list ')' {
        auto tmp1 = $2;
        res = new IR(kOptWithColumnList, OP3("(", ")", ""), tmp1);
        $$ = res;
    }

;


with_column_list:

    comma_separated_ident_list {
        auto tmp1 = $1;
        res = new IR(kWithColumnList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ident_sys_alloc:

    ident_cli {
        auto tmp1 = $1;
        res = new IR(kIdentSysAlloc, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


comma_separated_ident_list:

    ident_sys_alloc {
        auto tmp1 = $1;
        res = new IR(kCommaSeparatedIdentList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | comma_separated_ident_list ',' ident_sys_alloc {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kCommaSeparatedIdentList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;



with_element_head:

    ident {
        auto tmp1 = $1;
        res = new IR(kWithElementHead, OP3("", "", ""), tmp1);
        $$ = res;
    }

;






insert_ident:

    simple_ident_nospvar {
        auto tmp1 = $1;
        res = new IR(kInsertIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_wild {
        auto tmp1 = $1;
        res = new IR(kInsertIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


table_wild:

    ident '.' '*' {
        auto tmp1 = $1;
        res = new IR(kTableWild, OP3("", ". *", ""), tmp1);
        $$ = res;
    }

    | ident '.' ident '.' '*' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableWild, OP3("", ".", ". *"), tmp1, tmp2);
        $$ = res;
    }

;


select_sublist_qualified_asterisk:

    ident_cli '.' '*' {
        auto tmp1 = $1;
        res = new IR(kSelectSublistQualifiedAsterisk, OP3("", ". *", ""), tmp1);
        $$ = res;
    }

    | ident_cli '.' ident_cli '.' '*' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSelectSublistQualifiedAsterisk, OP3("", ".", ". *"), tmp1, tmp2);
        $$ = res;
    }

;


order_ident:

    expr {
        auto tmp1 = $1;
        res = new IR(kOrderIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



simple_ident:

    ident_cli {
        auto tmp1 = $1;
        res = new IR(kSimpleIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_cli '.' ident_cli {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleIdent, OP3("", ".", ""), tmp1, tmp2);
        $$ = res;
    }

    | '.' ident_cli '.' ident_cli {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kSimpleIdent, OP3(".", ".", ""), tmp1, tmp2);
        $$ = res;
    }

    | ident_cli '.' ident_cli '.' ident_cli {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleIdent_1, OP3("", ".", "."), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kSimpleIdent, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | COLON_ORACLE_SYM ident_cli '.' ident_cli {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleIdent_2, OP3("", "", "."), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSimpleIdent, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


simple_ident_nospvar:

    ident {
        auto tmp1 = $1;
        res = new IR(kSimpleIdentNospvar, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident '.' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleIdentNospvar, OP3("", ".", ""), tmp1, tmp2);
        $$ = res;
    }

    | COLON_ORACLE_SYM ident_cli '.' ident_cli {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSimpleIdentNospvar_1, OP3("", "", "."), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSimpleIdentNospvar, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | '.' ident '.' ident {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kSimpleIdentNospvar, OP3(".", ".", ""), tmp1, tmp2);
        $$ = res;
    }

    | ident '.' ident '.' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSimpleIdentNospvar_2, OP3("", ".", "."), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kSimpleIdentNospvar, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


field_ident:

    ident {
        auto tmp1 = $1;
        res = new IR(kFieldIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident '.' ident '.' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFieldIdent_1, OP3("", ".", "."), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kFieldIdent, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ident '.' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kFieldIdent, OP3("", ".", ""), tmp1, tmp2);
        $$ = res;
    }

    | '.' ident {
        auto tmp1 = $2;
        res = new IR(kFieldIdent, OP3(".", "", ""), tmp1);
        $$ = res;
    }

;


table_ident:

    ident {
        auto tmp1 = $1;
        res = new IR(kTableIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident '.' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableIdent, OP3("", ".", ""), tmp1, tmp2);
        $$ = res;
    }

    | '.' ident {
        auto tmp1 = $2;
        res = new IR(kTableIdent, OP3(".", "", ""), tmp1);
        $$ = res;
    }

;


table_ident_opt_wild:

    ident opt_wild {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableIdentOptWild, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ident '.' ident opt_wild {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableIdentOptWild_1, OP3("", ".", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kTableIdentOptWild, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


table_ident_nodb:

    ident {
        auto tmp1 = $1;
        res = new IR(kTableIdentNodb, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


IDENT_cli:

    IDENT {
        auto tmp1 = $1;
        res = new IR(kIDENTCli, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IDENT_QUOTED {
        auto tmp1 = $1;
        res = new IR(kIDENTCli, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ident_cli:

    IDENT {
        auto tmp1 = $1;
        res = new IR(kIdentCli, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IDENT_QUOTED {
        auto tmp1 = $1;
        res = new IR(kIdentCli, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_ident {
        auto tmp1 = $1;
        res = new IR(kIdentCli, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


IDENT_sys:

    IDENT_cli {
        auto tmp1 = $1;
        res = new IR(kIDENTSys, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


TEXT_STRING_sys:

    TEXT_STRING {
        auto tmp1 = $1;
        res = new IR(kTEXTSTRINGSys, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


TEXT_STRING_literal:

    TEXT_STRING {
        auto tmp1 = $1;
        res = new IR(kTEXTSTRINGLiteral, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


TEXT_STRING_filesystem:

    TEXT_STRING {
        auto tmp1 = $1;
        res = new IR(kTEXTSTRINGFilesystem, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ident_table_alias:

    IDENT_sys {
        auto tmp1 = $1;
        res = new IR(kIdentTableAlias, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_table_alias {
        auto tmp1 = $1;
        res = new IR(kIdentTableAlias, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ident_cli_set_usual_case:

    IDENT_cli {
        auto tmp1 = $1;
        res = new IR(kIdentCliSetUsualCase, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_set_usual_case {
        auto tmp1 = $1;
        res = new IR(kIdentCliSetUsualCase, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ident_sysvar_name:

    IDENT_sys {
        auto tmp1 = $1;
        res = new IR(kIdentSysvarName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sysvar_name {
        auto tmp1 = $1;
        res = new IR(kIdentSysvarName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TEXT_STRING_sys {
        auto tmp1 = $1;
        res = new IR(kIdentSysvarName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



ident:

    IDENT_sys {
        auto tmp1 = $1;
        res = new IR(kIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_ident {
        auto tmp1 = $1;
        res = new IR(kIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


label_ident:

    IDENT_sys {
        auto tmp1 = $1;
        res = new IR(kLabelIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_label {
        auto tmp1 = $1;
        res = new IR(kLabelIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ident_or_text:

    ident {
        auto tmp1 = $1;
        res = new IR(kIdentOrText, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TEXT_STRING_sys {
        auto tmp1 = $1;
        res = new IR(kIdentOrText, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LEX_HOSTNAME {
        auto tmp1 = $1;
        res = new IR(kIdentOrText, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


user_maybe_role:

    ident_or_text {
        auto tmp1 = $1;
        res = new IR(kUserMaybeRole, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_or_text '@' ident_or_text {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUserMaybeRole, OP3("", "@", ""), tmp1, tmp2);
        $$ = res;
    }

    | CURRENT_USER optional_braces {
        auto tmp1 = $2;
        res = new IR(kUserMaybeRole, OP3("CURRENT_USER", "", ""), tmp1);
        $$ = res;
    }

;


user_or_role:

    user_maybe_role | current_role {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kUserOrRole_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kUserOrRole, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


user:

    user_maybe_role {
        auto tmp1 = $1;
        res = new IR(kUser, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



keyword_table_alias:

    keyword_data_type {
        auto tmp1 = $1;
        res = new IR(kKeywordTableAlias, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_cast_type {
        auto tmp1 = $1;
        res = new IR(kKeywordTableAlias, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_set_special_case {
        auto tmp1 = $1;
        res = new IR(kKeywordTableAlias, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_block_section {
        auto tmp1 = $1;
        res = new IR(kKeywordTableAlias, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_head {
        auto tmp1 = $1;
        res = new IR(kKeywordTableAlias, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_var_and_label {
        auto tmp1 = $1;
        res = new IR(kKeywordTableAlias, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_var_not_label {
        auto tmp1 = $1;
        res = new IR(kKeywordTableAlias, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sysvar_type {
        auto tmp1 = $1;
        res = new IR(kKeywordTableAlias, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_verb_clause {
        auto tmp1 = $1;
        res = new IR(kKeywordTableAlias, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FUNCTION_SYM {
        res = new IR(kKeywordTableAlias, OP3("FUNCTION_SYM", "", ""));
        $$ = res;
    }

    | EXCEPTION_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kKeywordTableAlias, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IGNORED_SYM {
        res = new IR(kKeywordTableAlias, OP3("IGNORED_SYM", "", ""));
        $$ = res;
    }

;



keyword_ident:

    keyword_data_type {
        auto tmp1 = $1;
        res = new IR(kKeywordIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_cast_type {
        auto tmp1 = $1;
        res = new IR(kKeywordIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_set_special_case {
        auto tmp1 = $1;
        res = new IR(kKeywordIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_block_section {
        auto tmp1 = $1;
        res = new IR(kKeywordIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_head {
        auto tmp1 = $1;
        res = new IR(kKeywordIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_var_and_label {
        auto tmp1 = $1;
        res = new IR(kKeywordIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_var_not_label {
        auto tmp1 = $1;
        res = new IR(kKeywordIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sysvar_type {
        auto tmp1 = $1;
        res = new IR(kKeywordIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_verb_clause {
        auto tmp1 = $1;
        res = new IR(kKeywordIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FUNCTION_SYM {
        res = new IR(kKeywordIdent, OP3("FUNCTION_SYM", "", ""));
        $$ = res;
    }

    | WINDOW_SYM {
        res = new IR(kKeywordIdent, OP3("WINDOW_SYM", "", ""));
        $$ = res;
    }

    | EXCEPTION_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kKeywordIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IGNORED_SYM {
        res = new IR(kKeywordIdent, OP3("IGNORED_SYM", "", ""));
        $$ = res;
    }

;


keyword_sysvar_name:

    keyword_data_type {
        auto tmp1 = $1;
        res = new IR(kKeywordSysvarName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_cast_type {
        auto tmp1 = $1;
        res = new IR(kKeywordSysvarName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_set_special_case {
        auto tmp1 = $1;
        res = new IR(kKeywordSysvarName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_block_section {
        auto tmp1 = $1;
        res = new IR(kKeywordSysvarName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_head {
        auto tmp1 = $1;
        res = new IR(kKeywordSysvarName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_var_and_label {
        auto tmp1 = $1;
        res = new IR(kKeywordSysvarName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_var_not_label {
        auto tmp1 = $1;
        res = new IR(kKeywordSysvarName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_verb_clause {
        auto tmp1 = $1;
        res = new IR(kKeywordSysvarName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FUNCTION_SYM {
        res = new IR(kKeywordSysvarName, OP3("FUNCTION_SYM", "", ""));
        $$ = res;
    }

    | WINDOW_SYM {
        res = new IR(kKeywordSysvarName, OP3("WINDOW_SYM", "", ""));
        $$ = res;
    }

    | EXCEPTION_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kKeywordSysvarName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IGNORED_SYM {
        res = new IR(kKeywordSysvarName, OP3("IGNORED_SYM", "", ""));
        $$ = res;
    }

    | OFFSET_SYM {
        res = new IR(kKeywordSysvarName, OP3("OFFSET_SYM", "", ""));
        $$ = res;
    }

;


keyword_set_usual_case:

    keyword_data_type {
        auto tmp1 = $1;
        res = new IR(kKeywordSetUsualCase, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_cast_type {
        auto tmp1 = $1;
        res = new IR(kKeywordSetUsualCase, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_block_section {
        auto tmp1 = $1;
        res = new IR(kKeywordSetUsualCase, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_head {
        auto tmp1 = $1;
        res = new IR(kKeywordSetUsualCase, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_var_and_label {
        auto tmp1 = $1;
        res = new IR(kKeywordSetUsualCase, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_var_not_label {
        auto tmp1 = $1;
        res = new IR(kKeywordSetUsualCase, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sysvar_type {
        auto tmp1 = $1;
        res = new IR(kKeywordSetUsualCase, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_verb_clause {
        auto tmp1 = $1;
        res = new IR(kKeywordSetUsualCase, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FUNCTION_SYM {
        res = new IR(kKeywordSetUsualCase, OP3("FUNCTION_SYM", "", ""));
        $$ = res;
    }

    | WINDOW_SYM {
        res = new IR(kKeywordSetUsualCase, OP3("WINDOW_SYM", "", ""));
        $$ = res;
    }

    | EXCEPTION_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kKeywordSetUsualCase, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IGNORED_SYM {
        res = new IR(kKeywordSetUsualCase, OP3("IGNORED_SYM", "", ""));
        $$ = res;
    }

    | OFFSET_SYM {
        res = new IR(kKeywordSetUsualCase, OP3("OFFSET_SYM", "", ""));
        $$ = res;
    }

;


non_reserved_keyword_udt:

    keyword_sp_var_not_label {
        auto tmp1 = $1;
        res = new IR(kNonReservedKeywordUdt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_head {
        auto tmp1 = $1;
        res = new IR(kNonReservedKeywordUdt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_verb_clause {
        auto tmp1 = $1;
        res = new IR(kNonReservedKeywordUdt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_set_special_case {
        auto tmp1 = $1;
        res = new IR(kNonReservedKeywordUdt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_block_section {
        auto tmp1 = $1;
        res = new IR(kNonReservedKeywordUdt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sysvar_type {
        auto tmp1 = $1;
        res = new IR(kNonReservedKeywordUdt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_var_and_label {
        auto tmp1 = $1;
        res = new IR(kNonReservedKeywordUdt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | OFFSET_SYM {
        res = new IR(kNonReservedKeywordUdt, OP3("OFFSET_SYM", "", ""));
        $$ = res;
    }

;



keyword_sp_var_not_label:

    ASCII_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("ASCII_SYM", "", ""));
        $$ = res;
    }

    | BACKUP_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("BACKUP_SYM", "", ""));
        $$ = res;
    }

    | BINLOG_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("BINLOG_SYM", "", ""));
        $$ = res;
    }

    | BYTE_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("BYTE_SYM", "", ""));
        $$ = res;
    }

    | CACHE_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("CACHE_SYM", "", ""));
        $$ = res;
    }

    | CHECKSUM_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("CHECKSUM_SYM", "", ""));
        $$ = res;
    }

    | CHECKPOINT_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("CHECKPOINT_SYM", "", ""));
        $$ = res;
    }

    | COLUMN_ADD_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("COLUMN_ADD_SYM", "", ""));
        $$ = res;
    }

    | COLUMN_CHECK_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("COLUMN_CHECK_SYM", "", ""));
        $$ = res;
    }

    | COLUMN_CREATE_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("COLUMN_CREATE_SYM", "", ""));
        $$ = res;
    }

    | COLUMN_DELETE_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("COLUMN_DELETE_SYM", "", ""));
        $$ = res;
    }

    | COLUMN_GET_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("COLUMN_GET_SYM", "", ""));
        $$ = res;
    }

    | COMMENT_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("COMMENT_SYM", "", ""));
        $$ = res;
    }

    | COMPRESSED_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("COMPRESSED_SYM", "", ""));
        $$ = res;
    }

    | DEALLOCATE_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("DEALLOCATE_SYM", "", ""));
        $$ = res;
    }

    | EXAMINED_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("EXAMINED_SYM", "", ""));
        $$ = res;
    }

    | EXCLUDE_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("EXCLUDE_SYM", "", ""));
        $$ = res;
    }

    | EXECUTE_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("EXECUTE_SYM", "", ""));
        $$ = res;
    }

    | FLUSH_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("FLUSH_SYM", "", ""));
        $$ = res;
    }

    | FOLLOWING_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("FOLLOWING_SYM", "", ""));
        $$ = res;
    }

    | FORMAT_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("FORMAT_SYM", "", ""));
        $$ = res;
    }

    | GET_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("GET_SYM", "", ""));
        $$ = res;
    }

    | HELP_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("HELP_SYM", "", ""));
        $$ = res;
    }

    | HOST_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("HOST_SYM", "", ""));
        $$ = res;
    }

    | INSTALL_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("INSTALL_SYM", "", ""));
        $$ = res;
    }

    | OPTION {
        res = new IR(kKeywordSpVarNotLabel, OP3("OPTION", "", ""));
        $$ = res;
    }

    | OPTIONS_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("OPTIONS_SYM", "", ""));
        $$ = res;
    }

    | OTHERS_MARIADB_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("OTHERS_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | OWNER_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("OWNER_SYM", "", ""));
        $$ = res;
    }

    | PARSER_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("PARSER_SYM", "", ""));
        $$ = res;
    }

    | PERIOD_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("PERIOD_SYM", "", ""));
        $$ = res;
    }

    | PORT_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("PORT_SYM", "", ""));
        $$ = res;
    }

    | PRECEDING_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("PRECEDING_SYM", "", ""));
        $$ = res;
    }

    | PREPARE_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("PREPARE_SYM", "", ""));
        $$ = res;
    }

    | REMOVE_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("REMOVE_SYM", "", ""));
        $$ = res;
    }

    | RESET_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("RESET_SYM", "", ""));
        $$ = res;
    }

    | RESTORE_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("RESTORE_SYM", "", ""));
        $$ = res;
    }

    | SECURITY_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("SECURITY_SYM", "", ""));
        $$ = res;
    }

    | SERVER_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("SERVER_SYM", "", ""));
        $$ = res;
    }

    | SOCKET_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("SOCKET_SYM", "", ""));
        $$ = res;
    }

    | SLAVE {
        res = new IR(kKeywordSpVarNotLabel, OP3("SLAVE", "", ""));
        $$ = res;
    }

    | SLAVES {
        res = new IR(kKeywordSpVarNotLabel, OP3("SLAVES", "", ""));
        $$ = res;
    }

    | SONAME_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("SONAME_SYM", "", ""));
        $$ = res;
    }

    | START_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("START_SYM", "", ""));
        $$ = res;
    }

    | STOP_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("STOP_SYM", "", ""));
        $$ = res;
    }

    | STORED_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("STORED_SYM", "", ""));
        $$ = res;
    }

    | TIES_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("TIES_SYM", "", ""));
        $$ = res;
    }

    | UNICODE_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("UNICODE_SYM", "", ""));
        $$ = res;
    }

    | UNINSTALL_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("UNINSTALL_SYM", "", ""));
        $$ = res;
    }

    | UNBOUNDED_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("UNBOUNDED_SYM", "", ""));
        $$ = res;
    }

    | WITHIN {
        res = new IR(kKeywordSpVarNotLabel, OP3("WITHIN", "", ""));
        $$ = res;
    }

    | WRAPPER_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("WRAPPER_SYM", "", ""));
        $$ = res;
    }

    | XA_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("XA_SYM", "", ""));
        $$ = res;
    }

    | UPGRADE_SYM {
        res = new IR(kKeywordSpVarNotLabel, OP3("UPGRADE_SYM", "", ""));
        $$ = res;
    }

;



keyword_sp_head:

    CONTAINS_SYM {
        res = new IR(kKeywordSpHead, OP3("CONTAINS_SYM", "", ""));
        $$ = res;
    }

    | LANGUAGE_SYM {
        res = new IR(kKeywordSpHead, OP3("LANGUAGE_SYM", "", ""));
        $$ = res;
    }

    | NO_SYM {
        res = new IR(kKeywordSpHead, OP3("NO_SYM", "", ""));
        $$ = res;
    }

    | CHARSET {
        res = new IR(kKeywordSpHead, OP3("CHARSET", "", ""));
        $$ = res;
    }

    | FOLLOWS_SYM {
        res = new IR(kKeywordSpHead, OP3("FOLLOWS_SYM", "", ""));
        $$ = res;
    }

    | PRECEDES_SYM {
        res = new IR(kKeywordSpHead, OP3("PRECEDES_SYM", "", ""));
        $$ = res;
    }

;



keyword_verb_clause:

    CLOSE_SYM {
        res = new IR(kKeywordVerbClause, OP3("CLOSE_SYM", "", ""));
        $$ = res;
    }

    | COMMIT_SYM {
        res = new IR(kKeywordVerbClause, OP3("COMMIT_SYM", "", ""));
        $$ = res;
    }

    | DO_SYM {
        res = new IR(kKeywordVerbClause, OP3("DO_SYM", "", ""));
        $$ = res;
    }

    | HANDLER_SYM {
        res = new IR(kKeywordVerbClause, OP3("HANDLER_SYM", "", ""));
        $$ = res;
    }

    | OPEN_SYM {
        res = new IR(kKeywordVerbClause, OP3("OPEN_SYM", "", ""));
        $$ = res;
    }

    | REPAIR {
        res = new IR(kKeywordVerbClause, OP3("REPAIR", "", ""));
        $$ = res;
    }

    | ROLLBACK_SYM {
        res = new IR(kKeywordVerbClause, OP3("ROLLBACK_SYM", "", ""));
        $$ = res;
    }

    | SAVEPOINT_SYM {
        res = new IR(kKeywordVerbClause, OP3("SAVEPOINT_SYM", "", ""));
        $$ = res;
    }

    | SHUTDOWN {
        res = new IR(kKeywordVerbClause, OP3("SHUTDOWN", "", ""));
        $$ = res;
    }

    | TRUNCATE_SYM {
        res = new IR(kKeywordVerbClause, OP3("TRUNCATE_SYM", "", ""));
        $$ = res;
    }

;


keyword_set_special_case:

    NAMES_SYM {
        res = new IR(kKeywordSetSpecialCase, OP3("NAMES_SYM", "", ""));
        $$ = res;
    }

    | ROLE_SYM {
        res = new IR(kKeywordSetSpecialCase, OP3("ROLE_SYM", "", ""));
        $$ = res;
    }

    | PASSWORD_SYM {
        res = new IR(kKeywordSetSpecialCase, OP3("PASSWORD_SYM", "", ""));
        $$ = res;
    }

;


keyword_sysvar_type:

    GLOBAL_SYM {
        res = new IR(kKeywordSysvarType, OP3("GLOBAL_SYM", "", ""));
        $$ = res;
    }

    | LOCAL_SYM {
        res = new IR(kKeywordSysvarType, OP3("LOCAL_SYM", "", ""));
        $$ = res;
    }

    | SESSION_SYM {
        res = new IR(kKeywordSysvarType, OP3("SESSION_SYM", "", ""));
        $$ = res;
    }

;




keyword_data_type:

    BIT_SYM {
        res = new IR(kKeywordDataType, OP3("BIT_SYM", "", ""));
        $$ = res;
    }

    | BOOLEAN_SYM {
        res = new IR(kKeywordDataType, OP3("BOOLEAN_SYM", "", ""));
        $$ = res;
    }

    | BOOL_SYM {
        res = new IR(kKeywordDataType, OP3("BOOL_SYM", "", ""));
        $$ = res;
    }

    | CLOB_MARIADB_SYM {
        res = new IR(kKeywordDataType, OP3("CLOB_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | CLOB_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kKeywordDataType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DATE_SYM %prec PREC_BELOW_CONTRACTION_TOKEN2 {
        res = new IR(kKeywordDataType, OP3("DATE_SYM", "", ""));
        $$ = res;
    }

    | DATETIME {
        res = new IR(kKeywordDataType, OP3("DATETIME", "", ""));
        $$ = res;
    }

    | ENUM {
        res = new IR(kKeywordDataType, OP3("ENUM", "", ""));
        $$ = res;
    }

    | FIXED_SYM {
        res = new IR(kKeywordDataType, OP3("FIXED_SYM", "", ""));
        $$ = res;
    }

    | JSON_SYM {
        res = new IR(kKeywordDataType, OP3("JSON_SYM", "", ""));
        $$ = res;
    }

    | MEDIUM_SYM {
        res = new IR(kKeywordDataType, OP3("MEDIUM_SYM", "", ""));
        $$ = res;
    }

    | NATIONAL_SYM {
        res = new IR(kKeywordDataType, OP3("NATIONAL_SYM", "", ""));
        $$ = res;
    }

    | NCHAR_SYM {
        res = new IR(kKeywordDataType, OP3("NCHAR_SYM", "", ""));
        $$ = res;
    }

    | NUMBER_MARIADB_SYM {
        res = new IR(kKeywordDataType, OP3("NUMBER_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | NUMBER_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kKeywordDataType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NVARCHAR_SYM {
        res = new IR(kKeywordDataType, OP3("NVARCHAR_SYM", "", ""));
        $$ = res;
    }

    | RAW_MARIADB_SYM {
        res = new IR(kKeywordDataType, OP3("RAW_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | RAW_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kKeywordDataType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ROW_SYM {
        res = new IR(kKeywordDataType, OP3("ROW_SYM", "", ""));
        $$ = res;
    }

    | SERIAL_SYM {
        res = new IR(kKeywordDataType, OP3("SERIAL_SYM", "", ""));
        $$ = res;
    }

    | TEXT_SYM {
        res = new IR(kKeywordDataType, OP3("TEXT_SYM", "", ""));
        $$ = res;
    }

    | TIMESTAMP %prec PREC_BELOW_CONTRACTION_TOKEN2 {
        res = new IR(kKeywordDataType, OP3("TIMESTAMP", "", ""));
        $$ = res;
    }

    | TIME_SYM %prec PREC_BELOW_CONTRACTION_TOKEN2 {
        res = new IR(kKeywordDataType, OP3("TIME_SYM", "", ""));
        $$ = res;
    }

    | VARCHAR2_MARIADB_SYM {
        res = new IR(kKeywordDataType, OP3("VARCHAR2_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | VARCHAR2_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kKeywordDataType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | YEAR_SYM {
        res = new IR(kKeywordDataType, OP3("YEAR_SYM", "", ""));
        $$ = res;
    }

;



keyword_cast_type:

    SIGNED_SYM {
        res = new IR(kKeywordCastType, OP3("SIGNED_SYM", "", ""));
        $$ = res;
    }

;




keyword_sp_var_and_label:

    ACTION {
        res = new IR(kKeywordSpVarAndLabel, OP3("ACTION", "", ""));
        $$ = res;
    }

    | ACCOUNT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ACCOUNT_SYM", "", ""));
        $$ = res;
    }

    | ADDDATE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ADDDATE_SYM", "", ""));
        $$ = res;
    }

    | ADD_MONTHS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ADD_MONTHS_SYM", "", ""));
        $$ = res;
    }

    | ADMIN_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ADMIN_SYM", "", ""));
        $$ = res;
    }

    | AFTER_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("AFTER_SYM", "", ""));
        $$ = res;
    }

    | AGAINST {
        res = new IR(kKeywordSpVarAndLabel, OP3("AGAINST", "", ""));
        $$ = res;
    }

    | AGGREGATE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("AGGREGATE_SYM", "", ""));
        $$ = res;
    }

    | ALGORITHM_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ALGORITHM_SYM", "", ""));
        $$ = res;
    }

    | ALWAYS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ALWAYS_SYM", "", ""));
        $$ = res;
    }

    | ANY_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ANY_SYM", "", ""));
        $$ = res;
    }

    | AT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("AT_SYM", "", ""));
        $$ = res;
    }

    | ATOMIC_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ATOMIC_SYM", "", ""));
        $$ = res;
    }

    | AUTHORS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("AUTHORS_SYM", "", ""));
        $$ = res;
    }

    | AUTO_INC {
        res = new IR(kKeywordSpVarAndLabel, OP3("AUTO_INC", "", ""));
        $$ = res;
    }

    | AUTOEXTEND_SIZE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("AUTOEXTEND_SIZE_SYM", "", ""));
        $$ = res;
    }

    | AUTO_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("AUTO_SYM", "", ""));
        $$ = res;
    }

    | AVG_ROW_LENGTH {
        res = new IR(kKeywordSpVarAndLabel, OP3("AVG_ROW_LENGTH", "", ""));
        $$ = res;
    }

    | AVG_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("AVG_SYM", "", ""));
        $$ = res;
    }

    | BLOCK_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("BLOCK_SYM", "", ""));
        $$ = res;
    }

    | BODY_MARIADB_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("BODY_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | BTREE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("BTREE_SYM", "", ""));
        $$ = res;
    }

    | CASCADED {
        res = new IR(kKeywordSpVarAndLabel, OP3("CASCADED", "", ""));
        $$ = res;
    }

    | CATALOG_NAME_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CATALOG_NAME_SYM", "", ""));
        $$ = res;
    }

    | CHAIN_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CHAIN_SYM", "", ""));
        $$ = res;
    }

    | CHANNEL_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CHANNEL_SYM", "", ""));
        $$ = res;
    }

    | CHANGED {
        res = new IR(kKeywordSpVarAndLabel, OP3("CHANGED", "", ""));
        $$ = res;
    }

    | CIPHER_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CIPHER_SYM", "", ""));
        $$ = res;
    }

    | CLIENT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CLIENT_SYM", "", ""));
        $$ = res;
    }

    | CLASS_ORIGIN_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CLASS_ORIGIN_SYM", "", ""));
        $$ = res;
    }

    | COALESCE {
        res = new IR(kKeywordSpVarAndLabel, OP3("COALESCE", "", ""));
        $$ = res;
    }

    | CODE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CODE_SYM", "", ""));
        $$ = res;
    }

    | COLLATION_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("COLLATION_SYM", "", ""));
        $$ = res;
    }

    | COLUMN_NAME_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("COLUMN_NAME_SYM", "", ""));
        $$ = res;
    }

    | COLUMNS {
        res = new IR(kKeywordSpVarAndLabel, OP3("COLUMNS", "", ""));
        $$ = res;
    }

    | COMMITTED_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("COMMITTED_SYM", "", ""));
        $$ = res;
    }

    | COMPACT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("COMPACT_SYM", "", ""));
        $$ = res;
    }

    | COMPLETION_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("COMPLETION_SYM", "", ""));
        $$ = res;
    }

    | CONCURRENT {
        res = new IR(kKeywordSpVarAndLabel, OP3("CONCURRENT", "", ""));
        $$ = res;
    }

    | CONNECTION_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CONNECTION_SYM", "", ""));
        $$ = res;
    }

    | CONSISTENT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CONSISTENT_SYM", "", ""));
        $$ = res;
    }

    | CONSTRAINT_CATALOG_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CONSTRAINT_CATALOG_SYM", "", ""));
        $$ = res;
    }

    | CONSTRAINT_SCHEMA_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CONSTRAINT_SCHEMA_SYM", "", ""));
        $$ = res;
    }

    | CONSTRAINT_NAME_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CONSTRAINT_NAME_SYM", "", ""));
        $$ = res;
    }

    | CONTEXT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CONTEXT_SYM", "", ""));
        $$ = res;
    }

    | CONTRIBUTORS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CONTRIBUTORS_SYM", "", ""));
        $$ = res;
    }

    | CURRENT_POS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CURRENT_POS_SYM", "", ""));
        $$ = res;
    }

    | CPU_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CPU_SYM", "", ""));
        $$ = res;
    }

    | CUBE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CUBE_SYM", "", ""));
        $$ = res;
    }

    | CURRENT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CURRENT_SYM", "", ""));
        $$ = res;
    }

    | CURSOR_NAME_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CURSOR_NAME_SYM", "", ""));
        $$ = res;
    }

    | CYCLE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("CYCLE_SYM", "", ""));
        $$ = res;
    }

    | DATA_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("DATA_SYM", "", ""));
        $$ = res;
    }

    | DATAFILE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("DATAFILE_SYM", "", ""));
        $$ = res;
    }

    | DATE_FORMAT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("DATE_FORMAT_SYM", "", ""));
        $$ = res;
    }

    | DAY_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("DAY_SYM", "", ""));
        $$ = res;
    }

    | DECODE_MARIADB_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("DECODE_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | DECODE_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kKeywordSpVarAndLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DEFINER_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("DEFINER_SYM", "", ""));
        $$ = res;
    }

    | DELAY_KEY_WRITE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("DELAY_KEY_WRITE_SYM", "", ""));
        $$ = res;
    }

    | DES_KEY_FILE {
        res = new IR(kKeywordSpVarAndLabel, OP3("DES_KEY_FILE", "", ""));
        $$ = res;
    }

    | DIAGNOSTICS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("DIAGNOSTICS_SYM", "", ""));
        $$ = res;
    }

    | DIRECTORY_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("DIRECTORY_SYM", "", ""));
        $$ = res;
    }

    | DISABLE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("DISABLE_SYM", "", ""));
        $$ = res;
    }

    | DISCARD {
        res = new IR(kKeywordSpVarAndLabel, OP3("DISCARD", "", ""));
        $$ = res;
    }

    | DISK_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("DISK_SYM", "", ""));
        $$ = res;
    }

    | DUMPFILE {
        res = new IR(kKeywordSpVarAndLabel, OP3("DUMPFILE", "", ""));
        $$ = res;
    }

    | DUPLICATE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("DUPLICATE_SYM", "", ""));
        $$ = res;
    }

    | DYNAMIC_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("DYNAMIC_SYM", "", ""));
        $$ = res;
    }

    | ELSEIF_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kKeywordSpVarAndLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ELSIF_MARIADB_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ELSIF_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | EMPTY_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("EMPTY_SYM", "", ""));
        $$ = res;
    }

    | ENDS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ENDS_SYM", "", ""));
        $$ = res;
    }

    | ENGINE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ENGINE_SYM", "", ""));
        $$ = res;
    }

    | ENGINES_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ENGINES_SYM", "", ""));
        $$ = res;
    }

    | ERROR_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ERROR_SYM", "", ""));
        $$ = res;
    }

    | ERRORS {
        res = new IR(kKeywordSpVarAndLabel, OP3("ERRORS", "", ""));
        $$ = res;
    }

    | ESCAPE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ESCAPE_SYM", "", ""));
        $$ = res;
    }

    | EVENT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("EVENT_SYM", "", ""));
        $$ = res;
    }

    | EVENTS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("EVENTS_SYM", "", ""));
        $$ = res;
    }

    | EVERY_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("EVERY_SYM", "", ""));
        $$ = res;
    }

    | EXCEPTION_MARIADB_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("EXCEPTION_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | EXCHANGE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("EXCHANGE_SYM", "", ""));
        $$ = res;
    }

    | EXPANSION_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("EXPANSION_SYM", "", ""));
        $$ = res;
    }

    | EXPIRE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("EXPIRE_SYM", "", ""));
        $$ = res;
    }

    | EXPORT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("EXPORT_SYM", "", ""));
        $$ = res;
    }

    | EXTENDED_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("EXTENDED_SYM", "", ""));
        $$ = res;
    }

    | EXTENT_SIZE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("EXTENT_SIZE_SYM", "", ""));
        $$ = res;
    }

    | FAULTS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("FAULTS_SYM", "", ""));
        $$ = res;
    }

    | FAST_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("FAST_SYM", "", ""));
        $$ = res;
    }

    | FOUND_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("FOUND_SYM", "", ""));
        $$ = res;
    }

    | ENABLE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ENABLE_SYM", "", ""));
        $$ = res;
    }

    | FEDERATED_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("FEDERATED_SYM", "", ""));
        $$ = res;
    }

    | FULL {
        res = new IR(kKeywordSpVarAndLabel, OP3("FULL", "", ""));
        $$ = res;
    }

    | FILE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("FILE_SYM", "", ""));
        $$ = res;
    }

    | FIRST_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("FIRST_SYM", "", ""));
        $$ = res;
    }

    | GENERAL {
        res = new IR(kKeywordSpVarAndLabel, OP3("GENERAL", "", ""));
        $$ = res;
    }

    | GENERATED_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("GENERATED_SYM", "", ""));
        $$ = res;
    }

    | GET_FORMAT {
        res = new IR(kKeywordSpVarAndLabel, OP3("GET_FORMAT", "", ""));
        $$ = res;
    }

    | GRANTS {
        res = new IR(kKeywordSpVarAndLabel, OP3("GRANTS", "", ""));
        $$ = res;
    }

    | GOTO_MARIADB_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("GOTO_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | HASH_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("HASH_SYM", "", ""));
        $$ = res;
    }

    | HARD_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("HARD_SYM", "", ""));
        $$ = res;
    }

    | HISTORY_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("HISTORY_SYM", "", ""));
        $$ = res;
    }

    | HOSTS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("HOSTS_SYM", "", ""));
        $$ = res;
    }

    | HOUR_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("HOUR_SYM", "", ""));
        $$ = res;
    }

    | ID_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ID_SYM", "", ""));
        $$ = res;
    }

    | IDENTIFIED_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("IDENTIFIED_SYM", "", ""));
        $$ = res;
    }

    | IGNORE_SERVER_IDS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("IGNORE_SERVER_IDS_SYM", "", ""));
        $$ = res;
    }

    | INCREMENT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("INCREMENT_SYM", "", ""));
        $$ = res;
    }

    | IMMEDIATE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("IMMEDIATE_SYM", "", ""));
        $$ = res;
    }

    | INVOKER_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("INVOKER_SYM", "", ""));
        $$ = res;
    }

    | IMPORT {
        res = new IR(kKeywordSpVarAndLabel, OP3("IMPORT", "", ""));
        $$ = res;
    }

    | INDEXES {
        res = new IR(kKeywordSpVarAndLabel, OP3("INDEXES", "", ""));
        $$ = res;
    }

    | INITIAL_SIZE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("INITIAL_SIZE_SYM", "", ""));
        $$ = res;
    }

    | IO_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("IO_SYM", "", ""));
        $$ = res;
    }

    | IPC_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("IPC_SYM", "", ""));
        $$ = res;
    }

    | ISOLATION {
        res = new IR(kKeywordSpVarAndLabel, OP3("ISOLATION", "", ""));
        $$ = res;
    }

    | ISOPEN_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ISOPEN_SYM", "", ""));
        $$ = res;
    }

    | ISSUER_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ISSUER_SYM", "", ""));
        $$ = res;
    }

    | INSERT_METHOD {
        res = new IR(kKeywordSpVarAndLabel, OP3("INSERT_METHOD", "", ""));
        $$ = res;
    }

    | INVISIBLE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("INVISIBLE_SYM", "", ""));
        $$ = res;
    }

    | JSON_TABLE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("JSON_TABLE_SYM", "", ""));
        $$ = res;
    }

    | KEY_BLOCK_SIZE {
        res = new IR(kKeywordSpVarAndLabel, OP3("KEY_BLOCK_SIZE", "", ""));
        $$ = res;
    }

    | LAST_VALUE {
        res = new IR(kKeywordSpVarAndLabel, OP3("LAST_VALUE", "", ""));
        $$ = res;
    }

    | LAST_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("LAST_SYM", "", ""));
        $$ = res;
    }

    | LASTVAL_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("LASTVAL_SYM", "", ""));
        $$ = res;
    }

    | LEAVES {
        res = new IR(kKeywordSpVarAndLabel, OP3("LEAVES", "", ""));
        $$ = res;
    }

    | LESS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("LESS_SYM", "", ""));
        $$ = res;
    }

    | LEVEL_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("LEVEL_SYM", "", ""));
        $$ = res;
    }

    | LIST_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("LIST_SYM", "", ""));
        $$ = res;
    }

    | LOCKED_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("LOCKED_SYM", "", ""));
        $$ = res;
    }

    | LOCKS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("LOCKS_SYM", "", ""));
        $$ = res;
    }

    | LOGFILE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("LOGFILE_SYM", "", ""));
        $$ = res;
    }

    | LOGS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("LOGS_SYM", "", ""));
        $$ = res;
    }

    | MAX_ROWS {
        res = new IR(kKeywordSpVarAndLabel, OP3("MAX_ROWS", "", ""));
        $$ = res;
    }

    | MASTER_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_SYM", "", ""));
        $$ = res;
    }

    | MASTER_HEARTBEAT_PERIOD_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_HEARTBEAT_PERIOD_SYM", "", ""));
        $$ = res;
    }

    | MASTER_GTID_POS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_GTID_POS_SYM", "", ""));
        $$ = res;
    }

    | MASTER_HOST_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_HOST_SYM", "", ""));
        $$ = res;
    }

    | MASTER_PORT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_PORT_SYM", "", ""));
        $$ = res;
    }

    | MASTER_LOG_FILE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_LOG_FILE_SYM", "", ""));
        $$ = res;
    }

    | MASTER_LOG_POS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_LOG_POS_SYM", "", ""));
        $$ = res;
    }

    | MASTER_USER_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_USER_SYM", "", ""));
        $$ = res;
    }

    | MASTER_USE_GTID_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_USE_GTID_SYM", "", ""));
        $$ = res;
    }

    | MASTER_PASSWORD_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_PASSWORD_SYM", "", ""));
        $$ = res;
    }

    | MASTER_SERVER_ID_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_SERVER_ID_SYM", "", ""));
        $$ = res;
    }

    | MASTER_CONNECT_RETRY_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_CONNECT_RETRY_SYM", "", ""));
        $$ = res;
    }

    | MASTER_DELAY_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_DELAY_SYM", "", ""));
        $$ = res;
    }

    | MASTER_SSL_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_SSL_SYM", "", ""));
        $$ = res;
    }

    | MASTER_SSL_CA_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_SSL_CA_SYM", "", ""));
        $$ = res;
    }

    | MASTER_SSL_CAPATH_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_SSL_CAPATH_SYM", "", ""));
        $$ = res;
    }

    | MASTER_SSL_CERT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_SSL_CERT_SYM", "", ""));
        $$ = res;
    }

    | MASTER_SSL_CIPHER_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_SSL_CIPHER_SYM", "", ""));
        $$ = res;
    }

    | MASTER_SSL_CRL_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_SSL_CRL_SYM", "", ""));
        $$ = res;
    }

    | MASTER_SSL_CRLPATH_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_SSL_CRLPATH_SYM", "", ""));
        $$ = res;
    }

    | MASTER_SSL_KEY_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MASTER_SSL_KEY_SYM", "", ""));
        $$ = res;
    }

    | MAX_CONNECTIONS_PER_HOUR {
        res = new IR(kKeywordSpVarAndLabel, OP3("MAX_CONNECTIONS_PER_HOUR", "", ""));
        $$ = res;
    }

    | MAX_QUERIES_PER_HOUR {
        res = new IR(kKeywordSpVarAndLabel, OP3("MAX_QUERIES_PER_HOUR", "", ""));
        $$ = res;
    }

    | MAX_SIZE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MAX_SIZE_SYM", "", ""));
        $$ = res;
    }

    | MAX_STATEMENT_TIME_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MAX_STATEMENT_TIME_SYM", "", ""));
        $$ = res;
    }

    | MAX_UPDATES_PER_HOUR {
        res = new IR(kKeywordSpVarAndLabel, OP3("MAX_UPDATES_PER_HOUR", "", ""));
        $$ = res;
    }

    | MAX_USER_CONNECTIONS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MAX_USER_CONNECTIONS_SYM", "", ""));
        $$ = res;
    }

    | MEMORY_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MEMORY_SYM", "", ""));
        $$ = res;
    }

    | MERGE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MERGE_SYM", "", ""));
        $$ = res;
    }

    | MESSAGE_TEXT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MESSAGE_TEXT_SYM", "", ""));
        $$ = res;
    }

    | MICROSECOND_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MICROSECOND_SYM", "", ""));
        $$ = res;
    }

    | MIGRATE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MIGRATE_SYM", "", ""));
        $$ = res;
    }

    | MINUTE_SYM %ifdef MARIADB {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kKeywordSpVarAndLabel, OP3("MINUTE_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | MINUS_ORACLE_SYM %endif {
        auto tmp1 = $2;
        res = new IR(kKeywordSpVarAndLabel, OP3("MINUS_ORACLE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | MINVALUE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MINVALUE_SYM", "", ""));
        $$ = res;
    }

    | MIN_ROWS {
        res = new IR(kKeywordSpVarAndLabel, OP3("MIN_ROWS", "", ""));
        $$ = res;
    }

    | MODIFY_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MODIFY_SYM", "", ""));
        $$ = res;
    }

    | MODE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MODE_SYM", "", ""));
        $$ = res;
    }

    | MONITOR_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MONITOR_SYM", "", ""));
        $$ = res;
    }

    | MONTH_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MONTH_SYM", "", ""));
        $$ = res;
    }

    | MUTEX_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MUTEX_SYM", "", ""));
        $$ = res;
    }

    | MYSQL_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MYSQL_SYM", "", ""));
        $$ = res;
    }

    | MYSQL_ERRNO_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("MYSQL_ERRNO_SYM", "", ""));
        $$ = res;
    }

    | NAME_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("NAME_SYM", "", ""));
        $$ = res;
    }

    | NESTED_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("NESTED_SYM", "", ""));
        $$ = res;
    }

    | NEVER_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("NEVER_SYM", "", ""));
        $$ = res;
    }

    | NEXT_SYM %prec PREC_BELOW_CONTRACTION_TOKEN2 {
        res = new IR(kKeywordSpVarAndLabel, OP3("NEXT_SYM", "", ""));
        $$ = res;
    }

    | NEXTVAL_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("NEXTVAL_SYM", "", ""));
        $$ = res;
    }

    | NEW_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("NEW_SYM", "", ""));
        $$ = res;
    }

    | NOCACHE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("NOCACHE_SYM", "", ""));
        $$ = res;
    }

    | NOCYCLE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("NOCYCLE_SYM", "", ""));
        $$ = res;
    }

    | NOMINVALUE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("NOMINVALUE_SYM", "", ""));
        $$ = res;
    }

    | NOMAXVALUE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("NOMAXVALUE_SYM", "", ""));
        $$ = res;
    }

    | NO_WAIT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("NO_WAIT_SYM", "", ""));
        $$ = res;
    }

    | NOWAIT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("NOWAIT_SYM", "", ""));
        $$ = res;
    }

    | NODEGROUP_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("NODEGROUP_SYM", "", ""));
        $$ = res;
    }

    | NONE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("NONE_SYM", "", ""));
        $$ = res;
    }

    | NOTFOUND_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("NOTFOUND_SYM", "", ""));
        $$ = res;
    }

    | OF_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("OF_SYM", "", ""));
        $$ = res;
    }

    | OLD_PASSWORD_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("OLD_PASSWORD_SYM", "", ""));
        $$ = res;
    }

    | ONE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ONE_SYM", "", ""));
        $$ = res;
    }

    | ONLINE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ONLINE_SYM", "", ""));
        $$ = res;
    }

    | ONLY_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ONLY_SYM", "", ""));
        $$ = res;
    }

    | ORDINALITY_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ORDINALITY_SYM", "", ""));
        $$ = res;
    }

    | OVERLAPS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("OVERLAPS_SYM", "", ""));
        $$ = res;
    }

    | PACKAGE_MARIADB_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("PACKAGE_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | PACK_KEYS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("PACK_KEYS_SYM", "", ""));
        $$ = res;
    }

    | PAGE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("PAGE_SYM", "", ""));
        $$ = res;
    }

    | PARTIAL {
        res = new IR(kKeywordSpVarAndLabel, OP3("PARTIAL", "", ""));
        $$ = res;
    }

    | PARTITIONING_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("PARTITIONING_SYM", "", ""));
        $$ = res;
    }

    | PARTITIONS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("PARTITIONS_SYM", "", ""));
        $$ = res;
    }

    | PATH_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("PATH_SYM", "", ""));
        $$ = res;
    }

    | PERSISTENT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("PERSISTENT_SYM", "", ""));
        $$ = res;
    }

    | PHASE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("PHASE_SYM", "", ""));
        $$ = res;
    }

    | PLUGIN_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("PLUGIN_SYM", "", ""));
        $$ = res;
    }

    | PLUGINS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("PLUGINS_SYM", "", ""));
        $$ = res;
    }

    | PRESERVE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("PRESERVE_SYM", "", ""));
        $$ = res;
    }

    | PREV_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("PREV_SYM", "", ""));
        $$ = res;
    }

    | PREVIOUS_SYM %prec PREC_BELOW_CONTRACTION_TOKEN2 {
        res = new IR(kKeywordSpVarAndLabel, OP3("PREVIOUS_SYM", "", ""));
        $$ = res;
    }

    | PRIVILEGES {
        res = new IR(kKeywordSpVarAndLabel, OP3("PRIVILEGES", "", ""));
        $$ = res;
    }

    | PROCESS {
        res = new IR(kKeywordSpVarAndLabel, OP3("PROCESS", "", ""));
        $$ = res;
    }

    | PROCESSLIST_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("PROCESSLIST_SYM", "", ""));
        $$ = res;
    }

    | PROFILE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("PROFILE_SYM", "", ""));
        $$ = res;
    }

    | PROFILES_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("PROFILES_SYM", "", ""));
        $$ = res;
    }

    | PROXY_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("PROXY_SYM", "", ""));
        $$ = res;
    }

    | QUARTER_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("QUARTER_SYM", "", ""));
        $$ = res;
    }

    | QUERY_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("QUERY_SYM", "", ""));
        $$ = res;
    }

    | QUICK {
        res = new IR(kKeywordSpVarAndLabel, OP3("QUICK", "", ""));
        $$ = res;
    }

    | RAISE_MARIADB_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("RAISE_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | READ_ONLY_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("READ_ONLY_SYM", "", ""));
        $$ = res;
    }

    | REBUILD_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("REBUILD_SYM", "", ""));
        $$ = res;
    }

    | RECOVER_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("RECOVER_SYM", "", ""));
        $$ = res;
    }

    | REDO_BUFFER_SIZE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("REDO_BUFFER_SIZE_SYM", "", ""));
        $$ = res;
    }

    | REDOFILE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("REDOFILE_SYM", "", ""));
        $$ = res;
    }

    | REDUNDANT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("REDUNDANT_SYM", "", ""));
        $$ = res;
    }

    | RELAY {
        res = new IR(kKeywordSpVarAndLabel, OP3("RELAY", "", ""));
        $$ = res;
    }

    | RELAYLOG_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("RELAYLOG_SYM", "", ""));
        $$ = res;
    }

    | RELAY_LOG_FILE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("RELAY_LOG_FILE_SYM", "", ""));
        $$ = res;
    }

    | RELAY_LOG_POS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("RELAY_LOG_POS_SYM", "", ""));
        $$ = res;
    }

    | RELAY_THREAD {
        res = new IR(kKeywordSpVarAndLabel, OP3("RELAY_THREAD", "", ""));
        $$ = res;
    }

    | RELOAD {
        res = new IR(kKeywordSpVarAndLabel, OP3("RELOAD", "", ""));
        $$ = res;
    }

    | REORGANIZE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("REORGANIZE_SYM", "", ""));
        $$ = res;
    }

    | REPEATABLE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("REPEATABLE_SYM", "", ""));
        $$ = res;
    }

    | REPLAY_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("REPLAY_SYM", "", ""));
        $$ = res;
    }

    | REPLICATION {
        res = new IR(kKeywordSpVarAndLabel, OP3("REPLICATION", "", ""));
        $$ = res;
    }

    | RESOURCES {
        res = new IR(kKeywordSpVarAndLabel, OP3("RESOURCES", "", ""));
        $$ = res;
    }

    | RESTART_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("RESTART_SYM", "", ""));
        $$ = res;
    }

    | RESUME_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("RESUME_SYM", "", ""));
        $$ = res;
    }

    | RETURNED_SQLSTATE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("RETURNED_SQLSTATE_SYM", "", ""));
        $$ = res;
    }

    | RETURNS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("RETURNS_SYM", "", ""));
        $$ = res;
    }

    | REUSE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("REUSE_SYM", "", ""));
        $$ = res;
    }

    | REVERSE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("REVERSE_SYM", "", ""));
        $$ = res;
    }

    | ROLLUP_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ROLLUP_SYM", "", ""));
        $$ = res;
    }

    | ROUTINE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ROUTINE_SYM", "", ""));
        $$ = res;
    }

    | ROWCOUNT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ROWCOUNT_SYM", "", ""));
        $$ = res;
    }

    | ROWTYPE_MARIADB_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ROWTYPE_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | ROW_COUNT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("ROW_COUNT_SYM", "", ""));
        $$ = res;
    }

    | ROW_FORMAT_SYM %ifdef MARIADB {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kKeywordSpVarAndLabel, OP3("ROW_FORMAT_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | ROWNUM_SYM %endif {
        auto tmp1 = $2;
        res = new IR(kKeywordSpVarAndLabel, OP3("ROWNUM_SYM", "", ""), tmp1);
        $$ = res;
    }

    | RTREE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("RTREE_SYM", "", ""));
        $$ = res;
    }

    | SCHEDULE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SCHEDULE_SYM", "", ""));
        $$ = res;
    }

    | SCHEMA_NAME_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SCHEMA_NAME_SYM", "", ""));
        $$ = res;
    }

    | SECOND_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SECOND_SYM", "", ""));
        $$ = res;
    }

    | SEQUENCE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SEQUENCE_SYM", "", ""));
        $$ = res;
    }

    | SERIALIZABLE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SERIALIZABLE_SYM", "", ""));
        $$ = res;
    }

    | SETVAL_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SETVAL_SYM", "", ""));
        $$ = res;
    }

    | SIMPLE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SIMPLE_SYM", "", ""));
        $$ = res;
    }

    | SHARE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SHARE_SYM", "", ""));
        $$ = res;
    }

    | SKIP_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SKIP_SYM", "", ""));
        $$ = res;
    }

    | SLAVE_POS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SLAVE_POS_SYM", "", ""));
        $$ = res;
    }

    | SLOW {
        res = new IR(kKeywordSpVarAndLabel, OP3("SLOW", "", ""));
        $$ = res;
    }

    | SNAPSHOT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SNAPSHOT_SYM", "", ""));
        $$ = res;
    }

    | SOFT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SOFT_SYM", "", ""));
        $$ = res;
    }

    | SOUNDS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SOUNDS_SYM", "", ""));
        $$ = res;
    }

    | SOURCE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SOURCE_SYM", "", ""));
        $$ = res;
    }

    | SQL_CACHE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SQL_CACHE_SYM", "", ""));
        $$ = res;
    }

    | SQL_BUFFER_RESULT {
        res = new IR(kKeywordSpVarAndLabel, OP3("SQL_BUFFER_RESULT", "", ""));
        $$ = res;
    }

    | SQL_NO_CACHE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SQL_NO_CACHE_SYM", "", ""));
        $$ = res;
    }

    | SQL_THREAD {
        res = new IR(kKeywordSpVarAndLabel, OP3("SQL_THREAD", "", ""));
        $$ = res;
    }

    | STAGE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("STAGE_SYM", "", ""));
        $$ = res;
    }

    | STARTS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("STARTS_SYM", "", ""));
        $$ = res;
    }

    | STATEMENT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("STATEMENT_SYM", "", ""));
        $$ = res;
    }

    | STATUS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("STATUS_SYM", "", ""));
        $$ = res;
    }

    | STORAGE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("STORAGE_SYM", "", ""));
        $$ = res;
    }

    | STRING_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("STRING_SYM", "", ""));
        $$ = res;
    }

    | SUBCLASS_ORIGIN_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SUBCLASS_ORIGIN_SYM", "", ""));
        $$ = res;
    }

    | SUBDATE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SUBDATE_SYM", "", ""));
        $$ = res;
    }

    | SUBJECT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SUBJECT_SYM", "", ""));
        $$ = res;
    }

    | SUBPARTITION_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SUBPARTITION_SYM", "", ""));
        $$ = res;
    }

    | SUBPARTITIONS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SUBPARTITIONS_SYM", "", ""));
        $$ = res;
    }

    | SUPER_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SUPER_SYM", "", ""));
        $$ = res;
    }

    | SUSPEND_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SUSPEND_SYM", "", ""));
        $$ = res;
    }

    | SWAPS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SWAPS_SYM", "", ""));
        $$ = res;
    }

    | SWITCHES_SYM %ifdef MARIADB {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kKeywordSpVarAndLabel, OP3("SWITCHES_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | SYSDATE %endif {
        auto tmp1 = $2;
        res = new IR(kKeywordSpVarAndLabel, OP3("SYSDATE", "", ""), tmp1);
        $$ = res;
    }

    | SYSTEM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SYSTEM", "", ""));
        $$ = res;
    }

    | SYSTEM_TIME_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("SYSTEM_TIME_SYM", "", ""));
        $$ = res;
    }

    | TABLE_NAME_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("TABLE_NAME_SYM", "", ""));
        $$ = res;
    }

    | TABLES {
        res = new IR(kKeywordSpVarAndLabel, OP3("TABLES", "", ""));
        $$ = res;
    }

    | TABLE_CHECKSUM_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("TABLE_CHECKSUM_SYM", "", ""));
        $$ = res;
    }

    | TABLESPACE {
        res = new IR(kKeywordSpVarAndLabel, OP3("TABLESPACE", "", ""));
        $$ = res;
    }

    | TEMPORARY {
        res = new IR(kKeywordSpVarAndLabel, OP3("TEMPORARY", "", ""));
        $$ = res;
    }

    | TEMPTABLE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("TEMPTABLE_SYM", "", ""));
        $$ = res;
    }

    | THAN_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("THAN_SYM", "", ""));
        $$ = res;
    }

    | TRANSACTION_SYM %prec PREC_BELOW_CONTRACTION_TOKEN2 {
        res = new IR(kKeywordSpVarAndLabel, OP3("TRANSACTION_SYM", "", ""));
        $$ = res;
    }

    | TRANSACTIONAL_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("TRANSACTIONAL_SYM", "", ""));
        $$ = res;
    }

    | THREADS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("THREADS_SYM", "", ""));
        $$ = res;
    }

    | TRIGGERS_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("TRIGGERS_SYM", "", ""));
        $$ = res;
    }

    | TRIM_ORACLE {
        res = new IR(kKeywordSpVarAndLabel, OP3("TRIM_ORACLE", "", ""));
        $$ = res;
    }

    | TIMESTAMP_ADD {
        res = new IR(kKeywordSpVarAndLabel, OP3("TIMESTAMP_ADD", "", ""));
        $$ = res;
    }

    | TIMESTAMP_DIFF {
        res = new IR(kKeywordSpVarAndLabel, OP3("TIMESTAMP_DIFF", "", ""));
        $$ = res;
    }

    | TYPES_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("TYPES_SYM", "", ""));
        $$ = res;
    }

    | TYPE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("TYPE_SYM", "", ""));
        $$ = res;
    }

    | UDF_RETURNS_SYM {
        auto tmp1 = $1;
        res = new IR(kKeywordSpVarAndLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | UNCOMMITTED_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("UNCOMMITTED_SYM", "", ""));
        $$ = res;
    }

    | UNDEFINED_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("UNDEFINED_SYM", "", ""));
        $$ = res;
    }

    | UNDO_BUFFER_SIZE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("UNDO_BUFFER_SIZE_SYM", "", ""));
        $$ = res;
    }

    | UNDOFILE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("UNDOFILE_SYM", "", ""));
        $$ = res;
    }

    | UNKNOWN_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("UNKNOWN_SYM", "", ""));
        $$ = res;
    }

    | UNTIL_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("UNTIL_SYM", "", ""));
        $$ = res;
    }

    | USER_SYM %prec PREC_BELOW_CONTRACTION_TOKEN2 {
        res = new IR(kKeywordSpVarAndLabel, OP3("USER_SYM", "", ""));
        $$ = res;
    }

    | USE_FRM {
        res = new IR(kKeywordSpVarAndLabel, OP3("USE_FRM", "", ""));
        $$ = res;
    }

    | VARIABLES {
        res = new IR(kKeywordSpVarAndLabel, OP3("VARIABLES", "", ""));
        $$ = res;
    }

    | VERSIONING_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("VERSIONING_SYM", "", ""));
        $$ = res;
    }

    | VIEW_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("VIEW_SYM", "", ""));
        $$ = res;
    }

    | VIRTUAL_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("VIRTUAL_SYM", "", ""));
        $$ = res;
    }

    | VISIBLE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("VISIBLE_SYM", "", ""));
        $$ = res;
    }

    | VALUE_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("VALUE_SYM", "", ""));
        $$ = res;
    }

    | WARNINGS {
        res = new IR(kKeywordSpVarAndLabel, OP3("WARNINGS", "", ""));
        $$ = res;
    }

    | WAIT_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("WAIT_SYM", "", ""));
        $$ = res;
    }

    | WEEK_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("WEEK_SYM", "", ""));
        $$ = res;
    }

    | WEIGHT_STRING_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("WEIGHT_STRING_SYM", "", ""));
        $$ = res;
    }

    | WITHOUT {
        res = new IR(kKeywordSpVarAndLabel, OP3("WITHOUT", "", ""));
        $$ = res;
    }

    | WORK_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("WORK_SYM", "", ""));
        $$ = res;
    }

    | X509_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("X509_SYM", "", ""));
        $$ = res;
    }

    | XML_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("XML_SYM", "", ""));
        $$ = res;
    }

    | VIA_SYM {
        res = new IR(kKeywordSpVarAndLabel, OP3("VIA_SYM", "", ""));
        $$ = res;
    }

;



reserved_keyword_udt_not_param_type:

    ACCESSIBLE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("ACCESSIBLE_SYM", "", ""));
        $$ = res;
    }

    | ADD {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("ADD", "", ""));
        $$ = res;
    }

    | ALL {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("ALL", "", ""));
        $$ = res;
    }

    | ALTER {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("ALTER", "", ""));
        $$ = res;
    }

    | ANALYZE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("ANALYZE_SYM", "", ""));
        $$ = res;
    }

    | AND_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("AND_SYM", "", ""));
        $$ = res;
    }

    | AS {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("AS", "", ""));
        $$ = res;
    }

    | ASC {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("ASC", "", ""));
        $$ = res;
    }

    | ASENSITIVE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("ASENSITIVE_SYM", "", ""));
        $$ = res;
    }

    | BEFORE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("BEFORE_SYM", "", ""));
        $$ = res;
    }

    | BETWEEN_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("BETWEEN_SYM", "", ""));
        $$ = res;
    }

    | BIT_AND {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("BIT_AND", "", ""));
        $$ = res;
    }

    | BIT_OR {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("BIT_OR", "", ""));
        $$ = res;
    }

    | BIT_XOR {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("BIT_XOR", "", ""));
        $$ = res;
    }

    | BODY_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kReservedKeywordUdtNotParamType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | BOTH {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("BOTH", "", ""));
        $$ = res;
    }

    | BY {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("BY", "", ""));
        $$ = res;
    }

    | CALL_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("CALL_SYM", "", ""));
        $$ = res;
    }

    | CASCADE {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("CASCADE", "", ""));
        $$ = res;
    }

    | CASE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("CASE_SYM", "", ""));
        $$ = res;
    }

    | CAST_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("CAST_SYM", "", ""));
        $$ = res;
    }

    | CHANGE {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("CHANGE", "", ""));
        $$ = res;
    }

    | CHECK_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("CHECK_SYM", "", ""));
        $$ = res;
    }

    | COLLATE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("COLLATE_SYM", "", ""));
        $$ = res;
    }

    | CONSTRAINT {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("CONSTRAINT", "", ""));
        $$ = res;
    }

    | CONTINUE_MARIADB_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("CONTINUE_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | CONTINUE_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kReservedKeywordUdtNotParamType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CONVERT_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("CONVERT_SYM", "", ""));
        $$ = res;
    }

    | COUNT_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("COUNT_SYM", "", ""));
        $$ = res;
    }

    | CREATE {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("CREATE", "", ""));
        $$ = res;
    }

    | CROSS {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("CROSS", "", ""));
        $$ = res;
    }

    | CUME_DIST_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("CUME_DIST_SYM", "", ""));
        $$ = res;
    }

    | CURDATE {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("CURDATE", "", ""));
        $$ = res;
    }

    | CURRENT_USER {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("CURRENT_USER", "", ""));
        $$ = res;
    }

    | CURRENT_ROLE {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("CURRENT_ROLE", "", ""));
        $$ = res;
    }

    | CURTIME {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("CURTIME", "", ""));
        $$ = res;
    }

    | DATABASE {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DATABASE", "", ""));
        $$ = res;
    }

    | DATABASES {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DATABASES", "", ""));
        $$ = res;
    }

    | DATE_ADD_INTERVAL {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DATE_ADD_INTERVAL", "", ""));
        $$ = res;
    }

    | DATE_SUB_INTERVAL {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DATE_SUB_INTERVAL", "", ""));
        $$ = res;
    }

    | DAY_HOUR_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DAY_HOUR_SYM", "", ""));
        $$ = res;
    }

    | DAY_MICROSECOND_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DAY_MICROSECOND_SYM", "", ""));
        $$ = res;
    }

    | DAY_MINUTE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DAY_MINUTE_SYM", "", ""));
        $$ = res;
    }

    | DAY_SECOND_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DAY_SECOND_SYM", "", ""));
        $$ = res;
    }

    | DECLARE_MARIADB_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DECLARE_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | DECLARE_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kReservedKeywordUdtNotParamType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DEFAULT", "", ""));
        $$ = res;
    }

    | DELETE_DOMAIN_ID_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DELETE_DOMAIN_ID_SYM", "", ""));
        $$ = res;
    }

    | DELETE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DELETE_SYM", "", ""));
        $$ = res;
    }

    | DENSE_RANK_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DENSE_RANK_SYM", "", ""));
        $$ = res;
    }

    | DESC {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DESC", "", ""));
        $$ = res;
    }

    | DESCRIBE {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DESCRIBE", "", ""));
        $$ = res;
    }

    | DETERMINISTIC_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DETERMINISTIC_SYM", "", ""));
        $$ = res;
    }

    | DISTINCT {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DISTINCT", "", ""));
        $$ = res;
    }

    | DIV_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DIV_SYM", "", ""));
        $$ = res;
    }

    | DO_DOMAIN_IDS_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DO_DOMAIN_IDS_SYM", "", ""));
        $$ = res;
    }

    | DROP {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DROP", "", ""));
        $$ = res;
    }

    | DUAL_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("DUAL_SYM", "", ""));
        $$ = res;
    }

    | EACH_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("EACH_SYM", "", ""));
        $$ = res;
    }

    | ELSE {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("ELSE", "", ""));
        $$ = res;
    }

    | ELSEIF_MARIADB_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("ELSEIF_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | ELSIF_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kReservedKeywordUdtNotParamType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ENCLOSED {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("ENCLOSED", "", ""));
        $$ = res;
    }

    | ESCAPED {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("ESCAPED", "", ""));
        $$ = res;
    }

    | EXCEPT_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("EXCEPT_SYM", "", ""));
        $$ = res;
    }

    | EXISTS {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("EXISTS", "", ""));
        $$ = res;
    }

    | EXTRACT_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("EXTRACT_SYM", "", ""));
        $$ = res;
    }

    | FALSE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("FALSE_SYM", "", ""));
        $$ = res;
    }

    | FETCH_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("FETCH_SYM", "", ""));
        $$ = res;
    }

    | FIRST_VALUE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("FIRST_VALUE_SYM", "", ""));
        $$ = res;
    }

    | FOREIGN {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("FOREIGN", "", ""));
        $$ = res;
    }

    | FROM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("FROM", "", ""));
        $$ = res;
    }

    | FULLTEXT_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("FULLTEXT_SYM", "", ""));
        $$ = res;
    }

    | GOTO_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kReservedKeywordUdtNotParamType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | GRANT {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("GRANT", "", ""));
        $$ = res;
    }

    | GROUP_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("GROUP_SYM", "", ""));
        $$ = res;
    }

    | GROUP_CONCAT_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("GROUP_CONCAT_SYM", "", ""));
        $$ = res;
    }

    | LAG_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("LAG_SYM", "", ""));
        $$ = res;
    }

    | LEAD_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("LEAD_SYM", "", ""));
        $$ = res;
    }

    | HAVING {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("HAVING", "", ""));
        $$ = res;
    }

    | HOUR_MICROSECOND_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("HOUR_MICROSECOND_SYM", "", ""));
        $$ = res;
    }

    | HOUR_MINUTE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("HOUR_MINUTE_SYM", "", ""));
        $$ = res;
    }

    | HOUR_SECOND_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("HOUR_SECOND_SYM", "", ""));
        $$ = res;
    }

    | IF_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("IF_SYM", "", ""));
        $$ = res;
    }

    | IGNORE_DOMAIN_IDS_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("IGNORE_DOMAIN_IDS_SYM", "", ""));
        $$ = res;
    }

    | IGNORE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("IGNORE_SYM", "", ""));
        $$ = res;
    }

    | IGNORED_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("IGNORED_SYM", "", ""));
        $$ = res;
    }

    | INDEX_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("INDEX_SYM", "", ""));
        $$ = res;
    }

    | INFILE {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("INFILE", "", ""));
        $$ = res;
    }

    | INNER_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("INNER_SYM", "", ""));
        $$ = res;
    }

    | INSENSITIVE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("INSENSITIVE_SYM", "", ""));
        $$ = res;
    }

    | INSERT {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("INSERT", "", ""));
        $$ = res;
    }

    | INTERSECT_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("INTERSECT_SYM", "", ""));
        $$ = res;
    }

    | INTERVAL_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("INTERVAL_SYM", "", ""));
        $$ = res;
    }

    | INTO {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("INTO", "", ""));
        $$ = res;
    }

    | IS {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("IS", "", ""));
        $$ = res;
    }

    | ITERATE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("ITERATE_SYM", "", ""));
        $$ = res;
    }

    | JOIN_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("JOIN_SYM", "", ""));
        $$ = res;
    }

    | KEYS {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("KEYS", "", ""));
        $$ = res;
    }

    | KEY_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("KEY_SYM", "", ""));
        $$ = res;
    }

    | KILL_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("KILL_SYM", "", ""));
        $$ = res;
    }

    | LEADING {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("LEADING", "", ""));
        $$ = res;
    }

    | LEAVE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("LEAVE_SYM", "", ""));
        $$ = res;
    }

    | LEFT {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("LEFT", "", ""));
        $$ = res;
    }

    | LIKE {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("LIKE", "", ""));
        $$ = res;
    }

    | LIMIT {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("LIMIT", "", ""));
        $$ = res;
    }

    | LINEAR_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("LINEAR_SYM", "", ""));
        $$ = res;
    }

    | LINES {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("LINES", "", ""));
        $$ = res;
    }

    | LOAD {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("LOAD", "", ""));
        $$ = res;
    }

    | LOCATOR_SYM {
        auto tmp1 = $1;
        res = new IR(kReservedKeywordUdtNotParamType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LOCK_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("LOCK_SYM", "", ""));
        $$ = res;
    }

    | LOOP_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("LOOP_SYM", "", ""));
        $$ = res;
    }

    | LOW_PRIORITY {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("LOW_PRIORITY", "", ""));
        $$ = res;
    }

    | MASTER_SSL_VERIFY_SERVER_CERT_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("MASTER_SSL_VERIFY_SERVER_CERT_SYM", "", ""));
        $$ = res;
    }

    | MATCH {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("MATCH", "", ""));
        $$ = res;
    }

    | MAX_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("MAX_SYM", "", ""));
        $$ = res;
    }

    | MAXVALUE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("MAXVALUE_SYM", "", ""));
        $$ = res;
    }

    | MEDIAN_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("MEDIAN_SYM", "", ""));
        $$ = res;
    }

    | MINUTE_MICROSECOND_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("MINUTE_MICROSECOND_SYM", "", ""));
        $$ = res;
    }

    | MINUTE_SECOND_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("MINUTE_SECOND_SYM", "", ""));
        $$ = res;
    }

    | MIN_SYM %ifdef ORACLE {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kReservedKeywordUdtNotParamType, OP3("MIN_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | MINUS_ORACLE_SYM %endif {
        auto tmp1 = $2;
        res = new IR(kReservedKeywordUdtNotParamType, OP3("MINUS_ORACLE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | MODIFIES_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("MODIFIES_SYM", "", ""));
        $$ = res;
    }

    | MOD_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("MOD_SYM", "", ""));
        $$ = res;
    }

    | NATURAL {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("NATURAL", "", ""));
        $$ = res;
    }

    | NEG {
        auto tmp1 = $1;
        res = new IR(kReservedKeywordUdtNotParamType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NOT_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("NOT_SYM", "", ""));
        $$ = res;
    }

    | NOW_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("NOW_SYM", "", ""));
        $$ = res;
    }

    | NO_WRITE_TO_BINLOG {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("NO_WRITE_TO_BINLOG", "", ""));
        $$ = res;
    }

    | NTILE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("NTILE_SYM", "", ""));
        $$ = res;
    }

    | NULL_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("NULL_SYM", "", ""));
        $$ = res;
    }

    | NTH_VALUE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("NTH_VALUE_SYM", "", ""));
        $$ = res;
    }

    | ON {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("ON", "", ""));
        $$ = res;
    }

    | OPTIMIZE {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("OPTIMIZE", "", ""));
        $$ = res;
    }

    | OPTIONALLY {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("OPTIONALLY", "", ""));
        $$ = res;
    }

    | ORDER_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("ORDER_SYM", "", ""));
        $$ = res;
    }

    | OR_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("OR_SYM", "", ""));
        $$ = res;
    }

    | OTHERS_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kReservedKeywordUdtNotParamType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | OUTER {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("OUTER", "", ""));
        $$ = res;
    }

    | OUTFILE {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("OUTFILE", "", ""));
        $$ = res;
    }

    | OVER_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("OVER_SYM", "", ""));
        $$ = res;
    }

    | PACKAGE_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kReservedKeywordUdtNotParamType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | PAGE_CHECKSUM_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("PAGE_CHECKSUM_SYM", "", ""));
        $$ = res;
    }

    | PARSE_VCOL_EXPR_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("PARSE_VCOL_EXPR_SYM", "", ""));
        $$ = res;
    }

    | PARTITION_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("PARTITION_SYM", "", ""));
        $$ = res;
    }

    | PERCENT_RANK_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("PERCENT_RANK_SYM", "", ""));
        $$ = res;
    }

    | PERCENTILE_CONT_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("PERCENTILE_CONT_SYM", "", ""));
        $$ = res;
    }

    | PERCENTILE_DISC_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("PERCENTILE_DISC_SYM", "", ""));
        $$ = res;
    }

    | PORTION_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("PORTION_SYM", "", ""));
        $$ = res;
    }

    | POSITION_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("POSITION_SYM", "", ""));
        $$ = res;
    }

    | PRECISION {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("PRECISION", "", ""));
        $$ = res;
    }

    | PRIMARY_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("PRIMARY_SYM", "", ""));
        $$ = res;
    }

    | PROCEDURE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("PROCEDURE_SYM", "", ""));
        $$ = res;
    }

    | PURGE {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("PURGE", "", ""));
        $$ = res;
    }

    | RAISE_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kReservedKeywordUdtNotParamType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RANGE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("RANGE_SYM", "", ""));
        $$ = res;
    }

    | RANK_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("RANK_SYM", "", ""));
        $$ = res;
    }

    | READS_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("READS_SYM", "", ""));
        $$ = res;
    }

    | READ_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("READ_SYM", "", ""));
        $$ = res;
    }

    | READ_WRITE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("READ_WRITE_SYM", "", ""));
        $$ = res;
    }

    | RECURSIVE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("RECURSIVE_SYM", "", ""));
        $$ = res;
    }

    | REF_SYSTEM_ID_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("REF_SYSTEM_ID_SYM", "", ""));
        $$ = res;
    }

    | REFERENCES {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("REFERENCES", "", ""));
        $$ = res;
    }

    | REGEXP {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("REGEXP", "", ""));
        $$ = res;
    }

    | RELEASE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("RELEASE_SYM", "", ""));
        $$ = res;
    }

    | RENAME {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("RENAME", "", ""));
        $$ = res;
    }

    | REPEAT_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("REPEAT_SYM", "", ""));
        $$ = res;
    }

    | REPLACE {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("REPLACE", "", ""));
        $$ = res;
    }

    | REQUIRE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("REQUIRE_SYM", "", ""));
        $$ = res;
    }

    | RESIGNAL_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("RESIGNAL_SYM", "", ""));
        $$ = res;
    }

    | RESTRICT {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("RESTRICT", "", ""));
        $$ = res;
    }

    | RETURNING_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("RETURNING_SYM", "", ""));
        $$ = res;
    }

    | RETURN_MARIADB_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("RETURN_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | RETURN_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kReservedKeywordUdtNotParamType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | REVOKE {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("REVOKE", "", ""));
        $$ = res;
    }

    | RIGHT {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("RIGHT", "", ""));
        $$ = res;
    }

    | ROWS_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("ROWS_SYM", "", ""));
        $$ = res;
    }

    | ROWTYPE_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kReservedKeywordUdtNotParamType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ROW_NUMBER_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("ROW_NUMBER_SYM", "", ""));
        $$ = res;
    }

    | SECOND_MICROSECOND_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("SECOND_MICROSECOND_SYM", "", ""));
        $$ = res;
    }

    | SELECT_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("SELECT_SYM", "", ""));
        $$ = res;
    }

    | SENSITIVE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("SENSITIVE_SYM", "", ""));
        $$ = res;
    }

    | SEPARATOR_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("SEPARATOR_SYM", "", ""));
        $$ = res;
    }

    | SERVER_OPTIONS {
        auto tmp1 = $1;
        res = new IR(kReservedKeywordUdtNotParamType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SHOW {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("SHOW", "", ""));
        $$ = res;
    }

    | SIGNAL_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("SIGNAL_SYM", "", ""));
        $$ = res;
    }

    | SPATIAL_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("SPATIAL_SYM", "", ""));
        $$ = res;
    }

    | SPECIFIC_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("SPECIFIC_SYM", "", ""));
        $$ = res;
    }

    | SQLEXCEPTION_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("SQLEXCEPTION_SYM", "", ""));
        $$ = res;
    }

    | SQLSTATE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("SQLSTATE_SYM", "", ""));
        $$ = res;
    }

    | SQLWARNING_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("SQLWARNING_SYM", "", ""));
        $$ = res;
    }

    | SQL_BIG_RESULT {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("SQL_BIG_RESULT", "", ""));
        $$ = res;
    }

    | SQL_SMALL_RESULT {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("SQL_SMALL_RESULT", "", ""));
        $$ = res;
    }

    | SQL_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("SQL_SYM", "", ""));
        $$ = res;
    }

    | SSL_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("SSL_SYM", "", ""));
        $$ = res;
    }

    | STARTING {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("STARTING", "", ""));
        $$ = res;
    }

    | STATS_AUTO_RECALC_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("STATS_AUTO_RECALC_SYM", "", ""));
        $$ = res;
    }

    | STATS_PERSISTENT_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("STATS_PERSISTENT_SYM", "", ""));
        $$ = res;
    }

    | STATS_SAMPLE_PAGES_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("STATS_SAMPLE_PAGES_SYM", "", ""));
        $$ = res;
    }

    | STDDEV_SAMP_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("STDDEV_SAMP_SYM", "", ""));
        $$ = res;
    }

    | STD_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("STD_SYM", "", ""));
        $$ = res;
    }

    | STRAIGHT_JOIN {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("STRAIGHT_JOIN", "", ""));
        $$ = res;
    }

    | SUBSTRING {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("SUBSTRING", "", ""));
        $$ = res;
    }

    | SUM_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("SUM_SYM", "", ""));
        $$ = res;
    }

    | TABLE_REF_PRIORITY {
        auto tmp1 = $1;
        res = new IR(kReservedKeywordUdtNotParamType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TABLE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("TABLE_SYM", "", ""));
        $$ = res;
    }

    | TERMINATED {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("TERMINATED", "", ""));
        $$ = res;
    }

    | THEN_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("THEN_SYM", "", ""));
        $$ = res;
    }

    | TO_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("TO_SYM", "", ""));
        $$ = res;
    }

    | TRAILING {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("TRAILING", "", ""));
        $$ = res;
    }

    | TRIGGER_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("TRIGGER_SYM", "", ""));
        $$ = res;
    }

    | TRIM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("TRIM", "", ""));
        $$ = res;
    }

    | TRUE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("TRUE_SYM", "", ""));
        $$ = res;
    }

    | UNDO_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("UNDO_SYM", "", ""));
        $$ = res;
    }

    | UNION_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("UNION_SYM", "", ""));
        $$ = res;
    }

    | UNIQUE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("UNIQUE_SYM", "", ""));
        $$ = res;
    }

    | UNLOCK_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("UNLOCK_SYM", "", ""));
        $$ = res;
    }

    | UPDATE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("UPDATE_SYM", "", ""));
        $$ = res;
    }

    | USAGE {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("USAGE", "", ""));
        $$ = res;
    }

    | USE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("USE_SYM", "", ""));
        $$ = res;
    }

    | USING {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("USING", "", ""));
        $$ = res;
    }

    | UTC_DATE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("UTC_DATE_SYM", "", ""));
        $$ = res;
    }

    | UTC_TIMESTAMP_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("UTC_TIMESTAMP_SYM", "", ""));
        $$ = res;
    }

    | UTC_TIME_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("UTC_TIME_SYM", "", ""));
        $$ = res;
    }

    | VALUES {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("VALUES", "", ""));
        $$ = res;
    }

    | VALUES_IN_SYM {
        auto tmp1 = $1;
        res = new IR(kReservedKeywordUdtNotParamType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | VALUES_LESS_SYM {
        auto tmp1 = $1;
        res = new IR(kReservedKeywordUdtNotParamType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | VARIANCE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("VARIANCE_SYM", "", ""));
        $$ = res;
    }

    | VARYING {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("VARYING", "", ""));
        $$ = res;
    }

    | VAR_SAMP_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("VAR_SAMP_SYM", "", ""));
        $$ = res;
    }

    | WHEN_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("WHEN_SYM", "", ""));
        $$ = res;
    }

    | WHERE {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("WHERE", "", ""));
        $$ = res;
    }

    | WHILE_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("WHILE_SYM", "", ""));
        $$ = res;
    }

    | WITH {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("WITH", "", ""));
        $$ = res;
    }

    | XOR {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("XOR", "", ""));
        $$ = res;
    }

    | YEAR_MONTH_SYM {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("YEAR_MONTH_SYM", "", ""));
        $$ = res;
    }

    | ZEROFILL {
        res = new IR(kReservedKeywordUdtNotParamType, OP3("ZEROFILL", "", ""));
        $$ = res;
    }

;




set:

    SET {} set_param {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSet, OP3("SET", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


set_param:

    option_value_no_option_type {
        auto tmp1 = $1;
        res = new IR(kSetParam, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | option_value_no_option_type ',' option_value_list {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSetParam, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | TRANSACTION_SYM {} transaction_characteristics {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSetParam, OP3("TRANSACTION_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | option_type {} start_option_value_list_following_option_type {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSetParam_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSetParam, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | STATEMENT_SYM set_stmt_option_list {} FOR_SYM directly_executable_statement {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSetParam_2, OP3("STATEMENT_SYM", "", "FOR_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kSetParam, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


set_stmt_option_list:

    set_stmt_option {
        auto tmp1 = $1;
        res = new IR(kSetStmtOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | set_stmt_option_list ',' set_stmt_option {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSetStmtOptionList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;



start_option_value_list_following_option_type:

    option_value_following_option_type {
        auto tmp1 = $1;
        res = new IR(kStartOptionValueListFollowingOptionType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | option_value_following_option_type ',' option_value_list {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kStartOptionValueListFollowingOptionType, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | TRANSACTION_SYM {} transaction_characteristics {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kStartOptionValueListFollowingOptionType, OP3("TRANSACTION_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;



option_value_list:

    option_value {
        auto tmp1 = $1;
        res = new IR(kOptionValueList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | option_value_list ',' option_value {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptionValueList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;



option_value:

    option_type {} option_value_following_option_type {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptionValue_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kOptionValue, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | option_value_no_option_type {
        auto tmp1 = $1;
        res = new IR(kOptionValue, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


option_type:

    GLOBAL_SYM {
        res = new IR(kOptionType, OP3("GLOBAL_SYM", "", ""));
        $$ = res;
    }

    | LOCAL_SYM {
        res = new IR(kOptionType, OP3("LOCAL_SYM", "", ""));
        $$ = res;
    }

    | SESSION_SYM {
        res = new IR(kOptionType, OP3("SESSION_SYM", "", ""));
        $$ = res;
    }

;


opt_var_type:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptVarType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | GLOBAL_SYM {
        res = new IR(kOptVarType, OP3("GLOBAL_SYM", "", ""));
        $$ = res;
    }

    | LOCAL_SYM {
        res = new IR(kOptVarType, OP3("LOCAL_SYM", "", ""));
        $$ = res;
    }

    | SESSION_SYM {
        res = new IR(kOptVarType, OP3("SESSION_SYM", "", ""));
        $$ = res;
    }

;


opt_var_ident_type:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptVarIdentType, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | GLOBAL_SYM '.' {
        auto tmp1 = $2;
        res = new IR(kOptVarIdentType, OP3("GLOBAL_SYM .", "", ""), tmp1);
        $$ = res;
    }

    | LOCAL_SYM '.' {
        auto tmp1 = $2;
        res = new IR(kOptVarIdentType, OP3("LOCAL_SYM .", "", ""), tmp1);
        $$ = res;
    }

    | SESSION_SYM '.' {
        auto tmp1 = $2;
        res = new IR(kOptVarIdentType, OP3("SESSION_SYM .", "", ""), tmp1);
        $$ = res;
    }

;



set_stmt_option:

    ident_cli equal {} set_expr_or_default {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSetStmtOption_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSetStmtOption_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kSetStmtOption, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | ident_cli '.' ident equal {} set_expr_or_default {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSetStmtOption_3, OP3("", ".", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSetStmtOption_4, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kSetStmtOption_5, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kSetStmtOption, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | DEFAULT '.' ident equal {} set_expr_or_default {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kSetStmtOption_6, OP3("DEFAULT .", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kSetStmtOption_7, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kSetStmtOption, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;




option_value_following_option_type:

    ident_cli equal {} set_expr_or_default {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptionValueFollowingOptionType_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kOptionValueFollowingOptionType_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kOptionValueFollowingOptionType, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | ident_cli '.' ident equal {} set_expr_or_default {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptionValueFollowingOptionType_3, OP3("", ".", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kOptionValueFollowingOptionType_4, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kOptionValueFollowingOptionType_5, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kOptionValueFollowingOptionType, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | DEFAULT '.' ident equal {} set_expr_or_default {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptionValueFollowingOptionType_6, OP3("DEFAULT .", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kOptionValueFollowingOptionType_7, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kOptionValueFollowingOptionType, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;



option_value_no_option_type:

    ident_cli_set_usual_case equal {} set_expr_or_default {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptionValueNoOptionType_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kOptionValueNoOptionType_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kOptionValueNoOptionType, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | ident_cli_set_usual_case '.' ident equal {} set_expr_or_default {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kOptionValueNoOptionType_3, OP3("", ".", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kOptionValueNoOptionType_4, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kOptionValueNoOptionType_5, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kOptionValueNoOptionType, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | DEFAULT '.' ident equal {} set_expr_or_default {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptionValueNoOptionType_6, OP3("DEFAULT .", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kOptionValueNoOptionType_7, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kOptionValueNoOptionType, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | '@' ident_or_text equal {} expr {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptionValueNoOptionType_8, OP3("@", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kOptionValueNoOptionType_9, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kOptionValueNoOptionType, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | '@' '@' opt_var_ident_type ident_sysvar_name equal {} set_expr_or_default {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptionValueNoOptionType_10, OP3("@ @", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kOptionValueNoOptionType_11, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kOptionValueNoOptionType_12, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kOptionValueNoOptionType, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | '@' '@' opt_var_ident_type ident_sysvar_name '.' ident equal {} set_expr_or_default {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptionValueNoOptionType_13, OP3("@ @", "", "."), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kOptionValueNoOptionType_14, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $7;
        res = new IR(kOptionValueNoOptionType_15, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $8;
        res = new IR(kOptionValueNoOptionType_16, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $9;
        res = new IR(kOptionValueNoOptionType, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | '@' '@' opt_var_ident_type DEFAULT '.' ident equal {} set_expr_or_default {
        auto tmp1 = $3;
        auto tmp2 = $6;
        res = new IR(kOptionValueNoOptionType_17, OP3("@ @", "DEFAULT .", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $7;
        res = new IR(kOptionValueNoOptionType_18, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $8;
        res = new IR(kOptionValueNoOptionType_19, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $9;
        res = new IR(kOptionValueNoOptionType, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | charset old_or_new_charset_name_or_default {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptionValueNoOptionType, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | NAMES_SYM equal expr {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptionValueNoOptionType, OP3("NAMES_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | NAMES_SYM charset_name_or_default {
        auto tmp1 = $2;
        res = new IR(kOptionValueNoOptionType, OP3("NAMES_SYM", "", ""), tmp1);
        $$ = res;
    }

    | NAMES_SYM charset_name_or_default COLLATE_SYM collation_name_or_default {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kOptionValueNoOptionType, OP3("NAMES_SYM", "COLLATE_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | DEFAULT ROLE_SYM grant_role {
        auto tmp1 = $3;
        res = new IR(kOptionValueNoOptionType, OP3("DEFAULT ROLE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT ROLE_SYM grant_role FOR_SYM user {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kOptionValueNoOptionType, OP3("DEFAULT ROLE_SYM", "FOR_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | ROLE_SYM ident_or_text {
        auto tmp1 = $2;
        res = new IR(kOptionValueNoOptionType, OP3("ROLE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | ROLE_SYM equal {} set_expr_or_default {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptionValueNoOptionType_20, OP3("ROLE_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kOptionValueNoOptionType, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | PASSWORD_SYM equal {} text_or_password {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptionValueNoOptionType_21, OP3("PASSWORD_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kOptionValueNoOptionType, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | PASSWORD_SYM FOR_SYM {} user equal text_or_password {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kOptionValueNoOptionType_22, OP3("PASSWORD_SYM FOR_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kOptionValueNoOptionType_23, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kOptionValueNoOptionType, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


transaction_characteristics:

    transaction_access_mode {
        auto tmp1 = $1;
        res = new IR(kTransactionCharacteristics, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | isolation_level {
        auto tmp1 = $1;
        res = new IR(kTransactionCharacteristics, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | transaction_access_mode ',' isolation_level {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTransactionCharacteristics, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | isolation_level ',' transaction_access_mode {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTransactionCharacteristics, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


transaction_access_mode:

    transaction_access_mode_types {
        auto tmp1 = $1;
        res = new IR(kTransactionAccessMode, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


isolation_level:

    ISOLATION LEVEL_SYM isolation_types {
        auto tmp1 = $3;
        res = new IR(kIsolationLevel, OP3("ISOLATION LEVEL_SYM", "", ""), tmp1);
        $$ = res;
    }

;


transaction_access_mode_types:

    READ_SYM ONLY_SYM {
        res = new IR(kTransactionAccessModeTypes, OP3("READ_SYM ONLY_SYM", "", ""));
        $$ = res;
    }

    | READ_SYM WRITE_SYM {
        res = new IR(kTransactionAccessModeTypes, OP3("READ_SYM WRITE_SYM", "", ""));
        $$ = res;
    }

;


isolation_types:

    READ_SYM UNCOMMITTED_SYM {
        res = new IR(kIsolationTypes, OP3("READ_SYM UNCOMMITTED_SYM", "", ""));
        $$ = res;
    }

    | READ_SYM COMMITTED_SYM {
        res = new IR(kIsolationTypes, OP3("READ_SYM COMMITTED_SYM", "", ""));
        $$ = res;
    }

    | REPEATABLE_SYM READ_SYM {
        res = new IR(kIsolationTypes, OP3("REPEATABLE_SYM READ_SYM", "", ""));
        $$ = res;
    }

    | SERIALIZABLE_SYM {
        res = new IR(kIsolationTypes, OP3("SERIALIZABLE_SYM", "", ""));
        $$ = res;
    }

;



text_or_password:

    TEXT_STRING {
        auto tmp1 = $1;
        res = new IR(kTextOrPassword, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | PASSWORD_SYM '(' TEXT_STRING ')' {
        auto tmp1 = $3;
        res = new IR(kTextOrPassword, OP3("PASSWORD_SYM (", ")", ""), tmp1);
        $$ = res;
    }

    | OLD_PASSWORD_SYM '(' TEXT_STRING ')' {
        auto tmp1 = $3;
        res = new IR(kTextOrPassword, OP3("OLD_PASSWORD_SYM (", ")", ""), tmp1);
        $$ = res;
    }

;


set_expr_or_default:

    expr {
        auto tmp1 = $1;
        res = new IR(kSetExprOrDefault, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kSetExprOrDefault, OP3("DEFAULT", "", ""));
        $$ = res;
    }

    | ON {
        res = new IR(kSetExprOrDefault, OP3("ON", "", ""));
        $$ = res;
    }

    | ALL {
        res = new IR(kSetExprOrDefault, OP3("ALL", "", ""));
        $$ = res;
    }

    | BINARY {
        res = new IR(kSetExprOrDefault, OP3("BINARY", "", ""));
        $$ = res;
    }

;




lock:

    LOCK_SYM table_or_tables {} table_lock_list opt_lock_wait_timeout {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kLock_1, OP3("LOCK_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kLock_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kLock, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


opt_lock_wait_timeout:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptLockWaitTimeout, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | WAIT_SYM ulong_num{} } {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptLockWaitTimeout, OP3("WAIT_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | NOWAIT_SYM{} } {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptLockWaitTimeout, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


table_or_tables:

    TABLE_SYM {
        res = new IR(kTableOrTables, OP3("TABLE_SYM", "", ""));
        $$ = res;
    }

    | TABLES {
        res = new IR(kTableOrTables, OP3("TABLES", "", ""));
        $$ = res;
    }

;


table_lock_list:

    table_lock {
        auto tmp1 = $1;
        res = new IR(kTableLockList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | table_lock_list ',' table_lock {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kTableLockList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


table_lock:

    table_ident opt_table_alias_clause lock_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTableLock_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kTableLock, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


lock_option:

    READ_SYM {
        res = new IR(kLockOption, OP3("READ_SYM", "", ""));
        $$ = res;
    }

    | WRITE_SYM {
        res = new IR(kLockOption, OP3("WRITE_SYM", "", ""));
        $$ = res;
    }

    | WRITE_SYM CONCURRENT {
        res = new IR(kLockOption, OP3("WRITE_SYM CONCURRENT", "", ""));
        $$ = res;
    }

    | LOW_PRIORITY WRITE_SYM {
        res = new IR(kLockOption, OP3("LOW_PRIORITY WRITE_SYM", "", ""));
        $$ = res;
    }

    | READ_SYM LOCAL_SYM {
        res = new IR(kLockOption, OP3("READ_SYM LOCAL_SYM", "", ""));
        $$ = res;
    }

;


unlock:

    UNLOCK_SYM {} table_or_tables {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kUnlock, OP3("UNLOCK_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;




handler:

    HANDLER_SYM {} handler_tail {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kHandler, OP3("HANDLER_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


handler_tail:

    table_ident OPEN_SYM opt_table_alias_clause {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kHandlerTail, OP3("", "OPEN_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | table_ident_nodb CLOSE_SYM {
        auto tmp1 = $1;
        res = new IR(kHandlerTail, OP3("", "CLOSE_SYM", ""), tmp1);
        $$ = res;
    }

    | table_ident_nodb READ_SYM {} handler_read_or_scan opt_where_clause opt_global_limit_clause {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kHandlerTail_1, OP3("", "READ_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kHandlerTail_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kHandlerTail_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kHandlerTail, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


handler_read_or_scan:

    handler_scan_function {
        auto tmp1 = $1;
        res = new IR(kHandlerReadOrScan, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident handler_rkey_function {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kHandlerReadOrScan, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


handler_scan_function:

    FIRST_SYM {
        res = new IR(kHandlerScanFunction, OP3("FIRST_SYM", "", ""));
        $$ = res;
    }

    | NEXT_SYM {
        res = new IR(kHandlerScanFunction, OP3("NEXT_SYM", "", ""));
        $$ = res;
    }

;


handler_rkey_function:

    FIRST_SYM {
        res = new IR(kHandlerRkeyFunction, OP3("FIRST_SYM", "", ""));
        $$ = res;
    }

    | NEXT_SYM {
        res = new IR(kHandlerRkeyFunction, OP3("NEXT_SYM", "", ""));
        $$ = res;
    }

    | PREV_SYM {
        res = new IR(kHandlerRkeyFunction, OP3("PREV_SYM", "", ""));
        $$ = res;
    }

    | LAST_SYM {
        res = new IR(kHandlerRkeyFunction, OP3("LAST_SYM", "", ""));
        $$ = res;
    }

    | handler_rkey_mode {} '(' values ')' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kHandlerRkeyFunction_1, OP3("", "", "("), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kHandlerRkeyFunction, OP3("", "", ")"), res, tmp3);
        $$ = res;
    }

;


handler_rkey_mode:

    '=' {
        auto tmp1 = $1;
        res = new IR(kHandlerRkeyMode, OP3("=", "", ""), tmp1);
        $$ = res;
    }

    | GE {
        res = new IR(kHandlerRkeyMode, OP3("GE", "", ""));
        $$ = res;
    }

    | LE {
        res = new IR(kHandlerRkeyMode, OP3("LE", "", ""));
        $$ = res;
    }

    | '>' {
        auto tmp1 = $1;
        res = new IR(kHandlerRkeyMode, OP3(">", "", ""), tmp1);
        $$ = res;
    }

    | '<' {
        auto tmp1 = $1;
        res = new IR(kHandlerRkeyMode, OP3("<", "", ""), tmp1);
        $$ = res;
    }

;




revoke:

    REVOKE clear_privileges revoke_command {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kRevoke, OP3("REVOKE", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


revoke_command:

    grant_privileges ON opt_table grant_ident FROM user_and_role_list {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRevokeCommand_1, OP3("", "ON", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kRevokeCommand_2, OP3("", "", "FROM"), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kRevokeCommand, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | grant_privileges ON sp_handler grant_ident FROM user_and_role_list {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRevokeCommand_3, OP3("", "ON", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kRevokeCommand_4, OP3("", "", "FROM"), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kRevokeCommand, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | ALL opt_privileges ',' GRANT OPTION FROM user_and_role_list {
        auto tmp1 = $2;
        auto tmp2 = $7;
        res = new IR(kRevokeCommand, OP3("ALL", ", GRANT OPTION FROM", ""), tmp1, tmp2);
        $$ = res;
    }

    | PROXY_SYM ON user FROM user_list {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kRevokeCommand, OP3("PROXY_SYM ON", "FROM", ""), tmp1, tmp2);
        $$ = res;
    }

    | admin_option_for_role FROM user_and_role_list {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRevokeCommand, OP3("", "FROM", ""), tmp1, tmp2);
        $$ = res;
    }

;


admin_option_for_role:

    ADMIN_SYM OPTION FOR_SYM grant_role {
        auto tmp1 = $4;
        res = new IR(kAdminOptionForRole, OP3("ADMIN_SYM OPTION FOR_SYM", "", ""), tmp1);
        $$ = res;
    }

    | grant_role {
        auto tmp1 = $1;
        res = new IR(kAdminOptionForRole, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


grant:

    GRANT clear_privileges grant_command {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kGrant, OP3("GRANT", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


grant_command:

    grant_privileges ON opt_table grant_ident TO_SYM grant_list opt_require_clause opt_grant_options {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGrantCommand_1, OP3("", "ON", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kGrantCommand_2, OP3("", "", "TO_SYM"), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kGrantCommand_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kGrantCommand_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $8;
        res = new IR(kGrantCommand, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | grant_privileges ON sp_handler grant_ident TO_SYM grant_list opt_require_clause opt_grant_options {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGrantCommand_5, OP3("", "ON", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kGrantCommand_6, OP3("", "", "TO_SYM"), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kGrantCommand_7, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kGrantCommand_8, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $8;
        res = new IR(kGrantCommand, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

    | PROXY_SYM ON user TO_SYM grant_list opt_grant_option {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kGrantCommand_9, OP3("PROXY_SYM ON", "TO_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kGrantCommand, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | grant_role TO_SYM grant_list opt_with_admin_option {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGrantCommand_10, OP3("", "TO_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kGrantCommand, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


opt_with_admin:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptWithAdmin, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | WITH ADMIN_SYM user_or_role {
        auto tmp1 = $3;
        res = new IR(kOptWithAdmin, OP3("WITH ADMIN_SYM", "", ""), tmp1);
        $$ = res;
    }

;


opt_with_admin_option:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptWithAdminOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | WITH ADMIN_SYM OPTION {
        res = new IR(kOptWithAdminOption, OP3("WITH ADMIN_SYM OPTION", "", ""));
        $$ = res;
    }

;


role_list:

    grant_role {
        auto tmp1 = $1;
        res = new IR(kRoleList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | role_list ',' grant_role {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kRoleList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


current_role:

    CURRENT_ROLE optional_braces {
        auto tmp1 = $2;
        res = new IR(kCurrentRole, OP3("CURRENT_ROLE", "", ""), tmp1);
        $$ = res;
    }

;


grant_role:

    ident_or_text {
        auto tmp1 = $1;
        res = new IR(kGrantRole, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | current_role {
        auto tmp1 = $1;
        res = new IR(kGrantRole, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_table:

    TABLE_SYM {
        res = new IR(kOptTable, OP3("TABLE_SYM", "", ""));
        $$ = res;
    }

    | TABLE_SYM {
        res = new IR(kOptTable, OP3("TABLE_SYM", "", ""));
        $$ = res;
    }

;


grant_privileges:

    object_privilege_list {
        auto tmp1 = $1;
        res = new IR(kGrantPrivileges, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ALL opt_privileges {
        auto tmp1 = $2;
        res = new IR(kGrantPrivileges, OP3("ALL", "", ""), tmp1);
        $$ = res;
    }

;


opt_privileges:

    PRIVILEGES {
        res = new IR(kOptPrivileges, OP3("PRIVILEGES", "", ""));
        $$ = res;
    }

    | PRIVILEGES {
        res = new IR(kOptPrivileges, OP3("PRIVILEGES", "", ""));
        $$ = res;
    }

;


object_privilege_list:

    object_privilege {
        auto tmp1 = $1;
        res = new IR(kObjectPrivilegeList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | column_list_privilege {
        auto tmp1 = $1;
        res = new IR(kObjectPrivilegeList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | object_privilege_list ',' object_privilege {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kObjectPrivilegeList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | object_privilege_list ',' column_list_privilege {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kObjectPrivilegeList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


column_list_privilege:

    column_privilege '(' comma_separated_ident_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kColumnListPrivilege, OP3("", "(", ")"), tmp1, tmp2);
        $$ = res;
    }

;


column_privilege:

    SELECT_SYM {
        res = new IR(kColumnPrivilege, OP3("SELECT_SYM", "", ""));
        $$ = res;
    }

    | INSERT {
        res = new IR(kColumnPrivilege, OP3("INSERT", "", ""));
        $$ = res;
    }

    | UPDATE_SYM {
        res = new IR(kColumnPrivilege, OP3("UPDATE_SYM", "", ""));
        $$ = res;
    }

    | REFERENCES {
        res = new IR(kColumnPrivilege, OP3("REFERENCES", "", ""));
        $$ = res;
    }

;


object_privilege:

    SELECT_SYM {
        res = new IR(kObjectPrivilege, OP3("SELECT_SYM", "", ""));
        $$ = res;
    }

    | INSERT {
        res = new IR(kObjectPrivilege, OP3("INSERT", "", ""));
        $$ = res;
    }

    | UPDATE_SYM {
        res = new IR(kObjectPrivilege, OP3("UPDATE_SYM", "", ""));
        $$ = res;
    }

    | REFERENCES {
        res = new IR(kObjectPrivilege, OP3("REFERENCES", "", ""));
        $$ = res;
    }

    | DELETE_SYM {
        res = new IR(kObjectPrivilege, OP3("DELETE_SYM", "", ""));
        $$ = res;
    }

    | USAGE {
        res = new IR(kObjectPrivilege, OP3("USAGE", "", ""));
        $$ = res;
    }

    | INDEX_SYM {
        res = new IR(kObjectPrivilege, OP3("INDEX_SYM", "", ""));
        $$ = res;
    }

    | ALTER {
        res = new IR(kObjectPrivilege, OP3("ALTER", "", ""));
        $$ = res;
    }

    | CREATE {
        res = new IR(kObjectPrivilege, OP3("CREATE", "", ""));
        $$ = res;
    }

    | DROP {
        res = new IR(kObjectPrivilege, OP3("DROP", "", ""));
        $$ = res;
    }

    | EXECUTE_SYM {
        res = new IR(kObjectPrivilege, OP3("EXECUTE_SYM", "", ""));
        $$ = res;
    }

    | RELOAD {
        res = new IR(kObjectPrivilege, OP3("RELOAD", "", ""));
        $$ = res;
    }

    | SHUTDOWN {
        res = new IR(kObjectPrivilege, OP3("SHUTDOWN", "", ""));
        $$ = res;
    }

    | PROCESS {
        res = new IR(kObjectPrivilege, OP3("PROCESS", "", ""));
        $$ = res;
    }

    | FILE_SYM {
        res = new IR(kObjectPrivilege, OP3("FILE_SYM", "", ""));
        $$ = res;
    }

    | GRANT OPTION {
        res = new IR(kObjectPrivilege, OP3("GRANT OPTION", "", ""));
        $$ = res;
    }

    | SHOW DATABASES {
        res = new IR(kObjectPrivilege, OP3("SHOW DATABASES", "", ""));
        $$ = res;
    }

    | SUPER_SYM {
        res = new IR(kObjectPrivilege, OP3("SUPER_SYM", "", ""));
        $$ = res;
    }

    | CREATE TEMPORARY TABLES {
        res = new IR(kObjectPrivilege, OP3("CREATE TEMPORARY TABLES", "", ""));
        $$ = res;
    }

    | LOCK_SYM TABLES {
        res = new IR(kObjectPrivilege, OP3("LOCK_SYM TABLES", "", ""));
        $$ = res;
    }

    | REPLICATION SLAVE {
        res = new IR(kObjectPrivilege, OP3("REPLICATION SLAVE", "", ""));
        $$ = res;
    }

    | REPLICATION CLIENT_SYM {
        res = new IR(kObjectPrivilege, OP3("REPLICATION CLIENT_SYM", "", ""));
        $$ = res;
    }

    | CREATE VIEW_SYM {
        res = new IR(kObjectPrivilege, OP3("CREATE VIEW_SYM", "", ""));
        $$ = res;
    }

    | SHOW VIEW_SYM {
        res = new IR(kObjectPrivilege, OP3("SHOW VIEW_SYM", "", ""));
        $$ = res;
    }

    | CREATE ROUTINE_SYM {
        res = new IR(kObjectPrivilege, OP3("CREATE ROUTINE_SYM", "", ""));
        $$ = res;
    }

    | ALTER ROUTINE_SYM {
        res = new IR(kObjectPrivilege, OP3("ALTER ROUTINE_SYM", "", ""));
        $$ = res;
    }

    | CREATE USER_SYM {
        res = new IR(kObjectPrivilege, OP3("CREATE USER_SYM", "", ""));
        $$ = res;
    }

    | EVENT_SYM {
        res = new IR(kObjectPrivilege, OP3("EVENT_SYM", "", ""));
        $$ = res;
    }

    | TRIGGER_SYM {
        res = new IR(kObjectPrivilege, OP3("TRIGGER_SYM", "", ""));
        $$ = res;
    }

    | CREATE TABLESPACE {
        res = new IR(kObjectPrivilege, OP3("CREATE TABLESPACE", "", ""));
        $$ = res;
    }

    | DELETE_SYM HISTORY_SYM {
        res = new IR(kObjectPrivilege, OP3("DELETE_SYM HISTORY_SYM", "", ""));
        $$ = res;
    }

    | SET USER_SYM {
        res = new IR(kObjectPrivilege, OP3("SET USER_SYM", "", ""));
        $$ = res;
    }

    | FEDERATED_SYM ADMIN_SYM {
        res = new IR(kObjectPrivilege, OP3("FEDERATED_SYM ADMIN_SYM", "", ""));
        $$ = res;
    }

    | CONNECTION_SYM ADMIN_SYM {
        res = new IR(kObjectPrivilege, OP3("CONNECTION_SYM ADMIN_SYM", "", ""));
        $$ = res;
    }

    | READ_SYM ONLY_SYM ADMIN_SYM {
        res = new IR(kObjectPrivilege, OP3("READ_SYM ONLY_SYM ADMIN_SYM", "", ""));
        $$ = res;
    }

    | READ_ONLY_SYM ADMIN_SYM {
        res = new IR(kObjectPrivilege, OP3("READ_ONLY_SYM ADMIN_SYM", "", ""));
        $$ = res;
    }

    | BINLOG_SYM MONITOR_SYM {
        res = new IR(kObjectPrivilege, OP3("BINLOG_SYM MONITOR_SYM", "", ""));
        $$ = res;
    }

    | BINLOG_SYM ADMIN_SYM {
        res = new IR(kObjectPrivilege, OP3("BINLOG_SYM ADMIN_SYM", "", ""));
        $$ = res;
    }

    | BINLOG_SYM REPLAY_SYM {
        res = new IR(kObjectPrivilege, OP3("BINLOG_SYM REPLAY_SYM", "", ""));
        $$ = res;
    }

    | REPLICATION MASTER_SYM ADMIN_SYM {
        res = new IR(kObjectPrivilege, OP3("REPLICATION MASTER_SYM ADMIN_SYM", "", ""));
        $$ = res;
    }

    | REPLICATION SLAVE ADMIN_SYM {
        res = new IR(kObjectPrivilege, OP3("REPLICATION SLAVE ADMIN_SYM", "", ""));
        $$ = res;
    }

    | SLAVE MONITOR_SYM {
        res = new IR(kObjectPrivilege, OP3("SLAVE MONITOR_SYM", "", ""));
        $$ = res;
    }

;


opt_and:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptAnd, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AND_SYM{}} {
        auto tmp1 = $1;
        res = new IR(kOptAnd, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


require_list:

    require_list_element opt_and require_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kRequireList_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kRequireList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | require_list_element {
        auto tmp1 = $1;
        res = new IR(kRequireList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


require_list_element:

    SUBJECT_SYM TEXT_STRING {
        auto tmp1 = $2;
        res = new IR(kRequireListElement, OP3("SUBJECT_SYM", "", ""), tmp1);
        $$ = res;
    }

    | ISSUER_SYM TEXT_STRING {
        auto tmp1 = $2;
        res = new IR(kRequireListElement, OP3("ISSUER_SYM", "", ""), tmp1);
        $$ = res;
    }

    | CIPHER_SYM TEXT_STRING {
        auto tmp1 = $2;
        res = new IR(kRequireListElement, OP3("CIPHER_SYM", "", ""), tmp1);
        $$ = res;
    }

;


grant_ident:

    '*' {
        auto tmp1 = $1;
        res = new IR(kGrantIdent, OP3("*", "", ""), tmp1);
        $$ = res;
    }

    | ident '.' '*' {
        auto tmp1 = $1;
        res = new IR(kGrantIdent, OP3("", ". *", ""), tmp1);
        $$ = res;
    }

    | '*' '.' '*' {
        auto tmp1 = $3;
        res = new IR(kGrantIdent, OP3("* . *", "", ""), tmp1);
        $$ = res;
    }

    | table_ident {
        auto tmp1 = $1;
        res = new IR(kGrantIdent, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


user_list:

    user {
        auto tmp1 = $1;
        res = new IR(kUserList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | user_list ',' user {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUserList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


grant_list:

    grant_user {
        auto tmp1 = $1;
        res = new IR(kGrantList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | grant_list ',' grant_user {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGrantList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


user_and_role_list:

    user_or_role {
        auto tmp1 = $1;
        res = new IR(kUserAndRoleList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | user_and_role_list ',' user_or_role {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUserAndRoleList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


via_or_with:

    VIA_SYM | WITH {
        auto tmp1 = $2;
        res = new IR(kViaOrWith, OP3("VIA_SYM", "WITH", ""), tmp1);
        $$ = res;
    }

;

using_or_as:

    USING | AS {
        auto tmp1 = $2;
        res = new IR(kUsingOrAs, OP3("USING", "AS", ""), tmp1);
        $$ = res;
    }

;


grant_user:

    user IDENTIFIED_SYM BY TEXT_STRING {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kGrantUser, OP3("", "IDENTIFIED_SYM BY", ""), tmp1, tmp2);
        $$ = res;
    }

    | user IDENTIFIED_SYM BY PASSWORD_SYM TEXT_STRING {
        auto tmp1 = $1;
        auto tmp2 = $5;
        res = new IR(kGrantUser, OP3("", "IDENTIFIED_SYM BY PASSWORD_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | user IDENTIFIED_SYM via_or_with auth_expression {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kGrantUser_1, OP3("", "IDENTIFIED_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kGrantUser, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | user_or_role {
        auto tmp1 = $1;
        res = new IR(kGrantUser, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


auth_expression:

    auth_token OR_SYM auth_expression {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kAuthExpression, OP3("", "OR_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | auth_token {
        auto tmp1 = $1;
        res = new IR(kAuthExpression, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


auth_token:

    ident_or_text opt_auth_str {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kAuthToken, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_auth_str:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptAuthStr, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | using_or_as TEXT_STRING_sys {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptAuthStr, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | using_or_as PASSWORD_SYM '(' TEXT_STRING ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kOptAuthStr, OP3("", "PASSWORD_SYM (", ")"), tmp1, tmp2);
        $$ = res;
    }

;


opt_require_clause:

    REQUIRE_SYM require_list {
        auto tmp1 = $2;
        res = new IR(kOptRequireClause, OP3("REQUIRE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | REQUIRE_SYM require_list {
        auto tmp1 = $2;
        res = new IR(kOptRequireClause, OP3("REQUIRE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | REQUIRE_SYM SSL_SYM {
        res = new IR(kOptRequireClause, OP3("REQUIRE_SYM SSL_SYM", "", ""));
        $$ = res;
    }

    | REQUIRE_SYM X509_SYM {
        res = new IR(kOptRequireClause, OP3("REQUIRE_SYM X509_SYM", "", ""));
        $$ = res;
    }

    | REQUIRE_SYM NONE_SYM {
        res = new IR(kOptRequireClause, OP3("REQUIRE_SYM NONE_SYM", "", ""));
        $$ = res;
    }

;


resource_option:

    MAX_QUERIES_PER_HOUR ulong_num {
        auto tmp1 = $2;
        res = new IR(kResourceOption, OP3("MAX_QUERIES_PER_HOUR", "", ""), tmp1);
        $$ = res;
    }

    | MAX_UPDATES_PER_HOUR ulong_num {
        auto tmp1 = $2;
        res = new IR(kResourceOption, OP3("MAX_UPDATES_PER_HOUR", "", ""), tmp1);
        $$ = res;
    }

    | MAX_CONNECTIONS_PER_HOUR ulong_num {
        auto tmp1 = $2;
        res = new IR(kResourceOption, OP3("MAX_CONNECTIONS_PER_HOUR", "", ""), tmp1);
        $$ = res;
    }

    | MAX_USER_CONNECTIONS_SYM int_num {
        auto tmp1 = $2;
        res = new IR(kResourceOption, OP3("MAX_USER_CONNECTIONS_SYM", "", ""), tmp1);
        $$ = res;
    }

    | MAX_STATEMENT_TIME_SYM NUM_literal {
        auto tmp1 = $2;
        res = new IR(kResourceOption, OP3("MAX_STATEMENT_TIME_SYM", "", ""), tmp1);
        $$ = res;
    }

;


resource_option_list:

    resource_option_list resource_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kResourceOptionList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | resource_option {
        auto tmp1 = $1;
        res = new IR(kResourceOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_resource_options:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptResourceOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | WITH resource_option_list {
        auto tmp1 = $2;
        res = new IR(kOptResourceOptions, OP3("WITH", "", ""), tmp1);
        $$ = res;
    }

;



opt_grant_options:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptGrantOptions, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | WITH grant_option_list {
        auto tmp1 = $2;
        res = new IR(kOptGrantOptions, OP3("WITH", "", ""), tmp1);
        $$ = res;
    }

;


opt_grant_option:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptGrantOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | WITH GRANT OPTION {
        res = new IR(kOptGrantOption, OP3("WITH GRANT OPTION", "", ""));
        $$ = res;
    }

;


grant_option_list:

    grant_option_list grant_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kGrantOptionList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | grant_option {
        auto tmp1 = $1;
        res = new IR(kGrantOptionList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


grant_option:

    GRANT OPTION {
        res = new IR(kGrantOption, OP3("GRANT OPTION", "", ""));
        $$ = res;
    }

    | resource_option {
        auto tmp1 = $1;
        res = new IR(kGrantOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


begin_stmt_mariadb:

    BEGIN_MARIADB_SYM {} opt_work {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kBeginStmtMariadb, OP3("BEGIN_MARIADB_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


compound_statement:

    sp_proc_stmt_compound_ok {
        auto tmp1 = $1;
        res = new IR(kCompoundStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_not:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptNot, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | not {
        auto tmp1 = $1;
        res = new IR(kOptNot, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_work:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptWork, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | WORK_SYM {}} {
        auto tmp1 = $2;
        res = new IR(kOptWork, OP3("WORK_SYM", "", ""), tmp1);
        $$ = res;
    }

;


opt_chain:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptChain, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AND_SYM NO_SYM CHAIN_SYM {
        res = new IR(kOptChain, OP3("AND_SYM NO_SYM CHAIN_SYM", "", ""));
        $$ = res;
    }

    | AND_SYM CHAIN_SYM {
        res = new IR(kOptChain, OP3("AND_SYM CHAIN_SYM", "", ""));
        $$ = res;
    }

;


opt_release:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptRelease, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RELEASE_SYM {
        res = new IR(kOptRelease, OP3("RELEASE_SYM", "", ""));
        $$ = res;
    }

    | NO_SYM RELEASE_SYM {
        res = new IR(kOptRelease, OP3("NO_SYM RELEASE_SYM", "", ""));
        $$ = res;
    }

;


commit:

    COMMIT_SYM opt_work opt_chain opt_release {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kCommit_1, OP3("COMMIT_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kCommit, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


rollback:

    ROLLBACK_SYM opt_work opt_chain opt_release {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kRollback_1, OP3("ROLLBACK_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kRollback, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ROLLBACK_SYM opt_work TO_SYM SAVEPOINT_SYM ident {
        auto tmp1 = $2;
        auto tmp2 = $5;
        res = new IR(kRollback, OP3("ROLLBACK_SYM", "TO_SYM SAVEPOINT_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | ROLLBACK_SYM opt_work TO_SYM ident {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kRollback, OP3("ROLLBACK_SYM", "TO_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

;


savepoint:

    SAVEPOINT_SYM ident {
        auto tmp1 = $2;
        res = new IR(kSavepoint, OP3("SAVEPOINT_SYM", "", ""), tmp1);
        $$ = res;
    }

;


release:

    RELEASE_SYM SAVEPOINT_SYM ident {
        auto tmp1 = $3;
        res = new IR(kRelease, OP3("RELEASE_SYM SAVEPOINT_SYM", "", ""), tmp1);
        $$ = res;
    }

;




unit_type_decl:

    UNION_SYM union_option {
        auto tmp1 = $2;
        res = new IR(kUnitTypeDecl, OP3("UNION_SYM", "", ""), tmp1);
        $$ = res;
    }

    | INTERSECT_SYM union_option {
        auto tmp1 = $2;
        res = new IR(kUnitTypeDecl, OP3("INTERSECT_SYM", "", ""), tmp1);
        $$ = res;
    }

    | EXCEPT_SYM union_option {
        auto tmp1 = $2;
        res = new IR(kUnitTypeDecl, OP3("EXCEPT_SYM", "", ""), tmp1);
        $$ = res;
    }

;



union_option:

    {} {
        auto tmp1 = $1;
        res = new IR(kUnionOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DISTINCT {
        res = new IR(kUnionOption, OP3("DISTINCT", "", ""));
        $$ = res;
    }

    | ALL {
        res = new IR(kUnionOption, OP3("ALL", "", ""));
        $$ = res;
    }

;


query_expression_option:

    STRAIGHT_JOIN {
        res = new IR(kQueryExpressionOption, OP3("STRAIGHT_JOIN", "", ""));
        $$ = res;
    }

    | HIGH_PRIORITY {
        res = new IR(kQueryExpressionOption, OP3("HIGH_PRIORITY", "", ""));
        $$ = res;
    }

    | DISTINCT {
        res = new IR(kQueryExpressionOption, OP3("DISTINCT", "", ""));
        $$ = res;
    }

    | UNIQUE_SYM {
        res = new IR(kQueryExpressionOption, OP3("UNIQUE_SYM", "", ""));
        $$ = res;
    }

    | SQL_SMALL_RESULT {
        res = new IR(kQueryExpressionOption, OP3("SQL_SMALL_RESULT", "", ""));
        $$ = res;
    }

    | SQL_BIG_RESULT {
        res = new IR(kQueryExpressionOption, OP3("SQL_BIG_RESULT", "", ""));
        $$ = res;
    }

    | SQL_BUFFER_RESULT {
        res = new IR(kQueryExpressionOption, OP3("SQL_BUFFER_RESULT", "", ""));
        $$ = res;
    }

    | SQL_CALC_FOUND_ROWS {
        res = new IR(kQueryExpressionOption, OP3("SQL_CALC_FOUND_ROWS", "", ""));
        $$ = res;
    }

    | ALL {
        res = new IR(kQueryExpressionOption, OP3("ALL", "", ""));
        $$ = res;
    }

;




definer_opt:

    no_definer {
        auto tmp1 = $1;
        res = new IR(kDefinerOpt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | definer {
        auto tmp1 = $1;
        res = new IR(kDefinerOpt, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


no_definer:

    no_definer: {
        auto tmp1 = $1;
        res = new IR(kNoDefiner, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


definer:

    DEFINER_SYM '=' user_or_role {
        auto tmp1 = $3;
        res = new IR(kDefiner, OP3("DEFINER_SYM =", "", ""), tmp1);
        $$ = res;
    }

;




view_algorithm:

    ALGORITHM_SYM '=' UNDEFINED_SYM {
        res = new IR(kViewAlgorithm, OP3("ALGORITHM_SYM = UNDEFINED_SYM", "", ""));
        $$ = res;
    }

    | ALGORITHM_SYM '=' MERGE_SYM {
        res = new IR(kViewAlgorithm, OP3("ALGORITHM_SYM = MERGE_SYM", "", ""));
        $$ = res;
    }

    | ALGORITHM_SYM '=' TEMPTABLE_SYM {
        res = new IR(kViewAlgorithm, OP3("ALGORITHM_SYM = TEMPTABLE_SYM", "", ""));
        $$ = res;
    }

;


opt_view_suid:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptViewSuid, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | view_suid {
        auto tmp1 = $1;
        res = new IR(kOptViewSuid, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


view_suid:

    SQL_SYM SECURITY_SYM DEFINER_SYM {
        res = new IR(kViewSuid, OP3("SQL_SYM SECURITY_SYM DEFINER_SYM", "", ""));
        $$ = res;
    }

    | SQL_SYM SECURITY_SYM INVOKER_SYM {
        res = new IR(kViewSuid, OP3("SQL_SYM SECURITY_SYM INVOKER_SYM", "", ""));
        $$ = res;
    }

;


view_list_opt:

    {} {
        auto tmp1 = $1;
        res = new IR(kViewListOpt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | '(' view_list ')'{} } {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kViewListOpt, OP3("(", "')'{}", ""), tmp1, tmp2);
        $$ = res;
    }

;


view_list:

    ident {
        auto tmp1 = $1;
        res = new IR(kViewList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | view_list ',' ident {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kViewList, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;


view_select:

    {} query_expression view_check_option {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kViewSelect_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kViewSelect, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


view_check_option:

    {} {
        auto tmp1 = $1;
        res = new IR(kViewCheckOption, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | WITH CHECK_SYM OPTION {
        res = new IR(kViewCheckOption, OP3("WITH CHECK_SYM OPTION", "", ""));
        $$ = res;
    }

    | WITH CASCADED CHECK_SYM OPTION {
        res = new IR(kViewCheckOption, OP3("WITH CASCADED CHECK_SYM OPTION", "", ""));
        $$ = res;
    }

    | WITH LOCAL_SYM CHECK_SYM OPTION {
        res = new IR(kViewCheckOption, OP3("WITH LOCAL_SYM CHECK_SYM OPTION", "", ""));
        $$ = res;
    }

;




trigger_action_order:

    FOLLOWS_SYM {
        res = new IR(kTriggerActionOrder, OP3("FOLLOWS_SYM", "", ""));
        $$ = res;
    }

    | PRECEDES_SYM {
        res = new IR(kTriggerActionOrder, OP3("PRECEDES_SYM", "", ""));
        $$ = res;
    }

;


trigger_follows_precedes_clause:

    {} {
        auto tmp1 = $1;
        res = new IR(kTriggerFollowsPrecedesClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | trigger_action_order ident_or_text {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTriggerFollowsPrecedesClause, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


trigger_tail:

    remember_name opt_if_not_exists {} sp_name trg_action_time trg_event ON remember_name {} table_ident FOR_SYM remember_name {} EACH_SYM ROW_SYM {} trigger_follows_precedes_clause {} sp_proc_stmt force_lookahead {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kTriggerTail_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kTriggerTail_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kTriggerTail_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kTriggerTail_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $6;
        res = new IR(kTriggerTail_5, OP3("", "", "ON"), res, tmp6);
        PUSH(res);
        auto tmp7 = $8;
        res = new IR(kTriggerTail_6, OP3("", "", ""), res, tmp7);
        PUSH(res);
        auto tmp8 = $9;
        res = new IR(kTriggerTail_7, OP3("", "", ""), res, tmp8);
        PUSH(res);
        auto tmp9 = $10;
        res = new IR(kTriggerTail_8, OP3("", "", "FOR_SYM"), res, tmp9);
        PUSH(res);
        auto tmp10 = $12;
        res = new IR(kTriggerTail_9, OP3("", "", ""), res, tmp10);
        PUSH(res);
        auto tmp11 = $13;
        res = new IR(kTriggerTail_10, OP3("", "", "EACH_SYM ROW_SYM"), res, tmp11);
        PUSH(res);
        auto tmp12 = $16;
        res = new IR(kTriggerTail_11, OP3("", "", ""), res, tmp12);
        PUSH(res);
        auto tmp13 = $17;
        res = new IR(kTriggerTail_12, OP3("", "", ""), res, tmp13);
        PUSH(res);
        auto tmp14 = $18;
        res = new IR(kTriggerTail_13, OP3("", "", ""), res, tmp14);
        PUSH(res);
        auto tmp15 = $19;
        res = new IR(kTriggerTail_14, OP3("", "", ""), res, tmp15);
        PUSH(res);
        auto tmp16 = $20;
        res = new IR(kTriggerTail, OP3("", "", ""), res, tmp16);
        $$ = res;
    }

;





sf_return_type:

    {} field_type {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSfReturnType, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;




xa:

    XA_SYM begin_or_start xid opt_join_or_resume {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kXa_1, OP3("XA_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kXa, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | XA_SYM END xid opt_suspend {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kXa, OP3("XA_SYM END", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | XA_SYM PREPARE_SYM xid {
        auto tmp1 = $3;
        res = new IR(kXa, OP3("XA_SYM PREPARE_SYM", "", ""), tmp1);
        $$ = res;
    }

    | XA_SYM COMMIT_SYM xid opt_one_phase {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kXa, OP3("XA_SYM COMMIT_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | XA_SYM ROLLBACK_SYM xid {
        auto tmp1 = $3;
        res = new IR(kXa, OP3("XA_SYM ROLLBACK_SYM", "", ""), tmp1);
        $$ = res;
    }

    | XA_SYM RECOVER_SYM opt_format_xid {
        auto tmp1 = $3;
        res = new IR(kXa, OP3("XA_SYM RECOVER_SYM", "", ""), tmp1);
        $$ = res;
    }

;


opt_format_xid:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptFormatXid, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FORMAT_SYM '=' ident_or_text {
        auto tmp1 = $3;
        res = new IR(kOptFormatXid, OP3("FORMAT_SYM =", "", ""), tmp1);
        $$ = res;
    }

;


xid:

    text_string {
        auto tmp1 = $1;
        res = new IR(kXid, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | text_string ',' text_string {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kXid, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

    | text_string ',' text_string ',' ulong_num {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kXid_1, OP3("", ",", ","), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kXid, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


begin_or_start:

    BEGIN_MARIADB_SYM {
        res = new IR(kBeginOrStart, OP3("BEGIN_MARIADB_SYM", "", ""));
        $$ = res;
    }

    | BEGIN_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kBeginOrStart, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | START_SYM {
        res = new IR(kBeginOrStart, OP3("START_SYM", "", ""));
        $$ = res;
    }

;


opt_join_or_resume:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptJoinOrResume, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | JOIN_SYM {
        res = new IR(kOptJoinOrResume, OP3("JOIN_SYM", "", ""));
        $$ = res;
    }

    | RESUME_SYM {
        res = new IR(kOptJoinOrResume, OP3("RESUME_SYM", "", ""));
        $$ = res;
    }

;


opt_one_phase:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptOnePhase, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ONE_SYM PHASE_SYM {
        res = new IR(kOptOnePhase, OP3("ONE_SYM PHASE_SYM", "", ""));
        $$ = res;
    }

;


opt_suspend:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptSuspend, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SUSPEND_SYM {} opt_migrate {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptSuspend, OP3("SUSPEND_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_migrate:

    {} {
        auto tmp1 = $1;
        res = new IR(kOptMigrate, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FOR_SYM MIGRATE_SYM{} } {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kOptMigrate, OP3("FOR_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


install:

    INSTALL_SYM PLUGIN_SYM opt_if_not_exists ident SONAME_SYM TEXT_STRING_sys {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kInstall_1, OP3("INSTALL_SYM PLUGIN_SYM", "", "SONAME_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kInstall, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | INSTALL_SYM SONAME_SYM TEXT_STRING_sys {
        auto tmp1 = $3;
        res = new IR(kInstall, OP3("INSTALL_SYM SONAME_SYM", "", ""), tmp1);
        $$ = res;
    }

;


uninstall:

    UNINSTALL_SYM PLUGIN_SYM opt_if_exists ident {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUninstall, OP3("UNINSTALL_SYM PLUGIN_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | UNINSTALL_SYM SONAME_SYM opt_if_exists TEXT_STRING_sys {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kUninstall, OP3("UNINSTALL_SYM SONAME_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

;



keep_gcc_happy:

    IMPOSSIBLE_ACTION {
        auto tmp1 = $1;
        res = new IR(kKeepGccHappy, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


_empty:

    _empty: {
        auto tmp1 = $1;
        res = new IR(kEmpty, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

%ifdef MARIADB



statement:

    verb_clause {
        auto tmp1 = $1;
        res = new IR(kStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | set_assign {
        auto tmp1 = $1;
        res = new IR(kStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_statement:

    statement {
        auto tmp1 = $1;
        res = new IR(kSpStatement, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_cli_directly_assignable {} opt_sp_cparam_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpStatement_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSpStatement, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ident_cli_directly_assignable '.' ident {} opt_sp_cparam_list {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpStatement_2, OP3("", ".", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSpStatement_3, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kSpStatement, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | ident_cli_directly_assignable '.' ident '.' ident {} opt_sp_cparam_list {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpStatement_4, OP3("", ".", "."), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kSpStatement_5, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kSpStatement_6, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kSpStatement, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


sp_if_then_statements:

    sp_proc_stmts1_implicit_block {
        auto tmp1 = $1;
        res = new IR(kSpIfThenStatements, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_case_then_statements:

    sp_proc_stmts1_implicit_block {
        auto tmp1 = $1;
        res = new IR(kSpCaseThenStatements, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


reserved_keyword_udt_param_type:

    INOUT_SYM {
        res = new IR(kReservedKeywordUdtParamType, OP3("INOUT_SYM", "", ""));
        $$ = res;
    }

    | IN_SYM {
        res = new IR(kReservedKeywordUdtParamType, OP3("IN_SYM", "", ""));
        $$ = res;
    }

    | OUT_SYM {
        res = new IR(kReservedKeywordUdtParamType, OP3("OUT_SYM", "", ""));
        $$ = res;
    }

;


reserved_keyword_udt:

    reserved_keyword_udt_not_param_type {
        auto tmp1 = $1;
        res = new IR(kReservedKeywordUdt, OP3("", "", ""), tmp1);
        $$ = res;
    }

;




keyword_sp_block_section:

    BEGIN_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kKeywordSpBlockSection, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | END {
        res = new IR(kKeywordSpBlockSection, OP3("END", "", ""));
        $$ = res;
    }

;






keyword_label:

    keyword_data_type {
        auto tmp1 = $1;
        res = new IR(kKeywordLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_set_special_case {
        auto tmp1 = $1;
        res = new IR(kKeywordLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_var_and_label {
        auto tmp1 = $1;
        res = new IR(kKeywordLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sysvar_type {
        auto tmp1 = $1;
        res = new IR(kKeywordLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FUNCTION_SYM {
        res = new IR(kKeywordLabel, OP3("FUNCTION_SYM", "", ""));
        $$ = res;
    }

    | COMPRESSED_SYM {
        res = new IR(kKeywordLabel, OP3("COMPRESSED_SYM", "", ""));
        $$ = res;
    }

    | EXCEPTION_ORACLE_SYM {
        auto tmp1 = $1;
        res = new IR(kKeywordLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IGNORED_SYM {
        res = new IR(kKeywordLabel, OP3("IGNORED_SYM", "", ""));
        $$ = res;
    }

;


keyword_sp_decl:

    keyword_sp_head {
        auto tmp1 = $1;
        res = new IR(kKeywordSpDecl, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_set_special_case {
        auto tmp1 = $1;
        res = new IR(kKeywordSpDecl, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_var_and_label {
        auto tmp1 = $1;
        res = new IR(kKeywordSpDecl, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_var_not_label {
        auto tmp1 = $1;
        res = new IR(kKeywordSpDecl, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sysvar_type {
        auto tmp1 = $1;
        res = new IR(kKeywordSpDecl, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_verb_clause {
        auto tmp1 = $1;
        res = new IR(kKeywordSpDecl, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | WINDOW_SYM {
        res = new IR(kKeywordSpDecl, OP3("WINDOW_SYM", "", ""));
        $$ = res;
    }

    | IGNORED_SYM {
        res = new IR(kKeywordSpDecl, OP3("IGNORED_SYM", "", ""));
        $$ = res;
    }

;


opt_truncate_table_storage_clause:

    empty {
        auto tmp1 = $1;
        res = new IR(kOptTruncateTableStorageClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DROP STORAGE_SYM {
        res = new IR(kOptTruncateTableStorageClause, OP3("DROP STORAGE_SYM", "", ""));
        $$ = res;
    }

    | REUSE_SYM STORAGE_SYM {
        res = new IR(kOptTruncateTableStorageClause, OP3("REUSE_SYM STORAGE_SYM", "", ""));
        $$ = res;
    }

;



ident_for_loop_index:

    ident_directly_assignable {
        auto tmp1 = $1;
        res = new IR(kIdentForLoopIndex, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


row_field_name:

    ident_directly_assignable {
        auto tmp1 = $1;
        res = new IR(kRowFieldName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


while_body:

    expr_lex LOOP_SYM {} sp_proc_stmts1 END LOOP_SYM {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kWhileBody_1, OP3("", "LOOP_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kWhileBody, OP3("", "", "END LOOP_SYM"), res, tmp3);
        $$ = res;
    }

;


for_loop_statements:

    LOOP_SYM sp_proc_stmts1 END LOOP_SYM {
        auto tmp1 = $2;
        res = new IR(kForLoopStatements, OP3("LOOP_SYM", "END LOOP_SYM", ""), tmp1);
        $$ = res;
    }

;


sp_label:

    label_ident ':' {
        auto tmp1 = $1;
        res = new IR(kSpLabel, OP3("", ":", ""), tmp1);
        $$ = res;
    }

;


sp_control_label:

    labels_declaration_oracle {
        auto tmp1 = $1;
        res = new IR(kSpControlLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_block_label:

    labels_declaration_oracle {
        auto tmp1 = $1;
        res = new IR(kSpBlockLabel, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_opt_default:

    empty {
        auto tmp1 = $1;
        res = new IR(kSpOptDefault, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DEFAULT expr {
        auto tmp1 = $2;
        res = new IR(kSpOptDefault, OP3("DEFAULT", "", ""), tmp1);
        $$ = res;
    }

    | SET_VAR expr {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpOptDefault, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


sp_decl_variable_list_anchored:

    sp_decl_idents_init_vars optionally_qualified_column_ident PERCENT_ORACLE_SYM TYPE_SYM sp_opt_default {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpDeclVariableListAnchored_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSpDeclVariableListAnchored_2, OP3("", "", "TYPE_SYM"), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kSpDeclVariableListAnchored, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | sp_decl_idents_init_vars optionally_qualified_column_ident PERCENT_ORACLE_SYM ROWTYPE_ORACLE_SYM sp_opt_default {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpDeclVariableListAnchored_3, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSpDeclVariableListAnchored_4, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kSpDeclVariableListAnchored_5, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kSpDeclVariableListAnchored, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


sp_param_name_and_mode:

    sp_param_name sp_opt_inout {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpParamNameAndMode, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


sp_param:

    sp_param_name_and_mode field_type {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpParam, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | sp_param_name_and_mode ROW_SYM row_type_body {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpParam, OP3("", "ROW_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | sp_param_anchored {
        auto tmp1 = $1;
        res = new IR(kSpParam, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_param_anchored:

    sp_param_name_and_mode sp_decl_ident '.' ident PERCENT_ORACLE_SYM TYPE_SYM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpParamAnchored_1, OP3("", "", "."), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSpParamAnchored_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kSpParamAnchored, OP3("", "", "TYPE_SYM"), res, tmp4);
        $$ = res;
    }

    | sp_param_name_and_mode sp_decl_ident '.' ident '.' ident PERCENT_ORACLE_SYM TYPE_SYM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpParamAnchored_3, OP3("", "", "."), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSpParamAnchored_4, OP3("", "", "."), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kSpParamAnchored_5, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $7;
        res = new IR(kSpParamAnchored, OP3("", "", "TYPE_SYM"), res, tmp5);
        $$ = res;
    }

    | sp_param_name_and_mode sp_decl_ident PERCENT_ORACLE_SYM ROWTYPE_ORACLE_SYM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpParamAnchored_6, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSpParamAnchored_7, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kSpParamAnchored, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | sp_param_name_and_mode sp_decl_ident '.' ident PERCENT_ORACLE_SYM ROWTYPE_ORACLE_SYM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpParamAnchored_8, OP3("", "", "."), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSpParamAnchored_9, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kSpParamAnchored_10, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kSpParamAnchored, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;



sf_c_chistics_and_body_standalone:

    sp_c_chistics {} sp_tail_is sp_body force_lookahead {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSfCChisticsAndBodyStandalone_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSfCChisticsAndBodyStandalone_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kSfCChisticsAndBodyStandalone_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kSfCChisticsAndBodyStandalone, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


sp_tail_standalone:

    sp_name {} opt_sp_parenthesized_pdparam_list sp_c_chistics {} sp_tail_is sp_body opt_sp_name {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpTailStandalone_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSpTailStandalone_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kSpTailStandalone_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kSpTailStandalone_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $6;
        res = new IR(kSpTailStandalone_5, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $7;
        res = new IR(kSpTailStandalone_6, OP3("", "", ""), res, tmp7);
        PUSH(res);
        auto tmp8 = $8;
        res = new IR(kSpTailStandalone, OP3("", "", ""), res, tmp8);
        $$ = res;
    }

;


drop_routine:

    DROP FUNCTION_SYM opt_if_exists ident '.' ident {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropRoutine_1, OP3("DROP FUNCTION_SYM", "", "."), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $6;
        res = new IR(kDropRoutine, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | DROP FUNCTION_SYM opt_if_exists ident {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropRoutine, OP3("DROP FUNCTION_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP PROCEDURE_SYM opt_if_exists sp_name {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropRoutine, OP3("DROP PROCEDURE_SYM", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP PACKAGE_ORACLE_SYM opt_if_exists sp_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kDropRoutine_2, OP3("DROP", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kDropRoutine, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | DROP PACKAGE_ORACLE_SYM BODY_ORACLE_SYM opt_if_exists sp_name {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kDropRoutine_3, OP3("DROP", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kDropRoutine_4, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kDropRoutine, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;



create_routine:

    create_or_replace definer_opt PROCEDURE_SYM opt_if_not_exists {} sp_tail_standalone {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateRoutine_1, OP3("", "", "PROCEDURE_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kCreateRoutine_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kCreateRoutine_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kCreateRoutine, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | create_or_replace definer opt_aggregate FUNCTION_SYM opt_if_not_exists sp_name {} opt_sp_parenthesized_fdparam_list RETURN_ORACLE_SYM sf_return_type sf_c_chistics_and_body_standalone opt_sp_name {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateRoutine_4, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kCreateRoutine_5, OP3("", "", "FUNCTION_SYM"), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kCreateRoutine_6, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kCreateRoutine_7, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $7;
        res = new IR(kCreateRoutine_8, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $8;
        res = new IR(kCreateRoutine_9, OP3("", "", ""), res, tmp7);
        PUSH(res);
        auto tmp8 = $9;
        res = new IR(kCreateRoutine_10, OP3("", "", ""), res, tmp8);
        PUSH(res);
        auto tmp9 = $10;
        res = new IR(kCreateRoutine_11, OP3("", "", ""), res, tmp9);
        PUSH(res);
        auto tmp10 = $11;
        res = new IR(kCreateRoutine_12, OP3("", "", ""), res, tmp10);
        PUSH(res);
        auto tmp11 = $12;
        res = new IR(kCreateRoutine, OP3("", "", ""), res, tmp11);
        $$ = res;
    }

    | create_or_replace no_definer opt_aggregate FUNCTION_SYM opt_if_not_exists sp_name {} opt_sp_parenthesized_fdparam_list RETURN_ORACLE_SYM sf_return_type sf_c_chistics_and_body_standalone opt_sp_name {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateRoutine_13, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kCreateRoutine_14, OP3("", "", "FUNCTION_SYM"), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kCreateRoutine_15, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kCreateRoutine_16, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $7;
        res = new IR(kCreateRoutine_17, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $8;
        res = new IR(kCreateRoutine_18, OP3("", "", ""), res, tmp7);
        PUSH(res);
        auto tmp8 = $9;
        res = new IR(kCreateRoutine_19, OP3("", "", ""), res, tmp8);
        PUSH(res);
        auto tmp9 = $10;
        res = new IR(kCreateRoutine_20, OP3("", "", ""), res, tmp9);
        PUSH(res);
        auto tmp10 = $11;
        res = new IR(kCreateRoutine_21, OP3("", "", ""), res, tmp10);
        PUSH(res);
        auto tmp11 = $12;
        res = new IR(kCreateRoutine, OP3("", "", ""), res, tmp11);
        $$ = res;
    }

    | create_or_replace no_definer opt_aggregate FUNCTION_SYM opt_if_not_exists ident RETURNS_SYM udf_type SONAME_SYM TEXT_STRING_sys {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateRoutine_22, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kCreateRoutine_23, OP3("", "", "FUNCTION_SYM"), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kCreateRoutine_24, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kCreateRoutine_25, OP3("", "", "RETURNS_SYM"), res, tmp5);
        PUSH(res);
        auto tmp6 = $8;
        res = new IR(kCreateRoutine_26, OP3("", "", "SONAME_SYM"), res, tmp6);
        PUSH(res);
        auto tmp7 = $10;
        res = new IR(kCreateRoutine, OP3("", "", ""), res, tmp7);
        $$ = res;
    }

    | create_or_replace definer_opt PACKAGE_ORACLE_SYM opt_if_not_exists sp_name opt_create_package_chistics_init sp_tail_is remember_name {} opt_package_specification_element_list END remember_end_opt opt_sp_name {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateRoutine_27, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kCreateRoutine_28, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kCreateRoutine_29, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kCreateRoutine_30, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $6;
        res = new IR(kCreateRoutine_31, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $7;
        res = new IR(kCreateRoutine_32, OP3("", "", ""), res, tmp7);
        PUSH(res);
        auto tmp8 = $8;
        res = new IR(kCreateRoutine_33, OP3("", "", ""), res, tmp8);
        PUSH(res);
        auto tmp9 = $9;
        res = new IR(kCreateRoutine_34, OP3("", "", ""), res, tmp9);
        PUSH(res);
        auto tmp10 = $10;
        res = new IR(kCreateRoutine_35, OP3("", "", "END"), res, tmp10);
        PUSH(res);
        auto tmp11 = $12;
        res = new IR(kCreateRoutine_36, OP3("", "", ""), res, tmp11);
        PUSH(res);
        auto tmp12 = $13;
        res = new IR(kCreateRoutine, OP3("", "", ""), res, tmp12);
        $$ = res;
    }

    | create_or_replace definer_opt PACKAGE_ORACLE_SYM BODY_ORACLE_SYM opt_if_not_exists sp_name opt_create_package_chistics_init sp_tail_is remember_name {} package_implementation_declare_section {} package_implementation_executable_section {} remember_end_opt opt_sp_name {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreateRoutine_37, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kCreateRoutine_38, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kCreateRoutine_39, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kCreateRoutine_40, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $6;
        res = new IR(kCreateRoutine_41, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $7;
        res = new IR(kCreateRoutine_42, OP3("", "", ""), res, tmp7);
        PUSH(res);
        auto tmp8 = $8;
        res = new IR(kCreateRoutine_43, OP3("", "", ""), res, tmp8);
        PUSH(res);
        auto tmp9 = $9;
        res = new IR(kCreateRoutine_44, OP3("", "", ""), res, tmp9);
        PUSH(res);
        auto tmp10 = $10;
        res = new IR(kCreateRoutine_45, OP3("", "", ""), res, tmp10);
        PUSH(res);
        auto tmp11 = $11;
        res = new IR(kCreateRoutine_46, OP3("", "", ""), res, tmp11);
        PUSH(res);
        auto tmp12 = $12;
        res = new IR(kCreateRoutine_47, OP3("", "", ""), res, tmp12);
        PUSH(res);
        auto tmp13 = $13;
        res = new IR(kCreateRoutine_48, OP3("", "", ""), res, tmp13);
        PUSH(res);
        auto tmp14 = $14;
        res = new IR(kCreateRoutine_49, OP3("", "", ""), res, tmp14);
        PUSH(res);
        auto tmp15 = $15;
        res = new IR(kCreateRoutine_50, OP3("", "", ""), res, tmp15);
        PUSH(res);
        auto tmp16 = $16;
        res = new IR(kCreateRoutine, OP3("", "", ""), res, tmp16);
        $$ = res;
    }

;



sp_decls:

    empty {
        auto tmp1 = $1;
        res = new IR(kSpDecls, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_decls sp_decl ';' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpDecls, OP3("", "", ";"), tmp1, tmp2);
        $$ = res;
    }

;


sp_decl:

    DECLARE_MARIADB_SYM sp_decl_body {
        auto tmp1 = $2;
        res = new IR(kSpDecl, OP3("DECLARE_MARIADB_SYM", "", ""), tmp1);
        $$ = res;
    }

;



sp_decl_body:

    sp_decl_variable_list {
        auto tmp1 = $1;
        res = new IR(kSpDeclBody, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_decl_ident CONDITION_SYM FOR_SYM sp_cond {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kSpDeclBody, OP3("", "CONDITION_SYM FOR_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | sp_decl_handler {
        auto tmp1 = $1;
        res = new IR(kSpDeclBody, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_decl_ident CURSOR_SYM {} opt_parenthesized_cursor_formal_parameters FOR_SYM sp_cursor_stmt {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSpDeclBody_1, OP3("", "CURSOR_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSpDeclBody_2, OP3("", "", "FOR_SYM"), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kSpDeclBody, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;



















sp_proc_stmt_in_returns_clause:

    sp_proc_stmt_return {
        auto tmp1 = $1;
        res = new IR(kSpProcStmtInReturnsClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_labeled_block {
        auto tmp1 = $1;
        res = new IR(kSpProcStmtInReturnsClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_unlabeled_block {
        auto tmp1 = $1;
        res = new IR(kSpProcStmtInReturnsClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_labeled_control {
        auto tmp1 = $1;
        res = new IR(kSpProcStmtInReturnsClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_compound_ok {
        auto tmp1 = $1;
        res = new IR(kSpProcStmtInReturnsClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_proc_stmt:

    sp_labeled_block {
        auto tmp1 = $1;
        res = new IR(kSpProcStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_unlabeled_block {
        auto tmp1 = $1;
        res = new IR(kSpProcStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_labeled_control {
        auto tmp1 = $1;
        res = new IR(kSpProcStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_unlabeled_control {
        auto tmp1 = $1;
        res = new IR(kSpProcStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_labelable_stmt {
        auto tmp1 = $1;
        res = new IR(kSpProcStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | labels_declaration_oracle sp_labelable_stmt {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpProcStmt, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


sp_proc_stmt_compound_ok:

    sp_proc_stmt_if {
        auto tmp1 = $1;
        res = new IR(kSpProcStmtCompoundOk, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | case_stmt_specification {
        auto tmp1 = $1;
        res = new IR(kSpProcStmtCompoundOk, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_unlabeled_block {
        auto tmp1 = $1;
        res = new IR(kSpProcStmtCompoundOk, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_unlabeled_control {
        auto tmp1 = $1;
        res = new IR(kSpProcStmtCompoundOk, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



sp_labeled_block:

    sp_block_label BEGIN_ORACLE_SYM {} sp_block_statements_and_exceptions END sp_opt_label {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpLabeledBlock_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSpLabeledBlock_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kSpLabeledBlock_3, OP3("", "", "END"), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kSpLabeledBlock, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | sp_block_label DECLARE_ORACLE_SYM {} opt_sp_decl_body_list {} BEGIN_ORACLE_SYM sp_block_statements_and_exceptions END sp_opt_label {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpLabeledBlock_4, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSpLabeledBlock_5, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kSpLabeledBlock_6, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kSpLabeledBlock_7, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $6;
        res = new IR(kSpLabeledBlock_8, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $7;
        res = new IR(kSpLabeledBlock_9, OP3("", "", "END"), res, tmp7);
        PUSH(res);
        auto tmp8 = $9;
        res = new IR(kSpLabeledBlock, OP3("", "", ""), res, tmp8);
        $$ = res;
    }

;


sp_unlabeled_block:

    BEGIN_ORACLE_SYM opt_not_atomic {} sp_block_statements_and_exceptions END {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpUnlabeledBlock_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSpUnlabeledBlock_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kSpUnlabeledBlock, OP3("", "", "END"), res, tmp4);
        $$ = res;
    }

    | DECLARE_ORACLE_SYM {} opt_sp_decl_body_list {} BEGIN_ORACLE_SYM sp_block_statements_and_exceptions END {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpUnlabeledBlock_3, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSpUnlabeledBlock_4, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kSpUnlabeledBlock_5, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kSpUnlabeledBlock_6, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $6;
        res = new IR(kSpUnlabeledBlock, OP3("", "", "END"), res, tmp6);
        $$ = res;
    }

;


sp_unlabeled_block_not_atomic:

    BEGIN_MARIADB_SYM not ATOMIC_SYM {} sp_decls sp_proc_stmts END {
        auto tmp1 = $2;
        auto tmp2 = $4;
        res = new IR(kSpUnlabeledBlockNotAtomic_1, OP3("BEGIN_MARIADB_SYM", "ATOMIC_SYM", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kSpUnlabeledBlockNotAtomic_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kSpUnlabeledBlockNotAtomic, OP3("", "", "END"), res, tmp4);
        $$ = res;
    }

;


%endif MARIADB


%ifdef ORACLE

=== statement ===

=== sp_statement ===

=== sp_if_then_statements ===

=== sp_case_then_statements ===

=== reserved_keyword_udt ===



=== keyword_sp_block_section ===





=== keyword_label ===

=== keyword_sp_decl ===

=== opt_truncate_table_storage_clause ===


=== ident_for_loop_index ===

=== row_field_name ===

=== while_body ===

=== for_loop_statements ===


=== sp_control_label ===

=== sp_block_label ===



remember_end_opt:

    remember_end_opt: {
        auto tmp1 = $1;
        res = new IR(kRememberEndOpt, OP3("", "", ""), tmp1);
        $$ = res;
    }

;

=== sp_opt_default ===


sp_opt_inout:

    empty {
        auto tmp1 = $1;
        res = new IR(kSpOptInout, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_parameter_type {
        auto tmp1 = $1;
        res = new IR(kSpOptInout, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IN_SYM OUT_SYM {
        res = new IR(kSpOptInout, OP3("IN_SYM OUT_SYM", "", ""));
        $$ = res;
    }

;


sp_proc_stmts1_implicit_block:

    {} sp_proc_stmts1 {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpProcStmts1ImplicitBlock, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;



remember_lex:

    remember_lex: {
        auto tmp1 = $1;
        res = new IR(kRememberLex, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


keyword_directly_assignable:

    keyword_data_type {
        auto tmp1 = $1;
        res = new IR(kKeywordDirectlyAssignable, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_cast_type {
        auto tmp1 = $1;
        res = new IR(kKeywordDirectlyAssignable, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_set_special_case {
        auto tmp1 = $1;
        res = new IR(kKeywordDirectlyAssignable, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_var_and_label {
        auto tmp1 = $1;
        res = new IR(kKeywordDirectlyAssignable, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sp_var_not_label {
        auto tmp1 = $1;
        res = new IR(kKeywordDirectlyAssignable, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_sysvar_type {
        auto tmp1 = $1;
        res = new IR(kKeywordDirectlyAssignable, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FUNCTION_SYM {
        res = new IR(kKeywordDirectlyAssignable, OP3("FUNCTION_SYM", "", ""));
        $$ = res;
    }

    | WINDOW_SYM {
        res = new IR(kKeywordDirectlyAssignable, OP3("WINDOW_SYM", "", ""));
        $$ = res;
    }

;


ident_directly_assignable:

    IDENT_sys {
        auto tmp1 = $1;
        res = new IR(kIdentDirectlyAssignable, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_directly_assignable {
        auto tmp1 = $1;
        res = new IR(kIdentDirectlyAssignable, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


ident_cli_directly_assignable:

    IDENT_cli {
        auto tmp1 = $1;
        res = new IR(kIdentCliDirectlyAssignable, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | keyword_directly_assignable {
        auto tmp1 = $1;
        res = new IR(kIdentCliDirectlyAssignable, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



set_assign:

    ident_cli_directly_assignable SET_VAR {} set_expr_or_default {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSetAssign_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSetAssign_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kSetAssign, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

    | ident_cli_directly_assignable '.' ident SET_VAR {} set_expr_or_default {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kSetAssign_3, OP3("", ".", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSetAssign_4, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kSetAssign_5, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kSetAssign, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

    | COLON_ORACLE_SYM ident '.' ident SET_VAR {} set_expr_or_default {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSetAssign_6, OP3("", "", "."), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSetAssign_7, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $5;
        res = new IR(kSetAssign_8, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $6;
        res = new IR(kSetAssign_9, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $7;
        res = new IR(kSetAssign, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

;



labels_declaration_oracle:

    label_declaration_oracle {
        auto tmp1 = $1;
        res = new IR(kLabelsDeclarationOracle, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | labels_declaration_oracle label_declaration_oracle {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kLabelsDeclarationOracle, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


label_declaration_oracle:

    SHIFT_LEFT label_ident SHIFT_RIGHT {
        auto tmp1 = $2;
        res = new IR(kLabelDeclarationOracle, OP3("SHIFT_LEFT", "SHIFT_RIGHT", ""), tmp1);
        $$ = res;
    }

;


opt_exception_clause:

    empty {
        auto tmp1 = $1;
        res = new IR(kOptExceptionClause, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | EXCEPTION_ORACLE_SYM exception_handlers {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptExceptionClause, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


exception_handlers:

    exception_handler {
        auto tmp1 = $1;
        res = new IR(kExceptionHandlers, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | exception_handlers exception_handler {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kExceptionHandlers, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


exception_handler:

    WHEN_SYM {} sp_hcond_list THEN_SYM sp_proc_stmts1_implicit_block {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kExceptionHandler_1, OP3("WHEN_SYM", "", "THEN_SYM"), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $5;
        res = new IR(kExceptionHandler, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

;


sp_no_param:

    empty {
        auto tmp1 = $1;
        res = new IR(kSpNoParam, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_sp_parenthesized_fdparam_list:

    sp_no_param {
        auto tmp1 = $1;
        res = new IR(kOptSpParenthesizedFdparamList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_parenthesized_fdparam_list {
        auto tmp1 = $1;
        res = new IR(kOptSpParenthesizedFdparamList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_sp_parenthesized_pdparam_list:

    sp_no_param {
        auto tmp1 = $1;
        res = new IR(kOptSpParenthesizedPdparamList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_parenthesized_pdparam_list {
        auto tmp1 = $1;
        res = new IR(kOptSpParenthesizedPdparamList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



opt_sp_name:

    empty {
        auto tmp1 = $1;
        res = new IR(kOptSpName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_name {
        auto tmp1 = $1;
        res = new IR(kOptSpName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



opt_package_routine_end_name:

    empty {
        auto tmp1 = $1;
        res = new IR(kOptPackageRoutineEndName, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident {
        auto tmp1 = $1;
        res = new IR(kOptPackageRoutineEndName, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_tail_is:

    IS {
        res = new IR(kSpTailIs, OP3("IS", "", ""));
        $$ = res;
    }

    | AS {
        res = new IR(kSpTailIs, OP3("AS", "", ""));
        $$ = res;
    }

;


sp_instr_addr:

    sp_instr_addr: {
        auto tmp1 = $1;
        res = new IR(kSpInstrAddr, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_body:

    {} opt_sp_decl_body_list {} BEGIN_ORACLE_SYM sp_block_statements_and_exceptions {} END {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpBody_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSpBody_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kSpBody_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kSpBody_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $6;
        res = new IR(kSpBody, OP3("", "", "END"), res, tmp6);
        $$ = res;
    }

;


create_package_chistic:

    COMMENT_SYM TEXT_STRING_sys {
        auto tmp1 = $2;
        res = new IR(kCreatePackageChistic, OP3("COMMENT_SYM", "", ""), tmp1);
        $$ = res;
    }

    | sp_suid {
        auto tmp1 = $1;
        res = new IR(kCreatePackageChistic, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


create_package_chistics:

    create_package_chistic {
        auto tmp1 = $1;
        res = new IR(kCreatePackageChistics, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | create_package_chistics create_package_chistic {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kCreatePackageChistics, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


opt_create_package_chistics:

    empty {
        auto tmp1 = $1;
        res = new IR(kOptCreatePackageChistics, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | create_package_chistics {
        auto tmp1 = $1;
        res = new IR(kOptCreatePackageChistics, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


opt_create_package_chistics_init:

    {} opt_create_package_chistics {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kOptCreatePackageChisticsInit, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;



package_implementation_executable_section:

    END {
        res = new IR(kPackageImplementationExecutableSection, OP3("END", "", ""));
        $$ = res;
    }

    | BEGIN_ORACLE_SYM sp_block_statements_and_exceptions END {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPackageImplementationExecutableSection, OP3("", "", "END"), tmp1, tmp2);
        $$ = res;
    }

;








package_implementation_declare_section:

    package_implementation_declare_section_list1 {
        auto tmp1 = $1;
        res = new IR(kPackageImplementationDeclareSection, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | package_implementation_declare_section_list2 {
        auto tmp1 = $1;
        res = new IR(kPackageImplementationDeclareSection, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | package_implementation_declare_section_list1 package_implementation_declare_section_list2 {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPackageImplementationDeclareSection, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


package_implementation_declare_section_list1:

    package_implementation_item_declaration {
        auto tmp1 = $1;
        res = new IR(kPackageImplementationDeclareSectionList1, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | package_implementation_declare_section_list1 package_implementation_item_declaration {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPackageImplementationDeclareSectionList1, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


package_implementation_declare_section_list2:

    package_implementation_routine_definition {
        auto tmp1 = $1;
        res = new IR(kPackageImplementationDeclareSectionList2, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | package_implementation_declare_section_list2 package_implementation_routine_definition {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPackageImplementationDeclareSectionList2, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


package_routine_lex:

    package_routine_lex: {
        auto tmp1 = $1;
        res = new IR(kPackageRoutineLex, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



package_specification_function:

    remember_lex package_routine_lex ident {} opt_sp_parenthesized_fdparam_list RETURN_ORACLE_SYM sf_return_type sp_c_chistics {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPackageSpecificationFunction_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kPackageSpecificationFunction_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kPackageSpecificationFunction_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kPackageSpecificationFunction_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $6;
        res = new IR(kPackageSpecificationFunction_5, OP3("", "", ""), res, tmp6);
        PUSH(res);
        auto tmp7 = $7;
        res = new IR(kPackageSpecificationFunction_6, OP3("", "", ""), res, tmp7);
        PUSH(res);
        auto tmp8 = $8;
        res = new IR(kPackageSpecificationFunction, OP3("", "", ""), res, tmp8);
        $$ = res;
    }

;


package_specification_procedure:

    remember_lex package_routine_lex ident {} opt_sp_parenthesized_pdparam_list sp_c_chistics {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPackageSpecificationProcedure_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kPackageSpecificationProcedure_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kPackageSpecificationProcedure_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kPackageSpecificationProcedure_4, OP3("", "", ""), res, tmp5);
        PUSH(res);
        auto tmp6 = $6;
        res = new IR(kPackageSpecificationProcedure, OP3("", "", ""), res, tmp6);
        $$ = res;
    }

;



package_implementation_routine_definition:

    FUNCTION_SYM package_specification_function package_implementation_function_body ';' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kPackageImplementationRoutineDefinition, OP3("FUNCTION_SYM", "", ";"), tmp1, tmp2);
        $$ = res;
    }

    | PROCEDURE_SYM package_specification_procedure package_implementation_procedure_body ';' {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kPackageImplementationRoutineDefinition, OP3("PROCEDURE_SYM", "", ";"), tmp1, tmp2);
        $$ = res;
    }

    | package_specification_element {
        auto tmp1 = $1;
        res = new IR(kPackageImplementationRoutineDefinition, OP3("", "", ""), tmp1);
        $$ = res;
    }

;



package_implementation_function_body:

    sp_tail_is remember_lex {} sp_body opt_package_routine_end_name {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPackageImplementationFunctionBody_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kPackageImplementationFunctionBody_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kPackageImplementationFunctionBody_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kPackageImplementationFunctionBody, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;


package_implementation_procedure_body:

    sp_tail_is remember_lex {} sp_body opt_package_routine_end_name {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPackageImplementationProcedureBody_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kPackageImplementationProcedureBody_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kPackageImplementationProcedureBody_3, OP3("", "", ""), res, tmp4);
        PUSH(res);
        auto tmp5 = $5;
        res = new IR(kPackageImplementationProcedureBody, OP3("", "", ""), res, tmp5);
        $$ = res;
    }

;



package_implementation_item_declaration:

    sp_decl_variable_list ';' {
        auto tmp1 = $1;
        res = new IR(kPackageImplementationItemDeclaration, OP3("", ";", ""), tmp1);
        $$ = res;
    }

;


opt_package_specification_element_list:

    empty {
        auto tmp1 = $1;
        res = new IR(kOptPackageSpecificationElementList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | package_specification_element_list {
        auto tmp1 = $1;
        res = new IR(kOptPackageSpecificationElementList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


package_specification_element_list:

    package_specification_element {
        auto tmp1 = $1;
        res = new IR(kPackageSpecificationElementList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | package_specification_element_list package_specification_element {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kPackageSpecificationElementList, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;


package_specification_element:

    FUNCTION_SYM package_specification_function ';' {
        auto tmp1 = $2;
        res = new IR(kPackageSpecificationElement, OP3("FUNCTION_SYM", ";", ""), tmp1);
        $$ = res;
    }

    | PROCEDURE_SYM package_specification_procedure ';' {
        auto tmp1 = $2;
        res = new IR(kPackageSpecificationElement, OP3("PROCEDURE_SYM", ";", ""), tmp1);
        $$ = res;
    }

;

=== sp_decl_variable_list_anchored ===

=== sp_param_name_and_mode ===

=== sp_param ===

=== sp_param_anchored ===


=== sf_c_chistics_and_body_standalone ===

=== sp_tail_standalone ===

=== drop_routine ===


=== create_routine ===


opt_sp_decl_body_list:

    empty {
        auto tmp1 = $1;
        res = new IR(kOptSpDeclBodyList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_decl_body_list {
        auto tmp1 = $1;
        res = new IR(kOptSpDeclBodyList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_decl_body_list:

    sp_decl_non_handler_list {} opt_sp_decl_handler_list {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpDeclBodyList_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSpDeclBodyList, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | sp_decl_handler_list {
        auto tmp1 = $1;
        res = new IR(kSpDeclBodyList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_decl_non_handler_list:

    sp_decl_non_handler ';' {
        auto tmp1 = $1;
        res = new IR(kSpDeclNonHandlerList, OP3("", ";", ""), tmp1);
        $$ = res;
    }

    | sp_decl_non_handler_list sp_decl_non_handler ';' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpDeclNonHandlerList, OP3("", "", ";"), tmp1, tmp2);
        $$ = res;
    }

;


sp_decl_handler_list:

    sp_decl_handler ';' {
        auto tmp1 = $1;
        res = new IR(kSpDeclHandlerList, OP3("", ";", ""), tmp1);
        $$ = res;
    }

    | sp_decl_handler_list sp_decl_handler ';' {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpDeclHandlerList, OP3("", "", ";"), tmp1, tmp2);
        $$ = res;
    }

;


opt_sp_decl_handler_list:

    empty {
        auto tmp1 = $1;
        res = new IR(kOptSpDeclHandlerList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_decl_handler_list {
        auto tmp1 = $1;
        res = new IR(kOptSpDeclHandlerList, OP3("", "", ""), tmp1);
        $$ = res;
    }

;


sp_decl_non_handler:

    sp_decl_variable_list {
        auto tmp1 = $1;
        res = new IR(kSpDeclNonHandler, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ident_directly_assignable CONDITION_SYM FOR_SYM sp_cond {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kSpDeclNonHandler, OP3("", "CONDITION_SYM FOR_SYM", ""), tmp1, tmp2);
        $$ = res;
    }

    | ident_directly_assignable EXCEPTION_ORACLE_SYM {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpDeclNonHandler, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | CURSOR_SYM ident_directly_assignable {} opt_parenthesized_cursor_formal_parameters IS sp_cursor_stmt {
        auto tmp1 = $2;
        auto tmp2 = $3;
        res = new IR(kSpDeclNonHandler_1, OP3("CURSOR_SYM", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $4;
        res = new IR(kSpDeclNonHandler_2, OP3("", "", "IS"), res, tmp3);
        PUSH(res);
        auto tmp4 = $6;
        res = new IR(kSpDeclNonHandler, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;


=== sp_proc_stmt ===


sp_labelable_stmt:

    sp_proc_stmt_statement {
        auto tmp1 = $1;
        res = new IR(kSpLabelableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_continue_oracle {
        auto tmp1 = $1;
        res = new IR(kSpLabelableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_exit_oracle {
        auto tmp1 = $1;
        res = new IR(kSpLabelableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_leave {
        auto tmp1 = $1;
        res = new IR(kSpLabelableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_iterate {
        auto tmp1 = $1;
        res = new IR(kSpLabelableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_goto_oracle {
        auto tmp1 = $1;
        res = new IR(kSpLabelableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_with_cursor {
        auto tmp1 = $1;
        res = new IR(kSpLabelableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_return {
        auto tmp1 = $1;
        res = new IR(kSpLabelableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | sp_proc_stmt_if {
        auto tmp1 = $1;
        res = new IR(kSpLabelableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | case_stmt_specification {
        auto tmp1 = $1;
        res = new IR(kSpLabelableStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NULL_SYM {
        res = new IR(kSpLabelableStmt, OP3("NULL_SYM", "", ""));
        $$ = res;
    }

;

=== sp_proc_stmt_compound_ok ===


=== sp_labeled_block ===


opt_not_atomic:

    empty {
        auto tmp1 = $1;
        res = new IR(kOptNotAtomic, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | not ATOMIC_SYM {
        auto tmp1 = $1;
        res = new IR(kOptNotAtomic, OP3("", "ATOMIC_SYM", ""), tmp1);
        $$ = res;
    }

;

=== sp_unlabeled_block ===


sp_block_statements_and_exceptions:

    sp_instr_addr sp_proc_stmts {} opt_exception_clause {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kSpBlockStatementsAndExceptions_1, OP3("", "", ""), tmp1, tmp2);
        PUSH(res);
        auto tmp3 = $3;
        res = new IR(kSpBlockStatementsAndExceptions_2, OP3("", "", ""), res, tmp3);
        PUSH(res);
        auto tmp4 = $4;
        res = new IR(kSpBlockStatementsAndExceptions, OP3("", "", ""), res, tmp4);
        $$ = res;
    }

;