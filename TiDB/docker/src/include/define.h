#ifndef __DEFINE_SQLRIGHTIR_H__
#define __DEFINE_SQLRIGHTIR_H__

#define ALLTYPE(V)                         \
  /* New one here!!! */                    \
  V(TypeUnknown)                           \
  V(TypeRoot)                              \
  V(TypeIntegerLiteral)                    \
  V(TypeFloatLiteral)                      \
  V(TypeStringLiteral)                     \
  V(TypeIdentifier)                        \
  V(TypeIndexAdviseStmt)                   \
  V(TypeMaxIndexNumClause)                 \
  V(TypeAlterDatabaseStmt)                 \
  V(TypeDropDatabaseStmt)                  \
  V(TypeIndexPartSpecification)            \
  V(TypeReferenceDef)                      \
  V(TypeOnDeleteOpt)                       \
  V(TypeOnUpdateOpt)                       \
  V(TypeColumnOption)                      \
  V(TypeIndexOption)                       \
  V(TypeConstraint)                        \
  V(TypeColumnDef)                         \
  V(TypeFieldType)                         \
  V(TypeCreateDatabaseStmt)                \
  V(TypeCreateTableStmt)                   \
  V(TypeDropTableStmt)                     \
  V(TypeDropPlacementPolicyStmt)           \
  V(TypeDropSequenceStmt)                  \
  V(TypeRenameTableStmt)                   \
  V(TypeTableToTable)                      \
  V(TypeCreateViewStmt)                    \
  V(TypeCreatePlacementPolicyStmt)         \
  V(TypeCreateSequenceStmt)                \
  V(TypeIndexLockAndAlgorithm)             \
  V(TypeCreateIndexStmt)                   \
  V(TypeDropIndexStmt)                     \
  V(TypeLockTablesStmt)                    \
  V(TypeUnlockTablesStmt)                  \
  V(TypeCleanupTableLockStmt)              \
  V(TypeRepairTableStmt)                   \
  V(TypePlacementOption)                   \
  V(TypeTableOption)                       \
  V(TypeSequenceOption)                    \
  V(TypeColumnPosition)                    \
  V(TypeAlterOrderItem)                    \
  V(TypeAlterTableSpec)                    \
  V(TypeAlterTableStmt)                    \
  V(TypeTruncateTableStmt)                 \
  V(TypeSubPartitionDefinition)            \
  V(TypePartitionDefinitionClauseNone)     \
  V(TypePartitionDefinitionClauseLessThan) \
  V(TypePartitionDefinitionClauseIn)       \
  V(TypePartitionDefinitionClauseHistory)  \
  V(TypePartitionDefinition)               \
  V(TypePartitionMethod)                   \
  V(TypePartitionOptions)                  \
  V(TypeRecoverTableStmt)                  \
  V(TypeFlashBackTableStmt)                \
  V(TypeAttributesSpec)                    \
  V(TypeStatsOptionsSpec)                  \
  V(TypeAlterPlacementPolicyStmt)          \
  V(TypeAlterSequenceStmt)                 \
  V(TypeJoin)                              \
  V(TypeTableName)                         \
  V(TypeIndexHint)                         \
  V(TypeDeleteTableList)                   \
  V(TypeOnCondition)                       \
  V(TypeTableSource)                       \
  V(TypeWildCardField)                     \
  V(TypeSelectField)                       \
  V(TypeFieldList)                         \
  V(TypeTableRefsClause)                   \
  V(TypeByItem)                            \
  V(TypeGroupByClause)                     \
  V(TypeHavingClause)                      \
  V(TypeOrderByClause)                     \
  V(TypeTableSample)                       \
  V(TypeCommonTableExpression)             \
  V(TypeWithClause)                        \
  V(TypeSelectStmt)                        \
  V(TypeSetOprSelectList)                  \
  V(TypeSetOprStmt)                        \
  V(TypeColumnNameOrUserVar)               \
  V(TypeLoadDataStmt)                      \
  V(TypeFieldsClause)                      \
  V(TypeLinesClause)                       \
  V(TypeCallStmt)                          \
  V(TypePriorityEnum)                      \
  V(TypeInsertStmt)                        \
  V(TypeDeleteStmt)                        \
  V(TypeNonTransactionalDeleteStmt)        \
  V(TypeUpdateStmt)                        \
  V(TypeLimit)                             \
  V(TypeUserIdentity)                      \
  V(TypeRoleIdentity)                      \
  V(TypeShowStmt)                          \
  V(TypeWindowSpec)                        \
  V(TypeSelectIntoOption)                  \
  V(TypePartitionByClause)                 \
  V(TypeFrameClause)                       \
  V(TypeFrameBound)                        \
  V(TypeSplitRegionStmt)                   \
  V(TypeSplitOption)                       \
  V(TypeAsOfClause)                        \
  V(TypeBinaryOperationExpr)               \
  V(TypeWhenClause)                        \
  V(TypeCaseExpr)                          \
  V(TypeSubqueryExpr)                      \
  V(TypeCompareSubqueryExpr)               \
  V(TypeTableNameExpr)                     \
  V(TypeColumnName)                        \
  V(TypeColumnNameExpr)                    \
  V(TypeDefaultExpr)                       \
  V(TypeExistsSubqueryExpr)                \
  V(TypePatternInExpr)                     \
  V(TypeIsNullExpr)                        \
  V(TypePatternLikeExpr)                   \
  V(TypeParenthesesExpr)                   \
  V(TypePositionExpr)                      \
  V(TypePatternRegexpExpr)                 \
  V(TypeRowExpr)                           \
  V(TypeUnaryOperationExpr)                \
  V(TypeValuesExpr)                        \
  V(TypeVariableExpr)                      \
  V(TypeMaxValueExpr)                      \
  V(TypeMatchAgainst)                      \
  V(TypeSetCollationExpr)                  \
  V(TypeFuncCallExpr)                      \
  V(TypeFuncCastExpr)                      \
  V(TypeTrimDirectionExpr)                 \
  V(TypeAggregateFuncExpr)                 \
  V(TypeWindowFuncExpr)                    \
  V(TypeTimeUnitExpr)                      \
  V(TypeGetFormatSelectorExpr)             \
  V(TypeAuthOption)                        \
  V(TypeTraceStmt)                         \
  V(TypeExplainForStmt)                    \
  V(TypeExplainStmt)                       \
  V(TypePlanReplayerStmt)                  \
  V(TypeCompactTableStmt)                  \
  V(TypePrepareStmt)                       \
  V(TypeDeallocateStmt)                    \
  V(TypeExecuteStmt)                       \
  V(TypeBeginStmt)                         \
  V(TypeBinlogStmt)                        \
  V(TypeCompletionType)                    \
  V(TypeCommitStmt)                        \
  V(TypeRollbackStmt)                      \
  V(TypeUseStmt)                           \
  V(TypeVariableAssignment)                \
  V(TypeFlushStmt)                         \
  V(TypeKillStmt)                          \
  V(TypeSetStmt)                           \
  V(TypeSetConfigStmt)                     \
  V(TypeSetPwdStmt)                        \
  V(TypeChangeStmt)                        \
  V(TypeSetRoleStmt)                       \
  V(TypeSetDefaultRoleStmt)                \
  V(TypeUserSpec)                          \
  V(TypeTLSOption)                         \
  V(TypeResourceOption)                    \
  V(TypePasswordOrLockOption)              \
  V(TypeCreateUserStmt)                    \
  V(TypeAlterUserStmt)                     \
  V(TypeAlterInstanceStmt)                 \
  V(TypeDropUserStmt)                      \
  V(TypeCreateBindingStmt)                 \
  V(TypeDropBindingStmt)                   \
  V(TypeSetBindingStmt)                    \
  V(TypeCreateStatisticsStmt)              \
  V(TypeDropStatisticsStmt)                \
  V(TypeDoStmt)                            \
  V(TypeShowSlow)                          \
  V(TypeAdminStmt)                         \
  V(TypePrivElem)                          \
  V(TypeObjectTypeType)                    \
  V(TypeGrantLevel)                        \
  V(TypeRevokeStmt)                        \
  V(TypeRevokeRoleStmt)                    \
  V(TypeGrantStmt)                         \
  V(TypeGrantRoleStmt)                     \
  V(TypeShutdownStmt)                      \
  V(TypeRestartStmt)                       \
  V(TypeRenameUserStmt)                    \
  V(TypeHelpStmt)                          \
  V(TypeUserToUser)                        \
  V(TypeBRIEOption)                        \
  V(TypeBRIEStmt)                          \
  V(TypePurgeImportStmt)                   \
  V(TypeCreateImportStmt)                  \
  V(TypeStopImportStmt)                    \
  V(TypeResumeImportStmt)                  \
  V(TypeAlterImportStmt)                   \
  V(TypeDropImportStmt)                    \
  V(TypeShowImportStmt)                    \
  V(TypeHintTable)                         \
  V(TypeTableOptimizerHint)                \
  V(TypeAnalyzeTableStmt)                  \
  V(TypeDropStatsStmt)                     \
  V(TypeLoadStatsStmt)                     \
  V(TypeCreateTableAsStmt)                 \
  V(TypeValuesClause)                      \
  V(TypeExpr)                              \
  V(TypeBetweenExpr)                       \
  V(TypeIsTruthExpr)                       \
  V(TypeWhereClause)                       \
  V(TypeStmtList)                          \
  V(TypeStmt)

