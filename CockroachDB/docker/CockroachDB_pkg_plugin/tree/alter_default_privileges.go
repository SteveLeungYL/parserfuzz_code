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

import (
	"bytes"
	"github.com/cockroachdb/cockroach/pkg/sql/privilege"
)

// AlterDefaultPrivileges represents an ALTER DEFAULT PRIVILEGES statement.
type AlterDefaultPrivileges struct {
	Roles RoleSpecList
	// True if `ALTER DEFAULT PRIVILEGES FOR ALL ROLES` is executed.
	ForAllRoles bool
	// If Schema is not specified, ALTER DEFAULT PRIVILEGES is being
	// run on the current database.
	Schemas ObjectNamePrefixList

	// Database is only used when converting a granting / revoking incompatible
	// database privileges to an alter default privileges statement.
	// If it is not set, the current database is used.
	Database *Name

	// Only one of Grant or Revoke should be set. IsGrant is used to determine
	// which one is set.
	IsGrant bool
	Grant   AbbreviatedGrant
	Revoke  AbbreviatedRevoke

	SQLRightInterface
}

// Format implements the NodeFormatter interface.
func (n *AlterDefaultPrivileges) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER DEFAULT PRIVILEGES ")
	if n.ForAllRoles {
		ctx.WriteString("FOR ALL ROLES ")
	} else if len(n.Roles) > 0 {
		ctx.WriteString("FOR ROLE ")
		for i, role := range n.Roles {
			if i > 0 {
				ctx.WriteString(", ")
			}
			ctx.FormatNode(&role)
		}
		ctx.WriteString(" ")
	}
	if len(n.Schemas) > 0 {
		ctx.WriteString("IN SCHEMA ")
		ctx.FormatNode(n.Schemas)
		ctx.WriteString(" ")
	}
	if n.IsGrant {
		n.Grant.Format(ctx)
	} else {
		n.Revoke.Format(ctx)
	}
}

