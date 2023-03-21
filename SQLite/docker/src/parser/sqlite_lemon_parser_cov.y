
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
p_cov_map->log_cov_map(232509); 
}

cmdlist ::= cmdlist ecmd . {
p_cov_map->log_cov_map(125405); 
}

cmdlist ::= ecmd . {
p_cov_map->log_cov_map(104177); 
}

ecmd ::= SEMI . {
p_cov_map->log_cov_map(21152); 
}

ecmd ::= cmdx SEMI . {
p_cov_map->log_cov_map(162492); 
}

ecmd ::= explain cmdx SEMI .       {
p_cov_map->log_cov_map(45422); 
}

explain ::= EXPLAIN .              {
p_cov_map->log_cov_map(19200); 
}

explain ::= EXPLAIN QUERY PLAN .   {
p_cov_map->log_cov_map(20726); 
}

cmdx ::= cmd .           {
p_cov_map->log_cov_map(185100); 
}

cmd ::= BEGIN transtype trans_opt .  {
p_cov_map->log_cov_map(113548); 
}

trans_opt ::= . {
p_cov_map->log_cov_map(117018); 
}

trans_opt ::= TRANSACTION . {
p_cov_map->log_cov_map(221484); 
}

trans_opt ::= TRANSACTION nm . {
p_cov_map->log_cov_map(43906); 
}

%type transtype {IR*}
transtype ::= .             {
p_cov_map->log_cov_map(133342); 
}

transtype ::= DEFERRED .  {
p_cov_map->log_cov_map(213086); 
}

transtype ::= IMMEDIATE . {
p_cov_map->log_cov_map(204537); 
}

transtype ::= EXCLUSIVE . {
p_cov_map->log_cov_map(189211); 
}

cmd ::= COMMIT|END trans_opt .   {
p_cov_map->log_cov_map(58087); 
}

cmd ::= ROLLBACK trans_opt .     {
p_cov_map->log_cov_map(60722); 
}

savepoint_opt ::= SAVEPOINT . {
p_cov_map->log_cov_map(234058); 
}

savepoint_opt ::= . {
p_cov_map->log_cov_map(50305); 
}

cmd ::= SAVEPOINT nm . {
p_cov_map->log_cov_map(119797); 
}

cmd ::= RELEASE savepoint_opt nm . {
p_cov_map->log_cov_map(49177); 
}

cmd ::= ROLLBACK trans_opt TO savepoint_opt nm . {
p_cov_map->log_cov_map(214544); 
}

cmd ::= create_table create_table_args . {
p_cov_map->log_cov_map(69176); 
}

create_table ::= createkw temp TABLE ifnotexists nm dbnm . {
p_cov_map->log_cov_map(247727); 
}

createkw ::= CREATE .  {
p_cov_map->log_cov_map(194913); 
}

%type ifnotexists {IR*}
ifnotexists ::= .              {
p_cov_map->log_cov_map(193443); 
}

ifnotexists ::= IF NOT EXISTS . {
p_cov_map->log_cov_map(129313); 
}

%type temp {IR*}
temp ::= TEMP .  {
p_cov_map->log_cov_map(158359); 
}

temp ::= .      {
p_cov_map->log_cov_map(123797); 
}

create_table_args ::= LP columnlist conslist_opt RP table_option_set . {
p_cov_map->log_cov_map(166099); 
}

create_table_args ::= AS select . {
p_cov_map->log_cov_map(242022); 
}

%type table_option_set {IR*}
%type table_option {IR*}
table_option_set ::= .    {
p_cov_map->log_cov_map(76855); 
}

table_option_set ::= table_option . {
p_cov_map->log_cov_map(32397); 
}

table_option_set ::= table_option_set COMMA table_option . {
p_cov_map->log_cov_map(255678); 
}

table_option ::= WITHOUT nm . {
p_cov_map->log_cov_map(146032); 
}

table_option ::= nm . {
p_cov_map->log_cov_map(245066); 
}

columnlist ::= columnlist COMMA columnname carglist . {
p_cov_map->log_cov_map(117331); 
}

columnlist ::= columnname carglist . {
p_cov_map->log_cov_map(68644); 
}

columnname ::= nm typetoken . {
p_cov_map->log_cov_map(84051); 
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
p_cov_map->log_cov_map(241636); 
}

nm ::= STRING . {
p_cov_map->log_cov_map(239138); 
}

nm ::= JOIN_KW . {
p_cov_map->log_cov_map(77607); 
}

%type typetoken {IR*}
typetoken ::= .   {
p_cov_map->log_cov_map(186321); 
}

typetoken ::= typename . {
p_cov_map->log_cov_map(15745); 
}

typetoken ::= typename LP signed RP . {
p_cov_map->log_cov_map(49446); 
}

typetoken ::= typename LP signed COMMA signed RP . {
p_cov_map->log_cov_map(149043); 
}

%type typename {IR*}
typename ::= ids . {
p_cov_map->log_cov_map(149241); 
}

typename ::= typename ids . {
p_cov_map->log_cov_map(209973); 
}

signed ::= plus_num . {
p_cov_map->log_cov_map(240329); 
}

signed ::= minus_num . {
p_cov_map->log_cov_map(244434); 
}

%type scanpt {IR*}
scanpt ::= . {
p_cov_map->log_cov_map(122442); 
}

scantok ::= . {
p_cov_map->log_cov_map(79976); 
}

carglist ::= carglist ccons . {
p_cov_map->log_cov_map(96436); 
}