#define ALLDATATYPE(V)         \
  V(DataNone)                  \
  V(DataUnknownType)           \
  V(DataCharSet)               \
  V(DataEncryptionName)        \
  V(DataChangeFeed)            \
  V(DataDatabaseName)          \
  V(DataSuperRegion)           \
  V(DataRoleName)              \
  V(DataCatalogName)           \
  V(DataSchemaName)            \
  V(DataFunctionName)          \
  V(DataFunctionExpr)          \
  V(DataExtensionName)         \
  V(DataCollationName)         \
  V(DataColumnName)            \
  V(DataConstraintName)        \
  V(DataViewName)              \
  V(DataSequenceName)          \
  V(DataTableName)             \
  V(DataRegionName)            \
  V(DataTemplateName)          \
  V(DataEncodingName)          \
  V(DataCTypeName)             \
  V(DataIndexName)             \
  V(DataTypeName)              \
  V(DataPartitionName)         \
  V(DataRangeName)             \
  V(DataFamilyName)            \
  V(DataStatsName)             \
  V(DataSettingName)           \
  V(DataSavePointName)         \
  V(DataPrivilege)             \
  V(DataWindowName)            \
  V(DataStatementPreparedName) \
  V(DataCursorName)            \
  V(DataZoneName)              \
  V(DataChannelName)           \
  V(DataTableAliasName)        \
  V(DataColumnAliasName)       \
  V(DataLiteral)               \
  V(DataViewColumnName)        \
  V(DataStorageParams)         \
  V(DataPolicyName)            \
  V(DataTableSpaceName)        \
  V(DataForeignKeyName)        \
  V(DataVariableName)

