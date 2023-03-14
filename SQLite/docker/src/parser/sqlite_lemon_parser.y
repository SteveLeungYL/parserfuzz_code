
// All token codes are small integers with #defines that begin with "TK_"
%token_prefix TKIR_

// The type of the data attached to each token is Token.  This is also the
// default type for non-terminals.
//
%token_type {const char*}
%default_type {IR*}

// An extra argument to the parse function for the parser, which is available
// to all actions.
%extra_argument {IR** root_ir}

// The name of the generated procedure that implements the parser
// is as follows:
%name IRParser

// input is the start symbol
%start_symbol input

// The following text is included near the beginning of the C source
// code file that implements the parser.
//
%include {

    #include "../include/ast.h"
    #include "../include/define.h"

}

input(A) ::= cmdlist(B) . {
A = new IR(kInput, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

cmdlist(A) ::= cmdlist(B) ecmd(C) . {
A = new IR(kCmdlist, OP3("", "", ""), (IR*)B, (IR*)C);
*root_ir = (IR*)(A);
}

cmdlist(A) ::= ecmd(B) . {
A = new IR(kCmdlist, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

ecmd(A) ::= SEMI . {
A = new IR(kEcmd, OP3("SEMI", "", ""));
*root_ir = (IR*)(A);
}

ecmd(A) ::= cmdx(B) SEMI . {
A = new IR(kEcmd, OP3("", "SEMI", ""), (IR*)B);
*root_ir = (IR*)(A);
}

ecmd(A) ::= explain(B) cmdx(C) SEMI .       {
A = new IR(kEcmd, OP3("", "", "SEMI"), (IR*)B, (IR*)C);
*root_ir = (IR*)(A);
}

explain(A) ::= EXPLAIN .              {
A = new IR(kExplain, OP3("EXPLAIN", "", ""));
*root_ir = (IR*)(A);
}

explain(A) ::= EXPLAIN QUERY PLAN .   {
A = new IR(kExplain, OP3("EXPLAIN QUERY PLAN", "", ""));
*root_ir = (IR*)(A);
}

cmdx(A) ::= cmd(B) .           {
A = new IR(kCmdx, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

cmd(A) ::= BEGIN transtype(C) trans_opt(D) .  {
A = new IR(kCmd, OP3("BEGIN", "", ""), (IR*)C, (IR*)D);
*root_ir = (IR*)(A);
}

trans_opt(A) ::= . {
A = new IR(kTransOpt, OP0());
*root_ir = (IR*)(A);
}

trans_opt(A) ::= TRANSACTION . {
A = new IR(kTransOpt, OP3("TRANSACTION", "", ""));
*root_ir = (IR*)(A);
}

trans_opt(A) ::= TRANSACTION nm(C) . {
A = new IR(kTransOpt, OP3("TRANSACTION", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

%type transtype {IR*}
transtype(A) ::= .             {
A = new IR(kTranstype, OP0());
*root_ir = (IR*)(A);
}

transtype(A) ::= DEFERRED .  {
A = new IR(kTranstype, OP3("DEFERRED", "", ""));
*root_ir = (IR*)(A);
}

transtype(A) ::= IMMEDIATE . {
A = new IR(kTranstype, OP3("IMMEDIATE", "", ""));
*root_ir = (IR*)(A);
}

transtype(A) ::= EXCLUSIVE . {
A = new IR(kTranstype, OP3("EXCLUSIVE", "", ""));
*root_ir = (IR*)(A);
}

cmd(A) ::= COMMIT|END trans_opt(C) .   {
A = new IR(kCmd, OP3("COMMIT|END", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

cmd(A) ::= ROLLBACK trans_opt(C) .     {
A = new IR(kCmd, OP3("ROLLBACK", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

savepoint_opt(A) ::= SAVEPOINT . {
A = new IR(kSavepointOpt, OP3("SAVEPOINT", "", ""));
*root_ir = (IR*)(A);
}

savepoint_opt(A) ::= . {
A = new IR(kSavepointOpt, OP0());
*root_ir = (IR*)(A);
}

cmd(A) ::= SAVEPOINT nm(C) . {
A = new IR(kCmd, OP3("SAVEPOINT", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

cmd(A) ::= RELEASE savepoint_opt(C) nm(D) . {
A = new IR(kCmd, OP3("RELEASE", "", ""), (IR*)C, (IR*)D);
*root_ir = (IR*)(A);
}

cmd(A) ::= ROLLBACK trans_opt(C) TO savepoint_opt(E) nm(F) . {
A = new IR(kUnknown, OP3("ROLLBACK", "TO", ""), (IR*)C, (IR*)E);
A = new IR(kCmd, OP3("", "", ""), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

cmd(A) ::= create_table(B) create_table_args(C) . {
A = new IR(kCmd, OP3("", "", ""), (IR*)B, (IR*)C);
*root_ir = (IR*)(A);
}

create_table(A) ::= createkw(B) temp(C) TABLE ifnotexists(E) nm(F) dbnm(G) . {
A = new IR(kUnknown, OP3("", "", "TABLE"), (IR*)B, (IR*)C);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
A = new IR(kCreateTable, OP3("", "", ""), (IR*)A, (IR*)G);
*root_ir = (IR*)(A);
}

createkw(A) ::= CREATE .  {
A = new IR(kCreatekw, OP3("CREATE", "", ""));
*root_ir = (IR*)(A);
}

%type ifnotexists {IR*}
ifnotexists(A) ::= .              {
A = new IR(kIfnotexists, OP0());
*root_ir = (IR*)(A);
}

ifnotexists(A) ::= IF NOT EXISTS . {
A = new IR(kIfnotexists, OP3("IF NOT EXISTS", "", ""));
*root_ir = (IR*)(A);
}

%type temp {IR*}
temp(A) ::= TEMP .  {
A = new IR(kTemp, OP3("TEMP", "", ""));
*root_ir = (IR*)(A);
}

temp(A) ::= .      {
A = new IR(kTemp, OP0());
*root_ir = (IR*)(A);
}

create_table_args(A) ::= LP columnlist(C) conslist_opt(D) RP table_option_set(F) . {
A = new IR(kUnknown, OP3("LP", "", "RP"), (IR*)C, (IR*)D);
A = new IR(kCreateTableArgs, OP3("", "", ""), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

create_table_args(A) ::= AS select(C) . {
A = new IR(kCreateTableArgs, OP3("AS", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

%type table_option_set {IR*}
%type table_option {IR*}
table_option_set(A) ::= .    {
A = new IR(kTableOptionSet, OP0());
*root_ir = (IR*)(A);
}

table_option_set(A) ::= table_option(B) . {
A = new IR(kTableOptionSet, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

table_option_set(A) ::= table_option_set(B) COMMA table_option(D) . {
A = new IR(kTableOptionSet, OP3("", "COMMA", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

table_option(A) ::= WITHOUT nm(C) . {
A = new IR(kTableOption, OP3("WITHOUT", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

table_option(A) ::= nm(B) . {
A = new IR(kTableOption, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

columnlist(A) ::= columnlist(B) COMMA columnname(D) carglist(E) . {
A = new IR(kUnknown, OP3("", "COMMA", ""), (IR*)B, (IR*)D);
A = new IR(kColumnlist, OP3("", "", ""), (IR*)A, (IR*)E);
*root_ir = (IR*)(A);
}

columnlist(A) ::= columnname(B) carglist(C) . {
A = new IR(kColumnlist, OP3("", "", ""), (IR*)B, (IR*)C);
*root_ir = (IR*)(A);
}

columnname(A) ::= nm(B) typetoken(C) . {
A = new IR(kColumnname, OP3("", "", ""), (IR*)B, (IR*)C);
*root_ir = (IR*)(A);
}

%token ABORT ACTION AFTER ANALYZE ASC ATTACH BEFORE BEGIN BY CASCADE CAST.
%token CONFLICT DATABASE DEFERRED DESC DETACH EACH END EXCLUSIVE EXPLAIN FAIL.
%token OR AND NOT IS MATCH LIKE_KW BETWEEN IN ISNULL NOTNULL NE EQ.
%token GT LE LT GE ESCAPE.
%fallback ID
  ABORT ACTION AFTER ANALYZE ASC ATTACH BEFORE BEGIN BY CASCADE CAST COLUMNKW
  CONFLICT DATABASE DEFERRED DESC DETACH DO
  EACH END EXCLUSIVE EXPLAIN FAIL FOR
  IGNORE IMMEDIATE INITIALLY INSTEAD LIKE_KW MATCH NO PLAN
  QUERY KEY OF OFFSET PRAGMA RAISE RECURSIVE RELEASE REPLACE RESTRICT ROW ROWS
  ROLLBACK SAVEPOINT TEMP TRIGGER VACUUM VIEW VIRTUAL WITH WITHOUT
  NULLS FIRST LAST
  CURRENT FOLLOWING PARTITION PRECEDING RANGE UNBOUNDED
  EXCLUDE GROUPS OTHERS TIES
  GENERATED ALWAYS
  MATERIALIZED
  REINDEX RENAME CTIME_KW IF
  .
%wildcard ANY.
%left OR.
%left AND.
%right NOT.
%left IS MATCH LIKE_KW BETWEEN IN ISNULL NOTNULL NE EQ.
%left GT LE LT GE.
%right ESCAPE.
%left BITAND BITOR LSHIFT RSHIFT.
%left PLUS MINUS.
%left STAR SLASH REM.
%left CONCAT PTR.
%left COLLATE.
%right BITNOT.
%nonassoc ON.
%token_class id  ID|INDEXED.
%token_class ids  ID|STRING.
%type nm {IR*}
nm(A) ::= id . {
A = new IR(kNm, OP3("ID", "", ""));
*root_ir = (IR*)(A);
}

nm(A) ::= STRING . {
A = new IR(kNm, OP3("STRING", "", ""));
*root_ir = (IR*)(A);
}

nm(A) ::= JOIN_KW . {
A = new IR(kNm, OP3("JOIN_KW", "", ""));
*root_ir = (IR*)(A);
}

%type typetoken {IR*}
typetoken(A) ::= .   {
A = new IR(kTypetoken, OP0());
*root_ir = (IR*)(A);
}

typetoken(A) ::= typename(B) . {
A = new IR(kTypetoken, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

typetoken(A) ::= typename(B) LP signed(D) RP . {
A = new IR(kTypetoken, OP3("", "LP", "RP"), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

typetoken(A) ::= typename(B) LP signed(D) COMMA signed(F) RP . {
A = new IR(kUnknown, OP3("", "LP", "COMMA"), (IR*)B, (IR*)D);
A = new IR(kTypetoken, OP3("", "", "RP"), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

%type typename {IR*}
typename(A) ::= ids . {
A = new IR(kTypename, OP3("IDS", "", ""));
*root_ir = (IR*)(A);
}

typename(A) ::= typename(B) ids . {
A = new IR(kTypename, OP3("", "IDS", ""), (IR*)B);
*root_ir = (IR*)(A);
}

signed(A) ::= plus_num(B) . {
A = new IR(kSigned, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

signed(A) ::= minus_num(B) . {
A = new IR(kSigned, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

%type scanpt {IR*}
scanpt(A) ::= . {
A = new IR(kScanpt, OP0());
*root_ir = (IR*)(A);
}

scantok(A) ::= . {
A = new IR(kScantok, OP0());
*root_ir = (IR*)(A);
}

carglist(A) ::= carglist(B) ccons(C) . {
A = new IR(kCarglist, OP3("", "", ""), (IR*)B, (IR*)C);
*root_ir = (IR*)(A);
}

carglist(A) ::= . {
A = new IR(kCarglist, OP0());
*root_ir = (IR*)(A);
}

ccons(A) ::= CONSTRAINT nm(C) .           {
A = new IR(kCcons, OP3("CONSTRAINT", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

ccons(A) ::= DEFAULT scantok(C) term(D) . {
A = new IR(kCcons, OP3("DEFAULT", "", ""), (IR*)C, (IR*)D);
*root_ir = (IR*)(A);
}

ccons(A) ::= DEFAULT LP expr(D) RP . {
A = new IR(kCcons, OP3("DEFAULT LP", "RP", ""), (IR*)D);
*root_ir = (IR*)(A);
}

ccons(A) ::= DEFAULT PLUS scantok(D) term(E) . {
A = new IR(kCcons, OP3("DEFAULT PLUS", "", ""), (IR*)D, (IR*)E);
*root_ir = (IR*)(A);
}

ccons(A) ::= DEFAULT MINUS scantok(D) term(E) . {
A = new IR(kCcons, OP3("DEFAULT MINUS", "", ""), (IR*)D, (IR*)E);
*root_ir = (IR*)(A);
}

ccons(A) ::= DEFAULT scantok(C) id .       {
A = new IR(kCcons, OP3("DEFAULT", "ID", ""), (IR*)C);
*root_ir = (IR*)(A);
}

ccons(A) ::= NULL onconf(C) . {
A = new IR(kCcons, OP3("NULL", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

ccons(A) ::= NOT NULL onconf(D) .    {
A = new IR(kCcons, OP3("NOT NULL", "", ""), (IR*)D);
*root_ir = (IR*)(A);
}

ccons(A) ::= PRIMARY KEY sortorder(D) onconf(E) autoinc(F) . {
A = new IR(kUnknown, OP3("PRIMARY KEY", "", ""), (IR*)D, (IR*)E);
A = new IR(kCcons, OP3("", "", ""), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

ccons(A) ::= UNIQUE onconf(C) .      {
A = new IR(kCcons, OP3("UNIQUE", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

ccons(A) ::= CHECK LP expr(D) RP .  {
A = new IR(kCcons, OP3("CHECK LP", "RP", ""), (IR*)D);
*root_ir = (IR*)(A);
}

ccons(A) ::= REFERENCES nm(C) eidlist_opt(D) refargs(E) . {
A = new IR(kUnknown, OP3("REFERENCES", "", ""), (IR*)C, (IR*)D);
A = new IR(kCcons, OP3("", "", ""), (IR*)A, (IR*)E);
*root_ir = (IR*)(A);
}

ccons(A) ::= defer_subclause(B) .    {
A = new IR(kCcons, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

ccons(A) ::= COLLATE ids .        {
A = new IR(kCcons, OP3("COLLATE IDS", "", ""));
*root_ir = (IR*)(A);
}

ccons(A) ::= GENERATED ALWAYS AS generated(E) . {
A = new IR(kCcons, OP3("GENERATED ALWAYS AS", "", ""), (IR*)E);
*root_ir = (IR*)(A);
}

ccons(A) ::= AS generated(C) . {
A = new IR(kCcons, OP3("AS", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

generated(A) ::= LP expr(C) RP .          {
A = new IR(kGenerated, OP3("LP", "RP", ""), (IR*)C);
*root_ir = (IR*)(A);
}

generated(A) ::= LP expr(C) RP ID . {
A = new IR(kGenerated, OP3("LP", "RP ID", ""), (IR*)C);
*root_ir = (IR*)(A);
}

%type autoinc {IR*}
autoinc(A) ::= .          {
A = new IR(kAutoinc, OP0());
*root_ir = (IR*)(A);
}

autoinc(A) ::= AUTOINCR .  {
A = new IR(kAutoinc, OP3("AUTOINCR", "", ""));
*root_ir = (IR*)(A);
}

%type refargs {IR*}
refargs(A) ::= .                  {
A = new IR(kRefargs, OP0());
*root_ir = (IR*)(A);
}

refargs(A) ::= refargs(B) refarg(C) . {
A = new IR(kRefargs, OP3("", "", ""), (IR*)B, (IR*)C);
*root_ir = (IR*)(A);
}

%type refarg {IR*}
refarg(A) ::= MATCH nm(C) .              {
A = new IR(kRefarg, OP3("MATCH", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

refarg(A) ::= ON INSERT refact(D) .      {
A = new IR(kRefarg, OP3("ON INSERT", "", ""), (IR*)D);
*root_ir = (IR*)(A);
}

refarg(A) ::= ON DELETE refact(D) .   {
A = new IR(kRefarg, OP3("ON DELETE", "", ""), (IR*)D);
*root_ir = (IR*)(A);
}

refarg(A) ::= ON UPDATE refact(D) .   {
A = new IR(kRefarg, OP3("ON UPDATE", "", ""), (IR*)D);
*root_ir = (IR*)(A);
}

%type refact {IR*}
refact(A) ::= SET NULL .              {
A = new IR(kRefact, OP3("SET NULL", "", ""));
*root_ir = (IR*)(A);
}

refact(A) ::= SET DEFAULT .           {
A = new IR(kRefact, OP3("SET DEFAULT", "", ""));
*root_ir = (IR*)(A);
}

refact(A) ::= CASCADE .               {
A = new IR(kRefact, OP3("CASCADE", "", ""));
*root_ir = (IR*)(A);
}

refact(A) ::= RESTRICT .              {
A = new IR(kRefact, OP3("RESTRICT", "", ""));
*root_ir = (IR*)(A);
}

refact(A) ::= NO ACTION .             {
A = new IR(kRefact, OP3("NO ACTION", "", ""));
*root_ir = (IR*)(A);
}

%type defer_subclause {IR*}
defer_subclause(A) ::= NOT DEFERRABLE init_deferred_pred_opt(D) .     {
A = new IR(kDeferSubclause, OP3("NOT DEFERRABLE", "", ""), (IR*)D);
*root_ir = (IR*)(A);
}

defer_subclause(A) ::= DEFERRABLE init_deferred_pred_opt(C) .      {
A = new IR(kDeferSubclause, OP3("DEFERRABLE", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

%type init_deferred_pred_opt {IR*}
init_deferred_pred_opt(A) ::= .                       {
A = new IR(kInitDeferredPredOpt, OP0());
*root_ir = (IR*)(A);
}

init_deferred_pred_opt(A) ::= INITIALLY DEFERRED .     {
A = new IR(kInitDeferredPredOpt, OP3("INITIALLY DEFERRED", "", ""));
*root_ir = (IR*)(A);
}

init_deferred_pred_opt(A) ::= INITIALLY IMMEDIATE .    {
A = new IR(kInitDeferredPredOpt, OP3("INITIALLY IMMEDIATE", "", ""));
*root_ir = (IR*)(A);
}

conslist_opt(A) ::= .                         {
A = new IR(kConslistOpt, OP0());
*root_ir = (IR*)(A);
}

conslist_opt(A) ::= COMMA conslist(C) . {
A = new IR(kConslistOpt, OP3("COMMA", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

conslist(A) ::= conslist(B) tconscomma(C) tcons(D) . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
A = new IR(kConslist, OP3("", "", ""), (IR*)A, (IR*)D);
*root_ir = (IR*)(A);
}

conslist(A) ::= tcons(B) . {
A = new IR(kConslist, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

tconscomma(A) ::= COMMA .            {
A = new IR(kTconscomma, OP3("COMMA", "", ""));
*root_ir = (IR*)(A);
}

tconscomma(A) ::= . {
A = new IR(kTconscomma, OP0());
*root_ir = (IR*)(A);
}

tcons(A) ::= CONSTRAINT nm(C) .      {
A = new IR(kTcons, OP3("CONSTRAINT", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

tcons(A) ::= PRIMARY KEY LP sortlist(E) autoinc(F) RP onconf(H) . {
A = new IR(kUnknown, OP3("PRIMARY KEY LP", "", "RP"), (IR*)E, (IR*)F);
A = new IR(kTcons, OP3("", "", ""), (IR*)A, (IR*)H);
*root_ir = (IR*)(A);
}

tcons(A) ::= UNIQUE LP sortlist(D) RP onconf(F) . {
A = new IR(kTcons, OP3("UNIQUE LP", "RP", ""), (IR*)D, (IR*)F);
*root_ir = (IR*)(A);
}

tcons(A) ::= CHECK LP expr(D) RP onconf(F) . {
A = new IR(kTcons, OP3("CHECK LP", "RP", ""), (IR*)D, (IR*)F);
*root_ir = (IR*)(A);
}

tcons(A) ::= FOREIGN KEY LP eidlist(E) RP REFERENCES nm(H) eidlist_opt(I) refargs(J) defer_subclause_opt(K) . {
A = new IR(kUnknown, OP3("FOREIGN KEY LP", "RP REFERENCES", ""), (IR*)E, (IR*)H);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)I);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)J);
A = new IR(kTcons, OP3("", "", ""), (IR*)A, (IR*)K);
*root_ir = (IR*)(A);
}

%type defer_subclause_opt {IR*}
defer_subclause_opt(A) ::= .                    {
A = new IR(kDeferSubclauseOpt, OP0());
*root_ir = (IR*)(A);
}

defer_subclause_opt(A) ::= defer_subclause(B) . {
A = new IR(kDeferSubclauseOpt, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

%type onconf {IR*}
%type orconf {IR*}
%type resolvetype {IR*}
onconf(A) ::= .                              {
A = new IR(kOnconf, OP0());
*root_ir = (IR*)(A);
}

onconf(A) ::= ON CONFLICT resolvetype(D) .    {
A = new IR(kOnconf, OP3("ON CONFLICT", "", ""), (IR*)D);
*root_ir = (IR*)(A);
}

orconf(A) ::= .                              {
A = new IR(kOrconf, OP0());
*root_ir = (IR*)(A);
}

orconf(A) ::= OR resolvetype(C) .             {
A = new IR(kOrconf, OP3("OR", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

resolvetype(A) ::= raisetype(B) . {
A = new IR(kResolvetype, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

resolvetype(A) ::= IGNORE .                   {
A = new IR(kResolvetype, OP3("IGNORE", "", ""));
*root_ir = (IR*)(A);
}

resolvetype(A) ::= REPLACE .                  {
A = new IR(kResolvetype, OP3("REPLACE", "", ""));
*root_ir = (IR*)(A);
}

cmd(A) ::= DROP TABLE ifexists(D) fullname(E) . {
A = new IR(kCmd, OP3("DROP TABLE", "", ""), (IR*)D, (IR*)E);
*root_ir = (IR*)(A);
}

%type ifexists {IR*}
ifexists(A) ::= IF EXISTS .   {
A = new IR(kIfexists, OP3("IF EXISTS", "", ""));
*root_ir = (IR*)(A);
}

ifexists(A) ::= .            {
A = new IR(kIfexists, OP0());
*root_ir = (IR*)(A);
}

cmd(A) ::= createkw(B) temp(C) VIEW ifnotexists(E) nm(F) dbnm(G) eidlist_opt(H) AS select(J) . {
A = new IR(kUnknown, OP3("", "", "VIEW"), (IR*)B, (IR*)C);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)G);
A = new IR(kUnknown, OP3("", "", "AS"), (IR*)A, (IR*)H);
A = new IR(kCmd, OP3("", "", ""), (IR*)A, (IR*)J);
*root_ir = (IR*)(A);
}

cmd(A) ::= DROP VIEW ifexists(D) fullname(E) . {
A = new IR(kCmd, OP3("DROP VIEW", "", ""), (IR*)D, (IR*)E);
*root_ir = (IR*)(A);
}

cmd(A) ::= select(B) .  {
A = new IR(kCmd, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

%type select {IR*}
%type selectnowith {IR*}
%type oneselect {IR*}
select(A) ::= WITH wqlist(C) selectnowith(D) . {
A = new IR(kSelect, OP3("WITH", "", ""), (IR*)C, (IR*)D);
*root_ir = (IR*)(A);
}

select(A) ::= WITH RECURSIVE wqlist(D) selectnowith(E) . {
A = new IR(kSelect, OP3("WITH RECURSIVE", "", ""), (IR*)D, (IR*)E);
*root_ir = (IR*)(A);
}

select(A) ::= selectnowith(B) . {
A = new IR(kSelect, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

selectnowith(A) ::= oneselect(B) . {
A = new IR(kSelectnowith, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

selectnowith(A) ::= selectnowith(B) multiselect_op(C) oneselect(D) .  {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
A = new IR(kSelectnowith, OP3("", "", ""), (IR*)A, (IR*)D);
*root_ir = (IR*)(A);
}

%type multiselect_op {IR*}
multiselect_op(A) ::= UNION .             {
A = new IR(kMultiselectOp, OP3("UNION", "", ""));
*root_ir = (IR*)(A);
}

multiselect_op(A) ::= UNION ALL .             {
A = new IR(kMultiselectOp, OP3("UNION ALL", "", ""));
*root_ir = (IR*)(A);
}

multiselect_op(A) ::= EXCEPT|INTERSECT .  {
A = new IR(kMultiselectOp, OP3("EXCEPT|INTERSECT", "", ""));
*root_ir = (IR*)(A);
}

oneselect(A) ::= SELECT distinct(C) selcollist(D) from(E) where_opt(F) groupby_opt(G) having_opt(H) orderby_opt(I) limit_opt(J) . {
A = new IR(kUnknown, OP3("SELECT", "", ""), (IR*)C, (IR*)D);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)G);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)H);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)I);
A = new IR(kOneselect, OP3("", "", ""), (IR*)A, (IR*)J);
*root_ir = (IR*)(A);
}

oneselect(A) ::= SELECT distinct(C) selcollist(D) from(E) where_opt(F) groupby_opt(G) having_opt(H) window_clause(I) orderby_opt(J) limit_opt(K) . {
A = new IR(kUnknown, OP3("SELECT", "", ""), (IR*)C, (IR*)D);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)G);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)H);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)I);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)J);
A = new IR(kOneselect, OP3("", "", ""), (IR*)A, (IR*)K);
*root_ir = (IR*)(A);
}

oneselect(A) ::= values(B) . {
A = new IR(kOneselect, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

%type values {IR*}
values(A) ::= VALUES LP nexprlist(D) RP . {
A = new IR(kValues, OP3("VALUES LP", "RP", ""), (IR*)D);
*root_ir = (IR*)(A);
}

values(A) ::= values(B) COMMA LP nexprlist(E) RP . {
A = new IR(kValues, OP3("", "COMMA LP", "RP"), (IR*)B, (IR*)E);
*root_ir = (IR*)(A);
}

%type distinct {IR*}
distinct(A) ::= DISTINCT .   {
A = new IR(kDistinct, OP3("DISTINCT", "", ""));
*root_ir = (IR*)(A);
}

distinct(A) ::= ALL .        {
A = new IR(kDistinct, OP3("ALL", "", ""));
*root_ir = (IR*)(A);
}

distinct(A) ::= .           {
A = new IR(kDistinct, OP0());
*root_ir = (IR*)(A);
}

%type selcollist {IR*}
%type sclp {IR*}
sclp(A) ::= selcollist(B) COMMA . {
A = new IR(kSclp, OP3("", "COMMA", ""), (IR*)B);
*root_ir = (IR*)(A);
}

sclp(A) ::= .                                {
A = new IR(kSclp, OP0());
*root_ir = (IR*)(A);
}

selcollist(A) ::= sclp(B) scanpt(C) expr(D) scanpt(E) as(F) .     {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)D);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
A = new IR(kSelcollist, OP3("", "", ""), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

selcollist(A) ::= sclp(B) scanpt(C) STAR . {
A = new IR(kSelcollist, OP3("", "", "STAR"), (IR*)B, (IR*)C);
*root_ir = (IR*)(A);
}

selcollist(A) ::= sclp(B) scanpt(C) nm(D) DOT STAR . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
A = new IR(kSelcollist, OP3("", "", "DOT STAR"), (IR*)A, (IR*)D);
*root_ir = (IR*)(A);
}

%type as {IR*}
as(A) ::= AS nm(C) .    {
A = new IR(kAs, OP3("AS", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

as(A) ::= ids . {
A = new IR(kAs, OP3("IDS", "", ""));
*root_ir = (IR*)(A);
}

as(A) ::= .            {
A = new IR(kAs, OP0());
*root_ir = (IR*)(A);
}

%type seltablist {IR*}
%type stl_prefix {IR*}
%type from {IR*}
from(A) ::= .                {
A = new IR(kFrom, OP0());
*root_ir = (IR*)(A);
}

from(A) ::= FROM seltablist(C) . {
A = new IR(kFrom, OP3("FROM", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

stl_prefix(A) ::= seltablist(B) joinop(C) .    {
A = new IR(kStlPrefix, OP3("", "", ""), (IR*)B, (IR*)C);
*root_ir = (IR*)(A);
}

stl_prefix(A) ::= .                           {
A = new IR(kStlPrefix, OP0());
*root_ir = (IR*)(A);
}

seltablist(A) ::= stl_prefix(B) nm(C) dbnm(D) as(E) on_using(F) . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)D);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
A = new IR(kSeltablist, OP3("", "", ""), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

seltablist(A) ::= stl_prefix(B) nm(C) dbnm(D) as(E) indexed_by(F) on_using(G) . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)D);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
A = new IR(kSeltablist, OP3("", "", ""), (IR*)A, (IR*)G);
*root_ir = (IR*)(A);
}

seltablist(A) ::= stl_prefix(B) nm(C) dbnm(D) LP exprlist(F) RP as(H) on_using(I) . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
A = new IR(kUnknown, OP3("", "", "LP"), (IR*)A, (IR*)D);
A = new IR(kUnknown, OP3("", "", "RP"), (IR*)A, (IR*)F);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)H);
A = new IR(kSeltablist, OP3("", "", ""), (IR*)A, (IR*)I);
*root_ir = (IR*)(A);
}

seltablist(A) ::= stl_prefix(B) LP select(D) RP as(F) on_using(G) . {
A = new IR(kUnknown, OP3("", "LP", "RP"), (IR*)B, (IR*)D);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
A = new IR(kSeltablist, OP3("", "", ""), (IR*)A, (IR*)G);
*root_ir = (IR*)(A);
}

seltablist(A) ::= stl_prefix(B) LP seltablist(D) RP as(F) on_using(G) . {
A = new IR(kUnknown, OP3("", "LP", "RP"), (IR*)B, (IR*)D);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
A = new IR(kSeltablist, OP3("", "", ""), (IR*)A, (IR*)G);
*root_ir = (IR*)(A);
}

%type dbnm {IR*}
dbnm(A) ::= .          {
A = new IR(kDbnm, OP0());
*root_ir = (IR*)(A);
}

dbnm(A) ::= DOT nm(C) . {
A = new IR(kDbnm, OP3("DOT", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

%type fullname {IR*}
fullname(A) ::= nm(B) .  {
A = new IR(kFullname, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

fullname(A) ::= nm(B) DOT nm(D) . {
A = new IR(kFullname, OP3("", "DOT", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

%type xfullname {IR*}
xfullname(A) ::= nm(B) .  {
A = new IR(kXfullname, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

xfullname(A) ::= nm(B) DOT nm(D) .  {
A = new IR(kXfullname, OP3("", "DOT", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

xfullname(A) ::= nm(B) DOT nm(D) AS nm(F) .  {
A = new IR(kUnknown, OP3("", "DOT", "AS"), (IR*)B, (IR*)D);
A = new IR(kXfullname, OP3("", "", ""), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

xfullname(A) ::= nm(B) AS nm(D) . {
A = new IR(kXfullname, OP3("", "AS", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

%type joinop {IR*}
joinop(A) ::= COMMA|JOIN .              {
A = new IR(kJoinop, OP3("COMMA|JOIN", "", ""));
*root_ir = (IR*)(A);
}

joinop(A) ::= JOIN_KW JOIN . {
A = new IR(kJoinop, OP3("JOIN_KW JOIN", "", ""));
*root_ir = (IR*)(A);
}

joinop(A) ::= JOIN_KW nm(C) JOIN . {
A = new IR(kJoinop, OP3("JOIN_KW", "JOIN", ""), (IR*)C);
*root_ir = (IR*)(A);
}

joinop(A) ::= JOIN_KW nm(C) nm(D) JOIN . {
A = new IR(kJoinop, OP3("JOIN_KW", "", "JOIN"), (IR*)C, (IR*)D);
*root_ir = (IR*)(A);
}

%type on_using {IR*}
on_using(A) ::= ON expr(C) .            {
A = new IR(kOnUsing, OP3("ON", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

on_using(A) ::= USING LP idlist(D) RP . {
A = new IR(kOnUsing, OP3("USING LP", "RP", ""), (IR*)D);
*root_ir = (IR*)(A);
}

on_using(A) ::= .                  [OR]{
A = new IR(kOnUsing, OP0());
*root_ir = (IR*)(A);
}

%type indexed_opt {IR*}
%type indexed_by  {IR*}
indexed_opt(A) ::= .                 {
A = new IR(kIndexedOpt, OP0());
*root_ir = (IR*)(A);
}

indexed_opt(A) ::= indexed_by(B) . {
A = new IR(kIndexedOpt, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

indexed_by(A) ::= INDEXED BY nm(D) . {
A = new IR(kIndexedBy, OP3("INDEXED BY", "", ""), (IR*)D);
*root_ir = (IR*)(A);
}

indexed_by(A) ::= NOT INDEXED .      {
A = new IR(kIndexedBy, OP3("NOT INDEXED", "", ""));
*root_ir = (IR*)(A);
}

%type orderby_opt {IR*}
%type sortlist {IR*}
orderby_opt(A) ::= .                          {
A = new IR(kOrderbyOpt, OP0());
*root_ir = (IR*)(A);
}

orderby_opt(A) ::= ORDER BY sortlist(D) .      {
A = new IR(kOrderbyOpt, OP3("ORDER BY", "", ""), (IR*)D);
*root_ir = (IR*)(A);
}

sortlist(A) ::= sortlist(B) COMMA expr(D) sortorder(E) nulls(F) . {
A = new IR(kUnknown, OP3("", "COMMA", ""), (IR*)B, (IR*)D);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
A = new IR(kSortlist, OP3("", "", ""), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

sortlist(A) ::= expr(B) sortorder(C) nulls(D) . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
A = new IR(kSortlist, OP3("", "", ""), (IR*)A, (IR*)D);
*root_ir = (IR*)(A);
}

%type sortorder {IR*}
sortorder(A) ::= ASC .           {
A = new IR(kSortorder, OP3("ASC", "", ""));
*root_ir = (IR*)(A);
}

sortorder(A) ::= DESC .          {
A = new IR(kSortorder, OP3("DESC", "", ""));
*root_ir = (IR*)(A);
}

sortorder(A) ::= .              {
A = new IR(kSortorder, OP0());
*root_ir = (IR*)(A);
}

%type nulls {IR*}
nulls(A) ::= NULLS FIRST .       {
A = new IR(kNulls, OP3("NULLS FIRST", "", ""));
*root_ir = (IR*)(A);
}

nulls(A) ::= NULLS LAST .        {
A = new IR(kNulls, OP3("NULLS LAST", "", ""));
*root_ir = (IR*)(A);
}

nulls(A) ::= .                  {
A = new IR(kNulls, OP0());
*root_ir = (IR*)(A);
}

%type groupby_opt {IR*}
groupby_opt(A) ::= .                      {
A = new IR(kGroupbyOpt, OP0());
*root_ir = (IR*)(A);
}

groupby_opt(A) ::= GROUP BY nexprlist(D) . {
A = new IR(kGroupbyOpt, OP3("GROUP BY", "", ""), (IR*)D);
*root_ir = (IR*)(A);
}

%type having_opt {IR*}
having_opt(A) ::= .                {
A = new IR(kHavingOpt, OP0());
*root_ir = (IR*)(A);
}

having_opt(A) ::= HAVING expr(C) .  {
A = new IR(kHavingOpt, OP3("HAVING", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

%type limit_opt {IR*}
limit_opt(A) ::= .       {
A = new IR(kLimitOpt, OP0());
*root_ir = (IR*)(A);
}

limit_opt(A) ::= LIMIT expr(C) . {
A = new IR(kLimitOpt, OP3("LIMIT", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

limit_opt(A) ::= LIMIT expr(C) OFFSET expr(E) . {
A = new IR(kLimitOpt, OP3("LIMIT", "OFFSET", ""), (IR*)C, (IR*)E);
*root_ir = (IR*)(A);
}

limit_opt(A) ::= LIMIT expr(C) COMMA expr(E) . {
A = new IR(kLimitOpt, OP3("LIMIT", "COMMA", ""), (IR*)C, (IR*)E);
*root_ir = (IR*)(A);
}

cmd(A) ::= with(B) DELETE FROM xfullname(E) indexed_opt(F) where_opt_ret(G) orderby_opt(H) limit_opt(I) . {
A = new IR(kUnknown, OP3("", "DELETE FROM", ""), (IR*)B, (IR*)E);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)G);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)H);
A = new IR(kCmd, OP3("", "", ""), (IR*)A, (IR*)I);
*root_ir = (IR*)(A);
}

%type where_opt {IR*}
%type where_opt_ret {IR*}
where_opt(A) ::= .                    {
A = new IR(kWhereOpt, OP0());
*root_ir = (IR*)(A);
}

where_opt(A) ::= WHERE expr(C) .       {
A = new IR(kWhereOpt, OP3("WHERE", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

where_opt_ret(A) ::= .                                      {
A = new IR(kWhereOptRet, OP0());
*root_ir = (IR*)(A);
}

where_opt_ret(A) ::= WHERE expr(C) .                         {
A = new IR(kWhereOptRet, OP3("WHERE", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

where_opt_ret(A) ::= RETURNING selcollist(C) .               {
A = new IR(kWhereOptRet, OP3("RETURNING", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

where_opt_ret(A) ::= WHERE expr(C) RETURNING selcollist(E) . {
A = new IR(kWhereOptRet, OP3("WHERE", "RETURNING", ""), (IR*)C, (IR*)E);
*root_ir = (IR*)(A);
}

cmd(A) ::= with(B) UPDATE orconf(D) xfullname(E) indexed_opt(F) SET setlist(H) from(I) where_opt_ret(J) orderby_opt(K) limit_opt(L) .  {
A = new IR(kUnknown, OP3("", "UPDATE", ""), (IR*)B, (IR*)D);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
A = new IR(kUnknown, OP3("", "", "SET"), (IR*)A, (IR*)F);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)H);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)I);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)J);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)K);
A = new IR(kCmd, OP3("", "", ""), (IR*)A, (IR*)L);
*root_ir = (IR*)(A);
}

%type setlist {IR*}
setlist(A) ::= setlist(B) COMMA nm(D) EQ expr(F) . {
A = new IR(kUnknown, OP3("", "COMMA", "EQ"), (IR*)B, (IR*)D);
A = new IR(kSetlist, OP3("", "", ""), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

setlist(A) ::= setlist(B) COMMA LP idlist(E) RP EQ expr(H) . {
A = new IR(kUnknown, OP3("", "COMMA LP", "RP EQ"), (IR*)B, (IR*)E);
A = new IR(kSetlist, OP3("", "", ""), (IR*)A, (IR*)H);
*root_ir = (IR*)(A);
}

setlist(A) ::= nm(B) EQ expr(D) . {
A = new IR(kSetlist, OP3("", "EQ", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

setlist(A) ::= LP idlist(C) RP EQ expr(F) . {
A = new IR(kSetlist, OP3("LP", "RP EQ", ""), (IR*)C, (IR*)F);
*root_ir = (IR*)(A);
}

cmd(A) ::= with(B) insert_cmd(C) INTO xfullname(E) idlist_opt(F) select(G) upsert(H) . {
A = new IR(kUnknown, OP3("", "", "INTO"), (IR*)B, (IR*)C);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)G);
A = new IR(kCmd, OP3("", "", ""), (IR*)A, (IR*)H);
*root_ir = (IR*)(A);
}

cmd(A) ::= with(B) insert_cmd(C) INTO xfullname(E) idlist_opt(F) DEFAULT VALUES returning(I) . {
A = new IR(kUnknown, OP3("", "", "INTO"), (IR*)B, (IR*)C);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
A = new IR(kUnknown, OP3("", "", "DEFAULT VALUES"), (IR*)A, (IR*)F);
A = new IR(kCmd, OP3("", "", ""), (IR*)A, (IR*)I);
*root_ir = (IR*)(A);
}

%type upsert {IR*}
upsert(A) ::= . {
A = new IR(kUpsert, OP0());
*root_ir = (IR*)(A);
}

upsert(A) ::= RETURNING selcollist(C) .  {
A = new IR(kUpsert, OP3("RETURNING", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

upsert(A) ::= ON CONFLICT LP sortlist(E) RP where_opt(G) DO UPDATE SET setlist(K) where_opt(L) upsert(M) . {
A = new IR(kUnknown, OP3("ON CONFLICT LP", "RP", "DO UPDATE SET"), (IR*)E, (IR*)G);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)K);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)L);
A = new IR(kUpsert, OP3("", "", ""), (IR*)A, (IR*)M);
*root_ir = (IR*)(A);
}

upsert(A) ::= ON CONFLICT LP sortlist(E) RP where_opt(G) DO NOTHING upsert(J) . {
A = new IR(kUnknown, OP3("ON CONFLICT LP", "RP", "DO NOTHING"), (IR*)E, (IR*)G);
A = new IR(kUpsert, OP3("", "", ""), (IR*)A, (IR*)J);
*root_ir = (IR*)(A);
}

upsert(A) ::= ON CONFLICT DO NOTHING returning(F) . {
A = new IR(kUpsert, OP3("ON CONFLICT DO NOTHING", "", ""), (IR*)F);
*root_ir = (IR*)(A);
}

upsert(A) ::= ON CONFLICT DO UPDATE SET setlist(G) where_opt(H) returning(I) . {
A = new IR(kUnknown, OP3("ON CONFLICT DO UPDATE SET", "", ""), (IR*)G, (IR*)H);
A = new IR(kUpsert, OP3("", "", ""), (IR*)A, (IR*)I);
*root_ir = (IR*)(A);
}

returning(A) ::= RETURNING selcollist(C) .  {
A = new IR(kReturning, OP3("RETURNING", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

returning(A) ::= . {
A = new IR(kReturning, OP0());
*root_ir = (IR*)(A);
}

%type insert_cmd {IR*}
insert_cmd(A) ::= INSERT orconf(C) .   {
A = new IR(kInsertCmd, OP3("INSERT", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

insert_cmd(A) ::= REPLACE .            {
A = new IR(kInsertCmd, OP3("REPLACE", "", ""));
*root_ir = (IR*)(A);
}

%type idlist_opt {IR*}
%type idlist {IR*}
idlist_opt(A) ::= .                       {
A = new IR(kIdlistOpt, OP0());
*root_ir = (IR*)(A);
}

idlist_opt(A) ::= LP idlist(C) RP .    {
A = new IR(kIdlistOpt, OP3("LP", "RP", ""), (IR*)C);
*root_ir = (IR*)(A);
}

idlist(A) ::= idlist(B) COMMA nm(D) . {
A = new IR(kIdlist, OP3("", "COMMA", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

idlist(A) ::= nm(B) . {
A = new IR(kIdlist, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

%type expr {IR*}
%type term {IR*}
expr(A) ::= term(B) . {
A = new IR(kExpr, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

expr(A) ::= LP expr(C) RP . {
A = new IR(kExpr, OP3("LP", "RP", ""), (IR*)C);
*root_ir = (IR*)(A);
}

expr(A) ::= id .          {
A = new IR(kExpr, OP3("ID", "", ""));
*root_ir = (IR*)(A);
}

expr(A) ::= JOIN_KW .     {
A = new IR(kExpr, OP3("JOIN_KW", "", ""));
*root_ir = (IR*)(A);
}

expr(A) ::= nm(B) DOT nm(D) . {
A = new IR(kExpr, OP3("", "DOT", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

expr(A) ::= nm(B) DOT nm(D) DOT nm(F) . {
A = new IR(kUnknown, OP3("", "DOT", "DOT"), (IR*)B, (IR*)D);
A = new IR(kExpr, OP3("", "", ""), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

term(A) ::= NULL|FLOAT|BLOB . {
A = new IR(kTerm, OP3("NULL|FLOAT|BLOB", "", ""));
*root_ir = (IR*)(A);
}

term(A) ::= STRING .          {
A = new IR(kTerm, OP3("STRING", "", ""));
*root_ir = (IR*)(A);
}

term(A) ::= INTEGER . {
A = new IR(kTerm, OP3("INTEGER", "", ""));
*root_ir = (IR*)(A);
}

expr(A) ::= VARIABLE .     {
A = new IR(kExpr, OP3("VARIABLE", "", ""));
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) COLLATE ids . {
A = new IR(kExpr, OP3("", "COLLATE IDS", ""), (IR*)B);
*root_ir = (IR*)(A);
}

expr(A) ::= CAST LP expr(D) AS typetoken(F) RP . {
A = new IR(kExpr, OP3("CAST LP", "AS", "RP"), (IR*)D, (IR*)F);
*root_ir = (IR*)(A);
}

expr(A) ::= id LP distinct(D) exprlist(E) RP . {
A = new IR(kExpr, OP3("ID LP", "", "RP"), (IR*)D, (IR*)E);
*root_ir = (IR*)(A);
}

expr(A) ::= id LP STAR RP . {
A = new IR(kExpr, OP3("ID LP STAR RP", "", ""));
*root_ir = (IR*)(A);
}

expr(A) ::= id LP distinct(D) exprlist(E) RP filter_over(G) . {
A = new IR(kUnknown, OP3("ID LP", "", "RP"), (IR*)D, (IR*)E);
A = new IR(kExpr, OP3("", "", ""), (IR*)A, (IR*)G);
*root_ir = (IR*)(A);
}

expr(A) ::= id LP STAR RP filter_over(F) . {
A = new IR(kExpr, OP3("ID LP STAR RP", "", ""), (IR*)F);
*root_ir = (IR*)(A);
}

term(A) ::= CTIME_KW . {
A = new IR(kTerm, OP3("CTIME_KW", "", ""));
*root_ir = (IR*)(A);
}

expr(A) ::= LP nexprlist(C) COMMA expr(E) RP . {
A = new IR(kExpr, OP3("LP", "COMMA", "RP"), (IR*)C, (IR*)E);
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) AND expr(D) .        {
A = new IR(kExpr, OP3("", "AND", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) OR expr(D) .     {
A = new IR(kExpr, OP3("", "OR", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) LT|GT|GE|LE expr(D) . {
A = new IR(kExpr, OP3("", "LT|GT|GE|LE", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) EQ|NE expr(D) .  {
A = new IR(kExpr, OP3("", "EQ|NE", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) BITAND|BITOR|LSHIFT|RSHIFT expr(D) . {
A = new IR(kExpr, OP3("", "BITAND|BITOR|LSHIFT|RSHIFT", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) PLUS|MINUS expr(D) . {
A = new IR(kExpr, OP3("", "PLUS|MINUS", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) STAR|SLASH|REM expr(D) . {
A = new IR(kExpr, OP3("", "STAR|SLASH|REM", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) CONCAT expr(D) . {
A = new IR(kExpr, OP3("", "CONCAT", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

%type likeop {IR*}
likeop(A) ::= LIKE_KW|MATCH . {
A = new IR(kLikeop, OP3("LIKE_KW|MATCH", "", ""));
*root_ir = (IR*)(A);
}

likeop(A) ::= NOT LIKE_KW|MATCH . {
A = new IR(kLikeop, OP3("NOT LIKE_KW|MATCH", "", ""));
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) likeop(C) expr(D) .   [LIKE_KW] {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
A = new IR(kExpr, OP3("", "", ""), (IR*)A, (IR*)D);
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) likeop(C) expr(D) ESCAPE expr(F) .   [LIKE_KW] {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
A = new IR(kUnknown, OP3("", "", "ESCAPE"), (IR*)A, (IR*)D);
A = new IR(kExpr, OP3("", "", ""), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) ISNULL|NOTNULL .   {
A = new IR(kExpr, OP3("", "ISNULL|NOTNULL", ""), (IR*)B);
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) NOT NULL .    {
A = new IR(kExpr, OP3("", "NOT NULL", ""), (IR*)B);
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) IS expr(D) .     {
A = new IR(kExpr, OP3("", "IS", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) IS NOT expr(E) . {
A = new IR(kExpr, OP3("", "IS NOT", ""), (IR*)B, (IR*)E);
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) IS NOT DISTINCT FROM expr(G) .     {
A = new IR(kExpr, OP3("", "IS NOT DISTINCT FROM", ""), (IR*)B, (IR*)G);
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) IS DISTINCT FROM expr(F) . {
A = new IR(kExpr, OP3("", "IS DISTINCT FROM", ""), (IR*)B, (IR*)F);
*root_ir = (IR*)(A);
}

expr(A) ::= NOT expr(C) .  {
A = new IR(kExpr, OP3("NOT", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

expr(A) ::= BITNOT expr(C) . {
A = new IR(kExpr, OP3("BITNOT", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

expr(A) ::= PLUS|MINUS expr(C) .  [BITNOT]{
A = new IR(kExpr, OP3("PLUS|MINUS", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) PTR expr(D) . {
A = new IR(kExpr, OP3("", "PTR", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

%type between_op {IR*}
between_op(A) ::= BETWEEN .     {
A = new IR(kBetweenOp, OP3("BETWEEN", "", ""));
*root_ir = (IR*)(A);
}

between_op(A) ::= NOT BETWEEN . {
A = new IR(kBetweenOp, OP3("NOT BETWEEN", "", ""));
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) between_op(C) expr(D) AND expr(F) .  [BETWEEN]{
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
A = new IR(kUnknown, OP3("", "", "AND"), (IR*)A, (IR*)D);
A = new IR(kExpr, OP3("", "", ""), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

in_op(A) ::= IN .      {
A = new IR(kInOp, OP3("IN", "", ""));
*root_ir = (IR*)(A);
}

in_op(A) ::= NOT IN .  {
A = new IR(kInOp, OP3("NOT IN", "", ""));
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) in_op(C) LP exprlist(E) RP .  [IN]{
A = new IR(kUnknown, OP3("", "", "LP"), (IR*)B, (IR*)C);
A = new IR(kExpr, OP3("", "", "RP"), (IR*)A, (IR*)E);
*root_ir = (IR*)(A);
}

expr(A) ::= LP select(C) RP . {
A = new IR(kExpr, OP3("LP", "RP", ""), (IR*)C);
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) in_op(C) LP select(E) RP .   [IN]{
A = new IR(kUnknown, OP3("", "", "LP"), (IR*)B, (IR*)C);
A = new IR(kExpr, OP3("", "", "RP"), (IR*)A, (IR*)E);
*root_ir = (IR*)(A);
}

expr(A) ::= expr(B) in_op(C) nm(D) dbnm(E) paren_exprlist(F) .  [IN]{
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)D);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
A = new IR(kExpr, OP3("", "", ""), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

expr(A) ::= EXISTS LP select(D) RP . {
A = new IR(kExpr, OP3("EXISTS LP", "RP", ""), (IR*)D);
*root_ir = (IR*)(A);
}

expr(A) ::= CASE case_operand(C) case_exprlist(D) case_else(E) END . {
A = new IR(kUnknown, OP3("CASE", "", ""), (IR*)C, (IR*)D);
A = new IR(kExpr, OP3("", "", "END"), (IR*)A, (IR*)E);
*root_ir = (IR*)(A);
}

%type case_exprlist {IR*}
case_exprlist(A) ::= case_exprlist(B) WHEN expr(D) THEN expr(F) . {
A = new IR(kUnknown, OP3("", "WHEN", "THEN"), (IR*)B, (IR*)D);
A = new IR(kCaseExprlist, OP3("", "", ""), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

case_exprlist(A) ::= WHEN expr(C) THEN expr(E) . {
A = new IR(kCaseExprlist, OP3("WHEN", "THEN", ""), (IR*)C, (IR*)E);
*root_ir = (IR*)(A);
}

%type case_else {IR*}
case_else(A) ::= ELSE expr(C) .         {
A = new IR(kCaseElse, OP3("ELSE", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

case_else(A) ::= .                     {
A = new IR(kCaseElse, OP0());
*root_ir = (IR*)(A);
}

%type case_operand {IR*}
case_operand(A) ::= expr(B) .            {
A = new IR(kCaseOperand, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

case_operand(A) ::= .                   {
A = new IR(kCaseOperand, OP0());
*root_ir = (IR*)(A);
}

%type exprlist {IR*}
%type nexprlist {IR*}
exprlist(A) ::= nexprlist(B) . {
A = new IR(kExprlist, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

exprlist(A) ::= .                            {
A = new IR(kExprlist, OP0());
*root_ir = (IR*)(A);
}

nexprlist(A) ::= nexprlist(B) COMMA expr(D) . {
A = new IR(kNexprlist, OP3("", "COMMA", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

nexprlist(A) ::= expr(B) . {
A = new IR(kNexprlist, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

%type paren_exprlist {IR*}
paren_exprlist(A) ::= .   {
A = new IR(kParenExprlist, OP0());
*root_ir = (IR*)(A);
}

paren_exprlist(A) ::= LP exprlist(C) RP .  {
A = new IR(kParenExprlist, OP3("LP", "RP", ""), (IR*)C);
*root_ir = (IR*)(A);
}

cmd(A) ::= createkw(B) uniqueflag(C) INDEX ifnotexists(E) nm(F) dbnm(G) ON nm(I) LP sortlist(K) RP where_opt(M) . {
A = new IR(kUnknown, OP3("", "", "INDEX"), (IR*)B, (IR*)C);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
A = new IR(kUnknown, OP3("", "", "ON"), (IR*)A, (IR*)G);
A = new IR(kUnknown, OP3("", "", "LP"), (IR*)A, (IR*)I);
A = new IR(kUnknown, OP3("", "", "RP"), (IR*)A, (IR*)K);
A = new IR(kCmd, OP3("", "", ""), (IR*)A, (IR*)M);
*root_ir = (IR*)(A);
}

%type uniqueflag {IR*}
uniqueflag(A) ::= UNIQUE .  {
A = new IR(kUniqueflag, OP3("UNIQUE", "", ""));
*root_ir = (IR*)(A);
}

uniqueflag(A) ::= .        {
A = new IR(kUniqueflag, OP0());
*root_ir = (IR*)(A);
}

%type eidlist {IR*}
%type eidlist_opt {IR*}
eidlist_opt(A) ::= .                         {
A = new IR(kEidlistOpt, OP0());
*root_ir = (IR*)(A);
}

eidlist_opt(A) ::= LP eidlist(C) RP .         {
A = new IR(kEidlistOpt, OP3("LP", "RP", ""), (IR*)C);
*root_ir = (IR*)(A);
}

eidlist(A) ::= eidlist(B) COMMA nm(D) collate(E) sortorder(F) .  {
A = new IR(kUnknown, OP3("", "COMMA", ""), (IR*)B, (IR*)D);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
A = new IR(kEidlist, OP3("", "", ""), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

eidlist(A) ::= nm(B) collate(C) sortorder(D) . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
A = new IR(kEidlist, OP3("", "", ""), (IR*)A, (IR*)D);
*root_ir = (IR*)(A);
}

%type collate {IR*}
collate(A) ::= .              {
A = new IR(kCollate, OP0());
*root_ir = (IR*)(A);
}

collate(A) ::= COLLATE ids .   {
A = new IR(kCollate, OP3("COLLATE IDS", "", ""));
*root_ir = (IR*)(A);
}

cmd(A) ::= DROP INDEX ifexists(D) fullname(E) .   {
A = new IR(kCmd, OP3("DROP INDEX", "", ""), (IR*)D, (IR*)E);
*root_ir = (IR*)(A);
}

%type vinto {IR*}
cmd(A) ::= VACUUM vinto(C) .                {
A = new IR(kCmd, OP3("VACUUM", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

cmd(A) ::= VACUUM nm(C) vinto(D) .          {
A = new IR(kCmd, OP3("VACUUM", "", ""), (IR*)C, (IR*)D);
*root_ir = (IR*)(A);
}

vinto(A) ::= INTO expr(C) .              {
A = new IR(kVinto, OP3("INTO", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

vinto(A) ::= .                          {
A = new IR(kVinto, OP0());
*root_ir = (IR*)(A);
}

cmd(A) ::= PRAGMA nm(C) dbnm(D) .                {
A = new IR(kCmd, OP3("PRAGMA", "", ""), (IR*)C, (IR*)D);
*root_ir = (IR*)(A);
}

cmd(A) ::= PRAGMA nm(C) dbnm(D) EQ nmnum(F) .    {
A = new IR(kUnknown, OP3("PRAGMA", "", "EQ"), (IR*)C, (IR*)D);
A = new IR(kCmd, OP3("", "", ""), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

cmd(A) ::= PRAGMA nm(C) dbnm(D) LP nmnum(F) RP . {
A = new IR(kUnknown, OP3("PRAGMA", "", "LP"), (IR*)C, (IR*)D);
A = new IR(kCmd, OP3("", "", "RP"), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

cmd(A) ::= PRAGMA nm(C) dbnm(D) EQ minus_num(F) . {
A = new IR(kUnknown, OP3("PRAGMA", "", "EQ"), (IR*)C, (IR*)D);
A = new IR(kCmd, OP3("", "", ""), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

cmd(A) ::= PRAGMA nm(C) dbnm(D) LP minus_num(F) RP . {
A = new IR(kUnknown, OP3("PRAGMA", "", "LP"), (IR*)C, (IR*)D);
A = new IR(kCmd, OP3("", "", "RP"), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

nmnum(A) ::= plus_num(B) . {
A = new IR(kNmnum, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

nmnum(A) ::= nm(B) . {
A = new IR(kNmnum, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

nmnum(A) ::= ON . {
A = new IR(kNmnum, OP3("ON", "", ""));
*root_ir = (IR*)(A);
}

nmnum(A) ::= DELETE . {
A = new IR(kNmnum, OP3("DELETE", "", ""));
*root_ir = (IR*)(A);
}

nmnum(A) ::= DEFAULT . {
A = new IR(kNmnum, OP3("DEFAULT", "", ""));
*root_ir = (IR*)(A);
}

%token_class number INTEGER|FLOAT.
plus_num(A) ::= PLUS number .       {
A = new IR(kPlusNum, OP3("PLUS NUMBER", "", ""));
*root_ir = (IR*)(A);
}

plus_num(A) ::= number . {
A = new IR(kPlusNum, OP3("NUMBER", "", ""));
*root_ir = (IR*)(A);
}

minus_num(A) ::= MINUS number .     {
A = new IR(kMinusNum, OP3("MINUS NUMBER", "", ""));
*root_ir = (IR*)(A);
}

cmd(A) ::= createkw(B) trigger_decl(C) BEGIN trigger_cmd_list(E) END . {
A = new IR(kUnknown, OP3("", "", "BEGIN"), (IR*)B, (IR*)C);
A = new IR(kCmd, OP3("", "", "END"), (IR*)A, (IR*)E);
*root_ir = (IR*)(A);
}

trigger_decl(A) ::= temp(B) TRIGGER ifnotexists(D) nm(E) dbnm(F) trigger_time(G) trigger_event(H) ON fullname(J) foreach_clause(K) when_clause(L) . {
A = new IR(kUnknown, OP3("", "TRIGGER", ""), (IR*)B, (IR*)D);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)G);
A = new IR(kUnknown, OP3("", "", "ON"), (IR*)A, (IR*)H);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)J);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)K);
A = new IR(kTriggerDecl, OP3("", "", ""), (IR*)A, (IR*)L);
*root_ir = (IR*)(A);
}

%type trigger_time {IR*}
trigger_time(A) ::= BEFORE|AFTER .  {
A = new IR(kTriggerTime, OP3("BEFORE|AFTER", "", ""));
*root_ir = (IR*)(A);
}

trigger_time(A) ::= INSTEAD OF .  {
A = new IR(kTriggerTime, OP3("INSTEAD OF", "", ""));
*root_ir = (IR*)(A);
}

trigger_time(A) ::= .            {
A = new IR(kTriggerTime, OP0());
*root_ir = (IR*)(A);
}

%type trigger_event {IR*}
trigger_event(A) ::= DELETE|INSERT .   {
A = new IR(kTriggerEvent, OP3("DELETE|INSERT", "", ""));
*root_ir = (IR*)(A);
}

trigger_event(A) ::= UPDATE .          {
A = new IR(kTriggerEvent, OP3("UPDATE", "", ""));
*root_ir = (IR*)(A);
}

trigger_event(A) ::= UPDATE OF idlist(D) . {
A = new IR(kTriggerEvent, OP3("UPDATE OF", "", ""), (IR*)D);
*root_ir = (IR*)(A);
}

foreach_clause(A) ::= . {
A = new IR(kForeachClause, OP0());
*root_ir = (IR*)(A);
}

foreach_clause(A) ::= FOR EACH ROW . {
A = new IR(kForeachClause, OP3("FOR EACH ROW", "", ""));
*root_ir = (IR*)(A);
}

%type when_clause {IR*}
when_clause(A) ::= .             {
A = new IR(kWhenClause, OP0());
*root_ir = (IR*)(A);
}

when_clause(A) ::= WHEN expr(C) . {
A = new IR(kWhenClause, OP3("WHEN", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

%type trigger_cmd_list {IR*}
trigger_cmd_list(A) ::= trigger_cmd_list(B) trigger_cmd(C) SEMI . {
A = new IR(kTriggerCmdList, OP3("", "", "SEMI"), (IR*)B, (IR*)C);
*root_ir = (IR*)(A);
}

trigger_cmd_list(A) ::= trigger_cmd(B) SEMI . {
A = new IR(kTriggerCmdList, OP3("", "SEMI", ""), (IR*)B);
*root_ir = (IR*)(A);
}

%type trnm {IR*}
trnm(A) ::= nm(B) . {
A = new IR(kTrnm, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

trnm(A) ::= nm(B) DOT nm(D) . {
A = new IR(kTrnm, OP3("", "DOT", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

tridxby(A) ::= . {
A = new IR(kTridxby, OP0());
*root_ir = (IR*)(A);
}

tridxby(A) ::= INDEXED BY nm(D) . {
A = new IR(kTridxby, OP3("INDEXED BY", "", ""), (IR*)D);
*root_ir = (IR*)(A);
}

tridxby(A) ::= NOT INDEXED . {
A = new IR(kTridxby, OP3("NOT INDEXED", "", ""));
*root_ir = (IR*)(A);
}

%type trigger_cmd {IR*}
trigger_cmd(A) ::= UPDATE orconf(C) trnm(D) tridxby(E) SET setlist(G) from(H) where_opt(I) scanpt(J) .  {
A = new IR(kUnknown, OP3("UPDATE", "", ""), (IR*)C, (IR*)D);
A = new IR(kUnknown, OP3("", "", "SET"), (IR*)A, (IR*)E);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)G);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)H);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)I);
A = new IR(kTriggerCmd, OP3("", "", ""), (IR*)A, (IR*)J);
*root_ir = (IR*)(A);
}

trigger_cmd(A) ::= scanpt(B) insert_cmd(C) INTO trnm(E) idlist_opt(F) select(G) upsert(H) scanpt(I) . {
A = new IR(kUnknown, OP3("", "", "INTO"), (IR*)B, (IR*)C);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)G);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)H);
A = new IR(kTriggerCmd, OP3("", "", ""), (IR*)A, (IR*)I);
*root_ir = (IR*)(A);
}

trigger_cmd(A) ::= DELETE FROM trnm(D) tridxby(E) where_opt(F) scanpt(G) . {
A = new IR(kUnknown, OP3("DELETE FROM", "", ""), (IR*)D, (IR*)E);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
A = new IR(kTriggerCmd, OP3("", "", ""), (IR*)A, (IR*)G);
*root_ir = (IR*)(A);
}

trigger_cmd(A) ::= scanpt(B) select(C) scanpt(D) . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
A = new IR(kTriggerCmd, OP3("", "", ""), (IR*)A, (IR*)D);
*root_ir = (IR*)(A);
}

expr(A) ::= RAISE LP IGNORE RP .  {
A = new IR(kExpr, OP3("RAISE LP IGNORE RP", "", ""));
*root_ir = (IR*)(A);
}

expr(A) ::= RAISE LP raisetype(D) COMMA nm(F) RP .  {
A = new IR(kExpr, OP3("RAISE LP", "COMMA", "RP"), (IR*)D, (IR*)F);
*root_ir = (IR*)(A);
}

%type raisetype {IR*}
raisetype(A) ::= ROLLBACK .  {
A = new IR(kRaisetype, OP3("ROLLBACK", "", ""));
*root_ir = (IR*)(A);
}

raisetype(A) ::= ABORT .     {
A = new IR(kRaisetype, OP3("ABORT", "", ""));
*root_ir = (IR*)(A);
}

raisetype(A) ::= FAIL .      {
A = new IR(kRaisetype, OP3("FAIL", "", ""));
*root_ir = (IR*)(A);
}

cmd(A) ::= DROP TRIGGER ifexists(D) fullname(E) . {
A = new IR(kCmd, OP3("DROP TRIGGER", "", ""), (IR*)D, (IR*)E);
*root_ir = (IR*)(A);
}

cmd(A) ::= ATTACH database_kw_opt(C) expr(D) AS expr(F) key_opt(G) . {
A = new IR(kUnknown, OP3("ATTACH", "", "AS"), (IR*)C, (IR*)D);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
A = new IR(kCmd, OP3("", "", ""), (IR*)A, (IR*)G);
*root_ir = (IR*)(A);
}

cmd(A) ::= DETACH database_kw_opt(C) expr(D) . {
A = new IR(kCmd, OP3("DETACH", "", ""), (IR*)C, (IR*)D);
*root_ir = (IR*)(A);
}

%type key_opt {IR*}
key_opt(A) ::= .                     {
A = new IR(kKeyOpt, OP0());
*root_ir = (IR*)(A);
}

key_opt(A) ::= KEY expr(C) .          {
A = new IR(kKeyOpt, OP3("KEY", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

database_kw_opt(A) ::= DATABASE . {
A = new IR(kDatabaseKwOpt, OP3("DATABASE", "", ""));
*root_ir = (IR*)(A);
}

database_kw_opt(A) ::= . {
A = new IR(kDatabaseKwOpt, OP0());
*root_ir = (IR*)(A);
}

cmd(A) ::= REINDEX .                {
A = new IR(kCmd, OP3("REINDEX", "", ""));
*root_ir = (IR*)(A);
}

cmd(A) ::= REINDEX nm(C) dbnm(D) .  {
A = new IR(kCmd, OP3("REINDEX", "", ""), (IR*)C, (IR*)D);
*root_ir = (IR*)(A);
}

cmd(A) ::= ANALYZE .                {
A = new IR(kCmd, OP3("ANALYZE", "", ""));
*root_ir = (IR*)(A);
}

cmd(A) ::= ANALYZE nm(C) dbnm(D) .  {
A = new IR(kCmd, OP3("ANALYZE", "", ""), (IR*)C, (IR*)D);
*root_ir = (IR*)(A);
}

cmd(A) ::= ALTER TABLE fullname(D) RENAME TO nm(G) . {
A = new IR(kCmd, OP3("ALTER TABLE", "RENAME TO", ""), (IR*)D, (IR*)G);
*root_ir = (IR*)(A);
}

cmd(A) ::= ALTER TABLE add_column_fullname(D) ADD kwcolumn_opt(F) columnname(G) carglist(H) . {
A = new IR(kUnknown, OP3("ALTER TABLE", "ADD", ""), (IR*)D, (IR*)F);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)G);
A = new IR(kCmd, OP3("", "", ""), (IR*)A, (IR*)H);
*root_ir = (IR*)(A);
}

cmd(A) ::= ALTER TABLE fullname(D) DROP kwcolumn_opt(F) nm(G) . {
A = new IR(kUnknown, OP3("ALTER TABLE", "DROP", ""), (IR*)D, (IR*)F);
A = new IR(kCmd, OP3("", "", ""), (IR*)A, (IR*)G);
*root_ir = (IR*)(A);
}

add_column_fullname(A) ::= fullname(B) . {
A = new IR(kAddColumnFullname, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

cmd(A) ::= ALTER TABLE fullname(D) RENAME kwcolumn_opt(F) nm(G) TO nm(I) . {
A = new IR(kUnknown, OP3("ALTER TABLE", "RENAME", ""), (IR*)D, (IR*)F);
A = new IR(kUnknown, OP3("", "", "TO"), (IR*)A, (IR*)G);
A = new IR(kCmd, OP3("", "", ""), (IR*)A, (IR*)I);
*root_ir = (IR*)(A);
}

kwcolumn_opt(A) ::= . {
A = new IR(kKwcolumnOpt, OP0());
*root_ir = (IR*)(A);
}

kwcolumn_opt(A) ::= COLUMNKW . {
A = new IR(kKwcolumnOpt, OP3("COLUMNKW", "", ""));
*root_ir = (IR*)(A);
}

cmd(A) ::= create_vtab(B) .                       {
A = new IR(kCmd, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

cmd(A) ::= create_vtab(B) LP vtabarglist(D) RP .  {
A = new IR(kCmd, OP3("", "LP", "RP"), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

create_vtab(A) ::= createkw(B) VIRTUAL TABLE ifnotexists(E) nm(F) dbnm(G) USING nm(I) . {
A = new IR(kUnknown, OP3("", "VIRTUAL TABLE", ""), (IR*)B, (IR*)E);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
A = new IR(kUnknown, OP3("", "", "USING"), (IR*)A, (IR*)G);
A = new IR(kCreateVtab, OP3("", "", ""), (IR*)A, (IR*)I);
*root_ir = (IR*)(A);
}

vtabarglist(A) ::= vtabarg(B) . {
A = new IR(kVtabarglist, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

vtabarglist(A) ::= vtabarglist(B) COMMA vtabarg(D) . {
A = new IR(kVtabarglist, OP3("", "COMMA", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

vtabarg(A) ::= .                       {
A = new IR(kVtabarg, OP0());
*root_ir = (IR*)(A);
}

vtabarg(A) ::= vtabarg(B) vtabargtoken(C) . {
A = new IR(kVtabarg, OP3("", "", ""), (IR*)B, (IR*)C);
*root_ir = (IR*)(A);
}

vtabargtoken(A) ::= ANY .            {
A = new IR(kVtabargtoken, OP3("ANY", "", ""));
*root_ir = (IR*)(A);
}

vtabargtoken(A) ::= lp(B) anylist(C) RP .  {
A = new IR(kVtabargtoken, OP3("", "", "RP"), (IR*)B, (IR*)C);
*root_ir = (IR*)(A);
}

lp(A) ::= LP .                       {
A = new IR(kLp, OP3("LP", "", ""));
*root_ir = (IR*)(A);
}

anylist(A) ::= . {
A = new IR(kAnylist, OP0());
*root_ir = (IR*)(A);
}

anylist(A) ::= anylist(B) LP anylist(D) RP . {
A = new IR(kAnylist, OP3("", "LP", "RP"), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

anylist(A) ::= anylist(B) ANY . {
A = new IR(kAnylist, OP3("", "ANY", ""), (IR*)B);
*root_ir = (IR*)(A);
}

%type wqlist {IR*}
%type wqitem {IR*}
with(A) ::= . {
A = new IR(kWith, OP0());
*root_ir = (IR*)(A);
}

with(A) ::= WITH wqlist(C) .              {
A = new IR(kWith, OP3("WITH", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

with(A) ::= WITH RECURSIVE wqlist(D) .    {
A = new IR(kWith, OP3("WITH RECURSIVE", "", ""), (IR*)D);
*root_ir = (IR*)(A);
}

%type wqas {IR*}
wqas(A) ::= AS .                  {
A = new IR(kWqas, OP3("AS", "", ""));
*root_ir = (IR*)(A);
}

wqas(A) ::= AS MATERIALIZED .     {
A = new IR(kWqas, OP3("AS MATERIALIZED", "", ""));
*root_ir = (IR*)(A);
}

wqas(A) ::= AS NOT MATERIALIZED . {
A = new IR(kWqas, OP3("AS NOT MATERIALIZED", "", ""));
*root_ir = (IR*)(A);
}

wqitem(A) ::= nm(B) eidlist_opt(C) wqas(D) LP select(F) RP . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
A = new IR(kUnknown, OP3("", "", "LP"), (IR*)A, (IR*)D);
A = new IR(kWqitem, OP3("", "", "RP"), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

wqlist(A) ::= wqitem(B) . {
A = new IR(kWqlist, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

wqlist(A) ::= wqlist(B) COMMA wqitem(D) . {
A = new IR(kWqlist, OP3("", "COMMA", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

%type windowdefn_list {IR*}
windowdefn_list(A) ::= windowdefn(B) . {
A = new IR(kWindowdefnList, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

windowdefn_list(A) ::= windowdefn_list(B) COMMA windowdefn(D) . {
A = new IR(kWindowdefnList, OP3("", "COMMA", ""), (IR*)B, (IR*)D);
*root_ir = (IR*)(A);
}

%type windowdefn {IR*}
windowdefn(A) ::= nm(B) AS LP window(E) RP . {
A = new IR(kWindowdefn, OP3("", "AS LP", "RP"), (IR*)B, (IR*)E);
*root_ir = (IR*)(A);
}

%type window {IR*}
%type frame_opt {IR*}
%type part_opt {IR*}
%type filter_clause {IR*}
%type over_clause {IR*}
%type filter_over {IR*}
%type range_or_rows {IR*}
%type frame_bound {IR*}
%type frame_bound_s {IR*}
%type frame_bound_e {IR*}
window(A) ::= PARTITION BY nexprlist(D) orderby_opt(E) frame_opt(F) . {
A = new IR(kUnknown, OP3("PARTITION BY", "", ""), (IR*)D, (IR*)E);
A = new IR(kWindow, OP3("", "", ""), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

window(A) ::= nm(B) PARTITION BY nexprlist(E) orderby_opt(F) frame_opt(G) . {
A = new IR(kUnknown, OP3("", "PARTITION BY", ""), (IR*)B, (IR*)E);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
A = new IR(kWindow, OP3("", "", ""), (IR*)A, (IR*)G);
*root_ir = (IR*)(A);
}

window(A) ::= ORDER BY sortlist(D) frame_opt(E) . {
A = new IR(kWindow, OP3("ORDER BY", "", ""), (IR*)D, (IR*)E);
*root_ir = (IR*)(A);
}

window(A) ::= nm(B) ORDER BY sortlist(E) frame_opt(F) . {
A = new IR(kUnknown, OP3("", "ORDER BY", ""), (IR*)B, (IR*)E);
A = new IR(kWindow, OP3("", "", ""), (IR*)A, (IR*)F);
*root_ir = (IR*)(A);
}

window(A) ::= frame_opt(B) . {
A = new IR(kWindow, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

window(A) ::= nm(B) frame_opt(C) . {
A = new IR(kWindow, OP3("", "", ""), (IR*)B, (IR*)C);
*root_ir = (IR*)(A);
}

frame_opt(A) ::= .                             {
A = new IR(kFrameOpt, OP0());
*root_ir = (IR*)(A);
}

frame_opt(A) ::= range_or_rows(B) frame_bound_s(C) frame_exclude_opt(D) . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
A = new IR(kFrameOpt, OP3("", "", ""), (IR*)A, (IR*)D);
*root_ir = (IR*)(A);
}

frame_opt(A) ::= range_or_rows(B) BETWEEN frame_bound_s(D) AND frame_bound_e(F) frame_exclude_opt(G) . {
A = new IR(kUnknown, OP3("", "BETWEEN", "AND"), (IR*)B, (IR*)D);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
A = new IR(kFrameOpt, OP3("", "", ""), (IR*)A, (IR*)G);
*root_ir = (IR*)(A);
}

range_or_rows(A) ::= RANGE|ROWS|GROUPS .   {
A = new IR(kRangeOrRows, OP3("RANGE|ROWS|GROUPS", "", ""));
*root_ir = (IR*)(A);
}

frame_bound_s(A) ::= frame_bound(B) .         {
A = new IR(kFrameBoundS, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

frame_bound_s(A) ::= UNBOUNDED PRECEDING . {
A = new IR(kFrameBoundS, OP3("UNBOUNDED PRECEDING", "", ""));
*root_ir = (IR*)(A);
}

frame_bound_e(A) ::= frame_bound(B) .         {
A = new IR(kFrameBoundE, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

frame_bound_e(A) ::= UNBOUNDED FOLLOWING . {
A = new IR(kFrameBoundE, OP3("UNBOUNDED FOLLOWING", "", ""));
*root_ir = (IR*)(A);
}

frame_bound(A) ::= expr(B) PRECEDING|FOLLOWING . {
A = new IR(kFrameBound, OP3("", "PRECEDING|FOLLOWING", ""), (IR*)B);
*root_ir = (IR*)(A);
}

frame_bound(A) ::= CURRENT ROW .           {
A = new IR(kFrameBound, OP3("CURRENT ROW", "", ""));
*root_ir = (IR*)(A);
}

%type frame_exclude_opt {IR*}
frame_exclude_opt(A) ::= . {
A = new IR(kFrameExcludeOpt, OP0());
*root_ir = (IR*)(A);
}

frame_exclude_opt(A) ::= EXCLUDE frame_exclude(C) . {
A = new IR(kFrameExcludeOpt, OP3("EXCLUDE", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

%type frame_exclude {IR*}
frame_exclude(A) ::= NO OTHERS .   {
A = new IR(kFrameExclude, OP3("NO OTHERS", "", ""));
*root_ir = (IR*)(A);
}

frame_exclude(A) ::= CURRENT ROW . {
A = new IR(kFrameExclude, OP3("CURRENT ROW", "", ""));
*root_ir = (IR*)(A);
}

frame_exclude(A) ::= GROUP|TIES .  {
A = new IR(kFrameExclude, OP3("GROUP|TIES", "", ""));
*root_ir = (IR*)(A);
}

%type window_clause {IR*}
window_clause(A) ::= WINDOW windowdefn_list(C) . {
A = new IR(kWindowClause, OP3("WINDOW", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

filter_over(A) ::= filter_clause(B) over_clause(C) . {
A = new IR(kFilterOver, OP3("", "", ""), (IR*)B, (IR*)C);
*root_ir = (IR*)(A);
}

filter_over(A) ::= over_clause(B) . {
A = new IR(kFilterOver, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

filter_over(A) ::= filter_clause(B) . {
A = new IR(kFilterOver, OP3("", "", ""), (IR*)B);
*root_ir = (IR*)(A);
}

over_clause(A) ::= OVER LP window(D) RP . {
A = new IR(kOverClause, OP3("OVER LP", "RP", ""), (IR*)D);
*root_ir = (IR*)(A);
}

over_clause(A) ::= OVER nm(C) . {
A = new IR(kOverClause, OP3("OVER", "", ""), (IR*)C);
*root_ir = (IR*)(A);
}

filter_clause(A) ::= FILTER LP WHERE expr(E) RP .  {
A = new IR(kFilterClause, OP3("FILTER LP WHERE", "RP", ""), (IR*)E);
*root_ir = (IR*)(A);
}

%token
  COLUMN          /* Reference to a table column */
  AGG_FUNCTION    /* An aggregate function */
  AGG_COLUMN      /* An aggregated column */
  TRUEFALSE       /* True or false keyword */
  ISNOT           /* Combination of IS and NOT */
  FUNCTION        /* A function invocation */
  UMINUS          /* Unary minus */
  UPLUS           /* Unary plus */
  TRUTH           /* IS TRUE or IS FALSE or IS NOT TRUE or IS NOT FALSE */
  REGISTER        /* Reference to a VDBE register */
  VECTOR          /* Vector */
  SELECT_COLUMN   /* Choose a single column from a multi-column SELECT */
  IF_NULL_ROW     /* the if-null-row operator */
  ASTERISK        /* The "*" in count(*) and similar */
  SPAN            /* The span operator */
  ERROR           /* An expression containing an error */
.
%token SPACE ILLEGAL.
