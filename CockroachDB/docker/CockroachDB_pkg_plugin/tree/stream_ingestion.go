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

// StreamIngestion represents a RESTORE FROM REPLICATION STREAM statement.
type StreamIngestion struct {
	Targets  BackupTargetList
	From     StringOrPlaceholderOptList
	AsTenant TenantID
}

var _ Statement = &StreamIngestion{}

// Format implements the NodeFormatter interface.
func (node *StreamIngestion) Format(ctx *FmtCtx) {
	ctx.WriteString("RESTORE ")
	ctx.FormatNode(&node.Targets)
	ctx.WriteString(" ")
	ctx.WriteString("FROM REPLICATION STREAM FROM ")
	ctx.FormatNode(&node.From)
	if node.AsTenant.Specified {
		ctx.WriteString(" AS TENANT ")
		ctx.FormatNode(&node.AsTenant)
	}
}

// SQLRight Code Injection.
func (node *StreamIngestion) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "RESTORE "

	targetNode := node.Targets.LogCurrentNode(depth + 1)

	infix := " FROM REPLICATION STREAM FROM"

	fromNode := node.From.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		NodeHash: 140550,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    targetNode,
		RNode:    fromNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	infix = ""
	if node.AsTenant.Specified {
		infix = " AS TENANT "
		asNode := node.AsTenant.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			NodeHash: 201170,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    asNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.NodeHash = 232397
	rootIR.IRType = TypeStreamIngestion

	return rootIR
}
