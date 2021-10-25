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

    stmtmulti ';' stmt {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kstmtmulti, OP3("", ";", ""), tmp1, tmp2);
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

def TestEventTriggerWhenItem():
    data = """
event_trigger_when_item:
		ColId IN_P '(' event_trigger_value_list ')'
			{ $$ = makeDefElem($1, (Node *) $4, @1); }
		;    
		| ColId IN_P '(' event_trigger_value_list ')'
			{ $$ = makeDefElem($1, (Node *) $4, @1); }
		;    
"""
    expect = """
event_trigger_when_item:

    ColId IN_P '(' event_trigger_value_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kevent_trigger_when_item, OP3("", "IN_P (", ")"), tmp1, tmp2);
        $$ = res;
    }

    | ColId IN_P '(' event_trigger_value_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kevent_trigger_when_item, OP3("", "IN_P (", ")"), tmp1, tmp2);
        $$ = res;
    }

;
"""

    _test(data, expect)


def TestWhenClauseList():
    data = """
when_clause_list:
			/* There must be at least one */
			when_clause								{ $$ = list_make1($1); }
			| when_clause_list when_clause			{ $$ = lappend($1, $2); }
		;    
"""
    translate(data)
#     FIXME:

def TestOptCreatefuncOptList():
    data = """
opt_createfunc_opt_list:
			createfunc_opt_list
			| /*EMPTY*/ { $$ = NIL; }
	;    
"""
    expect = """
opt_createfunc_opt_list:

    createfunc_opt_list {
        auto tmp1 = $1;
        res = new IR(kopt_createfunc_opt_list, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kopt_createfunc_opt_list, string(""));
        $$ = res;
    }

;    
"""
    _test(data, expect)

def TestEvent():
    data = """
event:		SELECT									{ $$ = CMD_SELECT; }
			| UPDATE								{ $$ = CMD_UPDATE; }
			| DELETE_P								{ $$ = CMD_DELETE; }
			| INSERT								{ $$ = CMD_INSERT; }
		 ;
"""
    expect = """
event:

    SELECT {
        res = new IR(kevent, string("SELECT"));
        $$ = res;
    }

    | UPDATE {
        res = new IR(kevent, string("UPDATE"));
        $$ = res;
    }

    | DELETE_P {
        res = new IR(kevent, string("DELETE_P"));
        $$ = res;
    }

    | INSERT {
        res = new IR(kevent, string("INSERT"));
        $$ = res;
    }

;
"""
    _test(data, expect)

def TestFuncApplication():
    data = """

func_application:

    func_name '(' ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kfunc_application, OP3("", "( )", ""), tmp1, tmp2);
        $$ = res;
    }

    | func_name '(' func_arg_list opt_sort_clause ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "(", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kfunc_application, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

    | func_name '(' VARIADIC func_arg_expr opt_sort_clause ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("", "( VARIADIC", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kfunc_application, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

    | func_name '(' func_arg_list ',' VARIADIC func_arg_expr opt_sort_clause ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "(", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kUnknown, OP3("", "VARIADIC", ""), res, tmp3);
        auto tmp4 = $7;
        res = new IR(kfunc_application, OP3("", ")", ""), res, tmp4);
        $$ = res;
    }

    | func_name '(' ALL func_arg_list opt_sort_clause ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("", "( ALL", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kfunc_application, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

    | func_name '(' DISTINCT func_arg_list opt_sort_clause ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("", "( DISTINCT", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kfunc_application, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

    | func_name '(' '*' ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kfunc_application, OP3("", "( * )", ""), tmp1, tmp2);
        $$ = res;
    }

;
"""
    expect = """
    
"""
    translate(data)

