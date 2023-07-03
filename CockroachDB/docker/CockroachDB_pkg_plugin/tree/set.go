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

// SetVar represents a SET or RESET statement.
type SetVar struct {
	Name     string
	Local    bool
	Values   Exprs
	Reset    bool
	ResetAll bool
}

// Format implements the NodeFormatter interface.
func (node *SetVar) Format(ctx *FmtCtx) {
	if node.ResetAll {
		ctx.WriteString("RESET ALL")
		return
	}
	if node.Reset {
		ctx.WriteString("RESET ")
		ctx.WithFlags(ctx.flags & ^FmtAnonymize & ^FmtMarkRedactionNode, func() {
			// Session var names never contain PII and should be distinguished
			// for feature tracking purposes.
			ctx.FormatNameP(&node.Name)
		})
		return
	}
	ctx.WriteString("SET ")
	if node.Local {
		ctx.WriteString("LOCAL ")
	}
	if node.Name == "" {
		ctx.WriteString("ROW (")
		ctx.FormatNode(&node.Values)
		ctx.WriteString(")")
	} else {
		ctx.WithFlags(ctx.flags & ^FmtAnonymize & ^FmtMarkRedactionNode, func() {
			// Session var names never contain PII and should be distinguished
			// for feature tracking purposes.
			ctx.FormatNameP(&node.Name)
		})

		ctx.WriteString(" = ")
		ctx.FormatNode(&node.Values)
	}
}

