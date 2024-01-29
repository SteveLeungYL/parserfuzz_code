Start:
	StatementList


;
AlterTableStmt:
	'ALTER' IgnoreOptional 'TABLE' TableName AlterTableSpecListOpt AlterTablePartitionOpt
|	'ALTER' IgnoreOptional 'TABLE' TableName 'ANALYZE' 'PARTITION' PartitionNameList AnalyzeOptionListOpt
|	'ALTER' IgnoreOptional 'TABLE' TableName 'ANALYZE' 'PARTITION' PartitionNameList 'INDEX' IndexNameList AnalyzeOptionListOpt
|	'ALTER' IgnoreOptional 'TABLE' TableName 'COMPACT' 'TIFLASH' 'REPLICA'

;
PlacementOptionList:
	DirectPlacementOption
|	PlacementOptionList DirectPlacementOption
|	PlacementOptionList ',' DirectPlacementOption

;
DirectPlacementOption:
	'PRIMARY_REGION' EqOpt stringLit
|	'REGIONS' EqOpt stringLit
|	'FOLLOWERS' EqOpt LengthNum
|	'VOTERS' EqOpt LengthNum
|	'LEARNERS' EqOpt LengthNum
|	'SCHEDULE' EqOpt stringLit
|	'CONSTRAINTS' EqOpt stringLit
|	'LEADER_CONSTRAINTS' EqOpt stringLit
|	'FOLLOWER_CONSTRAINTS' EqOpt stringLit
|	'VOTER_CONSTRAINTS' EqOpt stringLit
|	'LEARNER_CONSTRAINTS' EqOpt stringLit

;
PlacementPolicyOption:
	'PLACEMENT' 'POLICY' EqOpt stringLit
|	'PLACEMENT' 'POLICY' EqOpt PolicyName
|	'PLACEMENT' 'POLICY' EqOpt 'DEFAULT'
|	'PLACEMENT' 'POLICY' 'SET' 'DEFAULT'

;
AttributesOpt:
	'ATTRIBUTES' EqOpt 'DEFAULT'
|	'ATTRIBUTES' EqOpt stringLit

;
StatsOptionsOpt:
	'STATS_OPTIONS' EqOpt 'DEFAULT'
|	'STATS_OPTIONS' EqOpt stringLit

;
AlterTablePartitionOpt:
	PartitionOpt
|	'REMOVE' 'PARTITIONING'
|	'REORGANIZE' 'PARTITION' NoWriteToBinLogAliasOpt ReorganizePartitionRuleOpt
|	'PARTITION' Identifier AttributesOpt
|	'PARTITION' Identifier PartDefOptionList

;
LocationLabelList:
|	'LOCATION' 'LABELS' StringList

;
AlterTableSpec:
	TableOptionList %prec higherThanComma
|	'SET' 'TIFLASH' 'REPLICA' LengthNum LocationLabelList
|	'CONVERT' 'TO' CharsetKw CharsetName OptCollate
|	'CONVERT' 'TO' CharsetKw 'DEFAULT' OptCollate
|	'ADD' ColumnKeywordOpt IfNotExists ColumnDef ColumnPosition
|	'ADD' ColumnKeywordOpt IfNotExists '(' TableElementList ')'
|	'ADD' Constraint
|	'ADD' 'PARTITION' IfNotExists NoWriteToBinLogAliasOpt PartitionDefinitionListOpt
|	'ADD' 'PARTITION' IfNotExists NoWriteToBinLogAliasOpt 'PARTITIONS' NUM
|	'ADD' 'STATS_EXTENDED' IfNotExists Identifier StatsType '(' ColumnNameList ')'
|	AttributesOpt
|	StatsOptionsOpt
|	'CHECK' 'PARTITION' AllOrPartitionNameList
|	'COALESCE' 'PARTITION' NoWriteToBinLogAliasOpt NUM
|	'DROP' ColumnKeywordOpt IfExists ColumnName RestrictOrCascadeOpt
|	'DROP' 'PRIMARY' 'KEY'
|	'DROP' 'PARTITION' IfExists PartitionNameList %prec lowerThanComma
|	'DROP' 'STATS_EXTENDED' IfExists Identifier
|	'EXCHANGE' 'PARTITION' Identifier 'WITH' 'TABLE' TableName WithValidationOpt
|	'TRUNCATE' 'PARTITION' AllOrPartitionNameList
|	'OPTIMIZE' 'PARTITION' NoWriteToBinLogAliasOpt AllOrPartitionNameList
|	'REPAIR' 'PARTITION' NoWriteToBinLogAliasOpt AllOrPartitionNameList
|	'IMPORT' 'PARTITION' AllOrPartitionNameList 'TABLESPACE'
|	'DISCARD' 'PARTITION' AllOrPartitionNameList 'TABLESPACE'
|	'IMPORT' 'TABLESPACE'
|	'DISCARD' 'TABLESPACE'
|	'REBUILD' 'PARTITION' NoWriteToBinLogAliasOpt AllOrPartitionNameList
|	'DROP' KeyOrIndex IfExists Identifier
|	'DROP' 'FOREIGN' 'KEY' IfExists Symbol
|	'ORDER' 'BY' AlterOrderList %prec lowerThenOrder
|	'DISABLE' 'KEYS'
|	'ENABLE' 'KEYS'
|	'MODIFY' ColumnKeywordOpt IfExists ColumnDef ColumnPosition
|	'CHANGE' ColumnKeywordOpt IfExists ColumnName ColumnDef ColumnPosition
|	'ALTER' ColumnKeywordOpt ColumnName 'SET' 'DEFAULT' SignedLiteral
|	'ALTER' ColumnKeywordOpt ColumnName 'SET' 'DEFAULT' '(' Expression ')'
|	'ALTER' ColumnKeywordOpt ColumnName 'DROP' 'DEFAULT'
|	'RENAME' 'COLUMN' Identifier 'TO' Identifier
|	'RENAME' 'TO' TableName
|	'RENAME' EqOpt TableName
|	'RENAME' 'AS' TableName
|	'RENAME' KeyOrIndex Identifier 'TO' Identifier
|	LockClause
|	Writeable
|	AlgorithmClause
|	'FORCE'
|	'WITH' 'VALIDATION'
|	'WITHOUT' 'VALIDATION'
// Added in MySQL 8.0.13, see: https://dev.mysql.com/doc/refman/8.0/en/keywords.html for details
|	'SECONDARY_LOAD'
// Added in MySQL 8.0.13, see: https://dev.mysql.com/doc/refman/8.0/en/keywords.html for details
|	'SECONDARY_UNLOAD'
|	'ALTER' CheckConstraintKeyword Identifier EnforcedOrNot
|	'DROP' CheckConstraintKeyword Identifier
|	'ALTER' 'INDEX' Identifier IndexInvisible
// 	Support caching or non-caching a table in memory for tidb, It can be found in the official Oracle document, see: https://docs.oracle.com/database/121/SQLRF/statements_3001.htm
|	'CACHE'
|	'NOCACHE'

;
ReorganizePartitionRuleOpt:
	 %prec lowerThanRemove
|	PartitionNameList 'INTO' '(' PartitionDefinitionList ')'

;
AllOrPartitionNameList:
	'ALL'
|	PartitionNameList %prec lowerThanComma

;
WithValidationOpt:
|	WithValidation

;
WithValidation:
	'WITH' 'VALIDATION'
|	'WITHOUT' 'VALIDATION'

;
WithClustered:
	'CLUSTERED'
|	'NONCLUSTERED'

;
AlgorithmClause:
	'ALGORITHM' EqOpt 'DEFAULT'
|	'ALGORITHM' EqOpt 'COPY'
|	'ALGORITHM' EqOpt 'INPLACE'
|	'ALGORITHM' EqOpt 'INSTANT'
|	'ALGORITHM' EqOpt identifier

;
LockClause:
	'LOCK' EqOpt 'DEFAULT'
|	'LOCK' EqOpt Identifier

;
Writeable:
	'READ' 'WRITE'
|	'READ' 'ONLY'

;
KeyOrIndex:
	'KEY'
|	'INDEX'

;
KeyOrIndexOpt:
|	KeyOrIndex

;
ColumnKeywordOpt:
	 %prec empty
|	'COLUMN'

;
ColumnPosition:
|	'FIRST'
|	'AFTER' ColumnName

;
AlterTableSpecListOpt:
|	AlterTableSpecList

;
AlterTableSpecList:
	AlterTableSpec
|	AlterTableSpecList ',' AlterTableSpec

;
PartitionNameList:
	Identifier
|	PartitionNameList ',' Identifier

;
ConstraintKeywordOpt:
	 %prec empty
|	'CONSTRAINT'
|	'CONSTRAINT' Symbol

;
Symbol:
	Identifier


;
RenameTableStmt:
	'RENAME' 'TABLE' TableToTableList

;
TableToTableList:
	TableToTable
|	TableToTableList ',' TableToTable

;
TableToTable:
	TableName 'TO' TableName


;
RenameUserStmt:
	'RENAME' 'USER' UserToUserList

;
UserToUserList:
	UserToUser
|	UserToUserList ',' UserToUser

;
UserToUser:
	Username 'TO' Username


;
RecoverTableStmt:
	'RECOVER' 'TABLE' 'BY' 'JOB' Int64Num
|	'RECOVER' 'TABLE' TableName
|	'RECOVER' 'TABLE' TableName Int64Num


;
FlashbackTableStmt:
	'FLASHBACK' 'TABLE' TableName FlashbackToNewName

;
FlashbackToNewName:
|	'TO' Identifier


;
SplitRegionStmt:
	'SPLIT' SplitSyntaxOption 'TABLE' TableName PartitionNameListOpt SplitOption
|	'SPLIT' SplitSyntaxOption 'TABLE' TableName PartitionNameListOpt 'INDEX' Identifier SplitOption

;
SplitOption:
	'BETWEEN' RowValue 'AND' RowValue 'REGIONS' Int64Num
|	'BY' ValuesList

;
SplitSyntaxOption:
|	'REGION' 'FOR'
|	'PARTITION'
|	'REGION' 'FOR' 'PARTITION'

;
AnalyzeTableStmt:
	'ANALYZE' 'TABLE' TableNameList AllColumnsOrPredicateColumnsOpt AnalyzeOptionListOpt
|	'ANALYZE' 'TABLE' TableName 'INDEX' IndexNameList AnalyzeOptionListOpt
|	'ANALYZE' 'INCREMENTAL' 'TABLE' TableName 'INDEX' IndexNameList AnalyzeOptionListOpt
|	'ANALYZE' 'TABLE' TableName 'PARTITION' PartitionNameList AllColumnsOrPredicateColumnsOpt AnalyzeOptionListOpt
|	'ANALYZE' 'TABLE' TableName 'PARTITION' PartitionNameList 'INDEX' IndexNameList AnalyzeOptionListOpt
|	'ANALYZE' 'INCREMENTAL' 'TABLE' TableName 'PARTITION' PartitionNameList 'INDEX' IndexNameList AnalyzeOptionListOpt
|	'ANALYZE' 'TABLE' TableName 'UPDATE' 'HISTOGRAM' 'ON' IdentList AnalyzeOptionListOpt
|	'ANALYZE' 'TABLE' TableName 'DROP' 'HISTOGRAM' 'ON' IdentList
|	'ANALYZE' 'TABLE' TableName 'COLUMNS' IdentList AnalyzeOptionListOpt
|	'ANALYZE' 'TABLE' TableName 'PARTITION' PartitionNameList 'COLUMNS' IdentList AnalyzeOptionListOpt

;
AllColumnsOrPredicateColumnsOpt:
|	'ALL' 'COLUMNS'
|	'PREDICATE' 'COLUMNS'

;
AnalyzeOptionListOpt:
|	'WITH' AnalyzeOptionList

;
AnalyzeOptionList:
	AnalyzeOption
|	AnalyzeOptionList ',' AnalyzeOption

;
AnalyzeOption:
	NUM 'BUCKETS'
|	NUM 'TOPN'
|	NUM 'CMSKETCH' 'DEPTH'
|	NUM 'CMSKETCH' 'WIDTH'
|	NUM 'SAMPLES'
|	NumLiteral 'SAMPLERATE'


;
Assignment:
	ColumnName eq ExprOrDefault

;
AssignmentList:
	Assignment
|	AssignmentList ',' Assignment

;
AssignmentListOpt:
|	AssignmentList

;
BeginTransactionStmt:
	'BEGIN'
|	'BEGIN' 'PESSIMISTIC'
|	'BEGIN' 'OPTIMISTIC'
|	'START' 'TRANSACTION'
|	'START' 'TRANSACTION' 'READ' 'WRITE'
|	'START' 'TRANSACTION' 'WITH' 'CONSISTENT' 'SNAPSHOT'
|	'START' 'TRANSACTION' 'WITH' 'CAUSAL' 'CONSISTENCY' 'ONLY'
|	'START' 'TRANSACTION' 'READ' 'ONLY'
|	'START' 'TRANSACTION' 'READ' 'ONLY' AsOfClause

;
BinlogStmt:
	'BINLOG' stringLit

;
ColumnDefList:
	ColumnDef
|	ColumnDefList ',' ColumnDef

;
ColumnDef:
	ColumnName Type ColumnOptionListOpt
|	ColumnName 'SERIAL' ColumnOptionListOpt

;
ColumnName:
	Identifier
|	Identifier '.' Identifier
|	Identifier '.' Identifier '.' Identifier

;
ColumnNameList:
	ColumnName
|	ColumnNameList ',' ColumnName

;
ColumnNameListOpt:
|	ColumnNameList

;
IdentListWithParenOpt:
|	'(' IdentList ')'

;
IdentList:
	Identifier
|	IdentList ',' Identifier

;
ColumnNameOrUserVarListOpt:
|	ColumnNameOrUserVariableList

;
ColumnNameOrUserVariableList:
	ColumnNameOrUserVariable
|	ColumnNameOrUserVariableList ',' ColumnNameOrUserVariable

;
ColumnNameOrUserVariable:
	ColumnName
|	UserVariable

;
ColumnNameOrUserVarListOptWithBrackets:
|	'(' ColumnNameOrUserVarListOpt ')'

;
CommitStmt:
	'COMMIT'
|	'COMMIT' CompletionTypeWithinTransaction

;
PrimaryOpt:
|	'PRIMARY'

;
NotSym:
	not
|	not2

;
EnforcedOrNot:
	'ENFORCED'
|	NotSym 'ENFORCED'

;
EnforcedOrNotOpt:
	%prec lowerThanNot
