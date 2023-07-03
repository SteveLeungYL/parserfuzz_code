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

// ReturningClause represents the returning clause on a statement.
type ReturningClause interface {
	NodeFormatter
	// statementReturnType returns the StatementReturnType of statements that include
	// the implementors variant of a RETURNING clause.
	statementReturnType() StatementReturnType
	returningClause()

	SQLRightInterface
}

var _ ReturningClause = &ReturningExprs{}
var _ ReturningClause = &ReturningNothing{}
var _ ReturningClause = &NoReturningClause{}

// ReturningExprs represents RETURNING expressions.
type ReturningExprs SelectExprs

// Format implements the NodeFormatter interface.
func (r *ReturningExprs) Format(ctx *FmtCtx) {
	ctx.WriteString("RETURNING ")
	ctx.FormatNode((*SelectExprs)(r))
}

// SQLRight Code Injection.
func (node *ReturningExprs) LogCurrentNode(depth int) *SQLRightIR {

	prefix := " RETURNING "

	selectStmt := (*SelectExprs)(node).LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		NodeHash: 9383,
		IRType:   TypeReturningExprs,
		DataType: DataNone,
		LNode:    selectStmt,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ReturningNothingClause is a shared instance to avoid unnecessary allocations.
var ReturningNothingClause = &ReturningNothing{}

// ReturningNothing represents RETURNING NOTHING.
type ReturningNothing struct{}

// Format implements the NodeFormatter interface.
func (*ReturningNothing) Format(ctx *FmtCtx) {
	ctx.WriteString("RETURNING NOTHING")
}

// SQLRight Code Injection.
func (node *ReturningNothing) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "RETURNING NOTHING"

	rootIR := &SQLRightIR{
		NodeHash: 76606,
		IRType:   TypeReturningNothing,
		DataType: DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AbsentReturningClause is a ReturningClause variant representing the absence of
// a RETURNING clause.
var AbsentReturningClause = &NoReturningClause{}

// NoReturningClause represents the absence of a RETURNING clause.
type NoReturningClause struct{}

// Format implements the NodeFormatter interface.
func (*NoReturningClause) Format(_ *FmtCtx) {}

// SQLRight Code Injection.
func (node *NoReturningClause) LogCurrentNode(depth int) *SQLRightIR {

	rootIR := &SQLRightIR{
		NodeHash: 54589,
		IRType:   TypeNoReturningClause,
		DataType: DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// used by parent statements to determine their own StatementReturnType.
func (*ReturningExprs) statementReturnType() StatementReturnType    { return Rows }
func (*ReturningNothing) statementReturnType() StatementReturnType  { return RowsAffected }
func (*NoReturningClause) statementReturnType() StatementReturnType { return RowsAffected }

func (*ReturningExprs) returningClause()    {}
func (*ReturningNothing) returningClause()  {}
func (*NoReturningClause) returningClause() {}

// HasReturningClause determines if a ReturningClause is present, given a
// variant of the ReturningClause interface.
func HasReturningClause(clause ReturningClause) bool {
	_, ok := clause.(*NoReturningClause)
	return !ok
}
