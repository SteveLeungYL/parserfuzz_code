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

import "fmt"

// AlterDatabaseOwner represents a ALTER DATABASE OWNER TO statement.
type AlterDatabaseOwner struct {
	Name  Name
	Owner RoleSpec
	SQLRightInterface
}

// Format implements the NodeFormatter interface.
func (node *AlterDatabaseOwner) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER DATABASE ")
	ctx.FormatNode(&node.Name)
	ctx.WriteString(" OWNER TO ")
	ctx.FormatNode(&node.Owner)
}

// SQLRight Code Injection.
func (node *AlterDatabaseOwner) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextUse,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: "",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
		Str:    string(node.Name),
	}

	RNode := node.Owner.LogCurrentNode(depth+1, ContextUse)
	rootIR := &SQLRightIR{
		IRType:   TypeAlterDatabaseOwner,
		DataType: DataNone,
		LNode:    tmpNode,
		RNode:    RNode,
		Prefix:   "ALTER DATABASE ",
		Infix:    " OWNER TO ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterDatabaseAddRegion represents a ALTER DATABASE ADD REGION statement.
type AlterDatabaseAddRegion struct {
	Name        Name
	Region      Name
	IfNotExists bool
}

var _ Statement = &AlterDatabaseAddRegion{}

// Format implements the NodeFormatter interface.
func (node *AlterDatabaseAddRegion) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER DATABASE ")
	ctx.FormatNode(&node.Name)
	ctx.WriteString(" ADD REGION ")
	if node.IfNotExists {
		ctx.WriteString("IF NOT EXISTS ")
	}
	ctx.FormatNode(&node.Region)
}

// SQLRight Code Injection.
func (node *AlterDatabaseAddRegion) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Name),
	}
	LNode := tmpNode

	tmpStr := ""
	if node.IfNotExists {
		tmpStr = "IF NOT EXISTS "
	}
	tmpNode = &SQLRightIR{
		IRType:   TypeOptIfNotExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: tmpStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}
	RNode := tmpNode

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "ALTER DATABASE ",
		Infix:    " ADD REGION ",
		Suffix:   "",
		Depth:    depth,
	}

	tmpNode = &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataRegionName,
		ContextFlag: ContextDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Region),
	}
	RNode = tmpNode

	rootIR = &SQLRightIR{
		IRType:   TypeAlterDatabaseAddRegion,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    RNode,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterDatabaseDropRegion represents a ALTER DATABASE DROP REGION statement.
type AlterDatabaseDropRegion struct {
	Name     Name
	Region   Name
	IfExists bool
}

var _ Statement = &AlterDatabaseDropRegion{}

// Format implements the NodeFormatter interface.
func (node *AlterDatabaseDropRegion) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER DATABASE ")
	ctx.FormatNode(&node.Name)
	ctx.WriteString(" DROP REGION ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(&node.Region)
}

// SQLRight Code Injection.
func (node *AlterDatabaseDropRegion) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Name),
	}
	LNode := tmpNode

	tmpStr := ""
	if node.IfExists {
		tmpStr = "IF EXISTS "
	}
	tmpRNode := &SQLRightIR{
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		Prefix:   tmpStr,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}
	RNode := tmpRNode

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "ALTER DATABASE ",
		Infix:    " DROP REGION ",
		Suffix:   "",
		Depth:    depth,
	}

	tmpNode = &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataRegionName,
		ContextFlag: ContextUndefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Region),
	}
	RNode = tmpNode

	rootIR = &SQLRightIR{
		IRType:   TypeAlterDatabaseDropRegion,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    RNode,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterDatabasePrimaryRegion represents a ALTER DATABASE PRIMARY REGION ... statement.
type AlterDatabasePrimaryRegion struct {
	Name          Name
	PrimaryRegion Name
}

var _ Statement = &AlterDatabasePrimaryRegion{}

// Format implements the NodeFormatter interface.
func (node *AlterDatabasePrimaryRegion) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER DATABASE ")
	ctx.FormatNode(&node.Name)
	ctx.WriteString(" PRIMARY REGION ")
	node.PrimaryRegion.Format(ctx)
}

// SQLRight Code Injection.
func (node *AlterDatabasePrimaryRegion) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Name),
	}
	LNode := tmpNode

	tmpNode = &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataRegionName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.PrimaryRegion),
	}
	RNode := tmpNode

	rootIR := &SQLRightIR{
		IRType:   TypeAlterChangeFeed,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "ALTER DATABASE ",
		Infix:    " PRIMARY REGION ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterDatabaseSurvivalGoal represents a ALTER DATABASE SURVIVE ... statement.
type AlterDatabaseSurvivalGoal struct {
	Name         Name
	SurvivalGoal SurvivalGoal
}

var _ Statement = &AlterDatabaseSurvivalGoal{}

// Format implements the NodeFormatter interface.
func (node *AlterDatabaseSurvivalGoal) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER DATABASE ")
	ctx.FormatNode(&node.Name)
	ctx.WriteString(" ")
	node.SurvivalGoal.Format(ctx)
}

