// Copyright 2015 PingCAP, Inc.
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
	"bytes"
	"fmt"
	"net/url"
	"strconv"
	"strings"

	"github.com/pingcap/errors"
	"github.com/pingcap/tidb/parser/auth"
	"github.com/pingcap/tidb/parser/charset"
	"github.com/pingcap/tidb/parser/format"
	"github.com/pingcap/tidb/parser/model"
	"github.com/pingcap/tidb/parser/mysql"
	"github.com/pingcap/tidb/parser/sql_ir"
)

var (
	_ StmtNode = &AdminStmt{}
	_ StmtNode = &AlterUserStmt{}
	_ StmtNode = &BeginStmt{}
	_ StmtNode = &BinlogStmt{}
	_ StmtNode = &CommitStmt{}
	_ StmtNode = &CreateUserStmt{}
	_ StmtNode = &DeallocateStmt{}
	_ StmtNode = &DoStmt{}
	_ StmtNode = &ExecuteStmt{}
	_ StmtNode = &ExplainStmt{}
	_ StmtNode = &GrantStmt{}
	_ StmtNode = &PrepareStmt{}
	_ StmtNode = &RollbackStmt{}
	_ StmtNode = &SetPwdStmt{}
	_ StmtNode = &SetRoleStmt{}
	_ StmtNode = &SetDefaultRoleStmt{}
	_ StmtNode = &SetStmt{}
	_ StmtNode = &UseStmt{}
	_ StmtNode = &FlushStmt{}
	_ StmtNode = &KillStmt{}
	_ StmtNode = &CreateBindingStmt{}
	_ StmtNode = &DropBindingStmt{}
	_ StmtNode = &SetBindingStmt{}
	_ StmtNode = &ShutdownStmt{}
	_ StmtNode = &RestartStmt{}
	_ StmtNode = &RenameUserStmt{}
	_ StmtNode = &HelpStmt{}
	_ StmtNode = &PlanReplayerStmt{}
	_ StmtNode = &CompactTableStmt{}

	_ Node = &PrivElem{}
	_ Node = &VariableAssignment{}
)

// Isolation level constants.
const (
	ReadCommitted   = "READ-COMMITTED"
	ReadUncommitted = "READ-UNCOMMITTED"
	Serializable    = "SERIALIZABLE"
	RepeatableRead  = "REPEATABLE-READ"

	PumpType    = "PUMP"
	DrainerType = "DRAINER"
)

// Transaction mode constants.
const (
	Optimistic  = "OPTIMISTIC"
	Pessimistic = "PESSIMISTIC"
)

// TypeOpt is used for parsing data type option from SQL.
type TypeOpt struct {
	IsUnsigned bool
	IsZerofill bool
}

// FloatOpt is used for parsing floating-point type option from SQL.
// See http://dev.mysql.com/doc/refman/5.7/en/floating-point-types.html
type FloatOpt struct {
	Flen    int
	Decimal int
}

// AuthOption is used for parsing create use statement.
type AuthOption struct {
	// ByAuthString set as true, if AuthString is used for authorization. Otherwise, authorization is done by HashString.
	ByAuthString bool
	AuthString   string
	HashString   string
	AuthPlugin   string
}

func (n *AuthOption) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "IDENTIFIED"

	if n.AuthPlugin != "" {
		prefix += " WITH "
		prefix += n.AuthPlugin
	}
	if n.ByAuthString {
		prefix += " BY " + n.AuthString
	} else if n.HashString != "" {
		prefix += " AS " + n.HashString
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeAuthOption

	return rootNode

}

// Restore implements Node interface.
func (n *AuthOption) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("IDENTIFIED")
	if n.AuthPlugin != "" {
		ctx.WriteKeyWord(" WITH ")
		ctx.WriteString(n.AuthPlugin)
	}
	if n.ByAuthString {
		ctx.WriteKeyWord(" BY ")
		ctx.WriteString(n.AuthString)
	} else if n.HashString != "" {
		ctx.WriteKeyWord(" AS ")
		ctx.WriteString(n.HashString)
	}
	return nil
}

// TraceStmt is a statement to trace what sql actually does at background.
type TraceStmt struct {
	stmtNode

	Stmt   StmtNode
	Format string

	TracePlan       bool
	TracePlanTarget string
}

func (n *TraceStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "TRACE "

	if n.TracePlan {
		prefix += "PLAN "
		if n.TracePlanTarget != "" {
			prefix += "TARGET = " + n.TracePlanTarget + " "
		}
	} else if n.Format != "row" {
		prefix += "FORMAT = " + n.Format + " "
	}

	lNode := n.Stmt.LogCurrentNode(depth + 1)

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeTraceStmt

	return rootNode

}

// Restore implements Node interface.
func (n *TraceStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("TRACE ")
	if n.TracePlan {
		ctx.WriteKeyWord("PLAN ")
		if n.TracePlanTarget != "" {
			ctx.WriteKeyWord("TARGET")
			ctx.WritePlain(" = ")
			ctx.WriteString(n.TracePlanTarget)
			ctx.WritePlain(" ")
		}
	} else if n.Format != "row" {
		ctx.WriteKeyWord("FORMAT")
		ctx.WritePlain(" = ")
		ctx.WriteString(n.Format)
		ctx.WritePlain(" ")
	}
	if err := n.Stmt.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore TraceStmt.Stmt")
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *TraceStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*TraceStmt)
	node, ok := n.Stmt.Accept(v)
	if !ok {
		return n, false
	}
	n.Stmt = node.(StmtNode)
	return v.Leave(n)
}

// ExplainForStmt is a statement to provite information about how is SQL statement executeing
// in connection #ConnectionID
// See https://dev.mysql.com/doc/refman/5.7/en/explain.html
type ExplainForStmt struct {
	stmtNode

	Format       string
	ConnectionID uint64
}

func (n *ExplainForStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "EXPLAIN FORMAT = " + n.Format + " FOR CONNECTION"
	lNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		IValue:   int64(n.ConnectionID),
		Str:      strconv.FormatUint(n.ConnectionID, 10),
		Depth:    depth,
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeExplainForStmt
	return rootNode

}

// Restore implements Node interface.
func (n *ExplainForStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("EXPLAIN ")
	ctx.WriteKeyWord("FORMAT ")
	ctx.WritePlain("= ")
	ctx.WriteString(n.Format)
	ctx.WritePlain(" ")
	ctx.WriteKeyWord("FOR ")
	ctx.WriteKeyWord("CONNECTION ")
	ctx.WritePlain(strconv.FormatUint(n.ConnectionID, 10))
	return nil
}

// Accept implements Node Accept interface.
func (n *ExplainForStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*ExplainForStmt)
	return v.Leave(n)
}

// ExplainStmt is a statement to provide information about how is SQL statement executed
// or get columns information in a table.
// See https://dev.mysql.com/doc/refman/5.7/en/explain.html
type ExplainStmt struct {
	stmtNode

	Stmt    StmtNode
	Format  string
	Analyze bool
}

func (n *ExplainStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := ""
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	if showStmt, ok := n.Stmt.(*ShowStmt); ok {
		prefix += "DESC "

		lNode := showStmt.LogCurrentNode(depth + 1)

		rootNode.LNode = lNode
		rootNode.Prefix = prefix

		midfix := ""
		if showStmt.Column != nil {
			midfix = " "
			rNode := showStmt.Column.LogCurrentNode(depth + 1)

			columnNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(rNode, sql_ir.DataColumnName)
			for _, columnNameNode := range columnNameNodeList {
				columnNameNode.DataType = sql_ir.DataColumnName
				columnNameNode.ContextFlag = sql_ir.ContextUse
			}

			rootNode.RNode = rNode
			rootNode.Infix = midfix
		}

		rootNode.IRType = sql_ir.TypeExplainStmt
		return rootNode
	}

	midfix := "EXPLAIN "
	if n.Analyze {
		midfix += "ANALYZE "
	}

	if !n.Analyze || strings.ToLower(n.Format) != "row" {
		midfix += "FORMAT = " + n.Format + " "
	}
	rNode := n.Stmt.LogCurrentNode(depth + 1)

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		Infix:    midfix,
		RNode:    rNode,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeExplainStmt

	return rootNode

}

// Restore implements Node interface.
func (n *ExplainStmt) Restore(ctx *format.RestoreCtx) error {
	if showStmt, ok := n.Stmt.(*ShowStmt); ok {
		ctx.WriteKeyWord("DESC ")
		if err := showStmt.Table.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore ExplainStmt.ShowStmt.Table")
		}
		if showStmt.Column != nil {
			ctx.WritePlain(" ")
			if err := showStmt.Column.Restore(ctx); err != nil {
				return errors.Annotate(err, "An error occurred while restore ExplainStmt.ShowStmt.Column")
			}
		}
		return nil
	}
	ctx.WriteKeyWord("EXPLAIN ")
	if n.Analyze {
		ctx.WriteKeyWord("ANALYZE ")
	}
	if !n.Analyze || strings.ToLower(n.Format) != "row" {
		ctx.WriteKeyWord("FORMAT ")
		ctx.WritePlain("= ")
		ctx.WriteString(n.Format)
		ctx.WritePlain(" ")
	}
	if err := n.Stmt.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore ExplainStmt.Stmt")
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *ExplainStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*ExplainStmt)
	node, ok := n.Stmt.Accept(v)
	if !ok {
		return n, false
	}
	n.Stmt = node.(StmtNode)
	return v.Leave(n)
}

// PlanReplayerStmt is a statement to dump or load information for recreating plans
type PlanReplayerStmt struct {
	stmtNode

	Stmt    StmtNode
	Analyze bool
	Load    bool
	File    string
	// Where is the where clause in select statement.
	Where ExprNode
	// OrderBy is the ordering expression list.
	OrderBy *OrderByClause
	// Limit is the limit clause.
	Limit *Limit
}

func (n *PlanReplayerStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := ""
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	if n.Load {
		prefix += "PLAN REPLAYER LOAD " + n.File
		rootNode.Prefix = prefix
		rootNode.IRType = sql_ir.TypePlanReplayerStmt
		return rootNode
	}

	prefix += "PLAN REPLAYER DUMP EXPLAIN "
	if n.Analyze {
		prefix += "ANALYZE "
	}

	if n.Stmt == nil {
		prefix += "SLOW QUERY"
		if n.Where != nil {
			prefix += " WHERE "
			lNode := n.Where.LogCurrentNode(depth + 1)

			rootNode.LNode = lNode
		}

		rootNode.Prefix = prefix
		prefix = ""

		if n.OrderBy != nil {
			midfix := " "
			rNode := n.OrderBy.LogCurrentNode(depth + 1)

			rootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    rootNode,
				RNode:    rNode,
				Infix:    midfix,
				Depth:    depth,
			}
		}

		rootNode.Prefix = prefix
		prefix = ""

		if n.Limit != nil {
			midfix := " "
			rNode := n.Limit.LogCurrentNode(depth + 1)
			rootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    rootNode,
				RNode:    rNode,
				Infix:    midfix,
				Depth:    depth,
			}
		}
		rootNode.Prefix = prefix
		prefix = ""

		rootNode.IRType = sql_ir.TypePlanReplayerStmt
		return rootNode

	}

	lNode := n.Stmt.LogCurrentNode(depth + 1)
	rootNode.LNode = lNode
	rootNode.Prefix = prefix

	rootNode.IRType = sql_ir.TypePlanReplayerStmt

	return rootNode

}

// Restore implements Node interface.
func (n *PlanReplayerStmt) Restore(ctx *format.RestoreCtx) error {
	if n.Load {
		ctx.WriteKeyWord("PLAN REPLAYER LOAD ")
		ctx.WriteString(n.File)
		return nil
	}
	ctx.WriteKeyWord("PLAN REPLAYER DUMP EXPLAIN ")
	if n.Analyze {
		ctx.WriteKeyWord("ANALYZE ")
	}
	if n.Stmt == nil {
		ctx.WriteKeyWord("SLOW QUERY")
		if n.Where != nil {
			ctx.WriteKeyWord(" WHERE ")
			if err := n.Where.Restore(ctx); err != nil {
				return errors.Annotate(err, "An error occurred while restore PlanReplayerStmt.Where")
			}
		}
		if n.OrderBy != nil {
			ctx.WriteKeyWord(" ")
			if err := n.OrderBy.Restore(ctx); err != nil {
				return errors.Annotate(err, "An error occurred while restore PlanReplayerStmt.OrderBy")
			}
		}
		if n.Limit != nil {
			ctx.WriteKeyWord(" ")
			if err := n.Limit.Restore(ctx); err != nil {
				return errors.Annotate(err, "An error occurred while restore PlanReplayerStmt.Limit")
			}
		}
		return nil
	}
	if err := n.Stmt.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore PlanReplayerStmt.Stmt")
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *PlanReplayerStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}

	n = newNode.(*PlanReplayerStmt)

	if n.Load {
		return v.Leave(n)
	}

	if n.Stmt == nil {
		if n.Where != nil {
			node, ok := n.Where.Accept(v)
			if !ok {
				return n, false
			}
			n.Where = node.(ExprNode)
		}

		if n.OrderBy != nil {
			node, ok := n.OrderBy.Accept(v)
			if !ok {
				return n, false
			}
			n.OrderBy = node.(*OrderByClause)
		}

		if n.Limit != nil {
			node, ok := n.Limit.Accept(v)
			if !ok {
				return n, false
			}
			n.Limit = node.(*Limit)
		}
		return v.Leave(n)
	}

	node, ok := n.Stmt.Accept(v)
	if !ok {
		return n, false
	}
	n.Stmt = node.(StmtNode)
	return v.Leave(n)
}

type CompactReplicaKind string

const (
	// CompactReplicaKindTiFlash means compacting TiFlash replicas.
	CompactReplicaKindTiFlash = "TIFLASH"

	// CompactReplicaKindTiKV means compacting TiKV replicas.
	CompactReplicaKindTiKV = "TIKV"
)

// CompactTableStmt is a statement to manually compact a table.
type CompactTableStmt struct {
	stmtNode

	Table       *TableName
	ReplicaKind CompactReplicaKind
}

func (n *CompactTableStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "ALTER TABLE "
	lNode := n.Table.LogCurrentNode(depth + 1)
	tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(lNode, sql_ir.DataTableName)
	for _, tableNameNode := range tableNameNodeList {
		tableNameNode.DataType = sql_ir.DataTableName
		tableNameNode.ContextFlag = sql_ir.ContextUse
	}

	// Note: There is only TiFlash replica available now. TiKV will be added later.
	midfix := " COMPACT " + string(n.ReplicaKind) + " REPLICA"

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Infix:    midfix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeCompactTableStmt

	return rootNode

}

// Restore implements Node interface.
func (n *CompactTableStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("ALTER TABLE ")
	if err := n.Table.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while add table")
	}

	// Note: There is only TiFlash replica available now. TiKV will be added later.
	ctx.WriteKeyWord(" COMPACT ")
	ctx.WriteKeyWord(string(n.ReplicaKind))
	ctx.WriteKeyWord(" REPLICA")
	return nil
}

// Accept implements Node Accept interface.
func (n *CompactTableStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*CompactTableStmt)
	node, ok := n.Table.Accept(v)
	if !ok {
		return n, false
	}
	n.Table = node.(*TableName)
	return v.Leave(n)
}

// PrepareStmt is a statement to prepares a SQL statement which contains placeholders,
// and it is executed with ExecuteStmt and released with DeallocateStmt.
// See https://dev.mysql.com/doc/refman/5.7/en/prepare.html
type PrepareStmt struct {
	stmtNode

	Name    string
	SQLText string
	SQLVar  *VariableExpr
}

func (n *PrepareStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "PREPARE "
	lNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataStatementPreparedName,
		ContextFlag: sql_ir.ContextDefine,
		Str:         n.Name,
		Depth:       depth,
	}
	midfix := " FROM "

	if n.SQLText != "" {
		rNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeStringLiteral,
			DataType: sql_ir.DataNone,
			Str:      "'" + n.SQLText + "'",
			Depth:    depth,
		}

		rootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    lNode,
			RNode:    rNode,
			Prefix:   prefix,
			Infix:    midfix,
			Depth:    depth,
		}
		rootNode.IRType = sql_ir.TypePrepareStmt
		return rootNode
	}

	if n.SQLVar != nil {
		rNode := n.SQLVar.LogCurrentNode(depth + 1)
		rootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    lNode,
			RNode:    rNode,
			Prefix:   prefix,
			Infix:    midfix,
			Depth:    depth,
		}
		rootNode.IRType = sql_ir.TypePrepareStmt
		return rootNode
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	rootNode.IRType = sql_ir.TypePrepareStmt

	// Return empty
	return rootNode

}

// Restore implements Node interface.
func (n *PrepareStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("PREPARE ")
	ctx.WriteName(n.Name)
	ctx.WriteKeyWord(" FROM ")
	if n.SQLText != "" {
		ctx.WriteString(n.SQLText)
		return nil
	}
	if n.SQLVar != nil {
		if err := n.SQLVar.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore PrepareStmt.SQLVar")
		}
		return nil
	}
	return errors.New("An error occurred while restore PrepareStmt")
}

// Accept implements Node Accept interface.
func (n *PrepareStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*PrepareStmt)
	if n.SQLVar != nil {
		node, ok := n.SQLVar.Accept(v)
		if !ok {
			return n, false
		}
		n.SQLVar = node.(*VariableExpr)
	}
	return v.Leave(n)
}

// DeallocateStmt is a statement to release PreparedStmt.
// See https://dev.mysql.com/doc/refman/5.7/en/deallocate-prepare.html
type DeallocateStmt struct {
	stmtNode

	Name string
}

func (n *DeallocateStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "DEALLOCATE PREPARE "
	nameNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataStatementPreparedName,
		ContextFlag: sql_ir.ContextUndefine,
		Str:         n.Name,
		Depth:       depth,
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    nameNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeDeallocateStmt
	return rootNode

}

// Restore implements Node interface.
func (n *DeallocateStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("DEALLOCATE PREPARE ")
	ctx.WriteName(n.Name)
	return nil
}

// Accept implements Node Accept interface.
func (n *DeallocateStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*DeallocateStmt)
	return v.Leave(n)
}

// Prepared represents a prepared statement.
type Prepared struct {
	Stmt          StmtNode
	StmtType      string
	Params        []ParamMarkerExpr
	SchemaVersion int64
	UseCache      bool
	CachedPlan    interface{}
	CachedNames   interface{}
}

// ExecuteStmt is a statement to execute PreparedStmt.
// See https://dev.mysql.com/doc/refman/5.7/en/execute.html
type ExecuteStmt struct {
	stmtNode

	Name       string
	UsingVars  []ExprNode
	BinaryArgs interface{}
	ExecID     uint32
	IdxInMulti int
}

func (n *ExecuteStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "EXECUTE "
	nameNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataStatementPreparedName,
		ContextFlag: sql_ir.ContextUse,
		Str:         n.Name,
		Depth:       depth,
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    nameNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	if len(n.UsingVars) > 0 {
		topMidfix := " USING "
		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for i, val := range n.UsingVars {
			midfix := ""
			if i != 0 {
				midfix = ", "
			}
			valNode := val.LogCurrentNode(depth + 1)

			if i == 0 {
				tmpRootNode.LNode = valNode
			} else {
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    valNode,
					Infix:    midfix,
					Depth:    depth,
				}
			}
		}
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    tmpRootNode,
			Infix:    topMidfix,
			Depth:    depth,
		}
	}

	rootNode.IRType = sql_ir.TypeExecuteStmt

	return rootNode

}

