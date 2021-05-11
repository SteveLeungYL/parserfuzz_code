#pragma once
#ifndef __DEFINE_H__
#define __DEFINE_H__

#define ALLTYPE(V) \
    V(kIR) \
    V(kIROperator) \
    V(kNode) \
    V(kOpt) \
    V(kOptString) \
    V(kProgram) \
    V(kStatement) \
    V(kOptionalHints) \
    V(kPrepareStatement) \
    V(kPreparableStatement) \
    V(kShowStatement) \
    V(kHint) \
    V(kHintList) \
    V(kPrepareTargetQuery) \
    V(kSelectStatement) \
    V(kImportStatement) \
    V(kCreateStatement) \
    V(kInsertStatement) \
    V(kDeleteStatement) \
    V(kUpdateStatement) \
    V(kDropStatement) \
    V(kExecuteStatement) \
    V(kImportFileType) \
    V(kFilePath) \
    V(kOptIfNotExists) \
    V(kColumnDefCommaList) \
    V(kColumnDef) \
    V(kColumnType) \
    V(kOptColumnNullable) \
    V(kOptIfExists) \
    V(kExistsOrNot) \
    V(kOptExistsOrNot) \
    V(kOptColumnList) \
    V(kUpdateClauseCommalist) \
    V(kUpdateClause) \
    V(kSelectWithParen) \
    V(kSelectParenOrClause) \
    V(kSelectNoParen) \
    V(kSetOperator) \
    V(kSetType) \
    V(kOptAll) \
    V(kSelectClause) \
    V(kOptDistinct) \
    V(kSelectList) \
    V(kFromClause) \
    V(kOptFromClause) \
    V(kOptWhere) \
    V(kOptGroup) \
    V(kOptHaving) \
    V(kOptOrder) \
    V(kOrderList) \
    V(kOrderTerm) \
    V(kOptOrderType) \
    V(kOptLimit) \
    V(kExprList) \
    V(kLiteralList) \
    V(kOptLiteralList) \
    V(kNewExpr) \
    V(kLogicExpr) \
    V(kExistsExpr) \
    V(kElseExpr) \
    V(kOptElseExpr) \
    V(kOptExpr) \
    V(kScalarExpr) \
    V(kUnaryOp) \
    V(kBinaryOp) \
    V(kInTarget) \
    V(kFunctionExpr) \
    V(kExtractExpr) \
    V(kArrayExpr) \
    V(kCaseCondition) \
    V(kCaseConditionList) \
    V(kDatetimeField) \
    V(kColumnName) \
    V(kLiteral) \
    V(kStringLiteral) \
    V(kBlobLiteral) \
    V(kIntLiteral) \
    V(kNumericLiteral) \
    V(kNullLiteral) \
    V(kParamExpr) \
    V(kIdentifier) \
    V(kTableOrSubquery) \
    V(kTableOrSubqueryList) \
    V(kTableRefCommaList) \
    V(kTableRefAtomic) \
    V(kNonjoinTableRefAtomic) \
    V(kTableRefName) \
    V(kTableRefNameNoAlias) \
    V(kTableName) \
    V(kTableAlias) \
    V(kOptTableAlias) \
    V(kColumnAlias) \
    V(kOptColumnAlias) \
    V(kResultColumn) \
    V(kResultColumnList) \
    V(kAlias) \
    V(kOptAlias) \
    V(kWithClause) \
    V(kOptWithClause) \
    V(kWithDescriptionList) \
    V(kWithDescription) \
    V(kJoinClause) \
    V(kOptJoinType) \
    V(kJoinConstraint) \
    V(kOptSemicolon) \
    V(kIdentCommaList) \
    V(kInit) \
    V(kStatementList) \
    V(kUnknown)  \
    V(kEmpty)   \
    V(kCmdPragma) \
    V(kPragmaKey) \
    V(kPragmaName) \
    V(kPragmaValue) \
    V(kSchemaName) \
    V(kOptColumnArglist) \
	V(kColumnArglist) \
	V(kColumnArg) \
	V(kOptOnConflict) \
	V(kResolveType) \
	V(kOptAutoinc) \
	V(kOptUnique) \
	V(kIndexName) \
	V(kTriggerDeclare) \
	V(kOptTmp) \
	V(kTriggerName) \
	V(kOptTriggerTime) \
	V(kTriggerEvent) \
	V(kOptOfColumnList) \
	V(kOptForEach) \
	V(kOptWhen) \
	V(kTriggerCmdList) \
	V(kTriggerCmd) \
	V(kModuleName) \
	V(kOptOverClause) \
	V(kOptFilterClause) \
	V(kFilterClause) \
	V(kWindowClause) \
	V(kWindowDefnList) \
	V(kWindowDefn) \
	V(kWindow) \
	V(kWindowName) \
	V(kOptBaseWindowName) \
	V(kOptFrame) \
	V(kRangeOrRows) \
	V(kFrameBoundS) \
	V(kFrameBoundE) \
	V(kFrameBound) \
	V(kFrameExclude) \
	V(kOptFrameExclude) \
    V(kInsertType) \
    V(kCmd) \
    V(kCmdAttach) \
    V(kCmdDetach) \
    V(kCmdReindex) \
    V(kCmdAnalyze) \
    V(kSuperList)  \
    V(kOnExpr) \
    V(kEscapeExpr) \
    V(kOptEscapeExpr) \
    V(kWhereExpr) \
    V(kOptIndex) \
    V(kJoinOp)   \
    V(kAlterStatement) \
    V(kOptColumn) \
    V(kCmdRelease)  \
    V(kSavepointName) \
    V(kVacuumStatement) \
    V(kOptSchemaName) \
    V(kRollbackStatement) \
    V(kOptTransaction) \
    V(kOptToSavepoint) \
    V(kBeginStatement) \
    V(kCommitStatement) \
    V(kUpsertClause) \
    V(kIndexedColumnList) \
    V(kIndexedColumn) \
    V(kOptCollate) \
    V(kCollate) \
    V(kAssignList) \
    V(kOptOrderOfNull) \
    V(kNullOfExpr) \
    V(kAssignClause) \
    V(kColumnNameList) \
    V(kFunctionName) \
    V(kFunctionArgs) \
    V(kCollationName) \
    V(kOptWithoutRowID) \
    V(kOptUpsertClause) \
    V(kOptConstraintName) \
    V(kTableConstraintDef) \
    V(kTableConstraintDefCommaList) \
    V(kColumnOrTableConstraintDefCommaList) \
    V(kJoinSuffix) \
    V(kJoinSuffixList) \
    V(kPartitionBy) \
    V(kOptPartitionBy) \
    V(kOptNot) \
    V(kRaiseFunction) \
    \
    /* the following type does not has corresponding class*/ \
    \
    V(kInExpr) \
    V(kBetweenExpr) \
    V(kTableNameAndOptTableAlias) \
    V(kJoinOpAndTable) \
    V(kBinaryExprHead) \
    V(kExprCollate) \
    V(kExprCollateOrderType) \
    V(kBaseWindowPartition) \
    V(kBaseWindowPartitionOrder) \
    V(kFunctionNameArgs) \
    V(kExprOptNot) \
    V(kExprOptNotBop) \
    V(kExprOptNotBopExpr) \
    V(kFunctionNameArgsFilter) \
    V(kCaseConditionListElse)