// SQLRight Code Injection.
func (node *AlterDatabaseSurvivalGoal) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Name),
	}
	LNode := tmpNode

	RNode := node.SurvivalGoal.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeAlterDatabaseSurvivalGoal,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "ALTER DATABASE ",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterDatabasePlacement represents a ALTER DATABASE PLACEMENT statement.
type AlterDatabasePlacement struct {
	Name      Name
	Placement DataPlacement
}

var _ Statement = &AlterDatabasePlacement{}

// Format implements the NodeFormatter interface.
func (node *AlterDatabasePlacement) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER DATABASE ")
	ctx.FormatNode(&node.Name)
	ctx.WriteString(" ")
	node.Placement.Format(ctx)
}

// SQLRight Code Injection.
func (node *AlterDatabasePlacement) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Name),
	}
	LNode := tmpNode

	RNode := node.Placement.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeAlterDatabasePlacement,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "ALTER DATABASE ",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterDatabaseAddSuperRegion represents a
// ALTER DATABASE ADD SUPER REGION ... statement.
type AlterDatabaseAddSuperRegion struct {
	DatabaseName    Name
	SuperRegionName Name
	Regions         []Name
}

var _ Statement = &AlterDatabaseAddSuperRegion{}

// Format implements the NodeFormatter interface.
func (node *AlterDatabaseAddSuperRegion) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER DATABASE ")
	ctx.FormatNode(&node.DatabaseName)
	ctx.WriteString(" ADD SUPER REGION ")
	ctx.FormatNode(&node.SuperRegionName)
	ctx.WriteString(" VALUES ")
	for i, region := range node.Regions {
		if i != 0 {
			ctx.WriteString(",")
		}
		ctx.FormatNode(&region)
	}
}

// SQLRight Code Injection.
func (node *AlterDatabaseAddSuperRegion) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.DatabaseName),
	}
	LNode := tmpNode

	tmpNode = &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataSuperRegion,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.SuperRegionName),
	}
	RNode := tmpNode

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "ALTER DATABASE ",
		Infix:    " ADD SUPER REGION ",
		Suffix:   " VALUES ",
		Depth:    depth,
	}

	for i, n := range node.Regions {

		tmpNode = &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataRegionName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         string(n),
		}
		RNode = tmpNode

		infix := ""
		if i > 0 {
			infix = ", "
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeAlterDatabaseAddSuperRegion

	return rootIR
}

// AlterDatabaseDropSuperRegion represents a
// ALTER DATABASE DROP SUPER REGION ... statement.
type AlterDatabaseDropSuperRegion struct {
	DatabaseName    Name
	SuperRegionName Name
}

var _ Statement = &AlterDatabaseDropSuperRegion{}

// Format implements the NodeFormatter interface.
func (node *AlterDatabaseDropSuperRegion) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER DATABASE ")
	ctx.FormatNode(&node.DatabaseName)
	ctx.WriteString(" DROP SUPER REGION ")
	ctx.FormatNode(&node.SuperRegionName)
}

// SQLRight Code Injection.
func (node *AlterDatabaseDropSuperRegion) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.DatabaseName),
	}
	LNode := tmpNode

	tmpNode = &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataSuperRegion,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.SuperRegionName),
	}
	RNode := tmpNode

	rootIR := &SQLRightIR{
		IRType:   TypeAlterDatabaseDropSuperRegion,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "ALTER DATABASE ",
		Infix:    " DROP SUPER REGION ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterDatabaseAlterSuperRegion represents a
// ALTER DATABASE ADD SUPER REGION ... statement.
type AlterDatabaseAlterSuperRegion struct {
	DatabaseName    Name
	SuperRegionName Name
	Regions         []Name
}

var _ Statement = &AlterDatabaseAlterSuperRegion{}

// Format implements the NodeFormatter interface.
func (node *AlterDatabaseAlterSuperRegion) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER DATABASE ")
	ctx.FormatNode(&node.DatabaseName)
	ctx.WriteString(" ALTER SUPER REGION ")
	ctx.FormatNode(&node.SuperRegionName)
	ctx.WriteString(" VALUES ")
	for i, region := range node.Regions {
		if i != 0 {
			ctx.WriteString(",")
		}
		ctx.FormatNode(&region)
	}
}

// SQLRight Code Injection.
func (node *AlterDatabaseAlterSuperRegion) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.DatabaseName),
	}
	LNode := tmpNode

	tmpNode = &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataSuperRegion,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.SuperRegionName),
	}
	RNode := tmpNode

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "ALTER DATABASE ",
		Infix:    " ALTER SUPER REGION ",
		Suffix:   " VALUES ",
		Depth:    depth,
	}

	for i, n := range node.Regions {

		tmpNode = &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataRegionName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         string(n),
		}
		RNode = tmpNode

		infix := ""
		if i > 0 {
			infix = ", "
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}

	}

	rootIR.IRType = TypeAlterDatabaseAlterSuperRegion

	return rootIR
}