#define ALLCONTEXTFLAGS(V)  \
  V(ContextUnknown)         \
  V(ContextDefine)          \
  V(ContextUse)             \
  V(ContextUndefine)        \
  V(ContextReplaceDefine)   \
  V(ContextReplaceUndefine) \
  V(ContextNoModi)          \
  V(ContextUseFollow)

#define ALLFUNCTIONTYPES(V) \
  V(FUNCAGGR)               \
  V(FUNCWINDOW)             \
  V(FUNCARRAY)              \
  V(FUNCENUM)               \
  V(FUNCBOOL)               \
  V(FUNCCOMPARE)            \
  V(FUNCCRYPTO)             \
  V(FUNCDATETIME)           \
  V(FUNCDECIMAL)            \
  V(FUNCFLOAT)              \
  V(FUNCUUID)               \
  V(FUNCINET)               \
  V(FUNCINT)                \
  V(FUNCJSONB)              \
  V(FUNCARRAYSTRING)        \
  V(FUNCSEQUENCE)           \
  V(FUNCSTREAM)             \
  V(FUNCSTRING)             \
  V(FUNCSYSTEMINFO)         \
  V(FUNCTIMETZ)             \
  V(FUNCSYSTEMREPAIR)       \
  V(FUNCUNKNOWN)

