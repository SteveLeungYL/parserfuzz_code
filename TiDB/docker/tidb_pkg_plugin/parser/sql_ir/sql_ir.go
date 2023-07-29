package sql_ir

type SQLRightIRType int
type SQLRightDataType int
type SQLRightContextFlag int
type SQLRightDataAffinity int

const (
	TypeUnknown SQLRightIRType = iota
	TypeRoot
	TypeIntegerLiteral
	TypeFloatLiteral
	TypeStringLiteral
	TypeIdentifier
	TypeIndexAdviseStmt
	TypeMaxIndexNumClause
	TypeAlterDatabaseStmt
	TypeDropDatabaseStmt
	TypeIndexPartSpecification
	TypeReferenceDef
	TypeOnDeleteOpt
	TypeOnUpdateOpt
	TypeColumnOption
	TypeIndexOption
	TypeConstraint
	TypeColumnDef
	TypeFieldType
	TypeCreateDatabaseStmt
	TypeCreateTableStmt
	TypeDropTableStmt
	TypeDropPlacementPolicyStmt
	TypeDropSequenceStmt
	TypeRenameTableStmt
	TypeTableToTable
	TypeCreateViewStmt
	TypeCreatePlacementPolicyStmt
	TypeCreateSequenceStmt
	TypeIndexLockAndAlgorithm
	TypeCreateIndexStmt
	TypeDropIndexStmt
	TypeLockTablesStmt
	TypeUnlockTablesStmt
	TypeCleanupTableLockStmt
	TypeRepairTableStmt
	TypePlacementOption
	TypeTableOption
	TypeSequenceOption
	TypeColumnPosition
	TypeAlterOrderItem
	TypeAlterTableSpec
	TypeAlterTableStmt
	TypeTruncateTableStmt
	TypeSubPartitionDefinition
	TypePartitionDefinitionClauseNone
	TypePartitionDefinitionClauseLessThan
	TypePartitionDefinitionClauseIn
	TypePartitionDefinitionClauseHistory
	TypePartitionDefinition
	TypePartitionMethod
	TypePartitionOptions
	TypeRecoverTableStmt
	TypeFlashBackTableStmt
	TypeAttributesSpec
	TypeStatsOptionsSpec
	TypeAlterPlacementPolicyStmt
	TypeAlterSequenceStmt
	TypeJoin
	TypeTableName
	TypeIndexHint
	TypeDeleteTableList
	TypeOnCondition
	TypeTableSource
	TypeWildCardField
	TypeSelectField
	TypeFieldList
	TypeTableRefsClause
	TypeByItem
	TypeGroupByClause
	TypeHavingClause
	TypeOrderByClause
	TypeTableSample
	TypeCommonTableExpression
	TypeWithClause
	TypeSelectStmt
	TypeSetOprSelectList
	TypeSetOprStmt
	TypeColumnNameOrUserVar
	TypeLoadDataStmt
	TypeFieldsClause
	TypeLinesClause
	TypeCallStmt
	TypePriorityEnum
	TypeInsertStmt
	TypeDeleteStmt
	TypeNonTransactionalDeleteStmt
	TypeUpdateStmt
	TypeLimit
	TypeUserIdentity
	TypeRoleIdentity
	TypeShowStmt
	TypeWindowSpec
	TypeSelectIntoOption
	TypePartitionByClause
	TypeFrameClause
	TypeFrameBound
	TypeSplitRegionStmt
	TypeSplitOption
	TypeAsOfClause
	TypeBinaryOperationExpr
	TypeWhenClause
	TypeCaseExpr
	TypeSubqueryExpr
	TypeCompareSubqueryExpr
	TypeTableNameExpr
	TypeColumnName
	TypeColumnNameExpr
	TypeDefaultExpr
	TypeExistsSubqueryExpr
	TypePatternInExpr
	TypeIsNullExpr
	TypePatternLikeExpr
	TypeParenthesesExpr
	TypePositionExpr
	TypePatternRegexpExpr
	TypeRowExpr
	TypeUnaryOperationExpr
	TypeValuesExpr
	TypeVariableExpr
	TypeMaxValueExpr
	TypeMatchAgainst
	TypeSetCollationExpr
	TypeFuncCallExpr
	TypeFuncCastExpr
	TypeTrimDirectionExpr
	TypeAggregateFuncExpr
	TypeWindowFuncExpr
	TypeTimeUnitExpr
	TypeGetFormatSelectorExpr
	TypeAuthOption
	TypeTraceStmt
	TypeExplainForStmt
	TypeExplainStmt
	TypePlanReplayerStmt
	TypeCompactTableStmt
	TypePrepareStmt
	TypeDeallocateStmt
	TypeExecuteStmt
	TypeBeginStmt
	TypeBinlogStmt
	TypeCompletionType
	TypeCommitStmt
	TypeRollbackStmt
	TypeUseStmt
	TypeVariableAssignment
	TypeFlushStmt
	TypeKillStmt
	TypeSetStmt
	TypeSetConfigStmt
	TypeSetPwdStmt
	TypeChangeStmt
	TypeSetRoleStmt
	TypeSetDefaultRoleStmt
	TypeUserSpec
	TypeTLSOption
	TypeResourceOption
)

