// Copyright 2015 The Cockroach Authors.
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
	"fmt"
	"strings"

	"github.com/cockroachdb/cockroach/pkg/sql/lex"
)

// AlterTable represents an ALTER TABLE statement.
type AlterTable struct {
	IfExists bool
	Table    *UnresolvedObjectName
	Cmds     AlterTableCmds
	SQLRightInterface
}

// Format implements the NodeFormatter interface.
func (node *AlterTable) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER TABLE ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(node.Table)
	ctx.FormatNode(&node.Cmds)
}

// SQLRight Code Injection.
func (node AlterTable) LogCurrentNode(depth int) *SQLRightIR {

	tmpTableStr := node.Table.String()
	LNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataTableName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         tmpTableStr,
	}

	RNode := node.Cmds.LogCurrentNode(depth + 1)

	prefix := "ALTER TABLE "
	if node.IfExists {
		prefix += "IF EXISTS "
	}

	rootIR := &SQLRightIR{
		IRType:   TypeAlterTable,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterTableCmds represents a list of table alterations.
type AlterTableCmds []AlterTableCmd

// Format implements the NodeFormatter interface.
func (node *AlterTableCmds) Format(ctx *FmtCtx) {
	for i, n := range *node {
		if i > 0 {
			ctx.WriteString(",")
		}
		ctx.FormatNode(n)
	}
}

// SQLRight Code Injection.
func (node *AlterTableCmds) LogCurrentNode(depth int) *SQLRightIR {

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
				infix = ","
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
			RNode := n.LogCurrentNode(depth + 1)

			tmpIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    tmpIR,
				RNode:    RNode,
				Prefix:   "",
				Infix:    ", ",
				Suffix:   "",
				Depth:    depth,
			}
		}
	}

	// Only flag the root node for the type.
	tmpIR.IRType = TypeAlterChangefeedCmds
	return tmpIR
}

// AlterTableCmd represents a table modification operation.
type AlterTableCmd interface {
	NodeFormatter
	// TelemetryName returns the counter name to use for telemetry purposes.
	TelemetryName() string
	// Placeholder function to ensure that only desired types
	// (AlterTable*) conform to the AlterTableCmd interface.
	alterTableCmd()

	SQLRightInterface
}

func (*AlterTableAddColumn) alterTableCmd()          {}
func (*AlterTableAddConstraint) alterTableCmd()      {}
func (*AlterTableAlterColumnType) alterTableCmd()    {}
func (*AlterTableAlterPrimaryKey) alterTableCmd()    {}
func (*AlterTableDropColumn) alterTableCmd()         {}
func (*AlterTableDropConstraint) alterTableCmd()     {}
func (*AlterTableDropNotNull) alterTableCmd()        {}
func (*AlterTableDropStored) alterTableCmd()         {}
func (*AlterTableSetNotNull) alterTableCmd()         {}
func (*AlterTableRenameColumn) alterTableCmd()       {}
func (*AlterTableRenameConstraint) alterTableCmd()   {}
func (*AlterTableSetAudit) alterTableCmd()           {}
func (*AlterTableSetDefault) alterTableCmd()         {}
func (*AlterTableSetOnUpdate) alterTableCmd()        {}
func (*AlterTableSetVisible) alterTableCmd()         {}
func (*AlterTableValidateConstraint) alterTableCmd() {}
func (*AlterTablePartitionByTable) alterTableCmd()   {}
func (*AlterTableInjectStats) alterTableCmd()        {}
func (*AlterTableSetStorageParams) alterTableCmd()   {}
func (*AlterTableResetStorageParams) alterTableCmd() {}

var _ AlterTableCmd = &AlterTableAddColumn{}
var _ AlterTableCmd = &AlterTableAddConstraint{}
var _ AlterTableCmd = &AlterTableAlterColumnType{}
var _ AlterTableCmd = &AlterTableDropColumn{}
var _ AlterTableCmd = &AlterTableDropConstraint{}
var _ AlterTableCmd = &AlterTableDropNotNull{}
var _ AlterTableCmd = &AlterTableDropStored{}
var _ AlterTableCmd = &AlterTableSetNotNull{}
var _ AlterTableCmd = &AlterTableRenameColumn{}
var _ AlterTableCmd = &AlterTableRenameConstraint{}
var _ AlterTableCmd = &AlterTableSetAudit{}
var _ AlterTableCmd = &AlterTableSetDefault{}
var _ AlterTableCmd = &AlterTableSetOnUpdate{}
var _ AlterTableCmd = &AlterTableSetVisible{}
var _ AlterTableCmd = &AlterTableValidateConstraint{}
var _ AlterTableCmd = &AlterTablePartitionByTable{}
var _ AlterTableCmd = &AlterTableInjectStats{}
var _ AlterTableCmd = &AlterTableSetStorageParams{}
var _ AlterTableCmd = &AlterTableResetStorageParams{}

