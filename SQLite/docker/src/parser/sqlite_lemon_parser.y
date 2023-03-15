
// All token codes are small integers with #defines that begin with "TK_"
%token_prefix TKIR_

// The type of the data attached to each token is Token.  This is also the
// default type for non-terminals.
//
%token_type {const char*}
%default_type {IR*}

// An extra argument to the parse function for the parser, which is available
// to all actions.
%extra_argument {GramCovMap* p_cov_map}

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

input ::= cmdlist . {
p_cov_map->log_cov_map(239893); 
}

cmdlist ::= cmdlist ecmd . {
p_cov_map->log_cov_map(108263); 
}

cmdlist ::= ecmd . {
p_cov_map->log_cov_map(176099); 
}

ecmd ::= SEMI . {
p_cov_map->log_cov_map(68306); 
}

ecmd ::= cmdx SEMI . {
p_cov_map->log_cov_map(75711); 
}

ecmd ::= explain cmdx SEMI .       {
p_cov_map->log_cov_map(31733); 
}

explain ::= EXPLAIN .              {
p_cov_map->log_cov_map(222208); 
}

explain ::= EXPLAIN QUERY PLAN .   {
p_cov_map->log_cov_map(229205); 
}

cmdx ::= cmd .           {
p_cov_map->log_cov_map(223441); 
}

cmd ::= BEGIN transtype trans_opt .  {
p_cov_map->log_cov_map(228461); 
}

trans_opt ::= . {
p_cov_map->log_cov_map(5921); 
}

trans_opt ::= TRANSACTION . {
p_cov_map->log_cov_map(213721); 
}

trans_opt ::= TRANSACTION nm . {
p_cov_map->log_cov_map(147123); 
}

%type transtype {IR*}
transtype ::= .             {
p_cov_map->log_cov_map(105862); 
}

transtype ::= DEFERRED .  {
p_cov_map->log_cov_map(12200); 
}

transtype ::= IMMEDIATE . {
p_cov_map->log_cov_map(31335); 
}

transtype ::= EXCLUSIVE . {
p_cov_map->log_cov_map(30187); 
}

cmd ::= COMMIT|END trans_opt .   {
p_cov_map->log_cov_map(23480); 
}

cmd ::= ROLLBACK trans_opt .     {
p_cov_map->log_cov_map(23886); 
}

savepoint_opt ::= SAVEPOINT . {
p_cov_map->log_cov_map(45249); 
}

savepoint_opt ::= . {
p_cov_map->log_cov_map(5962); 
}

cmd ::= SAVEPOINT nm . {
p_cov_map->log_cov_map(136346); 
}

cmd ::= RELEASE savepoint_opt nm . {
p_cov_map->log_cov_map(259572); 
}

cmd ::= ROLLBACK trans_opt TO savepoint_opt nm . {
p_cov_map->log_cov_map(118733); 
}

cmd ::= create_table create_table_args . {
p_cov_map->log_cov_map(96608); 
}

create_table ::= createkw temp TABLE ifnotexists nm dbnm . {
p_cov_map->log_cov_map(136098); 
}

createkw ::= CREATE .  {
p_cov_map->log_cov_map(23695); 
}

%type ifnotexists {IR*}
ifnotexists ::= .              {
p_cov_map->log_cov_map(64391); 
}

ifnotexists ::= IF NOT EXISTS . {
p_cov_map->log_cov_map(162176); 
}

%type temp {IR*}
temp ::= TEMP .  {
p_cov_map->log_cov_map(194710); 
}

temp ::= .      {
p_cov_map->log_cov_map(12617); 
}

create_table_args ::= LP columnlist conslist_opt RP table_option_set . {
p_cov_map->log_cov_map(186184); 
}

create_table_args ::= AS select . {
p_cov_map->log_cov_map(19775); 
}

%type table_option_set {IR*}
%type table_option {IR*}
table_option_set ::= .    {
p_cov_map->log_cov_map(229601); 
}

table_option_set ::= table_option . {
p_cov_map->log_cov_map(183066); 
}

table_option_set ::= table_option_set COMMA table_option . {
p_cov_map->log_cov_map(86783); 
}

table_option ::= WITHOUT nm . {
p_cov_map->log_cov_map(5928); 
}

table_option ::= nm . {
p_cov_map->log_cov_map(45460); 
}

columnlist ::= columnlist COMMA columnname carglist . {
p_cov_map->log_cov_map(201337); 
}

columnlist ::= columnname carglist . {
p_cov_map->log_cov_map(47841); 
}