#define ALLDATAAFFINITY(V)       \
  /* New one here!!! */          \
  V(AFFIUNKNOWN)                 \
  V(AFFIANY)                     \
  V(AFFIBIT)                     \
  V(AFFIBOOL)                    \
  V(AFFIBYTES)                   \
  V(AFFICOLLATE)                 \
  V(AFFIDATE)                    \
  V(AFFIENUM)                    \
  V(AFFIDECIMAL)                 \
  V(AFFIFLOAT)                   \
  V(AFFIINET)                    \
  V(AFFIINT)                     \
  V(AFFIINTERVAL)                \
  V(AFFIINTERVALTZ)              \
  V(AFFIJSONB)                   \
  V(AFFIOID)                     \
  V(AFFISERIAL)                  \
  V(AFFISTRING)                  \
  V(AFFITIME)                    \
  V(AFFITIMETZ)                  \
  V(AFFITIMESTAMP)               \
  V(AFFITIMESTAMPTZ)             \
  V(AFFIUUID)                    \
  V(AFFIGEOGRAPHY)               \
  V(AFFIGEOMETRY)                \
  V(AFFIBOX2D)                   \
  V(AFFIVOID)                    \
  V(AFFIPOINT)                   \
  V(AFFILINESTRING)              \
  V(AFFIPOLYGON)                 \
  V(AFFIMULTIPOINT)              \
  V(AFFIMULTILINESTRING)         \
  V(AFFIMULTIPOLYGON)            \
  V(AFFIGEOMETRYCOLLECTION)      \
  V(AFFIOIDWRAPPER)              \
  V(AFFIWHOLESTMT)               \
  V(AFFIONOFF)                   \
  V(AFFIONOFFAUTO)               \
  V(AFFIARRAY)                   \
  V(AFFIARRAYANY)                \
  V(AFFIARRAYUNKNOWN)            \
  V(AFFIARRAYBIT)                \
  V(AFFIARRAYBOOL)               \
  V(AFFIARRAYBYTES)              \
  V(AFFIARRAYCOLLATE)            \
  V(AFFIARRAYDATE)               \
  V(AFFIARRAYENUM)               \
  V(AFFIARRAYDECIMAL)            \
  V(AFFIARRAYFLOAT)              \
  V(AFFIARRAYINET)               \
  V(AFFIARRAYINT)                \
  V(AFFIARRAYINTERVAL)           \
  V(AFFIARRAYJSONB)              \
  V(AFFIARRAYOID)                \
  V(AFFIARRAYSERIAL)             \
  V(AFFIARRAYSTRING)             \
  V(AFFIARRAYTIME)               \
  V(AFFIARRAYTIMETZ)             \
  V(AFFIARRAYTIMESTAMP)          \
  V(AFFIARRAYTIMESTAMPTZ)        \
  V(AFFIARRAYUUID)               \
  V(AFFIARRAYGEOGRAPHY)          \
  V(AFFIARRAYGEOMETRY)           \
  V(AFFIARRAYBOX2D)              \
  V(AFFIARRAYVOID)               \
  V(AFFIARRAYPOINT)              \
  V(AFFIARRAYLINESTRING)         \
  V(AFFIARRAYPOLYGON)            \
  V(AFFIARRAYMULTIPOINT)         \
  V(AFFIARRAYMULTILINESTRING)    \
  V(AFFIARRAYMULTIPOLYGON)       \
  V(AFFIARRAYGEOMETRYCOLLECTION) \
  V(AFFIARRAYOIDWRAPPER)         \
  V(AFFIARRAYWHOLESTMT)          \
  V(AFFIARRAYONOFF)              \
  V(AFFIARRAYONOFFAUTO)          \
  V(AFFITABLENAME)               \
  V(AFFICOLUMNNAME)              \
  V(AFFICONSTRAINTNAME)          \
  V(AFFITUPLE)

