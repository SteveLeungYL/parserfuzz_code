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
	"github.com/cockroachdb/cockroach/pkg/sql/pgwire/pgcode"
	"github.com/cockroachdb/cockroach/pkg/sql/pgwire/pgerror"
)

// CopyFrom represents a COPY FROM statement.
type CopyFrom struct {
	Table   TableName
	Columns NameList
	Stdin   bool
	Options CopyOptions
}

// CopyOptions describes options for COPY execution.
type CopyOptions struct {
	Destination Expr
	CopyFormat  CopyFormat
	Delimiter   Expr
	Null        Expr
	Escape      *StrVal
	Header      bool
}

var _ NodeFormatter = &CopyOptions{}

// Format implements the NodeFormatter interface.
func (node *CopyFrom) Format(ctx *FmtCtx) {
	ctx.WriteString("COPY ")
	ctx.FormatNode(&node.Table)
	if len(node.Columns) > 0 {
		ctx.WriteString(" (")
		ctx.FormatNode(&node.Columns)
		ctx.WriteString(")")
	}
	ctx.WriteString(" FROM ")
	if node.Stdin {
		ctx.WriteString("STDIN")
	}
	if !node.Options.IsDefault() {
		ctx.WriteString(" WITH ")
		ctx.FormatNode(&node.Options)
	}
}

// SQLRight Code Injection.
func (node *CopyFrom) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "COPY "

	tableNode := node.Table.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    tableNode,
		Prefix:   prefix,
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	if len(node.Columns) > 0 {
		infix := " ("
		suffix := ")"
		columnNode := node.Columns.LogCurrentNodeWithType(depth+1, DataColumnName)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    columnNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   suffix,
			Depth:    depth,
		}
	}

	infix := " FROM "
	var optStdin *SQLRightIR
	if node.Stdin {
		optStdin = &SQLRightIR{
			IRType:   TypeOptStdin,
			DataType: DataNone,
			Prefix:   "STDIN",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	} else {
		optStdin = &SQLRightIR{
			IRType:   TypeOptStdin,
			DataType: DataNone,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    optStdin,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	infix = ""
	var optionNode *SQLRightIR
	if !node.Options.IsDefault() {
		infix = " WITH "
		optionNode = node.Options.LogCurrentNode(depth + 1)
	}

	rootIR = &SQLRightIR{
		IRType:   TypeCopyFrom,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    optionNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// Format implements the NodeFormatter interface
func (o *CopyOptions) Format(ctx *FmtCtx) {
	var addSep bool
	maybeAddSep := func() {
		if addSep {
			ctx.WriteString(" ")
		}
		addSep = true
	}

	if o.CopyFormat != CopyFormatText {
		maybeAddSep()
		switch o.CopyFormat {
		case CopyFormatBinary:
			ctx.WriteString("BINARY")
		case CopyFormatCSV:
			ctx.WriteString("CSV")
		}
	}
	if o.Delimiter != nil {
		maybeAddSep()
		ctx.WriteString("DELIMITER ")
		ctx.FormatNode(o.Delimiter)
		addSep = true
	}
	if o.Null != nil {
		maybeAddSep()
		ctx.WriteString("NULL ")
		ctx.FormatNode(o.Null)
		addSep = true
	}
	if o.Destination != nil {
		maybeAddSep()
		// Lowercase because that's what has historically been produced
		// by copy_file_upload.go, so this will provide backward
		// compatibility with older servers.
		ctx.WriteString("destination = ")
		ctx.FormatNode(o.Destination)
		addSep = true
	}
	if o.Escape != nil {
		maybeAddSep()
		ctx.WriteString("ESCAPE ")
		ctx.FormatNode(o.Escape)
	}
	if o.Header {
		maybeAddSep()
		ctx.WriteString("HEADER")
	}
}

// SQLRight Code Injection.
func (node *CopyOptions) LogCurrentNode(depth int) *SQLRightIR {

	infix := ""
	var copyFormatNode *SQLRightIR
	if node.CopyFormat != CopyFormatText {
		copyFormatStr := ""
		switch node.CopyFormat {
		case CopyFormatBinary:
			copyFormatStr = "BINARY"
		case CopyFormatCSV:
			copyFormatStr = "CSV"
		}

		tmpCopy := &SQLRightIR{
			IRType:   TypeCopyFormat,
			DataType: DataNone,
			Prefix:   copyFormatStr,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		copyFormatNode = tmpCopy
		infix = ", "
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    copyFormatNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	if node.Delimiter != nil {

		tmpInfix := infix + "DELIMITER "
		delimiterNode := node.Delimiter.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    delimiterNode,
			Prefix:   "",
			Infix:    tmpInfix,
			Suffix:   "",
			Depth:    depth,
		}
		infix = ", "
	}

	if node.Null != nil {

		tmpInfix := infix + "NULL "
		nullNode := node.Null.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    nullNode,
			Prefix:   "",
			Infix:    tmpInfix,
			Suffix:   "",
			Depth:    depth,
		}
		infix = ", "
	}

	if node.Destination != nil {

		tmpInfix := infix + "destination = "
		destinationNode := node.Destination.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    destinationNode,
			Prefix:   "",
			Infix:    tmpInfix,
			Suffix:   "",
			Depth:    depth,
		}
		infix = ", "
	}

	if node.Escape != nil {

		tmpInfix := infix + "ESCAPE = "
		escapeNode := node.Destination.LogCurrentNode(depth + 1)

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    escapeNode,
			Prefix:   "",
			Infix:    tmpInfix,
			Suffix:   "",
			Depth:    depth,
		}
		infix = ", "
	}

	if node.Header {
		tmpInfix := infix + "HEADER "

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			Prefix:   "",
			Infix:    tmpInfix,
			Suffix:   "",
			Depth:    depth,
		}
		infix = ", "
	}

	rootIR.IRType = TypeCopyOptions

	return rootIR
}

// IsDefault returns true if this struct has default value.
func (o CopyOptions) IsDefault() bool {
	return o == CopyOptions{}
}

// CombineWith merges other options into this struct. An error is returned if
// the same option merged multiple times.
func (o *CopyOptions) CombineWith(other *CopyOptions) error {
	if other.Destination != nil {
		if o.Destination != nil {
			return pgerror.Newf(pgcode.Syntax, "destination option specified multiple times")
		}
		o.Destination = other.Destination
	}
	if other.CopyFormat != CopyFormatText {
		if o.CopyFormat != CopyFormatText {
			return pgerror.Newf(pgcode.Syntax, "format option specified multiple times")
		}
		o.CopyFormat = other.CopyFormat
	}
	if other.Delimiter != nil {
		if o.Delimiter != nil {
			return pgerror.Newf(pgcode.Syntax, "delimiter option specified multiple times")
		}
		o.Delimiter = other.Delimiter
	}
	if other.Null != nil {
		if o.Null != nil {
			return pgerror.Newf(pgcode.Syntax, "null option specified multiple times")
		}
		o.Null = other.Null
	}
	if other.Escape != nil {
		if o.Escape != nil {
			return pgerror.Newf(pgcode.Syntax, "escape option specified multiple times")
		}
		o.Escape = other.Escape
	}
	if other.Header {
		o.Header = true
	}
	return nil
}

// CopyFormat identifies a COPY data format.
type CopyFormat int

// Valid values for CopyFormat.
const (
	CopyFormatText CopyFormat = iota
	CopyFormatBinary
	CopyFormatCSV
)
