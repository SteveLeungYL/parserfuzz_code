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

import "strconv"

// AlterBackupSchedule represents an ALTER BACKUP SCHEDULE statement.
type AlterBackupSchedule struct {
	ScheduleID uint64
	Cmds       AlterBackupScheduleCmds
}

var _ Statement = &AlterBackupSchedule{}

// Format implements the NodeFormatter interface.
func (node *AlterBackupSchedule) Format(ctx *FmtCtx) {
	ctx.WriteString(`ALTER BACKUP SCHEDULE `)
	if ctx.HasFlags(FmtHideConstants) || ctx.HasFlags(FmtAnonymize) {
		ctx.WriteString("123")
	} else {
		ctx.WriteString(strconv.FormatUint(node.ScheduleID, 10))
	}
	ctx.WriteByte(' ')
	ctx.FormatNode(&node.Cmds)
}

// SQLRight Code Injection.
func (node *AlterBackupSchedule) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:       TypeIntegerLiteral,
		DataType:     DataNone,
		DataAffinity: AFFIINT,
		Prefix:       "",
		Infix:        "",
		Suffix:       "",
		Depth:        depth,
		UValue:       node.ScheduleID,
	}

	LNode := tmpNode
	RNode := node.Cmds.LogCurrentNode(depth + 1)
	rootIR := &SQLRightIR{
		IRType:   TypeAlterBackupSchedule,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "ALTER BACKUP SCHEDULE ",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterBackupScheduleCmds represents a list of changefeed alterations
type AlterBackupScheduleCmds []AlterBackupScheduleCmd

// Format implements the NodeFormatter interface.
func (node *AlterBackupScheduleCmds) Format(ctx *FmtCtx) {
	for i, n := range *node {
		if i > 0 {
			ctx.WriteString(", ")
		}
		ctx.FormatNode(n)
	}
}

// SQLRight Code Injection.
func (node *AlterBackupScheduleCmds) LogCurrentNode(depth int) *SQLRightIR {

	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{}
	for i, n := range *node {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n.LogCurrentNode(depth + 1)
			var RNode *SQLRightIR
			infix := ""
			if len(*node) >= 2 {
				RNode = (*node)[1].LogCurrentNode(depth + 1)
				infix = ", "
			}

			tmpIR = &SQLRightIR{
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
			RNode := n.LogCurrentNode(depth + 1)

			tmpIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    tmpIR,
				RNode:    RNode,
				Prefix:   "",
				Infix:    ", ",
				Suffix:   "",
				Depth:    depth,
			}
		}
	}

	// Only flag the root node for the type.
	tmpIR.IRType = TypeAlterBackupScheduleCmds
	return tmpIR
}

// AlterBackupScheduleCmd represents a changefeed modification operation.
type AlterBackupScheduleCmd interface {
	NodeFormatter
	// Placeholder function to ensure that only desired types
	// (AlterBackupSchedule*) conform to the AlterBackupScheduleCmd interface.
	alterBackupScheduleCmd()
	SQLRightInterface
}

func (*AlterBackupScheduleSetLabel) alterBackupScheduleCmd()          {}
func (*AlterBackupScheduleSetInto) alterBackupScheduleCmd()           {}
func (*AlterBackupScheduleSetWith) alterBackupScheduleCmd()           {}
func (*AlterBackupScheduleSetRecurring) alterBackupScheduleCmd()      {}
func (*AlterBackupScheduleSetFullBackup) alterBackupScheduleCmd()     {}
func (*AlterBackupScheduleSetScheduleOption) alterBackupScheduleCmd() {}

var _ AlterBackupScheduleCmd = &AlterBackupScheduleSetLabel{}
var _ AlterBackupScheduleCmd = &AlterBackupScheduleSetInto{}
var _ AlterBackupScheduleCmd = &AlterBackupScheduleSetWith{}
var _ AlterBackupScheduleCmd = &AlterBackupScheduleSetRecurring{}
var _ AlterBackupScheduleCmd = &AlterBackupScheduleSetFullBackup{}
var _ AlterBackupScheduleCmd = &AlterBackupScheduleSetScheduleOption{}

// AlterBackupScheduleSetLabel represents an ADD <label> command
type AlterBackupScheduleSetLabel struct {
	Label Expr
}

// Format implements the NodeFormatter interface.
func (node *AlterBackupScheduleSetLabel) Format(ctx *FmtCtx) {
	ctx.WriteString("SET LABEL ")
	ctx.FormatNode(node.Label)
}

