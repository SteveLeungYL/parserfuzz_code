

stmt_block:
  stmt

stmt:
  HELPTOKEN 
| preparable_stmt           
| analyze_stmt              
| copy_from_stmt
| comment_stmt
| execute_stmt              
| deallocate_stmt           
| discard_stmt              
| grant_stmt                
| prepare_stmt              
| revoke_stmt               
| savepoint_stmt            
| reassign_owned_by_stmt    
| drop_owned_by_stmt        
| release_stmt              
| refresh_stmt              
| nonpreparable_set_stmt    
| transaction_stmt          
| close_cursor_stmt         
| declare_cursor_stmt       
| fetch_cursor_stmt         
| move_cursor_stmt          
| reindex_stmt
| 




alter_stmt:
  alter_ddl_stmt      
| alter_role_stmt     
| alter_tenant_csetting_stmt  
| alter_unsupported_stmt
| ALTER error         

alter_ddl_stmt:
  alter_table_stmt              
| alter_index_stmt              
| alter_view_stmt               
| alter_sequence_stmt           
| alter_database_stmt           
| alter_range_stmt              
| alter_partition_stmt          
| alter_schema_stmt             
| alter_type_stmt               
| alter_default_privileges_stmt 
| alter_changefeed_stmt         
| alter_backup_stmt             















































alter_table_stmt:
  alter_onetable_stmt
| alter_relocate_stmt
| alter_split_stmt
| alter_unsplit_stmt
| alter_scatter_stmt
| alter_zone_table_stmt
| alter_rename_table_stmt
| alter_table_set_schema_stmt
| alter_table_locality_stmt
| alter_table_owner_stmt


| ALTER TABLE error     























alter_partition_stmt:
  alter_zone_partition_stmt
| ALTER PARTITION error 







alter_view_stmt:
  alter_rename_view_stmt
| alter_view_set_schema_stmt
| alter_view_owner_stmt


| ALTER VIEW error 













alter_sequence_stmt:
  alter_rename_sequence_stmt
| alter_sequence_options_stmt
| alter_sequence_set_schema_stmt
| alter_sequence_owner_stmt
| ALTER SEQUENCE error 

alter_sequence_options_stmt:
  ALTER SEQUENCE sequence_name sequence_option_list
| ALTER SEQUENCE IF EXISTS sequence_name sequence_option_list
















alter_database_stmt:
  alter_rename_database_stmt
| alter_zone_database_stmt
| alter_database_owner
| alter_database_to_schema_stmt
| alter_database_add_region_stmt
| alter_database_drop_region_stmt
| alter_database_survival_goal_stmt
| alter_database_primary_region_stmt
| alter_database_placement_stmt
| alter_database_set_stmt
| alter_database_add_super_region
| alter_database_alter_super_region
| alter_database_drop_super_region


| ALTER DATABASE error 

alter_database_owner:
  ALTER DATABASE database_name OWNER TO role_spec


alter_database_set_stmt:
  ALTER DATABASE database_name set_or_reset_clause

alter_database_placement_stmt:
  ALTER DATABASE database_name placement_clause

alter_database_add_region_stmt:
  ALTER DATABASE database_name ADD REGION region_name
| ALTER DATABASE database_name ADD REGION IF NOT EXISTS region_name

alter_database_drop_region_stmt:
  ALTER DATABASE database_name DROP REGION region_name
| ALTER DATABASE database_name DROP REGION IF EXISTS region_name

alter_database_survival_goal_stmt:
  ALTER DATABASE database_name survival_goal_clause

alter_database_primary_region_stmt:
  ALTER DATABASE database_name primary_region_clause
| ALTER DATABASE database_name SET primary_region_clause

alter_database_add_super_region:
  ALTER DATABASE database_name ADD SUPER REGION name VALUES name_list

alter_database_drop_super_region:
  ALTER DATABASE database_name DROP SUPER REGION name

alter_database_alter_super_region:
  ALTER DATABASE database_name ALTER SUPER REGION name VALUES name_list




















alter_range_stmt:
  alter_zone_range_stmt
| alter_range_relocate_stmt
| ALTER RANGE error 





















alter_index_stmt:
  alter_oneindex_stmt
| alter_relocate_index_stmt
| alter_split_index_stmt
| alter_unsplit_index_stmt
| alter_scatter_index_stmt
| alter_rename_index_stmt
| alter_zone_index_stmt


| ALTER INDEX error 

alter_onetable_stmt:
  ALTER TABLE relation_expr alter_table_cmds
| ALTER TABLE IF EXISTS relation_expr alter_table_cmds

alter_oneindex_stmt:
  ALTER INDEX table_index_name alter_index_cmds
| ALTER INDEX IF EXISTS table_index_name alter_index_cmds

alter_split_stmt:
  ALTER TABLE table_name SPLIT AT select_stmt
| ALTER TABLE table_name SPLIT AT select_stmt WITH EXPIRATION a_expr

alter_split_index_stmt:
  ALTER INDEX table_index_name SPLIT AT select_stmt
| ALTER INDEX table_index_name SPLIT AT select_stmt WITH EXPIRATION a_expr

alter_unsplit_stmt:
  ALTER TABLE table_name UNSPLIT AT select_stmt
| ALTER TABLE table_name UNSPLIT ALL

alter_unsplit_index_stmt:
  ALTER INDEX table_index_name UNSPLIT AT select_stmt
| ALTER INDEX table_index_name UNSPLIT ALL

relocate_kw:
  TESTING_RELOCATE
| EXPERIMENTAL_RELOCATE
| RELOCATE

relocate_subject:
  relocate_subject_nonlease
| LEASE

relocate_subject_nonlease:
  VOTERS
| 
| NONVOTERS

alter_relocate_stmt:
  ALTER TABLE table_name relocate_kw relocate_subject select_stmt

alter_relocate_index_stmt:
  ALTER INDEX table_index_name relocate_kw relocate_subject select_stmt











alter_zone_range_stmt:
  ALTER RANGE a_expr set_zone_config

alter_range_relocate_stmt:
  ALTER RANGE relocate_kw LEASE TO a_expr FOR select_stmt
| ALTER RANGE a_expr relocate_kw LEASE TO a_expr
| ALTER RANGE relocate_kw relocate_subject_nonlease FROM a_expr TO a_expr FOR select_stmt
| ALTER RANGE a_expr relocate_kw relocate_subject_nonlease FROM a_expr TO a_expr

set_zone_config:
  CONFIGURE ZONE to_or_eq a_expr
| CONFIGURE ZONE USING var_set_list
| CONFIGURE ZONE USING DEFAULT
| CONFIGURE ZONE DISCARD

alter_zone_database_stmt:
  ALTER DATABASE database_name set_zone_config

alter_zone_table_stmt:
  ALTER TABLE table_name set_zone_config

alter_zone_index_stmt:
  ALTER INDEX table_index_name set_zone_config

alter_zone_partition_stmt:
  ALTER PARTITION partition_name OF TABLE table_name set_zone_config
| ALTER PARTITION partition_name OF INDEX table_index_name set_zone_config
| ALTER PARTITION partition_name OF INDEX table_name '@' '*' set_zone_config
| ALTER PARTITION partition_name OF TABLE table_name '@' error
| ALTER PARTITION partition_name OF TABLE table_name '@' '*' error

var_set_list:
  var_name '=' COPY FROM PARENT
| var_name '=' var_value
| var_set_list ',' var_name '=' var_value
| var_set_list ',' var_name '=' COPY FROM PARENT

alter_scatter_stmt:
  ALTER TABLE table_name SCATTER
| ALTER TABLE table_name SCATTER FROM '(' expr_list ')' TO '(' expr_list ')'

alter_scatter_index_stmt:
  ALTER INDEX table_index_name SCATTER
| ALTER INDEX table_index_name SCATTER FROM '(' expr_list ')' TO '(' expr_list ')'

alter_table_cmds:
  alter_table_cmd
| alter_table_cmds ',' alter_table_cmd

alter_table_cmd:
  
  RENAME opt_column column_name TO column_name
  
| RENAME CONSTRAINT column_name TO column_name
  
| ADD column_def
  
| ADD IF NOT EXISTS column_def
  
| ADD COLUMN column_def
  
| ADD COLUMN IF NOT EXISTS column_def
  
| ALTER opt_column column_name alter_column_default
  
| ALTER opt_column column_name alter_column_on_update
  
| ALTER opt_column column_name alter_column_visible
  
| ALTER opt_column column_name DROP NOT NULL
  
| ALTER opt_column column_name DROP STORED
  
| ALTER opt_column column_name SET NOT NULL
| ALTER opt_column column_name ADD error
  
| DROP opt_column IF EXISTS column_name opt_drop_behavior
  
| DROP opt_column column_name opt_drop_behavior
  
  
  
  
| ALTER opt_column column_name opt_set_data TYPE typename opt_collate opt_alter_column_using
  
| ADD table_constraint opt_validate_behavior
  
| ADD CONSTRAINT IF NOT EXISTS constraint_name constraint_elem opt_validate_behavior
  
| ALTER CONSTRAINT constraint_name error 
  
| INHERITS error
  
| NO INHERITS error
  
  
| ALTER PRIMARY KEY USING COLUMNS '(' index_params ')' opt_hash_sharded opt_with_storage_parameter_list
| VALIDATE CONSTRAINT constraint_name
  
| DROP CONSTRAINT IF EXISTS constraint_name opt_drop_behavior
  
| DROP CONSTRAINT constraint_name opt_drop_behavior
  
| EXPERIMENTAL_AUDIT SET audit_mode
  
| partition_by_table
  
| INJECT STATISTICS a_expr
| SET '(' storage_parameter_list ')'
| RESET '(' storage_parameter_key_list ')'

audit_mode:
  READ WRITE 
| OFF        

alter_index_cmds:
  alter_index_cmd
| alter_index_cmds ',' alter_index_cmd

alter_index_cmd:
  partition_by_index

alter_column_default:
  SET DEFAULT a_expr
| DROP DEFAULT

alter_column_on_update:
  SET ON UPDATE b_expr
| DROP ON UPDATE

alter_column_visible:
  SET VISIBLE
| SET NOT VISIBLE

opt_alter_column_using:
  USING a_expr
| 


opt_drop_behavior:
  CASCADE
| RESTRICT
| 

opt_validate_behavior:
  NOT VALID
| 




















alter_type_stmt:
  ALTER TYPE type_name ADD VALUE SCONST opt_add_val_placement
| ALTER TYPE type_name ADD VALUE IF NOT EXISTS SCONST opt_add_val_placement
| ALTER TYPE type_name DROP VALUE SCONST
| ALTER TYPE type_name RENAME VALUE SCONST TO SCONST
| ALTER TYPE type_name RENAME TO name
| ALTER TYPE type_name SET SCHEMA schema_name
| ALTER TYPE type_name OWNER TO role_spec
| ALTER TYPE type_name RENAME ATTRIBUTE column_name TO column_name opt_drop_behavior
| ALTER TYPE type_name alter_attribute_action_list
| ALTER TYPE error 

opt_add_val_placement:
  BEFORE SCONST
| AFTER SCONST
| 

role_spec:
  IDENT
| unreserved_keyword
| CURRENT_USER
| SESSION_USER

role_spec_list:
  role_spec
| role_spec_list ',' role_spec

alter_attribute_action_list:
  alter_attribute_action
| alter_attribute_action_list ',' alter_attribute_action

alter_attribute_action:
  ADD ATTRIBUTE column_name type_name opt_collate opt_drop_behavior
| DROP ATTRIBUTE column_name opt_drop_behavior
| DROP ATTRIBUTE IF EXISTS column_name opt_drop_behavior
| ALTER ATTRIBUTE column_name TYPE type_name opt_collate opt_drop_behavior
| ALTER ATTRIBUTE column_name SET DATA TYPE type_name opt_collate opt_drop_behavior





refresh_stmt:
  REFRESH MATERIALIZED VIEW opt_concurrently view_name opt_clear_data
| REFRESH error 

opt_clear_data:
  WITH DATA
| WITH NO DATA
| 






































backup_stmt:
  BACKUP opt_backup_targets INTO sconst_or_placeholder IN string_or_placeholder_opt_list opt_as_of_clause opt_with_backup_options
| BACKUP opt_backup_targets INTO string_or_placeholder_opt_list opt_as_of_clause opt_with_backup_options
| BACKUP opt_backup_targets INTO LATEST IN string_or_placeholder_opt_list opt_as_of_clause opt_with_backup_options
| BACKUP opt_backup_targets TO string_or_placeholder_opt_list opt_as_of_clause opt_incremental opt_with_backup_options
| BACKUP error 

opt_backup_targets:
| targets


opt_with_backup_options:
  WITH backup_options_list
| WITH OPTIONS '(' backup_options_list ')'
| 

backup_options_list:
  
  backup_options
| backup_options_list ',' backup_options


backup_options:
  ENCRYPTION_PASSPHRASE '=' string_or_placeholder
| REVISION_HISTORY
| DETACHED
| KMS '=' string_or_placeholder_opt_list
| INCREMENTAL_LOCATION '=' string_or_placeholder_opt_list











































































create_schedule_for_backup_stmt:
 CREATE SCHEDULE schedule_label_spec FOR BACKUP opt_backup_targets INTO
  string_or_placeholder_opt_list opt_with_backup_options
  cron_expr opt_full_backup_clause opt_with_schedule_options
 | CREATE SCHEDULE error  


sconst_or_placeholder:
  SCONST
| PLACEHOLDER

cron_expr:
  RECURRING sconst_or_placeholder
  
  

schedule_label_spec:
  string_or_placeholder
| IF NOT EXISTS string_or_placeholder
| 


opt_full_backup_clause:
  FULL BACKUP sconst_or_placeholder
  
  
| FULL BACKUP ALWAYS
| 

opt_with_schedule_options:
  WITH SCHEDULE OPTIONS kv_option_list
| WITH SCHEDULE OPTIONS '(' kv_option_list ')'
| 

































restore_stmt:
  RESTORE FROM list_of_string_or_placeholder_opt_list opt_as_of_clause opt_with_restore_options
| RESTORE FROM string_or_placeholder IN list_of_string_or_placeholder_opt_list opt_as_of_clause opt_with_restore_options
| RESTORE targets FROM list_of_string_or_placeholder_opt_list opt_as_of_clause opt_with_restore_options
| RESTORE targets FROM string_or_placeholder IN list_of_string_or_placeholder_opt_list opt_as_of_clause opt_with_restore_options
| RESTORE SYSTEM USERS FROM list_of_string_or_placeholder_opt_list opt_as_of_clause opt_with_restore_options
| RESTORE SYSTEM USERS FROM string_or_placeholder IN list_of_string_or_placeholder_opt_list opt_as_of_clause opt_with_restore_options
| RESTORE targets FROM REPLICATION STREAM FROM string_or_placeholder_opt_list opt_as_of_clause
| RESTORE error 

