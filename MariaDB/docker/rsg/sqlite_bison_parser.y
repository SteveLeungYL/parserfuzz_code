%%
/*********************************
 ** Section 3: Grammar Definition
 *********************************/

// Defines our general input.
input:
        opt_semicolon statement_list opt_semicolon {
            $$ = NULL;
            result->opt_semicolon_prefix_ = $1;
            result->statement_list_ = $2;
            result->opt_semicolon_suffix_ = $3;
        }
    ;


statement_list:
        statement {
            $$ = new StatementList();
            $$->v_statement_list_.push_back($1);
        }
    |   statement_list opt_semicolon statement {
            $1->v_opt_semicolon_list_.push_back($2);
            $1->v_statement_list_.push_back($3);
            $$ = $1;
        }
    ;

statement:
        preparable_statement {
            $$ = new Statement();
            $$->sub_type_ = CASE0;
            $$->preparable_statement_ = $1;
        }
    |   explain preparable_statement {
            $$ = new Statement();
            $$->sub_type_ = CASE1;
            $$->explain_ = $1;
            $$->preparable_statement_ = $2;
        }
    ;

explain:
        EXPLAIN QUERY PLAN {
            $$ = new Explain();
            $$->sub_type_ = CASE0;
            $$->str_val_ = "EXPLAIN QUERY PLAN";
        }
    |   EXPLAIN {
            $$ = new Explain();
            $$->sub_type_ = CASE0;
            $$->str_val_ = "EXPLAIN";
        }

preparable_statement:
    /* have checked */
        alter_statement   { $$ = $1; }
    |   analyze_statement { $$ = $1; }
    |   attach_statement  { $$ = $1; }
    |   begin_statement   { $$ = $1; }
    |   commit_statement  { $$ = $1; }
    |   create_statement  { $$ = $1; }
    |   delete_statement  { $$ = $1; }
    |   detach_statement  { $$ = $1; }
    |   drop_statement    { $$ = $1; }
    |   insert_statement  { $$ = $1; }
    |   pragma_statement  { $$ = $1; }
    |   reindex_statement { $$ = $1; }
    |   release_statement { $$ = $1; }
    |   rollback_statement  {$$ = $1;}
    |   savepoint_statement { $$ = $1; }
    |   select_statement  { $$ = $1; }
    |   update_statement  { $$ = $1; }
    |   vacuum_statement  { $$ = $1; }
    ;
    /* being checked*/
    /* to be checked*/
    /* to be supported */
    /* |   delete_statement_limited { $$ = $1; } // SQLITE_ENABLE_UPDATE_DELETE_LIMIT */
    /* |   update_statement_limited { $$ = $1; } // SQLITE_ENABLE_UPDATE_DELETE_LIMIT */


release_statement:
        RELEASE SAVEPOINT IDENTIFIER {
            $$ = new ReleaseStatement();
            $$->sub_type_ = CASE0;
            $$->savepoint_name_ = new Identifier($3, id_savepoint_name);
            free($3);
        }
    |   RELEASE IDENTIFIER {
            $$ = new ReleaseStatement();
            $$->sub_type_ = CASE1;
            $$->savepoint_name_ = new Identifier($2, id_savepoint_name);
            free($2);
        }
    ;

pragma_statement:
        PRAGMA pragma_key{
            $$ = new PragmaStatement();
            $$->sub_type_ = CASE0;
            $$->pragma_key_ = $2;
        }
    |   PRAGMA pragma_key '=' pragma_value {
            $$ = new PragmaStatement();
            $$->sub_type_ = CASE1;
            $$->pragma_key_ = $2;
            $$->pragma_value_ = $4;
    }
    |   PRAGMA pragma_key '(' pragma_value ')' {
            $$ = new PragmaStatement();
            $$->sub_type_ = CASE2;
            $$->pragma_key_ = $2;
            $$->pragma_value_ = $4;
    }
    ;

reindex_statement:
        REINDEX {$$ = new ReindexStatement(); $$->sub_type_ = CASE0;}
    |   REINDEX table_name {$$ = new ReindexStatement(); $$->sub_type_ = CASE1; $$->table_name_ = $2; $$->table_name_->identifier_->id_type_ = id_top_table_name;}
    /* TODO: also accepts collation-name / index-name, but it seems the grammar does not distingusih them */
    ;

analyze_statement:
        ANALYZE {$$ = new AnalyzeStatement(); $$->sub_type_ = CASE0;}
    |   ANALYZE table_name {$$ = new AnalyzeStatement(); $$->sub_type_ = CASE1; $$->table_name_ = $2; $$->table_name_->identifier_->id_type_ = id_top_table_name;}
    ;

attach_statement:
        ATTACH new_expr AS schema_name{
            $$ = new AttachStatement();
            $$->sub_type_ = CASE0;
            $$->expr_ = $2;
            $$->schema_name_ = $4;
        }
    |   ATTACH DATABASE new_expr AS schema_name{
            $$ = new AttachStatement();
            $$->sub_type_ = CASE1;
            $$->expr_ = $3;
            $$->schema_name_ = $5;
        }
    ;

detach_statement:
        DETACH schema_name {
            $$ = new DetachStatement();
            $$->sub_type_ = CASE0;
            $$->schema_name_ = $2;
        }
    |   DETACH DATABASE schema_name{
            $$ = new DetachStatement();
            $$->sub_type_ = CASE1;
            $$->schema_name_ = $3;
    }
    ;

pragma_key:
        pragma_name {$$ = new PragmaKey(); $$->sub_type_ = CASE0; $$->pragma_name_ = $1;}
    |   schema_name '.' pragma_name { $$ = new PragmaKey(); $$->sub_type_ = CASE1; $$->schema_name_ = $1; $$->pragma_name_ = $3;}
    ;

pragma_value:
        signed_number {$$ = new PragmaValue(); $$->sub_type_ = CASE0; $$->signed_number_ = $1;}
    |   string_literal {$$ = new PragmaValue(); $$->sub_type_ = CASE1; $$->string_literal_ = $1;}
    |   IDENTIFIER {$$ = new PragmaValue(); $$->sub_type_ = CASE2; $$->identifier_ = new Identifier($1, id_pragma_value); free($1);}
    |   ON {$$ = new PragmaValue(); $$->sub_type_ = CASE2; $$->identifier_ = new Identifier("ON", id_pragma_value); }
    |   OFF {$$ = new PragmaValue(); $$->sub_type_ = CASE2; $$->identifier_ = new Identifier("OFF", id_pragma_value); }
    |   DELETE {$$ = new PragmaValue(); $$->sub_type_ = CASE2; $$->identifier_ = new Identifier("DELETE", id_pragma_value); }
    |   DEFAULT {$$ = new PragmaValue(); $$->sub_type_ = CASE2; $$->identifier_ = new Identifier("DEFAULT", id_pragma_value); }
    ;

schema_name:
        IDENTIFIER { $$ = new SchemaName(); $$->identifier_ = new Identifier($1, id_schema_name); free($1); }
    ;

pragma_name:
        IDENTIFIER {$$ = new PragmaName(); $$->identifier_ = new Identifier($1, id_pragma_name); free($1);}
    ;

savepoint_statement:
        SAVEPOINT IDENTIFIER { $$ = new SavepointStatement(); $$->savepoint_name_ = new Identifier($2, id_create_savepoint_name); free($2); }
    ;

rollback_statement: // add z
        ROLLBACK opt_transaction opt_to_savepoint {
            $$ = new RollbackStatement();
            $$->opt_transaction_ = $2;
            $$->opt_to_savepoint_ = $3;
        }
 ;

opt_transaction: // add z
        TRANSACTION {
            $$ = new OptTransaction();
            $$->str_val_ = "TRANSACTION";
        }
    |   /* empty */{
            $$ = new OptTransaction();
            $$->str_val_ = "";
        }
 ;

 opt_to_savepoint: //add z
        TO IDENTIFIER {
            $$ = new OptToSavepoint();
            $$->sub_type_ = CASE0;
            $$->savepoint_name_ = new Identifier($2, id_savepoint_name);
            free($2);
        }
    |   TO SAVEPOINT IDENTIFIER {
            $$ = new OptToSavepoint();
            $$->sub_type_ = CASE1;
            $$->savepoint_name_ = new Identifier($3, id_savepoint_name);
            free($3);
        }
    |   /* empty */{
            $$ = new OptToSavepoint();
            $$->sub_type_ = CASE2;
        }
 ;


vacuum_statement: //add z
        VACUUM opt_schema_name INTO file_path{
            $$ = new VacuumStatement();
            $$->sub_type_ = CASE0;
            $$->opt_schema_name_ = $2;
            $$->file_path_ = $4;
        }
    |   VACUUM opt_schema_name{
            $$ = new VacuumStatement();
            $$->sub_type_ = CASE1;
            $$->opt_schema_name_ = $2;
        }
    ;

opt_schema_name: //add z
        schema_name {
            $$ = new OptSchemaName();
            $$->sub_type_ = CASE0;
            $$->schema_name_ = $1;
        }
    |   /*empty*/ {
            $$ = new OptSchemaName();
            $$->sub_type_ = CASE1;
        }
    ;

begin_statement: //add z
        BEGIN opt_transaction {
            $$ = new BeginStatement();
            $$->sub_type_ = CASE0;
            $$->opt_transaction_ = $2;
        }
    |   BEGIN DEFFERED opt_transaction {
            $$ = new BeginStatement();
            $$->sub_type_ = CASE1;
            $$->opt_transaction_ = $3;
        }
    |   BEGIN IMEDIATE opt_transaction {
            $$ = new BeginStatement();
            $$->sub_type_ = CASE2;
            $$->opt_transaction_ = $3;
        }
    |   BEGIN EXCLUSIVE opt_transaction {
            $$ = new BeginStatement();
            $$->sub_type_ = CASE3;
            $$->opt_transaction_ = $3;
        }
 ;

commit_statement: //add z
        COMMIT opt_transaction {
            $$ = new CommitStatement();
            $$->sub_type_ = CASE0;
            $$->opt_transaction_ = $2;
        }
    |   END opt_transaction {
            $$ = new CommitStatement();
            $$->sub_type_ = CASE1;
            $$->opt_transaction_ = $2;
        }
 ;

partition_by:
        PARTITION BY expr_list { $$ = new PartitionBy(); $$->expr_list_ = $3; }

opt_partition_by:
        partition_by { $$ = new OptPartitionBy(); $$->sub_type_ = CASE0; $$->partition_by_ = $1; }
    |   /* empty */  { $$ = new OptPartitionBy(); $$->sub_type_ = CASE1; }

opt_upsert_clause:
        upsert_clause {$$ = new OptUpsertClause(); $$->sub_type_ = CASE0; $$->upsert_clause_ = $1;}
    |   /* empty */ {$$ = new OptUpsertClause(); $$->sub_type_ = CASE1;}

