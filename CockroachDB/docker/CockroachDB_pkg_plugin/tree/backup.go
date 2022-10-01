// Copyright 2016 The Cockroach Authors.
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
	"github.com/cockroachdb/errors"
	"github.com/google/go-cmp/cmp"
)

// DescriptorCoverage specifies the subset of descriptors that are requested during a backup
// or a restore.
type DescriptorCoverage int32

const (
	// RequestedDescriptors table coverage means that the backup is not
	// guaranteed to have all of the cluster data. This can be accomplished by
	// backing up a specific subset of tables/databases. Note that even if all
	// of the tables and databases have been included in the backup manually, a
	// backup is not said to have complete table coverage unless it was created
	// by a `BACKUP TO` command.
	RequestedDescriptors DescriptorCoverage = iota

	// AllDescriptors table coverage means that backup is guaranteed to have all the
	// relevant data in the cluster. These can only be created by running a
	// full cluster backup with `BACKUP TO`.
	AllDescriptors

	// SystemUsers coverage indicates that only the system.users
	// table will be restored from the backup.
	SystemUsers
)

// BackupOptions describes options for the BACKUP execution.
type BackupOptions struct {
	CaptureRevisionHistory Expr
	EncryptionPassphrase   Expr
	Detached               *DBool
	EncryptionKMSURI       StringOrPlaceholderOptList
	IncrementalStorage     StringOrPlaceholderOptList
}

var _ NodeFormatter = &BackupOptions{}

// Backup represents a BACKUP statement.
type Backup struct {
	Targets *BackupTargetList

	// To is set to the root directory of the backup (called the <destination> in
	// the docs).
	To StringOrPlaceholderOptList

	// IncrementalFrom is only set for the old 'BACKUP .... TO ...' syntax.
	IncrementalFrom Exprs

	AsOf    AsOfClause
	Options BackupOptions

	// Nested is set to true when the user creates a backup with
	//`BACKUP ... INTO... ` syntax.
	Nested bool

	// AppendToLatest is set to true if the user creates a backup with
	//`BACKUP...INTO LATEST...`
	AppendToLatest bool

	// Subdir may be set by the parser when the SQL query is of the form `BACKUP
	// INTO 'subdir' IN...`. Alternatively, if Nested is true but a subdir was not
	// explicitly specified by the user, then this will be set during BACKUP
	// planning once the destination has been resolved.
	Subdir Expr
}

var _ Statement = &Backup{}

// Format implements the NodeFormatter interface.
func (node *Backup) Format(ctx *FmtCtx) {
	ctx.WriteString("BACKUP ")
	if node.Targets != nil {
		ctx.FormatNode(node.Targets)
		ctx.WriteString(" ")
	}
	if node.Nested {
		ctx.WriteString("INTO ")
		if node.Subdir != nil {
			ctx.FormatNode(node.Subdir)
			ctx.WriteString(" IN ")
		} else if node.AppendToLatest {
			ctx.WriteString("LATEST IN ")
		}
	} else {
		ctx.WriteString("TO ")
	}
	ctx.FormatNode(&node.To)
	if node.AsOf.Expr != nil {
		ctx.WriteString(" ")
		ctx.FormatNode(&node.AsOf)
	}
	if node.IncrementalFrom != nil {
		ctx.WriteString(" INCREMENTAL FROM ")
		ctx.FormatNode(&node.IncrementalFrom)
	}

	if !node.Options.IsDefault() {
		ctx.WriteString(" WITH ")
		ctx.FormatNode(&node.Options)
	}
}

