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
	"github.com/pingcap/errors"
	"github.com/pingcap/tidb/parser/auth"
	"github.com/pingcap/tidb/parser/format"
	"github.com/pingcap/tidb/parser/model"
	"github.com/pingcap/tidb/parser/mysql"
	"github.com/pingcap/tidb/parser/sql_ir"
	"github.com/pingcap/tidb/parser/terror"
	"github.com/pingcap/tidb/parser/tidb"
	"github.com/pingcap/tidb/parser/types"
	"strconv"
)

var (
	_ DDLNode = &AlterTableStmt{}
	_ DDLNode = &AlterSequenceStmt{}
	_ DDLNode = &AlterPlacementPolicyStmt{}
	_ DDLNode = &CreateDatabaseStmt{}
	_ DDLNode = &CreateIndexStmt{}
	_ DDLNode = &CreateTableStmt{}
	_ DDLNode = &CreateViewStmt{}
	_ DDLNode = &CreateSequenceStmt{}
	_ DDLNode = &CreatePlacementPolicyStmt{}
	_ DDLNode = &DropDatabaseStmt{}
	_ DDLNode = &DropIndexStmt{}
	_ DDLNode = &DropTableStmt{}
	_ DDLNode = &DropSequenceStmt{}
	_ DDLNode = &DropPlacementPolicyStmt{}
	_ DDLNode = &RenameTableStmt{}
	_ DDLNode = &TruncateTableStmt{}
	_ DDLNode = &RepairTableStmt{}

	_ Node = &AlterTableSpec{}
	_ Node = &ColumnDef{}
	_ Node = &ColumnOption{}
	_ Node = &ColumnPosition{}
	_ Node = &Constraint{}
	_ Node = &IndexPartSpecification{}
	_ Node = &ReferenceDef{}
)

// CharsetOpt is used for parsing charset option from SQL.
type CharsetOpt struct {
	Chs string
	Col string
}

// NullString represents a string that may be nil.
type NullString struct {
	String string
	Empty  bool // Empty is true if String is empty backtick.
}

// DatabaseOptionType is the type for database options.
type DatabaseOptionType int

// Database option types.
const (
	DatabaseOptionNone DatabaseOptionType = iota
	DatabaseOptionCharset
	DatabaseOptionCollate
	DatabaseOptionEncryption
	DatabaseSetTiFlashReplica
	DatabaseOptionPlacementPolicy = DatabaseOptionType(PlacementOptionPolicy)
)

// DatabaseOption represents database option.
type DatabaseOption struct {
	Tp             DatabaseOptionType
	Value          string
	UintValue      uint64
	TiFlashReplica *TiFlashReplicaSpec

	sql_ir.SqlRsgInterface
}

func (n *DatabaseOption) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	var rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	switch n.Tp {
	case DatabaseOptionCharset:
		prefix := "CHARACTER SET = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataCharSet,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.Value,
			Prefix:      prefix,
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
		}
		prefix = ""
		rootNode.LNode = lNode
	case DatabaseOptionCollate:
		prefix := "COLLATE = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataCollationName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.Value,
			Prefix:      prefix,
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
		}
		prefix = ""
		rootNode.LNode = lNode
	case DatabaseOptionEncryption:
		prefix := "ENCRYPTION = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataEncryptionName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.Value,
			Prefix:      prefix,
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
		}
		prefix = ""
		rootNode.LNode = lNode
	case DatabaseOptionPlacementPolicy:
		placementOpt := PlacementOption{
			Tp:        PlacementOptionPolicy,
			UintValue: n.UintValue,
			StrValue:  n.Value,
		}
		lNode := placementOpt.LogCurrentNode(depth + 1)
		rootNode.LNode = lNode
	case DatabaseSetTiFlashReplica:
		prefix := "SET TIFLASH REPLICA "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			IValue:   int64(n.TiFlashReplica.Count),
			Str:      strconv.FormatUint(n.TiFlashReplica.Count, 10),
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		midfix := ""
		if len(n.TiFlashReplica.Labels) != 0 {
			midfix = " LOCATION LABELS \"zone\" "
		}

		rootNode.Prefix = prefix
		rootNode.Infix = midfix
		rootNode.LNode = lNode
	}

	return rootNode
}

// Restore implements Node interface.
func (n *DatabaseOption) Restore(ctx *format.RestoreCtx) error {
	switch n.Tp {
	case DatabaseOptionCharset:
		ctx.WriteKeyWord("CHARACTER SET")
		ctx.WritePlain(" = ")
		ctx.WritePlain(n.Value)
	case DatabaseOptionCollate:
		ctx.WriteKeyWord("COLLATE")
		ctx.WritePlain(" = ")
		ctx.WritePlain(n.Value)
	case DatabaseOptionEncryption:
		ctx.WriteKeyWord("ENCRYPTION")
		ctx.WritePlain(" = ")
		ctx.WriteString(n.Value)
	case DatabaseOptionPlacementPolicy:
		placementOpt := PlacementOption{
			Tp:        PlacementOptionPolicy,
			UintValue: n.UintValue,
			StrValue:  n.Value,
		}
		return placementOpt.Restore(ctx)
	case DatabaseSetTiFlashReplica:
		ctx.WriteKeyWord("SET TIFLASH REPLICA ")
		ctx.WritePlainf("%d", n.TiFlashReplica.Count)
		if len(n.TiFlashReplica.Labels) == 0 {
			break
		}
		ctx.WriteKeyWord(" LOCATION LABELS ")
		for i, v := range n.TiFlashReplica.Labels {
			if i > 0 {
				ctx.WritePlain(", ")
			}
			ctx.WriteString(v)
		}
	default:
		return errors.Errorf("invalid DatabaseOptionType: %d", n.Tp)
	}
	return nil
}

// CreateDatabaseStmt is a statement to create a database.
// See https://dev.mysql.com/doc/refman/5.7/en/create-database.html
type CreateDatabaseStmt struct {
	ddlNode

	IfNotExists bool
	Name        string
	Options     []*DatabaseOption

	sql_ir.SqlRsgInterface
}

func (n *CreateDatabaseStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}
	prefix := "CREATE DATABASE "
	if n.IfNotExists {
		prefix += "IF NOT EXISTS "
	}

	lNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataDatabaseName,
		ContextFlag: sql_ir.ContextDefine,
		Str:         n.Name,
		Depth:       depth + 1,
	}

	rootNode.LNode = lNode
	rootNode.Prefix = prefix

	for _, option := range n.Options {
		rNode := option.LogCurrentNode(depth + 1)
		midfix := " "

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Infix:    midfix,
			Depth:    depth,
		}
	}

	rootNode.IRType = sql_ir.TypeCreateDatabaseStmt
	return rootNode
}

// Restore implements Node interface.
func (n *CreateDatabaseStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("CREATE DATABASE ")
	if n.IfNotExists {
		ctx.WriteKeyWord("IF NOT EXISTS ")
	}
	ctx.WriteName(n.Name)
	for i, option := range n.Options {
		ctx.WritePlain(" ")
		err := option.Restore(ctx)
		if err != nil {
			return errors.Annotatef(err, "An error occurred while splicing CreateDatabaseStmt DatabaseOption: [%v]", i)
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *CreateDatabaseStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*CreateDatabaseStmt)
	return v.Leave(n)
}

// AlterDatabaseStmt is a statement to change the structure of a database.
// See https://dev.mysql.com/doc/refman/5.7/en/alter-database.html
type AlterDatabaseStmt struct {
	ddlNode

	Name                 string
	AlterDefaultDatabase bool
	Options              []*DatabaseOption
}

func (n *AlterDatabaseStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if n.isAllPlacementOptions() {
		rootNode.IRType = sql_ir.TypeUnknown
		return rootNode
	}

	/* We should ignore this line. Seems to be a special comment setting flag,
	 * but does not impact the query parsing process.
	 */
	//if n.isAllPlacementOptions() && ctx.Flags.HasTiDBSpecialCommentFlag() {
	//	return LogCurrentNodePlacementStmtInSpecialComment(n)
	//}

	prefix := "ALTER DATABASE "
	if !n.AlterDefaultDatabase {
		nameNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataDatabaseName,
			ContextFlag: sql_ir.ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
		}
		rootNode.LNode = nameNode
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		prefix = ""
	} else {
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		prefix = ""
	}

	for _, option := range n.Options {
		midfix := " "
		rNode := option.LogCurrentNode(depth + 1)
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Prefix:   "",
			Infix:    midfix,
			Suffix:   "",
			Depth:    depth,
		}
	}
	rootNode.IRType = sql_ir.TypeAlterDatabaseStmt
	return rootNode

}

// Restore implements Node interface.
func (n *AlterDatabaseStmt) Restore(ctx *format.RestoreCtx) error {
	if ctx.Flags.HasSkipPlacementRuleForRestoreFlag() && n.isAllPlacementOptions() {
		return nil
	}
	// If all options placement options and RestoreTiDBSpecialComment flag is on,
	// we should restore the whole node in special comment. For example, the restore result should be:
	// /*T![placement] ALTER DATABASE `db1` PLACEMENT POLICY = `p1` */
	// instead of
	// ALTER DATABASE `db1` /*T![placement] PLACEMENT POLICY = `p1` */
	// because altering a database without any options is not a legal syntax in mysql
	if n.isAllPlacementOptions() && ctx.Flags.HasTiDBSpecialCommentFlag() {
		return restorePlacementStmtInSpecialComment(ctx, n)
	}

	ctx.WriteKeyWord("ALTER DATABASE")
	if !n.AlterDefaultDatabase {
		ctx.WritePlain(" ")
		ctx.WriteName(n.Name)
	}
	for i, option := range n.Options {
		ctx.WritePlain(" ")
		err := option.Restore(ctx)
		if err != nil {
			return errors.Annotatef(err, "An error occurred while splicing AlterDatabaseStmt DatabaseOption: [%v]", i)
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *AlterDatabaseStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*AlterDatabaseStmt)
	return v.Leave(n)
}

func (n *AlterDatabaseStmt) isAllPlacementOptions() bool {
	for _, n := range n.Options {
		switch n.Tp {
		case DatabaseOptionPlacementPolicy:
		default:
			return false
		}
	}
	return true
}

// DropDatabaseStmt is a statement to drop a database and all tables in the database.
// See https://dev.mysql.com/doc/refman/5.7/en/drop-database.html
type DropDatabaseStmt struct {
	ddlNode

	IfExists bool
	Name     string
}

func (n *DropDatabaseStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}
	prefix := "DROP DATABASE "
	if n.IfExists {
		prefix += "IF EXISTS "
	}
	nameNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataDatabaseName,
		ContextFlag: sql_ir.ContextUndefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
	}
	rootNode.LNode = nameNode
	rootNode.Prefix = prefix
	rootNode.IRType = sql_ir.TypeDropDatabaseStmt

	return rootNode
}

// Restore implements Node interface.
func (n *DropDatabaseStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("DROP DATABASE ")
	if n.IfExists {
		ctx.WriteKeyWord("IF EXISTS ")
	}
	ctx.WriteName(n.Name)
	return nil
}

// Accept implements Node Accept interface.
func (n *DropDatabaseStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*DropDatabaseStmt)
	return v.Leave(n)
}

// IndexPartSpecifications is used for parsing index column name or index expression from SQL.
type IndexPartSpecification struct {
	node

	Column *ColumnName
	Length int
	Expr   ExprNode
}

func (n *IndexPartSpecification) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if n.Expr != nil {
		lNode := n.Expr.LogCurrentNode(depth + 1)
		rootNode.LNode = lNode
		rootNode.Prefix = "("
		rootNode.Infix = ")"
	}
	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}
	rNode := n.Column.LogCurrentNode(depth + 1)
	columnNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(rNode, sql_ir.DataColumnName)
	for _, columnNameNode := range columnNameNodeList {
		columnNameNode.DataType = sql_ir.DataColumnName
		columnNameNode.ContextFlag = sql_ir.ContextUse
	}

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    rNode,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}
	if n.Length > 0 {
		rNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			Str:      strconv.FormatInt(int64(n.Length), 10),
			IValue:   int64(n.Length),
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Prefix:   "",
			Infix:    "(",
			Suffix:   ")",
			Depth:    depth,
		}
	}
	rootNode.IRType = sql_ir.TypeIndexPartSpecification
	return rootNode
}

// Restore implements Node interface.
func (n *IndexPartSpecification) Restore(ctx *format.RestoreCtx) error {
	if n.Expr != nil {
		ctx.WritePlain("(")
		if err := n.Expr.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while splicing IndexPartSpecifications")
		}
		ctx.WritePlain(")")
		return nil
	}
	if err := n.Column.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while splicing IndexPartSpecifications")
	}
	if n.Length > 0 {
		ctx.WritePlainf("(%d)", n.Length)
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *IndexPartSpecification) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*IndexPartSpecification)
	if n.Expr != nil {
		node, ok := n.Expr.Accept(v)
		if !ok {
			return n, false
		}
		n.Expr = node.(ExprNode)
		return v.Leave(n)
	}
	node, ok := n.Column.Accept(v)
	if !ok {
		return n, false
	}
	n.Column = node.(*ColumnName)
	return v.Leave(n)
}

// MatchType is the type for reference match type.
type MatchType int

// match type
const (
	MatchNone MatchType = iota
	MatchFull
	MatchPartial
	MatchSimple
)

// ReferenceDef is used for parsing foreign key reference option from SQL.
// See http://dev.mysql.com/doc/refman/5.7/en/create-table-foreign-keys.html
type ReferenceDef struct {
	node

	Table                   *TableName
	IndexPartSpecifications []*IndexPartSpecification
	OnDelete                *OnDeleteOpt
	OnUpdate                *OnUpdateOpt
	Match                   MatchType
}

func (n *ReferenceDef) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if n.Table != nil {
		prefix := "REFERENCES "
		lNode := n.Table.LogCurrentNode(depth + 1)
		tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(lNode, sql_ir.DataTableName)
		for _, tableNameNode := range tableNameNodeList {
			tableNameNode.DataType = sql_ir.DataTableName
			tableNameNode.ContextFlag = sql_ir.ContextUse
		}

		rootNode.LNode = lNode
		rootNode.Prefix = prefix
	}
	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if n.IndexPartSpecifications != nil {
		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		for i, indexColNames := range n.IndexPartSpecifications {
			midfix := " "
			if i > 0 {
				midfix = ", "
			}
			curColNameNode := indexColNames.LogCurrentNode(depth + 1)
			if i == 0 {
				tmpRootNode.LNode = curColNameNode
				tmpRootNode.Infix = midfix
			} else { // i > 0
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    curColNameNode,
					Prefix:   "",
					Infix:    midfix,
					Suffix:   "",
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
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}
	if n.Match != MatchNone {
		tmpPrefix := " MATCH "
		switch n.Match {
		case MatchFull:
			tmpPrefix += "FULL "
		case MatchPartial:
			tmpPrefix += "PARTIAL "
		case MatchSimple:
			tmpPrefix += "SIMPLE "
		}
		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Prefix:   tmpPrefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    tmpRootNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	if n.OnDelete.ReferOpt != ReferOptionNoOption {
		midfix := " "
		rNode := n.OnDelete.LogCurrentNode(depth + 1)
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Prefix:   "",
			Infix:    midfix,
			Suffix:   "",
			Depth:    depth,
		}
	}
	if n.OnUpdate.ReferOpt != ReferOptionNoOption {
		midfix := " "
		rNode := n.OnUpdate.LogCurrentNode(depth + 1)
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Prefix:   "",
			Infix:    midfix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootNode.IRType = sql_ir.TypeReferenceDef
	return rootNode

}

// Restore implements Node interface.
func (n *ReferenceDef) Restore(ctx *format.RestoreCtx) error {
	if n.Table != nil {
		ctx.WriteKeyWord("REFERENCES ")
		if err := n.Table.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while splicing ReferenceDef")
		}
	}

	if n.IndexPartSpecifications != nil {
		ctx.WritePlain("(")
		for i, indexColNames := range n.IndexPartSpecifications {
			if i > 0 {
				ctx.WritePlain(", ")
			}
			if err := indexColNames.Restore(ctx); err != nil {
				return errors.Annotatef(err, "An error occurred while splicing IndexPartSpecifications: [%v]", i)
			}
		}
		ctx.WritePlain(")")
	}

	if n.Match != MatchNone {
		ctx.WriteKeyWord(" MATCH ")
		switch n.Match {
		case MatchFull:
			ctx.WriteKeyWord("FULL")
		case MatchPartial:
			ctx.WriteKeyWord("PARTIAL")
		case MatchSimple:
			ctx.WriteKeyWord("SIMPLE")
		}
	}
	if n.OnDelete.ReferOpt != ReferOptionNoOption {
		ctx.WritePlain(" ")
		if err := n.OnDelete.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while splicing OnDelete")
		}
	}
	if n.OnUpdate.ReferOpt != ReferOptionNoOption {
		ctx.WritePlain(" ")
		if err := n.OnUpdate.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while splicing OnUpdate")
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *ReferenceDef) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*ReferenceDef)
	if n.Table != nil {
		node, ok := n.Table.Accept(v)
		if !ok {
			return n, false
		}
		n.Table = node.(*TableName)
	}
	for i, val := range n.IndexPartSpecifications {
		node, ok := val.Accept(v)
		if !ok {
			return n, false
		}
		n.IndexPartSpecifications[i] = node.(*IndexPartSpecification)
	}
	onDelete, ok := n.OnDelete.Accept(v)
	if !ok {
		return n, false
	}
	n.OnDelete = onDelete.(*OnDeleteOpt)
	onUpdate, ok := n.OnUpdate.Accept(v)
	if !ok {
		return n, false
	}
	n.OnUpdate = onUpdate.(*OnUpdateOpt)
	return v.Leave(n)
}

// ReferOptionType is the type for refer options.
type ReferOptionType int

// Refer option types.
const (
	ReferOptionNoOption ReferOptionType = iota
	ReferOptionRestrict
	ReferOptionCascade
	ReferOptionSetNull
	ReferOptionNoAction
	ReferOptionSetDefault
)

// String implements fmt.Stringer interface.
func (r ReferOptionType) String() string {
	switch r {
	case ReferOptionRestrict:
		return "RESTRICT"
	case ReferOptionCascade:
		return "CASCADE"
	case ReferOptionSetNull:
		return "SET NULL"
	case ReferOptionNoAction:
		return "NO ACTION"
	case ReferOptionSetDefault:
		return "SET DEFAULT"
	}
	return ""
}

// OnDeleteOpt is used for optional on delete clause.
type OnDeleteOpt struct {
	node
	ReferOpt ReferOptionType
}

func (n *OnDeleteOpt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := ""
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if n.ReferOpt != ReferOptionNoOption {
		prefix += "ON DELETE "
		prefix += n.ReferOpt.String()
	}
	rootNode.Prefix = prefix
	rootNode.IRType = sql_ir.TypeOnDeleteOpt
	return rootNode

}

// Restore implements Node interface.
func (n *OnDeleteOpt) Restore(ctx *format.RestoreCtx) error {
	if n.ReferOpt != ReferOptionNoOption {
		ctx.WriteKeyWord("ON DELETE ")
		ctx.WriteKeyWord(n.ReferOpt.String())
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *OnDeleteOpt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*OnDeleteOpt)
	return v.Leave(n)
}

// OnUpdateOpt is used for optional on update clause.
type OnUpdateOpt struct {
	node
	ReferOpt ReferOptionType
}

func (n *OnUpdateOpt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := ""
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if n.ReferOpt != ReferOptionNoOption {
		prefix += "ON UPDATE "
		prefix += n.ReferOpt.String()
	}
	rootNode.Prefix = prefix
	rootNode.IRType = sql_ir.TypeOnUpdateOpt
	return rootNode

}

// Restore implements Node interface.
func (n *OnUpdateOpt) Restore(ctx *format.RestoreCtx) error {
	if n.ReferOpt != ReferOptionNoOption {
		ctx.WriteKeyWord("ON UPDATE ")
		ctx.WriteKeyWord(n.ReferOpt.String())
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *OnUpdateOpt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*OnUpdateOpt)
	return v.Leave(n)
}

// ColumnOptionType is the type for ColumnOption.
type ColumnOptionType int

// ColumnOption types.
const (
	ColumnOptionNoOption ColumnOptionType = iota
	ColumnOptionPrimaryKey
	ColumnOptionNotNull
	ColumnOptionAutoIncrement
	ColumnOptionDefaultValue
	ColumnOptionUniqKey
	ColumnOptionNull
	ColumnOptionOnUpdate // For Timestamp and Datetime only.
	ColumnOptionFulltext
	ColumnOptionComment
	ColumnOptionGenerated
	ColumnOptionReference
	ColumnOptionCollate
	ColumnOptionCheck
	ColumnOptionColumnFormat
	ColumnOptionStorage
	ColumnOptionAutoRandom
)

var (
	invalidOptionForGeneratedColumn = map[ColumnOptionType]struct{}{
		ColumnOptionAutoIncrement: {},
		ColumnOptionOnUpdate:      {},
		ColumnOptionDefaultValue:  {},
	}
)

// ColumnOption is used for parsing column constraint info from SQL.
type ColumnOption struct {
	node

	Tp ColumnOptionType
	// Expr is used for ColumnOptionDefaultValue/ColumnOptionOnUpdateColumnOptionGenerated.
	// For ColumnOptionDefaultValue or ColumnOptionOnUpdate, it's the target value.
	// For ColumnOptionGenerated, it's the target expression.
	Expr ExprNode
	// Stored is only for ColumnOptionGenerated, default is false.
	Stored bool
	// Refer is used for foreign key.
	Refer               *ReferenceDef
	StrValue            string
	AutoRandomBitLength int
	// Enforced is only for Check, default is true.
	Enforced bool
	// Name is only used for Check Constraint nameContextUnknown.
	ConstraintName string
	PrimaryKeyTp   model.PrimaryKeyType
}

func (n *ColumnOption) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	switch n.Tp {
	case ColumnOptionNoOption:
		rootNode.IRType = sql_ir.TypeColumnOption
		return rootNode
	case ColumnOptionPrimaryKey:
		prefix := " PRIMARY KEY " + n.PrimaryKeyTp.String()
		rootNode.Prefix = prefix
		rootNode.IRType = sql_ir.TypeColumnOption
		return rootNode
	case ColumnOptionNotNull:
		prefix := " NOT NULL "
		rootNode.Prefix = prefix
		rootNode.IRType = sql_ir.TypeColumnOption
		return rootNode
	case ColumnOptionAutoIncrement:
		prefix := " AUTO_INCREMENT "
		rootNode.Prefix = prefix
		rootNode.IRType = sql_ir.TypeColumnOption
		return rootNode
	case ColumnOptionDefaultValue:
		prefix := "DEFAULT "
		lNode := n.Expr.LogCurrentNode(depth + 1)
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
		rootNode.IRType = sql_ir.TypeColumnOption
		return rootNode
	case ColumnOptionUniqKey:
		prefix := " UNIQUE KEY "
		rootNode.Prefix = prefix
		rootNode.IRType = sql_ir.TypeColumnOption
		return rootNode
	case ColumnOptionNull:
		prefix := " NULL "
		rootNode.Prefix = prefix
		rootNode.IRType = sql_ir.TypeColumnOption
		return rootNode
	case ColumnOptionOnUpdate:
		prefix := " ON UPDATE "
		lNode := n.Expr.LogCurrentNode(depth + 1)
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
		rootNode.IRType = sql_ir.TypeColumnOption
		return rootNode
	case ColumnOptionFulltext:
		// Error
		rootNode.IRType = sql_ir.TypeColumnOption
		return rootNode
	case ColumnOptionComment:
		prefix := " COMMENT "
		lNode := n.Expr.LogCurrentNode(depth + 1)
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
		rootNode.IRType = sql_ir.TypeColumnOption
		return rootNode
	case ColumnOptionGenerated:
		prefix := "GENERATED ALWAYS AS "
		prefix += "("

		lNode := n.Expr.LogCurrentNode(depth + 1)
		midfix := ")"
		if n.Stored {
			midfix += " STORED "
		} else {
			midfix += " VIRTUAL "
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
		rootNode.Infix = midfix
		rootNode.IRType = sql_ir.TypeColumnOption
		return rootNode

	case ColumnOptionReference:
		lNode := n.Refer.LogCurrentNode(depth + 1)
		rootNode.LNode = lNode
		rootNode.IRType = sql_ir.TypeColumnOption
		return rootNode
	case ColumnOptionCollate:
		prefix := " COLLATE "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataCollationName,
			ContextFlag: sql_ir.ContextDefine, // TODO:: Not sure here.
			Str:         n.StrValue,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
		rootNode.IRType = sql_ir.TypeColumnOption
	case ColumnOptionCheck:
		prefix := ""
		if n.ConstraintName != "" {
			prefix += " CONSTRAINT "
			lNode := &sql_ir.SqlRsgIR{
				IRType:      sql_ir.TypeIdentifier,
				DataType:    sql_ir.DataConstraintName,
				ContextFlag: sql_ir.ContextDefine, // TODO:: Not sure here.
				Str:         n.ConstraintName,
				Depth:       depth,
			}
			rootNode.Prefix = prefix
			prefix = ""
			rootNode.Infix = " "
			rootNode.LNode = lNode
		}
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		midfix := " CHECK "
		midfix += " ( "
		rNode := n.Expr.LogCurrentNode(depth + 1)
		suffix := ")"
		if n.Enforced {
			suffix += " ENFORCED"
		} else {
			suffix += " NOT ENFORCED"
		}
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Prefix:   "",
			Infix:    midfix,
			Suffix:   suffix,
			Depth:    depth,
		}
		rootNode.IRType = sql_ir.TypeColumnOption
		return rootNode
	case ColumnOptionColumnFormat:
		prefix := " COLUMN_FORMAT " + n.StrValue
		rootNode.Prefix = prefix
		rootNode.IRType = sql_ir.TypeColumnOption
		return rootNode
	case ColumnOptionStorage:
		prefix := " STORAGE " + n.StrValue
		rootNode.Prefix = prefix
		rootNode.IRType = sql_ir.TypeColumnOption
		return rootNode
	case ColumnOptionAutoRandom:
		prefix := " AUTO_RANDOM ("
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			IValue:   int64(n.AutoRandomBitLength),
			Str:      strconv.FormatInt(int64(n.AutoRandomBitLength), 10),
			Depth:    depth,
		}
		midfix := ")"
		rootNode.Prefix = prefix
		rootNode.Infix = midfix
		rootNode.LNode = lNode
		rootNode.IRType = sql_ir.TypeColumnOption
		return rootNode
	default:
		rootNode.IRType = sql_ir.TypeColumnOption
		return rootNode
	}
	// Should not come here. Logic error?
	rootNode.IRType = sql_ir.TypeColumnOption
	return rootNode
}

