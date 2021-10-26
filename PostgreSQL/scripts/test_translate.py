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
        res = new IR(kDropSubscriptionStmt, OP3("DROP SUBSCRIPTION IF EXISTS", "", ""), tmp1, tmp2);
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
        res = new IR(kStmtblock, OP3("", "", ""), tmp1);
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
        res = new IR(kCreateUserStmt_1, OP3("CREATE USER", "USER", "CREATE"), tmp1, tmp2);
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
        res = new IR(kStmtmulti, OP3("", ";", ""), tmp1, tmp2);
        $$ = res;
    }

    | stmt {
        auto tmp1 = $1;
        res = new IR(kStmtmulti, OP3("", "", ""), tmp1);
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
        res = new IR(kStmtmulti, OP3("CREATE USER", "", ""));
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
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterCollationStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterDatabaseStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterDatabaseSetStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterDefaultPrivilegesStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterDomainStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterEnumStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterExtensionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterExtensionContentsStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterFdwStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterForeignServerStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterFunctionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterGroupStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterObjectDependsStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterObjectSchemaStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterOwnerStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterOperatorStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterTypeStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterPolicyStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterSeqStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterSystemStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterTableStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterTblSpcStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterCompositeTypeStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterPublicationStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterRoleSetStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterRoleStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterSubscriptionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterStatsStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterTSConfigurationStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterTSDictionaryStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterUserMappingStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AnalyzeStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CallStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CheckPointStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ClosePortalStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ClusterStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CommentStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ConstraintsSetStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CopyStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateAmStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateAsStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateAssertionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateCastStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateConversionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateDomainStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateExtensionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateFdwStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateForeignServerStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateForeignTableStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateFunctionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateGroupStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateMatViewStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateOpClassStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateOpFamilyStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreatePublicationStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | AlterOpFamilyStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreatePolicyStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreatePLangStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateSchemaStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateSeqStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateSubscriptionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateStatsStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateTableSpaceStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateTransformStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateTrigStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateEventTrigStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateRoleStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateUserStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreateUserMappingStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | CreatedbStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DeallocateStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DeclareCursorStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DefineStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DeleteStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DiscardStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DoStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropCastStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropOpClassStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropOpFamilyStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropOwnedStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropSubscriptionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropTableSpaceStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropTransformStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropRoleStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropUserMappingStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | DropdbStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ExecuteStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ExplainStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | FetchStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | GrantStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | GrantRoleStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ImportForeignSchemaStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | IndexStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | InsertStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ListenStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RefreshMatViewStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LoadStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | LockStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | NotifyStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | PrepareStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ReassignOwnedStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ReindexStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RemoveAggrStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RemoveFuncStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RemoveOperStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RenameStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RevokeStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RevokeRoleStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | RuleStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SecLabelStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | SelectStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TransactionStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | TruncateStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | UnlistenStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | UpdateStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | VacuumStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | VariableResetStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | VariableSetStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | VariableShowStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | ViewStmt {
        auto tmp1 = $1;
        res = new IR(kStmt, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kStmt, OP3("", "", ""));
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
        res = new IR(kName, OP3("", "", ""), tmp1);
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
        res = new IR(kConstraintAttributeSpec, OP3("", "", ""));
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

    ColId IN_P '(' event_trigger_value_list ')' ; {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kEventTriggerWhenItem_1, OP3("", "IN (", ")"), tmp1, tmp2);
        auto tmp3 = $6;
        res = new IR(kEventTriggerWhenItem, OP3("", "", ""), res, tmp3);
        $$ = res;
    }

    | ColId IN_P '(' event_trigger_value_list ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kEventTriggerWhenItem, OP3("", "IN (", ")"), tmp1, tmp2);
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
        res = new IR(kOptCreatefuncOptList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | /*EMPTY*/ {
        res = new IR(kOptCreatefuncOptList, OP3("", "", ""));
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
        res = new IR(kEvent, OP3("SELECT", "", ""));
        $$ = res;
    }

    | UPDATE {
        res = new IR(kEvent, OP3("UPDATE", "", ""));
        $$ = res;
    }

    | DELETE_P {
        res = new IR(kEvent, OP3("DELETE", "", ""));
        $$ = res;
    }

    | INSERT {
        res = new IR(kEvent, OP3("INSERT", "", ""));
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
        res = new IR(kFuncApplication, OP3("", "( )", ""), tmp1, tmp2);
        $$ = res;
    }

    | func_name '(' func_arg_list opt_sort_clause ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "(", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kFuncApplication, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

    | func_name '(' VARIADIC func_arg_expr opt_sort_clause ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("", "( VARIADIC", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kFuncApplication, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

    | func_name '(' func_arg_list ',' VARIADIC func_arg_expr opt_sort_clause ')' {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kUnknown, OP3("", "(", ""), tmp1, tmp2);
        auto tmp3 = $4;
        res = new IR(kUnknown, OP3("", "VARIADIC", ""), res, tmp3);
        auto tmp4 = $7;
        res = new IR(kFuncApplication, OP3("", ")", ""), res, tmp4);
        $$ = res;
    }

    | func_name '(' ALL func_arg_list opt_sort_clause ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("", "( ALL", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kFuncApplication, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

    | func_name '(' DISTINCT func_arg_list opt_sort_clause ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kUnknown, OP3("", "( DISTINCT", ""), tmp1, tmp2);
        auto tmp3 = $5;
        res = new IR(kFuncApplication, OP3("", ")", ""), res, tmp3);
        $$ = res;
    }

    | func_name '(' '*' ')' {
        auto tmp1 = $1;
        auto tmp2 = $4;
        res = new IR(kFuncApplication, OP3("", "( * )", ""), tmp1, tmp2);
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
    print(translate(data))
    expect = """
bare_label_keyword:

    ABORT_P {
        res = new IR(kBareLabelKeyword, string("ABORT"));
        $$ = res;
    }

    | ABSOLUTE_P {
        res = new IR(kBareLabelKeyword, string("ABSOLUTE"));
        $$ = res;
    }

    | ACCESS {
        res = new IR(kBareLabelKeyword, string("ACCESS"));
        $$ = res;
    }

    | ACTION {
        res = new IR(kBareLabelKeyword, string("ACTION"));
        $$ = res;
    }

    | ADD_P {
        res = new IR(kBareLabelKeyword, string("ADD"));
        $$ = res;
    }

    | ADMIN {
        res = new IR(kBareLabelKeyword, string("ADMIN"));
        $$ = res;
    }

    | AFTER {
        res = new IR(kBareLabelKeyword, string("AFTER"));
        $$ = res;
    }

    | AGGREGATE {
        res = new IR(kBareLabelKeyword, string("AGGREGATE"));
        $$ = res;
    }

    | ALL {
        res = new IR(kBareLabelKeyword, string("ALL"));
        $$ = res;
    }

    | ALSO {
        res = new IR(kBareLabelKeyword, string("ALSO"));
        $$ = res;
    }

    | ALTER {
        res = new IR(kBareLabelKeyword, string("ALTER"));
        $$ = res;
    }

    | ALWAYS {
        res = new IR(kBareLabelKeyword, string("ALWAYS"));
        $$ = res;
    }

    | ANALYSE {
        res = new IR(kBareLabelKeyword, string("ANALYSE"));
        $$ = res;
    }

    | ANALYZE {
        res = new IR(kBareLabelKeyword, string("ANALYZE"));
        $$ = res;
    }

    | AND {
        res = new IR(kBareLabelKeyword, string("AND"));
        $$ = res;
    }

    | ANY {
        res = new IR(kBareLabelKeyword, string("ANY"));
        $$ = res;
    }

    | ASC {
        res = new IR(kBareLabelKeyword, string("ASC"));
        $$ = res;
    }

    | ASENSITIVE {
        res = new IR(kBareLabelKeyword, string("ASENSITIVE"));
        $$ = res;
    }

    | ASSERTION {
        res = new IR(kBareLabelKeyword, string("ASSERTION"));
        $$ = res;
    }

    | ASSIGNMENT {
        res = new IR(kBareLabelKeyword, string("ASSIGNMENT"));
        $$ = res;
    }

    | ASYMMETRIC {
        res = new IR(kBareLabelKeyword, string("ASYMMETRIC"));
        $$ = res;
    }

    | AT {
        res = new IR(kBareLabelKeyword, string("AT"));
        $$ = res;
    }

    | ATOMIC {
        res = new IR(kBareLabelKeyword, string("ATOMIC"));
        $$ = res;
    }

    | ATTACH {
        res = new IR(kBareLabelKeyword, string("ATTACH"));
        $$ = res;
    }

    | ATTRIBUTE {
        res = new IR(kBareLabelKeyword, string("ATTRIBUTE"));
        $$ = res;
    }

    | AUTHORIZATION {
        res = new IR(kBareLabelKeyword, string("AUTHORIZATION"));
        $$ = res;
    }

    | BACKWARD {
        res = new IR(kBareLabelKeyword, string("BACKWARD"));
        $$ = res;
    }

    | BEFORE {
        res = new IR(kBareLabelKeyword, string("BEFORE"));
        $$ = res;
    }

    | BEGIN_P {
        res = new IR(kBareLabelKeyword, string("BEGIN"));
        $$ = res;
    }

    | BETWEEN {
        res = new IR(kBareLabelKeyword, string("BETWEEN"));
        $$ = res;
    }

    | BIGINT {
        res = new IR(kBareLabelKeyword, string("BIGINT"));
        $$ = res;
    }

    | BINARY {
        res = new IR(kBareLabelKeyword, string("BINARY"));
        $$ = res;
    }

    | BIT {
        res = new IR(kBareLabelKeyword, string("BIT"));
        $$ = res;
    }

    | BOOLEAN_P {
        res = new IR(kBareLabelKeyword, string("BOOLEAN"));
        $$ = res;
    }

    | BOTH {
        res = new IR(kBareLabelKeyword, string("BOTH"));
        $$ = res;
    }

    | BREADTH {
        res = new IR(kBareLabelKeyword, string("BREADTH"));
        $$ = res;
    }

    | BY {
        res = new IR(kBareLabelKeyword, string("BY"));
        $$ = res;
    }

    | CACHE {
        res = new IR(kBareLabelKeyword, string("CACHE"));
        $$ = res;
    }

    | CALL {
        res = new IR(kBareLabelKeyword, string("CALL"));
        $$ = res;
    }

    | CALLED {
        res = new IR(kBareLabelKeyword, string("CALLED"));
        $$ = res;
    }

    | CASCADE {
        res = new IR(kBareLabelKeyword, string("CASCADE"));
        $$ = res;
    }

    | CASCADED {
        res = new IR(kBareLabelKeyword, string("CASCADED"));
        $$ = res;
    }

    | CASE {
        res = new IR(kBareLabelKeyword, string("CASE"));
        $$ = res;
    }

    | CAST {
        res = new IR(kBareLabelKeyword, string("CAST"));
        $$ = res;
    }

    | CATALOG_P {
        res = new IR(kBareLabelKeyword, string("CATALOG"));
        $$ = res;
    }

    | CHAIN {
        res = new IR(kBareLabelKeyword, string("CHAIN"));
        $$ = res;
    }

    | CHARACTERISTICS {
        res = new IR(kBareLabelKeyword, string("CHARACTERISTICS"));
        $$ = res;
    }

    | CHECK {
        res = new IR(kBareLabelKeyword, string("CHECK"));
        $$ = res;
    }

    | CHECKPOINT {
        res = new IR(kBareLabelKeyword, string("CHECKPOINT"));
        $$ = res;
    }

    | CLASS {
        res = new IR(kBareLabelKeyword, string("CLASS"));
        $$ = res;
    }

    | CLOSE {
        res = new IR(kBareLabelKeyword, string("CLOSE"));
        $$ = res;
    }

    | CLUSTER {
        res = new IR(kBareLabelKeyword, string("CLUSTER"));
        $$ = res;
    }

    | COALESCE {
        res = new IR(kBareLabelKeyword, string("COALESCE"));
        $$ = res;
    }

    | COLLATE {
        res = new IR(kBareLabelKeyword, string("COLLATE"));
        $$ = res;
    }

    | COLLATION {
        res = new IR(kBareLabelKeyword, string("COLLATION"));
        $$ = res;
    }

    | COLUMN {
        res = new IR(kBareLabelKeyword, string("COLUMN"));
        $$ = res;
    }

    | COLUMNS {
        res = new IR(kBareLabelKeyword, string("COLUMNS"));
        $$ = res;
    }

    | COMMENT {
        res = new IR(kBareLabelKeyword, string("COMMENT"));
        $$ = res;
    }

    | COMMENTS {
        res = new IR(kBareLabelKeyword, string("COMMENTS"));
        $$ = res;
    }

    | COMMIT {
        res = new IR(kBareLabelKeyword, string("COMMIT"));
        $$ = res;
    }

    | COMMITTED {
        res = new IR(kBareLabelKeyword, string("COMMITTED"));
        $$ = res;
    }

    | COMPRESSION {
        res = new IR(kBareLabelKeyword, string("COMPRESSION"));
        $$ = res;
    }

    | CONCURRENTLY {
        res = new IR(kBareLabelKeyword, string("CONCURRENTLY"));
        $$ = res;
    }

    | CONFIGURATION {
        res = new IR(kBareLabelKeyword, string("CONFIGURATION"));
        $$ = res;
    }

    | CONFLICT {
        res = new IR(kBareLabelKeyword, string("CONFLICT"));
        $$ = res;
    }

    | CONNECTION {
        res = new IR(kBareLabelKeyword, string("CONNECTION"));
        $$ = res;
    }

    | CONSTRAINT {
        res = new IR(kBareLabelKeyword, string("CONSTRAINT"));
        $$ = res;
    }

    | CONSTRAINTS {
        res = new IR(kBareLabelKeyword, string("CONSTRAINTS"));
        $$ = res;
    }

    | CONTENT_P {
        res = new IR(kBareLabelKeyword, string("CONTENT"));
        $$ = res;
    }

    | CONTINUE_P {
        res = new IR(kBareLabelKeyword, string("CONTINUE"));
        $$ = res;
    }

    | CONVERSION_P {
        res = new IR(kBareLabelKeyword, string("CONVERSION"));
        $$ = res;
    }

    | COPY {
        res = new IR(kBareLabelKeyword, string("COPY"));
        $$ = res;
    }

    | COST {
        res = new IR(kBareLabelKeyword, string("COST"));
        $$ = res;
    }

    | CROSS {
        res = new IR(kBareLabelKeyword, string("CROSS"));
        $$ = res;
    }

    | CSV {
        res = new IR(kBareLabelKeyword, string("CSV"));
        $$ = res;
    }

    | CUBE {
        res = new IR(kBareLabelKeyword, string("CUBE"));
        $$ = res;
    }

    | CURRENT_P {
        res = new IR(kBareLabelKeyword, string("CURRENT"));
        $$ = res;
    }

    | CURRENT_CATALOG {
        res = new IR(kBareLabelKeyword, string("CURRENT_CATALOG"));
        $$ = res;
    }

    | CURRENT_DATE {
        res = new IR(kBareLabelKeyword, string("CURRENT_DATE"));
        $$ = res;
    }

    | CURRENT_ROLE {
        res = new IR(kBareLabelKeyword, string("CURRENT_ROLE"));
        $$ = res;
    }

    | CURRENT_SCHEMA {
        res = new IR(kBareLabelKeyword, string("CURRENT_SCHEMA"));
        $$ = res;
    }

    | CURRENT_TIME {
        res = new IR(kBareLabelKeyword, string("CURRENT_TIME"));
        $$ = res;
    }

    | CURRENT_TIMESTAMP {
        res = new IR(kBareLabelKeyword, string("CURRENT_TIMESTAMP"));
        $$ = res;
    }

    | CURRENT_USER {
        res = new IR(kBareLabelKeyword, string("CURRENT_USER"));
        $$ = res;
    }

    | CURSOR {
        res = new IR(kBareLabelKeyword, string("CURSOR"));
        $$ = res;
    }

    | CYCLE {
        res = new IR(kBareLabelKeyword, string("CYCLE"));
        $$ = res;
    }

    | DATA_P {
        res = new IR(kBareLabelKeyword, string("DATA"));
        $$ = res;
    }

    | DATABASE {
        res = new IR(kBareLabelKeyword, string("DATABASE"));
        $$ = res;
    }

    | DEALLOCATE {
        res = new IR(kBareLabelKeyword, string("DEALLOCATE"));
        $$ = res;
    }

    | DEC {
        res = new IR(kBareLabelKeyword, string("DEC"));
        $$ = res;
    }

    | DECIMAL_P {
        res = new IR(kBareLabelKeyword, string("DECIMAL"));
        $$ = res;
    }

    | DECLARE {
        res = new IR(kBareLabelKeyword, string("DECLARE"));
        $$ = res;
    }

    | DEFAULT {
        res = new IR(kBareLabelKeyword, string("DEFAULT"));
        $$ = res;
    }

    | DEFAULTS {
        res = new IR(kBareLabelKeyword, string("DEFAULTS"));
        $$ = res;
    }

    | DEFERRABLE {
        res = new IR(kBareLabelKeyword, string("DEFERRABLE"));
        $$ = res;
    }

    | DEFERRED {
        res = new IR(kBareLabelKeyword, string("DEFERRED"));
        $$ = res;
    }

    | DEFINER {
        res = new IR(kBareLabelKeyword, string("DEFINER"));
        $$ = res;
    }

    | DELETE_P {
        res = new IR(kBareLabelKeyword, string("DELETE"));
        $$ = res;
    }

    | DELIMITER {
        res = new IR(kBareLabelKeyword, string("DELIMITER"));
        $$ = res;
    }

    | DELIMITERS {
        res = new IR(kBareLabelKeyword, string("DELIMITERS"));
        $$ = res;
    }

    | DEPENDS {
        res = new IR(kBareLabelKeyword, string("DEPENDS"));
        $$ = res;
    }

    | DEPTH {
        res = new IR(kBareLabelKeyword, string("DEPTH"));
        $$ = res;
    }

    | DESC {
        res = new IR(kBareLabelKeyword, string("DESC"));
        $$ = res;
    }

    | DETACH {
        res = new IR(kBareLabelKeyword, string("DETACH"));
        $$ = res;
    }

    | DICTIONARY {
        res = new IR(kBareLabelKeyword, string("DICTIONARY"));
        $$ = res;
    }

    | DISABLE_P {
        res = new IR(kBareLabelKeyword, string("DISABLE"));
        $$ = res;
    }

    | DISCARD {
        res = new IR(kBareLabelKeyword, string("DISCARD"));
        $$ = res;
    }

    | DISTINCT {
        res = new IR(kBareLabelKeyword, string("DISTINCT"));
        $$ = res;
    }

    | DO {
        res = new IR(kBareLabelKeyword, string("DO"));
        $$ = res;
    }

    | DOCUMENT_P {
        res = new IR(kBareLabelKeyword, string("DOCUMENT"));
        $$ = res;
    }

    | DOMAIN_P {
        res = new IR(kBareLabelKeyword, string("DOMAIN"));
        $$ = res;
    }

    | DOUBLE_P {
        res = new IR(kBareLabelKeyword, string("DOUBLE"));
        $$ = res;
    }

    | DROP {
        res = new IR(kBareLabelKeyword, string("DROP"));
        $$ = res;
    }

    | EACH {
        res = new IR(kBareLabelKeyword, string("EACH"));
        $$ = res;
    }

    | ELSE {
        res = new IR(kBareLabelKeyword, string("ELSE"));
        $$ = res;
    }

    | ENABLE_P {
        res = new IR(kBareLabelKeyword, string("ENABLE"));
        $$ = res;
    }

    | ENCODING {
        res = new IR(kBareLabelKeyword, string("ENCODING"));
        $$ = res;
    }

    | ENCRYPTED {
        res = new IR(kBareLabelKeyword, string("ENCRYPTED"));
        $$ = res;
    }

    | END_P {
        res = new IR(kBareLabelKeyword, string("END"));
        $$ = res;
    }

    | ENUM_P {
        res = new IR(kBareLabelKeyword, string("ENUM"));
        $$ = res;
    }

    | ESCAPE {
        res = new IR(kBareLabelKeyword, string("ESCAPE"));
        $$ = res;
    }

    | EVENT {
        res = new IR(kBareLabelKeyword, string("EVENT"));
        $$ = res;
    }

    | EXCLUDE {
        res = new IR(kBareLabelKeyword, string("EXCLUDE"));
        $$ = res;
    }

    | EXCLUDING {
        res = new IR(kBareLabelKeyword, string("EXCLUDING"));
        $$ = res;
    }

    | EXCLUSIVE {
        res = new IR(kBareLabelKeyword, string("EXCLUSIVE"));
        $$ = res;
    }

    | EXECUTE {
        res = new IR(kBareLabelKeyword, string("EXECUTE"));
        $$ = res;
    }

    | EXISTS {
        res = new IR(kBareLabelKeyword, string("EXISTS"));
        $$ = res;
    }

    | EXPLAIN {
        res = new IR(kBareLabelKeyword, string("EXPLAIN"));
        $$ = res;
    }

    | EXPRESSION {
        res = new IR(kBareLabelKeyword, string("EXPRESSION"));
        $$ = res;
    }

    | EXTENSION {
        res = new IR(kBareLabelKeyword, string("EXTENSION"));
        $$ = res;
    }

    | EXTERNAL {
        res = new IR(kBareLabelKeyword, string("EXTERNAL"));
        $$ = res;
    }

    | EXTRACT {
        res = new IR(kBareLabelKeyword, string("EXTRACT"));
        $$ = res;
    }

    | FALSE_P {
        res = new IR(kBareLabelKeyword, string("FALSE"));
        $$ = res;
    }

    | FAMILY {
        res = new IR(kBareLabelKeyword, string("FAMILY"));
        $$ = res;
    }

    | FINALIZE {
        res = new IR(kBareLabelKeyword, string("FINALIZE"));
        $$ = res;
    }

    | FIRST_P {
        res = new IR(kBareLabelKeyword, string("FIRST"));
        $$ = res;
    }

    | FLOAT_P {
        res = new IR(kBareLabelKeyword, string("FLOAT"));
        $$ = res;
    }

    | FOLLOWING {
        res = new IR(kBareLabelKeyword, string("FOLLOWING"));
        $$ = res;
    }

    | FORCE {
        res = new IR(kBareLabelKeyword, string("FORCE"));
        $$ = res;
    }

    | FOREIGN {
        res = new IR(kBareLabelKeyword, string("FOREIGN"));
        $$ = res;
    }

    | FORWARD {
        res = new IR(kBareLabelKeyword, string("FORWARD"));
        $$ = res;
    }

    | FREEZE {
        res = new IR(kBareLabelKeyword, string("FREEZE"));
        $$ = res;
    }

    | FULL {
        res = new IR(kBareLabelKeyword, string("FULL"));
        $$ = res;
    }

    | FUNCTION {
        res = new IR(kBareLabelKeyword, string("FUNCTION"));
        $$ = res;
    }

    | FUNCTIONS {
        res = new IR(kBareLabelKeyword, string("FUNCTIONS"));
        $$ = res;
    }

    | GENERATED {
        res = new IR(kBareLabelKeyword, string("GENERATED"));
        $$ = res;
    }

    | GLOBAL {
        res = new IR(kBareLabelKeyword, string("GLOBAL"));
        $$ = res;
    }

    | GRANTED {
        res = new IR(kBareLabelKeyword, string("GRANTED"));
        $$ = res;
    }

    | GREATEST {
        res = new IR(kBareLabelKeyword, string("GREATEST"));
        $$ = res;
    }

    | GROUPING {
        res = new IR(kBareLabelKeyword, string("GROUPING"));
        $$ = res;
    }

    | GROUPS {
        res = new IR(kBareLabelKeyword, string("GROUPS"));
        $$ = res;
    }

    | HANDLER {
        res = new IR(kBareLabelKeyword, string("HANDLER"));
        $$ = res;
    }

    | HEADER_P {
        res = new IR(kBareLabelKeyword, string("HEADER"));
        $$ = res;
    }

    | HOLD {
        res = new IR(kBareLabelKeyword, string("HOLD"));
        $$ = res;
    }

    | IDENTITY_P {
        res = new IR(kBareLabelKeyword, string("IDENTITY"));
        $$ = res;
    }

    | IF_P {
        res = new IR(kBareLabelKeyword, string("IF"));
        $$ = res;
    }

    | ILIKE {
        res = new IR(kBareLabelKeyword, string("ILIKE"));
        $$ = res;
    }

    | IMMEDIATE {
        res = new IR(kBareLabelKeyword, string("IMMEDIATE"));
        $$ = res;
    }

    | IMMUTABLE {
        res = new IR(kBareLabelKeyword, string("IMMUTABLE"));
        $$ = res;
    }

    | IMPLICIT_P {
        res = new IR(kBareLabelKeyword, string("IMPLICIT"));
        $$ = res;
    }

    | IMPORT_P {
        res = new IR(kBareLabelKeyword, string("IMPORT"));
        $$ = res;
    }

    | IN_P {
        res = new IR(kBareLabelKeyword, string("IN"));
        $$ = res;
    }

    | INCLUDE {
        res = new IR(kBareLabelKeyword, string("INCLUDE"));
        $$ = res;
    }

    | INCLUDING {
        res = new IR(kBareLabelKeyword, string("INCLUDING"));
        $$ = res;
    }

    | INCREMENT {
        res = new IR(kBareLabelKeyword, string("INCREMENT"));
        $$ = res;
    }

    | INDEX {
        res = new IR(kBareLabelKeyword, string("INDEX"));
        $$ = res;
    }

    | INDEXES {
        res = new IR(kBareLabelKeyword, string("INDEXES"));
        $$ = res;
    }

    | INHERIT {
        res = new IR(kBareLabelKeyword, string("INHERIT"));
        $$ = res;
    }

    | INHERITS {
        res = new IR(kBareLabelKeyword, string("INHERITS"));
        $$ = res;
    }

    | INITIALLY {
        res = new IR(kBareLabelKeyword, string("INITIALLY"));
        $$ = res;
    }

    | INLINE_P {
        res = new IR(kBareLabelKeyword, string("INLINE"));
        $$ = res;
    }

    | INNER_P {
        res = new IR(kBareLabelKeyword, string("INNER"));
        $$ = res;
    }

    | INOUT {
        res = new IR(kBareLabelKeyword, string("INOUT"));
        $$ = res;
    }

    | INPUT_P {
        res = new IR(kBareLabelKeyword, string("INPUT"));
        $$ = res;
    }

    | INSENSITIVE {
        res = new IR(kBareLabelKeyword, string("INSENSITIVE"));
        $$ = res;
    }

    | INSERT {
        res = new IR(kBareLabelKeyword, string("INSERT"));
        $$ = res;
    }

    | INSTEAD {
        res = new IR(kBareLabelKeyword, string("INSTEAD"));
        $$ = res;
    }

    | INT_P {
        res = new IR(kBareLabelKeyword, string("INT"));
        $$ = res;
    }

    | INTEGER {
        res = new IR(kBareLabelKeyword, string("INTEGER"));
        $$ = res;
    }

    | INTERVAL {
        res = new IR(kBareLabelKeyword, string("INTERVAL"));
        $$ = res;
    }

    | INVOKER {
        res = new IR(kBareLabelKeyword, string("INVOKER"));
        $$ = res;
    }

    | IS {
        res = new IR(kBareLabelKeyword, string("IS"));
        $$ = res;
    }

    | ISOLATION {
        res = new IR(kBareLabelKeyword, string("ISOLATION"));
        $$ = res;
    }

    | JOIN {
        res = new IR(kBareLabelKeyword, string("JOIN"));
        $$ = res;
    }

    | KEY {
        res = new IR(kBareLabelKeyword, string("KEY"));
        $$ = res;
    }

    | LABEL {
        res = new IR(kBareLabelKeyword, string("LABEL"));
        $$ = res;
    }

    | LANGUAGE {
        res = new IR(kBareLabelKeyword, string("LANGUAGE"));
        $$ = res;
    }

    | LARGE_P {
        res = new IR(kBareLabelKeyword, string("LARGE"));
        $$ = res;
    }

    | LAST_P {
        res = new IR(kBareLabelKeyword, string("LAST"));
        $$ = res;
    }

    | LATERAL_P {
        res = new IR(kBareLabelKeyword, string("LATERAL"));
        $$ = res;
    }

    | LEADING {
        res = new IR(kBareLabelKeyword, string("LEADING"));
        $$ = res;
    }

    | LEAKPROOF {
        res = new IR(kBareLabelKeyword, string("LEAKPROOF"));
        $$ = res;
    }

    | LEAST {
        res = new IR(kBareLabelKeyword, string("LEAST"));
        $$ = res;
    }

    | LEFT {
        res = new IR(kBareLabelKeyword, string("LEFT"));
        $$ = res;
    }

    | LEVEL {
        res = new IR(kBareLabelKeyword, string("LEVEL"));
        $$ = res;
    }

    | LIKE {
        res = new IR(kBareLabelKeyword, string("LIKE"));
        $$ = res;
    }

    | LISTEN {
        res = new IR(kBareLabelKeyword, string("LISTEN"));
        $$ = res;
    }

    | LOAD {
        res = new IR(kBareLabelKeyword, string("LOAD"));
        $$ = res;
    }

    | LOCAL {
        res = new IR(kBareLabelKeyword, string("LOCAL"));
        $$ = res;
    }

    | LOCALTIME {
        res = new IR(kBareLabelKeyword, string("LOCALTIME"));
        $$ = res;
    }

    | LOCALTIMESTAMP {
        res = new IR(kBareLabelKeyword, string("LOCALTIMESTAMP"));
        $$ = res;
    }

    | LOCATION {
        res = new IR(kBareLabelKeyword, string("LOCATION"));
        $$ = res;
    }

    | LOCK_P {
        res = new IR(kBareLabelKeyword, string("LOCK"));
        $$ = res;
    }

    | LOCKED {
        res = new IR(kBareLabelKeyword, string("LOCKED"));
        $$ = res;
    }

    | LOGGED {
        res = new IR(kBareLabelKeyword, string("LOGGED"));
        $$ = res;
    }

    | MAPPING {
        res = new IR(kBareLabelKeyword, string("MAPPING"));
        $$ = res;
    }

    | MATCH {
        res = new IR(kBareLabelKeyword, string("MATCH"));
        $$ = res;
    }

    | MATERIALIZED {
        res = new IR(kBareLabelKeyword, string("MATERIALIZED"));
        $$ = res;
    }

    | MAXVALUE {
        res = new IR(kBareLabelKeyword, string("MAXVALUE"));
        $$ = res;
    }

    | METHOD {
        res = new IR(kBareLabelKeyword, string("METHOD"));
        $$ = res;
    }

    | MINVALUE {
        res = new IR(kBareLabelKeyword, string("MINVALUE"));
        $$ = res;
    }

    | MODE {
        res = new IR(kBareLabelKeyword, string("MODE"));
        $$ = res;
    }

    | MOVE {
        res = new IR(kBareLabelKeyword, string("MOVE"));
        $$ = res;
    }

    | NAME_P {
        res = new IR(kBareLabelKeyword, string("NAME"));
        $$ = res;
    }

    | NAMES {
        res = new IR(kBareLabelKeyword, string("NAMES"));
        $$ = res;
    }

    | NATIONAL {
        res = new IR(kBareLabelKeyword, string("NATIONAL"));
        $$ = res;
    }

    | NATURAL {
        res = new IR(kBareLabelKeyword, string("NATURAL"));
        $$ = res;
    }

    | NCHAR {
        res = new IR(kBareLabelKeyword, string("NCHAR"));
        $$ = res;
    }

    | NEW {
        res = new IR(kBareLabelKeyword, string("NEW"));
        $$ = res;
    }

    | NEXT {
        res = new IR(kBareLabelKeyword, string("NEXT"));
        $$ = res;
    }

    | NFC {
        res = new IR(kBareLabelKeyword, string("NFC"));
        $$ = res;
    }

    | NFD {
        res = new IR(kBareLabelKeyword, string("NFD"));
        $$ = res;
    }

    | NFKC {
        res = new IR(kBareLabelKeyword, string("NFKC"));
        $$ = res;
    }

    | NFKD {
        res = new IR(kBareLabelKeyword, string("NFKD"));
        $$ = res;
    }

    | NO {
        res = new IR(kBareLabelKeyword, string("NO"));
        $$ = res;
    }

    | NONE {
        res = new IR(kBareLabelKeyword, string("NONE"));
        $$ = res;
    }

    | NORMALIZE {
        res = new IR(kBareLabelKeyword, string("NORMALIZE"));
        $$ = res;
    }

    | NORMALIZED {
        res = new IR(kBareLabelKeyword, string("NORMALIZED"));
        $$ = res;
    }

    | NOT {
        res = new IR(kBareLabelKeyword, string("NOT"));
        $$ = res;
    }

    | NOTHING {
        res = new IR(kBareLabelKeyword, string("NOTHING"));
        $$ = res;
    }

    | NOTIFY {
        res = new IR(kBareLabelKeyword, string("NOTIFY"));
        $$ = res;
    }

    | NOWAIT {
        res = new IR(kBareLabelKeyword, string("NOWAIT"));
        $$ = res;
    }

    | NULL_P {
        res = new IR(kBareLabelKeyword, string("NULL"));
        $$ = res;
    }

    | NULLIF {
        res = new IR(kBareLabelKeyword, string("NULLIF"));
        $$ = res;
    }

    | NULLS_P {
        res = new IR(kBareLabelKeyword, string("NULLS"));
        $$ = res;
    }

    | NUMERIC {
        res = new IR(kBareLabelKeyword, string("NUMERIC"));
        $$ = res;
    }

    | OBJECT_P {
        res = new IR(kBareLabelKeyword, string("OBJECT"));
        $$ = res;
    }

    | OF {
        res = new IR(kBareLabelKeyword, string("OF"));
        $$ = res;
    }

    | OFF {
        res = new IR(kBareLabelKeyword, string("OFF"));
        $$ = res;
    }

    | OIDS {
        res = new IR(kBareLabelKeyword, string("OIDS"));
        $$ = res;
    }

    | OLD {
        res = new IR(kBareLabelKeyword, string("OLD"));
        $$ = res;
    }

    | ONLY {
        res = new IR(kBareLabelKeyword, string("ONLY"));
        $$ = res;
    }

    | OPERATOR {
        res = new IR(kBareLabelKeyword, string("OPERATOR"));
        $$ = res;
    }

    | OPTION {
        res = new IR(kBareLabelKeyword, string("OPTION"));
        $$ = res;
    }

    | OPTIONS {
        res = new IR(kBareLabelKeyword, string("OPTIONS"));
        $$ = res;
    }

    | OR {
        res = new IR(kBareLabelKeyword, string("OR"));
        $$ = res;
    }

    | ORDINALITY {
        res = new IR(kBareLabelKeyword, string("ORDINALITY"));
        $$ = res;
    }

    | OTHERS {
        res = new IR(kBareLabelKeyword, string("OTHERS"));
        $$ = res;
    }

    | OUT_P {
        res = new IR(kBareLabelKeyword, string("OUT"));
        $$ = res;
    }

    | OUTER_P {
        res = new IR(kBareLabelKeyword, string("OUTER"));
        $$ = res;
    }

    | OVERLAY {
        res = new IR(kBareLabelKeyword, string("OVERLAY"));
        $$ = res;
    }

    | OVERRIDING {
        res = new IR(kBareLabelKeyword, string("OVERRIDING"));
        $$ = res;
    }

    | OWNED {
        res = new IR(kBareLabelKeyword, string("OWNED"));
        $$ = res;
    }

    | OWNER {
        res = new IR(kBareLabelKeyword, string("OWNER"));
        $$ = res;
    }

    | PARALLEL {
        res = new IR(kBareLabelKeyword, string("PARALLEL"));
        $$ = res;
    }

    | PARSER {
        res = new IR(kBareLabelKeyword, string("PARSER"));
        $$ = res;
    }

    | PARTIAL {
        res = new IR(kBareLabelKeyword, string("PARTIAL"));
        $$ = res;
    }

    | PARTITION {
        res = new IR(kBareLabelKeyword, string("PARTITION"));
        $$ = res;
    }

    | PASSING {
        res = new IR(kBareLabelKeyword, string("PASSING"));
        $$ = res;
    }

    | PASSWORD {
        res = new IR(kBareLabelKeyword, string("PASSWORD"));
        $$ = res;
    }

    | PLACING {
        res = new IR(kBareLabelKeyword, string("PLACING"));
        $$ = res;
    }

    | PLANS {
        res = new IR(kBareLabelKeyword, string("PLANS"));
        $$ = res;
    }

    | POLICY {
        res = new IR(kBareLabelKeyword, string("POLICY"));
        $$ = res;
    }

    | POSITION {
        res = new IR(kBareLabelKeyword, string("POSITION"));
        $$ = res;
    }

    | PRECEDING {
        res = new IR(kBareLabelKeyword, string("PRECEDING"));
        $$ = res;
    }

    | PREPARE {
        res = new IR(kBareLabelKeyword, string("PREPARE"));
        $$ = res;
    }

    | PREPARED {
        res = new IR(kBareLabelKeyword, string("PREPARED"));
        $$ = res;
    }

    | PRESERVE {
        res = new IR(kBareLabelKeyword, string("PRESERVE"));
        $$ = res;
    }

    | PRIMARY {
        res = new IR(kBareLabelKeyword, string("PRIMARY"));
        $$ = res;
    }

    | PRIOR {
        res = new IR(kBareLabelKeyword, string("PRIOR"));
        $$ = res;
    }

    | PRIVILEGES {
        res = new IR(kBareLabelKeyword, string("PRIVILEGES"));
        $$ = res;
    }

    | PROCEDURAL {
        res = new IR(kBareLabelKeyword, string("PROCEDURAL"));
        $$ = res;
    }

    | PROCEDURE {
        res = new IR(kBareLabelKeyword, string("PROCEDURE"));
        $$ = res;
    }

    | PROCEDURES {
        res = new IR(kBareLabelKeyword, string("PROCEDURES"));
        $$ = res;
    }

    | PROGRAM {
        res = new IR(kBareLabelKeyword, string("PROGRAM"));
        $$ = res;
    }

    | PUBLICATION {
        res = new IR(kBareLabelKeyword, string("PUBLICATION"));
        $$ = res;
    }

    | QUOTE {
        res = new IR(kBareLabelKeyword, string("QUOTE"));
        $$ = res;
    }

    | RANGE {
        res = new IR(kBareLabelKeyword, string("RANGE"));
        $$ = res;
    }

    | READ {
        res = new IR(kBareLabelKeyword, string("READ"));
        $$ = res;
    }

    | REAL {
        res = new IR(kBareLabelKeyword, string("REAL"));
        $$ = res;
    }

    | REASSIGN {
        res = new IR(kBareLabelKeyword, string("REASSIGN"));
        $$ = res;
    }

    | RECHECK {
        res = new IR(kBareLabelKeyword, string("RECHECK"));
        $$ = res;
    }

    | RECURSIVE {
        res = new IR(kBareLabelKeyword, string("RECURSIVE"));
        $$ = res;
    }

    | REF {
        res = new IR(kBareLabelKeyword, string("REF"));
        $$ = res;
    }

    | REFERENCES {
        res = new IR(kBareLabelKeyword, string("REFERENCES"));
        $$ = res;
    }

    | REFERENCING {
        res = new IR(kBareLabelKeyword, string("REFERENCING"));
        $$ = res;
    }

    | REFRESH {
        res = new IR(kBareLabelKeyword, string("REFRESH"));
        $$ = res;
    }

    | REINDEX {
        res = new IR(kBareLabelKeyword, string("REINDEX"));
        $$ = res;
    }

    | RELATIVE_P {
        res = new IR(kBareLabelKeyword, string("RELATIVE"));
        $$ = res;
    }

    | RELEASE {
        res = new IR(kBareLabelKeyword, string("RELEASE"));
        $$ = res;
    }

    | RENAME {
        res = new IR(kBareLabelKeyword, string("RENAME"));
        $$ = res;
    }

    | REPEATABLE {
        res = new IR(kBareLabelKeyword, string("REPEATABLE"));
        $$ = res;
    }

    | REPLACE {
        res = new IR(kBareLabelKeyword, string("REPLACE"));
        $$ = res;
    }

    | REPLICA {
        res = new IR(kBareLabelKeyword, string("REPLICA"));
        $$ = res;
    }

    | RESET {
        res = new IR(kBareLabelKeyword, string("RESET"));
        $$ = res;
    }

    | RESTART {
        res = new IR(kBareLabelKeyword, string("RESTART"));
        $$ = res;
    }

    | RESTRICT {
        res = new IR(kBareLabelKeyword, string("RESTRICT"));
        $$ = res;
    }

    | RETURN {
        res = new IR(kBareLabelKeyword, string("RETURN"));
        $$ = res;
    }

    | RETURNS {
        res = new IR(kBareLabelKeyword, string("RETURNS"));
        $$ = res;
    }

    | REVOKE {
        res = new IR(kBareLabelKeyword, string("REVOKE"));
        $$ = res;
    }

    | RIGHT {
        res = new IR(kBareLabelKeyword, string("RIGHT"));
        $$ = res;
    }

    | ROLE {
        res = new IR(kBareLabelKeyword, string("ROLE"));
        $$ = res;
    }

    | ROLLBACK {
        res = new IR(kBareLabelKeyword, string("ROLLBACK"));
        $$ = res;
    }

    | ROLLUP {
        res = new IR(kBareLabelKeyword, string("ROLLUP"));
        $$ = res;
    }

    | ROUTINE {
        res = new IR(kBareLabelKeyword, string("ROUTINE"));
        $$ = res;
    }

    | ROUTINES {
        res = new IR(kBareLabelKeyword, string("ROUTINES"));
        $$ = res;
    }

    | ROW {
        res = new IR(kBareLabelKeyword, string("ROW"));
        $$ = res;
    }

    | ROWS {
        res = new IR(kBareLabelKeyword, string("ROWS"));
        $$ = res;
    }

    | RULE {
        res = new IR(kBareLabelKeyword, string("RULE"));
        $$ = res;
    }

    | SAVEPOINT {
        res = new IR(kBareLabelKeyword, string("SAVEPOINT"));
        $$ = res;
    }

    | SCHEMA {
        res = new IR(kBareLabelKeyword, string("SCHEMA"));
        $$ = res;
    }

    | SCHEMAS {
        res = new IR(kBareLabelKeyword, string("SCHEMAS"));
        $$ = res;
    }

    | SCROLL {
        res = new IR(kBareLabelKeyword, string("SCROLL"));
        $$ = res;
    }

    | SEARCH {
        res = new IR(kBareLabelKeyword, string("SEARCH"));
        $$ = res;
    }

    | SECURITY {
        res = new IR(kBareLabelKeyword, string("SECURITY"));
        $$ = res;
    }

    | SELECT {
        res = new IR(kBareLabelKeyword, string("SELECT"));
        $$ = res;
    }

    | SEQUENCE {
        res = new IR(kBareLabelKeyword, string("SEQUENCE"));
        $$ = res;
    }

    | SEQUENCES {
        res = new IR(kBareLabelKeyword, string("SEQUENCES"));
        $$ = res;
    }

    | SERIALIZABLE {
        res = new IR(kBareLabelKeyword, string("SERIALIZABLE"));
        $$ = res;
    }

    | SERVER {
        res = new IR(kBareLabelKeyword, string("SERVER"));
        $$ = res;
    }

    | SESSION {
        res = new IR(kBareLabelKeyword, string("SESSION"));
        $$ = res;
    }

    | SESSION_USER {
        res = new IR(kBareLabelKeyword, string("SESSION_USER"));
        $$ = res;
    }

    | SET {
        res = new IR(kBareLabelKeyword, string("SET"));
        $$ = res;
    }

    | SETOF {
        res = new IR(kBareLabelKeyword, string("SETOF"));
        $$ = res;
    }

    | SETS {
        res = new IR(kBareLabelKeyword, string("SETS"));
        $$ = res;
    }

    | SHARE {
        res = new IR(kBareLabelKeyword, string("SHARE"));
        $$ = res;
    }

    | SHOW {
        res = new IR(kBareLabelKeyword, string("SHOW"));
        $$ = res;
    }

    | SIMILAR {
        res = new IR(kBareLabelKeyword, string("SIMILAR"));
        $$ = res;
    }

    | SIMPLE {
        res = new IR(kBareLabelKeyword, string("SIMPLE"));
        $$ = res;
    }

    | SKIP {
        res = new IR(kBareLabelKeyword, string("SKIP"));
        $$ = res;
    }

    | SMALLINT {
        res = new IR(kBareLabelKeyword, string("SMALLINT"));
        $$ = res;
    }

    | SNAPSHOT {
        res = new IR(kBareLabelKeyword, string("SNAPSHOT"));
        $$ = res;
    }

    | SOME {
        res = new IR(kBareLabelKeyword, string("SOME"));
        $$ = res;
    }

    | SQL_P {
        res = new IR(kBareLabelKeyword, string("SQL"));
        $$ = res;
    }

    | STABLE {
        res = new IR(kBareLabelKeyword, string("STABLE"));
        $$ = res;
    }

    | STANDALONE_P {
        res = new IR(kBareLabelKeyword, string("STANDALONE"));
        $$ = res;
    }

    | START {
        res = new IR(kBareLabelKeyword, string("START"));
        $$ = res;
    }

    | STATEMENT {
        res = new IR(kBareLabelKeyword, string("STATEMENT"));
        $$ = res;
    }

    | STATISTICS {
        res = new IR(kBareLabelKeyword, string("STATISTICS"));
        $$ = res;
    }

    | STDIN {
        res = new IR(kBareLabelKeyword, string("STDIN"));
        $$ = res;
    }

    | STDOUT {
        res = new IR(kBareLabelKeyword, string("STDOUT"));
        $$ = res;
    }

    | STORAGE {
        res = new IR(kBareLabelKeyword, string("STORAGE"));
        $$ = res;
    }

    | STORED {
        res = new IR(kBareLabelKeyword, string("STORED"));
        $$ = res;
    }

    | STRICT_P {
        res = new IR(kBareLabelKeyword, string("STRICT"));
        $$ = res;
    }

    | STRIP_P {
        res = new IR(kBareLabelKeyword, string("STRIP"));
        $$ = res;
    }

    | SUBSCRIPTION {
        res = new IR(kBareLabelKeyword, string("SUBSCRIPTION"));
        $$ = res;
    }

    | SUBSTRING {
        res = new IR(kBareLabelKeyword, string("SUBSTRING"));
        $$ = res;
    }

    | SUPPORT {
        res = new IR(kBareLabelKeyword, string("SUPPORT"));
        $$ = res;
    }

    | SYMMETRIC {
        res = new IR(kBareLabelKeyword, string("SYMMETRIC"));
        $$ = res;
    }

    | SYSID {
        res = new IR(kBareLabelKeyword, string("SYSID"));
        $$ = res;
    }

    | SYSTEM_P {
        res = new IR(kBareLabelKeyword, string("SYSTEM"));
        $$ = res;
    }

    | TABLE {
        res = new IR(kBareLabelKeyword, string("TABLE"));
        $$ = res;
    }

    | TABLES {
        res = new IR(kBareLabelKeyword, string("TABLES"));
        $$ = res;
    }

    | TABLESAMPLE {
        res = new IR(kBareLabelKeyword, string("TABLESAMPLE"));
        $$ = res;
    }

    | TABLESPACE {
        res = new IR(kBareLabelKeyword, string("TABLESPACE"));
        $$ = res;
    }

    | TEMP {
        res = new IR(kBareLabelKeyword, string("TEMP"));
        $$ = res;
    }

    | TEMPLATE {
        res = new IR(kBareLabelKeyword, string("TEMPLATE"));
        $$ = res;
    }

    | TEMPORARY {
        res = new IR(kBareLabelKeyword, string("TEMPORARY"));
        $$ = res;
    }

    | TEXT_P {
        res = new IR(kBareLabelKeyword, string("TEXT"));
        $$ = res;
    }

    | THEN {
        res = new IR(kBareLabelKeyword, string("THEN"));
        $$ = res;
    }

    | TIES {
        res = new IR(kBareLabelKeyword, string("TIES"));
        $$ = res;
    }

    | TIME {
        res = new IR(kBareLabelKeyword, string("TIME"));
        $$ = res;
    }

    | TIMESTAMP {
        res = new IR(kBareLabelKeyword, string("TIMESTAMP"));
        $$ = res;
    }

    | TRAILING {
        res = new IR(kBareLabelKeyword, string("TRAILING"));
        $$ = res;
    }

    | TRANSACTION {
        res = new IR(kBareLabelKeyword, string("TRANSACTION"));
        $$ = res;
    }

    | TRANSFORM {
        res = new IR(kBareLabelKeyword, string("TRANSFORM"));
        $$ = res;
    }

    | TREAT {
        res = new IR(kBareLabelKeyword, string("TREAT"));
        $$ = res;
    }

    | TRIGGER {
        res = new IR(kBareLabelKeyword, string("TRIGGER"));
        $$ = res;
    }

    | TRIM {
        res = new IR(kBareLabelKeyword, string("TRIM"));
        $$ = res;
    }

    | TRUE_P {
        res = new IR(kBareLabelKeyword, string("TRUE"));
        $$ = res;
    }

    | TRUNCATE {
        res = new IR(kBareLabelKeyword, string("TRUNCATE"));
        $$ = res;
    }

    | TRUSTED {
        res = new IR(kBareLabelKeyword, string("TRUSTED"));
        $$ = res;
    }

    | TYPE_P {
        res = new IR(kBareLabelKeyword, string("TYPE"));
        $$ = res;
    }

    | TYPES_P {
        res = new IR(kBareLabelKeyword, string("TYPES"));
        $$ = res;
    }

    | UESCAPE {
        res = new IR(kBareLabelKeyword, string("UESCAPE"));
        $$ = res;
    }

    | UNBOUNDED {
        res = new IR(kBareLabelKeyword, string("UNBOUNDED"));
        $$ = res;
    }

    | UNCOMMITTED {
        res = new IR(kBareLabelKeyword, string("UNCOMMITTED"));
        $$ = res;
    }

    | UNENCRYPTED {
        res = new IR(kBareLabelKeyword, string("UNENCRYPTED"));
        $$ = res;
    }

    | UNIQUE {
        res = new IR(kBareLabelKeyword, string("UNIQUE"));
        $$ = res;
    }

    | UNKNOWN {
        res = new IR(kBareLabelKeyword, string("UNKNOWN"));
        $$ = res;
    }

    | UNLISTEN {
        res = new IR(kBareLabelKeyword, string("UNLISTEN"));
        $$ = res;
    }

    | UNLOGGED {
        res = new IR(kBareLabelKeyword, string("UNLOGGED"));
        $$ = res;
    }

    | UNTIL {
        res = new IR(kBareLabelKeyword, string("UNTIL"));
        $$ = res;
    }

    | UPDATE {
        res = new IR(kBareLabelKeyword, string("UPDATE"));
        $$ = res;
    }

    | USER {
        res = new IR(kBareLabelKeyword, string("USER"));
        $$ = res;
    }

    | USING {
        res = new IR(kBareLabelKeyword, string("USING"));
        $$ = res;
    }

    | VACUUM {
        res = new IR(kBareLabelKeyword, string("VACUUM"));
        $$ = res;
    }

    | VALID {
        res = new IR(kBareLabelKeyword, string("VALID"));
        $$ = res;
    }

    | VALIDATE {
        res = new IR(kBareLabelKeyword, string("VALIDATE"));
        $$ = res;
    }

    | VALIDATOR {
        res = new IR(kBareLabelKeyword, string("VALIDATOR"));
        $$ = res;
    }

    | VALUE_P {
        res = new IR(kBareLabelKeyword, string("VALUE"));
        $$ = res;
    }

    | VALUES {
        res = new IR(kBareLabelKeyword, string("VALUES"));
        $$ = res;
    }

    | VARCHAR {
        res = new IR(kBareLabelKeyword, string("VARCHAR"));
        $$ = res;
    }

    | VARIADIC {
        res = new IR(kBareLabelKeyword, string("VARIADIC"));
        $$ = res;
    }

    | VERBOSE {
        res = new IR(kBareLabelKeyword, string("VERBOSE"));
        $$ = res;
    }

    | VERSION_P {
        res = new IR(kBareLabelKeyword, string("VERSION"));
        $$ = res;
    }

    | VIEW {
        res = new IR(kBareLabelKeyword, string("VIEW"));
        $$ = res;
    }

    | VIEWS {
        res = new IR(kBareLabelKeyword, string("VIEWS"));
        $$ = res;
    }

    | VOLATILE {
        res = new IR(kBareLabelKeyword, string("VOLATILE"));
        $$ = res;
    }

    | WHEN {
        res = new IR(kBareLabelKeyword, string("WHEN"));
        $$ = res;
    }

    | WHITESPACE_P {
        res = new IR(kBareLabelKeyword, string("WHITESPACE"));
        $$ = res;
    }

    | WORK {
        res = new IR(kBareLabelKeyword, string("WORK"));
        $$ = res;
    }

    | WRAPPER {
        res = new IR(kBareLabelKeyword, string("WRAPPER"));
        $$ = res;
    }

    | WRITE {
        res = new IR(kBareLabelKeyword, string("WRITE"));
        $$ = res;
    }

    | XML_P {
        res = new IR(kBareLabelKeyword, string("XML"));
        $$ = res;
    }

    | XMLATTRIBUTES {
        res = new IR(kBareLabelKeyword, string("XMLATTRIBUTES"));
        $$ = res;
    }

    | XMLCONCAT {
        res = new IR(kBareLabelKeyword, string("XMLCONCAT"));
        $$ = res;
    }

    | XMLELEMENT {
        res = new IR(kBareLabelKeyword, string("XMLELEMENT"));
        $$ = res;
    }

    | XMLEXISTS {
        res = new IR(kBareLabelKeyword, string("XMLEXISTS"));
        $$ = res;
    }

    | XMLFOREST {
        res = new IR(kBareLabelKeyword, string("XMLFOREST"));
        $$ = res;
    }

    | XMLNAMESPACES {
        res = new IR(kBareLabelKeyword, string("XMLNAMESPACES"));
        $$ = res;
    }

    | XMLPARSE {
        res = new IR(kBareLabelKeyword, string("XMLPARSE"));
        $$ = res;
    }

    | XMLPI {
        res = new IR(kBareLabelKeyword, string("XMLPI"));
        $$ = res;
    }

    | XMLROOT {
        res = new IR(kBareLabelKeyword, string("XMLROOT"));
        $$ = res;
    }

    | XMLSERIALIZE {
        res = new IR(kBareLabelKeyword, string("XMLSERIALIZE"));
        $$ = res;
    }

    | XMLTABLE {
        res = new IR(kBareLabelKeyword, string("XMLTABLE"));
        $$ = res;
    }

    | YES_P {
        res = new IR(kBareLabelKeyword, string("YES"));
        $$ = res;
    }

    | ZONE {
        res = new IR(kBareLabelKeyword, string("ZONE"));
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
        res = new IR(kDocumentOrContent, string("DOCUMENT_P"));
        $$ = res;
    }

    | CONTENT_P DOCUMENT_P {
        res = new IR(kDocumentOrContent, string("CONTENT_P DOCUMENT_P"));
        $$ = res;
    }

    | CONTENT_P DOCUMENT_P CONTENT_P {
        res = new IR(kDocumentOrContent, string("CONTENT_P DOCUMENT_P CONTENT_P"));
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
        res = new IR(kQualifiedNameList, OP3("", "", ""), tmp1);
        $$ = res;
    }

    | qualified_name_list ',' qualified_name {
        auto tmp1 = $1;
        auto tmp2 = $3;
        res = new IR(kQualifiedNameList, OP3("", ",", ""), tmp1, tmp2);
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
        res = new IR(kNumeric, OP3("INT", "", ""));
        $$ = res;
    }

    | INTEGER {
        res = new IR(kNumeric, OP3("INTEGER", "", ""));
        $$ = res;
    }

    | SMALLINT {
        res = new IR(kNumeric, OP3("SMALLINT", "", ""));
        $$ = res;
    }

    | BIGINT {
        res = new IR(kNumeric, OP3("BIGINT", "", ""));
        $$ = res;
    }

    | REAL {
        res = new IR(kNumeric, OP3("REAL", "", ""));
        $$ = res;
    }

    | FLOAT_P opt_float {
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("FLOAT", "", ""), tmp1);
        $$ = res;
    }

    | DOUBLE_P PRECISION {
        res = new IR(kNumeric, OP3("DOUBLE PRECISION", "", ""));
        $$ = res;
    }

    | DECIMAL_P opt_type_modifiers {
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("DECIMAL", "", ""), tmp1);
        $$ = res;
    }

    | DEC opt_type_modifiers {
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("DEC", "", ""), tmp1);
        $$ = res;
    }

    | NUMERIC opt_type_modifiers {
        auto tmp1 = $2;
        res = new IR(kNumeric, OP3("NUMERIC", "", ""), tmp1);
        $$ = res;
    }

    | BOOLEAN_P {
        res = new IR(kNumeric, OP3("BOOLEAN", "", ""));
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


def TestMultipleComments():
    data = """
bare_label_keyword: /* EMPTY */
			  ABORT_P
			  /* EMPTY */
			| /* EMPTY */
			  ABSOLUTE_P /* EMPTY */
			| /* EMPTY */ ACCESS
			| ACTION /* EMPTY */
			| /* EMPTY */ XMLTABLE /* EMPTY */
			/* EMPTY */
			| /* EMPTY */
			  YES_P
			| ZONE
			  /* EMPTY */
	    ;
"""
    expect = """
bare_label_keyword:

    ABORT_P {
        res = new IR(kBareLabelKeyword, OP3("ABORT", "", ""));
        $$ = res;
    }

    | ABSOLUTE_P {
        res = new IR(kBareLabelKeyword, OP3("ABSOLUTE", "", ""));
        $$ = res;
    }

    | ACCESS {
        res = new IR(kBareLabelKeyword, OP3("ACCESS", "", ""));
        $$ = res;
    }

    | ACTION {
        res = new IR(kBareLabelKeyword, OP3("ACTION", "", ""));
        $$ = res;
    }

    | XMLTABLE {
        res = new IR(kBareLabelKeyword, OP3("XMLTABLE", "", ""));
        $$ = res;
    }

    | YES_P {
        res = new IR(kBareLabelKeyword, OP3("YES", "", ""));
        $$ = res;
    }

    | ZONE {
        res = new IR(kBareLabelKeyword, OP3("ZONE", "", ""));
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
        TestMultipleComments()
        print("All tests passed!")
    except Exception as e:
        logger.exception(e)
        


if __name__ == "__main__":
    test()
