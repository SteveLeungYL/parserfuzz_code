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

// DropBehavior represents options for dropping schema elements.
type DropBehavior int

// DropBehavior values.
const (
	DropDefault DropBehavior = iota
	DropRestrict
	DropCascade
)

var dropBehaviorName = [...]string{
	DropDefault:  "",
	DropRestrict: "RESTRICT",
	DropCascade:  "CASCADE",
}

func (d DropBehavior) String() string {
	return dropBehaviorName[d]
}

// DropDatabase represents a DROP DATABASE statement.
type DropDatabase struct {
	Name         Name
	IfExists     bool
	DropBehavior DropBehavior
}

// Format implements the NodeFormatter interface.
func (node *DropDatabase) Format(ctx *FmtCtx) {
	ctx.WriteString("DROP DATABASE ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(&node.Name)
	if node.DropBehavior != DropDefault {
		ctx.WriteByte(' ')
		ctx.WriteString(node.DropBehavior.String())
	}
}

// SQLRight Code Injection.
func (node *DropDatabase) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "DROP DATABASE"

	optIfExistStr := ""
	if node.IfExists {
		optIfExistStr = "IF EXISTS "
	}
	ifExistsNode := &SQLRightIR{
		NodeHash: 207240,
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		Prefix:   optIfExistStr,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	nameNode := &SQLRightIR{
		NodeHash:    82090,
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextUndefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Name.String(),
	}

	rootIR := &SQLRightIR{
		NodeHash: 253688,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    ifExistsNode,
		RNode:    nameNode,
		Prefix:   prefix,
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	if node.DropBehavior != DropDefault {

		dropBehaviorNode := &SQLRightIR{
			NodeHash: 32873,
			IRType:   TypeDropBehavior,
			DataType: DataNone,
			Prefix:   node.DropBehavior.String(),
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		rootIR = &SQLRightIR{
			NodeHash: 79649,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    dropBehaviorNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.NodeHash = 119369
	rootIR.IRType = TypeDropDatabase

	return rootIR
}

// DropIndex represents a DROP INDEX statement.
type DropIndex struct {
	IndexList    TableIndexNames
	IfExists     bool
	DropBehavior DropBehavior
	Concurrently bool
}

// Format implements the NodeFormatter interface.
func (node *DropIndex) Format(ctx *FmtCtx) {
	ctx.WriteString("DROP INDEX ")
	if node.Concurrently {
		ctx.WriteString("CONCURRENTLY ")
	}
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(&node.IndexList)
	if node.DropBehavior != DropDefault {
		ctx.WriteByte(' ')
		ctx.WriteString(node.DropBehavior.String())
	}
}

// SQLRight Code Injection.
func (node *DropIndex) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "DROP INDEX "

	optConcurrStr := ""
	if node.Concurrently {
		optConcurrStr = "CONCURRENTLY "
	}

	optConcurrNode := &SQLRightIR{
		NodeHash: 26853,
		IRType:   TypeOptConcurrently,
		DataType: DataNone,
		Prefix:   optConcurrStr,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	optIfExistStr := ""
	if node.IfExists {
		optIfExistStr = "IF EXISTS "
	}
	ifExistsNode := &SQLRightIR{
		NodeHash: 217450,
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	rootIR := &SQLRightIR{
		NodeHash: 123540,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    optConcurrNode,
		RNode:    ifExistsNode,
		Prefix:   prefix,
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	indexList := node.IndexList.LogCurrentNodeWithType(depth+1, DataIndexName, ContextUndefine)
	rootIR = &SQLRightIR{
		NodeHash: 62322,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    indexList,
		Prefix:   "",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	if node.DropBehavior != DropDefault {

		dropBehaviorNode := &SQLRightIR{
			NodeHash: 207760,
			IRType:   TypeDropBehavior,
			DataType: DataNone,
			Prefix:   node.DropBehavior.String(),
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		rootIR = &SQLRightIR{
			NodeHash: 110334,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    dropBehaviorNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.NodeHash = 118136
	rootIR.IRType = TypeDropIndex

	return rootIR
}

// DropTable represents a DROP TABLE statement.
type DropTable struct {
	Names        TableNames
	IfExists     bool
	DropBehavior DropBehavior
}

// Format implements the NodeFormatter interface.
func (node *DropTable) Format(ctx *FmtCtx) {
	ctx.WriteString("DROP TABLE ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(&node.Names)
	if node.DropBehavior != DropDefault {
		ctx.WriteByte(' ')
		ctx.WriteString(node.DropBehavior.String())
	}
}

// SQLRight Code Injection.
func (node *DropTable) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "DROP TABLE "

	optIfExistStr := ""
	if node.IfExists {
		optIfExistStr = "IF EXISTS "
	}
	ifExistsNode := &SQLRightIR{
		NodeHash: 45099,
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	nameNode := node.Names.LogCurrentNodeWithType(depth+1, DataTableName, ContextUndefine)

	rootIR := &SQLRightIR{
		NodeHash: 89394,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    ifExistsNode,
		RNode:    nameNode,
		Prefix:   prefix,
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	if node.DropBehavior != DropDefault {

		dropBehaviorNode := &SQLRightIR{
			NodeHash: 8991,
			IRType:   TypeDropBehavior,
			DataType: DataNone,
			Prefix:   node.DropBehavior.String(),
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		rootIR = &SQLRightIR{
			NodeHash: 242900,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    dropBehaviorNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.NodeHash = 12909
	rootIR.IRType = TypeDropTable

	return rootIR
}

// DropView represents a DROP VIEW statement.
type DropView struct {
	Names          TableNames
	IfExists       bool
	DropBehavior   DropBehavior
	IsMaterialized bool
}

// Format implements the NodeFormatter interface.
func (node *DropView) Format(ctx *FmtCtx) {
	ctx.WriteString("DROP ")
	if node.IsMaterialized {
		ctx.WriteString("MATERIALIZED ")
	}
	ctx.WriteString("VIEW ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(&node.Names)
	if node.DropBehavior != DropDefault {
		ctx.WriteByte(' ')
		ctx.WriteString(node.DropBehavior.String())
	}
}

// SQLRight Code Injection.
func (node *DropView) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "DROP "

	if node.IsMaterialized {
		prefix += "MATERIALIZED "
	}

	prefix += "VIEW "

	optIfExistStr := ""
	if node.IfExists {
		optIfExistStr = "IF EXISTS "
	}
	ifExistsNode := &SQLRightIR{
		NodeHash: 85027,
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	nameNode := node.Names.LogCurrentNodeWithType(depth+1, DataViewName, ContextUndefine)

	rootIR := &SQLRightIR{
		NodeHash: 86137,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    ifExistsNode,
		RNode:    nameNode,
		Prefix:   prefix,
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	if node.DropBehavior != DropDefault {

		dropBehaviorNode := &SQLRightIR{
			NodeHash: 232313,
			IRType:   TypeDropBehavior,
			DataType: DataNone,
			Prefix:   node.DropBehavior.String(),
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		rootIR = &SQLRightIR{
			NodeHash: 11146,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    dropBehaviorNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.NodeHash = 243730
	rootIR.IRType = TypeDropView

	return rootIR
}

// DropSequence represents a DROP SEQUENCE statement.
type DropSequence struct {
	Names        TableNames
	IfExists     bool
	DropBehavior DropBehavior
}

// Format implements the NodeFormatter interface.
func (node *DropSequence) Format(ctx *FmtCtx) {
	ctx.WriteString("DROP SEQUENCE ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(&node.Names)
	if node.DropBehavior != DropDefault {
		ctx.WriteByte(' ')
		ctx.WriteString(node.DropBehavior.String())
	}
}

// SQLRight Code Injection.
func (node *DropSequence) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "DROP SEQUENCE "

	optIfExistStr := ""
	if node.IfExists {
		optIfExistStr = "IF EXISTS "
	}
	ifExistsNode := &SQLRightIR{
		NodeHash: 190209,
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	nameNode := node.Names.LogCurrentNodeWithType(depth+1, DataSequenceName, ContextUndefine)

	rootIR := &SQLRightIR{
		NodeHash: 202722,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    ifExistsNode,
		RNode:    nameNode,
		Prefix:   prefix,
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	if node.DropBehavior != DropDefault {

		dropBehaviorNode := &SQLRightIR{
			NodeHash: 14907,
			IRType:   TypeDropBehavior,
			DataType: DataNone,
			Prefix:   node.DropBehavior.String(),
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		rootIR = &SQLRightIR{
			NodeHash: 124784,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    dropBehaviorNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.NodeHash = 28542
	rootIR.IRType = TypeDropSequence

	return rootIR
}

// DropRole represents a DROP ROLE statement
type DropRole struct {
	Names    RoleSpecList
	IsRole   bool
	IfExists bool
}

// Format implements the NodeFormatter interface.
func (node *DropRole) Format(ctx *FmtCtx) {
	ctx.WriteString("DROP")
	if node.IsRole {
		ctx.WriteString(" ROLE ")
	} else {
		ctx.WriteString(" USER ")
	}
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(&node.Names)
}

// SQLRight Code Injection.
func (node *DropRole) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "DROP"
	if node.IsRole {
		prefix += " ROLE "
	} else {
		prefix += " USER "
	}

	optIfExistStr := ""
	if node.IfExists {
		optIfExistStr = "IF EXISTS "
	}
	ifExistsNode := &SQLRightIR{
		NodeHash: 24211,
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	nameNode := node.Names.LogCurrentNode(depth+1, ContextUndefine)

	rootIR := &SQLRightIR{
		NodeHash: 38253,
		IRType:   TypeDropRole,
		DataType: DataNone,
		LNode:    ifExistsNode,
		RNode:    nameNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// DropType represents a DROP TYPE command.
type DropType struct {
	Names        []*UnresolvedObjectName
	IfExists     bool
	DropBehavior DropBehavior
}

var _ Statement = &DropType{}

// Format implements the NodeFormatter interface.
func (node *DropType) Format(ctx *FmtCtx) {
	ctx.WriteString("DROP TYPE ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	for i := range node.Names {
		if i > 0 {
			ctx.WriteString(", ")
		}
		ctx.FormatNode(node.Names[i])
	}
	if node.DropBehavior != DropDefault {
		ctx.WriteByte(' ')
		ctx.WriteString(node.DropBehavior.String())
	}
}

// SQLRight Code Injection.
func (node *DropType) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "DROP TYPE "

	optIfExistStr := ""
	if node.IfExists {
		optIfExistStr = "IF EXISTS "
	}
	ifExistsNode := &SQLRightIR{
		NodeHash: 136105,
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	var nameListNode []*SQLRightIR
	var nameList *SQLRightIR
	for i := range node.Names {
		nameNodeStr := node.Names[i].String()
		nameNode := &SQLRightIR{
			NodeHash:    183215,
			IRType:      TypeIdentifier,
			DataType:    DataTypeName,
			ContextFlag: ContextUndefine,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         nameNodeStr,
		}
		nameListNode = append(nameListNode, nameNode)
	}

	for i, n := range nameListNode {
		if i == 0 {
			// Take care of the first two nodes.
			LNode := n
			var RNode *SQLRightIR
			tmpInfix := ""
			if len(nameListNode) >= 2 {
				RNode = (nameListNode)[1]
				tmpInfix = ", "
			}
			nameList = &SQLRightIR{
				NodeHash: 125732,
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   "",
				Infix:    tmpInfix,
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
			LNode := nameList
			RNode := n

			nameList = &SQLRightIR{
				NodeHash: 203609,
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

	rootIR := &SQLRightIR{
		NodeHash: 197655,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    ifExistsNode,
		RNode:    nameList,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if node.DropBehavior != DropDefault {

		dropBehaviorNode := &SQLRightIR{
			NodeHash: 248005,
			IRType:   TypeDropBehavior,
			DataType: DataNone,
			Prefix:   node.DropBehavior.String(),
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		rootIR = &SQLRightIR{
			NodeHash: 20435,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    dropBehaviorNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.NodeHash = 105617
	rootIR.IRType = TypeDropType

	return rootIR
}

// DropSchema represents a DROP SCHEMA command.
type DropSchema struct {
	Names        ObjectNamePrefixList
	IfExists     bool
	DropBehavior DropBehavior
}

var _ Statement = &DropSchema{}

// Format implements the NodeFormatter interface.
func (node *DropSchema) Format(ctx *FmtCtx) {
	ctx.WriteString("DROP SCHEMA ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(&node.Names)
	if node.DropBehavior != DropDefault {
		ctx.WriteString(" ")
		ctx.WriteString(node.DropBehavior.String())
	}
}

// SQLRight Code Injection.
func (node *DropSchema) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "DROP SCHEMA "

	optIfExistStr := ""
	if node.IfExists {
		optIfExistStr = "IF EXISTS "
	}
	ifExistsNode := &SQLRightIR{
		NodeHash: 49410,
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	nameNode := node.Names.LogCurrentNodeWithType(depth+1, DataSchemaName, ContextUndefine)

	rootIR := &SQLRightIR{
		NodeHash: 173017,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    ifExistsNode,
		RNode:    nameNode,
		Prefix:   prefix,
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	if node.DropBehavior != DropDefault {

		dropBehaviorNode := &SQLRightIR{
			NodeHash: 52648,
			IRType:   TypeDropBehavior,
			DataType: DataNone,
			Prefix:   node.DropBehavior.String(),
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		rootIR = &SQLRightIR{
			NodeHash: 72144,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    dropBehaviorNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.NodeHash = 131262
	rootIR.IRType = TypeDropSchema

	return rootIR
}

// DropExternalConnection represents a DROP EXTERNAL CONNECTION statement.
type DropExternalConnection struct {
	ConnectionLabel Expr
}

var _ Statement = &DropExternalConnection{}

// Format implements the Statement interface.
func (node *DropExternalConnection) Format(ctx *FmtCtx) {
	ctx.WriteString("DROP EXTERNAL CONNECTION")

	if node.ConnectionLabel != nil {
		ctx.WriteString(" ")
		ctx.FormatNode(node.ConnectionLabel)
	}
}

// SQLRight Code Injection.
func (node *DropExternalConnection) LogCurrentNode(depth int) *SQLRightIR {

	// TODO: FIXME: Does not handle the the connection label correctly.
	// Should marked as ContextUndefine.

	prefix := "DROP EXTERNAL CONNECTION"

	var connectionNode *SQLRightIR
	infix := ""
	if node.ConnectionLabel != nil {
		infix = " "
		connectionNode = node.ConnectionLabel.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		NodeHash: 203036,
		IRType:   TypeDropExternalConnection,
		DataType: DataNone,
		LNode:    connectionNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}