#define ALLCLASS(V) \
    V(IR) \
    V(IROperator) \
    V(Node) \
    V(Opt) \
    V(OptString) \
    V(Program) \
    V(Statement) \
    V(OptionalHints) \
    V(PrepareStatement) \
    V(PreparableStatement) \
    V(ShowStatement) \
    V(Hint) \
    V(HintList) \
    V(PrepareTargetQuery) \
    V(SelectStatement) \
    V(ImportStatement) \
    V(CreateStatement) \
    V(InsertStatement) \
    V(DeleteStatement) \
    V(UpdateStatement) \
    V(DropStatement) \
    V(ExecuteStatement) \
    V(ImportFileType) \
    V(FilePath) \
    V(OptIfNotExists) \
    V(ColumnDefCommaList) \
    V(ColumnDef) \
    V(ColumnType) \
    V(OptColumnNullable) \
    V(OptIfExists) \
    V(ExistsOrNot) \
    V(OptExistsOrNot) \
    V(OptColumnList) \
    V(UpdateClauseCommalist) \
    V(UpdateClause) \
    V(SelectWithParen) \
    V(SelectParenOrClause) \
    V(SelectNoParen) \
    V(SetOperator) \
    V(SetType) \
    V(OptAll) \
    V(SelectClause) \
    V(OptDistinct) \
    V(SelectList) \
    V(FromClause) \
    V(OptFromClause) \
    V(OptWhere) \
    V(OptGroup) \
    V(OptHaving) \
    V(OptOrder) \
    V(OrderList) \
    V(OrderTerm) \
    V(OptOrderType) \
    V(OptLimit) \
    V(ExprList) \
    V(LiteralList) \
    V(OptLiteralList) \
    V(NewExpr) \
    V(LogicExpr) \
    V(ElseExpr) \
    V(OptElseExpr) \
    V(OptExpr) \
    V(UnaryOp) \
    V(BinaryOp) \
    V(InTarget) \
    V(CaseCondition) \
    V(CaseConditionList) \
    V(DatetimeField) \
    V(ColumnName) \
    V(FunctionName) \
    V(FunctionArgs) \
    V(Literal) \
    V(StringLiteral) \
    V(BlobLiteral) \
    V(IntLiteral) \
    V(NumericLiteral) \
    V(NullLiteral) \
    V(ParamExpr) \
    V(Identifier) \
    V(TableRefCommaList) \
    V(TableRefAtomic) \
    V(NonjoinTableRefAtomic) \
    V(TableRefName) \
    V(TableRefNameNoAlias) \
    V(TableName) \
    V(TableAlias) \
    V(OptTableAlias) \
    V(ColumnAlias) \
    V(OptColumnAlias) \
    V(ResultColumn) \
    V(ResultColumnList) \
    V(Alias) \
    V(OptAlias) \
    V(WithClause) \
    V(OptWithClause) \
    V(WithDescriptionList) \
    V(WithDescription) \
    V(JoinClause) \
    V(OptJoinType) \
    V(JoinConstraint) \
    V(OptSemicolon) \
    V(IdentCommaList) \
    V(Init) \
    V(StatementList) \
    V(Unknown) \
    V(Empty)    \
    V(CmdPragma) \
    V(PragmaKey) \
    V(PragmaName) \
    V(PragmaValue) \
    V(SchemaName) \
    V(OptColumnArglist) \
	V(ColumnArglist) \
	V(ColumnArg) \
	V(OptOnConflict) \
	V(ResolveType) \
	V(OptAutoinc) \
	V(OptUnique) \
	V(IndexName) \
	V(TriggerDeclare) \
	V(OptTmp) \
	V(TriggerName) \
	V(OptTriggerTime) \
	V(TriggerEvent) \
	V(OptOfColumnList) \
	V(OptForEach) \
	V(OptWhen) \
	V(TriggerCmdList) \
	V(TriggerCmd) \
	V(ModuleName) \
	V(OptOverClause) \
	V(OptFilterClause) \
	V(FilterClause) \
	V(WindowClause) \
	V(WindowDefnList) \
	V(WindowDefn) \
	V(Window) \
	V(WindowName) \
	V(OptBaseWindowName) \
	V(OptFrame) \
	V(RangeOrRows) \
	V(FrameBoundS) \
	V(FrameBoundE) \
	V(FrameBound) \
	V(FrameExclude) \
	V(OptFrameExclude) \
    V(InsertType)\
    V(Cmd) \
    V(CmdAttach) \
    V(CmdDetach) \
    V(CmdReindex) \
    V(CmdAnalyze) \
    V(SuperList) \
    V(OnExpr) \
    V(EscapeExpr) \
    V(OptEscapeExpr) \
    V(WhereExpr) \
    V(OptIndex) \
    V(AlterStatement) \
    V(OptColumn) \
    V(CmdRelease) \
    V(SavepointName) \
    V(VacuumStatement) \
    V(OptSchemaName) \
    V(RollbackStatement) \
    V(OptTransaction) \
    V(OptToSavepoint) \
    V(BeginStatement) \
    V(CommitStatement) \
    V(JoinOp)   \
    V(TableOrSubquery) \
    V(TableOrSubqueryList) \
    V(UpsertClause) \
    V(IndexedColumnList) \
    V(IndexedColumn) \
    V(OptCollate) \
    V(Collate) \
    V(AssignList) \
    V(OptOrderOfNull) \
    V(NullOfExpr) \
    V(AssignClause) \
    V(ColumnNameList) \
    V(CollationName) \
    V(OptWithoutRowID) \
    V(OptUpsertClause) \
    V(OptConstraintName) \
    V(TableConstraintDef) \
    V(TableConstraintDefCommaList) \
    V(ColumnOrTableConstraintDefCommaList) \
    V(JoinSuffix) \
    V(JoinSuffixList) \
    V(PartitionBy) \
    V(OptPartitionBy) \
    V(OptNot) \
    V(RaiseFunction) \
    \
    /* the following type does not has corresponding class*/ \
    \
    V(InExpr) \
    V(BetweenExpr) \
    V(TableNameAndOptTableAlias) \
    V(JoinOpAndTable) \
    V(BinaryExprHead) \
    V(ExprCollate) \
    V(ExprCollateOrderType) \
    V(BaseWindowPartition) \
    V(BaseWindowPartitionOrder) \
    V(FunctionNameArgs) \
    V(ExprOptNot) \
    V(ExprOptNotBop) \
    V(ExprOptNotBopExpr) \
    V(FunctionNameArgsFilter) \
    V(CaseConditionListElse)


#define SWITCHSTART \
    switch(sub_type_){ 

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
    IR *res = NULL; \


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
    IR * res;       \
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
