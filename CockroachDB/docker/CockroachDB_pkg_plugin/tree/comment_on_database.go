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

// CommentOnDatabase represents an COMMENT ON DATABASE statement.
type CommentOnDatabase struct {
	Name    Name
	Comment *string
}

// Format implements the NodeFormatter interface.
func (n *CommentOnDatabase) Format(ctx *FmtCtx) {
	ctx.WriteString("COMMENT ON DATABASE ")
	ctx.FormatNode(&n.Name)
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
func (node *CommentOnDatabase) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "COMMENT ON DATABASE "

	databaseNode := &SQLRightIR{
		NodeHash:    32011,
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Name.String(),
	}

	rootIR := &SQLRightIR{
		NodeHash: 208814,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    databaseNode,
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
		NodeHash: 4438,
		IRType:   TypeStringLiteral,
		DataType: DataLiteral,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
		Str:      "'" + commentStr + "'",
	}

	rootIR = &SQLRightIR{
		NodeHash: 126323,
		IRType:   TypeCommentOnDatabase,
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
