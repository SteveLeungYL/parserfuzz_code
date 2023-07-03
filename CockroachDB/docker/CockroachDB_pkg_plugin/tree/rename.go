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

// RenameDatabase represents a RENAME DATABASE statement.
type RenameDatabase struct {
	Name    Name
	NewName Name
}

// Format implements the NodeFormatter interface.
func (node *RenameDatabase) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER DATABASE ")
	ctx.FormatNode(&node.Name)
	ctx.WriteString(" RENAME TO ")
	ctx.FormatNode(&node.NewName)
}

// SQLRight Code Injection.
func (node *RenameDatabase) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ALTER DATABASE "

	nameNode := &SQLRightIR{
		NodeHash:    221442,
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextReplaceUndefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Name.String(),
	}

	infix := " RENAME TO "

	newNameNode := &SQLRightIR{
		NodeHash:    102124,
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextReplaceDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.NewName.String(),
	}

	rootIR := &SQLRightIR{
		NodeHash: 204834,
		IRType:   TypeRenameDatabase,
		DataType: DataNone,
		LNode:    nameNode,
		RNode:    newNameNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ReparentDatabase represents a database reparenting as a schema operation.
type ReparentDatabase struct {
	Name   Name
	Parent Name
}

// Format implements the NodeFormatter interface.
func (node *ReparentDatabase) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER DATABASE ")
	ctx.FormatNode(&node.Name)
	ctx.WriteString(" CONVERT TO SCHEMA WITH PARENT ")
	ctx.FormatNode(&node.Parent)
}

// SQLRight Code Injection.
func (node *ReparentDatabase) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ALTER DATABASE "

	nameNode := &SQLRightIR{
		NodeHash:    38591,
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Name.String(),
	}

	infix := " CONVERT TO SCHEMA WITH PARENT "

	newNameNode := &SQLRightIR{
		NodeHash:    87985,
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Parent.String(),
	}

	rootIR := &SQLRightIR{
		NodeHash: 119808,
		IRType:   TypeReparentDatabase,
		DataType: DataNone,
		LNode:    nameNode,
		RNode:    newNameNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// RenameTable represents a RENAME TABLE or RENAME VIEW or RENAME SEQUENCE
// statement. Whether the user has asked to rename a view or a sequence
// is indicated by the IsView and IsSequence fields.
type RenameTable struct {
	Name           *UnresolvedObjectName
	NewName        *UnresolvedObjectName
	IfExists       bool
	IsView         bool
	IsMaterialized bool
	IsSequence     bool
}

// Format implements the NodeFormatter interface.
func (node *RenameTable) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER ")
	if node.IsView {
		if node.IsMaterialized {
			ctx.WriteString("MATERIALIZED ")
		}
		ctx.WriteString("VIEW ")
	} else if node.IsSequence {
		ctx.WriteString("SEQUENCE ")
	} else {
		ctx.WriteString("TABLE ")
	}
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(node.Name)
	ctx.WriteString(" RENAME TO ")
	ctx.FormatNode(node.NewName)
}