|	EnforcedOrNot

;
EnforcedOrNotOrNotNullOpt:
	//	 This branch is needed to workaround the need of a lookahead of 2 for the grammar:
	//
	//	   ...
	NotSym 'NULL'
|	EnforcedOrNotOpt

;
ColumnOption:
	NotSym 'NULL'
|	'NULL'
|	'AUTO_INCREMENT'
|	PrimaryOpt 'KEY'
|	PrimaryOpt 'KEY' WithClustered
|	'UNIQUE' %prec lowerThanKey
|	'UNIQUE' 'KEY'
|	'DEFAULT' DefaultValueExpr
|	'SERIAL' 'DEFAULT' 'VALUE'
|	'ON' 'UPDATE' NowSymOptionFraction
|	'COMMENT' stringLit
|	ConstraintKeywordOpt 'CHECK' '(' Expression ')' EnforcedOrNotOrNotNullOpt
|	GeneratedAlways 'AS' '(' Expression ')' VirtualOrStored
|	ReferDef
|	'COLLATE' CollationName
|	'COLUMN_FORMAT' ColumnFormat
|	'STORAGE' StorageMedia
|	'AUTO_RANDOM' OptFieldLen

;
StorageMedia:
	'DEFAULT'
|	'DISK'
|	'MEMORY'

;
ColumnFormat:
	'DEFAULT'
|	'FIXED'
|	'DYNAMIC'

;
GeneratedAlways:

|	'GENERATED' 'ALWAYS'

;
VirtualOrStored:
|	'VIRTUAL'
|	'STORED'

;
ColumnOptionList:
	ColumnOption
|	ColumnOptionList ColumnOption

;
ColumnOptionListOpt:
|	ColumnOptionList

;
ConstraintElem:
	'PRIMARY' 'KEY' IndexNameAndTypeOpt '(' IndexPartSpecificationList ')' IndexOptionList
|	'FULLTEXT' KeyOrIndexOpt IndexName '(' IndexPartSpecificationList ')' IndexOptionList
|	KeyOrIndex IfNotExists IndexNameAndTypeOpt '(' IndexPartSpecificationList ')' IndexOptionList
|	'UNIQUE' KeyOrIndexOpt IndexNameAndTypeOpt '(' IndexPartSpecificationList ')' IndexOptionList
|	'FOREIGN' 'KEY' IfNotExists IndexName '(' IndexPartSpecificationList ')' ReferDef
|	'CHECK' '(' Expression ')' EnforcedOrNotOpt

;
Match:
	'MATCH' 'FULL'
|	'MATCH' 'PARTIAL'
|	'MATCH' 'SIMPLE'

;
MatchOpt:
|	Match

;
ReferDef:
	'REFERENCES' TableName IndexPartSpecificationListOpt MatchOpt OnDeleteUpdateOpt

;
OnDelete:
	'ON' 'DELETE' ReferOpt

;
OnUpdate:
	'ON' 'UPDATE' ReferOpt

;
OnDeleteUpdateOpt:
	%prec lowerThanOn
|	OnDelete %prec lowerThanOn
|	OnUpdate %prec lowerThanOn
|	OnDelete OnUpdate
|	OnUpdate OnDelete

;
ReferOpt:
	'RESTRICT'
|	'CASCADE'
|	'SET' 'NULL'
|	'NO' 'ACTION'
|	'SET' 'DEFAULT'


;
DefaultValueExpr:
	NowSymOptionFractionParentheses
|	SignedLiteral
|	NextValueForSequence
|	BuiltinFunction

;
BuiltinFunction:
	'(' BuiltinFunction ')'
|	identifier '(' ')'
|	identifier '(' ExpressionList ')'

;
NowSymOptionFractionParentheses:
	'(' NowSymOptionFractionParentheses ')'
|	NowSymOptionFraction

;
NowSymOptionFraction:
	NowSym
|	NowSymFunc '(' ')'
|	NowSymFunc '(' NUM ')'

;
NextValueForSequence:
	'NEXT' 'VALUE' forKwd TableName
|	'NEXTVAL' '(' TableName ')'


;
NowSymFunc:
	'CURRENT_TIMESTAMP'
|	'LOCALTIME'
|	'LOCALTIMESTAMP'
|	builtinNow

;
NowSym:
	'CURRENT_TIMESTAMP'
|	'LOCALTIME'
|	'LOCALTIMESTAMP'

;
SignedLiteral:
	Literal
|	'+' NumLiteral
|	'-' NumLiteral

;
NumLiteral:
	intLit
|	floatLit
|	decLit

;
StatsType:
	'CARDINALITY'
|	'DEPENDENCY'
|	'CORRELATION'

;
BindingStatusType:
	'ENABLED'
|	'DISABLED'

;
CreateStatisticsStmt:
	'CREATE' 'STATISTICS' IfNotExists Identifier '(' StatsType ')' 'ON' TableName '(' ColumnNameList ')'

;
DropStatisticsStmt:
	'DROP' 'STATISTICS' Identifier


;
CreateIndexStmt:
	'CREATE' IndexKeyTypeOpt 'INDEX' IfNotExists Identifier IndexTypeOpt 'ON' TableName '(' IndexPartSpecificationList ')' IndexOptionList IndexLockAndAlgorithmOpt

;
IndexPartSpecificationListOpt:
|	'(' IndexPartSpecificationList ')'

;
IndexPartSpecificationList:
	IndexPartSpecification
|	IndexPartSpecificationList ',' IndexPartSpecification

;
IndexPartSpecification:
	ColumnName OptFieldLen OptOrder
|	'(' Expression ')' OptOrder

;
IndexLockAndAlgorithmOpt:
|	LockClause
|	AlgorithmClause
|	LockClause AlgorithmClause
|	AlgorithmClause LockClause

;
IndexKeyTypeOpt:
|	'UNIQUE'
|	'SPATIAL'
|	'FULLTEXT'


;
AlterDatabaseStmt:
	'ALTER' DatabaseSym DBName DatabaseOptionList
|	'ALTER' DatabaseSym DatabaseOptionList


;
CreateDatabaseStmt:
	'CREATE' DatabaseSym IfNotExists DBName DatabaseOptionListOpt

;
DBName:
	Identifier

;
PolicyName:
	Identifier

;
DatabaseOption:
	DefaultKwdOpt CharsetKw EqOpt CharsetName
|	DefaultKwdOpt 'COLLATE' EqOpt CollationName
|	DefaultKwdOpt 'ENCRYPTION' EqOpt EncryptionOpt
|	DefaultKwdOpt PlacementPolicyOption
|	PlacementPolicyOption
|	'SET' 'TIFLASH' 'REPLICA' LengthNum LocationLabelList

;
DatabaseOptionListOpt:
|	DatabaseOptionList

;
DatabaseOptionList:
	DatabaseOption
|	DatabaseOptionList DatabaseOption


;
CreateTableStmt:
	'CREATE' OptTemporary 'TABLE' IfNotExists TableName TableElementList CreateTableOptionListOpt PartitionOpt DuplicateOpt AsOpt CreateTableSelectOpt OnCommitOpt
|	'CREATE' OptTemporary 'TABLE' IfNotExists TableName LikeTableWithOrWithoutParen OnCommitOpt

;
OnCommitOpt:
|	'ON' 'COMMIT' 'DELETE' 'ROWS'
|	'ON' 'COMMIT' 'PRESERVE' 'ROWS'

;
DefaultKwdOpt:
	%prec lowerThanCharsetKwd
|	'DEFAULT'

;
PartitionOpt:
|	'PARTITION' 'BY' PartitionMethod PartitionNumOpt SubPartitionOpt PartitionDefinitionListOpt

;
SubPartitionMethod:
	LinearOpt 'KEY' PartitionKeyAlgorithmOpt '(' ColumnNameListOpt ')'
|	LinearOpt 'HASH' '(' BitExpr ')'

;
PartitionKeyAlgorithmOpt:
|	'ALGORITHM' eq NUM

;
PartitionMethod:
	SubPartitionMethod
|	'RANGE' '(' BitExpr ')'
|	'RANGE' FieldsOrColumns '(' ColumnNameList ')'
|	'LIST' '(' BitExpr ')'
|	'LIST' FieldsOrColumns '(' ColumnNameList ')'
|	'SYSTEM_TIME' 'INTERVAL' Expression TimeUnit
|	'SYSTEM_TIME' 'LIMIT' LengthNum
|	'SYSTEM_TIME'

;
LinearOpt:
|	'LINEAR'

;
SubPartitionOpt:
|	'SUBPARTITION' 'BY' SubPartitionMethod SubPartitionNumOpt

;
SubPartitionNumOpt:
|	'SUBPARTITIONS' LengthNum

;
PartitionNumOpt:
|	'PARTITIONS' LengthNum

;
PartitionDefinitionListOpt:
	 %prec lowerThanCreateTableSelect
|	'(' PartitionDefinitionList ')'

;
PartitionDefinitionList:
	PartitionDefinition
|	PartitionDefinitionList ',' PartitionDefinition

;
PartitionDefinition:
	'PARTITION' Identifier PartDefValuesOpt PartDefOptionList SubPartDefinitionListOpt

;
SubPartDefinitionListOpt:
|	'(' SubPartDefinitionList ')'

;
SubPartDefinitionList:
	SubPartDefinition
|	SubPartDefinitionList ',' SubPartDefinition

;
SubPartDefinition:
	'SUBPARTITION' Identifier PartDefOptionList

;
PartDefOptionList:
|	PartDefOptionList PartDefOption

;
PartDefOption:
	'COMMENT' EqOpt stringLit
|	'ENGINE' EqOpt StringName
|	'STORAGE' 'ENGINE' EqOpt StringName
|	'INSERT_METHOD' EqOpt StringName
|	'DATA' 'DIRECTORY' EqOpt stringLit
|	'INDEX' 'DIRECTORY' EqOpt stringLit
|	'MAX_ROWS' EqOpt LengthNum
|	'MIN_ROWS' EqOpt LengthNum
|	'TABLESPACE' EqOpt Identifier
|	'NODEGROUP' EqOpt LengthNum
|	PlacementPolicyOption

;
PartDefValuesOpt:
|	'VALUES' 'LESS' 'THAN' 'MAXVALUE'
|	'VALUES' 'LESS' 'THAN' '(' MaxValueOrExpressionList ')'
|	'DEFAULT'
|	'VALUES' 'IN' '(' MaxValueOrExpressionList ')'
|	'HISTORY'
|	'CURRENT'

;
DuplicateOpt:
|	'IGNORE'
|	'REPLACE'

;
AsOpt:
|	'AS'

;
CreateTableSelectOpt:
|	SetOprStmt
|	SelectStmt
|	SelectStmtWithClause
|	SubSelect

;
CreateViewSelectOpt:
	SetOprStmt
|	SelectStmt
|	SelectStmtWithClause
|	SubSelect

;
LikeTableWithOrWithoutParen:
	'LIKE' TableName
|	'(' 'LIKE' TableName ')'


;
CreateViewStmt:
	'CREATE' OrReplace ViewAlgorithm ViewDefiner ViewSQLSecurity 'VIEW' ViewName ViewFieldList 'AS' CreateViewSelectOpt ViewCheckOption

;
OrReplace:
|	'OR' 'REPLACE'

;
ViewAlgorithm:
|	'ALGORITHM' '=' 'UNDEFINED'
|	'ALGORITHM' '=' 'MERGE'
|	'ALGORITHM' '=' 'TEMPTABLE'

;
ViewDefiner:
|	'DEFINER' '=' Username

;
ViewSQLSecurity:
|	'SQL' 'SECURITY' 'DEFINER'
|	'SQL' 'SECURITY' 'INVOKER'

;
ViewName:
	TableName

;
ViewFieldList:
|	'(' ColumnList ')'

;
ColumnList:
	Identifier
|	ColumnList ',' Identifier

;
ViewCheckOption:
|	'WITH' 'CASCADED' 'CHECK' 'OPTION'
|	'WITH' 'LOCAL' 'CHECK' 'OPTION'


;
DoStmt:
	'DO' ExpressionList


;
DeleteWithoutUsingStmt:
	'DELETE' TableOptimizerHintsOpt PriorityOpt QuickOptional IgnoreOptional 'FROM' TableName PartitionNameListOpt TableAsNameOpt IndexHintListOpt WhereClauseOptional OrderByOptional LimitClause
|	'DELETE' TableOptimizerHintsOpt PriorityOpt QuickOptional IgnoreOptional TableAliasRefList 'FROM' TableRefs WhereClauseOptional

;
DeleteWithUsingStmt:
	'DELETE' TableOptimizerHintsOpt PriorityOpt QuickOptional IgnoreOptional 'FROM' TableAliasRefList 'USING' TableRefs WhereClauseOptional

;
DeleteFromStmt:
	DeleteWithoutUsingStmt
|	DeleteWithUsingStmt
|	WithClause DeleteWithoutUsingStmt
|	WithClause DeleteWithUsingStmt

;
DatabaseSym:
	'DATABASE'

;
DropDatabaseStmt:
	'DROP' DatabaseSym IfExists DBName


;
DropIndexStmt:
	'DROP' 'INDEX' IfExists Identifier 'ON' TableName IndexLockAndAlgorithmOpt

;
DropTableStmt:
	'DROP' OptTemporary TableOrTables IfExists TableNameList RestrictOrCascadeOpt

;
OptTemporary:
|	'TEMPORARY'
|	'GLOBAL' 'TEMPORARY'

;
DropViewStmt:
	'DROP' 'VIEW' TableNameList RestrictOrCascadeOpt
|	'DROP' 'VIEW' 'IF' 'EXISTS' TableNameList RestrictOrCascadeOpt

;
DropUserStmt:
	'DROP' 'USER' UsernameList
|	'DROP' 'USER' 'IF' 'EXISTS' UsernameList

;
DropRoleStmt:
	'DROP' 'ROLE' RolenameList
|	'DROP' 'ROLE' 'IF' 'EXISTS' RolenameList

;
DropStatsStmt:
	'DROP' 'STATS' TableName
|	'DROP' 'STATS' TableName 'PARTITION' PartitionNameList
|	'DROP' 'STATS' TableName 'GLOBAL'

;
RestrictOrCascadeOpt:
|	'RESTRICT'
|	'CASCADE'

;
TableOrTables:
	'TABLE'
|	'TABLES'

;
EqOpt:
|	eq

;
EmptyStmt:

;
TraceStmt:
	'TRACE' TraceableStmt