def TestBareLabelKeyword():
    data = """
bare_label_keyword:
			  ABORT_P
			| ABSOLUTE_P
			| ACCESS
			| ACTION
			| ADD_P
			| ADMIN
			| AFTER
			| AGGREGATE
			| ALL
			| ALSO
			| ALTER
			| ALWAYS
			| ANALYSE
			| ANALYZE
			| AND
			| ANY
			| ASC
			| ASENSITIVE
			| ASSERTION
			| ASSIGNMENT
			| ASYMMETRIC
			| AT
			| ATOMIC
			| ATTACH
			| ATTRIBUTE
			| AUTHORIZATION
			| BACKWARD
			| BEFORE
			| BEGIN_P
			| BETWEEN
			| BIGINT
			| BINARY
			| BIT
			| BOOLEAN_P
			| BOTH
			| BREADTH
			| BY
			| CACHE
			| CALL
			| CALLED
			| CASCADE
			| CASCADED
			| CASE
			| CAST
			| CATALOG_P
			| CHAIN
			| CHARACTERISTICS
			| CHECK
			| CHECKPOINT
			| CLASS
			| CLOSE
			| CLUSTER
			| COALESCE
			| COLLATE
			| COLLATION
			| COLUMN
			| COLUMNS
			| COMMENT
			| COMMENTS
			| COMMIT
			| COMMITTED
			| COMPRESSION
			| CONCURRENTLY
			| CONFIGURATION
			| CONFLICT
			| CONNECTION
			| CONSTRAINT
			| CONSTRAINTS
			| CONTENT_P
			| CONTINUE_P
			| CONVERSION_P
			| COPY
			| COST
			| CROSS
			| CSV
			| CUBE
			| CURRENT_P
			| CURRENT_CATALOG
			| CURRENT_DATE
			| CURRENT_ROLE
			| CURRENT_SCHEMA
			| CURRENT_TIME
			| CURRENT_TIMESTAMP
			| CURRENT_USER
			| CURSOR
			| CYCLE
			| DATA_P
			| DATABASE
			| DEALLOCATE
			| DEC
			| DECIMAL_P
			| DECLARE
			| DEFAULT
			| DEFAULTS
			| DEFERRABLE
			| DEFERRED
			| DEFINER
			| DELETE_P
			| DELIMITER
			| DELIMITERS
			| DEPENDS
			| DEPTH
			| DESC
			| DETACH
			| DICTIONARY
			| DISABLE_P
			| DISCARD
			| DISTINCT
			| DO
			| DOCUMENT_P
			| DOMAIN_P
			| DOUBLE_P
			| DROP
			| EACH
			| ELSE
			| ENABLE_P
			| ENCODING
			| ENCRYPTED
			| END_P
			| ENUM_P
			| ESCAPE
			| EVENT
			| EXCLUDE
			| EXCLUDING
			| EXCLUSIVE
			| EXECUTE
			| EXISTS
			| EXPLAIN
			| EXPRESSION
			| EXTENSION
			| EXTERNAL
			| EXTRACT
			| FALSE_P
			| FAMILY
			| FINALIZE
			| FIRST_P
			| FLOAT_P
			| FOLLOWING
			| FORCE
			| FOREIGN
			| FORWARD
			| FREEZE
			| FULL
			| FUNCTION
			| FUNCTIONS
			| GENERATED
			| GLOBAL
			| GRANTED
			| GREATEST
			| GROUPING
			| GROUPS
			| HANDLER
			| HEADER_P
			| HOLD
			| IDENTITY_P
			| IF_P
			| ILIKE
			| IMMEDIATE
			| IMMUTABLE
			| IMPLICIT_P
			| IMPORT_P
			| IN_P
			| INCLUDE
			| INCLUDING
			| INCREMENT
			| INDEX
			| INDEXES
			| INHERIT
			| INHERITS
			| INITIALLY
			| INLINE_P
			| INNER_P
			| INOUT
			| INPUT_P
			| INSENSITIVE
			| INSERT
			| INSTEAD
			| INT_P
			| INTEGER
			| INTERVAL
			| INVOKER
			| IS
			| ISOLATION
			| JOIN
			| KEY
			| LABEL
			| LANGUAGE
			| LARGE_P
			| LAST_P
			| LATERAL_P
			| LEADING
			| LEAKPROOF
			| LEAST
			| LEFT
			| LEVEL
			| LIKE
			| LISTEN
			| LOAD
			| LOCAL
			| LOCALTIME
			| LOCALTIMESTAMP
			| LOCATION
			| LOCK_P
			| LOCKED
			| LOGGED
			| MAPPING
			| MATCH
			| MATERIALIZED
			| MAXVALUE
			| METHOD
			| MINVALUE
			| MODE
			| MOVE
			| NAME_P
			| NAMES
			| NATIONAL
			| NATURAL
			| NCHAR
			| NEW
			| NEXT
			| NFC
			| NFD
			| NFKC
			| NFKD
			| NO
			| NONE
			| NORMALIZE
			| NORMALIZED
			| NOT
			| NOTHING
			| NOTIFY
			| NOWAIT
			| NULL_P
			| NULLIF
			| NULLS_P
			| NUMERIC
			| OBJECT_P
			| OF
			| OFF
			| OIDS
			| OLD
			| ONLY
			| OPERATOR
			| OPTION
			| OPTIONS
			| OR
			| ORDINALITY
			| OTHERS
			| OUT_P
			| OUTER_P
			| OVERLAY
			| OVERRIDING
			| OWNED
			| OWNER
			| PARALLEL
			| PARSER
			| PARTIAL
			| PARTITION
			| PASSING
			| PASSWORD
			| PLACING
			| PLANS
			| POLICY
			| POSITION
			| PRECEDING
			| PREPARE
			| PREPARED
			| PRESERVE
			| PRIMARY
			| PRIOR
			| PRIVILEGES
			| PROCEDURAL
			| PROCEDURE
			| PROCEDURES
			| PROGRAM
			| PUBLICATION
			| QUOTE
			| RANGE
			| READ
			| REAL
			| REASSIGN
			| RECHECK
			| RECURSIVE
			| REF
			| REFERENCES
			| REFERENCING
			| REFRESH
			| REINDEX
			| RELATIVE_P
			| RELEASE
			| RENAME
			| REPEATABLE
			| REPLACE
			| REPLICA
			| RESET
			| RESTART
			| RESTRICT
			| RETURN
			| RETURNS
			| REVOKE
			| RIGHT
			| ROLE
			| ROLLBACK
			| ROLLUP
			| ROUTINE
			| ROUTINES
			| ROW
			| ROWS
			| RULE
			| SAVEPOINT
			| SCHEMA
			| SCHEMAS
			| SCROLL
			| SEARCH
			| SECURITY
			| SELECT
			| SEQUENCE
			| SEQUENCES
			| SERIALIZABLE
			| SERVER
			| SESSION
			| SESSION_USER
			| SET
			| SETOF
			| SETS
			| SHARE
			| SHOW
			| SIMILAR
			| SIMPLE
			| SKIP
			| SMALLINT
			| SNAPSHOT
			| SOME
			| SQL_P
			| STABLE
			| STANDALONE_P
			| START
			| STATEMENT
			| STATISTICS
			| STDIN
			| STDOUT
			| STORAGE
			| STORED
			| STRICT_P
			| STRIP_P
			| SUBSCRIPTION
			| SUBSTRING
			| SUPPORT
			| SYMMETRIC
			| SYSID
			| SYSTEM_P
			| TABLE
			| TABLES
			| TABLESAMPLE
			| TABLESPACE
			| TEMP
			| TEMPLATE
			| TEMPORARY
			| TEXT_P
			| THEN
			| TIES
			| TIME
			| TIMESTAMP
			| TRAILING
			| TRANSACTION
			| TRANSFORM
			| TREAT
			| TRIGGER
			| TRIM
			| TRUE_P
			| TRUNCATE
			| TRUSTED
			| TYPE_P
			| TYPES_P
			| UESCAPE
			| UNBOUNDED
			| UNCOMMITTED
			| UNENCRYPTED
			| UNIQUE
			| UNKNOWN
			| UNLISTEN
			| UNLOGGED
			| UNTIL
			| UPDATE
			| USER
			| USING
			| VACUUM
			| VALID
			| VALIDATE
			| VALIDATOR
			| VALUE_P
			| VALUES
			| VARCHAR
			| VARIADIC
			| VERBOSE
			| VERSION_P
			| VIEW
			| VIEWS
			| VOLATILE
			| WHEN
			| WHITESPACE_P
			| WORK
			| WRAPPER
			| WRITE
			| XML_P
			| XMLATTRIBUTES
			| XMLCONCAT
			| XMLELEMENT
			| XMLEXISTS
			| XMLFOREST
			| XMLNAMESPACES
			| XMLPARSE
			| XMLPI
			| XMLROOT
			| XMLSERIALIZE
			| XMLTABLE
			| YES_P
			| ZONE
		;

"""
    expect = """
bare_label_keyword:

    ABORT_P {
        res = new IR(kbare_label_keyword, string("ABORT_P"));
        $$ = res;
    }

    | ABSOLUTE_P {
        res = new IR(kbare_label_keyword, string("ABSOLUTE_P"));
        $$ = res;
    }

    | ACCESS {
        res = new IR(kbare_label_keyword, string("ACCESS"));
        $$ = res;
    }

    | ACTION {
        res = new IR(kbare_label_keyword, string("ACTION"));
        $$ = res;
    }

    | ADD_P {
        res = new IR(kbare_label_keyword, string("ADD_P"));
        $$ = res;
    }

    | ADMIN {
        res = new IR(kbare_label_keyword, string("ADMIN"));
        $$ = res;
    }

    | AFTER {
        res = new IR(kbare_label_keyword, string("AFTER"));
        $$ = res;
    }

    | AGGREGATE {
        res = new IR(kbare_label_keyword, string("AGGREGATE"));
        $$ = res;
    }

    | ALL {
        res = new IR(kbare_label_keyword, string("ALL"));
        $$ = res;
    }

    | ALSO {
        res = new IR(kbare_label_keyword, string("ALSO"));
        $$ = res;
    }

    | ALTER {
        res = new IR(kbare_label_keyword, string("ALTER"));
        $$ = res;
    }

    | ALWAYS {
        res = new IR(kbare_label_keyword, string("ALWAYS"));
        $$ = res;
    }

    | ANALYSE {
        res = new IR(kbare_label_keyword, string("ANALYSE"));
        $$ = res;
    }

    | ANALYZE {
        res = new IR(kbare_label_keyword, string("ANALYZE"));
        $$ = res;
    }

    | AND {
        res = new IR(kbare_label_keyword, string("AND"));
        $$ = res;
    }

    | ANY {
        res = new IR(kbare_label_keyword, string("ANY"));
        $$ = res;
    }

    | ASC {
        res = new IR(kbare_label_keyword, string("ASC"));
        $$ = res;
    }

    | ASENSITIVE {
        res = new IR(kbare_label_keyword, string("ASENSITIVE"));
        $$ = res;
    }

    | ASSERTION {
        res = new IR(kbare_label_keyword, string("ASSERTION"));
        $$ = res;
    }

    | ASSIGNMENT {
        res = new IR(kbare_label_keyword, string("ASSIGNMENT"));
        $$ = res;
    }

    | ASYMMETRIC {
        res = new IR(kbare_label_keyword, string("ASYMMETRIC"));
        $$ = res;
    }

    | AT {
        res = new IR(kbare_label_keyword, string("AT"));
        $$ = res;
    }

    | ATOMIC {
        res = new IR(kbare_label_keyword, string("ATOMIC"));
        $$ = res;
    }

    | ATTACH {
        res = new IR(kbare_label_keyword, string("ATTACH"));
        $$ = res;
    }

    | ATTRIBUTE {
        res = new IR(kbare_label_keyword, string("ATTRIBUTE"));
        $$ = res;
    }

    | AUTHORIZATION {
        res = new IR(kbare_label_keyword, string("AUTHORIZATION"));
        $$ = res;
    }

    | BACKWARD {
        res = new IR(kbare_label_keyword, string("BACKWARD"));
        $$ = res;
    }

    | BEFORE {
        res = new IR(kbare_label_keyword, string("BEFORE"));
        $$ = res;
    }

    | BEGIN_P {
        res = new IR(kbare_label_keyword, string("BEGIN_P"));
        $$ = res;
    }

    | BETWEEN {
        res = new IR(kbare_label_keyword, string("BETWEEN"));
        $$ = res;
    }

    | BIGINT {
        res = new IR(kbare_label_keyword, string("BIGINT"));
        $$ = res;
    }

    | BINARY {
        res = new IR(kbare_label_keyword, string("BINARY"));
        $$ = res;
    }

    | BIT {
        res = new IR(kbare_label_keyword, string("BIT"));
        $$ = res;
    }

    | BOOLEAN_P {
        res = new IR(kbare_label_keyword, string("BOOLEAN_P"));
        $$ = res;
    }

    | BOTH {
        res = new IR(kbare_label_keyword, string("BOTH"));
        $$ = res;
    }

    | BREADTH {
        res = new IR(kbare_label_keyword, string("BREADTH"));
        $$ = res;
    }

    | BY {
        res = new IR(kbare_label_keyword, string("BY"));
        $$ = res;
    }

    | CACHE {
        res = new IR(kbare_label_keyword, string("CACHE"));
        $$ = res;
    }

    | CALL {
        res = new IR(kbare_label_keyword, string("CALL"));
        $$ = res;
    }

    | CALLED {
        res = new IR(kbare_label_keyword, string("CALLED"));
        $$ = res;
    }

    | CASCADE {
        res = new IR(kbare_label_keyword, string("CASCADE"));
        $$ = res;
    }

    | CASCADED {
        res = new IR(kbare_label_keyword, string("CASCADED"));
        $$ = res;
    }

    | CASE {
        res = new IR(kbare_label_keyword, string("CASE"));
        $$ = res;
    }

    | CAST {
        res = new IR(kbare_label_keyword, string("CAST"));
        $$ = res;
    }

    | CATALOG_P {
        res = new IR(kbare_label_keyword, string("CATALOG_P"));
        $$ = res;
    }

    | CHAIN {
        res = new IR(kbare_label_keyword, string("CHAIN"));
        $$ = res;
    }

    | CHARACTERISTICS {
        res = new IR(kbare_label_keyword, string("CHARACTERISTICS"));
        $$ = res;
    }

    | CHECK {
        res = new IR(kbare_label_keyword, string("CHECK"));
        $$ = res;
    }

    | CHECKPOINT {
        res = new IR(kbare_label_keyword, string("CHECKPOINT"));
        $$ = res;
    }

    | CLASS {
        res = new IR(kbare_label_keyword, string("CLASS"));
        $$ = res;
    }

    | CLOSE {
        res = new IR(kbare_label_keyword, string("CLOSE"));
        $$ = res;
    }

    | CLUSTER {
        res = new IR(kbare_label_keyword, string("CLUSTER"));
        $$ = res;
    }

    | COALESCE {
        res = new IR(kbare_label_keyword, string("COALESCE"));
        $$ = res;
    }

    | COLLATE {
        res = new IR(kbare_label_keyword, string("COLLATE"));
        $$ = res;
    }

    | COLLATION {
        res = new IR(kbare_label_keyword, string("COLLATION"));
        $$ = res;
    }

    | COLUMN {
        res = new IR(kbare_label_keyword, string("COLUMN"));
        $$ = res;
    }

    | COLUMNS {
        res = new IR(kbare_label_keyword, string("COLUMNS"));
        $$ = res;
    }

    | COMMENT {
        res = new IR(kbare_label_keyword, string("COMMENT"));
        $$ = res;
    }

    | COMMENTS {
        res = new IR(kbare_label_keyword, string("COMMENTS"));
        $$ = res;
    }

    | COMMIT {
        res = new IR(kbare_label_keyword, string("COMMIT"));
        $$ = res;
    }

    | COMMITTED {
        res = new IR(kbare_label_keyword, string("COMMITTED"));
        $$ = res;
    }

    | COMPRESSION {
        res = new IR(kbare_label_keyword, string("COMPRESSION"));
        $$ = res;
    }

    | CONCURRENTLY {
        res = new IR(kbare_label_keyword, string("CONCURRENTLY"));
        $$ = res;
    }

    | CONFIGURATION {
        res = new IR(kbare_label_keyword, string("CONFIGURATION"));
        $$ = res;
    }

    | CONFLICT {
        res = new IR(kbare_label_keyword, string("CONFLICT"));
        $$ = res;
    }

    | CONNECTION {
        res = new IR(kbare_label_keyword, string("CONNECTION"));
        $$ = res;
    }

    | CONSTRAINT {
        res = new IR(kbare_label_keyword, string("CONSTRAINT"));
        $$ = res;
    }

    | CONSTRAINTS {
        res = new IR(kbare_label_keyword, string("CONSTRAINTS"));
        $$ = res;
    }

    | CONTENT_P {
        res = new IR(kbare_label_keyword, string("CONTENT_P"));
        $$ = res;
    }

    | CONTINUE_P {
        res = new IR(kbare_label_keyword, string("CONTINUE_P"));
        $$ = res;
    }

    | CONVERSION_P {
        res = new IR(kbare_label_keyword, string("CONVERSION_P"));
        $$ = res;
    }

    | COPY {
        res = new IR(kbare_label_keyword, string("COPY"));
        $$ = res;
    }

    | COST {
        res = new IR(kbare_label_keyword, string("COST"));
        $$ = res;
    }

    | CROSS {
        res = new IR(kbare_label_keyword, string("CROSS"));
        $$ = res;
    }

    | CSV {
        res = new IR(kbare_label_keyword, string("CSV"));
        $$ = res;
    }

    | CUBE {
        res = new IR(kbare_label_keyword, string("CUBE"));
        $$ = res;
    }

    | CURRENT_P {
        res = new IR(kbare_label_keyword, string("CURRENT_P"));
        $$ = res;
    }

    | CURRENT_CATALOG {
        res = new IR(kbare_label_keyword, string("CURRENT_CATALOG"));
        $$ = res;
    }

    | CURRENT_DATE {
        res = new IR(kbare_label_keyword, string("CURRENT_DATE"));
        $$ = res;
    }

    | CURRENT_ROLE {
        res = new IR(kbare_label_keyword, string("CURRENT_ROLE"));
        $$ = res;
    }

    | CURRENT_SCHEMA {
        res = new IR(kbare_label_keyword, string("CURRENT_SCHEMA"));
        $$ = res;
    }

    | CURRENT_TIME {
        res = new IR(kbare_label_keyword, string("CURRENT_TIME"));
        $$ = res;
    }

    | CURRENT_TIMESTAMP {
        res = new IR(kbare_label_keyword, string("CURRENT_TIMESTAMP"));
        $$ = res;
    }

    | CURRENT_USER {
        res = new IR(kbare_label_keyword, string("CURRENT_USER"));
        $$ = res;
    }

    | CURSOR {
        res = new IR(kbare_label_keyword, string("CURSOR"));
        $$ = res;
    }

    | CYCLE {
        res = new IR(kbare_label_keyword, string("CYCLE"));
        $$ = res;
    }

    | DATA_P {
        res = new IR(kbare_label_keyword, string("DATA_P"));
        $$ = res;
    }

    | DATABASE {
        res = new IR(kbare_label_keyword, string("DATABASE"));
        $$ = res;
    }

    | DEALLOCATE {
        res = new IR(kbare_label_keyword, string("DEALLOCATE"));
        $$ = res;
    }

    | DEC {
        res = new IR(kbare_label_keyword, string("DEC"));
        $$ = res;
    }

    | DECIMAL_P {
        res = new IR(kbare_label_keyword, string("DECIMAL_P"));
        $$ = res;
    }

    | DECLARE {
        res = new IR(kbare_label_keyword, string("DECLARE"));
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kbare_label_keyword, string("DEFAULT"));
        $$ = res;
    }

    | DEFAULTS {
        res = new IR(kbare_label_keyword, string("DEFAULTS"));
        $$ = res;
    }

    | DEFERRABLE {
        res = new IR(kbare_label_keyword, string("DEFERRABLE"));
        $$ = res;
    }

    | DEFERRED {
        res = new IR(kbare_label_keyword, string("DEFERRED"));
        $$ = res;
    }

    | DEFINER {
        res = new IR(kbare_label_keyword, string("DEFINER"));
        $$ = res;
    }

    | DELETE_P {
        res = new IR(kbare_label_keyword, string("DELETE_P"));
        $$ = res;
    }

    | DELIMITER {
        res = new IR(kbare_label_keyword, string("DELIMITER"));
        $$ = res;
    }

    | DELIMITERS {
        res = new IR(kbare_label_keyword, string("DELIMITERS"));
        $$ = res;
    }

    | DEPENDS {
        res = new IR(kbare_label_keyword, string("DEPENDS"));
        $$ = res;
    }

    | DEPTH {
        res = new IR(kbare_label_keyword, string("DEPTH"));
        $$ = res;
    }

    | DESC {
        res = new IR(kbare_label_keyword, string("DESC"));
        $$ = res;
    }

    | DETACH {
        res = new IR(kbare_label_keyword, string("DETACH"));
        $$ = res;
    }

    | DICTIONARY {
        res = new IR(kbare_label_keyword, string("DICTIONARY"));
        $$ = res;
    }

    | DISABLE_P {
        res = new IR(kbare_label_keyword, string("DISABLE_P"));
        $$ = res;
    }

    | DISCARD {
        res = new IR(kbare_label_keyword, string("DISCARD"));
        $$ = res;
    }

    | DISTINCT {
        res = new IR(kbare_label_keyword, string("DISTINCT"));
        $$ = res;
    }

    | DO {
        res = new IR(kbare_label_keyword, string("DO"));
        $$ = res;
    }

    | DOCUMENT_P {
        res = new IR(kbare_label_keyword, string("DOCUMENT_P"));
        $$ = res;
    }

    | DOMAIN_P {
        res = new IR(kbare_label_keyword, string("DOMAIN_P"));
        $$ = res;
    }

    | DOUBLE_P {
        res = new IR(kbare_label_keyword, string("DOUBLE_P"));
        $$ = res;
    }

    | DROP {
        res = new IR(kbare_label_keyword, string("DROP"));
        $$ = res;
    }

    | EACH {
        res = new IR(kbare_label_keyword, string("EACH"));
        $$ = res;
    }

    | ELSE {
        res = new IR(kbare_label_keyword, string("ELSE"));
        $$ = res;
    }

    | ENABLE_P {
        res = new IR(kbare_label_keyword, string("ENABLE_P"));
        $$ = res;
    }

    | ENCODING {
        res = new IR(kbare_label_keyword, string("ENCODING"));
        $$ = res;
    }

    | ENCRYPTED {
        res = new IR(kbare_label_keyword, string("ENCRYPTED"));
        $$ = res;
    }

    | END_P {
        res = new IR(kbare_label_keyword, string("END_P"));
        $$ = res;
    }

    | ENUM_P {
        res = new IR(kbare_label_keyword, string("ENUM_P"));
        $$ = res;
    }

    | ESCAPE {
        res = new IR(kbare_label_keyword, string("ESCAPE"));
        $$ = res;
    }

    | EVENT {
        res = new IR(kbare_label_keyword, string("EVENT"));
        $$ = res;
    }

    | EXCLUDE {
        res = new IR(kbare_label_keyword, string("EXCLUDE"));
        $$ = res;
    }

    | EXCLUDING {
        res = new IR(kbare_label_keyword, string("EXCLUDING"));
        $$ = res;
    }

    | EXCLUSIVE {
        res = new IR(kbare_label_keyword, string("EXCLUSIVE"));
        $$ = res;
    }

    | EXECUTE {
        res = new IR(kbare_label_keyword, string("EXECUTE"));
        $$ = res;
    }

    | EXISTS {
        res = new IR(kbare_label_keyword, string("EXISTS"));
        $$ = res;
    }

    | EXPLAIN {
        res = new IR(kbare_label_keyword, string("EXPLAIN"));
        $$ = res;
    }

    | EXPRESSION {
        res = new IR(kbare_label_keyword, string("EXPRESSION"));
        $$ = res;
    }

    | EXTENSION {
        res = new IR(kbare_label_keyword, string("EXTENSION"));
        $$ = res;
    }

    | EXTERNAL {
        res = new IR(kbare_label_keyword, string("EXTERNAL"));
        $$ = res;
    }

    | EXTRACT {
        res = new IR(kbare_label_keyword, string("EXTRACT"));
        $$ = res;
    }

    | FALSE_P {
        res = new IR(kbare_label_keyword, string("FALSE_P"));
        $$ = res;
    }

    | FAMILY {
        res = new IR(kbare_label_keyword, string("FAMILY"));
        $$ = res;
    }

    | FINALIZE {
        res = new IR(kbare_label_keyword, string("FINALIZE"));
        $$ = res;
    }

    | FIRST_P {
        res = new IR(kbare_label_keyword, string("FIRST_P"));
        $$ = res;
    }

    | FLOAT_P {
        res = new IR(kbare_label_keyword, string("FLOAT_P"));
        $$ = res;
    }

    | FOLLOWING {
        res = new IR(kbare_label_keyword, string("FOLLOWING"));
        $$ = res;
    }

    | FORCE {
        res = new IR(kbare_label_keyword, string("FORCE"));
        $$ = res;
    }

    | FOREIGN {
        res = new IR(kbare_label_keyword, string("FOREIGN"));
        $$ = res;
    }

    | FORWARD {
        res = new IR(kbare_label_keyword, string("FORWARD"));
        $$ = res;
    }

    | FREEZE {
        res = new IR(kbare_label_keyword, string("FREEZE"));
        $$ = res;
    }

    | FULL {
        res = new IR(kbare_label_keyword, string("FULL"));
        $$ = res;
    }

    | FUNCTION {
        res = new IR(kbare_label_keyword, string("FUNCTION"));
        $$ = res;
    }

    | FUNCTIONS {
        res = new IR(kbare_label_keyword, string("FUNCTIONS"));
        $$ = res;
    }

    | GENERATED {
        res = new IR(kbare_label_keyword, string("GENERATED"));
        $$ = res;
    }

    | GLOBAL {
        res = new IR(kbare_label_keyword, string("GLOBAL"));
        $$ = res;
    }

    | GRANTED {
        res = new IR(kbare_label_keyword, string("GRANTED"));
        $$ = res;
    }

    | GREATEST {
        res = new IR(kbare_label_keyword, string("GREATEST"));
        $$ = res;
    }

    | GROUPING {
        res = new IR(kbare_label_keyword, string("GROUPING"));
        $$ = res;
    }

    | GROUPS {
        res = new IR(kbare_label_keyword, string("GROUPS"));
        $$ = res;
    }

    | HANDLER {
        res = new IR(kbare_label_keyword, string("HANDLER"));
        $$ = res;
    }

    | HEADER_P {
        res = new IR(kbare_label_keyword, string("HEADER_P"));
        $$ = res;
    }

    | HOLD {
        res = new IR(kbare_label_keyword, string("HOLD"));
        $$ = res;
    }

    | IDENTITY_P {
        res = new IR(kbare_label_keyword, string("IDENTITY_P"));
        $$ = res;
    }

    | IF_P {
        res = new IR(kbare_label_keyword, string("IF_P"));
        $$ = res;
    }

    | ILIKE {
        res = new IR(kbare_label_keyword, string("ILIKE"));
        $$ = res;
    }

    | IMMEDIATE {
        res = new IR(kbare_label_keyword, string("IMMEDIATE"));
        $$ = res;
    }

    | IMMUTABLE {
        res = new IR(kbare_label_keyword, string("IMMUTABLE"));
        $$ = res;
    }

    | IMPLICIT_P {
        res = new IR(kbare_label_keyword, string("IMPLICIT_P"));
        $$ = res;
    }

    | IMPORT_P {
        res = new IR(kbare_label_keyword, string("IMPORT_P"));
        $$ = res;
    }

    | IN_P {
        res = new IR(kbare_label_keyword, string("IN_P"));
        $$ = res;
    }

    | INCLUDE {
        res = new IR(kbare_label_keyword, string("INCLUDE"));
        $$ = res;
    }

    | INCLUDING {
        res = new IR(kbare_label_keyword, string("INCLUDING"));
        $$ = res;
    }

    | INCREMENT {
        res = new IR(kbare_label_keyword, string("INCREMENT"));
        $$ = res;
    }

    | INDEX {
        res = new IR(kbare_label_keyword, string("INDEX"));
        $$ = res;
    }

    | INDEXES {
        res = new IR(kbare_label_keyword, string("INDEXES"));
        $$ = res;
    }

    | INHERIT {
        res = new IR(kbare_label_keyword, string("INHERIT"));
        $$ = res;
    }

    | INHERITS {
        res = new IR(kbare_label_keyword, string("INHERITS"));
        $$ = res;
    }

    | INITIALLY {
        res = new IR(kbare_label_keyword, string("INITIALLY"));
        $$ = res;
    }

    | INLINE_P {
        res = new IR(kbare_label_keyword, string("INLINE_P"));
        $$ = res;
    }

    | INNER_P {
        res = new IR(kbare_label_keyword, string("INNER_P"));
        $$ = res;
    }

    | INOUT {
        res = new IR(kbare_label_keyword, string("INOUT"));
        $$ = res;
    }

    | INPUT_P {
        res = new IR(kbare_label_keyword, string("INPUT_P"));
        $$ = res;
    }

    | INSENSITIVE {
        res = new IR(kbare_label_keyword, string("INSENSITIVE"));
        $$ = res;
    }

    | INSERT {
        res = new IR(kbare_label_keyword, string("INSERT"));
        $$ = res;
    }

    | INSTEAD {
        res = new IR(kbare_label_keyword, string("INSTEAD"));
        $$ = res;
    }

    | INT_P {
        res = new IR(kbare_label_keyword, string("INT_P"));
        $$ = res;
    }

    | INTEGER {
        res = new IR(kbare_label_keyword, string("INTEGER"));
        $$ = res;
    }

    | INTERVAL {
        res = new IR(kbare_label_keyword, string("INTERVAL"));
        $$ = res;
    }

    | INVOKER {
        res = new IR(kbare_label_keyword, string("INVOKER"));
        $$ = res;
    }

    | IS {
        res = new IR(kbare_label_keyword, string("IS"));
        $$ = res;
    }

    | ISOLATION {
        res = new IR(kbare_label_keyword, string("ISOLATION"));
        $$ = res;
    }

    | JOIN {
        res = new IR(kbare_label_keyword, string("JOIN"));
        $$ = res;
    }

    | KEY {
        res = new IR(kbare_label_keyword, string("KEY"));
        $$ = res;
    }

    | LABEL {
        res = new IR(kbare_label_keyword, string("LABEL"));
        $$ = res;
    }

    | LANGUAGE {
        res = new IR(kbare_label_keyword, string("LANGUAGE"));
        $$ = res;
    }

    | LARGE_P {
        res = new IR(kbare_label_keyword, string("LARGE_P"));
        $$ = res;
    }

    | LAST_P {
        res = new IR(kbare_label_keyword, string("LAST_P"));
        $$ = res;
    }

    | LATERAL_P {
        res = new IR(kbare_label_keyword, string("LATERAL_P"));
        $$ = res;
    }

    | LEADING {
        res = new IR(kbare_label_keyword, string("LEADING"));
        $$ = res;
    }

    | LEAKPROOF {
        res = new IR(kbare_label_keyword, string("LEAKPROOF"));
        $$ = res;
    }

    | LEAST {
        res = new IR(kbare_label_keyword, string("LEAST"));
        $$ = res;
    }

    | LEFT {
        res = new IR(kbare_label_keyword, string("LEFT"));
        $$ = res;
    }

    | LEVEL {
        res = new IR(kbare_label_keyword, string("LEVEL"));
        $$ = res;
    }

    | LIKE {
        res = new IR(kbare_label_keyword, string("LIKE"));
        $$ = res;
    }

    | LISTEN {
        res = new IR(kbare_label_keyword, string("LISTEN"));
        $$ = res;
    }

    | LOAD {
        res = new IR(kbare_label_keyword, string("LOAD"));
        $$ = res;
    }

    | LOCAL {
        res = new IR(kbare_label_keyword, string("LOCAL"));
        $$ = res;
    }

    | LOCALTIME {
        res = new IR(kbare_label_keyword, string("LOCALTIME"));
        $$ = res;
    }

    | LOCALTIMESTAMP {
        res = new IR(kbare_label_keyword, string("LOCALTIMESTAMP"));
        $$ = res;
    }

    | LOCATION {
        res = new IR(kbare_label_keyword, string("LOCATION"));
        $$ = res;
    }

    | LOCK_P {
        res = new IR(kbare_label_keyword, string("LOCK_P"));
        $$ = res;
    }

    | LOCKED {
        res = new IR(kbare_label_keyword, string("LOCKED"));
        $$ = res;
    }

    | LOGGED {
        res = new IR(kbare_label_keyword, string("LOGGED"));
        $$ = res;
    }

    | MAPPING {
        res = new IR(kbare_label_keyword, string("MAPPING"));
        $$ = res;
    }

    | MATCH {
        res = new IR(kbare_label_keyword, string("MATCH"));
        $$ = res;
    }

    | MATERIALIZED {
        res = new IR(kbare_label_keyword, string("MATERIALIZED"));
        $$ = res;
    }

    | MAXVALUE {
        res = new IR(kbare_label_keyword, string("MAXVALUE"));
        $$ = res;
    }

    | METHOD {
        res = new IR(kbare_label_keyword, string("METHOD"));
        $$ = res;
    }

    | MINVALUE {
        res = new IR(kbare_label_keyword, string("MINVALUE"));
        $$ = res;
    }

    | MODE {
        res = new IR(kbare_label_keyword, string("MODE"));
        $$ = res;
    }

    | MOVE {
        res = new IR(kbare_label_keyword, string("MOVE"));
        $$ = res;
    }

    | NAME_P {
        res = new IR(kbare_label_keyword, string("NAME_P"));
        $$ = res;
    }

    | NAMES {
        res = new IR(kbare_label_keyword, string("NAMES"));
        $$ = res;
    }

    | NATIONAL {
        res = new IR(kbare_label_keyword, string("NATIONAL"));
        $$ = res;
    }

    | NATURAL {
        res = new IR(kbare_label_keyword, string("NATURAL"));
        $$ = res;
    }

    | NCHAR {
        res = new IR(kbare_label_keyword, string("NCHAR"));
        $$ = res;
    }

    | NEW {
        res = new IR(kbare_label_keyword, string("NEW"));
        $$ = res;
    }

    | NEXT {
        res = new IR(kbare_label_keyword, string("NEXT"));
        $$ = res;
    }

    | NFC {
        res = new IR(kbare_label_keyword, string("NFC"));
        $$ = res;
    }

    | NFD {
        res = new IR(kbare_label_keyword, string("NFD"));
        $$ = res;
    }

    | NFKC {
        res = new IR(kbare_label_keyword, string("NFKC"));
        $$ = res;
    }

    | NFKD {
        res = new IR(kbare_label_keyword, string("NFKD"));
        $$ = res;
    }

    | NO {
        res = new IR(kbare_label_keyword, string("NO"));
        $$ = res;
    }

    | NONE {
        res = new IR(kbare_label_keyword, string("NONE"));
        $$ = res;
    }

    | NORMALIZE {
        res = new IR(kbare_label_keyword, string("NORMALIZE"));
        $$ = res;
    }

    | NORMALIZED {
        res = new IR(kbare_label_keyword, string("NORMALIZED"));
        $$ = res;
    }

    | NOT {
        res = new IR(kbare_label_keyword, string("NOT"));
        $$ = res;
    }

    | NOTHING {
        res = new IR(kbare_label_keyword, string("NOTHING"));
        $$ = res;
    }

    | NOTIFY {
        res = new IR(kbare_label_keyword, string("NOTIFY"));
        $$ = res;
    }

    | NOWAIT {
        res = new IR(kbare_label_keyword, string("NOWAIT"));
        $$ = res;
    }

    | NULL_P {
        res = new IR(kbare_label_keyword, string("NULL_P"));
        $$ = res;
    }

    | NULLIF {
        res = new IR(kbare_label_keyword, string("NULLIF"));
        $$ = res;
    }

    | NULLS_P {
        res = new IR(kbare_label_keyword, string("NULLS_P"));
        $$ = res;
    }

    | NUMERIC {
        res = new IR(kbare_label_keyword, string("NUMERIC"));
        $$ = res;
    }

    | OBJECT_P {
        res = new IR(kbare_label_keyword, string("OBJECT_P"));
        $$ = res;
    }

    | OF {
        res = new IR(kbare_label_keyword, string("OF"));
        $$ = res;
    }

    | OFF {
        res = new IR(kbare_label_keyword, string("OFF"));
        $$ = res;
    }

    | OIDS {
        res = new IR(kbare_label_keyword, string("OIDS"));
        $$ = res;
    }

    | OLD {
        res = new IR(kbare_label_keyword, string("OLD"));
        $$ = res;
    }

    | ONLY {
        res = new IR(kbare_label_keyword, string("ONLY"));
        $$ = res;
    }

    | OPERATOR {
        res = new IR(kbare_label_keyword, string("OPERATOR"));
        $$ = res;
    }

    | OPTION {
        res = new IR(kbare_label_keyword, string("OPTION"));
        $$ = res;
    }

    | OPTIONS {
        res = new IR(kbare_label_keyword, string("OPTIONS"));
        $$ = res;
    }

    | OR {
        res = new IR(kbare_label_keyword, string("OR"));
        $$ = res;
    }

    | ORDINALITY {
        res = new IR(kbare_label_keyword, string("ORDINALITY"));
        $$ = res;
    }

    | OTHERS {
        res = new IR(kbare_label_keyword, string("OTHERS"));
        $$ = res;
    }

    | OUT_P {
        res = new IR(kbare_label_keyword, string("OUT_P"));
        $$ = res;
    }

    | OUTER_P {
        res = new IR(kbare_label_keyword, string("OUTER_P"));
        $$ = res;
    }

    | OVERLAY {
        res = new IR(kbare_label_keyword, string("OVERLAY"));
        $$ = res;
    }

    | OVERRIDING {
        res = new IR(kbare_label_keyword, string("OVERRIDING"));
        $$ = res;
    }

    | OWNED {
        res = new IR(kbare_label_keyword, string("OWNED"));
        $$ = res;
    }

    | OWNER {
        res = new IR(kbare_label_keyword, string("OWNER"));
        $$ = res;
    }

    | PARALLEL {
        res = new IR(kbare_label_keyword, string("PARALLEL"));
        $$ = res;
    }

    | PARSER {
        res = new IR(kbare_label_keyword, string("PARSER"));
        $$ = res;
    }

    | PARTIAL {
        res = new IR(kbare_label_keyword, string("PARTIAL"));
        $$ = res;
    }

    | PARTITION {
        res = new IR(kbare_label_keyword, string("PARTITION"));
        $$ = res;
    }

    | PASSING {
        res = new IR(kbare_label_keyword, string("PASSING"));
        $$ = res;
    }

    | PASSWORD {
        res = new IR(kbare_label_keyword, string("PASSWORD"));
        $$ = res;
    }

    | PLACING {
        res = new IR(kbare_label_keyword, string("PLACING"));
        $$ = res;
    }

    | PLANS {
        res = new IR(kbare_label_keyword, string("PLANS"));
        $$ = res;
    }

    | POLICY {
        res = new IR(kbare_label_keyword, string("POLICY"));
        $$ = res;
    }

    | POSITION {
        res = new IR(kbare_label_keyword, string("POSITION"));
        $$ = res;
    }

    | PRECEDING {
        res = new IR(kbare_label_keyword, string("PRECEDING"));
        $$ = res;
    }

    | PREPARE {
        res = new IR(kbare_label_keyword, string("PREPARE"));
        $$ = res;
    }

    | PREPARED {
        res = new IR(kbare_label_keyword, string("PREPARED"));
        $$ = res;
    }

    | PRESERVE {
        res = new IR(kbare_label_keyword, string("PRESERVE"));
        $$ = res;
    }

    | PRIMARY {
        res = new IR(kbare_label_keyword, string("PRIMARY"));
        $$ = res;
    }

    | PRIOR {
        res = new IR(kbare_label_keyword, string("PRIOR"));
        $$ = res;
    }

    | PRIVILEGES {
        res = new IR(kbare_label_keyword, string("PRIVILEGES"));
        $$ = res;
    }

    | PROCEDURAL {
        res = new IR(kbare_label_keyword, string("PROCEDURAL"));
        $$ = res;
    }

    | PROCEDURE {
        res = new IR(kbare_label_keyword, string("PROCEDURE"));
        $$ = res;
    }

    | PROCEDURES {
        res = new IR(kbare_label_keyword, string("PROCEDURES"));
        $$ = res;
    }

    | PROGRAM {
        res = new IR(kbare_label_keyword, string("PROGRAM"));
        $$ = res;
    }

    | PUBLICATION {
        res = new IR(kbare_label_keyword, string("PUBLICATION"));
        $$ = res;
    }

    | QUOTE {
        res = new IR(kbare_label_keyword, string("QUOTE"));
        $$ = res;
    }

    | RANGE {
        res = new IR(kbare_label_keyword, string("RANGE"));
        $$ = res;
    }

    | READ {
        res = new IR(kbare_label_keyword, string("READ"));
        $$ = res;
    }

    | REAL {
        res = new IR(kbare_label_keyword, string("REAL"));
        $$ = res;
    }

    | REASSIGN {
        res = new IR(kbare_label_keyword, string("REASSIGN"));
        $$ = res;
    }

    | RECHECK {
        res = new IR(kbare_label_keyword, string("RECHECK"));
        $$ = res;
    }

    | RECURSIVE {
        res = new IR(kbare_label_keyword, string("RECURSIVE"));
        $$ = res;
    }

    | REF {
        res = new IR(kbare_label_keyword, string("REF"));
        $$ = res;
    }

    | REFERENCES {
        res = new IR(kbare_label_keyword, string("REFERENCES"));
        $$ = res;
    }

    | REFERENCING {
        res = new IR(kbare_label_keyword, string("REFERENCING"));
        $$ = res;
    }

    | REFRESH {
        res = new IR(kbare_label_keyword, string("REFRESH"));
        $$ = res;
    }

    | REINDEX {
        res = new IR(kbare_label_keyword, string("REINDEX"));
        $$ = res;
    }

    | RELATIVE_P {
        res = new IR(kbare_label_keyword, string("RELATIVE_P"));
        $$ = res;
    }

    | RELEASE {
        res = new IR(kbare_label_keyword, string("RELEASE"));
        $$ = res;
    }

    | RENAME {
        res = new IR(kbare_label_keyword, string("RENAME"));
        $$ = res;
    }

    | REPEATABLE {
        res = new IR(kbare_label_keyword, string("REPEATABLE"));
        $$ = res;
    }

    | REPLACE {
        res = new IR(kbare_label_keyword, string("REPLACE"));
        $$ = res;
    }

    | REPLICA {
        res = new IR(kbare_label_keyword, string("REPLICA"));
        $$ = res;
    }

    | RESET {
        res = new IR(kbare_label_keyword, string("RESET"));
        $$ = res;
    }

    | RESTART {
        res = new IR(kbare_label_keyword, string("RESTART"));
        $$ = res;
    }

    | RESTRICT {
        res = new IR(kbare_label_keyword, string("RESTRICT"));
        $$ = res;
    }

    | RETURN {
        res = new IR(kbare_label_keyword, string("RETURN"));
        $$ = res;
    }

    | RETURNS {
        res = new IR(kbare_label_keyword, string("RETURNS"));
        $$ = res;
    }

    | REVOKE {
        res = new IR(kbare_label_keyword, string("REVOKE"));
        $$ = res;
    }

    | RIGHT {
        res = new IR(kbare_label_keyword, string("RIGHT"));
        $$ = res;
    }

    | ROLE {
        res = new IR(kbare_label_keyword, string("ROLE"));
        $$ = res;
    }

    | ROLLBACK {
        res = new IR(kbare_label_keyword, string("ROLLBACK"));
        $$ = res;
    }

    | ROLLUP {
        res = new IR(kbare_label_keyword, string("ROLLUP"));
        $$ = res;
    }

    | ROUTINE {
        res = new IR(kbare_label_keyword, string("ROUTINE"));
        $$ = res;
    }

    | ROUTINES {
        res = new IR(kbare_label_keyword, string("ROUTINES"));
        $$ = res;
    }

    | ROW {
        res = new IR(kbare_label_keyword, string("ROW"));
        $$ = res;
    }

    | ROWS {
        res = new IR(kbare_label_keyword, string("ROWS"));
        $$ = res;
    }

    | RULE {
        res = new IR(kbare_label_keyword, string("RULE"));
        $$ = res;
    }

    | SAVEPOINT {
        res = new IR(kbare_label_keyword, string("SAVEPOINT"));
        $$ = res;
    }

    | SCHEMA {
        res = new IR(kbare_label_keyword, string("SCHEMA"));
        $$ = res;
    }

    | SCHEMAS {
        res = new IR(kbare_label_keyword, string("SCHEMAS"));
        $$ = res;
    }

    | SCROLL {
        res = new IR(kbare_label_keyword, string("SCROLL"));
        $$ = res;
    }

    | SEARCH {
        res = new IR(kbare_label_keyword, string("SEARCH"));
        $$ = res;
    }

    | SECURITY {
        res = new IR(kbare_label_keyword, string("SECURITY"));
        $$ = res;
    }

    | SELECT {
        res = new IR(kbare_label_keyword, string("SELECT"));
        $$ = res;
    }

    | SEQUENCE {
        res = new IR(kbare_label_keyword, string("SEQUENCE"));
        $$ = res;
    }

    | SEQUENCES {
        res = new IR(kbare_label_keyword, string("SEQUENCES"));
        $$ = res;
    }

    | SERIALIZABLE {
        res = new IR(kbare_label_keyword, string("SERIALIZABLE"));
        $$ = res;
    }

    | SERVER {
        res = new IR(kbare_label_keyword, string("SERVER"));
        $$ = res;
    }

    | SESSION {
        res = new IR(kbare_label_keyword, string("SESSION"));
        $$ = res;
    }

    | SESSION_USER {
        res = new IR(kbare_label_keyword, string("SESSION_USER"));
        $$ = res;
    }

    | SET {
        res = new IR(kbare_label_keyword, string("SET"));
        $$ = res;
    }

    | SETOF {
        res = new IR(kbare_label_keyword, string("SETOF"));
        $$ = res;
    }

    | SETS {
        res = new IR(kbare_label_keyword, string("SETS"));
        $$ = res;
    }

    | SHARE {
        res = new IR(kbare_label_keyword, string("SHARE"));
        $$ = res;
    }

    | SHOW {
        res = new IR(kbare_label_keyword, string("SHOW"));
        $$ = res;
    }

    | SIMILAR {
        res = new IR(kbare_label_keyword, string("SIMILAR"));
        $$ = res;
    }

    | SIMPLE {
        res = new IR(kbare_label_keyword, string("SIMPLE"));
        $$ = res;
    }

    | SKIP {
        res = new IR(kbare_label_keyword, string("SKIP"));
        $$ = res;
    }

    | SMALLINT {
        res = new IR(kbare_label_keyword, string("SMALLINT"));
        $$ = res;
    }

    | SNAPSHOT {
        res = new IR(kbare_label_keyword, string("SNAPSHOT"));
        $$ = res;
    }

    | SOME {
        res = new IR(kbare_label_keyword, string("SOME"));
        $$ = res;
    }

    | SQL_P {
        res = new IR(kbare_label_keyword, string("SQL_P"));
        $$ = res;
    }

    | STABLE {
        res = new IR(kbare_label_keyword, string("STABLE"));
        $$ = res;
    }

    | STANDALONE_P {
        res = new IR(kbare_label_keyword, string("STANDALONE_P"));
        $$ = res;
    }

    | START {
        res = new IR(kbare_label_keyword, string("START"));
        $$ = res;
    }

    | STATEMENT {
        res = new IR(kbare_label_keyword, string("STATEMENT"));
        $$ = res;
    }

    | STATISTICS {
        res = new IR(kbare_label_keyword, string("STATISTICS"));
        $$ = res;
    }

    | STDIN {
        res = new IR(kbare_label_keyword, string("STDIN"));
        $$ = res;
    }

    | STDOUT {
        res = new IR(kbare_label_keyword, string("STDOUT"));
        $$ = res;
    }

    | STORAGE {
        res = new IR(kbare_label_keyword, string("STORAGE"));
        $$ = res;
    }

    | STORED {
        res = new IR(kbare_label_keyword, string("STORED"));
        $$ = res;
    }

    | STRICT_P {
        res = new IR(kbare_label_keyword, string("STRICT_P"));
        $$ = res;
    }

    | STRIP_P {
        res = new IR(kbare_label_keyword, string("STRIP_P"));
        $$ = res;
    }

    | SUBSCRIPTION {
        res = new IR(kbare_label_keyword, string("SUBSCRIPTION"));
        $$ = res;
    }

    | SUBSTRING {
        res = new IR(kbare_label_keyword, string("SUBSTRING"));
        $$ = res;
    }

    | SUPPORT {
        res = new IR(kbare_label_keyword, string("SUPPORT"));
        $$ = res;
    }

    | SYMMETRIC {
        res = new IR(kbare_label_keyword, string("SYMMETRIC"));
        $$ = res;
    }

    | SYSID {
        res = new IR(kbare_label_keyword, string("SYSID"));
        $$ = res;
    }

    | SYSTEM_P {
        res = new IR(kbare_label_keyword, string("SYSTEM_P"));
        $$ = res;
    }

    | TABLE {
        res = new IR(kbare_label_keyword, string("TABLE"));
        $$ = res;
    }

    | TABLES {
        res = new IR(kbare_label_keyword, string("TABLES"));
        $$ = res;
    }

    | TABLESAMPLE {
        res = new IR(kbare_label_keyword, string("TABLESAMPLE"));
        $$ = res;
    }

    | TABLESPACE {
        res = new IR(kbare_label_keyword, string("TABLESPACE"));
        $$ = res;
    }

    | TEMP {
        res = new IR(kbare_label_keyword, string("TEMP"));
        $$ = res;
    }

    | TEMPLATE {
        res = new IR(kbare_label_keyword, string("TEMPLATE"));
        $$ = res;
    }

    | TEMPORARY {
        res = new IR(kbare_label_keyword, string("TEMPORARY"));
        $$ = res;
    }

    | TEXT_P {
        res = new IR(kbare_label_keyword, string("TEXT_P"));
        $$ = res;
    }

    | THEN {
        res = new IR(kbare_label_keyword, string("THEN"));
        $$ = res;
    }

    | TIES {
        res = new IR(kbare_label_keyword, string("TIES"));
        $$ = res;
    }

    | TIME {
        res = new IR(kbare_label_keyword, string("TIME"));
        $$ = res;
    }

    | TIMESTAMP {
        res = new IR(kbare_label_keyword, string("TIMESTAMP"));
        $$ = res;
    }

    | TRAILING {
        res = new IR(kbare_label_keyword, string("TRAILING"));
        $$ = res;
    }

    | TRANSACTION {
        res = new IR(kbare_label_keyword, string("TRANSACTION"));
        $$ = res;
    }

    | TRANSFORM {
        res = new IR(kbare_label_keyword, string("TRANSFORM"));
        $$ = res;
    }

    | TREAT {
        res = new IR(kbare_label_keyword, string("TREAT"));
        $$ = res;
    }

    | TRIGGER {
        res = new IR(kbare_label_keyword, string("TRIGGER"));
        $$ = res;
    }

    | TRIM {
        res = new IR(kbare_label_keyword, string("TRIM"));
        $$ = res;
    }

    | TRUE_P {
        res = new IR(kbare_label_keyword, string("TRUE_P"));
        $$ = res;
    }

    | TRUNCATE {
        res = new IR(kbare_label_keyword, string("TRUNCATE"));
        $$ = res;
    }

    | TRUSTED {
        res = new IR(kbare_label_keyword, string("TRUSTED"));
        $$ = res;
    }

    | TYPE_P {
        res = new IR(kbare_label_keyword, string("TYPE_P"));
        $$ = res;
    }

    | TYPES_P {
        res = new IR(kbare_label_keyword, string("TYPES_P"));
        $$ = res;
    }

    | UESCAPE {
        res = new IR(kbare_label_keyword, string("UESCAPE"));
        $$ = res;
    }

    | UNBOUNDED {
        res = new IR(kbare_label_keyword, string("UNBOUNDED"));
        $$ = res;
    }

    | UNCOMMITTED {
        res = new IR(kbare_label_keyword, string("UNCOMMITTED"));
        $$ = res;
    }

    | UNENCRYPTED {
        res = new IR(kbare_label_keyword, string("UNENCRYPTED"));
        $$ = res;
    }

    | UNIQUE {
        res = new IR(kbare_label_keyword, string("UNIQUE"));
        $$ = res;
    }

    | UNKNOWN {
        res = new IR(kbare_label_keyword, string("UNKNOWN"));
        $$ = res;
    }

    | UNLISTEN {
        res = new IR(kbare_label_keyword, string("UNLISTEN"));
        $$ = res;
    }

    | UNLOGGED {
        res = new IR(kbare_label_keyword, string("UNLOGGED"));
        $$ = res;
    }

    | UNTIL {
        res = new IR(kbare_label_keyword, string("UNTIL"));
        $$ = res;
    }

    | UPDATE {
        res = new IR(kbare_label_keyword, string("UPDATE"));
        $$ = res;
    }

    | USER {
        res = new IR(kbare_label_keyword, string("USER"));
        $$ = res;
    }

    | USING {
        res = new IR(kbare_label_keyword, string("USING"));
        $$ = res;
    }

    | VACUUM {
        res = new IR(kbare_label_keyword, string("VACUUM"));
        $$ = res;
    }

    | VALID {
        res = new IR(kbare_label_keyword, string("VALID"));
        $$ = res;
    }

    | VALIDATE {
        res = new IR(kbare_label_keyword, string("VALIDATE"));
        $$ = res;
    }

    | VALIDATOR {
        res = new IR(kbare_label_keyword, string("VALIDATOR"));
        $$ = res;
    }

    | VALUE_P {
        res = new IR(kbare_label_keyword, string("VALUE_P"));
        $$ = res;
    }

    | VALUES {
        res = new IR(kbare_label_keyword, string("VALUES"));
        $$ = res;
    }

    | VARCHAR {
        res = new IR(kbare_label_keyword, string("VARCHAR"));
        $$ = res;
    }

    | VARIADIC {
        res = new IR(kbare_label_keyword, string("VARIADIC"));
        $$ = res;
    }

    | VERBOSE {
        res = new IR(kbare_label_keyword, string("VERBOSE"));
        $$ = res;
    }

    | VERSION_P {
        res = new IR(kbare_label_keyword, string("VERSION_P"));
        $$ = res;
    }

    | VIEW {
        res = new IR(kbare_label_keyword, string("VIEW"));
        $$ = res;
    }

    | VIEWS {
        res = new IR(kbare_label_keyword, string("VIEWS"));
        $$ = res;
    }

    | VOLATILE {
        res = new IR(kbare_label_keyword, string("VOLATILE"));
        $$ = res;
    }

    | WHEN {
        res = new IR(kbare_label_keyword, string("WHEN"));
        $$ = res;
    }

    | WHITESPACE_P {
        res = new IR(kbare_label_keyword, string("WHITESPACE_P"));
        $$ = res;
    }

    | WORK {
        res = new IR(kbare_label_keyword, string("WORK"));
        $$ = res;
    }

    | WRAPPER {
        res = new IR(kbare_label_keyword, string("WRAPPER"));
        $$ = res;
    }

    | WRITE {
        res = new IR(kbare_label_keyword, string("WRITE"));
        $$ = res;
    }

    | XML_P {
        res = new IR(kbare_label_keyword, string("XML_P"));
        $$ = res;
    }

    | XMLATTRIBUTES {
        res = new IR(kbare_label_keyword, string("XMLATTRIBUTES"));
        $$ = res;
    }

    | XMLCONCAT {
        res = new IR(kbare_label_keyword, string("XMLCONCAT"));
        $$ = res;
    }

    | XMLELEMENT {
        res = new IR(kbare_label_keyword, string("XMLELEMENT"));
        $$ = res;
    }

    | XMLEXISTS {
        res = new IR(kbare_label_keyword, string("XMLEXISTS"));
        $$ = res;
    }

    | XMLFOREST {
        res = new IR(kbare_label_keyword, string("XMLFOREST"));
        $$ = res;
    }

    | XMLNAMESPACES {
        res = new IR(kbare_label_keyword, string("XMLNAMESPACES"));
        $$ = res;
    }

    | XMLPARSE {
        res = new IR(kbare_label_keyword, string("XMLPARSE"));
        $$ = res;
    }

    | XMLPI {
        res = new IR(kbare_label_keyword, string("XMLPI"));
        $$ = res;
    }

    | XMLROOT {
        res = new IR(kbare_label_keyword, string("XMLROOT"));
        $$ = res;
    }

    | XMLSERIALIZE {
        res = new IR(kbare_label_keyword, string("XMLSERIALIZE"));
        $$ = res;
    }

    | XMLTABLE {
        res = new IR(kbare_label_keyword, string("XMLTABLE"));
        $$ = res;
    }

    | YES_P {
        res = new IR(kbare_label_keyword, string("YES_P"));
        $$ = res;
    }

    | ZONE {
        res = new IR(kbare_label_keyword, string("ZONE"));
        $$ = res;
    }

;
"""
    _test(data, expect)

