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

import (
	"github.com/cockroachdb/cockroach/pkg/sql/pgwire/pgcode"
	"github.com/cockroachdb/cockroach/pkg/sql/pgwire/pgerror"
)

// CreateChangefeed represents a CREATE CHANGEFEED statement.
type CreateChangefeed struct {
	Targets ChangefeedTargets
	SinkURI Expr
	Options KVOptions
	Select  *SelectClause
}

var _ Statement = &CreateChangefeed{}

// Format implements the NodeFormatter interface.
func (node *CreateChangefeed) Format(ctx *FmtCtx) {
	if node.Select != nil {
		node.formatWithPredicates(ctx)
		return
	}

	if node.SinkURI != nil {
		ctx.WriteString("CREATE ")
	} else {
		// Sinkless feeds don't really CREATE anything, so the syntax omits the
		// prefix. They're also still EXPERIMENTAL, so they get marked as such.
		ctx.WriteString("EXPERIMENTAL ")
	}

	ctx.WriteString("CHANGEFEED FOR ")
	ctx.FormatNode(&node.Targets)
	if node.SinkURI != nil {
		ctx.WriteString(" INTO ")
		ctx.FormatNode(node.SinkURI)
	}
	if node.Options != nil {
		ctx.WriteString(" WITH ")
		ctx.FormatNode(&node.Options)
	}
}

// SQLRight Code Injection.
func (node *CreateChangefeed) LogCurrentNode(depth int) *SQLRightIR {

	if node.Select != nil {
		rootIR := node.LogCurrentNodeWithPredicates(depth)
		return rootIR
	}

	prefix := ""
	if node.SinkURI != nil {
		prefix += "CREATE "
	} else {
		// Sinkless feeds don't really CREATE anything, so the syntax omits the
		// prefix. They're also still EXPERIMENTAL, so they get marked as such.
		prefix += "EXPERIMENTAL "
	}

	prefix += "CHANGEFEED FOR "

	targetNode := node.Targets.LogCurrentNode(depth + 1)

	var sinkNode *SQLRightIR
	infix := ""
	if node.SinkURI != nil {
		infix = " INTO "
		sinkNode = node.SinkURI.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    targetNode,
		RNode:    sinkNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	if node.Options != nil {
		infix = "WITH "
		optionNode := node.Options.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
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

	rootIR.IRType = TypeCreateChangefeed

	return rootIR
}

// formatWithPredicates is a helper to format node when creating
// changefeed with predicates.
func (node *CreateChangefeed) formatWithPredicates(ctx *FmtCtx) {
	ctx.WriteString("CREATE CHANGEFEED")
	if node.SinkURI != nil {
		ctx.WriteString(" INTO ")
		ctx.FormatNode(node.SinkURI)
	}
	if node.Options != nil {
		ctx.WriteString(" WITH ")
		ctx.FormatNode(&node.Options)
	}
	ctx.WriteString(" AS ")
	node.Select.Format(ctx)
}

// SQLRight Code Injection.
func (node *CreateChangefeed) LogCurrentNodeWithPredicates(depth int) *SQLRightIR {

	prefix := "CREATE CHANGEFEED "

	var sinkNode *SQLRightIR
	if node.SinkURI != nil {
		prefix += " INTO "
		sinkNode = node.SinkURI.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    sinkNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if node.Options != nil {
		infix := "WITH"
		optionNode := node.Options.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
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

	infix := " AS "
	selectNode := node.Select.LogCurrentNode(depth + 1)

	rootIR = &SQLRightIR{
		IRType:   TypeCreateChangefeed,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    selectNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ChangefeedTarget represents a database object to be watched by a changefeed.
type ChangefeedTarget struct {
	TableName  TablePattern
	FamilyName Name
}

// Format implements the NodeFormatter interface.
func (ct *ChangefeedTarget) Format(ctx *FmtCtx) {
	ctx.WriteString("TABLE ")
	ctx.FormatNode(ct.TableName)
	if ct.FamilyName != "" {
		ctx.WriteString(" FAMILY ")
		ctx.FormatNode(&ct.FamilyName)
	}
}

// SQLRight Code Injection.
func (node *ChangefeedTarget) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "TABLE "

	tableNode := node.TableName.LogCurrentNode(depth + 1)

	infix := ""

	var familyNode *SQLRightIR
	if node.FamilyName != "" {
		infix = " FAMILY "
		tmpFamilyNode := &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataFamilyName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.FamilyName.String(),
		}
		familyNode = tmpFamilyNode
	}

	rootIR := &SQLRightIR{
		IRType:   TypeChangefeedTarget,
		DataType: DataNone,
		LNode:    tableNode,
		RNode:    familyNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ChangefeedTargets represents a list of database objects to be watched by a changefeed.
type ChangefeedTargets []ChangefeedTarget

// Format implements the NodeFormatter interface.
func (cts *ChangefeedTargets) Format(ctx *FmtCtx) {
	for i, ct := range *cts {
		if i > 0 {
			ctx.WriteString(", ")
		}
		ctx.FormatNode(&ct)
	}
}

// SQLRight Code Injection.
func (node *ChangefeedTargets) LogCurrentNode(depth int) *SQLRightIR {

	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{}
	for i, n := range *node {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n.LogCurrentNode(depth + 1)
			var RNode *SQLRightIR
			infix := ""
			if len(*node) >= 2 {
				RNode = (*node)[1].LogCurrentNode(depth + 1)
				infix = ", "
			}
			tmpIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   "",
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}
		} else if i == 1 {
			// The first two element would be saved in the same IR node.
			continue
		} else {
			// i >= 2. Begins from the third element.
			// Left node is the previous cmds.
			// Right node is the new cmd.
			LNode := tmpIR
			RNode := n.LogCurrentNode(depth + 1)

			tmpIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   "",
				Infix:    ", ",
				Suffix:   "",
				Depth:    depth,
			}
		}
	}

	// Only flag the root node for the type.
	tmpIR.IRType = TypeChangefeedTargets
	return tmpIR
}

// ChangefeedTargetFromTableExpr returns ChangefeedTarget for the
// specified table expression.
func ChangefeedTargetFromTableExpr(e TableExpr) (ChangefeedTarget, error) {
	switch t := e.(type) {
	case TablePattern:
		return ChangefeedTarget{TableName: t}, nil
	case *AliasedTableExpr:
		if tn, ok := t.Expr.(*TableName); ok {
			return ChangefeedTarget{TableName: tn}, nil
		}
	}
	return ChangefeedTarget{}, pgerror.Newf(
		pgcode.InvalidName, "unsupported changefeed target type")
}
