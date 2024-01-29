package rsgGenerator

import (
	"fmt"
	"github.com/rsg/yacc"
)

func GenerateMySQL(r RSGInterface, root string, rootPathNode *PathNode, parentHash uint32, depth int, rootDepth int) []string {

	//fmt.Printf("\n\n\nLooking for root: %s, depth: %d\n\n\n", root, depth)
	replayingMode := false
	isChooseCompRule := false
	isFavPathNode := false

	if rootPathNode == nil {
		fmt.Printf("\n\n\nError: rootPathNode is nil. \n\n\n")
		// Return nil is different from return an empty array.
		// Return nil represent error.
		return nil
	}

	// Initialize to an empty slice instead of nil because nil means error.
	ret := make([]string, 0)

	if root == "shutdown_stmt" || root == "drop_database_stmt" ||
		root == "alter_database_stmt" || root == "alter_user_stmt" ||
		root == "set_role_stmt" || root == "revoke" || root == "grant" ||
		root == "drop_user_stmt" || root == "set" {
		return ret
	}

	//fmt.Printf("\n\n\n From root: %s, getting allProds size: %d \n\n\n", root, len(allProds))
	var curChosenRule *yacc.ExpressionNode
	if rootPathNode.ExprProds == nil {
		// Not in the replaying mode, choose one node using MABChooseARM and proceed.
		//fmt.Printf("\n\n\nLooking for root: %s, depth: %d\n\n\n", root, depth)
		replayingMode = false

		curRuleSet := r.PrioritizeParserRules(root, parentHash, depth)

		curChosenRule = r.MABChooseArm(curRuleSet)

		// Mark the current parent to child rule as triggered.
		r.MarkEdgeCov(parentHash, curChosenRule.UniqueHash)

		// Check whether all rules in the current root keyword is triggered.
		// If not all are triggered, set is isFav = true
		isFavPathNode = r.CheckIsFav(root, parentHash)

		isChooseCompRule = r.IsInCompProds(root, curChosenRule)

		rootPathNode.ExprProds = curChosenRule
		rootPathNode.Children = []*PathNode{}
	} else {
		// Replay mode, directly reuse the previous chosen rule.
		//fmt.Printf("\n\n\nReplaying mode: Looking for root: %s, depth: %d\n\n\n", root, depth)
		replayingMode = true
		curChosenRule = rootPathNode.ExprProds
	}

	if curChosenRule == nil {
		fmt.Printf("\n\n\nERROR: getting nil curChosenRule. \n\n\n")
		return nil
	}

	rootHash := curChosenRule.UniqueHash

	replayExprIdx := 0
	for _, item := range curChosenRule.Items {
		switch item.Typ {
		case yacc.TypLiteral:
			v := item.Value[1 : len(item.Value)-1]
			ret = append(ret, v)
			continue
		case yacc.TypToken:
			//fmt.Printf("Getting prod.Items: %s\n", item.Value)

			var v []string

			tokenStr := item.Value

			if depth < 0 {
				if tokenStr == "expr" {
					ret = append(ret, " TRUE ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				} else if tokenStr == "subquery" {
					ret = append(ret, " (select 'abc') ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				} else if tokenStr == "table_factor" {
					ret = append(ret, " v0 ")
					rootPathNode.ExprProds = nil
					rootPathNode.Children = []*PathNode{}
					continue
				}
			}

			switch tokenStr {
			case "ident":
				v = []string{" v0 "}
			case "TEXT_STRING":
				v = []string{" 'abc' "}
			case "NUM":
				fallthrough
			case "LONG_NUM":
				fallthrough
			case "ULONGLONG_NUM":
				fallthrough
			case "DECIMAL_NUM":
				v = []string{" 100 "}
			case "HEX_NUM":
				v = []string{" 0x100 "}
			case "FLOAT_NUM":
				v = []string{" 100.0 "}
			case "END_OF_INPUT":
				v = []string{""}
			case "NOT2_SYM":
				v = []string{" NOT "}
			case "NEG":
				v = []string{" - "}
			case "OR2_SYM":
				v = []string{" OR "}
			case "NOW":
				v = []string{" CURRENT_TIMESTAMP "}
			case "AND_AND_SYM":
				v = []string{" && "}
			case "LT":
				v = []string{" < "}
			case "LE":
				v = []string{" <= "}
			case "NE":
				v = []string{" != "}
			case "EQ":
				v = []string{" = "}
			case "GT_SYM":
				v = []string{" > "}
			case "GE":
				v = []string{" >= "}
			case "SHIFT_LEFT":
				v = []string{" << "}
			case "SHIFT_RIGHT":
				v = []string{" >> "}
			case "EQUAL_SYM":
				v = []string{" <=> "}
			case "ACCESSIBLE_SYM":
				v = []string{" ACCESSIBLE "}
			case "ACCOUNT_SYM":
				v = []string{" ACCOUNT "}
			case "ACTION":
				v = []string{" ACTION "}
			case "ACTIVE_SYM":
				v = []string{" ACTIVE "}
			case "ADD":
				v = []string{" ADD "}
			case "ADMIN_SYM":
				v = []string{" ADMIN "}
			case "AFTER_SYM":
				v = []string{" AFTER "}
			case "AGAINST":
				v = []string{" AGAINST "}
			case "AGGREGATE_SYM":
				v = []string{" AGGREGATE "}
			case "ALL":
				v = []string{" ALL "}
			case "ALGORITHM_SYM":
				v = []string{" ALGORITHM "}
			case "ALTER":
				v = []string{" ALTER "}
			case "ALWAYS_SYM":
				v = []string{" ALWAYS "}
			case "ANALYZE_SYM":
				v = []string{" ANALYZE "}
			case "AND_SYM":
				v = []string{" AND "}
			case "ANY_SYM":
				if r.Intn(2) == 0 {
					v = []string{" ANY "}
				} else {
					v = []string{" SOME "}
				}
			case "ARRAY_SYM":
				v = []string{" ARRAY "}
			case "AS":
				v = []string{" AS "}
			case "ASC":
				v = []string{" ASC "}
			case "ASCII_SYM":
				v = []string{" ASCII "}
			case "ASENSITIVE_SYM":
				v = []string{" ASENSITIVE "}
			case "AT_SYM":
				v = []string{" AT "}
			case "ATTRIBUTE_SYM":
				v = []string{" ATTRIBUTE "}
			case "AUTHENTICATION_SYM":
				v = []string{" AUTHENTICATION "}
			case "AUTO_INC":
				v = []string{" AUTO_INCREMENT "}
			case "AUTOEXTEND_SIZE_SYM":
				v = []string{" AUTOEXTEND_SIZE "}
			case "AVG_SYM":
				v = []string{" AVG "}
			case "AVG_ROW_LENGTH":
				v = []string{" AVG_ROW_LENGTH "}
			case "BACKUP_SYM":
				v = []string{" BACKUP "}
			case "BEFORE_SYM":
				v = []string{" BEFORE "}
			case "BEGIN_SYM":
				v = []string{" BEGIN "}
			case "BETWEEN_SYM":
				v = []string{" BETWEEN "}
			case "BIGINT_SYM":
				v = []string{" BIGINT "}
			case "BINARY_SYM":
				v = []string{" BINARY "}
			case "BINLOG_SYM":
				v = []string{" BINLOG "}
			case "BIT_SYM":
				v = []string{" BIT "}
			case "BLOB_SYM":
				v = []string{" BLOB "}
			case "BLOCK_SYM":
				v = []string{" BLOCK "}
			case "BOOL_SYM":
				v = []string{" BOOL "}
			case "BOOLEAN_SYM":
				v = []string{" BOOLEAN "}
			case "BOTH":
				v = []string{" BOTH "}
			case "BTREE_SYM":
				v = []string{" BTREE "}
			case "BUCKETS_SYM":
				v = []string{" BUCKETS "}
			case "BY":
				v = []string{" BY "}
			case "BYTE_SYM":
				v = []string{" BYTE "}
			case "CACHE_SYM":
				v = []string{" CACHE "}
			case "CALL_SYM":
				v = []string{" CALL "}
			case "CASCADE":
				v = []string{" CASCADE "}
			case "CASCADED":
				v = []string{" CASCADED "}
			case "CASE_SYM":
				v = []string{" CASE "}
			case "CATALOG_NAME_SYM":
				v = []string{" CATALOG_NAME "}
			case "CHAIN_SYM":
				v = []string{" CHAIN "}
			case "CHALLENGE_RESPONSE_SYM":
				v = []string{" CHALLENGE_RESPONSE "}
			case "CHANGE":
				v = []string{" CHANGE "}
			case "CHANGED":
				v = []string{" CHANGED "}
			case "CHANNEL_SYM":
				v = []string{" CHANNEL "}
			case "CHAR_SYM":
				v = []string{" CHAR "}
			case "CHARSET":
				v = []string{" CHARSET "}
			case "CHECK_SYM":
				v = []string{" CHECK "}
			case "CHECKSUM_SYM":
				v = []string{" CHECKSUM "}
			case "CIPHER_SYM":
				v = []string{" CIPHER "}
			case "CLASS_ORIGIN_SYM":
				v = []string{" CLASS_ORIGIN "}
			case "CLIENT_SYM":
				v = []string{" CLIENT "}
			case "CLONE_SYM":
				v = []string{" CLONE "}
			case "CLOSE_SYM":
				v = []string{" CLOSE "}
			case "COALESCE":
				v = []string{" COALESCE "}
			case "CODE_SYM":
				v = []string{" CODE "}
			case "COLLATE_SYM":
				v = []string{" COLLATE "}
			case "COLLATION_SYM":
				v = []string{" COLLATION "}
			case "COLUMN_SYM":
				v = []string{" COLUMN "}
			case "COLUMN_FORMAT_SYM":
				v = []string{" COLUMN_FORMAT "}
			case "COLUMN_NAME_SYM":
				v = []string{" COLUMN_NAME "}
			case "COLUMNS":
				v = []string{" COLUMNS "}
			case "COMMENT_SYM":
				v = []string{" COMMENT "}
			case "COMMIT_SYM":
				v = []string{" COMMIT "}
			case "COMMITTED_SYM":
				v = []string{" COMMITTED "}
			case "COMPACT_SYM":
				v = []string{" COMPACT "}
			case "COMPLETION_SYM":
				v = []string{" COMPLETION "}
			case "COMPONENT_SYM":
				v = []string{" COMPONENT "}
			case "COMPRESSION_SYM":
				v = []string{" COMPRESSION "}
			case "COMPRESSED_SYM":
				v = []string{" COMPRESSED "}
			case "ENCRYPTION_SYM":
				v = []string{" ENCRYPTION "}
			case "CONCURRENT":
				v = []string{" CONCURRENT "}
			case "CONDITION_SYM":
				v = []string{" CONDITION "}
			case "CONNECTION_SYM":
				v = []string{" CONNECTION "}
			case "CONSISTENT_SYM":
				v = []string{" CONSISTENT "}
			case "CONSTRAINT":
				v = []string{" CONSTRAINT "}
			case "CONSTRAINT_CATALOG_SYM":
				v = []string{" CONSTRAINT_CATALOG "}
			case "CONSTRAINT_NAME_SYM":
				v = []string{" CONSTRAINT_NAME "}
			case "CONSTRAINT_SCHEMA_SYM":
				v = []string{" CONSTRAINT_SCHEMA "}
			case "CONTAINS_SYM":
				v = []string{" CONTAINS "}
			case "CONTEXT_SYM":
				v = []string{" CONTEXT "}
			case "CONTINUE_SYM":
				v = []string{" CONTINUE "}
			case "CONVERT_SYM":
				v = []string{" CONVERT "}
			case "CPU_SYM":
				v = []string{" CPU "}
			case "CREATE":
				v = []string{" CREATE "}
			case "CROSS":
				v = []string{" CROSS "}
			case "CUBE_SYM":
				v = []string{" CUBE "}
			case "CUME_DIST_SYM":
				v = []string{" CUME_DIST "}
			case "CURRENT_SYM":
				v = []string{" CURRENT "}
			case "CURDATE":
				v = []string{" CURRENT_DATE "}
			case "CURTIME":
				v = []string{" CURRENT_TIME "}
			case "NOW_SYM":
				v = []string{" CURRENT_TIMESTAMP "}
			case "CURRENT_USER":
				v = []string{" 'abc' "}
			case "CURSOR_SYM":
				v = []string{" CURSOR "}
			case "CURSOR_NAME_SYM":
				v = []string{" CURSOR_NAME "}
			case "DATA_SYM":
				v = []string{" DATA "}
			case "DATABASE":
				v = []string{" DATABASE "}
			case "DATABASES":
				v = []string{" DATABASES "}
			case "DATAFILE_SYM":
				v = []string{" DATAFILE "}
			case "DATE_SYM":
				v = []string{" DATE "}
			case "DATETIME_SYM":
				v = []string{" DATETIME "}
			case "DAY_SYM":
				v = []string{" DAY "}
			case "DAY_HOUR_SYM":
				v = []string{" DAY_HOUR "}
			case "DAY_MICROSECOND_SYM":
				v = []string{" DAY_MICROSECOND "}
			case "DAY_MINUTE_SYM":
				v = []string{" DAY_MINUTE "}
			case "DAY_SECOND_SYM":
				v = []string{" DAY_SECOND "}
			case "DEALLOCATE_SYM":
				v = []string{" DEALLOCATE "}
			case "DECIMAL_SYM":
				v = []string{" DECIMAL "}
			case "DECLARE_SYM":
				v = []string{" DECLARE "}
			case "DEFAULT_SYM":
				v = []string{" DEFAULT "}
			case "DEFAULT_AUTH_SYM":
				v = []string{" DEFAULT_AUTH "}
			case "DEFINER_SYM":
				v = []string{" DEFINER "}
			case "DEFINITION_SYM":
				v = []string{" DEFINITION "}
			case "DELAYED_SYM":
				v = []string{" DELAYED "}
			case "DELAY_KEY_WRITE_SYM":
				v = []string{" DELAY_KEY_WRITE "}
			case "DENSE_RANK_SYM":
				v = []string{" DENSE_RANK "}
			case "DESC":
				v = []string{" DESC "}
			case "DESCRIPTION_SYM":
				v = []string{" DESCRIPTION "}
			case "DETERMINISTIC_SYM":
				v = []string{" DETERMINISTIC "}
			case "DIAGNOSTICS_SYM":
				v = []string{" DIAGNOSTICS "}
			case "DIRECTORY_SYM":
				v = []string{" DIRECTORY "}
			case "DISABLE_SYM":
				v = []string{" DISABLE "}
			case "DISCARD_SYM":
				v = []string{" DISCARD "}
			case "DISK_SYM":
				v = []string{" DISK "}
			case "DISTINCT":
				v = []string{" DISTINCT "}
			case "DISTINCT /* Access likes this */":
				v = []string{" DISTINCTROW "}
			case "DIV_SYM":
				v = []string{" DIV "}
			case "DO_SYM":
				v = []string{" DO "}
			case "DOUBLE_SYM":
				v = []string{" DOUBLE "}
			case "DROP":
				v = []string{" DROP "}
			case "DUAL_SYM":
				v = []string{" DUAL "}
			case "DUMPFILE":
				v = []string{" DUMPFILE "}
			case "DUPLICATE_SYM":
				v = []string{" DUPLICATE "}
			case "DYNAMIC_SYM":
				v = []string{" DYNAMIC "}
			case "EACH_SYM":
				v = []string{" EACH "}
			case "ELSE":
				v = []string{" ELSE "}
			case "ELSEIF_SYM":
				v = []string{" ELSEIF "}
			case "EMPTY_SYM":
				v = []string{" EMPTY "}
			case "ENABLE_SYM":
				v = []string{" ENABLE "}
			case "ENCLOSED":
				v = []string{" ENCLOSED "}
			case "END":
				v = []string{" END "}
			case "ENDS_SYM":
				v = []string{" ENDS "}
			case "ENFORCED_SYM":
				v = []string{" ENFORCED "}
			case "ENGINE_SYM":
				v = []string{" ENGINE "}
			case "ENGINE_ATTRIBUTE_SYM":
				v = []string{" ENGINE_ATTRIBUTE "}
			case "ENGINES_SYM":
				v = []string{" ENGINES "}
			case "ENUM_SYM":
				v = []string{" ENUM "}
			case "ERROR_SYM":
				v = []string{" ERROR "}
			case "ERRORS":
				v = []string{" ERRORS "}
			case "ESCAPE_SYM":
				v = []string{" ESCAPE "}
			case "ESCAPED":
				v = []string{" ESCAPED "}
			case "EVENT_SYM":
				v = []string{" EVENT "}
			case "EVENTS_SYM":
				v = []string{" EVENTS "}
			case "EVERY_SYM":
				v = []string{" EVERY "}
			case "EXCEPT_SYM":
				v = []string{" EXCEPT "}
			case "EXCHANGE_SYM":
				v = []string{" EXCHANGE "}
			case "EXCLUDE_SYM":
				v = []string{" EXCLUDE "}
			case "EXECUTE_SYM":
				v = []string{" EXECUTE "}
			case "EXISTS":
				v = []string{" EXISTS "}
			case "EXIT_SYM":
				v = []string{" EXIT "}
			case "EXPANSION_SYM":
				v = []string{" EXPANSION "}
			case "EXPORT_SYM":
				v = []string{" EXPORT "}
			case "EXPIRE_SYM":
				v = []string{" EXPIRE "}
			case "DESCRIBE":
				v = []string{" EXPLAIN "}
			case "EXTENDED_SYM":
				v = []string{" EXTENDED "}
			case "EXTENT_SIZE_SYM":
				v = []string{" EXTENT_SIZE "}
			case "FACTOR_SYM":
				v = []string{" FACTOR "}
			case "FAILED_LOGIN_ATTEMPTS_SYM":
				v = []string{" FAILED_LOGIN_ATTEMPTS "}
			case "FALSE_SYM":
				v = []string{" FALSE "}
			case "FAST_SYM":
				v = []string{" FAST "}
			case "FAULTS_SYM":
				v = []string{" FAULTS "}
			case "FETCH_SYM":
				v = []string{" FETCH "}
			case "FILE_SYM":
				v = []string{" FILE "}
			case "FILE_BLOCK_SIZE_SYM":
				v = []string{" FILE_BLOCK_SIZE "}
			case "FILTER_SYM":
				v = []string{" FILTER "}
			case "FINISH_SYM":
				v = []string{" FINISH "}
			case "FIRST_SYM":
				v = []string{" FIRST "}
			case "FIRST_VALUE_SYM":
				v = []string{" FIRST_VALUE "}
			case "FIXED_SYM":
				v = []string{" FIXED "}
			case "FLOAT_SYM":
				v = []string{" FLOAT "}
			case "FLUSH_SYM":
				v = []string{" FLUSH "}
			case "FOLLOWS_SYM":
				v = []string{" FOLLOWS "}
			case "FOLLOWING_SYM":
				v = []string{" FOLLOWING "}
			case "FOR_SYM":
				v = []string{" FOR "}
			case "FORCE_SYM":
				v = []string{" FORCE "}
			case "FOREIGN":
				v = []string{" FOREIGN "}
			case "FORMAT_SYM":
				v = []string{" FORMAT "}
			case "FOUND_SYM":
				v = []string{" FOUND "}
			case "FROM":
				v = []string{" FROM "}
			case "FULL":
				v = []string{" FULL "}
			case "FULLTEXT_SYM":
				v = []string{" FULLTEXT "}
			case "FUNCTION_SYM":
				v = []string{" FUNCTION "}
			case "GENERAL":
				v = []string{" GENERAL "}
			case "GROUP_REPLICATION":
				v = []string{" GROUP_REPLICATION "}
			case "GEOMETRYCOLLECTION_SYM":
				v = []string{" GEOMCOLLECTION "}
			case "GEOMETRY_SYM":
				v = []string{" GEOMETRY "}
			case "GET_FORMAT":
				v = []string{" GET_FORMAT "}
			case "GET_MASTER_PUBLIC_KEY_SYM":
				v = []string{" GET_MASTER_PUBLIC_KEY "}
			case "GET_SOURCE_PUBLIC_KEY_SYM":
				v = []string{" GET_SOURCE_PUBLIC_KEY "}
			case "GET_SYM":
				v = []string{" GET "}
			case "GENERATED":
				v = []string{" GENERATED "}
			case "GLOBAL_SYM":
				v = []string{" GLOBAL "}
			case "GRANT":
				v = []string{" GRANT "}
			case "GRANTS":
				v = []string{" GRANTS "}
			case "GROUP_SYM":
				v = []string{" GROUP "}
			case "GROUPING_SYM":
				v = []string{" GROUPING "}
			case "GROUPS_SYM":
				v = []string{" GROUPS "}
			case "GTID_ONLY_SYM":
				v = []string{" GTID_ONLY "}
			case "HANDLER_SYM":
				v = []string{" HANDLER "}
			case "HASH_SYM":
				v = []string{" HASH "}
			case "HAVING":
				v = []string{" HAVING "}
			case "HELP_SYM":
				v = []string{" HELP "}
			case "HIGH_PRIORITY":
				v = []string{" HIGH_PRIORITY "}
			case "HISTOGRAM_SYM":
				v = []string{" HISTOGRAM "}
			case "HISTORY_SYM":
				v = []string{" HISTORY "}
			case "HOST_SYM":
				v = []string{" HOST "}
			case "HOSTS_SYM":
				v = []string{" HOSTS "}
			case "HOUR_SYM":
				v = []string{" HOUR "}
			case "HOUR_MICROSECOND_SYM":
				v = []string{" HOUR_MICROSECOND "}
			case "HOUR_MINUTE_SYM":
				v = []string{" HOUR_MINUTE "}
			case "HOUR_SECOND_SYM":
				v = []string{" HOUR_SECOND "}
			case "IDENTIFIED_SYM":
				v = []string{" IDENTIFIED "}
			case "IF":
				v = []string{" IF "}
			case "IGNORE_SYM":
				v = []string{" IGNORE "}
			case "IGNORE_SERVER_IDS_SYM":
				v = []string{" IGNORE_SERVER_IDS "}
			case "IMPORT":
				v = []string{" IMPORT "}
			case "IN_SYM":
				v = []string{" IN "}
			case "INACTIVE_SYM":
				v = []string{" INACTIVE "}
			case "INDEX_SYM":
				v = []string{" INDEX "}
			case "INDEXES":
				v = []string{" INDEXES "}
			case "INFILE":
				v = []string{" INFILE "}
			case "INITIAL_SYM":
				v = []string{" INITIAL "}
			case "INITIAL_SIZE_SYM":
				v = []string{" INITIAL_SIZE "}
			case "INITIATE_SYM":
				v = []string{" INITIATE "}
			case "INNER_SYM":
				v = []string{" INNER "}
			case "INOUT_SYM":
				v = []string{" INOUT "}
			case "INSENSITIVE_SYM":
				v = []string{" INSENSITIVE "}
			case "INSERT_METHOD":
				v = []string{" INSERT_METHOD "}
			case "INSTALL_SYM":
				v = []string{" INSTALL "}
			case "INSTANCE_SYM":
				v = []string{" INSTANCE "}
			case "INT_SYM":
				v = []string{" INT "}
			case "INTERVAL_SYM":
				v = []string{" INTERVAL "}
			case "INTO":
				v = []string{" INTO "}
			case "IO_SYM":
				v = []string{" IO "}
			case "IO_AFTER_GTIDS":
				v = []string{" IO_AFTER_GTIDS "}
			case "IO_BEFORE_GTIDS":
				v = []string{" IO_BEFORE_GTIDS "}
			case "RELAY_THREAD":
				if r.Intn(2) == 0 {
					v = []string{" IO_THREAD "}
				} else {
					v = []string{" RELAY_THREAD "}
				}
			case "IPC_SYM":
				v = []string{" IPC "}
			case "IS":
				v = []string{" IS "}
			case "ISOLATION":
				v = []string{" ISOLATION "}
			case "ISSUER_SYM":
				v = []string{" ISSUER "}
			case "ITERATE_SYM":
				v = []string{" ITERATE "}
			case "INVISIBLE_SYM":
				v = []string{" INVISIBLE "}
			case "INVOKER_SYM":
				v = []string{" INVOKER "}
			case "JOIN_SYM":
				v = []string{" JOIN "}
			case "JSON_SYM":
				v = []string{" JSON "}
			case "JSON_TABLE_SYM":
				v = []string{" JSON_TABLE "}
			case "JSON_VALUE_SYM":
				v = []string{" JSON_VALUE "}
			case "KEY_SYM":
				v = []string{" KEY "}
			case "KEYRING_SYM":
				v = []string{" KEYRING "}
			case "KEYS":
				v = []string{" KEYS "}
			case "KEY_BLOCK_SIZE":
				v = []string{" KEY_BLOCK_SIZE "}
			case "KILL_SYM":
				v = []string{" KILL "}
			case "LAG_SYM":
				v = []string{" LAG "}
			case "LANGUAGE_SYM":
				v = []string{" LANGUAGE "}
			case "LAST_SYM":
				v = []string{" LAST "}
			case "LAST_VALUE_SYM":
				v = []string{" LAST_VALUE "}
			case "LATERAL_SYM":
				v = []string{" LATERAL "}
			case "LEAD_SYM":
				v = []string{" LEAD "}
			case "LEADING":
				v = []string{" LEADING "}
			case "LEAVE_SYM":
				v = []string{" LEAVE "}
			case "LEAVES":
				v = []string{" LEAVES "}
			case "LEFT":
				v = []string{" LEFT "}
			case "LESS_SYM":
				v = []string{" LESS "}
			case "LEVEL_SYM":
				v = []string{" LEVEL "}
			case "LIKE":
				v = []string{" LIKE "}
			case "LIMIT":
				v = []string{" LIMIT "}
			case "LINEAR_SYM":
				v = []string{" LINEAR "}
			case "LINES":
				v = []string{" LINES "}
			case "LINESTRING_SYM":
				v = []string{" LINESTRING "}
			case "LIST_SYM":
				v = []string{" LIST "}
			case "LOAD":
				v = []string{" LOAD "}
			case "LOCAL_SYM":
				v = []string{" LOCAL "}
			case "LOCK_SYM":
				v = []string{" LOCK "}
			case "LOCKED_SYM":
				v = []string{" LOCKED "}
			case "LOCKS_SYM":
				v = []string{" LOCKS "}
			case "LOGFILE_SYM":
				v = []string{" LOGFILE "}
			case "LOGS_SYM":
				v = []string{" LOGS "}
			case "LONG_SYM":
				v = []string{" LONG "}
			case "LONGBLOB_SYM":
				v = []string{" LONGBLOB "}
			case "LONGTEXT_SYM":
				v = []string{" LONGTEXT "}
			case "LOOP_SYM":
				v = []string{" LOOP "}
			case "LOW_PRIORITY":
				v = []string{" LOW_PRIORITY "}
			case "MASTER_SYM":
				v = []string{" MASTER "}
			case "MASTER_AUTO_POSITION_SYM":
				v = []string{" MASTER_AUTO_POSITION "}
			case "MASTER_BIND_SYM":
				v = []string{" MASTER_BIND "}
			case "MASTER_CONNECT_RETRY_SYM":
				v = []string{" MASTER_CONNECT_RETRY "}
			case "MASTER_COMPRESSION_ALGORITHM_SYM":
				v = []string{" MASTER_COMPRESSION_ALGORITHMS "}
			case "MASTER_DELAY_SYM":
				v = []string{" MASTER_DELAY "}
			case "MASTER_HEARTBEAT_PERIOD_SYM":
				v = []string{" MASTER_HEARTBEAT_PERIOD "}
			case "MASTER_HOST_SYM":
				v = []string{" MASTER_HOST "}
			case "MASTER_LOG_FILE_SYM":
				v = []string{" MASTER_LOG_FILE "}
			case "MASTER_LOG_POS_SYM":
				v = []string{" MASTER_LOG_POS "}
			case "MASTER_PASSWORD_SYM":
				v = []string{" "}
			case "MASTER_PORT_SYM":
				v = []string{" MASTER_PORT "}
			case "MASTER_PUBLIC_KEY_PATH_SYM":
				v = []string{" MASTER_PUBLIC_KEY_PATH "}
			case "MASTER_RETRY_COUNT_SYM":
				v = []string{" MASTER_RETRY_COUNT "}
			case "MASTER_SSL_SYM":
				v = []string{" MASTER_SSL "}
			case "MASTER_SSL_CA_SYM":
				v = []string{" MASTER_SSL_CA "}
			case "MASTER_SSL_CAPATH_SYM":
				v = []string{" MASTER_SSL_CAPATH "}
			case "MASTER_SSL_CERT_SYM":
				v = []string{" MASTER_SSL_CERT "}
			case "MASTER_SSL_CIPHER_SYM":
				v = []string{" MASTER_SSL_CIPHER "}
			case "MASTER_SSL_CRL_SYM":
				v = []string{" MASTER_SSL_CRL "}
			case "MASTER_SSL_CRLPATH_SYM":
				v = []string{" MASTER_SSL_CRLPATH "}
			case "MASTER_SSL_KEY_SYM":
				v = []string{" MASTER_SSL_KEY "}
			case "MASTER_SSL_VERIFY_SERVER_CERT_SYM":
				v = []string{" MASTER_SSL_VERIFY_SERVER_CERT "}
			case "MASTER_TLS_CIPHERSUITES_SYM":
				v = []string{" MASTER_TLS_CIPHERSUITES "}
			case "MASTER_TLS_VERSION_SYM":
				v = []string{" MASTER_TLS_VERSION "}
			case "MASTER_USER_SYM":
				v = []string{" MASTER_USER "}
			case "MASTER_ZSTD_COMPRESSION_LEVEL_SYM":
				v = []string{" MASTER_ZSTD_COMPRESSION_LEVEL "}
			case "MATCH":
				v = []string{" MATCH "}
			case "MAX_CONNECTIONS_PER_HOUR":
				v = []string{" MAX_CONNECTIONS_PER_HOUR "}
			case "MAX_QUERIES_PER_HOUR":
				v = []string{" MAX_QUERIES_PER_HOUR "}
			case "MAX_ROWS":
				v = []string{" MAX_ROWS "}
			case "MAX_SIZE_SYM":
				v = []string{" MAX_SIZE "}
			case "MAX_UPDATES_PER_HOUR":
				v = []string{" MAX_UPDATES_PER_HOUR "}
			case "MAX_USER_CONNECTIONS_SYM":
				v = []string{" MAX_USER_CONNECTIONS "}
			case "MAX_VALUE_SYM":
				v = []string{" MAXVALUE "}
			case "MEDIUM_SYM":
				v = []string{" MEDIUM "}
			case "MEDIUMBLOB_SYM":
				v = []string{" MEDIUMBLOB "}
			case "MEDIUMINT_SYM":
				v = []string{" MEDIUMINT "}
			case "MEDIUMTEXT_SYM":
				v = []string{" MEDIUMTEXT "}
			case "MEMBER_SYM":
				v = []string{" MEMBER "}
			case "MEMORY_SYM":
				v = []string{" MEMORY "}
			case "MERGE_SYM":
				v = []string{" MERGE "}
			case "MESSAGE_TEXT_SYM":
				v = []string{" MESSAGE_TEXT "}
			case "MICROSECOND_SYM":
				v = []string{" MICROSECOND "}
			case "MIGRATE_SYM":
				v = []string{" MIGRATE "}
			case "MINUTE_SYM":
				v = []string{" MINUTE "}
			case "MINUTE_MICROSECOND_SYM":
				v = []string{" MINUTE_MICROSECOND "}
			case "MINUTE_SECOND_SYM":
				v = []string{" MINUTE_SECOND "}
			case "MIN_ROWS":
				v = []string{" MIN_ROWS "}
			case "MOD_SYM":
				v = []string{" MOD "}
			case "MODE_SYM":
				v = []string{" MODE "}
			case "MODIFIES_SYM":
				v = []string{" MODIFIES "}
			case "MODIFY_SYM":
				v = []string{" MODIFY "}
			case "MONTH_SYM":
				v = []string{" MONTH "}
			case "MULTILINESTRING_SYM":
				v = []string{" MULTILINESTRING "}
			case "MULTIPOINT_SYM":
				v = []string{" MULTIPOINT "}
			case "MULTIPOLYGON_SYM":
				v = []string{" MULTIPOLYGON "}
			case "MUTEX_SYM":
				v = []string{" MUTEX "}
			case "MYSQL_ERRNO_SYM":
				v = []string{" MYSQL_ERRNO "}
			case "NAME_SYM":
				v = []string{" NAME "}
			case "NAMES_SYM":
				v = []string{" NAMES "}
			case "NATIONAL_SYM":
				v = []string{" NATIONAL "}
			case "NATURAL":
				v = []string{" NATURAL "}
			case "NDBCLUSTER_SYM":
				v = []string{" NDB "}
			case "NCHAR_SYM":
				v = []string{" NCHAR "}
			case "NESTED_SYM":
				v = []string{" NESTED "}
			case "NETWORK_NAMESPACE_SYM":
				v = []string{" NETWORK_NAMESPACE "}
			case "NEVER_SYM":
				v = []string{" NEVER "}
			case "NEW_SYM":
				v = []string{" NEW "}
			case "NEXT_SYM":
				v = []string{" NEXT "}
			case "NO_SYM":
				v = []string{" NO "}
			case "NO_WAIT_SYM":
				v = []string{" NO_WAIT "}
			case "NOWAIT_SYM":
				v = []string{" NOWAIT "}
			case "NODEGROUP_SYM":
				v = []string{" NODEGROUP "}
			case "NONE_SYM":
				v = []string{" NONE "}
			case "NOT_SYM":
				v = []string{" NOT "}
			case "NO_WRITE_TO_BINLOG":
				v = []string{" NO_WRITE_TO_BINLOG "}
			case "NTH_VALUE_SYM":
				v = []string{" NTH_VALUE "}
			case "NTILE_SYM":
				v = []string{" NTILE "}
			case "NULL_SYM":
				v = []string{" NULL "}
			case "NULLS_SYM":
				v = []string{" NULLS "}
			case "NUMBER_SYM":
				v = []string{" NUMBER "}
			case "NUMERIC_SYM":
				v = []string{" NUMERIC "}
			case "NVARCHAR_SYM":
				v = []string{" NVARCHAR "}
			case "OF_SYM":
				v = []string{" OF "}
			case "OFF_SYM":
				v = []string{" OFF "}
			case "OFFSET_SYM":
				v = []string{" OFFSET "}
			case "OJ_SYM":
				v = []string{" OJ "}
			case "OLD_SYM":
				v = []string{" OLD "}
			case "ON_SYM":
				v = []string{" ON "}
			case "ONE_SYM":
				v = []string{" ONE "}
			case "ONLY_SYM":
				v = []string{" ONLY "}
			case "OPEN_SYM":
				v = []string{" OPEN "}
			case "OPTIMIZE":
				v = []string{" OPTIMIZE "}
			case "OPTIMIZER_COSTS_SYM":
				v = []string{" OPTIMIZER_COSTS "}
			case "OPTIONS_SYM":
				v = []string{" OPTIONS "}
			case "OPTION":
				v = []string{" OPTION "}
			case "OPTIONAL_SYM":
				v = []string{" OPTIONAL "}
			case "OPTIONALLY":
				v = []string{" OPTIONALLY "}
			case "OR_SYM":
				v = []string{" OR "}
			case "ORGANIZATION_SYM":
				v = []string{" ORGANIZATION "}
			case "OTHERS_SYM":
				v = []string{" OTHERS "}
			case "ORDER_SYM":
				v = []string{" ORDER "}
			case "ORDINALITY_SYM":
				v = []string{" ORDINALITY "}
			case "OUT_SYM":
				v = []string{" OUT "}
			case "OUTER_SYM":
				v = []string{" OUTER "}
			case "OUTFILE":
				v = []string{" OUTFILE "}
			case "OVER_SYM":
				v = []string{" OVER "}
			case "OWNER_SYM":
				v = []string{" OWNER "}
			case "PACK_KEYS_SYM":
				v = []string{" PACK_KEYS "}
			case "PATH_SYM":
				v = []string{" PATH "}
			case "PARSER_SYM":
				v = []string{" PARSER "}
			case "PAGE_SYM":
				v = []string{" PAGE "}
			case "PARTIAL":
				v = []string{" PARTIAL "}
			case "PARTITION_SYM":
				v = []string{" PARTITION "}
			case "PARTITIONING_SYM":
				v = []string{" PARTITIONING "}
			case "PARTITIONS_SYM":
				v = []string{" PARTITIONS "}
			case "PASSWORD":
				v = []string{" "}
			case "PASSWORD_LOCK_TIME_SYM":
				v = []string{" "}
			case "PERCENT_RANK_SYM":
				v = []string{" PERCENT_RANK "}
			case "PERSIST_SYM":
				v = []string{" PERSIST "}
			case "PERSIST_ONLY_SYM":
				v = []string{" PERSIST_ONLY "}
			case "PHASE_SYM":
				v = []string{" PHASE "}
			case "PLUGIN_SYM":
				v = []string{" PLUGIN "}
			case "PLUGINS_SYM":
				v = []string{" PLUGINS "}
			case "PLUGIN_DIR_SYM":
				v = []string{" PLUGIN_DIR "}
			case "POINT_SYM":
				v = []string{" POINT "}
			case "POLYGON_SYM":
				v = []string{" POLYGON "}
			case "PORT_SYM":
				v = []string{" PORT "}
			case "PRECEDES_SYM":
				v = []string{" PRECEDES "}
			case "PRECEDING_SYM":
				v = []string{" PRECEDING "}
			case "PRECISION":
				v = []string{" PRECISION "}
			case "PREPARE_SYM":
				v = []string{" PREPARE "}
			case "PRESERVE_SYM":
				v = []string{" PRESERVE "}
			case "PREV_SYM":
				v = []string{" PREV "}
			case "PRIMARY_SYM":
				v = []string{" PRIMARY "}
			case "PRIVILEGES":
				v = []string{" PRIVILEGES "}
			case "PRIVILEGE_CHECKS_USER_SYM":
				v = []string{" PRIVILEGE_CHECKS_USER "}
			case "PROCEDURE_SYM":
				v = []string{" PROCEDURE "}
			case "PROCESS":
				v = []string{" PROCESS "}
			case "PROCESSLIST_SYM":
				v = []string{" PROCESSLIST "}
			case "PROFILE_SYM":
				v = []string{" PROFILE "}
			case "PROFILES_SYM":
				v = []string{" PROFILES "}
			case "PROXY_SYM":
				v = []string{" PROXY "}
			case "PURGE":
				v = []string{" PURGE "}
			case "QUARTER_SYM":
				v = []string{" QUARTER "}
			case "QUERY_SYM":
				v = []string{" QUERY "}
			case "QUICK":
				v = []string{" QUICK "}
			case "RANDOM_SYM":
				v = []string{" RANDOM "}
			case "RANK_SYM":
				v = []string{" RANK "}
			case "RANGE_SYM":
				v = []string{" RANGE "}
			case "READ_SYM":
				v = []string{" READ "}
			case "READ_ONLY_SYM":
				v = []string{" READ_ONLY "}
			case "READ_WRITE_SYM":
				v = []string{" READ_WRITE "}
			case "READS_SYM":
				v = []string{" READS "}
			case "REAL_SYM":
				v = []string{" REAL "}
			case "REBUILD_SYM":
				v = []string{" REBUILD "}
			case "RECOVER_SYM":
				v = []string{" RECOVER "}
			case "RECURSIVE_SYM":
				v = []string{" RECURSIVE "}
			case "REDO_BUFFER_SIZE_SYM":
				v = []string{" REDO_BUFFER_SIZE "}
			case "REDUNDANT_SYM":
				v = []string{" REDUNDANT "}
			case "REFERENCE_SYM":
				v = []string{" REFERENCE "}
			case "REFERENCES":
				v = []string{" REFERENCES "}
			case "REGEXP":
				v = []string{" REGEXP "}
			case "REGISTRATION_SYM":
				v = []string{" REGISTRATION "}
			case "RELAY":
				v = []string{" RELAY "}
			case "RELAYLOG_SYM":
				v = []string{" RELAYLOG "}
			case "RELAY_LOG_FILE_SYM":
				v = []string{" RELAY_LOG_FILE "}
			case "RELAY_LOG_POS_SYM":
				v = []string{" RELAY_LOG_POS "}
			case "RELEASE_SYM":
				v = []string{" RELEASE "}
			case "RELOAD":
				v = []string{" RELOAD "}
			case "REMOVE_SYM":
				v = []string{" REMOVE "}
			case "RENAME":
				v = []string{" RENAME "}
			case "ASSIGN_GTIDS_TO_ANONYMOUS_TRANSACTIONS_SYM":
				v = []string{" ASSIGN_GTIDS_TO_ANONYMOUS_TRANSACTIONS "}
			case "REORGANIZE_SYM":
				v = []string{" REORGANIZE "}
			case "REPAIR":
				v = []string{" REPAIR "}
			case "REPEATABLE_SYM":
				v = []string{" REPEATABLE "}
			case "REPLICA_SYM":
				v = []string{" REPLICA "}
			case "REPLICAS_SYM":
				v = []string{" REPLICAS "}
			case "REPLICATION":
				v = []string{" REPLICATION "}
			case "REPLICATE_DO_DB":
				v = []string{" REPLICATE_DO_DB "}
			case "REPLICATE_IGNORE_DB":
				v = []string{" REPLICATE_IGNORE_DB "}
			case "REPLICATE_DO_TABLE":
				v = []string{" REPLICATE_DO_TABLE "}
			case "REPLICATE_IGNORE_TABLE":
				v = []string{" REPLICATE_IGNORE_TABLE "}
			case "REPLICATE_WILD_DO_TABLE":
				v = []string{" REPLICATE_WILD_DO_TABLE "}
			case "REPLICATE_WILD_IGNORE_TABLE":
				v = []string{" REPLICATE_WILD_IGNORE_TABLE "}
			case "REPLICATE_REWRITE_DB":
				v = []string{" REPLICATE_REWRITE_DB "}
			case "REPEAT_SYM":
				v = []string{" REPEAT "}
			case "REQUIRE_SYM":
				v = []string{" REQUIRE "}
			case "REQUIRE_ROW_FORMAT_SYM":
				v = []string{" REQUIRE_ROW_FORMAT "}
			case "REQUIRE_TABLE_PRIMARY_KEY_CHECK_SYM":
				v = []string{" REQUIRE_TABLE_PRIMARY_KEY_CHECK "}
			case "RESET_SYM":
				v = []string{" RESET "}
			case "RESPECT_SYM":
				v = []string{" RESPECT "}
			case "RESIGNAL_SYM":
				v = []string{" RESIGNAL "}
			case "RESOURCE_SYM":
				v = []string{" RESOURCE "}
			case "RESTART_SYM":
				v = []string{" RESTART "}
			case "RESTORE_SYM":
				v = []string{" RESTORE "}
			case "RESTRICT":
				v = []string{" RESTRICT "}
			case "RESUME_SYM":
				v = []string{" RESUME "}
			case "RETAIN_SYM":
				v = []string{" RETAIN "}
			case "RETURNED_SQLSTATE_SYM":
				v = []string{" RETURNED_SQLSTATE "}
			case "RETURN_SYM":
				v = []string{" RETURN "}
			case "RETURNING_SYM":
				v = []string{" RETURNING "}
			case "RETURNS_SYM":
				v = []string{" RETURNS "}
			case "REUSE_SYM":
				v = []string{" REUSE "}
			case "REVERSE_SYM":
				v = []string{" REVERSE "}
			case "REVOKE":
				v = []string{" REVOKE "}
			case "RIGHT":
				v = []string{" RIGHT "}
			case "REGEXP /* Like in mSQL2 */":
				v = []string{" RLIKE "}
			case "ROLE_SYM":
				v = []string{" ROLE "}
			case "ROLLBACK_SYM":
				v = []string{" ROLLBACK "}
			case "ROLLUP_SYM":
				v = []string{" ROLLUP "}
			case "ROUTINE_SYM":
				v = []string{" ROUTINE "}
			case "ROTATE_SYM":
				v = []string{" ROTATE "}
			case "ROW_SYM":
				v = []string{" ROW "}
			case "ROW_COUNT_SYM":
				v = []string{" ROW_COUNT "}
			case "ROW_NUMBER_SYM":
				v = []string{" ROW_NUMBER "}
			case "ROWS_SYM":
				v = []string{" ROWS "}
			case "ROW_FORMAT_SYM":
				v = []string{" ROW_FORMAT "}
			case "RTREE_SYM":
				v = []string{" RTREE "}
			case "SAVEPOINT_SYM":
				v = []string{" SAVEPOINT "}
			case "SCHEDULE_SYM":
				v = []string{" SCHEDULE "}
			case "SCHEMA_NAME_SYM":
				v = []string{" SCHEMA_NAME "}
			case "SECOND_SYM":
				v = []string{" SECOND "}
			case "SECOND_MICROSECOND_SYM":
				v = []string{" SECOND_MICROSECOND "}
			case "SECONDARY_SYM":
				v = []string{" SECONDARY "}
			case "SECONDARY_ENGINE_SYM":
				v = []string{" SECONDARY_ENGINE "}
			case "SECONDARY_ENGINE_ATTRIBUTE_SYM":
				v = []string{" SECONDARY_ENGINE_ATTRIBUTE "}
			case "SECONDARY_LOAD_SYM":
				v = []string{" SECONDARY_LOAD "}
			case "SECONDARY_UNLOAD_SYM":
				v = []string{" SECONDARY_UNLOAD "}
			case "SECURITY_SYM":
				v = []string{" SECURITY "}
			case "SENSITIVE_SYM":
				v = []string{" SENSITIVE "}
			case "SEPARATOR_SYM":
				v = []string{" SEPARATOR "}
			case "SERIAL_SYM":
				v = []string{" SERIAL "}
			case "SERIALIZABLE_SYM":
				v = []string{" SERIALIZABLE "}
			case "SESSION_SYM":
				v = []string{" SESSION "}
			case "SERVER_SYM":
				v = []string{" SERVER "}
			case "SET_SYM":
				v = []string{" SET "}
			case "SHARE_SYM":
				v = []string{" SHARE "}
			case "SHOW":
				v = []string{" SHOW "}
			case "SHUTDOWN":
				v = []string{" SHUTDOWN "}
			case "SIGNAL_SYM":
				v = []string{" SIGNAL "}
			case "SIGNED_SYM":
				v = []string{" SIGNED "}
			case "SIMPLE_SYM":
				v = []string{" SIMPLE "}
			case "SKIP_SYM":
				v = []string{" SKIP "}
			case "SLAVE":
				v = []string{" SLAVE "}
			case "SLOW":
				v = []string{" SLOW "}
			case "SNAPSHOT_SYM":
				v = []string{" SNAPSHOT "}
			case "SMALLINT_SYM":
				v = []string{" SMALLINT "}
			case "SOCKET_SYM":
				v = []string{" SOCKET "}
			case "SONAME_SYM":
				v = []string{" SONAME "}
			case "SOUNDS_SYM":
				v = []string{" SOUNDS "}
			case "SOURCE_SYM":
				v = []string{" SOURCE "}
			case "SOURCE_AUTO_POSITION_SYM":
				v = []string{" SOURCE_AUTO_POSITION "}
			case "SOURCE_BIND_SYM":
				v = []string{" SOURCE_BIND "}
			case "SOURCE_COMPRESSION_ALGORITHM_SYM":
				v = []string{" SOURCE_COMPRESSION_ALGORITHMS "}
			case "SOURCE_CONNECT_RETRY_SYM":
				v = []string{" SOURCE_CONNECT_RETRY "}
			case "SOURCE_CONNECTION_AUTO_FAILOVER_SYM":
				v = []string{" SOURCE_CONNECTION_AUTO_FAILOVER "}
			case "SOURCE_DELAY_SYM":
				v = []string{" SOURCE_DELAY "}
			case "SOURCE_HEARTBEAT_PERIOD_SYM":
				v = []string{" SOURCE_HEARTBEAT_PERIOD "}
			case "SOURCE_HOST_SYM":
				v = []string{" SOURCE_HOST "}
			case "SOURCE_LOG_FILE_SYM":
				v = []string{" SOURCE_LOG_FILE "}
			case "SOURCE_LOG_POS_SYM":
				v = []string{" SOURCE_LOG_POS "}
			case "SOURCE_PASSWORD_SYM":
				v = []string{" "}
			case "SOURCE_PORT_SYM":
				v = []string{" SOURCE_PORT "}
			case "SOURCE_PUBLIC_KEY_PATH_SYM":
				v = []string{" SOURCE_PUBLIC_KEY_PATH "}
			case "SOURCE_RETRY_COUNT_SYM":
				v = []string{" SOURCE_RETRY_COUNT "}
			case "SOURCE_SSL_CAPATH_SYM":
				v = []string{" SOURCE_SSL_CAPATH "}
			case "SOURCE_SSL_CA_SYM":
				v = []string{" SOURCE_SSL_CA "}
			case "SOURCE_SSL_CERT_SYM":
				v = []string{" SOURCE_SSL_CERT "}
			case "SOURCE_SSL_CIPHER_SYM":
				v = []string{" SOURCE_SSL_CIPHER "}
			case "SOURCE_SSL_CRL_SYM":
				v = []string{" SOURCE_SSL_CRL "}
			case "SOURCE_SSL_CRLPATH_SYM":
				v = []string{" SOURCE_SSL_CRLPATH "}
			case "SOURCE_SSL_KEY_SYM":
				v = []string{" SOURCE_SSL_KEY "}
			case "SOURCE_SSL_SYM":
				v = []string{" SOURCE_SSL "}
			case "SOURCE_SSL_VERIFY_SERVER_CERT_SYM":
				v = []string{" SOURCE_SSL_VERIFY_SERVER_CERT "}
			case "SOURCE_TLS_CIPHERSUITES_SYM":
				v = []string{" SOURCE_TLS_CIPHERSUITES "}
			case "SOURCE_TLS_VERSION_SYM":
				v = []string{" SOURCE_TLS_VERSION "}
			case "SOURCE_USER_SYM":
				v = []string{" SOURCE_USER "}
			case "SOURCE_ZSTD_COMPRESSION_LEVEL_SYM":
				v = []string{" SOURCE_ZSTD_COMPRESSION_LEVEL "}
			case "SPATIAL_SYM":
				v = []string{" SPATIAL "}
			case "SPECIFIC_SYM":
				v = []string{" SPECIFIC "}
			case "SQL_SYM":
				v = []string{" SQL "}
			case "SQLEXCEPTION_SYM":
				v = []string{" SQLEXCEPTION "}
			case "SQLSTATE_SYM":
				v = []string{" SQLSTATE "}
			case "SQLWARNING_SYM":
				v = []string{" SQLWARNING "}
			case "SQL_AFTER_GTIDS":
				v = []string{" SQL_AFTER_GTIDS "}
			case "SQL_AFTER_MTS_GAPS":
				v = []string{" SQL_AFTER_MTS_GAPS "}
			case "SQL_BEFORE_GTIDS":
				v = []string{" SQL_BEFORE_GTIDS "}
			case "SQL_BIG_RESULT":
				v = []string{" SQL_BIG_RESULT "}
			case "SQL_BUFFER_RESULT":
				v = []string{" SQL_BUFFER_RESULT "}
			case "SQL_CALC_FOUND_ROWS":
				v = []string{" SQL_CALC_FOUND_ROWS "}
			case "SQL_NO_CACHE_SYM":
				v = []string{" SQL_NO_CACHE "}
			case "SQL_SMALL_RESULT":
				v = []string{" SQL_SMALL_RESULT "}
			case "SQL_THREAD":
				v = []string{" SQL_THREAD "}
			case "SRID_SYM":
				v = []string{" SRID "}
			case "SSL_SYM":
				v = []string{" SSL "}
			case "STACKED_SYM":
				v = []string{" STACKED "}
			case "START_SYM":
				v = []string{" START "}
			case "STARTING":
				v = []string{" STARTING "}
			case "STARTS_SYM":
				v = []string{" STARTS "}
			case "STATS_AUTO_RECALC_SYM":
				v = []string{" STATS_AUTO_RECALC "}
			case "STATS_PERSISTENT_SYM":
				v = []string{" STATS_PERSISTENT "}
			case "STATS_SAMPLE_PAGES_SYM":
				v = []string{" STATS_SAMPLE_PAGES "}
			case "STATUS_SYM":
				v = []string{" STATUS "}
			case "STOP_SYM":
				v = []string{" STOP "}
			case "STORAGE_SYM":
				v = []string{" STORAGE "}
			case "STORED_SYM":
				v = []string{" STORED "}
			case "STRAIGHT_JOIN":
				v = []string{" STRAIGHT_JOIN "}
			case "STREAM_SYM":
				v = []string{" STREAM "}
			case "STRING_SYM":
				v = []string{" STRING "}
			case "SUBCLASS_ORIGIN_SYM":
				v = []string{" SUBCLASS_ORIGIN "}
			case "SUBJECT_SYM":
				v = []string{" SUBJECT "}
			case "SUBPARTITION_SYM":
				v = []string{" SUBPARTITION "}
			case "SUBPARTITIONS_SYM":
				v = []string{" SUBPARTITIONS "}
			case "SUPER_SYM":
				v = []string{" SUPER "}
			case "SUSPEND_SYM":
				v = []string{" SUSPEND "}
			case "SWAPS_SYM":
				v = []string{" SWAPS "}
			case "SWITCHES_SYM":
				v = []string{" SWITCHES "}
			case "SYSTEM_SYM":
				v = []string{" SYSTEM "}
			case "TABLE_SYM":
				v = []string{" TABLE "}
			case "TABLE_NAME_SYM":
				v = []string{" TABLE_NAME "}
			case "TABLES":
				v = []string{" TABLES "}
			case "TABLESPACE_SYM":
				v = []string{" TABLESPACE "}
			case "TABLE_CHECKSUM_SYM":
				v = []string{" TABLE_CHECKSUM "}
			case "TEMPORARY":
				v = []string{" TEMPORARY "}
			case "TEMPTABLE_SYM":
				v = []string{" TEMPTABLE "}
			case "TERMINATED":
				v = []string{" TERMINATED "}
			case "TEXT_SYM":
				v = []string{" TEXT "}
			case "THAN_SYM":
				v = []string{" THAN "}
			case "THEN_SYM":
				v = []string{" THEN "}
			case "THREAD_PRIORITY_SYM":
				v = []string{" THREAD_PRIORITY "}
			case "TIES_SYM":
				v = []string{" TIES "}
			case "TIME_SYM":
				v = []string{" TIME "}
			case "TIMESTAMP_SYM":
				v = []string{" TIMESTAMP "}
			case "TIMESTAMP_ADD":
				v = []string{" TIMESTAMPADD "}
			case "TIMESTAMP_DIFF":
				v = []string{" TIMESTAMPDIFF "}
			case "TINYBLOB_SYM":
				v = []string{" TINYBLOB "}
			case "TINYINT_SYM":
				v = []string{" TINYINT "}
			case "TINYTEXT_SYN":
				v = []string{" TINYTEXT "}
			case "TLS_SYM":
				v = []string{" TLS "}
			case "TO_SYM":
				v = []string{" TO "}
			case "TRAILING":
				v = []string{" TRAILING "}
			case "TRANSACTION_SYM":
				v = []string{" TRANSACTION "}
			case "TRIGGER_SYM":
				v = []string{" TRIGGER "}
			case "TRIGGERS_SYM":
				v = []string{" TRIGGERS "}
			case "TRUE_SYM":
				v = []string{" TRUE "}
			case "TRUNCATE_SYM":
				v = []string{" TRUNCATE "}
			case "TYPE_SYM":
				v = []string{" TYPE "}
			case "TYPES_SYM":
				v = []string{" TYPES "}
			case "UNBOUNDED_SYM":
				v = []string{" UNBOUNDED "}
			case "UNCOMMITTED_SYM":
				v = []string{" UNCOMMITTED "}
			case "UNDEFINED_SYM":
				v = []string{" UNDEFINED "}
			case "UNDO_BUFFER_SIZE_SYM":
				v = []string{" UNDO_BUFFER_SIZE "}
			case "UNDOFILE_SYM":
				v = []string{" UNDOFILE "}
			case "UNDO_SYM":
				v = []string{" UNDO "}
			case "UNICODE_SYM":
				v = []string{" UNICODE "}
			case "UNION_SYM":
				v = []string{" UNION "}
			case "UNIQUE_SYM":
				v = []string{" UNIQUE "}
			case "UNKNOWN_SYM":
				v = []string{" UNKNOWN "}
			case "UNLOCK_SYM":
				v = []string{" UNLOCK "}
			case "UNINSTALL_SYM":
				v = []string{" UNINSTALL "}
			case "UNREGISTER_SYM":
				v = []string{" UNREGISTER "}
			case "UNSIGNED_SYM":
				v = []string{" UNSIGNED "}
			case "UNTIL_SYM":
				v = []string{" UNTIL "}
			case "UPGRADE_SYM":
				v = []string{" UPGRADE "}
			case "USAGE":
				v = []string{" USAGE "}
			case "USE_SYM":
				v = []string{" USE "}
			case "USER":
				v = []string{" USER "}
			case "RESOURCES":
				v = []string{" USER_RESOURCES "}
			case "USE_FRM":
				v = []string{" USE_FRM "}
			case "USING":
				v = []string{" USING "}
			case "UTC_DATE_SYM":
				v = []string{" UTC_DATE "}
			case "UTC_TIME_SYM":
				v = []string{" UTC_TIME "}
			case "UTC_TIMESTAMP_SYM":
				v = []string{" UTC_TIMESTAMP "}
			case "VALIDATION_SYM":
				v = []string{" VALIDATION "}
			case "VALUE_SYM":
				v = []string{" VALUE "}
			case "VALUES":
				v = []string{" VALUES "}
			case "VARBINARY_SYM":
				v = []string{" VARBINARY "}
			case "VARCHAR_SYM":
				v = []string{" VARCHAR "}
			case "VARIABLES":
				v = []string{" VARIABLES "}
			case "VARYING":
				v = []string{" VARYING "}
			case "WAIT_SYM":
				v = []string{" WAIT "}
			case "WARNINGS":
				v = []string{" WARNINGS "}
			case "WEEK_SYM":
				v = []string{" WEEK "}
			case "WEIGHT_STRING_SYM":
				v = []string{" WEIGHT_STRING "}
			case "WHEN_SYM":
				v = []string{" WHEN "}
			case "WHERE":
				v = []string{" WHERE "}
			case "WHILE_SYM":
				v = []string{" WHILE "}
			case "WINDOW_SYM":
				v = []string{" WINDOW "}
			case "VCPU_SYM":
				v = []string{" VCPU "}
			case "VIEW_SYM":
				v = []string{" VIEW "}
			case "VIRTUAL_SYM":
				v = []string{" VIRTUAL "}
			case "VISIBLE_SYM":
				v = []string{" VISIBLE "}
			case "WITH":
				v = []string{" WITH "}
			case "WITHOUT_SYM":
				v = []string{" WITHOUT "}
			case "WORK_SYM":
				v = []string{" WORK "}
			case "WRAPPER_SYM":
				v = []string{" WRAPPER "}
			case "WRITE_SYM":
				v = []string{" WRITE "}
			case "X509_SYM":
				v = []string{" X509 "}
			case "XOR":
				v = []string{" XOR "}
			case "XA_SYM":
				v = []string{" XA "}
			case "XID_SYM":
				v = []string{" XID "}
			case "XML_SYM":
				v = []string{" XML "}
			case "YEAR_SYM":
				v = []string{" YEAR "}
			case "YEAR_MONTH_SYM":
				v = []string{" YEAR_MONTH "}
			case "ZEROFILL_SYM":
				v = []string{" ZEROFILL "}
			case "ZONE_SYM":
				v = []string{" ZONE "}
			case "OR_OR_SYM":
				v = []string{" || "}
			case "DELETE_SYM":
				v = []string{" DELETE "}
			case "INSERT_SYM":
				v = []string{" INSERT "}
			case "REPLACE_SYM":
				v = []string{" REPLACE "}
			case "SELECT_SYM":
				v = []string{" SELECT "}
			case "UPDATE_SYM":
				v = []string{" UPDATE "}
			case "ADDDATE_SYM":
				v = []string{" ADDDATE "}
			case "BIT_AND_SYM":
				v = []string{" BIT_AND "}
			case "BIT_OR_SYM":
				v = []string{" BIT_OR "}
			case "BIT_XOR_SYM":
				v = []string{" BIT_XOR "}
			case "CAST_SYM":
				v = []string{" CAST "}
			case "COUNT_SYM":
				v = []string{" COUNT "}
			case "DATE_ADD_INTERVAL":
				v = []string{" DATE_ADD "}
			case "DATE_SUB_INTERVAL":
				v = []string{" DATE_SUB "}
			case "EXTRACT_SYM":
				v = []string{" EXTRACT "}
			case "GROUP_CONCAT_SYM":
				v = []string{" GROUP_CONCAT "}
			case "JSON_OBJECTAGG":
				v = []string{" JSON_OBJECTAGG "}
			case "JSON_ARRAYAGG":
				v = []string{" JSON_ARRAYAGG "}
			case "MAX_SYM":
				v = []string{" MAX "}
			case "SUBSTRING /* unireg function */":
				v = []string{" MID "}
			case "MIN_SYM":
				v = []string{" MIN "}
			case "POSITION_SYM":
				v = []string{" POSITION "}
			case "STD_SYM":
				v = []string{" STD "}
			case "STDDEV_SAMP_SYM":
				v = []string{" STDDEV_SAMP "}
			case "ST_COLLECT_SYM":
				v = []string{" ST_COLLECT "}
			case "SUBDATE_SYM":
				v = []string{" SUBDATE "}
			case "SUBSTRING":
				v = []string{" SUBSTRING "}
			case "SUM_SYM":
				v = []string{" SUM "}
			case "SYSDATE":
				v = []string{" SYSDATE "}
			case "TRIM":
				v = []string{" TRIM "}
			case "VARIANCE_SYM":
				v = []string{" VARIANCE "}
			case "VAR_SAMP_SYM":
				v = []string{" VAR_SAMP "}
			case "BKA_HINT":
				v = []string{" BKA "}
			case "BNL_HINT":
				v = []string{" BNL "}
			case "DUPSWEEDOUT_HINT":
				v = []string{" DUPSWEEDOUT "}
			case "FIRSTMATCH_HINT":
				v = []string{" FIRSTMATCH "}
			case "INTOEXISTS_HINT":
				v = []string{" INTOEXISTS "}
			case "LOOSESCAN_HINT":
				v = []string{" LOOSESCAN "}
			case "MATERIALIZATION_HINT":
				v = []string{" MATERIALIZATION "}
			case "MAX_EXECUTION_TIME_HINT":
				v = []string{" MAX_EXECUTION_TIME "}
			case "NO_BKA_HINT":
				v = []string{" NO_BKA "}
			case "NO_BNL_HINT":
				v = []string{" NO_BNL "}
			case "NO_ICP_HINT":
				v = []string{" NO_ICP "}
			case "NO_MRR_HINT":
				v = []string{" NO_MRR "}
			case "NO_RANGE_OPTIMIZATION_HINT":
				v = []string{" NO_RANGE_OPTIMIZATION "}
			case "NO_SEMIJOIN_HINT":
				v = []string{" NO_SEMIJOIN "}
			case "MRR_HINT":
				v = []string{" MRR "}
			case "QB_NAME_HINT":
				v = []string{" QB_NAME "}
			case "SEMIJOIN_HINT":
				v = []string{" SEMIJOIN "}
			case "SET_VAR_HINT":
				v = []string{" SET_VAR "}
			case "SET_VAR":
				v = []string{" = "}
			case "@":
				v = []string{" "}
			case "SUBQUERY_HINT":
				v = []string{" SUBQUERY "}
			case "DERIVED_MERGE_HINT":
				v = []string{" MERGE "}
			case "NO_DERIVED_MERGE_HINT":
				v = []string{" NO_MERGE "}
			case "JOIN_PREFIX_HINT":
				v = []string{" JOIN_PREFIX "}
			case "JOIN_SUFFIX_HINT":
				v = []string{" JOIN_SUFFIX "}
			case "JOIN_ORDER_HINT":
				v = []string{" JOIN_ORDER "}
			case "JOIN_FIXED_ORDER_HINT":
				v = []string{" JOIN_FIXED_ORDER "}
			case "INDEX_MERGE_HINT":
				v = []string{" INDEX_MERGE "}
			case "NO_INDEX_MERGE_HINT":
				v = []string{" NO_INDEX_MERGE "}
			case "RESOURCE_GROUP_HINT":
				v = []string{" RESOURCE_GROUP "}
			case "SKIP_SCAN_HINT":
				v = []string{" SKIP_SCAN "}
			case "NO_SKIP_SCAN_HINT":
				v = []string{" NO_SKIP_SCAN "}
			case "HASH_JOIN_HINT":
				v = []string{" HASH_JOIN "}
			case "NO_HASH_JOIN_HINT":
				v = []string{" NO_HASH_JOIN "}
			case "INDEX_HINT":
				v = []string{" INDEX "}
			case "NO_INDEX_HINT":
				v = []string{" NO_INDEX "}
			case "JOIN_INDEX_HINT":
				v = []string{" JOIN_INDEX "}
			case "NO_JOIN_INDEX_HINT":
				v = []string{" NO_JOIN_INDEX "}
			case "GROUP_INDEX_HINT":
				v = []string{" GROUP_INDEX "}
			case "NO_GROUP_INDEX_HINT":
				v = []string{" NO_GROUP_INDEX "}
			case "ORDER_INDEX_HINT":
				v = []string{" ORDER_INDEX "}
			case "NO_ORDER_INDEX_HINT":
				v = []string{" NO_ORDER_INDEX "}
			case "DERIVED_CONDITION_PUSHDOWN_HINT":
				v = []string{" DERIVED_CONDITION_PUSHDOWN "}
			case "NO_DERIVED_CONDITION_PUSHDOWN_HINT":
				v = []string{" NO_DERIVED_CONDITION_PUSHDOWN "}

			default:

				if _, ok := r.GetAllProds()[tokenStr]; !ok {
					// Terminating token.
					if len(tokenStr) > 3 && tokenStr[len(tokenStr)-4:] == "_SYM" {
						tokenStr = tokenStr[:len(tokenStr)-4]
					}
					v = []string{tokenStr}
				} else {
					// Non-terminating token.
					var newChildPathNode *PathNode
					if !replayingMode {
						newChildPathNode = &PathNode{
							Id:        r.GetPathId(),
							Parent:    rootPathNode,
							ExprProds: nil,
							Children:  []*PathNode{},
							IsFav:     isFavPathNode,
							// Debug
							//ParentStr: root,
						}
						r.SetPathId(r.GetPathId() + 1)
						rootPathNode.Children = append(rootPathNode.Children, newChildPathNode)
						if isChooseCompRule {
							// Choosing the complex rules, depth - 1.
							v = GenerateMySQL(r, item.Value, newChildPathNode, rootHash, depth-1, rootDepth)
						} else {
							// If not choosing the complex rules, depth not decrease.
							v = GenerateMySQL(r, item.Value, newChildPathNode, rootHash, depth, rootDepth)
						}
					} else {
						if replayExprIdx >= len(rootPathNode.Children) {
							//fmt.Printf("\n\n\nERROR: The replaying node is not consistent with the saved structure. \n\n\n")
							//fmt.Printf("Root: %s", root)
							//fmt.Printf("len(rootPathNode.Children): %d\n", len(rootPathNode.Children))
							//fmt.Printf("replayExprIdx %d\n", replayExprIdx)
							return nil
						}
						newChildPathNode = rootPathNode.Children[replayExprIdx]
						replayExprIdx += 1
						// We won't decrease depth number in replaying mode.
						v = GenerateMySQL(r, item.Value, newChildPathNode, rootHash, depth, rootDepth)
					}
				}

			}
			if v == nil {
				fmt.Printf("\n\n\nError: v == nil in the RSGInterface. Root: %s, item: %s\n\n\n", root, item.Value)
				return nil
			}
			ret = append(ret, v...)
		default:
			panic("unknown item type")
		}
	}
	//fmt.Printf("\n%sLevel: %d, root: %s, allProds: %v", strings.Repeat(" ", 9-depth), depth, root, curChosenRule.Items)
	return ret
}