upsert_clause:
        upsert_item { $$ = new UpsertClause(); $$->v_upsert_item_list_.push_back($1); }
    |   upsert_clause upsert_item { $1->v_upsert_item_list_.push_back($2); $$ = $1; }
    ;

upsert_item:
        ON CONFLICT opt_conflict_target DO NOTHING {
          $$ = new UpsertItem();
          $$->sub_type_ = CASE0;
          $$->opt_conflict_target_ = $3;
        }
    |   ON CONFLICT opt_conflict_target DO UPDATE SET assign_list opt_where {
          $$ = new UpsertItem();
          $$->sub_type_ = CASE1;
          $$->opt_conflict_target_ = $3;
          $$->assign_list_ = $7;
          $$->opt_where_ = $8;
        }
    ;

opt_conflict_target:
        conflict_target { $$ = new OptConflictTarget(); $$->sub_type_ = CASE0; $$->conflict_target_ = $1; }
    |   /* empty */ { $$ = new OptConflictTarget(); $$->sub_type_ = CASE1; }
    ;

conflict_target:
        '(' indexed_column_list ')' opt_where {
          $$ = new ConflictTarget();
          $$->indexed_column_list_ = $2;
          $$->opt_where_ = $4;
        }
    ;


indexed_column_list:
        indexed_column {
            $$ = new IndexedColumnList();
            $$->v_indexed_column_list_.push_back($1);
        }
    |   indexed_column_list ',' indexed_column {
            $1->v_indexed_column_list_.push_back($3);
            $$ = $1;
        }
 ;

indexed_column:
        new_expr opt_collate opt_order_type {
            $$ = new IndexedColumn();
            $$->expr_ = $1;
            $$->opt_collate_ = $2;
            $$->opt_order_type_ = $3;
        }
 ;

collate:
        COLLATE IDENTIFIER {
            $$ = new Collate();
            $$->collate_name_ = new Identifier($2, id_collation_name);
            free($2);
        }
    ;


opt_collate:
        collate {
          $$ = new OptCollate();
          $$->sub_type_ = CASE0;
          $$->collate_ = $1;
        }
    |   /* empty */{
          $$ = new OptCollate();
          $$->sub_type_ = CASE1;
        }
 ;


assign_list:
        assign_clause {
            $$ = new AssignList();
            $$->v_assign_list_.push_back($1);

        }
    |   assign_list ',' assign_clause {
            $1->v_assign_list_.push_back($3);
            $$ = $1;
        }
 ;


opt_order_of_null:
        NULLS FIRST {
            $$ = new OptOrderOfNull();
            $$->str_val_ = "NULLS FIRST";
        }
    |   NULLS LAST {
            $$ = new OptOrderOfNull();
            $$->str_val_ = "NULLS LAST";
        }
    |   {
            $$ = new OptOrderOfNull();
            $$->str_val_ = "";
        }
    ;

null_of_expr:
        ISNULL { $$ = new NullOfExpr(); $$->str_val_ = "ISNULL"; }
    |   NOTNULL { $$ = new NullOfExpr(); $$->str_val_ = "NOTNULL"; }
    |   NOT NULL { $$ = new NullOfExpr(); $$->str_val_ = "NOT NULL"; }
    ;

exists_or_not:
        EXISTS { $$ = new ExistsOrNot(); $$->str_val_ = "EXISTS"; }
    |   NOT EXISTS { $$ = new ExistsOrNot(); $$->str_val_ = "NOT EXISTS"; }
    ;

assign_clause:
        column_name '=' new_expr {
            $$ = new AssignClause();
            $$->sub_type_ = CASE0;
            $$->column_name_ = $1;
            $$->expr_ = $3;
        }

    |   '(' column_name_list ')' '=' new_expr {
            $$ = new AssignClause();
            $$->sub_type_ = CASE1;
            $$->column_name_list_ = $2;
            $$->expr_ = $5;
        }
 ;

column_name_list:
        column_name {
            $$ = new ColumnNameList();
            $$->v_column_name_list_.push_back($1);
        }
    |   column_name_list ',' column_name {
            $1->v_column_name_list_.push_back($3);
            $$ = $1;
        }
;

file_path:
        string_literal {
            $$ = new FilePath();
            $$->str_val_ = $1->str_val_;
            delete($1);
         }
    ;

/*****************************
 * Alter statement
 * ALTER TABLE a RENAME TO b;
 * ALTER TABLE a ADD COLUMN c(name INT);
 *****************************/
alter_statement:
        ALTER TABLE table_name RENAME TO table_name {
          $$ = new AlterStatement();
          $$->sub_type_ = CASE0;
          $$->table_name1_ = $3;
          $$->table_name1_->identifier_->id_type_ = id_top_table_name;
          $$->table_name2_ = $6;
          $$->table_name2_->identifier_->id_type_ = id_create_table_name;
        }
    |   ALTER TABLE table_name RENAME opt_column column_name TO one_column_name {
          $$ = new AlterStatement();
          $$->sub_type_ = CASE1;
          $$->table_name1_ = $3;
          $$->table_name1_->identifier_->id_type_ = id_top_table_name;
          $$->opt_column_ = $5;
          $$->column_name1_ = $6;
          $$->column_name2_ = $8;
          $$->column_name2_->identifier_col_->id_type_ = id_create_column_name;
        }
    |   ALTER TABLE table_name ADD opt_column column_def {
          $$ = new AlterStatement();
          $$->sub_type_ = CASE2;
          $$->table_name1_ = $3;
          $$->table_name1_->identifier_->id_type_ = id_top_table_name;
          $$->opt_column_ = $5;
          $$->column_def_ = $6;
        }
    |   ALTER TABLE table_name DROP opt_column column_name {
          $$ = new AlterStatement();
          $$->sub_type_ = CASE3;
          $$->table_name1_ = $3;
          $$->table_name1_->identifier_->id_type_ = id_top_table_name;
          $$->opt_column_ = $5;
          $$->column_name1_ = $6;
        }
    ;

opt_column:
	COLUMN {
		$$ = new OptColumn();
    $$->str_val_ = "COLUMN";
	}
 |	/* empty */{
		$$ = new OptColumn();
    $$->str_val_ = "";
	}
 ;

/******************************
 * Create Statement
 * CREATE TABLE students (name TEXT, student_number INTEGER, city TEXT, grade DOUBLE)
 * CREATE TABLE students FROM TBL FILE 'test/students.tbl'
 ******************************/

create_table_statement:
        CREATE opt_tmp TABLE opt_if_not_exists table_name AS select_statement {
          $$ = new CreateTableStatement();
          $$->sub_type_ = CASE0;
          $$->opt_tmp_ = NULL; $2->deep_delete(); // we do not want TEMP
          $$->opt_if_not_exists_ = $4;
          $5->identifier_->id_type_ = id_create_table_name;
          $$->table_name_ = $5;
          $$->select_statement_ = $7;
        }
    |   CREATE opt_tmp TABLE opt_if_not_exists table_name '(' column_def_list ')' opt_without_rowid opt_strict {
          $$ = new CreateTableStatement();
          $$->sub_type_ = CASE1;
          $$->opt_tmp_ = NULL; $2->deep_delete(); // we do not want TEMP
          $$->opt_if_not_exists_ = $4;
          $5->identifier_->id_type_ = id_create_table_name;
          $$->table_name_ = $5;
          $$->column_def_list_ = $7;
          $$->opt_without_rowid_ = $9;
          $$->opt_strict_ = $10;
        }
    |   CREATE opt_tmp TABLE opt_if_not_exists table_name '(' column_def_list ',' table_constraint_list ')' opt_without_rowid opt_strict {
          $$ = new CreateTableStatement();
          $$->sub_type_ = CASE2;
          $$->opt_tmp_ = NULL; $2->deep_delete(); // we do not want TEMP
          $$->opt_if_not_exists_ = $4;
          $5->identifier_->id_type_ = id_create_table_name;
          $$->table_name_ = $5;
          $$->column_def_list_ = $7;
          $$->table_constraint_list_ = $9;
          $$->opt_without_rowid_ = $11;
          $$->opt_strict_ = $12;
        }
    ;

create_view_statement:
        CREATE opt_tmp VIEW opt_if_not_exists table_name opt_column_list_paren AS select_statement {
            $$ = new CreateViewStatement();
            $$->opt_tmp_ = $2;
            $$->opt_if_not_exists_ = $4;
            $$->view_name_ = $5;
            $$->view_name_->identifier_->id_type_ = id_create_table_name;
            $$->opt_column_list_paren_ = $6;
            $$->select_statement_ = $8;
            if ($$) {
                auto tmp1 = $$->opt_column_list_paren_;
                if (tmp1) {
                    auto tmp2 = tmp1->column_name_list_;
                    if(tmp2) {
                        for (auto& tmp3 : tmp2->v_column_name_list_) {
                            if (tmp3->identifier_col_) {
                                tmp3->identifier_col_->id_type_ = id_create_column_name;
                            }
                        }
                    }
                }
            }
        }
    ;

create_index_statement:
        CREATE opt_unique INDEX opt_if_not_exists index_name ON table_name '(' indexed_column_list ')' opt_where {
            $$ = new CreateIndexStatement();
            $$->opt_unique_ = $2;
            $$->opt_if_not_exists_ = $4;
            $$->index_name_ = $5;
            $$->index_name_->identifier_->id_type_ = id_create_index_name;;
            $$->table_name_ = $7;
            $$->table_name_->identifier_->id_type_ = id_top_table_name;
            $$->indexed_column_list_ = $9;
            $$->opt_where_ = $11;
            /* indexed_column_list is defined as id_index_name */
        }
    ;

create_virtual_table_statement:
        CREATE VIRTUAL TABLE  opt_if_not_exists table_name USING module_name opt_column_list_paren opt_without_rowid {
            $$ = new CreateVirtualTableStatement();
            $$->opt_if_not_exists_ = $4;
            $$->table_name_ = $5;
            $$->table_name_->identifier_->id_type_ = id_create_table_name;
            $$->module_name_ = $7;
            $$->opt_column_list_paren_ = $8;
            $$->opt_without_rowid_ = $9;
            if ($$) {
                auto tmp1 = $$->opt_column_list_paren_;
                if (tmp1) {
                    auto tmp2 = tmp1->column_name_list_;
                    if(tmp2) {
                        for (auto& tmp3 : tmp2->v_column_name_list_) {
                            if (tmp3->identifier_col_) {
                                if (get_rand_int(100) < 50) {
                                    tmp3->identifier_col_->id_type_ = id_create_column_name;
                                } else {
                                    tmp3->identifier_col_->id_type_ = id_top_column_name;
                                }
                            }
                        }
                    }
                }
            }
        }
    ;

