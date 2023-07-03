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
	"fmt"

	"github.com/cockroachdb/cockroach/pkg/sql/lexbase"
)

// RoleSpecType represents whether the RoleSpec is represented by
// string name or if the spec is CURRENT_USER or SESSION_USER.
type RoleSpecType int

const (
	// RoleName represents if a RoleSpec is defined using an IDENT or
	// unreserved_keyword in the grammar.
	RoleName RoleSpecType = iota
	// CurrentUser represents if a RoleSpec is defined using CURRENT_USER.
	CurrentUser
	// SessionUser represents if a RoleSpec is defined using SESSION_USER.
	SessionUser
)

func (r RoleSpecType) String() string {
	switch r {
	case RoleName:
		return "ROLE_NAME"
	case CurrentUser:
		return "CURRENT_USER"
	case SessionUser:
		return "SESSION_USER"
	default:
		panic(fmt.Sprintf("unknown role spec type: %d", r))
	}
}

// SQLRight Code Injection.
func (node RoleSpecType) LogCurrentNode(depth int) *SQLRightIR {

	var prefix = ""

	switch node {
	case RoleName:
		prefix = "ROLE_NAME"
	case CurrentUser:
		prefix = "CURRENT_USER"
	case SessionUser:
		prefix = "SESSION_USER"
	default:
		panic(fmt.Sprintf("unknown role spec type: %d", node))
	}

	rootIR := &SQLRightIR{
		NodeHash: 102095,
		IRType:   TypeRoleSpecType,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// RoleSpecList is a list of RoleSpec.
type RoleSpecList []RoleSpec

// RoleSpec represents a role.
// Name should only be populated if RoleSpecType is RoleName.
type RoleSpec struct {
	RoleSpecType RoleSpecType
	Name         string
	SQLRightInterface
}

// MakeRoleSpecWithRoleName creates a RoleSpec using a RoleName.
func MakeRoleSpecWithRoleName(name string) RoleSpec {
	return RoleSpec{RoleSpecType: RoleName, Name: name}
}

// Undefined returns if RoleSpec is undefined.
func (r RoleSpec) Undefined() bool {
	return r.RoleSpecType == RoleName && len(r.Name) == 0
}

// Format implements the NodeFormatter interface.
func (r *RoleSpec) Format(ctx *FmtCtx) {
	f := ctx.flags
	if f.HasFlags(FmtAnonymize) && !isArityIndicatorString(r.Name) {
		ctx.WriteByte('_')
	} else {
		switch r.RoleSpecType {
		case RoleName:
			lexbase.EncodeRestrictedSQLIdent(&ctx.Buffer, r.Name, f.EncodeFlags())
			return
		case CurrentUser, SessionUser:
			ctx.WriteString(r.RoleSpecType.String())
		}
	}
}

// SQLRight Code Injection.
func (node *RoleSpec) LogCurrentNode(depth int, flag SQLRightContextFlag) *SQLRightIR {

	var rootNode *SQLRightIR
	switch node.RoleSpecType {
	case RoleName:
		LNode := &SQLRightIR{
			NodeHash:    173061,
			IRType:      TypeIdentifier,
			DataType:    DataRoleName,
			ContextFlag: flag,
			//LNode:    LNode,
			//RNode:    RNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
			Str:    node.Name,
		}

		tmpNode := &SQLRightIR{
			NodeHash: 145933,
			IRType:   TypeRoleSpec,
			DataType: DataNone,
			LNode:    LNode,
			//RNode:    RNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootNode = tmpNode

	case CurrentUser, SessionUser:
		LNode := node.RoleSpecType.LogCurrentNode(depth + 1)

		tmpNode := &SQLRightIR{
			NodeHash: 253304,
			IRType:   TypeRoleSpec,
			DataType: DataNone,
			LNode:    LNode,
			//RNode:    RNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		rootNode = tmpNode
	}

	return rootNode
}

// Format implements the NodeFormatter interface.
func (l *RoleSpecList) Format(ctx *FmtCtx) {
	for i := range *l {
		if i > 0 {
			ctx.WriteString(", ")
		}
		ctx.FormatNode(&(*l)[i])
	}
}

// SQLRight Code Injection.
func (node *RoleSpecList) LogCurrentNode(depth int, flag SQLRightContextFlag) *SQLRightIR {

	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{
		NodeHash: 46342}
	for i, n := range *node {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n.LogCurrentNode(depth+1, flag)
			var RNode *SQLRightIR
			infix := ""
			if len(*node) >= 2 {
				RNode = (*node)[1].LogCurrentNode(depth+1, flag)
				infix = ", "
			}
			tmpIR = &SQLRightIR{
				NodeHash: 171038,
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
			LNode := tmpIR
			RNode := n.LogCurrentNode(depth+1, flag)

			tmpIR = &SQLRightIR{
				NodeHash: 43941,
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

	// Only flag the root node for the type.
	tmpIR.IRType = TypeRoleSpecList
	return tmpIR
}
