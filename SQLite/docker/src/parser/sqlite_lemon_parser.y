
// All token codes are small integers with #defines that begin with "TK_"
%token_prefix TKIR_

// The type of the data attached to each token is Token.  This is also the
// default type for non-terminals.
//
%token_type {const char*}
%default_type {IR*}

// An extra argument to the parse function for the parser, which is available
// to all actions.
%extra_argument {vector<IR*>* v_ir}

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
    #include "../include/utils.h"
    #include <vector>
    #include <string>
    #include <algorithm>

    void iter_set_id_type(IR* in, IDTYPE id_type) {
        if (in == nullptr) {
            std::cerr << "Error: iter_set_id in parser is nullptr. Logic Error? \n";
        }
        // Iterate IR binary tree, depth prioritized. (not left depth prioritized)
        bool is_finished_search = false;
        std::vector<IR*> ir_vec_iter;
        std::vector<IR*> all_ir_node_vec;
        IR* cur_IR = in;
        // Begin iterating.
        while (!is_finished_search) {
            ir_vec_iter.push_back(cur_IR);
            if (cur_IR != in)
                {all_ir_node_vec.push_back(cur_IR);} // Ignore the root input node at the moment, put it at the end of the vector.

            if (cur_IR->left_ != nullptr){
                cur_IR = cur_IR->left_;
                continue;
            } else { // Reaching the most depth. Consulting ir_vec_iter for right_ nodes.
                cur_IR = nullptr;
                while (cur_IR == nullptr){
                    if (ir_vec_iter.size() == 0){
                        is_finished_search = true;
                        break;
                    }
                    cur_IR = ir_vec_iter.back()->right_;
                    ir_vec_iter.pop_back();
                }
                continue;
            }
        }
        all_ir_node_vec.push_back(in);

        for (IR* cur_ir : all_ir_node_vec) {
            if (cur_ir->type_ == kIdentifier && !(cur_ir->is_node_struct_fixed) ) {
                cur_ir->id_type_ = id_type;
            }
        }

        return;
    }

}