#define ALLCOLLATIONS(V) \
  V(defaultcollation)    \
  V(und)                 \
  V(aa)                  \
  V(af)                  \
  V(ar)                  \
  V(as)                  \
  V(az)                  \
  V(be)                  \
  V(bg)                  \
  V(bn)                  \
  V(bs)                  \
  V(ca)                  \
  V(cs)                  \
  V(cy)                  \
  V(da)                  \
  V(de)                  \
  V(dz)                  \
  V(ee)                  \
  V(el)                  \
  V(en)                  \
  V(eo)                  \
  V(es)                  \
  V(et)                  \
  V(fa)                  \
  V(fi)                  \
  V(fil)                 \
  V(fo)                  \
  V(fr)                  \
  V(gu)                  \
  V(ha)                  \
  V(haw)                 \
  V(he)                  \
  V(hi)                  \
  V(hr)                  \
  V(hu)                  \
  V(hy)                  \
  V(ig)                  \
  V(is)                  \
  V(ja)                  \
  V(kk)                  \
  V(kl)                  \
  V(km)                  \
  V(kn)                  \
  V(ko)                  \
  V(kok)                 \
  V(ln)                  \
  V(lt)                  \
  V(lv)                  \
  V(mk)                  \
  V(ml)                  \
  V(mr)                  \
  V(mt)                  \
  V(my)                  \
  V(nb)                  \
  V(nn)                  \
  V(nso)                 \
  V(om)                  \
  V(pa)                  \
  V(pl)                  \
  V(ps)                  \
  V(ro)                  \
  V(ru)                  \
  V(se)                  \
  V(si)                  \
  V(sk)                  \
  V(sl)                  \
  V(sq)                  \
  V(sr)                  \
  V(ssy)                 \
  V(sv)                  \
  V(ta)                  \
  V(te)                  \
  V(th)                  \
  V(tn)                  \
  V(to)                  \
  V(tr)                  \
  V(uk)                  \
  V(ur)                  \
  V(vi)                  \
  V(wae)                 \
  V(yo)                  \
  V(zh)

#define SAFEDELETE(a) \
  if (a != NULL)      \
  a->deep_delete()

#define SAFEDELETELIST(a) \
  for (auto _i : a)       \
  SAFEDELETE(_i)

#define OP1(a) new IROperator(a)

#define OP2(a, b) new IROperator(a, b)

#define OP3(a, b, c) new IROperator(a, b, c)

#define OPSTART(a) new IROperator(a)

#define OPMID(a) new IROperator("", a, "")

#define OPEND(a) new IROperator("", "", a)

#define OP0() new IROperator()

#define MUTATESTART               \
  IR* res = NULL;                 \
  auto randint = get_rand_int(3); \
  switch (randint) {

#define DOLEFT case 0: {

#define DORIGHT \
  break;        \
  }             \
                \
  case 1: {

#define DOBOTH \
  break;       \
  }            \
  case 2: {

#define MUTATEEND \
  }               \
  }               \
                  \
  return res;

#endif // __DEFINE_SQLRIGHTIR_H__
