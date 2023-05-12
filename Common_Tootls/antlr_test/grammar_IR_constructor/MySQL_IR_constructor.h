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

  IR* gen_node_ir(vector<antlr4::tree::ParseTree*>, IRTYPE);

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
    return this->gen_node_ir(ctx->children, kQuery);
  }

  virtual std::any visitSimpleStatement(MySQLParser::SimpleStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleStatement);
  }

  virtual std::any visitAlterStatement(MySQLParser::AlterStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterStatement);
  }

  virtual std::any visitAlterDatabase(MySQLParser::AlterDatabaseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterDatabase);
  }

  virtual std::any visitAlterEvent(MySQLParser::AlterEventContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterEvent);
  }

  virtual std::any visitAlterLogfileGroup(MySQLParser::AlterLogfileGroupContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterLogfileGroup);
  }

  virtual std::any visitAlterLogfileGroupOptions(MySQLParser::AlterLogfileGroupOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterLogfileGroupOptions);
  }

  virtual std::any visitAlterLogfileGroupOption(MySQLParser::AlterLogfileGroupOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterLogfileGroupOption);
  }

  virtual std::any visitAlterServer(MySQLParser::AlterServerContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterServer);
  }

  virtual std::any visitAlterTable(MySQLParser::AlterTableContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterTable);
  }

  virtual std::any visitAlterTableActions(MySQLParser::AlterTableActionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterTableActions);
  }

  virtual std::any visitAlterCommandList(MySQLParser::AlterCommandListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterCommandList);
  }

  virtual std::any visitAlterCommandsModifierList(MySQLParser::AlterCommandsModifierListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterCommandsModifierList);
  }

  virtual std::any visitStandaloneAlterCommands(MySQLParser::StandaloneAlterCommandsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kStandaloneAlterCommands);
  }

  virtual std::any visitAlterPartition(MySQLParser::AlterPartitionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterPartition);
  }

  virtual std::any visitAlterList(MySQLParser::AlterListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterList);
  }

  virtual std::any visitAlterCommandsModifier(MySQLParser::AlterCommandsModifierContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterCommandsModifier);
  }

  virtual std::any visitAlterListItem(MySQLParser::AlterListItemContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterListItem);
  }

  virtual std::any visitPlace(MySQLParser::PlaceContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPlace);
  }

  virtual std::any visitRestrict(MySQLParser::RestrictContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRestrict);
  }

  virtual std::any visitAlterOrderList(MySQLParser::AlterOrderListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterOrderList);
  }

  virtual std::any visitAlterAlgorithmOption(MySQLParser::AlterAlgorithmOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterAlgorithmOption);
  }

  virtual std::any visitAlterLockOption(MySQLParser::AlterLockOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterLockOption);
  }

  virtual std::any visitIndexLockAndAlgorithm(MySQLParser::IndexLockAndAlgorithmContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIndexLockAndAlgorithm);
  }

  virtual std::any visitWithValidation(MySQLParser::WithValidationContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWithValidation);
  }

  virtual std::any visitRemovePartitioning(MySQLParser::RemovePartitioningContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRemovePartitioning);
  }

  virtual std::any visitAllOrPartitionNameList(MySQLParser::AllOrPartitionNameListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAllOrPartitionNameList);
  }

  virtual std::any visitAlterTablespace(MySQLParser::AlterTablespaceContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterTablespace);
  }

  virtual std::any visitAlterUndoTablespace(MySQLParser::AlterUndoTablespaceContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterUndoTablespace);
  }

  virtual std::any visitUndoTableSpaceOptions(MySQLParser::UndoTableSpaceOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUndoTableSpaceOptions);
  }

  virtual std::any visitUndoTableSpaceOption(MySQLParser::UndoTableSpaceOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUndoTableSpaceOption);
  }

  virtual std::any visitAlterTablespaceOptions(MySQLParser::AlterTablespaceOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterTablespaceOptions);
  }

  virtual std::any visitAlterTablespaceOption(MySQLParser::AlterTablespaceOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterTablespaceOption);
  }

  virtual std::any visitChangeTablespaceOption(MySQLParser::ChangeTablespaceOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kChangeTablespaceOption);
  }

  virtual std::any visitAlterView(MySQLParser::AlterViewContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterView);
  }

  virtual std::any visitViewTail(MySQLParser::ViewTailContext *ctx) override {
    return this->gen_node_ir(ctx->children, kViewTail);
  }

  virtual std::any visitViewSelect(MySQLParser::ViewSelectContext *ctx) override {
    return this->gen_node_ir(ctx->children, kViewSelect);
  }

  virtual std::any visitViewCheckOption(MySQLParser::ViewCheckOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kViewCheckOption);
  }

  virtual std::any visitCreateStatement(MySQLParser::CreateStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateStatement);
  }

  virtual std::any visitCreateDatabase(MySQLParser::CreateDatabaseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateDatabase);
  }

  virtual std::any visitCreateDatabaseOption(MySQLParser::CreateDatabaseOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateDatabaseOption);
  }

  virtual std::any visitCreateTable(MySQLParser::CreateTableContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateTable);
  }

  virtual std::any visitTableElementList(MySQLParser::TableElementListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTableElementList);
  }

  virtual std::any visitTableElement(MySQLParser::TableElementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTableElement);
  }

  virtual std::any visitDuplicateAsQueryExpression(MySQLParser::DuplicateAsQueryExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDuplicateAsQueryExpression);
  }

  virtual std::any visitQueryExpressionOrParens(MySQLParser::QueryExpressionOrParensContext *ctx) override {
    return this->gen_node_ir(ctx->children, kQueryExpressionOrParens);
  }

  virtual std::any visitCreateRoutine(MySQLParser::CreateRoutineContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateRoutine);
  }

  virtual std::any visitCreateProcedure(MySQLParser::CreateProcedureContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateProcedure);
  }

  virtual std::any visitCreateFunction(MySQLParser::CreateFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateFunction);
  }

  virtual std::any visitCreateUdf(MySQLParser::CreateUdfContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateUdf);
  }

  virtual std::any visitRoutineCreateOption(MySQLParser::RoutineCreateOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRoutineCreateOption);
  }

  virtual std::any visitRoutineAlterOptions(MySQLParser::RoutineAlterOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRoutineAlterOptions);
  }

  virtual std::any visitRoutineOption(MySQLParser::RoutineOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRoutineOption);
  }

  virtual std::any visitCreateIndex(MySQLParser::CreateIndexContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateIndex);
  }

  virtual std::any visitIndexNameAndType(MySQLParser::IndexNameAndTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIndexNameAndType);
  }

  virtual std::any visitCreateIndexTarget(MySQLParser::CreateIndexTargetContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateIndexTarget);
  }

  virtual std::any visitCreateLogfileGroup(MySQLParser::CreateLogfileGroupContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateLogfileGroup);
  }

  virtual std::any visitLogfileGroupOptions(MySQLParser::LogfileGroupOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLogfileGroupOptions);
  }

  virtual std::any visitLogfileGroupOption(MySQLParser::LogfileGroupOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLogfileGroupOption);
  }

  virtual std::any visitCreateServer(MySQLParser::CreateServerContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateServer);
  }

  virtual std::any visitServerOptions(MySQLParser::ServerOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kServerOptions);
  }

  virtual std::any visitServerOption(MySQLParser::ServerOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kServerOption);
  }

  virtual std::any visitCreateTablespace(MySQLParser::CreateTablespaceContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateTablespace);
  }

  virtual std::any visitCreateUndoTablespace(MySQLParser::CreateUndoTablespaceContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateUndoTablespace);
  }

  virtual std::any visitTsDataFileName(MySQLParser::TsDataFileNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTsDataFileName);
  }

  virtual std::any visitTsDataFile(MySQLParser::TsDataFileContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTsDataFile);
  }

  virtual std::any visitTablespaceOptions(MySQLParser::TablespaceOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTablespaceOptions);
  }

  virtual std::any visitTablespaceOption(MySQLParser::TablespaceOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTablespaceOption);
  }

  virtual std::any visitTsOptionInitialSize(MySQLParser::TsOptionInitialSizeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTsOptionInitialSize);
  }

  virtual std::any visitTsOptionUndoRedoBufferSize(MySQLParser::TsOptionUndoRedoBufferSizeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTsOptionUndoRedoBufferSize);
  }

  virtual std::any visitTsOptionAutoextendSize(MySQLParser::TsOptionAutoextendSizeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTsOptionAutoextendSize);
  }

  virtual std::any visitTsOptionMaxSize(MySQLParser::TsOptionMaxSizeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTsOptionMaxSize);
  }

  virtual std::any visitTsOptionExtentSize(MySQLParser::TsOptionExtentSizeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTsOptionExtentSize);
  }

  virtual std::any visitTsOptionNodegroup(MySQLParser::TsOptionNodegroupContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTsOptionNodegroup);
  }

  virtual std::any visitTsOptionEngine(MySQLParser::TsOptionEngineContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTsOptionEngine);
  }

  virtual std::any visitTsOptionWait(MySQLParser::TsOptionWaitContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTsOptionWait);
  }

  virtual std::any visitTsOptionComment(MySQLParser::TsOptionCommentContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTsOptionComment);
  }

  virtual std::any visitTsOptionFileblockSize(MySQLParser::TsOptionFileblockSizeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTsOptionFileblockSize);
  }

  virtual std::any visitTsOptionEncryption(MySQLParser::TsOptionEncryptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTsOptionEncryption);
  }

  virtual std::any visitCreateView(MySQLParser::CreateViewContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateView);
  }

  virtual std::any visitViewReplaceOrAlgorithm(MySQLParser::ViewReplaceOrAlgorithmContext *ctx) override {
    return this->gen_node_ir(ctx->children, kViewReplaceOrAlgorithm);
  }

  virtual std::any visitViewAlgorithm(MySQLParser::ViewAlgorithmContext *ctx) override {
    return this->gen_node_ir(ctx->children, kViewAlgorithm);
  }

  virtual std::any visitViewSuid(MySQLParser::ViewSuidContext *ctx) override {
    return this->gen_node_ir(ctx->children, kViewSuid);
  }

  virtual std::any visitCreateTrigger(MySQLParser::CreateTriggerContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateTrigger);
  }

  virtual std::any visitTriggerFollowsPrecedesClause(MySQLParser::TriggerFollowsPrecedesClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTriggerFollowsPrecedesClause);
  }

  virtual std::any visitCreateEvent(MySQLParser::CreateEventContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateEvent);
  }

  virtual std::any visitCreateRole(MySQLParser::CreateRoleContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateRole);
  }

  virtual std::any visitCreateSpatialReference(MySQLParser::CreateSpatialReferenceContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateSpatialReference);
  }

  virtual std::any visitSrsAttribute(MySQLParser::SrsAttributeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSrsAttribute);
  }

  virtual std::any visitDropStatement(MySQLParser::DropStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDropStatement);
  }

  virtual std::any visitDropDatabase(MySQLParser::DropDatabaseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDropDatabase);
  }

  virtual std::any visitDropEvent(MySQLParser::DropEventContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDropEvent);
  }

  virtual std::any visitDropFunction(MySQLParser::DropFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDropFunction);
  }

  virtual std::any visitDropProcedure(MySQLParser::DropProcedureContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDropProcedure);
  }

  virtual std::any visitDropIndex(MySQLParser::DropIndexContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDropIndex);
  }

  virtual std::any visitDropLogfileGroup(MySQLParser::DropLogfileGroupContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDropLogfileGroup);
  }

  virtual std::any visitDropLogfileGroupOption(MySQLParser::DropLogfileGroupOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDropLogfileGroupOption);
  }

  virtual std::any visitDropServer(MySQLParser::DropServerContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDropServer);
  }

  virtual std::any visitDropTable(MySQLParser::DropTableContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDropTable);
  }

  virtual std::any visitDropTableSpace(MySQLParser::DropTableSpaceContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDropTableSpace);
  }

  virtual std::any visitDropTrigger(MySQLParser::DropTriggerContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDropTrigger);
  }

  virtual std::any visitDropView(MySQLParser::DropViewContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDropView);
  }

  virtual std::any visitDropRole(MySQLParser::DropRoleContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDropRole);
  }

  virtual std::any visitDropSpatialReference(MySQLParser::DropSpatialReferenceContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDropSpatialReference);
  }

  virtual std::any visitDropUndoTablespace(MySQLParser::DropUndoTablespaceContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDropUndoTablespace);
  }

  virtual std::any visitRenameTableStatement(MySQLParser::RenameTableStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRenameTableStatement);
  }

  virtual std::any visitRenamePair(MySQLParser::RenamePairContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRenamePair);
  }

  virtual std::any visitTruncateTableStatement(MySQLParser::TruncateTableStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTruncateTableStatement);
  }

  virtual std::any visitImportStatement(MySQLParser::ImportStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kImportStatement);
  }

  virtual std::any visitCallStatement(MySQLParser::CallStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCallStatement);
  }

  virtual std::any visitDeleteStatement(MySQLParser::DeleteStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDeleteStatement);
  }

  virtual std::any visitPartitionDelete(MySQLParser::PartitionDeleteContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPartitionDelete);
  }

  virtual std::any visitDeleteStatementOption(MySQLParser::DeleteStatementOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDeleteStatementOption);
  }

  virtual std::any visitDoStatement(MySQLParser::DoStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDoStatement);
  }

  virtual std::any visitHandlerStatement(MySQLParser::HandlerStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kHandlerStatement);
  }

  virtual std::any visitHandlerReadOrScan(MySQLParser::HandlerReadOrScanContext *ctx) override {
    return this->gen_node_ir(ctx->children, kHandlerReadOrScan);
  }

  virtual std::any visitInsertStatement(MySQLParser::InsertStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kInsertStatement);
  }

  virtual std::any visitInsertLockOption(MySQLParser::InsertLockOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kInsertLockOption);
  }

  virtual std::any visitInsertFromConstructor(MySQLParser::InsertFromConstructorContext *ctx) override {
    return this->gen_node_ir(ctx->children, kInsertFromConstructor);
  }

  virtual std::any visitFields(MySQLParser::FieldsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFields);
  }

  virtual std::any visitInsertValues(MySQLParser::InsertValuesContext *ctx) override {
    return this->gen_node_ir(ctx->children, kInsertValues);
  }

  virtual std::any visitInsertQueryExpression(MySQLParser::InsertQueryExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kInsertQueryExpression);
  }

  virtual std::any visitValueList(MySQLParser::ValueListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kValueList);
  }

  virtual std::any visitValues(MySQLParser::ValuesContext *ctx) override {
    return this->gen_node_ir(ctx->children, kValues);
  }

  virtual std::any visitValuesReference(MySQLParser::ValuesReferenceContext *ctx) override {
    return this->gen_node_ir(ctx->children, kValuesReference);
  }

  virtual std::any visitInsertUpdateList(MySQLParser::InsertUpdateListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kInsertUpdateList);
  }

  virtual std::any visitLoadStatement(MySQLParser::LoadStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLoadStatement);
  }

  virtual std::any visitDataOrXml(MySQLParser::DataOrXmlContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDataOrXml);
  }

  virtual std::any visitXmlRowsIdentifiedBy(MySQLParser::XmlRowsIdentifiedByContext *ctx) override {
    return this->gen_node_ir(ctx->children, kXmlRowsIdentifiedBy);
  }

  virtual std::any visitLoadDataFileTail(MySQLParser::LoadDataFileTailContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLoadDataFileTail);
  }

  virtual std::any visitLoadDataFileTargetList(MySQLParser::LoadDataFileTargetListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLoadDataFileTargetList);
  }

  virtual std::any visitFieldOrVariableList(MySQLParser::FieldOrVariableListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFieldOrVariableList);
  }

  virtual std::any visitReplaceStatement(MySQLParser::ReplaceStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kReplaceStatement);
  }

  virtual std::any visitSelectStatement(MySQLParser::SelectStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSelectStatement);
  }

  virtual std::any visitSelectStatementWithInto(MySQLParser::SelectStatementWithIntoContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSelectStatementWithInto);
  }

  virtual std::any visitQueryExpression(MySQLParser::QueryExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kQueryExpression);
  }

  virtual std::any visitQueryExpressionBody(MySQLParser::QueryExpressionBodyContext *ctx) override {
    return this->gen_node_ir(ctx->children, kQueryExpressionBody);
  }

  virtual std::any visitQueryExpressionParens(MySQLParser::QueryExpressionParensContext *ctx) override {
    return this->gen_node_ir(ctx->children, kQueryExpressionParens);
  }

  virtual std::any visitQueryPrimary(MySQLParser::QueryPrimaryContext *ctx) override {
    return this->gen_node_ir(ctx->children, kQueryPrimary);
  }

  virtual std::any visitQuerySpecification(MySQLParser::QuerySpecificationContext *ctx) override {
    return this->gen_node_ir(ctx->children, kQuerySpecification);
  }

  virtual std::any visitSubquery(MySQLParser::SubqueryContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSubquery);
  }

  virtual std::any visitQuerySpecOption(MySQLParser::QuerySpecOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kQuerySpecOption);
  }

  virtual std::any visitLimitClause(MySQLParser::LimitClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLimitClause);
  }

  virtual std::any visitSimpleLimitClause(MySQLParser::SimpleLimitClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleLimitClause);
  }

  virtual std::any visitLimitOptions(MySQLParser::LimitOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLimitOptions);
  }

  virtual std::any visitLimitOption(MySQLParser::LimitOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLimitOption);
  }

  virtual std::any visitIntoClause(MySQLParser::IntoClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIntoClause);
  }

  virtual std::any visitProcedureAnalyseClause(MySQLParser::ProcedureAnalyseClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kProcedureAnalyseClause);
  }

  virtual std::any visitHavingClause(MySQLParser::HavingClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kHavingClause);
  }

  virtual std::any visitWindowClause(MySQLParser::WindowClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWindowClause);
  }

  virtual std::any visitWindowDefinition(MySQLParser::WindowDefinitionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWindowDefinition);
  }

  virtual std::any visitWindowSpec(MySQLParser::WindowSpecContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWindowSpec);
  }

  virtual std::any visitWindowSpecDetails(MySQLParser::WindowSpecDetailsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWindowSpecDetails);
  }

  virtual std::any visitWindowFrameClause(MySQLParser::WindowFrameClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWindowFrameClause);
  }

  virtual std::any visitWindowFrameUnits(MySQLParser::WindowFrameUnitsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWindowFrameUnits);
  }

  virtual std::any visitWindowFrameExtent(MySQLParser::WindowFrameExtentContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWindowFrameExtent);
  }

  virtual std::any visitWindowFrameStart(MySQLParser::WindowFrameStartContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWindowFrameStart);
  }

  virtual std::any visitWindowFrameBetween(MySQLParser::WindowFrameBetweenContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWindowFrameBetween);
  }

  virtual std::any visitWindowFrameBound(MySQLParser::WindowFrameBoundContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWindowFrameBound);
  }

  virtual std::any visitWindowFrameExclusion(MySQLParser::WindowFrameExclusionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWindowFrameExclusion);
  }

  virtual std::any visitWithClause(MySQLParser::WithClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWithClause);
  }

  virtual std::any visitCommonTableExpression(MySQLParser::CommonTableExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCommonTableExpression);
  }

  virtual std::any visitGroupByClause(MySQLParser::GroupByClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kGroupByClause);
  }

  virtual std::any visitOlapOption(MySQLParser::OlapOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kOlapOption);
  }

  virtual std::any visitOrderClause(MySQLParser::OrderClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kOrderClause);
  }

  virtual std::any visitDirection(MySQLParser::DirectionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDirection);
  }

  virtual std::any visitFromClause(MySQLParser::FromClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFromClause);
  }

  virtual std::any visitTableReferenceList(MySQLParser::TableReferenceListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTableReferenceList);
  }

  virtual std::any visitTableValueConstructor(MySQLParser::TableValueConstructorContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTableValueConstructor);
  }

  virtual std::any visitExplicitTable(MySQLParser::ExplicitTableContext *ctx) override {
    return this->gen_node_ir(ctx->children, kExplicitTable);
  }

  virtual std::any visitRowValueExplicit(MySQLParser::RowValueExplicitContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRowValueExplicit);
  }

  virtual std::any visitSelectOption(MySQLParser::SelectOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSelectOption);
  }

  virtual std::any visitLockingClauseList(MySQLParser::LockingClauseListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLockingClauseList);
  }

  virtual std::any visitLockingClause(MySQLParser::LockingClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLockingClause);
  }

  virtual std::any visitLockStrengh(MySQLParser::LockStrenghContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLockStrengh);
  }

  virtual std::any visitLockedRowAction(MySQLParser::LockedRowActionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLockedRowAction);
  }

  virtual std::any visitSelectItemList(MySQLParser::SelectItemListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSelectItemList);
  }

  virtual std::any visitSelectItem(MySQLParser::SelectItemContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSelectItem);
  }

  virtual std::any visitSelectAlias(MySQLParser::SelectAliasContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSelectAlias);
  }

  virtual std::any visitWhereClause(MySQLParser::WhereClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWhereClause);
  }

  virtual std::any visitTableReference(MySQLParser::TableReferenceContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTableReference);
  }

  virtual std::any visitEscapedTableReference(MySQLParser::EscapedTableReferenceContext *ctx) override {
    return this->gen_node_ir(ctx->children, kEscapedTableReference);
  }

  virtual std::any visitJoinedTable(MySQLParser::JoinedTableContext *ctx) override {
    return this->gen_node_ir(ctx->children, kJoinedTable);
  }

  virtual std::any visitNaturalJoinType(MySQLParser::NaturalJoinTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kNaturalJoinType);
  }

  virtual std::any visitInnerJoinType(MySQLParser::InnerJoinTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kInnerJoinType);
  }

  virtual std::any visitOuterJoinType(MySQLParser::OuterJoinTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kOuterJoinType);
  }

  virtual std::any visitTableFactor(MySQLParser::TableFactorContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTableFactor);
  }

  virtual std::any visitSingleTable(MySQLParser::SingleTableContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSingleTable);
  }

  virtual std::any visitSingleTableParens(MySQLParser::SingleTableParensContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSingleTableParens);
  }

  virtual std::any visitDerivedTable(MySQLParser::DerivedTableContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDerivedTable);
  }

  virtual std::any visitTableReferenceListParens(MySQLParser::TableReferenceListParensContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTableReferenceListParens);
  }

  virtual std::any visitTableFunction(MySQLParser::TableFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTableFunction);
  }

  virtual std::any visitColumnsClause(MySQLParser::ColumnsClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kColumnsClause);
  }

  virtual std::any visitJtColumn(MySQLParser::JtColumnContext *ctx) override {
    return this->gen_node_ir(ctx->children, kJtColumn);
  }

  virtual std::any visitOnEmptyOrError(MySQLParser::OnEmptyOrErrorContext *ctx) override {
    return this->gen_node_ir(ctx->children, kOnEmptyOrError);
  }

  virtual std::any visitOnEmpty(MySQLParser::OnEmptyContext *ctx) override {
    return this->gen_node_ir(ctx->children, kOnEmpty);
  }

  virtual std::any visitOnError(MySQLParser::OnErrorContext *ctx) override {
    return this->gen_node_ir(ctx->children, kOnError);
  }

  virtual std::any visitJtOnResponse(MySQLParser::JtOnResponseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kJtOnResponse);
  }

  virtual std::any visitUnionOption(MySQLParser::UnionOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUnionOption);
  }

  virtual std::any visitTableAlias(MySQLParser::TableAliasContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTableAlias);
  }

  virtual std::any visitIndexHintList(MySQLParser::IndexHintListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIndexHintList);
  }

  virtual std::any visitIndexHint(MySQLParser::IndexHintContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIndexHint);
  }

  virtual std::any visitIndexHintType(MySQLParser::IndexHintTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIndexHintType);
  }

  virtual std::any visitKeyOrIndex(MySQLParser::KeyOrIndexContext *ctx) override {
    return this->gen_node_ir(ctx->children, kKeyOrIndex);
  }

  virtual std::any visitConstraintKeyType(MySQLParser::ConstraintKeyTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kConstraintKeyType);
  }

  virtual std::any visitIndexHintClause(MySQLParser::IndexHintClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIndexHintClause);
  }

  virtual std::any visitIndexList(MySQLParser::IndexListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIndexList);
  }

  virtual std::any visitIndexListElement(MySQLParser::IndexListElementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIndexListElement);
  }

  virtual std::any visitUpdateStatement(MySQLParser::UpdateStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUpdateStatement);
  }

  virtual std::any visitTransactionOrLockingStatement(MySQLParser::TransactionOrLockingStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTransactionOrLockingStatement);
  }

  virtual std::any visitTransactionStatement(MySQLParser::TransactionStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTransactionStatement);
  }

  virtual std::any visitBeginWork(MySQLParser::BeginWorkContext *ctx) override {
    return this->gen_node_ir(ctx->children, kBeginWork);
  }

  virtual std::any visitTransactionCharacteristic(MySQLParser::TransactionCharacteristicContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTransactionCharacteristic);
  }

  virtual std::any visitSavepointStatement(MySQLParser::SavepointStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSavepointStatement);
  }

  virtual std::any visitLockStatement(MySQLParser::LockStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLockStatement);
  }

  virtual std::any visitLockItem(MySQLParser::LockItemContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLockItem);
  }

  virtual std::any visitLockOption(MySQLParser::LockOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLockOption);
  }

  virtual std::any visitXaStatement(MySQLParser::XaStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kXaStatement);
  }

  virtual std::any visitXaConvert(MySQLParser::XaConvertContext *ctx) override {
    return this->gen_node_ir(ctx->children, kXaConvert);
  }

  virtual std::any visitXid(MySQLParser::XidContext *ctx) override {
    return this->gen_node_ir(ctx->children, kXid);
  }

  virtual std::any visitReplicationStatement(MySQLParser::ReplicationStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kReplicationStatement);
  }

  virtual std::any visitResetOption(MySQLParser::ResetOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kResetOption);
  }

  virtual std::any visitMasterResetOptions(MySQLParser::MasterResetOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kMasterResetOptions);
  }

  virtual std::any visitReplicationLoad(MySQLParser::ReplicationLoadContext *ctx) override {
    return this->gen_node_ir(ctx->children, kReplicationLoad);
  }

  virtual std::any visitChangeMaster(MySQLParser::ChangeMasterContext *ctx) override {
    return this->gen_node_ir(ctx->children, kChangeMaster);
  }

  virtual std::any visitChangeMasterOptions(MySQLParser::ChangeMasterOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kChangeMasterOptions);
  }

  virtual std::any visitMasterOption(MySQLParser::MasterOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kMasterOption);
  }

  virtual std::any visitPrivilegeCheckDef(MySQLParser::PrivilegeCheckDefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPrivilegeCheckDef);
  }

  virtual std::any visitTablePrimaryKeyCheckDef(MySQLParser::TablePrimaryKeyCheckDefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTablePrimaryKeyCheckDef);
  }

  virtual std::any visitMasterTlsCiphersuitesDef(MySQLParser::MasterTlsCiphersuitesDefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kMasterTlsCiphersuitesDef);
  }

  virtual std::any visitMasterFileDef(MySQLParser::MasterFileDefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kMasterFileDef);
  }

  virtual std::any visitServerIdList(MySQLParser::ServerIdListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kServerIdList);
  }

  virtual std::any visitChangeReplication(MySQLParser::ChangeReplicationContext *ctx) override {
    return this->gen_node_ir(ctx->children, kChangeReplication);
  }

  virtual std::any visitFilterDefinition(MySQLParser::FilterDefinitionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFilterDefinition);
  }

  virtual std::any visitFilterDbList(MySQLParser::FilterDbListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFilterDbList);
  }

  virtual std::any visitFilterTableList(MySQLParser::FilterTableListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFilterTableList);
  }

  virtual std::any visitFilterStringList(MySQLParser::FilterStringListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFilterStringList);
  }

  virtual std::any visitFilterWildDbTableString(MySQLParser::FilterWildDbTableStringContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFilterWildDbTableString);
  }

  virtual std::any visitFilterDbPairList(MySQLParser::FilterDbPairListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFilterDbPairList);
  }

  virtual std::any visitSlave(MySQLParser::SlaveContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSlave);
  }

  virtual std::any visitSlaveUntilOptions(MySQLParser::SlaveUntilOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSlaveUntilOptions);
  }

  virtual std::any visitSlaveConnectionOptions(MySQLParser::SlaveConnectionOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSlaveConnectionOptions);
  }

  virtual std::any visitSlaveThreadOptions(MySQLParser::SlaveThreadOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSlaveThreadOptions);
  }

  virtual std::any visitSlaveThreadOption(MySQLParser::SlaveThreadOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSlaveThreadOption);
  }

  virtual std::any visitGroupReplication(MySQLParser::GroupReplicationContext *ctx) override {
    return this->gen_node_ir(ctx->children, kGroupReplication);
  }

  virtual std::any visitPreparedStatement(MySQLParser::PreparedStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPreparedStatement);
  }

  virtual std::any visitExecuteStatement(MySQLParser::ExecuteStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kExecuteStatement);
  }

  virtual std::any visitExecuteVarList(MySQLParser::ExecuteVarListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kExecuteVarList);
  }

  virtual std::any visitCloneStatement(MySQLParser::CloneStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCloneStatement);
  }

  virtual std::any visitDataDirSSL(MySQLParser::DataDirSSLContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDataDirSSL);
  }

  virtual std::any visitSsl(MySQLParser::SslContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSsl);
  }

  virtual std::any visitAccountManagementStatement(MySQLParser::AccountManagementStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAccountManagementStatement);
  }

  virtual std::any visitAlterUser(MySQLParser::AlterUserContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterUser);
  }

  virtual std::any visitAlterUserTail(MySQLParser::AlterUserTailContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterUserTail);
  }

  virtual std::any visitUserFunction(MySQLParser::UserFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUserFunction);
  }

  virtual std::any visitCreateUser(MySQLParser::CreateUserContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateUser);
  }

  virtual std::any visitCreateUserTail(MySQLParser::CreateUserTailContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateUserTail);
  }

  virtual std::any visitDefaultRoleClause(MySQLParser::DefaultRoleClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDefaultRoleClause);
  }

  virtual std::any visitRequireClause(MySQLParser::RequireClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRequireClause);
  }

  virtual std::any visitConnectOptions(MySQLParser::ConnectOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kConnectOptions);
  }

  virtual std::any visitAccountLockPasswordExpireOptions(MySQLParser::AccountLockPasswordExpireOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAccountLockPasswordExpireOptions);
  }

  virtual std::any visitDropUser(MySQLParser::DropUserContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDropUser);
  }

  virtual std::any visitGrant(MySQLParser::GrantContext *ctx) override {
    return this->gen_node_ir(ctx->children, kGrant);
  }

  virtual std::any visitGrantTargetList(MySQLParser::GrantTargetListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kGrantTargetList);
  }

  virtual std::any visitGrantOptions(MySQLParser::GrantOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kGrantOptions);
  }

  virtual std::any visitExceptRoleList(MySQLParser::ExceptRoleListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kExceptRoleList);
  }

  virtual std::any visitWithRoles(MySQLParser::WithRolesContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWithRoles);
  }

  virtual std::any visitGrantAs(MySQLParser::GrantAsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kGrantAs);
  }

  virtual std::any visitVersionedRequireClause(MySQLParser::VersionedRequireClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kVersionedRequireClause);
  }

  virtual std::any visitRenameUser(MySQLParser::RenameUserContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRenameUser);
  }

  virtual std::any visitRevoke(MySQLParser::RevokeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRevoke);
  }

  virtual std::any visitOnTypeTo(MySQLParser::OnTypeToContext *ctx) override {
    return this->gen_node_ir(ctx->children, kOnTypeTo);
  }

  virtual std::any visitAclType(MySQLParser::AclTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAclType);
  }

  virtual std::any visitRoleOrPrivilegesList(MySQLParser::RoleOrPrivilegesListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRoleOrPrivilegesList);
  }

  virtual std::any visitRoleOrPrivilege(MySQLParser::RoleOrPrivilegeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRoleOrPrivilege);
  }

  virtual std::any visitGrantIdentifier(MySQLParser::GrantIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children, kGrantIdentifier);
  }

  virtual std::any visitRequireList(MySQLParser::RequireListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRequireList);
  }

  virtual std::any visitRequireListElement(MySQLParser::RequireListElementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRequireListElement);
  }

  virtual std::any visitGrantOption(MySQLParser::GrantOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kGrantOption);
  }

  virtual std::any visitSetRole(MySQLParser::SetRoleContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSetRole);
  }

  virtual std::any visitRoleList(MySQLParser::RoleListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRoleList);
  }

  virtual std::any visitRole(MySQLParser::RoleContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRole);
  }

  virtual std::any visitTableAdministrationStatement(MySQLParser::TableAdministrationStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTableAdministrationStatement);
  }

  virtual std::any visitHistogram(MySQLParser::HistogramContext *ctx) override {
    return this->gen_node_ir(ctx->children, kHistogram);
  }

  virtual std::any visitCheckOption(MySQLParser::CheckOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCheckOption);
  }

  virtual std::any visitRepairType(MySQLParser::RepairTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRepairType);
  }

  virtual std::any visitInstallUninstallStatment(MySQLParser::InstallUninstallStatmentContext *ctx) override {
    return this->gen_node_ir(ctx->children, kInstallUninstallStatment);
  }

  virtual std::any visitSetStatement(MySQLParser::SetStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSetStatement);
  }

  virtual std::any visitStartOptionValueList(MySQLParser::StartOptionValueListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kStartOptionValueList);
  }

  virtual std::any visitTransactionCharacteristics(MySQLParser::TransactionCharacteristicsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTransactionCharacteristics);
  }

  virtual std::any visitTransactionAccessMode(MySQLParser::TransactionAccessModeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTransactionAccessMode);
  }

  virtual std::any visitIsolationLevel(MySQLParser::IsolationLevelContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIsolationLevel);
  }

  virtual std::any visitOptionValueListContinued(MySQLParser::OptionValueListContinuedContext *ctx) override {
    return this->gen_node_ir(ctx->children, kOptionValueListContinued);
  }

  virtual std::any visitOptionValueNoOptionType(MySQLParser::OptionValueNoOptionTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kOptionValueNoOptionType);
  }

  virtual std::any visitOptionValue(MySQLParser::OptionValueContext *ctx) override {
    return this->gen_node_ir(ctx->children, kOptionValue);
  }

  virtual std::any visitSetSystemVariable(MySQLParser::SetSystemVariableContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSetSystemVariable);
  }

  virtual std::any visitStartOptionValueListFollowingOptionType(MySQLParser::StartOptionValueListFollowingOptionTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kStartOptionValueListFollowingOptionType);
  }

  virtual std::any visitOptionValueFollowingOptionType(MySQLParser::OptionValueFollowingOptionTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kOptionValueFollowingOptionType);
  }

  virtual std::any visitSetExprOrDefault(MySQLParser::SetExprOrDefaultContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSetExprOrDefault);
  }

  virtual std::any visitShowStatement(MySQLParser::ShowStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kShowStatement);
  }

  virtual std::any visitShowCommandType(MySQLParser::ShowCommandTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kShowCommandType);
  }

  virtual std::any visitNonBlocking(MySQLParser::NonBlockingContext *ctx) override {
    return this->gen_node_ir(ctx->children, kNonBlocking);
  }

  virtual std::any visitFromOrIn(MySQLParser::FromOrInContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFromOrIn);
  }

  virtual std::any visitInDb(MySQLParser::InDbContext *ctx) override {
    return this->gen_node_ir(ctx->children, kInDb);
  }

  virtual std::any visitProfileType(MySQLParser::ProfileTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kProfileType);
  }

  virtual std::any visitOtherAdministrativeStatement(MySQLParser::OtherAdministrativeStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kOtherAdministrativeStatement);
  }

  virtual std::any visitKeyCacheListOrParts(MySQLParser::KeyCacheListOrPartsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kKeyCacheListOrParts);
  }

  virtual std::any visitKeyCacheList(MySQLParser::KeyCacheListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kKeyCacheList);
  }

  virtual std::any visitAssignToKeycache(MySQLParser::AssignToKeycacheContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAssignToKeycache);
  }

  virtual std::any visitAssignToKeycachePartition(MySQLParser::AssignToKeycachePartitionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAssignToKeycachePartition);
  }

  virtual std::any visitCacheKeyList(MySQLParser::CacheKeyListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCacheKeyList);
  }

  virtual std::any visitKeyUsageElement(MySQLParser::KeyUsageElementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kKeyUsageElement);
  }

  virtual std::any visitKeyUsageList(MySQLParser::KeyUsageListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kKeyUsageList);
  }

  virtual std::any visitFlushOption(MySQLParser::FlushOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFlushOption);
  }

  virtual std::any visitLogType(MySQLParser::LogTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLogType);
  }

  virtual std::any visitFlushTables(MySQLParser::FlushTablesContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFlushTables);
  }

  virtual std::any visitFlushTablesOptions(MySQLParser::FlushTablesOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFlushTablesOptions);
  }

  virtual std::any visitPreloadTail(MySQLParser::PreloadTailContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPreloadTail);
  }

  virtual std::any visitPreloadList(MySQLParser::PreloadListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPreloadList);
  }

  virtual std::any visitPreloadKeys(MySQLParser::PreloadKeysContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPreloadKeys);
  }

  virtual std::any visitAdminPartition(MySQLParser::AdminPartitionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAdminPartition);
  }

  virtual std::any visitResourceGroupManagement(MySQLParser::ResourceGroupManagementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kResourceGroupManagement);
  }

  virtual std::any visitCreateResourceGroup(MySQLParser::CreateResourceGroupContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateResourceGroup);
  }

  virtual std::any visitResourceGroupVcpuList(MySQLParser::ResourceGroupVcpuListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kResourceGroupVcpuList);
  }

  virtual std::any visitVcpuNumOrRange(MySQLParser::VcpuNumOrRangeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kVcpuNumOrRange);
  }

  virtual std::any visitResourceGroupPriority(MySQLParser::ResourceGroupPriorityContext *ctx) override {
    return this->gen_node_ir(ctx->children, kResourceGroupPriority);
  }

  virtual std::any visitResourceGroupEnableDisable(MySQLParser::ResourceGroupEnableDisableContext *ctx) override {
    return this->gen_node_ir(ctx->children, kResourceGroupEnableDisable);
  }

  virtual std::any visitAlterResourceGroup(MySQLParser::AlterResourceGroupContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterResourceGroup);
  }

  virtual std::any visitSetResourceGroup(MySQLParser::SetResourceGroupContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSetResourceGroup);
  }

  virtual std::any visitThreadIdList(MySQLParser::ThreadIdListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kThreadIdList);
  }

  virtual std::any visitDropResourceGroup(MySQLParser::DropResourceGroupContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDropResourceGroup);
  }

  virtual std::any visitUtilityStatement(MySQLParser::UtilityStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUtilityStatement);
  }

  virtual std::any visitDescribeStatement(MySQLParser::DescribeStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDescribeStatement);
  }

  virtual std::any visitExplainStatement(MySQLParser::ExplainStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kExplainStatement);
  }

  virtual std::any visitExplainableStatement(MySQLParser::ExplainableStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kExplainableStatement);
  }

  virtual std::any visitHelpCommand(MySQLParser::HelpCommandContext *ctx) override {
    return this->gen_node_ir(ctx->children, kHelpCommand);
  }

  virtual std::any visitUseCommand(MySQLParser::UseCommandContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUseCommand);
  }

  virtual std::any visitRestartServer(MySQLParser::RestartServerContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRestartServer);
  }

  virtual std::any visitExprOr(MySQLParser::ExprOrContext *ctx) override {
    return this->gen_node_ir(ctx->children, kExprOr);
  }

  virtual std::any visitExprNot(MySQLParser::ExprNotContext *ctx) override {
    return this->gen_node_ir(ctx->children, kExprNot);
  }

  virtual std::any visitExprIs(MySQLParser::ExprIsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kExprIs);
  }

  virtual std::any visitExprAnd(MySQLParser::ExprAndContext *ctx) override {
    return this->gen_node_ir(ctx->children, kExprAnd);
  }

  virtual std::any visitExprXor(MySQLParser::ExprXorContext *ctx) override {
    return this->gen_node_ir(ctx->children, kExprXor);
  }

  virtual std::any visitPrimaryExprPredicate(MySQLParser::PrimaryExprPredicateContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPrimaryExprPredicate);
  }

  virtual std::any visitPrimaryExprCompare(MySQLParser::PrimaryExprCompareContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPrimaryExprCompare);
  }

  virtual std::any visitPrimaryExprAllAny(MySQLParser::PrimaryExprAllAnyContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPrimaryExprAllAny);
  }

  virtual std::any visitPrimaryExprIsNull(MySQLParser::PrimaryExprIsNullContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPrimaryExprIsNull);
  }

  virtual std::any visitCompOp(MySQLParser::CompOpContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCompOp);
  }

  virtual std::any visitPredicate(MySQLParser::PredicateContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPredicate);
  }

  virtual std::any visitPredicateExprIn(MySQLParser::PredicateExprInContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPredicateExprIn);
  }

  virtual std::any visitPredicateExprBetween(MySQLParser::PredicateExprBetweenContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPredicateExprBetween);
  }

  virtual std::any visitPredicateExprLike(MySQLParser::PredicateExprLikeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPredicateExprLike);
  }

  virtual std::any visitPredicateExprRegex(MySQLParser::PredicateExprRegexContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPredicateExprRegex);
  }

  virtual std::any visitBitExpr(MySQLParser::BitExprContext *ctx) override {
    return this->gen_node_ir(ctx->children, kBitExpr);
  }

  virtual std::any visitSimpleExprConvert(MySQLParser::SimpleExprConvertContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprConvert);
  }

  virtual std::any visitSimpleExprVariable(MySQLParser::SimpleExprVariableContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprVariable);
  }

  virtual std::any visitSimpleExprCast(MySQLParser::SimpleExprCastContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprCast);
  }

  virtual std::any visitSimpleExprUnary(MySQLParser::SimpleExprUnaryContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprUnary);
  }

  virtual std::any visitSimpleExprOdbc(MySQLParser::SimpleExprOdbcContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprOdbc);
  }

  virtual std::any visitSimpleExprRuntimeFunction(MySQLParser::SimpleExprRuntimeFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprRuntimeFunction);
  }

  virtual std::any visitSimpleExprFunction(MySQLParser::SimpleExprFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprFunction);
  }

  virtual std::any visitSimpleExprCollate(MySQLParser::SimpleExprCollateContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprCollate);
  }

  virtual std::any visitSimpleExprMatch(MySQLParser::SimpleExprMatchContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprMatch);
  }

  virtual std::any visitSimpleExprWindowingFunction(MySQLParser::SimpleExprWindowingFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprWindowingFunction);
  }

  virtual std::any visitSimpleExprBinary(MySQLParser::SimpleExprBinaryContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprBinary);
  }

  virtual std::any visitSimpleExprColumnRef(MySQLParser::SimpleExprColumnRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprColumnRef);
  }

  virtual std::any visitSimpleExprParamMarker(MySQLParser::SimpleExprParamMarkerContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprParamMarker);
  }

  virtual std::any visitSimpleExprSum(MySQLParser::SimpleExprSumContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprSum);
  }

  virtual std::any visitSimpleExprConvertUsing(MySQLParser::SimpleExprConvertUsingContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprConvertUsing);
  }

  virtual std::any visitSimpleExprSubQuery(MySQLParser::SimpleExprSubQueryContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprSubQuery);
  }

  virtual std::any visitSimpleExprGroupingOperation(MySQLParser::SimpleExprGroupingOperationContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprGroupingOperation);
  }

  virtual std::any visitSimpleExprNot(MySQLParser::SimpleExprNotContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprNot);
  }

  virtual std::any visitSimpleExprValues(MySQLParser::SimpleExprValuesContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprValues);
  }

  virtual std::any visitSimpleExprDefault(MySQLParser::SimpleExprDefaultContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprDefault);
  }

  virtual std::any visitSimpleExprList(MySQLParser::SimpleExprListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprList);
  }

  virtual std::any visitSimpleExprInterval(MySQLParser::SimpleExprIntervalContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprInterval);
  }

  virtual std::any visitSimpleExprCase(MySQLParser::SimpleExprCaseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprCase);
  }

  virtual std::any visitSimpleExprConcat(MySQLParser::SimpleExprConcatContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprConcat);
  }

  virtual std::any visitSimpleExprLiteral(MySQLParser::SimpleExprLiteralContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprLiteral);
  }

  virtual std::any visitArrayCast(MySQLParser::ArrayCastContext *ctx) override {
    return this->gen_node_ir(ctx->children, kArrayCast);
  }

  virtual std::any visitJsonOperator(MySQLParser::JsonOperatorContext *ctx) override {
    return this->gen_node_ir(ctx->children, kJsonOperator);
  }

  virtual std::any visitSumExpr(MySQLParser::SumExprContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSumExpr);
  }

  virtual std::any visitGroupingOperation(MySQLParser::GroupingOperationContext *ctx) override {
    return this->gen_node_ir(ctx->children, kGroupingOperation);
  }

  virtual std::any visitWindowFunctionCall(MySQLParser::WindowFunctionCallContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWindowFunctionCall);
  }

  virtual std::any visitWindowingClause(MySQLParser::WindowingClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWindowingClause);
  }

  virtual std::any visitLeadLagInfo(MySQLParser::LeadLagInfoContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLeadLagInfo);
  }

  virtual std::any visitNullTreatment(MySQLParser::NullTreatmentContext *ctx) override {
    return this->gen_node_ir(ctx->children, kNullTreatment);
  }

  virtual std::any visitJsonFunction(MySQLParser::JsonFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kJsonFunction);
  }

  virtual std::any visitInSumExpr(MySQLParser::InSumExprContext *ctx) override {
    return this->gen_node_ir(ctx->children, kInSumExpr);
  }

  virtual std::any visitIdentListArg(MySQLParser::IdentListArgContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIdentListArg);
  }

  virtual std::any visitIdentList(MySQLParser::IdentListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIdentList);
  }

  virtual std::any visitFulltextOptions(MySQLParser::FulltextOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFulltextOptions);
  }

  virtual std::any visitRuntimeFunctionCall(MySQLParser::RuntimeFunctionCallContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRuntimeFunctionCall);
  }

  virtual std::any visitGeometryFunction(MySQLParser::GeometryFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kGeometryFunction);
  }

  virtual std::any visitTimeFunctionParameters(MySQLParser::TimeFunctionParametersContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTimeFunctionParameters);
  }

  virtual std::any visitFractionalPrecision(MySQLParser::FractionalPrecisionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFractionalPrecision);
  }

  virtual std::any visitWeightStringLevels(MySQLParser::WeightStringLevelsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWeightStringLevels);
  }

  virtual std::any visitWeightStringLevelListItem(MySQLParser::WeightStringLevelListItemContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWeightStringLevelListItem);
  }

  virtual std::any visitDateTimeTtype(MySQLParser::DateTimeTtypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDateTimeTtype);
  }

  virtual std::any visitTrimFunction(MySQLParser::TrimFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTrimFunction);
  }

  virtual std::any visitSubstringFunction(MySQLParser::SubstringFunctionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSubstringFunction);
  }

  virtual std::any visitFunctionCall(MySQLParser::FunctionCallContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFunctionCall);
  }

  virtual std::any visitUdfExprList(MySQLParser::UdfExprListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUdfExprList);
  }

  virtual std::any visitUdfExpr(MySQLParser::UdfExprContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUdfExpr);
  }

  virtual std::any visitVariable(MySQLParser::VariableContext *ctx) override {
    return this->gen_node_ir(ctx->children, kVariable);
  }

  virtual std::any visitUserVariable(MySQLParser::UserVariableContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUserVariable);
  }

  virtual std::any visitSystemVariable(MySQLParser::SystemVariableContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSystemVariable);
  }

  virtual std::any visitInternalVariableName(MySQLParser::InternalVariableNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kInternalVariableName);
  }

  virtual std::any visitWhenExpression(MySQLParser::WhenExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWhenExpression);
  }

  virtual std::any visitThenExpression(MySQLParser::ThenExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kThenExpression);
  }

  virtual std::any visitElseExpression(MySQLParser::ElseExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kElseExpression);
  }

  virtual std::any visitCastType(MySQLParser::CastTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCastType);
  }

  virtual std::any visitExprList(MySQLParser::ExprListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kExprList);
  }

  virtual std::any visitCharset(MySQLParser::CharsetContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCharset);
  }

  virtual std::any visitNotRule(MySQLParser::NotRuleContext *ctx) override {
    return this->gen_node_ir(ctx->children, kNotRule);
  }

  virtual std::any visitNot2Rule(MySQLParser::Not2RuleContext *ctx) override {
    return this->gen_node_ir(ctx->children, kNot2Rule);
  }

  virtual std::any visitInterval(MySQLParser::IntervalContext *ctx) override {
    return this->gen_node_ir(ctx->children, kInterval);
  }

  virtual std::any visitIntervalTimeStamp(MySQLParser::IntervalTimeStampContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIntervalTimeStamp);
  }

  virtual std::any visitExprListWithParentheses(MySQLParser::ExprListWithParenthesesContext *ctx) override {
    return this->gen_node_ir(ctx->children, kExprListWithParentheses);
  }

  virtual std::any visitExprWithParentheses(MySQLParser::ExprWithParenthesesContext *ctx) override {
    return this->gen_node_ir(ctx->children, kExprWithParentheses);
  }

  virtual std::any visitSimpleExprWithParentheses(MySQLParser::SimpleExprWithParenthesesContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleExprWithParentheses);
  }

  virtual std::any visitOrderList(MySQLParser::OrderListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kOrderList);
  }

  virtual std::any visitOrderExpression(MySQLParser::OrderExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kOrderExpression);
  }

  virtual std::any visitGroupList(MySQLParser::GroupListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kGroupList);
  }

  virtual std::any visitGroupingExpression(MySQLParser::GroupingExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kGroupingExpression);
  }

  virtual std::any visitChannel(MySQLParser::ChannelContext *ctx) override {
    return this->gen_node_ir(ctx->children, kChannel);
  }

  virtual std::any visitCompoundStatement(MySQLParser::CompoundStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCompoundStatement);
  }

  virtual std::any visitReturnStatement(MySQLParser::ReturnStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kReturnStatement);
  }

  virtual std::any visitIfStatement(MySQLParser::IfStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIfStatement);
  }

  virtual std::any visitIfBody(MySQLParser::IfBodyContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIfBody);
  }

  virtual std::any visitThenStatement(MySQLParser::ThenStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kThenStatement);
  }

  virtual std::any visitCompoundStatementList(MySQLParser::CompoundStatementListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCompoundStatementList);
  }

  virtual std::any visitCaseStatement(MySQLParser::CaseStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCaseStatement);
  }

  virtual std::any visitElseStatement(MySQLParser::ElseStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kElseStatement);
  }

  virtual std::any visitLabeledBlock(MySQLParser::LabeledBlockContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLabeledBlock);
  }

  virtual std::any visitUnlabeledBlock(MySQLParser::UnlabeledBlockContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUnlabeledBlock);
  }

  virtual std::any visitLabel(MySQLParser::LabelContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLabel);
  }

  virtual std::any visitBeginEndBlock(MySQLParser::BeginEndBlockContext *ctx) override {
    return this->gen_node_ir(ctx->children, kBeginEndBlock);
  }

  virtual std::any visitLabeledControl(MySQLParser::LabeledControlContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLabeledControl);
  }

  virtual std::any visitUnlabeledControl(MySQLParser::UnlabeledControlContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUnlabeledControl);
  }

  virtual std::any visitLoopBlock(MySQLParser::LoopBlockContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLoopBlock);
  }

  virtual std::any visitWhileDoBlock(MySQLParser::WhileDoBlockContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWhileDoBlock);
  }

  virtual std::any visitRepeatUntilBlock(MySQLParser::RepeatUntilBlockContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRepeatUntilBlock);
  }

  virtual std::any visitSpDeclarations(MySQLParser::SpDeclarationsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSpDeclarations);
  }

  virtual std::any visitSpDeclaration(MySQLParser::SpDeclarationContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSpDeclaration);
  }

  virtual std::any visitVariableDeclaration(MySQLParser::VariableDeclarationContext *ctx) override {
    return this->gen_node_ir(ctx->children, kVariableDeclaration);
  }

  virtual std::any visitConditionDeclaration(MySQLParser::ConditionDeclarationContext *ctx) override {
    return this->gen_node_ir(ctx->children, kConditionDeclaration);
  }

  virtual std::any visitSpCondition(MySQLParser::SpConditionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSpCondition);
  }

  virtual std::any visitSqlstate(MySQLParser::SqlstateContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSqlstate);
  }

  virtual std::any visitHandlerDeclaration(MySQLParser::HandlerDeclarationContext *ctx) override {
    return this->gen_node_ir(ctx->children, kHandlerDeclaration);
  }

  virtual std::any visitHandlerCondition(MySQLParser::HandlerConditionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kHandlerCondition);
  }

  virtual std::any visitCursorDeclaration(MySQLParser::CursorDeclarationContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCursorDeclaration);
  }

  virtual std::any visitIterateStatement(MySQLParser::IterateStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIterateStatement);
  }

  virtual std::any visitLeaveStatement(MySQLParser::LeaveStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLeaveStatement);
  }

  virtual std::any visitGetDiagnostics(MySQLParser::GetDiagnosticsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kGetDiagnostics);
  }

  virtual std::any visitSignalAllowedExpr(MySQLParser::SignalAllowedExprContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSignalAllowedExpr);
  }

  virtual std::any visitStatementInformationItem(MySQLParser::StatementInformationItemContext *ctx) override {
    return this->gen_node_ir(ctx->children, kStatementInformationItem);
  }

  virtual std::any visitConditionInformationItem(MySQLParser::ConditionInformationItemContext *ctx) override {
    return this->gen_node_ir(ctx->children, kConditionInformationItem);
  }

  virtual std::any visitSignalInformationItemName(MySQLParser::SignalInformationItemNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSignalInformationItemName);
  }

  virtual std::any visitSignalStatement(MySQLParser::SignalStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSignalStatement);
  }

  virtual std::any visitResignalStatement(MySQLParser::ResignalStatementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kResignalStatement);
  }

  virtual std::any visitSignalInformationItem(MySQLParser::SignalInformationItemContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSignalInformationItem);
  }

  virtual std::any visitCursorOpen(MySQLParser::CursorOpenContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCursorOpen);
  }

  virtual std::any visitCursorClose(MySQLParser::CursorCloseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCursorClose);
  }

  virtual std::any visitCursorFetch(MySQLParser::CursorFetchContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCursorFetch);
  }

  virtual std::any visitSchedule(MySQLParser::ScheduleContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSchedule);
  }

  virtual std::any visitColumnDefinition(MySQLParser::ColumnDefinitionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kColumnDefinition);
  }

  virtual std::any visitCheckOrReferences(MySQLParser::CheckOrReferencesContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCheckOrReferences);
  }

  virtual std::any visitCheckConstraint(MySQLParser::CheckConstraintContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCheckConstraint);
  }

  virtual std::any visitConstraintEnforcement(MySQLParser::ConstraintEnforcementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kConstraintEnforcement);
  }

  virtual std::any visitTableConstraintDef(MySQLParser::TableConstraintDefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTableConstraintDef);
  }

  virtual std::any visitConstraintName(MySQLParser::ConstraintNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kConstraintName);
  }

  virtual std::any visitFieldDefinition(MySQLParser::FieldDefinitionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFieldDefinition);
  }

  virtual std::any visitColumnAttribute(MySQLParser::ColumnAttributeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kColumnAttribute);
  }

  virtual std::any visitColumnFormat(MySQLParser::ColumnFormatContext *ctx) override {
    return this->gen_node_ir(ctx->children, kColumnFormat);
  }

  virtual std::any visitStorageMedia(MySQLParser::StorageMediaContext *ctx) override {
    return this->gen_node_ir(ctx->children, kStorageMedia);
  }

  virtual std::any visitGcolAttribute(MySQLParser::GcolAttributeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kGcolAttribute);
  }

  virtual std::any visitReferences(MySQLParser::ReferencesContext *ctx) override {
    return this->gen_node_ir(ctx->children, kReferences);
  }

  virtual std::any visitDeleteOption(MySQLParser::DeleteOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDeleteOption);
  }

  virtual std::any visitKeyList(MySQLParser::KeyListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kKeyList);
  }

  virtual std::any visitKeyPart(MySQLParser::KeyPartContext *ctx) override {
    return this->gen_node_ir(ctx->children, kKeyPart);
  }

  virtual std::any visitKeyListWithExpression(MySQLParser::KeyListWithExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kKeyListWithExpression);
  }

  virtual std::any visitKeyPartOrExpression(MySQLParser::KeyPartOrExpressionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kKeyPartOrExpression);
  }

  virtual std::any visitKeyListVariants(MySQLParser::KeyListVariantsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kKeyListVariants);
  }

  virtual std::any visitIndexType(MySQLParser::IndexTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIndexType);
  }

  virtual std::any visitIndexOption(MySQLParser::IndexOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIndexOption);
  }

  virtual std::any visitCommonIndexOption(MySQLParser::CommonIndexOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCommonIndexOption);
  }

  virtual std::any visitVisibility(MySQLParser::VisibilityContext *ctx) override {
    return this->gen_node_ir(ctx->children, kVisibility);
  }

  virtual std::any visitIndexTypeClause(MySQLParser::IndexTypeClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIndexTypeClause);
  }

  virtual std::any visitFulltextIndexOption(MySQLParser::FulltextIndexOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFulltextIndexOption);
  }

  virtual std::any visitSpatialIndexOption(MySQLParser::SpatialIndexOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSpatialIndexOption);
  }

  virtual std::any visitDataTypeDefinition(MySQLParser::DataTypeDefinitionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDataTypeDefinition);
  }

  virtual std::any visitDataType(MySQLParser::DataTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDataType);
  }

  virtual std::any visitNchar(MySQLParser::NcharContext *ctx) override {
    return this->gen_node_ir(ctx->children, kNchar);
  }

  virtual std::any visitRealType(MySQLParser::RealTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRealType);
  }

  virtual std::any visitFieldLength(MySQLParser::FieldLengthContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFieldLength);
  }

  virtual std::any visitFieldOptions(MySQLParser::FieldOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFieldOptions);
  }

  virtual std::any visitCharsetWithOptBinary(MySQLParser::CharsetWithOptBinaryContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCharsetWithOptBinary);
  }

  virtual std::any visitAscii(MySQLParser::AsciiContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAscii);
  }

  virtual std::any visitUnicode(MySQLParser::UnicodeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUnicode);
  }

  virtual std::any visitWsNumCodepoints(MySQLParser::WsNumCodepointsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWsNumCodepoints);
  }

  virtual std::any visitTypeDatetimePrecision(MySQLParser::TypeDatetimePrecisionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTypeDatetimePrecision);
  }

  virtual std::any visitCharsetName(MySQLParser::CharsetNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCharsetName);
  }

  virtual std::any visitCollationName(MySQLParser::CollationNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCollationName);
  }

  virtual std::any visitCreateTableOptions(MySQLParser::CreateTableOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateTableOptions);
  }

  virtual std::any visitCreateTableOptionsSpaceSeparated(MySQLParser::CreateTableOptionsSpaceSeparatedContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateTableOptionsSpaceSeparated);
  }

  virtual std::any visitCreateTableOption(MySQLParser::CreateTableOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateTableOption);
  }

  virtual std::any visitTernaryOption(MySQLParser::TernaryOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTernaryOption);
  }

  virtual std::any visitDefaultCollation(MySQLParser::DefaultCollationContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDefaultCollation);
  }

  virtual std::any visitDefaultEncryption(MySQLParser::DefaultEncryptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDefaultEncryption);
  }

  virtual std::any visitDefaultCharset(MySQLParser::DefaultCharsetContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDefaultCharset);
  }

  virtual std::any visitPartitionClause(MySQLParser::PartitionClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPartitionClause);
  }

  virtual std::any visitPartitionDefKey(MySQLParser::PartitionDefKeyContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPartitionDefKey);
  }

  virtual std::any visitPartitionDefHash(MySQLParser::PartitionDefHashContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPartitionDefHash);
  }

  virtual std::any visitPartitionDefRangeList(MySQLParser::PartitionDefRangeListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPartitionDefRangeList);
  }

  virtual std::any visitSubPartitions(MySQLParser::SubPartitionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSubPartitions);
  }

  virtual std::any visitPartitionKeyAlgorithm(MySQLParser::PartitionKeyAlgorithmContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPartitionKeyAlgorithm);
  }

  virtual std::any visitPartitionDefinitions(MySQLParser::PartitionDefinitionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPartitionDefinitions);
  }

  virtual std::any visitPartitionDefinition(MySQLParser::PartitionDefinitionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPartitionDefinition);
  }

  virtual std::any visitPartitionValuesIn(MySQLParser::PartitionValuesInContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPartitionValuesIn);
  }

  virtual std::any visitPartitionOption(MySQLParser::PartitionOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPartitionOption);
  }

  virtual std::any visitSubpartitionDefinition(MySQLParser::SubpartitionDefinitionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSubpartitionDefinition);
  }

  virtual std::any visitPartitionValueItemListParen(MySQLParser::PartitionValueItemListParenContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPartitionValueItemListParen);
  }

  virtual std::any visitPartitionValueItem(MySQLParser::PartitionValueItemContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPartitionValueItem);
  }

  virtual std::any visitDefinerClause(MySQLParser::DefinerClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDefinerClause);
  }

  virtual std::any visitIfExists(MySQLParser::IfExistsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIfExists);
  }

  virtual std::any visitIfNotExists(MySQLParser::IfNotExistsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIfNotExists);
  }

  virtual std::any visitProcedureParameter(MySQLParser::ProcedureParameterContext *ctx) override {
    return this->gen_node_ir(ctx->children, kProcedureParameter);
  }

  virtual std::any visitFunctionParameter(MySQLParser::FunctionParameterContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFunctionParameter);
  }

  virtual std::any visitCollate(MySQLParser::CollateContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCollate);
  }

  virtual std::any visitTypeWithOptCollate(MySQLParser::TypeWithOptCollateContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTypeWithOptCollate);
  }

  virtual std::any visitSchemaIdentifierPair(MySQLParser::SchemaIdentifierPairContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSchemaIdentifierPair);
  }

  virtual std::any visitViewRefList(MySQLParser::ViewRefListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kViewRefList);
  }

  virtual std::any visitUpdateList(MySQLParser::UpdateListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUpdateList);
  }

  virtual std::any visitUpdateElement(MySQLParser::UpdateElementContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUpdateElement);
  }

  virtual std::any visitCharsetClause(MySQLParser::CharsetClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCharsetClause);
  }

  virtual std::any visitFieldsClause(MySQLParser::FieldsClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFieldsClause);
  }

  virtual std::any visitFieldTerm(MySQLParser::FieldTermContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFieldTerm);
  }

  virtual std::any visitLinesClause(MySQLParser::LinesClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLinesClause);
  }

  virtual std::any visitLineTerm(MySQLParser::LineTermContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLineTerm);
  }

  virtual std::any visitUserList(MySQLParser::UserListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUserList);
  }

  virtual std::any visitCreateUserList(MySQLParser::CreateUserListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateUserList);
  }

  virtual std::any visitAlterUserList(MySQLParser::AlterUserListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterUserList);
  }

  virtual std::any visitCreateUserEntry(MySQLParser::CreateUserEntryContext *ctx) override {
    return this->gen_node_ir(ctx->children, kCreateUserEntry);
  }

  virtual std::any visitAlterUserEntry(MySQLParser::AlterUserEntryContext *ctx) override {
    return this->gen_node_ir(ctx->children, kAlterUserEntry);
  }

  virtual std::any visitRetainCurrentPassword(MySQLParser::RetainCurrentPasswordContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRetainCurrentPassword);
  }

  virtual std::any visitDiscardOldPassword(MySQLParser::DiscardOldPasswordContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDiscardOldPassword);
  }

  virtual std::any visitReplacePassword(MySQLParser::ReplacePasswordContext *ctx) override {
    return this->gen_node_ir(ctx->children, kReplacePassword);
  }

  virtual std::any visitUserIdentifierOrText(MySQLParser::UserIdentifierOrTextContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUserIdentifierOrText);
  }

  virtual std::any visitUser(MySQLParser::UserContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUser);
  }

  virtual std::any visitLikeClause(MySQLParser::LikeClauseContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLikeClause);
  }

  virtual std::any visitLikeOrWhere(MySQLParser::LikeOrWhereContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLikeOrWhere);
  }

  virtual std::any visitOnlineOption(MySQLParser::OnlineOptionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kOnlineOption);
  }

  virtual std::any visitNoWriteToBinLog(MySQLParser::NoWriteToBinLogContext *ctx) override {
    return this->gen_node_ir(ctx->children, kNoWriteToBinLog);
  }

  virtual std::any visitUsePartition(MySQLParser::UsePartitionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUsePartition);
  }

  virtual std::any visitFieldIdentifier(MySQLParser::FieldIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFieldIdentifier);
  }

  virtual std::any visitColumnName(MySQLParser::ColumnNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kColumnName);
  }

  virtual std::any visitColumnInternalRef(MySQLParser::ColumnInternalRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kColumnInternalRef);
  }

  virtual std::any visitColumnInternalRefList(MySQLParser::ColumnInternalRefListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kColumnInternalRefList);
  }

  virtual std::any visitColumnRef(MySQLParser::ColumnRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kColumnRef);
  }

  virtual std::any visitInsertIdentifier(MySQLParser::InsertIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children, kInsertIdentifier);
  }

  virtual std::any visitIndexName(MySQLParser::IndexNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIndexName);
  }

  virtual std::any visitIndexRef(MySQLParser::IndexRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIndexRef);
  }

  virtual std::any visitTableWild(MySQLParser::TableWildContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTableWild);
  }

  virtual std::any visitSchemaName(MySQLParser::SchemaNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSchemaName);
  }

  virtual std::any visitSchemaRef(MySQLParser::SchemaRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSchemaRef);
  }

  virtual std::any visitProcedureName(MySQLParser::ProcedureNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kProcedureName);
  }

  virtual std::any visitProcedureRef(MySQLParser::ProcedureRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kProcedureRef);
  }

  virtual std::any visitFunctionName(MySQLParser::FunctionNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFunctionName);
  }

  virtual std::any visitFunctionRef(MySQLParser::FunctionRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFunctionRef);
  }

  virtual std::any visitTriggerName(MySQLParser::TriggerNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTriggerName);
  }

  virtual std::any visitTriggerRef(MySQLParser::TriggerRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTriggerRef);
  }

  virtual std::any visitViewName(MySQLParser::ViewNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kViewName);
  }

  virtual std::any visitViewRef(MySQLParser::ViewRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kViewRef);
  }

  virtual std::any visitTablespaceName(MySQLParser::TablespaceNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTablespaceName);
  }

  virtual std::any visitTablespaceRef(MySQLParser::TablespaceRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTablespaceRef);
  }

  virtual std::any visitLogfileGroupName(MySQLParser::LogfileGroupNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLogfileGroupName);
  }

  virtual std::any visitLogfileGroupRef(MySQLParser::LogfileGroupRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLogfileGroupRef);
  }

  virtual std::any visitEventName(MySQLParser::EventNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kEventName);
  }

  virtual std::any visitEventRef(MySQLParser::EventRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kEventRef);
  }

  virtual std::any visitUdfName(MySQLParser::UdfNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUdfName);
  }

  virtual std::any visitServerName(MySQLParser::ServerNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kServerName);
  }

  virtual std::any visitServerRef(MySQLParser::ServerRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kServerRef);
  }

  virtual std::any visitEngineRef(MySQLParser::EngineRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kEngineRef);
  }

  virtual std::any visitTableName(MySQLParser::TableNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTableName);
  }

  virtual std::any visitFilterTableRef(MySQLParser::FilterTableRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFilterTableRef);
  }

  virtual std::any visitTableRefWithWildcard(MySQLParser::TableRefWithWildcardContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTableRefWithWildcard);
  }

  virtual std::any visitTableRef(MySQLParser::TableRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTableRef);
  }

  virtual std::any visitTableRefList(MySQLParser::TableRefListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTableRefList);
  }

  virtual std::any visitTableAliasRefList(MySQLParser::TableAliasRefListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTableAliasRefList);
  }

  virtual std::any visitParameterName(MySQLParser::ParameterNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kParameterName);
  }

  virtual std::any visitLabelIdentifier(MySQLParser::LabelIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLabelIdentifier);
  }

  virtual std::any visitLabelRef(MySQLParser::LabelRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLabelRef);
  }

  virtual std::any visitRoleIdentifier(MySQLParser::RoleIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRoleIdentifier);
  }

  virtual std::any visitRoleRef(MySQLParser::RoleRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRoleRef);
  }

  virtual std::any visitPluginRef(MySQLParser::PluginRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPluginRef);
  }

  virtual std::any visitComponentRef(MySQLParser::ComponentRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kComponentRef);
  }

  virtual std::any visitResourceGroupRef(MySQLParser::ResourceGroupRefContext *ctx) override {
    return this->gen_node_ir(ctx->children, kResourceGroupRef);
  }

  virtual std::any visitWindowName(MySQLParser::WindowNameContext *ctx) override {
    return this->gen_node_ir(ctx->children, kWindowName);
  }

  virtual std::any visitPureIdentifier(MySQLParser::PureIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPureIdentifier);
  }

  virtual std::any visitIdentifier(MySQLParser::IdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIdentifier);
  }

  virtual std::any visitIdentifierList(MySQLParser::IdentifierListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIdentifierList);
  }

  virtual std::any visitIdentifierListWithParentheses(MySQLParser::IdentifierListWithParenthesesContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIdentifierListWithParentheses);
  }

  virtual std::any visitQualifiedIdentifier(MySQLParser::QualifiedIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children, kQualifiedIdentifier);
  }

  virtual std::any visitSimpleIdentifier(MySQLParser::SimpleIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSimpleIdentifier);
  }

  virtual std::any visitDotIdentifier(MySQLParser::DotIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children, kDotIdentifier);
  }

  virtual std::any visitUlong_number(MySQLParser::Ulong_numberContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUlong_number);
  }

  virtual std::any visitReal_ulong_number(MySQLParser::Real_ulong_numberContext *ctx) override {
    return this->gen_node_ir(ctx->children, kReal_ulong_number);
  }

  virtual std::any visitUlonglong_number(MySQLParser::Ulonglong_numberContext *ctx) override {
    return this->gen_node_ir(ctx->children, kUlonglong_number);
  }

  virtual std::any visitReal_ulonglong_number(MySQLParser::Real_ulonglong_numberContext *ctx) override {
    return this->gen_node_ir(ctx->children, kReal_ulonglong_number);
  }

  virtual std::any visitLiteral(MySQLParser::LiteralContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLiteral);
  }

  virtual std::any visitSignedLiteral(MySQLParser::SignedLiteralContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSignedLiteral);
  }

  virtual std::any visitStringList(MySQLParser::StringListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kStringList);
  }

  virtual std::any visitTextStringLiteral(MySQLParser::TextStringLiteralContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTextStringLiteral);
  }

  virtual std::any visitTextString(MySQLParser::TextStringContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTextString);
  }

  virtual std::any visitTextStringHash(MySQLParser::TextStringHashContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTextStringHash);
  }

  virtual std::any visitTextLiteral(MySQLParser::TextLiteralContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTextLiteral);
  }

  virtual std::any visitTextStringNoLinebreak(MySQLParser::TextStringNoLinebreakContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTextStringNoLinebreak);
  }

  virtual std::any visitTextStringLiteralList(MySQLParser::TextStringLiteralListContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTextStringLiteralList);
  }

  virtual std::any visitNumLiteral(MySQLParser::NumLiteralContext *ctx) override {
    return this->gen_node_ir(ctx->children, kNumLiteral);
  }

  virtual std::any visitBoolLiteral(MySQLParser::BoolLiteralContext *ctx) override {
    return this->gen_node_ir(ctx->children, kBoolLiteral);
  }

  virtual std::any visitNullLiteral(MySQLParser::NullLiteralContext *ctx) override {
    return this->gen_node_ir(ctx->children, kNullLiteral);
  }

  virtual std::any visitTemporalLiteral(MySQLParser::TemporalLiteralContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTemporalLiteral);
  }

  virtual std::any visitFloatOptions(MySQLParser::FloatOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kFloatOptions);
  }

  virtual std::any visitStandardFloatOptions(MySQLParser::StandardFloatOptionsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kStandardFloatOptions);
  }

  virtual std::any visitPrecision(MySQLParser::PrecisionContext *ctx) override {
    return this->gen_node_ir(ctx->children, kPrecision);
  }

  virtual std::any visitTextOrIdentifier(MySQLParser::TextOrIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children, kTextOrIdentifier);
  }

  virtual std::any visitLValueIdentifier(MySQLParser::LValueIdentifierContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLValueIdentifier);
  }

  virtual std::any visitRoleIdentifierOrText(MySQLParser::RoleIdentifierOrTextContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRoleIdentifierOrText);
  }

  virtual std::any visitSizeNumber(MySQLParser::SizeNumberContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSizeNumber);
  }

  virtual std::any visitParentheses(MySQLParser::ParenthesesContext *ctx) override {
    return this->gen_node_ir(ctx->children, kParentheses);
  }

  virtual std::any visitEqual(MySQLParser::EqualContext *ctx) override {
    return this->gen_node_ir(ctx->children, kEqual);
  }

  virtual std::any visitOptionType(MySQLParser::OptionTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kOptionType);
  }

  virtual std::any visitVarIdentType(MySQLParser::VarIdentTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kVarIdentType);
  }

  virtual std::any visitSetVarIdentType(MySQLParser::SetVarIdentTypeContext *ctx) override {
    return this->gen_node_ir(ctx->children, kSetVarIdentType);
  }

  virtual std::any visitIdentifierKeyword(MySQLParser::IdentifierKeywordContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIdentifierKeyword);
  }

  virtual std::any visitIdentifierKeywordsAmbiguous1RolesAndLabels(MySQLParser::IdentifierKeywordsAmbiguous1RolesAndLabelsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIdentifierKeywordsAmbiguous1RolesAndLabels);
  }

  virtual std::any visitIdentifierKeywordsAmbiguous2Labels(MySQLParser::IdentifierKeywordsAmbiguous2LabelsContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIdentifierKeywordsAmbiguous2Labels);
  }

  virtual std::any visitLabelKeyword(MySQLParser::LabelKeywordContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLabelKeyword);
  }

  virtual std::any visitIdentifierKeywordsAmbiguous3Roles(MySQLParser::IdentifierKeywordsAmbiguous3RolesContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIdentifierKeywordsAmbiguous3Roles);
  }

  virtual std::any visitIdentifierKeywordsUnambiguous(MySQLParser::IdentifierKeywordsUnambiguousContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIdentifierKeywordsUnambiguous);
  }

  virtual std::any visitRoleKeyword(MySQLParser::RoleKeywordContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRoleKeyword);
  }

  virtual std::any visitLValueKeyword(MySQLParser::LValueKeywordContext *ctx) override {
    return this->gen_node_ir(ctx->children, kLValueKeyword);
  }

  virtual std::any visitIdentifierKeywordsAmbiguous4SystemVariables(MySQLParser::IdentifierKeywordsAmbiguous4SystemVariablesContext *ctx) override {
    return this->gen_node_ir(ctx->children, kIdentifierKeywordsAmbiguous4SystemVariables);
  }

  virtual std::any visitRoleOrIdentifierKeyword(MySQLParser::RoleOrIdentifierKeywordContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRoleOrIdentifierKeyword);
  }

  virtual std::any visitRoleOrLabelKeyword(MySQLParser::RoleOrLabelKeywordContext *ctx) override {
    return this->gen_node_ir(ctx->children, kRoleOrLabelKeyword);
  }


};

#endif