// Restore implements Node interface.
func (n *ColumnOption) Restore(ctx *format.RestoreCtx) error {
	switch n.Tp {
	case ColumnOptionNoOption:
		return nil
	case ColumnOptionPrimaryKey:
		ctx.WriteKeyWord("PRIMARY KEY")
		pkTp := n.PrimaryKeyTp.String()
		if len(pkTp) != 0 {
			ctx.WritePlain(" ")
			_ = ctx.WriteWithSpecialComments(tidb.FeatureIDClusteredIndex, func() error {
				ctx.WriteKeyWord(pkTp)
				return nil
			})
		}
	case ColumnOptionNotNull:
		ctx.WriteKeyWord("NOT NULL")
	case ColumnOptionAutoIncrement:
		ctx.WriteKeyWord("AUTO_INCREMENT")
	case ColumnOptionDefaultValue:
		ctx.WriteKeyWord("DEFAULT ")
		if err := n.Expr.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while splicing ColumnOption DefaultValue Expr")
		}
	case ColumnOptionUniqKey:
		ctx.WriteKeyWord("UNIQUE KEY")
	case ColumnOptionNull:
		ctx.WriteKeyWord("NULL")
	case ColumnOptionOnUpdate:
		ctx.WriteKeyWord("ON UPDATE ")
		if err := n.Expr.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while splicing ColumnOption ON UPDATE Expr")
		}
	case ColumnOptionFulltext:
		return errors.New("TiDB Parser ignore the `ColumnOptionFulltext` type now")
	case ColumnOptionComment:
		ctx.WriteKeyWord("COMMENT ")
		if err := n.Expr.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while splicing ColumnOption COMMENT Expr")
		}
	case ColumnOptionGenerated:
		ctx.WriteKeyWord("GENERATED ALWAYS AS")
		ctx.WritePlain("(")
		if err := n.Expr.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while splicing ColumnOption GENERATED ALWAYS Expr")
		}
		ctx.WritePlain(")")
		if n.Stored {
			ctx.WriteKeyWord(" STORED")
		} else {
			ctx.WriteKeyWord(" VIRTUAL")
		}
	case ColumnOptionReference:
		if err := n.Refer.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while splicing ColumnOption ReferenceDef")
		}
	case ColumnOptionCollate:
		if n.StrValue == "" {
			return errors.New("Empty ColumnOption COLLATE")
		}
		ctx.WriteKeyWord("COLLATE ")
		ctx.WritePlain(n.StrValue)
	case ColumnOptionCheck:
		if n.ConstraintName != "" {
			ctx.WriteKeyWord("CONSTRAINT ")
			ctx.WriteName(n.ConstraintName)
			ctx.WritePlain(" ")
		}
		ctx.WriteKeyWord("CHECK")
		ctx.WritePlain("(")
		if err := n.Expr.Restore(ctx); err != nil {
			return errors.Trace(err)
		}
		ctx.WritePlain(")")
		if n.Enforced {
			ctx.WriteKeyWord(" ENFORCED")
		} else {
			ctx.WriteKeyWord(" NOT ENFORCED")
		}
	case ColumnOptionColumnFormat:
		ctx.WriteKeyWord("COLUMN_FORMAT ")
		ctx.WriteKeyWord(n.StrValue)
	case ColumnOptionStorage:
		ctx.WriteKeyWord("STORAGE ")
		ctx.WriteKeyWord(n.StrValue)
	case ColumnOptionAutoRandom:
		_ = ctx.WriteWithSpecialComments(tidb.FeatureIDAutoRandom, func() error {
			ctx.WriteKeyWord("AUTO_RANDOM")
			if n.AutoRandomBitLength != types.UnspecifiedLength {
				ctx.WritePlainf("(%d)", n.AutoRandomBitLength)
			}
			return nil
		})
	default:
		return errors.New("An error occurred while splicing ColumnOption")
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *ColumnOption) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*ColumnOption)
	if n.Expr != nil {
		node, ok := n.Expr.Accept(v)
		if !ok {
			return n, false
		}
		n.Expr = node.(ExprNode)
	}
	return v.Leave(n)
}

// IndexVisibility is the option for index visibility.
type IndexVisibility int

// IndexVisibility options.
const (
	IndexVisibilityDefault IndexVisibility = iota
	IndexVisibilityVisible
	IndexVisibilityInvisible
)

// IndexOption is the index options.
//
//	  KEY_BLOCK_SIZE [=] value
//	| index_type
//	| WITH PARSER parser_name
//	| COMMENT 'string'
//
// See http://dev.mysql.com/doc/refman/5.7/en/create-table.html
type IndexOption struct {
	node

	KeyBlockSize uint64
	Tp           model.IndexType
	Comment      string
	ParserName   model.CIStr
	Visibility   IndexVisibility
	PrimaryKeyTp model.PrimaryKeyType
}

func (n *IndexOption) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := ""
	if n.PrimaryKeyTp != model.PrimaryKeyTypeDefault {
		prefix += n.PrimaryKeyTp.String()
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if n.KeyBlockSize > 0 {

		midfix := " KEY_BLOCK_SIZE = "
		rNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			UValue:   n.KeyBlockSize,
			Depth:    depth,
		}

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Prefix:   "",
			Infix:    midfix,
			Suffix:   "",
			Depth:    depth,
		}

	}

	if n.Tp != model.IndexTypeInvalid {
		midfix := " USING " + n.Tp.String()

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			Prefix:   "",
			Infix:    midfix,
			Suffix:   "",
			Depth:    depth,
		}

	}

	if len(n.ParserName.O) > 0 {
		midfix := " WITH PARSER " + n.ParserName.O

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			Prefix:   "",
			Infix:    midfix,
			Suffix:   "",
			Depth:    depth,
		}

	}

	if n.Comment != "" {
		midfix := " COMMENT " + n.Comment

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			Prefix:   "",
			Infix:    midfix,
			Suffix:   "",
			Depth:    depth,
		}

	}

	if n.Visibility != IndexVisibilityDefault {

		midfix := " "
		switch n.Visibility {
		case IndexVisibilityVisible:
			midfix += "VISIBLE"
		case IndexVisibilityInvisible:
			midfix += "INVISIBLE"
		}

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			Prefix:   "",
			Infix:    midfix,
			Suffix:   "",
			Depth:    depth,
		}

	}
	rootNode.IRType = sql_ir.TypeIndexOption
	return rootNode

}

// Restore implements Node interface.
func (n *IndexOption) Restore(ctx *format.RestoreCtx) error {
	hasPrevOption := false
	if n.PrimaryKeyTp != model.PrimaryKeyTypeDefault {
		_ = ctx.WriteWithSpecialComments(tidb.FeatureIDClusteredIndex, func() error {
			ctx.WriteKeyWord(n.PrimaryKeyTp.String())
			return nil
		})
		hasPrevOption = true
	}
	if n.KeyBlockSize > 0 {
		if hasPrevOption {
			ctx.WritePlain(" ")
		}
		ctx.WriteKeyWord("KEY_BLOCK_SIZE")
		ctx.WritePlainf("=%d", n.KeyBlockSize)
		hasPrevOption = true
	}

	if n.Tp != model.IndexTypeInvalid {
		if hasPrevOption {
			ctx.WritePlain(" ")
		}
		ctx.WriteKeyWord("USING ")
		ctx.WritePlain(n.Tp.String())
		hasPrevOption = true
	}

	if len(n.ParserName.O) > 0 {
		if hasPrevOption {
			ctx.WritePlain(" ")
		}
		ctx.WriteKeyWord("WITH PARSER ")
		ctx.WriteName(n.ParserName.O)
		hasPrevOption = true
	}

	if n.Comment != "" {
		if hasPrevOption {
			ctx.WritePlain(" ")
		}
		ctx.WriteKeyWord("COMMENT ")
		ctx.WriteString(n.Comment)
		hasPrevOption = true
	}

	if n.Visibility != IndexVisibilityDefault {
		if hasPrevOption {
			ctx.WritePlain(" ")
		}
		switch n.Visibility {
		case IndexVisibilityVisible:
			ctx.WriteKeyWord("VISIBLE")
		case IndexVisibilityInvisible:
			ctx.WriteKeyWord("INVISIBLE")
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *IndexOption) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*IndexOption)
	return v.Leave(n)
}

// ConstraintType is the type for Constraint.
type ConstraintType int

// ConstraintTypes
const (
	ConstraintNoConstraint ConstraintType = iota
	ConstraintPrimaryKey
	ConstraintKey
	ConstraintIndex
	ConstraintUniq
	ConstraintUniqKey
	ConstraintUniqIndex
	ConstraintForeignKey
	ConstraintFulltext
	ConstraintCheck
)

// Constraint is constraint for table definition.
type Constraint struct {
	node

	// only supported by MariaDB 10.0.2+ (ADD {INDEX|KEY}, ADD FOREIGN KEY),
	// see https://mariadb.com/kb/en/library/alter-table/
	IfNotExists bool

	Tp   ConstraintType
	Name string

	Keys []*IndexPartSpecification // Used for PRIMARY KEY, UNIQUE, ......

	Refer *ReferenceDef // Used for foreign key.

	Option *IndexOption // Index Options

	Expr ExprNode // Used for Check

	Enforced bool // Used for Check

	InColumn bool // Used for Check

	InColumnName string // Used for Check
	IsEmptyIndex bool   // Used for Check
}

func (n *Constraint) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	switch n.Tp {
	case ConstraintNoConstraint:
		rootNode.IRType = sql_ir.TypeConstraint
		return rootNode
	case ConstraintPrimaryKey:
		prefix := " PRIMARY KEY "
		rootNode.Prefix = prefix
	case ConstraintKey:
		prefix := " KEY "
		if n.IfNotExists {
			prefix += " IF NOT EXISTS"
		}
		rootNode.Prefix = prefix
	case ConstraintIndex:
		prefix := " INDEX "
		if n.IfNotExists {
			prefix += " IF NOT EXISTS"
		}
	case ConstraintUniq:
		prefix := " UNIQUE "
		rootNode.Prefix = prefix
	case ConstraintUniqKey:
		prefix := " UNIQUE KEY "
		rootNode.Prefix = prefix
	case ConstraintUniqIndex:
		prefix := " UNIQUE INDEX "
		rootNode.Prefix = prefix
	case ConstraintFulltext:
		prefix := " FULLTEXT "
		rootNode.Prefix = prefix
	case ConstraintCheck:
		if n.Name != "" {
			prefix := " CONSTRAINT "
			nameNode := &sql_ir.SqlRsgIR{
				IRType:      sql_ir.TypeIdentifier,
				DataType:    sql_ir.DataConstraintName,
				ContextFlag: sql_ir.ContextUse, // TODO:: Not sure here
				Str:         n.Name,
				Depth:       depth,
			}
			rootNode.Prefix = prefix
			rootNode.LNode = nameNode
			rootNode.Infix = " "
		}
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		midfix := " CHECK ( "
		rNode := n.Expr.LogCurrentNode(depth + 1)
		suffix := ")"
		if n.Enforced {
			suffix += "ENFORCED"
		} else {
			suffix += "NOT ENFORCED"
		}
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Prefix:   "",
			Infix:    midfix,
			Suffix:   suffix,
			Depth:    depth,
		}
		rootNode.IRType = sql_ir.TypeConstraint
		return rootNode
	}

	if n.Tp == ConstraintForeignKey {
		prefix := " CONSTRAINT "
		midfix := " "
		var lNode *sql_ir.SqlRsgIR = nil
		if n.Name != "" {
			lNode = &sql_ir.SqlRsgIR{
				IRType:      sql_ir.TypeIdentifier,
				DataType:    sql_ir.DataConstraintName,
				ContextFlag: sql_ir.ContextUse, // TODO:: Not sure here.
				Str:         n.Name,
				Depth:       depth,
			}
		}
		midfix += "FOREIGN KEY "
		if n.IfNotExists {
			midfix += "IF NOT EXISTS "
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
		rootNode.Infix = midfix

	} else if n.Name != "" || n.IsEmptyIndex {
		prefix := " "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataConstraintName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.Name,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	}

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	midfix := " ( "
	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, keys := range n.Keys {
		tmpMidfix := ""
		if i > 0 {
			tmpMidfix = ", "
		}
		curKeyNode := keys.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = curKeyNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    curKeyNode,
				Prefix:   "",
				Infix:    tmpMidfix,
				Suffix:   "",
				Depth:    depth,
			}
		}
	}
	suffix := ")"
	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Prefix:   "",
		Infix:    midfix,
		Suffix:   suffix,
		Depth:    depth,
	}

	if n.Refer != nil {
		midfix = " "
		rNode := n.Refer.LogCurrentNode(depth + 1)
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Prefix:   "",
			Infix:    midfix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if n.Option != nil {
		midfix = " "
		rNode := n.Option.LogCurrentNode(depth + 1)
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Prefix:   "",
			Infix:    midfix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootNode.IRType = sql_ir.TypeConstraint
	return rootNode

}

// Restore implements Node interface.
func (n *Constraint) Restore(ctx *format.RestoreCtx) error {
	switch n.Tp {
	case ConstraintNoConstraint:
		return nil
	case ConstraintPrimaryKey:
		ctx.WriteKeyWord("PRIMARY KEY")
	case ConstraintKey:
		ctx.WriteKeyWord("KEY")
		if n.IfNotExists {
			ctx.WriteKeyWord(" IF NOT EXISTS")
		}
	case ConstraintIndex:
		ctx.WriteKeyWord("INDEX")
		if n.IfNotExists {
			ctx.WriteKeyWord(" IF NOT EXISTS")
		}
	case ConstraintUniq:
		ctx.WriteKeyWord("UNIQUE")
	case ConstraintUniqKey:
		ctx.WriteKeyWord("UNIQUE KEY")
	case ConstraintUniqIndex:
		ctx.WriteKeyWord("UNIQUE INDEX")
	case ConstraintFulltext:
		ctx.WriteKeyWord("FULLTEXT")
	case ConstraintCheck:
		if n.Name != "" {
			ctx.WriteKeyWord("CONSTRAINT ")
			ctx.WriteName(n.Name)
			ctx.WritePlain(" ")
		}
		ctx.WriteKeyWord("CHECK")
		ctx.WritePlain("(")
		if err := n.Expr.Restore(ctx); err != nil {
			return errors.Trace(err)
		}
		ctx.WritePlain(") ")
		if n.Enforced {
			ctx.WriteKeyWord("ENFORCED")
		} else {
			ctx.WriteKeyWord("NOT ENFORCED")
		}
		return nil
	}

	if n.Tp == ConstraintForeignKey {
		ctx.WriteKeyWord("CONSTRAINT ")
		if n.Name != "" {
			ctx.WriteName(n.Name)
			ctx.WritePlain(" ")
		}
		ctx.WriteKeyWord("FOREIGN KEY ")
		if n.IfNotExists {
			ctx.WriteKeyWord("IF NOT EXISTS ")
		}
	} else if n.Name != "" || n.IsEmptyIndex {
		ctx.WritePlain(" ")
		ctx.WriteName(n.Name)
	}

	ctx.WritePlain("(")
	for i, keys := range n.Keys {
		if i > 0 {
			ctx.WritePlain(", ")
		}
		if err := keys.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while splicing Constraint Keys: [%v]", i)
		}
	}
	ctx.WritePlain(")")

	if n.Refer != nil {
		ctx.WritePlain(" ")
		if err := n.Refer.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while splicing Constraint Refer")
		}
	}

	if n.Option != nil {
		ctx.WritePlain(" ")
		if err := n.Option.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while splicing Constraint Option")
		}
	}

	return nil
}

// Accept implements Node Accept interface.
func (n *Constraint) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*Constraint)
	for i, val := range n.Keys {
		node, ok := val.Accept(v)
		if !ok {
			return n, false
		}
		n.Keys[i] = node.(*IndexPartSpecification)
	}
	if n.Refer != nil {
		node, ok := n.Refer.Accept(v)
		if !ok {
			return n, false
		}
		n.Refer = node.(*ReferenceDef)
	}
	if n.Option != nil {
		node, ok := n.Option.Accept(v)
		if !ok {
			return n, false
		}
		n.Option = node.(*IndexOption)
	}
	if n.Expr != nil {
		node, ok := n.Expr.Accept(v)
		if !ok {
			return n, false
		}
		n.Expr = node.(ExprNode)
	}
	return v.Leave(n)
}

// ColumnDef is used for parsing column definition from SQL.
type ColumnDef struct {
	node

	Name    *ColumnName
	Tp      *types.FieldType
	Options []*ColumnOption
}

func (n *ColumnDef) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	lNode := n.Name.LogCurrentNode(depth + 1)
	columnNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(lNode, sql_ir.DataColumnName)
	for _, columnNameNode := range columnNameNodeList {
		columnNameNode.DataType = sql_ir.DataColumnName
		columnNameNode.ContextFlag = sql_ir.ContextDefine
	}

	midfix := ""

	var rNode *sql_ir.SqlRsgIR = nil
	if n.Tp != nil {
		midfix = " "
		rNode = n.Tp.LogCurrentNode(depth + 1)
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		RNode:    rNode,
		Prefix:   "",
		Infix:    midfix,
		Suffix:   "",
		Depth:    depth,
	}

	for _, options := range n.Options {
		midfix = " "
		rNode = options.LogCurrentNode(depth + 1)
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Prefix:   "",
			Infix:    midfix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootNode.IRType = sql_ir.TypeColumnDef
	return rootNode

}

// Restore implements Node interface.
func (n *ColumnDef) Restore(ctx *format.RestoreCtx) error {
	if err := n.Name.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while splicing ColumnDef Name")
	}
	if n.Tp != nil {
		ctx.WritePlain(" ")
		if err := n.Tp.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while splicing ColumnDef Type")
		}
	}
	for i, options := range n.Options {
		ctx.WritePlain(" ")
		if err := options.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while splicing ColumnDef ColumnOption: [%v]", i)
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *ColumnDef) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*ColumnDef)
	node, ok := n.Name.Accept(v)
	if !ok {
		return n, false
	}
	n.Name = node.(*ColumnName)
	for i, val := range n.Options {
		node, ok := val.Accept(v)
		if !ok {
			return n, false
		}
		n.Options[i] = node.(*ColumnOption)
	}
	return v.Leave(n)
}

// Validate checks if a column definition is legal.
// For example, generated column definitions that contain such
// column options as `ON UPDATE`, `AUTO_INCREMENT`, `DEFAULT`
// are illegal.
func (n *ColumnDef) Validate() bool {
	generatedCol := false
	illegalOpt4gc := false
	for _, opt := range n.Options {
		if opt.Tp == ColumnOptionGenerated {
			generatedCol = true
		}
		_, found := invalidOptionForGeneratedColumn[opt.Tp]
		illegalOpt4gc = illegalOpt4gc || found
	}
	return !(generatedCol && illegalOpt4gc)
}

type TemporaryKeyword int

const (
	TemporaryNone TemporaryKeyword = iota
	TemporaryGlobal
	TemporaryLocal
)

// CreateTableStmt is a statement to create a table.
// See https://dev.mysql.com/doc/refman/5.7/en/create-table.html
type CreateTableStmt struct {
	ddlNode

	IfNotExists bool
	TemporaryKeyword
	// Meanless when TemporaryKeyword is not TemporaryGlobal.
	// ON COMMIT DELETE ROWS => true
	// ON COMMIT PRESERVE ROW => false
	OnCommitDelete bool
	Table          *TableName
	ReferTable     *TableName
	Cols           []*ColumnDef
	Constraints    []*Constraint
	Options        []*TableOption
	Partition      *PartitionOptions
	OnDuplicate    OnDuplicateKeyHandlingType
	Select         ResultSetNode
}

func (n *CreateTableStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	isCreateTableAs := false
	prefix := ""

	switch n.TemporaryKeyword {
	case TemporaryNone:
		prefix += "CREATE TABLE "
	case TemporaryGlobal:
		prefix += "CREATE GLOBAL TEMPORARY TABLE "
	case TemporaryLocal:
		prefix += "CREATE TEMPORARY TABLE "
	}
	if n.IfNotExists {
		prefix += "IF NOT EXISTS "
	}

	lNode := n.Table.LogCurrentNode(depth + 1)
	tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(lNode, sql_ir.DataTableName)
	for _, tableNameNode := range tableNameNodeList {
		tableNameNode.DataType = sql_ir.DataTableName
		tableNameNode.ContextFlag = sql_ir.ContextDefine
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if n.ReferTable != nil {
		midfix := " LIKE "
		rNode := n.ReferTable.LogCurrentNode(depth + 1)
		tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(rNode, sql_ir.DataTableName)
		for _, tableNameNode := range tableNameNodeList {
			tableNameNode.DataType = sql_ir.DataTableName
			tableNameNode.ContextFlag = sql_ir.ContextUse
		}

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    lNode,
			RNode:    rNode,
			Prefix:   "",
			Infix:    midfix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	lenCols := len(n.Cols)
	lenConstraints := len(n.Constraints)
	if lenCols+lenConstraints > 0 {
		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for i, col := range n.Cols {
			midfix := ""
			if i > 0 {
				midfix = ", "
			}
			if i == 0 {
				tmpRootNode.LNode = col.LogCurrentNode(depth + 1)
			} else { // i > 0
				colNode := col.LogCurrentNode(depth + 1)
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    colNode,
					Infix:    midfix,
					Depth:    depth,
				}
			}
		}
		for i, constraint := range n.Constraints {
			midfix := ""
			if i > 0 || lenCols >= 1 {
				midfix = ", "
			}
			if i == 0 && lenCols == 0 {
				tmpRootNode.LNode = constraint.LogCurrentNode(depth + 1)
			} else {
				colNode := constraint.LogCurrentNode(depth + 1)
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    colNode,
					Infix:    midfix,
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
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	for _, option := range n.Options {
		midfix := " "
		rNode := option.LogCurrentNode(depth + 1)

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Prefix:   "",
			Infix:    midfix,
			Suffix:   "",
			Depth:    depth,
		}

	}

	if n.Partition != nil {

		midfix := " "
		rNode := n.Partition.LogCurrentNode(depth + 1)

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Prefix:   "",
			Infix:    midfix,
			Suffix:   "",
			Depth:    depth,
		}

	}

	if n.Select != nil {
		midfix := ""
		isCreateTableAs = true
		switch n.OnDuplicate {
		case OnDuplicateKeyHandlingError:
			midfix += " AS "
		case OnDuplicateKeyHandlingIgnore:
			midfix += " IGNORE AS "
		case OnDuplicateKeyHandlingReplace:
			midfix += " REPLACE AS "
		}

		rNode := n.Select.LogCurrentNode(depth + 1)

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Prefix:   "",
			Infix:    midfix,
			Suffix:   "",
			Depth:    depth,
		}

	}

	if n.TemporaryKeyword == TemporaryGlobal {
		midfix := ""
		if n.OnCommitDelete {
			midfix += " ON COMMIT DELETE ROWS"
		} else {
			midfix += " ON COMMIT PRESERVE ROWS"
		}
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			Prefix:   "",
			Infix:    midfix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if !isCreateTableAs {
		rootNode.IRType = sql_ir.TypeCreateTableStmt
	} else {
		rootNode.IRType = sql_ir.TypeCreateTableAsStmt
	}

	return rootNode

}

// Restore implements Node interface.
func (n *CreateTableStmt) Restore(ctx *format.RestoreCtx) error {
	switch n.TemporaryKeyword {
	case TemporaryNone:
		ctx.WriteKeyWord("CREATE TABLE ")
	case TemporaryGlobal:
		ctx.WriteKeyWord("CREATE GLOBAL TEMPORARY TABLE ")
	case TemporaryLocal:
		ctx.WriteKeyWord("CREATE TEMPORARY TABLE ")
	}
	if n.IfNotExists {
		ctx.WriteKeyWord("IF NOT EXISTS ")
	}

	if err := n.Table.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while splicing CreateTableStmt Table")
	}

	if n.ReferTable != nil {
		ctx.WriteKeyWord(" LIKE ")
		if err := n.ReferTable.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while splicing CreateTableStmt ReferTable")
		}
	}
	lenCols := len(n.Cols)
	lenConstraints := len(n.Constraints)
	if lenCols+lenConstraints > 0 {
		ctx.WritePlain(" (")
		for i, col := range n.Cols {
			if i > 0 {
				ctx.WritePlain(",")
			}
			if err := col.Restore(ctx); err != nil {
				return errors.Annotatef(err, "An error occurred while splicing CreateTableStmt ColumnDef: [%v]", i)
			}
		}
		for i, constraint := range n.Constraints {
			if i > 0 || lenCols >= 1 {
				ctx.WritePlain(",")
			}
			if err := constraint.Restore(ctx); err != nil {
				return errors.Annotatef(err, "An error occurred while splicing CreateTableStmt Constraints: [%v]", i)
			}
		}
		ctx.WritePlain(")")
	}

	for i, option := range n.Options {
		ctx.WritePlain(" ")
		if err := option.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while splicing CreateTableStmt TableOption: [%v]", i)
		}
	}

	if n.Partition != nil {
		ctx.WritePlain(" ")
		if err := n.Partition.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while splicing CreateTableStmt Partition")
		}
	}

	if n.Select != nil {
		switch n.OnDuplicate {
		case OnDuplicateKeyHandlingError:
			ctx.WriteKeyWord(" AS ")
		case OnDuplicateKeyHandlingIgnore:
			ctx.WriteKeyWord(" IGNORE AS ")
		case OnDuplicateKeyHandlingReplace:
			ctx.WriteKeyWord(" REPLACE AS ")
		}

		if err := n.Select.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while splicing CreateTableStmt Select")
		}
	}

	if n.TemporaryKeyword == TemporaryGlobal {
		if n.OnCommitDelete {
			ctx.WriteKeyWord(" ON COMMIT DELETE ROWS")
		} else {
			ctx.WriteKeyWord(" ON COMMIT PRESERVE ROWS")
		}
	}

	return nil
}

// Accept implements Node Accept interface.
func (n *CreateTableStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*CreateTableStmt)
	node, ok := n.Table.Accept(v)
	if !ok {
		return n, false
	}
	n.Table = node.(*TableName)
	if n.ReferTable != nil {
		node, ok = n.ReferTable.Accept(v)
		if !ok {
			return n, false
		}
		n.ReferTable = node.(*TableName)
	}
	for i, val := range n.Cols {
		node, ok = val.Accept(v)
		if !ok {
			return n, false
		}
		n.Cols[i] = node.(*ColumnDef)
	}
	for i, val := range n.Constraints {
		node, ok = val.Accept(v)
		if !ok {
			return n, false
		}
		n.Constraints[i] = node.(*Constraint)
	}
	if n.Select != nil {
		node, ok := n.Select.Accept(v)
		if !ok {
			return n, false
		}
		n.Select = node.(ResultSetNode)
	}
	if n.Partition != nil {
		node, ok := n.Partition.Accept(v)
		if !ok {
			return n, false
		}
		n.Partition = node.(*PartitionOptions)
	}

	return v.Leave(n)
}

// DropTableStmt is a statement to drop one or more tables.
// See https://dev.mysql.com/doc/refman/5.7/en/drop-table.html
type DropTableStmt struct {
	ddlNode

	IfExists         bool
	Tables           []*TableName
	IsView           bool
	TemporaryKeyword // make sense ONLY if/when IsView == false
}

