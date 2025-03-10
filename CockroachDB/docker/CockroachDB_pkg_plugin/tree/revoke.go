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

import "github.com/cockroachdb/cockroach/pkg/sql/privilege"

// Revoke represents a REVOKE statement.
// PrivilegeList and TargetList are defined in grant.go
type Revoke struct {
	Privileges     privilege.List
	Targets        GrantTargetList
	Grantees       RoleSpecList
	GrantOptionFor bool
}

// Format implements the NodeFormatter interface.
func (node *Revoke) Format(ctx *FmtCtx) {
	ctx.WriteString("REVOKE ")
	if node.Targets.System {
		ctx.WriteString(" SYSTEM ")
	}
	// NB: we cannot use FormatNode() here because node.Privileges is
	// not an AST node. This is OK, because a privilege list cannot
	// contain sensitive information.
	node.Privileges.Format(&ctx.Buffer)
	if !node.Targets.System {
		ctx.WriteString(" ON ")
		ctx.FormatNode(&node.Targets)
	}
	ctx.WriteString(" FROM ")
	ctx.FormatNode(&node.Grantees)
}

// SQLRight Code Injection.
func (node *Revoke) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "REVOKE "
	if node.Targets.System {
		prefix += " SYSTEM "
	}

	privilegeNode := &SQLRightIR{
		NodeHash: 115454,
		IRType:   TypePrivilege,
		DataType: DataNone,
		Prefix:   node.Privileges.String(),
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	var targetNode *SQLRightIR
	infix := ""
	if !node.Targets.System {
		infix = " ON "
		targetNode = node.Targets.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		NodeHash: 84149,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    privilegeNode,
		RNode:    targetNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	infix = " FROM "
	grantNode := node.Grantees.LogCurrentNode(depth+1, ContextUse)

	rootIR = &SQLRightIR{
		NodeHash: 106675,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    grantNode,
		Prefix:   "",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	rootIR.NodeHash = 214427
	rootIR.IRType = TypeRevoke

	return rootIR
}

// RevokeRole represents a REVOKE <role> statement.
type RevokeRole struct {
	Roles       NameList
	Members     RoleSpecList
	AdminOption bool
}

// Format implements the NodeFormatter interface.
func (node *RevokeRole) Format(ctx *FmtCtx) {
	ctx.WriteString("REVOKE ")
	if node.AdminOption {
		ctx.WriteString("ADMIN OPTION FOR ")
	}
	ctx.FormatNode(&node.Roles)
	ctx.WriteString(" FROM ")
	ctx.FormatNode(&node.Members)
}

// SQLRight Code Injection.
func (node *RevokeRole) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "REVOKE "

	if node.AdminOption {
		prefix += "ADMIN OPTION FOR "
	}

	roleNode := node.Roles.LogCurrentNodeWithType(depth+1, DataRoleName)

	infix := " FROM "

	memberNode := node.Members.LogCurrentNode(depth+1, ContextUse)

	rootIR := &SQLRightIR{
		NodeHash: 60979,
		IRType:   TypeRevokeRole,
		DataType: DataNone,
		LNode:    roleNode,
		RNode:    memberNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}