// SQLRight Code Injection.
func (node *Backup) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "BACKUP "
	infix := ""
	var pTargetsNode *SQLRightIR
	if node.Targets != nil {
		pTargetsNode = node.Targets.LogCurrentNode(depth + 1)
		infix = " "
	}
	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    pTargetsNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  infix,
		Suffix: "",
		Depth:  depth,
	}

	if node.Nested {
		infix = "INTO"
		if node.Subdir != nil {
			pSubdirNode := node.Subdir.LogCurrentNode(depth + 1)
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    pSubdirNode,
				Prefix:   "",
				Infix:    infix,
				Suffix:   " IN ",
				Depth:    depth,
			}
		} else if node.AppendToLatest {
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				//RNode:  subdirNode,
				Prefix: "",
				Infix:  "LATEST IN ",
				Suffix: "",
				Depth:  depth,
			}
		}
	} else {
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			//RNode:  subdirNode,
			Prefix: "",
			Infix:  "TO ",
			Suffix: "",
			Depth:  depth,
		}
	}
	pToNode := node.To.LogCurrentNode(depth + 1)
	rootIR = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    pToNode,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if node.AsOf.Expr != nil {
		pAsExprNode := node.AsOf.Expr.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    pAsExprNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.IncrementalFrom != nil {
		pIncrementalFrom := node.IncrementalFrom.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    pIncrementalFrom,
			Prefix:   "",
			Infix:    " INCREMENTAL FROM ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	if !node.Options.IsDefault() {
		pOptionsNode := node.Options.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    pOptionsNode,
			Prefix:   "",
			Infix:    " WITH ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeBackup

	return rootIR
}

// Coverage return the coverage (all vs requested).
func (node Backup) Coverage() DescriptorCoverage {
	if node.Targets == nil {
		return AllDescriptors
	}
	return RequestedDescriptors
}

// RestoreOptions describes options for the RESTORE execution.
type RestoreOptions struct {
	EncryptionPassphrase      Expr
	DecryptionKMSURI          StringOrPlaceholderOptList
	IntoDB                    Expr
	SkipMissingFKs            bool
	SkipMissingSequences      bool
	SkipMissingSequenceOwners bool
	SkipMissingViews          bool
	Detached                  bool
	SkipLocalitiesCheck       bool
	DebugPauseOn              Expr
	NewDBName                 Expr
	IncrementalStorage        StringOrPlaceholderOptList
	AsTenant                  Expr
	SchemaOnly                bool
	VerifyData                bool
}

var _ NodeFormatter = &RestoreOptions{}

// Restore represents a RESTORE statement.
type Restore struct {
	Targets            BackupTargetList
	DescriptorCoverage DescriptorCoverage

	// From contains the URIs for the backup(s) we seek to restore.
	//   - len(From)>1 implies the user explicitly passed incremental backup paths,
	//     which is only allowed using the old syntax, `RESTORE <targets> FROM <destination>.
	//     In this case, From[0] contains the URI(s) for the full backup.
	//   - len(From)==1 implies we'll have to look for incremental backups in planning
	//   - len(From[0]) > 1 implies the backups are locality aware
	//   - From[i][0] must be the default locality.
	From    []StringOrPlaceholderOptList
	AsOf    AsOfClause
	Options RestoreOptions

	// Subdir may be set by the parser when the SQL query is of the form `RESTORE
	// ... FROM 'from' IN 'subdir'...`. Alternatively, restore_planning.go will set
	// it for the query `RESTORE ... FROM 'from' IN LATEST...`
	Subdir Expr
}

var _ Statement = &Restore{}

// Format implements the NodeFormatter interface.
func (node *Restore) Format(ctx *FmtCtx) {
	ctx.WriteString("RESTORE ")
	if node.DescriptorCoverage == RequestedDescriptors {
		ctx.FormatNode(&node.Targets)
		ctx.WriteString(" ")
	}
	ctx.WriteString("FROM ")
	if node.Subdir != nil {
		ctx.FormatNode(node.Subdir)
		ctx.WriteString(" IN ")
	}
	for i := range node.From {
		if i > 0 {
			ctx.WriteString(", ")
		}
		ctx.FormatNode(&node.From[i])
	}
	if node.AsOf.Expr != nil {
		ctx.WriteString(" ")
		ctx.FormatNode(&node.AsOf)
	}
	if !node.Options.IsDefault() {
		ctx.WriteString(" WITH ")
		ctx.FormatNode(&node.Options)
	}
}

// SQLRight Code Injection.
func (node *Restore) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "RESTORE "
	infix := ""
	var pTargetNode *SQLRightIR
	if node.DescriptorCoverage == RequestedDescriptors {
		pTargetNode = node.Targets.LogCurrentNode(depth + 1)
		infix = " "
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    pTargetNode,
		//RNode:  subdirNode,
		Prefix: prefix,
		Infix:  infix,
		Suffix: "",
		Depth:  depth,
	}

	infix = "FROM "

	if node.Subdir != nil {
		subdirNode := node.Subdir.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    subdirNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   " IN ",
			Depth:    depth,
		}
		infix = " "
	}

	infix = " "
	for i := range node.From {
		fromNode := node.From[i].LogCurrentNode(depth + 1)
		if i > 0 {
			infix = ", "
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    fromNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.AsOf.Expr != nil {
		pAsOfNode := node.AsOf.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    pAsOfNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	if !node.Options.IsDefault() {
		pOptionNode := node.Options.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    pOptionNode,
			Prefix:   "",
			Infix:    " WITH ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeRestore

	return rootIR
}

// KVOption is a key-value option.
type KVOption struct {
	Key      Name
	Value    Expr
	DataType SQLRightDataType
}

// SQLRight Code Injection.
func (node *KVOption) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    node.DataType,
		ContextFlag: ContextUnknown,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Key),
	}
	LNode := tmpNode

	RNode := node.Value.LogCurrentNode(depth + 1)
	rootIR := &SQLRightIR{
		IRType:   TypeKVOption,
		DataType: node.DataType,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "",
		Infix:    " = ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// KVOptions is a list of KVOptions.
type KVOptions []KVOption

// Format implements the NodeFormatter interface.
func (o *KVOptions) Format(ctx *FmtCtx) {
	for i := range *o {
		n := &(*o)[i]
		if i > 0 {
			ctx.WriteString(", ")
		}
		// KVOption Key values never contain PII and should be distinguished
		// for feature tracking purposes.
		ctx.WithFlags(ctx.flags&^FmtMarkRedactionNode, func() {
			ctx.FormatNode(&n.Key)
		})
		if n.Value != nil {
			ctx.WriteString(` = `)
			ctx.FormatNode(n.Value)
		}
	}
}

// SQLRight Code Injection.
func (node *KVOptions) LogCurrentNode(depth int) *SQLRightIR {

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
			LNode := tmpIR
			RNode := n.LogCurrentNode(depth + 1)

			tmpIR = &SQLRightIR{
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
	tmpIR.IRType = TypeKVOptions
	return tmpIR
}

// StringOrPlaceholderOptList is a list of strings or placeholders.
type StringOrPlaceholderOptList []Expr

// Format implements the NodeFormatter interface.
func (node *StringOrPlaceholderOptList) Format(ctx *FmtCtx) {
	if len(*node) > 1 {
		ctx.WriteString("(")
	}
	ctx.FormatNode((*Exprs)(node))
	if len(*node) > 1 {
		ctx.WriteString(")")
	}
}

// SQLRight Code Injection.
func (node *StringOrPlaceholderOptList) LogCurrentNode(depth int) *SQLRightIR {

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
			prefixStr := ""
			suffixStr := ""
			if len(*node) > 1 {
				prefixStr = "("
			}
			if len(*node) == 2 {
				// if len(*node) == 1, no need to add ')'
				suffixStr = ")"
			}
			tmpIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   prefixStr,
				Infix:    " ",
				Suffix:   suffixStr,
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
			RNode := n.LogCurrentNode(depth + 1)

			tmpIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   "",
				Infix:    " ",
				Suffix:   ")", // End bracket
				Depth:    depth,
			}
		}
	}

	// Only flag the root node for the type.
	tmpIR.IRType = TypeStringOrPlaceholderOptList
	return tmpIR
}

