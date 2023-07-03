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

import "github.com/cockroachdb/cockroach/pkg/sql/sem/catid"

// ID is a custom type for {Database,Table}Descriptor IDs.
type ID = catid.ColumnID

// ColumnID is a custom type for ColumnDescriptor IDs.
type ColumnID = catid.ColumnID

// TableRef represents a numeric table reference.
// (Syntax !NNN in SQL.)
type TableRef struct {
	// TableID is the descriptor ID of the requested table.
	TableID int64

	// ColumnIDs is the list of column IDs requested in the table.
	// Note that a nil array here means "unspecified" (all columns)
	// whereas an array of length 0 means "zero columns".
	// Lists of zero columns are not supported and will throw an error.
	Columns []ColumnID

	// As determines the names that can be used in the surrounding query
	// to refer to this source.
	As AliasClause
}

// Format implements the NodeFormatter interface.
func (n *TableRef) Format(ctx *FmtCtx) {
	ctx.Printf("[%d", n.TableID)
	if n.Columns != nil {
		ctx.WriteByte('(')
		for i, c := range n.Columns {
			if i > 0 {
				ctx.WriteString(", ")
			}
			ctx.Printf("%d", c)
		}
		ctx.WriteByte(')')
	}
	if n.As.Alias != "" {
		ctx.WriteString(" AS ")
		ctx.FormatNode(&n.As)
	}
	ctx.WriteByte(']')
}

func (node *TableRef) LogCurrentNodeHelper(depth int, tableID int64) *SQLRightIR {
	tableNode := &SQLRightIR{
		NodeHash:     50896,
		IRType:       TypeIntegerLiteral,
		DataType:     DataLiteral,
		DataAffinity: AFFIINT,
		Prefix:       "",
		Infix:        "",
		Suffix:       "",
		Depth:        depth,
		IValue:       tableID,
	}

	return tableNode
}

// SQLRight Code Injection.
func (node *TableRef) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "["
	tableIDNode := &SQLRightIR{
		NodeHash:     167616,
		IRType:       TypeIntegerLiteral,
		DataType:     DataLiteral, // TODO: FIXME: Data type unknown.
		DataAffinity: AFFIINT,
		Prefix:       "",
		Infix:        "",
		Suffix:       "",
		Depth:        depth,
		IValue:       node.TableID,
	}

	var tmpRootIR *SQLRightIR
	if node.Columns != nil {
		var tmpIR *SQLRightIR
		for i, n := range node.Columns {
			if i == 0 {
				// Take care of the first two nodes.
				LNode := node.LogCurrentNodeHelper(depth+1, int64(n))
				var RNode *SQLRightIR
				if len(node.Columns) >= 2 {
					RNode = node.LogCurrentNodeHelper(depth+1, int64((node.Columns)[1]))
				}
				tmpIR = &SQLRightIR{
					NodeHash: 240946,
					IRType:   TypeUnknown,
					DataType: DataNone,
					LNode:    LNode,
					RNode:    RNode,
					Prefix:   "",
					Infix:    " ",
					Suffix:   "",
					Depth:    depth,
				}
				tmpRootIR = tmpIR
			} else if i == 1 {
				// The first two element would be saved in the same IR node.
				continue
			} else {
				// i >= 2. Begins from the third element.
				// Left node is the previous cmds.
				// Right node is the new cmd.
				LNode := tmpIR
				RNode := node.LogCurrentNodeHelper(depth+1, int64(n))

				tmpIR = &SQLRightIR{
					NodeHash: 11895,
					IRType:   TypeUnknown,
					DataType: DataNone,
					LNode:    LNode,
					RNode:    RNode,
					Prefix:   "",
					Infix:    " ",
					Suffix:   "",
					Depth:    depth,
				}
				tmpRootIR = tmpIR
			}
		}
	}

	rootIR := &SQLRightIR{
		NodeHash: 202610,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    tableIDNode,
		RNode:    tmpRootIR,
		Prefix:   prefix,
		Infix:    "(",
		Suffix:   ")",
		Depth:    depth,
		Str:      node.String(),
	}

	if node.As.Alias != "" {
		infix := " AS "
		asNode := node.As.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			NodeHash: 141734,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    asNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.Suffix = "]"
	rootIR.IRType = TypeTableRef

	return rootIR
}

func (n *TableRef) String() string { return AsString(n) }

// tableExpr implements the TableExpr interface.
func (n *TableRef) tableExpr() {}