// ColumnMutationCmd is the subset of AlterTableCmds that modify an
// existing column.
type ColumnMutationCmd interface {
	AlterTableCmd
	GetColumn() Name
}

// AlterTableAddColumn represents an ADD COLUMN command.
type AlterTableAddColumn struct {
	IfNotExists bool
	ColumnDef   *ColumnTableDef
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTableAddColumn) TelemetryName() string {
	return "add_column"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableAddColumn) Format(ctx *FmtCtx) {
	ctx.WriteString(" ADD COLUMN ")
	if node.IfNotExists {
		ctx.WriteString("IF NOT EXISTS ")
	}
	ctx.FormatNode(node.ColumnDef)
}

// SQLRight Code Injection.
func (node *AlterTableAddColumn) LogCurrentNode(depth int) *SQLRightIR {

	prefix := " ADD COLUMN "
	if node.IfNotExists {
		prefix += "IF NOT EXISTS "
	}
	LNode := node.ColumnDef.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeAlterTableAddColumn,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// HoistAddColumnConstraints converts column constraints in ADD COLUMN commands,
// stored in node.Cmds, into top-level commands to add those constraints.
// Currently, this only applies to checks. For example, the ADD COLUMN in
//
//	ALTER TABLE t ADD COLUMN a INT CHECK (a < 1)
//
// is transformed into two commands, as in
//
//	ALTER TABLE t ADD COLUMN a INT, ADD CONSTRAINT check_a CHECK (a < 1)
//
// (with an auto-generated name).
//
// Note that some SQL databases require that a constraint attached to a column
// to refer only to the column it is attached to. We follow Postgres' behavior,
// however, in omitting this restriction by blindly hoisting all column
// constraints. For example, the following statement is accepted in
// CockroachDB and Postgres, but not necessarily other SQL databases:
//
//	ALTER TABLE t ADD COLUMN a INT CHECK (a < b)
func (node *AlterTable) HoistAddColumnConstraints(onHoistedFKConstraint func()) {
	var normalizedCmds AlterTableCmds

	for _, cmd := range node.Cmds {
		normalizedCmds = append(normalizedCmds, cmd)

		if t, ok := cmd.(*AlterTableAddColumn); ok {
			d := t.ColumnDef
			for _, checkExpr := range d.CheckExprs {
				normalizedCmds = append(normalizedCmds,
					&AlterTableAddConstraint{
						ConstraintDef: &CheckConstraintTableDef{
							Expr: checkExpr.Expr,
							Name: checkExpr.ConstraintName,
						},
						ValidationBehavior: ValidationDefault,
					},
				)
			}
			d.CheckExprs = nil
			if d.HasFKConstraint() {
				var targetCol NameList
				if d.References.Col != "" {
					targetCol = append(targetCol, d.References.Col)
				}
				fk := &ForeignKeyConstraintTableDef{
					Table:    *d.References.Table,
					FromCols: NameList{d.Name},
					ToCols:   targetCol,
					Name:     d.References.ConstraintName,
					Actions:  d.References.Actions,
					Match:    d.References.Match,
				}
				constraint := &AlterTableAddConstraint{
					ConstraintDef:      fk,
					ValidationBehavior: ValidationDefault,
				}
				normalizedCmds = append(normalizedCmds, constraint)
				d.References.Table = nil
				onHoistedFKConstraint()
			}
		}
	}
	node.Cmds = normalizedCmds
}

// ValidationBehavior specifies whether or not a constraint is validated.
type ValidationBehavior int

const (
	// ValidationDefault is the default validation behavior (immediate).
	ValidationDefault ValidationBehavior = iota
	// ValidationSkip skips validation of any existing data.
	ValidationSkip
)

// AlterTableAddConstraint represents an ADD CONSTRAINT command.
type AlterTableAddConstraint struct {
	ConstraintDef      ConstraintTableDef
	ValidationBehavior ValidationBehavior
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTableAddConstraint) TelemetryName() string {
	return "add_constraint"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableAddConstraint) Format(ctx *FmtCtx) {
	ctx.WriteString(" ADD ")
	ctx.FormatNode(node.ConstraintDef)
	if node.ValidationBehavior == ValidationSkip {
		ctx.WriteString(" NOT VALID")
	}
}

// SQLRight Code Injection.
func (node *AlterTableAddConstraint) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.ConstraintDef.LogCurrentNode(depth + 1)
	infix := ""
	if node.ValidationBehavior == ValidationSkip {
		infix = " NOT VALID"
	}
	rootIR := &SQLRightIR{
		IRType:   TypeAlterTableAddConstraint,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: " ADD ",
		Infix:  infix,
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// AlterTableAlterColumnType represents an ALTER TABLE ALTER COLUMN TYPE command.
type AlterTableAlterColumnType struct {
	Collation string
	Column    Name
	ToType    ResolvableTypeReference
	Using     Expr
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTableAlterColumnType) TelemetryName() string {
	return "alter_column_type"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableAlterColumnType) Format(ctx *FmtCtx) {
	ctx.WriteString(" ALTER COLUMN ")
	ctx.FormatNode(&node.Column)
	ctx.WriteString(" SET DATA TYPE ")
	ctx.WriteString(node.ToType.SQLString())
	if len(node.Collation) > 0 {
		ctx.WriteString(" COLLATE ")
		lex.EncodeLocaleName(&ctx.Buffer, node.Collation)
	}
	if node.Using != nil {
		ctx.WriteString(" USING ")
		ctx.FormatNode(node.Using)
	}
}

// SQLRight Code Injection.
func (node *AlterTableAlterColumnType) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataColumnName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Column),
	}
	columnNode := tmpNode

	typeStr := node.ToType.SQLString()
	typeNode := &SQLRightIR{
		IRType:   TypeResolvableTypeReference,
		DataType: DataNone,
		Prefix:   "",
		Infix:    typeStr,
		Suffix:   "",
		Depth:    depth,
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    columnNode,
		RNode:    typeNode,
		Prefix:   " ALTER COLUMN ",
		Infix:    " SET DATA TYPE ",
		Suffix:   "",
		Depth:    depth,
	}

	if len(node.Collation) > 0 {
		collationNode := &SQLRightIR{
			IRType:       TypeStringLiteral,
			DataType:     DataCollationName,
			ContextFlag:  ContextUnknown,
			DataAffinity: AFFICOLLATE,
			Prefix:       "",
			Infix:        "",
			Suffix:       "",
			Depth:        depth + 1,
			Str:          node.Collation,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    collationNode,
			Prefix:   "",
			Infix:    " COLLATE ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.Using != nil {
		usingExpr := node.Using.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUsingCluster,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    usingExpr,
			Prefix:   "",
			Infix:    " USING ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	return rootIR
}

// GetColumn implements the ColumnMutationCmd interface.
func (node *AlterTableAlterColumnType) GetColumn() Name {
	return node.Column
}

// AlterTableAlterPrimaryKey represents an ALTER TABLE ALTER PRIMARY KEY command.
type AlterTableAlterPrimaryKey struct {
	Columns       IndexElemList
	Sharded       *ShardedIndexDef
	Name          Name
	StorageParams StorageParams
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTableAlterPrimaryKey) TelemetryName() string {
	return "alter_primary_key"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableAlterPrimaryKey) Format(ctx *FmtCtx) {
	ctx.WriteString(" ALTER PRIMARY KEY USING COLUMNS (")
	ctx.FormatNode(&node.Columns)
	ctx.WriteString(")")
	if node.Sharded != nil {
		ctx.FormatNode(node.Sharded)
	}
	if node.StorageParams != nil {
		ctx.WriteString(" WITH (")
		ctx.FormatNode(&node.StorageParams)
		ctx.WriteString(")")
	}
}

// SQLRight Code Injection.
func (node *AlterTableAlterPrimaryKey) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.Columns.LogCurrentNode(depth+1, ContextUse)

	var RNode *SQLRightIR
	if node.Sharded != nil {
		RNode = node.Sharded.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   " ALTER PRIMARY KEY USING COLUMNS ( ",
		Infix:    ")",
		Suffix:   "",
		Depth:    depth,
	}

	if node.StorageParams != nil {
		RNode = node.StorageParams.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    " WITH (",
			Suffix:   ")",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeAlterTableAlterPrimaryKey
	return rootIR
}

// AlterTableDropColumn represents a DROP COLUMN command.
type AlterTableDropColumn struct {
	IfExists     bool
	Column       Name
	DropBehavior DropBehavior
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTableDropColumn) TelemetryName() string {
	return "drop_column"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableDropColumn) Format(ctx *FmtCtx) {
	ctx.WriteString(" DROP COLUMN ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(&node.Column)
	if node.DropBehavior != DropDefault {
		ctx.Printf(" %s", node.DropBehavior)
	}
}

// SQLRight Code Injection.
func (node *AlterTableDropColumn) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""
	if node.IfExists {
		prefix = "IF EXISTS "
	}
	LNode := &SQLRightIR{
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataColumnName,
		ContextFlag: ContextUndefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Column),
	}
	RNode := tmpNode

	suffix := ""
	if node.DropBehavior != DropDefault {
		suffix = fmt.Sprintf(" %s", node.DropBehavior)
	}

	rootIR := &SQLRightIR{
		IRType:   TypeAlterTableDropColumn,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   " DROP COLUMN ",
		Infix:    "",
		Suffix:   suffix,
		Depth:    depth,
	}

	return rootIR
}

