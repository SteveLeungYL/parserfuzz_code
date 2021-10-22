#pragma once
#ifndef __DEFINE_H__
#define __DEFINE_H__

#define ALLTYPE(V)                                                             \
  V(kProgram)                                                                  \
  V(kStmtlist)                                                                 \
  V(kStmt)                                                                     \
  V(kCreateStmt)                                                               \
  V(kDropStmt)                                                                 \
  V(kAlterStmt)                                                                \
  V(kAlterIndexStmt)                                                           \
  V(kAlterGroupStmt)                                                           \
  V(kSelectStmt)                                                               \
  V(kSelectWithParens)                                                         \
  V(kSelectNoParens)                                                           \
  V(kSelectClauseList)                                                         \
  V(kSelectClause)                                                             \
  V(kCombineClause)                                                            \
  V(kOptFromClause)                                                            \
  V(kSelectTarget)                                                             \
  V(kOptWindowClause)                                                          \
  V(kWindowClause)                                                             \
  V(kWindowDefList)                                                            \
  V(kWindowDef)                                                                \
  V(kWindowName)                                                               \
  V(kWindow)                                                                   \
  V(kOptPartition)                                                             \
  V(kOptFrameClause)                                                           \
  V(kRangeOrRows)                                                              \
  V(kFrameBoundStart)                                                          \
  V(kFrameBoundEnd)                                                            \
  V(kFrameBound)                                                               \
  V(kOptFrameExclude)                                                          \
  V(kFrameExclude)                                                             \
  V(kOptExistWindowName)                                                       \
  V(kOptGroupClause)                                                           \
  V(kOptHavingClause)                                                          \
  V(kOptWhereClause)                                                           \
  V(kWhereClause)                                                              \
  V(kFromClause)                                                               \
  V(kTableRef)                                                                 \
  V(kOptOnOrUsing)                                                             \
  V(kOnOrUsing)                                                                \
  V(kColumnNameList)                                                           \
  V(kOptTablePrefix)                                                           \
  V(kJoinOp)                                                                   \
  V(kOptJoinType)                                                              \
  V(kExprList)                                                                 \
  V(kOptLimitClause)                                                           \
  V(kLimitClause)                                                              \
  V(kOptOrderClause)                                                           \
  V(kOptOrderNulls)                                                            \
  V(kOrderItemList)                                                            \
  V(kOrderItem)                                                                \
  V(kOptOrderBehavior)                                                         \
  V(kOptWithClause)                                                            \
  V(kCteList)                                                                  \
  V(kCteTableName)                                                             \
  V(kOptAllOrDistinct)                                                         \
  V(kCreateTableStmt)                                                          \
  V(kCreateIndexStmt)                                                          \
  V(kCreateViewStmt)                                                           \
  V(kDropIndexStmt)                                                            \
  V(kDropTableStmt)                                                            \
  V(kDropViewStmt)                                                             \
  V(kInsertStmt)                                                               \
  V(kInsertTarget)                                                             \
  V(kInsertQuery)                                                              \
  V(kValuesDefaultClause)                                                      \
  V(kExprDefaultListWithParens)                                                \
  V(kExprDefaultList)                                                                             \
  V(kOverrideKind)                                                             \
  V(kReturningClause)                                                          \
  V(kTargetList)                                                               \
  V(kTargetEl)                                                                 \
  V(kInsertRest)                                                               \
  V(kSuperValuesList)                                                          \
  V(kValuesList)                                                               \
  V(kOptOnConflict)                                                            \
  V(kOptConflictExpr)                                                          \
  V(kIndexedColumnList)                                                        \
  V(kIndexedColumn)                                                            \
  V(kUpdateStmt)                                                               \
  V(kReindexStmt)                                                              \
  V(kAlterAction)                                                              \
  V(kColumnDefList)                                                            \
  V(kColumnDef)                                                                \
  V(kOptColumnConstraintList)                                                  \
  V(kColumnConstraintList)                                                     \
  V(kColumnConstraint)                                                         \
  V(kConstraintType)                                                           \
  V(kForeignClause)                                                            \
  V(kOptForeignKeyActions)                                                     \
  V(kForeignKeyActions)                                                        \
  V(kKeyActions)                                                               \
  V(kOptConstraintAttributeSpec)                                               \
  V(kOptInitialTime)                                                           \
  V(kConstraintName)                                                           \
  V(kOptTemp)                                                                  \
  V(kOptCheckOption)                                                           \
  V(kOptColumnNameListP)                                                       \
  V(kSetClauseList)                                                            \
  V(kSetClause)                                                                \
  V(kExpr)                                                                     \
  V(kOperand)                                                                  \
  V(kCastExpr)                                                                 \
  V(kCountExpr)                                                                \
  V(kAllExpr)                                                                  \
  V(kSumExpr)                                                                  \
  V(kScalarExpr)                                                               \
  V(kUnaryExpr)                                                                \
  V(kBinaryExpr)                                                               \
  V(kLogicExpr)                                                                \
  V(kInExpr)                                                                   \
  V(kCaseExpr)                                                                 \
  V(kBetweenExpr)                                                              \
  V(kExistsExpr)                                                               \
  V(kCaseList)                                                                 \
  V(kCaseClause)                                                               \
  V(kCompExpr)                                                                 \
  V(kExtractExpr)                                                              \
  V(kDatetimeField)                                                            \
  V(kArrayIndex)                                                               \
  V(kLiteral)                                                                  \
  V(kStringLiteral)                                                            \
  V(kBoolLiteral)                                                              \
  V(kNumLiteral)                                                               \
  V(kIntLiteral)                                                               \
  V(kFloatLiteral)                                                             \
  V(kOptColumn)                                                                \
  V(kOptIfNotExist)                                                            \
  V(kOptIfExist)                                                               \
  V(kIdentifier)                                                               \
  V(kTableName)                                                                \
  V(kColumnName)                                                               \
  V(kOptUnique)                                                                \
  V(kViewName)                                                                 \
  V(kIndexName)                                                                \
  V(kTablespaceName)                                                           \
  V(kRoleName)                                                                 \
  V(kExtensionName)                                                            \
  V(kIndexStorageParameterList)                                                \
  V(kIndexStorageParameter)                                                    \
  V(kBinaryOp)                                                                 \
  V(kOptNot)                                                                   \
  V(kName)                                                                     \
  V(kTypeName)                                                                 \
  V(kCharacterType)                                                            \
  V(kCharacterWithLength)                                                      \
  V(kCharacterWithoutLength)                                                   \
  V(kCharacterConflicta)                                                       \
  V(kOptVarying)                                                               \
  V(kNumericType)                                                              \
  V(kOptTableConstraintList)                                                   \
  V(kTableConstraintList)                                                      \
  V(kTableConstraint)                                                          \
  V(kUnknown)                                                                  \
  V(kEmpty)                                                                    \
  V(kOptAlias)                                                                 \
  V(kFuncExpr)                                                                 \
  V(kFuncName)                                                                 \
  V(kFuncArgs)                                                                 \
  V(kOptSemi)                                                                  \
  V(kOptNo)                                                                    \
  V(kOptNowait)                                                                \
  V(kOptOwnedby)                                                               \
  V(kOnOffLiteral)                                                             \
  V(kOptConcurrently)                                                          \
  V(kOptIfNotExistIndex)                                                       \
  V(kOptOnly)                                                                  \
  V(kOptUsingMethod)                                                           \
  V(kMethodName)                                                               \
  V(kOptTablespace)                                                            \
  V(kOptWherePredicate)                                                        \
  V(kPredicateName)                                                            \
  V(kOptWithIndexStorageParameterList)                                         \
  V(kOptIncludeColumnNameList)                                                 \
  V(kOptCollate)                                                               \
  V(kCollationName)                                                            \
  V(kOptColumnOrExpr)                                                          \
  V(kIndexedCreateIndexRestStmtList)                                           \
  V(kCreateIndexRestStmt)                                                      \
  V(kOptIndexOpclassParameterList)                                             \
  V(kOptOpclassParameterList)                                                  \
  V(kIndexOpclassParameterList)                                                \
  V(kIndexOpclassParameter)                                                    \
  V(kOpclassName)                                                              \
  V(kOpclassParameterName)                                                     \
  V(kOpclassParameterValue)                                                    \
  V(kOptIndexNameList)                                                         \
  V(kIndexNameList)                                                            \
  V(kOptCascadeRestrict)                                                       \
  V(kRoleSpecification)                                                        \
  V(kUserName)                                                                 \
  V(kUserNameList)                                                                 \
  V(kGroupName)                                                                \
  V(kDropGroupStmt)                                                            \
  V(kGroupNameList)                                                            \
  V(kValuesStmt)                                                            \
  V(kExprListWithParens)                                                            \
  V(kCommonTableExpr)                                                            \
  V(kOptTable)                                                            \
  V(kIntoClause)                                                            \
  V(kAllorDistinct)                                                            \
  V(kDistinctClause)                                                           \
  V(kOptTempTableName)                                                           \
  V(kOptMaterialized)                                                           \
  V(kWithClause)                                                           \
  V(kHavingClause)                                                           \
  V(kOptAllClause)                                                           \
  V(kGroupClause)                                                           \
  V(kOptSelectTarget)                                                           \
  V(kSimpleSelect)                                                           \
  V(kRelationExpr)                                                           \
  V(kOrderClause)                                                           \
  V(kSelectLimit)                                                           \
  V(kOptSelectLimit)                                                           \
  V(kForLockingStrength)                                                        \
  V(kLockedRelsList)                                                        \
  V(kTableNameList)                                                        \
  V(kOptNoWaitorSkip)                                                        \
  V(kForLockingItem)                                                        \
  V(kForLockingClause)                                                        \
  V(kForLockingItemList)                                                        \
  V(kOptForLockingClause)                                                        \
  V(kPreparableStmt)                                                           \
  V(kAlterViewStmt)                                                            \
  V(kAlterViewAction)                                                          \
  V(kOwnerSpecification)                                                       \
  V(kSchemaName)                                                               \
  V(kIndexOptViewOptionList)                                                   \
  V(kIndexOptViewOption)                                                       \
  V(kOptEqualViewOptionValue)                                                  \
  V(kViewOptionName)                                                           \
  V(kViewOptionValue)                                                          \
  V(kViewOptionNameList)                                                       \
  V(kOptReindexOptionList)                                                      \
  V(kReindexOptionList)                                                         \
  V(kReindexOption)                                                             \
  V(kDatabaseName)                                                              \
  V(kSystemName)                                                                \
  V(kCreateGroupStmt)                                                          \
  V(kOptWithOptionList)                                                        \
  V(kOptWith)                                                                  \
  V(kOptionList)                                                               \
  V(kOption)                                                                   \
  V(kRoleNameList)                                                             \
  V(kOptEncrypted)                                                             \
  V(kViewNameList)                                                             \
  V(kOptOrReplace)                                                             \
  V(kOptTempToken)                                                             \
  V(kOptRecursive)                                                             \
  V(kOptWithViewOptionList)                                                    \
  V(kCreateTableAsStmt)                                                        \
  V(kCreateAsTarget)                                                           \
  V(kTableAccessMethodClause)                                                  \
  V(kOptWithStorageParameterList)                                              \
  V(kAlterTblspcStmt)                                                          \
  V(kIndexOptTablespaceOptionList)                                             \
  V(kIndexOptTablespaceOption)                                             \
  V(kOptEqualTablespaceOptionValue)                                             \
  V(kTablespaceOptionName)                                             \
  V(kTablespaceOptionValue)                                             \
  V(kAlterConversionStmt)                                                       \
  V(kConversionName)                                                            \
  V(kOptWithData)                                                              \
  V(kUnreservedKeyword) \
  V(kReservedKeyword) \
  V(kColNameKeyword) \
  V(kTypeFuncNameKeyword) \
  V(kColId) \
  V(kTypeFunctionName) \
  V(kNonReservedWord) \
  V(kColLabel) \
  V(kAttrs) \
  V(kAttrName) \
  V(kAnyName) \
  V(kAnyNameList) \
  V(kOptTableElementList) \
  V(kOptTypedTableElementList) \
  V(kTableElementList) \
  V(kTypedTableElementList) \
  V(kTableElement) \
  V(kTypedTableElement) \
  V(kTableLikeClause) \
  V(kTableLikeOptionList) \
  V(kTableLikeOption) \
  V(kColumnOptions) \
  V(kColQualList) \
  V(kColConstraint) \
  V(kColConstraintElem) \
  V(kGeneratedWhen) \
  V(kConstraintAttr) \
  V(kKeyMatch) \
  V(kOptInherit) \
  V(kOptNoInherit) \
  V(kOptColumnList) \
  V(kColumnList) \
  V(kColumnElem) \
  V(kOptPartitionSpec) \
  V(kPartitionSpec) \
  V(kPartParams) \
  V(kPartElem) \
  V(kOptWithReplotions) \
  V(kOnCommitOption) \
  V(kOptTableSpace) \
  V(kOptConsTableSpace) \
  V(kExistingIndex) \
  V(kPartitionBoundSpec) \
  V(kHashPartboundElem) \
  V(kHashPartbound) \
  V(kOptDefinition) \
  V(kDefinition) \
  V(kDefList) \
  V(kDefElem) \
  V(kDefArg) \
  V(kIconst) \
  V(kSconst) \
  V(kSignedIconst) \
  V(kFuncType) \
  V(kOptBy) \
  V(kNumericOnly) \
  V(kNumericOnlyList) \
  V(kOptParenthesizedSeqOptList) \
  V(kSeqOptList) \
  V(kSeqOptElem) \
  V(kReloptions) \
  V(kOptReloptions) \
  V(kReloptionList) \
  V(kReloptionElem) \
  V(kOptClass)                                                                  \

