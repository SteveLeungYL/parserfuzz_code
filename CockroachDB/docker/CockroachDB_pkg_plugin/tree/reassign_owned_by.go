// Copyright 2020 The Cockroach Authors.
//
// Use of this software is governed by the Business Source License
// included in the file licenses/BSL.txt.
//
// As of the Change Date specified in that file, in accordance with
// the Business Source License, use of this software will be governed
// by the Apache License, Version 2.0, included in the file
// licenses/APL.txt.

package tree

// ReassignOwnedBy represents a REASSIGN OWNED BY <name> TO <name> statement.
type ReassignOwnedBy struct {
	OldRoles RoleSpecList
	NewRole  RoleSpec
}

var _ Statement = &ReassignOwnedBy{}

// Format implements the NodeFormatter interface.
func (node *ReassignOwnedBy) Format(ctx *FmtCtx) {
	ctx.WriteString("REASSIGN OWNED BY ")
	for i := range node.OldRoles {
		if i > 0 {
			ctx.WriteString(", ")
		}
		node.OldRoles[i].Format(ctx)
	}
	ctx.WriteString(" TO ")
	ctx.FormatNode(&node.NewRole)
}

// SQLRight Code Injection.
func (node *ReassignOwnedBy) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "REASSIGN OWNED BY "

	var rootIR *SQLRightIR
	for i, n := range node.OldRoles {
		if i == 0 {
			// Take care of the first two nodes.
			LNode := n.LogCurrentNode(depth+1, ContextUse)
			var RNode *SQLRightIR
			infix := ""
			if len(node.OldRoles) >= 2 {
				infix = ", "
				RNode = (node.OldRoles)[1].LogCurrentNode(depth+1, ContextUse)
			}
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   "",
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
			LNode := rootIR
			RNode := n.LogCurrentNode(depth+1, ContextUse)

			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   "",
				Infix:    ", ",
				Suffix:   "",
				Depth:    depth,
			}
		}
	}

	newRoleNode := node.NewRole.LogCurrentNode(depth+1, ContextUse)

	rootIR = &SQLRightIR{
		IRType:   TypeReassignOwnedBy,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    newRoleNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}