input(A) ::= cmdlist(B) . {
A = new IR(kInput, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

cmdlist(A) ::= cmdlist(B) ecmd(C) . {
A = new IR(kCmdlist, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
}

cmdlist(A) ::= ecmd(B) . {
A = new IR(kCmdlist, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

ecmd(A) ::= SEMI(B) . {
A = new IR(kEcmd, OP3(string(B), "", ""));
v_ir->push_back(A);
}

ecmd(A) ::= cmdx(B) SEMI(C) . {
A = new IR(kEcmd, OP3("", string(C), ""), (IR*)B);
v_ir->push_back(A);
}

ecmd(A) ::= explain(B) cmdx(C) SEMI(D) .       {
A = new IR(kEcmd, OP3("", "", string(D)), (IR*)B, (IR*)C);
v_ir->push_back(A);
}

explain(A) ::= EXPLAIN(B) .              {
A = new IR(kExplain, OP3(string(B), "", ""));
v_ir->push_back(A);
}

explain(A) ::= EXPLAIN(B) QUERY(C) PLAN(D) .   {
A = new IR(kExplain, OP3(string(B) + " " + string(C) + " " + string(D), "", ""));
v_ir->push_back(A);
}

cmdx(A) ::= cmd(B) .           {
A = new IR(kCmdx, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

cmd(A) ::= BEGIN(B) transtype(C) trans_opt(D) .  {
A = new IR(kCmdBegin, OP3(string(B), "", ""), (IR*)C, (IR*)D);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

trans_opt(A) ::= . {
A = new IR(kTransOpt, OP0());
v_ir->push_back(A);
}

trans_opt(A) ::= TRANSACTION(B) . {
A = new IR(kTransOpt, OP3(string(B), "", ""));
v_ir->push_back(A);
}

trans_opt(A) ::= TRANSACTION(B) nm(C) . {
C->id_type_ = id_transaction_name;
A = new IR(kTransOpt, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

%type transtype {IR*}
transtype(A) ::= .             {
A = new IR(kTranstype, OP0());
v_ir->push_back(A);
}

transtype(A) ::= DEFERRED(B) .  {
A = new IR(kTranstype, OP3(string(B), "", ""));
v_ir->push_back(A);
}

transtype(A) ::= IMMEDIATE(B) . {
A = new IR(kTranstype, OP3(string(B), "", ""));
v_ir->push_back(A);
}

transtype(A) ::= EXCLUSIVE(B) . {
A = new IR(kTranstype, OP3(string(B), "", ""));
v_ir->push_back(A);
}

cmd(A) ::= COMMIT(B)|END(B) trans_opt(C) .   {
A = new IR(kCmdCommit, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

cmd(A) ::= ROLLBACK(B) trans_opt(C) .     {
A = new IR(kCmdRollback, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

savepoint_opt(A) ::= SAVEPOINT(B) . {
A = new IR(kSavepointOpt, OP3(string(B), "", ""));
v_ir->push_back(A);
}

savepoint_opt(A) ::= . {
A = new IR(kSavepointOpt, OP0());
v_ir->push_back(A);
}

cmd(A) ::= SAVEPOINT(B) nm(C) . {
C->id_type_ = id_savepoint_name;
A = new IR(kCmdSavepoint, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

cmd(A) ::= RELEASE(B) savepoint_opt(C) nm(D) . {
D->id_type_ = id_savepoint_name;
A = new IR(kCmdRelease, OP3(string(B), "", ""), (IR*)C, (IR*)D);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

cmd(A) ::= ROLLBACK(B) trans_opt(C) TO(D) savepoint_opt(E) nm(F) . {
F->id_type_ = id_savepoint_name;
A = new IR(kUnknown, OP3(string(B), string(D), ""), (IR*)C, (IR*)E);
v_ir->push_back(A);
A = new IR(kCmdRollback, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

cmd(A) ::= create_table(B) create_table_args(C) . {
A = new IR(kCmdCreateTable, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

create_table(A) ::= createkw(B) temp(C) TABLE(D) ifnotexists(E) nm(F) dbnm(G) . {
A = new IR(kUnknown, OP3("", "", string(D)), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kCreateTable, OP3("", "", ""), (IR*)A, (IR*)G);
v_ir->push_back(A);
if (!(F->is_empty()) && !(G->is_empty())) {
    if (G->left_ != nullptr) {
        G->left_->id_type_ = id_create_table_name;
    }
    F->id_type_ = id_database_name;
} else {
    F->id_type_ = id_create_table_name;
}
}

createkw(A) ::= CREATE(B) .  {
A = new IR(kCreatekw, OP3(string(B), "", ""));
v_ir->push_back(A);
}

%type ifnotexists {IR*}
ifnotexists(A) ::= .              {
A = new IR(kIfnotexists, OP0());
v_ir->push_back(A);
}

ifnotexists(A) ::= IF(B) NOT(C) EXISTS(D) . {
A = new IR(kIfnotexists, OP3(string(B) + " " + string(C) + " " + string(D), "", ""));
v_ir->push_back(A);
}

%type temp {IR*}
temp(A) ::= TEMP(B) .  {
A = new IR(kTemp, OP3(string(B), "", ""));
v_ir->push_back(A);
}

temp(A) ::= .      {
A = new IR(kTemp, OP0());
v_ir->push_back(A);
}

create_table_args(A) ::= LP(B) columnlist(C) conslist_opt(D) RP(E) table_option_set(F) . {
A = new IR(kUnknown, OP3(string(B), "", string(E)), (IR*)C, (IR*)D);
v_ir->push_back(A);
A = new IR(kCreateTableArgs, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);

iter_set_id_type(C, id_create_column_name);

}

create_table_args(A) ::= AS(B) select(C) . {
A = new IR(kCreateTableArgs, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

%type table_option_set {IR*}
%type table_option {IR*}
table_option_set(A) ::= .    {
A = new IR(kTableOptionSet, OP0());
v_ir->push_back(A);
}

table_option_set(A) ::= table_option(B) . {
A = new IR(kTableOptionSet, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

table_option_set(A) ::= table_option_set(B) COMMA(C) table_option(D) . {
A = new IR(kTableOptionSet, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
}

table_option(A) ::= WITHOUT(B) nm(C) . {
C->str_val_ = "ROWID";
A = new IR(kTableOption, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

table_option(A) ::= nm(B) . {
B->str_val_ = "STRICT";
A = new IR(kTableOption, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

columnlist(A) ::= columnlist(B) COMMA(C) columnname(D) carglist(E) . {
A = new IR(kUnknown, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
A = new IR(kColumnlist, OP3("", "", ""), (IR*)A, (IR*)E);
v_ir->push_back(A);
}

columnlist(A) ::= columnname(B) carglist(C) . {
A = new IR(kColumnlist, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
}

columnname(A) ::= nm(B) typetoken(C) . {
A = new IR(kColumnname, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
B->id_type_ = id_column_name;
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
%token_class idj  ID|INDEXED|JOIN_KW.
%type nm {IR*}

nm(A) ::= idj(B) . {
A = new IR(kIdentifier, string(B));
v_ir->push_back(A);
}

nm(A) ::= STRING(B) . {
A = new IR(kIdentifier, string(B));
v_ir->push_back(A);
}

%type typetoken {IR*}
typetoken(A) ::= .   {
A = new IR(kTypetoken, OP0());
v_ir->push_back(A);
}

typetoken(A) ::= typename(B) . {
A = new IR(kTypetoken, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

typetoken(A) ::= typename(B) LP(C) signed(D) RP(E) . {
A = new IR(kTypetoken, OP3("", string(C), string(E)), (IR*)B, (IR*)D);
v_ir->push_back(A);
}

typetoken(A) ::= typename(B) LP(C) signed(D) COMMA(E) signed(F) RP(G) . {
A = new IR(kUnknown, OP3("", string(C), string(E)), (IR*)B, (IR*)D);
v_ir->push_back(A);
A = new IR(kTypetoken, OP3("", "", string(G)), (IR*)A, (IR*)F);
v_ir->push_back(A);
}

%type typename {IR*}
typename(A) ::= ids(B) . {
A = new IR(kTypename, OP3(string(B), "", ""));
v_ir->push_back(A);
}

typename(A) ::= typename(B) ids(C) . {
A = new IR(kTypename, OP3("", string(C), ""), (IR*)B);
v_ir->push_back(A);
}

signed(A) ::= plus_num(B) . {
A = new IR(kSigned, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

signed(A) ::= minus_num(B) . {
A = new IR(kSigned, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

%type scanpt {IR*}
scanpt(A) ::= . {
A = new IR(kScanpt, OP0());
v_ir->push_back(A);
}

scantok(A) ::= . {
A = new IR(kScantok, OP0());
v_ir->push_back(A);
}

carglist(A) ::= carglist(B) ccons(C) . {
A = new IR(kCarglist, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
}

carglist(A) ::= . {
A = new IR(kCarglist, OP0());
v_ir->push_back(A);
}

ccons(A) ::= CONSTRAINT(B) nm(C) .           {
A = new IR(kCcons, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
C->id_type_ = id_table_constraint_name;
}

ccons(A) ::= DEFAULT(B) scantok(C) term(D) . {
A = new IR(kCcons, OP3(string(B), "", ""), (IR*)C, (IR*)D);
v_ir->push_back(A);
}

ccons(A) ::= DEFAULT(B) LP(C) expr(D) RP(E) . {
A = new IR(kCcons, OP3(string(B) + " " + string(C), string(E), ""), (IR*)D);
v_ir->push_back(A);
}

ccons(A) ::= DEFAULT(B) PLUS(C) scantok(D) term(E) . {
A = new IR(kCcons, OP3(string(B) + " " + string(C), "", ""), (IR*)D, (IR*)E);
v_ir->push_back(A);
}

ccons(A) ::= DEFAULT(B) MINUS(C) scantok(D) term(E) . {
A = new IR(kCcons, OP3(string(B) + " " + string(C), "", ""), (IR*)D, (IR*)E);
v_ir->push_back(A);
}

ccons(A) ::= DEFAULT(B) scantok(C) id(D) .       {
A = new IR(kCcons, OP3(string(B), string(D), ""), (IR*)C);
v_ir->push_back(A);
}

ccons(A) ::= NULL(B) onconf(C) . {
A = new IR(kCcons, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

ccons(A) ::= NOT(B) NULL(C) onconf(D) .    {
A = new IR(kCcons, OP3(string(B) + " " + string(C), "", ""), (IR*)D);
v_ir->push_back(A);
}

ccons(A) ::= PRIMARY(B) KEY(C) sortorder(D) onconf(E) autoinc(F) . {
A = new IR(kUnknown, OP3(string(B) + " " + string(C), "", ""), (IR*)D, (IR*)E);
v_ir->push_back(A);
A = new IR(kCcons, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
}

ccons(A) ::= UNIQUE(B) onconf(C) .      {
A = new IR(kCcons, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

ccons(A) ::= CHECK(B) LP(C) expr(D) RP(E) .  {
A = new IR(kCcons, OP3(string(B) + " " + string(C), string(E), ""), (IR*)D);
v_ir->push_back(A);
}

ccons(A) ::= REFERENCES(B) nm(C) eidlist_opt(D) refargs(E) . {
A = new IR(kUnknown, OP3(string(B), "", ""), (IR*)C, (IR*)D);
v_ir->push_back(A);
A = new IR(kCcons, OP3("", "", ""), (IR*)A, (IR*)E);
v_ir->push_back(A);
C->id_type_=id_top_table_name; // Referenced outer table.
}

ccons(A) ::= defer_subclause(B) .    {
A = new IR(kCcons, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

ccons(A) ::= COLLATE(B) ids(C) .        {
IR* tmp_ids = new IR(kIdentifier, string(C), id_collation_name);
tmp_ids->is_node_struct_fixed = true;
A = new IR(kCcons, OP3(string(B) + " ", "", ""), tmp_ids);
v_ir->push_back(A);
}

ccons(A) ::= GENERATED(B) ALWAYS(C) AS(D) generated(E) . {
A = new IR(kCcons, OP3(string(B) + " " + string(C) + " " + string(D), "", ""), (IR*)E);
v_ir->push_back(A);
}

ccons(A) ::= AS(B) generated(C) . {
A = new IR(kCcons, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

generated(A) ::= LP(B) expr(C) RP(D) .          {
A = new IR(kGenerated, OP3(string(B), string(D), ""), (IR*)C);
v_ir->push_back(A);
}

generated(A) ::= LP(B) expr(C) RP(D) ID(E) . {
string id_str = E;
if (findStringIn(id_str, "VIRTUAL") || findStringIn(id_str, "STORE")) {
    id_str = "VIRTUAL";
}
A = new IR(kGenerated, OP3(string(B), string(D) + id_str, ""), (IR*)C);
v_ir->push_back(A);
}

%type autoinc {IR*}
autoinc(A) ::= .          {
A = new IR(kAutoinc, OP0());
v_ir->push_back(A);
}

autoinc(A) ::= AUTOINCR(B) .  {
A = new IR(kAutoinc, OP3(string(B), "", ""));
v_ir->push_back(A);
}

%type refargs {IR*}
refargs(A) ::= .                  {
A = new IR(kRefargs, OP0());
v_ir->push_back(A);
}

refargs(A) ::= refargs(B) refarg(C) . {
A = new IR(kRefargs, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
}

%type refarg {IR*}
refarg(A) ::= MATCH(B) nm(C) .              {
A = new IR(kRefarg, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
// TODO: Not sure what the nm should match to.
}

refarg(A) ::= ON(B) INSERT(C) refact(D) .      {
A = new IR(kRefarg, OP3(string(B) + " " + string(C), "", ""), (IR*)D);
v_ir->push_back(A);
}

refarg(A) ::= ON(B) DELETE(C) refact(D) .   {
A = new IR(kRefarg, OP3(string(B) + " " + string(C), "", ""), (IR*)D);
v_ir->push_back(A);
}

refarg(A) ::= ON(B) UPDATE(C) refact(D) .   {
A = new IR(kRefarg, OP3(string(B) + " " + string(C), "", ""), (IR*)D);
v_ir->push_back(A);
}

%type refact {IR*}
refact(A) ::= SET(B) NULL(C) .              {
A = new IR(kRefact, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

refact(A) ::= SET(B) DEFAULT(C) .           {
A = new IR(kRefact, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

refact(A) ::= CASCADE(B) .               {
A = new IR(kRefact, OP3(string(B), "", ""));
v_ir->push_back(A);
}

refact(A) ::= RESTRICT(B) .              {
A = new IR(kRefact, OP3(string(B), "", ""));
v_ir->push_back(A);
}

refact(A) ::= NO(B) ACTION(C) .             {
A = new IR(kRefact, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

%type defer_subclause {IR*}
defer_subclause(A) ::= NOT(B) DEFERRABLE(C) init_deferred_pred_opt(D) .     {
A = new IR(kDeferSubclause, OP3(string(B) + " " + string(C), "", ""), (IR*)D);
v_ir->push_back(A);
}

defer_subclause(A) ::= DEFERRABLE(B) init_deferred_pred_opt(C) .      {
A = new IR(kDeferSubclause, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

%type init_deferred_pred_opt {IR*}
init_deferred_pred_opt(A) ::= .                       {
A = new IR(kInitDeferredPredOpt, OP0());
v_ir->push_back(A);
}

init_deferred_pred_opt(A) ::= INITIALLY(B) DEFERRED(C) .     {
A = new IR(kInitDeferredPredOpt, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

init_deferred_pred_opt(A) ::= INITIALLY(B) IMMEDIATE(C) .    {
A = new IR(kInitDeferredPredOpt, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

conslist_opt(A) ::= .                         {
A = new IR(kConslistOpt, OP0());
v_ir->push_back(A);
}

conslist_opt(A) ::= COMMA(B) conslist(C) . {
A = new IR(kConslistOpt, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

conslist(A) ::= conslist(B) tconscomma(C) tcons(D) . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kConslist, OP3("", "", ""), (IR*)A, (IR*)D);
v_ir->push_back(A);
}

conslist(A) ::= tcons(B) . {
A = new IR(kConslist, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

tconscomma(A) ::= COMMA(B) .            {
A = new IR(kTconscomma, OP3(string(B), "", ""));
v_ir->push_back(A);
}

tconscomma(A) ::= . {
A = new IR(kTconscomma, OP0());
v_ir->push_back(A);
}

tcons(A) ::= CONSTRAINT(B) nm(C) .      {
A = new IR(kTcons, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
C->id_type_=id_table_constraint_name;
}

tcons(A) ::= PRIMARY(B) KEY(C) LP(D) sortlist(E) autoinc(F) RP(G) onconf(H) . {
A = new IR(kUnknown, OP3(string(B) + " " + string(C) + " " + string(D), "", string(G)), (IR*)E, (IR*)F);
v_ir->push_back(A);
A = new IR(kTcons, OP3("", "", ""), (IR*)A, (IR*)H);
v_ir->push_back(A);
}

tcons(A) ::= UNIQUE(B) LP(C) sortlist(D) RP(E) onconf(F) . {
A = new IR(kTcons, OP3(string(B) + " " + string(C), string(E), ""), (IR*)D, (IR*)F);
v_ir->push_back(A);
}

tcons(A) ::= CHECK(B) LP(C) expr(D) RP(E) onconf(F) . {
A = new IR(kTcons, OP3(string(B) + " " + string(C), string(E), ""), (IR*)D, (IR*)F);
v_ir->push_back(A);
}

tcons(A) ::= FOREIGN(B) KEY(C) LP(D) eidlist(E) RP(F) REFERENCES(G) nm(H) eidlist_opt(I) refargs(J) defer_subclause_opt(K) . {
A = new IR(kUnknown, OP3(string(B) + " " + string(C) + " " + string(D), string(F) + " " + string(G), ""), (IR*)E, (IR*)H);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)I);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)J);
v_ir->push_back(A);
A = new IR(kTcons, OP3("", "", ""), (IR*)A, (IR*)K);
v_ir->push_back(A);
H->id_type_ = id_column_name; // Not sure whether this is accurate.
}

%type defer_subclause_opt {IR*}
defer_subclause_opt(A) ::= .                    {
A = new IR(kDeferSubclauseOpt, OP0());
v_ir->push_back(A);
}

defer_subclause_opt(A) ::= defer_subclause(B) . {
A = new IR(kDeferSubclauseOpt, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

%type onconf {IR*}
%type orconf {IR*}
%type resolvetype {IR*}
onconf(A) ::= .                              {
A = new IR(kOnconf, OP0());
v_ir->push_back(A);
}

onconf(A) ::= ON(B) CONFLICT(C) resolvetype(D) .    {
A = new IR(kOnconf, OP3(string(B) + " " + string(C), "", ""), (IR*)D);
v_ir->push_back(A);
}

orconf(A) ::= .                              {
A = new IR(kOrconf, OP0());
v_ir->push_back(A);
}

orconf(A) ::= OR(B) resolvetype(C) .             {
A = new IR(kOrconf, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

resolvetype(A) ::= raisetype(B) . {
A = new IR(kResolvetype, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

resolvetype(A) ::= IGNORE(B) .                   {
A = new IR(kResolvetype, OP3(string(B), "", ""));
v_ir->push_back(A);
}

resolvetype(A) ::= REPLACE(B) .                  {
A = new IR(kResolvetype, OP3(string(B), "", ""));
v_ir->push_back(A);
}

cmd(A) ::= DROP(B) TABLE(C) ifexists(D) fullname(E) . {
A = new IR(kCmdDropTable, OP3(string(B) + " " + string(C), "", ""), (IR*)D, (IR*)E);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
if (E->right_ != nullptr) {
    E->left_->id_type_ = id_database_name;
    E->right_->id_type_ = id_top_table_name;
} else {
    E->left_->id_type_ = id_top_table_name;
}
}

%type ifexists {IR*}
ifexists(A) ::= IF(B) EXISTS(C) .   {
A = new IR(kIfexists, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

ifexists(A) ::= .            {
A = new IR(kIfexists, OP0());
v_ir->push_back(A);
}

cmd(A) ::= createkw(B) temp(C) VIEW(D) ifnotexists(E) nm(F) dbnm(G) eidlist_opt(H) AS(I) select(J) . {
A = new IR(kUnknown, OP3("", "", string(D)), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)G);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", string(I)), (IR*)A, (IR*)H);
v_ir->push_back(A);
A = new IR(kCmdCreateView, OP3("", "", ""), (IR*)A, (IR*)J);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
if (!(F->is_empty()) && !(G->is_empty())) {
    F->id_type_ = id_database_name;
    G->left_->id_type_ = id_create_view_name;
} else {
    F->id_type_ = id_create_view_name;
}
}

cmd(A) ::= DROP(B) VIEW(C) ifexists(D) fullname(E) . {
A = new IR(kCmdDropView, OP3(string(B) + " " + string(C), "", ""), (IR*)D, (IR*)E);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
if (E->right_ != nullptr) {
    E->left_->id_type_ = id_database_name;
    E->right_->id_type_ = id_view_name;
} else {
    E->left_->id_type_ = id_view_name;
}
}

cmd(A) ::= select(B) .  {
A = new IR(kCmdSelect, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

%type select {IR*}
%type selectnowith {IR*}
%type oneselect {IR*}
select(A) ::= WITH(B) wqlist(C) selectnowith(D) . {
A = new IR(kSelect, OP3(string(B), "", ""), (IR*)C, (IR*)D);
v_ir->push_back(A);
}

select(A) ::= WITH(B) RECURSIVE(C) wqlist(D) selectnowith(E) . {
A = new IR(kSelect, OP3(string(B) + " " + string(C), "", ""), (IR*)D, (IR*)E);
v_ir->push_back(A);
}

select(A) ::= selectnowith(B) . {
A = new IR(kSelect, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

selectnowith(A) ::= oneselect(B) . {
A = new IR(kSelectnowith, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

selectnowith(A) ::= selectnowith(B) multiselect_op(C) oneselect(D) .  {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kSelectnowith, OP3("", "", ""), (IR*)A, (IR*)D);
v_ir->push_back(A);
}

%type multiselect_op {IR*}
multiselect_op(A) ::= UNION(B) .             {
A = new IR(kMultiselectOp, OP3(string(B), "", ""));
v_ir->push_back(A);
}

multiselect_op(A) ::= UNION(B) ALL(C) .             {
A = new IR(kMultiselectOp, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

multiselect_op(A) ::= EXCEPT(B)|INTERSECT(B) .  {
A = new IR(kMultiselectOp, OP3(string(B), "", ""));
v_ir->push_back(A);
}

oneselect(A) ::= SELECT(B) distinct(C) selcollist(D) from(E) where_opt(F) groupby_opt(G) having_opt(H) orderby_opt(I) limit_opt(J) . {
A = new IR(kUnknown, OP3(string(B), "", ""), (IR*)C, (IR*)D);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)G);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)H);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)I);
v_ir->push_back(A);
A = new IR(kOneselect, OP3("", "", ""), (IR*)A, (IR*)J);
v_ir->push_back(A);
}

oneselect(A) ::= SELECT(B) distinct(C) selcollist(D) from(E) where_opt(F) groupby_opt(G) having_opt(H) window_clause(I) orderby_opt(J) limit_opt(K) . {
A = new IR(kUnknown, OP3(string(B), "", ""), (IR*)C, (IR*)D);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)G);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)H);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)I);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)J);
v_ir->push_back(A);
A = new IR(kOneselect, OP3("", "", ""), (IR*)A, (IR*)K);
v_ir->push_back(A);
}

oneselect(A) ::= values(B) . {
A = new IR(kOneselect, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

%type values {IR*}
values(A) ::= VALUES(B) LP(C) nexprlist(D) RP(E) . {
A = new IR(kValues, OP3(string(B) + " " + string(C), string(E), ""), (IR*)D);
v_ir->push_back(A);
}

values(A) ::= values(B) COMMA(C) LP(D) nexprlist(E) RP(F) . {
A = new IR(kValues, OP3("", string(C) + " " + string(D), string(F)), (IR*)B, (IR*)E);
v_ir->push_back(A);
}

%type distinct {IR*}
distinct(A) ::= DISTINCT(B) .   {
A = new IR(kDistinct, OP3(string(B), "", ""));
v_ir->push_back(A);
}

distinct(A) ::= ALL(B) .        {
A = new IR(kDistinct, OP3(string(B), "", ""));
v_ir->push_back(A);
}

distinct(A) ::= .           {
A = new IR(kDistinct, OP0());
v_ir->push_back(A);
}

%type selcollist {IR*}
%type sclp {IR*}
sclp(A) ::= selcollist(B) COMMA(C) . {
A = new IR(kSclp, OP3("", string(C), ""), (IR*)B);
v_ir->push_back(A);
}

sclp(A) ::= .                                {
A = new IR(kSclp, OP0());
v_ir->push_back(A);
}

selcollist(A) ::= sclp(B) scanpt(C) expr(D) scanpt(E) as(F) .     {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)D);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
v_ir->push_back(A);
A = new IR(kSelcollist, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
}

selcollist(A) ::= sclp(B) scanpt(C) STAR(D) . {
A = new IR(kSelcollist, OP3("", "", string(D)), (IR*)B, (IR*)C);
v_ir->push_back(A);
}

selcollist(A) ::= sclp(B) scanpt(C) nm(D) DOT(E) STAR(F) . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kSelcollist, OP3("", "", string(E) + " " + string(F)), (IR*)A, (IR*)D);
v_ir->push_back(A);
}

%type as {IR*}
as(A) ::= AS(B) nm(C) .    {
A = new IR(kAs, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
C->id_type_ = id_column_alias_name;
}

as(A) ::= ids(B) . {
IR* tmp = new IR(kIdentifier, string(B), id_column_alias_name);
v_ir->push_back(tmp);
A = new IR(kAs, OP3("", "", ""), tmp);
v_ir->push_back(A);
}

as(A) ::= .            {
A = new IR(kAs, OP0());
v_ir->push_back(A);
}

%type seltablist {IR*}
%type stl_prefix {IR*}
%type from {IR*}
from(A) ::= .                {
A = new IR(kFrom, OP0());
v_ir->push_back(A);
}

from(A) ::= FROM(B) seltablist(C) . {
A = new IR(kFrom, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

stl_prefix(A) ::= seltablist(B) joinop(C) .    {
A = new IR(kStlPrefix, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
}

stl_prefix(A) ::= .                           {
A = new IR(kStlPrefix, OP0());
v_ir->push_back(A);
}

seltablist(A) ::= stl_prefix(B) nm(C) dbnm(D) as(E) on_using(F) . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)D);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
v_ir->push_back(A);
A = new IR(kSeltablist, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
if (!E->is_empty()) {
    E->left_->id_type_ = id_table_alias_name;
}
if (!(C->is_empty()) && !(D->is_empty())) {
    if (D->left_ != nullptr) {
        D->left_->id_type_ = id_top_table_name;
    }
    C->id_type_ = id_database_name;
} else {
    C->id_type_ = id_top_table_name;
}
}

seltablist(A) ::= stl_prefix(B) nm(C) dbnm(D) as(E) indexed_by(F) on_using(G) . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)D);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kSeltablist, OP3("", "", ""), (IR*)A, (IR*)G);
v_ir->push_back(A);
if (!E->is_empty()) {
    E->left_->id_type_ = id_table_alias_name;
}
if (!(C->is_empty()) && !(D->is_empty())) {
    if (D->left_ != nullptr) {
        D->left_->id_type_ = id_top_table_name;
    }
    C->id_type_ = id_database_name;
} else {
    C->id_type_ = id_top_table_name;
}
}

seltablist(A) ::= stl_prefix(B) nm(C) dbnm(D) LP(E) exprlist(F) RP(G) as(H) on_using(I) . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", string(E)), (IR*)A, (IR*)D);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", string(G)), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)H);
v_ir->push_back(A);
A = new IR(kSeltablist, OP3("", "", ""), (IR*)A, (IR*)I);
v_ir->push_back(A);
if (!H->is_empty()) {
    H->left_->id_type_ = id_table_alias_name;
}
if (!(C->is_empty()) && !(D->is_empty())) {
    if (D->left_ != nullptr) {
        D->left_->id_type_ = id_top_table_name;
    }
    C->id_type_ = id_database_name;
} else {
    C->id_type_ = id_top_table_name;
}
}

seltablist(A) ::= stl_prefix(B) LP(C) select(D) RP(E) as(F) on_using(G) . {
A = new IR(kUnknown, OP3("", string(C), string(E)), (IR*)B, (IR*)D);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kSeltablist, OP3("", "", ""), (IR*)A, (IR*)G);
v_ir->push_back(A);
if (!F->is_empty()) {
    F->left_->id_type_ = id_table_alias_name;
}
}

seltablist(A) ::= stl_prefix(B) LP(C) seltablist(D) RP(E) as(F) on_using(G) . {
A = new IR(kUnknown, OP3("", string(C), string(E)), (IR*)B, (IR*)D);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kSeltablist, OP3("", "", ""), (IR*)A, (IR*)G);
v_ir->push_back(A);
if (!F->is_empty()) {
    F->left_->id_type_ = id_table_alias_name;
}
}

%type dbnm {IR*}
dbnm(A) ::= .          {
A = new IR(kDbnm, OP0());
v_ir->push_back(A);
}

dbnm(A) ::= DOT(B) nm(C) . {
A = new IR(kDbnm, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
C->id_type_ = id_table_name;
}

%type fullname {IR*}
fullname(A) ::= nm(B) .  {
A = new IR(kFullname, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
B->id_type_ = id_table_name;
}

fullname(A) ::= nm(B) DOT(C) nm(D) . {
A = new IR(kFullname, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
B->id_type_ = id_database_name;
D->id_type_ = id_table_name;
}

%type xfullname {IR*}
xfullname(A) ::= nm(B) .  {
A = new IR(kXfullname, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
B->id_type_ = id_top_table_name;
}

xfullname(A) ::= nm(B) DOT(C) nm(D) .  {
A = new IR(kXfullname, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
B->id_type_ = id_database_name;
D->id_type_ = id_top_table_name;
}

xfullname(A) ::= nm(B) DOT(C) nm(D) AS(E) nm(F) .  {
A = new IR(kUnknown, OP3("", string(C), string(E)), (IR*)B, (IR*)D);
v_ir->push_back(A);
A = new IR(kXfullname, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
B->id_type_ = id_database_name;
D->id_type_ = id_top_table_name;
F->id_type_ = id_table_alias_name;
}

xfullname(A) ::= nm(B) AS(C) nm(D) . {
A = new IR(kXfullname, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
B->id_type_ = id_top_table_name;
D->id_type_ = id_table_alias_name;
}

%type joinop {IR*}
joinop(A) ::= COMMA(B)|JOIN(B) .              {
A = new IR(kJoinop, OP3(string(B), "", ""));
v_ir->push_back(A);
}

joinop(A) ::= JOIN_KW(B) JOIN(C) . {
A = new IR(kJoinop, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

joinop(A) ::= JOIN_KW(B) nm(C) JOIN(D) . {
A = new IR(kJoinop, OP3(string(B), string(D), ""), (IR*)C);
v_ir->push_back(A);
}

joinop(A) ::= JOIN_KW(B) nm(C) nm(D) JOIN(E) . {
A = new IR(kJoinop, OP3(string(B), "", string(E)), (IR*)C, (IR*)D);
v_ir->push_back(A);
}

%type on_using {IR*}
on_using(A) ::= ON(B) expr(C) .            {
A = new IR(kOnUsing, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

on_using(A) ::= USING(B) LP(C) idlist(D) RP(E) . {
A = new IR(kOnUsing, OP3(string(B) + " " + string(C), string(E), ""), (IR*)D);
v_ir->push_back(A);
}

on_using(A) ::= .                  [OR]{
A = new IR(kOnUsing, OP0());
v_ir->push_back(A);
}

%type indexed_opt {IR*}
%type indexed_by  {IR*}
indexed_opt(A) ::= .                 {
A = new IR(kIndexedOpt, OP0());
v_ir->push_back(A);
}

indexed_opt(A) ::= indexed_by(B) . {
A = new IR(kIndexedOpt, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

indexed_by(A) ::= INDEXED(B) BY(C) nm(D) . {
A = new IR(kIndexedBy, OP3(string(B) + " " + string(C), "", ""), (IR*)D);
v_ir->push_back(A);
D->id_type_ = id_index_name;
}

indexed_by(A) ::= NOT(B) INDEXED(C) .      {
A = new IR(kIndexedBy, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

%type orderby_opt {IR*}
%type sortlist {IR*}
orderby_opt(A) ::= .                          {
A = new IR(kOrderbyOpt, OP0());
v_ir->push_back(A);
}

orderby_opt(A) ::= ORDER(B) BY(C) sortlist(D) .      {
A = new IR(kOrderbyOpt, OP3(string(B) + " " + string(C), "", ""), (IR*)D);
v_ir->push_back(A);
}

sortlist(A) ::= sortlist(B) COMMA(C) expr(D) sortorder(E) nulls(F) . {
A = new IR(kUnknown, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
v_ir->push_back(A);
A = new IR(kSortlist, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
}

sortlist(A) ::= expr(B) sortorder(C) nulls(D) . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kSortlist, OP3("", "", ""), (IR*)A, (IR*)D);
v_ir->push_back(A);
}

%type sortorder {IR*}
sortorder(A) ::= ASC(B) .           {
A = new IR(kSortorder, OP3(string(B), "", ""));
v_ir->push_back(A);
}

sortorder(A) ::= DESC(B) .          {
A = new IR(kSortorder, OP3(string(B), "", ""));
v_ir->push_back(A);
}

sortorder(A) ::= .              {
A = new IR(kSortorder, OP0());
v_ir->push_back(A);
}

%type nulls {IR*}
nulls(A) ::= NULLS(B) FIRST(C) .       {
A = new IR(kNulls, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

nulls(A) ::= NULLS(B) LAST(C) .        {
A = new IR(kNulls, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

nulls(A) ::= .                  {
A = new IR(kNulls, OP0());
v_ir->push_back(A);
}

%type groupby_opt {IR*}
groupby_opt(A) ::= .                      {
A = new IR(kGroupbyOpt, OP0());
v_ir->push_back(A);
}

groupby_opt(A) ::= GROUP(B) BY(C) nexprlist(D) . {
A = new IR(kGroupbyOpt, OP3(string(B) + " " + string(C), "", ""), (IR*)D);
v_ir->push_back(A);
}

%type having_opt {IR*}
having_opt(A) ::= .                {
A = new IR(kHavingOpt, OP0());
v_ir->push_back(A);
}

having_opt(A) ::= HAVING(B) expr(C) .  {
A = new IR(kHavingOpt, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

%type limit_opt {IR*}
limit_opt(A) ::= .       {
A = new IR(kLimitOpt, OP0());
v_ir->push_back(A);
}

limit_opt(A) ::= LIMIT(B) expr(C) . {
A = new IR(kLimitOpt, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

limit_opt(A) ::= LIMIT(B) expr(C) OFFSET(D) expr(E) . {
A = new IR(kLimitOpt, OP3(string(B), string(D), ""), (IR*)C, (IR*)E);
v_ir->push_back(A);
}

limit_opt(A) ::= LIMIT(B) expr(C) COMMA(D) expr(E) . {
A = new IR(kLimitOpt, OP3(string(B), string(D), ""), (IR*)C, (IR*)E);
v_ir->push_back(A);
}

cmd(A) ::= with(B) DELETE(C) FROM(D) xfullname(E) indexed_opt(F) where_opt_ret(G) orderby_opt(H) limit_opt(I) . {
A = new IR(kUnknown, OP3("", string(C) + " " + string(D), ""), (IR*)B, (IR*)E);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)G);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)H);
v_ir->push_back(A);
A = new IR(kCmdDelete, OP3("", "", ""), (IR*)A, (IR*)I);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

%type where_opt {IR*}
%type where_opt_ret {IR*}
where_opt(A) ::= .                    {
A = new IR(kWhereOpt, OP0());
v_ir->push_back(A);
}

where_opt(A) ::= WHERE(B) expr(C) .       {
A = new IR(kWhereOpt, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

where_opt_ret(A) ::= .                                      {
A = new IR(kWhereOptRet, OP0());
v_ir->push_back(A);
}

where_opt_ret(A) ::= WHERE(B) expr(C) .                         {
A = new IR(kWhereOptRet, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

where_opt_ret(A) ::= RETURNING(B) selcollist(C) .               {
A = new IR(kWhereOptRet, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

where_opt_ret(A) ::= WHERE(B) expr(C) RETURNING(D) selcollist(E) . {
A = new IR(kWhereOptRet, OP3(string(B), string(D), ""), (IR*)C, (IR*)E);
v_ir->push_back(A);
}

cmd(A) ::= with(B) UPDATE(C) orconf(D) xfullname(E) indexed_opt(F) SET(G) setlist(H) from(I) where_opt_ret(J) orderby_opt(K) limit_opt(L) .  {
A = new IR(kUnknown, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", string(G)), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)H);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)I);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)J);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)K);
v_ir->push_back(A);
A = new IR(kCmdUpdate, OP3("", "", ""), (IR*)A, (IR*)L);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

%type setlist {IR*}
setlist(A) ::= setlist(B) COMMA(C) nm(D) EQ(E) expr(F) . {
A = new IR(kUnknown, OP3("", string(C), string(E)), (IR*)B, (IR*)D);
v_ir->push_back(A);
A = new IR(kSetlist, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
D->id_type_ = id_column_name;
}

setlist(A) ::= setlist(B) COMMA(C) LP(D) idlist(E) RP(F) EQ(G) expr(H) . {
A = new IR(kUnknown, OP3("", string(C) + " " + string(D), string(F) + " " + string(G)), (IR*)B, (IR*)E);
v_ir->push_back(A);
A = new IR(kSetlist, OP3("", "", ""), (IR*)A, (IR*)H);
v_ir->push_back(A);
}

setlist(A) ::= nm(B) EQ(C) expr(D) . {
A = new IR(kSetlist, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
B->id_type_ = id_column_name;
}

setlist(A) ::= LP(B) idlist(C) RP(D) EQ(E) expr(F) . {
A = new IR(kSetlist, OP3(string(B), string(D) + " " + string(E), ""), (IR*)C, (IR*)F);
v_ir->push_back(A);
}

cmd(A) ::= with(B) insert_cmd(C) INTO(D) xfullname(E) idlist_opt(F) select(G) upsert(H) . {
A = new IR(kUnknown, OP3("", "", string(D)), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)G);
v_ir->push_back(A);
A = new IR(kCmdInsert, OP3("", "", ""), (IR*)A, (IR*)H);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

cmd(A) ::= with(B) insert_cmd(C) INTO(D) xfullname(E) idlist_opt(F) DEFAULT(G) VALUES(H) returning(I) . {
A = new IR(kUnknown, OP3("", "", string(D)), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", string(G) + " " + string(H)), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kCmdInsert, OP3("", "", ""), (IR*)A, (IR*)I);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

%type upsert {IR*}
upsert(A) ::= . {
A = new IR(kUpsert, OP0());
v_ir->push_back(A);
}

upsert(A) ::= RETURNING(B) selcollist(C) .  {
A = new IR(kUpsert, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

upsert(A) ::= ON(B) CONFLICT(C) LP(D) sortlist(E) RP(F) where_opt(G) DO(H) UPDATE(I) SET(J) setlist(K) where_opt(L) upsert(M) . {
A = new IR(kUnknown, OP3(string(B) + " " + string(C) + " " + string(D), string(F), string(H) + " " + string(I) + " " + string(J)), (IR*)E, (IR*)G);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)K);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)L);
v_ir->push_back(A);
A = new IR(kUpsert, OP3("", "", ""), (IR*)A, (IR*)M);
v_ir->push_back(A);
}

upsert(A) ::= ON(B) CONFLICT(C) LP(D) sortlist(E) RP(F) where_opt(G) DO(H) NOTHING(I) upsert(J) . {
A = new IR(kUnknown, OP3(string(B) + " " + string(C) + " " + string(D), string(F), string(H) + " " + string(I)), (IR*)E, (IR*)G);
v_ir->push_back(A);
A = new IR(kUpsert, OP3("", "", ""), (IR*)A, (IR*)J);
v_ir->push_back(A);
}

upsert(A) ::= ON(B) CONFLICT(C) DO(D) NOTHING(E) returning(F) . {
A = new IR(kUpsert, OP3(string(B) + " " + string(C) + " " + string(D) + " " + string(E), "", ""), (IR*)F);
v_ir->push_back(A);
}

upsert(A) ::= ON(B) CONFLICT(C) DO(D) UPDATE(E) SET(F) setlist(G) where_opt(H) returning(I) . {
A = new IR(kUnknown, OP3(string(B) + " " + string(C) + " " + string(D) + " " + string(E) + " " + string(F), "", ""), (IR*)G, (IR*)H);
v_ir->push_back(A);
A = new IR(kUpsert, OP3("", "", ""), (IR*)A, (IR*)I);
v_ir->push_back(A);
}

returning(A) ::= RETURNING(B) selcollist(C) .  {
A = new IR(kReturning, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

returning(A) ::= . {
A = new IR(kReturning, OP0());
v_ir->push_back(A);
}

%type insert_cmd {IR*}
insert_cmd(A) ::= INSERT(B) orconf(C) .   {
A = new IR(kInsertCmd, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

insert_cmd(A) ::= REPLACE(B) .            {
A = new IR(kInsertCmd, OP3(string(B), "", ""));
v_ir->push_back(A);
}

%type idlist_opt {IR*}
%type idlist {IR*}
idlist_opt(A) ::= .                       {
A = new IR(kIdlistOpt, OP0());
v_ir->push_back(A);
}

idlist_opt(A) ::= LP(B) idlist(C) RP(D) .    {
A = new IR(kIdlistOpt, OP3(string(B), string(D), ""), (IR*)C);
v_ir->push_back(A);
}

idlist(A) ::= idlist(B) COMMA(C) nm(D) . {
A = new IR(kIdlist, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
D->id_type_ = id_column_name;
}

idlist(A) ::= nm(B) . {
A = new IR(kIdlist, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
B->id_type_ = id_column_name;
}

%type expr {IR*}
%type term {IR*}
expr(A) ::= term(B) . {
A = new IR(kExpr, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

expr(A) ::= LP(B) expr(C) RP(D) . {
A = new IR(kExpr, OP3(string(B), string(D), ""), (IR*)C);
v_ir->push_back(A);
}

expr(A) ::= idj(B) .          {
A = new IR(kIdentifier, string(B), id_column_name);
v_ir->push_back(A);
}

expr(A) ::= nm(B) DOT(C) nm(D) . {
A = new IR(kExpr, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
B->id_type_ = id_table_name;
D->id_type_ = id_column_name;
}

expr(A) ::= nm(B) DOT(C) nm(D) DOT(E) nm(F) . {
A = new IR(kUnknown, OP3("", string(C), string(E)), (IR*)B, (IR*)D);
v_ir->push_back(A);
A = new IR(kExpr, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
B->id_type_ = id_database_name;
D->id_type_ = id_table_name;
F->id_type_ = id_column_name;
}

term(A) ::= NULL(B)|FLOAT(B)|BLOB(B) . {
A = new IR(kFloatLiteral, string(B));
v_ir->push_back(A);
}

term(A) ::= STRING(B) .          {
A = new IR(kStringLiteral, string(B));
v_ir->push_back(A);
}

term(A) ::= INTEGER(B) . {
A = new IR(kIntegerLiteral, string(B));
v_ir->push_back(A);
}

expr(A) ::= VARIABLE(B) .     {
A = new IR(kExpr, string(B));
v_ir->push_back(A);
}

expr(A) ::= expr(B) COLLATE(C) ids(D) . {
A = new IR(kExpr, OP3("", string(C) + " " + string(D), ""), (IR*)B);
v_ir->push_back(A);
}

expr(A) ::= CAST(B) LP(C) expr(D) AS(E) typetoken(F) RP(G) . {
A = new IR(kExpr, OP3(string(B) + " " + string(C), string(E), string(G)), (IR*)D, (IR*)F);
v_ir->push_back(A);
}

expr(A) ::= idj(B) LP(C) distinct(D) exprlist(E) RP(F) . {

IR* func_ir = new IR(kIdentifier, string(B), id_function_name);
v_ir->push_back(func_ir);
A = new IR(kUnknown, OP3("", string(C), ""), func_ir, (IR*)D );
v_ir->push_back(A);
A = new IR(kExpr, OP3("", "", string(F)), (IR*)A, (IR*)E);
v_ir->push_back(A);

}

expr(A) ::= idj(B) LP(C) STAR(D) RP(E) . {

IR* func_ir = new IR(kIdentifier, string(B), id_function_name);
v_ir->push_back(func_ir);
A = new IR(kExpr, OP3("", string(C) + " " + string(D) + " " + string(E), ""), func_ir);
v_ir->push_back(A);

}

expr(A) ::= idj(B) LP(C) distinct(D) exprlist(E) RP(F) filter_over(G) . {

IR* func_ir = new IR(kIdentifier, string(B), id_function_name);
v_ir->push_back(func_ir);
A = new IR(kUnknown, OP3("", string(C), ""), func_ir, (IR*)D);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
v_ir->push_back(A);
A = new IR(kExpr, OP3("", string(F), ""), (IR*)A, (IR*)G);
v_ir->push_back(A);
}

expr(A) ::= idj(B) LP(C) STAR(D) RP(E) filter_over(F) . {

IR* func_ir = new IR(kIdentifier, string(B), id_function_name);
v_ir->push_back(func_ir);
A = new IR(kExpr, OP3("", string(C) + " " + string(D) + " " + string(E), ""), func_ir, (IR*)F);
v_ir->push_back(A);

}

term(A) ::= CTIME_KW(B) . {
A = new IR(kTimeLiteral, OP3(string(B), "", ""));
v_ir->push_back(A);
}

expr(A) ::= LP(B) nexprlist(C) COMMA(D) expr(E) RP(F) . {
A = new IR(kExpr, OP3(string(B), string(D), string(F)), (IR*)C, (IR*)E);
v_ir->push_back(A);
}

expr(A) ::= expr(B) AND(C) expr(D) .        {
A = new IR(kExpr, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
}

expr(A) ::= expr(B) OR(C) expr(D) .     {
A = new IR(kExpr, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
}

expr(A) ::= expr(B) LT(C)|GT(C)|GE(C)|LE(C) expr(D) . {
A = new IR(kExpr, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
}

expr(A) ::= expr(B) EQ(C)|NE(C) expr(D) .  {
A = new IR(kExpr, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
}

expr(A) ::= expr(B) BITAND(C)|BITOR(C)|LSHIFT(C)|RSHIFT(C) expr(D) . {
A = new IR(kExpr, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
}

expr(A) ::= expr(B) PLUS(C)|MINUS(C) expr(D) . {
A = new IR(kExpr, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
}

expr(A) ::= expr(B) STAR(C)|SLASH(C)|REM(C) expr(D) . {
A = new IR(kExpr, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
}

expr(A) ::= expr(B) CONCAT(C) expr(D) . {
A = new IR(kExpr, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
}

%type likeop {IR*}
likeop(A) ::= LIKE_KW(B)|MATCH(B) . {
A = new IR(kLikeop, OP3(string(B), "", ""));
v_ir->push_back(A);
}

likeop(A) ::= NOT(B) LIKE_KW(C)|MATCH(C) . {
A = new IR(kLikeop, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

expr(A) ::= expr(B) likeop(C) expr(D) .   [LIKE_KW] {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kExpr, OP3("", "", ""), (IR*)A, (IR*)D);
v_ir->push_back(A);
}

expr(A) ::= expr(B) likeop(C) expr(D) ESCAPE(E) expr(F) .   [LIKE_KW] {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", string(E)), (IR*)A, (IR*)D);
v_ir->push_back(A);
A = new IR(kExpr, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
}

expr(A) ::= expr(B) ISNULL(C)|NOTNULL(C) .   {
A = new IR(kExpr, OP3("", string(C), ""), (IR*)B);
v_ir->push_back(A);
}

expr(A) ::= expr(B) NOT(C) NULL(D) .    {
A = new IR(kExpr, OP3("", string(C) + " " + string(D), ""), (IR*)B);
v_ir->push_back(A);
}

expr(A) ::= expr(B) IS(C) expr(D) .     {
A = new IR(kExpr, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
}

expr(A) ::= expr(B) IS(C) NOT(D) expr(E) . {
A = new IR(kExpr, OP3("", string(C) + " " + string(D), ""), (IR*)B, (IR*)E);
v_ir->push_back(A);
}

expr(A) ::= expr(B) IS(C) NOT(D) DISTINCT(E) FROM(F) expr(G) .     {
A = new IR(kExpr, OP3("", string(C) + " " + string(D) + " " + string(E) + " " + string(F), ""), (IR*)B, (IR*)G);
v_ir->push_back(A);
}

expr(A) ::= expr(B) IS(C) DISTINCT(D) FROM(E) expr(F) . {
A = new IR(kExpr, OP3("", string(C) + " " + string(D) + " " + string(E), ""), (IR*)B, (IR*)F);
v_ir->push_back(A);
}

expr(A) ::= NOT(B) expr(C) .  {
A = new IR(kExpr, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

expr(A) ::= BITNOT(B) expr(C) . {
A = new IR(kExpr, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

expr(A) ::= PLUS(B)|MINUS(B) expr(C) .  [BITNOT]{
A = new IR(kExpr, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

expr(A) ::= expr(B) PTR(C) expr(D) . {
A = new IR(kExpr, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
}

%type between_op {IR*}
between_op(A) ::= BETWEEN(B) .     {
A = new IR(kBetweenOp, OP3(string(B), "", ""));
v_ir->push_back(A);
}

between_op(A) ::= NOT(B) BETWEEN(C) . {
A = new IR(kBetweenOp, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

expr(A) ::= expr(B) between_op(C) expr(D) AND(E) expr(F) .  [BETWEEN]{
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", string(E)), (IR*)A, (IR*)D);
v_ir->push_back(A);
A = new IR(kExpr, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
}

in_op(A) ::= IN(B) .      {
A = new IR(kInOp, OP3(string(B), "", ""));
v_ir->push_back(A);
}

in_op(A) ::= NOT(B) IN(C) .  {
A = new IR(kInOp, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

expr(A) ::= expr(B) in_op(C) LP(D) exprlist(E) RP(F) .  [IN]{
A = new IR(kUnknown, OP3("", "", string(D)), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kExpr, OP3("", "", string(F)), (IR*)A, (IR*)E);
v_ir->push_back(A);
}

expr(A) ::= LP(B) select(C) RP(D) . {
A = new IR(kExpr, OP3(string(B), string(D), ""), (IR*)C);
v_ir->push_back(A);
}

expr(A) ::= expr(B) in_op(C) LP(D) select(E) RP(F) .   [IN]{
A = new IR(kUnknown, OP3("", "", string(D)), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kExpr, OP3("", "", string(F)), (IR*)A, (IR*)E);
v_ir->push_back(A);
}

expr(A) ::= expr(B) in_op(C) nm(D) dbnm(E) paren_exprlist(F) .  [IN]{
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)D);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
v_ir->push_back(A);
A = new IR(kExpr, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
if (!(D->is_empty()) && !(E->is_empty())) {
    if (E->left_ != nullptr) {
        E->left_->id_type_ = id_table_name;
    }
    D->id_type_ = id_database_name;
} else {
    D->id_type_ = id_table_name;
}
}

expr(A) ::= EXISTS(B) LP(C) select(D) RP(E) . {
A = new IR(kExpr, OP3(string(B) + " " + string(C), string(E), ""), (IR*)D);
v_ir->push_back(A);
}

expr(A) ::= CASE(B) case_operand(C) case_exprlist(D) case_else(E) END(F) . {
A = new IR(kUnknown, OP3(string(B), "", ""), (IR*)C, (IR*)D);
v_ir->push_back(A);
A = new IR(kExpr, OP3("", "", string(F)), (IR*)A, (IR*)E);
v_ir->push_back(A);
}

%type case_exprlist {IR*}
case_exprlist(A) ::= case_exprlist(B) WHEN(C) expr(D) THEN(E) expr(F) . {
A = new IR(kUnknown, OP3("", string(C), string(E)), (IR*)B, (IR*)D);
v_ir->push_back(A);
A = new IR(kCaseExprlist, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
}

case_exprlist(A) ::= WHEN(B) expr(C) THEN(D) expr(E) . {
A = new IR(kCaseExprlist, OP3(string(B), string(D), ""), (IR*)C, (IR*)E);
v_ir->push_back(A);
}

%type case_else {IR*}
case_else(A) ::= ELSE(B) expr(C) .         {
A = new IR(kCaseElse, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

case_else(A) ::= .                     {
A = new IR(kCaseElse, OP0());
v_ir->push_back(A);
}

%type case_operand {IR*}
case_operand(A) ::= expr(B) .            {
A = new IR(kCaseOperand, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

case_operand(A) ::= .                   {
A = new IR(kCaseOperand, OP0());
v_ir->push_back(A);
}

%type exprlist {IR*}
%type nexprlist {IR*}
exprlist(A) ::= nexprlist(B) . {
A = new IR(kExprlist, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

exprlist(A) ::= .                            {
A = new IR(kExprlist, OP0());
v_ir->push_back(A);
}

nexprlist(A) ::= nexprlist(B) COMMA(C) expr(D) . {
A = new IR(kNexprlist, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
}

nexprlist(A) ::= expr(B) . {
A = new IR(kNexprlist, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

%type paren_exprlist {IR*}
paren_exprlist(A) ::= .   {
A = new IR(kParenExprlist, OP0());
v_ir->push_back(A);
}

paren_exprlist(A) ::= LP(B) exprlist(C) RP(D) .  {
A = new IR(kParenExprlist, OP3(string(B), string(D), ""), (IR*)C);
v_ir->push_back(A);
}

cmd(A) ::= createkw(B) uniqueflag(C) INDEX(D) ifnotexists(E) nm(F) dbnm(G) ON(H) nm(I) LP(J) sortlist(K) RP(L) where_opt(M) . {
A = new IR(kUnknown, OP3("", "", string(D)), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", string(H)), (IR*)A, (IR*)G);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", string(J)), (IR*)A, (IR*)I);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", string(L)), (IR*)A, (IR*)K);
v_ir->push_back(A);
A = new IR(kCmdCreateIndex, OP3("", "", ""), (IR*)A, (IR*)M);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
if (!(F->is_empty()) && !(G->is_empty())) {
    if (G->left_ != nullptr) {
        G->left_->id_type_ = id_create_index_name;
    }
    F->id_type_ = id_database_name;
} else {
    F->id_type_ = id_create_index_name;
}
I->id_type_ = id_column_name;
}

%type uniqueflag {IR*}
uniqueflag(A) ::= UNIQUE(B) .  {
A = new IR(kUniqueflag, OP3(string(B), "", ""));
v_ir->push_back(A);
}

uniqueflag(A) ::= .        {
A = new IR(kUniqueflag, OP0());
v_ir->push_back(A);
}

%type eidlist {IR*}
%type eidlist_opt {IR*}
eidlist_opt(A) ::= .                         {
A = new IR(kEidlistOpt, OP0());
v_ir->push_back(A);
}

eidlist_opt(A) ::= LP(B) eidlist(C) RP(D) .         {
A = new IR(kEidlistOpt, OP3(string(B), string(D), ""), (IR*)C);
v_ir->push_back(A);
}

eidlist(A) ::= eidlist(B) COMMA(C) nm(D) collate(E) sortorder(F) .  {
A = new IR(kUnknown, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
v_ir->push_back(A);
A = new IR(kEidlist, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
D->id_type_ = id_column_name;
D->is_node_struct_fixed = true;
}

eidlist(A) ::= nm(B) collate(C) sortorder(D) . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kEidlist, OP3("", "", ""), (IR*)A, (IR*)D);
v_ir->push_back(A);
B->id_type_ = id_column_name;
B->is_node_struct_fixed = true;
}

%type collate {IR*}
collate(A) ::= .              {
A = new IR(kCollate, OP0());
v_ir->push_back(A);
}

collate(A) ::= COLLATE(B) ids(C) .   {
IR* tmp_ids = new IR(kIdentifier, string(C), id_collation_name);
tmp_ids->is_node_struct_fixed = true;
A = new IR(kCollate, OP3(string(B) + " ", "", ""), tmp_ids);
v_ir->push_back(A);
}

cmd(A) ::= DROP(B) INDEX(C) ifexists(D) fullname(E) .   {
A = new IR(kCmdDropIndex, OP3(string(B) + " " + string(C), "", ""), (IR*)D, (IR*)E);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
if (E->right_ != nullptr) {
    E->left_->id_type_ = id_database_name;
    E->right_->id_type_ = id_index_name;
} else {
    E->left_->id_type_ = id_index_name;
}
}

%type vinto {IR*}
cmd(A) ::= VACUUM(B) vinto(C) .                {
A = new IR(kCmdVacuum, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

cmd(A) ::= VACUUM(B) nm(C) vinto(D) .          {
A = new IR(kCmdVacuum, OP3(string(B), "", ""), (IR*)C, (IR*)D);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
C->id_type_ = id_database_name;
}

vinto(A) ::= INTO(B) expr(C) .              {
A = new IR(kVinto, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

vinto(A) ::= .                          {
A = new IR(kVinto, OP0());
v_ir->push_back(A);
}

cmd(A) ::= PRAGMA(B) nm(C) dbnm(D) .                {
string nm_str = C->to_string();
string dbnm_str = D->to_string();
v_ir->erase(std::remove(v_ir->begin(), v_ir->end(), C), v_ir->end());
v_ir->erase(std::remove(v_ir->begin(), v_ir->end(), D), v_ir->end());
if (D->left_ != nullptr) {
v_ir->erase(std::remove(v_ir->begin(), v_ir->end(), D->left_), v_ir->end());
}
C->deep_drop();
D->deep_drop();
IR* cmd_name_ir = new IR(kIdentifier, nm_str + dbnm_str, id_pragma_name);
v_ir->push_back(cmd_name_ir);
A = new IR(kCmdPragma, OP3(string(B), "", ""), (IR*)cmd_name_ir );
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

cmd(A) ::= PRAGMA(B) nm(C) dbnm(D) EQ(E) nmnum(F) .    {
string nm_str = C->to_string();
string dbnm_str = D->to_string();
v_ir->erase(std::remove(v_ir->begin(), v_ir->end(), C), v_ir->end());
v_ir->erase(std::remove(v_ir->begin(), v_ir->end(), D), v_ir->end());
if (D->left_ != nullptr) {
v_ir->erase(std::remove(v_ir->begin(), v_ir->end(), D->left_), v_ir->end());
}
C->deep_drop();
D->deep_drop();
IR* cmd_name_ir = new IR(kIdentifier, nm_str + dbnm_str, id_pragma_name);
v_ir->push_back(cmd_name_ir);
A = new IR(kUnknown, OP3(string(B), "", string(E)), cmd_name_ir);
v_ir->push_back(A);
A = new IR(kCmdPragma, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

cmd(A) ::= PRAGMA(B) nm(C) dbnm(D) LP(E) nmnum(F) RP(G) . {
string nm_str = C->to_string();
string dbnm_str = D->to_string();
v_ir->erase(std::remove(v_ir->begin(), v_ir->end(), C), v_ir->end());
v_ir->erase(std::remove(v_ir->begin(), v_ir->end(), D), v_ir->end());
if (D->left_ != nullptr) {
v_ir->erase(std::remove(v_ir->begin(), v_ir->end(), D->left_), v_ir->end());
}
C->deep_drop();
D->deep_drop();
IR* cmd_name_ir = new IR(kIdentifier, nm_str + dbnm_str, id_pragma_name);
v_ir->push_back(cmd_name_ir);
A = new IR(kUnknown, OP3(string(B), "", string(E)), cmd_name_ir);
v_ir->push_back(A);
A = new IR(kCmdPragma, OP3("", "", string(G)), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

cmd(A) ::= PRAGMA(B) nm(C) dbnm(D) EQ(E) minus_num(F) . {
string nm_str = C->to_string();
string dbnm_str = D->to_string();
v_ir->erase(std::remove(v_ir->begin(), v_ir->end(), C), v_ir->end());
v_ir->erase(std::remove(v_ir->begin(), v_ir->end(), D), v_ir->end());
if (D->left_ != nullptr) {
v_ir->erase(std::remove(v_ir->begin(), v_ir->end(), D->left_), v_ir->end());
}
C->deep_drop();
D->deep_drop();
IR* cmd_name_ir = new IR(kIdentifier, nm_str + dbnm_str, id_pragma_name);
v_ir->push_back(cmd_name_ir);
A = new IR(kUnknown, OP3(string(B), "", string(E)), cmd_name_ir);
v_ir->push_back(A);
A = new IR(kCmdPragma, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

cmd(A) ::= PRAGMA(B) nm(C) dbnm(D) LP(E) minus_num(F) RP(G) . {
string nm_str = C->to_string();
string dbnm_str = D->to_string();
v_ir->erase(std::remove(v_ir->begin(), v_ir->end(), C), v_ir->end());
v_ir->erase(std::remove(v_ir->begin(), v_ir->end(), D), v_ir->end());
if (D->left_ != nullptr) {
v_ir->erase(std::remove(v_ir->begin(), v_ir->end(), D->left_), v_ir->end());
}
C->deep_drop();
D->deep_drop();
IR* cmd_name_ir = new IR(kIdentifier, nm_str + dbnm_str, id_pragma_name);
v_ir->push_back(cmd_name_ir);
A = new IR(kUnknown, OP3(string(B), "", string(E)), cmd_name_ir);
v_ir->push_back(A);
A = new IR(kCmdPragma, OP3("", "", string(G)), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

nmnum(A) ::= plus_num(B) . {
A = new IR(kNmnum, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

nmnum(A) ::= nm(B) . {
B->id_type_ = id_pragma_value;
A = new IR(kNmnum, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

nmnum(A) ::= ON(B) . {
A = new IR(kNmnum, OP3(string(B), "", ""));
v_ir->push_back(A);
}

nmnum(A) ::= DELETE(B) . {
A = new IR(kNmnum, OP3(string(B), "", ""));
v_ir->push_back(A);
}

nmnum(A) ::= DEFAULT(B) . {
A = new IR(kNmnum, OP3(string(B), "", ""));
v_ir->push_back(A);
}

%token_class number INTEGER|FLOAT.
plus_num(A) ::= PLUS(B) number(C) .       {
A = new IR(kPlusNum, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

plus_num(A) ::= number(B) . {
A = new IR(kPlusNum, OP3(string(B), "", ""));
v_ir->push_back(A);
}

minus_num(A) ::= MINUS(B) number(C) .     {
A = new IR(kMinusNum, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

cmd(A) ::= createkw(B) trigger_decl(C) BEGIN(D) trigger_cmd_list(E) END(F) . {
A = new IR(kUnknown, OP3("", "", string(D)), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kCmdCreateTrigger, OP3("", "", string(F)), (IR*)A, (IR*)E);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

trigger_decl(A) ::= temp(B) TRIGGER(C) ifnotexists(D) nm(E) dbnm(F) trigger_time(G) trigger_event(H) ON(I) fullname(J) foreach_clause(K) when_clause(L) . {
A = new IR(kUnknown, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)G);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", string(I)), (IR*)A, (IR*)H);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)J);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)K);
v_ir->push_back(A);
A = new IR(kTriggerDecl, OP3("", "", ""), (IR*)A, (IR*)L);
v_ir->push_back(A);
if (!(E->is_empty()) && !(F->is_empty())) {
    if (F->left_ != nullptr) {
        F->left_->id_type_ = id_create_index_name;
    }
    E->id_type_ = id_database_name;
} else {
    E->id_type_ = id_create_index_name;
}
if (J->right_ != nullptr) {
    J->left_->id_type_ = id_database_name;
    J->right_->id_type_ = id_top_table_name;
} else {
    J->left_->id_type_ = id_top_table_name;
}

}

%type trigger_time {IR*}
trigger_time(A) ::= BEFORE(B)|AFTER(B) .  {
A = new IR(kTriggerTime, OP3(string(B), "", ""));
v_ir->push_back(A);
}

trigger_time(A) ::= INSTEAD(B) OF(C) .  {
A = new IR(kTriggerTime, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

trigger_time(A) ::= .            {
A = new IR(kTriggerTime, OP0());
v_ir->push_back(A);
}

%type trigger_event {IR*}
trigger_event(A) ::= DELETE(B)|INSERT(B) .   {
A = new IR(kTriggerEvent, OP3(string(B), "", ""));
v_ir->push_back(A);
}

trigger_event(A) ::= UPDATE(B) .          {
A = new IR(kTriggerEvent, OP3(string(B), "", ""));
v_ir->push_back(A);
}

trigger_event(A) ::= UPDATE(B) OF(C) idlist(D) . {
A = new IR(kTriggerEvent, OP3(string(B) + " " + string(C), "", ""), (IR*)D);
v_ir->push_back(A);
}

foreach_clause(A) ::= . {
A = new IR(kForeachClause, OP0());
v_ir->push_back(A);
}

foreach_clause(A) ::= FOR(B) EACH(C) ROW(D) . {
A = new IR(kForeachClause, OP3(string(B) + " " + string(C) + " " + string(D), "", ""));
v_ir->push_back(A);
}

%type when_clause {IR*}
when_clause(A) ::= .             {
A = new IR(kWhenClause, OP0());
v_ir->push_back(A);
}

when_clause(A) ::= WHEN(B) expr(C) . {
A = new IR(kWhenClause, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

%type trigger_cmd_list {IR*}
trigger_cmd_list(A) ::= trigger_cmd_list(B) trigger_cmd(C) SEMI(D) . {
A = new IR(kTriggerCmdList, OP3("", "", string(D)), (IR*)B, (IR*)C);
v_ir->push_back(A);
}

trigger_cmd_list(A) ::= trigger_cmd(B) SEMI(C) . {
A = new IR(kTriggerCmdList, OP3("", string(C), ""), (IR*)B);
v_ir->push_back(A);
}

%type trnm {IR*}
trnm(A) ::= nm(B) . {
A = new IR(kTrnm, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
B->id_type_ = id_top_table_name;
}

trnm(A) ::= nm(B) DOT(C) nm(D) . {
A = new IR(kTrnm, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
B->id_type_ = id_database_name;
D->id_type_ = id_top_table_name;
}

tridxby(A) ::= . {
A = new IR(kTridxby, OP0());
v_ir->push_back(A);
}

tridxby(A) ::= INDEXED(B) BY(C) nm(D) . {
A = new IR(kTridxby, OP3(string(B) + " " + string(C), "", ""), (IR*)D);
v_ir->push_back(A);
D->id_type_ = id_index_name;
}

tridxby(A) ::= NOT(B) INDEXED(C) . {
A = new IR(kTridxby, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

%type trigger_cmd {IR*}
trigger_cmd(A) ::= UPDATE(B) orconf(C) trnm(D) tridxby(E) SET(F) setlist(G) from(H) where_opt(I) scanpt(J) .  {
A = new IR(kUnknown, OP3(string(B), "", ""), (IR*)C, (IR*)D);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", string(F)), (IR*)A, (IR*)E);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)G);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)H);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)I);
v_ir->push_back(A);
A = new IR(kTriggerCmd, OP3("", "", ""), (IR*)A, (IR*)J);
v_ir->push_back(A);
}

trigger_cmd(A) ::= scanpt(B) insert_cmd(C) INTO(D) trnm(E) idlist_opt(F) select(G) upsert(H) scanpt(I) . {
A = new IR(kUnknown, OP3("", "", string(D)), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)E);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)G);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)H);
v_ir->push_back(A);
A = new IR(kTriggerCmd, OP3("", "", ""), (IR*)A, (IR*)I);
v_ir->push_back(A);
}

trigger_cmd(A) ::= DELETE(B) FROM(C) trnm(D) tridxby(E) where_opt(F) scanpt(G) . {
A = new IR(kUnknown, OP3(string(B) + " " + string(C), "", ""), (IR*)D, (IR*)E);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kTriggerCmd, OP3("", "", ""), (IR*)A, (IR*)G);
v_ir->push_back(A);
}

trigger_cmd(A) ::= scanpt(B) select(C) scanpt(D) . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kTriggerCmd, OP3("", "", ""), (IR*)A, (IR*)D);
v_ir->push_back(A);
}

expr(A) ::= RAISE(B) LP(C) IGNORE(D) RP(E) .  {
A = new IR(kExpr, OP3(string(B) + " " + string(C) + " " + string(D) + " " + string(E), "", ""));
v_ir->push_back(A);
}

expr(A) ::= RAISE(B) LP(C) raisetype(D) COMMA(E) nm(F) RP(G) .  {
A = new IR(kExpr, OP3(string(B) + " " + string(C), string(E), string(G)), (IR*)D, (IR*)F);
v_ir->push_back(A);
}

%type raisetype {IR*}
raisetype(A) ::= ROLLBACK(B) .  {
A = new IR(kRaisetype, OP3(string(B), "", ""));
v_ir->push_back(A);
}

raisetype(A) ::= ABORT(B) .     {
A = new IR(kRaisetype, OP3(string(B), "", ""));
v_ir->push_back(A);
}

raisetype(A) ::= FAIL(B) .      {
A = new IR(kRaisetype, OP3(string(B), "", ""));
v_ir->push_back(A);
}

cmd(A) ::= DROP(B) TRIGGER(C) ifexists(D) fullname(E) . {
A = new IR(kCmdDropTrigger, OP3(string(B) + " " + string(C), "", ""), (IR*)D, (IR*)E);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
if (E->right_ != nullptr) {
    E->left_->id_type_ = id_database_name;
    E->right_->id_type_ = id_trigger_name;
} else {
    E->left_->id_type_ = id_trigger_name;
}
}

cmd(A) ::= ATTACH(B) database_kw_opt(C) expr(D) AS(E) expr(F) key_opt(G) . {
A = new IR(kUnknown, OP3(string(B), "", string(E)), (IR*)C, (IR*)D);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kCmdAttach, OP3("", "", ""), (IR*)A, (IR*)G);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

cmd(A) ::= DETACH(B) database_kw_opt(C) expr(D) . {
A = new IR(kCmdDetach, OP3(string(B), "", ""), (IR*)C, (IR*)D);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

%type key_opt {IR*}
key_opt(A) ::= .                     {
A = new IR(kKeyOpt, OP0());
v_ir->push_back(A);
}

key_opt(A) ::= KEY(B) expr(C) .          {
A = new IR(kKeyOpt, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

database_kw_opt(A) ::= DATABASE(B) . {
A = new IR(kDatabaseKwOpt, OP3(string(B), "", ""));
v_ir->push_back(A);
}

database_kw_opt(A) ::= . {
A = new IR(kDatabaseKwOpt, OP0());
v_ir->push_back(A);
}

cmd(A) ::= REINDEX(B) .                {
A = new IR(kCmdReindex, OP3(string(B), "", ""));
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

cmd(A) ::= REINDEX(B) nm(C) dbnm(D) .  {
A = new IR(kCmdReindex, OP3(string(B), "", ""), (IR*)C, (IR*)D);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
if (!(C->is_empty()) && !(D->is_empty())) {
    if (D->left_ != nullptr) {
        D->left_->id_type_ = id_index_name;
    }
    C->id_type_ = id_database_name;
} else {
    C->id_type_ = id_index_name;
}
}

cmd(A) ::= ANALYZE(B) .                {
A = new IR(kCmdAnalyze, OP3(string(B), "", ""));
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

cmd(A) ::= ANALYZE(B) nm(C) dbnm(D) .  {
A = new IR(kCmdAnalyze, OP3(string(B), "", ""), (IR*)C, (IR*)D);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
if (!(C->is_empty()) && !(D->is_empty())) {
    if (D->left_ != nullptr) {
        D->left_->id_type_ = id_top_table_name;
    }
    C->id_type_ = id_database_name;
} else {
    C->id_type_ = id_top_table_name;
}
}

cmd(A) ::= ALTER(B) TABLE(C) fullname(D) RENAME(E) TO(F) nm(G) . {
A = new IR(kCmdAlterTableRename, OP3(string(B) + " " + string(C), string(E) + " " + string(F), ""), (IR*)D, (IR*)G);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
if (D->right_ != nullptr) {
    D->left_->id_type_ = id_database_name;
    D->right_->id_type_ = id_top_table_name;
} else {
    D->left_->id_type_ = id_top_table_name;
}

G->id_type_ = id_create_table_name;

}

cmd(A) ::= ALTER(B) TABLE(C) add_column_fullname(D) ADD(E) kwcolumn_opt(F) columnname(G) carglist(H) . {
A = new IR(kUnknown, OP3(string(B) + " " + string(C), string(E), ""), (IR*)D, (IR*)F);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)G);
v_ir->push_back(A);
A = new IR(kCmdAlterTableAddColumn, OP3("", "", ""), (IR*)A, (IR*)H);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
G->left_->id_type_ = id_create_column_name;
}

cmd(A) ::= ALTER(B) TABLE(C) fullname(D) DROP(E) kwcolumn_opt(F) nm(G) . {
A = new IR(kUnknown, OP3(string(B) + " " + string(C), string(E), ""), (IR*)D, (IR*)F);
v_ir->push_back(A);
A = new IR(kCmdAlterTableDropColumn, OP3("", "", ""), (IR*)A, (IR*)G);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
G->id_type_ = id_column_name;
}

add_column_fullname(A) ::= fullname(B) . {
A = new IR(kAddColumnFullname, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
if (B->right_ != nullptr) {
    B->left_->id_type_ = id_database_name;
    B->right_->id_type_ = id_top_table_name;
} else {
    B->left_->id_type_ = id_top_table_name;
}
}

cmd(A) ::= ALTER(B) TABLE(C) fullname(D) RENAME(E) kwcolumn_opt(F) nm(G) TO(H) nm(I) . {
A = new IR(kUnknown, OP3(string(B) + " " + string(C), string(E), ""), (IR*)D, (IR*)F);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", string(H)), (IR*)A, (IR*)G);
v_ir->push_back(A);
A = new IR(kCmdAlterTableRenameColumn, OP3("", "", ""), (IR*)A, (IR*)I);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);

if (D->right_ != nullptr) {
    D->left_->id_type_ = id_database_name;
    D->right_->id_type_ = id_top_table_name;
} else {
    D->left_->id_type_ = id_top_table_name;
}

G->id_type_ = id_column_name;
I->id_type_ = id_create_column_name;

}

kwcolumn_opt(A) ::= . {
A = new IR(kKwcolumnOpt, OP0());
v_ir->push_back(A);
}

kwcolumn_opt(A) ::= COLUMNKW(B) . {
A = new IR(kKwcolumnOpt, OP3(string(B), "", ""));
v_ir->push_back(A);
}

cmd(A) ::= create_vtab(B) .                       {
A = new IR(kCmdCreateVTable, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

cmd(A) ::= create_vtab(B) LP(C) vtabarglist(D) RP(E) .  {
A = new IR(kCmdCreateVTable, OP3("", string(C), string(E)), (IR*)B, (IR*)D);
v_ir->push_back(A);
A = new IR(kCmd, OP0(), (IR*)(A));
v_ir->push_back(A);
}

create_vtab(A) ::= createkw(B) VIRTUAL(C) TABLE(D) ifnotexists(E) nm(F) dbnm(G) USING(H) nm(I) . {
A = new IR(kUnknown, OP3("", string(C) + " " + string(D), ""), (IR*)B, (IR*)E);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", string(H)), (IR*)A, (IR*)G);
v_ir->push_back(A);
A = new IR(kCreateVtab, OP3("", "", ""), (IR*)A, (IR*)I);
v_ir->push_back(A);
if (!(F->is_empty()) && !(G->is_empty())) {
    if (G->left_ != nullptr) {
        G->left_->id_type_ = id_create_table_name;
    }
    F->id_type_ = id_database_name;
} else {
    F->id_type_ = id_create_table_name;
}
}

vtabarglist(A) ::= vtabarg(B) . {
A = new IR(kVtabarglist, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

vtabarglist(A) ::= vtabarglist(B) COMMA(C) vtabarg(D) . {
A = new IR(kVtabarglist, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
}

vtabarg(A) ::= .                       {
A = new IR(kVtabarg, OP0());
v_ir->push_back(A);
}

vtabarg(A) ::= vtabarg(B) vtabargtoken(C) . {
A = new IR(kVtabarg, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
}

vtabargtoken(A) ::= ANY(B) .            {
A = new IR(kVtabargtoken, OP3(string(B), "", ""));
v_ir->push_back(A);
}

vtabargtoken(A) ::= lp(B) anylist(C) RP(D) .  {
A = new IR(kVtabargtoken, OP3("", "", string(D)), (IR*)B, (IR*)C);
v_ir->push_back(A);
}

lp(A) ::= LP(B) .                       {
A = new IR(kLp, OP3(string(B), "", ""));
v_ir->push_back(A);
}

anylist(A) ::= . {
A = new IR(kAnylist, OP0());
v_ir->push_back(A);
}

anylist(A) ::= anylist(B) LP(C) anylist(D) RP(E) . {
A = new IR(kAnylist, OP3("", string(C), string(E)), (IR*)B, (IR*)D);
v_ir->push_back(A);
}

anylist(A) ::= anylist(B) ANY(C) . {
A = new IR(kAnylist, OP3("", string(C), ""), (IR*)B);
v_ir->push_back(A);
}

%type wqlist {IR*}
%type wqitem {IR*}
with(A) ::= . {
A = new IR(kWith, OP0());
v_ir->push_back(A);
}

with(A) ::= WITH(B) wqlist(C) .              {
A = new IR(kWith, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

with(A) ::= WITH(B) RECURSIVE(C) wqlist(D) .    {
A = new IR(kWith, OP3(string(B) + " " + string(C), "", ""), (IR*)D);
v_ir->push_back(A);
}

%type wqas {IR*}
wqas(A) ::= AS(B) .                  {
A = new IR(kWqas, OP3(string(B), "", ""));
v_ir->push_back(A);
}

wqas(A) ::= AS(B) MATERIALIZED(C) .     {
A = new IR(kWqas, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

wqas(A) ::= AS(B) NOT(C) MATERIALIZED(D) . {
A = new IR(kWqas, OP3(string(B) + " " + string(C) + " " + string(D), "", ""));
v_ir->push_back(A);
}

wqitem(A) ::= nm(B) eidlist_opt(C) wqas(D) LP(E) select(F) RP(G) . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", string(E)), (IR*)A, (IR*)D);
v_ir->push_back(A);
A = new IR(kWqitem, OP3("", "", string(G)), (IR*)A, (IR*)F);
v_ir->push_back(A);
if (C->is_empty()) {
    B->id_type_ = id_create_column_name_with_tmp;
}
else {
    B->id_type_ = id_create_table_name_with_tmp;
    iter_set_id_type(C, id_create_column_name_with_tmp);
}

}

wqlist(A) ::= wqitem(B) . {
A = new IR(kWqlist, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

wqlist(A) ::= wqlist(B) COMMA(C) wqitem(D) . {
A = new IR(kWqlist, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
}

%type windowdefn_list {IR*}
windowdefn_list(A) ::= windowdefn(B) . {
A = new IR(kWindowdefnList, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

windowdefn_list(A) ::= windowdefn_list(B) COMMA(C) windowdefn(D) . {
A = new IR(kWindowdefnList, OP3("", string(C), ""), (IR*)B, (IR*)D);
v_ir->push_back(A);
}

%type windowdefn {IR*}
windowdefn(A) ::= nm(B) AS(C) LP(D) window(E) RP(F) . {
A = new IR(kWindowdefn, OP3("", string(C) + " " + string(D), string(F)), (IR*)B, (IR*)E);
v_ir->push_back(A);
B->id_type_ = id_window_name;
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
window(A) ::= PARTITION(B) BY(C) nexprlist(D) orderby_opt(E) frame_opt(F) . {
A = new IR(kUnknown, OP3(string(B) + " " + string(C), "", ""), (IR*)D, (IR*)E);
v_ir->push_back(A);
A = new IR(kWindow, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
}

window(A) ::= nm(B) PARTITION(C) BY(D) nexprlist(E) orderby_opt(F) frame_opt(G) . {
A = new IR(kUnknown, OP3("", string(C) + " " + string(D), ""), (IR*)B, (IR*)E);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kWindow, OP3("", "", ""), (IR*)A, (IR*)G);
v_ir->push_back(A);
B->id_type_ = id_window_name;
}

window(A) ::= ORDER(B) BY(C) sortlist(D) frame_opt(E) . {
A = new IR(kWindow, OP3(string(B) + " " + string(C), "", ""), (IR*)D, (IR*)E);
v_ir->push_back(A);
}

window(A) ::= nm(B) ORDER(C) BY(D) sortlist(E) frame_opt(F) . {
A = new IR(kUnknown, OP3("", string(C) + " " + string(D), ""), (IR*)B, (IR*)E);
v_ir->push_back(A);
A = new IR(kWindow, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
B->id_type_ = id_window_name;
}

window(A) ::= frame_opt(B) . {
A = new IR(kWindow, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

window(A) ::= nm(B) frame_opt(C) . {
A = new IR(kWindow, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
B->id_type_ = id_window_name;
}

frame_opt(A) ::= .                             {
A = new IR(kFrameOpt, OP0());
v_ir->push_back(A);
}

frame_opt(A) ::= range_or_rows(B) frame_bound_s(C) frame_exclude_opt(D) . {
A = new IR(kUnknown, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
A = new IR(kFrameOpt, OP3("", "", ""), (IR*)A, (IR*)D);
v_ir->push_back(A);
}

frame_opt(A) ::= range_or_rows(B) BETWEEN(C) frame_bound_s(D) AND(E) frame_bound_e(F) frame_exclude_opt(G) . {
A = new IR(kUnknown, OP3("", string(C), string(E)), (IR*)B, (IR*)D);
v_ir->push_back(A);
A = new IR(kUnknown, OP3("", "", ""), (IR*)A, (IR*)F);
v_ir->push_back(A);
A = new IR(kFrameOpt, OP3("", "", ""), (IR*)A, (IR*)G);
v_ir->push_back(A);
}

range_or_rows(A) ::= RANGE(B)|ROWS(B)|GROUPS(B) .   {
A = new IR(kRangeOrRows, OP3(string(B), "", ""));
v_ir->push_back(A);
}

frame_bound_s(A) ::= frame_bound(B) .         {
A = new IR(kFrameBoundS, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

frame_bound_s(A) ::= UNBOUNDED(B) PRECEDING(C) . {
A = new IR(kFrameBoundS, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

frame_bound_e(A) ::= frame_bound(B) .         {
A = new IR(kFrameBoundE, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

frame_bound_e(A) ::= UNBOUNDED(B) FOLLOWING(C) . {
A = new IR(kFrameBoundE, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

frame_bound(A) ::= expr(B) PRECEDING(C)|FOLLOWING(C) . {
A = new IR(kFrameBound, OP3("", string(C), ""), (IR*)B);
v_ir->push_back(A);
}

frame_bound(A) ::= CURRENT(B) ROW(C) .           {
A = new IR(kFrameBound, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

%type frame_exclude_opt {IR*}
frame_exclude_opt(A) ::= . {
A = new IR(kFrameExcludeOpt, OP0());
v_ir->push_back(A);
}

frame_exclude_opt(A) ::= EXCLUDE(B) frame_exclude(C) . {
A = new IR(kFrameExcludeOpt, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

%type frame_exclude {IR*}
frame_exclude(A) ::= NO(B) OTHERS(C) .   {
A = new IR(kFrameExclude, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

frame_exclude(A) ::= CURRENT(B) ROW(C) . {
A = new IR(kFrameExclude, OP3(string(B) + " " + string(C), "", ""));
v_ir->push_back(A);
}

frame_exclude(A) ::= GROUP(B)|TIES(B) .  {
A = new IR(kFrameExclude, OP3(string(B), "", ""));
v_ir->push_back(A);
}

%type window_clause {IR*}
window_clause(A) ::= WINDOW(B) windowdefn_list(C) . {
A = new IR(kWindowClause, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
}

filter_over(A) ::= filter_clause(B) over_clause(C) . {
A = new IR(kFilterOver, OP3("", "", ""), (IR*)B, (IR*)C);
v_ir->push_back(A);
}

filter_over(A) ::= over_clause(B) . {
A = new IR(kFilterOver, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

filter_over(A) ::= filter_clause(B) . {
A = new IR(kFilterOver, OP3("", "", ""), (IR*)B);
v_ir->push_back(A);
}

over_clause(A) ::= OVER(B) LP(C) window(D) RP(E) . {
A = new IR(kOverClause, OP3(string(B) + " " + string(C), string(E), ""), (IR*)D);
v_ir->push_back(A);
}

over_clause(A) ::= OVER(B) nm(C) . {
A = new IR(kOverClause, OP3(string(B), "", ""), (IR*)C);
v_ir->push_back(A);
C->id_type_ = id_window_name;
}

filter_clause(A) ::= FILTER(B) LP(C) WHERE(D) expr(E) RP(F) .  {
A = new IR(kFilterClause, OP3(string(B) + " " + string(C) + " " + string(D), string(F), ""), (IR*)E);
v_ir->push_back(A);
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