// Restore implements Node interface.
func (n *ExecuteStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("EXECUTE ")
	ctx.WriteName(n.Name)
	if len(n.UsingVars) > 0 {
		ctx.WriteKeyWord(" USING ")
		for i, val := range n.UsingVars {
			if i != 0 {
				ctx.WritePlain(",")
			}
			if err := val.Restore(ctx); err != nil {
				return errors.Annotatef(err, "An error occurred while restore ExecuteStmt.UsingVars index %d", i)
			}
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *ExecuteStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*ExecuteStmt)
	for i, val := range n.UsingVars {
		node, ok := val.Accept(v)
		if !ok {
			return n, false
		}
		n.UsingVars[i] = node.(ExprNode)
	}
	return v.Leave(n)
}

// BeginStmt is a statement to start a new transaction.
// See https://dev.mysql.com/doc/refman/5.7/en/commit.html
type BeginStmt struct {
	stmtNode
	Mode                  string
	CausalConsistencyOnly bool
	ReadOnly              bool
	// AS OF is used to read the data at a specific point of time.
	// Should only be used when ReadOnly is true.
	AsOf *AsOfClause
}

func (n *BeginStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := ""
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	if n.Mode == "" {
		if n.ReadOnly {
			prefix += "START TRANSACTION READ ONLY"
			if n.AsOf != nil {
				prefix += " "

				lNode := n.AsOf.LogCurrentNode(depth + 1)

				rootNode := &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnaryOperationExpr,
					DataType: sql_ir.DataNone,
					LNode:    lNode,
					Prefix:   prefix,
					Depth:    depth,
				}

				rootNode.IRType = sql_ir.TypeBeginStmt
				return rootNode
			}
		} else if n.CausalConsistencyOnly {
			prefix += "START TRANSACTION WITH CAUSAL CONSISTENCY ONLY"
		} else {
			prefix += "START TRANSACTION"
		}
		rootNode.Prefix = prefix
	} else {
		prefix += "BEGIN " + n.Mode
		rootNode.Prefix = prefix
	}

	rootNode.IRType = sql_ir.TypeBeginStmt
	return rootNode

}

// Restore implements Node interface.
func (n *BeginStmt) Restore(ctx *format.RestoreCtx) error {
	if n.Mode == "" {
		if n.ReadOnly {
			ctx.WriteKeyWord("START TRANSACTION READ ONLY")
			if n.AsOf != nil {
				ctx.WriteKeyWord(" ")
				return n.AsOf.Restore(ctx)
			}
		} else if n.CausalConsistencyOnly {
			ctx.WriteKeyWord("START TRANSACTION WITH CAUSAL CONSISTENCY ONLY")
		} else {
			ctx.WriteKeyWord("START TRANSACTION")
		}
	} else {
		ctx.WriteKeyWord("BEGIN ")
		ctx.WriteKeyWord(n.Mode)
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *BeginStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*BeginStmt)
	return v.Leave(n)
}

// BinlogStmt is an internal-use statement.
// We just parse and ignore it.
// See http://dev.mysql.com/doc/refman/5.7/en/binlog.html
type BinlogStmt struct {
	stmtNode
	Str string
}

func (n *BinlogStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "BINLOG " + n.Str

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeBinlogStmt

	return rootNode
}

// Restore implements Node interface.
func (n *BinlogStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("BINLOG ")
	ctx.WriteString(n.Str)
	return nil
}

// Accept implements Node Accept interface.
func (n *BinlogStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*BinlogStmt)
	return v.Leave(n)
}

// CompletionType defines completion_type used in COMMIT and ROLLBACK statements
type CompletionType int8

const (
	// CompletionTypeDefault refers to NO_CHAIN
	CompletionTypeDefault CompletionType = iota
	CompletionTypeChain
	CompletionTypeRelease
)

func (n *CompletionType) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := ""
	switch *n {
	case CompletionTypeDefault:
		break
	case CompletionTypeChain:
		prefix += " AND CHAIN"
	case CompletionTypeRelease:
		prefix += " RELEASE "
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeCompletionType
	return nil

}

func (n CompletionType) Restore(ctx *format.RestoreCtx) error {
	switch n {
	case CompletionTypeDefault:
		break
	case CompletionTypeChain:
		ctx.WriteKeyWord(" AND CHAIN")
	case CompletionTypeRelease:
		ctx.WriteKeyWord(" RELEASE")
	}
	return nil
}

// CommitStmt is a statement to commit the current transaction.
// See https://dev.mysql.com/doc/refman/5.7/en/commit.html
type CommitStmt struct {
	stmtNode
	// CompletionType overwrites system variable `completion_type` within transaction
	CompletionType CompletionType
}

func (n *CommitStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "COMMIT"
	lNode := n.CompletionType.LogCurrentNode(depth + 1)

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeCommitStmt
	return rootNode

}

// Restore implements Node interface.
func (n *CommitStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("COMMIT")
	if err := n.CompletionType.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore CommitStmt.CompletionType")
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *CommitStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*CommitStmt)
	return v.Leave(n)
}

// RollbackStmt is a statement to roll back the current transaction.
// See https://dev.mysql.com/doc/refman/5.7/en/commit.html
type RollbackStmt struct {
	stmtNode
	// CompletionType overwrites system variable `completion_type` within transaction
	CompletionType CompletionType
}

func (n *RollbackStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "ROLLBACK"
	lNode := n.CompletionType.LogCurrentNode(depth + 1)

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeRollbackStmt

	return rootNode

}

// Restore implements Node interface.
func (n *RollbackStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("ROLLBACK")
	if err := n.CompletionType.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore RollbackStmt.CompletionType")
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *RollbackStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*RollbackStmt)
	return v.Leave(n)
}

// UseStmt is a statement to use the DBName database as the current database.
// See https://dev.mysql.com/doc/refman/5.7/en/use.html
type UseStmt struct {
	stmtNode

	DBName string
}

func (n *UseStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "USE "
	dbNameNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataDatabaseName,
		ContextFlag: sql_ir.ContextUse,
		Str:         n.DBName,
		Depth:       depth,
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    dbNameNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeUseStmt

	return rootNode

}

// Restore implements Node interface.
func (n *UseStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("USE ")
	ctx.WriteName(n.DBName)
	return nil
}

// Accept implements Node Accept interface.
func (n *UseStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*UseStmt)
	return v.Leave(n)
}

const (
	// SetNames is the const for set names stmt.
	// If VariableAssignment.Name == Names, it should be set names stmt.
	SetNames = "SetNAMES"
	// SetCharset is the const for set charset stmt.
	SetCharset = "SetCharset"
)

// VariableAssignment is a variable assignment struct.
type VariableAssignment struct {
	node
	Name     string
	Value    ExprNode
	IsGlobal bool
	IsSystem bool

	// ExtendValue is a way to store extended info.
	// VariableAssignment should be able to store information for SetCharset/SetPWD Stmt.
	// For SetCharsetStmt, Value is charset, ExtendValue is collation.
	// TODO: Use SetStmt to implement set password statement.
	ExtendValue ValueExpr
}

func (n *VariableAssignment) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := ""
	midfix := ""
	var lNode *sql_ir.SqlRsgIR = nil

	if n.IsSystem {
		prefix += "@@"
		if n.IsGlobal {
			prefix += "GLOBAL"
		} else {
			prefix += "SESSION"
		}
		prefix += "."
	} else if n.Name != SetNames && n.Name != SetCharset {
		prefix += "@"
	}
	if n.Name == SetNames {
		prefix += "NAMES "
	} else if n.Name == SetCharset {
		prefix += "CHARSET "
	} else {
		lNode = &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataVariableName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.Name,
			Depth:       depth,
		}
		midfix = " = "
	}

	rNode := n.Value.LogCurrentNode(depth + 1)
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		RNode:    rNode,
		Prefix:   prefix,
		Infix:    midfix,
		Depth:    depth,
	}

	if n.ExtendValue != nil {
		midfix = " COLLATE "
		rNode = n.ExtendValue.LogCurrentNode(depth + 1)
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Infix:    midfix,
			Depth:    depth,
		}
	}

	rootNode.IRType = sql_ir.TypeVariableAssignment
	return rootNode

}

// Restore implements Node interface.
func (n *VariableAssignment) Restore(ctx *format.RestoreCtx) error {
	if n.IsSystem {
		ctx.WritePlain("@@")
		if n.IsGlobal {
			ctx.WriteKeyWord("GLOBAL")
		} else {
			ctx.WriteKeyWord("SESSION")
		}
		ctx.WritePlain(".")
	} else if n.Name != SetNames && n.Name != SetCharset {
		ctx.WriteKeyWord("@")
	}
	if n.Name == SetNames {
		ctx.WriteKeyWord("NAMES ")
	} else if n.Name == SetCharset {
		ctx.WriteKeyWord("CHARSET ")
	} else {
		ctx.WriteName(n.Name)
		ctx.WritePlain("=")
	}
	if err := n.Value.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore VariableAssignment.Value")
	}
	if n.ExtendValue != nil {
		ctx.WriteKeyWord(" COLLATE ")
		if err := n.ExtendValue.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore VariableAssignment.ExtendValue")
		}
	}
	return nil
}

// Accept implements Node interface.
func (n *VariableAssignment) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*VariableAssignment)
	node, ok := n.Value.Accept(v)
	if !ok {
		return n, false
	}
	n.Value = node.(ExprNode)
	return v.Leave(n)
}

// FlushStmtType is the type for FLUSH statement.
type FlushStmtType int

// Flush statement types.
const (
	FlushNone FlushStmtType = iota
	FlushTables
	FlushPrivileges
	FlushStatus
	FlushTiDBPlugin
	FlushHosts
	FlushLogs
	FlushClientErrorsSummary
)

// LogType is the log type used in FLUSH statement.
type LogType int8

const (
	LogTypeDefault LogType = iota
	LogTypeBinary
	LogTypeEngine
	LogTypeError
	LogTypeGeneral
	LogTypeSlow
)

// FlushStmt is a statement to flush tables/privileges/optimizer costs and so on.
type FlushStmt struct {
	stmtNode

	Tp              FlushStmtType // Privileges/Tables/...
	NoWriteToBinLog bool
	LogType         LogType
	Tables          []*TableName // For FlushTableStmt, if Tables is empty, it means flush all tables.
	ReadLock        bool
	Plugins         []string
}

func (n *FlushStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}

	prefix := "FLUSH "
	if n.NoWriteToBinLog {
		prefix += "NO_WRITE_TO_BINLOG "
	}

	switch n.Tp {
	case FlushTables:
		prefix += "TABLES"

		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for i, v := range n.Tables {
			midfix := " "
			if i == 0 {
				midfix = " "
			} else {
				midfix = ", "
			}

			vNode := v.LogCurrentNode(depth + 1)
			tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(vNode, sql_ir.DataTableName)
			for _, tableNameNode := range tableNameNodeList {
				tableNameNode.DataType = sql_ir.DataTableName
				tableNameNode.ContextFlag = sql_ir.ContextUse
			}

			if i == 0 {
				tmpRootNode.LNode = vNode
			} else { // i > 0
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    vNode,
					Infix:    midfix,
					Depth:    depth,
				}
			}
		}

		midfix := ""
		if n.ReadLock {
			midfix = " WITH READ LOCK"
		}
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    tmpRootNode,
			Prefix:   prefix,
			Infix:    midfix,
			Depth:    depth,
		}
		prefix = ""
		midfix = "''"

	case FlushPrivileges:
		prefix += "PRIVILEGES"
		rootNode.Prefix = prefix
		prefix = ""

	case FlushStatus:
		prefix += "STATUS"
		rootNode.Prefix = prefix
		prefix = ""

	case FlushTiDBPlugin:
		prefix += "TIDB PLUGINS"

		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for i, v := range n.Plugins {
			tmpMidfix := ""
			if i == 0 {
				tmpMidfix = " "
			} else {
				tmpMidfix = ", "
			}
			vNode := &sql_ir.SqlRsgIR{
				IRType:      sql_ir.TypeIdentifier,
				DataType:    sql_ir.DataNone,
				ContextFlag: sql_ir.ContextUse,
				Str:         v,
				Depth:       depth,
			}

			if i == 0 {
				tmpRootNode.LNode = vNode
			} else { // i > 0
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    vNode,
					Infix:    tmpMidfix,
					Depth:    depth,
				}
			}

			rootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				Prefix:   prefix,
				Depth:    depth,
			}

			prefix = ""
		}
	case FlushHosts:
		prefix += "HOSTS"
		rootNode.Prefix = prefix
		prefix = ""
	case FlushLogs:
		switch n.LogType {
		case LogTypeDefault:
			prefix += "LOGS"
		case LogTypeBinary:
			prefix += "BINARY LOGS"
		case LogTypeEngine:
			prefix += "ENGINE LOGS"
		case LogTypeError:
			prefix += "ERROR LOGS"
		case LogTypeGeneral:
			prefix += "GENERAL LOGS"
		case LogTypeSlow:
			prefix += "SLOW LOGS"
		}
		rootNode.Prefix = prefix
		prefix = ""
	case FlushClientErrorsSummary:
		prefix += "CLIENT_ERRORS_SUMMARY"
		rootNode.Prefix = prefix
		prefix = ""
	default:
		break
	}

	rootNode.IRType = sql_ir.TypeFlushStmt
	return rootNode
}

// Restore implements Node interface.
func (n *FlushStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("FLUSH ")
	if n.NoWriteToBinLog {
		ctx.WriteKeyWord("NO_WRITE_TO_BINLOG ")
	}
	switch n.Tp {
	case FlushTables:
		ctx.WriteKeyWord("TABLES")
		for i, v := range n.Tables {
			if i == 0 {
				ctx.WritePlain(" ")
			} else {
				ctx.WritePlain(", ")
			}
			if err := v.Restore(ctx); err != nil {
				return errors.Annotatef(err, "An error occurred while restore FlushStmt.Tables[%d]", i)
			}
		}
		if n.ReadLock {
			ctx.WriteKeyWord(" WITH READ LOCK")
		}
	case FlushPrivileges:
		ctx.WriteKeyWord("PRIVILEGES")
	case FlushStatus:
		ctx.WriteKeyWord("STATUS")
	case FlushTiDBPlugin:
		ctx.WriteKeyWord("TIDB PLUGINS")
		for i, v := range n.Plugins {
			if i == 0 {
				ctx.WritePlain(" ")
			} else {
				ctx.WritePlain(", ")
			}
			ctx.WritePlain(v)
		}
	case FlushHosts:
		ctx.WriteKeyWord("HOSTS")
	case FlushLogs:
		var logType string
		switch n.LogType {
		case LogTypeDefault:
			logType = "LOGS"
		case LogTypeBinary:
			logType = "BINARY LOGS"
		case LogTypeEngine:
			logType = "ENGINE LOGS"
		case LogTypeError:
			logType = "ERROR LOGS"
		case LogTypeGeneral:
			logType = "GENERAL LOGS"
		case LogTypeSlow:
			logType = "SLOW LOGS"
		}
		ctx.WriteKeyWord(logType)
	case FlushClientErrorsSummary:
		ctx.WriteKeyWord("CLIENT_ERRORS_SUMMARY")
	default:
		return errors.New("Unsupported type of FlushStmt")
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *FlushStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*FlushStmt)
	return v.Leave(n)
}

// KillStmt is a statement to kill a query or connection.
type KillStmt struct {
	stmtNode

	// Query indicates whether terminate a single query on this connection or the whole connection.
	// If Query is true, terminates the statement the connection is currently executing, but leaves the connection itself intact.
	// If Query is false, terminates the connection associated with the given ConnectionID, after terminating any statement the connection is executing.
	Query        bool
	ConnectionID uint64
	// TiDBExtension is used to indicate whether the user knows he is sending kill statement to the right tidb-server.
	// When the SQL grammar is "KILL TIDB [CONNECTION | QUERY] connectionID", TiDBExtension will be set.
	// It's a special grammar extension in TiDB. This extension exists because, when the connection is:
	// client -> LVS proxy -> TiDB, and type Ctrl+C in client, the following action will be executed:
	// new a connection; kill xxx;
	// kill command may send to the wrong TiDB, because the exists of LVS proxy, and kill the wrong session.
	// So, "KILL TIDB" grammar is introduced, and it REQUIRES DIRECT client -> TiDB TOPOLOGY.
	// TODO: The standard KILL grammar will be supported once we have global connectionID.
	TiDBExtension bool
}

func (n *KillStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "KILL"
	if n.TiDBExtension {
		prefix += " TIDB "
	}
	if n.Query {
		prefix += " QUERY "
	}

	lNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		IValue:   int64(n.ConnectionID),
		Str:      strconv.FormatInt(int64(n.ConnectionID), 10),
		Depth:    depth,
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeKillStmt

	return rootNode

}

// Restore implements Node interface.
func (n *KillStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("KILL")
	if n.TiDBExtension {
		ctx.WriteKeyWord(" TIDB")
	}
	if n.Query {
		ctx.WriteKeyWord(" QUERY")
	}
	ctx.WritePlainf(" %d", n.ConnectionID)
	return nil
}

// Accept implements Node Accept interface.
func (n *KillStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*KillStmt)
	return v.Leave(n)
}

// SetStmt is the statement to set variables.
type SetStmt struct {
	stmtNode
	// Variables is the list of variable assignment.
	Variables []*VariableAssignment
}

func (n *SetStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "SET "

	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, v := range n.Variables {
		midfix := ""
		if i != 0 {
			midfix = ", "
		}
		vNode := v.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = vNode
		} else {
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    vNode,
				Infix:    midfix,
				Depth:    depth,
			}
		}
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    tmpRootNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeSetStmt

	return rootNode

}

// Restore implements Node interface.
func (n *SetStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("SET ")
	for i, v := range n.Variables {
		if i != 0 {
			ctx.WritePlain(", ")
		}
		if err := v.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore SetStmt.Variables[%d]", i)
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *SetStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*SetStmt)
	for i, val := range n.Variables {
		node, ok := val.Accept(v)
		if !ok {
			return n, false
		}
		n.Variables[i] = node.(*VariableAssignment)
	}
	return v.Leave(n)
}

// SetConfigStmt is the statement to set cluster configs.
type SetConfigStmt struct {
	stmtNode

	Type     string // TiDB, TiKV, PD
	Instance string // '127.0.0.1:3306'
	Name     string // the variable name
	Value    ExprNode
}

func (n *SetConfigStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "SET CONFIG "
	if n.Type != "" {
		prefix += n.Type
	} else {
		prefix += n.Instance
	}
	prefix += " "
	lNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataVariableName,
		ContextFlag: sql_ir.ContextUse,
		Str:         n.Name,
		Depth:       depth,
	}
	midfix := " = "
	rNode := n.Value.LogCurrentNode(depth + 1)

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		RNode:    rNode,
		Infix:    midfix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeSetConfigStmt
	return rootNode

}

func (n *SetConfigStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("SET CONFIG ")
	if n.Type != "" {
		ctx.WriteKeyWord(n.Type)
	} else {
		ctx.WriteString(n.Instance)
	}
	ctx.WritePlain(" ")
	ctx.WriteKeyWord(n.Name)
	ctx.WritePlain(" = ")
	return n.Value.Restore(ctx)
}

