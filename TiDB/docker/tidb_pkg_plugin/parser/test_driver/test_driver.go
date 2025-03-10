// Copyright 2019 PingCAP, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// See the License for the specific language governing permissions and
// limitations under the License.

//go:build !codes
// +build !codes

package test_driver

import (
	"fmt"
	"io"
	"strconv"

	"github.com/pingcap/tidb/parser/ast"
	"github.com/pingcap/tidb/parser/charset"
	"github.com/pingcap/tidb/parser/format"
	"github.com/pingcap/tidb/parser/mysql"
	"github.com/pingcap/tidb/parser/sql_ir"
)

func init() {
	ast.NewValueExpr = newValueExpr
	ast.NewParamMarkerExpr = newParamMarkerExpr
	ast.NewDecimal = func(str string) (interface{}, error) {
		dec := new(MyDecimal)
		err := dec.FromString([]byte(str))
		return dec, err
	}
	ast.NewHexLiteral = func(str string) (interface{}, error) {
		h, err := NewHexLiteral(str)
		return h, err
	}
	ast.NewBitLiteral = func(str string) (interface{}, error) {
		b, err := NewBitLiteral(str)
		return b, err
	}
}

var (
	_ ast.ParamMarkerExpr = &ParamMarkerExpr{}
	_ ast.ValueExpr       = &ValueExpr{}
)

// ValueExpr is the simple value expression.
type ValueExpr struct {
	ast.TexprNode
	Datum
	projectionOffset int
}

func (n *ValueExpr) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := ""
	var lNode *sql_ir.SqlRsgIR
	var rNode *sql_ir.SqlRsgIR

	switch n.Kind() {
	case KindNull:
		prefix += "NULL"
	case KindInt64:
		if n.Type.GetFlag()&mysql.IsBooleanFlag != 0 {
			if n.GetInt64() > 0 {
				prefix += "TRUE"
			} else {
				prefix += "FALSE"
			}
		} else {
			lNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeIntegerLiteral,
				DataType: sql_ir.DataNone,
				Str:      strconv.FormatInt(n.GetInt64(), 10),
				IValue:   int64(n.GetInt64()),
				Depth:    depth,
			}
		}
	case KindUint64:
		lNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeIntegerLiteral,
			DataType: sql_ir.DataNone,
			Str:      strconv.FormatInt(int64(n.GetUint64()), 10),
			IValue:   int64(n.GetUint64()),
			Depth:    depth,
		}
	case KindFloat32:
		lNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeFloatLiteral,
			DataType: sql_ir.DataNone,
			Str:      strconv.FormatFloat(n.GetFloat64(), 'e', -1, 32),
			FValue:   n.GetFloat64(),
			Depth:    depth,
		}
	case KindFloat64:
		lNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeFloatLiteral,
			DataType: sql_ir.DataNone,
			Str:      strconv.FormatFloat(n.GetFloat64(), 'e', -1, 64),
			FValue:   n.GetFloat64(),
			Depth:    depth,
		}
	case KindString:
		// Ignore the charset setting string.
		lNode = &sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypeStringLiteral,
			DataType: sql_ir.DataNone,
			Str:      "'" + n.GetString() + "'",
			Depth:    depth,
		}
	case KindBytes:
		prefix += (n.GetString())
	case KindMysqlDecimal:
		prefix += n.GetMysqlDecimal().String()
	case KindBinaryLiteral:
		// Ignore the charset declaration
		if n.Type.GetFlag()&mysql.UnsignedFlag != 0 {
			lNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeStringLiteral,
				DataType: sql_ir.DataNone,
				Str:      "'" + string(n.GetBytes()) + "'",
				Depth:    depth,
			}
		} else {
			lNode = &sql_ir.SqlRsgIR{
				IRType:   sql_ir.TypeStringLiteral,
				DataType: sql_ir.DataNone,
				Str:      "'" + n.GetBinaryLiteral().ToBitLiteralString(true) + "'",
				Depth:    depth,
			}
		}
	case KindMysqlDuration, KindMysqlEnum,
		KindMysqlBit, KindMysqlSet, KindMysqlTime,
		KindInterface, KindMinNotNull, KindMaxValue,
		KindRaw, KindMysqlJSON:
		// TODO implement Restore function
		// DO NOTHING.
		break
	default:
		// DO NOTHING.
		break
	}

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		LNode:    lNode,
		RNode:    rNode,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeValueExpr

	return rootNode

}

