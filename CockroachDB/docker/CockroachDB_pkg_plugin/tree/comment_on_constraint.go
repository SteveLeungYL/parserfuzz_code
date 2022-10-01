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

// CommentOnConstraint represents a COMMENT ON CONSTRAINT statement
type CommentOnConstraint struct {
	Constraint Name
	Table      *UnresolvedObjectName
	Comment    *string
}

// Format implements the NodeFormatter interface.
func (n *CommentOnConstraint) Format(ctx *FmtCtx) {
	ctx.WriteString("COMMENT ON CONSTRAINT ")
	ctx.FormatNode(&n.Constraint)
	ctx.WriteString(" ON ")
	ctx.FormatNode(n.Table)
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
func (node *CommentOnConstraint) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "COMMENT ON CONSTRAINT "

	constraintNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataConstraintName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Constraint.String(),
	}

	infix := " ON "

	tableNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataTableName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Table.String(),
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    constraintNode,
		RNode:    tableNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   " IS ",
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
		IRType:   TypeCommentOnConstraint,
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