string_or_placeholder_opt_list:
  string_or_placeholder
| '(' string_or_placeholder_list ')'

list_of_string_or_placeholder_opt_list:
  string_or_placeholder_opt_list
| list_of_string_or_placeholder_opt_list ',' string_or_placeholder_opt_list


opt_with_restore_options:
  WITH restore_options_list
| WITH OPTIONS '(' restore_options_list ')'
| 

restore_options_list:
  
  restore_options
| restore_options_list ',' restore_options


restore_options:
  ENCRYPTION_PASSPHRASE '=' string_or_placeholder
| KMS '=' string_or_placeholder_opt_list
| INTO_DB '=' string_or_placeholder
| SKIP_MISSING_FOREIGN_KEYS
| SKIP_MISSING_SEQUENCES
| SKIP_MISSING_SEQUENCE_OWNERS
| SKIP_MISSING_VIEWS
| DETACHED
| SKIP_LOCALITIES_CHECK
| DEBUG_PAUSE_ON '=' string_or_placeholder
| NEW_DB_NAME '=' string_or_placeholder
| INCREMENTAL_LOCATION '=' string_or_placeholder_opt_list
| TENANT '=' string_or_placeholder

import_format:
  name

alter_unsupported_stmt:
  ALTER FUNCTION error
| ALTER DOMAIN error
| ALTER AGGREGATE error






















import_stmt:
 IMPORT import_format '(' string_or_placeholder ')' opt_with_options
| IMPORT import_format string_or_placeholder opt_with_options
| IMPORT TABLE table_name FROM import_format '(' string_or_placeholder ')' opt_with_options
| IMPORT TABLE table_name FROM import_format string_or_placeholder opt_with_options
| IMPORT INTO table_name '(' insert_column_list ')' import_format DATA '(' string_or_placeholder_list ')' opt_with_options
| IMPORT INTO table_name import_format DATA '(' string_or_placeholder_list ')' opt_with_options
| IMPORT error 














export_stmt:
  EXPORT INTO import_format string_or_placeholder opt_with_options FROM select_stmt
| EXPORT error 

string_or_placeholder:
  non_reserved_word_or_sconst
| PLACEHOLDER

string_or_placeholder_list:
  string_or_placeholder
| string_or_placeholder_list ',' string_or_placeholder

opt_incremental:
  INCREMENTAL FROM string_or_placeholder_list
| 

kv_option:
  name '=' string_or_placeholder
|  name
|  SCONST '=' string_or_placeholder
|  SCONST

kv_option_list:
  kv_option
|  kv_option_list ',' kv_option

opt_with_options:
  WITH kv_option_list
| WITH OPTIONS '(' kv_option_list ')'
| 







copy_from_stmt:
  COPY table_name opt_column_list FROM STDIN opt_with_copy_options opt_where_clause
| COPY table_name opt_column_list FROM error

opt_with_copy_options:
  opt_with copy_options_list
| 

copy_options_list:
  copy_options
| copy_options_list copy_options

copy_options:
  DESTINATION '=' string_or_placeholder
| BINARY
| CSV
| DELIMITER string_or_placeholder
| NULL string_or_placeholder
| OIDS error
| FREEZE error
| HEADER error
| QUOTE SCONST
| ESCAPE SCONST error
| FORCE QUOTE error
| FORCE NOT NULL error
| FORCE NULL error
| ENCODING SCONST error




cancel_stmt:
  cancel_jobs_stmt      
| cancel_queries_stmt   
| cancel_sessions_stmt  
| cancel_all_jobs_stmt  
| CANCEL error          







cancel_jobs_stmt:
  CANCEL JOB a_expr
| CANCEL JOB error 
| CANCEL JOBS select_stmt
| CANCEL JOBS for_schedules_clause
| CANCEL JOBS error 







cancel_queries_stmt:
  CANCEL QUERY a_expr
| CANCEL QUERY IF EXISTS a_expr
| CANCEL QUERY error 
| CANCEL QUERIES select_stmt
| CANCEL QUERIES IF EXISTS select_stmt
| CANCEL QUERIES error 







cancel_sessions_stmt:
  CANCEL SESSION a_expr
| CANCEL SESSION IF EXISTS a_expr
| CANCEL SESSION error 
| CANCEL SESSIONS select_stmt
| CANCEL SESSIONS IF EXISTS select_stmt
| CANCEL SESSIONS error 





cancel_all_jobs_stmt:
  CANCEL ALL name JOBS
| CANCEL ALL error 

comment_stmt:
  COMMENT ON DATABASE database_name IS comment_text
| COMMENT ON SCHEMA schema_name IS comment_text
| COMMENT ON TABLE table_name IS comment_text
| COMMENT ON COLUMN column_path IS comment_text
| COMMENT ON INDEX table_index_name IS comment_text

| COMMENT ON CONSTRAINT constraint_name ON table_name IS comment_text
| COMMENT ON EXTENSION error 
| COMMENT ON FUNCTION error 

comment_text:
  SCONST
| NULL







create_stmt:
  create_role_stmt     
| create_ddl_stmt      
| create_stats_stmt    
| create_schedule_for_backup_stmt   
| create_changefeed_stmt
| create_replication_stream_stmt
| create_extension_stmt  
| create_unsupported   
| CREATE error         




create_extension_stmt:
  CREATE EXTENSION IF NOT EXISTS name
| CREATE EXTENSION name 
| CREATE EXTENSION IF NOT EXISTS name WITH error
| CREATE EXTENSION name WITH error 
| CREATE EXTENSION error 

create_unsupported:
  CREATE ACCESS METHOD error 
| CREATE AGGREGATE error 
| CREATE CAST error 
| CREATE CONSTRAINT TRIGGER error 
| CREATE CONVERSION error 
| CREATE DEFAULT CONVERSION error 
| CREATE FOREIGN TABLE error 
| CREATE FOREIGN DATA error 
| CREATE FUNCTION error 
| CREATE OR REPLACE FUNCTION error 
| CREATE opt_or_replace opt_trusted opt_procedural LANGUAGE name error 
| CREATE OPERATOR error 
| CREATE PUBLICATION error 
| CREATE opt_or_replace RULE error 
| CREATE SERVER error 
| CREATE SUBSCRIPTION error 
| CREATE TABLESPACE error 
| CREATE TEXT error 
| CREATE TRIGGER error 

opt_or_replace:
  OR REPLACE 
|  

opt_trusted:
  TRUSTED 
|  

opt_procedural:
  PROCEDURAL 
|  

drop_unsupported:
  DROP ACCESS METHOD error 
| DROP AGGREGATE error 
| DROP CAST error 
| DROP COLLATION error 
| DROP CONVERSION error 
| DROP DOMAIN error 
| DROP EXTENSION IF EXISTS name error 
| DROP EXTENSION name error 
| DROP FOREIGN TABLE error 
| DROP FOREIGN DATA error 
| DROP FUNCTION error 
| DROP opt_procedural LANGUAGE name error 
| DROP OPERATOR error 
| DROP PUBLICATION error 
| DROP RULE error 
| DROP SERVER error 
| DROP SUBSCRIPTION error 
| DROP TEXT error 
| DROP TRIGGER error 

create_ddl_stmt:
  create_database_stmt 
| create_index_stmt    
| create_schema_stmt   
| create_table_stmt    
| create_table_as_stmt 

| CREATE opt_persistence_temp_table TABLE error   
| create_type_stmt     
| create_view_stmt     
| create_sequence_stmt 







create_stats_stmt:
  CREATE STATISTICS statistics_name opt_stats_columns FROM create_stats_target opt_create_stats_options
| CREATE STATISTICS error 

opt_stats_columns:
  ON name_list
| 

create_stats_target:
  table_name
| '[' iconst64 ']'

opt_create_stats_options:
  WITH OPTIONS create_stats_option_list


| as_of_clause
| 

create_stats_option_list:
  create_stats_option
| create_stats_option_list create_stats_option

create_stats_option:
  THROTTLING FCONST
| as_of_clause








create_changefeed_stmt:
  CREATE CHANGEFEED FOR changefeed_targets opt_changefeed_sink opt_with_options
| EXPERIMENTAL CHANGEFEED FOR changefeed_targets opt_with_options

changefeed_targets:
  changefeed_target
| changefeed_targets ',' changefeed_target

changefeed_target:
  TABLE table_name
| table_name
|
  TABLE table_name FAMILY family_name
|
table_name FAMILY family_name



opt_changefeed_sink:
  INTO string_or_placeholder
| 











create_replication_stream_stmt:
  CREATE REPLICATION STREAM FOR targets opt_changefeed_sink opt_with_replication_options


opt_with_replication_options:
  WITH replication_options_list
| WITH OPTIONS '(' replication_options_list ')'
| 

replication_options_list:
  
  replication_options
| replication_options_list ',' replication_options


replication_options:
  CURSOR '=' a_expr
| DETACHED








delete_stmt:
  opt_with_clause DELETE FROM table_expr_opt_alias_idx opt_using_clause opt_where_clause opt_sort_clause opt_limit_clause returning_clause
| opt_with_clause DELETE error 

opt_using_clause:
  USING from_list 
|  





discard_stmt:
  DISCARD ALL
| DISCARD PLANS 
| DISCARD SEQUENCES 
| DISCARD TEMP 
| DISCARD TEMPORARY 
| DISCARD error 






drop_stmt:
  drop_ddl_stmt      
| drop_role_stmt     
| drop_schedule_stmt 
| drop_unsupported   
| DROP error         

drop_ddl_stmt:
  drop_database_stmt 
| drop_index_stmt    
| drop_table_stmt    
| drop_view_stmt     
| drop_sequence_stmt 
| drop_schema_stmt   
| drop_type_stmt     





drop_view_stmt:
  DROP VIEW table_name_list opt_drop_behavior
| DROP VIEW IF EXISTS table_name_list opt_drop_behavior
| DROP MATERIALIZED VIEW table_name_list opt_drop_behavior
| DROP MATERIALIZED VIEW IF EXISTS table_name_list opt_drop_behavior
| DROP VIEW error 





drop_sequence_stmt:
  DROP SEQUENCE table_name_list opt_drop_behavior
| DROP SEQUENCE IF EXISTS table_name_list opt_drop_behavior
| DROP SEQUENCE error 





drop_table_stmt:
  DROP TABLE table_name_list opt_drop_behavior
| DROP TABLE IF EXISTS table_name_list opt_drop_behavior
| DROP TABLE error 





drop_index_stmt:
  DROP INDEX opt_concurrently table_index_name_list opt_drop_behavior
| DROP INDEX opt_concurrently IF EXISTS table_index_name_list opt_drop_behavior
| DROP INDEX error 





drop_database_stmt:
  DROP DATABASE database_name opt_drop_behavior
| DROP DATABASE IF EXISTS database_name opt_drop_behavior
| DROP DATABASE error 




drop_type_stmt:
  DROP TYPE type_name_list opt_drop_behavior
| DROP TYPE IF EXISTS type_name_list opt_drop_behavior
| DROP TYPE error 

target_types:
  type_name_list

type_name_list:
  type_name
| type_name_list ',' type_name




drop_schema_stmt:
  DROP SCHEMA schema_name_list opt_drop_behavior
| DROP SCHEMA IF EXISTS schema_name_list opt_drop_behavior
| DROP SCHEMA error 





drop_role_stmt:
  DROP role_or_group_or_user role_spec_list
| DROP role_or_group_or_user IF EXISTS role_spec_list
| DROP role_or_group_or_user error 

table_name_list:
  table_name
| table_name_list ',' table_name







analyze_stmt:
  ANALYZE analyze_target
| ANALYZE error 
| ANALYSE analyze_target
| ANALYSE error 

analyze_target:
  table_name


















explain_stmt:
  EXPLAIN explainable_stmt
| EXPLAIN error 
| EXPLAIN '(' explain_option_list ')' explainable_stmt
| EXPLAIN ANALYZE explainable_stmt
| EXPLAIN ANALYSE explainable_stmt
| EXPLAIN ANALYZE '(' explain_option_list ')' explainable_stmt
| EXPLAIN ANALYSE '(' explain_option_list ')' explainable_stmt




| EXPLAIN '(' error 

explainable_stmt:
  preparable_stmt
| execute_stmt

preparable_stmt:
  alter_stmt     
| backup_stmt    
| cancel_stmt    
| create_stmt    
| delete_stmt    
| drop_stmt      
| explain_stmt   
| import_stmt    
| insert_stmt    
| pause_stmt     
| reset_stmt     
| restore_stmt   
| resume_stmt    
| export_stmt    
| scrub_stmt     
| select_stmt    
| preparable_set_stmt 
| show_stmt         
| truncate_stmt     
| update_stmt       
| upsert_stmt       



row_source_extension_stmt:
  delete_stmt       
| explain_stmt      
| insert_stmt       
| select_stmt       
| show_stmt         
| update_stmt       
| upsert_stmt       

explain_option_list:
  explain_option_name
| explain_option_list ',' explain_option_name





alter_changefeed_stmt:
  ALTER CHANGEFEED a_expr alter_changefeed_cmds
| ALTER CHANGEFEED error 

alter_changefeed_cmds:
  alter_changefeed_cmd
| alter_changefeed_cmds alter_changefeed_cmd

alter_changefeed_cmd:
  
  ADD changefeed_targets opt_with_options
  
| DROP changefeed_targets
| SET kv_option_list
| UNSET name_list












alter_backup_stmt:
  ALTER BACKUP string_or_placeholder alter_backup_cmds
| ALTER BACKUP string_or_placeholder IN string_or_placeholder alter_backup_cmds
| ALTER BACKUP error 

alter_backup_cmds:
	alter_backup_cmd
|	alter_backup_cmds alter_backup_cmd

alter_backup_cmd:
	ADD backup_kms

backup_kms:
	NEW_KMS '=' string_or_placeholder_opt_list WITH OLD_KMS '=' string_or_placeholder_opt_list





prepare_stmt:
  PREPARE table_alias_name prep_type_clause AS preparable_stmt
| PREPARE table_alias_name prep_type_clause AS OPT PLAN SCONST
| PREPARE error 

prep_type_clause:
  '(' type_list ')'
| 