|	'TRACE' 'FORMAT' '=' stringLit TraceableStmt
|	'TRACE' 'PLAN' TraceableStmt
|	'TRACE' 'PLAN' 'TARGET' '=' stringLit TraceableStmt

;
ExplainSym:
	'EXPLAIN'
|	'DESCRIBE'
|	'DESC'

;
ExplainStmt:
	ExplainSym TableName
|	ExplainSym TableName ColumnName
|	ExplainSym ExplainableStmt
|	ExplainSym 'FOR' 'CONNECTION' NUM
|	ExplainSym 'FORMAT' '=' stringLit 'FOR' 'CONNECTION' NUM
|	ExplainSym 'FORMAT' '=' stringLit ExplainableStmt
|	ExplainSym 'FORMAT' '=' ExplainFormatType 'FOR' 'CONNECTION' NUM
|	ExplainSym 'FORMAT' '=' ExplainFormatType ExplainableStmt
|	ExplainSym 'ANALYZE' ExplainableStmt
|	ExplainSym 'ANALYZE' 'FORMAT' '=' ExplainFormatType ExplainableStmt
|	ExplainSym 'ANALYZE' 'FORMAT' '=' stringLit ExplainableStmt

;
ExplainFormatType:
	'TRADITIONAL'
|	'JSON'
|	'ROW'
|	'DOT'
|	'BRIEF'
|	'VERBOSE'
|	'TRUE_CARD_COST'


;
BRIEStmt:
	'BACKUP' BRIETables 'TO' stringLit BRIEOptions
|	'RESTORE' BRIETables 'FROM' stringLit BRIEOptions

;
BRIETables:
	DatabaseSym '*'
|	DatabaseSym DBNameList
|	'TABLE' TableNameList

;
DBNameList:
	DBName
|	DBNameList ',' DBName

;
BRIEOptions:
	%prec empty
|	BRIEOptions BRIEOption

;
BRIEIntegerOptionName:
	'CONCURRENCY'
|	'RESUME'

;
BRIEBooleanOptionName:
	'SEND_CREDENTIALS_TO_TIKV'
|	'ONLINE'
|	'CHECKPOINT'
|	'SKIP_SCHEMA_FILES'
|	'STRICT_FORMAT'
|	'CSV_NOT_NULL'
|	'CSV_BACKSLASH_ESCAPE'
|	'CSV_TRIM_LAST_SEPARATORS'

;
BRIEStringOptionName:
	'TIKV_IMPORTER'
|	'CSV_SEPARATOR'
|	'CSV_DELIMITER'
|	'CSV_NULL'

;
BRIEKeywordOptionName:
	'BACKEND'
|	'ON_DUPLICATE'
|	'ON' 'DUPLICATE'

;
BRIEOption:
	BRIEIntegerOptionName EqOpt LengthNum
|	BRIEBooleanOptionName EqOpt Boolean
|	BRIEStringOptionName EqOpt stringLit
|	BRIEKeywordOptionName EqOpt StringNameOrBRIEOptionKeyword
|	'SNAPSHOT' EqOpt LengthNum TimestampUnit 'AGO'
|	'SNAPSHOT' EqOpt stringLit
	// not including this into BRIEStringOptionName to avoid shift/reduce conflict
|	'SNAPSHOT' EqOpt LengthNum
	// not including this into BRIEIntegerOptionName to avoid shift/reduce conflict
|	'LAST_BACKUP' EqOpt stringLit
|	'LAST_BACKUP' EqOpt LengthNum
|	'RATE_LIMIT' EqOpt LengthNum 'MB' '/' 'SECOND'
|	'CSV_HEADER' EqOpt FieldsOrColumns
|	'CSV_HEADER' EqOpt LengthNum
|	'CHECKSUM' EqOpt Boolean
|	'CHECKSUM' EqOpt OptionLevel
|	'ANALYZE' EqOpt Boolean
|	'ANALYZE' EqOpt OptionLevel

;
LengthNum:
	NUM

;
Int64Num:
	NUM

;
NUM:
	intLit

;
Boolean:
	NUM
|	'FALSE'
|	'TRUE'

;
OptionLevel:
	'OFF'
|	'OPTIONAL'
|	'REQUIRED'

;
PurgeImportStmt:
	'PURGE' 'IMPORT' NUM


;
CreateImportStmt:
	'CREATE' 'IMPORT' IfNotExists Identifier 'FROM' stringLit ErrorHandling BRIEOptions

;
StopImportStmt:
	'STOP' 'IMPORT' IfRunning Identifier

;
ResumeImportStmt:
	'RESUME' 'IMPORT' IfNotRunning Identifier

;
AlterImportStmt:
	'ALTER' 'IMPORT' Identifier ErrorHandling BRIEOptions ImportTruncate

;
DropImportStmt:
	'DROP' 'IMPORT' IfExists Identifier

;
ShowImportStmt:
	'SHOW' 'IMPORT' Identifier OptErrors TableNameListOpt2

;
IfRunning:
|	'IF' 'RUNNING'

;
IfNotRunning:
|	'IF' NotSym 'RUNNING'

;
OptErrors:
|	'ERRORS'

;
ErrorHandling:
|	'REPLACE'
|	'SKIP' 'ALL'
|	'SKIP' 'CONSTRAINT'
|	'SKIP' 'DUPLICATE'
|	'SKIP' 'STRICT'

;
ImportTruncate:
|	'TRUNCATE' 'ALL' TableNameListOpt2
|	'TRUNCATE' 'ERRORS' TableNameListOpt2

;
Expression:
	singleAtIdentifier assignmentEq Expression %prec assignmentEq
|	Expression logOr Expression %prec pipes
|	Expression 'XOR' Expression %prec xor
|	Expression logAnd Expression %prec andand
|	'NOT' Expression %prec not
|	'MATCH' '(' ColumnNameList ')' 'AGAINST' '(' BitExpr FulltextSearchModifierOpt ')'
|	BoolPri IsOrNotOp trueKwd %prec is
|	BoolPri IsOrNotOp falseKwd %prec is
|	BoolPri IsOrNotOp 'UNKNOWN' %prec is
|	BoolPri

;
MaxValueOrExpression:
	'MAXVALUE'
|	BitExpr

;
FulltextSearchModifierOpt:
|	'IN' 'NATURAL' 'LANGUAGE' 'MODE'
|	'IN' 'NATURAL' 'LANGUAGE' 'MODE' 'WITH' 'QUERY' 'EXPANSION'
|	'IN' 'BOOLEAN' 'MODE'
|	'WITH' 'QUERY' 'EXPANSION'

;
logOr:
	pipesAsOr
|	'OR'

;
logAnd:
	'&&'
|	'AND'

;
ExpressionList:
	Expression
|	ExpressionList ',' Expression

;
MaxValueOrExpressionList:
	MaxValueOrExpression
|	MaxValueOrExpressionList ',' MaxValueOrExpression

;
ExpressionListOpt:
|	ExpressionList

;
FuncDatetimePrecListOpt:
|	FuncDatetimePrecList

;
FuncDatetimePrecList:
	intLit

;
BoolPri:
	BoolPri IsOrNotOp 'NULL' %prec is
|	BoolPri CompareOp PredicateExpr %prec eq
|	BoolPri CompareOp AnyOrAll SubSelect %prec eq
|	BoolPri CompareOp singleAtIdentifier assignmentEq PredicateExpr %prec assignmentEq
|	PredicateExpr

;
CompareOp:
	'>='
|	'>'
|	'<='
|	'<'
|	'!='
|	'<>'
|	'='
|	'<=>'

;
BetweenOrNotOp:
	'BETWEEN'
|	NotSym 'BETWEEN'

;
IsOrNotOp:
	'IS'
|	'IS' NotSym

;
InOrNotOp:
	'IN'
|	NotSym 'IN'

;
LikeOrNotOp:
	'LIKE'
|	NotSym 'LIKE'

;
RegexpOrNotOp:
	RegexpSym
|	NotSym RegexpSym

;
AnyOrAll:
	'ANY'
|	'SOME'
|	'ALL'

;
PredicateExpr:
	BitExpr InOrNotOp '(' ExpressionList ')'
|	BitExpr InOrNotOp SubSelect
|	BitExpr BetweenOrNotOp BitExpr 'AND' PredicateExpr
|	BitExpr LikeOrNotOp SimpleExpr LikeEscapeOpt
|	BitExpr RegexpOrNotOp SimpleExpr
|	BitExpr

;
RegexpSym:
	'REGEXP'
|	'RLIKE'

;
LikeEscapeOpt:
	%prec empty
|	'ESCAPE' stringLit

;
Field:
	'*' %prec '*'
|	Identifier '.' '*' %prec '*'
|	Identifier '.' Identifier '.' '*' %prec '*'
|	Expression FieldAsNameOpt

;
FieldAsNameOpt:
|	FieldAsName

;
FieldAsName:
	Identifier
|	'AS' Identifier
|	stringLit
|	'AS' stringLit

;
FieldList:
	Field
|	FieldList ',' Field

;
GroupByClause:
	'GROUP' 'BY' ByList

;
HavingClause:
|	'HAVING' Expression

;
AsOfClauseOpt:
	%prec empty
|	AsOfClause

;
AsOfClause:
	asof 'TIMESTAMP' Expression

;
IfExists:
|	'IF' 'EXISTS'

;
IfNotExists:
|	'IF' NotSym 'EXISTS'

;
IgnoreOptional:
|	'IGNORE'

;
IndexName:
|	Identifier

;
IndexOptionList:
|	IndexOptionList IndexOption

;
IndexOption:
	'KEY_BLOCK_SIZE' EqOpt LengthNum
|	IndexType
|	'WITH' 'PARSER' Identifier
|	'COMMENT' stringLit
|	IndexInvisible
|	WithClustered


;
IndexNameAndTypeOpt:
	IndexName
|	IndexName 'USING' IndexTypeName
|	Identifier 'TYPE' IndexTypeName

;
IndexTypeOpt:
|	IndexType

;
IndexType:
	'USING' IndexTypeName
|	'TYPE' IndexTypeName

;
IndexTypeName:
	'BTREE'
|	'HASH'
|	'RTREE'

;
IndexInvisible:
	'VISIBLE'
|	'INVISIBLE'


;
Identifier:
	identifier
|	UnReservedKeyword
|	NotKeywordToken
|	TiDBKeyword

;
UnReservedKeyword:
	'ACTION'
