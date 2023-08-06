package sql_ir

type RsgIRType int
type RsgDataType int
type RsgContextFlag int
type RsgDataAffinity int

const (
	TypeUnknown RsgIRType = iota
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
	TypePasswordOrLockOption
	TypeCreateUserStmt
	TypeAlterUserStmt
	TypeAlterInstanceStmt
	TypeDropUserStmt
	TypeCreateBindingStmt
	TypeDropBindingStmt
	TypeSetBindingStmt
	TypeCreateStatisticsStmt
	TypeDropStatisticsStmt
	TypeDoStmt
	TypeShowSlow
	TypeAdminStmt
	TypePrivElem
	TypeObjectTypeType
	TypeGrantLevel
	TypeRevokeStmt
	TypeRevokeRoleStmt
	TypeGrantStmt
	TypeGrantRoleStmt
	TypeShutdownStmt
	TypeRestartStmt
	TypeRenameUserStmt
	TypeHelpStmt
	TypeUserToUser
	TypeBRIEOption
	TypeBRIEStmt
	TypePurgeImportStmt
	TypeCreateImportStmt
	TypeStopImportStmt
	TypeResumeImportStmt
	TypeAlterImportStmt
	TypeDropImportStmt
	TypeShowImportStmt
	TypeHintTable
	TypeTableOptimizerHint
	TypeAnalyzeTableStmt
	TypeDropStatsStmt
	TypeLoadStatsStmt
	TypeCreateTableAsStmt
	TypeValuesClause
	TypeExpr
	TypeBetweenExpr
	TypeIsTruthExpr
	TypeWhereClause
	TypeValueExpr
	TypeParamMarkerExpr
)

const (
	DataNone RsgDataType = iota
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
	ContextUnknown RsgContextFlag = iota
	ContextDefine
	ContextUse
	ContextUndefine
	ContextReplaceDefine
	ContextReplaceUndefine
	ContextNoModi
	ContextUseFollow // Use Follow stands for the table names or column names that has already been referred in the statement.
)

// SQLRight inject code. To log all the info required for SQLRight to build the IR.
type SqlRsgIR struct {
	Prefix      string
	Infix       string
	Suffix      string
	LNode       *SqlRsgIR
	RNode       *SqlRsgIR
	IRType      RsgIRType
	DataType    RsgDataType
	ContextFlag RsgContextFlag
	//DataAffinity RsgDataAffinity
	Depth    int
	Str      string
	IValue   int64
	UValue   uint64
	FValue   float64
	NodeHash uint64 // Potentially used for calculating grammar coverage.
}
type SqlRsgInterface interface {
	// Recursive function to construct the SQLRight IR tree.
	LogCurrentNode(depth int) *SqlRsgIR
}

func GetSubNodeFromParentNodeWithType(curRootNode *SqlRsgIR,
	irType RsgIRType) []*SqlRsgIR {
	// Iterate IR binary tree, left depth prioritized.
	isFinishedSearch := false
	irVecIter := make([]*SqlRsgIR, 0)
	irVecMatchingType := make([]*SqlRsgIR, 0)
	curIr := curRootNode
	// Begin iterating.
	for !isFinishedSearch {
		irVecIter = append(irVecIter, curIr)
		if curIr.IRType == irType {
			irVecMatchingType = append(irVecMatchingType, curIr)
		}

		if curIr.LNode != nil {
			curIr = curIr.LNode
			continue
		} else { // Reaching the most depth. Consulting irVecIter for right_
			// nodes.
			curIr = nil
			for curIr == nil {
				if len(irVecIter) == 0 {
					isFinishedSearch = true
					break
				}
				curIr = irVecIter[len(irVecIter)-1].RNode
				irVecIter = irVecIter[:len(irVecIter)-1]
			}
			continue
		}
	}

	return irVecMatchingType
}

func GetSubNodeFromParentNodeWithDataType(curRootNode *SqlRsgIR,
	dataType RsgDataType) []*SqlRsgIR {
	// Iterate IR binary tree, left depth prioritized.
	isFinishedSearch := false
	irVecIter := make([]*SqlRsgIR, 0)
	irVecMatchingType := make([]*SqlRsgIR, 0)
	curIr := curRootNode
	// Begin iterating.
	for !isFinishedSearch {
		irVecIter = append(irVecIter, curIr)
		if curIr.DataType == dataType {
			irVecMatchingType = append(irVecMatchingType, curIr)
		}

		if curIr.LNode != nil {
			curIr = curIr.LNode
			continue
		} else { // Reaching the most depth. Consulting irVecIter for right_
			// nodes.
			curIr = nil
			for curIr == nil {
				if len(irVecIter) == 0 {
					isFinishedSearch = true
					break
				}
				curIr = irVecIter[len(irVecIter)-1].RNode
				irVecIter = irVecIter[:len(irVecIter)-1]
			}
			continue
		}
	}

	return irVecMatchingType
}
