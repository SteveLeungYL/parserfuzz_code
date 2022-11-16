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

import (
	"fmt"
	"github.com/cockroachdb/cockroach/pkg/sql/pgwire/pgcode"
	"github.com/cockroachdb/cockroach/pkg/sql/pgwire/pgerror"
	"github.com/cockroachdb/cockroach/pkg/sql/sem/catid"
	"github.com/cockroachdb/cockroach/pkg/sql/sem/tree/treewindow"
	"github.com/cockroachdb/errors"
	"github.com/cockroachdb/redact"
)

// SelectStatement represents any SELECT statement.
type SelectStatement interface {
	Statement
	selectStatement()
}

func (*ParenSelect) selectStatement()         {}
func (*SelectClause) selectStatement()        {}
func (*UnionClause) selectStatement()         {}
func (*ValuesClause) selectStatement()        {}
func (*LiteralValuesClause) selectStatement() {}

// Select represents a SelectStatement with an ORDER and/or LIMIT.
type Select struct {
	With    *With
	Select  SelectStatement
	OrderBy OrderBy
	Limit   *Limit
	Locking LockingClause
}

// Format implements the NodeFormatter interface.
func (node *Select) Format(ctx *FmtCtx) {
	ctx.FormatNode(node.With)
	ctx.FormatNode(node.Select)
	if len(node.OrderBy) > 0 {
		ctx.WriteByte(' ')
		ctx.FormatNode(&node.OrderBy)
	}
	if node.Limit != nil {
		ctx.WriteByte(' ')
		ctx.FormatNode(node.Limit)
	}
	ctx.FormatNode(&node.Locking)
}

// SQLRight Code Injection.
func (node *Select) LogCurrentNode(depth int) *SQLRightIR {

	withNode := node.With.LogCurrentNode(depth + 1)
	selectNode := node.Select.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    withNode,
		RNode:    selectNode,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if len(node.OrderBy) > 0 {
		infix := " "
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
		infix := " "
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

	lockingNode := node.Locking.LogCurrentNode(depth + 1)

	rootIR = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    lockingNode,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	rootIR.IRType = TypeSelect

	return rootIR
}

// ParenSelect represents a parenthesized SELECT/UNION/VALUES statement.
type ParenSelect struct {
	Select *Select
}

// Format implements the NodeFormatter interface.
func (node *ParenSelect) Format(ctx *FmtCtx) {
	ctx.WriteByte('(')
	ctx.FormatNode(node.Select)
	ctx.WriteByte(')')
}

// SQLRight Code Injection.
func (node *ParenSelect) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "("
	infix := ")"

	selectNode := node.Select.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeParenSelect,
		DataType: DataNone,
		LNode:    selectNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  infix,
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// SelectClause represents a SELECT statement.
type SelectClause struct {
	From        From
	DistinctOn  DistinctOn
	Exprs       SelectExprs
	GroupBy     GroupBy
	Window      Window
	Having      *Where
	Where       *Where
	Distinct    bool
	TableSelect bool
}

// Format implements the NodeFormatter interface.
func (node *SelectClause) Format(ctx *FmtCtx) {
	f := ctx.flags
	if f.HasFlags(FmtSummary) {
		ctx.WriteString("SELECT")
		if len(node.From.Tables) > 0 {
			ctx.WriteByte(' ')
			ctx.FormatNode(&node.From)
		}
		return
	}
	if node.TableSelect {
		ctx.WriteString("TABLE ")
		ctx.FormatNode(node.From.Tables[0])
	} else {
		ctx.WriteString("SELECT ")
		if node.Distinct {
			if node.DistinctOn != nil {
				ctx.FormatNode(&node.DistinctOn)
				ctx.WriteByte(' ')
			} else {
				ctx.WriteString("DISTINCT ")
			}
		}
		ctx.FormatNode(&node.Exprs)
		if len(node.From.Tables) > 0 {
			ctx.WriteByte(' ')
			ctx.FormatNode(&node.From)
		}
		if node.Where != nil {
			ctx.WriteByte(' ')
			ctx.FormatNode(node.Where)
		}
		if len(node.GroupBy) > 0 {
			ctx.WriteByte(' ')
			ctx.FormatNode(&node.GroupBy)
		}
		if node.Having != nil {
			ctx.WriteByte(' ')
			ctx.FormatNode(node.Having)
		}
		if len(node.Window) > 0 {
			ctx.WriteByte(' ')
			ctx.FormatNode(&node.Window)
		}
	}
}

// SQLRight Code Injection.
func (node *SelectClause) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""
	/* FmtSummary? */
	//prefix := "SELECT "
	//if len(node.From.Tables) > 0 {
	//	fromNode := node.From.LogCurrentNode(depth + 1)
	//	rootIR := &SQLRightIR{
	//		IRType:   TypeSelectClause,
	//		DataType: DataNone,
	//		LNode:    fromNode,
	//		//RNode:  newTypeNode,
	//		Prefix: prefix,
	//		Infix:  "",
	//		Suffix: "",
	//		Depth:  depth,
	//	}
	//	return rootIR
	//}

	if node.TableSelect {
		prefix += "TABLE "
		tableNode0 := node.From.Tables.LogCurrentNode(depth + 1)

		rootIR := &SQLRightIR{
			IRType:   TypeSelectClause,
			DataType: DataNone,
			LNode:    tableNode0,
			//RNode:  ,
			Prefix: prefix,
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}

		return rootIR

	} else {

		prefix = "SELECT "

		var optDistinctNode *SQLRightIR
		if node.Distinct {
			if node.DistinctOn != nil {
				distinceOnNode := node.DistinctOn.LogCurrentNode(depth + 1)
				tmpOptDistinctNode := &SQLRightIR{
					IRType:   TypeOptDistinct,
					DataType: DataNone,
					LNode:    distinceOnNode,
					//RNode:  colateNode,
					Prefix: "",
					Infix:  " ",
					Suffix: "",
					Depth:  depth,
				}
				optDistinctNode = tmpOptDistinctNode
			} else {
				tmpOptDistinctNode := &SQLRightIR{
					IRType:   TypeOptDistinct,
					DataType: DataNone,
					//LNode:    distinceOnNode,
					//RNode:  colateNode,
					Prefix: "DISTINCT ",
					Infix:  "",
					Suffix: "",
					Depth:  depth,
				}
				optDistinctNode = tmpOptDistinctNode
			}
		} else {
			// Empty node
			tmpOptDistinctNode := &SQLRightIR{
				IRType:   TypeOptDistinct,
				DataType: DataNone,
				//LNode:    distinceOnNode,
				//RNode:  colateNode,
				Prefix: "",
				Infix:  "",
				Suffix: "",
				Depth:  depth,
			}
			optDistinctNode = tmpOptDistinctNode
		}

		exprsNode := node.Exprs.LogCurrentNode(depth + 1)

		rootIR := &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    optDistinctNode,
			RNode:    exprsNode,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		if len(node.From.Tables) > 0 {

			fromNode := node.From.LogCurrentNode(depth + 1)
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    fromNode,
				Prefix:   "",
				Infix:    " ",
				Suffix:   "",
				Depth:    depth,
			}
		}

		if node.Where != nil {
			whereNode := node.Where.LogCurrentNode(depth + 1)
			rootIR = &SQLRightIR{
				IRType:   TypeHaving,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    whereNode,
				Prefix:   "",
				Infix:    " ",
				Suffix:   "",
				Depth:    depth,
			}
		}

		if len(node.GroupBy) > 0 {
			groupByNode := node.GroupBy.LogCurrentNode(depth + 1)
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    groupByNode,
				Prefix:   "",
				Infix:    " ",
				Suffix:   "",
				Depth:    depth,
			}
		}
		if node.Having != nil {
			havingNode := node.Having.LogCurrentNode(depth + 1)
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    havingNode,
				Prefix:   "",
				Infix:    " ",
				Suffix:   "",
				Depth:    depth,
			}

		}
		if len(node.Window) > 0 {
			windowNode := node.Window.LogCurrentNode(depth + 1)
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    windowNode,
				Prefix:   "",
				Infix:    "",
				Suffix:   "",
				Depth:    depth,
			}
		}

		rootIR.IRType = TypeSelectClause
		return rootIR
	}
}

// SelectExprs represents SELECT expressions.
type SelectExprs []SelectExpr

// Format implements the NodeFormatter interface.
func (node *SelectExprs) Format(ctx *FmtCtx) {
	for i := range *node {
		if i > 0 {
			ctx.WriteString(", ")
		}
		ctx.FormatNode(&(*node)[i])
	}
}

// SQLRight Code Injection.
func (node *SelectExprs) LogCurrentNode(depth int) *SQLRightIR {

	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{}
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
	tmpIR.IRType = TypeSelectExprs
	return tmpIR

}

