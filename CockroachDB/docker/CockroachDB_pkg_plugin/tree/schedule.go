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

// FullBackupClause describes the frequency of full backups.
type FullBackupClause struct {
	AlwaysFull bool
	Recurrence Expr
}

// LabelSpec describes the labeling specification for an object.
type LabelSpec struct {
	IfNotExists bool
	Label       Expr
}

// Format implements the NodeFormatter interface.
func (l *LabelSpec) Format(ctx *FmtCtx) {
	if l.IfNotExists {
		ctx.WriteString(" IF NOT EXISTS")
	}
	if l.Label != nil {
		ctx.WriteString(" ")
		ctx.FormatNode(l.Label)
	}
}

// SQLRight Code Injection.
func (node *LabelSpec) LogCurrentNode(depth int) *SQLRightIR {

	optIfNotExistStr := ""
	if node.IfNotExists {
		optIfNotExistStr = "IF NOT EXISTS "
	}
	ifNotExistsNode := &SQLRightIR{
		IRType:   TypeOptIfNotExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfNotExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	infix := ""
	var labelNode *SQLRightIR
	if node.Label != nil {
		infix = " "
		labelNode = node.Label.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		IRType:   TypeLabelSpec,
		DataType: DataNone,
		LNode:    ifNotExistsNode,
		RNode:    labelNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

var _ NodeFormatter = &LabelSpec{}

// ScheduledBackup represents scheduled backup job.
type ScheduledBackup struct {
	ScheduleLabelSpec LabelSpec
	Recurrence        Expr
	FullBackup        *FullBackupClause /* nil implies choose default */
	Targets           *BackupTargetList /* nil implies tree.AllDescriptors coverage */
	To                StringOrPlaceholderOptList
	BackupOptions     BackupOptions
	ScheduleOptions   KVOptions
}

var _ Statement = &ScheduledBackup{}

// Format implements the NodeFormatter interface.
func (node *ScheduledBackup) Format(ctx *FmtCtx) {
	ctx.WriteString("CREATE SCHEDULE")

	ctx.FormatNode(&node.ScheduleLabelSpec)
	ctx.WriteString(" FOR BACKUP")
	if node.Targets != nil {
		ctx.WriteString(" ")
		ctx.FormatNode(node.Targets)
	}

	ctx.WriteString(" INTO ")
	ctx.FormatNode(&node.To)

	if !node.BackupOptions.IsDefault() {
		ctx.WriteString(" WITH ")
		ctx.FormatNode(&node.BackupOptions)
	}

	ctx.WriteString(" RECURRING ")
	if node.Recurrence == nil {
		ctx.WriteString("NEVER")
	} else {
		ctx.FormatNode(node.Recurrence)
	}

	if node.FullBackup != nil {

		if node.FullBackup.Recurrence != nil {
			ctx.WriteString(" FULL BACKUP ")
			ctx.FormatNode(node.FullBackup.Recurrence)
		} else if node.FullBackup.AlwaysFull {
			ctx.WriteString(" FULL BACKUP ALWAYS")
		}
	}

	if node.ScheduleOptions != nil {
		ctx.WriteString(" WITH SCHEDULE OPTIONS ")
		ctx.FormatNode(&node.ScheduleOptions)
	}
}

// SQLRight Code Injection.
func (node *ScheduledBackup) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "CREATE SCHEDULE"

	pScheduleSchNode := node.ScheduleLabelSpec.LogCurrentNode(depth + 1)

	infix := " FOR BACKUP"

	var pTargetNode *SQLRightIR
	if node.Targets != nil {
		infix += " "
		pTargetNode = node.Targets.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    pScheduleSchNode,
		RNode:    pTargetNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	pToNode := node.To.LogCurrentNode(depth + 1)

	rootIR = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    pToNode,
		Prefix:   "",
		Infix:    " INTO ",
		Suffix:   "",
		Depth:    depth,
	}

	if !node.BackupOptions.IsDefault() {
		infix = " WITH "
		pBackupOptions := node.BackupOptions.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    pBackupOptions,
			Prefix:   "",
			Infix:    " WITH ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	infix = " RECURRING "
	if node.Recurrence == nil {
		recurrenceNode := &SQLRightIR{
			IRType:   TypeRecurrence,
			DataType: DataNone,
			//LNode:    ,
			//RNode:    RNode,
			Prefix: " NEVER ",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    recurrenceNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	} else {
		pRecurrenceNode := node.Recurrence.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeRecurrence,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    pRecurrenceNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.FullBackup != nil {
		infix = ""
		if node.FullBackup.Recurrence != nil {
			infix = " FULL BACKUP "
			pRecurrenceNode := node.FullBackup.Recurrence.LogCurrentNode(depth + 1)

			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    pRecurrenceNode,
				Prefix:   "",
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}

		} else if node.FullBackup.AlwaysFull {
			recurrenceNode := &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				//LNode:    ,
				//RNode:    RNode,
				Prefix: " FULL BACKUP ALWAYS",
				Infix:  "",
				Suffix: "",
				Depth:  depth,
			}

			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    recurrenceNode,
				Prefix:   "",
				Infix:    infix,
				Suffix:   "",
				Depth:    depth,
			}
		}
	}

	if node.ScheduleOptions != nil {
		infix = " WITH SCHEDULE OPTIONS "
		schedleOptionNode := node.ScheduleOptions.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    schedleOptionNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeScheduledBackup
	return rootIR
}

// Coverage return the coverage (all vs requested).
func (node ScheduledBackup) Coverage() DescriptorCoverage {
	if node.Targets == nil {
		return AllDescriptors
	}
	return RequestedDescriptors
}