func (n *SetConfigStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*SetConfigStmt)
	if node, ok := n.Value.Accept(v); !ok {
		return n, false
	} else {
		n.Value = node.(ExprNode)
	}
	return v.Leave(n)
}

/*
// SetCharsetStmt is a statement to assign values to character and collation variables.
// See https://dev.mysql.com/doc/refman/5.7/en/set-statement.html
type SetCharsetStmt struct {
	stmtNode

	Charset string
	Collate string
}

// Accept implements Node Accept interface.
func (n *SetCharsetStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*SetCharsetStmt)
	return v.Leave(n)
}
*/

// SetPwdStmt is a statement to assign a password to user account.
// See https://dev.mysql.com/doc/refman/5.7/en/set-password.html
type SetPwdStmt struct {
	stmtNode

	User     *auth.UserIdentity
	Password string
}

func (n *SetPwdStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	prefix := "SET PASSWORD"

	if n.User != nil {
		prefix += " FOR "
		lNode := n.User.LogCurrentNode(depth + 1)
		rootNode.LNode = lNode
	}

	rootNode.Prefix = prefix
	prefix = ""

	midfix := " = "
	rNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeStringLiteral,
		DataType: sql_ir.DataNone,
		Str:      "'" + n.Password + "'",
		Depth:    depth,
	}

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    rNode,
		Infix:    midfix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeSetPwdStmt
	return rootNode

}

// Restore implements Node interface.
func (n *SetPwdStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("SET PASSWORD")
	if n.User != nil {
		ctx.WriteKeyWord(" FOR ")
		if err := n.User.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore SetPwdStmt.User")
		}
	}
	ctx.WritePlain("=")
	ctx.WriteString(n.Password)
	return nil
}

// SecureText implements SensitiveStatement interface.
func (n *SetPwdStmt) SecureText() string {
	return fmt.Sprintf("set password for user %s", n.User)
}

// Accept implements Node Accept interface.
func (n *SetPwdStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*SetPwdStmt)
	return v.Leave(n)
}

type ChangeStmt struct {
	stmtNode

	NodeType string
	State    string
	NodeID   string
}

func (n *ChangeStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "CHANGE " + n.NodeType + " TO NODE_STATE = " + n.State + " FOR NODE_ID " + n.NodeID

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeChangeStmt
	return rootNode

}

// Restore implements Node interface.
func (n *ChangeStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("CHANGE ")
	ctx.WriteKeyWord(n.NodeType)
	ctx.WriteKeyWord(" TO NODE_STATE ")
	ctx.WritePlain("=")
	ctx.WriteString(n.State)
	ctx.WriteKeyWord(" FOR NODE_ID ")
	ctx.WriteString(n.NodeID)
	return nil
}

// SecureText implements SensitiveStatement interface.
func (n *ChangeStmt) SecureText() string {
	return fmt.Sprintf("change %s to node_state='%s' for node_id '%s'", strings.ToLower(n.NodeType), n.State, n.NodeID)
}

// Accept implements Node Accept interface.
func (n *ChangeStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*ChangeStmt)
	return v.Leave(n)
}

// SetRoleStmtType is the type for FLUSH statement.
type SetRoleStmtType int

// SetRole statement types.
const (
	SetRoleDefault SetRoleStmtType = iota
	SetRoleNone
	SetRoleAll
	SetRoleAllExcept
	SetRoleRegular
)

type SetRoleStmt struct {
	stmtNode

	SetRoleOpt SetRoleStmtType
	RoleList   []*auth.RoleIdentity
}

func (n *SetRoleStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "SET ROLE"
	switch n.SetRoleOpt {
	case SetRoleDefault:
		prefix += "SET ROLE DEFAULT "
	case SetRoleNone:
		prefix += " NONE "
	case SetRoleAll:
		prefix += " ALL "
	case SetRoleAllExcept:
		prefix += " ALL EXCEPT "
	}

	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, role := range n.RoleList {
		roleNode := role.LogCurrentNode(depth + 1)

		if i == 0 {
			tmpRootNode.LNode = roleNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    roleNode,
				Infix:    ", ",
				Depth:    depth,
			}
		}
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    tmpRootNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeSetRoleStmt

	return rootNode
}

func (n *SetRoleStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("SET ROLE")
	switch n.SetRoleOpt {
	case SetRoleDefault:
		ctx.WriteKeyWord(" DEFAULT")
	case SetRoleNone:
		ctx.WriteKeyWord(" NONE")
	case SetRoleAll:
		ctx.WriteKeyWord(" ALL")
	case SetRoleAllExcept:
		ctx.WriteKeyWord(" ALL EXCEPT")
	}
	for i, role := range n.RoleList {
		ctx.WritePlain(" ")
		err := role.Restore(ctx)
		if err != nil {
			return errors.Annotate(err, "An error occurred while restore SetRoleStmt.RoleList")
		}
		if i != len(n.RoleList)-1 {
			ctx.WritePlain(",")
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *SetRoleStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*SetRoleStmt)
	return v.Leave(n)
}

type SetDefaultRoleStmt struct {
	stmtNode

	SetRoleOpt SetRoleStmtType
	RoleList   []*auth.RoleIdentity
	UserList   []*auth.UserIdentity
}

func (n *SetDefaultRoleStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "SET DEFAULT ROLE"
	switch n.SetRoleOpt {
	case SetRoleNone:
		prefix += " NONE"
	case SetRoleAll:
		prefix += " ALL"
	default:
	}

	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, role := range n.RoleList {
		midfix := " "
		if i > 0 {
			midfix = ", "
		}
		roleNode := role.LogCurrentNode(depth + 1)

		if i == 0 {
			tmpRootNode.LNode = roleNode
			tmpRootNode.Infix = midfix
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    roleNode,
				Infix:    midfix,
				Depth:    depth,
			}
		}
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    tmpRootNode,
		Prefix:   prefix,
		Depth:    depth,
	}
	prefix = ""

	midfix := " TO"
	tmpRootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, user := range n.UserList {
		tmpMidfix := " "
		if i > 0 {
			tmpMidfix = ", "
		}
		userNode := user.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = userNode
			tmpRootNode.Infix = midfix
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    userNode,
				Infix:    tmpMidfix,
				Depth:    depth,
			}
		}
	}

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Infix:    midfix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeSetDefaultRoleStmt
	return rootNode
}

func (n *SetDefaultRoleStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("SET DEFAULT ROLE")
	switch n.SetRoleOpt {
	case SetRoleNone:
		ctx.WriteKeyWord(" NONE")
	case SetRoleAll:
		ctx.WriteKeyWord(" ALL")
	default:
	}
	for i, role := range n.RoleList {
		ctx.WritePlain(" ")
		err := role.Restore(ctx)
		if err != nil {
			return errors.Annotate(err, "An error occurred while restore SetDefaultRoleStmt.RoleList")
		}
		if i != len(n.RoleList)-1 {
			ctx.WritePlain(",")
		}
	}
	ctx.WritePlain(" TO")
	for i, user := range n.UserList {
		ctx.WritePlain(" ")
		err := user.Restore(ctx)
		if err != nil {
			return errors.Annotate(err, "An error occurred while restore SetDefaultRoleStmt.UserList")
		}
		if i != len(n.UserList)-1 {
			ctx.WritePlain(",")
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *SetDefaultRoleStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*SetDefaultRoleStmt)
	return v.Leave(n)
}

// UserSpec is used for parsing create user statement.
type UserSpec struct {
	User    *auth.UserIdentity
	AuthOpt *AuthOption
	IsRole  bool
}

func (n *UserSpec) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	lNode := n.User.LogCurrentNode(depth + 1)
	midfix := ""
	var rNode *sql_ir.SqlRsgIR

	if n.AuthOpt != nil {
		midfix = " "
		rNode = n.AuthOpt.LogCurrentNode(depth + 1)
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		RNode:    rNode,
		Infix:    midfix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeUserSpec
	return rootNode

}

// Restore implements Node interface.
func (n *UserSpec) Restore(ctx *format.RestoreCtx) error {
	if err := n.User.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore UserSpec.User")
	}
	if n.AuthOpt != nil {
		ctx.WritePlain(" ")
		if err := n.AuthOpt.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore UserSpec.AuthOpt")
		}
	}
	return nil
}

// SecurityString formats the UserSpec without password information.
func (n *UserSpec) SecurityString() string {
	withPassword := false
	if opt := n.AuthOpt; opt != nil {
		if len(opt.AuthString) > 0 || len(opt.HashString) > 0 {
			withPassword = true
		}
	}
	if withPassword {
		return fmt.Sprintf("{%s password = ***}", n.User)
	}
	return n.User.String()
}

// EncodedPassword returns the encoded password (which is the real data mysql.user).
// The boolean value indicates input's password format is legal or not.
func (n *UserSpec) EncodedPassword() (string, bool) {
	if n.AuthOpt == nil {
		return "", true
	}

	opt := n.AuthOpt
	if opt.ByAuthString {
		switch opt.AuthPlugin {
		case mysql.AuthCachingSha2Password:
			return auth.NewSha2Password(opt.AuthString), true
		case mysql.AuthSocket:
			return "", true
		default:
			return auth.EncodePassword(opt.AuthString), true
		}
	}

	// In case we have 'IDENTIFIED WITH <plugin>' but no 'BY <password>' to set an empty password.
	if opt.HashString == "" {
		return opt.HashString, true
	}

	// Not a legal password string.
	switch opt.AuthPlugin {
	case mysql.AuthCachingSha2Password:
		if len(opt.HashString) != mysql.SHAPWDHashLen {
			return "", false
		}
	case "", mysql.AuthNativePassword:
		if len(opt.HashString) != (mysql.PWDHashLen+1) || !strings.HasPrefix(opt.HashString, "*") {
			return "", false
		}
	case mysql.AuthSocket:
	default:
		return "", false
	}
	return opt.HashString, true
}

const (
	TlsNone = iota
	Ssl
	X509
	Cipher
	Issuer
	Subject
	SAN
)

type TLSOption struct {
	Type  int
	Value string
}

func (n *TLSOption) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := ""
	switch n.Type {
	case TlsNone:
		prefix += "NONE"
	case Ssl:
		prefix += "SSL"
	case X509:
		prefix += "X509"
	case Cipher:
		prefix += "CIPHER " + n.Value
	case Issuer:
		prefix += "ISSUER " + n.Value
	case Subject:
		prefix += "SUBJECT " + n.Value
	case SAN:
		prefix += "SAN " + n.Value
	default:
		break
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeTLSOption
	return rootNode

}

func (t *TLSOption) Restore(ctx *format.RestoreCtx) error {
	switch t.Type {
	case TlsNone:
		ctx.WriteKeyWord("NONE")
	case Ssl:
		ctx.WriteKeyWord("SSL")
	case X509:
		ctx.WriteKeyWord("X509")
	case Cipher:
		ctx.WriteKeyWord("CIPHER ")
		ctx.WriteString(t.Value)
	case Issuer:
		ctx.WriteKeyWord("ISSUER ")
		ctx.WriteString(t.Value)
	case Subject:
		ctx.WriteKeyWord("SUBJECT ")
		ctx.WriteString(t.Value)
	case SAN:
		ctx.WriteKeyWord("SAN ")
		ctx.WriteString(t.Value)
	default:
		return errors.Errorf("Unsupported TLSOption.Type %d", t.Type)
	}
	return nil
}

const (
	MaxQueriesPerHour = iota + 1
	MaxUpdatesPerHour
	MaxConnectionsPerHour
	MaxUserConnections
)

type ResourceOption struct {
	Type  int
	Count int64
}

func (n *ResourceOption) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := ""
	switch n.Type {
	case MaxQueriesPerHour:
		prefix += "MAX_QUERIES_PER_HOUR "
	case MaxUpdatesPerHour:
		prefix += "MAX_UPDATES_PER_HOUR  "
	case MaxConnectionsPerHour:
		prefix += "MAX_CONNECTIONS_PER_HOUR "
	case MaxUserConnections:
		prefix += "MAX_USER_CONNECTIONS "
	default:
		break
	}
	lNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		IValue:   int64(n.Count),
		Str:      strconv.FormatInt(int64(n.Count), 10),
		Depth:    depth,
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeResourceOption
	return rootNode
}

func (r *ResourceOption) Restore(ctx *format.RestoreCtx) error {
	switch r.Type {
	case MaxQueriesPerHour:
		ctx.WriteKeyWord("MAX_QUERIES_PER_HOUR ")
	case MaxUpdatesPerHour:
		ctx.WriteKeyWord("MAX_UPDATES_PER_HOUR ")
	case MaxConnectionsPerHour:
		ctx.WriteKeyWord("MAX_CONNECTIONS_PER_HOUR ")
	case MaxUserConnections:
		ctx.WriteKeyWord("MAX_USER_CONNECTIONS ")
	default:
		return errors.Errorf("Unsupported ResourceOption.Type %d", r.Type)
	}
	ctx.WritePlainf("%d", r.Count)
	return nil
}

const (
	PasswordExpire = iota + 1
	PasswordExpireDefault
	PasswordExpireNever
	PasswordExpireInterval
	Lock
	Unlock
)

type PasswordOrLockOption struct {
	Type  int
	Count int64
}

func (n *PasswordOrLockOption) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := ""
	midfix := ""
	var lNode *sql_ir.SqlRsgIR
	switch n.Type {
	case PasswordExpire:
		prefix += "PASSWORD EXPIRE "
	case PasswordExpireDefault:
		prefix += "PASSWORD EXPIRE DEFAULT "
	case PasswordExpireNever:
		prefix += "PASSWORD EXPIRE NEVER"
	case PasswordExpireInterval:
		prefix += "PASSWORD EXPIRE INTERVAL"
		lNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			IValue:   int64(n.Count),
			Str:      strconv.FormatInt(int64(n.Count), 10),
			Depth:    depth,
		}
		midfix += " DAY"
	case Lock:
		prefix += "ACCOUNT LOCK"
	case Unlock:
		prefix += "ACCOUNT UNLOCK"
	default:
		break
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Infix:    midfix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypePasswordOrLockOption

	return rootNode

}

func (p *PasswordOrLockOption) Restore(ctx *format.RestoreCtx) error {
	switch p.Type {
	case PasswordExpire:
		ctx.WriteKeyWord("PASSWORD EXPIRE")
	case PasswordExpireDefault:
		ctx.WriteKeyWord("PASSWORD EXPIRE DEFAULT")
	case PasswordExpireNever:
		ctx.WriteKeyWord("PASSWORD EXPIRE NEVER")
	case PasswordExpireInterval:
		ctx.WriteKeyWord("PASSWORD EXPIRE INTERVAL")
		ctx.WritePlainf(" %d", p.Count)
		ctx.WriteKeyWord(" DAY")
	case Lock:
		ctx.WriteKeyWord("ACCOUNT LOCK")
	case Unlock:
		ctx.WriteKeyWord("ACCOUNT UNLOCK")
	default:
		return errors.Errorf("Unsupported PasswordOrLockOption.Type %d", p.Type)
	}
	return nil
}

// CreateUserStmt creates user account.
// See https://dev.mysql.com/doc/refman/5.7/en/create-user.html
type CreateUserStmt struct {
	stmtNode

	IsCreateRole          bool
	IfNotExists           bool
	Specs                 []*UserSpec
	TLSOptions            []*TLSOption
	ResourceOptions       []*ResourceOption
	PasswordOrLockOptions []*PasswordOrLockOption
}

func (n *CreateUserStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := ""
	if n.IsCreateRole {
		prefix += "CREATE ROLE "
	} else {
		prefix += "CREATE USER "
	}
	if n.IfNotExists {
		prefix += "IF NOT EXISTS "
	}

	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, v := range n.Specs {
		midfix := ""
		if i != 0 {
			midfix = ", "
		}
		vNode := v.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = vNode
		} else {
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    vNode,
				Infix:    midfix,
				Depth:    depth,
			}
		}
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    tmpRootNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	midfix := ""
	if len(n.TLSOptions) != 0 {
		midfix = " REQUIRE "
	}

	tmpRootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}

	for i, option := range n.TLSOptions {
		tmpMidfix := ""
		if i != 0 {
			tmpMidfix = " AND "
		}
		optionNode := option.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = optionNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    optionNode,
				Infix:    tmpMidfix,
				Depth:    depth,
			}
		}
	}

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Infix:    midfix,
		Depth:    depth,
	}

	midfix = ""

	if len(n.ResourceOptions) != 0 {
		midfix += " WITH"
	}

	tmpRootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, v := range n.ResourceOptions {
		tmpMidfix := " "
		vNode := v.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = vNode
		} else {
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    vNode,
				Infix:    tmpMidfix,
				Depth:    depth,
			}
		}
	}
	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Infix:    midfix,
		Depth:    depth,
	}

	tmpRootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, v := range n.PasswordOrLockOptions {
		midfix = " "
		vNode := v.LogCurrentNode(depth + 1)

		if i == 0 {
			tmpRootNode.LNode = vNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    vNode,
				Infix:    midfix,
				Depth:    depth,
			}
		}
	}

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Infix:    " ",
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeCreateUserStmt

	return rootNode

}

// Restore implements Node interface.
func (n *CreateUserStmt) Restore(ctx *format.RestoreCtx) error {
	if n.IsCreateRole {
		ctx.WriteKeyWord("CREATE ROLE ")
	} else {
		ctx.WriteKeyWord("CREATE USER ")
	}
	if n.IfNotExists {
		ctx.WriteKeyWord("IF NOT EXISTS ")
	}
	for i, v := range n.Specs {
		if i != 0 {
			ctx.WritePlain(", ")
		}
		if err := v.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore CreateUserStmt.Specs[%d]", i)
		}
	}

	if len(n.TLSOptions) != 0 {
		ctx.WriteKeyWord(" REQUIRE ")
	}

	for i, option := range n.TLSOptions {
		if i != 0 {
			ctx.WriteKeyWord(" AND ")
		}
		if err := option.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore CreateUserStmt.TLSOptions[%d]", i)
		}
	}

	if len(n.ResourceOptions) != 0 {
		ctx.WriteKeyWord(" WITH")
	}

	for i, v := range n.ResourceOptions {
		ctx.WritePlain(" ")
		if err := v.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore CreateUserStmt.ResourceOptions[%d]", i)
		}
	}

	for i, v := range n.PasswordOrLockOptions {
		ctx.WritePlain(" ")
		if err := v.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore CreateUserStmt.PasswordOrLockOptions[%d]", i)
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *CreateUserStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*CreateUserStmt)
	return v.Leave(n)
}

// SecureText implements SensitiveStatement interface.
func (n *CreateUserStmt) SecureText() string {
	var buf bytes.Buffer
	buf.WriteString("create user")
	for _, user := range n.Specs {
		buf.WriteString(" ")
		buf.WriteString(user.SecurityString())
	}
	return buf.String()
}

// AlterUserStmt modifies user account.
// See https://dev.mysql.com/doc/refman/5.7/en/alter-user.html
type AlterUserStmt struct {
	stmtNode

	IfExists              bool
	CurrentAuth           *AuthOption
	Specs                 []*UserSpec
	TLSOptions            []*TLSOption
	ResourceOptions       []*ResourceOption
	PasswordOrLockOptions []*PasswordOrLockOption
}

