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
	"github.com/cockroachdb/cockroach/pkg/sql/lexbase"
	"github.com/cockroachdb/cockroach/pkg/sql/pgwire/pgcode"
	"github.com/cockroachdb/cockroach/pkg/sql/pgwire/pgerror"
	"github.com/cockroachdb/errors"
)

// A Name is an SQL identifier.
//
// In general, a Name is the result of parsing a name nonterminal, which is used
// in the grammar where reserved keywords cannot be distinguished from
// identifiers. A Name that matches a reserved keyword must thus be quoted when
// formatted. (Names also need quoting for a variety of other reasons; see
// isBareIdentifier.)
//
// For historical reasons, some Names are instead the result of parsing
// `unrestricted_name` nonterminals. See UnrestrictedName for details.
type Name string

// Format implements the NodeFormatter interface.
func (n *Name) Format(ctx *FmtCtx) {
	f := ctx.flags
	if f.HasFlags(FmtAnonymize) && !isArityIndicatorString(string(*n)) {
		ctx.WriteByte('_')
	} else {
		lexbase.EncodeRestrictedSQLIdent(&ctx.Buffer, string(*n), f.EncodeFlags())
	}
}

// NameStringP escapes an identifier stored in a heap string to a SQL
// identifier, avoiding a heap allocation.
func NameStringP(s *string) string {
	return ((*Name)(s)).String()
}

// NameString escapes an identifier stored in a string to a SQL
// identifier.
func NameString(s string) string {
	return ((*Name)(&s)).String()
}

// ErrNameStringP escapes an identifier stored a string to a SQL
// identifier suitable for printing in error messages, avoiding a heap
// allocation.
func ErrNameStringP(s *string) string {
	return ErrString(((*Name)(s)))
}

// ErrNameString escapes an identifier stored a string to a SQL
// identifier suitable for printing in error messages.
func ErrNameString(s string) string {
	return ErrString(((*Name)(&s)))
}

// Normalize normalizes to lowercase and Unicode Normalization Form C
// (NFC).
func (n Name) Normalize() string {
	return lexbase.NormalizeName(string(n))
}

// An UnrestrictedName is a Name that does not need to be escaped when it
// matches a reserved keyword.
//
// In general, an UnrestrictedName is the result of parsing an unrestricted_name
// nonterminal, which is used in the grammar where reserved keywords can be
// unambiguously interpreted as identifiers. When formatted, an UnrestrictedName
// that matches a reserved keyword thus does not need to be quoted.
//
// For historical reasons, some unrestricted_name nonterminals are instead
// parsed as Names. The only user-visible impact of this is that we are too
// aggressive about quoting names in certain positions. New grammar rules should
// prefer to parse unrestricted_name nonterminals into UnrestrictedNames.
type UnrestrictedName string

// Format implements the NodeFormatter interface.
func (u *UnrestrictedName) Format(ctx *FmtCtx) {
	f := ctx.flags
	if f.HasFlags(FmtAnonymize) {
		ctx.WriteByte('_')
	} else {
		lexbase.EncodeUnrestrictedSQLIdent(&ctx.Buffer, string(*u), f.EncodeFlags())
	}
}

// ToStrings converts the name list to an array of regular strings.
func (l NameList) ToStrings() []string {
	if l == nil {
		return nil
	}
	names := make([]string, len(l))
	for i, n := range l {
		names[i] = string(n)
	}
	return names
}

// A NameList is a list of identifiers.
type NameList []Name

// Format implements the NodeFormatter interface.
func (l *NameList) Format(ctx *FmtCtx) {
	for i := range *l {
		if i > 0 {
			ctx.WriteString(", ")
		}
		ctx.FormatNode(&(*l)[i])
	}
}

// SQLRight Code Injection.
func (node *NameList) LogCurrentNode(depth int) *SQLRightIR {
	return node.LogCurrentNodeWithType(depth, DataUnknownType)
}

// SQLRight Code Injection.
func (node *NameList) LogCurrentNodeWithType(depth int, dataType SQLRightDataType) *SQLRightIR {

	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{}
	for i, n := range *node {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    dataType,
				ContextFlag: ContextUse,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         n.String(),
			}
			var RNode *SQLRightIR
			infix := ""
			if len(*node) >= 2 {
				infix = ", "
				tmpRNode := &SQLRightIR{
					IRType:      TypeIdentifier,
					DataType:    dataType,
					ContextFlag: ContextUse,
					Prefix:      "",
					Infix:       "",
					Suffix:      "",
					Depth:       depth,
					Str:         (*node)[1].String(),
				}
				RNode = tmpRNode
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
			RNode := &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    dataType,
				ContextFlag: ContextUse,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         n.String(),
			}

			tmpIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: dataType,
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
	tmpIR.IRType = TypeNameList
	return tmpIR
}

// Contains returns true if the NameList contains the name.
func (l NameList) Contains(name Name) bool {
	for _, n := range l {
		if n == name {
			return true
		}
	}
	return false
}

// ArraySubscript corresponds to the syntax `<name>[ ... ]`.
type ArraySubscript struct {
	Begin Expr
	End   Expr
	Slice bool
}

// Format implements the NodeFormatter interface.
func (a *ArraySubscript) Format(ctx *FmtCtx) {
	ctx.WriteByte('[')
	if a.Begin != nil {
		ctx.FormatNode(a.Begin)
	}
	if a.Slice {
		ctx.WriteByte(':')
		if a.End != nil {
			ctx.FormatNode(a.End)
		}
	}
	ctx.WriteByte(']')
}

