// Copyright 2016 The Cockroach Authors.
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

// Table patterns are used by e.g. GRANT statements, to designate
// zero, one or more table names.  For example:
//   GRANT ... ON foo ...
//   GRANT ... ON * ...
//   GRANT ... ON db.*  ...
//
// The other syntax nodes hold a TablePattern reference.  This is
// initially populated during parsing with an UnresolvedName, which
// can be transformed to either a TableName (single name) or
// AllTablesSelector instance (all tables of a given database) using
// NormalizeTablePattern().

// TablePattern is the common interface to UnresolvedName, TableName
// and AllTablesSelector.
type TablePattern interface {
	fmt.Stringer
	NodeFormatter

	SQLRightInterface

	// NormalizeTablePattern() guarantees to return a pattern that is
	// not an UnresolvedName. This converts the UnresolvedName to an
	// AllTablesSelector or TableName as necessary.
	NormalizeTablePattern() (TablePattern, error)
}

var _ TablePattern = &UnresolvedName{}
var _ TablePattern = &TableName{}
var _ TablePattern = &AllTablesSelector{}

// NormalizeTablePattern resolves an UnresolvedName to either a
// TableName or AllTablesSelector.
func (n *UnresolvedName) NormalizeTablePattern() (TablePattern, error) {
	return classifyTablePattern(n)
}

// NormalizeTablePattern implements the TablePattern interface.
func (t *TableName) NormalizeTablePattern() (TablePattern, error) { return t, nil }

// AllTablesSelector corresponds to a selection of all
// tables in a database, e.g. when used with GRANT.
type AllTablesSelector struct {
	ObjectNamePrefix
}

// Format implements the NodeFormatter interface.
func (at *AllTablesSelector) Format(ctx *FmtCtx) {
	at.ObjectNamePrefix.Format(ctx)
	if at.ExplicitSchema || ctx.alwaysFormatTablePrefix() {
		ctx.WriteByte('.')
	}
	ctx.WriteByte('*')
}

// SQLRight Code Injection.
func (node *AllTablesSelector) LogCurrentNode(depth int) *SQLRightIR {

	objectNode := node.ObjectNamePrefix.LogCurrentNode(depth + 1)

	infix := ""
	if node.ExplicitSchema {
		infix += "."
	}
	infix += "*"

	rootIR := &SQLRightIR{
		NodeHash: 77181,
		IRType:   TypeAllTablesSelector,
		DataType: DataNone,
		LNode:    objectNode,
		//RNode:    RNode,
		Prefix: "",
		Infix:  infix,
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

func (at *AllTablesSelector) String() string { return AsString(at) }

// NormalizeTablePattern implements the TablePattern interface.
func (at *AllTablesSelector) NormalizeTablePattern() (TablePattern, error) { return at, nil }

// TablePatterns implement a comma-separated list of table patterns.
// Used by e.g. the GRANT statement.
type TablePatterns []TablePattern

// TableAttrs saves the table petterns and a bool field SequenceOnly that shows
// if all tables are sequences.
type TableAttrs struct {
	SequenceOnly  bool
	TablePatterns TablePatterns
}

// Format implements the NodeFormatter interface.
func (tt *TablePatterns) Format(ctx *FmtCtx) {
	for i, t := range *tt {
		if i > 0 {
			ctx.WriteString(", ")
		}
		ctx.FormatNode(t)
	}
}

// SQLRight Code Injection.
func (node *TablePatterns) LogCurrentNode(depth int) *SQLRightIR {

	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{
		NodeHash: 156567}
	for i, n := range *node {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n.LogCurrentNode(depth + 1)
			var RNode *SQLRightIR
			infix := " "
			if len(*node) >= 2 {
				infix = ", "
				RNode = (*node)[1].LogCurrentNode(depth + 1)
			}
			tmpIR = &SQLRightIR{
				NodeHash: 129468,
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
				NodeHash: 154692,
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
	tmpIR.NodeHash = 193928
	tmpIR.IRType = TypeTablePatterns
	return tmpIR

}
