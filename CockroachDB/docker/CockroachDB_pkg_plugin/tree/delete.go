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

// Delete represents a DELETE statement.
type Delete struct {
	With      *With
	Table     TableExpr
	Where     *Where
	OrderBy   OrderBy
	Limit     *Limit
	Returning ReturningClause
}

// Format implements the NodeFormatter interface.
func (node *Delete) Format(ctx *FmtCtx) {
	ctx.FormatNode(node.With)
	ctx.WriteString("DELETE FROM ")
	ctx.FormatNode(node.Table)
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
func (node *Delete) LogCurrentNode(depth int) *SQLRightIR {

	withNode := node.With.LogCurrentNode(depth + 1)
	infix := "DELETE FROM "
	tableNode := node.Table.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		NodeHash: 44726,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    withNode,
		RNode:    tableNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	if node.Where != nil {
		infix = " "
		whereNode := node.Where.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			NodeHash: 132181,
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
		orderByNode := node.OrderBy.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			NodeHash: 133171,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    orderByNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}
	if node.Limit != nil {
		limitNode := node.Limit.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			NodeHash: 35934,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    limitNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}
	if HasReturningClause(node.Returning) {
		returningNode := node.Returning.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			NodeHash: 183148,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    returningNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeDelete

	return rootIR
}
