import os

with open("../grammar/MySQLParserBaseVisitor.h", "r") as base_vis, open("all_rule_declares.h", "w") as fd:
    fd.write(f"#define ALLTYPE(V) \\\n")
    for cur_line in base_vis.readlines():
        if "virtual std::any visit" not in cur_line:
            continue

        cur_line = cur_line.split("virtual std::any visit")[1]
        cur_line = cur_line.split("(")[0]
        cur_type = "k" + cur_line
        fd.write(f"V({cur_type}) \\\n")

    fd.write("V(kIntLiteral) \\\n")
    fd.write("V(kFloatLiteral) \\\n")
    fd.write("V(kStringLiteral) \\\n")
    fd.write("V(kBooleanLiteral) \\\n")
    fd.write("V(kIdentifierRule) \\\n")
    fd.write("V(kStmtList) \\\n")
    fd.write("V(kUnknown)\n\n")


    fd.write(f"\n#define ALLDATAFLAG(V) \\\n")
    fd.write("""\
  V(kUse) \\
  V(kMapToClosestOne) \\
  V(kNoSplit) \\
  V(kGlobal) \\
  V(kReplace) \\
  V(kUndefine) \\
  V(kAlias) \\
  V(kMapToAll) \\
  V(kDefine) \\
  V(kNoModi) \\
  V(kUseDefine)  /* Immediate use of the defined column. In PRIMARY KEY(), INDEX() etc.*/ \\
  V(kFlagUnknown) \\
""")

    fd.write("\n\n\n")
    fd.write(f"#define ALLDATATYPE(V) \\\n")
    fd.write("""\
  V(kDataWhatever) \\
  V(kDataTableName) \\
  V(kDataColumnName) \\
  V(kDataViewName) \\
  V(kDataFunctionName) \\
  V(kDataFunctionParams) \\
  V(kDataPragmaKey) \\
  V(kDataPragmaValue) \\
  V(kDataTableSpaceName) \\
  V(kDataUndoTableSpaceName) \\
  V(kDataSequenceName) \\
  V(kDataExtensionName) \\
  V(kDataRoleName) \\
  V(kDataSchemaName) \\
  V(kDataDatabase) \\
  V(kDataTriggerName) \\
  V(kDataWindowName) \\
  V(kDataTriggerFunction) \\
  V(kDataDomainName) \\
  V(kDataAliasName) \\
  V(kDataFixLater) \\
  V(kDataIndexName) \\
  V(kDataUserName) \\
  V(kDataHostName) \\
  V(kDataCollate) \\
  V(kDataCharsetName) \\
  V(kDataProcedureName) \\
  V(kDataProcedureParams) \\
  V(kDataServerName) \\
  V(kDataWrapperName) \\
  V(kDataSavePoint) \\
  V(kDataGroupName) \\
  V(kDataLogFileGroupName) \\
  V(kDataFileSystem) \\
  V(kDataSystemVarName) \\
  V(kDataAliasTableName) \\
  V(kDataTableNameFollow) \\
  V(kDataColumnNameFollow) \\
  V(kDataConstraintName) \\
  V(kDataVarName) \\
  V(kDataStmtName) \\
  V(kDataPluginName) \\
  V(kDataComponentName) \\
  V(kDataEngineName) \\
  V(kDataParserName) \\
  V(kDataForeignKey) \\
  V(kDataPartitionName) \\
  V(kDataDatabaseFollow) \\
  V(kDataLabelName) \\
  V(kDataLiteral) \\
  V(kDataEventName) \\
  
""")

    fd.write("\n\n\n")
    fd.write(f"#define ALLSPECIALTERMTOKENTYPE(V) \\\n")
    fd.write("""\
  V(IDENTIFIER) \\
  V(SINGLE_QUOTED_TEXT) \\
  V(DOUBLE_QUOTED_TEXT) \\
  V(HEX_NUMBER) \\
  V(BIN_NUMBER) \\
  V(NCHAR_TEXT) \\
  V(INT_NUMBER) \\
  V(LONG_NUMBER) \\
  V(ULONGLONG_NUMBER) \\
  V(DECIMAL_NUMBER) \\
  V(FLOAT_NUMBER) \\
  V(TRUE_SYMBOL) \\
  V(FALSE_SYMBOL) \\

""")