func (n *DropTableStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := ""
	if n.IsView {
		prefix += "DROP VIEW "
	} else {
		switch n.TemporaryKeyword {
		case TemporaryNone:
			prefix += "DROP TABLE "
		case TemporaryGlobal:
			prefix += "DROP GLOBAL TEMPORARY TABLE "
		case TemporaryLocal:
			prefix += "DROP TEMPORARY TABLE "
		}
	}

	if n.IfExists {
		prefix += "IF EXISTS "
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	for index, table := range n.Tables {
		midfix := ""
		if index != 0 {
			midfix = ", "
		}
		curTableNode := table.LogCurrentNode(depth + 1)
		tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(curTableNode, sql_ir.DataTableName)
		for _, tableNameNode := range tableNameNodeList {
			tableNameNode.DataType = sql_ir.DataTableName
			tableNameNode.ContextFlag = sql_ir.ContextUndefine
		}

		if index == 0 {
			rootNode.LNode = curTableNode
		} else { // index > 0
			rootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    rootNode,
				RNode:    curTableNode,
				Prefix:   "",
				Infix:    midfix,
				Suffix:   "",
				Depth:    depth,
			}
		}
	}

	rootNode.IRType = sql_ir.TypeDropTableStmt

	return rootNode

}

// Restore implements Node interface.
func (n *DropTableStmt) Restore(ctx *format.RestoreCtx) error {
	if n.IsView {
		ctx.WriteKeyWord("DROP VIEW ")
	} else {
		switch n.TemporaryKeyword {
		case TemporaryNone:
			ctx.WriteKeyWord("DROP TABLE ")
		case TemporaryGlobal:
			ctx.WriteKeyWord("DROP GLOBAL TEMPORARY TABLE ")
		case TemporaryLocal:
			ctx.WriteKeyWord("DROP TEMPORARY TABLE ")
		}
	}
	if n.IfExists {
		ctx.WriteKeyWord("IF EXISTS ")
	}

	for index, table := range n.Tables {
		if index != 0 {
			ctx.WritePlain(", ")
		}
		if err := table.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore DropTableStmt.Tables[%d]", index)
		}
	}

	return nil
}

// Accept implements Node Accept interface.
func (n *DropTableStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*DropTableStmt)
	for i, val := range n.Tables {
		node, ok := val.Accept(v)
		if !ok {
			return n, false
		}
		n.Tables[i] = node.(*TableName)
	}
	return v.Leave(n)
}

// DropPlacementPolicyStmt is a statement to drop a Policy.
type DropPlacementPolicyStmt struct {
	ddlNode

	IfExists   bool
	PolicyName model.CIStr
}

func (n *DropPlacementPolicyStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := "DROP PLACEMENT POLICY "

	if n.IfExists {
		prefix += "IF EXISTS "
	}

	lNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataNone,
		ContextFlag: sql_ir.ContextUndefine,
		Str:         n.PolicyName.O,
		Depth:       depth,
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeDropPlacementPolicyStmt

	return rootNode

}

// Restore implements Restore interface.
func (n *DropPlacementPolicyStmt) Restore(ctx *format.RestoreCtx) error {
	if ctx.Flags.HasTiDBSpecialCommentFlag() {
		return restorePlacementStmtInSpecialComment(ctx, n)
	}

	ctx.WriteKeyWord("DROP PLACEMENT POLICY ")
	if n.IfExists {
		ctx.WriteKeyWord("IF EXISTS ")
	}
	ctx.WriteName(n.PolicyName.O)
	return nil
}

func (n *DropPlacementPolicyStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*DropPlacementPolicyStmt)
	return v.Leave(n)
}

// DropSequenceStmt is a statement to drop a Sequence.
type DropSequenceStmt struct {
	ddlNode

	IfExists  bool
	Sequences []*TableName
}

func (n *DropSequenceStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "DROP SEQUENCE "
	if n.IfExists {
		prefix += "IF EXISTS "
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   prefix,
		Depth:    depth,
	}
	prefix = ""

	for i, sequence := range n.Sequences {
		midfix := ""
		if i != 0 {
			midfix = ", "
		}
		curSeqNode := sequence.LogCurrentNode(depth + 1)
		tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(curSeqNode, sql_ir.DataTableName)
		for _, tableNameNode := range tableNameNodeList {
			tableNameNode.DataType = sql_ir.DataSequenceName
			tableNameNode.ContextFlag = sql_ir.ContextUndefine
		}

		if i == 0 {
			rootNode.LNode = curSeqNode
		} else { // i > 0
			rootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    rootNode,
				RNode:    curSeqNode,
				Infix:    midfix,
				Depth:    depth,
			}
		}
	}

	rootNode.IRType = sql_ir.TypeDropSequenceStmt

	return rootNode
}

// Restore implements Node interface.
func (n *DropSequenceStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("DROP SEQUENCE ")
	if n.IfExists {
		ctx.WriteKeyWord("IF EXISTS ")
	}
	for i, sequence := range n.Sequences {
		if i != 0 {
			ctx.WritePlain(", ")
		}
		if err := sequence.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore DropSequenceStmt.Sequences[%d]", i)
		}
	}

	return nil
}

// Accept implements Node Accept interface.
func (n *DropSequenceStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*DropSequenceStmt)
	for i, val := range n.Sequences {
		node, ok := val.Accept(v)
		if !ok {
			return n, false
		}
		n.Sequences[i] = node.(*TableName)
	}
	return v.Leave(n)
}

// RenameTableStmt is a statement to rename a table.
// See http://dev.mysql.com/doc/refman/5.7/en/rename-table.html
type RenameTableStmt struct {
	ddlNode

	TableToTables []*TableToTable
}

func (n *RenameTableStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "RENAME TABLE "

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   prefix,
		Depth:    depth,
	}

	for i, table2table := range n.TableToTables {
		midfix := ""
		if i != 0 {
			midfix = ", "
		}
		if i == 0 {
			curNode := table2table.LogCurrentNode(depth + 1)
			rootNode.LNode = curNode
		} else { // i > 0
			curNode := table2table.LogCurrentNode(depth + 1)
			rootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    rootNode,
				RNode:    curNode,
				Infix:    midfix,
				Depth:    depth,
			}
		}
	}

	rootNode.IRType = sql_ir.TypeRenameTableStmt

	return rootNode
}

// Restore implements Node interface.
func (n *RenameTableStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("RENAME TABLE ")
	for index, table2table := range n.TableToTables {
		if index != 0 {
			ctx.WritePlain(", ")
		}
		if err := table2table.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore RenameTableStmt.TableToTables")
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *RenameTableStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*RenameTableStmt)

	for i, t := range n.TableToTables {
		node, ok := t.Accept(v)
		if !ok {
			return n, false
		}
		n.TableToTables[i] = node.(*TableToTable)
	}

	return v.Leave(n)
}

// TableToTable represents renaming old table to new table used in RenameTableStmt.
type TableToTable struct {
	node
	OldTable *TableName
	NewTable *TableName
}

func (n *TableToTable) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	lNode := n.OldTable.LogCurrentNode(depth + 1)
	tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(lNode, sql_ir.DataTableName)
	for _, tableNameNode := range tableNameNodeList {
		tableNameNode.DataType = sql_ir.DataTableName
		tableNameNode.ContextFlag = sql_ir.ContextUndefine
	}

	midfix := " TO "
	rNode := n.NewTable.LogCurrentNode(depth + 1)
	tableNameNodeList = sql_ir.GetSubNodeFromParentNodeWithDataType(rNode, sql_ir.DataTableName)
	for _, tableNameNode := range tableNameNodeList {
		tableNameNode.DataType = sql_ir.DataTableName
		tableNameNode.ContextFlag = sql_ir.ContextDefine
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		RNode:    rNode,
		Infix:    midfix,
		Depth:    depth,
	}
	rootNode.IRType = sql_ir.TypeTableToTable
	return rootNode
}

// Restore implements Node interface.
func (n *TableToTable) Restore(ctx *format.RestoreCtx) error {
	if err := n.OldTable.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore TableToTable.OldTable")
	}
	ctx.WriteKeyWord(" TO ")
	if err := n.NewTable.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore TableToTable.NewTable")
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *TableToTable) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*TableToTable)
	node, ok := n.OldTable.Accept(v)
	if !ok {
		return n, false
	}
	n.OldTable = node.(*TableName)
	node, ok = n.NewTable.Accept(v)
	if !ok {
		return n, false
	}
	n.NewTable = node.(*TableName)
	return v.Leave(n)
}

// CreateViewStmt is a statement to create a View.
// See https://dev.mysql.com/doc/refman/5.7/en/create-view.html
type CreateViewStmt struct {
	ddlNode

	OrReplace   bool
	ViewName    *TableName
	Cols        []model.CIStr
	Select      StmtNode
	SchemaCols  []model.CIStr
	Algorithm   model.ViewAlgorithm
	Definer     *auth.UserIdentity
	Security    model.ViewSecurity
	CheckOption model.ViewCheckOption
}

func (n *CreateViewStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := ""

	prefix += "CREATE "
	if n.OrReplace {
		prefix += "OR REPLACE "
	}
	prefix += "ALGORITHM = " + n.Algorithm.String()
	prefix += " DEFINER = current_user" // Hard fixed.
	prefix += " SQL SECURITY " + n.Security.String()
	prefix += " VIEW "

	lNode := n.ViewName.LogCurrentNode(depth + 1)
	viewNameIdenNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(lNode, sql_ir.DataTableName)
	if len(viewNameIdenNodeList) != 0 {
		for _, viewNameIdenNode := range viewNameIdenNodeList {
			viewNameIdenNode.IRType = sql_ir.TypeIdentifier
			viewNameIdenNode.DataType = sql_ir.DataViewName
			viewNameIdenNode.ContextFlag = sql_ir.ContextDefine
		}
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
		Prefix:   prefix,
		Depth:    depth,
	}
	for i, col := range n.Cols {
		curColNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataColumnName,
			ContextFlag: sql_ir.ContextDefine,
			Str:         col.O,
			Depth:       depth,
		}
		if i == 0 {
			tmpRootNode.LNode = curColNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    curColNode,
				Infix:    ", ",
				Depth:    depth,
			}
		}
		tmpRootNode.Prefix = "("
		tmpRootNode.Suffix = ")"
	}
	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Depth:    depth,
	}

	midfix := " AS "

	selectNode := n.Select.LogCurrentNode(depth + 1)

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    selectNode,
		Infix:    midfix,
		Depth:    depth,
	}
	midfix = ""

	if n.CheckOption != model.CheckOptionCascaded {
		midfix = " WITH " + n.CheckOption.String() + " CHECK OPTION"
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			Infix:    midfix,
			Depth:    depth,
		}
		midfix = ""
	}

	rootNode.IRType = sql_ir.TypeCreateViewStmt

	return rootNode

}

// Restore implements Node interface.
func (n *CreateViewStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("CREATE ")
	if n.OrReplace {
		ctx.WriteKeyWord("OR REPLACE ")
	}
	ctx.WriteKeyWord("ALGORITHM")
	ctx.WritePlain(" = ")
	ctx.WriteKeyWord(n.Algorithm.String())
	ctx.WriteKeyWord(" DEFINER")
	ctx.WritePlain(" = ")

	// todo Use n.Definer.Restore(ctx) to replace this part
	if n.Definer.CurrentUser {
		ctx.WriteKeyWord("current_user")
	} else {
		ctx.WriteName(n.Definer.Username)
		if n.Definer.Hostname != "" {
			ctx.WritePlain("@")
			ctx.WriteName(n.Definer.Hostname)
		}
	}

	ctx.WriteKeyWord(" SQL SECURITY ")
	ctx.WriteKeyWord(n.Security.String())
	ctx.WriteKeyWord(" VIEW ")

	if err := n.ViewName.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while create CreateViewStmt.ViewName")
	}

	for i, col := range n.Cols {
		if i == 0 {
			ctx.WritePlain(" (")
		} else {
			ctx.WritePlain(",")
		}
		ctx.WriteName(col.O)
		if i == len(n.Cols)-1 {
			ctx.WritePlain(")")
		}
	}

	ctx.WriteKeyWord(" AS ")

	if err := n.Select.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while create CreateViewStmt.Select")
	}

	if n.CheckOption != model.CheckOptionCascaded {
		ctx.WriteKeyWord(" WITH ")
		ctx.WriteKeyWord(n.CheckOption.String())
		ctx.WriteKeyWord(" CHECK OPTION")
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *CreateViewStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*CreateViewStmt)
	node, ok := n.ViewName.Accept(v)
	if !ok {
		return n, false
	}
	n.ViewName = node.(*TableName)
	selnode, ok := n.Select.Accept(v)
	if !ok {
		return n, false
	}
	n.Select = selnode.(StmtNode)
	return v.Leave(n)
}

// CreatePlacementPolicyStmt is a statement to create a policy.
type CreatePlacementPolicyStmt struct {
	ddlNode

	OrReplace        bool
	IfNotExists      bool
	PolicyName       model.CIStr
	PlacementOptions []*PlacementOption
}

func (n *CreatePlacementPolicyStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "CREATE "
	if n.OrReplace {
		prefix += "OR REPLACE "
	}
	prefix += "PLACEMENT POLICY "
	if n.IfNotExists {
		prefix += "IF NOT EXISTS "
	}
	lNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataPolicyName,
		ContextFlag: sql_ir.ContextDefine,
		Str:         n.PolicyName.O,
		Depth:       depth,
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	for _, option := range n.PlacementOptions {
		midfix := " "
		rNode := option.LogCurrentNode(depth + 1)
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Infix:    midfix,
			Depth:    depth,
		}
	}

	rootNode.IRType = sql_ir.TypeCreatePlacementPolicyStmt
	return rootNode

}

// Restore implements Node interface.
func (n *CreatePlacementPolicyStmt) Restore(ctx *format.RestoreCtx) error {
	if ctx.Flags.HasTiDBSpecialCommentFlag() {
		return restorePlacementStmtInSpecialComment(ctx, n)
	}

	ctx.WriteKeyWord("CREATE ")
	if n.OrReplace {
		ctx.WriteKeyWord("OR REPLACE ")
	}
	ctx.WriteKeyWord("PLACEMENT POLICY ")
	if n.IfNotExists {
		ctx.WriteKeyWord("IF NOT EXISTS ")
	}
	ctx.WriteName(n.PolicyName.O)
	for i, option := range n.PlacementOptions {
		ctx.WritePlain(" ")
		if err := option.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while splicing CreatePlacementPolicy TableOption: [%v]", i)
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *CreatePlacementPolicyStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*CreatePlacementPolicyStmt)
	return v.Leave(n)
}

// CreateSequenceStmt is a statement to create a Sequence.
type CreateSequenceStmt struct {
	ddlNode

	// TODO : support or replace if need : care for it will conflict on temporaryOpt.
	IfNotExists bool
	Name        *TableName
	SeqOptions  []*SequenceOption
	TblOptions  []*TableOption
}

func (n *CreateSequenceStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "CREATE SEQUENCE "
	if n.IfNotExists {
		prefix += "IF NOT EXISTS "
	}
	lNode := n.Name.LogCurrentNode(depth + 1)
	tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(lNode, sql_ir.DataTableName)
	for _, tableNameNode := range tableNameNodeList {
		tableNameNode.DataType = sql_ir.DataSequenceName
		tableNameNode.ContextFlag = sql_ir.ContextDefine
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	for _, option := range n.SeqOptions {
		midfix := " "
		rNode := option.LogCurrentNode(depth + 1)
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Infix:    midfix,
			Depth:    depth,
		}
	}
	for _, option := range n.TblOptions {
		midfix := " "
		rNode := option.LogCurrentNode(depth + 1)
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Infix:    midfix,
			Depth:    depth,
		}
	}

	rootNode.IRType = sql_ir.TypeCreateSequenceStmt
	return rootNode

}

// Restore implements Node interface.
func (n *CreateSequenceStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("CREATE ")
	ctx.WriteKeyWord("SEQUENCE ")
	if n.IfNotExists {
		ctx.WriteKeyWord("IF NOT EXISTS ")
	}
	if err := n.Name.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while create CreateSequenceStmt.Name")
	}
	for i, option := range n.SeqOptions {
		ctx.WritePlain(" ")
		if err := option.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while splicing CreateSequenceStmt SequenceOption: [%v]", i)
		}
	}
	for i, option := range n.TblOptions {
		ctx.WritePlain(" ")
		if err := option.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while splicing CreateSequenceStmt TableOption: [%v]", i)
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *CreateSequenceStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*CreateSequenceStmt)
	node, ok := n.Name.Accept(v)
	if !ok {
		return n, false
	}
	n.Name = node.(*TableName)
	return v.Leave(n)
}

// IndexLockAndAlgorithm stores the algorithm option and the lock option.
type IndexLockAndAlgorithm struct {
	node

	LockTp      LockType
	AlgorithmTp AlgorithmType
}

func (n *IndexLockAndAlgorithm) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := ""
	if n.AlgorithmTp != AlgorithmTypeDefault {
		prefix += "ALGORITHM"
		prefix += " = " + n.AlgorithmTp.String()
	}
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   prefix,
		Depth:    depth,
	}
	prefix = ""

	if n.LockTp != LockTypeDefault {
		midfix := "LOCK = " + n.LockTp.String()
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			Infix:    midfix,
			Depth:    depth,
		}
	}

	rootNode.IRType = sql_ir.TypeIndexLockAndAlgorithm
	return rootNode

}

// Restore implements Node interface.
func (n *IndexLockAndAlgorithm) Restore(ctx *format.RestoreCtx) error {
	hasPrevOption := false
	if n.AlgorithmTp != AlgorithmTypeDefault {
		ctx.WriteKeyWord("ALGORITHM")
		ctx.WritePlain(" = ")
		ctx.WriteKeyWord(n.AlgorithmTp.String())
		hasPrevOption = true
	}

	if n.LockTp != LockTypeDefault {
		if hasPrevOption {
			ctx.WritePlain(" ")
		}
		ctx.WriteKeyWord("LOCK")
		ctx.WritePlain(" = ")
		ctx.WriteKeyWord(n.LockTp.String())
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *IndexLockAndAlgorithm) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*IndexLockAndAlgorithm)
	return v.Leave(n)
}

// IndexKeyType is the type for index key.
type IndexKeyType int

// Index key types.
const (
	IndexKeyTypeNone IndexKeyType = iota
	IndexKeyTypeUnique
	IndexKeyTypeSpatial
	IndexKeyTypeFullText
)

// CreateIndexStmt is a statement to create an index.
// See https://dev.mysql.com/doc/refman/5.7/en/create-index.html
type CreateIndexStmt struct {
	ddlNode

	// only supported by MariaDB 10.0.2+,
	// see https://mariadb.com/kb/en/library/create-index/
	IfNotExists bool

	IndexName               string
	Table                   *TableName
	IndexPartSpecifications []*IndexPartSpecification
	IndexOption             *IndexOption
	KeyType                 IndexKeyType
	LockAlg                 *IndexLockAndAlgorithm
}

func (n *CreateIndexStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := "CREATE "

	switch n.KeyType {
	case IndexKeyTypeUnique:
		prefix += "UNIQUE "
	case IndexKeyTypeSpatial:
		prefix += "SPATIAL "
	case IndexKeyTypeFullText:
		prefix += "FULLTEXT "
	}

	prefix += "INDEX "
	if n.IfNotExists {
		prefix += "IF NOT EXISTS "
	}

	lNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataIndexName,
		ContextFlag: sql_ir.ContextDefine,
		Str:         n.IndexName,
		Depth:       depth,
	}

	midfix := " ON "

	rNode := n.Table.LogCurrentNode(depth + 1)

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		RNode:    rNode,
		Prefix:   prefix,
		Infix:    midfix,
		Depth:    depth,
	}
	midfix = ""

	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, indexColName := range n.IndexPartSpecifications {
		midfix = ""
		if i != 0 {
			midfix = ", "
		}
		curIndexCovNode := indexColName.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = curIndexCovNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    curIndexCovNode,
				Infix:    midfix,
				Depth:    depth,
			}
		}
	}
	tmpRootNode.Prefix = " ( "
	tmpRootNode.Suffix = " ) "
	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Depth:    depth,
	}
	midfix = ""

	if n.IndexOption.Tp != model.IndexTypeInvalid || n.IndexOption.KeyBlockSize > 0 || n.IndexOption.Comment != "" || len(n.IndexOption.ParserName.O) > 0 || n.IndexOption.Visibility != IndexVisibilityDefault {
		midfix = " "
		rNode = n.IndexOption.LogCurrentNode(depth + 1)
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Infix:    midfix,
			Depth:    depth,
		}
	}

	if n.LockAlg != nil {
		midfix = " "
		rNode = n.LockAlg.LogCurrentNode(depth + 1)
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Infix:    midfix,
			Depth:    depth,
		}
	}

	rootNode.IRType = sql_ir.TypeCreateIndexStmt
	return rootNode

}

// Restore implements Node interface.
func (n *CreateIndexStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("CREATE ")
	switch n.KeyType {
	case IndexKeyTypeUnique:
		ctx.WriteKeyWord("UNIQUE ")
	case IndexKeyTypeSpatial:
		ctx.WriteKeyWord("SPATIAL ")
	case IndexKeyTypeFullText:
		ctx.WriteKeyWord("FULLTEXT ")
	}
	ctx.WriteKeyWord("INDEX ")
	if n.IfNotExists {
		ctx.WriteKeyWord("IF NOT EXISTS ")
	}
	ctx.WriteName(n.IndexName)
	ctx.WriteKeyWord(" ON ")
	if err := n.Table.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore CreateIndexStmt.Table")
	}

	ctx.WritePlain(" (")
	for i, indexColName := range n.IndexPartSpecifications {
		if i != 0 {
			ctx.WritePlain(", ")
		}
		if err := indexColName.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore CreateIndexStmt.IndexPartSpecifications: [%v]", i)
		}
	}
	ctx.WritePlain(")")

	if n.IndexOption.Tp != model.IndexTypeInvalid || n.IndexOption.KeyBlockSize > 0 || n.IndexOption.Comment != "" || len(n.IndexOption.ParserName.O) > 0 || n.IndexOption.Visibility != IndexVisibilityDefault {
		ctx.WritePlain(" ")
		if err := n.IndexOption.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore CreateIndexStmt.IndexOption")
		}
	}

	if n.LockAlg != nil {
		ctx.WritePlain(" ")
		if err := n.LockAlg.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore CreateIndexStmt.LockAlg")
		}
	}

	return nil
}

// Accept implements Node Accept interface.
func (n *CreateIndexStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*CreateIndexStmt)
	node, ok := n.Table.Accept(v)
	if !ok {
		return n, false
	}
	n.Table = node.(*TableName)
	for i, val := range n.IndexPartSpecifications {
		node, ok = val.Accept(v)
		if !ok {
			return n, false
		}
		n.IndexPartSpecifications[i] = node.(*IndexPartSpecification)
	}
	if n.IndexOption != nil {
		node, ok := n.IndexOption.Accept(v)
		if !ok {
			return n, false
		}
		n.IndexOption = node.(*IndexOption)
	}
	if n.LockAlg != nil {
		node, ok := n.LockAlg.Accept(v)
		if !ok {
			return n, false
		}
		n.LockAlg = node.(*IndexLockAndAlgorithm)
	}
	return v.Leave(n)
}

// DropIndexStmt is a statement to drop the index.
// See https://dev.mysql.com/doc/refman/5.7/en/drop-index.html
type DropIndexStmt struct {
	ddlNode

	IfExists  bool
	IndexName string
	Table     *TableName
	LockAlg   *IndexLockAndAlgorithm
}

func (n *DropIndexStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := "DROP INDEX "

	if n.IfExists {
		prefix += "IF EXISTS "
	}

	lNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataIndexName,
		ContextFlag: sql_ir.ContextUndefine,
		Str:         n.IndexName,
		Depth:       depth,
	}

	midfix := " ON "

	rNode := n.Table.LogCurrentNode(depth + 1)
	tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(rNode, sql_ir.DataTableName)
	for _, tableNameNode := range tableNameNodeList {
		tableNameNode.DataType = sql_ir.DataTableName
		tableNameNode.ContextFlag = sql_ir.ContextUse
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
	midfix = ""

	if n.LockAlg != nil {
		midfix = " "
		rNode = n.LockAlg.LogCurrentNode(depth + 1)
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Infix:    midfix,
			Depth:    depth,
		}
	}

	rootNode.IRType = sql_ir.TypeDropIndexStmt
	return rootNode

}

// Restore implements Node interface.
func (n *DropIndexStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("DROP INDEX ")
	if n.IfExists {
		_ = ctx.WriteWithSpecialComments("", func() error {
			ctx.WriteKeyWord("IF EXISTS ")
			return nil
		})
	}
	ctx.WriteName(n.IndexName)
	ctx.WriteKeyWord(" ON ")

	if err := n.Table.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while add index")
	}

	if n.LockAlg != nil {
		ctx.WritePlain(" ")
		if err := n.LockAlg.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore CreateIndexStmt.LockAlg")
		}
	}

	return nil
}

// Accept implements Node Accept interface.
func (n *DropIndexStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*DropIndexStmt)
	node, ok := n.Table.Accept(v)
	if !ok {
		return n, false
	}
	n.Table = node.(*TableName)
	if n.LockAlg != nil {
		node, ok := n.LockAlg.Accept(v)
		if !ok {
			return n, false
		}
		n.LockAlg = node.(*IndexLockAndAlgorithm)
	}
	return v.Leave(n)
}

// LockTablesStmt is a statement to lock tables.
type LockTablesStmt struct {
	ddlNode

	TableLocks []TableLock
}

// TableLock contains the table name and lock type.
type TableLock struct {
	Table *TableName
	Type  model.TableLockType
}

// Accept implements Node Accept interface.
func (n *LockTablesStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*LockTablesStmt)
	for i := range n.TableLocks {
		node, ok := n.TableLocks[i].Table.Accept(v)
		if !ok {
			return n, false
		}
		n.TableLocks[i].Table = node.(*TableName)
	}
	return v.Leave(n)
}

func (n *LockTablesStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := "LOCK TABLES "

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, tl := range n.TableLocks {
		midfix := ""
		if i != 0 {
			midfix = ", "
		}
		tableNode := tl.Table.LogCurrentNode(depth + 1)
		tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(tableNode, sql_ir.DataTableName)
		for _, tableNameNode := range tableNameNodeList {
			tableNameNode.DataType = sql_ir.DataTableName
			tableNameNode.ContextFlag = sql_ir.ContextUse
		}

		tmpMidfix := " " + tl.Type.String()
		tmpNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    tableNode,
			Infix:    tmpMidfix,
			Depth:    depth,
		}

		if i == 0 {
			rootNode.LNode = tmpNode
		} else { // i > 0
			rootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    rootNode,
				RNode:    tmpNode,
				Infix:    midfix,
				Depth:    depth,
			}
		}
	}
	rootNode.Prefix = prefix
	rootNode.IRType = sql_ir.TypeLockTablesStmt
	return rootNode
}

// Restore implements Node interface.
func (n *LockTablesStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("LOCK TABLES ")
	for i, tl := range n.TableLocks {
		if i != 0 {
			ctx.WritePlain(", ")
		}
		if err := tl.Table.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while add index")
		}
		ctx.WriteKeyWord(" " + tl.Type.String())
	}
	return nil
}

// UnlockTablesStmt is a statement to unlock tables.
type UnlockTablesStmt struct {
	ddlNode
}

// Accept implements Node Accept interface.
func (n *UnlockTablesStmt) Accept(v Visitor) (Node, bool) {
	_, _ = v.Enter(n)
	return v.Leave(n)
}