execute_stmt:
  EXECUTE table_alias_name execute_param_clause
| EXECUTE table_alias_name execute_param_clause DISCARD ROWS
| EXECUTE error 

execute_param_clause:
  '(' expr_list ')'
| 





deallocate_stmt:
  DEALLOCATE name
| DEALLOCATE PREPARE name
| DEALLOCATE ALL
| DEALLOCATE PREPARE ALL
| DEALLOCATE error 




















grant_stmt:
  GRANT privileges ON targets TO role_spec_list opt_with_grant_option
| GRANT privilege_list TO role_spec_list
| GRANT privilege_list TO role_spec_list WITH ADMIN OPTION
| GRANT privileges ON TYPE target_types TO role_spec_list opt_with_grant_option
| GRANT privileges ON SCHEMA schema_name_list TO role_spec_list opt_with_grant_option
| GRANT privileges ON SCHEMA schema_name_list TO role_spec_list WITH error
| GRANT privileges ON ALL TABLES IN SCHEMA schema_name_list TO role_spec_list opt_with_grant_option
| GRANT privileges ON SEQUENCE error
| GRANT error 




















revoke_stmt:
  REVOKE privileges ON targets FROM role_spec_list
| REVOKE GRANT OPTION FOR privileges ON targets FROM role_spec_list
| REVOKE privilege_list FROM role_spec_list
| REVOKE ADMIN OPTION FOR privilege_list FROM role_spec_list
| REVOKE privileges ON TYPE target_types FROM role_spec_list
| REVOKE GRANT OPTION FOR privileges ON TYPE target_types FROM role_spec_list
| REVOKE privileges ON SCHEMA schema_name_list FROM role_spec_list
| REVOKE GRANT OPTION FOR privileges ON SCHEMA schema_name_list FROM role_spec_list
| REVOKE privileges ON ALL TABLES IN SCHEMA schema_name_list FROM role_spec_list
| REVOKE GRANT OPTION FOR privileges ON ALL TABLES IN SCHEMA schema_name_list FROM role_spec_list
| REVOKE privileges ON SEQUENCE error
| REVOKE error 



privileges:
  ALL opt_privileges_clause
| privilege_list

privilege_list:
  privilege
| privilege_list ',' privilege




privilege:
  name
| CREATE
| GRANT
| SELECT

reset_stmt:
  reset_session_stmt  
| reset_csetting_stmt 





reset_session_stmt:
  RESET session_var
| RESET SESSION session_var
| RESET_ALL ALL
| RESET error 





reset_csetting_stmt:
  RESET CLUSTER SETTING var_name
| RESET CLUSTER error 








use_stmt:
  USE var_value
| USE error 


nonpreparable_set_stmt:
  set_transaction_stmt 
| set_exprs_internal   
| SET CONSTRAINTS error 


preparable_set_stmt:
  set_session_stmt     
| set_local_stmt       
| set_csetting_stmt    
| use_stmt             












scrub_stmt:
  scrub_table_stmt
| scrub_database_stmt
| EXPERIMENTAL SCRUB error 












scrub_database_stmt:
  EXPERIMENTAL SCRUB DATABASE database_name opt_as_of_clause
| EXPERIMENTAL SCRUB DATABASE error 















scrub_table_stmt:
  EXPERIMENTAL SCRUB TABLE table_name opt_as_of_clause opt_scrub_options_clause
| EXPERIMENTAL SCRUB TABLE error 

opt_scrub_options_clause:
  WITH OPTIONS scrub_option_list
| 

scrub_option_list:
  scrub_option
| scrub_option_list ',' scrub_option

scrub_option:
  INDEX ALL
| INDEX '(' name_list ')'
| CONSTRAINT ALL
| CONSTRAINT '(' name_list ')'
| PHYSICAL






set_csetting_stmt:
  SET CLUSTER SETTING var_name to_or_eq var_value
| SET CLUSTER error 







alter_tenant_csetting_stmt:
  ALTER TENANT d_expr set_or_reset_csetting_stmt
| ALTER TENANT_ALL ALL set_or_reset_csetting_stmt
| ALTER TENANT error 
| ALTER TENANT_ALL ALL error 

set_or_reset_csetting_stmt:
  reset_csetting_stmt
| set_csetting_stmt

to_or_eq:
  '='
| TO

set_exprs_internal:
  SET ROW '(' expr_list ')'











set_session_stmt:
  SET_TRACING TRACING to_or_eq var_list
| SET_TRACING SESSION TRACING to_or_eq var_list
| SET SESSION set_rest_more
| SET SESSION error  
| SET set_rest_more
| SET error  

| SET SESSION CHARACTERISTICS AS TRANSACTION transaction_mode_list









set_local_stmt:
  SET LOCAL set_rest
| SET LOCAL error  














set_transaction_stmt:
  SET TRANSACTION transaction_mode_list
| SET TRANSACTION error 
| SET SESSION TRANSACTION transaction_mode_list
| SET SESSION TRANSACTION error 

generic_set:
  var_name to_or_eq var_list

set_rest:

   generic_set




| TIME ZONE zone_value
| var_name FROM CURRENT 


| SCHEMA var_value
| ROLE var_value

set_rest_more:

  set_rest
| SESSION AUTHORIZATION DEFAULT
| SESSION AUTHORIZATION IDENT
| SESSION AUTHORIZATION SCONST

| set_names





set_names:
  NAMES var_value
| NAMES

var_name:
  name
| name attrs

attrs:
  '.' unrestricted_name
| attrs '.' unrestricted_name

var_value:
  a_expr
| extra_var_value












extra_var_value:
  ON
| cockroachdb_extra_reserved_keyword

var_list:
  var_value
| var_list ',' var_value

iso_level:
  READ UNCOMMITTED
| READ COMMITTED
| SNAPSHOT
| REPEATABLE READ
| SERIALIZABLE

user_priority:
  LOW
| NORMAL
| HIGH






zone_value:
  SCONST
| IDENT
| interval_value
| numeric_only
| DEFAULT
| LOCAL











show_stmt:
  show_backup_stmt           
| show_columns_stmt          
| show_constraints_stmt      
| show_create_stmt           
| show_create_schedules_stmt 
| show_local_or_tenant_csettings_stmt 
| show_databases_stmt        
| show_enums_stmt            
| show_types_stmt            
| show_fingerprints_stmt
| show_grants_stmt           
| show_histogram_stmt        
| show_indexes_stmt          
| show_partitions_stmt       
| show_jobs_stmt             
| show_locality_stmt
| show_schedules_stmt        
| show_statements_stmt       
| show_ranges_stmt           
| show_range_for_row_stmt
| show_regions_stmt          
| show_survival_goal_stmt    
| show_roles_stmt            
| show_savepoint_stmt        
| show_schemas_stmt          
| show_sequences_stmt        
| show_session_stmt          
| show_sessions_stmt         
| show_stats_stmt            
| show_syntax_stmt           
| show_tables_stmt           
| show_trace_stmt            
| show_transaction_stmt      
| show_transactions_stmt     
| show_transfer_stmt         
| show_users_stmt            
| show_zone_stmt             
| SHOW error                 
| show_last_query_stats_stmt
| show_full_scans_stmt
| show_default_privileges_stmt 
| show_completions_stmt





close_cursor_stmt:
	CLOSE ALL
| CLOSE cursor_name
| CLOSE error 





declare_cursor_stmt:
  
  
	DECLARE cursor_name opt_binary opt_sensitivity opt_scroll CURSOR opt_hold FOR select_stmt
| DECLARE error 

opt_binary:
  BINARY
| 

opt_sensitivity:
  INSENSITIVE
| ASENSITIVE
| 

opt_scroll:
  SCROLL
| NO SCROLL
| 

opt_hold:
  WITH HOLD
| WITHOUT HOLD
| 





fetch_cursor_stmt:
  FETCH cursor_movement_specifier
| FETCH error 





move_cursor_stmt:
  MOVE cursor_movement_specifier
| MOVE error 

cursor_movement_specifier:
  cursor_name
| from_or_in cursor_name
| next_prior opt_from_or_in cursor_name
| forward_backward opt_from_or_in cursor_name
| opt_forward_backward signed_iconst64 opt_from_or_in cursor_name
| opt_forward_backward ALL opt_from_or_in cursor_name
| ABSOLUTE signed_iconst64 opt_from_or_in cursor_name
| RELATIVE signed_iconst64 opt_from_or_in cursor_name
| FIRST opt_from_or_in cursor_name
| LAST opt_from_or_in cursor_name

next_prior:
  NEXT  
| PRIOR 

opt_forward_backward:
  forward_backward 
|  

forward_backward:
  FORWARD  
| BACKWARD 

opt_from_or_in:
  from_or_in 
|  

from_or_in:
  FROM 
| IN 

reindex_stmt:
  REINDEX TABLE error
| REINDEX INDEX error
| REINDEX SCHEMA error
| REINDEX DATABASE error
| REINDEX SYSTEM error





show_session_stmt:
  SHOW session_var         
| SHOW SESSION session_var 
| SHOW SESSION error 

session_var:
  IDENT
| IDENT session_var_parts



| ALL
| DATABASE


| NAMES 
| ROLE
| SESSION_USER
| LC_COLLATE
| LC_CTYPE
| TRACING 
| TRACING session_var_parts

| TIME ZONE 
| TIME error 

session_var_parts:
  '.' IDENT
| session_var_parts '.' IDENT











show_stats_stmt:
  SHOW STATISTICS FOR TABLE table_name
| SHOW STATISTICS USING JSON FOR TABLE table_name
| SHOW STATISTICS error 








show_histogram_stmt:
  SHOW HISTOGRAM ICONST
| SHOW HISTOGRAM error 





show_backup_stmt:
  SHOW BACKUPS IN string_or_placeholder
| SHOW BACKUP show_backup_details FROM string_or_placeholder IN string_or_placeholder opt_with_options
| SHOW BACKUP string_or_placeholder IN string_or_placeholder opt_with_options
| SHOW BACKUP string_or_placeholder opt_with_options
| SHOW BACKUP SCHEMAS string_or_placeholder opt_with_options
| SHOW BACKUP FILES string_or_placeholder opt_with_options
| SHOW BACKUP RANGES string_or_placeholder opt_with_options
| SHOW BACKUP error 

show_backup_details:
| SCHEMAS
| FILES
| RANGES







show_csettings_stmt:
  SHOW CLUSTER SETTING var_name
| SHOW CLUSTER SETTING ALL
| SHOW CLUSTER error 
| SHOW ALL CLUSTER SETTINGS
| SHOW ALL CLUSTER error 
| SHOW CLUSTER SETTINGS
| SHOW PUBLIC CLUSTER SETTINGS
| SHOW PUBLIC CLUSTER error 

show_local_or_tenant_csettings_stmt:
  show_csettings_stmt
| show_csettings_stmt FOR TENANT d_expr
| show_csettings_stmt FOR TENANT error 





show_columns_stmt:
  SHOW COLUMNS FROM table_name with_comment
| SHOW COLUMNS error 





show_partitions_stmt:
  SHOW PARTITIONS FROM TABLE table_name
| SHOW PARTITIONS FROM DATABASE database_name
| SHOW PARTITIONS FROM INDEX table_index_name
| SHOW PARTITIONS FROM INDEX table_name '@' '*'
| SHOW PARTITIONS error 





show_databases_stmt:
  SHOW DATABASES with_comment
| SHOW DATABASES error 




show_default_privileges_stmt:
  SHOW DEFAULT PRIVILEGES opt_for_roles opt_in_schema 
| SHOW DEFAULT PRIVILEGES FOR ALL ROLES opt_in_schema 
| SHOW DEFAULT PRIVILEGES error 




show_enums_stmt:
  SHOW ENUMS
| SHOW ENUMS FROM name '.' name
| SHOW ENUMS FROM name

| SHOW ENUMS error 




show_types_stmt:
  SHOW TYPES
| SHOW TYPES error 










show_grants_stmt:
  SHOW GRANTS opt_on_targets_roles for_grantee_clause
| SHOW GRANTS error 





show_indexes_stmt:
  SHOW INDEX FROM table_name with_comment
| SHOW INDEX error 
| SHOW INDEX FROM DATABASE database_name with_comment
| SHOW INDEXES FROM table_name with_comment
| SHOW INDEXES FROM DATABASE database_name with_comment
| SHOW INDEXES error 
| SHOW KEYS FROM table_name with_comment
| SHOW KEYS FROM DATABASE database_name with_comment
| SHOW KEYS error 





show_constraints_stmt:
  SHOW CONSTRAINT FROM table_name with_comment
| SHOW CONSTRAINT error 
| SHOW CONSTRAINTS FROM table_name with_comment
| SHOW CONSTRAINTS error 





show_statements_stmt:
  SHOW opt_cluster statements_or_queries
| SHOW opt_cluster statements_or_queries error 
| SHOW ALL opt_cluster statements_or_queries
| SHOW ALL opt_cluster statements_or_queries error 

opt_cluster:
| CLUSTER
| LOCAL



statements_or_queries:
  STATEMENTS
| QUERIES








show_jobs_stmt:
  SHOW AUTOMATIC JOBS
| SHOW JOBS
| SHOW CHANGEFEED JOBS
| SHOW AUTOMATIC JOBS error 
| SHOW JOBS error 
| SHOW CHANGEFEED JOBS error 
| SHOW JOBS select_stmt
| SHOW JOBS WHEN COMPLETE select_stmt
| SHOW JOBS for_schedules_clause
| SHOW CHANGEFEED JOBS select_stmt
| SHOW JOBS select_stmt error 
| SHOW JOB a_expr
| SHOW CHANGEFEED JOB a_expr
| SHOW JOB WHEN COMPLETE a_expr
| SHOW JOB error 
| SHOW CHANGEFEED JOB error 







show_schedules_stmt:
  SHOW SCHEDULES opt_schedule_executor_type
| SHOW SCHEDULES opt_schedule_executor_type error 
| SHOW schedule_state SCHEDULES opt_schedule_executor_type
| SHOW schedule_state SCHEDULES opt_schedule_executor_type error 
| SHOW SCHEDULE a_expr
| SHOW SCHEDULE error  

schedule_state:
  RUNNING
| PAUSED

opt_schedule_executor_type:
| FOR BACKUP
| FOR SQL STATISTICS






show_trace_stmt:
  SHOW opt_compact TRACE FOR SESSION
| SHOW opt_compact TRACE error 
| SHOW opt_compact KV TRACE FOR SESSION
| SHOW opt_compact KV error 
| SHOW opt_compact EXPERIMENTAL_REPLICA TRACE FOR SESSION
| SHOW opt_compact EXPERIMENTAL_REPLICA error 