const (
	DataNone SQLRightDataType = iota
	DataUnknownType
	DataCharSet
	DataEncryptionName
	DataChangeFeed
	DataDatabaseName
	DataSuperRegion
	DataRoleName
	DataCatalogName
	DataSchemaName
	DataFunctionName
	DataFunctionExpr
	DataExtensionName
	DataCollationName
	DataColumnName
	DataConstraintName
	DataViewName
	DataSequenceName
	DataTableName
	DataRegionName
	DataTemplateName
	DataEncodingName
	DataCTypeName
	DataIndexName
	DataTypeName
	DataPartitionName
	DataRangeName
	DataFamilyName
	DataStatsName
	DataSettingName
	DataSavePointName
	DataPrivilege
	DataWindowName
	DataStatementPreparedName
	DataCursorName
	DataZoneName
	DataChannelName
	DataTableAliasName
	DataColumnAliasName
	DataLiteral
	DataViewColumnName
	DataStorageParams
	DataPolicyName
	DataTableSpaceName
	DataForeignKeyName
	DataVariableName
)

const (
	ContextUnknown SQLRightContextFlag = iota
	ContextDefine
	ContextUse
	ContextUndefine
	ContextReplaceDefine
	ContextReplaceUndefine
	ContextNoModi
	ContextUseFollow // Use Follow stands for the table names or column names that has already been referred in the statement.
)

const (
	AFFIUNKNOWN SQLRightDataAffinity = iota
	AFFIANY
	AFFIBIT
	AFFIBOOL
	AFFIBYTES
	AFFICOLLATE
	AFFIDATE
	AFFIENUM
	AFFIDECIMAL
	AFFIFLOAT
	AFFIINET
	AFFIINT
	AFFIINTERVAL
	AFFIINTERVALTZ
	AFFIJSONB
	AFFIOID
	AFFISERIAL
	AFFISTRING
	AFFITIME
	AFFITIMETZ
	AFFITIMESTAMP
	AFFITIMESTAMPTZ
	AFFIUUID
	AFFIGEOGRAPHY // TODO:: FIXME:: Not sure what this is, may need to split to other types.
	AFFIGEOMETRY  // TODO:: FIXME:: Not sure what this is, may need to split to other types.
	AFFIBOX2D     // TODO:: FIXME:: Not sure what this is, may need to split to other types.
	AFFIVOID
	AFFIPOINT
	AFFILINESTRING
	AFFIPOLYGON
	AFFIMULTIPOINT
	AFFIMULTILINESTRING
	AFFIMULTIPOLYGON
	AFFIGEOMETRYCOLLECTION
	AFFIOIDWRAPPER
	AFFIWHOLESTMT
	AFFIONOFF
	AFFIONOFFAUTO
	AFFIARRAY
	AFFIARRAYANY
	AFFIARRAYUNKNOWN
	AFFIARRAYBIT
	AFFIARRAYBOOL
	AFFIARRAYBYTES
	AFFIARRAYCOLLATE
	AFFIARRAYDATE
	AFFIARRAYENUM
	AFFIARRAYDECIMAL
	AFFIARRAYFLOAT
	AFFIARRAYINET
	AFFIARRAYINT
	AFFIARRAYINTERVAL
	AFFIARRAYJSONB
	AFFIARRAYOID
	AFFIARRAYSERIAL
	AFFIARRAYSTRING
	AFFIARRAYTIME
	AFFIARRAYTIMETZ
	AFFIARRAYTIMESTAMP
	AFFIARRAYTIMESTAMPTZ
	AFFIARRAYUUID
	AFFIARRAYGEOGRAPHY
	AFFIARRAYGEOMETRY
	AFFIARRAYBOX2D
	AFFIARRAYVOID
	AFFIARRAYPOINT
	AFFIARRAYLINESTRING
	AFFIARRAYPOLYGON
	AFFIARRAYMULTIPOINT
	AFFIARRAYMULTILINESTRING
	AFFIARRAYMULTIPOLYGON
	AFFIARRAYGEOMETRYCOLLECTION
	AFFIARRAYOIDWRAPPER
	AFFIARRAYWHOLESTM
	AFFIARRAYONOFF
	AFFIARRAYONOFFAUTO
	AFFITABLENAME
	AFFICOLUMNNAME
	AFFICONSTRAINTNAME
	AFFITUPLE
)

// SQLRight inject code. To log all the info required for SQLRight to build the IR.
type SqlRsgIR struct {
	Prefix       string
	Infix        string
	Suffix       string
	LNode        *SqlRsgIR
	RNode        *SqlRsgIR
	IRType       SQLRightIRType
	DataType     SQLRightDataType
	ContextFlag  SQLRightContextFlag
	DataAffinity SQLRightDataAffinity
	Depth        int
	Str          string
	IValue       int64
	UValue       uint64
	FValue       float64
	NodeHash     uint64 // Potentially used for calculating grammar coverage.
}
type SqlRsgInterface interface {
	// Recursive function to construct the SQLRight IR tree.
	LogCurrentNode(depth int) *SqlRsgIR
}