// SelectExpr represents a SELECT expression.
type SelectExpr struct {
	Expr Expr
	As   UnrestrictedName
}

// NormalizeTopLevelVarName preemptively expands any UnresolvedName at
// the top level of the expression into a VarName. This is meant
// to catch stars so that sql.checkRenderStar() can see it prior to
// other expression transformations.
func (node *SelectExpr) NormalizeTopLevelVarName() error {
	if vBase, ok := node.Expr.(VarName); ok {
		v, err := vBase.NormalizeVarName()
		if err != nil {
			return err
		}
		node.Expr = v
	}
	return nil
}

// StarSelectExpr is a convenience function that represents an unqualified "*"
// in a select expression.
func StarSelectExpr() SelectExpr {
	return SelectExpr{Expr: StarExpr()}
}

// Format implements the NodeFormatter interface.
func (node *SelectExpr) Format(ctx *FmtCtx) {
	ctx.FormatNode(node.Expr)
	if node.As != "" {
		ctx.WriteString(" AS ")
		ctx.FormatNode(&node.As)
	}
}

// SQLRight Code Injection.
func (node *SelectExpr) LogCurrentNode(depth int) *SQLRightIR {

	exprNode := node.Expr.LogCurrentNode(depth + 1)

	infix := ""
	var asNode *SQLRightIR
	if node.As != "" {
		infix = " AS "
		asStr := node.As.String()
		tmpAsNode := &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataColumnAliasName,
			ContextFlag: ContextDefine,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         asStr,
		}
		asNode = tmpAsNode
	}

	rootIR := &SQLRightIR{
		IRType:   TypeSelectExpr,
		DataType: DataNone,
		LNode:    exprNode,
		RNode:    asNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AliasClause represents an alias, optionally with a column def list:
// "AS name", "AS name(col1, col2)", or "AS name(col1 INT, col2 STRING)".
// Note that the last form is only valid in the context of record-returning
// functions, which also require the last form to define their output types.
type AliasClause struct {
	Alias Name
	Cols  ColumnDefList
}

// Format implements the NodeFormatter interface.
func (f *AliasClause) Format(ctx *FmtCtx) {
	ctx.FormatNode(&f.Alias)
	if len(f.Cols) != 0 {
		// Format as "alias (col1, col2, ...)".
		ctx.WriteString(" (")
		ctx.FormatNode(&f.Cols)
		ctx.WriteByte(')')
	}
}

// SQLRight Code Injection.
func (node *AliasClause) LogCurrentNode(depth int) *SQLRightIR {

	dataType := DataTableAliasName

	//if len(node.Cols) > 0 {
	//	dataType = DataTableAliasName
	//}

	aliasStr := node.Alias.String()
	tmpAliasNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    dataType,
		ContextFlag: ContextDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         aliasStr,
	}
	aliasNode := tmpAliasNode

	infix := ""
	suffix := ""
	var colNode *SQLRightIR
	if len(node.Cols) != 0 {
		infix = "("
		suffix = ")"
		tmpColNode := node.Cols.LogCurrentNodeWithType(depth+1, DataColumnAliasName, ContextDefine)
		colNode = tmpColNode
	}

	rootIR := &SQLRightIR{
		IRType:   TypeAliasClause,
		DataType: DataNone,
		LNode:    aliasNode,
		RNode:    colNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   suffix,
		Depth:    depth,
	}

	return rootIR
}

// ColumnDef represents a column definition in the context of a record type
// alias, like in select * from json_to_record(...) AS foo(a INT, b INT).
type ColumnDef struct {
	Name Name
	Type ResolvableTypeReference
}

// Format implements the NodeFormatter interface.
func (c *ColumnDef) Format(ctx *FmtCtx) {
	ctx.FormatNode(&c.Name)
	if c.Type != nil {
		ctx.WriteByte(' ')
		ctx.WriteString(c.Type.SQLString())
	}
}

func (node *ColumnDef) LogCurrentNode(depth int) *SQLRightIR {
	return node.LogCurrentNodeWithType(depth, DataColumnName, ContextDefine)
}

