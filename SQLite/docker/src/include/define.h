#pragma once
#ifndef __DEFINE_H__
#define __DEFINE_H__

#define ALLTYPE(V)                                                             \
  V(kUnknown)                                                                  \
  V(kFloatLiteral)                                                             \
  V(kStringLiteral)                                                            \
  V(kIntegerLiteral)                                                           \
  V(kTimeLiteral)                                                              \
  V(kInput)                                                                    \
  V(kIdentifier)                                                               \
  V(kCmdlist)                                                                  \
  V(kEcmd)                                                                     \
  V(kExplain)                                                                  \
  V(kCmdx)                                                                     \
  V(kCmd)                                                                      \
  V(kCmdBegin)                                                                 \
  V(kCmdCommit)                                                                \
  V(kCmdRollback)                                                              \
  V(kCmdSavepoint)                                                             \
  V(kCmdRelease)                                                               \
  V(kCmdCreateTable)                                                           \
  V(kCmdCreateView)                                                            \
  V(kCmdSelect)                                                                \
  V(kCmdDelete)                                                                \
  V(kCmdUpdate)                                                                \
  V(kCmdInsert)                                                                \
  V(kCmdCreateIndex)                                                           \
  V(kCmdVacuum)                                                                \
  V(kCmdPragma)                                                                \
  V(kCmdCreateTrigger)                                                         \
  V(kCmdAttach)                                                                \
  V(kCmdDetach)                                                                \
  V(kCmdReindex)                                                               \
  V(kCmdAnalyze)                                                               \
  V(kCmdCreateVTable)                                                          \
  V(kCmdDropTable)                                                             \
  V(kCmdDropView)                                                              \
  V(kCmdDropIndex)                                                             \
  V(kCmdDropTrigger)                                                           \
  V(kCmdAlterTableAddColumn)                                                   \
  V(kCmdAlterTableDropColumn)                                                  \
  V(kCmdAlterTableRenameColumn)                                                \
  V(kCmdAlterTableRename)                                                      \
  V(kTransOpt)                                                                 \
  V(kTranstype)                                                                \
  V(kSavepointOpt)                                                             \
  V(kCreateTable)                                                              \
  V(kCreatekw)                                                                 \
  V(kIfnotexists)                                                              \
  V(kTemp)                                                                     \
  V(kCreateTableArgs)                                                          \
  V(kTableOptionSet)                                                           \
  V(kTableOption)                                                              \
  V(kColumnlist)                                                               \
  V(kColumnname)                                                               \
  V(kNm)                                                                       \
  V(kTypetoken)                                                                \
  V(kTypename)                                                                 \
  V(kSigned)                                                                   \
  V(kScanpt)                                                                   \
  V(kScantok)                                                                  \
  V(kCarglist)                                                                 \
  V(kCcons)                                                                    \
  V(kGenerated)                                                                \
  V(kAutoinc)                                                                  \
  V(kRefargs)                                                                  \
  V(kRefarg)                                                                   \
  V(kRefact)                                                                   \
  V(kDeferSubclause)                                                           \
  V(kInitDeferredPredOpt)                                                      \
  V(kConslistOpt)                                                              \
  V(kConslist)                                                                 \
  V(kTconscomma)                                                               \
  V(kTcons)                                                                    \
  V(kDeferSubclauseOpt)                                                        \
  V(kOnconf)                                                                   \
  V(kOrconf)                                                                   \
  V(kResolvetype)                                                              \
  V(kIfexists)                                                                 \
  V(kSelect)                                                                   \
  V(kSelectnowith)                                                             \
  V(kMultiselectOp)                                                            \
  V(kOneselect)                                                                \
  V(kValues)                                                                   \
  V(kDistinct)                                                                 \
  V(kSclp)                                                                     \
  V(kSelcollist)                                                               \
  V(kAs)                                                                       \
  V(kFrom)                                                                     \
  V(kStlPrefix)                                                                \
  V(kSeltablist)                                                               \
  V(kDbnm)                                                                     \
  V(kFullname)                                                                 \
  V(kXfullname)                                                                \
  V(kJoinop)                                                                   \
  V(kOnUsing)                                                                  \
  V(kIndexedOpt)                                                               \
  V(kIndexedBy)                                                                \
  V(kOrderbyOpt)                                                               \
  V(kSortlist)                                                                 \
  V(kSortorder)                                                                \
  V(kNulls)                                                                    \
  V(kGroupbyOpt)                                                               \
  V(kHavingOpt)                                                                \
  V(kLimitOpt)                                                                 \
  V(kWhereOpt)                                                                 \
  V(kWhereOptRet)                                                              \
  V(kSetlist)                                                                  \
  V(kUpsert)                                                                   \
  V(kReturning)                                                                \
  V(kInsertCmd)                                                                \
  V(kIdlistOpt)                                                                \
  V(kIdlist)                                                                   \
  V(kExpr)                                                                     \
  V(kExprFunc)                                                                 \
  V(kTerm)                                                                     \
  V(kLikeop)                                                                   \
  V(kBetweenOp)                                                                \
  V(kInOp)                                                                     \
  V(kCaseExprlist)                                                             \
  V(kCaseElse)                                                                 \
  V(kCaseOperand)                                                              \
  V(kExprlist)                                                                 \
  V(kNexprlist)                                                                \
  V(kParenExprlist)                                                            \
  V(kUniqueflag)                                                               \
  V(kEidlistOpt)                                                               \
  V(kEidlist)                                                                  \
  V(kCollate)                                                                  \
  V(kVinto)                                                                    \
  V(kNmnum)                                                                    \
  V(kPlusNum)                                                                  \
  V(kMinusNum)                                                                 \
  V(kTriggerDecl)                                                              \
  V(kTriggerTime)                                                              \
  V(kTriggerEvent)                                                             \
  V(kForeachClause)                                                            \
  V(kWhenClause)                                                               \
  V(kTriggerCmdList)                                                           \
  V(kTrnm)                                                                     \
  V(kTridxby)                                                                  \
  V(kTriggerCmd)                                                               \
  V(kRaisetype)                                                                \
  V(kKeyOpt)                                                                   \
  V(kDatabaseKwOpt)                                                            \
  V(kAddColumnFullname)                                                        \
  V(kKwcolumnOpt)                                                              \
  V(kCreateVtab)                                                               \
  V(kVtabarglist)                                                              \
  V(kVtabarg)                                                                  \
  V(kVtabargtoken)                                                             \
  V(kLp)                                                                       \
  V(kAnylist)                                                                  \
  V(kWith)                                                                     \
  V(kWqas)                                                                     \
  V(kWqitem)                                                                   \
  V(kWqlist)                                                                   \
  V(kWindowdefnList)                                                           \
  V(kWindowdefn)                                                               \
  V(kWindow)                                                                   \
  V(kFrameOpt)                                                                 \
  V(kRangeOrRows)                                                              \
  V(kFrameBoundS)                                                              \
  V(kFrameBoundE)                                                              \
  V(kFrameBound)                                                               \
  V(kFrameExcludeOpt)                                                          \
  V(kFrameExclude)                                                             \
  V(kWindowClause)                                                             \
  V(kFilterOver)                                                               \
  V(kOverClause)                                                               \
  V(kFilterClause)

