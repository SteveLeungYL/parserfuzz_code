// Copyright 2019 PingCAP, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// See the License for the specific language governing permissions and
// limitations under the License.

package ast

import (
	"github.com/pingcap/tidb/parser/format"
	"strconv"
)

var _ StmtNode = &IndexAdviseStmt{}

// IndexAdviseStmt is used to advise indexes
type IndexAdviseStmt struct {
	stmtNode

	IsLocal     bool
	Path        string
	MaxMinutes  uint64
	MaxIndexNum *MaxIndexNumClause
	LinesInfo   *LinesClause

	SqlRsgInterface
}

// RSG fuzzer inject.
func (n *IndexAdviseStmt) LogCurrentNode(depth int) *SqlRsgIR {
	var rootNode *SqlRsgIR = &SqlRsgIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}
	prefix := " INDEX ADVISE "

	if n.IsLocal {
		prefix += "LOCAL "
	}
	prefix += "INFILE "
	prefix += "'./in'"

	if n.MaxMinutes != UnspecifiedSize {
		tmpPrefix := " MAX_MINUTES "
		lNode := &SqlRsgIR{
			IRType:   TypeIntegerLiteral,
			DataType: DataNone,
			IValue:   int64(n.MaxMinutes),
			Str:      strconv.FormatUint(n.MaxMinutes, 10),
			Prefix:   tmpPrefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth + 1,
		}
		rootNode.LNode = lNode
	}

	var rNode *SqlRsgIR
	if n.MaxIndexNum != nil {
		rNode = n.MaxIndexNum.LogCurrentNode(depth + 1)
	}

	rootNode = &SqlRsgIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootNode,
		RNode:    rNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}
	rNode = nil
	prefix = ""

	rNode = n.LinesInfo.LogCurrentNode(depth + 1)
	rootNode = &SqlRsgIR{
		IRType:   TypeIndexAdviseStmt,
		DataType: DataNone,
		LNode:    rootNode,
		RNode:    rNode,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootNode
}

// Restore implements Node Accept interface.
func (n *IndexAdviseStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("INDEX ADVISE ")
	if n.IsLocal {
		ctx.WriteKeyWord("LOCAL ")
	}
	ctx.WriteKeyWord("INFILE ")
	ctx.WriteString(n.Path)
	if n.MaxMinutes != UnspecifiedSize {
		ctx.WriteKeyWord(" MAX_MINUTES ")
		ctx.WritePlainf("%d", n.MaxMinutes)
	}
	if n.MaxIndexNum != nil {
		n.MaxIndexNum.Restore(ctx)
	}
	n.LinesInfo.Restore(ctx)
	return nil
}

// Accept implements Node Accept interface.
func (n *IndexAdviseStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*IndexAdviseStmt)
	return v.Leave(n)
}

// MaxIndexNumClause represents 'maximum number of indexes' clause in index advise statement.
type MaxIndexNumClause struct {
	PerTable uint64
	PerDB    uint64

	SqlRsgInterface
}

// RSG fuzzer inject.
func (n *MaxIndexNumClause) LogCurrentNode(depth int) *SqlRsgIR {

	rootNode := &SqlRsgIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	prefix := " MAX_IDXNUM"
	if n.PerTable != UnspecifiedSize {
		tmpPrefix := " PER_TABLE "

		lNode := &SqlRsgIR{
			IRType:   TypeIntegerLiteral,
			DataType: DataNone,
			IValue:   int64(n.PerTable),
			Str:      strconv.FormatUint(n.PerTable, 10),
			Prefix:   tmpPrefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth + 1,
		}
		rootNode.LNode = lNode
	}

	midfix := ""
	var rNode *SqlRsgIR
	if n.PerDB != UnspecifiedSize {
		midfix = " PER_DB "
		rNode = &SqlRsgIR{
			IRType:   TypeIntegerLiteral,
			DataType: DataNone,
			IValue:   int64(n.PerDB),
			Str:      strconv.FormatUint(n.PerDB, 10),
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootNode = &SqlRsgIR{
		IRType:   TypeMaxIndexNumClause,
		DataType: DataNone,
		LNode:    rootNode,
		RNode:    rNode,
		Prefix:   prefix,
		Infix:    midfix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootNode

}

// Restore for max index num clause
func (n *MaxIndexNumClause) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord(" MAX_IDXNUM")
	if n.PerTable != UnspecifiedSize {
		ctx.WriteKeyWord(" PER_TABLE ")
		ctx.WritePlainf("%d", n.PerTable)
	}
	if n.PerDB != UnspecifiedSize {
		ctx.WriteKeyWord(" PER_DB ")
		ctx.WritePlainf("%d", n.PerDB)
	}
	return nil
}