#define ALLCLASS(V)                                                            \
  V(Program)                                                                   \
  V(Stmtlist)                                                                  \
  V(Stmt)                                                                      \
  V(CreateStmt)                                                                \
  V(DropStmt)                                                                  \
  V(AlterStmt)                                                                 \
  V(AlterIndexStmt)                                                            \
  V(AlterGroupStmt)                                                            \
  V(SelectStmt)                                                                \
  V(SelectWithParens)                                                          \
  V(SelectNoParens)                                                            \
  V(SelectClauseList)                                                          \
  V(SelectClause)                                                              \
  V(CombineClause)                                                             \
  V(OptFromClause)                                                             \
  V(SelectTarget)                                                              \
  V(OptWindowClause)                                                           \
  V(WindowClause)                                                              \
  V(WindowDefList)                                                             \
  V(WindowDef)                                                                 \
  V(WindowName)                                                                \
  V(Window)                                                                    \
  V(OptPartition)                                                              \
  V(OptFrameClause)                                                            \
  V(RangeOrRows)                                                               \
  V(FrameBoundStart)                                                           \
  V(FrameBoundEnd)                                                             \
  V(FrameBound)                                                                \
  V(OptFrameExclude)                                                           \
  V(FrameExclude)                                                              \
  V(OptExistWindowName)                                                        \
  V(OptGroupClause)                                                            \
  V(OptHavingClause)                                                           \
  V(OptWhereClause)                                                            \
  V(WhereClause)                                                               \
  V(FromClause)                                                                \
  V(TableRef)                                                                  \
  V(OptOnOrUsing)                                                              \
  V(OnOrUsing)                                                                 \
  V(ColumnNameList)                                                            \
  V(OptTablePrefix)                                                            \
  V(JoinOp)                                                                    \
  V(OptJoinType)                                                               \
  V(ExprList)                                                                  \
  V(OptLimitClause)                                                            \
  V(LimitClause)                                                               \
  V(OptOrderClause)                                                            \
  V(OptOrderNulls)                                                             \
  V(OrderItemList)                                                             \
  V(OrderItem)                                                                 \
  V(OptOrderBehavior)                                                          \
  V(OptWithClause)                                                             \
  V(CteList)                                                                   \
  V(CteTableName)                                                              \
  V(OptAllOrDistinct)                                                          \
  V(CreateTableStmt)                                                           \
  V(CreateIndexStmt)                                                           \
  V(CreateViewStmt)                                                            \
  V(DropIndexStmt)                                                             \
  V(DropTableStmt)                                                             \
  V(DropViewStmt)                                                              \
  V(InsertStmt)                                                                \
  V(InsertTarget)                                                             \
  V(InsertQuery)                                                              \
  V(ValuesDefaultClause)                                                       \
  V(ExprDefaultListWithParens)                                                 \
  V(ExprDefaultList)                                                                             \
  V(OverrideKind)                                                             \
  V(ReturningClause)                                                          \
  V(TargetList)                                                               \
  V(TargetEl)                                                                 \
  V(InsertRest)                                                                \
  V(SuperValuesList)                                                           \
  V(ValuesList)                                                                \
  V(OptOnConflict)                                                             \
  V(OptConflictExpr)                                                           \
  V(IndexedColumnList)                                                         \
  V(IndexedColumn)                                                             \
  V(UpdateStmt)                                                                \
  V(ReindexStmt)                                                               \
  V(AlterAction)                                                               \
  V(ColumnDefList)                                                             \
  V(ColumnDef)                                                                 \
  V(OptColumnConstraintList)                                                   \
  V(ColumnConstraintList)                                                      \
  V(ColumnConstraint)                                                          \
  V(ConstraintType)                                                            \
  V(ForeignClause)                                                             \
  V(OptForeignKeyActions)                                                      \
  V(ForeignKeyActions)                                                         \
  V(KeyActions)                                                                \
  V(OptConstraintAttributeSpec)                                                \
  V(OptInitialTime)                                                            \
  V(ConstraintName)                                                            \
  V(OptTemp)                                                                   \
  V(OptCheckOption)                                                            \
  V(OptColumnNameListP)                                                        \
  V(SetClauseList)                                                             \
  V(SetClause)                                                                 \
  V(Expr)                                                                      \
  V(Operand)                                                                   \
  V(CastExpr)                                                                  \
  V(CountExpr)                                                                 \
  V(AllExpr)                                                                   \
  V(SumExpr)                                                                   \
  V(ScalarExpr)                                                                \
  V(UnaryExpr)                                                                 \
  V(BinaryExpr)                                                                \
  V(LogicExpr)                                                                 \
  V(InExpr)                                                                    \
  V(CaseExpr)                                                                  \
  V(BetweenExpr)                                                               \
  V(ExistsExpr)                                                                \
  V(CaseList)                                                                  \
  V(CaseClause)                                                                \
  V(CompExpr)                                                                  \
  V(ExtractExpr)                                                               \
  V(DatetimeField)                                                             \
  V(ArrayIndex)                                                                \
  V(Literal)                                                                   \
  V(StringLiteral)                                                             \
  V(BoolLiteral)                                                               \
  V(NumLiteral)                                                                \
  V(IntLiteral)                                                                \
  V(FloatLiteral)                                                              \
  V(OptColumn)                                                                 \
  V(OptIfNotExist)                                                             \
  V(OptIfExist)                                                                \
  V(Identifier)                                                                \
  V(TableName)                                                                 \
  V(ColumnName)                                                                \
  V(OptUnique)                                                                 \
  V(ViewName)                                                                  \
  V(IndexName)                                                                 \
  V(TablespaceName)                                                            \
  V(RoleName)                                                                  \
  V(ExtensionName)                                                             \
  V(IndexStorageParameterList)                                                 \
  V(IndexStorageParameter)                                                     \
  V(BinaryOp)                                                                  \
  V(OptNot)                                                                    \
  V(Name)                                                                      \
  V(TypeName)                                                                  \
  V(CharacterType)                                                             \
  V(CharacterWithLength)                                                       \
  V(CharacterWithoutLength)                                                    \
  V(CharacterConflicta)                                                        \
  V(OptVarying)                                                                \
  V(NumericType)                                                               \
  V(OptTableConstraintList)                                                    \
  V(TableConstraintList)                                                       \
  V(TableConstraint)                                                           \
  V(OptAlias)                                                                  \
  V(FuncExpr)                                                                  \
  V(FuncName)                                                                  \
  V(FuncArgs)                                                                  \
  V(OptSemi)                                                                   \
  V(OptNo)                                                                     \
  V(OptNowait)                                                                 \
  V(OptOwnedby)                                                                \
  V(OnOffLiteral)                                                              \
  V(OptConcurrently)                                                           \
  V(OptIfNotExistIndex)                                                        \
  V(OptOnly)                                                                   \
  V(OptUsingMethod)                                                            \
  V(MethodName)                                                                \
  V(OptTablespace)                                                             \
  V(OptWherePredicate)                                                         \
  V(PredicateName)                                                             \
  V(OptWithIndexStorageParameterList)                                          \
  V(OptIncludeColumnNameList)                                                  \
  V(ColumnNameList)                                                            \
  V(OptCollate)                                                                \
  V(CollationName)                                                             \
  V(OptColumnOrExpr)                                                           \
  V(IndexedCreateIndexRestStmtList)                                            \
  V(CreateIndexRestStmt)                                                       \
  V(OptIndexOpclassParameterList)                                              \
  V(OptOpclassParameterList)                                                   \
  V(IndexOpclassParameterList)                                                 \
  V(IndexOpclassParameter)                                                     \
  V(OpclassName)                                                               \
  V(OpclassParameterName)                                                      \
  V(OpclassParameterValue)                                                     \
  V(OptIndexNameList)                                                          \
  V(IndexNameList)                                                             \
  V(OptCascadeRestrict)                                                        \
  V(RoleSpecification)                                                         \
  V(UserName)                                                                  \
  V(UserNameList)                                                                  \
  V(GroupName)                                                                 \
  V(DropGroupStmt)                                                                 \
  V(GroupNameList)                                                                 \
  V(ValuesStmt)                                                                 \
  V(ExprListWithParens)                                                                 \
  V(CommonTableExpr)                                                           \
  V(OptTable)                                                           \
  V(IntoClause)                                                           \
  V(AllorDistinct)                                                          \
  V(DistinctClause)                                                           \
  V(OptTempTableName)                                                           \
  V(OptMaterialized)                                                             \
  V(WithClause)                                                           \
  V(HavingClause)                                                           \
  V(OptAllClause)                                                           \
  V(GroupClause)                                                            \
  V(OptSelectTarget)                                                           \
  V(SimpleSelect)                                                           \
  V(RelationExpr)                                                           \
  V(OrderClause)                                                           \
  V(SelectLimit)                                                           \
  V(OptSelectLimit)                                                           \
  V(ForLockingStrength)                                                           \
  V(LockedRelsList)                                                        \
  V(TableNameList)                                                        \
  V(OptNoWaitorSkip)                                                        \
  V(ForLockingItem)                                                        \
  V(ForLockingClause)                                                        \
  V(ForLockingItemList)                                                        \
  V(OptForLockingClause)                                                        \
  V(PreparableStmt)                                                           \
  V(AlterViewStmt)                                                            \
  V(AlterViewAction)                                                          \
  V(OwnerSpecification)                                                       \
  V(SchemaName)                                                               \
  V(IndexOptViewOptionList)                                                   \
  V(IndexOptViewOption)                                                       \
  V(OptEqualViewOptionValue)                                                  \
  V(ViewOptionName)                                                           \
  V(ViewOptionValue)                                                          \
  V(ViewOptionNameList)                                                        \
  V(OptReindexOptionList)                                                      \
  V(ReindexOptionList)                                                         \
  V(ReindexOption)                                                             \
  V(DatabaseName)                                                              \
  V(SystemName)                                                                \
  V(CreateGroupStmt)                                                           \
  V(OptWithOptionList)                                                         \
  V(OptionList)                                                                \
  V(Option)                                                                    \
  V(RoleNameList)                                                              \
  V(OptEncrypted)                                                              \
  V(OptWith)                                                                   \
  V(ViewNameList)                                                              \
  V(OptOrReplace)                                                              \
  V(OptTempToken)                                                              \
  V(OptRecursive)                                                              \
  V(OptWithViewOptionList)                                                     \
  V(CreateTableAsStmt)                                                         \
  V(CreateAsTarget)                                                            \
  V(TableAccessMethodClause)                                                   \
  V(OptWithStorageParameterList)                                               \
  V(OnCommitOption)                                                            \
  V(AlterTblspcStmt)                                                          \
  V(IndexOptTablespaceOptionList)                                             \
  V(IndexOptTablespaceOption)                                             \
  V(OptEqualTablespaceOptionValue)                                             \
  V(TablespaceOptionName)                                             \
  V(TablespaceOptionValue)                                                     \
  V(AlterConversionStmt)                                                       \
  V(ConversionName)                                                            \
  V(OptWithData)  \
  V(UnreservedKeyword) \
  V(ReservedKeyword) \
  V(ColNameKeyword) \
  V(TypeFuncNameKeyword) \
  V(ColId) \
  V(TypeFunctionName) \
  V(NonReservedWord) \
  V(ColLabel) \
  V(Attrs) \
  V(AttrName) \
  V(AnyName) \
  V(AnyNameList) \
  V(OptTableElementList) \
  V(OptTypedTableElementList) \
  V(TableElementList) \
  V(TypedTableElementList) \
  V(TableElement) \
  V(TypedTableElement) \
  V(TableLikeClause) \
  V(TableLikeOptionList) \
  V(TableLikeOption) \
  V(ColumnOptions) \
  V(ColQualList) \
  V(ColConstraint) \
  V(ColConstraintElem) \
  V(GeneratedWhen) \
  V(ConstraintAttr) \
  V(KeyMatch) \
  V(KeyActions) \
  V(OptInherit) \
  V(OptNoInherit) \
  V(OptColumnList) \
  V(ColumnList) \
  V(ColumnElem) \
  V(OptPartitionSpec) \
  V(PartitionSpec) \
  V(PartParams) \
  V(PartElem) \
  V(TableAccessMethodClause) \
  V(OptWithReplotions) \
  V(OnCommitOption) \
  V(OptTableSpace) \
  V(OptConsTableSpace) \
  V(ExistingIndex) \
  V(PartitionBoundSpec) \
  V(HashPartboundElem) \
  V(HashPartbound) \
  V(OptDefinition) \
  V(Definition) \
  V(DefList) \
  V(DefElem) \
  V(DefArg) \
  V(Iconst) \
  V(Sconst) \
  V(SignedIconst) \
  V(FuncType) \
  V(OptBy) \
  V(NumericOnly) \
  V(NumericOnlyList) \
  V(OptParenthesizedSeqOptList) \
  V(SeqOptList) \
  V(SeqOptElem) \
  V(Reloptions) \
  V(OptReloptions) \
  V(ReloptionList) \
  V(ReloptionElem) \
  V(OptClass) \