create_trigger_statement:
        CREATE opt_tmp TRIGGER opt_if_not_exists trigger_name opt_trigger_time trigger_event ON table_name opt_for_each opt_when BEGIN trigger_cmd_list END {
            $$ = new CreateTriggerStatement();
            $$->opt_tmp_ = $2;
            $$->opt_if_not_exists_ = $4;
            $$->trigger_name_ = $5;
            $$->trigger_name_->identifier_->id_type_ = id_create_trigger_name;;
            $$->opt_trigger_time_ = $6;
            $$->trigger_event_ = $7;
            $$->table_name_ = $9;
            $$->table_name_->identifier_->id_type_ = id_top_table_name;
            $$->opt_for_each_ = $10;
            $$->opt_when_ = $11;
            $$->trigger_cmd_list_ = $13;
        }
    ;

create_statement:
        create_table_statement { $$ = $1; }
    |   create_view_statement { $$ = $1; }
    |   create_index_statement { $$ = $1; }
    |   create_virtual_table_statement { $$ = $1; }
    |   create_trigger_statement { $$ = $1; }
    ;

opt_without_rowid:
        WITHOUT ROWID {$$ = new OptWithoutRowID(); $$->str_val_ = "WITHOUT ROWID";}
    |   /* empty */  {{$$ = new OptWithoutRowID(); $$->str_val_ = "";}}

opt_strict:
        STRICT  {$$ = new OptStrict(); $$->str_val_ = "STRICT"; }
    |   ',' STRICT  {$$ = new OptStrict(); $$->str_val_ = ", STRICT"; }
    |   /* empty */  {$$ = new OptStrict(); $$->str_val_ = ""; }

opt_unique:
        UNIQUE {$$ = new OptUnique(); $$->str_val_ = "UNIQUE";}
    | /* empty */ {$$ = new OptUnique(); $$->str_val_ = "";}
    ;

opt_tmp:
        TEMP {$$ = new OptTmp(); $$->str_val_ = "TEMP";}
    |   TEMPORARY {$$ = new OptTmp(); $$->str_val_ = "TEMPORARY";}
    |   /* empty */  {$$ = new OptTmp(); $$->str_val_ = "";}
    ;

opt_trigger_time:
        BEFORE {$$ = new OptTriggerTime(); $$->str_val_ = "BEFORE";}
    |   AFTER {$$ = new OptTriggerTime(); $$->str_val_ = "AFTER";}
    |   INSTEAD OF {$$ = new OptTriggerTime(); $$->str_val_ = "INSTEAD OF";}
    |   /* empty */ {$$ = new OptTriggerTime(); $$->str_val_ = "";}
    ;

trigger_event:
        DELETE {$$ = new TriggerEvent(); $$->sub_type_ = CASE0;}
    |   INSERT {$$ = new TriggerEvent(); $$->sub_type_ = CASE1;}
    |   UPDATE opt_of_column_list {$$ = new TriggerEvent(); $$->sub_type_ = CASE2; $$->opt_of_column_list_ = $2;}
    ;

opt_of_column_list:
        OF column_name_list {$$ = new OptOfColumnList(); $$->sub_type_ = CASE0; $$->column_name_list_ = $2;}
    |   /* empty */ {$$ = new OptOfColumnList(); $$->sub_type_ = CASE1;}
    ;

opt_for_each:
        FOR EACH ROW {$$ = new OptForEach(); $$->str_val_ = "FOR EACH ROW";}
    |   /* empty */ {$$ = new OptForEach(); $$->str_val_ = "";}
    ;

opt_when:
        WHEN new_expr {$$ = new OptWhen(); $$->sub_type_ = CASE0; $$->expr_ = $2;}
    |   /* empty */ {$$ = new OptWhen(); $$->sub_type_ = CASE1;}
    ;

trigger_cmd_list:
        trigger_cmd ';' {$$ = new TriggerCmdList(); $$->v_trigger_cmd_list_.push_back($1);}
    |   trigger_cmd_list trigger_cmd ';' {$1->v_trigger_cmd_list_.push_back($2); $$ = $1;}
    ;

trigger_cmd:
        select_statement {$$ = new TriggerCmd(); $$->stmt_ = $1;}
    |   update_statement {$$ = new TriggerCmd(); $$->stmt_ = $1;}
    |   insert_statement {$$ = new TriggerCmd(); $$->stmt_ = $1;}
    |   delete_statement {$$ = new TriggerCmd(); $$->stmt_ = $1;}
    ;

module_name:
        IDENTIFIER {$$ = new ModuleName(); $$->identifier_ = new Identifier($1); free($1);}
    ;

opt_not:
        NOT { $$ = new OptNot(); $$->sub_type_ = CASE0; }
    |   /* empty */ { $$ = new OptNot(); $$->sub_type_ = CASE1; }
    ;

opt_recursive:
        RECURSIVE { $$ = new OptRecursive(); $$->str_val_ = "RECURSIVE"; }
    |   /* empty */ { $$ = new OptRecursive(); $$->str_val_ = ""; }

opt_if_not_exists:
        IF NOT EXISTS { $$ = new OptIfNotExists(); $$->str_val_ = "IF NOT EXISTS"; }
    |   /* empty */ { $$ = new OptIfNotExists(); $$->str_val_ = ""; }
    ;

column_def_list:
        column_def {
            $$ = new ColumnDefList();
            $$->v_column_def_list_.push_back($1);
            }
    |   column_def_list ',' column_def {
            $1->v_column_def_list_.push_back($3);
            $$ = $1;
            }
    ;

table_constraint_list:
        table_constraint {
            $$ = new TableConstraintList();
            $$->v_table_constraint_list_.push_back($1);
            }
    |   table_constraint_list table_constraint {
            $1->v_table_constraint_list_.push_back($2);
            $$ = $1;
            }
    |   table_constraint_list ',' table_constraint {
            $1->v_table_constraint_list_.push_back($3);
            $$ = $1;
            }
    ;


table_constraint:
        opt_constraint_name CHECK '(' new_expr ')' {
            $$ = new TableConstraint();
            $$->sub_type_ = CASE0;
            $$->opt_constraint_name_ = $1;
            $$->expr_ = $4;
          }
    |   opt_constraint_name PRIMARY KEY '(' indexed_column_list ')' opt_conflict_clause {
            $$ = new TableConstraint();
            $$->sub_type_ = CASE1;
            $$->opt_constraint_name_ = $1;
            $$->indexed_column_list_ = $5;
            $$->opt_conflict_clause_ = $7;
          }
    |   opt_constraint_name UNIQUE '(' indexed_column_list ')' opt_conflict_clause {
            $$ = new TableConstraint();
            $$->sub_type_ = CASE2;
            $$->opt_constraint_name_ = $1;
            $$->indexed_column_list_ = $4;
            $$->opt_conflict_clause_ = $6;
          }
    |   opt_constraint_name FOREIGN KEY '(' column_name_list ')' foreign_key_clause {
            $$ = new TableConstraint();
            $$->sub_type_ = CASE3;
            $$->opt_constraint_name_ = $1;
            $$->column_name_list_ = $5;
            $$->foreign_key_clause_ = $7;
        }
    ;

column_def:
        IDENTIFIER column_type opt_column_constraintlist {
            $$ = new ColumnDef();
            $$->identifier_ = new Identifier($1, id_create_column_name);
            $$->column_type_ = $2;
            $$->opt_column_constraintlist_ = $3;
            free($1);
        }
    ;


opt_column_constraintlist:
        column_constraintlist {$$ = new OptColumnConstraintlist(); $$->sub_type_ = CASE0; $$->column_constraintlist_ = $1;}
    |   /* empty */ {$$ = new OptColumnConstraintlist(); $$->sub_type_ = CASE1;}
    ;

column_constraintlist:
        column_constraintlist column_constraint {
            $1->v_column_constraint_.push_back($2);
            $$ = $1;
            }
    |   column_constraint {
        $$ = new ColumnConstraintlist();
        $$->v_column_constraint_.push_back($1);
        }
    ;

/* looks good */
opt_constraint_name:
        CONSTRAINT IDENTIFIER {
            $$ = new OptConstraintName();
            $$->sub_type_ = CASE0;
            $$->identifier_ = new Identifier($2, id_table_constraint_name);
            free($2);
          }
    |   /* empty */ {
            $$ = new OptConstraintName();
            $$->sub_type_ = CASE1;
          }
    ;

opt_deferrable_clause:
        deferrable_clause { $$ = new OptDeferrableClause(); $$->sub_type_ = CASE0; $$->deferrable_clause_ = $1; }
    |   /* empty */ { $$ = new OptDeferrableClause(); $$->sub_type_ = CASE1; }
    ;

deferrable_clause:
        opt_not DEFERRABLE { $$ = new DeferrableClause(); $$->opt_not_ = $1; $$->str_val_ = ""; }
    |   opt_not DEFERRABLE INITIALLY DEFERRED { $$ = new DeferrableClause(); $$->opt_not_ = $1; $$->str_val_ = "INITIALLY DEFERRED"; }
    |   opt_not DEFERRABLE INITIALLY IMMEDIATE { $$ = new DeferrableClause(); $$->opt_not_ = $1; $$->str_val_ = "INITIALLY IMMEDIATE"; }
    ;

opt_foreign_key_on_list:
        foreign_key_on_list { $$ = new OptForeignKeyOnList(); $$->sub_type_ = CASE0; $$->foreign_key_on_list_ = $1; }
    |   /* empty */ { $$ = new OptForeignKeyOnList(); $$->sub_type_ = CASE1; }
    ;

foreign_key_on_list:
        foreign_key_on { $$ = new ForeignKeyOnList(); $$->v_foreign_key_on_list_.push_back($1); }
    |   foreign_key_on_list foreign_key_on { $1->v_foreign_key_on_list_.push_back($2); $$ = $1; }
    ;

foreign_key_on:
        ON DELETE SET NULL    { $$ = new ForeignKeyOn(); $$->sub_type_ = CASE0; $$->str_val_ = "ON DELETE SET NULL"; }
    |   ON DELETE SET DEFAULT { $$ = new ForeignKeyOn(); $$->sub_type_ = CASE0; $$->str_val_ = "ON DELETE SET DEFAULT"; }
    |   ON DELETE CASCADE     { $$ = new ForeignKeyOn(); $$->sub_type_ = CASE0; $$->str_val_ = "ON DELETE CASCADE"; }
    |   ON DELETE RESTRICT    { $$ = new ForeignKeyOn(); $$->sub_type_ = CASE0; $$->str_val_ = "ON DELETE RESTRICT"; }
    |   ON DELETE NO ACTION   { $$ = new ForeignKeyOn(); $$->sub_type_ = CASE0; $$->str_val_ = "ON DELETE NO ACTION"; }
    |   ON UPDATE SET NULL    { $$ = new ForeignKeyOn(); $$->sub_type_ = CASE0; $$->str_val_ = "ON UPDATE SET NULL"; }
    |   ON UPDATE SET DEFAULT { $$ = new ForeignKeyOn(); $$->sub_type_ = CASE0; $$->str_val_ = "ON UPDATE SET DEFAULT"; }
    |   ON UPDATE CASCADE     { $$ = new ForeignKeyOn(); $$->sub_type_ = CASE0; $$->str_val_ = "ON UPDATE CASCADE"; }
    |   ON UPDATE RESTRICT    { $$ = new ForeignKeyOn(); $$->sub_type_ = CASE0; $$->str_val_ = "ON UPDATE RESTRICT"; }
    |   ON UPDATE NO ACTION   { $$ = new ForeignKeyOn(); $$->sub_type_ = CASE0; $$->str_val_ = "ON UPDATE NO ACTION"; }
    |   MATCH IDENTIFIER      { $$ = new ForeignKeyOn(); $$->sub_type_ = CASE1; $$->identifier_ = new Identifier($2); free($2); }
    ;