// Format implements the NodeFormatter interface
func (o *BackupOptions) Format(ctx *FmtCtx) {
	var addSep bool
	maybeAddSep := func() {
		if addSep {
			ctx.WriteString(", ")
		}
		addSep = true
	}
	if o.CaptureRevisionHistory != nil {
		ctx.WriteString("revision_history = ")
		ctx.FormatNode(o.CaptureRevisionHistory)
		addSep = true
	}

	if o.EncryptionPassphrase != nil {
		maybeAddSep()
		ctx.WriteString("encryption_passphrase = ")
		if ctx.flags.HasFlags(FmtShowPasswords) {
			ctx.FormatNode(o.EncryptionPassphrase)
		} else {
			ctx.WriteString(PasswordSubstitution)
		}
	}

	if o.Detached == DBoolTrue {
		maybeAddSep()
		ctx.WriteString("detached")
	}

	if o.EncryptionKMSURI != nil {
		maybeAddSep()
		ctx.WriteString("kms = ")
		ctx.FormatNode(&o.EncryptionKMSURI)
	}

	if o.IncrementalStorage != nil {
		maybeAddSep()
		ctx.WriteString("incremental_location = ")
		ctx.FormatNode(&o.IncrementalStorage)
	}
}

// SQLRight Code Injection.
func (node *BackupOptions) LogCurrentNode(depth int) *SQLRightIR {

	infix := ""
	var addSep bool
	maybeAddSep := func() {
		if addSep {
			infix = ", "
		}
		addSep = true
	}

	prefix := ""
	var pCaptureNode *SQLRightIR
	if node.CaptureRevisionHistory != nil {
		prefix = "revision_history = "
		pCaptureNode = node.CaptureRevisionHistory.LogCurrentNode(depth + 1)
		addSep = true
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    pCaptureNode,
		//RNode:    fromNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	if node.EncryptionPassphrase != nil {
		maybeAddSep()
		if addSep {
			infix = ", "
		} else {
			infix = " "
		}
		infix += "encryption_passphrase = "
		passphraseNode := node.EncryptionPassphrase.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    passphraseNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}

	}

	if node.Detached == DBoolTrue {
		maybeAddSep()
		if addSep {
			infix = ", "
		} else {
			infix = " "
		}

		detachedNode := &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			//LNode:    ,
			//RNode:    RNode,
			Prefix: "detached",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    detachedNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.EncryptionKMSURI != nil {
		maybeAddSep()
		if addSep {
			infix = ", "
		} else {
			infix = " "
		}
		infix += "kms = "
		KMSURINode := node.EncryptionKMSURI.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    KMSURINode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.IncrementalStorage != nil {
		maybeAddSep()
		maybeAddSep()
		if addSep {
			infix = ", "
		} else {
			infix = " "
		}
		infix += "incremental_location = "

		incrementNode := node.IncrementalStorage.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    incrementNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}

	}

	rootIR.IRType = TypeBackupOptions
	return rootIR
}