#define ALLDATATYPE(V)                                                         \
  V(DataWhatever)                                                              \
  V(DataTableName)                                                             \
  V(DataColumnName)                                                            \
  V(DataViewName)                                                              \
  V(DataFunctionName)                                                          \
  V(DataPragmaKey)                                                             \
  V(DataPragmaValue)                                                           \
  V(DataTableSpaceName)                                                        \
  V(DataSequenceName)                                                          \
  V(DataExtensionName)                                                         \
  V(DataRoleName)                                                              \
  V(DataSchemaName)                                                            \
  V(DataDatabase)                                                              \
  V(DataTriggerName)                                                           \
  V(DataWindowName)                                                            \
  V(DataTriggerFunction)                                                       \
  V(DataDomainName)                                                            \
  V(DataAliasName)                                                             \
  V(DataLiteral)                                                               \
  V(DataIndexName)                                                             \
  V(DataUserName)                                                              \
  V(DataGroupName)                                                             \
  V(DataDatabaseName)                                                          \
  V(DataSystemName)                                                            \
  V(DataConversionName)                                                        \


#define SWITCHSTART switch (case_idx_) {

#define SWITCHEND                                                              \
  default:                                                                     \
                                                                               \
    assert(0);                                                                 \
    }

#define CASESTART(idx) case CASE##idx: {