carglist ::= . {
p_cov_map->log_cov_map(75803); 
}

ccons ::= CONSTRAINT nm .           {
p_cov_map->log_cov_map(125113); 
}

ccons ::= DEFAULT scantok term . {
p_cov_map->log_cov_map(164287); 
}

ccons ::= DEFAULT LP expr RP . {
p_cov_map->log_cov_map(204447); 
}

ccons ::= DEFAULT PLUS scantok term . {
p_cov_map->log_cov_map(150683); 
}

ccons ::= DEFAULT MINUS scantok term . {
p_cov_map->log_cov_map(63187); 
}

ccons ::= DEFAULT scantok id .       {
p_cov_map->log_cov_map(33184); 
}

ccons ::= NULL onconf . {
p_cov_map->log_cov_map(218204); 
}

ccons ::= NOT NULL onconf .    {
p_cov_map->log_cov_map(249279); 
}

ccons ::= PRIMARY KEY sortorder onconf autoinc . {
p_cov_map->log_cov_map(43097); 
}

ccons ::= UNIQUE onconf .      {
p_cov_map->log_cov_map(250779); 
}

ccons ::= CHECK LP expr RP .  {
p_cov_map->log_cov_map(88926); 
}

ccons ::= REFERENCES nm eidlist_opt refargs . {
p_cov_map->log_cov_map(95791); 
}

ccons ::= defer_subclause .    {
p_cov_map->log_cov_map(44835); 
}

ccons ::= COLLATE ids .        {
p_cov_map->log_cov_map(245886); 
}

ccons ::= GENERATED ALWAYS AS generated . {
p_cov_map->log_cov_map(81095); 
}

ccons ::= AS generated . {
p_cov_map->log_cov_map(217086); 
}

generated ::= LP expr RP .          {
p_cov_map->log_cov_map(64789); 
}

generated ::= LP expr RP ID . {
p_cov_map->log_cov_map(220380); 
}

%type autoinc {IR*}
autoinc ::= .          {
p_cov_map->log_cov_map(199290); 
}

autoinc ::= AUTOINCR .  {
p_cov_map->log_cov_map(182786); 
}

%type refargs {IR*}
refargs ::= .                  {
p_cov_map->log_cov_map(235891); 
}

refargs ::= refargs refarg . {
p_cov_map->log_cov_map(129372); 
}

%type refarg {IR*}
refarg ::= MATCH nm .              {
p_cov_map->log_cov_map(3188); 
}

refarg ::= ON INSERT refact .      {
p_cov_map->log_cov_map(198521); 
}

refarg ::= ON DELETE refact .   {
p_cov_map->log_cov_map(108355); 
}

refarg ::= ON UPDATE refact .   {
p_cov_map->log_cov_map(169834); 
}

%type refact {IR*}
refact ::= SET NULL .              {
p_cov_map->log_cov_map(100271); 
}

refact ::= SET DEFAULT .           {
p_cov_map->log_cov_map(129003); 
}

refact ::= CASCADE .               {
p_cov_map->log_cov_map(7586); 
}

refact ::= RESTRICT .              {
p_cov_map->log_cov_map(154437); 
}

refact ::= NO ACTION .             {
p_cov_map->log_cov_map(139095); 
}

%type defer_subclause {IR*}
defer_subclause ::= NOT DEFERRABLE init_deferred_pred_opt .     {
p_cov_map->log_cov_map(83655); 
}

defer_subclause ::= DEFERRABLE init_deferred_pred_opt .      {
p_cov_map->log_cov_map(114352); 
}

%type init_deferred_pred_opt {IR*}
init_deferred_pred_opt ::= .                       {
p_cov_map->log_cov_map(117243); 
}

init_deferred_pred_opt ::= INITIALLY DEFERRED .     {
p_cov_map->log_cov_map(55763); 
}

init_deferred_pred_opt ::= INITIALLY IMMEDIATE .    {
p_cov_map->log_cov_map(163680); 
}

conslist_opt ::= .                         {
p_cov_map->log_cov_map(206006); 
}

conslist_opt ::= COMMA conslist . {
p_cov_map->log_cov_map(56691); 
}

conslist ::= conslist tconscomma tcons . {
p_cov_map->log_cov_map(222586); 
}

conslist ::= tcons . {
p_cov_map->log_cov_map(186217); 
}

tconscomma ::= COMMA .            {
p_cov_map->log_cov_map(37465); 
}

tconscomma ::= . {
p_cov_map->log_cov_map(249317); 
}

tcons ::= CONSTRAINT nm .      {
p_cov_map->log_cov_map(152610); 
}

tcons ::= PRIMARY KEY LP sortlist autoinc RP onconf . {
p_cov_map->log_cov_map(66500); 
}

tcons ::= UNIQUE LP sortlist RP onconf . {
p_cov_map->log_cov_map(60527); 
}

tcons ::= CHECK LP expr RP onconf . {
p_cov_map->log_cov_map(77736); 
}

tcons ::= FOREIGN KEY LP eidlist RP REFERENCES nm eidlist_opt refargs defer_subclause_opt . {
p_cov_map->log_cov_map(233030); 
}

%type defer_subclause_opt {IR*}
defer_subclause_opt ::= .                    {
p_cov_map->log_cov_map(153217); 
}

defer_subclause_opt ::= defer_subclause . {
p_cov_map->log_cov_map(67986); 
}

%type onconf {IR*}
%type orconf {IR*}
%type resolvetype {IR*}
onconf ::= .                              {
p_cov_map->log_cov_map(124940); 
}

