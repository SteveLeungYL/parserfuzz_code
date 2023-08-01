package main

import "C"
import (
	"encoding/json"
	"fmt"

	"github.com/pingcap/tidb/parser"
	"github.com/pingcap/tidb/parser/sql_ir"
	_ "github.com/pingcap/tidb/parser/test_driver"
)

//export ParseHelper
func ParseHelper(inData string) (*C.char, int) {

	p := parser.New()
	// The return res from p.Parse is an array of stmtNode structure.
	// Each element is one statement from the query.
	stmtNodes, _, err := p.Parse(inData, "", "") // Ignore the warnings.

	if err != nil {
		return nil, 0
	}

	// Convert to SQLRight IR struct
	var irList []sql_ir.SqlRsgIR
	for _, curStmtNode := range stmtNodes {
		tmpIR := curStmtNode.LogCurrentNode(0)
		if tmpIR != nil {
			irList = append(irList, *tmpIR)
		} else {
			return nil, 0
		}
	}

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