#define ALLCLASS(V)                                                            \
  V(IR)                                                                        \
  V(IROperator)                                                                \
  V(Input)                                                                     \
  V(Cmdlist)                                                                   \
  V(Ecmd)                                                                      \
  V(Explain)                                                                   \
  V(Cmdx)                                                                      \
  V(Cmd)                                                                       \
  V(TransOpt)                                                                  \
  V(Transtype)                                                                 \
  V(SavepointOpt)                                                              \
  V(CreateTable)                                                               \
  V(Createkw)                                                                  \
  V(Ifnotexists)                                                               \
  V(Temp)                                                                      \
  V(CreateTableArgs)                                                           \
  V(TableOptionSet)                                                            \
  V(TableOption)                                                               \
  V(Columnlist)                                                                \
  V(Columnname)                                                                \
  V(Nm)                                                                        \
  V(Typetoken)                                                                 \
  V(Typename)                                                                  \
  V(Signed)                                                                    \
  V(Scanpt)                                                                    \
  V(Scantok)                                                                   \
  V(Carglist)                                                                  \
  V(Ccons)                                                                     \
  V(Generated)                                                                 \
  V(Autoinc)                                                                   \
  V(Refargs)                                                                   \
  V(Refarg)                                                                    \
  V(Refact)                                                                    \
  V(DeferSubclause)                                                            \
  V(InitDeferredPredOpt)                                                       \
  V(ConslistOpt)                                                               \
  V(Conslist)                                                                  \
  V(Tconscomma)                                                                \
  V(Tcons)                                                                     \
  V(DeferSubclauseOpt)                                                         \
  V(Onconf)                                                                    \
  V(Orconf)                                                                    \
  V(Resolvetype)                                                               \
  V(Ifexists)                                                                  \
  V(Select)                                                                    \
  V(Selectnowith)                                                              \
  V(MultiselectOp)                                                             \
  V(Oneselect)                                                                 \
  V(Values)                                                                    \
  V(Distinct)                                                                  \
  V(Sclp)                                                                      \
  V(Selcollist)                                                                \
  V(As)                                                                        \
  V(From)                                                                      \
  V(StlPrefix)                                                                 \
  V(Seltablist)                                                                \
  V(Dbnm)                                                                      \
  V(Fullname)                                                                  \
  V(Xfullname)                                                                 \
  V(Joinop)                                                                    \
  V(OnUsing)                                                                   \
  V(IndexedOpt)                                                                \
  V(IndexedBy)                                                                 \
  V(OrderbyOpt)                                                                \
  V(Sortlist)                                                                  \
  V(Sortorder)                                                                 \
  V(Nulls)                                                                     \
  V(GroupbyOpt)                                                                \
  V(HavingOpt)                                                                 \
  V(LimitOpt)                                                                  \
  V(WhereOpt)                                                                  \
  V(WhereOptRet)                                                               \
  V(Setlist)                                                                   \
  V(Upsert)                                                                    \
  V(Returning)                                                                 \
  V(InsertCmd)                                                                 \
  V(IdlistOpt)                                                                 \
  V(Idlist)                                                                    \
  V(Expr)                                                                      \
  V(Term)                                                                      \
  V(Likeop)                                                                    \
  V(BetweenOp)                                                                 \
  V(InOp)                                                                      \
  V(CaseExprlist)                                                              \
  V(CaseElse)                                                                  \
  V(CaseOperand)                                                               \
  V(Exprlist)                                                                  \
  V(Nexprlist)                                                                 \
  V(ParenExprlist)                                                             \
  V(Uniqueflag)                                                                \
  V(EidlistOpt)                                                                \
  V(Eidlist)                                                                   \
  V(Collate)                                                                   \
  V(Vinto)                                                                     \
  V(Nmnum)                                                                     \
  V(PlusNum)                                                                   \
  V(MinusNum)                                                                  \
  V(TriggerDecl)                                                               \
  V(TriggerTime)                                                               \
  V(TriggerEvent)                                                              \
  V(ForeachClause)                                                             \
  V(WhenClause)                                                                \
  V(TriggerCmdList)                                                            \
  V(Trnm)                                                                      \
  V(Tridxby)                                                                   \
  V(TriggerCmd)                                                                \
  V(Raisetype)                                                                 \
  V(KeyOpt)                                                                    \
  V(DatabaseKwOpt)                                                             \
  V(AddColumnFullname)                                                         \
  V(KwcolumnOpt)                                                               \
  V(CreateVtab)                                                                \
  V(Vtabarglist)                                                               \
  V(Vtabarg)                                                                   \
  V(Vtabargtoken)                                                              \
  V(Lp)                                                                        \
  V(Anylist)                                                                   \
  V(With)                                                                      \
  V(Wqas)                                                                      \
  V(Wqitem)                                                                    \
  V(Wqlist)                                                                    \
  V(WindowdefnList)                                                            \
  V(Windowdefn)                                                                \
  V(Window)                                                                    \
  V(FrameOpt)                                                                  \
  V(RangeOrRows)                                                               \
  V(FrameBoundS)                                                               \
  V(FrameBoundE)                                                               \
  V(FrameBound)                                                                \
  V(FrameExcludeOpt)                                                           \
  V(FrameExclude)                                                              \
  V(WindowClause)                                                              \
  V(FilterOver)                                                                \
  V(OverClause)                                                                \
  V(FilterClause)

