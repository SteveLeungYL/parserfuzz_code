
// All token codes are small integers with #defines that begin with "TK_"
%token_prefix TKIR_

// The type of the data attached to each token is Token.  This is also the
// default type for non-terminals.
//
%token_type {const char*}
%default_type {void*}

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

input ::= cmdlist . {
p_cov_map->log_cov_map(24469); 
}

cmdlist ::= cmdlist ecmd . {
p_cov_map->log_cov_map(87152); 
}

cmdlist ::= ecmd . {
p_cov_map->log_cov_map(109555); 
}

ecmd ::= SEMI . {
p_cov_map->log_cov_map(247624); 
}

ecmd ::= cmdx SEMI . {
p_cov_map->log_cov_map(138040); 
}

ecmd ::= explain cmdx SEMI .       {
p_cov_map->log_cov_map(132910); 
}

explain ::= EXPLAIN .              {
p_cov_map->log_cov_map(28108); 
}

explain ::= EXPLAIN QUERY PLAN .   {
p_cov_map->log_cov_map(206249); 
}

cmdx ::= cmd .           {
p_cov_map->log_cov_map(15075); 
}

cmd ::= BEGIN transtype trans_opt .  {
p_cov_map->log_cov_map(231221); 
}

trans_opt ::= . {
p_cov_map->log_cov_map(174123); 
}

trans_opt ::= TRANSACTION . {
p_cov_map->log_cov_map(95109); 
}

trans_opt ::= TRANSACTION nm . {
p_cov_map->log_cov_map(11577); 
}

%type transtype {IR*}
transtype ::= .             {
p_cov_map->log_cov_map(11062); 
}

transtype ::= DEFERRED .  {
p_cov_map->log_cov_map(39908); 
}

transtype ::= IMMEDIATE . {
p_cov_map->log_cov_map(6445); 
}

transtype ::= EXCLUSIVE . {
p_cov_map->log_cov_map(101781); 
}

cmd ::= COMMIT|END trans_opt .   {
p_cov_map->log_cov_map(253610); 
}

cmd ::= ROLLBACK trans_opt .     {
p_cov_map->log_cov_map(68756); 
}

savepoint_opt ::= SAVEPOINT . {
p_cov_map->log_cov_map(151411); 
}

savepoint_opt ::= . {
p_cov_map->log_cov_map(232889); 
}

cmd ::= SAVEPOINT nm . {
p_cov_map->log_cov_map(198732); 
}

cmd ::= RELEASE savepoint_opt nm . {
p_cov_map->log_cov_map(44043); 
}

cmd ::= ROLLBACK trans_opt TO savepoint_opt nm . {
p_cov_map->log_cov_map(158412); 
}

cmd ::= create_table create_table_args . {
p_cov_map->log_cov_map(153119); 
}

create_table ::= createkw temp TABLE ifnotexists nm dbnm . {
p_cov_map->log_cov_map(78875); 
}

createkw ::= CREATE .  {
p_cov_map->log_cov_map(259008); 
}

%type ifnotexists {IR*}
ifnotexists ::= .              {
p_cov_map->log_cov_map(219075); 
}

ifnotexists ::= IF NOT EXISTS . {
p_cov_map->log_cov_map(6787); 
}

%type temp {IR*}
temp ::= TEMP .  {
p_cov_map->log_cov_map(136204); 
}

temp ::= .      {
p_cov_map->log_cov_map(107921); 
}

create_table_args ::= LP columnlist conslist_opt RP table_option_set . {
p_cov_map->log_cov_map(206051); 
}

create_table_args ::= AS select . {
p_cov_map->log_cov_map(68468); 
}

%type table_option_set {IR*}
%type table_option {IR*}
table_option_set ::= .    {
p_cov_map->log_cov_map(49740); 
}

table_option_set ::= table_option . {
p_cov_map->log_cov_map(235576); 
}

table_option_set ::= table_option_set COMMA table_option . {
p_cov_map->log_cov_map(63505); 
}

table_option ::= WITHOUT nm . {
p_cov_map->log_cov_map(104718); 
}

table_option ::= nm . {
p_cov_map->log_cov_map(216838); 
}

columnlist ::= columnlist COMMA columnname carglist . {
p_cov_map->log_cov_map(222009); 
}

columnlist ::= columnname carglist . {
p_cov_map->log_cov_map(60185); 
}

