// Copyright 2020 The Cockroach Authors.
//
// Use of this software is governed by the Business Source License
// included in the file licenses/BSL.txt.
//
// As of the Change Date specified in that file, in accordance with
// the Business Source License, use of this software will be governed
// by the Apache License, Version 2.0, included in the file
// licenses/APL.txt.

package tree

// ObjectName is a common interface for qualified object names.
type ObjectName interface {
	NodeFormatter
	Object() string
	Schema() string
	Catalog() string
	FQString() string
	objectName()
}

var _ ObjectName = &TableName{}
var _ ObjectName = &TypeName{}
var _ ObjectName = &FunctionName{}

// objName is the internal type for a qualified object.
type objName struct {
	// ObjectName is the unqualified name for the object
	// (table/view/sequence/function/type).
	ObjectName Name

	// ObjectNamePrefix is the path to the object.  This can be modified
	// further by name resolution, see name_resolution.go.
	ObjectNamePrefix
}

func (o *objName) Object() string {
	return string(o.ObjectName)
}

// ToUnresolvedObjectName converts the type name to an unresolved object name.
// Schema and catalog are included if indicated by the ExplicitSchema and
// ExplicitCatalog flags.
func (o *objName) ToUnresolvedObjectName() *UnresolvedObjectName {
	u := &UnresolvedObjectName{}

	u.NumParts = 1
	u.Parts[0] = string(o.ObjectName)
	if o.ExplicitSchema {
		u.Parts[u.NumParts] = string(o.SchemaName)
		u.NumParts++
	}
	if o.ExplicitCatalog {
		u.Parts[u.NumParts] = string(o.CatalogName)
		u.NumParts++
	}
	return u
}

// ObjectNamePrefix corresponds to the path prefix of an object name.
type ObjectNamePrefix struct {
	CatalogName Name
	SchemaName  Name

	// ExplicitCatalog is true iff the catalog was explicitly specified
	// or it needs to be rendered during pretty-printing.
	ExplicitCatalog bool
	// ExplicitSchema is true iff the schema was explicitly specified
	// or it needs to be rendered during pretty-printing.
	ExplicitSchema bool

	SQLRightInterface
}

// Format implements the NodeFormatter interface.
func (tp *ObjectNamePrefix) Format(ctx *FmtCtx) {
	alwaysFormat := ctx.alwaysFormatTablePrefix()
	if tp.ExplicitSchema || alwaysFormat {
		if tp.ExplicitCatalog || alwaysFormat {
			ctx.FormatNode(&tp.CatalogName)
			ctx.WriteByte('.')
		}
		ctx.FormatNode(&tp.SchemaName)
	}
}

func (node *ObjectNamePrefix) LogCurrentNode(depth int) *SQLRightIR {
	return node.LogCurrentNodeWithType(depth, DataSchemaName, ContextUse)
}