func (n *UnlockTablesStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := "UNLOCK TABLES"
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   prefix,
		Depth:    depth,
	}
	rootNode.IRType = sql_ir.TypeUnlockTablesStmt
	return rootNode
}

// Restore implements Node interface.
func (n *UnlockTablesStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("UNLOCK TABLES")
	return nil
}

// CleanupTableLockStmt is a statement to cleanup table lock.
type CleanupTableLockStmt struct {
	ddlNode

	Tables []*TableName
}

// Accept implements Node Accept interface.
func (n *CleanupTableLockStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*CleanupTableLockStmt)
	for i := range n.Tables {
		node, ok := n.Tables[i].Accept(v)
		if !ok {
			return n, false
		}
		n.Tables[i] = node.(*TableName)
	}
	return v.Leave(n)
}

func (n *CleanupTableLockStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := "ADMIN CLEANUP TABLE LOCK "

	rootNode := &sql_ir.SqlRsgIR{
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
	rootNode.IRType = sql_ir.TypeCleanupTableLockStmt
	return rootNode

}

// Restore implements Node interface.
func (n *CleanupTableLockStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("ADMIN CLEANUP TABLE LOCK ")
	for i, v := range n.Tables {
		if i != 0 {
			ctx.WritePlain(", ")
		}
		if err := v.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore CleanupTableLockStmt.Tables[%d]", i)
		}
	}
	return nil
}

// RepairTableStmt is a statement to repair tableInfo.
type RepairTableStmt struct {
	ddlNode
	Table      *TableName
	CreateStmt *CreateTableStmt
}

// Accept implements Node Accept interface.
func (n *RepairTableStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*RepairTableStmt)
	node, ok := n.Table.Accept(v)
	if !ok {
		return n, false
	}
	n.Table = node.(*TableName)
	node, ok = n.CreateStmt.Accept(v)
	if !ok {
		return n, false
	}
	n.CreateStmt = node.(*CreateTableStmt)
	return v.Leave(n)
}

func (n *RepairTableStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := "ADMIN REPAIR TABLE "
	lNode := n.Table.LogCurrentNode(depth + 1)
	tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(lNode, sql_ir.DataTableName)
	for _, tableNameNode := range tableNameNodeList {
		tableNameNode.DataType = sql_ir.DataTableName
		tableNameNode.ContextFlag = sql_ir.ContextUse
	}

	midfix := " "
	rNode := n.CreateStmt.LogCurrentNode(depth + 1)

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		RNode:    rNode,
		Prefix:   prefix,
		Infix:    midfix,
		Depth:    depth,
	}
	rootNode.IRType = sql_ir.TypeRepairTableStmt
	return nil
}

// Restore implements Node interface.
func (n *RepairTableStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("ADMIN REPAIR TABLE ")
	if err := n.Table.Restore(ctx); err != nil {
		return errors.Annotatef(err, "An error occurred while restore RepairTableStmt.table : [%v]", n.Table)
	}
	ctx.WritePlain(" ")
	if err := n.CreateStmt.Restore(ctx); err != nil {
		return errors.Annotatef(err, "An error occurred while restore RepairTableStmt.createStmt : [%v]", n.CreateStmt)
	}
	return nil
}

// PlacementOptionType is the type for PlacementOption
type PlacementOptionType int

// PlacementOption types.
const (
	PlacementOptionPrimaryRegion PlacementOptionType = 0x3000 + iota
	PlacementOptionRegions
	PlacementOptionFollowerCount
	PlacementOptionVoterCount
	PlacementOptionLearnerCount
	PlacementOptionSchedule
	PlacementOptionConstraints
	PlacementOptionLeaderConstraints
	PlacementOptionLearnerConstraints
	PlacementOptionFollowerConstraints
	PlacementOptionVoterConstraints
	PlacementOptionPolicy
)

// PlacementOption is used for parsing placement option.
type PlacementOption struct {
	Tp        PlacementOptionType
	StrValue  string
	UintValue uint64

	sql_ir.SqlRsgInterface
}

func (n *PlacementOption) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := ""
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	switch n.Tp {
	case PlacementOptionPrimaryRegion:
		prefix += "PRIMARY_REGION = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataRegionName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.StrValue,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode

	case PlacementOptionRegions:
		prefix += "REGIONS = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataRegionName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.StrValue,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case PlacementOptionFollowerCount:
		prefix += "FOLLOWERS = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			Str:      strconv.FormatUint(n.UintValue, 10),
			IValue:   int64(n.UintValue),
			Depth:    depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode

	case PlacementOptionVoterCount:
		prefix += "VOTERS = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			Str:      strconv.FormatUint(n.UintValue, 10),
			IValue:   int64(n.UintValue),
			Depth:    depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case PlacementOptionLearnerCount:
		prefix += "LEARNERS = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			Str:      strconv.FormatUint(n.UintValue, 10),
			IValue:   int64(n.UintValue),
			Depth:    depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case PlacementOptionSchedule:
		prefix += "SCHEDULE = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataSchemaName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.StrValue,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case PlacementOptionConstraints:
		prefix += "CONSTRAINTS = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataConstraintName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.StrValue,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case PlacementOptionLeaderConstraints:
		prefix += "LEADER_CONSTRAINTS = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataConstraintName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.StrValue,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case PlacementOptionFollowerConstraints:
		prefix += "FOLLOWER_CONSTRAINTS = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataConstraintName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.StrValue,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case PlacementOptionVoterConstraints:
		prefix += "VOTER_CONSTRAINTS = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataConstraintName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.StrValue,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case PlacementOptionLearnerConstraints:
		prefix += "LEARNER_CONSTRAINTS = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataConstraintName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.StrValue,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case PlacementOptionPolicy:
		prefix += "PLACEMENT POLICY = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataPolicyName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.StrValue,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	default:
		// Do nothing here.
	}
	rootNode.IRType = sql_ir.TypePlacementOption
	return rootNode

}

func (n *PlacementOption) Restore(ctx *format.RestoreCtx) error {
	if ctx.Flags.HasSkipPlacementRuleForRestoreFlag() {
		return nil
	}
	fn := func() error {
		switch n.Tp {
		case PlacementOptionPrimaryRegion:
			ctx.WriteKeyWord("PRIMARY_REGION ")
			ctx.WritePlain("= ")
			ctx.WriteString(n.StrValue)
		case PlacementOptionRegions:
			ctx.WriteKeyWord("REGIONS ")
			ctx.WritePlain("= ")
			ctx.WriteString(n.StrValue)
		case PlacementOptionFollowerCount:
			ctx.WriteKeyWord("FOLLOWERS ")
			ctx.WritePlain("= ")
			ctx.WritePlainf("%d", n.UintValue)
		case PlacementOptionVoterCount:
			ctx.WriteKeyWord("VOTERS ")
			ctx.WritePlain("= ")
			ctx.WritePlainf("%d", n.UintValue)
		case PlacementOptionLearnerCount:
			ctx.WriteKeyWord("LEARNERS ")
			ctx.WritePlain("= ")
			ctx.WritePlainf("%d", n.UintValue)
		case PlacementOptionSchedule:
			ctx.WriteKeyWord("SCHEDULE ")
			ctx.WritePlain("= ")
			ctx.WriteString(n.StrValue)
		case PlacementOptionConstraints:
			ctx.WriteKeyWord("CONSTRAINTS ")
			ctx.WritePlain("= ")
			ctx.WriteString(n.StrValue)
		case PlacementOptionLeaderConstraints:
			ctx.WriteKeyWord("LEADER_CONSTRAINTS ")
			ctx.WritePlain("= ")
			ctx.WriteString(n.StrValue)
		case PlacementOptionFollowerConstraints:
			ctx.WriteKeyWord("FOLLOWER_CONSTRAINTS ")
			ctx.WritePlain("= ")
			ctx.WriteString(n.StrValue)
		case PlacementOptionVoterConstraints:
			ctx.WriteKeyWord("VOTER_CONSTRAINTS ")
			ctx.WritePlain("= ")
			ctx.WriteString(n.StrValue)
		case PlacementOptionLearnerConstraints:
			ctx.WriteKeyWord("LEARNER_CONSTRAINTS ")
			ctx.WritePlain("= ")
			ctx.WriteString(n.StrValue)
		case PlacementOptionPolicy:
			ctx.WriteKeyWord("PLACEMENT POLICY ")
			ctx.WritePlain("= ")
			ctx.WriteName(n.StrValue)
		default:
			return errors.Errorf("invalid PlacementOption: %d", n.Tp)
		}
		return nil
	}
	// WriteSpecialComment
	return ctx.WriteWithSpecialComments(tidb.FeatureIDPlacement, fn)
}

type StatsOptionType int

const (
	StatsOptionBuckets StatsOptionType = 0x5000 + iota
	StatsOptionTopN
	StatsOptionColsChoice
	StatsOptionColList
	StatsOptionSampleRate
)

// TableOptionType is the type for TableOption
type TableOptionType int

// TableOption types.
const (
	TableOptionNone TableOptionType = iota
	TableOptionEngine
	TableOptionCharset
	TableOptionCollate
	TableOptionAutoIdCache
	TableOptionAutoIncrement
	TableOptionAutoRandomBase
	TableOptionComment
	TableOptionAvgRowLength
	TableOptionCheckSum
	TableOptionCompression
	TableOptionConnection
	TableOptionPassword
	TableOptionKeyBlockSize
	TableOptionMaxRows
	TableOptionMinRows
	TableOptionDelayKeyWrite
	TableOptionRowFormat
	TableOptionStatsPersistent
	TableOptionStatsAutoRecalc
	TableOptionShardRowID
	TableOptionPreSplitRegion
	TableOptionPackKeys
	TableOptionTablespace
	TableOptionNodegroup
	TableOptionDataDirectory
	TableOptionIndexDirectory
	TableOptionStorageMedia
	TableOptionStatsSamplePages
	TableOptionSecondaryEngine
	TableOptionSecondaryEngineNull
	TableOptionInsertMethod
	TableOptionTableCheckSum
	TableOptionUnion
	TableOptionEncryption
	TableOptionPlacementPolicy = TableOptionType(PlacementOptionPolicy)
	TableOptionStatsBuckets    = TableOptionType(StatsOptionBuckets)
	TableOptionStatsTopN       = TableOptionType(StatsOptionTopN)
	TableOptionStatsColsChoice = TableOptionType(StatsOptionColsChoice)
	TableOptionStatsColList    = TableOptionType(StatsOptionColList)
	TableOptionStatsSampleRate = TableOptionType(StatsOptionSampleRate)
)

// RowFormat types
const (
	RowFormatDefault uint64 = iota + 1
	RowFormatDynamic
	RowFormatFixed
	RowFormatCompressed
	RowFormatRedundant
	RowFormatCompact
	TokuDBRowFormatDefault
	TokuDBRowFormatFast
	TokuDBRowFormatSmall
	TokuDBRowFormatZlib
	TokuDBRowFormatQuickLZ
	TokuDBRowFormatLzma
	TokuDBRowFormatSnappy
	TokuDBRowFormatUncompressed
)

// OnDuplicateKeyHandlingType is the option that handle unique key values in 'CREATE TABLE ... SELECT' or `LOAD DATA`.
// See https://dev.mysql.com/doc/refman/5.7/en/create-table-select.html
// See https://dev.mysql.com/doc/refman/5.7/en/load-data.html
type OnDuplicateKeyHandlingType int

// OnDuplicateKeyHandling types
const (
	OnDuplicateKeyHandlingError OnDuplicateKeyHandlingType = iota
	OnDuplicateKeyHandlingIgnore
	OnDuplicateKeyHandlingReplace
)

const (
	TableOptionCharsetWithoutConvertTo uint64 = 0
	TableOptionCharsetWithConvertTo    uint64 = 1
)

// TableOption is used for parsing table option from SQL.
type TableOption struct {
	Tp         TableOptionType
	Default    bool
	StrValue   string
	UintValue  uint64
	BoolValue  bool
	Value      ValueExpr
	TableNames []*TableName

	sql_ir.SqlRsgInterface
}

func (n *TableOption) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := ""
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	switch n.Tp {
	case TableOptionEngine:
		prefix += "ENGINE = "
		tmpStr := "''"
		if n.StrValue != "" {
			tmpStr = n.StrValue
		}
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataNone,
			ContextFlag: sql_ir.ContextUnknown,
			Str:         tmpStr,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode

	case TableOptionCharset:
		if n.UintValue == TableOptionCharsetWithConvertTo {
			prefix += "CONVERT TO "
		} else {
			prefix += "DEFAULT "
		}
		prefix += "CHARACTER SET "
		if n.UintValue == TableOptionCharsetWithoutConvertTo {
			prefix += "= "
		}
		var lNode *sql_ir.SqlRsgIR = nil
		if n.Default {
			prefix += "DEFAULT "
		} else {
			lNode = &sql_ir.SqlRsgIR{
				IRType:      sql_ir.TypeIdentifier,
				DataType:    sql_ir.DataCharSet,
				ContextFlag: sql_ir.ContextUse,
				Str:         n.StrValue,
				Depth:       depth,
			}
		}
		rootNode.Prefix = prefix
		if lNode != nil {
			rootNode.LNode = lNode
		}
	case TableOptionCollate:
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataCollationName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.StrValue,
			Depth:       depth,
		}
		prefix = "DEFAULT COLLATE = "
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case TableOptionAutoIncrement:
		if n.BoolValue {
			prefix += "FORCE "
		}
		prefix += "AUTO_INCREMENT = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			IValue:   int64(n.UintValue),
			Str:      strconv.FormatInt(int64(n.UintValue), 10),
			Depth:    depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix

	case TableOptionAutoIdCache:
		prefix += "AUTO_ID_CACHE = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			IValue:   int64(n.UintValue),
			Str:      strconv.FormatInt(int64(n.UintValue), 10),
			Depth:    depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix
		rootNode.IRType = sql_ir.TypeTableOption
		return rootNode

	case TableOptionAutoRandomBase:
		if n.BoolValue {
			prefix += "FORCE "
			rootNode.Prefix = prefix
		}
		prefix += "AUTO_RANDOM_BASE = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			IValue:   int64(n.UintValue),
			Str:      strconv.FormatInt(int64(n.UintValue), 10),
			Depth:    depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix
	case TableOptionComment:
		prefix += "COMMENT = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Str:      n.StrValue,
			Depth:    depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix
	case TableOptionAvgRowLength:
		prefix += "AVG_ROW_LENGTH = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			Str:      strconv.FormatInt(int64(n.UintValue), 10),
			IValue:   int64(n.UintValue),
			Depth:    depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix
	case TableOptionCheckSum:
		prefix += "CHECKSUM = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			Str:      strconv.FormatInt(int64(n.UintValue), 10),
			IValue:   int64(n.UintValue),
			Depth:    depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix
	case TableOptionCompression:
		prefix += "COMPRESSION = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Str:      n.StrValue,
			Depth:    depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix
	case TableOptionConnection:
		prefix += "CONNECTION = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Str:      n.StrValue,
			Depth:    depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix
	case TableOptionPassword:
		prefix += "PASSWORD = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Str:      n.StrValue,
			Depth:    depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix
	case TableOptionKeyBlockSize:
		prefix += "KEY_BLOCK_SIZE = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			Str:      strconv.FormatInt(int64(n.UintValue), 10),
			IValue:   int64(n.UintValue),
			Depth:    depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix
	case TableOptionMaxRows:
		prefix += "MAX_ROWS = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			Str:      strconv.FormatInt(int64(n.UintValue), 10),
			IValue:   int64(n.UintValue),
			Depth:    depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix
	case TableOptionMinRows:
		prefix += "MIN_ROWS = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			Str:      strconv.FormatInt(int64(n.UintValue), 10),
			IValue:   int64(n.UintValue),
			Depth:    depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix
	case TableOptionDelayKeyWrite:
		prefix += "DELAY_KEY_WRITE = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			Str:      strconv.FormatInt(int64(n.UintValue), 10),
			IValue:   int64(n.UintValue),
			Depth:    depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix
	case TableOptionRowFormat:
		prefix += "ROW_FORMAT + "
		switch n.UintValue {
		case RowFormatDefault:
			prefix += "DEFAULT "
		case RowFormatDynamic:
			prefix += "DYNAMIC "
		case RowFormatFixed:
			prefix += "FIXED "
		case RowFormatCompressed:
			prefix += "COMPRESSED "
		case RowFormatRedundant:
			prefix += "REDUNDANT "
		case RowFormatCompact:
			prefix += "COMPACT "
		case TokuDBRowFormatDefault:
			prefix += "TOKUDB_DEFAULT "
		case TokuDBRowFormatFast:
			prefix += "TOKUDB_FAST "
		case TokuDBRowFormatSmall:
			prefix += "TOKUDB_SMALL "
		case TokuDBRowFormatZlib:
			prefix += "TOKUDB_ZLIB "
		case TokuDBRowFormatQuickLZ:
			prefix += "TOKUDB_QUICKLZ "
		case TokuDBRowFormatLzma:
			prefix += "TOKUDB_LZMA "
		case TokuDBRowFormatSnappy:
			prefix += "TOKUDB_SNAPPY "
		case TokuDBRowFormatUncompressed:
			prefix += "TOKUDB_UNCOMPRESSED "
		default:
			prefix += ""
		}
		rootNode.Prefix = prefix
	case TableOptionStatsPersistent:
		// TODO: not support
		prefix += "STATS_PERSISTENT = DEFAULT"
		rootNode.Prefix = prefix
	case TableOptionStatsAutoRecalc:
		prefix += "STATS_AUTO_RECALC = "
		var lNode *sql_ir.SqlRsgIR = nil
		if n.Default {
			prefix += "DEFAULT "
		} else {
			lNode =
				&sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeIntegerLiteral,
					DataType: sql_ir.DataNone,
					Str:      strconv.FormatInt(int64(n.UintValue), 10),
					IValue:   int64(n.UintValue),
					Depth:    depth,
				}
		}
		rootNode.Prefix = prefix
		if lNode != nil {
			rootNode.LNode = lNode
		}
	case TableOptionShardRowID:
		prefix += "SHARD_ROW_ID_BITS = "
		lNode :=
			&sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeIntegerLiteral,
				DataType: sql_ir.DataNone,
				Str:      strconv.FormatInt(int64(n.UintValue), 10),
				IValue:   int64(n.UintValue),
				Depth:    depth,
			}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case TableOptionPreSplitRegion:
		prefix += "PRE_SPLIT_REGIONS = "
		lNode :=
			&sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeIntegerLiteral,
				DataType: sql_ir.DataNone,
				Str:      strconv.FormatInt(int64(n.UintValue), 10),
				IValue:   int64(n.UintValue),
				Depth:    depth,
			}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case TableOptionPackKeys:
		// TODO: not support
		prefix += "PACK_KEYS = DEFAULT"
		rootNode.Prefix = prefix
	case TableOptionTablespace:
		prefix += "TABLESPACE = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataTableSpaceName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.StrValue,
			Depth:       depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix
	case TableOptionNodegroup:
		prefix += "NODEGROUP = "
		lNode :=
			&sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeIntegerLiteral,
				DataType: sql_ir.DataNone,
				Str:      strconv.FormatInt(int64(n.UintValue), 10),
				IValue:   int64(n.UintValue),
				Depth:    depth,
			}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case TableOptionDataDirectory:
		prefix += "DATA DIRECTORY = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Str:      n.StrValue,
			Depth:    depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix
	case TableOptionIndexDirectory:
		prefix += "INDEX DIRECTORY  = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Str:      n.StrValue,
			Depth:    depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix
	case TableOptionStorageMedia:
		prefix += "STORAGE "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Str:      n.StrValue,
			Depth:    depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix
	case TableOptionStatsSamplePages:
		prefix += "STATS_SAMPLE_PAGES = "
		var lNode *sql_ir.SqlRsgIR = nil
		if n.Default {
			prefix += "DEFAULT "
		} else {
			lNode =
				&sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeIntegerLiteral,
					DataType: sql_ir.DataNone,
					Str:      strconv.FormatInt(int64(n.UintValue), 10),
					IValue:   int64(n.UintValue),
					Depth:    depth,
				}
		}
		rootNode.Prefix = prefix
		if lNode != nil {
			rootNode.LNode = lNode
		}
	case TableOptionSecondaryEngine:
		prefix += "SECONDARY_ENGINE "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Str:      n.StrValue,
			Depth:    depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix
	case TableOptionSecondaryEngineNull:
		prefix += "SECONDARY_ENGINE = NULL"
		rootNode.Prefix = prefix
	case TableOptionInsertMethod:
		prefix += "INSERT_METHOD "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Str:      n.StrValue,
			Depth:    depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix
	case TableOptionTableCheckSum:
		prefix += "TABLE_CHECKSUM = "
		lNode :=
			&sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeIntegerLiteral,
				DataType: sql_ir.DataNone,
				Str:      strconv.FormatInt(int64(n.UintValue), 10),
				IValue:   int64(n.UintValue),
				Depth:    depth,
			}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case TableOptionUnion:
		prefix += "UNION = ("
		for i, tableName := range n.TableNames {
			midfix := ""
			if i != 0 {
				midfix = ", "
			}
			tableNameNode := tableName.LogCurrentNode(depth + 1)
			tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(tableNameNode, sql_ir.DataTableName)
			for _, tmpTableNameNode := range tableNameNodeList {
				tmpTableNameNode.DataType = sql_ir.DataTableName
				tmpTableNameNode.ContextFlag = sql_ir.ContextUse
			}

			if i == 0 {
				rootNode.LNode = tableNameNode
			} else {
				rootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    rootNode,
					RNode:    tableNameNode,
					Infix:    midfix,
					Depth:    depth,
				}
			}
		}
		rootNode.Prefix = prefix
		rootNode.Suffix = ")"
	case TableOptionEncryption:
		prefix += "ENCRYPTION = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Str:      n.StrValue,
			Depth:    depth,
		}
		rootNode.LNode = lNode
		rootNode.Prefix = prefix
	case TableOptionPlacementPolicy:
		placementOpt := PlacementOption{
			Tp:        PlacementOptionPolicy,
			UintValue: n.UintValue,
			StrValue:  n.StrValue,
		}
		return placementOpt.LogCurrentNode(depth)
	case TableOptionStatsBuckets:
		prefix += "STATS_BUCKETS = "
		var lNode *sql_ir.SqlRsgIR = nil
		if n.Default {
			prefix += "DEFAULT "
		} else {
			lNode =
				&sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeIntegerLiteral,
					DataType: sql_ir.DataNone,
					Str:      strconv.FormatInt(int64(n.UintValue), 10),
					IValue:   int64(n.UintValue),
					Depth:    depth,
				}
		}
		rootNode.Prefix = prefix
		if lNode != nil {
			rootNode.LNode = lNode
		}
	case TableOptionStatsTopN:
		prefix += "STATS_TOPN = "
		var lNode *sql_ir.SqlRsgIR = nil
		if n.Default {
			prefix += "DEFAULT "
		} else {
			lNode =
				&sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeIntegerLiteral,
					DataType: sql_ir.DataNone,
					Str:      strconv.FormatInt(int64(n.UintValue), 10),
					IValue:   int64(n.UintValue),
					Depth:    depth,
				}
		}
		rootNode.Prefix = prefix
		if lNode != nil {
			rootNode.LNode = lNode
		}
	case TableOptionStatsSampleRate:
		prefix += "STATS_SAMPLE_RATE = "
		var lNode *sql_ir.SqlRsgIR = nil
		if n.Default {
			prefix += "DEFAULT "
		} else {
			lNode =
				&sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeIntegerLiteral,
					DataType: sql_ir.DataNone,
					Str:      "1",      // Cannot cast the original type
					IValue:   int64(1), // Cannot cast the original type
					Depth:    depth,
				}
		}
		rootNode.Prefix = prefix
		if lNode != nil {
			rootNode.LNode = lNode
		}
	case TableOptionStatsColsChoice:
		prefix += "STATS_COL_CHOICE = "
		var lNode *sql_ir.SqlRsgIR = nil
		if n.Default {
			prefix += "DEFAULT "
		} else {
			lNode =
				&sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					Str:      n.StrValue, // Cannot cast the original type
					Depth:    depth,
				}
		}
		rootNode.Prefix = prefix
		if lNode != nil {
			rootNode.LNode = lNode
		}

	case TableOptionStatsColList:
		prefix += "STATS_COL_LIST = "
		var lNode *sql_ir.SqlRsgIR = nil
		if n.Default {
			prefix += "DEFAULT "
		} else {
			lNode =
				&sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					Str:      n.StrValue, // Cannot cast the original type
					Depth:    depth,
				}
		}
		rootNode.Prefix = prefix
		if lNode != nil {
			rootNode.LNode = lNode
		}

	default:
		// Do nothing.
	}

	rootNode.IRType = sql_ir.TypeTableOption
	return nil

}