onconf ::= ON CONFLICT resolvetype .    {
p_cov_map->log_cov_map(34971); 
}

orconf ::= .                              {
p_cov_map->log_cov_map(107039); 
}

orconf ::= OR resolvetype .             {
p_cov_map->log_cov_map(155006); 
}

resolvetype ::= raisetype . {
p_cov_map->log_cov_map(147622); 
}

resolvetype ::= IGNORE .                   {
p_cov_map->log_cov_map(54035); 
}

resolvetype ::= REPLACE .                  {
p_cov_map->log_cov_map(184526); 
}

cmd ::= DROP TABLE ifexists fullname . {
p_cov_map->log_cov_map(31720); 
}

%type ifexists {IR*}
ifexists ::= IF EXISTS .   {
p_cov_map->log_cov_map(117289); 
}

ifexists ::= .            {
p_cov_map->log_cov_map(230221); 
}

cmd ::= createkw temp VIEW ifnotexists nm dbnm eidlist_opt AS select . {
p_cov_map->log_cov_map(123437); 
}

cmd ::= DROP VIEW ifexists fullname . {
p_cov_map->log_cov_map(33135); 
}

cmd ::= select .  {
p_cov_map->log_cov_map(81154); 
}

%type select {IR*}
%type selectnowith {IR*}
%type oneselect {IR*}
select ::= WITH wqlist selectnowith . {
p_cov_map->log_cov_map(39046); 
}

select ::= WITH RECURSIVE wqlist selectnowith . {
p_cov_map->log_cov_map(247289); 
}

select ::= selectnowith . {
p_cov_map->log_cov_map(167584); 
}

selectnowith ::= oneselect . {
p_cov_map->log_cov_map(139661); 
}

selectnowith ::= selectnowith multiselect_op oneselect .  {
p_cov_map->log_cov_map(82173); 
}

%type multiselect_op {IR*}
multiselect_op ::= UNION .             {
p_cov_map->log_cov_map(56823); 
}

multiselect_op ::= UNION ALL .             {
p_cov_map->log_cov_map(253162); 
}

multiselect_op ::= EXCEPT|INTERSECT .  {
p_cov_map->log_cov_map(182760); 
}

oneselect ::= SELECT distinct selcollist from where_opt groupby_opt having_opt orderby_opt limit_opt . {
p_cov_map->log_cov_map(240707); 
}

oneselect ::= SELECT distinct selcollist from where_opt groupby_opt having_opt window_clause orderby_opt limit_opt . {
p_cov_map->log_cov_map(51498); 
}

oneselect ::= values . {
p_cov_map->log_cov_map(245685); 
}

%type values {IR*}
values ::= VALUES LP nexprlist RP . {
p_cov_map->log_cov_map(42048); 
}

values ::= values COMMA LP nexprlist RP . {
p_cov_map->log_cov_map(249116); 
}

%type distinct {IR*}
distinct ::= DISTINCT .   {
p_cov_map->log_cov_map(32059); 
}

distinct ::= ALL .        {
p_cov_map->log_cov_map(32345); 
}

distinct ::= .           {
p_cov_map->log_cov_map(147131); 
}

%type selcollist {IR*}
%type sclp {IR*}
sclp ::= selcollist COMMA . {
p_cov_map->log_cov_map(122761); 
}

sclp ::= .                                {
p_cov_map->log_cov_map(121508); 
}

selcollist ::= sclp scanpt expr scanpt as .     {
p_cov_map->log_cov_map(110936); 
}

selcollist ::= sclp scanpt STAR . {
p_cov_map->log_cov_map(35749); 
}

selcollist ::= sclp scanpt nm DOT STAR . {
p_cov_map->log_cov_map(96035); 
}

%type as {IR*}
as ::= AS nm .    {
p_cov_map->log_cov_map(8721); 
}

as ::= ids . {
p_cov_map->log_cov_map(53601); 
}

as ::= .            {
p_cov_map->log_cov_map(10657); 
}

%type seltablist {IR*}
%type stl_prefix {IR*}
%type from {IR*}
from ::= .                {
p_cov_map->log_cov_map(31139); 
}

from ::= FROM seltablist . {
p_cov_map->log_cov_map(73402); 
}

stl_prefix ::= seltablist joinop .    {
p_cov_map->log_cov_map(10526); 
}

stl_prefix ::= .                           {
p_cov_map->log_cov_map(13413); 
}

seltablist ::= stl_prefix nm dbnm as on_using . {
p_cov_map->log_cov_map(103063); 
}

seltablist ::= stl_prefix nm dbnm as indexed_by on_using . {
p_cov_map->log_cov_map(54046); 
}

seltablist ::= stl_prefix nm dbnm LP exprlist RP as on_using . {
p_cov_map->log_cov_map(194793); 
}

seltablist ::= stl_prefix LP select RP as on_using . {
p_cov_map->log_cov_map(101595); 
}

seltablist ::= stl_prefix LP seltablist RP as on_using . {
p_cov_map->log_cov_map(155134); 
}

%type dbnm {IR*}
dbnm ::= .          {
p_cov_map->log_cov_map(17968); 
}

dbnm ::= DOT nm . {
p_cov_map->log_cov_map(204968); 
}

%type fullname {IR*}
fullname ::= nm .  {
p_cov_map->log_cov_map(182543); 
}

fullname ::= nm DOT nm . {
p_cov_map->log_cov_map(214907); 
}

%type xfullname {IR*}
xfullname ::= nm .  {
p_cov_map->log_cov_map(58496); 
}