func (n *AlterUserStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "ALTER USER "
	if n.IfExists {
		prefix += "IF EXISTS "
	}
	var lNode *sql_ir.SqlRsgIR = nil
	if n.CurrentAuth != nil {
		prefix += "USER() "
		lNode = n.CurrentAuth.LogCurrentNode(depth + 1)
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, v := range n.Specs {
		midfix := ""
		if i != 0 {
			midfix = ", "
		}
		vNode := v.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = vNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    vNode,
				Infix:    midfix,
				Depth:    depth,
			}
		}
	}

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Depth:    depth,
	}

	midfix := ""
	if len(n.TLSOptions) != 0 {
		midfix += " REQUIRE "
	}

	tmpRootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, option := range n.TLSOptions {
		tmpMidfix := ""
		if i != 0 {
			tmpMidfix += " AND "
		}
		optionNode := option.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = optionNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    optionNode,
				Infix:    tmpMidfix,
				Depth:    depth,
			}
		}
	}

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Infix:    midfix,
		Depth:    depth,
	}

	midfix = ""
	if len(n.ResourceOptions) != 0 {
		midfix += " WITH"
	}

	tmpRootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, v := range n.ResourceOptions {
		tmpMidfix := " "
		vNode := v.LogCurrentNode(depth + 1)

		if i == 0 {
			tmpRootNode.LNode = vNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    vNode,
				Infix:    tmpMidfix,
				Depth:    depth,
			}
		}
	}

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Infix:    midfix,
		Depth:    depth,
	}

	tmpRootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, v := range n.PasswordOrLockOptions {
		tmpMidfix := " "
		vNode := v.LogCurrentNode(depth + 1)

		if i == 0 {
			tmpRootNode.LNode = vNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    vNode,
				Infix:    tmpMidfix,
				Depth:    depth,
			}
		}
	}

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeAlterUserStmt

	return rootNode

}

// Restore implements Node interface.
func (n *AlterUserStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("ALTER USER ")
	if n.IfExists {
		ctx.WriteKeyWord("IF EXISTS ")
	}
	if n.CurrentAuth != nil {
		ctx.WriteKeyWord("USER")
		ctx.WritePlain("() ")
		if err := n.CurrentAuth.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore AlterUserStmt.CurrentAuth")
		}
	}
	for i, v := range n.Specs {
		if i != 0 {
			ctx.WritePlain(", ")
		}
		if err := v.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore AlterUserStmt.Specs[%d]", i)
		}
	}

	if len(n.TLSOptions) != 0 {
		ctx.WriteKeyWord(" REQUIRE ")
	}

	for i, option := range n.TLSOptions {
		if i != 0 {
			ctx.WriteKeyWord(" AND ")
		}
		if err := option.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore AlterUserStmt.TLSOptions[%d]", i)
		}
	}

	if len(n.ResourceOptions) != 0 {
		ctx.WriteKeyWord(" WITH")
	}

	for i, v := range n.ResourceOptions {
		ctx.WritePlain(" ")
		if err := v.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore AlterUserStmt.ResourceOptions[%d]", i)
		}
	}

	for i, v := range n.PasswordOrLockOptions {
		ctx.WritePlain(" ")
		if err := v.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore AlterUserStmt.PasswordOrLockOptions[%d]", i)
		}
	}
	return nil
}

// SecureText implements SensitiveStatement interface.
func (n *AlterUserStmt) SecureText() string {
	var buf bytes.Buffer
	buf.WriteString("alter user")
	for _, user := range n.Specs {
		buf.WriteString(" ")
		buf.WriteString(user.SecurityString())
	}
	return buf.String()
}

// Accept implements Node Accept interface.
func (n *AlterUserStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*AlterUserStmt)
	return v.Leave(n)
}

// AlterInstanceStmt modifies instance.
// See https://dev.mysql.com/doc/refman/8.0/en/alter-instance.html
type AlterInstanceStmt struct {
	stmtNode

	ReloadTLS         bool
	NoRollbackOnError bool
}

func (n *AlterInstanceStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "ALTER INSTANCE"

	if n.ReloadTLS {
		prefix += " RELOAD TLS"
	}

	if n.NoRollbackOnError {
		prefix += " NO ROLLBACK ON ERROR"
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeAlterInstanceStmt

	return rootNode

}

// Restore implements Node interface.
func (n *AlterInstanceStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("ALTER INSTANCE")
	if n.ReloadTLS {
		ctx.WriteKeyWord(" RELOAD TLS")
	}
	if n.NoRollbackOnError {
		ctx.WriteKeyWord(" NO ROLLBACK ON ERROR")
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *AlterInstanceStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*AlterInstanceStmt)
	return v.Leave(n)
}

// DropUserStmt creates user account.
// See http://dev.mysql.com/doc/refman/5.7/en/drop-user.html
type DropUserStmt struct {
	stmtNode

	IfExists   bool
	IsDropRole bool
	UserList   []*auth.UserIdentity
}

func (n *DropUserStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := ""
	if n.IsDropRole {
		prefix += "DROP ROLE "
	} else {
		prefix += "DROP USER "
	}
	if n.IfExists {
		prefix += "IF EXISTS "
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}

	for i, v := range n.UserList {
		midfix := ""
		if i != 0 {
			midfix = ", "
		}
		vNode := v.LogCurrentNode(depth + 1)

		if i == 0 {
			rootNode.LNode = vNode
		} else { // i > 0
			rootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    rootNode,
				RNode:    vNode,
				Infix:    midfix,
				Depth:    depth,
			}
		}
	}

	rootNode.Prefix = prefix

	rootNode.IRType = sql_ir.TypeDropUserStmt
	return rootNode

}

// Restore implements Node interface.
func (n *DropUserStmt) Restore(ctx *format.RestoreCtx) error {
	if n.IsDropRole {
		ctx.WriteKeyWord("DROP ROLE ")
	} else {
		ctx.WriteKeyWord("DROP USER ")
	}
	if n.IfExists {
		ctx.WriteKeyWord("IF EXISTS ")
	}
	for i, v := range n.UserList {
		if i != 0 {
			ctx.WritePlain(", ")
		}
		if err := v.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore DropUserStmt.UserList[%d]", i)
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *DropUserStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*DropUserStmt)
	return v.Leave(n)
}

// CreateBindingStmt creates sql binding hint.
type CreateBindingStmt struct {
	stmtNode

	GlobalScope bool
	OriginNode  StmtNode
	HintedNode  StmtNode
}

func (n *CreateBindingStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "CREATE "
	if n.GlobalScope {
		prefix += "GLOBAL "
	} else {
		prefix += "SESSION "
	}
	prefix += "BINDING FOR "
	lNode := n.OriginNode.LogCurrentNode(depth + 1)
	midfix := " USING "
	rNode := n.HintedNode.LogCurrentNode(depth + 1)

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		RNode:    rNode,
		Prefix:   prefix,
		Infix:    midfix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeCreateBindingStmt
	return rootNode

}

func (n *CreateBindingStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("CREATE ")
	if n.GlobalScope {
		ctx.WriteKeyWord("GLOBAL ")
	} else {
		ctx.WriteKeyWord("SESSION ")
	}
	ctx.WriteKeyWord("BINDING FOR ")
	if err := n.OriginNode.Restore(ctx); err != nil {
		return errors.Trace(err)
	}
	ctx.WriteKeyWord(" USING ")
	if err := n.HintedNode.Restore(ctx); err != nil {
		return errors.Trace(err)
	}
	return nil
}

func (n *CreateBindingStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*CreateBindingStmt)
	origNode, ok := n.OriginNode.Accept(v)
	if !ok {
		return n, false
	}
	n.OriginNode = origNode.(StmtNode)
	hintedNode, ok := n.HintedNode.Accept(v)
	if !ok {
		return n, false
	}
	n.HintedNode = hintedNode.(StmtNode)
	return v.Leave(n)
}

// DropBindingStmt deletes sql binding hint.
type DropBindingStmt struct {
	stmtNode

	GlobalScope bool
	OriginNode  StmtNode
	HintedNode  StmtNode
}

func (n *DropBindingStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "DROP "
	if n.GlobalScope {
		prefix += "GLOBAL "
	} else {
		prefix += "SESSION "
	}
	prefix += "BINDING FOR "
	lNode := n.OriginNode.LogCurrentNode(depth + 1)
	midfix := ""
	var rNode *sql_ir.SqlRsgIR = nil
	if n.HintedNode != nil {
		midfix = " USING "
		rNode = n.HintedNode.LogCurrentNode(depth + 1)
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		RNode:    rNode,
		Prefix:   prefix,
		Infix:    midfix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeDropBindingStmt

	return rootNode

}

func (n *DropBindingStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("DROP ")
	if n.GlobalScope {
		ctx.WriteKeyWord("GLOBAL ")
	} else {
		ctx.WriteKeyWord("SESSION ")
	}
	ctx.WriteKeyWord("BINDING FOR ")
	if err := n.OriginNode.Restore(ctx); err != nil {
		return errors.Trace(err)
	}
	if n.HintedNode != nil {
		ctx.WriteKeyWord(" USING ")
		if err := n.HintedNode.Restore(ctx); err != nil {
			return errors.Trace(err)
		}
	}
	return nil
}

func (n *DropBindingStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*DropBindingStmt)
	origNode, ok := n.OriginNode.Accept(v)
	if !ok {
		return n, false
	}
	n.OriginNode = origNode.(StmtNode)
	if n.HintedNode != nil {
		hintedNode, ok := n.HintedNode.Accept(v)
		if !ok {
			return n, false
		}
		n.HintedNode = hintedNode.(StmtNode)
	}
	return v.Leave(n)
}

// BindingStatusType defines the status type for the binding
type BindingStatusType int8

// Binding status types.
const (
	BindingStatusTypeEnabled BindingStatusType = iota
	BindingStatusTypeDisabled
)

// SetBindingStmt sets sql binding status.
type SetBindingStmt struct {
	stmtNode

	BindingStatusType BindingStatusType
	OriginNode        StmtNode
	HintedNode        StmtNode
}

func (n *SetBindingStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "SET BINDING "
	switch n.BindingStatusType {
	case BindingStatusTypeEnabled:
		prefix += "ENABLED "
	case BindingStatusTypeDisabled:
		prefix += "DISABLED "
	}
	prefix += "FOR "
	lNode := n.OriginNode.LogCurrentNode(depth + 1)
	midfix := ""
	var rNode *sql_ir.SqlRsgIR = nil
	if n.HintedNode != nil {
		midfix = " USING "
		rNode = n.HintedNode.LogCurrentNode(depth + 1)
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		RNode:    rNode,
		Prefix:   prefix,
		Infix:    midfix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeSetBindingStmt

	return rootNode
}

func (n *SetBindingStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("SET ")
	ctx.WriteKeyWord("BINDING ")
	switch n.BindingStatusType {
	case BindingStatusTypeEnabled:
		ctx.WriteKeyWord("ENABLED ")
	case BindingStatusTypeDisabled:
		ctx.WriteKeyWord("DISABLED ")
	}
	ctx.WriteKeyWord("FOR ")
	if err := n.OriginNode.Restore(ctx); err != nil {
		return errors.Trace(err)
	}
	if n.HintedNode != nil {
		ctx.WriteKeyWord(" USING ")
		if err := n.HintedNode.Restore(ctx); err != nil {
			return errors.Trace(err)
		}
	}
	return nil
}

func (n *SetBindingStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*SetBindingStmt)
	origNode, ok := n.OriginNode.Accept(v)
	if !ok {
		return n, false
	}
	n.OriginNode = origNode.(StmtNode)
	if n.HintedNode != nil {
		hintedNode, ok := n.HintedNode.Accept(v)
		if !ok {
			return n, false
		}
		n.HintedNode = hintedNode.(StmtNode)
	}
	return v.Leave(n)
}

// Extended statistics types.
const (
	StatsTypeCardinality uint8 = iota
	StatsTypeDependency
	StatsTypeCorrelation
)

// StatisticsSpec is the specification for ADD /DROP STATISTICS.
type StatisticsSpec struct {
	StatsName string
	StatsType uint8
	Columns   []*ColumnName
}

// CreateStatisticsStmt is a statement to create extended statistics.
// Examples:
//
//	CREATE STATISTICS stats1 (cardinality) ON t(a, b, c);
//	CREATE STATISTICS stats2 (dependency) ON t(a, b);
//	CREATE STATISTICS stats3 (correlation) ON t(a, b);
type CreateStatisticsStmt struct {
	stmtNode

	IfNotExists bool
	StatsName   string
	StatsType   uint8
	Table       *TableName
	Columns     []*ColumnName
}

func (n *CreateStatisticsStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "CREATE STATISTICS "
	if n.IfNotExists {
		prefix += "IF NOT EXISTS "
	}
	nameNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataStatsName,
		ContextFlag: sql_ir.ContextDefine,
		Str:         n.StatsName,
		Depth:       depth,
	}

	midfix := ""
	switch n.StatsType {
	case StatsTypeCardinality:
		midfix += " (cardinality) "
	case StatsTypeDependency:
		midfix += " (dependency) "
	case StatsTypeCorrelation:
		midfix += " (correlation) "
	}
	midfix += "ON "

	rNode := n.Table.LogCurrentNode(depth + 1)
	tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(rNode, sql_ir.DataTableName)
	for _, tableNameNode := range tableNameNodeList {
		tableNameNode.DataType = sql_ir.DataTableName
		tableNameNode.ContextFlag = sql_ir.ContextUse
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    nameNode,
		RNode:    rNode,
		Prefix:   prefix,
		Infix:    midfix,
		Depth:    depth,
	}

	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, col := range n.Columns {
		tmpMidfix := ""
		if i != 0 {
			tmpMidfix = ", "
		}
		colNode := col.LogCurrentNode(depth + 1)

		columnNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(colNode, sql_ir.DataColumnName)
		for _, columnNameNode := range columnNameNodeList {
			columnNameNode.DataType = sql_ir.DataColumnName
			columnNameNode.ContextFlag = sql_ir.ContextUse
		}

		if i == 0 {
			tmpRootNode.LNode = colNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    colNode,
				Infix:    tmpMidfix,
				Depth:    depth,
			}
		}
	}

	tmpRootNode.Prefix = "("
	tmpRootNode.Suffix = ")"

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeCreateStatisticsStmt

	return rootNode
}

// Restore implements Node interface.
func (n *CreateStatisticsStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("CREATE STATISTICS ")
	if n.IfNotExists {
		ctx.WriteKeyWord("IF NOT EXISTS ")
	}
	ctx.WriteName(n.StatsName)
	switch n.StatsType {
	case StatsTypeCardinality:
		ctx.WriteKeyWord(" (cardinality) ")
	case StatsTypeDependency:
		ctx.WriteKeyWord(" (dependency) ")
	case StatsTypeCorrelation:
		ctx.WriteKeyWord(" (correlation) ")
	}
	ctx.WriteKeyWord("ON ")
	if err := n.Table.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore CreateStatisticsStmt.Table")
	}

	ctx.WritePlain("(")
	for i, col := range n.Columns {
		if i != 0 {
			ctx.WritePlain(", ")
		}
		if err := col.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore CreateStatisticsStmt.Columns: [%v]", i)
		}
	}
	ctx.WritePlain(")")
	return nil
}

// Accept implements Node Accept interface.
func (n *CreateStatisticsStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*CreateStatisticsStmt)
	node, ok := n.Table.Accept(v)
	if !ok {
		return n, false
	}
	n.Table = node.(*TableName)
	for i, col := range n.Columns {
		node, ok = col.Accept(v)
		if !ok {
			return n, false
		}
		n.Columns[i] = node.(*ColumnName)
	}
	return v.Leave(n)
}

// DropStatisticsStmt is a statement to drop extended statistics.
// Examples:
//
//	DROP STATISTICS stats1;
type DropStatisticsStmt struct {
	stmtNode

	StatsName string
}

func (n *DropStatisticsStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "DROP STATISTICS "
	statNameNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataStatsName,
		ContextFlag: sql_ir.ContextUndefine,
		Str:         n.StatsName,
		Depth:       depth,
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    statNameNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeDropStatisticsStmt

	return rootNode

}

// Restore implements Node interface.
func (n *DropStatisticsStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("DROP STATISTICS ")
	ctx.WriteName(n.StatsName)
	return nil
}

// Accept implements Node Accept interface.
func (n *DropStatisticsStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*DropStatisticsStmt)
	return v.Leave(n)
}

// DoStmt is the struct for DO statement.
type DoStmt struct {
	stmtNode

	Exprs []ExprNode
}

func (n *DoStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "DO "
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, v := range n.Exprs {
		midfix := ""
		if i != 0 {
			midfix = ", "
		}
		vNode := v.LogCurrentNode(depth + 1)
		if i == 0 {
			rootNode.LNode = vNode
		} else { // i > 0
			rootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    rootNode,
				RNode:    vNode,
				Infix:    midfix,
				Depth:    depth,
			}
		}
	}

	rootNode.Prefix = prefix
	rootNode.IRType = sql_ir.TypeDoStmt

	return rootNode

}

// Restore implements Node interface.
func (n *DoStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("DO ")
	for i, v := range n.Exprs {
		if i != 0 {
			ctx.WritePlain(", ")
		}
		if err := v.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore DoStmt.Exprs[%d]", i)
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *DoStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*DoStmt)
	for i, val := range n.Exprs {
		node, ok := val.Accept(v)
		if !ok {
			return n, false
		}
		n.Exprs[i] = node.(ExprNode)
	}
	return v.Leave(n)
}

// AdminStmtType is the type for admin statement.
type AdminStmtType int

// Admin statement types.
const (
	AdminShowDDL = iota + 1
	AdminCheckTable
	AdminShowDDLJobs
	AdminCancelDDLJobs
	AdminCheckIndex
	AdminRecoverIndex
	AdminCleanupIndex
	AdminCheckIndexRange
	AdminShowDDLJobQueries
	AdminChecksumTable
	AdminShowSlow
	AdminShowNextRowID
	AdminReloadExprPushdownBlacklist
	AdminReloadOptRuleBlacklist
	AdminPluginDisable
	AdminPluginEnable
	AdminFlushBindings
	AdminCaptureBindings
	AdminEvolveBindings
	AdminReloadBindings
	AdminShowTelemetry
	AdminResetTelemetryID
	AdminReloadStatistics
	AdminFlushPlanCache
)

// HandleRange represents a range where handle value >= Begin and < End.
type HandleRange struct {
	Begin int64
	End   int64
}

type StatementScope int

const (
	StatementScopeNone StatementScope = iota
	StatementScopeSession
	StatementScopeInstance
	StatementScopeGlobal
)

// ShowSlowType defines the type for SlowSlow statement.
type ShowSlowType int

const (
	// ShowSlowTop is a ShowSlowType constant.
	ShowSlowTop ShowSlowType = iota
	// ShowSlowRecent is a ShowSlowType constant.
	ShowSlowRecent
)

// ShowSlowKind defines the kind for SlowSlow statement when the type is ShowSlowTop.
type ShowSlowKind int

const (
	// ShowSlowKindDefault is a ShowSlowKind constant.
	ShowSlowKindDefault ShowSlowKind = iota
	// ShowSlowKindInternal is a ShowSlowKind constant.
	ShowSlowKindInternal
	// ShowSlowKindAll is a ShowSlowKind constant.
	ShowSlowKindAll
)