// AlterTableDropConstraint represents a DROP CONSTRAINT command.
type AlterTableDropConstraint struct {
	IfExists     bool
	Constraint   Name
	DropBehavior DropBehavior
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTableDropConstraint) TelemetryName() string {
	return "drop_constraint"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableDropConstraint) Format(ctx *FmtCtx) {
	ctx.WriteString(" DROP CONSTRAINT ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(&node.Constraint)
	if node.DropBehavior != DropDefault {
		ctx.Printf(" %s", node.DropBehavior)
	}
}

// SQLRight Code Injection.
func (node *AlterTableDropConstraint) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""
	if node.IfExists {
		prefix = "IF EXISTS "
	}
	LNode := &SQLRightIR{
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataConstraintName,
		ContextFlag: ContextUndefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Constraint),
	}
	RNode := tmpNode

	suffix := ""
	if node.DropBehavior != DropDefault {
		suffix = fmt.Sprintf(" %s", node.DropBehavior)
	}

	rootIR := &SQLRightIR{
		IRType:   TypeAlterTableDropConstraint,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   " DROP CONSTRAINT ",
		Infix:    "",
		Suffix:   suffix,
		Depth:    depth,
	}

	return rootIR
}

// AlterTableValidateConstraint represents a VALIDATE CONSTRAINT command.
type AlterTableValidateConstraint struct {
	Constraint Name
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTableValidateConstraint) TelemetryName() string {
	return "validate_constraint"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableValidateConstraint) Format(ctx *FmtCtx) {
	ctx.WriteString(" VALIDATE CONSTRAINT ")
	ctx.FormatNode(&node.Constraint)
}