xfullname ::= nm DOT nm .  {
p_cov_map->log_cov_map(148004); 
}

xfullname ::= nm DOT nm AS nm .  {
p_cov_map->log_cov_map(186453); 
}

xfullname ::= nm AS nm . {
p_cov_map->log_cov_map(250486); 
}

%type joinop {IR*}
joinop ::= COMMA|JOIN .              {
p_cov_map->log_cov_map(101340); 
}

joinop ::= JOIN_KW JOIN . {
p_cov_map->log_cov_map(18681); 
}

joinop ::= JOIN_KW nm JOIN . {
p_cov_map->log_cov_map(13938); 
}

joinop ::= JOIN_KW nm nm JOIN . {
p_cov_map->log_cov_map(94503); 
}

%type on_using {IR*}
on_using ::= ON expr .            {
p_cov_map->log_cov_map(208703); 
}

on_using ::= USING LP idlist RP . {
p_cov_map->log_cov_map(59111); 
}

on_using ::= .                  [OR]{
p_cov_map->log_cov_map(163093); 
}

%type indexed_opt {IR*}
%type indexed_by  {IR*}
indexed_opt ::= .                 {
p_cov_map->log_cov_map(147971); 
}

indexed_opt ::= indexed_by . {
p_cov_map->log_cov_map(46475); 
}

indexed_by ::= INDEXED BY nm . {
p_cov_map->log_cov_map(196939); 
}

indexed_by ::= NOT INDEXED .      {
p_cov_map->log_cov_map(52452); 
}

%type orderby_opt {IR*}
%type sortlist {IR*}
orderby_opt ::= .                          {
p_cov_map->log_cov_map(234569); 
}

orderby_opt ::= ORDER BY sortlist .      {
p_cov_map->log_cov_map(107079); 
}

sortlist ::= sortlist COMMA expr sortorder nulls . {
p_cov_map->log_cov_map(169766); 
}

sortlist ::= expr sortorder nulls . {
p_cov_map->log_cov_map(249397); 
}

%type sortorder {IR*}
sortorder ::= ASC .           {
p_cov_map->log_cov_map(215324); 
}

sortorder ::= DESC .          {
p_cov_map->log_cov_map(55221); 
}

sortorder ::= .              {
p_cov_map->log_cov_map(129399); 
}

%type nulls {IR*}
nulls ::= NULLS FIRST .       {
p_cov_map->log_cov_map(25107); 
}

nulls ::= NULLS LAST .        {
p_cov_map->log_cov_map(259119); 
}

nulls ::= .                  {
p_cov_map->log_cov_map(83790); 
}

%type groupby_opt {IR*}
groupby_opt ::= .                      {
p_cov_map->log_cov_map(213796); 
}

groupby_opt ::= GROUP BY nexprlist . {
p_cov_map->log_cov_map(229960); 
}

%type having_opt {IR*}
having_opt ::= .                {
p_cov_map->log_cov_map(260043); 
}

having_opt ::= HAVING expr .  {
p_cov_map->log_cov_map(163124); 
}

%type limit_opt {IR*}
limit_opt ::= .       {
p_cov_map->log_cov_map(14701); 
}

limit_opt ::= LIMIT expr . {
p_cov_map->log_cov_map(182343); 
}

limit_opt ::= LIMIT expr OFFSET expr . {
p_cov_map->log_cov_map(49905); 
}

limit_opt ::= LIMIT expr COMMA expr . {
p_cov_map->log_cov_map(190065); 
}

cmd ::= with DELETE FROM xfullname indexed_opt where_opt_ret orderby_opt limit_opt . {
p_cov_map->log_cov_map(189973); 
}

%type where_opt {IR*}
%type where_opt_ret {IR*}
where_opt ::= .                    {
p_cov_map->log_cov_map(78459); 
}

where_opt ::= WHERE expr .       {
p_cov_map->log_cov_map(49520); 
}

where_opt_ret ::= .                                      {
p_cov_map->log_cov_map(65547); 
}

where_opt_ret ::= WHERE expr .                         {
p_cov_map->log_cov_map(129612); 
}

where_opt_ret ::= RETURNING selcollist .               {
p_cov_map->log_cov_map(248997); 
}

where_opt_ret ::= WHERE expr RETURNING selcollist . {
p_cov_map->log_cov_map(80735); 
}

cmd ::= with UPDATE orconf xfullname indexed_opt SET setlist from where_opt_ret orderby_opt limit_opt .  {
p_cov_map->log_cov_map(125305); 
}

%type setlist {IR*}
setlist ::= setlist COMMA nm EQ expr . {
p_cov_map->log_cov_map(99010); 
}

setlist ::= setlist COMMA LP idlist RP EQ expr . {
p_cov_map->log_cov_map(70232); 
}

setlist ::= nm EQ expr . {
p_cov_map->log_cov_map(77420); 
}

setlist ::= LP idlist RP EQ expr . {
p_cov_map->log_cov_map(142022); 
}

cmd ::= with insert_cmd INTO xfullname idlist_opt select upsert . {
p_cov_map->log_cov_map(51267); 
}

cmd ::= with insert_cmd INTO xfullname idlist_opt DEFAULT VALUES returning . {
p_cov_map->log_cov_map(148464); 
}

%type upsert {IR*}
upsert ::= . {
p_cov_map->log_cov_map(90288); 
}

upsert ::= RETURNING selcollist .  {
p_cov_map->log_cov_map(13639); 
}