// ShowSlow is used for the following command:
//
//	admin show slow top [ internal | all] N
//	admin show slow recent N
type ShowSlow struct {
	Tp    ShowSlowType
	Count uint64
	Kind  ShowSlowKind
}

func (n *ShowSlow) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := ""
	switch n.Tp {
	case ShowSlowRecent:
		prefix += "RECENT "
	case ShowSlowTop:
		prefix += "TOP "
		switch n.Kind {
		case ShowSlowKindDefault:
			// do nothing
		case ShowSlowKindInternal:
			prefix += "INTERNAL "
		case ShowSlowKindAll:
			prefix += "ALL "
		default:
			break
		}
	default:
		break
	}
	lNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		IValue:   int64(n.Count),
		Str:      strconv.FormatInt(int64(n.Count), 10),
		Depth:    depth,
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeShowSlow
	return rootNode
}

// Restore implements Node interface.
func (n *ShowSlow) Restore(ctx *format.RestoreCtx) error {
	switch n.Tp {
	case ShowSlowRecent:
		ctx.WriteKeyWord("RECENT ")
	case ShowSlowTop:
		ctx.WriteKeyWord("TOP ")
		switch n.Kind {
		case ShowSlowKindDefault:
			// do nothing
		case ShowSlowKindInternal:
			ctx.WriteKeyWord("INTERNAL ")
		case ShowSlowKindAll:
			ctx.WriteKeyWord("ALL ")
		default:
			return errors.New("Unsupported kind of ShowSlowTop")
		}
	default:
		return errors.New("Unsupported type of ShowSlow")
	}
	ctx.WritePlainf("%d", n.Count)
	return nil
}

// AdminStmt is the struct for Admin statement.
type AdminStmt struct {
	stmtNode

	Tp        AdminStmtType
	Index     string
	Tables    []*TableName
	JobIDs    []int64
	JobNumber int64

	HandleRanges   []HandleRange
	ShowSlow       *ShowSlow
	Plugins        []string
	Where          ExprNode
	StatementScope StatementScope
}

func (n *AdminStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	restoreTables := func() *sql_ir.SqlRsgIR {
		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for i, v := range n.Tables {
			midfix := ""
			if i != 0 {
				midfix = ", "
			}
			vNode := v.LogCurrentNode(depth + 1)
			tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(vNode, sql_ir.DataTableName)
			for _, tableNameNode := range tableNameNodeList {
				tableNameNode.DataType = sql_ir.DataTableName
				tableNameNode.ContextFlag = sql_ir.ContextUse
			}

			if i == 0 {
				tmpRootNode.LNode = vNode
			} else {
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    vNode,
					Infix:    midfix,
					Depth:    depth,
				}
			}
		}

		return tmpRootNode
	}

	restoreJobIDs := func() *sql_ir.SqlRsgIR {
		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}

		for i, v := range n.JobIDs {
			midfix := ""
			if i != 0 {
				midfix = ", "
			}
			vNode := &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				IValue:   v,
				Str:      strconv.FormatInt(v, 10),
				Depth:    depth,
			}
			if i == 0 {
				tmpRootNode.LNode = vNode
			} else {
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    vNode,
					Infix:    midfix,
					Depth:    depth,
				}
			}
		}

		return tmpRootNode
	}

	prefix := "ADMIN "
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}

	switch n.Tp {
	case AdminShowDDL:
		prefix += "SHOW DDL"
		rootNode.Prefix = prefix
		prefix = ""
	case AdminShowDDLJobs:
		prefix += "SHOW DDL JOBS"
		var lNode *sql_ir.SqlRsgIR = nil
		if n.JobNumber != 0 {
			lNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				IValue:   n.JobNumber,
				Str:      strconv.FormatInt(n.JobNumber, 10),
				Depth:    depth,
			}
		}
		midfix := ""
		var rNode *sql_ir.SqlRsgIR = nil
		if n.Where != nil {
			midfix = " WHERE "
			rNode = n.Where.LogCurrentNode(depth + 1)
		}

		rootNode.Prefix = prefix
		rootNode.LNode = lNode

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Infix:    midfix,
			Depth:    depth,
		}

	case AdminShowNextRowID:
		prefix += "SHOW "
		lNode := restoreTables()
		midfix := " NEXT_ROW_ID "
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
		rootNode.Infix = midfix

	case AdminCheckTable:
		prefix += "CHECK TABLE "
		lNode := restoreTables()
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case AdminCheckIndex:
		prefix += "CHECK INDEX "
		lNode := restoreTables()
		rNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataIndexName,
			ContextFlag: sql_ir.ContextDefine,
			Str:         n.Index,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.Infix = " "
		rootNode.LNode = lNode
		rootNode.RNode = rNode

	case AdminRecoverIndex:
		prefix += "RECOVER INDEX "
		lNode := restoreTables()
		rNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataIndexName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.Index,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.Infix = " "
		rootNode.LNode = lNode
		rootNode.RNode = rNode

	case AdminCleanupIndex:
		prefix += "CLEANUP INDEX "
		lNode := restoreTables()
		rNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataIndexName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.Index,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.Infix = " "
		rootNode.LNode = lNode
		rootNode.RNode = rNode

	case AdminCheckIndexRange:
		prefix := "CHECK INDEX "
		lNode := restoreTables()
		rNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataIndexName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.Index,
			Depth:       depth,
		}

		rootNode.Prefix = prefix
		rootNode.Infix = " "
		rootNode.LNode = lNode
		rootNode.RNode = rNode

		midfix := ""
		if n.HandleRanges != nil {
			midfix = " "
			tmpRootNode := &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				Depth:    depth,
			}
			for i, v := range n.HandleRanges {
				if i != 0 {
					midfix = ", "
				}
				tmpLNode := &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeIntegerLiteral,
					DataType: sql_ir.DataNone,
					IValue:   v.Begin,
					Str:      strconv.FormatInt(v.Begin, 10),
					Depth:    depth,
				}
				tmpRNode := &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeIntegerLiteral,
					DataType: sql_ir.DataNone,
					IValue:   v.End,
					Str:      strconv.FormatInt(v.End, 10),
					Depth:    depth,
				}

				tmptmpRootNode := &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpLNode,
					RNode:    tmpRNode,
					Infix:    ",",
					Depth:    depth,
				}

				if i == 0 {
					tmpRootNode.LNode = tmptmpRootNode
				} else {
					tmpRootNode = &sql_ir.SqlRsgIR{
						IRType:   sql_ir.TypeUnknown,
						DataType: sql_ir.DataNone,
						LNode:    tmpRootNode,
						RNode:    tmptmpRootNode,
						Infix:    midfix,
						Depth:    depth,
					}
				}
			}
			rootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    rootNode,
				RNode:    tmpRootNode,
				Infix:    " ",
				Depth:    depth,
			}
		}
		prefix = ""
	case AdminChecksumTable:
		prefix = "CHECKSUM TABLE "
		lNode := restoreTables()
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
		prefix = ""

	case AdminCancelDDLJobs:
		prefix += "CANCEL DDL JOBS "
		lNode := restoreJobIDs()
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
		prefix = ""
	case AdminShowDDLJobQueries:
		prefix += "SHOW DDL JOB QUERIES "
		lNode := restoreJobIDs()
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
		prefix = ""
	case AdminShowSlow:
		prefix += "SHOW SLOW "
		lNode := n.ShowSlow.LogCurrentNode(depth + 1)
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
		prefix = ""

	case AdminReloadExprPushdownBlacklist:
		prefix += "RELOAD EXPR_PUSHDOWN_BLACKLIST"
		rootNode.Prefix = prefix
		prefix = ""
	case AdminReloadOptRuleBlacklist:
		prefix += "RELOAD OPT_RULE_BLACKLIST"
		rootNode.Prefix = prefix
		prefix = ""
	case AdminPluginEnable:
		prefix += "PLUGINS ENABLE"
		for i, v := range n.Plugins {
			if i == 0 {
				prefix += " "
			} else {
				prefix += ", "
			}
			prefix += v
		}
		rootNode.Prefix = prefix
		prefix = ""

	case AdminPluginDisable:
		prefix += "PLUGINS DISABLE"

		for i, v := range n.Plugins {
			if i == 0 {
				prefix += " "
			} else {
				prefix += ", "
			}
			prefix += v
		}

		rootNode.Prefix = prefix
		prefix = ""
	case AdminFlushBindings:
		prefix += "FLUSH BINDINGS"
		rootNode.Prefix = prefix
		prefix = ""
	case AdminCaptureBindings:
		prefix += "CAPTURE BINDINGS"
		rootNode.Prefix = prefix
		prefix = ""
	case AdminEvolveBindings:
		prefix += "EVOLVE BINDINGS"
		rootNode.Prefix = prefix
		prefix = ""
	case AdminReloadBindings:
		prefix += "RELOAD BINDINGS"
		rootNode.Prefix = prefix
		prefix = ""
	case AdminShowTelemetry:
		prefix += "SHOW TELEMETRY"
		rootNode.Prefix = prefix
		prefix = ""
	case AdminResetTelemetryID:
		prefix += "RESET TELEMETRY_ID"
		rootNode.Prefix = prefix
		prefix = ""
	case AdminReloadStatistics:
		prefix += "RELOAD STATS_EXTENDED"
		rootNode.Prefix = prefix
		prefix = ""
	case AdminFlushPlanCache:
		if n.StatementScope == StatementScopeSession {
			prefix += "FLUSH SESSION PLAN_CACHE"
			rootNode.Prefix = prefix
			prefix = ""
		} else if n.StatementScope == StatementScopeInstance {
			prefix += "FLUSH INSTANCE PLAN_CACHE"
			rootNode.Prefix = prefix
			prefix = ""
		} else if n.StatementScope == StatementScopeGlobal {
			prefix += "FLUSH GLOBAL PLAN_CACHE"
			rootNode.Prefix = prefix
			prefix = ""
		}
	default:
		break
	}
	prefix = ""
	rootNode.IRType = sql_ir.TypeAdminStmt

	return rootNode

}

// Restore implements Node interface.
func (n *AdminStmt) Restore(ctx *format.RestoreCtx) error {
	restoreTables := func() error {
		for i, v := range n.Tables {
			if i != 0 {
				ctx.WritePlain(", ")
			}
			if err := v.Restore(ctx); err != nil {
				return errors.Annotatef(err, "An error occurred while restore AdminStmt.Tables[%d]", i)
			}
		}
		return nil
	}
	restoreJobIDs := func() {
		for i, v := range n.JobIDs {
			if i != 0 {
				ctx.WritePlain(", ")
			}
			ctx.WritePlainf("%d", v)
		}
	}

	ctx.WriteKeyWord("ADMIN ")
	switch n.Tp {
	case AdminShowDDL:
		ctx.WriteKeyWord("SHOW DDL")
	case AdminShowDDLJobs:
		ctx.WriteKeyWord("SHOW DDL JOBS")
		if n.JobNumber != 0 {
			ctx.WritePlainf(" %d", n.JobNumber)
		}
		if n.Where != nil {
			ctx.WriteKeyWord(" WHERE ")
			if err := n.Where.Restore(ctx); err != nil {
				return errors.Annotate(err, "An error occurred while restore ShowStmt.Where")
			}
		}
	case AdminShowNextRowID:
		ctx.WriteKeyWord("SHOW ")
		if err := restoreTables(); err != nil {
			return err
		}
		ctx.WriteKeyWord(" NEXT_ROW_ID")
	case AdminCheckTable:
		ctx.WriteKeyWord("CHECK TABLE ")
		if err := restoreTables(); err != nil {
			return err
		}
	case AdminCheckIndex:
		ctx.WriteKeyWord("CHECK INDEX ")
		if err := restoreTables(); err != nil {
			return err
		}
		ctx.WritePlainf(" %s", n.Index)
	case AdminRecoverIndex:
		ctx.WriteKeyWord("RECOVER INDEX ")
		if err := restoreTables(); err != nil {
			return err
		}
		ctx.WritePlainf(" %s", n.Index)
	case AdminCleanupIndex:
		ctx.WriteKeyWord("CLEANUP INDEX ")
		if err := restoreTables(); err != nil {
			return err
		}
		ctx.WritePlainf(" %s", n.Index)
	case AdminCheckIndexRange:
		ctx.WriteKeyWord("CHECK INDEX ")
		if err := restoreTables(); err != nil {
			return err
		}
		ctx.WritePlainf(" %s", n.Index)
		if n.HandleRanges != nil {
			ctx.WritePlain(" ")
			for i, v := range n.HandleRanges {
				if i != 0 {
					ctx.WritePlain(", ")
				}
				ctx.WritePlainf("(%d,%d)", v.Begin, v.End)
			}
		}
	case AdminChecksumTable:
		ctx.WriteKeyWord("CHECKSUM TABLE ")
		if err := restoreTables(); err != nil {
			return err
		}
	case AdminCancelDDLJobs:
		ctx.WriteKeyWord("CANCEL DDL JOBS ")
		restoreJobIDs()
	case AdminShowDDLJobQueries:
		ctx.WriteKeyWord("SHOW DDL JOB QUERIES ")
		restoreJobIDs()
	case AdminShowSlow:
		ctx.WriteKeyWord("SHOW SLOW ")
		if err := n.ShowSlow.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore AdminStmt.ShowSlow")
		}
	case AdminReloadExprPushdownBlacklist:
		ctx.WriteKeyWord("RELOAD EXPR_PUSHDOWN_BLACKLIST")
	case AdminReloadOptRuleBlacklist:
		ctx.WriteKeyWord("RELOAD OPT_RULE_BLACKLIST")
	case AdminPluginEnable:
		ctx.WriteKeyWord("PLUGINS ENABLE")
		for i, v := range n.Plugins {
			if i == 0 {
				ctx.WritePlain(" ")
			} else {
				ctx.WritePlain(", ")
			}
			ctx.WritePlain(v)
		}
	case AdminPluginDisable:
		ctx.WriteKeyWord("PLUGINS DISABLE")
		for i, v := range n.Plugins {
			if i == 0 {
				ctx.WritePlain(" ")
			} else {
				ctx.WritePlain(", ")
			}
			ctx.WritePlain(v)
		}
	case AdminFlushBindings:
		ctx.WriteKeyWord("FLUSH BINDINGS")
	case AdminCaptureBindings:
		ctx.WriteKeyWord("CAPTURE BINDINGS")
	case AdminEvolveBindings:
		ctx.WriteKeyWord("EVOLVE BINDINGS")
	case AdminReloadBindings:
		ctx.WriteKeyWord("RELOAD BINDINGS")
	case AdminShowTelemetry:
		ctx.WriteKeyWord("SHOW TELEMETRY")
	case AdminResetTelemetryID:
		ctx.WriteKeyWord("RESET TELEMETRY_ID")
	case AdminReloadStatistics:
		ctx.WriteKeyWord("RELOAD STATS_EXTENDED")
	case AdminFlushPlanCache:
		if n.StatementScope == StatementScopeSession {
			ctx.WriteKeyWord("FLUSH SESSION PLAN_CACHE")
		} else if n.StatementScope == StatementScopeInstance {
			ctx.WriteKeyWord("FLUSH INSTANCE PLAN_CACHE")
		} else if n.StatementScope == StatementScopeGlobal {
			ctx.WriteKeyWord("FLUSH GLOBAL PLAN_CACHE")
		}
	default:
		return errors.New("Unsupported AdminStmt type")
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *AdminStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}

	n = newNode.(*AdminStmt)
	for i, val := range n.Tables {
		node, ok := val.Accept(v)
		if !ok {
			return n, false
		}
		n.Tables[i] = node.(*TableName)
	}

	if n.Where != nil {
		node, ok := n.Where.Accept(v)
		if !ok {
			return n, false
		}
		n.Where = node.(ExprNode)
	}

	return v.Leave(n)
}

// RoleOrPriv is a temporary structure to be further processed into auth.RoleIdentity or PrivElem
type RoleOrPriv struct {
	Symbols string      // hold undecided symbols
	Node    interface{} // hold auth.RoleIdentity or PrivElem that can be sure when parsing
}

func (n *RoleOrPriv) ToRole() (*auth.RoleIdentity, error) {
	if n.Node != nil {
		if r, ok := n.Node.(*auth.RoleIdentity); ok {
			return r, nil
		}
		return nil, errors.Errorf("can't convert to RoleIdentity, type %T", n.Node)
	}
	return &auth.RoleIdentity{Username: n.Symbols, Hostname: "%"}, nil
}

func (n *RoleOrPriv) ToPriv() (*PrivElem, error) {
	if n.Node != nil {
		if p, ok := n.Node.(*PrivElem); ok {
			return p, nil
		}
		return nil, errors.Errorf("can't convert to PrivElem, type %T", n.Node)
	}
	if len(n.Symbols) == 0 {
		return nil, errors.New("symbols should not be length 0")
	}
	return &PrivElem{Priv: mysql.ExtendedPriv, Name: n.Symbols}, nil
}

// PrivElem is the privilege type and optional column list.
type PrivElem struct {
	node

	Priv mysql.PrivilegeType
	Cols []*ColumnName
	Name string
}

func (n *PrivElem) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	prefix := ""
	var lNode *sql_ir.SqlRsgIR = nil
	if n.Priv == mysql.AllPriv {
		prefix += "ALL"
		rootNode.Prefix = prefix
		prefix = ""
	} else if n.Priv == mysql.ExtendedPriv {
		lNode = &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataStatementPreparedName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.Name,
			Depth:       depth,
		}
		rootNode.LNode = lNode
	} else {
		str, ok := mysql.Priv2Str[n.Priv]
		if ok {
			prefix += str
			rootNode.Prefix = prefix
			prefix = ""
		} else {
			rootNode.IRType = sql_ir.TypePrivElem
			return rootNode
		}
	}
	if n.Cols != nil {
		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for i, v := range n.Cols {
			tmpMidfix := ""
			if i != 0 {
				tmpMidfix = ","
			}
			vNode := v.LogCurrentNode(depth + 1)
			columnNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(vNode, sql_ir.DataColumnName)
			for _, columnNameNode := range columnNameNodeList {
				columnNameNode.DataType = sql_ir.DataColumnName
				columnNameNode.ContextFlag = sql_ir.ContextUse
			}

			if i == 0 {
				tmpRootNode.LNode = vNode
			} else { // i > 0
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    vNode,
					Infix:    tmpMidfix,
					Depth:    depth,
				}
			}
		}
		tmpRootNode.Prefix = "("
		tmpRootNode.Suffix = ")"

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    tmpRootNode,
			Depth:    depth,
		}
	}

	rootNode.IRType = sql_ir.TypePrivElem

	return rootNode
}

// Restore implements Node interface.
func (n *PrivElem) Restore(ctx *format.RestoreCtx) error {
	if n.Priv == mysql.AllPriv {
		ctx.WriteKeyWord("ALL")
	} else if n.Priv == mysql.ExtendedPriv {
		ctx.WriteKeyWord(n.Name)
	} else {
		str, ok := mysql.Priv2Str[n.Priv]
		if ok {
			ctx.WriteKeyWord(str)
		} else {
			return errors.New("Undefined privilege type")
		}
	}
	if n.Cols != nil {
		ctx.WritePlain(" (")
		for i, v := range n.Cols {
			if i != 0 {
				ctx.WritePlain(",")
			}
			if err := v.Restore(ctx); err != nil {
				return errors.Annotatef(err, "An error occurred while restore PrivElem.Cols[%d]", i)
			}
		}
		ctx.WritePlain(")")
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *PrivElem) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*PrivElem)
	for i, val := range n.Cols {
		node, ok := val.Accept(v)
		if !ok {
			return n, false
		}
		n.Cols[i] = node.(*ColumnName)
	}
	return v.Leave(n)
}