foreign_key_clause:
        REFERENCES IDENTIFIER opt_column_list_paren opt_foreign_key_on_list opt_deferrable_clause {
          $$ = new ForeignKeyClause();
          $$->foreign_table_ = new Identifier($2); free($2);
          $$->opt_column_list_paren_ = $3;
          $$->opt_foreign_key_on_list_ = $4;
          $$->opt_deferrable_clause_ = $5;
        }
    ;

column_constraint:
        opt_constraint_name PRIMARY KEY opt_order_type opt_conflict_clause opt_autoinc {
          $$ = new ColumnConstraint();
          $$->sub_type_ = CASE0;
          $$->opt_constraint_name_ = $1;
          $$->opt_order_type_ = $4;
          $$->opt_conflict_clause_ = $5;
          $$->opt_autoinc_ = $6;
        }
    |   opt_constraint_name opt_not NULL opt_conflict_clause {
          $$ = new ColumnConstraint();
          $$->sub_type_ = CASE1;
          $$->opt_constraint_name_ = $1;
          $$->opt_not_ = $2;
          $$->opt_conflict_clause_ = $4;
        }
    |   opt_constraint_name UNIQUE opt_conflict_clause {
          $$ = new ColumnConstraint();
          $$->sub_type_ = CASE2;
          $$->opt_constraint_name_ = $1;
          $$->opt_conflict_clause_ = $3;
        }
    |   opt_constraint_name CHECK '(' new_expr ')' {
          $$ = new ColumnConstraint();
          $$->sub_type_ = CASE3;
          $$->opt_constraint_name_ = $1;
          $$->expr_ = $4;
        }
    |   DEFAULT '(' new_expr ')' {
          $$ = new ColumnConstraint();
          $$->sub_type_ = CASE4;
          $$->expr_ = $3;
        }
    |   DEFAULT literal {
          $$ = new ColumnConstraint();
          $$->sub_type_ = CASE5;
          $$->literal_ = $2;
        }
    |   DEFAULT signed_number {
          $$ = new ColumnConstraint();
          $$->sub_type_ = CASE6;
          $$->signed_number_ = $2;
        }
    |   collate {
          $$ = new ColumnConstraint();
          $$->sub_type_ = CASE7;
          $$->collate_ = $1;
        }
    |   opt_constraint_name foreign_key_clause {
          $$ = new ColumnConstraint();
          $$->sub_type_ = CASE8;
          $$->opt_constraint_name_ = $1;
          $$->foreign_key_clause_ = $2;
        }
    |   GENERATED ALWAYS AS '(' new_expr ')' opt_stored_virtual {
          $$ = new ColumnConstraint();
          $$->sub_type_ = CASE9;
          $$->expr_ = $5;
          $$->opt_stored_virtual_ = $7;
        }
    |   AS '(' new_expr ')' opt_stored_virtual {
          $$ = new ColumnConstraint();
          $$->sub_type_ = CASE10;
          $$->expr_ = $3;
          $$->opt_stored_virtual_ = $5;
        }
    |   GENERATED ALWAYS {
          $$ = new ColumnConstraint();
          $$->sub_type_ = CASE11;
    }
    ;

opt_stored_virtual:
        STORED { $$ = new OptStoredVirtual(); $$->str_val_ = "STORED"; }
    |   VIRTUAL  { $$ = new OptStoredVirtual(); $$->str_val_ = "VIRTUAL"; }
    |   /* empty */ { $$ = new OptStoredVirtual(); $$->str_val_ = ""; }
    ;

/* looks good */
opt_conflict_clause:
        ON CONFLICT resolve_type {$$ = new OptConflictClause(); $$->sub_type_ = CASE0; $$->resolve_type_ = $3;}
    |   /* empty */ {$$ = new OptConflictClause(); $$->sub_type_ = CASE1;}
    ;

/* looks good */
resolve_type:
        ABORT {$$ = new ResolveType(); $$->str_val_ = "ABORT";}
    |   FAIL {$$ = new ResolveType(); $$->str_val_ = "FAIL";}
    |   IGNORE {$$ = new ResolveType(); $$->str_val_ = "IGNORE";}
    |   REPLACE {$$ = new ResolveType(); $$->str_val_ = "REPLACE";}
    |   ROLLBACK {$$ = new ResolveType(); $$->str_val_ = "ROLLBACK";}
    ;

/* looks good */
/* seems the keyword AUTOINCREMENT is not supported by sqlite, weird */
opt_autoinc:
        AUTOINCR {$$ = new OptAutoinc(); $$->str_val_ = "AUTOINCR";}
    |   AUTOINCREMENT {$$ = new OptAutoinc(); $$->str_val_ = "AUTOINCREMENT";}
    |   /* empty */ {$$ = new OptAutoinc(); $$->str_val_ = "";}
    ;


column_type:
           INT { $$ = new ColumnType(); $$->str_val_ = string("INT"); }
    |   INT2 { $$ = new ColumnType(); $$->str_val_ = string("INT2"); }
    |   INT8 { $$ = new ColumnType(); $$->str_val_ = string("INT8"); }
    |   INTEGER { $$ = new ColumnType(); $$->str_val_ = string("INTEGER"); }
    |   TINYINT { $$ = new ColumnType(); $$->str_val_ = string("TINYINT"); }
    |   SMALLINT { $$ = new ColumnType(); $$->str_val_ = string("SMALLINT"); }
    |   MEDIUMINT { $$ = new ColumnType(); $$->str_val_ = string("MEDIUMINT"); }
    |   BIGINT { $$ = new ColumnType(); $$->str_val_ = string("BIGINT"); }
    |   UNSIGNED BIG INT { $$ = new ColumnType(); $$->str_val_ = string("UNSIGNED BIG INT"); }
    |   LONG { $$ = new ColumnType(); $$->str_val_ = string("LONG"); }
    |   FLOAT { $$ = new ColumnType(); $$->str_val_ = string("FLOAT"); }
    |   DOUBLE { $$ = new ColumnType(); $$->str_val_ = string("DOUBLE"); }
    |   DOUBLE PRECISION { $$ = new ColumnType(); $$->str_val_ = string("DOUBLE PRECISION"); }
    |   CHAR '(' INTVAL ')' { $$ = new ColumnType();
            $$->str_val_ = string("CHAR(") + to_string($3) + ")";
            }
    |   CHARACTER '(' INTVAL ')' { $$ = new ColumnType();
            $$->str_val_ = string("CHARACTER(") + to_string($3) + ")";
            }
    |   VARCHAR '(' INTVAL ')' {
            $$ = new ColumnType();
            $$->str_val_ = string("VARCHAR(") + to_string($3) + ")";
            }
    |   VARYING CHARACTER '(' INTVAL ')' {
            $$ = new ColumnType();
            $$->str_val_ = string("VARYING CHARACTER(") + to_string($4) + ")";
            }
    |   NCHAR '(' INTVAL ')' { $$ = new ColumnType();
            $$->str_val_ = string("NCHAR(") + to_string($3) + ")";
            }
    |   NATIVE CHARACTER '(' INTVAL ')' { $$ = new ColumnType();
            $$->str_val_ = string("NATIVE CHARACTER(") + to_string($4) + ")";
            }
    |   NVARCHAR '(' INTVAL ')' { $$ = new ColumnType();
            $$->str_val_ = string("NVARCHAR(") + to_string($3) + ")";
            }
    |   TEXT { $$ = new ColumnType(); $$->str_val_ = string("TEXT"); }
    |   CLOB { $$ = new ColumnType(); $$->str_val_ = string("CLOB"); }
    |   BLOB { $$ = new ColumnType(); $$->str_val_ = string("BLOB"); }
    |   REAL { $$ = new ColumnType(); $$->str_val_ = string("REAL"); }
    |   NUMERIC { $$ = new ColumnType(); $$->str_val_ = string("NUMERIC"); }
    |   NUM     { $$ = new ColumnType(); $$->str_val_ = string("NUM"); }
    |   BOOL { $$ = new ColumnType(); $$->str_val_ = string("BOOL"); }
    |   BOOLEAN { $$ = new ColumnType(); $$->str_val_ = string("BOOLEAN"); }
    |   DECIMAL '(' INTVAL ',' INTVAL ')' {
                $$ = new ColumnType();
                $$->str_val_ = string("DECIMAL(") + to_string($3) + "," + to_string($5) + ")";
            }
    |   DATE { $$ = new ColumnType(); $$->str_val_ = string("DATE"); }
    |   DATETIME { $$ = new ColumnType(); $$->str_val_ = string("DATETIME"); }
    |   STRINGTOKEN  {$$ = new ColumnType(); $$->str_val_ = string("STRING"); }
    |   ANY  {$$ = new ColumnType(); $$->str_val_ = string("ANY"); }
    |   /* empty*/ { $$ = new ColumnType(); $$->str_val_ = string(""); }
    ;

/******************************
 * Drop Statement
 * DROP TABLE students;
 * DEALLOCATE PREPARE stmt;
 ******************************/

drop_table_statement:
        DROP TABLE opt_if_exists table_name {
            $$ = new DropTableStatement();
            $$->opt_if_exists_ = $3;
            $$->table_name_ = $4;
            $$->table_name_->identifier_->id_type_ = id_top_table_name;
        }
    ;

drop_index_statement:
        DROP INDEX opt_if_exists index_name {
            $$ = new DropIndexStatement();
            $$->opt_if_exists_ = $3;
            $$->index_name_ = $4;
        }
    ;

drop_view_statement:
        DROP VIEW opt_if_exists table_name {
            $$ = new DropViewStatement();
            $$->opt_if_exists_ = $3;
            $$->view_name_ = $4;
            $$->view_name_->identifier_->id_type_ = id_top_table_name;
        }
    ;

drop_trigger_statement:
        DROP TRIGGER opt_if_exists trigger_name {
            $$ = new DropTriggerStatement();
            $$->opt_if_exists_ = $3;
            $$->trigger_name_ = $4;
        }
    ;

drop_statement:
        drop_table_statement { $$ = $1; }
    |   drop_index_statement { $$ = $1; }
    |   drop_view_statement  { $$ = $1; }
    |   drop_trigger_statement { $$ = $1; }
    ;

opt_if_exists:
        IF EXISTS   { $$ = new OptIfExists(); $$->str_val_ = "IF EXISTS"; }
    |   /* empty */ { $$ = new OptIfExists(); $$->str_val_ = ""; }
    ;

