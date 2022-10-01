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

import (
	"context"
	"github.com/cockroachdb/cockroach/pkg/sql/pgwire/pgcode"
	"github.com/cockroachdb/cockroach/pkg/sql/pgwire/pgerror"
	"github.com/cockroachdb/cockroach/pkg/sql/types"
	"github.com/cockroachdb/cockroach/pkg/util/errorutil/unimplemented"
	"github.com/cockroachdb/errors"
	"strings"
)

// ErrConflictingFunctionOption indicates that there are conflicting or
// redundant function options from user input to either create or alter a
// function.
var ErrConflictingFunctionOption = pgerror.New(pgcode.Syntax, "conflicting or redundant options")

// FunctionName represent a function name in a UDF relevant statement, either
// DDL or DML statement. Similar to TableName, it is constructed for incoming
// SQL queries from an UnresolvedObjectName.
type FunctionName struct {
	objName
}

// MakeFunctionNameFromPrefix returns a FunctionName with the given prefix and
// function name.
func MakeFunctionNameFromPrefix(prefix ObjectNamePrefix, object Name) FunctionName {
	return FunctionName{objName{
		ObjectName:       object,
		ObjectNamePrefix: prefix,
	}}
}

// MakeQualifiedFunctionName constructs a FunctionName with the given db and
// schema name as prefix.
func MakeQualifiedFunctionName(db string, sc string, fn string) FunctionName {
	return MakeFunctionNameFromPrefix(
		ObjectNamePrefix{
			CatalogName:     Name(db),
			ExplicitCatalog: true,
			SchemaName:      Name(sc),
			ExplicitSchema:  true,
		}, Name(fn),
	)
}

// Format implements the NodeFormatter interface.
func (f *FunctionName) Format(ctx *FmtCtx) {
	f.ObjectNamePrefix.Format(ctx)
	if f.ExplicitSchema || ctx.alwaysFormatTablePrefix() {
		ctx.WriteByte('.')
	}
	ctx.FormatNode(&f.ObjectName)
}

// SQLRight Code Injection.
func (node *FunctionName) LogCurrentNode(depth int, flag SQLRightContextFlag) *SQLRightIR {

	rootIR := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataFunctionName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.String(),
	}

	return rootIR
}

func (f *FunctionName) String() string { return AsString(f) }

// FQString renders the function name in full, not omitting the prefix
// schema and catalog names. Suitable for logging, etc.
func (f *FunctionName) FQString() string {
	ctx := NewFmtCtx(FmtSimple)
	ctx.FormatNode(&f.CatalogName)
	ctx.WriteByte('.')
	ctx.FormatNode(&f.SchemaName)
	ctx.WriteByte('.')
	ctx.FormatNode(&f.ObjectName)
	return ctx.CloseAndGetString()
}

func (f *FunctionName) objectName() {}

// CreateFunction represents a CREATE FUNCTION statement.
type CreateFunction struct {
	IsProcedure bool
	Replace     bool
	FuncName    FunctionName
	Args        FuncArgs
	ReturnType  FuncReturnType
	Options     FunctionOptions
	RoutineBody *RoutineBody
}

// Format implements the NodeFormatter interface.
func (node *CreateFunction) Format(ctx *FmtCtx) {
	ctx.WriteString("CREATE ")
	if node.Replace {
		ctx.WriteString("OR REPLACE ")
	}
	ctx.WriteString("FUNCTION ")
	ctx.FormatNode(&node.FuncName)
	ctx.WriteString("(")
	ctx.FormatNode(node.Args)
	ctx.WriteString(")\n\t")
	ctx.WriteString("RETURNS ")
	if node.ReturnType.IsSet {
		ctx.WriteString("SETOF ")
	}
	ctx.WriteString(node.ReturnType.Type.SQLString())
	ctx.WriteString("\n\t")
	var funcBody FunctionBodyStr
	for _, option := range node.Options {
		switch t := option.(type) {
		case FunctionBodyStr:
			funcBody = t
			continue
		}
		ctx.FormatNode(option)
		ctx.WriteString("\n\t")
	}
	if len(funcBody) > 0 {
		ctx.FormatNode(funcBody)
	}
	if node.RoutineBody != nil {
		ctx.WriteString("BEGIN ATOMIC ")
		for _, stmt := range node.RoutineBody.Stmts {
			ctx.FormatNode(stmt)
			ctx.WriteString("; ")
		}
		ctx.WriteString("END")
	}
}