opt_compact:
  COMPACT 
|  





show_sessions_stmt:
  SHOW opt_cluster SESSIONS
| SHOW opt_cluster SESSIONS error 
| SHOW ALL opt_cluster SESSIONS
| SHOW ALL opt_cluster SESSIONS error 





show_tables_stmt:
  SHOW TABLES FROM name '.' name with_comment
| SHOW TABLES FROM name with_comment
| SHOW TABLES with_comment
| SHOW TABLES error 




show_transactions_stmt:
  SHOW opt_cluster TRANSACTIONS
| SHOW opt_cluster TRANSACTIONS error 
| SHOW ALL opt_cluster TRANSACTIONS
| SHOW ALL opt_cluster TRANSACTIONS error 

with_comment:
  WITH COMMENT 
|   




show_schemas_stmt:
  SHOW SCHEMAS FROM name
| SHOW SCHEMAS
| SHOW SCHEMAS error 




show_sequences_stmt:
  SHOW SEQUENCES FROM name
| SHOW SEQUENCES
| SHOW SEQUENCES error 




show_syntax_stmt:
  SHOW SYNTAX SCONST
| SHOW SYNTAX error 

show_completions_stmt:
  SHOW COMPLETIONS AT OFFSET ICONST FOR SCONST

show_last_query_stats_stmt:
  SHOW LAST QUERY STATISTICS query_stats_cols

query_stats_cols:
  RETURNING name_list
| 




show_savepoint_stmt:
  SHOW SAVEPOINT STATUS
| SHOW SAVEPOINT error 





show_transaction_stmt:
  SHOW TRANSACTION ISOLATION LEVEL
| SHOW TRANSACTION PRIORITY
| SHOW TRANSACTION STATUS
| SHOW TRANSACTION error 




show_transfer_stmt:
  SHOW TRANSFER STATE WITH SCONST
| SHOW TRANSFER STATE
| SHOW TRANSFER error 









show_create_stmt:
  SHOW CREATE table_name
| SHOW CREATE TABLE table_name
| SHOW CREATE VIEW table_name
| SHOW CREATE SEQUENCE table_name
| SHOW CREATE DATABASE db_name
| SHOW CREATE ALL SCHEMAS
| SHOW CREATE ALL TABLES
| SHOW CREATE ALL TYPES
| SHOW CREATE error 







show_create_schedules_stmt:
  SHOW CREATE ALL SCHEDULES
| SHOW CREATE ALL SCHEDULES error 
| SHOW CREATE SCHEDULE a_expr
| SHOW CREATE SCHEDULE error 





show_users_stmt:
  SHOW USERS
| SHOW USERS error 





show_roles_stmt:
  SHOW ROLES
| SHOW ROLES error 







show_zone_stmt:
  SHOW ZONE CONFIGURATION from_with_implicit_for_alias RANGE zone_name
| SHOW ZONE CONFIGURATION from_with_implicit_for_alias DATABASE database_name
| SHOW ZONE CONFIGURATION from_with_implicit_for_alias TABLE table_name opt_partition
| SHOW ZONE CONFIGURATION from_with_implicit_for_alias PARTITION partition_name OF TABLE table_name
| SHOW ZONE CONFIGURATION from_with_implicit_for_alias INDEX table_index_name opt_partition
| SHOW ZONE CONFIGURATION from_with_implicit_for_alias PARTITION partition_name OF INDEX table_index_name
| SHOW ZONE CONFIGURATION error 
| SHOW ZONE CONFIGURATIONS
| SHOW ZONE CONFIGURATIONS error 
| SHOW ALL ZONE CONFIGURATIONS
| SHOW ALL ZONE CONFIGURATIONS error 

from_with_implicit_for_alias:
  FROM
| FOR 






show_range_for_row_stmt:
  SHOW RANGE FROM TABLE table_name FOR ROW '(' expr_list ')'
| SHOW RANGE FROM INDEX table_index_name FOR ROW '(' expr_list ')'
| SHOW RANGE error 






show_ranges_stmt:
  SHOW RANGES FROM TABLE table_name
| SHOW RANGES FROM INDEX table_index_name
| SHOW RANGES FROM DATABASE database_name
| SHOW RANGES error 






show_survival_goal_stmt:
  SHOW SURVIVAL GOAL FROM DATABASE
| SHOW SURVIVAL GOAL FROM DATABASE database_name









show_regions_stmt:
  SHOW REGIONS FROM CLUSTER
| SHOW REGIONS FROM DATABASE
| SHOW REGIONS FROM ALL DATABASES
| SHOW REGIONS FROM DATABASE database_name
| SHOW REGIONS
| SHOW SUPER REGIONS FROM DATABASE database_name
| SHOW REGIONS error 

show_locality_stmt:
  SHOW LOCALITY

show_fingerprints_stmt:
  SHOW EXPERIMENTAL_FINGERPRINTS FROM TABLE table_name

show_full_scans_stmt:
  SHOW FULL TABLE SCANS

opt_on_targets_roles:
  ON targets_roles
| 
















































































































targets:
  IDENT
| col_name_keyword
| unreserved_keyword
| complex_table_pattern
| table_pattern ',' table_pattern_list
| TABLE table_pattern_list


| TENANT iconst64
| TENANT IDENT
| DATABASE name_list




targets_roles:
  ROLE role_spec_list
| SCHEMA schema_name_list
| TYPE type_name_list
| targets

for_grantee_clause:
  FOR role_spec_list
| 









pause_stmt:
  pause_jobs_stmt       
| pause_schedules_stmt  
| pause_all_jobs_stmt  
| PAUSE error           








resume_stmt:
  resume_jobs_stmt       
| resume_schedules_stmt  
| resume_all_jobs_stmt  
| RESUME error           





resume_all_jobs_stmt:
  RESUME ALL name JOBS
| RESUME ALL error 







pause_jobs_stmt:
  PAUSE JOB a_expr
| PAUSE JOB a_expr WITH REASON '=' string_or_placeholder
| PAUSE JOB error 
| PAUSE JOBS select_stmt
| PAUSE JOBS select_stmt WITH REASON '=' string_or_placeholder
| PAUSE JOBS for_schedules_clause
| PAUSE JOBS error 


for_schedules_clause:
  FOR SCHEDULES select_stmt
| FOR SCHEDULE a_expr








pause_schedules_stmt:
  PAUSE SCHEDULE a_expr
| PAUSE SCHEDULE error 
| PAUSE SCHEDULES select_stmt
| PAUSE SCHEDULES error 





pause_all_jobs_stmt:
  PAUSE ALL name JOBS
| PAUSE ALL error 






create_schema_stmt:
  CREATE SCHEMA qualifiable_schema_name
| CREATE SCHEMA IF NOT EXISTS qualifiable_schema_name
| CREATE SCHEMA opt_schema_name AUTHORIZATION role_spec
| CREATE SCHEMA IF NOT EXISTS opt_schema_name AUTHORIZATION role_spec
| CREATE SCHEMA error 








alter_schema_stmt:
  ALTER SCHEMA qualifiable_schema_name RENAME TO schema_name
| ALTER SCHEMA qualifiable_schema_name OWNER TO role_spec
| ALTER SCHEMA error 

































create_table_stmt:
  CREATE opt_persistence_temp_table TABLE table_name '(' opt_table_elem_list ')' opt_create_table_inherits opt_partition_by_table opt_table_with opt_create_table_on_commit opt_locality
| CREATE opt_persistence_temp_table TABLE IF NOT EXISTS table_name '(' opt_table_elem_list ')' opt_create_table_inherits opt_partition_by_table opt_table_with opt_create_table_on_commit opt_locality

opt_locality:
  locality
| 

opt_table_with:
  opt_with_storage_parameter_list
| WITHOUT OIDS
| WITH OIDS error

opt_create_table_inherits:
| INHERITS error

opt_with_storage_parameter_list:
| WITH '(' storage_parameter_list ')'

opt_create_table_on_commit:
| ON COMMIT PRESERVE ROWS
| ON COMMIT DELETE ROWS error
| ON COMMIT DROP error

storage_parameter_key:
  name
| SCONST

storage_parameter_key_list:
  storage_parameter_key
| storage_parameter_key_list ',' storage_parameter_key

storage_parameter:
  storage_parameter_key '=' var_value

storage_parameter_list:
  storage_parameter
|  storage_parameter_list ',' storage_parameter

create_table_as_stmt:
  CREATE opt_persistence_temp_table TABLE table_name create_as_opt_col_list opt_table_with AS select_stmt opt_create_as_data opt_create_table_on_commit
| CREATE opt_persistence_temp_table TABLE IF NOT EXISTS table_name create_as_opt_col_list opt_table_with AS select_stmt opt_create_as_data opt_create_table_on_commit

opt_create_as_data:
| WITH DATA    
| WITH NO DATA 


 opt_temp:
  TEMPORARY         
| TEMP              
|          

opt_persistence_temp_table:
  opt_temp
| LOCAL TEMPORARY   
| LOCAL TEMP        
| GLOBAL TEMPORARY  
| GLOBAL TEMP       
| UNLOGGED          

opt_table_elem_list:
  table_elem_list
| 

table_elem_list:
  table_elem
| table_elem_list ',' table_elem

table_elem:
  column_def
| index_def
| family_def
| table_constraint opt_validate_behavior
| LIKE table_name like_table_option_list

like_table_option_list:
  like_table_option_list INCLUDING like_table_option
| like_table_option_list EXCLUDING like_table_option
| 

like_table_option:
  COMMENTS			
| CONSTRAINTS		
| DEFAULTS			
| IDENTITY	  	
| GENERATED			
| INDEXES			
| STATISTICS		
| STORAGE			
| ALL				


partition:
  PARTITION partition_name

opt_partition:
  partition
| 

opt_partition_by:
  partition_by
| 

partition_by_index:
  partition_by

opt_partition_by_index:
  partition_by
| 

partition_by_table:
  partition_by
| PARTITION ALL BY partition_by_inner

opt_partition_by_table:
  partition_by_table
| 

partition_by:
  PARTITION BY partition_by_inner

partition_by_inner:
  LIST '(' name_list ')' '(' list_partitions ')'
| RANGE '(' name_list ')' '(' range_partitions ')'
| NOTHING

list_partitions:
  list_partition
| list_partitions ',' list_partition

list_partition:
  partition VALUES IN '(' expr_list ')' opt_partition_by

range_partitions:
  range_partition
| range_partitions ',' range_partition

range_partition:
  partition VALUES FROM '(' expr_list ')' TO '(' expr_list ')' opt_partition_by




column_def:
  column_name typename col_qual_list

col_qual_list:
  col_qual_list col_qualification
| 

col_qualification:
  CONSTRAINT constraint_name col_qualification_elem
| col_qualification_elem
| COLLATE collation_name
| FAMILY family_name
| CREATE FAMILY family_name
| CREATE FAMILY
| CREATE IF NOT EXISTS FAMILY family_name













col_qualification_elem:
  NOT NULL
| NULL
| NOT VISIBLE
| UNIQUE opt_without_index
| PRIMARY KEY opt_with_storage_parameter_list
| PRIMARY KEY USING HASH opt_hash_sharded_bucket_count opt_with_storage_parameter_list

| CHECK '(' a_expr ')'
| DEFAULT b_expr
| ON UPDATE b_expr
| REFERENCES table_name opt_name_parens key_match reference_actions
| generated_as '(' a_expr ')' STORED
| generated_as '(' a_expr ')' VIRTUAL
| generated_as error
| generated_always_as IDENTITY '(' opt_sequence_option_list ')'
| generated_by_default_as IDENTITY '(' opt_sequence_option_list ')'
| generated_always_as IDENTITY
| generated_by_default_as IDENTITY

opt_without_index:
  WITHOUT INDEX
| 

generated_as:
  AS 
| generated_always_as

generated_always_as:
  GENERATED_ALWAYS ALWAYS AS 

generated_by_default_as:
  GENERATED_BY_DEFAULT BY DEFAULT AS 

index_def:
  INDEX opt_index_name '(' index_params ')' opt_hash_sharded opt_storing opt_partition_by_index opt_with_storage_parameter_list opt_where_clause
| UNIQUE INDEX opt_index_name '(' index_params ')' opt_hash_sharded opt_storing opt_partition_by_index opt_with_storage_parameter_list opt_where_clause
| INVERTED INDEX opt_name '(' index_params ')' opt_partition_by_index opt_with_storage_parameter_list opt_where_clause

family_def:
  FAMILY opt_family_name '(' name_list ')'




table_constraint:
  CONSTRAINT constraint_name constraint_elem
| constraint_elem

constraint_elem:
  CHECK '(' a_expr ')' opt_deferrable
| UNIQUE opt_without_index '(' index_params ')'
    opt_storing opt_partition_by_index opt_deferrable opt_where_clause
| PRIMARY KEY '(' index_params ')' opt_hash_sharded opt_with_storage_parameter_list
| FOREIGN KEY '(' name_list ')' REFERENCES table_name
    opt_column_list key_match reference_actions opt_deferrable
| EXCLUDE USING error


create_as_opt_col_list:
  '(' create_as_table_defs ')'
| 

create_as_table_defs:
  column_name create_as_col_qual_list
| create_as_table_defs ',' column_name create_as_col_qual_list
| create_as_table_defs ',' family_def
| create_as_table_defs ',' create_as_constraint_def


create_as_constraint_def:
  create_as_constraint_elem

create_as_constraint_elem:
  PRIMARY KEY '(' create_as_params ')' opt_with_storage_parameter_list

create_as_params:
  create_as_param
| create_as_params ',' create_as_param

create_as_param:
  column_name

create_as_col_qual_list:
  create_as_col_qual_list create_as_col_qualification
| 

create_as_col_qualification:
  create_as_col_qualification_elem
| FAMILY family_name

create_as_col_qualification_elem:
  PRIMARY KEY opt_with_storage_parameter_list

opt_deferrable:
| DEFERRABLE 
| DEFERRABLE INITIALLY DEFERRED 
| DEFERRABLE INITIALLY IMMEDIATE 
| INITIALLY DEFERRED 
| INITIALLY IMMEDIATE 

storing:
  COVERING
| STORING
| INCLUDE










opt_storing:
  storing '(' name_list ')'
| 

opt_hash_sharded:
  USING HASH opt_hash_sharded_bucket_count
  | 

opt_hash_sharded_bucket_count:
  WITH_LA BUCKET_COUNT '=' a_expr
  |