// SQLRight Code Injection.
func (node *ObjectNamePrefix) LogCurrentNodeWithType(depth int, dataType SQLRightDataType, contextFlag SQLRightContextFlag) *SQLRightIR {

	tmpNode := &SQLRightIR{
		NodeHash:    156139,
		IRType:      TypeIdentifier,
		DataType:    DataCatalogName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.CatalogName),
	}
	LNode := tmpNode

	tmpNode = &SQLRightIR{
		NodeHash:    95008,
		IRType:      TypeIdentifier,
		DataType:    dataType,
		ContextFlag: contextFlag,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.SchemaName),
	}
	RNode := tmpNode

	rootIR := &SQLRightIR{
		NodeHash: 194275,
		IRType:   TypeObjectNamePrefix,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "",
		Infix:    ".",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

func (tp *ObjectNamePrefix) String() string { return AsString(tp) }

// Schema retrieves the unqualified schema name.
func (tp *ObjectNamePrefix) Schema() string {
	return string(tp.SchemaName)
}

// Catalog retrieves the unqualified catalog name.
func (tp *ObjectNamePrefix) Catalog() string {
	return string(tp.CatalogName)
}

// ObjectNamePrefixList is a list of ObjectNamePrefix
type ObjectNamePrefixList []ObjectNamePrefix

// Format implements the NodeFormatter interface.
func (tp ObjectNamePrefixList) Format(ctx *FmtCtx) {
	for idx, objectNamePrefix := range tp {
		ctx.FormatNode(&objectNamePrefix)
		if idx != len(tp)-1 {
			ctx.WriteString(", ")
		}
	}
}

func (node *ObjectNamePrefixList) LogCurrentNode(depth int) *SQLRightIR {
	return node.LogCurrentNodeWithType(depth, DataSchemaName, ContextUse)
}

// SQLRight Code Injection.
func (node *ObjectNamePrefixList) LogCurrentNodeWithType(depth int, dataType SQLRightDataType, contextFlag SQLRightContextFlag) *SQLRightIR {

	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{
		NodeHash: 4458}
	for i, n := range *node {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n.LogCurrentNodeWithType(depth+1, dataType, contextFlag)
			var RNode *SQLRightIR
			infix := ""
			if len(*node) >= 2 {
				RNode = (*node)[1].LogCurrentNodeWithType(depth+1, dataType, contextFlag)
				infix = ", "
			}
			tmpIR = &SQLRightIR{
				NodeHash: 24769,
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
				NodeHash: 63825,
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
	tmpIR.NodeHash = 82596
	tmpIR.IRType = TypeObjectNamePrefixList
	return tmpIR
}

// UnresolvedObjectName is an unresolved qualified name for a database object
// (table, view, etc). It is like UnresolvedName but more restrictive.
// It should only be constructed via NewUnresolvedObjectName.
type UnresolvedObjectName struct {
	// NumParts indicates the number of name parts specified; always 1 or greater.
	NumParts int

	// Parts are the name components, in reverse order.
	// There are at most 3: object name, schema, catalog/db.
	//
	// Note: Parts has a fixed size so that we avoid a heap allocation for the
	// slice every time we construct an UnresolvedObjectName. It does imply
	// however that Parts does not have a meaningful "length"; its actual length
	// (the number of parts specified) is populated in NumParts above.
	Parts [3]string

	// UnresolvedObjectName can be annotated with a *tree.TableName.
	AnnotatedNode
}

// UnresolvedObjectName implements TableExpr.
func (*UnresolvedObjectName) tableExpr() {}

// NewUnresolvedObjectName creates an unresolved object name, verifying that it
// is well-formed.
func NewUnresolvedObjectName(
	numParts int, parts [3]string, annotationIdx AnnotationIdx,
) (*UnresolvedObjectName, error) {
	u := &UnresolvedObjectName{
		NumParts:      numParts,
		Parts:         parts,
		AnnotatedNode: AnnotatedNode{AnnIdx: annotationIdx},
	}
	if u.NumParts < 1 {
		return nil, newInvTableNameError(u)
	}

	// Check that all the parts specified are not empty.
	// It's OK if the catalog name is empty.
	// We allow this in e.g. `select * from "".crdb_internal.tables`.
	lastCheck := u.NumParts
	if lastCheck > 2 {
		lastCheck = 2
	}
	for i := 0; i < lastCheck; i++ {
		if len(u.Parts[i]) == 0 {
			return nil, newInvTableNameError(u)
		}
	}
	return u, nil
}

// Resolved returns the resolved name in the annotation for this node (or nil if
// there isn't one).
func (u *UnresolvedObjectName) Resolved(ann *Annotations) ObjectName {
	r := u.GetAnnotation(ann)
	if r == nil {
		return nil
	}
	return r.(ObjectName)
}

// Format implements the NodeFormatter interface.
func (u *UnresolvedObjectName) Format(ctx *FmtCtx) {
	// If we want to format the corresponding resolved name, look it up in the
	// annotation.
	if ctx.HasFlags(FmtAlwaysQualifyTableNames) || ctx.tableNameFormatter != nil {
		if ctx.tableNameFormatter != nil && ctx.ann == nil {
			// TODO(radu): this is a temporary hack while we transition to using
			// unresolved names everywhere. We will need to revisit and see if we need
			// to switch to (or add) an UnresolvedObjectName formatter.
			tn := u.ToTableName()
			tn.Format(ctx)
			return
		}

		if n := u.Resolved(ctx.ann); n != nil {
			n.Format(ctx)
			return
		}
	}

	for i := u.NumParts; i > 0; i-- {
		// The first part to print is the last item in u.Parts. It is also
		// a potentially restricted name to disambiguate from keywords in
		// the grammar, so print it out as a "Name". Every part after that is
		// necessarily an unrestricted name.
		if i == u.NumParts {
			ctx.FormatNode((*Name)(&u.Parts[i-1]))
		} else {
			ctx.WriteByte('.')
			ctx.FormatNode((*UnrestrictedName)(&u.Parts[i-1]))
		}
	}
}

// SQLRight Code Injection.
func (node *UnresolvedObjectName) LogCurrentNode(depth int) *SQLRightIR {

	rootIR := &SQLRightIR{
		NodeHash:    196773,
		IRType:      TypeIdentifier,
		DataType:    DataNone,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.String(),
	}

	return rootIR
}

func (u *UnresolvedObjectName) String() string { return AsString(u) }

// TODO(radu): the schema and catalog names might not be in the right places; we
// would only figure that out during name resolution. This method is temporary,
// while we change all the code paths to only use TableName after resolution.
func (u *UnresolvedObjectName) toObjName() objName {
	return objName{
		ObjectName: Name(u.Parts[0]),
		ObjectNamePrefix: ObjectNamePrefix{
			SchemaName:      Name(u.Parts[1]),
			CatalogName:     Name(u.Parts[2]),
			ExplicitSchema:  u.NumParts >= 2,
			ExplicitCatalog: u.NumParts >= 3,
		},
	}
}

// ToTableName converts the unresolved name to a table name.
func (u *UnresolvedObjectName) ToTableName() TableName {
	return TableName{u.toObjName()}
}

// ToFunctionName converts the unresolved name to a function name.
func (u *UnresolvedObjectName) ToFunctionName() FunctionName {
	return FunctionName{u.toObjName()}
}

// ToUnresolvedName converts the unresolved object name to the more general
// unresolved name.
func (u *UnresolvedObjectName) ToUnresolvedName() *UnresolvedName {
	return &UnresolvedName{
		NumParts: u.NumParts,
		Parts:    NameParts{u.Parts[0], u.Parts[1], u.Parts[2]},
	}
}

// Utility methods below for operating on UnresolvedObjectName more natural.

// Object returns the unqualified object name.
func (u *UnresolvedObjectName) Object() string {
	return u.Parts[0]
}

// Schema returns the schema of the object.
func (u *UnresolvedObjectName) Schema() string {
	return u.Parts[1]
}

// Catalog returns the catalog of the object.
func (u *UnresolvedObjectName) Catalog() string {
	return u.Parts[2]
}

// HasExplicitSchema returns whether a schema is specified on the object.
func (u *UnresolvedObjectName) HasExplicitSchema() bool {
	return u.NumParts >= 2
}

// HasExplicitCatalog returns whether a catalog is specified on the object.
func (u *UnresolvedObjectName) HasExplicitCatalog() bool {
	return u.NumParts >= 3
}