def TestOnlyMultipleKeywords():
    data = """
document_or_content: DOCUMENT_P						{ $$ = XMLOPTION_DOCUMENT; }
			| CONTENT_P	DOCUMENT_P					{ $$ = XMLOPTION_CONTENT; }
			| CONTENT_P	DOCUMENT_P	CONTENT_P		{ $$ = XMLOPTION_CONTENT; }
		; 
"""
    expect = """
document_or_content:

    DOCUMENT_P {
        res = new IR(kdocument_or_content, string("DOCUMENT_P"));
        $$ = res;
    }

    | CONTENT_P DOCUMENT_P {
        res = new IR(kdocument_or_content, string("CONTENT_P DOCUMENT_P"));
        $$ = res;
    }

    | CONTENT_P DOCUMENT_P CONTENT_P {
        res = new IR(kdocument_or_content, string("CONTENT_P DOCUMENT_P CONTENT_P"));
        $$ = res;
    }

;
"""
    _test(data, expect)

def TestQualifiedNameList():
    data ="""
qualified_name_list:
			qualified_name							{ $$ = list_make1($1); }
			| qualified_name_list ',' qualified_name { $$ = lappend($1, $3); }
		;    
"""
    expect = """
qualified_name_list:

    qualified_name {
        auto tmp1 = $1;
        res = new IR(kqualified_name_list, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | qualified_name_list ',' qualified_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kqualified_name_list, OP3("", ",", ""), tmp1, tmp2);
        $$ = res;
    }

;
"""
    _test(data, expect)

