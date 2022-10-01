// Copyright 2017 The Cockroach Authors.
//
// Use of this software is governed by the Business Source License
// included in the file licenses/BSL.txt.
//
// As of the Change Date specified in that file, in accordance with
// the Business Source License, use of this software will be governed
// by the Apache License, Version 2.0, included in the file
// licenses/APL.txt.

package tree

// ZoneSpecifier represents a reference to a configurable zone of the keyspace.
type ZoneSpecifier struct {
	// Only one of NamedZone, Database or TableOrIndex may be set.
	NamedZone UnrestrictedName
	Database  Name
	// TODO(radu): TableOrIndex abuses TableIndexName: it allows for the case when
	// an index is not specified, in which case TableOrIndex.Index is empty.
	TableOrIndex TableIndexName

	// Partition is only respected when Table is set.
	Partition Name
}

// TelemetryName returns a name fitting for telemetry purposes.
func (node ZoneSpecifier) TelemetryName() string {
	if node.NamedZone != "" {
		return "range"
	}
	if node.Database != "" {
		return "database"
	}
	str := ""
	if node.Partition != "" {
		str = "partition."
	}
	if node.TargetsIndex() {
		str += "index"
	} else {
		str += "table"
	}
	return str
}

// TargetsTable returns whether the zone specifier targets a table or a subzone
// within a table.
func (node ZoneSpecifier) TargetsTable() bool {
	return node.NamedZone == "" && node.Database == ""
}

// TargetsIndex returns whether the zone specifier targets an index.
func (node ZoneSpecifier) TargetsIndex() bool {
	return node.TargetsTable() && node.TableOrIndex.Index != ""
}

// TargetsPartition returns whether the zone specifier targets a partition.
func (node ZoneSpecifier) TargetsPartition() bool {
	return node.TargetsTable() && node.Partition != ""
}

// Format implements the NodeFormatter interface.
func (node *ZoneSpecifier) Format(ctx *FmtCtx) {
	if node.NamedZone != "" {
		ctx.WriteString("RANGE ")
		ctx.FormatNode(&node.NamedZone)
	} else if node.Database != "" {
		ctx.WriteString("DATABASE ")
		ctx.FormatNode(&node.Database)
	} else {
		if node.Partition != "" {
			ctx.WriteString("PARTITION ")
			ctx.FormatNode(&node.Partition)
			ctx.WriteString(" OF ")
		}
		if node.TargetsIndex() {
			ctx.WriteString("INDEX ")
		} else {
			ctx.WriteString("TABLE ")
		}
		ctx.FormatNode(&node.TableOrIndex)
	}
}

// SQLRight Code Injection.
func (node *ZoneSpecifier) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""
	infix := ""

	if node.NamedZone != "" {
		prefix += "RANGE "
		nameZoneNode := &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataZoneName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.NamedZone.String(),
		}

		rootIR := &SQLRightIR{
			IRType:   TypeZoneSpecifier,
			DataType: DataNone,
			LNode:    nameZoneNode,
			Prefix:   prefix,
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
		return rootIR

	} else if node.Database != "" {
		prefix += "DATABASE "
		databaseName := &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataDatabaseName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Database.String(),
		}

		rootIR := &SQLRightIR{
			IRType:   TypeZoneSpecifier,
			DataType: DataNone,
			LNode:    databaseName,
			Prefix:   prefix,
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
		return rootIR

	} else {
		var partitionName *SQLRightIR
		if node.Partition != "" {
			prefix += "PARTITION "
			infix = " OF "

			partitionName = &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataPartitionName,
				ContextFlag: ContextUse,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         node.Partition.String(),
			}
		}
		if node.TargetsIndex() {
			infix += "INDEX "
		} else {
			infix += "TABLE "
		}
		nameNode := node.TableOrIndex.LogCurrentNode(depth + 1)

		rootIR := &SQLRightIR{
			IRType:   TypeZoneSpecifier,
			DataType: DataNone,
			LNode:    partitionName,
			RNode:    nameNode,
			Prefix:   prefix,
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
		return rootIR
	}
}

func (node *ZoneSpecifier) String() string { return AsString(node) }

// ShowZoneConfig represents a SHOW ZONE CONFIGURATION
// statement.
type ShowZoneConfig struct {
	ZoneSpecifier
}

// Format implements the NodeFormatter interface.
func (node *ShowZoneConfig) Format(ctx *FmtCtx) {
	if node.ZoneSpecifier == (ZoneSpecifier{}) {
		ctx.WriteString("SHOW ZONE CONFIGURATIONS")
	} else {
		ctx.WriteString("SHOW ZONE CONFIGURATION FROM ")
		ctx.FormatNode(&node.ZoneSpecifier)
	}
}

