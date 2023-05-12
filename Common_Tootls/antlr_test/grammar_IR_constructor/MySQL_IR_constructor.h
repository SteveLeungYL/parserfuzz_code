#ifndef ANTLR_TEST_MYSQLIRCONSTRUCTOR_H
#define ANTLR_TEST_MYSQLIRCONSTRUCTOR_H

// DO NOT MODIFY THIS FILE. 
// This code is generated from PYTHON script generate_MySQL_IR_constructor.h.
// Use ANTLR4 to generate the MySQLParserBaseVisitor.h in ../grammar/ before calling the python generation script.

#include <iostream>
#include <cstring>
#include <filesystem>
#include <typeinfo>
#include <vector>
#include <cassert>
#include <array>
#include <algorithm>

#include "../MySQLBaseCommon.h"
#include "../grammar/MySQLParserBaseVisitor.h"
#include "../ast/ast.h"
#include "all_rule_declares.h"

using namespace std;
using namespace parsers;

//#define DEBUG

typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef unsigned long long u64;

#define MAP_SIZE_POW2 18
#define MAP_SIZE (1 << MAP_SIZE_POW2)

#define likely(_x) __builtin_expect(!!(_x), 1)
#define unlikely(_x) __builtin_expect(!!(_x), 0)

#define FINDINARRAY(x, y) find(x.begin(), x.end(), y) != x.end()

class MySQLIRConstructor: public parsers::MySQLParserBaseVisitor {
private:

  MySQLParser* p_parser;

  enum ParseTreeTypeEnum{
    TOKEN = 0,
    RULE = 1
  };

  array<int, 18> special_term_token_ir_type = {
#define DECLARE_TYPE(v) MySQLParser::v,
      ALLSPECIALTERMTOKENTYPE(DECLARE_TYPE)
#undef DECLARE_TYPE
  };

  bool is_special_term_token_ir_type(antlr4::tree::ParseTree* node) {
    auto *tmp = dynamic_cast<antlr4::tree::TerminalNode*>(node);
    if (tmp != nullptr) {
      // term token type
      if (FINDINARRAY(special_term_token_ir_type, tmp->getSymbol()->getType())) {
        // matched.
        return true;
      } else {
        // not matched.
        return false;
      }
    } else {
      // not a terminated token type.
      return false;
    }
  }

  IR* gen_node_ir(vector<antlr4::tree::ParseTree*>);

  inline bool is_parser_tree_node_terminated (antlr4::tree::ParseTree* child) {
    if (antlr4::ParserRuleContext* tmp = dynamic_cast<antlr4::ParserRuleContext*>(child)) {
      // has sub-rule.
      return false;
    } else {
      // terminated token.
      if (this->is_special_term_token_ir_type(child)) {
        // Identifiers, Literals.
        return false;
      } else {
        return true;
      }
    }
  }

  inline string get_terminated_token_str(antlr4::tree::ParseTree* child) {
    string out_str = dynamic_cast<antlr4::tree::TerminalNode*>(child)->getSymbol()->getText();
    if (out_str == "<EOF>") {
        return "";
    } else {
        return out_str;
    }
  }

  inline IR* gen_special_terminated_token_ir(antlr4::tree::ParseTree* child) {
    if (dynamic_cast<antlr4::tree::TerminalNode*>(child)->getSymbol()->getType() == MySQLParser::IDENTIFIER) {
      return new IR(kIdentifier, string(dynamic_cast<antlr4::tree::TerminalNode*>(child)->getSymbol()->getText()), DATATYPE::kDataWhatever, 0, DATAFLAG::kFlagUnknown);
    } else {
      return new IR(kLiteral, string(dynamic_cast<antlr4::tree::TerminalNode*>(child)->getSymbol()->getText()));
    }
  }

  inline IR* get_rule_returned_ir(antlr4::tree::ParseTree* child) {
    if (this->is_special_term_token_ir_type(child)) {
      // Identifiers, Literals.
      return gen_special_terminated_token_ir(child);
    } else {
      // Other normal rules.
      return any_cast<IR *>(visit(child));
    }
  }

public:

  void set_parser(MySQLParser* in) {this->p_parser = in;}

