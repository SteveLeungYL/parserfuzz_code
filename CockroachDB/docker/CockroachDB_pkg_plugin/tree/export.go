// Copyright 2018 The Cockroach Authors.
//
// Use of this software is governed by the Business Source License
// included in the file licenses/BSL.txt.
//
// As of the Change Date specified in that file, in accordance with
// the Business Source License, use of this software will be governed
// by the Apache License, Version 2.0, included in the file
// licenses/APL.txt.

package tree

// Export represents a EXPORT statement.
type Export struct {
	Query      *Select
	FileFormat string
	File       Expr
	Options    KVOptions
}

var _ Statement = &Export{}

// Format implements the NodeFormatter interface.
func (node *Export) Format(ctx *FmtCtx) {
	ctx.WriteString("EXPORT INTO ")
	ctx.WriteString(node.FileFormat)
	ctx.WriteString(" ")
	ctx.FormatNode(node.File)
	if node.Options != nil {
		ctx.WriteString(" WITH ")
		ctx.FormatNode(&node.Options)
	}
	ctx.WriteString(" FROM ")
	ctx.FormatNode(node.Query)
}

// SQLRight Code Injection.
func (node *Export) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "EXPORT INTO "

	fileFormatNode := &SQLRightIR{
		IRType:   TypeFileFormat,
		DataType: DataNone,
		Prefix:   node.FileFormat,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	infix := " "

	var pOptionNode *SQLRightIR
	if node.Options != nil {
		infix += "WITH "
		pOptionNode = node.Options.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    fileFormatNode,
		RNode:    pOptionNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	infix = " FROM "

	fromNode := node.Query.LogCurrentNode(depth + 1)

	rootIR = &SQLRightIR{
		IRType:   TypeExport,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    fromNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}