/******************************
 * Delete Statement / Truncate statement
 * DELETE FROM students WHERE grade > 3.0
 * DELETE FROM students <=> TRUNCATE students
 ******************************/
delete_statement:
        opt_with_clause DELETE FROM qualified_table_name opt_where opt_returning_clause {
            $$ = new DeleteStatement();
            $$->opt_with_clause_ = $1;
            $$->qualified_table_name_ = $4;
            $$->opt_where_ = $5;
            $$->opt_returning_clause_ = $6;
        }
    ;

/******************************
 * Insert Statement
 * INSERT INTO students VALUES ('Max', 1112233, 'Musterhausen', 2.3)
 * INSERT INTO employees SELECT * FROM stundents
 ******************************/
insert_statement:
        opt_with_clause insert_type table_name opt_table_alias_as opt_column_list_paren insert_value opt_returning_clause {
            $$ = new InsertStatement();
            $$->sub_type_ = CASE0;
            $$->opt_with_clause_ = $1;
            $$->insert_type_ = $2;
            $$->table_name_ = $3;
            $$->table_name_->identifier_->id_type_ = id_top_table_name;
            $$->opt_table_alias_as_ = $4;
            $$->opt_column_list_paren_ = $5;
            $$->insert_value_= $6;
            $$->opt_returning_clause_ = $7;
        }
    ;

insert_value:
        VALUES expr_list_paren_list opt_upsert_clause{
            $$ = new InsertValue();
            $$->sub_type_ = CASE0;
            $$->expr_list_paren_list_ = $2;
            $$->opt_upsert_clause_ = $3;
        }
    |   select_statement opt_upsert_clause{
            $$ = new InsertValue();
            $$->sub_type_ = CASE1;
            $$->select_statement_ = $1;
            $$->opt_upsert_clause_ = $2;
        }
    |   DEFAULT VALUES {
            $$ = new InsertValue();
            $$->sub_type_ = CASE2;
        }
    ;


update_type:
        UPDATE { $$ = new UpdateType(); $$->sub_type_ = CASE0; $$->str_val_ = "UPDATE"; }
    |   UPDATE OR resolve_type {$$ = new UpdateType(); $$->sub_type_ = CASE1; $$->resolve_type_ = $3;}
    ;

insert_type:
        INSERT INTO { $$ = new InsertType(); $$->sub_type_ = CASE0; $$->str_val_ = "INSERT INTO"; }
    |   REPLACE INTO {$$ = new InsertType(); $$->sub_type_ = CASE0; $$->str_val_  = "REPLACE INTO";}
    |   INSERT OR resolve_type INTO {$$ = new InsertType(); $$->sub_type_ = CASE1; $$->resolve_type_ = $3;}
    ;

opt_column_list_paren:
        '(' column_name_list ')' { $$ = new OptColumnListParen(); $$->sub_type_ = CASE0; $$->column_name_list_ = $2; }
    |   /* empty */ { $$ = new OptColumnListParen(); $$->sub_type_ = CASE1; }
    ;

/******************************
 * Update Statement
 * UPDATE students SET grade = 1.3, name='Felix Fürstenberg' WHERE name = 'Max Mustermann';
 ******************************/

update_statement:
    opt_with_clause update_type qualified_table_name SET update_clause_list opt_from_clause opt_where opt_returning_clause {
        $$ = new UpdateStatement();
        $$->opt_with_clause_ = $1;
        $$->update_type_ = $2;
        $$->qualified_table_name_ = $3;
        $$->update_clause_list_ = $5;
        $$->opt_from_clause_ = $6;
        $$->opt_where_ = $7;
        $$->opt_returning_clause_ = $8;
    }
    ;

update_clause_list:
        update_clause {
            $$ = new UpdateClauseList();
            $$->v_update_clause_list_.push_back($1);
            }
    |   update_clause_list ',' update_clause {
        $1->v_update_clause_list_.push_back($3);
        $$ = $1; }
    ;

update_clause:
        one_column_name '=' new_expr {
            $$ = new UpdateClause();
            $$->sub_type_ = CASE0;
            $$->column_name_ = $1;
            $$->expr_ = $3;
        }
    |   '(' column_name_list ')' '=' new_expr {
            $$ = new UpdateClause();
            $$->sub_type_ = CASE1;
            $$->column_name_list_ = $2;
            $$->expr_ = $5;
        }
    ;

/******************************
 * Select Statement
 * SELECT a TABLE table1 WHERE c = 1
 ******************************/

select_statement:
        opt_with_clause select_core_list opt_order opt_limit {
          $$ = new SelectStatement();
          $$->opt_with_clause_ = $1;
          $$->select_core_list_ = $2;
          $$->opt_order_ = $3;
          //$$->opt_limit_ = $4;
          $4->deep_delete(); // we do not want LIMIT
        }
    ;

select_core_list:
        select_core { $$ = new SelectCoreList(); $$->v_select_core_list_.push_back($1); }
    |   select_core_list set_operator select_core {
          $1->v_select_core_list_.push_back($3);
          $1->v_set_operator_list_.push_back($2);
          $$ = $1;
        }
    ;

set_operator:
        UNION {$$ = new SetOperator(); $$->str_val_ = "UNION";}
    |   UNION ALL {$$ = new SetOperator(); $$->str_val_ = "UNION ALL";}
    |   INTERSECT {$$ = new SetOperator(); $$->str_val_ = "INTERSECT";}
    |   EXCEPT  {$$ = new SetOperator(); $$->str_val_ = "EXCEPT";}
    ;

select_core:
        SELECT opt_distinct result_column_list opt_from_clause opt_where opt_group opt_window_clause {
          $$ = new SelectCore();
          $$->sub_type_ = CASE0;
          $$->opt_distinct_ = $2;
          $$->result_column_list_ = $3;
          $$->opt_from_clause_ = $4;
          $$->opt_where_ = $5;
          $$->opt_group_ = $6;
          $$->opt_window_clause_ = $7;
        }
    |   VALUES expr_list_paren_list {
          $$ = new SelectCore();
          $$->sub_type_ = CASE1;
          $$->expr_list_paren_list_ = $2;
        }
    ;

opt_window_clause:
        window_clause { $$ = new OptWindowClause(); $$->sub_type_ = CASE0; $$->window_clause_ = $1; }
    |   /* empty */ { $$ = new OptWindowClause(); $$->sub_type_ = CASE1; }
    ;

window_clause:
        WINDOW windowdefn_list {$$ = new WindowClause(); $$->windowdefn_list_ = $2;}
    ;

windowdefn_list:
        windowdefn {$$ = new WindowDefnList(); $$->v_windowdefn_list_.push_back($1);}
    |   windowdefn_list ',' windowdefn {$1->v_windowdefn_list_.push_back($3); $$ = $1;}
    ;

windowdefn:
        window_name AS '(' window_body ')' {
          $$ = new WindowDefn();
          $1->identifier_->id_type_ = id_create_window_name;
          $$->window_name_ = $1;
          $$->window_body_ = $4;
        }
    ;

window_body:
        opt_base_window_name opt_partition_by opt_order opt_frame {
            $$ = new WindowBody();
            $$->sub_type_ = CASE0;
            $$->opt_base_window_name_ = $1;
            $$->opt_partition_by_ = $2;
            $$->opt_order_ = $3;
            $$->opt_frame_ = $4;
        }
    ;

opt_base_window_name:
        IDENTIFIER {$$ = new OptBaseWindowName(); $$->sub_type_ = CASE0; $$->identifier_ = new Identifier($1, id_base_window_name); free($1);}
    | /* empty */ {$$ = new OptBaseWindowName(); $$->sub_type_ = CASE1;}
    ;

window_name:
        IDENTIFIER { $$ = new WindowName(); $$->identifier_ = new Identifier($1, id_window_name); free($1); }

opt_frame:
        range_or_rows frame_bound opt_frame_exclude {
            $$ = new OptFrame();
            $$->sub_type_ = CASE0;
            $$->range_or_rows_ = $1;
            $$->frame_bound_ = $2;
            $$->opt_frame_exclude_ = $3;
        }
    |   range_or_rows BETWEEN frame_bound_s BTWAND frame_bound_e opt_frame_exclude {
            $$ = new OptFrame();
            $$->sub_type_ = CASE1;
            $$->range_or_rows_ = $1;
            $$->frame_bound_s_ = $3;
            $$->frame_bound_e_ = $5;
            $$->opt_frame_exclude_ = $6;
        }
    |   /* empty */ {$$ = new OptFrame(); $$->sub_type_ = CASE2;}
    ;

range_or_rows:
        RANGE   { $$ = new RangeOrRows(); $$->str_val_ = "RANGE";  }
    |   ROWS    { $$ = new RangeOrRows(); $$->str_val_ = "ROWS";   }
    |   GROUPS  { $$ = new RangeOrRows(); $$->str_val_ = "GROUPS"; }
    ;

frame_bound_s:
        UNBOUNDED PRECEDING { $$ = new FrameBoundS(); $$->sub_type_ = CASE0; $$->str_val_ = "UNBOUNDED PRECEDING"; }
    |   CURRENT ROW { $$ = new FrameBoundS(); $$->sub_type_ = CASE0; $$->str_val_ = "CURRENT ROW"; }
    |   new_expr PRECEDING { $$ = new FrameBoundS(); $$->sub_type_ = CASE1; $$->str_val_ = "PRECEDING"; $$->expr_ = $1; }
    |   new_expr FOLLOWING { $$ = new FrameBoundS(); $$->sub_type_ = CASE1; $$->str_val_ = "FOLLOWING"; $$->expr_ = $1; }
    ;

frame_bound_e:
        UNBOUNDED FOLLOWING { $$ = new FrameBoundE(); $$->sub_type_ = CASE0; $$->str_val_ = "UNBOUNDED FOLLOWING"; }
    |   CURRENT ROW { $$ = new FrameBoundE(); $$->sub_type_ = CASE0; $$->str_val_ = "CURRENT ROW"; }
    |   new_expr PRECEDING { $$ = new FrameBoundE(); $$->sub_type_ = CASE1; $$->str_val_ = "PRECEDING"; $$->expr_ = $1; }
    |   new_expr FOLLOWING { $$ = new FrameBoundE(); $$->sub_type_ = CASE1; $$->str_val_ = "FOLLOWING"; $$->expr_ = $1; }
    ;

frame_bound:
        UNBOUNDED PRECEDING { $$ = new FrameBound(); $$->sub_type_ = CASE0; $$->str_val_ = "UNBOUNDED PRECEDING"; }
    |   CURRENT ROW {$$ = new FrameBound(); $$->sub_type_ = CASE0; $$->str_val_ = "CURRENT ROW"; }
    |   new_expr PRECEDING {$$ = new FrameBound(); $$->sub_type_ = CASE1; $$->str_val_ = "PRECEDING"; $$->expr_ = $1;}
    ;