func (n *TableOption) Restore(ctx *format.RestoreCtx) error {
	switch n.Tp {
	case TableOptionEngine:
		ctx.WriteKeyWord("ENGINE ")
		ctx.WritePlain("= ")
		if n.StrValue != "" {
			ctx.WritePlain(n.StrValue)
		} else {
			ctx.WritePlain("''")
		}
	case TableOptionCharset:
		if n.UintValue == TableOptionCharsetWithConvertTo {
			ctx.WriteKeyWord("CONVERT TO ")
		} else {
			ctx.WriteKeyWord("DEFAULT ")
		}
		ctx.WriteKeyWord("CHARACTER SET ")
		if n.UintValue == TableOptionCharsetWithoutConvertTo {
			ctx.WriteKeyWord("= ")
		}
		if n.Default {
			ctx.WriteKeyWord("DEFAULT")
		} else {
			ctx.WriteKeyWord(n.StrValue)
		}
	case TableOptionCollate:
		ctx.WriteKeyWord("DEFAULT COLLATE ")
		ctx.WritePlain("= ")
		ctx.WriteKeyWord(n.StrValue)
	case TableOptionAutoIncrement:
		if n.BoolValue {
			_ = ctx.WriteWithSpecialComments(tidb.FeatureIDForceAutoInc, func() error {
				ctx.WriteKeyWord("FORCE")
				return nil
			})
			ctx.WritePlain(" ")
		}
		ctx.WriteKeyWord("AUTO_INCREMENT ")
		ctx.WritePlain("= ")
		ctx.WritePlainf("%d", n.UintValue)
	case TableOptionAutoIdCache:
		_ = ctx.WriteWithSpecialComments(tidb.FeatureIDAutoIDCache, func() error {
			ctx.WriteKeyWord("AUTO_ID_CACHE ")
			ctx.WritePlain("= ")
			ctx.WritePlainf("%d", n.UintValue)
			return nil
		})
	case TableOptionAutoRandomBase:
		if n.BoolValue {
			_ = ctx.WriteWithSpecialComments(tidb.FeatureIDForceAutoInc, func() error {
				ctx.WriteKeyWord("FORCE")
				return nil
			})
			ctx.WritePlain(" ")
		}
		_ = ctx.WriteWithSpecialComments(tidb.FeatureIDAutoRandomBase, func() error {
			ctx.WriteKeyWord("AUTO_RANDOM_BASE ")
			ctx.WritePlain("= ")
			ctx.WritePlainf("%d", n.UintValue)
			return nil
		})
	case TableOptionComment:
		ctx.WriteKeyWord("COMMENT ")
		ctx.WritePlain("= ")
		ctx.WriteString(n.StrValue)
	case TableOptionAvgRowLength:
		ctx.WriteKeyWord("AVG_ROW_LENGTH ")
		ctx.WritePlain("= ")
		ctx.WritePlainf("%d", n.UintValue)
	case TableOptionCheckSum:
		ctx.WriteKeyWord("CHECKSUM ")
		ctx.WritePlain("= ")
		ctx.WritePlainf("%d", n.UintValue)
	case TableOptionCompression:
		ctx.WriteKeyWord("COMPRESSION ")
		ctx.WritePlain("= ")
		ctx.WriteString(n.StrValue)
	case TableOptionConnection:
		ctx.WriteKeyWord("CONNECTION ")
		ctx.WritePlain("= ")
		ctx.WriteString(n.StrValue)
	case TableOptionPassword:
		ctx.WriteKeyWord("PASSWORD ")
		ctx.WritePlain("= ")
		ctx.WriteString(n.StrValue)
	case TableOptionKeyBlockSize:
		ctx.WriteKeyWord("KEY_BLOCK_SIZE ")
		ctx.WritePlain("= ")
		ctx.WritePlainf("%d", n.UintValue)
	case TableOptionMaxRows:
		ctx.WriteKeyWord("MAX_ROWS ")
		ctx.WritePlain("= ")
		ctx.WritePlainf("%d", n.UintValue)
	case TableOptionMinRows:
		ctx.WriteKeyWord("MIN_ROWS ")
		ctx.WritePlain("= ")
		ctx.WritePlainf("%d", n.UintValue)
	case TableOptionDelayKeyWrite:
		ctx.WriteKeyWord("DELAY_KEY_WRITE ")
		ctx.WritePlain("= ")
		ctx.WritePlainf("%d", n.UintValue)
	case TableOptionRowFormat:
		ctx.WriteKeyWord("ROW_FORMAT ")
		ctx.WritePlain("= ")
		switch n.UintValue {
		case RowFormatDefault:
			ctx.WriteKeyWord("DEFAULT")
		case RowFormatDynamic:
			ctx.WriteKeyWord("DYNAMIC")
		case RowFormatFixed:
			ctx.WriteKeyWord("FIXED")
		case RowFormatCompressed:
			ctx.WriteKeyWord("COMPRESSED")
		case RowFormatRedundant:
			ctx.WriteKeyWord("REDUNDANT")
		case RowFormatCompact:
			ctx.WriteKeyWord("COMPACT")
		case TokuDBRowFormatDefault:
			ctx.WriteKeyWord("TOKUDB_DEFAULT")
		case TokuDBRowFormatFast:
			ctx.WriteKeyWord("TOKUDB_FAST")
		case TokuDBRowFormatSmall:
			ctx.WriteKeyWord("TOKUDB_SMALL")
		case TokuDBRowFormatZlib:
			ctx.WriteKeyWord("TOKUDB_ZLIB")
		case TokuDBRowFormatQuickLZ:
			ctx.WriteKeyWord("TOKUDB_QUICKLZ")
		case TokuDBRowFormatLzma:
			ctx.WriteKeyWord("TOKUDB_LZMA")
		case TokuDBRowFormatSnappy:
			ctx.WriteKeyWord("TOKUDB_SNAPPY")
		case TokuDBRowFormatUncompressed:
			ctx.WriteKeyWord("TOKUDB_UNCOMPRESSED")
		default:
			return errors.Errorf("invalid TableOption: TableOptionRowFormat: %d", n.UintValue)
		}
	case TableOptionStatsPersistent:
		// TODO: not support
		ctx.WriteKeyWord("STATS_PERSISTENT ")
		ctx.WritePlain("= ")
		ctx.WriteKeyWord("DEFAULT")
		ctx.WritePlain(" /* TableOptionStatsPersistent is not supported */ ")
	case TableOptionStatsAutoRecalc:
		ctx.WriteKeyWord("STATS_AUTO_RECALC ")
		ctx.WritePlain("= ")
		if n.Default {
			ctx.WriteKeyWord("DEFAULT")
		} else {
			ctx.WritePlainf("%d", n.UintValue)
		}
	case TableOptionShardRowID:
		_ = ctx.WriteWithSpecialComments(tidb.FeatureIDTiDB, func() error {
			ctx.WriteKeyWord("SHARD_ROW_ID_BITS ")
			ctx.WritePlainf("= %d", n.UintValue)
			return nil
		})
	case TableOptionPreSplitRegion:
		_ = ctx.WriteWithSpecialComments(tidb.FeatureIDTiDB, func() error {
			ctx.WriteKeyWord("PRE_SPLIT_REGIONS ")
			ctx.WritePlainf("= %d", n.UintValue)
			return nil
		})
	case TableOptionPackKeys:
		// TODO: not support
		ctx.WriteKeyWord("PACK_KEYS ")
		ctx.WritePlain("= ")
		ctx.WriteKeyWord("DEFAULT")
		ctx.WritePlain(" /* TableOptionPackKeys is not supported */ ")
	case TableOptionTablespace:
		ctx.WriteKeyWord("TABLESPACE ")
		ctx.WritePlain("= ")
		ctx.WriteName(n.StrValue)
	case TableOptionNodegroup:
		ctx.WriteKeyWord("NODEGROUP ")
		ctx.WritePlainf("= %d", n.UintValue)
	case TableOptionDataDirectory:
		ctx.WriteKeyWord("DATA DIRECTORY ")
		ctx.WritePlain("= ")
		ctx.WriteString(n.StrValue)
	case TableOptionIndexDirectory:
		ctx.WriteKeyWord("INDEX DIRECTORY ")
		ctx.WritePlain("= ")
		ctx.WriteString(n.StrValue)
	case TableOptionStorageMedia:
		ctx.WriteKeyWord("STORAGE ")
		ctx.WriteKeyWord(n.StrValue)
	case TableOptionStatsSamplePages:
		ctx.WriteKeyWord("STATS_SAMPLE_PAGES ")
		ctx.WritePlain("= ")
		if n.Default {
			ctx.WriteKeyWord("DEFAULT")
		} else {
			ctx.WritePlainf("%d", n.UintValue)
		}
	case TableOptionSecondaryEngine:
		ctx.WriteKeyWord("SECONDARY_ENGINE ")
		ctx.WritePlain("= ")
		ctx.WriteString(n.StrValue)
	case TableOptionSecondaryEngineNull:
		ctx.WriteKeyWord("SECONDARY_ENGINE ")
		ctx.WritePlain("= ")
		ctx.WriteKeyWord("NULL")
	case TableOptionInsertMethod:
		ctx.WriteKeyWord("INSERT_METHOD ")
		ctx.WritePlain("= ")
		ctx.WriteKeyWord(n.StrValue)
	case TableOptionTableCheckSum:
		ctx.WriteKeyWord("TABLE_CHECKSUM ")
		ctx.WritePlain("= ")
		ctx.WritePlainf("%d", n.UintValue)
	case TableOptionUnion:
		ctx.WriteKeyWord("UNION ")
		ctx.WritePlain("= (")
		for i, tableName := range n.TableNames {
			if i != 0 {
				ctx.WritePlain(",")
			}
			tableName.Restore(ctx)
		}
		ctx.WritePlain(")")
	case TableOptionEncryption:
		ctx.WriteKeyWord("ENCRYPTION ")
		ctx.WritePlain("= ")
		ctx.WriteString(n.StrValue)
	case TableOptionPlacementPolicy:
		if ctx.Flags.HasSkipPlacementRuleForRestoreFlag() {
			return nil
		}
		placementOpt := PlacementOption{
			Tp:        PlacementOptionPolicy,
			UintValue: n.UintValue,
			StrValue:  n.StrValue,
		}
		return placementOpt.Restore(ctx)
	case TableOptionStatsBuckets:
		ctx.WriteKeyWord("STATS_BUCKETS ")
		ctx.WritePlain("= ")
		if n.Default {
			ctx.WriteKeyWord("DEFAULT")
		} else {
			ctx.WritePlainf("%d", n.UintValue)
		}
	case TableOptionStatsTopN:
		ctx.WriteKeyWord("STATS_TOPN ")
		ctx.WritePlain("= ")
		if n.Default {
			ctx.WriteKeyWord("DEFAULT")
		} else {
			ctx.WritePlainf("%d", n.UintValue)
		}
	case TableOptionStatsSampleRate:
		ctx.WriteKeyWord("STATS_SAMPLE_RATE ")
		ctx.WritePlain("= ")
		if n.Default {
			ctx.WriteKeyWord("DEFAULT")
		} else {
			ctx.WritePlainf("%v", n.Value.GetValue())
		}
	case TableOptionStatsColsChoice:
		ctx.WriteKeyWord("STATS_COL_CHOICE ")
		ctx.WritePlain("= ")
		if n.Default {
			ctx.WriteKeyWord("DEFAULT")
		} else {
			ctx.WriteString(n.StrValue)
		}
	case TableOptionStatsColList:
		ctx.WriteKeyWord("STATS_COL_LIST ")
		ctx.WritePlain("= ")
		if n.Default {
			ctx.WriteKeyWord("DEFAULT")
		} else {
			ctx.WriteString(n.StrValue)
		}
	default:
		return errors.Errorf("invalid TableOption: %d", n.Tp)
	}
	return nil
}

// SequenceOptionType is the type for SequenceOption
type SequenceOptionType int

// SequenceOption types.
const (
	SequenceOptionNone SequenceOptionType = iota
	SequenceOptionIncrementBy
	SequenceStartWith
	SequenceNoMinValue
	SequenceMinValue
	SequenceNoMaxValue
	SequenceMaxValue
	SequenceNoCache
	SequenceCache
	SequenceNoCycle
	SequenceCycle
	// SequenceRestart is only used in alter sequence statement.
	SequenceRestart
	SequenceRestartWith
)

// SequenceOption is used for parsing sequence option from SQL.
type SequenceOption struct {
	Tp       SequenceOptionType
	IntValue int64
	sql_ir.SqlRsgInterface
}

func (n *SequenceOption) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := ""
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}

	switch n.Tp {
	case SequenceOptionIncrementBy:
		prefix += "INCREMENT BY "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			IValue:   n.IntValue,
			Str:      strconv.FormatInt(n.IntValue, 10),
			Depth:    depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case SequenceStartWith:
		prefix += "START WITH "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			IValue:   n.IntValue,
			Str:      strconv.FormatInt(n.IntValue, 10),
			Depth:    depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case SequenceNoMinValue:
		prefix += "NO MINVALUE "
		rootNode.Prefix = prefix
	case SequenceMinValue:
		prefix += "MINVALUE "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			IValue:   n.IntValue,
			Str:      strconv.FormatInt(n.IntValue, 10),
			Depth:    depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode

	case SequenceNoMaxValue:
		prefix += "NO MAXVALUE "
		rootNode.Prefix = prefix
	case SequenceMaxValue:
		prefix += "MAXVALUE  "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			IValue:   n.IntValue,
			Str:      strconv.FormatInt(n.IntValue, 10),
			Depth:    depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode

	case SequenceNoCache:
		prefix += "NOCACHE "
	case SequenceCache:
		prefix += "CACHE  "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			IValue:   n.IntValue,
			Str:      strconv.FormatInt(n.IntValue, 10),
			Depth:    depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case SequenceNoCycle:
		prefix += "NOCYCLE "
		rootNode.Prefix = prefix
	case SequenceCycle:
		prefix += "CYCLE "
		rootNode.Prefix = prefix
	case SequenceRestart:
		prefix += "RESTART "
		rootNode.Prefix = prefix
	case SequenceRestartWith:
		prefix += "RESTART WITH "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			IValue:   n.IntValue,
			Str:      strconv.FormatInt(n.IntValue, 10),
			Depth:    depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode

	default:
		// Do nothing here.
	}
	rootNode.IRType = sql_ir.TypeSequenceOption
	return rootNode

}

func (n *SequenceOption) Restore(ctx *format.RestoreCtx) error {
	switch n.Tp {
	case SequenceOptionIncrementBy:
		ctx.WriteKeyWord("INCREMENT BY ")
		ctx.WritePlainf("%d", n.IntValue)
	case SequenceStartWith:
		ctx.WriteKeyWord("START WITH ")
		ctx.WritePlainf("%d", n.IntValue)
	case SequenceNoMinValue:
		ctx.WriteKeyWord("NO MINVALUE")
	case SequenceMinValue:
		ctx.WriteKeyWord("MINVALUE ")
		ctx.WritePlainf("%d", n.IntValue)
	case SequenceNoMaxValue:
		ctx.WriteKeyWord("NO MAXVALUE")
	case SequenceMaxValue:
		ctx.WriteKeyWord("MAXVALUE ")
		ctx.WritePlainf("%d", n.IntValue)
	case SequenceNoCache:
		ctx.WriteKeyWord("NOCACHE")
	case SequenceCache:
		ctx.WriteKeyWord("CACHE ")
		ctx.WritePlainf("%d", n.IntValue)
	case SequenceNoCycle:
		ctx.WriteKeyWord("NOCYCLE")
	case SequenceCycle:
		ctx.WriteKeyWord("CYCLE")
	case SequenceRestart:
		ctx.WriteKeyWord("RESTART")
	case SequenceRestartWith:
		ctx.WriteKeyWord("RESTART WITH ")
		ctx.WritePlainf("%d", n.IntValue)
	default:
		return errors.Errorf("invalid SequenceOption: %d", n.Tp)
	}
	return nil
}

// ColumnPositionType is the type for ColumnPosition.
type ColumnPositionType int

// ColumnPosition Types
const (
	ColumnPositionNone ColumnPositionType = iota
	ColumnPositionFirst
	ColumnPositionAfter
)

// ColumnPosition represent the position of the newly added column
type ColumnPosition struct {
	node
	// Tp is either ColumnPositionNone, ColumnPositionFirst or ColumnPositionAfter.
	Tp ColumnPositionType
	// RelativeColumn is the column the newly added column after if type is ColumnPositionAfter
	RelativeColumn *ColumnName
}

func (n *ColumnPosition) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := ""
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}

	switch n.Tp {
	case ColumnPositionNone:
		// do nothing
	case ColumnPositionFirst:
		prefix += "FIRST "
		rootNode.Prefix = prefix
	case ColumnPositionAfter:
		prefix += "AFTER "
		lNode := n.RelativeColumn.LogCurrentNode(depth + 1)
		columnNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(lNode, sql_ir.DataColumnName)
		for _, columnNameNode := range columnNameNodeList {
			columnNameNode.DataType = sql_ir.DataColumnName
			columnNameNode.ContextFlag = sql_ir.ContextUse
		}

		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	default:
		// do nothing.
	}

	rootNode.IRType = sql_ir.TypeColumnPosition
	return rootNode

}

// Restore implements Node interface.
func (n *ColumnPosition) Restore(ctx *format.RestoreCtx) error {
	switch n.Tp {
	case ColumnPositionNone:
		// do nothing
	case ColumnPositionFirst:
		ctx.WriteKeyWord("FIRST")
	case ColumnPositionAfter:
		ctx.WriteKeyWord("AFTER ")
		if err := n.RelativeColumn.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore ColumnPosition.RelativeColumn")
		}
	default:
		return errors.Errorf("invalid ColumnPositionType: %d", n.Tp)
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *ColumnPosition) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*ColumnPosition)
	if n.RelativeColumn != nil {
		node, ok := n.RelativeColumn.Accept(v)
		if !ok {
			return n, false
		}
		n.RelativeColumn = node.(*ColumnName)
	}
	return v.Leave(n)
}

// AlterTableType is the type for AlterTableSpec.
type AlterTableType int

// AlterTable types.
const (
	AlterTableOption AlterTableType = iota + 1
	AlterTableAddColumns
	AlterTableAddConstraint
	AlterTableDropColumn
	AlterTableDropPrimaryKey
	AlterTableDropIndex
	AlterTableDropForeignKey
	AlterTableModifyColumn
	AlterTableChangeColumn
	AlterTableRenameColumn
	AlterTableRenameTable
	AlterTableAlterColumn
	AlterTableLock
	AlterTableWriteable
	AlterTableAlgorithm
	AlterTableRenameIndex
	AlterTableForce
	AlterTableAddPartitions
	// A tombstone for `AlterTableAlterPartition`. It will never be used anymore.
	// Just left a tombstone here to keep the enum number unchanged.
	__DEPRECATED_AlterTableAlterPartition
	AlterTablePartitionAttributes
	AlterTablePartitionOptions
	AlterTableCoalescePartitions
	AlterTableDropPartition
	AlterTableTruncatePartition
	AlterTablePartition
	AlterTableEnableKeys
	AlterTableDisableKeys
	AlterTableRemovePartitioning
	AlterTableWithValidation
	AlterTableWithoutValidation
	AlterTableSecondaryLoad
	AlterTableSecondaryUnload
	AlterTableRebuildPartition
	AlterTableReorganizePartition
	AlterTableCheckPartitions
	AlterTableExchangePartition
	AlterTableOptimizePartition
	AlterTableRepairPartition
	AlterTableImportPartitionTablespace
	AlterTableDiscardPartitionTablespace
	AlterTableAlterCheck
	AlterTableDropCheck
	AlterTableImportTablespace
	AlterTableDiscardTablespace
	AlterTableIndexInvisible
	// TODO: Add more actions
	AlterTableOrderByColumns
	// AlterTableSetTiFlashReplica uses to set the table TiFlash replica.
	AlterTableSetTiFlashReplica
	// A tombstone for `AlterTablePlacement`. It will never be used anymore.
	// Just left a tombstone here to keep the enum number unchanged.
	__DEPRECATED_AlterTablePlacement
	AlterTableAddStatistics
	AlterTableDropStatistics
	AlterTableAttributes
	AlterTableCache
	AlterTableNoCache
	AlterTableStatsOptions
)

// LockType is the type for AlterTableSpec.
// See https://dev.mysql.com/doc/refman/5.7/en/alter-table.html#alter-table-concurrency
type LockType byte

func (n LockType) String() string {
	switch n {
	case LockTypeNone:
		return "NONE"
	case LockTypeDefault:
		return "DEFAULT"
	case LockTypeShared:
		return "SHARED"
	case LockTypeExclusive:
		return "EXCLUSIVE"
	}
	return ""
}

// Lock Types.
const (
	LockTypeNone LockType = iota + 1
	LockTypeDefault
	LockTypeShared
	LockTypeExclusive
)

// AlgorithmType is the algorithm of the DDL operations.
// See https://dev.mysql.com/doc/refman/8.0/en/alter-table.html#alter-table-performance.
type AlgorithmType byte

// DDL algorithms.
// For now, TiDB only supported inplace and instance algorithms. If the user specify `copy`,
// will get an error.
const (
	AlgorithmTypeDefault AlgorithmType = iota
	AlgorithmTypeCopy
	AlgorithmTypeInplace
	AlgorithmTypeInstant
)

func (a AlgorithmType) String() string {
	switch a {
	case AlgorithmTypeDefault:
		return "DEFAULT"
	case AlgorithmTypeCopy:
		return "COPY"
	case AlgorithmTypeInplace:
		return "INPLACE"
	case AlgorithmTypeInstant:
		return "INSTANT"
	default:
		return "DEFAULT"
	}
}

// AlterTableSpec represents alter table specification.
type AlterTableSpec struct {
	node

	// only supported by MariaDB 10.0.2+ (DROP COLUMN, CHANGE COLUMN, MODIFY COLUMN, DROP INDEX, DROP FOREIGN KEY, DROP PARTITION)
	// see https://mariadb.com/kb/en/library/alter-table/
	IfExists bool

	// only supported by MariaDB 10.0.2+ (ADD COLUMN, ADD PARTITION)
	// see https://mariadb.com/kb/en/library/alter-table/
	IfNotExists bool

	NoWriteToBinlog bool
	OnAllPartitions bool

	Tp               AlterTableType
	Name             string
	IndexName        model.CIStr
	Constraint       *Constraint
	Options          []*TableOption
	OrderByList      []*AlterOrderItem
	NewTable         *TableName
	NewColumns       []*ColumnDef
	NewConstraints   []*Constraint
	OldColumnName    *ColumnName
	NewColumnName    *ColumnName
	Position         *ColumnPosition
	LockType         LockType
	Algorithm        AlgorithmType
	Comment          string
	FromKey          model.CIStr
	ToKey            model.CIStr
	Partition        *PartitionOptions
	PartitionNames   []model.CIStr
	PartDefinitions  []*PartitionDefinition
	WithValidation   bool
	Num              uint64
	Visibility       IndexVisibility
	TiFlashReplica   *TiFlashReplicaSpec
	Writeable        bool
	Statistics       *StatisticsSpec
	AttributesSpec   *AttributesSpec
	StatsOptionsSpec *StatsOptionsSpec
}

type TiFlashReplicaSpec struct {
	Count  uint64
	Labels []string
}

// AlterOrderItem represents an item in order by at alter table stmt.
type AlterOrderItem struct {
	node
	Column *ColumnName
	Desc   bool
}

func (n *AlterOrderItem) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	lNode := n.Column.LogCurrentNode(depth + 1)
	columnNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(lNode, sql_ir.DataColumnName)
	for _, columnNameNode := range columnNameNodeList {
		columnNameNode.DataType = sql_ir.DataColumnName
		columnNameNode.ContextFlag = sql_ir.ContextUse
	}

	midfix := ""
	if n.Desc {
		midfix = " DESC"
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Infix:    midfix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeAlterOrderItem
	return rootNode

}

// Restore implements Node interface.
func (n *AlterOrderItem) Restore(ctx *format.RestoreCtx) error {
	if err := n.Column.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore AlterOrderItem.Column")
	}
	if n.Desc {
		ctx.WriteKeyWord(" DESC")
	}
	return nil
}

func (n *AlterTableSpec) IsAllPlacementRule() bool {
	switch n.Tp {
	case AlterTablePartitionAttributes, AlterTablePartitionOptions, AlterTableOption, AlterTableAttributes:
		for _, o := range n.Options {
			if o.Tp != TableOptionPlacementPolicy {
				return false
			}
		}
		return true
	default:
		return false
	}
}

