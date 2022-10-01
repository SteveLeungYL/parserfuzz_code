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

// AlterSchema represents an ALTER SCHEMA statement.
type AlterSchema struct {
	Schema ObjectNamePrefix
	Cmd    AlterSchemaCmd
}

var _ Statement = &AlterSchema{}

// Format implements the NodeFormatter interface.
func (node *AlterSchema) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER SCHEMA ")
	ctx.FormatNode(&node.Schema)
	ctx.FormatNode(node.Cmd)
}

// SQLRight Code Injection.
func (node *AlterSchema) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.Schema.LogCurrentNode(depth + 1)
	RNode := node.Cmd.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeAlterSchema,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "ALTER SCHEMA ",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterSchemaCmd represents a schema modification operation.
type AlterSchemaCmd interface {
	NodeFormatter
	alterSchemaCmd()
	SQLRightInterface
}

func (*AlterSchemaRename) alterSchemaCmd() {}

// AlterSchemaRename represents an ALTER SCHEMA RENAME command.
type AlterSchemaRename struct {
	NewName Name
}

// Format implements the NodeFormatter interface.
func (node *AlterSchemaRename) Format(ctx *FmtCtx) {
	ctx.WriteString(" RENAME TO ")
	ctx.FormatNode(&node.NewName)
}

// SQLRight Code Injection.
func (node *AlterSchemaRename) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataSchemaName,
		ContextFlag: ContextDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.NewName),
	}
	LNode := tmpNode

	rootIR := &SQLRightIR{
		IRType:   TypeAlterSchemaRename,
		DataType: DataNone,
		LNode:    LNode,
		Prefix:   " RENAME TO ",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

func (*AlterSchemaOwner) alterSchemaCmd() {}

// AlterSchemaOwner represents an ALTER SCHEMA OWNER TO command.
type AlterSchemaOwner struct {
	Owner RoleSpec
}

// Format implements the NodeFormatter interface.
func (node *AlterSchemaOwner) Format(ctx *FmtCtx) {
	ctx.WriteString(" OWNER TO ")
	ctx.FormatNode(&node.Owner)
}

// SQLRight Code Injection.
func (node *AlterSchemaOwner) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.Owner.LogCurrentNode(depth+1, ContextUse)

	rootIR := &SQLRightIR{
		IRType:   TypeAlterSchemaOwner,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: " OWNER TO ",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}
