#pragma once

#ifndef __sql_ir_define
#define __sql_ir_define

#include <string>
#include <cstring>
#include <fstream>
#include <iostream>
#include <vector>
#include <set>
#include <algorithm>

#ifndef __has_include
  static_assert(false, "__has_include not supported");
#else
#  if __cplusplus >= 201703L && __has_include(<filesystem>)
#    include <filesystem>
namespace fs = std::filesystem;
#  elif __has_include(<experimental/filesystem>)
#    include <experimental/filesystem>
namespace fs = std::experimental::filesystem;
#  elif __has_include(<boost/filesystem.hpp>)
#    include <boost/filesystem.hpp>
namespace fs = boost::filesystem;
#  endif
#endif

namespace duckdb_libpgquery {

/* Yu: Implement the IR structure from ParserFuzz here.
** ParserFuzz injected code.
*/

#define ALLTYPE(V) \
	V(kStmtblock)   \
	V(kStmtmulti)   \
	V(kStmt)   \
	V(kAlterTableStmt)   \
	V(kAlterIdentityColumnOptionList)   \
	V(kAlterColumnDefault)   \
	V(kAlterIdentityColumnOption)   \
	V(kAlterGenericOptionList)   \
	V(kAlterTableCmd)   \
	V(kAlterTableCmd_1)   \
	V(kAlterTableCmd_2)   \
	V(kAlterTableCmd_3)   \
	V(kAlterTableCmd_4)   \
	V(kAlterTableCmd_5)   \
	V(kAlterTableCmd_6)   \
	V(kAlterTableCmd_7)   \
	V(kAlterTableCmd_8)   \
	V(kAlterTableCmd_9)   \
	V(kAlterTableCmd_10)   \
	V(kAlterTableCmd_11)   \
	V(kAlterTableCmd_12)   \
	V(kAlterTableCmd_13)   \
	V(kAlterTableCmd_14)   \
	V(kAlterTableCmd_15)   \
	V(kAlterUsing)   \
	V(kAlterGenericOptionElem)   \
	V(kAlterTableCmds)   \
	V(kAlterGenericOptions)   \
	V(kOptSetData)   \
	V(kDeallocateStmt)   \
	V(kQualifiedName)   \
	V(kColId)   \
	V(kColIdOrString)   \
	V(kSconst)   \
	V(kIndirection)   \
	V(kIndirectionEl)   \
	V(kAttrName)   \
	V(kColLabel)   \
	V(kRenameStmt)   \
	V(kRenameStmt_1)   \
	V(kRenameStmt_2)   \
	V(kRenameStmt_3)   \
	V(kRenameStmt_4)   \
	V(kRenameStmt_5)   \
	V(kRenameStmt_6)   \
	V(kOptColumn)   \
	V(kInsertStmt)   \
	V(kInsertStmt_1)   \
	V(kInsertStmt_2)   \
	V(kInsertStmt_3)   \
	V(kInsertStmt_4)   \
	V(kInsertStmt_5)   \
	V(kInsertRest)   \
	V(kInsertRest_1)   \
	V(kInsertTarget)   \
	V(kOptByNameOrPosition)   \
	V(kOptConfExpr)   \
	V(kOptWithClause)   \
	V(kInsertColumnItem)   \
	V(kSetClause)   \
	V(kOptOrAction)   \
	V(kOptOnConflict)   \
	V(kOptOnConflict_1)   \
	V(kOptOnConflict_2)   \
	V(kIndexElem)   \
	V(kIndexElem_1)   \
	V(kIndexElem_2)   \
	V(kIndexElem_3)   \
	V(kIndexElem_4)   \
	V(kIndexElem_5)   \
	V(kIndexElem_6)   \
	V(kIndexElem_7)   \
	V(kIndexElem_8)   \
	V(kIndexElem_9)   \
	V(kReturningClause)   \
	V(kOverrideKind)   \
	V(kSetTargetList)   \
	V(kOptCollate)   \
	V(kOptClass)   \
	V(kInsertColumnList)   \
	V(kSetClauseList)   \
	V(kSetClauseListOptComma)   \
	V(kIndexParams)   \
	V(kSetTarget)   \
	V(kCreateTypeStmt)   \
	V(kOptEnumValList)   \
	V(kEnumValList)   \
	V(kPragmaStmt)   \
	V(kCreateSeqStmt)   \
	V(kCreateSeqStmt_1)   \
	V(kCreateSeqStmt_2)   \
	V(kCreateSeqStmt_3)   \
	V(kOptSeqOptList)   \
	V(kExecuteStmt)   \
	V(kExecuteStmt_1)   \
	V(kExecuteStmt_2)   \
	V(kExecuteStmt_3)   \
	V(kExecuteStmt_4)   \
	V(kExecuteStmt_5)   \
	V(kExecuteStmt_6)   \
	V(kExecuteParamExpr)   \
	V(kExecuteParamList)   \
	V(kExecuteParamClause)   \
	V(kAlterSeqStmt)   \
	V(kSeqOptList)   \
	V(kOptWith)   \
	V(kNumericOnly)   \
	V(kSeqOptElem)   \
	V(kOptBy)   \
	V(kSignedIconst)   \
	V(kTransactionStmt)   \
	V(kOptTransaction)   \
	V(kUseStmt)   \
	V(kCreateStmt)   \
	V(kCreateStmt_1)   \
	V(kCreateStmt_2)   \
	V(kCreateStmt_3)   \
	V(kCreateStmt_4)   \
	V(kCreateStmt_5)   \
	V(kCreateStmt_6)   \
	V(kCreateStmt_7)   \
	V(kCreateStmt_8)   \
	V(kCreateStmt_9)   \
	V(kConstraintAttributeSpec)   \
	V(kDefArg)   \
	V(kOptParenthesizedSeqOptList)   \
	V(kGenericOptionArg)   \
	V(kKeyAction)   \
	V(kColConstraint)   \
	V(kColConstraintElem)   \
	V(kColConstraintElem_1)   \
	V(kColConstraintElem_2)   \
	V(kGeneratedColumnType)   \
	V(kOptGeneratedColumnType)   \
	V(kGeneratedConstraintElem)   \
	V(kGeneratedConstraintElem_1)   \
	V(kGenericOptionElem)   \
	V(kKeyUpdate)   \
	V(kKeyActions)   \
	V(kOnCommitOption)   \
	V(kReloptions)   \
	V(kOptNoInherit)   \
	V(kTableConstraint)   \
	V(kTableLikeOption)   \
	V(kReloptionList)   \
	V(kExistingIndex)   \
	V(kConstraintAttr)   \
	V(kDefinition)   \
	V(kTableLikeOptionList)   \
	V(kGenericOptionName)   \
	V(kConstraintAttributeElem)   \
	V(kColumnDef)   \
	V(kColumnDef_1)   \
	V(kColumnDef_2)   \
	V(kColumnDef_3)   \
	V(kDefList)   \
	V(kIndexName)   \
	V(kTableElement)   \
	V(kDefElem)   \
	V(kOptDefinition)   \
	V(kOptTableElementList)   \
	V(kColumnElem)   \
	V(kOptColumnList)   \
	V(kColQualList)   \
	V(kKeyDelete)   \
	V(kReloptionElem)   \
	V(kReloptionElem_1)   \
	V(kColumnList)   \
	V(kColumnListOptComma)   \
	V(kFuncType)   \
	V(kConstraintElem)   \
	V(kConstraintElem_1)   \
	V(kConstraintElem_2)   \
	V(kConstraintElem_3)   \
	V(kConstraintElem_4)   \
	V(kConstraintElem_5)   \
	V(kConstraintElem_6)   \
	V(kTableElementList)   \
	V(kKeyMatch)   \
	V(kTableLikeClause)   \
	V(kOptTemp)   \
	V(kGeneratedWhen)   \
	V(kDropStmt)   \
	V(kDropStmt_1)   \
	V(kDropStmt_2)   \
	V(kDropStmt_3)   \
	V(kDropStmt_4)   \
	V(kDropStmt_5)   \
	V(kDropStmt_6)   \
	V(kDropStmt_7)   \
	V(kDropStmt_8)   \
	V(kDropStmt_9)   \
	V(kDropStmt_10)   \
	V(kDropTypeAnyName)   \
	V(kDropTypeName)   \
	V(kAnyNameList)   \
	V(kOptDropBehavior)   \
	V(kDropTypeNameOnAnyName)   \
	V(kTypeNameList)   \
	V(kCreateFunctionStmt)   \
	V(kCreateFunctionStmt_1)   \
	V(kCreateFunctionStmt_2)   \
	V(kCreateFunctionStmt_3)   \
	V(kCreateFunctionStmt_4)   \
	V(kCreateFunctionStmt_5)   \
	V(kCreateFunctionStmt_6)   \
	V(kCreateFunctionStmt_7)   \
	V(kCreateFunctionStmt_8)   \
	V(kCreateFunctionStmt_9)   \
	V(kCreateFunctionStmt_10)   \
	V(kCreateFunctionStmt_11)   \
	V(kCreateFunctionStmt_12)   \
	V(kCreateFunctionStmt_13)   \
	V(kCreateFunctionStmt_14)   \
	V(kCreateFunctionStmt_15)   \
	V(kCreateFunctionStmt_16)   \
	V(kCreateFunctionStmt_17)   \
	V(kCreateFunctionStmt_18)   \
	V(kMacroAlias)   \
	V(kParamList)   \
	V(kUpdateStmt)   \
	V(kUpdateStmt_1)   \
	V(kUpdateStmt_2)   \
	V(kUpdateStmt_3)   \
	V(kUpdateStmt_4)   \
	V(kCopyStmt)   \
	V(kCopyStmt_1)   \
	V(kCopyStmt_2)   \
	V(kCopyStmt_3)   \
	V(kCopyStmt_4)   \
	V(kCopyStmt_5)   \
	V(kCopyStmt_6)   \
	V(kCopyStmt_7)   \
	V(kCopyStmt_8)   \
	V(kCopyStmt_9)   \
	V(kCopyStmt_10)   \
	V(kCopyStmt_11)   \
	V(kCopyFrom)   \
	V(kCopyDelimiter)   \
	V(kCopyGenericOptArgList)   \
	V(kOptUsing)   \
	V(kOptAs)   \
	V(kOptProgram)   \
	V(kCopyOptions)   \
	V(kCopyGenericOptArg)   \
	V(kCopyGenericOptElem)   \
	V(kOptOids)   \
	V(kCopyOptList)   \
	V(kOptBinary)   \
	V(kCopyOptItem)   \
	V(kCopyGenericOptArgListItem)   \
	V(kCopyFileName)   \
	V(kCopyGenericOptList)   \
	V(kSelectStmt)   \
	V(kSelectWithParens)   \
	V(kSelectNoParens)   \
	V(kSelectNoParens_1)   \
	V(kSelectNoParens_2)   \
	V(kSelectNoParens_3)   \
	V(kSelectNoParens_4)   \
	V(kSelectNoParens_5)   \
	V(kSelectNoParens_6)   \
	V(kSelectNoParens_7)   \
	V(kSelectNoParens_8)   \
	V(kSelectNoParens_9)   \
	V(kSelectNoParens_10)   \
	V(kSelectNoParens_11)   \
	V(kSelectClause)   \
	V(kOptSelect)   \
	V(kSimpleSelect)   \
	V(kSimpleSelect_1)   \
	V(kSimpleSelect_2)   \
	V(kSimpleSelect_3)   \
	V(kSimpleSelect_4)   \
	V(kSimpleSelect_5)   \
	V(kSimpleSelect_6)   \
	V(kSimpleSelect_7)   \
	V(kSimpleSelect_8)   \
	V(kSimpleSelect_9)   \
	V(kSimpleSelect_10)   \
	V(kSimpleSelect_11)   \
	V(kSimpleSelect_12)   \
	V(kSimpleSelect_13)   \
	V(kSimpleSelect_14)   \
	V(kSimpleSelect_15)   \
	V(kSimpleSelect_16)   \
	V(kSimpleSelect_17)   \
	V(kSimpleSelect_18)   \
	V(kSimpleSelect_19)   \
	V(kSimpleSelect_20)   \
	V(kSimpleSelect_21)   \
	V(kSimpleSelect_22)   \
	V(kSimpleSelect_23)   \
	V(kSimpleSelect_24)   \
	V(kSimpleSelect_25)   \
	V(kSimpleSelect_26)   \
	V(kSimpleSelect_27)   \
	V(kSimpleSelect_28)   \
	V(kSimpleSelect_29)   \
	V(kSimpleSelect_30)   \
	V(kSimpleSelect_31)   \
	V(kSimpleSelect_32)   \
	V(kSimpleSelect_33)   \
	V(kSimpleSelect_34)   \
	V(kSimpleSelect_35)   \
	V(kSimpleSelect_36)   \
	V(kSimpleSelect_37)   \
	V(kSimpleSelect_38)   \
	V(kSimpleSelect_39)   \
	V(kSimpleSelect_40)   \
	V(kSimpleSelect_41)   \
	V(kSimpleSelect_42)   \
	V(kSimpleSelect_43)   \
	V(kSimpleSelect_44)   \
	V(kSimpleSelect_45)   \
	V(kSimpleSelect_46)   \
	V(kSimpleSelect_47)   \
	V(kSimpleSelect_48)   \
	V(kSimpleSelect_49)   \
	V(kSimpleSelect_50)   \
	V(kSimpleSelect_51)   \
	V(kSimpleSelect_52)   \
	V(kSimpleSelect_53)   \
	V(kSimpleSelect_54)   \
	V(kSimpleSelect_55)   \
	V(kSimpleSelect_56)   \
	V(kSimpleSelect_57)   \
	V(kSimpleSelect_58)   \
	V(kSimpleSelect_59)   \
	V(kValueOrValues)   \
	V(kPivotKeyword)   \
	V(kUnpivotKeyword)   \
	V(kPivotColumnEntry)   \
	V(kPivotColumnListInternal)   \
	V(kPivotColumnList)   \
	V(kWithClause)   \
	V(kCteList)   \
	V(kCommonTableExpr)   \
	V(kCommonTableExpr_1)   \
	V(kCommonTableExpr_2)   \
	V(kOptMaterialized)   \
	V(kIntoClause)   \
	V(kOptTempTableName)   \
	V(kOptTable)   \
	V(kAllOrDistinct)   \
	V(kByName)   \
	V(kDistinctClause)   \
	V(kOptAllClause)   \
	V(kOptIgnoreNulls)   \
	V(kOptSortClause)   \
	V(kSortClause)   \
	V(kSortbyList)   \
	V(kSortby)   \
	V(kSortby_1)   \
	V(kSortby_2)   \
	V(kOptAscDesc)   \
	V(kOptNullsOrder)   \
	V(kSelectLimit)   \
	V(kOptSelectLimit)   \
	V(kLimitClause)   \
	V(kLimitClause_1)   \
	V(kOffsetClause)   \
	V(kSampleCount)   \
	V(kSampleClause)   \
	V(kOptSampleFunc)   \
	V(kTablesampleEntry)   \
	V(kTablesampleEntry_1)   \
	V(kTablesampleEntry_2)   \
	V(kTablesampleClause)   \
	V(kOptTablesampleClause)   \
	V(kOptRepeatableClause)   \
	V(kSelectLimitValue)   \
	V(kSelectOffsetValue)   \
	V(kSelectFetchFirstValue)   \
	V(kIOrFConst)   \
	V(kRowOrRows)   \
	V(kFirstOrNext)   \
	V(kGroupClause)   \
	V(kGroupByList)   \
	V(kGroupByListOptComma)   \
	V(kGroupByItem)   \
	V(kEmptyGroupingSet)   \
	V(kRollupClause)   \
	V(kCubeClause)   \
	V(kGroupingSetsClause)   \
	V(kGroupingOrGroupingId)   \
	V(kHavingClause)   \
	V(kQualifyClause)   \
	V(kForLockingClause)   \
	V(kOptForLockingClause)   \
	V(kForLockingItems)   \
	V(kForLockingItem)   \
	V(kForLockingItem_1)   \
	V(kForLockingStrength)   \
	V(kLockedRelsList)   \
	V(kOptNowaitOrSkip)   \
	V(kValuesClause)   \
	V(kValuesClauseOptComma)   \
	V(kFromClause)   \
	V(kFromList)   \
	V(kFromListOptComma)   \
	V(kTableRef)   \
	V(kTableRef_1)   \
	V(kTableRef_2)   \
	V(kTableRef_3)   \
	V(kTableRef_4)   \
	V(kTableRef_5)   \
	V(kTableRef_6)   \
	V(kTableRef_7)   \
	V(kTableRef_8)   \
	V(kTableRef_9)   \
	V(kTableRef_10)   \
	V(kOptPivotGroupBy)   \
	V(kOptIncludeNulls)   \
	V(kSinglePivotValue)   \
	V(kPivotHeader)   \
	V(kPivotValue)   \
	V(kPivotValueList)   \
	V(kUnpivotHeader)   \
	V(kUnpivotValue)   \
	V(kUnpivotValueList)   \
	V(kJoinedTable)   \
	V(kJoinedTable_1)   \
	V(kJoinedTable_2)   \
	V(kJoinedTable_3)   \
	V(kJoinedTable_4)   \
	V(kJoinedTable_5)   \
	V(kJoinedTable_6)   \
	V(kJoinedTable_7)   \
	V(kJoinedTable_8)   \
	V(kJoinedTable_9)   \
	V(kAliasClause)   \
	V(kOptAliasClause)   \
	V(kFuncAliasClause)   \
	V(kJoinType)   \
	V(kJoinOuter)   \
	V(kJoinQual)   \
	V(kRelationExpr)   \
	V(kFuncTable)   \
	V(kRowsfromItem)   \
	V(kRowsfromList)   \
	V(kOptColDefList)   \
	V(kOptOrdinality)   \
	V(kWhereClause)   \
	V(kTableFuncElementList)   \
	V(kTableFuncElement)   \
	V(kTableFuncElement_1)   \
	V(kOptCollateClause)   \
	V(kColidTypeList)   \
	V(kColidTypeList_1)   \
	V(kRowOrStruct)   \
	V(kOptTypename)   \
	V(kTypename)   \
	V(kTypename_1)   \
	V(kOptArrayBounds)   \
	V(kSimpleTypename)   \
	V(kConstTypename)   \
	V(kGenericType)   \
	V(kOptTypeModifiers)   \
	V(kNumeric)   \
	V(kOptFloat)   \
	V(kBit)   \
	V(kConstBit)   \
	V(kBitWithLength)   \
	V(kBitWithoutLength)   \
	V(kCharacter)   \
	V(kConstCharacter)   \
	V(kCharacterWithLength)   \
	V(kCharacterWithoutLength)   \
	V(kOptVarying)   \
	V(kConstDatetime)   \
	V(kConstInterval)   \
	V(kOptTimezone)   \
	V(kYearKeyword)   \
	V(kMonthKeyword)   \
	V(kDayKeyword)   \
	V(kHourKeyword)   \
	V(kMinuteKeyword)   \
	V(kSecondKeyword)   \
	V(kMillisecondKeyword)   \
	V(kMicrosecondKeyword)   \
	V(kOptInterval)   \
	V(kAExpr)   \
	V(kAExpr_1)   \
	V(kAExpr_2)   \
	V(kAExpr_3)   \
	V(kAExpr_4)   \
	V(kAExpr_5)   \
	V(kAExpr_6)   \
	V(kAExpr_7)   \
	V(kAExpr_8)   \
	V(kAExpr_9)   \
	V(kAExpr_10)   \
	V(kAExpr_11)   \
	V(kAExpr_12)   \
	V(kAExpr_13)   \
	V(kAExpr_14)   \
	V(kAExpr_15)   \
	V(kAExpr_16)   \
	V(kAExpr_17)   \
	V(kAExpr_18)   \
	V(kBExpr)   \
	V(kBExpr_1)   \
	V(kCExpr)   \
	V(kDExpr)   \
	V(kIndirectionExpr)   \
	V(kStructExpr)   \
	V(kFuncApplication)   \
	V(kFuncApplication_1)   \
	V(kFuncApplication_2)   \
	V(kFuncApplication_3)   \
	V(kFuncApplication_4)   \
	V(kFuncApplication_5)   \
	V(kFuncApplication_6)   \
	V(kFuncApplication_7)   \
	V(kFuncApplication_8)   \
	V(kFuncApplication_9)   \
	V(kFuncApplication_10)   \
	V(kFuncApplication_11)   \
	V(kFuncExpr)   \
	V(kFuncExpr_1)   \
	V(kFuncExpr_2)   \
	V(kFuncExpr_3)   \
	V(kFuncExprWindowless)   \
	V(kFuncExprCommonSubexpr)   \
	V(kListComprehension)   \
	V(kListComprehension_1)   \
	V(kListComprehension_2)   \
	V(kWithinGroupClause)   \
	V(kFilterClause)   \
	V(kExportClause)   \
	V(kWindowClause)   \
	V(kWindowDefinitionList)   \
	V(kWindowDefinition)   \
	V(kOverClause)   \
	V(kWindowSpecification)   \
	V(kWindowSpecification_1)   \
	V(kWindowSpecification_2)   \
	V(kOptExistingWindowName)   \
	V(kOptPartitionClause)   \
	V(kOptFrameClause)   \
	V(kFrameExtent)   \
	V(kFrameBound)   \
	V(kQualifiedRow)   \
	V(kRow)   \
	V(kDictArg)   \
	V(kDictArguments)   \
	V(kDictArgumentsOptComma)   \
	V(kMapArg)   \
	V(kMapArguments)   \
	V(kMapArgumentsOptComma)   \
	V(kOptMapArgumentsOptComma)   \
	V(kSubType)   \
	V(kAllOp)   \
	V(kMathOp)   \
	V(kQualOp)   \
	V(kQualAllOp)   \
	V(kSubqueryOp)   \
	V(kAnyOperator)   \
	V(kCExprList)   \
	V(kCExprListOptComma)   \
	V(kExprList)   \
	V(kExprListOptComma)   \
	V(kOptExprListOptComma)   \
	V(kFuncArgList)   \
	V(kFuncArgExpr)   \
	V(kTypeList)   \
	V(kExtractList)   \
	V(kExtractArg)   \
	V(kOverlayList)   \
	V(kOverlayList_1)   \
	V(kOverlayList_2)   \
	V(kOverlayList_3)   \
	V(kOverlayPlacing)   \
	V(kPositionList)   \
	V(kSubstrList)   \
	V(kSubstrList_1)   \
	V(kSubstrList_2)   \
	V(kSubstrFrom)   \
	V(kSubstrFor)   \
	V(kTrimList)   \
	V(kInExpr)   \
	V(kCaseExpr)   \
	V(kCaseExpr_1)   \
	V(kWhenClauseList)   \
	V(kWhenClause)   \
	V(kCaseDefault)   \
	V(kCaseArg)   \
	V(kColumnref)   \
	V(kIndirectionEl_1)   \
	V(kOptSliceBound)   \
	V(kOptIndirection)   \
	V(kOptFuncArguments)   \
	V(kExtendedIndirectionEl)   \
	V(kExtendedIndirectionEl_1)   \
	V(kExtendedIndirection)   \
	V(kOptExtendedIndirection)   \
	V(kOptAsymmetric)   \
	V(kOptTargetListOptComma)   \
	V(kTargetList)   \
	V(kTargetListOptComma)   \
	V(kTargetEl)   \
	V(kExceptList)   \
	V(kOptExceptList)   \
	V(kReplaceListEl)   \
	V(kReplaceList)   \
	V(kReplaceListOptComma)   \
	V(kOptReplaceList)   \
	V(kQualifiedNameList)   \
	V(kNameList)   \
	V(kNameListOptComma)   \
	V(kNameListOptCommaOptBracket)   \
	V(kName)   \
	V(kFuncName)   \
	V(kAexprConst)   \
	V(kAexprConst_1)   \
	V(kAexprConst_2)   \
	V(kAexprConst_3)   \
	V(kAexprConst_4)   \
	V(kAexprConst_5)   \
	V(kAexprConst_6)   \
	V(kIconst)   \
	V(kTypeFunctionName)   \
	V(kFunctionNameToken)   \
	V(kTypeNameToken)   \
	V(kAnyName)   \
	V(kAttrs)   \
	V(kOptNameList)   \
	V(kParamName)   \
	V(kColLabelOrString)   \
	V(kPrepareStmt)   \
	V(kPrepareStmt_1)   \
	V(kPrepTypeClause)   \
	V(kPreparableStmt)   \
	V(kCreateSchemaStmt)   \
	V(kOptSchemaEltList)   \
	V(kSchemaStmt)   \
	V(kIndexStmt)   \
	V(kIndexStmt_1)   \
	V(kIndexStmt_2)   \
	V(kIndexStmt_3)   \
	V(kIndexStmt_4)   \
	V(kIndexStmt_5)   \
	V(kIndexStmt_6)   \
	V(kIndexStmt_7)   \
	V(kIndexStmt_8)   \
	V(kIndexStmt_9)   \
	V(kIndexStmt_10)   \
	V(kIndexStmt_11)   \
	V(kIndexStmt_12)   \
	V(kIndexStmt_13)   \
	V(kIndexStmt_14)   \
	V(kAccessMethod)   \
	V(kAccessMethodClause)   \
	V(kOptConcurrently)   \
	V(kOptIndexName)   \
	V(kOptReloptions)   \
	V(kOptUnique)   \
	V(kAlterObjectSchemaStmt)   \
	V(kCheckPointStmt)   \
	V(kOptColId)   \
	V(kExportStmt)   \
	V(kExportStmt_1)   \
	V(kImportStmt)   \
	V(kExplainStmt)   \
	V(kExplainStmt_1)   \
	V(kOptVerbose)   \
	V(kExplainOptionArg)   \
	V(kExplainableStmt)   \
	V(kNonReservedWord)   \
	V(kNonReservedWordOrSconst)   \
	V(kExplainOptionList)   \
	V(kAnalyzeKeyword)   \
	V(kOptBooleanOrString)   \
	V(kExplainOptionElem)   \
	V(kExplainOptionName)   \
	V(kVariableSetStmt)   \
	V(kSetRest)   \
	V(kGenericSet)   \
	V(kVarValue)   \
	V(kZoneValue)   \
	V(kZoneValue_1)   \
	V(kZoneValue_2)   \
	V(kVarList)   \
	V(kLoadStmt)   \
	V(kFileName)   \
	V(kRepoPath)   \
	V(kVacuumStmt)   \
	V(kVacuumStmt_1)   \
	V(kVacuumStmt_2)   \
	V(kVacuumStmt_3)   \
	V(kVacuumStmt_4)   \
	V(kVacuumStmt_5)   \
	V(kVacuumStmt_6)   \
	V(kVacuumStmt_7)   \
	V(kVacuumOptionElem)   \
	V(kOptFull)   \
	V(kVacuumOptionList)   \
	V(kOptFreeze)   \
	V(kDeleteStmt)   \
	V(kDeleteStmt_1)   \
	V(kDeleteStmt_2)   \
	V(kDeleteStmt_3)   \
	V(kRelationExprOptAlias)   \
	V(kWhereOrCurrentClause)   \
	V(kUsingClause)   \
	V(kAnalyzeStmt)   \
	V(kAnalyzeStmt_1)   \
	V(kAnalyzeStmt_2)   \
	V(kAttachStmt)   \
	V(kAttachStmt_1)   \
	V(kAttachStmt_2)   \
	V(kDetachStmt)   \
	V(kOptDatabase)   \
	V(kOptDatabaseAlias)   \
	V(kIdentName)   \
	V(kIdentList)   \
	V(kVariableResetStmt)   \
	V(kGenericReset)   \
	V(kResetRest)   \
	V(kVariableShowStmt)   \
	V(kShowOrDescribe)   \
	V(kOptTables)   \
	V(kVarName)   \
	V(kTableId)   \
	V(kCallStmt)   \
	V(kViewStmt)   \
	V(kViewStmt_1)   \
	V(kViewStmt_2)   \
	V(kViewStmt_3)   \
	V(kViewStmt_4)   \
	V(kViewStmt_5)   \
	V(kViewStmt_6)   \
	V(kViewStmt_7)   \
	V(kViewStmt_8)   \
	V(kViewStmt_9)   \
	V(kViewStmt_10)   \
	V(kViewStmt_11)   \
	V(kViewStmt_12)   \
	V(kViewStmt_13)   \
	V(kViewStmt_14)   \
	V(kViewStmt_15)   \
	V(kViewStmt_16)   \
	V(kViewStmt_17)   \
	V(kViewStmt_18)   \
	V(kViewStmt_19)   \
	V(kViewStmt_20)   \
	V(kOptCheckOption)   \
	V(kCreateAsStmt)   \
	V(kCreateAsStmt_1)   \
	V(kCreateAsStmt_2)   \
	V(kCreateAsStmt_3)   \
	V(kCreateAsStmt_4)   \
	V(kCreateAsStmt_5)   \
	V(kCreateAsStmt_6)   \
	V(kOptWithData)   \
	V(kCreateAsTarget)   \
	V(kCreateAsTarget_1)   \
	V(kCreateAsTarget_2)   \
	V(kIdentifier)   \
	V(kStringLiteral)   \
	V(kFloatLiteral)   \
	V(kIntegerLiteral)   \
	V(kBinLiteral)   \
	V(kBoolLiteral)   \
	V(kUnknown)


#define ALLDATATYPE(V) \
	V(DataWhatever) \
	V(DataTableName) \
	V(DataColumnName) \
	V(DataViewName) \
	V(DataFunctionName) \
	V(DataFunctionParams) \
	V(DataPragmaKey) \
	V(DataPragmaValue) \
	V(DataTableSpaceName) \
	V(DataUndoTableSpaceName) \
	V(DataSequenceName) \
	V(DataExtensionName) \
	V(DataRoleName) \
	V(DataSchemaName) \
	V(DataDatabase) \
	V(DataTriggerName) \
	V(DataWindowName) \
	V(DataTriggerFunction) \
	V(DataDomainName) \
	V(DataAliasName) \
    V(DataFixLater) \
    V(DataIndexName) \
    V(DataUserName) \
    V(DataHostName) \
    V(DataCollate) \
    V(DataCharsetName) \
    V(DataProcedureName) \
    V(DataProcedureParams) \
    V(DataServerName) \
    V(DataWrapperName) \
    V(DataSavePoint) \
    V(DataGroupName) \
    V(DataLogFileGroupName) \
    V(DataFileName) \
    V(DataRepoPath) \
    V(DataSystemVarName) \
    V(DataAliasTableName) \
    V(DataTableNameFollow) \
    V(DataColumnNameFollow) \
    V(DataConstraintName) \
    V(DataVarName) \
    V(DataStmtName) \
    V(DataPluginName) \
    V(DataComponentName) \
    V(DataEngineName) \
    V(DataParserName) \
    V(DataForeignKey) \
    V(DataPartitionName) \
    V(DataStorageName) \
    V(DataSampleFunction) \
    V(DataDatabaseFollow) \
    V(DataAccessMethod) \
    V(DataCheckPointName) \
    V(DataDictArg) \
    V(DataPrepareName) \
    V(DataCompressionName) \
    V(DataTypeName) \
    V(DataReloptionName) \
    V(DataClassName) \
    V(DataLiteral)