|	'ADVISE'
|	'ASCII'
|	'ATTRIBUTES'
|	'BINDING_CACHE'
|	'STATS_OPTIONS'
|	'STATS_SAMPLE_RATE'
|	'STATS_COL_CHOICE'
|	'STATS_COL_LIST'
|	'AUTO_ID_CACHE'
|	'AUTO_INCREMENT'
|	'AFTER'
|	'ALWAYS'
|	'AVG'
|	'BEGIN'
|	'BIT'
|	'BOOL'
|	'BOOLEAN'
|	'BTREE'
|	'BYTE'
|	'CAPTURE'
|	'CAUSAL'
|	'CLEANUP'
|	'CHAIN'
|	'CHARSET'
|	'COLUMNS'
|	'CONFIG'
|	'SAN'
|	'COMMIT'
|	'COMPACT'
|	'COMPRESSED'
|	'CONSISTENCY'
|	'CONSISTENT'
|	'CURRENT'
|	'DATA'
|	'DATE' %prec lowerThanStringLitToken
|	'DATETIME'
|	'DAY'
|	'DEALLOCATE'
|	'DO'
|	'DUPLICATE'
|	'DYNAMIC'
|	'ENCRYPTION'
|	'END'
|	'ENFORCED'
|	'ENGINE'
|	'ENGINES'
|	'ENUM'
|	'ERROR'
|	'ERRORS'
|	'ESCAPE'
|	'EVOLVE'
|	'EXECUTE'
|	'EXTENDED'
|	'FIELDS'
|	'FILE'
|	'FIRST'
|	'FIXED'
|	'FLUSH'
|	'FOLLOWING'
|	'FORMAT'
|	'FULL'
|	'GENERAL'
|	'GLOBAL'
|	'HASH'
|	'HELP'
|	'HOUR'
|	'INSERT_METHOD'
|	'LESS'
|	'LOCAL'
|	'LAST'
|	'NAMES'
|	'NVARCHAR'
|	'OFFSET'
|	'PACK_KEYS'
|	'PARSER'
|	'PASSWORD' %prec lowerThanEq
|	'PREPARE'
|	'PRE_SPLIT_REGIONS'
|	'PROXY'
|	'QUICK'
|	'REBUILD'
|	'REDUNDANT'
|	'REORGANIZE'
|	'RESTART'
|	'ROLE'
|	'ROLLBACK'
|	'SESSION'
|	'SIGNED'
|	'SHARD_ROW_ID_BITS'
|	'SHUTDOWN'
|	'SNAPSHOT'
|	'START'
|	'STATUS'
|	'OPEN'
|	'SUBPARTITIONS'
|	'SUBPARTITION'
|	'TABLES'
|	'TABLESPACE'
|	'TEXT'
|	'THAN'
|	'TIME' %prec lowerThanStringLitToken
|	'TIMESTAMP' %prec lowerThanStringLitToken
|	'TRACE'
|	'TRANSACTION'
|	'TRUNCATE'
|	'UNBOUNDED'
|	'UNKNOWN'
|	'VALUE' %prec lowerThanValueKeyword
|	'WARNINGS'
|	'YEAR'
|	'MODE'
|	'WEEK'
|	'WEIGHT_STRING'
|	'ANY'
|	'SOME'
|	'USER'
|	'IDENTIFIED'
|	'COLLATION'
|	'COMMENT'
|	'AVG_ROW_LENGTH'
|	'CONNECTION'
|	'CHECKSUM'
|	'COMPRESSION'
|	'KEY_BLOCK_SIZE'
|	'MASTER'
|	'MAX_ROWS'
|	'MIN_ROWS'
|	'NATIONAL'
|	'NCHAR'
|	'ROW_FORMAT'
|	'QUARTER'
|	'GRANTS'
|	'TRIGGERS'
|	'DELAY_KEY_WRITE'
|	'ISOLATION'
|	'JSON'
|	'REPEATABLE'
|	'RESPECT'
|	'COMMITTED'
|	'UNCOMMITTED'
|	'ONLY'
|	'SERIAL'
|	'SERIALIZABLE'
|	'LEVEL'
|	'VARIABLES'
|	'SQL_CACHE'
|	'INDEXES'
|	'PROCESSLIST'
|	'SQL_NO_CACHE'
|	'DISABLE'
|	'DISABLED'
|	'ENABLE'
|	'ENABLED'
|	'REVERSE'
|	'PRIVILEGES'
|	'NO'
|	'BINLOG'
|	'FUNCTION'
|	'VIEW'
|	'BINDING'
|	'BINDINGS'
|	'MODIFY'
|	'EVENTS'
|	'PARTITIONS'
|	'NONE'
|	'NULLS'
|	'SUPER'
|	'EXCLUSIVE'
|	'STATS_PERSISTENT'
|	'STATS_AUTO_RECALC'
|	'ROW_COUNT'
|	'COALESCE'
|	'MONTH'
|	'PROCESS'
|	'PROFILE'
|	'PROFILES'
|	'MICROSECOND'
|	'MINUTE'
|	'PLUGINS'
|	'PRECEDING'
|	'QUERY'
|	'QUERIES'
|	'SECOND'
|	'SEPARATOR'
|	'SHARE'
|	'SHARED'
|	'SLOW'
|	'MAX_CONNECTIONS_PER_HOUR'
|	'MAX_QUERIES_PER_HOUR'
|	'MAX_UPDATES_PER_HOUR'
|	'MAX_USER_CONNECTIONS'
|	'REPLICATION'
|	'CLIENT'
|	'SLAVE'
|	'RELOAD'
|	'TEMPORARY'
|	'ROUTINE'
|	'EVENT'
|	'ALGORITHM'
|	'DEFINER'
|	'INVOKER'
|	'MERGE'
|	'TEMPTABLE'
|	'UNDEFINED'
|	'SECURITY'
|	'CASCADED'
|	'RECOVER'
|	'CIPHER'
|	'SUBJECT'
|	'ISSUER'
|	'X509'
|	'NEVER'
|	'EXPIRE'
|	'ACCOUNT'
|	'INCREMENTAL'
|	'CPU'
|	'MEMORY'
|	'BLOCK'
|	'IO'
|	'CONTEXT'
|	'SWITCHES'
|	'PAGE'
|	'FAULTS'
|	'IPC'
|	'SWAPS'
|	'SOURCE'
|	'TRADITIONAL'
|	'SQL_BUFFER_RESULT'
|	'DIRECTORY'
|	'HISTOGRAM'
|	'HISTORY'
|	'LIST'
|	'NODEGROUP'
|	'SYSTEM_TIME'
|	'PARTIAL'
|	'SIMPLE'
|	'REMOVE'
|	'PARTITIONING'
|	'STORAGE'
|	'DISK'
|	'STATS_SAMPLE_PAGES'
|	'SECONDARY_ENGINE'
|	'SECONDARY_LOAD'
|	'SECONDARY_UNLOAD'
|	'VALIDATION'
|	'WITHOUT'
|	'RTREE'
|	'EXCHANGE'
|	'COLUMN_FORMAT'
|	'REPAIR'
|	'IMPORT'
|	'IMPORTS'
|	'DISCARD'
|	'TABLE_CHECKSUM'
|	'UNICODE'
|	'AUTO_RANDOM'
|	'AUTO_RANDOM_BASE'
|	'SQL_TSI_DAY'
|	'SQL_TSI_HOUR'
|	'SQL_TSI_MINUTE'
|	'SQL_TSI_MONTH'
|	'SQL_TSI_QUARTER'
|	'SQL_TSI_SECOND'
|	'LANGUAGE'
|	'SQL_TSI_WEEK'
|	'SQL_TSI_YEAR'
|	'INVISIBLE'
|	'VISIBLE'
|	'TYPE'
|	'NOWAIT'
|	'INSTANCE'
|	'REPLICA'
|	'LOCATION'
|	'LABELS'
|	'LOGS'
|	'HOSTS'
|	'AGAINST'
|	'EXPANSION'
|	'INCREMENT'
|	'MINVALUE'
|	'NOMAXVALUE'
|	'NOMINVALUE'
|	'NOCACHE'
|	'CACHE'
|	'CYCLE'
|	'NOCYCLE'
|	'SEQUENCE'
|	'MAX_MINUTES'
|	'MAX_IDXNUM'
|	'PER_TABLE'
|	'PER_DB'
|	'NEXT'
|	'NEXTVAL'
|	'LASTVAL'
|	'SETVAL'
|	'AGO'
|	'BACKUP'
|	'BACKUPS'
|	'CONCURRENCY'
|	'MB'
|	'ONLINE'
|	'RATE_LIMIT'
|	'RESTORE'
|	'RESTORES'
|	'SEND_CREDENTIALS_TO_TIKV'
|	'LAST_BACKUP'
|	'CHECKPOINT'
|	'SKIP_SCHEMA_FILES'
|	'STRICT_FORMAT'
|	'BACKEND'
|	'CSV_BACKSLASH_ESCAPE'
|	'CSV_NOT_NULL'
|	'CSV_TRIM_LAST_SEPARATORS'
|	'CSV_DELIMITER'
|	'CSV_HEADER'
|	'CSV_NULL'
|	'CSV_SEPARATOR'
|	'ON_DUPLICATE'
|	'TIKV_IMPORTER'
|	'REPLICAS'
|	'POLICY'
|	'WAIT'
|	'CLIENT_ERRORS_SUMMARY'
|	'BERNOULLI'
|	'SYSTEM'
|	'PERCENT'
|	'RESUME'
|	'OFF'
|	'OPTIONAL'
|	'REQUIRED'
|	'PURGE'
|	'SKIP'
|	'LOCKED'
|	'CLUSTERED'
|	'NONCLUSTERED'
|	'PRESERVE'

;
TiDBKeyword:
	'ADMIN'
|	'BATCH'
|	'BUCKETS'
|	'BUILTINS'
|	'CANCEL'
|	'CARDINALITY'
|	'CMSKETCH'
|	'COLUMN_STATS_USAGE'
|	'CORRELATION'
|	'DDL'
|	'DEPENDENCY'
|	'DEPTH'
|	'DRAINER'
|	'JOBS'
|	'JOB'
|	'NODE_ID'
|	'NODE_STATE'
|	'PUMP'
|	'SAMPLES'
|	'SAMPLERATE'
|	'STATISTICS'
|	'STATS'
|	'STATS_META'
|	'STATS_HISTOGRAMS'
|	'STATS_TOPN'
|	'STATS_BUCKETS'
|	'STATS_HEALTHY'
|	'HISTOGRAMS_IN_FLIGHT'
|	'TELEMETRY'
|	'TELEMETRY_ID'
|	'TIDB'
|	'TIFLASH'
|	'TOPN'
|	'SPLIT'
|	'OPTIMISTIC'
|	'PESSIMISTIC'
|	'WIDTH'
|	'REGIONS'
|	'REGION'
|	'RESET'
|	'DRY'
|	'RUN'

;
NotKeywordToken:
	'ADDDATE'
|	'APPROX_COUNT_DISTINCT'
|	'APPROX_PERCENTILE'
|	'BIT_AND'
|	'BIT_OR'
|	'BIT_XOR'
|	'BRIEF'
|	'CAST'
|	'COPY'
|	'CURTIME'
|	'DATE_ADD'
|	'DATE_SUB'
|	'DOT'
|	'DUMP'
|	'EXTRACT'
|	'GET_FORMAT'
|	'GROUP_CONCAT'
|	'INPLACE'
|	'INSTANT'
|	'INTERNAL'
|	'MIN'
|	'MAX'
|	'NOW'
|	'RECENT'
|	'REPLAYER'
|	'RUNNING'
|	'PLACEMENT'
|	'PLAN'
|	'PLAN_CACHE'
|	'POSITION'
|	'PREDICATE'
|	'S3'
|	'STRICT'
|	'SUBDATE'
|	'SUBSTRING'
|	'SUM'
|	'STD'
|	'STDDEV'
|	'STDDEV_POP'
|	'STDDEV_SAMP'
|	'STOP'
|	'VARIANCE'
|	'VAR_POP'
|	'VAR_SAMP'
|	'TARGET'
|	'TIMESTAMPADD'
|	'TIMESTAMPDIFF'
|	'TOKUDB_DEFAULT'
|	'TOKUDB_FAST'
|	'TOKUDB_LZMA'
|	'TOKUDB_QUICKLZ'
|	'TOKUDB_SNAPPY'
|	'TOKUDB_SMALL'
|	'TOKUDB_UNCOMPRESSED'
|	'TOKUDB_ZLIB'
|	'TOP'
|	'TRIM'
|	'NEXT_ROW_ID'
|	'EXPR_PUSHDOWN_BLACKLIST'
|	'OPT_RULE_BLACKLIST'
|	'BOUND'
|	'EXACT' %prec lowerThanStringLitToken
|	'STALENESS'
|	'STRONG'
|	'FLASHBACK'
|	'JSON_OBJECTAGG'
|	'JSON_ARRAYAGG'
|	'TLS'
|	'FOLLOWER'
|	'FOLLOWERS'
|	'LEADER'
|	'LEARNER'
|	'LEARNERS'
|	'VERBOSE'
|	'TRUE_CARD_COST'
|	'VOTER'
|	'VOTERS'
|	'CONSTRAINTS'
|	'PRIMARY_REGION'
|	'SCHEDULE'
|	'LEADER_CONSTRAINTS'
|	'FOLLOWER_CONSTRAINTS'
|	'LEARNER_CONSTRAINTS'
|	'VOTER_CONSTRAINTS'


;
CallStmt:
	'CALL' ProcedureCall

;
ProcedureCall:
	identifier
|	Identifier '.' Identifier
|	identifier '(' ExpressionListOpt ')'
|	Identifier '.' Identifier '(' ExpressionListOpt ')'


;
InsertIntoStmt:
	'INSERT' TableOptimizerHintsOpt PriorityOpt IgnoreOptional IntoOpt TableName PartitionNameListOpt InsertValues OnDuplicateKeyUpdate

;
IntoOpt:
|	'INTO'

;
InsertValues:
	'(' ColumnNameListOpt ')' ValueSym ValuesList
|	'(' ColumnNameListOpt ')' SetOprStmt
|	'(' ColumnNameListOpt ')' SelectStmt
|	'(' ColumnNameListOpt ')' SelectStmtWithClause
|	'(' ColumnNameListOpt ')' SubSelect
|	ValueSym ValuesList %prec insertValues
|	SetOprStmt
|	SelectStmt
|	SelectStmtWithClause
|	SubSelect
|	'SET' ColumnSetValueList

;
ValueSym:
	'VALUE'
|	'VALUES'

;
ValuesList:
	RowValue
|	ValuesList ',' RowValue

;
RowValue:
	'(' ValuesOpt ')'

;
ValuesOpt:
|	Values

;
Values:
	Values ',' ExprOrDefault
|	ExprOrDefault

;
ExprOrDefault:
	Expression
|	'DEFAULT'

;
ColumnSetValue:
	ColumnName eq ExprOrDefault

;
ColumnSetValueList:
|	ColumnSetValue
|	ColumnSetValueList ',' ColumnSetValue


;
OnDuplicateKeyUpdate:
|	'ON' 'DUPLICATE' 'KEY' 'UPDATE' AssignmentList


;
ReplaceIntoStmt:
	'REPLACE' PriorityOpt IntoOpt TableName PartitionNameListOpt InsertValues

;
Literal:
	'FALSE'
|	'NULL'
|	'TRUE'
|	floatLit
|	decLit
|	intLit
|	StringLiteral %prec lowerThanStringLitToken
|	'UNDERSCORE_CHARSET' stringLit
|	hexLit
|	bitLit
|	'UNDERSCORE_CHARSET' hexLit
|	'UNDERSCORE_CHARSET' bitLit

;
StringLiteral:
	stringLit
|	StringLiteral stringLit

;
AlterOrderList:
	AlterOrderItem
|	AlterOrderList ',' AlterOrderItem

;
AlterOrderItem:
	ColumnName OptOrder

;
OrderBy:
	'ORDER' 'BY' ByList

;
ByList:
	ByItem
|	ByList ',' ByItem

;
ByItem:
	Expression
|	Expression Order

;
Order:
	'ASC'
|	'DESC'

;
OptOrder:
|	'ASC'
|	'DESC'

;
OrderByOptional:
|	OrderBy

;
BitExpr:
	BitExpr '|' BitExpr %prec '|'
|	BitExpr '&' BitExpr %prec '&'
|	BitExpr '<<' BitExpr %prec lsh
|	BitExpr '>>' BitExpr %prec rsh
|	BitExpr '+' BitExpr %prec '+'
|	BitExpr '-' BitExpr %prec '-'
|	BitExpr '+' 'INTERVAL' Expression TimeUnit %prec '+'
|	BitExpr '-' 'INTERVAL' Expression TimeUnit %prec '+'
|	BitExpr '*' BitExpr %prec '*'
|	BitExpr '/' BitExpr %prec '/'
|	BitExpr '%' BitExpr %prec '%'
|	BitExpr 'DIV' BitExpr %prec div
|	BitExpr 'MOD' BitExpr %prec mod
|	BitExpr '^' BitExpr
|	SimpleExpr

;
SimpleIdent:
	Identifier
|	Identifier '.' Identifier
|	Identifier '.' Identifier '.' Identifier

;
SimpleExpr:
	SimpleIdent
|	FunctionCallKeyword
|	FunctionCallNonKeyword
|	FunctionCallGeneric
|	SimpleExpr 'COLLATE' CollationName
|	WindowFuncCall
|	Literal
|	paramMarker
|	Variable
|	SumExpr
|	'!' SimpleExpr %prec neg
|	'~' SimpleExpr %prec neg
|	'-' SimpleExpr %prec neg
|	'+' SimpleExpr %prec neg
|	SimpleExpr pipes SimpleExpr
|	not2 SimpleExpr %prec neg
|	SubSelect %prec neg
|	'(' Expression ')'
|	'(' ExpressionList ',' Expression ')'
|	'ROW' '(' ExpressionList ',' Expression ')'
|	'EXISTS' SubSelect
|	''
|	'BINARY' SimpleExpr %prec neg
|	builtinCast '(' Expression 'AS' CastType ')'
|	'CASE' ExpressionOpt WhenClauseList ElseOpt 'END'
|	'CONVERT' '(' Expression ',' CastType ')'
|	'CONVERT' '(' Expression 'USING' CharsetName ')'
|	'DEFAULT' '(' SimpleIdent ')'
|	'VALUES' '(' SimpleIdent ')' %prec lowerThanInsertValues
|	SimpleIdent jss stringLit
|	SimpleIdent juss stringLit

;
DistinctKwd:
	'DISTINCT'