#define ALLDATATYPE(V)                                                         \
  V(TYPEUNKNOWN)                                                               \
  V(TYPEUNDEFINE)                                                              \
  V(TYPEANY)                                                                   \
  V(TYPENONE)                                                                  \
  V(TYPEIDENT)                                                                 \
  V(TYPEVOID)                                                                  \
  V(TYPEBIGINT)                                                                \
  V(TYPEBIGSERIAL)                                                             \
  V(TYPEBIT)                                                                   \
  V(TYPEVARBIT)                                                                \
  V(TYPEBOOL)                                                                  \
  V(TYPEBYTEA)                                                                 \
  V(TYPECHAR)                                                                  \
  V(TYPEVARCHAR)                                                               \
  V(TYPECIDR)                                                                  \
  V(TYPEDATE)                                                                  \
  V(TYPEFLOAT)                                                                 \
  V(TYPEINET)                                                                  \
  V(TYPEINT)                                                                   \
  V(TYPEINTERVAL)                                                              \
  V(TYPEJSON)                                                                  \
  V(TYPEJSONB)                                                                 \
  V(TYPEMACADDR)                                                               \
  V(TYPEMACADDR8)                                                              \
  V(TYPEMONEY)                                                                 \
  V(TYPENUMERIC)                                                               \
  V(TYPEREAL)                                                                  \
  V(TYPESMALLINT)                                                              \
  V(TYPESMALLSERIAL)                                                           \
  V(TYPESERIAL)                                                                \
  V(TYPETEXT)                                                                  \
  V(TYPETIME)                                                                  \
  V(TYPETIMETZ)                                                                \
  V(TYPETIMESTAMP)                                                             \
  V(TYPETIMESTAMPTZ)                                                           \
  V(TYPEUUID)                                                                  \
  V(TYPEOID)                                                                   \
  /* Separator line. Do not auto generate the types below this line. */        \
  V(TYPECSTRING)                                                               \
  /* Separator line. Do not support the types below this line. */              \
  V(TYPENOTSUPPORT)                                                            \
  V(TYPETSQUERY)                                                               \
  V(TYPETSVECTOR)                                                              \
  V(TYPETXIDSNAPSHOT)                                                          \
  V(TYPEXML)                                                                   \
  V(TYPEENUM)                                                                  \
  V(TYPETUPLE)                                                                 \
  V(TYPEBOX)                                                                   \
  V(TYPECIRCLE)                                                                \
  V(TYPELINE)                                                                  \
  V(TYPELSEG)                                                                  \
  V(TYPEPATH)                                                                  \
  V(TYPEPGLSN)                                                                 \
  V(TYPEPGSNAPSHOT)                                                            \
  V(TYPEPOINT)                                                                 \
  V(TYPEPOLYGON)


#define SAFETRANSLATE(a) (assert(a != NULL), a->translate(v_ir_collector))

#define SAFEDELETE(a)                                                          \
  if (a != NULL)                                                               \
  a->deep_delete()

#define OP1(a) new IROperator(a)

#define OP2(a, b) new IROperator(a, b)

#define OP3(a, b, c) new IROperator(a, b, c)

#define OPSTART(a) new IROperator(a)

#define OPMID(a) new IROperator("", a, "")

#define OPEND(a) new IROperator("", "", a)

#define OP0() new IROperator()

#define MUTATESTART                                                            \
  IR *res;                                                                     \
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