func (n *AlterTableSpec) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	if n.IsAllPlacementRule() {
		rootNode.IRType = sql_ir.TypeAlterTableSpec
		return rootNode
	}
	prefix := ""

	switch n.Tp {
	case AlterTableSetTiFlashReplica:
		prefix += "SET TIFLASH REPLICA "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			IValue:   int64(n.TiFlashReplica.Count),
			Str:      strconv.FormatInt(int64(n.TiFlashReplica.Count), 10),
			Depth:    depth,
		}
		if len(n.TiFlashReplica.Labels) == 0 {
			rootNode.LNode = lNode
			rootNode.Prefix = prefix
			break
		}
		midfix := " LOCATION LABELS "
		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for i, v := range n.TiFlashReplica.Labels {
			tmpMidfix := ""
			if i > 0 {
				tmpMidfix = ", "
			}
			curStrNode := &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				Str:      v,
				Depth:    depth,
			}
			if i == 0 {
				tmpRootNode.LNode = curStrNode
			} else { //i > 0
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    curStrNode,
					Infix:    tmpMidfix,
					Depth:    depth,
				}
			}
		}
		rootNode.LNode = lNode
		rootNode.RNode = tmpRootNode
		rootNode.Prefix = prefix
		rootNode.Infix = midfix

	case AlterTableAddStatistics:
		prefix += "ADD STATS_EXTENDED "
		if n.IfNotExists {
			prefix += "IF NOT EXISTS "
		}
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataStatsName,
			ContextFlag: sql_ir.ContextDefine,
			Str:         n.Statistics.StatsName,
			Depth:       depth,
		}

		midfix := ""
		switch n.Statistics.StatsType {
		case StatsTypeCardinality:
			midfix = " CARDINALITY("
		case StatsTypeDependency:
			midfix = " DEPENDENCY("
		case StatsTypeCorrelation:
			midfix = " CORRELATION("
		}

		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for i, col := range n.Statistics.Columns {
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
					Infix:    tmpMidfix,
					LNode:    tmpRootNode,
					RNode:    colNode,
					Depth:    depth,
				}
			}
		}

		rootNode.Prefix = prefix
		rootNode.Infix = midfix
		rootNode.Suffix = ")"
		rootNode.LNode = lNode
		rootNode.RNode = tmpRootNode

	case AlterTableDropStatistics:
		prefix += "DROP STATS_EXTENDED "
		if n.IfExists {
			prefix += "IF EXISTS "
		}
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataStatsName,
			ContextFlag: sql_ir.ContextUndefine,
			Str:         n.Statistics.StatsName,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode

	case AlterTableOption:
		switch {
		case len(n.Options) == 2 && n.Options[0].Tp == TableOptionCharset && n.Options[1].Tp == TableOptionCollate:
			if n.Options[0].UintValue == TableOptionCharsetWithConvertTo {
				prefix += "CONVERT TO "
			}
			prefix += "CHARACTER SET "
			var lNode *sql_ir.SqlRsgIR = nil
			if n.Options[0].Default {
				prefix += "DEFAULT"
			} else {
				lNode = &sql_ir.SqlRsgIR{
					IRType:      sql_ir.TypeIdentifier,
					DataType:    sql_ir.DataCharSet,
					ContextFlag: sql_ir.ContextUse,
					Str:         n.Options[0].StrValue,
					Depth:       depth,
				}
			}
			rootNode.Prefix = prefix
			rootNode.LNode = lNode
			prefix = ""

			midfix := " COLLATE "
			rNode := &sql_ir.SqlRsgIR{
				IRType:      sql_ir.TypeIdentifier,
				DataType:    sql_ir.DataCollationName,
				ContextFlag: sql_ir.ContextUse,
				Str:         n.Options[1].StrValue,
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

		case n.Options[0].Tp == TableOptionCharset && n.Options[0].Default:
			if n.Options[0].UintValue == TableOptionCharsetWithConvertTo {
				prefix += "CONVERT TO "
			}
			prefix += "CHARACTER SET DEFAULT"

		default:
			for i, opt := range n.Options {
				optNode := opt.LogCurrentNode(depth + 1)
				if i == 0 {
					rootNode.LNode = optNode
				} else { // i > 0
					rootNode = &sql_ir.SqlRsgIR{
						IRType:   sql_ir.TypeUnknown,
						DataType: sql_ir.DataNone,
						LNode:    rootNode,
						RNode:    optNode,
						Infix:    " ",
						Depth:    depth,
					}
				}
			}
		}
	case AlterTableAddColumns:
		prefix += "ADD COLUMN "
		if n.IfNotExists {
			prefix += "IF NOT EXISTS "
		}
		if n.Position != nil && len(n.NewColumns) == 1 {
			lNode := n.NewColumns[0].LogCurrentNode(depth + 1)
			midfix := ""
			if n.Position.Tp != ColumnPositionNone {
				midfix = " "
			}
			rNode := n.Position.LogCurrentNode(depth + 1)

			rootNode.LNode = lNode
			rootNode.RNode = rNode
			rootNode.Infix = midfix

		} else {
			lenCols := len(n.NewColumns)
			tmpRootNode := &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				Depth:    depth,
			}
			for i, col := range n.NewColumns {
				tmpMidfix := ""
				if i != 0 {
					tmpMidfix = ", "
				}
				colNode := col.LogCurrentNode(depth + 1)
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
			for i, constraint := range n.NewConstraints {
				tmpMidfix := ""
				if i != 0 || lenCols >= 1 {
					tmpMidfix = ", "
				}
				constraintNode := constraint.LogCurrentNode(depth + 1)
				if i == 0 && lenCols == 0 {
					tmpRootNode.LNode = constraintNode
				} else { // i > 0
					tmpRootNode = &sql_ir.SqlRsgIR{
						IRType:   sql_ir.TypeUnknown,
						DataType: sql_ir.DataNone,
						LNode:    tmpRootNode,
						RNode:    constraintNode,
						Infix:    tmpMidfix,
						Depth:    depth,
					}
				}
			}
			tmpRootNode.Prefix = "("
			tmpRootNode.Suffix = ")"

			rootNode.Prefix = prefix
			rootNode.LNode = tmpRootNode
		}
	case AlterTableAddConstraint:
		prefix += "ADD "
		lNode := n.Constraint.LogCurrentNode(depth + 1)

		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case AlterTableDropColumn:
		prefix += "DROP COLUMN "
		if n.IfExists {
			prefix += "IF EXISTS "
		}

		lNode := n.OldColumnName.LogCurrentNode(depth + 1)
		columnNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(lNode, sql_ir.DataColumnName)
		for _, columnNameNode := range columnNameNodeList {
			columnNameNode.DataType = sql_ir.DataColumnName
			columnNameNode.ContextFlag = sql_ir.ContextUndefine
		}

		rootNode.Prefix = prefix
		rootNode.LNode = lNode

	// TODO: RestrictOrCascadeOpt not support
	case AlterTableDropPrimaryKey:
		prefix += "DROP PRIMARY KEY"
		rootNode.Prefix = prefix
	case AlterTableDropIndex:
		prefix += "DROP INDEX "
		if n.IfExists {
			prefix += "IF EXISTS "
		}
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataIndexName,
			ContextFlag: sql_ir.ContextUndefine,
			Str:         n.Name,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode

	case AlterTableDropForeignKey:
		prefix += "DROP FOREIGN KEY "
		if n.IfExists {
			prefix += "IF EXISTS "
		}
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataForeignKeyName,
			ContextFlag: sql_ir.ContextUndefine,
			Str:         n.Name,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode

	case AlterTableModifyColumn:
		prefix = "MODIFY COLUMN "
		if n.IfExists {
			prefix += "IF EXISTS "
		}
		lNode := n.NewColumns[0].LogCurrentNode(depth + 1)
		midfix := ""
		if n.Position.Tp != ColumnPositionNone {
			midfix = " "
		}
		rNode := n.Position.LogCurrentNode(depth + 1)

		rootNode.Prefix = prefix
		rootNode.Infix = midfix
		rootNode.LNode = lNode
		rootNode.RNode = rNode

	case AlterTableChangeColumn:
		prefix += "CHANGE COLUMN "
		if n.IfExists {
			prefix += "IF EXISTS "
		}
		lNode := n.OldColumnName.LogCurrentNode(depth + 1)
		columnNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(lNode, sql_ir.DataColumnName)
		for _, columnNameNode := range columnNameNodeList {
			columnNameNode.DataType = sql_ir.DataColumnName
			columnNameNode.ContextFlag = sql_ir.ContextUndefine
		}
		midfix := " "
		rNode := n.NewColumns[0].LogCurrentNode(depth + 1)
		columnNameNodeList = sql_ir.GetSubNodeFromParentNodeWithDataType(rNode, sql_ir.DataColumnName)
		for _, columnNameNode := range columnNameNodeList {
			columnNameNode.DataType = sql_ir.DataColumnName
			columnNameNode.ContextFlag = sql_ir.ContextDefine
		}

		rootNode.Prefix = prefix
		rootNode.Infix = midfix
		rootNode.LNode = lNode
		rootNode.RNode = rNode

		midfix = ""
		if n.Position.Tp != ColumnPositionNone {
			midfix = " "
		}
		rNode = n.Position.LogCurrentNode(depth + 1)

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Infix:    midfix,
			Depth:    depth,
		}

	case AlterTableRenameColumn:
		prefix += "RENAME COLUMN "
		lNode := n.OldColumnName.LogCurrentNode(depth + 1)
		columnNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(lNode, sql_ir.DataColumnName)
		for _, columnNameNode := range columnNameNodeList {
			columnNameNode.DataType = sql_ir.DataColumnName
			columnNameNode.ContextFlag = sql_ir.ContextUndefine
		}

		midfix := " TO "
		rNode := n.NewColumnName.LogCurrentNode(depth + 1)
		columnNameNodeList = sql_ir.GetSubNodeFromParentNodeWithDataType(rNode, sql_ir.DataColumnName)
		for _, columnNameNode := range columnNameNodeList {
			columnNameNode.DataType = sql_ir.DataColumnName
			columnNameNode.ContextFlag = sql_ir.ContextDefine
		}

		rootNode.Prefix = prefix
		rootNode.Infix = midfix
		rootNode.LNode = lNode
		rootNode.RNode = rNode

	case AlterTableRenameTable:
		prefix += "RENAME AS "
		lNode := n.NewTable.LogCurrentNode(depth + 1)
		newTableNameList := sql_ir.GetSubNodeFromParentNodeWithDataType(lNode, sql_ir.DataTableName)
		for _, newTableName := range newTableNameList {
			newTableName.DataType = sql_ir.DataTableName
			newTableName.ContextFlag = sql_ir.ContextDefine
		}

		rootNode.Prefix = prefix
		rootNode.LNode = lNode

	case AlterTableAlterColumn:
		prefix += "ALTER COLUMN "
		lNode := n.NewColumns[0].LogCurrentNode(depth + 1)
		if len(n.NewColumns[0].Options) == 1 {
			midfix := "SET DEFAULT "
			expr := n.NewColumns[0].Options[0].Expr
			if valueExpr, ok := expr.(ValueExpr); ok {
				rNode := valueExpr.LogCurrentNode(depth + 1)
				rootNode.Prefix = prefix
				rootNode.Infix = midfix
				rootNode.LNode = lNode
				rootNode.RNode = rNode
				prefix = ""
			} else {
				midfix += "("
				rNode := expr.LogCurrentNode(depth + 1)
				rootNode.Prefix = prefix
				rootNode.Infix = midfix
				rootNode.Suffix = ")"
				rootNode.LNode = lNode
				rootNode.RNode = rNode
			}
		} else {
			midfix := " DROP DEFAULT"
			rootNode.Prefix = prefix
			rootNode.Infix = midfix
		}
	case AlterTableLock:

		prefix += "LOCK = "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Str:      n.LockType.String(),
			Depth:    depth,
		}

		rootNode.Prefix = prefix
		rootNode.LNode = lNode

	case AlterTableWriteable:
		prefix += "READ "
		if n.Writeable {
			prefix += "WRITE"
		} else {
			prefix += "ONLY"
		}
		rootNode.Prefix = prefix

	case AlterTableOrderByColumns:
		prefix += "ORDER BY "
		for i, alterOrderItem := range n.OrderByList {
			midfix := ""
			if i != 0 {
				midfix = ", "
			}
			alterOrderItemNode := alterOrderItem.LogCurrentNode(depth + 1)
			if i == 0 {
				rootNode.LNode = alterOrderItemNode
			} else { // i > 0
				rootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    rootNode,
					RNode:    alterOrderItemNode,
					Infix:    midfix,
					Depth:    depth,
				}
			}
		}
		rootNode.Prefix = prefix
	case AlterTableAlgorithm:

		prefix += "ALGORITHM = " + n.Algorithm.String()
		rootNode.Prefix = prefix

	case AlterTableRenameIndex:

		prefix += "RENAME INDEX "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataIndexName,
			ContextFlag: sql_ir.ContextUndefine,
			Str:         n.FromKey.O,
			Depth:       depth,
		}
		midfix := " TO "
		rNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataIndexName,
			ContextFlag: sql_ir.ContextDefine,
			Str:         n.ToKey.O,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.Infix = midfix
		rootNode.LNode = lNode
		rootNode.RNode = rNode

	case AlterTableForce:
		prefix += "FORCE"
		rootNode.Prefix = prefix

	case AlterTableAddPartitions:
		prefix += "ADD PARTITION"
		if n.IfNotExists {
			prefix += " IF NOT EXISTS"
		}
		if n.NoWriteToBinlog {
			prefix += " NO_WRITE_TO_BINLOG"
		}
		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		if n.PartDefinitions != nil {
			tmpPrefix := " ("
			for i, def := range n.PartDefinitions {
				tmpMidfix := ""
				if i != 0 {
					tmpMidfix = ", "
				}
				defNode := def.LogCurrentNode(depth + 1)
				if i == 0 {
					tmpRootNode.LNode = defNode
				} else { //i > 0
					tmpRootNode = &sql_ir.SqlRsgIR{
						IRType:   sql_ir.TypeUnknown,
						DataType: sql_ir.DataNone,
						LNode:    tmpRootNode,
						RNode:    defNode,
						Infix:    tmpMidfix,
						Depth:    depth,
					}
				}
			}
			tmpRootNode.Prefix = tmpPrefix
			tmpRootNode.Suffix = ")"
		} else if n.Num != 0 {
			tmpPrefix := " PARTITIONS "
			numNode := &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeIntegerLiteral,
				DataType: sql_ir.DataNone,
				IValue:   int64(n.Num),
				Str:      strconv.FormatInt(int64(n.Num), 10),
				Depth:    depth,
			}
			tmpRootNode.Prefix = tmpPrefix
			tmpRootNode.LNode = numNode
		}

		rootNode.Prefix = prefix
		rootNode.LNode = tmpRootNode

	case AlterTablePartitionOptions:
		prefix += "PARTITION "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataPartitionName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.PartitionNames[0].O,
			Depth:       depth,
		}

		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}

		for i, opt := range n.Options {
			optNode := opt.LogCurrentNode(depth + 1)
			if i == 0 {
				tmpRootNode.LNode = optNode
			} else { // i > 0
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

		rootNode.Prefix = prefix
		rootNode.Infix = " "
		rootNode.LNode = lNode
		rootNode.RNode = tmpRootNode

	case AlterTablePartitionAttributes:
		prefix = "PARTITION "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataPartitionName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.PartitionNames[0].O,
			Depth:       depth,
		}
		midfix := " "

		spec := n.AttributesSpec
		rNode := spec.LogCurrentNode(depth + 1)

		rootNode.Prefix = prefix
		rootNode.Infix = midfix
		rootNode.LNode = lNode
		rootNode.RNode = rNode

	case AlterTableCoalescePartitions:
		prefix += "COALESCE PARTITION "
		if n.NoWriteToBinlog {
			prefix += "NO_WRITE_TO_BINLOG "
		}
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			IValue:   int64(n.Num),
			Str:      strconv.FormatInt(int64(n.Num), 10),
			Depth:    depth,
		}

		rootNode.Prefix = prefix
		rootNode.LNode = lNode

	case AlterTableDropPartition:
		prefix += "DROP PARTITION "
		if n.IfExists {
			prefix += "IF EXISTS "
		}
		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for i, name := range n.PartitionNames {
			midfix := ""
			if i != 0 {
				midfix = ", "
			}
			nameNode := &sql_ir.SqlRsgIR{
				IRType:      sql_ir.TypeIdentifier,
				DataType:    sql_ir.DataPartitionName,
				ContextFlag: sql_ir.ContextUndefine,
				Str:         name.O,
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
					Infix:    midfix,
					Depth:    depth,
				}
			}
		}

		rootNode.Prefix = prefix
		rootNode.LNode = tmpRootNode

	case AlterTableTruncatePartition:
		prefix += "TRUNCATE PARTITION "
		if n.OnAllPartitions {
			prefix += "ALL "
			rootNode.Prefix = prefix
			break
		}
		for i, name := range n.PartitionNames {
			tmpMidfix := ""
			if i != 0 {
				tmpMidfix = ","
			}
			nameNode := &sql_ir.SqlRsgIR{
				IRType:      sql_ir.TypeIdentifier,
				DataType:    sql_ir.DataPartitionName,
				ContextFlag: sql_ir.ContextUse,
				Str:         name.O,
				Depth:       depth,
			}
			if i == 0 {
				rootNode.LNode = nameNode
			} else { // i > 0
				rootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    rootNode,
					RNode:    nameNode,
					Infix:    tmpMidfix,
					Depth:    depth,
				}
			}
		}

		rootNode.Prefix = prefix

	case AlterTableCheckPartitions:
		prefix += "CHECK PARTITION "
		if n.OnAllPartitions {
			prefix += "ALL "
			rootNode.Prefix = prefix
			break
		}
		for i, name := range n.PartitionNames {
			tmpMidfix := ""
			if i != 0 {
				tmpMidfix = ","
			}
			nameNode := &sql_ir.SqlRsgIR{
				IRType:      sql_ir.TypeIdentifier,
				DataType:    sql_ir.DataPartitionName,
				ContextFlag: sql_ir.ContextUse,
				Str:         name.O,
				Depth:       depth,
			}
			if i == 0 {
				rootNode.LNode = nameNode
			} else { // i > 0
				rootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    rootNode,
					RNode:    nameNode,
					Infix:    tmpMidfix,
					Depth:    depth,
				}
			}
		}

		rootNode.Prefix = prefix
	case AlterTableOptimizePartition:
		prefix += "OPTIMIZE PARTITION "
		if n.NoWriteToBinlog {
			prefix += "NO_WRITE_TO_BINLOG "
		}
		if n.OnAllPartitions {
			prefix += "ALL"
			rootNode.Prefix = prefix
			break
		}
		for i, name := range n.PartitionNames {
			tmpMidfix := ""
			if i != 0 {
				tmpMidfix = ","
			}
			nameNode := &sql_ir.SqlRsgIR{
				IRType:      sql_ir.TypeIdentifier,
				DataType:    sql_ir.DataPartitionName,
				ContextFlag: sql_ir.ContextUse,
				Str:         name.O,
				Depth:       depth,
			}
			if i == 0 {
				rootNode.LNode = nameNode
			} else { // i > 0
				rootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    rootNode,
					RNode:    nameNode,
					Infix:    tmpMidfix,
					Depth:    depth,
				}
			}
		}

		rootNode.Prefix = prefix
	case AlterTableRepairPartition:
		prefix += "REPAIR PARTITION "
		if n.NoWriteToBinlog {
			prefix += "NO_WRITE_TO_BINLOG "
		}
		if n.OnAllPartitions {
			prefix += "ALL"
			rootNode.Prefix = prefix
			break
		}
		for i, name := range n.PartitionNames {
			tmpMidfix := ""
			if i != 0 {
				tmpMidfix = ","
			}
			nameNode := &sql_ir.SqlRsgIR{
				IRType:      sql_ir.TypeIdentifier,
				DataType:    sql_ir.DataPartitionName,
				ContextFlag: sql_ir.ContextUse,
				Str:         name.O,
				Depth:       depth,
			}
			if i == 0 {
				rootNode.LNode = nameNode
			} else { // i > 0
				rootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    rootNode,
					RNode:    nameNode,
					Infix:    tmpMidfix,
					Depth:    depth,
				}
			}
		}

		rootNode.Prefix = prefix
	case AlterTableImportPartitionTablespace:
		prefix += "IMPORT PARTITION "
		if n.OnAllPartitions {
			prefix += "ALL"
		} else {
			for i, name := range n.PartitionNames {
				tmpMidfix := ""
				if i != 0 {
					tmpMidfix = ","
				}
				nameNode := &sql_ir.SqlRsgIR{
					IRType:      sql_ir.TypeIdentifier,
					DataType:    sql_ir.DataPartitionName,
					ContextFlag: sql_ir.ContextUse,
					Str:         name.O,
					Depth:       depth,
				}
				if i == 0 {
					rootNode.LNode = nameNode
				} else { // i > 0
					rootNode = &sql_ir.SqlRsgIR{
						IRType:   sql_ir.TypeUnknown,
						DataType: sql_ir.DataNone,
						LNode:    rootNode,
						RNode:    nameNode,
						Infix:    tmpMidfix,
						Depth:    depth,
					}
				}
			}
		}
		rootNode.Prefix = prefix
		rootNode.Suffix = " TABLESPACE"
	case AlterTableDiscardPartitionTablespace:
		prefix += "DISCARD PARTITION "
		if n.OnAllPartitions {
			prefix += "ALL"
		} else {
			for i, name := range n.PartitionNames {
				tmpMidfix := ""
				if i != 0 {
					tmpMidfix = ","
				}
				nameNode := &sql_ir.SqlRsgIR{
					IRType:      sql_ir.TypeIdentifier,
					DataType:    sql_ir.DataPartitionName,
					ContextFlag: sql_ir.ContextUndefine,
					Str:         name.O,
					Depth:       depth,
				}
				if i == 0 {
					rootNode.LNode = nameNode
				} else { // i > 0
					rootNode = &sql_ir.SqlRsgIR{
						IRType:   sql_ir.TypeUnknown,
						DataType: sql_ir.DataNone,
						LNode:    rootNode,
						RNode:    nameNode,
						Infix:    tmpMidfix,
						Depth:    depth,
					}
				}
			}
		}
		rootNode.Prefix = prefix
		rootNode.Suffix = " TABLESPACE"
	case AlterTablePartition:
		lNode := n.Position.LogCurrentNode(depth + 1)
		rootNode.LNode = lNode
	case AlterTableEnableKeys:
		prefix = "ENABLE KEYS"
		rootNode.Prefix = prefix
	case AlterTableDisableKeys:
		prefix = "DISABLE KEYS"
		rootNode.Prefix = prefix
	case AlterTableRemovePartitioning:
		prefix = "REMOVE PARTITIONING"
		rootNode.Prefix = prefix
	case AlterTableWithValidation:
		prefix = "WITH VALIDATION"
		rootNode.Prefix = prefix
	case AlterTableWithoutValidation:
		prefix = "WITHOUT VALIDATION"
		rootNode.Prefix = prefix
	case AlterTableRebuildPartition:
		prefix = "REBUILD PARTITION "
		if n.NoWriteToBinlog {
			prefix += "NO_WRITE_TO_BINLOG "
		}
		if n.OnAllPartitions {
			prefix += "ALL"
			rootNode.Prefix = prefix
			break
		}
		for i, name := range n.PartitionNames {
			tmpMidfix := ""
			if i != 0 {
				tmpMidfix = ","
			}
			nameNode := &sql_ir.SqlRsgIR{
				IRType:      sql_ir.TypeIdentifier,
				DataType:    sql_ir.DataPartitionName,
				ContextFlag: sql_ir.ContextUse,
				Str:         name.O,
				Depth:       depth,
			}
			if i == 0 {
				rootNode.LNode = nameNode
			} else { // i > 0
				rootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    rootNode,
					RNode:    nameNode,
					Infix:    tmpMidfix,
					Depth:    depth,
				}
			}
		}
		rootNode.Prefix = prefix
	case AlterTableReorganizePartition:
		prefix += "REORGANIZE PARTITION"
		if n.NoWriteToBinlog {
			prefix += " NO_WRITE_TO_BINLOG"
		}
		if n.OnAllPartitions {
			rootNode.Prefix = prefix
			break
		}
		tmpRootNodeFirst := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for i, name := range n.PartitionNames {
			nameNode := &sql_ir.SqlRsgIR{
				IRType:      sql_ir.TypeIdentifier,
				DataType:    sql_ir.DataPartitionName,
				ContextFlag: sql_ir.ContextUse,
				Str:         name.O,
				Depth:       depth,
			}
			if i == 0 {
				tmpRootNodeFirst.LNode = nameNode
			} else {
				tmpRootNodeFirst.LNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNodeFirst,
					RNode:    nameNode,
					Infix:    ", ",
					Depth:    depth,
				}
			}
		}
		midfix := " INTO "

		var rNode *sql_ir.SqlRsgIR = nil
		if n.PartDefinitions != nil {
			for i, def := range n.PartDefinitions {
				defNode := def.LogCurrentNode(depth + 1)
				if i == 0 {
					rNode.LNode = defNode
				} else { // i > 0
					rNode = &sql_ir.SqlRsgIR{
						IRType:   sql_ir.TypeUnknown,
						DataType: sql_ir.DataNone,
						LNode:    rNode,
						RNode:    defNode,
						Infix:    ", ",
						Depth:    depth,
					}
				}
			}
			tmpPrefix := "("
			tmpSuffix := ")"
			rNode.Prefix = tmpPrefix
			rNode.Suffix = tmpSuffix
		}
		rootNode.LNode = tmpRootNodeFirst
		rootNode.RNode = rNode
		rootNode.Prefix = prefix
		rootNode.Infix = midfix

	case AlterTableExchangePartition:
		prefix += "EXCHANGE PARTITION "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataPartitionName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.PartitionNames[0].O,
			Depth:       depth,
		}

		midfix := " WITH TABLE "

		rNode := n.NewTable.LogCurrentNode(depth + 1)
		newTableNameList := sql_ir.GetSubNodeFromParentNodeWithDataType(rNode, sql_ir.DataTableName)
		for _, newTableName := range newTableNameList {
			newTableName.DataType = sql_ir.DataTableName
			newTableName.ContextFlag = sql_ir.ContextUse
		}
		suffix := ""
		if !n.WithValidation {
			suffix += " WITHOUT VALIDATION"
		}

		rootNode.Prefix = prefix
		rootNode.Infix = midfix
		rootNode.Suffix = suffix
		rootNode.LNode = lNode
		rootNode.RNode = rNode

	case AlterTableSecondaryLoad:
		prefix += "SECONDARY_LOAD"
		rootNode.Prefix = prefix
	case AlterTableSecondaryUnload:
		prefix += "SECONDARY_UNLOAD"
		rootNode.Prefix = prefix
	case AlterTableAlterCheck:

		prefix += "ALTER CHECK "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataConstraintName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.Constraint.Name,
			Depth:       depth,
		}
		midfix := ""
		if !n.Constraint.Enforced {
			midfix += " NOT"
		}
		midfix += " ENFORCED"

		rootNode.Prefix = prefix
		rootNode.Infix = midfix
		rootNode.LNode = lNode

	case AlterTableDropCheck:
		prefix += "DROP CHECK "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataConstraintName,
			ContextFlag: sql_ir.ContextUndefine,
			Str:         n.Constraint.Name,
			Depth:       depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
	case AlterTableImportTablespace:
		prefix += "IMPORT TABLESPACE"
		rootNode.Prefix = prefix
	case AlterTableDiscardTablespace:
		prefix += "DISCARD TABLESPACE"
		rootNode.Prefix = prefix
	case AlterTableIndexInvisible:
		prefix += "ALTER INDEX "
		lNode := &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataIndexName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.IndexName.O,
			Depth:       depth,
		}
		midfix := ""
		switch n.Visibility {
		case IndexVisibilityVisible:
			midfix += " VISIBLE"
		case IndexVisibilityInvisible:
			midfix += " INVISIBLE"
		}

		rootNode.Prefix = prefix
		rootNode.Infix = midfix
		rootNode.LNode = lNode

	case AlterTableAttributes:
		spec := n.AttributesSpec
		lNode := spec.LogCurrentNode(depth + 1)
		rootNode.LNode = lNode
	case AlterTableCache:
		prefix += "CACHE"
		rootNode.Prefix = prefix
	case AlterTableNoCache:
		prefix += "NOCACHE"
		rootNode.Prefix = prefix
	case AlterTableStatsOptions:
		spec := n.StatsOptionsSpec
		lNode := spec.LogCurrentNode(depth + 1)
		rootNode.LNode = lNode

	default:
		// Do nothing.
	}
	rootNode.IRType = sql_ir.TypeAlterTableSpec

	return rootNode
}