|	'DISTINCTROW'

;
DistinctOpt:
	'ALL'
|	DistinctKwd

;
DefaultFalseDistinctOpt:
|	DistinctOpt

;
DefaultTrueDistinctOpt:
|	DistinctOpt

;
BuggyDefaultFalseDistinctOpt:
	DefaultFalseDistinctOpt
|	DistinctKwd 'ALL'

;
FunctionNameConflict:
	'ASCII'
|	'CHARSET'
|	'COALESCE'
|	'COLLATION'
|	'DATE'
|	'DATABASE'
|	'DAY'
|	'HOUR'
|	'IF'
|	'INTERVAL'
|	'FORMAT'
|	'LEFT'
|	'MICROSECOND'
|	'MINUTE'
|	'MONTH'
|	builtinNow
|	'QUARTER'
|	'REPEAT'
|	'REPLACE'
|	'REVERSE'
|	'RIGHT'
|	'ROW_COUNT'
|	'SECOND'
|	'TIME'
|	'TIMESTAMP'
|	'TRUNCATE'
|	'USER'
|	'WEEK'
|	'YEAR'

;
OptionalBraces:
|	'(' ')'

;
FunctionNameOptionalBraces:
	'CURRENT_USER'
|	'CURRENT_DATE'
|	'CURRENT_ROLE'
|	'UTC_DATE'

;
FunctionNameDatetimePrecision:
	'CURRENT_TIME'
|	'CURRENT_TIMESTAMP'
|	'LOCALTIME'
|	'LOCALTIMESTAMP'
|	'UTC_TIME'
|	'UTC_TIMESTAMP'

;
FunctionCallKeyword:
	FunctionNameConflict '(' ExpressionListOpt ')'
|	builtinUser '(' ExpressionListOpt ')'
|	FunctionNameOptionalBraces OptionalBraces
|	builtinCurDate '(' ')'
|	FunctionNameDatetimePrecision FuncDatetimePrec
|	'CHAR' '(' ExpressionList ')'
|	'CHAR' '(' ExpressionList 'USING' CharsetName ')'
|	'DATE' stringLit
|	'TIME' stringLit
|	'TIMESTAMP' stringLit
|	'INSERT' '(' ExpressionListOpt ')'
|	'MOD' '(' BitExpr ',' BitExpr ')'
|	'PASSWORD' '(' ExpressionListOpt ')'

;
FunctionCallNonKeyword:
	builtinCurTime '(' FuncDatetimePrecListOpt ')'
|	builtinSysDate '(' FuncDatetimePrecListOpt ')'
|	FunctionNameDateArithMultiForms '(' Expression ',' Expression ')'
|	FunctionNameDateArithMultiForms '(' Expression ',' 'INTERVAL' Expression TimeUnit ')'
|	FunctionNameDateArith '(' Expression ',' 'INTERVAL' Expression TimeUnit ')'
|	builtinExtract '(' TimeUnit 'FROM' Expression ')'
|	'GET_FORMAT' '(' GetFormatSelector ',' Expression ')'
|	builtinPosition '(' BitExpr 'IN' Expression ')'
|	builtinSubstring '(' Expression ',' Expression ')'
|	builtinSubstring '(' Expression 'FROM' Expression ')'
|	builtinSubstring '(' Expression ',' Expression ',' Expression ')'
|	builtinSubstring '(' Expression 'FROM' Expression 'FOR' Expression ')'
|	'TIMESTAMPADD' '(' TimestampUnit ',' Expression ',' Expression ')'
|	'TIMESTAMPDIFF' '(' TimestampUnit ',' Expression ',' Expression ')'
|	builtinTrim '(' Expression ')'
|	builtinTrim '(' Expression 'FROM' Expression ')'
|	builtinTrim '(' TrimDirection 'FROM' Expression ')'
|	builtinTrim '(' TrimDirection Expression 'FROM' Expression ')'
|	weightString '(' Expression ')'
|	weightString '(' Expression 'AS' Char FieldLen ')'
|	weightString '(' Expression 'AS' 'BINARY' FieldLen ')'
|	FunctionNameSequence
|	builtinTranslate '(' Expression ',' Expression ',' Expression ')'

;
GetFormatSelector:
	'DATE'
|	'DATETIME'
|	'TIME'
|	'TIMESTAMP'

;
FunctionNameDateArith:
	builtinDateAdd
|	builtinDateSub

;
FunctionNameDateArithMultiForms:
	addDate
|	subDate

;
TrimDirection:
	'BOTH'
|	'LEADING'
|	'TRAILING'

;
FunctionNameSequence:
	'LASTVAL' '(' TableName ')'
|	'SETVAL' '(' TableName ',' SignedNum ')'
|	NextValueForSequence

;
SumExpr:
	'AVG' '(' BuggyDefaultFalseDistinctOpt Expression ')' OptWindowingClause
|	builtinApproxCountDistinct '(' ExpressionList ')'
|	builtinApproxPercentile '(' ExpressionList ')'
|	builtinBitAnd '(' Expression ')' OptWindowingClause
|	builtinBitAnd '(' 'ALL' Expression ')' OptWindowingClause
|	builtinBitOr '(' Expression ')' OptWindowingClause
|	builtinBitOr '(' 'ALL' Expression ')' OptWindowingClause
|	builtinBitXor '(' Expression ')' OptWindowingClause
|	builtinBitXor '(' 'ALL' Expression ')' OptWindowingClause
|	builtinCount '(' DistinctKwd ExpressionList ')'
|	builtinCount '(' 'ALL' Expression ')' OptWindowingClause
|	builtinCount '(' Expression ')' OptWindowingClause
|	builtinCount '(' '*' ')' OptWindowingClause
|	builtinGroupConcat '(' BuggyDefaultFalseDistinctOpt ExpressionList OrderByOptional OptGConcatSeparator ')' OptWindowingClause
|	builtinMax '(' BuggyDefaultFalseDistinctOpt Expression ')' OptWindowingClause
|	builtinMin '(' BuggyDefaultFalseDistinctOpt Expression ')' OptWindowingClause
|	builtinSum '(' BuggyDefaultFalseDistinctOpt Expression ')' OptWindowingClause
|	builtinStddevPop '(' BuggyDefaultFalseDistinctOpt Expression ')' OptWindowingClause
|	builtinStddevSamp '(' BuggyDefaultFalseDistinctOpt Expression ')' OptWindowingClause
|	builtinVarPop '(' BuggyDefaultFalseDistinctOpt Expression ')' OptWindowingClause
|	builtinVarSamp '(' BuggyDefaultFalseDistinctOpt Expression ')' OptWindowingClause
|	'JSON_ARRAYAGG' '(' Expression ')' OptWindowingClause
|	'JSON_ARRAYAGG' '(' 'ALL' Expression ')' OptWindowingClause
|	'JSON_OBJECTAGG' '(' Expression ',' Expression ')' OptWindowingClause
|	'JSON_OBJECTAGG' '(' 'ALL' Expression ',' Expression ')' OptWindowingClause
|	'JSON_OBJECTAGG' '(' Expression ',' 'ALL' Expression ')' OptWindowingClause
|	'JSON_OBJECTAGG' '(' 'ALL' Expression ',' 'ALL' Expression ')' OptWindowingClause

;
OptGConcatSeparator:
|	'SEPARATOR' stringLit

;
FunctionCallGeneric:
	identifier '(' ExpressionListOpt ')'
|	Identifier '.' Identifier '(' ExpressionListOpt ')'

;
FuncDatetimePrec:
|	'(' ')'
|	'(' intLit ')'

;
TimeUnit:
	TimestampUnit
|	'SECOND_MICROSECOND'
|	'MINUTE_MICROSECOND'
|	'MINUTE_SECOND'
|	'HOUR_MICROSECOND'
|	'HOUR_SECOND'
|	'HOUR_MINUTE'
|	'DAY_MICROSECOND'
|	'DAY_SECOND'
|	'DAY_MINUTE'
|	'DAY_HOUR'
|	'YEAR_MONTH'

;
TimestampUnit:
	'MICROSECOND'
|	'SECOND'
|	'MINUTE'
|	'HOUR'
|	'DAY'
|	'WEEK'
|	'MONTH'
|	'QUARTER'
|	'YEAR'
|	'SQL_TSI_SECOND'
|	'SQL_TSI_MINUTE'
|	'SQL_TSI_HOUR'
|	'SQL_TSI_DAY'
|	'SQL_TSI_WEEK'
|	'SQL_TSI_MONTH'
|	'SQL_TSI_QUARTER'
|	'SQL_TSI_YEAR'

;
ExpressionOpt:
|	Expression

;
WhenClauseList:
	WhenClause
|	WhenClauseList WhenClause

;
WhenClause:
	'WHEN' Expression 'THEN' Expression

;
ElseOpt:
|	'ELSE' Expression

;
CastType:
	'BINARY' OptFieldLen
|	Char OptFieldLen OptBinary
|	'DATE'
|	'YEAR'
|	'DATETIME' OptFieldLen
|	'DECIMAL' FloatOpt
|	'TIME' OptFieldLen
|	'SIGNED' OptInteger
|	'UNSIGNED' OptInteger
|	'JSON'
|	'DOUBLE'
|	'FLOAT' FloatOpt
|	'REAL'

;
Priority:
	'LOW_PRIORITY'
|	'HIGH_PRIORITY'
|	'DELAYED'

;
PriorityOpt:
|	Priority

;
TableName:
	Identifier
|	Identifier '.' Identifier

;
TableNameList:
	TableName
|	TableNameList ',' TableName

;
TableNameOptWild:
	Identifier OptWild
|	Identifier '.' Identifier OptWild

;
TableAliasRefList:
	TableNameOptWild
|	TableAliasRefList ',' TableNameOptWild

;
OptWild:
	%prec empty
|	'.' '*'

;
QuickOptional:
	%prec empty
|	'QUICK'


;
PreparedStmt:
	'PREPARE' Identifier 'FROM' PrepareSQL

;
PrepareSQL:
	stringLit
|	UserVariable


;
ExecuteStmt:
	'EXECUTE' Identifier
|	'EXECUTE' Identifier 'USING' UserVariableList

;
UserVariableList:
	UserVariable
|	UserVariableList ',' UserVariable

;
DeallocateStmt:
	DeallocateSym 'PREPARE' Identifier

;
DeallocateSym:
	'DEALLOCATE'
|	'DROP'

;
RollbackStmt:
	'ROLLBACK'
|	'ROLLBACK' CompletionTypeWithinTransaction

;
CompletionTypeWithinTransaction:
	'AND' 'CHAIN' 'NO' 'RELEASE'
|	'AND' 'NO' 'CHAIN' 'RELEASE'
|	'AND' 'NO' 'CHAIN' 'NO' 'RELEASE'
|	'AND' 'CHAIN'
|	'AND' 'NO' 'CHAIN'
|	'RELEASE'
|	'NO' 'RELEASE'

;
ShutdownStmt:
	'SHUTDOWN'

;
RestartStmt:
	'RESTART'

;
HelpStmt:
	'HELP' stringLit

;
SelectStmtBasic:
	'SELECT' SelectStmtOpts SelectStmtFieldList

;
SelectStmtFromDualTable:
	SelectStmtBasic FromDual WhereClauseOptional

;
SelectStmtFromTable:
	SelectStmtBasic 'FROM' TableRefsClause WhereClauseOptional SelectStmtGroup HavingClause WindowClauseOptional

;
TableSampleOpt:
	%prec empty
|	'TABLESAMPLE' TableSampleMethodOpt '(' Expression TableSampleUnitOpt ')' RepeatableOpt
|	'TABLESAMPLE' TableSampleMethodOpt '(' ')' RepeatableOpt

;
TableSampleMethodOpt:
	%prec empty
|	'SYSTEM'
|	'BERNOULLI'
|	'REGIONS'

;
TableSampleUnitOpt:
	%prec empty
|	'ROWS'
|	'PERCENT'

;
RepeatableOpt:
	%prec empty
|	'REPEATABLE' '(' Expression ')'

;
SelectStmt:
	SelectStmtBasic WhereClauseOptional SelectStmtGroup OrderByOptional SelectStmtLimitOpt SelectLockOpt SelectStmtIntoOption
|	SelectStmtFromDualTable SelectStmtGroup OrderByOptional SelectStmtLimitOpt SelectLockOpt SelectStmtIntoOption
|	SelectStmtFromTable OrderByOptional SelectStmtLimitOpt SelectLockOpt SelectStmtIntoOption
|	'TABLE' TableName OrderByOptional SelectStmtLimitOpt SelectLockOpt SelectStmtIntoOption
|	'VALUES' ValuesStmtList OrderByOptional SelectStmtLimitOpt SelectLockOpt SelectStmtIntoOption

;
SelectStmtWithClause:
	WithClause SelectStmt
|	WithClause SubSelect

;
WithClause:
	'WITH' WithList
|	'WITH' 'RECURSIVE' WithList

;
WithList:
	WithList ',' CommonTableExpr
|	CommonTableExpr

;
CommonTableExpr:
	Identifier IdentListWithParenOpt 'AS' SubSelect

;
FromDual:
	'FROM' 'DUAL'

;
WindowClauseOptional:
|	'WINDOW' WindowDefinitionList

;
WindowDefinitionList:
	WindowDefinition
|	WindowDefinitionList ',' WindowDefinition

;
WindowDefinition:
	WindowName 'AS' WindowSpec

;
WindowName:
	Identifier

;
WindowSpec:
	'(' WindowSpecDetails ')'

;
WindowSpecDetails:
	OptExistingWindowName OptPartitionClause OptWindowOrderByClause OptWindowFrameClause

;
OptExistingWindowName:
|	WindowName

;
OptPartitionClause:
|	'PARTITION' 'BY' ByList

;
OptWindowOrderByClause:
|	'ORDER' 'BY' ByList

;
OptWindowFrameClause:
|	WindowFrameUnits WindowFrameExtent

;
WindowFrameUnits:
	'ROWS'
|	'RANGE'
|	'GROUPS'

;
WindowFrameExtent:
	WindowFrameStart
|	WindowFrameBetween

;
WindowFrameStart:
	'UNBOUNDED' 'PRECEDING'
|	NumLiteral 'PRECEDING'
|	paramMarker 'PRECEDING'
|	'INTERVAL' Expression TimeUnit 'PRECEDING'
|	'CURRENT' 'ROW'

;
WindowFrameBetween:
	'BETWEEN' WindowFrameBound 'AND' WindowFrameBound

;
WindowFrameBound:
	WindowFrameStart
