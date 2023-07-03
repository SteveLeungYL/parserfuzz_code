// Copyright 2021 The Cockroach Authors.
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

// CommentOnSchema represents an COMMENT ON SCHEMA statement.
type CommentOnSchema struct {
	Name    ObjectNamePrefix
	Comment *string
}

// Format implements the NodeFormatter interface.
func (n *CommentOnSchema) Format(ctx *FmtCtx) {
	ctx.WriteString("COMMENT ON SCHEMA ")
	ctx.FormatNode(&n.Name)
	ctx.WriteString(" IS ")
	if n.Comment != nil {
		// TODO(knz): Replace all this with ctx.FormatNode
		// when COMMENT supports expressions.
		if ctx.flags.HasFlags(FmtHideConstants) {
			ctx.WriteByte('_')
		} else {
			lexbase.EncodeSQLStringWithFlags(&ctx.Buffer, *n.Comment, ctx.flags.EncodeFlags())
		}
	} else {
		ctx.WriteString("NULL")
	}
}

// SQLRight Code Injection.
func (node *CommentOnSchema) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "COMMENT ON SCHEMA "

	schemaNode := &SQLRightIR{
		NodeHash:    144284,
		IRType:      TypeIdentifier,
		DataType:    DataSchemaName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Name.String(),
	}

	rootIR := &SQLRightIR{
		NodeHash: 136541,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    schemaNode,
		Prefix:   prefix,
		Infix:    " IS ",
		Suffix:   "",
		Depth:    depth,
	}

	commentStr := ""
	if node.Comment != nil {
		commentStr = *(node.Comment)
	}
	commentNode := &SQLRightIR{
		NodeHash: 261789,
		IRType:   TypeStringLiteral,
		DataType: DataLiteral,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
		Str:      "'" + commentStr + "'",
	}

	rootIR = &SQLRightIR{
		NodeHash: 182122,
		IRType:   TypeCommentOnSchema,
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
