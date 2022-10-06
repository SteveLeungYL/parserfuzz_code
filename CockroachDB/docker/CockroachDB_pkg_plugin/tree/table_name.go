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

// TableName corresponds to the name of a table in a FROM clause,
// INSERT or UPDATE statement, etc.
//
// This is constructed for incoming SQL queries from an UnresolvedObjectName,
//
// Internal uses of this struct should not construct instances of
// TableName directly, and instead use the NewTableName /
// MakeTableName functions underneath.
//
// TableName is a public type for objName. It exposes the fields
// and can be default-constructed but cannot be instantiated with a
// non-default value; this encourages the use of the constructors below.
type TableName struct {
	objName
}

// Format implements the NodeFormatter interface.
func (t *TableName) Format(ctx *FmtCtx) {
	if ctx.tableNameFormatter != nil {
		ctx.tableNameFormatter(ctx, t)
		return
	}
	t.ObjectNamePrefix.Format(ctx)
	if t.ExplicitSchema || ctx.alwaysFormatTablePrefix() {
		ctx.WriteByte('.')
	}
	ctx.FormatNode(&t.ObjectName)
}

// SQLRight Code Injection.
func (node *TableName) LogCurrentNode(depth int) *SQLRightIR {
	return node.LogCurrentNodeWithType(depth, DataTableName, ContextUse)
}

// SQLRight Code Injection.
func (node *TableName) LogCurrentNodeWithType(depth int, dataType SQLRightDataType, flag SQLRightContextFlag) *SQLRightIR {

	rootIR := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    dataType,
		ContextFlag: flag,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.String(),
	}

	return rootIR
}

func (t *TableName) String() string { return AsString(t) }

func (t *TableName) objectName() {}

// FQString renders the table name in full, not omitting the prefix
// schema and catalog names. Suitable for logging, etc.
func (t *TableName) FQString() string {
	ctx := NewFmtCtx(FmtSimple)
	ctx.FormatNode(&t.CatalogName)
	ctx.WriteByte('.')
	ctx.FormatNode(&t.SchemaName)
	ctx.WriteByte('.')
	ctx.FormatNode(&t.ObjectName)
	return ctx.CloseAndGetString()
}

// Table retrieves the unqualified table name.
func (t *TableName) Table() string {
	return string(t.ObjectName)
}

// Equals returns true if the two table names are identical (including
// the ExplicitSchema/ExplicitCatalog flags).
func (t *TableName) Equals(other *TableName) bool {
	return *t == *other
}

// tableExpr implements the TableExpr interface.
func (*TableName) tableExpr() {}

// NewTableNameWithSchema creates a new table name qualified with a given
// catalog and schema.
func NewTableNameWithSchema(db, sc, tbl Name) *TableName {
	tn := MakeTableNameWithSchema(db, sc, tbl)
	return &tn
}

// MakeTableNameWithSchema creates a new fully qualified table name.
func MakeTableNameWithSchema(db, schema, tbl Name) TableName {
	return TableName{objName{
		ObjectName: tbl,
		ObjectNamePrefix: ObjectNamePrefix{
			CatalogName:     db,
			SchemaName:      schema,
			ExplicitSchema:  true,
			ExplicitCatalog: true,
		},
	}}
}

// MakeTableNameFromPrefix creates a table name from an unqualified name
// and a resolved prefix.
func MakeTableNameFromPrefix(prefix ObjectNamePrefix, object Name) TableName {
	return TableName{objName{
		ObjectName:       object,
		ObjectNamePrefix: prefix,
	}}
}

// MakeUnqualifiedTableName creates a new base table name.
func MakeUnqualifiedTableName(tbl Name) TableName {
	return TableName{objName{
		ObjectName: tbl,
	}}
}

// NewUnqualifiedTableName creates a new base table name.
func NewUnqualifiedTableName(tbl Name) *TableName {
	tn := MakeUnqualifiedTableName(tbl)
	return &tn
}

func makeTableNameFromUnresolvedName(n *UnresolvedName) TableName {
	return TableName{objName{
		ObjectName:       Name(n.Parts[0]),
		ObjectNamePrefix: makeObjectNamePrefixFromUnresolvedName(n),
	}}
}

func makeObjectNamePrefixFromUnresolvedName(n *UnresolvedName) ObjectNamePrefix {
	return ObjectNamePrefix{
		SchemaName:      Name(n.Parts[1]),
		CatalogName:     Name(n.Parts[2]),
		ExplicitSchema:  n.NumParts >= 2,
		ExplicitCatalog: n.NumParts >= 3,
	}
}

// TableNames represents a comma separated list (see the Format method)
// of table names.
type TableNames []TableName

// Format implements the NodeFormatter interface.
func (ts *TableNames) Format(ctx *FmtCtx) {
	sep := ""
	for i := range *ts {
		ctx.WriteString(sep)
		ctx.FormatNode(&(*ts)[i])
		sep = ", "
	}
}

// SQLRight Code Injection.
func (node *TableNames) LogCurrentNode(depth int) *SQLRightIR {
	return node.LogCurrentNodeWithType(depth, DataTableName, ContextUse)
}

