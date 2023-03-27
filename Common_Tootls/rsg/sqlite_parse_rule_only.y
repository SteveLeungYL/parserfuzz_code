// Reprint of input file "parse.y".
// Symbols:
//   0 $                      160 ELSE                  
//   1 SEMI                   161 INDEX                 
//   2 EXPLAIN                162 ALTER                 
//   3 QUERY                  163 ADD                   
//   4 PLAN                   164 WINDOW                
//   5 BEGIN                  165 OVER                  
//   6 TRANSACTION            166 FILTER                
//   7 DEFERRED               167 COLUMN                
//   8 IMMEDIATE              168 AGG_FUNCTION          
//   9 EXCLUSIVE              169 AGG_COLUMN            
//  10 COMMIT                 170 TRUEFALSE             
//  11 END                    171 ISNOT                 
//  12 ROLLBACK               172 FUNCTION              
//  13 SAVEPOINT              173 UMINUS                
//  14 RELEASE                174 UPLUS                 
//  15 TO                     175 TRUTH                 
//  16 TABLE                  176 REGISTER              
//  17 CREATE                 177 VECTOR                
//  18 IF                     178 SELECT_COLUMN         
//  19 NOT                    179 IF_NULL_ROW           
//  20 EXISTS                 180 ASTERISK              
//  21 TEMP                   181 SPAN                  
//  22 LP                     182 ERROR                 
//  23 RP                     183 SPACE                 
//  24 AS                     184 ILLEGAL               
//  25 COMMA                  185 input                 
//  26 WITHOUT                186 cmdlist               
//  27 ABORT                  187 ecmd                  
//  28 ACTION                 188 cmdx                  
//  29 AFTER                  189 explain               
//  30 ANALYZE                190 cmd                   
//  31 ASC                    191 transtype             
//  32 ATTACH                 192 trans_opt             
//  33 BEFORE                 193 nm                    
//  34 BY                     194 savepoint_opt         
//  35 CASCADE                195 create_table          
//  36 CAST                   196 create_table_args     
//  37 CONFLICT               197 createkw              
//  38 DATABASE               198 temp                  
//  39 DESC                   199 ifnotexists           
//  40 DETACH                 200 dbnm                  
//  41 EACH                   201 columnlist            
//  42 FAIL                   202 conslist_opt          
//  43 OR                     203 table_option_set      
//  44 AND                    204 select                
//  45 IS                     205 table_option          
//  46 MATCH                  206 columnname            
//  47 LIKE_KW                207 carglist              
//  48 BETWEEN                208 typetoken             
//  49 IN                     209 typename              
//  50 ISNULL                 210 signed                
//  51 NOTNULL                211 plus_num              
//  52 NE                     212 minus_num             
//  53 EQ                     213 scanpt                
//  54 GT                     214 scantok               
//  55 LE                     215 ccons                 
//  56 LT                     216 term                  
//  57 GE                     217 expr                  
//  58 ESCAPE                 218 onconf                
//  59 ID                     219 sortorder             
//  60 COLUMNKW               220 autoinc               
//  61 DO                     221 eidlist_opt           
//  62 FOR                    222 refargs               
//  63 IGNORE                 223 defer_subclause       
//  64 INITIALLY              224 generated             
//  65 INSTEAD                225 refarg                
//  66 NO                     226 refact                
//  67 KEY                    227 init_deferred_pred_opt
//  68 OF                     228 conslist              
//  69 OFFSET                 229 tconscomma            
//  70 PRAGMA                 230 tcons                 
//  71 RAISE                  231 sortlist              
//  72 RECURSIVE              232 eidlist               
//  73 REPLACE                233 defer_subclause_opt   
//  74 RESTRICT               234 orconf                
//  75 ROW                    235 resolvetype           
//  76 ROWS                   236 raisetype             
//  77 TRIGGER                237 ifexists              
//  78 VACUUM                 238 fullname              
//  79 VIEW                   239 selectnowith          
//  80 VIRTUAL                240 oneselect             
//  81 WITH                   241 wqlist                
//  82 NULLS                  242 multiselect_op        
//  83 FIRST                  243 distinct              
//  84 LAST                   244 selcollist            
//  85 CURRENT                245 from                  
//  86 FOLLOWING              246 where_opt             
//  87 PARTITION              247 groupby_opt           
//  88 PRECEDING              248 having_opt            
//  89 RANGE                  249 orderby_opt           
//  90 UNBOUNDED              250 limit_opt             
//  91 EXCLUDE                251 window_clause         
//  92 GROUPS                 252 values                
//  93 OTHERS                 253 nexprlist             
//  94 TIES                   254 sclp                  
//  95 GENERATED              255 as                    
//  96 ALWAYS                 256 seltablist            
//  97 MATERIALIZED           257 stl_prefix            
//  98 REINDEX                258 joinop                
//  99 RENAME                 259 on_using              
// 100 CTIME_KW               260 indexed_by            
// 101 ANY                    261 exprlist              
// 102 BITAND                 262 xfullname             
// 103 BITOR                  263 idlist                
// 104 LSHIFT                 264 indexed_opt           
// 105 RSHIFT                 265 nulls                 
// 106 PLUS                   266 with                  
// 107 MINUS                  267 where_opt_ret         
// 108 STAR                   268 setlist               
// 109 SLASH                  269 insert_cmd            
// 110 REM                    270 idlist_opt            
// 111 CONCAT                 271 upsert                
// 112 PTR                    272 returning             
// 113 COLLATE                273 filter_over           
// 114 BITNOT                 274 likeop                
// 115 ON                     275 between_op            
// 116 INDEXED                276 in_op                 
// 117 STRING                 277 paren_exprlist        
// 118 JOIN_KW                278 case_operand          
// 119 CONSTRAINT             279 case_exprlist         
// 120 DEFAULT                280 case_else             
// 121 NULL                   281 uniqueflag            
// 122 PRIMARY                282 collate               
// 123 UNIQUE                 283 vinto                 
// 124 CHECK                  284 nmnum                 
// 125 REFERENCES             285 trigger_decl          
// 126 AUTOINCR               286 trigger_cmd_list      
// 127 INSERT                 287 trigger_time          
// 128 DELETE                 288 trigger_event         
// 129 UPDATE                 289 foreach_clause        
// 130 SET                    290 when_clause           
// 131 DEFERRABLE             291 trigger_cmd           
// 132 FOREIGN                292 trnm                  
// 133 DROP                   293 tridxby               
// 134 UNION                  294 database_kw_opt       
// 135 ALL                    295 key_opt               
// 136 EXCEPT                 296 add_column_fullname   
// 137 INTERSECT              297 kwcolumn_opt          
// 138 SELECT                 298 create_vtab           
// 139 VALUES                 299 vtabarglist           
// 140 DISTINCT               300 vtabarg               
// 141 DOT                    301 vtabargtoken          
// 142 FROM                   302 lp                    
// 143 JOIN                   303 anylist               
// 144 USING                  304 wqitem                
// 145 ORDER                  305 wqas                  
// 146 GROUP                  306 windowdefn_list       
// 147 HAVING                 307 windowdefn            
// 148 LIMIT                  308 window                
// 149 WHERE                  309 frame_opt             
// 150 RETURNING              310 part_opt              
// 151 INTO                   311 filter_clause         
// 152 NOTHING                312 over_clause           
// 153 FLOAT                  313 range_or_rows         
// 154 BLOB                   314 frame_bound           
// 155 INTEGER                315 frame_bound_s         
// 156 VARIABLE               316 frame_bound_e         
// 157 CASE                   317 frame_exclude_opt     
// 158 WHEN                   318 frame_exclude         
// 159 THEN                  
explain ::= EXPLAIN.
explain ::= EXPLAIN QUERY PLAN.
cmdx ::= cmd.
cmd ::= BEGIN transtype trans_opt.
transtype ::=.
transtype ::= DEFERRED.
transtype ::= IMMEDIATE.
transtype ::= EXCLUSIVE.
cmd ::= COMMIT trans_opt.
cmd ::= END trans_opt.
cmd ::= ROLLBACK trans_opt.
cmd ::= SAVEPOINT nm.
cmd ::= RELEASE savepoint_opt nm.
cmd ::= ROLLBACK trans_opt TO savepoint_opt nm.
create_table ::= createkw temp TABLE ifnotexists nm dbnm.
createkw ::= CREATE.
ifnotexists ::=.
ifnotexists ::= IF NOT EXISTS.
temp ::= TEMP.
temp ::=.
create_table_args ::= LP columnlist conslist_opt RP table_option_set.
create_table_args ::= AS selectnowith.
table_option_set ::=.
table_option_set ::= table_option.
table_option ::= without_rowid COMMA strict_option.
table_option ::= strict_option.
table_option ::= without_rowid.
without_rowid ::= WITHOUT ROWID.
strict_option ::= STRICT.
columnname ::= nm typetoken.
typetoken ::=.
typetoken ::= typename LP signed RP.
typetoken ::= typename LP signed COMMA signed RP.
typename ::= typename ID.
typename ::= typename STRING.
scanpt ::=.
scantok ::=.
ccons ::= CONSTRAINT nm.
ccons ::= DEFAULT scantok term.
ccons ::= DEFAULT LP expr RP.
ccons ::= DEFAULT PLUS scantok term.
ccons ::= DEFAULT MINUS scantok term.
ccons ::= DEFAULT scantok ID.
ccons ::= DEFAULT scantok INDEXED.
ccons ::= NOT NULL onconf.
ccons ::= PRIMARY KEY sortorder onconf autoinc.
ccons ::= UNIQUE onconf.
ccons ::= CHECK LP expr RP.
ccons ::= REFERENCES nm eidlist_opt refargs.
ccons ::= defer_subclause.
ccons ::= COLLATE NOCASE.
ccons ::= COLLATE BINARY.
generated ::= LP expr RP.
generated ::= LP expr RP ID.
autoinc ::=.
autoinc ::= AUTOINCR.
refargs ::=.
refargs ::= refargs refarg.
refarg ::= MATCH nm.
refarg ::= ON INSERT refact.
refarg ::= ON DELETE refact.
refarg ::= ON UPDATE refact.
refact ::= SET NULL.
refact ::= SET DEFAULT.
refact ::= CASCADE.
refact ::= RESTRICT.
refact ::= NO ACTION.
defer_subclause ::= NOT DEFERRABLE init_deferred_pred_opt.
defer_subclause ::= DEFERRABLE init_deferred_pred_opt.
init_deferred_pred_opt ::=.
init_deferred_pred_opt ::= INITIALLY DEFERRED.
init_deferred_pred_opt ::= INITIALLY IMMEDIATE.
conslist_opt ::=.
tconscomma ::= COMMA.
tcons ::= CONSTRAINT nm.
tcons ::= PRIMARY KEY LP sortlist autoinc RP onconf.
tcons ::= UNIQUE LP sortlist RP onconf.
tcons ::= CHECK LP expr RP onconf.
tcons ::= FOREIGN KEY LP eidlist RP REFERENCES nm eidlist_opt refargs defer_subclause_opt.
defer_subclause_opt ::=.
onconf ::=.
onconf ::= ON CONFLICT resolvetype.
orconf ::=.
orconf ::= OR resolvetype.
resolvetype ::= IGNORE.
resolvetype ::= REPLACE.
cmd ::= DROP TABLE ifexists fullname.
ifexists ::= IF EXISTS.
ifexists ::=.
cmd ::= createkw temp VIEW ifnotexists nm dbnm eidlist_opt AS selectnowith.
cmdCreateView ::= createkw temp VIEW ifnotexists nm dbnm eidlist_opt AS selectnowith.
cmd ::= DROP VIEW ifexists fullname.
cmd ::= select.
cmdSelect ::= select.
select ::= WITH wqlist selectnowith.
select ::= WITH RECURSIVE wqlist selectnowith.
select ::= selectnowith.
selectnowith ::= selectnowith multiselect_op oneselect.
multiselect_op ::= UNION.
multiselect_op ::= UNION ALL.
multiselect_op ::= EXCEPT.
multiselect_op ::= INTERSECT.
oneselect ::= SELECT distinct selcollist from where_opt groupby_opt having_opt orderby_opt limit_opt.
oneselect ::= SELECT distinct selcollist from where_opt groupby_opt having_opt window_clause orderby_opt limit_opt.
values ::= VALUES LP nexprlist RP.
values ::= values COMMA LP nexprlist RP.
distinct ::= DISTINCT.
distinct ::= ALL.
distinct ::=.
selcollist ::= expr as.
selcollist ::= STAR.
selcollist ::= nm DOT STAR.
as ::= AS nm.
as ::=.
from ::=.
from ::= FROM seltablist.
stl_prefix ::= seltablistnorecursive joinop.
stl_prefix ::=.
seltablistnorecursive ::= nm dbnm as.
seltablistnorecursive ::= nm dbnm as indexed_by.
seltablistnorecursive ::= nm dbnm LP exprlist RP as.
seltablistnorecursive ::= LP selectnowith RP as.
seltablist ::= stl_prefix nm dbnm as on_using.
seltablist ::= stl_prefix nm dbnm as indexed_by on_using.
seltablist ::= stl_prefix nm dbnm LP exprlist RP as on_using.
seltablist ::= stl_prefix LP selectnowith RP as on_using.
seltablist ::= stl_prefix LP seltablistnorecursive RP as on_using.
dbnm ::=.
fullname ::= nm.
xfullname ::= nm.
xfullname ::= nm AS nm.
joinop ::= COMMA|JOIN|CROSS|INNER JOIN.
joinop ::= JOIN_KW join_new_keyword_alternative JOIN.
joinop ::= NATURAL JOIN_KW join_new_keyword_alternative JOIN.
joinop ::= NATURAL INNER JOIN.
join_new_keyword_alternative ::= OUTER.
join_new_keyword_alternative ::= .
on_using ::= ON expr.
on_using ::= USING LP idlist RP.
on_using ::=. [OR]
indexed_opt ::=.
indexed_by ::= INDEXED BY nm.
indexed_by ::= NOT INDEXED.
orderby_opt ::=.
orderby_opt ::= ORDER BY sortlist.
sortlistnorecursive ::= expr sortorder nulls.
sortlist ::= sortlistnorecursive COMMA expr sortorder nulls.
sortlist ::= expr sortorder nulls.
sortorder ::= ASC.
sortorder ::= DESC.
sortorder ::=.
nulls ::= NULLS FIRST.
nulls ::= NULLS LAST.
nulls ::=.
groupby_opt ::=.
groupby_opt ::= GROUP BY nexprlist.
having_opt ::=.
having_opt ::= HAVING expr.
limit_opt ::=.
limit_opt ::= LIMIT expr.
limit_opt ::= LIMIT expr OFFSET expr.
limit_opt ::= LIMIT expr COMMA expr.
cmd ::= with DELETE FROM xfullname indexed_opt where_opt_ret.
where_opt ::=.
where_opt ::= WHERE expr.
where_opt_ret ::=.
where_opt_ret ::= WHERE expr.
where_opt_ret ::= RETURNING selcollist.
where_opt_ret ::= WHERE expr RETURNING selcollist.
cmd ::= with UPDATE orconf xfullname indexed_opt SET setlist from where_opt_ret.
cmdUpdate ::= with UPDATE orconf xfullname indexed_opt SET setlist from where_opt_ret.
setlistnorecursive ::= nm EQ expr.
setlistnorecursive ::= LP idlist RP EQ expr.
setlist ::= setlistnorecursive COMMA nm EQ expr.
setlist ::= setlistnorecursive COMMA LP idlist RP EQ expr.
setlist ::= nm EQ expr.
setlist ::= LP idlist RP EQ expr.
cmd ::= with insert_cmd INTO xfullname idlist_opt selectnowith upsert.
cmdInsert ::= with insert_cmd INTO xfullname idlist_opt selectnowith upsert.
cmd ::= with insert_cmd INTO xfullname idlist_opt DEFAULT VALUES returning.
cmdInsert ::= with insert_cmd INTO xfullname idlist_opt DEFAULT VALUES returning.
upsert ::=.
upsert ::= RETURNING selcollist.
upsert ::= ON CONFLICT LP sortlist RP where_opt DO UPDATE SET setlist where_opt upsert.
upsert ::= ON CONFLICT LP sortlist RP where_opt DO NOTHING upsert.
upsert ::= ON CONFLICT DO NOTHING returning.
upsert ::= ON CONFLICT DO UPDATE SET setlist where_opt returning.
returning ::= RETURNING selcollist.
insert_cmd ::= INSERT orconf.
insert_cmd ::= REPLACE.
idlist_opt ::=.
idlist_opt ::= LP idlist RP.
idlist ::= idlist COMMA nm.
idlist ::= nm.
expr ::= LP expr RP.
exprnorecursive ::= LP expr RP.
expr ::= ID.
exprnorecursive ::= ID.
expr ::= nm DOT nm.
exprnorecursive ::= nm DOT nm.
expr ::= nm DOT nm DOT nm.
exprnorecursive ::= nm DOT nm DOT nm.
term ::= NULL|FLOAT|BLOB.
term ::= STRING.
term ::= INTEGER.
expr ::= VARIABLE.
exprnorecursive ::= VARIABLE.
expr ::= exprnorecursive COLLATE ID.
expr ::= exprnorecursive COLLATE STRING.
expr ::= CAST LP exprnorecursive AS typetoken RP.
expr ::= ID LP distinct exprlistnorecursive RP.
expr ::= ID LP STAR RP.
exprnorecursive ::= ID LP STAR RP.
expr ::= ID LP distinct exprlistnorecursive RP filter_over.
expr ::= ID LP STAR RP filter_over.
exprnorecursive ::= ID LP STAR RP filter_over.
term ::= CTIME_KW.
expr ::= LP nexprlistnorecursive COMMA expr RP.
expr ::= exprnorecursive AND exprnorecursive.
expr ::= exprnorecursive OR exprnorecursive.
expr ::= exprnorecursive LT exprnorecursive.
expr ::= exprnorecursive GT exprnorecursive.
expr ::= exprnorecursive GE exprnorecursive.
expr ::= exprnorecursive LE exprnorecursive.
expr ::= exprnorecursive EQ exprnorecursive.
expr ::= exprnorecursive NE exprnorecursive.
expr ::= exprnorecursive BITAND exprnorecursive.
expr ::= exprnorecursive BITOR exprnorecursive.
expr ::= exprnorecursive LSHIFT exprnorecursive.
expr ::= exprnorecursive RSHIFT exprnorecursive.
expr ::= exprnorecursive PLUS exprnorecursive.
expr ::= exprnorecursive MINUS exprnorecursive.
expr ::= exprnorecursive STAR exprnorecursive.
expr ::= exprnorecursive SLASH exprnorecursive.
expr ::= exprnorecursive REM exprnorecursive.
expr ::= exprnorecursive CONCAT exprnorecursive.
likeop ::= NOT LIKE_KW.
likeop ::= NOT MATCH.
expr ::= exprnorecursive likeop exprnorecursive.
expr ::= exprnorecursive likeop exprnorecursive ESCAPE exprnorecursive.
expr ::= exprnorecursive ISNULL.
expr ::= exprnorecursive NOTNULL.
expr ::= exprnorecursive NOT NULL.
expr ::= exprnorecursive IS exprnorecursive.
expr ::= exprnorecursive IS NOT exprnorecursive.
expr ::= exprnorecursive IS NOT DISTINCT FROM exprnorecursive.
expr ::= exprnorecursive IS DISTINCT FROM exprnorecursive.
expr ::= NOT exprnorecursive.
expr ::= BITNOT exprnorecursive.
expr ::= PLUS exprnorecursive.
expr ::= MINUS exprnorecursive.
between_op ::= BETWEEN.
between_op ::= NOT BETWEEN.
expr ::= exprnorecursive between_op exprnorecursive AND exprnorecursive.
in_op ::= IN.
in_op ::= NOT IN.
expr ::= expr in_op LP exprlistnorecursive RP.
expr ::= LP selectnowith RP.
expr ::= exprnorecursive in_op LP selectwith RP.
expr ::= exprnorecursive in_op nm dbnm paren_exprlist.
expr ::= EXISTS LP selectnowith RP.
expr ::= CASE case_operand case_exprlist case_else END.
case_exprlist ::= WHEN expr THEN expr.
case_else ::= ELSE exprnorecursive.
case_else ::=.
case_operand ::= exprnorecursive.
case_operand ::=.
nexprlist ::= exprnorecursive.
nexprlistnorecursive ::= exprnorecursive.
paren_exprlist ::=.
paren_exprlist ::= LP exprlist RP.
cmd ::= createkw uniqueflag INDEX ifnotexists nm dbnm ON nm LP sortlist RP where_opt.
cmdCreateIndex ::= createkw uniqueflag INDEX ifnotexists nm dbnm ON nm LP sortlist RP where_opt.
uniqueflag ::= UNIQUE.
uniqueflag ::=.
eidlist_opt ::=.
eidlist_opt ::= LP eidlist RP.
eidlistnorecursive ::= nm collate sortorder.
eidlist ::= eidlistnorecursive COMMA nm collate sortorder.
eidlist ::= nm collate sortorder.
collate ::=.
collate ::= COLLATE ID.
collate ::= COLLATE STRING.
cmd ::= DROP INDEX ifexists fullname.
cmd ::= VACUUM vinto.
cmd ::= VACUUM nm vinto.
vinto ::= INTO expr.
vinto ::=.
cmdPragma ::= PRAGMA nm dbnm.
cmdPragma ::= PRAGMA nm dbnm EQ nmnum.
cmdPragma ::= PRAGMA nm dbnm LP nmnum RP.
cmdPragma ::= PRAGMA nm dbnm EQ minus_num.
cmdPragma ::= PRAGMA nm dbnm LP minus_num RP.
cmd ::= PRAGMA nm dbnm.
cmd ::= PRAGMA nm dbnm EQ nmnum.
cmd ::= PRAGMA nm dbnm LP nmnum RP.
cmd ::= PRAGMA nm dbnm EQ minus_num.
cmd ::= PRAGMA nm dbnm LP minus_num RP.
plus_num ::= PLUS INTEGER.
plus_num ::= PLUS FLOAT.
minus_num ::= MINUS INTEGER.
minus_num ::= MINUS FLOAT.
cmd ::= createkw trigger_decl BEGIN trigger_cmd_list END.
trigger_decl ::= temp TRIGGER ifnotexists nm dbnm trigger_time trigger_event ON fullname foreach_clause when_clause.
trigger_time ::= BEFORE|AFTER.
trigger_time ::= INSTEAD OF.
trigger_time ::=.
trigger_event ::= DELETE|INSERT.
trigger_event ::= UPDATE.
trigger_event ::= UPDATE OF idlist.
when_clause ::=.
when_clause ::= WHEN expr.
trigger_cmd_list_norecursive ::= trigger_cmd SEMI.
trigger_cmd_list ::= trigger_cmd_list_norecursive trigger_cmd SEMI.
trigger_cmd_list ::= trigger_cmd SEMI.
trnm ::= nm DOT nm.
tridxby ::= INDEXED BY nm.
tridxby ::= NOT INDEXED.
trigger_cmd ::= UPDATE orconf trnm tridxby SET setlist from where_opt scanpt.
trigger_cmd ::= scanpt insert_cmd INTO trnm idlist_opt selectnowith upsert scanpt.
trigger_cmd ::= DELETE FROM trnm tridxby where_opt scanpt.
trigger_cmd ::= scanpt selectnowith scanpt.
expr ::= RAISE LP IGNORE RP.
exprnorecursive ::= RAISE LP IGNORE RP.
expr ::= RAISE LP raisetype COMMA nm RP.
exprnorecursive ::= RAISE LP raisetype COMMA nm RP.
raisetype ::= ROLLBACK.
raisetype ::= ABORT.
raisetype ::= FAIL.
cmd ::= DROP TRIGGER ifexists fullname.
cmd ::= ATTACH database_kw_opt expr AS expr key_opt.
cmd ::= DETACH database_kw_opt expr.
key_opt ::=.
key_opt ::= KEY expr.
cmd ::= REINDEX.
cmd ::= REINDEX nm dbnm.
cmd ::= ANALYZE.
cmd ::= ANALYZE nm dbnm.
cmdAlter ::= ALTER TABLE fullname RENAME TO nm.
cmdAlter ::= ALTER TABLE add_column_fullname ADD kwcolumn_opt columnname carglist.
cmdAlter ::= ALTER TABLE fullname DROP kwcolumn_opt nm.
cmdAlter ::= ALTER TABLE fullname RENAME kwcolumn_opt nm TO nm.
cmd ::= ALTER TABLE fullname RENAME TO nm.
cmd ::= ALTER TABLE add_column_fullname ADD kwcolumn_opt columnname carglist.
cmd ::= ALTER TABLE fullname DROP kwcolumn_opt nm.
add_column_fullname ::= fullname.
cmd ::= ALTER TABLE fullname RENAME kwcolumn_opt nm TO nm.
cmd ::= create_vtab.
cmd ::= create_vtab LP vtabarglist RP.
create_vtab ::= createkw VIRTUAL TABLE ifnotexists nm dbnm USING nm.
vtabarg ::=.
vtabargtoken ::= ANY.
vtabargtoken ::= lp anylist RP.
lp ::= LP.
with ::= WITH wqlist.
with ::= WITH RECURSIVE wqlist.
wqas ::= AS.
wqas ::= AS MATERIALIZED.
wqas ::= AS NOT MATERIALIZED.
wqitem ::= nm eidlist_opt wqas LP selectnowith RP.
wqlist ::= wqitem.
wqlistnorecursive ::= wqitem.
wqlist ::= wqlistnorecursive COMMA wqitem.
windowdefn_list ::= windowdefn.
windowdefn_list_norecursive ::= windowdefn.
windowdefn_list ::= windowdefn_list_norecursive COMMA windowdefn.
windowdefn ::= nm AS LP window RP.
window ::= PARTITION BY nexprlist orderby_opt frame_opt.
window ::= nm PARTITION BY nexprlist orderby_opt frame_opt.
window ::= ORDER BY sortlist frame_opt.
window ::= nm ORDER BY sortlist frame_opt.
window ::= frame_opt.
window ::= nm frame_opt.
frame_opt ::=.
frame_opt ::= range_or_rows frame_bound_s frame_exclude_opt.
frame_opt ::= range_or_rows BETWEEN frame_bound_s AND frame_bound_e frame_exclude_opt.
range_or_rows ::= RANGE|ROWS|GROUPS.
frame_bound_s ::= frame_bound.
frame_bound_s ::= UNBOUNDED PRECEDING.
frame_bound_e ::= frame_bound.
frame_bound_e ::= UNBOUNDED FOLLOWING.
frame_bound ::= expr PRECEDING.
frame_bound ::= expr FOLLOWING.
frame_bound ::= CURRENT ROW.
frame_exclude_opt ::=.
frame_exclude_opt ::= EXCLUDE frame_exclude.
frame_exclude ::= NO OTHERS.
frame_exclude ::= CURRENT ROW.
frame_exclude ::= GROUP|TIES.
window_clause ::= WINDOW windowdefn_list.
filter_over ::= filter_clause over_clause.
filter_over ::= over_clause.
filter_over ::= filter_clause.
over_clause ::= OVER LP window RP.
over_clause ::= OVER nm.
filter_clause ::= FILTER LP WHERE expr RP.
input ::= cmdlist.
cmdlist ::= cmdlist ecmd.
cmdlist ::= ecmd.
ecmd ::= SEMI.
ecmd ::= cmdx SEMI.
ecmd ::= explain cmdx SEMI.
trans_opt ::=.
trans_opt ::= TRANSACTION.
trans_opt ::= TRANSACTION nm.
savepoint_opt ::= SAVEPOINT.
savepoint_opt ::=.
cmd ::= create_table create_table_args.
cmdCreateTable ::= create_table create_table_args.
table_option_set ::= table_option.
columnlist ::= columnlistnorecursive COMMA columnname carglist.
columnlistnorecursive ::= columnname carglist.
columnlist ::= columnname carglist.
nm ::= ID.
nm ::= STRING.
typetoken ::= typename.
typename ::= ID|STRING.
signed ::= plus_num.
signed ::= minus_num.
carglist ::= carglist ccons.
carglist ::=.
ccons ::= NULL onconf.
ccons ::= GENERATED ALWAYS AS generated.
ccons ::= AS generated.
conslist_opt ::= COMMA conslist.
conslist ::= conslistnorecursive tconscomma tcons.
conslistnorecursive ::= tcons.
conslist ::= tcons.
tconscomma ::=.
defer_subclause_opt ::= defer_subclause.
resolvetype ::= raisetype.
selectnowith ::= oneselect.
oneselect ::= values.
as ::= ID|STRING.
indexed_opt ::= indexed_by.
returning ::=.
expr ::= term.
likeop ::= LIKE_KW|MATCH.
exprlist ::= nexprlist.
exprlistnorecursive ::= nexprlistnorecursive.
nmnum ::= plus_num.
nmnum ::= nm.
nmnum ::= ON.
nmnum ::= DELETE.
nmnum ::= DEFAULT.
plus_num ::= INTEGER|FLOAT.
foreach_clause ::=.
foreach_clause ::= FOR EACH ROW.
trnm ::= nm.
tridxby ::=.
database_kw_opt ::= DATABASE.
database_kw_opt ::=.
kwcolumn_opt ::=.
kwcolumn_opt ::= COLUMNKW.
vtabarglist ::= vtabarg.
vtabarglistnorecursive ::= vtabarg.
vtabarglist ::= vtabarglistnorecursive COMMA vtabarg.
vtabarg ::= vtabarg vtabargtoken.
anylist ::= LP ANY RP.
anylist ::= ANY.
with ::=.
