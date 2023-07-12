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

// Import represents a IMPORT statement.
type Import struct {
	Table      *TableName
	Into       bool
	IntoCols   NameList
	FileFormat string
	Files      Exprs
	Bundle     bool
	Options    KVOptions
}

var _ Statement = &Import{}

// Format implements the NodeFormatter interface.
func (node *Import) Format(ctx *FmtCtx) {
	ctx.WriteString("IMPORT ")

	if node.Bundle {
		if node.Table != nil {
			ctx.WriteString("TABLE ")
			ctx.FormatNode(node.Table)
			ctx.WriteString(" FROM ")
		}
		ctx.WriteString(node.FileFormat)
		ctx.WriteByte(' ')
		ctx.FormatNode(&node.Files)
	} else {
		if node.Into {
			ctx.WriteString("INTO ")
			ctx.FormatNode(node.Table)
			if node.IntoCols != nil {
				ctx.WriteByte('(')
				ctx.FormatNode(&node.IntoCols)
				ctx.WriteString(") ")
			} else {
				ctx.WriteString(" ")
			}
		} else {
			ctx.WriteString("TABLE ")
			ctx.FormatNode(node.Table)
		}
		ctx.WriteString(node.FileFormat)
		ctx.WriteString(" DATA (")
		ctx.FormatNode(&node.Files)
		ctx.WriteString(")")
	}

	if node.Options != nil {
		ctx.WriteString(" WITH ")
		ctx.FormatNode(&node.Options)
	}
}

// SQLRight Code Injection.
func (node *Import) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "IMPORT "
	infix := ""

	var rootIR *SQLRightIR
	if node.Bundle {
		var tableNode *SQLRightIR
		if node.Table != nil {
			prefix += "TABLE "
			tableNode = node.Table.LogCurrentNode(depth)
			infix = " FROM "
		}

		rootIR = &SQLRightIR{
			NodeHash: 228428,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    tableNode,
			Prefix:   prefix,
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
		prefix = ""
		infix = ""

		fileFormat := &SQLRightIR{
			NodeHash: 124318,
			IRType:   TypeFileFormat,
			DataType: DataNone, // TODO: FIXME: Data type unknown.
			Prefix:   node.FileFormat,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		rootIR = &SQLRightIR{
			NodeHash: 201403,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    fileFormat,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}

		filesNode := node.Files.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			NodeHash: 232493,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    filesNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	} else {
		if node.Into {
			prefix += "INTO "
			tableNode := node.Table.LogCurrentNode(depth + 1)

			suffix := ""
			var colNode *SQLRightIR
			if node.IntoCols != nil {
				infix = "("
				colNode = node.IntoCols.LogCurrentNodeWithType(depth+1, DataColumnName)
				suffix = ")"
			} else {
				infix = " "
			}

			rootIR = &SQLRightIR{
				NodeHash: 154345,
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    tableNode,
				RNode:    colNode,
				Prefix:   prefix,
				Infix:    infix,
				Suffix:   suffix,
				Depth:    depth,
			}
		} else {

			prefix += "TABLE "
			tableNode := node.Table.LogCurrentNode(depth + 1)

			rootIR = &SQLRightIR{
				NodeHash: 127885,
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    tableNode,
				Prefix:   prefix,
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}
		}
		prefix = ""
		infix = ""

		fileFormatNode := &SQLRightIR{
			NodeHash: 71781,
			IRType:   TypeFileFormat,
			DataType: DataNone, // TODO: FIXME: Data type unknown.
			Prefix:   node.FileFormat,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		rootIR = &SQLRightIR{
			NodeHash: 206427,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    fileFormatNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		fileNode := node.Files.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			NodeHash: 90583,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    fileNode,
			Prefix:   "",
			Infix:    " DATA (",
			Suffix:   ")",
			Depth:    depth,
		}
	}

	if node.Options != nil {
		infix = " WITH "
		optionNode := node.Options.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			NodeHash: 80662,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optionNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.NodeHash = 64285
	rootIR.IRType = TypeImport

	return rootIR
}