upsert ::= ON CONFLICT LP sortlist RP where_opt DO UPDATE SET setlist where_opt upsert . {
p_cov_map->log_cov_map(79356); 
}

upsert ::= ON CONFLICT LP sortlist RP where_opt DO NOTHING upsert . {
p_cov_map->log_cov_map(82908); 
}

upsert ::= ON CONFLICT DO NOTHING returning . {
p_cov_map->log_cov_map(237781); 
}

upsert ::= ON CONFLICT DO UPDATE SET setlist where_opt returning . {
p_cov_map->log_cov_map(82309); 
}

returning ::= RETURNING selcollist .  {
p_cov_map->log_cov_map(70777); 
}

returning ::= . {
p_cov_map->log_cov_map(219643); 
}

%type insert_cmd {IR*}
insert_cmd ::= INSERT orconf .   {
p_cov_map->log_cov_map(53615); 
}

insert_cmd ::= REPLACE .            {
p_cov_map->log_cov_map(245373); 
}

%type idlist_opt {IR*}
%type idlist {IR*}
idlist_opt ::= .                       {
p_cov_map->log_cov_map(104146); 
}

idlist_opt ::= LP idlist RP .    {
p_cov_map->log_cov_map(166248); 
}

idlist ::= idlist COMMA nm . {
p_cov_map->log_cov_map(84768); 
}

idlist ::= nm . {
p_cov_map->log_cov_map(239167); 
}

%type expr {IR*}
%type term {IR*}
expr ::= term . {
p_cov_map->log_cov_map(101994); 
}

expr ::= LP expr RP . {
p_cov_map->log_cov_map(107735); 
}

expr ::= id .          {
p_cov_map->log_cov_map(193321); 
}

expr ::= JOIN_KW .     {
p_cov_map->log_cov_map(89230); 
}

expr ::= nm DOT nm . {
p_cov_map->log_cov_map(59866); 
}

expr ::= nm DOT nm DOT nm . {
p_cov_map->log_cov_map(112858); 
}

term ::= NULL|FLOAT|BLOB . {
p_cov_map->log_cov_map(57813); 
}

term ::= STRING .          {
p_cov_map->log_cov_map(154867); 
}

term ::= INTEGER . {
p_cov_map->log_cov_map(165060); 
}

expr ::= VARIABLE .     {
p_cov_map->log_cov_map(194196); 
}

expr ::= expr COLLATE ids . {
p_cov_map->log_cov_map(116549); 
}

expr ::= CAST LP expr AS typetoken RP . {
p_cov_map->log_cov_map(95319); 
}

expr ::= id LP distinct exprlist RP . {
p_cov_map->log_cov_map(41612); 
}

expr ::= id LP STAR RP . {
p_cov_map->log_cov_map(137289); 
}

expr ::= id LP distinct exprlist RP filter_over . {
p_cov_map->log_cov_map(69800); 
}

expr ::= id LP STAR RP filter_over . {
p_cov_map->log_cov_map(54430); 
}

term ::= CTIME_KW . {
p_cov_map->log_cov_map(173128); 
}

expr ::= LP nexprlist COMMA expr RP . {
p_cov_map->log_cov_map(59540); 
}

expr ::= expr AND expr .        {
p_cov_map->log_cov_map(222019); 
}

expr ::= expr OR expr .     {
p_cov_map->log_cov_map(75740); 
}

expr ::= expr LT|GT|GE|LE expr . {
p_cov_map->log_cov_map(77153); 
}

expr ::= expr EQ|NE expr .  {
p_cov_map->log_cov_map(241279); 
}

expr ::= expr BITAND|BITOR|LSHIFT|RSHIFT expr . {
p_cov_map->log_cov_map(75097); 
}

expr ::= expr PLUS|MINUS expr . {
p_cov_map->log_cov_map(87793); 
}

expr ::= expr STAR|SLASH|REM expr . {
p_cov_map->log_cov_map(96234); 
}

expr ::= expr CONCAT expr . {
p_cov_map->log_cov_map(226096); 
}

%type likeop {IR*}
likeop ::= LIKE_KW|MATCH . {
p_cov_map->log_cov_map(25384); 
}

likeop ::= NOT LIKE_KW|MATCH . {
p_cov_map->log_cov_map(129592); 
}

expr ::= expr likeop expr .   [LIKE_KW] {
p_cov_map->log_cov_map(235225); 
}

expr ::= expr likeop expr ESCAPE expr .   [LIKE_KW] {
p_cov_map->log_cov_map(185420); 
}

expr ::= expr ISNULL|NOTNULL .   {
p_cov_map->log_cov_map(77801); 
}

expr ::= expr NOT NULL .    {
p_cov_map->log_cov_map(50073); 
}

expr ::= expr IS expr .     {
p_cov_map->log_cov_map(90302); 
}

expr ::= expr IS NOT expr . {
p_cov_map->log_cov_map(71868); 
}

expr ::= expr IS NOT DISTINCT FROM expr .     {
p_cov_map->log_cov_map(257857); 
}

expr ::= expr IS DISTINCT FROM expr . {
p_cov_map->log_cov_map(139003); 
}

expr ::= NOT expr .  {
p_cov_map->log_cov_map(253490); 
}

expr ::= BITNOT expr . {
p_cov_map->log_cov_map(245522); 
}

expr ::= PLUS|MINUS expr .  [BITNOT]{
p_cov_map->log_cov_map(106373); 
}

expr ::= expr PTR expr . {
p_cov_map->log_cov_map(235746); 
}

