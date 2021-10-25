import click 
import sys
from loguru import logger
from translate import translate
def _test(data, expect):
    assert expect.strip() == translate(data).strip()


def TestDropSubscriptionStmt():
    data = """
DropSubscriptionStmt: DROP SUBSCRIPTION name opt_drop_behavior
            {
                DropSubscriptionStmt *n = makeNode(DropSubscriptionStmt);
                n->subname = $3;
                n->missing_ok = false;
                n->behavior = $4;
                $$ = (Node *) n;
            }
            |  DROP SUBSCRIPTION IF_P EXISTS name opt_drop_behavior
            {
                DropSubscriptionStmt *n = makeNode(DropSubscriptionStmt);
                n->subname = $5;
                n->missing_ok = true;
                n->behavior = $6;
                $$ = (Node *) n;
            }
    ;
"""
    expect = """
DropSubscriptionStmt:

    DROP SUBSCRIPTION name opt_drop_behavior {
        auto tmp1 = $3;
        auto tmp2 = $4;
        res = new IR(kDropSubscriptionStmt, OP3("DROP SUBSCRIPTION", "", ""), tmp1, tmp2);
        $$ = res;
    }

    | DROP SUBSCRIPTION IF_P EXISTS name opt_drop_behavior {
        auto tmp1 = $5;
        auto tmp2 = $6;
        res = new IR(kDropSubscriptionStmt, OP3("DROP SUBSCRIPTION IF_P EXISTS", "", ""), tmp1, tmp2);
        $$ = res;
    }

;
    """
    
    _test(data, expect)


def TestStmtBlock(): 
        data = """
stmtblock:	stmtmulti
			{
				pg_yyget_extra(yyscanner)->parsetree = $1;
			}
		;    
"""
        expect = """
stmtblock:

    stmtmulti {
        auto tmp1 = $1;
        res = new IR(kstmtblock, OP3("", "", ""), tmp1);
        $$ = res;
    }

;        
"""        
        _test(data, expect)
        

def TestCreateUserStmt():
    data = """
CreateUserStmt:
			CREATE USER RoleId USER opt_with CREATE OptRoleList USER
				{
					CreateRoleStmt *n = makeNode(CreateRoleStmt);
					n->stmt_type = ROLESTMT_USER;
					n->role = $3;
					n->options = $5;
					$$ = (Node *)n;
				}
		;
    """
    expect = """
CreateUserStmt:

    CREATE USER RoleId USER opt_with CREATE OptRoleList USER {
        auto tmp1 = $3;
        auto tmp2 = $5;
        res = new IR(kUnknown, OP3("CREATE USER", "USER", "CREATE"), tmp1, tmp2);
        auto tmp3 = $7;
        res = new IR(kCreateUserStmt, OP3("", "USER", ""), res, tmp3);
        $$ = res;
    }

;
"""

    _test(data, expect)

def TestStmtMulti():
    data = """
stmtmulti:	stmtmulti ';' stmt
            {
                if ($1 != NIL)
                {
                    /* update length of previous stmt */
                    updateRawStmtEnd(llast_node(RawStmt, $1), @2);
                }
                if ($3 != NULL)
                    $$ = lappend($1, makeRawStmt($3, @2 + 1));
                else
                    $$ = $1;
            }
        | stmt
            {
                if ($1 != NULL)
                    $$ = list_make1(makeRawStmt($1, 0));
                else
                    $$ = NIL;
            }
    ;
"""
    expect = """
stmtmulti:

    stmtmulti OP_SEMI stmt {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kstmtmulti, OP3("", "';'", ""), tmp1, tmp2);
        $$ = res;
    }

    | stmt {
        auto tmp1 = $1;
        res = new IR(kstmtmulti, OP3("", "", ""), tmp1);
        $$ = res;
    }

;
"""
    _test(data, expect)

def TestOnlyKeywords():
    data = """
stmtmulti:	CREATE USER
        {
        }
;
    """
    expect = """
stmtmulti:

    CREATE USER {
        res = new IR(kstmtmulti, string("CREATE USER"));
        $$ = res;
    }

;
"""
    _test(data, expect)