|	'UNBOUNDED' 'FOLLOWING'
|	NumLiteral 'FOLLOWING'
|	paramMarker 'FOLLOWING'
|	'INTERVAL' Expression TimeUnit 'FOLLOWING'

;
OptWindowingClause:
|	WindowingClause

;
WindowingClause:
	'OVER' WindowNameOrSpec

;
WindowNameOrSpec:
	WindowName
|	WindowSpec

;
WindowFuncCall:
	'ROW_NUMBER' '(' ')' WindowingClause
|	'RANK' '(' ')' WindowingClause
|	'DENSE_RANK' '(' ')' WindowingClause
|	'CUME_DIST' '(' ')' WindowingClause
|	'PERCENT_RANK' '(' ')' WindowingClause
|	'NTILE' '(' SimpleExpr ')' WindowingClause
|	'LEAD' '(' Expression OptLeadLagInfo ')' OptNullTreatment WindowingClause
|	'LAG' '(' Expression OptLeadLagInfo ')' OptNullTreatment WindowingClause
|	'FIRST_VALUE' '(' Expression ')' OptNullTreatment WindowingClause
|	'LAST_VALUE' '(' Expression ')' OptNullTreatment WindowingClause
|	'NTH_VALUE' '(' Expression ',' SimpleExpr ')' OptFromFirstLast OptNullTreatment WindowingClause

;
OptLeadLagInfo:
|	',' NumLiteral OptLLDefault
|	',' paramMarker OptLLDefault

;
OptLLDefault:
|	',' Expression

;
OptNullTreatment:
|	'RESPECT' 'NULLS'
|	'IGNORE' 'NULLS'

;
OptFromFirstLast:
|	'FROM' 'FIRST'
|	'FROM' 'LAST'

;
TableRefsClause:
	TableRefs

;
TableRefs:
	EscapedTableRef
|	TableRefs ',' EscapedTableRef

;
EscapedTableRef:
	TableRef %prec lowerThanSetKeyword
|	''

;
TableRef:
	TableFactor
|	JoinTable

;
TableFactor:
	TableName PartitionNameListOpt TableAsNameOpt AsOfClauseOpt IndexHintListOpt TableSampleOpt
|	SubSelect TableAsNameOpt
|	'(' TableRefs ')'

;
PartitionNameListOpt:
|	'PARTITION' '(' PartitionNameList ')'

;
TableAsNameOpt:
	%prec empty
|	TableAsName

;
TableAsName:
	Identifier
|	'AS' Identifier

;
IndexHintType:
	'USE' KeyOrIndex
|	'IGNORE' KeyOrIndex
|	'FORCE' KeyOrIndex

;
IndexHintScope:
|	'FOR' 'JOIN'
|	'FOR' 'ORDER' 'BY'
|	'FOR' 'GROUP' 'BY'

;
IndexHint:
	IndexHintType IndexHintScope '(' IndexNameList ')'

;
IndexNameList:
|	Identifier
|	IndexNameList ',' Identifier
|	'PRIMARY'
|	IndexNameList ',' 'PRIMARY'

;
IndexHintList:
	IndexHint
|	IndexHintList IndexHint

;
IndexHintListOpt:
|	IndexHintList

;
JoinTable:
	TableRef CrossOpt TableRef %prec tableRefPriority
|	TableRef CrossOpt TableRef 'ON' Expression
|	TableRef CrossOpt TableRef 'USING' '(' ColumnNameList ')'
|	TableRef JoinType OuterOpt 'JOIN' TableRef 'ON' Expression
|	TableRef JoinType OuterOpt 'JOIN' TableRef 'USING' '(' ColumnNameList ')'
|	TableRef 'NATURAL' 'JOIN' TableRef
|	TableRef 'NATURAL' JoinType OuterOpt 'JOIN' TableRef
|	TableRef 'STRAIGHT_JOIN' TableRef
|	TableRef 'STRAIGHT_JOIN' TableRef 'ON' Expression

;
JoinType:
	'LEFT'
|	'RIGHT'

;
OuterOpt:
|	'OUTER'

;
CrossOpt:
	'JOIN'
|	'CROSS' 'JOIN'
|	'INNER' 'JOIN'

;
LimitClause:
|	'LIMIT' LimitOption

;
LimitOption:
	LengthNum
|	paramMarker

;
RowOrRows:
	'ROW'
|	'ROWS'

;
FirstOrNext:
	'FIRST'
|	'NEXT'

;
FetchFirstOpt:
|	LimitOption

;
SelectStmtLimit:
	'LIMIT' LimitOption
|	'LIMIT' LimitOption ',' LimitOption
|	'LIMIT' LimitOption 'OFFSET' LimitOption
|	'FETCH' FirstOrNext FetchFirstOpt RowOrRows 'ONLY'

;
SelectStmtLimitOpt:
|	SelectStmtLimit

;
SelectStmtOpt:
	TableOptimizerHints
|	DistinctOpt
|	Priority
|	'SQL_SMALL_RESULT'
|	'SQL_BIG_RESULT'
|	'SQL_BUFFER_RESULT'
|	SelectStmtSQLCache
|	'SQL_CALC_FOUND_ROWS'
|	'STRAIGHT_JOIN'

;
SelectStmtOpts:
	%prec empty
|	SelectStmtOptsList %prec lowerThanSelectOpt

;
SelectStmtOptsList:
	SelectStmtOptsList SelectStmtOpt
|	SelectStmtOpt

;
TableOptimizerHints:
	hintComment

;
TableOptimizerHintsOpt:
|	TableOptimizerHints

;
SelectStmtSQLCache:
	'SQL_CACHE'
|	'SQL_NO_CACHE'

;
SelectStmtFieldList:
	FieldList

;
SelectStmtGroup:
|	GroupByClause

;
SelectStmtIntoOption:
|	'INTO' 'OUTFILE' stringLit Fields Lines

// See https://dev.mysql.com/doc/refman/5.7/en/subqueries.html
;
SubSelect:
	'(' SelectStmt ')'
|	'(' SetOprStmt ')'
|	'(' SelectStmtWithClause ')'
|	'(' SubSelect ')'

// See https://dev.mysql.com/doc/refman/8.0/en/innodb-locking-reads.html
;
SelectLockOpt:
|	'FOR' 'UPDATE' OfTablesOpt
|	'FOR' 'SHARE' OfTablesOpt
|	'FOR' 'UPDATE' OfTablesOpt 'NOWAIT'
|	'FOR' 'UPDATE' OfTablesOpt 'WAIT' NUM
|	'FOR' 'SHARE' OfTablesOpt 'NOWAIT'
|	'FOR' 'UPDATE' OfTablesOpt 'SKIP' 'LOCKED'
|	'FOR' 'SHARE' OfTablesOpt 'SKIP' 'LOCKED'
|	'LOCK' 'IN' 'SHARE' 'MODE'

;
OfTablesOpt:
|	'OF' TableNameList

;
SetOprStmt:
	SetOprStmtWoutLimitOrderBy
|	SetOprStmtWithLimitOrderBy
|	WithClause SetOprStmtWithLimitOrderBy
|	WithClause SetOprStmtWoutLimitOrderBy

// See https://dev.mysql.com/doc/refman/5.7/en/union.html
// See https://mariadb.com/kb/en/intersect/
// See https://mariadb.com/kb/en/except/
;
SetOprStmtWoutLimitOrderBy:
	SetOprClauseList SetOpr SelectStmt
|	SetOprClauseList SetOpr SubSelect

;
SetOprStmtWithLimitOrderBy:
	SetOprClauseList SetOpr SubSelect OrderBy
|	SetOprClauseList SetOpr SubSelect SelectStmtLimit
|	SetOprClauseList SetOpr SubSelect OrderBy SelectStmtLimit
|	SubSelect OrderBy
|	SubSelect SelectStmtLimit
|	SubSelect OrderBy SelectStmtLimit

;
SetOprClauseList:
	SetOprClause
|	SetOprClauseList SetOpr SetOprClause

;
SetOprClause:
	SelectStmt
|	SubSelect

;
SetOpr:
	'UNION' SetOprOpt
|	'EXCEPT' SetOprOpt
|	'INTERSECT' SetOprOpt

;
SetOprOpt:
	DefaultTrueDistinctOpt


;
ChangeStmt:
	'CHANGE' 'PUMP' 'TO' 'NODE_STATE' eq stringLit forKwd 'NODE_ID' stringLit
|	'CHANGE' 'DRAINER' 'TO' 'NODE_STATE' eq stringLit forKwd 'NODE_ID' stringLit


;
SetStmt:
	'SET' VariableAssignmentList
|	'SET' 'PASSWORD' eq PasswordOpt
|	'SET' 'PASSWORD' 'FOR' Username eq PasswordOpt
|	'SET' 'GLOBAL' 'TRANSACTION' TransactionChars
|	'SET' 'SESSION' 'TRANSACTION' TransactionChars
|	'SET' 'TRANSACTION' TransactionChars
|	'SET' 'CONFIG' Identifier ConfigItemName EqOrAssignmentEq SetExpr
|	'SET' 'CONFIG' stringLit ConfigItemName EqOrAssignmentEq SetExpr

;
SetRoleStmt:
	'SET' 'ROLE' SetRoleOpt

;
SetDefaultRoleStmt:
	'SET' 'DEFAULT' 'ROLE' SetDefaultRoleOpt 'TO' UsernameList

;
SetDefaultRoleOpt:
	'NONE'
|	'ALL'
|	RolenameList

;
SetRoleOpt:
	'ALL' 'EXCEPT' RolenameList
|	SetDefaultRoleOpt
|	'DEFAULT'

;
TransactionChars:
	TransactionChar
|	TransactionChars ',' TransactionChar

;
TransactionChar:
	'ISOLATION' 'LEVEL' IsolationLevel
|	'READ' 'WRITE'
|	'READ' 'ONLY'
|	'READ' 'ONLY' AsOfClause

;
IsolationLevel:
	'REPEATABLE' 'READ'
|	'READ' 'COMMITTED'
|	'READ' 'UNCOMMITTED'
|	'SERIALIZABLE'

;
SetExpr:
	'ON'
|	'BINARY'
|	ExprOrDefault

;
EqOrAssignmentEq:
	eq
|	assignmentEq

;
VariableName:
	Identifier
|	Identifier '.' Identifier

;
ConfigItemName:
	Identifier
|	Identifier '.' ConfigItemName
|	Identifier '-' ConfigItemName

;
VariableAssignment:
	VariableName EqOrAssignmentEq SetExpr
|	'GLOBAL' VariableName EqOrAssignmentEq SetExpr
|	'SESSION' VariableName EqOrAssignmentEq SetExpr
|	'LOCAL' VariableName EqOrAssignmentEq SetExpr
|	doubleAtIdentifier EqOrAssignmentEq SetExpr
|	singleAtIdentifier EqOrAssignmentEq Expression
|	'NAMES' CharsetName
|	'NAMES' CharsetName 'COLLATE' 'DEFAULT'
|	'NAMES' CharsetName 'COLLATE' StringName
|	'NAMES' 'DEFAULT'
|	CharsetKw CharsetNameOrDefault

;
CharsetNameOrDefault:
	CharsetName
|	'DEFAULT'

;
CharsetName:
	StringName
|	binaryType

;
CollationName:
	StringName
|	binaryType

;
VariableAssignmentList:
	VariableAssignment
|	VariableAssignmentList ',' VariableAssignment

;
Variable:
	SystemVariable
|	UserVariable

;
SystemVariable:
	doubleAtIdentifier

;
UserVariable:
	singleAtIdentifier

;
Username:
	StringName
|	StringName '@' StringName
|	StringName singleAtIdentifier
|	'CURRENT_USER' OptionalBraces

;
UsernameList:
	Username
|	UsernameList ',' Username

;
PasswordOpt:
	stringLit
|	'PASSWORD' '(' AuthString ')'

;
AuthString:
	stringLit

;
RoleNameString:
	stringLit
|	identifier

;
RolenameComposed:
	StringName '@' StringName
|	StringName singleAtIdentifier

;
RolenameWithoutIdent:
	stringLit
|	RolenameComposed

;
Rolename:
	RoleNameString
|	RolenameComposed

;
RolenameList:
	Rolename
|	RolenameList ',' Rolename


;
AdminStmt:
	'ADMIN' 'SHOW' 'DDL'
|	'ADMIN' 'SHOW' 'DDL' 'JOBS' WhereClauseOptional
|	'ADMIN' 'SHOW' 'DDL' 'JOBS' Int64Num WhereClauseOptional
|	'ADMIN' 'SHOW' TableName 'NEXT_ROW_ID'
|	'ADMIN' 'CHECK' 'TABLE' TableNameList
|	'ADMIN' 'CHECK' 'INDEX' TableName Identifier
|	'ADMIN' 'RECOVER' 'INDEX' TableName Identifier
|	'ADMIN' 'CLEANUP' 'INDEX' TableName Identifier
|	'ADMIN' 'CHECK' 'INDEX' TableName Identifier HandleRangeList
|	'ADMIN' 'CHECKSUM' 'TABLE' TableNameList
|	'ADMIN' 'CANCEL' 'DDL' 'JOBS' NumList
|	'ADMIN' 'SHOW' 'DDL' 'JOB' 'QUERIES' NumList
|	'ADMIN' 'SHOW' 'SLOW' AdminShowSlow
|	'ADMIN' 'RELOAD' 'EXPR_PUSHDOWN_BLACKLIST'
|	'ADMIN' 'RELOAD' 'OPT_RULE_BLACKLIST'
|	'ADMIN' 'PLUGINS' 'ENABLE' PluginNameList
|	'ADMIN' 'PLUGINS' 'DISABLE' PluginNameList
|	'ADMIN' 'CLEANUP' 'TABLE' 'LOCK' TableNameList
|	'ADMIN' 'REPAIR' 'TABLE' TableName CreateTableStmt
|	'ADMIN' 'FLUSH' 'BINDINGS'
|	'ADMIN' 'CAPTURE' 'BINDINGS'
|	'ADMIN' 'EVOLVE' 'BINDINGS'
|	'ADMIN' 'RELOAD' 'BINDINGS'
|	'ADMIN' 'RELOAD' 'STATS_EXTENDED'
|	'ADMIN' 'RELOAD' 'STATISTICS'
|	'ADMIN' 'SHOW' 'TELEMETRY'
|	'ADMIN' 'RESET' 'TELEMETRY_ID'
|	'ADMIN' 'FLUSH' StatementScope 'PLAN_CACHE'