frame_exclude:
        EXCLUDE NO OTHERS   { $$ = new FrameExclude(); $$->str_val_ = "EXCLUDE NO OTHERS"; }
    |   EXCLUDE CURRENT ROW { $$ = new FrameExclude(); $$->str_val_ = "EXCLUDE CURRENT ROW"; }
    |   EXCLUDE GROUP       { $$ = new FrameExclude(); $$->str_val_ = "EXCLUDE GROUP"; }
    |   EXCLUDE TIES        { $$ = new FrameExclude(); $$->str_val_ = "EXCLUDE TIES"; }
    ;

opt_frame_exclude:
        frame_exclude { $$ = new OptFrameExclude(); $$->sub_type_ = CASE0; $$->frame_exclude_ = $1; }
    |   /* empty */   { $$ = new OptFrameExclude(); $$->sub_type_ = CASE1; }
    ;

opt_distinct:
        DISTINCT { $$ = new OptDistinct();  $$->str_val_ = "DISTINCT";}
    |   ALL { $$ = new OptDistinct();  $$->str_val_ = "ALL";}
    |   /* empty */ { $$ = new OptDistinct();  $$->str_val_ = "";}
    ;

result_column_list:
        result_column { $$ = new ResultColumnList(); $$->v_result_column_list_.push_back($1); }
    |   result_column_list ',' result_column {
          $1->v_result_column_list_.push_back($3);
          $$ = $1;
        }

opt_returning_clause:
        RETURNING returning_column_list { $$ = new OptReturningClause(); $$->sub_type_ = CASE0; $$->returning_column_list_ = $2; }
    |   /* empty */ { $$ = new OptReturningClause(); $$->sub_type_ = CASE1; }
    ;

returning_column_list:
        returning_column { $$ = new ResultColumnList(); $$->v_result_column_list_.push_back($1); }
    |   returning_column_list ',' result_column {
          $1->v_result_column_list_.push_back($3);
          $$ = $1;
        }

result_column:
        new_expr opt_column_alias { $$ = new ResultColumn(); $$->sub_type_ = CASE0; $$->expr_ = $1; $$->opt_column_alias_ = $2; }
    |   '*' { $$ = new ResultColumn(); $$->sub_type_ = CASE1; }
    |   table_name '.' '*' { $$ = new ResultColumn(); $$->sub_type_ = CASE2; $$->table_name_ = $1; }
    ;

returning_column:
        new_expr opt_column_alias { $$ = new ResultColumn(); $$->sub_type_ = CASE0; $$->expr_ = $1; $$->opt_column_alias_ = $2; }
    |   '*' { $$ = new ResultColumn(); $$->sub_type_ = CASE1; }
    ;


opt_from_clause:
        from_clause opt_column_alias  { $$ = new OptFromClause(); $$->sub_type_ = CASE0; $$->from_clause_ = $1; $$->opt_column_alias_ = $2;}
    |   /* empty */  { $$ = new OptFromClause(); $$->sub_type_ = CASE1;}
    ;

from_clause:
        FROM join_clause { $$ = new FromClause(); $$->sub_type_ = CASE0; $$->join_clause_ = $2; }
    |   FROM table_or_subquery_list { $$ = new FromClause(); $$->sub_type_ = CASE1; $$->table_or_subquery_list_ = $2; }
    ;

opt_where:
        where_expr { $$ = new OptWhere(); $$->sub_type_ = CASE0; $$->where_expr_ = $1; }
    |   /* empty */ { $$ = new OptWhere(); $$->sub_type_ = CASE1;}
    ;

opt_else_expr:
        else_expr { $$ = new OptElseExpr(); $$->sub_type_ = CASE0; $$->else_expr_ = $1; }
    |   /* empty */   { $$ = new OptElseExpr(); $$->sub_type_ = CASE1; }
    ;

opt_escape_expr:
        escape_expr { $$ = new OptEscapeExpr(); $$->sub_type_ = CASE0; $$->escape_expr_ = $1; }
    |   /* empty */   { $$ = new OptEscapeExpr(); $$->sub_type_ = CASE1; }
    ;

opt_group:
        GROUP BY expr_list opt_having {
            $$ = new OptGroup();
            $$->sub_type_ = CASE0;
            $$->expr_list_ = $3;
            $$->opt_having_ = $4;
        }
    |   /* empty */ { $$ = new OptGroup(); $$->sub_type_ = CASE1;}
    ;

opt_having:
        HAVING new_expr { $$ = new OptHaving(); $$->sub_type_ = CASE0; $$->expr_ = $2; }
    |   /* empty */ { $$ = new OptHaving(); $$->sub_type_ = CASE1;} ;

opt_order:
        ORDER BY order_list { $$ = new OptOrder(); $$->sub_type_ = CASE0; $$->order_list_ = $3; }
    |   /* empty */ {  $$ = new OptOrder(); $$->sub_type_ = CASE1;}
    ;

order_list:
        order_term { $$ = new OrderList(); $$->v_order_term_.push_back($1); }
    |   order_list ',' order_term { $1->v_order_term_.push_back($3); $$ = $1; }
    ;

order_term:
        new_expr opt_collate opt_order_type opt_order_of_null{
          $$ = new OrderTerm();
          $$->expr_ = $1;
          $$->opt_collate_ = $2;
          $$->opt_order_type_ = $3;
          $$->opt_order_of_null_ = $4;
        }
    ;

/* looks good */
opt_order_type:
        ASC { $$ = new OptOrderType(); $$->str_val_ = "ASC"; }
    |   DESC { $$ = new OptOrderType(); $$->str_val_ = "DESC"; }
    |   /* empty */ { $$ = new OptOrderType(); $$->str_val_ = ""; }
    ;

opt_limit:
        LIMIT new_expr { $$ = new OptLimit(); $$->sub_type_ = CASE0; $$->expr1_ = $2;}
    |   LIMIT new_expr OFFSET new_expr { $$ = new OptLimit(); $$->sub_type_ = CASE1; $$->expr1_ = $2; $$->expr2_ = $4; }
    |   LIMIT new_expr ',' new_expr { $$ = new OptLimit(); $$->sub_type_ = CASE2; $$->expr1_ = $2; $$->expr2_ = $4; }
    |   /* empty */ { $$ = new OptLimit(); $$->sub_type_ = CASE3; }
    ;

/******************************
 * Expressions
 ******************************/

expr_list_paren_list:
        expr_list_paren { $$ = new ExprListParenList(); $$->v_expr_list_paren_list_.push_back($1); }
    |   expr_list_paren_list ',' expr_list_paren { $1->v_expr_list_paren_list_.push_back($3); $$ = $1; }
    ;

expr_list_paren:
        '(' expr_list ')' { $$ = new ExprListParen(); $$->expr_list_ = $2; }

expr_list:
        new_expr {
          $$ = new ExprList();
          $$->v_expr_list_.push_back($1);
        }
    |   expr_list ',' new_expr {
          $1->v_expr_list_.push_back($3);
          $$ = $1;
        }
    ;

function_name:
        IDENTIFIER {
            $$ = new FunctionName();
            $$->identifier_ = new Identifier($1);
            free($1);
        }
;

function_args:
        opt_distinct expr_list { $$ = new FunctionArgs(); $$->sub_type_ = CASE0; $$->opt_distinct_ = $1; $$->expr_list_ = $2; }
    |   '*' { $$ = new FunctionArgs(); $$->sub_type_ = CASE1; $$->str_val_ = string("*"); }
    |   /* empty */ { $$ = new FunctionArgs(); $$->sub_type_ = CASE1; $$->str_val_ = string(""); }

new_expr:
        literal {
          $$ = new NewExpr();
          $$->sub_type_ = CASE0;
          $$->literal_ = $1;
        }
    /* |   TODO: bind parameter */
    |   column_name {
          $$ = new NewExpr();
          $$->sub_type_ = CASE1;
          $$->column_name_ = $1;
        }
    |   unary_op new_expr {
          $$ = new NewExpr();
          $$->sub_type_ = CASE2;
          $$->unary_op_ = $1;
          $$->new_expr1_ = $2;
        }
    |   new_expr binary_op new_expr {
          $$ = new NewExpr();
          $$->sub_type_ = CASE3;
          $$->new_expr1_ = $1;
          $$->binary_op_ = $2;
          $$->new_expr2_ = $3;
        }
    |   function_name '(' function_args ')' opt_filter_clause opt_over_clause {
          $$ = new NewExpr();
          $$->sub_type_ = CASE4;
          $$->function_name_ = $1;
          $$->function_args_ = $3;
          $$->opt_filter_clause_ = $5;
          $$->opt_over_clause_ = $6;
        }
    |   '(' expr_list ')' {
          $$ = new NewExpr();
          $$->sub_type_ = CASE5;
          $$->expr_list_ = $2;
        }
	  |   CAST '(' new_expr AS column_type ')' {
		      $$ = new NewExpr();
          $$->sub_type_ = CASE6;
		      $$->new_expr1_ = $3;
          $$->column_type_ = $5;
	      }
    |   new_expr collate {
          $$ = new NewExpr();
          $$->sub_type_ = CASE7;
          $$->new_expr1_ = $1;
          $$->collate_ = $2;
        }
    |   new_expr opt_not similar_bop new_expr opt_escape_expr {
          $$ = new NewExpr();
          $$->sub_type_ = CASE8;
          $$->new_expr1_ = $1;
          $$->opt_not_ = $2;
          $$->binary_op_ = $3;
          $$->new_expr2_ = $4;
          $$->opt_escape_expr_ = $5;
        }
    |   new_expr null_of_expr {
          $$ = new NewExpr();
          $$->sub_type_ = CASE9;
          $$->new_expr1_ = $1;
          $$->null_of_expr_ = $2;
        }
    /* covered by binary_op */
    /* |  new_expr IS opt_not new_expr */
    |   new_expr opt_not BETWEEN new_expr BTWAND new_expr {
          $$ = new NewExpr();
          $$->sub_type_ = CASE10;
          $$->new_expr1_ = $1;
          $$->opt_not_ = $2;
          $$->new_expr2_ = $4;
          $$->new_expr3_ = $6;
        }
    |   new_expr opt_not in_op in_target {
          $$ = new NewExpr();
          $$->sub_type_ = CASE11;
          $$->new_expr1_ = $1;
          $$->opt_not_ = $2;
          $$->binary_op_ = $3;
          $$->in_target_ = $4;
        }
    |   exists_or_not '(' select_statement ')' {
          $$ = new NewExpr();
          $$->sub_type_ = CASE12;
          $$->exists_or_not_ = $1;
          $$->select_statement_ = $3;
        }
    |   CASE opt_expr case_condition_list opt_else_expr END {
          $$ = new NewExpr();
          $$->sub_type_ = CASE13;
          $$->opt_expr_ = $2;
          $$->case_condition_list_ = $3;
          $$->opt_else_expr_ = $4;
        }
    |   raise_function {
          $$ = new NewExpr();
          $$->sub_type_ = CASE14;
          $$->raise_function_ = $1;
          }
    |   '(' select_statement ')' {
          $$ = new NewExpr();
          $$->sub_type_ = CASE15;
          $$->select_statement_ = $2;
        }
    ;