// Restore implements Node interface.
func (n *AlterTableSpec) Restore(ctx *format.RestoreCtx) error {
	if n.IsAllPlacementRule() && ctx.Flags.HasSkipPlacementRuleForRestoreFlag() {
		return nil
	}
	switch n.Tp {
	case AlterTableSetTiFlashReplica:
		ctx.WriteKeyWord("SET TIFLASH REPLICA ")
		ctx.WritePlainf("%d", n.TiFlashReplica.Count)
		if len(n.TiFlashReplica.Labels) == 0 {
			break
		}
		ctx.WriteKeyWord(" LOCATION LABELS ")
		for i, v := range n.TiFlashReplica.Labels {
			if i > 0 {
				ctx.WritePlain(", ")
			}
			ctx.WriteString(v)
		}
	case AlterTableAddStatistics:
		ctx.WriteKeyWord("ADD STATS_EXTENDED ")
		if n.IfNotExists {
			ctx.WriteKeyWord("IF NOT EXISTS ")
		}
		ctx.WriteName(n.Statistics.StatsName)
		switch n.Statistics.StatsType {
		case StatsTypeCardinality:
			ctx.WriteKeyWord(" CARDINALITY(")
		case StatsTypeDependency:
			ctx.WriteKeyWord(" DEPENDENCY(")
		case StatsTypeCorrelation:
			ctx.WriteKeyWord(" CORRELATION(")
		}
		for i, col := range n.Statistics.Columns {
			if i != 0 {
				ctx.WritePlain(", ")
			}
			if err := col.Restore(ctx); err != nil {
				return errors.Annotatef(err, "An error occurred while restore AddStatisticsSpec.Columns: [%v]", i)
			}
		}
		ctx.WritePlain(")")
	case AlterTableDropStatistics:
		ctx.WriteKeyWord("DROP STATS_EXTENDED ")
		if n.IfExists {
			ctx.WriteKeyWord("IF EXISTS ")
		}
		ctx.WriteName(n.Statistics.StatsName)
	case AlterTableOption:
		switch {
		case len(n.Options) == 2 && n.Options[0].Tp == TableOptionCharset && n.Options[1].Tp == TableOptionCollate:
			if n.Options[0].UintValue == TableOptionCharsetWithConvertTo {
				ctx.WriteKeyWord("CONVERT TO ")
			}
			ctx.WriteKeyWord("CHARACTER SET ")
			if n.Options[0].Default {
				ctx.WriteKeyWord("DEFAULT")
			} else {
				ctx.WriteKeyWord(n.Options[0].StrValue)
			}
			ctx.WriteKeyWord(" COLLATE ")
			ctx.WriteKeyWord(n.Options[1].StrValue)
		case n.Options[0].Tp == TableOptionCharset && n.Options[0].Default:
			if n.Options[0].UintValue == TableOptionCharsetWithConvertTo {
				ctx.WriteKeyWord("CONVERT TO ")
			}
			ctx.WriteKeyWord("CHARACTER SET DEFAULT")
		default:
			for i, opt := range n.Options {
				if i != 0 {
					ctx.WritePlain(" ")
				}
				if err := opt.Restore(ctx); err != nil {
					return errors.Annotatef(err, "An error occurred while restore AlterTableSpec.Options[%d]", i)
				}
			}
		}
	case AlterTableAddColumns:
		ctx.WriteKeyWord("ADD COLUMN ")
		if n.IfNotExists {
			ctx.WriteKeyWord("IF NOT EXISTS ")
		}
		if n.Position != nil && len(n.NewColumns) == 1 {
			if err := n.NewColumns[0].Restore(ctx); err != nil {
				return errors.Annotatef(err, "An error occurred while restore AlterTableSpec.NewColumns[%d]", 0)
			}
			if n.Position.Tp != ColumnPositionNone {
				ctx.WritePlain(" ")
			}
			if err := n.Position.Restore(ctx); err != nil {
				return errors.Annotate(err, "An error occurred while restore AlterTableSpec.Position")
			}
		} else {
			lenCols := len(n.NewColumns)
			ctx.WritePlain("(")
			for i, col := range n.NewColumns {
				if i != 0 {
					ctx.WritePlain(", ")
				}
				if err := col.Restore(ctx); err != nil {
					return errors.Annotatef(err, "An error occurred while restore AlterTableSpec.NewColumns[%d]", i)
				}
			}
			for i, constraint := range n.NewConstraints {
				if i != 0 || lenCols >= 1 {
					ctx.WritePlain(", ")
				}
				if err := constraint.Restore(ctx); err != nil {
					return errors.Annotatef(err, "An error occurred while restore AlterTableSpec.NewConstraints[%d]", i)
				}
			}
			ctx.WritePlain(")")
		}
	case AlterTableAddConstraint:
		ctx.WriteKeyWord("ADD ")
		if err := n.Constraint.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore AlterTableSpec.Constraint")
		}
	case AlterTableDropColumn:
		ctx.WriteKeyWord("DROP COLUMN ")
		if n.IfExists {
			ctx.WriteKeyWord("IF EXISTS ")
		}
		if err := n.OldColumnName.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore AlterTableSpec.OldColumnName")
		}
	// TODO: RestrictOrCascadeOpt not support
	case AlterTableDropPrimaryKey:
		ctx.WriteKeyWord("DROP PRIMARY KEY")
	case AlterTableDropIndex:
		ctx.WriteKeyWord("DROP INDEX ")
		if n.IfExists {
			ctx.WriteKeyWord("IF EXISTS ")
		}
		ctx.WriteName(n.Name)
	case AlterTableDropForeignKey:
		ctx.WriteKeyWord("DROP FOREIGN KEY ")
		if n.IfExists {
			ctx.WriteKeyWord("IF EXISTS ")
		}
		ctx.WriteName(n.Name)
	case AlterTableModifyColumn:
		ctx.WriteKeyWord("MODIFY COLUMN ")
		if n.IfExists {
			ctx.WriteKeyWord("IF EXISTS ")
		}
		if err := n.NewColumns[0].Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore AlterTableSpec.NewColumns[0]")
		}
		if n.Position.Tp != ColumnPositionNone {
			ctx.WritePlain(" ")
		}
		if err := n.Position.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore AlterTableSpec.Position")
		}
	case AlterTableChangeColumn:
		ctx.WriteKeyWord("CHANGE COLUMN ")
		if n.IfExists {
			ctx.WriteKeyWord("IF EXISTS ")
		}
		if err := n.OldColumnName.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore AlterTableSpec.OldColumnName")
		}
		ctx.WritePlain(" ")
		if err := n.NewColumns[0].Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore AlterTableSpec.NewColumns[0]")
		}
		if n.Position.Tp != ColumnPositionNone {
			ctx.WritePlain(" ")
		}
		if err := n.Position.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore AlterTableSpec.Position")
		}
	case AlterTableRenameColumn:
		ctx.WriteKeyWord("RENAME COLUMN ")
		if err := n.OldColumnName.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore AlterTableSpec.OldColumnName")
		}
		ctx.WriteKeyWord(" TO ")
		if err := n.NewColumnName.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore AlterTableSpec.NewColumnName")
		}
	case AlterTableRenameTable:
		ctx.WriteKeyWord("RENAME AS ")
		if err := n.NewTable.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore AlterTableSpec.NewTable")
		}
	case AlterTableAlterColumn:
		ctx.WriteKeyWord("ALTER COLUMN ")
		if err := n.NewColumns[0].Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore AlterTableSpec.NewColumns[0]")
		}
		if len(n.NewColumns[0].Options) == 1 {
			ctx.WriteKeyWord("SET DEFAULT ")
			expr := n.NewColumns[0].Options[0].Expr
			if valueExpr, ok := expr.(ValueExpr); ok {
				if err := valueExpr.Restore(ctx); err != nil {
					return errors.Annotate(err, "An error occurred while restore AlterTableSpec.NewColumns[0].Options[0].Expr")
				}
			} else {
				ctx.WritePlain("(")
				if err := expr.Restore(ctx); err != nil {
					return errors.Annotate(err, "An error occurred while restore AlterTableSpec.NewColumns[0].Options[0].Expr")
				}
				ctx.WritePlain(")")
			}
		} else {
			ctx.WriteKeyWord(" DROP DEFAULT")
		}
	case AlterTableLock:
		ctx.WriteKeyWord("LOCK ")
		ctx.WritePlain("= ")
		ctx.WriteKeyWord(n.LockType.String())
	case AlterTableWriteable:
		ctx.WriteKeyWord("READ ")
		if n.Writeable {
			ctx.WriteKeyWord("WRITE")
		} else {
			ctx.WriteKeyWord("ONLY")
		}
	case AlterTableOrderByColumns:
		ctx.WriteKeyWord("ORDER BY ")
		for i, alterOrderItem := range n.OrderByList {
			if i != 0 {
				ctx.WritePlain(",")
			}
			if err := alterOrderItem.Restore(ctx); err != nil {
				return errors.Annotatef(err, "An error occurred while restore AlterTableSpec.OrderByList[%d]", i)
			}
		}
	case AlterTableAlgorithm:
		ctx.WriteKeyWord("ALGORITHM ")
		ctx.WritePlain("= ")
		ctx.WriteKeyWord(n.Algorithm.String())
	case AlterTableRenameIndex:
		ctx.WriteKeyWord("RENAME INDEX ")
		ctx.WriteName(n.FromKey.O)
		ctx.WriteKeyWord(" TO ")
		ctx.WriteName(n.ToKey.O)
	case AlterTableForce:
		// TODO: not support
		ctx.WriteKeyWord("FORCE")
		ctx.WritePlain(" /* AlterTableForce is not supported */ ")
	case AlterTableAddPartitions:
		ctx.WriteKeyWord("ADD PARTITION")
		if n.IfNotExists {
			ctx.WriteKeyWord(" IF NOT EXISTS")
		}
		if n.NoWriteToBinlog {
			ctx.WriteKeyWord(" NO_WRITE_TO_BINLOG")
		}
		if n.PartDefinitions != nil {
			ctx.WritePlain(" (")
			for i, def := range n.PartDefinitions {
				if i != 0 {
					ctx.WritePlain(", ")
				}
				if err := def.Restore(ctx); err != nil {
					return errors.Annotatef(err, "An error occurred while restore AlterTableSpec.PartDefinitions[%d]", i)
				}
			}
			ctx.WritePlain(")")
		} else if n.Num != 0 {
			ctx.WriteKeyWord(" PARTITIONS ")
			ctx.WritePlainf("%d", n.Num)
		}
	case AlterTablePartitionOptions:
		restoreWithoutSpecialComment := func() error {
			origFlags := ctx.Flags
			defer func() {
				ctx.Flags = origFlags
			}()
			ctx.Flags &= ^format.RestoreTiDBSpecialComment
			ctx.WriteKeyWord("PARTITION ")
			ctx.WriteName(n.PartitionNames[0].O)
			ctx.WritePlain(" ")

			for i, opt := range n.Options {
				if i != 0 {
					ctx.WritePlain(" ")
				}
				if err := opt.Restore(ctx); err != nil {
					return errors.Annotatef(err, "An error occurred while restore AlterTableSpec.Options[%d] for PARTITION `%s`", i, n.PartitionNames[0].O)
				}
			}
			return nil
		}

		var err error
		if ctx.Flags.HasTiDBSpecialCommentFlag() {
			// AlterTablePartitionOptions now only supports placement options, so add put all options to special comment
			err = ctx.WriteWithSpecialComments(tidb.FeatureIDPlacement, restoreWithoutSpecialComment)
		} else {
			err = restoreWithoutSpecialComment()
		}

		if err != nil {
			return err
		}
	case AlterTablePartitionAttributes:
		ctx.WriteKeyWord("PARTITION ")
		ctx.WriteName(n.PartitionNames[0].O)
		ctx.WritePlain(" ")

		spec := n.AttributesSpec
		if err := spec.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore AlterTableSpec.AttributesSpec")
		}
	case AlterTableCoalescePartitions:
		ctx.WriteKeyWord("COALESCE PARTITION ")
		if n.NoWriteToBinlog {
			ctx.WriteKeyWord("NO_WRITE_TO_BINLOG ")
		}
		ctx.WritePlainf("%d", n.Num)
	case AlterTableDropPartition:
		ctx.WriteKeyWord("DROP PARTITION ")
		if n.IfExists {
			ctx.WriteKeyWord("IF EXISTS ")
		}
		for i, name := range n.PartitionNames {
			if i != 0 {
				ctx.WritePlain(",")
			}
			ctx.WriteName(name.O)
		}
	case AlterTableTruncatePartition:
		ctx.WriteKeyWord("TRUNCATE PARTITION ")
		if n.OnAllPartitions {
			ctx.WriteKeyWord("ALL")
			return nil
		}
		for i, name := range n.PartitionNames {
			if i != 0 {
				ctx.WritePlain(",")
			}
			ctx.WriteName(name.O)
		}
	case AlterTableCheckPartitions:
		ctx.WriteKeyWord("CHECK PARTITION ")
		if n.OnAllPartitions {
			ctx.WriteKeyWord("ALL")
			return nil
		}
		for i, name := range n.PartitionNames {
			if i != 0 {
				ctx.WritePlain(",")
			}
			ctx.WriteName(name.O)
		}
	case AlterTableOptimizePartition:
		ctx.WriteKeyWord("OPTIMIZE PARTITION ")
		if n.NoWriteToBinlog {
			ctx.WriteKeyWord("NO_WRITE_TO_BINLOG ")
		}
		if n.OnAllPartitions {
			ctx.WriteKeyWord("ALL")
			return nil
		}
		for i, name := range n.PartitionNames {
			if i != 0 {
				ctx.WritePlain(",")
			}
			ctx.WriteName(name.O)
		}
	case AlterTableRepairPartition:
		ctx.WriteKeyWord("REPAIR PARTITION ")
		if n.NoWriteToBinlog {
			ctx.WriteKeyWord("NO_WRITE_TO_BINLOG ")
		}
		if n.OnAllPartitions {
			ctx.WriteKeyWord("ALL")
			return nil
		}
		for i, name := range n.PartitionNames {
			if i != 0 {
				ctx.WritePlain(",")
			}
			ctx.WriteName(name.O)
		}
	case AlterTableImportPartitionTablespace:
		ctx.WriteKeyWord("IMPORT PARTITION ")
		if n.OnAllPartitions {
			ctx.WriteKeyWord("ALL")
		} else {
			for i, name := range n.PartitionNames {
				if i != 0 {
					ctx.WritePlain(",")
				}
				ctx.WriteName(name.O)
			}
		}
		ctx.WriteKeyWord(" TABLESPACE")
	case AlterTableDiscardPartitionTablespace:
		ctx.WriteKeyWord("DISCARD PARTITION ")
		if n.OnAllPartitions {
			ctx.WriteKeyWord("ALL")
		} else {
			for i, name := range n.PartitionNames {
				if i != 0 {
					ctx.WritePlain(",")
				}
				ctx.WriteName(name.O)
			}
		}
		ctx.WriteKeyWord(" TABLESPACE")
	case AlterTablePartition:
		if err := n.Partition.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore AlterTableSpec.Partition")
		}
	case AlterTableEnableKeys:
		ctx.WriteKeyWord("ENABLE KEYS")
	case AlterTableDisableKeys:
		ctx.WriteKeyWord("DISABLE KEYS")
	case AlterTableRemovePartitioning:
		ctx.WriteKeyWord("REMOVE PARTITIONING")
	case AlterTableWithValidation:
		ctx.WriteKeyWord("WITH VALIDATION")
	case AlterTableWithoutValidation:
		ctx.WriteKeyWord("WITHOUT VALIDATION")
	case AlterTableRebuildPartition:
		ctx.WriteKeyWord("REBUILD PARTITION ")
		if n.NoWriteToBinlog {
			ctx.WriteKeyWord("NO_WRITE_TO_BINLOG ")
		}
		if n.OnAllPartitions {
			ctx.WriteKeyWord("ALL")
			return nil
		}
		for i, name := range n.PartitionNames {
			if i != 0 {
				ctx.WritePlain(",")
			}
			ctx.WriteName(name.O)
		}
	case AlterTableReorganizePartition:
		ctx.WriteKeyWord("REORGANIZE PARTITION")
		if n.NoWriteToBinlog {
			ctx.WriteKeyWord(" NO_WRITE_TO_BINLOG")
		}
		if n.OnAllPartitions {
			return nil
		}
		for i, name := range n.PartitionNames {
			if i != 0 {
				ctx.WritePlain(",")
			} else {
				ctx.WritePlain(" ")
			}
			ctx.WriteName(name.O)
		}
		ctx.WriteKeyWord(" INTO ")
		if n.PartDefinitions != nil {
			ctx.WritePlain("(")
			for i, def := range n.PartDefinitions {
				if i != 0 {
					ctx.WritePlain(", ")
				}
				if err := def.Restore(ctx); err != nil {
					return errors.Annotatef(err, "An error occurred while restore AlterTableSpec.PartDefinitions[%d]", i)
				}
			}
			ctx.WritePlain(")")
		}
	case AlterTableExchangePartition:
		ctx.WriteKeyWord("EXCHANGE PARTITION ")
		ctx.WriteName(n.PartitionNames[0].O)
		ctx.WriteKeyWord(" WITH TABLE ")
		n.NewTable.Restore(ctx)
		if !n.WithValidation {
			ctx.WriteKeyWord(" WITHOUT VALIDATION")
		}
	case AlterTableSecondaryLoad:
		ctx.WriteKeyWord("SECONDARY_LOAD")
	case AlterTableSecondaryUnload:
		ctx.WriteKeyWord("SECONDARY_UNLOAD")
	case AlterTableAlterCheck:
		ctx.WriteKeyWord("ALTER CHECK ")
		ctx.WriteName(n.Constraint.Name)
		if !n.Constraint.Enforced {
			ctx.WriteKeyWord(" NOT")
		}
		ctx.WriteKeyWord(" ENFORCED")
	case AlterTableDropCheck:
		ctx.WriteKeyWord("DROP CHECK ")
		ctx.WriteName(n.Constraint.Name)
	case AlterTableImportTablespace:
		ctx.WriteKeyWord("IMPORT TABLESPACE")
	case AlterTableDiscardTablespace:
		ctx.WriteKeyWord("DISCARD TABLESPACE")
	case AlterTableIndexInvisible:
		ctx.WriteKeyWord("ALTER INDEX ")
		ctx.WriteName(n.IndexName.O)
		switch n.Visibility {
		case IndexVisibilityVisible:
			ctx.WriteKeyWord(" VISIBLE")
		case IndexVisibilityInvisible:
			ctx.WriteKeyWord(" INVISIBLE")
		}
	case AlterTableAttributes:
		spec := n.AttributesSpec
		if err := spec.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore AlterTableSpec.AttributesSpec")
		}
	case AlterTableCache:
		ctx.WriteKeyWord("CACHE")
	case AlterTableNoCache:
		ctx.WriteKeyWord("NOCACHE")
	case AlterTableStatsOptions:
		spec := n.StatsOptionsSpec
		if err := spec.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore AlterTableSpec.StatsOptionsSpec")
		}

	default:
		// TODO: not support
		ctx.WritePlainf(" /* AlterTableType(%d) is not supported */ ", n.Tp)
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *AlterTableSpec) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*AlterTableSpec)
	if n.Constraint != nil {
		node, ok := n.Constraint.Accept(v)
		if !ok {
			return n, false
		}
		n.Constraint = node.(*Constraint)
	}
	if n.NewTable != nil {
		node, ok := n.NewTable.Accept(v)
		if !ok {
			return n, false
		}
		n.NewTable = node.(*TableName)
	}
	for i, col := range n.NewColumns {
		node, ok := col.Accept(v)
		if !ok {
			return n, false
		}
		n.NewColumns[i] = node.(*ColumnDef)
	}
	for i, constraint := range n.NewConstraints {
		node, ok := constraint.Accept(v)
		if !ok {
			return n, false
		}
		n.NewConstraints[i] = node.(*Constraint)
	}
	if n.OldColumnName != nil {
		node, ok := n.OldColumnName.Accept(v)
		if !ok {
			return n, false
		}
		n.OldColumnName = node.(*ColumnName)
	}
	if n.Position != nil {
		node, ok := n.Position.Accept(v)
		if !ok {
			return n, false
		}
		n.Position = node.(*ColumnPosition)
	}
	if n.Partition != nil {
		node, ok := n.Partition.Accept(v)
		if !ok {
			return n, false
		}
		n.Partition = node.(*PartitionOptions)
	}
	for _, def := range n.PartDefinitions {
		if !def.acceptInPlace(v) {
			return n, false
		}
	}
	return v.Leave(n)
}

// AlterTableStmt is a statement to change the structure of a table.
// See https://dev.mysql.com/doc/refman/5.7/en/alter-table.html
type AlterTableStmt struct {
	ddlNode

	Table *TableName
	Specs []*AlterTableSpec
}

func (n *AlterTableStmt) HaveOnlyPlacementOptions() bool {
	for _, n := range n.Specs {
		if n.Tp == AlterTablePartitionOptions {
			if !n.IsAllPlacementRule() {
				return false
			}
		} else {
			return false
		}

	}
	return true
}

func (n *AlterTableStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "ALTER TABLE "
	lNode := n.Table.LogCurrentNode(depth + 1)
	tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(lNode, sql_ir.DataTableName)
	for _, tableNameNode := range tableNameNodeList {
		tableNameNode.ContextFlag = sql_ir.ContextUse
	}

	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	var specs []*AlterTableSpec
	for _, spec := range n.Specs {
		if !(spec.IsAllPlacementRule()) {
			specs = append(specs, spec)
		}
	}
	for i, spec := range specs {
		midfix := " "
		if i == 0 || spec.Tp == AlterTablePartition || spec.Tp == AlterTableRemovePartitioning || spec.Tp == AlterTableImportTablespace || spec.Tp == AlterTableDiscardTablespace {
			midfix = " "
		} else {
			midfix = ", "
		}
		specNode := spec.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = specNode
			tmpRootNode.Infix = midfix
		} else {
			tmpRootNode.LNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    specNode,
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
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeAlterTableStmt

	return nil

}

// Restore implements Node interface.
func (n *AlterTableStmt) Restore(ctx *format.RestoreCtx) error {
	if ctx.Flags.HasSkipPlacementRuleForRestoreFlag() && n.HaveOnlyPlacementOptions() {
		return nil
	}
	ctx.WriteKeyWord("ALTER TABLE ")
	if err := n.Table.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore AlterTableStmt.Table")
	}
	var specs []*AlterTableSpec
	for _, spec := range n.Specs {
		if !(spec.IsAllPlacementRule() && ctx.Flags.HasSkipPlacementRuleForRestoreFlag()) {
			specs = append(specs, spec)
		}
	}
	for i, spec := range specs {
		if i == 0 || spec.Tp == AlterTablePartition || spec.Tp == AlterTableRemovePartitioning || spec.Tp == AlterTableImportTablespace || spec.Tp == AlterTableDiscardTablespace {
			ctx.WritePlain(" ")
		} else {
			ctx.WritePlain(", ")
		}
		if err := spec.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore AlterTableStmt.Specs[%d]", i)
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *AlterTableStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*AlterTableStmt)
	node, ok := n.Table.Accept(v)
	if !ok {
		return n, false
	}
	n.Table = node.(*TableName)
	for i, val := range n.Specs {
		node, ok = val.Accept(v)
		if !ok {
			return n, false
		}
		n.Specs[i] = node.(*AlterTableSpec)
	}
	return v.Leave(n)
}

// TruncateTableStmt is a statement to empty a table completely.
// See https://dev.mysql.com/doc/refman/5.7/en/truncate-table.html
type TruncateTableStmt struct {
	ddlNode

	Table *TableName
}

func (n *TruncateTableStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := "TRUNCATE TABLE "
	lNode := n.Table.LogCurrentNode(depth + 1)
	tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(lNode, sql_ir.DataTableName)
	for _, tableNameNode := range tableNameNodeList {
		tableNameNode.DataType = sql_ir.DataTableName
		tableNameNode.ContextFlag = sql_ir.ContextUse
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeTruncateTableStmt
	return rootNode
}

// Restore implements Node interface.
func (n *TruncateTableStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("TRUNCATE TABLE ")
	if err := n.Table.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore TruncateTableStmt.Table")
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *TruncateTableStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*TruncateTableStmt)
	node, ok := n.Table.Accept(v)
	if !ok {
		return n, false
	}
	n.Table = node.(*TableName)
	return v.Leave(n)
}

var (
	ErrNoParts                              = terror.ClassDDL.NewStd(mysql.ErrNoParts)
	ErrPartitionColumnList                  = terror.ClassDDL.NewStd(mysql.ErrPartitionColumnList)
	ErrPartitionRequiresValues              = terror.ClassDDL.NewStd(mysql.ErrPartitionRequiresValues)
	ErrPartitionsMustBeDefined              = terror.ClassDDL.NewStd(mysql.ErrPartitionsMustBeDefined)
	ErrPartitionWrongNoPart                 = terror.ClassDDL.NewStd(mysql.ErrPartitionWrongNoPart)
	ErrPartitionWrongNoSubpart              = terror.ClassDDL.NewStd(mysql.ErrPartitionWrongNoSubpart)
	ErrPartitionWrongValues                 = terror.ClassDDL.NewStd(mysql.ErrPartitionWrongValues)
	ErrRowSinglePartitionField              = terror.ClassDDL.NewStd(mysql.ErrRowSinglePartitionField)
	ErrSubpartition                         = terror.ClassDDL.NewStd(mysql.ErrSubpartition)
	ErrSystemVersioningWrongPartitions      = terror.ClassDDL.NewStd(mysql.ErrSystemVersioningWrongPartitions)
	ErrTooManyValues                        = terror.ClassDDL.NewStd(mysql.ErrTooManyValues)
	ErrWrongPartitionTypeExpectedSystemTime = terror.ClassDDL.NewStd(mysql.ErrWrongPartitionTypeExpectedSystemTime)
	ErrUnknownCharacterSet                  = terror.ClassDDL.NewStd(mysql.ErrUnknownCharacterSet)
)

type SubPartitionDefinition struct {
	Name    model.CIStr
	Options []*TableOption

	sql_ir.SqlRsgInterface
}

func (n *SubPartitionDefinition) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := "SUBPARTITION "
	lNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataPartitionName,
		ContextFlag: sql_ir.ContextDefine,
		Str:         n.Name.O,
		Depth:       depth,
	}

	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}

	for i, opt := range n.Options {
		optNode := opt.LogCurrentNode(depth + 1)
		if i == 0 {
			tmpRootNode.LNode = tmpRootNode
		} else { // i > 0
			tmpRootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    tmpRootNode,
				RNode:    optNode,
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
		Depth:    depth,
	}
	rootNode.IRType = sql_ir.TypeSubPartitionDefinition
	return rootNode
}

func (spd *SubPartitionDefinition) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("SUBPARTITION ")
	ctx.WriteName(spd.Name.O)
	for i, opt := range spd.Options {
		ctx.WritePlain(" ")
		if err := opt.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore SubPartitionDefinition.Options[%d]", i)
		}
	}
	return nil
}

type PartitionDefinitionClause interface {
	restore(ctx *format.RestoreCtx) error
	acceptInPlace(v Visitor) bool
	// Validate checks if the clause is consistent with the given options.
	// `pt` can be 0 and `columns` can be -1 to skip checking the clause against
	// the partition type or number of columns in the expression list.
	Validate(pt model.PartitionType, columns int) error
	sql_ir.SqlRsgInterface
}

type PartitionDefinitionClauseNone struct{ sql_ir.SqlRsgInterface }

func (n *PartitionDefinitionClauseNone) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	rootNode.IRType = sql_ir.TypePartitionDefinitionClauseNone
	return rootNode
}
func (n *PartitionDefinitionClauseNone) restore(ctx *format.RestoreCtx) error {
	return nil
}

func (n *PartitionDefinitionClauseNone) acceptInPlace(v Visitor) bool {
	return true
}

func (n *PartitionDefinitionClauseNone) Validate(pt model.PartitionType, columns int) error {
	switch pt {
	case 0:
	case model.PartitionTypeRange:
		return ErrPartitionRequiresValues.GenWithStackByArgs("RANGE", "LESS THAN")
	case model.PartitionTypeList:
		return ErrPartitionRequiresValues.GenWithStackByArgs("LIST", "IN")
	case model.PartitionTypeSystemTime:
		return ErrSystemVersioningWrongPartitions
	}
	return nil
}

type PartitionDefinitionClauseLessThan struct {
	Exprs []ExprNode
	sql_ir.SqlRsgInterface
}

func (n *PartitionDefinitionClauseLessThan) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := " VALUES LESS THAN ( "
	suffix := ")"
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, expr := range n.Exprs {
		exprNNode := expr.LogCurrentNode(depth + 1)
		if i == 0 {
			rootNode.LNode = exprNNode
		} else { // i > 0
			rootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    rootNode,
				RNode:    exprNNode,
				Infix:    ", ",
				Depth:    depth,
			}
		}
	}
	rootNode.Prefix = prefix
	rootNode.Suffix = suffix
	rootNode.IRType = sql_ir.TypePartitionDefinitionClauseLessThan
	return rootNode
}

func (n *PartitionDefinitionClauseLessThan) restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord(" VALUES LESS THAN ")
	ctx.WritePlain("(")
	for i, expr := range n.Exprs {
		if i != 0 {
			ctx.WritePlain(", ")
		}
		if err := expr.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore PartitionDefinitionClauseLessThan.Exprs[%d]", i)
		}
	}
	ctx.WritePlain(")")
	return nil
}

func (n *PartitionDefinitionClauseLessThan) acceptInPlace(v Visitor) bool {
	for i, expr := range n.Exprs {
		newExpr, ok := expr.Accept(v)
		if !ok {
			return false
		}
		n.Exprs[i] = newExpr.(ExprNode)
	}
	return true
}

func (n *PartitionDefinitionClauseLessThan) Validate(pt model.PartitionType, columns int) error {
	switch pt {
	case model.PartitionTypeRange, 0:
	default:
		return ErrPartitionWrongValues.GenWithStackByArgs("RANGE", "LESS THAN")
	}

	switch {
	case columns == 0 && len(n.Exprs) != 1:
		return ErrTooManyValues.GenWithStackByArgs("RANGE")
	case columns > 0 && len(n.Exprs) != columns:
		return ErrPartitionColumnList
	}
	return nil
}

type PartitionDefinitionClauseIn struct {
	Values [][]ExprNode
	sql_ir.SqlRsgInterface
}