// SQLRight Code Injection.
func (node *ArraySubscript) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "["

	var beginNode *SQLRightIR
	if node.Begin != nil {
		beginNode = node.Begin.LogCurrentNode(depth + 1)
	}

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    beginNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if node.Slice {
		infix := ":"

		var endNode *SQLRightIR
		if node.End != nil {
			endNode = node.End.LogCurrentNode(depth + 1)
		}
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    endNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.Suffix = "]"
	rootIR.IRType = TypeArraySubscript

	return rootIR
}

// UnresolvedName corresponds to an unresolved qualified name.
type UnresolvedName struct {
	// NumParts indicates the number of name parts specified, including
	// the star. Always 1 or greater.
	NumParts int

	// Star indicates the name ends with a star.
	// In that case, Parts below is empty in the first position.
	Star bool

	// Parts are the name components, in reverse order.
	// There are at most 4: column, table, schema, catalog/db.
	//
	// Note: NameParts has a fixed size so that we avoid a heap
	// allocation for the slice every time we construct an
	// UnresolvedName. It does imply however that Parts does not have
	// a meaningful "length"; its actual length (the number of parts
	// specified) is populated in NumParts above.
	Parts NameParts
}

// NameParts is the array of strings that composes the path in an
// UnresolvedName.
type NameParts = [4]string

// Format implements the NodeFormatter interface.
func (u *UnresolvedName) Format(ctx *FmtCtx) {
	stopAt := 1
	if u.Star {
		stopAt = 2
	}
	for i := u.NumParts; i >= stopAt; i-- {
		// The first part to print is the last item in u.Parts.  It is also
		// a potentially restricted name to disambiguate from keywords in
		// the grammar, so print it out as a "Name". Every part after that is
		// necessarily an unrestricted name.
		if i == u.NumParts {
			ctx.FormatNode((*Name)(&u.Parts[i-1]))
		} else {
			ctx.FormatNode((*UnrestrictedName)(&u.Parts[i-1]))
		}
		if i > 1 {
			ctx.WriteByte('.')
		}
	}
	if u.Star {
		ctx.WriteByte('*')
	}
}

// SQLRight Code Injection.
func (node *UnresolvedName) LogCurrentNode(depth int) *SQLRightIR {

	var nodeList []*SQLRightIR

	// The name list is in the reverse order.
	// At most 4: column, table, schema, catalog/db.
	for i := 0; i < node.NumParts; i++ {
		// The first part to print is the last item in u.Parts.  It is also
		// a potentially restricted name to disambiguate from keywords in
		// the grammar, so print it out as a "Name". Every part after that is
		// necessarily an unrestricted name.
		if i == 0 {
			idenStr := node.Parts[i]
			if node.Star {
				idenStr = "*"
			}
			curNode := &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    DataColumnName,
				ContextFlag: ContextUse,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         idenStr,
			}
			nodeList = append(nodeList, curNode)
		} else {
			dataType := DataUnknownType
			if i == 1 {
				dataType = DataTableName
			} else if i == 2 {
				dataType = DataSchemaName
			} else if i == 3 {
				dataType = DataDatabaseName
			}
			curNode := &SQLRightIR{
				IRType:      TypeIdentifier,
				DataType:    dataType,
				ContextFlag: ContextUse,
				Prefix:      "",
				Infix:       "",
				Suffix:      "",
				Depth:       depth,
				Str:         node.Parts[i],
			}
			nodeList = append(nodeList, curNode)
		}
	}

	// Reverse the nodeList:
	for i, j := 0, len(nodeList)-1; i < j; i, j = i+1, j-1 {
		nodeList[i], nodeList[j] = nodeList[j], nodeList[i]
	}

	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{}
	for i, n := range nodeList {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := (n)
			var RNode *SQLRightIR
			infix := ""
			suffix := ""

			if len(nodeList) >= 2 {
				infix = "."
				RNode = (nodeList[1])
			}
			tmpIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   "",
				Infix:    infix,
				Suffix:   suffix,
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
			RNode := n

			tmpIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   "",
				Infix:    ".",
				Suffix:   "",
				Depth:    depth,
			}
		}
	}

	// Only flag the root node for the type.
	tmpIR.IRType = TypeUnresolvedName
	return tmpIR

}

func (u *UnresolvedName) String() string { return AsString(u) }

// NewUnresolvedName constructs an UnresolvedName from some strings.
func NewUnresolvedName(args ...string) *UnresolvedName {
	n := MakeUnresolvedName(args...)
	return &n
}

// MakeUnresolvedName constructs an UnresolvedName from some strings.
func MakeUnresolvedName(args ...string) UnresolvedName {
	n := UnresolvedName{NumParts: len(args)}
	for i := 0; i < len(args); i++ {
		n.Parts[i] = args[len(args)-1-i]
	}
	return n
}

// ToUnresolvedObjectName converts an UnresolvedName to an UnresolvedObjectName.
func (u *UnresolvedName) ToUnresolvedObjectName(idx AnnotationIdx) (*UnresolvedObjectName, error) {
	if u.NumParts == 4 {
		return nil, pgerror.Newf(pgcode.Syntax, "improper qualified name (too many dotted names): %s", u)
	}
	return NewUnresolvedObjectName(
		u.NumParts,
		[3]string{u.Parts[0], u.Parts[1], u.Parts[2]},
		idx,
	)
}

// ToFunctionName converts an UnresolvedName to a FunctionName.
func (u *UnresolvedName) ToFunctionName() (*FunctionName, error) {
	un, err := u.ToUnresolvedObjectName(NoAnnotation)
	if err != nil {
		return nil, errors.Newf("invalid function name: %s", u.String())
	}
	fn := un.ToFunctionName()
	return &fn, nil
}
