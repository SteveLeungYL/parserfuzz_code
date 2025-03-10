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

// Split represents an `ALTER TABLE/INDEX .. SPLIT AT ..` statement.
type Split struct {
	TableOrIndex TableIndexName
	// Each row contains values for the columns in the PK or index (or a prefix
	// of the columns).
	Rows *Select
	// Splits can last a specified amount of time before becoming eligible for
	// automatic merging.
	ExpireExpr Expr
}

// Format implements the NodeFormatter interface.
func (node *Split) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER ")
	if node.TableOrIndex.Index != "" {
		ctx.WriteString("INDEX ")
	} else {
		ctx.WriteString("TABLE ")
	}
	ctx.FormatNode(&node.TableOrIndex)
	ctx.WriteString(" SPLIT AT ")
	ctx.FormatNode(node.Rows)
	if node.ExpireExpr != nil {
		ctx.WriteString(" WITH EXPIRATION ")
		ctx.FormatNode(node.ExpireExpr)
	}
}

// SQLRight Code Injection.
func (node *Split) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ALTER "

	if node.TableOrIndex.Index != "" {
		prefix += "INDEX "
	} else {
		prefix += "TABLE "
	}

	nameNode := node.TableOrIndex.LogCurrentNode(depth + 1)

	infix := "SPLIT AT "

	rowNode := node.Rows.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		NodeHash: 147428,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    nameNode,
		RNode:    rowNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	if node.ExpireExpr != nil {
		infix = " WITH EXPIRATION "
		expireNode := node.ExpireExpr.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			NodeHash: 132305,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    expireNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.NodeHash = 80400
	rootIR.IRType = TypeSplit

	return rootIR
}

// Unsplit represents an `ALTER TABLE/INDEX .. UNSPLIT AT ..` statement.
type Unsplit struct {
	TableOrIndex TableIndexName
	// Each row contains values for the columns in the PK or index (or a prefix
	// of the columns).
	Rows *Select
	All  bool
}

// Format implements the NodeFormatter interface.
func (node *Unsplit) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER ")
	if node.TableOrIndex.Index != "" {
		ctx.WriteString("INDEX ")
	} else {
		ctx.WriteString("TABLE ")
	}
	ctx.FormatNode(&node.TableOrIndex)
	if node.All {
		ctx.WriteString(" UNSPLIT ALL")
	} else {
		ctx.WriteString(" UNSPLIT AT ")
		ctx.FormatNode(node.Rows)
	}
}

// SQLRight Code Injection.
func (node *Unsplit) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ALTER "

	if node.TableOrIndex.Index != "" {
		prefix += "INDEX "
	} else {
		prefix += "TABLE "
	}

	nameNode := node.TableOrIndex.LogCurrentNode(depth + 1)

	var rowsNode *SQLRightIR

	infix := ""
	if node.All {
		infix = " UNSPLIT ALL"
	} else {
		infix = " UNSPLIT AT "
		rowsNode = node.Rows.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		NodeHash: 117768,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    nameNode,
		RNode:    rowsNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	rootIR.NodeHash = 27207
	rootIR.IRType = TypeUnsplit

	return rootIR
}

// Relocate represents an `ALTER TABLE/INDEX .. EXPERIMENTAL_RELOCATE ..`
// statement.
type Relocate struct {
	// TODO(a-robinson): It's not great that this can only work on ranges that
	// are part of a currently valid table or index.
	TableOrIndex TableIndexName
	// Each row contains an array with store ids and values for the columns in the
	// PK or index (or a prefix of the columns).
	// See docs/RFCS/sql_split_syntax.md.
	Rows            *Select
	SubjectReplicas RelocateSubject
}

// Format implements the NodeFormatter interface.
func (node *Relocate) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER ")
	if node.TableOrIndex.Index != "" {
		ctx.WriteString("INDEX ")
	} else {
		ctx.WriteString("TABLE ")
	}
	ctx.FormatNode(&node.TableOrIndex)
	ctx.WriteString(" RELOCATE ")
	ctx.FormatNode(&node.SubjectReplicas)
	ctx.WriteByte(' ')
	ctx.FormatNode(node.Rows)
}

// SQLRight Code Injection.
func (node *Relocate) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ALTER "

	if node.TableOrIndex.Index != "" {
		prefix += "INDEX "
	} else {
		prefix += "TABLE "
	}

	nameNode := node.TableOrIndex.LogCurrentNode(depth + 1)

	infix := " RELOCATE "

	subjectNode := node.SubjectReplicas.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		NodeHash: 181741,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    nameNode,
		RNode:    subjectNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	infix = " "

	rowsNode := node.Rows.LogCurrentNode(depth + 1)

	rootIR = &SQLRightIR{
		NodeHash: 61312,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    rowsNode,
		Prefix:   "",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	rootIR.NodeHash = 116178
	rootIR.IRType = TypeRelocate

	return rootIR
}

// Scatter represents an `ALTER TABLE/INDEX .. SCATTER ..`
// statement.
type Scatter struct {
	TableOrIndex TableIndexName
	// Optional from and to values for the columns in the PK or index (or a prefix
	// of the columns).
	// See docs/RFCS/sql_split_syntax.md.
	From, To Exprs
}

// Format implements the NodeFormatter interface.
func (node *Scatter) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER ")
	if node.TableOrIndex.Index != "" {
		ctx.WriteString("INDEX ")
	} else {
		ctx.WriteString("TABLE ")
	}
	ctx.FormatNode(&node.TableOrIndex)
	ctx.WriteString(" SCATTER")
	if node.From != nil {
		ctx.WriteString(" FROM (")
		ctx.FormatNode(&node.From)
		ctx.WriteString(") TO (")
		ctx.FormatNode(&node.To)
		ctx.WriteString(")")
	}
}

// SQLRight Code Injection.
func (node *Scatter) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ALTER "

	if node.TableOrIndex.Index != "" {
		prefix += "INDEX "
	} else {
		prefix += "TABLE "
	}

	nameNode := node.TableOrIndex.LogCurrentNode(depth + 1)

	infix := " SCATTER"

	rootIR := &SQLRightIR{
		NodeHash: 48399,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    nameNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	infix = ""
	if node.From != nil {
		infix = " FROM ("

		fromNode := node.From.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			NodeHash: 168716,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    fromNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}

		infix = ") TO ("

		toNode := node.To.LogCurrentNode(depth + 1)

		suffix := ")"

		rootIR = &SQLRightIR{
			NodeHash: 58921,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    toNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   suffix,
			Depth:    depth,
		}
	}

	rootIR.NodeHash = 187782
	rootIR.IRType = TypeScatter

	return rootIR
}
