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

import "github.com/cockroachdb/cockroach/pkg/sql/lexbase"

// CommentOnColumn represents an COMMENT ON COLUMN statement.
type CommentOnColumn struct {
	*ColumnItem
	Comment *string
}

// Format implements the NodeFormatter interface.
func (n *CommentOnColumn) Format(ctx *FmtCtx) {
	ctx.WriteString("COMMENT ON COLUMN ")
	ctx.FormatNode(n.ColumnItem)
	ctx.WriteString(" IS ")
	if n.Comment != nil {
		// TODO(knz): Replace all this with ctx.FormatNode
		// when COMMENT supports expressions.
		if ctx.flags.HasFlags(FmtHideConstants) {
			ctx.WriteString("'_'")
		} else {
			lexbase.EncodeSQLStringWithFlags(&ctx.Buffer, *n.Comment, ctx.flags.EncodeFlags())
		}
	} else {
		ctx.WriteString("NULL")
	}
}

// SQLRight Code Injection.
func (node *CommentOnColumn) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "COMMENT ON COLUMN "

	columnItemNode := node.ColumnItem.LogCurrentNode(depth + 1)

	infix := " IS "

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    columnItemNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	prefix = ""
	infix = ""

	var commentNode *SQLRightIR
	if node.Comment != nil {
		commentNode = &SQLRightIR{
			IRType:   TypeStringLiteral,
			DataType: DataNone, // TODO: FIXME: Data type unknown.
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
			Str:      "'" + *node.Comment + "'",
		}
	} else {
		commentNode = &SQLRightIR{
			IRType:   TypeStringLiteral,
			DataType: DataNone, // TODO: FIXME: Data type unknown.
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
			Str:      "NULL",
		}
	}

	rootIR = &SQLRightIR{
		IRType:   TypeCommentOnColumn,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    commentNode,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}
