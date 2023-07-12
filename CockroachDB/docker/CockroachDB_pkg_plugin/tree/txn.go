// Copyright 2015 The Cockroach Authors.
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
	"strings"

	"github.com/cockroachdb/cockroach/pkg/sql/pgwire/pgcode"
	"github.com/cockroachdb/cockroach/pkg/sql/pgwire/pgerror"
)

// IsolationLevel holds the isolation level for a transaction.
type IsolationLevel int

// IsolationLevel values
const (
	UnspecifiedIsolation IsolationLevel = iota
	SerializableIsolation
)

var isolationLevelNames = [...]string{
	UnspecifiedIsolation:  "UNSPECIFIED",
	SerializableIsolation: "SERIALIZABLE",
}

// IsolationLevelMap is a map from string isolation level name to isolation
// level, in the lowercase format that set isolation_level supports.
var IsolationLevelMap = map[string]IsolationLevel{
	"serializable": SerializableIsolation,
}

func (i IsolationLevel) String() string {
	if i < 0 || i > IsolationLevel(len(isolationLevelNames)-1) {
		return fmt.Sprintf("IsolationLevel(%d)", i)
	}
	return isolationLevelNames[i]
}

// UserPriority holds the user priority for a transaction.
type UserPriority int

// UserPriority values
const (
	UnspecifiedUserPriority UserPriority = iota
	Low
	Normal
	High
)

var userPriorityNames = [...]string{
	UnspecifiedUserPriority: "UNSPECIFIED",
	Low:                     "LOW",
	Normal:                  "NORMAL",
	High:                    "HIGH",
}

func (up UserPriority) String() string {
	if up < 0 || up > UserPriority(len(userPriorityNames)-1) {
		return fmt.Sprintf("UserPriority(%d)", up)
	}
	return userPriorityNames[up]
}

// UserPriorityFromString converts a string into a UserPriority.
func UserPriorityFromString(val string) (_ UserPriority, ok bool) {
	switch strings.ToUpper(val) {
	case "LOW":
		return Low, true
	case "NORMAL":
		return Normal, true
	case "HIGH":
		return High, true
	default:
		return 0, false
	}
}

// ReadWriteMode holds the read write mode for a transaction.
type ReadWriteMode int

// ReadWriteMode values
const (
	UnspecifiedReadWriteMode ReadWriteMode = iota
	ReadOnly
	ReadWrite
)

var readWriteModeNames = [...]string{
	UnspecifiedReadWriteMode: "UNSPECIFIED",
	ReadOnly:                 "ONLY",
	ReadWrite:                "WRITE",
}

func (ro ReadWriteMode) String() string {
	if ro < 0 || ro > ReadWriteMode(len(readWriteModeNames)-1) {
		return fmt.Sprintf("ReadWriteMode(%d)", ro)
	}
	return readWriteModeNames[ro]
}

// DeferrableMode holds the deferrable mode for a transaction.
type DeferrableMode int

// DeferrableMode values.
const (
	UnspecifiedDeferrableMode DeferrableMode = iota
	Deferrable
	NotDeferrable
)

var deferrableModeNames = [...]string{
	UnspecifiedDeferrableMode: "UNSPECIFIED",
	Deferrable:                "DEFERRABLE",
	NotDeferrable:             "NOT DEFERRABLE",
}

func (d DeferrableMode) String() string {
	if d < 0 || d > DeferrableMode(len(deferrableModeNames)-1) {
		return fmt.Sprintf("DeferrableMode(%d)", d)
	}
	return deferrableModeNames[d]
}

// TransactionModes holds the transaction modes for a transaction.
type TransactionModes struct {
	Isolation     IsolationLevel
	UserPriority  UserPriority
	ReadWriteMode ReadWriteMode
	AsOf          AsOfClause
	Deferrable    DeferrableMode
}