columnname ::= nm typetoken . {
p_cov_map->log_cov_map(101617); 
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
nm ::= id . {
p_cov_map->log_cov_map(200661); 
}

nm ::= STRING . {
p_cov_map->log_cov_map(106347); 
}

nm ::= JOIN_KW . {
p_cov_map->log_cov_map(45767); 
}

%type typetoken {IR*}
typetoken ::= .   {
p_cov_map->log_cov_map(41222); 
}

typetoken ::= typename . {
p_cov_map->log_cov_map(200721); 
}

typetoken ::= typename LP signed RP . {
p_cov_map->log_cov_map(174372); 
}

typetoken ::= typename LP signed COMMA signed RP . {
p_cov_map->log_cov_map(4098); 
}

%type typename {IR*}
typename ::= ids . {
p_cov_map->log_cov_map(115395); 
}

typename ::= typename ids . {
p_cov_map->log_cov_map(14808); 
}

signed ::= plus_num . {
p_cov_map->log_cov_map(120408); 
}

signed ::= minus_num . {
p_cov_map->log_cov_map(101489); 
}

%type scanpt {IR*}
scanpt ::= . {
p_cov_map->log_cov_map(55300); 
}

scantok ::= . {
p_cov_map->log_cov_map(120832); 
}

carglist ::= carglist ccons . {
p_cov_map->log_cov_map(116534); 
}

carglist ::= . {
p_cov_map->log_cov_map(148820); 
}

ccons ::= CONSTRAINT nm .           {
p_cov_map->log_cov_map(21413); 
}

ccons ::= DEFAULT scantok term . {
p_cov_map->log_cov_map(217960); 
}

ccons ::= DEFAULT LP expr RP . {
p_cov_map->log_cov_map(190915); 
}

ccons ::= DEFAULT PLUS scantok term . {
p_cov_map->log_cov_map(121565); 
}

ccons ::= DEFAULT MINUS scantok term . {
p_cov_map->log_cov_map(196619); 
}

ccons ::= DEFAULT scantok id .       {
p_cov_map->log_cov_map(207439); 
}

ccons ::= NULL onconf . {
p_cov_map->log_cov_map(260553); 
}

ccons ::= NOT NULL onconf .    {
p_cov_map->log_cov_map(260266); 
}

ccons ::= PRIMARY KEY sortorder onconf autoinc . {
p_cov_map->log_cov_map(99624); 
}

ccons ::= UNIQUE onconf .      {
p_cov_map->log_cov_map(151753); 
}

ccons ::= CHECK LP expr RP .  {
p_cov_map->log_cov_map(144525); 
}

ccons ::= REFERENCES nm eidlist_opt refargs . {
p_cov_map->log_cov_map(235802); 
}

ccons ::= defer_subclause .    {
p_cov_map->log_cov_map(82802); 
}

ccons ::= COLLATE ids .        {
p_cov_map->log_cov_map(11704); 
}

ccons ::= GENERATED ALWAYS AS generated . {
p_cov_map->log_cov_map(21221); 
}

ccons ::= AS generated . {
p_cov_map->log_cov_map(199552); 
}

generated ::= LP expr RP .          {
p_cov_map->log_cov_map(111895); 
}

generated ::= LP expr RP ID . {
p_cov_map->log_cov_map(40933); 
}

%type autoinc {IR*}
autoinc ::= .          {
p_cov_map->log_cov_map(212257); 
}

autoinc ::= AUTOINCR .  {
p_cov_map->log_cov_map(180260); 
}

%type refargs {IR*}
refargs ::= .                  {
p_cov_map->log_cov_map(151152); 
}

refargs ::= refargs refarg . {
p_cov_map->log_cov_map(179571); 
}

%type refarg {IR*}
refarg ::= MATCH nm .              {
p_cov_map->log_cov_map(237294); 
}

refarg ::= ON INSERT refact .      {
p_cov_map->log_cov_map(217755); 
}

refarg ::= ON DELETE refact .   {
p_cov_map->log_cov_map(60502); 
}

refarg ::= ON UPDATE refact .   {
p_cov_map->log_cov_map(23999); 
}

%type refact {IR*}
refact ::= SET NULL .              {
p_cov_map->log_cov_map(162853); 
}

refact ::= SET DEFAULT .           {
p_cov_map->log_cov_map(248627); 
}

refact ::= CASCADE .               {
p_cov_map->log_cov_map(199536); 
}

refact ::= RESTRICT .              {
p_cov_map->log_cov_map(165408); 
}

refact ::= NO ACTION .             {
p_cov_map->log_cov_map(46103); 
}

%type defer_subclause {IR*}
defer_subclause ::= NOT DEFERRABLE init_deferred_pred_opt .     {
p_cov_map->log_cov_map(23106); 
}

defer_subclause ::= DEFERRABLE init_deferred_pred_opt .      {
p_cov_map->log_cov_map(53381); 
}

%type init_deferred_pred_opt {IR*}
init_deferred_pred_opt ::= .                       {
p_cov_map->log_cov_map(27417); 
}

init_deferred_pred_opt ::= INITIALLY DEFERRED .     {
p_cov_map->log_cov_map(227268); 
}

init_deferred_pred_opt ::= INITIALLY IMMEDIATE .    {
p_cov_map->log_cov_map(184579); 
}

conslist_opt ::= .                         {
p_cov_map->log_cov_map(200818); 
}

conslist_opt ::= COMMA conslist . {
p_cov_map->log_cov_map(86890); 
}

conslist ::= conslist tconscomma tcons . {
p_cov_map->log_cov_map(50753); 
}

conslist ::= tcons . {
p_cov_map->log_cov_map(226489); 
}

tconscomma ::= COMMA .            {
p_cov_map->log_cov_map(69568); 
}

tconscomma ::= . {
p_cov_map->log_cov_map(226461); 
}

tcons ::= CONSTRAINT nm .      {
p_cov_map->log_cov_map(65284); 
}

tcons ::= PRIMARY KEY LP sortlist autoinc RP onconf . {
p_cov_map->log_cov_map(35803); 
}

tcons ::= UNIQUE LP sortlist RP onconf . {
p_cov_map->log_cov_map(7607); 
}

tcons ::= CHECK LP expr RP onconf . {
p_cov_map->log_cov_map(1434); 
}

tcons ::= FOREIGN KEY LP eidlist RP REFERENCES nm eidlist_opt refargs defer_subclause_opt . {
p_cov_map->log_cov_map(243226); 
}

%type defer_subclause_opt {IR*}
defer_subclause_opt ::= .                    {
p_cov_map->log_cov_map(252267); 
}

defer_subclause_opt ::= defer_subclause . {
p_cov_map->log_cov_map(73776); 
}

%type onconf {IR*}
%type orconf {IR*}
%type resolvetype {IR*}
onconf ::= .                              {
p_cov_map->log_cov_map(73496); 
}

onconf ::= ON CONFLICT resolvetype .    {
p_cov_map->log_cov_map(196313); 
}

orconf ::= .                              {
p_cov_map->log_cov_map(39290); 
}

orconf ::= OR resolvetype .             {
p_cov_map->log_cov_map(22197); 
}

resolvetype ::= raisetype . {
p_cov_map->log_cov_map(62475); 
}

resolvetype ::= IGNORE .                   {
p_cov_map->log_cov_map(259998); 
}

resolvetype ::= REPLACE .                  {
p_cov_map->log_cov_map(204390); 
}

cmd ::= DROP TABLE ifexists fullname . {
p_cov_map->log_cov_map(258431); 
}

%type ifexists {IR*}
ifexists ::= IF EXISTS .   {
p_cov_map->log_cov_map(23363); 
}

ifexists ::= .            {
p_cov_map->log_cov_map(221608); 
}

cmd ::= createkw temp VIEW ifnotexists nm dbnm eidlist_opt AS select . {
p_cov_map->log_cov_map(93376); 
}

cmd ::= DROP VIEW ifexists fullname . {
p_cov_map->log_cov_map(137895); 
}

cmd ::= select .  {
p_cov_map->log_cov_map(199210); 
}

%type select {IR*}
%type selectnowith {IR*}
%type oneselect {IR*}
select ::= WITH wqlist selectnowith . {
p_cov_map->log_cov_map(116500); 
}

select ::= WITH RECURSIVE wqlist selectnowith . {
p_cov_map->log_cov_map(108833); 
}

select ::= selectnowith . {
p_cov_map->log_cov_map(63420); 
}

selectnowith ::= oneselect . {
p_cov_map->log_cov_map(233456); 
}

selectnowith ::= selectnowith multiselect_op oneselect .  {
p_cov_map->log_cov_map(100512); 
}

%type multiselect_op {IR*}
multiselect_op ::= UNION .             {
p_cov_map->log_cov_map(142320); 
}

multiselect_op ::= UNION ALL .             {
p_cov_map->log_cov_map(162406); 
}

multiselect_op ::= EXCEPT|INTERSECT .  {
p_cov_map->log_cov_map(133750); 
}

oneselect ::= SELECT distinct selcollist from where_opt groupby_opt having_opt orderby_opt limit_opt . {
p_cov_map->log_cov_map(170329); 
}

oneselect ::= SELECT distinct selcollist from where_opt groupby_opt having_opt window_clause orderby_opt limit_opt . {
p_cov_map->log_cov_map(451); 
}

oneselect ::= values . {
p_cov_map->log_cov_map(256497); 
}

%type values {IR*}
values ::= VALUES LP nexprlist RP . {
p_cov_map->log_cov_map(162536); 
}

values ::= values COMMA LP nexprlist RP . {
p_cov_map->log_cov_map(176067); 
}

%type distinct {IR*}
distinct ::= DISTINCT .   {
p_cov_map->log_cov_map(56680); 
}

distinct ::= ALL .        {
p_cov_map->log_cov_map(208518); 
}

distinct ::= .           {
p_cov_map->log_cov_map(90256); 
}

%type selcollist {IR*}
%type sclp {IR*}
sclp ::= selcollist COMMA . {
p_cov_map->log_cov_map(74849); 
}

sclp ::= .                                {
p_cov_map->log_cov_map(102170); 
}

selcollist ::= sclp scanpt expr scanpt as .     {
p_cov_map->log_cov_map(37426); 
}

selcollist ::= sclp scanpt STAR . {
p_cov_map->log_cov_map(155344); 
}

selcollist ::= sclp scanpt nm DOT STAR . {
p_cov_map->log_cov_map(6664); 
}

%type as {IR*}
as ::= AS nm .    {
p_cov_map->log_cov_map(129328); 
}

as ::= ids . {
p_cov_map->log_cov_map(157822); 
}

as ::= .            {
p_cov_map->log_cov_map(96906); 
}

%type seltablist {IR*}
%type stl_prefix {IR*}
%type from {IR*}
from ::= .                {
p_cov_map->log_cov_map(208952); 
}

from ::= FROM seltablist . {
p_cov_map->log_cov_map(177368); 
}

stl_prefix ::= seltablist joinop .    {
p_cov_map->log_cov_map(96971); 
}

stl_prefix ::= .                           {
p_cov_map->log_cov_map(246312); 
}

seltablist ::= stl_prefix nm dbnm as on_using . {
p_cov_map->log_cov_map(188690); 
}

seltablist ::= stl_prefix nm dbnm as indexed_by on_using . {
p_cov_map->log_cov_map(21227); 
}

seltablist ::= stl_prefix nm dbnm LP exprlist RP as on_using . {
p_cov_map->log_cov_map(125920); 
}

seltablist ::= stl_prefix LP select RP as on_using . {
p_cov_map->log_cov_map(252324); 
}

seltablist ::= stl_prefix LP seltablist RP as on_using . {
p_cov_map->log_cov_map(58409); 
}

%type dbnm {IR*}
dbnm ::= .          {
p_cov_map->log_cov_map(226858); 
}

dbnm ::= DOT nm . {
p_cov_map->log_cov_map(178757); 
}

%type fullname {IR*}
fullname ::= nm .  {
p_cov_map->log_cov_map(69241); 
}

fullname ::= nm DOT nm . {
p_cov_map->log_cov_map(23886); 
}

%type xfullname {IR*}
xfullname ::= nm .  {
p_cov_map->log_cov_map(112588); 
}

xfullname ::= nm DOT nm .  {
p_cov_map->log_cov_map(94723); 
}

xfullname ::= nm DOT nm AS nm .  {
p_cov_map->log_cov_map(36301); 
}

xfullname ::= nm AS nm . {
p_cov_map->log_cov_map(19144); 
}

%type joinop {IR*}
joinop ::= COMMA|JOIN .              {
p_cov_map->log_cov_map(141572); 
}

joinop ::= JOIN_KW JOIN . {
p_cov_map->log_cov_map(49520); 
}

joinop ::= JOIN_KW nm JOIN . {
p_cov_map->log_cov_map(129264); 
}

joinop ::= JOIN_KW nm nm JOIN . {
p_cov_map->log_cov_map(28134); 
}

%type on_using {IR*}
on_using ::= ON expr .            {
p_cov_map->log_cov_map(118016); 
}

on_using ::= USING LP idlist RP . {
p_cov_map->log_cov_map(47606); 
}

on_using ::= .                  [OR]{
p_cov_map->log_cov_map(192417); 
}

%type indexed_opt {IR*}
%type indexed_by  {IR*}
indexed_opt ::= .                 {
p_cov_map->log_cov_map(5612); 
}

indexed_opt ::= indexed_by . {
p_cov_map->log_cov_map(33806); 
}

indexed_by ::= INDEXED BY nm . {
p_cov_map->log_cov_map(197418); 
}

indexed_by ::= NOT INDEXED .      {
p_cov_map->log_cov_map(5082); 
}

%type orderby_opt {IR*}
%type sortlist {IR*}
orderby_opt ::= .                          {
p_cov_map->log_cov_map(218830); 
}

orderby_opt ::= ORDER BY sortlist .      {
p_cov_map->log_cov_map(210567); 
}

sortlist ::= sortlist COMMA expr sortorder nulls . {
p_cov_map->log_cov_map(60101); 
}

sortlist ::= expr sortorder nulls . {
p_cov_map->log_cov_map(5069); 
}

%type sortorder {IR*}
sortorder ::= ASC .           {
p_cov_map->log_cov_map(180838); 
}

sortorder ::= DESC .          {
p_cov_map->log_cov_map(117481); 
}

sortorder ::= .              {
p_cov_map->log_cov_map(61370); 
}

%type nulls {IR*}
nulls ::= NULLS FIRST .       {
p_cov_map->log_cov_map(205344); 
}

nulls ::= NULLS LAST .        {
p_cov_map->log_cov_map(41837); 
}

nulls ::= .                  {
p_cov_map->log_cov_map(102729); 
}

%type groupby_opt {IR*}
groupby_opt ::= .                      {
p_cov_map->log_cov_map(175742); 
}

groupby_opt ::= GROUP BY nexprlist . {
p_cov_map->log_cov_map(163109); 
}

%type having_opt {IR*}
having_opt ::= .                {
p_cov_map->log_cov_map(29740); 
}

having_opt ::= HAVING expr .  {
p_cov_map->log_cov_map(83525); 
}

%type limit_opt {IR*}
limit_opt ::= .       {
p_cov_map->log_cov_map(220201); 
}

limit_opt ::= LIMIT expr . {
p_cov_map->log_cov_map(162968); 
}

limit_opt ::= LIMIT expr OFFSET expr . {
p_cov_map->log_cov_map(133855); 
}

limit_opt ::= LIMIT expr COMMA expr . {
p_cov_map->log_cov_map(175460); 
}

cmd ::= with DELETE FROM xfullname indexed_opt where_opt_ret orderby_opt limit_opt . {
p_cov_map->log_cov_map(101283); 
}

%type where_opt {IR*}
%type where_opt_ret {IR*}
where_opt ::= .                    {
p_cov_map->log_cov_map(219759); 
}

where_opt ::= WHERE expr .       {
p_cov_map->log_cov_map(187610); 
}

where_opt_ret ::= .                                      {
p_cov_map->log_cov_map(123266); 
}

where_opt_ret ::= WHERE expr .                         {
p_cov_map->log_cov_map(24269); 
}

where_opt_ret ::= RETURNING selcollist .               {
p_cov_map->log_cov_map(97252); 
}

where_opt_ret ::= WHERE expr RETURNING selcollist . {
p_cov_map->log_cov_map(255902); 
}

cmd ::= with UPDATE orconf xfullname indexed_opt SET setlist from where_opt_ret orderby_opt limit_opt .  {
p_cov_map->log_cov_map(52329); 
}

%type setlist {IR*}
setlist ::= setlist COMMA nm EQ expr . {
p_cov_map->log_cov_map(259930); 
}

setlist ::= setlist COMMA LP idlist RP EQ expr . {
p_cov_map->log_cov_map(35835); 
}

setlist ::= nm EQ expr . {
p_cov_map->log_cov_map(220890); 
}

setlist ::= LP idlist RP EQ expr . {
p_cov_map->log_cov_map(108657); 
}

cmd ::= with insert_cmd INTO xfullname idlist_opt select upsert . {
p_cov_map->log_cov_map(46805); 
}

cmd ::= with insert_cmd INTO xfullname idlist_opt DEFAULT VALUES returning . {
p_cov_map->log_cov_map(23); 
}

%type upsert {IR*}
upsert ::= . {
p_cov_map->log_cov_map(81997); 
}

upsert ::= RETURNING selcollist .  {
p_cov_map->log_cov_map(35074); 
}

upsert ::= ON CONFLICT LP sortlist RP where_opt DO UPDATE SET setlist where_opt upsert . {
p_cov_map->log_cov_map(54416); 
}

upsert ::= ON CONFLICT LP sortlist RP where_opt DO NOTHING upsert . {
p_cov_map->log_cov_map(250887); 
}

upsert ::= ON CONFLICT DO NOTHING returning . {
p_cov_map->log_cov_map(235538); 
}

upsert ::= ON CONFLICT DO UPDATE SET setlist where_opt returning . {
p_cov_map->log_cov_map(110239); 
}

returning ::= RETURNING selcollist .  {
p_cov_map->log_cov_map(129021); 
}

returning ::= . {
p_cov_map->log_cov_map(81207); 
}

%type insert_cmd {IR*}
insert_cmd ::= INSERT orconf .   {
p_cov_map->log_cov_map(6299); 
}

insert_cmd ::= REPLACE .            {
p_cov_map->log_cov_map(34713); 
}

%type idlist_opt {IR*}
%type idlist {IR*}
idlist_opt ::= .                       {
p_cov_map->log_cov_map(1997); 
}

idlist_opt ::= LP idlist RP .    {
p_cov_map->log_cov_map(260680); 
}

idlist ::= idlist COMMA nm . {
p_cov_map->log_cov_map(38892); 
}

idlist ::= nm . {
p_cov_map->log_cov_map(37968); 
}

%type expr {IR*}
%type term {IR*}
expr ::= term . {
p_cov_map->log_cov_map(49801); 
}

expr ::= LP expr RP . {
p_cov_map->log_cov_map(6773); 
}

expr ::= id .          {
p_cov_map->log_cov_map(4510); 
}

expr ::= JOIN_KW .     {
p_cov_map->log_cov_map(93396); 
}

expr ::= nm DOT nm . {
p_cov_map->log_cov_map(153563); 
}

expr ::= nm DOT nm DOT nm . {
p_cov_map->log_cov_map(105654); 
}

term ::= NULL|FLOAT|BLOB . {
p_cov_map->log_cov_map(182656); 
}

term ::= STRING .          {
p_cov_map->log_cov_map(10461); 
}

term ::= INTEGER . {
p_cov_map->log_cov_map(112395); 
}

expr ::= VARIABLE .     {
p_cov_map->log_cov_map(157407); 
}

expr ::= expr COLLATE ids . {
p_cov_map->log_cov_map(115608); 
}

expr ::= CAST LP expr AS typetoken RP . {
p_cov_map->log_cov_map(204885); 
}

expr ::= id LP distinct exprlist RP . {
p_cov_map->log_cov_map(245239); 
}

expr ::= id LP STAR RP . {
p_cov_map->log_cov_map(257100); 
}

expr ::= id LP distinct exprlist RP filter_over . {
p_cov_map->log_cov_map(254867); 
}

expr ::= id LP STAR RP filter_over . {
p_cov_map->log_cov_map(36013); 
}

term ::= CTIME_KW . {
p_cov_map->log_cov_map(34598); 
}

expr ::= LP nexprlist COMMA expr RP . {
p_cov_map->log_cov_map(155225); 
}

expr ::= expr AND expr .        {
p_cov_map->log_cov_map(21857); 
}

expr ::= expr OR expr .     {
p_cov_map->log_cov_map(30438); 
}

expr ::= expr LT|GT|GE|LE expr . {
p_cov_map->log_cov_map(258330); 
}

expr ::= expr EQ|NE expr .  {
p_cov_map->log_cov_map(121703); 
}

expr ::= expr BITAND|BITOR|LSHIFT|RSHIFT expr . {
p_cov_map->log_cov_map(249292); 
}

expr ::= expr PLUS|MINUS expr . {
p_cov_map->log_cov_map(121411); 
}

expr ::= expr STAR|SLASH|REM expr . {
p_cov_map->log_cov_map(106614); 
}

expr ::= expr CONCAT expr . {
p_cov_map->log_cov_map(187068); 
}

%type likeop {IR*}
likeop ::= LIKE_KW|MATCH . {
p_cov_map->log_cov_map(65559); 
}

likeop ::= NOT LIKE_KW|MATCH . {
p_cov_map->log_cov_map(253278); 
}

expr ::= expr likeop expr .   [LIKE_KW] {
p_cov_map->log_cov_map(14367); 
}

expr ::= expr likeop expr ESCAPE expr .   [LIKE_KW] {
p_cov_map->log_cov_map(212141); 
}

expr ::= expr ISNULL|NOTNULL .   {
p_cov_map->log_cov_map(243157); 
}

expr ::= expr NOT NULL .    {
p_cov_map->log_cov_map(196778); 
}

expr ::= expr IS expr .     {
p_cov_map->log_cov_map(160766); 
}

expr ::= expr IS NOT expr . {
p_cov_map->log_cov_map(217154); 
}

expr ::= expr IS NOT DISTINCT FROM expr .     {
p_cov_map->log_cov_map(63709); 
}

expr ::= expr IS DISTINCT FROM expr . {
p_cov_map->log_cov_map(254070); 
}

expr ::= NOT expr .  {
p_cov_map->log_cov_map(82426); 
}

expr ::= BITNOT expr . {
p_cov_map->log_cov_map(221270); 
}

expr ::= PLUS|MINUS expr .  [BITNOT]{
p_cov_map->log_cov_map(5006); 
}

expr ::= expr PTR expr . {
p_cov_map->log_cov_map(126961); 
}

%type between_op {IR*}
between_op ::= BETWEEN .     {
p_cov_map->log_cov_map(38193); 
}

between_op ::= NOT BETWEEN . {
p_cov_map->log_cov_map(257209); 
}

expr ::= expr between_op expr AND expr .  [BETWEEN]{
p_cov_map->log_cov_map(19433); 
}

in_op ::= IN .      {
p_cov_map->log_cov_map(158196); 
}

in_op ::= NOT IN .  {
p_cov_map->log_cov_map(179543); 
}

expr ::= expr in_op LP exprlist RP .  [IN]{
p_cov_map->log_cov_map(161047); 
}

expr ::= LP select RP . {
p_cov_map->log_cov_map(247130); 
}

expr ::= expr in_op LP select RP .   [IN]{
p_cov_map->log_cov_map(70299); 
}

expr ::= expr in_op nm dbnm paren_exprlist .  [IN]{
p_cov_map->log_cov_map(97944); 
}

expr ::= EXISTS LP select RP . {
p_cov_map->log_cov_map(135737); 
}

expr ::= CASE case_operand case_exprlist case_else END . {
p_cov_map->log_cov_map(177123); 
}

%type case_exprlist {IR*}
case_exprlist ::= case_exprlist WHEN expr THEN expr . {
p_cov_map->log_cov_map(39904); 
}

case_exprlist ::= WHEN expr THEN expr . {
p_cov_map->log_cov_map(149755); 
}

%type case_else {IR*}
case_else ::= ELSE expr .         {
p_cov_map->log_cov_map(253036); 
}

case_else ::= .                     {
p_cov_map->log_cov_map(86786); 
}

%type case_operand {IR*}
case_operand ::= expr .            {
p_cov_map->log_cov_map(196200); 
}

case_operand ::= .                   {
p_cov_map->log_cov_map(52666); 
}

%type exprlist {IR*}
%type nexprlist {IR*}
exprlist ::= nexprlist . {
p_cov_map->log_cov_map(140653); 
}

exprlist ::= .                            {
p_cov_map->log_cov_map(53335); 
}

nexprlist ::= nexprlist COMMA expr . {
p_cov_map->log_cov_map(124513); 
}

nexprlist ::= expr . {
p_cov_map->log_cov_map(101042); 
}

%type paren_exprlist {IR*}
paren_exprlist ::= .   {
p_cov_map->log_cov_map(43654); 
}

paren_exprlist ::= LP exprlist RP .  {
p_cov_map->log_cov_map(63823); 
}

cmd ::= createkw uniqueflag INDEX ifnotexists nm dbnm ON nm LP sortlist RP where_opt . {
p_cov_map->log_cov_map(92167); 
}

%type uniqueflag {IR*}
uniqueflag ::= UNIQUE .  {
p_cov_map->log_cov_map(153119); 
}

uniqueflag ::= .        {
p_cov_map->log_cov_map(25125); 
}

%type eidlist {IR*}
%type eidlist_opt {IR*}
eidlist_opt ::= .                         {
p_cov_map->log_cov_map(88265); 
}

eidlist_opt ::= LP eidlist RP .         {
p_cov_map->log_cov_map(184026); 
}

eidlist ::= eidlist COMMA nm collate sortorder .  {
p_cov_map->log_cov_map(109745); 
}

eidlist ::= nm collate sortorder . {
p_cov_map->log_cov_map(111053); 
}

%type collate {IR*}
collate ::= .              {
p_cov_map->log_cov_map(246534); 
}

collate ::= COLLATE ids .   {
p_cov_map->log_cov_map(183703); 
}

cmd ::= DROP INDEX ifexists fullname .   {
p_cov_map->log_cov_map(164476); 
}

%type vinto {IR*}
cmd ::= VACUUM vinto .                {
p_cov_map->log_cov_map(93734); 
}

cmd ::= VACUUM nm vinto .          {
p_cov_map->log_cov_map(44377); 
}

vinto ::= INTO expr .              {
p_cov_map->log_cov_map(222569); 
}

vinto ::= .                          {
p_cov_map->log_cov_map(43693); 
}

cmd ::= PRAGMA nm dbnm .                {
p_cov_map->log_cov_map(47914); 
}

cmd ::= PRAGMA nm dbnm EQ nmnum .    {
p_cov_map->log_cov_map(13213); 
}

cmd ::= PRAGMA nm dbnm LP nmnum RP . {
p_cov_map->log_cov_map(31828); 
}

cmd ::= PRAGMA nm dbnm EQ minus_num . {
p_cov_map->log_cov_map(226754); 
}

cmd ::= PRAGMA nm dbnm LP minus_num RP . {
p_cov_map->log_cov_map(180054); 
}

nmnum ::= plus_num . {
p_cov_map->log_cov_map(81689); 
}

nmnum ::= nm . {
p_cov_map->log_cov_map(154223); 
}

nmnum ::= ON . {
p_cov_map->log_cov_map(230752); 
}

nmnum ::= DELETE . {
p_cov_map->log_cov_map(98948); 
}

nmnum ::= DEFAULT . {
p_cov_map->log_cov_map(177610); 
}

%token_class number INTEGER|FLOAT.
plus_num ::= PLUS number .       {
p_cov_map->log_cov_map(66979); 
}

plus_num ::= number . {
p_cov_map->log_cov_map(124251); 
}

minus_num ::= MINUS number .     {
p_cov_map->log_cov_map(150740); 
}

cmd ::= createkw trigger_decl BEGIN trigger_cmd_list END . {
p_cov_map->log_cov_map(109202); 
}

trigger_decl ::= temp TRIGGER ifnotexists nm dbnm trigger_time trigger_event ON fullname foreach_clause when_clause . {
p_cov_map->log_cov_map(141269); 
}

%type trigger_time {IR*}
trigger_time ::= BEFORE|AFTER .  {
p_cov_map->log_cov_map(227129); 
}

trigger_time ::= INSTEAD OF .  {
p_cov_map->log_cov_map(92576); 
}

trigger_time ::= .            {
p_cov_map->log_cov_map(97636); 
}

%type trigger_event {IR*}
trigger_event ::= DELETE|INSERT .   {
p_cov_map->log_cov_map(247155); 
}

trigger_event ::= UPDATE .          {
p_cov_map->log_cov_map(31990); 
}

trigger_event ::= UPDATE OF idlist . {
p_cov_map->log_cov_map(151032); 
}

foreach_clause ::= . {
p_cov_map->log_cov_map(184264); 
}

foreach_clause ::= FOR EACH ROW . {
p_cov_map->log_cov_map(121964); 
}

%type when_clause {IR*}
when_clause ::= .             {
p_cov_map->log_cov_map(106691); 
}

when_clause ::= WHEN expr . {
p_cov_map->log_cov_map(133589); 
}

%type trigger_cmd_list {IR*}
trigger_cmd_list ::= trigger_cmd_list trigger_cmd SEMI . {
p_cov_map->log_cov_map(192260); 
}

trigger_cmd_list ::= trigger_cmd SEMI . {
p_cov_map->log_cov_map(195535); 
}

%type trnm {IR*}
trnm ::= nm . {
p_cov_map->log_cov_map(14568); 
}

trnm ::= nm DOT nm . {
p_cov_map->log_cov_map(54663); 
}

tridxby ::= . {
p_cov_map->log_cov_map(39369); 
}

tridxby ::= INDEXED BY nm . {
p_cov_map->log_cov_map(86231); 
}

tridxby ::= NOT INDEXED . {
p_cov_map->log_cov_map(196014); 
}

%type trigger_cmd {IR*}
trigger_cmd ::= UPDATE orconf trnm tridxby SET setlist from where_opt scanpt .  {
p_cov_map->log_cov_map(55970); 
}

trigger_cmd ::= scanpt insert_cmd INTO trnm idlist_opt select upsert scanpt . {
p_cov_map->log_cov_map(228479); 
}

trigger_cmd ::= DELETE FROM trnm tridxby where_opt scanpt . {
p_cov_map->log_cov_map(109252); 
}

trigger_cmd ::= scanpt select scanpt . {
p_cov_map->log_cov_map(179412); 
}

expr ::= RAISE LP IGNORE RP .  {
p_cov_map->log_cov_map(211734); 
}

expr ::= RAISE LP raisetype COMMA nm RP .  {
p_cov_map->log_cov_map(155543); 
}

%type raisetype {IR*}
raisetype ::= ROLLBACK .  {
p_cov_map->log_cov_map(68901); 
}

raisetype ::= ABORT .     {
p_cov_map->log_cov_map(89150); 
}

raisetype ::= FAIL .      {
p_cov_map->log_cov_map(251217); 
}

cmd ::= DROP TRIGGER ifexists fullname . {
p_cov_map->log_cov_map(30083); 
}

cmd ::= ATTACH database_kw_opt expr AS expr key_opt . {
p_cov_map->log_cov_map(103390); 
}

cmd ::= DETACH database_kw_opt expr . {
p_cov_map->log_cov_map(117767); 
}

%type key_opt {IR*}
key_opt ::= .                     {
p_cov_map->log_cov_map(157272); 
}

key_opt ::= KEY expr .          {
p_cov_map->log_cov_map(59398); 
}

database_kw_opt ::= DATABASE . {
p_cov_map->log_cov_map(110976); 
}

database_kw_opt ::= . {
p_cov_map->log_cov_map(6958); 
}

cmd ::= REINDEX .                {
p_cov_map->log_cov_map(51837); 
}

cmd ::= REINDEX nm dbnm .  {
p_cov_map->log_cov_map(154841); 
}

cmd ::= ANALYZE .                {
p_cov_map->log_cov_map(225033); 
}

cmd ::= ANALYZE nm dbnm .  {
p_cov_map->log_cov_map(177091); 
}

cmd ::= ALTER TABLE fullname RENAME TO nm . {
p_cov_map->log_cov_map(174052); 
}

cmd ::= ALTER TABLE add_column_fullname ADD kwcolumn_opt columnname carglist . {
p_cov_map->log_cov_map(185942); 
}

cmd ::= ALTER TABLE fullname DROP kwcolumn_opt nm . {
p_cov_map->log_cov_map(206584); 
}

add_column_fullname ::= fullname . {
p_cov_map->log_cov_map(103809); 
}

cmd ::= ALTER TABLE fullname RENAME kwcolumn_opt nm TO nm . {
p_cov_map->log_cov_map(204355); 
}

kwcolumn_opt ::= . {
p_cov_map->log_cov_map(13010); 
}

kwcolumn_opt ::= COLUMNKW . {
p_cov_map->log_cov_map(55464); 
}

cmd ::= create_vtab .                       {
p_cov_map->log_cov_map(114631); 
}

cmd ::= create_vtab LP vtabarglist RP .  {
p_cov_map->log_cov_map(40003); 
}

create_vtab ::= createkw VIRTUAL TABLE ifnotexists nm dbnm USING nm . {
p_cov_map->log_cov_map(76766); 
}

vtabarglist ::= vtabarg . {
p_cov_map->log_cov_map(260291); 
}

vtabarglist ::= vtabarglist COMMA vtabarg . {
p_cov_map->log_cov_map(44326); 
}

vtabarg ::= .                       {
p_cov_map->log_cov_map(160132); 
}

vtabarg ::= vtabarg vtabargtoken . {
p_cov_map->log_cov_map(127900); 
}

vtabargtoken ::= ANY .            {
p_cov_map->log_cov_map(187562); 
}

vtabargtoken ::= lp anylist RP .  {
p_cov_map->log_cov_map(61307); 
}

lp ::= LP .                       {
p_cov_map->log_cov_map(207784); 
}

anylist ::= . {
p_cov_map->log_cov_map(164212); 
}

anylist ::= anylist LP anylist RP . {
p_cov_map->log_cov_map(175888); 
}

anylist ::= anylist ANY . {
p_cov_map->log_cov_map(173974); 
}

%type wqlist {IR*}
%type wqitem {IR*}
with ::= . {
p_cov_map->log_cov_map(191304); 
}

with ::= WITH wqlist .              {
p_cov_map->log_cov_map(148800); 
}

with ::= WITH RECURSIVE wqlist .    {
p_cov_map->log_cov_map(26630); 
}

%type wqas {IR*}
wqas ::= AS .                  {
p_cov_map->log_cov_map(131871); 
}

wqas ::= AS MATERIALIZED .     {
p_cov_map->log_cov_map(210578); 
}

wqas ::= AS NOT MATERIALIZED . {
p_cov_map->log_cov_map(113778); 
}

wqitem ::= nm eidlist_opt wqas LP select RP . {
p_cov_map->log_cov_map(72142); 
}

wqlist ::= wqitem . {
p_cov_map->log_cov_map(52285); 
}

wqlist ::= wqlist COMMA wqitem . {
p_cov_map->log_cov_map(253506); 
}

%type windowdefn_list {IR*}
windowdefn_list ::= windowdefn . {
p_cov_map->log_cov_map(68364); 
}

windowdefn_list ::= windowdefn_list COMMA windowdefn . {
p_cov_map->log_cov_map(3034); 
}

%type windowdefn {IR*}
windowdefn ::= nm AS LP window RP . {
p_cov_map->log_cov_map(47681); 
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
p_cov_map->log_cov_map(9569); 
}

window ::= nm PARTITION BY nexprlist orderby_opt frame_opt . {
p_cov_map->log_cov_map(118346); 
}

window ::= ORDER BY sortlist frame_opt . {
p_cov_map->log_cov_map(14366); 
}

window ::= nm ORDER BY sortlist frame_opt . {
p_cov_map->log_cov_map(86937); 
}

window ::= frame_opt . {
p_cov_map->log_cov_map(235584); 
}

window ::= nm frame_opt . {
p_cov_map->log_cov_map(113469); 
}

frame_opt ::= .                             {
p_cov_map->log_cov_map(78756); 
}

frame_opt ::= range_or_rows frame_bound_s frame_exclude_opt . {
p_cov_map->log_cov_map(72768); 
}

frame_opt ::= range_or_rows BETWEEN frame_bound_s AND frame_bound_e frame_exclude_opt . {
p_cov_map->log_cov_map(194465); 
}

range_or_rows ::= RANGE|ROWS|GROUPS .   {
p_cov_map->log_cov_map(65250); 
}

frame_bound_s ::= frame_bound .         {
p_cov_map->log_cov_map(14419); 
}

frame_bound_s ::= UNBOUNDED PRECEDING . {
p_cov_map->log_cov_map(50934); 
}

frame_bound_e ::= frame_bound .         {
p_cov_map->log_cov_map(24589); 
}

frame_bound_e ::= UNBOUNDED FOLLOWING . {
p_cov_map->log_cov_map(12600); 
}

frame_bound ::= expr PRECEDING|FOLLOWING . {
p_cov_map->log_cov_map(239996); 
}

frame_bound ::= CURRENT ROW .           {
p_cov_map->log_cov_map(16479); 
}

%type frame_exclude_opt {IR*}
frame_exclude_opt ::= . {
p_cov_map->log_cov_map(7558); 
}

frame_exclude_opt ::= EXCLUDE frame_exclude . {
p_cov_map->log_cov_map(34835); 
}

%type frame_exclude {IR*}
frame_exclude ::= NO OTHERS .   {
p_cov_map->log_cov_map(111782); 
}

frame_exclude ::= CURRENT ROW . {
p_cov_map->log_cov_map(124293); 
}

frame_exclude ::= GROUP|TIES .  {
p_cov_map->log_cov_map(121958); 
}

%type window_clause {IR*}
window_clause ::= WINDOW windowdefn_list . {
p_cov_map->log_cov_map(159606); 
}

filter_over ::= filter_clause over_clause . {
p_cov_map->log_cov_map(115328); 
}

filter_over ::= over_clause . {
p_cov_map->log_cov_map(157941); 
}

filter_over ::= filter_clause . {
p_cov_map->log_cov_map(49408); 
}

over_clause ::= OVER LP window RP . {
p_cov_map->log_cov_map(133851); 
}

over_clause ::= OVER nm . {
p_cov_map->log_cov_map(127380); 
}

filter_clause ::= FILTER LP WHERE expr RP .  {
p_cov_map->log_cov_map(69429); 
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
