#pragma once
#ifndef __DEFINE_H__
#define __DEFINE_H__


#define ALLTYPE(V) \
	V(kProgram) \
	V(kStmtlist) \
	V(kStmt) \
	V(kCreateStmt) \
	V(kDropStmt) \
	V(kAlterStmt) \
	V(kSelectStmt) \
	V(kSelectWithParens) \
	V(kSelectNoParens) \
	V(kSelectClauseList) \
	V(kSelectClause) \
	V(kCombineClause) \
	V(kOptFromClause) \
	V(kSelectTarget) \
	V(kOptWindowClause) \
	V(kWindowClause) \
	V(kWindowDefList) \
	V(kWindowDef) \
	V(kWindowName) \
	V(kWindow) \
	V(kOptPartition) \
	V(kOptFrameClause) \
	V(kRangeOrRows) \
	V(kFrameBoundStart) \
	V(kFrameBoundEnd) \
	V(kFrameBound) \
	V(kOptExistWindowName) \
	V(kOptGroupClause) \
	V(kOptHavingClause) \
	V(kOptWhereClause) \
	V(kWhereClause) \
	V(kFromClause) \
	V(kTableRef) \
	V(kOptIndex) \
	V(kOptOn) \
	V(kOptUsing) \
	V(kColumnNameList) \
	V(kOptTablePrefix) \
	V(kJoinOp) \
	V(kOptJoinType) \
	V(kExprList) \
	V(kOptLimitClause) \
	V(kLimitClause) \
	V(kOptLimitRowCount) \
	V(kOptOrderClause) \
	V(kOptOrderNulls) \
	V(kOrderItemList) \
	V(kOrderItem) \
	V(kOptOrderBehavior) \
	V(kOptWithClause) \
	V(kCteTableList) \
	V(kCteTable) \
	V(kCteTableName) \
	V(kOptAllOrDistinct) \
	V(kCreateTableStmt) \
	V(kCreateIndexStmt) \
	V(kCreateTriggerStmt) \
	V(kCreateViewStmt) \
	V(kOptTableOptionList) \
	V(kTableOptionList) \
	V(kTableOption) \
	V(kOptOpComma) \
	V(kOptIgnoreOrReplace) \
	V(kOptViewAlgorithm) \
	V(kOptSqlSecurity) \
	V(kOptIndexOption) \
	V(kOptExtraOption) \
	V(kIndexAlgorithmOption) \
	V(kLockOption) \
	V(kOptOpEqual) \
	V(kTriggerEvents) \
	V(kTriggerName) \
	V(kTriggerActionTime) \
	V(kDropIndexStmt) \
	V(kDropTableStmt) \
	V(kOptRestrictOrCascade) \
	V(kDropTriggerStmt) \
	V(kDropViewStmt) \
	V(kInsertStmt) \
	V(kInsertRest) \
	V(kSuperValuesList) \
	V(kValuesList) \
	V(kOptOnConflict) \
	V(kOptConflictExpr) \
	V(kIndexedColumnList) \
	V(kIndexedColumn) \
	V(kUpdateStmt) \
	V(kAlterAction) \
	V(kAlterConstantAction) \
	V(kColumnDefList) \
	V(kColumnDef) \
	V(kOptColumnConstraintList) \
	V(kColumnConstraintList) \
	V(kColumnConstraint) \
	V(kOptReferenceClause) \
	V(kOptCheck) \
	V(kConstraintType) \
	V(kReferenceClause) \
	V(kOptForeignKey) \
	V(kOptForeignKeyActions) \
	V(kForeignKeyActions) \
	V(kKeyActions) \
	V(kOptConstraintAttributeSpec) \
	V(kOptInitialTime) \
	V(kConstraintName) \
	V(kOptTemp) \
	V(kOptCheckOption) \
	V(kOptColumnNameListP) \
	V(kSetClauseList) \
	V(kSetClause) \
	V(kOptAsAlias) \
	V(kExpr) \
	V(kOperand) \
	V(kCastExpr) \
	V(kCoalesceExpr) \
	V(kMaxExpr) \
	V(kMinExpr) \
	V(kScalarExpr) \
	V(kUnaryExpr) \
	V(kBinaryExpr) \
	V(kLogicExpr) \
	V(kInExpr) \
	V(kCaseExpr) \
	V(kBetweenExpr) \
	V(kExistsExpr) \
	V(kFunctionExpr) \
	V(kOptDistinct) \
	V(kOptFilterClause) \
	V(kOptOverClause) \
	V(kCaseList) \
	V(kCaseClause) \
	V(kCompExpr) \
	V(kExtractExpr) \
	V(kDatetimeField) \
	V(kArrayExpr) \
	V(kArrayIndex) \
	V(kLiteral) \
	V(kStringLiteral) \
	V(kBoolLiteral) \
	V(kNumLiteral) \
	V(kIntLiteral) \
	V(kFloatLiteral) \
	V(kOptColumn) \
	V(kTriggerBody) \
	V(kOptIfNotExist) \
	V(kOptIfExist) \
	V(kIdentifier) \
	V(kAsAlias) \
	V(kTableName) \
	V(kColumnName) \
	V(kOptIndexKeyword) \
	V(kViewName) \
	V(kFunctionName) \
	V(kBinaryOp) \
	V(kOptNot) \
	V(kName) \
	V(kTypeName) \
	V(kTypeNameList) \
	V(kCharacterType) \
	V(kCharacterWithLength) \
	V(kCharacterWithoutLength) \
	V(kCharacterConflicta) \
	V(kNumericType) \
	V(kOptTableConstraintList) \
	V(kTableConstraintList) \
	V(kTableConstraint) \
	V(kOptEnforced) \
	V(kUnknown) \


#define ALLCLASS(V) \



#define ALLDATATYPE(V) \
	V(DataWhatever) \
	V(DataTableName) \
	V(DataColumnName) \
	V(DataViewName) \
	V(DataFunctionName) \
	V(DataPragmaKey) \
	V(DataPragmaValue) \
	V(DataTableSpaceName) \
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
    
#endif