opt_column_list:
  '(' name_list ')'
| 















key_match:
  MATCH SIMPLE
| MATCH FULL
| MATCH PARTIAL
| 




reference_actions:
  reference_on_update
| reference_on_delete
| reference_on_update reference_on_delete
| reference_on_delete reference_on_update
| 

reference_on_update:
  ON_LA UPDATE reference_action

reference_on_delete:
  ON_LA DELETE reference_action

reference_action:


  NO ACTION
| RESTRICT
| CASCADE
| SET NULL
| SET DEFAULT















create_sequence_stmt:
  CREATE opt_temp SEQUENCE sequence_name opt_sequence_option_list
| CREATE opt_temp SEQUENCE IF NOT EXISTS sequence_name opt_sequence_option_list
| CREATE opt_temp SEQUENCE error 

opt_sequence_option_list:
  sequence_option_list
|           

sequence_option_list:
  sequence_option_elem                       
| sequence_option_list sequence_option_elem  

sequence_option_elem:
  AS typename                  
| CYCLE                        
| NO CYCLE                     
| OWNED BY NONE                
| OWNED BY column_path         
| CACHE signed_iconst64        
| INCREMENT signed_iconst64    
| INCREMENT BY signed_iconst64 
| MINVALUE signed_iconst64     
| NO MINVALUE                  
| MAXVALUE signed_iconst64     
| NO MAXVALUE                  
| START signed_iconst64        
| START WITH signed_iconst64   
| VIRTUAL                      





truncate_stmt:
  TRUNCATE opt_table relation_expr_list opt_drop_behavior
| TRUNCATE error 

password_clause:
  ENCRYPTED PASSWORD string_or_placeholder
| PASSWORD string_or_placeholder
| PASSWORD NULL





create_role_stmt:
  CREATE role_or_group_or_user role_spec opt_role_options
| CREATE role_or_group_or_user IF NOT EXISTS role_spec opt_role_options
| CREATE role_or_group_or_user error 








alter_role_stmt:
  ALTER role_or_group_or_user role_spec opt_role_options

| ALTER role_or_group_or_user IF EXISTS role_spec opt_role_options

| ALTER role_or_group_or_user role_spec opt_in_database set_or_reset_clause
| ALTER role_or_group_or_user IF EXISTS role_spec opt_in_database set_or_reset_clause
| ALTER ROLE_ALL ALL opt_in_database set_or_reset_clause
| ALTER USER_ALL ALL opt_in_database set_or_reset_clause
| ALTER role_or_group_or_user error 

opt_in_database:
  IN DATABASE database_name
| 



set_or_reset_clause:
  SET set_rest
| SET_TRACING set_rest
| RESET_ALL ALL
| RESET session_var



role_or_group_or_user:
  ROLE
| GROUP
| USER





create_view_stmt:
  CREATE opt_temp opt_view_recursive VIEW view_name opt_column_list AS select_stmt


| CREATE OR REPLACE opt_temp opt_view_recursive VIEW view_name opt_column_list AS select_stmt
| CREATE opt_temp opt_view_recursive VIEW IF NOT EXISTS view_name opt_column_list AS select_stmt
| CREATE MATERIALIZED VIEW view_name opt_column_list AS select_stmt opt_with_data
| CREATE MATERIALIZED VIEW IF NOT EXISTS view_name opt_column_list AS select_stmt opt_with_data
| CREATE opt_temp opt_view_recursive VIEW error 

opt_with_data:
  WITH NO DATA error
| WITH DATA
| 

role_option:
  CREATEROLE
| NOCREATEROLE
| LOGIN
| NOLOGIN
| CONTROLJOB
| NOCONTROLJOB
| CONTROLCHANGEFEED
| NOCONTROLCHANGEFEED
| CREATEDB
| NOCREATEDB
| CREATELOGIN
| NOCREATELOGIN
| VIEWACTIVITY
| NOVIEWACTIVITY
| VIEWACTIVITYREDACTED
| NOVIEWACTIVITYREDACTED
| CANCELQUERY
| NOCANCELQUERY
| MODIFYCLUSTERSETTING
| NOMODIFYCLUSTERSETTING
| SQLLOGIN
| NOSQLLOGIN
| VIEWCLUSTERSETTING
| NOVIEWCLUSTERSETTING
| password_clause
| valid_until_clause

role_options:
  role_option
| role_options role_option

opt_role_options:
  opt_with role_options
| 

valid_until_clause:
  VALID UNTIL string_or_placeholder
| VALID UNTIL NULL

opt_view_recursive:
| RECURSIVE 





create_type_stmt:
  
  CREATE TYPE type_name AS ENUM '(' opt_enum_val_list ')'
| CREATE TYPE IF NOT EXISTS type_name AS ENUM '(' opt_enum_val_list ')'
| CREATE TYPE error 
  
| CREATE TYPE type_name AS '(' error      
  
| CREATE TYPE type_name AS RANGE error    
  
| CREATE TYPE type_name '(' error         
  
| CREATE TYPE type_name                   
  
| CREATE DOMAIN type_name error           

opt_enum_val_list:
  enum_val_list
| 

enum_val_list:
  SCONST
| enum_val_list ',' SCONST












create_index_stmt:
  CREATE opt_unique INDEX opt_concurrently opt_index_name ON table_name opt_index_access_method '(' index_params ')' opt_hash_sharded opt_storing opt_partition_by_index opt_with_storage_parameter_list opt_where_clause
| CREATE opt_unique INDEX opt_concurrently IF NOT EXISTS index_name ON table_name opt_index_access_method '(' index_params ')' opt_hash_sharded opt_storing opt_partition_by_index opt_with_storage_parameter_list opt_where_clause
| CREATE opt_unique INVERTED INDEX opt_concurrently opt_index_name ON table_name '(' index_params ')' opt_storing opt_partition_by_index opt_with_storage_parameter_list opt_where_clause
| CREATE opt_unique INVERTED INDEX opt_concurrently IF NOT EXISTS index_name ON table_name '(' index_params ')' opt_storing opt_partition_by_index opt_with_storage_parameter_list opt_where_clause
| CREATE opt_unique INDEX error 

opt_index_access_method:
  USING name
| 

opt_concurrently:
  CONCURRENTLY
| 

opt_unique:
  UNIQUE
| 

index_params:
  index_elem
| index_params ',' index_elem




index_elem:
  func_expr_windowless index_elem_options
| '(' a_expr ')' index_elem_options
| name index_elem_options

index_elem_options:
  opt_class opt_asc_desc opt_nulls_order

opt_class:
  name 
|  

opt_collate:
  COLLATE collation_name 
|  

opt_asc_desc:
  ASC
| DESC
| 

alter_database_to_schema_stmt:
  ALTER DATABASE database_name CONVERT TO SCHEMA WITH PARENT database_name

alter_rename_database_stmt:
  ALTER DATABASE database_name RENAME TO database_name

alter_rename_table_stmt:
  ALTER TABLE relation_expr RENAME TO table_name
| ALTER TABLE IF EXISTS relation_expr RENAME TO table_name

alter_table_set_schema_stmt:
  ALTER TABLE relation_expr SET SCHEMA schema_name
| ALTER TABLE IF EXISTS relation_expr SET SCHEMA schema_name

alter_table_locality_stmt:
  ALTER TABLE relation_expr SET locality
| ALTER TABLE IF EXISTS relation_expr SET locality

locality:
  LOCALITY GLOBAL
| LOCALITY REGIONAL BY TABLE IN region_name
| LOCALITY REGIONAL BY TABLE IN PRIMARY REGION
| LOCALITY REGIONAL BY TABLE
| LOCALITY REGIONAL IN region_name
| LOCALITY REGIONAL IN PRIMARY REGION
| LOCALITY REGIONAL
| LOCALITY REGIONAL BY ROW
| LOCALITY REGIONAL BY ROW AS name

alter_table_owner_stmt:
  ALTER TABLE relation_expr OWNER TO role_spec
| ALTER TABLE IF EXISTS relation_expr OWNER TO role_spec

alter_view_set_schema_stmt:
	ALTER VIEW relation_expr SET SCHEMA schema_name
| ALTER MATERIALIZED VIEW relation_expr SET SCHEMA schema_name
| ALTER VIEW IF EXISTS relation_expr SET SCHEMA schema_name
| ALTER MATERIALIZED VIEW IF EXISTS relation_expr SET SCHEMA schema_name

alter_view_owner_stmt:
	ALTER VIEW relation_expr OWNER TO role_spec
| ALTER MATERIALIZED VIEW relation_expr OWNER TO role_spec
| ALTER VIEW IF EXISTS relation_expr OWNER TO role_spec
| ALTER MATERIALIZED VIEW IF EXISTS relation_expr OWNER TO role_spec

alter_sequence_set_schema_stmt:
	ALTER SEQUENCE relation_expr SET SCHEMA schema_name
| ALTER SEQUENCE IF EXISTS relation_expr SET SCHEMA schema_name

alter_sequence_owner_stmt:
	ALTER SEQUENCE relation_expr OWNER TO role_spec
| ALTER SEQUENCE IF EXISTS relation_expr OWNER TO role_spec

alter_rename_view_stmt:
  ALTER VIEW relation_expr RENAME TO view_name
| ALTER MATERIALIZED VIEW relation_expr RENAME TO view_name
| ALTER VIEW IF EXISTS relation_expr RENAME TO view_name
| ALTER MATERIALIZED VIEW IF EXISTS relation_expr RENAME TO view_name

alter_rename_sequence_stmt:
  ALTER SEQUENCE relation_expr RENAME TO sequence_name
| ALTER SEQUENCE IF EXISTS relation_expr RENAME TO sequence_name

alter_rename_index_stmt:
  ALTER INDEX table_index_name RENAME TO index_name
| ALTER INDEX IF EXISTS table_index_name RENAME TO index_name







alter_default_privileges_stmt:
 ALTER DEFAULT PRIVILEGES opt_for_roles opt_in_schemas abbreviated_grant_stmt
| ALTER DEFAULT PRIVILEGES opt_for_roles opt_in_schemas abbreviated_revoke_stmt
| ALTER DEFAULT PRIVILEGES FOR ALL ROLES opt_in_schemas abbreviated_grant_stmt
| ALTER DEFAULT PRIVILEGES FOR ALL ROLES opt_in_schemas abbreviated_revoke_stmt
| ALTER DEFAULT PRIVILEGES error 

abbreviated_grant_stmt:
  GRANT privileges ON alter_default_privileges_target_object TO role_spec_list opt_with_grant_option

opt_with_grant_option:
 WITH GRANT OPTION
| 

abbreviated_revoke_stmt:
  REVOKE privileges ON alter_default_privileges_target_object FROM role_spec_list opt_drop_behavior
| REVOKE GRANT OPTION FOR privileges ON alter_default_privileges_target_object FROM role_spec_list opt_drop_behavior

alter_default_privileges_target_object:
  TABLES
| SEQUENCES
| TYPES
| SCHEMAS
| FUNCTIONS error
| ROUTINES error

opt_for_roles:
 FOR role_or_group_or_user role_spec_list
|  

opt_in_schema:
 IN SCHEMA schema_name
| 


opt_in_schemas:
 IN SCHEMA schema_name_list
| 

opt_column:
  COLUMN 
|  

opt_set_data:
  SET DATA 
|  





release_stmt:
  RELEASE savepoint_name
| RELEASE error 







resume_jobs_stmt:
  RESUME JOB a_expr
| RESUME JOB error 
| RESUME JOBS select_stmt
| RESUME JOBS for_schedules_clause
| RESUME JOBS error 










resume_schedules_stmt:
  RESUME SCHEDULE a_expr
| RESUME SCHEDULE error 
| RESUME SCHEDULES select_stmt
| RESUME SCHEDULES error 










drop_schedule_stmt:
  DROP SCHEDULE a_expr
| DROP SCHEDULE error 
| DROP SCHEDULES select_stmt
| DROP SCHEDULES error 





savepoint_stmt:
  SAVEPOINT name
| SAVEPOINT error 


transaction_stmt:
  begin_stmt    
| commit_stmt   
| rollback_stmt 
| abort_stmt    












begin_stmt:
  BEGIN opt_transaction begin_transaction
| BEGIN error 
| START TRANSACTION begin_transaction
| START error 







commit_stmt:
  COMMIT opt_transaction
| COMMIT error 
| END opt_transaction
| END error 

abort_stmt:
  ABORT opt_abort_mod

opt_abort_mod:
  TRANSACTION 
| WORK        
|  







rollback_stmt:
  ROLLBACK opt_transaction
| ROLLBACK opt_transaction TO savepoint_name
| ROLLBACK error 

opt_transaction:
  TRANSACTION 
|  

savepoint_name:
  SAVEPOINT name
| name

begin_transaction:
  transaction_mode_list
| 

transaction_mode_list:
  transaction_mode
| transaction_mode_list opt_comma transaction_mode




opt_comma:
  ','
| 

transaction_mode:
  transaction_iso_level
| transaction_user_priority
| transaction_read_mode
| as_of_clause
| transaction_deferrable_mode

transaction_user_priority:
  PRIORITY user_priority

transaction_iso_level:
  ISOLATION LEVEL iso_level

transaction_read_mode:
  READ ONLY
| READ WRITE

transaction_deferrable_mode:
  DEFERRABLE
| NOT DEFERRABLE





create_database_stmt:
  CREATE DATABASE database_name opt_with opt_template_clause opt_encoding_clause opt_lc_collate_clause opt_lc_ctype_clause opt_connection_limit opt_primary_region_clause opt_regions_list opt_survival_goal_clause opt_placement_clause opt_owner_clause
| CREATE DATABASE IF NOT EXISTS database_name opt_with opt_template_clause opt_encoding_clause opt_lc_collate_clause opt_lc_ctype_clause opt_connection_limit opt_primary_region_clause opt_regions_list opt_survival_goal_clause opt_placement_clause
| CREATE DATABASE error 

opt_primary_region_clause:
  primary_region_clause
| 

primary_region_clause:
  PRIMARY REGION opt_equal region_name 

opt_placement_clause:
  placement_clause
| 

placement_clause:
  PLACEMENT RESTRICTED
| PLACEMENT DEFAULT

opt_regions_list:
  region_or_regions opt_equal region_name_list
| 

region_or_regions:
  REGION
| REGIONS

survival_goal_clause:
  SURVIVE opt_equal REGION FAILURE
| SURVIVE opt_equal ZONE FAILURE
| SURVIVE opt_equal AVAILABILITY ZONE FAILURE