// ObjectTypeType is the type for object type.
type ObjectTypeType int

const (
	// ObjectTypeNone is for empty object type.
	ObjectTypeNone ObjectTypeType = iota + 1
	// ObjectTypeTable means the following object is a table.
	ObjectTypeTable
	// ObjectTypeFunction means the following object is a stored function.
	ObjectTypeFunction
	// ObjectTypeProcedure means the following object is a stored procedure.
	ObjectTypeProcedure
)

func (n *ObjectTypeType) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := ""
	switch *n {
	case ObjectTypeNone:
		break
	case ObjectTypeTable:
		prefix += "TABLE"
	case ObjectTypeFunction:
		prefix += "FUNCTION"
	case ObjectTypeProcedure:
		prefix += "PROCEDURE"
	default:
		break
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeObjectTypeType
	return rootNode

}

// Restore implements Node interface.
func (n ObjectTypeType) Restore(ctx *format.RestoreCtx) error {
	switch n {
	case ObjectTypeNone:
		// do nothing
	case ObjectTypeTable:
		ctx.WriteKeyWord("TABLE")
	case ObjectTypeFunction:
		ctx.WriteKeyWord("FUNCTION")
	case ObjectTypeProcedure:
		ctx.WriteKeyWord("PROCEDURE")
	default:
		return errors.New("Unsupported object type")
	}
	return nil
}

// GrantLevelType is the type for grant level.
type GrantLevelType int

const (
	// GrantLevelNone is the dummy const for default value.
	GrantLevelNone GrantLevelType = iota + 1
	// GrantLevelGlobal means the privileges are administrative or apply to all databases on a given server.
	GrantLevelGlobal
	// GrantLevelDB means the privileges apply to all objects in a given database.
	GrantLevelDB
	// GrantLevelTable means the privileges apply to all columns in a given table.
	GrantLevelTable
)

// GrantLevel is used for store the privilege scope.
type GrantLevel struct {
	Level     GrantLevelType
	DBName    string
	TableName string
}

func (n *GrantLevel) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}

	switch n.Level {
	case GrantLevelDB:
		if n.DBName == "" {
			prefix := "*"
			rootNode.Prefix = prefix
		} else {
			lNode := &sql_ir.SqlRsgIR{
				IRType:      sql_ir.TypeIdentifier,
				DataType:    sql_ir.DataDatabaseName,
				ContextFlag: sql_ir.ContextUse,
				Str:         n.DBName,
				Depth:       depth,
			}
			midfix := ".*"
			rootNode.LNode = lNode
			rootNode.Infix = midfix
		}
	case GrantLevelGlobal:
		prefix := "*.*"
		rootNode.Prefix = prefix
	case GrantLevelTable:
		midfix := ""
		if n.DBName != "" {
			lNode := &sql_ir.SqlRsgIR{
				IRType:      sql_ir.TypeIdentifier,
				DataType:    sql_ir.DataDatabaseName,
				ContextFlag: sql_ir.ContextUse,
				Str:         n.DBName,
				Depth:       depth,
			}
			midfix = "."
			rootNode.LNode = lNode
			rootNode.Infix = midfix
		}
		rNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataTableName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.TableName,
			Depth:       depth,
		}
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Infix:    midfix,
			Depth:    depth,
		}
	}

	rootNode.IRType = sql_ir.TypeGrantLevel
	return rootNode

}

// Restore implements Node interface.
func (n *GrantLevel) Restore(ctx *format.RestoreCtx) error {
	switch n.Level {
	case GrantLevelDB:
		if n.DBName == "" {
			ctx.WritePlain("*")
		} else {
			ctx.WriteName(n.DBName)
			ctx.WritePlain(".*")
		}
	case GrantLevelGlobal:
		ctx.WritePlain("*.*")
	case GrantLevelTable:
		if n.DBName != "" {
			ctx.WriteName(n.DBName)
			ctx.WritePlain(".")
		}
		ctx.WriteName(n.TableName)
	}
	return nil
}

// RevokeStmt is the struct for REVOKE statement.
type RevokeStmt struct {
	stmtNode

	Privs      []*PrivElem
	ObjectType ObjectTypeType
	Level      *GrantLevel
	Users      []*UserSpec
}

func (n *RevokeStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "REVOKE "
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, v := range n.Privs {
		midfix := ""
		if i != 0 {
			midfix = ", "
		}
		vNode := v.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = vNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    vNode,
				Infix:    midfix,
				Depth:    depth,
			}
		}
	}
	rootNode.Prefix = prefix
	rootNode.LNode = tmpRootNode

	midfix := " ON "
	if n.ObjectType != ObjectTypeNone {
		rNode := n.ObjectType.LogCurrentNode(depth + 1)
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Infix:    midfix,
			Depth:    depth,
		}
		midfix = " "
	}

	rNode := n.Level.LogCurrentNode(depth + 1)
	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    rNode,
		Infix:    midfix,
		Depth:    depth,
	}

	midfix = " FROM "
	tmpRootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, v := range n.Users {
		tmpMidfix := ""
		if i != 0 {
			tmpMidfix = ", "
		}
		vNode := v.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = vNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    vNode,
				Infix:    tmpMidfix,
				Depth:    depth,
			}
		}
	}

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Infix:    midfix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeRevokeStmt
	return rootNode
}

// Restore implements Node interface.
func (n *RevokeStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("REVOKE ")
	for i, v := range n.Privs {
		if i != 0 {
			ctx.WritePlain(", ")
		}
		if err := v.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore RevokeStmt.Privs[%d]", i)
		}
	}
	ctx.WriteKeyWord(" ON ")
	if n.ObjectType != ObjectTypeNone {
		if err := n.ObjectType.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore RevokeStmt.ObjectType")
		}
		ctx.WritePlain(" ")
	}
	if err := n.Level.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore RevokeStmt.Level")
	}
	ctx.WriteKeyWord(" FROM ")
	for i, v := range n.Users {
		if i != 0 {
			ctx.WritePlain(", ")
		}
		if err := v.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore RevokeStmt.Users[%d]", i)
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *RevokeStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*RevokeStmt)
	for i, val := range n.Privs {
		node, ok := val.Accept(v)
		if !ok {
			return n, false
		}
		n.Privs[i] = node.(*PrivElem)
	}
	return v.Leave(n)
}

// RevokeStmt is the struct for REVOKE statement.
type RevokeRoleStmt struct {
	stmtNode

	Roles []*auth.RoleIdentity
	Users []*auth.UserIdentity
}

func (n *RevokeRoleStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "REVOKE "
	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, role := range n.Roles {
		tmpMidfix := ""
		if i != 0 {
			tmpMidfix = ", "
		}
		roleNode := role.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = roleNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    roleNode,
				Infix:    tmpMidfix,
				Depth:    depth,
			}
		}
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    tmpRootNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	midfix := " FROM "
	tmpRootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, v := range n.Users {
		tmpMidfix := ""
		if i != 0 {
			tmpMidfix = ", "
		}
		roleNode := v.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = roleNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    roleNode,
				Infix:    tmpMidfix,
				Depth:    depth,
			}
		}
	}

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Infix:    midfix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeRevokeRoleStmt

	return rootNode
}

// Restore implements Node interface.
func (n *RevokeRoleStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("REVOKE ")
	for i, role := range n.Roles {
		if i != 0 {
			ctx.WritePlain(", ")
		}
		if err := role.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore RevokeRoleStmt.Roles[%d]", i)
		}
	}
	ctx.WriteKeyWord(" FROM ")
	for i, v := range n.Users {
		if i != 0 {
			ctx.WritePlain(", ")
		}
		if err := v.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore RevokeRoleStmt.Users[%d]", i)
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *RevokeRoleStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*RevokeRoleStmt)
	return v.Leave(n)
}

// GrantStmt is the struct for GRANT statement.
type GrantStmt struct {
	stmtNode

	Privs      []*PrivElem
	ObjectType ObjectTypeType
	Level      *GrantLevel
	Users      []*UserSpec
	TLSOptions []*TLSOption
	WithGrant  bool
}

func (n *GrantStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "GRANT "
	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, v := range n.Privs {
		midfix := ""
		if i != 0 && v.Priv != 0 {
			midfix = ", "
		} else if v.Priv == 0 {
			midfix = " "
		}
		vNode := v.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = tmpRootNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    vNode,
				Infix:    midfix,
				Depth:    depth,
			}
		}
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    tmpRootNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	midfix := " ON "
	if n.ObjectType != ObjectTypeNone {
		rNode := n.ObjectType.LogCurrentNode(depth + 1)
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Infix:    midfix,
			Depth:    depth,
		}
		midfix = " "
	}

	rNode := n.Level.LogCurrentNode(depth + 1)
	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    rNode,
		Infix:    midfix,
		Depth:    depth,
	}

	midfix = " TO "
	tmpRootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, v := range n.Users {
		tmpMidfix := ""
		if i != 0 {
			tmpMidfix = ", "
		}
		vNode := v.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = vNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    vNode,
				Infix:    tmpMidfix,
				Depth:    depth,
			}
		}
	}
	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Infix:    midfix,
		Depth:    depth,
	}
	midfix = ""

	if n.TLSOptions != nil {
		if len(n.TLSOptions) != 0 {
			midfix += " REQUIRE "
		}

		tmpRootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for i, option := range n.TLSOptions {
			tmpMidfix := ""
			if i != 0 {
				tmpMidfix = " AND "
			}
			optionNode := option.LogCurrentNode(depth + 1)
			if i == 0 {
				tmpRootNode.LNode = optionNode
			} else { // i > 0
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    optionNode,
					Infix:    tmpMidfix,
					Depth:    depth,
				}
			}
		}

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    tmpRootNode,
			Infix:    midfix,
			Depth:    depth,
		}
	}

	if n.WithGrant {
		rootNode.Suffix = " WITH GRANT OPTION"
	}

	rootNode.IRType = sql_ir.TypeGrantStmt

	return rootNode
}

// Restore implements Node interface.
func (n *GrantStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("GRANT ")
	for i, v := range n.Privs {
		if i != 0 && v.Priv != 0 {
			ctx.WritePlain(", ")
		} else if v.Priv == 0 {
			ctx.WritePlain(" ")
		}
		if err := v.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore GrantStmt.Privs[%d]", i)
		}
	}
	ctx.WriteKeyWord(" ON ")
	if n.ObjectType != ObjectTypeNone {
		if err := n.ObjectType.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore GrantStmt.ObjectType")
		}
		ctx.WritePlain(" ")
	}
	if err := n.Level.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore GrantStmt.Level")
	}
	ctx.WriteKeyWord(" TO ")
	for i, v := range n.Users {
		if i != 0 {
			ctx.WritePlain(", ")
		}
		if err := v.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore GrantStmt.Users[%d]", i)
		}
	}
	if n.TLSOptions != nil {
		if len(n.TLSOptions) != 0 {
			ctx.WriteKeyWord(" REQUIRE ")
		}
		for i, option := range n.TLSOptions {
			if i != 0 {
				ctx.WriteKeyWord(" AND ")
			}
			if err := option.Restore(ctx); err != nil {
				return errors.Annotatef(err, "An error occurred while restore GrantStmt.TLSOptions[%d]", i)
			}
		}
	}
	if n.WithGrant {
		ctx.WriteKeyWord(" WITH GRANT OPTION")
	}
	return nil
}

// SecureText implements SensitiveStatement interface.
func (n *GrantStmt) SecureText() string {
	text := n.text
	// Filter "identified by xxx" because it would expose password information.
	idx := strings.Index(strings.ToLower(text), "identified")
	if idx > 0 {
		text = text[:idx]
	}
	return text
}

// Accept implements Node Accept interface.
func (n *GrantStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*GrantStmt)
	for i, val := range n.Privs {
		node, ok := val.Accept(v)
		if !ok {
			return n, false
		}
		n.Privs[i] = node.(*PrivElem)
	}
	return v.Leave(n)
}

// GrantProxyStmt is the struct for GRANT PROXY statement.
type GrantProxyStmt struct {
	stmtNode

	LocalUser     *auth.UserIdentity
	ExternalUsers []*auth.UserIdentity
	WithGrant     bool
}

// Accept implements Node Accept interface.
func (n *GrantProxyStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*GrantProxyStmt)
	return v.Leave(n)
}

func (n *GrantProxyStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "GRANT PROXY ON "
	lNode := n.LocalUser.LogCurrentNode(depth + 1)
	midfix := " TO "

	tmpRootnode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, v := range n.ExternalUsers {
		tmpMidfix := ""
		if i != 0 {
			tmpMidfix = ", "
		}
		vNode := v.LogCurrentNode(depth + 1)

		if i == 0 {
			tmpRootnode.LNode = vNode
		} else { // i > 0
			tmpRootnode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootnode,
				RNode:    vNode,
				Infix:    tmpMidfix,
				Depth:    depth,
			}
		}
	}
	suffix := ""
	if n.WithGrant {
		suffix = " WITH GRANT OPTION"
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		RNode:    tmpRootnode,
		Prefix:   prefix,
		Infix:    midfix,
		Suffix:   suffix,
		Depth:    depth,
	}

	return rootNode

}

// Restore implements Node interface.
func (n *GrantProxyStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("GRANT PROXY ON ")
	if err := n.LocalUser.Restore(ctx); err != nil {
		return errors.Annotatef(err, "An error occurred while restore GrantProxyStmt.LocalUser")
	}
	ctx.WriteKeyWord(" TO ")
	for i, v := range n.ExternalUsers {
		if i != 0 {
			ctx.WritePlain(", ")
		}
		if err := v.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore GrantProxyStmt.ExternalUsers[%d]", i)
		}
	}
	if n.WithGrant {
		ctx.WriteKeyWord(" WITH GRANT OPTION")
	}
	return nil
}

// GrantRoleStmt is the struct for GRANT TO statement.
type GrantRoleStmt struct {
	stmtNode

	Roles []*auth.RoleIdentity
	Users []*auth.UserIdentity
}

// Accept implements Node Accept interface.
func (n *GrantRoleStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*GrantRoleStmt)
	return v.Leave(n)
}

func (n *GrantRoleStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "GRANT "

	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	if len(n.Roles) > 0 {
		tmpMidfix := ""
		for i, role := range n.Roles {
			if i != 0 {
				tmpMidfix = ", "
			}
			roleNode := role.LogCurrentNode(depth + 1)
			if i == 0 {
				tmpRootNode.LNode = roleNode
			} else { // i > 0
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    roleNode,
					Infix:    tmpMidfix,
					Depth:    depth,
				}
			}
		}
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   prefix,
		LNode:    tmpRootNode,
		Depth:    depth,
	}

	midfix := " TO "
	tmpRootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, v := range n.Users {
		tmpMidfix := ""
		if i != 0 {
			tmpMidfix = ", "
		}
		vNode := v.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = vNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    vNode,
				Infix:    tmpMidfix,
				Depth:    depth,
			}
		}
	}

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Infix:    midfix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeGrantRoleStmt

	return rootNode

}

// Restore implements Node interface.
func (n *GrantRoleStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("GRANT ")
	if len(n.Roles) > 0 {
		for i, role := range n.Roles {
			if i != 0 {
				ctx.WritePlain(", ")
			}
			if err := role.Restore(ctx); err != nil {
				return errors.Annotatef(err, "An error occurred while restore GrantRoleStmt.Roles[%d]", i)
			}
		}
	}
	ctx.WriteKeyWord(" TO ")
	for i, v := range n.Users {
		if i != 0 {
			ctx.WritePlain(", ")
		}
		if err := v.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore GrantStmt.Users[%d]", i)
		}
	}
	return nil
}

// SecureText implements SensitiveStatement interface.
func (n *GrantRoleStmt) SecureText() string {
	text := n.text
	// Filter "identified by xxx" because it would expose password information.
	idx := strings.Index(strings.ToLower(text), "identified")
	if idx > 0 {
		text = text[:idx]
	}
	return text
}

// ShutdownStmt is a statement to stop the TiDB server.
// See https://dev.mysql.com/doc/refman/5.7/en/shutdown.html
type ShutdownStmt struct {
	stmtNode
}

func (n *ShutdownStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "SHUTDOWN"

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeShutdownStmt
	return rootNode
}

// Restore implements Node interface.
func (n *ShutdownStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("SHUTDOWN")
	return nil
}

// Accept implements Node Accept interface.
func (n *ShutdownStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*ShutdownStmt)
	return v.Leave(n)
}

// RestartStmt is a statement to restart the TiDB server.
// See https://dev.mysql.com/doc/refman/8.0/en/restart.html
type RestartStmt struct {
	stmtNode
}

func (n *RestartStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "RESTART"

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeRestartStmt
	return rootNode
}

// Restore implements Node interface.
func (n *RestartStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("RESTART")
	return nil
}

// Accept implements Node Accept interface.
func (n *RestartStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*RestartStmt)
	return v.Leave(n)
}

// HelpStmt is a statement for server side help
// See https://dev.mysql.com/doc/refman/8.0/en/help.html
type HelpStmt struct {
	stmtNode

	Topic string
}

func (n *HelpStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "HELP '" + n.Topic + "'"
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeHelpStmt

	return rootNode
}

// Restore implements Node interface.
func (n *HelpStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("HELP ")
	ctx.WriteString(n.Topic)
	return nil
}

// Accept implements Node Accept interface.
func (n *HelpStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*HelpStmt)
	return v.Leave(n)
}

// RenameUserStmt is a statement to rename a user.
// See http://dev.mysql.com/doc/refman/5.7/en/rename-user.html
type RenameUserStmt struct {
	stmtNode

	UserToUsers []*UserToUser
}

func (n *RenameUserStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "RENAME USER "
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for index, user2user := range n.UserToUsers {
		midfix := ""
		if index != 0 {
			midfix = ", "
		}
		userNode := user2user.LogCurrentNode(depth + 1)
		if index == 0 {
			rootNode.LNode = userNode
		} else { // i > 0
			rootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    rootNode,
				RNode:    userNode,
				Infix:    midfix,
				Depth:    depth,
			}
		}
	}

	rootNode.Prefix = prefix
	rootNode.IRType = sql_ir.TypeRenameUserStmt

	return rootNode
}

// Restore implements Node interface.
func (n *RenameUserStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("RENAME USER ")
	for index, user2user := range n.UserToUsers {
		if index != 0 {
			ctx.WritePlain(", ")
		}
		if err := user2user.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore RenameUserStmt.UserToUsers")
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *RenameUserStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*RenameUserStmt)

	for i, t := range n.UserToUsers {
		node, ok := t.Accept(v)
		if !ok {
			return n, false
		}
		n.UserToUsers[i] = node.(*UserToUser)
	}
	return v.Leave(n)
}

// UserToUser represents renaming old user to new user used in RenameUserStmt.
type UserToUser struct {
	node
	OldUser *auth.UserIdentity
	NewUser *auth.UserIdentity
}