// SQLRight Code Injection.
func (node *AlterBackupScheduleSetLabel) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.Label.LogCurrentNode(depth + 1)
	rootIR := &SQLRightIR{
		IRType:   TypeAlterBackupScheduleSetLabel,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: "SET LABEL ",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// AlterBackupScheduleSetInto represents a SET <destinations> command
type AlterBackupScheduleSetInto struct {
	Into StringOrPlaceholderOptList
}

// Format implements the NodeFormatter interface.
func (node *AlterBackupScheduleSetInto) Format(ctx *FmtCtx) {
	ctx.WriteString("SET INTO ")
	ctx.FormatNode(&node.Into)
}

// SQLRight Code Injection.
func (node *AlterBackupScheduleSetInto) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.Into.LogCurrentNode(depth + 1)
	rootIR := &SQLRightIR{
		IRType:   TypeAlterBackupScheduleSetInto,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: "SET INTO ",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// AlterBackupScheduleSetWith represents an SET <options> command
type AlterBackupScheduleSetWith struct {
	With *BackupOptions
}

// Format implements the NodeFormatter interface.
func (node *AlterBackupScheduleSetWith) Format(ctx *FmtCtx) {
	ctx.WriteString("SET WITH ")
	ctx.FormatNode(node.With)
}

// SQLRight Code Injection.
func (node *AlterBackupScheduleSetWith) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.With.LogCurrentNode(depth + 1)
	rootIR := &SQLRightIR{
		IRType:   TypeAlterBackupScheduleSetWith,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: "SET WITH ",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// AlterBackupScheduleSetRecurring represents an SET RECURRING <recurrence> command
type AlterBackupScheduleSetRecurring struct {
	Recurrence Expr
}

// Format implements the NodeFormatter interface.
func (node *AlterBackupScheduleSetRecurring) Format(ctx *FmtCtx) {
	ctx.WriteString("SET RECURRING ")
	if node.Recurrence == nil {
		ctx.WriteString("NEVER")
	} else {
		ctx.FormatNode(node.Recurrence)
	}
}

// SQLRight Code Injection.
func (node *AlterBackupScheduleSetRecurring) LogCurrentNode(depth int) *SQLRightIR {

	var LNode *SQLRightIR
	infix := "NEVER"
	if node.Recurrence != nil {
		LNode = node.Recurrence.LogCurrentNode(depth + 1)
		infix = ""
	}

	rootIR := &SQLRightIR{
		IRType:   TypeAlterBackupScheduleSetRecurring,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: "SET RECURRING ",
		Infix:  infix,
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// AlterBackupScheduleSetFullBackup represents an SET FULL BACKUP <recurrence> command
type AlterBackupScheduleSetFullBackup struct {
	FullBackup FullBackupClause
}

// Format implements the NodeFormatter interface.
func (node *AlterBackupScheduleSetFullBackup) Format(ctx *FmtCtx) {
	ctx.WriteString("SET FULL BACKUP ")
	if node.FullBackup.AlwaysFull {
		ctx.WriteString("ALWAYS")
	} else {
		ctx.FormatNode(node.FullBackup.Recurrence)
	}
}

// SQLRight Code Injection.
func (node *AlterBackupScheduleSetFullBackup) LogCurrentNode(depth int) *SQLRightIR {

	var LNode *SQLRightIR
	infix := ""
	if node.FullBackup.AlwaysFull {
		// Empty. Leave LNode empty.
		infix = "ALWAYS"
	} else {
		LNode = node.FullBackup.Recurrence.LogCurrentNode(depth + 1)
	}
	rootIR := &SQLRightIR{
		IRType:   TypeAlterBackupScheduleSetFullBackup,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: "SET FULL BACKUP ",
		Infix:  infix,
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// AlterBackupScheduleSetScheduleOption represents an SET SCHEDULE OPTION <kv_options> command
type AlterBackupScheduleSetScheduleOption struct {
	Option KVOption
}

// Format implements the NodeFormatter interface.
func (node *AlterBackupScheduleSetScheduleOption) Format(ctx *FmtCtx) {
	ctx.WriteString("SET SCHEDULE OPTION ")

	// KVOption Key values never contain PII and should be distinguished
	// for feature tracking purposes.
	o := node.Option
	ctx.WithFlags(ctx.flags&^FmtMarkRedactionNode, func() {
		ctx.FormatNode(&o.Key)
	})
	if o.Value != nil {
		ctx.WriteString(` = `)
		ctx.FormatNode(o.Value)
	}
}

// SQLRight Code Injection.
func (node *AlterBackupScheduleSetScheduleOption) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.Option.LogCurrentNode(depth + 1)
	rootIR := &SQLRightIR{
		IRType:   TypeAlterBackupScheduleSetScheduleOption,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: "SET SCHEDULE OPTION ",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}