opt_survival_goal_clause:
  survival_goal_clause
| 

opt_template_clause:
  TEMPLATE opt_equal non_reserved_word_or_sconst
| 

opt_encoding_clause:
  ENCODING opt_equal non_reserved_word_or_sconst
| 

opt_lc_collate_clause:
  LC_COLLATE opt_equal non_reserved_word_or_sconst
| 

opt_lc_ctype_clause:
  LC_CTYPE opt_equal non_reserved_word_or_sconst
| 

opt_connection_limit:
  CONNECTION LIMIT opt_equal signed_iconst
| 

opt_owner_clause:
  OWNER opt_equal role_spec
| 

opt_equal:
  '=' 
|  









insert_stmt:
  opt_with_clause INSERT INTO insert_target insert_rest returning_clause
| opt_with_clause INSERT INTO insert_target insert_rest on_conflict returning_clause
| opt_with_clause INSERT error 








upsert_stmt:
  opt_with_clause UPSERT INTO insert_target insert_rest returning_clause
| opt_with_clause UPSERT error 

insert_target:
  table_name




| table_name AS table_alias_name
| numeric_table_ref

insert_rest:
  select_stmt
| '(' insert_column_list ')' select_stmt
| DEFAULT VALUES

insert_column_list:
  insert_column_item
| insert_column_list ',' insert_column_item















insert_column_item:
  column_name
| column_name '.' error 

on_conflict:
  ON CONFLICT DO NOTHING
| ON CONFLICT '(' name_list ')' opt_where_clause DO NOTHING
| ON CONFLICT '(' name_list ')' opt_where_clause DO UPDATE SET set_clause_list opt_where_clause
| ON CONFLICT ON CONSTRAINT constraint_name DO NOTHING
| ON CONFLICT ON CONSTRAINT constraint_name DO UPDATE SET set_clause_list opt_where_clause

returning_clause:
  RETURNING target_list
| RETURNING NOTHING
| 











update_stmt:
  opt_with_clause UPDATE table_expr_opt_alias_idx
    SET set_clause_list opt_from_list opt_where_clause opt_sort_clause opt_limit_clause returning_clause
| opt_with_clause UPDATE error 

opt_from_list:
  FROM from_list 
|  

set_clause_list:
  set_clause
| set_clause_list ',' set_clause




set_clause:
  single_set_clause
| multiple_set_clause

single_set_clause:
  column_name '=' a_expr
| column_name '.' error 

multiple_set_clause:
  '(' insert_column_list ')' '=' in_expr






reassign_owned_by_stmt:
  REASSIGN OWNED BY role_spec_list TO role_spec
| REASSIGN OWNED BY error 






drop_owned_by_stmt:
  DROP OWNED BY role_spec_list opt_drop_behavior
| DROP OWNED BY error 





































select_stmt:
  select_no_parens 
| select_with_parens 

select_with_parens:
  '(' select_no_parens ')'
| '(' select_with_parens ')'










select_no_parens:
  simple_select
| select_clause sort_clause
| select_clause opt_sort_clause for_locking_clause opt_select_limit
| select_clause opt_sort_clause select_limit opt_for_locking_clause
| with_clause select_clause
| with_clause select_clause sort_clause
| with_clause select_clause opt_sort_clause for_locking_clause opt_select_limit
| with_clause select_clause opt_sort_clause select_limit opt_for_locking_clause

for_locking_clause:
  for_locking_items 
| FOR READ ONLY     

opt_for_locking_clause:
  for_locking_clause 
|         

for_locking_items:
  for_locking_item
| for_locking_items for_locking_item

for_locking_item:
  for_locking_strength opt_locked_rels opt_nowait_or_skip

for_locking_strength:
  FOR UPDATE        
| FOR NO KEY UPDATE 
| FOR SHARE         
| FOR KEY SHARE     

opt_locked_rels:
| OF table_name_list 

opt_nowait_or_skip:
| SKIP LOCKED 
| NOWAIT      

select_clause:


  '(' error 
| simple_select
| select_with_parens































simple_select:
  simple_select_clause 
| values_clause        
| table_clause         
| set_operation
















simple_select_clause:
  SELECT opt_all_clause target_list
    from_clause opt_where_clause
    group_clause having_clause window_clause
| SELECT distinct_clause target_list
    from_clause opt_where_clause
    group_clause having_clause window_clause
| SELECT distinct_on_clause target_list
    from_clause opt_where_clause
    group_clause having_clause window_clause
| SELECT error 

set_operation:
  select_clause UNION all_or_distinct select_clause
| select_clause INTERSECT all_or_distinct select_clause
| select_clause EXCEPT all_or_distinct select_clause





table_clause:
  TABLE table_ref
| TABLE error 









with_clause:
  WITH cte_list
| WITH_LA cte_list
| WITH RECURSIVE cte_list

cte_list:
  common_table_expr
| cte_list ',' common_table_expr

materialize_clause:
  MATERIALIZED
| NOT MATERIALIZED

common_table_expr:
  table_alias_name opt_column_list AS '(' preparable_stmt ')'
| table_alias_name opt_column_list AS materialize_clause '(' preparable_stmt ')'

opt_with:
  WITH 
|  

opt_with_clause:
  with_clause
| 

opt_table:
  TABLE 
|  

all_or_distinct:
  ALL
| DISTINCT
| 

distinct_clause:
  DISTINCT

distinct_on_clause:
  DISTINCT ON '(' expr_list ')'

opt_all_clause:
  ALL 
|  

opt_privileges_clause:
  PRIVILEGES 
|  

opt_sort_clause:
  sort_clause
| 

sort_clause:
  ORDER BY sortby_list

single_sort_clause:
  ORDER BY sortby
| ORDER BY sortby ',' sortby_list

sortby_list:
  sortby
| sortby_list ',' sortby

sortby:
  a_expr opt_asc_desc opt_nulls_order
| PRIMARY KEY table_name opt_asc_desc
| INDEX table_name '@' index_name opt_asc_desc

opt_nulls_order:
  NULLS_LA FIRST
| NULLS_LA LAST
| 

select_limit:
  limit_clause offset_clause
| offset_clause limit_clause
| limit_clause
| offset_clause

opt_select_limit:
  select_limit 
|   

opt_limit_clause:
  limit_clause
|  

limit_clause:
  LIMIT ALL
| LIMIT a_expr






| FETCH first_or_next select_fetch_first_value row_or_rows ONLY
| FETCH first_or_next row_or_rows ONLY

offset_clause:
  OFFSET a_expr
  
  
  
| OFFSET select_fetch_first_value row_or_rows












select_fetch_first_value:
  c_expr
| only_signed_iconst
| only_signed_fconst


row_or_rows:
  ROW 
| ROWS 

first_or_next:
  FIRST 
| NEXT 














group_clause:
  GROUP BY group_by_list
| 

group_by_list:
  group_by_item 
| group_by_list ',' group_by_item 




group_by_item:
  a_expr 
| ROLLUP '(' error 
| CUBE '(' error 
| GROUPING SETS error 

having_clause:
  HAVING a_expr
| 














values_clause:
  VALUES '(' expr_list ')' 
| VALUES error 
| values_clause ',' '(' expr_list ')'





from_clause:
  FROM from_list opt_as_of_clause
| FROM error 
| 

from_list:
  table_ref
| from_list ',' table_ref

index_flags_param:
  FORCE_INDEX '=' index_name
| FORCE_INDEX '=' '[' iconst64 ']'
| ASC
| DESC
|
  NO_INDEX_JOIN
|
  NO_ZIGZAG_JOIN
|
  NO_FULL_SCAN
|
  IGNORE_FOREIGN_KEYS
|
  FORCE_ZIGZAG
|
  FORCE_ZIGZAG '=' index_name
|
  FORCE_ZIGZAG '=' '[' iconst64 ']'

index_flags_param_list:
  index_flags_param
|
  index_flags_param_list ',' index_flags_param

opt_index_flags:
  '@' index_name
| '@' '[' iconst64 ']'
| '@' ''
| 





























table_ref:
  numeric_table_ref opt_index_flags opt_ordinality opt_alias_clause
| relation_expr opt_index_flags opt_ordinality opt_alias_clause
| select_with_parens opt_ordinality opt_alias_clause
| LATERAL select_with_parens opt_ordinality opt_alias_clause
| joined_table
| '(' joined_table ')' opt_ordinality alias_clause
| func_table opt_ordinality opt_alias_clause
| LATERAL func_table opt_ordinality opt_alias_clause














| '[' row_source_extension_stmt ']' opt_ordinality opt_alias_clause

numeric_table_ref:
  '[' iconst64 opt_tableref_col_list alias_clause ']'

func_table:
  func_expr_windowless
| ROWS FROM '(' rowsfrom_list ')'

rowsfrom_list:
  rowsfrom_item
| rowsfrom_list ',' rowsfrom_item

rowsfrom_item:
  func_expr_windowless opt_col_def_list

opt_col_def_list:
| AS '(' error

opt_tableref_col_list:
| '(' ')'                   
| '(' tableref_col_list ')' 

tableref_col_list:
  iconst64
| tableref_col_list ',' iconst64

opt_ordinality:
  WITH_LA ORDINALITY
| 















joined_table:
  '(' joined_table ')'
| table_ref CROSS opt_join_hint JOIN table_ref
| table_ref join_type opt_join_hint JOIN table_ref join_qual
| table_ref JOIN table_ref join_qual
| table_ref NATURAL join_type opt_join_hint JOIN table_ref
| table_ref NATURAL JOIN table_ref

alias_clause:
  AS table_alias_name opt_column_list
| table_alias_name opt_column_list

opt_alias_clause:
  alias_clause
| 

as_of_clause:
  AS_LA OF SYSTEM TIME a_expr

opt_as_of_clause:
  as_of_clause
| 

join_type:
  FULL join_outer
| LEFT join_outer
| RIGHT join_outer
| INNER


join_outer:
  OUTER 
|  





















opt_join_hint:
  HASH
| MERGE
| LOOKUP
| INVERTED
| 








join_qual:
  USING '(' name_list ')'
| ON a_expr

relation_expr:
  table_name              
| table_name '*'          
| ONLY table_name         
| ONLY '(' table_name ')' 

relation_expr_list:
  relation_expr
| relation_expr_list ',' relation_expr








table_expr_opt_alias_idx:
  table_name_opt_idx 
| table_name_opt_idx table_alias_name
| table_name_opt_idx AS table_alias_name
| numeric_table_ref opt_index_flags

table_name_opt_idx:
  opt_only table_name opt_index_flags opt_descendant

opt_only:
	ONLY
| 

opt_descendant:
	'*'
| 

where_clause:
  WHERE a_expr

opt_where_clause:
  where_clause
| 







typename:
  simple_typename opt_array_bounds
  
  
| simple_typename ARRAY '[' ICONST ']' 
| simple_typename ARRAY '[' ICONST ']' '[' error 
| simple_typename ARRAY 

cast_target:
  typename

opt_array_bounds:
  
  
  '[' ']' 
| '[' ']' '[' error 
| '[' ICONST ']'
| '[' ICONST ']' '[' error 
|  




general_type_name:
  type_function_name_no_crdb_extra



complex_type_name:
  general_type_name '.' unrestricted_name
| general_type_name '.' unrestricted_name '.' unrestricted_name

simple_typename:
  general_type_name
| '@' iconst32
| complex_type_name
| const_typename
| bit_with_length
| character_with_length
| interval_type
| POINT error  
| POLYGON error  

geo_shape_type:
  POINT 
| POINTM 
| POINTZ 
| POINTZM 
| LINESTRING 
| LINESTRINGM 
| LINESTRINGZ 
| LINESTRINGZM 
| POLYGON 
| POLYGONM 
| POLYGONZ 
| POLYGONZM 
| MULTIPOINT 
| MULTIPOINTM 
| MULTIPOINTZ 
| MULTIPOINTZM 
| MULTILINESTRING 
| MULTILINESTRINGM 
| MULTILINESTRINGZ 
| MULTILINESTRINGZM 
| MULTIPOLYGON 
| MULTIPOLYGONM 
| MULTIPOLYGONZ 
| MULTIPOLYGONZM 
| GEOMETRYCOLLECTION 
| GEOMETRYCOLLECTIONM 
| GEOMETRYCOLLECTIONZ 
| GEOMETRYCOLLECTIONZM 
| GEOMETRY 
| GEOMETRYM 
| GEOMETRYZ 
| GEOMETRYZM 

const_geo:
  GEOGRAPHY 
| GEOMETRY  
| BOX2D     
| GEOMETRY '(' geo_shape_type ')'
| GEOGRAPHY '(' geo_shape_type ')'
| GEOMETRY '(' geo_shape_type ',' signed_iconst ')'
| GEOGRAPHY '(' geo_shape_type ',' signed_iconst ')'










const_typename:
  numeric
| bit_without_length
| character_without_length
| const_datetime
| const_geo

opt_numeric_modifiers:
  '(' iconst32 ')'
| '(' iconst32 ',' iconst32 ')'
| 


numeric:
  INT
| INTEGER
| SMALLINT
| BIGINT
| REAL
| FLOAT opt_float
| DOUBLE PRECISION
| DECIMAL opt_numeric_modifiers
| DEC opt_numeric_modifiers
| NUMERIC opt_numeric_modifiers
| BOOLEAN

opt_float:
  '(' ICONST ')'
| 

bit_with_length:
  BIT opt_varying '(' iconst32 ')'
| VARBIT '(' iconst32 ')'

bit_without_length:
  BIT
| BIT VARYING
| VARBIT

character_with_length:
  character_base '(' iconst32 ')'

character_without_length:
  character_base

character_base:
  char_aliases
| char_aliases VARYING
| VARCHAR
| STRING

char_aliases:
  CHAR
| CHARACTER

opt_varying:
  VARYING     
|  


const_datetime:
  DATE
| TIME opt_timezone
| TIME '(' iconst32 ')' opt_timezone
| TIMETZ                             
| TIMETZ '(' iconst32 ')'
| TIMESTAMP opt_timezone
| TIMESTAMP '(' iconst32 ')' opt_timezone
| TIMESTAMPTZ
| TIMESTAMPTZ '(' iconst32 ')'

opt_timezone:
  WITH_LA TIME ZONE 
| WITHOUT TIME ZONE 
|          

interval_type:
  INTERVAL
| INTERVAL interval_qualifier
| INTERVAL '(' iconst32 ')'

interval_qualifier:
  YEAR 
| MONTH 
| DAY 
| HOUR 
| MINUTE 
| interval_second