// CombineWith merges other backup options into this backup options struct.
// An error is returned if the same option merged multiple times.
func (o *BackupOptions) CombineWith(other *BackupOptions) error {
	if o.CaptureRevisionHistory != nil {
		if other.CaptureRevisionHistory != nil {
			return errors.New("revision_history option specified multiple times")
		}
	} else {
		o.CaptureRevisionHistory = other.CaptureRevisionHistory
	}

	if o.EncryptionPassphrase == nil {
		o.EncryptionPassphrase = other.EncryptionPassphrase
	} else if other.EncryptionPassphrase != nil {
		return errors.New("encryption_passphrase specified multiple times")
	}

	if o.Detached != nil {
		if other.Detached != nil {
			return errors.New("detached option specified multiple times")
		}
	} else {
		o.Detached = other.Detached
	}

	if o.EncryptionKMSURI == nil {
		o.EncryptionKMSURI = other.EncryptionKMSURI
	} else if other.EncryptionKMSURI != nil {
		return errors.New("kms specified multiple times")
	}

	if o.IncrementalStorage == nil {
		o.IncrementalStorage = other.IncrementalStorage
	} else if other.IncrementalStorage != nil {
		return errors.New("incremental_location option specified multiple times")
	}

	return nil
}

// IsDefault returns true if this backup options struct has default value.
func (o BackupOptions) IsDefault() bool {
	options := BackupOptions{}
	return o.CaptureRevisionHistory == options.CaptureRevisionHistory &&
		o.Detached == options.Detached && cmp.Equal(o.EncryptionKMSURI, options.EncryptionKMSURI) &&
		o.EncryptionPassphrase == options.EncryptionPassphrase &&
		cmp.Equal(o.IncrementalStorage, options.IncrementalStorage)
}