// SQLRight Code Injection.
func (node *AlterDefaultPrivileges) LogCurrentNode(depth int) *SQLRightIR {

	// Handle FOR ALL ROLE or FOR ROLE first.
	var LNode *SQLRightIR
	var rootNode *SQLRightIR
	prefix := ""
	if node.ForAllRoles {
		// root node with FOR ALL ROLES.
		prefix = "FOR ALL ROLES "
		rootNode = &SQLRightIR{
			IRType:   TypeOptForRole,
			DataType: DataNone,
			//LNode:    LNode,
			//RNode:    RNode,
			Prefix: prefix,
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
	} else if len(node.Roles) > 0 {
		// root node with role list.
		prefix = "FOR ROLE "
		LNode = node.Roles.LogCurrentNode(depth+1, ContextUse)

		rootNode = &SQLRightIR{
			IRType:   TypeOptForRole,
			DataType: DataNone,
			LNode:    LNode,
			//RNode:    RNode,
			Prefix: prefix,
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}

	} else {
		// Empty root node.
		rootNode = &SQLRightIR{
			IRType:   TypeOptForRole,
			DataType: DataNone,
			//LNode:    LNode,
			//RNode:    RNode,
			Prefix: prefix,
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
	}

	roleNode := rootNode

	// Handle for optInSchema
	var schemaNode *SQLRightIR
	infix := ""
	if len(node.Schemas) > 0 {
		schemaNode = node.Schemas.LogCurrentNode(depth + 1)
		infix = " IN SCHEMA "
	}

	rootNode = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    roleNode,
		RNode:    schemaNode,
		Prefix:   "ALTER DEFAULT PRIVILEGES ",
		Infix:    infix,
		Suffix:   " ",
		Depth:    depth,
	}

	LNode = rootNode

	var RNode *SQLRightIR
	if node.IsGrant {
		RNode = node.Grant.LogCurrentNode(depth + 1)
	} else {
		RNode = node.Revoke.LogCurrentNode(depth + 1)
	}

	rootNode = &SQLRightIR{
		IRType:   TypeAlterDefaultPrivileges,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootNode
}

// AbbreviatedGrant represents the GRANT part of an
// ALTER DEFAULT PRIVILEGES statement.
type AbbreviatedGrant struct {
	Privileges      privilege.List
	Target          privilege.TargetObjectType
	Grantees        RoleSpecList
	WithGrantOption bool

	SQLRightInterface
}

// Format implements the NodeFormatter interface.
func (n *AbbreviatedGrant) Format(ctx *FmtCtx) {
	ctx.WriteString("GRANT ")
	n.Privileges.Format(&ctx.Buffer)
	ctx.WriteString(" ON ")
	switch n.Target {
	case privilege.Tables:
		ctx.WriteString("TABLES ")
	case privilege.Sequences:
		ctx.WriteString("SEQUENCES ")
	case privilege.Types:
		ctx.WriteString("TYPES ")
	case privilege.Schemas:
		ctx.WriteString("SCHEMAS ")
	case privilege.Functions:
		ctx.WriteString("FUNCTIONS ")
	}
	ctx.WriteString("TO ")
	n.Grantees.Format(ctx)
	if n.WithGrantOption {
		ctx.WriteString(" WITH GRANT OPTION")
	}
}

// SQLRight Code Injection.
func (node *AbbreviatedGrant) LogCurrentNode(depth int) *SQLRightIR {

	var tmpBuffer bytes.Buffer
	node.Privileges.Format(&tmpBuffer)
	prefix := "GRANT " + tmpBuffer.String() + " ON "

	// grant target
	grantTarget := ""
	switch node.Target {
	case privilege.Tables:
		grantTarget = "TABLES "
	case privilege.Sequences:
		grantTarget = "SEQUENCES "
	case privilege.Types:
		grantTarget = "TYPES "
	case privilege.Schemas:
		grantTarget = "SCHEMAS "
	case privilege.Functions:
		grantTarget = "FUNCTIONS "
	}

	tmpNode := &SQLRightIR{
		IRType:   TypeGrantTarget,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: grantTarget,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	LNode := tmpNode

	RNode := node.Grantees.LogCurrentNode(depth+1, ContextUse)

	suffix := ""
	if node.WithGrantOption {
		suffix = " WITH GRANT OPTION"
	}

	rootIR := &SQLRightIR{
		IRType:   TypeAbbreviatedGrant,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   prefix,
		Infix:    "TO ",
		Suffix:   suffix,
		Depth:    depth,
	}

	return rootIR
}

// AbbreviatedRevoke represents the REVOKE part of an
// ALTER DEFAULT PRIVILEGES statement.
type AbbreviatedRevoke struct {
	Privileges     privilege.List
	Target         privilege.TargetObjectType
	Grantees       RoleSpecList
	GrantOptionFor bool

	SQLRightInterface
}

// Format implements the NodeFormatter interface.
func (n *AbbreviatedRevoke) Format(ctx *FmtCtx) {
	ctx.WriteString("REVOKE ")
	if n.GrantOptionFor {
		ctx.WriteString("GRANT OPTION FOR ")
	}
	n.Privileges.Format(&ctx.Buffer)
	ctx.WriteString(" ON ")
	switch n.Target {
	case privilege.Tables:
		ctx.WriteString("TABLES ")
	case privilege.Sequences:
		ctx.WriteString("SEQUENCES ")
	case privilege.Types:
		ctx.WriteString("TYPES ")
	case privilege.Schemas:
		ctx.WriteString("SCHEMAS ")
	case privilege.Functions:
		ctx.WriteString("FUNCTIONS ")
	}
	ctx.WriteString(" FROM ")
	n.Grantees.Format(ctx)
}

// SQLRight Code Injection.
func (node *AbbreviatedRevoke) LogCurrentNode(depth int) *SQLRightIR {

	var tmpBuffer bytes.Buffer
	node.Privileges.Format(&tmpBuffer)

	prefix := "REVOKE "
	if node.GrantOptionFor {
		prefix += "GRANT OPTION FOR "
	}
	prefix += tmpBuffer.String()
	prefix += " ON "

	// grant target
	revokeTarget := ""
	switch node.Target {
	case privilege.Tables:
		revokeTarget = "TABLES "
	case privilege.Sequences:
		revokeTarget = "SEQUENCES "
	case privilege.Types:
		revokeTarget = "TYPES "
	case privilege.Schemas:
		revokeTarget = "SCHEMAS "
	case privilege.Functions:
		revokeTarget = "FUNCTIONS "
	}

	tmpNode := &SQLRightIR{
		IRType:   TypeGrantTarget,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: revokeTarget,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	LNode := tmpNode

	RNode := node.Grantees.LogCurrentNode(depth+1, ContextUse)

	rootIR := &SQLRightIR{
		IRType:   TypeAbbreviatedRevoke,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   prefix,
		Infix:    " FROM ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}
