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

import (
	"fmt"
	"github.com/cockroachdb/cockroach/pkg/sql/lexbase"
	"strconv"
)

// ShowVar represents a SHOW statement.
type ShowVar struct {
	Name string
}

// Format implements the NodeFormatter interface.
func (node *ShowVar) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW ")
	// Session var names never contain PII and should be distinguished
	// for feature tracking purposes.
	ctx.WithFlags(ctx.flags & ^FmtAnonymize & ^FmtMarkRedactionNode, func() {
		ctx.FormatNameP(&node.Name)
	})
}

// SQLRight Code Injection.
func (node *ShowVar) LogCurrentNode(depth int) *SQLRightIR {

	nameNode := &SQLRightIR{
		NodeHash:    169605,
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
		NodeHash: 17137,
		IRType:   TypeShowVar,
		DataType: DataNone,
		Prefix:   "SHOW ",
		LNode:    nameNode,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowClusterSetting represents a SHOW CLUSTER SETTING statement.
type ShowClusterSetting struct {
	Name string
}

// Format implements the NodeFormatter interface.
func (node *ShowClusterSetting) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW CLUSTER SETTING ")
	// Cluster setting names never contain PII and should be distinguished
	// for feature tracking purposes.
	ctx.WithFlags(ctx.flags & ^FmtAnonymize & ^FmtMarkRedactionNode, func() {
		ctx.FormatNameP(&node.Name)
	})
}

// SQLRight Code Injection.
func (node *ShowClusterSetting) LogCurrentNode(depth int) *SQLRightIR {

	nameNode := &SQLRightIR{
		NodeHash:    183441,
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
		NodeHash: 144826,
		IRType:   TypeShowClusterSetting,
		DataType: DataNone,
		Prefix:   "SHOW CLUSTER SETTING ",
		LNode:    nameNode,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowClusterSettingList represents a SHOW [ALL|PUBLIC] CLUSTER SETTINGS statement.
type ShowClusterSettingList struct {
	// All indicates whether to include non-public settings in the output.
	All bool
}

// Format implements the NodeFormatter interface.
func (node *ShowClusterSettingList) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW ")
	qual := "PUBLIC"
	if node.All {
		qual = "ALL"
	}
	ctx.WriteString(qual)
	ctx.WriteString(" CLUSTER SETTINGS")
}

// SQLRight Code Injection.
func (node *ShowClusterSettingList) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW "

	qual := "PUBLIC"
	if node.All {
		qual = "ALL"
	}

	prefix += qual

	prefix += " CLUSTER SETTINGS"

	rootIR := &SQLRightIR{
		NodeHash: 187520,
		IRType:   TypeShowClusterSettingList,
		DataType: DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowBackupDetails represents the type of details to display for a SHOW BACKUP
// statement.
type ShowBackupDetails int

const (
	// BackupDefaultDetails identifies a bare SHOW BACKUP statement.
	BackupDefaultDetails ShowBackupDetails = iota
	// BackupRangeDetails identifies a SHOW BACKUP RANGES statement.
	BackupRangeDetails
	// BackupFileDetails identifies a SHOW BACKUP FILES statement.
	BackupFileDetails
	// BackupSchemaDetails identifies a SHOW BACKUP SCHEMAS statement.
	BackupSchemaDetails
	// BackupValidateDetails identifies a SHOW BACKUP VALIDATION
	// statement.
	BackupValidateDetails
)

// TODO (msbutler): 22.2 after removing old style show backup syntax, rename
// Path to Subdir and InCollection to Dest.

// ShowBackup represents a SHOW BACKUP statement.
type ShowBackup struct {
	Path         Expr
	InCollection StringOrPlaceholderOptList
	From         bool
	Details      ShowBackupDetails
	Options      KVOptions
}

// Format implements the NodeFormatter interface.
func (node *ShowBackup) Format(ctx *FmtCtx) {
	if node.InCollection != nil && node.Path == nil {
		ctx.WriteString("SHOW BACKUPS IN ")
		ctx.FormatNode(&node.InCollection)
		return
	}
	ctx.WriteString("SHOW BACKUP ")

	switch node.Details {
	case BackupRangeDetails:
		ctx.WriteString("RANGES ")
	case BackupFileDetails:
		ctx.WriteString("FILES ")
	case BackupSchemaDetails:
		ctx.WriteString("SCHEMAS ")
	}

	if node.From {
		ctx.WriteString("FROM ")
	}

	ctx.FormatNode(node.Path)
	if node.InCollection != nil {
		ctx.WriteString(" IN ")
		ctx.FormatNode(&node.InCollection)
	}
	if len(node.Options) > 0 {
		ctx.WriteString(" WITH ")
		ctx.FormatNode(&node.Options)
	}
}

// SQLRight Code Injection.
func (node *ShowBackup) LogCurrentNode(depth int) *SQLRightIR {

	if node.InCollection != nil && node.Path == nil {
		inCollectionNode := node.InCollection.LogCurrentNode(depth + 1)

		rootIR := &SQLRightIR{
			NodeHash: 220014,
			IRType:   TypeShowBackup,
			DataType: DataNone,
			LNode:    inCollectionNode,
			//RNode:,
			Prefix: "SHOW BACKUPS IN ",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
		return rootIR
	}

	prefix := "SHOW BACKUP "

	switch node.Details {
	case BackupRangeDetails:
		prefix += "RANGES "
	case BackupFileDetails:
		prefix += "FILES "
	case BackupSchemaDetails:
		prefix += "SCHEMAS "
	}

	if node.From {
		prefix += "FROM "
	}

	pathNode := node.Path.LogCurrentNode(depth + 1)

	var pInCollectionNode *SQLRightIR
	infix := ""
	if node.InCollection != nil {
		infix = " IN "
		pInCollectionNode = node.InCollection.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		NodeHash: 59578,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    pathNode,
		RNode:    pInCollectionNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	if len(node.Options) > 0 {
		infix = "WITH"
		optionNode := node.Options.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			NodeHash: 180502,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optionNode,
			Prefix:   "",
			Infix:    " WITH ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeShowBackup

	return rootIR
}

// ShowColumns represents a SHOW COLUMNS statement.
type ShowColumns struct {
	Table       *UnresolvedObjectName
	WithComment bool
}

// Format implements the NodeFormatter interface.
func (node *ShowColumns) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW COLUMNS FROM ")
	ctx.FormatNode(node.Table)

	if node.WithComment {
		ctx.WriteString(" WITH COMMENT")
	}
}

// SQLRight Code Injection.
func (node *ShowColumns) LogCurrentNode(depth int) *SQLRightIR {

	nameNode := &SQLRightIR{
		NodeHash:    164973,
		IRType:      TypeIdentifier,
		DataType:    DataTableName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Table.String(),
	}

	infix := ""
	if node.WithComment {
		infix = " WITH COMMENT"
	}

	rootIR := &SQLRightIR{
		NodeHash: 135619,
		IRType:   TypeShowColumns,
		DataType: DataNone,
		LNode:    nameNode,
		Prefix:   "SHOW COLUMNS FROM ",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowDatabases represents a SHOW DATABASES statement.
type ShowDatabases struct {
	WithComment bool
}

// Format implements the NodeFormatter interface.
func (node *ShowDatabases) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW DATABASES")

	if node.WithComment {
		ctx.WriteString(" WITH COMMENT")
	}
}

// SQLRight Code Injection.
func (node *ShowDatabases) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW DATABASES"

	if node.WithComment {
		prefix += " WITH COMMENT"
	}

	rootIR := &SQLRightIR{
		NodeHash: 243003,
		IRType:   TypeShowDatabases,
		DataType: DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowEnums represents a SHOW ENUMS statement.
type ShowEnums struct {
	ObjectNamePrefix
}

// Format implements the NodeFormatter interface.
func (node *ShowEnums) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW ENUMS")
}

// SQLRight Code Injection.
func (node *ShowEnums) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW ENUMS"

	rootIR := &SQLRightIR{
		NodeHash: 119287,
		IRType:   TypeShowEnums,
		DataType: DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowTypes represents a SHOW TYPES statement.
type ShowTypes struct{}

// Format implements the NodeFormatter interface.
func (node *ShowTypes) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW TYPES")
}

// SQLRight Code Injection.
func (node *ShowTypes) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW TYPES"

	rootIR := &SQLRightIR{
		NodeHash: 80720,
		IRType:   TypeShowTypes,
		DataType: DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowTraceType is an enum of SHOW TRACE variants.
type ShowTraceType string

// A list of the SHOW TRACE variants.
const (
	ShowTraceRaw     ShowTraceType = "TRACE"
	ShowTraceKV      ShowTraceType = "KV TRACE"
	ShowTraceReplica ShowTraceType = "EXPERIMENTAL_REPLICA TRACE"
)

// ShowTraceForSession represents a SHOW TRACE FOR SESSION statement.
type ShowTraceForSession struct {
	TraceType ShowTraceType
	Compact   bool
}

// Format implements the NodeFormatter interface.
func (node *ShowTraceForSession) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW ")
	if node.Compact {
		ctx.WriteString("COMPACT ")
	}
	ctx.WriteString(string(node.TraceType))
	ctx.WriteString(" FOR SESSION")
}

// SQLRight Code Injection.
func (node *ShowTraceForSession) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW "

	if node.Compact {
		prefix += "COMPACT "
	}

	prefix += string(node.TraceType)

	prefix += " FOR SESSION"

	rootIR := &SQLRightIR{
		NodeHash: 173776,
		IRType:   TypeShowTraceForSession,
		DataType: DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowIndexes represents a SHOW INDEX statement.
type ShowIndexes struct {
	Table       *UnresolvedObjectName
	WithComment bool
}

// Format implements the NodeFormatter interface.
func (node *ShowIndexes) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW INDEXES FROM ")
	ctx.FormatNode(node.Table)

	if node.WithComment {
		ctx.WriteString(" WITH COMMENT")
	}
}

// SQLRight Code Injection.
func (node *ShowIndexes) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW INDEXES FROM "

	tableNameNode := &SQLRightIR{
		NodeHash:    259480,
		IRType:      TypeIdentifier,
		DataType:    DataTableName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Table.String(),
	}

	infix := ""
	if node.WithComment {
		infix = " WITH COMMENT"
	}

	rootIR := &SQLRightIR{
		NodeHash: 258694,
		IRType:   TypeShowIndexes,
		DataType: DataNone,
		LNode:    tableNameNode,
		//RNode:
		Prefix: prefix,
		Infix:  infix,
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// ShowDatabaseIndexes represents a SHOW INDEXES FROM DATABASE statement.
type ShowDatabaseIndexes struct {
	Database    Name
	WithComment bool
}

// Format implements the NodeFormatter interface.
func (node *ShowDatabaseIndexes) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW INDEXES FROM DATABASE ")
	ctx.FormatNode(&node.Database)

	if node.WithComment {
		ctx.WriteString(" WITH COMMENT")
	}
}

// SQLRight Code Injection.
func (node *ShowDatabaseIndexes) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW INDEXES FROM DATABASE "

	databaseName := &SQLRightIR{
		NodeHash:    204560,
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Database.String(),
	}

	infix := ""
	if node.WithComment {
		infix = " WITH COMMENT"
	}

	rootIR := &SQLRightIR{
		NodeHash: 231643,
		IRType:   TypeShowDatabaseIndexes,
		DataType: DataNone,
		LNode:    databaseName,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowQueries represents a SHOW STATEMENTS statement.
type ShowQueries struct {
	All     bool
	Cluster bool
}

// Format implements the NodeFormatter interface.
func (node *ShowQueries) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW ")
	if node.All {
		ctx.WriteString("ALL ")
	}
	if node.Cluster {
		ctx.WriteString("CLUSTER STATEMENTS")
	} else {
		ctx.WriteString("LOCAL STATEMENTS")
	}
}

// SQLRight Code Injection.
func (node *ShowQueries) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW "

	if node.All {
		prefix += "ALL "
	}
	if node.Cluster {
		prefix += "CLUSTER STATEMENTS"
	} else {
		prefix += "LOCAL STATEMENTS"
	}

	rootIR := &SQLRightIR{
		NodeHash: 11854,
		IRType:   TypeShowQueries,
		DataType: DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowJobs represents a SHOW JOBS statement
type ShowJobs struct {
	// If non-nil, a select statement that provides the job ids to be shown.
	Jobs *Select

	// If Automatic is true, show only automatically-generated jobs such
	// as automatic CREATE STATISTICS jobs. If Automatic is false, show
	// only non-automatically-generated jobs.
	Automatic bool

	// Whether to block and wait for completion of all running jobs to be displayed.
	Block bool

	// If non-nil, only display jobs started by the specified
	// schedules.
	Schedules *Select
}

// Format implements the NodeFormatter interface.
func (node *ShowJobs) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW ")
	if node.Automatic {
		ctx.WriteString("AUTOMATIC ")
	}
	ctx.WriteString("JOBS")
	if node.Block {
		ctx.WriteString(" WHEN COMPLETE")
	}
	if node.Jobs != nil {
		ctx.WriteString(" ")
		ctx.FormatNode(node.Jobs)
	}
	if node.Schedules != nil {
		ctx.WriteString(" FOR SCHEDULES ")
		ctx.FormatNode(node.Schedules)
	}
}

// SQLRight Code Injection.
func (node *ShowJobs) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW "
	if node.Automatic {
		prefix += "AUTOMATIC "
	}
	prefix += "JOBS"

	if node.Block {
		prefix += " WHEN COMPLETE "
	}

	var jobNode *SQLRightIR
	if node.Jobs != nil {
		jobNode = node.Jobs.LogCurrentNode(depth + 1)
	}

	var scheduleNode *SQLRightIR
	infix := ""
	if node.Schedules != nil {
		infix = " FOR SCHEDULES "
		scheduleNode = node.Schedules.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		NodeHash: 205695,
		IRType:   TypeShowJobs,
		DataType: DataNone,
		LNode:    jobNode,
		RNode:    scheduleNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowChangefeedJobs represents a SHOW CHANGEFEED JOBS statement
type ShowChangefeedJobs struct {
	// If non-nil, a select statement that provides the job ids to be shown.
	Jobs *Select
}

// Format implements the NodeFormatter interface.
func (node *ShowChangefeedJobs) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW CHANGEFEED JOBS")
	if node.Jobs != nil {
		ctx.WriteString(" ")
		ctx.FormatNode(node.Jobs)
	}
}

// SQLRight Code Injection.
func (node *ShowChangefeedJobs) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW CHANGEFEED JOBS "

	var jobNode *SQLRightIR
	if node.Jobs != nil {
		jobNode = node.Jobs.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		NodeHash: 16259,
		IRType:   TypeShowChangefeedJobs,
		DataType: DataNone,
		LNode:    jobNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowSurvivalGoal represents a SHOW REGIONS statement
type ShowSurvivalGoal struct {
	DatabaseName Name
}

// Format implements the NodeFormatter interface.
func (node *ShowSurvivalGoal) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW SURVIVAL GOAL FROM DATABASE")
	if node.DatabaseName != "" {
		ctx.WriteString(" ")
		ctx.FormatNode(&node.DatabaseName)
	}
}

// SQLRight Code Injection.
func (node *ShowSurvivalGoal) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW SURVIVAL GOAL FROM DATABASE "

	var databaseNode *SQLRightIR
	if node.DatabaseName != "" {
		tmpNode := &SQLRightIR{
			NodeHash:    34754,
			IRType:      TypeIdentifier,
			DataType:    DataDatabaseName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.DatabaseName.String(),
		}
		databaseNode = tmpNode
	}

	rootIR := &SQLRightIR{
		NodeHash: 245768,
		IRType:   TypeShowSurvivalGoal,
		DataType: DataNone,
		LNode:    databaseNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowRegionsFrom denotes what kind of SHOW REGIONS command is being used.
type ShowRegionsFrom int

const (
	// ShowRegionsFromCluster represents SHOW REGIONS FROM CLUSTER.
	ShowRegionsFromCluster ShowRegionsFrom = iota
	// ShowRegionsFromDatabase represents SHOW REGIONS FROM DATABASE.
	ShowRegionsFromDatabase
	// ShowRegionsFromAllDatabases represents SHOW REGIONS FROM ALL DATABASES.
	ShowRegionsFromAllDatabases
	// ShowRegionsFromDefault represents SHOW REGIONS.
	ShowRegionsFromDefault
	// ShowSuperRegionsFromDatabase represents SHOW SUPER REGIONS FROM DATABASE.
	ShowSuperRegionsFromDatabase
)

// ShowRegions represents a SHOW REGIONS statement
type ShowRegions struct {
	ShowRegionsFrom ShowRegionsFrom
	DatabaseName    Name
}

// Format implements the NodeFormatter interface.
func (node *ShowRegions) Format(ctx *FmtCtx) {
	if node.ShowRegionsFrom == ShowSuperRegionsFromDatabase {
		ctx.WriteString("SHOW SUPER REGIONS")
	} else {
		ctx.WriteString("SHOW REGIONS")
	}
	switch node.ShowRegionsFrom {
	case ShowRegionsFromDefault:
	case ShowRegionsFromAllDatabases:
		ctx.WriteString(" FROM ALL DATABASES")
	case ShowRegionsFromDatabase, ShowSuperRegionsFromDatabase:
		ctx.WriteString(" FROM DATABASE")
		if node.DatabaseName != "" {
			ctx.WriteString(" ")
			ctx.FormatNode(&node.DatabaseName)
		}
	case ShowRegionsFromCluster:
		ctx.WriteString(" FROM CLUSTER")
	default:
		panic(fmt.Sprintf("unknown ShowRegionsFrom: %v", node.ShowRegionsFrom))
	}
}

// SQLRight Code Injection.
func (node *ShowRegions) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""
	if node.ShowRegionsFrom == ShowSuperRegionsFromDatabase {
		prefix += "SHOW SUPER REGIONS"
	} else {
		prefix += "SHOW REGIONS"
	}

	var databaseNode *SQLRightIR
	switch node.ShowRegionsFrom {
	case ShowRegionsFromDefault:
	case ShowRegionsFromAllDatabases:
		prefix += " FROM ALL DATABASES"
	case ShowRegionsFromDatabase, ShowSuperRegionsFromDatabase:
		prefix += " FROM DATABASE "
		if node.DatabaseName != "" {
			tmpDatabaseNode := &SQLRightIR{
				NodeHash:    231123,
				IRType:      TypeIdentifier,
				DataType:    DataDatabaseName,
				ContextFlag: ContextUse,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         node.DatabaseName.String(),
			}
			databaseNode = tmpDatabaseNode
		}
	case ShowRegionsFromCluster:
		prefix += " FROM CLUSTER"
	default:
		panic(fmt.Sprintf("unknown ShowRegionsFrom: %v", node.ShowRegionsFrom))
	}

	rootIR := &SQLRightIR{
		NodeHash: 41102,
		IRType:   TypeShowRegions,
		DataType: DataNone,
		LNode:    databaseNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowSessions represents a SHOW SESSIONS statement
type ShowSessions struct {
	All     bool
	Cluster bool
}

// Format implements the NodeFormatter interface.
func (node *ShowSessions) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW ")
	if node.All {
		ctx.WriteString("ALL ")
	}
	if node.Cluster {
		ctx.WriteString("CLUSTER SESSIONS")
	} else {
		ctx.WriteString("LOCAL SESSIONS")
	}
}

// SQLRight Code Injection.
func (node *ShowSessions) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW "
	if node.All {
		prefix += "ALL "
	}

	if node.Cluster {
		prefix += "CLUSTER SESSIONS"
	} else {
		prefix += "LOCAL SESSIONS"
	}

	rootIR := &SQLRightIR{
		NodeHash: 238246,
		IRType:   TypeShowSessions,
		DataType: DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowSchemas represents a SHOW SCHEMAS statement.
type ShowSchemas struct {
	Database Name
}

// Format implements the NodeFormatter interface.
func (node *ShowSchemas) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW SCHEMAS")
	if node.Database != "" {
		ctx.WriteString(" FROM ")
		ctx.FormatNode(&node.Database)
	}
}

// SQLRight Code Injection.
func (node *ShowSchemas) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW SCHEMAS"

	var pDatabaseNode *SQLRightIR
	if node.Database != "" {
		prefix += " FROM "
		dataNode := &SQLRightIR{
			NodeHash:    50011,
			IRType:      TypeIdentifier,
			DataType:    DataDatabaseName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Database.String(),
		}
		pDatabaseNode = dataNode
	}

	rootIR := &SQLRightIR{
		NodeHash: 172932,
		IRType:   TypeShowSchemas,
		DataType: DataNone,
		LNode:    pDatabaseNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowSequences represents a SHOW SEQUENCES statement.
type ShowSequences struct {
	Database Name
}

// Format implements the NodeFormatter interface.
func (node *ShowSequences) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW SEQUENCES")
	if node.Database != "" {
		ctx.WriteString(" FROM ")
		ctx.FormatNode(&node.Database)
	}
}

// SQLRight Code Injection.
func (node *ShowSequences) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW SEQUENCES"

	var pDatabaseNode *SQLRightIR
	if node.Database != "" {
		prefix += " FROM "
		dataNode := &SQLRightIR{
			NodeHash:    47036,
			IRType:      TypeIdentifier,
			DataType:    DataDatabaseName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Database.String(),
		}
		pDatabaseNode = dataNode
	}

	rootIR := &SQLRightIR{
		NodeHash: 131581,
		IRType:   TypeShowSequences,
		DataType: DataNone,
		LNode:    pDatabaseNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowTables represents a SHOW TABLES statement.
type ShowTables struct {
	ObjectNamePrefix
	WithComment bool
}

// Format implements the NodeFormatter interface.
func (node *ShowTables) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW TABLES")
	if node.ExplicitSchema {
		ctx.WriteString(" FROM ")
		ctx.FormatNode(&node.ObjectNamePrefix)
	}

	if node.WithComment {
		ctx.WriteString(" WITH COMMENT")
	}
}

// SQLRight Code Injection.
func (node *ShowTables) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW TABLES"

	var pDatabaseNode *SQLRightIR
	if node.ExplicitSchema {
		prefix += " FROM "
		dataNode := &SQLRightIR{
			NodeHash:    215698,
			IRType:      TypeIdentifier,
			DataType:    DataSchemaName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.ObjectNamePrefix.String(),
		}
		pDatabaseNode = dataNode
	}

	infix := ""
	if node.WithComment {
		infix = " WITH COMMENT"
	}

	rootIR := &SQLRightIR{
		NodeHash: 31889,
		IRType:   TypeShowTables,
		DataType: DataNone,
		LNode:    pDatabaseNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowTransactions represents a SHOW TRANSACTIONS statement
type ShowTransactions struct {
	All     bool
	Cluster bool
}

// Format implements the NodeFormatter interface.
func (node *ShowTransactions) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW ")
	if node.All {
		ctx.WriteString("ALL ")
	}
	if node.Cluster {
		ctx.WriteString("CLUSTER TRANSACTIONS")
	} else {
		ctx.WriteString("LOCAL TRANSACTIONS")
	}
}

// SQLRight Code Injection.
func (node *ShowTransactions) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW "
	if node.All {
		prefix += "ALL "
	}
	if node.Cluster {
		prefix += "CLUSTER TRANSACTIONS"
	} else {
		prefix += "LOCAL TRANSACTIONS"
	}

	rootIR := &SQLRightIR{
		NodeHash: 260965,
		IRType:   TypeShowTransactions,
		DataType: DataNone,
		//LNode:    ,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// ShowConstraints represents a SHOW CONSTRAINTS statement.
type ShowConstraints struct {
	Table       *UnresolvedObjectName
	WithComment bool
}

// Format implements the NodeFormatter interface.
func (node *ShowConstraints) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW CONSTRAINTS FROM ")
	ctx.FormatNode(node.Table)

	if node.WithComment {
		ctx.WriteString(" WITH COMMENT")
	}
}

// SQLRight Code Injection.
func (node *ShowConstraints) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW CONSTRAINTS FROM "

	var pTableNode *SQLRightIR
	tableNode := &SQLRightIR{
		NodeHash:    192403,
		IRType:      TypeIdentifier,
		DataType:    DataTableName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Table.String(),
	}
	pTableNode = tableNode

	infix := ""
	if node.WithComment {
		infix = " WITH COMMENT"
	}

	rootIR := &SQLRightIR{
		NodeHash: 75464,
		IRType:   TypeShowConstraints,
		DataType: DataNone,
		LNode:    pTableNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowGrants represents a SHOW GRANTS statement.
// GrantTargetList is defined in grant.go.
type ShowGrants struct {
	Targets  *GrantTargetList
	Grantees RoleSpecList
}

// Format implements the NodeFormatter interface.
func (node *ShowGrants) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW ")
	if node.Targets != nil && node.Targets.System {
		ctx.WriteString("SYSTEM ")
	}
	ctx.WriteString("GRANTS")
	if node.Targets != nil {
		if !node.Targets.System {
			ctx.WriteString(" ON ")
			ctx.FormatNode(node.Targets)
		}
	}
	if node.Grantees != nil {
		ctx.WriteString(" FOR ")
		ctx.FormatNode(&node.Grantees)
	}
}

// SQLRight Code Injection.
func (node *ShowGrants) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW "

	if node.Targets != nil && node.Targets.System {
		prefix += "SYSTEM "
	}

	prefix += "GRANTS"

	var pTargetNode *SQLRightIR
	if node.Targets != nil {
		if !node.Targets.System {
			prefix += " ON "
			pTargetNode = node.Targets.LogCurrentNode(depth + 1)
		}
	}

	rootIR := &SQLRightIR{
		NodeHash: 178530,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    pTargetNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if node.Grantees != nil {
		infix := " FOR "
		grantNode := node.Grantees.LogCurrentNode(depth+1, ContextUse)

		rootIR = &SQLRightIR{
			NodeHash: 81255,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    grantNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeShowGrants

	return rootIR
}

// ShowRoleGrants represents a SHOW GRANTS ON ROLE statement.
type ShowRoleGrants struct {
	Roles    RoleSpecList
	Grantees RoleSpecList
}

// Format implements the NodeFormatter interface.
func (node *ShowRoleGrants) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW GRANTS ON ROLE")
	if node.Roles != nil {
		ctx.WriteString(" ")
		ctx.FormatNode(&node.Roles)
	}
	if node.Grantees != nil {
		ctx.WriteString(" FOR ")
		ctx.FormatNode(&node.Grantees)
	}
}

// SQLRight Code Injection.
func (node *ShowRoleGrants) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW GRANTS ON ROLE "

	var pRoleNode *SQLRightIR
	if node.Roles != nil {
		pRoleNode = node.Roles.LogCurrentNode(depth+1, ContextUse)
	}

	rootIR := &SQLRightIR{
		NodeHash: 63767,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    pRoleNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	if node.Grantees != nil {
		infix := " FOR "
		grantNode := node.Grantees.LogCurrentNode(depth+1, ContextUse)

		rootIR = &SQLRightIR{
			NodeHash: 30747,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    grantNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}

	}

	rootIR.IRType = TypeShowRoleGrants

	return rootIR
}

// ShowCreateMode denotes what kind of SHOW CREATE should be used
type ShowCreateMode int

const (
	// ShowCreateModeTable represents SHOW CREATE TABLE
	ShowCreateModeTable ShowCreateMode = iota
	// ShowCreateModeView represents SHOW CREATE VIEW
	ShowCreateModeView
	// ShowCreateModeSequence represents SHOW CREATE SEQUENCE
	ShowCreateModeSequence
	// ShowCreateModeDatabase represents SHOW CREATE DATABASE
	ShowCreateModeDatabase
)

// ShowCreate represents a SHOW CREATE statement.
type ShowCreate struct {
	Mode ShowCreateMode
	Name *UnresolvedObjectName
}

// Format implements the NodeFormatter interface.
func (node *ShowCreate) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW CREATE ")

	switch node.Mode {
	case ShowCreateModeDatabase:
		ctx.WriteString("DATABASE ")
	}
	ctx.FormatNode(node.Name)
}

// SQLRight Code Injection.
func (node *ShowCreate) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW CREATE "

	switch node.Mode {
	case ShowCreateModeDatabase:
		prefix += "DATABASE "
	}

	nameNode := &SQLRightIR{
		NodeHash:    141525,
		IRType:      TypeIdentifier,
		DataType:    DataDatabaseName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Name.String(),
	}

	rootIR := &SQLRightIR{
		NodeHash: 191399,
		IRType:   TypeShowCreate,
		DataType: DataNone,
		LNode:    nameNode,
		//RNode:  readNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// ShowCreateAllSchemas represents a SHOW CREATE ALL SCHEMAS statement.
type ShowCreateAllSchemas struct{}

// Format implements the NodeFormatter interface.
func (node *ShowCreateAllSchemas) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW CREATE ALL SCHEMAS")
}

// SQLRight Code Injection.
func (node *ShowCreateAllSchemas) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW CREATE ALL SCHEMAS"

	rootIR := &SQLRightIR{
		NodeHash: 144073,
		IRType:   TypeShowCreateAllSchemas,
		DataType: DataNone,
		//LNode:  nameNode,
		//RNode:  readNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// ShowCreateAllTables represents a SHOW CREATE ALL TABLES statement.
type ShowCreateAllTables struct{}

// Format implements the NodeFormatter interface.
func (node *ShowCreateAllTables) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW CREATE ALL TABLES")
}

// SQLRight Code Injection.
func (node *ShowCreateAllTables) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW CREATE ALL TABLES"

	rootIR := &SQLRightIR{
		NodeHash: 139735,
		IRType:   TypeShowCreateAllTables,
		DataType: DataNone,
		//LNode:  nameNode,
		//RNode:  readNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// ShowCreateAllTypes represents a SHOW CREATE ALL TYPES statement.
type ShowCreateAllTypes struct{}

// Format implements the NodeFormatter interface.
func (node *ShowCreateAllTypes) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW CREATE ALL TYPES")
}

// SQLRight Code Injection.
func (node *ShowCreateAllTypes) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW CREATE ALL TYPES"

	rootIR := &SQLRightIR{
		NodeHash: 169138,
		IRType:   TypeShowCreateAllTypes,
		DataType: DataNone,
		//LNode:  nameNode,
		//RNode:  readNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// ShowCreateSchedules represents a SHOW CREATE SCHEDULE statement.
type ShowCreateSchedules struct {
	ScheduleID Expr
}

// Format implements the NodeFormatter interface.
func (node *ShowCreateSchedules) Format(ctx *FmtCtx) {
	if node.ScheduleID != nil {
		ctx.WriteString("SHOW CREATE SCHEDULE ")
		ctx.FormatNode(node.ScheduleID)
		return
	}
	ctx.Printf("SHOW CREATE ALL SCHEDULES")
}

// SQLRight Code Injection.
func (node *ShowCreateSchedules) LogCurrentNode(depth int) *SQLRightIR {

	if node.ScheduleID != nil {
		prefix := "SHOW CREATE SCHEDULE "

		scheduleNode := node.ScheduleID.LogCurrentNode(depth + 1)

		rootIR := &SQLRightIR{
			NodeHash: 68504,
			IRType:   TypeShowCreateSchedules,
			DataType: DataNone,
			LNode:    scheduleNode,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		return rootIR
	}

	prefix := "SHOW CREATE ALL SCHEDULES"

	rootIR := &SQLRightIR{
		NodeHash: 196855,
		IRType:   TypeShowCreateSchedules,
		DataType: DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowSyntax represents a SHOW SYNTAX statement.
// This the most lightweight thing that can be done on a statement
// server-side: just report the statement that was entered without
// any processing. Meant for use for syntax checking on clients,
// when the client version might differ from the server.
type ShowSyntax struct {
	Statement string
}

// Format implements the NodeFormatter interface.
func (node *ShowSyntax) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW SYNTAX ")
	if ctx.flags.HasFlags(FmtAnonymize) || ctx.flags.HasFlags(FmtHideConstants) {
		ctx.WriteString("'_'")
	} else {
		ctx.WriteString(lexbase.EscapeSQLString(node.Statement))
	}
}

// SQLRight Code Injection.
func (node *ShowSyntax) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW SYNTAX"

	infix := lexbase.EscapeSQLString(node.Statement)

	rootIR := &SQLRightIR{
		NodeHash: 89988,
		IRType:   TypeShowSyntax,
		DataType: DataNone,
		//LNode:  nameNode,
		//RNode:  readNode,
		Prefix: prefix,
		Infix:  infix,
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// ShowTransactionStatus represents a SHOW TRANSACTION STATUS statement.
type ShowTransactionStatus struct {
}

// Format implements the NodeFormatter interface.
func (node *ShowTransactionStatus) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW TRANSACTION STATUS")
}

// SQLRight Code Injection.
func (node *ShowTransactionStatus) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW TRANSACTION STATUS"

	rootIR := &SQLRightIR{
		NodeHash: 6220,
		IRType:   TypeShowTransactionStatus,
		DataType: DataNone,
		//LNode:  nameNode,
		//RNode:  readNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// ShowLastQueryStatistics represents a SHOW LAST QUERY STATS statement.
type ShowLastQueryStatistics struct {
	Columns NameList
}

// ShowLastQueryStatisticsDefaultColumns is the default list of columns
// when the USING clause is not specified.
// Note: the form that does not specify the USING clause is deprecated.
// Remove it when there are no more clients using it (22.1 or later).
var ShowLastQueryStatisticsDefaultColumns = NameList([]Name{
	"parse_latency",
	"plan_latency",
	"exec_latency",
	"service_latency",
	"post_commit_jobs_latency",
})

// Format implements the NodeFormatter interface.
func (node *ShowLastQueryStatistics) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW LAST QUERY STATISTICS RETURNING ")
	// The column names for this statement never contain PII and should
	// be distinguished for feature tracking purposes.
	ctx.WithFlags(ctx.flags & ^FmtAnonymize & ^FmtMarkRedactionNode, func() {
		ctx.FormatNode(&node.Columns)
	})
}

// SQLRight Code Injection.
func (node *ShowLastQueryStatistics) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW LAST QUERY STATISTICS RETURNING "

	columnNode := node.Columns.LogCurrentNodeWithType(depth+1, DataColumnName)

	rootIR := &SQLRightIR{
		NodeHash: 157984,
		IRType:   TypeShowLastQueryStatistics,
		DataType: DataNone,
		LNode:    columnNode,
		//RNode:  readNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// ShowFullTableScans represents a SHOW FULL TABLE SCANS statement.
type ShowFullTableScans struct {
}

// Format implements the NodeFormatter interface.
func (node *ShowFullTableScans) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW FULL TABLE SCANS")
}

// SQLRight Code Injection.
func (node *ShowFullTableScans) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW FULL TABLE SCANS"

	rootIR := &SQLRightIR{
		NodeHash: 65699,
		IRType:   TypeShowFullTableScans,
		DataType: DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowSavepointStatus represents a SHOW SAVEPOINT STATUS statement.
type ShowSavepointStatus struct {
}

// Format implements the NodeFormatter interface.
func (node *ShowSavepointStatus) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW SAVEPOINT STATUS")
}

// SQLRight Code Injection.
func (node *ShowSavepointStatus) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW SAVEPOINT STATUS"

	rootIR := &SQLRightIR{
		NodeHash: 182652,
		IRType:   TypeShowSavepointStatus,
		DataType: DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowUsers represents a SHOW USERS statement.
type ShowUsers struct {
}

// Format implements the NodeFormatter interface.
func (node *ShowUsers) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW USERS")
}

// SQLRight Code Injection.
func (node *ShowUsers) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW USERS"

	rootIR := &SQLRightIR{
		NodeHash: 40622,
		IRType:   TypeShowUsers,
		DataType: DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowRoles represents a SHOW ROLES statement.
type ShowRoles struct {
}

// Format implements the NodeFormatter interface.
func (node *ShowRoles) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW ROLES")
}

// SQLRight Code Injection.
func (node *ShowRoles) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW ROLES"

	rootIR := &SQLRightIR{
		NodeHash: 145962,
		IRType:   TypeShowRoles,
		DataType: DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowRanges represents a SHOW RANGES statement.
type ShowRanges struct {
	TableOrIndex TableIndexName
	DatabaseName Name
}

// Format implements the NodeFormatter interface.
func (node *ShowRanges) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW RANGES FROM ")
	if node.DatabaseName != "" {
		ctx.WriteString("DATABASE ")
		ctx.FormatNode(&node.DatabaseName)
	} else if node.TableOrIndex.Index != "" {
		ctx.WriteString("INDEX ")
		ctx.FormatNode(&node.TableOrIndex)
	} else {
		ctx.WriteString("TABLE ")
		ctx.FormatNode(&node.TableOrIndex)
	}
}

// SQLRight Code Injection.
func (node *ShowRanges) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW RANGES FROM "

	var idenNode *SQLRightIR

	if node.DatabaseName != "" {
		prefix += "DATABASE "
		idenNode = &SQLRightIR{
			NodeHash:    182129,
			IRType:      TypeIdentifier,
			DataType:    DataDatabaseName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.DatabaseName.String(),
		}
	} else if node.TableOrIndex.Index != "" {
		prefix += "INDEX "
		idenNode = &SQLRightIR{
			NodeHash:    132074,
			IRType:      TypeIdentifier,
			DataType:    DataIndexName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.TableOrIndex.String(),
		}
	} else {
		prefix += "TABLE "
		idenNode = &SQLRightIR{
			NodeHash:    19197,
			IRType:      TypeIdentifier,
			DataType:    DataTableName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.TableOrIndex.String(),
		}
	}

	rootIR := &SQLRightIR{
		NodeHash: 128508,
		IRType:   TypeShowRanges,
		DataType: DataNone,
		LNode:    idenNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowRangeForRow represents a SHOW RANGE FOR ROW statement.
type ShowRangeForRow struct {
	TableOrIndex TableIndexName
	Row          Exprs
}

// Format implements the NodeFormatter interface.
func (node *ShowRangeForRow) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW RANGE FROM ")
	if node.TableOrIndex.Index != "" {
		ctx.WriteString("INDEX ")
	} else {
		ctx.WriteString("TABLE ")
	}
	ctx.FormatNode(&node.TableOrIndex)
	ctx.WriteString(" FOR ROW (")
	ctx.FormatNode(&node.Row)
	ctx.WriteString(")")
}

// SQLRight Code Injection.
func (node *ShowRangeForRow) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW RANGE FROM "

	var idenNode *SQLRightIR
	if node.TableOrIndex.Index != "" {
		prefix += "INDEX "
		idenNode = &SQLRightIR{
			NodeHash:    177273,
			IRType:      TypeIdentifier,
			DataType:    DataIndexName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.TableOrIndex.String(),
		}
	} else {
		prefix += "TABLE "
		idenNode = &SQLRightIR{
			NodeHash:    107829,
			IRType:      TypeIdentifier,
			DataType:    DataTableName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.TableOrIndex.String(),
		}
	}

	infix := " FOR ROW ( "
	rowNode := node.Row.LogCurrentNode(depth + 1)
	suffix := ")"

	rootIR := &SQLRightIR{
		NodeHash: 127017,
		IRType:   TypeShowRangeForRow,
		DataType: DataNone,
		LNode:    idenNode,
		RNode:    rowNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   suffix,
		Depth:    depth,
	}

	return rootIR
}

// ShowFingerprints represents a SHOW EXPERIMENTAL_FINGERPRINTS statement.
type ShowFingerprints struct {
	Table *UnresolvedObjectName
}

// Format implements the NodeFormatter interface.
func (node *ShowFingerprints) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW EXPERIMENTAL_FINGERPRINTS FROM TABLE ")
	ctx.FormatNode(node.Table)
}

// SQLRight Code Injection.
func (node *ShowFingerprints) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW EXPERIMENTAL_FINGERPRINTS FROM TABLE "

	tableNode := &SQLRightIR{
		NodeHash:    146350,
		IRType:      TypeIdentifier,
		DataType:    DataTableName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Table.String(),
	}

	rootIR := &SQLRightIR{
		NodeHash: 62288,
		IRType:   TypeShowFingerprints,
		DataType: DataNone,
		LNode:    tableNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowTableStats represents a SHOW STATISTICS FOR TABLE statement.
type ShowTableStats struct {
	Table     *UnresolvedObjectName
	UsingJSON bool
	Options   KVOptions
}

// Format implements the NodeFormatter interface.
func (node *ShowTableStats) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW STATISTICS ")
	if node.UsingJSON {
		ctx.WriteString("USING JSON ")
	}
	ctx.WriteString("FOR TABLE ")
	ctx.FormatNode(node.Table)
	if len(node.Options) > 0 {
		ctx.WriteString(" WITH ")
		ctx.FormatNode(&node.Options)
	}
}

// SQLRight Code Injection.
func (node *ShowTableStats) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW STATISTICS "

	if node.UsingJSON {
		prefix += "USING JSON "
	}

	prefix += "FOR TABLE "

	tableNode := &SQLRightIR{
		NodeHash:    66402,
		IRType:      TypeIdentifier,
		DataType:    DataTableName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Table.String(),
	}

	infix := ""
	var optionNode *SQLRightIR
	if len(node.Options) > 0 {
		infix = " WITH "
		optionNode = node.Options.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		NodeHash: 23981,
		IRType:   TypeShowTableStats,
		DataType: DataNone,
		LNode:    tableNode,
		RNode:    optionNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowHistogram represents a SHOW HISTOGRAM statement.
type ShowHistogram struct {
	HistogramID int64
}

// Format implements the NodeFormatter interface.
func (node *ShowHistogram) Format(ctx *FmtCtx) {
	ctx.Printf("SHOW HISTOGRAM %d", node.HistogramID)
}

// SQLRight Code Injection.
func (node *ShowHistogram) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW HISTOGRAM "

	intLiteralNode := &SQLRightIR{
		NodeHash:     173199,
		IRType:       TypeIntegerLiteral,
		DataType:     DataLiteral,
		DataAffinity: AFFIINT,
		Prefix:       "",
		Infix:        "",
		Suffix:       "",
		Depth:        depth,
		IValue:       node.HistogramID,
	}

	rootIR := &SQLRightIR{
		NodeHash: 57754,
		IRType:   TypeShowHistogram,
		DataType: DataNone,
		LNode:    intLiteralNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowPartitions represents a SHOW PARTITIONS statement.
type ShowPartitions struct {
	IsDB     bool
	Database Name

	IsIndex bool
	Index   TableIndexName

	IsTable bool
	Table   *UnresolvedObjectName
}

// Format implements the NodeFormatter interface.
func (node *ShowPartitions) Format(ctx *FmtCtx) {
	if node.IsDB {
		ctx.Printf("SHOW PARTITIONS FROM DATABASE ")
		ctx.FormatNode(&node.Database)
	} else if node.IsIndex {
		ctx.Printf("SHOW PARTITIONS FROM INDEX ")
		ctx.FormatNode(&node.Index)
	} else {
		ctx.Printf("SHOW PARTITIONS FROM TABLE ")
		ctx.FormatNode(node.Table)
	}
}

// SQLRight Code Injection.
func (node *ShowPartitions) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""
	var idenNode *SQLRightIR

	if node.IsDB {
		prefix += "SHOW PARTITIONS FROM DATABASE "
		idenNode = &SQLRightIR{
			NodeHash:    228856,
			IRType:      TypeIdentifier,
			DataType:    DataDatabaseName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Database.String(),
		}
	} else if node.IsIndex {
		prefix += "SHOW PARTITIONS FROM INDEX "
		idenNode = &SQLRightIR{
			NodeHash:    76404,
			IRType:      TypeIdentifier,
			DataType:    DataIndexName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Index.String(),
		}
	} else {
		prefix += "SHOW PARTITIONS FROM TABLE "
		idenNode = &SQLRightIR{
			NodeHash:    198694,
			IRType:      TypeIdentifier,
			DataType:    DataTableName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Table.String(),
		}
	}

	rootIR := &SQLRightIR{
		NodeHash: 57934,
		IRType:   TypeShowPartitions,
		DataType: DataNone,
		LNode:    idenNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ScheduledJobExecutorType is a type identifying the names of
// the supported scheduled job executors.
type ScheduledJobExecutorType int

const (
	// InvalidExecutor is a placeholder for an invalid executor type.
	InvalidExecutor ScheduledJobExecutorType = iota

	// ScheduledBackupExecutor is an executor responsible for
	// the execution of the scheduled backups.
	ScheduledBackupExecutor

	// ScheduledSQLStatsCompactionExecutor is an executor responsible for the
	// execution of the scheduled SQL Stats compaction.
	ScheduledSQLStatsCompactionExecutor

	// ScheduledRowLevelTTLExecutor is an executor responsible for the cleanup
	// of rows on row level TTL tables.
	ScheduledRowLevelTTLExecutor

	// ScheduledSchemaTelemetryExecutor is an executor responsible for the logging
	// of schema telemetry.
	ScheduledSchemaTelemetryExecutor
)

var scheduleExecutorInternalNames = map[ScheduledJobExecutorType]string{
	InvalidExecutor:                     "unknown-executor",
	ScheduledBackupExecutor:             "scheduled-backup-executor",
	ScheduledSQLStatsCompactionExecutor: "scheduled-sql-stats-compaction-executor",
	ScheduledRowLevelTTLExecutor:        "scheduled-row-level-ttl-executor",
	ScheduledSchemaTelemetryExecutor:    "scheduled-schema-telemetry-executor",
}

// InternalName returns an internal executor name.
// This name can be used to filter matching schedules.
func (t ScheduledJobExecutorType) InternalName() string {
	return scheduleExecutorInternalNames[t]
}

// UserName returns a user friendly executor name.
func (t ScheduledJobExecutorType) UserName() string {
	switch t {
	case ScheduledBackupExecutor:
		return "BACKUP"
	case ScheduledSQLStatsCompactionExecutor:
		return "SQL STATISTICS"
	case ScheduledRowLevelTTLExecutor:
		return "ROW LEVEL TTL"
	case ScheduledSchemaTelemetryExecutor:
		return "SCHEMA TELEMETRY"
	}
	return "unsupported-executor"
}

// ScheduleState describes what kind of schedules to display
type ScheduleState int

const (
	// SpecifiedSchedules indicates that show schedules should
	// only show subset of schedules.
	SpecifiedSchedules ScheduleState = iota

	// ActiveSchedules indicates that show schedules should
	// only show those schedules that are currently active.
	ActiveSchedules

	// PausedSchedules indicates that show schedules should
	// only show those schedules that are currently paused.
	PausedSchedules
)

// Format implements the NodeFormatter interface.
func (s ScheduleState) Format(ctx *FmtCtx) {
	switch s {
	case ActiveSchedules:
		ctx.WriteString("RUNNING")
	case PausedSchedules:
		ctx.WriteString("PAUSED")
	default:
		// Nothing
	}
}

// SQLRight Code Injection.
func (node ScheduleState) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""
	switch node {
	case ActiveSchedules:
		prefix = "RUNNING "
	case PausedSchedules:
		prefix = "PAUSED "
	default:
		prefix = ""
	}

	rootIR := &SQLRightIR{
		NodeHash: 19690,
		IRType:   TypeScheduleState,
		DataType: DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowSchedules represents a SHOW SCHEDULES statement.
type ShowSchedules struct {
	WhichSchedules ScheduleState
	ExecutorType   ScheduledJobExecutorType
	ScheduleID     Expr
}

var _ Statement = &ShowSchedules{}

// Format implements the NodeFormatter interface.
func (n *ShowSchedules) Format(ctx *FmtCtx) {
	if n.ScheduleID != nil {
		ctx.WriteString("SHOW SCHEDULE ")
		ctx.FormatNode(n.ScheduleID)
		return
	}
	ctx.Printf("SHOW")

	if n.WhichSchedules != SpecifiedSchedules {
		ctx.WriteString(" ")
		ctx.FormatNode(&n.WhichSchedules)
	}

	ctx.Printf(" SCHEDULES")

	if n.ExecutorType != InvalidExecutor {
		// TODO(knz): beware of using ctx.FormatNode here if
		// FOR changes to support expressions.
		ctx.Printf(" FOR %s", n.ExecutorType.UserName())
	}
}

// SQLRight Code Injection.
func (node *ShowSchedules) LogCurrentNode(depth int) *SQLRightIR {

	if node.ScheduleID != nil {
		prefix := "SHOW SCHEDULE "
		exprNode := node.ScheduleID.LogCurrentNode(depth + 1)

		rootIR := &SQLRightIR{
			NodeHash: 59948,
			IRType:   TypeShowSchedules,
			DataType: DataNone,
			LNode:    exprNode,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		return rootIR
	}

	prefix := "SHOW "

	var optWhichSchedule *SQLRightIR
	if node.WhichSchedules != SpecifiedSchedules {
		optWhichSchedule = node.WhichSchedules.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		NodeHash: 257483,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    optWhichSchedule,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	infix := "SCHEDULES"

	var userNameNode *SQLRightIR
	if node.ExecutorType != InvalidExecutor {
		// TODO(knz): beware of using ctx.FormatNode here if
		// FOR changes to support expressions.
		userNameStr := fmt.Sprintf("%s", node.ExecutorType.UserName())
		infix += " FOR "

		userNode := &SQLRightIR{
			NodeHash:    230426,
			IRType:      TypeIdentifier,
			DataType:    DataRoleName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         userNameStr,
		}
		userNameNode = userNode
	}

	rootIR = &SQLRightIR{
		NodeHash: 203516,
		IRType:   TypeShowSchedules,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    userNameNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowDefaultPrivileges represents a SHOW DEFAULT PRIVILEGES statement.
type ShowDefaultPrivileges struct {
	Roles       RoleSpecList
	ForAllRoles bool
	// If Schema is not specified, SHOW DEFAULT PRIVILEGES is being
	// run on the current database.
	Schema Name
}

var _ Statement = &ShowDefaultPrivileges{}

// Format implements the NodeFormatter interface.
func (n *ShowDefaultPrivileges) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW DEFAULT PRIVILEGES ")
	if len(n.Roles) > 0 {
		ctx.WriteString("FOR ROLE ")
		for i, role := range n.Roles {
			if i > 0 {
				ctx.WriteString(", ")
			}
			ctx.FormatNode(&role)
		}
		ctx.WriteString(" ")
	} else if n.ForAllRoles {
		ctx.WriteString("FOR ALL ROLES ")
	}
	if n.Schema != Name("") {
		ctx.WriteString("IN SCHEMA ")
		ctx.FormatNode(&n.Schema)
	}
}

// SQLRight Code Injection.
func (node *ShowDefaultPrivileges) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW DEFAULT PRIVILEGES "
	var tmpNode *SQLRightIR
	if len(node.Roles) > 0 {
		for i, role := range node.Roles {
			if i > 0 {
				if i == 0 {
					// Take care of the first two nodes.
					LNode := role.LogCurrentNode(depth+1, ContextUse)
					var RNode *SQLRightIR
					if i == 0 {
						prefix += "FOR ROLE "
					} else {
						prefix = ""
					}
					infix := " "
					if len(node.Roles) >= 2 {
						infix = ", "
						RNode = (node.Roles)[1].LogCurrentNode(depth+1, ContextUse)
					}
					tmpNode = &SQLRightIR{
						NodeHash: 12331,
						IRType:   TypeUnknown,
						DataType: DataNone,
						LNode:    LNode,
						RNode:    RNode,
						Prefix:   prefix,
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
					LNode := tmpNode
					RNode := role.LogCurrentNode(depth+1, ContextUse)

					tmpNode = &SQLRightIR{
						NodeHash: 136841,
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
		}
	} else if node.ForAllRoles {
		prefix += "FOR ALL ROLES "
		tmpNode = &SQLRightIR{
			NodeHash: 201616,
			IRType:   TypeUnknown,
			DataType: DataNone,
			//LNode:    LNode,
			//RNode:    RNode,
			Prefix: prefix,
			Infix:  ", ",
			Suffix: "",
			Depth:  depth,
		}
	}
	if node.Schema.String() != "" {
		prefix += "IN SCHEMA "
		schemaNode := &SQLRightIR{
			NodeHash:    10599,
			IRType:      TypeIdentifier,
			DataType:    DataSchemaName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Schema.String(),
		}

		tmpNode = &SQLRightIR{
			NodeHash: 92966,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    schemaNode,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}
	rootIR := tmpNode
	rootIR.IRType = TypeShowDefaultPrivileges

	return rootIR
}

// ShowTransferState represents a SHOW TRANSFER STATE statement.
type ShowTransferState struct {
	TransferKey *StrVal
}

// Format implements the NodeFormatter interface.
func (node *ShowTransferState) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW TRANSFER STATE")
	if node.TransferKey != nil {
		ctx.WriteString(" WITH ")
		ctx.FormatNode(node.TransferKey)
	}
}

// SQLRight Code Injection.
func (node *ShowTransferState) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW TRANSFER STATE "

	var transferNode *SQLRightIR
	if node.TransferKey != nil {
		prefix += " WITH "
		// TRANSFER KEY.
		strNode := &SQLRightIR{
			NodeHash:     87646,
			IRType:       TypeStringLiteral,
			DataType:     DataLiteral,
			DataAffinity: AFFIUNKNOWN,
			Prefix:       "",
			Infix:        "",
			Suffix:       "",
			Depth:        depth,
			Str:          node.TransferKey.String(),
		}
		transferNode = strNode
	}

	rootIR := &SQLRightIR{
		NodeHash: 233566,
		IRType:   TypeShowTransferState,
		DataType: DataNone,
		LNode:    transferNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ShowCompletions represents a SHOW COMPLETIONS statement.
type ShowCompletions struct {
	Statement *StrVal
	Offset    *NumVal
}

// Format implements the NodeFormatter interface.
func (s ShowCompletions) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW COMPLETIONS AT OFFSET ")
	s.Offset.Format(ctx)
	ctx.WriteString(" FOR ")
	ctx.FormatNode(s.Statement)
}

// SQLRight Code Injection.
func (node *ShowCompletions) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW COMPLETIONS AT OFFSET "

	offsetInt, err := strconv.ParseInt(node.Offset.OrigString(), 10, 64)
	if err != nil {
		offsetInt = 0
	}
	offsetNode := &SQLRightIR{
		NodeHash:     237109,
		IRType:       TypeIntegerLiteral,
		DataType:     DataLiteral,
		DataAffinity: AFFIINT,
		Prefix:       "",
		Infix:        "",
		Suffix:       "",
		Depth:        depth,
		IValue:       offsetInt,
	}

	statementStr := node.Statement.String()
	// This is a whole SQL statement str.
	statementNode := &SQLRightIR{
		NodeHash:     77632,
		IRType:       TypeStringLiteral,
		DataType:     DataLiteral,
		DataAffinity: AFFIWHOLESTMT,
		Prefix:       "",
		Infix:        "",
		Suffix:       "",
		Depth:        depth,
		Str:          statementStr,
	}

	rootIR := &SQLRightIR{
		NodeHash: 177690,
		IRType:   TypeShowCompletions,
		DataType: DataNone,
		LNode:    offsetNode,
		RNode:    statementNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

var _ Statement = &ShowCompletions{}

// ShowCreateFunction represents a SHOW CREATE FUNCTION statement.
type ShowCreateFunction struct {
	Name ResolvableFunctionReference
}

// Format implements the NodeFormatter interface.
func (node *ShowCreateFunction) Format(ctx *FmtCtx) {
	ctx.WriteString("SHOW CREATE FUNCTION ")
	ctx.FormatNode(&node.Name)
}

// SQLRight Code Injection.
func (node *ShowCreateFunction) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "SHOW CREATE FUNCTION "

	nameNode := &SQLRightIR{
		NodeHash:    215527,
		IRType:      TypeIdentifier,
		DataType:    DataFunctionName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Name.String(),
	}

	rootIR := &SQLRightIR{
		NodeHash: 172186,
		IRType:   TypeShowCreateFunction,
		DataType: DataNone,
		LNode:    nameNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

var _ Statement = &ShowCreateFunction{}

// ShowCreateExternalConnections represents a SHOW CREATE EXTERNAL CONNECTION
// statement.
type ShowCreateExternalConnections struct {
	ConnectionLabel Expr
}

// Format implements the NodeFormatter interface.
func (node *ShowCreateExternalConnections) Format(ctx *FmtCtx) {
	if node.ConnectionLabel != nil {
		ctx.WriteString("SHOW CREATE EXTERNAL CONNECTION ")
		ctx.FormatNode(node.ConnectionLabel)
		return
	}
	ctx.Printf("SHOW CREATE ALL EXTERNAL CONNECTIONS")
}

// SQLRight Code Injection.
func (node *ShowCreateExternalConnections) LogCurrentNode(depth int) *SQLRightIR {

	if node.ConnectionLabel != nil {
		prefix := "SHOW CREATE EXTERNAL CONNECTION "
		connectionNode := node.ConnectionLabel.LogCurrentNode(depth + 1)

		rootIR := &SQLRightIR{
			NodeHash: 50795,
			IRType:   TypeShowCreateExternalConnections,
			DataType: DataNone,
			LNode:    connectionNode,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		return rootIR
	}

	prefix := "SHOW CREATE ALL EXTERNAL CONNECTIONS"

	rootIR := &SQLRightIR{
		NodeHash: 126433,
		IRType:   TypeShowCreateExternalConnections,
		DataType: DataNone,
		//LNode:    connectionNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}
	return rootIR
}

var _ Statement = &ShowCreateExternalConnections{}