// Format implements the NodeFormatter interface.
func (o *RestoreOptions) Format(ctx *FmtCtx) {
	var addSep bool
	maybeAddSep := func() {
		if addSep {
			ctx.WriteString(", ")
		}
		addSep = true
	}
	if o.EncryptionPassphrase != nil {
		addSep = true
		ctx.WriteString("encryption_passphrase = ")
		ctx.FormatNode(o.EncryptionPassphrase)
	}

	if o.DecryptionKMSURI != nil {
		maybeAddSep()
		ctx.WriteString("kms = ")
		ctx.FormatNode(&o.DecryptionKMSURI)
	}

	if o.IntoDB != nil {
		maybeAddSep()
		ctx.WriteString("into_db = ")
		ctx.FormatNode(o.IntoDB)
	}

	if o.DebugPauseOn != nil {
		maybeAddSep()
		ctx.WriteString("debug_pause_on = ")
		ctx.FormatNode(o.DebugPauseOn)
	}

	if o.SkipMissingFKs {
		maybeAddSep()
		ctx.WriteString("skip_missing_foreign_keys")
	}

	if o.SkipMissingSequenceOwners {
		maybeAddSep()
		ctx.WriteString("skip_missing_sequence_owners")
	}

	if o.SkipMissingSequences {
		maybeAddSep()
		ctx.WriteString("skip_missing_sequences")
	}

	if o.SkipMissingViews {
		maybeAddSep()
		ctx.WriteString("skip_missing_views")
	}

	if o.Detached {
		maybeAddSep()
		ctx.WriteString("detached")
	}

	if o.SkipLocalitiesCheck {
		maybeAddSep()
		ctx.WriteString("skip_localities_check")
	}

	if o.NewDBName != nil {
		maybeAddSep()
		ctx.WriteString("new_db_name = ")
		ctx.FormatNode(o.NewDBName)
	}

	if o.IncrementalStorage != nil {
		maybeAddSep()
		ctx.WriteString("incremental_location = ")
		ctx.FormatNode(&o.IncrementalStorage)
	}

	if o.AsTenant != nil {
		maybeAddSep()
		ctx.WriteString("tenant = ")
		ctx.FormatNode(o.AsTenant)
	}
	if o.SchemaOnly {
		maybeAddSep()
		ctx.WriteString("schema_only")
	}
	if o.VerifyData {
		maybeAddSep()
		ctx.WriteString("verify_backup_table_data")
	}
}

// SQLRight Code Injection.
func (node *RestoreOptions) LogCurrentNode(depth int) *SQLRightIR {

	infix := ""
	var addSep bool
	maybeAddSep := func() {
		if addSep {
			infix = ", "
		}
		addSep = true
	}

	prefix := ""
	var pEncryptionPassphrase *SQLRightIR
	if node.EncryptionPassphrase != nil {
		prefix = "encryption_passphrase = "
		pEncryptionPassphrase = node.EncryptionPassphrase.LogCurrentNode(depth + 1)
		addSep = true
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    pEncryptionPassphrase,
		//RNode:    fromNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	if node.DecryptionKMSURI != nil {
		maybeAddSep()
		if addSep {
			infix = ", "
		} else {
			infix = " "
		}
		infix += "kms = "
		KMSURINode := node.DecryptionKMSURI.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    KMSURINode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.IntoDB != nil {
		maybeAddSep()
		if addSep {
			infix = ", "
		} else {
			infix = " "
		}

		infix += "into_db = "
		intoDBNode := node.IntoDB.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    intoDBNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.DebugPauseOn != nil {

		maybeAddSep()
		if addSep {
			infix = ", "
		} else {
			infix = " "
		}

		infix += "debug_pause_on = "
		debugNode := node.DebugPauseOn.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    debugNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.SkipMissingFKs {
		maybeAddSep()
		if addSep {
			infix = ", "
		} else {
			infix = " "
		}

		infix += "skip_missing_foreign_keys"

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			//RNode:    ,
			Prefix: "",
			Infix:  infix,
			Suffix: "",
			Depth:  depth,
		}
	}

	if node.SkipMissingSequenceOwners {
		maybeAddSep()
		if addSep {
			infix = ", "
		} else {
			infix = " "
		}

		infix += "skip_missing_sequence_owners"

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			//RNode:    ,
			Prefix: "",
			Infix:  infix,
			Suffix: "",
			Depth:  depth,
		}
	}

	if node.SkipMissingSequences {
		maybeAddSep()
		if addSep {
			infix = ", "
		} else {
			infix = " "
		}

		infix += "skip_missing_sequences"

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			//RNode:    ,
			Prefix: "",
			Infix:  infix,
			Suffix: "",
			Depth:  depth,
		}
	}

	if node.SkipMissingViews {
		maybeAddSep()
		if addSep {
			infix = ", "
		} else {
			infix = " "
		}

		infix += "skip_missing_views"

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			//RNode:    ,
			Prefix: "",
			Infix:  infix,
			Suffix: "",
			Depth:  depth,
		}
	}

	if node.Detached {
		maybeAddSep()
		if addSep {
			infix = ", "
		} else {
			infix = " "
		}

		infix += "detached"

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			//RNode:    ,
			Prefix: "",
			Infix:  infix,
			Suffix: "",
			Depth:  depth,
		}

	}

	if node.SkipLocalitiesCheck {
		maybeAddSep()
		if addSep {
			infix = ", "
		} else {
			infix = " "
		}

		infix += "skip_localities_check"

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			//RNode:    ,
			Prefix: "",
			Infix:  infix,
			Suffix: "",
			Depth:  depth,
		}
	}

	if node.NewDBName != nil {

		maybeAddSep()
		if addSep {
			infix = ", "
		} else {
			infix = " "
		}

		infix += "skip_localities_check"

		newDBNode := node.NewDBName.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    newDBNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}

	}

	if node.IncrementalStorage != nil {
		maybeAddSep()
		if addSep {
			infix = ", "
		} else {
			infix = " "
		}

		infix += "incremental_location = "

		incrementNode := node.IncrementalStorage.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    incrementNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}

	}

	if node.AsTenant != nil {
		maybeAddSep()
		if addSep {
			infix = ", "
		} else {
			infix = " "
		}

		infix += "tenant = "

		tenantNode := node.AsTenant.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    tenantNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	if node.SchemaOnly {

		maybeAddSep()
		if addSep {
			infix = ", "
		} else {
			infix = " "
		}

		infix += "schema_only"

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			//RNode:    tenantNode,
			Prefix: "",
			Infix:  infix,
			Suffix: "",
			Depth:  depth,
		}
	}

	if node.VerifyData {

		maybeAddSep()
		if addSep {
			infix = ", "
		} else {
			infix = " "
		}

		infix += "verify_backup_table_data"

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeRestoreOptions

	return rootIR
}