// SQLRight Code Injection.
func (node *RenameTable) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ALTER "

	var dataType SQLRightDataType
	if node.IsView {
		if node.IsMaterialized {
			prefix += "MATERIALIZED "
		}
		prefix += "VIEW "
		dataType = DataViewName
	} else if node.IsSequence {
		prefix += "SEQUENCE "
		dataType = DataSequenceName
	} else {
		prefix += "TABLE "
		dataType = DataTableName
	}

	optIfExistStr := ""
	if node.IfExists {
		optIfExistStr = "IF EXISTS "
	}
	ifExistsNode := &SQLRightIR{
		NodeHash: 141806,
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		Prefix:   optIfExistStr,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	nameNode := &SQLRightIR{
		NodeHash:    105647,
		IRType:      TypeIdentifier,
		DataType:    dataType,
		ContextFlag: ContextReplaceUndefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Name.String(),
	}

	rootIR := &SQLRightIR{
		NodeHash: 96785,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    ifExistsNode,
		RNode:    nameNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	newNameNode := &SQLRightIR{
		NodeHash:    253239,
		IRType:      TypeIdentifier,
		DataType:    dataType,
		ContextFlag: ContextReplaceDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.NewName.String(),
	}

	rootIR = &SQLRightIR{
		NodeHash: 179535,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    newNameNode,
		Prefix:   "",
		Infix:    " RENAME TO ",
		Suffix:   "",
		Depth:    depth,
	}

	rootIR.IRType = TypeRenameTable

	return rootIR
}

// RenameIndex represents a RENAME INDEX statement.
type RenameIndex struct {
	Index    *TableIndexName
	NewName  UnrestrictedName
	IfExists bool
}

// Format implements the NodeFormatter interface.
func (node *RenameIndex) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER INDEX ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(node.Index)
	ctx.WriteString(" RENAME TO ")
	ctx.FormatNode(&node.NewName)
}

// SQLRight Code Injection.
func (node *RenameIndex) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ALTER INDEX "

	optIfExistStr := ""
	if node.IfExists {
		optIfExistStr = "IF EXISTS "
	}
	ifExistsNode := &SQLRightIR{
		NodeHash: 221349,
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	indexNameNode := &SQLRightIR{
		NodeHash:    235005,
		IRType:      TypeIdentifier,
		DataType:    DataIndexName,
		ContextFlag: ContextReplaceUndefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Index.String(),
	}

	rootIR := &SQLRightIR{
		NodeHash: 258172,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    ifExistsNode,
		RNode:    indexNameNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	infix := " RENAME TO "

	newNameNode := &SQLRightIR{
		NodeHash:    218372,
		IRType:      TypeIdentifier,
		DataType:    DataIndexName,
		ContextFlag: ContextReplaceDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.NewName.String(),
	}

	rootIR = &SQLRightIR{
		NodeHash: 77283,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    newNameNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	rootIR.IRType = TypeRenameIndex

	return rootIR
}

// RenameColumn represents a RENAME COLUMN statement.
type RenameColumn struct {
	Table   TableName
	Name    Name
	NewName Name
	// IfExists refers to the table, not the column.
	IfExists bool
}

// Format implements the NodeFormatter interface.
func (node *RenameColumn) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER TABLE ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(&node.Table)
	ctx.WriteString(" RENAME COLUMN ")
	ctx.FormatNode(&node.Name)
	ctx.WriteString(" TO ")
	ctx.FormatNode(&node.NewName)
}

// SQLRight Code Injection.
func (node *RenameColumn) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ALTER TABLE "

	optIfExistStr := ""
	if node.IfExists {
		optIfExistStr = "IF EXISTS "
	}
	ifExistsNode := &SQLRightIR{
		NodeHash: 184161,
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	tableNameNode := node.Table.LogCurrentNodeWithType(depth+1, DataTableName, ContextUse)

	rootIR := &SQLRightIR{
		NodeHash: 188791,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    ifExistsNode,
		RNode:    tableNameNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	infix := " RENAME COLUMN "

	columnName := &SQLRightIR{
		NodeHash:    69122,
		IRType:      TypeIdentifier,
		DataType:    DataColumnName,
		ContextFlag: ContextReplaceUndefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Name.String(),
	}

	rootIR = &SQLRightIR{
		NodeHash: 98634,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    columnName,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	newColumnName := &SQLRightIR{
		NodeHash:    133406,
		IRType:      TypeIdentifier,
		DataType:    DataIndexName,
		ContextFlag: ContextReplaceDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.NewName.String(),
	}

	rootIR = &SQLRightIR{
		NodeHash: 259409,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    newColumnName,
		Prefix:   "",
		Infix:    " TO ",
		Suffix:   "",
		Depth:    depth,
	}

	rootIR.IRType = TypeRenameColumn
	return rootIR
}
