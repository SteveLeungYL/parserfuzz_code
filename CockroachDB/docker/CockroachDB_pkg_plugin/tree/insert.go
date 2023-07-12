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

// Insert represents an INSERT statement.
type Insert struct {
	With       *With
	Table      TableExpr
	Columns    NameList
	Rows       *Select
	OnConflict *OnConflict
	Returning  ReturningClause
}

// Format implements the NodeFormatter interface.
func (node *Insert) Format(ctx *FmtCtx) {
	ctx.FormatNode(node.With)
	if node.OnConflict.IsUpsertAlias() {
		ctx.WriteString("UPSERT")
	} else {
		ctx.WriteString("INSERT")
	}
	ctx.WriteString(" INTO ")
	ctx.FormatNode(node.Table)
	if node.Columns != nil {
		ctx.WriteByte('(')
		ctx.FormatNode(&node.Columns)
		ctx.WriteByte(')')
	}
	if node.DefaultValues() {
		ctx.WriteString(" DEFAULT VALUES")
	} else {
		ctx.WriteByte(' ')
		ctx.FormatNode(node.Rows)
	}
	if node.OnConflict != nil && !node.OnConflict.IsUpsertAlias() {
		ctx.WriteString(" ON CONFLICT")
		if node.OnConflict.Constraint != "" {
			ctx.WriteString(" ON CONSTRAINT ")
			ctx.FormatNode(&node.OnConflict.Constraint)
		}
		if len(node.OnConflict.Columns) > 0 {
			ctx.WriteString(" (")
			ctx.FormatNode(&node.OnConflict.Columns)
			ctx.WriteString(")")
		}
		if node.OnConflict.ArbiterPredicate != nil {
			ctx.WriteString(" WHERE ")
			ctx.FormatNode(node.OnConflict.ArbiterPredicate)
		}
		if node.OnConflict.DoNothing {
			ctx.WriteString(" DO NOTHING")
		} else {
			ctx.WriteString(" DO UPDATE SET ")
			ctx.FormatNode(&node.OnConflict.Exprs)
			if node.OnConflict.Where != nil {
				ctx.WriteByte(' ')
				ctx.FormatNode(node.OnConflict.Where)
			}
		}
	}
	if HasReturningClause(node.Returning) {
		ctx.WriteByte(' ')
		ctx.FormatNode(node.Returning)
	}
}

// SQLRight Code Injection.
func (node *Insert) LogCurrentNode(depth int) *SQLRightIR {

	withNode := node.With.LogCurrentNode(depth + 1)

	infix := ""
	if node.OnConflict.IsUpsertAlias() {
		infix += "UPSERT"
	} else {
		infix += "INSERT"
	}
	infix += " INTO "

	tableNode := node.Table.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		NodeHash: 184983,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    withNode,
		RNode:    tableNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	if node.Columns != nil {
		infix = "("
		suffix := ")"
		columnNode := node.Columns.LogCurrentNodeWithType(depth+1, DataColumnName)

		rootIR = &SQLRightIR{
			NodeHash: 14557,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    columnNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   suffix,
			Depth:    depth,
		}
	}

	if node.DefaultValues() {
		tmpInfix := " DEFAULT VALUES"
		rootIR = &SQLRightIR{
			NodeHash: 123422,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			Prefix:   "",
			Infix:    tmpInfix,
			Suffix:   "",
			Depth:    depth,
		}
	} else {
		tmpInfix := " "
		rowNode := node.Rows.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			NodeHash: 200014,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    rowNode,
			Prefix:   "",
			Infix:    tmpInfix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.OnConflict != nil && !node.OnConflict.IsUpsertAlias() {
		infix = " ON CONFLICT"
		var constraintName *SQLRightIR
		if node.OnConflict.Constraint != "" {
			infix += " ON CONSTRAINT "
			constraintName = &SQLRightIR{
				NodeHash:    85048,
				IRType:      TypeIdentifier,
				DataType:    DataConstraintName,
				ContextFlag: ContextUse,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         node.OnConflict.Constraint.String(),
			}
		}
		rootIR = &SQLRightIR{
			NodeHash: 135481,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    constraintName,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
		if len(node.OnConflict.Columns) > 0 {
			infix = " ("
			suffix := ")"
			columnNode := node.OnConflict.Columns.LogCurrentNodeWithType(depth+1, DataColumnName)
			rootIR = &SQLRightIR{
				NodeHash: 25037,
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    columnNode,
				Prefix:   "",
				Infix:    infix,
				Suffix:   suffix,
				Depth:    depth,
			}
		}
		if node.OnConflict.ArbiterPredicate != nil {
			infix = " WHERE "
			predicateNode := node.OnConflict.ArbiterPredicate.LogCurrentNode(depth + 1)

			rootIR = &SQLRightIR{
				NodeHash: 147470,
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    predicateNode,
				Prefix:   "",
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}
		}
		if node.OnConflict.DoNothing {
			infix = " DO NOTHING"

			rootIR = &SQLRightIR{
				NodeHash: 197772,
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				Prefix:   "",
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}
		} else {

			infix = " DO UPDATE SET "
			exprsNode := node.OnConflict.Exprs.LogCurrentNode(depth + 1)

			rootIR = &SQLRightIR{
				NodeHash: 170911,
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    exprsNode,
				Prefix:   "",
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}

			if node.OnConflict.Where != nil {
				infix = " "
				whereNode := node.OnConflict.Where.LogCurrentNode(depth + 1)

				rootIR = &SQLRightIR{
					NodeHash: 119704,
					IRType:   TypeUnknown,
					DataType: DataNone,
					LNode:    rootIR,
					RNode:    whereNode,
					Prefix:   "",
					Infix:    infix,
					Suffix:   "",
					Depth:    depth,
				}
			}
		}
	}

	rootIR.NodeHash = 105505
	rootIR.IRType = TypeInsert
	return rootIR
}

// DefaultValues returns true iff only default values are being inserted.
func (node *Insert) DefaultValues() bool {
	return node.Rows.Select == nil
}

// OnConflict represents an `ON CONFLICT (columns) WHERE arbiter DO UPDATE SET
// exprs WHERE where` clause.
//
// The zero value for OnConflict is used to signal the UPSERT short form, which
// uses the primary key for as the conflict index and the values being inserted
// for Exprs.
type OnConflict struct {
	// At most one of Columns and Constraint will be set at once.
	// Columns is the list of arbiter columns, if set, that the user specified
	// in the ON CONFLICT (columns) list.
	Columns NameList
	// Constraint is the name of a table constraint that the user specified to
	// get the list of arbiter columns from, in the ON CONFLICT ON CONSTRAINT
	// form.
	Constraint       Name
	ArbiterPredicate Expr
	Exprs            UpdateExprs
	Where            *Where
	DoNothing        bool
}

// IsUpsertAlias returns true if the UPSERT syntactic sugar was used.
func (oc *OnConflict) IsUpsertAlias() bool {
	return oc != nil && oc.Columns == nil && oc.Constraint == "" &&
		oc.ArbiterPredicate == nil && oc.Exprs == nil && oc.Where == nil && !oc.DoNothing
}