// CombineWith merges other backup options into this backup options struct.
// An error is returned if the same option merged multiple times.
func (o *RestoreOptions) CombineWith(other *RestoreOptions) error {
	if o.EncryptionPassphrase == nil {
		o.EncryptionPassphrase = other.EncryptionPassphrase
	} else if other.EncryptionPassphrase != nil {
		return errors.New("encryption_passphrase specified multiple times")
	}

	if o.DecryptionKMSURI == nil {
		o.DecryptionKMSURI = other.DecryptionKMSURI
	} else if other.DecryptionKMSURI != nil {
		return errors.New("kms specified multiple times")
	}

	if o.IntoDB == nil {
		o.IntoDB = other.IntoDB
	} else if other.IntoDB != nil {
		return errors.New("into_db specified multiple times")
	}

	if o.SkipMissingFKs {
		if other.SkipMissingFKs {
			return errors.New("skip_missing_foreign_keys specified multiple times")
		}
	} else {
		o.SkipMissingFKs = other.SkipMissingFKs
	}

	if o.SkipMissingSequences {
		if other.SkipMissingSequences {
			return errors.New("skip_missing_sequences specified multiple times")
		}
	} else {
		o.SkipMissingSequences = other.SkipMissingSequences
	}

	if o.SkipMissingSequenceOwners {
		if other.SkipMissingSequenceOwners {
			return errors.New("skip_missing_sequence_owners specified multiple times")
		}
	} else {
		o.SkipMissingSequenceOwners = other.SkipMissingSequenceOwners
	}

	if o.SkipMissingViews {
		if other.SkipMissingViews {
			return errors.New("skip_missing_views specified multiple times")
		}
	} else {
		o.SkipMissingViews = other.SkipMissingViews
	}

	if o.Detached {
		if other.Detached {
			return errors.New("detached option specified multiple times")
		}
	} else {
		o.Detached = other.Detached
	}

	if o.SkipLocalitiesCheck {
		if other.SkipLocalitiesCheck {
			return errors.New("skip_localities_check specified multiple times")
		}
	} else {
		o.SkipLocalitiesCheck = other.SkipLocalitiesCheck
	}

	if o.DebugPauseOn == nil {
		o.DebugPauseOn = other.DebugPauseOn
	} else if other.DebugPauseOn != nil {
		return errors.New("debug_pause_on specified multiple times")
	}

	if o.NewDBName == nil {
		o.NewDBName = other.NewDBName
	} else if other.NewDBName != nil {
		return errors.New("new_db_name specified multiple times")
	}

	if o.IncrementalStorage == nil {
		o.IncrementalStorage = other.IncrementalStorage
	} else if other.IncrementalStorage != nil {
		return errors.New("incremental_location option specified multiple times")
	}

	if o.AsTenant == nil {
		o.AsTenant = other.AsTenant
	} else if other.AsTenant != nil {
		return errors.New("tenant option specified multiple times")
	}

	if o.SchemaOnly {
		if other.SchemaOnly {
			return errors.New("schema_only option specified multiple times")
		}
	} else {
		o.SchemaOnly = other.SchemaOnly
	}
	if o.VerifyData {
		if other.VerifyData {
			return errors.New("verify_backup_table_data option specified multiple times")
		}
	} else {
		o.VerifyData = other.VerifyData
	}
	return nil
}

