// Copyright 2019 The Cockroach Authors.
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

// CommentOnIndex represents a COMMENT ON INDEX statement.
type CommentOnIndex struct {
	Index   TableIndexName
	Comment *string
}

// Format implements the NodeFormatter interface.
func (n *CommentOnIndex) Format(ctx *FmtCtx) {
	ctx.WriteString("COMMENT ON INDEX ")
	ctx.FormatNode(&n.Index)
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
func (node *CommentOnIndex) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "COMMENT ON INDEX "

	indexNode := node.Index.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    indexNode,
		Prefix:   prefix,
		Infix:    " IS ",
		Suffix:   "",
		Depth:    depth,
	}

	commentStr := *(node.Comment)
	commentNode := &SQLRightIR{
		IRType:   TypeStringLiteral,
		DataType: DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
		Str:      commentStr,
	}

	rootIR = &SQLRightIR{
		IRType:   TypeCommentOnIndex,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    commentNode,
		Prefix:   "",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}