// SQLRight Code Injection.
func (node *ColumnDef) LogCurrentNodeWithType(depth int, dataType SQLRightDataType, contextFlag SQLRightContextFlag) *SQLRightIR {

	tmpNameNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    dataType,
		ContextFlag: contextFlag,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Name.String(),
	}
	nameNode := tmpNameNode

	infix := ""
	var typeNode *SQLRightIR
	if node.Type != nil {
		infix = " "
		typeStr := node.Type.SQLString()
		tmpTypeNode := &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataTypeName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         typeStr,
		}
		typeNode = tmpTypeNode
	}

	rootIR := &SQLRightIR{
		IRType:   TypeColumnDef,
		DataType: DataNone,
		LNode:    nameNode,
		RNode:    typeNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ColumnDefList represents a list of ColumnDefs.
type ColumnDefList []ColumnDef

// Format implements the NodeFormatter interface.
func (c *ColumnDefList) Format(ctx *FmtCtx) {
	for i := range *c {
		if i > 0 {
			ctx.WriteString(", ")
		}
		ctx.FormatNode(&(*c)[i])
	}
}

// SQLRight Code Injection.
func (node *ColumnDefList) LogCurrentNode(depth int) *SQLRightIR {
	return node.LogCurrentNodeWithType(depth, DataColumnName, ContextDefine)
}

// SQLRight Code Injection.
func (node *ColumnDefList) LogCurrentNodeWithType(depth int, dataType SQLRightDataType, contextFlag SQLRightContextFlag) *SQLRightIR {

	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{}
	for i, n := range *node {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n.LogCurrentNodeWithType(depth+1, dataType, contextFlag)
			var RNode *SQLRightIR
			infix := ""
			if len(*node) >= 2 {
				infix = ", "
				RNode = (*node)[1].LogCurrentNodeWithType(depth+1, dataType, contextFlag)
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
			RNode := n.LogCurrentNodeWithType(depth+1, dataType, contextFlag)

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
	tmpIR.IRType = TypeColumnDefList

	return tmpIR
}

// AsOfClause represents an as of time.
type AsOfClause struct {
	Expr Expr
}

// Format implements the NodeFormatter interface.
func (a *AsOfClause) Format(ctx *FmtCtx) {
	ctx.WriteString("AS OF SYSTEM TIME ")
	ctx.FormatNode(a.Expr)
}

// SQLRight Code Injection.
func (node *AsOfClause) LogCurrentNode(depth int) *SQLRightIR {

	exprNode := node.Expr.LogCurrentNode(depth + 1)

	prefix := "AS OF SYSTEM TIME "
	rootIR := &SQLRightIR{
		IRType:   TypeAsOfClause,
		DataType: DataNone,
		LNode:    exprNode,
		//RNode:    fromNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}
	return rootIR
}

// From represents a FROM clause.
type From struct {
	Tables TableExprs
	AsOf   AsOfClause
}

// Format implements the NodeFormatter interface.
func (node *From) Format(ctx *FmtCtx) {
	ctx.WriteString("FROM ")
	ctx.FormatNode(&node.Tables)
	if node.AsOf.Expr != nil {
		ctx.WriteByte(' ')
		ctx.FormatNode(&node.AsOf)
	}
}

// SQLRight Code Injection.
func (node *From) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "FROM "
	tableNode := node.Tables.LogCurrentNode(depth + 1)

	var asNode *SQLRightIR
	infix := ""
	if node.AsOf.Expr != nil {
		infix = " "
		asNode = node.AsOf.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		IRType:   TypeFrom,
		DataType: DataNone,
		LNode:    tableNode,
		RNode:    asNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// TableExprs represents a list of table expressions.
type TableExprs []TableExpr

// Format implements the NodeFormatter interface.
func (node *TableExprs) Format(ctx *FmtCtx) {
	prefix := ""
	for _, n := range *node {
		ctx.WriteString(prefix)
		ctx.FormatNode(n)
		prefix = ", "
	}
}

// SQLRight Code Injection.
func (node *TableExprs) LogCurrentNode(depth int) *SQLRightIR {

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
	tmpIR.IRType = TypeTableExprs
	return tmpIR
}

// TableExpr represents a table expression.
type TableExpr interface {
	NodeFormatter
	tableExpr()
	WalkTableExpr(Visitor) TableExpr
	SQLRightInterface
}

func (*AliasedTableExpr) tableExpr() {}
func (*ParenTableExpr) tableExpr()   {}
func (*JoinTableExpr) tableExpr()    {}
func (*RowsFromExpr) tableExpr()     {}
func (*Subquery) tableExpr()         {}
func (*StatementSource) tableExpr()  {}

// StatementSource encapsulates one of the other statements as a data source.
type StatementSource struct {
	Statement Statement
}

// Format implements the NodeFormatter interface.
func (node *StatementSource) Format(ctx *FmtCtx) {
	ctx.WriteByte('[')
	ctx.FormatNode(node.Statement)
	ctx.WriteByte(']')
}

// SQLRight Code Injection.
func (node *StatementSource) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "["
	infix := "]"

	statementNode := node.Statement.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeStatementSource,
		DataType: DataNone,
		LNode:    statementNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// IndexID is a custom type for IndexDescriptor IDs.
type IndexID = catid.IndexID

// IndexFlags represents "@<index_name|index_id>" or "@{param[,param]}" where
// param is one of:
//   - FORCE_INDEX=<index_name|index_id>
//   - ASC / DESC
//   - NO_INDEX_JOIN
//   - NO_ZIGZAG_JOIN
//   - NO_FULL_SCAN
//   - IGNORE_FOREIGN_KEYS
//   - FORCE_ZIGZAG
//   - FORCE_ZIGZAG=<index_name|index_id>*
//
// It is used optionally after a table name in SELECT statements.
type IndexFlags struct {
	Index   UnrestrictedName
	IndexID IndexID
	// Direction of the scan, if provided. Can only be set if
	// one of Index or IndexID is set.
	Direction Direction
	// NoIndexJoin cannot be specified together with an index.
	NoIndexJoin bool
	// NoZigzagJoin indicates we should not plan a zigzag join for this scan.
	NoZigzagJoin bool
	// NoFullScan indicates we should constrain this scan.
	NoFullScan bool
	// IgnoreForeignKeys disables optimizations based on outbound foreign key
	// references from this table. This is useful in particular for scrub queries
	// used to verify the consistency of foreign key relations.
	IgnoreForeignKeys bool
	// IgnoreUniqueWithoutIndexKeys disables optimizations based on unique without
	// index constraints.
	IgnoreUniqueWithoutIndexKeys bool
	// Zigzag hinting fields are distinct:
	// ForceZigzag means we saw a TABLE@{FORCE_ZIGZAG}
	// ZigzagIndexes means we saw TABLE@{FORCE_ZIGZAG=name}
	// ZigzagIndexIDs means we saw TABLE@{FORCE_ZIGZAG=[ID]}
	// The only allowable combinations are when a valid id and name are combined.
	ForceZigzag    bool
	ZigzagIndexes  []UnrestrictedName
	ZigzagIndexIDs []IndexID
}

// ForceIndex returns true if a forced index was specified, either using a name
// or an IndexID.
func (ih *IndexFlags) ForceIndex() bool {
	return ih.Index != "" || ih.IndexID != 0
}

// CombineWith combines two IndexFlags structures, returning an error if they
// conflict with one another.
func (ih *IndexFlags) CombineWith(other *IndexFlags) error {
	if ih.NoIndexJoin && other.NoIndexJoin {
		return errors.New("NO_INDEX_JOIN specified multiple times")
	}
	if ih.NoZigzagJoin && other.NoZigzagJoin {
		return errors.New("NO_ZIGZAG_JOIN specified multiple times")
	}
	if ih.NoFullScan && other.NoFullScan {
		return errors.New("NO_FULL_SCAN specified multiple times")
	}
	if ih.IgnoreForeignKeys && other.IgnoreForeignKeys {
		return errors.New("IGNORE_FOREIGN_KEYS specified multiple times")
	}
	if ih.IgnoreUniqueWithoutIndexKeys && other.IgnoreUniqueWithoutIndexKeys {
		return errors.New("IGNORE_UNIQUE_WITHOUT_INDEX_KEYS specified multiple times")
	}
	result := *ih
	result.NoIndexJoin = ih.NoIndexJoin || other.NoIndexJoin
	result.NoZigzagJoin = ih.NoZigzagJoin || other.NoZigzagJoin
	result.NoFullScan = ih.NoFullScan || other.NoFullScan
	result.IgnoreForeignKeys = ih.IgnoreForeignKeys || other.IgnoreForeignKeys
	result.IgnoreUniqueWithoutIndexKeys = ih.IgnoreUniqueWithoutIndexKeys ||
		other.IgnoreUniqueWithoutIndexKeys

	if other.Direction != 0 {
		if ih.Direction != 0 {
			return errors.New("ASC/DESC specified multiple times")
		}
		result.Direction = other.Direction
	}

	if other.ForceIndex() {
		if ih.ForceIndex() {
			return errors.New("FORCE_INDEX specified multiple times")
		}
		result.Index = other.Index
		result.IndexID = other.IndexID
	}

	if other.ForceZigzag {
		if ih.ForceZigzag {
			return errors.New("FORCE_ZIGZAG specified multiple times")
		}
		result.ForceZigzag = true
	}

	// We can have N zigzag indexes (in theory, we only support 2 now).
	if len(other.ZigzagIndexes) > 0 {
		if result.ForceZigzag {
			return errors.New("FORCE_ZIGZAG hints not distinct")
		}
		result.ZigzagIndexes = append(result.ZigzagIndexes, other.ZigzagIndexes...)
	}

	// We can have N zigzag indexes (in theory, we only support 2 now).
	if len(other.ZigzagIndexIDs) > 0 {
		if result.ForceZigzag {
			return errors.New("FORCE_ZIGZAG hints not distinct")
		}
		result.ZigzagIndexIDs = append(result.ZigzagIndexIDs, other.ZigzagIndexIDs...)
	}

	// We only set at the end to avoid a partially changed structure in one of the
	// error cases above.
	*ih = result
	return nil
}

// Check verifies if the flags are valid:
//   - ascending/descending is not specified without an index;
//   - no_index_join isn't specified with an index.
func (ih *IndexFlags) Check() error {
	if ih.NoIndexJoin && ih.ForceIndex() {
		return errors.New("FORCE_INDEX cannot be specified in conjunction with NO_INDEX_JOIN")
	}
	if ih.Direction != 0 && !ih.ForceIndex() {
		return errors.New("ASC/DESC must be specified in conjunction with an index")
	}
	if ih.zigzagForced() && ih.NoIndexJoin {
		return errors.New("FORCE_ZIGZAG cannot be specified in conjunction with NO_INDEX_JOIN")
	}
	if ih.zigzagForced() && ih.ForceIndex() {
		return errors.New("FORCE_ZIGZAG cannot be specified in conjunction with FORCE_INDEX")
	}
	if ih.zigzagForced() && ih.NoZigzagJoin {
		return errors.New("FORCE_ZIGZAG cannot be specified in conjunction with NO_ZIGZAG_JOIN")
	}
	for _, name := range ih.ZigzagIndexes {
		if len(string(name)) == 0 {
			return errors.New("FORCE_ZIGZAG index name cannot be empty string")
		}
	}

	return nil
}

// Format implements the NodeFormatter interface.
func (ih *IndexFlags) Format(ctx *FmtCtx) {
	ctx.WriteByte('@')
	if !ih.NoIndexJoin && !ih.NoZigzagJoin && !ih.NoFullScan && !ih.IgnoreForeignKeys &&
		!ih.IgnoreUniqueWithoutIndexKeys && ih.Direction == 0 && !ih.zigzagForced() {
		if ih.Index != "" {
			ctx.FormatNode(&ih.Index)
		} else {
			ctx.Printf("[%d]", ih.IndexID)
		}
	} else {
		ctx.WriteByte('{')
		var sep func()
		sep = func() {
			sep = func() { ctx.WriteByte(',') }
		}
		if ih.Index != "" || ih.IndexID != 0 {
			sep()
			ctx.WriteString("FORCE_INDEX=")
			if ih.Index != "" {
				ctx.FormatNode(&ih.Index)
			} else {
				ctx.Printf("[%d]", ih.IndexID)
			}

			if ih.Direction != 0 {
				ctx.Printf(",%s", ih.Direction)
			}
		}
		if ih.NoIndexJoin {
			sep()
			ctx.WriteString("NO_INDEX_JOIN")
		}

		if ih.NoZigzagJoin {
			sep()
			ctx.WriteString("NO_ZIGZAG_JOIN")
		}

		if ih.NoFullScan {
			sep()
			ctx.WriteString("NO_FULL_SCAN")
		}

		if ih.IgnoreForeignKeys {
			sep()
			ctx.WriteString("IGNORE_FOREIGN_KEYS")
		}

		if ih.IgnoreUniqueWithoutIndexKeys {
			sep()
			ctx.WriteString("IGNORE_UNIQUE_WITHOUT_INDEX_KEYS")
		}

		if ih.ForceZigzag || len(ih.ZigzagIndexes) > 0 || len(ih.ZigzagIndexIDs) > 0 {
			sep()
			if ih.ForceZigzag {
				ctx.WriteString("FORCE_ZIGZAG")
			} else {
				needSep := false
				for _, name := range ih.ZigzagIndexes {
					if needSep {
						sep()
					}
					ctx.WriteString("FORCE_ZIGZAG=")
					ctx.FormatNode(&name)
					needSep = true
				}
				for _, id := range ih.ZigzagIndexIDs {
					if needSep {
						sep()
					}
					ctx.WriteString("FORCE_ZIGZAG=")
					ctx.Printf("[%d]", id)
					needSep = true
				}
			}
		}
		ctx.WriteString("}")
	}
}

// SQLRight Code Injection.
func (node *IndexFlags) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "@"
	if !node.NoIndexJoin && !node.NoZigzagJoin && !node.NoFullScan && !node.IgnoreForeignKeys &&
		!node.IgnoreUniqueWithoutIndexKeys && node.Direction == 0 && !node.zigzagForced() {
		if node.Index != "" {
			indexStr := node.Index.String()
			tmpIndexNode := &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataIndexName,
				ContextFlag: ContextUse,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         indexStr,
			}
			indexNode := tmpIndexNode
			rootIR := &SQLRightIR{
				IRType:   TypeIndexFlags,
				DataType: DataNone,
				LNode:    indexNode,
				//RNode:    RNode,
				Prefix: prefix,
				Infix:  "",
				Suffix: "",
				Depth:  depth,
			}
			return rootIR
		} else {
			intLiteral := &SQLRightIR{
				IRType:       TypeIntegerLiteral,
				DataType:     DataLiteral,
				DataAffinity: AFFIINT,
				Prefix:       "",
				Infix:        "",
				Suffix:       "",
				Depth:        depth,
				IValue:       int64(node.IndexID),
			}
			indexNode := &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    intLiteral,
				//RNode:    RNode,
				Prefix: "[",
				Infix:  "]",
				Suffix: "",
				Depth:  depth,
			}
			rootIR := &SQLRightIR{
				IRType:   TypeIndexFlags,
				DataType: DataNone,
				LNode:    indexNode,
				//RNode:    RNode,
				Prefix: prefix,
				Infix:  "",
				Suffix: "",
				Depth:  depth,
			}
			return rootIR
		}
	} else {
		prefix += "{"
		var rootIR *SQLRightIR

		if node.Index != "" || node.IndexID != 0 {
			prefix += ", "

			tmpPrefix := "FORCE_INDEX="
			var indexNode *SQLRightIR
			if node.Index != "" {
				indexStr := node.Index.String()
				tmpIndexNode := &SQLRightIR{
					IRType:      TypeIdentifier,
					DataType:    DataIndexName,
					ContextFlag: ContextUse,
					Prefix:      "",
					Infix:       "",
					Suffix:      "",
					Depth:       depth,
					Str:         indexStr,
				}
				indexNode = tmpIndexNode
			} else {
				intLiteral := &SQLRightIR{
					IRType:       TypeIntegerLiteral,
					DataType:     DataLiteral,
					DataAffinity: AFFIINT,
					Prefix:       "",
					Infix:        "",
					Suffix:       "",
					Depth:        depth,
					IValue:       int64(node.IndexID),
				}
				tmpIndexNode := &SQLRightIR{
					IRType:   TypeUnknown,
					DataType: DataNone,
					LNode:    intLiteral,
					//RNode:    RNode,
					Prefix: "[",
					Infix:  "]",
					Suffix: "",
					Depth:  depth,
				}
				indexNode = tmpIndexNode
			}

			var directionNode *SQLRightIR
			if node.Direction != 0 {
				directionStr := fmt.Sprintf("%s", node.Direction)
				tmpDirectionNode := &SQLRightIR{
					IRType:   TypeDirection,
					DataType: DataNone,
					//LNode:    LNode,
					//RNode:    RNode,
					Prefix: "",
					Infix:  "",
					Suffix: "",
					Depth:  depth,
					Str:    directionStr,
				}
				directionNode = tmpDirectionNode
			}

			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    indexNode,
				RNode:    directionNode,
				Prefix:   tmpPrefix,
				Infix:    "",
				Suffix:   "",
				Depth:    depth,
			}

			// Use the prefix. '{,'
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				//RNode:    directionNode,
				Prefix: prefix,
				Infix:  "",
				Suffix: "",
				Depth:  depth,
			}
			prefix = ""
		}

		if node.NoIndexJoin {
			infix := ", "
			indexFlagNode := &SQLRightIR{
				IRType:   TypeIndexFlag,
				DataType: DataNone,
				//LNode:    LNode,
				//RNode:    RNode,
				Prefix: "NO_INDEX_JOIN",
				Infix:  "",
				Suffix: "",
				Depth:  depth,
			}
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    indexFlagNode,
				Prefix:   "",
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}
		}

		if node.NoZigzagJoin {
			infix := ", "
			indexFlagNode := &SQLRightIR{
				IRType:   TypeIndexFlag,
				DataType: DataNone,
				//LNode:    LNode,
				//RNode:    RNode,
				Prefix: "NO_ZIGZAG_JOIN",
				Infix:  "",
				Suffix: "",
				Depth:  depth,
			}
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    indexFlagNode,
				Prefix:   "",
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}
		}

		if node.NoFullScan {
			infix := ", "
			indexFlagNode := &SQLRightIR{
				IRType:   TypeIndexFlag,
				DataType: DataNone,
				//LNode:    LNode,
				//RNode:    RNode,
				Prefix: "NO_FULL_SCAN",
				Infix:  "",
				Suffix: "",
				Depth:  depth,
			}
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    indexFlagNode,
				Prefix:   "",
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}
		}

		if node.IgnoreForeignKeys {
			infix := ", "
			indexFlagNode := &SQLRightIR{
				IRType:   TypeIndexFlag,
				DataType: DataNone,
				//LNode:    LNode,
				//RNode:    RNode,
				Prefix: "IGNORE_FOREIGN_KEYS",
				Infix:  "",
				Suffix: "",
				Depth:  depth,
			}
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    indexFlagNode,
				Prefix:   "",
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}
		}

		if node.IgnoreUniqueWithoutIndexKeys {
			infix := ", "
			indexFlagNode := &SQLRightIR{
				IRType:   TypeIndexFlag,
				DataType: DataNone,
				//LNode:    LNode,
				//RNode:    RNode,
				Prefix: "IGNORE_UNIQUE_WITHOUT_INDEX_KEYS",
				Infix:  "",
				Suffix: "",
				Depth:  depth,
			}
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    indexFlagNode,
				Prefix:   "",
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}
		}

		if node.ForceZigzag || len(node.ZigzagIndexes) > 0 || len(node.ZigzagIndexIDs) > 0 {
			infix := ", "
			if node.ForceZigzag {
				indexFlagNode := &SQLRightIR{
					IRType:   TypeIndexFlag,
					DataType: DataNone,
					//LNode:    LNode,
					//RNode:    RNode,
					Prefix: "FORCE_ZIGZAG",
					Infix:  "",
					Suffix: "",
					Depth:  depth,
				}
				rootIR = &SQLRightIR{
					IRType:   TypeUnknown,
					DataType: DataNone,
					LNode:    rootIR,
					RNode:    indexFlagNode,
					Prefix:   "",
					Infix:    infix,
					Suffix:   "",
					Depth:    depth,
				}
			} else {
				//needSep := false
				infix = ", "
				for _, name := range node.ZigzagIndexes {
					indexName := name.String()
					indexNameNode := &SQLRightIR{
						IRType:      TypeIdentifier,
						DataType:    DataIndexName,
						ContextFlag: ContextUse,
						Prefix:      "",
						Infix:       "",
						Suffix:      "",
						Depth:       depth,
						Str:         indexName,
					}
					indexFlagNode := &SQLRightIR{
						IRType:   TypeIndexFlag,
						DataType: DataNone,
						LNode:    indexNameNode,
						//RNode:    RNode,
						Prefix: "FORCE_ZIGZAG=",
						Infix:  "",
						Suffix: "",
						Depth:  depth,
					}
					rootIR = &SQLRightIR{
						IRType:   TypeUnknown,
						DataType: DataNone,
						LNode:    rootIR,
						RNode:    indexFlagNode,
						Prefix:   "",
						Infix:    infix,
						Suffix:   "",
						Depth:    depth,
					}
					//needSep = true
				}
				for _, id := range node.ZigzagIndexIDs {

					intLiteral := &SQLRightIR{
						IRType:       TypeIntegerLiteral,
						DataType:     DataLiteral,
						DataAffinity: AFFIINT,
						Prefix:       "",
						Infix:        "",
						Suffix:       "",
						Depth:        depth,
						IValue:       int64(id),
					}
					indexFlagNode := &SQLRightIR{
						IRType:   TypeIndexFlag,
						DataType: DataNone,
						LNode:    intLiteral,
						//RNode:    RNode,
						Prefix: "FORCE_ZIGZAG=[",
						Infix:  "]",
						Suffix: "",
						Depth:  depth,
					}
					rootIR = &SQLRightIR{
						IRType:   TypeUnknown,
						DataType: DataNone,
						LNode:    rootIR,
						RNode:    indexFlagNode,
						Prefix:   "",
						Infix:    infix,
						Suffix:   "",
						Depth:    depth,
					}
				}
			}
		}

		rootIR.Suffix = "}"
		rootIR.IRType = TypeIndexFlags
		return rootIR
	}

}