def TestStmt():
    data = """
stmt:
			AlterEventTrigStmt
			| AlterCollationStmt
			| AlterDatabaseStmt
			| AlterDatabaseSetStmt
			| AlterDefaultPrivilegesStmt
			| AlterDomainStmt
			| AlterEnumStmt
			| AlterExtensionStmt
			| AlterExtensionContentsStmt
			| AlterFdwStmt
			| AlterForeignServerStmt
			| AlterFunctionStmt
			| AlterGroupStmt
			| AlterObjectDependsStmt
			| AlterObjectSchemaStmt
			| AlterOwnerStmt
			| AlterOperatorStmt
			| AlterTypeStmt
			| AlterPolicyStmt
			| AlterSeqStmt
			| AlterSystemStmt
			| AlterTableStmt
			| AlterTblSpcStmt
			| AlterCompositeTypeStmt
			| AlterPublicationStmt
			| AlterRoleSetStmt
			| AlterRoleStmt
			| AlterSubscriptionStmt
			| AlterStatsStmt
			| AlterTSConfigurationStmt
			| AlterTSDictionaryStmt
			| AlterUserMappingStmt
			| AnalyzeStmt
			| CallStmt
			| CheckPointStmt
			| ClosePortalStmt
			| ClusterStmt
			| CommentStmt
			| ConstraintsSetStmt
			| CopyStmt
			| CreateAmStmt
			| CreateAsStmt
			| CreateAssertionStmt
			| CreateCastStmt
			| CreateConversionStmt
			| CreateDomainStmt
			| CreateExtensionStmt
			| CreateFdwStmt
			| CreateForeignServerStmt
			| CreateForeignTableStmt
			| CreateFunctionStmt
			| CreateGroupStmt
			| CreateMatViewStmt
			| CreateOpClassStmt
			| CreateOpFamilyStmt
			| CreatePublicationStmt
			| AlterOpFamilyStmt
			| CreatePolicyStmt
			| CreatePLangStmt
			| CreateSchemaStmt
			| CreateSeqStmt
			| CreateStmt
			| CreateSubscriptionStmt
			| CreateStatsStmt
			| CreateTableSpaceStmt
			| CreateTransformStmt
			| CreateTrigStmt
			| CreateEventTrigStmt
			| CreateRoleStmt
			| CreateUserStmt
			| CreateUserMappingStmt
			| CreatedbStmt
			| DeallocateStmt
			| DeclareCursorStmt
			| DefineStmt
			| DeleteStmt
			| DiscardStmt
			| DoStmt
			| DropCastStmt
			| DropOpClassStmt
			| DropOpFamilyStmt
			| DropOwnedStmt
			| DropStmt
			| DropSubscriptionStmt
			| DropTableSpaceStmt
			| DropTransformStmt
			| DropRoleStmt
			| DropUserMappingStmt
			| DropdbStmt
			| ExecuteStmt
			| ExplainStmt
			| FetchStmt
			| GrantStmt
			| GrantRoleStmt
			| ImportForeignSchemaStmt
			| IndexStmt
			| InsertStmt
			| ListenStmt
			| RefreshMatViewStmt
			| LoadStmt
			| LockStmt
			| NotifyStmt
			| PrepareStmt
			| ReassignOwnedStmt
			| ReindexStmt
			| RemoveAggrStmt
			| RemoveFuncStmt
			| RemoveOperStmt
			| RenameStmt
			| RevokeStmt
			| RevokeRoleStmt
			| RuleStmt
			| SecLabelStmt
			| SelectStmt
			| TransactionStmt
			| TruncateStmt
			| UnlistenStmt
			| UpdateStmt
			| VacuumStmt
			| VariableResetStmt
			| VariableSetStmt
			| VariableShowStmt
			| ViewStmt
			| /*EMPTY*/
				{ $$ = NULL; }
		;    
"""
    expect = """
stmt:

    AlterEventTrigStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterCollationStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterDatabaseStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterDatabaseSetStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterDefaultPrivilegesStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterDomainStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterEnumStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterExtensionStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterExtensionContentsStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterFdwStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterForeignServerStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterFunctionStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterGroupStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterObjectDependsStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterObjectSchemaStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterOwnerStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterOperatorStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterTypeStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterPolicyStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterSeqStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterSystemStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterTableStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterTblSpcStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterCompositeTypeStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterPublicationStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterRoleSetStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterRoleStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterSubscriptionStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterStatsStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterTSConfigurationStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterTSDictionaryStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterUserMappingStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AnalyzeStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CallStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CheckPointStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ClosePortalStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ClusterStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CommentStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ConstraintsSetStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CopyStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateAmStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateAsStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateAssertionStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateCastStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateConversionStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateDomainStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateExtensionStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateFdwStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateForeignServerStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateForeignTableStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateFunctionStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateGroupStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateMatViewStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateOpClassStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateOpFamilyStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreatePublicationStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterOpFamilyStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreatePolicyStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreatePLangStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateSchemaStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateSeqStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateSubscriptionStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateStatsStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateTableSpaceStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateTransformStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateTrigStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateEventTrigStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateRoleStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateUserStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateUserMappingStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreatedbStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DeallocateStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DeclareCursorStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DefineStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DeleteStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DiscardStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DoStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropCastStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropOpClassStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropOpFamilyStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropOwnedStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropSubscriptionStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropTableSpaceStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropTransformStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropRoleStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropUserMappingStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropdbStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ExecuteStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ExplainStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FetchStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | GrantStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | GrantRoleStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ImportForeignSchemaStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IndexStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | InsertStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ListenStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RefreshMatViewStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LoadStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LockStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NotifyStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | PrepareStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ReassignOwnedStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ReindexStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RemoveAggrStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RemoveFuncStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RemoveOperStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RenameStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RevokeStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RevokeRoleStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RuleStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SecLabelStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SelectStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TransactionStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TruncateStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | UnlistenStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | UpdateStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | VacuumStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | VariableResetStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | VariableSetStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | VariableShowStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ViewStmt {
        auto tmp1 = $1;
        res = new IR(kstmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kstmt, string(""));
        $$ = res;
    }

;    
"""
    _test(data, expect)