def TestMappingKeywords():
    data = """
Numeric:	INT_P
				{
					$$ = SystemTypeName("int4");
					$$->location = @1;
				}
			| INTEGER
				{
					$$ = SystemTypeName("int4");
					$$->location = @1;
				}
			| SMALLINT
				{
					$$ = SystemTypeName("int2");
					$$->location = @1;
				}
			| BIGINT
				{
					$$ = SystemTypeName("int8");
					$$->location = @1;
				}
			| REAL
				{
					$$ = SystemTypeName("float4");
					$$->location = @1;
				}
			| FLOAT_P opt_float
				{
					$$ = $2;
					$$->location = @1;
				}
			| DOUBLE_P PRECISION
				{
					$$ = SystemTypeName("float8");
					$$->location = @1;
				}
			| DECIMAL_P opt_type_modifiers
				{
					$$ = SystemTypeName("numeric");
					$$->typmods = $2;
					$$->location = @1;
				}
			| DEC opt_type_modifiers
				{
					$$ = SystemTypeName("numeric");
					$$->typmods = $2;
					$$->location = @1;
				}
			| NUMERIC opt_type_modifiers
				{
					$$ = SystemTypeName("numeric");
					$$->typmods = $2;
					$$->location = @1;
				}
			| BOOLEAN_P
				{
					$$ = SystemTypeName("bool");
					$$->location = @1;
				}
		;
"""
    expect = """
Numeric:

    INT_P {
        res = new IR(kNumeric, string("int"));
        $$ = res;
    }

    | INTEGER {
        res = new IR(kNumeric, string("integer"));
        $$ = res;
    }

    | SMALLINT {
        res = new IR(kNumeric, string("smallint"));
        $$ = res;
    }

    | BIGINT {
        res = new IR(kNumeric, string("bigint"));
        $$ = res;
    }

    | REAL {
        res = new IR(kNumeric, string("real"));
        $$ = res;
    }

    | FLOAT_P opt_float {
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("float", "", ""), tmp1);
        $$ = res;
    }

    | DOUBLE_P PRECISION {
        res = new IR(kNumeric, string("double precision"));
        $$ = res;
    }

    | DECIMAL_P opt_type_modifiers {
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("decimal", "", ""), tmp1);
        $$ = res;
    }

    | DEC opt_type_modifiers {
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("dec", "", ""), tmp1);
        $$ = res;
    }

    | NUMERIC opt_type_modifiers {
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("numeric", "", ""), tmp1);
        $$ = res;
    }

    | BOOLEAN_P {
        res = new IR(kNumeric, string("boolean"));
        $$ = res;
    }

;
"""
    _test(data, expect)

