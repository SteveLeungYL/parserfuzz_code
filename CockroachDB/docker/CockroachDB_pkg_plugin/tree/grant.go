// Copyright 2012, Google Inc. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in licenses/BSD-vitess.txt.

// Portions of this file are additionally subject to the following
// license and copyright.
//
// Copyright 2015 The Cockroach Authors.
//
// Use of this software is governed by the Business Source License
// included in the file licenses/BSL.txt.
//
// As of the Change Date specified in that file, in accordance with
// the Business Source License, use of this software will be governed
// by the Apache License, Version 2.0, included in the file
// licenses/APL.txt.

// This code was derived from https://github.com/youtube/vitess.

package tree

import "github.com/cockroachdb/cockroach/pkg/sql/privilege"

// Grant represents a GRANT statement.
type Grant struct {
	Privileges      privilege.List
	Targets         GrantTargetList
	Grantees        RoleSpecList
	WithGrantOption bool
}

// GrantTargetList represents a list of targets.
// Only one field may be non-nil.
type GrantTargetList struct {
	Databases NameList
	Schemas   ObjectNamePrefixList
	Tables    TableAttrs
	Types     []*UnresolvedObjectName
	Functions FuncObjs
	// If the target is for all sequences in a set of schemas.
	AllSequencesInSchema bool
	// If the target is for all tables in a set of schemas.
	AllTablesInSchema bool
	// If the target is for all functions in a set of schemas.
	AllFunctionsInSchema bool
	// If the target is system.
	System bool
	// If the target is External Connection.
	ExternalConnections NameList

	// ForRoles and Roles are used internally in the parser and not used
	// in the AST. Therefore they do not participate in pretty-printing,
	// etc.
	ForRoles bool
	Roles    RoleSpecList
}

// Format implements the NodeFormatter interface.
func (tl *GrantTargetList) Format(ctx *FmtCtx) {
	if tl.Databases != nil {
		ctx.WriteString("DATABASE ")
		ctx.FormatNode(&tl.Databases)
	} else if tl.AllSequencesInSchema {
		ctx.WriteString("ALL SEQUENCES IN SCHEMA ")
		ctx.FormatNode(&tl.Schemas)
	} else if tl.AllTablesInSchema {
		ctx.WriteString("ALL TABLES IN SCHEMA ")
		ctx.FormatNode(&tl.Schemas)
	} else if tl.AllFunctionsInSchema {
		ctx.WriteString("ALL FUNCTIONS IN SCHEMA ")
		ctx.FormatNode(&tl.Schemas)
	} else if tl.Schemas != nil {
		ctx.WriteString("SCHEMA ")
		ctx.FormatNode(&tl.Schemas)
	} else if tl.Types != nil {
		ctx.WriteString("TYPE ")
		for i, typ := range tl.Types {
			if i != 0 {
				ctx.WriteString(", ")
			}
			ctx.FormatNode(typ)
		}
	} else if tl.ExternalConnections != nil {
		ctx.WriteString("EXTERNAL CONNECTION ")
		ctx.FormatNode(&tl.ExternalConnections)
	} else if tl.Functions != nil {
		ctx.WriteString("FUNCTION ")
		ctx.FormatNode(tl.Functions)
	} else {
		if tl.Tables.SequenceOnly {
			ctx.WriteString("SEQUENCE ")
		} else {
			ctx.WriteString("TABLE ")
		}
		ctx.FormatNode(&tl.Tables.TablePatterns)
	}
}