%type between_op {IR*}
between_op ::= BETWEEN .     {
p_cov_map->log_cov_map(217233); 
}

between_op ::= NOT BETWEEN . {
p_cov_map->log_cov_map(104068); 
}

expr ::= expr between_op expr AND expr .  [BETWEEN]{
p_cov_map->log_cov_map(189420); 
}

in_op ::= IN .      {
p_cov_map->log_cov_map(143210); 
}

in_op ::= NOT IN .  {
p_cov_map->log_cov_map(91977); 
}

expr ::= expr in_op LP exprlist RP .  [IN]{
p_cov_map->log_cov_map(169599); 
}

expr ::= LP select RP . {
p_cov_map->log_cov_map(195796); 
}

expr ::= expr in_op LP select RP .   [IN]{
p_cov_map->log_cov_map(18836); 
}

expr ::= expr in_op nm dbnm paren_exprlist .  [IN]{
p_cov_map->log_cov_map(151922); 
}

expr ::= EXISTS LP select RP . {
p_cov_map->log_cov_map(71455); 
}

expr ::= CASE case_operand case_exprlist case_else END . {
p_cov_map->log_cov_map(129242); 
}

%type case_exprlist {IR*}
case_exprlist ::= case_exprlist WHEN expr THEN expr . {
p_cov_map->log_cov_map(144014); 
}

case_exprlist ::= WHEN expr THEN expr . {
p_cov_map->log_cov_map(110910); 
}

%type case_else {IR*}
case_else ::= ELSE expr .         {
p_cov_map->log_cov_map(27305); 
}

case_else ::= .                     {
p_cov_map->log_cov_map(63304); 
}

%type case_operand {IR*}
case_operand ::= expr .            {
p_cov_map->log_cov_map(118183); 
}

case_operand ::= .                   {
p_cov_map->log_cov_map(136602); 
}

%type exprlist {IR*}
%type nexprlist {IR*}
exprlist ::= nexprlist . {
p_cov_map->log_cov_map(118654); 
}

exprlist ::= .                            {
p_cov_map->log_cov_map(187825); 
}

nexprlist ::= nexprlist COMMA expr . {
p_cov_map->log_cov_map(178300); 
}

nexprlist ::= expr . {
p_cov_map->log_cov_map(120917); 
}

%type paren_exprlist {IR*}
paren_exprlist ::= .   {
p_cov_map->log_cov_map(144177); 
}

paren_exprlist ::= LP exprlist RP .  {
p_cov_map->log_cov_map(134054); 
}

cmd ::= createkw uniqueflag INDEX ifnotexists nm dbnm ON nm LP sortlist RP where_opt . {
p_cov_map->log_cov_map(252499); 
}

%type uniqueflag {IR*}
uniqueflag ::= UNIQUE .  {
p_cov_map->log_cov_map(52549); 
}

uniqueflag ::= .        {
p_cov_map->log_cov_map(248134); 
}

%type eidlist {IR*}
%type eidlist_opt {IR*}
eidlist_opt ::= .                         {
p_cov_map->log_cov_map(73671); 
}

eidlist_opt ::= LP eidlist RP .         {
p_cov_map->log_cov_map(96059); 
}

eidlist ::= eidlist COMMA nm collate sortorder .  {
p_cov_map->log_cov_map(176383); 
}

eidlist ::= nm collate sortorder . {
p_cov_map->log_cov_map(59783); 
}

%type collate {IR*}
collate ::= .              {
p_cov_map->log_cov_map(231137); 
}

collate ::= COLLATE ids .   {
p_cov_map->log_cov_map(140643); 
}

cmd ::= DROP INDEX ifexists fullname .   {
p_cov_map->log_cov_map(175503); 
}

%type vinto {IR*}
cmd ::= VACUUM vinto .                {
p_cov_map->log_cov_map(83603); 
}

cmd ::= VACUUM nm vinto .          {
p_cov_map->log_cov_map(6818); 
}

vinto ::= INTO expr .              {
p_cov_map->log_cov_map(248417); 
}

vinto ::= .                          {
p_cov_map->log_cov_map(6927); 
}

cmd ::= PRAGMA nm dbnm .                {
p_cov_map->log_cov_map(19033); 
}

cmd ::= PRAGMA nm dbnm EQ nmnum .    {
p_cov_map->log_cov_map(150933); 
}

cmd ::= PRAGMA nm dbnm LP nmnum RP . {
p_cov_map->log_cov_map(188152); 
}

cmd ::= PRAGMA nm dbnm EQ minus_num . {
p_cov_map->log_cov_map(233094); 
}

cmd ::= PRAGMA nm dbnm LP minus_num RP . {
p_cov_map->log_cov_map(123459); 
}

nmnum ::= plus_num . {
p_cov_map->log_cov_map(115147); 
}

nmnum ::= nm . {
p_cov_map->log_cov_map(83744); 
}

nmnum ::= ON . {
p_cov_map->log_cov_map(232469); 
}

nmnum ::= DELETE . {
p_cov_map->log_cov_map(12626); 
}

nmnum ::= DEFAULT . {
p_cov_map->log_cov_map(65833); 
}

%token_class number INTEGER|FLOAT.
plus_num ::= PLUS number .       {
p_cov_map->log_cov_map(204031); 
}

plus_num ::= number . {
p_cov_map->log_cov_map(102986); 
}

minus_num ::= MINUS number .     {
p_cov_map->log_cov_map(30386); 
}

cmd ::= createkw trigger_decl BEGIN trigger_cmd_list END . {
p_cov_map->log_cov_map(230149); 
}

