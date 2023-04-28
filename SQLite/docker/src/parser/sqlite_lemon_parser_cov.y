
// All token codes are small integers with #defines that begin with "TK_"
%token_prefix TKIR_

// The type of the data attached to each token is Token.  This is also the
// default type for non-terminals.
//
%token_type {const char*}
%default_type {unsigned int}

// An extra argument to the parse function for the parser, which is available
// to all actions.
%extra_argument {GramCovMap* p_cov_map}

// The name of the generated procedure that implements the parser
// is as follows:
%name ParserCov

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
A = 152384; 
p_cov_map->log_edge_cov_map(B, A); 
}

cmdlist(A) ::= cmdlist(B) ecmd(C) . {
A = 41834; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

cmdlist(A) ::= ecmd(B) . {
A = 24315; 
p_cov_map->log_edge_cov_map(B, A); 
}

ecmd(A) ::= SEMI . {
A = 50141; 
}

ecmd(A) ::= cmdx(B) SEMI . {
A = 122340; 
p_cov_map->log_edge_cov_map(B, A); 
}

ecmd(A) ::= explain(B) cmdx(C) SEMI .       {
A = 92821; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

explain(A) ::= EXPLAIN .              {
A = 236429; 
}

explain(A) ::= EXPLAIN QUERY PLAN .   {
A = 13653; 
}

cmdx(A) ::= cmd(B) .           {
A = 162792; 
p_cov_map->log_edge_cov_map(B, A); 
}

cmd(A) ::= BEGIN transtype(B) trans_opt(C) .  {
A = 246427; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

trans_opt(A) ::= . {
A = 76505; 
}

trans_opt(A) ::= TRANSACTION . {
A = 102856; 
}

trans_opt(A) ::= TRANSACTION nm(B) . {
A = 224282; 
p_cov_map->log_edge_cov_map(B, A); 
}

%type transtype {unsigned int}
transtype(A) ::= .             {
A = 74019; 
}

transtype(A) ::= DEFERRED .  {
A = 96795; 
}

transtype(A) ::= IMMEDIATE . {
A = 32941; 
}

transtype(A) ::= EXCLUSIVE . {
A = 65075; 
}

cmd(A) ::= COMMIT|END trans_opt(B) .   {
A = 6554; 
p_cov_map->log_edge_cov_map(B, A); 
}

cmd(A) ::= ROLLBACK trans_opt(B) .     {
A = 110912; 
p_cov_map->log_edge_cov_map(B, A); 
}

savepoint_opt(A) ::= SAVEPOINT . {
A = 224971; 
}

savepoint_opt(A) ::= . {
A = 44839; 
}

cmd(A) ::= SAVEPOINT nm(B) . {
A = 230260; 
p_cov_map->log_edge_cov_map(B, A); 
}

cmd(A) ::= RELEASE savepoint_opt(B) nm(C) . {
A = 182151; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

cmd(A) ::= ROLLBACK trans_opt(B) TO savepoint_opt(C) nm(D) . {
A = 146098; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

cmd(A) ::= create_table(B) create_table_args(C) . {
A = 172385; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

create_table(A) ::= createkw(B) temp(C) TABLE ifnotexists(D) nm(E) dbnm(F) . {
A = 98545; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
}

createkw(A) ::= CREATE .  {
A = 98080; 
}

%type ifnotexists {unsigned int}
ifnotexists(A) ::= .              {
A = 69604; 
}

ifnotexists(A) ::= IF NOT EXISTS . {
A = 9016; 
}

%type temp {unsigned int}
temp(A) ::= TEMP .  {
A = 95427; 
}

temp(A) ::= .      {
A = 43787; 
}

create_table_args(A) ::= LP columnlist(B) conslist_opt(C) RP table_option_set(D) . {
A = 45086; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

create_table_args(A) ::= AS select(B) . {
A = 258859; 
p_cov_map->log_edge_cov_map(B, A); 
}

%type table_option_set {unsigned int}
%type table_option {unsigned int}
table_option_set(A) ::= .    {
A = 154861; 
}

table_option_set(A) ::= table_option(B) . {
A = 72624; 
p_cov_map->log_edge_cov_map(B, A); 
}

table_option_set(A) ::= table_option_set(B) COMMA table_option(C) . {
A = 237570; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

table_option(A) ::= WITHOUT nm(B) . {
A = 73274; 
p_cov_map->log_edge_cov_map(B, A); 
}

table_option(A) ::= nm(B) . {
A = 128864; 
p_cov_map->log_edge_cov_map(B, A); 
}

columnlist(A) ::= columnlist(B) COMMA columnname(C) carglist(D) . {
A = 136430; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

columnlist(A) ::= columnname(B) carglist(C) . {
A = 213444; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

columnname(A) ::= nm(B) typetoken(C) . {
A = 232935; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
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
%type nm {unsigned int}
nm(A) ::= idj . {
A = 63309; 
}

nm(A) ::= STRING . {
A = 221217; 
}

%type typetoken {unsigned int}
typetoken(A) ::= .   {
A = 230171; 
}

typetoken(A) ::= typename(B) . {
A = 95727; 
p_cov_map->log_edge_cov_map(B, A); 
}

typetoken(A) ::= typename(B) LP signed(C) RP . {
A = 60080; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

typetoken(A) ::= typename(B) LP signed(C) COMMA signed(D) RP . {
A = 110248; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

%type typename {unsigned int}
typename(A) ::= ids . {
A = 252362; 
}

typename(A) ::= typename(B) ids . {
A = 104667; 
p_cov_map->log_edge_cov_map(B, A); 
}

signed(A) ::= plus_num(B) . {
A = 128249; 
p_cov_map->log_edge_cov_map(B, A); 
}

signed(A) ::= minus_num(B) . {
A = 190006; 
p_cov_map->log_edge_cov_map(B, A); 
}

%type scanpt {unsigned int}
scanpt(A) ::= . {
A = 191646; 
}

scantok(A) ::= . {
A = 121826; 
}

carglist(A) ::= carglist(B) ccons(C) . {
A = 154725; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

carglist(A) ::= . {
A = 177881; 
}

ccons(A) ::= CONSTRAINT nm(B) .           {
A = 64888; 
p_cov_map->log_edge_cov_map(B, A); 
}

ccons(A) ::= DEFAULT scantok(B) term(C) . {
A = 97814; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

ccons(A) ::= DEFAULT LP expr(B) RP . {
A = 209655; 
p_cov_map->log_edge_cov_map(B, A); 
}

ccons(A) ::= DEFAULT PLUS scantok(B) term(C) . {
A = 109349; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

ccons(A) ::= DEFAULT MINUS scantok(B) term(C) . {
A = 58816; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

ccons(A) ::= DEFAULT scantok(B) id .       {
A = 118162; 
p_cov_map->log_edge_cov_map(B, A); 
}

ccons(A) ::= NULL onconf(B) . {
A = 126180; 
p_cov_map->log_edge_cov_map(B, A); 
}

ccons(A) ::= NOT NULL onconf(B) .    {
A = 122865; 
p_cov_map->log_edge_cov_map(B, A); 
}

ccons(A) ::= PRIMARY KEY sortorder(B) onconf(C) autoinc(D) . {
A = 144391; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

ccons(A) ::= UNIQUE onconf(B) .      {
A = 204475; 
p_cov_map->log_edge_cov_map(B, A); 
}

ccons(A) ::= CHECK LP expr(B) RP .  {
A = 133796; 
p_cov_map->log_edge_cov_map(B, A); 
}

ccons(A) ::= REFERENCES nm(B) eidlist_opt(C) refargs(D) . {
A = 16664; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

ccons(A) ::= defer_subclause(B) .    {
A = 175086; 
p_cov_map->log_edge_cov_map(B, A); 
}

ccons(A) ::= COLLATE ids .        {
A = 209038; 
}

ccons(A) ::= GENERATED ALWAYS AS generated(B) . {
A = 25592; 
p_cov_map->log_edge_cov_map(B, A); 
}

ccons(A) ::= AS generated(B) . {
A = 107243; 
p_cov_map->log_edge_cov_map(B, A); 
}

generated(A) ::= LP expr(B) RP .          {
A = 160238; 
p_cov_map->log_edge_cov_map(B, A); 
}

generated(A) ::= LP expr(B) RP ID . {
A = 71811; 
p_cov_map->log_edge_cov_map(B, A); 
}

%type autoinc {unsigned int}
autoinc(A) ::= .          {
A = 136399; 
}

autoinc(A) ::= AUTOINCR .  {
A = 19399; 
}

%type refargs {unsigned int}
refargs(A) ::= .                  {
A = 243258; 
}

refargs(A) ::= refargs(B) refarg(C) . {
A = 96397; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

%type refarg {unsigned int}
refarg(A) ::= MATCH nm(B) .              {
A = 232320; 
p_cov_map->log_edge_cov_map(B, A); 
}

refarg(A) ::= ON INSERT refact(B) .      {
A = 51290; 
p_cov_map->log_edge_cov_map(B, A); 
}

refarg(A) ::= ON DELETE refact(B) .   {
A = 76044; 
p_cov_map->log_edge_cov_map(B, A); 
}

refarg(A) ::= ON UPDATE refact(B) .   {
A = 38418; 
p_cov_map->log_edge_cov_map(B, A); 
}

%type refact {unsigned int}
refact(A) ::= SET NULL .              {
A = 92655; 
}

refact(A) ::= SET DEFAULT .           {
A = 188839; 
}

refact(A) ::= CASCADE .               {
A = 117481; 
}

refact(A) ::= RESTRICT .              {
A = 126127; 
}

refact(A) ::= NO ACTION .             {
A = 172623; 
}

%type defer_subclause {unsigned int}
defer_subclause(A) ::= NOT DEFERRABLE init_deferred_pred_opt(B) .     {
A = 24095; 
p_cov_map->log_edge_cov_map(B, A); 
}

defer_subclause(A) ::= DEFERRABLE init_deferred_pred_opt(B) .      {
A = 34608; 
p_cov_map->log_edge_cov_map(B, A); 
}

%type init_deferred_pred_opt {unsigned int}
init_deferred_pred_opt(A) ::= .                       {
A = 114590; 
}

init_deferred_pred_opt(A) ::= INITIALLY DEFERRED .     {
A = 222178; 
}

init_deferred_pred_opt(A) ::= INITIALLY IMMEDIATE .    {
A = 101889; 
}

conslist_opt(A) ::= .                         {
A = 163171; 
}

conslist_opt(A) ::= COMMA conslist(B) . {
A = 213268; 
p_cov_map->log_edge_cov_map(B, A); 
}

conslist(A) ::= conslist(B) tconscomma(C) tcons(D) . {
A = 31818; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

conslist(A) ::= tcons(B) . {
A = 261662; 
p_cov_map->log_edge_cov_map(B, A); 
}

tconscomma(A) ::= COMMA .            {
A = 226892; 
}

tconscomma(A) ::= . {
A = 245348; 
}

tcons(A) ::= CONSTRAINT nm(B) .      {
A = 156206; 
p_cov_map->log_edge_cov_map(B, A); 
}

tcons(A) ::= PRIMARY KEY LP sortlist(B) autoinc(C) RP onconf(D) . {
A = 91472; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

tcons(A) ::= UNIQUE LP sortlist(B) RP onconf(C) . {
A = 113067; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

tcons(A) ::= CHECK LP expr(B) RP onconf(C) . {
A = 199800; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

tcons(A) ::= FOREIGN KEY LP eidlist(B) RP REFERENCES nm(C) eidlist_opt(D) refargs(E) defer_subclause_opt(F) . {
A = 68323; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
}

%type defer_subclause_opt {unsigned int}
defer_subclause_opt(A) ::= .                    {
A = 245340; 
}

defer_subclause_opt(A) ::= defer_subclause(B) . {
A = 143016; 
p_cov_map->log_edge_cov_map(B, A); 
}

%type onconf {unsigned int}
%type orconf {unsigned int}
%type resolvetype {unsigned int}
onconf(A) ::= .                              {
A = 122944; 
}

onconf(A) ::= ON CONFLICT resolvetype(B) .    {
A = 205723; 
p_cov_map->log_edge_cov_map(B, A); 
}

orconf(A) ::= .                              {
A = 221522; 
}

orconf(A) ::= OR resolvetype(B) .             {
A = 171108; 
p_cov_map->log_edge_cov_map(B, A); 
}

resolvetype(A) ::= raisetype(B) . {
A = 209959; 
p_cov_map->log_edge_cov_map(B, A); 
}

resolvetype(A) ::= IGNORE .                   {
A = 105320; 
}

resolvetype(A) ::= REPLACE .                  {
A = 86634; 
}

cmd(A) ::= DROP TABLE ifexists(B) fullname(C) . {
A = 118821; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

%type ifexists {unsigned int}
ifexists(A) ::= IF EXISTS .   {
A = 10189; 
}

ifexists(A) ::= .            {
A = 74057; 
}

cmd(A) ::= createkw(B) temp(C) VIEW ifnotexists(D) nm(E) dbnm(F) eidlist_opt(G) AS select(H) . {
A = 120091; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
p_cov_map->log_edge_cov_map(G, A); 
p_cov_map->log_edge_cov_map(H, A); 
}

cmd(A) ::= DROP VIEW ifexists(B) fullname(C) . {
A = 42096; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

cmd(A) ::= select(B) .  {
A = 218071; 
p_cov_map->log_edge_cov_map(B, A); 
}

%type select {unsigned int}
%type selectnowith {unsigned int}
%type oneselect {unsigned int}
select(A) ::= WITH wqlist(B) selectnowith(C) . {
A = 21975; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

select(A) ::= WITH RECURSIVE wqlist(B) selectnowith(C) . {
A = 133911; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

select(A) ::= selectnowith(B) . {
A = 67255; 
p_cov_map->log_edge_cov_map(B, A); 
}

selectnowith(A) ::= oneselect(B) . {
A = 89324; 
p_cov_map->log_edge_cov_map(B, A); 
}

selectnowith(A) ::= selectnowith(B) multiselect_op(C) oneselect(D) .  {
A = 187131; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

%type multiselect_op {unsigned int}
multiselect_op(A) ::= UNION .             {
A = 123119; 
}

multiselect_op(A) ::= UNION ALL .             {
A = 46260; 
}

multiselect_op(A) ::= EXCEPT|INTERSECT .  {
A = 159242; 
}

oneselect(A) ::= SELECT distinct(B) selcollist(C) from(D) where_opt(E) groupby_opt(F) having_opt(G) orderby_opt(H) limit_opt(I) . {
A = 157778; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
p_cov_map->log_edge_cov_map(G, A); 
p_cov_map->log_edge_cov_map(H, A); 
p_cov_map->log_edge_cov_map(I, A); 
}

oneselect(A) ::= SELECT distinct(B) selcollist(C) from(D) where_opt(E) groupby_opt(F) having_opt(G) window_clause(H) orderby_opt(I) limit_opt(J) . {
A = 15585; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
p_cov_map->log_edge_cov_map(G, A); 
p_cov_map->log_edge_cov_map(H, A); 
p_cov_map->log_edge_cov_map(I, A); 
p_cov_map->log_edge_cov_map(J, A); 
}

oneselect(A) ::= values(B) . {
A = 5878; 
p_cov_map->log_edge_cov_map(B, A); 
}

%type values {unsigned int}
values(A) ::= VALUES LP nexprlist(B) RP . {
A = 184302; 
p_cov_map->log_edge_cov_map(B, A); 
}

values(A) ::= values(B) COMMA LP nexprlist(C) RP . {
A = 244627; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

%type distinct {unsigned int}
distinct(A) ::= DISTINCT .   {
A = 198677; 
}

distinct(A) ::= ALL .        {
A = 190178; 
}

distinct(A) ::= .           {
A = 22214; 
}

%type selcollist {unsigned int}
%type sclp {unsigned int}
sclp(A) ::= selcollist(B) COMMA . {
A = 33901; 
p_cov_map->log_edge_cov_map(B, A); 
}

sclp(A) ::= .                                {
A = 200738; 
}

selcollist(A) ::= sclp(B) scanpt(C) expr(D) scanpt(E) as(F) .     {
A = 173421; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
}

selcollist(A) ::= sclp(B) scanpt(C) STAR . {
A = 94351; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

selcollist(A) ::= sclp(B) scanpt(C) nm(D) DOT STAR . {
A = 116922; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

%type as {unsigned int}
as(A) ::= AS nm(B) .    {
A = 22878; 
p_cov_map->log_edge_cov_map(B, A); 
}

as(A) ::= ids . {
A = 102648; 
}

as(A) ::= .            {
A = 109665; 
}

%type seltablist {unsigned int}
%type stl_prefix {unsigned int}
%type from {unsigned int}
from(A) ::= .                {
A = 40616; 
}

from(A) ::= FROM seltablist(B) . {
A = 241809; 
p_cov_map->log_edge_cov_map(B, A); 
}

stl_prefix(A) ::= seltablist(B) joinop(C) .    {
A = 214401; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

stl_prefix(A) ::= .                           {
A = 159544; 
}

seltablist(A) ::= stl_prefix(B) nm(C) dbnm(D) as(E) on_using(F) . {
A = 57255; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
}

seltablist(A) ::= stl_prefix(B) nm(C) dbnm(D) as(E) indexed_by(F) on_using(G) . {
A = 69793; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
p_cov_map->log_edge_cov_map(G, A); 
}

seltablist(A) ::= stl_prefix(B) nm(C) dbnm(D) LP exprlist(E) RP as(F) on_using(G) . {
A = 161325; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
p_cov_map->log_edge_cov_map(G, A); 
}

seltablist(A) ::= stl_prefix(B) LP select(C) RP as(D) on_using(E) . {
A = 112207; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
}

seltablist(A) ::= stl_prefix(B) LP seltablist(C) RP as(D) on_using(E) . {
A = 61432; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
}

%type dbnm {unsigned int}
dbnm(A) ::= .          {
A = 136676; 
}

dbnm(A) ::= DOT nm(B) . {
A = 196651; 
p_cov_map->log_edge_cov_map(B, A); 
}

%type fullname {unsigned int}
fullname(A) ::= nm(B) .  {
A = 186442; 
p_cov_map->log_edge_cov_map(B, A); 
}

fullname(A) ::= nm(B) DOT nm(C) . {
A = 55400; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

%type xfullname {unsigned int}
xfullname(A) ::= nm(B) .  {
A = 22033; 
p_cov_map->log_edge_cov_map(B, A); 
}

xfullname(A) ::= nm(B) DOT nm(C) .  {
A = 24388; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

xfullname(A) ::= nm(B) DOT nm(C) AS nm(D) .  {
A = 92155; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

xfullname(A) ::= nm(B) AS nm(C) . {
A = 108728; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

%type joinop {unsigned int}
joinop(A) ::= COMMA|JOIN .              {
A = 233370; 
}

joinop(A) ::= JOIN_KW JOIN . {
A = 150993; 
}

joinop(A) ::= JOIN_KW nm(B) JOIN . {
A = 159587; 
p_cov_map->log_edge_cov_map(B, A); 
}

joinop(A) ::= JOIN_KW nm(B) nm(C) JOIN . {
A = 195427; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

%type on_using {unsigned int}
on_using(A) ::= ON expr(B) .            {
A = 51771; 
p_cov_map->log_edge_cov_map(B, A); 
}

on_using(A) ::= USING LP idlist(B) RP . {
A = 105090; 
p_cov_map->log_edge_cov_map(B, A); 
}

on_using(A) ::= .                  [OR]{
A = 238125; 
}

%type indexed_opt {unsigned int}
%type indexed_by  {unsigned int}
indexed_opt(A) ::= .                 {
A = 124699; 
}

indexed_opt(A) ::= indexed_by(B) . {
A = 239927; 
p_cov_map->log_edge_cov_map(B, A); 
}

indexed_by(A) ::= INDEXED BY nm(B) . {
A = 184350; 
p_cov_map->log_edge_cov_map(B, A); 
}

indexed_by(A) ::= NOT INDEXED .      {
A = 25550; 
}

%type orderby_opt {unsigned int}
%type sortlist {unsigned int}
orderby_opt(A) ::= .                          {
A = 217403; 
}

orderby_opt(A) ::= ORDER BY sortlist(B) .      {
A = 235333; 
p_cov_map->log_edge_cov_map(B, A); 
}

sortlist(A) ::= sortlist(B) COMMA expr(C) sortorder(D) nulls(E) . {
A = 113438; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
}

sortlist(A) ::= expr(B) sortorder(C) nulls(D) . {
A = 257064; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

%type sortorder {unsigned int}
sortorder(A) ::= ASC .           {
A = 67340; 
}

sortorder(A) ::= DESC .          {
A = 47254; 
}

sortorder(A) ::= .              {
A = 12128; 
}

%type nulls {unsigned int}
nulls(A) ::= NULLS FIRST .       {
A = 107139; 
}

nulls(A) ::= NULLS LAST .        {
A = 237979; 
}

nulls(A) ::= .                  {
A = 41892; 
}

%type groupby_opt {unsigned int}
groupby_opt(A) ::= .                      {
A = 203238; 
}

groupby_opt(A) ::= GROUP BY nexprlist(B) . {
A = 85685; 
p_cov_map->log_edge_cov_map(B, A); 
}

%type having_opt {unsigned int}
having_opt(A) ::= .                {
A = 64006; 
}

having_opt(A) ::= HAVING expr(B) .  {
A = 183486; 
p_cov_map->log_edge_cov_map(B, A); 
}

%type limit_opt {unsigned int}
limit_opt(A) ::= .       {
A = 133436; 
}

limit_opt(A) ::= LIMIT expr(B) . {
A = 243800; 
p_cov_map->log_edge_cov_map(B, A); 
}

limit_opt(A) ::= LIMIT expr(B) OFFSET expr(C) . {
A = 175725; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

limit_opt(A) ::= LIMIT expr(B) COMMA expr(C) . {
A = 259116; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

cmd(A) ::= with(B) DELETE FROM xfullname(C) indexed_opt(D) where_opt_ret(E) orderby_opt(F) limit_opt(G) . {
A = 75210; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
p_cov_map->log_edge_cov_map(G, A); 
}

%type where_opt {unsigned int}
%type where_opt_ret {unsigned int}
where_opt(A) ::= .                    {
A = 77368; 
}

where_opt(A) ::= WHERE expr(B) .       {
A = 252853; 
p_cov_map->log_edge_cov_map(B, A); 
}

where_opt_ret(A) ::= .                                      {
A = 157126; 
}

where_opt_ret(A) ::= WHERE expr(B) .                         {
A = 98890; 
p_cov_map->log_edge_cov_map(B, A); 
}

where_opt_ret(A) ::= RETURNING selcollist(B) .               {
A = 182283; 
p_cov_map->log_edge_cov_map(B, A); 
}

where_opt_ret(A) ::= WHERE expr(B) RETURNING selcollist(C) . {
A = 20997; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

cmd(A) ::= with(B) UPDATE orconf(C) xfullname(D) indexed_opt(E) SET setlist(F) from(G) where_opt_ret(H) orderby_opt(I) limit_opt(J) .  {
A = 62204; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
p_cov_map->log_edge_cov_map(G, A); 
p_cov_map->log_edge_cov_map(H, A); 
p_cov_map->log_edge_cov_map(I, A); 
p_cov_map->log_edge_cov_map(J, A); 
}

%type setlist {unsigned int}
setlist(A) ::= setlist(B) COMMA nm(C) EQ expr(D) . {
A = 56765; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

setlist(A) ::= setlist(B) COMMA LP idlist(C) RP EQ expr(D) . {
A = 68528; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

setlist(A) ::= nm(B) EQ expr(C) . {
A = 54537; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

setlist(A) ::= LP idlist(B) RP EQ expr(C) . {
A = 253104; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

cmd(A) ::= with(B) insert_cmd(C) INTO xfullname(D) idlist_opt(E) select(F) upsert(G) . {
A = 177480; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
p_cov_map->log_edge_cov_map(G, A); 
}

cmd(A) ::= with(B) insert_cmd(C) INTO xfullname(D) idlist_opt(E) DEFAULT VALUES returning(F) . {
A = 113679; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
}

%type upsert {unsigned int}
upsert(A) ::= . {
A = 191748; 
}

upsert(A) ::= RETURNING selcollist(B) .  {
A = 219868; 
p_cov_map->log_edge_cov_map(B, A); 
}

upsert(A) ::= ON CONFLICT LP sortlist(B) RP where_opt(C) DO UPDATE SET setlist(D) where_opt(E) upsert(F) . {
A = 9251; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
}

upsert(A) ::= ON CONFLICT LP sortlist(B) RP where_opt(C) DO NOTHING upsert(D) . {
A = 261587; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

upsert(A) ::= ON CONFLICT DO NOTHING returning(B) . {
A = 157412; 
p_cov_map->log_edge_cov_map(B, A); 
}

upsert(A) ::= ON CONFLICT DO UPDATE SET setlist(B) where_opt(C) returning(D) . {
A = 227046; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

returning(A) ::= RETURNING selcollist(B) .  {
A = 111399; 
p_cov_map->log_edge_cov_map(B, A); 
}

returning(A) ::= . {
A = 171292; 
}

%type insert_cmd {unsigned int}
insert_cmd(A) ::= INSERT orconf(B) .   {
A = 174905; 
p_cov_map->log_edge_cov_map(B, A); 
}

insert_cmd(A) ::= REPLACE .            {
A = 153992; 
}

%type idlist_opt {unsigned int}
%type idlist {unsigned int}
idlist_opt(A) ::= .                       {
A = 120136; 
}

idlist_opt(A) ::= LP idlist(B) RP .    {
A = 141124; 
p_cov_map->log_edge_cov_map(B, A); 
}

idlist(A) ::= idlist(B) COMMA nm(C) . {
A = 206465; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

idlist(A) ::= nm(B) . {
A = 103533; 
p_cov_map->log_edge_cov_map(B, A); 
}

%type expr {unsigned int}
%type term {unsigned int}
expr(A) ::= term(B) . {
A = 202920; 
p_cov_map->log_edge_cov_map(B, A); 
}

expr(A) ::= LP expr(B) RP . {
A = 149434; 
p_cov_map->log_edge_cov_map(B, A); 
}

expr(A) ::= idj .          {
A = 32662; 
}

expr(A) ::= nm(B) DOT nm(C) . {
A = 200810; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

expr(A) ::= nm(B) DOT nm(C) DOT nm(D) . {
A = 75495; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

term(A) ::= NULL|FLOAT|BLOB . {
A = 175001; 
}

term(A) ::= STRING .          {
A = 94864; 
}

term(A) ::= INTEGER . {
A = 244234; 
}

expr(A) ::= VARIABLE .     {
A = 68125; 
}

expr(A) ::= expr(B) COLLATE ids . {
A = 193364; 
p_cov_map->log_edge_cov_map(B, A); 
}

expr(A) ::= CAST LP expr(B) AS typetoken(C) RP . {
A = 172582; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

expr(A) ::= idj LP distinct(B) exprlist(C) RP . {
A = 27533; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

expr(A) ::= idj LP STAR RP . {
A = 37740; 
}

expr(A) ::= idj LP distinct(B) exprlist(C) RP filter_over(D) . {
A = 88891; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

expr(A) ::= idj LP STAR RP filter_over(B) . {
A = 3785; 
p_cov_map->log_edge_cov_map(B, A); 
}

term(A) ::= CTIME_KW . {
A = 185061; 
}

expr(A) ::= LP nexprlist(B) COMMA expr(C) RP . {
A = 169856; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

expr(A) ::= expr(B) AND expr(C) .        {
A = 236727; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

expr(A) ::= expr(B) OR expr(C) .     {
A = 52037; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

expr(A) ::= expr(B) LT|GT|GE|LE expr(C) . {
A = 32453; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

expr(A) ::= expr(B) EQ|NE expr(C) .  {
A = 11823; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

expr(A) ::= expr(B) BITAND|BITOR|LSHIFT|RSHIFT expr(C) . {
A = 186791; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

expr(A) ::= expr(B) PLUS|MINUS expr(C) . {
A = 212702; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

expr(A) ::= expr(B) STAR|SLASH|REM expr(C) . {
A = 146558; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

expr(A) ::= expr(B) CONCAT expr(C) . {
A = 41986; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

%type likeop {unsigned int}
likeop(A) ::= LIKE_KW|MATCH . {
A = 245473; 
}

likeop(A) ::= NOT LIKE_KW|MATCH . {
A = 188033; 
}

expr(A) ::= expr(B) likeop(C) expr(D) .   [LIKE_KW] {
A = 135739; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

expr(A) ::= expr(B) likeop(C) expr(D) ESCAPE expr(E) .   [LIKE_KW] {
A = 169201; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
}

expr(A) ::= expr(B) ISNULL|NOTNULL .   {
A = 258488; 
p_cov_map->log_edge_cov_map(B, A); 
}

expr(A) ::= expr(B) NOT NULL .    {
A = 97159; 
p_cov_map->log_edge_cov_map(B, A); 
}

expr(A) ::= expr(B) IS expr(C) .     {
A = 96129; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

expr(A) ::= expr(B) IS NOT expr(C) . {
A = 53907; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

expr(A) ::= expr(B) IS NOT DISTINCT FROM expr(C) .     {
A = 73980; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

expr(A) ::= expr(B) IS DISTINCT FROM expr(C) . {
A = 111696; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

expr(A) ::= NOT expr(B) .  {
A = 152902; 
p_cov_map->log_edge_cov_map(B, A); 
}

expr(A) ::= BITNOT expr(B) . {
A = 172296; 
p_cov_map->log_edge_cov_map(B, A); 
}

expr(A) ::= PLUS|MINUS expr(B) .  [BITNOT]{
A = 88167; 
p_cov_map->log_edge_cov_map(B, A); 
}

expr(A) ::= expr(B) PTR expr(C) . {
A = 61917; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

%type between_op {unsigned int}
between_op(A) ::= BETWEEN .     {
A = 18639; 
}

between_op(A) ::= NOT BETWEEN . {
A = 3434; 
}

expr(A) ::= expr(B) between_op(C) expr(D) AND expr(E) .  [BETWEEN]{
A = 49101; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
}

in_op(A) ::= IN .      {
A = 41601; 
}

in_op(A) ::= NOT IN .  {
A = 116035; 
}

expr(A) ::= expr(B) in_op(C) LP exprlist(D) RP .  [IN]{
A = 22282; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

expr(A) ::= LP select(B) RP . {
A = 18651; 
p_cov_map->log_edge_cov_map(B, A); 
}

expr(A) ::= expr(B) in_op(C) LP select(D) RP .   [IN]{
A = 114461; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

expr(A) ::= expr(B) in_op(C) nm(D) dbnm(E) paren_exprlist(F) .  [IN]{
A = 244820; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
}

expr(A) ::= EXISTS LP select(B) RP . {
A = 114789; 
p_cov_map->log_edge_cov_map(B, A); 
}

expr(A) ::= CASE case_operand(B) case_exprlist(C) case_else(D) END . {
A = 13579; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

%type case_exprlist {unsigned int}
case_exprlist(A) ::= case_exprlist(B) WHEN expr(C) THEN expr(D) . {
A = 100757; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

case_exprlist(A) ::= WHEN expr(B) THEN expr(C) . {
A = 32128; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

%type case_else {unsigned int}
case_else(A) ::= ELSE expr(B) .         {
A = 34256; 
p_cov_map->log_edge_cov_map(B, A); 
}

case_else(A) ::= .                     {
A = 158005; 
}

%type case_operand {unsigned int}
case_operand(A) ::= expr(B) .            {
A = 204691; 
p_cov_map->log_edge_cov_map(B, A); 
}

case_operand(A) ::= .                   {
A = 125976; 
}

%type exprlist {unsigned int}
%type nexprlist {unsigned int}
exprlist(A) ::= nexprlist(B) . {
A = 48622; 
p_cov_map->log_edge_cov_map(B, A); 
}

exprlist(A) ::= .                            {
A = 83151; 
}

nexprlist(A) ::= nexprlist(B) COMMA expr(C) . {
A = 153192; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

nexprlist(A) ::= expr(B) . {
A = 12762; 
p_cov_map->log_edge_cov_map(B, A); 
}

%type paren_exprlist {unsigned int}
paren_exprlist(A) ::= .   {
A = 147138; 
}

paren_exprlist(A) ::= LP exprlist(B) RP .  {
A = 122791; 
p_cov_map->log_edge_cov_map(B, A); 
}

cmd(A) ::= createkw(B) uniqueflag(C) INDEX ifnotexists(D) nm(E) dbnm(F) ON nm(G) LP sortlist(H) RP where_opt(I) . {
A = 236308; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
p_cov_map->log_edge_cov_map(G, A); 
p_cov_map->log_edge_cov_map(H, A); 
p_cov_map->log_edge_cov_map(I, A); 
}

%type uniqueflag {unsigned int}
uniqueflag(A) ::= UNIQUE .  {
A = 262038; 
}

uniqueflag(A) ::= .        {
A = 91310; 
}

%type eidlist {unsigned int}
%type eidlist_opt {unsigned int}
eidlist_opt(A) ::= .                         {
A = 161023; 
}

eidlist_opt(A) ::= LP eidlist(B) RP .         {
A = 57976; 
p_cov_map->log_edge_cov_map(B, A); 
}

eidlist(A) ::= eidlist(B) COMMA nm(C) collate(D) sortorder(E) .  {
A = 47453; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
}

eidlist(A) ::= nm(B) collate(C) sortorder(D) . {
A = 182447; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

%type collate {unsigned int}
collate(A) ::= .              {
A = 120574; 
}

collate(A) ::= COLLATE ids .   {
A = 4772; 
}

cmd(A) ::= DROP INDEX ifexists(B) fullname(C) .   {
A = 17750; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

%type vinto {unsigned int}
cmd(A) ::= VACUUM vinto(B) .                {
A = 230719; 
p_cov_map->log_edge_cov_map(B, A); 
}

cmd(A) ::= VACUUM nm(B) vinto(C) .          {
A = 149604; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

vinto(A) ::= INTO expr(B) .              {
A = 139399; 
p_cov_map->log_edge_cov_map(B, A); 
}

vinto(A) ::= .                          {
A = 149940; 
}

cmd(A) ::= PRAGMA nm(B) dbnm(C) .                {
A = 108011; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

cmd(A) ::= PRAGMA nm(B) dbnm(C) EQ nmnum(D) .    {
A = 113916; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

cmd(A) ::= PRAGMA nm(B) dbnm(C) LP nmnum(D) RP . {
A = 230734; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

cmd(A) ::= PRAGMA nm(B) dbnm(C) EQ minus_num(D) . {
A = 195373; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

cmd(A) ::= PRAGMA nm(B) dbnm(C) LP minus_num(D) RP . {
A = 197277; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

nmnum(A) ::= plus_num(B) . {
A = 153817; 
p_cov_map->log_edge_cov_map(B, A); 
}

nmnum(A) ::= nm(B) . {
A = 48844; 
p_cov_map->log_edge_cov_map(B, A); 
}

nmnum(A) ::= ON . {
A = 80152; 
}

nmnum(A) ::= DELETE . {
A = 182193; 
}

nmnum(A) ::= DEFAULT . {
A = 239432; 
}

%token_class number INTEGER|FLOAT.
plus_num(A) ::= PLUS number .       {
A = 8221; 
}

plus_num(A) ::= number . {
A = 181475; 
}

minus_num(A) ::= MINUS number .     {
A = 173489; 
}

cmd(A) ::= createkw(B) trigger_decl(C) BEGIN trigger_cmd_list(D) END . {
A = 256126; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

trigger_decl(A) ::= temp(B) TRIGGER ifnotexists(C) nm(D) dbnm(E) trigger_time(F) trigger_event(G) ON fullname(H) foreach_clause(I) when_clause(J) . {
A = 130066; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
p_cov_map->log_edge_cov_map(G, A); 
p_cov_map->log_edge_cov_map(H, A); 
p_cov_map->log_edge_cov_map(I, A); 
p_cov_map->log_edge_cov_map(J, A); 
}

%type trigger_time {unsigned int}
trigger_time(A) ::= BEFORE|AFTER .  {
A = 4242; 
}

trigger_time(A) ::= INSTEAD OF .  {
A = 235463; 
}

trigger_time(A) ::= .            {
A = 259314; 
}

%type trigger_event {unsigned int}
trigger_event(A) ::= DELETE|INSERT .   {
A = 160976; 
}

trigger_event(A) ::= UPDATE .          {
A = 255380; 
}

trigger_event(A) ::= UPDATE OF idlist(B) . {
A = 89064; 
p_cov_map->log_edge_cov_map(B, A); 
}

foreach_clause(A) ::= . {
A = 57798; 
}

foreach_clause(A) ::= FOR EACH ROW . {
A = 51035; 
}

%type when_clause {unsigned int}
when_clause(A) ::= .             {
A = 12594; 
}

when_clause(A) ::= WHEN expr(B) . {
A = 52778; 
p_cov_map->log_edge_cov_map(B, A); 
}

%type trigger_cmd_list {unsigned int}
trigger_cmd_list(A) ::= trigger_cmd_list(B) trigger_cmd(C) SEMI . {
A = 151056; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

trigger_cmd_list(A) ::= trigger_cmd(B) SEMI . {
A = 85669; 
p_cov_map->log_edge_cov_map(B, A); 
}

%type trnm {unsigned int}
trnm(A) ::= nm(B) . {
A = 162661; 
p_cov_map->log_edge_cov_map(B, A); 
}

trnm(A) ::= nm(B) DOT nm(C) . {
A = 166725; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

tridxby(A) ::= . {
A = 24809; 
}

tridxby(A) ::= INDEXED BY nm(B) . {
A = 205263; 
p_cov_map->log_edge_cov_map(B, A); 
}

tridxby(A) ::= NOT INDEXED . {
A = 199181; 
}

%type trigger_cmd {unsigned int}
trigger_cmd(A) ::= UPDATE orconf(B) trnm(C) tridxby(D) SET setlist(E) from(F) where_opt(G) scanpt(H) .  {
A = 88274; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
p_cov_map->log_edge_cov_map(G, A); 
p_cov_map->log_edge_cov_map(H, A); 
}

trigger_cmd(A) ::= scanpt(B) insert_cmd(C) INTO trnm(D) idlist_opt(E) select(F) upsert(G) scanpt(H) . {
A = 7100; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
p_cov_map->log_edge_cov_map(G, A); 
p_cov_map->log_edge_cov_map(H, A); 
}

trigger_cmd(A) ::= DELETE FROM trnm(B) tridxby(C) where_opt(D) scanpt(E) . {
A = 161726; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
}

trigger_cmd(A) ::= scanpt(B) select(C) scanpt(D) . {
A = 244286; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

expr(A) ::= RAISE LP IGNORE RP .  {
A = 144653; 
}

expr(A) ::= RAISE LP raisetype(B) COMMA nm(C) RP .  {
A = 206162; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

%type raisetype {unsigned int}
raisetype(A) ::= ROLLBACK .  {
A = 61603; 
}

raisetype(A) ::= ABORT .     {
A = 132441; 
}

raisetype(A) ::= FAIL .      {
A = 175033; 
}

cmd(A) ::= DROP TRIGGER ifexists(B) fullname(C) . {
A = 22929; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

cmd(A) ::= ATTACH database_kw_opt(B) expr(C) AS expr(D) key_opt(E) . {
A = 143275; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
}

cmd(A) ::= DETACH database_kw_opt(B) expr(C) . {
A = 181664; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

%type key_opt {unsigned int}
key_opt(A) ::= .                     {
A = 258666; 
}

key_opt(A) ::= KEY expr(B) .          {
A = 230228; 
p_cov_map->log_edge_cov_map(B, A); 
}

database_kw_opt(A) ::= DATABASE . {
A = 226247; 
}

database_kw_opt(A) ::= . {
A = 168944; 
}

cmd(A) ::= REINDEX .                {
A = 215231; 
}

cmd(A) ::= REINDEX nm(B) dbnm(C) .  {
A = 103598; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

cmd(A) ::= ANALYZE .                {
A = 8843; 
}

cmd(A) ::= ANALYZE nm(B) dbnm(C) .  {
A = 242594; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

cmd(A) ::= ALTER TABLE fullname(B) RENAME TO nm(C) . {
A = 43806; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

cmd(A) ::= ALTER TABLE add_column_fullname(B) ADD kwcolumn_opt(C) columnname(D) carglist(E) . {
A = 62368; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
}

cmd(A) ::= ALTER TABLE fullname(B) DROP kwcolumn_opt(C) nm(D) . {
A = 217557; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

add_column_fullname(A) ::= fullname(B) . {
A = 184585; 
p_cov_map->log_edge_cov_map(B, A); 
}

cmd(A) ::= ALTER TABLE fullname(B) RENAME kwcolumn_opt(C) nm(D) TO nm(E) . {
A = 174522; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
}

kwcolumn_opt(A) ::= . {
A = 129364; 
}

kwcolumn_opt(A) ::= COLUMNKW . {
A = 155635; 
}

cmd(A) ::= create_vtab(B) .                       {
A = 36389; 
p_cov_map->log_edge_cov_map(B, A); 
}

cmd(A) ::= create_vtab(B) LP vtabarglist(C) RP .  {
A = 95719; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

create_vtab(A) ::= createkw(B) VIRTUAL TABLE ifnotexists(C) nm(D) dbnm(E) USING nm(F) . {
A = 202821; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
p_cov_map->log_edge_cov_map(F, A); 
}

vtabarglist(A) ::= vtabarg(B) . {
A = 149684; 
p_cov_map->log_edge_cov_map(B, A); 
}

vtabarglist(A) ::= vtabarglist(B) COMMA vtabarg(C) . {
A = 19776; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

vtabarg(A) ::= .                       {
A = 138440; 
}

vtabarg(A) ::= vtabarg(B) vtabargtoken(C) . {
A = 156123; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

vtabargtoken(A) ::= ANY .            {
A = 83518; 
}

vtabargtoken(A) ::= lp(B) anylist(C) RP .  {
A = 210805; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

lp(A) ::= LP .                       {
A = 181170; 
}

anylist(A) ::= . {
A = 121677; 
}

anylist(A) ::= anylist(B) LP anylist(C) RP . {
A = 34947; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

anylist(A) ::= anylist(B) ANY . {
A = 100310; 
p_cov_map->log_edge_cov_map(B, A); 
}

%type wqlist {unsigned int}
%type wqitem {unsigned int}
with(A) ::= . {
A = 257492; 
}

with(A) ::= WITH wqlist(B) .              {
A = 37742; 
p_cov_map->log_edge_cov_map(B, A); 
}

with(A) ::= WITH RECURSIVE wqlist(B) .    {
A = 124854; 
p_cov_map->log_edge_cov_map(B, A); 
}

%type wqas {unsigned int}
wqas(A) ::= AS .                  {
A = 84711; 
}

wqas(A) ::= AS MATERIALIZED .     {
A = 217809; 
}

wqas(A) ::= AS NOT MATERIALIZED . {
A = 26288; 
}

wqitem(A) ::= nm(B) eidlist_opt(C) wqas(D) LP select(E) RP . {
A = 103206; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
}

wqlist(A) ::= wqitem(B) . {
A = 214108; 
p_cov_map->log_edge_cov_map(B, A); 
}

wqlist(A) ::= wqlist(B) COMMA wqitem(C) . {
A = 134797; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

%type windowdefn_list {unsigned int}
windowdefn_list(A) ::= windowdefn(B) . {
A = 113334; 
p_cov_map->log_edge_cov_map(B, A); 
}

windowdefn_list(A) ::= windowdefn_list(B) COMMA windowdefn(C) . {
A = 15849; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

%type windowdefn {unsigned int}
windowdefn(A) ::= nm(B) AS LP window(C) RP . {
A = 36037; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

%type window {unsigned int}
%type frame_opt {unsigned int}
%type part_opt {unsigned int}
%type filter_clause {unsigned int}
%type over_clause {unsigned int}
%type filter_over {unsigned int}
%type range_or_rows {unsigned int}
%type frame_bound {unsigned int}
%type frame_bound_s {unsigned int}
%type frame_bound_e {unsigned int}
window(A) ::= PARTITION BY nexprlist(B) orderby_opt(C) frame_opt(D) . {
A = 115370; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

window(A) ::= nm(B) PARTITION BY nexprlist(C) orderby_opt(D) frame_opt(E) . {
A = 106123; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
}

window(A) ::= ORDER BY sortlist(B) frame_opt(C) . {
A = 244092; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

window(A) ::= nm(B) ORDER BY sortlist(C) frame_opt(D) . {
A = 27153; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

window(A) ::= frame_opt(B) . {
A = 186596; 
p_cov_map->log_edge_cov_map(B, A); 
}

window(A) ::= nm(B) frame_opt(C) . {
A = 245975; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

frame_opt(A) ::= .                             {
A = 117283; 
}

frame_opt(A) ::= range_or_rows(B) frame_bound_s(C) frame_exclude_opt(D) . {
A = 215521; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
}

frame_opt(A) ::= range_or_rows(B) BETWEEN frame_bound_s(C) AND frame_bound_e(D) frame_exclude_opt(E) . {
A = 23365; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
p_cov_map->log_edge_cov_map(D, A); 
p_cov_map->log_edge_cov_map(E, A); 
}

range_or_rows(A) ::= RANGE|ROWS|GROUPS .   {
A = 21793; 
}

frame_bound_s(A) ::= frame_bound(B) .         {
A = 3342; 
p_cov_map->log_edge_cov_map(B, A); 
}

frame_bound_s(A) ::= UNBOUNDED PRECEDING . {
A = 53298; 
}

frame_bound_e(A) ::= frame_bound(B) .         {
A = 206016; 
p_cov_map->log_edge_cov_map(B, A); 
}

frame_bound_e(A) ::= UNBOUNDED FOLLOWING . {
A = 88803; 
}

frame_bound(A) ::= expr(B) PRECEDING|FOLLOWING . {
A = 74111; 
p_cov_map->log_edge_cov_map(B, A); 
}

frame_bound(A) ::= CURRENT ROW .           {
A = 28525; 
}

%type frame_exclude_opt {unsigned int}
frame_exclude_opt(A) ::= . {
A = 54486; 
}

frame_exclude_opt(A) ::= EXCLUDE frame_exclude(B) . {
A = 250025; 
p_cov_map->log_edge_cov_map(B, A); 
}

%type frame_exclude {unsigned int}
frame_exclude(A) ::= NO OTHERS .   {
A = 220305; 
}

frame_exclude(A) ::= CURRENT ROW . {
A = 47599; 
}

frame_exclude(A) ::= GROUP|TIES .  {
A = 225690; 
}

%type window_clause {unsigned int}
window_clause(A) ::= WINDOW windowdefn_list(B) . {
A = 167714; 
p_cov_map->log_edge_cov_map(B, A); 
}

filter_over(A) ::= filter_clause(B) over_clause(C) . {
A = 142268; 
p_cov_map->log_edge_cov_map(B, A); 
p_cov_map->log_edge_cov_map(C, A); 
}

filter_over(A) ::= over_clause(B) . {
A = 113984; 
p_cov_map->log_edge_cov_map(B, A); 
}

filter_over(A) ::= filter_clause(B) . {
A = 133640; 
p_cov_map->log_edge_cov_map(B, A); 
}

over_clause(A) ::= OVER LP window(B) RP . {
A = 50638; 
p_cov_map->log_edge_cov_map(B, A); 
}

over_clause(A) ::= OVER nm(B) . {
A = 248138; 
p_cov_map->log_edge_cov_map(B, A); 
}

filter_clause(A) ::= FILTER LP WHERE expr(B) RP .  {
A = 167040; 
p_cov_map->log_edge_cov_map(B, A); 
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
