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

// ValuesClause represents a VALUES clause.
type ValuesClause struct {
	Rows []Exprs
}

// ExprContainer represents an abstract container of Exprs
type ExprContainer interface {
	// NumRows returns number of rows.
	NumRows() int
	// NumCols returns number of columns.
	NumCols() int
	// Get returns the Expr at row i column j.
	Get(i, j int) Expr
}

// RawRows exposes a [][]TypedExpr as an ExprContainer.
type RawRows [][]TypedExpr

var _ ExprContainer = RawRows{}

// NumRows implements the ExprContainer interface.
func (r RawRows) NumRows() int {
	return len(r)
}

// NumCols implements the ExprContainer interface.
func (r RawRows) NumCols() int {
	return len(r[0])
}

// Get implements the ExprContainer interface.
func (r RawRows) Get(i, j int) Expr {
	return r[i][j]
}

// LiteralValuesClause is like ValuesClause but values have been typed checked
// and evaluated and are assumed to be ready to use Datums.
type LiteralValuesClause struct {
	Rows ExprContainer
}

// Format implements the NodeFormatter interface.
func (node *ValuesClause) Format(ctx *FmtCtx) {
	ctx.WriteString("VALUES ")
	comma := ""
	for i := range node.Rows {
		ctx.WriteString(comma)
		ctx.WriteByte('(')
		ctx.FormatNode(&node.Rows[i])
		ctx.WriteByte(')')
		comma = ", "
	}
}

// SQLRight Code Injection.
func (node *ValuesClause) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "VALUES "

	var rootIR *SQLRightIR
	for i, n := range node.Rows {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n.LogCurrentNode(depth + 1)
			var RNode *SQLRightIR
			infix := ""
			if len(node.Rows) >= 2 {
				RNode = node.Rows[1].LogCurrentNode(depth + 1)
				infix = ", "
			}
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   prefix, //Use the prefix once.
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
			RNode := n.LogCurrentNode(depth + 1)

			rootIR = &SQLRightIR{
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

	rootIR.IRType = TypeValuesClause

	return rootIR
}

// Format implements the NodeFormatter interface.
func (node *LiteralValuesClause) Format(ctx *FmtCtx) {
	ctx.WriteString("VALUES ")
	comma := ""
	for i := 0; i < node.Rows.NumRows(); i++ {
		ctx.WriteString(comma)
		ctx.WriteByte('(')
		comma2 := ""
		for j := 0; j < node.Rows.NumCols(); j++ {
			ctx.WriteString(comma2)
			ctx.FormatNode(node.Rows.Get(i, j))
			comma2 = ", "
		}
		ctx.WriteByte(')')
		comma = ", "
	}
}

func (_ LiteralValuesClause) LogCurrentNodeHelper(depth int, node []*SQLRightIR) *SQLRightIR {

	tmpIR := &SQLRightIR{}
	for i, n := range node {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n
			var RNode *SQLRightIR
			infix := ""
			if len(node) >= 2 {
				infix = ", "
				RNode = (node)[1]
			}
			tmpIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   "(",
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
			RNode := n

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

	tmpIR.Suffix = ")"

	// No need to set type name.
	return tmpIR

}

// SQLRight Code Injection.
func (node *LiteralValuesClause) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "VALUES "

	var rowList [][]*SQLRightIR
	for i := 0; i < node.Rows.NumRows(); i++ {
		var tmpArray []*SQLRightIR
		for j := 0; j < node.Rows.NumCols(); j++ {
			curRowNode := node.Rows.Get(i, j).LogCurrentNode(depth + 1)
			tmpArray = append(tmpArray, curRowNode)
		}
		rowList = append(rowList, tmpArray)
	}

	var rootIR *SQLRightIR

	for i, n := range rowList {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := node.LogCurrentNodeHelper(depth+1, n)
			var RNode *SQLRightIR
			infix := ""
			if len(rowList) >= 2 {
				infix = ", "
				RNode = node.LogCurrentNodeHelper(depth+1, (rowList)[1])
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
			RNode := node.LogCurrentNodeHelper(depth+1, n)

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

	rootIR = &SQLRightIR{
		IRType:   TypeLiteralValuesClause,
		DataType: DataNone,
		LNode:    rootIR,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}
