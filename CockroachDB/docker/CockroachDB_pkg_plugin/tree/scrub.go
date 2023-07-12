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

import "fmt"

// ScrubType describes the SCRUB statement operation.
type ScrubType int

const (
	// ScrubTable describes the SCRUB operation SCRUB TABLE.
	ScrubTable = iota
	// ScrubDatabase describes the SCRUB operation SCRUB DATABASE.
	ScrubDatabase = iota
)

// Scrub represents a SCRUB statement.
type Scrub struct {
	Typ     ScrubType
	Options ScrubOptions
	// Table is only set during SCRUB TABLE statements.
	Table *UnresolvedObjectName
	// Database is only set during SCRUB DATABASE statements.
	Database Name
	AsOf     AsOfClause
}

// Format implements the NodeFormatter interface.
func (n *Scrub) Format(ctx *FmtCtx) {
	ctx.WriteString("EXPERIMENTAL SCRUB ")
	switch n.Typ {
	case ScrubTable:
		ctx.WriteString("TABLE ")
		ctx.FormatNode(n.Table)
	case ScrubDatabase:
		ctx.WriteString("DATABASE ")
		ctx.FormatNode(&n.Database)
	default:
		panic("Unhandled ScrubType")
	}

	if n.AsOf.Expr != nil {
		ctx.WriteByte(' ')
		ctx.FormatNode(&n.AsOf)
	}

	if len(n.Options) > 0 {
		ctx.WriteString(" WITH OPTIONS ")
		ctx.FormatNode(&n.Options)
	}
}

// SQLRight Code Injection.
func (node *Scrub) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "EXPERIMENTAL SCRUB "

	var nameNode *SQLRightIR

	switch node.Typ {
	case ScrubTable:
		prefix += "TABLE "
		tableNode := &SQLRightIR{
			NodeHash:    145038,
			IRType:      TypeIdentifier,
			DataType:    DataTableName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Table.String(),
		}
		nameNode = tableNode
	case ScrubDatabase:
		prefix += "DATABASE "
		tableNode := &SQLRightIR{
			NodeHash:    230878,
			IRType:      TypeIdentifier,
			DataType:    DataDatabaseName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Database.String(),
		}
		nameNode = tableNode
	default:
		panic("Unhandled ScrubType")
	}

	infix := ""
	var asNode *SQLRightIR
	if node.AsOf.Expr != nil {
		infix += " "
		asNode = node.AsOf.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		NodeHash: 14797,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    nameNode,
		RNode:    asNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	infix = ""
	if len(node.Options) > 0 {
		infix = " WITH OPTIONS "
		optionNode := node.Options.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			NodeHash: 5909,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optionNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.NodeHash = 49143
	rootIR.IRType = TypeScrub

	return rootIR
}

// ScrubOptions corresponds to a comma-delimited list of scrub options.
type ScrubOptions []ScrubOption

// Format implements the NodeFormatter interface.
func (n *ScrubOptions) Format(ctx *FmtCtx) {
	for i, option := range *n {
		if i > 0 {
			ctx.WriteString(", ")
		}
		ctx.FormatNode(option)
	}
}

// SQLRight Code Injection.
func (node *ScrubOptions) LogCurrentNode(depth int) *SQLRightIR {
	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{
		NodeHash: 46948}
	for i, n := range *node {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n.LogCurrentNode(depth + 1)
			var RNode *SQLRightIR
			infix := ""
			if len(*node) >= 2 {
				infix = ", "
				RNode = (*node)[1].LogCurrentNode(depth + 1)
			}
			tmpIR = &SQLRightIR{
				NodeHash: 158458,
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
			LNode := tmpIR
			RNode := n.LogCurrentNode(depth + 1)

			tmpIR = &SQLRightIR{
				NodeHash: 95275,
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

	// Only flag the root node for the type.
	rootIR.NodeHash = 145137
	tmpIR.IRType = TypeScrubOptions
	return tmpIR
}

func (n *ScrubOptions) String() string { return AsString(n) }

// ScrubOption represents a scrub option.
type ScrubOption interface {
	fmt.Stringer
	NodeFormatter

	scrubOptionType()
	SQLRightInterface
}

// scrubOptionType implements the ScrubOption interface
func (*ScrubOptionIndex) scrubOptionType()      {}
func (*ScrubOptionPhysical) scrubOptionType()   {}
func (*ScrubOptionConstraint) scrubOptionType() {}

func (n *ScrubOptionIndex) String() string      { return AsString(n) }
func (n *ScrubOptionPhysical) String() string   { return AsString(n) }
func (n *ScrubOptionConstraint) String() string { return AsString(n) }

// ScrubOptionIndex represents an INDEX scrub check.
type ScrubOptionIndex struct {
	IndexNames NameList
}

// Format implements the NodeFormatter interface.
func (n *ScrubOptionIndex) Format(ctx *FmtCtx) {
	ctx.WriteString("INDEX ")
	if n.IndexNames != nil {
		ctx.WriteByte('(')
		ctx.FormatNode(&n.IndexNames)
		ctx.WriteByte(')')
	} else {
		ctx.WriteString("ALL")
	}
}

// SQLRight Code Injection.
func (node *ScrubOptionIndex) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "INDEX "

	if node.IndexNames != nil {
		prefix += "("
		indexNameNode := node.IndexNames.LogCurrentNodeWithType(depth+1, DataIndexName)
		infix := ")"

		rootIR := &SQLRightIR{
			NodeHash: 97748,
			IRType:   TypeScrubOptionIndex,
			DataType: DataNone,
			LNode:    indexNameNode,
			Prefix:   prefix,
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}

		return rootIR
	} else {
		prefix += "ALL "

		rootIR := &SQLRightIR{
			NodeHash: 111849,
			IRType:   TypeScrubOptionIndex,
			DataType: DataNone,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		return rootIR
	}
}

// ScrubOptionPhysical represents a PHYSICAL scrub check.
type ScrubOptionPhysical struct{}

// Format implements the NodeFormatter interface.
func (n *ScrubOptionPhysical) Format(ctx *FmtCtx) {
	ctx.WriteString("PHYSICAL")
}

// SQLRight Code Injection.
func (node *ScrubOptionPhysical) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "PHYSICAL"

	rootIR := &SQLRightIR{
		NodeHash: 108903,
		IRType:   TypeScrubOptionPhysical,
		DataType: DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ScrubOptionConstraint represents a CONSTRAINT scrub check.
type ScrubOptionConstraint struct {
	ConstraintNames NameList
}

// Format implements the NodeFormatter interface.
func (n *ScrubOptionConstraint) Format(ctx *FmtCtx) {
	ctx.WriteString("CONSTRAINT ")
	if n.ConstraintNames != nil {
		ctx.WriteByte('(')
		ctx.FormatNode(&n.ConstraintNames)
		ctx.WriteByte(')')
	} else {
		ctx.WriteString("ALL")
	}
}

// SQLRight Code Injection.
func (node *ScrubOptionConstraint) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "CONSTRAINT "

	if node.ConstraintNames != nil {
		prefix += "("

		constraintNode := node.ConstraintNames.LogCurrentNodeWithType(depth+1, DataConstraintName)

		infix := ")"

		rootIR := &SQLRightIR{
			NodeHash: 56631,
			IRType:   TypeScrubOptionConstraint,
			DataType: DataNone,
			LNode:    constraintNode,
			Prefix:   prefix,
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
		return rootIR

	} else {
		prefix += " ALL "
		rootIR := &SQLRightIR{
			NodeHash: 137845,
			IRType:   TypeScrubOptionConstraint,
			DataType: DataNone,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		return rootIR
	}

}