    enum DATAFLAG {
        kUse,
        kMapToClosestOne,
        kNoSplit,
        kGlobal,
        kReplace,
        kUndefine,
        kAlias,
        kMapToAll,
        kDefine,
        kNoModi,
        kUseDefine,  // Immediate use of the defined column. In PRIMARY KEY(), INDEX() etc.
        kFlagUnknown
    };


#define SWITCHSTART \
    switch(case_idx_){

#define SWITCHEND \
    default: \
        \
        assert(0); \
        \
    }

#define CASESTART(idx) \
    case CASE##idx: {\


#define CASEEND \
            break;\
        }

#define TRANSLATESTART \
    IR *res = NULL;

#define GENERATESTART(len) \
    case_idx_ = rand() % len ;

#define GENERATEEND \
    return ;

#define TRANSLATEEND \
     v_ir_collector.push_back(res); \
        \
     return res;

#define TRANSLATEENDNOPUSH \
     return res;

#define SAFETRANSLATE(a) \
    (assert(a != NULL), a->translate(v_ir_collector))

#define SAFEDELETE(a) \
    if(a != NULL) a->deep_delete()

#define SAFEDELETELIST(a) \
    for(auto _i: a) \
        SAFEDELETE(_i)

#define OP1(a) \
    new IROperator(a)

