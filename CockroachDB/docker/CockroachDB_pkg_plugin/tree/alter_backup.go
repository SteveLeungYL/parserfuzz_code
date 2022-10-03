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

// AlterBackup represents an ALTER BACKUP statement.
type AlterBackup struct {
	// Backup contains the locations for the backup we seek to add new keys to.
	Backup Expr
	Subdir Expr
	Cmds   AlterBackupCmds
}

var _ Statement = &AlterBackup{}

// Format implements the NodeFormatter interface.
func (node *AlterBackup) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER BACKUP ")

	if node.Subdir != nil {
		ctx.FormatNode(node.Subdir)
		ctx.WriteString(" IN ")
	}

	ctx.FormatNode(node.Backup)
	ctx.FormatNode(&node.Cmds)
}

// SQLRight Code Injection.
func (node *AlterBackup) LogCurrentNode(depth int) *SQLRightIR {

	var rootIR *SQLRightIR
	if node.Subdir != nil {

		LNode := node.Subdir.LogCurrentNode(depth + 1)
		RNode := node.Backup.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    LNode,
			RNode:    RNode,
			Prefix:   "ALTER BACKUP ",
			Infix:    " IN ",
			Suffix:   "",
			Depth:    depth,
		}

		RNode = node.Cmds.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeAlterBackup,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    RNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

	} else {
		// node.Subdir == nil

		LNode := node.Backup.LogCurrentNode(depth + 1)
		RNode := node.Cmds.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeAlterBackup,
			DataType: DataNone,
			LNode:    LNode,
			RNode:    RNode,
			Prefix:   "ALTER BACKUP ",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	return rootIR
}

// AlterBackupCmds is an array of type AlterBackupCmd
type AlterBackupCmds []AlterBackupCmd

// Format implements the NodeFormatter interface.
func (node *AlterBackupCmds) Format(ctx *FmtCtx) {
	for i, n := range *node {
		if i > 0 {
			ctx.WriteString(" ")
		}
		ctx.FormatNode(n)
	}
}

// SQLRight Code Injection.
func (node *AlterBackupCmds) LogCurrentNode(depth int) *SQLRightIR {

	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{}
	for i, n := range *node {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n.LogCurrentNode(depth + 1)
			var RNode *SQLRightIR
			if len(*node) >= 2 {
				RNode = (*node)[1].LogCurrentNode(depth + 1)
			}
			tmpIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   "",
				Infix:    " ",
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
				Infix:    " ",
				Suffix:   "",
				Depth:    depth,
			}
		}
	}

	// Only flag the root node for the type.
	tmpIR.IRType = TypeAlterBackupCmds
	return tmpIR
}

// AlterBackupCmd represents a backup modification operation.
type AlterBackupCmd interface {
	NodeFormatter
	SQLRightInterface
	alterBackupCmd()
}

func (node *AlterBackupKMS) alterBackupCmd() {}

var _ AlterBackupCmd = &AlterBackupKMS{}

// AlterBackupKMS represents a possible alter_backup_cmd option.
type AlterBackupKMS struct {
	KMSInfo BackupKMS
}

// Format implements the NodeFormatter interface.
func (node *AlterBackupKMS) Format(ctx *FmtCtx) {
	ctx.WriteString(" ADD NEW_KMS=")
	ctx.FormatNode(&node.KMSInfo.NewKMSURI)

	ctx.WriteString(" WITH OLD_KMS=")
	ctx.FormatNode(&node.KMSInfo.OldKMSURI)
}

// SQLRight Code Injection.
func (node *AlterBackupKMS) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.KMSInfo.LogCurrentNode(depth + 1)
	rootIR := &SQLRightIR{
		IRType:   TypeAlterBackupKMS,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: "ADD ",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// BackupKMS represents possible options used when altering a backup KMS
type BackupKMS struct {
	NewKMSURI StringOrPlaceholderOptList
	OldKMSURI StringOrPlaceholderOptList
}

// SQLRight Code Injection.
func (node *BackupKMS) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.NewKMSURI.LogCurrentNode(depth + 1)
	RNode := node.OldKMSURI.LogCurrentNode(depth + 1)
	rootIR := &SQLRightIR{
		IRType:   TypeBackupKMS,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "NEW_KMS=",
		Infix:    " WITH OLD_KMS=",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}
