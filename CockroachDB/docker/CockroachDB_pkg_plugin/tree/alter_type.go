// Copyright 2020 The Cockroach Authors.
//
// Use of this software is governed by the Business Source License
// included in the file licenses/BSL.txt.
//
// As of the Change Date specified in that file, in accordance with
// the Business Source License, use of this software will be governed
// by the Apache License, Version 2.0, included in the file
// licenses/APL.txt.

package tree

// AlterType represents an ALTER TYPE statement.
type AlterType struct {
	Type *UnresolvedObjectName
	Cmd  AlterTypeCmd
}

// Format implements the NodeFormatter interface.
func (node *AlterType) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER TYPE ")
	ctx.FormatNode(node.Type)
	ctx.FormatNode(node.Cmd)
}

// SQLRight Code Injection.
func (node *AlterType) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ALTER TYPE "

	typeStr := node.Type.String()
	typeNode := &SQLRightIR{
		NodeHash:    129603,
		IRType:      TypeIdentifier,
		DataType:    DataTypeName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         typeStr,
	}

	cmdNode := node.Cmd.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		NodeHash: 184733,
		IRType:   TypeAlterType,
		DataType: DataNone,
		LNode:    typeNode,
		RNode:    cmdNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterTypeCmd represents a type modification operation.
type AlterTypeCmd interface {
	NodeFormatter
	alterTypeCmd()
	// TelemetryName returns the counter name to use for telemetry purposes.
	TelemetryName() string
	SQLRightInterface
}

func (*AlterTypeAddValue) alterTypeCmd()    {}
func (*AlterTypeRenameValue) alterTypeCmd() {}
func (*AlterTypeRename) alterTypeCmd()      {}
func (*AlterTypeSetSchema) alterTypeCmd()   {}
func (*AlterTypeOwner) alterTypeCmd()       {}
func (*AlterTypeDropValue) alterTypeCmd()   {}

var _ AlterTypeCmd = &AlterTypeAddValue{}
var _ AlterTypeCmd = &AlterTypeRenameValue{}
var _ AlterTypeCmd = &AlterTypeRename{}
var _ AlterTypeCmd = &AlterTypeSetSchema{}
var _ AlterTypeCmd = &AlterTypeOwner{}
var _ AlterTypeCmd = &AlterTypeDropValue{}

// AlterTypeAddValue represents an ALTER TYPE ADD VALUE command.
type AlterTypeAddValue struct {
	NewVal      EnumValue
	IfNotExists bool
	Placement   *AlterTypeAddValuePlacement
}

// Format implements the NodeFormatter interface.
func (node *AlterTypeAddValue) Format(ctx *FmtCtx) {
	ctx.WriteString(" ADD VALUE ")
	if node.IfNotExists {
		ctx.WriteString("IF NOT EXISTS ")
	}
	ctx.FormatNode(&node.NewVal)
	if node.Placement != nil {
		if node.Placement.Before {
			ctx.WriteString(" BEFORE ")
		} else {
			ctx.WriteString(" AFTER ")
		}
		ctx.FormatNode(&node.Placement.ExistingVal)
	}
}