def TestCExpr():
    data = """
c_expr:		columnref								{ $$ = $1; }
			| AexprConst							{ $$ = $1; }
			| PARAM opt_indirection
				{
					ParamRef *p = makeNode(ParamRef);
					p->number = $1;
					p->location = @1;
					if ($2)
					{
						A_Indirection *n = makeNode(A_Indirection);
						n->arg = (Node *) p;
						n->indirection = check_indirection($2, yyscanner);
						$$ = (Node *) n;
					}
					else
						$$ = (Node *) p;
				}
			| '(' a_expr ')' opt_indirection
				{
					if ($4)
					{
						A_Indirection *n = makeNode(A_Indirection);
						n->arg = $2;
						n->indirection = check_indirection($4, yyscanner);
						$$ = (Node *)n;
					}
					else
						$$ = $2;
				}
			| case_expr
				{ $$ = $1; }
			| func_expr
				{ $$ = $1; }
			| select_with_parens			%prec UMINUS
				{
					SubLink *n = makeNode(SubLink);
					n->subLinkType = EXPR_SUBLINK;
					n->subLinkId = 0;
					n->testexpr = NULL;
					n->operName = NIL;
					n->subselect = $1;
					n->location = @1;
					$$ = (Node *)n;
				}
			| select_with_parens indirection
				{
					/*
					 * Because the select_with_parens nonterminal is designed
					 * to "eat" as many levels of parens as possible, the
					 * '(' a_expr ')' opt_indirection production above will
					 * fail to match a sub-SELECT with indirection decoration;
					 * the sub-SELECT won't be regarded as an a_expr as long
					 * as there are parens around it.  To support applying
					 * subscripting or field selection to a sub-SELECT result,
					 * we need this redundant-looking production.
					 */
					SubLink *n = makeNode(SubLink);
					A_Indirection *a = makeNode(A_Indirection);
					n->subLinkType = EXPR_SUBLINK;
					n->subLinkId = 0;
					n->testexpr = NULL;
					n->operName = NIL;
					n->subselect = $1;
					n->location = @1;
					a->arg = (Node *)n;
					a->indirection = check_indirection($2, yyscanner);
					$$ = (Node *)a;
				}
			| EXISTS select_with_parens
				{
					SubLink *n = makeNode(SubLink);
					n->subLinkType = EXISTS_SUBLINK;
					n->subLinkId = 0;
					n->testexpr = NULL;
					n->operName = NIL;
					n->subselect = $2;
					n->location = @1;
					$$ = (Node *)n;
				}
			| ARRAY select_with_parens
				{
					SubLink *n = makeNode(SubLink);
					n->subLinkType = ARRAY_SUBLINK;
					n->subLinkId = 0;
					n->testexpr = NULL;
					n->operName = NIL;
					n->subselect = $2;
					n->location = @1;
					$$ = (Node *)n;
				}
			| ARRAY array_expr
				{
					A_ArrayExpr *n = castNode(A_ArrayExpr, $2);
					/* point outermost A_ArrayExpr to the ARRAY keyword */
					n->location = @1;
					$$ = (Node *)n;
				}
			| explicit_row
				{
					RowExpr *r = makeNode(RowExpr);
					r->args = $1;
					r->row_typeid = InvalidOid;	/* not analyzed yet */
					r->colnames = NIL;	/* to be filled in during analysis */
					r->row_format = COERCE_EXPLICIT_CALL; /* abuse */
					r->location = @1;
					$$ = (Node *)r;
				}
			| implicit_row
				{
					RowExpr *r = makeNode(RowExpr);
					r->args = $1;
					r->row_typeid = InvalidOid;	/* not analyzed yet */
					r->colnames = NIL;	/* to be filled in during analysis */
					r->row_format = COERCE_IMPLICIT_CAST; /* abuse */
					r->location = @1;
					$$ = (Node *)r;
				}
			| GROUPING '(' expr_list ')'
			  {
				  GroupingFunc *g = makeNode(GroupingFunc);
				  g->args = $3;
				  g->location = @1;
				  $$ = (Node *)g;
			  }
		;
"""
    expect = """
"""
    translate(data)
#     TODO


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
        TestEventTriggerWhenItem()
        TestWhenClauseList()
        TestOptCreatefuncOptList()
        TestEvent()
        TestFuncApplication()
        TestBareLabelKeyword()
        TestOnlyMultipleKeywords()
        TestQualifiedNameList()
        TestMappingKeywords()
        TestCExpr()
        print("All tests passed!")
    except Exception as e:
        logger.exception(e)
        


if __name__ == "__main__":
    test()
