// Copyright 2022 The Cockroach Authors.
//
// Use of this software is governed by the Business Source License
// included in the file licenses/BSL.txt.
//
// As of the Change Date specified in that file, in accordance with
// the Business Source License, use of this software will be governed
// by the Apache License, Version 2.0, included in the file
// licenses/APL.txt.

package tree

// AlterChangefeed represents an ALTER CHANGEFEED statement.
type AlterChangefeed struct {
	Jobs Expr
	Cmds AlterChangefeedCmds
}

var _ Statement = &AlterChangefeed{}

// Format implements the NodeFormatter interface.
func (node *AlterChangefeed) Format(ctx *FmtCtx) {
	ctx.WriteString(`ALTER CHANGEFEED `)
	ctx.FormatNode(node.Jobs)
	ctx.FormatNode(&node.Cmds)
}

// SQLRight Code Injection.
func (node *AlterChangefeed) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.Jobs.LogCurrentNode(depth + 1)
	RNode := node.Cmds.LogCurrentNode(depth + 1)
	rootIR := &SQLRightIR{
		IRType:   TypeAlterChangeFeed,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "ALTER CHANGEFEED ",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterChangefeedCmds represents a list of changefeed alterations
type AlterChangefeedCmds []AlterChangefeedCmd

// Format implements the NodeFormatter interface.
func (node *AlterChangefeedCmds) Format(ctx *FmtCtx) {
	for i, n := range *node {
		if i > 0 {
			ctx.WriteString(" ")
		}
		ctx.FormatNode(n)
	}
}

// SQLRight Code Injection.
func (node *AlterChangefeedCmds) LogCurrentNode(depth int) *SQLRightIR {

	// TODO: FIXME. The depth is not handling correctly. All TypeAlterChangefeedCmds are in the same depth.

	tmpIR := &SQLRightIR{}
	for i, n := range *node {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n.LogCurrentNode(depth + 1)
			var RNode *SQLRightIR
			if len(*node) >= 2 {
				RNode = (*node)[1].LogCurrentNode(depth + 1)
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
				Infix:    " ",
				Suffix:   "",
				Depth:    depth,
			}
		}
	}

	// Only flag the root node for the type.
	tmpIR.IRType = TypeAlterChangefeedCmds
	return tmpIR
}

// AlterChangefeedCmd represents a changefeed modification operation.
type AlterChangefeedCmd interface {
	NodeFormatter
	SQLRightInterface
	// Placeholder function to ensure that only desired types
	// (AlterChangefeed*) conform to the AlterChangefeedCmd interface.
	alterChangefeedCmd()
}

func (*AlterChangefeedAddTarget) alterChangefeedCmd()    {}
func (*AlterChangefeedDropTarget) alterChangefeedCmd()   {}
func (*AlterChangefeedSetOptions) alterChangefeedCmd()   {}
func (*AlterChangefeedUnsetOptions) alterChangefeedCmd() {}

var _ AlterChangefeedCmd = &AlterChangefeedAddTarget{}
var _ AlterChangefeedCmd = &AlterChangefeedDropTarget{}
var _ AlterChangefeedCmd = &AlterChangefeedSetOptions{}
var _ AlterChangefeedCmd = &AlterChangefeedUnsetOptions{}

// AlterChangefeedAddTarget represents an ADD <targets> command
type AlterChangefeedAddTarget struct {
	Targets ChangefeedTargets
	Options KVOptions
}

// Format implements the NodeFormatter interface.
func (node *AlterChangefeedAddTarget) Format(ctx *FmtCtx) {
	ctx.WriteString(" ADD ")
	ctx.FormatNode(&node.Targets)
	if node.Options != nil {
		ctx.WriteString(" WITH ")
		ctx.FormatNode(&node.Options)
	}
}

// SQLRight Code Injection.
func (node *AlterChangefeedAddTarget) LogCurrentNode(depth int) *SQLRightIR {

	// Setup the Datatype for the key = value pairs.
	for _, n := range node.Options {
		n.DataType = DataChangeFeed
	}

	LNode := node.Targets.LogCurrentNode(depth + 1)
	var RNode *SQLRightIR
	if node.Options != nil {
		RNode = node.Options.LogCurrentNode(depth + 1)
	}
	rootIR := &SQLRightIR{
		IRType:   TypeAlterChangefeedAddTarget,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   " ADD ",
		Infix:    " WITH ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterChangefeedDropTarget represents an DROP <targets> command
type AlterChangefeedDropTarget struct {
	Targets ChangefeedTargets
}

// Format implements the NodeFormatter interface.
func (node *AlterChangefeedDropTarget) Format(ctx *FmtCtx) {
	ctx.WriteString(" DROP ")
	ctx.FormatNode(&node.Targets)
}

// SQLRight Code Injection.
func (node *AlterChangefeedDropTarget) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.Targets.LogCurrentNode(depth + 1)
	rootIR := &SQLRightIR{
		IRType:   TypeAlterChangefeedDropTarget,
		DataType: DataNone,
		LNode:    LNode,
		//		RNode:    RNode,
		Prefix: " DROP ",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// AlterChangefeedSetOptions represents an SET <options> command
type AlterChangefeedSetOptions struct {
	Options KVOptions
}

// Format implements the NodeFormatter interface.
func (node *AlterChangefeedSetOptions) Format(ctx *FmtCtx) {
	ctx.WriteString(" SET ")
	ctx.FormatNode(&node.Options)
}

// SQLRight Code Injection.
func (node *AlterChangefeedSetOptions) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.Options.LogCurrentNode(depth + 1)
	rootIR := &SQLRightIR{
		IRType:   TypeAlterChangefeedSetOptions,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: " SET ",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// AlterChangefeedUnsetOptions represents an UNSET <options> command
type AlterChangefeedUnsetOptions struct {
	Options NameList
}

// Format implements the NodeFormatter interface.
func (node *AlterChangefeedUnsetOptions) Format(ctx *FmtCtx) {
	ctx.WriteString(" UNSET ")
	ctx.FormatNode(&node.Options)
}

// SQLRight Code Injection.
func (node *AlterChangefeedUnsetOptions) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.Options.LogCurrentNode(depth + 1)
	rootIR := &SQLRightIR{
		IRType:   TypeAlterChangefeedUnsetOptions,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: " UNSET ",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}
