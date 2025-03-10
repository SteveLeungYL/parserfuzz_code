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

// Analyze represents an ANALYZE statement.
type Analyze struct {
	Table TableExpr
}

// Format implements the NodeFormatter interface.
func (node *Analyze) Format(ctx *FmtCtx) {
	ctx.WriteString("ANALYZE ")
	ctx.FormatNode(node.Table)
}

// SQLRight Code Injection.
func (node *Analyze) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ANALYZE "

	tableExprNode := node.Table.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		NodeHash: 93771,
		IRType:   TypeAnalyze,
		DataType: DataNone,
		LNode:    tableExprNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR

}
