package main

import "C"
import (
	"encoding/json"
	"fmt"

	"github.com/pingcap/tidb/parser"
	"github.com/pingcap/tidb/parser/sql_ir"
	_ "github.com/pingcap/tidb/parser/test_driver"
)

func ParseHelperAntiCrash(inData string) (irList []sql_ir.SqlRsgIR, errCode int) {

	defer func() {
		if err := recover(); err != nil {
			// 2 means parsing crashes.
			errCode = 2
			irList = make([]sql_ir.SqlRsgIR, 0)
		}
	}()

	p := parser.New()
	// The return res from p.Parse is an array of stmtNode structure.
	// Each element is one statement from the query.
	stmtNodes, _, err := p.Parse(inData, "", "") // Ignore the warnings.

	if err != nil {
		// 1 means parsing error
		return nil, 1
	}

	// errCode == 0, normal
	// Convert to SQLRight IR struct
	for _, curStmtNode := range stmtNodes {
		tmpIR := curStmtNode.LogCurrentNode(0)
		if tmpIR != nil {
			irList = append(irList, *tmpIR)
		} else {
			return nil, 0
		}
	}

	return irList, 0

}

//export ParseHelper
func ParseHelper(inData string) (*C.char, int) {

	irList, errCode := ParseHelperAntiCrash(inData)

	if errCode == 1 {
		// Parsing error.
		return nil, 0
	} else if errCode == 2 {
		// Parsing panic.
		panicNode := sql_ir.SqlRsgIR{
			IRType:   sql_ir.TypePanic,
			DataType: sql_ir.DataNone,
			Depth:    0,
		}
		irList = make([]sql_ir.SqlRsgIR, 0)
		irList = append(irList, panicNode)
	} // else: errCode == 0, normal.

	// Should convert to json string before passing back to C++ code.
	var jsonStrAllStatement string
	for idx, curIR := range irList {
		jsonStrAllStatement += fmt.Sprintf("idx: %d\n", idx)
		idx += 1
		jsonBytes, jErr := json.Marshal(curIR)
		if jErr != nil {
			return nil, 0
		}

		var m map[string]interface{}
		jErr = json.Unmarshal(jsonBytes, &m)
		if jErr != nil {
			return nil, 0
		}
		//TODO:: GRAM COV.
		//m["gramCov"] = gramCov
		jsonBytes, jErr = json.Marshal(m)

		jsonStr := string(jsonBytes)
		jsonStrAllStatement += jsonStr + "\n"
	}

	// Return the C char array version of jsonStrAllStatement.
	return C.CString(jsonStrAllStatement), len(jsonStrAllStatement)
}

func main() {
}