;
AdminShowSlow:
	'RECENT' NUM
|	'TOP' NUM
|	'TOP' 'INTERNAL' NUM
|	'TOP' 'ALL' NUM

;
HandleRangeList:
	HandleRange
|	HandleRangeList ',' HandleRange

;
HandleRange:
	'(' Int64Num ',' Int64Num ')'

;
NumList:
	Int64Num
|	NumList ',' Int64Num


;
ShowStmt:
	'SHOW' ShowTargetFilterable ShowLikeOrWhereOpt
|	'SHOW' 'CREATE' 'TABLE' TableName
|	'SHOW' 'CREATE' 'VIEW' TableName
|	'SHOW' 'CREATE' 'DATABASE' IfNotExists DBName
|	'SHOW' 'CREATE' 'SEQUENCE' TableName
|	'SHOW' 'CREATE' 'PLACEMENT' 'POLICY' PolicyName
|	'SHOW' 'CREATE' 'USER' Username
|	'SHOW' 'CREATE' 'IMPORT' Identifier
|	'SHOW' 'TABLE' TableName PartitionNameListOpt 'REGIONS' WhereClauseOptional
|	'SHOW' 'TABLE' TableName 'NEXT_ROW_ID'
|	'SHOW' 'TABLE' TableName PartitionNameListOpt 'INDEX' Identifier 'REGIONS' WhereClauseOptional
|	'SHOW' 'GRANTS'
|	'SHOW' 'GRANTS' 'FOR' Username UsingRoles
|	'SHOW' 'MASTER' 'STATUS'
|	'SHOW' OptFull 'PROCESSLIST'
|	'SHOW' 'PROFILES'
|	'SHOW' 'PROFILE' ShowProfileTypesOpt ShowProfileArgsOpt SelectStmtLimitOpt
|	'SHOW' 'PRIVILEGES'
|	'SHOW' 'BUILTINS'
|	'SHOW' 'PLACEMENT' 'FOR' ShowPlacementTarget

;
ShowPlacementTarget:
	DatabaseSym DBName
|	'TABLE' TableName
|	'TABLE' TableName 'PARTITION' Identifier

;
ShowProfileTypesOpt:
|	ShowProfileTypes

;
ShowProfileTypes:
	ShowProfileType
|	ShowProfileTypes ',' ShowProfileType

;
ShowProfileType:
	'CPU'
|	'MEMORY'
|	'BLOCK' 'IO'
|	'CONTEXT' 'SWITCHES'
|	'PAGE' 'FAULTS'
|	'IPC'
|	'SWAPS'
|	'SOURCE'
|	'ALL'

;
ShowProfileArgsOpt:
|	'FOR' 'QUERY' Int64Num

;
UsingRoles:
|	'USING' RolenameList

;
ShowIndexKwd:
	'INDEX'
|	'INDEXES'
|	'KEYS'

;
FromOrIn:
	'FROM'
|	'IN'

;
ShowTargetFilterable:
	'ENGINES'
|	'DATABASES'
|	'CONFIG'
|	CharsetKw
|	OptFull 'TABLES' ShowDatabaseNameOpt
|	'OPEN' 'TABLES' ShowDatabaseNameOpt
|	'TABLE' 'STATUS' ShowDatabaseNameOpt
|	ShowIndexKwd FromOrIn TableName
|	ShowIndexKwd FromOrIn Identifier FromOrIn Identifier
|	OptFull FieldsOrColumns ShowTableAliasOpt ShowDatabaseNameOpt
|	'EXTENDED' OptFull FieldsOrColumns ShowTableAliasOpt ShowDatabaseNameOpt
|	'WARNINGS'
|	'ERRORS'
|	GlobalScope 'VARIABLES'
|	GlobalScope 'STATUS'
|	GlobalScope 'BINDINGS'
|	'COLLATION'
|	'TRIGGERS' ShowDatabaseNameOpt
|	'BINDING_CACHE' 'STATUS'
|	'PROCEDURE' 'STATUS'
|	'PUMP' 'STATUS'
|	'DRAINER' 'STATUS'
|	'FUNCTION' 'STATUS'
|	'EVENTS' ShowDatabaseNameOpt
|	'PLUGINS'
|	'STATS_EXTENDED'
|	'STATS_META'
|	'STATS_HISTOGRAMS'
|	'STATS_TOPN'
|	'STATS_BUCKETS'
|	'STATS_HEALTHY'
|	'HISTOGRAMS_IN_FLIGHT'
|	'COLUMN_STATS_USAGE'
|	'ANALYZE' 'STATUS'
|	'BACKUPS'
|	'RESTORES'
|	'IMPORTS'
|	'PLACEMENT'
|	'PLACEMENT' 'LABELS'

;
ShowLikeOrWhereOpt:
|	'LIKE' SimpleExpr
|	'WHERE' Expression

;
GlobalScope:
|	'GLOBAL'
|	'SESSION'

;
StatementScope:
|	'GLOBAL'
|	'INSTANCE'
|	'SESSION'

;
OptFull:
|	'FULL'

;
ShowDatabaseNameOpt:
|	FromOrIn DBName

;
ShowTableAliasOpt:
	FromOrIn TableName

;
FlushStmt:
	'FLUSH' NoWriteToBinLogAliasOpt FlushOption

;
PluginNameList:
	Identifier
|	PluginNameList ',' Identifier

;
FlushOption:
	'PRIVILEGES'
|	'STATUS'
|	'TIDB' 'PLUGINS' PluginNameList
|	'HOSTS'
|	LogTypeOpt 'LOGS'
|	TableOrTables TableNameListOpt WithReadLockOpt
|	'CLIENT_ERRORS_SUMMARY'

;
LogTypeOpt:
|	'BINARY'
|	'ENGINE'
|	'ERROR'
|	'GENERAL'
|	'SLOW'

;
NoWriteToBinLogAliasOpt:
	%prec lowerThanLocal
|	'NO_WRITE_TO_BINLOG'
|	'LOCAL'

;
TableNameListOpt:
	%prec empty
|	TableNameList

;
TableNameListOpt2:
	%prec empty
|	'TABLE' TableNameList

;
WithReadLockOpt:
|	'WITH' 'READ' 'LOCK'

;
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

;
TraceableStmt:
	DeleteFromStmt
|	UpdateStmt
|	InsertIntoStmt
|	ReplaceIntoStmt
|	SetOprStmt
|	SelectStmt
|	SelectStmtWithClause
|	SubSelect
|	LoadDataStmt
|	BeginTransactionStmt
|	CommitStmt
|	RollbackStmt
|	SetStmt

;
ExplainableStmt:
	DeleteFromStmt
|	UpdateStmt
|	InsertIntoStmt
|	ReplaceIntoStmt
|	SetOprStmt
|	SelectStmt
|	SelectStmtWithClause
|	SubSelect
|	AlterTableStmt

;
StatementList:
	Statement
|	StatementList ';' Statement

;
Constraint:
	ConstraintKeywordOpt ConstraintElem

;
CheckConstraintKeyword:
	'CHECK'
|	'CONSTRAINT'

;
TableElement:
	ColumnDef
|	Constraint

;
TableElementList:
	TableElement
|	TableElementList ',' TableElement

;
TableElementListOpt:
	 %prec lowerThanCreateTableSelect
|	'(' TableElementList ')'

;
TableOption:
	PartDefOption
|	DefaultKwdOpt CharsetKw EqOpt CharsetName
|	DefaultKwdOpt 'COLLATE' EqOpt CollationName
|	ForceOpt 'AUTO_INCREMENT' EqOpt LengthNum
|	'AUTO_ID_CACHE' EqOpt LengthNum
|	ForceOpt 'AUTO_RANDOM_BASE' EqOpt LengthNum
|	'AVG_ROW_LENGTH' EqOpt LengthNum
|	'CONNECTION' EqOpt stringLit
|	'CHECKSUM' EqOpt LengthNum
|	'TABLE_CHECKSUM' EqOpt LengthNum
|	'PASSWORD' EqOpt stringLit
|	'COMPRESSION' EqOpt stringLit
|	'KEY_BLOCK_SIZE' EqOpt LengthNum
|	'DELAY_KEY_WRITE' EqOpt LengthNum
|	RowFormat
|	'STATS_PERSISTENT' EqOpt StatsPersistentVal
|	'STATS_AUTO_RECALC' EqOpt LengthNum
|	'STATS_AUTO_RECALC' EqOpt 'DEFAULT'
|	'STATS_SAMPLE_PAGES' EqOpt LengthNum
|	'STATS_SAMPLE_PAGES' EqOpt 'DEFAULT'
|	'STATS_BUCKETS' EqOpt LengthNum
|	'STATS_TOPN' EqOpt LengthNum
|	'STATS_SAMPLE_RATE' EqOpt NumLiteral
|	'STATS_COL_CHOICE' EqOpt stringLit
|	'STATS_COL_LIST' EqOpt stringLit
|	'SHARD_ROW_ID_BITS' EqOpt LengthNum
|	'PRE_SPLIT_REGIONS' EqOpt LengthNum
|	'PACK_KEYS' EqOpt StatsPersistentVal
|	'STORAGE' 'MEMORY'
|	'STORAGE' 'DISK'
|	'SECONDARY_ENGINE' EqOpt 'NULL'
|	'SECONDARY_ENGINE' EqOpt StringName
|	'UNION' EqOpt '(' TableNameListOpt ')'
|	'ENCRYPTION' EqOpt EncryptionOpt

;
ForceOpt:
|	'FORCE'

;
StatsPersistentVal:
	'DEFAULT'
|	LengthNum

;
CreateTableOptionListOpt:
	 %prec lowerThanCreateTableSelect
|	TableOptionList %prec lowerThanComma

;
TableOptionList:
	TableOption
|	TableOptionList TableOption
|	TableOptionList ',' TableOption

;
OptTable:
|	'TABLE'

;
TruncateTableStmt:
	'TRUNCATE' OptTable TableName

;
RowFormat:
	'ROW_FORMAT' EqOpt 'DEFAULT'
|	'ROW_FORMAT' EqOpt 'DYNAMIC'
|	'ROW_FORMAT' EqOpt 'FIXED'
|	'ROW_FORMAT' EqOpt 'COMPRESSED'
|	'ROW_FORMAT' EqOpt 'REDUNDANT'
|	'ROW_FORMAT' EqOpt 'COMPACT'
|	'ROW_FORMAT' EqOpt 'TOKUDB_DEFAULT'
|	'ROW_FORMAT' EqOpt 'TOKUDB_FAST'
|	'ROW_FORMAT' EqOpt 'TOKUDB_SMALL'
|	'ROW_FORMAT' EqOpt 'TOKUDB_ZLIB'
|	'ROW_FORMAT' EqOpt 'TOKUDB_QUICKLZ'
|	'ROW_FORMAT' EqOpt 'TOKUDB_LZMA'
|	'ROW_FORMAT' EqOpt 'TOKUDB_SNAPPY'
|	'ROW_FORMAT' EqOpt 'TOKUDB_UNCOMPRESSED'


;
Type:
	NumericType
|	StringType
|	DateAndTimeType

;
NumericType:
	IntegerType OptFieldLen FieldOpts
|	BooleanType FieldOpts
|	FixedPointType FloatOpt FieldOpts
|	FloatingPointType FloatOpt FieldOpts
|	BitValueType OptFieldLen

;
IntegerType:
	'TINYINT'
|	'SMALLINT'
|	'MEDIUMINT'
|	'INT'
|	'INT1'
|	'INT2'
|	'INT3'
|	'INT4'
|	'INT8'
|	'INTEGER'
|	'BIGINT'

;
BooleanType:
	'BOOL'
|	'BOOLEAN'

;
OptInteger:
|	'INTEGER'
|	'INT'

;
FixedPointType:
	'DECIMAL'
|	'NUMERIC'
|	'FIXED'

;
FloatingPointType:
	'FLOAT'
|	'REAL'
|	'DOUBLE'
|	'DOUBLE' 'PRECISION'

;
BitValueType:
	'BIT'

;
StringType:
	Char FieldLen OptBinary
|	Char OptBinary
|	NChar FieldLen OptBinary
|	NChar OptBinary
|	Varchar FieldLen OptBinary
|	NVarchar FieldLen OptBinary
|	'BINARY' OptFieldLen
|	'VARBINARY' FieldLen
|	BlobType
|	TextType OptCharsetWithOptBinary
|	'ENUM' '(' TextStringList ')' OptCharsetWithOptBinary
|	'SET' '(' TextStringList ')' OptCharsetWithOptBinary
|	'JSON'
|	'LONG' Varchar OptCharsetWithOptBinary
|	'LONG' OptCharsetWithOptBinary

;
Char:
	'CHARACTER'
|	'CHAR'

;
NChar:
	'NCHAR'
|	'NATIONAL' 'CHARACTER'
|	'NATIONAL' 'CHAR'

;
Varchar:
	'CHARACTER' 'VARYING'
|	'CHAR' 'VARYING'
|	'VARCHAR'
|	'VARCHARACTER'

;
NVarchar:
	'NATIONAL' 'VARCHAR'
|	'NATIONAL' 'VARCHARACTER'
|	'NVARCHAR'
|	'NCHAR' 'VARCHAR'
|	'NCHAR' 'VARCHARACTER'
|	'NATIONAL' 'CHARACTER' 'VARYING'
|	'NATIONAL' 'CHAR' 'VARYING'
|	'NCHAR' 'VARYING'

;
Year:
	'YEAR'
|	'SQL_TSI_YEAR'

;
BlobType:
	'TINYBLOB'
|	'BLOB' OptFieldLen
|	'MEDIUMBLOB'
|	'LONGBLOB'
|	'LONG' 'VARBINARY'

;
TextType:
	'TINYTEXT'
|	'TEXT' OptFieldLen
|	'MEDIUMTEXT'
|	'LONGTEXT'

;
OptCharsetWithOptBinary:
	OptBinary
|	'ASCII'
|	'UNICODE'
|	'BYTE'

;
DateAndTimeType:
	'DATE'
|	'DATETIME' OptFieldLen
|	'TIMESTAMP' OptFieldLen
|	'TIME' OptFieldLen
|	Year OptFieldLen FieldOpts

;
FieldLen:
	'(' LengthNum ')'

;
OptFieldLen:
|	FieldLen

;
FieldOpt:
	'UNSIGNED'
|	'SIGNED'
|	'ZEROFILL'

;
FieldOpts:
|	FieldOpts FieldOpt

;
FloatOpt:
|	FieldLen
|	Precision