func (n *PartitionDefinitionClauseIn) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := ""
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	if len(n.Values) == 0 {
		prefix += " DEFAULT"
		rootNode.Prefix = prefix
		rootNode.IRType = sql_ir.TypePartitionDefinitionClauseIn
		return rootNode
	}

	prefix += " VALUES IN ( "
	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	for i, valList := range n.Values {
		midfix := ""
		if i != 0 {
			midfix = ", "
		}
		if len(valList) == 1 {
			valListNode := valList[0].LogCurrentNode(depth + 1)
			if i == 0 {
				tmpRootNode.LNode = valListNode
			} else { //i > 0
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    valListNode,
					Infix:    midfix,
					Depth:    depth,
				}
			}
		} else {
			tmpPrefix := "("
			tmpSuffix := ")"
			tmpMidfix := ""
			tmptmpRootNode := &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				Depth:    depth,
			}
			for j, val := range valList {
				if j != 0 {
					tmpMidfix = ", "
				}
				valNode := val.LogCurrentNode(depth + 1)
				if i == 0 {
					tmptmpRootNode.LNode = valNode
				} else { //i > 0
					tmptmpRootNode = &sql_ir.SqlRsgIR{
						IRType:   sql_ir.TypeUnknown,
						DataType: sql_ir.DataNone,
						LNode:    tmptmpRootNode,
						RNode:    valNode,
						Infix:    tmpMidfix,
						Depth:    depth,
					}
				}
			}
			tmptmpRootNode.Prefix = tmpPrefix
			tmptmpRootNode.Suffix = tmpSuffix
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
	rootNode.Prefix = prefix
	rootNode.LNode = tmpRootNode
	rootNode.IRType = sql_ir.TypePartitionDefinitionClauseIn
	return rootNode

}

func (n *PartitionDefinitionClauseIn) restore(ctx *format.RestoreCtx) error {
	// we special-case an empty list of values to mean MariaDB's "DEFAULT" clause.
	if len(n.Values) == 0 {
		ctx.WriteKeyWord(" DEFAULT")
		return nil
	}

	ctx.WriteKeyWord(" VALUES IN ")
	ctx.WritePlain("(")
	for i, valList := range n.Values {
		if i != 0 {
			ctx.WritePlain(", ")
		}
		if len(valList) == 1 {
			if err := valList[0].Restore(ctx); err != nil {
				return errors.Annotatef(err, "An error occurred while restore PartitionDefinitionClauseIn.Values[%d][0]", i)
			}
		} else {
			ctx.WritePlain("(")
			for j, val := range valList {
				if j != 0 {
					ctx.WritePlain(", ")
				}
				if err := val.Restore(ctx); err != nil {
					return errors.Annotatef(err, "An error occurred while restore PartitionDefinitionClauseIn.Values[%d][%d]", i, j)
				}
			}
			ctx.WritePlain(")")
		}
	}
	ctx.WritePlain(")")
	return nil
}

func (n *PartitionDefinitionClauseIn) acceptInPlace(v Visitor) bool {
	for _, valList := range n.Values {
		for j, val := range valList {
			newVal, ok := val.Accept(v)
			if !ok {
				return false
			}
			valList[j] = newVal.(ExprNode)
		}
	}
	return true
}

func (n *PartitionDefinitionClauseIn) Validate(pt model.PartitionType, columns int) error {
	switch pt {
	case model.PartitionTypeList, 0:
	default:
		return ErrPartitionWrongValues.GenWithStackByArgs("LIST", "IN")
	}

	if len(n.Values) == 0 {
		return nil
	}

	expectedColCount := len(n.Values[0])
	for _, val := range n.Values[1:] {
		if len(val) != expectedColCount {
			return ErrPartitionColumnList
		}
	}

	switch {
	case columns == 0 && expectedColCount != 1:
		return ErrRowSinglePartitionField
	case columns > 0 && expectedColCount != columns:
		return ErrPartitionColumnList
	}
	return nil
}

type PartitionDefinitionClauseHistory struct {
	Current bool
	sql_ir.SqlRsgInterface
}

func (n *PartitionDefinitionClauseHistory) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := ""
	if n.Current {
		prefix += " CURRENT"
	} else {
		prefix += " HISTORY"
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypePartitionDefinitionClauseHistory
	return rootNode
}

func (n *PartitionDefinitionClauseHistory) restore(ctx *format.RestoreCtx) error {
	if n.Current {
		ctx.WriteKeyWord(" CURRENT")
	} else {
		ctx.WriteKeyWord(" HISTORY")
	}
	return nil
}

func (n *PartitionDefinitionClauseHistory) acceptInPlace(v Visitor) bool {
	return true
}

func (n *PartitionDefinitionClauseHistory) Validate(pt model.PartitionType, columns int) error {
	switch pt {
	case 0, model.PartitionTypeSystemTime:
	default:
		return ErrWrongPartitionTypeExpectedSystemTime
	}

	return nil
}

// PartitionDefinition defines a single partition.
type PartitionDefinition struct {
	Name    model.CIStr
	Clause  PartitionDefinitionClause
	Options []*TableOption
	Sub     []*SubPartitionDefinition
	sql_ir.SqlRsgInterface
}

// Comment returns the comment option given to this definition.
// The second return value indicates if the comment option exists.
func (n *PartitionDefinition) Comment() (string, bool) {
	for _, opt := range n.Options {
		if opt.Tp == TableOptionComment {
			return opt.StrValue, true
		}
	}
	return "", false
}

func (n *PartitionDefinition) acceptInPlace(v Visitor) bool {
	return n.Clause.acceptInPlace(v)
}

func (n *PartitionDefinition) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "PARTITION "
	lNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataPartitionName,
		ContextFlag: sql_ir.ContextDefine,
		Str:         n.Name.O,
		Depth:       depth,
	}

	rNode := n.Clause.LogCurrentNode(depth + 1)

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		RNode:    rNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	for _, opt := range n.Options {
		rNode = opt.LogCurrentNode(depth + 1)
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Infix:    " ",
			Depth:    depth,
		}
	}

	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}

	if len(n.Sub) > 0 {
		for i, spd := range n.Sub {
			tmpMidfix := ""
			if i != 0 {
				tmpMidfix += ","
			}
			spdNode := spd.LogCurrentNode(depth + 1)
			if i == 0 {
				tmpRootNode.LNode = spdNode
			} else { // i > 0
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    spdNode,
					Infix:    tmpMidfix,
					Depth:    depth,
				}
			}
		}
		tmpRootNode.Prefix = " ("
		tmpRootNode.Suffix = ")"
	}

	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypePartitionDefinition
	return rootNode

}

// Restore implements Node interface.
func (n *PartitionDefinition) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("PARTITION ")
	ctx.WriteName(n.Name.O)

	if err := n.Clause.restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore PartitionDefinition.Clause")
	}

	for i, opt := range n.Options {
		ctx.WritePlain(" ")
		if err := opt.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while restore PartitionDefinition.Options[%d]", i)
		}
	}

	if len(n.Sub) > 0 {
		ctx.WritePlain(" (")
		for i, spd := range n.Sub {
			if i != 0 {
				ctx.WritePlain(",")
			}
			if err := spd.Restore(ctx); err != nil {
				return errors.Annotatef(err, "An error occurred while restore PartitionDefinition.Sub[%d]", i)
			}
		}
		ctx.WritePlain(")")
	}

	return nil
}

// PartitionMethod describes how partitions or subpartitions are constructed.
type PartitionMethod struct {
	// Tp is the type of the partition function
	Tp model.PartitionType
	// Linear is a modifier to the HASH and KEY type for choosing a different
	// algorithm
	Linear bool
	// Expr is an expression used as argument of HASH, RANGE, LIST and
	// SYSTEM_TIME types
	Expr ExprNode
	// ColumnNames is a list of column names used as argument of KEY,
	// RANGE COLUMNS and LIST COLUMNS types
	ColumnNames []*ColumnName
	// Unit is a time unit used as argument of SYSTEM_TIME type
	Unit TimeUnitType
	// Limit is a row count used as argument of the SYSTEM_TIME type
	Limit uint64

	// Num is the number of (sub)partitions required by the method.
	Num uint64

	// KeyAlgorithm is the optional hash algorithm type for `PARTITION BY [LINEAR] KEY` syntax.
	KeyAlgorithm *PartitionKeyAlgorithm

	sql_ir.SqlRsgInterface
}

type PartitionKeyAlgorithm struct {
	Type uint64
}

func (n *PartitionMethod) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := ""

	if n.Linear {
		prefix += "LINEAR "
	}
	prefix += n.Tp.String()

	var lNode *sql_ir.SqlRsgIR = nil
	if n.KeyAlgorithm != nil {
		prefix += " ALGORITHM = "
		lNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			IValue:   int64(n.KeyAlgorithm.Type),
			Str:      strconv.FormatInt(int64(n.KeyAlgorithm.Type), 10),
			Depth:    depth,
		}
	}
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	switch {
	case n.Tp == model.PartitionTypeSystemTime:
		if n.Expr != nil && n.Unit != TimeUnitInvalid {
			midfix := " INTERVAL "
			rNode := n.Expr.LogCurrentNode(depth + 1)
			suffix := " " + n.Unit.String()

			rootNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				LNode:    rootNode,
				RNode:    rNode,
				Infix:    midfix,
				Suffix:   suffix,
				Depth:    depth,
			}
		}

	case n.Expr != nil:
		midfix := " ("
		rNode := n.Expr.LogCurrentNode(depth + 1)
		suffix := ")"
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Infix:    midfix,
			Suffix:   suffix,
			Depth:    depth,
		}

	default:
		midfix := ""
		if n.Tp == model.PartitionTypeRange || n.Tp == model.PartitionTypeList {
			midfix += " COLUMNS "
		}

		tmpRootNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			Depth:    depth,
		}
		for i, col := range n.ColumnNames {
			tmpMidfix := ""
			if i > 0 {
				tmpMidfix = ","
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
			Infix:    midfix,
			Depth:    depth,
		}
	}

	if n.Limit > 0 {
		midfix := " LIMIT "
		rNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			IValue:   int64(n.Limit),
			Str:      strconv.FormatInt(int64(n.Limit), 10),
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
	}

	rootNode.IRType = sql_ir.TypePartitionMethod

	return nil
}

// Restore implements the Node interface
func (n *PartitionMethod) Restore(ctx *format.RestoreCtx) error {
	if n.Linear {
		ctx.WriteKeyWord("LINEAR ")
	}
	ctx.WriteKeyWord(n.Tp.String())

	if n.KeyAlgorithm != nil {
		ctx.WriteKeyWord(" ALGORITHM")
		ctx.WritePlainf(" = %d", n.KeyAlgorithm.Type)
	}

	switch {
	case n.Tp == model.PartitionTypeSystemTime:
		if n.Expr != nil && n.Unit != TimeUnitInvalid {
			ctx.WriteKeyWord(" INTERVAL ")
			if err := n.Expr.Restore(ctx); err != nil {
				return errors.Annotate(err, "An error occurred while restore PartitionMethod.Expr")
			}
			ctx.WritePlain(" ")
			ctx.WriteKeyWord(n.Unit.String())
		}

	case n.Expr != nil:
		ctx.WritePlain(" (")
		if err := n.Expr.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore PartitionMethod.Expr")
		}
		ctx.WritePlain(")")

	default:
		if n.Tp == model.PartitionTypeRange || n.Tp == model.PartitionTypeList {
			ctx.WriteKeyWord(" COLUMNS")
		}
		ctx.WritePlain(" (")
		for i, col := range n.ColumnNames {
			if i > 0 {
				ctx.WritePlain(",")
			}
			if err := col.Restore(ctx); err != nil {
				return errors.Annotatef(err, "An error occurred while splicing PartitionMethod.ColumnName[%d]", i)
			}
		}
		ctx.WritePlain(")")
	}

	if n.Limit > 0 {
		ctx.WriteKeyWord(" LIMIT ")
		ctx.WritePlainf("%d", n.Limit)
	}

	return nil
}

// acceptInPlace is like Node.Accept but does not allow replacing the node itself.
func (n *PartitionMethod) acceptInPlace(v Visitor) bool {
	if n.Expr != nil {
		expr, ok := n.Expr.Accept(v)
		if !ok {
			return false
		}
		n.Expr = expr.(ExprNode)
	}
	for i, colName := range n.ColumnNames {
		newColName, ok := colName.Accept(v)
		if !ok {
			return false
		}
		n.ColumnNames[i] = newColName.(*ColumnName)
	}
	return true
}

// PartitionOptions specifies the partition options.
type PartitionOptions struct {
	node
	PartitionMethod
	Sub         *PartitionMethod
	Definitions []*PartitionDefinition
}

// Validate checks if the partition is well-formed.
func (n *PartitionOptions) Validate() error {
	// if both a partition list and the partition numbers are specified, their values must match
	if n.Num != 0 && len(n.Definitions) != 0 && n.Num != uint64(len(n.Definitions)) {
		return ErrPartitionWrongNoPart
	}
	// now check the subpartition count
	if len(n.Definitions) > 0 {
		// ensure the subpartition count for every partitions are the same
		// then normalize n.Num and n.Sub.Num so equality comparison works.
		n.Num = uint64(len(n.Definitions))

		subDefCount := len(n.Definitions[0].Sub)
		for _, pd := range n.Definitions[1:] {
			if len(pd.Sub) != subDefCount {
				return ErrPartitionWrongNoSubpart
			}
		}
		if n.Sub != nil {
			if n.Sub.Num != 0 && subDefCount != 0 && n.Sub.Num != uint64(subDefCount) {
				return ErrPartitionWrongNoSubpart
			}
			if subDefCount != 0 {
				n.Sub.Num = uint64(subDefCount)
			}
		} else if subDefCount != 0 {
			return ErrSubpartition
		}
	}

	switch n.Tp {
	case model.PartitionTypeHash, model.PartitionTypeKey:
		if n.Num == 0 {
			n.Num = 1
		}
	case model.PartitionTypeRange, model.PartitionTypeList:
		if len(n.Definitions) == 0 {
			return ErrPartitionsMustBeDefined.GenWithStackByArgs(n.Tp)
		}
	case model.PartitionTypeSystemTime:
		if len(n.Definitions) < 2 {
			return ErrSystemVersioningWrongPartitions
		}
	}

	for _, pd := range n.Definitions {
		// ensure the partition definition types match the methods,
		// e.g. RANGE partitions only allows VALUES LESS THAN
		if err := pd.Clause.Validate(n.Tp, len(n.ColumnNames)); err != nil {
			return err
		}
	}

	return nil
}

func (n *PartitionOptions) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "PARTITION BY "

	lNode := n.PartitionMethod.LogCurrentNode(depth + 1)

	midfix := ""
	var rNode *sql_ir.SqlRsgIR = nil
	if n.Num > 0 && len(n.Definitions) == 0 {
		midfix = " PARTITIONS "
		rNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			IValue:   int64(n.Num),
			Str:      strconv.FormatInt(int64(n.Num), 10),
			Depth:    depth,
		}
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
	midfix = ""

	if n.Sub != nil {
		midfix = " SUBPARTITION BY "
		rNode = n.Sub.LogCurrentNode(depth + 1)
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Infix:    midfix,
			Depth:    depth,
		}
		if n.Sub.Num > 0 {
			midfix = " SUBPARTITIONS "
			rNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeUnknown,
				DataType: sql_ir.DataNone,
				IValue:   int64(n.Sub.Num),
				Str:      strconv.FormatInt(int64(n.Sub.Num), 10),
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

		}
	}

	tmpRootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	if len(n.Definitions) > 0 {
		for i, def := range n.Definitions {
			defNode := def.LogCurrentNode(depth + 1)
			if i == 0 {
				tmpRootNode.LNode = defNode
			} else { // i > 0
				tmpRootNode = &sql_ir.SqlRsgIR{
					IRType:   sql_ir.TypeUnknown,
					DataType: sql_ir.DataNone,
					LNode:    tmpRootNode,
					RNode:    defNode,
					Infix:    ", ",
					Depth:    depth,
				}
			}
		}
		tmpRootNode.Prefix = " ( "
		tmpRootNode.Suffix = " ) "
	}
	rootNode = &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    rootNode,
		RNode:    tmpRootNode,
		Depth:    depth,
	}
	rootNode.IRType = sql_ir.TypePartitionOptions

	return rootNode
}

func (n *PartitionOptions) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("PARTITION BY ")
	if err := n.PartitionMethod.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore PartitionOptions.PartitionMethod")
	}

	if n.Num > 0 && len(n.Definitions) == 0 {
		ctx.WriteKeyWord(" PARTITIONS ")
		ctx.WritePlainf("%d", n.Num)
	}

	if n.Sub != nil {
		ctx.WriteKeyWord(" SUBPARTITION BY ")
		if err := n.Sub.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while restore PartitionOptions.Sub")
		}
		if n.Sub.Num > 0 {
			ctx.WriteKeyWord(" SUBPARTITIONS ")
			ctx.WritePlainf("%d", n.Sub.Num)
		}
	}

	if len(n.Definitions) > 0 {
		ctx.WritePlain(" (")
		for i, def := range n.Definitions {
			if i > 0 {
				ctx.WritePlain(",")
			}
			if err := def.Restore(ctx); err != nil {
				return errors.Annotatef(err, "An error occurred while restore PartitionOptions.Definitions[%d]", i)
			}
		}
		ctx.WritePlain(")")
	}

	return nil
}

func (n *PartitionOptions) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}

	n = newNode.(*PartitionOptions)
	if !n.PartitionMethod.acceptInPlace(v) {
		return n, false
	}
	if n.Sub != nil && !n.Sub.acceptInPlace(v) {
		return n, false
	}
	for _, def := range n.Definitions {
		if !def.acceptInPlace(v) {
			return n, false
		}
	}
	return v.Leave(n)
}

// RecoverTableStmt is a statement to recover dropped table.
type RecoverTableStmt struct {
	ddlNode

	JobID  int64
	Table  *TableName
	JobNum int64
}

func (n *RecoverTableStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "RECOVER TABLE "
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}

	if n.JobID != 0 {
		prefix += "BY JOB "
		lNode := &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			IValue:   n.JobID,
			Str:      strconv.FormatInt(n.JobID, 10),
			Depth:    depth,
		}
		rootNode.Prefix = prefix
		rootNode.LNode = lNode
		prefix = ""
	} else {
		tableNode := n.Table.LogCurrentNode(depth + 1)
		tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(tableNode, sql_ir.DataTableName)
		for _, tableNameNode := range tableNameNodeList {
			tableNameNode.DataType = sql_ir.DataTableName
			tableNameNode.ContextFlag = sql_ir.ContextUse
		}

		rootNode.LNode = tableNode
		if n.JobNum > 0 {
			numNode := &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeIntegerLiteral,
				DataType: sql_ir.DataNone,
				IValue:   n.JobNum,
				Str:      strconv.FormatInt(n.JobNum, 10),
				Depth:    depth,
			}
			rootNode.RNode = numNode
		}
	}
	rootNode.IRType = sql_ir.TypeRecoverTableStmt
	return rootNode
}

// Restore implements Node interface.
func (n *RecoverTableStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("RECOVER TABLE ")
	if n.JobID != 0 {
		ctx.WriteKeyWord("BY JOB ")
		ctx.WritePlainf("%d", n.JobID)
	} else {
		if err := n.Table.Restore(ctx); err != nil {
			return errors.Annotate(err, "An error occurred while splicing RecoverTableStmt Table")
		}
		if n.JobNum > 0 {
			ctx.WritePlainf(" %d", n.JobNum)
		}
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *RecoverTableStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}

	n = newNode.(*RecoverTableStmt)
	if n.Table != nil {
		node, ok := n.Table.Accept(v)
		if !ok {
			return n, false
		}
		n.Table = node.(*TableName)
	}
	return v.Leave(n)
}

// FlashBackTableStmt is a statement to restore a dropped/truncate table.
type FlashBackTableStmt struct {
	ddlNode

	Table   *TableName
	NewName string
}

func (n *FlashBackTableStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {
	prefix := "FLASHBACK TABLE "

	lNode := n.Table.LogCurrentNode(depth + 1)
	tableNameNodeList := sql_ir.GetSubNodeFromParentNodeWithDataType(lNode, sql_ir.DataTableName)
	for _, tableNameNode := range tableNameNodeList {
		tableNameNode.DataType = sql_ir.DataTableName
		tableNameNode.ContextFlag = sql_ir.ContextUse
	}

	midfix := ""
	var rNode *sql_ir.SqlRsgIR
	if len(n.NewName) > 0 {
		midfix = " TO "
		rNode = &sql_ir.SqlRsgIR{
			IRType:      sql_ir.TypeIdentifier,
			DataType:    sql_ir.DataTableName,
			ContextFlag: sql_ir.ContextUse,
			Str:         n.NewName,
			Depth:       depth,
		}
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

	rootNode.IRType = sql_ir.TypeFlashBackTableStmt
	return rootNode

}

// Restore implements Node interface.
func (n *FlashBackTableStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("FLASHBACK TABLE ")
	if err := n.Table.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while splicing RecoverTableStmt Table")
	}
	if len(n.NewName) > 0 {
		ctx.WriteKeyWord(" TO ")
		ctx.WriteName(n.NewName)
	}
	return nil
}

// Accept implements Node Accept interface.
func (n *FlashBackTableStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}

	n = newNode.(*FlashBackTableStmt)
	if n.Table != nil {
		node, ok := n.Table.Accept(v)
		if !ok {
			return n, false
		}
		n.Table = node.(*TableName)
	}
	return v.Leave(n)
}

type AttributesSpec struct {
	node

	Attributes string
	Default    bool
}

func (n *AttributesSpec) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "ATTRIBUTES = "
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	if n.Default {
		prefix += "DEFAULT"
		rootNode.Prefix = prefix
	} else {
		prefix += n.Attributes
		rootNode.Prefix = prefix
	}
	rootNode.IRType = sql_ir.TypeAttributesSpec
	return rootNode

}

func (n *AttributesSpec) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("ATTRIBUTES")
	ctx.WritePlain("=")
	if n.Default {
		ctx.WriteKeyWord("DEFAULT")
		return nil
	}
	ctx.WriteString(n.Attributes)
	return nil
}

func (n *AttributesSpec) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*AttributesSpec)
	return v.Leave(n)
}

type StatsOptionsSpec struct {
	node

	StatsOptions string
	Default      bool
}

func (n *StatsOptionsSpec) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "STATS_OPTIONS = "
	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Depth:    depth,
	}
	if n.Default {
		prefix += "DEFAULT"
		rootNode.Prefix = prefix
	} else {
		prefix += n.StatsOptions
		rootNode.Prefix = prefix
	}
	rootNode.IRType = sql_ir.TypeStatsOptionsSpec
	return rootNode
}

func (n *StatsOptionsSpec) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("STATS_OPTIONS")
	ctx.WritePlain("=")
	if n.Default {
		ctx.WriteKeyWord("DEFAULT")
		return nil
	}
	ctx.WriteString(n.StatsOptions)
	return nil
}

func (n *StatsOptionsSpec) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*StatsOptionsSpec)
	return v.Leave(n)
}

// AlterPlacementPolicyStmt is a statement to alter placement policy option.
type AlterPlacementPolicyStmt struct {
	ddlNode

	PolicyName       model.CIStr
	IfExists         bool
	PlacementOptions []*PlacementOption
}

func (n *AlterPlacementPolicyStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "ALTER PLACEMENT POLICY "
	if n.IfExists {
		prefix += "IF EXISTS "
	}
	lNode := &sql_ir.SqlRsgIR{
		IRType:      sql_ir.TypeIdentifier,
		DataType:    sql_ir.DataPolicyName,
		ContextFlag: sql_ir.ContextUse,
		Str:         n.PolicyName.O,
		Depth:       depth,
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	for _, option := range n.PlacementOptions {
		midfix := " "
		rNode := option.LogCurrentNode(depth + 1)

		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    rNode,
			Infix:    midfix,
			Depth:    depth,
		}
	}

	rootNode.IRType = sql_ir.TypeAlterPlacementPolicyStmt
	return rootNode

}

func (n *AlterPlacementPolicyStmt) Restore(ctx *format.RestoreCtx) error {
	if ctx.Flags.HasSkipPlacementRuleForRestoreFlag() {
		return nil
	}
	if ctx.Flags.HasTiDBSpecialCommentFlag() {
		return restorePlacementStmtInSpecialComment(ctx, n)
	}

	ctx.WriteKeyWord("ALTER PLACEMENT POLICY ")
	if n.IfExists {
		ctx.WriteKeyWord("IF EXISTS ")
	}
	ctx.WriteName(n.PolicyName.O)
	for i, option := range n.PlacementOptions {
		ctx.WritePlain(" ")
		if err := option.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while splicing AlterPlacementPolicyStmt TableOption: [%v]", i)
		}
	}
	return nil
}

func (n *AlterPlacementPolicyStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*AlterPlacementPolicyStmt)
	return v.Leave(n)
}

// AlterSequenceStmt is a statement to alter sequence option.
type AlterSequenceStmt struct {
	ddlNode

	// sequence name
	Name *TableName

	IfExists   bool
	SeqOptions []*SequenceOption
}

func (n *AlterSequenceStmt) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "ALTER SEQUENCE "
	if n.IfExists {
		prefix += "IF EXISTS "
	}
	lNode := n.Name.LogCurrentNode(depth + 1)
	seqNameList := sql_ir.GetSubNodeFromParentNodeWithDataType(lNode, sql_ir.DataTableName)
	for _, seqName := range seqNameList {
		seqName.DataType = sql_ir.DataSequenceName
		seqName.ContextFlag = sql_ir.ContextUse
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	for _, option := range n.SeqOptions {
		optionNode := option.LogCurrentNode(depth + 1)
		rootNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeUnknown,
			DataType: sql_ir.DataNone,
			LNode:    rootNode,
			RNode:    optionNode,
			Infix:    " ",
			Depth:    depth,
		}
	}

	rootNode.IRType = sql_ir.TypeAlterSequenceStmt
	return rootNode
}

func (n *AlterSequenceStmt) Restore(ctx *format.RestoreCtx) error {
	ctx.WriteKeyWord("ALTER SEQUENCE ")
	if n.IfExists {
		ctx.WriteKeyWord("IF EXISTS ")
	}
	if err := n.Name.Restore(ctx); err != nil {
		return errors.Annotate(err, "An error occurred while restore AlterSequenceStmt.Table")
	}
	for i, option := range n.SeqOptions {
		ctx.WritePlain(" ")
		if err := option.Restore(ctx); err != nil {
			return errors.Annotatef(err, "An error occurred while splicing AlterSequenceStmt SequenceOption: [%v]", i)
		}
	}
	return nil
}

func (n *AlterSequenceStmt) Accept(v Visitor) (Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*AlterSequenceStmt)
	node, ok := n.Name.Accept(v)
	if !ok {
		return n, false
	}
	n.Name = node.(*TableName)
	return v.Leave(n)
}

func restorePlacementStmtInSpecialComment(ctx *format.RestoreCtx, n DDLNode) error {
	origFlags := ctx.Flags
	defer func() {
		ctx.Flags = origFlags
	}()

	ctx.Flags |= format.RestoreTiDBSpecialComment
	return ctx.WriteWithSpecialComments(tidb.FeatureIDPlacement, func() error {
		ctx.Flags &= ^format.RestoreTiDBSpecialComment
		return n.Restore(ctx)
	})
}