func (n *UserToUser) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	lNode := n.OldUser.LogCurrentNode(depth + 1)
	midfix := " TO "
	rNode := n.NewUser.LogCurrentNode(depth + 1)

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		RNode:    rNode,
		Infix:    midfix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeUserToUser
	return rootNode

}

// Restore implements Node interface.
func (n *UserToUser) Restore(ctx *format.RestoreCtx) error {
	if err := n.OldUser.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore UserToUser.OldUser")
	}
	ctx.WriteKeyWord(" TO ")
	if err := n.NewUser.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore UserToUser.NewUser")
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *UserToUser) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*UserToUser)
	return v.Leave(n)
}

type BRIEKind uint8
type BRIEOptionType uint16

const (
	BRIEKindBackup BRIEKind = iota
	BRIEKindRestore

	// common BRIE options
	BRIEOptionRateLimit BRIEOptionType = iota + 1
	BRIEOptionConcurrency
	BRIEOptionChecksum
	BRIEOptionSendCreds
	BRIEOptionCheckpoint
	// backup options
	BRIEOptionBackupTimeAgo
	BRIEOptionBackupTS
	BRIEOptionBackupTSO
	BRIEOptionLastBackupTS
	BRIEOptionLastBackupTSO
	// restore options
	BRIEOptionOnline
	// import options
	BRIEOptionAnalyze
	BRIEOptionBackend
	BRIEOptionOnDuplicate
	BRIEOptionSkipSchemaFiles
	BRIEOptionStrictFormat
	BRIEOptionTiKVImporter
	BRIEOptionResume
	// CSV options
	BRIEOptionCSVBackslashEscape
	BRIEOptionCSVDelimiter
	BRIEOptionCSVHeader
	BRIEOptionCSVNotNull
	BRIEOptionCSVNull
	BRIEOptionCSVSeparator
	BRIEOptionCSVTrimLastSeparators

	BRIECSVHeaderIsColumns = ^uint64(0)
)

type BRIEOptionLevel uint64

const (
	BRIEOptionLevelOff      BRIEOptionLevel = iota // equals FALSE
	BRIEOptionLevelRequired                        // equals TRUE
	BRIEOptionLevelOptional
)

func (kind BRIEKind) String() string {
	switch kind {
	case BRIEKindBackup:
		return "BACKUP"
	case BRIEKindRestore:
		return "RESTORE"
	default:
		return ""
	}
}

func (kind BRIEOptionType) String() string {
	switch kind {
	case BRIEOptionRateLimit:
		return "RATE_LIMIT"
	case BRIEOptionConcurrency:
		return "CONCURRENCY"
	case BRIEOptionChecksum:
		return "CHECKSUM"
	case BRIEOptionSendCreds:
		return "SEND_CREDENTIALS_TO_TIKV"
	case BRIEOptionBackupTimeAgo, BRIEOptionBackupTS, BRIEOptionBackupTSO:
		return "SNAPSHOT"
	case BRIEOptionLastBackupTS, BRIEOptionLastBackupTSO:
		return "LAST_BACKUP"
	case BRIEOptionOnline:
		return "ONLINE"
	case BRIEOptionCheckpoint:
		return "CHECKPOINT"
	case BRIEOptionAnalyze:
		return "ANALYZE"
	case BRIEOptionBackend:
		return "BACKEND"
	case BRIEOptionOnDuplicate:
		return "ON_DUPLICATE"
	case BRIEOptionSkipSchemaFiles:
		return "SKIP_SCHEMA_FILES"
	case BRIEOptionStrictFormat:
		return "STRICT_FORMAT"
	case BRIEOptionTiKVImporter:
		return "TIKV_IMPORTER"
	case BRIEOptionResume:
		return "RESUME"
	case BRIEOptionCSVBackslashEscape:
		return "CSV_BACKSLASH_ESCAPE"
	case BRIEOptionCSVDelimiter:
		return "CSV_DELIMITER"
	case BRIEOptionCSVHeader:
		return "CSV_HEADER"
	case BRIEOptionCSVNotNull:
		return "CSV_NOT_NULL"
	case BRIEOptionCSVNull:
		return "CSV_NULL"
	case BRIEOptionCSVSeparator:
		return "CSV_SEPARATOR"
	case BRIEOptionCSVTrimLastSeparators:
		return "CSV_TRIM_LAST_SEPARATORS"
	default:
		return ""
	}
}

func (level BRIEOptionLevel) String() string {
	switch level {
	case BRIEOptionLevelOff:
		return "OFF"
	case BRIEOptionLevelOptional:
		return "OPTIONAL"
	case BRIEOptionLevelRequired:
		return "REQUIRED"
	default:
		return ""
	}
}

type BRIEOption struct {
	Tp        BRIEOptionType
	StrValue  string
	UintValue uint64
}

func (n *BRIEOption) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := n.Tp.String() + " = "
	midfix := ""
	var lNode *sql_ir.SqlRsgIR = nil

	switch n.Tp {
	case BRIEOptionBackupTS, BRIEOptionLastBackupTS, BRIEOptionBackend, BRIEOptionOnDuplicate, BRIEOptionTiKVImporter, BRIEOptionCSVDelimiter, BRIEOptionCSVNull, BRIEOptionCSVSeparator:
		prefix += "'" + n.StrValue + "'"
	case BRIEOptionBackupTimeAgo:
		lNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			IValue:   int64(n.UintValue / 1000),
			Str:      strconv.FormatInt(int64(n.UintValue/1000), 10),
			Depth:    depth,
		}
		midfix = " MICROSECOND AGO "
	case BRIEOptionRateLimit:
		lNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			IValue:   int64(n.UintValue / 1048576),
			Str:      strconv.FormatInt(int64(n.UintValue/1048576), 10),
			Depth:    depth,
		}
		midfix += " MB / SECOND "
	case BRIEOptionCSVHeader:
		if n.UintValue == BRIECSVHeaderIsColumns {
			prefix += " COLUMNS "
		} else {
			lNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				IValue:   int64(n.UintValue / 1048576),
				Str:      strconv.FormatInt(int64(n.UintValue/1048576), 10),
				Depth:    depth,
			}
		}
	case BRIEOptionChecksum, BRIEOptionAnalyze:
		// BACKUP/RESTORE doesn't support OPTIONAL value for now, should warn at executor
		prefix += BRIEOptionLevel(n.UintValue).String()
	default:
		lNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			IValue:   int64(n.UintValue / 1048576),
			Str:      strconv.FormatInt(int64(n.UintValue/1048576), 10),
			Depth:    depth,
		}
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Infix:    midfix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeBRIEOption
	return rootNode
}

func (opt *BRIEOption) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord(opt.Tp.String())
	ctx.WritePlain(" = ")
	switch opt.Tp {
	case BRIEOptionBackupTS, BRIEOptionLastBackupTS, BRIEOptionBackend, BRIEOptionOnDuplicate, BRIEOptionTiKVImporter, BRIEOptionCSVDelimiter, BRIEOptionCSVNull, BRIEOptionCSVSeparator:
		ctx.WriteString(opt.StrValue)
	case BRIEOptionBackupTimeAgo:
		ctx.WritePlainf("%d ", opt.UintValue/1000)
		ctx.WriteKeyWord("MICROSECOND AGO")
	case BRIEOptionRateLimit:
		ctx.WritePlainf("%d ", opt.UintValue/1048576)
		ctx.WriteKeyWord("MB")
		ctx.WritePlain("/")
		ctx.WriteKeyWord("SECOND")
	case BRIEOptionCSVHeader:
		if opt.UintValue == BRIECSVHeaderIsColumns {
			ctx.WriteKeyWord("COLUMNS")
		} else {
			ctx.WritePlainf("%d", opt.UintValue)
		}
	case BRIEOptionChecksum, BRIEOptionAnalyze:
		// BACKUP/RESTORE doesn't support OPTIONAL value for now, should warn at executor
		ctx.WriteKeyWord(BRIEOptionLevel(opt.UintValue).String())
	default:
		ctx.WritePlainf("%d", opt.UintValue)
	}
	return nil
}

// BRIEStmt is a statement for backup, restore, import and export.
type BRIEStmt struct {
	stmtNode

	Kind    BRIEKind
	Schemas []string
	Tables  []*TableName
	Storage string
	Options []*BRIEOption
}

func (n *BRIEStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*BRIEStmt)
	for i, val := range n.Tables {
		node, ok := val.Accept(v)
		if !ok {
			return n, false
		}
		n.Tables[i] = node.(*TableName)
	}
	return v.Leave(n)
}

func (n *BRIEStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	prefix := n.Kind.String()

	switch {
	case len(n.Tables) != 0:
		prefix += " TABLE "
		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for index, table := range n.Tables {
			tmpMidfix := ""
			if index != 0 {
				tmpMidfix = ", "
			}
			tableNode := table.LogCurrentNode(depth + 1)
			tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(tableNode, sql_ir.DataTableName)
			for _, tableNameNode := range tableNameNodeList {
				tableNameNode.DataType = sql_ir.DataTableName
				tableNameNode.ContextFlag = sql_ir.ContextUse
			}

			if index == 0 {
				tmpRootNode.LNode = tableNode
			} else { // i > 0
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    tableNode,
					Infix:    tmpMidfix,
					Depth:    depth,
				}
			}
		}
		rootNode.Prefix = prefix
		rootNode.LNode = tmpRootNode
		prefix = ""

	case len(n.Schemas) != 0:
		prefix += " DATABASE "
		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for index, schema := range n.Schemas {
			tmpMidfix := ""
			if index != 0 {
				tmpMidfix = ", "
			}
			schemaName := &sql_ir.SqlRsgIR{
				IRType:      sql_ir.TypeIdentifier,
				DataType:    sql_ir.DataSchemaName,
				ContextFlag: sql_ir.ContextUse,
				Str:         schema,
				Depth:       depth,
			}
			if index == 0 {
				tmpRootNode.LNode = schemaName
			} else { // i > 0
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    schemaName,
					Infix:    tmpMidfix,
					Depth:    depth,
				}
			}
		}

		rootNode.Prefix = prefix
		rootNode.LNode = tmpRootNode

	default:
		prefix = " DATABASE *"
		rootNode.Prefix = prefix
	}

	midfix := ""
	switch n.Kind {
	case BRIEKindBackup:
		midfix = " TO "
	case BRIEKindRestore:
		midfix = " FROM "
	}
	midfix += "'" + n.Storage + "' "

	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, opt := range n.Options {
		optNode := opt.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = optNode
		} else {
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    optNode,
				Infix:    " ",
				Depth:    depth,
			}
		}
	}

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Infix:    midfix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeBRIEStmt

	return rootNode

}

func (n *BRIEStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord(n.Kind.String())

	switch {
	case len(n.Tables) != 0:
		ctx.WriteKeyWord(" TABLE ")
		for index, table := range n.Tables {
			if index != 0 {
				ctx.WritePlain(", ")
			}
			if err := table.Restore(ctx); err != nil {
				return errors.Annotatef(err, "An error occurred while restore BRIEStmt.Tables[%d]", index)
			}
		}
	case len(n.Schemas) != 0:
		ctx.WriteKeyWord(" DATABASE ")
		for index, schema := range n.Schemas {
			if index != 0 {
				ctx.WritePlain(", ")
			}
			ctx.WriteName(schema)
		}
	default:
		ctx.WriteKeyWord(" DATABASE")
		ctx.WritePlain(" *")
	}

	switch n.Kind {
	case BRIEKindBackup:
		ctx.WriteKeyWord(" TO ")
	case BRIEKindRestore:
		ctx.WriteKeyWord(" FROM ")
	}
	ctx.WriteString(n.Storage)

	for _, opt := range n.Options {
		ctx.WritePlain(" ")
		if err := opt.Restore(ctx); err != nil {
			return err
		}
	}

	return nil
}

// SecureText implements SensitiveStmtNode
func (n *BRIEStmt) SecureText() string {
	// FIXME: this solution is not scalable, and duplicates some logic from BR.
	redactedStorage := n.Storage
	u, err := url.Parse(n.Storage)
	if err == nil {
		if u.Scheme == "s3" {
			query := u.Query()
			for key := range query {
				switch strings.ToLower(strings.ReplaceAll(key, "_", "-")) {
				case "access-key", "secret-access-key":
					query[key] = []string{"xxxxxx"}
				}
			}
			u.RawQuery = query.Encode()
			redactedStorage = u.String()
		}
	}

	redactedStmt := &BRIEStmt{
		Kind:    n.Kind,
		Schemas: n.Schemas,
		Tables:  n.Tables,
		Storage: redactedStorage,
		Options: n.Options,
	}

	var sb strings.Builder
	_ = redactedStmt.Restore(format.NewRestoreCtx(format.DefaultRestoreFlags, &sb))
	return sb.String()
}

type PurgeImportStmt struct {
	stmtNode

	TaskID uint64
}

func (n *PurgeImportStmt) Accept(v Visitor) (Node, bool) {
	newNode, _ := v.Enter(n)
	n = newNode.(*PurgeImportStmt)
	return v.Leave(n)
}

func (n *PurgeImportStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "PURGE IMPORT "
	lNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeIntegerLiteral,
		DataType: sql_ir.DataNone,
		IValue:   int64(n.TaskID),
		Str:      strconv.FormatInt(int64(n.TaskID), 10),
		Depth:    depth,
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypePurgeImportStmt

	return rootNode

}

func (n *PurgeImportStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WritePlainf("PURGE IMPORT %d", n.TaskID)
	return nil
}

// ErrorHandlingOption is used in async IMPORT related stmt
type ErrorHandlingOption uint64

const (
	ErrorHandleError ErrorHandlingOption = iota
	ErrorHandleReplace
	ErrorHandleSkipAll
	ErrorHandleSkipConstraint
	ErrorHandleSkipDuplicate
	ErrorHandleSkipStrict
)

func (o ErrorHandlingOption) String() string {
	switch o {
	case ErrorHandleError:
		return ""
	case ErrorHandleReplace:
		return "REPLACE"
	case ErrorHandleSkipAll:
		return "SKIP ALL"
	case ErrorHandleSkipConstraint:
		return "SKIP CONSTRAINT"
	case ErrorHandleSkipDuplicate:
		return "SKIP DUPLICATE"
	case ErrorHandleSkipStrict:
		return "SKIP STRICT"
	default:
		return ""
	}
}

type CreateImportStmt struct {
	stmtNode

	IfNotExists   bool
	Name          string
	Storage       string
	ErrorHandling ErrorHandlingOption
	Options       []*BRIEOption
}

func (n *CreateImportStmt) Accept(v Visitor) (Node, bool) {
	newNode, _ := v.Enter(n)
	n = newNode.(*CreateImportStmt)
	return v.Leave(n)
}

func (n *CreateImportStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "CREATE IMPORT "
	if n.IfNotExists {
		prefix += "IF NOT EXISTS "
	}
	lNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataNone,
		ContextFlag: sql_ir.ContextDefine,
		Str:         n.Name,
		Depth:       depth,
	}
	midfix := " FROM " + n.Storage
	if n.ErrorHandling != ErrorHandleError {
		midfix += " " + n.ErrorHandling.String()
	}

	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, opt := range n.Options {
		midfix := " "
		optNode := opt.LogCurrentNode(depth + 1)

		if i == 0 {
			tmpRootNode.LNode = optNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    optNode,
				Infix:    midfix,
				Depth:    depth,
			}
		}
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		RNode:    tmpRootNode,
		Prefix:   prefix,
		Infix:    midfix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeCreateImportStmt
	return rootNode
}

func (n *CreateImportStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("CREATE IMPORT ")
	if n.IfNotExists {
		ctx.WriteKeyWord("IF NOT EXISTS ")
	}
	ctx.WriteName(n.Name)
	ctx.WriteKeyWord(" FROM ")
	ctx.WriteString(n.Storage)
	if n.ErrorHandling != ErrorHandleError {
		ctx.WritePlain(" ")
		ctx.WriteKeyWord(n.ErrorHandling.String())
	}
	for _, opt := range n.Options {
		ctx.WritePlain(" ")
		if err := opt.Restore(ctx); err != nil {
			return err
		}
	}
	return nil
}

// SecureText implements SensitiveStmtNode
func (n *CreateImportStmt) SecureText() string {
	// FIXME: this solution is not scalable, and duplicates some logic from BR.
	redactedStorage := n.Storage
	u, err := url.Parse(n.Storage)
	if err == nil {
		if u.Scheme == "s3" {
			query := u.Query()
			for key := range query {
				switch strings.ToLower(strings.ReplaceAll(key, "_", "-")) {
				case "access-key", "secret-access-key":
					query[key] = []string{"xxxxxx"}
				}
			}
			u.RawQuery = query.Encode()
			redactedStorage = u.String()
		}
	}

	redactedStmt := &CreateImportStmt{
		IfNotExists:   n.IfNotExists,
		Name:          n.Name,
		Storage:       redactedStorage,
		ErrorHandling: n.ErrorHandling,
		Options:       n.Options,
	}

	var sb strings.Builder
	_ = redactedStmt.Restore(format.NewRestoreCtx(format.DefaultRestoreFlags, &sb))
	return sb.String()
}

type StopImportStmt struct {
	stmtNode

	IfRunning bool
	Name      string
}

func (n *StopImportStmt) Accept(v Visitor) (Node, bool) {
	newNode, _ := v.Enter(n)
	n = newNode.(*StopImportStmt)
	return v.Leave(n)
}

func (n *StopImportStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "STOP IMPORT "
	if n.IfRunning {
		prefix += "IF RUNNING "
	}
	nameNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataNone,
		ContextFlag: sql_ir.ContextUse,
		Str:         n.Name,
		Depth:       depth,
	}
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    nameNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeStopImportStmt

	return rootNode
}

func (n *StopImportStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("STOP IMPORT ")
	if n.IfRunning {
		ctx.WriteKeyWord("IF RUNNING ")
	}
	ctx.WriteName(n.Name)
	return nil
}

type ResumeImportStmt struct {
	stmtNode

	IfNotRunning bool
	Name         string
}

func (n *ResumeImportStmt) Accept(v Visitor) (Node, bool) {
	newNode, _ := v.Enter(n)
	n = newNode.(*ResumeImportStmt)
	return v.Leave(n)
}

func (n *ResumeImportStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "RESUME IMPORT "
	if n.IfNotRunning {
		prefix += "IF NOT RUNNING "
	}
	nameNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataNone,
		ContextFlag: sql_ir.ContextUse,
		Str:         n.Name,
		Depth:       depth,
	}
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    nameNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeResumeImportStmt

	return rootNode
}

func (n *ResumeImportStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("RESUME IMPORT ")
	if n.IfNotRunning {
		ctx.WriteKeyWord("IF NOT RUNNING ")
	}
	ctx.WriteName(n.Name)
	return nil
}

type ImportTruncate struct {
	IsErrorsOnly bool
	TableNames   []*TableName
}

type AlterImportStmt struct {
	stmtNode

	Name          string
	ErrorHandling ErrorHandlingOption
	Options       []*BRIEOption
	Truncate      *ImportTruncate
}

func (n *AlterImportStmt) Accept(v Visitor) (Node, bool) {
	newNode, _ := v.Enter(n)
	n = newNode.(*AlterImportStmt)
	return v.Leave(n)
}