// SQLRight Code Injection.
func (node *AlterTypeAddValue) LogCurrentNode(depth int) *SQLRightIR {

	prefix := " ADD VALUE "

	optIfNotExistStr := ""
	if node.IfNotExists {
		optIfNotExistStr = "IF NOT EXISTS "
	}
	ifNotExistsNode := &SQLRightIR{
		NodeHash: 95424,
		IRType:   TypeOptIfNotExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfNotExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	newValNode := node.NewVal.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		NodeHash: 46000,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    ifNotExistsNode,
		RNode:    newValNode,
		Prefix:   prefix,
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	if node.Placement != nil {
		infix := ""
		if node.Placement.Before {
			infix = " BEFORE "
		} else {
			infix = " AFTER "
		}
		existingValNode := node.Placement.ExistingVal.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			NodeHash: 198395,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    existingValNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeAlterTypeAddValue

	return rootIR
}

// TelemetryName implements the AlterTypeCmd interface.
func (node *AlterTypeAddValue) TelemetryName() string {
	return "add_value"
}

// AlterTypeAddValuePlacement represents the placement clause for an ALTER
// TYPE ADD VALUE command ([BEFORE | AFTER] value).
type AlterTypeAddValuePlacement struct {
	Before      bool
	ExistingVal EnumValue
}

// AlterTypeRenameValue represents an ALTER TYPE RENAME VALUE command.
type AlterTypeRenameValue struct {
	OldVal EnumValue
	NewVal EnumValue
}

// Format implements the NodeFormatter interface.
func (node *AlterTypeRenameValue) Format(ctx *FmtCtx) {
	ctx.WriteString(" RENAME VALUE ")
	ctx.FormatNode(&node.OldVal)
	ctx.WriteString(" TO ")
	ctx.FormatNode(&node.NewVal)
}

// SQLRight Code Injection.
func (node *AlterTypeRenameValue) LogCurrentNode(depth int) *SQLRightIR {

	prefix := " RENAME VALUE "

	oldValNode := node.OldVal.LogCurrentNode(depth + 1)
	newValNode := node.NewVal.LogCurrentNode(depth + 1)

	infix := "TO "

	rootIR := &SQLRightIR{
		NodeHash: 171898,
		IRType:   TypeAlterTypeRenameValue,
		DataType: DataNone,
		LNode:    oldValNode,
		RNode:    newValNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// TelemetryName implements the AlterTypeCmd interface.
func (node *AlterTypeRenameValue) TelemetryName() string {
	return "rename_value"
}

// AlterTypeDropValue represents an ALTER TYPE DROP VALUE command.
type AlterTypeDropValue struct {
	Val EnumValue
}

// Format implements the NodeFormatter interface.
func (node *AlterTypeDropValue) Format(ctx *FmtCtx) {
	ctx.WriteString(" DROP VALUE ")
	ctx.FormatNode(&node.Val)
}

// SQLRight Code Injection.
func (node *AlterTypeDropValue) LogCurrentNode(depth int) *SQLRightIR {

	prefix := " DROP VALUE "
	valNode := node.Val.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		NodeHash: 201064,
		IRType:   TypeAlterTypeDropValue,
		DataType: DataNone,
		LNode:    valNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// TelemetryName implements the AlterTypeCmd interface.
func (node *AlterTypeDropValue) TelemetryName() string {
	return "drop_value"
}

// AlterTypeRename represents an ALTER TYPE RENAME command.
type AlterTypeRename struct {
	NewName Name
}

// Format implements the NodeFormatter interface.
func (node *AlterTypeRename) Format(ctx *FmtCtx) {
	ctx.WriteString(" RENAME TO ")
	ctx.FormatNode(&node.NewName)
}

// SQLRight Code Injection.
func (node *AlterTypeRename) LogCurrentNode(depth int) *SQLRightIR {

	prefix := " RENAME TO "
	newNameStr := node.NewName.String()
	newnameNode := &SQLRightIR{
		NodeHash:    176106,
		IRType:      TypeIdentifier,
		DataType:    DataTypeName,
		ContextFlag: ContextReplaceDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         newNameStr,
	}

	rootIR := &SQLRightIR{
		NodeHash: 210686,
		IRType:   TypeAlterTypeRename,
		DataType: DataNone,
		LNode:    newnameNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// TelemetryName implements the AlterTypeCmd interface.
func (node *AlterTypeRename) TelemetryName() string {
	return "rename"
}

// AlterTypeSetSchema represents an ALTER TYPE SET SCHEMA command.
type AlterTypeSetSchema struct {
	Schema Name
}

// Format implements the NodeFormatter interface.
func (node *AlterTypeSetSchema) Format(ctx *FmtCtx) {
	ctx.WriteString(" SET SCHEMA ")
	ctx.FormatNode(&node.Schema)
}

// SQLRight Code Injection.
func (node *AlterTypeSetSchema) LogCurrentNode(depth int) *SQLRightIR {

	prefix := " SET SCHEMA "
	schemaNameStr := node.Schema.String()
	schemaNameNode := &SQLRightIR{
		NodeHash:    55090,
		IRType:      TypeIdentifier,
		DataType:    DataSchemaName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         schemaNameStr,
	}

	rootIR := &SQLRightIR{
		NodeHash: 203042,
		IRType:   TypeAlterTypeSetSchema,
		DataType: DataNone,
		LNode:    schemaNameNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// TelemetryName implements the AlterTypeCmd interface.
func (node *AlterTypeSetSchema) TelemetryName() string {
	return "set_schema"
}

// AlterTypeOwner represents an ALTER TYPE OWNER TO command.
type AlterTypeOwner struct {
	Owner RoleSpec
}

// Format implements the NodeFormatter interface.
func (node *AlterTypeOwner) Format(ctx *FmtCtx) {
	ctx.WriteString(" OWNER TO ")
	ctx.FormatNode(&node.Owner)
}

// SQLRight Code Injection.
func (node *AlterTypeOwner) LogCurrentNode(depth int) *SQLRightIR {

	prefix := " OWNER TO "
	newnameNode := node.Owner.LogCurrentNode(depth+1, ContextUse)

	rootIR := &SQLRightIR{
		NodeHash: 6408,
		IRType:   TypeAlterTypeOwner,
		DataType: DataNone,
		LNode:    newnameNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// TelemetryName implements the AlterTypeCmd interface.
func (node *AlterTypeOwner) TelemetryName() string {
	return "owner"
}