// Format implements the NodeFormatter interface.
func (node *TransactionModes) Format(ctx *FmtCtx) {
	var sep string
	if node.Isolation != UnspecifiedIsolation {
		ctx.Printf(" ISOLATION LEVEL %s", node.Isolation)
		sep = ","
	}
	if node.UserPriority != UnspecifiedUserPriority {
		ctx.Printf("%s PRIORITY %s", sep, node.UserPriority)
		sep = ","
	}
	if node.ReadWriteMode != UnspecifiedReadWriteMode {
		ctx.Printf("%s READ %s", sep, node.ReadWriteMode)
		sep = ","
	}
	if node.AsOf.Expr != nil {
		ctx.WriteString(sep)
		ctx.WriteString(" ")
		ctx.FormatNode(&node.AsOf)
		sep = ","
	}
	if node.Deferrable != UnspecifiedDeferrableMode {
		ctx.Printf("%s %s", sep, node.Deferrable)
	}
}

// SQLRight Code Injection.
func (node *TransactionModes) LogCurrentNode(depth int) *SQLRightIR {

	var sep string

	var optIsolationLevelNode *SQLRightIR
	if node.Isolation != UnspecifiedIsolation {
		optIsolationLevelNode = &SQLRightIR{
			NodeHash: 23704,
			IRType:   TypeOptIsolationLevel,
			DataType: DataNone,
			//LNode:    LNode,
			//RNode:    RNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
			Str:    fmt.Sprintf(" ISOLATION LEVEL %s", node.Isolation),
		}
		sep = ", "
	} else {
		optIsolationLevelNode = &SQLRightIR{
			NodeHash: 174932,
			IRType:   TypeOptIsolationLevel,
			DataType: DataNone,
			//LNode:    LNode,
			//RNode:    RNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
	}

	var pPriorityNode *SQLRightIR
	if node.UserPriority != UnspecifiedUserPriority {
		priorityNode := &SQLRightIR{
			NodeHash: 124176,
			IRType:   TypeUserPriority,
			DataType: DataNone,
			//LNode:    LNode,
			//RNode:    RNode,
			Prefix: " PRIORITY ",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
			Str:    fmt.Sprintf("%s", node.UserPriority),
		}
		pPriorityNode = priorityNode
		sep = ", "
	}

	curSep := ""
	if optIsolationLevelNode.Str != "" && pPriorityNode != nil {
		curSep = ", "
	}
	rootIR := &SQLRightIR{
		NodeHash: 237721,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    optIsolationLevelNode,
		RNode:    pPriorityNode,
		Prefix:   "",
		Infix:    curSep,
		Suffix:   "",
		Depth:    depth,
	}

	if node.ReadWriteMode != UnspecifiedReadWriteMode {
		readNode := &SQLRightIR{
			NodeHash: 54024,
			IRType:   TypeReadWriteMode,
			DataType: DataNone,
			//LNode:    LNode,
			//RNode:    RNode,
			Prefix: " READ ",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
			Str:    fmt.Sprintf("%s", node.ReadWriteMode),
		}
		sep = ","

		rootIR = &SQLRightIR{
			NodeHash: 168528,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    readNode,
			Prefix:   "",
			Infix:    sep,
			Suffix:   "",
			Depth:    depth,
		}

	}

	if node.AsOf.Expr != nil {
		asofNode := node.AsOf.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			NodeHash: 149528,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    asofNode,
			Prefix:   "",
			Infix:    sep,
			Suffix:   "",
			Depth:    depth,
		}
		sep = ","
	}

	if node.Deferrable != UnspecifiedDeferrableMode {
		deferNode := &SQLRightIR{
			NodeHash: 27667,
			IRType:   TypeDeferrable,
			DataType: DataNone,
			//LNode:    LNode,
			//RNode:    RNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
			Str:    fmt.Sprintf("%s", node.Deferrable),
		}

		rootIR = &SQLRightIR{
			NodeHash: 189093,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    deferNode,
			Prefix:   "",
			Infix:    sep,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.NodeHash = 195985
	rootIR.IRType = TypeTransactionModes
	return rootIR
}

var (
	errIsolationLevelSpecifiedMultipleTimes = pgerror.New(pgcode.Syntax, "isolation level specified multiple times")
	errUserPrioritySpecifiedMultipleTimes   = pgerror.New(pgcode.Syntax, "user priority specified multiple times")
	errReadModeSpecifiedMultipleTimes       = pgerror.New(pgcode.Syntax, "read mode specified multiple times")
	errAsOfSpecifiedMultipleTimes           = pgerror.New(pgcode.Syntax, "AS OF SYSTEM TIME specified multiple times")
	errDeferrableSpecifiedMultipleTimes     = pgerror.New(pgcode.Syntax, "deferrable mode specified multiple times")

	// ErrAsOfSpecifiedWithReadWrite is returned when a statement attempts to set
	// a historical query to READ WRITE which conflicts with its implied READ ONLY
	// mode.
	ErrAsOfSpecifiedWithReadWrite = pgerror.New(pgcode.Syntax, "AS OF SYSTEM TIME specified with READ WRITE mode")
)

// Merge groups two sets of transaction modes together.
// Used in the parser.
func (node *TransactionModes) Merge(other TransactionModes) error {
	if other.Isolation != UnspecifiedIsolation {
		if node.Isolation != UnspecifiedIsolation {
			return errIsolationLevelSpecifiedMultipleTimes
		}
		node.Isolation = other.Isolation
	}
	if other.UserPriority != UnspecifiedUserPriority {
		if node.UserPriority != UnspecifiedUserPriority {
			return errUserPrioritySpecifiedMultipleTimes
		}
		node.UserPriority = other.UserPriority
	}
	if other.AsOf.Expr != nil {
		if node.AsOf.Expr != nil {
			return errAsOfSpecifiedMultipleTimes
		}
		node.AsOf.Expr = other.AsOf.Expr
	}
	if other.ReadWriteMode != UnspecifiedReadWriteMode {
		if node.ReadWriteMode != UnspecifiedReadWriteMode {
			return errReadModeSpecifiedMultipleTimes
		}
		node.ReadWriteMode = other.ReadWriteMode
	}
	if node.ReadWriteMode != UnspecifiedReadWriteMode &&
		node.ReadWriteMode != ReadOnly &&
		node.AsOf.Expr != nil {
		return ErrAsOfSpecifiedWithReadWrite
	}
	if other.Deferrable != UnspecifiedDeferrableMode {
		if node.Deferrable != UnspecifiedDeferrableMode {
			return errDeferrableSpecifiedMultipleTimes
		}
		node.Deferrable = other.Deferrable
	}
	return nil
}

// BeginTransaction represents a BEGIN statement
type BeginTransaction struct {
	Modes TransactionModes
}

// Format implements the NodeFormatter interface.
func (node *BeginTransaction) Format(ctx *FmtCtx) {
	ctx.WriteString("BEGIN TRANSACTION")
	ctx.FormatNode(&node.Modes)
}

// SQLRight Code Injection.
func (node *BeginTransaction) LogCurrentNode(depth int) *SQLRightIR {

	modeNodes := node.Modes.LogCurrentNode(depth + 1)
	rootIR := &SQLRightIR{
		NodeHash: 12991,
		IRType:   TypeBeginTransaction,
		DataType: DataNone,
		LNode:    modeNodes,
		//RNode:    RNode,
		Prefix: "BEGIN TRANSACTION ",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// CommitTransaction represents a COMMIT statement.
type CommitTransaction struct{}

// Format implements the NodeFormatter interface.
func (node *CommitTransaction) Format(ctx *FmtCtx) {
	ctx.WriteString("COMMIT TRANSACTION")
}

// SQLRight Code Injection.
func (node *CommitTransaction) LogCurrentNode(depth int) *SQLRightIR {

	rootIR := &SQLRightIR{
		NodeHash: 141532,
		IRType:   TypeCommitTransaction,
		DataType: DataNone,
		//LNode:    modeNodes,
		//RNode:    RNode,
		Prefix: "COMMIT TRANSACTION ",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// RollbackTransaction represents a ROLLBACK statement.
type RollbackTransaction struct{}

// Format implements the NodeFormatter interface.
func (node *RollbackTransaction) Format(ctx *FmtCtx) {
	ctx.WriteString("ROLLBACK TRANSACTION")
}

// SQLRight Code Injection.
func (node *RollbackTransaction) LogCurrentNode(depth int) *SQLRightIR {

	rootIR := &SQLRightIR{
		NodeHash: 13730,
		IRType:   TypeRollbackTransaction,
		DataType: DataNone,
		//LNode:    modeNodes,
		//RNode:    RNode,
		Prefix: "ROLLBACK TRANSACTION ",
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// Savepoint represents a SAVEPOINT <name> statement.
type Savepoint struct {
	Name Name
}

// Format implements the NodeFormatter interface.
func (node *Savepoint) Format(ctx *FmtCtx) {
	ctx.WriteString("SAVEPOINT ")
	ctx.FormatNode(&node.Name)
}

// SQLRight Code Injection.
func (node *Savepoint) LogCurrentNode(depth int) *SQLRightIR {

	nameNode := &SQLRightIR{
		NodeHash:    36010,
		IRType:      TypeIdentifier,
		DataType:    DataSavePointName,
		ContextFlag: ContextDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Name.String(),
	}

	rootIR := &SQLRightIR{
		NodeHash: 238439,
		IRType:   TypeSavepoint,
		DataType: DataNone,
		Prefix:   "SAVEPOINT ",
		LNode:    nameNode,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// ReleaseSavepoint represents a RELEASE SAVEPOINT <name> statement.
type ReleaseSavepoint struct {
	Savepoint Name
}

// Format implements the NodeFormatter interface.
func (node *ReleaseSavepoint) Format(ctx *FmtCtx) {
	ctx.WriteString("RELEASE SAVEPOINT ")
	ctx.FormatNode(&node.Savepoint)
}

// SQLRight Code Injection.
func (node *ReleaseSavepoint) LogCurrentNode(depth int) *SQLRightIR {

	nameNode := &SQLRightIR{
		NodeHash:    251419,
		IRType:      TypeIdentifier,
		DataType:    DataSavePointName,
		ContextFlag: ContextUndefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Savepoint.String(),
	}

	rootIR := &SQLRightIR{
		NodeHash: 65526,
		IRType:   TypeReleaseSavepoint,
		DataType: DataNone,
		Prefix:   "RELEASE SAVEPOINT ",
		LNode:    nameNode,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// RollbackToSavepoint represents a ROLLBACK TO SAVEPOINT <name> statement.
type RollbackToSavepoint struct {
	Savepoint Name
}

// Format implements the NodeFormatter interface.
func (node *RollbackToSavepoint) Format(ctx *FmtCtx) {
	ctx.WriteString("ROLLBACK TRANSACTION TO SAVEPOINT ")
	ctx.FormatNode(&node.Savepoint)
}

// SQLRight Code Injection.
func (node *RollbackToSavepoint) LogCurrentNode(depth int) *SQLRightIR {

	nameNode := &SQLRightIR{
		NodeHash:    226977,
		IRType:      TypeIdentifier,
		DataType:    DataSavePointName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Savepoint.String(),
	}

	rootIR := &SQLRightIR{
		NodeHash: 112932,
		IRType:   TypeRollbackToSavepoint,
		DataType: DataNone,
		Prefix:   "ROLLBACK TRANSACTION TO SAVEPOINT ",
		LNode:    nameNode,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}
