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

import (
	"bytes"
	"fmt"
	"math/rand"
	"strconv"
	"strings"

	"github.com/cockroachdb/cockroach/pkg/sql/lexbase"
	"github.com/cockroachdb/cockroach/pkg/sql/pgwire/pgcode"
	"github.com/cockroachdb/cockroach/pkg/sql/pgwire/pgerror"
	"github.com/cockroachdb/cockroach/pkg/sql/roleoption"
	"github.com/cockroachdb/cockroach/pkg/sql/types"
	"github.com/cockroachdb/cockroach/pkg/util/pretty"
	"github.com/cockroachdb/errors"
	"golang.org/x/text/language"
)

// CreateDatabase represents a CREATE DATABASE statement.
type CreateDatabase struct {
	IfNotExists     bool
	Name            Name
	Template        string
	Encoding        string
	Collate         string
	CType           string
	ConnectionLimit int32
	PrimaryRegion   Name
	Regions         NameList
	SurvivalGoal    SurvivalGoal
	Placement       DataPlacement
	Owner           RoleSpec
	SecondaryRegion Name
}

// Format implements the NodeFormatter interface.
func (node *CreateDatabase) Format(ctx *FmtCtx) {
	ctx.WriteString("CREATE DATABASE ")
	if node.IfNotExists {
		ctx.WriteString("IF NOT EXISTS ")
	}
	ctx.FormatNode(&node.Name)
	if node.Template != "" {
		// NB: the template is not currently edited out under FmtAnonymize,
		// because we don't support custom templates. If/when custom
		// templates are supported, this should call ctx.FormatNode
		// on the template expr.
		ctx.WriteString(" TEMPLATE = ")
		lexbase.EncodeSQLStringWithFlags(&ctx.Buffer, node.Template, ctx.flags.EncodeFlags())
	}
	if node.Encoding != "" {
		// NB: the encoding is not currently edited out under FmtAnonymize,
		// because we don't support custom encodings. If/when custom
		// encodings are supported, this should call ctx.FormatNode
		// on the encoding expr.
		ctx.WriteString(" ENCODING = ")
		lexbase.EncodeSQLStringWithFlags(&ctx.Buffer, node.Encoding, ctx.flags.EncodeFlags())
	}
	if node.Collate != "" {
		// NB: the collation is not currently edited out under FmtAnonymize,
		// because we don't support custom collations. If/when custom
		// collations are supported, this should call ctx.FormatNode
		// on the collation expr.
		ctx.WriteString(" LC_COLLATE = ")
		lexbase.EncodeSQLStringWithFlags(&ctx.Buffer, node.Collate, ctx.flags.EncodeFlags())
	}
	if node.CType != "" {
		// NB: the ctype (formatting customization) is not currently
		// edited out under FmtAnonymize, because we don't support custom
		// cutomizations. If/when custom customizations are supported,
		// this should call ctx.FormatNode on the ctype expr.
		ctx.WriteString(" LC_CTYPE = ")
		lexbase.EncodeSQLStringWithFlags(&ctx.Buffer, node.CType, ctx.flags.EncodeFlags())
	}
	if node.ConnectionLimit != -1 {
		ctx.WriteString(" CONNECTION LIMIT = ")
		if ctx.flags.HasFlags(FmtHideConstants) {
			ctx.WriteByte('0')
		} else {
			// NB: use ctx.FormatNode when the connection limit becomes an expression.
			ctx.WriteString(strconv.Itoa(int(node.ConnectionLimit)))
		}
	}
	if node.PrimaryRegion != "" {
		ctx.WriteString(" PRIMARY REGION ")
		ctx.FormatNode(&node.PrimaryRegion)
	}
	if node.Regions != nil {
		ctx.WriteString(" REGIONS = ")
		ctx.FormatNode(&node.Regions)
	}
	if node.SurvivalGoal != SurvivalGoalDefault {
		ctx.WriteString(" ")
		ctx.FormatNode(&node.SurvivalGoal)
	}
	if node.Placement != DataPlacementUnspecified {
		ctx.WriteString(" ")
		ctx.FormatNode(&node.Placement)
	}

	if node.Owner.Name != "" {
		ctx.WriteString(" OWNER = ")
		ctx.FormatNode(&node.Owner)
	}

	if node.SecondaryRegion != "" {
		ctx.WriteString(" SECONDARY REGION ")
		ctx.FormatNode(&node.SecondaryRegion)
	}
}

