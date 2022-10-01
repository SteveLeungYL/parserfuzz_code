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

// Unlisten represents a UNLISTEN statement.
type Unlisten struct {
	ChannelName *UnresolvedObjectName
	Star        bool
}

var _ Statement = &Unlisten{}

// Format implements the NodeFormatter interface.
func (node *Unlisten) Format(ctx *FmtCtx) {
	ctx.WriteString("UNLISTEN ")
	if node.Star {
		ctx.WriteString("* ")
	} else if node.ChannelName != nil {
		ctx.FormatNode(node.ChannelName)
	}
}

// SQLRight Code Injection.
func (node *Unlisten) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "UNLISTEN "

	var channelNode *SQLRightIR

	if node.Star {
		prefix += "* "
	} else if node.ChannelName != nil {
		tmpChannelNode := &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataChannelName,
			ContextFlag: ContextUndefine,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.ChannelName.String(),
		}
		channelNode = tmpChannelNode
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnlisten,
		DataType: DataNone,
		LNode:    channelNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
		Str:      node.String(),
	}

	return rootIR
}

// String implements the Statement interface.
func (node *Unlisten) String() string {
	return AsString(node)
}