// SQLRight Code Injection.
func (node *SetVar) LogCurrentNode(depth int) *SQLRightIR {

	if node.ResetAll {
		rootIR := &SQLRightIR{
			NodeHash: 60749,
			IRType:   TypeSetVar,
			DataType: DataNone,
			//LNode:    ,
			//RNode:    "",
			Prefix: "RESET ALL",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		return rootIR
	}

	if node.Reset {
		settingNameNode := &SQLRightIR{
			NodeHash:    144286,
			IRType:      TypeIdentifier,
			DataType:    DataSettingName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Name,
		}
		rootIR := &SQLRightIR{
			NodeHash: 92464,
			IRType:   TypeSetVar,
			DataType: DataNone,
			LNode:    settingNameNode,
			//RNode:    fromNode,
			Prefix: "RESET ",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		return rootIR
	}

	prefix := "SET "
	infix := ""
	if node.Local {
		prefix += "LOCAL "
	}
	var pNameNode *SQLRightIR
	var pValueNode *SQLRightIR
	if node.Name == "" {
		prefix += "ROW ("
		infix = ")"
		pNameNode = node.Values.LogCurrentNode(depth + 1)
	} else {
		nameNode := &SQLRightIR{
			NodeHash:    178073,
			IRType:      TypeIdentifier,
			DataType:    DataSettingName,
			ContextFlag: ContextDefine,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Name,
		}
		pNameNode = nameNode

		infix = " = "

		pValueNode = node.Values.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		NodeHash: 199868,
		IRType:   TypeSetVar,
		DataType: DataNone,
		LNode:    pNameNode,
		RNode:    pValueNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// SetClusterSetting represents a SET CLUSTER SETTING statement.
type SetClusterSetting struct {
	Name  string
	Value Expr
}

// Format implements the NodeFormatter interface.
func (node *SetClusterSetting) Format(ctx *FmtCtx) {
	ctx.WriteString("SET CLUSTER SETTING ")

	// Cluster setting names never contain PII and should be distinguished
	// for feature tracking purposes.
	ctx.WithFlags(ctx.flags & ^FmtAnonymize & ^FmtMarkRedactionNode, func() {
		ctx.FormatNameP(&node.Name)
	})

	ctx.WriteString(" = ")

	switch v := node.Value.(type) {
	case *DBool, *DInt:
		ctx.WithFlags(ctx.flags & ^FmtAnonymize & ^FmtMarkRedactionNode, func() {
			ctx.FormatNode(v)
		})
	default:
		ctx.FormatNode(v)
	}
}

// SQLRight Code Injection.
func (node *SetClusterSetting) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SET CLUSTER SETTING "

	nameNode := &SQLRightIR{
		NodeHash:    200939,
		IRType:      TypeIdentifier,
		DataType:    DataNone,
		ContextFlag: ContextDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Name,
	}

	infix := " = "

	var pValueNode *SQLRightIR
	switch v := node.Value.(type) {
	case *DBool, *DInt:
		pValueNode = v.LogCurrentNode(depth + 1)
	default:
		pValueNode = v.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		NodeHash: 218263,
		IRType:   TypeSetClusterSetting,
		DataType: DataNone,
		LNode:    nameNode,
		RNode:    pValueNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// SetTransaction represents a SET TRANSACTION statement.
type SetTransaction struct {
	Modes TransactionModes
}

// Format implements the NodeFormatter interface.
func (node *SetTransaction) Format(ctx *FmtCtx) {
	ctx.WriteString("SET TRANSACTION")
	ctx.FormatNode(&node.Modes)
}

// SQLRight Code Injection.
func (node *SetTransaction) LogCurrentNode(depth int) *SQLRightIR {

	modeNodes := node.Modes.LogCurrentNode(depth + 1)
	rootIR := &SQLRightIR{
		NodeHash: 22590,
		IRType:   TypeSetTransaction,
		DataType: DataNone,
		LNode:    modeNodes,
		//RNode:    RNode,
		Prefix: "SET TRANSACTION ",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// SetSessionAuthorizationDefault represents a SET SESSION AUTHORIZATION DEFAULT
// statement. This can be extended (and renamed) if we ever support names in the
// last position.
type SetSessionAuthorizationDefault struct{}

// Format implements the NodeFormatter interface.
func (node *SetSessionAuthorizationDefault) Format(ctx *FmtCtx) {
	ctx.WriteString("SET SESSION AUTHORIZATION DEFAULT")
}

// SQLRight Code Injection.
func (node *SetSessionAuthorizationDefault) LogCurrentNode(depth int) *SQLRightIR {

	rootIR := &SQLRightIR{
		NodeHash: 16606,
		IRType:   TypeSetSessionAuthorizationDefault,
		DataType: DataNone,
		//LNode:    modeNodes,
		//RNode:    RNode,
		Prefix: "SET SESSION AUTHORIZATION DEFAULT",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// SetSessionCharacteristics represents a SET SESSION CHARACTERISTICS AS TRANSACTION statement.
type SetSessionCharacteristics struct {
	Modes TransactionModes
}

// Format implements the NodeFormatter interface.
func (node *SetSessionCharacteristics) Format(ctx *FmtCtx) {
	ctx.WriteString("SET SESSION CHARACTERISTICS AS TRANSACTION")
	ctx.FormatNode(&node.Modes)
}

// SQLRight Code Injection.
func (node *SetSessionCharacteristics) LogCurrentNode(depth int) *SQLRightIR {

	modeNodes := node.Modes.LogCurrentNode(depth + 1)
	rootIR := &SQLRightIR{
		NodeHash: 253183,
		IRType:   TypeSetSessionCharacteristics,
		DataType: DataNone,
		LNode:    modeNodes,
		//RNode:    RNode,
		Prefix: "SET SESSION CHARACTERISTICS AS TRANSACTION",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// SetTracing represents a SET TRACING statement.
type SetTracing struct {
	Values Exprs
}

// Format implements the NodeFormatter interface.
func (node *SetTracing) Format(ctx *FmtCtx) {
	ctx.WriteString("SET TRACING = ")
	// Set tracing values never contain PII and should be distinguished
	// for feature tracking purposes.
	ctx.WithFlags(ctx.flags&^FmtMarkRedactionNode, func() {
		ctx.FormatNode(&node.Values)
	})
}

// SQLRight Code Injection.
func (node *SetTracing) LogCurrentNode(depth int) *SQLRightIR {

	valueNodes := node.Values.LogCurrentNode(depth + 1)
	rootIR := &SQLRightIR{
		NodeHash: 62634,
		IRType:   TypeSetTracing,
		DataType: DataNone,
		LNode:    valueNodes,
		//RNode:    RNode,
		Prefix: "SET TRACING = ",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}
