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

// DropOwnedBy represents a DROP OWNED BY command.
type DropOwnedBy struct {
	Roles        RoleSpecList
	DropBehavior DropBehavior
}

var _ Statement = &DropOwnedBy{}

// Format implements the NodeFormatter interface.
func (node *DropOwnedBy) Format(ctx *FmtCtx) {
	ctx.WriteString("DROP OWNED BY ")
	for i := range node.Roles {
		if i > 0 {
			ctx.WriteString(", ")
		}
		node.Roles[i].Format(ctx)
	}
	if node.DropBehavior != DropDefault {
		ctx.WriteString(" ")
		ctx.WriteString(node.DropBehavior.String())
	}
}

// SQLRight Code Injection.
func (node *DropOwnedBy) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "DROP OWNED BY "

	roleNode := node.Roles.LogCurrentNode(depth+1, ContextUse)

	var pDropBehaviorNode *SQLRightIR
	if node.DropBehavior != DropDefault {
		dropBehaviorNode := &SQLRightIR{
			NodeHash: 180033,
			IRType:   TypeDropBehavior,
			DataType: DataNone,
			Prefix:   node.DropBehavior.String(),
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		pDropBehaviorNode = dropBehaviorNode
	}

	rootIR := &SQLRightIR{
		NodeHash: 53849,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    roleNode,
		RNode:    pDropBehaviorNode,
		Prefix:   prefix,
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	rootIR.NodeHash = 168675
	rootIR.IRType = TypeDropOwnedBy

	return rootIR
}