columnname ::= nm typetoken . {
p_cov_map->log_cov_map(197865); 
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
nm ::= idj . {
p_cov_map->log_cov_map(48250); 
}

nm ::= STRING . {
p_cov_map->log_cov_map(244807); 
}

%type typetoken {IR*}
typetoken ::= .   {
p_cov_map->log_cov_map(204296); 
}

typetoken ::= typename . {
p_cov_map->log_cov_map(143314); 
}

typetoken ::= typename LP signed RP . {
p_cov_map->log_cov_map(110341); 
}

typetoken ::= typename LP signed COMMA signed RP . {
p_cov_map->log_cov_map(37197); 
}

%type typename {IR*}
typename ::= ids . {
p_cov_map->log_cov_map(102655); 
}

typename ::= typename ids . {
p_cov_map->log_cov_map(122327); 
}

signed ::= plus_num . {
p_cov_map->log_cov_map(38614); 
}

signed ::= minus_num . {
p_cov_map->log_cov_map(207905); 
}

%type scanpt {IR*}
scanpt ::= . {
p_cov_map->log_cov_map(246873); 
}

scantok ::= . {
p_cov_map->log_cov_map(207565); 
}

carglist ::= carglist ccons . {
p_cov_map->log_cov_map(234794); 
}

carglist ::= . {
p_cov_map->log_cov_map(169203); 
}

ccons ::= CONSTRAINT nm .           {
p_cov_map->log_cov_map(87764); 
}

ccons ::= DEFAULT scantok term . {
p_cov_map->log_cov_map(3429); 
}

ccons ::= DEFAULT LP expr RP . {
p_cov_map->log_cov_map(151964); 
}

ccons ::= DEFAULT PLUS scantok term . {
p_cov_map->log_cov_map(79626); 
}

ccons ::= DEFAULT MINUS scantok term . {
p_cov_map->log_cov_map(186111); 
}

ccons ::= DEFAULT scantok id .       {
p_cov_map->log_cov_map(63903); 
}

ccons ::= NULL onconf . {
p_cov_map->log_cov_map(96609); 
}

ccons ::= NOT NULL onconf .    {
p_cov_map->log_cov_map(53311); 
}

ccons ::= PRIMARY KEY sortorder onconf autoinc . {
p_cov_map->log_cov_map(11600); 
}

ccons ::= UNIQUE onconf .      {
p_cov_map->log_cov_map(228633); 
}

ccons ::= CHECK LP expr RP .  {
p_cov_map->log_cov_map(90075); 
}

ccons ::= REFERENCES nm eidlist_opt refargs . {
p_cov_map->log_cov_map(182978); 
}

ccons ::= defer_subclause .    {
p_cov_map->log_cov_map(5881); 
}

ccons ::= COLLATE ids .        {
p_cov_map->log_cov_map(39104); 
}

ccons ::= GENERATED ALWAYS AS generated . {
p_cov_map->log_cov_map(219000); 
}

ccons ::= AS generated . {
p_cov_map->log_cov_map(113763); 
}

generated ::= LP expr RP .          {
p_cov_map->log_cov_map(162691); 
}

generated ::= LP expr RP ID . {
p_cov_map->log_cov_map(101052); 
}

%type autoinc {IR*}
autoinc ::= .          {
p_cov_map->log_cov_map(6904); 
}

autoinc ::= AUTOINCR .  {
p_cov_map->log_cov_map(77541); 
}

%type refargs {IR*}
refargs ::= .                  {
p_cov_map->log_cov_map(19247); 
}

refargs ::= refargs refarg . {
p_cov_map->log_cov_map(251425); 
}

%type refarg {IR*}
refarg ::= MATCH nm .              {
p_cov_map->log_cov_map(99145); 
}

refarg ::= ON INSERT refact .      {
p_cov_map->log_cov_map(28175); 
}

refarg ::= ON DELETE refact .   {
p_cov_map->log_cov_map(74159); 
}

refarg ::= ON UPDATE refact .   {
p_cov_map->log_cov_map(118316); 
}

%type refact {IR*}
refact ::= SET NULL .              {
p_cov_map->log_cov_map(186063); 
}

refact ::= SET DEFAULT .           {
p_cov_map->log_cov_map(258250); 
}

refact ::= CASCADE .               {
p_cov_map->log_cov_map(142666); 
}

refact ::= RESTRICT .              {
p_cov_map->log_cov_map(64248); 
}

refact ::= NO ACTION .             {
p_cov_map->log_cov_map(79461); 
}

%type defer_subclause {IR*}
defer_subclause ::= NOT DEFERRABLE init_deferred_pred_opt .     {
p_cov_map->log_cov_map(39098); 
}

defer_subclause ::= DEFERRABLE init_deferred_pred_opt .      {
p_cov_map->log_cov_map(40396); 
}

%type init_deferred_pred_opt {IR*}
init_deferred_pred_opt ::= .                       {
p_cov_map->log_cov_map(159989); 
}

init_deferred_pred_opt ::= INITIALLY DEFERRED .     {
p_cov_map->log_cov_map(169609); 
}

init_deferred_pred_opt ::= INITIALLY IMMEDIATE .    {
p_cov_map->log_cov_map(70874); 
}

conslist_opt ::= .                         {
p_cov_map->log_cov_map(124608); 
}

conslist_opt ::= COMMA conslist . {
p_cov_map->log_cov_map(231379); 
}

conslist ::= conslist tconscomma tcons . {
p_cov_map->log_cov_map(175537); 
}

conslist ::= tcons . {
p_cov_map->log_cov_map(48587); 
}

tconscomma ::= COMMA .            {
p_cov_map->log_cov_map(64419); 
}

tconscomma ::= . {
p_cov_map->log_cov_map(129939); 
}

tcons ::= CONSTRAINT nm .      {
p_cov_map->log_cov_map(137110); 
}

tcons ::= PRIMARY KEY LP sortlist autoinc RP onconf . {
p_cov_map->log_cov_map(257006); 
}

tcons ::= UNIQUE LP sortlist RP onconf . {
p_cov_map->log_cov_map(66198); 
}

tcons ::= CHECK LP expr RP onconf . {
p_cov_map->log_cov_map(18550); 
}

tcons ::= FOREIGN KEY LP eidlist RP REFERENCES nm eidlist_opt refargs defer_subclause_opt . {
p_cov_map->log_cov_map(210957); 
}

%type defer_subclause_opt {IR*}
defer_subclause_opt ::= .                    {
p_cov_map->log_cov_map(220932); 
}

defer_subclause_opt ::= defer_subclause . {
p_cov_map->log_cov_map(254843); 
}

%type onconf {IR*}
%type orconf {IR*}
%type resolvetype {IR*}
onconf ::= .                              {
p_cov_map->log_cov_map(157840); 
}

onconf ::= ON CONFLICT resolvetype .    {
p_cov_map->log_cov_map(230574); 
}

orconf ::= .                              {
p_cov_map->log_cov_map(230867); 
}

orconf ::= OR resolvetype .             {
p_cov_map->log_cov_map(88296); 
}

resolvetype ::= raisetype . {
p_cov_map->log_cov_map(232219); 
}

resolvetype ::= IGNORE .                   {
p_cov_map->log_cov_map(75731); 
}

resolvetype ::= REPLACE .                  {
p_cov_map->log_cov_map(132514); 
}

cmd ::= DROP TABLE ifexists fullname . {
p_cov_map->log_cov_map(99406); 
}

%type ifexists {IR*}
ifexists ::= IF EXISTS .   {
p_cov_map->log_cov_map(242499); 
}

ifexists ::= .            {
p_cov_map->log_cov_map(210631); 
}

cmd ::= createkw temp VIEW ifnotexists nm dbnm eidlist_opt AS select . {
p_cov_map->log_cov_map(183360); 
}

cmd ::= DROP VIEW ifexists fullname . {
p_cov_map->log_cov_map(147258); 
}

cmd ::= select .  {
p_cov_map->log_cov_map(100010); 
}

%type select {IR*}
%type selectnowith {IR*}
%type oneselect {IR*}
select ::= WITH wqlist selectnowith . {
p_cov_map->log_cov_map(251393); 
}

select ::= WITH RECURSIVE wqlist selectnowith . {
p_cov_map->log_cov_map(175055); 
}

select ::= selectnowith . {
p_cov_map->log_cov_map(34483); 
}

selectnowith ::= oneselect . {
p_cov_map->log_cov_map(119051); 
}

selectnowith ::= selectnowith multiselect_op oneselect .  {
p_cov_map->log_cov_map(88221); 
}

%type multiselect_op {IR*}
multiselect_op ::= UNION .             {
p_cov_map->log_cov_map(236352); 
}

multiselect_op ::= UNION ALL .             {
p_cov_map->log_cov_map(49282); 
}

multiselect_op ::= EXCEPT|INTERSECT .  {
p_cov_map->log_cov_map(191056); 
}

oneselect ::= SELECT distinct selcollist from where_opt groupby_opt having_opt orderby_opt limit_opt . {
p_cov_map->log_cov_map(190603); 
}

oneselect ::= SELECT distinct selcollist from where_opt groupby_opt having_opt window_clause orderby_opt limit_opt . {
p_cov_map->log_cov_map(178650); 
}

oneselect ::= values . {
p_cov_map->log_cov_map(54198); 
}

%type values {IR*}
values ::= VALUES LP nexprlist RP . {
p_cov_map->log_cov_map(149564); 
}

values ::= values COMMA LP nexprlist RP . {
p_cov_map->log_cov_map(6288); 
}

%type distinct {IR*}
distinct ::= DISTINCT .   {
p_cov_map->log_cov_map(9891); 
}

distinct ::= ALL .        {
p_cov_map->log_cov_map(63772); 
}

distinct ::= .           {
p_cov_map->log_cov_map(248888); 
}

%type selcollist {IR*}
%type sclp {IR*}
sclp ::= selcollist COMMA . {
p_cov_map->log_cov_map(178391); 
}

sclp ::= .                                {
p_cov_map->log_cov_map(150276); 
}

selcollist ::= sclp scanpt expr scanpt as .     {
p_cov_map->log_cov_map(234228); 
}

selcollist ::= sclp scanpt STAR . {
p_cov_map->log_cov_map(14473); 
}

selcollist ::= sclp scanpt nm DOT STAR . {
p_cov_map->log_cov_map(132646); 
}

%type as {IR*}
as ::= AS nm .    {
p_cov_map->log_cov_map(105591); 
}

as ::= ids . {
p_cov_map->log_cov_map(76027); 
}

as ::= .            {
p_cov_map->log_cov_map(911); 
}

%type seltablist {IR*}
%type stl_prefix {IR*}
%type from {IR*}
from ::= .                {
p_cov_map->log_cov_map(165220); 
}

from ::= FROM seltablist . {
p_cov_map->log_cov_map(61030); 
}

stl_prefix ::= seltablist joinop .    {
p_cov_map->log_cov_map(209050); 
}

stl_prefix ::= .                           {
p_cov_map->log_cov_map(208855); 
}

seltablist ::= stl_prefix nm dbnm as on_using . {
p_cov_map->log_cov_map(207136); 
}

seltablist ::= stl_prefix nm dbnm as indexed_by on_using . {
p_cov_map->log_cov_map(1945); 
}

seltablist ::= stl_prefix nm dbnm LP exprlist RP as on_using . {
p_cov_map->log_cov_map(133552); 
}

seltablist ::= stl_prefix LP select RP as on_using . {
p_cov_map->log_cov_map(152263); 
}

seltablist ::= stl_prefix LP seltablist RP as on_using . {
p_cov_map->log_cov_map(199813); 
}

%type dbnm {IR*}
dbnm ::= .          {
p_cov_map->log_cov_map(89547); 
}

dbnm ::= DOT nm . {
p_cov_map->log_cov_map(167189); 
}

%type fullname {IR*}
fullname ::= nm .  {
p_cov_map->log_cov_map(150842); 
}

fullname ::= nm DOT nm . {
p_cov_map->log_cov_map(174402); 
}

%type xfullname {IR*}
xfullname ::= nm .  {
p_cov_map->log_cov_map(178627); 
}

xfullname ::= nm DOT nm .  {
p_cov_map->log_cov_map(258354); 
}

xfullname ::= nm DOT nm AS nm .  {
p_cov_map->log_cov_map(184486); 
}

xfullname ::= nm AS nm . {
p_cov_map->log_cov_map(184408); 
}

%type joinop {IR*}
joinop ::= COMMA|JOIN .              {
p_cov_map->log_cov_map(11779); 
}

joinop ::= JOIN_KW JOIN . {
p_cov_map->log_cov_map(167693); 
}

joinop ::= JOIN_KW nm JOIN . {
p_cov_map->log_cov_map(19381); 
}

joinop ::= JOIN_KW nm nm JOIN . {
p_cov_map->log_cov_map(107894); 
}

%type on_using {IR*}
on_using ::= ON expr .            {
p_cov_map->log_cov_map(147038); 
}

on_using ::= USING LP idlist RP . {
p_cov_map->log_cov_map(55244); 
}

on_using ::= .                  [OR]{
p_cov_map->log_cov_map(230359); 
}

%type indexed_opt {IR*}
%type indexed_by  {IR*}
indexed_opt ::= .                 {
p_cov_map->log_cov_map(220557); 
}

indexed_opt ::= indexed_by . {
p_cov_map->log_cov_map(81471); 
}

indexed_by ::= INDEXED BY nm . {
p_cov_map->log_cov_map(260882); 
}

indexed_by ::= NOT INDEXED .      {
p_cov_map->log_cov_map(97657); 
}

%type orderby_opt {IR*}
%type sortlist {IR*}
orderby_opt ::= .                          {
p_cov_map->log_cov_map(257305); 
}

orderby_opt ::= ORDER BY sortlist .      {
p_cov_map->log_cov_map(251454); 
}

sortlist ::= sortlist COMMA expr sortorder nulls . {
p_cov_map->log_cov_map(235807); 
}

sortlist ::= expr sortorder nulls . {
p_cov_map->log_cov_map(207976); 
}

%type sortorder {IR*}
sortorder ::= ASC .           {
p_cov_map->log_cov_map(238798); 
}

sortorder ::= DESC .          {
p_cov_map->log_cov_map(190060); 
}

sortorder ::= .              {
p_cov_map->log_cov_map(25335); 
}

%type nulls {IR*}
nulls ::= NULLS FIRST .       {
p_cov_map->log_cov_map(174243); 
}

nulls ::= NULLS LAST .        {
p_cov_map->log_cov_map(77562); 
}

nulls ::= .                  {
p_cov_map->log_cov_map(126822); 
}

%type groupby_opt {IR*}
groupby_opt ::= .                      {
p_cov_map->log_cov_map(22430); 
}

groupby_opt ::= GROUP BY nexprlist . {
p_cov_map->log_cov_map(219409); 
}

%type having_opt {IR*}
having_opt ::= .                {
p_cov_map->log_cov_map(145496); 
}

having_opt ::= HAVING expr .  {
p_cov_map->log_cov_map(150437); 
}

%type limit_opt {IR*}
limit_opt ::= .       {
p_cov_map->log_cov_map(239462); 
}

limit_opt ::= LIMIT expr . {
p_cov_map->log_cov_map(130335); 
}

limit_opt ::= LIMIT expr OFFSET expr . {
p_cov_map->log_cov_map(190471); 
}

limit_opt ::= LIMIT expr COMMA expr . {
p_cov_map->log_cov_map(237994); 
}

cmd ::= with DELETE FROM xfullname indexed_opt where_opt_ret orderby_opt limit_opt . {
p_cov_map->log_cov_map(221286); 
}

%type where_opt {IR*}
%type where_opt_ret {IR*}
where_opt ::= .                    {
p_cov_map->log_cov_map(41044); 
}

where_opt ::= WHERE expr .       {
p_cov_map->log_cov_map(89712); 
}

where_opt_ret ::= .                                      {
p_cov_map->log_cov_map(13082); 
}

where_opt_ret ::= WHERE expr .                         {
p_cov_map->log_cov_map(50723); 
}

where_opt_ret ::= RETURNING selcollist .               {
p_cov_map->log_cov_map(127131); 
}

where_opt_ret ::= WHERE expr RETURNING selcollist . {
p_cov_map->log_cov_map(142237); 
}

cmd ::= with UPDATE orconf xfullname indexed_opt SET setlist from where_opt_ret orderby_opt limit_opt .  {
p_cov_map->log_cov_map(21927); 
}

%type setlist {IR*}
setlist ::= setlist COMMA nm EQ expr . {
p_cov_map->log_cov_map(55711); 
}

setlist ::= setlist COMMA LP idlist RP EQ expr . {
p_cov_map->log_cov_map(216508); 
}

setlist ::= nm EQ expr . {
p_cov_map->log_cov_map(251737); 
}

setlist ::= LP idlist RP EQ expr . {
p_cov_map->log_cov_map(87600); 
}

cmd ::= with insert_cmd INTO xfullname idlist_opt select upsert . {
p_cov_map->log_cov_map(59052); 
}

cmd ::= with insert_cmd INTO xfullname idlist_opt DEFAULT VALUES returning . {
p_cov_map->log_cov_map(70137); 
}

%type upsert {IR*}
upsert ::= . {
p_cov_map->log_cov_map(24405); 
}

upsert ::= RETURNING selcollist .  {
p_cov_map->log_cov_map(98663); 
}

upsert ::= ON CONFLICT LP sortlist RP where_opt DO UPDATE SET setlist where_opt upsert . {
p_cov_map->log_cov_map(67849); 
}

upsert ::= ON CONFLICT LP sortlist RP where_opt DO NOTHING upsert . {
p_cov_map->log_cov_map(242035); 
}

upsert ::= ON CONFLICT DO NOTHING returning . {
p_cov_map->log_cov_map(215497); 
}

upsert ::= ON CONFLICT DO UPDATE SET setlist where_opt returning . {
p_cov_map->log_cov_map(191732); 
}

returning ::= RETURNING selcollist .  {
p_cov_map->log_cov_map(121006); 
}

returning ::= . {
p_cov_map->log_cov_map(136921); 
}

%type insert_cmd {IR*}
insert_cmd ::= INSERT orconf .   {
p_cov_map->log_cov_map(182543); 
}

insert_cmd ::= REPLACE .            {
p_cov_map->log_cov_map(219123); 
}

%type idlist_opt {IR*}
%type idlist {IR*}
idlist_opt ::= .                       {
p_cov_map->log_cov_map(239283); 
}

idlist_opt ::= LP idlist RP .    {
p_cov_map->log_cov_map(147242); 
}

idlist ::= idlist COMMA nm . {
p_cov_map->log_cov_map(89833); 
}

idlist ::= nm . {
p_cov_map->log_cov_map(156877); 
}

%type expr {IR*}
%type term {IR*}
expr ::= term . {
p_cov_map->log_cov_map(150039); 
}

expr ::= LP expr RP . {
p_cov_map->log_cov_map(55447); 
}

expr ::= idj .          {
p_cov_map->log_cov_map(65572); 
}

expr ::= nm DOT nm . {
p_cov_map->log_cov_map(117877); 
}

expr ::= nm DOT nm DOT nm . {
p_cov_map->log_cov_map(211265); 
}

term ::= NULL|FLOAT|BLOB . {
p_cov_map->log_cov_map(205467); 
}

term ::= STRING .          {
p_cov_map->log_cov_map(206590); 
}

term ::= INTEGER . {
p_cov_map->log_cov_map(200737); 
}

expr ::= VARIABLE .     {
p_cov_map->log_cov_map(105128); 
}

expr ::= expr COLLATE ids . {
p_cov_map->log_cov_map(147743); 
}

expr ::= CAST LP expr AS typetoken RP . {
p_cov_map->log_cov_map(200222); 
}

expr ::= idj LP distinct exprlist RP . {
p_cov_map->log_cov_map(244306); 
}

expr ::= idj LP STAR RP . {
p_cov_map->log_cov_map(71312); 
}

expr ::= idj LP distinct exprlist RP filter_over . {
p_cov_map->log_cov_map(208667); 
}

expr ::= idj LP STAR RP filter_over . {
p_cov_map->log_cov_map(191327); 
}

term ::= CTIME_KW . {
p_cov_map->log_cov_map(54085); 
}

expr ::= LP nexprlist COMMA expr RP . {
p_cov_map->log_cov_map(142999); 
}

expr ::= expr AND expr .        {
p_cov_map->log_cov_map(169415); 
}

expr ::= expr OR expr .     {
p_cov_map->log_cov_map(158524); 
}

expr ::= expr LT|GT|GE|LE expr . {
p_cov_map->log_cov_map(46724); 
}

expr ::= expr EQ|NE expr .  {
p_cov_map->log_cov_map(182285); 
}

expr ::= expr BITAND|BITOR|LSHIFT|RSHIFT expr . {
p_cov_map->log_cov_map(96507); 
}

expr ::= expr PLUS|MINUS expr . {
p_cov_map->log_cov_map(117092); 
}

expr ::= expr STAR|SLASH|REM expr . {
p_cov_map->log_cov_map(248736); 
}

expr ::= expr CONCAT expr . {
p_cov_map->log_cov_map(187598); 
}

%type likeop {IR*}
likeop ::= LIKE_KW|MATCH . {
p_cov_map->log_cov_map(206846); 
}

likeop ::= NOT LIKE_KW|MATCH . {
p_cov_map->log_cov_map(131129); 
}

expr ::= expr likeop expr .   [LIKE_KW] {
p_cov_map->log_cov_map(138345); 
}

expr ::= expr likeop expr ESCAPE expr .   [LIKE_KW] {
p_cov_map->log_cov_map(117424); 
}

expr ::= expr ISNULL|NOTNULL .   {
p_cov_map->log_cov_map(109219); 
}

expr ::= expr NOT NULL .    {
p_cov_map->log_cov_map(5389); 
}

expr ::= expr IS expr .     {
p_cov_map->log_cov_map(95614); 
}

expr ::= expr IS NOT expr . {
p_cov_map->log_cov_map(47698); 
}

expr ::= expr IS NOT DISTINCT FROM expr .     {
p_cov_map->log_cov_map(33210); 
}

expr ::= expr IS DISTINCT FROM expr . {
p_cov_map->log_cov_map(106322); 
}

expr ::= NOT expr .  {
p_cov_map->log_cov_map(16004); 
}

expr ::= BITNOT expr . {
p_cov_map->log_cov_map(110077); 
}

expr ::= PLUS|MINUS expr .  [BITNOT]{
p_cov_map->log_cov_map(14392); 
}

expr ::= expr PTR expr . {
p_cov_map->log_cov_map(47110); 
}

%type between_op {IR*}
between_op ::= BETWEEN .     {
p_cov_map->log_cov_map(15561); 
}

between_op ::= NOT BETWEEN . {
p_cov_map->log_cov_map(89522); 
}

expr ::= expr between_op expr AND expr .  [BETWEEN]{
p_cov_map->log_cov_map(37779); 
}

in_op ::= IN .      {
p_cov_map->log_cov_map(51055); 
}

in_op ::= NOT IN .  {
p_cov_map->log_cov_map(198617); 
}

expr ::= expr in_op LP exprlist RP .  [IN]{
p_cov_map->log_cov_map(206101); 
}

expr ::= LP select RP . {
p_cov_map->log_cov_map(25782); 
}

expr ::= expr in_op LP select RP .   [IN]{
p_cov_map->log_cov_map(203282); 
}

expr ::= expr in_op nm dbnm paren_exprlist .  [IN]{
p_cov_map->log_cov_map(208988); 
}

expr ::= EXISTS LP select RP . {
p_cov_map->log_cov_map(213579); 
}

expr ::= CASE case_operand case_exprlist case_else END . {
p_cov_map->log_cov_map(33072); 
}

%type case_exprlist {IR*}
case_exprlist ::= case_exprlist WHEN expr THEN expr . {
p_cov_map->log_cov_map(64839); 
}

case_exprlist ::= WHEN expr THEN expr . {
p_cov_map->log_cov_map(8315); 
}

%type case_else {IR*}
case_else ::= ELSE expr .         {
p_cov_map->log_cov_map(211458); 
}

case_else ::= .                     {
p_cov_map->log_cov_map(162762); 
}

%type case_operand {IR*}
case_operand ::= expr .            {
p_cov_map->log_cov_map(219834); 
}

case_operand ::= .                   {
p_cov_map->log_cov_map(192178); 
}

%type exprlist {IR*}
%type nexprlist {IR*}
exprlist ::= nexprlist . {
p_cov_map->log_cov_map(158626); 
}

exprlist ::= .                            {
p_cov_map->log_cov_map(106055); 
}

nexprlist ::= nexprlist COMMA expr . {
p_cov_map->log_cov_map(199189); 
}

nexprlist ::= expr . {
p_cov_map->log_cov_map(17586); 
}

%type paren_exprlist {IR*}
paren_exprlist ::= .   {
p_cov_map->log_cov_map(187654); 
}

paren_exprlist ::= LP exprlist RP .  {
p_cov_map->log_cov_map(6263); 
}

cmd ::= createkw uniqueflag INDEX ifnotexists nm dbnm ON nm LP sortlist RP where_opt . {
p_cov_map->log_cov_map(259373); 
}

%type uniqueflag {IR*}
uniqueflag ::= UNIQUE .  {
p_cov_map->log_cov_map(88590); 
}

uniqueflag ::= .        {
p_cov_map->log_cov_map(47849); 
}

%type eidlist {IR*}
%type eidlist_opt {IR*}
eidlist_opt ::= .                         {
p_cov_map->log_cov_map(125463); 
}

eidlist_opt ::= LP eidlist RP .         {
p_cov_map->log_cov_map(168516); 
}

eidlist ::= eidlist COMMA nm collate sortorder .  {
p_cov_map->log_cov_map(91791); 
}

eidlist ::= nm collate sortorder . {
p_cov_map->log_cov_map(108937); 
}

%type collate {IR*}
collate ::= .              {
p_cov_map->log_cov_map(229116); 
}

collate ::= COLLATE ids .   {
p_cov_map->log_cov_map(98133); 
}

cmd ::= DROP INDEX ifexists fullname .   {
p_cov_map->log_cov_map(6019); 
}

%type vinto {IR*}
cmd ::= VACUUM vinto .                {
p_cov_map->log_cov_map(184605); 
}

cmd ::= VACUUM nm vinto .          {
p_cov_map->log_cov_map(118450); 
}

vinto ::= INTO expr .              {
p_cov_map->log_cov_map(203532); 
}

vinto ::= .                          {
p_cov_map->log_cov_map(52182); 
}

cmd ::= PRAGMA nm dbnm .                {
p_cov_map->log_cov_map(168336); 
}

cmd ::= PRAGMA nm dbnm EQ nmnum .    {
p_cov_map->log_cov_map(230305); 
}

cmd ::= PRAGMA nm dbnm LP nmnum RP . {
p_cov_map->log_cov_map(5628); 
}

cmd ::= PRAGMA nm dbnm EQ minus_num . {
p_cov_map->log_cov_map(22229); 
}

cmd ::= PRAGMA nm dbnm LP minus_num RP . {
p_cov_map->log_cov_map(181281); 
}

nmnum ::= plus_num . {
p_cov_map->log_cov_map(203695); 
}

nmnum ::= nm . {
p_cov_map->log_cov_map(34917); 
}

nmnum ::= ON . {
p_cov_map->log_cov_map(183064); 
}

nmnum ::= DELETE . {
p_cov_map->log_cov_map(182480); 
}

nmnum ::= DEFAULT . {
p_cov_map->log_cov_map(217191); 
}

%token_class number INTEGER|FLOAT.
plus_num ::= PLUS number .       {
p_cov_map->log_cov_map(38337); 
}

plus_num ::= number . {
p_cov_map->log_cov_map(124391); 
}

minus_num ::= MINUS number .     {
p_cov_map->log_cov_map(249856); 
}

cmd ::= createkw trigger_decl BEGIN trigger_cmd_list END . {
p_cov_map->log_cov_map(203536); 
}

trigger_decl ::= temp TRIGGER ifnotexists nm dbnm trigger_time trigger_event ON fullname foreach_clause when_clause . {
p_cov_map->log_cov_map(203043); 
}

%type trigger_time {IR*}
trigger_time ::= BEFORE|AFTER .  {
p_cov_map->log_cov_map(209226); 
}

trigger_time ::= INSTEAD OF .  {
p_cov_map->log_cov_map(203060); 
}

trigger_time ::= .            {
p_cov_map->log_cov_map(163340); 
}

%type trigger_event {IR*}
trigger_event ::= DELETE|INSERT .   {
p_cov_map->log_cov_map(54301); 
}

trigger_event ::= UPDATE .          {
p_cov_map->log_cov_map(89337); 
}

trigger_event ::= UPDATE OF idlist . {
p_cov_map->log_cov_map(32137); 
}

foreach_clause ::= . {
p_cov_map->log_cov_map(230846); 
}

foreach_clause ::= FOR EACH ROW . {
p_cov_map->log_cov_map(199606); 
}

%type when_clause {IR*}
when_clause ::= .             {
p_cov_map->log_cov_map(70780); 
}

when_clause ::= WHEN expr . {
p_cov_map->log_cov_map(135195); 
}

%type trigger_cmd_list {IR*}
trigger_cmd_list ::= trigger_cmd_list trigger_cmd SEMI . {
p_cov_map->log_cov_map(181073); 
}

trigger_cmd_list ::= trigger_cmd SEMI . {
p_cov_map->log_cov_map(66830); 
}

%type trnm {IR*}
trnm ::= nm . {
p_cov_map->log_cov_map(175793); 
}

trnm ::= nm DOT nm . {
p_cov_map->log_cov_map(86907); 
}

tridxby ::= . {
p_cov_map->log_cov_map(2235); 
}

tridxby ::= INDEXED BY nm . {
p_cov_map->log_cov_map(195005); 
}

tridxby ::= NOT INDEXED . {
p_cov_map->log_cov_map(32476); 
}

%type trigger_cmd {IR*}
trigger_cmd ::= UPDATE orconf trnm tridxby SET setlist from where_opt scanpt .  {
p_cov_map->log_cov_map(231285); 
}

trigger_cmd ::= scanpt insert_cmd INTO trnm idlist_opt select upsert scanpt . {
p_cov_map->log_cov_map(155252); 
}

trigger_cmd ::= DELETE FROM trnm tridxby where_opt scanpt . {
p_cov_map->log_cov_map(116812); 
}

trigger_cmd ::= scanpt select scanpt . {
p_cov_map->log_cov_map(94819); 
}

expr ::= RAISE LP IGNORE RP .  {
p_cov_map->log_cov_map(132055); 
}

expr ::= RAISE LP raisetype COMMA nm RP .  {
p_cov_map->log_cov_map(248601); 
}

%type raisetype {IR*}
raisetype ::= ROLLBACK .  {
p_cov_map->log_cov_map(173085); 
}

raisetype ::= ABORT .     {
p_cov_map->log_cov_map(55323); 
}

raisetype ::= FAIL .      {
p_cov_map->log_cov_map(96272); 
}

cmd ::= DROP TRIGGER ifexists fullname . {
p_cov_map->log_cov_map(207399); 
}

cmd ::= ATTACH database_kw_opt expr AS expr key_opt . {
p_cov_map->log_cov_map(46062); 
}

cmd ::= DETACH database_kw_opt expr . {
p_cov_map->log_cov_map(151484); 
}

%type key_opt {IR*}
key_opt ::= .                     {
p_cov_map->log_cov_map(92003); 
}

key_opt ::= KEY expr .          {
p_cov_map->log_cov_map(35035); 
}

database_kw_opt ::= DATABASE . {
p_cov_map->log_cov_map(151458); 
}

database_kw_opt ::= . {
p_cov_map->log_cov_map(170023); 
}

cmd ::= REINDEX .                {
p_cov_map->log_cov_map(121845); 
}

cmd ::= REINDEX nm dbnm .  {
p_cov_map->log_cov_map(92301); 
}

cmd ::= ANALYZE .                {
p_cov_map->log_cov_map(157021); 
}

cmd ::= ANALYZE nm dbnm .  {
p_cov_map->log_cov_map(101116); 
}

cmd ::= ALTER TABLE fullname RENAME TO nm . {
p_cov_map->log_cov_map(49625); 
}

cmd ::= ALTER TABLE add_column_fullname ADD kwcolumn_opt columnname carglist . {
p_cov_map->log_cov_map(101683); 
}

cmd ::= ALTER TABLE fullname DROP kwcolumn_opt nm . {
p_cov_map->log_cov_map(192384); 
}

add_column_fullname ::= fullname . {
p_cov_map->log_cov_map(153347); 
}

cmd ::= ALTER TABLE fullname RENAME kwcolumn_opt nm TO nm . {
p_cov_map->log_cov_map(133643); 
}

kwcolumn_opt ::= . {
p_cov_map->log_cov_map(65158); 
}

kwcolumn_opt ::= COLUMNKW . {
p_cov_map->log_cov_map(110657); 
}

cmd ::= create_vtab .                       {
p_cov_map->log_cov_map(151456); 
}

cmd ::= create_vtab LP vtabarglist RP .  {
p_cov_map->log_cov_map(135534); 
}

create_vtab ::= createkw VIRTUAL TABLE ifnotexists nm dbnm USING nm . {
p_cov_map->log_cov_map(137075); 
}

vtabarglist ::= vtabarg . {
p_cov_map->log_cov_map(210476); 
}

vtabarglist ::= vtabarglist COMMA vtabarg . {
p_cov_map->log_cov_map(132227); 
}

vtabarg ::= .                       {
p_cov_map->log_cov_map(129553); 
}

vtabarg ::= vtabarg vtabargtoken . {
p_cov_map->log_cov_map(193265); 
}

vtabargtoken ::= ANY .            {
p_cov_map->log_cov_map(174490); 
}

vtabargtoken ::= lp anylist RP .  {
p_cov_map->log_cov_map(55824); 
}

lp ::= LP .                       {
p_cov_map->log_cov_map(143235); 
}

anylist ::= . {
p_cov_map->log_cov_map(260190); 
}

anylist ::= anylist LP anylist RP . {
p_cov_map->log_cov_map(99339); 
}

anylist ::= anylist ANY . {
p_cov_map->log_cov_map(111575); 
}

%type wqlist {IR*}
%type wqitem {IR*}
with ::= . {
p_cov_map->log_cov_map(31145); 
}

with ::= WITH wqlist .              {
p_cov_map->log_cov_map(36151); 
}

with ::= WITH RECURSIVE wqlist .    {
p_cov_map->log_cov_map(124543); 
}

%type wqas {IR*}
wqas ::= AS .                  {
p_cov_map->log_cov_map(155712); 
}

wqas ::= AS MATERIALIZED .     {
p_cov_map->log_cov_map(215485); 
}

wqas ::= AS NOT MATERIALIZED . {
p_cov_map->log_cov_map(101455); 
}

wqitem ::= nm eidlist_opt wqas LP select RP . {
p_cov_map->log_cov_map(150016); 
}

wqlist ::= wqitem . {
p_cov_map->log_cov_map(127996); 
}

wqlist ::= wqlist COMMA wqitem . {
p_cov_map->log_cov_map(143929); 
}

%type windowdefn_list {IR*}
windowdefn_list ::= windowdefn . {
p_cov_map->log_cov_map(117875); 
}

windowdefn_list ::= windowdefn_list COMMA windowdefn . {
p_cov_map->log_cov_map(35765); 
}

%type windowdefn {IR*}
windowdefn ::= nm AS LP window RP . {
p_cov_map->log_cov_map(107431); 
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
window ::= PARTITION BY nexprlist orderby_opt frame_opt . {
p_cov_map->log_cov_map(17314); 
}

window ::= nm PARTITION BY nexprlist orderby_opt frame_opt . {
p_cov_map->log_cov_map(220236); 
}

window ::= ORDER BY sortlist frame_opt . {
p_cov_map->log_cov_map(239139); 
}

window ::= nm ORDER BY sortlist frame_opt . {
p_cov_map->log_cov_map(177531); 
}

window ::= frame_opt . {
p_cov_map->log_cov_map(64472); 
}

window ::= nm frame_opt . {
p_cov_map->log_cov_map(114043); 
}

frame_opt ::= .                             {
p_cov_map->log_cov_map(129340); 
}

frame_opt ::= range_or_rows frame_bound_s frame_exclude_opt . {
p_cov_map->log_cov_map(235264); 
}

frame_opt ::= range_or_rows BETWEEN frame_bound_s AND frame_bound_e frame_exclude_opt . {
p_cov_map->log_cov_map(124579); 
}

range_or_rows ::= RANGE|ROWS|GROUPS .   {
p_cov_map->log_cov_map(145935); 
}

frame_bound_s ::= frame_bound .         {
p_cov_map->log_cov_map(192312); 
}

frame_bound_s ::= UNBOUNDED PRECEDING . {
p_cov_map->log_cov_map(14194); 
}

frame_bound_e ::= frame_bound .         {
p_cov_map->log_cov_map(36616); 
}

frame_bound_e ::= UNBOUNDED FOLLOWING . {
p_cov_map->log_cov_map(244616); 
}

frame_bound ::= expr PRECEDING|FOLLOWING . {
p_cov_map->log_cov_map(48560); 
}

frame_bound ::= CURRENT ROW .           {
p_cov_map->log_cov_map(211877); 
}

%type frame_exclude_opt {IR*}
frame_exclude_opt ::= . {
p_cov_map->log_cov_map(11688); 
}

frame_exclude_opt ::= EXCLUDE frame_exclude . {
p_cov_map->log_cov_map(125780); 
}

%type frame_exclude {IR*}
frame_exclude ::= NO OTHERS .   {
p_cov_map->log_cov_map(141916); 
}

frame_exclude ::= CURRENT ROW . {
p_cov_map->log_cov_map(70278); 
}

frame_exclude ::= GROUP|TIES .  {
p_cov_map->log_cov_map(205991); 
}

%type window_clause {IR*}
window_clause ::= WINDOW windowdefn_list . {
p_cov_map->log_cov_map(111366); 
}

filter_over ::= filter_clause over_clause . {
p_cov_map->log_cov_map(164437); 
}

filter_over ::= over_clause . {
p_cov_map->log_cov_map(243329); 
}

filter_over ::= filter_clause . {
p_cov_map->log_cov_map(54892); 
}

over_clause ::= OVER LP window RP . {
p_cov_map->log_cov_map(65724); 
}

over_clause ::= OVER nm . {
p_cov_map->log_cov_map(2212); 
}

filter_clause ::= FILTER LP WHERE expr RP .  {
p_cov_map->log_cov_map(41021); 
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