func (ih *IndexFlags) zigzagForced() bool {
	return ih.ForceZigzag || len(ih.ZigzagIndexes) > 0 || len(ih.ZigzagIndexIDs) > 0
}

// AliasedTableExpr represents a table expression coupled with an optional
// alias.
type AliasedTableExpr struct {
	Expr       TableExpr
	IndexFlags *IndexFlags
	Ordinality bool
	Lateral    bool
	As         AliasClause
}

// Format implements the NodeFormatter interface.
func (node *AliasedTableExpr) Format(ctx *FmtCtx) {
	if node.Lateral {
		ctx.WriteString("LATERAL ")
	}
	ctx.FormatNode(node.Expr)
	if node.IndexFlags != nil {
		ctx.FormatNode(node.IndexFlags)
	}
	if node.Ordinality {
		ctx.WriteString(" WITH ORDINALITY")
	}
	if node.As.Alias != "" {
		ctx.WriteString(" AS ")
		ctx.FormatNode(&node.As)
	}
}

// SQLRight Code Injection.
func (node *AliasedTableExpr) LogCurrentNode(depth int) *SQLRightIR {

	var literalNode *SQLRightIR
	if node.Lateral {
		literalNode = &SQLRightIR{
			IRType:   TypeOptLiteral,
			DataType: DataNone,
			Prefix:   "LATERAL ",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	} else {
		literalNode = &SQLRightIR{
			IRType:   TypeOptLiteral,
			DataType: DataNone,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	exprNode := node.Expr.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    literalNode,
		RNode:    exprNode,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if node.IndexFlags != nil {
		indexFlagNode := node.IndexFlags.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    indexFlagNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.Ordinality {
		oridinalityNode := &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			Prefix:   " WITH ORDINALITY",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    oridinalityNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.As.Alias != "" {
		asNode := node.As.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    asNode,
			Prefix:   "",
			Infix:    " AS ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeAliasedTableExpr

	return rootIR
}

// ParenTableExpr represents a parenthesized TableExpr.
type ParenTableExpr struct {
	Expr TableExpr
}

// Format implements the NodeFormatter interface.
func (node *ParenTableExpr) Format(ctx *FmtCtx) {
	ctx.WriteByte('(')
	ctx.FormatNode(node.Expr)
	ctx.WriteByte(')')
}

// SQLRight Code Injection.
func (node *ParenTableExpr) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "("
	infix := ")"

	exprNode := node.Expr.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeParenTableExpr,
		DataType: DataNone,
		LNode:    exprNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  infix,
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// StripTableParens strips any parentheses surrounding a selection clause.
func StripTableParens(expr TableExpr) TableExpr {
	if p, ok := expr.(*ParenTableExpr); ok {
		return StripTableParens(p.Expr)
	}
	return expr
}

// JoinTableExpr represents a TableExpr that's a JOIN operation.
type JoinTableExpr struct {
	JoinType string
	Left     TableExpr
	Right    TableExpr
	Cond     JoinCond
	Hint     string
}

// JoinTableExpr.Join
const (
	AstFull  = "FULL"
	AstLeft  = "LEFT"
	AstRight = "RIGHT"
	AstCross = "CROSS"
	AstInner = "INNER"
)

// JoinTableExpr.Hint
const (
	AstHash     = "HASH"
	AstLookup   = "LOOKUP"
	AstMerge    = "MERGE"
	AstInverted = "INVERTED"
)

// Format implements the NodeFormatter interface.
func (node *JoinTableExpr) Format(ctx *FmtCtx) {
	ctx.FormatNode(node.Left)
	ctx.WriteByte(' ')
	if _, isNatural := node.Cond.(NaturalJoinCond); isNatural {
		// Natural joins have a different syntax: "<a> NATURAL <join_type> <b>"
		ctx.FormatNode(node.Cond)
		ctx.WriteByte(' ')
		if node.JoinType != "" {
			ctx.WriteString(node.JoinType)
			ctx.WriteByte(' ')
			if node.Hint != "" {
				ctx.WriteString(node.Hint)
				ctx.WriteByte(' ')
			}
		}
		ctx.WriteString("JOIN ")
		ctx.FormatNode(node.Right)
	} else {
		// General syntax: "<a> <join_type> [<join_hint>] JOIN <b> <condition>"
		if node.JoinType != "" {
			ctx.WriteString(node.JoinType)
			ctx.WriteByte(' ')
			if node.Hint != "" {
				ctx.WriteString(node.Hint)
				ctx.WriteByte(' ')
			}
		}
		ctx.WriteString("JOIN ")
		ctx.FormatNode(node.Right)
		if node.Cond != nil {
			ctx.WriteByte(' ')
			ctx.FormatNode(node.Cond)
		}
	}
}

// SQLRight Code Injection.
func (node *JoinTableExpr) LogCurrentNode(depth int) *SQLRightIR {

	var rootIR *SQLRightIR

	joinLeftNode := node.Left.LogCurrentNode(depth + 1)
	infix := " "

	if _, isNatural := node.Cond.(NaturalJoinCond); isNatural {
		// Natural joins have a different syntax: "<a> NATURAL <join_type> <b>"
		condNode := node.Cond.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    joinLeftNode,
			RNode:    condNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}

		if node.JoinType != "" {

			joinTypeNode := &SQLRightIR{
				IRType:   TypeJoinType,
				DataType: DataNone,
				Prefix:   node.JoinType,
				Infix:    "",
				Suffix:   "",
			}

			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    joinTypeNode,
				Prefix:   "",
				Infix:    " ",
				Suffix:   "",
				Depth:    depth,
			}

			if node.Hint != "" {
				joinHintNode := &SQLRightIR{
					IRType:   TypeJoinHint,
					DataType: DataNone,
					Prefix:   node.Hint,
					Infix:    "",
					Suffix:   "",
				}

				rootIR = &SQLRightIR{
					IRType:   TypeUnknown,
					DataType: DataNone,
					LNode:    rootIR,
					RNode:    joinHintNode,
					Prefix:   "",
					Infix:    " ",
					Suffix:   "",
					Depth:    depth,
				}
			}
		}
		infix = "JOIN "
		joinRightNode := node.Right.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    joinRightNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}

	} else {
		// General syntax: "<a> <join_type> [<join_hint>] JOIN <b> <condition>"
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    joinLeftNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		if node.JoinType != "" {

			joinTypeNode := &SQLRightIR{
				IRType:   TypeJoinType,
				DataType: DataNone,
				Prefix:   node.JoinType,
				Infix:    "",
				Suffix:   "",
			}

			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    joinTypeNode,
				Prefix:   "",
				Infix:    " ",
				Suffix:   "",
				Depth:    depth,
			}

			if node.Hint != "" {
				joinHintNode := &SQLRightIR{
					IRType:   TypeJoinHint,
					DataType: DataNone,
					Prefix:   node.Hint,
					Infix:    "",
					Suffix:   "",
				}

				rootIR = &SQLRightIR{
					IRType:   TypeUnknown,
					DataType: DataNone,
					LNode:    rootIR,
					RNode:    joinHintNode,
					Prefix:   "",
					Infix:    " ",
					Suffix:   "",
					Depth:    depth,
				}
			}
		}

		infix = " JOIN "
		joinRightNode := node.Right.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    joinRightNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}

		if node.Cond != nil {
			condNode := node.Cond.LogCurrentNode(depth + 1)
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    condNode,
				Prefix:   "",
				Infix:    " ",
				Suffix:   "",
				Depth:    depth,
			}
		}
	}

	rootIR.IRType = TypeJoinTableExpr
	return rootIR
}