;
Precision:
	'(' LengthNum ',' LengthNum ')'

;
OptBinMod:
|	'BINARY'

;
OptBinary:
|	'BINARY' OptCharset
|	CharsetKw CharsetName OptBinMod

;
OptCharset:
|	CharsetKw CharsetName

;
CharsetKw:
	'CHARACTER' 'SET'
|	'CHARSET'
|	'CHAR' 'SET'

;
OptCollate:
|	'COLLATE' CollationName

;
StringList:
	stringLit
|	StringList ',' stringLit

;
TextString:
	stringLit
|	hexLit
|	bitLit

;
TextStringList:
	TextString
|	TextStringList ',' TextString

;
StringName:
	stringLit
|	Identifier

;
StringNameOrBRIEOptionKeyword:
	StringName
|	'IGNORE'
|	'REPLACE'


;
UpdateStmt:
	UpdateStmtNoWith
|	WithClause UpdateStmtNoWith

;
UpdateStmtNoWith:
	'UPDATE' TableOptimizerHintsOpt PriorityOpt IgnoreOptional TableRef 'SET' AssignmentList WhereClauseOptional OrderByOptional LimitClause
|	'UPDATE' TableOptimizerHintsOpt PriorityOpt IgnoreOptional TableRefs 'SET' AssignmentList WhereClauseOptional

;
UseStmt:
	'USE' DBName

;
WhereClause:
	'WHERE' Expression

;
WhereClauseOptional:
|	WhereClause

;
CommaOpt:
|	','


;
CreateUserStmt:
	'CREATE' 'USER' IfNotExists UserSpecList RequireClauseOpt ConnectionOptions PasswordOrLockOptions

;
CreateRoleStmt:
	'CREATE' 'ROLE' IfNotExists RoleSpecList


;
AlterUserStmt:
	'ALTER' 'USER' IfExists UserSpecList RequireClauseOpt ConnectionOptions PasswordOrLockOptions
|	'ALTER' 'USER' IfExists 'USER' '(' ')' 'IDENTIFIED' 'BY' AuthString


;
AlterInstanceStmt:
	'ALTER' 'INSTANCE' InstanceOption

;
InstanceOption:
	'RELOAD' 'TLS'
|	'RELOAD' 'TLS' 'NO' 'ROLLBACK' 'ON' 'ERROR'

;
UserSpec:
	Username AuthOption

;
UserSpecList:
	UserSpec
|	UserSpecList ',' UserSpec

;
ConnectionOptions:
|	'WITH' ConnectionOptionList

;
ConnectionOptionList:
	ConnectionOption
|	ConnectionOptionList ConnectionOption

;
ConnectionOption:
	'MAX_QUERIES_PER_HOUR' Int64Num
|	'MAX_UPDATES_PER_HOUR' Int64Num
|	'MAX_CONNECTIONS_PER_HOUR' Int64Num
|	'MAX_USER_CONNECTIONS' Int64Num

;
RequireClauseOpt:
|	RequireClause

;
RequireClause:
	'REQUIRE' 'NONE'
|	'REQUIRE' 'SSL'
|	'REQUIRE' 'X509'
|	'REQUIRE' RequireList

;
RequireList:
	RequireListElement
|	RequireList 'AND' RequireListElement
|	RequireList RequireListElement

;
RequireListElement:
	'ISSUER' stringLit
|	'SUBJECT' stringLit
|	'CIPHER' stringLit
|	'SAN' stringLit

;
PasswordOrLockOptions:
|	PasswordOrLockOptionList

;
PasswordOrLockOptionList:
	PasswordOrLockOption
|	PasswordOrLockOptionList PasswordOrLockOption

;
PasswordOrLockOption:
	'ACCOUNT' 'UNLOCK'
|	'ACCOUNT' 'LOCK'
|	PasswordExpire
|	PasswordExpire 'INTERVAL' Int64Num 'DAY'
|	PasswordExpire 'NEVER'
|	PasswordExpire 'DEFAULT'

;
PasswordExpire:
	'PASSWORD' 'EXPIRE' ClearPasswordExpireOptions

;
ClearPasswordExpireOptions:

;
AuthOption:
|	'IDENTIFIED' 'BY' AuthString
|	'IDENTIFIED' 'WITH' AuthPlugin
|	'IDENTIFIED' 'WITH' AuthPlugin 'BY' AuthString
|	'IDENTIFIED' 'WITH' AuthPlugin 'AS' HashString
|	'IDENTIFIED' 'BY' 'PASSWORD' HashString

;
AuthPlugin:
	StringName

;
HashString:
	stringLit
|	hexLit

;
RoleSpec:
	Rolename

;
RoleSpecList:
	RoleSpec
|	RoleSpecList ',' RoleSpec

;
BindableStmt:
	SetOprStmt
|	SelectStmt
|	SelectStmtWithClause
|	SubSelect
|	UpdateStmt
|	DeleteWithoutUsingStmt
|	InsertIntoStmt
|	ReplaceIntoStmt


;
CreateBindingStmt:
	'CREATE' GlobalScope 'BINDING' 'FOR' BindableStmt 'USING' BindableStmt


;
DropBindingStmt:
	'DROP' GlobalScope 'BINDING' 'FOR' BindableStmt
|	'DROP' GlobalScope 'BINDING' 'FOR' BindableStmt 'USING' BindableStmt

;
SetBindingStmt:
	'SET' 'BINDING' BindingStatusType 'FOR' BindableStmt
|	'SET' 'BINDING' BindingStatusType 'FOR' BindableStmt 'USING' BindableStmt


;
GrantStmt:
	'GRANT' RoleOrPrivElemList 'ON' ObjectType PrivLevel 'TO' UserSpecList RequireClauseOpt WithGrantOptionOpt

;
GrantProxyStmt:
	'GRANT' 'PROXY' 'ON' Username 'TO' UsernameList WithGrantOptionOpt

;
GrantRoleStmt:
	'GRANT' RoleOrPrivElemList 'TO' UsernameList

;
WithGrantOptionOpt:
|	'WITH' 'GRANT' 'OPTION'
|	'WITH' 'MAX_QUERIES_PER_HOUR' NUM
|	'WITH' 'MAX_UPDATES_PER_HOUR' NUM
|	'WITH' 'MAX_CONNECTIONS_PER_HOUR' NUM
|	'WITH' 'MAX_USER_CONNECTIONS' NUM

;
ExtendedPriv:
	identifier
|	ExtendedPriv identifier

;
RoleOrPrivElem:
	PrivElem
|	RolenameWithoutIdent
|	ExtendedPriv
|	'LOAD' 'FROM' 'S3'
|	'SELECT' 'INTO' 'S3'

;
RoleOrPrivElemList:
	RoleOrPrivElem
|	RoleOrPrivElemList ',' RoleOrPrivElem

;
PrivElem:
	PrivType
|	PrivType '(' ColumnNameList ')'

;
PrivType:
	'ALL'
|	'ALL' 'PRIVILEGES'
|	'ALTER'
|	'CREATE'
|	'CREATE' 'USER'
|	'CREATE' 'TABLESPACE'
|	'TRIGGER'
|	'DELETE'
|	'DROP'
|	'PROCESS'
|	'EXECUTE'
|	'INDEX'
|	'INSERT'
|	'SELECT'
|	'SUPER'
|	'SHOW' 'DATABASES'
|	'UPDATE'
|	'GRANT' 'OPTION'
|	'REFERENCES'
|	'REPLICATION' 'SLAVE'
|	'REPLICATION' 'CLIENT'
|	'USAGE'
|	'RELOAD'
|	'FILE'
|	'CONFIG'
|	'CREATE' 'TEMPORARY' 'TABLES'
|	'LOCK' 'TABLES'
|	'CREATE' 'VIEW'
|	'SHOW' 'VIEW'
|	'CREATE' 'ROLE'
|	'DROP' 'ROLE'
|	'CREATE' 'ROUTINE'
|	'ALTER' 'ROUTINE'
|	'EVENT'
|	'SHUTDOWN'

;
ObjectType:
	%prec lowerThanFunction
|	'TABLE'
|	'FUNCTION'
|	'PROCEDURE'

;
PrivLevel:
	'*'
|	'*' '.' '*'
|	Identifier '.' '*'
|	Identifier '.' Identifier
|	Identifier


;
RevokeStmt:
	'REVOKE' RoleOrPrivElemList 'ON' ObjectType PrivLevel 'FROM' UserSpecList

;
RevokeRoleStmt:
	'REVOKE' RoleOrPrivElemList 'FROM' UsernameList


;
LoadDataStmt:
	'LOAD' 'DATA' LocalOpt 'INFILE' stringLit DuplicateOpt 'INTO' 'TABLE' TableName CharsetOpt Fields Lines IgnoreLines ColumnNameOrUserVarListOptWithBrackets LoadDataSetSpecOpt

;
IgnoreLines:
|	'IGNORE' NUM 'LINES'

;
CharsetOpt:
|	'CHARACTER' 'SET' CharsetName

;
LocalOpt:
|	'LOCAL'

;
Fields:
|	FieldsOrColumns FieldItemList

;
FieldsOrColumns:
	'FIELDS'
|	'COLUMNS'

;
FieldItemList:
	FieldItemList FieldItem
|	FieldItem

;
FieldItem:
	'TERMINATED' 'BY' FieldTerminator
|	'OPTIONALLY' 'ENCLOSED' 'BY' FieldTerminator
|	'ENCLOSED' 'BY' FieldTerminator
|	'ESCAPED' 'BY' FieldTerminator

;
FieldTerminator:
	stringLit
|	hexLit
|	bitLit

;
Lines:
|	'LINES' Starting LinesTerminated

;
Starting:
|	'STARTING' 'BY' FieldTerminator

;
LinesTerminated:
|	'TERMINATED' 'BY' FieldTerminator

;
LoadDataSetSpecOpt:
|	'SET' LoadDataSetList

;
LoadDataSetList:
	LoadDataSetList ',' LoadDataSetItem
|	LoadDataSetItem

;
LoadDataSetItem:
	SimpleIdent '=' ExprOrDefault


;
UnlockTablesStmt:
	'UNLOCK' TablesTerminalSym

;
LockTablesStmt:
	'LOCK' TablesTerminalSym TableLockList

;
TablesTerminalSym:
	'TABLES'
|	'TABLE'

;
TableLock:
	TableName LockType

;
LockType:
	'READ'
|	'READ' 'LOCAL'
|	'WRITE'
|	'WRITE' 'LOCAL'

;
TableLockList:
	TableLock
|	TableLockList ',' TableLock


;
NonTransactionalDeleteStmt:
	'BATCH' OptionalShardColumn 'LIMIT' NUM DryRunOptions DeleteFromStmt

;
DryRunOptions:
|	'DRY' 'RUN'
|	'DRY' 'RUN' 'QUERY'

;
OptionalShardColumn:
|	'ON' ColumnName


;
KillStmt:
	KillOrKillTiDB NUM
|	KillOrKillTiDB 'CONNECTION' NUM
|	KillOrKillTiDB 'QUERY' NUM

;
KillOrKillTiDB:
	'KILL'

|	'KILL' 'TIDB'

;
LoadStatsStmt:
	'LOAD' 'STATS' stringLit

;
DropPolicyStmt:
	'DROP' 'PLACEMENT' 'POLICY' IfExists PolicyName

;
CreatePolicyStmt:
	'CREATE' OrReplace 'PLACEMENT' 'POLICY' IfNotExists PolicyName PlacementOptionList

;
AlterPolicyStmt:
	'ALTER' 'PLACEMENT' 'POLICY' IfExists PolicyName PlacementOptionList


;
CreateSequenceStmt:
	'CREATE' 'SEQUENCE' IfNotExists TableName CreateSequenceOptionListOpt CreateTableOptionListOpt

;
CreateSequenceOptionListOpt:
|	SequenceOptionList

;
SequenceOptionList:
	SequenceOption
|	SequenceOptionList SequenceOption

;
SequenceOption:
	'INCREMENT' EqOpt SignedNum
|	'INCREMENT' 'BY' SignedNum
|	'START' EqOpt SignedNum
|	'START' 'WITH' SignedNum
|	'MINVALUE' EqOpt SignedNum
|	'NOMINVALUE'
|	'NO' 'MINVALUE'
|	'MAXVALUE' EqOpt SignedNum
|	'NOMAXVALUE'
|	'NO' 'MAXVALUE'
|	'CACHE' EqOpt SignedNum
|	'NOCACHE'
|	'NO' 'CACHE'
|	'CYCLE'
|	'NOCYCLE'
|	'NO' 'CYCLE'

;
SignedNum:
	Int64Num
|	'+' Int64Num
|	'-' NUM

;
DropSequenceStmt:
	'DROP' 'SEQUENCE' IfExists TableNameList


;
AlterSequenceStmt:
	'ALTER' 'SEQUENCE' IfExists TableName AlterSequenceOptionList

;
AlterSequenceOptionList:
	AlterSequenceOption
|	AlterSequenceOptionList AlterSequenceOption

;
AlterSequenceOption:
	SequenceOption
|	'RESTART'
|	'RESTART' EqOpt SignedNum
|	'RESTART' 'WITH' SignedNum


;
IndexAdviseStmt:
	'INDEX' 'ADVISE' LocalOpt 'INFILE' stringLit MaxMinutesOpt MaxIndexNumOpt Lines

;
MaxMinutesOpt:
|	'MAX_MINUTES' NUM

;
MaxIndexNumOpt:
|	'MAX_IDXNUM' PerTable PerDB

;
PerTable:
|	'PER_TABLE' NUM

;
PerDB:
|	'PER_DB' NUM

;
EncryptionOpt:
	stringLit

;
ValuesStmtList:
	RowStmt
|	ValuesStmtList ',' RowStmt

;
RowStmt:
	'ROW' RowValue


;
PlanReplayerStmt:
	'PLAN' 'REPLAYER' 'DUMP' 'EXPLAIN' ExplainableStmt
|	'PLAN' 'REPLAYER' 'DUMP' 'EXPLAIN' 'ANALYZE' ExplainableStmt
|	'PLAN' 'REPLAYER' 'DUMP' 'EXPLAIN' 'SLOW' 'QUERY' WhereClauseOptional OrderByOptional SelectStmtLimitOpt
|	'PLAN' 'REPLAYER' 'DUMP' 'EXPLAIN' 'ANALYZE' 'SLOW' 'QUERY' WhereClauseOptional OrderByOptional SelectStmtLimitOpt
|	'PLAN' 'REPLAYER' 'LOAD' stringLit
;