func (n *AlterImportStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "ALTER IMPORT "
	lNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataNone,
		ContextFlag: sql_ir.ContextUse,
		Str:         n.Name,
		Depth:       depth,
	}

	midfix := ""
	if n.ErrorHandling != ErrorHandleError {
		midfix = " " + n.ErrorHandling.String()
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Infix:    midfix,
		Depth:    depth,
	}
	prefix = ""
	midfix = ""

	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, opt := range n.Options {
		tmpMidfix := " "
		optNode := opt.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = optNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    optNode,
				Infix:    tmpMidfix,
				Depth:    depth,
			}
		}
	}

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Infix:    midfix,
		Depth:    depth,
	}

	midfix = ""
	if n.Truncate != nil {
		if n.Truncate.IsErrorsOnly {
			midfix += " TRUNCATE ERRORS"
		} else {
			midfix += " TRUNCATE ALL"
		}
		if len(n.Truncate.TableNames) != 0 {
			midfix += " TABLE "
		}

		tmpRootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for i := range n.Truncate.TableNames {
			tmpMidfix := ""
			if i == 0 {
				tmpMidfix = " "
			} else {
				tmpMidfix = ", "
			}
			truncateNode := n.Truncate.TableNames[i].LogCurrentNode(depth + 1)
			tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(truncateNode, sql_ir.DataTableName)
			for _, tableNameNode := range tableNameNodeList {
				tableNameNode.DataType = sql_ir.DataTableName
				tableNameNode.ContextFlag = sql_ir.ContextUse
			}

			if i == 0 {
				tmpRootNode.LNode = truncateNode
			} else { // i > 0
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    truncateNode,
					Infix:    tmpMidfix,
					Depth:    depth,
				}
			}
		}

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    tmpRootNode,
			Infix:    midfix,
			Depth:    depth,
		}
	}

	rootNode.IRType = sql_ir.TypeAlterImportStmt
	return rootNode
}

func (n *AlterImportStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("ALTER IMPORT ")
	ctx.WriteName(n.Name)
	if n.ErrorHandling != ErrorHandleError {
		ctx.WritePlain(" ")
		ctx.WriteKeyWord(n.ErrorHandling.String())
	}
	for _, opt := range n.Options {
		ctx.WritePlain(" ")
		if err := opt.Restore(ctx); err != nil {
			return err
		}
	}
	if n.Truncate != nil {
		if n.Truncate.IsErrorsOnly {
			ctx.WriteKeyWord(" TRUNCATE ERRORS")
		} else {
			ctx.WriteKeyWord(" TRUNCATE ALL")
		}
		if len(n.Truncate.TableNames) != 0 {
			ctx.WriteKeyWord(" TABLE")
		}
		for i := range n.Truncate.TableNames {
			if i == 0 {
				ctx.WritePlain(" ")
			} else {
				ctx.WritePlain(", ")
			}
			if err := n.Truncate.TableNames[i].Restore(ctx); err != nil {
				return err
			}
		}
	}
	return nil
}

type DropImportStmt struct {
	stmtNode

	IfExists bool
	Name     string
}

func (n *DropImportStmt) Accept(v Visitor) (Node, bool) {
	newNode, _ := v.Enter(n)
	n = newNode.(*DropImportStmt)
	return v.Leave(n)
}

func (n *DropImportStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "DROP IMPORT "
	if n.IfExists {
		prefix += "IF EXISTS "
	}
	nameNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataNone,
		ContextFlag: sql_ir.ContextUndefine,
		Suffix:      n.Name,
		Depth:       depth,
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    nameNode,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeDropImportStmt

	return rootNode
}

func (n *DropImportStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("DROP IMPORT ")
	if n.IfExists {
		ctx.WriteKeyWord("IF EXISTS ")
	}
	ctx.WriteName(n.Name)
	return nil
}

type ShowImportStmt struct {
	stmtNode

	Name       string
	ErrorsOnly bool
	TableNames []*TableName
}

func (n *ShowImportStmt) Accept(v Visitor) (Node, bool) {
	newNode, _ := v.Enter(n)
	n = newNode.(*ShowImportStmt)
	return v.Leave(n)
}

func (n *ShowImportStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "SHOW IMPORT "
	nameNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataNone,
		ContextFlag: sql_ir.ContextUse,
		Str:         n.Name,
		Depth:       depth,
	}
	midfix := ""
	if n.ErrorsOnly {
		midfix += " ERRORS"
	}
	if len(n.TableNames) != 0 {
		midfix += " TABLE"
	}

	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i := range n.TableNames {
		tmpMidfix := ""
		if i == 0 {
			tmpMidfix = " "
		} else {
			tmpMidfix = ", "
		}
		tableNameNode := n.TableNames[i].LogCurrentNode(depth + 1)
		tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(tableNameNode, sql_ir.DataTableName)
		for _, tmpTableNameNode := range tableNameNodeList {
			tmpTableNameNode.DataType = sql_ir.DataTableName
			tmpTableNameNode.ContextFlag = sql_ir.ContextUse
		}

		if i == 0 {
			tmpRootNode.LNode = tableNameNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    tableNameNode,
				Infix:    tmpMidfix,
				Depth:    depth,
			}
		}
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    nameNode,
		RNode:    tmpRootNode,
		Prefix:   prefix,
		Infix:    midfix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeShowImportStmt

	return rootNode

}

func (n *ShowImportStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("SHOW IMPORT ")
	ctx.WriteName(n.Name)
	if n.ErrorsOnly {
		ctx.WriteKeyWord(" ERRORS")
	}
	if len(n.TableNames) != 0 {
		ctx.WriteKeyWord(" TABLE")
	}
	for i := range n.TableNames {
		if i == 0 {
			ctx.WritePlain(" ")
		} else {
			ctx.WritePlain(", ")
		}
		if err := n.TableNames[i].Restore(ctx); err != nil {
			return err
		}
	}
	return nil
}

// Ident is the table identifier composed of schema name and table name.
type Ident struct {
	Schema model.CIStr
	Name   model.CIStr
}

// String implements fmt.Stringer interface.
func (i Ident) String() string {
	if i.Schema.O == "" {
		return i.Name.O
	}
	return fmt.Sprintf("%s.%s", i.Schema, i.Name)
}

// SelectStmtOpts wrap around select hints and switches
type SelectStmtOpts struct {
	Distinct        bool
	SQLBigResult    bool
	SQLBufferResult bool
	SQLCache        bool
	SQLSmallResult  bool
	CalcFoundRows   bool
	StraightJoin    bool
	Priority        mysql.PriorityEnum
	TableHints      []*TableOptimizerHint
	ExplicitAll     bool
}

// TableOptimizerHint is Table level optimizer hint
type TableOptimizerHint struct {
	node
	// HintName is the name or alias of the table(s) which the hint will affect.
	// Table hints has no schema info
	// It allows only table name or alias (if table has an alias)
	HintName model.CIStr
	// HintData is the payload of the hint. The actual type of this field
	// is defined differently as according `HintName`. Define as following:
	//
	// Statement Execution Time Optimizer Hints
	// See https://dev.mysql.com/doc/refman/5.7/en/optimizer-hints.html#optimizer-hints-execution-time
	// - MAX_EXECUTION_TIME  => uint64
	// - MEMORY_QUOTA        => int64
	// - QUERY_TYPE          => model.CIStr
	//
	// Time Range is used to hint the time range of inspection tables
	// e.g: select /*+ time_range('','') */ * from information_schema.inspection_result.
	// - TIME_RANGE          => ast.HintTimeRange
	// - READ_FROM_STORAGE   => model.CIStr
	// - USE_TOJA            => bool
	// - NTH_PLAN            => int64
	HintData interface{}
	// QBName is the default effective query block of this hint.
	QBName  model.CIStr
	Tables  []HintTable
	Indexes []model.CIStr
}

// HintTimeRange is the payload of `TIME_RANGE` hint
type HintTimeRange struct {
	From string
	To   string
}

// HintSetVar is the payload of `SET_VAR` hint
type HintSetVar struct {
	VarName string
	Value   string
}

// HintTable is table in the hint. It may have query block info.
type HintTable struct {
	DBName        model.CIStr
	TableName     model.CIStr
	QBName        model.CIStr
	PartitionList []model.CIStr
}

func (n *HintTable) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	midfix := ""
	if n.DBName.L != "" {
		dbNameNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataDatabaseName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.DBName.String(),
			Depth:       depth,
		}
		midfix = "."
		rootNode.LNode = dbNameNode
	}

	rNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataTableName,
		ContextFlag: sql_ir.ContextUse,
		Str:         n.TableName.String(),
		Depth:       depth,
	}

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    rNode,
		Infix:    midfix,
		Depth:    depth,
	}
	midfix = ""

	if n.QBName.L != "" {
		midfix = "@"
		rNode = &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataNone,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.QBName.String(),
			Depth:       depth,
		}

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Infix:    midfix,
			Depth:    depth,
		}
		midfix = ""
	}
	if len(n.PartitionList) > 0 {
		midfix += " PARTITION ("
		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for i, p := range n.PartitionList {
			tmpMidfix := ""
			if i > 0 {
				tmpMidfix = ", "
			}
			nameNode := &sql_ir.SqlRsgIR{
				IRType:      sql_ir.TypeIdentifier,
				DataType:    sql_ir.DataPartitionName,
				ContextFlag: sql_ir.ContextUse,
				Str:         p.String(),
				Depth:       depth,
			}

			if i == 0 {
				tmpRootNode.LNode = nameNode
			} else { // i > 0
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    nameNode,
					Infix:    tmpMidfix,
					Depth:    depth,
				}
			}
		}
		tmpRootNode.Prefix = "("
		tmpRootNode.Suffix = ")"

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    tmpRootNode,
			Infix:    midfix,
			Depth:    depth,
		}
	}

	rootNode.IRType = sql_ir.TypeHintTable
	return rootNode
}

func (ht *HintTable) Restore(ctx *format.RestoreCtx) {
	if ht.DBName.L != "" {
		ctx.WriteName(ht.DBName.String())
		ctx.WriteKeyWord(".")
	}
	ctx.WriteName(ht.TableName.String())
	if ht.QBName.L != "" {
		ctx.WriteKeyWord("@")
		ctx.WriteName(ht.QBName.String())
	}
	if len(ht.PartitionList) > 0 {
		ctx.WriteKeyWord(" PARTITION")
		ctx.WritePlain("(")
		for i, p := range ht.PartitionList {
			if i > 0 {
				ctx.WritePlain(", ")
			}
			ctx.WriteName(p.String())
		}
		ctx.WritePlain(")")
	}
}

func (n *TableOptimizerHint) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	topPrefix := n.HintName.String() + " ( "
	var lNode *sql_ir.SqlRsgIR = nil

	prefix := ""
	if n.QBName.L != "" {
		if n.HintName.L != "qb_name" {
			prefix += "@"
		}
		lNode = &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataNone,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.QBName.String(),
			Depth:       depth,
		}
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	midfix := ""
	// Hints without args except query block.
	switch n.HintName.L {
	case "hash_agg", "stream_agg", "agg_to_cop", "read_consistent_replica", "no_index_merge", "qb_name", "ignore_plan_cache", "limit_to_cop", "straight_join":
		midfix += ")"
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			Prefix:   topPrefix,
			Infix:    midfix,
			Depth:    depth,
		}
		rootNode.IRType = sql_ir.TypeTableOptimizerHint
		return rootNode
	}
	if n.QBName.L != "" {
		midfix = " "
	}
	// Hints with args except query block.
	switch n.HintName.L {
	case "max_execution_time":
		rNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			IValue:   int64(n.HintData.(uint64)),
			Str:      strconv.FormatInt(int64(n.HintData.(uint64)), 10),
			Depth:    depth,
		}
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Depth:    depth,
		}
	case "nth_plan":
		rNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			IValue:   int64(n.HintData.(int64)),
			Str:      strconv.FormatInt(int64(n.HintData.(uint64)), 10),
			Depth:    depth,
		}
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Depth:    depth,
		}
	case "tidb_hj", "tidb_smj", "tidb_inlj", "hash_join", "merge_join", "inl_join", "broadcast_join", "inl_hash_join", "inl_merge_join", "leading":
		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for i, table := range n.Tables {
			tmpMidfix := ""
			if i != 0 {
				tmpMidfix = ", "
			}
			tableNode := table.LogCurrentNode(depth + 1)
			if i == 0 {
				tmpRootNode.LNode = tableNode
			} else { // i > 0
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    tableNode,
					Infix:    tmpMidfix,
					Depth:    depth,
				}
			}
		}

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    tmpRootNode,
			Depth:    depth,
		}

	case "use_index", "ignore_index", "use_index_merge", "force_index":
		tableNode := n.Tables[0].LogCurrentNode(depth + 1)
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    tableNode,
			Depth:    depth,
		}
		midfix = " "
		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for i, index := range n.Indexes {
			tmpMidfix := ""
			if i != 0 {
				tmpMidfix = ", "
			}
			indexNode := &sql_ir.SqlRsgIR{
				IRType:      sql_ir.TypeIdentifier,
				DataType:    sql_ir.DataIndexName,
				ContextFlag: sql_ir.ContextUse,
				Str:         index.String(),
				Depth:       depth,
			}
			if i == 0 {
				tmpRootNode.LNode = indexNode
			} else {
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    indexNode,
					Infix:    tmpMidfix,
					Depth:    depth,
				}
			}
		}

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    tmpRootNode,
			Infix:    midfix,
			Depth:    depth,
		}

	case "use_toja", "use_cascades":
		if n.HintData.(bool) {
			midfix += "TRUE"
		} else {
			midfix += "FALSE"
		}

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			Infix:    midfix,
			Depth:    depth,
		}
	case "query_type":
		midfix = n.HintData.(model.CIStr).String()
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			Infix:    midfix,
			Depth:    depth,
		}
	case "memory_quota":
		suffix := "MB"
		rNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			IValue:   int64(n.HintData.(int64) / 1024 / 1024),
			Str:      strconv.FormatInt(int64(n.HintData.(int64)/1024/1024), 10),
			Depth:    depth,
		}

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Suffix:   suffix,
			Depth:    depth,
		}

	case "read_from_storage":
		midfix = n.HintData.(model.CIStr).String()
		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for i, table := range n.Tables {
			tmpMidfix := ""
			if i > 0 {
				tmpMidfix = ", "
			}
			tableNode := table.LogCurrentNode(depth + 1)
			if i == 0 {
				tmpRootNode.LNode = tableNode
			} else { // i > 0
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    tableNode,
					Infix:    tmpMidfix,
					Depth:    depth,
				}
			}
		}
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    tmpRootNode,
			Infix:    midfix,
			Depth:    depth,
		}
	case "time_range":
		hintData := n.HintData.(HintTimeRange)
		midfix += hintData.From + ", " + hintData.To
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			Infix:    midfix,
			Depth:    depth,
		}
	case "set_var":
		hintData := n.HintData.(HintSetVar)
		midfix += hintData.VarName + ", " + hintData.Value
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			Infix:    midfix,
			Depth:    depth,
		}
	}
	rootNode.Prefix = topPrefix
	rootNode.Suffix = ")"

	rootNode.IRType = sql_ir.TypeTableOptimizerHint

	return rootNode
}

// Restore implements Node interface.
func (n *TableOptimizerHint) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord(n.HintName.String())
	ctx.WritePlain("(")
	if n.QBName.L != "" {
		if n.HintName.L != "qb_name" {
			ctx.WriteKeyWord("@")
		}
		ctx.WriteName(n.QBName.String())
	}
	// Hints without args except query block.
	switch n.HintName.L {
	case "hash_agg", "stream_agg", "agg_to_cop", "read_consistent_replica", "no_index_merge", "qb_name", "ignore_plan_cache", "limit_to_cop", "straight_join":
		ctx.WritePlain(")")
		return nil
	}
	if n.QBName.L != "" {
		ctx.WritePlain(" ")
	}
	// Hints with args except query block.
	switch n.HintName.L {
	case "max_execution_time":
		ctx.WritePlainf("%d", n.HintData.(uint64))
	case "nth_plan":
		ctx.WritePlainf("%d", n.HintData.(int64))
	case "tidb_hj", "tidb_smj", "tidb_inlj", "hash_join", "merge_join", "inl_join", "broadcast_join", "inl_hash_join", "inl_merge_join", "leading":
		for i, table := range n.Tables {
			if i != 0 {
				ctx.WritePlain(", ")
			}
			table.Restore(ctx)
		}
	case "use_index", "ignore_index", "use_index_merge", "force_index":
		n.Tables[0].Restore(ctx)
		ctx.WritePlain(" ")
		for i, index := range n.Indexes {
			if i != 0 {
				ctx.WritePlain(", ")
			}
			ctx.WriteName(index.String())
		}
	case "use_toja", "use_cascades":
		if n.HintData.(bool) {
			ctx.WritePlain("TRUE")
		} else {
			ctx.WritePlain("FALSE")
		}
	case "query_type":
		ctx.WriteKeyWord(n.HintData.(model.CIStr).String())
	case "memory_quota":
		ctx.WritePlainf("%d MB", n.HintData.(int64)/1024/1024)
	case "read_from_storage":
		ctx.WriteKeyWord(n.HintData.(model.CIStr).String())
		for i, table := range n.Tables {
			if i == 0 {
				ctx.WritePlain("[")
			}
			table.Restore(ctx)
			if i == len(n.Tables)-1 {
				ctx.WritePlain("]")
			} else {
				ctx.WritePlain(", ")
			}
		}
	case "time_range":
		hintData := n.HintData.(HintTimeRange)
		ctx.WriteString(hintData.From)
		ctx.WritePlain(", ")
		ctx.WriteString(hintData.To)
	case "set_var":
		hintData := n.HintData.(HintSetVar)
		ctx.WriteString(hintData.VarName)
		ctx.WritePlain(", ")
		ctx.WriteString(hintData.Value)
	}
	ctx.WritePlain(")")
	return nil
}

// Accept implements Node Accept interface.
func (n *TableOptimizerHint) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*TableOptimizerHint)
	return v.Leave(n)
}

// TextString represent a string, it can be a binary literal.
type TextString struct {
	Value           string
	IsBinaryLiteral bool
}

// TransformTextStrings converts a slice of TextString to strings.
// This is only used by enum/set strings.
func TransformTextStrings(ts []*TextString, _ string) []string {
	// The UTF-8 encoding rather than other encoding is used
	// because parser is not possible to determine the "real"
	// charset that a binary literal string should be converted to.
	enc := charset.EncodingUTF8Impl
	ret := make([]string, 0, len(ts))
	for _, t := range ts {
		if !t.IsBinaryLiteral {
			ret = append(ret, t.Value)
		} else {
			// Validate the binary literal string.
			// See https://github.com/pingcap/tidb/issues/30740.
			r, _ := enc.Transform(nil, charset.HackSlice(t.Value), charset.OpDecodeNoErr)
			ret = append(ret, charset.HackString(r))
		}
	}
	return ret
}

type BinaryLiteral interface {
	ToString() string
}

// NewDecimal creates a types.Decimal value, it's provided by parser driver.
var NewDecimal func(string) (interface{}, error)

// NewHexLiteral creates a types.HexLiteral value, it's provided by parser driver.
var NewHexLiteral func(string) (interface{}, error)

// NewBitLiteral creates a types.BitLiteral value, it's provided by parser driver.
var NewBitLiteral func(string) (interface{}, error)
