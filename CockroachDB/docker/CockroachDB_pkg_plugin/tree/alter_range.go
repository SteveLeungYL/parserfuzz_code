// Copyright 2021 The Cockroach Authors.
//
// Use of this software is governed by the Business Source License
// included in the file licenses/BSL.txt.
//
// As of the Change Date specified in that file, in accordance with
// the Business Source License, use of this software will be governed
// by the Apache License, Version 2.0, included in the file
// licenses/APL.txt.

package tree

import "github.com/cockroachdb/errors"

// RelocateRange represents an `ALTER RANGE .. RELOCATE ..`
// statement.
type RelocateRange struct {
	Rows            *Select
	ToStoreID       Expr
	FromStoreID     Expr
	SubjectReplicas RelocateSubject
}

// RelocateSubject indicates what replicas of a range should be relocated.
type RelocateSubject int8

const (
	// RelocateLease indicates that leases should be relocated.
	RelocateLease RelocateSubject = iota
	// RelocateVoters indicates what voter replicas should be relocated.
	RelocateVoters
	// RelocateNonVoters indicates that non-voter replicas should be relocated.
	RelocateNonVoters
)

// Format implementsthe NodeFormatter interface.
func (n *RelocateSubject) Format(ctx *FmtCtx) {
	ctx.WriteString(n.String())
}

// SQLRight Code Injection.
func (node *RelocateSubject) LogCurrentNode(depth int) *SQLRightIR {

	prefix := node.String()

	rootIR := &SQLRightIR{
		NodeHash: 183029,
		IRType:   TypeRelocateSubject,
		DataType: DataNone,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

func (n RelocateSubject) String() string {
	switch n {
	case RelocateLease:
		return "LEASE"
	case RelocateVoters:
		return "VOTERS"
	case RelocateNonVoters:
		return "NONVOTERS"
	default:
		panic(errors.AssertionFailedf("programming error: unhandled case %d", int(n)))
	}
}

// Format implements the NodeFormatter interface.
func (n *RelocateRange) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER RANGE RELOCATE ")
	ctx.FormatNode(&n.SubjectReplicas)
	// When relocating leases, the origin store is implicit.
	if n.SubjectReplicas != RelocateLease {
		ctx.WriteString(" FROM ")
		ctx.FormatNode(n.FromStoreID)
	}
	ctx.WriteString(" TO ")
	ctx.FormatNode(n.ToStoreID)
	ctx.WriteString(" FOR ")
	ctx.FormatNode(n.Rows)
}

// SQLRight Code Injection.
func (node *RelocateRange) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ALTER RANGE RELOCATE "

	subjectNode := node.SubjectReplicas.LogCurrentNode(depth + 1)

	infix := ""
	var pFromNode *SQLRightIR
	if node.SubjectReplicas != RelocateLease {
		infix = " FROM "
		pFromNode = node.FromStoreID.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		NodeHash: 160787,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    subjectNode,
		RNode:    pFromNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	toNode := node.ToStoreID.LogCurrentNode(depth + 1)

	rootIR = &SQLRightIR{
		NodeHash: 105538,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    toNode,
		Prefix:   "",
		Infix:    " TO ",
		Suffix:   "",
		Depth:    depth,
	}

	rowNode := node.Rows.LogCurrentNode(depth + 1)

	rootIR = &SQLRightIR{
		NodeHash: 138521,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    rowNode,
		Prefix:   "",
		Infix:    " FOR ",
		Suffix:   "",
		Depth:    depth,
	}

	rootIR.NodeHash = 239074
	rootIR.IRType = TypeRelocateRange

	return rootIR
}
