// Copyright 2017 PingCAP, Inc.
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
	"github.com/pingcap/errors"
	"github.com/pingcap/tidb/parser/format"
	"github.com/pingcap/tidb/parser/model"
	"github.com/pingcap/tidb/parser/sql_ir"
	"strconv"
)

var (
	_ StmtNode = &AnalyzeTableStmt{}
	_ StmtNode = &DropStatsStmt{}
	_ StmtNode = &LoadStatsStmt{}
)

// AnalyzeTableStmt is used to create table statistics.
type AnalyzeTableStmt struct {
	stmtNode

	TableNames     []*TableName
	PartitionNames []model.CIStr
	IndexNames     []model.CIStr
	AnalyzeOpts    []AnalyzeOpt

	// IndexFlag is true when we only analyze indices for a table.
	IndexFlag   bool
	Incremental bool
	// HistogramOperation is set in "ANALYZE TABLE ... UPDATE/DROP HISTOGRAM ..." statement.
	HistogramOperation HistogramOperationType
	// ColumnNames indicate the columns whose statistics need to be collected.
	ColumnNames  []model.CIStr
	ColumnChoice model.ColumnChoice
}

// AnalyzeOptType is the type for analyze options.
type AnalyzeOptionType int

// Analyze option types.
const (
	AnalyzeOptNumBuckets = iota
	AnalyzeOptNumTopN
	AnalyzeOptCMSketchDepth
	AnalyzeOptCMSketchWidth
	AnalyzeOptNumSamples
	AnalyzeOptSampleRate
)

// AnalyzeOptionString stores the string form of analyze options.
var AnalyzeOptionString = map[AnalyzeOptionType]string{
	AnalyzeOptNumBuckets:    "BUCKETS",
	AnalyzeOptNumTopN:       "TOPN",
	AnalyzeOptCMSketchWidth: "CMSKETCH WIDTH",
	AnalyzeOptCMSketchDepth: "CMSKETCH DEPTH",
	AnalyzeOptNumSamples:    "SAMPLES",
	AnalyzeOptSampleRate:    "SAMPLERATE",
}

// HistogramOperationType is the type for histogram operation.
type HistogramOperationType int

// Histogram operation types.
const (
	// HistogramOperationNop shows no operation in histogram. Default value.
	HistogramOperationNop HistogramOperationType = iota
	HistogramOperationUpdate
	HistogramOperationDrop
)

// String implements fmt.Stringer for HistogramOperationType.
func (hot HistogramOperationType) String() string {
	switch hot {
	case HistogramOperationUpdate:
		return "UPDATE HISTOGRAM"
	case HistogramOperationDrop:
		return "DROP HISTOGRAM"
	}
	return ""
}

// AnalyzeOpt stores the analyze option type and value.
type AnalyzeOpt struct {
	Type  AnalyzeOptionType
	Value ValueExpr
}