  virtual std::any visitQuery(MySQLParser::QueryContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleStatement(MySQLParser::SimpleStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterStatement(MySQLParser::AlterStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterDatabase(MySQLParser::AlterDatabaseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterEvent(MySQLParser::AlterEventContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterLogfileGroup(MySQLParser::AlterLogfileGroupContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterLogfileGroupOptions(MySQLParser::AlterLogfileGroupOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterLogfileGroupOption(MySQLParser::AlterLogfileGroupOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterServer(MySQLParser::AlterServerContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterTable(MySQLParser::AlterTableContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterTableActions(MySQLParser::AlterTableActionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterCommandList(MySQLParser::AlterCommandListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterCommandsModifierList(MySQLParser::AlterCommandsModifierListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitStandaloneAlterCommands(MySQLParser::StandaloneAlterCommandsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterPartition(MySQLParser::AlterPartitionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterList(MySQLParser::AlterListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterCommandsModifier(MySQLParser::AlterCommandsModifierContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterListItem(MySQLParser::AlterListItemContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPlace(MySQLParser::PlaceContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRestrict(MySQLParser::RestrictContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterOrderList(MySQLParser::AlterOrderListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterAlgorithmOption(MySQLParser::AlterAlgorithmOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterLockOption(MySQLParser::AlterLockOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIndexLockAndAlgorithm(MySQLParser::IndexLockAndAlgorithmContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWithValidation(MySQLParser::WithValidationContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRemovePartitioning(MySQLParser::RemovePartitioningContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAllOrPartitionNameList(MySQLParser::AllOrPartitionNameListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterTablespace(MySQLParser::AlterTablespaceContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterUndoTablespace(MySQLParser::AlterUndoTablespaceContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUndoTableSpaceOptions(MySQLParser::UndoTableSpaceOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUndoTableSpaceOption(MySQLParser::UndoTableSpaceOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterTablespaceOptions(MySQLParser::AlterTablespaceOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterTablespaceOption(MySQLParser::AlterTablespaceOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitChangeTablespaceOption(MySQLParser::ChangeTablespaceOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterView(MySQLParser::AlterViewContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitViewTail(MySQLParser::ViewTailContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitViewSelect(MySQLParser::ViewSelectContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitViewCheckOption(MySQLParser::ViewCheckOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateStatement(MySQLParser::CreateStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateDatabase(MySQLParser::CreateDatabaseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateDatabaseOption(MySQLParser::CreateDatabaseOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateTable(MySQLParser::CreateTableContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTableElementList(MySQLParser::TableElementListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTableElement(MySQLParser::TableElementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDuplicateAsQueryExpression(MySQLParser::DuplicateAsQueryExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitQueryExpressionOrParens(MySQLParser::QueryExpressionOrParensContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateRoutine(MySQLParser::CreateRoutineContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateProcedure(MySQLParser::CreateProcedureContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateFunction(MySQLParser::CreateFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateUdf(MySQLParser::CreateUdfContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRoutineCreateOption(MySQLParser::RoutineCreateOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRoutineAlterOptions(MySQLParser::RoutineAlterOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRoutineOption(MySQLParser::RoutineOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateIndex(MySQLParser::CreateIndexContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIndexNameAndType(MySQLParser::IndexNameAndTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateIndexTarget(MySQLParser::CreateIndexTargetContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateLogfileGroup(MySQLParser::CreateLogfileGroupContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLogfileGroupOptions(MySQLParser::LogfileGroupOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLogfileGroupOption(MySQLParser::LogfileGroupOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateServer(MySQLParser::CreateServerContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitServerOptions(MySQLParser::ServerOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitServerOption(MySQLParser::ServerOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateTablespace(MySQLParser::CreateTablespaceContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateUndoTablespace(MySQLParser::CreateUndoTablespaceContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTsDataFileName(MySQLParser::TsDataFileNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTsDataFile(MySQLParser::TsDataFileContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTablespaceOptions(MySQLParser::TablespaceOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTablespaceOption(MySQLParser::TablespaceOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTsOptionInitialSize(MySQLParser::TsOptionInitialSizeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTsOptionUndoRedoBufferSize(MySQLParser::TsOptionUndoRedoBufferSizeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTsOptionAutoextendSize(MySQLParser::TsOptionAutoextendSizeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTsOptionMaxSize(MySQLParser::TsOptionMaxSizeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTsOptionExtentSize(MySQLParser::TsOptionExtentSizeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTsOptionNodegroup(MySQLParser::TsOptionNodegroupContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTsOptionEngine(MySQLParser::TsOptionEngineContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTsOptionWait(MySQLParser::TsOptionWaitContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTsOptionComment(MySQLParser::TsOptionCommentContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTsOptionFileblockSize(MySQLParser::TsOptionFileblockSizeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTsOptionEncryption(MySQLParser::TsOptionEncryptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateView(MySQLParser::CreateViewContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitViewReplaceOrAlgorithm(MySQLParser::ViewReplaceOrAlgorithmContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitViewAlgorithm(MySQLParser::ViewAlgorithmContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitViewSuid(MySQLParser::ViewSuidContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateTrigger(MySQLParser::CreateTriggerContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTriggerFollowsPrecedesClause(MySQLParser::TriggerFollowsPrecedesClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateEvent(MySQLParser::CreateEventContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateRole(MySQLParser::CreateRoleContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateSpatialReference(MySQLParser::CreateSpatialReferenceContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSrsAttribute(MySQLParser::SrsAttributeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDropStatement(MySQLParser::DropStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDropDatabase(MySQLParser::DropDatabaseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDropEvent(MySQLParser::DropEventContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDropFunction(MySQLParser::DropFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDropProcedure(MySQLParser::DropProcedureContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDropIndex(MySQLParser::DropIndexContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDropLogfileGroup(MySQLParser::DropLogfileGroupContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDropLogfileGroupOption(MySQLParser::DropLogfileGroupOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDropServer(MySQLParser::DropServerContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDropTable(MySQLParser::DropTableContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDropTableSpace(MySQLParser::DropTableSpaceContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDropTrigger(MySQLParser::DropTriggerContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDropView(MySQLParser::DropViewContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDropRole(MySQLParser::DropRoleContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDropSpatialReference(MySQLParser::DropSpatialReferenceContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDropUndoTablespace(MySQLParser::DropUndoTablespaceContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRenameTableStatement(MySQLParser::RenameTableStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRenamePair(MySQLParser::RenamePairContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTruncateTableStatement(MySQLParser::TruncateTableStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitImportStatement(MySQLParser::ImportStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCallStatement(MySQLParser::CallStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDeleteStatement(MySQLParser::DeleteStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPartitionDelete(MySQLParser::PartitionDeleteContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDeleteStatementOption(MySQLParser::DeleteStatementOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDoStatement(MySQLParser::DoStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitHandlerStatement(MySQLParser::HandlerStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitHandlerReadOrScan(MySQLParser::HandlerReadOrScanContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitInsertStatement(MySQLParser::InsertStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitInsertLockOption(MySQLParser::InsertLockOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitInsertFromConstructor(MySQLParser::InsertFromConstructorContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFields(MySQLParser::FieldsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitInsertValues(MySQLParser::InsertValuesContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitInsertQueryExpression(MySQLParser::InsertQueryExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitValueList(MySQLParser::ValueListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitValues(MySQLParser::ValuesContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitValuesReference(MySQLParser::ValuesReferenceContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitInsertUpdateList(MySQLParser::InsertUpdateListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLoadStatement(MySQLParser::LoadStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDataOrXml(MySQLParser::DataOrXmlContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitXmlRowsIdentifiedBy(MySQLParser::XmlRowsIdentifiedByContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLoadDataFileTail(MySQLParser::LoadDataFileTailContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLoadDataFileTargetList(MySQLParser::LoadDataFileTargetListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFieldOrVariableList(MySQLParser::FieldOrVariableListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitReplaceStatement(MySQLParser::ReplaceStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSelectStatement(MySQLParser::SelectStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSelectStatementWithInto(MySQLParser::SelectStatementWithIntoContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitQueryExpression(MySQLParser::QueryExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitQueryExpressionBody(MySQLParser::QueryExpressionBodyContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitQueryExpressionParens(MySQLParser::QueryExpressionParensContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitQueryPrimary(MySQLParser::QueryPrimaryContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitQuerySpecification(MySQLParser::QuerySpecificationContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSubquery(MySQLParser::SubqueryContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitQuerySpecOption(MySQLParser::QuerySpecOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLimitClause(MySQLParser::LimitClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleLimitClause(MySQLParser::SimpleLimitClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLimitOptions(MySQLParser::LimitOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLimitOption(MySQLParser::LimitOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIntoClause(MySQLParser::IntoClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitProcedureAnalyseClause(MySQLParser::ProcedureAnalyseClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitHavingClause(MySQLParser::HavingClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWindowClause(MySQLParser::WindowClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWindowDefinition(MySQLParser::WindowDefinitionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWindowSpec(MySQLParser::WindowSpecContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWindowSpecDetails(MySQLParser::WindowSpecDetailsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWindowFrameClause(MySQLParser::WindowFrameClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWindowFrameUnits(MySQLParser::WindowFrameUnitsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWindowFrameExtent(MySQLParser::WindowFrameExtentContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWindowFrameStart(MySQLParser::WindowFrameStartContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWindowFrameBetween(MySQLParser::WindowFrameBetweenContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWindowFrameBound(MySQLParser::WindowFrameBoundContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWindowFrameExclusion(MySQLParser::WindowFrameExclusionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWithClause(MySQLParser::WithClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCommonTableExpression(MySQLParser::CommonTableExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitGroupByClause(MySQLParser::GroupByClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitOlapOption(MySQLParser::OlapOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitOrderClause(MySQLParser::OrderClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDirection(MySQLParser::DirectionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFromClause(MySQLParser::FromClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTableReferenceList(MySQLParser::TableReferenceListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTableValueConstructor(MySQLParser::TableValueConstructorContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitExplicitTable(MySQLParser::ExplicitTableContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRowValueExplicit(MySQLParser::RowValueExplicitContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSelectOption(MySQLParser::SelectOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLockingClauseList(MySQLParser::LockingClauseListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLockingClause(MySQLParser::LockingClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLockStrengh(MySQLParser::LockStrenghContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLockedRowAction(MySQLParser::LockedRowActionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSelectItemList(MySQLParser::SelectItemListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSelectItem(MySQLParser::SelectItemContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSelectAlias(MySQLParser::SelectAliasContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWhereClause(MySQLParser::WhereClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTableReference(MySQLParser::TableReferenceContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitEscapedTableReference(MySQLParser::EscapedTableReferenceContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitJoinedTable(MySQLParser::JoinedTableContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitNaturalJoinType(MySQLParser::NaturalJoinTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitInnerJoinType(MySQLParser::InnerJoinTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitOuterJoinType(MySQLParser::OuterJoinTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTableFactor(MySQLParser::TableFactorContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSingleTable(MySQLParser::SingleTableContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSingleTableParens(MySQLParser::SingleTableParensContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDerivedTable(MySQLParser::DerivedTableContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTableReferenceListParens(MySQLParser::TableReferenceListParensContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTableFunction(MySQLParser::TableFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitColumnsClause(MySQLParser::ColumnsClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitJtColumn(MySQLParser::JtColumnContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitOnEmptyOrError(MySQLParser::OnEmptyOrErrorContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitOnEmpty(MySQLParser::OnEmptyContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitOnError(MySQLParser::OnErrorContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitJtOnResponse(MySQLParser::JtOnResponseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUnionOption(MySQLParser::UnionOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTableAlias(MySQLParser::TableAliasContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIndexHintList(MySQLParser::IndexHintListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIndexHint(MySQLParser::IndexHintContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIndexHintType(MySQLParser::IndexHintTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitKeyOrIndex(MySQLParser::KeyOrIndexContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitConstraintKeyType(MySQLParser::ConstraintKeyTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIndexHintClause(MySQLParser::IndexHintClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIndexList(MySQLParser::IndexListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIndexListElement(MySQLParser::IndexListElementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUpdateStatement(MySQLParser::UpdateStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTransactionOrLockingStatement(MySQLParser::TransactionOrLockingStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTransactionStatement(MySQLParser::TransactionStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitBeginWork(MySQLParser::BeginWorkContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTransactionCharacteristic(MySQLParser::TransactionCharacteristicContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSavepointStatement(MySQLParser::SavepointStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLockStatement(MySQLParser::LockStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLockItem(MySQLParser::LockItemContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLockOption(MySQLParser::LockOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitXaStatement(MySQLParser::XaStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitXaConvert(MySQLParser::XaConvertContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitXid(MySQLParser::XidContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitReplicationStatement(MySQLParser::ReplicationStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitResetOption(MySQLParser::ResetOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitMasterResetOptions(MySQLParser::MasterResetOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitReplicationLoad(MySQLParser::ReplicationLoadContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitChangeMaster(MySQLParser::ChangeMasterContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitChangeMasterOptions(MySQLParser::ChangeMasterOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitMasterOption(MySQLParser::MasterOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPrivilegeCheckDef(MySQLParser::PrivilegeCheckDefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTablePrimaryKeyCheckDef(MySQLParser::TablePrimaryKeyCheckDefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitMasterTlsCiphersuitesDef(MySQLParser::MasterTlsCiphersuitesDefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitMasterFileDef(MySQLParser::MasterFileDefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitServerIdList(MySQLParser::ServerIdListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitChangeReplication(MySQLParser::ChangeReplicationContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFilterDefinition(MySQLParser::FilterDefinitionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFilterDbList(MySQLParser::FilterDbListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFilterTableList(MySQLParser::FilterTableListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFilterStringList(MySQLParser::FilterStringListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFilterWildDbTableString(MySQLParser::FilterWildDbTableStringContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFilterDbPairList(MySQLParser::FilterDbPairListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSlave(MySQLParser::SlaveContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSlaveUntilOptions(MySQLParser::SlaveUntilOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSlaveConnectionOptions(MySQLParser::SlaveConnectionOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSlaveThreadOptions(MySQLParser::SlaveThreadOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSlaveThreadOption(MySQLParser::SlaveThreadOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitGroupReplication(MySQLParser::GroupReplicationContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPreparedStatement(MySQLParser::PreparedStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitExecuteStatement(MySQLParser::ExecuteStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitExecuteVarList(MySQLParser::ExecuteVarListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCloneStatement(MySQLParser::CloneStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDataDirSSL(MySQLParser::DataDirSSLContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSsl(MySQLParser::SslContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAccountManagementStatement(MySQLParser::AccountManagementStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterUser(MySQLParser::AlterUserContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterUserTail(MySQLParser::AlterUserTailContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUserFunction(MySQLParser::UserFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateUser(MySQLParser::CreateUserContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateUserTail(MySQLParser::CreateUserTailContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDefaultRoleClause(MySQLParser::DefaultRoleClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRequireClause(MySQLParser::RequireClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitConnectOptions(MySQLParser::ConnectOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAccountLockPasswordExpireOptions(MySQLParser::AccountLockPasswordExpireOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDropUser(MySQLParser::DropUserContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitGrant(MySQLParser::GrantContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitGrantTargetList(MySQLParser::GrantTargetListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitGrantOptions(MySQLParser::GrantOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitExceptRoleList(MySQLParser::ExceptRoleListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWithRoles(MySQLParser::WithRolesContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitGrantAs(MySQLParser::GrantAsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitVersionedRequireClause(MySQLParser::VersionedRequireClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRenameUser(MySQLParser::RenameUserContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRevoke(MySQLParser::RevokeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitOnTypeTo(MySQLParser::OnTypeToContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAclType(MySQLParser::AclTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRoleOrPrivilegesList(MySQLParser::RoleOrPrivilegesListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRoleOrPrivilege(MySQLParser::RoleOrPrivilegeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitGrantIdentifier(MySQLParser::GrantIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRequireList(MySQLParser::RequireListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRequireListElement(MySQLParser::RequireListElementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitGrantOption(MySQLParser::GrantOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSetRole(MySQLParser::SetRoleContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRoleList(MySQLParser::RoleListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRole(MySQLParser::RoleContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTableAdministrationStatement(MySQLParser::TableAdministrationStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitHistogram(MySQLParser::HistogramContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCheckOption(MySQLParser::CheckOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRepairType(MySQLParser::RepairTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitInstallUninstallStatment(MySQLParser::InstallUninstallStatmentContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSetStatement(MySQLParser::SetStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitStartOptionValueList(MySQLParser::StartOptionValueListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTransactionCharacteristics(MySQLParser::TransactionCharacteristicsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTransactionAccessMode(MySQLParser::TransactionAccessModeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIsolationLevel(MySQLParser::IsolationLevelContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitOptionValueListContinued(MySQLParser::OptionValueListContinuedContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitOptionValueNoOptionType(MySQLParser::OptionValueNoOptionTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitOptionValue(MySQLParser::OptionValueContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSetSystemVariable(MySQLParser::SetSystemVariableContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitStartOptionValueListFollowingOptionType(MySQLParser::StartOptionValueListFollowingOptionTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitOptionValueFollowingOptionType(MySQLParser::OptionValueFollowingOptionTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSetExprOrDefault(MySQLParser::SetExprOrDefaultContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitShowStatement(MySQLParser::ShowStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitShowCommandType(MySQLParser::ShowCommandTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitNonBlocking(MySQLParser::NonBlockingContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFromOrIn(MySQLParser::FromOrInContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitInDb(MySQLParser::InDbContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitProfileType(MySQLParser::ProfileTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitOtherAdministrativeStatement(MySQLParser::OtherAdministrativeStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitKeyCacheListOrParts(MySQLParser::KeyCacheListOrPartsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitKeyCacheList(MySQLParser::KeyCacheListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAssignToKeycache(MySQLParser::AssignToKeycacheContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAssignToKeycachePartition(MySQLParser::AssignToKeycachePartitionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCacheKeyList(MySQLParser::CacheKeyListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitKeyUsageElement(MySQLParser::KeyUsageElementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitKeyUsageList(MySQLParser::KeyUsageListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFlushOption(MySQLParser::FlushOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLogType(MySQLParser::LogTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFlushTables(MySQLParser::FlushTablesContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFlushTablesOptions(MySQLParser::FlushTablesOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPreloadTail(MySQLParser::PreloadTailContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPreloadList(MySQLParser::PreloadListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPreloadKeys(MySQLParser::PreloadKeysContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAdminPartition(MySQLParser::AdminPartitionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitResourceGroupManagement(MySQLParser::ResourceGroupManagementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateResourceGroup(MySQLParser::CreateResourceGroupContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitResourceGroupVcpuList(MySQLParser::ResourceGroupVcpuListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitVcpuNumOrRange(MySQLParser::VcpuNumOrRangeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitResourceGroupPriority(MySQLParser::ResourceGroupPriorityContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitResourceGroupEnableDisable(MySQLParser::ResourceGroupEnableDisableContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterResourceGroup(MySQLParser::AlterResourceGroupContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSetResourceGroup(MySQLParser::SetResourceGroupContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitThreadIdList(MySQLParser::ThreadIdListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDropResourceGroup(MySQLParser::DropResourceGroupContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUtilityStatement(MySQLParser::UtilityStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDescribeStatement(MySQLParser::DescribeStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitExplainStatement(MySQLParser::ExplainStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitExplainableStatement(MySQLParser::ExplainableStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitHelpCommand(MySQLParser::HelpCommandContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUseCommand(MySQLParser::UseCommandContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRestartServer(MySQLParser::RestartServerContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitExprOr(MySQLParser::ExprOrContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitExprNot(MySQLParser::ExprNotContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitExprIs(MySQLParser::ExprIsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitExprAnd(MySQLParser::ExprAndContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitExprXor(MySQLParser::ExprXorContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPrimaryExprPredicate(MySQLParser::PrimaryExprPredicateContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPrimaryExprCompare(MySQLParser::PrimaryExprCompareContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPrimaryExprAllAny(MySQLParser::PrimaryExprAllAnyContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPrimaryExprIsNull(MySQLParser::PrimaryExprIsNullContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCompOp(MySQLParser::CompOpContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPredicate(MySQLParser::PredicateContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPredicateExprIn(MySQLParser::PredicateExprInContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPredicateExprBetween(MySQLParser::PredicateExprBetweenContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPredicateExprLike(MySQLParser::PredicateExprLikeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPredicateExprRegex(MySQLParser::PredicateExprRegexContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitBitExpr(MySQLParser::BitExprContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprConvert(MySQLParser::SimpleExprConvertContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprVariable(MySQLParser::SimpleExprVariableContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprCast(MySQLParser::SimpleExprCastContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprUnary(MySQLParser::SimpleExprUnaryContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprOdbc(MySQLParser::SimpleExprOdbcContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprRuntimeFunction(MySQLParser::SimpleExprRuntimeFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprFunction(MySQLParser::SimpleExprFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprCollate(MySQLParser::SimpleExprCollateContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprMatch(MySQLParser::SimpleExprMatchContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprWindowingFunction(MySQLParser::SimpleExprWindowingFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprBinary(MySQLParser::SimpleExprBinaryContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprColumnRef(MySQLParser::SimpleExprColumnRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprParamMarker(MySQLParser::SimpleExprParamMarkerContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprSum(MySQLParser::SimpleExprSumContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprConvertUsing(MySQLParser::SimpleExprConvertUsingContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprSubQuery(MySQLParser::SimpleExprSubQueryContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprGroupingOperation(MySQLParser::SimpleExprGroupingOperationContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprNot(MySQLParser::SimpleExprNotContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprValues(MySQLParser::SimpleExprValuesContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprDefault(MySQLParser::SimpleExprDefaultContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprList(MySQLParser::SimpleExprListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprInterval(MySQLParser::SimpleExprIntervalContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprCase(MySQLParser::SimpleExprCaseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprConcat(MySQLParser::SimpleExprConcatContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprLiteral(MySQLParser::SimpleExprLiteralContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitArrayCast(MySQLParser::ArrayCastContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitJsonOperator(MySQLParser::JsonOperatorContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSumExpr(MySQLParser::SumExprContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitGroupingOperation(MySQLParser::GroupingOperationContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWindowFunctionCall(MySQLParser::WindowFunctionCallContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWindowingClause(MySQLParser::WindowingClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLeadLagInfo(MySQLParser::LeadLagInfoContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitNullTreatment(MySQLParser::NullTreatmentContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitJsonFunction(MySQLParser::JsonFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitInSumExpr(MySQLParser::InSumExprContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIdentListArg(MySQLParser::IdentListArgContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIdentList(MySQLParser::IdentListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFulltextOptions(MySQLParser::FulltextOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRuntimeFunctionCall(MySQLParser::RuntimeFunctionCallContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitGeometryFunction(MySQLParser::GeometryFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTimeFunctionParameters(MySQLParser::TimeFunctionParametersContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFractionalPrecision(MySQLParser::FractionalPrecisionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWeightStringLevels(MySQLParser::WeightStringLevelsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWeightStringLevelListItem(MySQLParser::WeightStringLevelListItemContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDateTimeTtype(MySQLParser::DateTimeTtypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTrimFunction(MySQLParser::TrimFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSubstringFunction(MySQLParser::SubstringFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFunctionCall(MySQLParser::FunctionCallContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUdfExprList(MySQLParser::UdfExprListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUdfExpr(MySQLParser::UdfExprContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitVariable(MySQLParser::VariableContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUserVariable(MySQLParser::UserVariableContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSystemVariable(MySQLParser::SystemVariableContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitInternalVariableName(MySQLParser::InternalVariableNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWhenExpression(MySQLParser::WhenExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitThenExpression(MySQLParser::ThenExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitElseExpression(MySQLParser::ElseExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCastType(MySQLParser::CastTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitExprList(MySQLParser::ExprListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCharset(MySQLParser::CharsetContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitNotRule(MySQLParser::NotRuleContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitNot2Rule(MySQLParser::Not2RuleContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitInterval(MySQLParser::IntervalContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIntervalTimeStamp(MySQLParser::IntervalTimeStampContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitExprListWithParentheses(MySQLParser::ExprListWithParenthesesContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitExprWithParentheses(MySQLParser::ExprWithParenthesesContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleExprWithParentheses(MySQLParser::SimpleExprWithParenthesesContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitOrderList(MySQLParser::OrderListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitOrderExpression(MySQLParser::OrderExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitGroupList(MySQLParser::GroupListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitGroupingExpression(MySQLParser::GroupingExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitChannel(MySQLParser::ChannelContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCompoundStatement(MySQLParser::CompoundStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitReturnStatement(MySQLParser::ReturnStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIfStatement(MySQLParser::IfStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIfBody(MySQLParser::IfBodyContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitThenStatement(MySQLParser::ThenStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCompoundStatementList(MySQLParser::CompoundStatementListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCaseStatement(MySQLParser::CaseStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitElseStatement(MySQLParser::ElseStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLabeledBlock(MySQLParser::LabeledBlockContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUnlabeledBlock(MySQLParser::UnlabeledBlockContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLabel(MySQLParser::LabelContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitBeginEndBlock(MySQLParser::BeginEndBlockContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLabeledControl(MySQLParser::LabeledControlContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUnlabeledControl(MySQLParser::UnlabeledControlContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLoopBlock(MySQLParser::LoopBlockContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWhileDoBlock(MySQLParser::WhileDoBlockContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRepeatUntilBlock(MySQLParser::RepeatUntilBlockContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSpDeclarations(MySQLParser::SpDeclarationsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSpDeclaration(MySQLParser::SpDeclarationContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitVariableDeclaration(MySQLParser::VariableDeclarationContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitConditionDeclaration(MySQLParser::ConditionDeclarationContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSpCondition(MySQLParser::SpConditionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSqlstate(MySQLParser::SqlstateContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitHandlerDeclaration(MySQLParser::HandlerDeclarationContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitHandlerCondition(MySQLParser::HandlerConditionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCursorDeclaration(MySQLParser::CursorDeclarationContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIterateStatement(MySQLParser::IterateStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLeaveStatement(MySQLParser::LeaveStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitGetDiagnostics(MySQLParser::GetDiagnosticsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSignalAllowedExpr(MySQLParser::SignalAllowedExprContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitStatementInformationItem(MySQLParser::StatementInformationItemContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitConditionInformationItem(MySQLParser::ConditionInformationItemContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSignalInformationItemName(MySQLParser::SignalInformationItemNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSignalStatement(MySQLParser::SignalStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitResignalStatement(MySQLParser::ResignalStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSignalInformationItem(MySQLParser::SignalInformationItemContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCursorOpen(MySQLParser::CursorOpenContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCursorClose(MySQLParser::CursorCloseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCursorFetch(MySQLParser::CursorFetchContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSchedule(MySQLParser::ScheduleContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitColumnDefinition(MySQLParser::ColumnDefinitionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCheckOrReferences(MySQLParser::CheckOrReferencesContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCheckConstraint(MySQLParser::CheckConstraintContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitConstraintEnforcement(MySQLParser::ConstraintEnforcementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTableConstraintDef(MySQLParser::TableConstraintDefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitConstraintName(MySQLParser::ConstraintNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFieldDefinition(MySQLParser::FieldDefinitionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitColumnAttribute(MySQLParser::ColumnAttributeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitColumnFormat(MySQLParser::ColumnFormatContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitStorageMedia(MySQLParser::StorageMediaContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitGcolAttribute(MySQLParser::GcolAttributeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitReferences(MySQLParser::ReferencesContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDeleteOption(MySQLParser::DeleteOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitKeyList(MySQLParser::KeyListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitKeyPart(MySQLParser::KeyPartContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitKeyListWithExpression(MySQLParser::KeyListWithExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitKeyPartOrExpression(MySQLParser::KeyPartOrExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitKeyListVariants(MySQLParser::KeyListVariantsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIndexType(MySQLParser::IndexTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIndexOption(MySQLParser::IndexOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCommonIndexOption(MySQLParser::CommonIndexOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitVisibility(MySQLParser::VisibilityContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIndexTypeClause(MySQLParser::IndexTypeClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFulltextIndexOption(MySQLParser::FulltextIndexOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSpatialIndexOption(MySQLParser::SpatialIndexOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDataTypeDefinition(MySQLParser::DataTypeDefinitionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDataType(MySQLParser::DataTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitNchar(MySQLParser::NcharContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRealType(MySQLParser::RealTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFieldLength(MySQLParser::FieldLengthContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFieldOptions(MySQLParser::FieldOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCharsetWithOptBinary(MySQLParser::CharsetWithOptBinaryContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAscii(MySQLParser::AsciiContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUnicode(MySQLParser::UnicodeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWsNumCodepoints(MySQLParser::WsNumCodepointsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTypeDatetimePrecision(MySQLParser::TypeDatetimePrecisionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCharsetName(MySQLParser::CharsetNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCollationName(MySQLParser::CollationNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateTableOptions(MySQLParser::CreateTableOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateTableOptionsSpaceSeparated(MySQLParser::CreateTableOptionsSpaceSeparatedContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateTableOption(MySQLParser::CreateTableOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTernaryOption(MySQLParser::TernaryOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDefaultCollation(MySQLParser::DefaultCollationContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDefaultEncryption(MySQLParser::DefaultEncryptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDefaultCharset(MySQLParser::DefaultCharsetContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPartitionClause(MySQLParser::PartitionClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPartitionDefKey(MySQLParser::PartitionDefKeyContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPartitionDefHash(MySQLParser::PartitionDefHashContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPartitionDefRangeList(MySQLParser::PartitionDefRangeListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSubPartitions(MySQLParser::SubPartitionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPartitionKeyAlgorithm(MySQLParser::PartitionKeyAlgorithmContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPartitionDefinitions(MySQLParser::PartitionDefinitionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPartitionDefinition(MySQLParser::PartitionDefinitionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPartitionValuesIn(MySQLParser::PartitionValuesInContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPartitionOption(MySQLParser::PartitionOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSubpartitionDefinition(MySQLParser::SubpartitionDefinitionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPartitionValueItemListParen(MySQLParser::PartitionValueItemListParenContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPartitionValueItem(MySQLParser::PartitionValueItemContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDefinerClause(MySQLParser::DefinerClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIfExists(MySQLParser::IfExistsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIfNotExists(MySQLParser::IfNotExistsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitProcedureParameter(MySQLParser::ProcedureParameterContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFunctionParameter(MySQLParser::FunctionParameterContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCollate(MySQLParser::CollateContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTypeWithOptCollate(MySQLParser::TypeWithOptCollateContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSchemaIdentifierPair(MySQLParser::SchemaIdentifierPairContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitViewRefList(MySQLParser::ViewRefListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUpdateList(MySQLParser::UpdateListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUpdateElement(MySQLParser::UpdateElementContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCharsetClause(MySQLParser::CharsetClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFieldsClause(MySQLParser::FieldsClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFieldTerm(MySQLParser::FieldTermContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLinesClause(MySQLParser::LinesClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLineTerm(MySQLParser::LineTermContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUserList(MySQLParser::UserListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateUserList(MySQLParser::CreateUserListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterUserList(MySQLParser::AlterUserListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitCreateUserEntry(MySQLParser::CreateUserEntryContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitAlterUserEntry(MySQLParser::AlterUserEntryContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRetainCurrentPassword(MySQLParser::RetainCurrentPasswordContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDiscardOldPassword(MySQLParser::DiscardOldPasswordContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitReplacePassword(MySQLParser::ReplacePasswordContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUserIdentifierOrText(MySQLParser::UserIdentifierOrTextContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUser(MySQLParser::UserContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLikeClause(MySQLParser::LikeClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLikeOrWhere(MySQLParser::LikeOrWhereContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitOnlineOption(MySQLParser::OnlineOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitNoWriteToBinLog(MySQLParser::NoWriteToBinLogContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUsePartition(MySQLParser::UsePartitionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFieldIdentifier(MySQLParser::FieldIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitColumnName(MySQLParser::ColumnNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitColumnInternalRef(MySQLParser::ColumnInternalRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitColumnInternalRefList(MySQLParser::ColumnInternalRefListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitColumnRef(MySQLParser::ColumnRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitInsertIdentifier(MySQLParser::InsertIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIndexName(MySQLParser::IndexNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIndexRef(MySQLParser::IndexRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTableWild(MySQLParser::TableWildContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSchemaName(MySQLParser::SchemaNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSchemaRef(MySQLParser::SchemaRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitProcedureName(MySQLParser::ProcedureNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitProcedureRef(MySQLParser::ProcedureRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFunctionName(MySQLParser::FunctionNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFunctionRef(MySQLParser::FunctionRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTriggerName(MySQLParser::TriggerNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTriggerRef(MySQLParser::TriggerRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitViewName(MySQLParser::ViewNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitViewRef(MySQLParser::ViewRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTablespaceName(MySQLParser::TablespaceNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTablespaceRef(MySQLParser::TablespaceRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLogfileGroupName(MySQLParser::LogfileGroupNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLogfileGroupRef(MySQLParser::LogfileGroupRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitEventName(MySQLParser::EventNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitEventRef(MySQLParser::EventRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUdfName(MySQLParser::UdfNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitServerName(MySQLParser::ServerNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitServerRef(MySQLParser::ServerRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitEngineRef(MySQLParser::EngineRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTableName(MySQLParser::TableNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFilterTableRef(MySQLParser::FilterTableRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTableRefWithWildcard(MySQLParser::TableRefWithWildcardContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTableRef(MySQLParser::TableRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTableRefList(MySQLParser::TableRefListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTableAliasRefList(MySQLParser::TableAliasRefListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitParameterName(MySQLParser::ParameterNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLabelIdentifier(MySQLParser::LabelIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLabelRef(MySQLParser::LabelRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRoleIdentifier(MySQLParser::RoleIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRoleRef(MySQLParser::RoleRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPluginRef(MySQLParser::PluginRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitComponentRef(MySQLParser::ComponentRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitResourceGroupRef(MySQLParser::ResourceGroupRefContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitWindowName(MySQLParser::WindowNameContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPureIdentifier(MySQLParser::PureIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIdentifier(MySQLParser::IdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIdentifierList(MySQLParser::IdentifierListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIdentifierListWithParentheses(MySQLParser::IdentifierListWithParenthesesContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitQualifiedIdentifier(MySQLParser::QualifiedIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSimpleIdentifier(MySQLParser::SimpleIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitDotIdentifier(MySQLParser::DotIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUlong_number(MySQLParser::Ulong_numberContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitReal_ulong_number(MySQLParser::Real_ulong_numberContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitUlonglong_number(MySQLParser::Ulonglong_numberContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitReal_ulonglong_number(MySQLParser::Real_ulonglong_numberContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLiteral(MySQLParser::LiteralContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSignedLiteral(MySQLParser::SignedLiteralContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitStringList(MySQLParser::StringListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTextStringLiteral(MySQLParser::TextStringLiteralContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTextString(MySQLParser::TextStringContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTextStringHash(MySQLParser::TextStringHashContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTextLiteral(MySQLParser::TextLiteralContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTextStringNoLinebreak(MySQLParser::TextStringNoLinebreakContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTextStringLiteralList(MySQLParser::TextStringLiteralListContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitNumLiteral(MySQLParser::NumLiteralContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitBoolLiteral(MySQLParser::BoolLiteralContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitNullLiteral(MySQLParser::NullLiteralContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTemporalLiteral(MySQLParser::TemporalLiteralContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitFloatOptions(MySQLParser::FloatOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitStandardFloatOptions(MySQLParser::StandardFloatOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitPrecision(MySQLParser::PrecisionContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitTextOrIdentifier(MySQLParser::TextOrIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLValueIdentifier(MySQLParser::LValueIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRoleIdentifierOrText(MySQLParser::RoleIdentifierOrTextContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSizeNumber(MySQLParser::SizeNumberContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitParentheses(MySQLParser::ParenthesesContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitEqual(MySQLParser::EqualContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitOptionType(MySQLParser::OptionTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitVarIdentType(MySQLParser::VarIdentTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitSetVarIdentType(MySQLParser::SetVarIdentTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIdentifierKeyword(MySQLParser::IdentifierKeywordContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIdentifierKeywordsAmbiguous1RolesAndLabels(MySQLParser::IdentifierKeywordsAmbiguous1RolesAndLabelsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIdentifierKeywordsAmbiguous2Labels(MySQLParser::IdentifierKeywordsAmbiguous2LabelsContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLabelKeyword(MySQLParser::LabelKeywordContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIdentifierKeywordsAmbiguous3Roles(MySQLParser::IdentifierKeywordsAmbiguous3RolesContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIdentifierKeywordsUnambiguous(MySQLParser::IdentifierKeywordsUnambiguousContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRoleKeyword(MySQLParser::RoleKeywordContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitLValueKeyword(MySQLParser::LValueKeywordContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitIdentifierKeywordsAmbiguous4SystemVariables(MySQLParser::IdentifierKeywordsAmbiguous4SystemVariablesContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRoleOrIdentifierKeyword(MySQLParser::RoleOrIdentifierKeywordContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }

  virtual std::any visitRoleOrLabelKeyword(MySQLParser::RoleOrLabelKeywordContext *ctx) override {
    return this->gen_node_ir(ctx->children);
  }


};

#endif