// SQLRight Code Injection.
func (node *CreateFunction) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "CREATE "

	if node.Replace {
		prefix += "OR REPLACE "
	}
	prefix += "FUNCTION "

	funcNameNode := node.FuncName.LogCurrentNode(depth+1, ContextDefine)

	infix := "("

	argsNode := node.Args.LogCurrentNode(depth + 1)

	suffix := ")\n\t"

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    funcNameNode,
		RNode:    argsNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   suffix,
		Depth:    depth,
	}

	infix = "RETURNS "
	if node.ReturnType.IsSet {
		infix += "SETOF "
	}

	returnTypeNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataTypeName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         node.ReturnType.Type.SQLString(),
	}

	rootIR = &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    rootIR,
		RNode:    returnTypeNode,
		Prefix:   "",
		Infix:    infix,
		Suffix:   "\n\t",
		Depth:    depth,
	}

	var funcBody FunctionBodyStr
	for _, option := range node.Options {
		switch t := option.(type) {
		case FunctionBodyStr:
			funcBody = t
			continue
		}
		optionNode := option.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    optionNode,
			Prefix:   "",
			Infix:    "",
			Suffix:   "\n\t",
			Depth:    depth,
		}
	}
	if len(funcBody) > 0 {
		funcBodyNode := funcBody.LogCurrentNode(depth + 1)
		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    funcBodyNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	infix = ""
	if node.RoutineBody != nil {
		infix = "BEGIN ATOMIC "

		for _, stmt := range node.RoutineBody.Stmts {
			stmtNode := stmt.LogCurrentNode(depth + 1)
			rootIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    rootIR,
				RNode:    stmtNode,
				Prefix:   "",
				Infix:    infix,
				Suffix:   "; ",
				Depth:    depth,
			}
			infix = ""
		}
		rootIR.Suffix += "END"
	}

	rootIR.IRType = TypeCreateFunction

	return rootIR
}

// RoutineBody represent a list of statements in a UDF body.
type RoutineBody struct {
	Stmts Statements
}

// RoutineReturn represent a RETURN statement in a UDF body.
type RoutineReturn struct {
	ReturnVal Expr
}

// Format implements the NodeFormatter interface.
func (node *RoutineReturn) Format(ctx *FmtCtx) {
	ctx.WriteString("RETURN ")
	ctx.FormatNode(node.ReturnVal)
}

// SQLRight Code Injection.
func (node *RoutineReturn) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "RETURN "

	returnValNode := node.ReturnVal.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeRoutineReturn,
		DataType: DataNone,
		LNode:    returnValNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// FunctionOptions represent a list of function options.
type FunctionOptions []FunctionOption

// FunctionOption is an interface representing UDF properties.
type FunctionOption interface {
	functionOption()
	NodeFormatter
	SQLRightInterface
}

func (FunctionNullInputBehavior) functionOption() {}
func (FunctionVolatility) functionOption()        {}
func (FunctionLeakproof) functionOption()         {}
func (FunctionBodyStr) functionOption()           {}
func (FunctionLanguage) functionOption()          {}

// FunctionNullInputBehavior represent the UDF property on null parameters.
type FunctionNullInputBehavior int

