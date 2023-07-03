// Copyright 2021 The Cockroach Authors.
//
// Use of this software is governed by the Business Source License
// included in the file licenses/BSL.txt.
//
// As of the Change Date specified in that file, in accordance with
// the Business Source License, use of this software will be governed
// by the Apache License, Version 2.0, included in the file
// licenses/APL.txt.

package tree

// AlterRole represents an `ALTER ROLE ... WITH options` statement.
type AlterRole struct {
	Name      RoleSpec
	IfExists  bool
	IsRole    bool
	KVOptions KVOptions
}

// Format implements the NodeFormatter interface.
func (node *AlterRole) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER")
	if node.IsRole {
		ctx.WriteString(" ROLE ")
	} else {
		ctx.WriteString(" USER ")
	}
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(&node.Name)

	if len(node.KVOptions) > 0 {
		ctx.WriteString(" WITH")
		node.KVOptions.formatAsRoleOptions(ctx)
	}
}

// SQLRight Code Injection.
func (node *AlterRole) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ALTER"
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
		NodeHash: 203076,
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	nameNode := node.Name.LogCurrentNode(depth+1, ContextUse)

	rootIR := &SQLRightIR{
		NodeHash: 58392,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    ifExistsNode,
		RNode:    nameNode,
		Prefix:   "",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	if len(node.KVOptions) > 0 {
		infix := " WITH"
		kvOptionsNode := node.KVOptions.LogCurrentNodeAsRoleOptions(depth + 1)

		rootIR = &SQLRightIR{
			NodeHash: 230911,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    kvOptionsNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeAlterRole

	return rootIR
}

// AlterRoleSet represents an `ALTER ROLE ... SET` statement.
type AlterRoleSet struct {
	RoleName     RoleSpec
	IfExists     bool
	IsRole       bool
	AllRoles     bool
	DatabaseName Name
	SetOrReset   *SetVar
}

// Format implements the NodeFormatter interface.
func (node *AlterRoleSet) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER")
	if node.IsRole {
		ctx.WriteString(" ROLE ")
	} else {
		ctx.WriteString(" USER ")
	}
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	if node.AllRoles {
		ctx.WriteString("ALL ")
	} else {
		ctx.FormatNode(&node.RoleName)
		ctx.WriteString(" ")
	}
	if node.DatabaseName != "" {
		ctx.WriteString("IN DATABASE ")
		ctx.FormatNode(&node.DatabaseName)
		ctx.WriteString(" ")
	}
	ctx.FormatNode(node.SetOrReset)
}

// SQLRight Code Injection.
func (node *AlterRoleSet) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ALTER "

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
		NodeHash: 105581,
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		Prefix:   optIfExistStr,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	var roleNameNode *SQLRightIR
	if node.AllRoles {
		tmpRoleNameNode := &SQLRightIR{
			NodeHash:    44344,
			IRType:      TypeIdentifier,
			DataType:    DataRoleName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         "ALL",
		}
		roleNameNode = tmpRoleNameNode
	} else {
		roleNameNode = node.RoleName.LogCurrentNode(depth+1, ContextUse)
	}

	rootIR := &SQLRightIR{
		NodeHash: 1980,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    ifExistsNode,
		RNode:    roleNameNode,
		Prefix:   prefix,
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	if node.DatabaseName != "" {
		infix := "IN DATABASE "
		databaseName := node.DatabaseName.String()

		databaseNameNode := &SQLRightIR{
			NodeHash:    159587,
			IRType:      TypeIdentifier,
			DataType:    DataDatabaseName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         databaseName,
		}

		rootIR = &SQLRightIR{
			NodeHash: 1155,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    databaseNameNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	setOrResetNode := node.SetOrReset.LogCurrentNode(depth + 1)

	rootIR = &SQLRightIR{
		NodeHash: 171150,
		IRType:   TypeAlterRoleSet,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    setOrResetNode,
		Prefix:   "",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}