// SQLRight Code Injection.
func (node *AlterTableValidateConstraint) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataConstraintName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Constraint),
	}
	LNode := tmpNode

	rootIR := &SQLRightIR{
		IRType:   TypeAlterTableValidateConstraint,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: " VALIDATE CONSTRAINT ",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// AlterTableRenameColumn represents an ALTER TABLE RENAME [COLUMN] command.
type AlterTableRenameColumn struct {
	Column  Name
	NewName Name
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTableRenameColumn) TelemetryName() string {
	return "rename_column"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableRenameColumn) Format(ctx *FmtCtx) {
	ctx.WriteString(" RENAME COLUMN ")
	ctx.FormatNode(&node.Column)
	ctx.WriteString(" TO ")
	ctx.FormatNode(&node.NewName)
}

// SQLRight Code Injection.
func (node *AlterTableRenameColumn) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataColumnName,
		ContextFlag: ContextReplaceUndefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Column),
	}
	LNode := tmpNode

	tmpNode = &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataColumnName,
		ContextFlag: ContextReplaceDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.NewName),
	}
	RNode := tmpNode

	rootIR := &SQLRightIR{
		IRType:   TypeAlterTableRenameColumn,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   " RENAME COLUMN ",
		Infix:    " TO ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterTableRenameConstraint represents an ALTER TABLE RENAME CONSTRAINT command.
type AlterTableRenameConstraint struct {
	Constraint Name
	NewName    Name
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTableRenameConstraint) TelemetryName() string {
	return "rename_constraint"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableRenameConstraint) Format(ctx *FmtCtx) {
	ctx.WriteString(" RENAME CONSTRAINT ")
	ctx.FormatNode(&node.Constraint)
	ctx.WriteString(" TO ")
	ctx.FormatNode(&node.NewName)
}

// SQLRight Code Injection.
func (node *AlterTableRenameConstraint) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataConstraintName,
		ContextFlag: ContextReplaceUndefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Constraint),
	}
	LNode := tmpNode

	tmpNode = &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataConstraintName,
		ContextFlag: ContextReplaceDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.NewName),
	}
	RNode := tmpNode

	rootIR := &SQLRightIR{
		IRType:   TypeAlterTableRenameConstraint,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   " RENAME CONSTRAINT ",
		Infix:    " TO ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterTableSetDefault represents an ALTER COLUMN SET DEFAULT
// or DROP DEFAULT command.
type AlterTableSetDefault struct {
	Column  Name
	Default Expr
}

// GetColumn implements the ColumnMutationCmd interface.
func (node *AlterTableSetDefault) GetColumn() Name {
	return node.Column
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTableSetDefault) TelemetryName() string {
	return "set_default"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableSetDefault) Format(ctx *FmtCtx) {
	ctx.WriteString(" ALTER COLUMN ")
	ctx.FormatNode(&node.Column)
	if node.Default == nil {
		ctx.WriteString(" DROP DEFAULT")
	} else {
		ctx.WriteString(" SET DEFAULT ")
		ctx.FormatNode(node.Default)
	}
}

// SQLRight Code Injection.
func (node *AlterTableSetDefault) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataColumnName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Column),
	}
	LNode := tmpNode

	var RNode *SQLRightIR
	infix := " DROP DEFAULT "
	if node.Default != nil {
		infix = " SET DEFAULT "
		RNode = node.Default.LogCurrentNode(depth + 1)
	} else {
		// Pass
	}

	rootIR := &SQLRightIR{
		IRType:   TypeAlterTableSetDefault,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   " ALTER COLUMN ",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterTableSetOnUpdate represents an ALTER COLUMN ON UPDATE SET
// or DROP ON UPDATE command.
type AlterTableSetOnUpdate struct {
	Column Name
	Expr   Expr
}

// GetColumn implements the ColumnMutationCmd interface.
func (node *AlterTableSetOnUpdate) GetColumn() Name {
	return node.Column
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTableSetOnUpdate) TelemetryName() string {
	return "set_on_update"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableSetOnUpdate) Format(ctx *FmtCtx) {
	ctx.WriteString(" ALTER COLUMN ")
	ctx.FormatNode(&node.Column)
	if node.Expr == nil {
		ctx.WriteString(" DROP ON UPDATE")
	} else {
		ctx.WriteString(" SET ON UPDATE ")
		ctx.FormatNode(node.Expr)
	}
}

// SQLRight Code Injection.
func (node *AlterTableSetOnUpdate) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataColumnName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Column),
	}
	LNode := tmpNode

	var RNode *SQLRightIR
	infix := " DROP ON UPDATE "
	if node.Expr != nil {
		infix = " SET ON UPDATE "
		RNode = node.Expr.LogCurrentNode(depth + 1)
	} else {
		// Pass
	}

	rootIR := &SQLRightIR{
		IRType:   TypeAlterTableSetOnUpdate,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   " ALTER COLUMN ",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterTableSetVisible represents an ALTER COLUMN SET VISIBLE or NOT VISIBLE command.
type AlterTableSetVisible struct {
	Column  Name
	Visible bool
}

// GetColumn implements the ColumnMutationCmd interface.
func (node *AlterTableSetVisible) GetColumn() Name {
	return node.Column
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTableSetVisible) TelemetryName() string {
	return "set_visible"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableSetVisible) Format(ctx *FmtCtx) {
	ctx.WriteString(" ALTER COLUMN ")
	ctx.FormatNode(&node.Column)
	ctx.WriteString(" SET ")
	if !node.Visible {
		ctx.WriteString("NOT ")
	}
	ctx.WriteString("VISIBLE")
}

// SQLRight Code Injection.
func (node *AlterTableSetVisible) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataColumnName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Column),
	}
	LNode := tmpNode

	prefix := ""
	if !node.Visible {
		prefix = "NOT "
	}

	tmpNode = &SQLRightIR{
		IRType:   TypeOptNot,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}
	RNode := tmpNode

	rootIR := &SQLRightIR{
		IRType:   TypeAlterTableSetOnUpdate,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   " ALTER COLUMN ",
		Infix:    " SET ",
		Suffix:   "VISIBLE",
		Depth:    depth,
	}

	return rootIR
}