// SQLRight Code Injection.
func (node *GrantTargetList) LogCurrentNode(depth int) *SQLRightIR {

	if node.Databases != nil {
		prefix := "DATABASE "
		databaseNode := node.Databases.LogCurrentNode(depth + 1)

		rootIR := &SQLRightIR{
			IRType:   TypeGrantTargetList,
			DataType: DataNone,
			LNode:    databaseNode,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		return rootIR

	} else if node.AllSequencesInSchema {
		prefix := "ALL SEQUENCES IN SCHEMA "
		schemaNode := node.Schemas.LogCurrentNode(depth + 1)

		rootIR := &SQLRightIR{
			IRType:   TypeGrantTargetList,
			DataType: DataNone,
			LNode:    schemaNode,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		return rootIR

	} else if node.AllTablesInSchema {
		prefix := "ALL TABLES IN SCHEMA "
		schemaNode := node.Schemas.LogCurrentNode(depth + 1)

		rootIR := &SQLRightIR{
			IRType:   TypeGrantTargetList,
			DataType: DataNone,
			LNode:    schemaNode,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		return rootIR
	} else if node.AllFunctionsInSchema {
		prefix := "ALL FUNCTIONS IN SCHEMA "
		schemaNode := node.Schemas.LogCurrentNode(depth + 1)

		rootIR := &SQLRightIR{
			IRType:   TypeGrantTargetList,
			DataType: DataNone,
			LNode:    schemaNode,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		return rootIR

	} else if node.Schemas != nil {

		prefix := "SCHEMA "
		schemaNode := node.Schemas.LogCurrentNode(depth + 1)

		rootIR := &SQLRightIR{
			IRType:   TypeGrantTargetList,
			DataType: DataNone,
			LNode:    schemaNode,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		return rootIR

	} else if node.Types != nil {
		prefix := "TYPE "
		var tmpIR *SQLRightIR

		for i, n := range node.Types {

			if i == 0 {
				// Take care of the first two nodes.
				LNode := &SQLRightIR{
					IRType:      TypeIdentifier,
					DataType:    DataTypeName,
					ContextFlag: ContextUse,
					//LNode:    LNode,
					//RNode:    RNode,
					Prefix: "",
					Infix:  "",
					Suffix: "",
					Depth:  depth,
					Str:    n.String(),
				}
				var RNode *SQLRightIR
				infix := ""
				if len(node.Types) >= 2 {
					infix = ", "
					tmpRNode := &SQLRightIR{
						IRType:      TypeIdentifier,
						DataType:    DataTypeName,
						ContextFlag: ContextUse,
						//LNode:    LNode,
						//RNode:    RNode,
						Prefix: "",
						Infix:  "",
						Suffix: "",
						Depth:  depth,
						Str:    (node.Types)[1].String(),
					}
					RNode = tmpRNode
				}
				tmpIR = &SQLRightIR{
					IRType:   TypeUnknown,
					DataType: DataNone,
					LNode:    LNode,
					RNode:    RNode,
					Prefix:   prefix,
					Infix:    infix,
					Suffix:   "",
					Depth:    depth,
				}
			} else if i == 1 {
				// The first two element would be saved in the same IR node.
				continue
			} else {
				// i >= 2. Begins from the third element.
				// Left node is the previous cmds.
				// Right node is the new cmd.
				LNode := tmpIR
				RNode := &SQLRightIR{
					IRType:      TypeIdentifier,
					DataType:    DataTypeName,
					ContextFlag: ContextUse,
					Prefix:      "",
					Infix:       ", ",
					Suffix:      "",
					Depth:       depth,
					Str:         n.String(),
				}

				tmpIR = &SQLRightIR{
					IRType:   TypeUnknown,
					DataType: DataNone,
					LNode:    LNode,
					RNode:    RNode,
					Prefix:   "",
					Infix:    " ",
					Suffix:   "",
					Depth:    depth,
				}
			}
		}

		tmpIR.IRType = TypeGrantTargetList
		return tmpIR

	} else if node.ExternalConnections != nil {
		prefix := "EXTERNAL CONNECTION "
		schemaNode := node.ExternalConnections.LogCurrentNode(depth + 1)

		rootIR := &SQLRightIR{
			IRType:   TypeGrantTargetList,
			DataType: DataNone,
			LNode:    schemaNode,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		return rootIR
	} else if node.Functions != nil {
		prefix := "FUNCTION "
		schemaNode := node.Functions.LogCurrentNode(depth+1, ContextUse)

		rootIR := &SQLRightIR{
			IRType:   TypeGrantTargetList,
			DataType: DataNone,
			LNode:    schemaNode,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		return rootIR

	} else {
		prefix := ""
		if node.Tables.SequenceOnly {
			prefix = "SEQUENCE "
		} else {
			prefix = "TABLE "
		}

		tablePatNode := node.Tables.TablePatterns.LogCurrentNode(depth + 1)

		rootIR := &SQLRightIR{
			IRType:   TypeGrantTargetList,
			DataType: DataNone,
			LNode:    tablePatNode,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		return rootIR

	}

}

// Format implements the NodeFormatter interface.
func (node *Grant) Format(ctx *FmtCtx) {
	ctx.WriteString("GRANT ")
	if node.Targets.System {
		ctx.WriteString(" SYSTEM ")
	}
	node.Privileges.Format(&ctx.Buffer)
	if !node.Targets.System {
		ctx.WriteString(" ON ")
		ctx.FormatNode(&node.Targets)
	}
	ctx.WriteString(" TO ")
	ctx.FormatNode(&node.Grantees)
}

// SQLRight Code Injection.
func (node *Grant) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "GRANT "
	if node.Targets.System {
		prefix += " SYSTEM "
	}

	privilegesStr := node.Privileges.String()
	privilegesNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataPrivilege,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         privilegesStr,
	}

	infix := ""
	var pTargetNode *SQLRightIR
	if !node.Targets.System {
		infix = " ON "
		pTargetNode = node.Targets.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    privilegesNode,
		RNode:    pTargetNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	infix = " TO "
	grantNode := node.Grantees.LogCurrentNode(depth+1, ContextUse)

	rootIR = &SQLRightIR{
		IRType:   TypeGrant,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    grantNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// GrantRole represents a GRANT <role> statement.
type GrantRole struct {
	Roles       NameList
	Members     RoleSpecList
	AdminOption bool
}

// Format implements the NodeFormatter interface.
func (node *GrantRole) Format(ctx *FmtCtx) {
	ctx.WriteString("GRANT ")
	ctx.FormatNode(&node.Roles)
	ctx.WriteString(" TO ")
	ctx.FormatNode(&node.Members)
	if node.AdminOption {
		ctx.WriteString(" WITH ADMIN OPTION")
	}
}

// SQLRight Code Injection.
func (node *GrantRole) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "GRANT "

	roleNode := node.Roles.LogCurrentNode(depth + 1)

	infix := " TO "

	memberNode := node.Members.LogCurrentNode(depth+1, ContextUse)

	suffix := ""
	if node.AdminOption {
		suffix += " WITH ADMIN OPTION"
	}

	rootIR := &SQLRightIR{
		IRType:   TypeGrantRole,
		DataType: DataNone,
		LNode:    roleNode,
		RNode:    memberNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   suffix,
		Depth:    depth,
	}

	return rootIR
}