| YEAR TO MONTH 
| DAY TO HOUR 
| DAY TO MINUTE 
| DAY TO interval_second 
| HOUR TO MINUTE 
| HOUR TO interval_second 
| MINUTE TO interval_second 

opt_interval_qualifier:
  interval_qualifier
| 

interval_second:
  SECOND
| SECOND '(' iconst32 ')'




















a_expr:
  c_expr
| a_expr TYPECAST cast_target
| a_expr TYPEANNOTATE typename
| a_expr COLLATE collation_name
| a_expr AT TIME ZONE a_expr 
  
  
  
  
  
  
  
| '+' a_expr 
| '-' a_expr 
| '~' a_expr 
| SQRT a_expr
| CBRT a_expr
| a_expr '+' a_expr
| a_expr '-' a_expr
| a_expr '*' a_expr
| a_expr '/' a_expr
| a_expr FLOORDIV a_expr
| a_expr '%' a_expr
| a_expr '^' a_expr
| a_expr '#' a_expr
| a_expr '&' a_expr
| a_expr '|' a_expr
| a_expr '<' a_expr
| a_expr '>' a_expr
| a_expr '?' a_expr
| a_expr JSON_SOME_EXISTS a_expr
| a_expr JSON_ALL_EXISTS a_expr
| a_expr CONTAINS a_expr
| a_expr CONTAINED_BY a_expr
| a_expr '=' a_expr
| a_expr CONCAT a_expr
| a_expr LSHIFT a_expr
| a_expr RSHIFT a_expr
| a_expr FETCHVAL a_expr
| a_expr FETCHTEXT a_expr
| a_expr FETCHVAL_PATH a_expr
| a_expr FETCHTEXT_PATH a_expr
| a_expr REMOVE_PATH a_expr
| a_expr INET_CONTAINED_BY_OR_EQUALS a_expr
| a_expr AND_AND a_expr
| a_expr INET_CONTAINS_OR_EQUALS a_expr
| a_expr LESS_EQUALS a_expr
| a_expr GREATER_EQUALS a_expr
| a_expr NOT_EQUALS a_expr
| qual_op a_expr 
| a_expr qual_op a_expr 
| a_expr AND a_expr
| a_expr OR a_expr
| NOT a_expr
| NOT_LA a_expr 
| a_expr LIKE a_expr
| a_expr LIKE a_expr ESCAPE a_expr 
| a_expr NOT_LA LIKE a_expr 
| a_expr NOT_LA LIKE a_expr ESCAPE a_expr 
| a_expr ILIKE a_expr
| a_expr ILIKE a_expr ESCAPE a_expr 
| a_expr NOT_LA ILIKE a_expr 
| a_expr NOT_LA ILIKE a_expr ESCAPE a_expr 
| a_expr SIMILAR TO a_expr 
| a_expr SIMILAR TO a_expr ESCAPE a_expr 
| a_expr NOT_LA SIMILAR TO a_expr 
| a_expr NOT_LA SIMILAR TO a_expr ESCAPE a_expr 
| a_expr '~' a_expr
| a_expr NOT_REGMATCH a_expr
| a_expr REGIMATCH a_expr
| a_expr NOT_REGIMATCH a_expr
| a_expr IS NAN 
| a_expr IS NOT NAN 
| a_expr IS NULL 
| a_expr ISNULL 
| a_expr IS NOT NULL 
| a_expr NOTNULL 
| row OVERLAPS row 
| a_expr IS TRUE 
| a_expr IS NOT TRUE 
| a_expr IS FALSE 
| a_expr IS NOT FALSE 
| a_expr IS UNKNOWN 
| a_expr IS NOT UNKNOWN 
| a_expr IS DISTINCT FROM a_expr 
| a_expr IS NOT DISTINCT FROM a_expr 
| a_expr IS OF '(' type_list ')' 
| a_expr IS NOT OF '(' type_list ')' 
| a_expr BETWEEN opt_asymmetric b_expr AND a_expr 
| a_expr NOT_LA BETWEEN opt_asymmetric b_expr AND a_expr 
| a_expr BETWEEN SYMMETRIC b_expr AND a_expr 
| a_expr NOT_LA BETWEEN SYMMETRIC b_expr AND a_expr 
| a_expr IN in_expr
| a_expr NOT_LA IN in_expr 
| a_expr subquery_op sub_type a_expr 
| DEFAULT


| UNIQUE '(' error 








b_expr:
  c_expr
| b_expr TYPECAST cast_target
| b_expr TYPEANNOTATE typename
| '+' b_expr 
| '-' b_expr 
| '~' b_expr 
| b_expr '+' b_expr
| b_expr '-' b_expr
| b_expr '*' b_expr
| b_expr '/' b_expr
| b_expr FLOORDIV b_expr
| b_expr '%' b_expr
| b_expr '^' b_expr
| b_expr '#' b_expr
| b_expr '&' b_expr
| b_expr '|' b_expr
| b_expr '<' b_expr
| b_expr '>' b_expr
| b_expr '=' b_expr
| b_expr CONCAT b_expr
| b_expr LSHIFT b_expr
| b_expr RSHIFT b_expr
| b_expr LESS_EQUALS b_expr
| b_expr GREATER_EQUALS b_expr
| b_expr NOT_EQUALS b_expr
| qual_op b_expr 
| b_expr qual_op b_expr 
| b_expr IS DISTINCT FROM b_expr 
| b_expr IS NOT DISTINCT FROM b_expr 
| b_expr IS OF '(' type_list ')' 
| b_expr IS NOT OF '(' type_list ')' 








c_expr:
  d_expr
| d_expr array_subscripts
| case_expr
| EXISTS select_with_parens































d_expr:
  ICONST
| FCONST
| SCONST
| BCONST
| BITCONST
| func_name '(' expr_list opt_sort_clause ')' SCONST 
| typed_literal
| interval_value
| TRUE
| FALSE
| NULL
| column_path_with_star
| '@' iconst64
| PLACEHOLDER

| '(' a_expr ')' '.' '*'
| '(' a_expr ')' '.' unrestricted_name
| '(' a_expr ')' '.' '@' ICONST
| '(' a_expr ')'
| func_expr
| select_with_parens 
| labeled_row
| ARRAY select_with_parens 
| ARRAY row
| ARRAY array_expr
| GROUPING '(' expr_list ')' 

func_application:
  func_name '(' ')'
| func_name '(' expr_list opt_sort_clause ')'
| func_name '(' VARIADIC a_expr opt_sort_clause ')' 
| func_name '(' expr_list ',' VARIADIC a_expr opt_sort_clause ')' 
| func_name '(' ALL expr_list opt_sort_clause ')'


| func_name '(' DISTINCT expr_list ')'
| func_name '(' '*' ')'
| func_name '(' error 



typed_literal:
  
  
  
  func_name_no_crdb_extra SCONST
| const_typename SCONST








func_expr:
  func_application within_group_clause filter_clause over_clause
| func_expr_common_subexpr





func_expr_windowless:
  func_application 
| func_expr_common_subexpr 


func_expr_common_subexpr:
  COLLATION FOR '(' a_expr ')'
| CURRENT_DATE
| CURRENT_SCHEMA


| CURRENT_CATALOG
| CURRENT_TIMESTAMP
| CURRENT_TIME
| LOCALTIMESTAMP
| LOCALTIME
| CURRENT_USER


| CURRENT_ROLE
| SESSION_USER
| USER
| CAST '(' a_expr AS cast_target ')'
| ANNOTATE_TYPE '(' a_expr ',' typename ')'
| IF '(' a_expr ',' a_expr ',' a_expr ')'
| IFERROR '(' a_expr ',' a_expr ',' a_expr ')'
| IFERROR '(' a_expr ',' a_expr ')'
| ISERROR '(' a_expr ')'
| ISERROR '(' a_expr ',' a_expr ')'
| NULLIF '(' a_expr ',' a_expr ')'
| IFNULL '(' a_expr ',' a_expr ')'
| COALESCE '(' expr_list ')'
| special_function

special_function:
  CURRENT_DATE '(' ')'
| CURRENT_DATE '(' error 
| CURRENT_SCHEMA '(' ')'
| CURRENT_SCHEMA '(' error 
| CURRENT_TIMESTAMP '(' ')'
| CURRENT_TIMESTAMP '(' a_expr ')'
| CURRENT_TIMESTAMP '(' error 
| CURRENT_TIME '(' ')'
| CURRENT_TIME '(' a_expr ')'
| CURRENT_TIME '(' error 
| LOCALTIMESTAMP '(' ')'
| LOCALTIMESTAMP '(' a_expr ')'
| LOCALTIMESTAMP '(' error 
| LOCALTIME '(' ')'
| LOCALTIME '(' a_expr ')'
| LOCALTIME '(' error 
| CURRENT_USER '(' ')'
| CURRENT_USER '(' error 
| SESSION_USER '(' ')'
| SESSION_USER '(' error 
| EXTRACT '(' extract_list ')'
| EXTRACT '(' error 
| EXTRACT_DURATION '(' extract_list ')'
| EXTRACT_DURATION '(' error 
| OVERLAY '(' overlay_list ')'
| OVERLAY '(' error 
| POSITION '(' position_list ')'
| SUBSTRING '(' substr_list ')'
| SUBSTRING '(' error 
| TREAT '(' a_expr AS typename ')' 
| TRIM '(' BOTH trim_list ')'
| TRIM '(' LEADING trim_list ')'
| TRIM '(' TRAILING trim_list ')'
| TRIM '(' trim_list ')'
| GREATEST '(' expr_list ')'
| GREATEST '(' error 
| LEAST '(' expr_list ')'
| LEAST '(' error 



within_group_clause:
  WITHIN GROUP '(' single_sort_clause ')'
| 

filter_clause:
  FILTER '(' WHERE a_expr ')'
| 


window_clause:
  WINDOW window_definition_list
| 

window_definition_list:
  window_definition
| window_definition_list ',' window_definition

window_definition:
  window_name AS window_specification

over_clause:
  OVER window_specification
| OVER window_name
| 

window_specification:
  '(' opt_existing_window_name opt_partition_clause
    opt_sort_clause opt_frame_clause ')'









opt_existing_window_name:
  name
|  

opt_partition_clause:
  PARTITION BY expr_list
| 

opt_frame_clause:
  RANGE frame_extent opt_frame_exclusion
| ROWS frame_extent opt_frame_exclusion
| GROUPS frame_extent opt_frame_exclusion
| 

frame_extent:
  frame_bound
| BETWEEN frame_bound AND frame_bound




frame_bound:
  UNBOUNDED PRECEDING
| UNBOUNDED FOLLOWING
| CURRENT ROW
| a_expr PRECEDING
| a_expr FOLLOWING

opt_frame_exclusion:
  EXCLUDE CURRENT ROW
| EXCLUDE GROUP
| EXCLUDE TIES
| EXCLUDE NO OTHERS
| 








row:
  ROW '(' opt_expr_list ')'
| expr_tuple_unambiguous

labeled_row:
  row
| '(' row AS name_list ')'

sub_type:
  ANY
| SOME
| ALL











all_op:
  
  '+' 
| '-' 
| '*' 
| '/' 
| '%' 
| '^' 
| '<' 
| '>' 
| '=' 
| LESS_EQUALS    
| GREATER_EQUALS 
| NOT_EQUALS     
  
| '?' 
| '&' 
| '|' 
| '#' 
| FLOORDIV 
| CONTAINS 
| CONTAINED_BY 
| LSHIFT 
| RSHIFT 
| CONCAT 
| FETCHVAL 
| FETCHTEXT 
| FETCHVAL_PATH 
| FETCHTEXT_PATH 
| JSON_SOME_EXISTS 
| JSON_ALL_EXISTS 
| NOT_REGMATCH 
| REGIMATCH 
| NOT_REGIMATCH 
| AND_AND 
| '~' 
| SQRT 
| CBRT 

operator_op:
  all_op
| name '.' all_op







qual_op:
  OPERATOR '(' operator_op ')'

subquery_op:
  all_op
| qual_op
| LIKE         
| NOT_LA LIKE  
| ILIKE        
| NOT_LA ILIKE 
  
  
  
  
  
  
  













expr_tuple1_ambiguous:
  '(' ')'
| '(' tuple1_ambiguous_values ')'

tuple1_ambiguous_values:
  a_expr
| a_expr ','
| a_expr ',' expr_list






expr_tuple_unambiguous:
  '(' ')'
| '(' tuple1_unambiguous_values ')'

tuple1_unambiguous_values:
  a_expr ','
| a_expr ',' expr_list

opt_expr_list:
  expr_list
| 

expr_list:
  a_expr
| expr_list ',' a_expr

type_list:
  typename
| type_list ',' typename

array_expr:
  '[' opt_expr_list ']'
| '[' array_expr_list ']'

array_expr_list:
  array_expr
| array_expr_list ',' array_expr

extract_list:
  extract_arg FROM a_expr
| expr_list



extract_arg:
  IDENT
| YEAR
| MONTH
| DAY
| HOUR
| MINUTE
| SECOND
| SCONST






overlay_list:
  a_expr overlay_placing substr_from substr_for
| a_expr overlay_placing substr_from
| expr_list

overlay_placing:
  PLACING a_expr


position_list:
  b_expr IN b_expr
| 












substr_list:
  a_expr substr_from substr_for
| a_expr substr_for substr_from
| a_expr substr_from
| a_expr substr_for
| opt_expr_list

substr_from:
  FROM a_expr

substr_for:
  FOR a_expr

trim_list:
  a_expr FROM expr_list
| FROM expr_list
| expr_list

in_expr:
  select_with_parens
| expr_tuple1_ambiguous






case_expr:
  CASE case_arg when_clause_list case_default END

when_clause_list:
  
  when_clause
| when_clause_list when_clause

when_clause:
  WHEN a_expr THEN a_expr

case_default:
  ELSE a_expr
| 

case_arg:
  a_expr
| 

array_subscript:
  '[' a_expr ']'
| '[' opt_slice_bound ':' opt_slice_bound ']'

opt_slice_bound:
  a_expr
| 

array_subscripts:
  array_subscript
| array_subscripts array_subscript

opt_asymmetric:
  ASYMMETRIC 
|  

target_list:
  target_elem
| target_list ',' target_elem

target_elem:
  a_expr AS target_name
  
  
  
  
  
| a_expr IDENT
| a_expr
| '*'



table_index_name_list:
  table_index_name
| table_index_name_list ',' table_index_name

table_pattern_list:
  table_pattern
| table_pattern_list ',' table_pattern