// AlterTableSetNotNull represents an ALTER COLUMN SET NOT NULL
// command.
type AlterTableSetNotNull struct {
	Column Name
}

// GetColumn implements the ColumnMutationCmd interface.
func (node *AlterTableSetNotNull) GetColumn() Name {
	return node.Column
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTableSetNotNull) TelemetryName() string {
	return "set_not_null"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableSetNotNull) Format(ctx *FmtCtx) {
	ctx.WriteString(" ALTER COLUMN ")
	ctx.FormatNode(&node.Column)
	ctx.WriteString(" SET NOT NULL")
}

// SQLRight Code Injection.
func (node *AlterTableSetNotNull) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataColumnName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Column),
	}
	LNode := tmpNode

	rootIR := &SQLRightIR{
		IRType:   TypeAlterTableSetNotNull,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: " ALTER COLUMN ",
		Infix:  " SET NOT NULL",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// AlterTableDropNotNull represents an ALTER COLUMN DROP NOT NULL
// command.
type AlterTableDropNotNull struct {
	Column Name
}

// GetColumn implements the ColumnMutationCmd interface.
func (node *AlterTableDropNotNull) GetColumn() Name {
	return node.Column
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTableDropNotNull) TelemetryName() string {
	return "drop_not_null"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableDropNotNull) Format(ctx *FmtCtx) {
	ctx.WriteString(" ALTER COLUMN ")
	ctx.FormatNode(&node.Column)
	ctx.WriteString(" DROP NOT NULL")
}

// SQLRight Code Injection.
func (node *AlterTableDropNotNull) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataColumnName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Column),
	}
	LNode := tmpNode

	rootIR := &SQLRightIR{
		IRType:   TypeAlterTableDropNotNull,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: " ALTER COLUMN ",
		Infix:  " DROP NOT NULL",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// AlterTableDropStored represents an ALTER COLUMN DROP STORED command
// to remove the computed-ness from a column.
type AlterTableDropStored struct {
	Column Name
}

// GetColumn implemnets the ColumnMutationCmd interface.
func (node *AlterTableDropStored) GetColumn() Name {
	return node.Column
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTableDropStored) TelemetryName() string {
	return "drop_stored"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableDropStored) Format(ctx *FmtCtx) {
	ctx.WriteString(" ALTER COLUMN ")
	ctx.FormatNode(&node.Column)
	ctx.WriteString(" DROP STORED")
}

// SQLRight Code Injection.
func (node *AlterTableDropStored) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataColumnName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Column),
	}
	LNode := tmpNode

	rootIR := &SQLRightIR{
		IRType:   TypeAlterTableDropStored,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: " ALTER COLUMN ",
		Infix:  " DROP STORED",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// AlterTablePartitionByTable represents an ALTER TABLE PARTITION [ALL]
// BY command.
type AlterTablePartitionByTable struct {
	*PartitionByTable
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTablePartitionByTable) TelemetryName() string {
	return "partition_by"
}

// Format implements the NodeFormatter interface.
func (node *AlterTablePartitionByTable) Format(ctx *FmtCtx) {
	ctx.FormatNode(node.PartitionByTable)
}

// SQLRight Code Injection.
func (node *AlterTablePartitionByTable) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.PartitionByTable.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeAlterTablePartitionByTable,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: "",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// AuditMode represents a table audit mode
type AuditMode int

const (
	// AuditModeDisable is the default mode - no audit.
	AuditModeDisable AuditMode = iota
	// AuditModeReadWrite enables audit on read or write statements.
	AuditModeReadWrite
)

var auditModeName = [...]string{
	AuditModeDisable:   "OFF",
	AuditModeReadWrite: "READ WRITE",
}

func (m AuditMode) String() string {
	return auditModeName[m]
}

// TelemetryName returns a friendly string for use in telemetry that represents
// the AuditMode.
func (m AuditMode) TelemetryName() string {
	return strings.ReplaceAll(strings.ToLower(m.String()), " ", "_")
}

// AlterTableSetAudit represents an ALTER TABLE AUDIT SET statement.
type AlterTableSetAudit struct {
	Mode AuditMode
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTableSetAudit) TelemetryName() string {
	return "set_audit"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableSetAudit) Format(ctx *FmtCtx) {
	ctx.WriteString(" EXPERIMENTAL_AUDIT SET ")
	ctx.WriteString(node.Mode.String())
}

// SQLRight Code Injection.
func (node *AlterTableSetAudit) LogCurrentNode(depth int) *SQLRightIR {

	prefix := node.Mode.String()
	LNode := &SQLRightIR{
		IRType:   TypeAuditMode,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	rootIR := &SQLRightIR{
		IRType:   TypeAlterTableSetAudit,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: " EXPERIMENTAL_AUDIT SET ",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// AlterTableInjectStats represents an ALTER TABLE INJECT STATISTICS statement.
type AlterTableInjectStats struct {
	Stats Expr
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTableInjectStats) TelemetryName() string {
	return "inject_stats"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableInjectStats) Format(ctx *FmtCtx) {
	ctx.WriteString(" INJECT STATISTICS ")
	ctx.FormatNode(node.Stats)
}

// SQLRight Code Injection.
func (node *AlterTableInjectStats) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.Stats.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeAlterTableInjectStats,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: " INJECT STATISTICS ",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// AlterTableSetStorageParams represents a ALTER TABLE SET command.
type AlterTableSetStorageParams struct {
	StorageParams StorageParams
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTableSetStorageParams) TelemetryName() string {
	return "set_storage_param"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableSetStorageParams) Format(ctx *FmtCtx) {
	ctx.WriteString(" SET (")
	ctx.FormatNode(&node.StorageParams)
	ctx.WriteString(")")
}

// SQLRight Code Injection.
func (node *AlterTableSetStorageParams) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.StorageParams.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeAlterTableSetStorageParams,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: " SET (",
		Infix:  ")",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// AlterTableResetStorageParams represents a ALTER TABLE RESET command.
type AlterTableResetStorageParams struct {
	Params NameList
}

// TelemetryName implements the AlterTableCmd interface.
func (node *AlterTableResetStorageParams) TelemetryName() string {
	return "set_storage_param"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableResetStorageParams) Format(ctx *FmtCtx) {
	ctx.WriteString(" RESET (")
	ctx.FormatNode(&node.Params)
	ctx.WriteString(")")
}

// SQLRight Code Injection.
func (node *AlterTableResetStorageParams) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.Params.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeAlterTableResetStorageParams,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: " RESET (",
		Infix:  ")",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// AlterTableLocality represents an ALTER TABLE LOCALITY command.
type AlterTableLocality struct {
	Name     *UnresolvedObjectName
	IfExists bool
	Locality *Locality
}

var _ Statement = &AlterTableLocality{}

// Format implements the NodeFormatter interface.
func (node *AlterTableLocality) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER TABLE ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(node.Name)
	ctx.WriteString(" SET ")
	ctx.FormatNode(node.Locality)
}

// SQLRight Code Injection.
func (node *AlterTableLocality) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""
	if node.IfExists {
		prefix = "IF EXISTS "
	}
	LNode := &SQLRightIR{
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	tmpTableStr := node.Name.String()
	tmpRNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataTableName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         tmpTableStr,
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    LNode,    // IF EXISTS
		RNode:    tmpRNode, // name
		Prefix:   "ALTER TABLE ",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	RNode := node.Locality.LogCurrentNode(depth + 1)

	rootIR = &SQLRightIR{
		IRType:   TypeAlterTableLocality,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    RNode,
		Prefix:   "",
		Infix:    " SET ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterTableSetSchema represents an ALTER TABLE SET SCHEMA command.
type AlterTableSetSchema struct {
	Name           *UnresolvedObjectName
	Schema         Name
	IfExists       bool
	IsView         bool
	IsMaterialized bool
	IsSequence     bool
}

// Format implements the NodeFormatter interface.
func (node *AlterTableSetSchema) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER")
	if node.IsView {
		if node.IsMaterialized {
			ctx.WriteString(" MATERIALIZED")
		}
		ctx.WriteString(" VIEW ")
	} else if node.IsSequence {
		ctx.WriteString(" SEQUENCE ")
	} else {
		ctx.WriteString(" TABLE ")
	}
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(node.Name)
	ctx.WriteString(" SET SCHEMA ")
	ctx.FormatNode(&node.Schema)
}

// SQLRight Code Injection.
func (node *AlterTableSetSchema) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ALTER"
	if node.IsView {
		if node.IsMaterialized {
			prefix += " MATERIALIZED"
		}
		prefix += " VIEW "
	} else if node.IsSequence {
		prefix += " SEQUENCE "
	} else {
		prefix += " TABLE "
	}

	tmpStr := ""
	if node.IfExists {
		tmpStr = "IF EXISTS "
	}
	LNode := &SQLRightIR{
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: tmpStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	tmpNameStr := node.Name.String()
	var nameDataType SQLRightDataType
	if node.IsView {
		nameDataType = DataViewName
	} else if node.IsSequence {
		nameDataType = DataSequenceName
	} else {
		nameDataType = DataTableName
	}

	RNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    nameDataType,
		ContextFlag: ContextUnknown,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         tmpNameStr,
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    LNode,  // IF EXISTS
		RNode:    RNode,  // name
		Prefix:   prefix, // ALTER ...
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
		Str:      tmpNameStr,
	}

	RNode = &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataSchemaName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Schema),
	}

	rootIR = &SQLRightIR{
		IRType:   TypeAlterTableSetSchema,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    RNode,
		Prefix:   "",
		Infix:    " SET SCHEMA ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// TelemetryName returns the telemetry counter to increment
// when this command is used.
func (node *AlterTableSetSchema) TelemetryName() string {
	return "set_schema"
}

// AlterTableOwner represents an ALTER TABLE OWNER TO command.
type AlterTableOwner struct {
	Name           *UnresolvedObjectName
	Owner          RoleSpec
	IfExists       bool
	IsView         bool
	IsMaterialized bool
	IsSequence     bool
}

// TelemetryName returns the telemetry counter to increment
// when this command is used.
func (node *AlterTableOwner) TelemetryName() string {
	return "owner_to"
}

// Format implements the NodeFormatter interface.
func (node *AlterTableOwner) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER")
	if node.IsView {
		if node.IsMaterialized {
			ctx.WriteString(" MATERIALIZED")
		}
		ctx.WriteString(" VIEW ")
	} else if node.IsSequence {
		ctx.WriteString(" SEQUENCE ")
	} else {
		ctx.WriteString(" TABLE ")
	}
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(node.Name)
	ctx.WriteString(" OWNER TO ")
	ctx.FormatNode(&node.Owner)
}

// SQLRight Code Injection.
func (node *AlterTableOwner) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ALTER"
	if node.IsView {
		if node.IsMaterialized {
			prefix += " MATERIALIZED"
		}
		prefix += " VIEW "
	} else if node.IsSequence {
		prefix += " SEQUENCE "
	} else {
		prefix += " TABLE "
	}

	tmpStr := ""
	if node.IfExists {
		tmpStr = "IF EXISTS "
	}
	LNode := &SQLRightIR{
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: tmpStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	tmpNameStr := node.Name.String()
	var nameDataType SQLRightDataType
	if node.IsView {
		nameDataType = DataViewName
	} else if node.IsSequence {
		nameDataType = DataSequenceName
	} else {
		nameDataType = DataTableName
	}

	RNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    nameDataType,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         tmpNameStr,
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    LNode,  // IF EXISTS
		RNode:    RNode,  // name
		Prefix:   prefix, // ALTER ...
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
		Str:      tmpNameStr,
	}

	tmpRNode := node.Owner.LogCurrentNode(depth+1, ContextUse)

	rootIR = &SQLRightIR{
		IRType:   TypeAlterTableOwner,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    tmpRNode, // Owner node.
		Prefix:   "",
		Infix:    " OWNER TO ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// GetTableType returns a string representing the type of table the command
// is operating on.
// It is assumed if the table is not a sequence or a view, then it is a
// regular table.
func GetTableType(isSequence bool, isView bool, isMaterialized bool) string {
	tableType := "table"
	if isSequence {
		tableType = "sequence"
	} else if isView {
		if isMaterialized {
			tableType = "materialized_view"
		} else {
			tableType = "view"
		}
	}

	return tableType
}