func (n *AnalyzeTableStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := ""
	if n.Incremental {
		prefix += "ANALYZE INCREMENTAL TABLE "
	} else {
		prefix += "ANALYZE TABLE "
	}

	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, table := range n.TableNames {
		tmpMidfix := ""
		if i != 0 {
			tmpMidfix = ","
		}
		tableNode := table.LogCurrentNode(depth + 1)
		tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(tableNode, sql_ir.DataTableName)
		for _, tableNameNode := range tableNameNodeList {
			tableNameNode.DataType = sql_ir.DataTableName
			tableNameNode.ContextFlag = sql_ir.ContextUse
		}

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
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    tmpRootNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	midfix := ""
	if len(n.PartitionNames) != 0 {
		midfix = " PARTITION "
	}
	tmpRootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, partition := range n.PartitionNames {
		tmpMidfix := ""
		if i != 0 {
			tmpMidfix = ", "
		}
		partitionNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataPartitionName,
			ContextFlag: sql_ir.ContextUse,
			Str:         partition.O,
			Depth:       depth,
		}
		if i == 0 {
			tmpRootNode.LNode = partitionNode
		} else {
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    partitionNode,
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

	tmpRootNode = nil
	if n.HistogramOperation != HistogramOperationNop {
		midfix += " " + (n.HistogramOperation.String()) + " "
		if len(n.ColumnNames) > 0 {
			midfix += "ON "
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				Depth:    depth,
			}
			for i, columnName := range n.ColumnNames {
				tmpMidfix := ""
				if i != 0 {
					tmpMidfix = ","
				}
				columnNameNode := &sql_ir.SqlRsgIR{
					IRType:      sql_ir.TypeIdentifier,
					DataType:    sql_ir.DataColumnName,
					ContextFlag: sql_ir.ContextUse,
					Str:         columnName.O,
					Depth:       depth,
				}
				if i == 0 {
					tmpRootNode.LNode = columnNameNode
				} else { // i > 0
					tmpRootNode = &sql_ir.SqlRsgIR{
						IRType:   sql_ir.TypeUnknown,
						DataType: sql_ir.DataNone,
						LNode:    tmpRootNode,
						RNode:    columnNameNode,
						Infix:    tmpMidfix,
						Depth:    depth,
					}
				}
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

	switch n.ColumnChoice {
	case model.AllColumns:
		midfix = " ALL COLUMNS"
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			Infix:    midfix,
			Depth:    depth,
		}
	case model.PredicateColumns:
		midfix = " PREDICATE COLUMNS"
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			Infix:    midfix,
			Depth:    depth,
		}
	case model.ColumnList:
		midfix = " COLUMNS "
		tmpRootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for i, columnName := range n.ColumnNames {
			tmpMidfix := ""
			if i != 0 {
				tmpMidfix = ","
			}
			columnName := &sql_ir.SqlRsgIR{
				IRType:      sql_ir.TypeIdentifier,
				DataType:    sql_ir.DataColumnName,
				ContextFlag: sql_ir.ContextUse,
				Str:         columnName.O,
				Depth:       depth,
			}

			if i == 0 {
				tmpRootNode.LNode = columnName
			} else {
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    columnName,
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
	}

	midfix = ""
	if n.IndexFlag {
		midfix += " INDEX"
	}

	tmpRootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, index := range n.IndexNames {
		tmpMidfix := ""
		if i != 0 {
			tmpMidfix = ","
		} else {
			tmpMidfix = " "
		}
		indexNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataIndexName,
			ContextFlag: sql_ir.ContextUse,
			Str:         index.O,
			Depth:       depth,
		}
		if i == 0 {
			tmpRootNode.LNode = indexNode
		} else { // i > 0
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

	midfix = ""
	if len(n.AnalyzeOpts) != 0 {
		midfix = " WITH"
		tmpRootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for i, opt := range n.AnalyzeOpts {
			tmpMidfix := ""
			if i != 0 {
				tmpMidfix = ","
			}
			valueNode := &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeIntegerLiteral,
				DataType: sql_ir.DataNone,
				IValue:   0,
				Str:      strconv.FormatInt(int64(0), 10),
				Depth:    depth,
			}
			tmptmpRootNode := &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    valueNode,
				Infix:    AnalyzeOptionString[opt.Type],
				Depth:    depth,
			}
			if i == 0 {
				tmpRootNode.LNode = tmptmpRootNode
			} else { // i > 0
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    tmptmpRootNode,
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

	rootNode.IRType = sql_ir.TypeAnalyzeTableStmt

	return rootNode
}

// Restore implements Node interface.
func (n *AnalyzeTableStmt) Restore(ctx *format.RestoreCtx) error {
	if n.Incremental {
		ctx.WriteKeyWord("ANALYZE INCREMENTAL TABLE ")
	} else {
		ctx.WriteKeyWord("ANALYZE TABLE ")
	}
	for i, table := range n.TableNames {
		if i != 0 {
			ctx.WritePlain(",")
		}
		if err := table.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore AnalyzeTableStmt.TableNames[%d]", i)
		}
	}
	if len(n.PartitionNames) != 0 {
		ctx.WriteKeyWord(" PARTITION ")
	}
	for i, partition := range n.PartitionNames {
		if i != 0 {
			ctx.WritePlain(",")
		}
		ctx.WriteName(partition.O)
	}
	if n.HistogramOperation != HistogramOperationNop {
		ctx.WritePlain(" ")
		ctx.WriteKeyWord(n.HistogramOperation.String())
		ctx.WritePlain(" ")
		if len(n.ColumnNames) > 0 {
			ctx.WriteKeyWord("ON ")
			for i, columnName := range n.ColumnNames {
				if i != 0 {
					ctx.WritePlain(",")
				}
				ctx.WriteName(columnName.O)
			}
		}
	}
	switch n.ColumnChoice {
	case model.AllColumns:
		ctx.WriteKeyWord(" ALL COLUMNS")
	case model.PredicateColumns:
		ctx.WriteKeyWord(" PREDICATE COLUMNS")
	case model.ColumnList:
		ctx.WriteKeyWord(" COLUMNS ")
		for i, columnName := range n.ColumnNames {
			if i != 0 {
				ctx.WritePlain(",")
			}
			ctx.WriteName(columnName.O)
		}
	}
	if n.IndexFlag {
		ctx.WriteKeyWord(" INDEX")
	}
	for i, index := range n.IndexNames {
		if i != 0 {
			ctx.WritePlain(",")
		} else {
			ctx.WritePlain(" ")
		}
		ctx.WriteName(index.O)
	}
	if len(n.AnalyzeOpts) != 0 {
		ctx.WriteKeyWord(" WITH")
		for i, opt := range n.AnalyzeOpts {
			if i != 0 {
				ctx.WritePlain(",")
			}
			ctx.WritePlainf(" %v ", opt.Value.GetValue())
			ctx.WritePlain(AnalyzeOptionString[opt.Type])
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *AnalyzeTableStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*AnalyzeTableStmt)
	for i, val := range n.TableNames {
		node, ok := val.Accept(v)
		if !ok {
			return n, false
		}
		n.TableNames[i] = node.(*TableName)
	}
	return v.Leave(n)
}

// DropStatsStmt is used to drop table statistics.
type DropStatsStmt struct {
	stmtNode

	Table          *TableName
	PartitionNames []model.CIStr
	IsGlobalStats  bool
}

func (n *DropStatsStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "DROP STATS "

	lNode := n.Table.LogCurrentNode(depth + 1)
	tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(lNode, sql_ir.DataTableName)
	for _, tableNameNode := range tableNameNodeList {
		tableNameNode.DataType = sql_ir.DataTableName
		tableNameNode.ContextFlag = sql_ir.ContextUse
	}

	midfix := ""
	if n.IsGlobalStats {
		midfix += " GLOBAL"
		rootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    lNode,
			Prefix:   prefix,
			Infix:    midfix,
			Depth:    depth,
		}
		rootNode.IRType = sql_ir.TypeDropStatsStmt
		return rootNode
	}

	if len(n.PartitionNames) != 0 {
		midfix += " PARTITION "
	}

	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, partition := range n.PartitionNames {
		tmpMidfix := ""
		if i != 0 {
			tmpMidfix = ","
		}
		partitionNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataPartitionName,
			ContextFlag: sql_ir.ContextUse,
			Str:         partition.O,
			Depth:       depth,
		}
		if i == 0 {
			tmpRootNode.LNode = partitionNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    partitionNode,
				Infix:    tmpMidfix,
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

	rootNode.IRType = sql_ir.TypeDropStatsStmt
	return rootNode

}

// Restore implements Node interface.
func (n *DropStatsStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("DROP STATS ")
	if err := n.Table.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while add table")
	}

	if n.IsGlobalStats {
		ctx.WriteKeyWord(" GLOBAL")
		return nil
	}

	if len(n.PartitionNames) != 0 {
		ctx.WriteKeyWord(" PARTITION ")
	}
	for i, partition := range n.PartitionNames {
		if i != 0 {
			ctx.WritePlain(",")
		}
		ctx.WriteName(partition.O)
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *DropStatsStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*DropStatsStmt)
	node, ok := n.Table.Accept(v)
	if !ok {
		return n, false
	}
	n.Table = node.(*TableName)
	return v.Leave(n)
}

// LoadStatsStmt is the statement node for loading statistic.
type LoadStatsStmt struct {
	stmtNode

	Path string
}

func (n *LoadStatsStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "LOAD STATS " + n.Path
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeLoadStatsStmt
	return rootNode
}

// Restore implements Node interface.
func (n *LoadStatsStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("LOAD STATS ")
	ctx.WriteString(n.Path)
	return nil
}

// Accept implements Node Accept interface.
func (n *LoadStatsStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*LoadStatsStmt)
	return v.Leave(n)
}
