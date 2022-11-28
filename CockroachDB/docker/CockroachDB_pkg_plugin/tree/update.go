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

// Update represents an UPDATE statement.
type Update struct {
	With      *With
	Table     TableExpr
	Exprs     UpdateExprs
	From      TableExprs
	Where     *Where
	OrderBy   OrderBy
	Limit     *Limit
	Returning ReturningClause
}

// Format implements the NodeFormatter interface.
func (node *Update) Format(ctx *FmtCtx) {
	ctx.FormatNode(node.With)
	ctx.WriteString("UPDATE ")
	ctx.FormatNode(node.Table)
	ctx.WriteString(" SET ")
	ctx.FormatNode(&node.Exprs)
	if len(node.From) > 0 {
		ctx.WriteString(" FROM ")
		ctx.FormatNode(&node.From)
	}
	if node.Where != nil {
		ctx.WriteByte(' ')
		ctx.FormatNode(node.Where)
	}
	if len(node.OrderBy) > 0 {
		ctx.WriteByte(' ')
		ctx.FormatNode(&node.OrderBy)
	}
	if node.Limit != nil {
		ctx.WriteByte(' ')
		ctx.FormatNode(node.Limit)
	}
	if HasReturningClause(node.Returning) {
		ctx.WriteByte(' ')
		ctx.FormatNode(node.Returning)
	}
}

// SQLRight Code Injection.
func (node *Update) LogCurrentNode(depth int) *SQLRightIR {

	withNode := node.With.LogCurrentNode(depth + 1)

	infix := "UPDATE "

	tableNode := node.Table.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    withNode,
		RNode:    tableNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	infix = " SET "

	exprsNode := node.Exprs.LogCurrentNode(depth + 1)

	rootIR = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    exprsNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	if len(node.From) > 0 {
		infix = " FROM "
		fromNode := node.From.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    fromNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.Where != nil {
		infix = " "
		whereNode := node.Where.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    whereNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if len(node.OrderBy) > 0 {
		infix = " "
		orderByNode := node.OrderBy.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    orderByNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}
	if node.Limit != nil {
		infix = " "
		limitNode := node.Limit.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    limitNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if HasReturningClause(node.Returning) {

		infix = " "
		returnningNode := node.Returning.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    returnningNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeUpdate

	return rootIR
}

// UpdateExprs represents a list of update expressions.
type UpdateExprs []*UpdateExpr

// Format implements the NodeFormatter interface.
func (node *UpdateExprs) Format(ctx *FmtCtx) {
	for i, n := range *node {
		if i > 0 {
			ctx.WriteString(", ")
		}
		ctx.FormatNode(n)
	}
}

// SQLRight Code Injection.
func (node *UpdateExprs) LogCurrentNode(depth int) *SQLRightIR {

	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{}
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
	tmpIR.IRType = TypeUpdateExprs
	return tmpIR
}

// UpdateExpr represents an update expression.
type UpdateExpr struct {
	Tuple bool
	Names NameList
	Expr  Expr
}

// Format implements the NodeFormatter interface.
func (node *UpdateExpr) Format(ctx *FmtCtx) {
	open, close := "", ""
	if node.Tuple {
		open, close = "(", ")"
	}
	ctx.WriteString(open)
	ctx.FormatNode(&node.Names)
	ctx.WriteString(close)
	ctx.WriteString(" = ")
	ctx.FormatNode(node.Expr)
}

// SQLRight Code Injection.
func (node *UpdateExpr) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""
	infix := ""

	if node.Tuple {
		prefix = "("
		infix = ")"
	}

	nameNode := node.Names.LogCurrentNodeWithType(depth+1, DataColumnName)

	infix += " = "

	exprNode := node.Expr.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeUpdateExpr,
		DataType: DataNone,
		LNode:    nameNode,
		RNode:    exprNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}