// SQLRight Code Injection.
func (node *CreateDatabase) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "CREATE DATABASE"

	optIfNotExistStr := ""
	if node.IfNotExists {
		optIfNotExistStr = "IF NOT EXISTS "
	}
	LNode := &SQLRightIR{
		IRType:   TypeOptIfNotExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfNotExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	databaseNameStr := node.Name.String()
	RNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         databaseNameStr,
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if node.Template != "" {
		infix := " TEMPLATE = "
		RNode = &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataTemplateName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Template,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
		LNode = rootIR
	}

	if node.Encoding != "" {
		infix := " ENCODING = "
		RNode = &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataEncodingName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Encoding,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.Collate != "" {
		infix := " LC_COLLATE = "
		RNode = &SQLRightIR{
			IRType:       TypeStringLiteral,
			DataType:     DataCollationName,
			ContextFlag:  ContextUse,
			DataAffinity: AFFICOLLATE,
			Prefix:       "",
			Infix:        "",
			Suffix:       "",
			Depth:        depth,
			Str:          node.Collate,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.CType != "" {
		infix := " LC_CTYPE = "
		RNode = &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataCTypeName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.CType,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.ConnectionLimit != -1 {
		infix := " CONNECTION LIMIT = "
		RNode = &SQLRightIR{
			IRType:       TypeIntegerLiteral,
			DataType:     DataLiteral,
			DataAffinity: AFFIINT,
			Prefix:       "",
			Infix:        "",
			Suffix:       "",
			Depth:        depth,
			IValue:       int64(node.ConnectionLimit),
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.PrimaryRegion != "" {
		infix := " PRIMARY REGION "
		RNode = &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataRegionName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.PrimaryRegion.String(),
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.Regions != nil {
		infix := " REGIONS = "
		pRNode := node.Regions.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    pRNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.SurvivalGoal != SurvivalGoalDefault {
		infix := " "
		pRNode := node.SurvivalGoal.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    pRNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.Placement != DataPlacementUnspecified {
		infix := " "
		pRNode := node.Placement.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    pRNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.Owner.Name != "" {
		infix := " OWNER = "
		pRNode := node.Owner.LogCurrentNode(depth+1, ContextUse)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    pRNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.SecondaryRegion != "" {
		infix := " SECONDARY REGIONS "
		secondRegionStr := node.SecondaryRegion.String()

		RNode = &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataRegionName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         secondRegionStr,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeCreateDatabase

	return rootIR
}

// IndexElem represents a column with a direction in a CREATE INDEX statement.
type IndexElem struct {
	// Column is set if this is a simple column reference (the common case).
	Column Name
	// Expr is set if the index element is an expression (part of an expression
	// index). If set, Column is empty.
	Expr       Expr
	Direction  Direction
	NullsOrder NullsOrder

	// OpClass is set if an index element was created using a named opclass.
	OpClass Name
}

// Format implements the NodeFormatter interface.
func (node *IndexElem) Format(ctx *FmtCtx) {
	if node.Expr == nil {
		ctx.FormatNode(&node.Column)
	} else {
		// Expressions in indexes need an extra set of parens, unless they are a
		// simple function call.
		_, isFunc := node.Expr.(*FuncExpr)
		if !isFunc {
			ctx.WriteByte('(')
		}
		ctx.FormatNode(node.Expr)
		if !isFunc {
			ctx.WriteByte(')')
		}
	}
	if node.OpClass != "" {
		ctx.WriteByte(' ')
		ctx.WriteString(node.OpClass.String())
	}
	if node.Direction != DefaultDirection {
		ctx.WriteByte(' ')
		ctx.WriteString(node.Direction.String())
	}
	if node.NullsOrder != DefaultNullsOrder {
		ctx.WriteByte(' ')
		ctx.WriteString(node.NullsOrder.String())
	}
}

// SQLRight Code Injection.
func (node *IndexElem) LogCurrentNode(depth int, flag SQLRightContextFlag) *SQLRightIR {

	prefix := ""
	infix := ""

	var PLNode *SQLRightIR
	if node.Expr == nil {
		tmpColumnStr := node.Column.String()
		LNode := &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataColumnName,
			ContextFlag: flag,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         tmpColumnStr,
		}
		PLNode = LNode
	} else {
		_, isFunc := node.Expr.(*FuncExpr)
		if !isFunc {
			prefix = "("
			infix = ") "
		}
		PLNode = node.Expr.LogCurrentNode(depth + 1)
	}

	var pRNode *SQLRightIR
	if node.OpClass != "" {
		opclassStr := node.OpClass.String()
		RNode := &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataNone, // TODO: FIXME: Datatype unknown here.
			ContextFlag: ContextUnknown,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         opclassStr,
		}
		pRNode = RNode
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    PLNode,
		RNode:    pRNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	if node.Direction != DefaultDirection {
		infix = " "
		directionStr := node.Direction.String()
		RNode := &SQLRightIR{
			IRType:   TypeDirection,
			DataType: DataNone,
			//LNode:    LNode,
			//RNode:    RNode,
			Prefix: directionStr,
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		pRNode = RNode

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    pRNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}

	}

	if node.NullsOrder != DefaultNullsOrder {
		infix = " "
		nullsOrderStr := node.NullsOrder.String()
		RNode := &SQLRightIR{
			IRType:   TypeNullsOrder,
			DataType: DataNone,
			//LNode:    LNode,
			//RNode:    RNode,
			Prefix: nullsOrderStr,
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		pRNode = RNode

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    pRNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}

	}

	rootIR.IRType = TypeIndexElem

	return rootIR
}

func (node *IndexElem) doc(p *PrettyCfg) pretty.Doc {
	var d pretty.Doc
	if node.Expr == nil {
		d = p.Doc(&node.Column)
	} else {
		// Expressions in indexes need an extra set of parens, unless they are a
		// simple function call.
		d = p.Doc(node.Expr)
		if _, isFunc := node.Expr.(*FuncExpr); !isFunc {
			d = p.bracket("(", d, ")")
		}
	}
	if node.OpClass != "" {
		d = pretty.ConcatSpace(d, pretty.Text(node.OpClass.String()))
	}
	if node.Direction != DefaultDirection {
		d = pretty.ConcatSpace(d, pretty.Keyword(node.Direction.String()))
	}
	if node.NullsOrder != DefaultNullsOrder {
		d = pretty.ConcatSpace(d, pretty.Keyword(node.NullsOrder.String()))
	}
	return d
}

// IndexElemList is list of IndexElem.
type IndexElemList []IndexElem

// Format pretty-prints the contained names separated by commas.
// Format implements the NodeFormatter interface.
func (l *IndexElemList) Format(ctx *FmtCtx) {
	for i := range *l {
		if i > 0 {
			ctx.WriteString(", ")
		}
		ctx.FormatNode(&(*l)[i])
	}
}

// SQLRight Code Injection.
func (node *IndexElemList) LogCurrentNode(depth int, flag SQLRightContextFlag) *SQLRightIR {

	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{}
	for i, n := range *node {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n.LogCurrentNode(depth+1, flag)
			var RNode *SQLRightIR
			infix := ""
			if len(*node) >= 2 {
				RNode = (*node)[1].LogCurrentNode(depth+1, flag)
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
			RNode := n.LogCurrentNode(depth+1, flag)

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
	tmpIR.IRType = TypeIndexElemList
	return tmpIR
}

// doc is part of the docer interface.
func (l *IndexElemList) doc(p *PrettyCfg) pretty.Doc {
	if l == nil || len(*l) == 0 {
		return pretty.Nil
	}
	d := make([]pretty.Doc, len(*l))
	for i := range *l {
		d[i] = p.Doc(&(*l)[i])
	}
	return p.commaSeparated(d...)
}

// CreateIndex represents a CREATE INDEX statement.
type CreateIndex struct {
	Name        Name
	Table       TableName
	Unique      bool
	Inverted    bool
	IfNotExists bool
	Columns     IndexElemList
	Sharded     *ShardedIndexDef
	// Extra columns to be stored together with the indexed ones as an optimization
	// for improved reading performance.
	Storing          NameList
	PartitionByIndex *PartitionByIndex
	StorageParams    StorageParams
	Predicate        Expr
	Concurrently     bool
	NotVisible       bool
}

// Format implements the NodeFormatter interface.
func (node *CreateIndex) Format(ctx *FmtCtx) {
	// Please also update indexForDisplay function in
	// pkg/sql/catalog/catformat/index.go if there's any update to index
	// definition components.
	ctx.WriteString("CREATE ")
	if node.Unique {
		ctx.WriteString("UNIQUE ")
	}
	if node.Inverted {
		ctx.WriteString("INVERTED ")
	}
	ctx.WriteString("INDEX ")
	if node.Concurrently {
		ctx.WriteString("CONCURRENTLY ")
	}
	if node.IfNotExists {
		ctx.WriteString("IF NOT EXISTS ")
	}
	if node.Name != "" {
		ctx.FormatNode(&node.Name)
		ctx.WriteByte(' ')
	}
	ctx.WriteString("ON ")
	ctx.FormatNode(&node.Table)

	ctx.WriteString(" (")
	ctx.FormatNode(&node.Columns)
	ctx.WriteByte(')')
	if node.Sharded != nil {
		ctx.FormatNode(node.Sharded)
	}
	if len(node.Storing) > 0 {
		ctx.WriteString(" STORING (")
		ctx.FormatNode(&node.Storing)
		ctx.WriteByte(')')
	}
	if node.PartitionByIndex != nil {
		ctx.FormatNode(node.PartitionByIndex)
	}
	if node.StorageParams != nil {
		ctx.WriteString(" WITH (")
		ctx.FormatNode(&node.StorageParams)
		ctx.WriteString(")")
	}
	if node.Predicate != nil {
		ctx.WriteString(" WHERE ")
		ctx.FormatNode(node.Predicate)
	}
	if node.NotVisible {
		ctx.WriteString(" NOT VISIBLE")
	}
}

// SQLRight Code Injection.
func (node *CreateIndex) LogCurrentNode(depth int) *SQLRightIR {

	tmpUniStr := ""
	if node.Unique {
		tmpUniStr = " UNIQUE "
	} else {
		tmpUniStr = ""
	}
	LNode := &SQLRightIR{
		IRType:   TypeOptUnique,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: tmpUniStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	tmpInvertedStr := ""
	if node.Inverted {
		tmpInvertedStr = "INVERTED "
	}
	RNode := &SQLRightIR{
		IRType:   TypeOptInverted,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: tmpInvertedStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "CREATE ",
		Infix:    " ",
		Suffix:   "INDEX ",
		Depth:    depth,
	}

	optConcurrStr := ""
	if node.Concurrently {
		optConcurrStr = "CONCURRENTLY "
	}
	RNode = &SQLRightIR{
		IRType:   TypeOptConcurrently,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optConcurrStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}
	rootIR = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    RNode,
		Prefix:   "",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	optExistStr := ""
	if node.IfNotExists {
		optExistStr = "IF NOT EXISTS "
	}
	RNode = &SQLRightIR{
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}
	rootIR = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    RNode,
		Prefix:   "",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	if node.Name != "" {
		indexName := node.Name.String()
		RNode = &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataIndexName,
			ContextFlag: ContextDefine,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         indexName,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   " ",
			Depth:    depth,
		}
	}

	// Required. ON TableName
	RNode = &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataTableName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Table.String(),
	}
	rootIR = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    RNode,
		Prefix:   "",
		Infix:    " ON ",
		Suffix:   "",
		Depth:    depth,
	}

	// column list
	pRNode := node.Columns.LogCurrentNode(depth+1, ContextUse)
	rootIR = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    pRNode,
		Prefix:   "",
		Infix:    " (",
		Suffix:   ")",
		Depth:    depth,
	}

	// opt sharded
	if node.Sharded != nil {
		pSharded := node.Sharded.LogCurrentNode(depth + 1)
		optShardedNode := &SQLRightIR{
			IRType:   TypeOptSharded,
			DataType: DataNone,
			LNode:    pSharded,
			//RNode:    pRNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optShardedNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	} else {
		optStoringNode := &SQLRightIR{
			IRType:   TypeOptSharded,
			DataType: DataNone,
			//LNode:    pStoringNode,
			//RNode:    pRNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optStoringNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	}

	// opt storing
	if len(node.Storing) > 0 {
		pStoringNode := node.Storing.LogCurrentNodeWithType(depth+1, DataColumnName)
		optStoringNode := &SQLRightIR{
			IRType:   TypeOptStoring,
			DataType: DataNone,
			LNode:    pStoringNode,
			//RNode:    pRNode,
			Prefix: " STORING (",
			Infix:  ")",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optStoringNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	} else {
		optStoringNode := &SQLRightIR{
			IRType:   TypeOptStoring,
			DataType: DataNone,
			//LNode:    pStoringNode,
			//RNode:    pRNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optStoringNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	}

	// opt partition by index
	if node.PartitionByIndex != nil {
		pParBy := node.PartitionByIndex.LogCurrentNode(depth + 1)
		optPartitionNode := &SQLRightIR{
			IRType:   TypeOptPartitionBy,
			DataType: DataNone,
			LNode:    pParBy,
			//RNode:    pRNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optPartitionNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	} else {
		optPartitionNode := &SQLRightIR{
			IRType:   TypeOptPartitionBy,
			DataType: DataNone,
			//LNode:    pStoringNode,
			//RNode:    pRNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optPartitionNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	}

	// opt StorageParams
	if node.StorageParams != nil {
		pStorageParams := node.StorageParams.LogCurrentNode(depth + 1)
		optStorageParams := &SQLRightIR{
			IRType:   TypeOptStorageParams,
			DataType: DataNone,
			LNode:    pStorageParams,
			//RNode:    pRNode,
			Prefix: " WITH (",
			Infix:  ")",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optStorageParams,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	} else {
		optPartitionNode := &SQLRightIR{
			IRType:   TypeOptStorageParams,
			DataType: DataNone,
			//LNode:    pStoringNode,
			//RNode:    pRNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optPartitionNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	}

	// opt predicate
	if node.Predicate != nil {
		pPredicate := node.Predicate.LogCurrentNode(depth + 1)
		optPredicate := &SQLRightIR{
			IRType:   TypeOptPredicate,
			DataType: DataNone,
			LNode:    pPredicate,
			//RNode:    pRNode,
			Prefix: " WHERE ",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optPredicate,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	} else {
		optPredicate := &SQLRightIR{
			IRType:   TypeOptPredicate,
			DataType: DataNone,
			//LNode:    pStoringNode,
			//RNode:    pRNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optPredicate,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	// opt VISIBLE
	notVisibleStr := ""
	if node.NotVisible {
		notVisibleStr = " NOT VISIBLE"
	}
	optNotVisible := &SQLRightIR{
		IRType:   TypeOptNotVisible,
		DataType: DataNone,
		//LNode:    ,
		//RNode:    ,
		Prefix: notVisibleStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}
	rootIR = &SQLRightIR{
		IRType:   TypeCreateIndex,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    optNotVisible,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// CreateTypeVariety represents a particular variety of user defined types.
type CreateTypeVariety int

//go:generate stringer -type=CreateTypeVariety
const (
	_ CreateTypeVariety = iota
	// Enum represents an ENUM user defined type.
	Enum
	// Composite represents a composite user defined type.
	Composite
	// Range represents a RANGE user defined type.
	Range
	// Base represents a base user defined type.
	Base
	// Shell represents a shell user defined type.
	Shell
	// Domain represents a DOMAIN user defined type.
	Domain
)

// EnumValue represents a single enum value.
type EnumValue string

// Format implements the NodeFormatter interface.
func (n *EnumValue) Format(ctx *FmtCtx) {
	f := ctx.flags
	if f.HasFlags(FmtAnonymize) {
		ctx.WriteByte('_')
	} else {
		lexbase.EncodeSQLString(&ctx.Buffer, string(*n))
	}
}

// SQLRight Code Injection.
func (node *EnumValue) LogCurrentNode(depth int) *SQLRightIR {

	var tmpBuffer bytes.Buffer
	lexbase.EncodeSQLString(&tmpBuffer, string(*node))
	irStr := tmpBuffer.String()

	rootIR := &SQLRightIR{
		IRType:       TypeStringLiteral,
		DataType:     DataLiteral,
		DataAffinity: AFFIENUM,
		Prefix:       "",
		Infix:        "",
		Suffix:       "",
		Depth:        depth,
		Str:          irStr,
	}

	return rootIR
}

// EnumValueList represents a list of enum values.
type EnumValueList []EnumValue

// Format implements the NodeFormatter interface.
func (l *EnumValueList) Format(ctx *FmtCtx) {
	for i := range *l {
		if i > 0 {
			ctx.WriteString(", ")
		}
		ctx.FormatNode(&(*l)[i])
	}
}

// SQLRight Code Injection.
func (node *EnumValueList) LogCurrentNode(depth int) *SQLRightIR {

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
	tmpIR.IRType = TypeEnumValueList
	return tmpIR
}

// CreateType represents a CREATE TYPE statement.
type CreateType struct {
	TypeName *UnresolvedObjectName
	Variety  CreateTypeVariety
	// EnumLabels is set when this represents a CREATE TYPE ... AS ENUM statement.
	EnumLabels EnumValueList
	// IfNotExists is true if IF NOT EXISTS was requested.
	IfNotExists bool
	SQLRightInterface
}

var _ Statement = &CreateType{}

// Format implements the NodeFormatter interface.
func (node *CreateType) Format(ctx *FmtCtx) {
	ctx.WriteString("CREATE TYPE ")
	if node.IfNotExists {
		ctx.WriteString("IF NOT EXISTS ")
	}
	ctx.FormatNode(node.TypeName)
	ctx.WriteString(" ")
	switch node.Variety {
	case Enum:
		ctx.WriteString("AS ENUM (")
		ctx.FormatNode(&node.EnumLabels)
		ctx.WriteString(")")
	}
}

// SQLRight Code Injection.
func (node *CreateType) LogCurrentNode(depth int) *SQLRightIR {

	ifNotExistStr := ""
	if node.IfNotExists {
		ifNotExistStr = "IF NOT EXISTS "
	}
	LNode := &SQLRightIR{
		IRType:   TypeOptIfNotExists,
		DataType: DataNone,
		//LNode:  LNode,
		//RNode:    pRNode,
		Prefix: "",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
		Str:    ifNotExistStr,
	}

	typeNameStr := node.TypeName.String()
	RNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataTypeName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         typeNameStr,
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    LNode, // IF NOT EXISTS
		RNode:    RNode, // Type name
		Prefix:   "CREATE TYPE ",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	switch node.Variety {
	case Enum:
		infix := " AS ENUM ("
		pRNode := node.EnumLabels.LogCurrentNode(depth + 1)
		suffix := ")"

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR, // previous root
			RNode:    pRNode, // enumlabels
			Prefix:   "",
			Infix:    infix,
			Suffix:   suffix,
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeCreateType

	return rootIR
}

func (node *CreateType) String() string {
	return AsString(node)
}

// TableDef represents a column, index or constraint definition within a CREATE
// TABLE statement.
type TableDef interface {
	NodeFormatter
	// Placeholder function to ensure that only desired types (*TableDef) conform
	// to the TableDef interface.
	tableDef()
	SQLRightInterface
}

func (*ColumnTableDef) tableDef()               {}
func (*IndexTableDef) tableDef()                {}
func (*FamilyTableDef) tableDef()               {}
func (*ForeignKeyConstraintTableDef) tableDef() {}
func (*CheckConstraintTableDef) tableDef()      {}
func (*LikeTableDef) tableDef()                 {}

// TableDefs represents a list of table definitions.
type TableDefs []TableDef

// Format implements the NodeFormatter interface.
func (node *TableDefs) Format(ctx *FmtCtx) {
	for i, n := range *node {
		if i > 0 {
			ctx.WriteString(", ")
		}
		ctx.FormatNode(n)
	}
}

// SQLRight Code Injection.
func (node *TableDefs) LogCurrentNode(depth int) *SQLRightIR {

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
	tmpIR.IRType = TypeTableDefs
	return tmpIR
}

// Nullability represents either NULL, NOT NULL or an unspecified value (silent
// NULL).
type Nullability int

// The values for NullType.
const (
	NotNull Nullability = iota
	Null
	SilentNull
)

// RandomNullability returns a random valid Nullability, given a random number
// generator, `rand`. If nullableOnly is true, the random Nullability will not
// be `NotNull`.
func RandomNullability(rand *rand.Rand, nullableOnly bool) Nullability {
	if nullableOnly {
		// Add 1 after getting the random number to exclude the zero-value NotNull.
		return Nullability(rand.Intn(int(SilentNull)) + 1)
	}
	return Nullability(rand.Intn(int(SilentNull) + 1))
}

// GeneratedIdentityType represents either GENERATED ALWAYS AS IDENTITY
// or GENERATED BY DEFAULT AS IDENTITY.
type GeneratedIdentityType int

// The values of GeneratedIdentity.GeneratedAsIdentityType.
const (
	GeneratedAlways GeneratedIdentityType = iota
	GeneratedByDefault
)

// ColumnTableDef represents a column definition within a CREATE TABLE
// statement.
type ColumnTableDef struct {
	Name              Name
	Type              ResolvableTypeReference
	IsSerial          bool
	GeneratedIdentity struct {
		IsGeneratedAsIdentity   bool
		GeneratedAsIdentityType GeneratedIdentityType
		SeqOptions              SequenceOptions
	}
	Hidden   bool
	Nullable struct {
		Nullability    Nullability
		ConstraintName Name
	}
	PrimaryKey struct {
		IsPrimaryKey  bool
		Sharded       bool
		ShardBuckets  Expr
		StorageParams StorageParams
	}
	Unique struct {
		IsUnique       bool
		WithoutIndex   bool
		ConstraintName Name
	}
	DefaultExpr struct {
		Expr           Expr
		ConstraintName Name
	}
	OnUpdateExpr struct {
		Expr           Expr
		ConstraintName Name
	}
	CheckExprs []ColumnTableDefCheckExpr
	References struct {
		Table          *TableName
		Col            Name
		ConstraintName Name
		Actions        ReferenceActions
		Match          CompositeKeyMatchMethod
	}
	Computed struct {
		Computed bool
		Expr     Expr
		Virtual  bool
	}
	Family struct {
		Name        Name
		Create      bool
		IfNotExists bool
	}
}

// ColumnTableDefCheckExpr represents a check constraint on a column definition
// within a CREATE TABLE statement.
type ColumnTableDefCheckExpr struct {
	Expr           Expr
	ConstraintName Name
}

func processCollationOnType(
	name Name, ref ResolvableTypeReference, c ColumnCollation,
) (*types.T, error) {
	// At the moment, only string types can be collated. User defined types
	//  like enums don't support collations, so check this at parse time.
	typ, ok := GetStaticallyKnownType(ref)
	if !ok {
		return nil, pgerror.Newf(pgcode.DatatypeMismatch,
			"COLLATE declaration for non-string-typed column %q", name)
	}
	switch typ.Family() {
	case types.StringFamily:
		return types.MakeCollatedString(typ, string(c)), nil
	case types.CollatedStringFamily:
		return nil, pgerror.Newf(pgcode.Syntax,
			"multiple COLLATE declarations for column %q", name)
	case types.ArrayFamily:
		elemTyp, err := processCollationOnType(name, typ.ArrayContents(), c)
		if err != nil {
			return nil, err
		}
		return types.MakeArray(elemTyp), nil
	default:
		return nil, pgerror.Newf(pgcode.DatatypeMismatch,
			"COLLATE declaration for non-string-typed column %q", name)
	}
}

// NewColumnTableDef constructs a column definition for a CreateTable statement.
func NewColumnTableDef(
	name Name,
	typRef ResolvableTypeReference,
	isSerial bool,
	qualifications []NamedColumnQualification,
) (*ColumnTableDef, error) {
	d := &ColumnTableDef{
		Name:     name,
		Type:     typRef,
		IsSerial: isSerial,
	}
	d.Nullable.Nullability = SilentNull
	for _, c := range qualifications {
		switch t := c.Qualification.(type) {
		case ColumnCollation:
			locale := string(t)
			// In postgres, all strings have collations defaulting to "default".
			// In CRDB, collated strings are treated separately to string family types.
			// To most behave like postgres, set the CollatedString type if a non-"default"
			// collation is used.
			if locale != DefaultCollationTag {
				_, err := language.Parse(locale)
				if err != nil {
					return nil, pgerror.Wrapf(err, pgcode.Syntax, "invalid locale %s", locale)
				}
				collatedTyp, err := processCollationOnType(name, d.Type, t)
				if err != nil {
					return nil, err
				}
				d.Type = collatedTyp
			}
		case *ColumnDefault:
			if d.HasDefaultExpr() || d.GeneratedIdentity.IsGeneratedAsIdentity {
				return nil, pgerror.Newf(pgcode.Syntax,
					"multiple default values specified for column %q", name)
			}
			d.DefaultExpr.Expr = t.Expr
			d.DefaultExpr.ConstraintName = c.Name
		case *ColumnOnUpdate:
			if d.HasOnUpdateExpr() {
				return nil, pgerror.Newf(pgcode.Syntax,
					"multiple ON UPDATE values specified for column %q", name)
			}
			if d.GeneratedIdentity.IsGeneratedAsIdentity {
				return nil, pgerror.Newf(pgcode.Syntax,
					"both generated identity and on update expression specified for column %q",
					name)
			}
			d.OnUpdateExpr.Expr = t.Expr
			d.OnUpdateExpr.ConstraintName = c.Name
		case *GeneratedAlwaysAsIdentity, *GeneratedByDefAsIdentity:
			if typ, ok := typRef.(*types.T); !ok || typ.InternalType.Family != types.IntFamily {
				return nil, pgerror.Newf(
					pgcode.InvalidParameterValue,
					"identity column type must be an INT",
				)
			}
			if d.GeneratedIdentity.IsGeneratedAsIdentity {
				return nil, pgerror.Newf(pgcode.Syntax,
					"multiple identity specifications for column %q", name)
			}
			if d.HasDefaultExpr() {
				return nil, pgerror.Newf(pgcode.Syntax,
					"multiple default values specified for column %q", name)
			}
			if d.Computed.Computed {
				return nil, pgerror.Newf(pgcode.Syntax,
					"both generated identity and computed expression specified for column %q", name)
			}
			if d.Nullable.Nullability == Null {
				return nil, pgerror.Newf(pgcode.Syntax,
					"conflicting NULL/NOT NULL declarations for column %q", name)
			}
			if d.HasOnUpdateExpr() {
				return nil, pgerror.Newf(pgcode.Syntax,
					"both generated identity and on update expression specified for column %q",
					name)
			}
			d.GeneratedIdentity.IsGeneratedAsIdentity = true
			d.Nullable.Nullability = NotNull
			switch c.Qualification.(type) {
			case *GeneratedAlwaysAsIdentity:
				d.GeneratedIdentity.GeneratedAsIdentityType = GeneratedAlways
				d.GeneratedIdentity.SeqOptions = t.(*GeneratedAlwaysAsIdentity).SeqOptions
			case *GeneratedByDefAsIdentity:
				d.GeneratedIdentity.GeneratedAsIdentityType = GeneratedByDefault
				d.GeneratedIdentity.SeqOptions = t.(*GeneratedByDefAsIdentity).SeqOptions
			}
		case HiddenConstraint:
			d.Hidden = true
		case NotNullConstraint:
			if d.Nullable.Nullability == Null {
				return nil, pgerror.Newf(pgcode.Syntax,
					"conflicting NULL/NOT NULL declarations for column %q", name)
			}
			d.Nullable.Nullability = NotNull
			d.Nullable.ConstraintName = c.Name
		case NullConstraint:
			if d.Nullable.Nullability == NotNull {
				return nil, pgerror.Newf(pgcode.Syntax,
					"conflicting NULL/NOT NULL declarations for column %q", name)
			}
			d.Nullable.Nullability = Null
			d.Nullable.ConstraintName = c.Name
		case PrimaryKeyConstraint:
			d.PrimaryKey.IsPrimaryKey = true
			d.PrimaryKey.StorageParams = c.Qualification.(PrimaryKeyConstraint).StorageParams
			d.Unique.ConstraintName = c.Name
		case ShardedPrimaryKeyConstraint:
			d.PrimaryKey.IsPrimaryKey = true
			constraint := c.Qualification.(ShardedPrimaryKeyConstraint)
			d.PrimaryKey.Sharded = true
			d.PrimaryKey.ShardBuckets = constraint.ShardBuckets
			d.PrimaryKey.StorageParams = constraint.StorageParams
			d.Unique.ConstraintName = c.Name
		case UniqueConstraint:
			d.Unique.IsUnique = true
			d.Unique.WithoutIndex = t.WithoutIndex
			d.Unique.ConstraintName = c.Name
		case *ColumnCheckConstraint:
			d.CheckExprs = append(d.CheckExprs, ColumnTableDefCheckExpr{
				Expr:           t.Expr,
				ConstraintName: c.Name,
			})
		case *ColumnFKConstraint:
			if d.HasFKConstraint() {
				return nil, pgerror.Newf(pgcode.InvalidTableDefinition,
					"multiple foreign key constraints specified for column %q", name)
			}
			d.References.Table = &t.Table
			d.References.Col = t.Col
			d.References.ConstraintName = c.Name
			d.References.Actions = t.Actions
			d.References.Match = t.Match
		case *ColumnComputedDef:
			if d.GeneratedIdentity.IsGeneratedAsIdentity {
				return nil, pgerror.Newf(pgcode.Syntax,
					"both generated identity and computed expression specified for column %q", name)
			}
			d.Computed.Computed = true
			d.Computed.Expr = t.Expr
			d.Computed.Virtual = t.Virtual
		case *ColumnFamilyConstraint:
			if d.HasColumnFamily() {
				return nil, pgerror.Newf(pgcode.InvalidTableDefinition,
					"multiple column families specified for column %q", name)
			}
			d.Family.Name = t.Family
			d.Family.Create = t.Create
			d.Family.IfNotExists = t.IfNotExists
		default:
			return nil, errors.AssertionFailedf("unexpected column qualification: %T", c)
		}
	}

	return d, nil
}

// HasDefaultExpr returns if the ColumnTableDef has a default expression.
func (node *ColumnTableDef) HasDefaultExpr() bool {
	return node.DefaultExpr.Expr != nil
}

// HasOnUpdateExpr returns if the ColumnTableDef has an ON UPDATE expression.
func (node *ColumnTableDef) HasOnUpdateExpr() bool {
	return node.OnUpdateExpr.Expr != nil
}

// HasFKConstraint returns if the ColumnTableDef has a foreign key constraint.
func (node *ColumnTableDef) HasFKConstraint() bool {
	return node.References.Table != nil
}

// IsComputed returns if the ColumnTableDef is a computed column.
func (node *ColumnTableDef) IsComputed() bool {
	return node.Computed.Computed
}

// IsVirtual returns if the ColumnTableDef is a virtual column.
func (node *ColumnTableDef) IsVirtual() bool {
	return node.Computed.Virtual
}

// HasColumnFamily returns if the ColumnTableDef has a column family.
func (node *ColumnTableDef) HasColumnFamily() bool {
	return node.Family.Name != "" || node.Family.Create
}

// Format implements the NodeFormatter interface.
func (node *ColumnTableDef) Format(ctx *FmtCtx) {
	ctx.FormatNode(&node.Name)

	// ColumnTableDef node type will not be specified if it represents a CREATE
	// TABLE ... AS query.
	if node.Type != nil {
		ctx.WriteByte(' ')
		ctx.WriteString(node.columnTypeString())
	}

	if node.Nullable.Nullability != SilentNull && node.Nullable.ConstraintName != "" {
		ctx.WriteString(" CONSTRAINT ")
		ctx.FormatNode(&node.Nullable.ConstraintName)
	}
	switch node.Nullable.Nullability {
	case Null:
		ctx.WriteString(" NULL")
	case NotNull:
		ctx.WriteString(" NOT NULL")
	}
	if node.Hidden {
		ctx.WriteString(" NOT VISIBLE")
	}
	if node.PrimaryKey.IsPrimaryKey || node.Unique.IsUnique {
		if node.Unique.ConstraintName != "" {
			ctx.WriteString(" CONSTRAINT ")
			ctx.FormatNode(&node.Unique.ConstraintName)
		}
		if node.PrimaryKey.IsPrimaryKey {
			ctx.WriteString(" PRIMARY KEY")

			// Always prefer to output hash sharding bucket count as a storage param.
			pkStorageParams := node.PrimaryKey.StorageParams
			if node.PrimaryKey.Sharded {
				ctx.WriteString(" USING HASH")
				bcStorageParam := node.PrimaryKey.StorageParams.GetVal(`bucket_count`)
				if _, ok := node.PrimaryKey.ShardBuckets.(DefaultVal); !ok && bcStorageParam == nil {
					pkStorageParams = append(
						pkStorageParams,
						StorageParam{
							Key:   `bucket_count`,
							Value: node.PrimaryKey.ShardBuckets,
						},
					)
				}
			}
			if len(pkStorageParams) > 0 {
				ctx.WriteString(" WITH (")
				ctx.FormatNode(&pkStorageParams)
				ctx.WriteString(")")
			}
		} else if node.Unique.IsUnique {
			ctx.WriteString(" UNIQUE")
			if node.Unique.WithoutIndex {
				ctx.WriteString(" WITHOUT INDEX")
			}
		}
	}
	if node.HasDefaultExpr() {
		if node.DefaultExpr.ConstraintName != "" {
			ctx.WriteString(" CONSTRAINT ")
			ctx.FormatNode(&node.DefaultExpr.ConstraintName)
		}
		ctx.WriteString(" DEFAULT ")
		ctx.FormatNode(node.DefaultExpr.Expr)
	}
	if node.HasOnUpdateExpr() {
		if node.OnUpdateExpr.ConstraintName != "" {
			ctx.WriteString(" CONSTRAINT ")
			ctx.FormatNode(&node.OnUpdateExpr.ConstraintName)
		}
		ctx.WriteString(" ON UPDATE ")
		ctx.FormatNode(node.OnUpdateExpr.Expr)
	}
	if node.GeneratedIdentity.IsGeneratedAsIdentity {
		switch node.GeneratedIdentity.GeneratedAsIdentityType {
		case GeneratedAlways:
			ctx.WriteString(" GENERATED ALWAYS AS IDENTITY")
		case GeneratedByDefault:
			ctx.WriteString(" GENERATED BY DEFAULT AS IDENTITY")
		}
		if genSeqOpt := node.GeneratedIdentity.SeqOptions; genSeqOpt != nil {
			ctx.WriteString(" (")
			// TODO(janexing): remove the leading and ending space of the
			// sequence option expression.
			genSeqOpt.Format(ctx)
			ctx.WriteString(" ) ")
		}
	}
	for _, checkExpr := range node.CheckExprs {
		if checkExpr.ConstraintName != "" {
			ctx.WriteString(" CONSTRAINT ")
			ctx.FormatNode(&checkExpr.ConstraintName)
		}
		ctx.WriteString(" CHECK (")
		ctx.FormatNode(checkExpr.Expr)
		ctx.WriteByte(')')
	}
	if node.HasFKConstraint() {
		if node.References.ConstraintName != "" {
			ctx.WriteString(" CONSTRAINT ")
			ctx.FormatNode(&node.References.ConstraintName)
		}
		ctx.WriteString(" REFERENCES ")
		ctx.FormatNode(node.References.Table)
		if node.References.Col != "" {
			ctx.WriteString(" (")
			ctx.FormatNode(&node.References.Col)
			ctx.WriteByte(')')
		}
		if node.References.Match != MatchSimple {
			ctx.WriteByte(' ')
			ctx.WriteString(node.References.Match.String())
		}
		ctx.FormatNode(&node.References.Actions)
	}
	if node.IsComputed() {
		ctx.WriteString(" AS (")
		ctx.FormatNode(node.Computed.Expr)
		if node.Computed.Virtual {
			ctx.WriteString(") VIRTUAL")
		} else {
			ctx.WriteString(") STORED")
		}
	}
	if node.HasColumnFamily() {
		if node.Family.Create {
			ctx.WriteString(" CREATE")
			if node.Family.IfNotExists {
				ctx.WriteString(" IF NOT EXISTS")
			}
		}
		ctx.WriteString(" FAMILY")
		if len(node.Family.Name) > 0 {
			ctx.WriteByte(' ')
			ctx.FormatNode(&node.Family.Name)
		}
	}
}

// SQLRight Code Injection.
func (node *ColumnTableDef) LogCurrentNode(depth int) *SQLRightIR {

	nameStr := node.Name.String()
	LNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataColumnName,
		ContextFlag: ContextDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         nameStr,
	}

	var RNode *SQLRightIR
	if node.Type != nil {
		typeStr := node.columnTypeString()
		RNode = &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataTypeName,
			ContextFlag: ContextDefine,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         typeStr,
		}
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	if node.Nullable.Nullability != SilentNull && node.Nullable.ConstraintName != "" {
		constraintStr := node.Nullable.ConstraintName.String()
		RNode = &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataConstraintName,
			ContextFlag: ContextDefine,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         constraintStr,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    "  CONSTRAINT ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	switch node.Nullable.Nullability {
	case Null:
		RNode = &SQLRightIR{
			IRType:   TypeNullability,
			DataType: DataNone,
			//LNode:  LNode,
			//RNode:  RNode,
			Prefix: " NULL",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	case NotNull:
		RNode = &SQLRightIR{
			IRType:   TypeNullability,
			DataType: DataNone,
			//LNode:  LNode,
			//RNode:  RNode,
			Prefix: " NOT NULL",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		LNode = rootIR
	}

	if node.Hidden {
		RNode = &SQLRightIR{
			IRType:   TypeOptNotVisible,
			DataType: DataNone,
			//LNode:  LNode,
			//RNode:  RNode,
			Prefix: " NOT VISIBLE",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	} else {
		RNode = &SQLRightIR{
			IRType:   TypeOptNotVisible,
			DataType: DataNone,
			//LNode:  LNode,
			//RNode:  RNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.PrimaryKey.IsPrimaryKey || node.Unique.IsUnique {
		if node.Unique.ConstraintName != "" {
			constraintName := node.Unique.ConstraintName.String()
			RNode = &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataConstraintName,
				ContextFlag: ContextDefine,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         constraintName,
			}

			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    RNode,
				Prefix:   "",
				Infix:    " CONSTRAINT ",
				Suffix:   "",
				Depth:    depth,
			}
		}
		if node.PrimaryKey.IsPrimaryKey {

			// PRIMARY KEY
			RNode = &SQLRightIR{
				IRType:   TypePrimaryKey,
				DataType: DataNone,
				//LNode:  LNode,
				//RNode:  RNode,
				Prefix: "",
				Infix:  " PRIMARY KEY ",
				Suffix: "",
				Depth:  depth,
			}

			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    RNode,
				Prefix:   "",
				Infix:    "",
				Suffix:   "",
				Depth:    depth,
			}

			// Keep original. StorageParams handling logic.
			// Always prefer to output hash sharding bucket count as a storage param.
			infix := ""
			pkStorageParams := node.PrimaryKey.StorageParams
			if node.PrimaryKey.Sharded {
				infix += " USING HASH"
				bcStorageParam := node.PrimaryKey.StorageParams.GetVal(`bucket_count`)
				if _, ok := node.PrimaryKey.ShardBuckets.(DefaultVal); !ok && bcStorageParam == nil {
					pkStorageParams = append(
						pkStorageParams,
						StorageParam{
							Key:   `bucket_count`,
							Value: node.PrimaryKey.ShardBuckets,
						},
					)
				}
			}
			if len(pkStorageParams) > 0 {
				infix += " WITH ("
				pRNode := pkStorageParams.LogCurrentNode(depth + 1)

				rootIR = &SQLRightIR{
					IRType:   TypeUnknown,
					DataType: DataNone,
					LNode:    rootIR,
					RNode:    pRNode,
					Prefix:   "",
					Infix:    infix,
					Suffix:   ")",
					Depth:    depth,
				}
			}
		} else if node.Unique.IsUnique {
			tmpUniStr := " UNIQUE "
			RNode = &SQLRightIR{
				IRType:   TypeOptUnique,
				DataType: DataNone,
				//LNode:    LNode,
				//RNode:    RNode,
				Prefix: tmpUniStr,
				Infix:  "",
				Suffix: "",
				Depth:  depth,
			}
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    RNode, // opt unique
				Prefix:   "",
				Infix:    "",
				Suffix:   "",
				Depth:    depth,
			}

			if node.Unique.WithoutIndex {
				woutIndex := " WITHOUT INDEX"
				RNode = &SQLRightIR{
					IRType:   TypeOptWithoutIndex,
					DataType: DataNone,
					//LNode:    LNode,
					//RNode:    RNode,
					Prefix: woutIndex,
					Infix:  "",
					Suffix: "",
					Depth:  depth,
				}
				rootIR = &SQLRightIR{
					IRType:   TypeUnknown,
					DataType: DataNone,
					LNode:    rootIR,
					RNode:    RNode, // opt without index
					Prefix:   "",
					Infix:    "",
					Suffix:   "",
					Depth:    depth,
				}
			}
		}
	}

	if node.HasDefaultExpr() {
		if node.DefaultExpr.ConstraintName != "" {
			constraintName := node.DefaultExpr.ConstraintName.String()
			RNode = &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataConstraintName,
				ContextFlag: ContextDefine,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         constraintName,
			}

			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    RNode,
				Prefix:   "",
				Infix:    " CONSTRAINT ",
				Suffix:   "",
				Depth:    depth,
			}
		}

		// DEFAULT EXPR
		pDefaultExpr := node.DefaultExpr.Expr.LogCurrentNode(depth + 1)
		defaultNode := &SQLRightIR{
			IRType:   TypeDefaultExpr,
			DataType: DataNone,
			LNode:    pDefaultExpr,
			//RNode:    pRNode,
			Prefix: " DEFAULT ",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    defaultNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.HasOnUpdateExpr() {
		if node.OnUpdateExpr.ConstraintName != "" {
			constraintName := node.OnUpdateExpr.ConstraintName.String()
			RNode = &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataConstraintName,
				ContextFlag: ContextDefine,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         constraintName,
			}

			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   "",
				Infix:    " CONSTRAINT ",
				Suffix:   "",
				Depth:    depth,
			}
		}

		// ON UPDATE
		pOnUpdateExpr := node.OnUpdateExpr.Expr.LogCurrentNode(depth + 1)
		onUpdateNode := &SQLRightIR{
			IRType:   TypeOnUpdateExpr,
			DataType: DataNone,
			LNode:    pOnUpdateExpr,
			//RNode:    pRNode,
			Prefix: " ON UPDATE ",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    onUpdateNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.GeneratedIdentity.IsGeneratedAsIdentity {
		identityStr := ""
		switch node.GeneratedIdentity.GeneratedAsIdentityType {
		case GeneratedAlways:
			identityStr = " GENERATED ALWAYS AS IDENTITY"
		case GeneratedByDefault:
			identityStr = " GENERATED BY DEFAULT AS IDENTITY"
		}
		RNode = &SQLRightIR{
			IRType:   TypeGeneratedIdentity,
			DataType: DataNone,
			//LNode:  LNode,
			//RNode:  RNode,
			Prefix: identityStr,
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		if genSeqOpt := node.GeneratedIdentity.SeqOptions; genSeqOpt != nil {
			tmpRNode := genSeqOpt.LogCurrentNode(depth + 1)
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    tmpRNode,
				Prefix:   "",
				Infix:    " (",
				Suffix:   " ) ",
				Depth:    depth,
			}
		}
	}

	for _, checkExpr := range node.CheckExprs {
		if checkExpr.ConstraintName != "" {
			prefix := " CONSTRAINT "
			constraintNameStr := checkExpr.ConstraintName.String()

			constrNode := &SQLRightIR{
				IRType:   TypeIdentifier,
				DataType: DataConstraintName,
				Prefix:   "",
				Infix:    "",
				Suffix:   "",
				Depth:    depth,
				Str:      constraintNameStr,
			}

			constrNode = &SQLRightIR{
				IRType:   TypeConstraintCluster,
				DataType: DataNone,
				LNode:    constrNode,
				Prefix:   prefix,
				Infix:    "",
				Suffix:   "",
				Depth:    depth,
			}

			rootIR = &SQLRightIR{
				IRType:   TypeConstraintCluster,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    constrNode,
				Prefix:   "",
				Infix:    "",
				Suffix:   "",
				Depth:    depth,
			}
		}

		infix := " CHECK ("
		exprNode := checkExpr.Expr.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    exprNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   ")",
			Depth:    depth,
		}
	}

	if node.HasFKConstraint() {
		if node.References.ConstraintName != "" {
			constraintName := node.References.ConstraintName.String()
			RNode = &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataConstraintName,
				ContextFlag: ContextDefine,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         constraintName,
			}

			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    RNode,
				Prefix:   "",
				Infix:    " CONSTRAINT ",
				Suffix:   "",
				Depth:    depth,
			}
		}

		tableNameStr := node.References.Table.String()
		tableInReference := &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataTableName,
			ContextFlag: ContextUse, // Foreign Table.
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         tableNameStr,
		}

		//rootIR = &SQLRightIR{
		//	IRType:   TypeUnknown,
		//	DataType: DataNone,
		//	LNode:  LNode,
		//	RNode:  RNode,
		//	Prefix:   "",
		//	Infix:    "",
		//	Suffix:   "",
		//	Depth:    depth,
		//}
		//LNode = rootIR

		var pRNode *SQLRightIR
		infix := ""
		suffix := ""
		if node.References.Col != "" {
			columnStr := node.References.Col.String()
			RNode = &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataColumnName,
				ContextFlag: ContextUse, // Foreign Column
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         columnStr,
			}
			pRNode = RNode
			infix = " ("
			suffix = ")"
		}

		referClusterNode := &SQLRightIR{
			IRType:   TypeUnknown, //TypeReferenceCluster
			DataType: DataNone,
			LNode:    tableInReference,
			RNode:    pRNode, // Col
			Prefix:   " REFERENCES ",
			Infix:    infix,
			Suffix:   suffix,
			Depth:    depth,
		}

		if node.References.Match != MatchSimple {
			matchStr := node.References.Match.String()
			matchLiteralNode := &SQLRightIR{
				IRType:       TypeStringLiteral, // Using string literal here. Not sure.
				DataType:     DataLiteral,
				DataAffinity: AFFIUNKNOWN, // Unknown affinity
				Prefix:       "",
				Infix:        "",
				Suffix:       "",
				Depth:        depth,
				Str:          "'" + matchStr + "'",
			}

			matchNode := &SQLRightIR{
				IRType:   TypeUnknown, // Using string literal here. Not sure.
				DataType: DataNone,
				LNode:    matchLiteralNode,
				//RNode:    RNode,
				Prefix: " ",
				Infix:  "",
				Suffix: "",
				Depth:  depth,
			}

			referClusterNode = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    referClusterNode,
				RNode:    matchNode,
				Prefix:   "",
				Infix:    "",
				Suffix:   "",
				Depth:    depth,
			}
		}
		actionNode := node.References.Actions.LogCurrentNode(depth + 1)
		referClusterNode = &SQLRightIR{
			IRType:   TypeReferenceCluster,
			DataType: DataNone,
			LNode:    referClusterNode,
			RNode:    actionNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    referClusterNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	}

	if node.IsComputed() {
		pRNode := node.Computed.Expr.LogCurrentNode(depth + 1)
		suffix := ""
		if node.Computed.Virtual {
			suffix += ") VIRTUAL"
		} else {
			suffix += ") STORED"
		}
		rootIR = &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataNone,
			ContextFlag: ContextUnknown,
			LNode:       rootIR,
			RNode:       pRNode,
			Prefix:      "",
			Infix:       " AS (",
			Suffix:      suffix,
			Depth:       depth,
		}
	}

	if node.HasColumnFamily() {
		infix := ""
		if node.Family.Create {
			infix += " CREATE"
			if node.Family.IfNotExists {
				RNode = &SQLRightIR{
					IRType:   TypeOptIfNotExists,
					DataType: DataNone,
					//LNode:    LNode,
					//RNode:    RNode,
					Prefix: " IF NOT EXISTS",
					Infix:  "",
					Suffix: "",
					Depth:  depth,
				}
				rootIR = &SQLRightIR{
					IRType:   TypeUnknown,
					DataType: DataNone,
					LNode:    rootIR,
					RNode:    RNode,
					Prefix:   "",
					Infix:    infix,
					Suffix:   "",
					Depth:    depth,
				}
			}
		}

		familyNode := &SQLRightIR{
			IRType:      TypeUnknown,
			DataType:    DataNone,
			ContextFlag: ContextDefine,
			Prefix:      " FAMILY",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    familyNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		if len(node.Family.Name) > 0 {
			familyNameNode := &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataFamilyName,
				ContextFlag: ContextDefine,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         node.Family.Name.String(),
			}

			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    familyNameNode,
				Prefix:   "",
				Infix:    " ",
				Suffix:   "",
				Depth:    depth,
			}
		}
	}

	rootIR.IRType = TypeColumnTableDef
	return rootIR
}

func (node *ColumnTableDef) columnTypeString() string {
	if node.IsSerial {
		// Map INT types to SERIAL keyword.
		// TODO (rohany): This should be pushed until type resolution occurs.
		//  However, the argument is that we deal with serial at parse time only,
		//  so we handle those cases here.
		switch MustBeStaticallyKnownType(node.Type).Width() {
		case 16:
			return "SERIAL2"
		case 32:
			return "SERIAL4"
		}
		return "SERIAL8"
	}
	return node.Type.SQLString()
}

// String implements the fmt.Stringer interface.
func (node *ColumnTableDef) String() string { return AsString(node) }

// NamedColumnQualification wraps a NamedColumnQualification with a name.
type NamedColumnQualification struct {
	Name          Name
	Qualification ColumnQualification
}

// ColumnQualification represents a constraint on a column.
type ColumnQualification interface {
	columnQualification()
}

func (ColumnCollation) columnQualification()             {}
func (*ColumnDefault) columnQualification()              {}
func (*ColumnOnUpdate) columnQualification()             {}
func (NotNullConstraint) columnQualification()           {}
func (NullConstraint) columnQualification()              {}
func (HiddenConstraint) columnQualification()            {}
func (PrimaryKeyConstraint) columnQualification()        {}
func (ShardedPrimaryKeyConstraint) columnQualification() {}
func (UniqueConstraint) columnQualification()            {}
func (*ColumnCheckConstraint) columnQualification()      {}
func (*ColumnComputedDef) columnQualification()          {}
func (*ColumnFKConstraint) columnQualification()         {}
func (*ColumnFamilyConstraint) columnQualification()     {}
func (*GeneratedAlwaysAsIdentity) columnQualification()  {}
func (*GeneratedByDefAsIdentity) columnQualification()   {}

// ColumnCollation represents a COLLATE clause for a column.
type ColumnCollation string

// ColumnDefault represents a DEFAULT clause for a column.
type ColumnDefault struct {
	Expr Expr
}

// ColumnOnUpdate represents a ON UPDATE clause for a column.
type ColumnOnUpdate struct {
	Expr Expr
}

// GeneratedAlwaysAsIdentity represents a column generated always as identity.
type GeneratedAlwaysAsIdentity struct {
	SeqOptions SequenceOptions
}

// GeneratedByDefAsIdentity represents a column generated by default as identity.
type GeneratedByDefAsIdentity struct {
	SeqOptions SequenceOptions
}

// NotNullConstraint represents NOT NULL on a column.
type NotNullConstraint struct{}

// NullConstraint represents NULL on a column.
type NullConstraint struct{}

// HiddenConstraint represents HIDDEN on a column.
type HiddenConstraint struct{}

// PrimaryKeyConstraint represents PRIMARY KEY on a column.
type PrimaryKeyConstraint struct {
	StorageParams StorageParams
}

// ShardedPrimaryKeyConstraint represents `PRIMARY KEY .. USING HASH..`
// on a column.
type ShardedPrimaryKeyConstraint struct {
	Sharded       bool
	ShardBuckets  Expr
	StorageParams StorageParams
}

// UniqueConstraint represents UNIQUE on a column.
type UniqueConstraint struct {
	WithoutIndex bool
}

// ColumnCheckConstraint represents either a check on a column.
type ColumnCheckConstraint struct {
	Expr Expr
}

// ColumnFKConstraint represents a FK-constaint on a column.
type ColumnFKConstraint struct {
	Table   TableName
	Col     Name // empty-string means use PK
	Actions ReferenceActions
	Match   CompositeKeyMatchMethod
}

// ColumnComputedDef represents the description of a computed column.
type ColumnComputedDef struct {
	Expr    Expr
	Virtual bool
}

// ColumnFamilyConstraint represents FAMILY on a column.
type ColumnFamilyConstraint struct {
	Family      Name
	Create      bool
	IfNotExists bool
}

// IndexTableDef represents an index definition within a CREATE TABLE
// statement.
type IndexTableDef struct {
	Name             Name
	Columns          IndexElemList
	Sharded          *ShardedIndexDef
	Storing          NameList
	Inverted         bool
	PartitionByIndex *PartitionByIndex
	StorageParams    StorageParams
	Predicate        Expr
	NotVisible       bool
}

// Format implements the NodeFormatter interface.
func (node *IndexTableDef) Format(ctx *FmtCtx) {
	if node.Inverted {
		ctx.WriteString("INVERTED ")
	}
	ctx.WriteString("INDEX ")
	if node.Name != "" {
		ctx.FormatNode(&node.Name)
		ctx.WriteByte(' ')
	}
	ctx.WriteByte('(')
	ctx.FormatNode(&node.Columns)
	ctx.WriteByte(')')
	if node.Sharded != nil {
		ctx.FormatNode(node.Sharded)
	}
	if node.Storing != nil {
		ctx.WriteString(" STORING (")
		ctx.FormatNode(&node.Storing)
		ctx.WriteByte(')')
	}
	if node.PartitionByIndex != nil {
		ctx.FormatNode(node.PartitionByIndex)
	}
	if node.StorageParams != nil {
		ctx.WriteString(" WITH (")
		ctx.FormatNode(&node.StorageParams)
		ctx.WriteString(")")
	}
	if node.Predicate != nil {
		ctx.WriteString(" WHERE ")
		ctx.FormatNode(node.Predicate)
	}
	if node.NotVisible {
		ctx.WriteString(" NOT VISIBLE")
	}
}

// SQLRight Code Injection.
func (node *IndexTableDef) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""
	if node.Inverted {
		prefix += "INVERTED"
	}
	LNode := &SQLRightIR{
		IRType:   TypeOptInverted,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	nameStr := ""
	if node.Name.String() != "" && node.Name.String() != "\"\"" {
		nameStr = node.Name.String()
	}
	RNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataIndexName,
		ContextFlag: ContextDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         nameStr,
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "",
		Infix:    " INDEX ",
		Suffix:   "",
		Depth:    depth,
	}

	pRNode := node.Columns.LogCurrentNode(depth+1, ContextUse)
	rootIR = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    pRNode,
		Prefix:   "",
		Infix:    "(",
		Suffix:   ")",
		Depth:    depth,
	}

	if node.Sharded != nil {
		pRNode = node.Sharded.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    pRNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	// opt storing
	if node.Storing != nil {
		pStoringNode := node.Storing.LogCurrentNodeWithType(depth+1, DataColumnName)
		optStoringNode := &SQLRightIR{
			IRType:   TypeOptStoring,
			DataType: DataNone,
			LNode:    pStoringNode,
			//RNode:    pRNode,
			Prefix: " STORING (",
			Infix:  ")",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optStoringNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	} else {
		optStoringNode := &SQLRightIR{
			IRType:   TypeOptStoring,
			DataType: DataNone,
			//LNode:    pStoringNode,
			//RNode:    pRNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optStoringNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	}

	// opt partition by index
	if node.PartitionByIndex != nil {
		pParBy := node.PartitionByIndex.LogCurrentNode(depth + 1)
		optPartitionNode := &SQLRightIR{
			IRType:   TypeOptPartitionBy,
			DataType: DataNone,
			LNode:    pParBy,
			//RNode:    pRNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optPartitionNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	} else {
		optPartitionNode := &SQLRightIR{
			IRType:   TypeOptPartitionBy,
			DataType: DataNone,
			//LNode:    pStoringNode,
			//RNode:    pRNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optPartitionNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	}

	// opt StorageParams
	if node.StorageParams != nil {
		pStorageParams := node.StorageParams.LogCurrentNode(depth + 1)
		optStorageParams := &SQLRightIR{
			IRType:   TypeOptStorageParams,
			DataType: DataNone,
			LNode:    pStorageParams,
			//RNode:    pRNode,
			Prefix: " WITH (",
			Infix:  ")",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optStorageParams,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	} else {
		optPartitionNode := &SQLRightIR{
			IRType:   TypeOptStorageParams,
			DataType: DataNone,
			//LNode:    pStoringNode,
			//RNode:    pRNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optPartitionNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	}

	// opt predicate
	if node.Predicate != nil {
		pPredicate := node.Predicate.LogCurrentNode(depth + 1)
		optPredicate := &SQLRightIR{
			IRType:   TypeOptPredicate,
			DataType: DataNone,
			LNode:    pPredicate,
			//RNode:    pRNode,
			Prefix: " WHERE ",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optPredicate,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	} else {
		optPredicate := &SQLRightIR{
			IRType:   TypeOptPredicate,
			DataType: DataNone,
			//LNode:    pStoringNode,
			//RNode:    pRNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optPredicate,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	// opt VISIBLE
	notVisibleStr := ""
	if node.NotVisible {
		notVisibleStr = " NOT VISIBLE"
	}
	optNotVisible := &SQLRightIR{
		IRType:   TypeOptNotVisible,
		DataType: DataNone,
		//LNode:    ,
		//RNode:    ,
		Prefix: notVisibleStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}
	rootIR = &SQLRightIR{
		IRType:   TypeIndexTableDef,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    optNotVisible,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ConstraintTableDef represents a constraint definition within a CREATE TABLE
// statement.
type ConstraintTableDef interface {
	TableDef
	// Placeholder function to ensure that only desired types
	// (*ConstraintTableDef) conform to the ConstraintTableDef interface.
	constraintTableDef()

	// SetName replaces the name of the definition in-place. Used in the parser.
	SetName(name Name)

	// SetIfNotExists sets this definition as coming from an
	// ADD CONSTRAINT IF NOT EXISTS statement. Used in the parser.
	SetIfNotExists()
}

func (*UniqueConstraintTableDef) constraintTableDef()     {}
func (*ForeignKeyConstraintTableDef) constraintTableDef() {}
func (*CheckConstraintTableDef) constraintTableDef()      {}

// UniqueConstraintTableDef represents a unique constraint within a CREATE
// TABLE statement.
type UniqueConstraintTableDef struct {
	IndexTableDef
	PrimaryKey   bool
	WithoutIndex bool
	IfNotExists  bool
}

// SetName implements the TableDef interface.
func (node *UniqueConstraintTableDef) SetName(name Name) {
	node.Name = name
}

// SetIfNotExists implements the ConstraintTableDef interface.
func (node *UniqueConstraintTableDef) SetIfNotExists() {
	node.IfNotExists = true
}

// Format implements the NodeFormatter interface.
func (node *UniqueConstraintTableDef) Format(ctx *FmtCtx) {
	if node.Name != "" {
		ctx.WriteString("CONSTRAINT ")
		if node.IfNotExists {
			ctx.WriteString("IF NOT EXISTS ")
		}
		ctx.FormatNode(&node.Name)
		ctx.WriteByte(' ')
	}
	if node.PrimaryKey {
		ctx.WriteString("PRIMARY KEY ")
	} else {
		ctx.WriteString("UNIQUE ")
	}
	if node.WithoutIndex {
		ctx.WriteString("WITHOUT INDEX ")
	}
	ctx.WriteByte('(')
	ctx.FormatNode(&node.Columns)
	ctx.WriteByte(')')
	if node.Sharded != nil {
		ctx.FormatNode(node.Sharded)
	}
	if node.Storing != nil {
		ctx.WriteString(" STORING (")
		ctx.FormatNode(&node.Storing)
		ctx.WriteByte(')')
	}
	if node.PartitionByIndex != nil {
		ctx.FormatNode(node.PartitionByIndex)
	}
	if node.Predicate != nil {
		ctx.WriteString(" WHERE ")
		ctx.FormatNode(node.Predicate)
	}
	if node.NotVisible {
		ctx.WriteString(" NOT VISIBLE")
	}
}

// SQLRight Code Injection.
func (node *UniqueConstraintTableDef) LogCurrentNode(depth int) *SQLRightIR {

	var LNode *SQLRightIR
	var rootIR *SQLRightIR
	if node.Name != "" {
		prefix := ""
		if node.IfNotExists {
			prefix = "IF NOT EXISTS "
		}
		LNode = &SQLRightIR{
			IRType:   TypeOptIfNotExists,
			DataType: DataNone,
			//LNode:    LNode,
			//RNode:    RNode,
			Prefix: prefix,
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}

		RNode := &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataConstraintName,
			ContextFlag: ContextDefine,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Name.String(),
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    LNode, // IF NOT EXISTS
			RNode:    RNode, // NAME
			Prefix:   "CONSTRAINT ",
			Infix:    "",
			Suffix:   " ",
			Depth:    depth,
		}
	}

	if node.PrimaryKey {
		RNode := &SQLRightIR{
			IRType:   TypePrimaryKey,
			DataType: DataNone,
			//LNode:    LNode,
			//RNode:    RNode,
			Prefix: "PRIMARY KEY",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	} else {
		RNode := &SQLRightIR{
			IRType:   TypeOptUnique,
			DataType: DataNone,
			//LNode:    LNode,
			//RNode:    RNode,
			Prefix: "UNIQUE ",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.WithoutIndex {
		RNode := &SQLRightIR{
			IRType:   TypeOptWithoutIndex,
			DataType: DataNone,
			//LNode:    LNode,
			//RNode:    RNode,
			Prefix: "WITHOUT INDEX ",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	pRNode := node.Columns.LogCurrentNode(depth+1, ContextUse)
	rootIR = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    pRNode,
		Prefix:   "",
		Infix:    "(",
		Suffix:   ")",
		Depth:    depth,
	}

	if node.Sharded != nil {
		pRNode = node.Sharded.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    pRNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	// opt storing
	if node.Storing != nil {
		pStoringNode := node.Storing.LogCurrentNodeWithType(depth+1, DataColumnName)
		optStoringNode := &SQLRightIR{
			IRType:   TypeOptStoring,
			DataType: DataNone,
			LNode:    pStoringNode,
			//RNode:    pRNode,
			Prefix: " STORING (",
			Infix:  ")",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optStoringNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	} else {
		optStoringNode := &SQLRightIR{
			IRType:   TypeOptStoring,
			DataType: DataNone,
			//LNode:    pStoringNode,
			//RNode:    pRNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optStoringNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	}

	// opt partition by index
	if node.PartitionByIndex != nil {
		pParBy := node.PartitionByIndex.LogCurrentNode(depth + 1)
		optPartitionNode := &SQLRightIR{
			IRType:   TypeOptPartitionBy,
			DataType: DataNone,
			LNode:    pParBy,
			//RNode:    pRNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optPartitionNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	} else {
		optPartitionNode := &SQLRightIR{
			IRType:   TypeOptPartitionBy,
			DataType: DataNone,
			//LNode:    pStoringNode,
			//RNode:    pRNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optPartitionNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	}

	// opt predicate
	if node.Predicate != nil {
		pPredicate := node.Predicate.LogCurrentNode(depth + 1)
		optPredicate := &SQLRightIR{
			IRType:   TypeOptPredicate,
			DataType: DataNone,
			LNode:    pPredicate,
			//RNode:    pRNode,
			Prefix: " WHERE ",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optPredicate,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	} else {
		optPredicate := &SQLRightIR{
			IRType:   TypeOptPredicate,
			DataType: DataNone,
			//LNode:    pStoringNode,
			//RNode:    pRNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optPredicate,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	// opt VISIBLE
	notVisibleStr := ""
	if node.NotVisible {
		notVisibleStr = " NOT VISIBLE"
	}
	optNotVisible := &SQLRightIR{
		IRType:   TypeOptNotVisible,
		DataType: DataNone,
		//LNode:    ,
		//RNode:    ,
		Prefix: notVisibleStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}
	rootIR = &SQLRightIR{
		IRType:   TypeUniqueConstraintTableDef,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    optNotVisible,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ReferenceAction is the method used to maintain referential integrity through
// foreign keys.
type ReferenceAction int

// The values for ReferenceAction.
const (
	NoAction ReferenceAction = iota
	Restrict
	SetNull
	SetDefault
	Cascade
)

var referenceActionName = [...]string{
	NoAction:   "NO ACTION",
	Restrict:   "RESTRICT",
	SetNull:    "SET NULL",
	SetDefault: "SET DEFAULT",
	Cascade:    "CASCADE",
}

func (ra ReferenceAction) String() string {
	return referenceActionName[ra]
}

// ReferenceActions contains the actions specified to maintain referential
// integrity through foreign keys for different operations.
type ReferenceActions struct {
	Delete ReferenceAction
	Update ReferenceAction
}

// Format implements the NodeFormatter interface.
func (node *ReferenceActions) Format(ctx *FmtCtx) {
	if node.Delete != NoAction {
		ctx.WriteString(" ON DELETE ")
		ctx.WriteString(node.Delete.String())
	}
	if node.Update != NoAction {
		ctx.WriteString(" ON UPDATE ")
		ctx.WriteString(node.Update.String())
	}
}

// SQLRight Code Injection.
func (node *ReferenceActions) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""
	if node.Delete != NoAction {
		prefix = " ON DELETE "
		prefix += node.Delete.String()

		rootIR := &SQLRightIR{
			IRType:   TypeReferenceActions,
			DataType: DataNone,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		return rootIR
	}
	if node.Update != NoAction {
		prefix = " ON UPDATE "
		prefix += node.Update.String()

		rootIR := &SQLRightIR{
			IRType:   TypeReferenceActions,
			DataType: DataNone,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		return rootIR
	}

	rootIR := &SQLRightIR{
		IRType:   TypeReferenceActions,
		DataType: DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}
	return rootIR

}

// CompositeKeyMatchMethod is the algorithm use when matching composite keys.
// See https://github.com/cockroachdb/cockroach/issues/20305 or
// https://www.postgresql.org/docs/11/sql-createtable.html for details on the
// different composite foreign key matching methods.
type CompositeKeyMatchMethod int

// The values for CompositeKeyMatchMethod.
const (
	MatchSimple CompositeKeyMatchMethod = iota
	MatchFull
	MatchPartial // Note: PARTIAL not actually supported at this point.
)

var compositeKeyMatchMethodName = [...]string{
	MatchSimple:  "MATCH SIMPLE",
	MatchFull:    "MATCH FULL",
	MatchPartial: "MATCH PARTIAL",
}

func (c CompositeKeyMatchMethod) String() string {
	return compositeKeyMatchMethodName[c]
}

// ForeignKeyConstraintTableDef represents a FOREIGN KEY constraint in the AST.
type ForeignKeyConstraintTableDef struct {
	Name        Name
	Table       TableName
	FromCols    NameList
	ToCols      NameList
	Actions     ReferenceActions
	Match       CompositeKeyMatchMethod
	IfNotExists bool
}

// Format implements the NodeFormatter interface.
func (node *ForeignKeyConstraintTableDef) Format(ctx *FmtCtx) {
	if node.Name != "" {
		ctx.WriteString("CONSTRAINT ")
		if node.IfNotExists {
			ctx.WriteString("IF NOT EXISTS ")
		}
		ctx.FormatNode(&node.Name)
		ctx.WriteByte(' ')
	}
	ctx.WriteString("FOREIGN KEY (")
	ctx.FormatNode(&node.FromCols)
	ctx.WriteString(") REFERENCES ")
	ctx.FormatNode(&node.Table)

	if len(node.ToCols) > 0 {
		ctx.WriteByte(' ')
		ctx.WriteByte('(')
		ctx.FormatNode(&node.ToCols)
		ctx.WriteByte(')')
	}

	if node.Match != MatchSimple {
		ctx.WriteByte(' ')
		ctx.WriteString(node.Match.String())
	}

	ctx.FormatNode(&node.Actions)
}

// SQLRight Code Injection.
func (node *ForeignKeyConstraintTableDef) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""
	var pRootIR *SQLRightIR
	if node.Name != "" {
		prefix += "CONSTRAINT "

		optIfNotExistStr := ""
		if node.IfNotExists {
			optIfNotExistStr = "IF NOT EXISTS "
		}
		ifNotExistsNode := &SQLRightIR{
			IRType:   TypeOptIfNotExists,
			DataType: DataNone,
			Prefix:   optIfNotExistStr,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		nameNode := &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataConstraintName,
			ContextFlag: ContextDefine,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Name.String(),
		}

		rootIR := &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    ifNotExistsNode,
			RNode:    nameNode,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		pRootIR = rootIR
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    pRootIR, // Could be empty node.
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	infix := "FOREIGN KEY ("
	fromCol := node.FromCols.LogCurrentNode(depth + 1)

	rootIR = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    fromCol,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	infix = ") REFERENCES "
	tableNode := node.Table.LogCurrentNode(depth + 1)

	rootIR = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    tableNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	if len(node.ToCols) > 0 {
		infix = " ("
		toColNode := node.ToCols.LogCurrentNode(depth + 1)
		suffix := ")"

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    toColNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   suffix,
			Depth:    depth,
		}
	}

	infix = " "

	if node.Match != MatchSimple {
		infix = " "
		matchNode := &SQLRightIR{
			IRType:   TypeMatching,
			DataType: DataUnknownType, // TODO: FIXME: Data type unknown.
			Prefix:   node.Match.String(),
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    matchNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeForeignKeyConstraintTableDef

	return rootIR
}

// SetName implements the ConstraintTableDef interface.
func (node *ForeignKeyConstraintTableDef) SetName(name Name) {
	node.Name = name
}

// SetIfNotExists implements the ConstraintTableDef interface.
func (node *ForeignKeyConstraintTableDef) SetIfNotExists() {
	node.IfNotExists = true
}

// CheckConstraintTableDef represents a check constraint within a CREATE
// TABLE statement.
type CheckConstraintTableDef struct {
	Name        Name
	Expr        Expr
	Hidden      bool
	IfNotExists bool
}

// SetName implements the ConstraintTableDef interface.
func (node *CheckConstraintTableDef) SetName(name Name) {
	node.Name = name
}

// SetIfNotExists implements the ConstraintTableDef interface.
func (node *CheckConstraintTableDef) SetIfNotExists() {
	node.IfNotExists = true
}

// Format implements the NodeFormatter interface.
func (node *CheckConstraintTableDef) Format(ctx *FmtCtx) {
	if node.Name != "" {
		ctx.WriteString("CONSTRAINT ")
		if node.IfNotExists {
			ctx.WriteString("IF NOT EXISTS ")
		}
		ctx.FormatNode(&node.Name)
		ctx.WriteByte(' ')
	}
	ctx.WriteString("CHECK (")
	ctx.FormatNode(node.Expr)
	ctx.WriteByte(')')
}

// SQLRight Code Injection.
func (node *CheckConstraintTableDef) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""

	var ifNotExistsNode *SQLRightIR
	var nameNode *SQLRightIR
	if node.Name != "" {
		prefix += "CONSTRAINT "

		optIfNotExistStr := ""
		if node.IfNotExists {
			optIfNotExistStr = "IF NOT EXISTS "
		}
		ifNotExistsNode = &SQLRightIR{
			IRType:   TypeOptIfNotExists,
			DataType: DataNone,
			//LNode:    LNode,
			//RNode:    RNode,
			Prefix: optIfNotExistStr,
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}

		tmpNameNode := &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataConstraintName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Name.String(),
		}
		nameNode = tmpNameNode
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    ifNotExistsNode,
		RNode:    nameNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	exprNode := node.Expr.LogCurrentNode(depth + 1)
	infix := "CHECK ("
	suffix := ")"

	rootIR = &SQLRightIR{
		IRType:   TypeCheckConstraintTableDef,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    exprNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   suffix,
		Depth:    depth,
	}

	return rootIR
}

// FamilyTableDef represents a family definition within a CREATE TABLE
// statement.
type FamilyTableDef struct {
	Name    Name
	Columns NameList
}

// Format implements the NodeFormatter interface.
func (node *FamilyTableDef) Format(ctx *FmtCtx) {
	ctx.WriteString("FAMILY ")
	if node.Name != "" {
		ctx.FormatNode(&node.Name)
		ctx.WriteByte(' ')
	}
	ctx.WriteByte('(')
	ctx.FormatNode(&node.Columns)
	ctx.WriteByte(')')
}

// SQLRight Code Injection.
func (node *FamilyTableDef) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "FAMILY "

	var nameNode *SQLRightIR
	if node.Name != "" {
		tmpNameNode := &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataFamilyName,
			ContextFlag: ContextDefine,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Name.String(),
		}
		nameNode = tmpNameNode
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    nameNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	infix := "("
	suffix := ")"

	columnsNode := node.Columns.LogCurrentNodeWithType(depth+1, DataColumnName)

	rootIR = &SQLRightIR{
		IRType:   TypeFamilyTableDef,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    columnsNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   suffix,
		Depth:    depth,
	}

	return rootIR
}

// ShardedIndexDef represents a hash sharded secondary index definition within a CREATE
// TABLE or CREATE INDEX statement.
type ShardedIndexDef struct {
	ShardBuckets Expr
}

// Format implements the NodeFormatter interface.
func (node *ShardedIndexDef) Format(ctx *FmtCtx) {
	if _, ok := node.ShardBuckets.(DefaultVal); ok {
		ctx.WriteString(" USING HASH")
		return
	}
	ctx.WriteString(" USING HASH WITH BUCKET_COUNT = ")
	ctx.FormatNode(node.ShardBuckets)
}

// SQLRight Code Injection.
func (node *ShardedIndexDef) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""
	if _, ok := node.ShardBuckets.(DefaultVal); ok {
		prefix = " USING HASH"

		rootIR := &SQLRightIR{
			IRType:   TypeShardedIndexDef,
			DataType: DataNone,
			//LNode:    pLNode,
			//RNode:    RNode,
			Prefix: prefix,
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}

		return rootIR
	}

	prefix = " USING HASH WITH BUCKET_COUNT = "
	pLNode := node.ShardBuckets.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeShardedIndexDef,
		DataType: DataNone,
		LNode:    pLNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// PartitionByType is an enum of each type of partitioning (LIST/RANGE).
type PartitionByType string

const (
	// PartitionByList indicates a PARTITION BY LIST clause.
	PartitionByList PartitionByType = "LIST"
	// PartitionByRange indicates a PARTITION BY LIST clause.
	PartitionByRange PartitionByType = "RANGE"
)

// PartitionByIndex represents a PARTITION BY definition within
// a CREATE/ALTER INDEX statement.
type PartitionByIndex struct {
	*PartitionBy
}

// ContainsPartitions determines if the partition by table contains
// a partition clause which is not PARTITION BY NOTHING.
func (node *PartitionByIndex) ContainsPartitions() bool {
	return node != nil && node.PartitionBy != nil
}

// ContainsPartitioningClause determines if the partition by table contains
// a partitioning clause, including PARTITION BY NOTHING.
func (node *PartitionByIndex) ContainsPartitioningClause() bool {
	return node != nil
}

// PartitionByTable represents a PARTITION [ALL] BY definition within
// a CREATE/ALTER TABLE statement.
type PartitionByTable struct {
	// All denotes PARTITION ALL BY.
	All bool

	*PartitionBy
}

// Format implements the NodeFormatter interface.
func (node *PartitionByTable) Format(ctx *FmtCtx) {
	if node == nil {
		ctx.WriteString(` PARTITION BY NOTHING`)
		return
	}
	ctx.WriteString(` PARTITION `)
	if node.All {
		ctx.WriteString(`ALL `)
	}
	ctx.WriteString(`BY `)
	node.PartitionBy.formatListOrRange(ctx)
}

// SQLRight Code Injection.
func (node *PartitionByTable) LogCurrentNode(depth int) *SQLRightIR {

	var rootIR *SQLRightIR
	if node == nil {
		prefix := " PARTITION BY NOTHING"
		rootIR = &SQLRightIR{
			IRType:   TypePartitionByTable,
			DataType: DataNone,
			//LNode:    LNode,
			//RNode:    RNode,
			Prefix: prefix,
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
	} else {
		prefix := " PARTITION "
		if node.All {
			prefix += "ALL "
		}
		prefix += "BY "
		pLNode := node.PartitionBy.LogCurrentNodeListOrRange(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypePartitionByTable,
			DataType: DataNone,
			LNode:    pLNode,
			//RNode:    RNode,
			Prefix: prefix,
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
	}

	return rootIR
}

// ContainsPartitions determines if the partition by table contains
// a partition clause which is not PARTITION BY NOTHING.
func (node *PartitionByTable) ContainsPartitions() bool {
	return node != nil && node.PartitionBy != nil
}

// ContainsPartitioningClause determines if the partition by table contains
// a partitioning clause, including PARTITION BY NOTHING.
func (node *PartitionByTable) ContainsPartitioningClause() bool {
	return node != nil
}

// PartitionBy represents an PARTITION BY definition within a CREATE/ALTER
// TABLE/INDEX statement or within a subpartition statement.
// This is wrapped by top level PartitionByTable/PartitionByIndex
// structs for table and index definitions respectively.
type PartitionBy struct {
	Fields NameList
	// Exactly one of List or Range is required to be non-empty.
	List  []ListPartition
	Range []RangePartition
}

// Format implements the NodeFormatter interface.
func (node *PartitionBy) Format(ctx *FmtCtx) {
	ctx.WriteString(` PARTITION BY `)
	node.formatListOrRange(ctx)
}

// SQLRight Code Injection.
func (node *PartitionBy) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.LogCurrentNodeListOrRange(depth + 1)
	rootIR := &SQLRightIR{
		IRType:   TypePartitionBy,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: " PARTITION BY ",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

func (node *PartitionBy) formatListOrRange(ctx *FmtCtx) {
	if node == nil {
		ctx.WriteString(`NOTHING`)
		return
	}
	if len(node.List) > 0 {
		ctx.WriteString(`LIST (`)
	} else if len(node.Range) > 0 {
		ctx.WriteString(`RANGE (`)
	}
	ctx.FormatNode(&node.Fields)
	ctx.WriteString(`) (`)
	for i := range node.List {
		if i > 0 {
			ctx.WriteString(", ")
		}
		ctx.FormatNode(&node.List[i])
	}
	for i := range node.Range {
		if i > 0 {
			ctx.WriteString(", ")
		}
		ctx.FormatNode(&node.Range[i])
	}
	ctx.WriteString(`)`)
}

// SQLRight Code Injection.
func (node *PartitionBy) LogCurrentNodeListOrRange(depth int) *SQLRightIR {

	if node == nil {
		rootIR := &SQLRightIR{
			IRType:   TypeUnknown, // This is not the root node from PartitionBy
			DataType: DataNone,
			//LNode:    LNode,
			//RNode:    RNode,
			Prefix: " NOTHING ",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		return rootIR
	}

	prefix := ""

	if len(node.List) > 0 {
		prefix = `LIST (`
	} else if len(node.Range) > 0 {
		prefix = `RANGE (`
	}

	pLNode := node.Fields.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    pLNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: " ",
		Depth:  depth,
	}
	//LNode := rootIR

	for i := range node.List {
		prefix = ""
		infix := " "
		if i == 0 {
			infix = " ) ("
		}
		if i > 0 {
			infix = ", "
		}
		pRNode := node.List[i].LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR, // previous root
			RNode:    pRNode, // current list
			Prefix:   prefix,
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
		//LNode = rootIR
	}

	for i := range node.Range {
		prefix = ""
		infix := " "
		if i > 0 {
			infix = ", "
		} else if i == 0 {
			infix = " ) ("
		}
		pRNode := node.Range[i].LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR, // previous root
			RNode:    pRNode, // current list
			Prefix:   prefix,
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
		//LNode = rootIR
	}

	rootIR.Suffix = ")"
	rootIR.IRType = TypePartitionBy

	return rootIR
}

// ListPartition represents a PARTITION definition within a PARTITION BY LIST.
type ListPartition struct {
	Name         UnrestrictedName
	Exprs        Exprs
	Subpartition *PartitionBy
}

// Format implements the NodeFormatter interface.
func (node *ListPartition) Format(ctx *FmtCtx) {
	ctx.WriteString(`PARTITION `)
	ctx.FormatNode(&node.Name)
	ctx.WriteString(` VALUES IN (`)
	ctx.FormatNode(&node.Exprs)
	ctx.WriteByte(')')
	if node.Subpartition != nil {
		ctx.FormatNode(node.Subpartition)
	}
}

// SQLRight Code Injection.
func (node *ListPartition) LogCurrentNode(depth int) *SQLRightIR {

	nameStr := node.Name.String()
	LNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataPartitionName,
		ContextFlag: ContextDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         nameStr,
	}
	pRNode := node.Exprs.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    pRNode,
		Prefix:   "PARTITION ",
		Infix:    " VALUES IN (",
		Suffix:   ")",
		Depth:    depth,
	}

	if node.Subpartition != nil {
		pRNode = node.Subpartition.LogCurrentNodeListOrRange(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    pRNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeListPartition

	return rootIR
}

// RangePartition represents a PARTITION definition within a PARTITION BY RANGE.
type RangePartition struct {
	Name         UnrestrictedName
	From         Exprs
	To           Exprs
	Subpartition *PartitionBy
}

// Format implements the NodeFormatter interface.
func (node *RangePartition) Format(ctx *FmtCtx) {
	ctx.WriteString(`PARTITION `)
	ctx.FormatNode(&node.Name)
	ctx.WriteString(` VALUES FROM (`)
	ctx.FormatNode(&node.From)
	ctx.WriteString(`) TO (`)
	ctx.FormatNode(&node.To)
	ctx.WriteByte(')')
	if node.Subpartition != nil {
		ctx.FormatNode(node.Subpartition)
	}
}

// SQLRight Code Injection.
func (node *RangePartition) LogCurrentNode(depth int) *SQLRightIR {

	rangeNameStr := node.Name.String()
	LNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataRangeName,
		ContextFlag: ContextDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         rangeNameStr,
	}

	pRNode := node.From.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    pRNode,
		Prefix:   "PARTITION ",
		Infix:    " VALUES FROM (",
		Suffix:   "",
		Depth:    depth,
	}

	pRNode = node.To.LogCurrentNode(depth + 1)
	rootIR = &SQLRightIR{
		IRType:   TypeRangePartition,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    pRNode,
		Prefix:   "",
		Infix:    ") TO (",
		Suffix:   ")",
		Depth:    depth,
	}

	return rootIR
}

// StorageParam is a key-value parameter for table storage.
type StorageParam struct {
	Key   Name
	Value Expr
}

// StorageParams is a list of StorageParams.
type StorageParams []StorageParam

// Format implements the NodeFormatter interface.
func (o *StorageParams) Format(ctx *FmtCtx) {
	for i := range *o {
		n := &(*o)[i]
		if i > 0 {
			ctx.WriteString(", ")
		}
		// TODO(knz): the key may need to be formatted differently
		// if we want to de-anonymize it.
		ctx.FormatNode(&n.Key)
		if n.Value != nil {
			ctx.WriteString(` = `)
			ctx.FormatNode(n.Value)
		}
	}
}

// SQLRight Code Injection.
func (node *StorageParams) LogCurrentNode(depth int) *SQLRightIR {

	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	var irList []*SQLRightIR
	tmpIR := &SQLRightIR{}
	for _, n := range *node {

		prefix := ""
		LNode := &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataNone, //TODO: FIXME: Unknown datatype here.
			ContextFlag: ContextUnknown,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth + 1,
			Str:         n.Key.String(),
		}
		pRNode := n.Value.LogCurrentNode(depth + 1)
		infix := " = "

		tmpIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    LNode,
			RNode:    pRNode,
			Prefix:   prefix,
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}

		irList = append(irList, tmpIR)
	}

	var rootIR *SQLRightIR
	for idx, curTmpIR := range irList {

		if idx == 0 {
			// Take care of the first two nodes.
			LNode := curTmpIR
			var RNode *SQLRightIR
			if len(*node) >= 2 {
				RNode = irList[1]
			}
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   "",
				Infix:    " ",
				Suffix:   "",
				Depth:    depth,
			}
		} else if idx == 1 {
			// The first two element would be saved in the same IR node.
			continue
		} else {
			// i >= 2. Begins from the third element.
			// Left node is the previous cmds.
			// Right node is the new cmd.
			RNode := curTmpIR

			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    RNode,
				Prefix:   "",
				Infix:    " ",
				Suffix:   "",
				Depth:    depth,
			}
		}
	}

	// Only flag the root node for the type.
	rootIR.IRType = TypeStorageParams
	return tmpIR
}

// GetVal returns corresponding value if a key exists, otherwise nil is
// returned.
func (o *StorageParams) GetVal(key string) Expr {
	k := Name(key)
	for _, param := range *o {
		if param.Key == k {
			return param.Value
		}
	}
	return nil
}

// CreateTableOnCommitSetting represents the CREATE TABLE ... ON COMMIT <action>
// parameters.
type CreateTableOnCommitSetting uint32

const (
	// CreateTableOnCommitUnset indicates that ON COMMIT was unset.
	CreateTableOnCommitUnset CreateTableOnCommitSetting = iota
	// CreateTableOnCommitPreserveRows indicates that ON COMMIT PRESERVE ROWS was set.
	CreateTableOnCommitPreserveRows
)

// CreateTable represents a CREATE TABLE statement.
type CreateTable struct {
	IfNotExists      bool
	Table            TableName
	PartitionByTable *PartitionByTable
	Persistence      Persistence
	StorageParams    StorageParams
	OnCommit         CreateTableOnCommitSetting
	// In CREATE...AS queries, Defs represents a list of ColumnTableDefs, one for
	// each column, and a ConstraintTableDef for each constraint on a subset of
	// these columns.
	Defs     TableDefs
	AsSource *Select
	Locality *Locality
}

// As returns true if this table represents a CREATE TABLE ... AS statement,
// false otherwise.
func (node *CreateTable) As() bool {
	return node.AsSource != nil
}

// AsHasUserSpecifiedPrimaryKey returns true if a CREATE TABLE ... AS statement
// has a PRIMARY KEY constraint specified.
func (node *CreateTable) AsHasUserSpecifiedPrimaryKey() bool {
	if node.As() {
		for _, def := range node.Defs {
			if d, ok := def.(*ColumnTableDef); !ok {
				return false
			} else if d.PrimaryKey.IsPrimaryKey {
				return true
			}
		}
	}
	return false
}

// Format implements the NodeFormatter interface.
func (node *CreateTable) Format(ctx *FmtCtx) {
	ctx.WriteString("CREATE ")
	switch node.Persistence {
	case PersistenceTemporary:
		ctx.WriteString("TEMPORARY ")
	case PersistenceUnlogged:
		ctx.WriteString("UNLOGGED ")
	}
	ctx.WriteString("TABLE ")
	if node.IfNotExists {
		ctx.WriteString("IF NOT EXISTS ")
	}
	ctx.FormatNode(&node.Table)
	node.FormatBody(ctx)
}

// SQLRight Code Injection.
func (node *CreateTable) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "CREATE "
	switch node.Persistence {
	case PersistenceTemporary:
		prefix += "TEMPORARY "
	case PersistenceUnlogged:
		prefix += "UNLOGGED "
	}
	prefix += "TABLE "

	existStr := ""
	if node.IfNotExists {
		existStr = "IF NOT EXISTS "
	}
	existNode := &SQLRightIR{
		IRType:   TypeOptIfNotExists,
		DataType: DataNone,
		//LNode:    ,
		//RNode:    RNode,
		Prefix: existStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	pTableNode := node.Table.LogCurrentNodeWithType(depth+1, DataTableName, ContextDefine)

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    existNode,
		RNode:    pTableNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	pBodyNode := node.LogCurrentNodeBody(depth + 1)

	rootIR = &SQLRightIR{
		IRType:   TypeCreateTable,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    pBodyNode,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// FormatBody formats the "body" of the create table definition - everything
// but the CREATE TABLE tableName part.
func (node *CreateTable) FormatBody(ctx *FmtCtx) {
	if node.As() {
		if len(node.Defs) > 0 {
			ctx.WriteString(" (")
			ctx.FormatNode(&node.Defs)
			ctx.WriteByte(')')
		}
		ctx.WriteString(" AS ")
		ctx.FormatNode(node.AsSource)
	} else {
		ctx.WriteString(" (")
		ctx.FormatNode(&node.Defs)
		ctx.WriteByte(')')
		if node.PartitionByTable != nil {
			ctx.FormatNode(node.PartitionByTable)
		}
		if node.StorageParams != nil {
			ctx.WriteString(` WITH (`)
			ctx.FormatNode(&node.StorageParams)
			ctx.WriteByte(')')
		}
		if node.Locality != nil {
			ctx.WriteString(" ")
			ctx.FormatNode(node.Locality)
		}
	}
}

// SQLRight Code Injection.
func (node *CreateTable) LogCurrentNodeBody(depth int) *SQLRightIR {

	var rootIR *SQLRightIR

	if node.As() {
		var nodeDefNode *SQLRightIR
		if len(node.Defs) > 0 {
			pNodeDefNode := node.Defs.LogCurrentNode(depth + 1)
			nodeDefNode = &SQLRightIR{
				IRType:   TypeOptTableDefs,
				DataType: DataNone,
				LNode:    pNodeDefNode,
				//RNode:    RNode,
				Prefix: " (",
				Infix:  ")",
				Suffix: "",
				Depth:  depth,
			}
		}
		pAsSourceNode := node.AsSource.LogCurrentNode(depth + 1) // This is a SELECT

		rootIR = &SQLRightIR{
			IRType:   TypeCreateTableAs,
			DataType: DataNone,
			LNode:    nodeDefNode,
			RNode:    pAsSourceNode,
			Prefix:   "",
			Infix:    " AS ",
			Suffix:   "",
			Depth:    depth,
		}
	} else {
		pNodeDefNode := node.Defs.LogCurrentNode(depth + 1)
		nodeDefNode := &SQLRightIR{
			IRType:   TypeOptTableDefs,
			DataType: DataNone,
			LNode:    pNodeDefNode,
			//RNode:    RNode,
			Prefix: " (",
			Infix:  ")",
			Suffix: "",
			Depth:  depth,
		}

		var pPartitionNode *SQLRightIR
		if node.PartitionByTable != nil {
			pPartitionNode = node.PartitionByTable.LogCurrentNode(depth + 1)
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    nodeDefNode,
			RNode:    pPartitionNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		if node.StorageParams != nil {
			pStorageParamsNode := node.StorageParams.LogCurrentNode(depth + 1)
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    pStorageParamsNode,
				Prefix:   "",
				Infix:    " WITH (",
				Suffix:   ")",
				Depth:    depth,
			}
		}
		if node.Locality != nil {
			pLocality := node.Locality.LogCurrentNode(depth + 1)
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    pLocality,
				Prefix:   "",
				Infix:    " ",
				Suffix:   "",
				Depth:    depth,
			}
		}
	}

	// Do not set type, because this is not the root node.

	return rootIR
}

// HoistConstraints finds column check and foreign key constraints defined
// inline with their columns and makes them table-level constraints, stored in
// n.Defs. For example, the foreign key constraint in
//
//	CREATE TABLE foo (a INT REFERENCES bar(a))
//
// gets pulled into a top-level constraint like:
//
//	CREATE TABLE foo (a INT, FOREIGN KEY (a) REFERENCES bar(a))
//
// Similarly, the CHECK constraint in
//
//	CREATE TABLE foo (a INT CHECK (a < 1), b INT)
//
// gets pulled into a top-level constraint like:
//
//	CREATE TABLE foo (a INT, b INT, CHECK (a < 1))
//
// Note that some SQL databases require that a constraint attached to a column
// to refer only to the column it is attached to. We follow Postgres' behavior,
// however, in omitting this restriction by blindly hoisting all column
// constraints. For example, the following table definition is accepted in
// CockroachDB and Postgres, but not necessarily other SQL databases:
//
//	CREATE TABLE foo (a INT CHECK (a < b), b INT)
//
// Unique constraints are not hoisted.
func (node *CreateTable) HoistConstraints() {
	for _, d := range node.Defs {
		if col, ok := d.(*ColumnTableDef); ok {
			for _, checkExpr := range col.CheckExprs {
				node.Defs = append(node.Defs,
					&CheckConstraintTableDef{
						Expr: checkExpr.Expr,
						Name: checkExpr.ConstraintName,
					},
				)
			}
			col.CheckExprs = nil
			if col.HasFKConstraint() {
				var targetCol NameList
				if col.References.Col != "" {
					targetCol = append(targetCol, col.References.Col)
				}
				node.Defs = append(node.Defs, &ForeignKeyConstraintTableDef{
					Table:    *col.References.Table,
					FromCols: NameList{col.Name},
					ToCols:   targetCol,
					Name:     col.References.ConstraintName,
					Actions:  col.References.Actions,
					Match:    col.References.Match,
				})
				col.References.Table = nil
			}
		}
	}
}

// CreateSchema represents a CREATE SCHEMA statement.
type CreateSchema struct {
	IfNotExists bool
	AuthRole    RoleSpec
	Schema      ObjectNamePrefix
}

// Format implements the NodeFormatter interface.
func (node *CreateSchema) Format(ctx *FmtCtx) {
	ctx.WriteString("CREATE SCHEMA")

	if node.IfNotExists {
		ctx.WriteString(" IF NOT EXISTS")
	}

	if node.Schema.ExplicitSchema {
		ctx.WriteString(" ")
		ctx.FormatNode(&node.Schema)
	}

	if !node.AuthRole.Undefined() {
		ctx.WriteString(" AUTHORIZATION ")
		ctx.FormatNode(&node.AuthRole)
	}
}

// SQLRight Code Injection.
func (node *CreateSchema) LogCurrentNode(depth int) *SQLRightIR {

	optIfNotExistStr := ""
	if node.IfNotExists {
		optIfNotExistStr = "IF NOT EXISTS "
	}
	ifNotExistsNode := &SQLRightIR{
		IRType:   TypeOptIfNotExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfNotExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	infix := ""
	var pSchemaNode *SQLRightIR
	if node.Schema.ExplicitSchema {
		infix = " "
		pSchemaNode = node.Schema.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    ifNotExistsNode,
		RNode:    pSchemaNode,
		Prefix:   "CREATE SCHEMA ",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	if !node.AuthRole.Undefined() {
		infix = " AUTHORIZATION "
		pAuthNode := node.AuthRole.LogCurrentNode(depth+1, ContextUse)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    pAuthNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeCreateSchema

	return rootIR
}

// CreateSequence represents a CREATE SEQUENCE statement.
type CreateSequence struct {
	IfNotExists bool
	Name        TableName
	Persistence Persistence
	Options     SequenceOptions
}

// Format implements the NodeFormatter interface.
func (node *CreateSequence) Format(ctx *FmtCtx) {
	ctx.WriteString("CREATE ")

	if node.Persistence == PersistenceTemporary {
		ctx.WriteString("TEMPORARY ")
	}

	ctx.WriteString("SEQUENCE ")

	if node.IfNotExists {
		ctx.WriteString("IF NOT EXISTS ")
	}
	ctx.FormatNode(&node.Name)
	ctx.FormatNode(&node.Options)
}

// SQLRight Code Injection.
func (node *CreateSequence) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "CREATE "
	if node.Persistence == PersistenceTemporary {
		prefix += "TEMPORARY "
	}
	prefix += "SEQUENCE "

	existStr := ""
	if node.IfNotExists {
		existStr = "IF NOT EXISTS "
	}
	existNode := &SQLRightIR{
		IRType:   TypeOptIfNotExists,
		DataType: DataNone,
		//LNode:    ,
		//RNode:    RNode,
		Prefix: existStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	pTableNode := node.Name.LogCurrentNode(depth + 1) // Change the type to sequence name?

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    existNode,
		RNode:    pTableNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	pOptionNode := node.Options.LogCurrentNode(depth + 1)
	rootIR = &SQLRightIR{
		IRType:   TypeCreateSequence,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    pOptionNode,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// SequenceOptions represents a list of sequence options.
type SequenceOptions []SequenceOption

// Format implements the NodeFormatter interface.
func (node *SequenceOptions) Format(ctx *FmtCtx) {
	for i := range *node {
		option := &(*node)[i]
		ctx.WriteByte(' ')
		switch option.Name {
		case SeqOptAs:
			ctx.WriteString(option.Name)
			ctx.WriteByte(' ')
			ctx.WriteString(option.AsIntegerType.SQLString())
		case SeqOptCycle, SeqOptNoCycle:
			ctx.WriteString(option.Name)
		case SeqOptCache:
			ctx.WriteString(option.Name)
			ctx.WriteByte(' ')
			// TODO(knz): replace all this with ctx.FormatNode if/when
			// the cache option supports expressions.
			if ctx.flags.HasFlags(FmtHideConstants) {
				ctx.WriteByte('0')
			} else {
				ctx.Printf("%d", *option.IntVal)
			}
		case SeqOptMaxValue, SeqOptMinValue:
			if option.IntVal == nil {
				ctx.WriteString("NO ")
				ctx.WriteString(option.Name)
			} else {
				ctx.WriteString(option.Name)
				ctx.WriteByte(' ')
				// TODO(knz): replace all this with ctx.FormatNode if/when
				// the min/max value options support expressions.
				if ctx.flags.HasFlags(FmtHideConstants) {
					ctx.WriteByte('0')
				} else {
					ctx.Printf("%d", *option.IntVal)
				}
			}
		case SeqOptStart:
			ctx.WriteString(option.Name)
			ctx.WriteByte(' ')
			if option.OptionalWord {
				ctx.WriteString("WITH ")
			}
			// TODO(knz): replace all this with ctx.FormatNode if/when
			// the start option supports expressions.
			if ctx.flags.HasFlags(FmtHideConstants) {
				ctx.WriteByte('0')
			} else {
				ctx.Printf("%d", *option.IntVal)
			}
		case SeqOptRestart:
			ctx.WriteString(option.Name)
			if option.IntVal != nil {
				ctx.WriteByte(' ')
				if option.OptionalWord {
					ctx.WriteString("WITH ")
				}
				if ctx.flags.HasFlags(FmtHideConstants) {
					ctx.WriteByte('0')
				} else {
					ctx.Printf("%d", *option.IntVal)
				}
			}
		case SeqOptIncrement:
			ctx.WriteString(option.Name)
			ctx.WriteByte(' ')
			if option.OptionalWord {
				ctx.WriteString("BY ")
			}
			// TODO(knz): replace all this with ctx.FormatNode if/when
			// the increment option supports expressions.
			if ctx.flags.HasFlags(FmtHideConstants) {
				ctx.WriteByte('0')
			} else {
				ctx.Printf("%d", *option.IntVal)
			}
		case SeqOptVirtual:
			ctx.WriteString(option.Name)
		case SeqOptOwnedBy:
			ctx.WriteString(option.Name)
			ctx.WriteByte(' ')
			switch option.ColumnItemVal {
			case nil:
				ctx.WriteString("NONE")
			default:
				ctx.FormatNode(option.ColumnItemVal)
			}
		default:
			panic(errors.AssertionFailedf("unexpected SequenceOption: %v", option))
		}
	}
}

// SQLRight Code Injection.
func (node *SequenceOptions) LogCurrentNode(depth int) *SQLRightIR {

	var optionNodeList []*SQLRightIR
	for i := range *node {
		option := &(*node)[i]
		switch option.Name {
		case SeqOptAs:
			idenNode := &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataNone,
				ContextFlag: ContextUnknown,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         option.Name,
			}

			optionNode := &SQLRightIR{
				IRType:   TypeStringLiteral, // TODO:: FIXME:: Doesn't seem to be stringliteral.
				DataType: DataLiteral,
				//LNode:    ,
				//RNode:    RNode,
				Prefix: "",
				Infix:  "",
				Suffix: "",
				Depth:  depth,
				Str:    "'" + option.AsIntegerType.SQLString() + "'",
			}

			optionNode = &SQLRightIR{
				IRType:   TypeSequenceOption,
				DataType: DataNone,
				LNode:    idenNode,
				RNode:    optionNode,
				Prefix:   "",
				Infix:    " ",
				Suffix:   "",
				Depth:    depth,
			}

			optionNodeList = append(optionNodeList, optionNode)

		case SeqOptCycle, SeqOptNoCycle:
			idenNode := &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataNone,
				ContextFlag: ContextUnknown,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         option.Name,
			}

			optionNode := &SQLRightIR{
				IRType:   TypeSequenceOption,
				DataType: DataNone,
				LNode:    idenNode,
				//RNode:  optionNode,
				Prefix: "",
				Infix:  " ",
				Suffix: "",
				Depth:  depth,
			}

			optionNodeList = append(optionNodeList, optionNode)
		case SeqOptCache:
			idenNode := &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataNone,
				ContextFlag: ContextUnknown,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         option.Name,
			}

			intLiteral := &SQLRightIR{
				IRType:       TypeIntegerLiteral,
				DataType:     DataLiteral,
				DataAffinity: AFFIINT,
				Prefix:       "",
				Infix:        "",
				Suffix:       "",
				Depth:        depth,
				IValue:       *option.IntVal,
			}

			optionNode := &SQLRightIR{
				IRType:   TypeSequenceOption,
				DataType: DataNone,
				LNode:    idenNode,
				RNode:    intLiteral,
				Prefix:   "",
				Infix:    "",
				Suffix:   "",
				Depth:    depth,
			}

			optionNodeList = append(optionNodeList, optionNode)

		case SeqOptMaxValue, SeqOptMinValue:
			prefix := ""
			var idenNode *SQLRightIR
			if option.IntVal == nil {
				prefix = "NO "
				idenNode = &SQLRightIR{
					IRType:      TypeIdentifier,
					DataType:    DataNone,
					ContextFlag: ContextUnknown,
					Prefix:      "",
					Infix:       "",
					Suffix:      "",
					Depth:       depth,
					Str:         option.Name,
				}
				optionNode := &SQLRightIR{
					IRType:   TypeSequenceOption,
					DataType: DataNone,
					LNode:    idenNode,
					//RNode:
					Prefix: prefix,
					Infix:  "",
					Suffix: "",
					Depth:  depth,
				}
				optionNodeList = append(optionNodeList, optionNode)
			} else {
				idenNode = &SQLRightIR{
					IRType:      TypeIdentifier,
					DataType:    DataNone,
					ContextFlag: ContextUnknown,
					Prefix:      "",
					Infix:       "",
					Suffix:      "",
					Depth:       depth,
					Str:         option.Name,
				}
				intLiteral := &SQLRightIR{
					IRType:       TypeIntegerLiteral,
					DataType:     DataLiteral,
					DataAffinity: AFFIINT,
					Prefix:       "",
					Infix:        "",
					Suffix:       "",
					Depth:        depth,
					IValue:       *option.IntVal,
				}
				optionNode := &SQLRightIR{
					IRType:   TypeSequenceOption,
					DataType: DataNone,
					LNode:    idenNode,
					RNode:    intLiteral,
					Prefix:   prefix,
					Infix:    " ",
					Suffix:   "",
					Depth:    depth,
				}
				optionNodeList = append(optionNodeList, optionNode)
			}
		case SeqOptStart:
			idenNode := &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataNone,
				ContextFlag: ContextUnknown,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         option.Name,
			}
			infix := " "
			if option.OptionalWord {
				infix += "WITH "
			}

			intLiteral := &SQLRightIR{
				IRType:       TypeIntegerLiteral,
				DataType:     DataLiteral,
				DataAffinity: AFFIINT,
				Prefix:       "",
				Infix:        "",
				Suffix:       "",
				Depth:        depth,
				IValue:       *option.IntVal,
			}

			optionNode := &SQLRightIR{
				IRType:   TypeSequenceOption,
				DataType: DataNone,
				LNode:    idenNode,
				RNode:    intLiteral,
				Prefix:   "",
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}

			optionNodeList = append(optionNodeList, optionNode)

		case SeqOptRestart:

			idenNode := &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataNone,
				ContextFlag: ContextUnknown,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         option.Name,
			}

			var pIntLiteral *SQLRightIR
			infix := ""
			if option.IntVal != nil {
				infix = " "
				if option.OptionalWord {
					infix += "WITH "
				}
				intLiteral := &SQLRightIR{
					IRType:       TypeIntegerLiteral,
					DataType:     DataLiteral,
					DataAffinity: AFFIINT,
					Prefix:       "",
					Infix:        "",
					Suffix:       "",
					Depth:        depth,
					IValue:       *option.IntVal,
				}
				pIntLiteral = intLiteral
			}

			optionNode := &SQLRightIR{
				IRType:   TypeSequenceOption,
				DataType: DataNone,
				LNode:    idenNode,
				RNode:    pIntLiteral,
				Prefix:   "",
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}

			optionNodeList = append(optionNodeList, optionNode)

		case SeqOptIncrement:

			idenNode := &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataNone,
				ContextFlag: ContextUnknown,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         option.Name,
			}

			infix := " "

			if option.OptionalWord {
				infix += "BY "
			}

			intLiteral := &SQLRightIR{
				IRType:       TypeIntegerLiteral,
				DataType:     DataLiteral,
				DataAffinity: AFFIINT,
				Prefix:       "",
				Infix:        "",
				Suffix:       "",
				Depth:        depth,
				IValue:       *option.IntVal,
			}
			pIntLiteral := intLiteral

			optionNode := &SQLRightIR{
				IRType:   TypeSequenceOption,
				DataType: DataNone,
				LNode:    idenNode,
				RNode:    pIntLiteral,
				Prefix:   "",
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}

			optionNodeList = append(optionNodeList, optionNode)
		case SeqOptVirtual:
			idenNode := &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataNone,
				ContextFlag: ContextUnknown,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         option.Name,
			}

			optionNode := &SQLRightIR{
				IRType:   TypeSequenceOption,
				DataType: DataNone,
				LNode:    idenNode,
				//RNode:    pIntLiteral,
				Prefix: "",
				Infix:  "",
				Suffix: "",
				Depth:  depth,
			}

			optionNodeList = append(optionNodeList, optionNode)
		case SeqOptOwnedBy:
			idenNode := &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataNone,
				ContextFlag: ContextUnknown,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         option.Name,
			}

			infix := " "

			var pColumnItemVal *SQLRightIR
			switch option.ColumnItemVal {
			case nil:
				columnItemVal := &SQLRightIR{
					IRType:   TypeColumnItemVal,
					DataType: DataNone,
					//LNode:    ,
					//RNode:    RNode,
					Prefix: "NONE",
					Infix:  "",
					Suffix: "",
					Depth:  depth,
				}
				pColumnItemVal = columnItemVal
			default:
				pColumnItemVal = option.ColumnItemVal.LogCurrentNode(depth + 1)
			}

			optionNode := &SQLRightIR{
				IRType:   TypeSequenceOption,
				DataType: DataNone,
				LNode:    idenNode,
				RNode:    pColumnItemVal,
				Prefix:   "",
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}

			optionNodeList = append(optionNodeList, optionNode)

		default:
			panic(errors.AssertionFailedf("unexpected SequenceOption: %v", option))
		}
	}

	// Reconstruct the list
	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{}
	for i, n := range optionNodeList {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := (optionNodeList[0])
			var RNode *SQLRightIR
			if len(*node) >= 2 {
				RNode = (optionNodeList[1])
			}
			tmpIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   "",
				Infix:    " ",
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
			RNode := (n)

			tmpIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   "",
				Infix:    " ",
				Suffix:   "",
				Depth:    depth,
			}
		}
	}

	// Only flag the root node for the type.
	tmpIR.IRType = TypeAlterChangefeedCmds
	return tmpIR
}

// SequenceOption represents an option on a CREATE SEQUENCE statement.
type SequenceOption struct {
	Name string

	// AsIntegerType specifies default min and max values of a sequence.
	AsIntegerType *types.T

	IntVal *int64

	OptionalWord bool

	ColumnItemVal *ColumnItem
}

// Names of options on CREATE SEQUENCE.
const (
	SeqOptAs        = "AS"
	SeqOptCycle     = "CYCLE"
	SeqOptNoCycle   = "NO CYCLE"
	SeqOptOwnedBy   = "OWNED BY"
	SeqOptCache     = "CACHE"
	SeqOptIncrement = "INCREMENT"
	SeqOptMinValue  = "MINVALUE"
	SeqOptMaxValue  = "MAXVALUE"
	SeqOptStart     = "START"
	SeqOptRestart   = "RESTART"
	SeqOptVirtual   = "VIRTUAL"

	// Avoid unused warning for constants.
	_ = SeqOptAs
)

// LikeTableDef represents a LIKE table declaration on a CREATE TABLE statement.
type LikeTableDef struct {
	Name    TableName
	Options []LikeTableOption
}

// LikeTableOption represents an individual INCLUDING / EXCLUDING statement
// on a LIKE table declaration.
type LikeTableOption struct {
	Excluded bool
	Opt      LikeTableOpt
}

// Format implements the NodeFormatter interface.
func (def *LikeTableDef) Format(ctx *FmtCtx) {
	ctx.WriteString("LIKE ")
	ctx.FormatNode(&def.Name)
	for _, o := range def.Options {
		ctx.WriteString(" ")
		ctx.FormatNode(o)
	}
}

// SQLRight Code Injection.
func (node *LikeTableDef) LogCurrentNode(depth int) *SQLRightIR {

	pTableNameNode := node.Name.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    pTableNameNode,
		//RNode:    RNode,
		Prefix: "LIKE ",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	for _, o := range node.Options {
		RNode := o.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeLikeTableDef

	return rootIR
}

// Format implements the NodeFormatter interface.
func (l LikeTableOption) Format(ctx *FmtCtx) {
	if l.Excluded {
		ctx.WriteString("EXCLUDING ")
	} else {
		ctx.WriteString("INCLUDING ")
	}
	ctx.WriteString(l.Opt.String())
}

// SQLRight Code Injection.
func (node *LikeTableOption) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""
	if node.Excluded {
		prefix += "EXCLUDING "
	} else {
		prefix += "INCLUDING "
	}

	prefix += node.Opt.String()

	rootIR := &SQLRightIR{
		IRType:   TypeLikeTableOption,
		DataType: DataNone,
		//LNode:    TypeLikeTableOption,
		//RNode:    RNode,
		Prefix: "",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// LikeTableOpt represents one of the types of things that can be included or
// excluded in a LIKE table declaration. It's a bitmap, where each of the Opt
// values is a single enabled bit in the map.
type LikeTableOpt int

// The values for LikeTableOpt.
const (
	LikeTableOptConstraints LikeTableOpt = 1 << iota
	LikeTableOptDefaults
	LikeTableOptGenerated
	LikeTableOptIndexes

	// Make sure this field stays last!
	likeTableOptInvalid
)

// LikeTableOptAll is the full LikeTableOpt bitmap.
const LikeTableOptAll = ^likeTableOptInvalid

// Has returns true if the receiver has the other options bits set.
func (o LikeTableOpt) Has(other LikeTableOpt) bool {
	return int(o)&int(other) != 0
}

func (o LikeTableOpt) String() string {
	switch o {
	case LikeTableOptConstraints:
		return "CONSTRAINTS"
	case LikeTableOptDefaults:
		return "DEFAULTS"
	case LikeTableOptGenerated:
		return "GENERATED"
	case LikeTableOptIndexes:
		return "INDEXES"
	case LikeTableOptAll:
		return "ALL"
	default:
		panic("unknown like table opt" + strconv.Itoa(int(o)))
	}
}

// ToRoleOptions converts KVOptions to a roleoption.List using
// typeAsString to convert exprs to strings.
func (o KVOptions) ToRoleOptions(
	typeAsStringOrNull func(e Expr, op string) (func() (bool, string, error), error), op string,
) (roleoption.List, error) {
	roleOptions := make(roleoption.List, len(o))

	for i, ro := range o {
		// Role options are always stored as keywords in ro.Key by the
		// parser.
		option, err := roleoption.ToOption(string(ro.Key))
		if err != nil {
			return nil, err
		}

		if ro.Value != nil {
			if ro.Value == DNull {
				roleOptions[i] = roleoption.RoleOption{
					Option: option, HasValue: true, Value: func() (bool, string, error) {
						return true, "", nil
					},
				}
			} else {
				strFn, err := typeAsStringOrNull(ro.Value, op)
				if err != nil {
					return nil, err
				}
				roleOptions[i] = roleoption.RoleOption{
					Option: option, Value: strFn, HasValue: true,
				}
			}
		} else {
			roleOptions[i] = roleoption.RoleOption{
				Option: option, HasValue: false,
			}
		}
	}

	return roleOptions, nil
}

func (o *KVOptions) formatAsRoleOptions(ctx *FmtCtx) {
	for _, option := range *o {
		ctx.WriteByte(' ')
		// Role option keys are always sequences of keywords separated
		// by spaces.
		ctx.WriteString(strings.ToUpper(string(option.Key)))

		// Password is a special case.
		if strings.HasSuffix(string(option.Key), "password") {
			ctx.WriteByte(' ')
			if ctx.flags.HasFlags(FmtShowPasswords) {
				ctx.FormatNode(option.Value)
			} else {
				ctx.WriteString(PasswordSubstitution)
			}
		} else if option.Value != nil {
			ctx.WriteByte(' ')
			if ctx.HasFlags(FmtHideConstants) {
				ctx.WriteString("'_'")
			} else {
				ctx.FormatNode(option.Value)
			}
		}
	}
}

// SQLRight Code Injection.
func (node *KVOptions) LogCurrentNodeAsRoleOptions(depth int) *SQLRightIR {

	var KVOptionsList []*SQLRightIR
	for _, option := range *node {

		prefix := strings.ToUpper(string(option.Key)) + " "

		// Password is a special case.
		var valueNode *SQLRightIR
		if option.Value != nil {
			valueNode = option.Value.LogCurrentNode(depth + 1)
		}

		optionNode := &SQLRightIR{
			IRType:   TypeKVOption,
			DataType: DataNone,
			LNode:    valueNode,
			//RNode:    RNode,
			Prefix: prefix,
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}

		KVOptionsList = append(KVOptionsList, optionNode)
	}

	tmpIR := &SQLRightIR{}
	for i, n := range KVOptionsList {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n
			var RNode *SQLRightIR
			if len(*node) >= 2 {
				RNode = (KVOptionsList[1])
			}
			tmpIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   "",
				Infix:    " ",
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
			RNode := n

			tmpIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   "",
				Infix:    " ",
				Suffix:   "",
				Depth:    depth,
			}
		}
	}

	tmpIR.IRType = TypeKVOptions

	return tmpIR
}

// CreateRole represents a CREATE ROLE statement.
type CreateRole struct {
	Name        RoleSpec
	IfNotExists bool
	IsRole      bool
	KVOptions   KVOptions
}

// Format implements the NodeFormatter interface.
func (node *CreateRole) Format(ctx *FmtCtx) {
	ctx.WriteString("CREATE")
	if node.IsRole {
		ctx.WriteString(" ROLE ")
	} else {
		ctx.WriteString(" USER ")
	}
	if node.IfNotExists {
		ctx.WriteString("IF NOT EXISTS ")
	}
	ctx.FormatNode(&node.Name)

	if len(node.KVOptions) > 0 {
		ctx.WriteString(" WITH")
		node.KVOptions.formatAsRoleOptions(ctx)
	}
}

// SQLRight Code Injection.
func (node *CreateRole) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "CREATE"
	if node.IsRole {
		prefix += " ROLE "
	} else {
		prefix += " USER "
	}

	optIfNotExistStr := ""
	if node.IfNotExists {
		optIfNotExistStr = "IF NOT EXISTS "
	}
	ifNotExistsNode := &SQLRightIR{
		IRType:   TypeOptIfNotExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfNotExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	roleNode := node.Name.LogCurrentNode(depth+1, ContextDefine)

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    ifNotExistsNode,
		RNode:    roleNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if len(node.KVOptions) > 0 {
		infix := " WITH"
		pRoleOptNode := node.KVOptions.LogCurrentNodeAsRoleOptions(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    pRoleOptNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeCreateRole

	return rootIR
}

// CreateView represents a CREATE VIEW statement.
type CreateView struct {
	Name         TableName
	ColumnNames  NameList
	AsSource     *Select
	IfNotExists  bool
	Persistence  Persistence
	Replace      bool
	Materialized bool
	WithData     bool
}

// Format implements the NodeFormatter interface.
func (node *CreateView) Format(ctx *FmtCtx) {
	ctx.WriteString("CREATE ")

	if node.Replace {
		ctx.WriteString("OR REPLACE ")
	}

	if node.Persistence == PersistenceTemporary {
		ctx.WriteString("TEMPORARY ")
	}

	if node.Materialized {
		ctx.WriteString("MATERIALIZED ")
	}

	ctx.WriteString("VIEW ")

	if node.IfNotExists {
		ctx.WriteString("IF NOT EXISTS ")
	}
	ctx.FormatNode(&node.Name)

	if len(node.ColumnNames) > 0 {
		ctx.WriteByte(' ')
		ctx.WriteByte('(')
		ctx.FormatNode(&node.ColumnNames)
		ctx.WriteByte(')')
	}

	ctx.WriteString(" AS ")
	ctx.FormatNode(node.AsSource)
	if node.Materialized && node.WithData {
		ctx.WriteString(" WITH DATA")
	} else if node.Materialized && !node.WithData {
		ctx.WriteString(" WITH NO DATA")
	}
}

// SQLRight Code Injection.
func (node *CreateView) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "CREATE "

	optOrReplaceNode := &SQLRightIR{
		IRType:   TypeOptOrReplace,
		DataType: DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
		Str:      "",
	}
	if node.Replace {
		optOrReplaceNode.Str = "OR REPLACE "
	}

	OptTemp := &SQLRightIR{
		IRType:   TypeOptTemporary,
		DataType: DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
		Str:      "",
	}
	if node.Persistence == PersistenceTemporary {
		OptTemp.Str = "TEMPORARY "
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    optOrReplaceNode,
		RNode:    OptTemp,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	OptMater := &SQLRightIR{
		IRType:   TypeOptMaterialized,
		DataType: DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
		Str:      "",
	}
	if node.Materialized {
		OptMater.Str = "MATERIALIZED "
	}

	rootIR = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    OptMater,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	optIfNotExistStr := ""
	if node.IfNotExists {
		optIfNotExistStr = "IF NOT EXISTS "
	}
	ifNotExistsNode := &SQLRightIR{
		IRType:   TypeOptIfNotExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfNotExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	rootIR = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    ifNotExistsNode,
		Prefix:   "",
		Infix:    "VIEW ",
		Suffix:   "",
		Depth:    depth,
	}

	nameNode := node.Name.LogCurrentNodeWithType(depth+1, DataViewName, ContextDefine)
	rootIR = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    nameNode,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if len(node.ColumnNames) > 0 {
		infix := ""
		infix += " ("
		columnNamesNode := node.ColumnNames.LogCurrentNodeWithType(depth+1, DataViewColumnName)
		suffix := ")"

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    columnNamesNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   suffix,
			Depth:    depth,
		}
	}

	asSourceNode := node.AsSource.LogCurrentNode(depth + 1)

	suffix := ""
	if node.Materialized && node.WithData {
		suffix = " WITH DATA"
	} else if node.Materialized && !node.WithData {
		suffix = " WITH NO DATA"
	}

	rootIR = &SQLRightIR{
		IRType:   TypeCreateView,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    asSourceNode,
		Prefix:   "",
		Infix:    " AS ",
		Suffix:   suffix,
		Depth:    depth,
	}

	return rootIR
}

// RefreshMaterializedView represents a REFRESH MATERIALIZED VIEW statement.
type RefreshMaterializedView struct {
	Name              *UnresolvedObjectName
	Concurrently      bool
	RefreshDataOption RefreshDataOption
}

// RefreshDataOption corresponds to arguments for the REFRESH MATERIALIZED VIEW
// statement.
type RefreshDataOption int

const (
	// RefreshDataDefault refers to no option provided to the REFRESH MATERIALIZED
	// VIEW statement.
	RefreshDataDefault RefreshDataOption = iota
	// RefreshDataWithData refers to the WITH DATA option provided to the REFRESH
	// MATERIALIZED VIEW statement.
	RefreshDataWithData
	// RefreshDataClear refers to the WITH NO DATA option provided to the REFRESH
	// MATERIALIZED VIEW statement.
	RefreshDataClear
)

// Format implements the NodeFormatter interface.
func (node *RefreshMaterializedView) Format(ctx *FmtCtx) {
	ctx.WriteString("REFRESH MATERIALIZED VIEW ")
	if node.Concurrently {
		ctx.WriteString("CONCURRENTLY ")
	}
	ctx.FormatNode(node.Name)
	switch node.RefreshDataOption {
	case RefreshDataWithData:
		ctx.WriteString(" WITH DATA")
	case RefreshDataClear:
		ctx.WriteString(" WITH NO DATA")
	}
}

// SQLRight Code Injection.
func (node *RefreshMaterializedView) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""

	if node.Concurrently {
		prefix += "CONCURRENTLY "
	}

	viewName := node.Name.String()
	viewNameNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataViewName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         viewName,
	}

	infix := ""
	switch node.RefreshDataOption {
	case RefreshDataWithData:
		infix = " WITH DATA"
	case RefreshDataClear:
		infix = " WITH NO DATA"
	}

	rootIR := &SQLRightIR{
		IRType:   TypeRefreshMaterializedView,
		DataType: DataNone,
		LNode:    viewNameNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  infix,
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// CreateStats represents a CREATE STATISTICS statement.
type CreateStats struct {
	Name        Name
	ColumnNames NameList
	Table       TableExpr
	Options     CreateStatsOptions
}

// Format implements the NodeFormatter interface.
func (node *CreateStats) Format(ctx *FmtCtx) {
	ctx.WriteString("CREATE STATISTICS ")
	ctx.FormatNode(&node.Name)

	if len(node.ColumnNames) > 0 {
		ctx.WriteString(" ON ")
		ctx.FormatNode(&node.ColumnNames)
	}

	ctx.WriteString(" FROM ")
	ctx.FormatNode(node.Table)

	if !node.Options.Empty() {
		ctx.WriteString(" WITH OPTIONS ")
		ctx.FormatNode(&node.Options)
	}
}

// SQLRight Code Injection.
func (node *CreateStats) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "CREATE STATISTICS "

	statName := node.Name.String()
	statNameNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataStatsName,
		ContextFlag: ContextDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         statName,
	}

	infix := ""
	var columnNameNode *SQLRightIR
	if len(node.ColumnNames) > 0 {
		infix = " ON "
		columnNameNode = node.ColumnNames.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    statNameNode,
		RNode:    columnNameNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	fromTableNode := node.Table.LogCurrentNode(depth + 1)
	rootIR = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    fromTableNode,
		Prefix:   "",
		Infix:    " FROM ",
		Suffix:   "",
		Depth:    depth,
	}

	if !node.Options.Empty() {
		optionNode := node.Options.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optionNode,
			Prefix:   "",
			Infix:    " WITH OPTIONS ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeCreateStats

	return rootIR
}

// CreateStatsOptions contains options for CREATE STATISTICS.
type CreateStatsOptions struct {
	// Throttling enables throttling and indicates the fraction of time we are
	// idling (between 0 and 1).
	Throttling float64

	// AsOf performs a historical read at the given timestamp.
	// Note that the timestamp will be moved up during the operation if it gets
	// too old (in order to avoid problems with TTL expiration).
	AsOf AsOfClause
}

// Empty returns true if no options were provided.
func (o *CreateStatsOptions) Empty() bool {
	return o.Throttling == 0 && o.AsOf.Expr == nil
}

// Format implements the NodeFormatter interface.
func (o *CreateStatsOptions) Format(ctx *FmtCtx) {
	sep := ""
	if o.Throttling != 0 {
		ctx.WriteString("THROTTLING ")
		// TODO(knz): Remove all this with ctx.FormatNode()
		// if/when throttling supports full expressions.
		if ctx.flags.HasFlags(FmtHideConstants) {
			// Using the value '0.001' instead of '0.0', because
			// when using '0.0' the statement does not get
			// formatted with the THROTTLING option.
			ctx.WriteString("0.001")
		} else {
			fmt.Fprintf(ctx, "%g", o.Throttling)
		}
		sep = " "
	}
	if o.AsOf.Expr != nil {
		ctx.WriteString(sep)
		ctx.FormatNode(&o.AsOf)
		sep = " "
	}
}

// SQLRight Code Injection.
func (node *CreateStatsOptions) LogCurrentNode(depth int) *SQLRightIR {

	sep := ""
	prefix := ""
	var throttleNumber *SQLRightIR
	if node.Throttling != 0 {
		prefix += "THROTTLING "
		throttleNumber = &SQLRightIR{
			IRType:       TypeFloatLiteral,
			DataType:     DataLiteral,
			DataAffinity: AFFIFLOAT,
			Prefix:       "",
			Infix:        "",
			Suffix:       "",
			Depth:        depth,
			FValue:       node.Throttling,
		}
		sep = " "
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    throttleNumber,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	if node.AsOf.Expr != nil {
		infix := sep
		asOfNode := node.AsOf.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    asOfNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeCreateStatsOptions

	return rootIR
}

// CombineWith combines two options, erroring out if the two options contain
// incompatible settings.
func (o *CreateStatsOptions) CombineWith(other *CreateStatsOptions) error {
	if other.Throttling != 0 {
		if o.Throttling != 0 {
			return errors.New("THROTTLING specified multiple times")
		}
		o.Throttling = other.Throttling
	}
	if other.AsOf.Expr != nil {
		if o.AsOf.Expr != nil {
			return errors.New("AS OF specified multiple times")
		}
		o.AsOf = other.AsOf
	}
	return nil
}

// CreateExtension represents a CREATE EXTENSION statement.
type CreateExtension struct {
	Name        string
	IfNotExists bool
}

// Format implements the NodeFormatter interface.
func (node *CreateExtension) Format(ctx *FmtCtx) {
	ctx.WriteString("CREATE EXTENSION ")
	if node.IfNotExists {
		ctx.WriteString("IF NOT EXISTS ")
	}
	// NB: we do not anonymize the extension name
	// because 1) we assume that extension names
	// do not contain sensitive information and
	// 2) we want to get telemetry on which extensions
	// users attempt to load.
	ctx.WriteString(node.Name)
}

// SQLRight Code Injection.
func (node *CreateExtension) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "CREATE EXTENSION "

	optIfNotExistStr := ""
	if node.IfNotExists {
		optIfNotExistStr = "IF NOT EXISTS "
	}
	ifNotExistsNode := &SQLRightIR{
		IRType:   TypeOptIfNotExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfNotExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	nameNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataExtensionName,
		ContextFlag: ContextDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Name,
	}

	rootIR := &SQLRightIR{
		IRType:   TypeCreateExtension,
		DataType: DataNone,
		LNode:    ifNotExistsNode,
		RNode:    nameNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// CreateExternalConnection represents a CREATE EXTERNAL CONNECTION statement.
type CreateExternalConnection struct {
	ConnectionLabelSpec LabelSpec
	As                  Expr
}

var _ Statement = &CreateExternalConnection{}

// Format implements the Statement interface.
func (node *CreateExternalConnection) Format(ctx *FmtCtx) {
	ctx.WriteString("CREATE EXTERNAL CONNECTION")
	ctx.FormatNode(&node.ConnectionLabelSpec)
	ctx.WriteString(" AS ")
	ctx.FormatNode(node.As)
}

// SQLRight Code Injection.
func (node *CreateExternalConnection) LogCurrentNode(depth int) *SQLRightIR {

	connectionNode := node.ConnectionLabelSpec.LogCurrentNode(depth + 1)
	asNode := node.As.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeCreateExternalConnection,
		DataType: DataNone,
		LNode:    connectionNode,
		RNode:    asNode,
		Prefix:   "CREATE EXTERNAL CONNECTION",
		Infix:    " AS ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}