// Restore implements Node interface.
func (n *ValueExpr) Restore(ctx *format.RestoreCtx) error {
	switch n.Kind() {
	case KindNull:
		ctx.WriteKeyWord("NULL")
	case KindInt64:
		if n.Type.GetFlag()&mysql.IsBooleanFlag != 0 {
			if n.GetInt64() > 0 {
				ctx.WriteKeyWord("TRUE")
			} else {
				ctx.WriteKeyWord("FALSE")
			}
		} else {
			ctx.WritePlain(strconv.FormatInt(n.GetInt64(), 10))
		}
	case KindUint64:
		ctx.WritePlain(strconv.FormatUint(n.GetUint64(), 10))
	case KindFloat32:
		ctx.WritePlain(strconv.FormatFloat(n.GetFloat64(), 'e', -1, 32))
	case KindFloat64:
		ctx.WritePlain(strconv.FormatFloat(n.GetFloat64(), 'e', -1, 64))
	case KindString:
		if n.Type.GetCharset() != "" {
			ctx.WritePlain("_")
			ctx.WriteKeyWord(n.Type.GetCharset())
		}
		ctx.WriteString(n.GetString())
	case KindBytes:
		ctx.WriteString(n.GetString())
	case KindMysqlDecimal:
		ctx.WritePlain(n.GetMysqlDecimal().String())
	case KindBinaryLiteral:
		if n.Type.GetCharset() != "" && n.Type.GetCharset() != mysql.DefaultCharset &&
			n.Type.GetCharset() != charset.CharsetBin {
			ctx.WritePlain("_")
			ctx.WriteKeyWord(n.Type.GetCharset() + " ")
		}
		if n.Type.GetFlag()&mysql.UnsignedFlag != 0 {
			ctx.WritePlainf("x'%x'", n.GetBytes())
		} else {
			ctx.WritePlain(n.GetBinaryLiteral().ToBitLiteralString(true))
		}
	case KindMysqlDuration, KindMysqlEnum,
		KindMysqlBit, KindMysqlSet, KindMysqlTime,
		KindInterface, KindMinNotNull, KindMaxValue,
		KindRaw, KindMysqlJSON:
		// TODO implement Restore function
		return fmt.Errorf("not implemented")
	default:
		return fmt.Errorf("can't format to string")
	}
	return nil
}

// GetDatumString implements the ValueExpr interface.
func (n *ValueExpr) GetDatumString() string {
	return n.GetString()
}

// Format the ExprNode into a Writer.
func (n *ValueExpr) Format(w io.Writer) {
	var s string
	switch n.Kind() {
	case KindNull:
		s = "NULL"
	case KindInt64:
		if n.Type.GetFlag()&mysql.IsBooleanFlag != 0 {
			if n.GetInt64() > 0 {
				s = "TRUE"
			} else {
				s = "FALSE"
			}
		} else {
			s = strconv.FormatInt(n.GetInt64(), 10)
		}
	case KindUint64:
		s = strconv.FormatUint(n.GetUint64(), 10)
	case KindFloat32:
		s = strconv.FormatFloat(n.GetFloat64(), 'e', -1, 32)
	case KindFloat64:
		s = strconv.FormatFloat(n.GetFloat64(), 'e', -1, 64)
	case KindString, KindBytes:
		s = strconv.Quote(n.GetString())
	case KindMysqlDecimal:
		s = n.GetMysqlDecimal().String()
	case KindBinaryLiteral:
		if n.Type.GetFlag()&mysql.UnsignedFlag != 0 {
			s = fmt.Sprintf("x'%x'", n.GetBytes())
		} else {
			s = n.GetBinaryLiteral().ToBitLiteralString(true)
		}
	default:
		panic("Can't format to string")
	}
	_, _ = fmt.Fprint(w, s)
}

// newValueExpr creates a ValueExpr with value, and sets default field type.
func newValueExpr(value interface{}, charset string, collate string) ast.ValueExpr {
	if ve, ok := value.(*ValueExpr); ok {
		return ve
	}
	ve := &ValueExpr{}
	ve.SetValue(value)
	DefaultTypeForValue(value, &ve.Type, charset, collate)
	ve.projectionOffset = -1
	return ve
}

// SetProjectionOffset sets ValueExpr.projectionOffset for logical plan builder.
func (n *ValueExpr) SetProjectionOffset(offset int) {
	n.projectionOffset = offset
}

// GetProjectionOffset returns ValueExpr.projectionOffset.
func (n *ValueExpr) GetProjectionOffset() int {
	return n.projectionOffset
}

// Accept implements Node interface.
func (n *ValueExpr) Accept(v ast.Visitor) (ast.Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*ValueExpr)
	return v.Leave(n)
}

// ParamMarkerExpr expression holds a place for another expression.
// Used in parsing prepare statement.
type ParamMarkerExpr struct {
	ValueExpr
	Offset    int
	Order     int
	InExecute bool
}

func (n *ParamMarkerExpr) LogCurrentNode(depth int) *sql_ir.SqlRsgIR {

	prefix := "?"

	rootNode := &sql_ir.SqlRsgIR{
		IRType:   sql_ir.TypeUnknown,
		DataType: sql_ir.DataNone,
		Prefix:   prefix,
		Depth:    depth,
	}

	rootNode.IRType = sql_ir.TypeParamMarkerExpr

	return rootNode

}

// Restore implements Node interface.
func (n *ParamMarkerExpr) Restore(ctx *format.RestoreCtx) error {
	ctx.WritePlain("?")
	return nil
}

func newParamMarkerExpr(offset int) ast.ParamMarkerExpr {
	return &ParamMarkerExpr{
		Offset: offset,
	}
}

// Format the ExprNode into a Writer.
func (n *ParamMarkerExpr) Format(w io.Writer) {
	panic("Not implemented")
}

// Accept implements Node Accept interface.
func (n *ParamMarkerExpr) Accept(v ast.Visitor) (ast.Node, bool) {
	newNode, skipChildren := v.Enter(n)
	if skipChildren {
		return v.Leave(newNode)
	}
	n = newNode.(*ParamMarkerExpr)
	return v.Leave(n)
}

// SetOrder implements the ParamMarkerExpr interface.
func (n *ParamMarkerExpr) SetOrder(order int) {
	n.Order = order
}