// SQLRight Code Injection.
func (node *TableNames) LogCurrentNodeWithType(depth int, dataType SQLRightDataType, contextFlag SQLRightContextFlag) *SQLRightIR {

	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{}
	for i, n := range *node {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n.LogCurrentNodeWithType(depth+1, dataType, contextFlag)
			var RNode *SQLRightIR
			infix := ""
			if len(*node) >= 2 {
				infix = ", "
				RNode = (*node)[1].LogCurrentNodeWithType(depth+1, dataType, contextFlag)
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
			RNode := n.LogCurrentNodeWithType(depth+1, dataType, contextFlag)

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
	tmpIR.IRType = TypeTableNames
	return tmpIR

}

func (ts *TableNames) String() string { return AsString(ts) }

// TableIndexName refers to a table index. There are a few cases:
//
//   - if both the table name and the index name are set, refers to a specific
//     index in a specific table.
//
//   - if the table name is set and index name is empty, refers to the primary
//     index of that table.
//
//   - if the table name is empty and the index name is set, refers to an index
//     of that name among all tables within a catalog/schema; if there is a
//     duplicate name, that will result in an error. Note that it is possible to
//     specify the schema or catalog without specifying a table name; in this
//     case, Table.ObjectNamePrefix has the fields set but Table.ObjectName is
//     empty.
type TableIndexName struct {
	Table TableName
	Index UnrestrictedName
}

// Format implements the NodeFormatter interface.
func (n *TableIndexName) Format(ctx *FmtCtx) {
	if n.Index == "" {
		ctx.FormatNode(&n.Table)
		return
	}

	if n.Table.ObjectName != "" {
		// The table is specified.
		ctx.FormatNode(&n.Table)
		ctx.WriteByte('@')
		ctx.FormatNode(&n.Index)
		return
	}

	// The table is not specified. The schema/catalog can still be specified.
	if n.Table.ExplicitSchema || ctx.alwaysFormatTablePrefix() {
		ctx.FormatNode(&n.Table.ObjectNamePrefix)
		ctx.WriteByte('.')
	}
	// In this case, we must format the index name as a restricted name (quotes
	// must be added for reserved keywords).
	ctx.FormatNode((*Name)(&n.Index))
}

// SQLRight Code Injection.
func (node *TableIndexName) LogCurrentNode(depth int) *SQLRightIR {
	return node.LogCurrentNodeWithType(depth, DataIndexName, ContextUse)
}

// SQLRight Code Injection.
func (node *TableIndexName) LogCurrentNodeWithType(depth int, datatype SQLRightDataType, contextFlag SQLRightContextFlag) *SQLRightIR {

	if node.Index == "" {
		tableNode := &SQLRightIR{
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
			IRType:   TypeTableIndexName,
			DataType: DataNone,
			LNode:    tableNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
		return rootIR
	}

	if node.Table.ObjectName != "" {
		// The table is specified.
		tableNode := &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    DataTableName,
			ContextFlag: ContextUse,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Table.String(),
		}

		infix := "@"

		indexNode := &SQLRightIR{
			IRType:      TypeIdentifier,
			DataType:    datatype,
			ContextFlag: contextFlag,
			Prefix:      "",
			Infix:       "",
			Suffix:      "",
			Depth:       depth,
			Str:         node.Index.String(),
		}

		rootIR := &SQLRightIR{
			IRType:   TypeTableIndexName,
			DataType: DataNone,
			LNode:    tableNode,
			RNode:    indexNode,
			Prefix:   "",
			Infix:    infix,
			Suffix:   "",
			Depth:    depth,
		}
		return rootIR
	}

	// The table is not specified. The schema/catalog can still be specified.
	var prefixNode *SQLRightIR
	infix := ""
	if node.Table.ExplicitSchema {
		prefixNode = node.Table.ObjectNamePrefix.LogCurrentNode(depth + 1)
		infix = "."
	}
	// In this case, we must format the index name as a restricted name (quotes
	// must be added for reserved keywords).

	indexNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    datatype,
		ContextFlag: contextFlag,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.Index.String(),
	}

	rootIR := &SQLRightIR{
		IRType:   TypeTableIndexName,
		DataType: DataNone,
		LNode:    prefixNode,
		RNode:    indexNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

func (n *TableIndexName) String() string { return AsString(n) }

// TableIndexNames is a list of indexes.
type TableIndexNames []*TableIndexName

// Format implements the NodeFormatter interface.
func (n *TableIndexNames) Format(ctx *FmtCtx) {
	sep := ""
	for _, tni := range *n {
		ctx.WriteString(sep)
		ctx.FormatNode(tni)
		sep = ", "
	}
}

// SQLRight Code Injection.
func (node *TableIndexNames) LogCurrentNodeWithType(depth int, dataType SQLRightDataType, contextFlag SQLRightContextFlag) *SQLRightIR {

	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{}
	for i, n := range *node {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n.LogCurrentNodeWithType(depth+1, dataType, contextFlag)
			var RNode *SQLRightIR
			infix := " "
			if len(*node) >= 2 {
				infix = ", "
				RNode = (*node)[1].LogCurrentNodeWithType(depth+1, dataType, contextFlag)
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
			RNode := n.LogCurrentNodeWithType(depth+1, dataType, contextFlag)

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
	tmpIR.IRType = TypeTableIndexNames
	return tmpIR
}
