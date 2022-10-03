// Copyright 2017 The Cockroach Authors.
//
// Use of this software is governed by the Business Source License
// included in the file licenses/BSL.txt.
//
// As of the Change Date specified in that file, in accordance with
// the Business Source License, use of this software will be governed
// by the Apache License, Version 2.0, included in the file
// licenses/APL.txt.

package tree

// AlterIndex represents an ALTER INDEX statement.
type AlterIndex struct {
	IfExists bool
	Index    TableIndexName
	Cmds     AlterIndexCmds
}

var _ Statement = &AlterIndex{}

// Format implements the NodeFormatter interface.
func (node *AlterIndex) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER INDEX ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(&node.Index)
	ctx.FormatNode(&node.Cmds)
}

// SQLRight Code Injection.
func (node *AlterIndex) LogCurrentNode(depth int) *SQLRightIR {

	tmpStr := ""
	if node.IfExists {
		tmpStr = "IF EXISTS "
	}
	tmpNode := &SQLRightIR{
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: tmpStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	LNode := tmpNode
	RNode := node.Index.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "ALTER INDEX ",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	RNode = node.Cmds.LogCurrentNode(depth + 1)

	rootIR = &SQLRightIR{
		IRType:   TypeAlterIndex,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    RNode,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterIndexCmds represents a list of index alterations.
type AlterIndexCmds []AlterIndexCmd

// Format implements the NodeFormatter interface.
func (node *AlterIndexCmds) Format(ctx *FmtCtx) {
	for i, n := range *node {
		if i > 0 {
			ctx.WriteString(",")
		}
		ctx.FormatNode(n)
	}
}

// SQLRight Code Injection.
func (node *AlterIndexCmds) LogCurrentNode(depth int) *SQLRightIR {

	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{}
	for i, n := range *node {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n.LogCurrentNode(depth + 1)
			var RNode *SQLRightIR
			infix := ""
			if len(*node) >= 2 {
				RNode = (*node)[1].LogCurrentNode(depth + 1)
				infix = ", "
			}
			tmpIR = &SQLRightIR{
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
			RNode := n.LogCurrentNode(depth + 1)

			tmpIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    tmpIR,
				RNode:    RNode,
				Prefix:   "",
				Infix:    ", ",
				Suffix:   "",
				Depth:    depth,
			}
		}
	}

	// Only flag the root node for the type.
	tmpIR.IRType = TypeAlterIndexCmds
	return tmpIR
}

// AlterIndexCmd represents an index modification operation.
type AlterIndexCmd interface {
	NodeFormatter
	// Placeholder function to ensure that only desired types
	// (AlterIndex*) conform to the AlterIndexCmd interface.
	alterIndexCmd()
	SQLRightInterface
}

func (*AlterIndexPartitionBy) alterIndexCmd() {}

var _ AlterIndexCmd = &AlterIndexPartitionBy{}

// AlterIndexPartitionBy represents an ALTER INDEX PARTITION BY
// command.
type AlterIndexPartitionBy struct {
	*PartitionByIndex
}

// Format implements the NodeFormatter interface.
func (node *AlterIndexPartitionBy) Format(ctx *FmtCtx) {
	ctx.FormatNode(node.PartitionByIndex)
}

// SQLRight Code Injection.
func (node *AlterIndexPartitionBy) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.PartitionByIndex.LogCurrentNode(depth + 1)
	rootIR := &SQLRightIR{
		IRType:   TypeAlterIndexPartitionBy,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: "",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// AlterIndexVisible represents a ALTER INDEX ... [VISIBLE | NOT VISIBLE] statement.
type AlterIndexVisible struct {
	Index      TableIndexName
	NotVisible bool
	IfExists   bool
}

var _ Statement = &AlterIndexVisible{}

// Format implements the NodeFormatter interface.
func (node *AlterIndexVisible) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER INDEX ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(&node.Index)
	if node.NotVisible {
		ctx.WriteString(" NOT VISIBLE")
	} else {
		ctx.WriteString(" VISIBLE")
	}
}

// SQLRight Code Injection.
func (node *AlterIndexVisible) LogCurrentNode(depth int) *SQLRightIR {

	tmpStr := ""
	if node.IfExists {
		tmpStr = "IF EXISTS "
	}
	tmpNode := &SQLRightIR{
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: tmpStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}
	LNode := tmpNode

	infix := " VISIBLE"
	if node.NotVisible {
		infix = " NOT VISIBLE"
	}

	rootIR := &SQLRightIR{
		IRType:   TypeAlterIndexVisible,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: "ALTER INDEX",
		Infix:  infix,
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}