unary_op:
        '-' { $$ = new UnaryOp(); $$->str_val_ = "-"; }
    |   '+' { $$ = new UnaryOp(); $$->str_val_ = "+"; }
    |   NOT { $$ = new UnaryOp(); $$->str_val_ = "NOT"; }
    |   '~' { $$ = new UnaryOp(); $$->str_val_ = "~"; }
    ;

binary_op:
        CONCAT    { $$ = new BinaryOp(); $$->str_val_ = "||"; }
    |   '*'       { $$ = new BinaryOp(); $$->str_val_ = "*"; }
    |   '/'       { $$ = new BinaryOp(); $$->str_val_ = "/"; }
    |   '%'       { $$ = new BinaryOp(); $$->str_val_ = "%"; }
    |   '+'       { $$ = new BinaryOp(); $$->str_val_ = "+"; }
    |   '-'       { $$ = new BinaryOp(); $$->str_val_ = "-"; }
    |   LSHIFT    { $$ = new BinaryOp(); $$->str_val_ = "<<"; }
    |   RSHIFT    { $$ = new BinaryOp(); $$->str_val_ = ">>"; }
    |   '&'       { $$ = new BinaryOp(); $$->str_val_ = "&"; }
    |   '|'       { $$ = new BinaryOp(); $$->str_val_ = "|"; }
    |   '<'       { $$ = new BinaryOp(); $$->str_val_ = "<"; }
    |   LESSEQ    { $$ = new BinaryOp(); $$->str_val_ = "<="; }
    |   '>'       { $$ = new BinaryOp(); $$->str_val_ = ">"; }
    |   GREATEREQ { $$ = new BinaryOp(); $$->str_val_ = ">="; }
    |   '='       { $$ = new BinaryOp(); $$->str_val_ = "="; }
    |   EQUALS    { $$ = new BinaryOp(); $$->str_val_ = "=="; }
    |   NOTEQUALS { $$ = new BinaryOp(); $$->str_val_ = "!="; }
    |   IS        { $$ = new BinaryOp(); $$->str_val_ = "IS"; }
    /* covered by IS and NOT */
    /* |   IS NOT    { $$ = new BinaryOp(); $$->str_val_ = "IS NOT"; } */
    |   AND       { $$ = new BinaryOp(); $$->str_val_ = "AND"; }
    |   OR        { $$ = new BinaryOp(); $$->str_val_ = "OR"; }
    ;

in_op:
        IN        { $$ = new BinaryOp(); $$->str_val_ = "IN"; }
    ;

similar_bop:
        LIKE      { $$ = new BinaryOp(); $$->str_val_ = "LIKE"; }
    |   GLOB      { $$ = new BinaryOp(); $$->str_val_ = "GLOB"; }
    |   MATCH     { $$ = new BinaryOp(); $$->str_val_ = "MATCH"; }
    |   REGEXP    { $$ = new BinaryOp(); $$->str_val_ = "REGEXP"; }
    ;

in_target:
        '(' ')'   { $$ = new InTarget(); $$->sub_type_ = CASE0; }
    |   '(' select_statement ')' {
          $$ = new InTarget();
          $$->sub_type_ = CASE1;
          $$->select_statement_ = $2;
        }
    |   '(' expr_list ')' {
          $$ = new InTarget();
          $$->sub_type_ = CASE2;
          $$->expr_list_ = $2;
        }
    |   table_name {
          $$ = new InTarget();
          $$->sub_type_ = CASE3;
          $$->table_name_ = $1;
        }
    /* TODO: |   table_function '(' ')' */
    /* TODO: |   table_function '(' expr_list ')' */
    ;

raise_function:
        RAISE '(' IGNORE ')' { $$ = new RaiseFunction(); $$->sub_type_ = CASE0; }
    |   RAISE '(' ROLLBACK ',' STRING ')' {
          $$ = new RaiseFunction();
          $$->sub_type_ = CASE1;
          $$->to_raise_ = "RAISE ( ROLLBACK, ";
          $$->error_msg_ = new Identifier($5);
          free($5);
        }
    |   RAISE '(' ABORT ',' STRING ')' {
          $$ = new RaiseFunction();
          $$->sub_type_ = CASE1;
          $$->to_raise_ = "RAISE ( ABORT, ";
          $$->error_msg_ = new Identifier($5);
          free($5);
        }
    |   RAISE '(' FAIL ',' STRING ')' {
          $$ = new RaiseFunction();
          $$->sub_type_ = CASE1;
          $$->to_raise_ = "RAISE ( FAIL, ";
          $$->error_msg_ = new Identifier($5);
          free($5);
        }
    ;

opt_expr:
        new_expr { $$ = new OptExpr(); $$->sub_type_ = CASE0; $$->expr_ = $1; }
    |   /* empty */ { $$ = new OptExpr(); $$->sub_type_ = CASE1; }
    ;

case_condition:
        WHEN new_expr THEN new_expr { $$ = new CaseCondition(); $$->when_expr_ = $2; $$->then_expr_ = $4; }
    ;

case_condition_list:
        case_condition { $$ = new CaseConditionList(); $$->v_case_condition_list_.push_back($1); }
    |   case_condition_list case_condition { $1->v_case_condition_list_.push_back($2); $$ = $1; }
    ;

opt_over_clause:
        OVER window_name { $$ = new OptOverClause(); $$->sub_type_ = CASE0; $$->window_name_ = $2; }
    |   OVER '(' window_body ')' {
          $$ = new OptOverClause();
          $$->sub_type_ = CASE1;
          $$->window_body_ = $3;
        }
    |   /* emtpy */ {$$ = new OptOverClause(); $$->sub_type_ = CASE2;}
    ;

filter_clause:
        FILTER '(' where_expr ')' {$$ = new FilterClause(); $$->where_expr_ = $3;}

opt_filter_clause:
        filter_clause { $$ = new OptFilterClause(); $$->sub_type_ = CASE0; $$->filter_clause_ = $1; }
    |   /* emtpy */ {$$ = new OptFilterClause(); $$->sub_type_ = CASE1;}
    ;

one_column_name:
        IDENTIFIER {
          $$ = new ColumnName();
          $$->sub_type_ = CASE0;
          $$->identifier_col_ = new Identifier($1, id_column_name);
          free($1);
        }
    |   ROWID {
          $$ = new ColumnName();
          $$->sub_type_ = CASE0;
          $$->identifier_col_ = new Identifier(string("ROWID"), id_column_name);
        }
    |   IDENTIFIER '.' IDENTIFIER {
          $$ = new ColumnName();
          $$->sub_type_ = CASE0;
          //$$->identifier_tbl_ = new Identifier($1, id_table_name);
          $$->identifier_col_ = new Identifier($3, id_column_name);
          free($1);
          free($3);
        }
    |   IDENTIFIER '.' ROWID {
          $$ = new ColumnName();
          $$->sub_type_ = CASE0;
          //$$->identifier_tbl_ = new Identifier($1, id_table_name);
          $$->identifier_col_ = new Identifier(string("ROWID"), id_column_name);
          free($1);
        }
    ;

column_name:
        one_column_name { $$=$1; }
    |   '*' {
          $$ = new ColumnName();
          $$->sub_type_ = CASE2;
        }
    |   IDENTIFIER '.' '*' {
          $$ = new ColumnName();
          $$->sub_type_ = CASE3;
          $$->identifier_tbl_ = new Identifier($1, id_table_name);
          free($1);
        }
    ;

literal:
        numeric_literal { $$ = $1; }
    |   string_literal  { $$ = $1; }
    |   blob_literal    { $$ = $1; }
    |   null_literal    { $$ = $1; }
    |   param_expr      { $$ = $1; }
    ;

string_literal:
        STRING { $$ = new StringLiteral(); $$->str_val_ = $1; free($1);}
    ;

signed_number:
            numeric_literal { $$ = new SignedNumber(); $$->str_sign_ = ""; $$->numeric_literal_ = $1; }
    |   '+' numeric_literal { $$ = new SignedNumber(); $$->str_sign_ = "+"; $$->numeric_literal_ = $2; }
    |   '-' numeric_literal { $$ = new SignedNumber(); $$->str_sign_ = "-"; $$->numeric_literal_ = $2; }
    ;

numeric_literal:
        FLOATVAL { $$ = new NumericLiteral(); $$->value_ = std::to_string($1); }
    |   INTVAL { $$ = new NumericLiteral(); $$->value_ = std::to_string($1); }
    |   HEXVAL { $$ = new NumericLiteral(); $$->value_ = $1; free($1); }
    |   EXPVAL { $$ = new NumericLiteral(); $$->value_ = $1; free($1); }
    |   TRUE { $$ = new NumericLiteral(); $$->value_ = string("TRUE"); }
    |   FALSE { $$ = new NumericLiteral(); $$->value_ = string("FALSE"); }
    |   CURRENT_TIME { $$ = new NumericLiteral(); $$->value_ = string("CURRENT_TIME"); }
    |   CURRENT_DATE { $$ = new NumericLiteral(); $$->value_ = string("CURRENT_DATE"); }
    |   CURRENT_TIMESTAMP { $$ = new NumericLiteral(); $$->value_ = string("CURRENT_TIMESTAMP"); }
    ;

null_literal:
        NULL { $$ = new NullLiteral(); }
    ;

blob_literal:
        BLOBSTRING { $$ = new BlobLiteral(); $$->str_val_ = string($1); free($1); }

param_expr:
        '?' {
            $$ = new ParamExpr();
        }
    ;


/******************************
 * Table
 ******************************/

opt_index:
        INDEXED BY IDENTIFIER {$$ = new OptIndex(); $$->sub_type_ = CASE0; $$->index_name_ = new Identifier($3, id_index_name); free($3); }
    |   NOT INDEXED {$$ = new OptIndex(); $$->sub_type_ = CASE1; }
    |   /*empty*/ {$$ = new OptIndex(); $$->sub_type_ = CASE2; }
    ;

on_expr:
        ON new_expr { $$ = new OnExpr(); $$->expr_ = $2; }
    ;

else_expr:
        ELSE new_expr { $$ = new ElseExpr(); $$->expr_ = $2; }
    ;
where_expr:
        WHERE new_expr { $$ = new WhereExpr(); $$->expr_ = $2; }
    ;

escape_expr:
        ESCAPE new_expr { $$ = new EscapeExpr(); $$->expr_ = $2; }
    ;

qualified_table_name:
        table_name opt_table_alias_as opt_index {
          $$ = new QualifiedTableName();
          $1->identifier_->id_type_ = id_top_table_name;
          $$->table_name_ = $1;
          $$->opt_table_alias_as_ = $2;
          $$->opt_index_ = $3;
        }