trigger_decl ::= temp TRIGGER ifnotexists nm dbnm trigger_time trigger_event ON fullname foreach_clause when_clause . {
p_cov_map->log_cov_map(260822); 
}

%type trigger_time {IR*}
trigger_time ::= BEFORE|AFTER .  {
p_cov_map->log_cov_map(19563); 
}

trigger_time ::= INSTEAD OF .  {
p_cov_map->log_cov_map(9064); 
}

trigger_time ::= .            {
p_cov_map->log_cov_map(202614); 
}

%type trigger_event {IR*}
trigger_event ::= DELETE|INSERT .   {
p_cov_map->log_cov_map(249753); 
}

trigger_event ::= UPDATE .          {
p_cov_map->log_cov_map(132833); 
}

trigger_event ::= UPDATE OF idlist . {
p_cov_map->log_cov_map(87033); 
}

foreach_clause ::= . {
p_cov_map->log_cov_map(56768); 
}

foreach_clause ::= FOR EACH ROW . {
p_cov_map->log_cov_map(36558); 
}

%type when_clause {IR*}
when_clause ::= .             {
p_cov_map->log_cov_map(203727); 
}

when_clause ::= WHEN expr . {
p_cov_map->log_cov_map(225624); 
}

%type trigger_cmd_list {IR*}
trigger_cmd_list ::= trigger_cmd_list trigger_cmd SEMI . {
p_cov_map->log_cov_map(106910); 
}

trigger_cmd_list ::= trigger_cmd SEMI . {
p_cov_map->log_cov_map(164717); 
}

%type trnm {IR*}
trnm ::= nm . {
p_cov_map->log_cov_map(256620); 
}

trnm ::= nm DOT nm . {
p_cov_map->log_cov_map(14745); 
}

tridxby ::= . {
p_cov_map->log_cov_map(227351); 
}

tridxby ::= INDEXED BY nm . {
p_cov_map->log_cov_map(245283); 
}

tridxby ::= NOT INDEXED . {
p_cov_map->log_cov_map(76965); 
}

%type trigger_cmd {IR*}
trigger_cmd ::= UPDATE orconf trnm tridxby SET setlist from where_opt scanpt .  {
p_cov_map->log_cov_map(162971); 
}

trigger_cmd ::= scanpt insert_cmd INTO trnm idlist_opt select upsert scanpt . {
p_cov_map->log_cov_map(199201); 
}

trigger_cmd ::= DELETE FROM trnm tridxby where_opt scanpt . {
p_cov_map->log_cov_map(261923); 
}

trigger_cmd ::= scanpt select scanpt . {
p_cov_map->log_cov_map(255506); 
}

expr ::= RAISE LP IGNORE RP .  {
p_cov_map->log_cov_map(105840); 
}

expr ::= RAISE LP raisetype COMMA nm RP .  {
p_cov_map->log_cov_map(99437); 
}

%type raisetype {IR*}
raisetype ::= ROLLBACK .  {
p_cov_map->log_cov_map(225310); 
}

raisetype ::= ABORT .     {
p_cov_map->log_cov_map(61322); 
}

raisetype ::= FAIL .      {
p_cov_map->log_cov_map(233692); 
}

cmd ::= DROP TRIGGER ifexists fullname . {
p_cov_map->log_cov_map(232223); 
}

cmd ::= ATTACH database_kw_opt expr AS expr key_opt . {
p_cov_map->log_cov_map(80009); 
}

cmd ::= DETACH database_kw_opt expr . {
p_cov_map->log_cov_map(166311); 
}

%type key_opt {IR*}
key_opt ::= .                     {
p_cov_map->log_cov_map(132385); 
}

key_opt ::= KEY expr .          {
p_cov_map->log_cov_map(152821); 
}

database_kw_opt ::= DATABASE . {
p_cov_map->log_cov_map(105806); 
}

database_kw_opt ::= . {
p_cov_map->log_cov_map(141142); 
}

cmd ::= REINDEX .                {
p_cov_map->log_cov_map(76544); 
}

cmd ::= REINDEX nm dbnm .  {
p_cov_map->log_cov_map(223768); 
}

cmd ::= ANALYZE .                {
p_cov_map->log_cov_map(99551); 
}

cmd ::= ANALYZE nm dbnm .  {
p_cov_map->log_cov_map(180992); 
}

cmd ::= ALTER TABLE fullname RENAME TO nm . {
p_cov_map->log_cov_map(203329); 
}

cmd ::= ALTER TABLE add_column_fullname ADD kwcolumn_opt columnname carglist . {
p_cov_map->log_cov_map(157790); 
}

cmd ::= ALTER TABLE fullname DROP kwcolumn_opt nm . {
p_cov_map->log_cov_map(196599); 
}

add_column_fullname ::= fullname . {
p_cov_map->log_cov_map(214203); 
}

cmd ::= ALTER TABLE fullname RENAME kwcolumn_opt nm TO nm . {
p_cov_map->log_cov_map(173433); 
}

kwcolumn_opt ::= . {
p_cov_map->log_cov_map(223032); 
}

kwcolumn_opt ::= COLUMNKW . {
p_cov_map->log_cov_map(172670); 
}

cmd ::= create_vtab .                       {
p_cov_map->log_cov_map(106920); 
}

cmd ::= create_vtab LP vtabarglist RP .  {
p_cov_map->log_cov_map(172316); 
}