#define OP2(a, b) \
    new IROperator(a,b)

#define OP3(a,b,c) \
    new IROperator(a,b,c)

#define OPSTART(a) \
    new IROperator(a)

#define OPMID(a) \
new IROperator("", a, "")

#define OPEND(a) \
    new IROperator("", "", a)

#define OP0() \
    new IROperator()


#define TRANSLATELIST(t, a, b) \
    res = SAFETRANSLATE(a[0]); \
    res = new IR(t, OP0(), res) ; \
    v_ir_collector.push_back(res); \
    for(int i = 1; i < a.size(); i++){ \
        IR * tmp = SAFETRANSLATE(a[i]); \
        res = new IR(t, OPMID(b), res, tmp); \
        v_ir_collector.push_back(res); \
    }

#define PUSH(a) \
    v_ir_collector.push_back(a)

#define MUTATESTART \
    IR * res = NULL;       \
    auto randint = get_rand_int(3); \
    switch(randint) { \

#define DOLEFT \
    case 0:{ \

#define DORIGHT \
    break; \
    } \
    \
    case 1: { \

#define DOBOTH  \
    break; }  \
    case 2:{ \

#define MUTATEEND \
    } \
    } \
    \
    return res; \



    enum IRTYPE{
#define DECLARE_TYPE(v)  \
    v,
        ALLTYPE(DECLARE_TYPE)
#undef DECLARE_TYPE
    };

    enum DATATYPE{
#define DECLARE_TYPE(v)  \
    k##v,
        ALLDATATYPE(DECLARE_TYPE)
#undef DECLARE_TYPE
    };

    class IROperator{
    public:
        IROperator(std::string prefix="", std::string middle="", std::string suffix=""):
                prefix_(prefix), middle_(middle), suffix_(suffix) {}

        std::string prefix_;
        std::string middle_;
        std::string suffix_;
    };


    class IR{
    public:
        IR(IRTYPE type,  IROperator* op, IR* left=NULL, IR* right=NULL):
                type_(type), op_(op), left_(left), right_(right), data_type_(kDataWhatever), data_flag_(kFlagUnknown){
            if (left_)
                left_->parent_ = this;
            if (right_)
                right_->parent_ = this;
        }

        IR(IRTYPE type, std::string str_val, DATATYPE data_type=kDataWhatever, DATAFLAG flag = kUse):
                type_(type), op_(NULL), left_(NULL), right_(NULL), str_val_(str_val), data_type_(data_type), data_flag_(flag){
            if (left_)
                left_->parent_ = this;
            if (right_)
                right_->parent_ = this;
        }

        IR(IRTYPE type, bool b_val):
                type_(type), bool_val_(b_val), left_(NULL), op_(NULL), right_(NULL), data_type_(kDataWhatever), data_flag_(kFlagUnknown){
            if (left_)
                left_->parent_ = this;
            if (right_)
                right_->parent_ = this;
        }

        IR(IRTYPE type, unsigned long long_val):
                type_(type), long_val_(long_val),left_(NULL), op_(NULL), right_(NULL), data_type_(kDataWhatever), data_flag_(kFlagUnknown){
            if (left_)
                left_->parent_ = this;
            if (right_)
                right_->parent_ = this;
        }

        IR(IRTYPE type, int int_val):
                type_(type), int_val_(int_val),left_(NULL), op_(NULL), right_(NULL), data_type_(kDataWhatever), data_flag_(kFlagUnknown){
            if (left_)
                left_->parent_ = this;
            if (right_)
                right_->parent_ = this;
        }

        IR(IRTYPE type, double f_val):
                type_(type), float_val_(f_val),left_(NULL), op_(NULL), right_(NULL), data_type_(kDataWhatever), data_flag_(kFlagUnknown){
            if (left_)
                left_->parent_ = this;
            if (right_)
                right_->parent_ = this;
        }

        IR(IRTYPE type, IROperator * op, IR * left, IR* right, double f_val, std::string str_val, unsigned int mutated_times, DATAFLAG flag):
                type_(type), float_val_(f_val), op_(op), left_(left), right_(right), str_val_(str_val),
                data_type_(kDataWhatever), data_flag_(flag), mutated_times_(mutated_times) {
            if (left_)
                left_->parent_ = this;
            if (right_)
                right_->parent_ = this;
        }

        IR(const IR* ir, IR* left, IR* right){
            this->type_ = ir->type_;
            if(ir->op_ != NULL)
                this->op_ = OP3(ir->op_->prefix_, ir->op_->middle_, ir->op_->suffix_);
            else{
                this->op_ = OP0();
            }
            this->left_ = left;
            this->right_ = right;
            this->str_val_ = ir->str_val_;
            this->long_val_ = ir->long_val_;
            this->data_type_ = ir->data_type_;
            this->data_flag_ = ir->data_flag_;
            this->mutated_times_ = ir->mutated_times_;

            if (left_)
                left_->parent_ = this;
            if (right_)
                right_->parent_ = this;

        }

        /* Data Structures */
        IRTYPE type_;
        union{
            int int_val_;
            unsigned long long_val_;
            double float_val_;
            bool bool_val_;
        };

        IROperator* op_ = NULL;
        IR* left_ = NULL;
        IR* right_ = NULL;
        IR* parent_ = NULL;

        std::string str_val_;

        DATAFLAG data_flag_;
        DATATYPE data_type_;

        int uniq_id_in_tree_ = -1;

        unsigned int mutated_times_ = 0;

        bool is_node_struct_fixed = false; // Do not mutate this IR if this set to be true.
        bool is_mutating = false;

        /* Helper functions */

        void drop() {
            if (this->op_)
                delete this->op_;
            delete this;
        };
        void deep_drop(){
            if (this->left_)
                this->left_->deep_drop();

            if (this->right_)
                this->right_->deep_drop();

            this->drop();
        };

        IR* get_left() {
            if (left_ == NULL) return NULL;
            else return left_;
        };
        IR* get_right() {
            if (right_ == NULL) return NULL;
            else return right_;
        };

        std::string get_prefix() {
            if (!op_) return NULL;
            return op_->prefix_;
        };
        std::string get_middle() {
            if (!op_) return NULL;
            return op_->middle_;
        };
        std::string get_suffix() {
            if (!op_) return NULL;
            return op_->suffix_;
        };
        IR* get_parent() {
            if (!parent_) return NULL;
            else return parent_;
        };

        bool update_left(IR* new_left) {
            this->left_ = new_left;
            if (new_left)
                new_left->parent_ = this;

            return true;
        };

        bool update_right(IR* new_right) {
            this->right_ = new_right;
            if (new_right)
                new_right->parent_ = this;

            return true;
        };

        bool swap_node(IR* old_node, IR* new_node) {
            if (old_node == NULL) {
                // printf("swap_node failed because old_node == NULL \n\n\n");
                return false;
            }

            IR *parent = this->locate_parent(old_node);

            if (parent == NULL) {
                // printf("swap_node failed because locate_parent failed. \n\n\n");
                return false;
            }
            else if (parent->left_ == old_node)
                parent->update_left(new_node);
            else if (parent->right_ == old_node)
                parent->update_right(new_node);
            else {
                // printf("swap_node failed because parent is not connected to new_node. \n\n\n");
                return false;
            }

            old_node->parent_ = NULL;

            return true;
        };

        bool detatch_node(IR* node) {
            return swap_node(node, NULL);
        };

        bool is_empty() {
            if (op_) {
                if (op_->prefix_ != "" || op_->middle_ != "" || op_->suffix_ != "" ) {
                    return false;
                }
            }
            if (str_val_ != "") {
                return false;
            }
            if (left_ || right_) {
                return false;
            }
            return true;
        };

        IR* locate_parent(IR* child) {
            for (IR *p = child; p; p = p->parent_)
                if (p->parent_ == this)
                    return child->parent_;

            return NULL;
        }
        IR* get_root() {
            IR *node = this;

            while (node->parent_ != NULL)
                node = node->parent_;

            return node;
        };

        std::string to_string() {
            auto res = to_string_core();
            this->trim_string(res);
            return res;
        }
        std::string to_string_core() {

            std::string res;

            if( op_ != NULL && op_->prefix_ != "" ){
                res += op_->prefix_ + " ";
            }

            if(left_ != NULL) {
                res += left_->to_string_core() + " ";
            }


            if( op_!= NULL && op_->middle_ != "") {
                res += op_->middle_ + " ";
            }
            if (
                    get_ir_type() == kStringLiteral
                    ) {
                res += " '" + str_val_ + "' ";
            }
            else if (str_val_ != "") {
                res += " " + str_val_ + " ";
            }
			else if (get_ir_type() == kIntegerLiteral) {
				// str_val_ == "" && ir_type == kIntegerLiteral
				res += std::to_string(int_val_);
			}


            if(right_ != NULL) {
                res += right_->to_string_core() + " ";
            }


            if(op_!= NULL && op_->suffix_ != "") {
                res += op_->suffix_ + " ";
            }

            return res;
        };

        DATATYPE get_data_type() {
            return data_type_;
        };

        void set_data_type(DATATYPE data_type) {
            this->data_type_ = data_type;
        };

        DATAFLAG get_data_flag() {
            return data_flag_;
        };

        void set_data_flag(DATAFLAG data_flag) {
            this->data_flag_ = data_flag;
        };

        std::string get_str_val() {
            return this->str_val_;
        };

        void set_str_val(std::string in) {
            this->str_val_ = in;
            return;
        }

        IRTYPE get_ir_type() {
            return type_;
        };

        static void trim_string(std::string &res) {

            int effect_idx = 0, idx = 0;
            bool prev_is_space = false;
            int sz = res.size();

            // skip leading spaces
            for (; idx < sz && res[idx] == ' '; idx++)
                ;

            // now idx points to the first non-space character
            for (; idx < sz; idx++) {

                char &c = res[idx];

                if (c == ' ') {

                    if (prev_is_space)
                        continue;

                    prev_is_space = true;
                    res[effect_idx++] = c;

                } else if (c == ';' || c == ',') {

                    if (prev_is_space)
                        res[effect_idx - 1] = c;
                    else
                        res[effect_idx++] = c;

                    prev_is_space = false;

                } else if (c == '@') {
                    // Skip following spaces.
                    res[effect_idx++] = c;
                }
                else {

                    prev_is_space = false;
                    res[effect_idx++] = c;
                }
            }

            if (effect_idx > 0 && res[effect_idx - 1] == ' ')
                effect_idx--;

            res.resize(effect_idx);
        }

        IR* deep_copy() {
            IR *left = NULL, *right = NULL, *copy_res;
            IROperator *op = NULL;

            if (this->left_)
                left = this->left_->deep_copy();
            if (this->right_)
                right = this->right_->deep_copy();

            if (this->op_)
                op = OP3(this->op_->prefix_, this->op_->middle_, this->op_->suffix_);

            copy_res = new IR(this->type_, op, left, right, this->float_val_,
                              this->str_val_, this->mutated_times_, kFlagUnknown);
            copy_res->data_type_ = this->data_type_;
            copy_res->data_flag_ = this->data_flag_;

            if (this->parent_) {
                copy_res->parent_ = this->parent_;
            } else {
                copy_res->parent_ = NULL;
            }

            copy_res->is_node_struct_fixed = this->is_node_struct_fixed;
            copy_res->is_mutating = this->is_mutating;

            return copy_res;
        }
    };

	#define s8 int8_t
	#define s16 int16_t
	#define s32 int32_t
	#define s64 int64_t
	#define u8 uint8_t
	#define u16 uint16_t
	#define u32 uint32_t
	#define u64 uint64_t
	#define likely(_x) __builtin_expect(!!(_x), 1)
	#define unlikely(_x) __builtin_expect(!!(_x), 0)
	#define MAP_SIZE (1 << 18)

	class GramCovMap {
	public:
	  GramCovMap() {
		this->block_cov_map = new unsigned char[MAP_SIZE]();
		memset(this->block_cov_map, 0, MAP_SIZE);
		this->block_virgin_map = new unsigned char[MAP_SIZE]();
		memset(this->block_virgin_map, 0xff, MAP_SIZE);

		this->edge_cov_map = new unsigned char[MAP_SIZE]();
		memset(this->edge_cov_map, 0, MAP_SIZE);
		this->edge_virgin_map = new unsigned char[MAP_SIZE]();
		memset(this->edge_virgin_map, 0xff, MAP_SIZE);
		edge_prev_cov = 0;
	  }
	  ~GramCovMap() {
		delete[](this->block_cov_map);
		delete[](this->block_virgin_map);
		delete[](this->edge_cov_map);
		delete[](this->edge_virgin_map);
	  }

	  std::vector<unsigned long long> cur_path_hash_vec;

	  u8 has_new_grammar_bits(bool is_debug = false, const std::string in = "") {
	//    has_new_grammar_bits(this->block_cov_map, this->block_virgin_map, is_debug); // disabled block coverage
		return has_new_grammar_bits(this->edge_cov_map, this->edge_virgin_map, is_debug, in);
	  }
	  u8 has_new_grammar_bits(u8 *cur_cov_map, u8 *cur_virgin_map, bool is_debug = false, const std::string in = "") {

#if defined(__x86_64__) || defined(__arm64__) || defined(__aarch64__)

	  	u64 *current = (u64 *)cur_cov_map;
	  	u64 *virgin = (u64 *)cur_virgin_map;

	  	u32 i = (MAP_SIZE >> 3);

#else

	  	u32 *current = (u32 *)this->cov_map;
	  	u32 *virgin = (u32 *)this->virgin_map;

	  	u32 i = (MAP_SIZE >> 2);

#endif /* ^__x86_64__ __arm64__ __aarch64__ */

	  	u8 ret = 0;

	  	while (i--) {

	  		/* Optimize for (*current & *virgin) == 0 - i.e., no bits in current bitmap
				 that have not been already cleared from the virgin map - since this will
				 almost always be the case. */

	  		if (unlikely(*current) && unlikely(*current & *virgin)) {

	  			if (likely(ret < 2) || unlikely(is_debug)) {

	  				u8 *cur = (u8 *)current;
	  				u8 *vir = (u8 *)virgin;

	  				/* Looks like we have not found any new bytes yet; see if any non-zero
						 bytes in current[] are pristine in virgin[]. */

#if defined(__x86_64__) || defined(__arm64__) || defined(__aarch64__)

	  				if ((cur[0] && vir[0] == 0xff) || (cur[1] && vir[1] == 0xff) ||
						  (cur[2] && vir[2] == 0xff) || (cur[3] && vir[3] == 0xff) ||
						  (cur[4] && vir[4] == 0xff) || (cur[5] && vir[5] == 0xff) ||
						  (cur[6] && vir[6] == 0xff) || (cur[7] && vir[7] == 0xff)) {
	  					ret = 2;
	  					if (unlikely(is_debug)) {
	  						std::vector<u8> byte = get_cur_new_byte(cur, vir);
	  						for (const u8 &cur_byte : byte) {
	  							this->gram_log_map_id(i, cur_byte, in);
	  						}
	  					}
						  } else if (unlikely(ret != 2))
						  	ret = 1;

#else

	  				if ((cur[0] && vir[0] == 0xff) || (cur[1] && vir[1] == 0xff) ||
						  (cur[2] && vir[2] == 0xff) || (cur[3] && vir[3] == 0xff))
	  					ret = 2;
	  				else if (unlikely(ret != 2))
	  					ret = 1;

#endif /* ^__x86_64__ __arm64__ __aarch64__ */
	  			}
	  			*virgin &= ~*current;
	  		}

	  		current++;
	  		virgin++;
	  	}

	  	return ret;
		}

	  void reset_block_cov_map() { memset(this->block_cov_map, 0, MAP_SIZE); }
	  void reset_block_virgin_map() { memset(this->block_virgin_map, 0, MAP_SIZE); }

	  void reset_edge_cov_map() {
		memset(this->edge_cov_map, 0, MAP_SIZE);
		edge_prev_cov = 0;
	  }
	  void reset_edge_virgin_map() {
		memset(this->edge_virgin_map, 0, MAP_SIZE);
		edge_prev_cov = 0;
	  }

	  void log_cov_map(unsigned int cur_cov) {
		unsigned int offset = (edge_prev_cov ^ cur_cov);
		if (edge_cov_map[offset] < 0xff) {
		  edge_cov_map[offset]++;
		}
		edge_prev_cov = (cur_cov >> 1);

		if (block_cov_map[cur_cov] < 0xff) {
		  block_cov_map[cur_cov]++;
		}
	  }

	  void log_edge_cov_map(unsigned int prev_cov, unsigned int cur_cov) {
		unsigned int offset = ((prev_cov >> 1) ^ cur_cov);
		if (edge_cov_map[offset] < 0xff) {
		  edge_cov_map[offset]++;
		}
		this->log_grammar_path(cur_cov);
		return;
	  }

	  inline void log_grammar_path(unsigned int cur_cov) {
		if(std::find(this->cur_path_hash_vec.begin(), cur_path_hash_vec.end(), cur_cov) == cur_path_hash_vec.end()) {
		  this->cur_path_hash_vec.push_back(cur_cov);
		}
	  }

	  inline double get_total_block_cov_percentage() {
		u32 t_bytes = this->count_non_255_bytes(this->block_virgin_map);
		return ((double)t_bytes * 100.0) / MAP_SIZE;
	  }
	  inline u32 get_total_block_cov_size_num() {
		return this->count_non_255_bytes(this->block_virgin_map);
	  }

	  inline double get_total_edge_cov_percentage() {
		u32 t_bytes = this->count_non_255_bytes(this->edge_virgin_map);
		return ((double)t_bytes * 100.0) / MAP_SIZE;
	  }
	  inline u32 get_total_edge_cov_size_num() {
		return this->count_non_255_bytes(this->edge_virgin_map);
	  }

	  unsigned char *get_edge_cov_map() { return this->edge_cov_map; }

	private:
	  unsigned char *block_cov_map = nullptr;
	  unsigned char *block_virgin_map = nullptr;
	  unsigned char *edge_cov_map = nullptr;
	  unsigned char *edge_virgin_map = nullptr;
	  unsigned int edge_prev_cov = 0;

	  /* count the number of non-255 bytes set in the bitmap. used strictly for the
	   status screen, several calls per second or so. */
	  // copy from afl-fuzz.
	  u32 count_non_255_bytes(u8 *mem) {
	  #define FF(_b) (0xff << ((_b) << 3))
	  		u32 *ptr = (u32 *)mem;
	  		u32 i = (MAP_SIZE >> 2);
	  		u32 ret = 0;

	  		while (i--) {

	  			u32 v = *(ptr++);

	  			/* This is called on the virgin bitmap, so optimize for the most likely
	  				 case. */

	  			if (v == 0xffffffff)
	  				continue;
	  			if ((v & FF(0)) != FF(0))
	  				ret++;
	  			if ((v & FF(1)) != FF(1))
	  				ret++;
	  			if ((v & FF(2)) != FF(2))
	  				ret++;
	  			if ((v & FF(3)) != FF(3))
	  				ret++;
	  		}

	  		return ret;
	  #undef FF
	  }

	  inline std::vector<u8> get_cur_new_byte(u8 *cur, u8 *vir) {
		std::vector<u8> new_byte_v;
		for (u8 i = 0; i < 8; i++) {
		  if (cur[i] && vir[i] == 0xff)
			new_byte_v.push_back(i);
		}
		return new_byte_v;
	  }

	  inline void gram_log_map_id (u32 i, u8 byte, const std::string in = "") {
		std::fstream gram_id_out;
		i = (MAP_SIZE >> 3) - i - 1 ;
		u32 actual_idx = i * 8 + byte;

		if (!fs::exists("./gram_cov.txt")) {
		  gram_id_out.open("./gram_cov.txt", std::fstream::out |
		  std::fstream::trunc);
		} else {
		  gram_id_out.open("./gram_cov.txt", std::fstream::out |
		  std::fstream::app);
		}
		gram_id_out << actual_idx << std::endl;
		gram_id_out.flush();
		gram_id_out.close();

		if (!fs::exists("./new_gram_file/")) {
		  fs::create_directory("./new_gram_file/");
		}
		std::fstream map_id_seed_output;
		map_id_seed_output.open(
			"./new_gram_file/" + std::to_string(actual_idx) + ".txt",
			std::fstream::out | std::fstream::trunc);
		map_id_seed_output << in;
		map_id_seed_output.close();

	  }
	};

	#undef s8
	#undef s16
	#undef s32
	#undef s64
	#undef u8
	#undef u16
	#undef u32
	#undef u64
	#undef likely
	#undef unlikely
	#undef MAP_SIZE

/*
** End ParserFuzz injected code.
*/

} // namespace duckdb_libpgquery

#endif

