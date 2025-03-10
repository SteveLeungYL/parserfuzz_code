%%

Start:
	StatementList

/**************************************AlterTableStmt***************************************
 * See https://dev.mysql.com/doc/refman/5.7/en/alter-table.html
 *******************************************************************************************/
AlterTableStmt:
	"ALTER" IgnoreOptional "TABLE" TableName AlterTableSpecListOpt AlterTablePartitionOpt
	{
		specs := $5.([]*ast.AlterTableSpec)
		if $6 != nil {
			specs = append(specs, $6.(*ast.AlterTableSpec))
		}
		$$ = &ast.AlterTableStmt{
			Table: $4.(*ast.TableName),
			Specs: specs,
		}
	}
|	"ALTER" IgnoreOptional "TABLE" TableName "ANALYZE" "PARTITION" PartitionNameList AnalyzeOptionListOpt
	{
		$$ = &ast.AnalyzeTableStmt{TableNames: []*ast.TableName{$4.(*ast.TableName)}, PartitionNames: $7.([]model.CIStr), AnalyzeOpts: $8.([]ast.AnalyzeOpt)}
	}
|	"ALTER" IgnoreOptional "TABLE" TableName "ANALYZE" "PARTITION" PartitionNameList "INDEX" IndexNameList AnalyzeOptionListOpt
	{
		$$ = &ast.AnalyzeTableStmt{
			TableNames:     []*ast.TableName{$4.(*ast.TableName)},
			PartitionNames: $7.([]model.CIStr),
			IndexNames:     $9.([]model.CIStr),
			IndexFlag:      true,
			AnalyzeOpts:    $10.([]ast.AnalyzeOpt),
		}
	}
|	"ALTER" IgnoreOptional "TABLE" TableName "COMPACT" "TIFLASH" "REPLICA"
	{
		$$ = &ast.CompactTableStmt{
			Table:       $4.(*ast.TableName),
			ReplicaKind: ast.CompactReplicaKindTiFlash,
		}
	}

PlacementOptionList:
	DirectPlacementOption
	{
		$$ = []*ast.PlacementOption{$1.(*ast.PlacementOption)}
	}
|	PlacementOptionList DirectPlacementOption
	{
		$$ = append($1.([]*ast.PlacementOption), $2.(*ast.PlacementOption))
	}
|	PlacementOptionList ',' DirectPlacementOption
	{
		$$ = append($1.([]*ast.PlacementOption), $3.(*ast.PlacementOption))
	}

DirectPlacementOption:
	"PRIMARY_REGION" EqOpt stringLit
	{
		$$ = &ast.PlacementOption{Tp: ast.PlacementOptionPrimaryRegion, StrValue: $3}
	}
|	"REGIONS" EqOpt stringLit
	{
		$$ = &ast.PlacementOption{Tp: ast.PlacementOptionRegions, StrValue: $3}
	}
|	"FOLLOWERS" EqOpt LengthNum
	{
		cnt := $3.(uint64)
		if cnt == 0 {
			yylex.AppendError(yylex.Errorf("FOLLOWERS must be positive"))
			return 1
		}
		$$ = &ast.PlacementOption{Tp: ast.PlacementOptionFollowerCount, UintValue: cnt}
	}
|	"VOTERS" EqOpt LengthNum
	{
		$$ = &ast.PlacementOption{Tp: ast.PlacementOptionVoterCount, UintValue: $3.(uint64)}
	}
|	"LEARNERS" EqOpt LengthNum
	{
		$$ = &ast.PlacementOption{Tp: ast.PlacementOptionLearnerCount, UintValue: $3.(uint64)}
	}
|	"SCHEDULE" EqOpt stringLit
	{
		$$ = &ast.PlacementOption{Tp: ast.PlacementOptionSchedule, StrValue: $3}
	}
|	"CONSTRAINTS" EqOpt stringLit
	{
		$$ = &ast.PlacementOption{Tp: ast.PlacementOptionConstraints, StrValue: $3}
	}
|	"LEADER_CONSTRAINTS" EqOpt stringLit
	{
		$$ = &ast.PlacementOption{Tp: ast.PlacementOptionLeaderConstraints, StrValue: $3}
	}
|	"FOLLOWER_CONSTRAINTS" EqOpt stringLit
	{
		$$ = &ast.PlacementOption{Tp: ast.PlacementOptionFollowerConstraints, StrValue: $3}
	}
|	"VOTER_CONSTRAINTS" EqOpt stringLit
	{
		$$ = &ast.PlacementOption{Tp: ast.PlacementOptionVoterConstraints, StrValue: $3}
	}
|	"LEARNER_CONSTRAINTS" EqOpt stringLit
	{
		$$ = &ast.PlacementOption{Tp: ast.PlacementOptionLearnerConstraints, StrValue: $3}
	}

PlacementPolicyOption:
	"PLACEMENT" "POLICY" EqOpt stringLit
	{
		$$ = &ast.PlacementOption{Tp: ast.PlacementOptionPolicy, StrValue: $4}
	}
|	"PLACEMENT" "POLICY" EqOpt PolicyName
	{
		$$ = &ast.PlacementOption{Tp: ast.PlacementOptionPolicy, StrValue: $4}
	}
|	"PLACEMENT" "POLICY" EqOpt "DEFAULT"
	{
		$$ = &ast.PlacementOption{Tp: ast.PlacementOptionPolicy, StrValue: $4}
	}
|	"PLACEMENT" "POLICY" "SET" "DEFAULT"
	{
		$$ = &ast.PlacementOption{Tp: ast.PlacementOptionPolicy, StrValue: $4}
	}

AttributesOpt:
	"ATTRIBUTES" EqOpt "DEFAULT"
	{
		$$ = &ast.AttributesSpec{Default: true}
	}
|	"ATTRIBUTES" EqOpt stringLit
	{
		$$ = &ast.AttributesSpec{Default: false, Attributes: $3}
	}

StatsOptionsOpt:
	"STATS_OPTIONS" EqOpt "DEFAULT"
	{
		$$ = &ast.StatsOptionsSpec{Default: true}
	}
|	"STATS_OPTIONS" EqOpt stringLit
	{
		$$ = &ast.StatsOptionsSpec{Default: false, StatsOptions: $3}
	}

AlterTablePartitionOpt:
	PartitionOpt
	{
		if $1 != nil {
			$$ = &ast.AlterTableSpec{
				Tp:        ast.AlterTablePartition,
				Partition: $1.(*ast.PartitionOptions),
			}
		} else {
			$$ = nil
		}
	}
|	"REMOVE" "PARTITIONING"
	{
		$$ = &ast.AlterTableSpec{
			Tp: ast.AlterTableRemovePartitioning,
		}
	}
|	"REORGANIZE" "PARTITION" NoWriteToBinLogAliasOpt ReorganizePartitionRuleOpt
	{
		ret := $4.(*ast.AlterTableSpec)
		ret.NoWriteToBinlog = $3.(bool)
		$$ = ret
	}
|	"PARTITION" Identifier AttributesOpt
	{
		$$ = &ast.AlterTableSpec{
			Tp:             ast.AlterTablePartitionAttributes,
			PartitionNames: []model.CIStr{model.NewCIStr($2)},
			AttributesSpec: $3.(*ast.AttributesSpec),
		}
	}
|	"PARTITION" Identifier PartDefOptionList
	{
		$$ = &ast.AlterTableSpec{
			Tp:             ast.AlterTablePartitionOptions,
			PartitionNames: []model.CIStr{model.NewCIStr($2)},
			Options:        $3.([]*ast.TableOption),
		}
	}

LocationLabelList:
	{
		$$ = []string{}
	}
|	"LOCATION" "LABELS" StringList
	{
		$$ = $3
	}

AlterTableSpec:
	TableOptionList %prec higherThanComma
	{
		$$ = &ast.AlterTableSpec{
			Tp:      ast.AlterTableOption,
			Options: $1.([]*ast.TableOption),
		}
	}
|	"SET" "TIFLASH" "REPLICA" LengthNum LocationLabelList
	{
		tiflashReplicaSpec := &ast.TiFlashReplicaSpec{
			Count:  $4.(uint64),
			Labels: $5.([]string),
		}
		$$ = &ast.AlterTableSpec{
			Tp:             ast.AlterTableSetTiFlashReplica,
			TiFlashReplica: tiflashReplicaSpec,
		}
	}
|	"CONVERT" "TO" CharsetKw CharsetName OptCollate
	{
		op := &ast.AlterTableSpec{
			Tp: ast.AlterTableOption,
			Options: []*ast.TableOption{{Tp: ast.TableOptionCharset, StrValue: $4,
				UintValue: ast.TableOptionCharsetWithConvertTo}},
		}
		if $5 != "" {
			op.Options = append(op.Options, &ast.TableOption{Tp: ast.TableOptionCollate, StrValue: $5})
		}
		$$ = op
	}
|	"CONVERT" "TO" CharsetKw "DEFAULT" OptCollate
	{
		op := &ast.AlterTableSpec{
			Tp: ast.AlterTableOption,
			Options: []*ast.TableOption{{Tp: ast.TableOptionCharset, Default: true,
				UintValue: ast.TableOptionCharsetWithConvertTo}},
		}
		if $5 != "" {
			op.Options = append(op.Options, &ast.TableOption{Tp: ast.TableOptionCollate, StrValue: $5})
		}
		$$ = op
	}
|	"ADD" ColumnKeywordOpt IfNotExists ColumnDef ColumnPosition
	{
		$$ = &ast.AlterTableSpec{
			IfNotExists: $3.(bool),
			Tp:          ast.AlterTableAddColumns,
			NewColumns:  []*ast.ColumnDef{$4.(*ast.ColumnDef)},
			Position:    $5.(*ast.ColumnPosition),
		}
	}
|	"ADD" ColumnKeywordOpt IfNotExists '(' TableElementList ')'
	{
		tes := $5.([]interface{})
		var columnDefs []*ast.ColumnDef
		var constraints []*ast.Constraint
		for _, te := range tes {
			switch te := te.(type) {
			case *ast.ColumnDef:
				columnDefs = append(columnDefs, te)
			case *ast.Constraint:
				constraints = append(constraints, te)
			}
		}
		$$ = &ast.AlterTableSpec{
			IfNotExists:    $3.(bool),
			Tp:             ast.AlterTableAddColumns,
			NewColumns:     columnDefs,
			NewConstraints: constraints,
		}
	}
|	"ADD" Constraint
	{
		constraint := $2.(*ast.Constraint)
		$$ = &ast.AlterTableSpec{
			Tp:         ast.AlterTableAddConstraint,
			Constraint: constraint,
		}
	}
|	"ADD" "PARTITION" IfNotExists NoWriteToBinLogAliasOpt PartitionDefinitionListOpt
	{
		var defs []*ast.PartitionDefinition
		if $5 != nil {
			defs = $5.([]*ast.PartitionDefinition)
		}
		noWriteToBinlog := $4.(bool)
		if noWriteToBinlog {
			yylex.AppendError(yylex.Errorf("The NO_WRITE_TO_BINLOG option is parsed but ignored for now."))
			parser.lastErrorAsWarn()
		}
		$$ = &ast.AlterTableSpec{
			IfNotExists:     $3.(bool),
			NoWriteToBinlog: noWriteToBinlog,
			Tp:              ast.AlterTableAddPartitions,
			PartDefinitions: defs,
		}
	}
|	"ADD" "PARTITION" IfNotExists NoWriteToBinLogAliasOpt "PARTITIONS" NUM
	{
		noWriteToBinlog := $4.(bool)
		if noWriteToBinlog {
			yylex.AppendError(yylex.Errorf("The NO_WRITE_TO_BINLOG option is parsed but ignored for now."))
			parser.lastErrorAsWarn()
		}
		$$ = &ast.AlterTableSpec{
			IfNotExists:     $3.(bool),
			NoWriteToBinlog: noWriteToBinlog,
			Tp:              ast.AlterTableAddPartitions,
			Num:             getUint64FromNUM($6),
		}
	}
|	"ADD" "STATS_EXTENDED" IfNotExists Identifier StatsType '(' ColumnNameList ')'
	{
		statsSpec := &ast.StatisticsSpec{
			StatsName: $4,
			StatsType: $5.(uint8),
			Columns:   $7.([]*ast.ColumnName),
		}
		$$ = &ast.AlterTableSpec{
			Tp:          ast.AlterTableAddStatistics,
			IfNotExists: $3.(bool),
			Statistics:  statsSpec,
		}
	}
|	AttributesOpt
	{
		$$ = &ast.AlterTableSpec{
			Tp:             ast.AlterTableAttributes,
			AttributesSpec: $1.(*ast.AttributesSpec),
		}
	}
|	StatsOptionsOpt
	{
		$$ = &ast.AlterTableSpec{
			Tp:               ast.AlterTableStatsOptions,
			StatsOptionsSpec: $1.(*ast.StatsOptionsSpec),
		}
	}
|	"CHECK" "PARTITION" AllOrPartitionNameList
	{
		yylex.AppendError(yylex.Errorf("The CHECK PARTITIONING clause is parsed but not implement yet."))
		parser.lastErrorAsWarn()
		ret := &ast.AlterTableSpec{
			Tp: ast.AlterTableCheckPartitions,
		}
		if $3 == nil {
			ret.OnAllPartitions = true
		} else {
			ret.PartitionNames = $3.([]model.CIStr)
		}
		$$ = ret
	}
|	"COALESCE" "PARTITION" NoWriteToBinLogAliasOpt NUM
	{
		noWriteToBinlog := $3.(bool)
		if noWriteToBinlog {
			yylex.AppendError(yylex.Errorf("The NO_WRITE_TO_BINLOG option is parsed but ignored for now."))
			parser.lastErrorAsWarn()
		}
		$$ = &ast.AlterTableSpec{
			Tp:              ast.AlterTableCoalescePartitions,
			NoWriteToBinlog: noWriteToBinlog,
			Num:             getUint64FromNUM($4),
		}
	}
|	"DROP" ColumnKeywordOpt IfExists ColumnName RestrictOrCascadeOpt
	{
		$$ = &ast.AlterTableSpec{
			IfExists:      $3.(bool),
			Tp:            ast.AlterTableDropColumn,
			OldColumnName: $4.(*ast.ColumnName),
		}
	}
|	"DROP" "PRIMARY" "KEY"
	{
		$$ = &ast.AlterTableSpec{Tp: ast.AlterTableDropPrimaryKey}
	}
|	"DROP" "PARTITION" IfExists PartitionNameList %prec lowerThanComma
	{
		$$ = &ast.AlterTableSpec{
			IfExists:       $3.(bool),
			Tp:             ast.AlterTableDropPartition,
			PartitionNames: $4.([]model.CIStr),
		}
	}
|	"DROP" "STATS_EXTENDED" IfExists Identifier
	{
		statsSpec := &ast.StatisticsSpec{
			StatsName: $4,
		}
		$$ = &ast.AlterTableSpec{
			Tp:         ast.AlterTableDropStatistics,
			IfExists:   $3.(bool),
			Statistics: statsSpec,
		}
	}
|	"EXCHANGE" "PARTITION" Identifier "WITH" "TABLE" TableName WithValidationOpt
	{
		$$ = &ast.AlterTableSpec{
			Tp:             ast.AlterTableExchangePartition,
			PartitionNames: []model.CIStr{model.NewCIStr($3)},
			NewTable:       $6.(*ast.TableName),
			WithValidation: $7.(bool),
		}
	}
|	"TRUNCATE" "PARTITION" AllOrPartitionNameList
	{
		ret := &ast.AlterTableSpec{
			Tp: ast.AlterTableTruncatePartition,
		}
		if $3 == nil {
			ret.OnAllPartitions = true
		} else {
			ret.PartitionNames = $3.([]model.CIStr)
		}
		$$ = ret
	}
|	"OPTIMIZE" "PARTITION" NoWriteToBinLogAliasOpt AllOrPartitionNameList
	{
		ret := &ast.AlterTableSpec{
			NoWriteToBinlog: $3.(bool),
			Tp:              ast.AlterTableOptimizePartition,
		}
		if $4 == nil {
			ret.OnAllPartitions = true
		} else {
			ret.PartitionNames = $4.([]model.CIStr)
		}
		$$ = ret
	}
|	"REPAIR" "PARTITION" NoWriteToBinLogAliasOpt AllOrPartitionNameList
	{
		ret := &ast.AlterTableSpec{
			NoWriteToBinlog: $3.(bool),
			Tp:              ast.AlterTableRepairPartition,
		}
		if $4 == nil {
			ret.OnAllPartitions = true
		} else {
			ret.PartitionNames = $4.([]model.CIStr)
		}
		$$ = ret
	}
|	"IMPORT" "PARTITION" AllOrPartitionNameList "TABLESPACE"
	{
		ret := &ast.AlterTableSpec{
			Tp: ast.AlterTableImportPartitionTablespace,
		}
		if $3 == nil {
			ret.OnAllPartitions = true
		} else {
			ret.PartitionNames = $3.([]model.CIStr)
		}
		$$ = ret
		yylex.AppendError(yylex.Errorf("The IMPORT PARTITION TABLESPACE clause is parsed but ignored by all storage engines."))
		parser.lastErrorAsWarn()
	}
|	"DISCARD" "PARTITION" AllOrPartitionNameList "TABLESPACE"
	{
		ret := &ast.AlterTableSpec{
			Tp: ast.AlterTableDiscardPartitionTablespace,
		}
		if $3 == nil {
			ret.OnAllPartitions = true
		} else {
			ret.PartitionNames = $3.([]model.CIStr)
		}
		$$ = ret
		yylex.AppendError(yylex.Errorf("The DISCARD PARTITION TABLESPACE clause is parsed but ignored by all storage engines."))
		parser.lastErrorAsWarn()
	}
|	"IMPORT" "TABLESPACE"
	{
		ret := &ast.AlterTableSpec{
			Tp: ast.AlterTableImportTablespace,
		}
		$$ = ret
		yylex.AppendError(yylex.Errorf("The IMPORT TABLESPACE clause is parsed but ignored by all storage engines."))
		parser.lastErrorAsWarn()
	}
|	"DISCARD" "TABLESPACE"
	{
		ret := &ast.AlterTableSpec{
			Tp: ast.AlterTableDiscardTablespace,
		}
		$$ = ret
		yylex.AppendError(yylex.Errorf("The DISCARD TABLESPACE clause is parsed but ignored by all storage engines."))
		parser.lastErrorAsWarn()
	}
|	"REBUILD" "PARTITION" NoWriteToBinLogAliasOpt AllOrPartitionNameList
	{
		ret := &ast.AlterTableSpec{
			Tp:              ast.AlterTableRebuildPartition,
			NoWriteToBinlog: $3.(bool),
		}
		if $4 == nil {
			ret.OnAllPartitions = true
		} else {
			ret.PartitionNames = $4.([]model.CIStr)
		}
		$$ = ret
	}
|	"DROP" KeyOrIndex IfExists Identifier
	{
		$$ = &ast.AlterTableSpec{
			IfExists: $3.(bool),
			Tp:       ast.AlterTableDropIndex,
			Name:     $4,
		}
	}
|	"DROP" "FOREIGN" "KEY" IfExists Symbol
	{
		$$ = &ast.AlterTableSpec{
			IfExists: $4.(bool),
			Tp:       ast.AlterTableDropForeignKey,
			Name:     $5,
		}
	}
|	"ORDER" "BY" AlterOrderList %prec lowerThenOrder
	{
		$$ = &ast.AlterTableSpec{
			Tp:          ast.AlterTableOrderByColumns,
			OrderByList: $3.([]*ast.AlterOrderItem),
		}
	}
|	"DISABLE" "KEYS"
	{
		$$ = &ast.AlterTableSpec{
			Tp: ast.AlterTableDisableKeys,
		}
	}
|	"ENABLE" "KEYS"
	{
		$$ = &ast.AlterTableSpec{
			Tp: ast.AlterTableEnableKeys,
		}
	}
|	"MODIFY" ColumnKeywordOpt IfExists ColumnDef ColumnPosition
	{
		$$ = &ast.AlterTableSpec{
			IfExists:   $3.(bool),
			Tp:         ast.AlterTableModifyColumn,
			NewColumns: []*ast.ColumnDef{$4.(*ast.ColumnDef)},
			Position:   $5.(*ast.ColumnPosition),
		}
	}
|	"CHANGE" ColumnKeywordOpt IfExists ColumnName ColumnDef ColumnPosition
	{
		$$ = &ast.AlterTableSpec{
			IfExists:      $3.(bool),
			Tp:            ast.AlterTableChangeColumn,
			OldColumnName: $4.(*ast.ColumnName),
			NewColumns:    []*ast.ColumnDef{$5.(*ast.ColumnDef)},
			Position:      $6.(*ast.ColumnPosition),
		}
	}
|	"ALTER" ColumnKeywordOpt ColumnName "SET" "DEFAULT" SignedLiteral
	{
		option := &ast.ColumnOption{Expr: $6}
		colDef := &ast.ColumnDef{
			Name:    $3.(*ast.ColumnName),
			Options: []*ast.ColumnOption{option},
		}
		$$ = &ast.AlterTableSpec{
			Tp:         ast.AlterTableAlterColumn,
			NewColumns: []*ast.ColumnDef{colDef},
		}
	}
|	"ALTER" ColumnKeywordOpt ColumnName "SET" "DEFAULT" '(' Expression ')'
	{
		option := &ast.ColumnOption{Expr: $7}
		colDef := &ast.ColumnDef{
			Name:    $3.(*ast.ColumnName),
			Options: []*ast.ColumnOption{option},
		}
		$$ = &ast.AlterTableSpec{
			Tp:         ast.AlterTableAlterColumn,
			NewColumns: []*ast.ColumnDef{colDef},
		}
	}
|	"ALTER" ColumnKeywordOpt ColumnName "DROP" "DEFAULT"
	{
		colDef := &ast.ColumnDef{
			Name: $3.(*ast.ColumnName),
		}
		$$ = &ast.AlterTableSpec{
			Tp:         ast.AlterTableAlterColumn,
			NewColumns: []*ast.ColumnDef{colDef},
		}
	}
|	"RENAME" "COLUMN" Identifier "TO" Identifier
	{
		oldColName := &ast.ColumnName{Name: model.NewCIStr($3)}
		newColName := &ast.ColumnName{Name: model.NewCIStr($5)}
		$$ = &ast.AlterTableSpec{
			Tp:            ast.AlterTableRenameColumn,
			OldColumnName: oldColName,
			NewColumnName: newColName,
		}
	}
|	"RENAME" "TO" TableName
	{
		$$ = &ast.AlterTableSpec{
			Tp:       ast.AlterTableRenameTable,
			NewTable: $3.(*ast.TableName),
		}
	}
|	"RENAME" EqOpt TableName
	{
		$$ = &ast.AlterTableSpec{
			Tp:       ast.AlterTableRenameTable,
			NewTable: $3.(*ast.TableName),
		}
	}
|	"RENAME" "AS" TableName
	{
		$$ = &ast.AlterTableSpec{
			Tp:       ast.AlterTableRenameTable,
			NewTable: $3.(*ast.TableName),
		}
	}
|	"RENAME" KeyOrIndex Identifier "TO" Identifier
	{
		$$ = &ast.AlterTableSpec{
			Tp:      ast.AlterTableRenameIndex,
			FromKey: model.NewCIStr($3),
			ToKey:   model.NewCIStr($5),
		}
	}
|	LockClause
	{
		$$ = &ast.AlterTableSpec{
			Tp:       ast.AlterTableLock,
			LockType: $1.(ast.LockType),
		}
	}
|	Writeable
	{
		$$ = &ast.AlterTableSpec{
			Tp:        ast.AlterTableWriteable,
			Writeable: $1.(bool),
		}
	}
|	AlgorithmClause
	{
		// Parse it and ignore it. Just for compatibility.
		$$ = &ast.AlterTableSpec{
			Tp:        ast.AlterTableAlgorithm,
			Algorithm: $1.(ast.AlgorithmType),
		}
	}
|	"FORCE"
	{
		// Parse it and ignore it. Just for compatibility.
		$$ = &ast.AlterTableSpec{
			Tp: ast.AlterTableForce,
		}
	}
|	"WITH" "VALIDATION"
	{
		// Parse it and ignore it. Just for compatibility.
		$$ = &ast.AlterTableSpec{
			Tp: ast.AlterTableWithValidation,
		}
	}
|	"WITHOUT" "VALIDATION"
	{
		// Parse it and ignore it. Just for compatibility.
		$$ = &ast.AlterTableSpec{
			Tp: ast.AlterTableWithoutValidation,
		}
	}
// Added in MySQL 8.0.13, see: https://dev.mysql.com/doc/refman/8.0/en/keywords.html for details
|	"SECONDARY_LOAD"
	{
		// Parse it and ignore it. Just for compatibility.
		$$ = &ast.AlterTableSpec{
			Tp: ast.AlterTableSecondaryLoad,
		}
		yylex.AppendError(yylex.Errorf("The SECONDARY_LOAD clause is parsed but not implement yet."))
		parser.lastErrorAsWarn()
	}
// Added in MySQL 8.0.13, see: https://dev.mysql.com/doc/refman/8.0/en/keywords.html for details
|	"SECONDARY_UNLOAD"
	{
		// Parse it and ignore it. Just for compatibility.
		$$ = &ast.AlterTableSpec{
			Tp: ast.AlterTableSecondaryUnload,
		}
		yylex.AppendError(yylex.Errorf("The SECONDARY_UNLOAD VALIDATION clause is parsed but not implement yet."))
		parser.lastErrorAsWarn()
	}
|	"ALTER" CheckConstraintKeyword Identifier EnforcedOrNot
	{
		c := &ast.Constraint{
			Name:     $3,
			Enforced: $4.(bool),
		}
		$$ = &ast.AlterTableSpec{
			Tp:         ast.AlterTableAlterCheck,
			Constraint: c,
		}
	}
|	"DROP" CheckConstraintKeyword Identifier
	{
		// Parse it and ignore it. Just for compatibility.
		c := &ast.Constraint{
			Name: $3,
		}
		$$ = &ast.AlterTableSpec{
			Tp:         ast.AlterTableDropCheck,
			Constraint: c,
		}
	}
|	"ALTER" "INDEX" Identifier IndexInvisible
	{
		$$ = &ast.AlterTableSpec{
			Tp:         ast.AlterTableIndexInvisible,
			IndexName:  model.NewCIStr($3),
			Visibility: $4.(ast.IndexVisibility),
		}
	}
// 	Support caching or non-caching a table in memory for tidb, It can be found in the official Oracle document, see: https://docs.oracle.com/database/121/SQLRF/statements_3001.htm
|	"CACHE"
	{
		$$ = &ast.AlterTableSpec{
			Tp: ast.AlterTableCache,
		}
	}
|	"NOCACHE"
	{
		$$ = &ast.AlterTableSpec{
			Tp: ast.AlterTableNoCache,
		}
	}

ReorganizePartitionRuleOpt:
	/* empty */ %prec lowerThanRemove
	{
		ret := &ast.AlterTableSpec{
			Tp:              ast.AlterTableReorganizePartition,
			OnAllPartitions: true,
		}
		$$ = ret
	}
|	PartitionNameList "INTO" '(' PartitionDefinitionList ')'
	{
		ret := &ast.AlterTableSpec{
			Tp:              ast.AlterTableReorganizePartition,
			PartitionNames:  $1.([]model.CIStr),
			PartDefinitions: $4.([]*ast.PartitionDefinition),
		}
		$$ = ret
	}

AllOrPartitionNameList:
	"ALL"
	{
		$$ = nil
	}
|	PartitionNameList %prec lowerThanComma

WithValidationOpt:
	{
		$$ = true
	}
|	WithValidation

WithValidation:
	"WITH" "VALIDATION"
	{
		$$ = true
	}
|	"WITHOUT" "VALIDATION"
	{
		$$ = false
	}

WithClustered:
	"CLUSTERED"
	{
		$$ = model.PrimaryKeyTypeClustered
	}
|	"NONCLUSTERED"
	{
		$$ = model.PrimaryKeyTypeNonClustered
	}

AlgorithmClause:
	"ALGORITHM" EqOpt "DEFAULT"
	{
		$$ = ast.AlgorithmTypeDefault
	}
|	"ALGORITHM" EqOpt "COPY"
	{
		$$ = ast.AlgorithmTypeCopy
	}
|	"ALGORITHM" EqOpt "INPLACE"
	{
		$$ = ast.AlgorithmTypeInplace
	}
|	"ALGORITHM" EqOpt "INSTANT"
	{
		$$ = ast.AlgorithmTypeInstant
	}
|	"ALGORITHM" EqOpt identifier
	{
		yylex.AppendError(ErrUnknownAlterAlgorithm.GenWithStackByArgs($1))
		return 1
	}

LockClause:
	"LOCK" EqOpt "DEFAULT"
	{
		$$ = ast.LockTypeDefault
	}
|	"LOCK" EqOpt Identifier
	{
		id := strings.ToUpper($3)

		if id == "NONE" {
			$$ = ast.LockTypeNone
		} else if id == "SHARED" {
			$$ = ast.LockTypeShared
		} else if id == "EXCLUSIVE" {
			$$ = ast.LockTypeExclusive
		} else {
			yylex.AppendError(ErrUnknownAlterLock.GenWithStackByArgs($3))
			return 1
		}
	}

Writeable:
	"READ" "WRITE"
	{
		$$ = true
	}
|	"READ" "ONLY"
	{
		$$ = false
	}

KeyOrIndex:
	"KEY"
|	"INDEX"

KeyOrIndexOpt:
	{}
|	KeyOrIndex

ColumnKeywordOpt:
	/* empty */ %prec empty
	{}
|	"COLUMN"

ColumnPosition:
	{
		$$ = &ast.ColumnPosition{Tp: ast.ColumnPositionNone}
	}
|	"FIRST"
	{
		$$ = &ast.ColumnPosition{Tp: ast.ColumnPositionFirst}
	}
|	"AFTER" ColumnName
	{
		$$ = &ast.ColumnPosition{
			Tp:             ast.ColumnPositionAfter,
			RelativeColumn: $2.(*ast.ColumnName),
		}
	}

AlterTableSpecListOpt:
	/* empty */
	{
		$$ = make([]*ast.AlterTableSpec, 0, 1)
	}
|	AlterTableSpecList

AlterTableSpecList:
	AlterTableSpec
	{
		$$ = []*ast.AlterTableSpec{$1.(*ast.AlterTableSpec)}
	}
|	AlterTableSpecList ',' AlterTableSpec
	{
		$$ = append($1.([]*ast.AlterTableSpec), $3.(*ast.AlterTableSpec))
	}

PartitionNameList:
	Identifier
	{
		$$ = []model.CIStr{model.NewCIStr($1)}
	}
|	PartitionNameList ',' Identifier
	{
		$$ = append($1.([]model.CIStr), model.NewCIStr($3))
	}

ConstraintKeywordOpt:
	/* empty */ %prec empty
	{
		$$ = nil
	}
|	"CONSTRAINT"
	{
		$$ = nil
	}
|	"CONSTRAINT" Symbol
	{
		$$ = $2
	}

Symbol:
	Identifier

/**************************************RenameTableStmt***************************************
 * See http://dev.mysql.com/doc/refman/5.7/en/rename-table.html
 *
 * RENAME TABLE
 *     tbl_name TO new_tbl_name
 *     [, tbl_name2 TO new_tbl_name2] ...
 *******************************************************************************************/
RenameTableStmt:
	"RENAME" "TABLE" TableToTableList
	{
		$$ = &ast.RenameTableStmt{
			TableToTables: $3.([]*ast.TableToTable),
		}
	}

TableToTableList:
	TableToTable
	{
		$$ = []*ast.TableToTable{$1.(*ast.TableToTable)}
	}
|	TableToTableList ',' TableToTable
	{
		$$ = append($1.([]*ast.TableToTable), $3.(*ast.TableToTable))
	}

TableToTable:
	TableName "TO" TableName
	{
		$$ = &ast.TableToTable{
			OldTable: $1.(*ast.TableName),
			NewTable: $3.(*ast.TableName),
		}
	}

/**************************************RenameUserStmt***************************************
 * See https://dev.mysql.com/doc/refman/5.7/en/rename-user.html
 *
 * RENAME USER
 *     old_user TO new_user
 *     [, old_user2 TO new_user2] ...
 *******************************************************************************************/
RenameUserStmt:
	"RENAME" "USER" UserToUserList
	{
		$$ = &ast.RenameUserStmt{
			UserToUsers: $3.([]*ast.UserToUser),
		}
	}

UserToUserList:
	UserToUser
	{
		$$ = []*ast.UserToUser{$1.(*ast.UserToUser)}
	}
|	UserToUserList ',' UserToUser
	{
		$$ = append($1.([]*ast.UserToUser), $3.(*ast.UserToUser))
	}

UserToUser:
	Username "TO" Username
	{
		$$ = &ast.UserToUser{
			OldUser: $1.(*auth.UserIdentity),
			NewUser: $3.(*auth.UserIdentity),
		}
	}

/*******************************************************************
 *
 *  Recover Table Statement
 *
 *  Example:
 *      RECOVER TABLE t1;
 *      RECOVER TABLE BY JOB 100;
 *
 *******************************************************************/
RecoverTableStmt:
	"RECOVER" "TABLE" "BY" "JOB" Int64Num
	{
		$$ = &ast.RecoverTableStmt{
			JobID: $5.(int64),
		}
	}
|	"RECOVER" "TABLE" TableName
	{
		$$ = &ast.RecoverTableStmt{
			Table: $3.(*ast.TableName),
		}
	}
|	"RECOVER" "TABLE" TableName Int64Num
	{
		$$ = &ast.RecoverTableStmt{
			Table:  $3.(*ast.TableName),
			JobNum: $4.(int64),
		}
	}

/*******************************************************************
 *
 *  Flush Back Table Statement
 *
 *  Example:
 *
 *******************************************************************/
FlashbackTableStmt:
	"FLASHBACK" "TABLE" TableName FlashbackToNewName
	{
		$$ = &ast.FlashBackTableStmt{
			Table:   $3.(*ast.TableName),
			NewName: $4,
		}
	}

FlashbackToNewName:
	{
		$$ = ""
	}
|	"TO" Identifier
	{
		$$ = $2
	}

/*******************************************************************
 *
 *  Split index region statement
 *
 *  Example:
 *      SPLIT TABLE table_name INDEX index_name BY (val1...),(val2...)...
 *
 *******************************************************************/
SplitRegionStmt:
	"SPLIT" SplitSyntaxOption "TABLE" TableName PartitionNameListOpt SplitOption
	{
		$$ = &ast.SplitRegionStmt{
			SplitSyntaxOpt: $2.(*ast.SplitSyntaxOption),
			Table:          $4.(*ast.TableName),
			PartitionNames: $5.([]model.CIStr),
			SplitOpt:       $6.(*ast.SplitOption),
		}
	}
|	"SPLIT" SplitSyntaxOption "TABLE" TableName PartitionNameListOpt "INDEX" Identifier SplitOption
	{
		$$ = &ast.SplitRegionStmt{
			SplitSyntaxOpt: $2.(*ast.SplitSyntaxOption),
			Table:          $4.(*ast.TableName),
			PartitionNames: $5.([]model.CIStr),
			IndexName:      model.NewCIStr($7),
			SplitOpt:       $8.(*ast.SplitOption),
		}
	}

SplitOption:
	"BETWEEN" RowValue "AND" RowValue "REGIONS" Int64Num
	{
		$$ = &ast.SplitOption{
			Lower: $2.([]ast.ExprNode),
			Upper: $4.([]ast.ExprNode),
			Num:   $6.(int64),
		}
	}
|	"BY" ValuesList
	{
		$$ = &ast.SplitOption{
			ValueLists: $2.([][]ast.ExprNode),
		}
	}

SplitSyntaxOption:
	/* empty */
	{
		$$ = &ast.SplitSyntaxOption{}
	}
|	"REGION" "FOR"
	{
		$$ = &ast.SplitSyntaxOption{
			HasRegionFor: true,
		}
	}
|	"PARTITION"
	{
		$$ = &ast.SplitSyntaxOption{
			HasPartition: true,
		}
	}
|	"REGION" "FOR" "PARTITION"
	{
		$$ = &ast.SplitSyntaxOption{
			HasRegionFor: true,
			HasPartition: true,
		}
	}

AnalyzeTableStmt:
	"ANALYZE" "TABLE" TableNameList AllColumnsOrPredicateColumnsOpt AnalyzeOptionListOpt
	{
		$$ = &ast.AnalyzeTableStmt{TableNames: $3.([]*ast.TableName), ColumnChoice: $4.(model.ColumnChoice), AnalyzeOpts: $5.([]ast.AnalyzeOpt)}
	}
|	"ANALYZE" "TABLE" TableName "INDEX" IndexNameList AnalyzeOptionListOpt
	{
		$$ = &ast.AnalyzeTableStmt{TableNames: []*ast.TableName{$3.(*ast.TableName)}, IndexNames: $5.([]model.CIStr), IndexFlag: true, AnalyzeOpts: $6.([]ast.AnalyzeOpt)}
	}
|	"ANALYZE" "INCREMENTAL" "TABLE" TableName "INDEX" IndexNameList AnalyzeOptionListOpt
	{
		$$ = &ast.AnalyzeTableStmt{TableNames: []*ast.TableName{$4.(*ast.TableName)}, IndexNames: $6.([]model.CIStr), IndexFlag: true, Incremental: true, AnalyzeOpts: $7.([]ast.AnalyzeOpt)}
	}
|	"ANALYZE" "TABLE" TableName "PARTITION" PartitionNameList AllColumnsOrPredicateColumnsOpt AnalyzeOptionListOpt
	{
		$$ = &ast.AnalyzeTableStmt{TableNames: []*ast.TableName{$3.(*ast.TableName)}, PartitionNames: $5.([]model.CIStr), ColumnChoice: $6.(model.ColumnChoice), AnalyzeOpts: $7.([]ast.AnalyzeOpt)}
	}
|	"ANALYZE" "TABLE" TableName "PARTITION" PartitionNameList "INDEX" IndexNameList AnalyzeOptionListOpt
	{
		$$ = &ast.AnalyzeTableStmt{
			TableNames:     []*ast.TableName{$3.(*ast.TableName)},
			PartitionNames: $5.([]model.CIStr),
			IndexNames:     $7.([]model.CIStr),
			IndexFlag:      true,
			AnalyzeOpts:    $8.([]ast.AnalyzeOpt),
		}
	}
|	"ANALYZE" "INCREMENTAL" "TABLE" TableName "PARTITION" PartitionNameList "INDEX" IndexNameList AnalyzeOptionListOpt
	{
		$$ = &ast.AnalyzeTableStmt{
			TableNames:     []*ast.TableName{$4.(*ast.TableName)},
			PartitionNames: $6.([]model.CIStr),
			IndexNames:     $8.([]model.CIStr),
			IndexFlag:      true,
			Incremental:    true,
			AnalyzeOpts:    $9.([]ast.AnalyzeOpt),
		}
	}
|	"ANALYZE" "TABLE" TableName "UPDATE" "HISTOGRAM" "ON" IdentList AnalyzeOptionListOpt
	{
		$$ = &ast.AnalyzeTableStmt{
			TableNames:         []*ast.TableName{$3.(*ast.TableName)},
			ColumnNames:        $7.([]model.CIStr),
			AnalyzeOpts:        $8.([]ast.AnalyzeOpt),
			HistogramOperation: ast.HistogramOperationUpdate,
		}
	}
|	"ANALYZE" "TABLE" TableName "DROP" "HISTOGRAM" "ON" IdentList
	{
		$$ = &ast.AnalyzeTableStmt{
			TableNames:         []*ast.TableName{$3.(*ast.TableName)},
			ColumnNames:        $7.([]model.CIStr),
			HistogramOperation: ast.HistogramOperationDrop,
		}
	}
|	"ANALYZE" "TABLE" TableName "COLUMNS" IdentList AnalyzeOptionListOpt
	{
		$$ = &ast.AnalyzeTableStmt{
			TableNames:   []*ast.TableName{$3.(*ast.TableName)},
			ColumnNames:  $5.([]model.CIStr),
			ColumnChoice: model.ColumnList,
			AnalyzeOpts:  $6.([]ast.AnalyzeOpt)}
	}
|	"ANALYZE" "TABLE" TableName "PARTITION" PartitionNameList "COLUMNS" IdentList AnalyzeOptionListOpt
	{
		$$ = &ast.AnalyzeTableStmt{
			TableNames:     []*ast.TableName{$3.(*ast.TableName)},
			PartitionNames: $5.([]model.CIStr),
			ColumnNames:    $7.([]model.CIStr),
			ColumnChoice:   model.ColumnList,
			AnalyzeOpts:    $8.([]ast.AnalyzeOpt)}
	}

AllColumnsOrPredicateColumnsOpt:
	/* empty */
	{
		$$ = model.DefaultChoice
	}
|	"ALL" "COLUMNS"
	{
		$$ = model.AllColumns
	}
|	"PREDICATE" "COLUMNS"
	{
		$$ = model.PredicateColumns
	}

AnalyzeOptionListOpt:
	{
		$$ = []ast.AnalyzeOpt{}
	}
|	"WITH" AnalyzeOptionList
	{
		$$ = $2.([]ast.AnalyzeOpt)
	}

AnalyzeOptionList:
	AnalyzeOption
	{
		$$ = []ast.AnalyzeOpt{$1.(ast.AnalyzeOpt)}
	}
|	AnalyzeOptionList ',' AnalyzeOption
	{
		$$ = append($1.([]ast.AnalyzeOpt), $3.(ast.AnalyzeOpt))
	}

AnalyzeOption:
	NUM "BUCKETS"
	{
		$$ = ast.AnalyzeOpt{Type: ast.AnalyzeOptNumBuckets, Value: ast.NewValueExpr($1, "", "")}
	}
|	NUM "TOPN"
	{
		$$ = ast.AnalyzeOpt{Type: ast.AnalyzeOptNumTopN, Value: ast.NewValueExpr($1, "", "")}
	}
|	NUM "CMSKETCH" "DEPTH"
	{
		$$ = ast.AnalyzeOpt{Type: ast.AnalyzeOptCMSketchDepth, Value: ast.NewValueExpr($1, "", "")}
	}
|	NUM "CMSKETCH" "WIDTH"
	{
		$$ = ast.AnalyzeOpt{Type: ast.AnalyzeOptCMSketchWidth, Value: ast.NewValueExpr($1, "", "")}
	}
|	NUM "SAMPLES"
	{
		$$ = ast.AnalyzeOpt{Type: ast.AnalyzeOptNumSamples, Value: ast.NewValueExpr($1, "", "")}
	}
|	NumLiteral "SAMPLERATE"
	{
		$$ = ast.AnalyzeOpt{Type: ast.AnalyzeOptSampleRate, Value: ast.NewValueExpr($1, "", "")}
	}

/*******************************************************************************************/
Assignment:
	ColumnName eq ExprOrDefault
	{
		$$ = &ast.Assignment{Column: $1.(*ast.ColumnName), Expr: $3}
	}

AssignmentList:
	Assignment
	{
		$$ = []*ast.Assignment{$1.(*ast.Assignment)}
	}
|	AssignmentList ',' Assignment
	{
		$$ = append($1.([]*ast.Assignment), $3.(*ast.Assignment))
	}

AssignmentListOpt:
	/* EMPTY */
	{
		$$ = []*ast.Assignment{}
	}
|	AssignmentList

BeginTransactionStmt:
	"BEGIN"
	{
		$$ = &ast.BeginStmt{}
	}
|	"BEGIN" "PESSIMISTIC"
	{
		$$ = &ast.BeginStmt{
			Mode: ast.Pessimistic,
		}
	}
|	"BEGIN" "OPTIMISTIC"
	{
		$$ = &ast.BeginStmt{
			Mode: ast.Optimistic,
		}
	}
|	"START" "TRANSACTION"
	{
		$$ = &ast.BeginStmt{}
	}
|	"START" "TRANSACTION" "READ" "WRITE"
	{
		$$ = &ast.BeginStmt{}
	}
|	"START" "TRANSACTION" "WITH" "CONSISTENT" "SNAPSHOT"
	{
		$$ = &ast.BeginStmt{}
	}
|	"START" "TRANSACTION" "WITH" "CAUSAL" "CONSISTENCY" "ONLY"
	{
		$$ = &ast.BeginStmt{
			CausalConsistencyOnly: true,
		}
	}
|	"START" "TRANSACTION" "READ" "ONLY"
	{
		$$ = &ast.BeginStmt{
			ReadOnly: true,
		}
	}
|	"START" "TRANSACTION" "READ" "ONLY" AsOfClause
	{
		$$ = &ast.BeginStmt{
			ReadOnly: true,
			AsOf:     $5.(*ast.AsOfClause),
		}
	}

BinlogStmt:
	"BINLOG" stringLit
	{
		$$ = &ast.BinlogStmt{Str: $2}
	}

ColumnDefList:
	ColumnDef
	{
		$$ = []*ast.ColumnDef{$1.(*ast.ColumnDef)}
	}
|	ColumnDefList ',' ColumnDef
	{
		$$ = append($1.([]*ast.ColumnDef), $3.(*ast.ColumnDef))
	}

ColumnDef:
	ColumnName Type ColumnOptionListOpt
	{
		colDef := &ast.ColumnDef{Name: $1.(*ast.ColumnName), Tp: $2.(*types.FieldType), Options: $3.([]*ast.ColumnOption)}
		if !colDef.Validate() {
			yylex.AppendError(yylex.Errorf("Invalid column definition"))
			return 1
		}
		$$ = colDef
	}
|	ColumnName "SERIAL" ColumnOptionListOpt
	{
		// TODO: check flen 0
		tp := types.NewFieldType(mysql.TypeLonglong)
		options := []*ast.ColumnOption{{Tp: ast.ColumnOptionNotNull}, {Tp: ast.ColumnOptionAutoIncrement}, {Tp: ast.ColumnOptionUniqKey}}
		options = append(options, $3.([]*ast.ColumnOption)...)
		tp.AddFlag(mysql.UnsignedFlag)
		colDef := &ast.ColumnDef{Name: $1.(*ast.ColumnName), Tp: tp, Options: options}
		if !colDef.Validate() {
			yylex.AppendError(yylex.Errorf("Invalid column definition"))
			return 1
		}
		$$ = colDef
	}

ColumnName:
	Identifier
	{
		$$ = &ast.ColumnName{Name: model.NewCIStr($1)}
	}
|	Identifier '.' Identifier
	{
		$$ = &ast.ColumnName{Table: model.NewCIStr($1), Name: model.NewCIStr($3)}
	}
|	Identifier '.' Identifier '.' Identifier
	{
		$$ = &ast.ColumnName{Schema: model.NewCIStr($1), Table: model.NewCIStr($3), Name: model.NewCIStr($5)}
	}

ColumnNameList:
	ColumnName
	{
		$$ = []*ast.ColumnName{$1.(*ast.ColumnName)}
	}
|	ColumnNameList ',' ColumnName
	{
		$$ = append($1.([]*ast.ColumnName), $3.(*ast.ColumnName))
	}

ColumnNameListOpt:
	/* EMPTY */
	{
		$$ = []*ast.ColumnName{}
	}
|	ColumnNameList

IdentListWithParenOpt:
	/* EMPTY */
	{
		$$ = []model.CIStr{}
	}
|	'(' IdentList ')'
	{
		$$ = $2
	}

IdentList:
	Identifier
	{
		$$ = []model.CIStr{model.NewCIStr($1)}
	}
|	IdentList ',' Identifier
	{
		$$ = append($1.([]model.CIStr), model.NewCIStr($3))
	}

ColumnNameOrUserVarListOpt:
	/* EMPTY */
	{
		$$ = []*ast.ColumnNameOrUserVar{}
	}
|	ColumnNameOrUserVariableList

ColumnNameOrUserVariableList:
	ColumnNameOrUserVariable
	{
		$$ = []*ast.ColumnNameOrUserVar{$1.(*ast.ColumnNameOrUserVar)}
	}
|	ColumnNameOrUserVariableList ',' ColumnNameOrUserVariable
	{
		$$ = append($1.([]*ast.ColumnNameOrUserVar), $3.(*ast.ColumnNameOrUserVar))
	}

ColumnNameOrUserVariable:
	ColumnName
	{
		$$ = &ast.ColumnNameOrUserVar{ColumnName: $1.(*ast.ColumnName)}
	}
|	UserVariable
	{
		$$ = &ast.ColumnNameOrUserVar{UserVar: $1.(*ast.VariableExpr)}
	}

ColumnNameOrUserVarListOptWithBrackets:
	/* EMPTY */
	{
		$$ = []*ast.ColumnNameOrUserVar{}
	}
|	'(' ColumnNameOrUserVarListOpt ')'
	{
		$$ = $2.([]*ast.ColumnNameOrUserVar)
	}

CommitStmt:
	"COMMIT"
	{
		$$ = &ast.CommitStmt{}
	}
|	"COMMIT" CompletionTypeWithinTransaction
	{
		$$ = &ast.CommitStmt{CompletionType: $2.(ast.CompletionType)}
	}

PrimaryOpt:
	{}
|	"PRIMARY"

NotSym:
	not
|	not2
	{
		$$ = "NOT"
	}

EnforcedOrNot:
	"ENFORCED"
	{
		$$ = true
	}
|	NotSym "ENFORCED"
	{
		$$ = false
	}

EnforcedOrNotOpt:
	%prec lowerThanNot
	{
		$$ = true
	}
|	EnforcedOrNot

EnforcedOrNotOrNotNullOpt:
	//	 This branch is needed to workaround the need of a lookahead of 2 for the grammar:
	//
	//	  { [NOT] NULL | CHECK(...) [NOT] ENFORCED } ...
	NotSym "NULL"
	{
		$$ = 0
	}
|	EnforcedOrNotOpt
	{
		if $1.(bool) {
			$$ = 1
		} else {
			$$ = 2
		}
	}

ColumnOption:
	NotSym "NULL"
	{
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionNotNull}
	}
|	"NULL"
	{
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionNull}
	}
|	"AUTO_INCREMENT"
	{
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionAutoIncrement}
	}
|	PrimaryOpt "KEY"
	{
		// KEY is normally a synonym for INDEX. The key attribute PRIMARY KEY
		// can also be specified as just KEY when given in a column definition.
		// See http://dev.mysql.com/doc/refman/5.7/en/create-table.html
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionPrimaryKey}
	}
|	PrimaryOpt "KEY" WithClustered
	{
		// KEY is normally a synonym for INDEX. The key attribute PRIMARY KEY
		// can also be specified as just KEY when given in a column definition.
		// See http://dev.mysql.com/doc/refman/5.7/en/create-table.html
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionPrimaryKey, PrimaryKeyTp: $3.(model.PrimaryKeyType)}
	}
|	"UNIQUE" %prec lowerThanKey
	{
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionUniqKey}
	}
|	"UNIQUE" "KEY"
	{
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionUniqKey}
	}
|	"DEFAULT" DefaultValueExpr
	{
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionDefaultValue, Expr: $2}
	}
|	"SERIAL" "DEFAULT" "VALUE"
	{
		$$ = []*ast.ColumnOption{{Tp: ast.ColumnOptionNotNull}, {Tp: ast.ColumnOptionAutoIncrement}, {Tp: ast.ColumnOptionUniqKey}}
	}
|	"ON" "UPDATE" NowSymOptionFraction
	{
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionOnUpdate, Expr: $3}
	}
|	"COMMENT" stringLit
	{
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionComment, Expr: ast.NewValueExpr($2, "", "")}
	}
|	ConstraintKeywordOpt "CHECK" '(' Expression ')' EnforcedOrNotOrNotNullOpt
	{
		// See https://dev.mysql.com/doc/refman/5.7/en/create-table.html
		// The CHECK clause is parsed but ignored by all storage engines.
		// See the branch named `EnforcedOrNotOrNotNullOpt`.

		optionCheck := &ast.ColumnOption{
			Tp:       ast.ColumnOptionCheck,
			Expr:     $4,
			Enforced: true,
		}
		// Keep the column type check constraint name.
		if $1 != nil {
			optionCheck.ConstraintName = $1.(string)
		}
		switch $6.(int) {
		case 0:
			$$ = []*ast.ColumnOption{optionCheck, {Tp: ast.ColumnOptionNotNull}}
		case 1:
			optionCheck.Enforced = true
			$$ = optionCheck
		case 2:
			optionCheck.Enforced = false
			$$ = optionCheck
		default:
		}
	}
|	GeneratedAlways "AS" '(' Expression ')' VirtualOrStored
	{
		startOffset := parser.startOffset(&yyS[yypt-2])
		endOffset := parser.endOffset(&yyS[yypt-1])
		expr := $4
		expr.SetText(parser.lexer.client, parser.src[startOffset:endOffset])

		$$ = &ast.ColumnOption{
			Tp:     ast.ColumnOptionGenerated,
			Expr:   expr,
			Stored: $6.(bool),
		}
	}
|	ReferDef
	{
		$$ = &ast.ColumnOption{
			Tp:    ast.ColumnOptionReference,
			Refer: $1.(*ast.ReferenceDef),
		}
	}
|	"COLLATE" CollationName
	{
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionCollate, StrValue: $2}
	}
|	"COLUMN_FORMAT" ColumnFormat
	{
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionColumnFormat, StrValue: $2}
	}
|	"STORAGE" StorageMedia
	{
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionStorage, StrValue: $2}
		yylex.AppendError(yylex.Errorf("The STORAGE clause is parsed but ignored by all storage engines."))
		parser.lastErrorAsWarn()
	}
|	"AUTO_RANDOM" OptFieldLen
	{
		$$ = &ast.ColumnOption{Tp: ast.ColumnOptionAutoRandom, AutoRandomBitLength: $2.(int)}
	}

StorageMedia:
	"DEFAULT"
|	"DISK"
|	"MEMORY"

ColumnFormat:
	"DEFAULT"
	{
		$$ = "DEFAULT"
	}
|	"FIXED"
	{
		$$ = "FIXED"
	}
|	"DYNAMIC"
	{
		$$ = "DYNAMIC"
	}

GeneratedAlways:

|	"GENERATED" "ALWAYS"

VirtualOrStored:
	{
		$$ = false
	}
|	"VIRTUAL"
	{
		$$ = false
	}
|	"STORED"
	{
		$$ = true
	}

ColumnOptionList:
	ColumnOption
	{
		if columnOption, ok := $1.(*ast.ColumnOption); ok {
			$$ = []*ast.ColumnOption{columnOption}
		} else {
			$$ = $1
		}
	}
|	ColumnOptionList ColumnOption
	{
		if columnOption, ok := $2.(*ast.ColumnOption); ok {
			$$ = append($1.([]*ast.ColumnOption), columnOption)
		} else {
			$$ = append($1.([]*ast.ColumnOption), $2.([]*ast.ColumnOption)...)
		}
	}

ColumnOptionListOpt:
	{
		$$ = []*ast.ColumnOption{}
	}
|	ColumnOptionList

ConstraintElem:
	"PRIMARY" "KEY" IndexNameAndTypeOpt '(' IndexPartSpecificationList ')' IndexOptionList
	{
		c := &ast.Constraint{
			Tp:           ast.ConstraintPrimaryKey,
			Keys:         $5.([]*ast.IndexPartSpecification),
			Name:         $3.([]interface{})[0].(*ast.NullString).String,
			IsEmptyIndex: $3.([]interface{})[0].(*ast.NullString).Empty,
		}
		if $7 != nil {
			c.Option = $7.(*ast.IndexOption)
		}
		if indexType := $3.([]interface{})[1]; indexType != nil {
			if c.Option == nil {
				c.Option = &ast.IndexOption{}
			}
			c.Option.Tp = indexType.(model.IndexType)
		}
		$$ = c
	}
|	"FULLTEXT" KeyOrIndexOpt IndexName '(' IndexPartSpecificationList ')' IndexOptionList
	{
		c := &ast.Constraint{
			Tp:           ast.ConstraintFulltext,
			Keys:         $5.([]*ast.IndexPartSpecification),
			Name:         $3.(*ast.NullString).String,
			IsEmptyIndex: $3.(*ast.NullString).Empty,
		}
		if $7 != nil {
			c.Option = $7.(*ast.IndexOption)
		}
		$$ = c
	}
|	KeyOrIndex IfNotExists IndexNameAndTypeOpt '(' IndexPartSpecificationList ')' IndexOptionList
	{
		c := &ast.Constraint{
			IfNotExists:  $2.(bool),
			Tp:           ast.ConstraintIndex,
			Keys:         $5.([]*ast.IndexPartSpecification),
			Name:         $3.([]interface{})[0].(*ast.NullString).String,
			IsEmptyIndex: $3.([]interface{})[0].(*ast.NullString).Empty,
		}
		if $7 != nil {
			c.Option = $7.(*ast.IndexOption)
		}
		if indexType := $3.([]interface{})[1]; indexType != nil {
			if c.Option == nil {
				c.Option = &ast.IndexOption{}
			}
			c.Option.Tp = indexType.(model.IndexType)
		}
		$$ = c
	}
|	"UNIQUE" KeyOrIndexOpt IndexNameAndTypeOpt '(' IndexPartSpecificationList ')' IndexOptionList
	{
		c := &ast.Constraint{
			Tp:           ast.ConstraintUniq,
			Keys:         $5.([]*ast.IndexPartSpecification),
			Name:         $3.([]interface{})[0].(*ast.NullString).String,
			IsEmptyIndex: $3.([]interface{})[0].(*ast.NullString).Empty,
		}
		if $7 != nil {
			c.Option = $7.(*ast.IndexOption)
		}

		if indexType := $3.([]interface{})[1]; indexType != nil {
			if c.Option == nil {
				c.Option = &ast.IndexOption{}
			}
			c.Option.Tp = indexType.(model.IndexType)
		}
		$$ = c
	}
|	"FOREIGN" "KEY" IfNotExists IndexName '(' IndexPartSpecificationList ')' ReferDef
	{
		$$ = &ast.Constraint{
			IfNotExists:  $3.(bool),
			Tp:           ast.ConstraintForeignKey,
			Keys:         $6.([]*ast.IndexPartSpecification),
			Name:         $4.(*ast.NullString).String,
			Refer:        $8.(*ast.ReferenceDef),
			IsEmptyIndex: $4.(*ast.NullString).Empty,
		}
	}
|	"CHECK" '(' Expression ')' EnforcedOrNotOpt
	{
		$$ = &ast.Constraint{
			Tp:       ast.ConstraintCheck,
			Expr:     $3.(ast.ExprNode),
			Enforced: $5.(bool),
		}
	}

Match:
	"MATCH" "FULL"
	{
		$$ = ast.MatchFull
	}
|	"MATCH" "PARTIAL"
	{
		$$ = ast.MatchPartial
	}
|	"MATCH" "SIMPLE"
	{
		$$ = ast.MatchSimple
	}

MatchOpt:
	{
		$$ = ast.MatchNone
	}
|	Match
	{
		$$ = $1
		yylex.AppendError(yylex.Errorf("The MATCH clause is parsed but ignored by all storage engines."))
		parser.lastErrorAsWarn()
	}

ReferDef:
	"REFERENCES" TableName IndexPartSpecificationListOpt MatchOpt OnDeleteUpdateOpt
	{
		onDeleteUpdate := $5.([2]interface{})
		$$ = &ast.ReferenceDef{
			Table:                   $2.(*ast.TableName),
			IndexPartSpecifications: $3.([]*ast.IndexPartSpecification),
			OnDelete:                onDeleteUpdate[0].(*ast.OnDeleteOpt),
			OnUpdate:                onDeleteUpdate[1].(*ast.OnUpdateOpt),
			Match:                   $4.(ast.MatchType),
		}
	}

OnDelete:
	"ON" "DELETE" ReferOpt
	{
		$$ = &ast.OnDeleteOpt{ReferOpt: $3.(ast.ReferOptionType)}
	}

OnUpdate:
	"ON" "UPDATE" ReferOpt
	{
		$$ = &ast.OnUpdateOpt{ReferOpt: $3.(ast.ReferOptionType)}
	}

OnDeleteUpdateOpt:
	%prec lowerThanOn
	{
		$$ = [2]interface{}{&ast.OnDeleteOpt{}, &ast.OnUpdateOpt{}}
	}
|	OnDelete %prec lowerThanOn
	{
		$$ = [2]interface{}{$1, &ast.OnUpdateOpt{}}
	}
|	OnUpdate %prec lowerThanOn
	{
		$$ = [2]interface{}{&ast.OnDeleteOpt{}, $1}
	}
|	OnDelete OnUpdate
	{
		$$ = [2]interface{}{$1, $2}
	}
|	OnUpdate OnDelete
	{
		$$ = [2]interface{}{$2, $1}
	}

ReferOpt:
	"RESTRICT"
	{
		$$ = ast.ReferOptionRestrict
	}
|	"CASCADE"
	{
		$$ = ast.ReferOptionCascade
	}
|	"SET" "NULL"
	{
		$$ = ast.ReferOptionSetNull
	}
|	"NO" "ACTION"
	{
		$$ = ast.ReferOptionNoAction
	}
|	"SET" "DEFAULT"
	{
		$$ = ast.ReferOptionSetDefault
		yylex.AppendError(yylex.Errorf("The SET DEFAULT clause is parsed but ignored by all storage engines."))
		parser.lastErrorAsWarn()
	}

/*
 * The DEFAULT clause specifies a default value for a column.
 * It can be a function or an expression. This means, for example,
 * that you can set the default for a date column to be the value of
 * a function such as NOW() or CURRENT_DATE. While in MySQL 8.0
 * expression default values are required to be enclosed in parentheses,
 * they are NOT required so in TiDB.
 *
 * See https://dev.mysql.com/doc/refman/8.0/en/create-table.html
 *     https://dev.mysql.com/doc/refman/8.0/en/data-type-defaults.html
 */
DefaultValueExpr:
	NowSymOptionFractionParentheses
|	SignedLiteral
|	NextValueForSequence
|	BuiltinFunction

BuiltinFunction:
	'(' BuiltinFunction ')'
	{
		$$ = $2.(*ast.FuncCallExpr)
	}
|	identifier '(' ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
		}
	}
|	identifier '(' ExpressionList ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args:   $3.([]ast.ExprNode),
		}
	}

NowSymOptionFractionParentheses:
	'(' NowSymOptionFractionParentheses ')'
	{
		$$ = $2.(*ast.FuncCallExpr)
	}
|	NowSymOptionFraction

NowSymOptionFraction:
	NowSym
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr("CURRENT_TIMESTAMP")}
	}
|	NowSymFunc '(' ')'
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr("CURRENT_TIMESTAMP")}
	}
|	NowSymFunc '(' NUM ')'
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr("CURRENT_TIMESTAMP"), Args: []ast.ExprNode{ast.NewValueExpr($3, parser.charset, parser.collation)}}
	}

NextValueForSequence:
	"NEXT" "VALUE" forKwd TableName
	{
		objNameExpr := &ast.TableNameExpr{
			Name: $4.(*ast.TableName),
		}
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr(ast.NextVal),
			Args:   []ast.ExprNode{objNameExpr},
		}
	}
|	"NEXTVAL" '(' TableName ')'
	{
		objNameExpr := &ast.TableNameExpr{
			Name: $3.(*ast.TableName),
		}
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr(ast.NextVal),
			Args:   []ast.ExprNode{objNameExpr},
		}
	}

/*
* See https://dev.mysql.com/doc/refman/5.7/en/date-and-time-functions.html#function_localtime
* TODO: Process other three keywords
*/
NowSymFunc:
	"CURRENT_TIMESTAMP"
|	"LOCALTIME"
|	"LOCALTIMESTAMP"
|	builtinNow

NowSym:
	"CURRENT_TIMESTAMP"
|	"LOCALTIME"
|	"LOCALTIMESTAMP"

SignedLiteral:
	Literal
	{
		$$ = ast.NewValueExpr($1, parser.charset, parser.collation)
	}
|	'+' NumLiteral
	{
		$$ = &ast.UnaryOperationExpr{Op: opcode.Plus, V: ast.NewValueExpr($2, parser.charset, parser.collation)}
	}
|	'-' NumLiteral
	{
		$$ = &ast.UnaryOperationExpr{Op: opcode.Minus, V: ast.NewValueExpr($2, parser.charset, parser.collation)}
	}

NumLiteral:
	intLit
|	floatLit
|	decLit

StatsType:
	"CARDINALITY"
	{
		$$ = ast.StatsTypeCardinality
	}
|	"DEPENDENCY"
	{
		$$ = ast.StatsTypeDependency
	}
|	"CORRELATION"
	{
		$$ = ast.StatsTypeCorrelation
	}

BindingStatusType:
	"ENABLED"
	{
		$$ = ast.BindingStatusTypeEnabled
	}
|	"DISABLED"
	{
		$$ = ast.BindingStatusTypeDisabled
	}

CreateStatisticsStmt:
	"CREATE" "STATISTICS" IfNotExists Identifier '(' StatsType ')' "ON" TableName '(' ColumnNameList ')'
	{
		$$ = &ast.CreateStatisticsStmt{
			IfNotExists: $3.(bool),
			StatsName:   $4,
			StatsType:   $6.(uint8),
			Table:       $9.(*ast.TableName),
			Columns:     $11.([]*ast.ColumnName),
		}
	}

DropStatisticsStmt:
	"DROP" "STATISTICS" Identifier
	{
		$$ = &ast.DropStatisticsStmt{StatsName: $3}
	}

/**************************************CreateIndexStmt***************************************
 * See https://dev.mysql.com/doc/refman/8.0/en/create-index.html
 *
 * TYPE type_name is recognized as a synonym for USING type_name. However, USING is the preferred form.
 *
 * CREATE [UNIQUE | FULLTEXT | SPATIAL] INDEX index_name
 *     [index_type]
 *     ON tbl_name (key_part,...)
 *     [index_option]
 *     [algorithm_option | lock_option] ...
 *
 * key_part: {col_name [(length)] | (expr)} [ASC | DESC]
 *
 * index_option:
 *     KEY_BLOCK_SIZE [=] value
 *   | index_type
 *   | WITH PARSER parser_name
 *   | COMMENT 'string'
 *   | {VISIBLE | INVISIBLE}
 *
 * index_type:
 *     USING {BTREE | HASH}
 *
 * algorithm_option:
 *     ALGORITHM [=] {DEFAULT | INPLACE | COPY}
 *
 * lock_option:
 *     LOCK [=] {DEFAULT | NONE | SHARED | EXCLUSIVE}
 *******************************************************************************************/
CreateIndexStmt:
	"CREATE" IndexKeyTypeOpt "INDEX" IfNotExists Identifier IndexTypeOpt "ON" TableName '(' IndexPartSpecificationList ')' IndexOptionList IndexLockAndAlgorithmOpt
	{
		var indexOption *ast.IndexOption
		if $12 != nil {
			indexOption = $12.(*ast.IndexOption)
			if indexOption.Tp == model.IndexTypeInvalid {
				if $6 != nil {
					indexOption.Tp = $6.(model.IndexType)
				}
			}
		} else {
			indexOption = &ast.IndexOption{}
			if $6 != nil {
				indexOption.Tp = $6.(model.IndexType)
			}
		}
		var indexLockAndAlgorithm *ast.IndexLockAndAlgorithm
		if $13 != nil {
			indexLockAndAlgorithm = $13.(*ast.IndexLockAndAlgorithm)
			if indexLockAndAlgorithm.LockTp == ast.LockTypeDefault && indexLockAndAlgorithm.AlgorithmTp == ast.AlgorithmTypeDefault {
				indexLockAndAlgorithm = nil
			}
		}
		$$ = &ast.CreateIndexStmt{
			IfNotExists:             $4.(bool),
			IndexName:               $5,
			Table:                   $8.(*ast.TableName),
			IndexPartSpecifications: $10.([]*ast.IndexPartSpecification),
			IndexOption:             indexOption,
			KeyType:                 $2.(ast.IndexKeyType),
			LockAlg:                 indexLockAndAlgorithm,
		}
	}

IndexPartSpecificationListOpt:
	{
		$$ = ([]*ast.IndexPartSpecification)(nil)
	}
|	'(' IndexPartSpecificationList ')'
	{
		$$ = $2
	}

IndexPartSpecificationList:
	IndexPartSpecification
	{
		$$ = []*ast.IndexPartSpecification{$1.(*ast.IndexPartSpecification)}
	}
|	IndexPartSpecificationList ',' IndexPartSpecification
	{
		$$ = append($1.([]*ast.IndexPartSpecification), $3.(*ast.IndexPartSpecification))
	}

IndexPartSpecification:
	ColumnName OptFieldLen OptOrder
	{
		// Order is parsed but just ignored as MySQL did.
		$$ = &ast.IndexPartSpecification{Column: $1.(*ast.ColumnName), Length: $2.(int)}
	}
|	'(' Expression ')' OptOrder
	{
		$$ = &ast.IndexPartSpecification{Expr: $2}
	}

IndexLockAndAlgorithmOpt:
	{
		$$ = nil
	}
|	LockClause
	{
		$$ = &ast.IndexLockAndAlgorithm{
			LockTp:      $1.(ast.LockType),
			AlgorithmTp: ast.AlgorithmTypeDefault,
		}
	}
|	AlgorithmClause
	{
		$$ = &ast.IndexLockAndAlgorithm{
			LockTp:      ast.LockTypeDefault,
			AlgorithmTp: $1.(ast.AlgorithmType),
		}
	}
|	LockClause AlgorithmClause
	{
		$$ = &ast.IndexLockAndAlgorithm{
			LockTp:      $1.(ast.LockType),
			AlgorithmTp: $2.(ast.AlgorithmType),
		}
	}
|	AlgorithmClause LockClause
	{
		$$ = &ast.IndexLockAndAlgorithm{
			LockTp:      $2.(ast.LockType),
			AlgorithmTp: $1.(ast.AlgorithmType),
		}
	}

IndexKeyTypeOpt:
	{
		$$ = ast.IndexKeyTypeNone
	}
|	"UNIQUE"
	{
		$$ = ast.IndexKeyTypeUnique
	}
|	"SPATIAL"
	{
		$$ = ast.IndexKeyTypeSpatial
	}
|	"FULLTEXT"
	{
		$$ = ast.IndexKeyTypeFullText
	}

/**************************************AlterDatabaseStmt***************************************
 * See https://dev.mysql.com/doc/refman/5.7/en/alter-database.html
 * 'ALTER DATABASE ... UPGRADE DATA DIRECTORY NAME' is not supported yet.
 *
 *  ALTER {DATABASE | SCHEMA} [db_name]
 *   alter_specification ...
 *
 *  alter_specification:
 *   [DEFAULT] CHARACTER SET [=] charset_name
 * | [DEFAULT] COLLATE [=] collation_name
 * | [DEFAULT] ENCRYPTION [=] {'Y' | 'N'}
 *******************************************************************************************/
AlterDatabaseStmt:
	"ALTER" DatabaseSym DBName DatabaseOptionList
	{
		$$ = &ast.AlterDatabaseStmt{
			Name:                 $3,
			AlterDefaultDatabase: false,
			Options:              $4.([]*ast.DatabaseOption),
		}
	}
|	"ALTER" DatabaseSym DatabaseOptionList
	{
		$$ = &ast.AlterDatabaseStmt{
			Name:                 "",
			AlterDefaultDatabase: true,
			Options:              $3.([]*ast.DatabaseOption),
		}
	}

/*******************************************************************
 *
 *  Create Database Statement
 *  CREATE {DATABASE | SCHEMA} [IF NOT EXISTS] db_name
 *      [create_specification] ...
 *
 *  create_specification:
 *      [DEFAULT] CHARACTER SET [=] charset_name
 *    | [DEFAULT] COLLATE [=] collation_name
 *    | [DEFAULT] ENCRYPTION [=] {'Y' | 'N'}
 *******************************************************************/
CreateDatabaseStmt:
	"CREATE" DatabaseSym IfNotExists DBName DatabaseOptionListOpt
	{
		$$ = &ast.CreateDatabaseStmt{
			IfNotExists: $3.(bool),
			Name:        $4,
			Options:     $5.([]*ast.DatabaseOption),
		}
	}

DBName:
	Identifier

PolicyName:
	Identifier

DatabaseOption:
	DefaultKwdOpt CharsetKw EqOpt CharsetName
	{
		$$ = &ast.DatabaseOption{Tp: ast.DatabaseOptionCharset, Value: $4}
	}
|	DefaultKwdOpt "COLLATE" EqOpt CollationName
	{
		$$ = &ast.DatabaseOption{Tp: ast.DatabaseOptionCollate, Value: $4}
	}
|	DefaultKwdOpt "ENCRYPTION" EqOpt EncryptionOpt
	{
		$$ = &ast.DatabaseOption{Tp: ast.DatabaseOptionEncryption, Value: $4}
	}
|	DefaultKwdOpt PlacementPolicyOption
	{
		placementOptions := $2.(*ast.PlacementOption)
		$$ = &ast.DatabaseOption{
			// offset trick, enums are identical but of different type
			Tp:        ast.DatabaseOptionType(placementOptions.Tp),
			Value:     placementOptions.StrValue,
			UintValue: placementOptions.UintValue,
		}
	}
|	PlacementPolicyOption
	{
		placementOptions := $1.(*ast.PlacementOption)
		$$ = &ast.DatabaseOption{
			// offset trick, enums are identical but of different type
			Tp:        ast.DatabaseOptionType(placementOptions.Tp),
			Value:     placementOptions.StrValue,
			UintValue: placementOptions.UintValue,
		}
	}
|	"SET" "TIFLASH" "REPLICA" LengthNum LocationLabelList
	{
		tiflashReplicaSpec := &ast.TiFlashReplicaSpec{
			Count:  $4.(uint64),
			Labels: $5.([]string),
		}
		$$ = &ast.DatabaseOption{
			Tp:             ast.DatabaseSetTiFlashReplica,
			TiFlashReplica: tiflashReplicaSpec,
		}
	}

DatabaseOptionListOpt:
	{
		$$ = []*ast.DatabaseOption{}
	}
|	DatabaseOptionList

DatabaseOptionList:
	DatabaseOption
	{
		$$ = []*ast.DatabaseOption{$1.(*ast.DatabaseOption)}
	}
|	DatabaseOptionList DatabaseOption
	{
		$$ = append($1.([]*ast.DatabaseOption), $2.(*ast.DatabaseOption))
	}

/*******************************************************************
 *
 *  Create Table Statement
 *
 *  Example:
 *      CREATE TABLE Persons
 *      (
 *          P_Id int NOT NULL,
 *          LastName varchar(255) NOT NULL,
 *          FirstName varchar(255),
 *          Address varchar(255),
 *          City varchar(255),
 *          PRIMARY KEY (P_Id)
 *      )
 *******************************************************************/
CreateTableStmt:
	"CREATE" OptTemporary "TABLE" IfNotExists TableName TableElementListOpt CreateTableOptionListOpt PartitionOpt DuplicateOpt AsOpt CreateTableSelectOpt OnCommitOpt
	{
		stmt := $6.(*ast.CreateTableStmt)
		stmt.Table = $5.(*ast.TableName)
		stmt.IfNotExists = $4.(bool)
		stmt.TemporaryKeyword = $2.(ast.TemporaryKeyword)
		stmt.Options = $7.([]*ast.TableOption)
		if $8 != nil {
			stmt.Partition = $8.(*ast.PartitionOptions)
		}
		stmt.OnDuplicate = $9.(ast.OnDuplicateKeyHandlingType)
		stmt.Select = $11.(*ast.CreateTableStmt).Select
		if ($12 != nil && stmt.TemporaryKeyword != ast.TemporaryGlobal) || (stmt.TemporaryKeyword == ast.TemporaryGlobal && $12 == nil) {
			yylex.AppendError(yylex.Errorf("GLOBAL TEMPORARY and ON COMMIT DELETE ROWS must appear together"))
		} else {
			if stmt.TemporaryKeyword == ast.TemporaryGlobal {
				stmt.OnCommitDelete = $12.(bool)
			}
		}
		$$ = stmt
	}
|	"CREATE" OptTemporary "TABLE" IfNotExists TableName LikeTableWithOrWithoutParen OnCommitOpt
	{
		tmp := &ast.CreateTableStmt{
			Table:            $5.(*ast.TableName),
			ReferTable:       $6.(*ast.TableName),
			IfNotExists:      $4.(bool),
			TemporaryKeyword: $2.(ast.TemporaryKeyword),
		}
		if ($7 != nil && tmp.TemporaryKeyword != ast.TemporaryGlobal) || (tmp.TemporaryKeyword == ast.TemporaryGlobal && $7 == nil) {
			yylex.AppendError(yylex.Errorf("GLOBAL TEMPORARY and ON COMMIT DELETE ROWS must appear together"))
		} else {
			if tmp.TemporaryKeyword == ast.TemporaryGlobal {
				tmp.OnCommitDelete = $7.(bool)
			}
		}
		$$ = tmp
	}

OnCommitOpt:
	{
		$$ = nil
	}
|	"ON" "COMMIT" "DELETE" "ROWS"
	{
		$$ = true
	}
|	"ON" "COMMIT" "PRESERVE" "ROWS"
	{
		$$ = false
	}

DefaultKwdOpt:
	%prec lowerThanCharsetKwd
	{}
|	"DEFAULT"

PartitionOpt:
	{
		$$ = nil
	}
|	"PARTITION" "BY" PartitionMethod PartitionNumOpt SubPartitionOpt PartitionDefinitionListOpt
	{
		method := $3.(*ast.PartitionMethod)
		method.Num = $4.(uint64)
		sub, _ := $5.(*ast.PartitionMethod)
		defs, _ := $6.([]*ast.PartitionDefinition)
		opt := &ast.PartitionOptions{
			PartitionMethod: *method,
			Sub:             sub,
			Definitions:     defs,
		}
		if err := opt.Validate(); err != nil {
			yylex.AppendError(err)
			return 1
		}
		$$ = opt
	}

SubPartitionMethod:
	LinearOpt "KEY" PartitionKeyAlgorithmOpt '(' ColumnNameListOpt ')'
	{
		keyAlgorithm, _ := $3.(*ast.PartitionKeyAlgorithm)
		$$ = &ast.PartitionMethod{
			Tp:           model.PartitionTypeKey,
			Linear:       len($1) != 0,
			ColumnNames:  $5.([]*ast.ColumnName),
			KeyAlgorithm: keyAlgorithm,
		}
	}
|	LinearOpt "HASH" '(' BitExpr ')'
	{
		$$ = &ast.PartitionMethod{
			Tp:     model.PartitionTypeHash,
			Linear: len($1) != 0,
			Expr:   $4.(ast.ExprNode),
		}
	}

PartitionKeyAlgorithmOpt:
	/* empty */
	{
		$$ = nil
	}
|	"ALGORITHM" eq NUM
	{
		tp := getUint64FromNUM($3)
		if tp != 1 && tp != 2 {
			yylex.AppendError(ErrSyntax)
			return 1
		}
		$$ = &ast.PartitionKeyAlgorithm{
			Type: tp,
		}
	}

PartitionMethod:
	SubPartitionMethod
|	"RANGE" '(' BitExpr ')'
	{
		$$ = &ast.PartitionMethod{
			Tp:   model.PartitionTypeRange,
			Expr: $3.(ast.ExprNode),
		}
	}
|	"RANGE" FieldsOrColumns '(' ColumnNameList ')'
	{
		$$ = &ast.PartitionMethod{
			Tp:          model.PartitionTypeRange,
			ColumnNames: $4.([]*ast.ColumnName),
		}
	}
|	"LIST" '(' BitExpr ')'
	{
		$$ = &ast.PartitionMethod{
			Tp:   model.PartitionTypeList,
			Expr: $3.(ast.ExprNode),
		}
	}
|	"LIST" FieldsOrColumns '(' ColumnNameList ')'
	{
		$$ = &ast.PartitionMethod{
			Tp:          model.PartitionTypeList,
			ColumnNames: $4.([]*ast.ColumnName),
		}
	}
|	"SYSTEM_TIME" "INTERVAL" Expression TimeUnit
	{
		$$ = &ast.PartitionMethod{
			Tp:   model.PartitionTypeSystemTime,
			Expr: $3.(ast.ExprNode),
			Unit: $4.(ast.TimeUnitType),
		}
	}
|	"SYSTEM_TIME" "LIMIT" LengthNum
	{
		$$ = &ast.PartitionMethod{
			Tp:    model.PartitionTypeSystemTime,
			Limit: $3.(uint64),
		}
	}
|	"SYSTEM_TIME"
	{
		$$ = &ast.PartitionMethod{
			Tp: model.PartitionTypeSystemTime,
		}
	}

LinearOpt:
	{
		$$ = ""
	}
|	"LINEAR"

SubPartitionOpt:
	{
		$$ = nil
	}
|	"SUBPARTITION" "BY" SubPartitionMethod SubPartitionNumOpt
	{
		method := $3.(*ast.PartitionMethod)
		method.Num = $4.(uint64)
		$$ = method
	}

SubPartitionNumOpt:
	{
		$$ = uint64(0)
	}
|	"SUBPARTITIONS" LengthNum
	{
		res := $2.(uint64)
		if res == 0 {
			yylex.AppendError(ast.ErrNoParts.GenWithStackByArgs("subpartitions"))
			return 1
		}
		$$ = res
	}

PartitionNumOpt:
	{
		$$ = uint64(0)
	}
|	"PARTITIONS" LengthNum
	{
		res := $2.(uint64)
		if res == 0 {
			yylex.AppendError(ast.ErrNoParts.GenWithStackByArgs("partitions"))
			return 1
		}
		$$ = res
	}

PartitionDefinitionListOpt:
	/* empty */ %prec lowerThanCreateTableSelect
	{
		$$ = nil
	}
|	'(' PartitionDefinitionList ')'
	{
		$$ = $2.([]*ast.PartitionDefinition)
	}

PartitionDefinitionList:
	PartitionDefinition
	{
		$$ = []*ast.PartitionDefinition{$1.(*ast.PartitionDefinition)}
	}
|	PartitionDefinitionList ',' PartitionDefinition
	{
		$$ = append($1.([]*ast.PartitionDefinition), $3.(*ast.PartitionDefinition))
	}

PartitionDefinition:
	"PARTITION" Identifier PartDefValuesOpt PartDefOptionList SubPartDefinitionListOpt
	{
		$$ = &ast.PartitionDefinition{
			Name:    model.NewCIStr($2),
			Clause:  $3.(ast.PartitionDefinitionClause),
			Options: $4.([]*ast.TableOption),
			Sub:     $5.([]*ast.SubPartitionDefinition),
		}
	}

SubPartDefinitionListOpt:
	/*empty*/
	{
		$$ = make([]*ast.SubPartitionDefinition, 0)
	}
|	'(' SubPartDefinitionList ')'
	{
		$$ = $2
	}

SubPartDefinitionList:
	SubPartDefinition
	{
		$$ = []*ast.SubPartitionDefinition{$1.(*ast.SubPartitionDefinition)}
	}
|	SubPartDefinitionList ',' SubPartDefinition
	{
		list := $1.([]*ast.SubPartitionDefinition)
		$$ = append(list, $3.(*ast.SubPartitionDefinition))
	}

SubPartDefinition:
	"SUBPARTITION" Identifier PartDefOptionList
	{
		$$ = &ast.SubPartitionDefinition{
			Name:    model.NewCIStr($2),
			Options: $3.([]*ast.TableOption),
		}
	}

PartDefOptionList:
	/*empty*/
	{
		$$ = make([]*ast.TableOption, 0)
	}
|	PartDefOptionList PartDefOption
	{
		list := $1.([]*ast.TableOption)
		$$ = append(list, $2.(*ast.TableOption))
	}

PartDefOption:
	"COMMENT" EqOpt stringLit
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionComment, StrValue: $3}
	}
|	"ENGINE" EqOpt StringName
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionEngine, StrValue: $3}
	}
|	"STORAGE" "ENGINE" EqOpt StringName
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionEngine, StrValue: $4}
	}
|	"INSERT_METHOD" EqOpt StringName
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionInsertMethod, StrValue: $3}
	}
|	"DATA" "DIRECTORY" EqOpt stringLit
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionDataDirectory, StrValue: $4}
	}
|	"INDEX" "DIRECTORY" EqOpt stringLit
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionIndexDirectory, StrValue: $4}
	}
|	"MAX_ROWS" EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionMaxRows, UintValue: $3.(uint64)}
	}
|	"MIN_ROWS" EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionMinRows, UintValue: $3.(uint64)}
	}
|	"TABLESPACE" EqOpt Identifier
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionTablespace, StrValue: $3}
	}
|	"NODEGROUP" EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionNodegroup, UintValue: $3.(uint64)}
	}
|	PlacementPolicyOption
	{
		placementOptions := $1.(*ast.PlacementOption)
		$$ = &ast.TableOption{
			// offset trick, enums are identical but of different type
			Tp:        ast.TableOptionType(placementOptions.Tp),
			StrValue:  placementOptions.StrValue,
			UintValue: placementOptions.UintValue,
		}
	}

PartDefValuesOpt:
	{
		$$ = &ast.PartitionDefinitionClauseNone{}
	}
|	"VALUES" "LESS" "THAN" "MAXVALUE"
	{
		$$ = &ast.PartitionDefinitionClauseLessThan{
			Exprs: []ast.ExprNode{&ast.MaxValueExpr{}},
		}
	}
|	"VALUES" "LESS" "THAN" '(' MaxValueOrExpressionList ')'
	{
		$$ = &ast.PartitionDefinitionClauseLessThan{
			Exprs: $5.([]ast.ExprNode),
		}
	}
|	"DEFAULT"
	{
		$$ = &ast.PartitionDefinitionClauseIn{}
	}
|	"VALUES" "IN" '(' MaxValueOrExpressionList ')'
	{
		exprs := $4.([]ast.ExprNode)
		values := make([][]ast.ExprNode, 0, len(exprs))
		for _, expr := range exprs {
			if row, ok := expr.(*ast.RowExpr); ok {
				values = append(values, row.Values)
			} else {
				values = append(values, []ast.ExprNode{expr})
			}
		}
		$$ = &ast.PartitionDefinitionClauseIn{Values: values}
	}
|	"HISTORY"
	{
		$$ = &ast.PartitionDefinitionClauseHistory{Current: false}
	}
|	"CURRENT"
	{
		$$ = &ast.PartitionDefinitionClauseHistory{Current: true}
	}

DuplicateOpt:
	{
		$$ = ast.OnDuplicateKeyHandlingError
	}
|	"IGNORE"
	{
		$$ = ast.OnDuplicateKeyHandlingIgnore
	}
|	"REPLACE"
	{
		$$ = ast.OnDuplicateKeyHandlingReplace
	}

AsOpt:
	{}
|	"AS"
	{}

CreateTableSelectOpt:
	/* empty */
	{
		$$ = &ast.CreateTableStmt{}
	}
|	SetOprStmt
	{
		$$ = &ast.CreateTableStmt{Select: $1.(ast.ResultSetNode)}
	}
|	SelectStmt
	{
		$$ = &ast.CreateTableStmt{Select: $1.(ast.ResultSetNode)}
	}
|	SelectStmtWithClause
	{
		$$ = &ast.CreateTableStmt{Select: $1.(ast.ResultSetNode)}
	}
|	SubSelect
	{
		var sel ast.ResultSetNode
		switch x := $1.(*ast.SubqueryExpr).Query.(type) {
		case *ast.SelectStmt:
			x.IsInBraces = true
			sel = x
		case *ast.SetOprStmt:
			x.IsInBraces = true
			sel = x
		}
		$$ = &ast.CreateTableStmt{Select: sel}
	}

CreateViewSelectOpt:
	SetOprStmt
|	SelectStmt
|	SelectStmtWithClause
|	SubSelect
	{
		var sel ast.StmtNode
		switch x := $1.(*ast.SubqueryExpr).Query.(type) {
		case *ast.SelectStmt:
			x.IsInBraces = true
			sel = x
		case *ast.SetOprStmt:
			x.IsInBraces = true
			sel = x
		}
		$$ = sel
	}

LikeTableWithOrWithoutParen:
	"LIKE" TableName
	{
		$$ = $2
	}
|	'(' "LIKE" TableName ')'
	{
		$$ = $3
	}

/*******************************************************************
 *
 *  Create View Statement
 *
 *  Example:
 *      CREATE VIEW OR REPLACE ALGORITHM = MERGE DEFINER="root@localhost" SQL SECURITY = definer view_name (col1,col2)
 *          as select Col1,Col2 from table WITH LOCAL CHECK OPTION
 *******************************************************************/
CreateViewStmt:
	"CREATE" OrReplace ViewAlgorithm ViewDefiner ViewSQLSecurity "VIEW" ViewName ViewFieldList "AS" CreateViewSelectOpt ViewCheckOption
	{
		startOffset := parser.startOffset(&yyS[yypt-1])
		selStmt := $10.(ast.StmtNode)
		selStmt.SetText(parser.lexer.client, strings.TrimSpace(parser.src[startOffset:]))
		x := &ast.CreateViewStmt{
			OrReplace: $2.(bool),
			ViewName:  $7.(*ast.TableName),
			Select:    selStmt,
			Algorithm: $3.(model.ViewAlgorithm),
			Definer:   $4.(*auth.UserIdentity),
			Security:  $5.(model.ViewSecurity),
		}
		if $8 != nil {
			x.Cols = $8.([]model.CIStr)
		}
		if $11 != nil {
			x.CheckOption = $11.(model.ViewCheckOption)
			endOffset := parser.startOffset(&yyS[yypt])
			selStmt.SetText(parser.lexer.client, strings.TrimSpace(parser.src[startOffset:endOffset]))
		} else {
			x.CheckOption = model.CheckOptionCascaded
		}
		$$ = x
	}

OrReplace:
	/* EMPTY */
	{
		$$ = false
	}
|	"OR" "REPLACE"
	{
		$$ = true
	}

ViewAlgorithm:
	/* EMPTY */
	{
		$$ = model.AlgorithmUndefined
	}
|	"ALGORITHM" "=" "UNDEFINED"
	{
		$$ = model.AlgorithmUndefined
	}
|	"ALGORITHM" "=" "MERGE"
	{
		$$ = model.AlgorithmMerge
	}
|	"ALGORITHM" "=" "TEMPTABLE"
	{
		$$ = model.AlgorithmTemptable
	}

ViewDefiner:
	/* EMPTY */
	{
		$$ = &auth.UserIdentity{CurrentUser: true}
	}
|	"DEFINER" "=" Username
	{
		$$ = $3
	}

ViewSQLSecurity:
	/* EMPTY */
	{
		$$ = model.SecurityDefiner
	}
|	"SQL" "SECURITY" "DEFINER"
	{
		$$ = model.SecurityDefiner
	}
|	"SQL" "SECURITY" "INVOKER"
	{
		$$ = model.SecurityInvoker
	}

ViewName:
	TableName

ViewFieldList:
	/* Empty */
	{
		$$ = nil
	}
|	'(' ColumnList ')'
	{
		$$ = $2.([]model.CIStr)
	}

ColumnList:
	Identifier
	{
		$$ = []model.CIStr{model.NewCIStr($1)}
	}
|	ColumnList ',' Identifier
	{
		$$ = append($1.([]model.CIStr), model.NewCIStr($3))
	}

ViewCheckOption:
	/* EMPTY */
	{
		$$ = nil
	}
|	"WITH" "CASCADED" "CHECK" "OPTION"
	{
		$$ = model.CheckOptionCascaded
	}
|	"WITH" "LOCAL" "CHECK" "OPTION"
	{
		$$ = model.CheckOptionLocal
	}

/******************************************************************
 * Do statement
 * See https://dev.mysql.com/doc/refman/5.7/en/do.html
 ******************************************************************/
DoStmt:
	"DO" ExpressionList
	{
		$$ = &ast.DoStmt{
			Exprs: $2.([]ast.ExprNode),
		}
	}

/*******************************************************************
 *
 *  Delete Statement
 *
 *******************************************************************/
DeleteWithoutUsingStmt:
	"DELETE" TableOptimizerHintsOpt PriorityOpt QuickOptional IgnoreOptional "FROM" TableName PartitionNameListOpt TableAsNameOpt IndexHintListOpt WhereClauseOptional OrderByOptional LimitClause
	{
		// Single Table
		tn := $7.(*ast.TableName)
		tn.IndexHints = $10.([]*ast.IndexHint)
		tn.PartitionNames = $8.([]model.CIStr)
		join := &ast.Join{Left: &ast.TableSource{Source: tn, AsName: $9.(model.CIStr)}, Right: nil}
		x := &ast.DeleteStmt{
			TableRefs: &ast.TableRefsClause{TableRefs: join},
			Priority:  $3.(mysql.PriorityEnum),
			Quick:     $4.(bool),
			IgnoreErr: $5.(bool),
		}
		if $2 != nil {
			x.TableHints = $2.([]*ast.TableOptimizerHint)
		}
		if $11 != nil {
			x.Where = $11.(ast.ExprNode)
		}
		if $12 != nil {
			x.Order = $12.(*ast.OrderByClause)
		}
		if $13 != nil {
			x.Limit = $13.(*ast.Limit)
		}

		$$ = x
	}
|	"DELETE" TableOptimizerHintsOpt PriorityOpt QuickOptional IgnoreOptional TableAliasRefList "FROM" TableRefs WhereClauseOptional
	{
		// Multiple Table
		x := &ast.DeleteStmt{
			Priority:     $3.(mysql.PriorityEnum),
			Quick:        $4.(bool),
			IgnoreErr:    $5.(bool),
			IsMultiTable: true,
			BeforeFrom:   true,
			Tables:       &ast.DeleteTableList{Tables: $6.([]*ast.TableName)},
			TableRefs:    &ast.TableRefsClause{TableRefs: $8.(*ast.Join)},
		}
		if $2 != nil {
			x.TableHints = $2.([]*ast.TableOptimizerHint)
		}
		if $9 != nil {
			x.Where = $9.(ast.ExprNode)
		}
		$$ = x
	}

DeleteWithUsingStmt:
	"DELETE" TableOptimizerHintsOpt PriorityOpt QuickOptional IgnoreOptional "FROM" TableAliasRefList "USING" TableRefs WhereClauseOptional
	{
		// Multiple Table
		x := &ast.DeleteStmt{
			Priority:     $3.(mysql.PriorityEnum),
			Quick:        $4.(bool),
			IgnoreErr:    $5.(bool),
			IsMultiTable: true,
			Tables:       &ast.DeleteTableList{Tables: $7.([]*ast.TableName)},
			TableRefs:    &ast.TableRefsClause{TableRefs: $9.(*ast.Join)},
		}
		if $2 != nil {
			x.TableHints = $2.([]*ast.TableOptimizerHint)
		}
		if $10 != nil {
			x.Where = $10.(ast.ExprNode)
		}
		$$ = x
	}

DeleteFromStmt:
	DeleteWithoutUsingStmt
|	DeleteWithUsingStmt
|	WithClause DeleteWithoutUsingStmt
	{
		d := $2.(*ast.DeleteStmt)
		d.With = $1.(*ast.WithClause)
		$$ = d
	}
|	WithClause DeleteWithUsingStmt
	{
		d := $2.(*ast.DeleteStmt)
		d.With = $1.(*ast.WithClause)
		$$ = d
	}

DatabaseSym:
	"DATABASE"

DropDatabaseStmt:
	"DROP" DatabaseSym IfExists DBName
	{
		$$ = &ast.DropDatabaseStmt{IfExists: $3.(bool), Name: $4}
	}

/******************************************************************
 * Drop Index Statement
 * See https://dev.mysql.com/doc/refman/8.0/en/drop-index.html
 *
 *  DROP INDEX index_name ON tbl_name
 *      [algorithm_option | lock_option] ...
 *
 *  algorithm_option:
 *      ALGORITHM [=] {DEFAULT|INPLACE|COPY}
 *
 *  lock_option:
 *      LOCK [=] {DEFAULT|NONE|SHARED|EXCLUSIVE}
 ******************************************************************/
DropIndexStmt:
	"DROP" "INDEX" IfExists Identifier "ON" TableName IndexLockAndAlgorithmOpt
	{
		var indexLockAndAlgorithm *ast.IndexLockAndAlgorithm
		if $7 != nil {
			indexLockAndAlgorithm = $7.(*ast.IndexLockAndAlgorithm)
			if indexLockAndAlgorithm.LockTp == ast.LockTypeDefault && indexLockAndAlgorithm.AlgorithmTp == ast.AlgorithmTypeDefault {
				indexLockAndAlgorithm = nil
			}
		}
		$$ = &ast.DropIndexStmt{IfExists: $3.(bool), IndexName: $4, Table: $6.(*ast.TableName), LockAlg: indexLockAndAlgorithm}
	}

DropTableStmt:
	"DROP" OptTemporary TableOrTables IfExists TableNameList RestrictOrCascadeOpt
	{
		$$ = &ast.DropTableStmt{IfExists: $4.(bool), Tables: $5.([]*ast.TableName), IsView: false, TemporaryKeyword: $2.(ast.TemporaryKeyword)}
	}

OptTemporary:
	/* empty */
	{
		$$ = ast.TemporaryNone
	}
|	"TEMPORARY"
	{
		$$ = ast.TemporaryLocal
	}
|	"GLOBAL" "TEMPORARY"
	{
		$$ = ast.TemporaryGlobal
	}

DropViewStmt:
	"DROP" "VIEW" TableNameList RestrictOrCascadeOpt
	{
		$$ = &ast.DropTableStmt{Tables: $3.([]*ast.TableName), IsView: true}
	}
|	"DROP" "VIEW" "IF" "EXISTS" TableNameList RestrictOrCascadeOpt
	{
		$$ = &ast.DropTableStmt{IfExists: true, Tables: $5.([]*ast.TableName), IsView: true}
	}

DropUserStmt:
	"DROP" "USER" UsernameList
	{
		$$ = &ast.DropUserStmt{IsDropRole: false, IfExists: false, UserList: $3.([]*auth.UserIdentity)}
	}
|	"DROP" "USER" "IF" "EXISTS" UsernameList
	{
		$$ = &ast.DropUserStmt{IsDropRole: false, IfExists: true, UserList: $5.([]*auth.UserIdentity)}
	}

DropRoleStmt:
	"DROP" "ROLE" RolenameList
	{
		tmp := make([]*auth.UserIdentity, 0, 10)
		roleList := $3.([]*auth.RoleIdentity)
		for _, r := range roleList {
			tmp = append(tmp, &auth.UserIdentity{Username: r.Username, Hostname: r.Hostname})
		}
		$$ = &ast.DropUserStmt{IsDropRole: true, IfExists: false, UserList: tmp}
	}
|	"DROP" "ROLE" "IF" "EXISTS" RolenameList
	{
		tmp := make([]*auth.UserIdentity, 0, 10)
		roleList := $5.([]*auth.RoleIdentity)
		for _, r := range roleList {
			tmp = append(tmp, &auth.UserIdentity{Username: r.Username, Hostname: r.Hostname})
		}
		$$ = &ast.DropUserStmt{IsDropRole: true, IfExists: true, UserList: tmp}
	}

DropStatsStmt:
	"DROP" "STATS" TableName
	{
		$$ = &ast.DropStatsStmt{Table: $3.(*ast.TableName)}
	}
|	"DROP" "STATS" TableName "PARTITION" PartitionNameList
	{
		$$ = &ast.DropStatsStmt{
			Table:          $3.(*ast.TableName),
			PartitionNames: $5.([]model.CIStr),
		}
	}
|	"DROP" "STATS" TableName "GLOBAL"
	{
		$$ = &ast.DropStatsStmt{
			Table:         $3.(*ast.TableName),
			IsGlobalStats: true,
		}
	}

RestrictOrCascadeOpt:
	{}
|	"RESTRICT"
|	"CASCADE"

TableOrTables:
	"TABLE"
|	"TABLES"

EqOpt:
	{}
|	eq

EmptyStmt:
	/* EMPTY */
	{
		$$ = nil
	}

TraceStmt:
	"TRACE" TraceableStmt
	{
		$$ = &ast.TraceStmt{
			Stmt:      $2,
			Format:    "row",
			TracePlan: false,
		}
		startOffset := parser.startOffset(&yyS[yypt])
		$2.SetText(parser.lexer.client, string(parser.src[startOffset:]))
	}
|	"TRACE" "FORMAT" "=" stringLit TraceableStmt
	{
		$$ = &ast.TraceStmt{
			Stmt:      $5,
			Format:    $4,
			TracePlan: false,
		}
		startOffset := parser.startOffset(&yyS[yypt])
		$5.SetText(parser.lexer.client, string(parser.src[startOffset:]))
	}
|	"TRACE" "PLAN" TraceableStmt
	{
		$$ = &ast.TraceStmt{
			Stmt:      $3,
			TracePlan: true,
		}
		startOffset := parser.startOffset(&yyS[yypt])
		$3.SetText(parser.lexer.client, string(parser.src[startOffset:]))
	}
|	"TRACE" "PLAN" "TARGET" "=" stringLit TraceableStmt
	{
		$$ = &ast.TraceStmt{
			Stmt:            $6,
			TracePlan:       true,
			TracePlanTarget: $5,
		}
		startOffset := parser.startOffset(&yyS[yypt])
		$6.SetText(parser.lexer.client, string(parser.src[startOffset:]))
	}

ExplainSym:
	"EXPLAIN"
|	"DESCRIBE"
|	"DESC"

ExplainStmt:
	ExplainSym TableName
	{
		$$ = &ast.ExplainStmt{
			Stmt: &ast.ShowStmt{
				Tp:    ast.ShowColumns,
				Table: $2.(*ast.TableName),
			},
		}
	}
|	ExplainSym TableName ColumnName
	{
		$$ = &ast.ExplainStmt{
			Stmt: &ast.ShowStmt{
				Tp:     ast.ShowColumns,
				Table:  $2.(*ast.TableName),
				Column: $3.(*ast.ColumnName),
			},
		}
	}
|	ExplainSym ExplainableStmt
	{
		$$ = &ast.ExplainStmt{
			Stmt:   $2,
			Format: "row",
		}
	}
|	ExplainSym "FOR" "CONNECTION" NUM
	{
		$$ = &ast.ExplainForStmt{
			Format:       "row",
			ConnectionID: getUint64FromNUM($4),
		}
	}
|	ExplainSym "FORMAT" "=" stringLit "FOR" "CONNECTION" NUM
	{
		$$ = &ast.ExplainForStmt{
			Format:       $4,
			ConnectionID: getUint64FromNUM($7),
		}
	}
|	ExplainSym "FORMAT" "=" stringLit ExplainableStmt
	{
		$$ = &ast.ExplainStmt{
			Stmt:   $5,
			Format: $4,
		}
	}
|	ExplainSym "FORMAT" "=" ExplainFormatType "FOR" "CONNECTION" NUM
	{
		$$ = &ast.ExplainForStmt{
			Format:       $4,
			ConnectionID: getUint64FromNUM($7),
		}
	}
|	ExplainSym "FORMAT" "=" ExplainFormatType ExplainableStmt
	{
		$$ = &ast.ExplainStmt{
			Stmt:   $5,
			Format: $4,
		}
	}
|	ExplainSym "ANALYZE" ExplainableStmt
	{
		$$ = &ast.ExplainStmt{
			Stmt:    $3,
			Format:  "row",
			Analyze: true,
		}
	}
|	ExplainSym "ANALYZE" "FORMAT" "=" ExplainFormatType ExplainableStmt
	{
		$$ = &ast.ExplainStmt{
			Stmt:    $6,
			Format:  $5,
			Analyze: true,
		}
	}
|	ExplainSym "ANALYZE" "FORMAT" "=" stringLit ExplainableStmt
	{
		$$ = &ast.ExplainStmt{
			Stmt:    $6,
			Format:  $5,
			Analyze: true,
		}
	}

ExplainFormatType:
	"TRADITIONAL"
|	"JSON"
|	"ROW"
|	"DOT"
|	"BRIEF"
|	"VERBOSE"
|	"TRUE_CARD_COST"

/*******************************************************************
 * Backup / restore / import statements
 *
 *	BACKUP DATABASE [ * | db1, db2, db3 ] TO 'scheme://location' [ options... ]
 *	BACKUP TABLE [ db1.tbl1, db2.tbl2 ] TO 'scheme://location' [ options... ]
 *	RESTORE DATABASE [ * | db1, db2, db3 ] FROM 'scheme://location' [ options... ]
 *	RESTORE TABLE [ db1.tbl1, db2.tbl2 ] FROM 'scheme://location' [ options... ]
 */
BRIEStmt:
	"BACKUP" BRIETables "TO" stringLit BRIEOptions
	{
		stmt := $2.(*ast.BRIEStmt)
		stmt.Kind = ast.BRIEKindBackup
		stmt.Storage = $4
		stmt.Options = $5.([]*ast.BRIEOption)
		$$ = stmt
	}
|	"RESTORE" BRIETables "FROM" stringLit BRIEOptions
	{
		stmt := $2.(*ast.BRIEStmt)
		stmt.Kind = ast.BRIEKindRestore
		stmt.Storage = $4
		stmt.Options = $5.([]*ast.BRIEOption)
		$$ = stmt
	}

BRIETables:
	DatabaseSym '*'
	{
		$$ = &ast.BRIEStmt{}
	}
|	DatabaseSym DBNameList
	{
		$$ = &ast.BRIEStmt{Schemas: $2.([]string)}
	}
|	"TABLE" TableNameList
	{
		$$ = &ast.BRIEStmt{Tables: $2.([]*ast.TableName)}
	}

DBNameList:
	DBName
	{
		$$ = []string{$1}
	}
|	DBNameList ',' DBName
	{
		$$ = append($1.([]string), $3)
	}

BRIEOptions:
	%prec empty
	{
		$$ = []*ast.BRIEOption{}
	}
|	BRIEOptions BRIEOption
	{
		$$ = append($1.([]*ast.BRIEOption), $2.(*ast.BRIEOption))
	}

BRIEIntegerOptionName:
	"CONCURRENCY"
	{
		$$ = ast.BRIEOptionConcurrency
	}
|	"RESUME"
	{
		$$ = ast.BRIEOptionResume
	}

BRIEBooleanOptionName:
	"SEND_CREDENTIALS_TO_TIKV"
	{
		$$ = ast.BRIEOptionSendCreds
	}
|	"ONLINE"
	{
		$$ = ast.BRIEOptionOnline
	}
|	"CHECKPOINT"
	{
		$$ = ast.BRIEOptionCheckpoint
	}
|	"SKIP_SCHEMA_FILES"
	{
		$$ = ast.BRIEOptionSkipSchemaFiles
	}
|	"STRICT_FORMAT"
	{
		$$ = ast.BRIEOptionStrictFormat
	}
|	"CSV_NOT_NULL"
	{
		$$ = ast.BRIEOptionCSVNotNull
	}
|	"CSV_BACKSLASH_ESCAPE"
	{
		$$ = ast.BRIEOptionCSVBackslashEscape
	}
|	"CSV_TRIM_LAST_SEPARATORS"
	{
		$$ = ast.BRIEOptionCSVTrimLastSeparators
	}

BRIEStringOptionName:
	"TIKV_IMPORTER"
	{
		$$ = ast.BRIEOptionTiKVImporter
	}
|	"CSV_SEPARATOR"
	{
		$$ = ast.BRIEOptionCSVSeparator
	}
|	"CSV_DELIMITER"
	{
		$$ = ast.BRIEOptionCSVDelimiter
	}
|	"CSV_NULL"
	{
		$$ = ast.BRIEOptionCSVNull
	}

BRIEKeywordOptionName:
	"BACKEND"
	{
		$$ = ast.BRIEOptionBackend
	}
|	"ON_DUPLICATE"
	{
		$$ = ast.BRIEOptionOnDuplicate
	}
|	"ON" "DUPLICATE"
	{
		$$ = ast.BRIEOptionOnDuplicate
	}

BRIEOption:
	BRIEIntegerOptionName EqOpt LengthNum
	{
		$$ = &ast.BRIEOption{
			Tp:        $1.(ast.BRIEOptionType),
			UintValue: $3.(uint64),
		}
	}
|	BRIEBooleanOptionName EqOpt Boolean
	{
		value := uint64(0)
		if $3.(bool) {
			value = 1
		}
		$$ = &ast.BRIEOption{
			Tp:        $1.(ast.BRIEOptionType),
			UintValue: value,
		}
	}
|	BRIEStringOptionName EqOpt stringLit
	{
		$$ = &ast.BRIEOption{
			Tp:       $1.(ast.BRIEOptionType),
			StrValue: $3,
		}
	}
|	BRIEKeywordOptionName EqOpt StringNameOrBRIEOptionKeyword
	{
		$$ = &ast.BRIEOption{
			Tp:       $1.(ast.BRIEOptionType),
			StrValue: strings.ToLower($3),
		}
	}
|	"SNAPSHOT" EqOpt LengthNum TimestampUnit "AGO"
	{
		unit, err := $4.(ast.TimeUnitType).Duration()
		if err != nil {
			yylex.AppendError(err)
			return 1
		}
		// TODO: check overflow?
		$$ = &ast.BRIEOption{
			Tp:        ast.BRIEOptionBackupTimeAgo,
			UintValue: $3.(uint64) * uint64(unit),
		}
	}
|	"SNAPSHOT" EqOpt stringLit
	// not including this into BRIEStringOptionName to avoid shift/reduce conflict
	{
		$$ = &ast.BRIEOption{
			Tp:       ast.BRIEOptionBackupTS,
			StrValue: $3,
		}
	}
|	"SNAPSHOT" EqOpt LengthNum
	// not including this into BRIEIntegerOptionName to avoid shift/reduce conflict
	{
		$$ = &ast.BRIEOption{
			Tp:        ast.BRIEOptionBackupTSO,
			UintValue: $3.(uint64),
		}
	}
|	"LAST_BACKUP" EqOpt stringLit
	{
		$$ = &ast.BRIEOption{
			Tp:       ast.BRIEOptionLastBackupTS,
			StrValue: $3,
		}
	}
|	"LAST_BACKUP" EqOpt LengthNum
	{
		$$ = &ast.BRIEOption{
			Tp:        ast.BRIEOptionLastBackupTSO,
			UintValue: $3.(uint64),
		}
	}
|	"RATE_LIMIT" EqOpt LengthNum "MB" '/' "SECOND"
	{
		// TODO: check overflow?
		$$ = &ast.BRIEOption{
			Tp:        ast.BRIEOptionRateLimit,
			UintValue: $3.(uint64) * 1048576,
		}
	}
|	"CSV_HEADER" EqOpt FieldsOrColumns
	{
		$$ = &ast.BRIEOption{
			Tp:        ast.BRIEOptionCSVHeader,
			UintValue: ast.BRIECSVHeaderIsColumns,
		}
	}
|	"CSV_HEADER" EqOpt LengthNum
	{
		$$ = &ast.BRIEOption{
			Tp:        ast.BRIEOptionCSVHeader,
			UintValue: $3.(uint64),
		}
	}
|	"CHECKSUM" EqOpt Boolean
	{
		value := uint64(0)
		if $3.(bool) {
			value = 1
		}
		$$ = &ast.BRIEOption{
			Tp:        ast.BRIEOptionChecksum,
			UintValue: value,
		}
	}
|	"CHECKSUM" EqOpt OptionLevel
	{
		$$ = &ast.BRIEOption{
			Tp:        ast.BRIEOptionChecksum,
			UintValue: uint64($3.(ast.BRIEOptionLevel)),
		}
	}
|	"ANALYZE" EqOpt Boolean
	{
		value := uint64(0)
		if $3.(bool) {
			value = 1
		}
		$$ = &ast.BRIEOption{
			Tp:        ast.BRIEOptionAnalyze,
			UintValue: value,
		}
	}
|	"ANALYZE" EqOpt OptionLevel
	{
		$$ = &ast.BRIEOption{
			Tp:        ast.BRIEOptionAnalyze,
			UintValue: uint64($3.(ast.BRIEOptionLevel)),
		}
	}

LengthNum:
	NUM
	{
		$$ = getUint64FromNUM($1)
	}

Int64Num:
	NUM
	{
		v, rangeErrMsg := getInt64FromNUM($1)
		if len(rangeErrMsg) != 0 {
			yylex.AppendError(yylex.Errorf(rangeErrMsg))
			return 1
		}
		$$ = v
	}

NUM:
	intLit

Boolean:
	NUM
	{
		$$ = $1.(int64) != 0
	}
|	"FALSE"
	{
		$$ = false
	}
|	"TRUE"
	{
		$$ = true
	}

OptionLevel:
	"OFF"
	{
		$$ = ast.BRIEOptionLevelOff
	}
|	"OPTIONAL"
	{
		$$ = ast.BRIEOptionLevelOptional
	}
|	"REQUIRED"
	{
		$$ = ast.BRIEOptionLevelRequired
	}

PurgeImportStmt:
	"PURGE" "IMPORT" NUM
	{
		$$ = &ast.PurgeImportStmt{TaskID: getUint64FromNUM($3)}
	}

/*******************************************************************
 * import statements
 *
 *	CREATE IMPORT [IF NOT EXISTS] import_name
 *		FROM data_location [REPLACE | SKIP {ALL | CONSTRAINT | DUPLICATE ｜ STRICT}]
 *		[options_list]
 *	STOP IMPORT [IF RUNNING] import_name
 *	RESUME IMPORT [IF NOT RUNNING] import_name
 *	ALTER IMPORT import_name
 *		[REPLACE | SKIP {ALL | CONSTRAINT | DUPLICATE | STRICT}]
 *		[options_list]
 *		[TRUNCATE
 *			{ALL | ERRORS} [TABLE table_name [, table_name] ...]
 *		]
 *	DROP IMPORT [IF EXISTS] import_name
 *	SHOW IMPORT import_name [ERRORS] [TABLE table_name [, table_name] ...]
 */
CreateImportStmt:
	"CREATE" "IMPORT" IfNotExists Identifier "FROM" stringLit ErrorHandling BRIEOptions
	{
		$$ = &ast.CreateImportStmt{
			IfNotExists:   $3.(bool),
			Name:          $4,
			Storage:       $6,
			ErrorHandling: $7.(ast.ErrorHandlingOption),
			Options:       $8.([]*ast.BRIEOption),
		}
	}

StopImportStmt:
	"STOP" "IMPORT" IfRunning Identifier
	{
		$$ = &ast.StopImportStmt{
			IfRunning: $3.(bool),
			Name:      $4,
		}
	}

ResumeImportStmt:
	"RESUME" "IMPORT" IfNotRunning Identifier
	{
		$$ = &ast.ResumeImportStmt{
			IfNotRunning: $3.(bool),
			Name:         $4,
		}
	}

AlterImportStmt:
	"ALTER" "IMPORT" Identifier ErrorHandling BRIEOptions ImportTruncate
	{
		s := &ast.AlterImportStmt{
			Name:          $3,
			ErrorHandling: $4.(ast.ErrorHandlingOption),
			Options:       $5.([]*ast.BRIEOption),
		}
		if $6 != nil {
			s.Truncate = $6.(*ast.ImportTruncate)
		}
		$$ = s
	}

DropImportStmt:
	"DROP" "IMPORT" IfExists Identifier
	{
		$$ = &ast.DropImportStmt{
			IfExists: $3.(bool),
			Name:     $4,
		}
	}

ShowImportStmt:
	"SHOW" "IMPORT" Identifier OptErrors TableNameListOpt2
	{
		$$ = &ast.ShowImportStmt{
			Name:       $3,
			ErrorsOnly: $4.(bool),
			TableNames: $5.([]*ast.TableName),
		}
	}

IfRunning:
	{
		$$ = false
	}
|	"IF" "RUNNING"
	{
		$$ = true
	}

IfNotRunning:
	{
		$$ = false
	}
|	"IF" NotSym "RUNNING"
	{
		$$ = true
	}

OptErrors:
	{
		$$ = false
	}
|	"ERRORS"
	{
		$$ = true
	}

ErrorHandling:
	{
		$$ = ast.ErrorHandleError
	}
|	"REPLACE"
	{
		$$ = ast.ErrorHandleReplace
	}
|	"SKIP" "ALL"
	{
		$$ = ast.ErrorHandleSkipAll
	}
|	"SKIP" "CONSTRAINT"
	{
		$$ = ast.ErrorHandleSkipConstraint
	}
|	"SKIP" "DUPLICATE"
	{
		$$ = ast.ErrorHandleSkipDuplicate
	}
|	"SKIP" "STRICT"
	{
		$$ = ast.ErrorHandleSkipStrict
	}

ImportTruncate:
	{
		$$ = nil
	}
|	"TRUNCATE" "ALL" TableNameListOpt2
	{
		$$ = &ast.ImportTruncate{
			IsErrorsOnly: false,
			TableNames:   $3.([]*ast.TableName),
		}
	}
|	"TRUNCATE" "ERRORS" TableNameListOpt2
	{
		$$ = &ast.ImportTruncate{
			IsErrorsOnly: true,
			TableNames:   $3.([]*ast.TableName),
		}
	}

Expression:
	singleAtIdentifier assignmentEq Expression %prec assignmentEq
	{
		v := $1
		v = strings.TrimPrefix(v, "@")
		$$ = &ast.VariableExpr{
			Name:     v,
			IsGlobal: false,
			IsSystem: false,
			Value:    $3,
		}
	}
|	Expression logOr Expression %prec pipes
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.LogicOr, L: $1, R: $3}
	}
|	Expression "XOR" Expression %prec xor
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.LogicXor, L: $1, R: $3}
	}
|	Expression logAnd Expression %prec andand
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.LogicAnd, L: $1, R: $3}
	}
|	"NOT" Expression %prec not
	{
		expr, ok := $2.(*ast.ExistsSubqueryExpr)
		if ok {
			expr.Not = !expr.Not
			$$ = $2
		} else {
			$$ = &ast.UnaryOperationExpr{Op: opcode.Not, V: $2}
		}
	}
|	"MATCH" '(' ColumnNameList ')' "AGAINST" '(' BitExpr FulltextSearchModifierOpt ')'
	{
		$$ = &ast.MatchAgainst{
			ColumnNames: $3.([]*ast.ColumnName),
			Against:     $7,
			Modifier:    ast.FulltextSearchModifier($8.(int)),
		}
	}
|	BoolPri IsOrNotOp trueKwd %prec is
	{
		$$ = &ast.IsTruthExpr{Expr: $1, Not: !$2.(bool), True: int64(1)}
	}
|	BoolPri IsOrNotOp falseKwd %prec is
	{
		$$ = &ast.IsTruthExpr{Expr: $1, Not: !$2.(bool), True: int64(0)}
	}
|	BoolPri IsOrNotOp "UNKNOWN" %prec is
	{
		/* https://dev.mysql.com/doc/refman/5.7/en/comparison-operators.html#operator_is */
		$$ = &ast.IsNullExpr{Expr: $1, Not: !$2.(bool)}
	}
|	BoolPri

MaxValueOrExpression:
	"MAXVALUE"
	{
		$$ = &ast.MaxValueExpr{}
	}
|	BitExpr

FulltextSearchModifierOpt:
	/* empty */
	{
		$$ = ast.FulltextSearchModifierNaturalLanguageMode
	}
|	"IN" "NATURAL" "LANGUAGE" "MODE"
	{
		$$ = ast.FulltextSearchModifierNaturalLanguageMode
	}
|	"IN" "NATURAL" "LANGUAGE" "MODE" "WITH" "QUERY" "EXPANSION"
	{
		$$ = ast.FulltextSearchModifierNaturalLanguageMode | ast.FulltextSearchModifierWithQueryExpansion
	}
|	"IN" "BOOLEAN" "MODE"
	{
		$$ = ast.FulltextSearchModifierBooleanMode
	}
|	"WITH" "QUERY" "EXPANSION"
	{
		$$ = ast.FulltextSearchModifierWithQueryExpansion
	}

logOr:
	pipesAsOr
|	"OR"

logAnd:
	"&&"
|	"AND"

ExpressionList:
	Expression
	{
		$$ = []ast.ExprNode{$1}
	}
|	ExpressionList ',' Expression
	{
		$$ = append($1.([]ast.ExprNode), $3)
	}

MaxValueOrExpressionList:
	MaxValueOrExpression
	{
		$$ = []ast.ExprNode{$1}
	}
|	MaxValueOrExpressionList ',' MaxValueOrExpression
	{
		$$ = append($1.([]ast.ExprNode), $3)
	}

ExpressionListOpt:
	{
		$$ = []ast.ExprNode{}
	}
|	ExpressionList

FuncDatetimePrecListOpt:
	{
		$$ = []ast.ExprNode{}
	}
|	FuncDatetimePrecList

FuncDatetimePrecList:
	intLit
	{
		expr := ast.NewValueExpr($1, parser.charset, parser.collation)
		$$ = []ast.ExprNode{expr}
	}

BoolPri:
	BoolPri IsOrNotOp "NULL" %prec is
	{
		$$ = &ast.IsNullExpr{Expr: $1, Not: !$2.(bool)}
	}
|	BoolPri CompareOp PredicateExpr %prec eq
	{
		$$ = &ast.BinaryOperationExpr{Op: $2.(opcode.Op), L: $1, R: $3}
	}
|	BoolPri CompareOp AnyOrAll SubSelect %prec eq
	{
		sq := $4.(*ast.SubqueryExpr)
		sq.MultiRows = true
		$$ = &ast.CompareSubqueryExpr{Op: $2.(opcode.Op), L: $1, R: sq, All: $3.(bool)}
	}
|	BoolPri CompareOp singleAtIdentifier assignmentEq PredicateExpr %prec assignmentEq
	{
		v := $3
		v = strings.TrimPrefix(v, "@")
		variable := &ast.VariableExpr{
			Name:     v,
			IsGlobal: false,
			IsSystem: false,
			Value:    $5,
		}
		$$ = &ast.BinaryOperationExpr{Op: $2.(opcode.Op), L: $1, R: variable}
	}
|	PredicateExpr

CompareOp:
	">="
	{
		$$ = opcode.GE
	}
|	'>'
	{
		$$ = opcode.GT
	}
|	"<="
	{
		$$ = opcode.LE
	}
|	'<'
	{
		$$ = opcode.LT
	}
|	"!="
	{
		$$ = opcode.NE
	}
|	"<>"
	{
		$$ = opcode.NE
	}
|	"="
	{
		$$ = opcode.EQ
	}
|	"<=>"
	{
		$$ = opcode.NullEQ
	}

BetweenOrNotOp:
	"BETWEEN"
	{
		$$ = true
	}
|	NotSym "BETWEEN"
	{
		$$ = false
	}

IsOrNotOp:
	"IS"
	{
		$$ = true
	}
|	"IS" NotSym
	{
		$$ = false
	}

InOrNotOp:
	"IN"
	{
		$$ = true
	}
|	NotSym "IN"
	{
		$$ = false
	}

LikeOrNotOp:
	"LIKE"
	{
		$$ = true
	}
|	NotSym "LIKE"
	{
		$$ = false
	}

RegexpOrNotOp:
	RegexpSym
	{
		$$ = true
	}
|	NotSym RegexpSym
	{
		$$ = false
	}

AnyOrAll:
	"ANY"
	{
		$$ = false
	}
|	"SOME"
	{
		$$ = false
	}
|	"ALL"
	{
		$$ = true
	}

PredicateExpr:
	BitExpr InOrNotOp '(' ExpressionList ')'
	{
		$$ = &ast.PatternInExpr{Expr: $1, Not: !$2.(bool), List: $4.([]ast.ExprNode)}
	}
|	BitExpr InOrNotOp SubSelect
	{
		sq := $3.(*ast.SubqueryExpr)
		sq.MultiRows = true
		$$ = &ast.PatternInExpr{Expr: $1, Not: !$2.(bool), Sel: sq}
	}
|	BitExpr BetweenOrNotOp BitExpr "AND" PredicateExpr
	{
		$$ = &ast.BetweenExpr{
			Expr:  $1,
			Left:  $3,
			Right: $5,
			Not:   !$2.(bool),
		}
	}
|	BitExpr LikeOrNotOp SimpleExpr LikeEscapeOpt
	{
		escape := $4
		if len(escape) > 1 {
			yylex.AppendError(ErrWrongArguments.GenWithStackByArgs("ESCAPE"))
			return 1
		} else if len(escape) == 0 {
			escape = "\\"
		}
		$$ = &ast.PatternLikeExpr{
			Expr:    $1,
			Pattern: $3,
			Not:     !$2.(bool),
			Escape:  escape[0],
		}
	}
|	BitExpr RegexpOrNotOp SimpleExpr
	{
		$$ = &ast.PatternRegexpExpr{Expr: $1, Pattern: $3, Not: !$2.(bool)}
	}
|	BitExpr

RegexpSym:
	"REGEXP"
|	"RLIKE"

LikeEscapeOpt:
	%prec empty
	{
		$$ = "\\"
	}
|	"ESCAPE" stringLit
	{
		$$ = $2
	}

Field:
	'*' %prec '*'
	{
		$$ = &ast.SelectField{WildCard: &ast.WildCardField{}}
	}
|	Identifier '.' '*' %prec '*'
	{
		wildCard := &ast.WildCardField{Table: model.NewCIStr($1)}
		$$ = &ast.SelectField{WildCard: wildCard}
	}
|	Identifier '.' Identifier '.' '*' %prec '*'
	{
		wildCard := &ast.WildCardField{Schema: model.NewCIStr($1), Table: model.NewCIStr($3)}
		$$ = &ast.SelectField{WildCard: wildCard}
	}
|	Expression FieldAsNameOpt
	{
		expr := $1
		asName := $2
		$$ = &ast.SelectField{Expr: expr, AsName: model.NewCIStr(asName)}
	}

FieldAsNameOpt:
	/* EMPTY */
	{
		$$ = ""
	}
|	FieldAsName

FieldAsName:
	Identifier
|	"AS" Identifier
	{
		$$ = $2
	}
|	stringLit
|	"AS" stringLit
	{
		$$ = $2
	}

FieldList:
	Field
	{
		field := $1.(*ast.SelectField)
		field.Offset = parser.startOffset(&yyS[yypt])
		$$ = []*ast.SelectField{field}
	}
|	FieldList ',' Field
	{
		fl := $1.([]*ast.SelectField)
		last := fl[len(fl)-1]
		if last.Expr != nil && last.AsName.O == "" {
			lastEnd := parser.endOffset(&yyS[yypt-1])
			last.SetText(parser.lexer.client, parser.src[last.Offset:lastEnd])
		}
		newField := $3.(*ast.SelectField)
		newField.Offset = parser.startOffset(&yyS[yypt])
		$$ = append(fl, newField)
	}

GroupByClause:
	"GROUP" "BY" ByList
	{
		$$ = &ast.GroupByClause{Items: $3.([]*ast.ByItem)}
	}

HavingClause:
	{
		$$ = nil
	}
|	"HAVING" Expression
	{
		$$ = &ast.HavingClause{Expr: $2}
	}

AsOfClauseOpt:
	%prec empty
	{
		$$ = nil
	}
|	AsOfClause

AsOfClause:
	asof "TIMESTAMP" Expression
	{
		$$ = &ast.AsOfClause{
			TsExpr: $3.(ast.ExprNode),
		}
	}

IfExists:
	{
		$$ = false
	}
|	"IF" "EXISTS"
	{
		$$ = true
	}

IfNotExists:
	{
		$$ = false
	}
|	"IF" NotSym "EXISTS"
	{
		$$ = true
	}

IgnoreOptional:
	{
		$$ = false
	}
|	"IGNORE"
	{
		$$ = true
	}

IndexName:
	{
		$$ = &ast.NullString{
			String: "",
			Empty:  false,
		}
	}
|	Identifier
	{
		$$ = &ast.NullString{
			String: $1,
			Empty:  len($1) == 0,
		}
	}

IndexOptionList:
	{
		$$ = nil
	}
|	IndexOptionList IndexOption
	{
		// Merge the options
		if $1 == nil {
			$$ = $2
		} else {
			opt1 := $1.(*ast.IndexOption)
			opt2 := $2.(*ast.IndexOption)
			if len(opt2.Comment) > 0 {
				opt1.Comment = opt2.Comment
			} else if opt2.Tp != 0 {
				opt1.Tp = opt2.Tp
			} else if opt2.KeyBlockSize > 0 {
				opt1.KeyBlockSize = opt2.KeyBlockSize
			} else if len(opt2.ParserName.O) > 0 {
				opt1.ParserName = opt2.ParserName
			} else if opt2.Visibility != ast.IndexVisibilityDefault {
				opt1.Visibility = opt2.Visibility
			} else if opt2.PrimaryKeyTp != model.PrimaryKeyTypeDefault {
				opt1.PrimaryKeyTp = opt2.PrimaryKeyTp
			}
			$$ = opt1
		}
	}

IndexOption:
	"KEY_BLOCK_SIZE" EqOpt LengthNum
	{
		$$ = &ast.IndexOption{
			KeyBlockSize: $3.(uint64),
		}
	}
|	IndexType
	{
		$$ = &ast.IndexOption{
			Tp: $1.(model.IndexType),
		}
	}
|	"WITH" "PARSER" Identifier
	{
		$$ = &ast.IndexOption{
			ParserName: model.NewCIStr($3),
		}
		yylex.AppendError(yylex.Errorf("The WITH PARASER clause is parsed but ignored by all storage engines."))
		parser.lastErrorAsWarn()
	}
|	"COMMENT" stringLit
	{
		$$ = &ast.IndexOption{
			Comment: $2,
		}
	}
|	IndexInvisible
	{
		$$ = &ast.IndexOption{
			Visibility: $1.(ast.IndexVisibility),
		}
	}
|	WithClustered
	{
		$$ = &ast.IndexOption{
			PrimaryKeyTp: $1.(model.PrimaryKeyType),
		}
	}

/*
  See: https://github.com/mysql/mysql-server/blob/8.0/sql/sql_yacc.yy#L7179

  The syntax for defining an index is:

    ... INDEX [index_name] [USING|TYPE] <index_type> ...

  The problem is that whereas USING is a reserved word, TYPE is not. We can
  still handle it if an index name is supplied, i.e.:

    ... INDEX type TYPE <index_type> ...

  here the index's name is unmbiguously 'type', but for this:

    ... INDEX TYPE <index_type> ...

  it's impossible to know what this actually mean - is 'type' the name or the
  type? For this reason we accept the TYPE syntax only if a name is supplied.
*/
IndexNameAndTypeOpt:
	IndexName
	{
		$$ = []interface{}{$1, nil}
	}
|	IndexName "USING" IndexTypeName
	{
		$$ = []interface{}{$1, $3}
	}
|	Identifier "TYPE" IndexTypeName
	{
		$$ = []interface{}{&ast.NullString{String: $1, Empty: len($1) == 0}, $3}
	}

IndexTypeOpt:
	{
		$$ = nil
	}
|	IndexType

IndexType:
	"USING" IndexTypeName
	{
		$$ = $2
	}
|	"TYPE" IndexTypeName
	{
		$$ = $2
	}

IndexTypeName:
	"BTREE"
	{
		$$ = model.IndexTypeBtree
	}
|	"HASH"
	{
		$$ = model.IndexTypeHash
	}
|	"RTREE"
	{
		$$ = model.IndexTypeRtree
	}

IndexInvisible:
	"VISIBLE"
	{
		$$ = ast.IndexVisibilityVisible
	}
|	"INVISIBLE"
	{
		$$ = ast.IndexVisibilityInvisible
	}

/**********************************Identifier********************************************/
Identifier:
	identifier
|	UnReservedKeyword
|	NotKeywordToken
|	TiDBKeyword

UnReservedKeyword:
	"ACTION"
|	"ADVISE"
|	"ASCII"
|	"ATTRIBUTES"
|	"BINDING_CACHE"
|	"STATS_OPTIONS"
|	"STATS_SAMPLE_RATE"
|	"STATS_COL_CHOICE"
|	"STATS_COL_LIST"
|	"AUTO_ID_CACHE"
|	"AUTO_INCREMENT"
|	"AFTER"
|	"ALWAYS"
|	"AVG"
|	"BEGIN"
|	"BIT"
|	"BOOL"
|	"BOOLEAN"
|	"BTREE"
|	"BYTE"
|	"CAPTURE"
|	"CAUSAL"
|	"CLEANUP"
|	"CHAIN"
|	"CHARSET"
|	"COLUMNS"
|	"CONFIG"
|	"SAN"
|	"COMMIT"
|	"COMPACT"
|	"COMPRESSED"
|	"CONSISTENCY"
|	"CONSISTENT"
|	"CURRENT"
|	"DATA"
|	"DATE" %prec lowerThanStringLitToken
|	"DATETIME"
|	"DAY"
|	"DEALLOCATE"
|	"DO"
|	"DUPLICATE"
|	"DYNAMIC"
|	"ENCRYPTION"
|	"END"
|	"ENFORCED"
|	"ENGINE"
|	"ENGINES"
|	"ENUM"
|	"ERROR"
|	"ERRORS"
|	"ESCAPE"
|	"EVOLVE"
|	"EXECUTE"
|	"EXTENDED"
|	"FIELDS"
|	"FILE"
|	"FIRST"
|	"FIXED"
|	"FLUSH"
|	"FOLLOWING"
|	"FORMAT"
|	"FULL"
|	"GENERAL"
|	"GLOBAL"
|	"HASH"
|	"HELP"
|	"HOUR"
|	"INSERT_METHOD"
|	"LESS"
|	"LOCAL"
|	"LAST"
|	"NAMES"
|	"NVARCHAR"
|	"OFFSET"
|	"PACK_KEYS"
|	"PARSER"
|	"PASSWORD" %prec lowerThanEq
|	"PREPARE"
|	"PRE_SPLIT_REGIONS"
|	"PROXY"
|	"QUICK"
|	"REBUILD"
|	"REDUNDANT"
|	"REORGANIZE"
|	"RESTART"
|	"ROLE"
|	"ROLLBACK"
|	"SESSION"
|	"SIGNED"
|	"SHARD_ROW_ID_BITS"
|	"SHUTDOWN"
|	"SNAPSHOT"
|	"START"
|	"STATUS"
|	"OPEN"
|	"SUBPARTITIONS"
|	"SUBPARTITION"
|	"TABLES"
|	"TABLESPACE"
|	"TEXT"
|	"THAN"
|	"TIME" %prec lowerThanStringLitToken
|	"TIMESTAMP" %prec lowerThanStringLitToken
|	"TRACE"
|	"TRANSACTION"
|	"TRUNCATE"
|	"UNBOUNDED"
|	"UNKNOWN"
|	"VALUE" %prec lowerThanValueKeyword
|	"WARNINGS"
|	"YEAR"
|	"MODE"
|	"WEEK"
|	"WEIGHT_STRING"
|	"ANY"
|	"SOME"
|	"USER"
|	"IDENTIFIED"
|	"COLLATION"
|	"COMMENT"
|	"AVG_ROW_LENGTH"
|	"CONNECTION"
|	"CHECKSUM"
|	"COMPRESSION"
|	"KEY_BLOCK_SIZE"
|	"MASTER"
|	"MAX_ROWS"
|	"MIN_ROWS"
|	"NATIONAL"
|	"NCHAR"
|	"ROW_FORMAT"
|	"QUARTER"
|	"GRANTS"
|	"TRIGGERS"
|	"DELAY_KEY_WRITE"
|	"ISOLATION"
|	"JSON"
|	"REPEATABLE"
|	"RESPECT"
|	"COMMITTED"
|	"UNCOMMITTED"
|	"ONLY"
|	"SERIAL"
|	"SERIALIZABLE"
|	"LEVEL"
|	"VARIABLES"
|	"SQL_CACHE"
|	"INDEXES"
|	"PROCESSLIST"
|	"SQL_NO_CACHE"
|	"DISABLE"
|	"DISABLED"
|	"ENABLE"
|	"ENABLED"
|	"REVERSE"
|	"PRIVILEGES"
|	"NO"
|	"BINLOG"
|	"FUNCTION"
|	"VIEW"
|	"BINDING"
|	"BINDINGS"
|	"MODIFY"
|	"EVENTS"
|	"PARTITIONS"
|	"NONE"
|	"NULLS"
|	"SUPER"
|	"EXCLUSIVE"
|	"STATS_PERSISTENT"
|	"STATS_AUTO_RECALC"
|	"ROW_COUNT"
|	"COALESCE"
|	"MONTH"
|	"PROCESS"
|	"PROFILE"
|	"PROFILES"
|	"MICROSECOND"
|	"MINUTE"
|	"PLUGINS"
|	"PRECEDING"
|	"QUERY"
|	"QUERIES"
|	"SECOND"
|	"SEPARATOR"
|	"SHARE"
|	"SHARED"
|	"SLOW"
|	"MAX_CONNECTIONS_PER_HOUR"
|	"MAX_QUERIES_PER_HOUR"
|	"MAX_UPDATES_PER_HOUR"
|	"MAX_USER_CONNECTIONS"
|	"REPLICATION"
|	"CLIENT"
|	"SLAVE"
|	"RELOAD"
|	"TEMPORARY"
|	"ROUTINE"
|	"EVENT"
|	"ALGORITHM"
|	"DEFINER"
|	"INVOKER"
|	"MERGE"
|	"TEMPTABLE"
|	"UNDEFINED"
|	"SECURITY"
|	"CASCADED"
|	"RECOVER"
|	"CIPHER"
|	"SUBJECT"
|	"ISSUER"
|	"X509"
|	"NEVER"
|	"EXPIRE"
|	"ACCOUNT"
|	"INCREMENTAL"
|	"CPU"
|	"MEMORY"
|	"BLOCK"
|	"IO"
|	"CONTEXT"
|	"SWITCHES"
|	"PAGE"
|	"FAULTS"
|	"IPC"
|	"SWAPS"
|	"SOURCE"
|	"TRADITIONAL"
|	"SQL_BUFFER_RESULT"
|	"DIRECTORY"
|	"HISTOGRAM"
|	"HISTORY"
|	"LIST"
|	"NODEGROUP"
|	"SYSTEM_TIME"
|	"PARTIAL"
|	"SIMPLE"
|	"REMOVE"
|	"PARTITIONING"
|	"STORAGE"
|	"DISK"
|	"STATS_SAMPLE_PAGES"
|	"SECONDARY_ENGINE"
|	"SECONDARY_LOAD"
|	"SECONDARY_UNLOAD"
|	"VALIDATION"
|	"WITHOUT"
|	"RTREE"
|	"EXCHANGE"
|	"COLUMN_FORMAT"
|	"REPAIR"
|	"IMPORT"
|	"IMPORTS"
|	"DISCARD"
|	"TABLE_CHECKSUM"
|	"UNICODE"
|	"AUTO_RANDOM"
|	"AUTO_RANDOM_BASE"
|	"SQL_TSI_DAY"
|	"SQL_TSI_HOUR"
|	"SQL_TSI_MINUTE"
|	"SQL_TSI_MONTH"
|	"SQL_TSI_QUARTER"
|	"SQL_TSI_SECOND"
|	"LANGUAGE"
|	"SQL_TSI_WEEK"
|	"SQL_TSI_YEAR"
|	"INVISIBLE"
|	"VISIBLE"
|	"TYPE"
|	"NOWAIT"
|	"INSTANCE"
|	"REPLICA"
|	"LOCATION"
|	"LABELS"
|	"LOGS"
|	"HOSTS"
|	"AGAINST"
|	"EXPANSION"
|	"INCREMENT"
|	"MINVALUE"
|	"NOMAXVALUE"
|	"NOMINVALUE"
|	"NOCACHE"
|	"CACHE"
|	"CYCLE"
|	"NOCYCLE"
|	"SEQUENCE"
|	"MAX_MINUTES"
|	"MAX_IDXNUM"
|	"PER_TABLE"
|	"PER_DB"
|	"NEXT"
|	"NEXTVAL"
|	"LASTVAL"
|	"SETVAL"
|	"AGO"
|	"BACKUP"
|	"BACKUPS"
|	"CONCURRENCY"
|	"MB"
|	"ONLINE"
|	"RATE_LIMIT"
|	"RESTORE"
|	"RESTORES"
|	"SEND_CREDENTIALS_TO_TIKV"
|	"LAST_BACKUP"
|	"CHECKPOINT"
|	"SKIP_SCHEMA_FILES"
|	"STRICT_FORMAT"
|	"BACKEND"
|	"CSV_BACKSLASH_ESCAPE"
|	"CSV_NOT_NULL"
|	"CSV_TRIM_LAST_SEPARATORS"
|	"CSV_DELIMITER"
|	"CSV_HEADER"
|	"CSV_NULL"
|	"CSV_SEPARATOR"
|	"ON_DUPLICATE"
|	"TIKV_IMPORTER"
|	"REPLICAS"
|	"POLICY"
|	"WAIT"
|	"CLIENT_ERRORS_SUMMARY"
|	"BERNOULLI"
|	"SYSTEM"
|	"PERCENT"
|	"RESUME"
|	"OFF"
|	"OPTIONAL"
|	"REQUIRED"
|	"PURGE"
|	"SKIP"
|	"LOCKED"
|	"CLUSTERED"
|	"NONCLUSTERED"
|	"PRESERVE"

TiDBKeyword:
	"ADMIN"
|	"BATCH"
|	"BUCKETS"
|	"BUILTINS"
|	"CANCEL"
|	"CARDINALITY"
|	"CMSKETCH"
|	"COLUMN_STATS_USAGE"
|	"CORRELATION"
|	"DDL"
|	"DEPENDENCY"
|	"DEPTH"
|	"DRAINER"
|	"JOBS"
|	"JOB"
|	"NODE_ID"
|	"NODE_STATE"
|	"PUMP"
|	"SAMPLES"
|	"SAMPLERATE"
|	"STATISTICS"
|	"STATS"
|	"STATS_META"
|	"STATS_HISTOGRAMS"
|	"STATS_TOPN"
|	"STATS_BUCKETS"
|	"STATS_HEALTHY"
|	"HISTOGRAMS_IN_FLIGHT"
|	"TELEMETRY"
|	"TELEMETRY_ID"
|	"TIDB"
|	"TIFLASH"
|	"TOPN"
|	"SPLIT"
|	"OPTIMISTIC"
|	"PESSIMISTIC"
|	"WIDTH"
|	"REGIONS"
|	"REGION"
|	"RESET"
|	"DRY"
|	"RUN"

NotKeywordToken:
	"ADDDATE"
|	"APPROX_COUNT_DISTINCT"
|	"APPROX_PERCENTILE"
|	"BIT_AND"
|	"BIT_OR"
|	"BIT_XOR"
|	"BRIEF"
|	"CAST"
|	"COPY"
|	"CURTIME"
|	"DATE_ADD"
|	"DATE_SUB"
|	"DOT"
|	"DUMP"
|	"EXTRACT"
|	"GET_FORMAT"
|	"GROUP_CONCAT"
|	"INPLACE"
|	"INSTANT"
|	"INTERNAL"
|	"MIN"
|	"MAX"
|	"NOW"
|	"RECENT"
|	"REPLAYER"
|	"RUNNING"
|	"PLACEMENT"
|	"PLAN"
|	"PLAN_CACHE"
|	"POSITION"
|	"PREDICATE"
|	"S3"
|	"STRICT"
|	"SUBDATE"
|	"SUBSTRING"
|	"SUM"
|	"STD"
|	"STDDEV"
|	"STDDEV_POP"
|	"STDDEV_SAMP"
|	"STOP"
|	"VARIANCE"
|	"VAR_POP"
|	"VAR_SAMP"
|	"TARGET"
|	"TIMESTAMPADD"
|	"TIMESTAMPDIFF"
|	"TOKUDB_DEFAULT"
|	"TOKUDB_FAST"
|	"TOKUDB_LZMA"
|	"TOKUDB_QUICKLZ"
|	"TOKUDB_SNAPPY"
|	"TOKUDB_SMALL"
|	"TOKUDB_UNCOMPRESSED"
|	"TOKUDB_ZLIB"
|	"TOP"
|	"TRIM"
|	"NEXT_ROW_ID"
|	"EXPR_PUSHDOWN_BLACKLIST"
|	"OPT_RULE_BLACKLIST"
|	"BOUND"
|	"EXACT" %prec lowerThanStringLitToken
|	"STALENESS"
|	"STRONG"
|	"FLASHBACK"
|	"JSON_OBJECTAGG"
|	"JSON_ARRAYAGG"
|	"TLS"
|	"FOLLOWER"
|	"FOLLOWERS"
|	"LEADER"
|	"LEARNER"
|	"LEARNERS"
|	"VERBOSE"
|	"TRUE_CARD_COST"
|	"VOTER"
|	"VOTERS"
|	"CONSTRAINTS"
|	"PRIMARY_REGION"
|	"SCHEDULE"
|	"LEADER_CONSTRAINTS"
|	"FOLLOWER_CONSTRAINTS"
|	"LEARNER_CONSTRAINTS"
|	"VOTER_CONSTRAINTS"

/************************************************************************************
 *
 *  Call Statements
 *
 **********************************************************************************/
CallStmt:
	"CALL" ProcedureCall
	{
		$$ = &ast.CallStmt{
			Procedure: $2.(*ast.FuncCallExpr),
		}
	}

ProcedureCall:
	identifier
	{
		$$ = &ast.FuncCallExpr{
			Tp:     ast.FuncCallExprTypeGeneric,
			FnName: model.NewCIStr($1),
			Args:   []ast.ExprNode{},
		}
	}
|	Identifier '.' Identifier
	{
		$$ = &ast.FuncCallExpr{
			Tp:     ast.FuncCallExprTypeGeneric,
			Schema: model.NewCIStr($1),
			FnName: model.NewCIStr($3),
			Args:   []ast.ExprNode{},
		}
	}
|	identifier '(' ExpressionListOpt ')'
	{
		$$ = &ast.FuncCallExpr{
			Tp:     ast.FuncCallExprTypeGeneric,
			FnName: model.NewCIStr($1),
			Args:   $3.([]ast.ExprNode),
		}
	}
|	Identifier '.' Identifier '(' ExpressionListOpt ')'
	{
		$$ = &ast.FuncCallExpr{
			Tp:     ast.FuncCallExprTypeGeneric,
			Schema: model.NewCIStr($1),
			FnName: model.NewCIStr($3),
			Args:   $5.([]ast.ExprNode),
		}
	}

/************************************************************************************
 *
 *  Insert Statements
 *
 **********************************************************************************/
InsertIntoStmt:
	"INSERT" TableOptimizerHintsOpt PriorityOpt IgnoreOptional IntoOpt TableName PartitionNameListOpt InsertValues OnDuplicateKeyUpdate
	{
		x := $8.(*ast.InsertStmt)
		x.Priority = $3.(mysql.PriorityEnum)
		x.IgnoreErr = $4.(bool)
		// Wraps many layers here so that it can be processed the same way as select statement.
		ts := &ast.TableSource{Source: $6.(*ast.TableName)}
		x.Table = &ast.TableRefsClause{TableRefs: &ast.Join{Left: ts}}
		if $9 != nil {
			x.OnDuplicate = $9.([]*ast.Assignment)
		}
		if $2 != nil {
			x.TableHints = $2.([]*ast.TableOptimizerHint)
		}
		x.PartitionNames = $7.([]model.CIStr)
		$$ = x
	}

IntoOpt:
	{}
|	"INTO"

InsertValues:
	'(' ColumnNameListOpt ')' ValueSym ValuesList
	{
		$$ = &ast.InsertStmt{
			Columns: $2.([]*ast.ColumnName),
			Lists:   $5.([][]ast.ExprNode),
		}
	}
|	'(' ColumnNameListOpt ')' SetOprStmt
	{
		$$ = &ast.InsertStmt{Columns: $2.([]*ast.ColumnName), Select: $4.(ast.ResultSetNode)}
	}
|	'(' ColumnNameListOpt ')' SelectStmt
	{
		$$ = &ast.InsertStmt{Columns: $2.([]*ast.ColumnName), Select: $4.(ast.ResultSetNode)}
	}
|	'(' ColumnNameListOpt ')' SelectStmtWithClause
	{
		$$ = &ast.InsertStmt{Columns: $2.([]*ast.ColumnName), Select: $4.(ast.ResultSetNode)}
	}
|	'(' ColumnNameListOpt ')' SubSelect
	{
		var sel ast.ResultSetNode
		switch x := $4.(*ast.SubqueryExpr).Query.(type) {
		case *ast.SelectStmt:
			x.IsInBraces = true
			sel = x
		case *ast.SetOprStmt:
			x.IsInBraces = true
			sel = x
		}
		$$ = &ast.InsertStmt{Columns: $2.([]*ast.ColumnName), Select: sel}
	}
|	ValueSym ValuesList %prec insertValues
	{
		$$ = &ast.InsertStmt{Lists: $2.([][]ast.ExprNode)}
	}
|	SetOprStmt
	{
		$$ = &ast.InsertStmt{Select: $1.(ast.ResultSetNode)}
	}
|	SelectStmt
	{
		$$ = &ast.InsertStmt{Select: $1.(ast.ResultSetNode)}
	}
|	SelectStmtWithClause
	{
		$$ = &ast.InsertStmt{Select: $1.(ast.ResultSetNode)}
	}
|	SubSelect
	{
		var sel ast.ResultSetNode
		switch x := $1.(*ast.SubqueryExpr).Query.(type) {
		case *ast.SelectStmt:
			x.IsInBraces = true
			sel = x
		case *ast.SetOprStmt:
			x.IsInBraces = true
			sel = x
		}
		$$ = &ast.InsertStmt{Select: sel}
	}
|	"SET" ColumnSetValueList
	{
		$$ = &ast.InsertStmt{Setlist: $2.([]*ast.Assignment)}
	}

ValueSym:
	"VALUE"
|	"VALUES"

ValuesList:
	RowValue
	{
		$$ = [][]ast.ExprNode{$1.([]ast.ExprNode)}
	}
|	ValuesList ',' RowValue
	{
		$$ = append($1.([][]ast.ExprNode), $3.([]ast.ExprNode))
	}

RowValue:
	'(' ValuesOpt ')'
	{
		$$ = $2
	}

ValuesOpt:
	{
		$$ = []ast.ExprNode{}
	}
|	Values

Values:
	Values ',' ExprOrDefault
	{
		$$ = append($1.([]ast.ExprNode), $3)
	}
|	ExprOrDefault
	{
		$$ = []ast.ExprNode{$1}
	}

ExprOrDefault:
	Expression
|	"DEFAULT"
	{
		$$ = &ast.DefaultExpr{}
	}

ColumnSetValue:
	ColumnName eq ExprOrDefault
	{
		$$ = &ast.Assignment{
			Column: $1.(*ast.ColumnName),
			Expr:   $3,
		}
	}

ColumnSetValueList:
	{
		$$ = []*ast.Assignment{}
	}
|	ColumnSetValue
	{
		$$ = []*ast.Assignment{$1.(*ast.Assignment)}
	}
|	ColumnSetValueList ',' ColumnSetValue
	{
		$$ = append($1.([]*ast.Assignment), $3.(*ast.Assignment))
	}

/*
 * ON DUPLICATE KEY UPDATE col_name=expr [, col_name=expr] ...
 * See https://dev.mysql.com/doc/refman/5.7/en/insert-on-duplicate.html
 */
OnDuplicateKeyUpdate:
	{
		$$ = nil
	}
|	"ON" "DUPLICATE" "KEY" "UPDATE" AssignmentList
	{
		$$ = $5
	}

/************************************************************************************
 *  Replace Statements
 *  See https://dev.mysql.com/doc/refman/5.7/en/replace.html
 *
 **********************************************************************************/
ReplaceIntoStmt:
	"REPLACE" PriorityOpt IntoOpt TableName PartitionNameListOpt InsertValues
	{
		x := $6.(*ast.InsertStmt)
		x.IsReplace = true
		x.Priority = $2.(mysql.PriorityEnum)
		ts := &ast.TableSource{Source: $4.(*ast.TableName)}
		x.Table = &ast.TableRefsClause{TableRefs: &ast.Join{Left: ts}}
		x.PartitionNames = $5.([]model.CIStr)
		$$ = x
	}

Literal:
	"FALSE"
	{
		$$ = ast.NewValueExpr(false, parser.charset, parser.collation)
	}
|	"NULL"
	{
		$$ = ast.NewValueExpr(nil, parser.charset, parser.collation)
	}
|	"TRUE"
	{
		$$ = ast.NewValueExpr(true, parser.charset, parser.collation)
	}
|	floatLit
	{
		$$ = ast.NewValueExpr($1, parser.charset, parser.collation)
	}
|	decLit
	{
		$$ = ast.NewValueExpr($1, parser.charset, parser.collation)
	}
|	intLit
	{
		$$ = ast.NewValueExpr($1, parser.charset, parser.collation)
	}
|	StringLiteral %prec lowerThanStringLitToken
|	"UNDERSCORE_CHARSET" stringLit
	{
		// See https://dev.mysql.com/doc/refman/5.7/en/charset-literal.html
		co, err := charset.GetDefaultCollationLegacy($1)
		if err != nil {
			yylex.AppendError(ast.ErrUnknownCharacterSet.GenWithStack("Unsupported character introducer: '%-.64s'", $1))
			return 1
		}
		expr := ast.NewValueExpr($2, $1, co)
		tp := expr.GetType()
		tp.SetCharset($1)
		tp.SetCollate(co)
		if tp.GetCollate() == charset.CollationBin {
			tp.AddFlag(mysql.BinaryFlag)
		}
		$$ = expr
	}
|	hexLit
	{
		$$ = ast.NewValueExpr($1, parser.charset, parser.collation)
	}
|	bitLit
	{
		$$ = ast.NewValueExpr($1, parser.charset, parser.collation)
	}
|	"UNDERSCORE_CHARSET" hexLit
	{
		co, err := charset.GetDefaultCollationLegacy($1)
		if err != nil {
			yylex.AppendError(ast.ErrUnknownCharacterSet.GenWithStack("Unsupported character introducer: '%-.64s'", $1))
			return 1
		}
		expr := ast.NewValueExpr($2, $1, co)
		tp := expr.GetType()
		tp.SetCharset($1)
		tp.SetCollate(co)
		if tp.GetCollate() == charset.CollationBin {
			tp.AddFlag(mysql.BinaryFlag)
		}
		$$ = expr
	}
|	"UNDERSCORE_CHARSET" bitLit
	{
		co, err := charset.GetDefaultCollationLegacy($1)
		if err != nil {
			yylex.AppendError(ast.ErrUnknownCharacterSet.GenWithStack("Unsupported character introducer: '%-.64s'", $1))
			return 1
		}
		expr := ast.NewValueExpr($2, $1, co)
		tp := expr.GetType()
		tp.SetCharset($1)
		tp.SetCollate(co)
		if tp.GetCollate() == charset.CollationBin {
			tp.AddFlag(mysql.BinaryFlag)
		}
		$$ = expr
	}

StringLiteral:
	stringLit
	{
		expr := ast.NewValueExpr($1, parser.charset, parser.collation)
		$$ = expr
	}
|	StringLiteral stringLit
	{
		valExpr := $1.(ast.ValueExpr)
		strLit := valExpr.GetString()
		expr := ast.NewValueExpr(strLit+$2, parser.charset, parser.collation)
		// Fix #4239, use first string literal as projection name.
		if valExpr.GetProjectionOffset() >= 0 {
			expr.SetProjectionOffset(valExpr.GetProjectionOffset())
		} else {
			expr.SetProjectionOffset(len(strLit))
		}
		$$ = expr
	}

AlterOrderList:
	AlterOrderItem
	{
		$$ = []*ast.AlterOrderItem{$1.(*ast.AlterOrderItem)}
	}
|	AlterOrderList ',' AlterOrderItem
	{
		$$ = append($1.([]*ast.AlterOrderItem), $3.(*ast.AlterOrderItem))
	}

AlterOrderItem:
	ColumnName OptOrder
	{
		$$ = &ast.AlterOrderItem{Column: $1.(*ast.ColumnName), Desc: $2.(bool)}
	}

OrderBy:
	"ORDER" "BY" ByList
	{
		$$ = &ast.OrderByClause{Items: $3.([]*ast.ByItem)}
	}

ByList:
	ByItem
	{
		$$ = []*ast.ByItem{$1.(*ast.ByItem)}
	}
|	ByList ',' ByItem
	{
		$$ = append($1.([]*ast.ByItem), $3.(*ast.ByItem))
	}

ByItem:
	Expression
	{
		expr := $1
		valueExpr, ok := expr.(ast.ValueExpr)
		if ok {
			position, isPosition := valueExpr.GetValue().(int64)
			if isPosition {
				expr = &ast.PositionExpr{N: int(position)}
			}
		}
		$$ = &ast.ByItem{Expr: expr, NullOrder: true}
	}
|	Expression Order
	{
		expr := $1
		valueExpr, ok := expr.(ast.ValueExpr)
		if ok {
			position, isPosition := valueExpr.GetValue().(int64)
			if isPosition {
				expr = &ast.PositionExpr{N: int(position)}
			}
		}
		$$ = &ast.ByItem{Expr: expr, Desc: $2.(bool)}
	}

Order:
	"ASC"
	{
		$$ = false
	}
|	"DESC"
	{
		$$ = true
	}

OptOrder:
	/* EMPTY */
	{
		$$ = false // ASC by default
	}
|	"ASC"
	{
		$$ = false
	}
|	"DESC"
	{
		$$ = true
	}

OrderByOptional:
	{
		$$ = nil
	}
|	OrderBy

BitExpr:
	BitExpr '|' BitExpr %prec '|'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Or, L: $1, R: $3}
	}
|	BitExpr '&' BitExpr %prec '&'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.And, L: $1, R: $3}
	}
|	BitExpr "<<" BitExpr %prec lsh
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.LeftShift, L: $1, R: $3}
	}
|	BitExpr ">>" BitExpr %prec rsh
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.RightShift, L: $1, R: $3}
	}
|	BitExpr '+' BitExpr %prec '+'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Plus, L: $1, R: $3}
	}
|	BitExpr '-' BitExpr %prec '-'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Minus, L: $1, R: $3}
	}
|	BitExpr '+' "INTERVAL" Expression TimeUnit %prec '+'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr("DATE_ADD"),
			Args: []ast.ExprNode{
				$1,
				$4,
				&ast.TimeUnitExpr{Unit: $5.(ast.TimeUnitType)},
			},
		}
	}
|	BitExpr '-' "INTERVAL" Expression TimeUnit %prec '+'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr("DATE_SUB"),
			Args: []ast.ExprNode{
				$1,
				$4,
				&ast.TimeUnitExpr{Unit: $5.(ast.TimeUnitType)},
			},
		}
	}
|	BitExpr '*' BitExpr %prec '*'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Mul, L: $1, R: $3}
	}
|	BitExpr '/' BitExpr %prec '/'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Div, L: $1, R: $3}
	}
|	BitExpr '%' BitExpr %prec '%'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Mod, L: $1, R: $3}
	}
|	BitExpr "DIV" BitExpr %prec div
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.IntDiv, L: $1, R: $3}
	}
|	BitExpr "MOD" BitExpr %prec mod
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Mod, L: $1, R: $3}
	}
|	BitExpr '^' BitExpr
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Xor, L: $1, R: $3}
	}
|	SimpleExpr

SimpleIdent:
	Identifier
	{
		$$ = &ast.ColumnNameExpr{Name: &ast.ColumnName{
			Name: model.NewCIStr($1),
		}}
	}
|	Identifier '.' Identifier
	{
		$$ = &ast.ColumnNameExpr{Name: &ast.ColumnName{
			Table: model.NewCIStr($1),
			Name:  model.NewCIStr($3),
		}}
	}
|	Identifier '.' Identifier '.' Identifier
	{
		$$ = &ast.ColumnNameExpr{Name: &ast.ColumnName{
			Schema: model.NewCIStr($1),
			Table:  model.NewCIStr($3),
			Name:   model.NewCIStr($5),
		}}
	}

SimpleExpr:
	SimpleIdent
|	FunctionCallKeyword
|	FunctionCallNonKeyword
|	FunctionCallGeneric
|	SimpleExpr "COLLATE" CollationName
	{
		$$ = &ast.SetCollationExpr{Expr: $1, Collate: $3}
	}
|	WindowFuncCall
|	Literal
|	paramMarker
	{
		$$ = ast.NewParamMarkerExpr(yyS[yypt].offset)
	}
|	Variable
|	SumExpr
|	'!' SimpleExpr %prec neg
	{
		$$ = &ast.UnaryOperationExpr{Op: opcode.Not2, V: $2}
	}
|	'~' SimpleExpr %prec neg
	{
		$$ = &ast.UnaryOperationExpr{Op: opcode.BitNeg, V: $2}
	}
|	'-' SimpleExpr %prec neg
	{
		$$ = &ast.UnaryOperationExpr{Op: opcode.Minus, V: $2}
	}
|	'+' SimpleExpr %prec neg
	{
		$$ = &ast.UnaryOperationExpr{Op: opcode.Plus, V: $2}
	}
|	SimpleExpr pipes SimpleExpr
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr(ast.Concat), Args: []ast.ExprNode{$1, $3}}
	}
|	not2 SimpleExpr %prec neg
	{
		$$ = &ast.UnaryOperationExpr{Op: opcode.Not2, V: $2}
	}
|	SubSelect %prec neg
|	'(' Expression ')'
	{
		startOffset := parser.startOffset(&yyS[yypt-1])
		endOffset := parser.endOffset(&yyS[yypt])
		expr := $2
		expr.SetText(parser.lexer.client, parser.src[startOffset:endOffset])
		$$ = &ast.ParenthesesExpr{Expr: expr}
	}
|	'(' ExpressionList ',' Expression ')'
	{
		values := append($2.([]ast.ExprNode), $4)
		$$ = &ast.RowExpr{Values: values}
	}
|	"ROW" '(' ExpressionList ',' Expression ')'
	{
		values := append($3.([]ast.ExprNode), $5)
		$$ = &ast.RowExpr{Values: values}
	}
|	"EXISTS" SubSelect
	{
		sq := $2.(*ast.SubqueryExpr)
		sq.Exists = true
		$$ = &ast.ExistsSubqueryExpr{Sel: sq}
	}
|	'{' Identifier Expression '}'
	{
		/*
		 * ODBC escape syntax.
		 * See https://dev.mysql.com/doc/refman/5.7/en/expressions.html
		 */
		tp := $3.GetType()
		switch $2 {
		case "d":
			tp.SetCharset("")
			tp.SetCollate("")
			$$ = &ast.FuncCallExpr{FnName: model.NewCIStr(ast.DateLiteral), Args: []ast.ExprNode{$3}}
		case "t":
			tp.SetCharset("")
			tp.SetCollate("")
			$$ = &ast.FuncCallExpr{FnName: model.NewCIStr(ast.TimeLiteral), Args: []ast.ExprNode{$3}}
		case "ts":
			tp.SetCharset("")
			tp.SetCollate("")
			$$ = &ast.FuncCallExpr{FnName: model.NewCIStr(ast.TimestampLiteral), Args: []ast.ExprNode{$3}}
		default:
			$$ = $3
		}
	}
|	"BINARY" SimpleExpr %prec neg
	{
		// See https://dev.mysql.com/doc/refman/5.7/en/cast-functions.html#operator_binary
		tp := types.NewFieldType(mysql.TypeString)
		tp.SetCharset(charset.CharsetBin)
		tp.SetCollate(charset.CharsetBin)
		tp.AddFlag(mysql.BinaryFlag)
		$$ = &ast.FuncCastExpr{
			Expr:         $2,
			Tp:           tp,
			FunctionType: ast.CastBinaryOperator,
		}
	}
|	builtinCast '(' Expression "AS" CastType ')'
	{
		/* See https://dev.mysql.com/doc/refman/5.7/en/cast-functions.html#function_cast */
		tp := $5.(*types.FieldType)
		defaultFlen, defaultDecimal := mysql.GetDefaultFieldLengthAndDecimalForCast(tp.GetType())
		if tp.GetFlen() == types.UnspecifiedLength {
			tp.SetFlen(defaultFlen)
		}
		if tp.GetDecimal() == types.UnspecifiedLength {
			tp.SetDecimal(defaultDecimal)
		}
		explicitCharset := parser.explicitCharset
		parser.explicitCharset = false
		$$ = &ast.FuncCastExpr{
			Expr:            $3,
			Tp:              tp,
			FunctionType:    ast.CastFunction,
			ExplicitCharSet: explicitCharset,
		}
	}
|	"CASE" ExpressionOpt WhenClauseList ElseOpt "END"
	{
		x := &ast.CaseExpr{WhenClauses: $3.([]*ast.WhenClause)}
		if $2 != nil {
			x.Value = $2
		}
		if $4 != nil {
			x.ElseClause = $4.(ast.ExprNode)
		}
		$$ = x
	}
|	"CONVERT" '(' Expression ',' CastType ')'
	{
		// See https://dev.mysql.com/doc/refman/5.7/en/cast-functions.html#function_convert
		tp := $5.(*types.FieldType)
		defaultFlen, defaultDecimal := mysql.GetDefaultFieldLengthAndDecimalForCast(tp.GetType())
		if tp.GetFlen() == types.UnspecifiedLength {
			tp.SetFlen(defaultFlen)
		}
		if tp.GetDecimal() == types.UnspecifiedLength {
			tp.SetDecimal(defaultDecimal)
		}
		explicitCharset := parser.explicitCharset
		parser.explicitCharset = false
		$$ = &ast.FuncCastExpr{
			Expr:            $3,
			Tp:              tp,
			FunctionType:    ast.CastConvertFunction,
			ExplicitCharSet: explicitCharset,
		}
	}
|	"CONVERT" '(' Expression "USING" CharsetName ')'
	{
		// See https://dev.mysql.com/doc/refman/5.7/en/cast-functions.html#function_convert
		charset1 := ast.NewValueExpr($5, "", "")
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args:   []ast.ExprNode{$3, charset1},
		}
	}
|	"DEFAULT" '(' SimpleIdent ')'
	{
		$$ = &ast.DefaultExpr{Name: $3.(*ast.ColumnNameExpr).Name}
	}
|	"VALUES" '(' SimpleIdent ')' %prec lowerThanInsertValues
	{
		$$ = &ast.ValuesExpr{Column: $3.(*ast.ColumnNameExpr)}
	}
|	SimpleIdent jss stringLit
	{
		expr := ast.NewValueExpr($3, parser.charset, parser.collation)
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr(ast.JSONExtract), Args: []ast.ExprNode{$1, expr}}
	}
|	SimpleIdent juss stringLit
	{
		expr := ast.NewValueExpr($3, parser.charset, parser.collation)
		extract := &ast.FuncCallExpr{FnName: model.NewCIStr(ast.JSONExtract), Args: []ast.ExprNode{$1, expr}}
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr(ast.JSONUnquote), Args: []ast.ExprNode{extract}}
	}

DistinctKwd:
	"DISTINCT"
|	"DISTINCTROW"

DistinctOpt:
	"ALL"
	{
		$$ = false
	}
|	DistinctKwd
	{
		$$ = true
	}

DefaultFalseDistinctOpt:
	{
		$$ = false
	}
|	DistinctOpt

DefaultTrueDistinctOpt:
	{
		$$ = true
	}
|	DistinctOpt

BuggyDefaultFalseDistinctOpt:
	DefaultFalseDistinctOpt
|	DistinctKwd "ALL"
	{
		$$ = true
	}

FunctionNameConflict:
	"ASCII"
|	"CHARSET"
|	"COALESCE"
|	"COLLATION"
|	"DATE"
|	"DATABASE"
|	"DAY"
|	"HOUR"
|	"IF"
|	"INTERVAL"
|	"FORMAT"
|	"LEFT"
|	"MICROSECOND"
|	"MINUTE"
|	"MONTH"
|	builtinNow
|	"QUARTER"
|	"REPEAT"
|	"REPLACE"
|	"REVERSE"
|	"RIGHT"
|	"ROW_COUNT"
|	"SECOND"
|	"TIME"
|	"TIMESTAMP"
|	"TRUNCATE"
|	"USER"
|	"WEEK"
|	"YEAR"

OptionalBraces:
	{}
|	'(' ')'
	{}

FunctionNameOptionalBraces:
	"CURRENT_USER"
|	"CURRENT_DATE"
|	"CURRENT_ROLE"
|	"UTC_DATE"

FunctionNameDatetimePrecision:
	"CURRENT_TIME"
|	"CURRENT_TIMESTAMP"
|	"LOCALTIME"
|	"LOCALTIMESTAMP"
|	"UTC_TIME"
|	"UTC_TIMESTAMP"

FunctionCallKeyword:
	FunctionNameConflict '(' ExpressionListOpt ')'
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr($1), Args: $3.([]ast.ExprNode)}
	}
|	builtinUser '(' ExpressionListOpt ')'
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr($1), Args: $3.([]ast.ExprNode)}
	}
|	FunctionNameOptionalBraces OptionalBraces
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr($1)}
	}
|	builtinCurDate '(' ')'
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr($1)}
	}
|	FunctionNameDatetimePrecision FuncDatetimePrec
	{
		args := []ast.ExprNode{}
		if $2 != nil {
			args = append(args, $2.(ast.ExprNode))
		}
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr($1), Args: args}
	}
|	"CHAR" '(' ExpressionList ')'
	{
		nilVal := ast.NewValueExpr(nil, parser.charset, parser.collation)
		args := $3.([]ast.ExprNode)
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr(ast.CharFunc),
			Args:   append(args, nilVal),
		}
	}
|	"CHAR" '(' ExpressionList "USING" CharsetName ')'
	{
		charset1 := ast.NewValueExpr($5, "", "")
		args := $3.([]ast.ExprNode)
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr(ast.CharFunc),
			Args:   append(args, charset1),
		}
	}
|	"DATE" stringLit
	{
		expr := ast.NewValueExpr($2, "", "")
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr(ast.DateLiteral), Args: []ast.ExprNode{expr}}
	}
|	"TIME" stringLit
	{
		expr := ast.NewValueExpr($2, "", "")
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr(ast.TimeLiteral), Args: []ast.ExprNode{expr}}
	}
|	"TIMESTAMP" stringLit
	{
		expr := ast.NewValueExpr($2, "", "")
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr(ast.TimestampLiteral), Args: []ast.ExprNode{expr}}
	}
|	"INSERT" '(' ExpressionListOpt ')'
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr(ast.InsertFunc), Args: $3.([]ast.ExprNode)}
	}
|	"MOD" '(' BitExpr ',' BitExpr ')'
	{
		$$ = &ast.BinaryOperationExpr{Op: opcode.Mod, L: $3, R: $5}
	}
|	"PASSWORD" '(' ExpressionListOpt ')'
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr(ast.PasswordFunc), Args: $3.([]ast.ExprNode)}
	}

FunctionCallNonKeyword:
	builtinCurTime '(' FuncDatetimePrecListOpt ')'
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr($1), Args: $3.([]ast.ExprNode)}
	}
|	builtinSysDate '(' FuncDatetimePrecListOpt ')'
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr($1), Args: $3.([]ast.ExprNode)}
	}
|	FunctionNameDateArithMultiForms '(' Expression ',' Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{
				$3,
				$5,
				&ast.TimeUnitExpr{Unit: ast.TimeUnitDay},
			},
		}
	}
|	FunctionNameDateArithMultiForms '(' Expression ',' "INTERVAL" Expression TimeUnit ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{
				$3,
				$6,
				&ast.TimeUnitExpr{Unit: $7.(ast.TimeUnitType)},
			},
		}
	}
|	FunctionNameDateArith '(' Expression ',' "INTERVAL" Expression TimeUnit ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{
				$3,
				$6,
				&ast.TimeUnitExpr{Unit: $7.(ast.TimeUnitType)},
			},
		}
	}
|	builtinExtract '(' TimeUnit "FROM" Expression ')'
	{
		timeUnit := &ast.TimeUnitExpr{Unit: $3.(ast.TimeUnitType)}
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args:   []ast.ExprNode{timeUnit, $5},
		}
	}
|	"GET_FORMAT" '(' GetFormatSelector ',' Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args: []ast.ExprNode{
				&ast.GetFormatSelectorExpr{Selector: $3.(ast.GetFormatSelectorType)},
				$5,
			},
		}
	}
|	builtinPosition '(' BitExpr "IN" Expression ')'
	{
		$$ = &ast.FuncCallExpr{FnName: model.NewCIStr($1), Args: []ast.ExprNode{$3, $5}}
	}
|	builtinSubstring '(' Expression ',' Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args:   []ast.ExprNode{$3, $5},
		}
	}
|	builtinSubstring '(' Expression "FROM" Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args:   []ast.ExprNode{$3, $5},
		}
	}
|	builtinSubstring '(' Expression ',' Expression ',' Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args:   []ast.ExprNode{$3, $5, $7},
		}
	}
|	builtinSubstring '(' Expression "FROM" Expression "FOR" Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args:   []ast.ExprNode{$3, $5, $7},
		}
	}
|	"TIMESTAMPADD" '(' TimestampUnit ',' Expression ',' Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args:   []ast.ExprNode{&ast.TimeUnitExpr{Unit: $3.(ast.TimeUnitType)}, $5, $7},
		}
	}
|	"TIMESTAMPDIFF" '(' TimestampUnit ',' Expression ',' Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args:   []ast.ExprNode{&ast.TimeUnitExpr{Unit: $3.(ast.TimeUnitType)}, $5, $7},
		}
	}
|	builtinTrim '(' Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args:   []ast.ExprNode{$3},
		}
	}
|	builtinTrim '(' Expression "FROM" Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args:   []ast.ExprNode{$5, $3},
		}
	}
|	builtinTrim '(' TrimDirection "FROM" Expression ')'
	{
		spaceVal := ast.NewValueExpr(" ", parser.charset, parser.collation)
		direction := &ast.TrimDirectionExpr{Direction: $3.(ast.TrimDirectionType)}
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args:   []ast.ExprNode{$5, spaceVal, direction},
		}
	}
|	builtinTrim '(' TrimDirection Expression "FROM" Expression ')'
	{
		direction := &ast.TrimDirectionExpr{Direction: $3.(ast.TrimDirectionType)}
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args:   []ast.ExprNode{$6, $4, direction},
		}
	}
|	weightString '(' Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args:   []ast.ExprNode{$3},
		}
	}
|	weightString '(' Expression "AS" Char FieldLen ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args:   []ast.ExprNode{$3, ast.NewValueExpr("CHAR", parser.charset, parser.collation), ast.NewValueExpr($6, parser.charset, parser.collation)},
		}
	}
|	weightString '(' Expression "AS" "BINARY" FieldLen ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args:   []ast.ExprNode{$3, ast.NewValueExpr("BINARY", parser.charset, parser.collation), ast.NewValueExpr($6, parser.charset, parser.collation)},
		}
	}
|	FunctionNameSequence
|	builtinTranslate '(' Expression ',' Expression ',' Expression ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args:   []ast.ExprNode{$3, $5, $7},
		}
	}

GetFormatSelector:
	"DATE"
	{
		$$ = ast.GetFormatSelectorDate
	}
|	"DATETIME"
	{
		$$ = ast.GetFormatSelectorDatetime
	}
|	"TIME"
	{
		$$ = ast.GetFormatSelectorTime
	}
|	"TIMESTAMP"
	{
		$$ = ast.GetFormatSelectorDatetime
	}

FunctionNameDateArith:
	builtinDateAdd
|	builtinDateSub

FunctionNameDateArithMultiForms:
	addDate
|	subDate

TrimDirection:
	"BOTH"
	{
		$$ = ast.TrimBoth
	}
|	"LEADING"
	{
		$$ = ast.TrimLeading
	}
|	"TRAILING"
	{
		$$ = ast.TrimTrailing
	}

FunctionNameSequence:
	"LASTVAL" '(' TableName ')'
	{
		objNameExpr := &ast.TableNameExpr{
			Name: $3.(*ast.TableName),
		}
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr(ast.LastVal),
			Args:   []ast.ExprNode{objNameExpr},
		}
	}
|	"SETVAL" '(' TableName ',' SignedNum ')'
	{
		objNameExpr := &ast.TableNameExpr{
			Name: $3.(*ast.TableName),
		}
		valueExpr := ast.NewValueExpr($5, parser.charset, parser.collation)
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr(ast.SetVal),
			Args:   []ast.ExprNode{objNameExpr, valueExpr},
		}
	}
|	NextValueForSequence

SumExpr:
	"AVG" '(' BuggyDefaultFalseDistinctOpt Expression ')' OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool), Spec: *($6.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool)}
		}
	}
|	builtinApproxCountDistinct '(' ExpressionList ')'
	{
		$$ = &ast.AggregateFuncExpr{F: $1, Args: $3.([]ast.ExprNode), Distinct: false}
	}
|	builtinApproxPercentile '(' ExpressionList ')'
	{
		$$ = &ast.AggregateFuncExpr{F: $1, Args: $3.([]ast.ExprNode)}
	}
|	builtinBitAnd '(' Expression ')' OptWindowingClause
	{
		if $5 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$3}, Spec: *($5.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$3}}
		}
	}
|	builtinBitAnd '(' "ALL" Expression ')' OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Spec: *($6.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4}}
		}
	}
|	builtinBitOr '(' Expression ')' OptWindowingClause
	{
		if $5 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$3}, Spec: *($5.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$3}}
		}
	}
|	builtinBitOr '(' "ALL" Expression ')' OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Spec: *($6.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4}}
		}
	}
|	builtinBitXor '(' Expression ')' OptWindowingClause
	{
		if $5 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$3}, Spec: *($5.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$3}}
		}
	}
|	builtinBitXor '(' "ALL" Expression ')' OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Spec: *($6.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4}}
		}
	}
|	builtinCount '(' DistinctKwd ExpressionList ')'
	{
		$$ = &ast.AggregateFuncExpr{F: $1, Args: $4.([]ast.ExprNode), Distinct: true}
	}
|	builtinCount '(' "ALL" Expression ')' OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Spec: *($6.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4}}
		}
	}
|	builtinCount '(' Expression ')' OptWindowingClause
	{
		if $5 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$3}, Spec: *($5.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$3}}
		}
	}
|	builtinCount '(' '*' ')' OptWindowingClause
	{
		args := []ast.ExprNode{ast.NewValueExpr(1, parser.charset, parser.collation)}
		if $5 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: args, Spec: *($5.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: args}
		}
	}
|	builtinGroupConcat '(' BuggyDefaultFalseDistinctOpt ExpressionList OrderByOptional OptGConcatSeparator ')' OptWindowingClause
	{
		args := $4.([]ast.ExprNode)
		args = append(args, $6.(ast.ExprNode))
		if $8 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: args, Distinct: $3.(bool), Spec: *($8.(*ast.WindowSpec))}
		} else {
			agg := &ast.AggregateFuncExpr{F: $1, Args: args, Distinct: $3.(bool)}
			if $5 != nil {
				agg.Order = $5.(*ast.OrderByClause)
			}
			$$ = agg
		}
	}
|	builtinMax '(' BuggyDefaultFalseDistinctOpt Expression ')' OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool), Spec: *($6.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool)}
		}
	}
|	builtinMin '(' BuggyDefaultFalseDistinctOpt Expression ')' OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool), Spec: *($6.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool)}
		}
	}
|	builtinSum '(' BuggyDefaultFalseDistinctOpt Expression ')' OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool), Spec: *($6.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool)}
		}
	}
|	builtinStddevPop '(' BuggyDefaultFalseDistinctOpt Expression ')' OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: ast.AggFuncStddevPop, Args: []ast.ExprNode{$4}, Distinct: $3.(bool), Spec: *($6.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: ast.AggFuncStddevPop, Args: []ast.ExprNode{$4}, Distinct: $3.(bool)}
		}
	}
|	builtinStddevSamp '(' BuggyDefaultFalseDistinctOpt Expression ')' OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool), Spec: *($6.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool)}
		}
	}
|	builtinVarPop '(' BuggyDefaultFalseDistinctOpt Expression ')' OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: ast.AggFuncVarPop, Args: []ast.ExprNode{$4}, Distinct: $3.(bool), Spec: *($6.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: ast.AggFuncVarPop, Args: []ast.ExprNode{$4}, Distinct: $3.(bool)}
		}
	}
|	builtinVarSamp '(' BuggyDefaultFalseDistinctOpt Expression ')' OptWindowingClause
	{
		$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Distinct: $3.(bool)}
	}
|	"JSON_ARRAYAGG" '(' Expression ')' OptWindowingClause
	{
		if $5 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$3}, Spec: *($5.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$3}}
		}
	}
|	"JSON_ARRAYAGG" '(' "ALL" Expression ')' OptWindowingClause
	{
		if $6 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4}, Spec: *($6.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4}}
		}
	}
|	"JSON_OBJECTAGG" '(' Expression ',' Expression ')' OptWindowingClause
	{
		if $7 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$3, $5}, Spec: *($7.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$3, $5}}
		}
	}
|	"JSON_OBJECTAGG" '(' "ALL" Expression ',' Expression ')' OptWindowingClause
	{
		if $8 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4, $6}, Spec: *($8.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4, $6}}
		}
	}
|	"JSON_OBJECTAGG" '(' Expression ',' "ALL" Expression ')' OptWindowingClause
	{
		if $8 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$3, $6}, Spec: *($8.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$3, $6}}
		}
	}
|	"JSON_OBJECTAGG" '(' "ALL" Expression ',' "ALL" Expression ')' OptWindowingClause
	{
		if $9 != nil {
			$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$4, $7}, Spec: *($9.(*ast.WindowSpec))}
		} else {
			$$ = &ast.AggregateFuncExpr{F: $1, Args: []ast.ExprNode{$4, $7}}
		}
	}

OptGConcatSeparator:
	{
		$$ = ast.NewValueExpr(",", "", "")
	}
|	"SEPARATOR" stringLit
	{
		$$ = ast.NewValueExpr($2, "", "")
	}

FunctionCallGeneric:
	identifier '(' ExpressionListOpt ')'
	{
		$$ = &ast.FuncCallExpr{
			FnName: model.NewCIStr($1),
			Args:   $3.([]ast.ExprNode),
		}
	}
|	Identifier '.' Identifier '(' ExpressionListOpt ')'
	{
		var tp ast.FuncCallExprType
		if isInTokenMap($3) {
			tp = ast.FuncCallExprTypeKeyword
		} else {
			tp = ast.FuncCallExprTypeGeneric
		}
		$$ = &ast.FuncCallExpr{
			Tp:     tp,
			Schema: model.NewCIStr($1),
			FnName: model.NewCIStr($3),
			Args:   $5.([]ast.ExprNode),
		}
	}

FuncDatetimePrec:
	{
		$$ = nil
	}
|	'(' ')'
	{
		$$ = nil
	}
|	'(' intLit ')'
	{
		expr := ast.NewValueExpr($2, parser.charset, parser.collation)
		$$ = expr
	}

TimeUnit:
	TimestampUnit
|	"SECOND_MICROSECOND"
	{
		$$ = ast.TimeUnitSecondMicrosecond
	}
|	"MINUTE_MICROSECOND"
	{
		$$ = ast.TimeUnitMinuteMicrosecond
	}
|	"MINUTE_SECOND"
	{
		$$ = ast.TimeUnitMinuteSecond
	}
|	"HOUR_MICROSECOND"
	{
		$$ = ast.TimeUnitHourMicrosecond
	}
|	"HOUR_SECOND"
	{
		$$ = ast.TimeUnitHourSecond
	}
|	"HOUR_MINUTE"
	{
		$$ = ast.TimeUnitHourMinute
	}
|	"DAY_MICROSECOND"
	{
		$$ = ast.TimeUnitDayMicrosecond
	}
|	"DAY_SECOND"
	{
		$$ = ast.TimeUnitDaySecond
	}
|	"DAY_MINUTE"
	{
		$$ = ast.TimeUnitDayMinute
	}
|	"DAY_HOUR"
	{
		$$ = ast.TimeUnitDayHour
	}
|	"YEAR_MONTH"
	{
		$$ = ast.TimeUnitYearMonth
	}

TimestampUnit:
	"MICROSECOND"
	{
		$$ = ast.TimeUnitMicrosecond
	}
|	"SECOND"
	{
		$$ = ast.TimeUnitSecond
	}
|	"MINUTE"
	{
		$$ = ast.TimeUnitMinute
	}
|	"HOUR"
	{
		$$ = ast.TimeUnitHour
	}
|	"DAY"
	{
		$$ = ast.TimeUnitDay
	}
|	"WEEK"
	{
		$$ = ast.TimeUnitWeek
	}
|	"MONTH"
	{
		$$ = ast.TimeUnitMonth
	}
|	"QUARTER"
	{
		$$ = ast.TimeUnitQuarter
	}
|	"YEAR"
	{
		$$ = ast.TimeUnitYear
	}
|	"SQL_TSI_SECOND"
	{
		$$ = ast.TimeUnitSecond
	}
|	"SQL_TSI_MINUTE"
	{
		$$ = ast.TimeUnitMinute
	}
|	"SQL_TSI_HOUR"
	{
		$$ = ast.TimeUnitHour
	}
|	"SQL_TSI_DAY"
	{
		$$ = ast.TimeUnitDay
	}
|	"SQL_TSI_WEEK"
	{
		$$ = ast.TimeUnitWeek
	}
|	"SQL_TSI_MONTH"
	{
		$$ = ast.TimeUnitMonth
	}
|	"SQL_TSI_QUARTER"
	{
		$$ = ast.TimeUnitQuarter
	}
|	"SQL_TSI_YEAR"
	{
		$$ = ast.TimeUnitYear
	}

ExpressionOpt:
	{
		$$ = nil
	}
|	Expression

WhenClauseList:
	WhenClause
	{
		$$ = []*ast.WhenClause{$1.(*ast.WhenClause)}
	}
|	WhenClauseList WhenClause
	{
		$$ = append($1.([]*ast.WhenClause), $2.(*ast.WhenClause))
	}

WhenClause:
	"WHEN" Expression "THEN" Expression
	{
		$$ = &ast.WhenClause{
			Expr:   $2,
			Result: $4,
		}
	}

ElseOpt:
	/* empty */
	{
		$$ = nil
	}
|	"ELSE" Expression
	{
		$$ = $2
	}

CastType:
	"BINARY" OptFieldLen
	{
		tp := types.NewFieldType(mysql.TypeVarString)
		tp.SetFlen($2.(int)) // TODO: Flen should be the flen of expression
		if tp.GetFlen() != types.UnspecifiedLength {
			tp.SetType(mysql.TypeString)
		}
		tp.SetCharset(charset.CharsetBin)
		tp.SetCollate(charset.CollationBin)
		tp.AddFlag(mysql.BinaryFlag)
		$$ = tp
	}
|	Char OptFieldLen OptBinary
	{
		tp := types.NewFieldType(mysql.TypeVarString)
		tp.SetFlen($2.(int)) // TODO: Flen should be the flen of expression
		tp.SetCharset($3.(*ast.OptBinary).Charset)
		if $3.(*ast.OptBinary).IsBinary {
			tp.AddFlag(mysql.BinaryFlag)
			tp.SetCharset(charset.CharsetBin)
			tp.SetCollate(charset.CollationBin)
		} else if tp.GetCharset() != "" {
			co, err := charset.GetDefaultCollation(tp.GetCharset())
			if err != nil {
				yylex.AppendError(yylex.Errorf("Get collation error for charset: %s", tp.GetCharset()))
				return 1
			}
			tp.SetCollate(co)
			parser.explicitCharset = true
		} else {
			tp.SetCharset(parser.charset)
			tp.SetCollate(parser.collation)
		}
		$$ = tp
	}
|	"DATE"
	{
		tp := types.NewFieldType(mysql.TypeDate)
		tp.SetCharset(charset.CharsetBin)
		tp.SetCollate(charset.CollationBin)
		tp.AddFlag(mysql.BinaryFlag)
		$$ = tp
	}
|	"YEAR"
	{
		tp := types.NewFieldType(mysql.TypeYear)
		tp.SetCharset(charset.CharsetBin)
		tp.SetCollate(charset.CollationBin)
		tp.AddFlag(mysql.BinaryFlag)
		$$ = tp
	}
|	"DATETIME" OptFieldLen
	{
		tp := types.NewFieldType(mysql.TypeDatetime)
		flen, _ := mysql.GetDefaultFieldLengthAndDecimalForCast(mysql.TypeDatetime)
		tp.SetFlen(flen)
		tp.SetDecimal($2.(int))
		if tp.GetDecimal() > 0 {
			tp.SetFlen(tp.GetFlen() + 1 + tp.GetDecimal())
		}
		tp.SetCharset(charset.CharsetBin)
		tp.SetCollate(charset.CollationBin)
		tp.AddFlag(mysql.BinaryFlag)
		$$ = tp
	}
|	"DECIMAL" FloatOpt
	{
		fopt := $2.(*ast.FloatOpt)
		tp := types.NewFieldType(mysql.TypeNewDecimal)
		tp.SetFlen(fopt.Flen)
		tp.SetDecimal(fopt.Decimal)
		tp.SetCharset(charset.CharsetBin)
		tp.SetCollate(charset.CollationBin)
		tp.AddFlag(mysql.BinaryFlag)
		$$ = tp
	}
|	"TIME" OptFieldLen
	{
		tp := types.NewFieldType(mysql.TypeDuration)
		flen, _ := mysql.GetDefaultFieldLengthAndDecimalForCast(mysql.TypeDuration)
		tp.SetFlen(flen)
		tp.SetDecimal($2.(int))
		if tp.GetDecimal() > 0 {
			tp.SetFlen(tp.GetFlen() + 1 + tp.GetDecimal())
		}
		tp.SetCharset(charset.CharsetBin)
		tp.SetCollate(charset.CollationBin)
		tp.AddFlag(mysql.BinaryFlag)
		$$ = tp
	}
|	"SIGNED" OptInteger
	{
		tp := types.NewFieldType(mysql.TypeLonglong)
		tp.SetCharset(charset.CharsetBin)
		tp.SetCollate(charset.CollationBin)
		tp.AddFlag(mysql.BinaryFlag)
		$$ = tp
	}
|	"UNSIGNED" OptInteger
	{
		tp := types.NewFieldType(mysql.TypeLonglong)
		tp.AddFlag(mysql.UnsignedFlag | mysql.BinaryFlag)
		tp.SetCharset(charset.CharsetBin)
		tp.SetCollate(charset.CollationBin)
		$$ = tp
	}
|	"JSON"
	{
		tp := types.NewFieldType(mysql.TypeJSON)
		tp.AddFlag(mysql.BinaryFlag | mysql.ParseToJSONFlag)
		tp.SetCharset(mysql.DefaultCharset)
		tp.SetCollate(mysql.DefaultCollationName)
		$$ = tp
	}
|	"DOUBLE"
	{
		tp := types.NewFieldType(mysql.TypeDouble)
		flen, decimal := mysql.GetDefaultFieldLengthAndDecimalForCast(mysql.TypeDouble)
		tp.SetFlen(flen)
		tp.SetDecimal(decimal)
		tp.AddFlag(mysql.BinaryFlag)
		tp.SetCharset(charset.CharsetBin)
		tp.SetCollate(charset.CollationBin)
		$$ = tp
	}
|	"FLOAT" FloatOpt
	{
		tp := types.NewFieldType(mysql.TypeFloat)
		fopt := $2.(*ast.FloatOpt)
		if fopt.Flen >= 54 {
			yylex.AppendError(ErrTooBigPrecision.GenWithStackByArgs(fopt.Flen, "CAST", 53))
		} else if fopt.Flen >= 25 {
			tp = types.NewFieldType(mysql.TypeDouble)
		}
		flen, decimal := mysql.GetDefaultFieldLengthAndDecimalForCast(tp.GetType())
		tp.SetFlen(flen)
		tp.SetDecimal(decimal)
		tp.AddFlag(mysql.BinaryFlag)
		tp.SetCharset(charset.CharsetBin)
		tp.SetCollate(charset.CollationBin)
		$$ = tp
	}
|	"REAL"
	{
		var tp *types.FieldType
		if parser.lexer.GetSQLMode().HasRealAsFloatMode() {
			tp = types.NewFieldType(mysql.TypeFloat)
		} else {
			tp = types.NewFieldType(mysql.TypeDouble)
		}
		flen, decimal := mysql.GetDefaultFieldLengthAndDecimalForCast(tp.GetType())
		tp.SetFlen(flen)
		tp.SetDecimal(decimal)
		tp.AddFlag(mysql.BinaryFlag)
		tp.SetCharset(charset.CharsetBin)
		tp.SetCollate(charset.CollationBin)
		$$ = tp
	}

Priority:
	"LOW_PRIORITY"
	{
		$$ = mysql.LowPriority
	}
|	"HIGH_PRIORITY"
	{
		$$ = mysql.HighPriority
	}
|	"DELAYED"
	{
		$$ = mysql.DelayedPriority
	}

PriorityOpt:
	{
		$$ = mysql.NoPriority
	}
|	Priority

TableName:
	Identifier
	{
		$$ = &ast.TableName{Name: model.NewCIStr($1)}
	}
|	Identifier '.' Identifier
	{
		$$ = &ast.TableName{Schema: model.NewCIStr($1), Name: model.NewCIStr($3)}
	}

TableNameList:
	TableName
	{
		tbl := []*ast.TableName{$1.(*ast.TableName)}
		$$ = tbl
	}
|	TableNameList ',' TableName
	{
		$$ = append($1.([]*ast.TableName), $3.(*ast.TableName))
	}

TableNameOptWild:
	Identifier OptWild
	{
		$$ = &ast.TableName{Name: model.NewCIStr($1)}
	}
|	Identifier '.' Identifier OptWild
	{
		$$ = &ast.TableName{Schema: model.NewCIStr($1), Name: model.NewCIStr($3)}
	}

TableAliasRefList:
	TableNameOptWild
	{
		tbl := []*ast.TableName{$1.(*ast.TableName)}
		$$ = tbl
	}
|	TableAliasRefList ',' TableNameOptWild
	{
		$$ = append($1.([]*ast.TableName), $3.(*ast.TableName))
	}

OptWild:
	%prec empty
	{}
|	'.' '*'
	{}

QuickOptional:
	%prec empty
	{
		$$ = false
	}
|	"QUICK"
	{
		$$ = true
	}

/***************************Prepared Statement Start******************************
 * See https://dev.mysql.com/doc/refman/5.7/en/prepare.html
 * Example:
 * PREPARE stmt_name FROM 'SELECT SQRT(POW(?,2) + POW(?,2)) AS hypotenuse';
 * OR
 * SET @s = 'SELECT SQRT(POW(?,2) + POW(?,2)) AS hypotenuse';
 * PREPARE stmt_name FROM @s;
 */
PreparedStmt:
	"PREPARE" Identifier "FROM" PrepareSQL
	{
		var sqlText string
		var sqlVar *ast.VariableExpr
		switch x := $4.(type) {
		case string:
			sqlText = x
		case *ast.VariableExpr:
			sqlVar = x
		}
		$$ = &ast.PrepareStmt{
			Name:    $2,
			SQLText: sqlText,
			SQLVar:  sqlVar,
		}
	}

PrepareSQL:
	stringLit
	{
		$$ = $1
	}
|	UserVariable
	{
		$$ = $1
	}

/*
 * See https://dev.mysql.com/doc/refman/5.7/en/execute.html
 * Example:
 * EXECUTE stmt1 USING @a, @b;
 * OR
 * EXECUTE stmt1;
 */
ExecuteStmt:
	"EXECUTE" Identifier
	{
		$$ = &ast.ExecuteStmt{Name: $2}
	}
|	"EXECUTE" Identifier "USING" UserVariableList
	{
		$$ = &ast.ExecuteStmt{
			Name:      $2,
			UsingVars: $4.([]ast.ExprNode),
		}
	}

UserVariableList:
	UserVariable
	{
		$$ = []ast.ExprNode{$1}
	}
|	UserVariableList ',' UserVariable
	{
		$$ = append($1.([]ast.ExprNode), $3)
	}

DeallocateStmt:
	DeallocateSym "PREPARE" Identifier
	{
		$$ = &ast.DeallocateStmt{Name: $3}
	}

DeallocateSym:
	"DEALLOCATE"
|	"DROP"

RollbackStmt:
	"ROLLBACK"
	{
		$$ = &ast.RollbackStmt{}
	}
|	"ROLLBACK" CompletionTypeWithinTransaction
	{
		$$ = &ast.RollbackStmt{CompletionType: $2.(ast.CompletionType)}
	}

CompletionTypeWithinTransaction:
	"AND" "CHAIN" "NO" "RELEASE"
	{
		$$ = ast.CompletionTypeChain
	}
|	"AND" "NO" "CHAIN" "RELEASE"
	{
		$$ = ast.CompletionTypeRelease
	}
|	"AND" "NO" "CHAIN" "NO" "RELEASE"
	{
		$$ = ast.CompletionTypeDefault
	}
|	"AND" "CHAIN"
	{
		$$ = ast.CompletionTypeChain
	}
|	"AND" "NO" "CHAIN"
	{
		$$ = ast.CompletionTypeDefault
	}
|	"RELEASE"
	{
		$$ = ast.CompletionTypeRelease
	}
|	"NO" "RELEASE"
	{
		$$ = ast.CompletionTypeDefault
	}

ShutdownStmt:
	"SHUTDOWN"
	{
		$$ = &ast.ShutdownStmt{}
	}

RestartStmt:
	"RESTART"
	{
		$$ = &ast.RestartStmt{}
	}

HelpStmt:
	"HELP" stringLit
	{
		$$ = &ast.HelpStmt{Topic: $2}
	}

SelectStmtBasic:
	"SELECT" SelectStmtOpts SelectStmtFieldList
	{
		st := &ast.SelectStmt{
			SelectStmtOpts: $2.(*ast.SelectStmtOpts),
			Distinct:       $2.(*ast.SelectStmtOpts).Distinct,
			Fields:         $3.(*ast.FieldList),
			Kind:           ast.SelectStmtKindSelect,
		}
		if st.SelectStmtOpts.TableHints != nil {
			st.TableHints = st.SelectStmtOpts.TableHints
		}
		$$ = st
	}

SelectStmtFromDualTable:
	SelectStmtBasic FromDual WhereClauseOptional
	{
		st := $1.(*ast.SelectStmt)
		lastField := st.Fields.Fields[len(st.Fields.Fields)-1]
		if lastField.Expr != nil && lastField.AsName.O == "" {
			lastEnd := yyS[yypt-1].offset - 1
			lastField.SetText(parser.lexer.client, parser.src[lastField.Offset:lastEnd])
		}
		if $3 != nil {
			st.Where = $3.(ast.ExprNode)
		}
	}

SelectStmtFromTable:
	SelectStmtBasic "FROM" TableRefsClause WhereClauseOptional SelectStmtGroup HavingClause WindowClauseOptional
	{
		st := $1.(*ast.SelectStmt)
		st.From = $3.(*ast.TableRefsClause)
		lastField := st.Fields.Fields[len(st.Fields.Fields)-1]
		if lastField.Expr != nil && lastField.AsName.O == "" {
			lastEnd := parser.endOffset(&yyS[yypt-5])
			lastField.SetText(parser.lexer.client, parser.src[lastField.Offset:lastEnd])
		}
		if $4 != nil {
			st.Where = $4.(ast.ExprNode)
		}
		if $5 != nil {
			st.GroupBy = $5.(*ast.GroupByClause)
		}
		if $6 != nil {
			st.Having = $6.(*ast.HavingClause)
		}
		if $7 != nil {
			st.WindowSpecs = ($7.([]ast.WindowSpec))
		}
		$$ = st
	}

TableSampleOpt:
	%prec empty
	{
		$$ = nil
	}
|	"TABLESAMPLE" TableSampleMethodOpt '(' Expression TableSampleUnitOpt ')' RepeatableOpt
	{
		var repSeed ast.ExprNode
		if $7 != nil {
			repSeed = ast.NewValueExpr($7, parser.charset, parser.collation)
		}
		$$ = &ast.TableSample{
			SampleMethod:     $2.(ast.SampleMethodType),
			Expr:             ast.NewValueExpr($4, parser.charset, parser.collation),
			SampleClauseUnit: $5.(ast.SampleClauseUnitType),
			RepeatableSeed:   repSeed,
		}
	}
|	"TABLESAMPLE" TableSampleMethodOpt '(' ')' RepeatableOpt
	{
		var repSeed ast.ExprNode
		if $5 != nil {
			repSeed = ast.NewValueExpr($5, parser.charset, parser.collation)
		}
		$$ = &ast.TableSample{
			SampleMethod:   $2.(ast.SampleMethodType),
			RepeatableSeed: repSeed,
		}
	}

TableSampleMethodOpt:
	%prec empty
	{
		$$ = ast.SampleMethodTypeNone
	}
|	"SYSTEM"
	{
		$$ = ast.SampleMethodTypeSystem
	}
|	"BERNOULLI"
	{
		$$ = ast.SampleMethodTypeBernoulli
	}
|	"REGIONS"
	{
		$$ = ast.SampleMethodTypeTiDBRegion
	}

TableSampleUnitOpt:
	%prec empty
	{
		$$ = ast.SampleClauseUnitTypeDefault
	}
|	"ROWS"
	{
		$$ = ast.SampleClauseUnitTypeRow
	}
|	"PERCENT"
	{
		$$ = ast.SampleClauseUnitTypePercent
	}

RepeatableOpt:
	%prec empty
	{
		$$ = nil
	}
|	"REPEATABLE" '(' Expression ')'
	{
		$$ = $3
	}

SelectStmt:
	SelectStmtBasic WhereClauseOptional SelectStmtGroup OrderByOptional SelectStmtLimitOpt SelectLockOpt SelectStmtIntoOption
	{
		st := $1.(*ast.SelectStmt)
		if $6 != nil {
			st.LockInfo = $6.(*ast.SelectLockInfo)
		}
		lastField := st.Fields.Fields[len(st.Fields.Fields)-1]
		if lastField.Expr != nil && lastField.AsName.O == "" {
			src := parser.src
			var lastEnd int
			if $2 != nil {
				lastEnd = yyS[yypt-5].offset - 1
			} else if $3 != nil {
				lastEnd = yyS[yypt-4].offset - 1
			} else if $4 != nil {
				lastEnd = yyS[yypt-3].offset - 1
			} else if $5 != nil {
				lastEnd = yyS[yypt-2].offset - 1
			} else if st.LockInfo != nil && st.LockInfo.LockType != ast.SelectLockNone {
				lastEnd = yyS[yypt-1].offset - 1
			} else if $7 != nil {
				lastEnd = yyS[yypt].offset - 1
			} else {
				lastEnd = len(src)
				if src[lastEnd-1] == ';' {
					lastEnd--
				}
			}
			lastField.SetText(parser.lexer.client, src[lastField.Offset:lastEnd])
		}
		if $2 != nil {
			st.Where = $2.(ast.ExprNode)
		}
		if $3 != nil {
			st.GroupBy = $3.(*ast.GroupByClause)
		}
		if $4 != nil {
			st.OrderBy = $4.(*ast.OrderByClause)
		}
		if $5 != nil {
			st.Limit = $5.(*ast.Limit)
		}
		if $7 != nil {
			st.SelectIntoOpt = $7.(*ast.SelectIntoOption)
		}
		$$ = st
	}
|	SelectStmtFromDualTable SelectStmtGroup OrderByOptional SelectStmtLimitOpt SelectLockOpt SelectStmtIntoOption
	{
		st := $1.(*ast.SelectStmt)
		if $2 != nil {
			st.GroupBy = $2.(*ast.GroupByClause)
		}
		if $3 != nil {
			st.OrderBy = $3.(*ast.OrderByClause)
		}
		if $4 != nil {
			st.Limit = $4.(*ast.Limit)
		}
		if $5 != nil {
			st.LockInfo = $5.(*ast.SelectLockInfo)
		}
		if $6 != nil {
			st.SelectIntoOpt = $6.(*ast.SelectIntoOption)
		}
		$$ = st
	}
|	SelectStmtFromTable OrderByOptional SelectStmtLimitOpt SelectLockOpt SelectStmtIntoOption
	{
		st := $1.(*ast.SelectStmt)
		if $4 != nil {
			st.LockInfo = $4.(*ast.SelectLockInfo)
		}
		if $2 != nil {
			st.OrderBy = $2.(*ast.OrderByClause)
		}
		if $3 != nil {
			st.Limit = $3.(*ast.Limit)
		}
		if $5 != nil {
			st.SelectIntoOpt = $5.(*ast.SelectIntoOption)
		}
		$$ = st
	}
|	"TABLE" TableName OrderByOptional SelectStmtLimitOpt SelectLockOpt SelectStmtIntoOption
	{
		st := &ast.SelectStmt{
			Kind:   ast.SelectStmtKindTable,
			Fields: &ast.FieldList{Fields: []*ast.SelectField{{WildCard: &ast.WildCardField{}}}},
		}
		ts := &ast.TableSource{Source: $2.(*ast.TableName)}
		st.From = &ast.TableRefsClause{TableRefs: &ast.Join{Left: ts}}
		if $3 != nil {
			st.OrderBy = $3.(*ast.OrderByClause)
		}
		if $4 != nil {
			st.Limit = $4.(*ast.Limit)
		}
		if $5 != nil {
			st.LockInfo = $5.(*ast.SelectLockInfo)
		}
		if $6 != nil {
			st.SelectIntoOpt = $6.(*ast.SelectIntoOption)
		}
		$$ = st
	}
|	"VALUES" ValuesStmtList OrderByOptional SelectStmtLimitOpt SelectLockOpt SelectStmtIntoOption
	{
		st := &ast.SelectStmt{
			Kind:   ast.SelectStmtKindValues,
			Fields: &ast.FieldList{Fields: []*ast.SelectField{{WildCard: &ast.WildCardField{}}}},
			Lists:  $2.([]*ast.RowExpr),
		}
		if $3 != nil {
			st.OrderBy = $3.(*ast.OrderByClause)
		}
		if $4 != nil {
			st.Limit = $4.(*ast.Limit)
		}
		if $5 != nil {
			st.LockInfo = $5.(*ast.SelectLockInfo)
		}
		if $6 != nil {
			st.SelectIntoOpt = $6.(*ast.SelectIntoOption)
		}
		$$ = st
	}

SelectStmtWithClause:
	WithClause SelectStmt
	{
		sel := $2.(*ast.SelectStmt)
		sel.With = $1.(*ast.WithClause)
		$$ = sel
	}
|	WithClause SubSelect
	{
		var sel ast.StmtNode
		switch x := $2.(*ast.SubqueryExpr).Query.(type) {
		case *ast.SelectStmt:
			x.IsInBraces = true
			x.WithBeforeBraces = true
			x.With = $1.(*ast.WithClause)
			sel = x
		case *ast.SetOprStmt:
			x.IsInBraces = true
			x.With = $1.(*ast.WithClause)
			sel = x
		}
		$$ = sel
	}

WithClause:
	"WITH" WithList
	{
		$$ = $2
	}
|	"WITH" recursive WithList
	{
		ws := $3.(*ast.WithClause)
		ws.IsRecursive = true
		for _, cte := range ws.CTEs {
			cte.IsRecursive = true
		}
		$$ = ws
	}

WithList:
	WithList ',' CommonTableExpr
	{
		ws := $1.(*ast.WithClause)
		ws.CTEs = append(ws.CTEs, $3.(*ast.CommonTableExpression))
		$$ = ws
	}
|	CommonTableExpr
	{
		ws := &ast.WithClause{}
		ws.CTEs = make([]*ast.CommonTableExpression, 0, 4)
		ws.CTEs = append(ws.CTEs, $1.(*ast.CommonTableExpression))
		$$ = ws
	}

CommonTableExpr:
	Identifier IdentListWithParenOpt "AS" SubSelect
	{
		cte := &ast.CommonTableExpression{}
		cte.Name = model.NewCIStr($1)
		cte.ColNameList = $2.([]model.CIStr)
		cte.Query = $4.(*ast.SubqueryExpr)
		$$ = cte
	}

FromDual:
	"FROM" "DUAL"

WindowClauseOptional:
	{
		$$ = nil
	}
|	"WINDOW" WindowDefinitionList
	{
		$$ = $2.([]ast.WindowSpec)
	}

WindowDefinitionList:
	WindowDefinition
	{
		$$ = []ast.WindowSpec{$1.(ast.WindowSpec)}
	}
|	WindowDefinitionList ',' WindowDefinition
	{
		$$ = append($1.([]ast.WindowSpec), $3.(ast.WindowSpec))
	}

WindowDefinition:
	WindowName "AS" WindowSpec
	{
		var spec = $3.(ast.WindowSpec)
		spec.Name = $1.(model.CIStr)
		$$ = spec
	}

WindowName:
	Identifier
	{
		$$ = model.NewCIStr($1)
	}

WindowSpec:
	'(' WindowSpecDetails ')'
	{
		$$ = $2.(ast.WindowSpec)
	}

WindowSpecDetails:
	OptExistingWindowName OptPartitionClause OptWindowOrderByClause OptWindowFrameClause
	{
		spec := ast.WindowSpec{Ref: $1.(model.CIStr)}
		if $2 != nil {
			spec.PartitionBy = $2.(*ast.PartitionByClause)
		}
		if $3 != nil {
			spec.OrderBy = $3.(*ast.OrderByClause)
		}
		if $4 != nil {
			spec.Frame = $4.(*ast.FrameClause)
		}
		$$ = spec
	}

OptExistingWindowName:
	{
		$$ = model.CIStr{}
	}
|	WindowName

OptPartitionClause:
	{
		$$ = nil
	}
|	"PARTITION" "BY" ByList
	{
		$$ = &ast.PartitionByClause{Items: $3.([]*ast.ByItem)}
	}

OptWindowOrderByClause:
	{
		$$ = nil
	}
|	"ORDER" "BY" ByList
	{
		$$ = &ast.OrderByClause{Items: $3.([]*ast.ByItem)}
	}

OptWindowFrameClause:
	{
		$$ = nil
	}
|	WindowFrameUnits WindowFrameExtent
	{
		$$ = &ast.FrameClause{
			Type:   $1.(ast.FrameType),
			Extent: $2.(ast.FrameExtent),
		}
	}

WindowFrameUnits:
	"ROWS"
	{
		$$ = ast.FrameType(ast.Rows)
	}
|	"RANGE"
	{
		$$ = ast.FrameType(ast.Ranges)
	}
|	"GROUPS"
	{
		$$ = ast.FrameType(ast.Groups)
	}

WindowFrameExtent:
	WindowFrameStart
	{
		$$ = ast.FrameExtent{
			Start: $1.(ast.FrameBound),
			End:   ast.FrameBound{Type: ast.CurrentRow},
		}
	}
|	WindowFrameBetween

WindowFrameStart:
	"UNBOUNDED" "PRECEDING"
	{
		$$ = ast.FrameBound{Type: ast.Preceding, UnBounded: true}
	}
|	NumLiteral "PRECEDING"
	{
		$$ = ast.FrameBound{Type: ast.Preceding, Expr: ast.NewValueExpr($1, parser.charset, parser.collation)}
	}
|	paramMarker "PRECEDING"
	{
		$$ = ast.FrameBound{Type: ast.Preceding, Expr: ast.NewParamMarkerExpr(yyS[yypt].offset)}
	}
|	"INTERVAL" Expression TimeUnit "PRECEDING"
	{
		$$ = ast.FrameBound{Type: ast.Preceding, Expr: $2, Unit: $3.(ast.TimeUnitType)}
	}
|	"CURRENT" "ROW"
	{
		$$ = ast.FrameBound{Type: ast.CurrentRow}
	}

WindowFrameBetween:
	"BETWEEN" WindowFrameBound "AND" WindowFrameBound
	{
		$$ = ast.FrameExtent{Start: $2.(ast.FrameBound), End: $4.(ast.FrameBound)}
	}

WindowFrameBound:
	WindowFrameStart
|	"UNBOUNDED" "FOLLOWING"
	{
		$$ = ast.FrameBound{Type: ast.Following, UnBounded: true}
	}
|	NumLiteral "FOLLOWING"
	{
		$$ = ast.FrameBound{Type: ast.Following, Expr: ast.NewValueExpr($1, parser.charset, parser.collation)}
	}
|	paramMarker "FOLLOWING"
	{
		$$ = ast.FrameBound{Type: ast.Following, Expr: ast.NewParamMarkerExpr(yyS[yypt].offset)}
	}
|	"INTERVAL" Expression TimeUnit "FOLLOWING"
	{
		$$ = ast.FrameBound{Type: ast.Following, Expr: $2, Unit: $3.(ast.TimeUnitType)}
	}

OptWindowingClause:
	{
		$$ = nil
	}
|	WindowingClause
	{
		spec := $1.(ast.WindowSpec)
		$$ = &spec
	}

WindowingClause:
	"OVER" WindowNameOrSpec
	{
		$$ = $2.(ast.WindowSpec)
	}

WindowNameOrSpec:
	WindowName
	{
		$$ = ast.WindowSpec{Name: $1.(model.CIStr), OnlyAlias: true}
	}
|	WindowSpec

WindowFuncCall:
	"ROW_NUMBER" '(' ')' WindowingClause
	{
		$$ = &ast.WindowFuncExpr{F: $1, Spec: $4.(ast.WindowSpec)}
	}
|	"RANK" '(' ')' WindowingClause
	{
		$$ = &ast.WindowFuncExpr{F: $1, Spec: $4.(ast.WindowSpec)}
	}
|	"DENSE_RANK" '(' ')' WindowingClause
	{
		$$ = &ast.WindowFuncExpr{F: $1, Spec: $4.(ast.WindowSpec)}
	}
|	"CUME_DIST" '(' ')' WindowingClause
	{
		$$ = &ast.WindowFuncExpr{F: $1, Spec: $4.(ast.WindowSpec)}
	}
|	"PERCENT_RANK" '(' ')' WindowingClause
	{
		$$ = &ast.WindowFuncExpr{F: $1, Spec: $4.(ast.WindowSpec)}
	}
|	"NTILE" '(' SimpleExpr ')' WindowingClause
	{
		$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$3}, Spec: $5.(ast.WindowSpec)}
	}
|	"LEAD" '(' Expression OptLeadLagInfo ')' OptNullTreatment WindowingClause
	{
		args := []ast.ExprNode{$3}
		if $4 != nil {
			args = append(args, $4.([]ast.ExprNode)...)
		}
		$$ = &ast.WindowFuncExpr{F: $1, Args: args, IgnoreNull: $6.(bool), Spec: $7.(ast.WindowSpec)}
	}
|	"LAG" '(' Expression OptLeadLagInfo ')' OptNullTreatment WindowingClause
	{
		args := []ast.ExprNode{$3}
		if $4 != nil {
			args = append(args, $4.([]ast.ExprNode)...)
		}
		$$ = &ast.WindowFuncExpr{F: $1, Args: args, IgnoreNull: $6.(bool), Spec: $7.(ast.WindowSpec)}
	}
|	"FIRST_VALUE" '(' Expression ')' OptNullTreatment WindowingClause
	{
		$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$3}, IgnoreNull: $5.(bool), Spec: $6.(ast.WindowSpec)}
	}
|	"LAST_VALUE" '(' Expression ')' OptNullTreatment WindowingClause
	{
		$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$3}, IgnoreNull: $5.(bool), Spec: $6.(ast.WindowSpec)}
	}
|	"NTH_VALUE" '(' Expression ',' SimpleExpr ')' OptFromFirstLast OptNullTreatment WindowingClause
	{
		$$ = &ast.WindowFuncExpr{F: $1, Args: []ast.ExprNode{$3, $5}, FromLast: $7.(bool), IgnoreNull: $8.(bool), Spec: $9.(ast.WindowSpec)}
	}

OptLeadLagInfo:
	{
		$$ = nil
	}
|	',' NumLiteral OptLLDefault
	{
		args := []ast.ExprNode{ast.NewValueExpr($2, parser.charset, parser.collation)}
		if $3 != nil {
			args = append(args, $3.(ast.ExprNode))
		}
		$$ = args
	}
|	',' paramMarker OptLLDefault
	{
		args := []ast.ExprNode{ast.NewParamMarkerExpr(yyS[yypt-1].offset)}
		if $3 != nil {
			args = append(args, $3.(ast.ExprNode))
		}
		$$ = args
	}

OptLLDefault:
	{
		$$ = nil
	}
|	',' Expression
	{
		$$ = $2
	}

OptNullTreatment:
	{
		$$ = false
	}
|	"RESPECT" "NULLS"
	{
		$$ = false
	}
|	"IGNORE" "NULLS"
	{
		$$ = true
	}

OptFromFirstLast:
	{
		$$ = false
	}
|	"FROM" "FIRST"
	{
		$$ = false
	}
|	"FROM" "LAST"
	{
		$$ = true
	}

TableRefsClause:
	TableRefs
	{
		$$ = &ast.TableRefsClause{TableRefs: $1.(*ast.Join)}
	}

TableRefs:
	EscapedTableRef
	{
		if j, ok := $1.(*ast.Join); ok {
			// if $1 is Join, use it directly
			$$ = j
		} else {
			$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: nil}
		}
	}
|	TableRefs ',' EscapedTableRef
	{
		/* from a, b is default cross join */
		$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: $3.(ast.ResultSetNode), Tp: ast.CrossJoin}
	}

EscapedTableRef:
	TableRef %prec lowerThanSetKeyword
|	'{' Identifier TableRef '}'
	{
		/*
		 * ODBC escape syntax for outer join is { OJ join_table }
		 * Use an Identifier for OJ
		 */
		$$ = $3
	}

TableRef:
	TableFactor
|	JoinTable

TableFactor:
	TableName PartitionNameListOpt TableAsNameOpt AsOfClauseOpt IndexHintListOpt TableSampleOpt
	{
		tn := $1.(*ast.TableName)
		tn.PartitionNames = $2.([]model.CIStr)
		tn.IndexHints = $5.([]*ast.IndexHint)
		if $6 != nil {
			tn.TableSample = $6.(*ast.TableSample)
		}
		if $4 != nil {
			tn.AsOf = $4.(*ast.AsOfClause)
		}
		$$ = &ast.TableSource{Source: tn, AsName: $3.(model.CIStr)}
	}
|	SubSelect TableAsNameOpt
	{
		resultNode := $1.(*ast.SubqueryExpr).Query
		$$ = &ast.TableSource{Source: resultNode, AsName: $2.(model.CIStr)}
	}
|	'(' TableRefs ')'
	{
		j := $2.(*ast.Join)
		j.ExplicitParens = true
		$$ = $2
	}

PartitionNameListOpt:
	/* empty */
	{
		$$ = []model.CIStr{}
	}
|	"PARTITION" '(' PartitionNameList ')'
	{
		$$ = $3
	}

TableAsNameOpt:
	%prec empty
	{
		$$ = model.CIStr{}
	}
|	TableAsName

TableAsName:
	Identifier
	{
		$$ = model.NewCIStr($1)
	}
|	"AS" Identifier
	{
		$$ = model.NewCIStr($2)
	}

IndexHintType:
	"USE" KeyOrIndex
	{
		$$ = ast.HintUse
	}
|	"IGNORE" KeyOrIndex
	{
		$$ = ast.HintIgnore
	}
|	"FORCE" KeyOrIndex
	{
		$$ = ast.HintForce
	}

IndexHintScope:
	{
		$$ = ast.HintForScan
	}
|	"FOR" "JOIN"
	{
		$$ = ast.HintForJoin
	}
|	"FOR" "ORDER" "BY"
	{
		$$ = ast.HintForOrderBy
	}
|	"FOR" "GROUP" "BY"
	{
		$$ = ast.HintForGroupBy
	}

IndexHint:
	IndexHintType IndexHintScope '(' IndexNameList ')'
	{
		$$ = &ast.IndexHint{
			IndexNames: $4.([]model.CIStr),
			HintType:   $1.(ast.IndexHintType),
			HintScope:  $2.(ast.IndexHintScope),
		}
	}

IndexNameList:
	{
		var nameList []model.CIStr
		$$ = nameList
	}
|	Identifier
	{
		$$ = []model.CIStr{model.NewCIStr($1)}
	}
|	IndexNameList ',' Identifier
	{
		$$ = append($1.([]model.CIStr), model.NewCIStr($3))
	}
|	"PRIMARY"
	{
		$$ = []model.CIStr{model.NewCIStr($1)}
	}
|	IndexNameList ',' "PRIMARY"
	{
		$$ = append($1.([]model.CIStr), model.NewCIStr($3))
	}

IndexHintList:
	IndexHint
	{
		$$ = []*ast.IndexHint{$1.(*ast.IndexHint)}
	}
|	IndexHintList IndexHint
	{
		$$ = append($1.([]*ast.IndexHint), $2.(*ast.IndexHint))
	}

IndexHintListOpt:
	{
		$$ = []*ast.IndexHint{}
	}
|	IndexHintList

JoinTable:
	/* Use %prec to evaluate production TableRef before cross join */
	TableRef CrossOpt TableRef %prec tableRefPriority
	{
		$$ = ast.NewCrossJoin($1.(ast.ResultSetNode), $3.(ast.ResultSetNode))
	}
|	TableRef CrossOpt TableRef "ON" Expression
	{
		on := &ast.OnCondition{Expr: $5}
		$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: $3.(ast.ResultSetNode), Tp: ast.CrossJoin, On: on}
	}
|	TableRef CrossOpt TableRef "USING" '(' ColumnNameList ')'
	{
		$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: $3.(ast.ResultSetNode), Tp: ast.CrossJoin, Using: $6.([]*ast.ColumnName)}
	}
|	TableRef JoinType OuterOpt "JOIN" TableRef "ON" Expression
	{
		on := &ast.OnCondition{Expr: $7}
		$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: $5.(ast.ResultSetNode), Tp: $2.(ast.JoinType), On: on}
	}
|	TableRef JoinType OuterOpt "JOIN" TableRef "USING" '(' ColumnNameList ')'
	{
		$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: $5.(ast.ResultSetNode), Tp: $2.(ast.JoinType), Using: $8.([]*ast.ColumnName)}
	}
|	TableRef "NATURAL" "JOIN" TableRef
	{
		$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: $4.(ast.ResultSetNode), NaturalJoin: true}
	}
|	TableRef "NATURAL" JoinType OuterOpt "JOIN" TableRef
	{
		$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: $6.(ast.ResultSetNode), Tp: $3.(ast.JoinType), NaturalJoin: true}
	}
|	TableRef "STRAIGHT_JOIN" TableRef
	{
		$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: $3.(ast.ResultSetNode), StraightJoin: true}
	}
|	TableRef "STRAIGHT_JOIN" TableRef "ON" Expression
	{
		on := &ast.OnCondition{Expr: $5}
		$$ = &ast.Join{Left: $1.(ast.ResultSetNode), Right: $3.(ast.ResultSetNode), StraightJoin: true, On: on}
	}

JoinType:
	"LEFT"
	{
		$$ = ast.LeftJoin
	}
|	"RIGHT"
	{
		$$ = ast.RightJoin
	}

OuterOpt:
	{}
|	"OUTER"

CrossOpt:
	"JOIN"
|	"CROSS" "JOIN"
|	"INNER" "JOIN"

LimitClause:
	{
		$$ = nil
	}
|	"LIMIT" LimitOption
	{
		$$ = &ast.Limit{Count: $2.(ast.ValueExpr)}
	}

LimitOption:
	LengthNum
	{
		$$ = ast.NewValueExpr($1, parser.charset, parser.collation)
	}
|	paramMarker
	{
		$$ = ast.NewParamMarkerExpr(yyS[yypt].offset)
	}

RowOrRows:
	"ROW"
|	"ROWS"

FirstOrNext:
	"FIRST"
|	"NEXT"

FetchFirstOpt:
	{
		$$ = ast.NewValueExpr(uint64(1), parser.charset, parser.collation)
	}
|	LimitOption

SelectStmtLimit:
	"LIMIT" LimitOption
	{
		$$ = &ast.Limit{Count: $2.(ast.ExprNode)}
	}
|	"LIMIT" LimitOption ',' LimitOption
	{
		$$ = &ast.Limit{Offset: $2.(ast.ExprNode), Count: $4.(ast.ExprNode)}
	}
|	"LIMIT" LimitOption "OFFSET" LimitOption
	{
		$$ = &ast.Limit{Offset: $4.(ast.ExprNode), Count: $2.(ast.ExprNode)}
	}
|	"FETCH" FirstOrNext FetchFirstOpt RowOrRows "ONLY"
	{
		$$ = &ast.Limit{Count: $3.(ast.ExprNode)}
	}

SelectStmtLimitOpt:
	{
		$$ = nil
	}
|	SelectStmtLimit

SelectStmtOpt:
	TableOptimizerHints
	{
		opt := &ast.SelectStmtOpts{}
		opt.SQLCache = true
		opt.TableHints = $1.([]*ast.TableOptimizerHint)
		$$ = opt
	}
|	DistinctOpt
	{
		opt := &ast.SelectStmtOpts{}
		opt.SQLCache = true
		if $1.(bool) {
			opt.Distinct = true
		} else {
			opt.Distinct = false
			opt.ExplicitAll = true
		}
		$$ = opt
	}
|	Priority
	{
		opt := &ast.SelectStmtOpts{}
		opt.SQLCache = true
		opt.Priority = $1.(mysql.PriorityEnum)
		$$ = opt
	}
|	"SQL_SMALL_RESULT"
	{
		opt := &ast.SelectStmtOpts{}
		opt.SQLCache = true
		opt.SQLSmallResult = true
		$$ = opt
	}
|	"SQL_BIG_RESULT"
	{
		opt := &ast.SelectStmtOpts{}
		opt.SQLCache = true
		opt.SQLBigResult = true
		$$ = opt
	}
|	"SQL_BUFFER_RESULT"
	{
		opt := &ast.SelectStmtOpts{}
		opt.SQLCache = true
		opt.SQLBufferResult = true
		$$ = opt
	}
|	SelectStmtSQLCache
	{
		opt := &ast.SelectStmtOpts{}
		opt.SQLCache = $1.(bool)
		$$ = opt
	}
|	"SQL_CALC_FOUND_ROWS"
	{
		opt := &ast.SelectStmtOpts{}
		opt.SQLCache = true
		opt.CalcFoundRows = true
		$$ = opt
	}
|	"STRAIGHT_JOIN"
	{
		opt := &ast.SelectStmtOpts{}
		opt.SQLCache = true
		opt.StraightJoin = true
		$$ = opt
	}

SelectStmtOpts:
	%prec empty
	{
		opt := &ast.SelectStmtOpts{}
		opt.SQLCache = true
		$$ = opt
	}
|	SelectStmtOptsList %prec lowerThanSelectOpt

SelectStmtOptsList:
	SelectStmtOptsList SelectStmtOpt
	{
		opts := $1.(*ast.SelectStmtOpts)
		opt := $2.(*ast.SelectStmtOpts)

		// Merge options.
		// Always use the first hint.
		if opt.TableHints != nil && opts.TableHints == nil {
			opts.TableHints = opt.TableHints
		}
		if opt.Distinct {
			opts.Distinct = true
		}
		if opt.Priority != mysql.NoPriority {
			opts.Priority = opt.Priority
		}
		if opt.SQLSmallResult {
			opts.SQLSmallResult = true
		}
		if opt.SQLBigResult {
			opts.SQLBigResult = true
		}
		if opt.SQLBufferResult {
			opts.SQLBufferResult = true
		}
		if !opt.SQLCache {
			opts.SQLCache = false
		}
		if opt.CalcFoundRows {
			opts.CalcFoundRows = true
		}
		if opt.StraightJoin {
			opts.StraightJoin = true
		}
		if opt.ExplicitAll {
			opts.ExplicitAll = true
		}

		if opts.Distinct && opts.ExplicitAll {
			yylex.AppendError(ErrWrongUsage.GenWithStackByArgs("ALL", "DISTINCT"))
			return 1
		}

		$$ = opts
	}
|	SelectStmtOpt

TableOptimizerHints:
	hintComment
	{
		hints, warns := parser.parseHint($1)
		for _, w := range warns {
			yylex.AppendError(w)
			parser.lastErrorAsWarn()
		}
		$$ = hints
	}

TableOptimizerHintsOpt:
	/* empty */
	{
		$$ = nil
	}
|	TableOptimizerHints

SelectStmtSQLCache:
	"SQL_CACHE"
	{
		$$ = true
	}
|	"SQL_NO_CACHE"
	{
		$$ = false
	}

SelectStmtFieldList:
	FieldList
	{
		$$ = &ast.FieldList{Fields: $1.([]*ast.SelectField)}
	}

SelectStmtGroup:
	/* EMPTY */
	{
		$$ = nil
	}
|	GroupByClause

SelectStmtIntoOption:
	{
		$$ = nil
	}
|	"INTO" "OUTFILE" stringLit Fields Lines
	{
		x := &ast.SelectIntoOption{
			Tp:       ast.SelectIntoOutfile,
			FileName: $3,
		}
		if $4 != nil {
			x.FieldsInfo = $4.(*ast.FieldsClause)
		}
		if $5 != nil {
			x.LinesInfo = $5.(*ast.LinesClause)
		}

		$$ = x
	}

// See https://dev.mysql.com/doc/refman/5.7/en/subqueries.html
SubSelect:
	'(' SelectStmt ')'
	{
		rs := $2.(*ast.SelectStmt)
		endOffset := parser.endOffset(&yyS[yypt])
		parser.setLastSelectFieldText(rs, endOffset)
		src := parser.src
		// See the implementation of yyParse function
		rs.SetText(parser.lexer.client, src[yyS[yypt-1].offset:yyS[yypt].offset])
		$$ = &ast.SubqueryExpr{Query: rs}
	}
|	'(' SetOprStmt ')'
	{
		rs := $2.(*ast.SetOprStmt)
		src := parser.src
		rs.SetText(parser.lexer.client, src[yyS[yypt-1].offset:yyS[yypt].offset])
		$$ = &ast.SubqueryExpr{Query: rs}
	}
|	'(' SelectStmtWithClause ')'
	{
		rs := $2.(*ast.SelectStmt)
		endOffset := parser.endOffset(&yyS[yypt])
		parser.setLastSelectFieldText(rs, endOffset)
		src := parser.src
		// See the implementation of yyParse function
		rs.SetText(parser.lexer.client, src[yyS[yypt-1].offset:yyS[yypt].offset])
		$$ = &ast.SubqueryExpr{Query: rs}
	}
|	'(' SubSelect ')'
	{
		subQuery := $2.(*ast.SubqueryExpr).Query
		isRecursive := true
		// remove redundant brackets like '((select 1))'
		for isRecursive {
			if _, isRecursive = subQuery.(*ast.SubqueryExpr); isRecursive {
				subQuery = subQuery.(*ast.SubqueryExpr).Query
			}
		}
		switch rs := subQuery.(type) {
		case *ast.SelectStmt:
			endOffset := parser.endOffset(&yyS[yypt])
			parser.setLastSelectFieldText(rs, endOffset)
			src := parser.src
			rs.SetText(parser.lexer.client, src[yyS[yypt-1].offset:yyS[yypt].offset])
			$$ = &ast.SubqueryExpr{Query: rs}
		case *ast.SetOprStmt:
			src := parser.src
			rs.SetText(parser.lexer.client, src[yyS[yypt-1].offset:yyS[yypt].offset])
			$$ = &ast.SubqueryExpr{Query: rs}
		}
	}

// See https://dev.mysql.com/doc/refman/8.0/en/innodb-locking-reads.html
SelectLockOpt:
	/* empty */
	{
		$$ = nil
	}
|	"FOR" "UPDATE" OfTablesOpt
	{
		$$ = &ast.SelectLockInfo{
			LockType: ast.SelectLockForUpdate,
			Tables:   $3.([]*ast.TableName),
		}
	}
|	"FOR" "SHARE" OfTablesOpt
	{
		$$ = &ast.SelectLockInfo{
			LockType: ast.SelectLockForShare,
			Tables:   $3.([]*ast.TableName),
		}
	}
|	"FOR" "UPDATE" OfTablesOpt "NOWAIT"
	{
		$$ = &ast.SelectLockInfo{
			LockType: ast.SelectLockForUpdateNoWait,
			Tables:   $3.([]*ast.TableName),
		}
	}
|	"FOR" "UPDATE" OfTablesOpt "WAIT" NUM
	{
		$$ = &ast.SelectLockInfo{
			LockType: ast.SelectLockForUpdateWaitN,
			WaitSec:  getUint64FromNUM($5),
			Tables:   $3.([]*ast.TableName),
		}
	}
|	"FOR" "SHARE" OfTablesOpt "NOWAIT"
	{
		$$ = &ast.SelectLockInfo{
			LockType: ast.SelectLockForShareNoWait,
			Tables:   $3.([]*ast.TableName),
		}
	}
|	"FOR" "UPDATE" OfTablesOpt "SKIP" "LOCKED"
	{
		$$ = &ast.SelectLockInfo{
			LockType: ast.SelectLockForUpdateSkipLocked,
			Tables:   $3.([]*ast.TableName),
		}
	}
|	"FOR" "SHARE" OfTablesOpt "SKIP" "LOCKED"
	{
		$$ = &ast.SelectLockInfo{
			LockType: ast.SelectLockForShareSkipLocked,
			Tables:   $3.([]*ast.TableName),
		}
	}
|	"LOCK" "IN" "SHARE" "MODE"
	{
		$$ = &ast.SelectLockInfo{
			LockType: ast.SelectLockForShare,
			Tables:   []*ast.TableName{},
		}
	}

OfTablesOpt:
	/* empty */
	{
		$$ = []*ast.TableName{}
	}
|	"OF" TableNameList
	{
		$$ = $2.([]*ast.TableName)
	}

SetOprStmt:
	SetOprStmtWoutLimitOrderBy
|	SetOprStmtWithLimitOrderBy
|	WithClause SetOprStmtWithLimitOrderBy
	{
		setOpr := $2.(*ast.SetOprStmt)
		setOpr.With = $1.(*ast.WithClause)
		$$ = setOpr
	}
|	WithClause SetOprStmtWoutLimitOrderBy
	{
		setOpr := $2.(*ast.SetOprStmt)
		setOpr.With = $1.(*ast.WithClause)
		$$ = setOpr
	}

// See https://dev.mysql.com/doc/refman/5.7/en/union.html
// See https://mariadb.com/kb/en/intersect/
// See https://mariadb.com/kb/en/except/
SetOprStmtWoutLimitOrderBy:
	SetOprClauseList SetOpr SelectStmt
	{
		setOprList1 := $1.([]ast.Node)
		if sel, isSelect := setOprList1[len(setOprList1)-1].(*ast.SelectStmt); isSelect && !sel.IsInBraces {
			endOffset := parser.endOffset(&yyS[yypt-1])
			parser.setLastSelectFieldText(sel, endOffset)
		}
		setOpr := &ast.SetOprStmt{SelectList: &ast.SetOprSelectList{Selects: $1.([]ast.Node)}}
		st := $3.(*ast.SelectStmt)
		setOpr.Limit = st.Limit
		setOpr.OrderBy = st.OrderBy
		st.Limit = nil
		st.OrderBy = nil
		st.AfterSetOperator = $2.(*ast.SetOprType)
		setOpr.SelectList.Selects = append(setOpr.SelectList.Selects, st)
		$$ = setOpr
	}
|	SetOprClauseList SetOpr SubSelect
	{
		setOprList1 := $1.([]ast.Node)
		if sel, isSelect := setOprList1[len(setOprList1)-1].(*ast.SelectStmt); isSelect && !sel.IsInBraces {
			endOffset := parser.endOffset(&yyS[yypt-1])
			parser.setLastSelectFieldText(sel, endOffset)
		}
		var setOprList2 []ast.Node
		var with2 *ast.WithClause
		switch x := $3.(*ast.SubqueryExpr).Query.(type) {
		case *ast.SelectStmt:
			setOprList2 = []ast.Node{x}
			with2 = x.With
		case *ast.SetOprStmt:
			setOprList2 = x.SelectList.Selects
			with2 = x.With
		}
		nextSetOprList := &ast.SetOprSelectList{Selects: setOprList2, With: with2}
		nextSetOprList.AfterSetOperator = $2.(*ast.SetOprType)
		setOprList := append(setOprList1, nextSetOprList)
		setOpr := &ast.SetOprStmt{SelectList: &ast.SetOprSelectList{Selects: setOprList}}
		$$ = setOpr
	}

SetOprStmtWithLimitOrderBy:
	SetOprClauseList SetOpr SubSelect OrderBy
	{
		setOprList1 := $1.([]ast.Node)
		if sel, isSelect := setOprList1[len(setOprList1)-1].(*ast.SelectStmt); isSelect && !sel.IsInBraces {
			endOffset := parser.endOffset(&yyS[yypt-2])
			parser.setLastSelectFieldText(sel, endOffset)
		}
		var setOprList2 []ast.Node
		var with2 *ast.WithClause
		switch x := $3.(*ast.SubqueryExpr).Query.(type) {
		case *ast.SelectStmt:
			setOprList2 = []ast.Node{x}
			with2 = x.With
		case *ast.SetOprStmt:
			setOprList2 = x.SelectList.Selects
			with2 = x.With
		}
		nextSetOprList := &ast.SetOprSelectList{Selects: setOprList2, With: with2}
		nextSetOprList.AfterSetOperator = $2.(*ast.SetOprType)
		setOprList := append(setOprList1, nextSetOprList)
		setOpr := &ast.SetOprStmt{SelectList: &ast.SetOprSelectList{Selects: setOprList}}
		setOpr.OrderBy = $4.(*ast.OrderByClause)
		$$ = setOpr
	}
|	SetOprClauseList SetOpr SubSelect SelectStmtLimit
	{
		setOprList1 := $1.([]ast.Node)
		if sel, isSelect := setOprList1[len(setOprList1)-1].(*ast.SelectStmt); isSelect && !sel.IsInBraces {
			endOffset := parser.endOffset(&yyS[yypt-2])
			parser.setLastSelectFieldText(sel, endOffset)
		}
		var setOprList2 []ast.Node
		var with2 *ast.WithClause
		switch x := $3.(*ast.SubqueryExpr).Query.(type) {
		case *ast.SelectStmt:
			setOprList2 = []ast.Node{x}
			with2 = x.With
		case *ast.SetOprStmt:
			setOprList2 = x.SelectList.Selects
			with2 = x.With
		}
		nextSetOprList := &ast.SetOprSelectList{Selects: setOprList2, With: with2}
		nextSetOprList.AfterSetOperator = $2.(*ast.SetOprType)
		setOprList := append(setOprList1, nextSetOprList)
		setOpr := &ast.SetOprStmt{SelectList: &ast.SetOprSelectList{Selects: setOprList}}
		setOpr.Limit = $4.(*ast.Limit)
		$$ = setOpr
	}
|	SetOprClauseList SetOpr SubSelect OrderBy SelectStmtLimit
	{
		setOprList1 := $1.([]ast.Node)
		if sel, isSelect := setOprList1[len(setOprList1)-1].(*ast.SelectStmt); isSelect && !sel.IsInBraces {
			endOffset := parser.endOffset(&yyS[yypt-3])
			parser.setLastSelectFieldText(sel, endOffset)
		}
		var setOprList2 []ast.Node
		var with2 *ast.WithClause
		switch x := $3.(*ast.SubqueryExpr).Query.(type) {
		case *ast.SelectStmt:
			setOprList2 = []ast.Node{x}
			with2 = x.With
		case *ast.SetOprStmt:
			setOprList2 = x.SelectList.Selects
			with2 = x.With
		}
		nextSetOprList := &ast.SetOprSelectList{Selects: setOprList2, With: with2}
		nextSetOprList.AfterSetOperator = $2.(*ast.SetOprType)
		setOprList := append(setOprList1, nextSetOprList)
		setOpr := &ast.SetOprStmt{SelectList: &ast.SetOprSelectList{Selects: setOprList}}
		setOpr.OrderBy = $4.(*ast.OrderByClause)
		setOpr.Limit = $5.(*ast.Limit)
		$$ = setOpr
	}
|	SubSelect OrderBy
	{
		var setOprList []ast.Node
		var with *ast.WithClause
		switch x := $1.(*ast.SubqueryExpr).Query.(type) {
		case *ast.SelectStmt:
			setOprList = []ast.Node{x}
			with = x.With
		case *ast.SetOprStmt:
			setOprList = x.SelectList.Selects
			with = x.With
		}
		setOpr := &ast.SetOprStmt{SelectList: &ast.SetOprSelectList{Selects: setOprList}, With: with}
		setOpr.OrderBy = $2.(*ast.OrderByClause)
		$$ = setOpr
	}
|	SubSelect SelectStmtLimit
	{
		var setOprList []ast.Node
		var with *ast.WithClause
		switch x := $1.(*ast.SubqueryExpr).Query.(type) {
		case *ast.SelectStmt:
			setOprList = []ast.Node{x}
			with = x.With
		case *ast.SetOprStmt:
			setOprList = x.SelectList.Selects
			with = x.With
		}
		setOpr := &ast.SetOprStmt{SelectList: &ast.SetOprSelectList{Selects: setOprList}, With: with}
		setOpr.Limit = $2.(*ast.Limit)
		$$ = setOpr
	}
|	SubSelect OrderBy SelectStmtLimit
	{
		var setOprList []ast.Node
		var with *ast.WithClause
		switch x := $1.(*ast.SubqueryExpr).Query.(type) {
		case *ast.SelectStmt:
			setOprList = []ast.Node{x}
			with = x.With
		case *ast.SetOprStmt:
			setOprList = x.SelectList.Selects
			with = x.With
		}
		setOpr := &ast.SetOprStmt{SelectList: &ast.SetOprSelectList{Selects: setOprList}, With: with}
		setOpr.OrderBy = $2.(*ast.OrderByClause)
		setOpr.Limit = $3.(*ast.Limit)
		$$ = setOpr
	}

SetOprClauseList:
	SetOprClause
|	SetOprClauseList SetOpr SetOprClause
	{
		setOprList1 := $1.([]ast.Node)
		setOprList2 := $3.([]ast.Node)
		if sel, isSelect := setOprList1[len(setOprList1)-1].(*ast.SelectStmt); isSelect && !sel.IsInBraces {
			endOffset := parser.endOffset(&yyS[yypt-1])
			parser.setLastSelectFieldText(sel, endOffset)
		}
		switch x := setOprList2[0].(type) {
		case *ast.SelectStmt:
			x.AfterSetOperator = $2.(*ast.SetOprType)
		case *ast.SetOprSelectList:
			x.AfterSetOperator = $2.(*ast.SetOprType)
		}
		$$ = append(setOprList1, setOprList2...)
	}

SetOprClause:
	SelectStmt
	{
		$$ = []ast.Node{$1.(*ast.SelectStmt)}
	}
|	SubSelect
	{
		var setOprList []ast.Node
		switch x := $1.(*ast.SubqueryExpr).Query.(type) {
		case *ast.SelectStmt:
			setOprList = []ast.Node{&ast.SetOprSelectList{Selects: []ast.Node{x}}}
		case *ast.SetOprStmt:
			setOprList = []ast.Node{&ast.SetOprSelectList{Selects: x.SelectList.Selects, With: x.With}}
		}
		$$ = setOprList
	}

SetOpr:
	"UNION" SetOprOpt
	{
		var tp ast.SetOprType
		tp = ast.Union
		if $2 == false {
			tp = ast.UnionAll
		}
		$$ = &tp
	}
|	"EXCEPT" SetOprOpt
	{
		var tp ast.SetOprType
		tp = ast.Except
		if $2 == false {
			tp = ast.ExceptAll
		}
		$$ = &tp
	}
|	"INTERSECT" SetOprOpt
	{
		var tp ast.SetOprType
		tp = ast.Intersect
		if $2 == false {
			tp = ast.IntersectAll
		}
		$$ = &tp
	}

SetOprOpt:
	DefaultTrueDistinctOpt

/********************Change Statement*******************************/
ChangeStmt:
	"CHANGE" "PUMP" "TO" "NODE_STATE" eq stringLit forKwd "NODE_ID" stringLit
	{
		$$ = &ast.ChangeStmt{
			NodeType: ast.PumpType,
			State:    $6,
			NodeID:   $9,
		}
	}
|	"CHANGE" "DRAINER" "TO" "NODE_STATE" eq stringLit forKwd "NODE_ID" stringLit
	{
		$$ = &ast.ChangeStmt{
			NodeType: ast.DrainerType,
			State:    $6,
			NodeID:   $9,
		}
	}

/********************Set Statement*******************************/
SetStmt:
	"SET" VariableAssignmentList
	{
		$$ = &ast.SetStmt{Variables: $2.([]*ast.VariableAssignment)}
	}
|	"SET" "PASSWORD" eq PasswordOpt
	{
		$$ = &ast.SetPwdStmt{Password: $4}
	}
|	"SET" "PASSWORD" "FOR" Username eq PasswordOpt
	{
		$$ = &ast.SetPwdStmt{User: $4.(*auth.UserIdentity), Password: $6}
	}
|	"SET" "GLOBAL" "TRANSACTION" TransactionChars
	{
		vars := $4.([]*ast.VariableAssignment)
		for _, v := range vars {
			v.IsGlobal = true
		}
		$$ = &ast.SetStmt{Variables: vars}
	}
|	"SET" "SESSION" "TRANSACTION" TransactionChars
	{
		$$ = &ast.SetStmt{Variables: $4.([]*ast.VariableAssignment)}
	}
|	"SET" "TRANSACTION" TransactionChars
	{
		assigns := $3.([]*ast.VariableAssignment)
		for i := 0; i < len(assigns); i++ {
			if assigns[i].Name == "tx_isolation" {
				// A special session variable that make setting tx_isolation take effect one time.
				assigns[i].Name = "tx_isolation_one_shot"
			}
		}
		$$ = &ast.SetStmt{Variables: assigns}
	}
|	"SET" "CONFIG" Identifier ConfigItemName EqOrAssignmentEq SetExpr
	{
		$$ = &ast.SetConfigStmt{Type: strings.ToLower($3), Name: $4, Value: $6}
	}
|	"SET" "CONFIG" stringLit ConfigItemName EqOrAssignmentEq SetExpr
	{
		$$ = &ast.SetConfigStmt{Instance: $3, Name: $4, Value: $6}
	}

SetRoleStmt:
	"SET" "ROLE" SetRoleOpt
	{
		$$ = $3.(*ast.SetRoleStmt)
	}

SetDefaultRoleStmt:
	"SET" "DEFAULT" "ROLE" SetDefaultRoleOpt "TO" UsernameList
	{
		tmp := $4.(*ast.SetRoleStmt)
		$$ = &ast.SetDefaultRoleStmt{
			SetRoleOpt: tmp.SetRoleOpt,
			RoleList:   tmp.RoleList,
			UserList:   $6.([]*auth.UserIdentity),
		}
	}

SetDefaultRoleOpt:
	"NONE"
	{
		$$ = &ast.SetRoleStmt{SetRoleOpt: ast.SetRoleNone, RoleList: nil}
	}
|	"ALL"
	{
		$$ = &ast.SetRoleStmt{SetRoleOpt: ast.SetRoleAll, RoleList: nil}
	}
|	RolenameList
	{
		$$ = &ast.SetRoleStmt{SetRoleOpt: ast.SetRoleRegular, RoleList: $1.([]*auth.RoleIdentity)}
	}

SetRoleOpt:
	"ALL" "EXCEPT" RolenameList
	{
		$$ = &ast.SetRoleStmt{SetRoleOpt: ast.SetRoleAllExcept, RoleList: $3.([]*auth.RoleIdentity)}
	}
|	SetDefaultRoleOpt
|	"DEFAULT"
	{
		$$ = &ast.SetRoleStmt{SetRoleOpt: ast.SetRoleDefault, RoleList: nil}
	}

TransactionChars:
	TransactionChar
	{
		if $1 != nil {
			$$ = $1
		} else {
			$$ = []*ast.VariableAssignment{}
		}
	}
|	TransactionChars ',' TransactionChar
	{
		if $3 != nil {
			varAssigns := $3.([]*ast.VariableAssignment)
			$$ = append($1.([]*ast.VariableAssignment), varAssigns...)
		} else {
			$$ = $1
		}
	}

TransactionChar:
	"ISOLATION" "LEVEL" IsolationLevel
	{
		varAssigns := []*ast.VariableAssignment{}
		expr := ast.NewValueExpr($3, parser.charset, parser.collation)
		varAssigns = append(varAssigns, &ast.VariableAssignment{Name: "tx_isolation", Value: expr, IsSystem: true})
		$$ = varAssigns
	}
|	"READ" "WRITE"
	{
		varAssigns := []*ast.VariableAssignment{}
		expr := ast.NewValueExpr("0", parser.charset, parser.collation)
		varAssigns = append(varAssigns, &ast.VariableAssignment{Name: "tx_read_only", Value: expr, IsSystem: true})
		$$ = varAssigns
	}
|	"READ" "ONLY"
	{
		varAssigns := []*ast.VariableAssignment{}
		expr := ast.NewValueExpr("1", parser.charset, parser.collation)
		varAssigns = append(varAssigns, &ast.VariableAssignment{Name: "tx_read_only", Value: expr, IsSystem: true})
		$$ = varAssigns
	}
|	"READ" "ONLY" AsOfClause
	{
		varAssigns := []*ast.VariableAssignment{}
		asof := $3.(*ast.AsOfClause)
		if asof != nil {
			varAssigns = append(varAssigns, &ast.VariableAssignment{Name: "tx_read_ts", Value: asof.TsExpr, IsSystem: true})
		}
		$$ = varAssigns
	}

IsolationLevel:
	"REPEATABLE" "READ"
	{
		$$ = ast.RepeatableRead
	}
|	"READ" "COMMITTED"
	{
		$$ = ast.ReadCommitted
	}
|	"READ" "UNCOMMITTED"
	{
		$$ = ast.ReadUncommitted
	}
|	"SERIALIZABLE"
	{
		$$ = ast.Serializable
	}

SetExpr:
	"ON"
	{
		$$ = ast.NewValueExpr("ON", parser.charset, parser.collation)
	}
|	"BINARY"
	{
		$$ = ast.NewValueExpr("BINARY", parser.charset, parser.collation)
	}
|	ExprOrDefault

EqOrAssignmentEq:
	eq
|	assignmentEq

VariableName:
	Identifier
|	Identifier '.' Identifier
	{
		$$ = $1 + "." + $3
	}

ConfigItemName:
	Identifier
|	Identifier '.' ConfigItemName
	{
		$$ = $1 + "." + $3
	}
|	Identifier '-' ConfigItemName
	{
		$$ = $1 + "-" + $3
	}

VariableAssignment:
	VariableName EqOrAssignmentEq SetExpr
	{
		$$ = &ast.VariableAssignment{Name: $1, Value: $3, IsSystem: true}
	}
|	"GLOBAL" VariableName EqOrAssignmentEq SetExpr
	{
		$$ = &ast.VariableAssignment{Name: $2, Value: $4, IsGlobal: true, IsSystem: true}
	}
|	"SESSION" VariableName EqOrAssignmentEq SetExpr
	{
		$$ = &ast.VariableAssignment{Name: $2, Value: $4, IsSystem: true}
	}
|	"LOCAL" VariableName EqOrAssignmentEq SetExpr
	{
		$$ = &ast.VariableAssignment{Name: $2, Value: $4, IsSystem: true}
	}
|	doubleAtIdentifier EqOrAssignmentEq SetExpr
	{
		v := strings.ToLower($1)
		var isGlobal bool
		if strings.HasPrefix(v, "@@global.") {
			isGlobal = true
			v = strings.TrimPrefix(v, "@@global.")
		} else if strings.HasPrefix(v, "@@session.") {
			v = strings.TrimPrefix(v, "@@session.")
		} else if strings.HasPrefix(v, "@@local.") {
			v = strings.TrimPrefix(v, "@@local.")
		} else if strings.HasPrefix(v, "@@") {
			v = strings.TrimPrefix(v, "@@")
		}
		$$ = &ast.VariableAssignment{Name: v, Value: $3, IsGlobal: isGlobal, IsSystem: true}
	}
|	singleAtIdentifier EqOrAssignmentEq Expression
	{
		v := $1
		v = strings.TrimPrefix(v, "@")
		$$ = &ast.VariableAssignment{Name: v, Value: $3}
	}
|	"NAMES" CharsetName
	{
		$$ = &ast.VariableAssignment{
			Name:  ast.SetNames,
			Value: ast.NewValueExpr($2, "", ""),
		}
	}
|	"NAMES" CharsetName "COLLATE" "DEFAULT"
	{
		$$ = &ast.VariableAssignment{
			Name:  ast.SetNames,
			Value: ast.NewValueExpr($2, "", ""),
		}
	}
|	"NAMES" CharsetName "COLLATE" StringName
	{
		$$ = &ast.VariableAssignment{
			Name:        ast.SetNames,
			Value:       ast.NewValueExpr($2, "", ""),
			ExtendValue: ast.NewValueExpr($4, "", ""),
		}
	}
|	"NAMES" "DEFAULT"
	{
		v := &ast.DefaultExpr{}
		$$ = &ast.VariableAssignment{Name: ast.SetNames, Value: v}
	}
|	CharsetKw CharsetNameOrDefault
	{
		$$ = &ast.VariableAssignment{Name: ast.SetCharset, Value: $2}
	}

CharsetNameOrDefault:
	CharsetName
	{
		$$ = ast.NewValueExpr($1, "", "")
	}
|	"DEFAULT"
	{
		$$ = &ast.DefaultExpr{}
	}

CharsetName:
	StringName
	{
		// Validate input charset name to keep the same behavior as parser of MySQL.
		cs, err := charset.GetCharsetInfo($1)
		if err != nil {
			yylex.AppendError(ErrUnknownCharacterSet.GenWithStackByArgs($1))
			return 1
		}
		// Use charset name returned from charset.GetCharsetInfo(),
		// to keep lower case of input for generated column restore.
		$$ = cs.Name
	}
|	binaryType
	{
		$$ = charset.CharsetBin
	}

CollationName:
	StringName
	{
		info, err := charset.GetCollationByName($1)
		if err != nil {
			yylex.AppendError(err)
			return 1
		}
		$$ = info.Name
	}
|	binaryType
	{
		$$ = charset.CollationBin
	}

VariableAssignmentList:
	VariableAssignment
	{
		$$ = []*ast.VariableAssignment{$1.(*ast.VariableAssignment)}
	}
|	VariableAssignmentList ',' VariableAssignment
	{
		$$ = append($1.([]*ast.VariableAssignment), $3.(*ast.VariableAssignment))
	}

Variable:
	SystemVariable
|	UserVariable

SystemVariable:
	doubleAtIdentifier
	{
		v := strings.ToLower($1)
		var isGlobal bool
		explicitScope := true
		if strings.HasPrefix(v, "@@global.") {
			isGlobal = true
			v = strings.TrimPrefix(v, "@@global.")
		} else if strings.HasPrefix(v, "@@session.") {
			v = strings.TrimPrefix(v, "@@session.")
		} else if strings.HasPrefix(v, "@@local.") {
			v = strings.TrimPrefix(v, "@@local.")
		} else if strings.HasPrefix(v, "@@") {
			v, explicitScope = strings.TrimPrefix(v, "@@"), false
		}
		$$ = &ast.VariableExpr{Name: v, IsGlobal: isGlobal, IsSystem: true, ExplicitScope: explicitScope}
	}

UserVariable:
	singleAtIdentifier
	{
		v := $1
		v = strings.TrimPrefix(v, "@")
		$$ = &ast.VariableExpr{Name: v, IsGlobal: false, IsSystem: false}
	}

Username:
	StringName
	{
		$$ = &auth.UserIdentity{Username: $1, Hostname: "%"}
	}
|	StringName '@' StringName
	{
		$$ = &auth.UserIdentity{Username: $1, Hostname: $3}
	}
|	StringName singleAtIdentifier
	{
		$$ = &auth.UserIdentity{Username: $1, Hostname: strings.TrimPrefix($2, "@")}
	}
|	"CURRENT_USER" OptionalBraces
	{
		$$ = &auth.UserIdentity{CurrentUser: true}
	}

UsernameList:
	Username
	{
		$$ = []*auth.UserIdentity{$1.(*auth.UserIdentity)}
	}
|	UsernameList ',' Username
	{
		$$ = append($1.([]*auth.UserIdentity), $3.(*auth.UserIdentity))
	}

PasswordOpt:
	stringLit
|	"PASSWORD" '(' AuthString ')'
	{
		$$ = $3
	}

AuthString:
	stringLit

RoleNameString:
	stringLit
|	identifier

RolenameComposed:
	StringName '@' StringName
	{
		$$ = &auth.RoleIdentity{Username: $1, Hostname: $3}
	}
|	StringName singleAtIdentifier
	{
		$$ = &auth.RoleIdentity{Username: $1, Hostname: strings.TrimPrefix($2, "@")}
	}

RolenameWithoutIdent:
	stringLit
	{
		$$ = &auth.RoleIdentity{Username: $1, Hostname: "%"}
	}
|	RolenameComposed
	{
		$$ = $1
	}

Rolename:
	RoleNameString
	{
		$$ = &auth.RoleIdentity{Username: $1, Hostname: "%"}
	}
|	RolenameComposed
	{
		$$ = $1
	}

RolenameList:
	Rolename
	{
		$$ = []*auth.RoleIdentity{$1.(*auth.RoleIdentity)}
	}
|	RolenameList ',' Rolename
	{
		$$ = append($1.([]*auth.RoleIdentity), $3.(*auth.RoleIdentity))
	}

/****************************Admin Statement*******************************/
AdminStmt:
	"ADMIN" "SHOW" "DDL"
	{
		$$ = &ast.AdminStmt{Tp: ast.AdminShowDDL}
	}
|	"ADMIN" "SHOW" "DDL" "JOBS" WhereClauseOptional
	{
		stmt := &ast.AdminStmt{Tp: ast.AdminShowDDLJobs}
		if $5 != nil {
			stmt.Where = $5.(ast.ExprNode)
		}
		$$ = stmt
	}
|	"ADMIN" "SHOW" "DDL" "JOBS" Int64Num WhereClauseOptional
	{
		stmt := &ast.AdminStmt{
			Tp:        ast.AdminShowDDLJobs,
			JobNumber: $5.(int64),
		}
		if $6 != nil {
			stmt.Where = $6.(ast.ExprNode)
		}
		$$ = stmt
	}
|	"ADMIN" "SHOW" TableName "NEXT_ROW_ID"
	{
		$$ = &ast.AdminStmt{
			Tp:     ast.AdminShowNextRowID,
			Tables: []*ast.TableName{$3.(*ast.TableName)},
		}
	}
|	"ADMIN" "CHECK" "TABLE" TableNameList
	{
		$$ = &ast.AdminStmt{
			Tp:     ast.AdminCheckTable,
			Tables: $4.([]*ast.TableName),
		}
	}
|	"ADMIN" "CHECK" "INDEX" TableName Identifier
	{
		$$ = &ast.AdminStmt{
			Tp:     ast.AdminCheckIndex,
			Tables: []*ast.TableName{$4.(*ast.TableName)},
			Index:  string($5),
		}
	}
|	"ADMIN" "RECOVER" "INDEX" TableName Identifier
	{
		$$ = &ast.AdminStmt{
			Tp:     ast.AdminRecoverIndex,
			Tables: []*ast.TableName{$4.(*ast.TableName)},
			Index:  string($5),
		}
	}
|	"ADMIN" "CLEANUP" "INDEX" TableName Identifier
	{
		$$ = &ast.AdminStmt{
			Tp:     ast.AdminCleanupIndex,
			Tables: []*ast.TableName{$4.(*ast.TableName)},
			Index:  string($5),
		}
	}
|	"ADMIN" "CHECK" "INDEX" TableName Identifier HandleRangeList
	{
		$$ = &ast.AdminStmt{
			Tp:           ast.AdminCheckIndexRange,
			Tables:       []*ast.TableName{$4.(*ast.TableName)},
			Index:        string($5),
			HandleRanges: $6.([]ast.HandleRange),
		}
	}
|	"ADMIN" "CHECKSUM" "TABLE" TableNameList
	{
		$$ = &ast.AdminStmt{
			Tp:     ast.AdminChecksumTable,
			Tables: $4.([]*ast.TableName),
		}
	}
|	"ADMIN" "CANCEL" "DDL" "JOBS" NumList
	{
		$$ = &ast.AdminStmt{
			Tp:     ast.AdminCancelDDLJobs,
			JobIDs: $5.([]int64),
		}
	}
|	"ADMIN" "SHOW" "DDL" "JOB" "QUERIES" NumList
	{
		$$ = &ast.AdminStmt{
			Tp:     ast.AdminShowDDLJobQueries,
			JobIDs: $6.([]int64),
		}
	}
|	"ADMIN" "SHOW" "SLOW" AdminShowSlow
	{
		$$ = &ast.AdminStmt{
			Tp:       ast.AdminShowSlow,
			ShowSlow: $4.(*ast.ShowSlow),
		}
	}
|	"ADMIN" "RELOAD" "EXPR_PUSHDOWN_BLACKLIST"
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminReloadExprPushdownBlacklist,
		}
	}
|	"ADMIN" "RELOAD" "OPT_RULE_BLACKLIST"
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminReloadOptRuleBlacklist,
		}
	}
|	"ADMIN" "PLUGINS" "ENABLE" PluginNameList
	{
		$$ = &ast.AdminStmt{
			Tp:      ast.AdminPluginEnable,
			Plugins: $4.([]string),
		}
	}
|	"ADMIN" "PLUGINS" "DISABLE" PluginNameList
	{
		$$ = &ast.AdminStmt{
			Tp:      ast.AdminPluginDisable,
			Plugins: $4.([]string),
		}
	}
|	"ADMIN" "CLEANUP" "TABLE" "LOCK" TableNameList
	{
		$$ = &ast.CleanupTableLockStmt{
			Tables: $5.([]*ast.TableName),
		}
	}
|	"ADMIN" "REPAIR" "TABLE" TableName CreateTableStmt
	{
		$$ = &ast.RepairTableStmt{
			Table:      $4.(*ast.TableName),
			CreateStmt: $5.(*ast.CreateTableStmt),
		}
	}
|	"ADMIN" "FLUSH" "BINDINGS"
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminFlushBindings,
		}
	}
|	"ADMIN" "CAPTURE" "BINDINGS"
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminCaptureBindings,
		}
	}
|	"ADMIN" "EVOLVE" "BINDINGS"
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminEvolveBindings,
		}
	}
|	"ADMIN" "RELOAD" "BINDINGS"
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminReloadBindings,
		}
	}
|	"ADMIN" "RELOAD" "STATS_EXTENDED"
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminReloadStatistics,
		}
	}
|	"ADMIN" "RELOAD" "STATISTICS"
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminReloadStatistics,
		}
	}
|	"ADMIN" "SHOW" "TELEMETRY"
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminShowTelemetry,
		}
	}
|	"ADMIN" "RESET" "TELEMETRY_ID"
	{
		$$ = &ast.AdminStmt{
			Tp: ast.AdminResetTelemetryID,
		}
	}
|	"ADMIN" "FLUSH" StatementScope "PLAN_CACHE"
	{
		$$ = &ast.AdminStmt{
			Tp:             ast.AdminFlushPlanCache,
			StatementScope: $3.(ast.StatementScope),
		}
	}

AdminShowSlow:
	"RECENT" NUM
	{
		$$ = &ast.ShowSlow{
			Tp:    ast.ShowSlowRecent,
			Count: getUint64FromNUM($2),
		}
	}
|	"TOP" NUM
	{
		$$ = &ast.ShowSlow{
			Tp:    ast.ShowSlowTop,
			Kind:  ast.ShowSlowKindDefault,
			Count: getUint64FromNUM($2),
		}
	}
|	"TOP" "INTERNAL" NUM
	{
		$$ = &ast.ShowSlow{
			Tp:    ast.ShowSlowTop,
			Kind:  ast.ShowSlowKindInternal,
			Count: getUint64FromNUM($3),
		}
	}
|	"TOP" "ALL" NUM
	{
		$$ = &ast.ShowSlow{
			Tp:    ast.ShowSlowTop,
			Kind:  ast.ShowSlowKindAll,
			Count: getUint64FromNUM($3),
		}
	}

HandleRangeList:
	HandleRange
	{
		$$ = []ast.HandleRange{$1.(ast.HandleRange)}
	}
|	HandleRangeList ',' HandleRange
	{
		$$ = append($1.([]ast.HandleRange), $3.(ast.HandleRange))
	}

HandleRange:
	'(' Int64Num ',' Int64Num ')'
	{
		$$ = ast.HandleRange{Begin: $2.(int64), End: $4.(int64)}
	}

NumList:
	Int64Num
	{
		$$ = []int64{$1.(int64)}
	}
|	NumList ',' Int64Num
	{
		$$ = append($1.([]int64), $3.(int64))
	}

/****************************Show Statement*******************************/
ShowStmt:
	"SHOW" ShowTargetFilterable ShowLikeOrWhereOpt
	{
		stmt := $2.(*ast.ShowStmt)
		if $3 != nil {
			if x, ok := $3.(*ast.PatternLikeExpr); ok && x.Expr == nil {
				stmt.Pattern = x
			} else {
				stmt.Where = $3.(ast.ExprNode)
			}
		}
		$$ = stmt
	}
|	"SHOW" "CREATE" "TABLE" TableName
	{
		$$ = &ast.ShowStmt{
			Tp:    ast.ShowCreateTable,
			Table: $4.(*ast.TableName),
		}
	}
|	"SHOW" "CREATE" "VIEW" TableName
	{
		$$ = &ast.ShowStmt{
			Tp:    ast.ShowCreateView,
			Table: $4.(*ast.TableName),
		}
	}
|	"SHOW" "CREATE" "DATABASE" IfNotExists DBName
	{
		$$ = &ast.ShowStmt{
			Tp:          ast.ShowCreateDatabase,
			IfNotExists: $4.(bool),
			DBName:      $5,
		}
	}
|	"SHOW" "CREATE" "SEQUENCE" TableName
	{
		$$ = &ast.ShowStmt{
			Tp:    ast.ShowCreateSequence,
			Table: $4.(*ast.TableName),
		}
	}
|	"SHOW" "CREATE" "PLACEMENT" "POLICY" PolicyName
	{
		$$ = &ast.ShowStmt{
			Tp:     ast.ShowCreatePlacementPolicy,
			DBName: $5,
		}
	}
|	"SHOW" "CREATE" "USER" Username
	{
		// See https://dev.mysql.com/doc/refman/5.7/en/show-create-user.html
		$$ = &ast.ShowStmt{
			Tp:   ast.ShowCreateUser,
			User: $4.(*auth.UserIdentity),
		}
	}
|	"SHOW" "CREATE" "IMPORT" Identifier
	{
		$$ = &ast.ShowStmt{
			Tp:     ast.ShowCreateImport,
			DBName: $4, // we reuse DBName of ShowStmt
		}
	}
|	"SHOW" "TABLE" TableName PartitionNameListOpt "REGIONS" WhereClauseOptional
	{
		stmt := &ast.ShowStmt{
			Tp:    ast.ShowRegions,
			Table: $3.(*ast.TableName),
		}
		stmt.Table.PartitionNames = $4.([]model.CIStr)
		if $6 != nil {
			stmt.Where = $6.(ast.ExprNode)
		}
		$$ = stmt
	}
|	"SHOW" "TABLE" TableName "NEXT_ROW_ID"
	{
		$$ = &ast.ShowStmt{
			Tp:    ast.ShowTableNextRowId,
			Table: $3.(*ast.TableName),
		}
	}
|	"SHOW" "TABLE" TableName PartitionNameListOpt "INDEX" Identifier "REGIONS" WhereClauseOptional
	{
		stmt := &ast.ShowStmt{
			Tp:        ast.ShowRegions,
			Table:     $3.(*ast.TableName),
			IndexName: model.NewCIStr($6),
		}
		stmt.Table.PartitionNames = $4.([]model.CIStr)
		if $8 != nil {
			stmt.Where = $8.(ast.ExprNode)
		}
		$$ = stmt
	}
|	"SHOW" "GRANTS"
	{
		// See https://dev.mysql.com/doc/refman/5.7/en/show-grants.html
		$$ = &ast.ShowStmt{Tp: ast.ShowGrants}
	}
|	"SHOW" "GRANTS" "FOR" Username UsingRoles
	{
		// See https://dev.mysql.com/doc/refman/5.7/en/show-grants.html
		if $5 != nil {
			$$ = &ast.ShowStmt{
				Tp:    ast.ShowGrants,
				User:  $4.(*auth.UserIdentity),
				Roles: $5.([]*auth.RoleIdentity),
			}
		} else {
			$$ = &ast.ShowStmt{
				Tp:    ast.ShowGrants,
				User:  $4.(*auth.UserIdentity),
				Roles: nil,
			}
		}
	}
|	"SHOW" "MASTER" "STATUS"
	{
		$$ = &ast.ShowStmt{
			Tp: ast.ShowMasterStatus,
		}
	}
|	"SHOW" OptFull "PROCESSLIST"
	{
		$$ = &ast.ShowStmt{
			Tp:   ast.ShowProcessList,
			Full: $2.(bool),
		}
	}
|	"SHOW" "PROFILES"
	{
		$$ = &ast.ShowStmt{
			Tp: ast.ShowProfiles,
		}
	}
|	"SHOW" "PROFILE" ShowProfileTypesOpt ShowProfileArgsOpt SelectStmtLimitOpt
	{
		v := &ast.ShowStmt{
			Tp: ast.ShowProfile,
		}
		if $3 != nil {
			v.ShowProfileTypes = $3.([]int)
		}
		if $4 != nil {
			v.ShowProfileArgs = $4.(*int64)
		}
		if $5 != nil {
			v.ShowProfileLimit = $5.(*ast.Limit)
		}
		$$ = v
	}
|	"SHOW" "PRIVILEGES"
	{
		$$ = &ast.ShowStmt{
			Tp: ast.ShowPrivileges,
		}
	}
|	"SHOW" "BUILTINS"
	{
		$$ = &ast.ShowStmt{
			Tp: ast.ShowBuiltins,
		}
	}
|	"SHOW" "PLACEMENT" "FOR" ShowPlacementTarget
	{
		$$ = $4.(*ast.ShowStmt)
	}

ShowPlacementTarget:
	DatabaseSym DBName
	{
		$$ = &ast.ShowStmt{
			Tp:     ast.ShowPlacementForDatabase,
			DBName: $2,
		}
	}
|	"TABLE" TableName
	{
		$$ = &ast.ShowStmt{
			Tp:    ast.ShowPlacementForTable,
			Table: $2.(*ast.TableName),
		}
	}
|	"TABLE" TableName "PARTITION" Identifier
	{
		$$ = &ast.ShowStmt{
			Tp:        ast.ShowPlacementForPartition,
			Table:     $2.(*ast.TableName),
			Partition: model.NewCIStr($4),
		}
	}

ShowProfileTypesOpt:
	{
		$$ = nil
	}
|	ShowProfileTypes

ShowProfileTypes:
	ShowProfileType
	{
		$$ = []int{$1.(int)}
	}
|	ShowProfileTypes ',' ShowProfileType
	{
		l := $1.([]int)
		l = append(l, $3.(int))
		$$ = l
	}

ShowProfileType:
	"CPU"
	{
		$$ = ast.ProfileTypeCPU
	}
|	"MEMORY"
	{
		$$ = ast.ProfileTypeMemory
	}
|	"BLOCK" "IO"
	{
		$$ = ast.ProfileTypeBlockIo
	}
|	"CONTEXT" "SWITCHES"
	{
		$$ = ast.ProfileTypeContextSwitch
	}
|	"PAGE" "FAULTS"
	{
		$$ = ast.ProfileTypePageFaults
	}
|	"IPC"
	{
		$$ = ast.ProfileTypeIpc
	}
|	"SWAPS"
	{
		$$ = ast.ProfileTypeSwaps
	}
|	"SOURCE"
	{
		$$ = ast.ProfileTypeSource
	}
|	"ALL"
	{
		$$ = ast.ProfileTypeAll
	}

ShowProfileArgsOpt:
	{
		$$ = nil
	}
|	"FOR" "QUERY" Int64Num
	{
		v := $3.(int64)
		$$ = &v
	}

UsingRoles:
	{
		$$ = nil
	}
|	"USING" RolenameList
	{
		$$ = $2.([]*auth.RoleIdentity)
	}

ShowIndexKwd:
	"INDEX"
|	"INDEXES"
|	"KEYS"

FromOrIn:
	"FROM"
|	"IN"

ShowTargetFilterable:
	"ENGINES"
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowEngines}
	}
|	"DATABASES"
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowDatabases}
	}
|	"CONFIG"
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowConfig}
	}
|	CharsetKw
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowCharset}
	}
|	OptFull "TABLES" ShowDatabaseNameOpt
	{
		$$ = &ast.ShowStmt{
			Tp:     ast.ShowTables,
			DBName: $3,
			Full:   $1.(bool),
		}
	}
|	"OPEN" "TABLES" ShowDatabaseNameOpt
	{
		$$ = &ast.ShowStmt{
			Tp:     ast.ShowOpenTables,
			DBName: $3,
		}
	}
|	"TABLE" "STATUS" ShowDatabaseNameOpt
	{
		$$ = &ast.ShowStmt{
			Tp:     ast.ShowTableStatus,
			DBName: $3,
		}
	}
|	ShowIndexKwd FromOrIn TableName
	{
		$$ = &ast.ShowStmt{
			Tp:    ast.ShowIndex,
			Table: $3.(*ast.TableName),
		}
	}
|	ShowIndexKwd FromOrIn Identifier FromOrIn Identifier
	{
		show := &ast.ShowStmt{
			Tp:    ast.ShowIndex,
			Table: &ast.TableName{Name: model.NewCIStr($3), Schema: model.NewCIStr($5)},
		}
		$$ = show
	}
|	OptFull FieldsOrColumns ShowTableAliasOpt ShowDatabaseNameOpt
	{
		$$ = &ast.ShowStmt{
			Tp:     ast.ShowColumns,
			Table:  $3.(*ast.TableName),
			DBName: $4,
			Full:   $1.(bool),
		}
	}
|	"EXTENDED" OptFull FieldsOrColumns ShowTableAliasOpt ShowDatabaseNameOpt
	{
		$$ = &ast.ShowStmt{
			Tp:       ast.ShowColumns,
			Table:    $4.(*ast.TableName),
			DBName:   $5,
			Full:     $2.(bool),
			Extended: true,
		}
	}
|	"WARNINGS"
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowWarnings}
	}
|	"ERRORS"
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowErrors}
	}
|	GlobalScope "VARIABLES"
	{
		$$ = &ast.ShowStmt{
			Tp:          ast.ShowVariables,
			GlobalScope: $1.(bool),
		}
	}
|	GlobalScope "STATUS"
	{
		$$ = &ast.ShowStmt{
			Tp:          ast.ShowStatus,
			GlobalScope: $1.(bool),
		}
	}
|	GlobalScope "BINDINGS"
	{
		$$ = &ast.ShowStmt{
			Tp:          ast.ShowBindings,
			GlobalScope: $1.(bool),
		}
	}
|	"COLLATION"
	{
		$$ = &ast.ShowStmt{
			Tp: ast.ShowCollation,
		}
	}
|	"TRIGGERS" ShowDatabaseNameOpt
	{
		$$ = &ast.ShowStmt{
			Tp:     ast.ShowTriggers,
			DBName: $2,
		}
	}
|	"BINDING_CACHE" "STATUS"
	{
		$$ = &ast.ShowStmt{
			Tp: ast.ShowBindingCacheStatus,
		}
	}
|	"PROCEDURE" "STATUS"
	{
		$$ = &ast.ShowStmt{
			Tp: ast.ShowProcedureStatus,
		}
	}
|	"PUMP" "STATUS"
	{
		$$ = &ast.ShowStmt{
			Tp: ast.ShowPumpStatus,
		}
	}
|	"DRAINER" "STATUS"
	{
		$$ = &ast.ShowStmt{
			Tp: ast.ShowDrainerStatus,
		}
	}
|	"FUNCTION" "STATUS"
	{
		// This statement is similar to SHOW PROCEDURE STATUS but for stored functions.
		// See http://dev.mysql.com/doc/refman/5.7/en/show-function-status.html
		// We do not support neither stored functions nor stored procedures.
		// So we reuse show procedure status process logic.
		$$ = &ast.ShowStmt{
			Tp: ast.ShowProcedureStatus,
		}
	}
|	"EVENTS" ShowDatabaseNameOpt
	{
		$$ = &ast.ShowStmt{
			Tp:     ast.ShowEvents,
			DBName: $2,
		}
	}
|	"PLUGINS"
	{
		$$ = &ast.ShowStmt{
			Tp: ast.ShowPlugins,
		}
	}
|	"STATS_EXTENDED"
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowStatsExtended}
	}
|	"STATS_META"
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowStatsMeta}
	}
|	"STATS_HISTOGRAMS"
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowStatsHistograms}
	}
|	"STATS_TOPN"
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowStatsTopN}
	}
|	"STATS_BUCKETS"
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowStatsBuckets}
	}
|	"STATS_HEALTHY"
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowStatsHealthy}
	}
|	"HISTOGRAMS_IN_FLIGHT"
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowHistogramsInFlight}
	}
|	"COLUMN_STATS_USAGE"
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowColumnStatsUsage}
	}
|	"ANALYZE" "STATUS"
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowAnalyzeStatus}
	}
|	"BACKUPS"
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowBackups}
	}
|	"RESTORES"
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowRestores}
	}
|	"IMPORTS"
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowImports}
	}
|	"PLACEMENT"
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowPlacement}
	}
|	"PLACEMENT" "LABELS"
	{
		$$ = &ast.ShowStmt{Tp: ast.ShowPlacementLabels}
	}

ShowLikeOrWhereOpt:
	{
		$$ = nil
	}
|	"LIKE" SimpleExpr
	{
		$$ = &ast.PatternLikeExpr{
			Pattern: $2,
			Escape:  '\\',
		}
	}
|	"WHERE" Expression
	{
		$$ = $2
	}

GlobalScope:
	{
		$$ = false
	}
|	"GLOBAL"
	{
		$$ = true
	}
|	"SESSION"
	{
		$$ = false
	}

StatementScope:
	{
		$$ = ast.StatementScopeSession
	}
|	"GLOBAL"
	{
		$$ = ast.StatementScopeGlobal
	}
|	"INSTANCE"
	{
		$$ = ast.StatementScopeInstance
	}
|	"SESSION"
	{
		$$ = ast.StatementScopeSession
	}

OptFull:
	{
		$$ = false
	}
|	"FULL"
	{
		$$ = true
	}

ShowDatabaseNameOpt:
	{
		$$ = ""
	}
|	FromOrIn DBName
	{
		$$ = $2
	}

ShowTableAliasOpt:
	FromOrIn TableName
	{
		$$ = $2.(*ast.TableName)
	}

FlushStmt:
	"FLUSH" NoWriteToBinLogAliasOpt FlushOption
	{
		tmp := $3.(*ast.FlushStmt)
		tmp.NoWriteToBinLog = $2.(bool)
		$$ = tmp
	}

PluginNameList:
	Identifier
	{
		$$ = []string{$1}
	}
|	PluginNameList ',' Identifier
	{
		$$ = append($1.([]string), $3)
	}

FlushOption:
	"PRIVILEGES"
	{
		$$ = &ast.FlushStmt{
			Tp: ast.FlushPrivileges,
		}
	}
|	"STATUS"
	{
		$$ = &ast.FlushStmt{
			Tp: ast.FlushStatus,
		}
	}
|	"TIDB" "PLUGINS" PluginNameList
	{
		$$ = &ast.FlushStmt{
			Tp:      ast.FlushTiDBPlugin,
			Plugins: $3.([]string),
		}
	}
|	"HOSTS"
	{
		$$ = &ast.FlushStmt{
			Tp: ast.FlushHosts,
		}
	}
|	LogTypeOpt "LOGS"
	{
		$$ = &ast.FlushStmt{
			Tp:      ast.FlushLogs,
			LogType: $1.(ast.LogType),
		}
	}
|	TableOrTables TableNameListOpt WithReadLockOpt
	{
		$$ = &ast.FlushStmt{
			Tp:       ast.FlushTables,
			Tables:   $2.([]*ast.TableName),
			ReadLock: $3.(bool),
		}
	}
|	"CLIENT_ERRORS_SUMMARY"
	{
		$$ = &ast.FlushStmt{
			Tp: ast.FlushClientErrorsSummary,
		}
	}

LogTypeOpt:
	/* empty */
	{
		$$ = ast.LogTypeDefault
	}
|	"BINARY"
	{
		$$ = ast.LogTypeBinary
	}
|	"ENGINE"
	{
		$$ = ast.LogTypeEngine
	}
|	"ERROR"
	{
		$$ = ast.LogTypeError
	}
|	"GENERAL"
	{
		$$ = ast.LogTypeGeneral
	}
|	"SLOW"
	{
		$$ = ast.LogTypeSlow
	}

NoWriteToBinLogAliasOpt:
	%prec lowerThanLocal
	{
		$$ = false
	}
|	"NO_WRITE_TO_BINLOG"
	{
		$$ = true
	}
|	"LOCAL"
	{
		$$ = true
	}

TableNameListOpt:
	%prec empty
	{
		$$ = []*ast.TableName{}
	}
|	TableNameList

TableNameListOpt2:
	%prec empty
	{
		$$ = []*ast.TableName{}
	}
|	"TABLE" TableNameList
	{
		$$ = $2
	}

WithReadLockOpt:
	{
		$$ = false
	}
|	"WITH" "READ" "LOCK"
	{
		$$ = true
	}

Statement:
	EmptyStmt
|	AdminStmt
|	AlterDatabaseStmt
|	AlterTableStmt
|	AlterUserStmt
|	AlterImportStmt
|	AlterInstanceStmt
|	AlterSequenceStmt
|	AlterPolicyStmt
|	AnalyzeTableStmt
|	BeginTransactionStmt
|	BinlogStmt
|	BRIEStmt
|	CommitStmt
|	DeallocateStmt
|	DeleteFromStmt
|	ExecuteStmt
|	ExplainStmt
|	ChangeStmt
|	CreateDatabaseStmt
|	CreateImportStmt
|	CreateIndexStmt
|	CreateTableStmt
|	CreateViewStmt
|	CreateUserStmt
|	CreateRoleStmt
|	CreateBindingStmt
|	CreatePolicyStmt
|	CreateSequenceStmt
|	CreateStatisticsStmt
|	DoStmt
|	DropDatabaseStmt
|	DropImportStmt
|	DropIndexStmt
|	DropTableStmt
|	DropPolicyStmt
|	DropSequenceStmt
|	DropViewStmt
|	DropUserStmt
|	DropRoleStmt
|	DropStatisticsStmt
|	DropStatsStmt
|	DropBindingStmt
|	FlushStmt
|	FlashbackTableStmt
|	GrantStmt
|	GrantProxyStmt
|	GrantRoleStmt
|	CallStmt
|	InsertIntoStmt
|	IndexAdviseStmt
|	KillStmt
|	LoadDataStmt
|	LoadStatsStmt
|	PlanReplayerStmt
|	PreparedStmt
|	PurgeImportStmt
|	RollbackStmt
|	RenameTableStmt
|	RenameUserStmt
|	ReplaceIntoStmt
|	RecoverTableStmt
|	ResumeImportStmt
|	RevokeStmt
|	RevokeRoleStmt
|	SetOprStmt
|	SelectStmt
|	SelectStmtWithClause
|	SubSelect
	{
		var sel ast.StmtNode
		switch x := $1.(*ast.SubqueryExpr).Query.(type) {
		case *ast.SelectStmt:
			x.IsInBraces = true
			sel = x
		case *ast.SetOprStmt:
			x.IsInBraces = true
			sel = x
		}
		$$ = sel
	}
|	SetStmt
|	SetBindingStmt
|	SetRoleStmt
|	SetDefaultRoleStmt
|	SplitRegionStmt
|	StopImportStmt
|	ShowImportStmt
|	ShowStmt
|	TraceStmt
|	TruncateTableStmt
|	UpdateStmt
|	UseStmt
|	UnlockTablesStmt
|	LockTablesStmt
|	ShutdownStmt
|	RestartStmt
|	HelpStmt
|	NonTransactionalDeleteStmt

TraceableStmt:
	DeleteFromStmt
|	UpdateStmt
|	InsertIntoStmt
|	ReplaceIntoStmt
|	SetOprStmt
|	SelectStmt
|	SelectStmtWithClause
|	SubSelect
	{
		var sel ast.StmtNode
		switch x := $1.(*ast.SubqueryExpr).Query.(type) {
		case *ast.SelectStmt:
			x.IsInBraces = true
			sel = x
		case *ast.SetOprStmt:
			x.IsInBraces = true
			sel = x
		}
		$$ = sel
	}
|	LoadDataStmt
|	BeginTransactionStmt
|	CommitStmt
|	RollbackStmt
|	SetStmt

ExplainableStmt:
	DeleteFromStmt
|	UpdateStmt
|	InsertIntoStmt
|	ReplaceIntoStmt
|	SetOprStmt
|	SelectStmt
|	SelectStmtWithClause
|	SubSelect
	{
		var sel ast.StmtNode
		switch x := $1.(*ast.SubqueryExpr).Query.(type) {
		case *ast.SelectStmt:
			x.IsInBraces = true
			sel = x
		case *ast.SetOprStmt:
			x.IsInBraces = true
			sel = x
		}
		$$ = sel
	}
|	AlterTableStmt

StatementList:
	Statement
	{
		if $1 != nil {
			s := $1
			if lexer, ok := yylex.(stmtTexter); ok {
				s.SetText(parser.lexer.client, lexer.stmtText())
			}
			parser.result = append(parser.result, s)
		}
	}
|	StatementList ';' Statement
	{
		if $3 != nil {
			s := $3
			if lexer, ok := yylex.(stmtTexter); ok {
				s.SetText(parser.lexer.client, lexer.stmtText())
			}
			parser.result = append(parser.result, s)
		}
	}

Constraint:
	ConstraintKeywordOpt ConstraintElem
	{
		cst := $2.(*ast.Constraint)
		if $1 != nil {
			cst.Name = $1.(string)
		}
		$$ = cst
	}

CheckConstraintKeyword:
	"CHECK"
|	"CONSTRAINT"

TableElement:
	ColumnDef
|	Constraint

TableElementList:
	TableElement
	{
		if $1 != nil {
			$$ = []interface{}{$1.(interface{})}
		} else {
			$$ = []interface{}{}
		}
	}
|	TableElementList ',' TableElement
	{
		if $3 != nil {
			$$ = append($1.([]interface{}), $3)
		} else {
			$$ = $1
		}
	}

TableElementListOpt:
	/* empty */ %prec lowerThanCreateTableSelect
	{
		var columnDefs []*ast.ColumnDef
		var constraints []*ast.Constraint
		$$ = &ast.CreateTableStmt{
			Cols:        columnDefs,
			Constraints: constraints,
		}
	}
|	'(' TableElementList ')'
	{
		tes := $2.([]interface{})
		var columnDefs []*ast.ColumnDef
		var constraints []*ast.Constraint
		for _, te := range tes {
			switch te := te.(type) {
			case *ast.ColumnDef:
				columnDefs = append(columnDefs, te)
			case *ast.Constraint:
				constraints = append(constraints, te)
			}
		}
		$$ = &ast.CreateTableStmt{
			Cols:        columnDefs,
			Constraints: constraints,
		}
	}

TableOption:
	PartDefOption
|	DefaultKwdOpt CharsetKw EqOpt CharsetName
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionCharset, StrValue: $4,
			UintValue: ast.TableOptionCharsetWithoutConvertTo}
	}
|	DefaultKwdOpt "COLLATE" EqOpt CollationName
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionCollate, StrValue: $4,
			UintValue: ast.TableOptionCharsetWithoutConvertTo}
	}
|	ForceOpt "AUTO_INCREMENT" EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionAutoIncrement, UintValue: $4.(uint64), BoolValue: $1.(bool)}
	}
|	"AUTO_ID_CACHE" EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionAutoIdCache, UintValue: $3.(uint64)}
	}
|	ForceOpt "AUTO_RANDOM_BASE" EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionAutoRandomBase, UintValue: $4.(uint64), BoolValue: $1.(bool)}
	}
|	"AVG_ROW_LENGTH" EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionAvgRowLength, UintValue: $3.(uint64)}
	}
|	"CONNECTION" EqOpt stringLit
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionConnection, StrValue: $3}
	}
|	"CHECKSUM" EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionCheckSum, UintValue: $3.(uint64)}
	}
|	"TABLE_CHECKSUM" EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionTableCheckSum, UintValue: $3.(uint64)}
	}
|	"PASSWORD" EqOpt stringLit
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionPassword, StrValue: $3}
	}
|	"COMPRESSION" EqOpt stringLit
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionCompression, StrValue: $3}
	}
|	"KEY_BLOCK_SIZE" EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionKeyBlockSize, UintValue: $3.(uint64)}
	}
|	"DELAY_KEY_WRITE" EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionDelayKeyWrite, UintValue: $3.(uint64)}
	}
|	RowFormat
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionRowFormat, UintValue: $1.(uint64)}
	}
|	"STATS_PERSISTENT" EqOpt StatsPersistentVal
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionStatsPersistent}
	}
|	"STATS_AUTO_RECALC" EqOpt LengthNum
	{
		n := $3.(uint64)
		if n != 0 && n != 1 {
			yylex.AppendError(yylex.Errorf("The value of STATS_AUTO_RECALC must be one of [0|1|DEFAULT]."))
			return 1
		}
		$$ = &ast.TableOption{Tp: ast.TableOptionStatsAutoRecalc, UintValue: n}
		yylex.AppendError(yylex.Errorf("The STATS_AUTO_RECALC is parsed but ignored by all storage engines."))
		parser.lastErrorAsWarn()
	}
|	"STATS_AUTO_RECALC" EqOpt "DEFAULT"
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionStatsAutoRecalc, Default: true}
		yylex.AppendError(yylex.Errorf("The STATS_AUTO_RECALC is parsed but ignored by all storage engines."))
		parser.lastErrorAsWarn()
	}
|	"STATS_SAMPLE_PAGES" EqOpt LengthNum
	{
		// Parse it but will ignore it.
		// In MySQL, STATS_SAMPLE_PAGES=N(Where 0<N<=65535) or STAS_SAMPLE_PAGES=DEFAULT.
		// Cause we don't support it, so we don't check range of the value.
		$$ = &ast.TableOption{Tp: ast.TableOptionStatsSamplePages, UintValue: $3.(uint64)}
		yylex.AppendError(yylex.Errorf("The STATS_SAMPLE_PAGES is parsed but ignored by all storage engines."))
		parser.lastErrorAsWarn()
	}
|	"STATS_SAMPLE_PAGES" EqOpt "DEFAULT"
	{
		// Parse it but will ignore it.
		// In MySQL, default value of STATS_SAMPLE_PAGES is 0.
		$$ = &ast.TableOption{Tp: ast.TableOptionStatsSamplePages, Default: true}
		yylex.AppendError(yylex.Errorf("The STATS_SAMPLE_PAGES is parsed but ignored by all storage engines."))
		parser.lastErrorAsWarn()
	}
|	"STATS_BUCKETS" EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionStatsBuckets, UintValue: $3.(uint64)}
	}
|	"STATS_TOPN" EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionStatsTopN, UintValue: $3.(uint64)}
	}
|	"STATS_SAMPLE_RATE" EqOpt NumLiteral
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionStatsSampleRate, Value: ast.NewValueExpr($3, "", "")}
	}
|	"STATS_COL_CHOICE" EqOpt stringLit
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionStatsColsChoice, StrValue: $3}
	}
|	"STATS_COL_LIST" EqOpt stringLit
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionStatsColList, StrValue: $3}
	}
|	"SHARD_ROW_ID_BITS" EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionShardRowID, UintValue: $3.(uint64)}
	}
|	"PRE_SPLIT_REGIONS" EqOpt LengthNum
	{
		$$ = &ast.TableOption{Tp: ast.TableOptionPreSplitRegion, UintValue: $3.(uint64)}
	}
|	"PACK_KEYS" EqOpt StatsPersistentVal
	{
		// Parse it but will ignore it.
		$$ = &ast.TableOption{Tp: ast.TableOptionPackKeys}
	}
|	"STORAGE" "MEMORY"
	{
		// Parse it but will ignore it.
		$$ = &ast.TableOption{Tp: ast.TableOptionStorageMedia, StrValue: "MEMORY"}
		yylex.AppendError(yylex.Errorf("The STORAGE clause is parsed but ignored by all storage engines."))
		parser.lastErrorAsWarn()
	}
|	"STORAGE" "DISK"
	{
		// Parse it but will ignore it.
		$$ = &ast.TableOption{Tp: ast.TableOptionStorageMedia, StrValue: "DISK"}
		yylex.AppendError(yylex.Errorf("The STORAGE clause is parsed but ignored by all storage engines."))
		parser.lastErrorAsWarn()
	}
|	"SECONDARY_ENGINE" EqOpt "NULL"
	{
		// Parse it but will ignore it
		// See https://github.com/mysql/mysql-server/blob/8.0/sql/sql_yacc.yy#L5977-L5984
		$$ = &ast.TableOption{Tp: ast.TableOptionSecondaryEngineNull}
		yylex.AppendError(yylex.Errorf("The SECONDARY_ENGINE clause is parsed but ignored by all storage engines."))
		parser.lastErrorAsWarn()
	}
|	"SECONDARY_ENGINE" EqOpt StringName
	{
		// Parse it but will ignore it
		// See https://github.com/mysql/mysql-server/blob/8.0/sql/sql_yacc.yy#L5977-L5984
		$$ = &ast.TableOption{Tp: ast.TableOptionSecondaryEngine, StrValue: $3}
		yylex.AppendError(yylex.Errorf("The SECONDARY_ENGINE clause is parsed but ignored by all storage engines."))
		parser.lastErrorAsWarn()
	}
|	"UNION" EqOpt '(' TableNameListOpt ')'
	{
		// Parse it but will ignore it
		$$ = &ast.TableOption{
			Tp:         ast.TableOptionUnion,
			TableNames: $4.([]*ast.TableName),
		}
		yylex.AppendError(yylex.Errorf("The UNION option is parsed but ignored by all storage engines."))
		parser.lastErrorAsWarn()
	}
|	"ENCRYPTION" EqOpt EncryptionOpt
	{
		// Parse it but will ignore it
		$$ = &ast.TableOption{Tp: ast.TableOptionEncryption, StrValue: $3}
	}

ForceOpt:
	/* empty */
	{
		$$ = false
	}
|	"FORCE"
	{
		$$ = true
	}

StatsPersistentVal:
	"DEFAULT"
	{}
|	LengthNum
	{}

CreateTableOptionListOpt:
	/* empty */ %prec lowerThanCreateTableSelect
	{
		$$ = []*ast.TableOption{}
	}
|	TableOptionList %prec lowerThanComma

TableOptionList:
	TableOption
	{
		$$ = []*ast.TableOption{$1.(*ast.TableOption)}
	}
|	TableOptionList TableOption
	{
		$$ = append($1.([]*ast.TableOption), $2.(*ast.TableOption))
	}
|	TableOptionList ',' TableOption
	{
		$$ = append($1.([]*ast.TableOption), $3.(*ast.TableOption))
	}

OptTable:
	{}
|	"TABLE"

TruncateTableStmt:
	"TRUNCATE" OptTable TableName
	{
		$$ = &ast.TruncateTableStmt{Table: $3.(*ast.TableName)}
	}

RowFormat:
	"ROW_FORMAT" EqOpt "DEFAULT"
	{
		$$ = ast.RowFormatDefault
	}
|	"ROW_FORMAT" EqOpt "DYNAMIC"
	{
		$$ = ast.RowFormatDynamic
	}
|	"ROW_FORMAT" EqOpt "FIXED"
	{
		$$ = ast.RowFormatFixed
	}
|	"ROW_FORMAT" EqOpt "COMPRESSED"
	{
		$$ = ast.RowFormatCompressed
	}
|	"ROW_FORMAT" EqOpt "REDUNDANT"
	{
		$$ = ast.RowFormatRedundant
	}
|	"ROW_FORMAT" EqOpt "COMPACT"
	{
		$$ = ast.RowFormatCompact
	}
|	"ROW_FORMAT" EqOpt "TOKUDB_DEFAULT"
	{
		$$ = ast.TokuDBRowFormatDefault
	}
|	"ROW_FORMAT" EqOpt "TOKUDB_FAST"
	{
		$$ = ast.TokuDBRowFormatFast
	}
|	"ROW_FORMAT" EqOpt "TOKUDB_SMALL"
	{
		$$ = ast.TokuDBRowFormatSmall
	}
|	"ROW_FORMAT" EqOpt "TOKUDB_ZLIB"
	{
		$$ = ast.TokuDBRowFormatZlib
	}
|	"ROW_FORMAT" EqOpt "TOKUDB_QUICKLZ"
	{
		$$ = ast.TokuDBRowFormatQuickLZ
	}
|	"ROW_FORMAT" EqOpt "TOKUDB_LZMA"
	{
		$$ = ast.TokuDBRowFormatLzma
	}
|	"ROW_FORMAT" EqOpt "TOKUDB_SNAPPY"
	{
		$$ = ast.TokuDBRowFormatSnappy
	}
|	"ROW_FORMAT" EqOpt "TOKUDB_UNCOMPRESSED"
	{
		$$ = ast.TokuDBRowFormatUncompressed
	}

/*************************************Type Begin***************************************/
Type:
	NumericType
|	StringType
|	DateAndTimeType

NumericType:
	IntegerType OptFieldLen FieldOpts
	{
		// TODO: check flen 0
		tp := types.NewFieldType($1.(byte))
		tp.SetFlen($2.(int))
		if $2.(int) != types.UnspecifiedLength && types.TiDBStrictIntegerDisplayWidth {
			yylex.AppendError(ErrWarnDeprecatedIntegerDisplayWidth)
			parser.lastErrorAsWarn()
		}
		for _, o := range $3.([]*ast.TypeOpt) {
			if o.IsUnsigned {
				tp.AddFlag(mysql.UnsignedFlag)
			}
			if o.IsZerofill {
				tp.AddFlag(mysql.ZerofillFlag)
			}
		}
		$$ = tp
	}
|	BooleanType FieldOpts
	{
		// TODO: check flen 0
		tp := types.NewFieldType($1.(byte))
		tp.SetFlen(1)
		for _, o := range $2.([]*ast.TypeOpt) {
			if o.IsUnsigned {
				tp.AddFlag(mysql.UnsignedFlag)
			}
			if o.IsZerofill {
				tp.AddFlag(mysql.ZerofillFlag)
			}
		}
		$$ = tp
	}
|	FixedPointType FloatOpt FieldOpts
	{
		fopt := $2.(*ast.FloatOpt)
		tp := types.NewFieldType($1.(byte))
		tp.SetFlen(fopt.Flen)
		tp.SetDecimal(fopt.Decimal)
		for _, o := range $3.([]*ast.TypeOpt) {
			if o.IsUnsigned {
				tp.AddFlag(mysql.UnsignedFlag)
			}
			if o.IsZerofill {
				tp.AddFlag(mysql.ZerofillFlag)
			}
		}
		$$ = tp
	}
|	FloatingPointType FloatOpt FieldOpts
	{
		fopt := $2.(*ast.FloatOpt)
		tp := types.NewFieldType($1.(byte))
		// check for a double(10) for syntax error
		if tp.GetType() == mysql.TypeDouble && parser.strictDoubleFieldType {
			if fopt.Flen != types.UnspecifiedLength && fopt.Decimal == types.UnspecifiedLength {
				yylex.AppendError(ErrSyntax)
				return 1
			}
		}
		tp.SetFlen(fopt.Flen)
		if tp.GetType() == mysql.TypeFloat && fopt.Decimal == types.UnspecifiedLength && tp.GetFlen() <= mysql.MaxDoublePrecisionLength {
			if tp.GetFlen() > mysql.MaxFloatPrecisionLength {
				tp.SetType(mysql.TypeDouble)
			}
			tp.SetFlen(types.UnspecifiedLength)
		}
		tp.SetDecimal(fopt.Decimal)
		for _, o := range $3.([]*ast.TypeOpt) {
			if o.IsUnsigned {
				tp.AddFlag(mysql.UnsignedFlag)
			}
			if o.IsZerofill {
				tp.AddFlag(mysql.ZerofillFlag)
			}
		}
		$$ = tp
	}
|	BitValueType OptFieldLen
	{
		tp := types.NewFieldType($1.(byte))
		tp.SetFlen($2.(int))
		if tp.GetFlen() == types.UnspecifiedLength {
			tp.SetFlen(1)
		}
		$$ = tp
	}

IntegerType:
	"TINYINT"
	{
		$$ = mysql.TypeTiny
	}
|	"SMALLINT"
	{
		$$ = mysql.TypeShort
	}
|	"MEDIUMINT"
	{
		$$ = mysql.TypeInt24
	}
|	"INT"
	{
		$$ = mysql.TypeLong
	}
|	"INT1"
	{
		$$ = mysql.TypeTiny
	}
|	"INT2"
	{
		$$ = mysql.TypeShort
	}
|	"INT3"
	{
		$$ = mysql.TypeInt24
	}
|	"INT4"
	{
		$$ = mysql.TypeLong
	}
|	"INT8"
	{
		$$ = mysql.TypeLonglong
	}
|	"INTEGER"
	{
		$$ = mysql.TypeLong
	}
|	"BIGINT"
	{
		$$ = mysql.TypeLonglong
	}

BooleanType:
	"BOOL"
	{
		$$ = mysql.TypeTiny
	}
|	"BOOLEAN"
	{
		$$ = mysql.TypeTiny
	}

OptInteger:
	{}
|	"INTEGER"
|	"INT"

FixedPointType:
	"DECIMAL"
	{
		$$ = mysql.TypeNewDecimal
	}
|	"NUMERIC"
	{
		$$ = mysql.TypeNewDecimal
	}
|	"FIXED"
	{
		$$ = mysql.TypeNewDecimal
	}

FloatingPointType:
	"FLOAT"
	{
		$$ = mysql.TypeFloat
	}
|	"REAL"
	{
		if parser.lexer.GetSQLMode().HasRealAsFloatMode() {
			$$ = mysql.TypeFloat
		} else {
			$$ = mysql.TypeDouble
		}
	}
|	"DOUBLE"
	{
		$$ = mysql.TypeDouble
	}
|	"DOUBLE" "PRECISION"
	{
		$$ = mysql.TypeDouble
	}

BitValueType:
	"BIT"
	{
		$$ = mysql.TypeBit
	}

StringType:
	Char FieldLen OptBinary
	{
		tp := types.NewFieldType(mysql.TypeString)
		tp.SetFlen($2.(int))
		tp.SetCharset($3.(*ast.OptBinary).Charset)
		if $3.(*ast.OptBinary).IsBinary {
			tp.AddFlag(mysql.BinaryFlag)
		}
		$$ = tp
	}
|	Char OptBinary
	{
		tp := types.NewFieldType(mysql.TypeString)
		tp.SetCharset($2.(*ast.OptBinary).Charset)
		if $2.(*ast.OptBinary).IsBinary {
			tp.AddFlag(mysql.BinaryFlag)
		}
		$$ = tp
	}
|	NChar FieldLen OptBinary
	{
		tp := types.NewFieldType(mysql.TypeString)
		tp.SetFlen($2.(int))
		tp.SetCharset($3.(*ast.OptBinary).Charset)
		if $3.(*ast.OptBinary).IsBinary {
			tp.AddFlag(mysql.BinaryFlag)
		}
		$$ = tp
	}
|	NChar OptBinary
	{
		tp := types.NewFieldType(mysql.TypeString)
		tp.SetCharset($2.(*ast.OptBinary).Charset)
		if $2.(*ast.OptBinary).IsBinary {
			tp.AddFlag(mysql.BinaryFlag)
		}
		$$ = tp
	}
|	Varchar FieldLen OptBinary
	{
		tp := types.NewFieldType(mysql.TypeVarchar)
		tp.SetFlen($2.(int))
		tp.SetCharset($3.(*ast.OptBinary).Charset)
		if $3.(*ast.OptBinary).IsBinary {
			tp.AddFlag(mysql.BinaryFlag)
		}
		$$ = tp
	}
|	NVarchar FieldLen OptBinary
	{
		tp := types.NewFieldType(mysql.TypeVarchar)
		tp.SetFlen($2.(int))
		tp.SetCharset($3.(*ast.OptBinary).Charset)
		if $3.(*ast.OptBinary).IsBinary {
			tp.AddFlag(mysql.BinaryFlag)
		}
		$$ = tp
	}
|	"BINARY" OptFieldLen
	{
		tp := types.NewFieldType(mysql.TypeString)
		tp.SetFlen($2.(int))
		tp.SetCharset(charset.CharsetBin)
		tp.SetCollate(charset.CharsetBin)
		tp.AddFlag(mysql.BinaryFlag)
		$$ = tp
	}
|	"VARBINARY" FieldLen
	{
		tp := types.NewFieldType(mysql.TypeVarchar)
		tp.SetFlen($2.(int))
		tp.SetCharset(charset.CharsetBin)
		tp.SetCollate(charset.CharsetBin)
		tp.AddFlag(mysql.BinaryFlag)
		$$ = tp
	}
|	BlobType
	{
		tp := $1.(*types.FieldType)
		tp.SetCharset(charset.CharsetBin)
		tp.SetCollate(charset.CharsetBin)
		tp.AddFlag(mysql.BinaryFlag)
		$$ = tp
	}
|	TextType OptCharsetWithOptBinary
	{
		tp := $1.(*types.FieldType)
		tp.SetCharset($2.(*ast.OptBinary).Charset)
		if $2.(*ast.OptBinary).IsBinary {
			tp.AddFlag(mysql.BinaryFlag)
		}
		$$ = tp
	}
|	"ENUM" '(' TextStringList ')' OptCharsetWithOptBinary
	{
		tp := types.NewFieldType(mysql.TypeEnum)
		elems := $3.([]*ast.TextString)
		opt := $5.(*ast.OptBinary)
		tp.SetElems(ast.TransformTextStrings(elems, opt.Charset))
		fieldLen := -1 // enum_flen = max(ele_flen)
		for i := range tp.GetElems() {
			tp.SetElem(i, strings.TrimRight(tp.GetElem(i), " "))
			if len(tp.GetElem(i)) > fieldLen {
				fieldLen = len(tp.GetElem(i))
			}
		}
		tp.SetFlen(fieldLen)
		tp.SetCharset(opt.Charset)
		if opt.IsBinary {
			tp.AddFlag(mysql.BinaryFlag)
		}
		$$ = tp
	}
|	"SET" '(' TextStringList ')' OptCharsetWithOptBinary
	{
		tp := types.NewFieldType(mysql.TypeSet)
		elems := $3.([]*ast.TextString)
		opt := $5.(*ast.OptBinary)
		tp.SetElems(ast.TransformTextStrings(elems, opt.Charset))
		fieldLen := len(tp.GetElems()) - 1 // set_flen = sum(ele_flen) + number_of_ele - 1
		for i := range tp.GetElems() {
			tp.SetElem(i, strings.TrimRight(tp.GetElem(i), " "))
			fieldLen += len(tp.GetElem(i))
		}
		tp.SetFlen(fieldLen)
		tp.SetCharset(opt.Charset)
		if opt.IsBinary {
			tp.AddFlag(mysql.BinaryFlag)
		}
		$$ = tp
	}
|	"JSON"
	{
		tp := types.NewFieldType(mysql.TypeJSON)
		tp.SetDecimal(0)
		tp.SetCharset(charset.CharsetBin)
		tp.SetCollate(charset.CollationBin)
		$$ = tp
	}
|	"LONG" Varchar OptCharsetWithOptBinary
	{
		tp := types.NewFieldType(mysql.TypeMediumBlob)
		tp.SetCharset($3.(*ast.OptBinary).Charset)
		if $3.(*ast.OptBinary).IsBinary {
			tp.AddFlag(mysql.BinaryFlag)
		}
		$$ = tp
	}
|	"LONG" OptCharsetWithOptBinary
	{
		tp := types.NewFieldType(mysql.TypeMediumBlob)
		tp.SetCharset($2.(*ast.OptBinary).Charset)
		if $2.(*ast.OptBinary).IsBinary {
			tp.AddFlag(mysql.BinaryFlag)
		}
		$$ = tp
	}

Char:
	"CHARACTER"
|	"CHAR"

NChar:
	"NCHAR"
|	"NATIONAL" "CHARACTER"
|	"NATIONAL" "CHAR"

Varchar:
	"CHARACTER" "VARYING"
|	"CHAR" "VARYING"
|	"VARCHAR"
|	"VARCHARACTER"

NVarchar:
	"NATIONAL" "VARCHAR"
|	"NATIONAL" "VARCHARACTER"
|	"NVARCHAR"
|	"NCHAR" "VARCHAR"
|	"NCHAR" "VARCHARACTER"
|	"NATIONAL" "CHARACTER" "VARYING"
|	"NATIONAL" "CHAR" "VARYING"
|	"NCHAR" "VARYING"

Year:
	"YEAR"
|	"SQL_TSI_YEAR"

BlobType:
	"TINYBLOB"
	{
		tp := types.NewFieldType(mysql.TypeTinyBlob)
		$$ = tp
	}
|	"BLOB" OptFieldLen
	{
		tp := types.NewFieldType(mysql.TypeBlob)
		tp.SetFlen($2.(int))
		$$ = tp
	}
|	"MEDIUMBLOB"
	{
		tp := types.NewFieldType(mysql.TypeMediumBlob)
		$$ = tp
	}
|	"LONGBLOB"
	{
		tp := types.NewFieldType(mysql.TypeLongBlob)
		$$ = tp
	}
|	"LONG" "VARBINARY"
	{
		tp := types.NewFieldType(mysql.TypeMediumBlob)
		$$ = tp
	}

TextType:
	"TINYTEXT"
	{
		tp := types.NewFieldType(mysql.TypeTinyBlob)
		$$ = tp
	}
|	"TEXT" OptFieldLen
	{
		tp := types.NewFieldType(mysql.TypeBlob)
		tp.SetFlen($2.(int))
		$$ = tp
	}
|	"MEDIUMTEXT"
	{
		tp := types.NewFieldType(mysql.TypeMediumBlob)
		$$ = tp
	}
|	"LONGTEXT"
	{
		tp := types.NewFieldType(mysql.TypeLongBlob)
		$$ = tp
	}

OptCharsetWithOptBinary:
	OptBinary
|	"ASCII"
	{
		$$ = &ast.OptBinary{
			IsBinary: false,
			Charset:  charset.CharsetLatin1,
		}
	}
|	"UNICODE"
	{
		cs, err := charset.GetCharsetInfo("ucs2")
		if err != nil {
			yylex.AppendError(ErrUnknownCharacterSet.GenWithStackByArgs("ucs2"))
			return 1
		}
		$$ = &ast.OptBinary{
			IsBinary: false,
			Charset:  cs.Name,
		}
	}
|	"BYTE"
	{
		$$ = &ast.OptBinary{
			IsBinary: false,
			Charset:  "",
		}
	}

DateAndTimeType:
	"DATE"
	{
		tp := types.NewFieldType(mysql.TypeDate)
		$$ = tp
	}
|	"DATETIME" OptFieldLen
	{
		tp := types.NewFieldType(mysql.TypeDatetime)
		tp.SetFlen(mysql.MaxDatetimeWidthNoFsp)
		tp.SetDecimal($2.(int))
		if tp.GetDecimal() > 0 {
			tp.SetFlen(tp.GetFlen() + 1 + tp.GetDecimal())
		}
		$$ = tp
	}
|	"TIMESTAMP" OptFieldLen
	{
		tp := types.NewFieldType(mysql.TypeTimestamp)
		tp.SetFlen(mysql.MaxDatetimeWidthNoFsp)
		tp.SetDecimal($2.(int))
		if tp.GetDecimal() > 0 {
			tp.SetFlen(tp.GetFlen() + 1 + tp.GetDecimal())
		}
		$$ = tp
	}
|	"TIME" OptFieldLen
	{
		tp := types.NewFieldType(mysql.TypeDuration)
		tp.SetFlen(mysql.MaxDurationWidthNoFsp)
		tp.SetDecimal($2.(int))
		if tp.GetDecimal() > 0 {
			tp.SetFlen(tp.GetFlen() + 1 + tp.GetDecimal())
		}
		$$ = tp
	}
|	Year OptFieldLen FieldOpts
	{
		tp := types.NewFieldType(mysql.TypeYear)
		tp.SetFlen($2.(int))
		if tp.GetFlen() != types.UnspecifiedLength && tp.GetFlen() != 4 {
			yylex.AppendError(ErrInvalidYearColumnLength.GenWithStackByArgs())
			return -1
		}
		$$ = tp
	}

FieldLen:
	'(' LengthNum ')'
	{
		$$ = int($2.(uint64))
	}

OptFieldLen:
	{
		$$ = types.UnspecifiedLength
	}
|	FieldLen

FieldOpt:
	"UNSIGNED"
	{
		$$ = &ast.TypeOpt{IsUnsigned: true}
	}
|	"SIGNED"
	{
		$$ = &ast.TypeOpt{IsUnsigned: false}
	}
|	"ZEROFILL"
	{
		$$ = &ast.TypeOpt{IsZerofill: true, IsUnsigned: true}
	}

FieldOpts:
	{
		$$ = []*ast.TypeOpt{}
	}
|	FieldOpts FieldOpt
	{
		$$ = append($1.([]*ast.TypeOpt), $2.(*ast.TypeOpt))
	}

FloatOpt:
	{
		$$ = &ast.FloatOpt{Flen: types.UnspecifiedLength, Decimal: types.UnspecifiedLength}
	}
|	FieldLen
	{
		$$ = &ast.FloatOpt{Flen: $1.(int), Decimal: types.UnspecifiedLength}
	}
|	Precision

Precision:
	'(' LengthNum ',' LengthNum ')'
	{
		$$ = &ast.FloatOpt{Flen: int($2.(uint64)), Decimal: int($4.(uint64))}
	}

OptBinMod:
	{
		$$ = false
	}
|	"BINARY"
	{
		$$ = true
	}

OptBinary:
	{
		$$ = &ast.OptBinary{
			IsBinary: false,
			Charset:  "",
		}
	}
|	"BINARY" OptCharset
	{
		$$ = &ast.OptBinary{
			IsBinary: true,
			Charset:  $2,
		}
	}
|	CharsetKw CharsetName OptBinMod
	{
		$$ = &ast.OptBinary{
			IsBinary: $3.(bool),
			Charset:  $2,
		}
	}

OptCharset:
	{
		$$ = ""
	}
|	CharsetKw CharsetName
	{
		$$ = $2
	}

CharsetKw:
	"CHARACTER" "SET"
|	"CHARSET"
|	"CHAR" "SET"

OptCollate:
	{
		$$ = ""
	}
|	"COLLATE" CollationName
	{
		$$ = $2
	}

StringList:
	stringLit
	{
		$$ = []string{$1}
	}
|	StringList ',' stringLit
	{
		$$ = append($1.([]string), $3)
	}

TextString:
	stringLit
	{
		$$ = &ast.TextString{Value: $1}
	}
|	hexLit
	{
		$$ = &ast.TextString{Value: $1.(ast.BinaryLiteral).ToString(), IsBinaryLiteral: true}
	}
|	bitLit
	{
		$$ = &ast.TextString{Value: $1.(ast.BinaryLiteral).ToString(), IsBinaryLiteral: true}
	}

TextStringList:
	TextString
	{
		$$ = []*ast.TextString{$1.(*ast.TextString)}
	}
|	TextStringList ',' TextString
	{
		$$ = append($1.([]*ast.TextString), $3.(*ast.TextString))
	}

StringName:
	stringLit
|	Identifier

StringNameOrBRIEOptionKeyword:
	StringName
|	"IGNORE"
|	"REPLACE"

/***********************************************************************************
 * Update Statement
 * See https://dev.mysql.com/doc/refman/5.7/en/update.html
 ***********************************************************************************/
UpdateStmt:
	UpdateStmtNoWith
|	WithClause UpdateStmtNoWith
	{
		u := $2.(*ast.UpdateStmt)
		u.With = $1.(*ast.WithClause)
		$$ = u
	}

UpdateStmtNoWith:
	"UPDATE" TableOptimizerHintsOpt PriorityOpt IgnoreOptional TableRef "SET" AssignmentList WhereClauseOptional OrderByOptional LimitClause
	{
		var refs *ast.Join
		if x, ok := $5.(*ast.Join); ok {
			refs = x
		} else {
			refs = &ast.Join{Left: $5.(ast.ResultSetNode)}
		}
		st := &ast.UpdateStmt{
			Priority:  $3.(mysql.PriorityEnum),
			TableRefs: &ast.TableRefsClause{TableRefs: refs},
			List:      $7.([]*ast.Assignment),
			IgnoreErr: $4.(bool),
		}
		if $2 != nil {
			st.TableHints = $2.([]*ast.TableOptimizerHint)
		}
		if $8 != nil {
			st.Where = $8.(ast.ExprNode)
		}
		if $9 != nil {
			st.Order = $9.(*ast.OrderByClause)
		}
		if $10 != nil {
			st.Limit = $10.(*ast.Limit)
		}
		$$ = st
	}
|	"UPDATE" TableOptimizerHintsOpt PriorityOpt IgnoreOptional TableRefs "SET" AssignmentList WhereClauseOptional
	{
		st := &ast.UpdateStmt{
			Priority:  $3.(mysql.PriorityEnum),
			TableRefs: &ast.TableRefsClause{TableRefs: $5.(*ast.Join)},
			List:      $7.([]*ast.Assignment),
			IgnoreErr: $4.(bool),
		}
		if $2 != nil {
			st.TableHints = $2.([]*ast.TableOptimizerHint)
		}
		if $8 != nil {
			st.Where = $8.(ast.ExprNode)
		}
		$$ = st
	}

UseStmt:
	"USE" DBName
	{
		$$ = &ast.UseStmt{DBName: $2}
	}

WhereClause:
	"WHERE" Expression
	{
		$$ = $2
	}

WhereClauseOptional:
	{
		$$ = nil
	}
|	WhereClause

CommaOpt:
	{}
|	','
	{}

/************************************************************************************
 *  Account Management Statements
 *  https://dev.mysql.com/doc/refman/5.7/en/account-management-sql.html
 ************************************************************************************/
CreateUserStmt:
	"CREATE" "USER" IfNotExists UserSpecList RequireClauseOpt ConnectionOptions PasswordOrLockOptions
	{
		// See https://dev.mysql.com/doc/refman/5.7/en/create-user.html
		$$ = &ast.CreateUserStmt{
			IsCreateRole:          false,
			IfNotExists:           $3.(bool),
			Specs:                 $4.([]*ast.UserSpec),
			TLSOptions:            $5.([]*ast.TLSOption),
			ResourceOptions:       $6.([]*ast.ResourceOption),
			PasswordOrLockOptions: $7.([]*ast.PasswordOrLockOption),
		}
	}

CreateRoleStmt:
	"CREATE" "ROLE" IfNotExists RoleSpecList
	{
		// See https://dev.mysql.com/doc/refman/8.0/en/create-role.html
		$$ = &ast.CreateUserStmt{
			IsCreateRole: true,
			IfNotExists:  $3.(bool),
			Specs:        $4.([]*ast.UserSpec),
		}
	}

/* See http://dev.mysql.com/doc/refman/5.7/en/alter-user.html */
AlterUserStmt:
	"ALTER" "USER" IfExists UserSpecList RequireClauseOpt ConnectionOptions PasswordOrLockOptions
	{
		$$ = &ast.AlterUserStmt{
			IfExists:              $3.(bool),
			Specs:                 $4.([]*ast.UserSpec),
			TLSOptions:            $5.([]*ast.TLSOption),
			ResourceOptions:       $6.([]*ast.ResourceOption),
			PasswordOrLockOptions: $7.([]*ast.PasswordOrLockOption),
		}
	}
|	"ALTER" "USER" IfExists "USER" '(' ')' "IDENTIFIED" "BY" AuthString
	{
		auth := &ast.AuthOption{
			AuthString:   $9,
			ByAuthString: true,
		}
		$$ = &ast.AlterUserStmt{
			IfExists:    $3.(bool),
			CurrentAuth: auth,
		}
	}

/* See https://dev.mysql.com/doc/refman/8.0/en/alter-instance.html */
AlterInstanceStmt:
	"ALTER" "INSTANCE" InstanceOption
	{
		$$ = $3.(*ast.AlterInstanceStmt)
	}

InstanceOption:
	"RELOAD" "TLS"
	{
		$$ = &ast.AlterInstanceStmt{
			ReloadTLS: true,
		}
	}
|	"RELOAD" "TLS" "NO" "ROLLBACK" "ON" "ERROR"
	{
		$$ = &ast.AlterInstanceStmt{
			ReloadTLS:         true,
			NoRollbackOnError: true,
		}
	}

UserSpec:
	Username AuthOption
	{
		userSpec := &ast.UserSpec{
			User: $1.(*auth.UserIdentity),
		}
		if $2 != nil {
			userSpec.AuthOpt = $2.(*ast.AuthOption)
		}
		$$ = userSpec
	}

UserSpecList:
	UserSpec
	{
		$$ = []*ast.UserSpec{$1.(*ast.UserSpec)}
	}
|	UserSpecList ',' UserSpec
	{
		$$ = append($1.([]*ast.UserSpec), $3.(*ast.UserSpec))
	}

ConnectionOptions:
	{
		l := []*ast.ResourceOption{}
		$$ = l
	}
|	"WITH" ConnectionOptionList
	{
		$$ = $2
		yylex.AppendError(yylex.Errorf("TiDB does not support WITH ConnectionOptions now, they would be parsed but ignored."))
		parser.lastErrorAsWarn()
	}

ConnectionOptionList:
	ConnectionOption
	{
		$$ = []*ast.ResourceOption{$1.(*ast.ResourceOption)}
	}
|	ConnectionOptionList ConnectionOption
	{
		l := $1.([]*ast.ResourceOption)
		l = append(l, $2.(*ast.ResourceOption))
		$$ = l
	}

ConnectionOption:
	"MAX_QUERIES_PER_HOUR" Int64Num
	{
		$$ = &ast.ResourceOption{
			Type:  ast.MaxQueriesPerHour,
			Count: $2.(int64),
		}
	}
|	"MAX_UPDATES_PER_HOUR" Int64Num
	{
		$$ = &ast.ResourceOption{
			Type:  ast.MaxUpdatesPerHour,
			Count: $2.(int64),
		}
	}
|	"MAX_CONNECTIONS_PER_HOUR" Int64Num
	{
		$$ = &ast.ResourceOption{
			Type:  ast.MaxConnectionsPerHour,
			Count: $2.(int64),
		}
	}
|	"MAX_USER_CONNECTIONS" Int64Num
	{
		$$ = &ast.ResourceOption{
			Type:  ast.MaxUserConnections,
			Count: $2.(int64),
		}
	}

RequireClauseOpt:
	{
		$$ = []*ast.TLSOption{}
	}
|	RequireClause

RequireClause:
	"REQUIRE" "NONE"
	{
		t := &ast.TLSOption{
			Type: ast.TlsNone,
		}
		$$ = []*ast.TLSOption{t}
	}
|	"REQUIRE" "SSL"
	{
		t := &ast.TLSOption{
			Type: ast.Ssl,
		}
		$$ = []*ast.TLSOption{t}
	}
|	"REQUIRE" "X509"
	{
		t := &ast.TLSOption{
			Type: ast.X509,
		}
		$$ = []*ast.TLSOption{t}
	}
|	"REQUIRE" RequireList
	{
		$$ = $2
	}

RequireList:
	RequireListElement
	{
		$$ = []*ast.TLSOption{$1.(*ast.TLSOption)}
	}
|	RequireList "AND" RequireListElement
	{
		l := $1.([]*ast.TLSOption)
		l = append(l, $3.(*ast.TLSOption))
		$$ = l
	}
|	RequireList RequireListElement
	{
		l := $1.([]*ast.TLSOption)
		l = append(l, $2.(*ast.TLSOption))
		$$ = l
	}

RequireListElement:
	"ISSUER" stringLit
	{
		$$ = &ast.TLSOption{
			Type:  ast.Issuer,
			Value: $2,
		}
	}
|	"SUBJECT" stringLit
	{
		$$ = &ast.TLSOption{
			Type:  ast.Subject,
			Value: $2,
		}
	}
|	"CIPHER" stringLit
	{
		$$ = &ast.TLSOption{
			Type:  ast.Cipher,
			Value: $2,
		}
	}
|	"SAN" stringLit
	{
		$$ = &ast.TLSOption{
			Type:  ast.SAN,
			Value: $2,
		}
	}

PasswordOrLockOptions:
	{
		l := []*ast.PasswordOrLockOption{}
		$$ = l
	}
|	PasswordOrLockOptionList
	{
		$$ = $1
		yylex.AppendError(yylex.Errorf("TiDB does not support PASSWORD EXPIRE and ACCOUNT LOCK now, they would be parsed but ignored."))
		parser.lastErrorAsWarn()
	}

PasswordOrLockOptionList:
	PasswordOrLockOption
	{
		$$ = []*ast.PasswordOrLockOption{$1.(*ast.PasswordOrLockOption)}
	}
|	PasswordOrLockOptionList PasswordOrLockOption
	{
		l := $1.([]*ast.PasswordOrLockOption)
		l = append(l, $2.(*ast.PasswordOrLockOption))
		$$ = l
	}

PasswordOrLockOption:
	"ACCOUNT" "UNLOCK"
	{
		$$ = &ast.PasswordOrLockOption{
			Type: ast.Unlock,
		}
	}
|	"ACCOUNT" "LOCK"
	{
		$$ = &ast.PasswordOrLockOption{
			Type: ast.Lock,
		}
	}
|	PasswordExpire
	{
		$$ = &ast.PasswordOrLockOption{
			Type: ast.PasswordExpire,
		}
	}
|	PasswordExpire "INTERVAL" Int64Num "DAY"
	{
		$$ = &ast.PasswordOrLockOption{
			Type:  ast.PasswordExpireInterval,
			Count: $3.(int64),
		}
	}
|	PasswordExpire "NEVER"
	{
		$$ = &ast.PasswordOrLockOption{
			Type: ast.PasswordExpireNever,
		}
	}
|	PasswordExpire "DEFAULT"
	{
		$$ = &ast.PasswordOrLockOption{
			Type: ast.PasswordExpireDefault,
		}
	}

PasswordExpire:
	"PASSWORD" "EXPIRE" ClearPasswordExpireOptions
	{
		$$ = nil
	}

ClearPasswordExpireOptions:
	{
		$$ = nil
	}

AuthOption:
	{
		$$ = nil
	}
|	"IDENTIFIED" "BY" AuthString
	{
		$$ = &ast.AuthOption{
			AuthString:   $3,
			ByAuthString: true,
		}
	}
|	"IDENTIFIED" "WITH" AuthPlugin
	{
		$$ = &ast.AuthOption{
			AuthPlugin: $3,
		}
	}
|	"IDENTIFIED" "WITH" AuthPlugin "BY" AuthString
	{
		$$ = &ast.AuthOption{
			AuthPlugin:   $3,
			AuthString:   $5,
			ByAuthString: true,
		}
	}
|	"IDENTIFIED" "WITH" AuthPlugin "AS" HashString
	{
		$$ = &ast.AuthOption{
			AuthPlugin: $3,
			HashString: $5,
		}
	}
|	"IDENTIFIED" "BY" "PASSWORD" HashString
	{
		$$ = &ast.AuthOption{
			AuthPlugin: mysql.AuthNativePassword,
			HashString: $4,
		}
	}

AuthPlugin:
	StringName

HashString:
	stringLit
|	hexLit
	{
		$$ = $1.(ast.BinaryLiteral).ToString()
	}

RoleSpec:
	Rolename
	{
		role := $1.(*auth.RoleIdentity)
		roleSpec := &ast.UserSpec{
			User: &auth.UserIdentity{
				Username: role.Username,
				Hostname: role.Hostname,
			},
			IsRole: true,
		}
		$$ = roleSpec
	}

RoleSpecList:
	RoleSpec
	{
		$$ = []*ast.UserSpec{$1.(*ast.UserSpec)}
	}
|	RoleSpecList ',' RoleSpec
	{
		$$ = append($1.([]*ast.UserSpec), $3.(*ast.UserSpec))
	}

BindableStmt:
	SetOprStmt
|	SelectStmt
|	SelectStmtWithClause
|	SubSelect
	{
		var sel ast.StmtNode
		switch x := $1.(*ast.SubqueryExpr).Query.(type) {
		case *ast.SelectStmt:
			x.IsInBraces = true
			sel = x
		case *ast.SetOprStmt:
			x.IsInBraces = true
			sel = x
		}
		$$ = sel
	}
|	UpdateStmt
|	DeleteWithoutUsingStmt
|	InsertIntoStmt
|	ReplaceIntoStmt

/*******************************************************************
 *
 *  Create Binding Statement
 *
 *  Example:
 *      CREATE GLOBAL BINDING FOR select Col1,Col2 from table USING select Col1,Col2 from table use index(Col1)
 *******************************************************************/
CreateBindingStmt:
	"CREATE" GlobalScope "BINDING" "FOR" BindableStmt "USING" BindableStmt
	{
		startOffset := parser.startOffset(&yyS[yypt-2])
		endOffset := parser.startOffset(&yyS[yypt-1])
		originStmt := $5
		originStmt.SetText(parser.lexer.client, strings.TrimSpace(parser.src[startOffset:endOffset]))

		startOffset = parser.startOffset(&yyS[yypt])
		hintedStmt := $7
		hintedStmt.SetText(parser.lexer.client, strings.TrimSpace(parser.src[startOffset:]))

		x := &ast.CreateBindingStmt{
			OriginNode:  originStmt,
			HintedNode:  hintedStmt,
			GlobalScope: $2.(bool),
		}

		$$ = x
	}

/*******************************************************************
 *
 *  Drop Binding Statement
 *
 *  Example:
 *      DROP GLOBAL BINDING FOR select Col1,Col2 from table
 *******************************************************************/
DropBindingStmt:
	"DROP" GlobalScope "BINDING" "FOR" BindableStmt
	{
		startOffset := parser.startOffset(&yyS[yypt])
		originStmt := $5
		originStmt.SetText(parser.lexer.client, strings.TrimSpace(parser.src[startOffset:]))

		x := &ast.DropBindingStmt{
			OriginNode:  originStmt,
			GlobalScope: $2.(bool),
		}

		$$ = x
	}
|	"DROP" GlobalScope "BINDING" "FOR" BindableStmt "USING" BindableStmt
	{
		startOffset := parser.startOffset(&yyS[yypt-2])
		endOffset := parser.startOffset(&yyS[yypt-1])
		originStmt := $5
		originStmt.SetText(parser.lexer.client, strings.TrimSpace(parser.src[startOffset:endOffset]))

		startOffset = parser.startOffset(&yyS[yypt])
		hintedStmt := $7
		hintedStmt.SetText(parser.lexer.client, strings.TrimSpace(parser.src[startOffset:]))

		x := &ast.DropBindingStmt{
			OriginNode:  originStmt,
			HintedNode:  hintedStmt,
			GlobalScope: $2.(bool),
		}

		$$ = x
	}

SetBindingStmt:
	"SET" "BINDING" BindingStatusType "FOR" BindableStmt
	{
		startOffset := parser.startOffset(&yyS[yypt])
		originStmt := $5
		originStmt.SetText(parser.lexer.client, strings.TrimSpace(parser.src[startOffset:]))

		x := &ast.SetBindingStmt{
			BindingStatusType: $3.(ast.BindingStatusType),
			OriginNode:        originStmt,
		}

		$$ = x
	}
|	"SET" "BINDING" BindingStatusType "FOR" BindableStmt "USING" BindableStmt
	{
		startOffset := parser.startOffset(&yyS[yypt-2])
		endOffset := parser.startOffset(&yyS[yypt-1])
		originStmt := $5
		originStmt.SetText(parser.lexer.client, strings.TrimSpace(parser.src[startOffset:endOffset]))

		startOffset = parser.startOffset(&yyS[yypt])
		hintedStmt := $7
		hintedStmt.SetText(parser.lexer.client, strings.TrimSpace(parser.src[startOffset:]))

		x := &ast.SetBindingStmt{
			BindingStatusType: $3.(ast.BindingStatusType),
			OriginNode:        originStmt,
			HintedNode:        hintedStmt,
		}

		$$ = x
	}

/*************************************************************************************
 * Grant statement
 * See https://dev.mysql.com/doc/refman/5.7/en/grant.html
 *************************************************************************************/
GrantStmt:
	"GRANT" RoleOrPrivElemList "ON" ObjectType PrivLevel "TO" UserSpecList RequireClauseOpt WithGrantOptionOpt
	{
		p, err := convertToPriv($2.([]*ast.RoleOrPriv))
		if err != nil {
			yylex.AppendError(err)
			return 1
		}
		$$ = &ast.GrantStmt{
			Privs:      p,
			ObjectType: $4.(ast.ObjectTypeType),
			Level:      $5.(*ast.GrantLevel),
			Users:      $7.([]*ast.UserSpec),
			TLSOptions: $8.([]*ast.TLSOption),
			WithGrant:  $9.(bool),
		}
	}

GrantProxyStmt:
	"GRANT" "PROXY" "ON" Username "TO" UsernameList WithGrantOptionOpt
	{
		$$ = &ast.GrantProxyStmt{
			LocalUser:     $4.(*auth.UserIdentity),
			ExternalUsers: $6.([]*auth.UserIdentity),
			WithGrant:     $7.(bool),
		}
	}

GrantRoleStmt:
	"GRANT" RoleOrPrivElemList "TO" UsernameList
	{
		r, err := convertToRole($2.([]*ast.RoleOrPriv))
		if err != nil {
			yylex.AppendError(err)
			return 1
		}
		$$ = &ast.GrantRoleStmt{
			Roles: r,
			Users: $4.([]*auth.UserIdentity),
		}
	}

WithGrantOptionOpt:
	{
		$$ = false
	}
|	"WITH" "GRANT" "OPTION"
	{
		$$ = true
	}
|	"WITH" "MAX_QUERIES_PER_HOUR" NUM
	{
		$$ = false
	}
|	"WITH" "MAX_UPDATES_PER_HOUR" NUM
	{
		$$ = false
	}
|	"WITH" "MAX_CONNECTIONS_PER_HOUR" NUM
	{
		$$ = false
	}
|	"WITH" "MAX_USER_CONNECTIONS" NUM
	{
		$$ = false
	}

ExtendedPriv:
	identifier
	{
		$$ = []string{$1}
	}
|	ExtendedPriv identifier
	{
		$$ = append($1.([]string), $2)
	}

RoleOrPrivElem:
	PrivElem
	{
		$$ = &ast.RoleOrPriv{
			Node: $1,
		}
	}
|	RolenameWithoutIdent
	{
		$$ = &ast.RoleOrPriv{
			Node: $1,
		}
	}
|	ExtendedPriv
	{
		$$ = &ast.RoleOrPriv{
			Symbols: strings.Join($1.([]string), " "),
		}
	}
|	"LOAD" "FROM" "S3"
	{
		$$ = &ast.RoleOrPriv{
			Symbols: "LOAD FROM S3",
		}
	}
|	"SELECT" "INTO" "S3"
	{
		$$ = &ast.RoleOrPriv{
			Symbols: "SELECT INTO S3",
		}
	}

RoleOrPrivElemList:
	RoleOrPrivElem
	{
		$$ = []*ast.RoleOrPriv{$1.(*ast.RoleOrPriv)}
	}
|	RoleOrPrivElemList ',' RoleOrPrivElem
	{
		$$ = append($1.([]*ast.RoleOrPriv), $3.(*ast.RoleOrPriv))
	}

PrivElem:
	PrivType
	{
		$$ = &ast.PrivElem{
			Priv: $1.(mysql.PrivilegeType),
		}
	}
|	PrivType '(' ColumnNameList ')'
	{
		$$ = &ast.PrivElem{
			Priv: $1.(mysql.PrivilegeType),
			Cols: $3.([]*ast.ColumnName),
		}
	}

PrivType:
	"ALL"
	{
		$$ = mysql.AllPriv
	}
|	"ALL" "PRIVILEGES"
	{
		$$ = mysql.AllPriv
	}
|	"ALTER"
	{
		$$ = mysql.AlterPriv
	}
|	"CREATE"
	{
		$$ = mysql.CreatePriv
	}
|	"CREATE" "USER"
	{
		$$ = mysql.CreateUserPriv
	}
|	"CREATE" "TABLESPACE"
	{
		$$ = mysql.CreateTablespacePriv
	}
|	"TRIGGER"
	{
		$$ = mysql.TriggerPriv
	}
|	"DELETE"
	{
		$$ = mysql.DeletePriv
	}
|	"DROP"
	{
		$$ = mysql.DropPriv
	}
|	"PROCESS"
	{
		$$ = mysql.ProcessPriv
	}
|	"EXECUTE"
	{
		$$ = mysql.ExecutePriv
	}
|	"INDEX"
	{
		$$ = mysql.IndexPriv
	}
|	"INSERT"
	{
		$$ = mysql.InsertPriv
	}
|	"SELECT"
	{
		$$ = mysql.SelectPriv
	}
|	"SUPER"
	{
		$$ = mysql.SuperPriv
	}
|	"SHOW" "DATABASES"
	{
		$$ = mysql.ShowDBPriv
	}
|	"UPDATE"
	{
		$$ = mysql.UpdatePriv
	}
|	"GRANT" "OPTION"
	{
		$$ = mysql.GrantPriv
	}
|	"REFERENCES"
	{
		$$ = mysql.ReferencesPriv
	}
|	"REPLICATION" "SLAVE"
	{
		$$ = mysql.ReplicationSlavePriv
	}
|	"REPLICATION" "CLIENT"
	{
		$$ = mysql.ReplicationClientPriv
	}
|	"USAGE"
	{
		$$ = mysql.UsagePriv
	}
|	"RELOAD"
	{
		$$ = mysql.ReloadPriv
	}
|	"FILE"
	{
		$$ = mysql.FilePriv
	}
|	"CONFIG"
	{
		$$ = mysql.ConfigPriv
	}
|	"CREATE" "TEMPORARY" "TABLES"
	{
		$$ = mysql.CreateTMPTablePriv
	}
|	"LOCK" "TABLES"
	{
		$$ = mysql.LockTablesPriv
	}
|	"CREATE" "VIEW"
	{
		$$ = mysql.CreateViewPriv
	}
|	"SHOW" "VIEW"
	{
		$$ = mysql.ShowViewPriv
	}
|	"CREATE" "ROLE"
	{
		$$ = mysql.CreateRolePriv
	}
|	"DROP" "ROLE"
	{
		$$ = mysql.DropRolePriv
	}
|	"CREATE" "ROUTINE"
	{
		$$ = mysql.CreateRoutinePriv
	}
|	"ALTER" "ROUTINE"
	{
		$$ = mysql.AlterRoutinePriv
	}
|	"EVENT"
	{
		$$ = mysql.EventPriv
	}
|	"SHUTDOWN"
	{
		$$ = mysql.ShutdownPriv
	}

ObjectType:
	%prec lowerThanFunction
	{
		$$ = ast.ObjectTypeNone
	}
|	"TABLE"
	{
		$$ = ast.ObjectTypeTable
	}
|	"FUNCTION"
	{
		$$ = ast.ObjectTypeFunction
	}
|	"PROCEDURE"
	{
		$$ = ast.ObjectTypeProcedure
	}

PrivLevel:
	'*'
	{
		$$ = &ast.GrantLevel{
			Level: ast.GrantLevelDB,
		}
	}
|	'*' '.' '*'
	{
		$$ = &ast.GrantLevel{
			Level: ast.GrantLevelGlobal,
		}
	}
|	Identifier '.' '*'
	{
		$$ = &ast.GrantLevel{
			Level:  ast.GrantLevelDB,
			DBName: $1,
		}
	}
|	Identifier '.' Identifier
	{
		$$ = &ast.GrantLevel{
			Level:     ast.GrantLevelTable,
			DBName:    $1,
			TableName: $3,
		}
	}
|	Identifier
	{
		$$ = &ast.GrantLevel{
			Level:     ast.GrantLevelTable,
			TableName: $1,
		}
	}

/**************************************RevokeStmt*******************************************
 * See https://dev.mysql.com/doc/refman/5.7/en/revoke.html
 *******************************************************************************************/
RevokeStmt:
	"REVOKE" RoleOrPrivElemList "ON" ObjectType PrivLevel "FROM" UserSpecList
	{
		p, err := convertToPriv($2.([]*ast.RoleOrPriv))
		if err != nil {
			yylex.AppendError(err)
			return 1
		}
		$$ = &ast.RevokeStmt{
			Privs:      p,
			ObjectType: $4.(ast.ObjectTypeType),
			Level:      $5.(*ast.GrantLevel),
			Users:      $7.([]*ast.UserSpec),
		}
	}

RevokeRoleStmt:
	"REVOKE" RoleOrPrivElemList "FROM" UsernameList
	{
		// MySQL has special syntax for REVOKE ALL [PRIVILEGES], GRANT OPTION
		// which uses the RevokeRoleStmt syntax but is of type RevokeStmt.
		// It is documented at https://dev.mysql.com/doc/refman/5.7/en/revoke.html
		// as the "second syntax" for REVOKE. It is only valid if *both*
		// ALL PRIVILEGES + GRANT OPTION are specified in that order.
		if isRevokeAllGrant($2.([]*ast.RoleOrPriv)) {
			var users []*ast.UserSpec
			for _, u := range $4.([]*auth.UserIdentity) {
				users = append(users, &ast.UserSpec{
					User: u,
				})
			}
			$$ = &ast.RevokeStmt{
				Privs:      []*ast.PrivElem{{Priv: mysql.AllPriv}, {Priv: mysql.GrantPriv}},
				ObjectType: ast.ObjectTypeNone,
				Level:      &ast.GrantLevel{Level: ast.GrantLevelGlobal},
				Users:      users,
			}
		} else {
			r, err := convertToRole($2.([]*ast.RoleOrPriv))
			if err != nil {
				yylex.AppendError(err)
				return 1
			}
			$$ = &ast.RevokeRoleStmt{
				Roles: r,
				Users: $4.([]*auth.UserIdentity),
			}
		}
	}

/**************************************LoadDataStmt*****************************************
 * See https://dev.mysql.com/doc/refman/5.7/en/load-data.html
 *******************************************************************************************/
LoadDataStmt:
	"LOAD" "DATA" LocalOpt "INFILE" stringLit DuplicateOpt "INTO" "TABLE" TableName CharsetOpt Fields Lines IgnoreLines ColumnNameOrUserVarListOptWithBrackets LoadDataSetSpecOpt
	{
		x := &ast.LoadDataStmt{
			Path:               $5,
			OnDuplicate:        $6.(ast.OnDuplicateKeyHandlingType),
			Table:              $9.(*ast.TableName),
			ColumnsAndUserVars: $14.([]*ast.ColumnNameOrUserVar),
			IgnoreLines:        $13.(uint64),
		}
		if $3 != nil {
			x.IsLocal = true
			// See https://dev.mysql.com/doc/refman/5.7/en/load-data.html#load-data-duplicate-key-handling
			// If you do not specify IGNORE or REPLACE modifier , then we set default behavior to IGNORE when LOCAL modifier is specified
			if x.OnDuplicate == ast.OnDuplicateKeyHandlingError {
				x.OnDuplicate = ast.OnDuplicateKeyHandlingIgnore
			}
		}
		if $11 != nil {
			x.FieldsInfo = $11.(*ast.FieldsClause)
		}
		if $12 != nil {
			x.LinesInfo = $12.(*ast.LinesClause)
		}
		if $15 != nil {
			x.ColumnAssignments = $15.([]*ast.Assignment)
		}
		columns := []*ast.ColumnName{}
		for _, v := range x.ColumnsAndUserVars {
			if v.ColumnName != nil {
				columns = append(columns, v.ColumnName)
			}
		}
		x.Columns = columns

		$$ = x
	}

IgnoreLines:
	{
		$$ = uint64(0)
	}
|	"IGNORE" NUM "LINES"
	{
		$$ = getUint64FromNUM($2)
	}

CharsetOpt:
	{}
|	"CHARACTER" "SET" CharsetName

LocalOpt:
	{
		$$ = nil
	}
|	"LOCAL"
	{
		$$ = $1
	}

Fields:
	{
		escape := "\\"
		$$ = &ast.FieldsClause{
			Terminated: "\t",
			Escaped:    escape[0],
		}
	}
|	FieldsOrColumns FieldItemList
	{
		fieldsClause := &ast.FieldsClause{
			Terminated: "\t",
			Escaped:    []byte("\\")[0],
		}
		fieldItems := $2.([]*ast.FieldItem)
		for _, item := range fieldItems {
			switch item.Type {
			case ast.Terminated:
				fieldsClause.Terminated = item.Value
			case ast.Enclosed:
				var enclosed byte
				if len(item.Value) > 0 {
					enclosed = item.Value[0]
				}
				fieldsClause.Enclosed = enclosed
				if item.OptEnclosed {
					fieldsClause.OptEnclosed = true
				}
			case ast.Escaped:
				var escaped byte
				if len(item.Value) > 0 {
					escaped = item.Value[0]
				}
				fieldsClause.Escaped = escaped
			}
		}
		$$ = fieldsClause
	}

FieldsOrColumns:
	"FIELDS"
|	"COLUMNS"

FieldItemList:
	FieldItemList FieldItem
	{
		fieldItems := $1.([]*ast.FieldItem)
		$$ = append(fieldItems, $2.(*ast.FieldItem))
	}
|	FieldItem
	{
		fieldItems := make([]*ast.FieldItem, 1, 1)
		fieldItems[0] = $1.(*ast.FieldItem)
		$$ = fieldItems
	}

FieldItem:
	"TERMINATED" "BY" FieldTerminator
	{
		$$ = &ast.FieldItem{
			Type:  ast.Terminated,
			Value: $3,
		}
	}
|	"OPTIONALLY" "ENCLOSED" "BY" FieldTerminator
	{
		str := $4
		if str != "\\" && len(str) > 1 {
			yylex.AppendError(ErrWrongFieldTerminators.GenWithStackByArgs())
			return 1
		}
		$$ = &ast.FieldItem{
			Type:        ast.Enclosed,
			Value:       str,
			OptEnclosed: true,
		}
	}
|	"ENCLOSED" "BY" FieldTerminator
	{
		str := $3
		if str != "\\" && len(str) > 1 {
			yylex.AppendError(ErrWrongFieldTerminators.GenWithStackByArgs())
			return 1
		}
		$$ = &ast.FieldItem{
			Type:  ast.Enclosed,
			Value: str,
		}
	}
|	"ESCAPED" "BY" FieldTerminator
	{
		str := $3
		if str != "\\" && len(str) > 1 {
			yylex.AppendError(ErrWrongFieldTerminators.GenWithStackByArgs())
			return 1
		}
		$$ = &ast.FieldItem{
			Type:  ast.Escaped,
			Value: str,
		}
	}

FieldTerminator:
	stringLit
|	hexLit
	{
		$$ = $1.(ast.BinaryLiteral).ToString()
	}
|	bitLit
	{
		$$ = $1.(ast.BinaryLiteral).ToString()
	}

Lines:
	{
		$$ = &ast.LinesClause{Terminated: "\n"}
	}
|	"LINES" Starting LinesTerminated
	{
		$$ = &ast.LinesClause{Starting: $2, Terminated: $3}
	}

Starting:
	{
		$$ = ""
	}
|	"STARTING" "BY" FieldTerminator
	{
		$$ = $3
	}

LinesTerminated:
	{
		$$ = "\n"
	}
|	"TERMINATED" "BY" FieldTerminator
	{
		$$ = $3
	}

LoadDataSetSpecOpt:
	{
		$$ = nil
	}
|	"SET" LoadDataSetList
	{
		$$ = $2
	}

LoadDataSetList:
	LoadDataSetList ',' LoadDataSetItem
	{
		l := $1.([]*ast.Assignment)
		$$ = append(l, $3.(*ast.Assignment))
	}
|	LoadDataSetItem
	{
		$$ = []*ast.Assignment{$1.(*ast.Assignment)}
	}

LoadDataSetItem:
	SimpleIdent "=" ExprOrDefault
	{
		$$ = &ast.Assignment{
			Column: $1.(*ast.ColumnNameExpr).Name,
			Expr:   $3,
		}
	}

/*********************************************************************
 * Lock/Unlock Tables
 * See http://dev.mysql.com/doc/refman/5.7/en/lock-tables.html
 * All the statement leaves empty. This is used to prevent mysqldump error.
 *********************************************************************/
UnlockTablesStmt:
	"UNLOCK" TablesTerminalSym
	{
		$$ = &ast.UnlockTablesStmt{}
	}

LockTablesStmt:
	"LOCK" TablesTerminalSym TableLockList
	{
		$$ = &ast.LockTablesStmt{
			TableLocks: $3.([]ast.TableLock),
		}
	}

TablesTerminalSym:
	"TABLES"
|	"TABLE"

TableLock:
	TableName LockType
	{
		$$ = ast.TableLock{
			Table: $1.(*ast.TableName),
			Type:  $2.(model.TableLockType),
		}
	}

LockType:
	"READ"
	{
		$$ = model.TableLockRead
	}
|	"READ" "LOCAL"
	{
		$$ = model.TableLockReadLocal
	}
|	"WRITE"
	{
		$$ = model.TableLockWrite
	}
|	"WRITE" "LOCAL"
	{
		$$ = model.TableLockWriteLocal
	}

TableLockList:
	TableLock
	{
		$$ = []ast.TableLock{$1.(ast.TableLock)}
	}
|	TableLockList ',' TableLock
	{
		$$ = append($1.([]ast.TableLock), $3.(ast.TableLock))
	}

/********************************************************************
 * Non-transactional Delete Statement
 * Split a SQL on a column. Used for bulk delete that doesn't need ACID.
 *******************************************************************/
NonTransactionalDeleteStmt:
	"BATCH" OptionalShardColumn "LIMIT" NUM DryRunOptions DeleteFromStmt
	{
		$$ = &ast.NonTransactionalDeleteStmt{
			DryRun:      $5.(int),
			ShardColumn: $2.(*ast.ColumnName),
			Limit:       getUint64FromNUM($4),
			DeleteStmt:  $6.(*ast.DeleteStmt),
		}
	}

DryRunOptions:
	{
		$$ = ast.NoDryRun
	}
|	"DRY" "RUN"
	{
		$$ = ast.DryRunSplitDml
	}
|	"DRY" "RUN" "QUERY"
	{
		$$ = ast.DryRunQuery
	}

OptionalShardColumn:
	{
		$$ = (*ast.ColumnName)(nil)
	}
|	"ON" ColumnName
	{
		$$ = $2.(*ast.ColumnName)
	}

/********************************************************************
 * Kill Statement
 * See https://dev.mysql.com/doc/refman/5.7/en/kill.html
 *******************************************************************/
KillStmt:
	KillOrKillTiDB NUM
	{
		$$ = &ast.KillStmt{
			ConnectionID:  getUint64FromNUM($2),
			TiDBExtension: $1.(bool),
		}
	}
|	KillOrKillTiDB "CONNECTION" NUM
	{
		$$ = &ast.KillStmt{
			ConnectionID:  getUint64FromNUM($3),
			TiDBExtension: $1.(bool),
		}
	}
|	KillOrKillTiDB "QUERY" NUM
	{
		$$ = &ast.KillStmt{
			ConnectionID:  getUint64FromNUM($3),
			Query:         true,
			TiDBExtension: $1.(bool),
		}
	}

KillOrKillTiDB:
	"KILL"
	{
		$$ = false
	}
/* KILL TIDB is a special grammar extension in TiDB, it can be used only when
   the client connect to TiDB directly, not proxied under LVS. */
|	"KILL" "TIDB"
	{
		$$ = true
	}

LoadStatsStmt:
	"LOAD" "STATS" stringLit
	{
		$$ = &ast.LoadStatsStmt{
			Path: $3,
		}
	}

DropPolicyStmt:
	"DROP" "PLACEMENT" "POLICY" IfExists PolicyName
	{
		$$ = &ast.DropPlacementPolicyStmt{
			IfExists:   $4.(bool),
			PolicyName: model.NewCIStr($5),
		}
	}

CreatePolicyStmt:
	"CREATE" OrReplace "PLACEMENT" "POLICY" IfNotExists PolicyName PlacementOptionList
	{
		$$ = &ast.CreatePlacementPolicyStmt{
			OrReplace:        $2.(bool),
			IfNotExists:      $5.(bool),
			PolicyName:       model.NewCIStr($6),
			PlacementOptions: $7.([]*ast.PlacementOption),
		}
	}

AlterPolicyStmt:
	"ALTER" "PLACEMENT" "POLICY" IfExists PolicyName PlacementOptionList
	{
		$$ = &ast.AlterPlacementPolicyStmt{
			IfExists:         $4.(bool),
			PolicyName:       model.NewCIStr($5),
			PlacementOptions: $6.([]*ast.PlacementOption),
		}
	}

/********************************************************************************************
 *
 *  Create Sequence Statement
 *
 *  Example:
 *	CREATE [TEMPORARY] SEQUENCE [IF NOT EXISTS] sequence_name
 *	[ INCREMENT [ BY | = ] increment ]
 *	[ MINVALUE [=] minvalue | NO MINVALUE | NOMINVALUE ]
 *	[ MAXVALUE [=] maxvalue | NO MAXVALUE | NOMAXVALUE ]
 *	[ START [ WITH | = ] start ]
 *	[ CACHE [=] cache | NOCACHE | NO CACHE]
 *	[ CYCLE | NOCYCLE | NO CYCLE]
 *	[table_options]
 ********************************************************************************************/
CreateSequenceStmt:
	"CREATE" "SEQUENCE" IfNotExists TableName CreateSequenceOptionListOpt CreateTableOptionListOpt
	{
		$$ = &ast.CreateSequenceStmt{
			IfNotExists: $3.(bool),
			Name:        $4.(*ast.TableName),
			SeqOptions:  $5.([]*ast.SequenceOption),
			TblOptions:  $6.([]*ast.TableOption),
		}
	}

CreateSequenceOptionListOpt:
	{
		$$ = []*ast.SequenceOption{}
	}
|	SequenceOptionList

SequenceOptionList:
	SequenceOption
	{
		$$ = []*ast.SequenceOption{$1.(*ast.SequenceOption)}
	}
|	SequenceOptionList SequenceOption
	{
		$$ = append($1.([]*ast.SequenceOption), $2.(*ast.SequenceOption))
	}

SequenceOption:
	"INCREMENT" EqOpt SignedNum
	{
		$$ = &ast.SequenceOption{Tp: ast.SequenceOptionIncrementBy, IntValue: $3.(int64)}
	}
|	"INCREMENT" "BY" SignedNum
	{
		$$ = &ast.SequenceOption{Tp: ast.SequenceOptionIncrementBy, IntValue: $3.(int64)}
	}
|	"START" EqOpt SignedNum
	{
		$$ = &ast.SequenceOption{Tp: ast.SequenceStartWith, IntValue: $3.(int64)}
	}
|	"START" "WITH" SignedNum
	{
		$$ = &ast.SequenceOption{Tp: ast.SequenceStartWith, IntValue: $3.(int64)}
	}
|	"MINVALUE" EqOpt SignedNum
	{
		$$ = &ast.SequenceOption{Tp: ast.SequenceMinValue, IntValue: $3.(int64)}
	}
|	"NOMINVALUE"
	{
		$$ = &ast.SequenceOption{Tp: ast.SequenceNoMinValue}
	}
|	"NO" "MINVALUE"
	{
		$$ = &ast.SequenceOption{Tp: ast.SequenceNoMinValue}
	}
|	"MAXVALUE" EqOpt SignedNum
	{
		$$ = &ast.SequenceOption{Tp: ast.SequenceMaxValue, IntValue: $3.(int64)}
	}
|	"NOMAXVALUE"
	{
		$$ = &ast.SequenceOption{Tp: ast.SequenceNoMaxValue}
	}
|	"NO" "MAXVALUE"
	{
		$$ = &ast.SequenceOption{Tp: ast.SequenceNoMaxValue}
	}
|	"CACHE" EqOpt SignedNum
	{
		$$ = &ast.SequenceOption{Tp: ast.SequenceCache, IntValue: $3.(int64)}
	}
|	"NOCACHE"
	{
		$$ = &ast.SequenceOption{Tp: ast.SequenceNoCache}
	}
|	"NO" "CACHE"
	{
		$$ = &ast.SequenceOption{Tp: ast.SequenceNoCache}
	}
|	"CYCLE"
	{
		$$ = &ast.SequenceOption{Tp: ast.SequenceCycle}
	}
|	"NOCYCLE"
	{
		$$ = &ast.SequenceOption{Tp: ast.SequenceNoCycle}
	}
|	"NO" "CYCLE"
	{
		$$ = &ast.SequenceOption{Tp: ast.SequenceNoCycle}
	}

SignedNum:
	Int64Num
|	'+' Int64Num
	{
		$$ = $2
	}
|	'-' NUM
	{
		unsigned_num := getUint64FromNUM($2)
		if unsigned_num > 9223372036854775808 {
			yylex.AppendError(yylex.Errorf("the Signed Value should be at the range of [-9223372036854775808, 9223372036854775807]."))
			return 1
		} else if unsigned_num == 9223372036854775808 {
			signed_one := int64(1)
			$$ = signed_one << 63
		} else {
			$$ = -int64(unsigned_num)
		}
	}

DropSequenceStmt:
	"DROP" "SEQUENCE" IfExists TableNameList
	{
		$$ = &ast.DropSequenceStmt{
			IfExists:  $3.(bool),
			Sequences: $4.([]*ast.TableName),
		}
	}

/********************************************************************************************
 *
 *  Alter Sequence Statement
 *
 *  Example:
 *	ALTER SEQUENCE [IF EXISTS] sequence_name
 *	[ INCREMENT [ BY | = ] increment ]
 *	[ MINVALUE [=] minvalue | NO MINVALUE | NOMINVALUE ]
 *	[ MAXVALUE [=] maxvalue | NO MAXVALUE | NOMAXVALUE ]
 *	[ START [ WITH | = ] start ]
 *	[ CACHE [=] cache | NOCACHE | NO CACHE]
 *	[ CYCLE | NOCYCLE | NO CYCLE]
 *	[ RESTART [WITH | = ] restart ]
 ********************************************************************************************/
AlterSequenceStmt:
	"ALTER" "SEQUENCE" IfExists TableName AlterSequenceOptionList
	{
		$$ = &ast.AlterSequenceStmt{
			IfExists:   $3.(bool),
			Name:       $4.(*ast.TableName),
			SeqOptions: $5.([]*ast.SequenceOption),
		}
	}

AlterSequenceOptionList:
	AlterSequenceOption
	{
		$$ = []*ast.SequenceOption{$1.(*ast.SequenceOption)}
	}
|	AlterSequenceOptionList AlterSequenceOption
	{
		$$ = append($1.([]*ast.SequenceOption), $2.(*ast.SequenceOption))
	}

AlterSequenceOption:
	SequenceOption
|	"RESTART"
	{
		$$ = &ast.SequenceOption{Tp: ast.SequenceRestart}
	}
|	"RESTART" EqOpt SignedNum
	{
		$$ = &ast.SequenceOption{Tp: ast.SequenceRestartWith, IntValue: $3.(int64)}
	}
|	"RESTART" "WITH" SignedNum
	{
		$$ = &ast.SequenceOption{Tp: ast.SequenceRestartWith, IntValue: $3.(int64)}
	}

/********************************************************************
 * Index Advisor Statement
 *
 * INDEX ADVISE
 * 	[LOCAL]
 *	INFILE 'file_name'
 *	[MAX_MINUTES number]
 *	[MAX_IDXNUM
 *  	[PER_TABLE number]
 *  	[PER_DB number]
 *	]
 *	[LINES
 *  	[STARTING BY 'string']
 *  	[TERMINATED BY 'string']
 *	]
 *******************************************************************/
IndexAdviseStmt:
	"INDEX" "ADVISE" LocalOpt "INFILE" stringLit MaxMinutesOpt MaxIndexNumOpt Lines
	{
		x := &ast.IndexAdviseStmt{
			Path:       $5,
			MaxMinutes: $6.(uint64),
		}
		if $3 != nil {
			x.IsLocal = true
		}
		if $7 != nil {
			x.MaxIndexNum = $7.(*ast.MaxIndexNumClause)
		}
		if $8 != nil {
			x.LinesInfo = $8.(*ast.LinesClause)
		}
		$$ = x
	}

MaxMinutesOpt:
	{
		$$ = uint64(ast.UnspecifiedSize)
	}
|	"MAX_MINUTES" NUM
	{
		$$ = getUint64FromNUM($2)
	}

MaxIndexNumOpt:
	{
		$$ = nil
	}
|	"MAX_IDXNUM" PerTable PerDB
	{
		$$ = &ast.MaxIndexNumClause{
			PerTable: $2.(uint64),
			PerDB:    $3.(uint64),
		}
	}

PerTable:
	{
		$$ = uint64(ast.UnspecifiedSize)
	}
|	"PER_TABLE" NUM
	{
		$$ = getUint64FromNUM($2)
	}

PerDB:
	{
		$$ = uint64(ast.UnspecifiedSize)
	}
|	"PER_DB" NUM
	{
		$$ = getUint64FromNUM($2)
	}

EncryptionOpt:
	stringLit
	{
		// Parse it but will ignore it
		switch $1 {
		case "Y", "y":
			yylex.AppendError(yylex.Errorf("The ENCRYPTION clause is parsed but ignored by all storage engines."))
			parser.lastErrorAsWarn()
		case "N", "n":
			break
		default:
			yylex.AppendError(ErrWrongValue.GenWithStackByArgs("argument (should be Y or N)", $1))
			return 1
		}
		$$ = $1
	}

ValuesStmtList:
	RowStmt
	{
		$$ = append([]*ast.RowExpr{}, $1.(*ast.RowExpr))
	}
|	ValuesStmtList ',' RowStmt
	{
		$$ = append($1.([]*ast.RowExpr), $3.(*ast.RowExpr))
	}

RowStmt:
	"ROW" RowValue
	{
		$$ = &ast.RowExpr{Values: $2.([]ast.ExprNode)}
	}

/********************************************************************
 *
 * Plan Replayer Statement
 *
 * PLAN REPLAYER
 * 		[DUMP EXPLAIN
 *			[ANALYZE]
 *			{ExplainableStmt
 *			| [WHERE where_condition]
 *			  [ORDER BY {col_name | expr | position}
 *    			[ASC | DESC], ... [WITH ROLLUP]]
 *  		  [LIMIT {[offset,] row_count | row_count OFFSET offset}]}
 *		| LOAD 'file_name']
 *******************************************************************/
PlanReplayerStmt:
	"PLAN" "REPLAYER" "DUMP" "EXPLAIN" ExplainableStmt
	{
		x := &ast.PlanReplayerStmt{
			Stmt:    $5,
			Analyze: false,
			Load:    false,
			File:    "",
			Where:   nil,
			OrderBy: nil,
			Limit:   nil,
		}
		startOffset := parser.startOffset(&yyS[yypt])
		x.Stmt.SetText(parser.lexer.client, strings.TrimSpace(parser.src[startOffset:]))

		$$ = x
	}
|	"PLAN" "REPLAYER" "DUMP" "EXPLAIN" "ANALYZE" ExplainableStmt
	{
		x := &ast.PlanReplayerStmt{
			Stmt:    $6,
			Analyze: true,
			Load:    false,
			File:    "",
			Where:   nil,
			OrderBy: nil,
			Limit:   nil,
		}
		startOffset := parser.startOffset(&yyS[yypt])
		x.Stmt.SetText(parser.lexer.client, strings.TrimSpace(parser.src[startOffset:]))

		$$ = x
	}
|	"PLAN" "REPLAYER" "DUMP" "EXPLAIN" "SLOW" "QUERY" WhereClauseOptional OrderByOptional SelectStmtLimitOpt
	{
		x := &ast.PlanReplayerStmt{
			Stmt:    nil,
			Analyze: false,
			Load:    false,
			File:    "",
		}
		if $7 != nil {
			x.Where = $7.(ast.ExprNode)
		}
		if $8 != nil {
			x.OrderBy = $8.(*ast.OrderByClause)
		}
		if $9 != nil {
			x.Limit = $9.(*ast.Limit)
		}

		$$ = x
	}
|	"PLAN" "REPLAYER" "DUMP" "EXPLAIN" "ANALYZE" "SLOW" "QUERY" WhereClauseOptional OrderByOptional SelectStmtLimitOpt
	{
		x := &ast.PlanReplayerStmt{
			Stmt:    nil,
			Analyze: true,
			Load:    false,
			File:    "",
		}
		if $8 != nil {
			x.Where = $8.(ast.ExprNode)
		}
		if $9 != nil {
			x.OrderBy = $9.(*ast.OrderByClause)
		}
		if $10 != nil {
			x.Limit = $10.(*ast.Limit)
		}

		$$ = x
	}
|	"PLAN" "REPLAYER" "LOAD" stringLit
	{
		x := &ast.PlanReplayerStmt{
			Stmt:    nil,
			Analyze: false,
			Load:    true,
			File:    $4,
			Where:   nil,
			OrderBy: nil,
			Limit:   nil,
		}

		$$ = x
	}
%%