def TestSingleLine():

    data = """
name:		ColId									{ $$ = $1; };
"""
    expect = """
name:

    ColId {
        auto tmp1 = $1;
        res = new IR(kname, OP3("", "", ""), tmp1);
        $$ = res;
    }

;
"""
    _test(data, expect)

def TestConstraintAttributeSpec():
    data = """
ConstraintAttributeSpec:
			/*EMPTY*/
				{ $$ = 0; }
			| ConstraintAttributeSpec ConstraintAttributeElem
				{
					/*
					 * We must complain about conflicting options.
					 * We could, but choose not to, complain about redundant
					 * options (ie, where $2's bit is already set in $1).
					 */
					int		newspec = $1 | $2;

					/* special message for this case */
					if ((newspec & (CAS_NOT_DEFERRABLE | CAS_INITIALLY_DEFERRED)) == (CAS_NOT_DEFERRABLE | CAS_INITIALLY_DEFERRED))
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("constraint declared INITIALLY DEFERRED must be DEFERRABLE"),
								 parser_errposition(@2)));
					/* generic message for other conflicts */
					if ((newspec & (CAS_NOT_DEFERRABLE | CAS_DEFERRABLE)) == (CAS_NOT_DEFERRABLE | CAS_DEFERRABLE) ||
						(newspec & (CAS_INITIALLY_IMMEDIATE | CAS_INITIALLY_DEFERRED)) == (CAS_INITIALLY_IMMEDIATE | CAS_INITIALLY_DEFERRED))
						ereport(ERROR,
								(errcode(ERRCODE_SYNTAX_ERROR),
								 errmsg("conflicting constraint properties"),
								 parser_errposition(@2)));
					$$ = newspec;
				}
		;    
"""
    expect = """
ConstraintAttributeSpec:

    /*EMPTY*/ {
        res = new IR(kConstraintAttributeSpec, string(""));
        $$ = res;
    }

    | ConstraintAttributeSpec ConstraintAttributeElem {
        auto tmp1 = $1;
        auto tmp2 = $2;
        res = new IR(kConstraintAttributeSpec, OP3("", "", ""), tmp1, tmp2);
        $$ = res;
    }

;
"""
    _test(data, expect)


@click.command()
@click.option("-p", "--print-output", is_flag=True, default=False)
def test(print_output):
    if not print_output:
        logger.remove()
        logger.add(sys.stderr, level="ERROR")
    
    try:
        TestDropSubscriptionStmt()
        TestStmtBlock()
        TestCreateUserStmt()
        TestStmtMulti()
        TestOnlyKeywords()
        TestStmt()
        TestSingleLine()
        TestConstraintAttributeSpec()
        print("All tests passed!")
    except Exception as e:
        logger.exception(e)
        


if __name__ == "__main__":
    test()
