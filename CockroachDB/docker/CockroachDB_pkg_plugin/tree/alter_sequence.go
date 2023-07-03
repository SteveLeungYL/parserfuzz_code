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

// AlterSequence represents an ALTER SEQUENCE statement, except in the case of
// ALTER SEQUENCE <seqName> RENAME TO <newSeqName>, which is represented by a
// RenameTable node.
type AlterSequence struct {
	IfExists bool
	Name     *UnresolvedObjectName
	Options  SequenceOptions
}

// Format implements the NodeFormatter interface.
func (node *AlterSequence) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER SEQUENCE ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(node.Name)
	ctx.FormatNode(&node.Options)
}

// SQLRight Code Injection.
func (node *AlterSequence) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "ALTER SEQUENCE "

	optIfExistStr := ""
	if node.IfExists {
		optIfExistStr = "IF EXISTS "
	}
	ifExistsNode := &SQLRightIR{
		NodeHash: 116262,
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	sequenceNameNode := &SQLRightIR{
		NodeHash:    49364,
		IRType:      TypeIdentifier,
		DataType:    DataSequenceName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Name.String(),
	}

	rootIR := &SQLRightIR{
		NodeHash: 201946,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    ifExistsNode,
		RNode:    sequenceNameNode,
		Prefix:   prefix,
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	optionNode := node.Options.LogCurrentNode(depth + 1)

	rootIR = &SQLRightIR{
		NodeHash: 55591,
		IRType:   TypeAlterSequence,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    optionNode,
		Prefix:   "",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}