#define CASEEND                                                                \
  break;                                                                       \
  }

#define TRANSLATESTART IR *res = NULL;

#define GENERATESTART(len) case_idx_ = rand() % len;

#define GENERATEEND return;

#define TRANSLATEEND                                                           \
  v_ir_collector.push_back(res);                                               \
                                                                               \
  return res;

#define TRANSLATEENDNOPUSH return res;

#define SAFETRANSLATE(a) (assert(a != NULL), a->translate(v_ir_collector))

#define SAFEDELETE(a)                                                          \
  if (a != NULL)                                                               \
  a->deep_delete()

#define SAFEDELETELIST(a)                                                      \
  for (auto _i : a)                                                            \
  SAFEDELETE(_i)

#define OP1(a) new IROperator(a)

#define OP2(a, b) new IROperator(a, b)

#define OP3(a, b, c) new IROperator(a, b, c)

#define OPSTART(a) new IROperator(a)

#define OPMID(a) new IROperator("", a, "")

#define OPEND(a) new IROperator("", "", a)

#define OP0() new IROperator()

#define TRANSLATELIST(t, a, b)                                                 \
  res = SAFETRANSLATE(a[0]);                                                   \
  res = new IR(t, OP0(), res);                                                 \
  v_ir_collector.push_back(res);                                               \
  for (int i = 1; i < a.size(); i++) {                                         \
    IR *tmp = SAFETRANSLATE(a[i]);                                             \
    res = new IR(t, OPMID(b), res, tmp);                                       \
    v_ir_collector.push_back(res);                                             \
  }

#define PUSH(a) v_ir_collector.push_back(a)

#define MUTATESTART                                                            \
  IR *res = NULL;                                                              \
  auto randint = get_rand_int(3);                                              \
  switch (randint) {

#define DOLEFT case 0: {

#define DORIGHT                                                                \
  break;                                                                       \
  }                                                                            \
                                                                               \
  case 1: {

#define DOBOTH                                                                 \
  break;                                                                       \
  }                                                                            \
  case 2: {

#define MUTATEEND                                                              \
  }                                                                            \
  }                                                                            \
                                                                               \
  return res;

#endif