// SQLRight Code Injection.
func (node *ShowZoneConfig) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""

	var zoneNode *SQLRightIR
	if node.ZoneSpecifier == (ZoneSpecifier{}) {
		prefix += "SHOW ZONE CONFIGURATIONS"
	} else {
		prefix += "SHOW ZONE CONFIGURATION FROM "
		zoneNode = node.ZoneSpecifier.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		IRType:   TypeShowZoneConfig,
		DataType: DataNone,
		LNode:    zoneNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR

}

// SetZoneConfig represents an ALTER DATABASE/TABLE... CONFIGURE ZONE
// statement.
type SetZoneConfig struct {
	ZoneSpecifier
	// AllIndexes indicates that the zone configuration should be applied across
	// all of a tables indexes. (ALTER PARTITION ... OF INDEX <tablename>@*)
	AllIndexes bool
	ZoneConfigSettings
}

// Format implements the NodeFormatter interface.
func (node *SetZoneConfig) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER ")
	ctx.FormatNode(&node.ZoneSpecifier)
	ctx.WriteString(" CONFIGURE ZONE ")
	node.ZoneConfigSettings.Format(ctx)
}

// SQLRight Code Injection.
func (node *SetZoneConfig) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ALTER "

	zoneNode := node.ZoneSpecifier.LogCurrentNode(depth + 1)

	infix := " CONFIGURE ZONE "

	zoneSetting := node.ZoneConfigSettings.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeSetZoneConfig,
		DataType: DataNone,
		LNode:    zoneNode,
		RNode:    zoneSetting,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ZoneConfigSettings represents info needed for zone config setting.
type ZoneConfigSettings struct {
	SetDefault bool
	YAMLConfig Expr
	Options    KVOptions
}

// Format implements the NodeFormatter interface.
func (node *ZoneConfigSettings) Format(ctx *FmtCtx) {
	if node.SetDefault {
		ctx.WriteString("USING DEFAULT")
	} else if node.YAMLConfig != nil {
		if node.YAMLConfig == DNull {
			ctx.WriteString("DISCARD")
		} else {
			ctx.WriteString("= ")
			ctx.FormatNode(node.YAMLConfig)
		}
	} else {
		ctx.WriteString("USING ")
		kvOptions := node.Options
		comma := ""
		for _, kv := range kvOptions {
			ctx.WriteString(comma)
			comma = ", "
			ctx.FormatNode(&kv.Key)
			if kv.Value != nil {
				ctx.WriteString(` = `)
				ctx.FormatNode(kv.Value)
			} else {
				ctx.WriteString(` = COPY FROM PARENT`)
			}
		}
	}
}

// SQLRight Code Injection.
func (node *ZoneConfigSettings) LogCurrentNode(depth int) *SQLRightIR {

	if node.SetDefault {
		prefix := "USING DEFAULT"
		rootIR := &SQLRightIR{
			IRType:   TypeZoneConfigSettings,
			DataType: DataNone,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		return rootIR
	} else if node.YAMLConfig != nil {
		prefix := ""
		var configNode *SQLRightIR
		if node.YAMLConfig == DNull {
			prefix = "DISCARD"
		} else {
			prefix = "= "
			configNode = node.YAMLConfig.LogCurrentNode(depth + 1)
		}
		rootIR := &SQLRightIR{
			IRType:   TypeZoneConfigSettings,
			DataType: DataNone,
			LNode:    configNode,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		return rootIR
	} else {
		prefix := "USING "

		var optionList []*SQLRightIR

		kvOptions := node.Options
		for _, kv := range kvOptions {
			keyNode := &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataUnknownType, // TODO: FIXME: Data type unknown.
				ContextFlag: ContextUse,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         kv.Key.String(),
			}

			infix := ""
			var valueNode *SQLRightIR
			if kv.Value != nil {
				infix = " = "
				valueNode = kv.Value.LogCurrentNode(depth + 1)
			} else {
				infix = " = COPY FROM PARENT "
			}

			optionNode := &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone, // TODO: FIXME: Data type unknown.
				LNode:    keyNode,
				RNode:    valueNode,
				Prefix:   "",
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}

			optionList = append(optionList, optionNode)
		}

		var optionNode *SQLRightIR
		for i, n := range optionList {
			if i == 0 {
				// Take care of the first two nodes.
				LNode := n
				var RNode *SQLRightIR
				infix := ""
				if len(optionList) >= 2 {
					infix = ", "
					RNode = (optionList)[1]
				}
				optionNode = &SQLRightIR{
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
				LNode := optionNode
				RNode := n

				optionNode = &SQLRightIR{
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
			IRType:   TypeZoneConfigSettings,
			DataType: DataNone,
			LNode:    optionNode,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		return rootIR
	}

}