// IsDefault returns true if this backup options struct has default value.
func (o RestoreOptions) IsDefault() bool {
	options := RestoreOptions{}
	return o.SkipMissingFKs == options.SkipMissingFKs &&
		o.SkipMissingSequences == options.SkipMissingSequences &&
		o.SkipMissingSequenceOwners == options.SkipMissingSequenceOwners &&
		o.SkipMissingViews == options.SkipMissingViews &&
		cmp.Equal(o.DecryptionKMSURI, options.DecryptionKMSURI) &&
		o.EncryptionPassphrase == options.EncryptionPassphrase &&
		o.IntoDB == options.IntoDB &&
		o.Detached == options.Detached &&
		o.SkipLocalitiesCheck == options.SkipLocalitiesCheck &&
		o.DebugPauseOn == options.DebugPauseOn &&
		o.NewDBName == options.NewDBName &&
		cmp.Equal(o.IncrementalStorage, options.IncrementalStorage) &&
		o.AsTenant == options.AsTenant &&
		o.SchemaOnly == options.SchemaOnly &&
		o.VerifyData == options.VerifyData
}

// BackupTargetList represents a list of targets.
// Only one field may be non-nil.
type BackupTargetList struct {
	Databases NameList
	Schemas   ObjectNamePrefixList
	Tables    TableAttrs
	TenantID  TenantID
}

// Format implements the NodeFormatter interface.
func (tl *BackupTargetList) Format(ctx *FmtCtx) {
	if tl.Databases != nil {
		ctx.WriteString("DATABASE ")
		ctx.FormatNode(&tl.Databases)
	} else if tl.Schemas != nil {
		ctx.WriteString("SCHEMA ")
		ctx.FormatNode(&tl.Schemas)
	} else if tl.TenantID.Specified {
		ctx.WriteString("TENANT ")
		ctx.FormatNode(&tl.TenantID)
	} else {
		if tl.Tables.SequenceOnly {
			ctx.WriteString("SEQUENCE ")
		} else {
			ctx.WriteString("TABLE ")
		}
		ctx.FormatNode(&tl.Tables.TablePatterns)
	}
}

// SQLRight Code Injection.
func (node *BackupTargetList) LogCurrentNode(depth int) *SQLRightIR {

	if node.Databases != nil {

		prefix := "DATABASE "
		databaseNode := node.Databases.LogCurrentNode(depth + 1)

		rootIR := &SQLRightIR{
			IRType:   TypeBackupTargetList,
			DataType: DataNone,
			LNode:    databaseNode,
			//RNode:    fromNode,
			Prefix: prefix,
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}

		return rootIR
	} else if node.Schemas != nil {

		prefix := "SCHEMA "
		schemaNode := node.Databases.LogCurrentNode(depth + 1)

		rootIR := &SQLRightIR{
			IRType:   TypeBackupTargetList,
			DataType: DataNone,
			LNode:    schemaNode,
			//RNode:    fromNode,
			Prefix: prefix,
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		return rootIR
	} else if node.TenantID.Specified {
		prefix := "TENANT "
		tenantNode := node.TenantID.LogCurrentNode(depth + 1)

		rootIR := &SQLRightIR{
			IRType:   TypeBackupTargetList,
			DataType: DataNone,
			LNode:    tenantNode,
			//RNode:    fromNode,
			Prefix: prefix,
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		return rootIR
	} else {
		prefix := ""
		if node.Tables.SequenceOnly {
			prefix = "SEQUENCE "
		} else {
			prefix = "TABLE "
		}
		tablepatNode := node.Tables.TablePatterns.LogCurrentNode(depth + 1)
		rootIR := &SQLRightIR{
			IRType:   TypeBackupTargetList,
			DataType: DataNone,
			LNode:    tablepatNode,
			//RNode:    fromNode,
			Prefix: prefix,
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		return rootIR
	}
}
