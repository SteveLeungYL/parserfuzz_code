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

import (
	"github.com/cockroachdb/cockroach/pkg/sql/lexbase"
)

// Prepare represents a PREPARE statement.
type Prepare struct {
	Name      Name
	Types     []ResolvableTypeReference
	Statement Statement
}

// Format implements the NodeFormatter interface.
func (node *Prepare) Format(ctx *FmtCtx) {
	ctx.WriteString("PREPARE ")
	ctx.FormatNode(&node.Name)
	if len(node.Types) > 0 {
		ctx.WriteString(" (")
		for i, t := range node.Types {
			if i > 0 {
				ctx.WriteString(", ")
			}
			ctx.WriteString(t.SQLString())
		}
		ctx.WriteRune(')')
	}
	ctx.WriteString(" AS ")
	ctx.FormatNode(node.Statement)
}

// SQLRight Code Injection.
func (node *Prepare) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "PREPARE "

	nameNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataStatementPreparedName,
		ContextFlag: ContextDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Name.String(),
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    nameNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	var typeList []*SQLRightIR
	if len(node.Types) > 0 {
		for _, t := range node.Types {
			typeNode := &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataTypeName,
				ContextFlag: ContextUse,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         t.SQLString(),
			}
			typeList = append(typeList, typeNode)
		}
	}

	var curTypeListRoot *SQLRightIR
	for i, n := range typeList {
		if i == 0 {
			// Take care of the first two nodes.
			LNode := n
			var RNode *SQLRightIR
			infix := ""
			if len(typeList) >= 2 {
				infix = ", "
				tmpRNode := typeList[1]
				RNode = tmpRNode
			}
			curTypeListRoot = &SQLRightIR{
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
			LNode := curTypeListRoot
			RNode := n

			curTypeListRoot = &SQLRightIR{
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
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    curTypeListRoot,
		Prefix:   "",
		Infix:    "(",
		Suffix:   ")",
		Depth:    depth,
	}

	statementNode := node.Statement.LogCurrentNode(depth + 1)

	rootIR = &SQLRightIR{
		IRType:   TypePrepare,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    statementNode,
		Prefix:   "",
		Infix:    " AS ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// CannedOptPlan is used as the AST for a PREPARE .. AS OPT PLAN statement.
// This is a testing facility that allows execution (and benchmarking) of
// specific plans. See exprgen package for more information on the syntax.
type CannedOptPlan struct {
	Plan string
}

// Format implements the NodeFormatter interface.
func (node *CannedOptPlan) Format(ctx *FmtCtx) {
	// This node can only be used as the AST for a Prepare statement of the form:
	//   PREPARE name AS OPT PLAN '...').
	ctx.WriteString("OPT PLAN ")
	ctx.WriteString(lexbase.EscapeSQLString(node.Plan))
}

// SQLRight Code Injection.
func (node *CannedOptPlan) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "OPT PLAN "
	prefix += lexbase.EscapeSQLString(node.Plan)

	rootIR := &SQLRightIR{
		IRType:   TypeCannedOptPlan,
		DataType: DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// Execute represents an EXECUTE statement.
type Execute struct {
	Name   Name
	Params Exprs
	// DiscardRows is set when we want to throw away all the rows rather than
	// returning for client (used for testing and benchmarking).
	DiscardRows bool
}

// Format implements the NodeFormatter interface.
func (node *Execute) Format(ctx *FmtCtx) {
	ctx.WriteString("EXECUTE ")
	ctx.FormatNode(&node.Name)
	if len(node.Params) > 0 {
		ctx.WriteString(" (")
		ctx.FormatNode(&node.Params)
		ctx.WriteByte(')')
	}
	if node.DiscardRows {
		ctx.WriteString(" DISCARD ROWS")
	}
}

// SQLRight Code Injection.
func (node *Execute) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "EXECUTE "

	nameNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataStatementPreparedName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Name.String(),
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    nameNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	var paramList []*SQLRightIR
	if len(node.Params) > 0 {
		for _, t := range node.Params {
			exprNode := t.LogCurrentNode(depth + 1)
			paramList = append(paramList, exprNode)
		}
	}

	var curParamListRoot *SQLRightIR
	for i, n := range paramList {
		if i == 0 {
			// Take care of the first two nodes.
			LNode := n
			var RNode *SQLRightIR
			infix := ""
			if len(paramList) >= 2 {
				infix = " "
				RNode = paramList[1]
			}
			curParamListRoot = &SQLRightIR{
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
			LNode := curParamListRoot
			RNode := n

			curParamListRoot = &SQLRightIR{
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

	rootIR = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    curParamListRoot,
		Prefix:   "",
		Infix:    "(",
		Suffix:   ")",
		Depth:    depth,
	}

	var optDiscardRows *SQLRightIR
	if node.DiscardRows {
		optDiscardRows = &SQLRightIR{
			IRType:   TypeOptDiscardRows,
			DataType: DataNone,
			Prefix:   " DISCARD ROWS",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	} else {
		optDiscardRows = &SQLRightIR{
			IRType:   TypeOptDiscardRows,
			DataType: DataNone,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR = &SQLRightIR{
		IRType:   TypeExecute,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    optDiscardRows,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// Deallocate represents a DEALLOCATE statement.
type Deallocate struct {
	Name Name // empty for ALL
}

// Format implements the NodeFormatter interface.
func (node *Deallocate) Format(ctx *FmtCtx) {
	ctx.WriteString("DEALLOCATE ")
	if node.Name == "" {
		ctx.WriteString("ALL")
	} else {
		// Special case for names in DEALLOCATE: the names are redacted in
		// FmtHideConstants mode so that DEALLOCATE statements all show up together
		// in the statement stats UI. The reason is that unlike other statements
		// where the name being referenced is useful for observability, the name of
		// a prepared statement doesn't matter that much. Also, it's extremely cheap
		// to run DEALLOCATE, which can lead to thousands or more DEALLOCATE
		// statements appearing in the UI; other statements that refer to things by
		// name are too expensive for that to be a real problem.
		if ctx.HasFlags(FmtHideConstants) {
			ctx.WriteByte('_')
		} else {
			ctx.FormatNode(&node.Name)
		}
	}
}

// SQLRight Code Injection.
func (node *Deallocate) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "DEALLOCATE "

	if node.Name == "" {
		prefix += "ALL "

		rootIR := &SQLRightIR{
			IRType:   TypeDeallocate,
			DataType: DataNone,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		return rootIR
	}

	nameNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataStatementPreparedName,
		ContextFlag: ContextUndefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Name.String(),
	}

	rootIR := &SQLRightIR{
		IRType:   TypeDeallocate,
		DataType: DataNone,
		LNode:    nameNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}