create_vtab ::= createkw VIRTUAL TABLE ifnotexists nm dbnm USING nm . {
p_cov_map->log_cov_map(188651); 
}

vtabarglist ::= vtabarg . {
p_cov_map->log_cov_map(215825); 
}

vtabarglist ::= vtabarglist COMMA vtabarg . {
p_cov_map->log_cov_map(39026); 
}

vtabarg ::= .                       {
p_cov_map->log_cov_map(227803); 
}

vtabarg ::= vtabarg vtabargtoken . {
p_cov_map->log_cov_map(45815); 
}

vtabargtoken ::= ANY .            {
p_cov_map->log_cov_map(34843); 
}

vtabargtoken ::= lp anylist RP .  {
p_cov_map->log_cov_map(37750); 
}

lp ::= LP .                       {
p_cov_map->log_cov_map(136922); 
}

anylist ::= . {
p_cov_map->log_cov_map(98655); 
}

anylist ::= anylist LP anylist RP . {
p_cov_map->log_cov_map(254891); 
}

anylist ::= anylist ANY . {
p_cov_map->log_cov_map(251396); 
}

%type wqlist {IR*}
%type wqitem {IR*}
with ::= . {
p_cov_map->log_cov_map(97599); 
}

with ::= WITH wqlist .              {
p_cov_map->log_cov_map(240362); 
}

with ::= WITH RECURSIVE wqlist .    {
p_cov_map->log_cov_map(154001); 
}

%type wqas {IR*}
wqas ::= AS .                  {
p_cov_map->log_cov_map(27268); 
}

wqas ::= AS MATERIALIZED .     {
p_cov_map->log_cov_map(74498); 
}

wqas ::= AS NOT MATERIALIZED . {
p_cov_map->log_cov_map(242870); 
}

wqitem ::= nm eidlist_opt wqas LP select RP . {
p_cov_map->log_cov_map(143183); 
}

wqlist ::= wqitem . {
p_cov_map->log_cov_map(121779); 
}

wqlist ::= wqlist COMMA wqitem . {
p_cov_map->log_cov_map(64641); 
}

%type windowdefn_list {IR*}
windowdefn_list ::= windowdefn . {
p_cov_map->log_cov_map(62211); 
}

windowdefn_list ::= windowdefn_list COMMA windowdefn . {
p_cov_map->log_cov_map(50837); 
}

%type windowdefn {IR*}
windowdefn ::= nm AS LP window RP . {
p_cov_map->log_cov_map(51073); 
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
p_cov_map->log_cov_map(174989); 
}

window ::= nm PARTITION BY nexprlist orderby_opt frame_opt . {
p_cov_map->log_cov_map(184993); 
}

window ::= ORDER BY sortlist frame_opt . {
p_cov_map->log_cov_map(114449); 
}

window ::= nm ORDER BY sortlist frame_opt . {
p_cov_map->log_cov_map(150898); 
}

window ::= frame_opt . {
p_cov_map->log_cov_map(229312); 
}

window ::= nm frame_opt . {
p_cov_map->log_cov_map(182371); 
}

frame_opt ::= .                             {
p_cov_map->log_cov_map(235137); 
}

frame_opt ::= range_or_rows frame_bound_s frame_exclude_opt . {
p_cov_map->log_cov_map(72947); 
}

frame_opt ::= range_or_rows BETWEEN frame_bound_s AND frame_bound_e frame_exclude_opt . {
p_cov_map->log_cov_map(150758); 
}

range_or_rows ::= RANGE|ROWS|GROUPS .   {
p_cov_map->log_cov_map(242597); 
}

frame_bound_s ::= frame_bound .         {
p_cov_map->log_cov_map(220904); 
}

frame_bound_s ::= UNBOUNDED PRECEDING . {
p_cov_map->log_cov_map(38674); 
}

frame_bound_e ::= frame_bound .         {
p_cov_map->log_cov_map(50542); 
}

frame_bound_e ::= UNBOUNDED FOLLOWING . {
p_cov_map->log_cov_map(22611); 
}

frame_bound ::= expr PRECEDING|FOLLOWING . {
p_cov_map->log_cov_map(7047); 
}

frame_bound ::= CURRENT ROW .           {
p_cov_map->log_cov_map(142224); 
}

%type frame_exclude_opt {IR*}
frame_exclude_opt ::= . {
p_cov_map->log_cov_map(138644); 
}

frame_exclude_opt ::= EXCLUDE frame_exclude . {
p_cov_map->log_cov_map(83692); 
}

%type frame_exclude {IR*}
frame_exclude ::= NO OTHERS .   {
p_cov_map->log_cov_map(102555); 
}

frame_exclude ::= CURRENT ROW . {
p_cov_map->log_cov_map(138442); 
}

frame_exclude ::= GROUP|TIES .  {
p_cov_map->log_cov_map(131841); 
}

%type window_clause {IR*}
window_clause ::= WINDOW windowdefn_list . {
p_cov_map->log_cov_map(148714); 
}

filter_over ::= filter_clause over_clause . {
p_cov_map->log_cov_map(206530); 
}

filter_over ::= over_clause . {
p_cov_map->log_cov_map(195181); 
}

filter_over ::= filter_clause . {
p_cov_map->log_cov_map(189731); 
}

over_clause ::= OVER LP window RP . {
p_cov_map->log_cov_map(32671); 
}

over_clause ::= OVER nm . {
p_cov_map->log_cov_map(138668); 
}

filter_clause ::= FILTER LP WHERE expr RP .  {
p_cov_map->log_cov_map(229312); 
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