trigger_name:
        IDENTIFIER {
          $$ = new TriggerName();
          $$->sub_type_ = CASE0;
          $$->identifier_ = new Identifier($1, id_trigger_name);
          free($1);
        }
    |   IDENTIFIER '.' IDENTIFIER {
          $$ = new TriggerName();
          $$->sub_type_ = CASE1;
          $$->database_id_ = new Identifier($1,id_database_name);
          $$->identifier_ = new Identifier($3, id_trigger_name);
          free($1);
          free($3);
        }
    ;


index_name:
        IDENTIFIER {
          $$ = new IndexName();
          $$->sub_type_ = CASE0;
          $$->identifier_ = new Identifier($1, id_index_name);
          free($1);
        }
    |   IDENTIFIER '.' IDENTIFIER {
          $$ = new IndexName();
          $$->sub_type_ = CASE1;
          $$->database_id_ = new Identifier($1,id_database_name);
          $$->identifier_ = new Identifier($3, id_index_name);
          free($1);
          free($3);
        }
    ;

table_name:
        IDENTIFIER {
          $$ = new TableName();
          $$->sub_type_ = CASE0;
          $$->identifier_ = new Identifier($1, id_table_name);
          free($1);
        }
    |   IDENTIFIER '.' IDENTIFIER {
          $$ = new TableName();
          $$->sub_type_ = CASE1;
          $$->database_id_ = new Identifier($1,id_database_name);
          $$->identifier_ = new Identifier($3, id_table_name);
          free($1);
          free($3);
        }
    ;

table_alias:
        IDENTIFIER {
          $$ = new TableAlias();
          $$->sub_type_ = CASE0;
          $$->alias_id_ = new Identifier($1, id_table_alias_name);
          free($1);
        }
    ;

opt_table_alias:
        table_alias { $$ = new OptTableAlias(); $$->sub_type_ = CASE0; $$->table_alias_ = $1; $$->is_existed_ = true; }
    |   AS table_alias { $$ = new OptTableAlias(); $$->sub_type_ = CASE1; $$->table_alias_ = $2; $$->is_existed_ = true; }
    |   /* empty */ { $$ = new OptTableAlias(); $$->sub_type_ = CASE2; $$->is_existed_ = false; }
    ;

opt_table_alias_as:
        AS table_alias { $$ = new OptTableAliasAs(); $$->sub_type_ = CASE0; $$->table_alias_ = $2; }
    |   /* empty */ { $$ = new OptTableAliasAs(); $$->sub_type_ = CASE1; }
    ;

/* column alias is independent from column */
column_alias:
        IDENTIFIER {
          $$ = new ColumnAlias();
          $$->sub_type_ = CASE0;
          $$->alias_id_ = new Identifier($1, id_column_alias_name);
          free($1);
        }
    |   AS IDENTIFIER {
          $$ = new ColumnAlias();
          $$->sub_type_ = CASE1;
          $$->alias_id_ = new Identifier($2, id_column_alias_name);
          free($2);
        }
    ;

opt_column_alias:
         column_alias { $$ = new OptColumnAlias(); $$->sub_type_ = CASE0; $$->column_alias_ = $1; }
    |    /* empty */ { $$ = new OptColumnAlias(); $$->sub_type_ = CASE1; }
    ;

/******************************
 * With Descriptions
 ******************************/

opt_with_clause:
        with_clause { $$ = new OptWithClause(); $$->sub_type_ = CASE0; $$->with_clause_=$1;}
    |   /* empty */ { $$ = new OptWithClause(); $$->sub_type_ = CASE1; }
    ;

with_clause:
        WITH opt_recursive common_table_expr_list {
          $$ = new WithClause();
          $$->opt_recursive_ = $2;
          $$->common_table_expr_list_ = $3;

          if ($$) {
                auto tmp1 = $$->common_table_expr_list_;
                if (tmp1) {
                    for (auto tmp2 : tmp1->v_common_table_expr_list_) {  // common_table_expr_
                        auto tmp3 = tmp2->table_name_;
                        if (tmp3) {
                            auto tmp_iden_ = tmp3->identifier_;
                            if (tmp_iden_) {
                                if(get_rand_int(100) < 50) {
                                    tmp_iden_->id_type_ = id_create_table_name_with_tmp;
                                } else {
                                    tmp_iden_->id_type_ = id_top_table_name;
                                }
                            }
                        }
                        auto tmp4 = tmp2 -> opt_column_list_paren_;
                        if (tmp4) {
                            auto tmp5 = tmp4->column_name_list_;
                            if (tmp5) {
                                for (auto tmp6 : tmp5->v_column_name_list_) {  // column_name_
                                    if (tmp6->identifier_col_) {
                                        if (get_rand_int(100) < 80) {
                                            tmp6->sub_type_ = CASE0; // Enforce identifier_col_ only. Do not add identifier_tbl_ or '.'
                                            tmp6->identifier_col_->id_type_ = id_create_column_name_with_tmp;
                                        } else {
                                            tmp6->sub_type_ = CASE0; // Enforce identifier_col_ only. Do not add identifier_tbl_ or '.'
                                            tmp6->identifier_col_->id_type_ = id_top_column_name;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
          }
        }
    ;

common_table_expr_list:
        common_table_expr {
          $$ = new CommonTableExprList();
          $$->v_common_table_expr_list_.push_back($1);
        }
    |   common_table_expr_list ',' common_table_expr {
          $1->v_common_table_expr_list_.push_back($3);
          $$ = $1;
        }
    ;

common_table_expr:
        table_name opt_column_list_paren AS '(' select_statement ')' {
          $$ = new CommonTableExpr();
          $$->sub_type_ = CASE0;
          $$->table_name_ = $1;
          $$->opt_column_list_paren_ = $2;
          $$->select_statement_ = $5;
        }
    ;

/******************************
 * Join Statements
 ******************************/

join_op:
        ','                     { $$ = new JoinOp(); $$->str_val_ = ","; }
    |                      JOIN { $$ = new JoinOp(); $$->str_val_ = "JOIN"; }
    |           LEFT       JOIN { $$ = new JoinOp(); $$->str_val_ = "LEFT JOIN"; }
    |           LEFT OUTER JOIN { $$ = new JoinOp(); $$->str_val_ = "LEFT OUTER JOIN"; }
    |           INNER      JOIN { $$ = new JoinOp(); $$->str_val_ = "INNER JOIN"; }
    |           CROSS      JOIN { $$ = new JoinOp(); $$->str_val_ = "CROSS JOIN"; }
    |   NATURAL            JOIN { $$ = new JoinOp(); $$->str_val_ = "NATURAL JOIN"; }
    |   NATURAL LEFT       JOIN { $$ = new JoinOp(); $$->str_val_ = "NATURAL LEFT JOIN"; }
    |   NATURAL LEFT OUTER JOIN { $$ = new JoinOp(); $$->str_val_ = "NATURAL LEFT OUTER JOIN"; }
    |   NATURAL INNER      JOIN { $$ = new JoinOp(); $$->str_val_ = "NATURAL INNER JOIN"; }
    |   NATURAL CROSS      JOIN { $$ = new JoinOp(); $$->str_val_ = "NATURAL CROSS JOIN"; }
    |           RIGHT      JOIN { $$ = new JoinOp(); $$->str_val_ = "RIGHT JOIN"; }
    |          RIGHT OUTER JOIN { $$ = new JoinOp(); $$->str_val_ = "RIGHT OUTER JOIN"; }
    |   NATURAL RIGHT      JOIN { $$ = new JoinOp(); $$->str_val_ = "NATURAL RIGHT JOIN"; }
    |  NATURAL RIGHT OUTER JOIN { $$ = new JoinOp(); $$->str_val_ = "NATURAL RIGHT OUTER JOIN"; }
    |           FULL       JOIN { $$ = new JoinOp(); $$->str_val_ = "FULL JOIN"; }
    |           FULL OUTER JOIN { $$ = new JoinOp(); $$->str_val_ = "FULL OUTER JOIN"; }
    |   NATURAL FULL       JOIN { $$ = new JoinOp(); $$->str_val_ = "NATURAL FULL JOIN"; }
    |   NATURAL FULL OUTER JOIN { $$ = new JoinOp(); $$->str_val_ = "NATURAL FULL OUTER JOIN"; }
    ;

join_constraint:
        on_expr  { $$ = new JoinConstraint(); $$->sub_type_ = CASE0; $$->on_expr_ = $1; }
    |   USING '(' column_name_list ')' { $$ = new JoinConstraint(); $$->sub_type_ = CASE1; $$->column_name_list_ = $3; }
    |   /* empty */ { $$ = new JoinConstraint(); $$->sub_type_ = CASE2; }
    ;

join_suffix:
        join_op table_or_subquery join_constraint {
          $$ = new JoinSuffix();
          $$->join_op_ = $1;
          $$->table_or_subquery_ = $2;
          $$->join_constraint_ = $3;
        }
    ;

join_suffix_list:
        join_suffix { $$ = new JoinSuffixList(); $$->v_join_suffix_list_.push_back($1); }
    |   join_suffix_list join_suffix { $1->v_join_suffix_list_.push_back($2); $$ = $1; }
    ;

join_clause:
        table_or_subquery { $$ = new JoinClause(); $$->sub_type_ = CASE0; $$->table_or_subquery_ = $1; }
    |   table_or_subquery join_suffix_list {
          $$ = new JoinClause();
          $$->sub_type_ = CASE1;
          $$->table_or_subquery_ = $1;
          $$->join_suffix_list_ = $2;
        }
    ;


table_or_subquery_list:
        table_or_subquery { $$ = new TableOrSubqueryList(); $$->v_table_or_subquery_list_.push_back($1); }
    |   table_or_subquery ',' table_or_subquery_list { $3->v_table_or_subquery_list_.push_back($1); $$ = $3; }

table_or_subquery:
        '(' select_statement ')' opt_table_alias {
          $$ = new TableOrSubquery();
          $$->sub_type_ = CASE0;
          $$->select_statement_ = $2;
          $$->opt_table_alias_ = $4;
        }
    |   '(' table_or_subquery_list ')' {
          $$ = new TableOrSubquery();
          $$->sub_type_ = CASE1;
          $$->table_or_subquery_list_ = $2;
        }
    |   table_name opt_table_alias opt_index {
          $$ = new TableOrSubquery();
          $$->sub_type_ = CASE2;
          $1->identifier_->id_type_ = id_top_table_name;
          $$->table_name_ = $1;
          $$->opt_table_alias_ = $2;
          $$->opt_index_ = $3;
        }
    |   '(' join_clause ')' {
          $$ = new TableOrSubquery();
          $$->sub_type_ = CASE3;
          $$->join_clause_ = $2;
        }
    /* |   table_function_name '(' expr_list ')' {} */ // TODO
    ;

/******************************
 * Misc
 ******************************/

opt_semicolon:
        ';' opt_semicolon {$$ = new OptSemicolon(); $$->str_val_ = ";"; $$->opt_semicolon_ = $2;}
    |   /* empty */{$$ = new OptSemicolon(); $$->str_val_ = "";}
    ;


%%