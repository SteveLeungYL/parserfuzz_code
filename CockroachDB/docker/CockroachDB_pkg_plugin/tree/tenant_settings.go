// Copyright 2022 The Cockroach Authors.
//
// Use of this software is governed by the Business Source License
// included in the file licenses/BSL.txt.
//
// As of the Change Date specified in that file, in accordance with
// the Business Source License, use of this software will be governed
// by the Apache License, Version 2.0, included in the file
// licenses/APL.txt.

package tree

// AlterTenantSetClusterSetting represents an ALTER TENANT
// SET CLUSTER SETTING statement.
type AlterTenantSetClusterSetting struct {
	SetClusterSetting
	TenantID  Expr
	TenantAll bool
}

// Format implements the NodeFormatter interface.
func (n *AlterTenantSetClusterSetting) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER TENANT ")
	if n.TenantAll {
		ctx.WriteString("ALL")
	} else {
		ctx.FormatNode(n.TenantID)
	}
	ctx.WriteByte(' ')
	ctx.FormatNode(&n.SetClusterSetting)
}

// SQLRight Code Injection.
func (node *AlterTenantSetClusterSetting) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ALTER TENANT "
	var tenantNode *SQLRightIR
	if node.TenantAll {
		tmpNode := &SQLRightIR{
			IRType:   TypeTenantAllOrID,
			DataType: DataNone,
			//LNode:    LNode,
			//RNode:    RNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		tenantNode = tmpNode
	} else {
		tenantNode = node.TenantID.LogCurrentNode(depth + 1)
	}

	infix := " "

	setClusterNode := node.SetClusterSetting.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeAlterTenantSetClusterSetting,
		DataType: DataNone,
		LNode:    tenantNode,
		RNode:    setClusterNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowTenantClusterSetting represents a SHOW CLUSTER SETTING ... FOR TENANT statement.
type ShowTenantClusterSetting struct {
	*ShowClusterSetting
	TenantID Expr
}

// Format implements the NodeFormatter interface.
func (node *ShowTenantClusterSetting) Format(ctx *FmtCtx) {
	ctx.FormatNode(node.ShowClusterSetting)
	ctx.WriteString(" FOR TENANT ")
	ctx.FormatNode(node.TenantID)
}

// SQLRight Code Injection.
func (node *ShowTenantClusterSetting) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.ShowClusterSetting.LogCurrentNode(depth + 1)

	RNode := node.TenantID.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeShowTenantClusterSetting,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "",
		Infix:    " FOR TENANT ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowTenantClusterSettingList represents a SHOW CLUSTER SETTINGS FOR TENANT statement.
type ShowTenantClusterSettingList struct {
	*ShowClusterSettingList
	TenantID Expr
}

// Format implements the NodeFormatter interface.
func (node *ShowTenantClusterSettingList) Format(ctx *FmtCtx) {
	ctx.FormatNode(node.ShowClusterSettingList)
	ctx.WriteString(" FOR TENANT ")
	ctx.FormatNode(node.TenantID)
}

// SQLRight Code Injection.
func (node *ShowTenantClusterSettingList) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.ShowClusterSettingList.LogCurrentNode(depth + 1)

	RNode := node.TenantID.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeShowTenantClusterSettingList,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "",
		Infix:    " FOR TENANT ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}