// AlterDatabaseSecondaryRegion represents a
// ALTER DATABASE SET SECONDARY REGION ... statement.
type AlterDatabaseSecondaryRegion struct {
	DatabaseName    Name
	SecondaryRegion Name
}

var _ Statement = &AlterDatabaseSecondaryRegion{}

// Format implements the NodeFormatter interface.
func (node *AlterDatabaseSecondaryRegion) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER DATABASE ")
	ctx.FormatNode(&node.DatabaseName)
	ctx.WriteString(" SET SECONDARY REGION ")
	node.SecondaryRegion.Format(ctx)
}

// SQLRight Code Injection.
func (node *AlterDatabaseSecondaryRegion) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.DatabaseName),
	}
	LNode := tmpNode

	tmpNode = &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataRegionName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.SecondaryRegion),
	}
	RNode := tmpNode

	rootIR := &SQLRightIR{
		IRType:   TypeAlterDatabaseSecondaryRegion,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "ALTER DATABASE ",
		Infix:    " SET SECONDARY REGION ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterDatabaseDropSecondaryRegion represents a
// ALTER DATABASE DROP SECONDARY REGION statement.
type AlterDatabaseDropSecondaryRegion struct {
	DatabaseName Name
	IfExists     bool
}

var _ Statement = &AlterDatabaseDropSecondaryRegion{}

// Format implements the NodeFormatter interface.
func (node *AlterDatabaseDropSecondaryRegion) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER DATABASE ")
	ctx.FormatNode(&node.DatabaseName)
	ctx.WriteString(" DROP SECONDARY REGION ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
}

// SQLRight Code Injection.
func (node *AlterDatabaseDropSecondaryRegion) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.DatabaseName),
	}
	LNode := tmpNode

	tmpStr := ""
	if node.IfExists {
		tmpStr = "IF EXISTS "
	}
	tmpNode = &SQLRightIR{
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		Prefix:   tmpStr,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}
	RNode := tmpNode

	rootIR := &SQLRightIR{
		IRType:   TypeAlterDatabaseDropSecondaryRegion,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "ALTER DATABASE ",
		Infix:    " DROP SECONDARY REGION ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterDatabaseSetZoneConfigExtension represents a
// ALTER DATABASE ... ALTER LOCALITY ... CONFIGURE ZONE ... statement.
type AlterDatabaseSetZoneConfigExtension struct {
	// ALTER DATABASE ...
	DatabaseName Name
	// ALTER LOCALITY ...
	LocalityLevel LocalityLevel
	RegionName    Name
	// CONFIGURE ZONE ...
	ZoneConfigSettings
}

var _ Statement = &AlterDatabaseSetZoneConfigExtension{}

// Format implements the NodeFormatter interface.
func (node *AlterDatabaseSetZoneConfigExtension) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER DATABASE ")
	ctx.FormatNode(&node.DatabaseName)
	ctx.WriteString(" ALTER LOCALITY")
	switch node.LocalityLevel {
	case LocalityLevelGlobal:
		ctx.WriteString(" GLOBAL")
	case LocalityLevelTable:
		ctx.WriteString(" REGIONAL")
		if node.RegionName != "" {
			ctx.WriteString(" IN ")
			ctx.FormatNode(&node.RegionName)
		}
	default:
		panic(fmt.Sprintf("unexpected locality: %#v", node.LocalityLevel))
	}
	ctx.WriteString(" CONFIGURE ZONE ")
	node.ZoneConfigSettings.Format(ctx)
}

// SQLRight Code Injection.
func (node *AlterDatabaseSetZoneConfigExtension) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.DatabaseName),
	}
	LNode := tmpNode

	var RNode *SQLRightIR
	infix := ""
	switch node.LocalityLevel {
	case LocalityLevelGlobal:
		infix = " GLOBAL"
	case LocalityLevelTable:
		infix = " REGIONAL"
		if node.RegionName != "" {
			infix = " IN "
			tmpNode = &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataRegionName,
				ContextFlag: ContextUnknown,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         string(node.RegionName),
			}
			RNode = tmpNode
		}
	default:
		panic(fmt.Sprintf("unexpected locality: %#v", node.LocalityLevel))
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "ALTER DATABASE ",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	RNode = node.ZoneConfigSettings.LogCurrentNode(depth + 1)

	rootIR = &SQLRightIR{
		IRType:   TypeAlterDatabaseSetZoneConfigExtension,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    RNode,
		Prefix:   "",
		Infix:    " CONFIGURE ZONE ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}