const (
	// FunctionCalledOnNullInput indicates that the function will be given the
	// chance to execute when presented with NULL input. This is the default if
	// no null input behavior is specified.
	FunctionCalledOnNullInput FunctionNullInputBehavior = iota
	// FunctionReturnsNullOnNullInput indicates that the function will result in
	// NULL given any NULL parameter.
	FunctionReturnsNullOnNullInput
	// FunctionStrict is the same as FunctionReturnsNullOnNullInput
	FunctionStrict
)

// Format implements the NodeFormatter interface.
func (node FunctionNullInputBehavior) Format(ctx *FmtCtx) {
	switch node {
	case FunctionCalledOnNullInput:
		ctx.WriteString("CALLED ON NULL INPUT")
	case FunctionReturnsNullOnNullInput:
		ctx.WriteString("RETURNS NULL ON NULL INPUT")
	case FunctionStrict:
		ctx.WriteString("STRICT")
	default:
		panic(pgerror.New(pgcode.InvalidParameterValue, "Unknown function option"))
	}
}

// SQLRight Code Injection.
func (node FunctionNullInputBehavior) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""

	switch node {
	case FunctionCalledOnNullInput:
		prefix = "CALLED ON NULL INPUT"
	case FunctionReturnsNullOnNullInput:
		prefix = "RETURNS NULL ON NULL INPUT"
	case FunctionStrict:
		prefix = "STRICT"
	default:
		panic(pgerror.New(pgcode.InvalidParameterValue, "Unknown function option"))
	}

	rootIR := &SQLRightIR{
		IRType:   TypeFunctionNullInputBehavior,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// FunctionVolatility represent UDF volatility property.
type FunctionVolatility int

const (
	// FunctionVolatile represents volatility.Volatile. This is the default
	// volatility if none is provided.
	FunctionVolatile FunctionVolatility = iota
	// FunctionImmutable represents volatility.Immutable.
	FunctionImmutable
	// FunctionStable represents volatility.Stable.
	FunctionStable
)

// Format implements the NodeFormatter interface.
func (node FunctionVolatility) Format(ctx *FmtCtx) {
	switch node {
	case FunctionVolatile:
		ctx.WriteString("VOLATILE")
	case FunctionImmutable:
		ctx.WriteString("IMMUTABLE")
	case FunctionStable:
		ctx.WriteString("STABLE")
	default:
		panic(pgerror.New(pgcode.InvalidParameterValue, "Unknown function option"))
	}
}

// SQLRight Code Injection.
func (node FunctionVolatility) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""

	switch node {
	case FunctionVolatile:
		prefix = "VOLATILE"
	case FunctionImmutable:
		prefix = "IMMUTABLE"
	case FunctionStable:
		prefix = "STABLE"
	default:
		panic(pgerror.New(pgcode.InvalidParameterValue, "Unknown function option"))

	}

	rootIR := &SQLRightIR{
		IRType:   TypeFunctionVolatility,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// FunctionLeakproof indicates whether if a UDF is leakproof or not. The default
// is NOT LEAKPROOF if no leakproof option is provided. LEAKPROOF can only be
// used with the IMMUTABLE volatility because we currently conflated LEAKPROOF
// as a volatility equal to IMMUTABLE+LEAKPROOF. Postgres allows
// STABLE+LEAKPROOF functions.
type FunctionLeakproof bool

// Format implements the NodeFormatter interface.
func (node FunctionLeakproof) Format(ctx *FmtCtx) {
	if !node {
		ctx.WriteString("NOT ")
	}
	ctx.WriteString("LEAKPROOF")
}

// SQLRight Code Injection.
func (node FunctionLeakproof) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""

	if !(node) {
		prefix = "NOT "
	}
	prefix += "LEAKPROOF"

	rootIR := &SQLRightIR{
		IRType:   TypeFunctionLeakproof,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// FunctionLanguage indicates the language of the statements in the UDF function
// body.
type FunctionLanguage int

const (
	_ FunctionLanguage = iota
	// FunctionLangSQL represent SQL language.
	FunctionLangSQL
)

// Format implements the NodeFormatter interface.
func (node FunctionLanguage) Format(ctx *FmtCtx) {
	ctx.WriteString("LANGUAGE ")
	switch node {
	case FunctionLangSQL:
		ctx.WriteString("SQL")
	default:
		panic(pgerror.New(pgcode.InvalidParameterValue, "Unknown function option"))
	}
}

// SQLRight Code Injection.
func (node FunctionLanguage) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "LANGUAGE SQL"

	rootIR := &SQLRightIR{
		IRType:   TypeFunctionLanguage,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: prefix,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// AsFunctionLanguage converts a string to a FunctionLanguage if applicable.
// Error is returned if string does not represent a valid UDF language.
func AsFunctionLanguage(lang string) (FunctionLanguage, error) {
	switch strings.ToLower(lang) {
	case "sql":
		return FunctionLangSQL, nil
	}
	return 0, errors.Newf("language %q does not exist", lang)
}

// FunctionBodyStr is a string containing all statements in a UDF body.
type FunctionBodyStr string

// Format implements the NodeFormatter interface.
func (node FunctionBodyStr) Format(ctx *FmtCtx) {
	ctx.WriteString("AS ")
	ctx.WriteString("$$")
	ctx.WriteString(string(node))
	ctx.WriteString("$$")
}

// SQLRight Code Injection.
func (node FunctionBodyStr) LogCurrentNode(depth int) *SQLRightIR {

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataNone, //TODO: FIXME: Datatype unknown.
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node),
	}
	LNode := tmpNode

	rootIR := &SQLRightIR{
		IRType:   TypeFunctionBodyStr,
		DataType: DataNone,
		LNode:    LNode,
		//RNode:    RNode,
		Prefix: "AS $$",
		Infix:  "$$",
		Suffix: "",
		Depth:  depth,
	}

	return rootIR
}

// FuncArgs represents a list of FuncArg.
type FuncArgs []FuncArg

// Format implements the NodeFormatter interface.
func (node FuncArgs) Format(ctx *FmtCtx) {
	for i, arg := range node {
		if i > 0 {
			ctx.WriteString(", ")
		}
		ctx.FormatNode(&arg)
	}
}

// SQLRight Code Injection.
func (node FuncArgs) LogCurrentNode(depth int) *SQLRightIR {

	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{}
	for i, n := range node {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n.LogCurrentNode(depth + 1)
			var RNode *SQLRightIR
			infix := ""
			if len(node) >= 2 {
				RNode = (node)[1].LogCurrentNode(depth + 1)
				infix = ", "
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
			RNode := n.LogCurrentNode(depth + 1)

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
	tmpIR.IRType = TypeFuncArgs
	return tmpIR
}

// FuncArg represents an argument from a UDF signature.
type FuncArg struct {
	Name       Name
	Type       ResolvableTypeReference
	Class      FuncArgClass
	DefaultVal Expr

	SQLRightInterface
}

// Format implements the NodeFormatter interface.
func (node *FuncArg) Format(ctx *FmtCtx) {
	switch node.Class {
	case FunctionArgIn:
		ctx.WriteString("IN")
	case FunctionArgOut:
		ctx.WriteString("OUT")
	case FunctionArgInOut:
		ctx.WriteString("INOUT")
	case FunctionArgVariadic:
		ctx.WriteString("VARIADIC")
	default:
		panic(pgerror.New(pgcode.InvalidParameterValue, "Unknown function option"))
	}
	ctx.WriteString(" ")
	if node.Name != "" {
		ctx.FormatNode(&node.Name)
		ctx.WriteString(" ")
	}
	ctx.WriteString(node.Type.SQLString())
	if node.DefaultVal != nil {
		ctx.WriteString(" DEFAULT ")
		ctx.FormatNode(node.DefaultVal)
	}
}

// SQLRight Code Injection.
func (node *FuncArg) LogCurrentNode(depth int) *SQLRightIR {

	prefix := ""
	switch node.Class {
	case FunctionArgIn:
		prefix = "IN"
	case FunctionArgOut:
		prefix = "OUT"
	case FunctionArgInOut:
		prefix = "INOUT"
	case FunctionArgVariadic:
		prefix = "VARIADIC"
	default:
		panic(pgerror.New(pgcode.InvalidParameterValue, "Unknown function option"))
	}
	prefix += " "
	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataNone, // TODO: FIXME: DATATYPE unknown here.
		ContextFlag: ContextUnknown,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Name),
	}
	LNode := tmpNode

	infix := " "

	tmpNode = &SQLRightIR{
		IRType:   TypeResolvableTypeReference,
		DataType: DataNone, // TODO: FIXME: DATATYPE unknown here.
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: node.Type.SQLString(),
		Infix:  "",
		Suffix: "",
		Depth:  depth,
		//Str:    node.Type.SQLString(),
	}
	RNode := tmpNode

	rootNode := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   prefix,
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	// Construct the OPT default node.
	var optDefaultValue *SQLRightIR
	if node.DefaultVal != nil {
		defaultValue := node.DefaultVal.LogCurrentNode(depth + 1)
		optDefaultValue = &SQLRightIR{
			IRType:   TypeOptDefaultValue,
			DataType: DataNone,
			LNode:    defaultValue,
			//RNode:    RNode,
			Prefix: " DEFAULT ",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
	} else {
		optDefaultValue = &SQLRightIR{
			IRType:   TypeOptDefaultValue,
			DataType: DataNone,
			//LNode:    defaultValue,
			//RNode:    RNode,
			Prefix: "",
			Infix:  "",
			Suffix: "",
			Depth:  depth,
		}
	}

	LNode = rootNode

	rootNode = &SQLRightIR{
		IRType:   TypeFuncArg,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    optDefaultValue,
		Prefix:   "",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootNode
}

// FuncArgClass indicates what type of argument an arg is.
type FuncArgClass int

const (
	// FunctionArgIn args can only be used as input.
	FunctionArgIn FuncArgClass = iota
	// FunctionArgOut args can only be used as output.
	FunctionArgOut
	// FunctionArgInOut args can be used as both input and output.
	FunctionArgInOut
	// FunctionArgVariadic args are variadic.
	FunctionArgVariadic
)

// FuncReturnType represent the return type of UDF.
type FuncReturnType struct {
	Type  ResolvableTypeReference
	IsSet bool
}

// DropFunction represents a DROP FUNCTION statement.
type DropFunction struct {
	IfExists     bool
	Functions    FuncObjs
	DropBehavior DropBehavior
}

// Format implements the NodeFormatter interface.
func (node *DropFunction) Format(ctx *FmtCtx) {
	ctx.WriteString("DROP FUNCTION ")
	if node.IfExists {
		ctx.WriteString("IF EXISTS ")
	}
	ctx.FormatNode(node.Functions)
	if node.DropBehavior != DropDefault {
		ctx.WriteString(" ")
		ctx.WriteString(node.DropBehavior.String())
	}
}

// SQLRight Code Injection.
func (node *DropFunction) LogCurrentNode(depth int) *SQLRightIR {

	prefix := "DROP FUNCTION "

	optIfExistStr := ""
	if node.IfExists {
		optIfExistStr = "IF EXISTS "
	}
	ifExistsNode := &SQLRightIR{
		IRType:   TypeOptIfExists,
		DataType: DataNone,
		//LNode:    LNode,
		//RNode:    RNode,
		Prefix: optIfExistStr,
		Infix:  "",
		Suffix: "",
		Depth:  depth,
	}

	funcNode := node.Functions.LogCurrentNode(depth+1, ContextUndefine)

	rootIR := &SQLRightIR{
		IRType:   TypeUnknown,
		DataType: DataNone,
		LNode:    ifExistsNode,
		RNode:    funcNode,
		Prefix:   prefix,
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	if node.DropBehavior != DropDefault {

		dropBehaviorNode := &SQLRightIR{
			IRType:   TypeDropBehavior,
			DataType: DataNone,
			Prefix:   node.DropBehavior.String(),
			Infix:    "",
			Suffix:   "",
			Depth:    depth,
		}

		rootIR = &SQLRightIR{
			IRType:   TypeUnknown,
			DataType: DataNone,
			LNode:    rootIR,
			RNode:    dropBehaviorNode,
			Prefix:   "",
			Infix:    " ",
			Suffix:   "",
			Depth:    depth,
		}
	}

	rootIR.IRType = TypeDropFunction

	return rootIR
}

// FuncObjs is a slice of FuncObj.
type FuncObjs []FuncObj

// Format implements the NodeFormatter interface.
func (node FuncObjs) Format(ctx *FmtCtx) {
	for i, f := range node {
		if i > 0 {
			ctx.WriteString(", ")
		}
		ctx.FormatNode(f)
	}
}

// SQLRight Code Injection.
func (node *FuncObjs) LogCurrentNode(depth int, flag SQLRightContextFlag) *SQLRightIR {

	// TODO: FIXME. The depth is not handling correctly. All struct for this type are in the same depth.

	tmpIR := &SQLRightIR{}
	for i, n := range *node {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n.LogCurrentNode(depth+1, flag)
			var RNode *SQLRightIR
			infix := ""
			if len(*node) >= 2 {
				infix = ", "
				RNode = (*node)[1].LogCurrentNode(depth+1, flag)
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
			RNode := n.LogCurrentNode(depth+1, flag)

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
	tmpIR.IRType = TypeFuncObjs
	return tmpIR
}

// FuncObj represents a function object DROP FUNCTION tries to drop.
type FuncObj struct {
	FuncName FunctionName
	Args     FuncArgs
	SQLRightInterface
}

// Format implements the NodeFormatter interface.
func (node FuncObj) Format(ctx *FmtCtx) {
	ctx.FormatNode(&node.FuncName)
	if node.Args != nil {
		ctx.WriteString("(")
		ctx.FormatNode(node.Args)
		ctx.WriteString(")")
	}
}

// SQLRight Code Injection.
func (node *FuncObj) LogCurrentNode(depth int, flag SQLRightContextFlag) *SQLRightIR {

	LNode := node.FuncName.LogCurrentNode(depth+1, flag)

	RNode := node.Args.LogCurrentNode(depth + 1)

	rootIR := &SQLRightIR{
		IRType:   TypeFuncObj,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "",
		Infix:    "(",
		Suffix:   ")",
		Depth:    depth,
	}

	return rootIR
}

// InputArgTypes returns a slice of argument types of the function.
func (node FuncObj) InputArgTypes(
	ctx context.Context, res TypeReferenceResolver,
) ([]*types.T, error) {
	// TODO(chengxiong): handle INOUT, OUT and VARIADIC argument classes when we
	// support them. This is because only IN and INOUT arg types need to be
	// considered to match a overload.
	var argTypes []*types.T
	if node.Args != nil {
		argTypes = make([]*types.T, len(node.Args))
		for i, arg := range node.Args {
			typ, err := ResolveType(ctx, arg.Type, res)
			if err != nil {
				return nil, err
			}
			argTypes[i] = typ
		}
	}
	return argTypes, nil
}

// AlterFunctionOptions represents a ALTER FUNCTION...action statement.
type AlterFunctionOptions struct {
	Function FuncObj
	Options  FunctionOptions
}

// Format implements the NodeFormatter interface.
func (node *AlterFunctionOptions) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER FUNCTION ")
	ctx.FormatNode(node.Function)
	for _, option := range node.Options {
		ctx.WriteString(" ")
		ctx.FormatNode(option)
	}
}

// SQLRight Code Injection.
func (node *AlterFunctionOptions) LogCurrentNode(depth int) *SQLRightIR {

	tmpIR := &SQLRightIR{}
	for i, n := range node.Options {

		if i == 0 {
			// Take care of the first two nodes.
			LNode := n.LogCurrentNode(depth + 1)
			var RNode *SQLRightIR
			if len(node.Options) >= 2 {
				RNode = (node.Options)[1].LogCurrentNode(depth + 1)
			}
			tmpIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   "",
				Infix:    " ",
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
			RNode := n.LogCurrentNode(depth + 1)

			tmpIR = &SQLRightIR{
				IRType:   TypeUnknown,
				DataType: DataNone,
				LNode:    LNode,
				RNode:    RNode,
				Prefix:   "",
				Infix:    " ",
				Suffix:   "",
				Depth:    depth,
			}
		}
	}

	var optionListNode *SQLRightIR
	if tmpIR.LNode != nil {
		optionListNode = tmpIR
		optionListNode.IRType = TypeFunctionOptions
	}
	LNode := node.Function.LogCurrentNode(depth+1, ContextUse)

	rootIR := &SQLRightIR{
		IRType:   TypeAlterChangeFeed,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    optionListNode,
		Prefix:   "ALTER FUNCTION ",
		Infix:    "",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterFunctionRename represents a ALTER FUNCTION...RENAME statement.
type AlterFunctionRename struct {
	Function FuncObj
	NewName  Name
}

// Format implements the NodeFormatter interface.
func (node *AlterFunctionRename) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER FUNCTION ")
	ctx.FormatNode(node.Function)
	ctx.WriteString(" RENAME TO ")
	ctx.WriteString(string(node.NewName))
}

// SQLRight Code Injection.
func (node *AlterFunctionRename) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.Function.LogCurrentNode(depth+1, ContextReplaceUndefine)
	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataFunctionName,
		ContextFlag: ContextReplaceUndefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.NewName),
	}
	RNode := tmpNode

	rootIR := &SQLRightIR{
		IRType:   TypeAlterFunctionRename,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "ALTER FUNCTION ",
		Infix:    " RENAME TO ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterFunctionSetSchema represents a ALTER FUNCTION...SET SCHEMA statement.
type AlterFunctionSetSchema struct {
	Function      FuncObj
	NewSchemaName Name
}

// Format implements the NodeFormatter interface.
func (node *AlterFunctionSetSchema) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER FUNCTION ")
	ctx.FormatNode(node.Function)
	ctx.WriteString(" SET SCHEMA ")
	ctx.WriteString(string(node.NewSchemaName))
}

// SQLRight Code Injection.
func (node *AlterFunctionSetSchema) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.Function.LogCurrentNode(depth+1, ContextReplaceUndefine)

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataSchemaName,
		ContextFlag: ContextReplaceDefine,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.NewSchemaName),
	}
	RNode := tmpNode

	rootIR := &SQLRightIR{
		IRType:   TypeAlterFunctionSetSchema,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "ALTER FUNCTION ",
		Infix:    " SET SCHEMA ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterFunctionSetOwner represents the ALTER FUNCTION...OWNER TO statement.
type AlterFunctionSetOwner struct {
	Function FuncObj
	NewOwner RoleSpec
}

// Format implements the NodeFormatter interface.
func (node *AlterFunctionSetOwner) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER FUNCTION ")
	ctx.FormatNode(node.Function)
	ctx.WriteString(" OWNER TO ")
	ctx.FormatNode(&node.NewOwner)
}

// SQLRight Code Injection.
func (node *AlterFunctionSetOwner) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.Function.LogCurrentNode(depth+1, ContextUse)
	RNode := node.NewOwner.LogCurrentNode(depth+1, ContextUse)

	rootIR := &SQLRightIR{
		IRType:   TypeAlterFunctionSetSchema,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "ALTER FUNCTION ",
		Infix:    " OWNER TO ",
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// AlterFunctionDepExtension represents the ALTER FUNCTION...DEPENDS ON statement.
type AlterFunctionDepExtension struct {
	Function  FuncObj
	Remove    bool
	Extension Name
}

// Format implements the NodeFormatter interface.
func (node *AlterFunctionDepExtension) Format(ctx *FmtCtx) {
	ctx.WriteString("ALTER FUNCTION  ")
	ctx.FormatNode(node.Function)
	if node.Remove {
		ctx.WriteString(" NO")
	}
	ctx.WriteString(" DEPENDS ON EXTENSION ")
	ctx.WriteString(string(node.Extension))
}

// SQLRight Code Injection.
func (node *AlterFunctionDepExtension) LogCurrentNode(depth int) *SQLRightIR {

	LNode := node.Function.LogCurrentNode(depth+1, ContextUse)

	tmpNode := &SQLRightIR{
		IRType:      TypeIdentifier,
		DataType:    DataExtensionName,
		ContextFlag: ContextUse,
		Prefix:      "",
		Infix:       "",
		Suffix:      "",
		Depth:       depth,
		Str:         string(node.Extension),
	}
	RNode := tmpNode

	infix := ""
	if node.Remove {
		infix = " NO DEPENDS ON EXTENSION "
	} else {
		infix = " DEPENDS ON EXTENSION "
	}

	rootIR := &SQLRightIR{
		IRType:   TypeAlterFunctionDepExtension,
		DataType: DataNone,
		LNode:    LNode,
		RNode:    RNode,
		Prefix:   "ALTER FUNCTION ",
		Infix:    infix,
		Suffix:   "",
		Depth:    depth,
	}

	return rootIR
}

// UDFDisallowanceVisitor is used to determine if a type checked expression
// contains any UDF function sub-expression. It's needed only temporarily to
// disallow any usage of UDF from relation objects.
type UDFDisallowanceVisitor struct {
	FoundUDF bool
}

// VisitPre implements the Visitor interface.
func (v *UDFDisallowanceVisitor) VisitPre(expr Expr) (recurse bool, newExpr Expr) {
	if funcExpr, ok := expr.(*FuncExpr); ok && funcExpr.ResolvedOverload().IsUDF {
		v.FoundUDF = true
		return false, expr
	}
	return true, expr
}

// VisitPost implements the Visitor interface.
func (v *UDFDisallowanceVisitor) VisitPost(expr Expr) (newNode Expr) {
	return expr
}

// MaybeFailOnUDFUsage returns an error if the given expression or any
// sub-expression used a UDF.
// TODO(chengxiong): remove this function when we start allowing UDF references.
func MaybeFailOnUDFUsage(expr TypedExpr) error {
	visitor := &UDFDisallowanceVisitor{}
	WalkExpr(visitor, expr)
	if visitor.FoundUDF {
		return unimplemented.NewWithIssue(83234, "usage of user-defined function from relations not supported")
	}
	return nil
}

// ValidateFuncOptions checks whether there are conflicting or redundant
// function options in the given slice.
func ValidateFuncOptions(options FunctionOptions) error {
	var hasLang, hasBody, hasLeakProof, hasVolatility, hasNullInputBehavior bool
	err := func(opt FunctionOption) error {
		return errors.Wrapf(ErrConflictingFunctionOption, "%s", AsString(opt))
	}
	for _, option := range options {
		switch option.(type) {
		case FunctionLanguage:
			if hasLang {
				return err(option)
			}
			hasLang = true
		case FunctionBodyStr:
			if hasBody {
				return err(option)
			}
			hasBody = true
		case FunctionLeakproof:
			if hasLeakProof {
				return err(option)
			}
			hasLeakProof = true
		case FunctionVolatility:
			if hasVolatility {
				return err(option)
			}
			hasVolatility = true
		case FunctionNullInputBehavior:
			if hasNullInputBehavior {
				return err(option)
			}
			hasNullInputBehavior = true
		default:
			return pgerror.Newf(pgcode.InvalidParameterValue, "unknown function option: ", AsString(option))
		}
	}

	return nil
}