// JoinCond represents a join condition.
type JoinCond interface {
	NodeFormatter
	joinCond()
	SQLRightInterface
}

func (NaturalJoinCond) joinCond() {}
func (*OnJoinCond) joinCond()     {}
func (*UsingJoinCond) joinCond()  {}

// NaturalJoinCond represents a NATURAL join condition
type NaturalJoinCond struct{}

// Format implements the NodeFormatter interface.
func (NaturalJoinCond) Format(ctx *FmtCtx) {
	ctx.WriteString("NATURAL")
}

// SQLRight Code Injection.
func (node NaturalJoinCond) LogCurrentNode(depth int) *SQLRightIR {
	prefix := "NATURAL"

	rootIR := &SQLRightIR{
		IRType:   TypeNaturalJoinCond,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// OnJoinCond represents an ON join condition.
type OnJoinCond struct {
	Expr Expr
}

// Format implements the NodeFormatter interface.
func (node *OnJoinCond) Format(ctx *FmtCtx) {
	ctx.WriteString("ON ")
	ctx.FormatNode(node.Expr)
}

// SQLRight Code Injection.
func (node *OnJoinCond) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ON "
	exprNode := node.Expr.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeOnJoinCond,
		DataType: DataNone,
		LNode:    exprNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// UsingJoinCond represents a USING join condition.
type UsingJoinCond struct {
	Cols NameList
}

// Format implements the NodeFormatter interface.
func (node *UsingJoinCond) Format(ctx *FmtCtx) {
	ctx.WriteString("USING (")
	ctx.FormatNode(&node.Cols)
	ctx.WriteByte(')')
}

// SQLRight Code Injection.
func (node *UsingJoinCond) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "USING ("
	infix := ")"

	colsNode := node.Cols.LogCurrentNodeWithType(depth+1, DataColumnName)

	rootIR := &SQLRightIR{
		IRType:   TypeUsingJoinCond,
		DataType: DataNone,
		LNode:    colsNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  infix,
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// Where represents a WHERE or HAVING clause.
type Where struct {
	Type string
	Expr Expr
}

// Where.Type
const (
	AstWhere  = "WHERE"
	AstHaving = "HAVING"
)

// NewWhere creates a WHERE or HAVING clause out of an Expr. If the expression
// is nil, it returns nil.
func NewWhere(typ string, expr Expr) *Where {
	if expr == nil {
		return nil
	}
	return &Where{Type: typ, Expr: expr}
}

// Format implements the NodeFormatter interface.
func (node *Where) Format(ctx *FmtCtx) {
	ctx.WriteString(node.Type)
	ctx.WriteByte(' ')
	ctx.FormatNode(node.Expr)
}

// SQLRight Code Injection.
func (node *Where) LogCurrentNode(depth int) *SQLRightIR {

	infix := " "
	typeNode := &SQLRightIR{
		IRType:      TypeUnknown,
		DataType:    DataUnknownType,
		ContextFlag: ContextUnknown,
		Prefix:      node.Type,
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
	}

	exprNode := node.Expr.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeWhere,
		DataType: DataNone,
		LNode:    typeNode,
		RNode:    exprNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// GroupBy represents a GROUP BY clause.
type GroupBy []Expr

// Format implements the NodeFormatter interface.
func (node *GroupBy) Format(ctx *FmtCtx) {
	prefix := "GROUP BY "
	for _, n := range *node {
		ctx.WriteString(prefix)
		ctx.FormatNode(n)
		prefix = ", "
	}
}

// SQLRight Code Injection.
func (node *GroupBy) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "GROUP BY "

	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{}
	for i, n := range *node {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n.LogCurrentNode(depth + 1)
			var RNode *SQLRightIR
			infix := ""
			if len(*node) >= 2 {
				infix = ", GROUP BY "
				RNode = (*node)[1].LogCurrentNode(depth + 1)
			}
			tmpIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   prefix,
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
				Infix:    ", GROUP BY",
				Suffix:   "",
				Depth:    depth,
			}
		}
	}

	// Only flag the root node for the type.
	tmpIR.IRType = TypeGroupBy
	return tmpIR
}

// DistinctOn represents a DISTINCT ON clause.
type DistinctOn []Expr

// Format implements the NodeFormatter interface.
func (node *DistinctOn) Format(ctx *FmtCtx) {
	ctx.WriteString("DISTINCT ON (")
	ctx.FormatNode((*Exprs)(node))
	ctx.WriteByte(')')
}

// SQLRight Code Injection.
func (node *DistinctOn) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "DISTINCT ON ("

	exprNode := ((*Exprs)(node)).LogCurrentNode(depth + 1)

	infix := ")"

	rootIR := &SQLRightIR{
		IRType:   TypeDistinctOn,
		DataType: DataNone,
		LNode:    exprNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// OrderBy represents an ORDER BY clause.
type OrderBy []*Order

// Format implements the NodeFormatter interface.
func (node *OrderBy) Format(ctx *FmtCtx) {
	prefix := "ORDER BY "
	for _, n := range *node {
		ctx.WriteString(prefix)
		ctx.FormatNode(n)
		prefix = ", "
	}
}

// SQLRight Code Injection.
func (node *OrderBy) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ORDER BY "

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
				Prefix:   prefix,
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
	tmpIR.IRType = TypeOrderBy
	return tmpIR
}

// Direction for ordering results.
type Direction int8

// Direction values.
const (
	DefaultDirection Direction = iota
	Ascending
	Descending
)

var directionName = [...]string{
	DefaultDirection: "",
	Ascending:        "ASC",
	Descending:       "DESC",
}

func (d Direction) String() string {
	if d < 0 || d > Direction(len(directionName)-1) {
		return fmt.Sprintf("Direction(%d)", d)
	}
	return directionName[d]
}

// NullsOrder for specifying ordering of NULLs.
type NullsOrder int8

// Null order values.
const (
	DefaultNullsOrder NullsOrder = iota
	NullsFirst
	NullsLast
)

var nullsOrderName = [...]string{
	DefaultNullsOrder: "",
	NullsFirst:        "NULLS FIRST",
	NullsLast:         "NULLS LAST",
}

func (n NullsOrder) String() string {
	if n < 0 || n > NullsOrder(len(nullsOrderName)-1) {
		return fmt.Sprintf("NullsOrder(%d)", n)
	}
	return nullsOrderName[n]
}

// OrderType indicates which type of expression is used in ORDER BY.
type OrderType int

const (
	// OrderByColumn is the regular "by expression/column" ORDER BY specification.
	OrderByColumn OrderType = iota
	// OrderByIndex enables the user to specify a given index' columns implicitly.
	OrderByIndex
)

// Order represents an ordering expression.
type Order struct {
	OrderType  OrderType
	Expr       Expr
	Direction  Direction
	NullsOrder NullsOrder
	// Table/Index replaces Expr when OrderType = OrderByIndex.
	Table TableName
	// If Index is empty, then the order should use the primary key.
	Index UnrestrictedName
}

// Format implements the NodeFormatter interface.
func (node *Order) Format(ctx *FmtCtx) {
	if node.OrderType == OrderByColumn {
		ctx.FormatNode(node.Expr)
	} else {
		if node.Index == "" {
			ctx.WriteString("PRIMARY KEY ")
			ctx.FormatNode(&node.Table)
		} else {
			ctx.WriteString("INDEX ")
			ctx.FormatNode(&node.Table)
			ctx.WriteByte('@')
			ctx.FormatNode(&node.Index)
		}
	}
	if node.Direction != DefaultDirection {
		ctx.WriteByte(' ')
		ctx.WriteString(node.Direction.String())
	}
	if node.NullsOrder != DefaultNullsOrder {
		ctx.WriteByte(' ')
		ctx.WriteString(node.NullsOrder.String())
	}
}

// SQLRight Code Injection.
func (node *Order) LogCurrentNode(depth int) *SQLRightIR {

	var rootIR *SQLRightIR

	if node.OrderType == OrderByColumn {
		exprNode := node.Expr.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    exprNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	} else {
		if node.Index == "" {
			prefix := "PRIMARY KEY "
			tableNode := node.Table.LogCurrentNode(depth + 1)

			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    tableNode,
				Prefix:   prefix,
				Infix:    "",
				Suffix:   "",
				Depth:    depth,
			}

		} else {

			prefix := "INDEX "
			infix := "@"
			tableNode := node.Table.LogCurrentNode(depth + 1)
			indexNamestr := node.Index.String()
			indexNode := &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataIndexName,
				ContextFlag: ContextUse,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         indexNamestr,
			}

			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    tableNode,
				RNode:    indexNode,
				Prefix:   prefix,
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}
		}
	}

	if node.Direction != DefaultDirection {
		infix := " "
		directionNode := &SQLRightIR{
			IRType:   TypeDirection,
			DataType: DataNone,
			Prefix:   node.Direction.String(),
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    directionNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}
	if node.NullsOrder != DefaultNullsOrder {

		infix := " "
		nullOrderNode := &SQLRightIR{
			IRType:   TypeNullsOrder,
			DataType: DataNone,
			Prefix:   node.NullsOrder.String(),
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    nullOrderNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeOrder

	return rootIR
}

// Equal checks if the node ordering is equivalent to other.
func (node *Order) Equal(other *Order) bool {
	return node.Expr.String() == other.Expr.String() && node.Direction == other.Direction &&
		node.Table == other.Table && node.OrderType == other.OrderType &&
		node.NullsOrder == other.NullsOrder
}

// Limit represents a LIMIT clause.
type Limit struct {
	Offset, Count Expr
	LimitAll      bool
}

// Format implements the NodeFormatter interface.
func (node *Limit) Format(ctx *FmtCtx) {
	needSpace := false
	if node.Count != nil {
		ctx.WriteString("LIMIT ")
		ctx.FormatNode(node.Count)
		needSpace = true
	} else if node.LimitAll {
		ctx.WriteString("LIMIT ALL")
		needSpace = true
	}
	if node.Offset != nil {
		if needSpace {
			ctx.WriteByte(' ')
		}
		ctx.WriteString("OFFSET ")
		ctx.FormatNode(node.Offset)
	}
}

// SQLRight Code Injection.
func (node *Limit) LogCurrentNode(depth int) *SQLRightIR {

	var limitCluster *SQLRightIR
	if node.Count != nil {
		countExpr := node.Count.LogCurrentNode(depth + 1)
		limitCluster = &SQLRightIR{
			IRType:   TypeLimitCluster,
			DataType: DataNone,
			LNode:    countExpr,
			Prefix:   "LIMIT ",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	} else if node.LimitAll {
		limitCluster = &SQLRightIR{
			IRType:   TypeLimitCluster,
			DataType: DataNone,
			Prefix:   "LIMIT ALL ",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	var offsetCluster *SQLRightIR
	if node.Offset != nil {
		offsetNode := node.Offset.LogCurrentNode(depth + 1)
		tmpOffsetCluster := &SQLRightIR{
			IRType:   TypeOffsetCluster,
			DataType: DataNone,
			LNode:    offsetNode,
			Prefix:   " OFFSET ",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		offsetCluster = tmpOffsetCluster
	}

	rootIR := &SQLRightIR{
		IRType:   TypeLimit,
		DataType: DataNone,
		LNode:    limitCluster,
		RNode:    offsetCluster,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// RowsFromExpr represents a ROWS FROM(...) expression.
type RowsFromExpr struct {
	Items Exprs
}

// Format implements the NodeFormatter interface.
func (node *RowsFromExpr) Format(ctx *FmtCtx) {
	ctx.WriteString("ROWS FROM (")
	ctx.FormatNode(&node.Items)
	ctx.WriteByte(')')
}

// SQLRight Code Injection.
func (node *RowsFromExpr) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ROWS FROM ("

	itemsNode := node.Items.LogCurrentNode(depth + 1)

	infix := ")"

	rootIR := &SQLRightIR{
		IRType:   TypeRowsFromExpr,
		DataType: DataNone,
		LNode:    itemsNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// Window represents a WINDOW clause.
type Window []*WindowDef

// Format implements the NodeFormatter interface.
func (node *Window) Format(ctx *FmtCtx) {
	prefix := "WINDOW "
	for _, n := range *node {
		ctx.WriteString(prefix)
		ctx.FormatNode(&n.Name)
		ctx.WriteString(" AS ")
		ctx.FormatNode(n)
		prefix = ", "
	}
}

// SQLRight Code Injection.
func (node *Window) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "WINDOW "
	infix := " AS "

	var windowNodeList []*SQLRightIR

	for _, n := range *node {

		nameStr := n.Name.String()
		nameNode := &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataWindowName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         nameStr,
		}

		RNode := n.LogCurrentNode(depth + 1)

		curWindowNode := &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    nameNode,
			RNode:    RNode,
			Prefix:   prefix,
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}

		windowNodeList = append(windowNodeList, curWindowNode)
	}

	var tmpIR *SQLRightIR
	for i, n := range windowNodeList {
		if i == 0 {
			// Take care of the first two nodes.
			LNode := n
			var RNode *SQLRightIR
			if len(*node) >= 2 {
				RNode = windowNodeList[1]
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

	// Only flag the root node for the type.
	tmpIR.IRType = TypeWindow
	return tmpIR

}

// WindowDef represents a single window definition expression.
type WindowDef struct {
	Name       Name
	RefName    Name
	Partitions Exprs
	OrderBy    OrderBy
	Frame      *WindowFrame
}

// Format implements the NodeFormatter interface.
func (node *WindowDef) Format(ctx *FmtCtx) {
	ctx.WriteByte('(')
	needSpaceSeparator := false
	if node.RefName != "" {
		ctx.FormatNode(&node.RefName)
		needSpaceSeparator = true
	}
	if len(node.Partitions) > 0 {
		if needSpaceSeparator {
			ctx.WriteByte(' ')
		}
		ctx.WriteString("PARTITION BY ")
		ctx.FormatNode(&node.Partitions)
		needSpaceSeparator = true
	}
	if len(node.OrderBy) > 0 {
		if needSpaceSeparator {
			ctx.WriteByte(' ')
		}
		ctx.FormatNode(&node.OrderBy)
		needSpaceSeparator = true
	}
	if node.Frame != nil {
		if needSpaceSeparator {
			ctx.WriteByte(' ')
		}
		ctx.FormatNode(node.Frame)
	}
	ctx.WriteRune(')')
}

// SQLRight Code Injection.
func (node *WindowDef) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "("
	var refNameNode *SQLRightIR

	if node.RefName != "" {
		refNameStr := node.RefName.String()
		tmpRefNameNode := &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataWindowName,
			ContextFlag: ContextDefine,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         refNameStr,
		}
		refNameNode = tmpRefNameNode
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    refNameNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if len(node.Partitions) > 0 {
		infix := "PARTITION BY "
		partitionNode := node.Partitions.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    partitionNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if len(node.OrderBy) > 0 {
		orderByNode := node.OrderBy.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
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

	if node.Frame != nil {
		frameNode := node.Frame.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    frameNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.Suffix = ")"
	rootIR.IRType = TypeWindowDef

	return rootIR
}

// OverrideWindowDef implements the logic to have a base window definition which
// then gets augmented by a different window definition.
func OverrideWindowDef(base *WindowDef, override WindowDef) (WindowDef, error) {
	// base.Partitions is always used.
	if len(override.Partitions) > 0 {
		return WindowDef{}, pgerror.Newf(pgcode.Windowing, "cannot override PARTITION BY clause of window %q", base.Name)
	}
	override.Partitions = base.Partitions

	// base.OrderBy is used if set.
	if len(base.OrderBy) > 0 {
		if len(override.OrderBy) > 0 {
			return WindowDef{}, pgerror.Newf(pgcode.Windowing, "cannot override ORDER BY clause of window %q", base.Name)
		}
		override.OrderBy = base.OrderBy
	}

	if base.Frame != nil {
		return WindowDef{}, pgerror.Newf(pgcode.Windowing, "cannot copy window %q because it has a frame clause", base.Name)
	}

	return override, nil
}

// WindowFrameBound specifies the offset and the type of boundary.
type WindowFrameBound struct {
	BoundType  treewindow.WindowFrameBoundType
	OffsetExpr Expr
}

// HasOffset returns whether node contains an offset.
func (node *WindowFrameBound) HasOffset() bool {
	return node.BoundType.IsOffset()
}

// WindowFrameBounds specifies boundaries of the window frame.
// The row at StartBound is included whereas the row at EndBound is not.
type WindowFrameBounds struct {
	StartBound *WindowFrameBound
	EndBound   *WindowFrameBound
}

// HasOffset returns whether node contains an offset in either of the bounds.
func (node *WindowFrameBounds) HasOffset() bool {
	return node.StartBound.HasOffset() || (node.EndBound != nil && node.EndBound.HasOffset())
}

// WindowFrame represents static state of window frame over which calculations are made.
type WindowFrame struct {
	Mode      treewindow.WindowFrameMode      // the mode of framing being used
	Bounds    WindowFrameBounds               // the bounds of the frame
	Exclusion treewindow.WindowFrameExclusion // optional frame exclusion
}

// IsDefaultFrame returns whether a frame equivalent to the default frame
// is being used (default is RANGE UNBOUNDED PRECEDING).
func (f *WindowFrame) IsDefaultFrame() bool {
	if f == nil {
		return true
	}
	if f.Bounds.StartBound.BoundType == treewindow.UnboundedPreceding {
		return f.DefaultFrameExclusion() && f.Mode == treewindow.RANGE &&
			(f.Bounds.EndBound == nil || f.Bounds.EndBound.BoundType == treewindow.CurrentRow)
	}
	return false
}

// DefaultFrameExclusion returns true if optional frame exclusion is omitted.
func (f *WindowFrame) DefaultFrameExclusion() bool {
	return f == nil || f.Exclusion == treewindow.NoExclusion
}

// Format implements the NodeFormatter interface.
func (node *WindowFrameBound) Format(ctx *FmtCtx) {
	switch node.BoundType {
	case treewindow.UnboundedPreceding:
		ctx.WriteString("UNBOUNDED PRECEDING")
	case treewindow.OffsetPreceding:
		ctx.FormatNode(node.OffsetExpr)
		ctx.WriteString(" PRECEDING")
	case treewindow.CurrentRow:
		ctx.WriteString("CURRENT ROW")
	case treewindow.OffsetFollowing:
		ctx.FormatNode(node.OffsetExpr)
		ctx.WriteString(" FOLLOWING")
	case treewindow.UnboundedFollowing:
		ctx.WriteString("UNBOUNDED FOLLOWING")
	default:
		panic(errors.AssertionFailedf("unhandled case: %d", redact.Safe(node.BoundType)))
	}
}

// SQLRight Code Injection.
func (node *WindowFrameBound) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""
	infix := ""
	suffix := ""
	var LNode *SQLRightIR
	switch node.BoundType {
	case treewindow.UnboundedPreceding:
		prefix = " UNBOUNDED PRECEDING "
	case treewindow.OffsetPreceding:
		LNode = node.OffsetExpr.LogCurrentNode(depth + 1)
		infix = " PRECEDING"
	case treewindow.CurrentRow:
		prefix = "CURRENT ROW"
	case treewindow.OffsetFollowing:
		LNode = node.OffsetExpr.LogCurrentNode(depth + 1)
		infix = " FOLLOWING"
	case treewindow.UnboundedFollowing:
		prefix = "UNBOUNDED FOLLOWING"
	default:
		panic(errors.AssertionFailedf("unhandled case: %d", redact.Safe(node.BoundType)))
	}

	rootIR := &SQLRightIR{
		IRType:   TypeWindowFrameBound,
		DataType: DataNone,
		LNode:    LNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   suffix,
		Depth:    depth,
	}
	return rootIR
}

// Format implements the NodeFormatter interface.
func (f *WindowFrame) Format(ctx *FmtCtx) {
	ctx.WriteString(treewindow.WindowModeName(f.Mode))
	ctx.WriteByte(' ')
	if f.Bounds.EndBound != nil {
		ctx.WriteString("BETWEEN ")
		ctx.FormatNode(f.Bounds.StartBound)
		ctx.WriteString(" AND ")
		ctx.FormatNode(f.Bounds.EndBound)
	} else {
		ctx.FormatNode(f.Bounds.StartBound)
	}
	if f.Exclusion != treewindow.NoExclusion {
		ctx.WriteByte(' ')
		ctx.WriteString(f.Exclusion.String())
	}
}

// SQLRight Code Injection.
func (node *WindowFrame) LogCurrentNode(depth int) *SQLRightIR {
	windowFrameMode := &SQLRightIR{
		IRType:   TypeWindowFrameMode,
		DataType: DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
		Str:      node.Mode.String(),
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    windowFrameMode,
		Prefix:   "",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	if node.Bounds.EndBound != nil {
		prefix := "BETWEEN "
		startBountNode := node.Bounds.StartBound.LogCurrentNode(depth + 1)
		infix := " AND "
		endBoutnNode := node.Bounds.EndBound.LogCurrentNode(depth + 1)

		boundsCluster := &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    startBountNode,
			RNode:    endBoutnNode,
			Prefix:   prefix,
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    boundsCluster,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}

	} else {
		startBountNode := node.Bounds.StartBound.LogCurrentNode(depth + 1)
		boundsCluster := &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    startBountNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    boundsCluster,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}
	if node.Exclusion != treewindow.NoExclusion {
		exclusionStr := node.Exclusion.String()
		exclusionNode := &SQLRightIR{
			IRType:   TypeWindowFrameExclusion,
			DataType: DataNone,
			Prefix:   exclusionStr,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    exclusionNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeWindowFrame
	return rootIR
}

// LockingClause represents a locking clause, like FOR UPDATE.
type LockingClause []*LockingItem

// Format implements the NodeFormatter interface.
func (node *LockingClause) Format(ctx *FmtCtx) {
	for _, n := range *node {
		ctx.FormatNode(n)
	}
}

// SQLRight Code Injection.
func (node *LockingClause) LogCurrentNode(depth int) *SQLRightIR {
	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

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
			LNode := tmpIR
			RNode := n.LogCurrentNode(depth + 1)

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

	// Only flag the root node for the type.
	tmpIR.IRType = TypeLockingClause
	return tmpIR
}

// LockingItem represents a single locking item in a locking clause.
type LockingItem struct {
	Strength   LockingStrength
	Targets    TableNames
	WaitPolicy LockingWaitPolicy
}

// Format implements the NodeFormatter interface.
func (f *LockingItem) Format(ctx *FmtCtx) {
	ctx.FormatNode(f.Strength)
	if len(f.Targets) > 0 {
		ctx.WriteString(" OF ")
		ctx.FormatNode(&f.Targets)
	}
	ctx.FormatNode(f.WaitPolicy)
}

// SQLRight Code Injection.
func (node *LockingItem) LogCurrentNode(depth int) *SQLRightIR {

	strengthNode := node.Strength.LogCurrentNode(depth + 1)

	infix := ""
	var targetNode *SQLRightIR
	if len(node.Targets) > 0 {
		infix = " OF "
		targetNode = node.Targets.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    strengthNode,
		RNode:    targetNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	waitPolicyStr := node.WaitPolicy.String()
	waitPolicyNode := &SQLRightIR{
		IRType:   TypeWaitPolicy,
		DataType: DataNone,
		Prefix:   waitPolicyStr,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	rootIR = &SQLRightIR{
		IRType:   TypeLockingItem,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    waitPolicyNode,
		Prefix:   "",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// LockingStrength represents the possible row-level lock modes for a SELECT
// statement.
type LockingStrength byte

// The ordering of the variants is important, because the highest numerical
// value takes precedence when row-level locking is specified multiple ways.
const (
	// ForNone represents the default - no for statement at all.
	// LockingItem AST nodes are never created with this strength.
	ForNone LockingStrength = iota
	// ForKeyShare represents FOR KEY SHARE.
	ForKeyShare
	// ForShare represents FOR SHARE.
	ForShare
	// ForNoKeyUpdate represents FOR NO KEY UPDATE.
	ForNoKeyUpdate
	// ForUpdate represents FOR UPDATE.
	ForUpdate
)

var lockingStrengthName = [...]string{
	ForNone:        "",
	ForKeyShare:    "FOR KEY SHARE",
	ForShare:       "FOR SHARE",
	ForNoKeyUpdate: "FOR NO KEY UPDATE",
	ForUpdate:      "FOR UPDATE",
}

func (s LockingStrength) String() string {
	return lockingStrengthName[s]
}

// Format implements the NodeFormatter interface.
func (s LockingStrength) Format(ctx *FmtCtx) {
	if s != ForNone {
		ctx.WriteString(" ")
		ctx.WriteString(s.String())
	}
}

// SQLRight Code Injection.
func (node LockingStrength) LogCurrentNode(depth int) *SQLRightIR {
	prefix := ""
	if node != ForNone {
		prefix += " "
		prefix += node.String()
	}
	rootIR := &SQLRightIR{
		IRType:   TypeLockingStrength,
		DataType: DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}
	return rootIR
}

// Max returns the maximum of the two locking strengths.
func (s LockingStrength) Max(s2 LockingStrength) LockingStrength {
	return LockingStrength(max(byte(s), byte(s2)))
}

// LockingWaitPolicy represents the possible policies for handling conflicting
// locks held by other active transactions when attempting to lock rows due to
// FOR UPDATE/SHARE clauses (i.e. it represents the NOWAIT and SKIP LOCKED
// options).
type LockingWaitPolicy byte

// The ordering of the variants is important, because the highest numerical
// value takes precedence when row-level locking is specified multiple ways.
const (
	// LockWaitBlock represents the default - wait for the lock to become
	// available.
	LockWaitBlock LockingWaitPolicy = iota
	// LockWaitSkipLocked represents SKIP LOCKED - skip rows that can't be locked.
	LockWaitSkipLocked
	// LockWaitError represents NOWAIT - raise an error if a row cannot be
	// locked.
	LockWaitError
)

var lockingWaitPolicyName = [...]string{
	LockWaitBlock:      "",
	LockWaitSkipLocked: "SKIP LOCKED",
	LockWaitError:      "NOWAIT",
}

func (p LockingWaitPolicy) String() string {
	return lockingWaitPolicyName[p]
}

// Format implements the NodeFormatter interface.
func (p LockingWaitPolicy) Format(ctx *FmtCtx) {
	if p != LockWaitBlock {
		ctx.WriteString(" ")
		ctx.WriteString(p.String())
	}
}

// SQLRight Code Injection.
func (node LockingWaitPolicy) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""
	if node != LockWaitBlock {
		prefix += " "
		prefix += node.String()
	}

	rootIR := &SQLRightIR{
		IRType:   TypeLockingWaitPolicy,
		DataType: DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// Max returns the maximum of the two locking wait policies.
func (p LockingWaitPolicy) Max(p2 LockingWaitPolicy) LockingWaitPolicy {
	return LockingWaitPolicy(max(byte(p), byte(p2)))
}

func max(a, b byte) byte {
	if a > b {
		return a
	}
	return b
}