table_index_name:
  table_name '@' index_name
| standalone_index_name











table_pattern:
  simple_db_object_name
| complex_table_pattern



complex_table_pattern:
  complex_db_object_name
| db_object_name_component '.' unrestricted_name '.' '*'
| db_object_name_component '.' '*'
| '*'

name_list:
  name
| name_list ',' name


numeric_only:
  signed_iconst
| signed_fconst

signed_iconst:
  ICONST
| only_signed_iconst

only_signed_iconst:
  '+' ICONST
| '-' ICONST

signed_fconst:
  FCONST
| only_signed_fconst

only_signed_fconst:
  '+' FCONST
| '-' FCONST


iconst32:
  ICONST




signed_iconst64:
  signed_iconst


iconst64:
  ICONST

interval_value:
  INTERVAL SCONST opt_interval_qualifier
| INTERVAL '(' iconst32 ')' SCONST































collation_name:        unrestricted_name

partition_name:        unrestricted_name

index_name:            unrestricted_name

opt_index_name:        opt_name

zone_name:             unrestricted_name

target_name:           unrestricted_name

constraint_name:       name

database_name:         name

column_name:           name

family_name:           name

opt_family_name:       opt_name

table_alias_name:      name

statistics_name:       name

window_name:           name

view_name:             table_name

type_name:             db_object_name

sequence_name:         db_object_name

region_name:           name

region_name_list:      name_list

schema_name:           name

qualifiable_schema_name:
	name
| name '.' name

schema_name_list:
  qualifiable_schema_name
| schema_name_list ',' qualifiable_schema_name


opt_schema_name:
	qualifiable_schema_name
| 

table_name:            db_object_name

db_name:               db_object_name

standalone_index_name: db_object_name

explain_option_name:   non_reserved_word

cursor_name:           name












column_path:
  name
| prefixed_column_path

prefixed_column_path:
  db_object_name_component '.' unrestricted_name
| db_object_name_component '.' unrestricted_name '.' unrestricted_name
| db_object_name_component '.' unrestricted_name '.' unrestricted_name '.' unrestricted_name








column_path_with_star:
  column_path
| db_object_name_component '.' unrestricted_name '.' unrestricted_name '.' '*'
| db_object_name_component '.' unrestricted_name '.' '*'
| db_object_name_component '.' '*'








func_name:
  type_function_name
| prefixed_column_path



func_name_no_crdb_extra:
  type_function_name_no_crdb_extra
| prefixed_column_path






db_object_name:
  simple_db_object_name
| complex_db_object_name



simple_db_object_name:
  db_object_name_component





complex_db_object_name:
  db_object_name_component '.' unrestricted_name
| db_object_name_component '.' unrestricted_name '.' unrestricted_name





db_object_name_component:
  name
| type_func_name_crdb_extra_keyword
| cockroachdb_extra_reserved_keyword


name:
  IDENT
| unreserved_keyword
| col_name_keyword

opt_name:
  name
| 

opt_name_parens:
  '(' name ')'
| 




non_reserved_word_or_sconst:
  non_reserved_word
| SCONST


type_function_name:
  IDENT
| unreserved_keyword
| type_func_name_keyword


type_function_name_no_crdb_extra:
  IDENT
| unreserved_keyword
| type_func_name_no_crdb_extra_keyword


non_reserved_word:
  IDENT
| unreserved_keyword
| col_name_keyword
| type_func_name_keyword




unrestricted_name:
  IDENT
| unreserved_keyword
| col_name_keyword
| type_func_name_keyword
| reserved_keyword









unreserved_keyword:
  ABORT
| ABSOLUTE
| ACTION
| ACCESS
| ADD
| ADMIN
| AFTER
| AGGREGATE
| ALTER
| ALWAYS
| ASENSITIVE
| AT
| ATTRIBUTE
| AUTOMATIC
| AVAILABILITY
| BACKUP
| BACKUPS
| BACKWARD
| BEFORE
| BEGIN
| BINARY
| BUCKET_COUNT
| BUNDLE
| BY
| CACHE
| CANCEL
| CANCELQUERY
| CASCADE
| CHANGEFEED
| CLOSE
| CLUSTER
| COLUMNS
| COMMENT
| COMMENTS
| COMMIT
| COMMITTED
| COMPACT
| COMPLETE
| COMPLETIONS
| CONFLICT
| CONFIGURATION
| CONFIGURATIONS
| CONFIGURE
| CONNECTION
| CONSTRAINTS
| CONTROLCHANGEFEED
| CONTROLJOB
| CONVERSION
| CONVERT
| COPY
| COVERING
| CREATEDB
| CREATELOGIN
| CREATEROLE
| CSV
| CUBE
| CURRENT
| CURSOR
| CYCLE
| DATA
| DATABASE
| DATABASES
| DAY
| DEALLOCATE
| DEBUG_PAUSE_ON
| DECLARE
| DELETE
| DEFAULTS
| DEFERRED
| DELIMITER
| DESTINATION
| DETACHED
| DISCARD
| DOMAIN
| DOUBLE
| DROP
| ENCODING
| ENCRYPTED
| ENCRYPTION_PASSPHRASE
| ENUM
| ENUMS
| ESCAPE
| EXCLUDE
| EXCLUDING
| EXECUTE
| EXECUTION
| EXPERIMENTAL
| EXPERIMENTAL_AUDIT
| EXPERIMENTAL_FINGERPRINTS
| EXPERIMENTAL_RELOCATE
| EXPERIMENTAL_REPLICA
| EXPIRATION
| EXPLAIN
| EXPORT
| EXTENSION
| FAILURE
| FILES
| FILTER
| FIRST
| FOLLOWING
| FORCE
| FORCE_INDEX
| FORCE_ZIGZAG
| FORWARD
| FREEZE
| FUNCTION
| FUNCTIONS
| GENERATED
| GEOMETRYM
| GEOMETRYZ
| GEOMETRYZM
| GEOMETRYCOLLECTION
| GEOMETRYCOLLECTIONM
| GEOMETRYCOLLECTIONZ
| GEOMETRYCOLLECTIONZM
| GLOBAL
| GOAL
| GRANTS
| GROUPS
| HASH
| HEADER
| HIGH
| HISTOGRAM
| HOLD
| HOUR
| IDENTITY
| IMMEDIATE
| IMPORT
| INCLUDE
| INCLUDING
| INCREMENT
| INCREMENTAL
| INCREMENTAL_LOCATION
| INDEXES
| INHERITS
| INJECT
| INSERT
| INTO_DB
| INVERTED
| ISOLATION
| JOB
| JOBS
| JSON
| KEY
| KEYS
| KMS
| KV
| LANGUAGE
| LAST
| LATEST
| LC_COLLATE
| LC_CTYPE
| LEASE
| LESS
| LEVEL
| LINESTRING
| LINESTRINGM
| LINESTRINGZ
| LINESTRINGZM
| LIST
| LOCAL
| LOCKED
| LOGIN
| LOCALITY
| LOOKUP
| LOW
| MATCH
| MATERIALIZED
| MAXVALUE
| MERGE
| METHOD
| MINUTE
| MINVALUE
| MODIFYCLUSTERSETTING
| MULTILINESTRING
| MULTILINESTRINGM
| MULTILINESTRINGZ
| MULTILINESTRINGZM
| MULTIPOINT
| MULTIPOINTM
| MULTIPOINTZ
| MULTIPOINTZM
| MULTIPOLYGON
| MULTIPOLYGONM
| MULTIPOLYGONZ
| MULTIPOLYGONZM
| MONTH
| MOVE
| NAMES
| NAN
| NEVER
| NEW_DB_NAME
| NEW_KMS
| NEXT
| NO
| NORMAL
| NO_INDEX_JOIN
| NO_ZIGZAG_JOIN
| NO_FULL_SCAN
| NOCREATEDB
| NOCREATELOGIN
| NOCANCELQUERY
| NOCREATEROLE
| NOCONTROLCHANGEFEED
| NOCONTROLJOB
| NOLOGIN
| NOMODIFYCLUSTERSETTING
| NONVOTERS
| NOSQLLOGIN
| NOVIEWACTIVITY
| NOVIEWACTIVITYREDACTED
| NOVIEWCLUSTERSETTING
| NOWAIT
| NULLS
| IGNORE_FOREIGN_KEYS
| INSENSITIVE
| OF
| OFF
| OIDS
| OLD_KMS
| OPERATOR
| OPT
| OPTION
| OPTIONS
| ORDINALITY
| OTHERS
| OVER
| OWNED
| OWNER
| PARENT
| PARTIAL
| PARTITION
| PARTITIONS
| PASSWORD
| PAUSE
| PAUSED
| PHYSICAL
| PLACEMENT
| PLAN
| PLANS
| POINTM
| POINTZ
| POINTZM
| POLYGONM
| POLYGONZ
| POLYGONZM
| PRECEDING
| PREPARE
| PRESERVE
| PRIOR
| PRIORITY
| PRIVILEGES
| PUBLIC
| PUBLICATION
| QUERIES
| QUERY
| QUOTE
| RANGE
| RANGES
| READ
| REASON
| REASSIGN
| RECURRING
| RECURSIVE
| REF
| REFRESH
| REGION
| REGIONAL
| REGIONS
| REINDEX
| RELATIVE
| RELEASE
| RELOCATE
| RENAME
| REPEATABLE
| REPLACE
| REPLICATION
| RESET
| RESTORE
| RESTRICT
| RESTRICTED
| RESUME
| RETRY
| REVISION_HISTORY
| REVOKE
| ROLE
| ROLES
| ROLLBACK
| ROLLUP
| ROUTINES
| ROWS
| RULE
| RUNNING
| SCHEDULE
| SCHEDULES
| SCROLL
| SETTING
| SETTINGS
| STATUS
| SAVEPOINT
| SCANS
| SCATTER
| SCHEMA
| SCHEMAS
| SCRUB
| SEARCH
| SECOND
| SERIALIZABLE
| SEQUENCE
| SEQUENCES
| SERVER
| SESSION
| SESSIONS
| SET
| SETS
| SHARE
| SHOW
| SIMPLE
| SKIP
| SKIP_LOCALITIES_CHECK
| SKIP_MISSING_FOREIGN_KEYS
| SKIP_MISSING_SEQUENCES
| SKIP_MISSING_SEQUENCE_OWNERS
| SKIP_MISSING_VIEWS
| SNAPSHOT
| SPLIT
| SQL
| SQLLOGIN
| START
| STATE
| STATEMENTS
| STATISTICS
| STDIN
| STORAGE
| STORE
| STORED
| STORING
| STREAM
| STRICT
| SUBSCRIPTION
| SUPER
| SURVIVE
| SURVIVAL
| SYNTAX
| SYSTEM
| TABLES
| TABLESPACE
| TEMP
| TEMPLATE
| TEMPORARY
| TENANT
| TESTING_RELOCATE
| TEXT
| TIES
| TRACE
| TRACING
| TRANSACTION
| TRANSACTIONS
| TRANSFER
| TRIGGER
| TRUNCATE
| TRUSTED
| TYPE
| TYPES
| THROTTLING
| UNBOUNDED
| UNCOMMITTED
| UNKNOWN
| UNLOGGED
| UNSET
| UNSPLIT
| UNTIL
| UPDATE
| UPSERT
| USE
| USERS
| VALID
| VALIDATE
| VALUE
| VARYING
| VIEW
| VIEWACTIVITY
| VIEWACTIVITYREDACTED
| VIEWCLUSTERSETTING
| VISIBLE
| VOTERS
| WITHIN
| WITHOUT
| WRITE
| YEAR
| ZONE










col_name_keyword:
  ANNOTATE_TYPE
| BETWEEN
| BIGINT
| BIT
| BOOLEAN
| BOX2D
| CHAR
| CHARACTER
| CHARACTERISTICS
| COALESCE
| DEC
| DECIMAL
| EXISTS
| EXTRACT
| EXTRACT_DURATION
| FLOAT
| GEOGRAPHY
| GEOMETRY
| GREATEST
| GROUPING
| IF
| IFERROR
| IFNULL
| INT
| INTEGER
| INTERVAL
| ISERROR
| LEAST
| NULLIF
| NUMERIC
| OUT
| OVERLAY
| POINT
| POLYGON
| POSITION
| PRECISION
| REAL
| ROW
| SMALLINT
| STRING
| SUBSTRING
| TIME
| TIMETZ
| TIMESTAMP
| TIMESTAMPTZ
| TREAT
| TRIM
| VALUES
| VARBIT
| VARCHAR
| VIRTUAL
| WORK



type_func_name_keyword:
  type_func_name_no_crdb_extra_keyword
| type_func_name_crdb_extra_keyword














type_func_name_no_crdb_extra_keyword:
  AUTHORIZATION
| COLLATION
| CROSS
| FULL
| INNER
| ILIKE
| IS
| ISNULL
| JOIN
| LEFT
| LIKE
| NATURAL
| NONE
| NOTNULL
| OUTER
| OVERLAPS
| RIGHT
| SIMILAR









type_func_name_crdb_extra_keyword:
  FAMILY










reserved_keyword:
  ALL
| ANALYSE
| ANALYZE
| AND
| ANY
| ARRAY
| AS
| ASC
| ASYMMETRIC
| BOTH
| CASE
| CAST
| CHECK
| COLLATE
| COLUMN
| CONCURRENTLY
| CONSTRAINT
| CREATE
| CURRENT_CATALOG
| CURRENT_DATE
| CURRENT_ROLE
| CURRENT_SCHEMA
| CURRENT_TIME
| CURRENT_TIMESTAMP
| CURRENT_USER
| DEFAULT
| DEFERRABLE
| DESC
| DISTINCT
| DO
| ELSE
| END
| EXCEPT
| FALSE
| FETCH
| FOR
| FOREIGN
| FROM
| GRANT
| GROUP
| HAVING
| IN
| INITIALLY
| INTERSECT
| INTO
| LATERAL
| LEADING
| LIMIT
| LOCALTIME
| LOCALTIMESTAMP
| NOT
| NULL
| OFFSET
| ON
| ONLY
| OR
| ORDER
| PLACING
| PRIMARY
| REFERENCES
| RETURNING
| SELECT
| SESSION_USER
| SOME
| SYMMETRIC
| TABLE
| THEN
| TO
| TRAILING
| TRUE
| UNION
| UNIQUE
| USER
| USING
| VARIADIC
| WHEN
| WHERE
| WINDOW
| WITH
| cockroachdb_extra_reserved_keyword








cockroachdb_extra_reserved_keyword:
  INDEX
| NOTHING

