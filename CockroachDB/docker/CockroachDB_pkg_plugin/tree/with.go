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

// With represents a WITH statement.
type With struct {
	Recursive bool
	CTEList   []*CTE
}

// CTE represents a common table expression inside of a WITH clause.
type CTE struct {
	Name AliasClause
	Mtr  MaterializeClause
	Stmt Statement
}

// MaterializeClause represents a materialize clause inside of a WITH clause.
type MaterializeClause struct {
	// Set controls whether to use the Materialize bool instead of the default.
	Set bool

	// Materialize overrides the default materialization behavior.
	Materialize bool
}

// Format implements the NodeFormatter interface.
func (node *With) Format(ctx *FmtCtx) {
	if node == nil {
		return
	}
	ctx.WriteString("WITH ")
	if node.Recursive {
		ctx.WriteString("RECURSIVE ")
	}
	for i, cte := range node.CTEList {
		if i != 0 {
			ctx.WriteString(", ")
		}
		ctx.FormatNode(&cte.Name)
		ctx.WriteString(" AS ")
		if cte.Mtr.Set {
			if !cte.Mtr.Materialize {
				ctx.WriteString("NOT ")
			}
			ctx.WriteString("MATERIALIZED ")
		}
		ctx.WriteString("(")
		ctx.FormatNode(cte.Stmt)
		ctx.WriteString(")")
	}
	ctx.WriteByte(' ')
}

// SQLRight Code Injection.
func (node *With) LogCurrentNode(depth int) *SQLRightIR {

	var rootIR *SQLRightIR
	if node == nil {
		rootIR = &SQLRightIR{
			NodeHash: 252219,
			IRType:   TypeWith,
			DataType: DataNone,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		return rootIR
	}

	prefix := "WITH "
	recursiveStr := ""
	if node.Recursive {
		recursiveStr = "RECURSIVE"
	}
	optRecursiveNode := &SQLRightIR{
		NodeHash: 22948,
		IRType:   TypeOptRecursive,
		DataType: DataNone,
		Prefix:   recursiveStr,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	rootIR = &SQLRightIR{
		NodeHash: 227520,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    optRecursiveNode,
		Prefix:   prefix,
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	var cteList []*SQLRightIR

	for _, cte := range node.CTEList {
		nameNode := cte.Name.LogCurrentNode(depth + 1)
		infix := " AS "

		materializeStr := ""
		if cte.Mtr.Set {
			if !cte.Mtr.Materialize {
				materializeStr = "NOT "
			}
			materializeStr += "MATERIALIZED "
		}
		materializeNode := &SQLRightIR{
			NodeHash: 228549,
			IRType:   TypeOptMaterialized,
			DataType: DataNone,
			Prefix:   materializeStr,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		cteClusterNode := &SQLRightIR{
			NodeHash: 121625,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    nameNode,
			RNode:    materializeNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}

		stmtNode := cte.Stmt.LogCurrentNode(depth + 1)

		cteClusterNode = &SQLRightIR{
			NodeHash: 118858,
			IRType:   TypeCTECluster,
			DataType: DataNone,
			LNode:    cteClusterNode,
			RNode:    stmtNode,
			Prefix:   "",
			Infix:    "(",
			Suffix:   ")",
			Depth:    depth,
		}
		cteList = append(cteList, cteClusterNode)
	}

	for i, n := range cteList {
		infix := ""
		if i != 0 {
			infix = ", "
		}
		rootIR = &SQLRightIR{
			NodeHash: 259037,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    n,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.Suffix = " "
	rootIR.NodeHash = 106330
	rootIR.IRType = TypeWith

	return rootIR

}
