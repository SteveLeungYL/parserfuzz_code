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

import "strconv"

// DeclareCursor represents a DECLARE statement.
type DeclareCursor struct {
	Name        Name
	Select      *Select
	Binary      bool
	Scroll      CursorScrollOption
	Sensitivity CursorSensitivity
	Hold        bool
}

// Format implements the NodeFormatter interface.
func (node *DeclareCursor) Format(ctx *FmtCtx) {
	ctx.WriteString("DECLARE ")
	ctx.FormatNode(&node.Name)
	ctx.WriteString(" ")
	if node.Binary {
		ctx.WriteString("BINARY ")
	}
	if node.Sensitivity != UnspecifiedSensitivity {
		ctx.WriteString(node.Sensitivity.String())
		ctx.WriteString(" ")
	}
	if node.Scroll != UnspecifiedScroll {
		ctx.WriteString(node.Scroll.String())
		ctx.WriteString(" ")
	}
	ctx.WriteString("CURSOR ")
	if node.Hold {
		ctx.WriteString("WITH HOLD ")
	}
	ctx.WriteString("FOR ")
	ctx.FormatNode(node.Select)
}

// SQLRight Code Injection.
func (node *DeclareCursor) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "DECLARE "

	nameNode := &SQLRightIR{
		NodeHash:    163785,
		IRType:      TypeIdentifier,
		DataType:    DataCursorName,
		ContextFlag: ContextDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Name.String(),
	}

	infix := " "

	var optBinaryNode *SQLRightIR
	if node.Binary {
		optBinaryNode = &SQLRightIR{
			NodeHash: 109967,
			IRType:   TypeOptBinary,
			DataType: DataNone,
			Prefix:   "BINARY ",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	} else {
		optBinaryNode = &SQLRightIR{
			NodeHash: 148486,
			IRType:   TypeOptBinary,
			DataType: DataNone,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR := &SQLRightIR{
		NodeHash: 248525,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    nameNode,
		RNode:    optBinaryNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}
	prefix = ""
	infix = ""

	var optSensitivity *SQLRightIR
	if node.Sensitivity != UnspecifiedSensitivity {
		prefix = node.Sensitivity.String() + " "
		optSensitivity = &SQLRightIR{
			NodeHash: 255141,
			IRType:   TypeOptSensitivity,
			DataType: DataNone,
			Prefix:   prefix,
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	} else {
		optSensitivity = &SQLRightIR{
			NodeHash: 203349,
			IRType:   TypeOptSensitivity,
			DataType: DataNone,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR = &SQLRightIR{
		NodeHash: 136674,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    optSensitivity,
		Prefix:   "",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	var optScrollNode *SQLRightIR
	if node.Scroll != UnspecifiedScroll {
		optScrollNode = &SQLRightIR{
			NodeHash: 220854,
			IRType:   TypeOptScroll,
			DataType: DataNone,
			Prefix:   node.Scroll.String(),
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		rootIR = &SQLRightIR{
			NodeHash: 18027,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optScrollNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	} else {
		optScrollNode = &SQLRightIR{
			NodeHash: 71513,
			IRType:   TypeOptScroll,
			DataType: DataNone,
			Prefix:   "",
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}
		rootIR = &SQLRightIR{
			NodeHash: 187581,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optScrollNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	infix = "CURSOR "
	if node.Hold {
		infix += "WITH HOLD "
	}
	infix += "FOR "

	selectNode := node.Select.LogCurrentNode(depth + 1)

	rootIR = &SQLRightIR{
		NodeHash: 123869,
		IRType:   TypeDeclareCursor,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    selectNode,
		Prefix:   "",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// CursorScrollOption represents the scroll option, if one was given, for a
// DECLARE statement.
type CursorScrollOption int8

const (
	// UnspecifiedScroll represents no SCROLL option having been given. In
	// Postgres, this is like NO SCROLL, but the returned cursor also supports
	// some simple cases of backward seeking. For CockroachDB, this is the same
	// as NO SCROLL.
	UnspecifiedScroll CursorScrollOption = iota
	// Scroll represents the SCROLL option. It is supposed to indicate that the
	// declared cursor is "scrollable", meaning it can be seeked backward.
	Scroll
	// NoScroll represents the NO SCROLL option, which means that the declared
	// cursor can only be moved forward.
	NoScroll
)

func (o CursorScrollOption) String() string {
	switch o {
	case Scroll:
		return "SCROLL"
	case NoScroll:
		return "NO SCROLL"
	}
	return ""
}

// CursorSensitivity represents the "sensitivity" of a cursor, which describes
// whether it sees writes that occur within the transaction after it was
// declared.
// CockroachDB, like Postgres, only supports "insensitive" cursors, and all
// three variants of sensitivity here resolve to insensitive. SENSITIVE cursors
// are not supported.
type CursorSensitivity int

const (
	// UnspecifiedSensitivity indicates that no sensitivity was specified. This
	// is the same as INSENSITIVE.
	UnspecifiedSensitivity CursorSensitivity = iota
	// Insensitive indicates that the cursor is "insensitive" to subsequent
	// writes, meaning that it sees a snapshot of data from the moment it was
	// declared, and won't see subsequent writes within the transaction.
	Insensitive
	// Asensitive indicates that "the cursor is implementation dependent".
	Asensitive
)

func (o CursorSensitivity) String() string {
	switch o {
	case Insensitive:
		return "INSENSITIVE"
	case Asensitive:
		return "ASENSITIVE"
	}
	return ""
}

// CursorStmt represents the shared structure between a FETCH and MOVE statement.
type CursorStmt struct {
	Name      Name
	FetchType FetchType
	Count     int64
}

// FetchCursor represents a FETCH statement.
type FetchCursor struct {
	CursorStmt
}

// MoveCursor represents a MOVE statement.
type MoveCursor struct {
	CursorStmt
}

// FetchType represents the type of a FETCH (or MOVE) statement.
type FetchType int

const (
	// FetchNormal represents a FETCH statement that doesn't have a special
	// qualifier. It's used for FORWARD, BACKWARD, NEXT, and PRIOR.
	FetchNormal FetchType = iota
	// FetchRelative represents a FETCH RELATIVE statement.
	FetchRelative
	// FetchAbsolute represents a FETCH ABSOLUTE statement.
	FetchAbsolute
	// FetchFirst represents a FETCH FIRST statement.
	FetchFirst
	// FetchLast represents a FETCH LAST statement.
	FetchLast
	// FetchAll represents a FETCH ALL statement.
	FetchAll
	// FetchBackwardAll represents a FETCH BACKWARD ALL statement.
	FetchBackwardAll
)

func (o FetchType) String() string {
	switch o {
	case FetchNormal:
		return ""
	case FetchRelative:
		return "RELATIVE"
	case FetchAbsolute:
		return "ABSOLUTE"
	case FetchFirst:
		return "FIRST"
	case FetchLast:
		return "LAST"
	case FetchAll:
		return "ALL"
	case FetchBackwardAll:
		return "BACKWARD ALL"
	}
	return ""
}

// HasCount returns true if the given fetch type should be printed with an
// associated count.
func (o FetchType) HasCount() bool {
	switch o {
	case FetchNormal, FetchRelative, FetchAbsolute:
		return true
	}
	return false
}

// Format implements the NodeFormatter interface.
func (c CursorStmt) Format(ctx *FmtCtx) {
	fetchType := c.FetchType.String()
	if fetchType != "" {
		ctx.WriteString(fetchType)
		ctx.WriteString(" ")
	}
	if c.FetchType.HasCount() {
		if ctx.HasFlags(FmtHideConstants) {
			ctx.WriteByte('0')
		} else {
			ctx.WriteString(strconv.Itoa(int(c.Count)))
		}
		ctx.WriteString(" ")
	}
	ctx.FormatNode(&c.Name)
}

// SQLRight Code Injection.
func (node *CursorStmt) LogCurrentNode(depth int) *SQLRightIR {

	fetchTypeStr := node.FetchType.String()

	fetchTypeNode := &SQLRightIR{
		NodeHash: 154656,
		IRType:   TypeOptFetchType,
		DataType: DataNone,
		Prefix:   fetchTypeStr, // Could be empty string
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	var countNode *SQLRightIR
	if node.FetchType.HasCount() {

		intLiteral := &SQLRightIR{
			NodeHash:     116231,
			IRType:       TypeIntegerLiteral,
			DataType:     DataLiteral,
			DataAffinity: AFFIINT,
			Prefix:       "",
			Infix:        "",
			Suffix:       "",
			Depth:        depth,
			IValue:       node.Count,
		}
		countNode = &SQLRightIR{
			NodeHash: 10790,
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    intLiteral,
			Infix:    " ",
			Depth:    depth,
		}
	}

	rootIR := &SQLRightIR{
		NodeHash: 63898,
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    fetchTypeNode,
		RNode:    countNode,
		Prefix:   "",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	nameNode := &SQLRightIR{
		NodeHash:    97931,
		IRType:      TypeIdentifier,
		DataType:    DataCursorName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Name.String(),
	}

	rootIR = &SQLRightIR{
		NodeHash: 80339,
		IRType:   TypeCursorStmt,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    nameNode,
		Prefix:   "",
		Infix:    " ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// Format implements the NodeFormatter interface.
func (f FetchCursor) Format(ctx *FmtCtx) {
	ctx.WriteString("FETCH ")
	f.CursorStmt.Format(ctx)
}

// SQLRight Code Injection.
func (node *FetchCursor) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "FETCH "

	cursorStmt := node.CursorStmt.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		NodeHash: 99380,
		IRType:   TypeFetchCursor,
		DataType: DataNone,
		LNode:    cursorStmt,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// Format implements the NodeFormatter interface.
func (m MoveCursor) Format(ctx *FmtCtx) {
	ctx.WriteString("MOVE ")
	m.CursorStmt.Format(ctx)
}

// SQLRight Code Injection.
func (node *MoveCursor) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "MOVE "

	cursorStmt := node.CursorStmt.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		NodeHash: 111075,
		IRType:   TypeMoveCursor,
		DataType: DataNone,
		LNode:    cursorStmt,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// CloseCursor represents a CLOSE statement.
type CloseCursor struct {
	Name Name
	All  bool
}

// Format implements the NodeFormatter interface.
func (c CloseCursor) Format(ctx *FmtCtx) {
	ctx.WriteString("CLOSE ")
	if c.All {
		ctx.WriteString("ALL")
	} else {
		ctx.FormatNode(&c.Name)
	}
}

// SQLRight Code Injection.
func (node *CloseCursor) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "CLOSE "

	var nameNode *SQLRightIR
	if node.All {
		prefix += "ALL"
	} else {
		tmpNameNode := &SQLRightIR{
			NodeHash:    148495,
			IRType:      TypeIdentifier,
			DataType:    DataCursorName,
			ContextFlag: ContextUndefine,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Name.String(),
		}
		nameNode = tmpNameNode
	}

	rootIR := &SQLRightIR{
		NodeHash: 131911,
		IRType:   TypeCloseCursor,
		DataType: DataNone,
		LNode:    nameNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}
